#!/usr/bin/env bash -eux

# Script for covering non-ansible steps

echo "Running setup.sh"

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

echo "Installing VirtualBox guest additions"

apt-get install -y linux-headers-$(uname -r) build-essential perl
apt-get install -y dkms

mount -o loop /home/${SSH_USER}/VBoxGuestAdditions.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -rf /home/${SSH_USER}/VBoxGuestAdditions.iso
