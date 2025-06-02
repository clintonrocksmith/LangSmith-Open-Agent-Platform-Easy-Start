#!/usr/bin/env python3
"""
Custom MCP Server with Comprehensive Tools
Provides file operations, web scraping, API integrations, system utilities, and data processing.
"""

import uvicorn
from mcp.server import FastMCP

# Import all our tool modules
from tools.file_operations import register_file_tools
from tools.web_scraping import register_web_tools
from tools.api_integrations import register_api_tools
from tools.system_utilities import register_system_tools
from tools.data_processing import register_data_tools

# Initialize the MCP server
mcp = FastMCP("Custom MCP Server with Comprehensive Tools")

def main():
    """Main entry point for the MCP server."""
    
    print("🚀 Initializing Custom MCP Server...")
    print("📚 Registering tool categories:")
    
    # Register all tool categories
    print("  • File Operations (read, write, search, manage files)")
    register_file_tools(mcp)
    
    print("  • Web Scraping (extract content from websites)")
    register_web_tools(mcp)
    
    print("  • API Integrations (weather, news, utilities)")
    register_api_tools(mcp)
    
    print("  • System Utilities (commands, status, monitoring)")
    register_system_tools(mcp)
    
    print("  • Data Processing (CSV, JSON, text analysis)")
    register_data_tools(mcp)
    
    print("\n✅ All tools registered successfully!")
    print("\n🌐 Starting MCP Server with streamable HTTP transport")
    print("🏠 Server URL: http://localhost:8002")
    print("🔗 Compatible with Open Agent Platform")
    print("Press Ctrl+C to stop the server...")
    
    # Get the Starlette app and run it with uvicorn on port 8002
    app = mcp.streamable_http_app()
    uvicorn.run(app, host="0.0.0.0", port=8002)

if __name__ == "__main__":
    main() 