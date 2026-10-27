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


# exit()



