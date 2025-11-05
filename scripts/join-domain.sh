#!/bin/bash
set -e

cat <<"EOF"
# ██████╗███████╗██████╗       ██╗   ██╗███████╗██████╗ ███████╗
# ██╔════╝██╔════╝██╔══██╗      ██║   ██║██╔════╝██╔══██╗██╔════╝
# ██║     █████╗  ██████╔╝█████╗██║   ██║█████╗  ██████╔╝█████╗
# ██║     ██╔══╝  ██╔══██╗╚════╝██║   ██║██╔══╝  ██╔═══╝ ██╔══╝
# ╚██████╗███████╗██║  ██║      ╚██████╔╝██║     ██║     ███████╗
#  ╚═════╝╚══════╝╚═╝  ╚═╝       ╚═════╝ ╚═╝     ╚═╝     ╚══════╝
# Script de Join FreeIPA - Rocky Linux 9 (LXC compatível)
EOF

# ----------------------------
# CONFIGURAÇÕES MANUAIS
# ----------------------------
read -p "Digite o hostname completo (ex: node01.cer.ufpe.br): " HOSTNAME_FULL
read -p "Digite o domínio (ex: cer.ufpe.br): " DOMINIO
read -p "Digite o servidor FreeIPA (ex: ipa.cer.ufpe.br): " SERVIDOR_IPA

# Realm derivado do domínio (maiúsculo)
REALM=$(echo "$DOMINIO" | tr '[:lower:]' '[:upper:]')

# Coleta credenciais FreeIPA
read -p "Digite o usuário admin do FreeIPA: " USUARIO_ADMIN
read -s -p "Digite a senha do usuário '$USUARIO_ADMIN': " SENHA_ADMIN
echo ""

# ----------------------------
# INSTALAR DEPENDÊNCIAS
# ----------------------------
echo "==> Instalando cliente FreeIPA e dependências..."
dnf install -y freeipa-client krb5-workstation sssd oddjob oddjob-mkhomedir chrony

# Inicia e habilita oddjobd
systemctl enable --now oddjobd

# Habilita sssd
systemctl enable --now sssd

# Configura hostname
echo "==> Configurando hostname..."
hostnamectl set-hostname "$HOSTNAME_FULL"

# Remove instalação antiga do cliente FreeIPA, se existir
ipa-client-install --uninstall -U || true

# ----------------------------
# INGRESSO NO DOMÍNIO
# ----------------------------
echo "==> Ingressando no FreeIPA..."

# Usa --no-ntp para evitar erro de chronyd dentro do container
if ! echo "$SENHA_ADMIN" | ipa-client-install \
    --hostname="$HOSTNAME_FULL" \
    --mkhomedir \
    --enable-dns-updates \
    --domain="$DOMINIO" \
    --server="$SERVIDOR_IPA" \
    --principal="$USUARIO_ADMIN" \
    --password="$SENHA_ADMIN" \
    --unattended \
    --no-ntp; then
    echo "❌ Falha ao ingressar no FreeIPA. Verifique /var/log/ipaclient-install.log"
    exit 1
fi

# ----------------------------
# CONFIRMAÇÃO
# ----------------------------
echo ""
echo "✅ Máquina $HOSTNAME_FULL ingressou no FreeIPA com sucesso!"
