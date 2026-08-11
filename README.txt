CoA Analytics 2.15.3
===================

CoA Analytics analyse les specialisations et les roles sur le serveur CoA.
L'addon reunit les nameplates de BG, le scoreboard enrichi, le classement BG
historique et les nouveaux classements PvE pour les donjons et les raids.

Architecture 2.7
----------------

- Noyau, classement BG, nameplates, suivi PvE, interfaces PvE, widget de
  donjon, interface principale et scoreboard sont charges comme des modules
  distincts.
- Chaque fichier reste largement sous la limite de 200 variables locales du
  client Lua 5.1 afin de permettre l'ajout de nouvelles fonctionnalites.
- Une API et un bus d'evenements internes limitent les dependances directes.
- La table persistante reste strictement CoAAnalyticsDB : aucune donnee ni
  version de schema n'est reinitialisee par ce changement d'architecture.
- La recherche utilise OnTabPressed, compatible Ascension 3.3.5, et tous les
  panneaux sont masques pendant leur construction pour eviter les overlaps.

Classement BG
-------------

- Les donnees et le classement de CoA BG Intelligence sont conserves.
- Deux vues : specialisations anonymes et joueurs individuels.
- Deux categories : Degats et Soins.
- Les specialisations proches du meilleur resultat se partagent les points.
- Un coefficient collectif reduit l'influence des BG desequilibres.
- Le score est normalise par le nombre de participations ponderees : une
  specialisation souvent presente devient plus fiable, pas artificiellement
  plus forte.
- Cinq BG virtuels a la moyenne stabilisent les petits echantillons.
- Les anciens Top 1, les echantillons et le poids des BG sont preserves.
- Dans les BG de capture de drapeau a trois points, un compte a rebours sans
  libelle est place sous les objectifs et actualise une fois par seconde.
- Le timer reconnait les variantes CoA par leur objectif /3, fonctionne avec
  les frames Blizzard et ElvUI, et reste masque sans limite fiable.

Classement individuel BG
------------------------

- Classements separes pour DPS, soigneurs, tanks et supports.
- Les DPS peuvent etre filtres en Tous, Melee ou Distance.
- Chaque joueur est compare uniquement aux joueurs du meme role dans le BG.
- Trois BG de placement sont necessaires avant de recevoir un rang officiel;
  les joueurs suivis une ou deux fois restent visibles mais non classes.
- Les metriques sont comparees a la moyenne du role avec une courbe continue
  et strictement croissante : deux gros resultats ne partagent plus le meme
  plafond et le meilleur resultat reste distingue.
- Les degats et les soins sont ajustes prudemment selon le niveau median du
  role dans le BG, sans effacer l'impact de la specialisation ou du joueur.
- Les interruptions, dissipations et vols de sort mesurables enrichissent le
  score des tanks et des supports sans conserver le detail des evenements.
- Les soigneurs sont notes a 95% sur les soins et a 5% sur la survie.
- Le score 100 represente la moyenne du role et est lisse avec 10 BG virtuels.
- Le classement utilise une borne prudente : une marge d'incertitude est
  retiree au score lisse. Elle est forte avec un seul BG puis diminue avec
  chaque participation ponderee, afin qu'un nouveau joueur ne depasse pas
  artificiellement une performance deja confirmee.
- La regularite indique le pourcentage de BG comparables a au moins 90% du
  meilleur joueur du meme role.
- Le coefficient collectif de stomp reduit de la meme facon l'influence du BG
  pour tous les joueurs.
- Les arrivees et departs en cours de BG sont mesures : les statistiques sont
  corrigees au temps joue et leur poids historique suit le taux de presence.
- Moins de 25% de presence, zero degat pour un DPS ou zero soin pour un
  soigneur ne produisent aucun echantillon individuel.
- Un resultat n'est accepte qu'apres avoir observe le BG actif puis sa fin,
  afin d'ignorer le gagnant obsolete du BG precedent pendant un chargement.
- Le rang utilise une icone; le nom est colore selon la classe.
- Les specialisations sont regroupees sous une icone avec un tooltip detaille.
- La derniere rencontre avec chaque joueur est affichee dans le tableau.
- Chaque en-tete explique sa valeur au survol.
- La recherche par nom propose jusqu'a huit joueurs en autocompletion.
- Ce classement commence avec la version 2.2.0 car l'ancien historique ne
  contenait que des donnees anonymes par specialisation.
- La version 2.7.0 conserve une copie exacte des anciens echantillons dans
  chaque entree, convertit leur moyenne vers la nouvelle courbe sans changer
  leur ordre, corrige les compteurs doubles detectables et applique ensuite
  le nouvel algorithme complet a tous les BG suivants.

Classement PvE
--------------

