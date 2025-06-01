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
    cat > langconnect/.env << EOF
# API key for the embeddings model. Defaults to OpenAI embeddings
OPENAI_API_KEY=$openai_key

# PostgreSQL configuration
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$postgres_password
POSTGRES_DB=langconnect_dev

# CORS configuration. Must be a JSON array of strings
ALLOW_ORIGINS=["http://localhost:$web_port"]

# For authentication
SUPABASE_URL=$supabase_url
# This must be the service role key
SUPABASE_KEY=$supabase_service_key
EOF
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
    cat > oap-langgraph-tools-agent/.env << EOF
# ------------------LangSmith tracing------------------
LANGCHAIN_PROJECT="$langsmith_project"
LANGCHAIN_API_KEY=$langsmith_key
LANGCHAIN_TRACING_V2=true
LANGCHAIN_ENDPOINT=$langsmith_endpoint
# -----------------------------------------------------

# At least one of these must be set. Defaults to OpenAI models. Ensure this is consistent
# with what is expected for the default models that are set in the GraphConfigPydantic class in tools_agent/agent.py
EOF

    if [ "$llm_provider" = "openai" ] || [ -n "$openai_key" ]; then
        echo "OPENAI_API_KEY=$openai_key" >> oap-langgraph-tools-agent/.env
    fi
    
    if [ "$llm_provider" = "anthropic" ] || [ -n "$anthropic_key" ]; then
        echo "ANTHROPIC_API_KEY=$anthropic_key" >> oap-langgraph-tools-agent/.env
    fi
    
    cat >> oap-langgraph-tools-agent/.env << EOF

# For user level authentication
SUPABASE_URL=$supabase_url
# Ensure this is your Supabase Service Role key
SUPABASE_KEY=$supabase_service_key
EOF
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
    cat > oap-agent-supervisor/.env << EOF
# ------------------LangSmith tracing------------------
LANGCHAIN_PROJECT="$langsmith_project"
LANGCHAIN_API_KEY=$langsmith_key
LANGCHAIN_TRACING_V2=true
LANGCHAIN_ENDPOINT=$langsmith_endpoint
# -----------------------------------------------------

EOF

    if [ "$llm_provider" = "openai" ] || [ -n "$openai_key" ]; then
        echo "OPENAI_API_KEY=$openai_key" >> oap-agent-supervisor/.env
    fi
    
    if [ "$llm_provider" = "anthropic" ] || [ -n "$anthropic_key" ]; then
        echo "ANTHROPIC_API_KEY=$anthropic_key" >> oap-agent-supervisor/.env
    fi
    
    cat >> oap-agent-supervisor/.env << EOF

SUPABASE_URL=$supabase_url
# Ensure this is your Supabase Service Role key
SUPABASE_KEY=$supabase_service_key
EOF
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
    cat > open-agent-platform/apps/web/.env.local << EOF
# The base API URL for the platform.
# Defaults to \`http://localhost:3000/api\` for development
NEXT_PUBLIC_BASE_API_URL="http://localhost:$web_port/api"

# LangSmith API key required for some admin tasks.
LANGSMITH_API_KEY="$langsmith_key"
# Whether or not to always use LangSmith auth (API key). If true, you will
# not get user scoped auth by default
NEXT_PUBLIC_USE_LANGSMITH_AUTH="false"
# LangSmith endpoint (optional)
LANGCHAIN_ENDPOINT="$langsmith_endpoint"

# The deployments to make available in the UI
NEXT_PUBLIC_DEPLOYMENTS=[{"id":"$tools_agent_id","deploymentUrl":"http://localhost:$tools_port","tenantId":"$tenant_id","name":"Tools Agent (Local)","isDefault":true,"defaultGraphId":"agent"},{"id":"$supervisor_agent_id","deploymentUrl":"http://localhost:$supervisor_port","tenantId":"$tenant_id","name":"Supervisor Agent (Local)","isDefault":false,"defaultGraphId":"agent"}]

# The RAG API URL for the platform.
NEXT_PUBLIC_RAG_API_URL="http://localhost:$rag_port"

# The base URL to the MCP server. Do not include the \`/mcp\` at the end.
NEXT_PUBLIC_MCP_SERVER_URL="$mcp_server_url"
# Whether or not the MCP server requires authentication.
# If true, all requests to the MCP server will go through a proxy
# route first.
NEXT_PUBLIC_MCP_AUTH_REQUIRED="$mcp_auth_required"

# Supabase Authentication
NEXT_PUBLIC_SUPABASE_ANON_KEY="$supabase_anon_key"
NEXT_PUBLIC_SUPABASE_URL="$supabase_url"

# Disable showing Google Auth in the UI
# Defaults to false.
NEXT_PUBLIC_GOOGLE_AUTH_DISABLED="$google_auth_disabled"
EOF
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

print_header "Open Agent Platform Setup from JSON Configuration"

# Check for required commands
for cmd in docker docker-compose jq git; do
    if ! command_exists "$cmd"; then
        print_error "$cmd is required but not installed. Please install it first."
        exit 1
    fi
