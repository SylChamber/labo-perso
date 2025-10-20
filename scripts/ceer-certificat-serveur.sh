#!/usr/bin/env bash
# Crée un certificat pour le serveur à partir de l'autorité de certificat intermédiaire

set -eo pipefail

if ! command -v step >/dev/null 2>&1 ; then
    >&2 echo "step est requis pour créer des autorités de certificat."
    exit 1
fi

SCRIPT_DIR=$(dirname "$0")
CERTS_DIR=~/.local/state/step/certs
CERT_NAME="Serveur Motel"
CERT_FILENAME=motel

if [ -f $CERTS_DIR/$CERT_FILENAME.crt ] || [ -f $CERTS_DIR/$CERT_FILENAME.key ]; then
    >&2 echo "Le certificat « $CERT_NAME » a déjà été créé sous $CERTS_DIR."
    exit 1
fi

if [ ! -f $SCRIPT_DIR/certificate.json.tpl ]; then
    >&2 echo "Le gabarit certificate.json.tpl est requis."
    exit 1
fi

if [ ! -f $CERTS_DIR/intermediate_ca.crt ] || [ ! -f $CERTS_DIR/intermediate_ca.key ]; then
    >&2 echo -e "Les fichiers d'autorité de certificat intermédaire sont requis:
    $CERTS_DIR/intermediate_ca.crt
    $CERTS_DIR/intermediate_ca.key"
    exit 1
fi

if [ ! -f $CERTS_DIR/root_ca.crt ]; then
    >&2 echo -e "Le fichier public d'autorité de certificat racine est requis:
    $CERTS_DIR/root_ca.crt"
    exit 1
fi

>&2 echo "Génération du certificat pour « $CERT_NAME »..."
step certificate create "$CERT_NAME" \
    $CERTS_DIR/$CERT_FILENAME.crt \
    $CERTS_DIR/$CERT_FILENAME.key \
  --ca $CERTS_DIR/intermediate_ca.crt \
  --ca-key $CERTS_DIR/intermediate_ca.key \
  --not-after=8760h \
  --bundle \
  -san motel.internal --san serveur.internal --san server.internal \
  --template $SCRIPT_DIR/certificate.json.tpl \
  --insecure --no-password

# ajout du ca racine au bundle pour Firefox, qui, sinon, ne reconnait pas le certificat comme étant valide
# même si l'OS le contient
cat $CERTS_DIR/root_ca.crt >> $CERTS_DIR/$CERT_FILENAME.crt

>&2 echo "Certificat créé sous $CERT_FILENAME/$CERT_FILENAME.{crt,key}"
