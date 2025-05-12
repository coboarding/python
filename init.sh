#!/bin/bash

# Function to create directory structure with comments
create_project_structure() {
    # Main project directory
    mkdir -p AutoFormFiller-Pro
    cd AutoFormFiller-Pro

    # Containers directory and its subdirectories
    mkdir -p containers/browser-service/browsers
    mkdir -p containers/browser-service/extensions/chrome
    mkdir -p containers/browser-service/extensions/firefox
    mkdir -p containers/browser-service/scripts
    # Create files in browser-service
    touch containers/browser-service/Dockerfile
    touch containers/browser-service/browsers/chrome-setup.sh
    touch containers/browser-service/browsers/firefox-setup.sh
    touch containers/browser-service/supervisord.conf
    touch containers/browser-service/scripts/form-fill.py

    # LLM Orchestrator
    mkdir -p containers/llm-orchestrator/model-configs
    mkdir -p containers/llm-orchestrator/data
    touch containers/llm-orchestrator/Dockerfile
    touch containers/llm-orchestrator/api.py
    touch containers/llm-orchestrator/detect-hardware.py
    touch containers/llm-orchestrator/pipeline_generator.py
    touch containers/llm-orchestrator/model-configs/cpu-configs.json
    touch containers/llm-orchestrator/model-configs/gpu-configs.json
    touch containers/llm-orchestrator/data/job_portals_knowledge.json

    # NoVNC
    mkdir -p containers/novnc
    touch containers/novnc/Dockerfile

    # Web Terminal
    mkdir -p containers/web-terminal
    touch containers/web-terminal/Dockerfile
    touch containers/web-terminal/startup.sh

    # Test Forms Server
    mkdir -p containers/test-forms-server/forms
    touch containers/test-forms-server/Dockerfile
    touch containers/test-forms-server/nginx.conf
    touch containers/test-forms-server/forms/simple-form.html
    touch containers/test-forms-server/forms/complex-form.html
    touch containers/test-forms-server/forms/file-upload-form.html

    # Test Runner
    mkdir -p containers/test-runner/tests
    touch containers/test-runner/Dockerfile
    touch containers/test-runner/tests/run-tests.py
    touch containers/test-runner/tests/test-simple-form.py
    touch containers/test-runner/tests/test-complex-form.py
    touch containers/test-runner/tests/test-file-upload.py

    # Web Interface
    mkdir -p containers/web-interface/src/components
    mkdir -p containers/web-interface/public
    touch containers/web-interface/Dockerfile
    touch containers/web-interface/nginx.conf
    touch containers/web-interface/package.json
    touch containers/web-interface/src/App.js
    touch containers/web-interface/src/App.css
    touch containers/web-interface/src/index.js
    touch containers/web-interface/src/index.css
    touch containers/web-interface/src/components/VoiceControl.js
    touch containers/web-interface/public/index.html

    # Volumes
    mkdir -p volumes/cv
    mkdir -p volumes/models
    mkdir -p volumes/config/pipelines
    mkdir -p volumes/passwords
    mkdir -p volumes/recordings

    # Project root files
    touch docker-compose.yml
    touch .env
    touch init.sh
    touch run.sh
    touch setup-all.sh
    touch run-tests.sh
    touch requirements.txt
    touch config.ini
    touch LICENSE
    touch README.md

    # Add comments to some key files
    echo "# AutoFormFiller-Pro Project Setup" > README.md

    echo "# Docker Compose configuration for AutoFormFiller-Pro" > docker-compose.yml

    echo "# Environment variables for the project" > .env

    echo "#!/bin/bash
# Initialize the entire AutoFormFiller-Pro project
# This script sets up all necessary components and dependencies" > init.sh
    chmod +x init.sh

    echo "# Configuration for browser automation and form filling" > containers/browser-service/supervisord.conf

    echo "# Main API entry point for LLM Orchestrator" > containers/llm-orchestrator/api.py

    echo "# Web interface main React component" > containers/web-interface/src/App.js
}

# Execute the function
create_project_structure

echo "Project structure created successfully in $(pwd)"