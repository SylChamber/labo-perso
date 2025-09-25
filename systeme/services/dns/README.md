# Déploiement du serveur DNS CoreDNS

## Déploiement de CoreDNS comme manifeste Kubernetes

Le [manifeste YAML Kubernetes (coredns.yaml)](coredns.yaml) définit un pod et une configuration CoreDNS à déployer avec la syntaxe Kubernetes.

L'approche a l'avantage de ne pas dépendre d'autres étapes.

Il faut toutefois noter que l'exposition du port DNS 53 en TCP et UDP est problématique dans podman, car le port est utilisé à l'interne par podman. En lançant `podman kube play` (peu importe l'utilisateur, même `root`), une erreur de liaison de port UDP se produit: `Error starting server failed to bind udp listener on 10.89.0.1:53: IO error: Address already in use (os error 98)`. (Voir les [références](#références)).

Puisque le port 53 doit être exposé sur l'hôte, on définit la réseautique du pod comme utilisant celle de l'hôte avec `hostNetwork: true`, et il est ainsi inutile de mapper les ports internes vers des ports de l'hôte (`ports.hostPort`).

CoreDNS sera déployé comme pod avec:

* un conteneur `coredns-coredns` qui héberge CoreDNS
* un conteneur d'infrastructure
* un volume créé selon le `ConfigMap` avec la configuration de CoreDNS

## Configuration FetchIt

La configuration FetchIt suivante est requis pour le déploiement:

```yaml
targetConfigs:
# Déploiement de CoreDNS
- url: https://github.com/SylChamber/labo-perso
  branch: main
  kube:
  - name: coredns
    targetPath: systeme/services/dns
    schedule: "*/3 * * * *"
```

Le dépôt sera inspecté à toutes les 3 minutes pour vérifier s'il y a des mises à jour.

## Vérification

Pour vérifier le déploiement, lancer:

> Ces commandes doivent être lancées avec l'utilisateur `root`.

```shell
> podman pod ps
POD ID        NAME        STATUS      CREATED         INFRA ID      # OF CONTAINERS
03c9f4cf442c  coredns     Running     11 seconds ago  c2a78da80bb2  2
```

pour lister les conteneurs:

```shell
podman ps
CONTAINER ID  IMAGE                             COMMAND               CREATED             STATUS             PORTS           NAMES
c2a78da80bb2                                                          About a minute ago  Up About a minute                  03c9f4cf442c-infra
ebb390c6ecb8  docker.io/coredns/coredns:1.12.4  -conf /etc/coredn...  About a minute ago  Up About a minute  53/tcp, 53/udp  coredns-coredns
```

pour lister le volume:

```shell
podman volume ls
DRIVER      VOLUME NAME
local       fetchit-volume
local       coredns-config
```

pour lister le contenu du volume:

```shell
> dir $(podman volume inspect coredns-config --format '{{ .Mountpoint }}')
total 8
-rw-r--r--. 1 root root  161 25 sep 15:50 Corefile
-rw-r--r--. 1 root root 1016 25 sep 15:50 internal.db
```

## Déploiement de CoreDNS comme Podman Quadlet

Un Podman Quadlet est un service systemd. Voir la [documentation sur le déploiement de CoreDNS](../../../docs/dns/README.md). Cette technique nécessite

* un dossier sur l'hôte configuré avec les bonnes permissions SELinux pour héberger la configuration de CoreDNS
* une définition de service systemd pour déployer le pod en référençant la configuration

Elle nécessite deux configurations de méthodes de déploiement différentes dans FetchIt:

* `filetransfer` pour transférer les fichiers de configuration sur le volume hôte
* `systemd` pour définir un service systemd pour lancer CoreDNS

Cette approche nécessite de définir les bonnes permissions SELinux sur un dossier hôte, par exemple `/etc/coredns`, et d'appliquer le type de contexte SELinux `container_file_t` dessus. Ceci doit être fait au préalable, sinon la première exécution du service échouera.

Pour cette raison, j'ai préféré l'approche `kube` qui est tout incluse et ne nécessite pas d'étapes préalables. Voir cette configuration sous [archive/](archive/).

## Références

* [Déploiement d'un serveur DNS pour le réseau local](../../../docs/dns/README.md)
* [kube: Cannot listen on the UDP port: listen udp4 :53: bind: address already in use - containers/podman - GitHub](https://github.com/containers/podman/issues/19108)
* [PortMappings can only be used with Bridge, slirp4netns, or pasta networking when using Network=private with pod - containers/podman - GitHub](https://github.com/containers/podman/issues/21019)
