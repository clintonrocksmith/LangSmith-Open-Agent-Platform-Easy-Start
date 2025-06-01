#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_header "Starting Open Agent Platform Services"

# Use the modular start services script
print_status "Using scripts/04-start-services.sh to start all services..."
./scripts/04-start-services.sh

print_header "All services started!"
echo -e "${GREEN}To stop all services, run: ./stop.sh${NC}" 