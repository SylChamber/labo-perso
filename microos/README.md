# Déploiement d'openSUSE MicroOS

Le déploiement de la variante MicroOS d'openSUSE, un mini Linux à système de fichier immuable pour serveur, implique:

* d'installer MicroOS à l'aide d'une clé USB d'installation
* de démarrer la première fois avec une clé « _combustion_ » qui contient un script de personnalisation de l'installation (par exemple, des instructions d'installation de logiciels, la création d'utilisateurs, etc.)

Le dossier `combustion` contient le [script de configuration](combustion/script) de MicroOS.

## Installation

Télécharger l'ISO de MicroOS et le graver sur une clé USB (voir les [références](#références) pour une technique de création de clé USB en ligne de commande).

<!-- TODO -->

## Références

* [How to write/create a Ubuntu .iso to a bootable USB device on Linux using dd command](https://www.cyberciti.biz/faq/creating-a-bootable-ubuntu-usb-stick-on-a-debian-linux/) (pour la ligne de commande pour créer une ISO démarrable)
* [openSUSE MicroOS Documentation](https://en.opensuse.org/Portal:MicroOS)
  * [Combustion](https://en.opensuse.org/Portal:MicroOS/Combustion)
  * [Full Disk Encryption (FDE)](https://en.opensuse.org/Portal:MicroOS/FDE)
* [SDB:K3s cluster deployment on MicroOS - openSUSE](https://en.opensuse.org/SDB:K3s_cluster_deployment_on_MicroOS)
