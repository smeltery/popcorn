---
hide:
  - toc
---

# Self-hosting

Run your own [Popcorn server](../index.md) when you want full ownership and
control over recordings, streams, accounts, and retention policy.

Popcorn server can be deployed for public or internal/private use in a
containerized environment. When an OCI image is published, it is available from
GitHub Container Registry at
[`ghcr.io/smeltery/popcorn-server`](https://github.com/smeltery/popcorn/pkgs/container/popcorn-server).

On NixOS you can instead use the [NixOS module](nixos.md), which runs the server
as a systemd service and can provision a PostgreSQL database for you.

Requirements:

- OCI runtime, e.g. [Docker](https://www.docker.com/),
  [Podman](https://podman.io/), [Kubernetes](https://kubernetes.io/)
- 512 MB of RAM minimum (for a personal instance), 1 GB recommended (for a
  community/company instance)
- [PostgreSQL](http://www.postgresql.org/download/) 14.0+ database server
- SMTP server (optional) - a dedicated service or your email provider's SMTP
  endpoint, for delivering login links. A single-user instance can skip it and
  read login links from the logs instead; see [Email](configuration.md#email).

To get started, follow the [quick start guide](quick-start.md), which provides a
template for a standard popcorn server configuration using
[docker-compose](https://docs.docker.com/compose/). This configuration includes
a PostgreSQL container and supports HTTPS, allowing you to set up a complete,
secure popcorn server easily.

Once your server is up and running, you'll be able to upload your recordings by
pointing [popcorn CLI](../../cli/index.md) to the server using the
`POPCORN_SERVER_URL` environment variable:

=== "CLI 3.x"

    ```sh
    export POPCORN_SERVER_URL=https://popcorn.example.com
    popcorn upload demo.pop
    ```

=== "CLI 2.x"

    ```sh
    export POPCORN_API_URL=https://popcorn.example.com
    popcorn upload demo.pop
    ```


If you need help with installation or maintenance, see
[support](../../../support.md).
