# Another Brick in the Wall
## Sobre o Projeto

Este repositório contém scripts automatizados para fortalecer a segurança de servidores Linux e facilitar sua integração em ambientes corporativos. O objetivo principal é fornecer ferramentas práticas e prontas para uso que permitam:

1. **Hardening automatizado** de servidores baseados nas principais distribuições Linux corporativas (Debian/Ubuntu e Rocky Linux/RHEL)
2. **Integração automatizada** com domínios FreeIPA para gerenciamento centralizado de identidades

Os scripts são mantidos pelo CER-UFPE e disponibilizados publicamente para auxiliar administradores de sistemas a implementarem boas práticas de segurança de forma rápida e consistente, reduzindo a complexidade operacional e os riscos associados à configuração manual de ambientes de produção.

# Hardening de servidores Linux
O hardening de servidores Linux é um conjunto de práticas e técnicas de segurança aplicadas para reduzir a superfície de ataque e vulnerabilidades de um sistema operacional. Este processo envolve a configuração adequada de permissões, desabilitação de serviços desnecessários, aplicação de patches de segurança, implementação de firewalls e políticas de acesso restritivo. A importância do hardening reside na proteção contra ameaças cibernéticas cada vez mais sofisticadas, garantindo a integridade, confidencialidade e disponibilidade dos dados e serviços hospedados. Em ambientes corporativos e de produção, o hardening é essencial para estar em conformidade com regulamentações de segurança e para minimizar riscos de invasões, perda de dados e interrupções de serviço.

## Debian/Ubuntu
```bash
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/CER-UFPE/another-brick-in-the-wall/refs/heads/main/scripts/debian_hardening.sh)"
```

## Rocky Linux/RHEL
```bash
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/CER-UFPE/another-brick-in-the-wall/refs/heads/main/scripts/rehl_hardening.sh)"
```

# FreeIPA - Join Domain
Um domínio é uma estrutura lógica de rede que agrupa recursos computacionais como servidores, estações de trabalho e usuários sob uma administração centralizada. Integrar um servidor a um domínio corporativo, como o FreeIPA, permite o gerenciamento centralizado de identidades, autenticação única (SSO), políticas de segurança uniformes e controle de acesso baseado em funções. A importância de estar dentro do domínio está na simplificação da administração de TI, no reforço da segurança através de políticas consistentes, na auditoria centralizada de acessos e na facilitação do cumprimento de normas de conformidade. Além disso, evita a proliferação de credenciais locais dispersas, reduzindo significativamente os riscos de segurança e melhorando a experiência dos usuários com acesso unificado aos recursos da organização.

## Pre-requisitos
Parametros que ter antes de executar o script:
- Domain FQN: Ex: example.com
- FreeIPA Server: Ex: ipa.example.com
- realm: Ex: EXAMPLE.COM
- ipa-adm-pwd: Senha do usuário administrador do FreeIPA

```bash
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/CER-UFPE/another-brick-in-the-wall/refs/heads/main/scripts/join-domain.sh)"
```
