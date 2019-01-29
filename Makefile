# Short name: Short name, following [a-zA-Z_], used all over the place.
# Some uses for short name:
# - Docker image name
# - Kubernetes service, deployment, pod names
SHORT_NAME := registry

include includes.mk versioning.mk

# the filepath to this repository, relative to $GOPATH/src
REPO_PATH = github.com/drycc/registry

SHELL_SCRIPTS = $(wildcard rootfs/bin/* _scripts/*.sh contrib/ci/*.sh)

# The following variables describe the containerized development environment
# and other build options
DEV_ENV_IMAGE := quay.io/drycc/go-dev:v0.22.0
DEV_ENV_WORK_DIR := /go/src/${REPO_PATH}
DEV_ENV_PREFIX := docker run --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR}
DEV_ENV_CMD := ${DEV_ENV_PREFIX} ${DEV_ENV_IMAGE}
LDFLAGS := "-s -w -X main.version=${VERSION}"
BINDIR := ./rootfs/opt/registry/sbin

# Legacy support for DEV_REGISTRY, plus new support for DRYCC_REGISTRY.
DRYCC_REGISTRY ?= ${DEV_REGISTRY}

ifeq ($(STORAGE_TYPE),)
  STORAGE_TYPE = fs
endif

all:
	@echo "Use a Makefile to control top-level building of the project."

build: check-docker
	mkdir -p ${BINDIR}
	$(MAKE) build-binary

# For cases where we're building from local
# We also alter the RC file to set the image name.
docker-build: check-docker build
	docker build ${DOCKER_BUILD_FLAGS} -t ${IMAGE} rootfs
	docker tag ${IMAGE} ${MUTABLE_IMAGE}

build-binary:
	${DEV_ENV_CMD} go build -ldflags ${LDFLAGS} -o $(BINDIR)/${SHORT_NAME} main.go
	$(call check-static-binary,$(BINDIR)/${SHORT_NAME})
	${DEV_ENV_CMD} upx -9 --brute $(BINDIR)/${SHORT_NAME}

test: check-docker test-style
	contrib/ci/test.sh ${IMAGE}

test-style:
	${DEV_ENV_CMD} shellcheck $(SHELL_SCRIPTS)

deploy: check-kubectl docker-build docker-push
	kubectl --namespace=drycc patch deployment drycc-$(SHORT_NAME) --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"$(IMAGE)"}]'

.PHONY: all build build-binary docker-build test test-style deploy
