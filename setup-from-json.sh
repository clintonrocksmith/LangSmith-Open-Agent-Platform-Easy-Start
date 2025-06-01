#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to generate UUID
generate_uuid() {
    if command_exists uuidgen; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    elif command_exists python3; then
        python3 -c "import uuid; print(str(uuid.uuid4()))"
    else
        # Fallback to a simple random string (not a real UUID but sufficient for demo)
        echo "$(date +%s)-$(shuf -i 1000-9999 -n 1)-4000-8000-$(shuf -i 100000000000-999999999999 -n 1)"
    fi
}

# Function to extract value from JSON using jq
get_json_value() {
    local key="$1"
    echo $(cat values.json | jq -r "$key")
}

# Function to update JSON file
update_json_value() {
    local key="$1"
    local value="$2"
    local temp_file=$(mktemp)
    jq "$key = \"$value\"" values.json > "$temp_file" && mv "$temp_file" values.json
}

# Function to create LangConnect .env file
create_langconnect_env() {
    local supabase_url="$1"
    local supabase_service_key="$2"
    local openai_key="$3"
    local postgres_password="$4"
    local web_port="$5"
    
    print_status "Creating LangConnect .env file..."
    if [ -f "langconnect/.env.example" ]; then
        cp langconnect/.env.example langconnect/.env
        # Update only the required values
        sed -i.bak "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=\"$openai_key\"|g" langconnect/.env
        sed -i.bak "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=\"$postgres_password\"|g" langconnect/.env
        sed -i.bak "s|SUPABASE_URL=.*|SUPABASE_URL=\"$supabase_url\"|g" langconnect/.env
        sed -i.bak "s|SUPABASE_KEY=.*|SUPABASE_KEY=\"$supabase_service_key\"|g" langconnect/.env
        sed -i.bak "s|ALLOW_ORIGINS=.*|ALLOW_ORIGINS=[\"http://localhost:$web_port\"]|g" langconnect/.env
        rm -f langconnect/.env.bak
    else
        print_error "langconnect/.env.example not found"
        exit 1
    fi
}

# Function to create Tools Agent .env file
create_tools_agent_env() {
    local langsmith_key="$1"
    local supabase_url="$2"
    local supabase_service_key="$3"
    local llm_provider="$4"
    local openai_key="$5"
    local anthropic_key="$6"
    local langsmith_endpoint="$7"
    local langsmith_project="$8"
    
    print_status "Creating Tools Agent .env file..."
    if [ -f "oap-langgraph-tools-agent/.env.example" ]; then
        cp oap-langgraph-tools-agent/.env.example oap-langgraph-tools-agent/.env
        # Update only the required values
        sed -i.bak "s|LANGCHAIN_PROJECT=.*|LANGCHAIN_PROJECT=\"$langsmith_project\"|g" oap-langgraph-tools-agent/.env
        sed -i.bak "s|LANGCHAIN_API_KEY=.*|LANGCHAIN_API_KEY=\"$langsmith_key\"|g" oap-langgraph-tools-agent/.env
        sed -i.bak "s|LANGCHAIN_ENDPOINT=.*|LANGCHAIN_ENDPOINT=\"$langsmith_endpoint\"|g" oap-langgraph-tools-agent/.env
        sed -i.bak "s|SUPABASE_URL=.*|SUPABASE_URL=\"$supabase_url\"|g" oap-langgraph-tools-agent/.env
        sed -i.bak "s|SUPABASE_KEY=.*|SUPABASE_KEY=\"$supabase_service_key\"|g" oap-langgraph-tools-agent/.env
        
        if [ "$llm_provider" = "openai" ] || [ -n "$openai_key" ]; then
            sed -i.bak "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=\"$openai_key\"|g" oap-langgraph-tools-agent/.env
        fi
        
        if [ "$llm_provider" = "anthropic" ] || [ -n "$anthropic_key" ]; then
            sed -i.bak "s|ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=\"$anthropic_key\"|g" oap-langgraph-tools-agent/.env
        fi
        
        rm -f oap-langgraph-tools-agent/.env.bak
    else
        print_error "oap-langgraph-tools-agent/.env.example not found"
        exit 1
    fi
}

