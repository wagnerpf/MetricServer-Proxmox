# 📦 Arquivos para GitHub - Guia Completo

## ✅ ARQUIVOS QUE DEVEM SER ENVIADOS PARA GITHUB

### 📋 Documentação Principal
| Arquivo | Propósito | Prioridade |
|---------|-----------|-----------|
| `README.md` | Introdução e instruções iniciais | 🔴 Alta |
| `QUICK_START.md` | Início rápido (5 passos) | 🔴 Alta |
| `ARQUITETURA_CORRIGIDA.md` | Explicação da arquitetura | 🟡 Média |
| `PROXMOX_METRIC_SERVER_SETUP.md` | Passo a passo completo | 🟡 Média |
| `RESUMO_EXECUTIVO.md` | Comparação antes/depois | 🟢 Baixa |
| `TROUBLESHOOTING.md` | Resolução de problemas | 🟡 Média |
| `QUERIES.md` | Exemplos de queries Flux | 🟢 Baixa |
| `STATUS.md` | Status/roadmap do projeto | 🟢 Baixa |
| ~~`.github/copilot-instructions.md`~~ | ~~Instruções para Copilot~~ | ❌ **NÃO ENVIAR** |

### 🔧 Arquivos de Configuração
| Arquivo | Propósito | Deve Enviar |
|---------|-----------|------------|
| `docker-compose.yml` | Stack completa | ✅ SIM |
| `.env.example` | Exemplo de variáveis | ✅ SIM (NUNCA .env!) |
| `.gitignore` | O que ignorar do Git | ✅ SIM |

### 🐳 Docker & Provisioning
| Arquivo | Propósito | Deve Enviar |
|---------|-----------|------------|
| `grafana/provisioning/datasources/influxdb.yml` | Datasource do Grafana | ✅ SIM |
| `grafana/provisioning/dashboards/dashboards.yml` | Provisioning de dashboards | ✅ SIM |
| `telegraf.conf` | Configuração Telegraf (opcional) | ✅ SIM |

### 🚀 Scripts
| Arquivo | Propósito | Deve Enviar |
|---------|-----------|------------|
| `init.sh` | Inicialização da stack | ✅ SIM |
| `manage.sh` | Gerenciamento de containers | ✅ SIM |
| `validate-setup.sh` | Validação automática | ✅ SIM |
| `visualizador-arquitetura.sh` | Visualização da arquitetura | ✅ SIM |

---

## ❌ ARQUIVOS QUE NÃO DEVEM SER ENVIADOS

### Arquivos Locais
```
.env                              # Credenciais reais (NUNCA enviar!)
.env.local                        # Env local
.env.*.local                      # Env local específico
```

### Volumes de Dados
```
data/                             # Dados do InfluxDB
backups/                          # Backups de banco
volumes/                          # Volumes Docker
influxdb-data/                    # Dados específicos
grafana-data/                     # Dados específicos
```

### Arquivos Temporários
```
*.log                             # Logs
logs/                             # Diretório de logs
tmp/                              # Temporários
temp/                             # Temporários
*.tmp                             # Cache
*.cache                           # Cache
```

### IDE & Editor
```
.vscode/                          # VS Code
.idea/                            # IntelliJ
*.swp, *.swo                      # Vim
.DS_Store                         # macOS
```

---

## 📄 Estrutura Recomendada para GitHub

```
MetricServer-Proxmox/
├── README.md                              ✅ Enviar
├── QUICK_START.md                         ✅ Enviar
├── ARQUITETURA_CORRIGIDA.md              ✅ Enviar
├── PROXMOX_METRIC_SERVER_SETUP.md        ✅ Enviar
├── RESUMO_EXECUTIVO.md                   ✅ Enviar
├── TROUBLESHOOTING.md                    ✅ Enviar
├── QUERIES.md                            ✅ Enviar
├── STATUS.md                             ✅ Enviar
├── GITHUB_FILES.md                       ✅ Enviar (este arquivo)
├── .env.example                          ✅ Enviar
├── .gitignore                            ✅ Enviar
├── docker-compose.yml                    ✅ Enviar
├── telegraf.conf                         ✅ Enviar
├── init.sh                               ✅ Enviar
├── manage.sh                             ✅ Enviar
├── validate-setup.sh                     ✅ Enviar
├── visualizador-arquitetura.sh           ✅ Enviar
├── .github/                              ❌ Ignorado
│   └── copilot-instructions.md          ❌ NÃO ENVIAR
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── influxdb.yml             ✅ Enviar
│       └── dashboards/
│           └── dashboards.yml           ✅ Enviar
└── data/                                 ❌ NÃO enviar
```

---

## 🚀 Preparando para GitHub

### 1️⃣ Verificar arquivos a enviar
```bash
# Ver arquivos que serão enviados
git status

# Ver arquivos ignorados
git check-ignore -v .env
git check-ignore -v data/
```

### 2️⃣ Adicionar todos os arquivos corretos
```bash
# Adicionar arquivos (respeitando .gitignore)
git add .

# Verificar o que será commitado
git status
```

### 3️⃣ Criar primeiro commit
```bash
git commit -m "Initial commit: Proxmox Metric Server stack with InfluxDB and Grafana"
```

### 4️⃣ Enviar para GitHub
```bash
git branch -M main
git push -u origin main
```

---

## ✨ Checklist Final

- [ ] `.env` **NÃO** foi adicionado ao Git
- [ ] `.env.example` **FOI** adicionado (com valores de exemplo)
- [ ] Diretório `data/` está ignorado
- [ ] Todos os `.md` estão presentes
- [ ] `docker-compose.yml` está presente
- [ ] Scripts têm permissão de execução (`chmod +x *.sh`)
- [ ] `.gitignore` está configurado
- [ ] README.md tem instruções claras
- [ ] Não há credenciais reais em nenhum arquivo

---

## 📝 Exemplo de Commit

```bash
# Primeiro commit
git add .
git commit -m "feat: Add Proxmox Metric Server monitoring stack

- Proxmox native Metric Server integration
- InfluxDB 2.7 for time-series storage
- Grafana 10.2 for visualization
- Automated validation and architecture scripts
- Complete documentation and troubleshooting guide"

git push -u origin main
```

---

## 🔐 Segurança - Importante!

### Nunca Commitar:
```bash
❌ Senhas reais
❌ Tokens de API
❌ Credenciais de qualquer tipo
❌ Dados de produção
❌ Arquivos de log
```

### Sempre Usar:
```bash
✅ .env.example com valores fictícios
✅ Variáveis de ambiente no CI/CD
✅ GitHub Secrets para credenciais
✅ .gitignore atualizado
```

---

## 📚 Arquivos Importantes

**IMPORTANTE**: Se não enviou ainda, certifique-se que estes arquivos existem:

```bash
# Verificar documentação
ls -la *.md

# Verificar scripts
ls -la *.sh

# Verificar configuração
ls -la docker-compose.yml .env.example

# Verificar .github
ls -la .github/
```

