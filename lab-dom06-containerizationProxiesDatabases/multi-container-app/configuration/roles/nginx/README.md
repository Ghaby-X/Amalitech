# nginx

Copied from `lab-dom04-AdvancedIAC/configuration/roles/nginx` (verified against Amazon Linux 2023). See that role's README for the full task-by-task rationale.

Installs nginx, clears the distro's default vhost, and (if the caller supplies a template) deploys and validates a site-specific config.

Here it's used as a reverse proxy in front of the dockerized `web` container (`../../templates/nginx-reverse-proxy.conf.j2`), not to serve static files - `nginx_template`/`nginx_site_conf_path` are set by `site.yml`, same ownership split as `lab-dom04`.

## Variables

| Variable | Default | Description |
|---|---|---|
| `nginx_package_name` | `nginx` | Overridden per OS family in `vars/`. |
| `nginx_package_update_cache` | `true` | Refreshes the package manager's repo metadata before installing. |
| `nginx_default_conf_path` | `/etc/nginx/conf.d/default.conf` | Path to the distro's stock default vhost, removed during setup. |
| `nginx_needs_enabled_symlink` | `false` | Whether the OS uses a `sites-available`/`sites-enabled` split (Debian-style). Amazon Linux doesn't. |
| `nginx_site_conf_link_path` | `""` | Symlink destination in `sites-enabled`, only used when `nginx_needs_enabled_symlink` is true. |
| `nginx_service_state` | `started` | Passed to `ansible.builtin.service`. |
| `nginx_service_enabled` | `true` | Whether the service starts on boot. |
| `nginx_template` | *(undefined)* | Must be set by the calling playbook. Path to the `.j2` template to render as the site's server block. |
| `nginx_site_conf_path` | *(undefined)* | Must be set by the calling playbook. Destination path for the rendered config. |

## Handlers

`Reload nginx`: reloads the service; notified by the default-block removal, the template deploy, and the symlink tasks.
