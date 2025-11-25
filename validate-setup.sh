#!/bin/bash

# ============================================================================
# SCRIPT: Validação da Arquitetura Proxmox Metric Server
# ============================================================================
# Este script verifica se tudo está configurado corretamente

set -e

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║  Validação da Stack - Proxmox Metric Server                          ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_mark="✅"
cross_mark="❌"

# 1. Verificar Docker
echo -e "${BLUE}1. Verificando Docker...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}${check_mark} Docker instalado${NC}"
else
    echo -e "${RED}${cross_mark} Docker não encontrado${NC}"
    exit 1
fi

# 2. Verificar docker-compose
echo ""
echo -e "${BLUE}2. Verificando docker-compose...${NC}"
if command -v docker-compose &> /dev/null; then
    VERSION=$(docker-compose --version)
    echo -e "${GREEN}${check_mark} $VERSION${NC}"
else
    echo -e "${RED}${cross_mark} docker-compose não encontrado${NC}"
    exit 1
fi

# 3. Verificar arquivos essenciais
echo ""
echo -e "${BLUE}3. Verificando arquivos de configuração...${NC}"

FILES=("docker-compose.yml" ".env.example" "README.md" "ARQUITETURA_CORRIGIDA.md" "PROXMOX_METRIC_SERVER_SETUP.md")

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}${check_mark} $file${NC}"
    else
        echo -e "${RED}${cross_mark} $file não encontrado${NC}"
    fi
done

# 4. Verificar portas
echo ""
echo -e "${BLUE}4. Verificando disponibilidade de portas...${NC}"

PORTS=("3000:Grafana" "8086:InfluxDB" "9100:Node-Exporter")

for port_info in "${PORTS[@]}"; do
    PORT=$(echo $port_info | cut -d: -f1)
    NAME=$(echo $port_info | cut -d: -f2)
    
    if ! nc -z 127.0.0.1 $PORT 2>/dev/null; then
        echo -e "${GREEN}${check_mark} Porta $PORT ($NAME) disponível${NC}"
    else
        echo -e "${YELLOW}⚠️ Porta $PORT ($NAME) pode estar em uso${NC}"
    fi
done

# 5. Status dos containers
echo ""
echo -e "${BLUE}5. Status dos containers...${NC}"

if docker-compose ps &> /dev/null; then
    RUNNING=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    echo -e "${GREEN}${check_mark} Docker Compose respondendo${NC}"
    if [ $RUNNING -gt 0 ]; then
        echo -e "${YELLOW}ℹ️ $RUNNING container(s) rodando${NC}"
        docker-compose ps
    else
        echo -e "${YELLOW}ℹ️ Nenhum container rodando (execute: docker-compose up -d)${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️ Nenhum container ainda iniciado${NC}"
fi

# 6. Verificar conectividade InfluxDB
echo ""
echo -e "${BLUE}6. Verificando InfluxDB...${NC}"

if docker-compose ps influxdb 2>/dev/null | grep -q "Up"; then
    if curl -s http://localhost:8086/health &> /dev/null; then
        echo -e "${GREEN}${check_mark} InfluxDB rodando e respondendo${NC}"
        
        # Tentar listar buckets
        BUCKETS=$(docker-compose exec influxdb influx bucket list -o proxmox-org 2>/dev/null | grep proxmox-metrics | wc -l)
        if [ $BUCKETS -gt 0 ]; then
            echo -e "${GREEN}${check_mark} Bucket 'proxmox-metrics' encontrado${NC}"
        else
            echo -e "${YELLOW}⚠️ Bucket 'proxmox-metrics' não encontrado (criar com init script)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ InfluxDB não respondendo em http://localhost:8086${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️ InfluxDB não está rodando${NC}"
fi

# 7. Verificar Grafana
echo ""
echo -e "${BLUE}7. Verificando Grafana...${NC}"

if docker-compose ps grafana 2>/dev/null | grep -q "Up"; then
    if curl -s http://localhost:3000/api/health &> /dev/null; then
        echo -e "${GREEN}${check_mark} Grafana rodando e respondendo${NC}"
    else
        echo -e "${YELLOW}⚠️ Grafana não respondendo em http://localhost:3000${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️ Grafana não está rodando${NC}"
fi

# 8. Resumo de acesso
echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║  Acessos Disponíveis                                                  ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo ""
echo -e "${BLUE}Interface Web:${NC}"
echo "  • Grafana:   http://localhost:3000"
echo "  • InfluxDB:  http://localhost:8086"
echo "  • Explorer:  http://localhost:9100 (Node Exporter)"

echo ""
echo -e "${BLUE}Comandos Úteis:${NC}"
echo "  • Iniciar stack:"
echo "    docker-compose up -d"
echo ""
echo "  • Parar stack:"
echo "    docker-compose stop"
echo ""
echo "  • Ver logs:"
echo "    docker-compose logs -f influxdb"
echo ""
echo "  • Verificar métricas:"
echo "    docker-compose exec influxdb influx query 'from(bucket:\"proxmox-metrics\") |> range(start:-1h)' -o proxmox-org"

echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║  Próximos Passos                                                       ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo ""
echo "1. Revisar ARQUITETURA_CORRIGIDA.md para entender a nova arquitetura"
echo "2. Configurar Proxmox Metric Server em Datacenter → Metric Server"
echo "3. Acessar Grafana e criar dashboards com queries Flux"
echo "4. Monitorar logs: docker-compose logs -f"
echo ""
echo -e "${GREEN}✅ Stack pronta! Execute: docker-compose up -d${NC}"
echo ""