# Function to create Supervisor Agent .env file
create_supervisor_agent_env() {
    local langsmith_key="$1"
    local supabase_url="$2"
    local supabase_service_key="$3"
    local llm_provider="$4"
    local openai_key="$5"
    local anthropic_key="$6"
    local langsmith_endpoint="$7"
    local langsmith_project="$8"
    
    print_status "Creating Supervisor Agent .env file..."
    if [ -f "oap-agent-supervisor/.env.example" ]; then
        cp oap-agent-supervisor/.env.example oap-agent-supervisor/.env
        # Update only the required values
        sed -i.bak "s|LANGCHAIN_PROJECT=.*|LANGCHAIN_PROJECT=\"$langsmith_project\"|g" oap-agent-supervisor/.env
        sed -i.bak "s|LANGCHAIN_API_KEY=.*|LANGCHAIN_API_KEY=\"$langsmith_key\"|g" oap-agent-supervisor/.env
        sed -i.bak "s|LANGCHAIN_ENDPOINT=.*|LANGCHAIN_ENDPOINT=\"$langsmith_endpoint\"|g" oap-agent-supervisor/.env
        sed -i.bak "s|SUPABASE_URL=.*|SUPABASE_URL=\"$supabase_url\"|g" oap-agent-supervisor/.env
        sed -i.bak "s|SUPABASE_KEY=.*|SUPABASE_KEY=\"$supabase_service_key\"|g" oap-agent-supervisor/.env
        
        if [ "$llm_provider" = "openai" ] || [ -n "$openai_key" ]; then
            sed -i.bak "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=\"$openai_key\"|g" oap-agent-supervisor/.env
        fi
        
        if [ "$llm_provider" = "anthropic" ] || [ -n "$anthropic_key" ]; then
            sed -i.bak "s|ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=\"$anthropic_key\"|g" oap-agent-supervisor/.env
        fi
        
        rm -f oap-agent-supervisor/.env.bak
    else
        print_error "oap-agent-supervisor/.env.example not found"
        exit 1
    fi
}

# Function to create Web Platform .env file
create_web_platform_env() {
    local supabase_url="$1"
    local supabase_anon_key="$2"
    local langsmith_key="$3"
    local rag_port="$4"
    local mcp_server_url="$5"
    local mcp_auth_required="$6"
    local google_auth_disabled="$7"
    local tools_agent_id="$8"
    local supervisor_agent_id="$9"
    local tenant_id="${10}"
    local tools_port="${11}"
    local supervisor_port="${12}"
    local web_port="${13}"
    local langsmith_endpoint="${14}"
    
    print_status "Creating Web Platform .env file..."
    if [ -f "open-agent-platform/apps/web/.env.example" ]; then
        cp open-agent-platform/apps/web/.env.example open-agent-platform/apps/web/.env
        # Update only the required values
        sed -i.bak "s|NEXT_PUBLIC_BASE_API_URL=.*|NEXT_PUBLIC_BASE_API_URL=\"http://localhost:$web_port/api\"|g" open-agent-platform/apps/web/.env
        sed -i.bak "s|LANGSMITH_API_KEY=.*|LANGSMITH_API_KEY=\"$langsmith_key\"|g" open-agent-platform/apps/web/.env
        sed -i.bak "s|LANGCHAIN_ENDPOINT=.*|LANGCHAIN_ENDPOINT=\"$langsmith_endpoint\"|g" open-agent-platform/apps/web/.env
        sed -i.bak "s|NEXT_PUBLIC_DEPLOYMENTS=.*|NEXT_PUBLIC_DEPLOYMENTS=[{\"id\":\"$tools_agent_id\",\"deploymentUrl\":\"http://localhost:$tools_port\",\"tenantId\":\"$tenant_id\",\"name\":\"Tools Agent (Local)\",\"isDefault\":true,\"defaultGraphId\":\"agent\"},{\"id\":\"$supervisor_agent_id\",\"deploymentUrl\":\"http://localhost:$supervisor_port\",\"tenantId\":\"$tenant_id\",\"name\":\"Supervisor Agent (Local)\",\"isDefault\":false,\"defaultGraphId\":\"agent\"}]|g" open-agent-platform/apps/web/.env
        sed -i.bak "s|NEXT_PUBLIC_RAG_API_URL=.*|NEXT_PUBLIC_RAG_API_URL=\"http://localhost:$rag_port\"|g" open-agent-platform/apps/web/.env
        sed -i.bak "s|NEXT_PUBLIC_MCP_SERVER_URL=.*|NEXT_PUBLIC_MCP_SERVER_URL=\"$mcp_server_url\"|g" open-agent-platform/apps/web/.env
        sed -i.bak "s|NEXT_PUBLIC_MCP_AUTH_REQUIRED=.*|NEXT_PUBLIC_MCP_AUTH_REQUIRED=\"$mcp_auth_required\"|g" open-agent-platform/apps/web/.env
        sed -i.bak "s|NEXT_PUBLIC_SUPABASE_ANON_KEY=.*|NEXT_PUBLIC_SUPABASE_ANON_KEY=\"$supabase_anon_key\"|g" open-agent-platform/apps/web/.env
        sed -i.bak "s|NEXT_PUBLIC_SUPABASE_URL=.*|NEXT_PUBLIC_SUPABASE_URL=\"$supabase_url\"|g" open-agent-platform/apps/web/.env
        sed -i.bak "s|NEXT_PUBLIC_GOOGLE_AUTH_DISABLED=.*|NEXT_PUBLIC_GOOGLE_AUTH_DISABLED=\"$google_auth_disabled\"|g" open-agent-platform/apps/web/.env
        rm -f open-agent-platform/apps/web/.env.bak
    else
        print_error "open-agent-platform/apps/web/.env.example not found"
        exit 1
    fi
}

