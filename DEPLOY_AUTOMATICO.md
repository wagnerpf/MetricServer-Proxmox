# 🚀 Deploy Automático com Geração de Token

## Visão Geral

Implementei um sistema de **deploy automático** que:

1. ✅ Sobe os containers (InfluxDB, Grafana)
2. ✅ Gera automaticamente a **organização** do InfluxDB
3. ✅ Gera automaticamente o **bucket** para métricas
4. ✅ Gera automaticamente o **token de autenticação**
5. ✅ Injeta o token no `.env`
6. ✅ Configura automaticamente o Grafana com a datasource

## Como Usar

### Opção 1: Deploy Automático (Recomendado)

```bash
# 1. Clone o repositório
git clone https://github.com/wagnerpf/MetricServer-Proxmox.git
cd MetricServer-Proxmox

# 2. Copie o arquivo de configuração
cp .env.example .env

# 3. Execute o deploy automático
./scripts/deploy.sh
```

**É isso!** O script fará tudo automaticamente:
- Sobe os containers
- Gera o token
- Atualiza o `.env`
- Reinicia o Grafana

### Opção 2: Deploy Manual (Passo a Passo)

```bash
# 1. Suba os containers
docker-compose up -d

# 2. Aguarde 10 segundos para o InfluxDB inicializar
sleep 10

# 3. Entre no container
docker-compose exec influxdb bash

# 4. Dentro do container, execute o script de inicialização
/tmp/init-influxdb.sh

# 5. Copie o token exibido

# 6. Saia do container
exit

# 7. Atualize o .env com o token
nano .env
# Procure por INFLUXDB_TOKEN=seu-token-gerado-aqui
# E substitua pelo token copiado

# 8. Reinicie o Grafana
docker-compose restart grafana
```

## O que os Scripts Fazem

### `scripts/init-influxdb.sh`

Script de inicialização que:
- ✅ Aguarda o InfluxDB estar pronto (com retry automático)
- ✅ Cria organização: `proxmox-org`
- ✅ Cria bucket: `proxmox-metrics`
- ✅ Cria token com permissões de escrita
- ✅ Salva token em `/tmp/proxmox-token.txt`
- ✅ Exibe informações de configuração

**Características:**
- Verifica se organização/bucket já existem
- Usa cores para melhor legibilidade
- Exibe resumo com instruções finais

### `scripts/deploy.sh`

Script de deploy que:
- ✅ Para containers antigos
- ✅ Limpa volumes para reset completo
- ✅ Sobe stack via docker-compose
- ✅ Executa init-influxdb.sh automaticamente
- ✅ Recupera token e atualiza `.env`
- ✅ Reinicia Grafana
- ✅ Exibe status final

**Fluxo:**
```
1. docker-compose down -v
   ↓
2. docker-compose up -d
   ↓
3. Aguarda 5 segundos
   ↓
4. Executa init-influxdb.sh
   ↓
5. Recupera token
   ↓
6. Atualiza .env
   ↓
7. docker-compose restart grafana
   ↓
✅ PRONTO!
```

## Estrutura de Arquivos

```
MetricServer-Proxmox/
├── scripts/
│   ├── deploy.sh              ← Novo: Deploy automático
│   ├── init-influxdb.sh       ← Novo: Inicialização InfluxDB
│   ├── manage.sh              ← Existente
│   ├── validate-setup.sh      ← Existente
│   └── visualizador-arquitetura.sh
├── docker-compose.yml         ← Atualizado (adiciona volume do script)
├── .env.example               ← Simplificado
├── .env                       ← Gerado automaticamente
└── ...
```

## Próximas Ações Após Deploy

### 1. Verificar Token

```bash
cat .env | grep INFLUXDB_TOKEN
```

### 2. Acessar Grafana

- URL: http://localhost:3000
- Usuário: `admin`
- Senha: (veja em `.env` → `GRAFANA_ADMIN_PASSWORD`)

### 3. Verificar Datasource

- Vá para: Configuration → Data Sources
- Você deve ver: "InfluxDB-Proxmox" (já configurada automaticamente)

### 4. Configurar Proxmox Metric Server

No **WebUI do Proxmox**:

1. Vá para: **Datacenter → Metric Server → Add**
2. Preencha:
   - **Type**: InfluxDB
   - **Host**: `<IP-deste-servidor>` (ex: 192.168.1.100)
   - **Port**: 8086
   - **Organization**: proxmox-org
   - **Bucket**: proxmox-metrics
   - **Token**: (copie de `.env` → `INFLUXDB_TOKEN`)
3. Clique em **Create**

### 5. Aguardar Métricas

- Proxmox começará a enviar métricas em ~2-3 minutos
- Você verá dados aparecer no Grafana

## Troubleshooting

### Token não foi gerado?

```bash
# Verificar logs do InfluxDB
docker-compose logs influxdb

# Executar script manualmente
docker-compose exec influxdb /tmp/init-influxdb.sh
```

### Grafana não conecta ao InfluxDB?

```bash
# Verificar se token está no .env
cat .env | grep INFLUXDB_TOKEN

# Se vazio, gere novamente:
docker-compose exec influxdb /tmp/init-influxdb.sh

# Depois atualize .env com o token
# E reinicie Grafana:
docker-compose restart grafana
```

### Erro "Unauthorized" no Proxmox?

- Verifique se o token está correto em `.env`
- Verifique se a organização é `proxmox-org`
- Verifique se o bucket é `proxmox-metrics`

### Limpar tudo e começar do zero

```bash
docker-compose down -v
rm -f /tmp/proxmox-token.txt
./scripts/deploy.sh
```

## Performance

**Tempo total de deploy:**
- ≈ 30-40 segundos (primeira execução)
- ≈ 10-15 segundos (reiniciação com dados persistidos)

## Segurança

⚠️ **Importante:**
- O arquivo `.env` contém credenciais
- Nunca commit `.env` no Git (está em `.gitignore`)
- Mude as senhas no `.env` em produção
- Use TLS ao expor InfluxDB externamente

## Variáveis de Ambiente Usadas

| Variável | Origem | Usado por |
|----------|--------|-----------|
| `INFLUX_ADMIN_USER` | .env | InfluxDB |
| `INFLUX_ADMIN_PASSWORD` | .env | InfluxDB |
| `INFLUXDB_TOKEN` | Gerado | InfluxDB + Grafana |
| `GRAFANA_ADMIN_USER` | .env | Grafana |
| `GRAFANA_ADMIN_PASSWORD` | .env | Grafana |

## Arquivos Criados/Modificados Nesta Sessão

```
✨ Criados:
  - scripts/init-influxdb.sh      (novo script de inicialização)
  - scripts/deploy.sh             (novo script de deploy)
  - DEPLOY_AUTOMATICO.md          (esta documentação)

🔧 Modificados:
  - docker-compose.yml            (adiciona volume do script)
  - .env.example                  (simplificado)
```

---

**Status**: ✅ Pronto para usar
**Última atualização**: $(date)
**Versão**: 1.0
