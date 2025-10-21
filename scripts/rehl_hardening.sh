#!/bin/bash
set -e

cat << 'EOF'
 ██████╗███████╗██████╗       ██╗   ██╗███████╗██████╗ ███████╗
██╔════╝██╔════╝██╔══██╗      ██║   ██║██╔════╝██╔══██╗██╔════╝
██║     █████╗  ██████╔╝█████╗██║   ██║█████╗  ██████╔╝█████╗
██║     ██╔══╝  ██╔══██╗╚════╝██║   ██║██╔══╝  ██╔═══╝ ██╔══╝
╚██████╗███████╗██║  ██║      ╚██████╔╝██║     ██║     ███████╗
 ╚═════╝╚══════╝╚═╝  ╚═╝       ╚═════╝ ╚═╝     ╚═╝     ╚══════╝
Hardening Process for Servers in the RHEL Family
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

# Args/flags:
#   --join-domain            Habilita o join no FreeIPA
#   --domain <DOMAIN>        Ex: example.com
#   --server <SERVER>        Ex: ipa.example.com
#   --realm <REALM>          Ex: EXAMPLE.COM
#   -h|--help                Ajuda
usage() {
  echo "Usage: sudo $0 [--join-domain]"
  exit 1
}

JOIN_DOMAIN=0
DOMAIN="cer.ufpe.br"
SERVER="150.161.56.119" # iam.cer.ufpe.br
REALM="CER.UFPE.BR"

while [[ $# -gt 0 ]]; do
  case $1 in
    --join-domain)
      JOIN_DOMAIN=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Update the system
echo "- Updating the system..."
dnf update -y

# install sshd if not present
if ! rpm -q openssh-server &>/dev/null; then
    echo "- Installing OpenSSH server..."
    dnf install -y openssh-server
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
echo "- Enabling and starting firewalld..."
dnf install -y firewalld
systemctl enable --now firewalld

echo "-- drop all incoming connections except SSH and rate limit SSH..."
firewall-cmd --set-default-zone=drop
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" service name="ssh" limit value="3/m" accept'
firewall-cmd --reload

# Enable and start fail2ban
echo "- Enabling and starting fail2ban..."
dnf install epel-release -y
dnf install fail2ban -y

# Configure fail2ban for SSH
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOL
[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 30m
EOL

systemctl enable --now fail2ban

# Set permissions on /etc/passwd and /etc/shadow
echo "- Setting permissions on /etc/passwd and /etc/shadow..."
chmod 644 /etc/passwd
chmod 600 /etc/shadow

# Enable automatic security updates
echo "- Enabling automatic security updates..."
dnf install -y dnf-automatic
systemctl enable --now dnf-automatic.timer
# Configure dnf-automatic for security updates only
sudo tee /etc/dnf/automatic.conf > /dev/null <<EOL
[commands]
apply_updates = yes
upgrade_type = security
EOL

# reload ssh and firewalld to apply all changes
echo "- Reloading sshd and firewalld to apply all changes..."
systemctl reload sshd
firewall-cmd --reload

# Join FreeIPA domain if flag is set
if [[ "$JOIN_DOMAIN" -eq 1 ]]; then
    if [[ -z "$DOMAIN" || -z "$SERVER" || -z "$REALM" ]]; then
        echo "Error: --join-domain requires --domain, --server and --realm." >&2
        usage
    fi
    echo "- Installing IPA client..."
    dnf install -y ipa-client
    echo "- Joining FreeIPA domain $DOMAIN..."
    ipa-client-install --domain="$DOMAIN" --server="$SERVER" --realm="$REALM" --mkhomedir --force-join -U
    echo "- FreeIPA join completed."
else
    echo "- Skipping FreeIPA domain join. Use --join-domain with --domain/--server/--realm to enable."
fi

echo "Hardening process completed successfully."