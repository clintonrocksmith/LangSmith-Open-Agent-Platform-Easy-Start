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
TENANT_ID=$(get_json_value '.generated_ids.tenant_id')
TOOLS_AGENT_ID=$(get_json_value '.generated_ids.tools_agent_id')
SUPERVISOR_AGENT_ID=$(get_json_value '.generated_ids.supervisor_agent_id')

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

# Use modular scripts for setup
print_header "Setting Up Open Agent Platform"

print_status "Step 1: Cloning/Updating Repositories..."
./scripts/01-clone-repos.sh

print_status "Step 2: Setting up Environment Files..."
./scripts/02-setup-env.sh

print_status "Step 3: Initializing Virtual Environments..."
./scripts/03-init-envs.sh

print_status "Step 4: Starting All Services..."
./scripts/04-start-services.sh

# Get ports for final status
RAG_PORT=$(get_json_value '.ports.rag_server')
TOOLS_PORT=$(get_json_value '.ports.tools_agent')
SUPERVISOR_PORT=$(get_json_value '.ports.supervisor_agent')
WEB_PORT=$(get_json_value '.ports.web_app')

# Wait for services to start
print_status "Waiting for all services to start..."
sleep 10

# Final status and instructions
print_header "Setup Complete!"

echo -e "${GREEN}All services are now running:${NC}"
echo "- Open Agent Platform: http://localhost:$WEB_PORT"
echo "- Tools Agent: http://localhost:$TOOLS_PORT"
echo "- Supervisor Agent: http://localhost:$SUPERVISOR_PORT"
echo "- LangConnect RAG Server: http://localhost:$RAG_PORT"

echo -e "\n${YELLOW}Environment files created:${NC}"
echo "- langconnect/.env"
echo "- oap-langgraph-tools-agent/.env"
echo "- oap-agent-supervisor/.env"
echo "- open-agent-platform/apps/web/.env"
echo "- open-agent-platform/apps/web/.env.local"

echo -e "\n${GREEN}Your Open Agent Platform is ready at http://localhost:$WEB_PORT${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Open http://localhost:$WEB_PORT in your browser"
echo "2. Sign up/sign in with Supabase authentication"
echo "3. Create and configure your agents"
echo "4. Start building with the platform!"

echo -e "\n${BLUE}To stop all services, run:${NC}"
echo "./stop.sh"

# Automatically open the browser
print_status "Opening Open Agent Platform in your browser..."
open "http://localhost:$WEB_PORT"

print_status "Setup completed successfully!"
