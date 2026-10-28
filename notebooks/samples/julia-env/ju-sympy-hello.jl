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
# # jl-sympy-hello: julia symbolic math demo
#
# ## SymPyPythonCall
#
# - [SymPy documentation](https://docs.sympy.org/latest/index.html)
# - [SymPy Features](https://docs.sympy.org/latest/tutorials/intro-tutorial/features.html)
# - [SymPyPythonCall.jl](https://github.com/jverzani/SymPyPythonCall.jl)
# - [SymPy.jl documentation](https://jverzani.github.io/SymPyCore.jl/dev/)
#

# %%
using SymPyPythonCall
using Plots

# %% [markdown]
# ## Integral

# %%
@syms x y z t

# %%
f = exp(-x^2 - y^2)
F = (f, (x, -oo, oo), (y, -oo, oo))

# %%
sympy.Integral(F...)

# %%
integrate(F...)

# %% [markdown]
# ## Derivative

# %%
g = sin(x) / x

# %%
dg = diff(g, x)

# %%
g

# %%
dg

# %%
gf, dgf = lambdify(g), lambdify(dg)
plot([gf, dgf], -10, 10; label = ["g(x)" "g′(x)"], xlabel = "x")

# %% [markdown]
# ## Differential Equation (ODE)

# %%
@syms y()
eq = diff(y(x), x, 2) + 9y(x)
Eq(eq, 0)

# %%
sol = dsolve(eq, y(x))
sol

# %%
sympy.checkodesol(eq, sol)

# %% [markdown]
# ## Appendix: sympy-plot-backends (`spb`) via PythonCall
#
# The Python demo plots with `spb.plot`. To use that backend directly instead of
# `Plots.jl`, import it through `PythonCall` (the Python module must be installed
# in the uv virtualenv that `PythonCall` points to):
#
# ```julia
# using PythonCall
# spb = pyimport("spb")
# spb.plot(g, dg)
# ```
