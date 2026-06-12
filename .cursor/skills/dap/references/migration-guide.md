---
name: dsl-migration-guide
description: Instructions for migrating blueprints from one DSL version to another (e.g., nativeedge_1_0 → dell_1_1). Use ONLY when the user explicitly asks to migrate, convert, or change DSL version.
version: "1.0"
alwaysApply: false
---

# DSL Migration Guide

## Purpose

This guide applies **ONLY** when the user asks to:
- Migrate a blueprint from one DSL version to another
- Convert a blueprint from NativeEdge to Dell DSL
- Change the DSL version while keeping the same structure
- Generate a blueprint "based on X DSL"

**Do NOT apply this guide for new blueprint generation.** For new blueprints, use the standard `blueprint-rules.md`.

## Core Principle

**Preserve the original blueprint structure.** Only change what is DSL-incompatible. Do NOT add new constraints, restructure inputs, or apply improvement rules unless the user explicitly requests them.

## Migration Rules

### 1. Update DSL Version

**Required:** Change `tosca_definitions_version` to the target DSL version.

Example:
```yaml
# Before (NativeEdge)
tosca_definitions_version: nativeedge_1_0

# After (Dell)
tosca_definitions_version: dell_1_1
```

### 2. Replace DSL Prefixes

**Required:** Replace all type, interface, relationship, datatype, and policy prefixes.

For NativeEdge → Dell migrations:
- `nativeedge.nodes.*` → `dell.nodes.*`
- `nativeedge.interfaces.*` → `dell.interfaces.*`
- `nativeedge.relationships.*` → `dell.relationships.*`
- `nativeedge.datatypes.*` → `dell.datatypes.*`
- `nativeedge.policies.*` → `dell.policies.*`

Also update implementation module paths on built-in node types (`Component`, `SharedResource`, `Blueprint`, `PasswordSecret`):
- `ne_extensions.nativeedge_types.*` → `dell_extensions.dell_types.*`

And the plugin declaration section:
- `ne_extensions:` → `dell_extensions:`

Example:
```yaml
# Before
node_type: nativeedge.nodes.SoftwareComponent
interfaces:
  nativeedge.interfaces.lifecycle:
    create: scripts/install.sh

# After
node_type: dell.nodes.SoftwareComponent
interfaces:
  dell.interfaces.lifecycle:
    create: scripts/install.sh
```

### 3. Remove NativeEdge-Only Properties

**Required:** Remove properties that are specific to NativeEdge and not supported in Dell DSL.

The following property must be removed from all nodes:
- `nativeedge_tagging` (present on AWS node types)

Example:
```yaml
# Before
node_templates:
  vm:
    type: dell.nodes.aws.ec2.Instances
    properties:
      nativeedge_tagging: true
      resource_config:
        ImageId: ami-12345678

# After
node_templates:
  vm:
    type: dell.nodes.aws.ec2.Instances
    properties:
      resource_config:
        ImageId: ami-12345678
```

**Important:** Remove completely — do not comment out. It will cause linter errors and deployment failures in Dell DSL.
The linter autofix can handle this: `dap-bpa blueprint lint --fix`.

### 4. Update Imports

**Required:** Update plugin imports by dropping the `nativeedge-` prefix. Do NOT add a `dell-` prefix — that name does not exist.

Pattern: `nativeedge-X-plugin` → `X-plugin`

| Before | After |
|---|---|
| `nativeedge-aws-plugin` | `aws-plugin` |
| `nativeedge-azure-plugin` | `azure-plugin` |
| `nativeedge-kubernetes-plugin` | `kubernetes-plugin` |
| `nativeedge-ansible-plugin` | `ansible-plugin` |
| `nativeedge-docker-plugin` | `docker-plugin` |
| `nativeedge-terraform-plugin` | `terraform-plugin` |
| `nativeedge-utilities-plugin` | `utilities-plugin` |
| `nativeedge-vsphere-plugin` | `vsphere-plugin` |

**Note:** The Edge Plugin and Storage Plugin did not follow this convention — look up their actual names rather than deriving them by pattern.

Also update the types import:
- `nativeedge/types/types.yaml` → `dell/types/types.yaml`

