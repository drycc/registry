# Drycc Registry v2

[![Build Status](https://woodpecker.drycc.cc/api/badges/drycc/registry/status.svg)](https://woodpecker.drycc.cc/drycc/registry)
[![Go Report Card](https://goreportcard.com/badge/github.com/drycc/registry)](https://goreportcard.com/report/github.com/drycc/registry)


Drycc (pronounced DAY-iss) is an open source PaaS that makes it easy to deploy and manage
applications on your own servers. Drycc builds on [Kubernetes](http://kubernetes.io/) to provide
a lightweight, [Heroku-inspired](http://heroku.com) workflow.

We welcome your input! If you have feedback, please submit an [issue][issues]. If you'd like to participate in development, please read the "Development" section below and submit a [pull request][prs].

# About

Registry consists of two components, namely the proxy component and the registry component.

## Proxy

The proxy component is a proxy deployed on every Kubernetes worker node, proxying all requests to the Drycc Workflow [registry][registry]. This allows the worker nodes daemons to communicate to the registry over localhost, bypassing the need for adding the `--insecure-registry` flag to the daemons.

## Registry

The registry component is a [Container registry](https://github.com/distribution/distribution) component for use in Kubernetes. While it's intended for use inside of the Drycc open source [PaaS](https://en.wikipedia.org/wiki/Platform_as_a_service), it's flexible enough to be used as a standalone pod on any Kubernetes cluster.

If you decide to use this component standalone, you can host your own Container registry in your own Kubernetes cluster.

The Container image that this repository builds is based on [the official Container v2 registry image](https://github.com/distribution/distribution).

# Development

The Drycc project welcomes contributions from all developers. The high level process for development matches many other open source projects. See below for an outline.

* Fork this repository
* Make your changes
* Submit a pull request (PR) to this repository with your changes, and unit tests whenever possible.
	* If your PR fixes any issues, make sure you write Fixes #1234 in your PR description (where #1234 is the number of the issue you're closing)
* The Drycc core contributors will review your code. After each of them sign off on your code, they'll label your PR with LGTM1 and LGTM2 (respectively). Once that happens, the contributors will merge it

## Deploying

If you want to use the latest registry image built by they Drycc team you can simply start a registry via `make deploy`.

If however, you want to build and use a custom image see the instructions below.

## Build and Deploy

To build a dev release of this image, you will also need a registry to hold the custom images. This can be your own registry, Dockerhub, or Quay.


First, configure your environment to point to the registry location.

```console
$ export DRYCC_REGISTRY=myregistry.com:5000  # if using Dockerhub, leave this unset
$ export IMAGE_PREFIX=youruser/             # if using Quay or Dockerhub
```

To build and push the image run:

```console
$ make podman-build podman-push
```

To deploy the image via patching the registry deployment run:

```console
$ make deploy
```

[issues]: https://github.com/drycc/registry/issues
[prs]: https://github.com/drycc/registry/pulls
[v2.18]: https://github.com/drycc/workflow/releases/tag/v2.18.0
