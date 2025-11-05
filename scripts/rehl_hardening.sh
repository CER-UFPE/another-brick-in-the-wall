#!/bin/bash
set -e

cat << 'EOF'
 ██████╗███████╗██████╗       ██╗   ██╗███████╗██████╗ ███████╗
██╔════╝██╔════╝██╔══██╗      ██║   ██║██╔════╝██╔══██╗██╔════╝
██║     █████╗  ██████╔╝█████╗██║   ██║█████╗  ██████╔╝█████╗
██║     ██╔══╝  ██╔══██╗╚════╝██║   ██║██╔══╝  ██╔═══╝ ██╔══╝
╚██████╗███████╗██║  ██║      ╚██████╔╝██║     ██║     ███████╗
 ╚═════╝╚══════╝╚═╝  ╚═╝       ╚═════╝ ╚═╝     ╚═╝     ╚══════╝
 Hardening Process for Rocky Linux 9
EOF

# Verifica se está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo "Error: este script deve ser executado com root (sudo)." >&2
    exit 1
fi

# Atualiza o sistema
echo "- Atualizando o sistema..."
dnf update -y

# Instala e configura SSH
echo "- Instalando e configurando OpenSSH server..."
dnf install -y openssh-server
systemctl enable --now sshd

# Configurações de segurança SSH
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding no/' /etc/ssh/sshd_config
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
systemctl restart sshd

# Habilita firewall
echo "- Instalando e configurando firewalld..."
dnf install -y firewalld
systemctl enable --now firewalld
firewall-cmd --set-default-zone=drop
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" service name="ssh" limit value="3/m" accept'
firewall-cmd --reload

# Habilita fail2ban
echo "- Instalando e configurando fail2ban..."
dnf install -y epel-release
dnf install -y fail2ban
cat >/etc/fail2ban/jail.local <<EOL
[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 30m
EOL
systemctl enable --now fail2ban

# Permissões seguras para arquivos sensíveis
chmod 644 /etc/passwd
chmod 600 /etc/shadow

# Atualizações automáticas de segurança
echo "- Configurando atualizações automáticas..."
dnf install -y dnf-automatic
systemctl enable --now dnf-automatic.timer
cat >/etc/dnf/automatic.conf <<EOL
[commands]
apply_updates = yes
upgrade_type = security
EOL

# --- Bloco de correção Rocky 9 para FreeIPA/SSSD ---
echo "- Corrigindo compatibilidade Rocky 9 (oddjob/SSSD/PAM)..."
dnf install -y oddjob oddjob-mkhomedir
systemctl enable --now oddjobd || echo "⚠️ oddjobd não iniciou — verifique keyctl/nesting no Proxmox"

# Ajusta permissões do sssd.conf caso exista
if [ -f /etc/sssd/sssd.conf ]; then
    chmod 600 /etc/sssd/sssd.conf
fi

# Ajusta PAM para criar home automaticamente
if ! grep -q "pam_oddjob_mkhomedir.so" /etc/pam.d/system-auth; then
    sed -i '/^session.*required.*pam_limits.so/a session    required    pam_oddjob_mkhomedir.so umask=0077' /etc/pam.d/system-auth
fi

# Reinicia serviços críticos
systemctl restart sshd
firewall-cmd --reload

echo "✅ Hardening completo!"
