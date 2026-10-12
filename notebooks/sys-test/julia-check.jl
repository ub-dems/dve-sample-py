# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     formats: ipynb,jl:percent
#     text_representation:
#       extension: .jl
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.6
#   kernelspec:
#     display_name: Julia 1.13
#     language: julia
#     name: julia-1.13
# ---

# %% [markdown]
# # Julia Environment Check
#
#
# ## Language Integrations
#
# - "R -> Julia": see CRAN Package ["JuliaCall"](https://cran.r-project.org/web/packages/JuliaCall/)
# - "Python -> Julia": see PYPI Package ["juliacall"](https://pypi.org/project/juliacall/)
# - "Julia -> Python"; see Julia Package: ["PythonCall"](https://juliapy.github.io/PythonCall.jl/stable/)
#
# ## Julia References
#
# - [Julia Documentation](https://docs.julialang.org/en/v1/)
# - [Tutorials](https://julialang.org/learning/tutorials/)
# - [Plots Gallery](https://docs.juliaplots.org/stable/gallery/gr/)
# - [SynPyCore.jj - Calculus](https://jverzani.github.io/SymPyCore.jl/stable/Tutorial/calculus/)
#
#

# %%
VERSION

# %%
versioninfo()

# %%
macro bash_str(s) open(`bash`,"w",stdout) do io; print(io, s); end; end


# %%
bash"""

 env | grep -e '^JULIA'

"""

# %% [markdown]
# ## Plotting

# %%
### `Plots` examples

# %%
using Pkg

# %%
# Pkg.add("Plots")

# %%
# Pkg.build("Plots")

# %%
using Plots

# %%
x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)
y3 = @. sin(x)^2 - 1/2

plot(x, [y1 y2], label=["sin(x)" "cos(x)"], lw=[2 1])
plot!(x, y3, label="sin(x)^2 - 1/2", lw=3, ls=:dot)
plot!(legend=:outerbottom, legendcolumns=3)
xlims!(0, 2pi)
title!("Trigonometric functions")
xlabel!("x")
ylabel!("y")

# %% [markdown]
# ## Python Integration

# %%
using PythonCall


# %% [markdown]
# ### Stdandard lib Example

# %%
math = pyimport("math")
math.sin(math.pi / 4) # returns ≈ 1/√2 = 0.70710678...

# %% [markdown]
# ### `pandas` Dataframe Example

# %%
pd = pyimport("pandas")
pyio = pyimport("io")

data = Dict(
    "column1" => ["a", "b", "c", "d", "e"],
    "column2" => ["data1", "data2", "data1", "data3", "data3"],
    "column3" => [0, 0, 0, 0, 0]
)
df = pd.DataFrame(pydict(data))

println("--- DataFrame Structure ---")
buf = pyio.StringIO()
df.info(buf=buf)
println(buf.getvalue())

for _ in 1:3
    mask = df["column2"].isin(pylist(["data2", "data3"]))
    df.loc[mask, "column3"] = df.loc[mask, "column3"].add(1)
end

println("--- SELECT 1: Ordered Data ---")
select1 = df.sort_values(by=pylist(["column2", "column1"]), ascending=pylist([true, false]))
display(select1)

println("\n--- SELECT 2: Grouped & Filtered Data ---")
grouped = df.groupby("column2")["column3"].sum().reset_index(name="tot3")
filtered = grouped[grouped["tot3"].gt(0)]
select2 = filtered.sort_values(by=pylist(["tot3", "column2"]), ascending=pylist([false, true]))
display(select2)

# %% [markdown]
# ### @pyexec Macro

# %%
@pyexec """
           global re
           import re

           def my_sentence(s):
               words = re.findall("[a-zA-Z]+", s)
               sentence = " ".join(words)
               return sentence
           """ => my_sentence

sentence = my_sentence("PythonCall.jl is very useful!")

# %% [markdown]
# ### Python `JuliaCall` Example

 # %%
 @pyexec """
           global jl, jx
           from juliacall import Main as jl

           def my_question(x, y=7):
               answer = jl.eval(jl.Meta.parse(f"{x} * {y}"))
               return answer
           """ => my_question
answer = my_question(6)

# %%
