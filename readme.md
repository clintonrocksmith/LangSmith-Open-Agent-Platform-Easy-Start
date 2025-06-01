# Open Agent Platform - JSON Configuration Setup

This setup approach uses a JSON configuration file (`values.json`) to store all the necessary configuration values, making it easier to manage and reproduce setups.

## Quick Start

1. **Edit `values.json`** with your actual configuration values
2. **Run the setup script**: `./setup-from-json.sh`
3. **Access your platform** at http://localhost:3000

## Prerequisites

Before running the setup, ensure you have:

- [Docker](https://docker.com) and Docker Compose
- [Node.js](https://nodejs.org) and [Yarn](https://yarnpkg.com)
- [uv](https://astral.sh/uv) Python package manager
- [jq](https://stedolan.github.io/jq/) JSON processor
  - macOS: `brew install jq`
  - Ubuntu/Debian: `apt-get install jq`

## Configuration

### Step 1: Update values.json

Edit the `values.json` file with your actual values:

```json
{
  "supabase": {
    "url": "https://your-project.supabase.co",
    "anon_key": "your_supabase_anon_key", 
    "service_role_key": "your_supabase_service_role_key"
  },
  "langsmith": {
    "api_key": "your_langsmith_api_key"
  },
  "llm": {
    "provider": "openai",
    "openai_api_key": "your_openai_api_key",
    "anthropic_api_key": "",
    "google_api_key": ""
  },
  "mcp": {
    "server_url": "https://your-mcp-server.com",
    "auth_required": false
  },
  "ports": {
    "rag_server": 8080,
    "tools_agent": 2024,
    "supervisor_agent": 2025,
    "web_app": 3000
  },
  "generated_ids": {
    "tenant_id": "",
    "tools_agent_id": "",
    "supervisor_agent_id": ""
  },
  "settings": {
    "google_auth_disabled": true,
    "run_locally": true
  }
}
```

### Required Values

#### Supabase Setup
1. Create account at [supabase.com](https://supabase.com)
2. Create a new project
3. Go to Settings > API to get:
   - Project URL (`url`)
   - Anon public key (`anon_key`)
   - Service role key (`service_role_key`)

#### LangSmith Setup
1. Create account at [smith.langchain.com](https://smith.langchain.com)
2. Go to Settings to get your API key

#### LLM Provider Setup
Choose one of:
- **OpenAI**: Get API key from [platform.openai.com](https://platform.openai.com)
- **Anthropic**: Get API key from [console.anthropic.com](https://console.anthropic.com)
- **Google**: Get API key from [ai.google.dev](https://ai.google.dev)

#### Optional: MCP Server
- If you have an MCP server (like Arcade), add the URL
- Set `auth_required` to `true` if authentication is needed

### Step 2: Run Setup

```bash
./setup-from-json.sh
```

The script will:
1. Validate your configuration
2. Generate UUIDs for local deployments (if not provided)
3. Set up and start all services:
   - LangConnect RAG Server
   - Tools Agent
   - Supervisor Agent
   - Web Platform

## Services

After setup, these services will be running:

| Service | Default Port | URL |
|---------|--------------|-----|
| Open Agent Platform | 3000 | http://localhost:3000 |
| LangConnect RAG Server | 8080 | http://localhost:8080 |
| Tools Agent | 2024 | http://localhost:2024 |
| Supervisor Agent | 2025 | http://localhost:2025 |

## Environment Files Created

The script creates these environment files:
- `langconnect/.env` - Docker Compose configuration
- `oap-langgraph-tools-agent/.env` - Tools Agent configuration
- `oap-agent-supervisor/.env` - Supervisor Agent configuration
- `open-agent-platform/apps/web/.env.local` - Web app configuration

## Stopping Services

Use the generated stop script:
```bash
./stop-oap.sh
```

Or manually:
```bash
# Stop background processes (replace with actual PIDs)
kill [TOOLS_AGENT_PID] [SUPERVISOR_AGENT_PID] [WEB_APP_PID]

# Stop Docker services
docker-compose -f langconnect/docker-compose.yml down
```

## Troubleshooting

### Port Conflicts
If you get port conflicts, update the ports in `values.json` and re-run the setup.

### Missing Dependencies
Ensure all prerequisites are installed:
```bash
# Check installations
docker --version
docker-compose --version
uv --version
yarn --version
node --version
jq --version
```

### Service Startup Issues
Check individual service logs:
```bash
# Check Docker logs
docker-compose -f langconnect/docker-compose.yml logs

# Check if ports are in use
lsof -i :3000  # Web app
lsof -i :8080  # RAG server
lsof -i :2024  # Tools agent
lsof -i :2025  # Supervisor agent
```

### Configuration Issues
Verify your `values.json` is valid JSON:
```bash
jq . values.json
```

## Advanced Configuration

### Custom Ports
Update the `ports` section in `values.json`:
```json
"ports": {
  "rag_server": 8081,
  "tools_agent": 2026,
  "supervisor_agent": 2027,
  "web_app": 3001
}
```

### Different LLM Providers
Change the `provider` and set the corresponding API key:
```json
"llm": {
  "provider": "anthropic",
  "anthropic_api_key": "your_anthropic_key"
}
```

### Production Deployment
For production, update these settings:
```json
"settings": {
  "google_auth_disabled": false,
  "run_locally": false
}
```

## Next Steps

1. Open http://localhost:3000 in your browser
2. Sign up/sign in with Supabase authentication
3. Configure your agents in the platform
4. Start building with the Open Agent Platform!

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Ensure your `values.json` has valid configuration values
4. Check that no other services are using the configured ports 