---
title: Data readme subtitle: dataset description author: .. date: 23/04/2020
---

Project DATA
============


Info
----

* `./data` - data directory, relative to project base directory
* `./data/int` - _"internal"_ data directory, committed to project repository
* `./data/ext` - _"external"_ data directory, not committed, link to external (shared) data
* `./data/tmp` - _"temporary"_ data directory, not committed, scratch (unshared) data
* `./data/def` - _"default"_ data directory, preconfigured default data directory, symlink to current data

Config
------

* `./data/.gitignore` - ignore all with exceptions

```

*

!.gitignore
!README.md

!int/



```

DATASETS
========


Test Dataset
------------

* `./data/int/test` - unit test data

DATA USAGE NOTE
===============


EXTERNAL PATHS
---------------

* `./data/ext/` - ignored from git repo

### "home": inside home directory

* `./data/ext/home/` - inside user home private directory _(fast, small)_

### "host": machine shared data

* `./data/ext/home/` - local machine shared data _(fast, small)_

### "user": network drive user area

* `./data/ext/user/` - network shared user data _(slow, big)_

INTERNAL PATHS
--------------

* `./data/int/` - internal git committed data

to be used _**only**_ for small samples used in usage demo and unit testing





PATH CONFIG
===========


Spec
----

* `dir-a` - relative to current working directory
* `./dir-b` - relative to project root directory
* `~/dir-c` - relative to user $HOME directory
* `/dir-d` - absolute path

Usage
-----

```python

##
# define
#

import os.path
import rootpath


def conf_dir(env_key, default_value):
    p = os.path.expanduser(os.getenv(env_key, default_value))
    return rootpath.detect(__file__, "^.git$") + p[1:] if p.startswith(f"./") else p


DATA_HOME = conf_dir('PC_DATA_HOME', "./data/ext/home")
DATA_HOST = conf_dir('PC_DATA_HOST', "./data/ext/host")
DATA_USER = conf_dir('PC_DATA_USER', "./data/ext/user")
DATA_DESK = conf_dir('PC_DATA_DESK', "~/Desktop")

##
# reference
#

path_1 = DATA_USER + f"/DRL/D2QN/save-01001653/main_dqn.h5"
path_2 = DATA_DESK + f"/results_DRL/final/model-a_test.csv"

```

run `test_common.py` unittest for path resolution






