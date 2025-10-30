#!/bin/bash
set -e

cat << 'EOF'
 ░▒▓██████▓▒░░▒▓████████▓▒░▒▓███████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓███████▓▒░░▒▓████████▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░
░▒▓█▓▒░      ░▒▓██████▓▒░ ░▒▓███████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░ ░▒▓███████▓▒░░▒▓██████▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓██▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░
 ░▒▓██████▓▒░░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██▓▒░░▒▓██████▓▒░░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓████████▓▒░
==================================================================================================
Join Domain Script - FreeIPA

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
#   --domain <DOMAIN>        Ex: example.com
#   --server <SERVER>        Ex: ipa.example.com
#   --realm <REALM>          Ex: EXAMPLE.COM
#   --ipa-adm-pwd <PASSWORD> Ex: SecretPassword123
#   -h|--help                Ajuda
usage() {
  echo "Usage: sudo $0 [--domain <DOMAIN>] [--server <SERVER>] [--realm <REALM>] [--ipa-adm-pwd <PASSWORD>]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --domain)
      DOMAIN="$2"
      shift 2
      ;;
    --server)
      SERVER="$2"
      shift 2
      ;;
    --realm)
      REALM="$2"
      shift 2
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

DOMAIN=""
SERVER="" # iam.cer.ufpe.br
REALM=""
IPA_ADM_PWD=""

while [ -z "${DOMAIN:-}" ]; do
    read -r -p "- Enter the domain (e.g., example.com): " DOMAIN
    DOMAIN=$(printf '%s' "$DOMAIN" | tr '[:upper:]' '[:lower:]' | xargs)
    if [ -z "$DOMAIN" ]; then
        echo "Error: domain cannot be empty." >&2
    fi
done

while [ -z "${SERVER:-}" ]; do
    read -r -p "- Enter the server (e.g., ipa.example.com): " SERVER
    SERVER=$(printf '%s' "$SERVER" | tr '[:upper:]' '[:lower:]' | xargs)
    if [ -z "$SERVER" ]; then
        echo "Error: server cannot be empty." >&2
    fi
done

while [ -z "${REALM:-}" ]; do
    read -r -p "- Enter the realm (e.g., EXAMPLE.COM): " REALM
    REALM=$(printf '%s' "$REALM" | tr '[:lower:]' '[:upper:]' | xargs)
    if [ -z "$REALM" ]; then
        echo "Error: realm cannot be empty." >&2
    fi
done

while [ -z "${IPA_ADM_PWD:-}" ]; do
    read -r -s -p "- Enter the IPA admin password: " IPA_ADM_PWD
    echo
    if [ -z "$IPA_ADM_PWD" ]; then
        echo "Error: IPA admin password cannot be empty." >&2
    fi
done

# print all information collected and ask for confirmation
echo " "
echo "--------------------------------------------------------------"
echo "!! REVIEW INFORMATION CAREFULLY BEFORE PROCEEDING !!"
echo "--------------------------------------------------------------"
echo "The following information has been collected:"
echo "- Domain: $DOMAIN"
echo "- Server: $SERVER"
echo "- Realm: $REALM"
echo "- IPA Admin Password: [HIDDEN]"
echo "--------------------------------------------------------------"
read -r -p "Is this information CORRECT? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborting. Please run the script again to provide the correct information."
    exit 1
fi

# Join the domain using realm command
if [[ -z "$DOMAIN" || -z "$SERVER" || -z "$REALM" ]]; then
    echo "Error: --join-domain requires --domain, --server and --realm." >&2
    usage
fi

echo "1. Installing IPA client..."

if command -v dnf &> /dev/null; then
    # RHEL/CentOS/Fedora
    dnf install -y ipa-client
elif command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    apt-get update
    apt-get install -y freeipa-client
else
    echo "Error: Unsupported distribution. Neither dnf nor apt-get found." >&2
    exit 1
fi

# Check if RHEL and update chronyd configuration
if command -v dnf &> /dev/null; then
  echo "- Updating chronyd configuration..."
  sed -i 's/^OPTIONS=.*/OPTIONS="-x"/' /etc/sysconfig/chronyd
  systemctl restart chronyd
  echo "- chronyd configuration updated."
fi

echo "2. Joining FreeIPA domain $DOMAIN..."
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
