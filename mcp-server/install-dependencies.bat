@echo off
setlocal enabledelayedexpansion

echo 🚀 Setting up MCP Server dependencies...

:: Check if we're in a virtual environment
if "%VIRTUAL_ENV%"=="" (
    echo ❌ No virtual environment detected. Please activate the virtual environment first:
    echo    Scripts\activate
    exit /b 1
) else (
    echo ✅ Virtual environment detected: %VIRTUAL_ENV%
)

:: Install dependencies
echo 📦 Installing Python dependencies...
python -m pip install --upgrade pip
if %errorlevel% neq 0 exit /b %errorlevel%

python -m pip install -r requirements.txt
if %errorlevel% neq 0 exit /b %errorlevel%

:: Test imports
echo 🔍 Testing imports...
python -c "import uvicorn; from mcp.server import FastMCP; import aiohttp; import requests; import pandas; print('✅ All imports successful')"
if %errorlevel% neq 0 exit /b %errorlevel%

echo 🎉 MCP Server setup complete!
echo.
echo To run the server:
echo 1. cd custom_mcp_server
echo 2. python main.py
echo.
echo The server will be available at http://localhost:8002
