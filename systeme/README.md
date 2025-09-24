# Code d'automatisation du système (serveur)

Ce dossier contient le code d'automatisation du système (du serveur):

* [configuration](configuration/README.md) (et installation) de l'OS
* déploiement des services systemd (par GitOps)

Le déploiement se fait à l'aide de FetchIt dont l'installation via conteneur podman se fait sous [configuration](configuration/README.md).

## Configuration de l'accès au dépôt GitHub privé

Pour donner l'accès en lecture seulement à ce dépôt GitHub privé, aller dans les **Settings** personnels sur GitHub > **Developer Settings** > **Personal access tokens** > **Fine-grained tokens**. Créer ensuite un token pour ce dépôt seulement avec la permission **Contents**.

Le PAT devra ensuite être remplacé dans le fichier de configuration `/etc/containers/fetchit/config.yaml` sous `configReload.pat`. Voir [fetchit-setup.sh](configuration/fetchit-setup.sh).

Références:

* [Creating a fine-grained personal access token - GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token)
* [How can I download a single raw file from a private github repo using the command line? - StackOverflow](https://stackoverflow.com/questions/18126559/how-can-i-download-a-single-raw-file-from-a-private-github-repo-using-the-comman#answer-79097362)
