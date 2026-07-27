# nginx

Installs nginx, clears the distro's default vhost, and (if the caller supplies a template) deploys and validates a site-specific reverse proxy config.

## What it does

1. Loads OS-family-specific variables from `vars/<os_family>.yml`, if one exists for the target host (falls back to `defaults/main.yml` otherwise).
2. Installs nginx via the generic `ansible.builtin.package` module.
3. Removes the distro's default server block, so it can't conflict with whatever site config gets deployed.
4. If the caller passed `nginx_template` and `nginx_site_conf_path`, renders that template to `nginx_site_conf_path` and validates the full, real `/etc/nginx/nginx.conf` afterward (not the fragment in isolation, since a bare `server {}` block isn't valid on its own).
5. On Debian-family hosts (`nginx_needs_enabled_symlink: true`), symlinks the deployed conf into `sites-enabled`.
6. Ensures the `nginx` service is started and enabled.


## OS support

Only Amazon Linux 2023 has a real, verified vars file (`vars/RedHat.yml`).

## Variables

| Variable | Default | Description |
|---|---|---|
| `nginx_package_name` | `nginx` | Overridden per OS family in `vars/`; this is the fallback. |
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
