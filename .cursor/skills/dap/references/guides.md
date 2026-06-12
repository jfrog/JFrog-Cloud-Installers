# DAP/BPA Workflow Guides

## Runtime Mode

You are running in IDE mode with shell access.
Use the `bpa` CLI for BPA operations.
Do not use the function interface unless explicitly instructed by the host.

This skill provides step-by-step tutorials for common DAP Orchestrator and Blueprint Assist workflows.

## Response Guidelines

**IMPORTANT: Always use only ONE guide section at a time. Never return the full document.**

**CRITICAL - CLI Command Accuracy (applies to ALL sections):**

Do not invent, infer, or "complete" BPA CLI commands under any circumstances.
Every suggested command must be copy-paste runnable and verified to work — not just syntactically present in help output.

- ❌ NEVER suggest commands that do not exist in the BPA CLI
- ❌ NEVER assume symmetry (e.g., `create` exists → `delete` exists)
- ❌ NEVER guess flags, arguments, or subcommands based on patterns
- ❌ NEVER complete partial commands with assumed syntax
- ✅ Only suggest commands that are known to be executable — "looks valid" is not enough
- ✅ If a command does not exist, explicitly say so and suggest alternatives (UI, API, or supported workflows)
- ✅ If unsure whether a command exists, ask a clarification question instead of guessing

**Verified command behavior (tested):**
- `dap-bpa knowledge plugins list <plugin>` — requires a plugin argument (there is no command to list all plugins)
- `dap-bpa knowledge plugins get <plugin> <type>` — `<type>` must be the full qualified name (e.g., `dell.nodes.vsphere.Server`, not `Server`)
- `dap-bpa orchestrator secrets create --key <name> --value <val>` — uses `--key` flag, not positional
- `--fields` flag — takes space-separated values (e.g., `--fields id status`), not comma-separated
- The CLI does not support: `secrets update`, `secrets delete`, `blueprints delete`, `deployments delete` — use DAP UI or API
- Provide plugin examples as "common examples (depending on your environment)" — never assume availability
- Suggest discovery: `dap-bpa knowledge docs search <technology>` or `dap-bpa knowledge blueprints find <technology>`

When answering user questions:

**For broad questions** (e.g., "how do I write a blueprint from scratch", "walk me through creating a blueprint"):
- Start with a concise summary of the high-level steps (3-5 bullet points)
- Add a brief sentence explaining what each step accomplishes
- End with: "Want me to walk you through one of these steps in detail?"
- Do NOT include the full step-by-step guide by default
- Do NOT include "Step X" headings in the summary
- Only provide the detailed guide if the user explicitly asks for more detail

**For focused questions** (e.g., "how do I add inputs", "how do I lint my blueprint"):
- Provide a natural, conversational answer
- Do NOT include "Step X" headings
- Use the relevant content from the appropriate section
- Structure it as a direct answer to their specific question
- Reference the Quick Reference table to identify the right section
- Return only the specific part needed, not the entire guide

## Quick Reference

For specific questions, jump directly to these sections:

| Question | Go to Guide |
|----------|-------------|
| "How do I write a blueprint?" | Guide: Write Blueprint |
| "How do I add inputs?" | Write Blueprint → Step 5: Add Inputs |
| "How do I add capabilities/outputs?" | Write Blueprint → Step 6: Add Capabilities |
| "How do I lint my blueprint?" | Write Blueprint → Step 7: Lint |
| "How do I upload my blueprint?" | Write Blueprint → Step 9: Upload |
| "How do I deploy a blueprint?" | Guide: Create Deployment |
| "How do I monitor deployment?" | Create Deployment → Step 4: Monitor Execution |
| "How do I create a secret?" | Guide: Create Secrets |
| "How do I use secrets in blueprints?" | Create Secrets → Step 2: Reference Secrets |
| "What are plugins?" | Guide: Plugins Overview |
| "Which plugin should I use?" | Plugins Overview → Step 2: Choose Plugin |
| "How do I delete resources?" | Guide: Delete Resources |
| "How do I delete a deployment?" | Delete Resources → Step 1: Delete Deployments |
| "What is DAP / BPA / blueprint / plugin / capability?" | `references/faq.md` |

