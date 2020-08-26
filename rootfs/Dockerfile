FROM registry:2.7

COPY . /

RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /bin/mc \
  && chmod +x /bin/mc \
  && apk add --no-cache jq bash \
  && chmod +x /bin/create_bucket /bin/normalize_storage 

VOLUME ["/var/lib/registry"]
CMD ["/opt/registry/sbin/registry"]
EXPOSE 5000
