#!/usr/bin/env bash

set -eoxf pipefail

CURRENT_DIR=$(cd "$(dirname "$0")"; pwd)

mkdir -p "${CURRENT_DIR}"/tmp/aws-user
echo "us-east-1" > "${CURRENT_DIR}"/tmp/aws-user/region
echo "registry-bucket" > "${CURRENT_DIR}"/tmp/aws-user/registry-bucket
echo "1234567890123456789012345678901234567890" > "${CURRENT_DIR}"/tmp/aws-user/accesskey
echo "1234567890123456789012345678901234567890" > "${CURRENT_DIR}"/tmp/aws-user/secretkey

MINIO_JOB=$(docker run -d \
  -v "${CURRENT_DIR}"/tmp/aws-user:/var/run/secrets/drycc/objectstore/creds \
  quay.io/drycc/minio:canary server /home/minio/)


JOB=$(docker run -d \
  -v "${CURRENT_DIR}"/tmp/aws-user:/var/run/secrets/drycc/objectstore/creds \
  "$1")

# let the registry run for a few seconds
sleep 5
# check that the registry is still up
docker logs "${JOB}"
docker ps -q --no-trunc=true | grep "${JOB}"
docker rm -f "${JOB}" "${MINIO_JOB}"
