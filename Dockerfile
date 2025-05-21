FROM percona/percona-postgresql-operator:2.6.0-ppg16.8-postgres

# Create a custom entrypoint script that sets OOM score and starts postgres
COPY entrypoint-wrapper.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint-wrapper.sh

# We don't change the original ENTRYPOINT - we wrap around it
ENTRYPOINT ["/usr/local/bin/entrypoint-wrapper.sh"]
