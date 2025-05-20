#/bin/bash

# Setting sudoers
sudo -i
sudo echo "vagrant ALL=NOPASSWD: ALL" >> /etc/sudoers

# Setting SSH
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
sudo systemctl restart ssh

# Change User
exit

# Copy Pubilc Keys
HOST_PUBLIC_KEY_FILE="$HOME/.ssh/id_rsa.pub"
VM_USER="vagrant"

TARGET_IPS=("192.168.56.10", "192.168.56.11")

if [ -f "$HOST_PUBLIC_KEY_FILE" ]; then
    for VM_IP in "${TARGET_IPS[@]}"; do
        sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no -p "22" "$VM_USER@$VM_IP"
    done
fi