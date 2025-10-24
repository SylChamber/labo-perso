#!/usr/bin/env bash
# Crée du manifeste YAML Kubernetes de secrets pour la gestion des certificat avec step-ca
# TODO: envisager un chart Helm!

set -eo pipefail

if ! command -v step >/dev/null 2>&1 ; then
    >&2 echo "step est requis pour générer le manifeste YAML Kubernetes de secrets pour la gestion des certificats."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1 ; then
    >&2 echo "jq est requis pour générer le manifeste YAML Kubernetes de secrets pour la gestion des certificats."
fi

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
# Si STEPPATH n'existe pas, définir un dossier par défaut
STEPPATH=${STEPPATH:-~/.local/state/step}
CERTS_DIR=$STEPPATH/certs

ROOT_CA_NAME=root_ca
INTERMEDIATE_CA_NAME=intermediate_ca
JWK_PROVISIONER_NAME=jwk_provisioner

# Assurer la présence des fichiers de secrets
fichiers=(
    ${INTERMEDIATE_CA_NAME}.crt
    ${INTERMEDIATE_CA_NAME}.key
    ${INTERMEDIATE_CA_NAME}.password
    ${JWK_PROVISIONER_NAME}.key
    ${JWK_PROVISIONER_NAME}.password
    ${JWK_PROVISIONER_NAME}.pub
    ${ROOT_CA_NAME}.crt
    ${ROOT_CA_NAME}.key
    ${ROOT_CA_NAME}.password
)
for f in ${fichiers[@]}; do
    if [ ! -f $CERTS_DIR/$f ]; then
        >&2 echo "Le fichier $CERTS_DIR/$f est requis pour générer le manifeste YAML Kubernetes de secrets pour la gestion des certificats."
        exit 1
    fi
done

# Définir les variables dynamiques et valeurs par défaut
export CA_NAMESPACE=${CA_NAMESPACE:-step-ca}
export CA_CHART_NAME=${CA_CHART_NAME:-step-certificates}
export CA_CHART_RELEASE_NAME=${CA_CHART_RELEASE_NAME:-acme}
export CA_CHART_FULLNAME=${CA_CHART_RELEASE_NAME}-${CA_CHART_NAME:-step-certificates}

export CA_URL=${CA_CHART_FULLNAME}.${CA_NAMESPACE}.svc.cluster.local
export CA_DNS_NAMES=$(echo "${CA_DNS_NAMES:-[\"ca.internal\", \"ac.internal\"]}" |
    jq --argjson dns "\"$CA_URL\"" '. += [ $dns ]' |
    jq --compact-output --argjson dns '"127.0.0.1"' '. += [ $dns ]')

# indenter chaque ligne d'un fichier
indent() {
    nombre_car=$1
    espaces=$(printf ' %.0s' $(seq 1 $nombre_car))
    fichier=$CERTS_DIR/$2
    cat $fichier | sed "s/^/$espaces/"
}

export INTERMEDIATE_CA_KEY=$(indent 4 ${INTERMEDIATE_CA_NAME}.key)
export INTERMEDIATE_CA_CRT=$(indent 4 ${INTERMEDIATE_CA_NAME}.crt)
export INTERMEDIATE_TLS_PASSWORD_B64=$(cat $CERTS_DIR/${INTERMEDIATE_CA_NAME}.password |
    base64 --wrap=0)
export ROOT_CA_KEY=$(indent 4 ${ROOT_CA_NAME}.key)
export ROOT_CA_CRT=$(indent 4 ${ROOT_CA_NAME}.crt)
export ROOT_CA_FINGERPRINT=$(step certificate fingerprint $CERTS_DIR/${ROOT_CA_NAME}.crt)

export JWK_PROVISIONER_ENCRYPTED_KEY=$(cat $CERTS_DIR/${JWK_PROVISIONER_NAME}.key |
    step crypto jose format |
    tee $CERTS_DIR/${JWK_PROVISIONER_NAME}.encrypted.key)
export JWK_PROVISIONER_KEY=$(indent 12 ${JWK_PROVISIONER_NAME}.pub)
export JWK_PROVISIONER_PASSWORD_B64=$(cat $CERTS_DIR/${JWK_PROVISIONER_NAME}.password |
    base64 --wrap=0)

>&2 echo "Génération du manifeste Kubernetes pour la gestion des certificats..."

cat $SCRIPT_DIR/secrets-ca.yaml.tpl | envsubst | tee $CERTS_DIR/secrets-ca.yaml

>&2 echo "Manifeste créé sous $CERTS_DIR/secrets-ca.yaml"
