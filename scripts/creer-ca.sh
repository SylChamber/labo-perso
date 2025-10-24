#!/usr/bin/env bash
# Crée des autorités privées de certificat racine et intermédiaire pour le réseau local

set -eo pipefail

if ! command -v step >/dev/null 2>&1 ; then
    >&2 echo "step est requis pour créer des autorités de certificat."
    exit 1
fi

SCRIPT_DIR=$(dirname "$0")
REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
# Si STEPPATH n'existe pas, définir un dossier par défaut
STEPPATH=${STEPPATH:-~/.local/state/step}
CERTS_DIR=$STEPPATH/certs
# 25 ans
NOT_AFTER=219144h

ROOT_CA_NAME=root_ca
INTERMEDIATE_CA_NAME=intermediate_ca

if [ ! -d $CERTS_DIR ]; then
    mkdir -p $CERTS_DIR
fi

if [ ! -f $SCRIPT_DIR/${ROOT_CA_NAME}.json.tpl ] || [ ! -f $SCRIPT_DIR/${INTERMEDIATE_CA_NAME}.json.tpl ]; then
    >&2 echo "Les gabarits ${ROOT_CA_NAME}.json.tpl et ${INTERMEDIATE_CA_NAME}.json.tpl sont requis sous $SCRIPT_DIR."
    exit 1
fi

# copier les gabarits dans $CERTS_DIR; mode interactif au cas où les fichiers existeraient
>&2 echo "Copie des gabarits dans le dossier de configuration de certificats $CERTS_DIR"
cp -i $SCRIPT_DIR/*.tpl $CERTS_DIR/

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
cat $SCRIPT_DIR/${ROOT_CA_NAME}.json.tpl | envsubst | tee $CERTS_DIR/${ROOT_CA_NAME}.json
cat $SCRIPT_DIR/${INTERMEDIATE_CA_NAME}.json.tpl | envsubst | tee $CERTS_DIR/${INTERMEDIATE_CA_NAME}.json

# Demander les mots de passe des certificats
read -sp "Veuillez saisir un mot de passe pour le certificat root: " ROOT_TLS_PASSWORD
>&2 echo

if [ -z "$ROOT_TLS_PASSWORD" ]; then
    >&2 echo "Aucun mot de passe saisi, génération d'un mot de passe..."
    ROOT_TLS_PASSWORD=$(openssl rand -base64 42)
fi

echo $ROOT_TLS_PASSWORD > $CERTS_DIR/${ROOT_CA_NAME}.password

read -sp "Veuillez saisir un mot de passe pour le certificat intermédiaire: " INTERMEDIATE_TLS_PASSWORD
>&2 echo

if [ -z "$INTERMEDIATE_TLS_PASSWORD" ]; then
    >&2 echo "Aucun mot de passe saisi, génération d'un mot de passe..."
    INTERMEDIATE_TLS_PASSWORD=$(openssl rand -base64 42)
fi

echo $INTERMEDIATE_TLS_PASSWORD > $CERTS_DIR/${INTERMEDIATE_CA_NAME}.password

# Générer la paire de certificat racine
>&2 echo "Génération du certificat racine..."
step certificate create \
  "${ROOT_CA_NAME}" \
  "$CERTS_DIR/${ROOT_CA_NAME}.crt" \
  "$CERTS_DIR/${ROOT_CA_NAME}.key" \
  --template="$CERTS_DIR/${ROOT_CA_NAME}.json" \
  --kty="EC" \
  --curve="P-256" \
  --password-file="$CERTS_DIR/${ROOT_CA_NAME}.password" \
  --not-before="0s" \
  --not-after="$NOT_AFTER" \
  --force

TLS_ROOT_CRT=$(cat $CERTS_DIR/${ROOT_CA_NAME}.crt | sed 's/^/        /')
TLS_ROOT_KEY=$(cat $CERTS_DIR/${ROOT_CA_NAME}.key | sed 's/^/        /')
TLS_ROOT_FINGERPRINT=$(step certificate fingerprint $CERTS_DIR/${ROOT_CA_NAME}.crt)

# Générer la paire de certificat intermédiaire
>&2 echo "Génération du certificat intermédiaire..."
step certificate create \
  "${INTERMEDIATE_CA_NAME}" \
  "$CERTS_DIR/${INTERMEDIATE_CA_NAME}.crt" \
  "$CERTS_DIR/${INTERMEDIATE_CA_NAME}.key" \
  --template="$CERTS_DIR/${INTERMEDIATE_CA_NAME}.json" \
  --kty="EC" \
  --curve="P-256" \
  --password-file="$CERTS_DIR/${INTERMEDIATE_CA_NAME}.password" \
  --not-before="0s" \
  --not-after="$NOT_AFTER" \
  --ca="$CERTS_DIR/${ROOT_CA_NAME}.crt" \
  --ca-key="$CERTS_DIR/${ROOT_CA_NAME}.key" \
  --ca-password-file="$CERTS_DIR/${ROOT_CA_NAME}.password" \
  --force

TLS_INTERMEDIATE_CRT=$(cat $CERTS_DIR/${INTERMEDIATE_CA_NAME}.crt | sed 's/^/        /')
TLS_INTERMEDIATE_KEY=$(cat $CERTS_DIR/${INTERMEDIATE_CA_NAME}.key | sed 's/^/        /')

# Définir un nom de provisioner s'il n'a pas été fourni
[ -z $PROVISIONER_NAME ] && export PROVISIONER_NAME=admin

# Demander un mot de passe pour le provisionneur JWK
read -sp "Veuillez saisir un mot de passe pour le provisionneur de certificats JWK: " JWK_PROVISIONER_PASSWORD
>&2 echo

if [ -z "$JWK_PROVISIONER_PASSWORD" ]; then
    >&2 echo "Aucun mot de passe saisi, génération d'un mot de passe..."
    JWK_PROVISIONER_PASSWORD=$(openssl rand -base64 42)
fi

echo $JWK_PROVISIONER_PASSWORD > $CERTS_DIR/jwk_provisioner.password

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

>&2 echo "Les fichiers de certificats ont été créés dans le dossier $CERTS_DIR.
Avant de les supprimer, veuillez les sauvegarder de façon sécuritaire
et générez le fichier manifeste de secrets pour step-ca."
