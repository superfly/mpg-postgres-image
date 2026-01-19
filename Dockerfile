ARG BASE_IMAGE_TAG=2.6.0-ppg16.8-postgres
FROM percona/percona-postgresql-operator:${BASE_IMAGE_TAG}

COPY postgres-oom-adjuster.sh /usr/local/bin/
COPY entrypoint-wrapper.sh /usr/local/bin/

# Switch user for the run command.
USER 0
# NOTE: We use this file to check if we can execute the entrypoint wrapper with arguments.
# The previous version didn't allow arguments, so if we'd try, we'd break the replica.
# We didn't catch this earlier because postgres-operator is overriding the entrypoint by
# setting a pod command param to execute patroni directly. This change will be accompanied
# by a postgres-operator patch to conditionally call the wrapper when this file exists,
# allowing us to use the wrapper and the oom adjuster.
RUN echo "2" > /usr/local/bin/.entrypoint-wrapper-version

# Switch back to postgres user
USER 26

ENTRYPOINT ["/usr/local/bin/entrypoint-wrapper.sh"]
