ARG GO_VERSION=1.11.2
FROM golang:${GO_VERSION}-alpine

RUN apk --no-cache add \
  ca-certificates \
  make \
  git

WORKDIR /src
COPY go.mod go.sum Makefile ./
RUN make vendor
COPY . .
RUN make test all

FROM alpine:latest
ENV TLS_PORT=9443 \
    LIFECYCLE_PORT=9000 \
    CONFIG=./conf/sidecars.yaml \
    TLS_CERT_FILE=/var/lib/secrets/cert.crt \
    TLS_KEY_FILE=/var/lib/secrets/cert.key
RUN apk --no-cache add ca-certificates bash
COPY --from=0 /src/bin/k8s-sidecar-injector /bin/k8s-sidecar-injector
COPY ./conf ./conf
COPY ./entrypoint.sh /bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE $TLS_PORT $LIFECYCLE_PORT
CMD []
