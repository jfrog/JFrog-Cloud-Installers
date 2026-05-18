# JFrog Dell Blueprints

Dell Blueprints that deploy JFrog products onto Kubernetes clusters using the Dell Application Platform (DAP). Each blueprint is a TOSCA-based definition (`dell_1_1`) that wraps an official JFrog Platform Helm chart and exposes it as a self-service catalog item within DAP.

## Available Blueprints

### jfrog-platform

Deploys **JFrog Platform (Artifactory)** on a Kubernetes cluster using the official `jfrog/jfrog-platform` Helm chart.

**What it provisions:**

- Kubernetes Namespace (created before Helm install via Kubernetes plugin)
- JFrog Artifactory with NGINX reverse-proxy (LoadBalancer service)
- PostgreSQL with persistent storage (bundled or external)
- Kubernetes Secrets for database credentials and license (created via Kubernetes plugin before Helm install)
- Configurable sizing templates (`xsmall` through `2xlarge`)
- Optional NGINX Ingress Controller and Kubernetes Ingress for external access
- Custom NGINX `mainConf` with optimised `worker_processes` (merged into sizing templates at build time)

**Inputs:**

| Group | Input | Description | Default |
|---|---|---|---|
| Credentials | `k8s_credentials` | DAP secret storing Kubernetes credentials (ssl_ca_cert, token) | — |
| Infrastructure | `namespace` | Target Kubernetes namespace | `jfrog-platform` |
| Persistence | `persistence` | Persistence mode: `storage_class` (PVC) or `storage_type` (file-system/nfs) | `storage_class` |
| Persistence | `persistence_type` | Storage type: `file-system` or `nfs` (visible when `storage_type` selected) | `file-system` |
| Persistence | `filesystem_cache_enabled` | Enable local file-system cache (`"true"` / `"false"`) | `"false"` |
| Persistence | `storage_class` | Kubernetes StorageClass name (visible when `storage_class` selected) | `""` (cluster default) |
| Persistence | `pvc_access_mode` | PVC access mode (visible when `storage_class` selected) | `ReadWriteOnce` |
| Persistence | `pvc_size` | PVC storage size (visible when `storage_class` selected) | `20Gi` |
| Persistence | `nfs_ip` | NFS server IP address (visible for nfs) | — |
| Persistence | `nfs_capacity` | NFS storage capacity (visible for nfs) | `200Gi` |
| Database | `postgresql_enabled` | Deploy bundled PostgreSQL subchart (`"true"` / `"false"`) | `"true"` |
| Database | `create_bundled_db_secret` | Create K8s secret with bundled DB credentials: 0 = No, 1 = Yes (visible when bundled) | `0` |
| Database | `create_external_db_secret` | Create K8s secret with external DB credentials: 0 = No, 1 = Yes (visible when external) | `0` |
| Database | `database_admin_password` | DAP general secret for PostgreSQL admin password (visible when external) | — |
| Database | `database_host` | PostgreSQL hostname (visible when external) | `jfrog-platform-postgresql` |
| Database | `database_port` | PostgreSQL port (visible when external) | `5432` |
| Database | `database_ssl_mode` | PostgreSQL SSL mode (visible when external) | `disable` |
| Database | `database_user` | DAP general secret for database username (visible when external) | — |
| Database | `database_password` | DAP general secret for database password (visible when external) | — |
| Chart Settings | `release_name` | Helm release name | `jfrog-platform` |
| Chart Settings | `chart_version` | Helm chart version (injected at build time) | `0.0.0` |
| Chart Settings | `sizing_template` | Resource sizing profile (see Sizing Templates below) | `small` |
| Licensing | `create_license_secret` | Create K8s license secret: 0 = No (trial mode), 1 = Yes | `0` |
| Licensing | `license_secret_ref` | DAP general secret containing raw Artifactory license text | — |
| Networking | `nginx_enabled` | Bundled NGINX with LoadBalancer (`"true"` / `"false"`) | `"true"` |
| Networking | `ingress_enabled` | Kubernetes Ingress (visible when NGINX disabled) | `"false"` |
| Networking | `install_ingress_controller` | Install ingress-nginx controller: 0 = No, 1 = Yes (visible for ingress) | `0` |
| Networking | `ingress_class_name` | Kubernetes IngressClass name (visible for ingress) | `nginx` |
| Networking | `ingress_host` | DNS hostname for the Ingress resource (visible for ingress) | `""` |

