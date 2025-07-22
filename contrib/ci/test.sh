#!/usr/bin/env bash

set -eoxf pipefail

DRYCC_STORAGE_ACCESSKEY=f4c4281665bc11ee8e0400163e04a9cd
DRYCC_STORAGE_SECRETKEY=f4c4281665bc11ee8e0400163e04a9cd


STORAGE_JOB=$(podman run -d --rm --entrypoint init-stack \
  -e MINIO_ROOT_USER="${DRYCC_STORAGE_ACCESSKEY}" \
  -e MINIO_ROOT_PASSWORD="${DRYCC_STORAGE_SECRETKEY}" \
  "${DEV_REGISTRY}"/drycc/storage:canary minio server /data)

# wait for port
STORAGE_IP=$(podman inspect --format "{{ .NetworkSettings.IPAddress }}" "${STORAGE_JOB}")
echo -e "\\033[32m---> Waitting for ${STORAGE_IP}:9000\\033[0m"
wait-for-port --host="${STORAGE_IP}" 9000
echo -e "\\033[32m---> S3 service ${STORAGE_IP}:9000 ready...\\033[0m"
podman logs "${STORAGE_JOB}"

REGISTRY_JOB=$(podman run -d --rm \
  -e DRYCC_REGISTRY_REDIRECT=false \
  -e DRYCC_REGISTRY_USERNAME=admin \
  -e DRYCC_REGISTRY_PASSWORD=admin \
  -e DRYCC_STORAGE_BUCKET=registry \
  -e DRYCC_STORAGE_ENDPOINT="http://${STORAGE_IP}:9000" \
  -e DRYCC_STORAGE_ACCESSKEY="${DRYCC_STORAGE_ACCESSKEY}" \
  -e DRYCC_STORAGE_SECRETKEY="${DRYCC_STORAGE_SECRETKEY}" \
  -e DRYCC_STORAGE_PATH_STYLE=on \
  "$1" start-registry)

# shellcheck disable=SC2317
function clean_before_exit {
  # delay before exiting, so stdout/stderr flushes through the logging system
  podman kill "${REGISTRY_JOB}"
  podman kill "${STORAGE_JOB}"
  podman kill "${PROXY_JOB}"
}
trap clean_before_exit EXIT

# let the registry run for a few seconds
REGISTRY_IP=$(podman inspect --format "{{ .NetworkSettings.IPAddress }}" "${REGISTRY_JOB}")
echo -e "\\033[32m---> Waitting for ${REGISTRY_IP}:5000\\033[0m"
wait-for-port --host="${REGISTRY_IP}" 5000
echo -e "\\033[32m---> S3 service ${REGISTRY_IP}:5000 ready...\\033[0m"

# proxy job
PROXY_JOB=$(podman run -d \
  -p 15555:8080 \
  -e DRYCC_REGISTRY_HOST="${REGISTRY_IP}:5000" \
  -e DRYCC_REGISTRY_USERNAME=admin \
  -e DRYCC_REGISTRY_PASSWORD=admin \
  "$1" start-proxy)

# let the registry proxy run for a few seconds
REGISTRY_PROXY_IP=$(podman inspect --format "{{ .NetworkSettings.IPAddress }}" "${PROXY_JOB}")
echo -e "\\033[32m---> Waitting for ${REGISTRY_PROXY_IP}:8080\\033[0m"
wait-for-port --host="${REGISTRY_PROXY_IP}" 8080
echo -e "\\033[32m---> S3 service ${REGISTRY_PROXY_IP}:8080 ready...\\033[0m"

# check that the registry is still up
http_status_code=$(curl -X GET -s -o /dev/null -w "%{http_code}" "http://${REGISTRY_PROXY_IP}:8080/v2/")
if [ "$http_status_code" != "200" ]; then
    echo "Expected http status code: 200, actual: ${http_status_code}"
    exit 1
fi

http_status_code=$(curl -X POST -s -o /dev/null -w "%{http_code}" "http://${REGISTRY_PROXY_IP}:8080/v2/")
if [ "$http_status_code" != "403" ]; then
    echo "Expected http status code: 403, actual: ${http_status_code}"
    exit 1
fi

echo -e "\\033[32m---> All test success...\\033[0m"