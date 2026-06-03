# Blueprint Examples & Multi-File Patterns

## Complete Basic Blueprint Template

```yaml
tosca_definitions_version: dell_1_1    # Default for DAP 1.1.0.0 (current)

description: >-
  Deploy a vCenter VM and configure it using Ansible

imports:
  - dell/types/types.yaml
  - plugin:vsphere-plugin?version= >=3.1.1.0,<4.0.0.0
  - plugin:ansible-plugin?version= >=4.1.8.0,<5.0.0.0

inputs:
  vcenter_secret:
    type: secret_key
    display_label: vCenter Credentials
    description: Secret containing vCenter credentials.
    hidden: false
    allow_update: false
    constraints:
      - type: vsphere
    display:
      group: infrastructure
      index: 0
  cpus:
    type: integer
    display_label: Number of vCPUs
    description: Number of virtual CPUs for VM.
    default: 1
    hidden: false
    allow_update: true
    constraints:
      - valid_values: [1, 2, 4, 6, 8]
        error_message: "Must be one of: 1, 2, 4, 6, or 8 vCPUs"
    display:
      group: infrastructure
      index: 1
  memory:
    type: integer
    display_label: Memory
    description: Memory (in MB) for VM.
    default: 1024
    hidden: false
    allow_update: true
    constraints:
      - valid_values: [1024, 2048, 4096, 8192]
        error_message: "Must be one of: 1024, 2048, 4096, or 8192 MB"
    display:
      group: infrastructure
      index: 2
  # BS-008: Consider airgapped vs internet-connected deployment models.
  # Include this input when the blueprint fetches artifacts from URLs,
  # connects to external APIs, or installs packages from public repos.
  environment_type:
    type: string
    display_label: Environment Type
    description: >
      Deployment model — "airgapped" for isolated environments
      with no internet access, "internet_connected" for environments
      that can reach public repositories and APIs.
    default: internet_connected
    hidden: false
    allow_update: false
    constraints:
      - valid_values: [airgapped, internet_connected]
        error_message: Must be "airgapped" or "internet_connected".
    display:
      group: infrastructure
      index: 3

input_groups:
  infrastructure:
    display_label: Infrastructure
    collapsible: true
    index: 0
    inputs:
      - vcenter_secret
      - cpus
      - memory
      - environment_type

dsl_definitions:
  connection_config: &connection_config
    username: administrator@vsphere.local
    password: { get_secret: { get_input: vcenter_secret } }
    host: vcenter.example.com
    port: 443
    datacenter_name: "Corporate Data Center"
    resource_pool_name: "Resources"
    auto_placement: true
    allow_insecure: true

  ansible_sources: &ansible_sources
    servers:
      hosts:
        server1:
          ansible_host: { get_attribute: [ vm, ip ] }
          ansible_user: admin
          ansible_ssh_pass: { get_secret: { get_input: vcenter_secret } }
          ansible_sudo_pass: { get_secret: { get_input: vcenter_secret } }
          ansible_host_key_checking: false

node_templates:
  vm:
    type: dell.vsphere.nodes.Server
    properties:
      connection_config: *connection_config
      agent_config:
        install_method: none
      server:
        template: production-server-template
        cpus: { get_input: cpus }
        memory: { get_input: memory }
      networking:
        connect_networks:
          - name: "VM Network"
            switch_distributed: true
            external: true
            management: true
    interfaces:
      dell.interfaces.lifecycle:
        poststart:
          implementation: ansible.plugins_ansible.tasks.run
          inputs:
            playbook_path: playbooks/patch_server.yaml
            sources: *ansible_sources

  app:
    type: dell.nodes.Root
    interfaces:
      dell.interfaces.lifecycle:
        start:
          implementation: ansible.plugins_ansible.tasks.run
          inputs:
            site_yaml_path: playbooks/install_nginx.yaml
            sources: *ansible_sources
    relationships:
      - target: vm
        type: dell.relationships.contained_in

capabilities:
  vm_ip:
    description: "IP address for VM"
    value: { get_attribute: [ vm, ip ] }
  web_endpoint:
    description: "Web URL"
    value:
      concat:
        - "http://"
        - { get_attribute: [ vm, ip ] }

labels:
  csys-obj-type:
    values:
      - service

blueprint_labels:
  csys-obj-type:
    values:
      - blueprint
```

The following `CHANGELOG.yaml` must be created alongside `blueprint.yaml` (BS-009):

