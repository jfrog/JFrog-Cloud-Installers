# Insight
The insight role will install insight software onto the host. An Artifactory server and Postgress database is required.

### Role Variables
* _insight_upgrade_only_: Perform an software upgrade only. Default is false.

Additional variables can be found in [defaults/main.yml](./defaults/main.yml).
## Example Playbook
```
---
- hosts: insight_servers
  roles:
    - insight
```

## Upgrades
The insight role supports software upgrades. To use a role to perform a software upgrade only, use the _insight_upgrade_only_ variables and specify the version. See the following example.

```
- hosts: insight_servers
  vars:
    insight_version: "{{ lookup('env', 'insight_version_upgrade') }}"
    insight_upgrade_only: true
  roles:
    - insight
```