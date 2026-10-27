#!./julia-r.sh

##
# julia-r ('rcall' environment) test
#

# usage: run script from project root
#
# ./exec/dummy/julia-r-hello.jl ...
#

using ArgParse
using Printf
using Dve

using Pkg

using RCall







r_salutation = "Hi"

# 1. Interpolate Julia variables directly into the R expression
r_hello = R"({
    devtools::load_all('.')
    dmy_hello(salutation = $r_salutation)
})"

print("r_hello=")
println(rcopy(r_hello)) # Safely convert back to a native Julia object


# 2. For calling Julia from R via JuliaCall inside the script:
"""R
library(JuliaCall)
julia_setup()
"""

# """R
# julia_library("Pkg")
# # Pass values explicitly or evaluate cleanly
# jl_status <- julia_eval("Pkg.status()")
# print("R>", "jl_status", jl_status)
# """


jl_hello = R"""({
         library(JuliaCall)
         julia_setup()
         julia_library("Dve")
         jl_hello <- julia_call("Dve.hello_world","Bonjour","Marianne")
         print(c("R>", "jl_hello", jl_hello))
         jl_hello
})"""

print("jl_hello=")
println(rcopy(jl_hello))







function parse_cli(args)
    s = ArgParseSettings(description = """
      Print a R and Julia greeting.

      Julia and R (in-process) interop demo.

      - Julia->R: "RCall.jl"   Julia Module 
      - R->Julia: "JuliaCall"  R Package (GitHub)

      see: src/Dve.jl
      see: R/dummy-fun.R

      NOTE:

      For R->Julia out-of-process interop,
      see CRAN "JuliaConnectoR" package

      """, preformatted_description = true,
      epilog = """
       run as (from project base directory):

        ./exec/dummy/julia-r-hello.jl Alice Bob
        ./exec/dummy/julia-r-hello.jl -F Alice Bob
        ./exec/dummy/julia-r-hello.jl -P Alice Bob
        ./exec/dummy/julia-r-hello.jl -v -s 'Bonjour'  Alice Bob
        ./exec/dummy/julia-r-hello.jl -v -F -s 'Bonjour'  Alice Bob
        ./exec/dummy/julia-r-hello.jl -v -P -s 'Bonjour'  Alice Bob
        ./exec/dummy/julia-r-hello.jl --demo
        ./exec/dummy/julia-r-hello.jl --help

      """, preformatted_epilog = true)
    @add_arg_table! s begin
        "--full", "-F"
        help = "enable JuliaCall (R->Julia) callbacks"
        action = :store_true
        "--proc", "-P"
        help = "enable JuliaConnectoR (R->Julia) sub-process calls"
        action = :store_true
        "--demo", "-D"
        help = "enable extra RCall demos"
        action = :store_true
        "--salutation", "-s"
        help = "greeting word"
        default = "Hello"
        "--verbose", "-v"
        help = "verbose logging"
        action = :store_true
        "who"
        help = "who to greet"
        nargs = '*'
        required = true
    end
    opts = parse_args(args, s)

    verbose = opts["verbose"]
    if verbose
        for (arg,val) in opts
            println("  $arg  =>  $val")
        end
    end
    return opts
    
end


function show_julia_status()
    Pkg.status()
end    

function show_julia_status_cb()
    """R
    julia_library("Pkg")
    # Pass values explicitly or evaluate cleanly
    jl_status <- julia_eval("Pkg.status()")
    print("R>", "jl_status", jl_status)
    """
end    

function show_julia_status_px()
    """R
    juliaImport("Pkg")
    # Pass values explicitly or evaluate cleanly
    jl_status <- juliaEval("Pkg.status()")
    print("R>", "jl_status", jl_status)
    """
end    

function show_r_status()
    r_sessioninfo = rcall(:sessionInfo)
    @printf "r_sessioninfo=%s\n" r_sessioninfo

    jmtcars = reval("mtcars");
    println(names(jmtcars))
    
end

function rcall_demo()

    r_sum = rcall(:sum, Float64[1.0, 4.0, 6.0])
    @printf "r_sum=%s\n" r_sum
    
    
end    


function init_r_session()

    R"({
    devtools::load_all('.')
    })"
    
end    

function init_julia_session_cb()

"""R
library(JuliaCall)
# julia_setup() ### disable julia session nesting
# julia_library("Dve")
"""
    
end    

function init_julia_session_px()

"""R
library(JuliaConnectoR)
juliaImport("Dve")
"""
    
end    


function hello_from_r(salutation, who)
    r_salutation = salutation

    # @rput r_salutation      # works in Julia REPL, script context mismatch 

    # 1. Interpolate Julia variables directly into the R expression
    r_hello = R"({
            # devtools::load_all('.')
            r_hello <- dmy_hello(salutation = $r_salutation)
            print(c('R>','r_hello','->',r_hello))
            r_hello

            })"

    # @rget r_hello          # works in Julia REPL, script context mismatch 

    print("r_hello=")
    println(rcopy(r_hello)) # Safely convert back to a native Julia object
    
end    

function hello_from_julia_cb(salutation, who)

jl_hello = R"""({
         # library(JuliaCall)
         # julia_setup()
         # julia_library("Dve")
         jl_hello <- julia_call("Dve.hello_world","Bonjour","Marianne")
         print(c("R>", "jl_hello", jl_hello))
         jl_hello
})"""

print("jl_hello=")
println(rcopy(jl_hello))
   
end    

function hello_from_julia_px(salutation, who)

jl_hello = R"""({
         # library(JuliaConnectoR)
         # juliaImport("Dve")
         jl_hello <- juliaCall("Dve.hello_world","Bonjour","Marianne")
         print(c("R>", "jl_hello", jl_hello))
         jl_hello
})"""

print("jl_hello=")
println(rcopy(jl_hello))
   
end    

function hello_from_julia(salutation, who)
    say = map( x -> hello_world(salutation, x), who)
    map(println,say)
end    

function shutdown(opts, rc)

    full = opts["full"]

    if full    
        R"""({

        # Explicitly close JuliaCall socket/connection before exit
        # to prevent event loop panic

        try(julia_command("exit()"), silent = TRUE)

        0

        })"""
    end
    
    # Clean teardown of RCall and embedded R before exiting
    try
        # Tell RCall/R to close open connections and finalize cleanly
        reval("q(save = 'no')")
    catch
        # Catch any harmless cleanup complaints
    end

    # Force a clean native exit without triggering the libuv stream panic
    Base.exit(rc)
    
end    

function process(opts)
    verbose = opts["verbose"]
    full = opts["full"]
    proc = opts["proc"]
    demo = opts["demo"]
    salutation = opts["salutation"]
    who = opts["who"]

    if verbose
        show_julia_status()
        show_r_status()
    end    

    if demo
        show_julia_status()
    end

    hello_from_julia(salutation, who)        
    
    hello_from_r(salutation, who)        
    
    if full

        init_julia_session_cb()
        
        if verbose
            show_julia_status_cb()
        end    

        hello_from_julia_cb(salutation, who)        
    end    
    
    if proc

        init_julia_session_px()
        
        if verbose
            show_julia_status_px()
        end    

        hello_from_julia_px(salutation, who)        
    end    
    
end    


function main(args = ARGS)
    opts = parse_cli(args)

    rc = process(opts)

    shutdown(opts, rc)
    
    return rc
end

abspath(PROGRAM_FILE) == (@__FILE__) && exit(main())
