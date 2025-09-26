# Déploiement des services système en conteneur

Ce dossier contient la configuration de déploiement des services système sous la forme de conteneurs Podman. Le déploiement se fait à l'aide de [FetchIt](https://fetchit.readthedocs.io/) dont l'installation via conteneur podman se fait sous [configuration](configuration/README.md).

Le fichier de configuration [config.yaml](config.yaml) définit les services à déployer. Ce fichier est récupéré dynamiquement par la configuration de base de FetchIt qui est générée après l'installation à l'aide du service `fetchit-setup.service`. Ce service lance le script [fetchit-setup.sh](../configuration/fetchit-setup.sh).

## Amorce du déploiement automatisé des services système

Après l'installation de l'OS, le service `fetchit-setup.service` aura été installé, mais ne sera pas actif. On l'utilise pour configurer FetchIt, qui sera déployé comme service systemd s'exécutant en conteneur.

> L'utilisation d'un service d'installation est une pratique de configuration courante sur les OS immuables pour pallier au fait que seule une partie du système de fichiers est modifiable par l'utilisateur. Par exemple, puisque le dossier `/etc` sera modifiable, il est préférable de ne rien y écrire pendant l'installation de l'OS.

Lancer le service avec:

```shell
sudo systemctl start fetchit-setup
```

> Il n'est pas requis d'activer (_enable_) le service `fetchit-setup` puisqu'il ne servira plus après la configuration initiale de Fetchit.

FetchIt sera installé, mais ne sera pas activé ni démarré. Dépendamment de la visibilité du dépôt git, il faudra d'abord modifier la configuration afin d'y inscrire les informations de connexion au dépôt (le PAT ou _personal access token_). Voir la section suivante, [Configuration de l'accès au dépôt GitHub privé](#configuration-de-laccès-au-dépôt-github-privé).

La configuration de FetchIt se trouve sous `/etc/fetchit/config.yaml`. Une fois l'accès au dépôt configuré, on recharge les services, puis on active et on lance le service `fetchit.service`:

```shell
sudo systemctl daemon-reload
sudo systemctl enable --now fetchit
```

## Configuration de l'accès au dépôt GitHub privé

> Je n'ai pas réussi à faire fonctionner FetchIt avec un **fine-grained PAT** GitHub. J'ai changé la visibilité de ce dépôt vers public afin d'éviter les problèmes d'accès pour l'instant.

Pour donner l'accès en lecture seulement à ce dépôt GitHub privé, aller dans les **Settings** personnels sur GitHub > **Developer Settings** > **Personal access tokens** > **Fine-grained tokens**. Créer ensuite un token pour ce dépôt seulement avec la permission **Contents**.

Le PAT devra ensuite être remplacé dans le fichier de configuration `/etc/containers/fetchit/config.yaml` sous `configReload.pat`. Voir [fetchit-setup.sh](configuration/fetchit-setup.sh).

Références:

* [Creating a fine-grained personal access token - GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token)
* [How can I download a single raw file from a private github repo using the command line? - StackOverflow](https://stackoverflow.com/questions/18126559/how-can-i-download-a-single-raw-file-from-a-private-github-repo-using-the-comman#answer-79097362)

## Configuration de FetchIt pour les opérations GitOps

> Comme mentionné ci-dessus, le dépôt git est présentement public et une authentification n'est pas nécessaire.

La configuration FetchIt dans [config.yaml](config.yaml) contient un jeton d'accès GitHub (PAT) qui permettra de télécharger dynamiquement la configuration à partir de ce dépôt git. Comme il est préférable de ne pas stocker de secret dans git, il faut configurer FetchIt autrement pour spécifier le PAT pour les opérations GitOps.

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