# Function to clone or update repository
clone_or_update_repo() {
    local repo_url="$1"
    local repo_dir="$2"
    local repo_name="$3"
    
    if [ -d "$repo_dir" ]; then
        print_status "Updating $repo_name repository..."
        cd "$repo_dir"
        if [ -d ".git" ]; then
            git pull origin main || git pull origin master || print_warning "Could not pull latest changes for $repo_name"
        else
            print_warning "$repo_dir exists but is not a git repository"
        fi
        cd ..
    else
        print_status "Cloning $repo_name repository..."
        git clone "$repo_url" "$repo_dir" || {
            print_error "Failed to clone $repo_name repository from $repo_url"
            exit 1
        }
    fi
}

# Function to initialize virtual environment and install dependencies
initialize_agent_env() {
    local agent_dir="$1"
    local agent_name="$2"
    
    print_status "Initializing $agent_name environment..."
    cd "$agent_dir"
    
    # Create virtual environment
    print_status "Creating virtual environment for $agent_name..."
    uv venv || {
        print_error "Failed to create virtual environment for $agent_name"
        exit 1
    }
    
    # Activate virtual environment and install dependencies
    print_status "Installing dependencies for $agent_name..."
    source .venv/bin/activate && uv sync || {
        print_error "Failed to install dependencies for $agent_name"
        exit 1
    }
    
    cd ..
}

# Function to start LangConnect services
start_langconnect() {
    print_status "Starting LangConnect services..."
    cd langconnect
    docker-compose up -d || {
        print_error "Failed to start LangConnect services"
        exit 1
    }
    cd ..
}

# Function to start agent services
start_agent_service() {
    local agent_dir="$1"
    local agent_name="$2"
    
    print_status "Starting $agent_name service..."
    cd "$agent_dir"
    source .venv/bin/activate
    uv run langgraph dev --no-browser &
    cd ..
}

print_header "Open Agent Platform Setup from JSON Configuration"

# Check if values.json exists
if [ ! -f "values.json" ]; then
    print_error "values.json file not found. Please create it first."
    exit 1
fi

# Check for required tools
print_status "Checking for required tools..."

required_tools=("git" "jq" "docker" "docker-compose" "uv" "yarn" "node")
for tool in "${required_tools[@]}"; do
    if ! command_exists "$tool"; then
        print_error "$tool is not installed. Please install it first."
        exit 1
    fi
done

print_status "All required tools are installed!"

# Repository URLs
OPEN_AGENT_PLATFORM_URL="https://github.com/langchain-ai/open-agent-platform.git"
TOOLS_AGENT_URL="https://github.com/langchain-ai/oap-langgraph-tools-agent.git"
SUPERVISOR_AGENT_URL="https://github.com/langchain-ai/oap-agent-supervisor.git"
LANGCONNECT_URL="https://github.com/langchain-ai/langconnect.git"

