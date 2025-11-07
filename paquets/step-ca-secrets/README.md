# Secrets pour step-ca

Provisionne des secrets pour le serveur ACME et provisionneur de certificat `step-ca`.

Requiert les fichiers suivants qui auront été créés au préalable par la cli `step` avec le script [scripts/creer-ca.sh](../../scripts/creer-ca.sh) à l'aide de la tâche `certs:ca` (`task certs:ca`).

* `intermediate_ca.password`: mot de passe de l'autorité de certificat intermédiaire, celle qui émettra les certificats
* `intermediate_ca.key`: clé chiffrée de l'autorité de certificat intermédiaire
* `intermediate_ca.crt`: certificat public de l'autorité intermédiaire
* `jwk_provisioner.password`: mot de passe du provisionneur JWK
* `root_ca.key`: clé chiffrée de l'autorité de certificat racine
* `root_ca.crt`: certificat public de l'autorité racine

Pour vérifier le rendu, exécuter:

> Remplacer `$CERTS` par le chemin vers les fichiers requis.
>
> **Important**: le nom de la charte doit être **remplacé** avec `nameOverride`, car cette charte crée des objets pour la charte `step-certificates` qui permet de déployer `step-ca`. Le nom doit donc être **le même**.

```shell
$CERTS=$HOME/.local/state/step/certs
helm template acme \
-n step-ca \
--set nameOverride=step-certificates \
--set-file secrets.intermediate_ca_password=$CERTS/intermediate_ca.password \
--set-file secrets.provisioner_password=$CERTS/jwk_provisioner.password \
--set-file secrets.intermediate_ca_key=$CERTS/intermediate_ca.key \
--set-file secrets.root_ca_key=$CERTS/root_ca.key \
--set-file certificats.intermediate_ca=$CERTS/intermediate_ca.crt \
--set-file certificats.root_ca=$CERTS/root_ca.crt \
./
```
