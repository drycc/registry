#!/usr/bin/env bash

set -eoxf pipefail

BASE_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
DRYCC_STORAGE_ACCESSKEY=f4c4281665bc11ee8e0400163e04a9cd
DRYCC_STORAGE_SECRETKEY=f4c4281665bc11ee8e0400163e04a9cd


STORAGE_JOB=$(podman run -d --entrypoint init-stack -p 8333:8333 \
  -v "${BASE_DIR}":/tmp/weed \
  -e DRYCC_STORAGE_ACCESSKEY="${DRYCC_STORAGE_ACCESSKEY}" \
  -e DRYCC_STORAGE_SECRETKEY="${DRYCC_STORAGE_SECRETKEY}" \
  "${DEV_REGISTRY}"/drycc/storage:canary /tmp/weed/start-s3.sh)

# wait for port
STORAGE_IP=$(podman inspect --format "{{ .NetworkSettings.IPAddress }}" "${STORAGE_JOB}")
echo -e "\\033[32m---> Waitting for ${STORAGE_IP}:8333\\033[0m"
wait-for-port --host="${STORAGE_IP}" 8333
echo -e "\\033[32m---> S3 service ${STORAGE_IP}:8333 ready...\\033[0m"
podman logs "${STORAGE_JOB}"

JOB=$(podman run -d \
  -e REGISTRY_HTTP_SECRET=drycc \
  -e DRYCC_REGISTRY_REDIRECT=false \
  -e DRYCC_REGISTRY_USERNAME=admin \
  -e DRYCC_REGISTRY_PASSWORD=admin \
  -e DRYCC_STORAGE_LOOKUP=path \
  -e DRYCC_STORAGE_BUCKET=registry \
  -e DRYCC_STORAGE_ENDPOINT="http://${STORAGE_IP}:8333" \
  -e DRYCC_STORAGE_ACCESSKEY="${DRYCC_STORAGE_ACCESSKEY}" \
  -e DRYCC_STORAGE_SECRETKEY="${DRYCC_STORAGE_SECRETKEY}" \
  "$1")

# shellcheck disable=SC2317
function clean_before_exit {
  # delay before exiting, so stdout/stderr flushes through the logging system
  podman kill "${JOB}"
  podman kill "${STORAGE_JOB}"
  podman rm -f "${JOB}" "${STORAGE_JOB}"
}
trap clean_before_exit EXIT

# let the registry run for a few seconds
REGISTRY_IP=$(podman inspect --format "{{ .NetworkSettings.IPAddress }}" "${JOB}")
echo -e "\\033[32m---> Waitting for ${REGISTRY_IP}:5000\\033[0m"
wait-for-port --host="${REGISTRY_IP}" 5000
echo -e "\\033[32m---> S3 service ${REGISTRY_IP}:5000 ready...\\033[0m"
# check that the registry is still up
podman logs "${JOB}"
podman ps -q --no-trunc=true | grep "${JOB}"
