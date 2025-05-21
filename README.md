# OOM-Protected PostgreSQL Docker Image

This Docker image extends `percona/percona-postgresql-operator:2.6.0-ppg16.8-postgres` with configurations to reduce the chances of PostgreSQL being killed by the Out-of-Memory (OOM) killer in Linux.

## Features

- Sets OOM score adjustment to `-900` for the PostgreSQL postmaster process
- Uses a root-to-user approach to ensure proper privileges for OOM adjustment
- Intelligently identifies and protects the PostgreSQL postmaster process
- Preserves the original container entrypoint and behavior
- Multi-architecture support (amd64/x86_64 and arm64/aarch64)

## How It Works

This image uses a focused approach to OOM protection specifically targeting the PostgreSQL postmaster process:

1. The container temporarily runs as root to gain necessary privileges
2. Our wrapper script sets the initial OOM score adjustment to -900
3. A background monitor continuously identifies and adjusts the PostgreSQL postmaster process
4. The script exports PG_OOM environment variables for child process handling
5. The wrapper script executes the original entrypoint with the original user (UID 26)

This approach ensures that the PostgreSQL postmaster process (the main database process) is the last process to be killed by the Linux OOM killer if memory becomes scarce.

## Technical Details

The wrapper script uses multiple methods to identify the PostgreSQL postmaster process:

1. Pattern matching for `postgres -D /pgdata/pg`
2. Parent-child relationship detection for postgres processes
3. Fallback to single postgres process detection

All actions are logged to `/tmp/postgres-oom-adjuster.log` for transparency and debugging.

## Usage

### Basic Docker Usage

```bash
docker build -t oom-protected-postgres .
docker run -d --name postgres oom-protected-postgres
```

## Continuous Integration / Deployment

This repository includes a GitHub Action that automatically builds and pushes the Docker image to GitHub Container Registry (ghcr.io) whenever changes are pushed to the main branch.

### Automated Multi-Architecture Builds

The workflow:
1. Builds the Docker image for multiple architectures (amd64 and arm64)
2. Tags it with:
   - `latest` tag
   - Short SHA of the commit (e.g., `sha-a1b2c3d`)
   - Date in YYYYMMDD format
3. Pushes it to GitHub Container Registry as a multi-architecture manifest

### Using the Pre-built Image

Once built, you can pull the image directly, and Docker will automatically select the right architecture for your system:

```bash
docker pull ghcr.io/[your-username]/mpg-postgres-image/oom-protected-postgres:latest
```

## References

- [PostgreSQL documentation on kernel resources](https://www.postgresql.org/docs/current/kernel-resources.html)
- [Percona blog on Out-of-Memory killer](https://www.percona.com/blog/out-of-memory-killer-or-savior/)
- [Docker Hub: percona/percona-postgresql-operator](https://hub.docker.com/r/percona/percona-postgresql-operator)
- [Patroni documentation](https://patroni.readthedocs.io/)
- [Percona Operator for PostgreSQL - Custom Resource options](https://docs.percona.com/percona-operator-for-postgresql/2.0/operator.html?h=custom+resource#patronidynamicconfiguration)
