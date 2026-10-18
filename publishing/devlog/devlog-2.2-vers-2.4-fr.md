# Pile Down 2.4 : plus de choix, un nouveau rythme

Depuis le précédent devlog, Pile Down a surtout évolué dans la façon de jouer : poser une tuile sans la faire glisser, rattraper une carte juste avant sa disparition, préparer une partie sur mesure ou prendre une pause entre deux manches.

Ce billet rassemble les changements **depuis la 2.2, jusqu’à la 2.4**. La mémoire reste au cœur du jeu, avec des tirages retravaillés et plusieurs corrections pour rendre les gestes plus fiables, notamment sur téléphone.

## Poser au clic ou au toucher

Vous pouvez maintenant **sélectionner une tuile, puis cliquer ou toucher la pile visée** pour la poser. Un contour jaune indique la sélection. Un clic dans le vide l’annule, et vous pouvez toujours passer au glisser-déposer.

Les options d’accessibilité permettent d’activer séparément **Poser au clic** et **Glisser-déposer**. Les deux sont actifs par défaut : à vous de choisir le geste qui vous convient.

Les règles spéciales suivent aussi ce mode de jeu. **Livraison à l’aveugle** masque la tuile sélectionnée, et **Patates chaudes** limite le temps pendant lequel vous pouvez la garder en sélection. Les cartes emportées par **Invite un ami** sont également signalées avant la pose.

## Une dernière chance avant la défausse

Après un coup réussi, les autres tuiles de la main restent jouables pendant leur courte animation de sortie. Si vous voyez une seconde solution, vous pouvez **attraper une tuile avant qu’elle disparaisse** et la poser à son tour.

La saisir arrête sa sortie, au clic comme en glissement. Un coup supplémentaire valide renouvelle la main et relance le chrono ; les tuiles qui quittent cette nouvelle main peuvent elles aussi être rattrapées. Il devient donc possible d’enchaîner plusieurs coups rapides.

Cette mécanique est encore expérimentale. Une mauvaise valeur coûte toujours une vie. Elle concerne la défausse après un coup valide ; les rechargements manuels, fins de manche et fins de partie conservent leur déroulement habituel.

Après une erreur non fatale, vous pouvez aussi reprendre une autre tuile pendant les animations de retour et de dégâts, pour repartir plus vite.

## Des tirages qui entretiennent les écarts

Le tirage des mains a été retravaillé pour limiter deux habitudes qui simplifiaient beaucoup la mémorisation : descendre toujours la même pile, ou maintenir toutes les piles à la même valeur.

Les nouvelles préférences cherchent un **écart modéré entre les piles**. Quand le plateau est presque aligné, elles favorisent un peu de séparation. Quand une pile prend beaucoup d’avance, elles favorisent le rattrapage des autres. Elles influencent les chances de tirage sans imposer un chemin unique.

La main garde au moins une carte jouable dans les modes qui le garantissent. **Main chanceuse** et les jokers conservent leurs avantages ; **Rechargement requis** garde son tirage particulier. La préférence liée aux écarts reste désactivée sur les manches aux petites valeurs.

La montée en difficulté a aussi été ajustée : plus un attribut approche de sa limite, moins il pèse dans le prochain tirage. Et une victoire rend désormais **une vie**, jusqu’au maximum disponible, au lieu de restaurer toutes les vies. Une nouvelle partie commence toujours avec toutes ses vies.

## Choisir son rythme

Deux nouvelles options permettent d’adapter le jeu :

- **Pause entre les rounds**, dans les options de jeu, garde l’annonce de difficulté à l’écran jusqu’à un clic, un toucher ou une touche du clavier. Le chrono de la manche suivante attend votre geste.
- **Fond fixe**, dans les options graphiques, arrête le défilement des motifs. Les transitions et les déformations restent actives.

Ces options sont désactivées par défaut et votre choix est sauvegardé.

## Préparer une partie avec une seed

La page Seeds permet maintenant de régler le **nombre de piles, la taille de la main, la valeur initiale et le temps par tour**, dans les limites déjà atteintes dans votre progression.

En mode normal, vous pouvez aussi choisir une manche de départ jusqu’à la plus haute déjà atteinte. Chaque réglage de difficulté propose **AUTO** : le jeu reconstruit alors la difficulté correspondant au départ choisi. Vous pouvez ne fixer qu’un attribut et laisser les autres en automatique.

Relancer la même seed conserve la configuration. De quoi travailler une situation précise ou partager le même point de départ avec quelqu’un.

## Des défis et des succès mieux cadrés

**Défilé de boss** commence désormais avec une règle dès la première manche, puis en ajoute une tous les trois rounds, jusqu’à cinq et sous réserve des incompatibilités. Cette progression s’applique aussi en mode infini.

Le **Tapis roulant** a reçu une nouvelle sortie : les tuiles arrivent depuis la droite, tournent à gauche et quittent l’écran par le bas. Le flux continue pendant que vous prenez une carte.

Dans **Chrono partagé**, le décompte est suspendu pendant le retour d’erreur, et un rechargement ajoute trois secondes. **Rechargement requis** préserve le temps restant pendant le remplacement de la main et accorde un petit supplément lorsqu’il reste moins d’une seconde.

Les succès respectent désormais les modes dans lesquels leur objectif doit être accompli. Les objectifs de progression et de vitesse restent liés aux parties normales ou infinies sans seed ; certains exploits de placement, de combos et de règles restent accessibles en défi ou depuis une étape. Les succès et la progression des anciennes sauvegardes sont conservés.

## Plus de confort sur mobile

Avec **Doigts collants**, un contour vert montre maintenant la tuile engagée. Sur écran tactile, une tuile lâchée hors d’une pile reste sur place et peut être reprise. Une erreur de pose libère la sélection pour vous laisser choisir une autre carte.

Les menus et le plateau tiennent compte des encoches et des barres système. Sur Android, vous pouvez afficher ou masquer ces barres depuis les options graphiques. Les listes défilantes, les sélections et plusieurs textes français ont également été ajustés.

Un nouvel écran de chargement animé accueille enfin le lancement du jeu, avec une pile de tuiles dont les valeurs suivent votre progression.

Merci pour vos retours ! Je suis particulièrement curieux de savoir comment vous jouez avec cette version : plutôt glisser-déposer ou pose au toucher ? Et est-ce que les nouvelles mains vous poussent à changer de pile plus souvent ?
