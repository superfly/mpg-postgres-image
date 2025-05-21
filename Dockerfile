FROM percona/percona-postgresql-operator:2.6.0-ppg16.8-postgres

# Switch to root user temporarily to gain necessary privileges for setup
USER root

# Install gosu for stepping down from root
RUN apt-get update && apt-get install -y --no-install-recommends gosu \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create a custom entrypoint script that sets OOM score and starts postgres
COPY entrypoint-wrapper.sh /usr/local/bin/
COPY postgres-oom-adjuster.sh /usr/local/bin/

# We don't change the original ENTRYPOINT - we wrap around it
ENTRYPOINT ["/usr/local/bin/entrypoint-wrapper.sh"]
