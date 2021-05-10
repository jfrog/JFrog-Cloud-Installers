# JFrog Ansible Installers Collection (Deprecated) 

## Getting Started
 
 1. Install this collection from Ansible Galaxy. This collection is also available in RedHat Automation Hub.
    
    ```
    ansible-galaxy collection install jfrog.installers
    ```
        
    Ensure you reference the collection in your playbook when using these roles.
        
    ```
    ---
    - hosts: xray
      collections:
        - jfrog.installers
      roles:
        - xray
    
    ```
    
 2. Ansible uses SSH to connect to hosts. Ensure that your SSH private key is on your client and the public keys are installed on your Ansible hosts. 
 
 3. Create your inventory file. Use one of the examples from the [examples directory](https://github.com/jfrog/JFrog-Cloud-Installers/tree/master/Ansible/examples) to construct an inventory file (hosts.yml) with the host addresses and variables.
 
 4. Create your playbook. Use one of the examples from the [examples directory](https://github.com/jfrog/JFrog-Cloud-Installers/tree/master/Ansible/examples) to construct a playbook using the JFrog Ansible roles. These roles will be applied to your inventory and provision software.
 
 5. Then execute with the following command to provision the JFrog software with Ansible. Variables can also be passed in at the command-line.
 
 ```
ansible-playbook -i hosts.yml playbook.yml --extra-vars "master_key=$(openssl rand -hex 16) join_key=$(openssl rand -hex 16)"
```

## Autogenerating Master and Join Keys
You may want to auto-generate your master amd join keys and apply it to all the nodes.

```
ansible-playbook -i hosts.yml playbook.yml --extra-vars "master_key=$(openssl rand -hex 16) join_key=$(openssl rand -hex 16)"
```

## Using [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) to Encrypt Vars
Some vars you may want to keep secret. You may put these vars into a separate file and encrypt them using [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html).

```
ansible-vault encrypt secret-vars.yml --vault-password-file ~/.vault_pass.txt
```

then in your playbook include the secret vars file.

```
- hosts: primary

  vars_files:
    - ./vars/secret-vars.yml
    - ./vars/vars.yml

  roles:
    - artifactory
```

## Bastion Hosts
In many cases, you may want to run this Ansible collection through a Bastion host to provision JFrog servers. You can include the following Var for a host or group of hosts:

```
ansible_ssh_common_args: '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -A user@host -W %h:%p"'

eg.
ansible_ssh_common_args: '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -A ubuntu@{{ azureDeployment.deployment.outputs.lbIp.value }} -W %h:%p"'
```

## Upgrades
The Artifactory and Xray roles support software upgrades. To use a role to perform a software upgrade only, use the _artifactory_upgrade_only_ or _xray_upgrade_only_ variables and specify the version. See the following example.

```
- hosts: artifactory
  vars:
    artifactory_version: "{{ lookup('env', 'artifactory_version_upgrade') }}"
    artifactory_upgrade_only: true
  roles:
    - artifactory

- hosts: xray
  vars:
    xray_version: "{{ lookup('env', 'xray_version_upgrade') }}"
    xray_upgrade_only: true
  roles:
    - xray
```
