# Laboratoire personnel

Ce dépôt contient le code de déploiement de mon laboratoire personnel selon les principes GitOps. Il est centré sur un miniserveur modeste de type Mini PC usagé.

* L'OS léger de type «immuable» a été sélectionné pour limiter les efforts d'entretien
* La distribution Kubernetes légère `k3s` est installée comme principale plateforme d'exécution
* Les dépendances du cluster Kubernetes sont déployées sous forme de conteneurs podman, comme services systemd avec Podman Quadlet

Les précédents travaux reposaient sur une installation de Ubuntu Server 24.04 et une installation de toutes les charges dans `k3s` (par exemple le serveur DNS), et déployées manuellement. La nouvelle mouture vise à automatiser le plus possible, en particulier avec les principes GitOps.

Le déploiement via des charts Helm sera privilégié plutôt que par les opérateurs, car `k3s` dispose d'un contrôleur Helm permettant d'automatiser le déploiement avec des CRD de charts Helm ― ce qui facilite l'amorçage ― sans compter la consommation de ressources par Operator Lifecycle Manager.

> De surcroît, Operator Lifecycle Manager est en évolution vers v1, la v0 est en mode maintenance, il n'y a pas encore de magasin v1, et des projets importants comme `cert-manager` abandonnent les opérateurs.

## État actuel

Le serveur a été [configuré avec openSUSE MicroOS](docs/microos/README.md), une installation personnalisée avec `k3s`, pour les raisons suivantes:

* le projet Cayo d'Universal Blue (basé sur `bootc`), bien qu'intéressant, est en développement depuis peu
* MicroOS existe depuis plusieurs années
* les mises à jour sont atomiques, tout en étant néanmoins réduites en taille par rapport aux OS Universal Blue (gérées comme images de conteneurs)
  * les mises à jour se font par couches de paquets classiques
  * les fonctionnalités de _snapshot_ du système de fichier `btrfs` sont utilisées pour permettre un retour en arrière, plutôt que de reposer sur des images de conteneurs comme Universal Blue
* l'installation et la configuration est plus simple qu'avec CentOS et Fedora `bootc`
  * un outil web convivial (Fuel Ignition) facilite la configuration

`k3s` est configuré avec le chiffrement au repos, et les valeurs par défaut pour les autres options.

## Feuille de route

Au plan du système:

