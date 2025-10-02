#!/usr/bin/env bash
# Crée des autorités privées de certificat racine et intermédiaire pour le réseau local

set -eo pipefail

if ! command -v step >/dev/null 2>&1 ; then
    echo "step est requis pour créer des autorités de certificat."
    exit 1
fi

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
CERTS_DIR=$REPO_ROOT_DIR/certs
# 25 ans
NOT_AFTER=219144h

mkdir -p $CERTS_DIR

if [ ! -f $SCRIPT_DIR/root-tls.json.tpl ] || [ ! -f $SCRIPT_DIR/intermediate-tls.json.tpl ]; then
    >&2 echo "Les gabarits root-tls.json.tpl et intermediate-tls.json.tpl sont requis."
    exit 1
fi

# assurer la présence des paramètres

# Champ Organisation des certificats; sera aussi utilisé pour nommer les autorités
# «$ORGANISATION Root Private Authority» et «$ORGANISATION Intermediary Private Authority»
: ${ORGANISATION:?Variable ORGANISATION manquante}

# Code de pays de 2 lettres: champ C du Subject des certificats
: ${COUNTRY:?Variable COUNTRY manquante, code de pays de 2 lettres}

# Champ ST (State/Province) du Subject des certificats
: ${PROVINCE:?Variable PROVINCE manquante, nom complet}

export ROOT_CA_NAME="$ORGANISATION Root Private Certificate Authority"
export INTERMEDIATE_CA_NAME="$ORGANISATION Intermediary Private Certificate Authority"

# Générer les gabarits de certificats
>&2 echo "Génération des gabarits de certificats..."
cat $SCRIPT_DIR/root-tls.json.tpl | envsubst | tee $CERTS_DIR/root-tls.json
cat $SCRIPT_DIR/intermediate-tls.json.tpl | envsubst | tee $CERTS_DIR/intermediate-tls.json

# Demander les mots de passe des certificats
read -sp "Veuillez saisir un mot de passe pour le certificat root: " ROOT_TLS_PASSWORD
>&2 echo

if [ -z "$ROOT_TLS_PASSWORD" ]; then
    >&2 echo "Aucun mot de passe saisi, génération d'un mot de passe..."
    ROOT_TLS_PASSWORD=$(openssl rand -base64 42)
fi

ROOT_TLS_PASSWORD_B64=$(echo $ROOT_TLS_PASSWORD |
    tee $CERTS_DIR/root-tls.password |
    base64 --wrap=0)

read -sp "Veuillez saisir un mot de passe pour le certificat intermédiaire: " INTERMEDIATE_TLS_PASSWORD
>&2 echo

if [ -z "$INTERMEDIATE_TLS_PASSWORD" ]; then
    >&2 echo "Aucun mot de passe saisi, génération d'un mot de passe..."
    INTERMEDIATE_TLS_PASSWORD=$(openssl rand -base64 42)
fi

INTERMEDIATE_TLS_PASSWORD_B64=$(echo $INTERMEDIATE_TLS_PASSWORD |
    tee $CERTS_DIR/intermediate-tls.password |
    base64 --wrap=0)

# Générer la paire de certificat racine
>&2 echo "Génération du certificat racine..."
step certificate create \
  "${ROOT_CA_NAME}" \
  "$CERTS_DIR/root-tls.crt" \
  "$CERTS_DIR/root-tls.key" \
  --template="$CERTS_DIR/root-tls.json" \
  --kty="EC" \
  --curve="P-256" \
  --password-file="$CERTS_DIR/root-tls.password" \
  --not-before="0s" \
  --not-after="$NOT_AFTER" \
  --force

TLS_ROOT_CRT=$(cat $CERTS_DIR/root-tls.crt | sed 's/^/        /')
TLS_ROOT_KEY=$(cat $CERTS_DIR/root-tls.key | sed 's/^/        /')
TLS_ROOT_FINGERPRINT=$(step certificate fingerprint $CERTS_DIR/root-tls.crt)

# Générer la paire de certificat intermédiaire
>&2 echo "Génération du certificat intermédiaire..."
step certificate create \
  "${INTERMEDIATE_CA_NAME}" \
  "$CERTS_DIR/intermediate-tls.crt" \
  "$CERTS_DIR/intermediate-tls.key" \
  --template="$CERTS_DIR/intermediate-tls.json" \
  --kty="EC" \
  --curve="P-256" \
  --password-file="$CERTS_DIR/intermediate-tls.password" \
  --not-before="0s" \
  --not-after="$NOT_AFTER" \
  --ca="$CERTS_DIR/root-tls.crt" \
  --ca-key="$CERTS_DIR/root-tls.key" \
  --ca-password-file=$CERTS_DIR/"root-tls.password" \
  --force

TLS_INTERMEDIATE_CRT=$(cat $CERTS_DIR/intermediate-tls.crt | sed 's/^/        /')
TLS_INTERMEDIATE_KEY=$(cat $CERTS_DIR/intermediate-tls.key | sed 's/^/        /')

# Définir un nom de provisioner s'il n'a pas été fourni
[ -z $PROVISIONER_NAME ] && export PROVISIONER_NAME=admin

# Demander un mot de passe pour le provisionneur JWK
read -sp "Veuillez saisir un mot de passe pour le provisionneur de certificats JWK: " JWK_PROVISIONER_PASSWORD
>&2 echo

if [ -z "$JWK_PROVISIONER_PASSWORD" ]; then
    >&2 echo "Aucun mot de passe saisi, génération d'un mot de passe..."
    JWK_PROVISIONER_PASSWORD=$(openssl rand -base64 42)
fi

JWK_PROVISIONER_PASSWORD_B64=$(echo $JWK_PROVISIONER_PASSWORD |
    tee $CERTS_DIR/jwk_provisioner.password |
    base64 --wrap=0)

# Générer un provisionneur JWK
>&2 echo "Génération du provisionneur JWK..."
step crypto jwk create \
  $CERTS_DIR/jwk_provisioner.pub \
  $CERTS_DIR/jwk_provisioner.key \
  --kty=EC \
  --curve=P-256 \
  --use=sig \
  --password-file=$CERTS_DIR/jwk_provisioner.password \
  --force

>&2 echo "Les fichiers de certificats ont été créés dans le dossier certs.
Avant de les supprimer, veuillez les sauvegarder de façon sécuritaire
et générez le fichier manifeste de secrets pour step-ca."