# Clone or update all repositories
print_header "Cloning/Updating Repositories"

clone_or_update_repo "$OPEN_AGENT_PLATFORM_URL" "open-agent-platform" "Open Agent Platform"
clone_or_update_repo "$TOOLS_AGENT_URL" "oap-langgraph-tools-agent" "Tools Agent"
clone_or_update_repo "$SUPERVISOR_AGENT_URL" "oap-agent-supervisor" "Supervisor Agent" 
clone_or_update_repo "$LANGCONNECT_URL" "langconnect" "LangConnect"

# Read configuration from JSON
print_status "Reading configuration from values.json..."

SUPABASE_URL=$(get_json_value '.supabase.url')
SUPABASE_ANON_KEY=$(get_json_value '.supabase.anon_key')
SUPABASE_SERVICE_ROLE_KEY=$(get_json_value '.supabase.service_role_key')
LANGSMITH_API_KEY=$(get_json_value '.langsmith.api_key')
LLM_PROVIDER=$(get_json_value '.llm.provider')
OPENAI_API_KEY=$(get_json_value '.llm.openai_api_key')
ANTHROPIC_API_KEY=$(get_json_value '.llm.anthropic_api_key')
GOOGLE_API_KEY=$(get_json_value '.llm.google_api_key')
MCP_SERVER_URL=$(get_json_value '.mcp.server_url')
MCP_AUTH_REQUIRED=$(get_json_value '.mcp.auth_required')
RAG_PORT=$(get_json_value '.ports.rag_server')
TOOLS_PORT=$(get_json_value '.ports.tools_agent')
SUPERVISOR_PORT=$(get_json_value '.ports.supervisor_agent')
WEB_PORT=$(get_json_value '.ports.web_app')
TENANT_ID=$(get_json_value '.generated_ids.tenant_id')
TOOLS_AGENT_ID=$(get_json_value '.generated_ids.tools_agent_id')
SUPERVISOR_AGENT_ID=$(get_json_value '.generated_ids.supervisor_agent_id')
GOOGLE_AUTH_DISABLED=$(get_json_value '.settings.google_auth_disabled')

# Validate required fields
if [ "$SUPABASE_URL" = "YOUR_SUPABASE_PROJECT_URL" ] || [ "$SUPABASE_URL" = "null" ]; then
    print_error "Please update values.json with your actual Supabase URL"
    exit 1
fi

if [ "$SUPABASE_ANON_KEY" = "YOUR_SUPABASE_ANON_KEY" ] || [ "$SUPABASE_ANON_KEY" = "null" ]; then
    print_error "Please update values.json with your actual Supabase anon key"
    exit 1
fi

if [ "$LANGSMITH_API_KEY" = "YOUR_LANGSMITH_API_KEY" ] || [ "$LANGSMITH_API_KEY" = "null" ]; then
    print_error "Please update values.json with your actual LangSmith API key"
    exit 1
fi

# Check LLM API key based on provider
case $LLM_PROVIDER in
    "openai")
        if [ "$OPENAI_API_KEY" = "YOUR_OPENAI_API_KEY" ] || [ "$OPENAI_API_KEY" = "null" ] || [ -z "$OPENAI_API_KEY" ]; then
            print_error "Please update values.json with your actual OpenAI API key"
            exit 1
        fi
        ;;
    "anthropic")
        if [ -z "$ANTHROPIC_API_KEY" ] || [ "$ANTHROPIC_API_KEY" = "null" ]; then
            print_error "Please update values.json with your actual Anthropic API key"
            exit 1
        fi
        ;;
    "google")
        if [ -z "$GOOGLE_API_KEY" ] || [ "$GOOGLE_API_KEY" = "null" ]; then
            print_error "Please update values.json with your actual Google API key"
            exit 1
        fi
        ;;
    *)
        print_error "Invalid LLM provider: $LLM_PROVIDER. Must be 'openai', 'anthropic', or 'google'"
        exit 1
        ;;
esac

# Generate UUIDs if they don't exist
if [ -z "$TENANT_ID" ] || [ "$TENANT_ID" = "null" ] || [ "$TENANT_ID" = "" ]; then
    TENANT_ID=$(generate_uuid)
    update_json_value '.generated_ids.tenant_id' "$TENANT_ID"
    print_status "Generated tenant ID: $TENANT_ID"
