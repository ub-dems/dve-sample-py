# ---
# jupyter:
#   jupytext:
#     formats: ipynb,R:percent
#     text_representation:
#       extension: .R
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.6
#   kernelspec:
#     display_name: R
#     language: R
#     name: ir
# ---

# %% [markdown]
# # R JuliaCall Interoperation

# %% [markdown]
# ## JuliaCall References
#
# * [GitHub: JuliaCall](https://github.com/JuliaInterop/JuliaCall)
# * [CRAN: JuliaCall](https://cran.r-project.org/web/packages/JuliaCall/index.html)
# * [JuliaCall in Jupyter R Notebook](https://cran.r-project.org/web/packages/JuliaCall/vignettes/JuliaCall_in_Jupyter_R_Notebook.html)
# * [JuliaCall Reference](https://cran.r-project.org/web/packages/JuliaCall/refman/JuliaCall.html)

# %% [markdown]
# ## R Environment

# %%
getwd()

# %%
setwd("../..")

# %%
getwd()

# %%
source(".Rprofile")

# %%
sessionInfo()

# %%
renv::status()

# %% [markdown]
# ## Julia Environment

# %%
system("env | grep ^JULIA", intern = TRUE)

# %% [markdown]
# ## JuliaCall Session

# %%
library("JuliaCall")

# %%
julia_setup()

# %%
julia_library("Pkg")

# %%
julia_eval("Pkg.status()")

# %% [markdown]
# ## Julia Plots

# %%
julia_library("Plots")

# %%
