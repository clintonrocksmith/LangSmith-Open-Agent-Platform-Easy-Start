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

# Start LangConnect RAG Server
if [ -d "langconnect" ]; then
    print_status "Starting LangConnect RAG Server with Docker Compose..."
    cd langconnect
    docker-compose up -d
    cd ..
else
    print_status "LangConnect directory not found. Skipping RAG Server."
fi

# Start Custom MCP Server
if [ -d "arcade-env/custom_mcp_server" ]; then
    print_status "Starting Custom MCP Server on port 8002..."
    cd arcade-env/custom_mcp_server
    source ../bin/activate
    nohup python main.py > ../../mcp_server.log 2>&1 &
    MCP_SERVER_PID=$!
    cd ../..
    print_status "Custom MCP Server started with PID: $MCP_SERVER_PID"
else
    print_status "Custom MCP server directory not found. Skipping MCP server."
fi

# Start Tools Agent
if [ -d "oap-langgraph-tools-agent" ]; then
    print_status "Starting Tools Agent..."
    cd oap-langgraph-tools-agent
    source .venv/bin/activate
    nohup uv run langgraph dev --no-browser --port 2024 > ../tools_agent.log 2>&1 &
    TOOLS_AGENT_PID=$!
    cd ..
    print_status "Tools Agent started with PID: $TOOLS_AGENT_PID"
else
    print_status "Tools Agent directory not found. Skipping Tools Agent."
fi

# Start Supervisor Agent
if [ -d "oap-agent-supervisor" ]; then
    print_status "Starting Supervisor Agent..."
    cd oap-agent-supervisor
    source .venv/bin/activate
    nohup uv run langgraph dev --no-browser --port 2025 > ../supervisor_agent.log 2>&1 &
    SUPERVISOR_AGENT_PID=$!
    cd ..
    print_status "Supervisor Agent started with PID: $SUPERVISOR_AGENT_PID"
else
    print_status "Supervisor Agent directory not found. Skipping Supervisor Agent."
fi

# Start Web Platform
if [ -d "open-agent-platform/apps/web" ]; then
    print_status "Starting Web Platform on port 3000..."
    cd open-agent-platform/apps/web
    nohup yarn start -p 3000 > ../../../web_app.log 2>&1 &
    WEB_APP_PID=$!
    cd ../../..
    print_status "Web Platform started with PID: $WEB_APP_PID"
else
    print_status "Web Platform directory not found. Skipping Web App."
fi

print_header "All requested services started (if present)."
echo -e "${GREEN}To stop all services, use the stop-oap.sh script or manually kill the PIDs above.${NC}" 