fi

if [ -z "$TOOLS_AGENT_ID" ] || [ "$TOOLS_AGENT_ID" = "null" ] || [ "$TOOLS_AGENT_ID" = "" ]; then
    TOOLS_AGENT_ID=$(generate_uuid)
    update_json_value '.generated_ids.tools_agent_id' "$TOOLS_AGENT_ID"
    print_status "Generated tools agent ID: $TOOLS_AGENT_ID"
fi

if [ -z "$SUPERVISOR_AGENT_ID" ] || [ "$SUPERVISOR_AGENT_ID" = "null" ] || [ "$SUPERVISOR_AGENT_ID" = "" ]; then
    SUPERVISOR_AGENT_ID=$(generate_uuid)
    update_json_value '.generated_ids.supervisor_agent_id' "$SUPERVISOR_AGENT_ID"
    print_status "Generated supervisor agent ID: $SUPERVISOR_AGENT_ID"
fi

print_status "Configuration validated successfully!"

# Start setting up components
print_header "Setting Up Components"

# 1. Set up LangConnect RAG Server
print_status "Setting up LangConnect RAG Server..."

if [ ! -d "langconnect" ]; then
    print_error "langconnect directory not found. Repository cloning may have failed."
    exit 1
fi

# Create .env file for LangConnect
create_langconnect_env "$SUPABASE_URL" "$SUPABASE_SERVICE_ROLE_KEY" "$OPENAI_API_KEY" "$SUPABASE_PASSWORD" "$WEB_PORT"

cd langconnect

print_status "Starting LangConnect with Docker Compose on port $RAG_PORT..."
# Update docker-compose port if needed
if [ "$RAG_PORT" != "8080" ]; then
    print_status "Updating docker-compose.yml to use port $RAG_PORT"
    # This assumes the docker-compose.yml has a standard port mapping structure
    sed -i.bak "s/8080:8080/$RAG_PORT:8080/g" docker-compose.yml
fi

docker-compose up -d

print_status "Waiting for LangConnect to be ready..."
sleep 15

# Test if LangConnect is running
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:$RAG_PORT/health > /dev/null; then
        print_status "LangConnect is running successfully!"
        break
    fi
    attempt=$((attempt + 1))
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    print_warning "LangConnect may not be fully ready yet. Continuing..."
fi

cd ..

# 2. Set up Custom MCP Server
print_status "Setting up Custom MCP Server..."

if [ ! -d "arcade-env/custom_mcp_server" ]; then
    print_warning "Custom MCP server directory not found. Skipping MCP server setup."
    print_warning "If you have a custom MCP server, ensure it's at arcade-env/custom_mcp_server/"
else
    cd arcade-env/custom_mcp_server
    
    print_status "Starting Custom MCP Server on port 8002..."
    
    # Activate the virtual environment and start the server
    source ../bin/activate
    python main.py &
    MCP_SERVER_PID=$!
    
    print_status "Custom MCP Server started with PID: $MCP_SERVER_PID"
    
    # Wait a moment for the server to start
    sleep 5
    
    # Test if MCP server is running
    if curl -s http://localhost:8002/health > /dev/null 2>&1; then
        print_status "Custom MCP Server is running successfully!"
    else
        print_warning "Custom MCP Server may not be fully ready yet. Continuing..."
    fi
    
    cd ../..
fi

# 3. Set up Tools Agent
print_status "Setting up Tools Agent..."

if [ ! -d "oap-langgraph-tools-agent" ]; then
    print_error "oap-langgraph-tools-agent directory not found. Repository cloning may have failed."
    exit 1
fi

# Create .env file for Tools Agent
create_tools_agent_env "$LANGSMITH_API_KEY" "$SUPABASE_URL" "$SUPABASE_SERVICE_ROLE_KEY" "$LLM_PROVIDER" "$OPENAI_API_KEY" "$ANTHROPIC_API_KEY" "$LANGCHAIN_ENDPOINT" "$LANGCHAIN_PROJECT"

cd oap-langgraph-tools-agent

# Set up virtual environment and install dependencies
print_status "Installing Tools Agent dependencies..."
if [ ! -d ".venv" ]; then
    uv venv