## Cloudify → DAP Terminology

| Cloudify Term | DAP Term |
|---------------|----------|
| Blueprint | Blueprint (same) |
| Deployment | Deployment (same) |
| Secret | Secret (same) |
| Plugin | Plugin (same) |
| Node Type | Node Type (same) |
| Execution | Execution (same) |
| NativeEdge | Dell Automation Platform |

---

# Guide: Write Blueprint

## Overview

A blueprint is a YAML file that defines infrastructure and application resources using TOSCA (Topology and Orchestration Specification for Cloud Applications). This guide walks you through creating a blueprint from scratch.

## Mental Model: What is a Blueprint?

A blueprint defines infrastructure and application resources in a declarative way.

Key concepts:
- **Node templates** — the resources to create (VMs, containers, networks)
- **Plugins** — integrations that know how to provision and manage those resources
- **Inputs** — user-provided parameters at deployment time
- **Interfaces** — lifecycle operations (create, configure, start)
- **Capabilities** — outputs exposed after deployment (IP addresses, connection details)

When you deploy a blueprint, the DAP Orchestrator follows your recipe to create actual resources in your infrastructure.

## Quick Start

The high-level flow for writing a blueprint:

1. **Plan** → Identify what resources you need and which plugins to use
2. **Research** → Find examples and look up node type properties
3. **Write** → Create the YAML file with inputs, nodes, and capabilities
4. **Validate** → Lint and validate to catch errors early
5. **Upload** → Upload to orchestrator and deploy

## Prerequisites

- `dap-bpa` CLI installed and configured (`dap-bpa setup` completed)
- Access to a DAP Orchestrator instance
- Basic understanding of YAML syntax

## Step 1: Identify the Plugin You Need

**Use this section when:** You're starting a new blueprint and need to identify which plugin to use for your infrastructure.

**Note:** The BPA CLI does not currently provide a command to list all available plugins. Plugin availability depends on your environment.

**Common plugin examples** (depending on your environment):
- **vsphere** - VMware vSphere VMs and infrastructure
- **aws** - Amazon Web Services resources
- **azure** - Microsoft Azure resources
- **gcp** - Google Cloud Platform resources
- **kubernetes** - Kubernetes resources
- **helm** - Helm charts
- **docker** - Docker containers
- **ansible** - Ansible playbooks
- **terraform** - Terraform modules

**To verify a plugin exists and see its node types:**
```bash
dap-bpa knowledge plugins list <plugin>
```

Example:
```bash
dap-bpa knowledge plugins list vsphere
```

**If you're not sure which plugin to use:**
- Search for examples: `dap-bpa knowledge blueprints find "<technology>"`
- Search documentation: `dap-bpa knowledge docs search "<technology>"`
- Refer to your environment configuration or existing blueprints

## Step 2: Search for Examples and Documentation

**Use this section when:** You want to learn from existing blueprints or need plugin-specific documentation.

**Action:**
```bash
dap-bpa knowledge blueprints find "vsphere vm"
dap-bpa knowledge docs search "vsphere server"
```

**What happens:** Returns example blueprints and documentation links.

## Step 3: Look Up Node Types

**Use this section when:** You need to get the exact properties and required fields for a specific node type before writing your blueprint.

**Action:**
```bash
dap-bpa knowledge plugins docs vsphere
dap-bpa knowledge plugins get vsphere dell.nodes.vsphere.Server
```

**What happens:** Returns the node type schema with properties, required fields, and examples.

## Step 4: Create the Blueprint File

**Use this section when:** You're ready to write the actual YAML blueprint file with the required structure.

**Action:** Create `blueprint.yaml` with these sections.

**Don't worry about the YAML length — we'll break it into clear sections, and you can build it piece by piece.**