- Trois categories : Degats, Soins et Tanks.
- Trois vues : Tous, Donjons et Raids.
- Un donjon termine constitue un echantillon complet.
- Un boss de raid vaincu constitue un echantillon independant.
- DPS donjon : poids boss adapte au temps de combat et a la part de degats
  reellement observee, reference robuste face aux autres DPS et correction du
  temps de participation.
- Une phase boss ou trash trop courte, marginale ou observee sur un seul DPS
  est ignoree afin qu'un evenement parasite ne puisse pas inverser les notes.
- Les degats sont corriges selon le niveau median des DPS du groupe avec une
  courbe prudente et bornee : le niveau est lisse sans effacer la build,
  l'equipement ni la performance reelle.
- DPS raid : performance sur le boss vaincu.
- Soins : stabilite, recuperation, couverture, disponibilite, mana et
  prevention. L'overheal ne pese que 2%.
- En raid, la contribution est ajustee au nombre et au profil des soigneurs.
- Tanks : controle d'aggro, prise des ennemis, stabilite, resistance,
  assistance externe, pics de degats et survie.
- La note tank donne davantage de poids au controle reel, stabilise les
  references historiques peu fournies, ignore les morts de recuperation et
  ne penalise plus directement les soins externes recus.
- Les degats du tank ajoutent au maximum 2 points et ses soins/absorptions au
  maximum 1 point. Ces bonus secondaires diminuent si l'aggro ou la survie
  ne sont pas satisfaisantes.
- Le score 100 represente la moyenne d'un contexte comparable.
- Dix echantillons virtuels stabilisent les petits volumes de donnees.
- Confiance : Provisoire (<5), Moyenne (5-19), Fiable (20+).
- Les barres de progression utilisent les memes couleurs de role que le
  classement BG avec un contraste renforce.

Performance PvE en temps reel
-----------------------------

- Un onglet separe suit tous les personnages du donjon actuel en temps reel.
- Les barres de progression reprennent la couleur rouge, orange, jaune ou
  verte de la note et disposent d'un contraste renforce.
- Le dernier donjon reste consultable apres avoir quitte l'instance.
- Les donnees sont remplacees uniquement au debut du donjon suivant.
- Chaque personnage recoit une note sur 10 adaptee a son role.
- 7/10 represente la performance attendue pour ce role et ce groupe.
- Un widget compact et deplacable peut afficher en donjon le nom et la note de
  chaque joueur. Il reutilise le snapshot existant, sans seconde collecte.
- Les noms temporairement indisponibles au chargement sont rescannes et
  recuperes aussi depuis le journal de combat au lieu de rester "Unknown".
- Le widget disparait automatiquement en dehors des donjons.
- DPS : comparaison robuste aux autres DPS, avec poids boss adaptatif, temps
  de participation et meme correction de niveau que l'historique.
- Le DPS/HPS affiche reste brut; seule la note comparative est ajustee.
- Les degats et actions des familiers, gardiens et invocations temporaires
  restent attribues a leur proprietaire pendant tout le donjon.
- Les diagnostics separent les degats directs et ceux des pets, leurs soins,
  absorptions, invocations et evenements. Les degats allies sans proprietaire
  identifiable sont aussi conserves pour reperer une invocation CoA atypique.
- L'historique des diagnostics affiche dans les reglages uniquement les logs
  complets et prets a etre envoyes pour analyse, avec le nom du donjon et sa
  date de fin selon l'heure locale du PC.
- Les 10 diagnostics complets les plus recents sont conserves; les anciens
  rapports sont remplaces automatiquement et la liste reste defilable.
- Les valeurs des classements PvE et de la performance du donjon utilisent
  exactement les memes colonnes, largeurs et alignements que leurs en-tetes.
- Toute l'interface, les info-bulles, confirmations et messages visibles sont
  disponibles en francais et en anglais. Les drapeaux francais et americain
  en haut a droite changent la langue et le choix est conserve.
- La langue peut aussi etre changee avec /coaa language fr ou en.
- Soigneurs : stabilite, soins utiles, recuperation, disponibilite, mana,
  absorptions et utilitaires.
- En donjon avec un seul soigneur, la note ne depend plus d'un second
  soigneur inexistant. Elle combine stabilite de vie, couverture, vitesse de
  recuperation, gestion du mana, prevention/utilitaires et temps en vie.
- La reactivite mesure d'abord la sortie de danger a 65% de vie. La remontee
  complete a 80% reste diagnostiquee separement afin de respecter les HoT.
- Sans echec critique ni mort evitable, une recuperation progressive ne peut
  plus provoquer a elle seule une forte penalite de reactivite.
- La pression reelle du donjon determine la confiance et le poids historique,
  sans limiter artificiellement la note d'execution affichee.
- La vie du groupe est echantillonnee toutes les 0,5 seconde pendant le combat
  pour mesurer les passages sous 75%, 50% et 25%, ainsi que les recuperations.
