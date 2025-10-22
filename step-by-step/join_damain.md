# FreeIPA
Um domínio é uma estrutura lógica de rede que agrupa recursos computacionais como servidores, estações de trabalho e usuários sob uma administração centralizada. Integrar um servidor a um domínio corporativo, como o FreeIPA, permite o gerenciamento centralizado de identidades, autenticação única (SSO), políticas de segurança uniformes e controle de acesso baseado em funções. A importância de estar dentro do domínio está na simplificação da administração de TI, no reforço da segurança através de políticas consistentes, na auditoria centralizada de acessos e na facilitação do cumprimento de normas de conformidade. Além disso, evita a proliferação de credenciais locais dispersas, reduzindo significativamente os riscos de segurança e melhorando a experiência dos usuários com acesso unificado aos recursos da organização.

## Join Domain Script
Script para juntar servidores Linux ao domínio FreeIPA de forma automatizada.
### Pre-requisitos
Parametros que ter antes de executar o script:
- **Domain FQDN**: Ex: example.com
- **FreeIPA Server**: Ex: ipa.example.com
- **Realm**: Ex: EXAMPLE.COM
- **IPA Admin Password**: Senha do usuário administrador do FreeIPA

```bash
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/CER-UFPE/another-brick-in-the-wall/refs/heads/main/scripts/join-domain.sh)"
```

## Instalação do FreeIPA Server
Caso queira instalar o FreeIPA Server, siga os passos abaixo:
> CONTEXTO: Esses passos são para configurar um servidor FreeIPA do zero, ajustando hostname, firewall, dependências e instalando o FreeIPA Server com DNS subordinado. Já que já existe um servidor DNS principal, este servidor atuará como um servidor subordinado no novo domínio.

### Configurações Iniciais
```bash
# Ajustar hostname e hosts
sudo hostnamectl set-hostname iam.cer.ufpr.br
echo "150.161.56.119  iam.cer.ufpe.br iam" | sudo tee -a /etc/hosts
# Verificar resolução de nome
hostname -f ping -c 3 iam.cer.ufpe.br

# Sincronizar hora
sudo timedatectl set-timezone America/Sao_Paulo

# Configurar firewall
sudo firewall-cmd --add-service={http,https,dns,ntp,freeipa-ldap,freeipa-ldaps,kerberos} --permanent sudo firewall-cmd --reload sudo firewall-cmd --list-all

# Instalar dependências
sudo dnf install freeipa-server freeipa-server-dns freeipa-client -y

# Configurar NTP
# Mudar o parametro OPTIONS="-x"
sudo nano /etc/sysconfig/chronyd

# Instalar e configurar FreeIPA Server
# Siga as instruções do prompt: (Até que...)
# - Responda "no" para reverse zones.
# - No prompt de NTP, responda "yes" e
#   adicione pools (ex.: 0.rocky.pool.ntp.org,1.rocky.pool.ntp.org).
sudo ipa-server-install --setup-dns
```
