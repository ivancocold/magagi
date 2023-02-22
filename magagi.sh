#!/bin/bash

#Pour débuguer le bash, merci d'activer la ligne ci-après.
    #set -x


#Exercice : Avec une ou plusieurs options.

#Introduction


#Pour répondre à la partie aller plus loin, j'utilise les commandes baobab et/ou ncdu.
#Il faut penser à télécharger/installer les dépendances baobab et ncdu (si ce n'est déjà fait) en exécutant la/les commande(s) ci-après dans le terminal:
    #- "sudo apt-get install ncdu"
    #- "sudo apt-get install baobab"

#Plus bas, dans le corps du script, une section vérifie si ncdu ou baobab sont nécessaires, puis s'ils sont installés. Elle se charge de les installer en cas de besoin.


#Avant d'éxecuter le présent fichier bash, il faut modifier ses droits (droits d'exécution).
#Pour ce faire, il faut exécuter la commande suivante dans la console:
	#-"chmod +x /chemin/vers/le/bash/magagi.sh"


#Il faut ensuite exécuter le fichier dans la console.
#Exemple:
    #"/chemin/vers/le/bash/magagi.sh"


#Pour transformer le script magagi.sh en une commande "magagi" exécutable dans la console, il faut (par exemple):
#Créer un lien symbolique (alias) vers le présent script dans le fichier de configuration bash (.bashrc ou .bash_aliases).
#On utilise la commande "alias magagi='/chemin/vers/magagi.sh'" (à enregistrer dans le config).
#Pour tenir compte des changements de le fichier de config, on éxecute la commande "source ~/.bashrc" dans la console.



#Phase de développement (code)


#Initialisation des variables


#Par défaut (sans options), le répertoire cible est le répertoire courant de l'environnement d'exécution.
dos=`pwd`


#L'exercice demande à chaque fois de retourner les sous-dossiers directs.
#Ainsi, la commande utilisée est du, avec une profondeur de 1.
commande='du -d 1 '


#Initialisation de la variable qui stockera l'expression régulière (regex)
reg=


#Initialisation des variables qui me permettront de tenir compte des options g (barre de progression) et i (mode graphique et interactif)
g=
i=


#Création de la fonction d'affichage d'aide

function aide
{
	echo -e "La fonction \"magagi\" ou le script \"./magagi.sh\" vous permet de visualiser le contenu et l'espace de stockage d'un dossier avec une profondeur 1 (affichage non recursif)."
    echo -e "Par défaut, elle/il cible le répertoire courant de l'environnement d'exécution."
	echo "Elle/il utilise les options suivantes: "
	echo "	-a: affiche les fichiers et dossiers cachés."
	echo "	-d: prend en argument un dossier cible."
	echo "	-e: prend en argument les dossiers/fichiers du dossier cible qu'il faut exclure du résultat."
    echo "	    Il faut mettre autant d'options e qu'on a d'arguments."
    echo -e "\tExemple : bash magagi.sh -e tata -e titi.sh -e para.tar"
    echo "	-f: affiche les fichiers en plus des sous-dossiers."
	echo "	-g: affiche visuellement l'espace occupé."
	echo "	-h: affiche les tailles des sous-dossiers."
	echo "	-i: affiche un mode graphique et interactif."
    echo "	-q: affiche l'aide."
	echo "	-r: prend en argument l'expression régulière cible dans le répertoire de recherche."
	echo "	-s: trie les résultats obtenus par ordre décroissant d'espace disque utilisé."
    echo -e "\t-t: Affiche la capacité totale du répertoire cible."
	echo "	-v: active le mode verbeux."
    echo "	-y: trie les résultats obtenus par ordre croissant d'espace disque utilisé."
	exit 0
} 


#Pour exploiter les arguments et les options, j'utilise l'utilitaire de ligne de commande getopts.
#Les options suivis par ":" (ici -d et -r) doivent avoir un argument.


#Une boucle while peut parcourir tous les options et arguments possibles.

#Je souhait d'abord traiter les cas