```yaml
# CHANGELOG.yaml (must be created alongside blueprint.yaml — BS-009)
1.0.0:
  - ticket: INITIAL
    developer: AI Blueprint Assist
    description: Initial blueprint generation
```

> **When to include `environment_type` (BS-008)**: any blueprint that fetches artifacts from external URLs (Git repos, Ansible Galaxy, container registries, REST APIs). **When to omit**: blueprints that only interact with infrastructure APIs provided via secrets (e.g. vCenter, PowerStore) — those endpoints are always reachable regardless of deployment model.

---

## Multi-File Blueprint Structure

Real-world blueprints should be split across multiple YAML files for maintainability. The main `blueprint.yaml` acts as the entry point and imports the other files using relative paths **in the `imports:` section**.

### Basic Split Pattern

For simple blueprints, separate concerns into peer files:

```
my-blueprint/
├── blueprint.yaml          # Entry point — imports, dsl_definitions, node_templates (or just imports)
├── CHANGELOG.yaml          # Version history (BS-009)
├── inputs.yaml             # Defines inputs: and input_groups: for this blueprint
├── capabilities.yaml       # Capabilities and outputs
└── README.md
```

**blueprint.yaml** (entry point):
```yaml
tosca_definitions_version: dell_1_1

imports:
  - dell/types/types.yaml
  - plugin:helm-plugin?version= >=1.4.0.0,<2.0.0.0
  - inputs.yaml             # imports the inputs definitions — this is NOT a parameters file
  - capabilities.yaml

input_groups:                # input_groups MUST be in the top-level YAML (BS-004)
  deployment_config:
    display_label: Deployment Configuration
    collapsible: true
    index: 0
    inputs:
      - replica_count
      - service_type

dsl_definitions:
  # Shared anchors here

node_templates:
  # Resource definitions here
```

**inputs.yaml** — defines `inputs:` only (NOT `input_groups` — that must be in the top-level YAML per BS-004):
```yaml
inputs:
  replica_count:
    type: integer
    display_label: Replica Count
    description: Number of replicas to deploy.
    default: 3
    hidden: false
    allow_update: true
    constraints:
      - in_range: [1, 10]
        error_message: "Must be between 1 and 10."
    display:
      group: deployment_config
      index: 0
  service_type:
    type: string
    display_label: Service Type
    description: Kubernetes service type.
    default: LoadBalancer
    hidden: false
    allow_update: true
    constraints:
      - valid_values: [ClusterIP, NodePort, LoadBalancer]
        error_message: "Must be one of: ClusterIP, NodePort, or LoadBalancer"
    display:
      group: deployment_config
      index: 1
```

> **`inputs.yaml` is a definitions file, NOT a parameters file.**
> - It contains `inputs:` — the schema and metadata for blueprint inputs
> - `input_groups:` must be in the top-level `blueprint.yaml` (BS-004), not in sub-files
> - It is imported by `blueprint.yaml` in the `imports:` section (not passed at deploy time)
> - It does NOT contain parameter values, runtime values, or deployment-specific settings
> - It does NOT contain `node_templates:`, `capabilities:`, `tosca_definitions_version:`, or any other top-level TOSCA keys
> - When the orchestrator deploys the blueprint, it merges all imported YAML files into a single blueprint

**capabilities.yaml**:
```yaml
capabilities:
  endpoint:
    description: Service endpoint
    value: { get_attribute: [helm_release, url] }
```

### Layered Pattern (Complex Blueprints)

For blueprints with multiple infrastructure and application layers, use subdirectories:

```
my-blueprint/
├── blueprint.yaml              # Entry point — only imports and dsl_definitions
├── CHANGELOG.yaml              # Version history (BS-009)
├── inputs.yaml                 # All inputs across all layers
├── capabilities.yaml           # All exposed capabilities/outputs
├── infrastructure/
│   ├── network.yaml            # Network node templates (VPC, subnet, security groups)
│   ├── storage.yaml            # Storage node templates (volumes, object storage)
│   └── compute.yaml            # VM / compute node templates
├── application/
│   ├── helm.yaml               # Helm releases
│   ├── kubernetes.yaml         # Raw K8s resources (secrets, configmaps)
│   └── monitoring.yaml         # Monitoring stack (Grafana, Prometheus)
└── scripts/
    └── configure.sh            # Scripts referenced by operations
```

