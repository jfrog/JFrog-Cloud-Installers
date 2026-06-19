# JFrog Dell Blueprints

Dell-certified TOSCA (`dell_1_1`) blueprints that deploy JFrog Platform onto Kubernetes via the Dell Application Platform (DAP). The bundle follows the Dell multi-component structure: a top-level orchestrator delegates to three component blueprints (input validator, stack verifier, and the JFrog Platform Helm release) that ship as a single `manifest.yaml`-indexed bundle. An ingress controller is a cluster prerequisite and is not installed by this bundle. Initial release is **v1.0.0**.

## Bundle Architecture

```
JFrog Platform Top-Level (orchestrator)
        │
        ├── Input Validator        (central agent — Python, no K8s)
        ├── Stack Verifier          (K8s Job — kubectl-based checks)
        └── JFrog Platform Component (labels + namespace/secrets + Helm release + ingress TLS + LB endpoint discovery)
```

Execution order enforced via `dell.relationships.depends_on`: input validation → stack verification → JFrog Platform install. An ingress controller must already exist in the cluster (prerequisite) when using Ingress mode.

## Available Blueprints

| Blueprint ID | Type | Purpose |
|---|---|---|
| `jfrog_platform_top_level` | environment | Top-level orchestrator that wires the three components together. This is the deployment entrypoint shown to end-users. |
| `jfrog_input_validator` | utility | Validates user inputs (formats + DAP secret existence/structure) on the central deployment agent. |
| `jfrog_stack_verifier` | utility | Runs a Kubernetes Job to validate cluster prerequisites (Kubernetes version, node readiness, storage class, ingress class, external DB connectivity). |
| `jfrog_platform_component` | environment (helm) | Fetches infrastructure labels (SaaS DAPO `target_id`), creates namespace + DAP-derived K8s secrets, installs the JFrog Platform Helm chart with `rollback: false`, wires optional Ingress TLS, and discovers the bundled-NGINX LoadBalancer endpoint. |

## Top-Level Inputs (User-Facing)

The top-level orchestrator gathers all user-visible inputs in one UI and forwards subsets to each component. Highlights:

| Group | Input | Purpose |
|---|---|---|
| Credentials | `k8s_credentials` | DAP `k8s` secret with cluster access details. Required keys: `host`, `port`, `verify_ssl`, `ssl_ca_cert`; for `verify_ssl='TLS'` also `cert_file`/`key_file`, for `verify_ssl='Token'` also `token`. |
| Credentials | `target_deployment_id` | DAP infrastructure deployment ID (`type: deployment_id`). Required so SaaS DAPO can copy the `target_id` label onto the deployment. |
| Database | `postgresql_enabled` | `"false"` by default - the bundle assumes external PostgreSQL out of the box. Set to `"true"` only for trial / dev / single-replica deployments. |
| Database | `database_credentials` | A single DAP Basic Authentication secret (`type: secret_key`, `constraints: - type: basic_auth_credentials`) holding the `username`/`password` for the Artifactory PostgreSQL user. **Required when `postgresql_enabled="false"`** (i.e., the default). |
| Database | `database_admin_password` | DAP `general` secret holding the Postgres admin password. **Required when `postgresql_enabled="false"`**. |
| Persistence | `persistence` | Storage mode: `storage-class` (PVC via a Kubernetes StorageClass) or `storage-type` (file-system / NFS). |
| Networking | `nginx_enabled` / `ingress_enabled` | External access mode — the chart's bundled NGINX (LoadBalancer) vs a Kubernetes Ingress resource. Both are `"true"`/`"false"` strings. Ingress mode binds to an existing IngressClass; the ingress controller is a cluster prerequisite. |
| Networking | `ingress_class_name` / `ingress_host` | The IngressClass to bind to and the DNS hostname for the Ingress. Shown and **required** only in Kubernetes Ingress mode (`nginx_enabled="false"`, `ingress_enabled="true"`); the validator also rejects the placeholder default `artifactory.example.com`. |
| Networking | `ingress_tls_enabled` / `ingress_tls_secret_ref` | Serve the Kubernetes Ingress over HTTPS. `ingress_tls_secret_ref` is a required DAP `general` secret holding `tls.crt`/`tls.key`; the blueprint creates the `<release_name>-tls` Kubernetes TLS secret from it. When disabled, Artifactory is served over HTTP. |
| Networking | `ingress_annotations` | An optional `dict` of annotations applied to `artifactory.ingress.annotations`, rendered to a Helm values file so values keep their exact YAML form (numbers, strings, multi-line blocks). Defaults to `{}` (no annotations). `nginx.org/redirect-to-https` is blueprint-managed from `ingress_tls_enabled` (set `"false"` when TLS is off, omitted when on) and ignored if set here. |

