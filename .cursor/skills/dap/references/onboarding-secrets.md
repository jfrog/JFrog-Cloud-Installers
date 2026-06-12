# DAP Onboarding — Secrets

## Create via UI

1. **Secrets** → **Create Secret**
2. Enter a Key (referenced in blueprints), a Value, optional description → **Create**

To update or delete: find the secret in the list → three-dot menu.

## Create via CLI

```bash
bpa orchestrator secrets create --key my_secret --value "my-value"
bpa orchestrator secrets list
bpa orchestrator secrets get my_secret
```

## Use in blueprints

Declare a `secret_key` input and reference it via `get_secret`:

```yaml
inputs:
  db_password:
    type: secret_key
    display_label: DB Password
    description: Database password secret key name

node_templates:
  my_db:
    type: dell.nodes.some.Type
    properties:
      password: { get_secret: { get_input: db_password } }
```

Never pass a literal string to `get_secret`. Always resolve through an input.