**blueprint.yaml** (entry point — thin orchestrator):
```yaml
tosca_definitions_version: dell_1_1

imports:
  - dell/types/types.yaml
  - plugin:vsphere-plugin?version= >=3.1.1.0,<4.0.0.0
  - plugin:helm-plugin?version= >=1.4.0.0,<2.0.0.0
  - plugin:kubernetes-plugin?version= >=3.4.0.0,<4.0.0.0
  - inputs.yaml
  - capabilities.yaml
  - infrastructure/network.yaml
  - infrastructure/storage.yaml
  - infrastructure/compute.yaml
  - application/helm.yaml
  - application/kubernetes.yaml

input_groups:                    # input_groups in the top-level YAML only (BS-004)
  infrastructure:
    display_label: Infrastructure
    collapsible: true
    index: 0
    inputs:
      - vsphere_secret
      - cpus
      - memory

dsl_definitions:
  connection_config: &connection_config
    username: { get_secret: { get_input: vsphere_secret } }
    password: { get_secret: { get_input: vsphere_secret } }
    host: { get_secret: { get_input: vsphere_secret } }
    port: 443
    allow_insecure: true
```

**infrastructure/network.yaml**:
```yaml
node_templates:
  network:
    type: dell.vsphere.nodes.Network
    properties:
      connection_config: *connection_config
      network:
        name: app-network
        switch_distributed: true
        vlan_id: 100
```

**infrastructure/compute.yaml**:
```yaml
node_templates:
  vm:
    type: dell.vsphere.nodes.Server
    properties:
      connection_config: *connection_config
      server:
        template: ubuntu-22.04
        cpus: { get_input: cpus }
        memory: { get_input: memory }
      networking:
        connect_networks:
          - name: app-network
            switch_distributed: true
    relationships:
      - target: network
        type: dell.relationships.connected_to
```

**application/helm.yaml**:
```yaml
node_templates:
  helm_release:
    type: dell.nodes.helm.Release
    properties:
      # ... look up exact properties with: bpa knowledge plugins get helm dell.nodes.helm.Release
    relationships:
      - target: vm
        type: dell.relationships.contained_in
```

### Tightly-Coupled Operations (BS-006 Exception)

When all operations nodes (policy assignment, CMDB registration, post-deploy config) depend directly on a single infrastructure node (one VM), splitting into `infrastructure/` and `operations/` subdirectories adds directory overhead with no portability benefit — the operations cannot be reused without the specific VM they act on.

In this case, co-locating all nodes in a single `node_templates` section (or a single definitions file) is acceptable. The basic split (`inputs.yaml`, `capabilities.yaml`) still applies — only the subdirectory split is waived.

The blueprint MUST include a YAML comment at the top of `node_templates` explaining why the split was not applied:

```yaml
# BS-006: Infrastructure and operations nodes are co-located because all
# operations (PowerProtect, ServiceNow, Ansible) depend directly on the
# VM node. Splitting into subdirectories would not improve portability.
node_templates:
  vm:
    type: dell.nodes.vsphere.Server
    # ...
  powerprotect_policy:
    type: dell.nodes.rest.Requests
    # ...
    relationships:
      - type: dell.relationships.depends_on
        target: vm
  servicenow_register:
    type: dell.nodes.rest.Requests
    # ...
    relationships:
      - type: dell.relationships.depends_on
        target: vm
```

### Import Rules for Multi-File Blueprints

1. **Relative paths**: All local imports are relative to the importing file's location
2. **One entry point**: Only `blueprint.yaml` imports plugins and `dell/types/types.yaml`. Sub-files just define their node_templates, inputs, etc.
3. **YAML anchors are file-scoped**: DSL definitions (`&anchor`) are only available within the file they are defined in. Each file that needs anchors must define its own `dsl_definitions` block. To share values across files, use inputs or namespaced imports — not YAML aliases.
4. **No circular imports**: File A cannot import File B if File B imports File A
5. **Namespace collisions**: Node template IDs must be unique across ALL files. If `infrastructure/network.yaml` defines `network` and `application/kubernetes.yaml` also defines `network`, the blueprint will fail
6. **Namespaced imports**: Use `- prefix--file.yaml` to namespace all definitions from that file. References become `prefix--node_name`. Use this when composing blueprints from independent modules that might have colliding names

### When to Split

