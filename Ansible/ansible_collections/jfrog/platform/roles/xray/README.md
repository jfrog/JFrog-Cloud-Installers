# Xray
The xray role will install Xray software onto the host. An Artifactory server and Postgress database is required.

### Role Variables
* _xray_upgrade_only_: Perform an software upgrade only. Default is false.

Additional variables can be found in [defaults/main.yml](./defaults/main.yml).
## Example Playbook
```
---
- hosts: xray_servers
  collections:
    - community.general
  roles:
    - xray
```

## Upgrades
The Xray role supports software upgrades. To use a role to perform a software upgrade only, use the _xray_upgrade_only_ variables and specify the version. See the following example.

```
- hosts: xray_servers
  collections:
    - community.general
  vars:
    xray_version: "{{ lookup('env', 'xray_version_upgrade') }}"
    xray_upgrade_only: true
  roles:
    - xray
```