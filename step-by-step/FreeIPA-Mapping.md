# FreeIPA-Compatible UID/GID Mapping for Proxmox LXC Unprivileged CTs

Containers LXC unprivileged utilizam user namespaces, o que significa que os UIDs/GIDs internos não correspondem diretamente aos UIDs/GIDs reais do host.
Por padrão, o Proxmox só mapeia 65536 IDs, o que funciona para usuários locais, mas não suporta ambientes como FreeIPA, onde os usuários possuem UIDs/GIDs muito altos (ex: 212800000+). 

Para permitir que CTs unprivileged usem UIDs/GIDs altos, é necessário estender o range de IDs permitidos no host.

Em todos os nós adicione em: 

```bash 
nano /etc/subuid 
nano /etc/subgid 
``` 
Substitua a linha por:

```bash
root:100000:500000000 
```
Aplique as atualizações:

```bash
systemctl restart lxc
```

## Configure cada CT unprivileged No Arquivo de configuração de CT (Por favor rode no nó Proxmox não dentro do CT): 

```bash
pct stop <ID>
```

```bash 
nano /etc/pve/lxc/<CTID>.conf
```

Adicione: 

```bash
# mapping padrão do Proxmox
lxc.idmap = u 0 100000 65536
lxc.idmap = g 0 100000 65536
# mapping estendido para FreeIPA
lxc.idmap = u 65536 200000 500000000
lxc.idmap = g 65536 200000 500000000
```
```bash
pct start <ID>
```

Esse mapeamento permite que o CT utilize UIDs/GIDs altos provenientes do FreeIPA, mantendo toda a segurança do modo unprivileged, sem precisar tornar o CT privilegiado.