while getopts "afe:ghiqsvtr:d:y" option;
do
	#Je traite chaque cas séparément.
	#Les différents options et arguments modifient la commande par défaut au fur et à mesure.
    #";;" marquent la fin du traitement d'une option.

	case $option in

		a) #Option d'affichage des fichiers et dossiers cachés
        #Cette option sera gérée plus bas pour pouvoir la gérer en même temps que l'option f.
        #Création d'une variable afin de mémoriser que l'option "a" a été saisie.
        a=1
		;;



		d) #Gestion du répertoire cible
		#Si l'option d a été saisie, elle est suivie d'un argument
        #Je le récupère le dossier cible en écrasant la variable dos.

        dos=$OPTARG
        
        #Je teste la validité du dossier cible.
        if [ ! -d $dos ]; then
            echo -e "Désolé, $dos, votre répertoire cible, n'est pas valide.\n"
            #Je sors du script si le dossier cible est invalide.
            exit 1
        fi

        #Je complète la commande.
            commande=$commande"$dos "
        ;;


        
        e) #Gestion des fichiers/dossiers à exclure du résultat.

        #Récupération de l'argument.
        exc=${OPTARG}

        #Je teste la validité du dossier/fichier à exclure.
        #Je me sers de la variable test pour faire les différents test

        #Premier cas:l'utilisateur a saisi un chemin (relatif ou absolu).
        #Je vérifie la présence de "/" dans la chaîne de caractère saisi.
        if echo $exc | grep -q -E '/'; then
            echo -e "Pour le fichier/dossier à exclure, merci de saisir un nom (et non pas un chemin).\n Le fichier/dossier à exclure n'est pas pris en compte pour cette fois.\n" 

        #Deuxième cas :l'utilisateur a saisi un nom de dossier/fichier.
        #Je reconstruis l'arborescence absolue.

        #Cas où le dossier cible a été saisi avec un "/" à la fin.
        elif [ "${dos: -1}" = "/" ]; then
            #Je reconstruis l'arborescence.
            #Ajout du dosssier/fichier à exclure à la cible sans ajouter de "/"
            test="$dos$exc"

            #Je teste la validité du fichier/dossier à exclure.
            if [ ! -d $test ]|[ ! -e $test ]; then
                echo -e "Le fichier/dossier $test à exclure n'existe pas dans le dossier cible.\n"
            else
                echo -e "\nVous avez choisi d'exclure le fichier/dossier : $exc\n"
                commande=$commande"--exclude $test "
            fi

        #Cas ou le dossier cible n'a pas été saisi avec un "/" à la fin.
        else
            #Je reconstruis l'arborescence.
            #Ajout du dosssier/fichier à exclure à la cible en ajouteant un "/"

            test="$dos/$exc"

            #Je teste la validité du fichier/dossier à exclure.
            if [ ! -d $test ]|[ ! -e $test ]; then
                echo -e "Le fichier/dossier $test à exclure n'existe pas dans le dossier cible.\n"
            else
                echo -e "\nVous avez choisi d'exclure le fichier/dossier : $exc\n"
                commande=$commande"--exclude $exc "
            fi
        fi
        ;;
        #La précédente manipulation ne permet pas d'exclure les fichiers cachés.
        #Exclure les fichiers cachés est possible en chaînant la commande du -a avec grep -v "fichier_à_exclure"


		f) #Affichage des fichiers (en plus des sous-dossiers).
        #Cette option sera gérée plus bas pour pouvoir la gérer en même temps que l'option a.
        #Création d'une variable afin de mémoriser que l'option "f" a été saisie.
        f=1
		;;

		
		g) #Affichage de la taille dans un barre de progression.
        g=1
		#La gestion de cette option sera faite plus bas.
        ;;

		
		h) #Affichage de la taille de manière lisible par un être humain.
        commande=$commande"-h "
		;;


        i) #Mode graphique et interactif 
        i=1
        #La gestion de cette option sera faite plus bas.
        ;;
        

		q) #Cette option affiche l'aide.
        aide
        ;;
		
		
		r)  #Gestion de la regex dans le répertoire cible.
        #Je récupère la regex dans une variable qui sera utilisée plus bas.
        reg=${OPTARG}
        ;;

        
		s) #Affichage d'un résultat trié par ordre décroissant.
        s=1
        #La gestion sera faite plus bas.
		;;
		

        t) #Affichage explicite du volume total du répertoire cible.
        commande=$commande"-c "
        ;;


		v)  #Activation du mode verbeux.
        verbose= true
        shift
        ;;		


		
		y) #Affichage d'un résultat trié par ordre croissant.
          y=1
		;;
		

        #Pour toute autre option, je signale sa non validité et sors du programme.
		\?) 	echo "Option non valide. Arrêt du programme." >&2
			aide
			exit 1;;
	esac
done




#Je vérifie les droits d'exécution sur le dossier cible est accessible.
if [ ! -x $dos ]; then
    echo -e "Désolé, le dossier cible n'est pas acccessible.\n"
    #Arrêt du script.
    exit 1
fi


#Tester les droits de lecture sur le dossier cible (le projet ne requiert pas de droits d'écriture)
if [ ! -r $dos ]; then
    echo -e "Désolé, mais vous n'avez pas les droits de lecture sur le dossier cible.\n"
    #Arrêt du script en cas de défaut de droits de lecture.
    exit 1
fi



#Gestion des options a (affichage des dossiers/fichiers cachés) et f (affichages des fichiers)

#Si "a" été saisie, j'afficherai fichiers et dossiers (mêmes cachés).
if [ "$a" == 1 ]; then
    commande=$commande"-a "

#Si "f" uniquement a été saisie, j'afficherai les fichiers du dossier cibles sans les éléments cachés.
elif [ "$f" == 1 ]; then
    commande=$commande"-a --exclude=\"*/.*\" "
fi


#Je complète ma commande avec les option pas encore traitées.

#Gestion de l'expression régulière
#Si l'expression régulière est renseignée, je chaîne une commande grep.
if test -n "$reg"; then
    echo -e "\nL'expression régulière choisie est \"$reg\"\n"
    commande=$commande"| grep $reg"