**Hidden inputs (auto-controlled):**

No hidden database toggles. Both `create_bundled_db_secret` and `create_external_db_secret` are user-controlled visible inputs.

**Sizing Templates:**

| Template | Replicas | Artifactory CPU / Memory | PostgreSQL Memory | Recommended For |
|---|---|---|---|---|
| `xsmall` | 1 | 1 CPU / 4 Gi | 8 Gi | Dev/test, minimum viable |
| `small` | 1 | 1 CPU / 5 Gi | 16 Gi | Small teams (~50 users) |
| `medium` | 2 | 1 CPU / 5 Gi each | 32 Gi | Medium teams, HA (~500 users) |
| `large` | 3 | 2 CPU / 12 Gi each | 64 Gi | Large organizations (~2000 users) |
| `xlarge` | 4 | 2 CPU / 16 Gi each | 128 Gi | Very large organizations (~5000 users) |
| `2xlarge` | 6 | 4 CPU / 24 Gi each | 256 Gi | Enterprise-scale (5000+ users) |

> **Note:** Medium and above require Enterprise licenses (one per replica). CPU/Memory values shown are for the Artifactory main container only; each tier also scales NGINX, Router, Access, Metadata, and other sidecar containers proportionally.

**Outputs:**

| Capability | Description |
|---|---|
| `release_name` | Deployed Helm release name |
| `namespace` | Kubernetes namespace of the deployment |
| `sizing` | Applied sizing template |
| `platform_url_ingress` | Artifactory URL when using ingress deployment mode |
| `platform_url_command` | kubectl command to get LoadBalancer IP (nginx mode) |

## Examples

The `examples/` directory contains sample input configurations for common deployment scenarios. These are **not** included in the release zip — they are for reference only.

| Example | Description |
|---|---|
| [bundled-postgres-trial.yaml](examples/bundled-postgres-trial.yaml) | Simplest deployment — bundled PostgreSQL, trial mode, LoadBalancer |
| [bundled-postgres-licensed.yaml](examples/bundled-postgres-licensed.yaml) | Bundled PostgreSQL with license from DAP secret |
| [external-postgres-licensed.yaml](examples/external-postgres-licensed.yaml) | External PostgreSQL with credentials from DAP secrets |
| [ingress-mode.yaml](examples/ingress-mode.yaml) | Kubernetes Ingress mode with optional ingress-nginx controller |
| [ha-production.yaml](examples/ha-production.yaml) | Full HA production: external DB, HA license, Ingress, PVC storage |

Each file includes DAP UI steps and explains what happens behind the scenes (hidden toggles, K8s Secrets created, etc.).

## Repository Structure

```
├── .github/workflows/
│   ├── dell-release.yaml                   # GitHub Actions – builds zip & publishes release
│   └── dell-validate-blueprints.yaml       # PR validation workflow
├── blueprints/
│   └── jfrog-platform/
│       ├── blueprint.yaml                  # Top-level imports, labels (thin file)
│       ├── CHANGELOG.yaml                  # Version changelog
│       ├── top_level/
│       │   ├── inputs.yaml                 # User-visible inputs + input_groups
│       │   ├── inputs_hidden.yaml          # Hidden/auto-controlled inputs
│       │   └── outputs.yaml                # Capabilities (outputs)
│       └── application/
│           ├── 00_namespace_and_secrets.yaml  # K8s Namespace + Secrets (license, DB creds)
│           ├── 01_ingress_nginx.yaml          # Ingress-nginx Helm release (conditional)
│           └── 02_jfrog_platform.yaml         # JFrog Platform Helm release
├── Makefile                                # Build, sync, validate, clean targets
├── scripts/
│   ├── release.sh                          # Interactive release helper
│   ├── sync_sizing_templates.sh            # Sync sizing templates from chart
│   ├── sync_networking_modes.sh            # Extract nginx mainConf from chart
│   ├── merge_nginx_config.py              # Merge nginx mainConf into sizing templates
│   ├── validate_blueprints.sh              # Local/CI blueprint validator
│   └── get_latest_jfrog_platform_version.sh
├── examples/                               # Sample input configs (not in zip)
│   ├── bundled-postgres-trial.yaml
│   ├── bundled-postgres-licensed.yaml
│   ├── external-postgres-licensed.yaml
│   ├── ingress-mode.yaml
│   └── ha-production.yaml
├── build/                                  # (gitignored) build-time artifacts
│   └── nginx-main-conf.txt                 # Extracted nginx.conf from chart (worker_processes overridden)
└── README.md
```

