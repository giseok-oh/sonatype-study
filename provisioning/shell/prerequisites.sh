echo "===== Upgrade packages ====="
sudo dnf upgrade -y

echo "===== Install Python3 ====="
sudo dnf install -y python312

echo "===== Install development tools ====="
sudo dnf groupinstall -y "Development Tools"