Example:
```yaml
# Before
imports:
  - nativeedge/types/types.yaml
  - plugin:nativeedge-aws-plugin?version=>=3.0.0.0,<4.0.0.0

# After
imports:
  - dell/types/types.yaml
  - plugin:aws-plugin?version=>=4.0.0.0,<5.0.0.0
```

### 5. Preserve Input Structure

**Do NOT add constraints to inputs** that had none in the original blueprint, unless the user explicitly asks for input improvements.

**Do NOT restructure inputs** or add new properties (`allow_update`, `hidden`, etc.) unless the user asks for it.

Example of what NOT to do:
```yaml
# Original (no constraints)
inputs:
  region:
    type: string
    description: AWS region

# WRONG - added constraints without being asked
inputs:
  region:
    type: string
    description: AWS region
    constraints:
      - valid_values: [us-east-1, us-west-2, eu-west-1]
        error_message: "Must be a valid AWS region"

# CORRECT - preserve original structure
inputs:
  region:
    type: string
    description: AWS region
```

**Exception:** If the user explicitly asks to "improve inputs", "add validation", or "follow best practices", then you MAY apply input improvement rules (IN-007, etc.).

### 6. Preserve File Structure

**Do NOT split single-file blueprints** into multi-file structures during migration, unless the user asks for it.

**Do NOT consolidate multi-file blueprints** into single files during migration.

**Preserve the original directory structure** and file organization.

### 7. Do Not Apply Blueprint Rules

**Do NOT apply the following rules during migration** unless the user explicitly requests improvements:
- IN-007 (mandatory constraints)
- BS-010 (multi-file split requirements)
- IN-009 (input grouping requirements)
- Any "Optional" or "best practice" rules

**Only apply rules that are necessary for DSL compatibility:**
- TD-001 (correct DSL version)
- TD-002 (correct branding prefixes)
- IM-003 (plugin version format)

## Migration Workflow

1. **Read the original blueprint** — understand its current structure
2. **Update DSL version** — change `tosca_definitions_version`
3. **Replace all DSL prefixes** — types, interfaces, relationships, datatypes, policies
4. **Remove NE-only properties** — delete `nativeedge_tagging` from all nodes
5. **Update imports** — `nativeedge-X-plugin` → `X-plugin`, `nativeedge/types/types.yaml` → `dell/types/types.yaml`
6. **Preserve everything else** — inputs, outputs, node structure, file organization
7. **Do NOT add constraints** or apply improvement rules unless asked

## Post-Migration

After migration, inform the user:
1. The migration is complete
2. The blueprint is ready to use in the target DSL
3. They can optionally run `dap-bpa blueprint lint --fix` to auto-correct any remaining issues
4. They can ask for improvements separately if desired (e.g., "now improve the inputs")

## Example Migration Request

User: "I have AWS_EC2_NE.zip built on nativeedge_1_0 dsl, generate a new bp based dell_1.1 dsl with the same structure, rename it AWS_EC2_DAP.zip"

Expected actions:
1. Extract and read AWS_EC2_NE.zip
2. Change `tosca_definitions_version: nativeedge_1_0` → `dell_1_1`
3. Replace all `nativeedge.*` prefixes with `dell.*`
4. Remove any `nativeedge_tagging` properties
5. Update imports: `nativeedge-aws-plugin` → `aws-plugin`, `nativeedge/types/types.yaml` → `dell/types/types.yaml`
6. Preserve all inputs exactly as they were (no new constraints)
7. Preserve all file structure exactly as it was
8. Create AWS_EC2_DAP.zip with the migrated blueprint

**Do NOT:**
- Add constraints to inputs that had none
- Split single-file blueprints into multiple files
- Add `allow_update`, `hidden`, or other properties to inputs
- Restructure or reorganize the blueprint
- Apply any improvement rules

## When This Guide Does Not Apply

This guide does NOT apply when:
- The user asks to generate a new blueprint (use `blueprint-rules.md`)
- The user asks to improve or refactor an existing blueprint (use `blueprint-rules.md`)
- The user asks to add features or functionality (use `blueprint-rules.md`)
- The request does not mention DSL version, migration, or conversion

This guide ONLY applies to DSL version migration requests where structure preservation is the goal.
