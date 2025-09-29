# Gestion des certificats

Les applications sur un réseau local auront besoin de certificats TLS pour le chiffrement des communications. Afin d'éviter de créer manuellement une autorité de certificat puis les certificats subséquents, déployer le serveur ACME et d'autorité privée de certrificat [step-ca](https://github.com/smallstep/certificates).

Il sera déployé dans Kubernetes car c'est plus simple, et il sera possible de définir un domaine sans port (avec SNI) pour y accéder.

> Comme indiqué dans les instructions d'installation de step-ca pour Kubernetes, envisager de déployer [autocert](https://github.com/smallstep/autocert), un addiciel Kubernetes permettant l'injection automatique de certificats dans les conteneurs et ainsi permettre le mTLS dans Kubernetes. À voir s'il est utile si on utilise cert-manager.

## Exécution en conteneur pour tests

Afin de tester le fonctionnement et de l'explorer, on peut lancer `step-ca` comme conteneur:

```shell
podman run -it --rm \
    -v step:/home/step \
    -p 9000:9000 \
    -e "DOCKER_STEPCA_INIT_NAME=SylChamber CA .internal" \
    -e "DOCKER_STEPCA_INIT_DNS_NAMES=localhost,$(hostname -f)" \
    -e "DOCKER_STEPCA_INIT_REMOTE_MANAGEMENT=true" \
    -e "DOCKER_STEPCA_INIT_ACME=true" \
    smallstep/step-ca
```

## Configuration initiale de step-ca pour Kubernetes

`step-ca` dispose d'un chart Helm, [step-certificates](https://artifacthub.io/packages/helm/smallstep/step-certificates). L'outil en ligne de commande `step` permet de générer une configuration pour `step-ca`:

```shell
brew install step
step ca init --helm 
```

Cette commande lancera un assistant pour générer un fichier `values.yaml` pour le chart Helm:

> Si on modifie `ca.dns` ou `--dns` ou comme option de commande, il faut ajouter tout domaine pouvant être utilisé à l'interne dans Kubernetes (tel qu'indiqué dans le README du chart). Ici, on présume un nom de _release_ `acme` et un déploiement dans le _namespace_ `step-ca`.

```shell
> step ca init --helm
✔ Deployment Type: Standalone
What would you like to name your new PKI?
✔ (e.g. Smallstep): SylChamber
What DNS names or IP addresses will clients use to reach your CA?
✔ (e.g. ca.example.com[,10.1.2.3,etc.]): ca.internal,ac.internal,acme-step-certificates.step-ca.svc.cluster.local,127.0.0.1
What IP and port will your new CA bind to (it should match service.targetPort)?
✔ (e.g. :443 or 127.0.0.1:443): :9100
What would you like to name the CA's first provisioner?
✔ (e.g. you@smallstep.com): moi@proton.me
Choose a password for your CA keys and first provisioner.
✔ [leave empty and we'll generate one]: 
✔ Password: ****************

Generating root certificate... done!
Generating intermediate certificate... done!
# Helm template
inject:
  enabled: true
  # Config contains the configuration files ca.json and defaults.json
(...)
```

> On doit spécifier le port de liaison (_bind_) car il sera inscrit dans la configuration de `step-ca`, sous `inject.config.files.ca\.json`. C'est le `targetPort` du service, soit le port du conteneur sur lequel l'application sera exposée. La valeur par défaut de `service.targetPort` est `9100`, aussi bien utiliser la valeur par défaut. C'est sous-optimal que la commande `step ca init` ne puisse modifier le port aux deux endroits.

On peut fournir les valeurs en option à la commande `step ca init` afin de générer le fichier sans interaction:

```shell
 echo "mot-de-passe" > ~/tmp/provisioner-password
step ca init --helm --deployment-type=standalone \
--name SylChamber \
--dns=ca.internal \
--dns=ac.internal \
--dns=acme-step-certificates.step-ca.svc.cluster.local \
--dns=127.0.0.1 \
--acme \
--address=:9100 \
--provisioner=moi@proton.me \
--password-file=provisioner-password \
--provisioner-password-file=$HOME/tmp/provisioner-password
```

Le fichier `values.yaml` généré incluera les certificats publics racine et intermédiaire, ainsi que les certificats privés sous une forme chiffrée. Toutefois, le fichier n'inclut pas le mot de passe utilisé pour chiffrer les clés, ni le mot de passe du provisionneur par défaut (les instructions de déploiement utilisent le même mot de passe pour les deux). Ils doivent être injectés par la ligne de commande `helm install`.

Dans un contexte GitOps, il est préférable d'utiliser la configuration avancée, et de définir les secrets à l'avance dans Kubernetes et d'utiliser la propriété `existingSecrets` du chart. La génération de la configuration a quand même son utilité, afin de générer les certificats et un `values.yaml` de base.

## Exposition de step-ca avec Ingress

Par défaut, `step-ca` est exposé avec un service `NodePort`. Le chart supporte toutefois l'exposition avec un `Ingress`.

## Installation dans Kubernetes

D'abord installer le dépôt Helm:

```shell
helm repo add smallstep https://smallstep.github.io/helm-charts/
helm repo update
```

ensuite installer `step-ca` dans Kubernetes:

```shell

```

## Références

* [ACME - Automatic Certificate Management Environment](https://en.wikipedia.org/w/index.php?title=Automatic_Certificate_Management_Environment)
* [Self-Host ACME Server](https://blog.sean-wright.com/self-host-acme-server/)
* [Run your own private CA & ACME server using step-ca](https://smallstep.com/blog/private-acme-server/)
* [step-ca - Github](https://github.com/smallstep/certificates)
* [step-ca Documentation](https://smallstep.com/docs/step-ca/)
  * [step-ca Installation](https://smallstep.com/docs/step-ca/installation/#kubernetes)
  * [step-ca Getting Started](https://smallstep.com/docs/step-ca/getting-started/)
* [step-certificates - ArtifactHUB](https://artifacthub.io/packages/helm/smallstep/step-certificates)
* [step-ca Docker Image - Docker Hub](https://hub.docker.com/r/smallstep/step-ca)
