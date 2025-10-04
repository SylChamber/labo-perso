#!/usr/bin/env bash
# Crée du manifeste YAML Kubernetes de secrets pour la gestion des certificat avec step-ca

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
CERTS_DIR=$REPO_ROOT_DIR/certs

# Assurer la présence des fichiers de secrets
fichiers=(
    intermediate-tls.crt
    intermediate-tls.key
    intermediate-tls.password
    jwk_provisioner.key
    jwk_provisioner.password
    jwk_provisioner.pub
    root-tls.crt
    root-tls.key
    root-tls.password
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

export INTERMEDIATE_CA_KEY=$(indent 4 intermediate-tls.key)
export INTERMEDIATE_CA_CRT=$(indent 4 intermediate-tls.crt)
export INTERMEDIATE_TLS_PASSWORD_B64=$(cat $CERTS_DIR/intermediate-tls.password |
    base64 --wrap=0)
export ROOT_CA_KEY=$(indent 4 root-tls.key)
export ROOT_CA_CRT=$(indent 4 root-tls.crt)
export ROOT_CA_FINGERPRINT=$(step certificate fingerprint $CERTS_DIR/root-tls.crt)

export JWK_PROVISIONER_ENCRYPTED_KEY=$(cat $CERTS_DIR/jwk_provisioner.key |
    step crypto jose format |
    tee $CERTS_DIR/jwk_provisioner.encrypted.key)
export JWK_PROVISIONER_KEY=$(indent 12 jwk_provisioner.pub)
export JWK_PROVISIONER_PASSWORD_B64=$(cat $CERTS_DIR/jwk_provisioner.password |
    base64 --wrap=0)

>&2 echo "Génération du manifeste Kubernetes pour la gestion des certificats..."

cat $SCRIPT_DIR/secrets-ca.yaml.tpl | envsubst | tee $CERTS_DIR/secrets-ca.yaml

>&2 echo "Manifeste créé sous $CERTS_DIR/secrets-ca.yaml"
