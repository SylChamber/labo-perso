# Cluster Kubernetes k3s

Un cluster Kubernetes k3s est déployé sur un vieux portable Dell Latitude E7250.

* Le [script d'installation a été téléchargé du site k3s.io](https://get.k3s.io)
* le script a été lancé avec les arguments suivants : `--tls-san="cloud.ici,nuage.ici" --secrets-encryption="true"`
  * le chiffrement des secrets dans `etcd` est activé
  * le certificat racine inclut les `subjectAltNames`:
    * `cloud.ici`
    * `nuage.ici`

> Explorer l'installation à l'aide d'un [fichier de configuration k3s](https://docs.k3s.io/installation/configuration#configuration-file).
