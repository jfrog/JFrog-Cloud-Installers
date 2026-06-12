---
name: blueprint-rules
description: Blueprint authoring compliance rules — apply whenever writing, reviewing, or linting DAP blueprint YAML.
version: "1.4"
alwaysApply: false
---

# Blueprint Best Practice Rules

## How to Use This Document

- Each rule has a unique **Ref** (e.g. `BS-001`), a **Status**, a **Level**, and a **Rule** description.
- **Mandatory** rules must be followed. A blueprint violating a mandatory rule is non-compliant.
- **Optional** rules are recommended best practice. They may be skipped with justification.
- **Status** controls enforcement: only apply rules where Status = `Enabled`. Ignore `Disabled` rules.
- Rules can be overridden by an optional `blueprint_rules_override.md` file — rules in that file take priority.
- All type references, plugin names, and interface names use `dell.*` branding (not `nativeedge.*`).

---

## TOSCA & Definitions

| Ref | Status | Rule | Level | Details |
|-----|--------|------|-------|---------|
| TD-001 | Enabled | All blueprints must use `tosca_definitions_version: dell_1_1`. | Mandatory | Do not use `dell_1_0` or any other version. |
| TD-002 | Enabled | All type references, plugin names, and interface names must use `dell.*` branding. | Mandatory | Replace any `nativeedge.*` references with `dell.*` equivalents. E.g. `dell.nodes.SoftwareComponent`, `dell.interfaces.lifecycle`, `dell.relationships.depends_on`. |

---

## Blueprint Structure

| Ref | Status | Rule | Level | Details |
|-----|--------|------|-------|---------|
| BS-001 | Enabled | All blueprint files must be placed in one directory and its subdirectories. | Mandatory | |
| BS-002 | Enabled | The blueprint zip file must contain one top-level folder with all relevant files and subfolders. | Mandatory | |
| BS-003 | Enabled | There must be one main blueprint YAML file for each top-level blueprint. | Mandatory | |
| BS-004 | Enabled | The main blueprint YAML must contain: `tosca_definitions_version`, `description`, `imports`, `input_groups`, `labels`, `blueprint_labels`. | Mandatory | All six sections are required. `input_groups` must only appear in the top-level YAML — do not place `input_groups` in sub-blueprint or input files. |
| BS-005 | Enabled | When a blueprint has multiple components, each component must be placed in its own subdirectory. | Mandatory | |
| BS-006 | Enabled | Infrastructure and application parts must be split into separate subdirectories. | Mandatory | Application logic should be infrastructure-independent for portability. |
| BS-007 | Enabled | All internal blueprint artifacts (scripts, Ansible playbooks, Terraform files, templates) must be placed in appropriately named subdirectories. | Mandatory | E.g. `scripts/`, `ansible/`, `terraform/`, `templates/`. |
| BS-008 | Enabled | Blueprints should consider all deployment models where possible: SaaS (internet-connected), on-prem, and airgapped. | Optional | "Airgapped" and "on-prem" are equivalent. Use an `environment_type` input with values `airgapped` / `internet_connected` to distinguish. |
| BS-009 | Enabled | Every blueprint must include a `CHANGELOG.yaml` file. | Mandatory | Must be present at initial generation and updated when the blueprint changes. Format: `<version>:` → list of `{ticket, developer, description}`. |
| BS-010 | Enabled | Blueprints must be split into multiple YAML files when they have 2+ plugins OR 5+ inputs. | Mandatory | **Single file** is only acceptable when: one plugin, ≤2 node templates, and <5 inputs. Otherwise use at minimum a **basic split**: `blueprint.yaml` (entry point — imports, `input_groups`, `dsl_definitions`, `node_templates`), `inputs.yaml` (`inputs:` only), `capabilities.yaml` (`capabilities:` only). For blueprints with separate infrastructure and application concerns, use a **layered split** with subdirectories. `input_groups` must remain in the top-level `blueprint.yaml` (BS-004). When in doubt, split — a multi-file blueprint is never wrong; a monolithic one often is. |

---

## Imports

