# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.6
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %% [markdown]
# # py-sympy-hello: python symbolic math demo
#
# ## sympy
#
# - [SymPy documentation](https://docs.sympy.org/latest/index.html)
# - [SymPy Features](https://docs.sympy.org/latest/tutorials/intro-tutorial/features.html)
# - [SymPy Plotting Backends](https://sympy-plot-backends.readthedocs.io/en/latest/index.html)
#

# %%
##
#  ruff: disable[B018,E501,F811]
#  pyright: reportUnusedExpression=false

# %%
from sympy import init_printing, symbols, Function, Derivative, Integral, Eq, integrate, diff, dsolve, checkodesol, oo, exp, sin
from sympy.abc import x
from spb import plot

init_printing()



# %% [markdown]
# ## Integral

# %%
x, y, z, t = symbols("x y z t")

# %%
f = exp(-(x**2) - y**2)
F = f , (x, -oo, oo), (y, -oo, oo)

# %%
Integral(*F)

# %%
integrate(*F)

# %% [markdown]
# ## Derivative

# %%
g = sin(x) / x

# %%
dg = diff(g)

# %%
g

# %%
dg

# %%
plot(g, dg)

# %% [markdown]
# ## Differential Equation (ODE)

# %%
y = Function("y")
eq = Derivative(y(x), x, x) + 9*y(x)
Eq(eq,0)

# %%
sol = dsolve(eq, y(x))
sol

# %%
checkodesol(eq, sol)

# %%
# ruff: enable[B018,E501,F811]
