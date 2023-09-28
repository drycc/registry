#!/usr/bin/env bash

set -eoxf pipefail

s3Accesskey=drycc
s3Secretkey=123456789

STORAGE_JOB=$(podman run -d --name storage \
  -e DRYCC_STORAGE_ACCESSKEY=$s3Accesskey \
  -e DRYCC_STORAGE_SECRETKEY=$s3Secretkey \
  "${DEV_REGISTRY}"/drycc/storage:canary minio server /data/storage/ --console-address :9001)

sleep 5
podman logs "${STORAGE_JOB}"

STORAGE_IP=$(podman inspect --format "{{ .NetworkSettings.IPAddress }}" "${STORAGE_JOB}")

JOB=$(podman run --add-host storage:"${STORAGE_IP}" \
  -d \
  -p 5000:5000 \
  -e REGISTRY_HTTP_SECRET=drycc \
  -e DRYCC_REGISTRY_REDIRECT=false \
  -e DRYCC_REGISTRY_USERNAME=admin \
  -e DRYCC_REGISTRY_PASSWORD=admin \
  -e DRYCC_STORAGE_LOOKUP=path \
  -e DRYCC_STORAGE_BUCKET=registry \
  -e DRYCC_STORAGE_ENDPOINT=http://storage:9000 \
  -e DRYCC_STORAGE_ACCESSKEY=$s3Accesskey \
  -e DRYCC_STORAGE_SECRETKEY=$s3Secretkey \
  "$1")

# let the registry run for a few seconds
sleep 5
# check that the registry is still up
podman logs "${JOB}"
podman ps -q --no-trunc=true | grep "${JOB}"
podman rm -f "${JOB}" "${STORAGE_JOB}"
