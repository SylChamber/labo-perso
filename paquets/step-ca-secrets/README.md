# Secrets pour step-ca

Ce dossier contient une `kustomization` permettant de générer et déployer les secrets requis par le chart Helm de [step-ca](https://smallstep.com/docs/step-ca/).

La `kustomization` requiert:

* `secrets/intermediate_ca.crt`
* `secrets/intermediate_ca.password` (fichier `env` avec la clé `password`)
* `secrets/intermediate_ca_key` (la clé chiffrée du certificat)
* `secrets/root_ca.crt`
* `secrets/root_ca.password` (fichier `env` avec la clé `password`)
* `secrets/root_ca_key` (la clé chiffrée du certificat)
* `secrets/jwk_provisioner.password` (fichier `env` avec la clé `password`)
