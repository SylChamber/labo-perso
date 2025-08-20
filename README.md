# Laboratoire personnel

Ce dépôt contient le code de déploiement de mon laboratoire personnel. Il est centré sur un miniserveur modeste de type Mini PC usagé.

* L'OS léger de type «immuable» a été sélectionné pour limiter les efforts d'entretien
* La distribution Kubernetes légère `k3s` est installée comme principale plateforme d'exécution
* Les dépendances du cluster Kubernetes sont déployées sous forme de conteneurs podman, comme services systemd avec Podman Quadlet

Les précédents travaux reposaient sur une installation de Ubuntu Server 24.04 et une installation de toutes les charges dans `k3s` (par exemple le serveur DNS), et déployées manuellement. La nouvelle mouture vise à automatiser le plus possible, en particulier avec les principes GitOps.

Le déploiement via des charts Helm sera privilégié plutôt que par les opérateurs, car `k3s` dispose d'un contrôleur Helm permettant d'automatiser le déploiement avec des CRD de charts Helm ― ce qui facilite l'amorçage ― sans compter la consommation de ressources par Operator Lifecycle Manager.

> De surcroît, Operator Lifecycle Manager est en évolution vers v1, la v0 est en mode maintenance, il n'y a pas encore de magasin v1, et des projets importants comme `cert-manager` abandonnent les opérateurs.

## État actuel

Le serveur a été [configuré avec openSUSE MicroOS](microos/README.md), une installation personnalisée avec `k3s`, pour les raisons suivantes:

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

* chiffrement intégral (Full Disk Encryption)
  * mes tentatives ont été infructueuses, tant avec Leap Micro (erreurs `btrfs` constantes) qu'avec MicroOS (déverrouillage via TPM non fonctionnel)
* sauvegardes
  * sauvegardes automatiques locales sur mes ordinateurs à l'aide de `syncthing` (déjà utilisé sur mes appareils)
  * sauvegarde automatique dans l'infonuagique des données chiffrées avec rclone (voir des fournisseurs potentiels listés sous [k3s - Sauvegardes](k3s/README.md#sauvegardes))
* serveur DNS
  * vise à faciliter la mise en place d'un réseau local avec des noms de domaine
  * déploiement de CoreDNS sous forme de service systemd avec Podman Quadlet (évolution des [travaux précédents](dns/README.md))
* serveur de certificats ACME
  * vise à faciliter la gestion des certificats TLS, et sert la même fonction que Let's Encrypt sur un réseau privé
  * déploiement de `step-ca` sous forme de Podman Quadlet (voir notes dans [k3s - Gestion des certificats](k3s/README.md#gestion-des-certificats))

Les serveurs DNS et de certificats sont des dépendances du cluster Kubernetes. Ils devraient être à tout le moins réalisés rapidement.

Au plan du cluster `k3s`:

* gestion des certificats avec `cert-manager`
  * déploiement avec un Helm Chart par le biais du Helm Controller de `k3s`
  * utilisation de `step-ca` pour provisionner les certificats
* déploiement en continu GitOps, avec Argo CD
  * déploiement d'Argo CD avec un Helm Chart par le biais du Helm Controller
* sécurité améliorée des pods avec le profil `Restricted` de Pod Security Standards
* mises à niveau automatisées de `k3s`
  * déploiement du System Upgrade Controller Rancher par GitOps
* outillage d'observabilité
  * évaluer Pixie, conçu pour les déploiements _edge_ (voir les notes dans [k3s - Observabilité](k3s/README.md#observabilité))
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
