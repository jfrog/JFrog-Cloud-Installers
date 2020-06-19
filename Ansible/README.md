# JFrog Ansible Installers Collection

This Ansible directory consists of the following directories that support the JFrog Ansible collection.
 
 * [ansible_collections directory](ansible_collections) - This directory contains the Ansible collection package that has the Ansible roles for Artifactory and Xray. See the collection [README](ansible_collections/README.md) for details on the available roles and variables.
 * [examples directory](examples) - This directory contains example playbooks for various architectures from single Artifactory (RT) deployments to high-availability setups.
 * [infra directory](infra) - This directory contains example infrastructure templates that can be used for testing and as example deployments.
 * [test directory](test) - This directory contains Gradle tests that can be used to verify a deployment. It also has Ansible playbooks for creating infrastructure, provisioning software and testing with Gradle.
 
 ## Getting Started
 
 1. Install this collection from Ansible Galaxy. This collection is also available in RedHat Automation Hub.
    ```
    ansible-galaxy collection install jfrog.installers
    ```
 2. Ansible uses SSH to connect to hosts. Ensure that your SSH private key is on your client and the public keys are installed on your Ansible hosts. 
 
 3. Create your inventory file. Use one of the examples from the [examples directory](examples) to construct an inventory file (hosts.yml) with the host addresses and variables.
 
 4. Create your playbook. Use one of the examples from the [examples directory](examples) to construct a playbook using the JFrog Ansible roles. These roles will be applied to your inventory and provision software.
 
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

## Building the Collection Archive
1. Go to the [ansible_collections/jfrog/installers directory](ansible_collections/jfrog/installers).
2. Update the galaxy.yml meta file as needed. Update the version.
3. Build the archive.
```
ansible-galaxy collection build
```
