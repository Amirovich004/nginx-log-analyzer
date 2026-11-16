FROM alpine:3.20

RUN apk add --no-cache bash gawk \
    && adduser -D -u 10001 app

COPY bin/log-analyzer /usr/local/bin/log-analyzer
RUN chmod +x /usr/local/bin/log-analyzer

USER app

ENTRYPOINT ["/usr/local/bin/log-analyzer"]
