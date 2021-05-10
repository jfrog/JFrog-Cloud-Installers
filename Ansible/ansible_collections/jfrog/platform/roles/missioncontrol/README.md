# Missioncontrol
The missioncontrol role will install missioncontrol software onto the host. An Artifactory server and Postgress database is required.

### Role Variables
* _mc_upgrade_only_: Perform an software upgrade only. Default is false.

Additional variables can be found in [defaults/main.yml](./defaults/main.yml).
## Example Playbook
```
---
- hosts: missioncontrol_servers
  roles:
    - missioncontrol
```

## Upgrades
The missioncontrol role supports software upgrades. To use a role to perform a software upgrade only, use the _xray_upgrade_only_ variables and specify the version. See the following example.

```
- hosts: missioncontrol_servers
  vars:
    missioncontrol_version: "{{ lookup('env', 'missioncontrol_version_upgrade') }}"
    mc_upgrade_only: true
  roles:
    - missioncontrol
```