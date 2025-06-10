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
MCP_PORT=$(jq -r '.ports.mcp_server' values.json)

# Function to wait for Docker to be available
wait_for_docker() {
    echo "Checking Docker availability..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker info > /dev/null 2>&1; then
            echo "Docker is running!"
            return 0
        fi
        echo "Waiting for Docker to be available... (attempt $((attempt + 1))/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "Error: Docker is not available after $max_attempts attempts"
    echo "Please start Docker Desktop and try again"
    return 1
}

# Function to start LangConnect
start_langconnect() {
    echo "Starting LangConnect on port $RAG_PORT..."
    
    # Wait for Docker to be available
    if ! wait_for_docker; then
        echo "Warning: Skipping LangConnect due to Docker unavailability"
        return 1
    fi
    
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
    
    # Activate virtual environment (Windows/Unix compatibility)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        source .venv/Scripts/activate
    else
        source .venv/bin/activate
    fi
    
    # Start LangGraph service
    uv run langgraph dev --no-browser --port "$port" &
    
    cd ..
}

# Function to start MCP server
start_mcp_server() {
    echo "Starting MCP Server on port $MCP_PORT..."
    cd mcp-server
    
    # Activate virtual environment (Windows/Unix compatibility)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        source Scripts/activate
    else
        source bin/activate
    fi
    
    # Start MCP server
    cd custom_mcp_server
    python main.py &
    cd ..
    
    cd ..
}

# Start MCP Server only if configured
MCP_SERVER_URL=$(jq -r '.mcp.server_url' values.json)
if [ -n "$MCP_SERVER_URL" ] && [ "$MCP_SERVER_URL" != "" ] && [ "$MCP_SERVER_URL" != "null" ]; then
    echo "MCP Server URL configured: $MCP_SERVER_URL"
    start_mcp_server
else
    echo "No MCP server URL configured, skipping MCP server startup..."
fi

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

# Wait for agent services to be ready
echo "Waiting for agent services to start..."
sleep 5

# Update agents with MCP server configuration now that services are running
MCP_SERVER_URL=$(jq -r '.mcp.server_url' values.json)
if [ -n "$MCP_SERVER_URL" ] && [ "$MCP_SERVER_URL" != "" ] && [ "$MCP_SERVER_URL" != "null" ]; then
    echo "Updating agents with MCP server configuration..."
    cd open-agent-platform/apps/web
    
    # Set environment variable for the update script
    export NEXT_PUBLIC_MCP_SERVER_URL="$MCP_SERVER_URL"
    
    if npx tsx scripts/update-agents-mcp-url.ts; then
        echo "Successfully updated all agents with MCP server URL: $MCP_SERVER_URL"
    else
        echo "Warning: Failed to update agents with MCP server URL, but continuing..."
    fi
    cd ../../..
else
    echo "No MCP server URL configured, skipping agent MCP update"
fi

echo "All services started!"
echo "Services are available at:"
echo "- Open Agent Platform: http://localhost:$WEB_PORT"
echo "- Tools Agent: http://localhost:$TOOLS_PORT"
echo "- Supervisor Agent: http://localhost:$SUPERVISOR_PORT"
echo "- LangConnect: http://localhost:$RAG_PORT"
if [ -n "$MCP_SERVER_URL" ] && [ "$MCP_SERVER_URL" != "" ] && [ "$MCP_SERVER_URL" != "null" ]; then
    echo "- MCP Server: http://localhost:$MCP_PORT"
fi 