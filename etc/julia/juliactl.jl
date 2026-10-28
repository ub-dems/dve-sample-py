#!/usr/bin/env -S julia --color=yes --startup-file=no
#
# juliactl: uv-inspired Julia project management (stdlib only).
#
#   uv run julia juliactl.jl init                  # create Project.toml
#   uv run julia juliactl.jl init --all            # init -> lock -> sync
#   uv run julia juliactl.jl init --pytorch --duckdb --all
#   uv run julia juliactl.jl lock --all            # lock -> sync
#   uv run julia juliactl.jl sync
#
# Python integration: when run under `uv run` (or next to a `.venv`), PythonCall
# is pointed at that venv (JULIA_PYTHONCALL_EXE) and CondaPkg is disabled
# (JULIA_CONDAPKG_BACKEND=Null), so Python packages come from pyproject.toml/uv,
# not from a second, conda-managed environment.

using Pkg
using TOML

# ------------------------------------------------------------------ logging

logmsg(msg; level = "LOG") = println("#juliactl|", level, "|", msg)

function die(msg; code = 1)
    logmsg(msg; level = "ERROR")
    exit(code)
end

const USAGE = """
juliactl: Julia project initialization (uv-inspired)

Usage:  juliactl <command> [options]

Commands:
  init [NAME]   create Project.toml with the predefined packages
                (merges missing packages if Project.toml already exists)
  lock          upgrade dependencies to latest versions, write Manifest.toml
  sync          install packages from Manifest.toml and precompile

Options:
  --all           chain commands: init -> lock -> sync, lock -> sync
  --dir PATH      project directory (default: current directory)
  --name NAME     project name (default: [project].name of pyproject.toml,
                  else the directory name); same as the positional NAME
  --python PATH   Python executable for PythonCall
                  (default: \$VIRTUAL_ENV, else ./.venv)
  --no-uv         do not run `uv add` for the Python-side requirements
  --force         init: recreate Project.toml instead of merging
  -h, --help      show this help

Integrations (init only):
  --keras         Python keras (+ torch backend) through PythonCall
  --pytorch       Python torch through PythonCall (alias: --torch)
  --duckdb        Julia native DuckDB.jl
  --polars        Python polars through PythonCall
  --dynare        Julia native Dynare.jl
  --plotly        legacy Plotly.jl (pins HTTP 0.9: may hold Pluto back)
"""

function exit_usage(code::Integer = 1)
    println(USAGE)
    exit(code)
end

# ------------------------------------------------------------ package tables

# Name -> UUID, as found in the General registry (so Project.toml can be
# written without resolving anything).
const REGISTRY_UUIDS = Dict{String,String}(
    "PythonCall"      => "6099a3de-0909-46bc-b1f4-468b9a2dfc0d",
    "PythonPlot"      => "274fc56d-3b97-40fa-a1cd-1b4a50311bf9",
    "IJulia"          => "7073ff75-c697-5162-941a-fcdaad2a7d2a",
    "Pluto"           => "c3e4b0f8-55cb-11ea-2926-15256bba5781",
    "LanguageServer"  => "2b0e0bc5-e4fd-59b4-8912-456d1b03d8d7",
    "Plotly"          => "58dd65bb-95f3-509e-9936-c39a10fdeae7",
    "PlutoPlotly"     => "8e989ff0-3d88-8e9f-f020-2b208a939ff0",
    "SymPyPythonCall" => "bc8888f7-b21e-4b7c-a06a-5d9c9496438c",
    "DuckDB"          => "d2f5444f-75bc-4fdf-ac35-56f514c445e1",
    "Dynare"          => "5203de40-99df-439e-afbc-014de65cb9ef",
)

# Template packages (Julia side) and what they need on the Python side
# (PythonPlot -> matplotlib, SymPyPythonCall -> sympy). With the CondaPkg
# backend disabled, these must live in the uv-managed venv.
# Note: the legacy Plotly.jl wrapper is NOT in the template (see --plotly): its
# latest release pins HTTP 0.9, which forces the resolver to downgrade Pluto to
# 0.14.x (broken on recent Julia). PlutoPlotly already brings PlotlyBase.
const BASE_JULIA = ["PythonCall", "PythonPlot", "IJulia", "Pluto",
                    "LanguageServer", "PlutoPlotly", "SymPyPythonCall"]
const BASE_PYTHON = ["matplotlib", "sympy"]

struct Extra
    julia::Vector{String}    # Julia-native packages -> Project.toml
    python::Vector{String}   # Python packages       -> pyproject.toml (uv add)
end

const EXTRAS = Dict{Symbol,Extra}(
    :keras   => Extra(String[],   ["keras", "torch"]),  # Keras 3 needs a backend
    :pytorch => Extra(String[],   ["torch"]),
    :duckdb  => Extra(["DuckDB"], String[]),            # native client available
    :polars  => Extra(String[],   ["polars"]),          # no mature native package
    :dynare  => Extra(["Dynare"], String[]),            # native (Dynare.jl)
    :plotly  => Extra(["Plotly"], String[]),            # legacy; may hold Pluto back
)