**Header and imports:**
```yaml
tosca_definitions_version: dell_1_1

imports:
  - dell/types/types.yaml
  - plugin:vsphere?version= >=6.0.0

description: >
  Deploy a VM on vSphere
```

**Inputs:**
```yaml
inputs:
  vm_name:
    type: string
    display_label: VM Name
    description: Name for the virtual machine
    default: my-vm
```

**Node template:**
```yaml
node_templates:
  my_vm:
    type: dell.nodes.vsphere.Server
    properties:
      server:
        name: { get_input: vm_name }
        template: ubuntu-22.04-template
      management_network:
        name: VM Network
      connection_config:
        username: { get_secret: vsphere_username }
        password: { get_secret: vsphere_password }
        host: { get_secret: vsphere_host }
    interfaces:
      dell.interfaces.lifecycle:
        create:
          implementation: vsphere.node_server
```

## Step 5: Add Inputs for User Configuration

**Use this section when:** You need to make your blueprint reusable by adding configurable parameters that users can provide at deployment time.

**Action:** Add to the `inputs` section:

```yaml
inputs:
  vm_name:
    type: string
    display_label: VM Name
    description: Name for the virtual machine
    default: my-vm
    constraints:
      - pattern: '^[a-zA-Z][a-zA-Z0-9-]*$'
        error_message: Must start with a letter, alphanumeric and hyphens only.

  vm_cpus:
    type: integer
    display_label: vCPUs
    description: Number of virtual CPUs
    default: 2
    constraints:
      - in_range: [1, 16]

  vm_memory_mb:
    type: integer
    display_label: Memory (MB)
    description: Memory in megabytes
    default: 4096
```

## Step 6: Add Capabilities for Outputs

**Use this section when:** You need to expose important values from your deployment (like IP addresses, connection strings) to users or other deployments.

**Action:** Add the `capabilities` section:

```yaml
capabilities:
  vm_ip:
    description: IP address of the deployed VM
    value: { get_attribute: [my_vm, ip] }

  vm_name:
    description: Name of the deployed VM
    value: { get_attribute: [my_vm, name] }
```

## Step 7: Lint the Blueprint

**Use this section when:** You've written your blueprint and want to check for common errors and compliance with best practices before uploading.

**Action:**
```bash
dap-bpa blueprint lint --file blueprint.yaml --verify
```

**What happens:** The linter checks your blueprint against mandatory rules.

**Verification:** You should see `errorsFound: false`. If errors appear, fix them and re-run.

**Common errors:** Missing `display_label`, wrong prefix (`dell.*` not `cloudify.*`), literal secrets.

## Step 8: Validate Against Plugin Schemas

**Use this section when:** You've linted your blueprint and want to ensure all node properties match the plugin schemas before uploading.

**Action:**
```bash
dap-bpa blueprint validate-all --file blueprint.yaml
```

**What happens:** Validates each node's properties against the plugin's schema.

## Step 9: Upload the Blueprint

**Use this section when:** Your blueprint is linted and validated, and you're ready to upload it to the DAP Orchestrator.

**Action:**
```bash
dap-bpa orchestrator blueprints upload --file blueprint.yaml --id my-blueprint --revision v1.0.0
```

**What happens:** The blueprint is uploaded and becomes available for deployment.

**Verification:** You should see output confirming the upload:
```
Blueprint uploaded successfully
ID: my-blueprint
Revision: v1.0.0
State: uploaded
```

## Success Moment 🎉

Your blueprint is now uploaded and ready to use! You can see it in the orchestrator UI and list it via:
```bash
dap-bpa orchestrator blueprints get my-blueprint --fields id state revisions
```

**What you achieved:**
- ✅ Identified the right plugin for your infrastructure
- ✅ Created a complete blueprint file with a VM node
- ✅ Added configurable inputs for reusability
- ✅ Exposed outputs via capabilities
- ✅ Linted and validated your blueprint
- ✅ Successfully uploaded your blueprint to the orchestrator

