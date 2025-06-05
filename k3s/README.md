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

## Ajout d'un utilisateur

L'ajout d'utilisateurs se fait via des [Certificate Signing Requests](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#normal-user) (CSR).

L'utilisateur se crée d'abord une clé:

> L'approche traditionnelle est d'utiliser l'algorithme RSA et de produire des clés de 2048 bits. Toutefois, la documentation d'OpenSSL mentionne que `genrsa` est remplacée par `openssl genpkey`. Également, selon Claude Sonnet 3.7, Kubernetes accepte également des clés ECDSA de 256 bits avec la courbe P-256.

```shell
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out user.key
```

et ensuite une CSR dans laquelle:

* le CN (_common name_) est le nom de l'utilisateur
* le O (_organization_) est le groupe dont il fera partie

> Le groupe [system:masters](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) ne peut être utilisé dans une demande de signature de certificat. Il faut créer un groupe pour les administrateurs, et ensuite configurer un `ClusterRoleBinding` de ce groupe avec le rôle `cluster-admin`. Voir [cluster-admins.yaml](cluster-admins.yaml).

Ces champs sont optionnels:

* le L (_locality_) est le nom de la ville
* le ST (_state_) est le nom de l'état ou de la province
* le C (_country_) est le code de deux lettres du pays

On crée la CSR ainsi:

```shell
openssl req -new -key user.key -out user.csr -subj "/CN=user/O=cluster-admins"
```

Convertir le CSR en base64 afin de le copier-coller dans un manifeste CSR pour Kubernetes:

```shell
cat user.csr | base64 -w0 ; echo
```

Créer le manifeste CSR pour Kubernetes et l'appliquer, en collant le contenu du CSR encodé en base64 dans le champ `spec.request`. Ou encore lancer cette commande:

```shell
cat <<EOF > user-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: user
spec:
  request: $(cat user.csr | base64 -w0)
  signerName: kubernetes.io/kube-apiserver-client
  usages:
    - client auth
    - digital signature
    - key encipherment
EOF
```

Puis, à l'aide de l'utilisateur `kubeadmin`, approuver la demande de signature de certificat:

```shell
kubectl certificate approve user
```

Approuver la demande:

```shell
kubectl certificate approve user
```

Récupérer le certificat signé:

```shell
kubectl get csr user -o jsonpath='{.status.certificate}' |
  base64 -d > user.crt
```

Vérifier le certificat:

```shell
openssl x509 -in user.crt -text -noout
```

Utiliser le certificat pour ajouter l'utilisateur à la configuration `kubectl`:

> Stocker le certificat et sa clé dans un dossier sécurisé, par exemple `~/.kube`, et s'assurer du mode d'accès approprié (`chmod 700 ~/.kube && chmod 600 ~/.kube/*`). Ne pas inclure les fichiers dans le `kubeconfig`, car les certificats expirent après 1 an. Ce sera ainsi plus facile de les mettre à jour.

```shell
kubectl config set-credentials user@cluster \
  --client-certificate=user.crt \
  --client-key=user.key

kubectl config set-context user@cluster \
  --cluster=cluster \
  --user=user@cluster

kubectl config use-context user@cluster
```

Valider le fonctionnement:

```shell
kubectl auth whoami
```

Références:

* [openssl - man page](https://manned.org/man/ubuntu-noble/openssl)

## Installation dans un OS atomique de la famille Fedora Core OS

Pour installation dans un OS de type Fedora Core OS ou uCore (qui en dérive) où le système de fichiers est immuable, il est préférable de ne pas utiliser le logiciel d'installation de `k3s` car ce dernier fait surtout de la configuration (en plus d'installer des prérequis au besoin, comme la [politique SELinux](https://docs.k3s.io/advanced#selinux-support) sous la famille Red Hat).

Après tout, dans cette situation, on désire une image d'OS qui inclut `k3s` mais qui permet de le configurer. Il faut donc reproduire les étapes du script d'installation. On peut suivre cette approche:

* on se limite à installer les prérequis:
  * `container-selinux` est déjà installé;
  * `selinux-policy-base` listé dans la documentation de `k3s` n'existe pas, donc à vérifier;
  * `k3s-selinux` disponible sur [github.com/k3s-io/k3s-selinux](https://github.com/k3s-io/k3s-selinux) (politique SELinux)
* on télécharge directement le binaire de `k3s` et on l'installe à l'endroit approprié (en accord avec la politique SELinux)
* on crée les dossiers requis avec les bonnes permissions
* on configure les options par défaut dans `/etc/rancher/k3s/config.yaml`
* on peut ajouter des composantes à déployer dans `/var/lib/rancher/k3s/server/manifests`
  * ce peut être des [HelmChartConfigs](https://docs.k3s.io/helm#customizing-packaged-components-with-helmchartconfig)
  * inclure [Operator Lifecycle Manager (OLM) v1](https://github.com/operator-framework/operator-controller) (_Operator Controller_ et _Catalogd_, le successeur de Operator Lifecycle Manager (OLM v0)
* on crée manuellement les services et on les active
* on laisse le soin aux utilisateurs de l'image de configurer les options spécifiques dans `/etc/rancher/k3s/config.yaml.d/*.yaml` (à déterminer comment faire, s'il est possible de le faire dans le fichier _ignition_)
  * ou encore des `CertificateSigningRequest`s dans `/var/lib/rancher/k3s/server/manifests`
  * vérifier si on peut ajouter des manifestes d'opérateurs, comme Argo CD

## Références

* [Documentation officielle de k3s](https://docs.k3s.io/)
* [Configuration Options - k3s Docs](https://docs.k3s.io/installation/configuration)
* [Upgrades - k3s Docs](https://docs.k3s.io/upgrades)
* [Taints and Tolerations - Example Use Cases - Kubernetes Docs](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#example-use-cases)
* [Resource Management for Pods and Containers - Extended resources - Kubernetes Docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#extended-resources)
* [Admission Control in Kubernetes - ExtendedResourceToleration - Kubernetes Docs](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#extendedresourcetoleration)
* [Schedule GPUs - Kubernetes Docs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)
* [Operator Lifecycle Manager (OLM) v1](https://github.com/operator-framework/operator-controller)
* [OLM v1 releases - operator-framework/operator-controller](https://github.com/operator-framework/operator-controller/releases)
