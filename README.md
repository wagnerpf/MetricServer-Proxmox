# MetricServer-Proxmox

Stack completa de monitoramento para **Proxmox VE** usando **Docker**, **InfluxDB** e **Grafana**.

## 📋 Visão Geral

Este projeto fornece uma solução containerizada e reproduzível para monitorar sua infraestrutura Proxmox VE com:

- **InfluxDB 2.x**: Banco de dados time-series para armazenar métricas
- **Grafana**: Plataforma de visualização com dashboards customizados
- **Telegraf**: Agent coletor de métricas do Proxmox
- **Node Exporter**: Coleta de métricas do host Docker

### Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    Proxmox VE                               │
│              (Host a ser monitorado)                        │
└────────────────────────┬────────────────────────────────────┘
                         │ API/SNMP/Prometheus
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Docker Compose (Host Monitor)                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Telegraf    │─→│  InfluxDB    │←─│  Grafana     │     │
│  │              │  │              │  │              │     │
│  │ (Collector)  │  │ (Time-series)│  │ (Dashboard)  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
│  ┌──────────────────┐                                      │
│  │  Node Exporter   │                                      │
│  │   (Host metrics) │                                      │
│  └──────────────────┘                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Pré-requisitos

- **Docker** 20.10+
- **Docker Compose** 1.29+ (ou `docker compose` v2)
- **Proxmox VE 7.0+** (com API habilitada)
- Acesso SSH ao servidor onde você rodará os containers
- Credenciais/Token de API do Proxmox VE

### Instalação Rápida

1. Clone ou crie o diretório do projeto:
```bash
mkdir -p ~/MetricServer-Proxmox
cd ~/MetricServer-Proxmox
```

2. Copie os arquivos do projeto para este diretório

3. Configure suas variáveis de ambiente:
```bash
cp .env.example .env
nano .env
```

4. Execute o script de inicialização:
```bash
bash init.sh
```

5. Acesse os serviços:
   - **Grafana**: http://localhost:3000
   - **InfluxDB**: http://localhost:8086
   - **Node Exporter**: http://localhost:9100/metrics

## 📝 Configuração

### 1. Configurar variáveis de ambiente (`.env`)

```bash
# InfluxDB
INFLUX_ADMIN_USER=admin
INFLUX_ADMIN_PASSWORD=sua_senha_forte

# Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=outra_senha_forte

# Proxmox VE
PROXMOX_HOST=192.168.1.100          # IP do seu Proxmox
PROXMOX_USER=root@pam                # Usuário do Proxmox
PROXMOX_PASSWORD=sua_senha_proxmox   # Senha
PROXMOX_TOKEN=user@pam!tokenid:xxxxx # Token API (preferido)
PROXMOX_SSL_VERIFY=false              # false para labs/dev
```

### 2. Gerar Token de API no Proxmox (Recomendado)

No Proxmox VE:
1. Vá em **Datacenter** → **API Tokens**
2. Clique em **Add** (ou equivalente)
3. Configure:
   - **User**: root@pam (ou seu usuário)
   - **Token ID**: algo como `monitoring-token`
   - **Privíleges**: Selecione acesso mínimo necessário
4. Copie o token gerado e adicione ao `.env`:
   ```
   PROXMOX_TOKEN=root@pam!monitoring-token:xxxxx...
   ```

### 3. Iniciar a Stack

```bash
# Usando docker-compose (v1.x)
docker-compose up -d

# Ou usando docker compose (v2.x)
docker compose up -d
```

Verificar status:
```bash
docker-compose ps
# ou
docker compose ps
```

### 4. Configurar InfluxDB

Acesse http://localhost:8086 e configure a organização/bucket inicial:

```bash
# Via CLI Docker
docker-compose exec influxdb influx bucket create \
  --name proxmox-metrics \
  --org proxmox-org \
  --retention 30d
```

### 5. Configurar Grafana

1. Acesse http://localhost:3000
2. Faça login com credenciais do `.env`
3. Vá em **Configuration** → **Data Sources**
4. A datasource InfluxDB já deve estar configurada (via provisioning)
5. Importe o dashboard: **Dashboards** → **Import** → selecione o arquivo JSON

