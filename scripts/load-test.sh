#!/bin/bash

# Load test script for HAProxy demo application

echo "================================"
echo "HAProxy Demo Load Test Script"
echo "================================"

# Default values
HOST=${HOST:-localhost}
PORT=${PORT:-80}
REQUESTS=${REQUESTS:-10000}
CONCURRENCY=${CONCURRENCY:-100}
ENDPOINT=${ENDPOINT:-/api/test}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Apache Bench is installed
if ! command -v ab &> /dev/null; then
    print_error "Apache Bench (ab) is not installed."
    print_info "Install it using:"
    print_info "  Ubuntu/Debian: sudo apt-get install apache2-utils"
    print_info "  macOS: already included with Apache"
    print_info "  CentOS/RHEL: sudo yum install httpd-tools"
    exit 1
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            HOST="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -r|--requests)
            REQUESTS="$2"
            shift 2
            ;;
        -c|--concurrency)
            CONCURRENCY="$2"
            shift 2
            ;;
        -e|--endpoint)
            ENDPOINT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -h, --host         Host to test (default: localhost)"
            echo "  -p, --port         Port to test (default: 80)"
            echo "  -r, --requests     Total number of requests (default: 10000)"
            echo "  -c, --concurrency  Number of concurrent requests (default: 100)"
            echo "  -e, --endpoint     API endpoint to test (default: /api/test)"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

URL="http://${HOST}:${PORT}${ENDPOINT}"

print_info "Starting load test..."
print_info "URL: $URL"
print_info "Total requests: $REQUESTS"
print_info "Concurrency: $CONCURRENCY"
echo ""

# Run the test
print_info "Running Apache Bench test..."
ab -n $REQUESTS -c $CONCURRENCY -g results.tsv "$URL"

# Check if gnuplot is available for generating graphs
if command -v gnuplot &> /dev/null && [ -f results.tsv ]; then
    print_info "Generating response time graph..."
    
    cat > plot.gnuplot << EOF
set terminal png
set output 'response_times.png'
set title 'Response Time Distribution'
set xlabel 'Request Number'
set ylabel 'Response Time (ms)'
set grid
plot 'results.tsv' using 9 with lines title 'Response Time'
EOF
    
    gnuplot plot.gnuplot
    rm plot.gnuplot
    print_info "Graph saved as response_times.png"
fi

# Test different endpoints
print_info ""
print_info "Testing instance distribution..."
echo "Testing load balancing across instances:"
for i in {1..10}; do
    response=$(curl -s "http://${HOST}:${PORT}/api/instance" | grep -o '"instanceId":"[^"]*"' | cut -d'"' -f4)
    echo "Request $i: Instance $response"
done

# Heavy operation test
print_info ""
print_info "Testing heavy operation endpoint..."
time curl -X POST "http://${HOST}:${PORT}/api/heavy?iterations=5000"

print_info ""
print_info "Load test completed!"

# Cleanup
rm -f results.tsv

# Show HAProxy stats URL
print_info ""
print_info "View HAProxy statistics at: http://${HOST}:8404/stats"
print_info "Username: admin, Password: admin" 