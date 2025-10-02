#!/usr/bin/env bash
# Crée un manifeste YAML Kubernetes de secrets pour la gestion des certificat avec step-ca

set -eo pipefail

if ! command -v step >/dev/null 2>&1 ; then
    echo "step est requis pour générer le manifeste YAML Kubernetes de secrets pour la gestion des certificats."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1 ; then
    echo "jq est requis pour générer le manifeste YAML Kubernetes de secrets pour la gestion des certificats."
fi

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
CERTS_DIR=$REPO_ROOT_DIR/certs

# Assurer la présence des paramètres obligatoires


# Définir les variables dynamiques et valeurs par défaut
export CA_NAMESPACE=${CA_NAMESPACE:-step-ca}
export CA_CHART_NAME=${CA_CHART_NAME:-step-certificates}
export CA_CHART_RELEASE_NAME=${CA_CHART_RELEASE_NAME:-acme}
export CA_CHART_FULLNAME=${CA_CHART_RELEASE_NAME}-${CA_CHART_NAME:-step-certificates}
export CA_URL=${CA_CHART_FULLNAME}.${CA_NAMESPACE}.svc.cluster.local
export CA_DNS_NAMES=$(echo "${CA_DNS_NAMES:-[\"ca.internal\", \"ac.internal\"]}" |
    jq --argjson dns "\"$CA_URL\"" '. += [ $dns ]' |
    jq --argjson dns '"127.0.0.1"' '. += [ $dns ]')
