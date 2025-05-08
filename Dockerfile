ARG CODENAME

FROM registry.drycc.cc/drycc/go-dev:latest AS build
ARG LDFLAGS
ADD . /workspace
RUN export GO111MODULE=on \
  && cd /workspace \
  && CGO_ENABLED=0 init-stack go build -ldflags "${LDFLAGS}" -o /bin/start-registry main.go \
  && upx -9 --brute /bin/start-registry


FROM registry.drycc.cc/drycc/base:${CODENAME}

ENV DRYCC_UID=1001 \
  DRYCC_GID=1001 \
  DRYCC_HOME_DIR=/var/lib/registry \
  JQ_VERSION="1.7.1" \
  MC_VERSION="2025.04.03.17.07.56" \
  NGINX_VERSION="1.25.1" \
  REGISTRY_VERSION="3.0.0"

RUN groupadd drycc --gid ${DRYCC_GID} \
  && useradd drycc -u ${DRYCC_UID} -g ${DRYCC_GID} -s /bin/bash -m -d ${DRYCC_HOME_DIR} \
  && install-packages apache2-utils \
  && install-stack jq $JQ_VERSION \
  && install-stack mc $MC_VERSION \
  && install-stack nginx ${NGINX_VERSION} \
  && install-stack registry $REGISTRY_VERSION \
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
  && chown -R ${DRYCC_UID}:${DRYCC_GID} /opt/drycc

COPY --from=build /bin/start-registry /bin/start-registry
COPY --chown=${DRYCC_UID}:${DRYCC_GID} rootfs/bin/ /bin/
COPY --chown=${DRYCC_UID}:${DRYCC_GID} rootfs/opt/drycc/nginx /opt/drycc/nginx
COPY --chown=${DRYCC_UID}:${DRYCC_GID} rootfs/config-example.yml /opt/drycc/registry/etc/config.yml

ENV OTEL_TRACES_EXPORTER=none \
  DRYCC_REGISTRY_CONFIG=/opt/drycc/registry/etc/config.yml

USER ${DRYCC_UID}
VOLUME ["${DRYCC_HOME_DIR}"]
EXPOSE 5000
