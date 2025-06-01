#!/bin/bash

# Check if values.json exists
if [ ! -f "values.json" ]; then
    echo "Error: values.json not found!"
    exit 1
fi

# Function to create .env file from example
create_env_file() {
    local dir=$1
    local example_file=$2
    local env_file=$3
    
    if [ -f "$dir/$example_file" ]; then
        echo "Creating $env_file from $example_file..."
        cp "$dir/$example_file" "$dir/$env_file"
    else
        echo "Warning: $example_file not found in $dir"
    fi
}

# Function to update environment variables in a file
update_env_file() {
    local file=$1
    local key=$2
    local value=$3
    local quote_value=${4:-true}  # Default to true, can be overridden
    
    if [ -f "$file" ]; then
        # Only update if the key exists in the file (don't add new keys)
        if grep -q "^$key=" "$file"; then
            if [ "$quote_value" = "true" ]; then
                sed -i.bak "s|^$key=.*|$key=\"$value\"|" "$file"
            else
                sed -i.bak "s|^$key=.*|$key=$value|" "$file"
            fi
            rm -f "${file}.bak"
        else
            echo "Warning: $key not found in $file, skipping..."
        fi
    fi
}

# Create .env files for each component
create_env_file "langconnect" ".env.example" ".env"
create_env_file "oap-langgraph-tools-agent" ".env.example" ".env"
create_env_file "oap-agent-supervisor" ".env.example" ".env"

# Handle web app environment files
if [ -f "open-agent-platform/apps/web/.env.example" ]; then
    echo "Creating .env.local for web app..."
    cp "open-agent-platform/apps/web/.env.example" "open-agent-platform/apps/web/.env.local"
    echo "Creating .env for web app..."
    cp "open-agent-platform/apps/web/.env.example" "open-agent-platform/apps/web/.env"
else
    echo "Warning: .env.example not found in open-agent-platform/apps/web"
fi

# Update environment variables from values.json
echo "Updating environment variables from values.json..."

# Extract values from nested JSON structure
SUPABASE_URL=$(jq -r '.supabase.url' values.json)
SUPABASE_ANON_KEY=$(jq -r '.supabase.anon_key' values.json)
SUPABASE_SERVICE_KEY=$(jq -r '.supabase.service_role_key' values.json)
POSTGRES_PASSWORD=$(jq -r '.supabase.password' values.json)

LANGCHAIN_API_KEY=$(jq -r '.langsmith.api_key' values.json)
LANGCHAIN_ENDPOINT=$(jq -r '.langsmith.endpoint' values.json)
LANGCHAIN_PROJECT=$(jq -r '.langsmith.project' values.json)

OPENAI_API_KEY=$(jq -r '.llm.openai_api_key' values.json)
ANTHROPIC_API_KEY=$(jq -r '.llm.anthropic_api_key' values.json)

# Update LangConnect .env
update_env_file "langconnect/.env" "SUPABASE_URL" "$SUPABASE_URL"
update_env_file "langconnect/.env" "SUPABASE_KEY" "$SUPABASE_SERVICE_KEY"
# Don't update POSTGRES_PASSWORD - keep the original value from .env.example
update_env_file "langconnect/.env" "OPENAI_API_KEY" "$OPENAI_API_KEY"

# Update Tools Agent .env
update_env_file "oap-langgraph-tools-agent/.env" "SUPABASE_URL" "$SUPABASE_URL"
update_env_file "oap-langgraph-tools-agent/.env" "SUPABASE_KEY" "$SUPABASE_SERVICE_KEY"
update_env_file "oap-langgraph-tools-agent/.env" "LANGCHAIN_API_KEY" "$LANGCHAIN_API_KEY"
update_env_file "oap-langgraph-tools-agent/.env" "LANGCHAIN_ENDPOINT" "$LANGCHAIN_ENDPOINT"
update_env_file "oap-langgraph-tools-agent/.env" "LANGCHAIN_PROJECT" "$LANGCHAIN_PROJECT"
update_env_file "oap-langgraph-tools-agent/.env" "OPENAI_API_KEY" "$OPENAI_API_KEY"
update_env_file "oap-langgraph-tools-agent/.env" "ANTHROPIC_API_KEY" "$ANTHROPIC_API_KEY"

# Update Supervisor Agent .env
update_env_file "oap-agent-supervisor/.env" "SUPABASE_URL" "$SUPABASE_URL"
update_env_file "oap-agent-supervisor/.env" "SUPABASE_KEY" "$SUPABASE_SERVICE_KEY"
update_env_file "oap-agent-supervisor/.env" "LANGCHAIN_API_KEY" "$LANGCHAIN_API_KEY"
update_env_file "oap-agent-supervisor/.env" "LANGCHAIN_ENDPOINT" "$LANGCHAIN_ENDPOINT"
update_env_file "oap-agent-supervisor/.env" "LANGCHAIN_PROJECT" "$LANGCHAIN_PROJECT"
update_env_file "oap-agent-supervisor/.env" "OPENAI_API_KEY" "$OPENAI_API_KEY"
update_env_file "oap-agent-supervisor/.env" "ANTHROPIC_API_KEY" "$ANTHROPIC_API_KEY"

