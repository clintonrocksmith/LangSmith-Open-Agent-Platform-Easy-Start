#!/bin/bash

# Function to initialize agent environment
init_agent_env() {
    local agent_dir=$1
    echo "Initializing environment for $agent_dir..."
    
    cd "$agent_dir"
    
    # Create virtual environment
    echo "Creating virtual environment..."
    uv venv
    
    # Activate virtual environment
    source .venv/bin/activate
    
    # Install dependencies
    echo "Installing dependencies..."
    uv sync
    
    # Deactivate virtual environment
    deactivate
    
    cd ..
}

# Initialize environments for each agent
init_agent_env "oap-langgraph-tools-agent"
init_agent_env "oap-agent-supervisor"

# Initialize web platform (different setup - Next.js app)
echo "Initializing environment for open-agent-platform web app..."
cd "open-agent-platform/apps/web"
echo "Installing dependencies..."
yarn install
cd ../../..

echo "Environment initialization completed!" 