---
name: dap-service-composition
description: Use when composing services — ServiceComponent sub-deployments, SharedResource, chaining blueprints, get_environment_capability. Triggers — service component, sub-deployment, dell.nodes.ServiceComponent, or requests to chain deployments.
---

# Service Composition — NativeEdge Blueprints

## Runtime Mode

You are running in agent mode.
Do not execute shell commands.
Use the bound tools that wrap `@blueprint-assist/core/skill-functions`.

Full function reference: `../dap/references/functions-reference.md`.

Service composition lets you build complex applications from smaller, independently deployed pieces. Instead of putting everything in one blueprint, you define a **main deployment** that spins up **sub-deployments** — each responsible for one layer (e.g. a VM, a database, a network). The main deployment ties them all together.

> **Related skill**: For the full blueprint authoring reference — node types, intrinsic functions, relationships, multi-file structure — invoke the **`dap`** skill (Blueprint Assist). Use this skill (`service-composition`) when the question is specifically about connecting deployments together.

---

## CRITICAL RULES

**NEVER write a service component node template from memory.** The `resource_config` shape and available properties must be verified with the `bpa` CLI before you write any YAML.

**Before writing any service composition blueprint:**
1. Call `findBlueprintExamples({ query: 'service component' })` to find a working example
2. Call `getBlueprintExample('<id>', { includeFiles: true })` to get the actual YAML
3. Call `getNodeTypeReference('', 'dell.nodes.ServiceComponent')` to get the exact property schema
4. Write the blueprint based ONLY on what the tools returned
5. Call `lintBlueprint('<path>', { verify: true })` to validate

---

## Core Concepts

| Term | Meaning |
|---|---|
| **Service component** | A node template of type `dell.nodes.ServiceComponent`. It represents one deployable piece of a larger service. |
| **Sub-deployment** | The deployment created when a service component node is installed. It is owned by the parent deployment. |
| **Main deployment** | The top-level deployment that contains all the service component nodes. |
| **Component blueprint** | The blueprint used by a service component — can be a catalog blueprint or a blueprint archive in a repo. |
| **SharedResource** | A node of type `dell.nodes.SharedResource` that connects to an **existing** deployment by ID rather than creating a new one. |

**Rule of thumb**: use service composition when two layers have independent lifecycles, or when you want to reuse a blueprint (e.g. a standard VM blueprint) across many applications without duplicating it.

---

## Architecture

```
Main Deployment
+-- service component: vm_layer   <- sub-deployment A (Virtual Machine blueprint)
+-- service component: db_layer   <- sub-deployment B (Database blueprint)
+-- app_node                      <- regular node, depends_on: vm_layer, db_layer
```

> **CHANGELOG.yaml (BS-009):** The parent blueprint AND each `components/<name>/` directory must contain their own `CHANGELOG.yaml`.

> **CHANGELOG.yaml requirement (BS-009):** The parent blueprint AND each sub-blueprint (component) directory must contain their own `CHANGELOG.yaml`. When generating a service composition blueprint, create a `CHANGELOG.yaml` at the top level and one inside each `components/<name>/` directory.

---

## `dell.nodes.ServiceComponent` — the Service Component Node Type

This is the node type you use in your blueprint to create a sub-deployment. It has a single key property: `resource_config`.

**Always look up the exact schema before writing:**
```ts
getNodeTypeReference('', 'dell.nodes.ServiceComponent')
```

### Canonical `resource_config` Structure

```yaml
vm_layer:
  type: dell.nodes.ServiceComponent
  properties:
    resource_config:
      blueprint:
        external_resource: true           # true = catalog/already-uploaded blueprint
        id: Virtual_Machine_for_vSphere   # Blueprint ID in the catalog
        revision_id: "2.1.0.1"           # ALWAYS include the revision
      deployment:
        display_name:                     # Human-readable name for the sub-deployment
          concat:
            - { get_sys: [deployment, name] }
            - "-vm"
        auto_inc_suffix: true             # Append -1, -2 ... to avoid name collisions
        inputs:
          hostname:  { get_input: vm_hostname }
          vcpu:      { get_input: vm_vcpus }
          memory:    { get_input: vm_memory }
```

