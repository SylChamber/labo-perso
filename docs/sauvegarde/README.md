# Sauvegarde

Pour assurer la pérennité des données personnelles (présentement synchronisées entre les ordinateurs via SyncThing) et des données du serveur (qui incluront éventuellement des données personnelles), les données seront sauvegardées dans l'infonuagique.

Un fournisseur non américain sera retenu, de préférence européen, pour éviter d'encourager l'hégémonie américaine, et assurer une meilleure sécurité de ces données.

L'outil `rclone` sera utilisé pour synchroniser les données tout en les chiffrant. Pour cette raison, le fournisseur doit être compatible avec `rclone`.

Les fournisseurs suivants sont envisagés:

* Proton Drive
  * c'est déjà mon fournisseur de courriel et d'agenda
  * toutefois le support Linux est manquant, et la performance ne serait pas au rendez-vous
* pCloud
  * il dispose d'une bonne réputation et offrirait d'excellentes performances
  * c'est toutefois un fournisseur suisse, et la Suisse prend un virage de surveillance étatique
  * les serveurs sont surtout aux États-Unis et au Luxembourg
  * le chiffrement côté client avec `rclone` peut toutefois pallier au risque
  * le chiffrement natif côté client est en option payante
  * le versionnage est offert
* Internxt
  * c'est un fournisseur espagnol, respectant la GDPR
  * la performance est bonne
  * c'est un service à zéro connaissance, avec chiffrement natif côté client inclus, contrairement à pCloud
  * le support `rclone` nécessite toutefois WebDav
  * aucun versionnage n'est offert

## Sauvegardes sur le réseau local

J'utilise `syncthing` pour la synchronisation des documents entre ordinateurs, et on peut donc s'en servir pour sauvegarder ces documents sur le serveur. `syncthing` a été ajouté à MicroOS.

Il faut d'abord activer ces services dans les règles parefeu `firewalld` dans Cockpit:

* `syncthing`
* `syncthing-gui`

Il suffit ensuite d'activer le service `syncthing` système pour l'utilisateur principal (ex. `sylvain`).

> Même comme service système, l'unité systemd distribuée avec le paquet `syncthing` par openSUSE doit être exécuté avec un utilisateur. Par simplicité, on choisit de le faire avec l'utilisateur principal sans privilège.

```shell
sudo system enable --now syncthing@sylvain
```

Pour accéder à l'interface web de syncthing sur le serveur, utiliser le `ssh tunneling` pour rediriger le port 8384 du serveur sur la machine locale, et ainsi faciliter la configuration à distance:

```shell
ssh -L 8385:localhost:8384 motel
```

on pourra ensuite accéder à syncthing sur le serveur avec l'URL locale `http://localhost:8385`.

Références:

* [Syncthing - Getting Started](https://docs.syncthing.net/intro/getting-started.html)
* [Syncthing - Starting Syncthing automatically](https://docs.syncthing.net/users/autostart.html#linux)
* [Syncthing - Firewall Setup](https://docs.syncthing.net/users/firewall.html#firewall-setup)
* [Accessing GUI when you have 2 machines running Syncthing on your network - r/Syncthing](https://www.reddit.com/r/Syncthing/comments/xpp3ky/accessing_gui_when_you_have_2_machines_running/)

## Références

* [Comparatif des meilleurs stockages cloud en 2025 : lequel choisir ? - 01net.com](https://www.01net.com/cloud/)
* [Test kDrive : avis sur le cloud le plus prometteur de 2025 - 01net.com](https://www.01net.com/cloud/kdrive/)
* [Les 18 meilleures alternatives à Google Drive - Leptidigital](https://www.leptidigital.fr/webmarketing/alternative-google-drive-24939/)
* [The Fastest Cloud Storage Providers (Tested & Ranked) - Gizmodo](https://gizmodo.com/best-cloud-storage/fastest)
* [pCloud Review: Secure, Fast, and Flexible Cloud Storage - Gizmodo](https://gizmodo.com/best-cloud-storage/pcloud)
* [Internxt Review: Surprisingly Good Cloud Storage! - Gizmodo](https://gizmodo.com/best-cloud-storage/internxt)
* [Icedrive vs pCloud: Which One to Use and Why?](https://gizmodo.com/best-cloud-storage/icedrive-vs-pcloud)
