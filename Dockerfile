ARG PG_VERSION=15

FROM postgres:$PG_VERSION-bookworm
ARG PG_VERSION

WORKDIR /tmp/lantern

COPY . .

# Install OpenSSL and sudo
RUN apt-get update && apt-get install -y openssl sudo

# Allow the postgres user to execute certain commands as root without a password
RUN echo "postgres ALL=(root) NOPASSWD: /usr/bin/mkdir, /bin/chown" > /etc/sudoers.d/postgres

# Add your init script
COPY ./ci/scripts/init-ssl.sh /docker-entrypoint-initdb.d/

# Set permissions
RUN chmod +x /docker-entrypoint-initdb.d/init-ssl.sh

RUN PG_VERSION=$PG_VERSION ./ci/scripts/build-docker.sh 