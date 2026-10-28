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
# @see [Plotly with Pandas dataframe side by side in Jupyter notebook](https://stackoverflow.com/questions/76604620/plotly-with-pandas-dataframe-side-by-side-in-jupyter-notebook)

# %% [markdown]
# @see [Plotly: Gallery of IPython Notebooks in Python/v3](https://plotly.com/python/v3/ipython-notebooks/)

# %%
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# %%
df = px.data.iris()
fig = px.scatter(df, x="sepal_width", y="sepal_length")
fig.show()

# %%
# Simple pandas dataframe
df[["sepal_length", "species"]].groupby("species").agg(["mean", "count", "median", "min", "max"])

# %%
df = px.data.iris()

specs = [[{"type": "xy"}, {"type": "table"}]]

fig = make_subplots(rows=1, cols=2, specs=specs, subplot_titles=["A Scatter Plot", "A DataFrame"])
fig.add_trace(go.Scatter(x=df.index, y=df["petal_length"].values), row=1, col=1)

fig.add_trace(
    go.Table(header={"values": df.columns}, cells={"values": (df.transpose().values.tolist())}),
    row=1,
    col=2,
)

fig.update_layout(template="plotly_dark")
fig.show()

# %%
