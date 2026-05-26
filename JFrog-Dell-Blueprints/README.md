# JFrog Dell Blueprints

Dell-certified TOSCA (`dell_1_1`) blueprints that deploy JFrog Platform onto Kubernetes via the Dell Application Platform (DAP). The bundle follows the Dell multi-component structure: a top-level orchestrator delegates to four component blueprints (input validator, stack verifier, optional ingress-nginx, and the JFrog Platform Helm release) that ship as a single `manifest.yaml`-indexed bundle. Initial release is **v1.0.0**.

## Bundle Architecture

```
JFrog Platform Top-Level (orchestrator)
        │
        ├── Input Validator        (central agent — Python, no K8s)
        ├── Stack Verifier          (K8s Job — kubectl-based checks)
        ├── Ingress NGINX Component (optional Helm release)
        └── JFrog Platform Component (fetch_labels + Helm release)
```

Execution order enforced via `dell.relationships.depends_on`: input validation → stack verification → optional ingress install → JFrog Platform install.

## Available Blueprints

| Blueprint ID | Type | Purpose |
|---|---|---|
| `jfrog_platform_top_level` | environment | Top-level orchestrator that wires the four components together. This is the deployment entrypoint shown to end-users. |
| `jfrog_input_validator` | utility | Validates user inputs (formats + DAP secret existence/structure) on the central deployment agent. |
| `jfrog_stack_verifier` | utility | Runs a Kubernetes Job to validate cluster prerequisites (Kubernetes version, node readiness, storage class, ingress class, external DB connectivity). |
| `ingress_nginx_component` | environment (helm) | Installs the optional ingress-nginx controller. Skipped when `install_ingress_controller=0`. |
| `jfrog_platform_component` | environment (helm) | Fetches infrastructure labels (SaaS DAPO `target_id`), creates namespace + DAP-derived K8s secrets, and installs the JFrog Platform Helm chart with `rollback: false`. |

## Top-Level Inputs (User-Facing)

The top-level orchestrator gathers all user-visible inputs in one UI and forwards subsets to each component. Highlights:

| Group | Input | Purpose |
|---|---|---|
| Credentials | `k8s_credentials` | DAP `k8s` secret with `ssl_ca_cert`/`token` and (for SaaS DAPO) `configuration.proxy_settings`. |
| Credentials | `target_deployment_id` | DAP infrastructure deployment ID. Required so SaaS DAPO can copy the `target_id` label onto the deployment. |
| Credentials | `container_registry_credentials_secret` | Optional DAP `basic_auth` secret for pulling the verifier image from a private registry. |
| Database | `postgresql_enabled` | `"false"` by default - the bundle assumes external PostgreSQL out of the box. Set to `"true"` only for trial / dev / single-replica deployments. |
| Database | `database_credentials` | DAP `basic_auth` secret with `username`/`password` for the Artifactory PostgreSQL user. **Required when `postgresql_enabled="false"`** (i.e., the default). |
| Database | `database_admin_password` | DAP `general` secret holding the Postgres admin password. **Required when `postgresql_enabled="false"`**. |
| Chart Settings | `ingress_nginx_repo_url`, `jfrog_helm_repo_url`, `container_registry_name` | Override the default external URLs to point at internal mirrors for air-gapped deployments. |
| Networking | `install_ingress_controller` | When `1`, the ingress_nginx_component is deployed; when `0`, the entire component (Binary + Repo + Release) is skipped. |

The full set of user-visible inputs lives in [blueprints/jfrog_platform_top_level/top_level/inputs.yaml](blueprints/jfrog_platform_top_level/top_level/inputs.yaml).

### Hidden Inputs

`top_level/inputs_hidden.yaml` only contains values that are not user-visible:

- `blueprint_ids` — mapping of logical names to catalog blueprint IDs.
- `*_revision_id` — 4-part `MAJOR.MINOR.PATCH.BUILD` revision strings, one per component.
- `blueprint_job_image` — default verifier container image (`dtzar/helm-kubectl:3.19`).
- `k8s_min_version`, `min_ready_nodes` — stack verifier thresholds.
- `chart_version` — `jfrog/jfrog-platform` Helm chart version, injected at packaging time by the Makefile from the resolved chart version. Hidden because the bundle ships pinned to a specific chart; the customer upgrades by uploading a new bundle, not by editing the input.

