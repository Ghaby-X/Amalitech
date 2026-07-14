# Create a YAML Configuration for an Application

**Learning objective:** Construct well-formed configuration files using YAML and JSON syntax.

A YAML configuration file for a sample web application, validated and
converted to JSON.

## Files

| File | Purpose |
|---|---|
| `app-config.yaml` | The application configuration: `application`, `server`, and `database` sections. |
| `app-config.json` | The same configuration converted to JSON via `yq`. |

## Steps taken

1. Created `app-config.yaml` defining the application's name, version, and
   environment; the server's host and port; and the database's engine,
   host, port, and credentials.
2. Validated the file's structure and indentation using an online YAML
   validator (https://yamlvalidator.com).
3. Converted the YAML file to JSON with `yq`:
   ```bash
   yq -p yaml -o json app-config.yaml > app-config.json
   ```

## Notes

- Indentation uses 2 spaces per level, no tabs, consistent throughout the
  file so YAML's whitespace-sensitive parsing doesn't break.
- `password: mysecurepassword` is a plaintext placeholder for lab purposes
  only; a real config would source secrets from a secrets manager or
  environment variable instead of committing them to the file.

## Expected outcome

A valid YAML configuration file that accurately represents the
application's structure and parameters, plus its equivalent JSON
representation.
