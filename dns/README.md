# Déploiement d'un serveur DNS pour le réseau local

> Comme ce serveur DNS est un prérequis pour le cluster Kubernetes, envisager de déployer CoreDNS comme conteneur Podman et de l'installer comme service systemd avec Podman Quadlet.

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
sudo apt install bind9-utils
named-checkzone rloc rloc.db
```

Pour tester la résolution de noms, il faut utiliser `dig`:

> Ou encore `nslookup` dans les conteneurs `busybox:1.28`.

```shell
dig @192.168.50.247 motel.rloc
```

## Références

* [Chart CoreDNS](https://github.com/coredns/helm)
* [CoreDNS Docker Image](https://hub.docker.com/r/coredns/coredns/)
* [Custom DNS Entries For Kubernetes - CoreDNS Blog](https://coredns.io/2017/05/08/custom-dns-entries-for-kubernetes/)