The two child blueprints (`jfrog_input_validator/inputs/inputs_hidden.yaml` and `jfrog_platform_component/inputs/inputs_hidden.yaml`) also carry `chart_version` as a hidden input so the chart version flows through to the validator and the Helm release without exposing it on any per-component form.

## Sizing Templates

| Template | Replicas | Artifactory CPU / Memory | PostgreSQL Memory | Recommended For |
|---|---|---|---|---|
| `xsmall` | 1 | 1 CPU / 4 Gi | 8 Gi | Dev/test, minimum viable |
| `small` | 1 | 1 CPU / 5 Gi | 16 Gi | Small teams (~50 users) |
| `medium` | 2 | 1 CPU / 5 Gi each | 32 Gi | Medium teams, HA (~500 users) |
| `large` | 3 | 2 CPU / 12 Gi each | 64 Gi | Large organizations (~2000 users) |
| `xlarge` | 4 | 2 CPU / 16 Gi each | 128 Gi | Very large organizations (~5000 users) |
| `2xlarge` | 6 | 4 CPU / 24 Gi each | 256 Gi | Enterprise-scale (5000+ users) |

> Medium and above require Enterprise licenses (one per replica).

## Examples

The `examples/` directory contains sample input configurations (not packaged in the bundle):

| Example | Description |
|---|---|
| [external-postgres-licensed.yaml](examples/external-postgres-licensed.yaml) | **Default mode.** External PostgreSQL with `database_credentials` basic_auth secret + license. |
| [ha-production.yaml](examples/ha-production.yaml) | Full HA production: external DB (default), HA license, Ingress, PVC storage. |
| [bundled-postgres-trial.yaml](examples/bundled-postgres-trial.yaml) | Trial / dev: explicit `postgresql_enabled: "true"`, LoadBalancer. |
| [bundled-postgres-licensed.yaml](examples/bundled-postgres-licensed.yaml) | Bundled PostgreSQL (opt-in) with license from DAP secret. |
| [ingress-mode.yaml](examples/ingress-mode.yaml) | Kubernetes Ingress mode with the optional ingress-nginx component. |
| [air-gapped.yaml](examples/air-gapped.yaml) | Air-gapped: internal mirrors for Helm charts and container registry. |

## Repository Structure

```
├── .github/workflows/
│   ├── dell-release.yaml              # Builds bundle & publishes GitHub release
│   └── dell-validate-blueprints.yaml  # PR validation
├── blueprints/
│   ├── jfrog_platform_top_level/      # Top-level orchestrator
│   │   ├── blueprint.yaml
│   │   ├── CHANGELOG.yaml
│   │   ├── top_level/
│   │   │   ├── inputs.yaml
│   │   │   ├── inputs_hidden.yaml
│   │   │   └── outputs.yaml
│   │   └── applications/
│   │       ├── 00_input_validator.yaml
│   │       ├── 01_stack_verifier.yaml
│   │       ├── 02_ingress_nginx.yaml
│   │       └── 03_jfrog_platform.yaml
│   ├── jfrog_input_validator/         # Central-agent Python validator
│   │   ├── blueprint.yaml
│   │   ├── CHANGELOG.yaml
│   │   ├── inputs/{inputs.yaml,inputs_hidden.yaml}
│   │   └── application/
│   │       ├── definitions.yaml
│   │       └── scripts/validate_inputs.py
│   ├── jfrog_stack_verifier/          # K8s Job-based cluster verifier
│   │   ├── blueprint.yaml
│   │   ├── CHANGELOG.yaml
│   │   ├── inputs/{inputs.yaml,inputs_hidden.yaml}
│   │   └── application/
│   │       ├── definitions.yaml
│   │       └── scripts/{parse_k8s_secret.py,prepare_registry_data.py}
│   ├── ingress_nginx_component/        # Optional ingress-nginx Helm release
│   │   ├── blueprint.yaml
│   │   ├── CHANGELOG.yaml
│   │   ├── inputs/{inputs.yaml,inputs_hidden.yaml}
│   │   └── application/ingress_nginx.yaml
│   └── jfrog_platform_component/       # JFrog Platform Helm release
│       ├── blueprint.yaml
│       ├── CHANGELOG.yaml
│       ├── inputs/{inputs.yaml,inputs_hidden.yaml}
│       └── application/
│           ├── 00_fetch_labels.yaml      # SaaS DAPO infrastructure linkage
│           ├── 01_namespace_and_secrets.yaml
│           └── 02_jfrog_platform.yaml    # Helm release with rollback:false
├── Makefile                            # Per-component zips + manifest + bundle
├── scripts/
│   ├── release.sh                      # Interactive release helper
│   ├── sync_sizing_templates.sh
│   ├── sync_networking_modes.sh
│   ├── merge_nginx_config.py
│   ├── generate_manifest.py            # SHA256 + Dell manifest emitter
│   ├── validate_blueprints.sh          # Multi-blueprint validator
│   └── get_latest_jfrog_platform_version.sh
├── examples/                           # Sample input configs (not in bundle)
└── README.md
```

