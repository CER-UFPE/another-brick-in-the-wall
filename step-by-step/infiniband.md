# Configuração da Infiniband após formatação e instalação do Proxmox VE
A Infiniband (IB) é uma tecnologia de interconexão de alta performance desenvolvida para fornecer baixa latência e alta largura de banda na comunicação entre servidores, storages e nós de clusters.
Ela é amplamente utilizada em ambientes de computação de alto desempenho (HPC), data centers e infraestruturas virtualizadas, como o Proxmox VE, permitindo que múltiplos nós troquem dados de forma extremamente rápida e eficiente.

## **Passo 1 — Atualizar o sistema e instalar as bibliotecas necessárias**

```bash
apt update
apt install infiniband-diags ibutils rdmacm-utils libmlx4-1 libmlx5-1 libibverbs1 ibverbs-utils
```
## Passo 2 — Verificar se a interface da Infiniband foi criada
```bash
ibv_devinfo
ip a
```
## Passo 3 - Carregue o módulo IPoIB:
```bash
modprobe ib_ipoib
```
## Passo 4 — Criar a interface no Proxmox para configurar a Infiniband
```bash
nano /etc/network/interfaces
```
### Adicione a interface ibp5s0:
Alterar o "x"
```bash
auto ibpxs0
iface ibpxs0 inet static
    address 192.168.1.x/24
    mtu 65507
    pre-up echo connected > /sys/class/net/ibpxs0/mode
```
Para salvar e sair:
```bash
CTRL + O
CTRL + X
```

## Passo 5 - Aplicar as alterações:
Alterar o "x"
```bash
ifdown ibpxs0 && ifup ibpxs0
```

## Passo 6 - Carregar modulos automaticamente:
Esse comando carrega automaticamente os modulos depois do reboot:
```bash
echo "mlx4_ib" >> /etc/modules
echo "ib_ipoib"   >> /etc/modules
```

## Passo 7 — Testar a comunicação:
Alterar o "x":
```bash
ping 192.168.1.x
```

## Passo 8 — Adicionar o nó configurado no host:
Alterar o "x"
```bash
192.168.1.x coiotex.cer.ufpe.br coiotex
```

