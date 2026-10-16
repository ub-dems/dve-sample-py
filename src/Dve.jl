"""

`Dve` Julia Module.

- see: notes/howtos/Julia*.{md,pdf}
- see: notes/samples/julia/


"""
module Dve

using PythonCall
using DataFrames: DataFrame
using Statistics: mean

export hello_world, scaled_mean, add_total


# -------------------------------------------------------------------------

export r_available

"""
    r_available() -> Bool

Return `true` if an R executable is discoverable through PATH.
This does not verify that R can start successfully.
"""
function r_available()::Bool
    Sys.which("R") !== nothing
end

"""
    r_works() -> Bool

Return `true` if R can be launched and reports its version.
"""
function r_works()::Bool
    r = Sys.which("R")
    isnothing(r) && return false

    try
        run(pipeline(`$r --version`, devnull))
        return true
    catch
        return false
    end
end


##
# RCall.jl extension
# see: `ext/DveRCallExt.jl`

function rcall_extension_loaded()::Bool
    Base.get_extension(Dve, :DveRCallExt) !== nothing
end


"Convert an R object to a DataFrame. Methods are added by the RCall extension."
function from_r end

"Convert a DataFrame to an R object. Methods are added by the RCall extension."
function to_r end

# -------------------------------------------------------------------------


"""
    hello_world(salutation, who) -> String

Return a formatted greeting, e.g. `hello_world("Hello", "Julia") == "Hello, Julia!"`.
"""
function hello_world(salutation::AbstractString, who::AbstractString)
    isempty(strip(salutation)) && throw(ArgumentError("salutation must not be empty"))
    return string(salutation, ", ", who, "!")
end

"Mean of `v` multiplied by `factor` (primitive/vector example for the bridges)."
scaled_mean(v::AbstractVector{<:Real}, factor::Real = 1) = mean(v) * factor

"""
    add_total(tbl) -> DataFrame

Accept any Tables.jl-compatible table with numeric columns `x` and `y`,
return a new `DataFrame` with an extra column `total = x + y`.
"""
function add_total(tbl)
    df = DataFrame(tbl)          # copies columns by default
    df.total = df.x .+ df.y
    return df
end


end # module
