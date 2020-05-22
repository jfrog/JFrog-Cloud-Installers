#!/usr/bin/env bash

ansible-playbook -i hosts.yml playbook.yml --extra-vars "master_key=$(openssl rand -hex 16) join_key=$(openssl rand -hex 16)"