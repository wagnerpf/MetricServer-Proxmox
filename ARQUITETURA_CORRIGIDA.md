# ⚡ Arquitetura Corrigida - Proxmox Metric Server

## 🎯 Mudança Principal

**ANTES (Incorreto):**
- Telegraf rodava no Docker tentando coletar via API Proxmox
- Muita complexidade, autenticação difícil, scraping ineficiente

**AGORA (Correto - Nativo):**
- Proxmox Metric Server (nativo do Proxmox) coleta as métricas automaticamente
- Envia diretamente para InfluxDB via HTTP
- Muito mais simples, eficiente e confiável ✅

## 📊 Nova Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROXMOX VE CLUSTER                          │
│  (pve1, pve2, pve3 / VMs / LXCs)                              │
│                                                                 │
│  ✅ Metric Server nativo (integrado ao Proxmox)               │
│     - Coleta CPU, RAM, Disco, Rede, VMs, LXCs               │
│     - Coleta automaticamente, sem Telegraf                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP(S)
                           │ Envia para InfluxDB
                           ▼
         192.168.1.100:8086 (InfluxDB)
                           │
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
        Proxmox      Grafana       (Opcional)
       Metrics      Dashboards     Telegraf
                                  (host local)
```

## 🚀 Passo a Passo - Implementação Corrigida

### 1️⃣ Iniciar Stack Docker

```bash
cd /home/admviana/Documentos/MetricServer-Proxmox

# Copiar arquivo de configuração
cp .env.example .env

# Editar .env - APENAS credenciais InfluxDB/Grafana necessárias
nano .env

# Variáveis essenciais:
INFLUX_ADMIN_USER=admin
INFLUX_ADMIN_PASSWORD=senhaforte123
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=senhaforte123

# Variáveis Proxmox NÃO SÃO NECESSÁRIAS (deixe em branco ou comente)
# PROXMOX_HOST=
# PROXMOX_USER=
# PROXMOX_PASSWORD=
```

### 2️⃣ Subir InfluxDB

```bash
# Subir apenas InfluxDB
docker-compose up -d influxdb

# Aguardar ~30 segundos
sleep 30

# Verificar status
docker-compose ps
```

### 3️⃣ Criar Bucket InfluxDB

```bash
# Acessar CLI do InfluxDB
docker-compose exec influxdb influx

# Dentro do InfluxDB:
# Criar bucket (30 dias de retenção)
> influx bucket create -n proxmox-metrics -o proxmox-org -d 30d

# Gerar token para Proxmox usar
> influx auth create \
  --org proxmox-org \
  --read-buckets proxmox-metrics \
  --write-buckets proxmox-metrics

# ⚠️ COPIE O TOKEN GERADO - usaremos no Proxmox

# Sair
> exit
```

### 4️⃣ Configurar Proxmox Metric Server

#### Acesso WebUI Proxmox:
```
https://seu-proxmox-ip:8006
Login: root@pam
Password: sua-senha
```

#### Navegar para Metric Server:
```
Menu esquerdo
  ↓
Datacenter
  ↓
Metric Server
```

#### Clicar em "Add" → "InfluxDB"

Preencher os campos:

| Campo | Valor |
|-------|-------|
| **Hostname/IP** | `192.168.1.100` ou IP do host Docker |
| **Port** | `8086` |
| **Organization** | `proxmox-org` |
| **Bucket** | `proxmox-metrics` |
| **Token** | (Cole o token gerado no passo 3) |
| **Protocol** | `http` (ou `https` se usar SSL) |
| **Timeout** | `1` |
| **Max Body Size** | `25000000` |

#### Clicar "Create"

✅ **Pronto!** Proxmox começará a enviar métricas automaticamente.

### 5️⃣ Verificar Métricas no InfluxDB

```bash
# Dentro do container InfluxDB
docker-compose exec influxdb influx query \
  'from(bucket:"proxmox-metrics") |> range(start:-1h)' \
  --org proxmox-org

# Ou acesse a WebUI:
# http://localhost:8086
# Username: admin
# Password: (a que você configurou)
```

### 6️⃣ Subir Grafana

```bash
# Subir Grafana
docker-compose up -d grafana

# Aguardar ~10 segundos
sleep 10

