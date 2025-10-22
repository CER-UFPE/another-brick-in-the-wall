
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
