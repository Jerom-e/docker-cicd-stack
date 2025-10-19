#!/usr/bin/env bash
# livraison.sh -- Install Docker + Compose plugin (on Debian 12/13) and coding stacks.
# Usage: sudo ./livraison.sh [--no-start]
set -euo pipefail


BASE_DIR="/opt/docker/gitlab"
SUBDIRS=("config" "logs" "data" "runner")

NO_START=false
if [ "${1:-}" = "--no-start" ]; then
  NO_START=true
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (sudo)." >&2
  exit 2
fi

echo "Updating apt and installing prerequisites..."
apt update
apt install -y ca-certificates curl gnupg lsb-release


echo "Creating Docker network 'dev-net' if it does not exist..."
if ! docker network ls --format '{{.Name}}' | grep -q 'dev-net$'; then
  docker network create --subnet=10.0.0.0/24 dev-net || true
fi

# Create Gitlab volume folder


echo "📁 Vérification et création des dossiers GitLab..."

for dir in "${SUBDIRS[@]}"; do
    FULL_PATH="${BASE_DIR}/${dir}"
    if [ ! -d "$FULL_PATH" ]; then
        echo "🆕 Création du dossier : $FULL_PATH"
        sudo mkdir -p "$FULL_PATH"
    else
        echo "✅ Dossier déjà présent : $FULL_PATH"
    fi
done
# Create Gitlab /etc/hosts entry 
echo "10.0.0.10 git.devtools.local" >> /etc/hosts

export GITLAB_HOME=/opt/docker/gitlab

# Deploy stacks in order: monitoring → administration → development → production
deploy_stack() {
  local dir="$1"
  echo
  echo "---- Deploying stack in ${dir} ----"
  pushd "${dir}" >/dev/null
  if [ "$NO_START" = true ]; then
    echo "Skipping 'docker compose up' because --no-start was provided."
  else
    # Use 'docker compose' (compose plugin). If not present, fall back to 'docker-compose' if installed.
    if command -v docker >/dev/null && docker compose version >/dev/null 2>&1; then
      docker compose up -d
    elif command -v docker-compose >/dev/null; then
      docker-compose up -d
    else
      echo "No compose command found (neither 'docker compose' nor 'docker-compose')." >&2
      popd >/dev/null
      return 1
    fi
  fi
  popd >/dev/null
}


# Order
deploy_stack "serveur"


# Tant que GitLab ne répond pas sur l'URL, on attend
until curl -sSf http://git.devtools.local/users/sign_in >/dev/null 2>&1; do
  echo "⏳ GitLab pas encore prêt, on attend 5s..."
  sleep 5
done


echo "✅ GitLab prêt !"

# Maintenant Rails est prêt → on peut récupérer le token
echo "le token pour ton runneur sera ou pas :"
export REG_TOKEN=$(docker exec gitlab_10.0.0.10 \
  gitlab-rails runner "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token")
echo $REG_TOKEN

# affiche le mot de passe initial root
echo "You know what to do with :"
docker exec -it gitlab_10.0.0.10 cat /etc/gitlab/initial_root_password 2>/dev/null || echo "🤷‍♂️ Le fichier n'existe plus (GitLab déjà initialisé ?)"
echo "All done. Use 'docker ps' to see running containers."



deploy_stack "runneur"

echo

echo "If you added a user to the docker group, they may need to log out and log in again."