## Common Pitfalls

| Issue | Cause | Fix |
|-------|-------|-----|
| Lint fails with missing display_label | Input missing `display_label` field | Add `display_label` to every input |
| Validation fails for unknown property | Typo in property name | Check plugin schema with `dap-bpa knowledge plugins get <plugin> <type>` |
| Secret in blueprint source | Using literal string with `get_secret` | Use `get_secret: { get_input: secret_name }` |
| Wrong TOSCA version | Using `cloudify_*` or `nativeedge_*` | Use `tosca_definitions_version: dell_1_1` |

## Multi-File Blueprints

If your blueprint has 2+ plugins or 5+ inputs, split into multiple files:

```
my-blueprint/
├── blueprint.yaml        # Main file with node_templates
├── inputs.yaml            # All inputs
├── capabilities.yaml      # All capabilities
└── scripts/               # Python scripts (if any)
```

---

# Guide: Create Deployment

## Overview

A deployment is an instance of a blueprint that creates actual resources in your infrastructure. This guide walks you through deploying a blueprint and monitoring the execution.

## Mental Model: What is a Deployment?

A deployment is a running instance of a blueprint in DAP.

Key concepts:
- **Blueprint** — the definition of what resources should be created
- **Deployment** — an instance created from a blueprint
- **Execution** — a workflow run that performs actions on the deployment, such as install or uninstall
- **Inputs** — values provided when creating the deployment
- **Capabilities** — outputs exposed by the deployment after execution

## Quick Start

The high-level flow for creating a deployment:

1. **Prepare** → Ensure blueprint is uploaded and secrets are ready
2. **Create** → Create the deployment with input values
3. **Monitor** → Watch the execution progress
4. **Verify** → Check deployment status and outputs
5. **Troubleshoot** → Address any failures if they occur

## Prerequisites

- A blueprint uploaded to the orchestrator (see the Write Blueprint guide)
- `dap-bpa` CLI installed and configured
- Access to a DAP Orchestrator instance
- Any credentials/secrets your blueprint requires

## Step 1: Verify Blueprint is Uploaded

**Objective:** Confirm your blueprint is available in the orchestrator.

**Action:**
```bash
dap-bpa orchestrator blueprints get my-blueprint --fields id state revisions
```

**Verification:** You should see `state: uploaded`.

## Step 2: Check Required Secrets

**Objective:** Ensure all secrets referenced in your blueprint exist.

**Action:**
```bash
dap-bpa orchestrator secrets list
```

**Verification:** All required secrets should appear in the list.

## Step 3: Create the Deployment

**Objective:** Create a deployment instance of your blueprint with input values.

**Action:**
```bash
dap-bpa orchestrator deployments create --blueprint-id my-blueprint --inputs '{"vm_name": "my-vm"}'
```

## Step 4: Monitor the Execution

**Objective:** Watch the deployment execution progress in real-time.

**Action:**
```bash
dap-bpa orchestrator executions get <execution_id> --fields id status error finished_operations total_operations
```

## Step 5: Check Execution Events

**Objective:** See detailed step-by-step progress and any error messages.

**Action:**
```bash
dap-bpa orchestrator events get <execution_id>
```

## Step 6: Verify Deployment Status

**Objective:** Confirm the deployment completed successfully.

**Action:**
```bash
dap-bpa orchestrator deployments get my-deployment --fields id deployment_status installation_status
```

**Verification:** You should see `deployment_status: created` and `installation_status: good`.

## Step 7: View Deployment Outputs

**Objective:** See the capabilities/outputs from your deployment.

**Note:** The `dap-bpa` CLI does not currently have a direct command to retrieve deployment outputs. Use the DAP Orchestrator UI or API to view deployment outputs.

## Success Moment 🎉

Your deployment is now running! You should see:
- `deployment_status: created`
- `installation_status: good`
- Your outputs/capabilities available via the DAP Orchestrator UI or API

## Common Pitfalls