* ajouts aux paquets
  * **(fait)** retrait des man pages
    * j'ai tenté d'installé les man pages mais ça n'a pas fonctionné, car MicroOS est configuré pour ne pas les inclure: `rpm.install.excludedocs = yes` est spécifié dans `/etc/zypp/zypp.conf`
    * c'est l'utilisation d'une `distrobox` qui est recommandée par le responsable de MicroOS
    * il y a un outil `man-online` qui permet d'afficher les pages man; `man` en est un alias
  * **(fait)** ajout de `distrobox`
    * `toolbox` est présent, toutefois
  * **(fait)** ajout des outils réseau dig, nslookup: `bind-utils`
  * **(fait)** ajout de tailscale, outil VPN et d'exposition sur Internet
  * **(fait)** ajout de [podlet](https://github.com/containers/podlet), qui génère des fichiers Quadlet
    * en attendant la version récente de podman qui inclut la fonctionnalité
  * **(fait)** `tree`, `jq`, `yq`, `setools-console` (pour `seinfo`)
* **(bloqué)** chiffrement intégral (Full Disk Encryption)
  * mes tentatives ont été infructueuses, tant avec Leap Micro (erreurs `btrfs` constantes) qu'avec MicroOS (déverrouillage via TPM non fonctionnel)
  * plusieurs tentatives faites avec MicroOS; systemd-crypt ne trouve pas l'appareil TPM2
  * mon serveur ne supporte pas la méthode de stockage par défaut
  * comme je veux les mises à jour automatiques de l'OS, je garde non chiffré pour l'instant
* **(fait)** serveur DNS
  * vise à faciliter la mise en place d'un réseau local avec des noms de domaine
  * **(fait)** déploiement de CoreDNS sous forme de service systemd avec Podman Quadlet (évolution des [travaux précédents](docs/dns/README.md))
  * non requis?
    * ajout du service coredns comme serveur DNS dans openSUSE MicroOS: l'ajout du DNS au routeur devrait être suffisant pour que le serveur interroge son service coredns pour la résolution sur le réseau local
* **(fait)** gestion de la configuration des services podman selon les principes GitOps
  * l'objectif est d'automatiser les services prérequis au cluster k3s:
    * CoreDNS
    * ACME
  * installer [FetchIt](https://fetchit.readthedocs.io) et ajouter à la configuration système
* **(fait)** redéploiement du serveur DNS par GitOps
* serveur de certificats ACME
  * vise à faciliter la gestion des certificats TLS, et sert la même fonction que Let's Encrypt sur un réseau privé
  * déploiement de `step-ca` sous forme de conteneur (voir notes dans [k3s - Gestion des certificats](docs/k3s/README.md#gestion-des-certificats))
  * pour utiliser un domaine spécifique à `step-ca` avec SNI, envisager le déploiement d'un proxy léger comme Caddy ou Traefik, ou de déployer dans k3s
* activation du [DNS over TLS](https://en.m.wikipedia.org/wiki/DNS_over_TLS) dans CoreDNS
  * les appareils Android utilisent le mode «DNS privé» par défaut; pour qu'ils utilisent le DNS du réseau local, il faut [activer le support DNS over TLS dans CoreDNS](https://bartonbytes.com/posts/how-to-configure-coredns-for-dns-over-tls/) avec le [plugin tls](https://coredns.io/plugins/tls/)
* sauvegardes
  * sauvegardes automatiques locales sur mes ordinateurs à l'aide de `syncthing` (déjà utilisé sur mes appareils)
  * sauvegarde automatique dans l'infonuagique des données chiffrées avec rclone (voir des fournisseurs potentiels listés sous [k3s - Sauvegardes](docs/k3s/README.md#sauvegardes))

Les serveurs DNS et de certificats sont des dépendances du cluster Kubernetes. Ils devraient être à tout le moins réalisés rapidement.

Au plan du cluster `k3s`:

* gestion des certificats avec `cert-manager`
  * déploiement avec un Helm Chart par le biais du Helm Controller de `k3s`
  * utilisation de `step-ca` pour provisionner les certificats
* déploiement en continu GitOps, avec Argo CD
  * déploiement d'Argo CD avec un Helm Chart par le biais du Helm Controller
* sécurité améliorée des pods avec le profil `Restricted` de Pod Security Standards
* gestion sécuritaire du redémarrage Kubernetes avec [Kured](https://kured.dev/)
  * déterminer si c'est requis
* mises à niveau automatisées de `k3s`
  * déploiement du System Upgrade Controller Rancher par GitOps
* outillage d'observabilité
  * évaluer Pixie, conçu pour les déploiements _edge_ (voir les notes dans [k3s - Observabilité](docs/k3s/README.md#observabilité))
* Nextcloud, plateforme autohébergée de stockage et de partage
* Tunnel d'exposition de services sur Internet
  * explorer les options, par exemple CloudFlare Tunnels
    * [Using Cloudflare Tunnels to Access Homelab Services Out of Local Network - It's FOSS](https://itsfoss.com/cloudflare-tunnels/)
    * [Configuration des tunnels Cloudflare : Rationaliser et sécuriser votre trafic réseau](https://fr.simeononsecurity.com/guides/how-to-setup-and-use-cloudflare-tunnels/)
    * [Une nouvelle percée : des tunnels gratuits pour tous - CloudFlare](https://blog.cloudflare.com/fr-fr/tunnel-for-everyone/)
* Serveur git autohébergé
  * serveur [Forgejo](https://forgejo.org/) pour s'affranchir des fournisseurs propriétaires
  * automatiser des miroirs sur Github ou GitLab
* Albums photos en ligne
  * évaluer les capacités de NextCloud
  * envisager Immich ou un autre produit libre

## Références

* [Quadlet is the key tool that makes Podman better than Docker, and here's how to use it](https://www.xda-developers.com/quadlet-guide/)
* [Beyond Kubernetes: Podman + Quadlet for Lean, Reliable Containers](https://www.oss-group.co.nz/blog/podman-quadlet)
* [FetchIt - GitOps-Based Approach of Podman Containers Management](https://fetchit.readthedocs.io)
* [podman-kube-play man page - create podman resources based on Kubernetes YAML](https://docs.podman.io/en/latest/markdown/podman-kube-play.1.html)
* [podman-kube-generate man page - generate Kubernetes YAML from podman resources](https://docs.podman.io/en/latest/markdown/podman-kube-generate.1.html)
