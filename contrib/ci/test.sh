#!/usr/bin/env bash

set -eoxf pipefail

s3Accesskey=drycc
s3Secretkey=123456789

STORAGE_JOB=$(podman run -d --entrypoint init-stack -p 8333:8333 \
  -e DRYCC_STORAGE_ACCESSKEY=$s3Accesskey \
  -e DRYCC_STORAGE_SECRETKEY=$s3Secretkey \
  "${DEV_REGISTRY}"/drycc/storage:canary weed server -dir=/data/hdd -s3)

# wait for port
STORAGE_IP=$(podman inspect --format "{{ .NetworkSettings.IPAddress }}" "${STORAGE_JOB}")
echo -e "\\033[32m---> Waitting for ${STORAGE_IP}:8333\\033[0m"
wait-for-port --host="${STORAGE_IP}" 8333
echo -e "\\033[32m---> S3 service ${STORAGE_IP}:8333 ready...\\033[0m"
podman logs "${STORAGE_JOB}"

JOB=$(podman run -d -p 5000:5000 \
  -e REGISTRY_HTTP_SECRET=drycc \
  -e DRYCC_REGISTRY_REDIRECT=false \
  -e DRYCC_REGISTRY_USERNAME=admin \
  -e DRYCC_REGISTRY_PASSWORD=admin \
  -e DRYCC_STORAGE_LOOKUP=path \
  -e DRYCC_STORAGE_BUCKET=registry \
  -e DRYCC_STORAGE_ENDPOINT="http://${STORAGE_IP}:8333" \
  -e DRYCC_STORAGE_ACCESSKEY=$s3Accesskey \
  -e DRYCC_STORAGE_SECRETKEY=$s3Secretkey \
  "$1")

# shellcheck disable=SC2317
function clean_before_exit {
  # delay before exiting, so stdout/stderr flushes through the logging system
  podman kill "${JOB}"
  podman kill "${STORAGE_JOB}"
  podman rm "${JOB}" "${STORAGE_JOB}"
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