| Issue | Cause | Fix |
|-------|-------|-----|
| Blueprint not found | Blueprint ID incorrect or not uploaded | Check blueprint state with `dap-bpa orchestrator blueprints get <id>` |
| Secret not found | Missing secret in orchestrator | Create the secret via `dap-bpa orchestrator secrets create --key <name> --value <val>` |
| Deployment stuck in pending | Execution not started or queued | Check execution status and events |

## Handling Failures

If the deployment fails:

1. Check the execution events: `dap-bpa orchestrator events get <execution_id>`
2. Identify the failed node and error
3. Fix the issue (update blueprint, fix inputs, create missing secrets)
4. Delete the failed deployment using the DAP Orchestrator UI or API
5. Create a new deployment with the fix

## Complete Blueprint Example

Here's the complete vSphere VM blueprint:

```yaml
tosca_definitions_version: dell_1_1

imports:
  - dell/types/types.yaml
  - plugin:vsphere?version= >=6.0.0

description: >
  Deploy a VM on vSphere

inputs:
  vm_name:
    type: string
    display_label: VM Name
    description: Name for the virtual machine
    default: my-vm

node_templates:
  my_vm:
    type: dell.nodes.vsphere.Server
    properties:
      server:
        name: { get_input: vm_name }
        template: ubuntu-22.04-template
      management_network:
        name: VM Network
      connection_config:
        username: { get_secret: vsphere_username }
        password: { get_secret: vsphere_password }
        host: { get_secret: vsphere_host }
    interfaces:
      dell.interfaces.lifecycle:
        create:
          implementation: vsphere.node_server

capabilities:
  vm_ip:
    description: IP address of the deployed VM
    value: { get_attribute: [my_vm, ip] }

  vm_name:
    description: Name of the deployed VM
    value: { get_attribute: [my_vm, name] }
```

---

# Guide: Create Secrets

## Overview

Secrets in DAP are secure storage for sensitive data like passwords, API keys, and tokens. This guide walks you through creating secrets and using them in blueprints.

## Mental Model: What are Secrets?

Think of secrets like a secure vault:
- **Secret store** is the vault (encrypted storage in DAP)
- **Secrets** are the items in the vault (passwords, keys, tokens)
- **Blueprints** request access to vault items (via `get_secret`)
- **Deployments** receive the actual values (resolved at runtime)

Secrets are never stored in blueprint files - they're referenced by name and resolved securely when the blueprint is deployed.

## Quick Start

The high-level flow for secret management:

1. **Create** → Add secrets to the DAP secret store
2. **Reference** → Use `get_secret` in blueprint inputs
3. **Deploy** → Secrets are resolved at deployment time
4. **Manage** → Update or delete secrets as needed

## Prerequisites

- `dap-bpa` CLI installed and configured (`dap-bpa setup` completed)
- Access to a DAP Orchestrator instance
- The sensitive values you want to store (passwords, API keys, etc.)

## Step 1: Create a Secret

**Use this section when:** You need to store a sensitive value (password, API key, token) in the DAP secret store.

**Action:**
```bash
dap-bpa orchestrator secrets create --key my_secret --value "my-secret-value"
```

For JSON secrets (with nested keys):
```bash
dap-bpa orchestrator secrets create --key my_secret --value '{"api_key": "xyz123", "token": "abc456"}'
```

With optional metadata:
```bash
dap-bpa orchestrator secrets create --key my_secret --value "my-value" --type generic --display-name "My Secret" --description "Secret description"
```

**What happens:** The secret is encrypted and stored in the DAP secret store.

## Step 2: Reference Secrets in Blueprint Inputs

**Use this section when:** You're writing a blueprint and need to allow users to specify which secret to use for a credential.

**Action:** Add to the `inputs` section:

```yaml
inputs:
  vsphere_username:
    type: string
    display_label: vSphere Username
    description: Username for vSphere authentication

  vsphere_password:
    type: secret_key
    display_label: vSphere Password
    description: Password for vSphere authentication
```

