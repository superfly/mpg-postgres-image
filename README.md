# OOM-Protected PostgreSQL Docker Image

This Docker image extends `percona/percona-postgresql-operator:2.6.0-ppg16.8-postgres` with configurations to reduce the chances of PostgreSQL being killed by the Out-of-Memory (OOM) killer in Linux.

## Features

- Sets OOM score adjustment to `-900` for the Patroni process (which manages PostgreSQL)

## How It Works

This image works with the Percona PostgreSQL Operator architecture:

1. Patroni is the process manager that starts and manages PostgreSQL
2. Our wrapper script sets the OOM score adjustment to -1000 for the Patroni process
3. This adjustment is inherited by PostgreSQL processes, protecting them from OOM killer
4. The wrapper script preserves the original entrypoint behavior of the parent image

## Usage

### Basic Usage

```bash
docker build -t oom-protected-postgres .
docker run -d --name postgres oom-protected-postgres
```

## Continuous Integration / Deployment

This repository includes a GitHub Action that automatically builds and pushes the Docker image to GitHub Container Registry (ghcr.io) whenever changes are pushed to the main branch.

### Automated Builds

The workflow:
1. Builds the Docker image
2. Tags it with both `latest` and the short commit SHA
3. Pushes it to GitHub Container Registry

### Using the Pre-built Image

Once built, you can pull the image directly:

```bash
docker pull ghcr.io/[your-username]/mpg-postgres-image/oom-protected-postgres:latest
```

### GitHub Action Configuration

The GitHub Action configuration is defined in `.github/workflows/build-and-push.yml`. If you fork this repository, you'll need to ensure your repository has permission to push packages. You can configure this in your repository settings under "Actions" > "General" > "Workflow permissions".

## References

- [PostgreSQL documentation on kernel resources](https://www.postgresql.org/docs/current/kernel-resources.html)
- [Percona blog on Out-of-Memory killer](https://www.percona.com/blog/out-of-memory-killer-or-savior/)
- [Docker Hub: percona/percona-postgresql-operator](https://hub.docker.com/r/percona/percona-postgresql-operator)
- [Patroni documentation](https://patroni.readthedocs.io/)
