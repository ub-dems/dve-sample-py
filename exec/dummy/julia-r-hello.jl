#!./julia-r.sh

##
# julia-r ('rcall' environment) test
#

# usage: run script from project root
#
# ./exec/dummy/julia-r-hello.jl ...
#

using Printf

using Pkg

Pkg.status()


using RCall

r_sessioninfo = rcall(:sessionInfo)
r_sum = rcall(:sum, Float64[1.0, 4.0, 6.0])

@printf "r_sessioninfo=%s\n" r_sessioninfo
@printf "r_sum=%s\n" r_sum

jmtcars = reval("mtcars");

println(names(jmtcars))



r_salutation = "Hi"

@rput r_salutation

@rlibrary devtools

"""R
devtools::load_all(".")
r_hello <- dmy_hello(salutation=r_salutation)
#r_hello <- dmy_hello()
print("R>", "r_hello", r_hello)
"""

@rget r_hello
print("r_hello=")
println(r_hello)
#@printf "r_hello=%s\n" r_hello



"""R
library(JuliaCall)
julia_setup()
julia_library("Pkg")
jl_status <- julia_eval("Pkg.status()")
"""

@rget jl_status
print("jl_status=")
println(jl_status)



"""R
julia_library("Dve")
jl_hello <- julia_call("Dve.hello_world","Bonjour","Marianne")
print("R>", "jl_hello", jl_hello)
"""

@rget jl_hello
print("jl_hello=")
println(jl_hello)



