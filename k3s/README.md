# Cluster Kubernetes k3s

## Installation dans un OS immuable

Un OS immuable à faible entretien et faible empreinte a été sélectionné pour héberger un cluster k3s: [openSUSE MicroOS](https://microos.opensuse.org/). Pour la procédure d'installation du serveur avec `k3s`, voir [Déploiement d'openSUSE MicroOS ou Leap Micro](../microos/README.md).

## GitOps

L'automatisation permet de gagner du temps au final. Le déploiement des applications dans le cluster sera donc géré selon les principes GitOps. [Argo CD](https://argo-cd.readthedocs.io/) a été choisi par familiarité.

On peut profiter de la [fonctionnalité du contrôleur Helm](https://docs.k3s.io/helm) pour déployer Argo CD via un Helm chart, mais directement via `kubectl` à l'aide de manifestes YAML. De cette façon, les mises à jour d'Argo CD pourront également être faites en GitOps.

Voir:

* [Installation - ArgoCD](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/#helm)
* [Argo CD Helm Chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
* [Helm - docs.k3s.io](https://docs.k3s.io/helm)

## Niveau de sécurité des pods

Explorer comment activer le profil `Restricted` et l'impact sur les déploiements.

* [Pod Security Admission - Kubernetes](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
* [Pod Security Standards - Kubernetes](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

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

## Sauvegardes

`k3s` utilise une BD SQLite par défaut, il n'y a donc pas de BD `etcd` à sauvegarder. Il n'y a que des fichiers à sauvegarder:

* BD: `/var/lib/rancher/k3s/server/db/`
  * token requis: `/var/lib/rancher/k3s/server/token`
* Stockage (volumes): `/var/lib/rancher/k3s/storage`

Références

* [Backup and Restore - docs.k3s.io](https://docs.k3s.io/datastore/backup-restore)
* [Storage - docs.k3s.io](https://docs.k3s.io/storage)
* [Configuration - local-path-provisioner](https://github.com/rancher/local-path-provisioner/blob/master/README.md#configuration)

## Operator Lifecycle Manager

Les opérateurs sont intéressants. Toutefois, j'ai choisi de ne pas les employer avec `k3s` pour les raisons suivantes:

* OLM v0 est en mode maintenance et sera éventuellement remplacé par OLM v1, pour lequel il ne semble pas y avoir de magasin encore
* OLM v0 ne s'installe que par le biais d'une CLI qu'on doit au préalable télécharger
  * on s'écarte de l'idéal Kubernetes d'installer par le biais de manifestes YAML
* OLM utilise des ressources dans le cluster
* certains projets d'importance (comme `cert-manager`) ont décidé de ne plus supporter d'opérateur
* `k3s` intègre un contrôleur Helm permettant d'automatiser par Kubernetes l'installation de charts

Référence

* [Helm - docs.k3s.io](https://docs.k3s.io/helm)

## Installation manuelle

Dans mes expérimentations, un cluster Kubernetes k3s a d'abord été déployé sur un vieux portable.

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

## Installation dans un OS Fedora atomique

> openSUSE MicroOS/Leap Micro a finalement été choisi comme OS serveur.

Pour installation dans un OS de type Fedora Core OS ou bootc où le système de fichiers est immuable, il est préférable de ne pas utiliser le logiciel d'installation de `k3s` car ce dernier fait surtout de la configuration (en plus d'installer des prérequis au besoin, comme la [politique SELinux](https://docs.k3s.io/advanced#selinux-support) sous la famille Red Hat).

Après tout, dans cette situation, on désire une image d'OS qui inclut `k3s` mais qui permet de le configurer. Il faut donc reproduire les étapes du script d'installation. On peut suivre cette approche:

* on se limite à installer les prérequis:
  * `container-selinux` est déjà installé;
  * `selinux-policy-base` listé dans la documentation de `k3s` n'existe pas, donc à vérifier;
  * `k3s-selinux` disponible sur [github.com/k3s-io/k3s-selinux](https://github.com/k3s-io/k3s-selinux) (politique SELinux)
* on télécharge directement le binaire de `k3s` et on l'installe à l'endroit approprié (en accord avec la politique SELinux)
  * en fait, le script d'installation permet de spécifier les emplacements:
    * des binaires (par défaut, `/usr/local/bin`): indiquer `/usr/bin`
    * des services systemd (par défaut, `/etc/systemd/system`): indiquer `/usr/lib/systemd/system`
* on crée les dossiers requis avec les bonnes permissions (inutile avec le script)
* `/etc`, `/var` et `/usr/local` sont persistants et modifiables et réservés à l'utilisateur
  * `/usr/local` est un symlink vers `/var/usrlocal`
  * alors on n'y installe rien, puisqu'ils seront copiés à l'installation initiale
  * toute mise à jour système subséquente ne verra pas de nouveaux changements (`/etc` est soumis à une fusion tri-partite)
* placer la configuration sous `/usr` (voir la [doc bootc sur la configuration](https://bootc-dev.github.io/bootc/building/guidance.html#configuration-in-usr-vs-etc)) et faire un symlink sous `/etc`
  * ça nécessite toutefois d'ajuster les politiques SELinux
* on configure les options par défaut dans `/usr/lib/rancher/k3s/config.yaml`
  * avec un symlink dans `/etc/rancher/k3s/config.yaml`
* utiliser `/var` pour les données de `k3s`
  * en fait, c'est k3s lui-même qui semble créer les fichiers sous `/var/lib/rancher`
* on peut ajouter des composantes à déployer dans `/var/lib/rancher/k3s/server/manifests`
  * ce peut être des [HelmChartConfigs](https://docs.k3s.io/helm#customizing-packaged-components-with-helmchartconfig)
  * inclure [Operator Lifecycle Manager (OLM) v1](https://github.com/operator-framework/operator-controller) (_Operator Controller_ et _Catalogd_, le successeur de Operator Lifecycle Manager (OLM v0)
  * et `cert-manager`, dont OLM v1 dépend
  * on peut les définir sous `/usr/lib/rancher/k3s/server/manifests` et les lier dans `/var/lib`
* on crée manuellement les services et on les active
  * en fait, le script peut s'en charger puisqu'on peut lui spécifier où les créer
* on laisse le soin aux utilisateurs de l'image de configurer les options spécifiques dans `/etc/rancher/k3s/config.yaml.d/*.yaml`
  * ou encore des `CertificateSigningRequest`s dans `/var/lib/rancher/k3s/server/manifests` (symlink)
  * vérifier si on peut ajouter des manifestes d'opérateurs, comme Argo CD

Voici les instructions shell pour l'installer avec les directives ci-dessus dans AlmaLinux 9 installé avec LibVirt:

```shell
TMP_DIR=$(mktemp -d /tmp/k3s-install-XXXXXX)
cd $TMP_DIR
curl -sfLo install-k3s.sh https://get.k3s.io
chmod +x ./install-k3s.sh
sudo mkdir -p /etc/rancher/k3s
sudo mkdir -p /usr/lib/rancher/k3s
cat << EOF | sudo tee /usr/lib/rancher/k3s/config.yaml
# configuration K3s
secrets-encryption: true
tls-san:
  - k3s.rloc
  - kubernetes.rloc
kube-apiserver-arg:
  # Activer l'ajout automatique des tolérances de ressources étendues, ex. nvidia.com/gpu
  - enable-admission-plugins=ExtendedResourceToleration
EOF
sudo ln -s /usr/lib/rancher/k3s/config.yaml /etc/rancher/k3s/config.yaml

INSTALL_K3S_BIN_DIR=/usr/bin \
INSTALL_K3S_SYSTEMD_DIR=/usr/lib/systemd/system \
./install-k3s.sh
# sauvegarder le jeton 'TOKEN' `/var/lib/rancher/k3s/server/token`
# requis pour joindre des nœuds (agents)
```

## Références

* [Documentation officielle de k3s](https://docs.k3s.io/)
* [Configuration Options - k3s Docs](https://docs.k3s.io/installation/configuration)
  * [Multiple Config Files - Configuration Options - k3s Docs](https://docs.k3s.io/installation/configuration?_highlight=config.yaml.d#multiple-config-files)
* [Upgrades - k3s Docs](https://docs.k3s.io/upgrades)
* [Taints and Tolerations - Example Use Cases - Kubernetes Docs](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#example-use-cases)
* [Resource Management for Pods and Containers - Extended resources - Kubernetes Docs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#extended-resources)
* [Admission Control in Kubernetes - ExtendedResourceToleration - Kubernetes Docs](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#extendedresourcetoleration)
* [Schedule GPUs - Kubernetes Docs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)
* [Operator Lifecycle Manager (OLM) v1](https://github.com/operator-framework/operator-controller)
* [OLM v1 releases - operator-framework/operator-controller](https://github.com/operator-framework/operator-controller/releases)
* [Building Images - bootc](https://bootc-dev.github.io/bootc/building/guidance.html)
