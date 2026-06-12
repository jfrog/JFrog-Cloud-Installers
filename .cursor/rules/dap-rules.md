---
name: dap-rules
description: Blueprint authoring compliance rules — apply whenever writing, reviewing, or linting DAP blueprint YAML.
alwaysApply: true
version: "1.0"
---

# DAP Blueprint Rules

## Skill Usage

- **Clarify ambiguous YAML requests.** If the user asks to write or fix "YAML" without specifying the type, ask whether it is a DAP blueprint, a Kubernetes manifest, a Helm values file, or something else. Do not assume.
- **You MUST invoke the `dap` skill first when working on blueprints.** Do NOT jump directly to a plugin-specific skill — `dap` is the router and must run before any other blueprint skill. It will direct you to the correct plugin or use-case skill.
- **Use plugin/use-case skills.** There are dedicated skills for each plugin (AWS, vSphere, Kubernetes, Helm, Terraform, Script, etc.) and for specialized use cases. The `dap` skill will guide you to the correct one.
- **Deployment Update skill** is for Day 2 operations — updating a running deployment's blueprint, inputs, or topology after initial install.
- **Service Composition skill** is for connecting multiple blueprints/deployments and processes together (sub-deployments, service components, deployment chaining).
- **Load `blueprint-rules.md`** when writing or reviewing blueprint YAML — it contains the detailed compliance rules (rule refs like BS-*, TD-*, SC-*, etc.).
- **Load `dap-monitor-check.md`** to check the result of the last babysitter/monitor run before starting a new one.

## Linting & Validation

- **Always run the linter** (`bpa blueprint lint --file <path>`) after making your initial changes to a blueprint. It catches structural and compliance issues early.
- **Then validate** (`bpa blueprint validate-all --file <path>`) for per-node structural checks.
- **Linter findings are correct ~99% of the time.** Treat every Error and Warning as a real problem. False positives exist but are rare — do not dismiss a finding because fixing it seems inconvenient or because you believe your output is correct. If you genuinely believe a finding is a false positive, explain why explicitly before skipping it.
