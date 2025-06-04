#/bin/bash

# Setting sudoers
sudo -i
echo "vagrant ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/vagrant

# Setting SSH
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Change User
exit

# Copy Pubilc Keys
HOST_PUBLIC_KEY_FILE="$HOME/.ssh/id_rsa.pub"
VM_USER="vagrant"

TARGET_IPS=$1

if [ -f "$HOST_PUBLIC_KEY_FILE" ]; then
    sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no -p "22" "$VM_USER@$VM_IP"
fi