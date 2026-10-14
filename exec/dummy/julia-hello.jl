#!/usr/bin/env -S julia --project=@script
# Activate the environment that lives next to this file, independent of the
# caller's working directory. A plain `julia` shebang has no --project flag.

#import Pkg
#Pkg.activate(@__DIR__; io = devnull)

using ArgParse
using Dve

function parse_cli(args)
    s = ArgParseSettings(description = """
      Print a greeting built by Dve.hello_world.

      see: src/Dve.jl

      """, preformatted_description = true,
      epilog = """
       run as (from project base directory):

        ./exec/dummy/julia-hello.jl Alice Bob
        ./exec/dummy/julia-hello.jl -s Hi  Alice Bob
        ./exec/dummy/julia-hello.jl --help

      """, preformatted_epilog = true)
    @add_arg_table! s begin
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
    return parse_args(args, s)
end

function main(args = ARGS)
    opts = parse_cli(args)
    
    verbose = opts["verbose"]
    if verbose
        for (arg,val) in opts
            println("  $arg  =>  $val")
        end
    end
    
    salutation = opts["salutation"]
    who = opts["who"]
    say = map( x -> hello_world(salutation, x), who)
    map(println,say)
    
    return 0
end

abspath(PROGRAM_FILE) == (@__FILE__) && exit(main())
