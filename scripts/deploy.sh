#!/bin/bash

################################################################################
# Script para Subir o Stack com Geração Automática de Token
# Uso: ./scripts/deploy.sh
################################################################################

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( dirname "$SCRIPT_DIR" )"
ENV_FILE="$PROJECT_DIR/.env"
TOKEN_FILE="/tmp/proxmox-token.txt"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Deploy Automático - Stack Proxmox + InfluxDB + Grafana${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se .env existe
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}✗ Arquivo .env não encontrado!${NC}"
    echo -e "${YELLOW}  Execute primeiro: cp .env.example .env${NC}"
    exit 1
fi

echo -e "${YELLOW}1️⃣  Parando containers existentes...${NC}"
cd "$PROJECT_DIR"
docker-compose down 2>/dev/null || true
echo -e "${GREEN}✓ Done${NC}"
echo ""

echo -e "${YELLOW}2️⃣  Limpando volumes antigos...${NC}"
docker-compose down -v 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Done${NC}"
echo ""

echo -e "${YELLOW}3️⃣  Subindo containers...${NC}"
docker-compose up -d
echo -e "${GREEN}✓ Done${NC}"
echo ""

echo -e "${YELLOW}4️⃣  Aguardando inicialização dos containers...${NC}"
sleep 5
echo -e "${GREEN}✓ Done${NC}"
echo ""

echo -e "${YELLOW}5️⃣  Entrando no container InfluxDB para gerar token...${NC}"
sleep 2

# Executar script de inicialização dentro do container
docker-compose exec -T influxdb bash /tmp/init-influxdb.sh

echo ""
echo -e "${YELLOW}6️⃣  Atualizando variáveis de ambiente com token gerado...${NC}"

# Recuperar o token do arquivo temporário
if [ -f "$TOKEN_FILE" ]; then
    TOKEN=$(cat "$TOKEN_FILE")
    
    # Atualizar .env com o token gerado
    if grep -q "^INFLUXDB_TOKEN=" "$ENV_FILE"; then
        # Substituir token existente
        sed -i "s/^INFLUXDB_TOKEN=.*/INFLUXDB_TOKEN=$TOKEN/" "$ENV_FILE"
    else
        # Adicionar token se não existir
        echo "INFLUXDB_TOKEN=$TOKEN" >> "$ENV_FILE"
    fi
    
    echo -e "${GREEN}✓ Token adicionado ao .env${NC}"
else
    echo -e "${RED}✗ Arquivo de token não encontrado${NC}"
    echo -e "${YELLOW}  O token foi exibido acima, copie-o manualmente para .env${NC}"
fi
echo ""

echo -e "${YELLOW}7️⃣  Reiniciando Grafana para aplicar token...${NC}"
docker-compose restart grafana
sleep 3
echo -e "${GREEN}✓ Done${NC}"
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}✅ DEPLOY CONCLUÍDO COM SUCESSO!${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📊 Stack Status:${NC}"
docker-compose ps
echo ""

echo -e "${YELLOW}🌐 Acessos:${NC}"
echo -e "  • InfluxDB:  ${GREEN}http://localhost:8086${NC}"
echo -e "  • Grafana:   ${GREEN}http://localhost:3000${NC}"
echo -e "    Usuario:   ${GREEN}admin${NC}"
echo -e "    Senha:     $(grep GRAFANA_ADMIN_PASSWORD $ENV_FILE | cut -d= -f2)"
echo ""

echo -e "${YELLOW}🔑 Token salvo em:${NC}"
echo -e "  ${GREEN}$ENV_FILE${NC}"
echo ""

echo -e "${YELLOW}📝 Próximas ações:${NC}"
echo -e "  1. Acesse Grafana em http://localhost:3000"
echo -e "  2. A datasource InfluxDB deve estar automaticamente configurada"
echo -e "  3. Configure o Proxmox Metric Server no WebUI do Proxmox"
echo -e "     - Use as credenciais exibidas acima"
echo ""
