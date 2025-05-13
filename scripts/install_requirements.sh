# Funkcja do instalacji wymaganych pakietów systemowych
install_requirements() {
  install_package docker docker
  install_package docker-compose docker-compose
  install_package terraform terraform
  install_package ansible ansible
  install_package python3-pip pip3
  if ! command -v pip3 >/dev/null 2>&1; then
    echo -e "${RED}Pip nadal nie jest zainstalowany! Spróbuj zainstalować ręcznie python3-pip.${NC}"
    install_package python3-pip pip3
  fi
  return 0
}
