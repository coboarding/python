#!/bin/bash
set -e

# Test all YAML/YML files for syntax
find . -type f \( -name '*.yml' -o -name '*.yaml' \) | while read -r file; do
  echo "Testing YAML syntax: $file"
  python3 -c "import sys, yaml; yaml.safe_load(open(sys.argv[1]))" "$file" || exit 1
done

echo "All YAML/YML files passed syntax check."

# Test all Dockerfiles with hadolint if available, else basic syntax via docker
if command -v hadolint &> /dev/null; then
  find . -type f -name 'Dockerfile*' | while read -r file; do
    echo "Linting Dockerfile: $file"
    hadolint "$file" || exit 1
  done
else
  find . -type f -name 'Dockerfile*' | while read -r file; do
    echo "Checking Dockerfile syntax: $file"
    docker run --rm -i hadolint/hadolint < "$file" || exit 1
  done
fi

echo "All Dockerfiles passed lint/syntax check."

# Test all JSON files for syntax
find . -type f -name '*.json' | while read -r file; do
  echo "Testing JSON syntax: $file"
  python3 -m json.tool "$file" > /dev/null || exit 1
done

echo "All JSON files passed syntax check."

echo "All declarative files are valid!"