## Bundle Output

`make all VERSION=1.0.0` produces:

```
target/
├── blueprints/
│   ├── jfrog_platform_top_level.zip
│   ├── jfrog_input_validator.zip
│   ├── jfrog_stack_verifier.zip
│   ├── ingress_nginx_component.zip
│   └── jfrog_platform_component.zip
├── plugins/                # empty (no custom plugins)
├── manifest.yaml           # Catalog index (id/revision/archive/checksum)
└── jfrog-platform.zip       # Bundle delivered to Dell
```

The bundle zip itself contains `blueprints/`, `plugins/`, and `manifest.yaml` — exactly the layout described in the Dell *Blueprint Structure Guide*.

### Versioning

- **Bundle version** (CLI / GitHub release): 3-part SemVer (`1.0.0`).
- **Manifest revision** (per-blueprint, per Dell guide): 4-part `MAJOR.MINOR.PATCH.BUILD` (`1.0.0.0`). The Makefile auto-derives the 4-part revision from the SemVer bundle version.
- **CHANGELOG.yaml** entries: 3-part SemVer.
- **Blueprint IDs** match the directory name (snake_case) and the `id:` in `manifest.yaml`.

## Prerequisites

- **Dell Application Platform (DAP)** with the Helm plugin (`>=1.4.0.0, <2.0.0.0`) and Kubernetes plugin (`>=3.3.0.0, <4.0.0.0`).
- A Kubernetes cluster reachable from DAP, with credentials stored as a DAP secret of type `k8s`. **For SaaS DAPO** the secret must include `configuration.proxy_settings.{disable, auto_resolve}`.
- A DAP infrastructure deployment whose ID is supplied as `target_deployment_id` so the JFrog Platform deployment can copy the `target_id` label.
- **External PostgreSQL credentials** (default mode, `postgresql_enabled="false"`): a DAP `basic_auth` secret (`username` / `password`) for the Artifactory PostgreSQL user (`database_credentials`), plus a DAP `general` secret for the admin password (`database_admin_password`). Bundled mode (`postgresql_enabled="true"`) skips both — use it only for trial / dev / single-replica deployments.
- For licensed deployments: a DAP general secret containing the raw Artifactory license text. **Required** when `sizing_template` is `medium`, `large`, `xlarge`, or `2xlarge` (Enterprise license, one per replica) — the input validator fails fast when `create_license_secret=0` or `license_secret_ref` is unset for those tiers.
- For master/join key override (optional, any sizing tier): two DAP general secrets containing the raw key material. The master key must be exactly **64 hex chars** (`openssl rand -hex 32`); the join key must be exactly **32 hex chars** (`openssl rand -hex 16`). The validator enforces both format and length.

## Validation

PR validation runs via `Validate Dell Blueprints / validate`. Run locally:

```bash
./scripts/validate_blueprints.sh
```

The validator now understands all four blueprint kinds (top-level orchestrator, helm component, kubernetes utility, central-agent utility) and applies the helm-chain check only to helm-typed blueprints.

## Building the Bundle

```bash
make all VERSION=1.0.0                       # Builds full bundle
make all VERSION=1.0.0 CHART_VERSION=11.5.2  # Pin chart version
make sync                                    # Sync sizing + nginx config only
make validate                                # Run blueprint validation
make clean                                   # Remove target/ and build/
```

The Makefile orchestrates: sync sizing/nginx -> stage each component -> patch `chart_version` defaults in each component's `inputs_hidden.yaml` -> zip per-component -> SHA256 + emit `manifest.yaml` -> bundle. The final bundle is always `target/jfrog-platform.zip` (no version suffix); the SemVer lives on the GitHub release page and in `manifest.yaml`.

## Releasing

```bash
NEW_VERSION=1.0.0 ./scripts/release.sh -y
```

