local API = CoAAnalyticsAPI

-- Le francais reste la langue par defaut des installations existantes.
-- Les textes sources restent en francais afin de limiter les changements dans
-- les modules de calcul; cette table traduit uniquement ce qui est affiche.
local ENGLISH = {
	["Settings"] = "Settings",
	["General"] = "General",
	["Nameplates"] = "Nameplates",
	["Classement BG"] = "BG Rankings",
	["Classement PvE"] = "PvE Rankings",
	["Performance PvE"] = "PvE Performance",
	["Specialisations"] = "Specializations",
	["Joueurs"] = "Players",
	["Degats"] = "Damage",
	["Soins"] = "Healing",
	["Tanks"] = "Tanks",
	["Supports"] = "Supports",
	["Tous"] = "All",
	["Donjons"] = "Dungeons",
	["Raids"] = "Raids",
	["Tous DPS"] = "All DPS",
	["Melee"] = "Melee",
	["Distance"] = "Ranged",
	["RANG"] = "RANK",
	["CLASSE / SPECIALISATION"] = "CLASS / SPECIALIZATION",
	["PERSONNAGE / SPECIALISATION"] = "CHARACTER / SPECIALIZATION",
	["JOUEUR"] = "PLAYER",
	["DERNIERE VUE"] = "LAST SEEN",
	["REGULARITE"] = "CONSISTENCY",
	["CONFIANCE"] = "CONFIDENCE",
	["MORTS"] = "DEATHS",
	["NOTE /10"] = "RATING /10",
	["PART (%)"] = "SHARE (%)",
	["Au-dessus - gauche"] = "Above - left",
	["Au-dessus - centre"] = "Above - center",
	["Au-dessus - droite"] = "Above - right",
	["Meme ligne - gauche"] = "Same line - left",
	["Meme ligne - droite"] = "Same line - right",
	["Performance du donjon"] = "Dungeon Performance",
	["Performance du donjon a l'ecran"] = "On-screen Dungeon Performance",
	["Afficher le widget de performance en donjon"] = "Show the dungeon performance widget",
	["Reinitialiser la position"] = "Reset Position",
	["Historique des diagnostics de donjon"] = "Dungeon Diagnostic History",
	["Aucun diagnostic enregistre"] = "No diagnostic recorded",
	["Aucun diagnostic complet enregistre"] = "No complete diagnostic recorded",
	["Aucun diagnostic complet conserve."] = "No complete diagnostic retained.",
	["Diagnostic actif pour le donjon actuel"] = "Diagnostic active for the current dungeon",
	["Suivi continu actif pour le prochain donjon"] = "Continuous tracking active for the next dungeon",
	["Desactiver"] = "Disable",
	["Enregistrer le prochain"] = "Record Next",
	["Tout effacer"] = "Clear All",
	["Exporter les rapports"] = "Export Reports",
	["Exporter"] = "Export",
	["Oui"] = "Yes",
	["Non"] = "No",
	["Annuler"] = "Cancel",
	["Cliquer pour utiliser cette langue."] = "Click to use this language.",
	["Langues disponibles : Francais (fr), Anglais (en)."] = "Available languages: French (fr), English (en).",
	["Affichage au-dessus des joueurs"] = "Display Above Players",
	["Icone du role"] = "Role Icon",
	["Icone de specialisation"] = "Specialization Icon",
	["Afficher l'icone de specialisation"] = "Show Specialization Icon",
	["Par defaut"] = "Defaults",
	["Classement selon les performances cumulees en BG"] = "Ranking by cumulative BG performance",
	["BG analyses"] = "BGs Analyzed",
	["BG collectes"] = "BGs Collected",
	["Influence moyenne"] = "Average Influence",
	["Specialisations classees"] = "Ranked Specializations",
	["Joueurs classes"] = "Ranked Players",
	["Reinitialiser"] = "Reset",
	["Rechercher un joueur..."] = "Search for a player...",
	["Echantillons analyses"] = "Samples Analyzed",
	["Reference moyenne"] = "Average Reference",
	["Donjon suivi"] = "Tracked Dungeon",
	["Temps de combat"] = "Combat Time",
	["Note moyenne du groupe"] = "Average Group Rating",
	["SUIVI EN TEMPS REEL"] = "LIVE TRACKING",
	["DERNIER DONJON CONSERVE"] = "LAST RETAINED DUNGEON",
	["EN ATTENTE D'UN DONJON"] = "WAITING FOR A DUNGEON",
	["Aucun"] = "None",
	["Partager le classement"] = "Share Ranking",
	["CoA Analytics - Groupe "] = "CoA Analytics - Group ",
	["Glisser pour deplacer"] = "Drag to move",
	["Collecte en cours..."] = "Collecting data...",
	["Clic gauche : reglages"] = "Left-click: settings",
	["Glisser : deplacer le bouton"] = "Drag: move the button",
	["Journal de detection des allies"] = "Ally Detection Log",
	["Tout selectionner"] = "Select All",
	["Fermer"] = "Close",
	["Classe inconnue"] = "Unknown class",
	["Specialisation inconnue"] = "Unknown specialization",
	["Role inconnu"] = "Unknown role",
	["Joueur inconnu"] = "Unknown player",
	["Donjon inconnu"] = "Unknown dungeon",
	["Donjon"] = "Dungeon",
	["Joueur"] = "Player",
	["Role"] = "Role",
	["ROLE"] = "ROLE",
	["Specialisation"] = "Specialization",
	["Instance inconnue"] = "Unknown instance",
	["date inconnue"] = "unknown date",
	["Inconnu"] = "Unknown",
	["Inconnue"] = "Unknown",
	["inconnue"] = "unknown",
	["faible"] = "low",
	["normale"] = "normal",
	["elevee"] = "high",
	["Ancienne"] = "Older",
	["Provisoire"] = "Provisional",
	["Moyenne"] = "Average",
	["Fiable"] = "Reliable",
	["Placement"] = "Placement",
	["DPS melee"] = "Melee DPS",
	["DPS distance"] = "Ranged DPS",
	["Soigneur"] = "Healer",
	["soigneurs"] = "healers",
	["donjons et raids"] = "dungeons and raids",
	["donjons"] = "dungeons",
	["boss de raid"] = "raid bosses",
	["Tank"] = "Tank",
	["Support"] = "Support",

	["Affiche uniquement en donjon une liste compacte et deplacable : nom colore par classe et note sur 10. Le widget reutilise le snapshot PvE actualise chaque seconde, sans collecte supplementaire."] =
		"Shows a compact movable list only in dungeons: class-colored names and ratings out of 10. The widget reuses the PvE snapshot refreshed every second, with no additional data collection.",
	["Seuls les diagnostics complets et prets a etre envoyes pour analyse sont listes. Les 10 plus recents sont conserves."] =
		"Only complete diagnostics ready to be sent for analysis are listed. The 10 most recent are retained.",
	["Exporter enregistre le fichier dans : WTF\\Account\\<compte>\\SavedVariables\\CoAAnalytics.lua"] =
		"Export writes the file to: WTF\\Account\\<account>\\SavedVariables\\CoAAnalytics.lua",
	["Exporter les diagnostics conserves ? L'interface sera rechargee automatiquement afin d'ecrire le fichier."] =
		"Export the retained diagnostics? The interface will reload automatically to write the file.",
	["Emplacement des icones sur les nameplates ennemies. Si les deux utilisent le meme emplacement, elles sont alignees automatiquement."] =
		"Icon positions on enemy nameplates. If both use the same position, they are aligned automatically.",
	["Compatible avec les nameplates Blizzard et ElvUI. Les modifications sont appliquees immediatement."] =
		"Compatible with Blizzard and ElvUI nameplates. Changes are applied immediately.",
	["Aucun score lisse pour le moment.\nLe classement commencera a la fin du prochain BG complet."] =
		"No stabilized score yet.\nRanking will begin after the next completed BG.",
	["Aucun joueur classe dans cette categorie.\nLe classement individuel commencera a la fin du prochain BG complet."] =
		"No ranked player in this category.\nIndividual ranking will begin after the next completed BG.",
	["Aucune performance PvE valide pour le moment.\nLe classement commencera apres un donjon termine ou un boss de raid vaincu."] =
		"No valid PvE performance yet.\nRanking will begin after a completed dungeon or a defeated raid boss.",
	["Aucun donjon memorise pour le moment.\nLe suivi commencera automatiquement a l'entree du prochain donjon."] =
		"No retained dungeon yet.\nTracking will start automatically upon entering the next dungeon.",
	["Effacer tout l'historique du classement PvE ?"] = "Clear the entire PvE ranking history?",
	["Effacer les classements BG par specialisation et par joueur ?"] = "Clear BG rankings by specialization and player?",
	["Effacer uniquement le classement individuel des joueurs ? Le classement par specialisation sera conserve."] =
		"Clear only the individual player ranking? The specialization ranking will be retained.",
	["Envoie la note du groupe, puis une ligne par joueur."] = "Sends the group rating, followed by one line per player.",
	["Cliquez sur Tout selectionner, faites Ctrl+C, puis envoyez le texte apres le BG."] =
		"Click Select All, press Ctrl+C, then send the text after the BG.",

	["Le score compare les performances moyennes, pas le nombre total de presences. Cinq participations virtuelles a la moyenne stabilisent les petits echantillons."] =
		"The score compares average performance, not total appearances. Five virtual average participations stabilize small samples.",
	["Part de cette specialisation dans la somme des scores normalises. Une presence frequente augmente la fiabilite, mais n'augmente plus directement ce pourcentage."] =
		"This specialization's share of normalized scores. Frequent appearances improve reliability but no longer directly increase this percentage.",
	["Le coefficient de stomp reduit l'influence du BG entier, jamais celle d'un joueur seul."] =
		"The stomp coefficient reduces the influence of the entire BG, never that of a single player.",
	["BG complets ayant distribue des points dans l'onglet actuel."] =
		"Completed BGs that awarded points in the current tab.",
	["Un BG equilibre compte a 100%, soit 1 point. Plus l'ecart de morts et de degats entre les equipes est grand, plus l'influence du BG est reduite, jusqu'a 25%. Le meme coefficient est applique a toutes les specialisations du match."] =
		"A balanced BG counts at 100%, or 1 point. The larger the death and damage gap between teams, the lower the BG influence, down to 25%. The same coefficient applies to every specialization in the match.",
	["Nombre de specialisations ayant deja recu des points dans l'onglet actuel."] =
		"Number of specializations that have already received points in the current tab.",
	["Position selon la performance moyenne par participation, apres lissage statistique."] =
		"Position by average performance per participation after statistical stabilization.",
	["Classe et specialisation CoA regroupees anonymement. Aucun nom de joueur n'est conserve dans cette vue."] =
		"CoA class and specialization grouped anonymously. No player name is retained in this view.",
	["Points moyens par participation. Le score est lisse avec cinq BG virtuels a la moyenne pour eviter qu'un petit echantillon domine le classement."] =
		"Average points per participation. The score is stabilized with five virtual average BGs so a small sample cannot dominate the ranking.",
	["Part de la specialisation dans la somme des scores normalises. Le nombre de participations ne donne plus directement de points supplementaires."] =
		"Specialization share of normalized scores. The number of participations no longer directly grants additional points.",
	["Nombre de BG enregistres depuis l'activation du classement individuel. L'ancien historique anonyme ne contient aucun nom recuperable."] =
		"Number of BGs recorded since individual ranking was enabled. The old anonymous history contains no recoverable names.",
	["Poids moyen des BG. Un stomp influence moins le classement, avec le meme coefficient pour tous les joueurs du match."] =
		"Average BG weight. A stomp has less ranking influence, using the same coefficient for all players in the match.",
	["Nombre de personnages ayant termine les trois BG de placement dans le role et le filtre affiches."] =
		"Number of characters who completed three placement BGs in the displayed role and filter.",
	["Position officielle apres trois BG de placement. Les joueurs encore en placement affichent un tiret."] =
		"Official position after three placement BGs. Players still in placement display a dash.",
	["Nom complet du personnage. Sa couleur correspond a sa classe. L'icone voisine affiche ses specialisations au survol."] =
		"Full character name. Its color matches the class. Hover the adjacent icon to view observed specializations.",
	["Moment de votre derniere rencontre avec ce personnage dans un BG enregistre."] =
		"Time of your latest encounter with this character in a recorded BG.",
	["Score classant = performance relative a la moyenne du role, corrigee selon le niveau et le pourcentage du BG effectivement joue, puis lissee avec 10 BG virtuels et une marge d'incertitude. Un joueur present moins de 25% ou sans degats/soins utiles a son role n'est pas enregistre."] =
		"Ranking score = performance relative to the role average, adjusted for level and actual BG participation, then stabilized with 10 virtual BGs and an uncertainty margin. A player present for under 25% or with no primary role activity is not recorded.",
	["Pourcentage de BG ou le joueur atteint au moins 90% du meilleur score de son role."] =
		"Percentage of BGs where the player reaches at least 90% of the best score for their role.",
	["Nombre de BG valides observes avec ce role. Trois BG sont necessaires pour recevoir un rang officiel."] =
		"Number of valid BGs observed with this role. Three BGs are required for an official rank.",
	["Placement jusqu'a 3 BG, puis confiance provisoire avant 5 BG, moyenne de 5 a 19 BG et fiable a partir de 20 BG."] =
		"Placement up to 3 BGs, provisional confidence before 5 BGs, average from 5 to 19 BGs, and reliable from 20 BGs.",
	["Rang officiel apres 3 BG valides. Les arrivees en cours de partie sont corrigees au temps joue et pesent moins dans l'historique ; moins de 25% de presence ou une activite principale nulle sont ignores."] =
		"Official rank after 3 valid BGs. Late joins are adjusted for time played and carry less historical weight; under 25% participation or zero primary activity is ignored.",
	["Le score est ramene vers 100 tant que l'echantillon est faible."] =
		"The score is pulled toward 100 while the sample is small.",
	["Les nouveaux echantillons DPS sont corriges selon le niveau median du groupe, avec une correction limitee pour conserver l'effet de la build et de l'equipement."] =
		"New DPS samples are adjusted to the group's median level, with a limited correction that preserves the impact of build and gear.",
	["100 = performance moyenne dans un contexte comparable. Le score est ajuste au contenu, puis stabilise avec 10 echantillons virtuels."] =
		"100 = average performance in a comparable context. The score is adjusted for content, then stabilized with 10 virtual samples.",
	[" Pour les DPS, les degats sont aussi ajustes au niveau median du groupe."] =
		" For DPS, damage is also adjusted to the group's median level.",
	[" Vue : "] = " View: ",
	["DPS : poids boss adapte au donjon, reference robuste entre DPS, puis correction prudente du niveau, de la participation et du temps en vie. Une phase trop courte ou isolee est ignoree."] =
		"DPS: dungeon-adjusted boss weight, robust comparison between DPS players, then cautious correction for level, participation, and alive time. Phases that are too short or isolated are ignored.",
	["Ce coefficient corrige uniquement la comparaison de la note; le DPS affiche reste la valeur reelle."] =
		"This coefficient only adjusts the rating comparison; displayed DPS remains the real value.",
	["Soigneur : stabilite, recuperation, couverture, disponibilite et gestion du mana. L'overheal a un impact presque nul. En soigneur unique, les morts hors portee et pendant un retour de wipe sont exclues."] =
		"Healer: stability, recovery, coverage, availability, and mana management. Overhealing has almost no impact. With a solo healer, out-of-range deaths and deaths during wipe recovery are excluded.",
	["Tank : controle d'aggro prioritaire, resistance stabilisee, survie et utilitaires. Les degats et soins ajoutent seulement un bonus secondaire."] =
		"Tank: threat control first, stabilized resilience, survival, and utility. Damage and healing only add a secondary bonus.",
	["Contribution : "] = "Contribution: ",
	["Contribution : degats %.0f%% (+%.1f) | soins %.0f%% (+%.1f)"] =
		"Contribution: damage %.0f%% (+%.1f) | healing %.0f%% (+%.1f)",
	["Support : degats et soins mesurables. Les bonus, controles et utilitaires non exposes par le client ne peuvent pas tous etre notes."] =
		"Support: measurable damage and healing. Buffs, control, and utility not exposed by the client cannot all be scored.",
	["7/10 correspond a la performance attendue pour le role dans ce groupe."] =
		"7/10 represents the expected performance for the role in this group.",
	["La note compare chaque personnage aux attentes de son propre role : 7/10 = performance attendue, 10/10 = exceptionnelle. Le resultat reste visible apres la sortie et sera remplace uniquement au debut du prochain donjon."] =
		"The rating compares each character with the expectations of their own role: 7/10 = expected performance, 10/10 = exceptional. The result remains visible after leaving and is replaced only when the next dungeon begins.",

	["Score lisse : "] = "Stabilized score: ",
	[" point par participation"] = " point per participation",
	["Score = performance par participation, lissee avec "] = "Score = performance per participation, stabilized with ",
	[" BG virtuels a la moyenne. "] = " virtual average BGs. ",
	["Jouer souvent augmente la fiabilite, pas le score. Influence moyenne des BG : "] =
		"Playing often improves reliability, not score. Average BG influence: ",
	[" ; les stomps comptent moins."] = "; stomps count less.",
	["Moyenne brute : "] = "Raw average: ",
	["Points cumules : "] = "Total points: ",
	["Part du classement : "] = "Ranking share: ",
	["Top 1 observes : "] = "Observed #1 finishes: ",
	["Top 1 : "] = "#1 finishes: ",
	["Top du role : "] = "Role #1 finishes: ",
	["Proche du meilleur (>= 90%) : "] = "Near the best (>= 90%): ",
	["Echantillon : "] = "Sample: ",
	[" BG (poids cumule "] = " BG (cumulative weight ",
	["Echantillons : "] = "Samples: ",
	["Echantillons ajustes au niveau : "] = "Level-adjusted samples: ",
	["Derniere performance creditee : "] = "Last credited performance: ",
	["Derniere rencontre : "] = "Last encounter: ",
	["Score classant : "] = "Ranking score: ",
	["Score de role : "] = "Role score: ",
	["Estimation lissee : "] = "Stabilized estimate: ",
	["(brut "] = "(raw ",
	["Marge d'incertitude : "] = "Uncertainty margin: ",
	["Regularite : "] = "Consistency: ",
	["en attente d'un adversaire du meme role"] = "waiting for an opponent of the same role",
	["BG comparables"] = "comparable BGs",
	["Presence au dernier BG : "] = "Last BG participation: ",
	["Dernier BG : "] = "Last BG: ",
	["mediane du role"] = "role median",
	["Placement : "] = "Placement: ",
	["BG valides avant le rang officiel."] = "valid BGs before an official rank.",
	["Confiance : "] = "Confidence: ",
	["Confiance "] = "Confidence ",
	["Indice brut : "] = "Raw index: ",
	["Note : "] = "Rating: ",
	["Non classe : "] = "Unranked: ",
	["Note en attente de donnees suffisantes."] = "Rating pending sufficient data.",
	["Degats : "] = "Damage: ",
	["Soins utiles : "] = "Effective healing: ",
	["Degats directs : %s | Degats des pets : %s (%.0f%%) | Invocations : %d"] =
		"Direct damage: %s | Pet damage: %s (%.0f%%) | Summons: %d",
	["Morts : "] = "Deaths: ",
	["Niveau "] = "Level ",
	["niveau median DPS"] = "median DPS level",
	["niveau median"] = "median level",
	["coefficient"] = "coefficient",
	["Stabilite "] = "Stability ",
	["Couverture "] = "Coverage ",
	["Reactivite "] = "Responsiveness ",
	["Disponibilite "] = "Availability ",
	["Prevention "] = "Prevention ",
	["Sortie de danger : "] = "Time out of danger: ",
	["Remontee a 80% : "] = "Recovery to 80%: ",
	["Reference : "] = "Reference: ",
	["echantillon(s)"] = "sample(s)",
	["confiance"] = "confidence",
	["Bonus utilitaire"] = "Utility bonus",
	["Controle "] = "Control ",
	["Perte "] = "Loss ",
	["Acquisition "] = "Acquisition ",
	["Resistance "] = "Resilience ",
	["Survie "] = "Survival ",
	["Rapports complets : "] = "Complete reports: ",
	[" | Dernier : "] = " | Latest: ",
	["Il y a "] = "",
	["A l'instant"] = "Just now",
	["un partage est deja en cours"] = "a share is already in progress",
	["aucun classement de donjon a partager"] = "no dungeon ranking to share",
	["diagnostic demarre avec le premier combat"] = "diagnostic started with the first combat",
	["aucun donjon actif a finaliser"] = "no active dungeon to finalize",
	["ce donjon a deja ete enregistre"] = "this dungeon has already been recorded",
	["donjon enregistre"] = "dungeon recorded",
	["donjon ignore : "] = "dungeon ignored: ",
	["diagnostic pret : il demarrera au premier combat"] = "diagnostic ready: it will start with the first combat",
	["diagnostic conserve pour le prochain vrai donjon"] = "diagnostic retained for the next actual dungeon",
	["diagnostic actif pour le donjon actuel"] = "diagnostic active for the current dungeon",
	["diagnostic desactive"] = "diagnostic disabled",
	["diagnostic arme pour le prochain donjon"] = "diagnostic armed for the next dungeon",
	["historique des diagnostics efface"] = "diagnostic history cleared",
	["aucun diagnostic a exporter"] = "no diagnostic to export",
	["diagnostic(s) en cours..."] = "diagnostic(s) being exported...",
	["arme pour le prochain donjon"] = "armed for the next dungeon",
	["dernier rapport : "] = "latest report: ",
	["rapport(s) conserve(s) sur "] = "report(s) retained out of ",
	["fichier apres /reload : "] = "file after /reload: ",
	["aucune instance PvE active"] = "no active PvE instance",
	["presence de combat insuffisante"] = "insufficient combat participation",
	["aucune activite mesurable"] = "no measurable activity",
	["combat trop court"] = "combat too short",
	["roles ou specialisations incomplets"] = "incomplete roles or specializations",
	["aucun degat pour ce role"] = "no damage for this role",
	["aucun soin utile pour ce role"] = "no effective healing for this role",
	["temps de tanking insuffisant"] = "insufficient tanking time",
	["aucune performance notee"] = "no rated performance",
	["fin du donjon"] = "dungeon completion",
	["sortie du donjon"] = "leaving the dungeon",
	["diagnostic enregistre ("] = "diagnostic recorded (",
	["). Le suivi reste actif pour le prochain donjon."] = "). Tracking remains active for the next dungeon.",
	["dernier donjon conserve"] = "last retained dungeon",
	[", specialisations "] = ", specializations ",
	["journal de detection allie efface"] = "ally detection log cleared",
	["donnees de detection effacees et remises en file"] = "detection data cleared and queued again",
	["erreur module "] = "module error ",
	["/coaa settings | classement | joueurs | pve | performance | pve log on|off|status|clear | pve status | language fr|en | log | status | debug | retry"] =
		"/coaa settings | ranking | players | pve | performance | pve log on|off|status|clear | pve status | language fr|en | log | status | debug | retry",
}

