# Build Stage
FROM golang:1.19.3-bullseye as builder

WORKDIR /
COPY ./ ./boltcard

# Build boltcard binaries.
RUN cd boltcard/ && \
    go build && \
    cd createboltcard/ && \
    go build


# Final Image
FROM debian:11-slim as final

# Variables
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=boltcard
ENV PG_VERSION=13
ENV PGDATA="/var/lib/postgresql/$PG_VERSION/main"
ENV PATH="$PATH:/usr/lib/postgresql/$PG_VERSION/bin"
WORKDIR /app

# Dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        gosu \
        systemctl \
        postgresql-$PG_VERSION \
        vim-common \
        openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add files.
COPY --from=builder /boltcard/boltcard ./
COPY --from=builder /boltcard/createboltcard/createboltcard ./
COPY create_db.sql ./
COPY docker/ ./

# Create user.
RUN useradd $USER

# Volumes
VOLUME /var/lib/postgresql
VOLUME /data

# Port
EXPOSE 9000

# Entrypoint
CMD ["./boltcard"]
ENTRYPOINT ["./entrypoint.sh"]
