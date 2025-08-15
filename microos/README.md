# Déploiement d'openSUSE MicroOS ou Leap Micro

Le déploiement des variantes MicroOS (_rolling) ou Leap Micro (stable, biannuelle) d'openSUSE, un mini Linux à système de fichier immuable pour serveur, implique:

* d'installer MicroOS à l'aide d'une clé USB d'installation
* de démarrer la première fois avec une clé « _combustion_ » qui contient un script de personnalisation de l'installation (par exemple, des instructions d'installation de logiciels, la création d'utilisateurs, etc.)

Le dossier `combustion` contient le [script de configuration](combustion/script) de MicroOS.

## Installation

Les versions MicroOS et Leap Micro sont similaires; cette dernière est basée sur SUSE Linux Micro, elle-même originant de MicroOS.

Leap Micro offre toutefois le chiffrement intégral (_full-disk encryption_) par le biais d'une image `raw`, alors que c'est plus compliqué pour MicroOS. De surcroît, une distribution _rolling_ implique un peu plus d'instabilité.

L'installation implique de télécharger l'image `raw` chiffrée «_encrypted_» de Leap Micro et d'écraser le disque du serveur avec cette image (voir les [références](#références) pour une technique d'écriture d'une clé USB ou d'un disque en ligne de commande).

1. Télécharger l'image `encrypted` de Leap Micro
2. Extraire l'image `raw` sur un disque externe ou une clé afin de pouvoir y accéder à partir du serveur cible
3. Utiliser le script [build-combustion-k3s](combustion/build-combustion-k3s) pour générer un script de combustion
4. Déposer le script `script` généré sur une clé USB étiquetée `ignition` dans un dossier `combustion`

    ```shell
    sudo mkfs.ext4 /dev/sda
    sudo e2label /dev/sda ignition
    sudo mkdir -p /mnt/ignition
    sudo mount /dev/sda /mnt/ignition
    sudo chmod 755 /mnt/ignition
    sudo mkdir /mnt/ignition/combustion
    sudo cp script *.pub /mnt/ignition/combustion    
    ```

5. Désactiver **SecureBoot** sur le serveur cible
6. Démarrer le serveur sur une clé USB démarrable «Live USB» comme Kubuntu
7. Insérer la clé ou disque contenant l'image `raw` de Leap Micro, et écraser le disque du serveur:

    ```shell
    wipefs --all /dev/sda
    dd if=/run/media/Disque/openSUSE-Leap-Micro-encrypted.raw of=/dev/sda bs=1MB --status=progress
    ```

8. Insérer la clé `combustion/ignition`, retirer la clé _Live USB_ et redémarrer le serveur
9. Choisir openSUSE Leap micro au menu GRUB

## Références

* [Get openSUSE Leap Micro](https://get.opensuse.org/leapmicro/)
* [How to write/create a Ubuntu .iso to a bootable USB device on Linux using dd command](https://www.cyberciti.biz/faq/creating-a-bootable-ubuntu-usb-stick-on-a-debian-linux/) (pour la ligne de commande pour créer une ISO démarrable)
* [SUSE Linux Micro 6.1 Documentation](https://documentation.suse.com/sle-micro/6.1/)
  * [Deploying SUSE Linux Micro Using a Raw Disk Image on Bare Metal](https://documentation.suse.com/sle-micro/6.1/html/Micro-deployment-raw-images/index.html)
* [openSUSE MicroOS Documentation](https://en.opensuse.org/Portal:MicroOS)
  * [Combustion](https://en.opensuse.org/Portal:MicroOS/Combustion)
  * [Full Disk Encryption (FDE)](https://en.opensuse.org/Portal:MicroOS/FDE)
* [SDB:K3s cluster deployment on MicroOS - openSUSE](https://en.opensuse.org/SDB:K3s_cluster_deployment_on_MicroOS)