| Scenario | Pattern |
|---|---|
| Simple single-plugin blueprint (< 50 lines) | Single `blueprint.yaml` is fine |
| Single plugin, multiple inputs/capabilities | Basic split: `inputs.yaml` + `capabilities.yaml` |
| Multiple plugins or infrastructure + app layers | Layered pattern with subdirectories |
| Reusable modules shared across blueprints | Namespaced imports (`prefix--module.yaml`) |
| All operations depend on a single infra node | Basic split (inputs/capabilities); flat node\_templates with BS-006 justification comment |

### Decision Guide for Cascade

When the user asks you to create a blueprint:

1. **Single file** — ONLY when: one plugin, one or two node templates, fewer than 5 inputs
2. **Basic split** — Two or more plugins OR more than 5 inputs: `blueprint.yaml`, `inputs.yaml`, `capabilities.yaml`
3. **Layered split** — Different infrastructure and application concerns (e.g. network + compute + app configuration): use subdirectories
4. **Always** keep `scripts/` and `playbooks/` in separate directories

Default to splitting when there are more than one layer, e.g. compute, network, application. When in doubt, split. A multi-file blueprint is never wrong; a monolithic one often is.

---

## Update Workflow Lifecycle (ND-009)

Production blueprints should implement update-related lifecycle operations so that `deployment update` can apply changes without a full reinstall. The recommended sub-operations and their execution order:

1. `check_drift` — Compare live state to desired state. Set `drifted: true` on the instance if they differ.
2. `update` — Apply the change (e.g. resize a VM, update a Helm value).
3. `postupdate` — Run any post-change validation or notification.

Optional additional operations: `preupdate`, `update_config`, `update_apply`, `update_postapply`, `preheal`, `heal`, `postheal`.

Example — a VM node with update support:

```yaml
node_templates:
  vm:
    type: dell.nodes.vsphere.Server
    properties:
      # ...
    interfaces:
      dell.interfaces.lifecycle:
        create:
          # ... (install workflow)
        delete:
          # ... (uninstall workflow)

        # ND-009: Update workflow operations
        check_drift:
          implementation: scripts/check_drift.py
          inputs:
            expected_cpus: { get_input: vm_cpus }
            expected_memory: { get_input: vm_memory_mb }
        update:
          implementation: scripts/update_vm.py
          inputs:
            cpus: { get_input: vm_cpus }
            memory: { get_input: vm_memory_mb }
        postupdate:
          implementation: scripts/verify_vm.py
```

**`scripts/check_drift.py`** should:
- Query the current VM state (e.g. via vSphere API)
- Compare against expected values from inputs
- Set `ctx.instance.runtime_properties['drifted'] = True` if they differ
- Be **read-only** — `check_drift` is invoked during `preview` mode, so it must not mutate state

**`scripts/update_vm.py`** should:
- Apply the new configuration (resize CPU/memory)
- Be idempotent (ND-004) — a retry should not fail if the change was already applied

This is optional (ND-009) but recommended for any blueprint that will be updated in place rather than torn down and redeployed.

See also: `dap-deployment-update` skill for the API/CLI side of deployment updates.

---

## DSL Definitions for Inline Values (DS-002)

YAML anchors can extract any repeated complex value — not just top-level property blocks. Extract when a value has 2+ intrinsic functions and appears more than once.

Common candidates:
- Authorization headers with `concat` + `get_secret`
- Complex `concat` expressions for URLs or paths
- Repeated `get_secret` chains with the same secret structure

Example — extracting auth headers:

```yaml
dsl_definitions:

  connection_config: &connection_config
    # ... (existing pattern)

  # DS-002: Extract repeated auth header into an anchor.
  powerprotect_auth: &powerprotect_auth
    concat:
      - "Basic "
      - { get_secret: [{ get_input: powerprotect_secret_name }, auth_token] }

  servicenow_auth: &servicenow_auth
    concat:
      - "Basic "
      - { get_secret: [{ get_input: servicenow_secret_name }, auth_token] }

node_templates:
  api_call:
    type: dell.nodes.rest.Requests
    # ...
    interfaces:
      dell.interfaces.lifecycle:
        start:
          implementation: rest.plugins_rest.tasks.execute
          inputs:
            template_file: templates/create-resource.yaml
            params:
              headers:
                Content-Type: application/json
                Authorization: *powerprotect_auth     # ← alias, not repeated concat
        delete:
          implementation: rest.plugins_rest.tasks.execute
          inputs:
            template_file: templates/delete-resource.yaml
            params:
              headers:
                Content-Type: application/json
                Authorization: *powerprotect_auth     # ← same anchor reused
```
