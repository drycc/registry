FROM minio/mc:RELEASE.2020-07-17T02-52-20Z as mc

FROM registry:2.7

COPY . /

COPY --from=mc /usr/bin/mc /usr/bin/mc

RUN apk add --no-cache jq bash \
  && chmod +x /bin/create_bucket /bin/normalize_storage 

VOLUME ["/var/lib/registry"]
CMD ["/opt/registry/sbin/registry"]
EXPOSE 5000
