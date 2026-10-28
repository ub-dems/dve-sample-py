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
# # local-db-test: local database demo with "SQLite"
#
# for better (Rust-based) implementtion (10x+ speed increase) look at:
#
# - [duckdb](https://duckdb.org/)
# - [Polars vs Pandas](https://pola.rs/)

# %%
import logging
import sys
import subprocess
from pathlib import Path

# %%
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url

# %%
from dve.config import conf

# %%
logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)

log = logging.getLogger(__name__)

# %%
cnf = conf.get_config()

# %%
local_uri = conf.get_config().db("demo").uri()

# %%
print(f"local_uri: {conf.get_config().db('demo').dump()}")
print(f"local_dsc: {conf.get_config().db('demo').dump(full=True)}")

# %%
# ! pwd

# %%
# jupyter current dir ("./notebooks") adjustment
local_uri = local_uri.replace("///", "///../../")

# %%
print(local_uri)


# %%
def sql_bind(engine):
    def sql_exec(qry: str):
        # engine.begin() automatically commits the transaction on success
        with engine.begin() as con:
            rs = con.execute(text(qry))

        # safely check if the result set is iterable (e.g., SELECT queries)
        if rs.returns_rows:
            for row in rs:
                print(row)
        else:
            # For CREATE/INSERT/UPDATE, just print the result status
            print(f"Executed successfully. Rows affected: {rs.rowcount}")

    return sql_exec


def drop_database(uri: str):
    # 0. Parse the actual file path from the SQLAlchemy URI automatically
    db_file_path = make_url(uri).database

    if db_file_path is None:
        return None

    db_path = Path(db_file_path)

    # 1. Ensure parent directory exists (creates 'dbms' and any missing parent directories)
    db_path.parent.mkdir(parents=True, exist_ok=True)

    # 2. Delete main database file and temporary WAL/SHM journal files if present
    db_path.unlink(missing_ok=True)
    Path(f"{db_path}-wal").unlink(missing_ok=True)
    Path(f"{db_path}-shm").unlink(missing_ok=True)

    # 3. Ensure the parent directory exists
    db_path.parent.mkdir(parents=True, exist_ok=True)
    return db_path


# %%
db_path = drop_database(local_uri)

# %%
engine = create_engine(local_uri, echo=True)

# %%
sql_exec = sql_bind(engine)

# %%
sql_exec("SELECT current_timestamp")

# %%
schema_sql = """

SELECT
  m.name as table_name,
  p.name as column_name
FROM
  sqlite_master AS m
JOIN
  pragma_table_info(m.name) AS p
WHERE
  m.type = 'table'
ORDER BY
  m.name,
  p.cid

"""


# %%
sql_exec(schema_sql)

# %%
create_sql = """

CREATE TABLE IF NOT EXISTS demo_table (
        column1 text PRIMARY KEY,
        column2 text NOT NULL,
        column3 integer DEFAULT 0
);

"""

insert_sql = """

INSERT INTO 'demo_table' ('column1', 'column2') VALUES
  ('a', 'data1'),
  ('b', 'data2'),
  ('c', 'data1'),
  ('d', 'data3'),
  ('e', 'data3');

"""

update_sql = """

UPDATE 'demo_table' SET
  column3 = column3 + 1
 WHERE
   column2 in ('data2', 'data3');

"""

select_sql = """

SELECT * FROM 'demo_table'
ORDER BY column2, column1 DESC;

"""

group_sql = """

SELECT column2, sum(column3) as tot3 FROM 'demo_table'
GROUP BY column2 HAVING tot3 > 0
ORDER BY tot3 DESC, column2;

"""


# %%
sql_exec(create_sql)

# %%
sql_exec(schema_sql)

# %%
sql_exec(insert_sql)

# %%
sql_exec(select_sql)

# %%
sql_exec(update_sql)
sql_exec(update_sql)
sql_exec(update_sql)

# %%
sql_exec(select_sql)

# %%
sql_exec(group_sql)

# %%
assert db_path
subprocess.run(["ls", "-l", db_path.parent], check=True)
