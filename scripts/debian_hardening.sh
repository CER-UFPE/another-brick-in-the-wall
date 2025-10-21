#!/bin/bash
set -e

cat << 'EOF'
 ██████╗███████╗██████╗       ██╗   ██╗███████╗██████╗ ███████╗
██╔════╝██╔════╝██╔══██╗      ██║   ██║██╔════╝██╔══██╗██╔════╝
██║     █████╗  ██████╔╝█████╗██║   ██║█████╗  ██████╔╝█████╗
██║     ██╔══╝  ██╔══██╗╚════╝██║   ██║██╔══╝  ██╔═══╝ ██╔══╝
╚██████╗███████╗██║  ██║      ╚██████╔╝██║     ██║     ███████╗
 ╚═════╝╚══════╝╚═╝  ╚═╝       ╚═════╝ ╚═╝     ╚═╝     ╚══════╝
Hardening Process for Servers in the Debian Family
EOF

# Check if executed via sudo/root
if [ "$EUID" -ne 0 ]; then
    echo "Error: this script must be run with root privileges (use 'sudo')." >&2
    exit 1
fi

if [ -z "${SUDO_USER:-}" ]; then
    echo "Error: the script was not run via 'sudo'. Please run: sudo $0 [options]" >&2
    exit 1
fi

# Update the system
echo "- Updating the system..."
apt update && apt upgrade -y

# install sshd if not present
if ! dpkg -s openssh-server >/dev/null 2>&1; then
    echo "- Instalando OpenSSH server..."
    apt install -y openssh-server
    systemctl enable --now ssh
fi

# Desable root SSH login
echo "- Disabling root SSH login..."
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable X11 forwarding
echo "- Disabling X11 forwarding..."
sed -i 's/#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config

# Disable empty password SSH login
echo "- Disabling empty password SSH login..."
sed -i 's/#PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# Disable TCP forwarding
echo "- Disabling TCP forwarding..."
sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding no/' /etc/ssh/sshd_config

# MaxAuthTries to 3
echo "- Setting MaxAuthTries to 3..."
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config

# Restart sshd to apply changes
systemctl restart sshd

# Enable and start firewalld
echo "- Enabling and starting UFW..."
apt install -y ufw

echo "-- drop all incoming connections except SSH and rate limit SSH..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw limit ssh comment 'Rate limit SSH connections'
ufw enable

# Enable and start fail2ban
echo "- Enabling and starting fail2ban..."
apt install fail2ban -y

# Configure fail2ban for SSH
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOL
[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 30m
EOL

systemctl restart fail2ban

# Set permissions on /etc/passwd and /etc/shadow
echo "- Setting permissions on /etc/passwd and /etc/shadow..."
chmod 644 /etc/passwd
chmod 600 /etc/shadow

# Enable automatic security updates
echo "- Enabling automatic security updates..."
apt install unattended-upgrades -y
dpkg-reconfigure -plow unattended-upgrades

# reload ssh and firewalld to apply all changes
echo "- Reloading sshd and UFW to apply all changes..."
systemctl restart sshd
ufw reload

echo "Hardening process completed successfully."
