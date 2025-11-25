# Configuração do Proxmox Metric Server com InfluxDB

## 🎯 Arquitetura Correta

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROXMOX VE CLUSTER                          │
│  (Nós: pve1, pve2, pve3 / VMs / LXCs)                          │
│                                                                 │
│  ✅ Métrica Server nativo do Proxmox                           │
│     (coleta automaticamente todas as métricas)                 │
└──────────────────────────┬──────────────────────────────────────┘
                           │ (HTTP/HTTPS)
                           │ Envia métricas periodicamente
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DOCKER COMPOSE STACK                         │
│                (outro servidor ou VM)                          │
│                                                                 │
│  ┌──────────────┐                                              │
│  │  InfluxDB    │◄─────────── Recebe métricas do Proxmox      │
│  │  (porta 8086)│                                              │
│  └──────────────┘                                              │
│         ▲                                                       │
│         │ (Flux Queries)                                       │
│         ▼                                                       │
│  ┌──────────────┐                                              │
│  │   Grafana    │──────────► Visualiza dados                  │
│  │  (porta 3000)│                                              │
│  └──────────────┘                                              │
│                                                                 │
│  ┌──────────────┐ (Opcional - métricas do host Docker)        │
│  │   Telegraf   │                                              │
│  │  (coletor)   │                                              │
│  └──────────────┘                                              │
│                                                                 │
│  ┌──────────────────────────┐ (Opcional - métricas de SO)     │
│  │  Node Exporter (porta 9100)                                │
│  └──────────────────────────┘                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Passo 1: Configurar InfluxDB para Receber Métricas do Proxmox

### 1.1 - Iniciar a Stack Docker

```bash
cd /home/admviana/Documentos/MetricServer-Proxmox

# Copiar e editar o arquivo de configuração
cp .env.example .env
nano .env

# Preencher apenas as credenciais do InfluxDB e Grafana (não precisa de Proxmox aqui)
INFLUX_ADMIN_USER=admin
INFLUX_ADMIN_PASSWORD=senhaforte123
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=senhaforte123
```

### 1.2 - Iniciar InfluxDB

```bash
docker-compose up -d influxdb

# Aguardar inicialização (~30 segundos)
sleep 30

# Verificar se está rodando
docker-compose ps
```

### 1.3 - Criar Database/Bucket para Proxmox

```bash
# Acessar o container InfluxDB
docker-compose exec influxdb influx

# Dentro do InfluxDB CLI, criar o bucket (se não existir)
influx bucket create -n proxmox-metrics -o proxmox-org -d 30d

# Gerar token de escrita
influx auth create \
  --org proxmox-org \
  --read-buckets proxmox-metrics \
  --write-buckets proxmox-metrics

# Copie o token (você usará no Proxmox)
```

## 🔧 Passo 2: Configurar Proxmox Metric Server

### 2.1 - Acessar WebUI do Proxmox

1. Abra o navegador: `https://seu-proxmox-ip:8006`
2. Faça login como root@pam

### 2.2 - Navegar até Metric Server

```
Datacenter
  ↓
Metric Server (lado esquerdo)
```

### 2.3 - Criar Nova Configuração InfluxDB

**Clique em "Create"** e selecione **"InfluxDB plugin"**

Preencha os campos:

```
Hostname/IP: 192.168.1.100  (IP do servidor onde está o Docker)
ou se estiver na mesma rede: docker-host.local ou IP específico

Port: 8086
Organization: proxmox-org
Bucket: proxmox-metrics
Token: <cole-o-token-gerado-acima>
Protocol: http ou https (dependendo da sua configuração)
Timeout: 1
Max Body Size: 25000000 (padrão)
```

### 2.4 - Testar a Conexão

Após criar, o Proxmox começará a enviar métricas automaticamente para InfluxDB.

**Para verificar se as métricas estão chegando:**

```bash
# Dentro do container InfluxDB
docker-compose exec influxdb influx query \
  'from(bucket:"proxmox-metrics") |> range(start:-1h)' \
  --org proxmox-org

# Ou use a interface web do InfluxDB:
# http://localhost:8086
# user: admin
# senha: a que você configurou
```

## 🎨 Passo 3: Configurar Grafana

### 3.1 - Acessar Grafana

```
http://localhost:3000
user: admin
password: (a que você configurou)
```

### 3.2 - Verificar Datasource InfluxDB

A datasource já deve estar pré-configurada. Para verificar:

```
Connections
  ↓
Data sources
  ↓
InfluxDB-Proxmox
```

Se não estiver, crie manualmente:
- **Type**: InfluxDB
- **Query Language**: Flux
- **URL**: http://influxdb:8086
- **Auth**: Token
- **Token**: (copie do InfluxDB)
- **Organization**: proxmox-org
- **Default Bucket**: proxmox-metrics

### 3.3 - Importar ou Criar Dashboards

Exemplo de query Flux para CPU de nós Proxmox:

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "node")
  |> filter(fn: (r) => r._field == "cpu")
  |> group(by: ["host"])
  |> mean()
```

## 📊 Métricas Disponíveis do Proxmox

O Proxmox Metric Server envia automaticamente:

### Por Nó (Node):
- CPU (%)
- Memória (MB, %)
- Disco (GB, %)
- Uptime
- Load average
- Network (bytes in/out)

### Por VM/LXC:
- CPU (%)
- Memória (MB)
- Disco I/O (bytes)
- Network (bytes)
- Status (running/stopped)

### Pela Cluster:
- Estado dos nós
- Quorum
- Réplicas (se Ceph)

## 🔐 Segurança

### Para Ambientes de Produção:

1. **Use HTTPS** entre Proxmox e InfluxDB:
   ```
   Protocol: https
   No SSL Verify: false (ativar verificação)
   ```

2. **Senhas Fortes**: Altere credenciais padrão

3. **Firewall**: Restrinja acesso ao InfluxDB apenas do Proxmox

4. **Tokens**: Use tokens com permissões mínimas (apenas escrita no bucket)

## 🐛 Troubleshooting

### Métricas não chegam ao InfluxDB?

1. Verifique conectividade:
   ```bash
   ping <ip-do-docker-host>
   curl -v http://<ip>:8086/health
   ```

2. Verifique logs do Proxmox:
   ```bash
   # No nó Proxmox
   journalctl -u pvestatd -f
   ```

3. Verifique logs do InfluxDB:
   ```bash
   docker-compose logs -f influxdb
   ```

### Dashboards vazios?

1. Confirme que há dados no InfluxDB:
   ```bash
   docker-compose exec influxdb influx query \
     'from(bucket:"proxmox-metrics") |> range(start:-30d) |> limit(n:10)'
   ```

2. Verifique labels/tags das métricas:
   ```bash
   docker-compose exec influxdb influx query \
     'from(bucket:"proxmox-metrics") |> keys() |> unique()' \
     -o proxmox-org
   ```

## 📚 Referências

- [Documentação Proxmox Metric Server](https://pve.proxmox.com/pve-docs-8/pve-admin-guide.html#external_metric_server)
- [InfluxDB v2 Documentation](https://docs.influxdata.com/influxdb/v2/)
- [Grafana + InfluxDB](https://grafana.com/docs/grafana/latest/datasources/influxdb/)