#S'il n'y a pas de regex renseignée, je le signale.
else
    echo -e "Vous n'avez pas renseigné d'expression régulière.\n"
fi

#Gestion du tri
#Si un tri est demande, je chaîne avec la commande de tri.

if [ "$s" == 1 ] && [ "$y" == 1 ]; then
    echo -e "Il est impossible de trier par ordre croissant et décroissant à la fois.\n"
    echo -e "Je trie donc par ordre décroissant par défaut.\n"
    commande=$commande" | sort -hr"
elif [ "$s" == 1 ]; then
 	commande=$commande" | sort -hr"

elif [ "$y" == 1 ]; then
 	commande=$commande" | sort -h"

#-n trie par ordre croissant, -hr trie par ordre décroissant.
fi


#Je mets des noms de colonnes au résultat de ma commande principale.
#commande=$commande" | awk '{echo -e \"Taille\tFichier\", $0}'"


#Traitement des options i et g.
#Si l'option g a été choisie, on utilisera la commande baobab.
#Si l'option i a été choisie, on utilisera la commande ncdu.
#Chaîner les commandes baobab et ncdu n'a pas de sens : leurs objectifs ne sont pas complémentaires.
#Ainsi l'une et l'autre option génère des commandes distinctes.
#Enfin, baobab et ncdu s'applique au dosssier cible sans considérer les différentes autres options.

#Je teste si l'option g a été renseignée.
#Si elle est renseignée, je prépare une commande ncdu
if test -n "$g"; then

#Cette section vérifie si ncdu est installé et l'installe.
    if ! command -v ncdu &> /dev/null ; then
        echo -e "ncdu n'est pas installé.\n'"
        echo -e "Nous allons procéder à l'installation de ses dépences.\n"
        eval 'sudo apt-get install ncdu'
    fi

    cg="ncdu -r $dos"
    #Les droits que j'ai testé sur le dossier cible sont les seuls droits de lecture.
        #Je rajoute donc l'option r à la commande ncdu pour me limiter aux droits de lecture. 
fi

#Tester si l'option i a été renseignée.
if test -n "$i"; then
    #Cette section vérifie si baobab est installé et l'installe.    
    if ! command -v baobab &> /dev/null ; then
        echo -e "baobab n'est pas installé.\n'"
        echo -e "Nous allons procéder à l'installation de ses dépences.\n"
        eval 'sudo apt-get install baobab'
    fi
    #Préparartion de la commande baobab.
    ci="baobab $dos"
fi


#Les options i et g rajoutent chacune une sortie suppplémentaire.
#Cela est dû à l'impssibilité de chaîner ces commandes avec la commande principale du.
#3 cas sont donc possibles:
#1) i et g ne sont pas renseignés, une seule commande (chainée) est exécutée.
#2) i ou g est renseigné, deux commandes sont exécutées.
#3) i et g sont rensignés en même temps, 3 commades sont exécutées.

#Cas 3
if test -n "$i" && test -n "$g"; then
    #J'affiche les 3 commandes finales.
    echo "3 commandes sont éxécutées. Il s'agit de:"
    echo "-commande 1 : $commande"
    echo "-commande 2 : $cg"
    echo -e "-commande 3 : $ci\n"

    #J'affiche le répertoire cible.
    echo -e "Le répertoire cible est $dos\n"

    #J'annonce le résultat.
    echo "Son contenu est: "

    #J'exécute les 3 commandes finales.
    echo -e "\nTaille\tFichier/Dossier\n"
    eval $commande
    eval $ci
    eval $cg

#Cas 2 avec i
elif test -n "$i"; then
    #J'affiche les 2 commandes finales.
    echo -e "\n Deux commandes sont éxécutées. Il s'agit de:"
    echo "-commande 1 : $commande"
    echo -e "-commande 2 : $ci\n"

    #J'affiche la commande le répertoire cible.
    echo -e "Le répertoire cible est $dos\n"

    #J'annonce le résultat.
    echo "Son contenu est: "

    #J'exécute les deux commandes finales.
    echo -e "\nTaille\tFichier/Dossier\n"
    eval $commande
    eval $ci

#Cas 2 avec g
elif test -n "$g"; then
    #J'affiche les 2 commandes finales.
    echo -e "\n Deux commandes sont éxécutées. Il s'agit de:"
    echo "-commande 1 : $commande"
    echo -e "-commande 2 : $cg \n"

    #J'affiche la commande le répertoire cible.
    echo -e "Le répertoire cible est $dos\n"

    #J'annonce le résultat.
    echo "Son contenu est: "

    #J'exécute les deux commandes finales.
    echo -e "\nTaille\tFichier/Dossier\n"
    eval $commande
    eval $cg

#Cas 1
else
    #J'affiche la commande finale.
    echo -e "\nUne commande est éxécutée. Il s'agit de:"
    echo -e "$commande\n"

    #J'affiche la commande le répertoire cible.
    echo -e "Le répertoire cible est $dos\n"

    #J'annonce le résultat.
    echo "Son contenu est: "

    #J'exécute les deux commandes finales.
    echo -e "\nTaille\tFichier/Dossier\n"
    eval $commande
fi

#Fin du script.
