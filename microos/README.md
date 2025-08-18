# Déploiement d'openSUSE MicroOS ou Leap Micro

Le déploiement des variantes MicroOS (_rolling) ou Leap Micro (stable, biannuelle) d'openSUSE, un mini Linux à système de fichier immuable pour serveur, implique:

* d'installer MicroOS à l'aide d'une clé USB d'installation
* de préparer une configuration « ignition/combustion » sur une clé USB avec
  * un fichier JSON de configuration `config.ign` avec:
    * des paquets à installer
    * des utilisateurs à créer
    * des services à créer ou activer
  * un script de personnalisation de l'installation, autrement dit des instructions supplémentaires

## Installation

Les versions MicroOS et Leap Micro sont similaires; cette dernière est basée sur SUSE Linux Micro, elle-même originant de MicroOS.

Voici les étapes pour l'installation d'une version `SelfInstall` (voir les [références](#références) pour une technique d'écriture d'une clé USB ou d'un disque en ligne de commande).

> L'image ISO ne permet pas de configurer l'installation avec combustion et ignition. Pour cela, on doit choisir une image `SelfInstall` ou `.raw`.
>
> De multiples tentatives d'installation d'images `.raw` ont été faites avec Leap Micro, pour la version `encrypted` pour le disque chiffré LUKS avec déverrouillage via TPM; le système était dysfonctionnel avec de multiples erreurs BTRFS.
>
> Une tentative a été faite avec l'ISO de MicroOS pour installer avec chiffrement intégral et déverrouillage via TPM. Ce dernier n'a pas fonctionné. Et il n'y avait pas possibilité d'installer des paquets supplémentaires à même l'installation.

1. Désactiver **SecureBoot** sur le serveur cible
2. Télécharger l'image `SelfInstall` de MicroOS et la graver sur une clé USB
3. Utiliser le site [Fuel Ignition](https://opensuse.github.io/fuel-ignition/) pour générer les fichiers ignition et combustion pour l'installation
   * le script [build-combustion-k3s](combustion/build-combustion-k3s) contient un bogue
4. Déposer le script combustion `script` et le fichier ignition `config.ign` sur une clé USB étiquetée `ignition` dans un dossier `combustion` et un dossier `ignition`, respectivement; on peut aussi télécharger une `.img` à partir de **Fuel Ignition** et la graver sur la clé:

    ```shell
    # en une seule étape avec un fichier `.img`
    sudo dd if=ignition-[nom-du-fichier].img of=/dev/sda status=progress
    # étapes manuelles
    sudo mkfs.ext4 /dev/sda
    sudo e2label /dev/sda ignition
    sudo mkdir -p /mnt/ignition
    sudo mount /dev/sda /mnt/ignition
    sudo chmod 755 /mnt/ignition
    sudo mkdir /mnt/ignition/combustion /mnt/ignition/ignition
    sudo cp script /mnt/ignition/combustion && sudo chmod 755 /mnt/ignition/combustion/script
    sudo cp config.ign /mnt/ignition/ignition && sudo chmod 644 /mnt/ignition/ignition/config.ign
    ```

5. Démarrer le serveur sur la clé USB MicroOS et la clé USB `ignition/combustion`
6. L'installation et la configuration se feront sans intervention et le serveur sera disponible, mais SELinux sera désactivé
7. S'authentifier avec `root` et redémarrer avec `reboot now` (ou `ctrl+alt+del`) pour que SELinux soit activé
8. Lancer l'installation de `k3s` avec `systemctl enable --now k3s-install`
9. Après l'installation réussie de `k3s`, lancer avec `systemctl enable --now k3s`

Voir la section suivante sur la configuration pour les détails de configuration.

## Configuration

Si on utilise Fuel Ignition pour générer la configuration, voici les informations à saisir:

### Paquets additionnels

> L'installation des man pages ne fonctionne pas. Les dossiers sous `/usr/share/man` sont vides. Doit-on générer les man pages pendant la configuration?

```text
# paquets additionnels
bash-completion btop htop glibc-locale kubecolor man man-pages man-pages-fr patterns-microos-cockpit starship syncthing vim-small zsh zsh-htmldoc
```

### Personnalisation du script combustion

```shell
# install additional packages for localization
zypper --non-interactive addlocale fr_CA

# download k3s installer
curl -L --output k3s_installer.sh https://get.k3s.io && install -m755 k3s_installer.sh /usr/bin/
```

### Services

#### Installation de k3s

L'installation de k3s se fait après l'installation et la configuration, via un service. On ne doit pas activer l'installation tout de suite, car le serveur lance les services tout de suite après la configuration, mais SELinux n'est pas encore activé. Le script d'installation de k3s détecte un système SELinux, et tente de configurer le contexte de l'exécutable `k3s`, sans succès.

Il faut lancer l'installation après avoir redémarré:

```shell
systemctl enable --now k3s-install
```

et une fois installé avec succès, on peut activer et démarrer le service `k3s`:

```shell
systemctl enable --now k3s
```

* nom: `k3s-install.service`
* enabled: `no`
* content:

  ```text
  [Unit]
  Description=Run k3s installer
  Wants=network-online.target
  After=network.target network-online.target
  ConditionPathExists=/usr/bin/k3s_installer.sh
  ConditionPathExists=!/usr/local/bin/k3s
  [Service]
  Type=forking
  TimeoutStartSec=120
  Environment="INSTALL_K3S_EXEC=server --cluster-init --write-kubeconfig-mode=644 --secrets-encryption=true --kube-apiserver-arg enable-admission-plugins=ExtendedResourceToleration --tls-san k3s.rloc,kubernetes.rloc,motel.rloc"
  ExecStart=/usr/bin/k3s_installer.sh
  RemainAfterExit=yes
  KillMode=process
  [Install]
  WantedBy=multi-user.target
  ```

#### Cockpit

Cockpit n'est pas installé par défaut dans la version `SelfInstall`. Il faut l'inclure dans les paquets additionnels avec `patterns-microos-cockpit`.

* nom: `cockpit.socket`
* enabled: `yes`

#### SSHd

* nom: `sshd.service`
* enabled: `yes`

## Références

* [Get openSUSE MicroOS](https://get.opensuse.org/microos/)
* [Get openSUSE Leap Micro](https://get.opensuse.org/leapmicro/)
* [Fuel Ignition](https://opensuse.github.io/fuel-ignition/)
* [How to write/create a Ubuntu .iso to a bootable USB device on Linux using dd command](https://www.cyberciti.biz/faq/creating-a-bootable-ubuntu-usb-stick-on-a-debian-linux/) (pour la ligne de commande pour créer une ISO démarrable)
* [YaST2 support for Full Disk Encryption with TPM2 - MicroOS Blog](https://microos.opensuse.org/blog/2025-08-11-fde-tpm2-yast2/) (YaST2 est le logiciel d'installation du Live USB MicroOS)
* [SUSE Linux Micro 6.1 Documentation](https://documentation.suse.com/sle-micro/6.1/)
  * [Deploying SUSE Linux Micro Using a Raw Disk Image on Bare Metal](https://documentation.suse.com/sle-micro/6.1/html/Micro-deployment-raw-images/index.html)
* [SUSE Linux Micro 5.5 Documentation](https://documentation.suse.com/sle-micro/5.5/)
  * [Deployment Guide](https://documentation.suse.com/sle-micro/5.5/html/SLE-Micro-all/book-deployment-slemicro.html)
* [openSUSE MicroOS Documentation](https://en.opensuse.org/Portal:MicroOS)
  * [Combustion](https://en.opensuse.org/Portal:MicroOS/Combustion)
  * [Full Disk Encryption (FDE)](https://en.opensuse.org/Portal:MicroOS/FDE)
* [SDB:K3s cluster deployment on MicroOS - openSUSE](https://en.opensuse.org/SDB:K3s_cluster_deployment_on_MicroOS)
