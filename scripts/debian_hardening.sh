#!/bin/bash
set -e

# ----------------------------------------------
# Default values for domain join
# ----------------------------------------------
JOIN_DOMAIN=0
DOMAIN="cer.ufpe.br"
SERVER="iam.cer.ufpe.br" # 150.161.56.119
REALM="CER.UFPE.BR"
# ----------------------------------------------


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

# Args/flags:
#   --join-domain            Habilita o join no FreeIPA
#   -h|--help                Ajuda
usage() {
  echo "Usage: sudo $0 [--join-domain]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --join-domain)
      JOIN_DOMAIN=1
      shift
      ;;
    --ipa-adm-pwd)
      IPA_ADM_PWD="$2"
      shift 2
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
apt update && apt upgrade -y

# install sshd if not present
if ! dpkg -s openssh-server >/dev/null 2>&1; then
    echo "- Instalando OpenSSH server..."
    apt-get install -y openssh-server
    # Opcional: habilitar e iniciar o serviço imediatamente
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
# deny all incoming by default, allow all outgoing
ufw default deny incoming
ufw default allow outgoing
# Permitir HTTP, HTTPS e SSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw limit ssh comment 'Rate limit SSH connections'

# activate UFW
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
apt install unattended-upgrades -y
dpkg-reconfigure -plow unattended-upgrades

# reload ssh and firewalld to apply all changes
echo "- Reloading sshd and firewalld to apply all changes..."
systemctl restart sshd
ufw reload

# Join FreeIPA domain if flag is set
if [[ "$JOIN_DOMAIN" -eq 1 ]]; then
    if [[ -z "$DOMAIN" || -z "$SERVER" || -z "$REALM" || -z "$IPA_ADM_PWD" ]]; then
        echo "Error: --join-domain requires --ipa-adm-pwd." >&2
        usage
    fi
    echo "- Installing IPA client..."
    apt install freeipa-client -y
    echo "- Joining FreeIPA domain $DOMAIN..."
    ipa-client-install \
	  --domain="$DOMAIN" \
	  --server="$SERVER" \
	  --realm="$REALM" \
	  --mkhomedir \
	  --force-join \
	  --principal=admin \
	  --password="$IPA_ADM_PWD" \
	  --unattended
    echo "- FreeIPA join completed."
else
    echo "- Skipping FreeIPA domain join. Use --join-domain with --domain/--server/--realm to enable."
fi

echo "Hardening process completed successfully."