**What happens:** The `type: secret_key` marks this input as a secret reference in the UI.

## Step 3: Use Secrets in Node Properties

**Use this section when:** You need to pass secret values to node properties in your blueprint.

**Action:** Use `get_secret` with an input reference:

```yaml
node_templates:
  my_vm:
    type: dell.nodes.vsphere.Server
    properties:
      connection_config:
        username: { get_input: vsphere_username }
        password: { get_secret: { get_input: vsphere_password } }
        host: { get_secret: { get_input: vsphere_host } }
```

**What happens:** At deployment time, the orchestrator resolves the secret names to actual values.

## Step 4: Use Nested JSON Secrets

**Use this section when:** Your secret contains JSON data with multiple keys (like an API response with multiple fields).

**Action:** Use array notation with `get_secret`:

```yaml
# Secret stored as: {"api_key": "xyz123", "token": "abc456"}
node_templates:
  my_node:
    type: dell.nodes.SomeType
    properties:
      api_key: { get_secret: [my_secret, api_key] }
      token: { get_secret: [my_secret, token] }
```

## Success Moment 🎉

Your secrets are now set up and ready to use! You can verify them:
```bash
dap-bpa orchestrator secrets list
```

## Security Best Practices

**Never do these:**
- ❌ Use literal strings with `get_secret`: `{ get_secret: "my-password" }`
- ❌ Store secrets in blueprint source files
- ❌ Log secret values in scripts or operations
- ❌ Use `get_secret` in capabilities or outputs (they display in UI)
- ❌ Store secrets in `runtime_properties` (retrievable via API)

**Always do these:**
- ✅ Use `type: secret_key` for secret inputs
- ✅ Reference secrets via inputs: `{ get_secret: { get_input: secret_name } }`
- ✅ Keep secrets in the orchestrator secret store
- ✅ Use secret rotation policies where applicable
- ✅ Limit secret access to required users/tenants

## Managing Secrets

**List all secrets:**
```bash
dap-bpa orchestrator secrets list
```

**Get a specific secret:**
```bash
dap-bpa orchestrator secrets get my_secret
```

**Note:** To update a secret value, you must delete it from the orchestrator UI and recreate it. The CLI does not currently support update or delete operations for secrets.

---

# Guide: Plugins Overview

## Overview

Plugins are modules that extend DAP with support for specific infrastructure and services. Each plugin provides node types, operations, and integration patterns for a particular technology (AWS, Kubernetes, vSphere, etc.).

## Mental Model: What are Plugins?

Think of plugins like specialized toolkits:
- **DAP core** is the workbench (the orchestrator, workflows, TOSCA engine)
- **Plugins** are the toolkits (each knows how to work with specific technologies)
- **Node types** are the tools (VM creator, pod deployer, storage provisioner)
- **Operations** are the techniques (create, configure, start, stop, delete)

## Quick Start

The high-level flow for using plugins:

1. **List** → See available plugins
2. **Choose** → Select the right plugin for your infrastructure
3. **Import** → Add plugin import to your blueprint
4. **Look up** → Get node type properties and operations
5. **Use** → Write node templates using plugin node types

## Prerequisites

- `dap-bpa` CLI installed and configured (`dap-bpa setup` completed)
- Access to a DAP Orchestrator instance
- Basic understanding of what infrastructure you want to deploy

## Step 1: Identify Available Plugins

**Use this section when:** You want to discover which plugins are available in your DAP environment.

**Note:** The BPA CLI does not currently provide a command to list all available plugins. Plugin availability depends on your environment configuration.

**Common plugin examples** (depending on your environment):
- vsphere, aws, azure, gcp (cloud providers)
- kubernetes, helm, docker (container orchestration)
- ansible, fabric, terraform (automation/IaC)
- openstack, libvirt, vcloud (virtualization)
- storage, utilities (specialized)

**To verify a specific plugin exists:**
```bash
dap-bpa knowledge plugins list <plugin>
```

