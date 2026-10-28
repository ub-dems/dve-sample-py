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
# # pivot_table: pandas demo
#
# for better (Rust-based) implementtion (10x+ speed increase) look at:
#
# - [duckdb](https://duckdb.org/)
# - [Polars vs Pandas](https://pola.rs/)
#
#

# %%
import pandas as pd

# %%
data = {
    "Name": ["Alice", "Bob", "Charlie", "Alice", "Bob", "Charlie"],
    "Age": [25, 30, 35, 28, 31, 36],
    "City": ["New York", "Los Angeles", "Chicago", "New York", "Los Angeles", "Chicago"],
    "Sales": [200, 150, 100, 300, 250, 200],
}
df = pd.DataFrame(data)

# %%
print(df.head())

# %%
print(df.info())

# %%
pd.pivot_table(
    df,
    values="Sales",
    index="City",
    columns="Name",
    aggfunc="mean",
    fill_value=0,
    margins=True,
    dropna=True,
    margins_name="Total",
    observed=False,
)

# %%
# Sample data
data = {
    "Date": ["2023-01-01", "2023-01-01", "2023-01-01", "2023-01-01", "2023-01-02", "2023-01-02"],
    "City": ["New York", "New York", "New York", "Los Angeles", "New York", "Los Angeles"],
    "Sales": [200, 100, 300, 150, 300, 250],
}

df = pd.DataFrame(data)

# Creating a pivot table
pivot = pd.pivot_table(df, values="Sales", index="Date", columns="City", aggfunc="sum")
print(pivot)

# %%
data = {
    "Date": ["2023-01-01", "2023-01-01", "2023-01-01", "2023-01-01", "2023-01-02", "2023-01-02"],
    "City": ["New York", "New York", "New York", "Los Angeles", "New York", "Los Angeles"],
    "Product": ["A", "A", "B", "B", "A", "B"],
    "Sales": [200, 100, 300, 150, 300, 250],
}

df = pd.DataFrame(data)

# Multi-index pivot table
pivot = pd.pivot_table(df, values="Sales", index=["Date", "City"], columns="Product", aggfunc="sum")
print(pivot)

# %%
# Using multiple aggregation functions
pivot = pd.pivot_table(df, values="Sales", index="Date", columns="City", aggfunc=["sum", len])
print(pivot)

# %%
# Filling missing values with 0
pivot = pd.pivot_table(df, values="Sales", index="Date", columns="City", aggfunc="sum", fill_value=0)
print(pivot)

# %%
# Styling the pivot table
styler = pivot.style
styler.format("${:.2f}")
styler.background_gradient(cmap="viridis")


# %%
# Renaming index and columns
pivot.rename(columns={"New York": "NY", "Los Angeles": "LA"}, inplace=True)
pivot.rename_axis("City", axis="columns", inplace=True)
pivot.rename_axis("Sales Date", axis="index", inplace=True)
print(pivot)

# %%
# Adding margins
pivot = pd.pivot_table(df, values="Sales", index="Date", columns="City", aggfunc="sum", margins=True)
print(pivot)

# %%
# Optimizing memory usage
df["Sales"] = df["Sales"].astype("int32")

# %%
df["Sales"]

# %%
df.head()
