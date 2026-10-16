.. highlight:: shell

============
Installation
============


Stable release
--------------

To install My Python package, run this command in your terminal:

.. code-block:: console

    $ pip install dvepy

This is the preferred method to install My Python package, as it will always install the most recent stable release.

If you don't have `pip`_ installed, this `Python installation guide`_ can guide
you through the process.

.. _pip: https://pip.pypa.io
.. _Python installation guide: http://docs.python-guide.org/en/latest/starting/installation/


From sources
------------

The sources for My Python package can be downloaded from the `Gitlab repo`_.

You can either clone the public repository:

.. code-block:: console

    $ git clone https://gitlab.com/ub-dems-public/ds-labs/dve-sample-py.git

Or download the `tarball`_:

.. code-block:: console

    $ curl  -OL https://gitlab.com/ub-dems-public/ds-labs/dve-sample-py/-/archive/master/dve-sample-py-master.tar.gz

Once you have a copy of the source, you can install it. The method of installation will depend on the packaging library being used.

For example, if `setuptools` is being used (a setup.py file is present), install my_python_package with:

.. code-block:: console

    $ poetry env use $(which python); poetry install

If `poetry` is being used (poetry.lock and pyproject.toml files are present), install my_python_package with:

.. code-block:: console

    $ poetry install


.. _Gitlab repo: https://gitlab.com/ub-dems-public/ds-labs/dve-sample-py.git
.. _tarball: https://gitlab.com/ub-dems-public/ds-labs/dve-sample-py/-/archive/master/dve-sample-py-master.tar.gz
