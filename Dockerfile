FROM alpine
RUN apk --update add nmap
COPY . /
WORKDIR /
ENTRYPOINT ["/entrypoint.sh"]