| Ref | Status | Rule | Level | Details |
|-----|--------|------|-------|---------|
| IM-001 | Enabled | The main blueprint YAML must import `dell/types/types.yaml`. | Mandatory | |
| IM-002 | Enabled | All required plugins must be imported in the main blueprint YAML so they are stored in one place. | Mandatory | |
| IM-003 | Enabled | Plugin imports must use version-range pinning with a minimum (`>=`) and a maximum (`<`) version. | Mandatory | Format: `plugin:<name>?version= >=X.Y.Z.W,<NEXT_MAJOR.0.0.0`. Example: `plugin:ansible-plugin?version= >=4.1.8.0,<5.0.0.0`. Use the latest published version as the minimum. See the Plugin Version Reference appendix. |
| IM-004 | Enabled | All relevant sub-blueprints must be imported from their subdirectories. | Mandatory | |

---

## Nodes

| Ref | Status | Rule | Level | Details |
|-----|--------|------|-------|---------|
| ND-001 | Enabled | Non-starting nodes must be connected to other nodes via relationships. A node without relationships runs in parallel to all others — this is usually a missed relationship. | Mandatory | |
| ND-002 | Enabled | Mandatory node lifecycle operations must be implemented for at least the `install` and `uninstall` workflows. | Mandatory | Nodes may inherit lifecycle ops from their type, or define/overwrite their own. |
| ND-003 | Enabled | The `uninstall` lifecycle must revert all relevant actions (e.g. script reverting install changes, VM removal). | Mandatory | Common persistent changes that must be reverted on uninstall: mount points (umount), fstab entries (remove line), systemd services (disable + remove unit), crontab entries, firewall rules (ufw/iptables), user accounts, configuration file modifications, package installations. Trace every persistent side effect of the corresponding create operation and ensure each one is reversed. |
| ND-004 | Enabled | Lifecycle operations must be idempotent: retrying must not cause a state change. Use runtime properties or query external systems to track state. | Mandatory | |
| ND-005 | Enabled | Bash, Python, or other executable code must not be placed inline in blueprint YAML. Use separate script files in a subdirectory (e.g. `scripts/`). | Mandatory | This applies to all blueprints, including simple ones. Scripts executed by the Fabric plugin must be POSIX `sh` compatible — the plugin ignores the shebang and executes via `sh`. |
| ND-006 | Enabled | Major reusable components must be defined in a separate blueprint and referenced as a `dell.nodes.ServiceComponent` node in the top-level blueprint. | Mandatory | |
| ND-007 | Enabled | ServiceComponent nodes must use `revision_id` (not `version`) in `resource_config.blueprint` for blueprint versioning. | Mandatory | `revision_id` is free text, supports exact match only — it cannot compare higher/lower versions. Example: `revision_id: 2.1.3.0`. |
| ND-008 | Enabled | The recommended order of node definitions in the YAML file should follow the expected order of execution based on relationships. | Optional |
| ND-009 | Enabled | Nodes should implement lifecycle operations for the `update` workflow. | Optional (Conditionally Mandatory) | For full update support, the following sub-operations are recommended: `check_drift`, `preupdate`, `update`, `postupdate`, `update_config`, `update_apply`, `update_postapply`, `preheal`, `heal`, `postheal`. **Conditionally Mandatory**: when the user requests update / Day-2 / drift support, `check_drift`, `update`, and `postupdate` become **Mandatory** and must appear together. Declaring `update` without `check_drift` is non-compliant in that context — `check_drift` must be present so the deployment-update workflow can detect live-state drift via `ctx.returns(...)` instead of falling back to synthetic drift flagging. | |

---

## Inputs

| Ref | Status | Rule | Level | Details |
|-----|--------|------|-------|---------|
| IN-001 | Enabled | Every input must have a `type` defined. | Mandatory | |
| IN-002 | Enabled | List-type inputs must specify `item_type` so the UI can render proper modals. | Mandatory | |
| IN-003 | Enabled | Every input must have a human-readable `display_label` with no underscores, using Title Case formatting. | Mandatory | |
| IN-004 | Enabled | Every input must have a descriptive `description` property. | Mandatory | |
| IN-005 | Enabled | Every input must have the `hidden` property explicitly set, even if the value is `false`. | Mandatory | |
| IN-006 | Enabled | Inputs that must not change after deployment must set `allow_update: false`. | Mandatory | |
| IN-007 | Enabled | Input values must be validated using `constraints` wherever applicable. | Mandatory | This includes all types. Boolean inputs should use `valid_values: [true, false]` with an `error_message`. Integer, string, and list inputs should use appropriate range, pattern, or valid_values constraints. |
| IN-008 | Enabled | Every constraint must include a descriptive `error_message`. The `error_message` must be correctly indented under its constraint entry (same level as the constraint key, e.g. `pattern`), not at the list-item level. | Mandatory | Example: `constraints:` → `- pattern: ^...$` (newline) `error_message: "Must be..."`. |
| IN-009 | Enabled | All non-hidden inputs must have `display` → `group` and `display` → `index` to group and order related inputs in the UI. All referenced groups must exist in `input_groups`. | Mandatory | |
| IN-010 | Enabled | Use `only_with` and `exclusive_with` to hide optional or conditional inputs appropriately. | Optional | |
| IN-011 | Enabled | Do not use `deployment` type inputs for deploy target. Use capabilities and `get_environment_capability` instead (unless a cluster is in use). | Mandatory | |

