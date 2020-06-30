# JFrog Ansible Collection

This Ansible directory consists of the following directories that support the JFrog Ansible collection.
 
 * [collection directory](collection) - This directory contains the Ansible collection package that has the Ansible roles for Artifactory and Xray. See the collection [README](collection/README.md) for details on the available roles and variables.
 * [infra directory](infra) - This directory contains example infrastructure templates that can be used for testing and as example deployments.
 * [project directory](project) - This directory contains example playbooks for various architectures from single Artifactory (RT) deployments to high-availability setups.
 * [test directory](test) - This directory contains Gradle tests that can be used to verify a deployment. It also has Ansible playbooks for creating infrastructure, provisioning software and testing with Gradle.
 
 ## Getting Started
 
 1. Install this collection or the roles in your Ansible path using your ansible.cfg file. The following is an example:
 ```
# Installs collections into [current dir]/ansible_collections/namespace/collection_name
collections_paths = ~/.ansible/collections:/usr/share/ansible/collections:collection

# Installs roles into [current dir]/roles/namespace.rolename
roles_path = Ansible/collection/jfrog/ansible/roles
```
 2. Ansible uses SSH to connect to hosts. Ensure that your SSH private key is on your client and the public keys are installed on your Ansible hosts. If you are using a bastion host, you can add the following Ansible variable to allow proxying through the bastion host.
 ```
 ansible_ssh_common_args: '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -A user@host -W %h:%p"'
 
 eg.
 ansible_ssh_common_args: '-o ProxyCommand="ssh -o StrictHostKeyChecking=no -A ubuntu@{{ azureDeployment.deployment.outputs.lbIp.value }} -W %h:%p"'
 ```
 3. Create your inventory file. Use one of the examples from the [project directory](project) to construct an inventory file (hosts.yml) with the host addresses and variables.
 
 4. Create your playbook. Use one of the examples from the [project directory](project) to construct a playbook using the JFrog Ansible roles. These roles will be applied to your inventory and provision software.
 
 5. Then execute with the following command to provision the JFrog software with Ansible. Variables can also be passed in at the command-line.
 
 ```
ansible-playbook -i hosts.yml playbook.yml --extra-vars "master_key=$(openssl rand -hex 16) join_key=$(openssl rand -hex 16)"
```