Example:
```bash
dap-bpa knowledge plugins list vsphere
```

## Step 2: Find Plugin Documentation

**Use this section when:** You need to learn about a specific plugin's capabilities.

**Action:**
```bash
dap-bpa knowledge plugins docs <plugin>
```

Example:
```bash
dap-bpa knowledge plugins docs vsphere
```

**Or search for examples:**
```bash
dap-bpa knowledge blueprints find "<technology>"
```

## Step 3: Import Plugins in Blueprint

**Use this section when:** You're writing a blueprint and need to import the plugins you'll use.

**Action:** Add to the `imports` section:

```yaml
imports:
  - dell/types/types.yaml
  - plugin:<plugin_name>?version= >=<version>
```

Example:
```yaml
imports:
  - dell/types/types.yaml
  - plugin:vsphere?version= >=6.0.0
  - plugin:ansible?version= >=2.9.0
```

## Step 4: Look Up Node Types

**Use this section when:** You need to see what node types a plugin provides and their properties.

**Action:**
```bash
dap-bpa knowledge plugins list <plugin>
```

Example:
```bash
dap-bpa knowledge plugins list vsphere
```

## Step 5: Get Node Type Details

**Use this section when:** You need the exact properties, required fields, and operations for a specific node type.

**Action:**
```bash
dap-bpa knowledge plugins get <plugin> <node_type>
```

Example:
```bash
dap-bpa knowledge plugins get vsphere dell.nodes.vsphere.Server
```

## Step 6: Get Plugin Documentation

**Use this section when:** You need plugin-specific documentation, authentication guides, or usage patterns.

**Action:**
```bash
dap-bpa knowledge plugins docs <plugin>
```

Example:
```bash
dap-bpa knowledge plugins docs vsphere
```

## Success Moment 🎉

You now understand how to find and use plugins! You can verify by:
```bash
dap-bpa knowledge plugins list vsphere
dap-bpa knowledge plugins docs vsphere
dap-bpa knowledge docs search "vsphere vm"
```

## Plugin Authentication

Authentication methods vary by plugin. **Common patterns** (refer to plugin-specific docs for details):

| Plugin Example | Typical Authentication Method |
|--------|----------------------|
| vsphere | Username/password or session token |
| aws | Access key ID and secret access key |
| azure | Service principal or managed identity |
| kubernetes | Kubeconfig or service account token |
| docker | Registry credentials |
| ansible | Inventory and SSH keys |
| terraform | Provider-specific credentials |
| helm | Kubeconfig and registry credentials |

**To get plugin-specific authentication details:**
```bash
dap-bpa knowledge plugins docs <plugin>
```

Most plugins use DAP secrets for credentials. See the "Create Secrets" guide for details.

## Common Pitfalls

| Issue | Cause | Fix |
|-------|-------|-----|
| Plugin not found | Plugin not installed or wrong name | Use `dap-bpa knowledge blueprints find "<technology>"` to find examples |
| Unknown node type | Typo in node type name or wrong plugin | Use `dap-bpa knowledge plugins list <plugin>` to verify |
| Missing required property | Property not provided in blueprint | Use `dap-bpa knowledge plugins get <plugin> <type>` to see required fields |
| Authentication failed | Wrong credentials or missing secret | Verify secret exists and credentials are correct |

---

# Guide: Delete Resources

## Overview

When you're done with resources in DAP, you'll want to clean them up to avoid clutter and potential costs. This guide walks you through deleting deployments, blueprints, secrets, and plugins safely.

## Mental Model: Resource Cleanup

Think of cleanup like kitchen cleanup:
- **Deployments** are the used dishes (running instances of blueprints)
- **Blueprints** are the recipes (definitions, can be reused)
- **Secrets** are the spices (credentials, should be kept secure)
- **Plugins** are the utensils (tools, rarely need deletion)

Cleanup order matters: clean deployments first (the dishes), then decide if you need the recipes (blueprints), and handle sensitive items (secrets) carefully.

## Quick Start