---

## Data Types

| Ref | Status | Rule | Level | Details |
|-----|--------|------|-------|---------|
| DT-001 | Enabled | Data types must be used for custom structures in node properties, input types, and input `item_type`s. | Mandatory | |
| DT-002 | Enabled | Data types should be defined in the same file as their associated inputs or nodes, depending on the use case. | Mandatory | |
| DT-003 | Enabled | All attributes within a data type definition must include `type` and `description`. | Mandatory | Other properties (`display` → `display_name`, `required`) are recommended but not currently enforced as mandatory. |

---

## Secrets

| Ref | Status | Rule | Level | Details |
|-----|--------|------|-------|---------|
| SC-001 | Enabled | Sensitive values must never be passed directly as inputs. Pass the secret name instead and resolve with `{ get_secret: { get_input: input_name } }`. | Mandatory | |
| SC-002 | Enabled | Secret inputs must use `type: secret_key` and include a `constraints: - type: <secret_schema>` entry specifying the relevant secret schema. | Mandatory | Example: `type: secret_key`, `constraints:` → `- type: ssh_private_key`. |

---

## Capabilities

| Ref | Status | Rule | Level | Details |
|-----|--------|------|-------|---------|
| CP-001 | Enabled | All relevant information from a deployment must be output as capabilities for consumption by users or other blueprints. | Mandatory | |
| CP-002 | Enabled | Every defined capability must have a `description`. | Mandatory | |
| CP-003 | Enabled | Use `get_capability` to dynamically evaluate capability values from another deployment. | Mandatory | |
| CP-004 | Enabled | Use `get_environment_capability` to fetch capabilities from a parent deployment (also for `deploy_on` with bulk deployment). | Mandatory | |

---

## DSL Definitions

| Ref | Status | Rule | Level | Details |
|-----|--------|------|-------|---------|
| DS-001 | Enabled | All reusable code blocks must be defined as YAML anchors in the blueprint's `dsl_definitions` section and reused via aliases throughout the blueprint. | Mandatory | |
| DS-002 | Enabled | Complex values (e.g. input values containing many intrinsic functions) should be defined as a `dsl_definition`. | Optional | |

---

## Input Groups

| Ref | Status | Rule | Level | Details |
|-----|--------|------|-------|---------|
| IG-001 | Enabled | Input groups must be defined in the top-level blueprint YAML to list inputs as collapsible collections in the UI. | Mandatory | Each group needs: `display_label`, `collapsible: true`, `index` (controls ordering), and `inputs` (list of input names). |
| IG-002 | Enabled | Every non-hidden input must belong to a group defined in `input_groups`. The group referenced in an input's `display` → `group` must exist. | Mandatory | Undefined group references are invalid. |

---

## Quick Reference — Compliant Input Example

```yaml
inputs:
  hostname:
    type: string
    hidden: false
    allow_update: false
    display_label: Hostname
    description: |
      Hostname of the Virtual Machine.
      Cannot contain characters other than:
      letters (a-z, A-Z), numbers (0-9), or hyphens (-).
    default: my-host
    constraints:
      - pattern: ^(?!-)[a-zA-Z0-9-]{1,63}(?<!-)$
        error_message: |
          Must be letters (a-z, A-Z), numbers (0-9), or hyphens (-).
          No more than 63 characters.
      - max_length: 63
        error_message: Hostname must not exceed 63 characters.
    display:
      group: infra
      index: 1
```

## Quick Reference — Compliant Secret Input Example

```yaml
inputs:
  ssh_private_key_secret_name:
    type: secret_key
    hidden: false
    allow_update: false
    display_label: SSH Private Key Secret Name
    description: |
      Name of the secret storing the SSH private key.
    constraints:
      - type: ssh_private_key
    display:
      group: infra
      index: 10
```

