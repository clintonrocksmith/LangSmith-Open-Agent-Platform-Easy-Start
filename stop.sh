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
    echo "No PID file found. Attempting to kill processes by port..."
    # Fallback: kill processes by port
    pkill -f "python main.py" 2>/dev/null || true
    pkill -f "langgraph dev.*port.*2024" 2>/dev/null || true
    pkill -f "langgraph dev.*port.*2025" 2>/dev/null || true
    pkill -f "yarn dev" 2>/dev/null || true
fi

# Stop Docker services
if [ -d "langconnect" ]; then
    cd langconnect
    docker-compose down
    cd ..
    echo "Stopped LangConnect Docker services"
fi

echo "All services stopped."
