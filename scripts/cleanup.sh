#!/usr/bin/env bash -eux

# Apt cleanup.
apt -y autoremove
apt autoclean
apt clean

# Fix permissions owned by root
chown -R vagrant.vagrant /home/vagrant
