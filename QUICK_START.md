# 🚀 Guia de Inicialização Rápida

## Estrutura do Projeto

```
MetricServer-Proxmox/
├── .github/
│   └── copilot-instructions.md     # Instruções para agentes IA
├── grafana/
│   └── provisioning/
│       ├── dashboards/
│       │   ├── dashboards.yml
│       │   └── proxmox-dashboard.json
│       └── datasources/
│           └── influxdb.yml
├── data/                            # VOLUMES (não no git)
│   ├── influxdb/
│   └── grafana/
├── docker-compose.yml               # Configuração dos containers
├── telegraf.conf                    # Configuração do coletor de métricas
├── .env.example                     # Template de variáveis
├── .env                             # ARQUIVO REAL (ignore no git)
├── .gitignore                       # Padrões a ignorar no git
├── init.sh                          # Script de inicialização
├── manage.sh                        # Script de gerenciamento
├── README.md                        # Documentação completa
├── TROUBLESHOOTING.md               # Guia de troubleshooting
├── QUERIES.md                       # Exemplos de queries Flux
└── QUICK_START.md                   # Este arquivo
```

---

## ⚡ Início Rápido (5 minutos)

### Pré-requisitos Mínimos
- ✅ Docker instalado
- ✅ Docker Compose instalado
- ✅ Conectividade com Proxmox VE
- ✅ Credenciais/Token do Proxmox

### Passo 1: Clonar/Copiar Projeto
```bash
cd ~/DocumentsMetricServer-Proxmox
# Ou clonar de um repositório git
```

### Passo 2: Configurar Environment
```bash
cp .env.example .env
nano .env  # ou use seu editor favorito
```

**Variáveis essenciais a preencher:**
```bash
PROXMOX_HOST=<seu_ip_ou_host>
PROXMOX_USER=root@pam  # ou seu usuário
PROXMOX_PASSWORD=<sua_senha>
# OU usar token (recomendado):
PROXMOX_TOKEN=user@pam!token-id:token-value
```

### Passo 3: Iniciar
```bash
bash init.sh
# Ou manualmente:
docker-compose up -d
```

### Passo 4: Acessar
- **Grafana**: http://localhost:3000 (admin / senha do .env)
- **InfluxDB**: http://localhost:8086 (admin / senha do .env)

---

## 📋 Checklist de Configuração

- [ ] Docker está instalado? `docker --version`
- [ ] Docker Compose está instalado? `docker-compose --version`
- [ ] IP/hostname do Proxmox está correto no `.env`
- [ ] Credenciais do Proxmox estão corretas
- [ ] Token do Proxmox é válido (não expirou)
- [ ] Firewall permite conexão 8006 (Proxmox) ← host Docker
- [ ] Porta 3000 (Grafana) está livre?
- [ ] Porta 8086 (InfluxDB) está livre?
- [ ] Espaço em disco disponível? (`df -h`)
- [ ] Arquivo `.env` foi criado e preenchido?

---

## 🎯 Usar o Script de Gerenciamento

Após criar o projeto, use `manage.sh` para operações:

```bash
# Iniciar
./manage.sh start

# Parar
./manage.sh stop

# Ver status
./manage.sh status

# Ver logs
./manage.sh logs
./manage.sh logs telegraf  # logs específicos

# Abrir shell no container
./manage.sh shell grafana

# Fazer backup
./manage.sh backup

# Restaurar backup
./manage.sh restore backups/backup-20231125-153022.tar.gz

# Verificar saúde
./manage.sh health

# Ajuda
./manage.sh help
```

---

## 🔧 Solução Rápida de Problemas

### Container não inicia
```bash
docker-compose logs --tail=20 [service-name]
docker-compose restart [service-name]
```

### Sem dados em Grafana
```bash
# Verificar se Telegraf coleta dados
docker-compose exec telegraf telegraf --config /etc/telegraf/telegraf.conf --test

# Verificar se dados chegam ao InfluxDB
docker-compose exec influxdb influx query \
  --org proxmox-org \
  'from(bucket:"proxmox-metrics") |> range(start:-1h) |> limit(n:5)'
```