The full set of user-visible inputs lives in [blueprints/jfrog_platform_top_level/top_level/inputs.yaml](blueprints/jfrog_platform_top_level/top_level/inputs.yaml).

### Hidden Inputs

`top_level/inputs_hidden.yaml` contains values that are not user-visible:

- `blueprint_ids` — mapping of logical names to catalog blueprint IDs.
- `*_revision_id` — 4-part `MAJOR.MINOR.PATCH.BUILD` revision strings, one per component.
- `blueprint_job_image` — default verifier container image, pinned by digest (`dtzar/helm-kubectl@sha256:d02d8d02...`, the multi-arch manifest-list digest of the `3.19` tag).
- `k8s_min_version`, `min_ready_nodes` — stack verifier thresholds.
- `k8s_deployment_constraints` — label-constraint map used by the `target_deployment_id` `deployment_id` input.
- `container_registry_credentials_secret`, `create_pull_secret` — optional private-registry pull credentials (DAP `general` secret + toggle) for the verifier image.
- `jfrog_helm_repo_url`, `container_registry_name` — external Helm/registry URLs. Hidden, but overridable (e.g. for air-gapped mirrors) by editing `inputs_hidden.yaml` before building the bundle.
- `chart_version` — `jfrog/jfrog-platform` Helm chart version, injected at packaging time by the Makefile from the resolved chart version. Hidden because the bundle ships pinned to a specific chart; the customer upgrades by uploading a new bundle, not by editing the input.

The child blueprints `jfrog_input_validator/inputs/inputs_hidden.yaml` and `jfrog_platform_component/inputs/inputs_hidden.yaml` also carry `chart_version` as a hidden input so the chart version flows through to the validator and the Helm release without exposing it on any per-component form.

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
| [external-postgres-licensed.yaml](examples/external-postgres-licensed.yaml) | **Default mode.** External PostgreSQL with a single `database_credentials` basic_auth secret + license. |
| [ha-production.yaml](examples/ha-production.yaml) | Full HA production: external DB, HA license, injected master/join keys, Ingress over HTTPS, PVC storage. |
| [bundled-postgres-trial.yaml](examples/bundled-postgres-trial.yaml) | Trial / dev: `postgresql_enabled: "true"`, LoadBalancer, no license. |
| [bundled-postgres-licensed.yaml](examples/bundled-postgres-licensed.yaml) | Bundled PostgreSQL (opt-in) with a license from a DAP secret. |
| [ingress-mode.yaml](examples/ingress-mode.yaml) | Kubernetes Ingress mode binding to a pre-installed ingress controller. |
| [ingress-tls.yaml](examples/ingress-tls.yaml) | Kubernetes Ingress terminating HTTPS via a DAP TLS secret (`ingress_tls_enabled` + `ingress_tls_secret_ref`). |
| [ingress-custom-annotations.yaml](examples/ingress-custom-annotations.yaml) | Kubernetes Ingress overriding `ingress_annotations` with a custom annotation map. |
| [nfs-storage.yaml](examples/nfs-storage.yaml) | NFS-backed persistence (`persistence: storage-type`, `persistence_type: nfs`). |

## Repository Structure

