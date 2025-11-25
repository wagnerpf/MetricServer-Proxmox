#!/bin/bash

# Script para gerenciar a stack MetricServer-Proxmox
# Uso: ./manage.sh [comando] [opções]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

function print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

function print_error() {
    echo -e "${RED}❌ $1${NC}"
}

function print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

function show_help() {
    cat <<EOF
MetricServer-Proxmox Manager

Uso: ./manage.sh [comando] [opções]

Comandos:
    start           Inicia a stack
    stop            Para a stack
    restart         Reinicia a stack
    status          Mostra status dos containers
    logs            Mostra logs em tempo real
    logs [service]  Mostra logs de um serviço específico
    shell [service] Abre shell em um container
    clean           Remove containers e volumes (PERIGO!)
    backup          Faz backup dos dados
    restore [file]  Restaura dados de um backup
    health          Verifica saúde dos serviços
    setup           Setup inicial completo
    help            Mostra esta mensagem

Exemplos:
    ./manage.sh start
    ./manage.sh logs telegraf
    ./manage.sh shell grafana
    ./manage.sh backup
EOF
}

function cmd_start() {
    print_header "Iniciando Stack"
    docker-compose up -d
    sleep 10
    cmd_status
    print_success "Stack iniciada!"
}

function cmd_stop() {
    print_header "Parando Stack"
    docker-compose stop
    print_success "Stack parada!"
}

function cmd_restart() {
    print_header "Reiniciando Stack"
    docker-compose restart
    sleep 10
    cmd_status
    print_success "Stack reiniciada!"
}

function cmd_status() {
    print_header "Status dos Containers"
    docker-compose ps
}

function cmd_logs() {
    if [ -z "$1" ]; then
        docker-compose logs -f
    else
        docker-compose logs -f "$1"
    fi
}

function cmd_shell() {
    if [ -z "$1" ]; then
        print_error "Serviço não especificado"
        echo "Serviços disponíveis:"
        docker-compose config --services
        exit 1
    fi
    docker-compose exec "$1" /bin/sh
}

function cmd_clean() {
    print_info "ATENÇÃO: Isto irá DELETAR TODOS os dados!"
    read -p "Digite 'sim' para confirmar: " -r
    if [[ $REPLY =~ ^[Ss][Ii][Mm]$ ]]; then
        print_header "Removendo Stack e Dados"
        docker-compose down -v
        print_success "Stack removida completamente"
    else
        print_info "Operação cancelada"
    fi
}

function cmd_backup() {
    print_header "Fazendo Backup"
    BACKUP_DIR="backups/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    print_info "Backup de volumes..."
    cp -r data/influxdb "$BACKUP_DIR/" 2>/dev/null || true
    cp -r data/grafana "$BACKUP_DIR/" 2>/dev/null || true
    cp -r grafana/provisioning "$BACKUP_DIR/" 2>/dev/null || true
    
    print_info "Backup de configurações..."
    cp docker-compose.yml "$BACKUP_DIR/"
    cp telegraf.conf "$BACKUP_DIR/"
    cp .env "$BACKUP_DIR/.env.backup"
    
    print_info "Compactando backup..."
    tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
    rm -rf "$BACKUP_DIR"
    
    print_success "Backup criado: $BACKUP_DIR.tar.gz"
}

function cmd_restore() {
    if [ -z "$1" ]; then
        print_error "Arquivo de backup não especificado"
        exit 1
    fi
    
    print_header "Restaurando Backup"
    print_info "Extraindo: $1"
    tar -xzf "$1"
    
    BACKUP_DIR=$(basename "$1" .tar.gz)
    print_info "Copiando dados..."
    cp -r "$BACKUP_DIR/influxdb" data/ 2>/dev/null || true
    cp -r "$BACKUP_DIR/grafana" data/ 2>/dev/null || true
    cp -r "$BACKUP_DIR/provisioning" grafana/ 2>/dev/null || true
    
    rm -rf "$BACKUP_DIR"
    print_success "Backup restaurado!"
}

function cmd_health() {
    print_header "Verificando Saúde dos Serviços"
    
    print_info "InfluxDB..."
    if curl -s http://localhost:8086/health > /dev/null; then
        print_success "InfluxDB está saudável"
    else
        print_error "InfluxDB está fora do ar"
    fi
    
    print_info "Grafana..."
    if curl -s http://localhost:3000/api/health > /dev/null; then
        print_success "Grafana está saudável"
    else
        print_error "Grafana está fora do ar"
    fi
    
    print_info "Telegraf..."
    if docker-compose exec -T telegraf telegraf --version > /dev/null 2>&1; then
        print_success "Telegraf está rodando"
    else
        print_error "Telegraf está com problemas"
    fi
    
    print_info "Node Exporter..."
    if curl -s http://localhost:9100/metrics > /dev/null; then
        print_success "Node Exporter está saudável"
    else
        print_error "Node Exporter está fora do ar"
    fi
}

function cmd_setup() {
    print_header "Setup Inicial Completo"
    
    if [ ! -f ".env" ]; then
        print_info "Criando .env..."
        cp .env.example .env
        print_error "EDITE o arquivo .env com suas credenciais antes de continuar!"
        echo "Execute: nano .env"
        exit 1
    fi
    
    mkdir -p data/influxdb data/grafana
    cmd_start
    print_success "Setup completo!"
}

# Main
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

case "$1" in
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    restart)
        cmd_restart
        ;;
    status)
        cmd_status
        ;;
    logs)
        cmd_logs "$2"
        ;;
    shell)
        cmd_shell "$2"
        ;;
    clean)
        cmd_clean
        ;;
    backup)
        cmd_backup
        ;;
    restore)
        cmd_restore "$2"
        ;;
    health)
        cmd_health
        ;;
    setup)
        cmd_setup
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Comando desconhecido: $1"
        show_help
        exit 1
        ;;
esac