## Prerequisites

- **Dell Application Platform (DAP)** with the Helm plugin (`>=1.4.0.0, <2.0.0.0`) and Kubernetes plugin (`>=3.3.0.0, <4.0.0.0`)
- A Kubernetes cluster with a valid kubeconfig stored as a DAP secret (`type: k8s`)
- **For licensed deployments:** An Artifactory license stored as a **DAP general secret** containing the raw license text (starting with `products:`). Do **not** base64-encode the value — the Helm chart handles encoding internally. Set `create_license_secret` to `1` and select the secret as `license_secret_ref` when deploying. If omitted (`create_license_secret: 0`), Artifactory starts in trial mode.
- **For external database:** Three DAP general secrets storing the PostgreSQL admin password, application database username, and application database password. These are referenced by `database_admin_password`, `database_user`, and `database_password` inputs (visible when `postgresql_enabled` is `"false"`). Set `create_external_db_secret` to `1` to create the K8s secret with these values.

## Blueprint Validation

Blueprint validation runs automatically in pull requests via the GitHub Actions workflow `Validate Dell Blueprints`.

Run the same validator locally:

```bash
./scripts/validate_blueprints.sh
```

For branch protection, set the required status check to:

- `Validate Dell Blueprints / validate`

## Releasing a New Version

Releases are automated via GitHub Actions. When a version tag (`JFrog-Dell-Blueprints/v*`) is pushed, the workflow:

1. Syncs sizing templates from the JFrog Platform Helm chart
2. Extracts the NGINX `mainConf` from the chart (overriding `worker_processes` to prevent OOM)
3. Merges the `mainConf` into each sizing template's `nginx:` block (so the single `values_file` contains everything)
4. Strips Go template whitespace trim modifiers (`{{-`/`-}}`) to preserve newlines in the rendered `nginx.conf`
5. Injects the resolved chart version into `inputs_hidden.yaml`
6. Zips the blueprint and sizing templates into a release archive

The archive extracts to a versioned root folder:

- `jfrog-dell-<version>/blueprint.yaml`
- `jfrog-dell-<version>/CHANGELOG.yaml`
- `jfrog-dell-<version>/top_level/` (inputs, outputs)
- `jfrog-dell-<version>/application/` (Helm release nodes)
- `jfrog-dell-<version>/sizing/` (generated from Helm chart, with nginx config merged)

The `scripts/` directory is **not** included in the release artifact — it is only used during development and CI.

### Building Artifacts Locally

Build the zip artifact using `make`:

```bash
make all VERSION=1.0.0
```

Specify a Helm chart version:

```bash
make all VERSION=1.0.0 CHART_VERSION=11.5.2
```

The artifact is written to `target/jfrog-dell-<VERSION>.zip`. Sizing templates and NGINX config are automatically synced from the Helm chart and merged during the build.

Other useful targets:

```bash
make sync                       # Sync sizing + nginx config only
make validate                   # Run blueprint validation
make clean                      # Remove target/ and build/
```

### Interactive Release Process

Use the helper script to walk through the release process interactively:

```bash
./scripts/release.sh
```

Or run it non-interactively:

```bash
NEW_VERSION=1.0.0 ./scripts/release.sh -y
```

The script will:

1. Check out the default branch and pull latest
2. Create a `JFrog-Dell-Blueprints/v<version>` branch
3. Push the branch and create an annotated `JFrog-Dell-Blueprints/v<version>` tag
4. Push the tag, which triggers the GitHub Actions workflow to build and publish the release

#### Specifying Helm Chart Version in CI

By default, releases sync sizing templates from the **latest** JFrog Platform Helm chart version. To use a specific chart version, trigger the workflow manually with `chart_version` input:

```bash
gh workflow run release.yaml -f chart_version=11.5.1
```

## Checking the Latest JFrog Platform Helm Chart Version

Run the helper script to fetch the latest stable version from `charts.jfrog.io`:

```bash
./scripts/get_latest_jfrog_platform_version.sh
```

Use the returned version as the `chart_version` input when deploying the blueprint, or as the `CHART_VERSION` parameter when building locally.

## DAP Platform Notes

Some DAP/Cloudify-specific behaviors affect blueprint design:

- **Boolean inputs and Helm**: DAP passes Python `True`/`False` to the Helm plugin, but Helm expects lowercase `"true"`/`"false"`. Use `type: string` with `valid_values: ["true", "false"]` for any value passed to `set_values`.
- **Integer for scalable instances**: `capabilities.scalable.default_instances` requires an integer. DAP cannot convert `type: boolean` to integer. Use `type: integer` with `valid_values: [0, 1]`.
- **Integer toggle pattern**: Integer inputs with `valid_values: [0, 1]` drive `scalable.default_instances` on conditional nodes. Hidden integer inputs with `only_with` do **not** reliably resolve to `0` when the condition is unmet. Both `create_bundled_db_secret` and `create_external_db_secret` are kept visible so the user explicitly controls which DB credentials secret is created.
- **Dict values in set_values**: The Helm plugin raises `unhashable type: 'dict'` when dict-lookup patterns are used in `set_values`. Use simple `type: string` hidden inputs instead.
- **Values file paths**: The Helm plugin only resolves file paths for the `values_file` property. Paths in `--values` flags are passed as-is to the CLI and will fail. Build-time merge into the `values_file` is the workaround.
- **License via K8s secret**: License content is stored in a DAP general secret, then written to a K8s Secret (`jfrog-platform-license`) via `dell.nodes.kubernetes.resources.Secret`. The Helm chart references the secret via `artifactory.artifactory.license.secret` and `dataKey`. This avoids multi-line license issues with Helm `--set`.
- **Database credentials via K8s secrets**: Database credentials are written to a K8s Secret (`jfrog-platform-database-creds`) before Helm install. Two mutually exclusive nodes handle bundled (hardcoded defaults) and external (DAP secrets) modes. The user controls which node is active via visible integer toggles: `create_bundled_db_secret` (visible when `postgresql_enabled: "true"`) and `create_external_db_secret` (visible when `postgresql_enabled: "false"`). Both default to `0`. The JDBC URL is constructed via `concat` to avoid Helm `--set` int64 port coercion (`%!g(int64=5432)`).
- **Namespace creation**: The namespace is created explicitly via `dell.nodes.kubernetes.resources.Namespace` before secrets and Helm install. The Helm release also includes `--create-namespace` as an idempotent fallback.
- **NGINX mainConf**: Use the chart's `nginx.mainConf` value to override the default `nginx.conf` (e.g., to set `worker_processes 4` and prevent OOM). This is merged into sizing templates at build time. The `additionalResources` + `customConfigMap` approach is unnecessary.
- **Secret inputs and only_with**: `type: secret_key` inputs resolve to `None` when hidden via `only_with`. This is safe as long as the consuming node is also scaled to `0` (not instantiated) when the condition is not met. Hidden integer inputs with `only_with` do **not** reliably resolve to `0` when the condition is unmet - avoid relying on hidden integer toggles for mutual exclusion. Use visible user-controlled toggles instead.
- **Networking toggles**: `nginx_enabled` and `ingress_enabled` must be user-visible inputs (not hidden). DAP cannot derive one input's value from another, so the user must explicitly set both when switching between nginx and ingress modes.
- **Input derivation**: DAP cannot derive one input's value from another. For conditional resource creation, use visible integer toggles with `only_with` so only the relevant toggle is shown in the UI. Both nodes are mutually exclusive (each depends on `create_namespace`).

## Contributing

Please read [CONTRIBUTIONS.md](CONTRIBUTIONS.md) for details on how to contribute to this project.

## License

Copyright 2026 JFrog Ltd.

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for the full license text.