```
# (repo root) .github/workflows/dell-release.yaml          # Builds bundle & publishes GitHub release
# (repo root) .github/workflows/dell-validate-blueprints.yaml  # PR validation
JFrog-Dell-Blueprints/
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
│   │       └── scripts/{parse_k8s_secret.py,prepare_registry_data.py,
│   │                    prepare_job_spec.py,fetch_labels.py,fetch_labels_stop.py}
│   └── jfrog_platform_component/       # JFrog Platform Helm release
│       ├── blueprint.yaml
│       ├── CHANGELOG.yaml
│       ├── inputs/{inputs.yaml,inputs_hidden.yaml}
│       ├── sizing/platform-*.yaml        # Generated from the Helm chart (git-ignored)
│       └── application/
│           ├── definitions.yaml          # fetch_labels, namespace, DAP secrets,
│           │                             # ingress TLS, Helm release (rollback:false),
│           │                             # LoadBalancer endpoint discovery
│           └── scripts/{parse_k8s_secret.py,fetch_labels.py,fetch_labels_stop.py,
│                        compute_ingress_tls.py,compute_key_secret_names.py,
│                        render_ingress_values.py,resolve_lb_endpoint.py}
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

- **Dell Application Platform (DAP)** with the Helm plugin (`>=1.4.3.0, <2.0.0.0`) and Kubernetes plugin (`>=3.4.1.0, <4.0.0.0`).
- A Kubernetes cluster reachable from DAP, with credentials stored as a DAP secret of type `k8s` containing the keys `host`, `port`, `verify_ssl`, `ssl_ca_cert` (plus `cert_file`/`key_file` for TLS auth, or `token` for Token auth).
- A DAP infrastructure deployment whose ID is supplied as `target_deployment_id` (`type: deployment_id`) so the JFrog Platform deployment can copy the `target_id` label.
- **External PostgreSQL credentials** (default mode, `postgresql_enabled="false"`): a single DAP Basic Authentication secret for the Artifactory PostgreSQL user (`database_credentials`, holding `username`/`password`), plus a DAP `general` secret for the admin password (`database_admin_password`). Bundled mode (`postgresql_enabled="true"`) skips both — use it only for trial / dev / single-replica deployments.
- For licensed deployments: a DAP general secret containing the raw Artifactory license text. **Required** when `sizing_template` is `medium`, `large`, `xlarge`, or `2xlarge` (Enterprise license, one per replica) — the input validator fails fast when `apply_license_secret="false"` or `license_secret_ref` is unset for those tiers.
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
| 3 | No service composition (top-level blueprint) | `jfrog_platform_top_level` orchestrates three `dell.nodes.ServiceComponent`s with explicit `depends_on` ordering. |
| 4 | Integer inputs use `valid_values` instead of `in_range` (Dell IN-007) | User-facing toggles are exposed as `valid_values: ["true", "false"]` strings (the validator derives the 0/1 integers internally via `_toggle_int`); `min_ready_nodes` uses `in_range: [1, 10]`. |
| 5 | Namespace input missing `allow_update: false` | Set on `namespace` at both top-level and component blueprints. |
| 6 | `release_name` / `chart_version` missing explicit `allow_update` | `release_name=false`; `chart_version=true`. |
| 7 | Missing `rollback: false` in Helm releases | Added to `jfrog_platform_release`. |
| 8 | K8s credentials documentation | `k8s_credentials` description documents the required keys (`host`, `port`, `verify_ssl`, `ssl_ca_cert`, plus `cert_file`/`key_file` for TLS or `token` for Token auth); `validate_inputs.py` validates the k8s secret structure per `verify_ssl` type. Proxy defaults are applied in `parse_k8s_secret.py`. |
| 9 | Helm repo always created (air-gapped failure) | The JFrog Platform Helm repo URL (`jfrog_helm_repo_url`) is a hidden input that can be repointed at an internal mirror for air-gapped deployments. The ingress controller is a cluster prerequisite (not installed by this bundle), so it adds no Helm-repo dependency. |
| 10 | Misnamed `inputs_hidden.yaml` | Cleaned up so it holds only non-user-facing inputs (e.g. `blueprint_ids`, `*_revision_id`, `blueprint_job_image`, `k8s_min_version`, `min_ready_nodes`, `chart_version`, plus the hidden air-gap/registry URLs and pull-secret settings). |

### Additional improvements delivered alongside the review items

- **SaaS DAPO label linkage** — `target_deployment_id` input (`type: deployment_id`) + `fetch_labels` node copies the `target_id` label onto the deployment.
- **External database credentials** — `database_credentials` is a single DAP Basic Authentication secret (`type: secret_key`, `constraints: - type: basic_auth_credentials`) holding `username`/`password`, required when `postgresql_enabled="false"`. The validator checks both keys are present and non-empty.
- **Air-gapped support** — `jfrog_helm_repo_url` and `container_registry_name` are hidden inputs that can be repointed at internal mirrors (edit `inputs_hidden.yaml` before building the bundle).
- **Manifest-indexed bundle** — `scripts/generate_manifest.py` emits a `manifest.yaml` with SHA256 per component and a 4-part revision auto-derived from the bundle SemVer.
- **Optional master/join key DAP-secret injection** — `apply_master_key_secret` + `master_key_secret_ref` and `apply_join_key_secret` + `join_key_secret_ref` let users replace the chart's hardcoded insecure default master/join keys with values held in DAP general secrets. The validator enforces format (64 hex chars / 32 hex chars) when the corresponding toggle is `1`; the toggles are independent of `sizing_template`.
- **`chart_version` is hidden** — the `jfrog/jfrog-platform` chart version lives in `inputs_hidden.yaml` across the orchestrator, the input validator, and the JFrog Platform component; the Makefile patches the default from `0.0.0` to the resolved chart version at packaging time so the bundle ships pinned and the customer never edits it.
- **Version-less bundle filename** — `make all` produces `target/jfrog-platform.zip` (no version suffix); the GitHub release page carries the SemVer version, and per-component revisions are tracked inside `manifest.yaml`.
- **Ingress TLS** — `ingress_tls_enabled` + `ingress_tls_secret_ref` (a required DAP `general` secret holding `tls.crt`/`tls.key`) drive the Artifactory Ingress over HTTPS. A `compute_ingress_tls` node resolves `tls_secret_name_effective` (the Kubernetes TLS secret name) and `url_scheme`. The `tls:` Helm values block (`secretName` + `hosts`) is written by `render_ingress_values.py` **only when TLS is enabled** — it is fully absent when disabled, so no stray `tls:` block appears on the Ingress object. The `ingress_tls_secret_ref` input is conditionally required (`only_with: ingress_enabled: "true", ingress_tls_enabled: "true"`).
- **Ingress annotations** — `ingress_annotations` (a `dict` input, default `{}`) is shown in the UI only when Ingress mode is active (`only_with: ingress_enabled: "true"`). It is rendered to a Helm values file by `render_ingress_values.py` and merged via a `--values` flag scoped to install/upgrade (not uninstall). This keeps values in their exact YAML form (numbers, booleans, multi-line blocks) which `helm --set` cannot represent. `nginx.org/redirect-to-https` is blueprint-managed from `ingress_tls_enabled` (`"false"` when TLS is off so plain HTTP works, omitted when on). No default annotations are applied — the deployer supplies annotations for their specific controller.
- **Supported ingress controllers** — only the **NGINX Ingress Controller** (from NGINX Inc. / F5 — the controller that fronts the NGINX web server as a reverse proxy, identified by `nginx.org/*` annotations and the `nginx.org/ingress-controller` IngressClass) is certified for this blueprint. The blueprint manages `nginx.org/*` annotations (such as `nginx.org/redirect-to-https`) that this controller consumes. The community `ingress-nginx` controller (`nginx.ingress.kubernetes.io/*` annotations) and other controllers (HAProxy, Traefik, Istio, etc.) are not certified; they may still be used at the deployer's own discretion via `ingress_class_name` and controller-specific `ingress_annotations`, but the `nginx.org/*` annotations the blueprint sets are ignored by them.
- **Service endpoint discovery** — in bundled-NGINX (LoadBalancer) mode, a `check_nginx_service_endpoint` node reads the `<release_name>-artifactory-nginx` Service; an always-on `resolve_lb_endpoint` node turns its external IP into the `platform_url_loadbalancer` capability (a clean string, or empty in Ingress mode rather than an unresolved `get_attribute` expression). Discovery is gated to NGINX mode via `scalable.default_instances`.
- **Mode-exclusive access URLs** — the two access-URL capabilities are mutually exclusive so the UI only ever shows the URL for the active mode. DAP capabilities always render, so the inactive mode resolves to an empty string instead of a misleading URL: `compute_ingress_tls` emits `platform_url_ingress` (`http(s)://<host>`) only when `ingress_enabled` is true (empty string otherwise), and `resolve_lb_endpoint` emits `platform_url_loadbalancer` (`http://<lb-ip>`) only when a LoadBalancer IP exists. In Ingress mode `platform_url_loadbalancer` is empty; in bundled-NGINX mode `platform_url_ingress` is empty.
- **"Apply ... Secret" toggles with conditionally-required refs** — the per-secret toggles are labelled `Apply <X> Secret` (Bundled Database, External Database, License, Master Key, Join Key) because the DAP secrets they reference are created by the user ahead of time; the toggle controls whether the blueprint materializes a Kubernetes Secret from them. When `Apply License/Master Key/Join Key Secret` is `"true"`, the matching secret ref (`license_secret_ref` / `master_key_secret_ref` / `join_key_secret_ref`) is shown and **required** via an `only_with` gate, so the form demands it up front instead of failing only at validation time.
- **Kebab-case persistence values** — the `persistence` input accepts `storage-class` / `storage-type`; the input-validator script and all `only_with` gates use the same kebab-case values across the orchestrator and components.
- **External PostgreSQL is the default mode** — `postgresql_enabled` defaults to `"false"`. The form opens with the external-DB fields visible (`database_credentials`, `database_admin_password`, `database_host`, `database_port`, `database_ssl_mode`, `apply_external_db_secret`); the input validator's Phase 2 secret-store checks for `database_admin_password` and `database_credentials` (username/password keys) are active by default. Customers who want the bundled subchart explicitly flip the toggle to `"true"`.

## Security Considerations

- **Bundled PostgreSQL is trial/dev only — never for production.** When `postgresql_enabled="true"`, the chart's bundled PostgreSQL subchart is deployed with **well-known default credentials** (`postgres` / `artifactory` / `artifactory`), written by the `database_credentials_bundled` node in [definitions.yaml](blueprints/jfrog_platform_component/application/definitions.yaml). These defaults are visible in the blueprint source and the resulting Kubernetes Secret, so bundled mode is intended strictly for trial / dev / single-replica use. **For any production deployment set `postgresql_enabled="false"` and supply credentials via DAP secrets** (`database_credentials` + `database_admin_password`). External PostgreSQL is the default mode for this reason.
- **Kubernetes Secrets encryption at rest.** The blueprint writes credentials, license, master/join keys, and TLS material to Kubernetes Secrets (base64, not encrypted by the blueprint). Enable **etcd encryption at rest** on the target cluster so these Secrets are protected in the datastore — this is a cluster-operator responsibility.
- **Pod security context.** Pod-level security controls (`runAsNonRoot`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem`, etc.) are owned by the upstream `jfrog/jfrog-platform` Helm chart. Align them with your cluster's Pod Security Standards via chart values rather than overriding them in the blueprint.
- **Supply chain.** The stack-verifier image (`blueprint_job_image`) is pinned by digest for tamper-proof, reproducible pulls — the default is the multi-arch manifest-list (index) digest of `dtzar/helm-kubectl:3.19`, so each node still resolves the correct architecture (amd64/arm64/etc.). The input also accepts `image/path:tag@sha256:<digest>` and plain `image/path:tag` forms, and the image can be hosted in an internal registry via the air-gapped settings. To update the pin, resolve the new manifest-list digest with `crane digest dtzar/helm-kubectl:<tag>` (or `docker buildx imagetools inspect`). Helm charts are pulled over HTTPS without signature verification; mirror them to an internal repository for provenance control in regulated environments.
- **Production TLS.** For production, enable Ingress TLS (`ingress_tls_enabled="true"` with `ingress_tls_secret_ref`) and use a strict database SSL mode (`database_ssl_mode="verify-full"`). These are left configurable rather than enforced so they do not break valid non-production topologies.

## Contributing

Please read [CONTRIBUTIONS.md](CONTRIBUTIONS.md).

## License

Copyright 2026 JFrog Ltd. Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
