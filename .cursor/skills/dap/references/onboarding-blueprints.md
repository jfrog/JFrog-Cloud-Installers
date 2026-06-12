# DAP Onboarding — Blueprints

## Upload via UI

1. In the Orchestrator UI, go to **Inventory** → **Blueprints** → **Upload Blueprint**
2. Choose your YAML file, enter a Blueprint ID, optional description
3. Click **Upload** — status shows `uploaded` when complete

## Upload via CLI

```bash
# Lint first (required)
bpa blueprint lint --file blueprint.yaml --verify

# Upload
bpa orchestrator blueprints upload --file blueprint.yaml --id my-blueprint --revision 1.0.0

# Confirm upload completed
bpa orchestrator blueprints get my-blueprint
```

## Finding starter templates

Use the knowledge base — search for working examples rather than writing from scratch:

```bash
# General search
bpa knowledge blueprints find "<what you want to deploy>"
bpa knowledge blueprints get <id> --include-files

# Examples by technology
bpa knowledge blueprints find "helm chart kubernetes"
bpa knowledge blueprints find "ansible playbook"
bpa knowledge blueprints find "terraform module"
bpa knowledge blueprints find "docker container"
bpa knowledge blueprints find "vsphere virtual machine"
```

Use the retrieved blueprint as a starting point — adapt inputs, node types, and properties to your use case. For authoring rules and structure, see the main skill and `references/blueprint-examples.md`.
