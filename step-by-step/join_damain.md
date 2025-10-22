# FreeIPA - Join Domain
Um domínio é uma estrutura lógica de rede que agrupa recursos computacionais como servidores, estações de trabalho e usuários sob uma administração centralizada. Integrar um servidor a um domínio corporativo, como o FreeIPA, permite o gerenciamento centralizado de identidades, autenticação única (SSO), políticas de segurança uniformes e controle de acesso baseado em funções. A importância de estar dentro do domínio está na simplificação da administração de TI, no reforço da segurança através de políticas consistentes, na auditoria centralizada de acessos e na facilitação do cumprimento de normas de conformidade. Além disso, evita a proliferação de credenciais locais dispersas, reduzindo significativamente os riscos de segurança e melhorando a experiência dos usuários com acesso unificado aos recursos da organização.

## Pre-requisitos
Parametros que ter antes de executar o script:
- **Domain FQDN**: Ex: example.com
- **FreeIPA Server**: Ex: ipa.example.com
- **Realm**: Ex: EXAMPLE.COM
- **IPA Admin Password**: Senha do usuário administrador do FreeIPA

```bash
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/CER-UFPE/another-brick-in-the-wall/refs/heads/main/scripts/join-domain.sh)"
```
