# Déploiement d'un serveur DNS pour le réseau local

Un serveur DNS est déployé dans `k3s` pour la résolution de noms dans le réseau local, puisque ça semble problématique avec le routeur wifi Asus.

Le même serveur DNS que celui déployé dans `k3s` ― CoreDNS ― est déployé dans un _namespace_ distinct afin d'éviter de nuire à la résolution de noms dans le cluster. Le port `5353` est utilisé pour éviter les conflits avec le DNS de l'hôte, puisqu'Ubuntu utilise le port `53` avec `systemd-resolved` pour la résolution de noms locale.

Le déploiement se fait à l'aide du chart `coredns` du repo officiel de CoreDNS. Le fichier `values.yaml` est utilisé pour configurer le serveur DNS:

```shell
kubectl create namespace lan-dns
helm install lan-dns coredns/coredns -f values.yaml -n lan-dns
```

Pour mettre à jour les entrées DNS, il faut modifier le fichier `values.yaml` et relancer le déploiement du chart `coredns`:

```shell
helm upgrade lan-dns coredns/coredns -f values.yaml -n lan-dns
```

## Test de la configuration DNS

On peut tester la syntaxe de la configuration en extrayant les valeurs du `zoneFile` `ici.db` dans un fichier puis en le vérifiant avec `named-checkzone`:

```shell
sudo apt install bind9-utils
named-checkzone ici ici.db
```

Pour tester la résolution de noms, il faut utiliser `dig`:

```shell
dig @192.168.50.247 -p 5353 motel.ici
```

En principe, on devrait pouvoir configurer le routeur pour qu'il utilise ce serveur DNS: `192.168.50.247#5353`.

## Références

- [Chart CoreDNS](https://github.com/coredns/helm)
- [Custom DNS Entries For Kubernetes - CoreDNS Blog](https://coredns.io/2017/05/08/custom-dns-entries-for-kubernetes/)
