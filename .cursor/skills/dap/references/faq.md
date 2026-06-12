# DAP Onboarding FAQ

Common questions and concise answers for new DAP users.

---

## What is DAP?

**DAP (Dell Automation Platform)** is an infrastructure orchestration platform that automates the deployment and lifecycle management of resources across cloud, on-premises, and hybrid environments. It was previously known as NativeEdge. DAP uses TOSCA-based blueprints to define infrastructure declaratively and executes them against real infrastructure via plugins.

## What is BPA?

**BPA (Blueprint Assist)** is the developer tooling layer for DAP. It includes:
- The `bpa` CLI — for uploading blueprints, managing secrets, querying plugins, and interacting with the orchestrator
- A knowledge base — searchable docs, node type schemas, and example blueprints
- IDE integrations — skills and extensions that surface DAP guidance in your editor

BPA is how developers author and validate blueprints before deploying them via DAP.

## What is a Blueprint?

A **blueprint** is a YAML file that declares what infrastructure should exist and how to create it. Written in TOSCA (`tosca_definitions_version: dell_1_1`), it defines:
- **Inputs** — user-provided parameters at deployment time
- **Node templates** — the resources to create (VMs, containers, networks)
- **Capabilities** — outputs exposed after deployment (IP addresses, endpoints)

A blueprint is a reusable definition. Multiple deployments can be created from the same blueprint with different input values.

## What is a Plugin?

A **plugin** is a module that extends DAP with support for a specific technology or infrastructure provider. Plugins provide:
- **Node types** — the resource types you can declare in a blueprint (e.g., `dell.nodes.vsphere.Server`)
- **Operations** — lifecycle actions (create, configure, start, stop, delete)
- **Authentication patterns** — how to connect to the target system

Common plugins include vsphere, aws, azure, kubernetes, helm, ansible, and terraform. You import a plugin in your blueprint's `imports` section.

## What is a Deployment?

A **deployment** is a running instance of a blueprint. When you deploy a blueprint, DAP:
1. Takes the blueprint definition and your input values
2. Creates an execution (a workflow run)
3. Provisions the actual resources in your infrastructure

A deployment tracks the state of those resources over time. Multiple deployments can be created from one blueprint.

## What is a Node Template?

A **node template** is a single resource declaration inside a blueprint's `node_templates` section. Each node template has:
- A **type** — the plugin node type (e.g., `dell.nodes.vsphere.Server`)
- **Properties** — configuration values for that resource
- **Interfaces** — lifecycle operations to run (create, configure, start)
- **Relationships** — dependencies on other node templates

At deployment time, each node template becomes a concrete resource in your infrastructure.

## What is a Capability?

A **capability** is an output value that a deployment exposes after it runs. Capabilities are defined in the blueprint's `capabilities` section and use `get_attribute` to read values from node templates (such as an IP address or hostname).

Capabilities are viewable in the DAP Orchestrator UI or API after a successful deployment. They should never contain secrets.

## What is an Execution?

An **execution** is a workflow run on a deployment. The most common executions are:
- `install` — provisions resources (runs on deployment creation)
- `uninstall` — tears down resources

You can monitor an execution's progress with `bpa orchestrator executions get <execution_id>` and view step-by-step events with `bpa orchestrator events get <execution_id>`.

## What's the difference between a Blueprint and a Deployment?

| | Blueprint | Deployment |
|---|---|---|
| What it is | A definition / recipe | A running instance |
| Reusable? | Yes — deploy many times | No — one instance per creation |
| Contains inputs? | Declares input schema | Has actual input values |
| Tracks resources? | No | Yes |
| Analogy | Class / template | Object / instance |

## What's the difference between DAP and BPA?

**DAP** is the orchestration platform — it runs and manages deployments.
**BPA** is the developer tooling — it helps you author, validate, and upload blueprints, and interact with DAP via CLI.

You use BPA to write blueprints; DAP executes them.

## What's the difference between a Plugin and a Node Type?

A **plugin** is the package (e.g., the vsphere plugin). A **node type** is a specific resource kind provided by that plugin (e.g., `dell.nodes.vsphere.Server`). One plugin typically provides many node types.