### Grafana não conecta ao InfluxDB
```bash
# Verificar conectividade
docker-compose exec grafana curl http://influxdb:8086/health

# Regenerar token
docker-compose exec influxdb influx auth create \
  --org proxmox-org \
  --description "Grafana"
```

### Proxmox API não responde
```bash
# Testar do host
curl -k https://PROXMOX_HOST:8006/api2/json/version

# Testar do container
docker-compose exec telegraf curl -k https://PROXMOX_HOST:8006/api2/json/version
```

---

## 📊 Arquitetura Resumida

```
                    ┌─────────────────────────┐
                    │    PROXMOX VE (7.x)     │
                    │  (seu hypervisor)       │
                    └────────────┬────────────┘
                                 │ API/SNMP
                                 ↓
        ┌────────────────────────────────────────────────┐
        │         Docker Compose Stack                    │
        │                                                 │
        │  ┌──────────────────────────────────────────┐  │
        │  │  Telegraf (1 min)                        │  │
        │  │  - Coleta métricas do Proxmox          │  │
        │  │  - Coleta do host local                │  │
        │  └──────────────┬──────────────────────────┘  │
        │                 │                               │
        │                 ↓                               │
        │  ┌──────────────────────────────────────────┐  │
        │  │  InfluxDB 2.x (porto 8086)              │  │
        │  │  - Armazena séries temporais            │  │
        │  │  - Retenção: 30 dias (configurável)     │  │
        │  └──────────────┬──────────────────────────┘  │
        │                 │                               │
        │                 ↓                               │
        │  ┌──────────────────────────────────────────┐  │
        │  │  Grafana (porto 3000)                    │  │
        │  │  - Dashboards bonitos                   │  │
        │  │  - Alertas (opcional)                   │  │
        │  │  - Relatórios                           │  │
        │  └──────────────────────────────────────────┘  │
        │                                                 │
        └────────────────────────────────────────────────┘
```

---

## 🔐 Segurança - O Mínimo

1. **Altere TODAS as senhas** no `.env`
2. **Use um Token de API** em vez de senha de root
3. **Limitar acesso às portas** com firewall
4. **Use HTTPS/TLS** em produção
5. **Fazer backups regularmente** (`./manage.sh backup`)

---

## 📈 Próximos Passos Após Setup

1. **Criar mais dashboards** personalizados
2. **Configurar alertas** no Grafana
3. **Ajustar retenção de dados** no InfluxDB
4. **Backup automatizado** via cron
5. **Monitorar mais hosts** Proxmox
6. **Adicionar mais exporters** (Prometheus, etc)

---

## 🆘 Suporte Rápido

| Problema | Comando |
|----------|---------|
| Ver logs | `docker-compose logs -f` |
| Status | `docker-compose ps` |
| Reiniciar tudo | `docker-compose restart` |
| Parar tudo | `docker-compose down` |
| Reset total | `docker-compose down -v` |
| Bash em container | `docker-compose exec grafana /bin/sh` |

---

## 📚 Documentação Completa

- 📖 **README.md** - Documentação detalhada
- 🐛 **TROUBLESHOOTING.md** - Soluções de problemas
- 📊 **QUERIES.md** - Exemplos de queries Flux
- 🤖 **.github/copilot-instructions.md** - Instruções para IA

---

## ✨ Sugestões Úteis

```bash
# Adicione ao seu ~/.bashrc ou ~/.zshrc para atalhos:
alias ms-start="cd ~/MetricServer-Proxmox && ./manage.sh start"
alias ms-stop="cd ~/MetricServer-Proxmox && ./manage.sh stop"
alias ms-logs="cd ~/MetricServer-Proxmox && docker-compose logs -f"
alias ms-status="cd ~/MetricServer-Proxmox && ./manage.sh status"
```

---

**Criado**: 2025-11-25  
**Versão**: 1.0  
**Status**: Pronto para uso ✅