The high-level flow for resource cleanup:

1. **Deployments** → Uninstall and delete deployments
2. **Blueprints** → Delete blueprints (if no longer needed)
3. **Secrets** → Delete secrets (after verifying no dependencies)
4. **Plugins** → Delete plugins (rare, usually not needed)

## Prerequisites

- `dap-bpa` CLI installed and configured (`dap-bpa setup` completed)
- Access to a DAP Orchestrator instance
- Understanding of which resources you want to delete

## Step 1: Delete Deployments

**Use this section when:** You want to remove a running deployment and clean up its resources.

**Note:** The `dap-bpa` CLI does not currently have a direct delete command for deployments. Use the DAP Orchestrator UI or API to delete deployments.

## Step 2: Delete Blueprints

**Use this section when:** You no longer need a blueprint and want to remove it from the orchestrator.

**Note:** The `dap-bpa` CLI does not currently have a delete command for blueprints. Use the DAP Orchestrator UI or API to delete blueprints.

## Step 3: Delete Secrets

**Use this section when:** You need to remove a secret from the orchestrator (e.g., after rotating credentials or decommissioning a service).

**Note:** The `dap-bpa` CLI does not currently have a delete command for secrets. Use the DAP Orchestrator UI or API to delete secrets.

## Step 4: Delete Plugins

**Use this section when:** You need to remove a plugin from the orchestrator (rare - usually not necessary).

**Action:**
```bash
dap-bpa orchestrator plugins delete <plugin_id>
```

Use `--force` only if the command fails due to safety checks or confirmation prompts:
```bash
dap-bpa orchestrator plugins delete <plugin_id> --force
```

**What happens:** The plugin is removed from the orchestrator.

**Warning:** You cannot delete a plugin if there are blueprints that import it. Delete those blueprints first.

## Success Moment 🎉

Your resources are cleaned up! You can verify:
```bash
dap-bpa orchestrator deployments list
dap-bpa orchestrator blueprints list
dap-bpa orchestrator secrets list
```

## Dependency Considerations

**Deletion order matters:**

1. **Deployments first** - Deployments depend on blueprints and secrets
2. **Blueprints second** - Blueprints depend on plugins
3. **Secrets third** - Secrets may be referenced by blueprints or deployments
4. **Plugins last** - Plugins are referenced by blueprints

**Check dependencies before deletion:**

```bash
# Check if blueprint has active deployments
dap-bpa orchestrator deployments list

# Check if secret is referenced (search blueprint files)
grep -r "get_secret.*<secret_name>" .

# Check if plugin is used (search blueprint files)
grep -r "plugin:<plugin_name>" .
```

## Common Pitfalls

| Issue | Cause | Fix |
|-------|-------|-----|
| Blueprint deletion failed | Active deployments still using it | Delete deployments first |
| Secret deletion broke deployment | Deployment still references secret | Update deployment or delete it first |
| Plugin deletion failed | Blueprints still import it | Delete those blueprints first |

## Safe Cleanup Workflow

For a complete cleanup of a project:

1. **List all resources:**
   ```bash
   dap-bpa orchestrator deployments list
   dap-bpa orchestrator blueprints list
   dap-bpa orchestrator secrets list
   ```

2. **Delete deployments:**
   Use the DAP Orchestrator UI or API to delete deployments.

3. **Delete blueprints:**
   Use the DAP Orchestrator UI or API to delete blueprints.

4. **Delete secrets:**
   Use the DAP Orchestrator UI or API to delete secrets.

---

## Next Steps

After completing any guide, you can:

- **Write blueprints** → Use the Write Blueprint guide
- **Deploy blueprints** → Use the Create Deployment guide
- **Manage secrets** → Use the Create Secrets guide
- **Understand plugins** → Use the Plugins Overview guide
- **Clean up resources** → Use the Delete Resources guide

For detailed plugin-specific guidance, see the individual plugin skills (dap-plugin-aws, dap-plugin-kubernetes, etc.).