fi
source .venv/bin/activate
uv sync

print_status "Starting Tools Agent on port $TOOLS_PORT..."
uv run langgraph dev --no-browser --port $TOOLS_PORT &
TOOLS_AGENT_PID=$!

cd ..

# 4. Set up Supervisor Agent
print_status "Setting up Supervisor Agent..."

if [ ! -d "oap-agent-supervisor" ]; then
    print_error "oap-agent-supervisor directory not found. Repository cloning may have failed."
    exit 1
fi

# Create .env file for Supervisor Agent
create_supervisor_agent_env "$LANGSMITH_API_KEY" "$SUPABASE_URL" "$SUPABASE_SERVICE_ROLE_KEY" "$LLM_PROVIDER" "$OPENAI_API_KEY" "$ANTHROPIC_API_KEY" "$LANGCHAIN_ENDPOINT" "$LANGCHAIN_PROJECT"

cd oap-agent-supervisor

# Set up virtual environment and install dependencies
print_status "Installing Supervisor Agent dependencies..."
if [ ! -d ".venv" ]; then
    uv venv
fi
source .venv/bin/activate
uv sync

print_status "Starting Supervisor Agent on port $SUPERVISOR_PORT..."
uv run langgraph dev --no-browser --port $SUPERVISOR_PORT &
SUPERVISOR_AGENT_PID=$!

cd ..

# 5. Set up Web Platform
print_status "Setting up Web Platform..."

if [ ! -d "open-agent-platform/apps/web" ]; then
    print_error "open-agent-platform/apps/web directory not found. Repository cloning may have failed."
    exit 1
fi

# Create .env file for Web Platform
create_web_platform_env "$SUPABASE_URL" "$SUPABASE_ANON_KEY" "$LANGSMITH_API_KEY" "$RAG_PORT" "$MCP_SERVER_URL" "$MCP_AUTH_REQUIRED" "$GOOGLE_AUTH_DISABLED" "$TOOLS_AGENT_ID" "$SUPERVISOR_AGENT_ID" "$TENANT_ID" "$TOOLS_PORT" "$SUPERVISOR_PORT" "$WEB_PORT" "$LANGCHAIN_ENDPOINT"

# Update agents with MCP server URL
print_status "Updating agents with MCP server configuration..."
cd open-agent-platform/apps/web
if npx tsx scripts/update-agents-mcp-url.ts; then
    print_status "Successfully updated all agents with MCP server URL"
else
    print_warning "Failed to update agents with MCP server URL, but continuing..."
fi
cd ../../..

cd open-agent-platform/apps/web

# Install dependencies
print_status "Installing Web Platform dependencies..."
yarn install

print_status "Building Web Platform for production..."
yarn build

print_status "Starting Web Platform in production mode on port $WEB_PORT..."
if [ "$WEB_PORT" != "3000" ]; then
    yarn start -p $WEB_PORT &
else
    yarn start &
fi
WEB_APP_PID=$!

cd ../../..

# Wait for services to start
print_status "Waiting for all services to start..."
sleep 20

# Final status and instructions
print_header "Setup Complete!"

echo -e "${GREEN}All services are now running:${NC}"
echo "- LangConnect RAG Server: http://localhost:$RAG_PORT"
echo "- Custom MCP Server: http://localhost:8002"
echo "- Tools Agent: http://localhost:$TOOLS_PORT"
echo "- Supervisor Agent: http://localhost:$SUPERVISOR_PORT"
echo "- Open Agent Platform: http://localhost:$WEB_PORT"

echo -e "\n${YELLOW}Environment files created:${NC}"
echo "- langconnect/.env (Docker Compose)"
echo "- oap-langgraph-tools-agent/.env"
echo "- oap-agent-supervisor/.env"
echo "- open-agent-platform/apps/web/.env"

echo -e "\n${YELLOW}Process IDs (for stopping services):${NC}"
if [ ! -z "$MCP_SERVER_PID" ]; then
    echo "- Custom MCP Server PID: $MCP_SERVER_PID"
fi
echo "- Tools Agent PID: $TOOLS_AGENT_PID"
echo "- Supervisor Agent PID: $SUPERVISOR_AGENT_PID"
echo "- Web App PID: $WEB_APP_PID"

