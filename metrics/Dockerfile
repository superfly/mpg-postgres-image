FROM pgsty/pg_exporter:1.0.2 as base

FROM pgsty/pg_exporter:1.0.2

COPY --from=base /etc/pg_exporter.yml /etc/pg_exporter/pg_exporter.yml

COPY *.yml /etc/pg_exporter/

ENV PG_EXPORTER_CONFIG=/etc/pg_exporter

USER 65534