#!/usr/bin/env bash

set -eoxf pipefail

s3Accesskey=drycc
s3Secretkey=123456789

MINIO_JOB=$(docker run -d --name minio \
  -e DRYCC_MINIO_ACCESSKEY=$s3Accesskey \
  -e DRYCC_MINIO_SECRETKEY=$s3Secretkey \
  "${DEV_REGISTRY}"/drycc/minio:canary server /data/minio/ --console-address :9001)

sleep 5
docker logs "${MINIO_JOB}"

MINIO_IP=$(docker inspect --format "{{ .NetworkSettings.IPAddress }}" "${MINIO_JOB}")

JOB=$(docker run --add-host minio:"${MINIO_IP}" \
  -d \
  -p 5000:5000 \
  -e REGISTRY_HTTP_SECRET=drycc \
  -e DRYCC_REGISTRY_REDIRECT=false \
  -e DRYCC_REGISTRY_USERNAME=admin \
  -e DRYCC_REGISTRY_PASSWORD=admin \
  -e DRYCC_MINIO_LOOKUP=path \
  -e DRYCC_MINIO_BUCKET=registry \
  -e DRYCC_MINIO_ENDPOINT=http://minio:9000 \
  -e DRYCC_MINIO_ACCESSKEY=$s3Accesskey \
  -e DRYCC_MINIO_SECRETKEY=$s3Secretkey \
  "$1")

# let the registry run for a few seconds
sleep 5
# check that the registry is still up
docker logs "${JOB}"
docker ps -q --no-trunc=true | grep "${JOB}"
docker rm -f "${JOB}" "${MINIO_JOB}"