**Key sub-properties:**

| Sub-property | Required | Description |
|---|---|---|
| `blueprint.external_resource` | Yes | `true` = catalog blueprint; `false` = archive upload |
| `blueprint.id` | Yes | Blueprint ID (literal or `{ get_input: ... }`) |
| `blueprint.revision_id` | Yes | Semver string. **Always include this.** |
| `blueprint.blueprint_archive` | Conditional | URL/path to zip (only when `external_resource: false`) |
| `deployment.display_name` | Recommended | Use `get_sys: [deployment, name]` so the name is unique |
| `deployment.auto_inc_suffix` | Recommended | Always pair with `display_name` |
| `deployment.inputs` | Conditional | Required if the component blueprint has inputs without defaults |

---

## Three Ways to Source a Component Blueprint

**1. Catalog blueprint** (most common in production):
```yaml
blueprint:
  external_resource: true
  id: Virtual_Machine_for_vSphere
  revision_id: "2.1.0.1"
```

**2. Blueprint archive** from a repository:
```yaml
blueprint:
  external_resource: false
  id: my-db-blueprint
  blueprint_archive: https://repo.example.com/blueprints/db-blueprint.zip
  main_file_name: blueprint.yaml   # omit if only one YAML at root
```

**3. Parameterised selection** (blueprint ID from input):
```yaml
blueprint:
  external_resource: true
  id: { get_input: compute_blueprint }
  revision_id: { get_input: compute_revision }
```

---

## `deployment.inputs` Patterns

### Flat pass-through

Map each component input to a top-level input: `hostname: { get_input: vm_hostname }`

### get_environment_capability

Bridge environment-level capabilities into sub-deployments: `vsphere_secret_name: { get_environment_capability: vcenter_credentials }`

### Sibling capabilities

Read output from another service component: `join_command: { get_attribute: [init_control_plane, capabilities, kubernetes_join_command] }`

> For detailed YAML examples and the dynamic precreate script pattern, run `findBlueprintExamples({ query: 'service-composition' })`.

---

## Capability Patterns

| Function | When to use |
|---|---|
| `get_attribute: [node, capabilities, key]` | Reading a capability from a **sibling** service component node in the same blueprint |
| `get_environment_capability: key` | Reading a capability from the **NED environment** (ECE layer, vSphere environment) |
| `get_capability: [deployment_id, key]` | Reading a capability from a **deployment by ID** — used with `SharedResource` |
| `get_secret: { get_attribute: [...] }` | When the capability value **is a secret key**, not the secret value itself |

> **Common mistake**: using `get_attribute` on a service component node without the `capabilities` middle segment. The correct 3-part path is `[node_id, capabilities, cap_name]`.

> For detailed defining/consuming capability examples, run `findBlueprintExamples({ query: 'service-composition' })`.

---

## `SharedResource` — Connecting to an Existing Deployment

Use `dell.nodes.SharedResource` to *consume* an existing deployment (e.g. a K8S cluster deployed separately) rather than create a new one:

```yaml
k3s_cluster:
  type: dell.nodes.SharedResource
  properties:
    resource_config:
      deployment:
        id: { get_input: k3s_deployment_id }   # No blueprint section — reference by ID
```

Read its capabilities with `get_capability`:

```yaml
kubeconfig_file_content:
  get_secret:
    get_capability:
      - { get_input: k3s_deployment_id }
      - kubeconfig_secret_name
```

---

## Workflow for Building a Service Composition Blueprint

1. `findBlueprintExamples({ query: 'service component vm application' })` — find a matching example
2. `getBlueprintExample('<id>', { includeFiles: true })` — get the actual YAML
3. For each component blueprint: verify it exists (`listDeployments(credentials)`), get its revision, know its required inputs and exported capabilities
4. `getNodeTypeReference('', 'dell.nodes.ServiceComponent')` — get the exact property schema
5. Write the blueprint based ONLY on what steps 1-4 returned
6. `lintBlueprint('blueprint.yaml', { verify: true })` — validate
7. `validateBlueprint('blueprint.yaml')` — validate node templates (if plugin source available)

