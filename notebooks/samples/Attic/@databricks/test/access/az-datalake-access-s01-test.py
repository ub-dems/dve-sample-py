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
# ruff: noqa: F821, C419, E501

# %%
def mountData(mountPoint):
  if any([x.mountPoint == mountPoint for x in dbutils.fs.mounts()]):
    print("mount: {} already mounted, skip".format(mountPoint))
    return
  print("mount: {} mounting, ...".format(mountPoint))
  dbutils.fs.mount(
  source = "wasbs://b01@rs0sa0xt0si740d01.blob.core.windows.net",
  mount_point = mountPoint,
  extra_configs = {"fs.azure.account.key.rs0sa0xt0si740d01.blob.core.windows.net":dbutils.secrets.get(scope = "databricks-default-secret-scope", key = "DbksStorageKey29365")})
  print("mount: {} mounting, done".format(mountPoint))

mountData("/mnt/data/b01")
#display(dbutils.fs.mounts())


# %%
df = spark.read.options(header="True", inferSchema="True", delimiter=",").csv("/mnt/data/b01/test/basic/load/raw/Iris.csv")

# %%
df.printSchema()
df.cache()
df.count()

# %%
import seaborn as sns

df1= df.drop("Id").toPandas()
df1.head()
sns.pairplot(data=df1, hue="Species")

# %%
display(df)
