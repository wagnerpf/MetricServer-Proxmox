#!/bin/bash

################################################################################
# Script de Inicialização Automática do InfluxDB para Proxmox Metric Server
# Este script é executado automaticamente quando o container InfluxDB inicia
# Cria: organização, bucket e token para o Proxmox Metric Server
################################################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
ORG_NAME="proxmox-org"
BUCKET_NAME="proxmox-metrics"
RETENTION="30d"
TOKEN_FILE="/tmp/proxmox-token.txt"
INFLUX_CLI="/usr/local/bin/influx"
MAX_RETRIES=30
RETRY_INTERVAL=2

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  InfluxDB Inicialização Automática${NC}"
echo -e "${BLUE}========================================${NC}"

# Função para esperar o InfluxDB estar pronto
wait_for_influxdb() {
    echo -e "${YELLOW}⏳ Aguardando InfluxDB ficar pronto...${NC}"
    
    local count=0
    while [ $count -lt $MAX_RETRIES ]; do
        if curl -sf http://localhost:8086/health > /dev/null 2>&1; then
            echo -e "${GREEN}✓ InfluxDB está pronto!${NC}"
            return 0
        fi
        
        count=$((count + 1))
        echo -e "${YELLOW}  Tentativa $count/$MAX_RETRIES...${NC}"
        sleep $RETRY_INTERVAL
    done
    
    echo -e "${RED}✗ InfluxDB não respondeu após $MAX_RETRIES tentativas${NC}"
    return 1
}

# Função para criar organização
create_org() {
    echo -e "${BLUE}📋 Criando organização: $ORG_NAME${NC}"
    
    if $INFLUX_CLI org list | grep -q "$ORG_NAME"; then
        echo -e "${YELLOW}  ℹ Organização já existe${NC}"
        return 0
    fi
    
    if $INFLUX_CLI org create -n "$ORG_NAME"; then
        echo -e "${GREEN}✓ Organização criada com sucesso${NC}"
        return 0
    else
        echo -e "${RED}✗ Erro ao criar organização${NC}"
        return 1
    fi
}

# Função para criar bucket
create_bucket() {
    echo -e "${BLUE}🪣 Criando bucket: $BUCKET_NAME${NC}"
    
    if $INFLUX_CLI bucket list -o "$ORG_NAME" | grep -q "$BUCKET_NAME"; then
        echo -e "${YELLOW}  ℹ Bucket já existe${NC}"
        return 0
    fi
    
    if $INFLUX_CLI bucket create -n "$BUCKET_NAME" -o "$ORG_NAME" -d "$RETENTION"; then
        echo -e "${GREEN}✓ Bucket criado com sucesso (Retenção: $RETENTION)${NC}"
        return 0
    else
        echo -e "${RED}✗ Erro ao criar bucket${NC}"
        return 1
    fi
}

# Função para criar token
create_token() {
    echo -e "${BLUE}🔑 Gerando token de autenticação${NC}"
    
    # Verificar se já existe um token com este nome
    TOKEN_NAME="proxmox-token-$(date +%s)"
    
    TOKEN_OUTPUT=$($INFLUX_CLI auth create \
        --org "$ORG_NAME" \
        --write-buckets "$BUCKET_NAME" \
        --description "Token para Proxmox Metric Server" \
        --json 2>&1)
    
    if [ $? -eq 0 ]; then
        # Extrair token do JSON output
        TOKEN=$(echo "$TOKEN_OUTPUT" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
        
        if [ -n "$TOKEN" ]; then
            # Salvar token em arquivo
            echo "$TOKEN" > "$TOKEN_FILE"
            chmod 600 "$TOKEN_FILE"
            
            echo -e "${GREEN}✓ Token criado com sucesso${NC}"
            echo -e "${GREEN}  Token salvo em: $TOKEN_FILE${NC}"
            return 0
        else
            echo -e "${RED}✗ Erro ao extrair token${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Erro ao criar token${NC}"
        echo -e "${RED}  Detalhes: $TOKEN_OUTPUT${NC}"
        return 1
    fi
}

# Função para exibir resumo
show_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}  ✅ Inicialização Concluída com Sucesso${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}📊 Configuração do InfluxDB:${NC}"
    echo -e "  • Organização:  ${GREEN}$ORG_NAME${NC}"
    echo -e "  • Bucket:       ${GREEN}$BUCKET_NAME${NC}"
    echo -e "  • Retenção:     ${GREEN}$RETENTION${NC}"
    echo ""
    
    if [ -f "$TOKEN_FILE" ]; then
        TOKEN=$(cat "$TOKEN_FILE")
        echo -e "${YELLOW}🔑 Token de Autenticação:${NC}"
        echo -e "  ${GREEN}${TOKEN:0:20}...${TOKEN: -20}${NC}"
        echo ""
        echo -e "${YELLOW}📝 Para usar no Proxmox WebUI:${NC}"
        echo -e "  1. Datacenter > Metric Server > Add"
        echo -e "  2. Tipo: InfluxDB"
        echo -e "  3. Host: <IP-deste-servidor>"
        echo -e "  4. Port: 8086"
        echo -e "  5. Organization: ${GREEN}$ORG_NAME${NC}"
        echo -e "  6. Bucket: ${GREEN}$BUCKET_NAME${NC}"
        echo -e "  7. Token:"
        echo -e "     ${GREEN}$TOKEN${NC}"
        echo ""
        echo -e "${BLUE}========================================${NC}"
    fi
}

# Função para exibir erro e sair
error_exit() {
    echo -e "${RED}✗ Inicialização falhou${NC}"
    exit 1
}

# =============================================================================
# MAIN - Executar sequência de inicialização
# =============================================================================

echo ""

# Aguardar InfluxDB estar pronto
wait_for_influxdb || error_exit

# Criar organização
create_org || error_exit

# Criar bucket
create_bucket || error_exit

# Criar token
create_token || error_exit

# Exibir resumo
show_summary

echo -e "${GREEN}✓ Script de inicialização concluído!${NC}"
echo ""