# Get additional values for web platform
WEB_PORT=$(jq -r '.ports.web_app' values.json)
RAG_PORT=$(jq -r '.ports.rag_server' values.json)
TOOLS_PORT=$(jq -r '.ports.tools_agent' values.json)
SUPERVISOR_PORT=$(jq -r '.ports.supervisor_agent' values.json)
MCP_SERVER_URL=$(jq -r '.mcp.server_url' values.json)
MCP_AUTH_REQUIRED=$(jq -r '.mcp.auth_required' values.json)
GOOGLE_AUTH_DISABLED=$(jq -r '.settings.google_auth_disabled' values.json)
TENANT_ID=$(jq -r '.generated_ids.tenant_id' values.json)
TOOLS_AGENT_ID=$(jq -r '.generated_ids.tools_agent_id' values.json)
SUPERVISOR_AGENT_ID=$(jq -r '.generated_ids.supervisor_agent_id' values.json)

# Create deployments JSON
DEPLOYMENTS="[{\"id\":\"$TOOLS_AGENT_ID\",\"deploymentUrl\":\"http://localhost:$TOOLS_PORT\",\"tenantId\":\"$TENANT_ID\",\"name\":\"Tools Agent (Local)\",\"isDefault\":true,\"defaultGraphId\":\"agent\"},{\"id\":\"$SUPERVISOR_AGENT_ID\",\"deploymentUrl\":\"http://localhost:$SUPERVISOR_PORT\",\"tenantId\":\"$TENANT_ID\",\"name\":\"Supervisor Agent (Local)\",\"isDefault\":false,\"defaultGraphId\":\"agent\"}]"

# Update Web App .env and .env.local
update_env_file "open-agent-platform/apps/web/.env" "NEXT_PUBLIC_BASE_API_URL" "http://localhost:$WEB_PORT/api"
update_env_file "open-agent-platform/apps/web/.env" "LANGSMITH_API_KEY" "$LANGCHAIN_API_KEY"
update_env_file "open-agent-platform/apps/web/.env" "NEXT_PUBLIC_DEPLOYMENTS" "$DEPLOYMENTS"
update_env_file "open-agent-platform/apps/web/.env" "NEXT_PUBLIC_RAG_API_URL" "http://localhost:$RAG_PORT"
update_env_file "open-agent-platform/apps/web/.env" "NEXT_PUBLIC_MCP_SERVER_URL" "$MCP_SERVER_URL"
update_env_file "open-agent-platform/apps/web/.env" "NEXT_PUBLIC_MCP_AUTH_REQUIRED" "$MCP_AUTH_REQUIRED" false
update_env_file "open-agent-platform/apps/web/.env" "NEXT_PUBLIC_SUPABASE_ANON_KEY" "$SUPABASE_ANON_KEY"
update_env_file "open-agent-platform/apps/web/.env" "NEXT_PUBLIC_SUPABASE_URL" "$SUPABASE_URL"
update_env_file "open-agent-platform/apps/web/.env" "NEXT_PUBLIC_GOOGLE_AUTH_DISABLED" "$GOOGLE_AUTH_DISABLED" false

update_env_file "open-agent-platform/apps/web/.env.local" "NEXT_PUBLIC_BASE_API_URL" "http://localhost:$WEB_PORT/api"
update_env_file "open-agent-platform/apps/web/.env.local" "LANGSMITH_API_KEY" "$LANGCHAIN_API_KEY"
update_env_file "open-agent-platform/apps/web/.env.local" "NEXT_PUBLIC_DEPLOYMENTS" "$DEPLOYMENTS"
update_env_file "open-agent-platform/apps/web/.env.local" "NEXT_PUBLIC_RAG_API_URL" "http://localhost:$RAG_PORT"
update_env_file "open-agent-platform/apps/web/.env.local" "NEXT_PUBLIC_MCP_SERVER_URL" "$MCP_SERVER_URL"
update_env_file "open-agent-platform/apps/web/.env.local" "NEXT_PUBLIC_MCP_AUTH_REQUIRED" "$MCP_AUTH_REQUIRED" false
update_env_file "open-agent-platform/apps/web/.env.local" "NEXT_PUBLIC_SUPABASE_ANON_KEY" "$SUPABASE_ANON_KEY"
update_env_file "open-agent-platform/apps/web/.env.local" "NEXT_PUBLIC_SUPABASE_URL" "$SUPABASE_URL"
update_env_file "open-agent-platform/apps/web/.env.local" "NEXT_PUBLIC_GOOGLE_AUTH_DISABLED" "$GOOGLE_AUTH_DISABLED" false

echo "Environment setup completed!" 