- Tanks : controle d'aggro, resistance, assistance recue et survie.
- Supports : contribution par minute, participation, temps en vie et
  utilitaires detectables, compares a un contexte historique equivalent.

Collecte PvE
------------

La collecte se lance automatiquement dans les instances de type donjon ou
raid. Le combat log est traite en temps reel et seules des statistiques
agregees sont conservees. La menace est echantillonnee environ trois fois par
seconde uniquement pendant les combats afin de limiter l'impact sur le jeu.

Les evenements officiels de fin de rencontre valident les boss de raid. Les
evenements de completion valident les donjons. Si le client ne produit pas
l'evenement de completion, une sortie peu apres un boss vaincu peut valider le
donjon avec le statut de completion deduite.

Nameplates et scoreboard BG
---------------------------

- Icone de role et de specialisation au-dessus ou sur la ligne du nameplate.
- Roles DPS melee et distance differencies.
- Compatible avec les nameplates Blizzard et ElvUI.
- Scoreboard BG : icone de specialisation, role, niveau, couleur de classe,
  meilleur DPS et meilleur soigneur.

Settings
--------

- Les reglages generaux et les reglages de nameplates sont separes.
- Le widget de performance en donjon peut etre active, masque et repositionne.
- Un bouton du widget partage la note globale, puis une ligne par joueur dans
  le canal groupe ou raid.
- La collecte PvE continue tant que le groupe combat, meme si l'utilisateur
  est mort. Le dernier boss est consolide avant l'enregistrement du donjon.
- Les morts instantanees sont distinguees des morts precedees d'une longue
  periode critique.
- La note des soigneurs se concentre sur la stabilite, la reactivite, la
  disponibilite et la gestion du mana. L'overheal ne pese que 2%.
- Lorsque l'utilisateur est l'unique soigneur, les morts et les degats hors
  de sa portee, hors combat ou pendant le retour apres un wipe ne diminuent
  plus sa note. Une mort reste affichee dans le rapport brut.
- Les DPS utilisent une reference robuste, un poids boss adaptatif et le temps
  de participation propre a chaque phase. Les joueurs inactifs et les anciens
  membres remplaces ne faussent plus la reference du groupe.
- Une phase representant moins de 3% des degats est ignoree; entre 3% et 20%,
  son poids augmente progressivement pour eviter qu'un segment marginal ne
  renverse le classement DPS.
- Les remplacements restent visibles individuellement, mais la taille du
  groupe utilise le maximum de joueurs presents simultanement.
- Un diagnostic peut etre active pour le donjon actuel ou le suivant. Le suivi
  reste ensuite actif et conserve les 10 derniers donjons sans doublon.
- Une entree sans combat ne consomme plus le diagnostic et ne peut plus
  remplacer un rapport valide. L'export choisit le donjon termine le plus
  recent et conserve le diagnostic arme jusqu'au premier vrai combat.
- Le diagnostic indique le nombre, la duree et l'origine des segments boss et
  trash pour faciliter l'analyse des clients Ascension atypiques.
- Le bouton "Exporter les rapports" recharge automatiquement l'interface et
  enregistre l'historique dans
  WTF\Account\<compte>\SavedVariables\CoAAnalytics.lua.
- Le bouton "Tout effacer" supprime aussi la copie technique du dernier
  donjon et les metadonnees d'export, puis recharge automatiquement
  l'interface pour repercuter immediatement l'effacement sur le disque.

Migration depuis CoA BG Intelligence
-------------------------------------

Le dossier principal devient CoAAnalytics et la base devient CoAAnalyticsDB.
Un petit pont de migration charge une fois l'ancienne base
CoABGIntelligenceDB puis copie tous les reglages et classements BG. Il ne
recalcule, ne reinitialise et ne supprime aucune donnee historique.

Commandes
---------

/coaa settings       ouvre l'interface
/coaa classement     ouvre le classement BG
/coaa joueurs        ouvre le classement individuel BG
/coaa pve            ouvre le classement PvE
/coaa performance    ouvre la performance du donjon actuel ou precedent
/coaa pve status     affiche l'etat de la collecte PvE
/coaa pve complete   valide manuellement le donjon actif (secours)
/coaa pve log on     active le suivi continu des diagnostics de donjon
/coaa pve log off    annule le diagnostic
/coaa pve log status affiche le statut et le chemin du fichier
/coaa pve log clear  efface les diagnostics conserves
/coaa status         affiche l'etat des nameplates BG
/coaa debug          active le debug BG
/coaa retry          relance la detection des specialisations
/coaa log            ouvre le journal de detection BG
/coaa log clear      efface ce journal

La commande historique /coabgi reste acceptee comme alias de compatibilite.
