#!/bin/bash

# Function to clone or update a repository
clone_or_update_repo() {
    local repo_name=$1
    local repo_url=$2
    
    if [ -d "$repo_name" ]; then
        echo "Updating $repo_name..."
        cd "$repo_name"
        git pull
        cd ..
    else
        echo "Cloning $repo_name..."
        git clone "$repo_url"
    fi
}

# Clone or update repositories
clone_or_update_repo "open-agent-platform" "https://github.com/langchain-ai/open-agent-platform.git"
clone_or_update_repo "oap-langgraph-tools-agent" "https://github.com/langchain-ai/oap-langgraph-tools-agent.git"
clone_or_update_repo "oap-agent-supervisor" "https://github.com/langchain-ai/oap-agent-supervisor.git"
clone_or_update_repo "langconnect" "https://github.com/langchain-ai/langconnect.git"

echo "Repository cloning/updating completed!" 