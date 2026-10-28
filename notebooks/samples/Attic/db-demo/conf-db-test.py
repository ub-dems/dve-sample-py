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
import logging
import sys

# %%
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# %%
from sqlalchemy import create_engine

# %%
from dve.config import conf

from dve.config.data import DATA_TEST

# %%
logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)

log = logging.getLogger(__name__)

plt.set_loglevel("info")

# %%
cnf = conf.get_config()

# %%
demo_uri = conf.get_config().db("demo").uri()

# %%
print(f"demo_uri: {conf.get_config().db('demo').dump()}")
print(f"demo_dsa: {conf.get_config().db('demo').dump(full=True)}")
print(f"demo_dsc: {conf.get_config().db('demo_my').dump(full=True)}")

# %%
# !echo "sudo mysql -e 'show databases;'"

# %%
# !pwd
# !ls -l ../../src/dve/resources/sql/my/demo-init.sql
# !echo "sudo mysql < ./src/dve/resources/sql/my/demo-init.sql"

# %%
# !mysql --user=demo --password='<Sec3et!>'  -e 'show databases;' demo

# %%
# !pwd
# !ls -l ../../data/int/test/iris.int/iris-ds/raw
# !wc -l ../../data/int/test/iris.int/iris-ds/raw/Iris.csv
# !head  ../../data/int/test/iris.int/iris-ds/raw/Iris.csv

# %%
iris_fn = DATA_TEST + "/iris.int/iris-ds/raw/Iris.csv"
print(iris_fn)

# %%
df = pd.read_csv(iris_fn)
print(df)

# %%
ax = df.plot.scatter(x="SepalLengthCm", y="SepalWidthCm", color="Blue", label="sepal")
df.plot.scatter(x="PetalLengthCm", y="PetalWidthCm", color="red", label="petal", ax=ax)

# %%
df1 = df.copy().drop(columns=["Id"])
df1

# %%
sns.pairplot(data=df1, hue="Species")

# %%
print(f"demo_uri: {conf.get_config().db('demo').dump()}")
demo_uri = conf.get_config().db("demo").uri()

# %%
engine = create_engine(demo_uri, echo=False)

# %%
df.copy().reset_index().to_sql(name="iris", con=engine, if_exists="replace")

# %%
with engine.connect() as con:
    rs = con.execute("SELECT Species, count(*) as n FROM iris GROUP BY Species")
    for row in rs:
        print(row)

# %%
with engine.connect().execution_options(autocommit=True) as conn:
    df_stats = pd.read_sql(
        """
    SELECT Species,
       AVG(PetalLengthCm) as PetalLengthCm_avg, STDDEV_SAMP(PetalLengthCm) as PetalLengthCm_std,
       AVG(PetalWidthCm)  as PetalWidthCm_avg,  STDDEV_SAMP(PetalWidthCm)  as PetalWidthCm_std,
       AVG(SepalLengthCm) as SepalLengthCm_avg, STDDEV_SAMP(SepalLengthCm) as SepalLengthCm_std,
       AVG(SepalWidthCm)  as SepalWidthCm_avg,  STDDEV_SAMP(SepalWidthCm)  as SepalWidthCm_std
       FROM iris
       GROUP BY Species
    """,
        con=conn,
    )

df_stats

# %%
df_stats.plot(
    x="Species",
    y=["PetalLengthCm_avg", "PetalWidthCm_avg", "SepalLengthCm_avg", "SepalWidthCm_avg"],
    kind="barh",
)

# %%
