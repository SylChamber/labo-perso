# Secrets pour step-ca

Provisionne des secrets pour le serveur ACME et provisionneur de certificat `step-ca`.

Requiert les fichiers suivants qui auront été créés au préalable par la cli `step` avec le script [scripts/creer-ca.sh](../../scripts/creer-ca.sh) à l'aide de la tâche `certs:ca` (`task certs:ca`).

* `intermediate_ca.password`: mot de passe de l'autorité de certificat intermédiaire, celle qui émettra les certificats
* `intermediate_ca.key`: clé chiffrée de l'autorité de certificat intermédiaire
* `jwk_provisioner.password`: mot de passe du provisionneur JWK
* `root_ca.key`: clé chiffrée de l'autorité de certificat racine

Exécuter:

> Remplacer `$CERTS_DIR` par le chemin vers les fichiers requis.

```shell
$CERTS_DIR=$HOME/.local/state/step/certs
helm template --set-file secrets.intermediate_ca_password=$CERTS_DIR/intermediate_ca.password \
--set-file secrets.provisioner_password=$CERTS_DIR/jwk_provisioner.password \
--set-file secrets.intermediate_ca_key=$CERTS_DIR/intermediate_ca.key \
--set-file secrets.root_ca_key=$CERTS_DIR/root_ca.key \
./
```
