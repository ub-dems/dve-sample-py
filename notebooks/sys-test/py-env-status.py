# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.5
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %% [markdown]
# # py-env-status: check python environment
#
# ## python configuration
#
# - see: `pyproject.toml`
# - see: [Astral `uv`](https://docs.astral.sh/uv/)
#
# ## python venv upgrade
#
# ### venv direct update
#
# ```bash
#
# # ------------------------------------------------------
#
# (type nvidia-smi && nvidia-smi -L) &> /dev/null \
#     && X_HAS_GPU=1 || X_HAS_GPU=0;
#
# case "$X_HAS_GPU" in
#      1) export X_UV_EXTRA='gpu' ;;
#      *) export X_UV_EXTRA='cpu' ;;
# esac
# export X_HAS_GPU
#
# # ------------------------------------------------------
#
#
#
# uv lock
# uv sync --extra=$X_UV_EXTRA --all-groups
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

# %%
# %env

# %%
# !uv --version; node --version; rustc --version; python --version; julia --version

# %%
# !uv python list

# %%
# ! poetry env info

# %%
# ! uv pip list

# %%
# ! uv tree  --no-dev --no-default-groups --no-dedupe --show-sizes

# %%
# ! uv tree --no-dedupe

# %%
# ! jupyter --version

# %%
# ! jupyter labextension list

# %%
# ! jupyter kernelspec list

# %%