const ALIASES = Dict("torch" => "pytorch")
const VALUE_OPTIONS = ("dir", "name", "python")

# ------------------------------------------------------------------ options

Base.@kwdef mutable struct Options
    dir::String = pwd()
    name::Union{Nothing,String} = nothing
    python::Union{Nothing,String} = nothing
    all::Bool = false
    force::Bool = false
    uv::Bool = true
    extras::Set{Symbol} = Set{Symbol}()
end

# Commands are values of type Val{:name}, dispatched on by `exec`.
const COMMANDS = Dict{String,Val}(
    "init" => Val(:init),
    "lock" => Val(:lock),
    "sync" => Val(:sync),
)

# What `--all` chains after each command.
next_command(::Val{:init}) = Val(:lock)
next_command(::Val{:lock}) = Val(:sync)
next_command(::Val)        = nothing

function take_value(rest, i, inline, key)
    if inline !== nothing
        return String(inline), i
    end
    i < length(rest) || die("option --$key requires a value")
    return String(rest[i + 1]), i + 1
end

function parse_args(args::Vector{String})
    isempty(args) && exit_usage(1)
    head, rest = args[1], args[2:end]
    head in ("-h", "--help", "help") && exit_usage(0)

    cmd = get(COMMANDS, head) do
        logmsg("unknown command: $head"; level = "ERROR")
        exit_usage(1)
    end

    opts = Options()
    i = 1
    while i <= length(rest)
        arg = rest[i]
        arg in ("-h", "--help") && exit_usage(0)

        m = match(r"^--([A-Za-z][\w-]*)(?:=(.*))?$", arg)
        if m === nothing
            startswith(arg, "-") && die("unknown option: $arg")
            isnothing(opts.name) || die("unexpected argument: $arg")
            opts.name = arg
        else
            key = String(m.captures[1])
            key = get(ALIASES, key, key)
            inline = m.captures[2]
            if key ∉ VALUE_OPTIONS && inline !== nothing
                die("option --$key does not take a value")
            end

            if key == "dir"
                opts.dir, i = take_value(rest, i, inline, key)
            elseif key == "name"
                opts.name, i = take_value(rest, i, inline, key)
            elseif key == "python"
                opts.python, i = take_value(rest, i, inline, key)
            elseif key == "all"
                opts.all = true
            elseif key == "force"
                opts.force = true
            elseif key == "no-uv"
                opts.uv = false
            elseif haskey(EXTRAS, Symbol(key))
                push!(opts.extras, Symbol(key))
            else
                die("unknown option: --$key")
            end
        end
        i += 1
    end

    opts.dir = abspath(opts.dir)
    if !(cmd isa Val{:init})
        isnothing(opts.name) || die("a project name is only valid for 'init'")
        isempty(opts.extras) || die("integration options are only valid for 'init'")
        opts.force && die("--force is only valid for 'init'")
    end
    return cmd, opts
end

# ------------------------------------------------------------------ helpers

project_file(o::Options)  = joinpath(o.dir, "Project.toml")
manifest_file(o::Options) = joinpath(o.dir, "Manifest.toml")

function require_project(o::Options)
    isfile(project_file(o)) ||
        die("no Project.toml in $(o.dir); run 'juliactl init' first")
end

# Name: explicit > pyproject.toml [project].name > directory name.
function deduce_name(o::Options)
    o.name !== nothing && return o.name
    pyproject = joinpath(o.dir, "pyproject.toml")
    if isfile(pyproject)
        project = get(TOML.parsefile(pyproject), "project", Dict{String,Any}())
        name = get(project, "name", nothing)
        name isa AbstractString && return String(name)
    end
    return basename(realpath(o.dir))
end

# Selected packages for one side ("julia" or "python"): template + integrations.
function requirements(o::Options, field::Symbol, base::Vector{String})
    pkgs = copy(base)
    for e in sort!(collect(o.extras))
        append!(pkgs, getproperty(EXTRAS[e], field))
    end
    return unique!(pkgs)
end

# ---------------------------------------------------------- python/uv bridge

function venv_python(venv::AbstractString)
    for parts in (("bin", "python"), ("Scripts", "python.exe"))
        py = joinpath(venv, parts...)
        isfile(py) && return py
    end
    return nothing
end

# Python of the active uv environment: --python > $VIRTUAL_ENV > ./.venv
function find_python(o::Options)
    o.python !== nothing && return something(Sys.which(o.python), abspath(o.python))
    for venv in (get(ENV, "VIRTUAL_ENV", ""), joinpath(o.dir, ".venv"))
        isempty(venv) && continue
        py = venv_python(venv)
        py === nothing || return py
    end
    return nothing
end

