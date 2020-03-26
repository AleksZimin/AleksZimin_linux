#!/bin/bash

# Update CentOS
yum clean all
yum update -y

echo "Update CentOS done. Rebooting"

# Reboot VM
shutdown -r now
