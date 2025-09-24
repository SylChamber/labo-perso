# Déploiement du serveur DNS CoreDNS

CoreDNS est déployé sous forme de Podman Quadlet, soit un service systemd. Voir la [documentation sur le déploiement de CoreDNS](../../../docs/dns/README.md).

> J'ai tenté de déployer CoreDNS comme [manifeste YAML Kubernetes (coredns.yaml)](archive/coredns.yaml), mais la tentative a été infructueuse. Même en lançant `podman kube play` sous l'utilisateur `root`, une erreur de liaison de port UDP se produit: `Error starting server failed to bind udp listener on 10.89.0.1:53: IO error: Address already in use (os error 98)`. La méthode systemd fonctionne sans problème, quoiqu'elle demande de configurer le type du contexte SELinux du dossier de configuration de CoreDNS.

La configuration sous [config.yaml](../config.yaml):

* installera d'abord un service systemd, qui créera le dossier de configuration `/etc/coredns` et appliquera le type de contexte SELinux `container_file_t`
* copiera sous `/etc/coredns` les fichiers du sous-dossier [configuration/](configuration/)
