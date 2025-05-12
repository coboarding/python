#!/bin/bash
# Test: sprawdzenie działania serwera test-forms-server
set -e
curl -I http://localhost:8090/forms/example.html
