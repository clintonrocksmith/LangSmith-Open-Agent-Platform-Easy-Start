# Open Agent Platform - LangSmith Setup

## Build/Test/Start Commands
- **Setup**: `./setup-from-json.sh` - Main setup script using values.json configuration
- **Start services**: `./start.sh` or `./scripts/04-start-services.sh`
- **Stop services**: `./stop.sh`
- **MCP Server**: `cd mcp-server && source bin/activate && cd custom_mcp_server && python main.py` (Unix) or `cd mcp-server && Scripts\activate && cd custom_mcp_server && python main.py` (Windows)
- **Individual agent**: `cd oap-langgraph-tools-agent && source .venv/bin/activate && uv run langgraph dev --port 2024` (Unix) or `.venv\Scripts\activate` (Windows)
- **Windows compatibility**: All scripts auto-detect Windows and use appropriate commands (taskkill vs pkill, Scripts vs bin, start vs open)

## Architecture
- **LangConnect**: Docker-based RAG server (port 8080)
- **Tools Agent**: Python/LangGraph service (port 2024) - handles tool execution
- **Supervisor Agent**: Python/LangGraph service (port 2025) - orchestrates agent workflows
- **Web Platform**: Next.js frontend (port 3000) - main UI
- **MCP Server**: Custom FastMCP server (port 8002) with file ops, web scraping, APIs, system utils, data processing

## Code Style
- **Python**: Pydantic models for tool parameters, type hints, descriptive docstrings
- **Config**: JSON-based configuration in values.json with validation
- **Naming**: snake_case for Python, descriptive function names
- **Error handling**: Graceful degradation, informative error messages
- **Structure**: Modular bash scripts, separated tool categories in MCP server
