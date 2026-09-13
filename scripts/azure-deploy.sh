set -eu

az login --identity --output none
az acr login --name ivakdokploytest --output none
docker pull "$image"
timeout 300 docker service update --image "$image" --with-registry-auth \
  --update-failure-action rollback --update-monitor 60s dokploy
test "$(docker service inspect dokploy --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')" = "$image"
curl --fail --silent --show-error --retry 20 --retry-all-errors \
  --retry-delay 5 --retry-max-time 180 \
  http://localhost:3000/api/trpc/settings.health > /dev/null
printf 'DEPLOYED=%s\n' "$image"
