FROM registry.drycc.cc/drycc/go-dev:latest AS build
ARG LDFLAGS
ADD . /workspace
RUN export GO111MODULE=on \
  && cd /workspace \
  && CGO_ENABLED=0 init-stack go build -ldflags "${LDFLAGS}" -o /usr/local/bin/registry main.go \
  && upx -9 --brute /usr/local/bin/registry


FROM registry.drycc.cc/drycc/base:bullseye

ENV DRYCC_UID=1001 \
  DRYCC_GID=1001 \
  DRYCC_HOME_DIR=/var/lib/registry \
  JQ_VERSION="1.6" \
  MC_VERSION="2022.04.01.23.44.48" \
  REGISTRY_VERSION="2.8.0"

COPY rootfs/bin/ /bin/
COPY --from=build /usr/local/bin/registry /opt/registry/bin/registry

RUN groupadd drycc --gid ${DRYCC_GID} \
  && useradd drycc -u ${DRYCC_UID} -g ${DRYCC_GID} -s /bin/bash -m -d ${DRYCC_HOME_DIR} \
  && install-packages apache2-utils \
  && install-stack jq $JQ_VERSION \
  && install-stack mc $MC_VERSION \
  && install-stack registry $REGISTRY_VERSION \
  && chmod +x /bin/init_registry \
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
  && chown -R ${DRYCC_GID}:${DRYCC_UID} ${DRYCC_HOME_DIR}

COPY --chown=${DRYCC_GID}:${DRYCC_UID} rootfs/config-example.yml /opt/drycc/registry/etc/config.yml

USER ${DRYCC_UID}
VOLUME ["${DRYCC_HOME_DIR}"]
CMD ["/opt/registry/bin/registry"]
EXPOSE 5000
