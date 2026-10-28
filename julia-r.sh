#!/bin/bash
[ -n "$container" ] || { echo "julia-r ('rcall' environment) enabled only in container"; exit 1; }
exec "$(dirname $0)/etc/julia/envs/rcall/julia" "$@"
