#!/bin/bash
echo "Stopping Open Agent Platform services..."

# Load PIDs if they exist
if [ -f ".oap_pids" ]; then
    source .oap_pids
    
    # Stop background processes
    if [ ! -z "$MCP_SERVER_PID" ]; then
        kill $MCP_SERVER_PID 2>/dev/null || true
        echo "Stopped Custom MCP Server (PID: $MCP_SERVER_PID)"
    fi
    if [ ! -z "$TOOLS_AGENT_PID" ]; then
        kill $TOOLS_AGENT_PID 2>/dev/null || true
        echo "Stopped Tools Agent (PID: $TOOLS_AGENT_PID)"
    fi
    if [ ! -z "$SUPERVISOR_AGENT_PID" ]; then
        kill $SUPERVISOR_AGENT_PID 2>/dev/null || true
        echo "Stopped Supervisor Agent (PID: $SUPERVISOR_AGENT_PID)"
    fi
    if [ ! -z "$WEB_APP_PID" ]; then
        kill $WEB_APP_PID 2>/dev/null || true
        echo "Stopped Web App (PID: $WEB_APP_PID)"
    fi
    
    rm .oap_pids
else
    echo "No PID file found. Attempting to kill processes by pattern and port..."
    
    # Get ports from values.json if available
    if [ -f "values.json" ]; then
        TOOLS_PORT=$(jq -r '.ports.tools_agent' values.json 2>/dev/null || echo "2024")
        SUPERVISOR_PORT=$(jq -r '.ports.supervisor_agent' values.json 2>/dev/null || echo "2025")
        WEB_PORT=$(jq -r '.ports.web_app' values.json 2>/dev/null || echo "3000")
    else
        TOOLS_PORT="2024"
        SUPERVISOR_PORT="2025" 
        WEB_PORT="3000"
    fi
    
    # Kill processes by pattern
    pkill -f "python main.py" 2>/dev/null || true
    pkill -f "langgraph dev.*port.*$TOOLS_PORT" 2>/dev/null || true
    pkill -f "langgraph dev.*port.*$SUPERVISOR_PORT" 2>/dev/null || true
    pkill -f "yarn dev.*port.*$WEB_PORT" 2>/dev/null || true
    pkill -f "yarn dev" 2>/dev/null || true
    
    # Also try killing by port directly
    lsof -ti:$TOOLS_PORT | xargs -r kill 2>/dev/null || true
    lsof -ti:$SUPERVISOR_PORT | xargs -r kill 2>/dev/null || true  
    lsof -ti:$WEB_PORT | xargs -r kill 2>/dev/null || true
    lsof -ti:8080 | xargs -r kill 2>/dev/null || true  # LangConnect
    
    echo "Attempted to stop services on ports: $TOOLS_PORT, $SUPERVISOR_PORT, $WEB_PORT, 8080"
fi

# Stop Docker services
if [ -d "langconnect" ]; then
    cd langconnect
    docker-compose down
    cd ..
    echo "Stopped LangConnect Docker services"
fi

echo "All services stopped."