echo -e "\n${BLUE}To stop all services, run:${NC}"
if [ ! -z "$MCP_SERVER_PID" ]; then
    echo "kill $MCP_SERVER_PID $TOOLS_AGENT_PID $SUPERVISOR_AGENT_PID $WEB_APP_PID 2>/dev/null || true"
else
    echo "kill $TOOLS_AGENT_PID $SUPERVISOR_AGENT_PID $WEB_APP_PID 2>/dev/null || true"
fi
echo "docker-compose -f langconnect/docker-compose.yml down"

echo -e "\n${GREEN}Your Open Agent Platform is ready at http://localhost:$WEB_PORT${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Open http://localhost:$WEB_PORT in your browser"
echo "2. Sign up/sign in with Supabase authentication"
echo "3. Create and configure your agents"
echo "4. Start building with the platform!"

# Automatically open the browser
print_status "Opening Open Agent Platform in your browser..."
open "http://localhost:$WEB_PORT"

# Save PIDs for stop script
cat > .oap_pids << EOF
MCP_SERVER_PID=$MCP_SERVER_PID
TOOLS_AGENT_PID=$TOOLS_AGENT_PID
SUPERVISOR_AGENT_PID=$SUPERVISOR_AGENT_PID
WEB_APP_PID=$WEB_APP_PID
RAG_PORT=$RAG_PORT
EOF

# Create enhanced stop script
cat > stop-oap.sh << EOF
#!/bin/bash
echo "Stopping Open Agent Platform services..."

# Load PIDs if they exist
if [ -f ".oap_pids" ]; then
    source .oap_pids
    
    # Stop background processes
    if [ ! -z "\$MCP_SERVER_PID" ]; then
        kill \$MCP_SERVER_PID 2>/dev/null || true
        echo "Stopped Custom MCP Server (PID: \$MCP_SERVER_PID)"
    fi
    if [ ! -z "\$TOOLS_AGENT_PID" ]; then
        kill \$TOOLS_AGENT_PID 2>/dev/null || true
        echo "Stopped Tools Agent (PID: \$TOOLS_AGENT_PID)"
    fi
    if [ ! -z "\$SUPERVISOR_AGENT_PID" ]; then
        kill \$SUPERVISOR_AGENT_PID 2>/dev/null || true
        echo "Stopped Supervisor Agent (PID: \$SUPERVISOR_AGENT_PID)"
    fi
    if [ ! -z "\$WEB_APP_PID" ]; then
        kill \$WEB_APP_PID 2>/dev/null || true
        echo "Stopped Web App (PID: \$WEB_APP_PID)"
    fi
    
    rm .oap_pids
else
    echo "No PID file found. Attempting to kill processes by port..."
    # Fallback: kill processes by port
    pkill -f "python main.py" 2>/dev/null || true
    pkill -f "langgraph dev.*port.*$TOOLS_PORT" 2>/dev/null || true
    pkill -f "langgraph dev.*port.*$SUPERVISOR_PORT" 2>/dev/null || true
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
EOF

chmod +x stop-oap.sh
echo -e "\n${GREEN}Created enhanced stop-oap.sh script to easily stop all services.${NC}"

# After cloning repositories, add initialization steps
print_header "Initializing Environments and Services"

# Initialize LangConnect
print_status "Setting up LangConnect..."
start_langconnect

# Initialize Tools Agent
print_status "Setting up Tools Agent..."
initialize_agent_env "oap-langgraph-tools-agent" "Tools Agent"
start_agent_service "oap-langgraph-tools-agent" "Tools Agent"

# Initialize Supervisor Agent
print_status "Setting up Supervisor Agent..."
initialize_agent_env "oap-agent-supervisor" "Supervisor Agent"
start_agent_service "oap-agent-supervisor" "Supervisor Agent"

# Initialize Open Agent Platform
print_status "Setting up Open Agent Platform..."
cd open-agent-platform
yarn install || {
    print_error "Failed to install Open Agent Platform dependencies"
    exit 1
}
cd ..

print_header "Setup Complete!"
print_status "All services have been initialized and started."
print_status "You can now access the Open Agent Platform at http://localhost:3000"
print_status "Tools Agent is running at http://localhost:2024"
print_status "Supervisor Agent is running at http://localhost:2025"
print_status "LangConnect is running at http://localhost:8080" 