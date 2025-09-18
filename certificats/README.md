# Gestion des certificats

Les applications sur un réseau local auront besoin de certificats TLS pour le chiffrement des communications. Afin d'éviter de créer manuellement une autorité de certificat puis les certificats subséquents, déployer le serveur ACME et d'autorité privée de certrificat [step-ca](https://github.com/smallstep/certificates).

Comme c'est une [dépendance du cluster k3s](../k3s/README.md#gestion-des-certificats), déployer sous la forme d'un Podman Quadlet comme service systemd, comme pour [CoreDNS](../dns/README.md).

## Références

* [Self-Host ACME Server](https://blog.sean-wright.com/self-host-acme-server/)
* [Run your own private CA & ACME server using step-ca](https://smallstep.com/blog/private-acme-server/)
* [step-ca - Github](https://github.com/smallstep/certificates)
* [step-ca Documentation](https://smallstep.com/docs/step-ca/index.html)
  * [step-ca Installation](https://smallstep.com/docs/step-ca/installation/index.html)
* [step-ca Docker Image - Docker Hub](https://hub.docker.com/r/smallstep/step-ca)
