#!/bin/bash

# Check if values.json exists and get port values
if [ ! -f "values.json" ]; then
    echo "Error: values.json not found!"
    exit 1
fi

# Get port values from values.json
RAG_PORT=$(jq -r '.ports.rag_server' values.json)
TOOLS_PORT=$(jq -r '.ports.tools_agent' values.json)
SUPERVISOR_PORT=$(jq -r '.ports.supervisor_agent' values.json)
WEB_PORT=$(jq -r '.ports.web_app' values.json)

# Function to start LangConnect
start_langconnect() {
    echo "Starting LangConnect on port $RAG_PORT..."
    cd langconnect
    docker-compose up -d
    cd ..
}

# Function to start agent service
start_agent_service() {
    local agent_dir=$1
    local port=$2
    
    echo "Starting $agent_dir on port $port..."
    cd "$agent_dir"
    
    # Activate virtual environment
    source .venv/bin/activate
    
    # Start LangGraph service
    uv run langgraph dev --no-browser --port "$port" &
    
    cd ..
}

# Start LangConnect
start_langconnect

# Start agent services
start_agent_service "oap-langgraph-tools-agent" "$TOOLS_PORT"
start_agent_service "oap-agent-supervisor" "$SUPERVISOR_PORT"

# Start Open Agent Platform web app
echo "Starting Open Agent Platform on port $WEB_PORT..."
cd open-agent-platform/apps/web
yarn dev --port "$WEB_PORT" &
cd ../../..

echo "All services started!"
echo "Services are available at:"
echo "- Open Agent Platform: http://localhost:$WEB_PORT"
echo "- Tools Agent: http://localhost:$TOOLS_PORT"
echo "- Supervisor Agent: http://localhost:$SUPERVISOR_PORT"
echo "- LangConnect: http://localhost:$RAG_PORT"
echo ""
echo "Note: MCP server is not started by this script (will run locally when needed)" 