# Déploiement d'un serveur DNS pour le réseau local

> Comme ce serveur DNS est un prérequis pour le cluster Kubernetes, envisager de déployer CoreDNS comme conteneur Podman et de l'installer comme service systemd avec Podman Quadlet.

Identifier d'abord comment ajouter un serveur DNS manuellement sous openSUSE, puisqu'il n'y a pas de service `systemd-resolved` comme sous Ubuntu. Ça semble se faire avec `NetworkManager`. Voir en référence.

Références

* [How to manage DNS in NetworkManager via console (nmcli)? - ServerFault](https://serverfault.com/questions/810636/how-to-manage-dns-in-networkmanager-via-console-nmcli)
* [Can’t resolve dns names - openSUSE Forums](https://forums.opensuse.org/t/cant-resolve-dns-names/169230)

## Choix du nom de domaine

Les avis sont partagés sur le choix d'un nom de domaine pour un réseau local. Plusieurs recommandations sont incorrectes. Selon les derniers RFC (_requests for comments_), deux domaines sont à la fois réservés pour les réseaux privés, et utilisables avec le protocole DNS:

* `.home.arpa` (pas optimal pour des néophytes ne connaissant pas le contexte ni l'acronyme ARPA)
* `.internal`

Le seul moyen fiable est d'éviter un domaine inexistant et d'utiliser un sous-domaine d'un domaine réel qui nous appartient. Par exemple: `local.sylchamber.ca`.

Dans un contexte purement interne, pour une résidence, on pourrait envisager:

* `.maison.internal`
* `.foyer.internal`
* `.domicile.internal`

C'est sur la 3e option que mon choix se porte: `.domicile.internal`. Le domaine peut être défini comme `domicile.internal` (sans le . en préfixe) dans la configuration d'un routeur Asus sous **Advanced Settings** > **LAN** > **DHCP Server** > **Basic Config** > **RT-AX88U's Domain Name**.

Références

* [.internal - Wikipedia](https://en.m.wikipedia.org/wiki/.internal)
* [Top level domain/domain suffix for private network? - ServerFault](https://serverfault.com/questions/17255/top-level-domain-domain-suffix-for-private-network) (voir les commentaires)
* [RFC9476 The .alt Special-Use Top-Level Domain](https://www.rfc-editor.org/rfc/rfc9476.html)
* [RFC8375 Special-Use Domain 'home.arpa.'](https://www.rfc-editor.org/rfc/rfc8375.html)
* [What's the difference between .local, .home, and .lan? - Unix&Linux](https://unix.stackexchange.com/questions/92441/whats-the-difference-between-local-home-and-lan)
* [Special-Use Domain Names - IANA](https://www.iana.org/assignments/special-use-domain-names/special-use-domain-names.xhtml)

## Exécution avec Podman

Sous openSUSE MicroOS, on doit activer une règle parefeu `firewalld` pour permettre l'entrée sur 53 en TCP en UDP. `cockpit-firewalld` doit être installé, et on peut gérer les règles sous **Réseau > Pare-feu** dans Cockpit. Activer le service `dns` pour débloquer le port TCP 53 et UDP 53.

Pour lancer manuellement CoreDNS avec la configuration par défaut (avec permissions pour exposer le port 53 sur TCP et UDP), pour tester:

> Lancer `podman run coredns/coredns -h` pour obtenir les options de ligne de commande.

```shell
podman run -d -p 53:53 -p 53:53/udp coredns/coredns 
```

on peut tester avec `dig` en spécifiant le serveur:

```shell
# localement
dig @localhost whoami.example.org

# à partir d'un autre ordinateur
dig @motel whoami.example.org
```

> Explorer comment définir un volume pour la configuration avec Podman Quadlet.

## Déploiement comme service Podman Quadlet

On peut utiliser [Podlet](https://github.com/containers/podlet) pour créer la base d'un fichier Podman Quadlet, mais on doit configurer plus de paramètres. Voir les références.

D'abord créer un dossier où sera stockée la configuration de CoreDNS (`Corefile`):

```shell
sudo mkdir -p /var/lib/coredns/etc
cat << EOF | sudo tee /var/lib/coredns/etc/Corefile
.:53 {
    log
    errors
    health
    ready
    forward . 24.200.241.37 24.201.245.77
}

domicile.internal:53 {
    file /etc/coredns/domicile.internal.db
    log
    errors
}
EOF

cat << EOF | sudo tee /var/lib/coredns/etc/domicile.internal.db
; Vérification du format:
; apt install bind9-utils - zypper install bind-utils
; named-checkzone domicile.internal.db

\$ORIGIN domicile.internal.
\$TTL 3600
@       IN      SOA     ns.domicile.internal. silicone95.proton.me. (
                        2024030901  ; Serial
                        7200        ; Refresh
                        3600        ; Retry
                        1209600     ; Expire
                        3600 )      ; Negative Cache TTL

@           IN      NS      ns.domicile.internal.
ns          IN      A       192.168.50.115

arcade      IN      A       192.168.50.185
ai          IN      CNAME   arcade.domicile.internal.
ia          IN      CNAME   arcade.domicile.internal.

motel       IN      A       192.168.50.115
cloud       IN      CNAME   motel.domicile.internal.
k3s         IN      CNAME   motel.domicile.internal.
kubernetes  IN      CNAME   motel.domicile.internal.
nuage       IN      CNAME   motel.domicile.internal.

routeur     IN      A       192.168.50.1
EOF
```

Sous SELinux, on doit également configurer le `label` `container_file_t` sur le dossier afin que podman puisse y accéder, car il n'ajuste pas les permissions pour les fichiers hôte montés comme volumes:

```shell
sudo semanage fcontext -a -t container_file_t "/var/lib/coredns(/.*)?"
sudo restorecon -R -v /var/lib/coredns
```

Ensuite créer un service Quadlet afin de démarrer et gérer un conteneur CoreDNS avec systemd. Utiliser `podlet` pour créer le squelette du fichier service `coredns.container`, en spécifiant le dossier créé à l'étape précédente pour la configuration de CoreDNS:

> L'emplacement par défaut de la configuration de CoreDNS est le dossier où se trouve l'exécutable de CoreDNS. L'option `-conf` ajoutée à CoreDNS permet de configurer l'emplacement du fichier de configuration `Corefile`. Le point de montage `/etc/coredns/Corefile` monté comme volume. L'option `-d` de `podlet` ajoute une description à l'unité systemd, tandis que l'option `--install` configure le lancement au démarrage.

```shell
podlet -d "CoreDNS - DNS and Service Discovery" \
    --install \
    podman run --name coredns \
    -d --restart always \
    -p 53:53 -p 53:53/udp \
    -v /var/lib/coredns/etc:/etc/coredns:ro \
    coredns/coredns:1.12.4 \
    -conf /etc/coredns/Corefile |
    sudo tee /etc/containers/systemd/coredns.container
```

puis ajouter un lien de documentation à l'entête `[Unit]`:

```ini
# coredns.container
[Unit]
Description=CoreDNS - DNS and Service Discovery
Documentation=https://coredns.io/manual/

[Container]
ContainerName=coredns
Exec=-conf /etc/coredns/Corefile
Image=coredns/coredns:1.12.4
PublishPort=53:53
PublishPort=53:53/udp
Volume=/var/lib/coredns/etc:/etc/coredns:ro

[Service]
Restart=always

[Install]
WantedBy=default.target
```

Enfin, on recharge le _daemon_ systemd afin de créer le service:

```shell
systemctl daemon-reload
```

Valider la création du service avec `systemctl cat`:

```shell
> systemctl cat coredns.service 
# /run/systemd/generator/coredns.service
# Automatically generated by /usr/lib/systemd/system-generators/podman-system-generator
# 
# coredns.container
[Unit]
Wants=network-online.target
After=network-online.target
Description=CoreDNS - DNS and Service Discovery
Documentation=https://coredns.io/manual/
SourcePath=/etc/containers/systemd/coredns.container
RequiresMountsFor=%t/containers
RequiresMountsFor=/var/lib/coredns/etc

[X-Container]
ContainerName=coredns
Exec=-conf /etc/coredns/Corefile
Image=coredns/coredns:1.12.4
PublishPort=53:53
PublishPort=53:53/udp
Volume=/var/lib/coredns/etc:/etc/coredns:ro

[Service]
Restart=always
Environment=PODMAN_SYSTEMD_UNIT=%n
KillMode=mixed
ExecStop=/usr/bin/podman rm -v -f -i coredns
ExecStopPost=-/usr/bin/podman rm -v -f -i coredns
Delegate=yes
Type=notify
NotifyAccess=all
SyslogIdentifier=%N
ExecStart=/usr/bin/podman run --name coredns --replace --rm --cgroups=split --sdnotify=conmon -d -v /var/lib/coredns/etc:/etc/coredns:ro --publish 53:53 --publish 53:53/udp coredns/coredns:1.12.4 -conf /etc/coredns/Corefile

[Install]
WantedBy=default.target
```

Finalement, on démarre le service:

> Un service Quadlet ne semble pas pouvoir être activé, puisque systemd rapporte avec `status` qu'il est généré. Pour démarrer automatiquement le service au démarrage, ajouter l'option podlet `--install` pour ajouter la section `[Install]` au service.

```shell
systemctl start coredns
```

* [Quadlet : Exécution de conteneurs podman sous systemd - Linuxtricks](https://www.linuxtricks.fr/wiki/quadlet-execution-de-conteneurs-podman-sous-systemd)
* [How to run Podman containers under Systemd with Quadlet - LinuxConfig](https://linuxconfig.org/how-to-run-podman-containers-under-systemd-with-quadlet)
* [Setup A Simple Homelab DNS Server Using CoreDNS and Docker](https://medium.com/@bensoer/setup-a-private-homelab-dns-server-using-coredns-and-docker-edcfdded841a)
* [Running CoreDNS as a DNS Server in a Container](https://dev.to/robbmanes/running-coredns-as-a-dns-server-in-a-container-1d0)
* [Container units [Container] - podman-systemd.unit - Podman Documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html#container-units-container)

## Configuration DNS dans le routeur Asus

Il suffit finalement de configurer le routeur Asus avec l'adresse IP de a machine hébergeant CoreDNS.

1. Visiter la page de configuration du routeur Asus, [https://192.168.50.1:8443](https://192.168.50.1:8443)
2. Aller à la page **Advanced Settings** > **LAN** > **DHCP Server**
3. Saisir l'adresse IP de la machine hébergeant CoreDNS dans **DNS Server 1**
4. Tester la résolution de noms sous **Advanced Settings** > **Network Tools** > **Network Analysis**

À noter que le routeur Asus ne permet pas de tester la résolution de noms avec des domaines non conformes à la RFC 1035, comme les domaines inventés pour un réseau local.

Également, Ubuntu peut ne pas tenir compte de la configuration DNS du routeur Asus. On peut avoir à spécifier manuellement un fichier `/etc/resolv.conf` avec l'adresse IP du serveur CoreDNS:

```text
nameserver 192.168.50.247
search .
```

## Test de la configuration DNS

Prendre note que le chart Helm de CoreDNS ne supporte qu'une seule zone. On est donc limité à spécifier la zone racine `.:53`, et on peut donc inclure des zones supplémentaires avec le plugin 'file'.

On peut tester la syntaxe de la configuration en extrayant les valeurs du `zoneFile` `ici.db` dans un fichier puis en le vérifiant avec `named-checkzone`:

```shell
# openSUSE MicroOS
sudo transactional-update pkg install bind-utils
# debian
sudo apt install bind9-utils
named-checkzone rloc rloc.db
```

Pour tester la résolution de noms, il faut utiliser `dig`:

> Ou encore `nslookup` dans les conteneurs `busybox:1.28`.

```shell
dig @192.168.50.247 motel.rloc
```

## Déploiement dans k3s

> Ce déploiement dans k3s implique une perte de service dans certaines situations où k3s est hors service. Préférer une installation hors k3s via un service podman Quadlet.

Un serveur DNS est déployé dans `k3s` pour la résolution de noms dans le réseau local, puisque ça semble problématique avec le routeur wifi Asus.

Le même serveur DNS que celui déployé dans `k3s` ― CoreDNS ― est déployé dans un _namespace_ distinct afin d'éviter de nuire à la résolution de noms dans le cluster. Puisqu'Ubuntu utilise le port `53` avec `systemd-resolved` pour la résolution de noms locale, ce dernier est désactivé afin d'utiliser le port `53` avec le déploiement de CoreDNS.

Le déploiement se fait à l'aide du chart `coredns` du repo officiel de CoreDNS. Le fichier `values.yaml` est utilisé pour configurer le serveur DNS:

```shell
kubectl create namespace lan-dns
helm install lan-dns coredns/coredns -f values.yaml -n lan-dns
```

Pour mettre à jour les entrées DNS, il faut modifier le fichier `values.yaml` et relancer le déploiement du chart `coredns`:

```shell
helm upgrade lan-dns coredns/coredns -f values.yaml -n lan-dns
```

Sur le serveur Ubuntu, il faut désactiver la résolution DNS locale avec `systemd-resolved` en créant le fichier `/etc/systemd/resolved.conf.d/lan-dns.conf` :

```shell
cat << EOF | sudo tee /etc/systemd/resolved.conf.d/lan-dns.conf
# Résolution DNS avec CoreDNS hébergé dans le cluster k8s local
[Resolve]
DNS=127.0.0.1 24.200.241.37 24.201.245.77
DNSStubListener=no
EOF
```

> `DNSStubListener=no` désactive la résolution locale du service `systemd-resolved` qui crée un DNS _stub_ qui redirige les requêtes DNS vers le serveur DNS du routeur. Ça nécessite de spécifier le serveur DNS local ainsi que les adresses IP des serveurs DNS du fournisseur. Il est inutile de spécifier l'adresse IP du routeur, puisque nous allons le configurer pour qu'il utilise le serveur DNS CoreDNS hébergé dans le cluster k3s local.

Redémarrer le service `systemd-resolved` pour prendre en compte les modifications:

```shell
sudo systemctl restart systemd-resolved
```

Il faut ensuite remplacer le fichier de configuration `/etc/resolv.conf` par un lien symbolique vers le fichier de configuration de `systemd-resolved`:

```shell
sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

On peut vérifier la résolution DNS avec `resolvectl status`. Le mode `resolv.conf` devrait être `uplink`:

```shell
> resolvectl status
Global
         Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
  resolv.conf mode: uplink
       DNS Servers: 127.0.0.1 24.200.241.37 24.201.245.77

Link 2 (eno1)
    Current Scopes: DNS
         Protocols: +DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
       DNS Servers: 192.168.50.1
```

Sur un système Ubuntu par défaut, la configuration **Global** spécifiera le mode `stub`:

```shell
> resolvectl status
Global
         Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
  resolv.conf mode: stub
```

On peut vérifier l'écoute sur le port 53 avec `ss` ou `netstat`:

```shell
sudo ss -tuln | grep 53
```

S'il n'y a plus de _stub_ DNS sur `systemd-resolved`, on ne devrait plus voir de service écoutant sur `127.0.0.53:53`.

## Références

* [Chart CoreDNS](https://github.com/coredns/helm)
* [CoreDNS Docker Image](https://hub.docker.com/r/coredns/coredns/)
* [Custom DNS Entries For Kubernetes - CoreDNS Blog](https://coredns.io/2017/05/08/custom-dns-entries-for-kubernetes/)