## Quick Reference — Compliant Boolean Input Example

```yaml
inputs:
  switch_distributed:
    type: boolean
    hidden: false
    allow_update: false
    display_label: Distributed Switch
    description: |
      Set to true if the network uses a distributed virtual switch.
    default: false
    constraints:
      - valid_values: [true, false]
        error_message: Must be true or false.
    display:
      group: network
      index: 3
```

## Quick Reference — Compliant Plugin Import Example

```yaml
imports:
  - dell/types/types.yaml
  - plugin:ansible-plugin?version= >=4.1.8.0,<5.0.0.0
  - plugin:fabric-plugin?version= >=2.1.2.0,<3.0.0.0
```

## Quick Reference — Compliant ServiceComponent Example

```yaml
node_templates:
  vm:
    type: dell.nodes.ServiceComponent
    properties:
      resource_config:
        blueprint:
          external_resource: true
          id: Virtual_Machine_for_vSphere
          revision_id: 2.1.0.1
        deployment:
          display_name:
            concat:
              - { get_sys: [deployment, name] }
              - "-vm"
```

## Quick Reference — CHANGELOG.yaml Format

```yaml
# Changelog for <blueprint_name>
1.0.0:
  - ticket: JIRA-001
    developer: J. Smith
    description: Initial blueprint version
```

---

## Appendix: Plugin Version Reference

Minimum versions for use in `plugin:` import lines (IM-003). Upper bound is always `<NEXT_MAJOR.0.0.0`.

| Plugin            | Min Version | Max (exclusive) | Import line example                                    |
| ----------------- | ----------- | --------------- | ------------------------------------------------------ |
| ansible-plugin    | 4.1.8.0     | <5.0.0.0        | `plugin:ansible-plugin?version= >=4.1.8.0,<5.0.0.0`    |
| aws-plugin        | 4.0.1.0     | <5.0.0.0        | `plugin:aws-plugin?version= >=4.0.1.0,<5.0.0.0`        |
| azure-plugin      | 4.0.1.0     | <5.0.0.0        | `plugin:azure-plugin?version= >=4.0.1.0,<5.0.0.0`      |
| docker-plugin     | 3.0.1.0     | <4.0.0.0        | `plugin:docker-plugin?version= >=3.0.1.0,<4.0.0.0`     |
| fabric-plugin     | 3.4.2.0     | <4.0.0.0        | `plugin:fabric-plugin?version= >=3.4.2.0,<4.0.0.0`     |
| helm-plugin       | 1.4.0.0     | <2.0.0.0        | `plugin:helm-plugin?version= >=1.4.0.0,<2.0.0.0`       |
| kubernetes-plugin | 3.4.0.0     | <4.0.0.0        | `plugin:kubernetes-plugin?version= >=3.4.0.0,<4.0.0.0` |
| libvirt-plugin    | 1.0.1.0     | <2.0.0.0        | `plugin:libvirt-plugin?version= >=1.0.1.0,<2.0.0.0`    |
| openstack-plugin  | 4.0.1.0     | <5.0.0.0        | `plugin:openstack-plugin?version= >=4.0.1.0,<5.0.0.0`  |
| redfish-plugin    | 1.0.1.0     | <2.0.0.0        | `plugin:redfish-plugin?version= >=1.0.1.0,<2.0.0.0`    |
| storage-plugin    | 1.0.0.0     | <2.0.0.0        | `plugin:storage-plugin?version= >=1.0.0.0,<2.0.0.0`    |
| terraform-plugin  | 1.2.1.0     | <2.0.0.0        | `plugin:terraform-plugin?version= >=1.2.1.0,<2.0.0.0`  |
| terragrunt-plugin | 1.0.1.0     | <2.0.0.0        | `plugin:terragrunt-plugin?version= >=1.0.1.0,<2.0.0.0` |
| utilities-plugin  | 3.1.4.0     | <4.0.0.0        | `plugin:utilities-plugin?version= >=3.1.4.0,<4.0.0.0`  |
| vcloud-plugin     | 3.0.1.0     | <4.0.0.0        | `plugin:vcloud-plugin?version= >=3.0.1.0,<4.0.0.0`     |
| vsphere-plugin    | 3.1.1.0     | <4.0.0.0        | `plugin:vsphere-plugin?version= >=3.1.1.0,<4.0.0.0`    |
