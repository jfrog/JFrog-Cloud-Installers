# DAP Onboarding — Deployments

## Create via UI

1. **Inventory** → **Blueprints** → click your blueprint → **Create Deployment**
2. Enter a Deployment ID, fill in inputs, click **Deploy**
3. Click the deployment to monitor execution progress — nodes, events, and logs update in real time

When finished: `deployment_status: created`, `installation_status: good`.

## Create via CLI

```bash
bpa orchestrator deployments create --blueprint-id my-blueprint --inputs '{"input_name": "value"}'

# Monitor execution
bpa orchestrator executions get <execution_id> --fields id status error finished_operations total_operations
bpa orchestrator events get <execution_id>
```

## View outputs/capabilities

```bash
bpa orchestrator deployments get <deployment_id>
# capabilities are included in the default response fields
```