# Make PythonCall use the uv venv instead of a CondaPkg-managed environment.
function configure_python!(o::Options)
    py = find_python(o)
    if py === nothing
        logmsg("no uv/venv Python found (VIRTUAL_ENV or .venv); PythonCall keeps its defaults";
               level = "WARN")
        return nothing
    end
    if o.python !== nothing || !haskey(ENV, "JULIA_PYTHONCALL_EXE")
        ENV["JULIA_PYTHONCALL_EXE"] = py
    end
    get!(ENV, "JULIA_CONDAPKG_BACKEND", "Null")
    logmsg("PythonCall -> $(ENV["JULIA_PYTHONCALL_EXE"]) (CondaPkg backend: $(ENV["JULIA_CONDAPKG_BACKEND"]))")
    return py
end

normalize_pyname(s::AbstractString) = lowercase(replace(s, r"[-_.]+" => "-"))

function declared_python_deps(pyproject::AbstractString)
    isfile(pyproject) || return String[]
    project = get(TOML.parsefile(pyproject), "project", Dict{String,Any}())
    deps = get(project, "dependencies", String[])
    return [normalize_pyname(m.match) for d in deps
            for m in (match(r"^[A-Za-z0-9][A-Za-z0-9._-]*", d),) if m !== nothing]
end

function add_python_requirements(o::Options)
    wanted = requirements(o, :python, BASE_PYTHON)
    pyproject = joinpath(o.dir, "pyproject.toml")
    have = declared_python_deps(pyproject)
    todo = filter(p -> normalize_pyname(p) ∉ have, wanted)
    if isempty(todo)
        logmsg("python requirements already declared in pyproject.toml")
        return
    end

    manual = "uv add " * join(todo, " ")
    uv = Sys.which("uv")
    if !o.uv || uv === nothing || !isfile(pyproject)
        logmsg("python requirements not installed automatically; run: $manual"; level = "WARN")
        return
    end

    logmsg("running: $manual")
    try
        run(Cmd(`$uv add $todo`; dir = o.dir))
    catch err
        logmsg("uv add failed ($(sprint(showerror, err))); run manually: $manual"; level = "WARN")
    end
    return
end

# ----------------------------------------------------------------- commands

function exec(::Val{:init}, o::Options)
    logmsg(":> INIT, ...")
    mkpath(o.dir)
    path = project_file(o)

    merging = isfile(path) && !o.force
    doc = merging ? TOML.parsefile(path) : Dict{String,Any}()
    if merging
        logmsg("Project.toml exists: adding missing packages only (--force recreates it)")
    else
        doc["name"] = deduce_name(o)
    end

    deps = get!(doc, "deps", Dict{String,Any}())
    added = String[]
    for pkg in requirements(o, :julia, BASE_JULIA)
        haskey(deps, pkg) && continue
        deps[pkg] = get(REGISTRY_UUIDS, pkg) do
            die("no registry UUID known for $pkg")
        end
        push!(added, pkg)
    end

    if !merging || !isempty(added)
        open(path, "w") do io
            TOML.print(io, doc; sorted = true)
        end
    end
    logmsg(isempty(added) ? "Project.toml unchanged" :
           "Project.toml: added " * join(added, ", "))

    add_python_requirements(o)

    py = configure_python!(o)
    if py !== nothing
        logmsg("for plain julia sessions: export JULIA_CONDAPKG_BACKEND=Null JULIA_PYTHONCALL_EXE=$py")
    end
    logmsg(":< INIT, done.")
end

function exec(::Val{:lock}, o::Options)
    logmsg(":> LOCK, ...")
    require_project(o)
    configure_python!(o)
    Pkg.activate(o.dir)
    # Pkg has no resolve-only upgrade: update() also fetches sources.
    # Precompilation is left to 'sync'.
    withenv("JULIA_PKG_PRECOMPILE_AUTO" => "0") do
        Pkg.update()
    end
    # Packages held back by [compat] constraints are marked and their blockers listed.
    logmsg("packages not at their latest version (and why):")
    Pkg.status(; outdated = true)
    logmsg(isfile(manifest_file(o)) ? "wrote $(manifest_file(o))" :
           "Manifest.toml was not created"; level = isfile(manifest_file(o)) ? "LOG" : "WARN")
    logmsg(":< LOCK, done.")
end

function exec(::Val{:sync}, o::Options)
    logmsg(":> SYNC, ...")
    require_project(o)
    isfile(manifest_file(o)) ||
        logmsg("no Manifest.toml: resolving first (run 'juliactl lock' to upgrade)"; level = "WARN")
    configure_python!(o)
    Pkg.activate(o.dir)
    Pkg.instantiate(; allow_autoprecomp = false)
    # strict: a package that fails to precompile (e.g. Pluto) makes 'sync' fail
    Pkg.precompile(; strict = true)
    logmsg(":< SYNC, done.")
end

function run_pipeline(cmd, o::Options)
    while cmd !== nothing
        exec(cmd, o)
        cmd = o.all ? next_command(cmd) : nothing
    end
end

function main(args = ARGS)
    cmd, opts = parse_args(String.(args))
    try
        run_pipeline(cmd, opts)
    catch err
        err isa InterruptException && rethrow()
        logmsg(sprint(showerror, err); level = "ERROR")
        exit(1)
    end
end

isinteractive() || main()
