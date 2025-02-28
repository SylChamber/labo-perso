# Cluster Kubernetes k3s

Un cluster Kubernetes k3s est déployé sur un vieux portable Dell Latitude E7250.

* Le [script d'installation a été téléchargé du site k3s.io](https://get.k3s.io)
* le script a été lancé avec les arguments suivants : `--tls-san="kubernetes.ici,cloud.ici,nuage.ici" --secrets-encryption="true"`
  * le chiffrement des secrets dans `etcd` est activé
  * le certificat racine inclut les `subjectAltNames`:
    * `kubernetes.ici`
    * `cloud.ici`
    * `nuage.ici`

On peut faire l'installation à l'aide d'un [fichier de configuration k3s](https://docs.k3s.io/installation/configuration#configuration-file):

D'abord, créer le fichier de configuration k3s:

```shell
sudo mkdir -p /etc/rancher/k3s
cat << EOF | sudo tee /etc/rancher/k3s/config.yaml
# configuration K3s
secrets-encryption: true
tls-san:
  - kubernetes.ici
  - cloud.ici
  - nuage.ici
  - motel.ici
EOF
```

Ensuite, installer k3s à l'aide du fichier de configuration:

```shell
curl -sfL https://get.k3s.io | sh
```

## Références

* [Documentation officielle de k3s](https://docs.k3s.io/)
* [Upgrades - k3s Docs](https://docs.k3s.io/upgrades)
* [Documentation officielle de Kubernetes](https://kubernetes.io/)
