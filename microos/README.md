# Déploiement d'openSUSE MicroOS ou Leap Micro

Le déploiement des variantes MicroOS (_rolling) ou Leap Micro (stable, biannuelle) d'openSUSE, un mini Linux à système de fichier immuable pour serveur, implique:

* d'installer MicroOS à l'aide d'une clé USB d'installation
* de préparer une configuration « ignition/combustion » sur une clé USB avec
  * un fichier JSON de configuration `config.ign` avec:
    * des paquets à installer
    * des utilisateurs à créer
    * des services à créer ou activer
  * un script de personnalisation de l'installation, autrement dit des instructions supplémentaires

## Installation SelfInstall

> Le serveur résultant ne sera pas protégé par le chiffrement intégral du disque. Je n'ai pas réussi à faire fonctionner le déverrouillage avec TPM2, ni avec FIDO2 sans vérification utilisateur.
>
> Avec `transactional-update`, MicroOS a l'avantage d'un système immutable qui peut très bien être modifié sans impact sur les mises à jour, puisque chaque transaction prépare un nouveau snapshot, qui sera lui-même remplacé à la prochaine mise à jour.

Les versions MicroOS et Leap Micro sont similaires; cette dernière est basée sur SUSE Linux Micro, elle-même originant de MicroOS.

Voici les étapes pour l'installation d'une version `SelfInstall` (voir les [références](#références) pour une technique d'écriture d'une clé USB ou d'un disque en ligne de commande).

> L'image ISO ne permet pas de configurer l'installation avec combustion et ignition. Pour cela, on doit choisir une image `SelfInstall` ou `.raw`.
>
> De multiples tentatives d'installation d'images `.raw` ont été faites avec Leap Micro, pour la version `encrypted` pour le disque chiffré LUKS avec déverrouillage via TPM; le système était dysfonctionnel avec de multiples erreurs BTRFS.
>
> Une tentative a été faite avec l'ISO de MicroOS pour installer avec chiffrement intégral et déverrouillage via TPM. Ce dernier n'a pas fonctionné. Une solution a toutefois été trouvée, voir la section précédente.

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

> L'installation des man pages ne fonctionne pas car la configuration `/etc/zypper/zypp.conf` spécifie de ne pas les installer. De surcroît, `btop` plante.

```text
# paquets additionnels
bash-completion cockpit-firewalld cockpit-selinux distrobox htop glibc-locale kubecolor patterns-microos-cockpit starship syncthing vim-small zsh zsh-htmldoc
```

### Personnalisation du script combustion

```shell
# install additional packages for localization
zypper --non-interactive addlocale fr_CA

# install tailscale
rpm --import https://pkgs.tailscale.com/stable/opensuse/tumbleweed/repo.gpg
zypper --non-interactive addrepo --gpgcheck --repo https://pkgs.tailscale.com/stable/opensuse/tumbleweed/tailscale.repo
zypper --non-interactive refresh
zypper --non-interactive install tailscale

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

## Installation avec logiciel d'installation (ISO)

> J'ai réussi à faire fonctionner le chiffrement intégral (FDE) avec déverrouillage via TPM2, mais en tentant une réinstallation, impossible de faire fonctionner le déchiffrement avec TPM2. Je ne suis pas arrivé à retrouver la combinaison de commandes qui l'ont fait fonctionner la première fois. Ça plante toujours sur une erreur disant que le device TPM2 est introuvable, et demande le mot de passe LUKS.

* saisir mot de passe du chiffrement intégral
* prendre en note le texte à insérer dans la ligne de commande de démarrage: measure-pcr-validatr.ignore=yes
* allumer le serveur
* saisir mot de passe du chiffrement intégral
* s'authentifier comme root
* selon [Quickstart in Full Disk Encryption with TPM and YaST2](https://microos.opensuse.org/blog/2024-09-03-quickstart-fde-yast2/), lancer
  * sdbootutil enroll --method=tpm2
* mettre à jour les mesures de prédictions
  * sdbootutil --ask-pin update-predictions
* redémarrer
* insuffisant, mot de passe est demandé

### Notes

Tentative infructueuse supplémentaire, qui repose sur `dracut`, qui ne peut fonctionner car ça requiert les droits en modification sur `/boot`. Ce qui n'est pas le cas pour `root`.

* le déverrouillage avec TPM2 ne fonctionne pas. Désinscrire
  * `sdbootutil unenroll --method tpm2`
* créer un utilisateur

    ```shell
    useradd -m sylvain
    mkdir ~sylvain/.ssh && chown sylvain:sylvain ~sylvain/.ssh && chmod 700 ~sylvain/.ssh
    cp ~/.ssh/authorized_keys ~sylvain/.ssh && chown sylvain:sylvain ~sylvain/.ssh/authorized_keys
    passwd sylvain
    ```

* création de `/etc/dracut.conf.d/50-tpm2.conf`

    ```shell
    # Déverrouillage avec TPM2
    # https://askubuntu.com/questions/1470391/luks-tpm2-auto-unlock-at-boot-systemd-cryptenroll
    hostonly="yes"
    add_dracutmodules+=" tpm2-tss "
    ```

* script `/usr/local/bin/tpm2-luks-enroll`, à lancer

    ```shell
    #!/usr/bin/env bash
    # Enrôler ou ré-enrôler le déverrouillage LUKS avec TPM2

    # obtenir les UUID des partitions dans un array, à partir de crypttab
    DEVICES=($(cat /etc/crypttab | grep -v '#' | awk '{print $2}' | sed -r 's/UUID=(.*)/\1/'))

    # enrôler chaque partition
    for DEVICE in ${DEVICES[@]}; do
      sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/disk/by-uuid/$DEVICE
      sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs="7+14:sha256" "$@" /dev/disk/by-uuid/$DEVICE
    done
    ```

* vérifier l'état du déverrouillage TPM2

    ```shell
    > sudo systemd-cryptenroll /dev/sda2
    SLOT TYPE    
      0 password
      1 tpm2
    > sudo systemd-cryptenroll /dev/sda3
    SLOT TYPE    
      0 password
      1 tpm2
    ```

* modifier `/etc/crypttab` pour ajouter `luks,tpm2-device=auto,no-read-workqueue,no-write-workqueue` à chaque partition LUKS
* lancer `dracut -f`

Références

* [LUKS + TPM2 + auto unlock at boot (systemd-cryptenroll) - AskUbuntu](https://askubuntu.com/questions/1470391/luks-tpm2-auto-unlock-at-boot-systemd-cryptenroll)
* [systemd-cryptenroll (1)](https://www.man7.org/linux/man-pages/man1/systemd-cryptenroll.1.html)

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
