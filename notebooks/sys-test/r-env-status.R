# ---
# jupyter:
#   jupytext:
#     formats: ipynb,R:percent
#     text_representation:
#       extension: .R
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.5
#   kernelspec:
#     display_name: R
#     language: R
#     name: ir
# ---

# %% [markdown]
# # r-env-status: check R environment
#
# ## R configuration
#
# - see: `DESCRIPTION`
# - see: [renv: Project Environments](https://rstudio.github.io/renv/)
#
# ## R venv upgrade
#
# ### venv direct update
#
# ```R
#
# # ---(main node)----------------------------------------
#
# renv::install()
# renv::status()
# renv::snapshot()
# renv::status()
#
# # ---(sec. node)----------------------------------------
#
# renv::status()
# renv::restore()
# renv::status()
#
#
# ```
# ### venv command update
#
# ```bash
#
# # out-of-container environment (.venv)
# ./setup.sh --help
#
# # in-container environment (.venv.cdk)
# ./runtime.sh --help
# ./build.sh --help
#
# ```

# %%
sessionInfo()

# %%
renv::status()

# %%
renv::diagnostics()

# %%
