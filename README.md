Script permettant la mise en place d'openssh et de powershell 7 sur les poste windows
cela pour plusieurs raison

1 - permettre le deploiement de logiciel automatiquement via un site web

2 - se connecter au poste via SSH avec powershell 7 avec enter-pssession -hostname PC

Les éléments à modifier :

Ligne 7 et 22 : mettre à jour l'URL par la nouvelle version au besoin

Ligne 81 : Décommenter et modifiez si vous souhaitez autoriser les accès à la machine via un groupe du domaine (par mot de passe)

Ligne 145 : permet d'ajouter une règle firewall pour le SSH, si vous êtes sur un AD, faites plutôt une GPO qui regroupe les règles firewall de vos ordinateurs, adaptez le profil suivant si le poste est sur un domaine, public ou privé

Ligne 152 : modifier le chemin 'C:\Users\Adminrenommer' par le compte admin que vous avez renommer (si t-elle est le cas), si vous n'avez pas renommé le compte, supprimer cette partie ,'C:\Users\Adminrenommer'

Ligne 169 : Remplacer cela (ssh-rsa ACLEPUB) par le contenu de votre fichier id_rsa.pub (clé publique générée plus haut)
