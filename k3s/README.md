# Cluster Kubernetes k3s

Un cluster Kubernetes k3s est déployé sur un vieux portable Dell Latitude E7250.

* Le [script d'installation a été téléchargé du site k3s.io](https://get.k3s.io)
* le script est lancé avec les arguments suivants : `--tls-san="kubernetes.rloc,cloud.rloc,nuage.rloc" --secrets-encryption="true"`
  * le chiffrement des secrets dans `etcd` est activé
  * le certificat racine inclut les `subjectAltNames`:
    * `kubernetes.rloc`
    * `cloud.rloc`
    * `nuage.rloc`

On peut faire l'installation à l'aide d'un [fichier de configuration k3s](https://docs.k3s.io/installation/configuration#configuration-file):

D'abord, créer le fichier de configuration k3s:

```shell
sudo mkdir -p /etc/rancher/k3s
cat << EOF | sudo tee /etc/rancher/k3s/config.yaml
# configuration K3s
secrets-encryption: true
tls-san:
  - kubernetes.rloc
  - cloud.rloc
  - nuage.rloc
  - motel.rloc
kube-apiserver-arg:
  # Activer l'ajout automatique des tolérances de ressources étendues, ex. nvidia.com/gpu
  - enable-admission-plugins=ExtendedResourceToleration
EOF
```

Ensuite, installer k3s à l'aide du fichier de configuration:

```shell
curl -sfL https://get.k3s.io | sh
```

## Ajout d'un noœud à GPU

Avant d'ajouter un nœud, [déployer le serveur DNS du réseau local](../dns/README.md) afin de bénéficier de la résolution de nom sur le réseau local.

Ensuite créer le fichier de configuration du nœud:

> On ajoute

```shell
sudo mkdir -p /etc/rancher/k3s
cat << EOF | sudo tee /etc/rancher/k3s/config.yaml
# configuration d'un agent, un worker k3s
server: https://kubernetes.rloc:6443
token-file: /etc/rancher/k3s/node-token
default-runtime: nvidia
node-label:
  - gpu=nvidia
EOF
```

> On spécifie ici le runtime par défaut comme étant `nvidia` afin de supporter l'utilisation du GPU pour exécuter des charges de travail GPU.

Copier le token du serveur pour l'inscription d'agents: `/var/lib/rancher/k3s/server/node-token` et le coller dans `/etc/rancher/k3s/node-token`.

```shell
# inclure un espace au début
 TOKEN='......'
echo $TOKEN | sudo tee /etc/rancher/k3s/node-token
sudo chmod 600 /etc/rancher/k3s/node-token
```

Ensuite, installer k3s à l'aide du fichier de configuration:

```shell
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" sh
```

## Références

* [Documentation officielle de k3s](https://docs.k3s.io/)
* [Configuration Options - k3s Docs](https://docs.k3s.io/installation/configuration)
* [Upgrades - k3s Docs](https://docs.k3s.io/upgrades)
* [Taints and Tolerations - Example Use Cases - Kubernetes Docs](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#example-use-cases)
* [Resource Management for Pods and Containers - Extended resources - Kubernetes Docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#extended-resources)
* [Admission Control in Kubernetes - ExtendedResourceToleration - Kubernetes Docs](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#extendedresourcetoleration)
* [Schedule GPUs - Kubernetes Docs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)