local FRENCH = {
	["Settings"] = "Reglages",
	["Nameplates"] = "Barres de nom",
	["General"] = "General",
	["debug enabled"] = "debug active",
	["debug disabled"] = "debug desactive",
}

local replacements
local cache = {}
local cacheCount = 0

local function CacheTranslation(original, translated)
	if translated ~= original and cacheCount < 2000 then
		cache[original] = translated
		cacheCount = cacheCount + 1
	end
	return translated
end

local function EscapePattern(value)
	return (value:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

local function BuildReplacements()
	replacements = {}
	for french, english in pairs(ENGLISH) do
		replacements[#replacements + 1] = { french, english }
	end
	table.sort(replacements, function(left, right)
		return #left[1] > #right[1]
	end)
end

function API.GetLanguage()
	local database = _G.CoAAnalyticsDB
	if type(database) == "table" and database.language == "en" then
		return "en"
	end
	return "fr"
end

function API.LocalizeText(value)
	if value == nil then
		return ""
	end
	local original = tostring(value)
	if API.GetLanguage() ~= "en" then
		return FRENCH[original] or original
	end
	if cache[original] ~= nil then
		return cache[original]
	end
	local direct = ENGLISH[original]
	if direct then
		return CacheTranslation(original, direct)
	end
	if not replacements then
		BuildReplacements()
	end
	local translated = original
	for index = 1, #replacements do
		local pair = replacements[index]
		if translated:find(pair[1], 1, true) then
			translated = translated:gsub(EscapePattern(pair[1]), function()
				return pair[2]
			end)
		end
	end
	return CacheTranslation(original, translated)
end

function API.SetLanguage(language, reloadUI)
	language = tostring(language or ""):lower()
	if language ~= "fr" and language ~= "en" then
		return false
	end
	if type(_G.CoAAnalyticsDB) ~= "table" then
		_G.CoAAnalyticsDB = {}
	end
	_G.CoAAnalyticsDB.language = language
	cache = {}
	cacheCount = 0
	if reloadUI and type(ReloadUI) == "function" then
		ReloadUI()
	end
	return true
end

function API.LocalizeRegion(region)
	if not region or region.coaAnalyticsLocalized then
		return region
	end
	local originalSetText = region.SetText
	if type(originalSetText) == "function" then
		region.SetText = function(self, value)
			return originalSetText(self, API.LocalizeText(value))
		end
	end
	local originalSetFormattedText = region.SetFormattedText
	if type(originalSetFormattedText) == "function" then
		region.SetFormattedText = function(self, formatText, ...)
			return originalSetFormattedText(self, API.LocalizeText(formatText), ...)
		end
	end
	local originalCreateFontString = region.CreateFontString
	if type(originalCreateFontString) == "function" then
		region.CreateFontString = function(self, ...)
			return API.LocalizeRegion(originalCreateFontString(self, ...))
		end
	end
	region.coaAnalyticsLocalized = true
	return region
end

function API.CreateLocalizedFrame(...)
	return API.LocalizeRegion(CreateFrame(...))
end

function API.CreateLocalizedTooltipProxy(tooltip)
	if not tooltip then
		return tooltip
	end
	return setmetatable({}, {
		__index = function(_, key)
			if key == "AddLine" then
				return function(_, value, ...)
					return tooltip:AddLine(API.LocalizeText(value), ...)
				end
			elseif key == "AddDoubleLine" then
				return function(_, left, right, ...)
					return tooltip:AddDoubleLine(
						API.LocalizeText(left), API.LocalizeText(right), ...
					)
				end
			elseif key == "SetText" then
				return function(_, value, ...)
					return tooltip:SetText(API.LocalizeText(value), ...)
				end
			elseif key == "AppendText" then
				return function(_, value)
					return tooltip:AppendText(API.LocalizeText(value))
				end
			end
			local member = tooltip[key]
			if type(member) == "function" then
				return function(_, ...)
					return member(tooltip, ...)
				end
			end
			return member
		end,
	})
end
