# Distribution
The Distribution role will install distribution software onto the host. An Artifactory server and Postgress database is required.

### Role Variables
* _distribution_upgrade_only_: Perform an software upgrade only. Default is false.

Additional variables can be found in [defaults/main.yml](./defaults/main.yml).
## Example Playbook
```
---
- hosts: distribution_servers
  collections:
    - community.general
  roles:
    - distribution
```

## Upgrades
The distribution role supports software upgrades. To use a role to perform a software upgrade only, use the _xray_upgrade_only_ variables and specify the version. See the following example.

```
- hosts: distributionservers
  collections:
    - community.general
  vars:
    distribution_version: "{{ lookup('env', 'distribution_version_upgrade') }}"
    distribution_upgrade_only: true
  roles:
    - distribution
```