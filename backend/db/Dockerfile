FROM postgres:16-alpine
LABEL maintainer="infinicard <dev@infinicard.example>"

# Copy any init scripts into the image so the DB can initialize without a host mount.
# Scripts in initdb/ will be executed by the official entrypoint when the DB is first created.
COPY initdb/ /docker-entrypoint-initdb.d/

# Ensure ownership is correct
RUN chown -R postgres:postgres /docker-entrypoint-initdb.d
