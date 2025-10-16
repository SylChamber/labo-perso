# Gestion des certificats

Les applications sur un réseau local auront besoin de certificats TLS pour le chiffrement des communications. Afin d'éviter de gérer manuellement une autorité de certificat puis les certificats subséquents, le serveur ACME et d'autorité privée de certrificat [step-ca](https://github.com/smallstep/certificates) sera déployé.

Il le sera dans Kubernetes car c'est plus simple, et il sera possible de définir un domaine sans port (avec SNI) pour y accéder.

> Comme indiqué dans les instructions d'installation de step-ca pour Kubernetes, envisager de déployer [autocert](https://github.com/smallstep/autocert), un addiciel Kubernetes permettant l'injection automatique de certificats dans les conteneurs et ainsi permettre le mTLS dans Kubernetes. À voir s'il est utile si on utilise cert-manager.

Toutefois, les certificats étant omniprésents dans les communications sur un réseau local, la priorité est de créer une autorité de certificat racine privée à l'aide de la CLI `step`, ainsi qu'une autorité intermédiaire. Les deux autorités pourront être utilisées dans la configuration de `step-ca`.

## Création d'autorités privées de certificat racine et intermédiaires

Bien qu'on puisse créer manuellement des autorités de certificat à l'aide de la CLI `openssl`, l'opération est plus simple à l'aide de la CLI `step`.

> Voir le dossier `examples/certificate_authority_single_instance` du chart Helm [step-certificates](https://artifacthub.io/packages/helm/smallstep/step-certificates) sur ArtifactHUB pour un exemple de création d'autorités racine et intermédiaire. À noter qu'il y a une erreur de nommage des champs dans les gabarits `root-tls.json.tpl` et `intermediate-tls.json.tpl`. Se référer à la [documentation de la bibliothèque x509util](https://pkg.go.dev/go.step.sm/crypto/x509util#Name) pour les bons noms.

On utilise la commande `step certificate create` pour créer une autorité de certificat, en spécifiant un gabarit en JSON pour les champs à compléter:

```json
# root-tls.json.tpl
{
  "subject": {
    "commonName": "${ROOT_CA_NAME}",
    "organization": "${ORGANISATION}",
    "country": "${COUNTRY}",
    "province": "${PROVINCE}"
  },
  "keyUsage": [ "certSign", "crlSign" ],
  "basicConstraints": {
    "isCA": true,
    "maxPathLen": 1
  }
}

# intermediate-tls.json.tpl
{
  "subject": {
    "commonName": "${INTERMEDIATE_CA_NAME}",
    "organization": "${ORGANISATION}",
    "country": "${COUNTRY}",
    "province": "${PROVINCE}"
  },
  "keyUsage": [ "certSign", "crlSign" ],
  "basicConstraints": {
    "isCA": true,
    "maxPathLen": 1
  }
}
```

Ces gabarits réfèrent à des variables d'environnement. On définit les variables (par exemple, `export ORGANISATION=SylChamber`) puis on utilise `envsubst` pour générer les fichiers JSON à fournir à `step`:

```shell
cat root-tls.json.tpl | envsubst | tee root-tls.json
cat intermediate-tls.json.tpl | envsubst | tee intermediate-tls.json
```

On peut ensuite faire générer les autorités de certificat par `step`:

```shell
# 25 ans
NOT_AFTER=219144h
# autorité racine; définir un mot de passe dans 'root-tls.password'
step certificate create \
  "${ORGANISATION} Root Private Authority" \
  "root-tls.crt" \
  "root-tls.key" \
  --template="root-tls.json" \
  --kty="EC" \
  --curve="P-256" \
  --password-file="root-tls.password" \
  --not-before="0s" \
  --not-after="$NOT_AFTER" \
  --force
# autorité intermédiaire; définir un mot de passe dans 'intermediate-tls.password'
step certificate create \
  "${ORGANISATION} Intermediate Private Authority" \
  "intermediate-tls.crt" \
  "intermediate-tls.key" \
  --template="intermediate-tls.json" \
  --kty="EC" \
  --curve="P-256" \
  --password-file="intermediate-tls.password" \
  --not-before="0s" \
  --not-after="$NOT_AFTER" \
  --ca="root-tls.crt" \
  --ca-key="root-tls.key" \
  --ca-password-file="root-tls.password" \
  --force
```

Voir le script sous [scripts/creer-ca.sh](../../scripts/creer-ca.sh) qui automatise ces opérations.

## Création d'un certificat TLS à l'aide de la cli step

Puisque `step-ca` sera déployé dans Kubernetes, il sera utile de pouvoir créer un certificat _leaf_ pour une application hébergée hors Kubernetes, par exemple Cockpit. La cli `step` permet de faire certaines opérations sans nécessiter le déploiement de `step-ca`.

> Tout certificat sera créé avec la signature du certificat intermédiaire. Les certificats seront stockés sous
> `~/.local/state/step/certs`.

Pour créer un certificat _leaf_ pour le serveur, utiliser le certificat intermédiaire comme autorité de certificat; le mot de passe de l'autorité sera demandé:

> On ne chiffre pas la clé afin que Cockpit puisse s'en servir.

```shell
step certificate create "Serveur Motel" motel.crt motel.key \
  --ca ~/.local/state/step/certs/intermediate_ca.crt \
  --ca-key ~/.local/state/step/certs/intermediate_ca.key \
  --not-after=8760h \
  --bundle \
  -san motel.internal --san serveur.internal --san server.internal \
  --template ~/.local/state/step/certs/certificate.json \
  --insecure --no-password
```

## Installation du certificat racine dans openSUSE MicroOS

Pour installer le certificat racine dans MicroOS, il faut le copier sous `/etc/pki/trust/anchors`, puis lancer `sudo update-ca-certificates`.

```shell
sudo cp SylChamber_Root_Private_Certificate_Authority.crt /etc/pki/trust/anchors/
sudo update-ca-certificates
```

Le certificat sera ensuite ajouté sous `/etc/ssl/certs/` (avec une extension `.pem`).

## Installation du certificat racine dans Firefox Linux

Firefox n'utilise pas les certificats de l'OS: il inclut ses propres certificats **dans chaque profil utilisateur**. Les [instructions de Mozilla sur l'ajout d'une autorité de certificat](https://support.mozilla.org/en-US/kb/setting-certificate-authorities-firefox) sont loin d'être limpides. Des [instructions sur AskUbuntu indiquent comment ajouter une autorité de certificat](https://askubuntu.com/questions/244582/add-certificate-authorities-system-wide-on-firefox#answer-1535553). Il s'agit d'ajouter une politique qui ajoute un module permettant d'utiliser les certificats de l'OS.

> Les paquets `p11-kit` et `p11-kit-modules` doivent être installés. Ils semblent l'être sous Ubuntu 25.04.

Il faut créer ce fichier sous `/etc/firefox/policies/policies.json`, puis relancer Firefox:

```json
{
  "policies": {
    "SecurityDevices": {
      "p11-kit-trust": "/usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so"
    }
  }
}
```

Références:

* [Add certificate authorities system-wide on Firefox - AskUbuntu](https://askubuntu.com/questions/244582/add-certificate-authorities-system-wide-on-firefox#answer-1535553)

## Configuration du certificat de Cockpit

On peut personnaliser le certificat TLS qui sera utilisé par Cockpit. On doit fournir:

* le certificat et l'autorité intermédiaire de certificat dans le même fichier `.crt` en format `PEM`;
* la clé non chiffrée dans un fichier `.key` du même nom.

Références:

* [SSL/TLS Usage - Cockpit](https://cockpit-project.org/guide/latest/https)

## Exécution d'une requête DNS-over-TLS

Pour exécuter avec `dig` une requête DoT avec un serveur DNS qui le supporte, on doit spécifier les options `+tls`, `tls-ca` et spécifier le `+tls-host`:

> L'option `+tls` semble optionnelle lorsqu'on précise `+tls-host` et `+tls-ca`. Le port `853` doit être débloqué sur le parefeu.

```shell
❯ dig +tls +tls-host=dns.google +tls-ca @8.8.8.8 qwant.com

; <<>> DiG 9.20.11-0ubuntu0.1-Ubuntu <<>> +tls +tls-host=dns.google +tls-ca @8.8.8.8 qwant.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 53151
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;qwant.com.                     IN      A

;; ANSWER SECTION:
qwant.com.              3600    IN      A       141.95.150.143
qwant.com.              3600    IN      A       54.38.0.163
qwant.com.              3600    IN      A       141.94.211.182

;; Query time: 44 msec
;; SERVER: 8.8.8.8#853(8.8.8.8) (TLS)
;; WHEN: Wed Oct 15 19:46:57 EDT 2025
;; MSG SIZE  rcvd: 86
```

ou encore, avec le serveur DNS public de CloudFlare:

```shell
dig +tls +tls-ca +tls-host=one.one.one.one @1.1.1.1 qwant.com
```

## Exécution de step-ca en conteneur pour tests

Afin de tester le fonctionnement et de l'explorer, on peut lancer `step-ca` comme conteneur:

> `dnsdomainname` retourne le domaine rapporté par le DNS; ici, `internal`, tel qu'il est configuré dans le routeur.

```shell
podman run -it --rm \
    -v step:/home/step \
    -p 9000:9000 \
    -e "DOCKER_STEPCA_INIT_NAME=SylChamber" \
    -e "DOCKER_STEPCA_INIT_DNS_NAMES=localhost,$(hostname -f),ca.$(dnsdomainname)" \
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
# TODO
```

## Références

* [ACME - Automatic Certificate Management Environment](https://en.wikipedia.org/w/index.php?title=Automatic_Certificate_Management_Environment)
* [Self-Host ACME Server](https://blog.sean-wright.com/self-host-acme-server/)
* [Run your own private CA & ACME server using step-ca](https://smallstep.com/blog/private-acme-server/) (les liens sont désuets, voir les liens ci-dessous)
* [step-ca - Github](https://github.com/smallstep/certificates)
* [step-ca Documentation](https://smallstep.com/docs/step-ca/)
  * [step-ca Installation](https://smallstep.com/docs/step-ca/installation/#kubernetes)
  * [step-ca Getting Started](https://smallstep.com/docs/step-ca/getting-started/)
* [step-certificates - ArtifactHUB](https://artifacthub.io/packages/helm/smallstep/step-certificates)
* [step-ca Docker Image - Docker Hub](https://hub.docker.com/r/smallstep/step-ca)
* [x509util - Name Object - Go Library](https://pkg.go.dev/go.step.sm/crypto/x509util#Name)
* [step - Documentation](https://smallstep.com/docs/step-cli/)
  * [Create and work with X.509 certificates](https://smallstep.com/docs/step-cli/basic-crypto-operations/#create-and-work-with-x509-certificates)
* [SSL/TLS Usage - Cockpit](https://cockpit-project.org/guide/latest/https)
* [ArgoCD and cert-manager TLS/SSL certificates Integration: In-depth guide](https://soappanda.medium.com/argocd-and-cert-manager-tls-ssl-certificates-integration-in-depth-guide-03199da8257a)
* [DNS over TLS - CloudFlare Docs](https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-tls/)
* [DNS over TLS vs. DNS over HTTPS | Secure DNS - CloudFlare](https://www.cloudflare.com/learning/dns/dns-over-tls/)
* [What is 1.1.1.1? - CloudFlare](https://www.cloudflare.com/learning/dns/what-is-1.1.1.1/)