---

## Retrieval

**Understand composition patterns** (multi-file, scaling):
```ts
findBlueprintExamples({ query: 'service-composition' })
```

**Search for specific topics**:
```ts
findBlueprintExamples({ query: 'service component' })
findBlueprintExamples({ query: 'SharedResource' })
```

**Find a working blueprint example**:
```ts
findBlueprintExamples({ query: 'service composition' })
```

Full function reference: `../dap/references/functions-reference.md`.

---

## Optional Components (Conditional Node Instantiation)

Some deployments include service component nodes that should only be provisioned when a user requests them (e.g., an optional monitoring stack, a GPU node, extra storage). The `control_installation` + `jmespath` pattern provides conditional instantiation without requiring separate blueprints.

### Pattern: `control_installation` with a Boolean Input

For `dell.nodes.ServiceComponent` nodes, use `control_installation` inside `resource_config`:

```yaml
inputs:
  install_monitoring:
    type: boolean
    display_label: Enable Monitoring
    description: When true, the monitoring stack will be deployed.
    default: false
    hidden: false
    allow_update: false
    constraints:
      - valid_values: [true, false]
        error_message: Must be true or false.

node_templates:
  monitoring_stack:
    type: dell.nodes.ServiceComponent
    properties:
      resource_config:
        blueprint:
          external_resource: true
          id: Monitoring_Stack
          revision_id: "1.0.0"
        deployment:
          display_name:
            concat:
              - { get_sys: [deployment, name] }
              - "-monitoring"
          auto_inc_suffix: true
          inputs: {}
        control_installation:
          install:
            jmespath:
              - 'length([?install_monitoring == `true`]) || `0`'
              - [{"install_monitoring": { get_input: install_monitoring }}]
          uninstall:
            jmespath:
              - 'length([?install_monitoring == `true`]) || `0`'
              - [{"install_monitoring": { get_input: install_monitoring }}]
```

**Key rules:**
- Both `install` and `uninstall` must use the same `jmespath` expression to keep them in sync.
- The expression **must return an integer** (`0` or `1`), not a boolean.
- `0` = the sub-deployment is NOT created during install. `1` = it IS created.
- `allow_update: false` on the controlling boolean — changing it after deployment requires a deployment update workflow.

### Pattern: `scalable.default_instances` (Non-ServiceComponent Nodes)

For regular nodes (not `ServiceComponent`), use the `scalable` capability instead:

```yaml
node_templates:
  optional_node:
    type: dell.nodes.Root
    capabilities:
      scalable:
        properties:
          default_instances:
            jmespath:
              - 'length([?enable_feature == `true`]) || `0`'
              - [{"enable_feature": { get_input: enable_feature }}]
```

- `default_instances: 0` — Node defined but install workflow skips it (zero instances created)
- `default_instances: 1` — Node instantiated normally

### Dependent Inputs with `only_with`

Use `only_with` on inputs that only make sense when the optional feature is enabled:

```yaml
inputs:
  monitoring_retention_days:
    type: integer
    display_label: Retention Days
    description: Only relevant when monitoring is enabled.
    default: 30
    only_with: install_monitoring
```

`only_with` hides the input in the DAP orchestrator UI when the referenced boolean is false.

**Map form (match a specific value):** `only_with` also accepts a map so you can gate on a specific value, not just a boolean `true`:

```yaml
inputs:
  ingress_host:
    type: string
    display_label: Ingress Host
    required: true        # mandatory ONLY while the gate is satisfied
    only_with:
      ingress_enabled: "true"
```

**Conditionally-required pattern:** combine `required: true` with `only_with` so a field is shown *and* mandatory only when its feature/toggle is on (and is skipped entirely otherwise). This surfaces the requirement in the form up front instead of failing later at validation time.