# Acessar em: http://localhost:3000
# Admin: admin / (sua senha)
```

### 7️⃣ Criar Dashboard no Grafana

Exemplos de queries Flux para Proxmox:

**CPU de Nós (últimas 24h):**
```flux
from(bucket: "proxmox-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "node")
  |> filter(fn: (r) => r._field == "cpu")
  |> group(by: ["host"])
  |> mean()
```

**Memória (últimas 7 dias):**
```flux
from(bucket: "proxmox-metrics")
  |> range(start: -7d)
  |> filter(fn: (r) => r._measurement == "memory")
  |> filter(fn: (r) => r._field == "used")
  |> mean()
```

**Todos os nós disponíveis:**
```flux
from(bucket: "proxmox-metrics")
  |> range(start: -1h)
  |> group(by: ["host"])
  |> last()
```

## 📈 Métricas Coletadas Automaticamente pelo Proxmox

### Por Nó (Node):
- ✅ CPU (% uso)
- ✅ Memória (MB, %)
- ✅ Disco (GB, %)
- ✅ Uptime (segundos)
- ✅ Load average
- ✅ Transações (tx/rx)

### Por VM/LXC:
- ✅ CPU (cores usados, %)
- ✅ Memória (MB usada)
- ✅ Disco I/O (bytes)
- ✅ Network (bytes in/out)
- ✅ Status (running/stopped)

### Cluster:
- ✅ Estado dos nós
- ✅ Quorum status
- ✅ Replicas (se Ceph)

## 🔐 Configuração de Segurança (Produção)

### 1. Use HTTPS entre Proxmox ↔ InfluxDB

No Proxmox Metric Server, se usar SSL:
```
Protocol: https
Verify Certificate: true (ative verificação)
```

### 2. Firewall - Restringir Acesso

```bash
# No host Docker
sudo ufw allow from 192.168.1.0/24 to any port 8086
sudo ufw deny from any to any port 8086
```

### 3. Alterar Senhas Padrão

```bash
# .env file
INFLUX_ADMIN_PASSWORD=SenhaComplexa123!@#
GRAFANA_ADMIN_PASSWORD=OutraSenhaForte456!@#
```

### 4. Tokens com Permissões Mínimas

No InfluxDB, o token para Proxmox deve ter:
- ✅ **Permissão**: Escrita (write)
- ✅ **Bucket**: Apenas `proxmox-metrics`
- ✅ **Organização**: `proxmox-org`

## 🐛 Troubleshooting

### ❌ Métricas não chegam ao InfluxDB?

**1. Verificar conectividade Proxmox → InfluxDB**
```bash
# No nó Proxmox
ping 192.168.1.100
curl -v http://192.168.1.100:8086/health
```

**2. Verificar logs do Proxmox**
```bash
# No nó Proxmox
journalctl -u pvestatd -f
tail -f /var/log/syslog | grep metric
```

**3. Verificar logs InfluxDB**
```bash
docker-compose logs -f influxdb
```

**4. Testar token manualmente**
```bash
curl -H "Authorization: Token seu-token-aqui" \
  http://localhost:8086/api/v2/orgs
```

### ❌ Grafana não mostra dados?

**1. Verificar datasource**
```
Grafana → Connections → Data sources → InfluxDB-Proxmox
Clicar em "Test"
```

**2. Verificar query Flux**
- Usar Editor visual primeiro
- Depois testar Flux no InfluxDB UI

**3. Verificar labels/tags disponíveis**
```bash
docker-compose exec influxdb influx query \
  'from(bucket:"proxmox-metrics") |> keys() |> unique()'
```

### ❌ InfluxDB demora para iniciar?

```bash
# Aumentar tempo de espera
sleep 60
docker-compose ps

# Ou acompanhar logs
docker-compose logs -f influxdb
```

## 📚 Referências Importantes

1. **Documentação Oficial Proxmox Metric Server**
   - https://pve.proxmox.com/pve-docs-8/pve-admin-guide.html#external_metric_server

2. **InfluxDB v2 Docs**
   - https://docs.influxdata.com/influxdb/v2/

3. **Flux Query Language**
   - https://docs.influxdata.com/flux/latest/

4. **Grafana + InfluxDB**
   - https://grafana.com/docs/grafana/latest/datasources/influxdb/

## ✅ Checklist de Implementação

- [ ] Docker Compose iniciado
- [ ] InfluxDB bucket criado
- [ ] Token InfluxDB gerado
- [ ] Proxmox Metric Server configurado
- [ ] Métricas chegando no InfluxDB (verificar com query)
- [ ] Grafana iniciado
- [ ] Datasource InfluxDB testado no Grafana
- [ ] Dashboard criado com queries Flux
- [ ] Verificação de segurança (firewall, senhas, HTTPS)
- [ ] Backup configurado (opcional)

## 🎉 Resultado Final

Você terá uma stack de monitoramento completa e profissional:

```
✅ Métricas do Proxmox coletadas automaticamente
✅ Dados armazenados em time-series database (InfluxDB)
✅ Visualização profissional (Grafana)
✅ Histórico de 30 dias (configurável)
✅ Totalmente containerizado
✅ Fácil backup e restauração
✅ Pronto para produção
```

**Proxmox Metric Server com InfluxDB e Grafana = Solução Perfeita!** 🚀
