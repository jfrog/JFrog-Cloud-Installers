# DAP Onboarding — Plugin Catalog

## Browse via UI

1. Navigate to **Catalog** in the left sidebar
2. Click a plugin name to see its node types, version, and documentation link

## Upload a plugin via UI

1. **Catalog** → **Upload Plugin**
2. Provide the plugin package URL or `.wgn` file → **Upload**

## Inspect plugins via CLI

```bash
bpa knowledge plugins list <plugin>           # node types
bpa knowledge plugins docs <plugin>           # full plugin reference
bpa knowledge plugins get <plugin> <type>     # specific node type properties
```

Available plugins: ansible, aws, azure, docker, fabric, helm, hzp-edge, kubernetes, libvirt, openstack, redfish, storage, terraform, terragrunt, utilities, vcloud, vsphere.

## Upload/delete a plugin via CLI

```bash
bpa orchestrator plugins upload --file <path.wgn>
bpa orchestrator plugins delete <plugin_id>
```
