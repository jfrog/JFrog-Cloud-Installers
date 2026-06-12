# ISV Onboarding Workflow — Post-Generation Guidance

After successfully generating and validating a blueprint (lint passes), optionally guide the user through the complete workflow from blueprint to deployment.

## When to Offer

Offer ISV onboarding workflow guidance when:
- Blueprint generation is complete (YAML written and linted successfully)
- User has not yet uploaded the blueprint
- User is working on blueprint conversion from existing assets (Ansible, Terraform, Helm, etc.)

## How to Offer

After blueprint lint passes, present the option:

```
Your blueprint is ready!

**Next Steps** — You have two options:

1. **Save locally** — Stop here and use the blueprint files in your project
2. **Test in DAP** — Upload and deploy to verify it works end-to-end

Would you like me to guide you through uploading and testing this blueprint in DAP?
```

## If User Accepts (Yes)

Guide them through:

1. **Authentication** (if not already configured)
   - Reference `references/onboarding-setup.md`
   - Walk through `dap-bpa setup` command
   - Verify with `dap-bpa orchestrator blueprints list`

2. **Upload Blueprint**
   - Reference `references/onboarding-blueprints.md`
   - Guide through lint → upload → verify workflow
   - Show `dap-bpa orchestrator blueprints upload` command

3. **Create Secrets** (if blueprint requires them)
   - Reference `references/onboarding-secrets.md`
   - Identify required secrets from blueprint
   - Guide through `dap-bpa orchestrator secrets create` commands

4. **Deploy and Monitor**
   - Reference `references/onboarding-deployments.md` and monitor section
   - Offer automated monitoring: `dap-bpa monitor --file blueprint.yaml`
   - Or manual deployment: `dap-bpa orchestrator deployments create`
   - Show how to check status and view outputs

5. **Verify Success**
   - Check deployment status
   - Review capabilities/outputs
   - Suggest next steps (production deployment, CI/CD setup)

## If User Declines (No)

Acknowledge and provide a reference:

```
No problem! Your blueprint files are ready to use.

When you're ready to test in DAP, see the ISV onboarding workflow guide:
`references/isv-onboarding-workflow.md`

Or ask me: "Walk me through deploying my blueprint to DAP"
```

## Key Principles

- **Make it optional** — Never force the workflow, users can stop at any stage
- **Reference existing docs** — Link to onboarding-*.md files, don't duplicate content
- **Use existing capabilities** — No new code, just guide users through existing DAP/BPA commands
- **Maintain context** — Remember blueprint details (file path, inputs, required secrets)
- **Offer monitoring** — Suggest `dap-bpa monitor` for automated testing and error diagnosis

## Example Flow

**After blueprint lint passes:**

> Your blueprint is ready!
>
> Would you like me to guide you through uploading and testing this blueprint in DAP? (yes/no)

**User: "yes"**

> Great! Let's get this deployed. First, we need to make sure you're authenticated with DAP.
>
> **Step 1: Authentication**
>
> Run this command to set up your DAP credentials:
> ```bash
> dap-bpa setup
> ```
>
> You'll need:
> - Portal domain (from your administrator)
> - Orchestrator domain
> - Org ID (tenant)
> - Client ID and secret (create in DAP portal: Identity Management → Clients)
>
> Let me know when setup is complete, or if you encounter any issues.

**User: "done"**

> Perfect! Let's verify authentication:
> ```bash
> dap-bpa orchestrator blueprints list
> ```
>
> If that works, we're ready to upload your blueprint.
>
> **Step 2: Upload Blueprint**
>
> ```bash
> dap-bpa orchestrator blueprints upload --file blueprint.yaml --id my-isv-blueprint --revision 1.0.0
> ```
>
> This will upload your blueprint to the DAP Orchestrator. Let me know when it completes.

Continue through secrets, deployment, and monitoring steps as above.
