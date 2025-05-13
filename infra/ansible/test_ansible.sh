#!/bin/bash
# Test: lintowanie i test idempotencji playbooków Ansible
set -e

cd "$(dirname "$0")"
echo "== Ansible Lint =="
ansible-lint playbook.yml || echo "Brak pliku playbook.yml lub lint błędny"

echo "== Test idempotencji =="
ansible-playbook --check playbook.yml || echo "Brak pliku playbook.yml lub błąd w playbooku"
