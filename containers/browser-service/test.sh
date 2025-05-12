#!/bin/bash
# Test: sprawdzenie działania browser-service
set -e
curl -X POST http://localhost:5001/fill-form -H "Content-Type: application/json" -d '{"form_url":"http://test.com","cv_path":"/volumes/cv/example_cv.html"}'
