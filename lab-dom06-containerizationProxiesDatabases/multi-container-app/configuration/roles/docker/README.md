# docker

Copied from `lab-dom04-AdvancedIAC/configuration/roles/docker` (verified against Amazon Linux 2023). See that role's README for the full rationale on why Compose is installed separately from the Docker package.

Installs Docker Engine, enables the service, and installs the Docker Compose v2 CLI plugin.

## Variables

| Variable | Default | Description |
|---|---|---|
| `docker_compose_version` | `v2.29.7` | Pinned Compose release to download. |
| `docker_cli_plugins_dir` | `/usr/local/lib/docker/cli-plugins` | Where the `docker` CLI looks for plugins. |
| `docker_service_state` | `started` | Passed to `ansible.builtin.service`. |
| `docker_service_enabled` | `true` | Whether the service starts on boot. |
| `docker_package_name` | `docker` | Overridden per OS family in `vars/`. |
| `docker_package_update_cache` | `true` | Refreshes the package manager's repo metadata before installing. |
