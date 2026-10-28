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

# %%
import sys

print(sys.version)

# %%
import platform

print(platform.python_version())

# %%
# !python --version

# %%
import numpy as np

print (np.__version__)


# %%
import pandas as pd

print (pd.__version__)

# %%
import pyspark
print (pyspark.__version__)

