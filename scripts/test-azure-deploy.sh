#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."

az() { test "$failure" != "az $1"; }
docker() {
  test "$failure" != "docker $1 ${2:-}" || return 1
  if [ "$1 $2" = 'service inspect' ]; then
    if [ "$failure" = rollback ]; then printf 'previous-image\n'; else printf '%s\n' "$image"; fi
  fi
}
timeout() { shift; "$@"; }
curl() { test "$failure" != curl; }
export -f az docker timeout curl
export image='ivakdokploytest.azurecr.io/dokploy@sha256:test'

for failure in none 'az login' 'az acr' 'docker pull ivakdokploytest.azurecr.io/dokploy@sha256:test' 'docker service update' 'docker service inspect' rollback curl; do
  export failure
  if output=$(bash scripts/azure-deploy.sh 2>&1); then
    test "$failure" = none
    test "$output" = "DEPLOYED=$image"
  else
    test "$failure" != none
    if [[ "$output" == *DEPLOYED=* ]]; then exit 1; fi
  fi
done
printf 'Deployment success and failure checks passed.\n'
