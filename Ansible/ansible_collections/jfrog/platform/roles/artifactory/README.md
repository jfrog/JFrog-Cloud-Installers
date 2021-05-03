# artifactory
The artifactory role installs the Artifactory Pro software onto the host. Per the Vars below, it will configure a node as primary or secondary. This role uses secondary roles artifactory_nginx to install nginx.

## Role Variables
* _server_name_: **mandatory** This is the server name. eg. "artifactory.54.175.51.178.xip.io"
* _artifactory_upgrade_only_: Perform an software upgrade only. Default is false.

Additional variables can be found in [defaults/main.yml](./defaults/main.yml).

## Example Playbook
```
---
- hosts: artifactory_servers
  roles:
    - artifactory
```

## Upgrades
The Artifactory role supports software upgrades. To use a role to perform a software upgrade only, use the _artifactory_upgrade_only_ variable and specify the version. See the following example.

```
- hosts: artifactory_servers
  vars:
    artifactory_version: "{{ lookup('env', 'artifactory_version_upgrade') }}"
    artifactory_upgrade_only: true
  roles:
    - artifactory
```