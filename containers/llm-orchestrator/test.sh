#!/bin/bash
# Test podstawowy: sprawdzenie działania API llm-orchestrator
set -e
curl -X POST http://localhost:5000/fill-form -H "Content-Type: application/json" -d '{"form_url":"http://test.com","cv_path":"/volumes/cv/example_cv.html"}'
