# Configuration et installation d'openSUSE MicroOS

Ce dossier contient les fichiers de configuration de base d'un serveur basé sur openSUSE MicroOS:

* `config-base.json`: fichier _ignition_ `config.ign` permettant de configurer l'OS; certaines valeurs doivent être personnalisées
* `script-base`: fichier _combustion_ `script` permettant de personnaliser l'installation de l'OS et installer certains logiciels
* `fetchit-setup.sh`: script de configuration de FetchIt à installer dans l'OS (référé par `script`)
* `base/*`: fichiers de base de services ayant servi à créer les fichiers de configuration ci-dessus

Voir [Déploiement d'openSUSE MicroOS ou Leap Micro](../../docs/microos/README.md) pour des instructions détaillées.
