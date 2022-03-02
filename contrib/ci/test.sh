#!/usr/bin/env bash

set -eoxf pipefail

CURRENT_DIR=$(cd "$(dirname "$0")"; pwd)

mkdir -p "${CURRENT_DIR}"/tmp/aws-user
echo "us-east-1" > "${CURRENT_DIR}"/tmp/aws-user/region
echo "registry-bucket" > "${CURRENT_DIR}"/tmp/aws-user/registry-bucket
echo "1234567890123456789012345678901234567890" > "${CURRENT_DIR}"/tmp/aws-user/accesskey
echo "1234567890123456789012345678901234567890" > "${CURRENT_DIR}"/tmp/aws-user/secretkey

MINIO_JOB=$(docker run -d --name minio \
  -v "${CURRENT_DIR}"/tmp/aws-user:/var/run/secrets/drycc/objectstore/creds \
  drycc/minio:canary server /data/minio/)

sleep 5
docker logs "${MINIO_JOB}"

MINIO_IP=$(docker inspect --format "{{ .NetworkSettings.IPAddress }}" "${MINIO_JOB}")

JOB=$(docker run --add-host minio:"${MINIO_IP}" \
  -d \
  -e DRYCC_MINIO_SERVICE_HOST=minio \
  -e DRYCC_MINIO_SERVICE_PORT=9000 \
  -v "${CURRENT_DIR}"/tmp/aws-user:/var/run/secrets/drycc/objectstore/creds \
  "$1")

# let the registry run for a few seconds
sleep 5
# check that the registry is still up
docker logs "${JOB}"
docker ps -q --no-trunc=true | grep "${JOB}"
docker rm -f "${JOB}" "${MINIO_JOB}"
