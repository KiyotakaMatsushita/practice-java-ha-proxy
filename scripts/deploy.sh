#!/bin/bash

# Deploy script for HAProxy demo application

echo "================================"
echo "HAProxy Demo Deploy Script"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  up        Start all services"
    echo "  down      Stop all services"
    echo "  restart   Restart all services"
    echo "  scale     Scale Spring Boot instances"
    echo "  logs      Show logs"
    echo "  status    Show service status"
    echo "  clean     Clean up everything"
    echo ""
    echo "Options:"
    echo "  --instances N    Number of Spring Boot instances (for scale command)"
    echo "  --monitoring     Include monitoring stack (Prometheus & Grafana)"
    echo "  --follow         Follow logs (for logs command)"
    echo ""
    echo "Examples:"
    echo "  $0 up"
    echo "  $0 up --monitoring"
    echo "  $0 scale --instances 5"
    echo "  $0 logs --follow"
}

# Parse command
COMMAND=$1
shift

# Parse options
INSTANCES=3
MONITORING=false
FOLLOW=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --instances)
            INSTANCES="$2"
            shift 2
            ;;
        --monitoring)
            MONITORING=true
            shift
            ;;
        --follow)
            FOLLOW=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Execute command
case $COMMAND in
    up)
        print_info "Starting HAProxy demo application..."
        
        # Copy .env.example to .env if it doesn't exist
        if [ ! -f .env ] && [ -f .env.example ]; then
            print_info "Creating .env file from .env.example..."
            cp .env.example .env
        fi
        
        # Build and start services
        if [ "$MONITORING" = true ]; then
            print_info "Starting with monitoring stack..."
            docker-compose --profile monitoring up -d --build --scale spring-app=$INSTANCES
        else
            docker-compose up -d --build --scale spring-app=$INSTANCES
        fi
        
        # Wait for services to be ready
        print_info "Waiting for services to be ready..."
        sleep 10
        
        # Run health check
        print_info "Running health check..."
        ./scripts/health-check.sh
        
        print_success "Deployment completed!"
        print_info "Access points:"
        print_info "  - Application: http://localhost"
        print_info "  - HAProxy Stats: http://localhost:8404/stats (admin/admin)"
        if [ "$MONITORING" = true ]; then
            print_info "  - Prometheus: http://localhost:9090"
            print_info "  - Grafana: http://localhost:3000 (admin/admin)"
        fi
        ;;
        
    down)
        print_info "Stopping HAProxy demo application..."
        docker-compose down
        print_success "All services stopped!"
        ;;
        
    restart)
        print_info "Restarting HAProxy demo application..."
        docker-compose restart
        print_success "All services restarted!"
        ;;
        
    scale)
        print_info "Scaling Spring Boot instances to $INSTANCES..."
        docker-compose up -d --scale spring-app=$INSTANCES --no-recreate
        print_success "Scaled to $INSTANCES instances!"
        
        # Show current instances
        sleep 3
        print_info "Current instances:"
        docker-compose ps | grep spring-app
        ;;
        
    logs)
        if [ "$FOLLOW" = true ]; then
            docker-compose logs -f
        else
            docker-compose logs --tail=100
        fi
        ;;
        
    status)
        print_info "Service status:"
        docker-compose ps
        echo ""
        print_info "Resource usage:"
        docker stats --no-stream
        ;;
        
    clean)
        print_warn "This will remove all containers, images, and volumes!"
        read -p "Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cleaning up..."
            docker-compose down -v --rmi all
            print_success "Cleanup completed!"
        else
            print_info "Cleanup cancelled."
        fi
        ;;
        
    *)
        print_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac 