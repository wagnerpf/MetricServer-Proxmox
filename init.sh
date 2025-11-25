#!/bin/bash

# Script de inicialização da Stack MetricServer-Proxmox
# Este script faz setup inicial e inicia todos os containers

set -e

echo "=========================================="
echo "MetricServer-Proxmox Setup"
echo "=========================================="
echo ""

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não está instalado. Por favor, instale Docker primeiro."
    exit 1
fi

# Verificar se docker-compose está instalado
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose não está instalado. Por favor, instale Docker Compose primeiro."
    exit 1
fi

# Copiar arquivo .env se não existir
if [ ! -f ".env" ]; then
    echo "📋 Criando arquivo .env a partir do template..."
    cp .env.example .env
    echo "⚠️  IMPORTANTE: Edite o arquivo .env com suas configurações do Proxmox"
    echo ""
fi

# Criar diretórios necessários
echo "📁 Criando diretórios de persistência..."
mkdir -p ./data/influxdb
mkdir -p ./data/grafana

# Iniciar containers
echo "🚀 Iniciando containers..."
docker-compose up -d

# Aguardar inicialização
echo "⏳ Aguardando inicialização dos serviços (30 segundos)..."
sleep 30

# Verificar status
echo ""
echo "📊 Status dos containers:"
docker-compose ps

echo ""
echo "=========================================="
echo "✅ Stack iniciada com sucesso!"
echo "=========================================="
echo ""
echo "📍 Acessar os serviços:"
echo "  - Grafana: http://localhost:3000"
echo "  - InfluxDB: http://localhost:8086"
echo "  - Node Exporter: http://localhost:9100/metrics"
echo ""
echo "📝 Próximos passos:"
echo "  1. Acesse o Grafana (http://localhost:3000)"
echo "  2. Faça login com as credenciais do .env"
echo "  3. Configure a datasource InfluxDB se necessário"
echo "  4. Configure o Telegraf com suas credenciais do Proxmox"
echo "  5. Verifique os logs: docker-compose logs -f telegraf"
echo ""
echo "🛠️  Para parar a stack: docker-compose down"
echo "🔄 Para reiniciar: docker-compose restart"
echo "📜 Para ver logs: docker-compose logs -f [service]"
echo ""
