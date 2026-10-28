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
# # NVIDIA system check

# %% language="bash"
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
# echo "X_HAS_GPU=$X_HAS_GPU"
# echo "X_UV_EXTRA=$X_UV_EXTRA"

# %%
# !echo $PATH | tr ':' '\n'

# %%
# !which -a nvidia-smi

# %%
# !nvidia-smi

# %%
# !nvidia-smi --version

# %%
# !nvidia-smi -L

# %%
# !lspci

# %%
# ! ldd $(which nvidia-smi)

# %%
# !apt list --installed | grep -i -e nvidia -e cuda -e blas -e cudnn

# %%
# !nvidia-smi -q

# %%
# !uv pip list | grep -e keras -e torch -e tensorflow -e ^nv

# %%
# ! uv tree --no-dedupe --no-group jupyter --show-sizes | grep -i -e nvidia -e torch -e keras -e tensorflow

# %%
# ! uv tree --no-dedupe --no-group jupyter --show-sizes

# %%
