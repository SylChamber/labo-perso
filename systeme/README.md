# Code d'automatisation du système (serveur)

Ce dossier contient le code d'automatisation du système (du serveur):

* [configuration](configuration/README.md) (et installation) de l'OS
* déploiement des services systemd (par GitOps)

Le déploiement se fait à l'aide de FetchIt dont l'installation via conteneur podman se fait sous [configuration](configuration/README.md).

## Configuration de l'accès au dépôt GitHub privé

> Je n'ai pas réussi à faire fonctionner FetchIt avec un **fine-grained PAT** GitHub. J'ai changé la visibilité de ce dépôt vers public afin d'éviter les problèmes d'accès pour l'instant.

Pour donner l'accès en lecture seulement à ce dépôt GitHub privé, aller dans les **Settings** personnels sur GitHub > **Developer Settings** > **Personal access tokens** > **Fine-grained tokens**. Créer ensuite un token pour ce dépôt seulement avec la permission **Contents**.

Le PAT devra ensuite être remplacé dans le fichier de configuration `/etc/containers/fetchit/config.yaml` sous `configReload.pat`. Voir [fetchit-setup.sh](configuration/fetchit-setup.sh).

Références:

* [Creating a fine-grained personal access token - GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token)
* [How can I download a single raw file from a private github repo using the command line? - StackOverflow](https://stackoverflow.com/questions/18126559/how-can-i-download-a-single-raw-file-from-a-private-github-repo-using-the-comman#answer-79097362)

## Configuration de FetchIt pour les opérations GitOps

> Comme mentionné ci-dessus, le dépôt git est présentement public et une authentification n'est pas nécessaire.

La configuration FetchIt sous [services/config.yaml](services/config.yaml) contient un jeton d'accès GitHub (PAT) qui permettra de télécharger dynamiquement la configuration à partir de ce dépôt git. Comme il est préférable de ne pas stocker de secret dans git, il faut configurer FetchIt autrement pour spécifier le PAT pour les opérations GitOps.

Le PAT est configuré comme secret Podman:

```shell
# commencer par une espace pour ne pas consigner cette commande dans l'historique
 export GH_PAT_TOKEN=github_pat_XXXXXXXXX
podman secret create --env GH_PAT GH_PAT_TOKEN
```

Il suffit ensuite de le fournir au conteneur FetchIt, à la commande `podman run`, avec l'option:

```shell
--secret GH_PAT,type=env
```

Références:

* [FetchIt - Methods](https://fetchit.readthedocs.io/en/latest/methods.html#methods)
