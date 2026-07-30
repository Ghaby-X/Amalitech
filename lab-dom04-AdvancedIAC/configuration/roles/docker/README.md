# docker

Installs Docker Engine, enables the service, and installs the Docker Compose v2 CLI plugin.

## What it does

1. Loads OS-family-specific variables from `vars/<os_family>.yml`, if one exists for the target host (falls back to `defaults/main.yml` otherwise).
2. Installs Docker from the distro's own default repos (not Docker Inc.'s official repo), via the generic `ansible.builtin.package` module.
3. Ensures the `docker` service is started and enabled.
4. Creates the CLI plugins directory and downloads the Docker Compose v2 binary into it.

## Why Compose is installed separately

This role installs Docker from each distro's own package (`docker` on Amazon Linux, historically `docker.io` on Debian/Ubuntu), not from Docker Inc.'s official `docker-ce` repo. Those distro-native packages give you the engine, CLI, and containerd, but not the Compose plugin or Buildx, since those are only bundled together when installing from Docker Inc.'s own repo.

Docker Compose v2 isn't a standalone binary you run directly (that was v1's `docker-compose`); it's a CLI plugin the `docker` command auto-discovers by looking for an executable named `docker-compose` inside a `cli-plugins` directory. Since the distro package doesn't ship that plugin, this role downloads the pinned release binary from GitHub directly, matching the host's CPU architecture, and drops it into `docker_cli_plugins_dir`. That's also what makes `docker compose` (with a space) work as a subcommand, and what `community.docker.docker_compose_v2` depends on elsewhere in this project.

## OS support

Only Amazon Linux 2023 has an OS-specific vars file (`vars/RedHat.yml`). If this role runs against a host whose `ansible_facts['os_family']` doesn't match an existing vars file, it silently falls back to `defaults/main.yml`, which assumes the same package name (`docker`), a fallback that's untested against any OS other than Amazon Linux.

## Variables

| Variable | Default | Description |
|---|---|---|
| `docker_compose_version` | `v2.29.7` | Pinned Compose release to download, independent of whatever Docker Engine version the distro repo carries. |
| `docker_cli_plugins_dir` | `/usr/local/lib/docker/cli-plugins` | Where the `docker` CLI looks for plugins; must exist before the Compose binary can be placed there. |
| `docker_service_state` | `started` | Passed to `ansible.builtin.service`. |
| `docker_service_enabled` | `true` | Whether the service starts on boot. |
| `docker_package_name` | `docker` | Overridden per OS family in `vars/`; this is the fallback. |
| `docker_package_update_cache` | `true` | Refreshes the package manager's repo metadata before installing. |
