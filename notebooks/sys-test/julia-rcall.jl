# ---
# jupyter:
#   jupytext:
#     formats: jl:percent,ipynb
#     text_representation:
#       extension: .jl
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.6
#   kernelspec:
#     display_name: "Julia\u2014RCall 1.13"
#     language: julia
#     name: julia_rcall-1.13
# ---

# %% [markdown]
# # Julia RCall.jl Interoperation

# %% [markdown]
# ## RCall Reference
#
# * [RCall.jl](https://juliainterop.github.io/RCall.jl/)
# * [Getting Started](https://juliainterop.github.io/RCall.jl/stable/gettingstarted/)

# %% [markdown]
# ## Project Rcall Environment

# %% [markdown]
# ```bash
#
# ls -1 ./etc/julia/envs/rcall
#
# LocalPreferences.toml
# Manifest.toml
# Project.toml
#
# ```

# %%
macro bash_str(s) open(`bash`,"w",stdout) do io; print(io, s); end; end

# %%
bash"""
 env | grep -e '^JULIA'
"""

# %% [markdown]
# ## LDCONFIG Required Configuration

# %% [markdown]
# *required*
#
# in `./docker/r-images/build.conf`
#
# ```bash
# # ---(ld)---------------------------
#
# Y_RE_LD_CONFIG=1
#
# ```
#

# %%
bash"""
 ls -l /etc/ld.so.conf.d/  
 find  /etc/ld.so.conf.d/ -type f -exec cat {} \;
"""

# %%
bash"""
 ldd /usr/local/lib/R/lib/libR.so
"""

# %%
bash"""
 ldd /usr/local/lib/R/library/utils/libs/utils.so
"""

# %% [markdown]
# ## Julia Environment

# %%
using Pkg

# %%
Pkg.status()

# %% [markdown]
# ## RCall Session

# %%
pwd()

# %%
cd("../..")

# %%
pwd()

# %%
using RCall

# %%
R"""
sessionInfo()
"""

# %%
R"""
renv::status()
R.version.string
"""

# %% [markdown]
# ## @rput and @rget macros

# %%
z = 1
@rput z
R" z "

# %%
R" r <- 2 "
@rget r
r

# %% [markdown]
# ## RCall API

# %%
jmtcars = reval("mtcars")
names(jmtcars)

# %%
rcall(:sum, Float64[1.0, 4.0, 6.0])

# %%
rcopy(R"c(1, 2)")

# %%
rcopy(R"list(a = 1, b= 'zz')")

# %%
robject(Dict(:a => 1, :b => 2))

# %% [markdown]
# ## @rlibrary and @rimport macros

# %%
@rlibrary boot

city = rcopy(R"boot::city") 

# %%
@rimport base as rbase

rbase.sum([1, 2, 3], var"rm.na" = true)

# %%
