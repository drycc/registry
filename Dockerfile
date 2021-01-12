FROM docker.io/minio/mc:latest as mc


FROM docker.io/drycc/go-dev:latest AS build
ARG LDFLAGS
ADD . /app
RUN export GO111MODULE=on \
  && cd /app \
  && CGO_ENABLED=0 go build -ldflags "${LDFLAGS}" -o /usr/local/bin/registry main.go \
  && upx -9 --brute /usr/local/bin/registry


FROM docker.io/library/registry:2.7

COPY rootfs /
COPY --from=mc /usr/bin/mc /bin/mc
COPY --from=build /usr/local/bin/registry /opt/registry/sbin/registry

RUN apk add --no-cache jq bash \
  && chmod +x /bin/create_bucket /bin/normalize_storage 

VOLUME ["/var/lib/registry"]
CMD ["/opt/registry/sbin/registry"]
EXPOSE 5000
