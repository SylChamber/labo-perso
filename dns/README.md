# Déploiement d'un serveur DNS pour le réseau local

Un serveur DNS est déployé dans `k3s` pour la résolution de noms dans le réseau local, puisque ça semble problématique avec le routeur wifi Asus.

Le même serveur DNS que celui déployé dans `k3s` ― CoreDNS ― est déployé dans un _namespace_ distinct afin d'éviter de nuire à la résolution de noms dans le cluster.

Le déploiement se fait à l'aide du chart `coredns` du repo officiel de CoreDNS.

Le fichier `values.yaml` est utilisé pour configurer le serveur DNS.

Pour mettre à jour les entrées DNS, il faut modifier le fichier `values.yaml` et relancer le déploiement du chart `coredns`:

```shell
helm upgrade dns-lan coredns/coredns -f values.yaml -n dns-lan
```

## Références

- [Chart CoreDNS](https://github.com/coredns/helm)
- [Custom DNS Entries For Kubernetes - CoreDNS Blog](https://coredns.io/2017/05/08/custom-dns-entries-for-kubernetes/)
