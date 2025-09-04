# PG Exporter for Managed Postgres

This container provides a custom-configured [pg_exporter](https://github.com/pgsty/pg_exporter) image that serves as a metrics sidecar for Managed Postgres instances.

## Purpose

The pg-exporter container runs alongside Managed Postgres instances to collect and expose PostgreSQL and PGBouncer metrics in Prometheus format, enabling comprehensive monitoring of database performance and health.

## Architecture

The image uses a multi-stage Docker build to combine:
1. The default pg_exporter configuration with all built-in collectors (~87 collectors for PostgreSQL and PGBouncer)
2. Custom collectors specific to our Managed Postgres needs

## Features

- Based on `pgsty/pg_exporter`
- Includes all default PostgreSQL collectors (v9.4-v18+)
- Includes all default PGBouncer collectors (v1.8-v1.24+)
- Custom collectors for enhanced monitoring
- Multi-architecture support (linux/amd64, linux/arm64)

## Custom Collectors

Current custom collectors in `/metrics`:

- **slow_queries.yml**: Slow query monitoring using pg_stat_monitor extension (queries > 1s)

## Adding New Collectors

To add new metric collectors, simply create a new `.yml` file in this directory. The build process automatically includes all YAML configuration files in the container.

### Query Configuration Structure

Each collector configuration file should follow this YAML structure:

```yaml
collector_name:
  name: collector_name           # Metric namespace
  desc: Description of metrics    # Human-readable description
  query: |                       # SQL query to execute
    SELECT column1, column2
    FROM table;
  ttl: 10                        # Cache time in seconds
  timeout: 1                     # Query timeout in seconds
  min_version: 90500            # Minimum PostgreSQL version (optional)
  tags: [ pgbouncer ]           # Tags for metric filtering (optional)
  metrics:
    - column1:
        usage: LABEL             # LABEL, GAUGE, COUNTER, or DISCARD
        description: Column description
    - column2:
        usage: GAUGE
        description: Numeric metric value
```

### Metric Types

- **LABEL**: Used for text values that become Prometheus labels
- **GAUGE**: For numeric values that can go up or down
- **COUNTER**: For cumulative values that only increase
- **DISCARD**: Ignore this column in the output

### Best Practices

1. Use appropriate TTL values to balance freshness vs. database load
2. Set reasonable timeout values for complex queries
3. Use version constraints when queries depend on specific PostgreSQL features
4. Tag collectors appropriately (e.g., `pgbouncer` for PGBouncer-specific metrics)
5. Test queries manually before adding them to ensure they work correctly

## How It Works

1. The Dockerfile copies the default `/etc/pg_exporter.yml` from the base image to `/etc/pg_exporter/`
2. All custom `.yml` files in this directory are added to the same location
3. The `PG_EXPORTER_CONFIG` environment variable points to the directory
4. pg_exporter loads all `.yml` files from the directory, combining built-in and custom collectors

## Build

The image is automatically built and pushed to GitHub Container Registry via GitHub Actions when changes are pushed to the main branch.

### Manual Build

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/superfly/pg-exporter:latest .
```

## Deployment

The container is deployed as a sidecar in Managed Postgres Kubernetes pods, configured to connect to either PostgreSQL or PGBouncer instances via the `PG_EXPORTER_URL` environment variable.