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

## Références

* [Comparatif des meilleurs stockages cloud en 2025 : lequel choisir ? - 01net.com](https://www.01net.com/cloud/)
* [Test kDrive : avis sur le cloud le plus prometteur de 2025 - 01net.com](https://www.01net.com/cloud/kdrive/)
* [Les 18 meilleures alternatives à Google Drive - Leptidigital](https://www.leptidigital.fr/webmarketing/alternative-google-drive-24939/)
* [The Fastest Cloud Storage Providers (Tested & Ranked) - Gizmodo](https://gizmodo.com/best-cloud-storage/fastest)
* [pCloud Review: Secure, Fast, and Flexible Cloud Storage - Gizmodo](https://gizmodo.com/best-cloud-storage/pcloud)
* [Internxt Review: Surprisingly Good Cloud Storage! - Gizmodo](https://gizmodo.com/best-cloud-storage/internxt)
* [Icedrive vs pCloud: Which One to Use and Why?](https://gizmodo.com/best-cloud-storage/icedrive-vs-pcloud)
