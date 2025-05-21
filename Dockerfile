FROM percona/percona-postgresql-operator:2.6.0-ppg16.8-postgres

# Switch to root user temporarily to gain necessary privileges for setup
USER root

COPY postgres-oom-adjuster.sh /usr/local/bin/
COPY entrypoint-wrapper.sh /usr/local/bin/

# We don't change the original ENTRYPOINT - we wrap around it
ENTRYPOINT ["/usr/local/bin/entrypoint-wrapper.sh"]
