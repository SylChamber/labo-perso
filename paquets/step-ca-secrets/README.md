# Secrets et configuration pour step-ca

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.28.4](https://img.shields.io/badge/AppVersion-0.28.4-informational?style=flat-square)

Provisionne des secrets pour le serveur ACME et provisionneur de certificat `step-ca`. C'est un préalable à l'installation de `step-ca` à l'aide de la charte Helm [step-certificates](https://artifacthub.io/packages/helm/smallstep/step-certificates).

Requiert les fichiers suivants qui auront été créés au préalable par la cli `step` avec le script [scripts/creer-ca.sh](../../scripts/creer-ca.sh) à l'aide de la tâche `certs:ca` (`task certs:ca`).

- `intermediate_ca.password`: mot de passe de l'autorité de certificat intermédiaire, celle qui émettra les certificats
- `intermediate_ca.key`: clé chiffrée de l'autorité de certificat intermédiaire
- `intermediate_ca.crt`: certificat public de l'autorité intermédiaire
- `jwk_provisioner.password`: mot de passe du provisionneur JWK
- `jwk_provisioner.encrypted.key`: clé chiffrée du provisionneur JWK
- `jwk_provisioner.pub`: clé publique du provisionneur JWK
- `root_ca.key`: clé chiffrée de l'autorité de certificat racine
- `root_ca.crt`: certificat public de l'autorité racine

> La cli `step` est également requise pour compiler l'empreinte (_fingerprint_) de l'autorité de certificat racine.

**Homepage:** <https://github.com/SylChamber/labo-perso/paquets/step-ca-secrets>

## Vérification du rendu

Pour vérifier le rendu, exécuter:

> Remplacer `$CERTS` par le chemin vers les fichiers requis.
>
> **Important**: le nom de la charte doit être **remplacé** avec `nameOverride`, car cette charte crée des objets pour la charte `step-certificates` qui permet de déployer `step-ca`. Le nom doit donc être **le même**.

```shell
CERTS=$HOME/.local/state/step/certs
helm template acme \
-n step-ca \
--set nameOverride=step-certificates \
--set-file intermediate_ca.key=$CERTS/intermediate_ca.key \
--set-file intermediate_ca.password=$CERTS/intermediate_ca.password \
--set-file intermediate_ca.pem=$CERTS/intermediate_ca.crt \
--set-file provisioner.key=$CERTS/jwk_provisioner.encrypted.key \
--set-file provisioner.password=$CERTS/jwk_provisioner.password \
--set-file provisioner.pub=$CERTS/jwk_provisioner.pub \
--set-file root_ca.key=$CERTS/root_ca.key \
--set-file root_ca.pem=$CERTS/root_ca.crt \
--set root_ca.fingerprint=$(step certificate fingerprint $CERTS/root_ca.crt) \
.
```

## Déploiement des secrets et de la configuration de step-ca

Pour déployer cette charte, exécuter:

> Remplacer `$CERTS` par le chemin vers les fichiers requis.
>
> **Important**:
>
> - le nom de la charte doit être **remplacé** avec `nameOverride`, car cette charte crée des objets pour la charte `step-certificates` qui permet de déployer `step-ca`. Le nom doit donc être **le même**.
> - le nom de la release, le namespace et le nom de la charte `step-certificates` (si on le remplace avec `nameOverride`) doivent **être les mêmes** qu'au déploiement de la charte `step-certificates` puisque cette charte-ci sert à fournir les secrets et la configuration à la charte `step-certificate`.

```shell
CERTS=$HOME/.local/state/step/certs
helm install acme \
-n step-ca \
--set nameOverride=step-certificates \
--set-file intermediate_ca.key=$CERTS/intermediate_ca.key \
--set-file intermediate_ca.password=$CERTS/intermediate_ca.password \
--set-file intermediate_ca.pem=$CERTS/intermediate_ca.crt \
--set-file provisioner.key=$CERTS/jwk_provisioner.encrypted.key \
--set-file provisioner.password=$CERTS/jwk_provisioner.password \
--set-file provisioner.pub=$CERTS/jwk_provisioner.pub \
--set-file root_ca.key=$CERTS/root_ca.key \
--set-file root_ca.pem=$CERTS/root_ca.crt \
--set root_ca.fingerprint=$(step certificate fingerprint $CERTS/root_ca.crt) \
.
```

## Source Code

- <https://github.com/SylChamber/labo-perso/paquets/step-ca-secrets>
- <https://artifacthub.io/packages/helm/smallstep/step-certificates>
- <https://github.com/smallstep/certificates>

## Values

| Key                      | Type   | Default                             | Description                                                                                                    |
| ------------------------ | ------ | ----------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| fullnameOverride         | string | `""`                                | Remplace le nom complet (fullname) d'application                                                               |
| intermediate_ca          | object | `{"key":"","password":"","pem":""}` | Autorité de certificat intermédiaire, émettrice de certificats                                                 |
| intermediate_ca.key      | string | `""`                                | Clé chiffrée de l'autorité de certificat intermédiaire                                                         |
| intermediate_ca.password | string | `""`                                | Mot de passe de l'autorité de certificat émetteur, intermediate_ca                                             |
| intermediate_ca.pem      | string | `""`                                | Certificat public en format PEM de l'autorité intermédiaire émettrice                                          |
| nameOverride             | string | `""`                                | Remplace le nom de la charte                                                                                   |
| provisioner              | object | `{"key":"","password":"","pub":""}` | Provisionneur JWK                                                                                              |
| provisioner.key          | string | `""`                                | Clé chiffrée du provisionneur JWK (ex. provisioner.encrypted.key), pour valeur "encryptedKey"                  |
| provisioner.password     | string | `""`                                | Mot de passe du certificat du provisionneur JWK                                                                |
| provisioner.pub          | string | `""`                                | Clé publique du provisionneur JWK, pour valeur "key"                                                           |
| root_ca.fingerprint      | string | `""`                                | Empreinte SHA256 (fingerprint) de l'autorité racine de certificat ('step certificate fingerprint root_ca.crt') |
| root_ca.key              | string | `""`                                | Clé chiffrée de l'autorité de certificat racine                                                                |
| root_ca.pem              | string | `""`                                | Certificat public en format PEM de l'autorité racine                                                           |

## Références

- [step-ca](https://github.com/smallstep/certificates)
- [step-certificates - ArtifactHUB](https://artifacthub.io/packages/helm/smallstep/step-certificates) (charte Helm)
- [step-ca Documentation](https://smallstep.com/docs/step-ca/)
- [step - Documentation](https://smallstep.com/docs/step-cli/) (CLI)
- [helm-docs](https://github.com/norwoodj/helm-docs)

---

Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
