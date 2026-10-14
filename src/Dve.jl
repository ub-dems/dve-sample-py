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
