# Secrets pour step-ca

Ce dossier contient une `kustomization` permettant de générer et déployer les secrets requis par le chart Helm de [step-ca](https://smallstep.com/docs/step-ca/).

La `kustomization` requiert:

* `secrets/intermediate_ca.crt`
* `secrets/intermediate_ca.key`
* `secrets/intermediate_ca.password`
* `secrets/root_ca.crt`
* `secrets/root_ca.key`
* `secrets/root_ca.password`
