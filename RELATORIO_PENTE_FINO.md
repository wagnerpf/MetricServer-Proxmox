# 🔍 Relatório de Pente Fino - Conformidade com Proxmox Metric Server

## ⚠️ PROBLEMAS ENCONTRADOS

### 1. ❌ `docker-compose.yml` - Container Telegraf ainda com credenciais Proxmox

**Linhas 30-45:**
```yaml
telegraf:
  environment:
    PROXMOX_HOST: ${PROXMOX_HOST:-192.168.1.100}
    PROXMOX_USER: ${PROXMOX_USER:-root@pam}
    PROXMOX_PASSWORD: ${PROXMOX_PASSWORD:-sua_senha_proxmox}
```

**Problema:** Telegraf não deve coletar do Proxmox via API!

**Solução:**
- ❌ Remover container Telegraf da stack **OU**
- ✅ Reconfigurar Telegraf para coletar **APENAS** métricas do host Docker (CPU, RAM, disco local)

---

### 2. ❌ `telegraf.conf` - Configuração com Proxmox API

**Linhas 37-39:**
```properties
[[inputs.prometheus]]
  urls = ["http://${PROXMOX_HOST}:8007/api2/json/nodes"]
  [inputs.prometheus.headers]
    Authorization = "PVEAPIToken=${PROXMOX_TOKEN}"
```

**Problema:** Tenta coletar do Proxmox via API (ERRADO!)

**Solução:** Remover todas as entradas de Proxmox, manter apenas:
- ✅ System metrics (CPU, RAM, Disco)
- ✅ Network metrics
- ✅ Disk I/O

---

### 3. ⚠️ Documentação com referências confusas

**Arquivos afetados:**
- `ARQUITETURA_CORRIGIDA.md` - Menciona Telegraf como "errado"
- `RESUMO_EXECUTIVO.md` - Comparação Telegraf vs Metric Server
- `MUDANCAS_IMPLEMENTADAS.md` - Referências ao Telegraf antigo
- `STATUS.md` - Lista Telegraf como componente
- `init.sh` - Instruções sobre Telegraf/Proxmox
- `manage.sh` - Gerenciamento do container Telegraf
- `visualizador-arquitetura.sh` - Mostra Telegraf na arquitetura

---

## 🎯 DECISÃO NECESSÁRIA

### Opção A: Remover Telegraf completamente
```
✅ Mais simples
✅ Alinha com a premissa (Proxmox envia tudo natively)
❌ Perde métricas adicionais do host Docker
```

**Stack final:**
```
Proxmox VE (Metric Server nativo)
    ↓ HTTP
InfluxDB (armazena)
    ↓ Flux queries
Grafana (visualiza)
```

---

### Opção B: Manter Telegraf apenas para host Docker
```
✅ Coleta métricas adicionais (CPU, RAM, Disco do Docker host)
✅ Não tenta acessar Proxmox
❌ Adiciona um componente não essencial
```

**Stack final:**
```
┌─ Proxmox VE (Metric Server nativo)
│       ↓ HTTP
├─ InfluxDB (armazena)
├─ Telegraf (APENAS métricas locais)
│       ↓ HTTP
└─ Grafana (visualiza)
```

---

## 📋 RECOMENDAÇÃO

**Opção A é melhor!** Razões:

1. ✅ Proxmox VE envia **TODOS** os dados que precisa (CPU, RAM, Disco, VMs, LXCs)
2. ✅ Telegraf para Proxmox API é desnecessário e complicado
3. ✅ Simplifica o projeto e a documentação
4. ✅ Reduz dependências
5. ✅ Alinha 100% com a premissa do projeto

**Impacto:**
- ❌ Remover: `telegraf.conf`, serviço Telegraf no docker-compose
- ✅ Manter: InfluxDB, Grafana, Proxmox Metric Server
- ✅ Atualizar: Documentação, scripts, diagramas

---

## ✅ ARQUIVOS PARA CORRIGIR

| Arquivo | Ação | Prioridade |
|---------|------|-----------|
| `docker-compose.yml` | Remove Telegraf | 🔴 Alta |
| `telegraf.conf` | Delete ou reescrever | 🔴 Alta |
| `ARQUITETURA_CORRIGIDA.md` | Remover refs Telegraf | 🟡 Média |
| `RESUMO_EXECUTIVO.md` | Simplificar comparação | 🟡 Média |
| `MUDANCAS_IMPLEMENTADAS.md` | Atualizar status | 🟡 Média |
| `STATUS.md` | Remover Telegraf da lista | 🟡 Média |
| `init.sh` | Remover instruções Telegraf | 🟡 Média |
| `manage.sh` | Remover gerenciamento Telegraf | 🟡 Média |
| `visualizador-arquitetura.sh` | Atualizar diagrama | 🟡 Média |
| `GITHUB_FILES.md` | Remover telegraf.conf | 🟢 Baixa |
| `QUICK_START.md` | Verificar referências | 🟢 Baixa |
| `README.md` | Verificar referências | 🟢 Baixa |
| `TROUBLESHOOTING.md` | Remover troubleshoot Telegraf | 🟢 Baixa |
| `QUERIES.md` | Verificar referências | 🟢 Baixa |

---

## 🚀 PRÓXIMOS PASSOS

1. ✅ Confirmar: Remover Telegraf completamente?
2. Corrigir `docker-compose.yml`
3. Remover/reescrever `telegraf.conf`
4. Atualizar toda documentação
5. Testar stack com Proxmox Metric Server real
6. Commit final: "refactor: Remove Telegraf, use only Proxmox native Metric Server"

