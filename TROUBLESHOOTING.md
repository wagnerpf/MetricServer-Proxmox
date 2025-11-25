# Troubleshooting - MetricServer-Proxmox

## Problemas Comuns e Soluções

### 1. Telegraf não conecta ao Proxmox

**Sintomas**: Telegraf reinicia continuamente ou logs mostram erro de conexão

**Verificar**:
```bash
# 1. Verificar conectividade SSH
ping 192.168.1.100

# 2. Verificar se Proxmox API está respondendo
curl -k https://192.168.1.100:8006/api2/json/version

# 3. Verificar credenciais
docker-compose logs telegraf | grep -i "auth\|error\|denied"
```

**Soluções**:
- Verificar se `PROXMOX_HOST` no `.env` está correto
- Verificar se `PROXMOX_USER` e `PROXMOX_PASSWORD` estão corretos
- Se usando token, verificar se o token é válido (não expirou)
- Verificar firewall entre o host Docker e Proxmox

---

### 2. InfluxDB não inicia ou demora muito

**Sintomas**: Container de InfluxDB fica em restart contínuo

**Verificar**:
```bash
# Ver logs detalhados
docker-compose logs influxdb

# Verificar espaço em disco
df -h

# Verificar permissões
ls -la data/influxdb
```

**Soluções**:
```bash
# Se arquivo corrompido, remover e recriar
docker-compose down
rm -rf data/influxdb
docker-compose up -d influxdb
```

---

### 3. Grafana mostra "Data source error"

**Sintomas**: Grafana não consegue conectar ao InfluxDB

**Verificar**:
```bash
# Testar conectividade
docker-compose exec grafana curl http://influxdb:8086/health

# Ver logs do Grafana
docker-compose logs grafana | grep -i "datasource\|influx"
```

**Soluções**:
```bash
# Regenerar token InfluxDB
docker-compose exec influxdb influx auth create \
  --org proxmox-org \
  --description "Grafana Token"

# Atualizar token no Grafana:
# 1. Entre no Grafana (http://localhost:3000)
# 2. Configuration > Data Sources > InfluxDB
# 3. Atualize o token
```

---

### 4. Sem dados em nenhum gráfico

**Sintomas**: Grafana mostra "No data in response"

**Verificar**:
```bash
# Verificar se dados estão chegando ao InfluxDB
docker-compose exec influxdb influx query \
  --org proxmox-org \
  'from(bucket:"proxmox-metrics") |> range(start:-1h) |> limit(n:10)'

# Verificar logs do Telegraf
docker-compose logs telegraf
```

**Soluções**:
```bash
# 1. Verificar configuração do telegraf
docker-compose exec telegraf telegraf --config /etc/telegraf/telegraf.conf --test

# 2. Forçar coleta de métricas
docker-compose restart telegraf

# 3. Aguardar alguns minutos (primeira coleta leva tempo)
```

---

### 5. Porta já em uso

**Erro**: "bind: address already in use"

**Soluções**:
```bash
# Verificar quem está usando a porta
sudo lsof -i :3000   # Grafana
sudo lsof -i :8086   # InfluxDB
sudo lsof -i :9100   # Node Exporter

# Opção 1: Parar o serviço que ocupa a porta
# Opção 2: Mudar a porta no docker-compose.yml
# Opção 3: Usar outra máquina/VM
```

---

### 6. Containers ficam em "Exited"

**Sintomas**: Alguns containers não ficam rodando

**Verificar**:
```bash
# Ver status detalhado
docker-compose ps

# Ver últimos logs
docker-compose logs --tail=50
```

**Soluções**:
```bash
# Reiniciar o container
docker-compose restart [service]

# Ou reiniciar tudo
docker-compose down
docker-compose up -d
```

---

### 7. InfluxDB consome muita memória

**Sintomas**: Sistema desacelerado, OOM kill

**Soluções**:
```bash
# Limitar memória no docker-compose.yml
# Adicione em cada serviço:
deploy:
  resources:
    limits:
      memory: 1G
    reservations:
      memory: 512M

# Após editar, recriar:
docker-compose up -d
```

---

### 8. Métricas do Proxmox não aparecem

**Sintomas**: Apenas métricas locais chegam, nenhuma do Proxmox

**Verificar**:
```bash
# Testar conectividade direta ao Proxmox
docker-compose exec telegraf \
  curl -k -H "Authorization: PVEAPIToken=user@pam!token-id:token-value" \
  https://192.168.1.100:8006/api2/json/nodes
```

**Soluções**:
1. Verificar se token/credenciais estão corretos
2. Verificar permissões do token no Proxmox
3. Verificar configuração do `telegraf.conf`
4. Testar com `curl` direto

---

### 9. Backup muito grande

**Sintomas**: Backup ocupa mais espaço que esperado

**Solução**:
```bash
# Limpar dados antigos do InfluxDB
docker-compose exec influxdb influx bucket update \
  --name proxmox-metrics \
  --retention 7d  # Manter apenas 7 dias de dados

# Forçar compactação
docker-compose exec influxdb influx compact
```

---

### 10. Reset completo (Última Opção)

**ATENÇÃO**: Isto DELETA todos os dados!

```bash
# Parar tudo
docker-compose down

# Remover TUDO
docker-compose down -v --remove-orphans
docker volume prune -f
docker image prune -a -f

# Recomeçar
rm -rf data/
cp .env.example .env
nano .env  # Configure novamente

# Iniciar
bash init.sh
```

---

## Checklist de Troubleshooting

- [ ] Docker está rodando? `docker ps`
- [ ] Arquivo `.env` existe e está configurado? `cat .env`
- [ ] Proxmox está acessível? `ping PROXMOX_HOST`
- [ ] Credenciais do Proxmox estão corretas?
- [ ] Firewall permite conexão?
- [ ] Espaço em disco disponível? `df -h`
- [ ] Logs de erro? `docker-compose logs`
- [ ] Portas estão livres? `sudo lsof -i :3000`

---

## Logs Úteis

```bash
# Ver todos os logs
docker-compose logs

# Ver logs recentes (últimas 50 linhas)
docker-compose logs --tail=50

# Ver logs em tempo real
docker-compose logs -f

# Logs de um serviço específico
docker-compose logs telegraf
docker-compose logs grafana
docker-compose logs influxdb

# Logs com timestamp
docker-compose logs --timestamps
```

---

## Informações Técnicas

### Portas Padrão
- Grafana: 3000
- InfluxDB: 8086
- Node Exporter: 9100

### Diretórios de Dados
- InfluxDB: `data/influxdb/`
- Grafana: `data/grafana/`

### Configurações
- Telegraf: `telegraf.conf`
- Environment: `.env`
- Provisioning: `grafana/provisioning/`

---

## Contactar Suporte

Se o problema persistir:
1. Coletar todos os logs: `docker-compose logs > logs.txt`
2. Incluir saída de: `docker-compose ps`
3. Incluir conteúdo do `.env` (sem senhas!)
4. Descrever exatamente o que não funciona
