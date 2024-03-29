# Short name: Short name, following [a-zA-Z_], used all over the place.
# Some uses for short name:
# - Container image name
# - Kubernetes service, deployment, pod names
SHORT_NAME := registry
DRYCC_REGISTRY ?= ${DEV_REGISTRY}
PLATFORM ?= linux/amd64,linux/arm64

include includes.mk versioning.mk

# the filepath to this repository, relative to $GOPATH/src
REPO_PATH = github.com/drycc/registry

SHELL_SCRIPTS = $(wildcard rootfs/bin/* _scripts/*.sh contrib/ci/*.sh)

# The following variables describe the containerized development environment
# and other build options
DEV_ENV_IMAGE := ${DEV_REGISTRY}/drycc/go-dev
DEV_ENV_WORK_DIR := /opt/drycc/go/src/${REPO_PATH}
DEV_ENV_PREFIX := podman run --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR}
DEV_ENV_CMD := ${DEV_ENV_PREFIX} ${DEV_ENV_IMAGE}
LDFLAGS := "-s -w -X main.version=${VERSION}"
BINDIR := ./rootfs/opt/registry/sbin

ifeq ($(STORAGE_TYPE),)
  STORAGE_TYPE = fs
endif

all:
	@echo "Use a Makefile to control top-level building of the project."

build: check-podman
	mkdir -p ${BINDIR}
	$(MAKE) build-binary

# For cases where we're building from local
# We also alter the RC file to set the image name.
podman-build: check-podman
	podman build --build-arg CODENAME=${CODENAME} -t ${IMAGE} --build-arg LDFLAGS=${LDFLAGS} .
	podman tag ${IMAGE} ${MUTABLE_IMAGE}

build-binary:
	${DEV_ENV_CMD} go build -ldflags ${LDFLAGS} -o $(BINDIR)/${SHORT_NAME} main.go
	$(call check-static-binary,$(BINDIR)/${SHORT_NAME})
	${DEV_ENV_CMD} upx -9 --brute $(BINDIR)/${SHORT_NAME}

test: check-podman podman-build test-style
	contrib/ci/test.sh ${IMAGE}

test-style:
	${DEV_ENV_CMD} shellcheck $(SHELL_SCRIPTS)

deploy: check-kubectl podman-build podman-push
	kubectl --namespace=drycc patch deployment drycc-$(SHORT_NAME) --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value":"$(IMAGE)"}]'

.PHONY: all build build-binary podman-build test test-style deploy
