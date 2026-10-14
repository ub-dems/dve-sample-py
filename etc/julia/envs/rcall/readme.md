# Julia <-> R "in-process" environment


## Install


### RCall.jl

requires R in path

- TODO(RCall)


```bash
julia --project=etc/julia/envs/rcall -e '
using Pkg;
Pkg.add("RCall");
Pkg.instantiate()
Pkg.precompile()
'
```


### JuliaCall

- TODO(JuliaCall)

```

      cat <<EOR >> ~/.Renviron
PATH=${X_ENV_PATH}
#X_ENV_VENV=${X_ENV_VENV}
#VIRTUAL_ENV=${VIRTUAL_ENV}
RETICULATE_PYTHON_ENV=${RETICULATE_PYTHON_ENV}
_R_CHECK_SYSTEM_CLOCK_=0
EOR


   R -q -e "rnv::install('JuliaCall')"


```
