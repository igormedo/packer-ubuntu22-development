#!/usr/bin/env bash -ex

# Update system
apt-get -y update
apt-get -y upgrade

# Install Ansible.
apt-get -y install python3-pip
python3 -m pip install ansible

[[ ! -f /usr/bin/ansible ]] && ln -s /usr/local/bin/ansible* /usr/bin/ || true
