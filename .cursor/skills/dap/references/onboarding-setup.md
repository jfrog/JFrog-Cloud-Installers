# DAP Onboarding — Initial Setup

Full product documentation: https://www.dell.com/support/product-details/en-us/product/dell-automation-platform-components/resources/manuals

## UI

The DAP Orchestrator UI is accessed from the DAP portal:

1. Log in to the DAP portal (URL provided by your administrator).
2. Click **Orchestrator** to open the Orchestrator UI.
3. Blueprints and Deployments are under **Inventory** in the left sidebar. Catalog (Plugins) and Secrets are also accessible from the sidebar.

## CLI

The `bpa` CLI authenticates with credentials obtained from the DAP portal:

1. **Create a client in the portal:**
   - Log in to the DAP portal
   - Go to **Identity Management** → **Clients**
   - Click **Add** (or **Edit** an existing client)
   - Fill in: name, description, and choose a role from the available options
   - Copy the client details: **tenant (org)**, **client ID**, **client secret**

2. **Configure the CLI** — run setup (recommended) or write the config directly:

   ```bash
   bpa setup
   # Prompts for: portal domain, orchestrator domain, org ID, client ID, client secret
   ```

   Or create `~/.blueprint-assist/config.json` directly:

   ```json
   {
     "orchestrators": {
       "default": {
         "portalDomain": "your-portal.dell.com",
         "orchestratorDomain": "your-orchestrator.dell.com",
         "orgId": "your-org-id",
         "clientId": "your-client-id",
         "clientSecret": "your-client-secret"
       }
     }
   }
   ```

3. **Verify:**

   ```bash
   bpa orchestrator blueprints list
   ```