## 📊 Métricas Coletadas

O Telegraf coleta as seguintes métricas do seu sistema:

| Métrica | Descrição | Intervalo |
|---------|-----------|-----------|
| `cpu` | Uso de CPU (%) | 60s |
| `mem` | Uso de memória (%) | 60s |
| `disk` | Uso de disco (%) | 60s |
| `net` | Tráfego de rede (bytes) | 60s |
| `processes` | Número de processos | 60s |
| `system` | Info do sistema | 60s |
| Proxmox API | Métricas diretas do Proxmox | 60s |

### Exemplo de Query Flux (InfluxDB)

```flux
// Uso de CPU nos últimos 24 horas
from(bucket: "proxmox-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_percent")
  |> mean()
```

## 🛠️ Troubleshooting

### Telegraf não conecta ao Proxmox

```bash
# Verificar logs
docker-compose logs telegraf

# Testar conectividade
docker-compose exec telegraf \
  curl -k https://192.168.1.100:8006/api2/json/version
```

### InfluxDB não recebe dados

```bash
# Verificar buckets
docker-compose exec influxdb influx bucket list

# Verificar tokens
docker-compose exec influxdb influx auth list

# Query para verificar dados
docker-compose exec influxdb influx query 'from(bucket:"proxmox-metrics") |> range(start:-1h)'
```

### Grafana não conecta ao InfluxDB

```bash
# Verificar logs do Grafana
docker-compose logs grafana

# Testar conexão com InfluxDB
docker-compose exec grafana curl -I http://influxdb:8086/health
```

### Resetar tudo e começar do zero

```bash
# Parar containers
docker-compose down

# Remover volumes (ATENÇÃO: deleta dados!)
docker-compose down -v

# Remover imagens
docker-compose down --rmi all

# Reiniciar
bash init.sh
```

## 📚 Comandos Úteis

```bash
# Ver logs em tempo real
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f telegraf
docker-compose logs -f grafana
docker-compose logs -f influxdb

# Executar comandos dentro do container
docker-compose exec telegraf telegraf --version
docker-compose exec influxdb influx --version
docker-compose exec grafana grafana-cli --version

# Parar a stack
docker-compose stop

# Reiniciar a stack
docker-compose restart

# Remover containers
docker-compose down
```

## 🔒 Segurança

### Recomendações

1. **Alterar senhas padrão** no `.env`
2. **Usar HTTPS** em produção (configurar certificados)
3. **Restringir acesso** às portas (firewall)
4. **Rotacionar credenciais** periodicamente
5. **Fazer backup** dos volumes de dados

### Backup

```bash
# Backup do InfluxDB
docker-compose exec influxdb influx backup /backups/influx-$(date +%Y%m%d)

# Backup dos volumes
tar -czf backup-$(date +%Y%m%d).tar.gz \
  data/influxdb \
  data/grafana \
  grafana/provisioning
```

### Restore

```bash
# Restaurar InfluxDB
docker-compose exec influxdb influx restore /backups/influx-YYYYMMDD

# Restaurar volumes
tar -xzf backup-YYYYMMDD.tar.gz
docker-compose up -d
```

## 📖 Documentação Adicional

- [InfluxDB 2.x Docs](https://docs.influxdata.com/influxdb/v2.0/)
- [Grafana Docs](https://grafana.com/docs/grafana/latest/)
- [Telegraf Docs](https://docs.influxdata.com/telegraf/v1.25/)
- [Proxmox VE API](https://pve.proxmox.com/pve-docs/api-viewer/)

## 🤝 Contribuindo

Sugestões de melhorias:
- Dashboard mais avançados
- Suporte a alertas
- Scripts de backup automático
- Integração com mais ferramentas

## 📄 Licença

Este projeto é fornecido como está, para fins educacionais e de laboratório.

## 🆘 Suporte

Para problemas, verifique:
1. Os logs dos containers (`docker-compose logs`)
2. As configurações do `.env`
3. Conectividade com Proxmox VE
4. Permissões de volumes/diretórios

---

**Última atualização**: 2025-11-25