done

# Clone repositories
OPEN_AGENT_PLATFORM_URL="https://github.com/langchain-ai/open-agent-platform.git"
TOOLS_AGENT_URL="https://github.com/langchain-ai/oap-langgraph-tools-agent.git"
SUPERVISOR_AGENT_URL="https://github.com/langchain-ai/oap-agent-supervisor.git"
LANGCONNECT_URL="https://github.com/langchain-ai/langconnect.git"

clone_or_update_repo "$OPEN_AGENT_PLATFORM_URL" "open-agent-platform" "Open Agent Platform"
clone_or_update_repo "$TOOLS_AGENT_URL" "oap-langgraph-tools-agent" "Tools Agent"
clone_or_update_repo "$SUPERVISOR_AGENT_URL" "oap-agent-supervisor" "Supervisor Agent"
clone_or_update_repo "$LANGCONNECT_URL" "langconnect" "LangConnect"

# Get values from JSON
SUPABASE_URL=$(get_json_value ".supabase.url")
SUPABASE_ANON_KEY=$(get_json_value ".supabase.anon_key")
SUPABASE_SERVICE_KEY=$(get_json_value ".supabase.service_role_key")
POSTGRES_PASSWORD=$(get_json_value ".supabase.password")
LANGSMITH_KEY=$(get_json_value ".langsmith.api_key")
LANGSMITH_ENDPOINT=$(get_json_value ".langsmith.endpoint")
LANGSMITH_PROJECT=$(get_json_value ".langsmith.project")
LLM_PROVIDER=$(get_json_value ".llm.provider")
OPENAI_KEY=$(get_json_value ".llm.openai_api_key")
ANTHROPIC_KEY=$(get_json_value ".llm.anthropic_api_key")
MCP_SERVER_URL=$(get_json_value ".mcp.server_url")
MCP_AUTH_REQUIRED=$(get_json_value ".mcp.auth_required")
GOOGLE_AUTH_DISABLED=$(get_json_value ".settings.google_auth_disabled")
RAG_PORT=$(get_json_value ".ports.rag_server")
TOOLS_PORT=$(get_json_value ".ports.tools_agent")
SUPERVISOR_PORT=$(get_json_value ".ports.supervisor_agent")
WEB_PORT=$(get_json_value ".ports.web_app")

# Generate or get IDs
TENANT_ID=$(get_json_value ".generated_ids.tenant_id")
if [ -z "$TENANT_ID" ] || [ "$TENANT_ID" = "null" ]; then
    TENANT_ID=$(generate_uuid)
    update_json_value ".generated_ids.tenant_id" "$TENANT_ID"
fi

TOOLS_AGENT_ID=$(get_json_value ".generated_ids.tools_agent_id")
if [ -z "$TOOLS_AGENT_ID" ] || [ "$TOOLS_AGENT_ID" = "null" ]; then
    TOOLS_AGENT_ID=$(generate_uuid)
    update_json_value ".generated_ids.tools_agent_id" "$TOOLS_AGENT_ID"
fi

SUPERVISOR_AGENT_ID=$(get_json_value ".generated_ids.supervisor_agent_id")
if [ -z "$SUPERVISOR_AGENT_ID" ] || [ "$SUPERVISOR_AGENT_ID" = "null" ]; then
    SUPERVISOR_AGENT_ID=$(generate_uuid)
    update_json_value ".generated_ids.supervisor_agent_id" "$SUPERVISOR_AGENT_ID"
fi

# Create .env files
create_langconnect_env "$SUPABASE_URL" "$SUPABASE_SERVICE_KEY" "$OPENAI_KEY" "$POSTGRES_PASSWORD" "$WEB_PORT"
create_tools_agent_env "$LANGSMITH_KEY" "$SUPABASE_URL" "$SUPABASE_SERVICE_KEY" "$LLM_PROVIDER" "$OPENAI_KEY" "$ANTHROPIC_KEY" "$LANGSMITH_ENDPOINT" "$LANGSMITH_PROJECT"
create_supervisor_agent_env "$LANGSMITH_KEY" "$SUPABASE_URL" "$SUPABASE_SERVICE_KEY" "$LLM_PROVIDER" "$OPENAI_KEY" "$ANTHROPIC_KEY" "$LANGSMITH_ENDPOINT" "$LANGSMITH_PROJECT"
create_web_platform_env "$SUPABASE_URL" "$SUPABASE_ANON_KEY" "$LANGSMITH_KEY" "$RAG_PORT" "$MCP_SERVER_URL" "$MCP_AUTH_REQUIRED" "$GOOGLE_AUTH_DISABLED" "$TOOLS_AGENT_ID" "$SUPERVISOR_AGENT_ID" "$TENANT_ID" "$TOOLS_PORT" "$SUPERVISOR_PORT" "$WEB_PORT" "$LANGSMITH_ENDPOINT"

print_header "Setup Complete"
print_status "Environment files have been created. You can now compare them with the .env.example files in each repository." 