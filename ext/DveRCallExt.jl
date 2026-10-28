module DveRCallExt

using Dve
using RCall
using DataFrames: DataFrame


"""
    r_version()

Return the R version reported through RCall.
"""
function r_version()
    RCall.rcopy(RCall.reval("R.version.string"))
end



Dve.from_r(x::RObject) = rcopy(DataFrame, x)   # copies
Dve.to_r(df::DataFrame) = robject(df)          # copies

end # module
