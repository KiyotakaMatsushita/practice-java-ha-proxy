#!/bin/bash

# Health check script for HAProxy demo application

echo "================================"
echo "HAProxy Demo Health Check"
echo "================================"

# Default values
HOST=${HOST:-localhost}
HAPROXY_PORT=${HAPROXY_PORT:-80}
STATS_PORT=${STATS_PORT:-8404}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Function to check endpoint
check_endpoint() {
    local url=$1
    local name=$2
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$response" = "200" ]; then
        print_success "$name is healthy (HTTP $response)"
        return 0
    else
        print_fail "$name is unhealthy (HTTP $response)"
        return 1
    fi
}

# Check HAProxy frontend
echo ""
echo "Checking HAProxy Frontend..."
check_endpoint "http://${HOST}:${HAPROXY_PORT}/api/test" "HAProxy Frontend"

# Check HAProxy stats
echo ""
echo "Checking HAProxy Stats..."
stats_response=$(curl -s -u admin:admin -o /dev/null -w "%{http_code}" "http://${HOST}:${STATS_PORT}/stats")
if [ "$stats_response" = "200" ]; then
    print_success "HAProxy Stats is accessible"
else
    print_fail "HAProxy Stats is not accessible (HTTP $stats_response)"
fi

# Check individual Spring Boot instances
echo ""
echo "Checking Spring Boot Instances..."
docker-compose ps | grep spring-app | while read -r line; do
    container_name=$(echo "$line" | awk '{print $1}')
    if docker exec "$container_name" curl -s -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
        print_success "Instance $container_name is healthy"
    else
        print_fail "Instance $container_name is unhealthy"
    fi
done

# Check Actuator endpoints
echo ""
echo "Checking Actuator Endpoints..."
endpoints=("health" "info" "metrics" "prometheus")
for endpoint in "${endpoints[@]}"; do
    check_endpoint "http://${HOST}:${HAPROXY_PORT}/actuator/$endpoint" "Actuator /$endpoint"
done

# Get instance distribution
echo ""
echo "Testing Load Distribution..."
declare -A instance_count
for i in {1..20}; do
    instance=$(curl -s "http://${HOST}:${HAPROXY_PORT}/api/instance" 2>/dev/null | grep -o '"instanceId":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$instance" ]; then
        ((instance_count[$instance]++))
    fi
done

echo "Request distribution across instances:"
for instance in "${!instance_count[@]}"; do
    echo "  Instance $instance: ${instance_count[$instance]} requests"
done

# Check system resources
echo ""
echo "System Resource Usage..."
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "(CONTAINER|haproxy|spring-app)"

# Summary
echo ""
echo "================================"
echo "Health Check Summary"
echo "================================"
print_info "HAProxy Stats: http://${HOST}:${STATS_PORT}/stats (admin/admin)"
print_info "Prometheus Metrics: http://${HOST}:${HAPROXY_PORT}/actuator/prometheus"
print_info "Application Health: http://${HOST}:${HAPROXY_PORT}/actuator/health" 