The release helper creates `jfrog-dell-blueprints/v1.0.0` branch + tag and pushes the tag, which triggers the `Release JFrog Dell Blueprint` workflow that builds and publishes the bundle as a GitHub release asset.

## Dell Review Items Addressed in v1.0.0 (INST-22974)

All 10 items from the Dell blueprint review (`jfrog_blueprint_review.pdf`) are addressed; numbering matches the review document.

| # | Review Item | Resolution |
|---|---|---|
| 1 | Missing input validation node | `jfrog_input_validator` component runs Python pre-create validation (formats + DAP secret existence/structure) on the central deployment agent. |
| 2 | Missing stack verification component | `jfrog_stack_verifier` component runs a Kubernetes Job that checks K8s version, ready nodes, storage class, ingress class, and external DB reachability. |
| 3 | No service composition (top-level blueprint) | `jfrog_platform_top_level` orchestrates four `dell.nodes.ServiceComponent`s with explicit `depends_on` ordering. |
| 4 | Integer inputs use `valid_values` instead of `in_range` (Dell IN-007) | All 13 integer toggle inputs converted to `in_range: [0, 1]` (or `[1, 10]` for `min_ready_nodes`). The validator now warns on regressions. |
| 5 | Namespace input missing `allow_update: false` | Set on `namespace` at both top-level and component blueprints. |
| 6 | `release_name` / `chart_version` / `ingress_nginx_version` missing explicit `allow_update` | `release_name=false`; `chart_version` / `ingress_nginx_version` = `true`. |
| 7 | Missing `rollback: false` in Helm releases | Added to both `jfrog_platform_release` and `ingress_nginx_release`. |
| 8 | K8s credentials missing `proxy_settings` documentation | `k8s_credentials` description documents the required `configuration.proxy_settings.{disable, auto_resolve}` block, and `validate_inputs.py` surfaces a warning when it is missing. |
| 9 | Helm repo always created (air-gapped failure) | Resolved by extracting ingress-nginx into its own component; the entire component (Binary + Repo + Release) scales to 0 instances when `install_ingress_controller=0`. |
| 10 | Misnamed `inputs_hidden.yaml` | Cleaned up to only contain truly internal inputs: `blueprint_ids`, `*_revision_id`, `blueprint_job_image`, `k8s_min_version`, `min_ready_nodes`, `chart_version` (build-time injected). |

### Additional improvements delivered alongside the review items

- **SaaS DAPO label linkage** — `target_deployment_id` input + `fetch_labels` node copies the `target_id` label onto the deployment.
- **`database_credentials` (`basic_auth`)** — single DAP secret with `username` / `password` keys replaces the v1 `database_user` / `database_password` pair. **BREAKING.**
- **Air-gapped support** — `jfrog_helm_repo_url`, `ingress_nginx_repo_url`, and `container_registry_name` are user-overridable so internal mirrors can replace external URLs.
- **Manifest-indexed bundle** — `scripts/generate_manifest.py` emits a `manifest.yaml` with SHA256 per component and a 4-part revision auto-derived from the bundle SemVer.
- **Optional master/join key DAP-secret injection** — `create_master_key_secret` + `master_key_secret_ref` and `create_join_key_secret` + `join_key_secret_ref` let users replace the chart's hardcoded insecure default master/join keys with values held in DAP general secrets. The validator enforces format (64 hex chars / 32 hex chars) when the corresponding toggle is `1`; the toggles are independent of `sizing_template`.
- **`chart_version` is hidden** — the `jfrog/jfrog-platform` chart version lives in `inputs_hidden.yaml` across the orchestrator and both helm child blueprints; the Makefile patches the default from `0.0.0` to the resolved chart version at packaging time so the bundle ships pinned and the customer never edits it.
- **Version-less bundle filename** — `make all` produces `target/jfrog-platform.zip` (no version suffix); the GitHub release page carries the SemVer version, and per-component revisions are tracked inside `manifest.yaml`.
- **External PostgreSQL is the default mode** — `postgresql_enabled` defaults to `"false"`. The form opens with the external-DB fields visible (`database_credentials`, `database_admin_password`, `database_host`, `database_port`, `database_ssl_mode`, `create_external_db_secret`); the input validator's Phase 2 secret-store checks for `database_admin_password` and `database_credentials` are active by default. Customers who want the bundled subchart explicitly flip the toggle to `"true"`.

## Contributing

Please read [CONTRIBUTIONS.md](CONTRIBUTIONS.md).

## License

Copyright 2026 JFrog Ltd. Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
