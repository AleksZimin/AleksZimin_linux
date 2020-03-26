#!/bin/bash

# Install bzip2
sudo yum -y install bzip2
# Install vbox guest additions
sudo mkdir - p /mnt/iso
sudo mount -o loop ${TEMP_FOLDER}/VBoxGuestAdditions*.iso /mnt/iso
cd /mnt/iso
sudo ./VBoxLinuxAdditions.run


echo "###   Hi from second stage of kernel build" >> /boot/grub2/grub.cfg
