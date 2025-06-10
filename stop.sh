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
    
    # Kill processes by pattern (Windows/Unix compatibility)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        # Windows: Use taskkill
        taskkill //F //IM python.exe 2>/dev/null || true
        taskkill //F //IM node.exe 2>/dev/null || true
        taskkill //F //IM yarn.cmd 2>/dev/null || true
    else
        # Unix: Use pkill
        pkill -f "python main.py" 2>/dev/null || true
        pkill -f "langgraph dev.*port.*$TOOLS_PORT" 2>/dev/null || true
        pkill -f "langgraph dev.*port.*$SUPERVISOR_PORT" 2>/dev/null || true
        pkill -f "yarn dev.*port.*$WEB_PORT" 2>/dev/null || true
        pkill -f "yarn dev" 2>/dev/null || true
        pkill -f "next dev" 2>/dev/null || true
        pkill -f "node.*next.*dev" 2>/dev/null || true
    fi
    
    # Kill specific processes by port (Windows/Unix compatibility)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        # Windows: Use netstat and taskkill
        kill_port_windows() {
            local port=$1
            local pids=$(netstat -ano | findstr ":$port " | awk '{print $5}' | sort -u 2>/dev/null || true)
            for pid in $pids; do
                if [ -n "$pid" ] && [ "$pid" != "0" ]; then
                    taskkill //F //PID $pid 2>/dev/null || true
                fi
            done
        }
        
        kill_port_windows $TOOLS_PORT
        kill_port_windows $SUPERVISOR_PORT  
        kill_port_windows $WEB_PORT
        kill_port_windows 8080
        kill_port_windows 8002
    else
        # Unix: Use lsof and ps
        for pid in $(lsof -ti:$TOOLS_PORT 2>/dev/null); do 
            proc_name=$(ps -p $pid -o comm= 2>/dev/null || echo "")
            if [[ "$proc_name" == *"python"* ]] || [[ "$proc_name" == *"uvicorn"* ]]; then
                kill $pid 2>/dev/null || true
            fi
        done
        for pid in $(lsof -ti:$SUPERVISOR_PORT 2>/dev/null); do 
            proc_name=$(ps -p $pid -o comm= 2>/dev/null || echo "")
            if [[ "$proc_name" == *"python"* ]] || [[ "$proc_name" == *"uvicorn"* ]]; then
                kill $pid 2>/dev/null || true
            fi
        done
        for pid in $(lsof -ti:$WEB_PORT 2>/dev/null); do 
            proc_name=$(ps -p $pid -o comm= 2>/dev/null || echo "")
            if [[ "$proc_name" == *"node"* ]] || [[ "$proc_name" == *"yarn"* ]]; then
                kill $pid 2>/dev/null || true
            fi
        done
        # Only kill port 8080 if it's our langconnect API, not Docker
        for pid in $(lsof -ti:8080 2>/dev/null); do 
            proc_name=$(ps -p $pid -o comm= 2>/dev/null || echo "")
            if [[ "$proc_name" == *"python"* ]] || [[ "$proc_name" == *"uvicorn"* ]]; then
                kill $pid 2>/dev/null || true
            fi
        done
        for pid in $(lsof -ti:8002 2>/dev/null); do 
            proc_name=$(ps -p $pid -o comm= 2>/dev/null || echo "")
            if [[ "$proc_name" == *"python"* ]] || [[ "$proc_name" == *"uvicorn"* ]]; then
                kill $pid 2>/dev/null || true
            fi
        done
    fi
    
    echo "Attempted to stop services on ports: $TOOLS_PORT, $SUPERVISOR_PORT, $WEB_PORT, 8080"
fi

# Stop specific Docker containers for LangConnect only
if [ -d "langconnect" ]; then
    cd langconnect
    # Stop only our specific containers, don't affect other Docker services
    docker-compose down 2>/dev/null || echo "LangConnect containers already stopped or not running"
    cd ..
    echo "Stopped LangConnect Docker services"
fi

echo "All services stopped."
