FROM docker.io/drycc/go-dev:latest AS build
ARG LDFLAGS
ADD . /workspace
RUN export GO111MODULE=on \
  && cd /workspace \
  && CGO_ENABLED=0 init-stack go build -ldflags "${LDFLAGS}" -o /usr/local/bin/registry main.go \
  && upx -9 --brute /usr/local/bin/registry


FROM docker.io/drycc/base:bullseye

RUN adduser --system \
   --shell /bin/bash \
   --disabled-password \
   --home /var/lib/registry \
   --group \
   drycc

COPY rootfs/bin/ /bin/
COPY rootfs/config-example.yml /etc/docker/registry/config.yml
COPY --from=build /usr/local/bin/registry /opt/registry/sbin/registry
ENV JQ_VERSION="1.6" \
  MC_VERSION="2022.02.26.03.58.31" \
  REGISTRY_VERSION="2.8.0"

RUN install-stack jq $JQ_VERSION \
  && install-stack mc $MC_VERSION \
  && install-stack registry $REGISTRY_VERSION \
  && chmod +x /bin/create_bucket /bin/normalize_storage \
  && rm -rf \
      /usr/share/doc \
      /usr/share/man \
      /usr/share/info \
      /usr/share/locale \
      /var/lib/apt/lists/* \
      /var/log/* \
      /var/cache/debconf/* \
      /etc/systemd \
      /lib/lsb \
      /lib/udev \
      /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/IBM* \
      /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/EBC* \
  && mkdir -p /usr/share/man/man{1..8} \
  && chown -R drycc:drycc /var/lib/registry

USER drycc
VOLUME ["/var/lib/registry"]
CMD ["/opt/registry/sbin/registry"]
EXPOSE 5000
