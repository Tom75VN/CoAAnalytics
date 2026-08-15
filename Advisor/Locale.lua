local Advisor = _G.CoAAnalyticsAdvisor

-- The game-data parser deliberately remains English-only.  This file is used
-- exclusively at presentation boundaries (our frames, chat and tooltips).
-- Existing French strings remain the canonical internal strings so the
-- recommendation engine and saved data are not affected by the UI language.

local FRENCH = {
    ["High"] = "Élevée",
    ["Medium"] = "Moyenne",
    ["Low"] = "Faible",
    ["Head"] = "Tête",
    ["Neck"] = "Cou",
    ["Shoulders"] = "Épaules",
    ["Shirt"] = "Chemise",
    ["Chest"] = "Torse",
    ["Waist"] = "Taille",
    ["Legs"] = "Jambes",
    ["Feet"] = "Pieds",
    ["Wrist"] = "Poignets",
    ["Hands"] = "Mains",
    ["Ring 1"] = "Anneau 1",
    ["Ring 2"] = "Anneau 2",
    ["Trinket 1"] = "Bijou 1",
    ["Trinket 2"] = "Bijou 2",
    ["Back"] = "Dos",
    ["Main Hand"] = "Main droite",
    ["Off Hand"] = "Main gauche",
    ["Ranged"] = "Distance",
    ["Tabard"] = "Tabard",
}

local ENGLISH = {
    ["Procs Time"] = "Time procs",
    ["Glisser pour déplacer"] = "Drag to move",
    ["Talent non sélectionné"] = "Talent not selected",
    ["PRÊT"] = "READY",
    ["EN ATTENTE"] = "WAITING",
    ["CHANGE D'AEON"] = "SWAP AEON",
    ["CAST : Oblivion → Ripple"] = "CAST: Oblivion → Ripple",
    ["Change d'Aeon → Oblivion → Ripple"] =
        "Swap Aeon → Oblivion → Ripple",
    ["Change d'Aeon maintenant"] = "Swap Aeon now",
    ["Through actif : continue la rotation"] =
        "Through active: continue the rotation",
    ["Ideal Time : GO = Oblivion puis Ripple."] =
        "Ideal Time: GO = Oblivion then Ripple.",
    ["Ideal Time : le timer indique le temps restant pour crit."] =
        "Ideal Time: the timer shows how long remains to use the crit.",
    ["Through : le timer indique le prochain changement d'Aeon."] =
        "Through: the timer shows when the next Aeon swap is ready.",
    ["PvE Mythic+ : Esprit > Puissance des sorts > Critique > Hâte > Intelligence > MP5."] =
        "PvE Mythic+: Spirit > Spell Power > Critical Strike > Haste > Intellect > MP5.",
    ["Esprit > Puissance des sorts > Critique > Hâte > Intelligence > MP5"] =
        "Spirit > Spell Power > Critical Strike > Haste > Intellect > MP5",
    -- Main window and navigation.
    ["Recommandations de classe et collecte communautaire DataProbe"] =
        "Class recommendations and community DataProbe collection",
    ["Conseils de personnage"] = "Character Advice",
    ["Langue de l’interface uniquement. Le parseur conserve les tooltips anglais."] =
        "Interface language only. The parser keeps using English tooltips.",
    ["Langues disponibles : fr, en."] = "Available languages: fr, en.",
    ["Conseils de spécialisation"] = "Specialization advice",
    ["Conseils"] = "Advice",
    ["Conseils  •  "] = "Advice  •  ",
    ["1  •  Export"] = "1  •  Export",
    ["2  •  Communauté"] = "2  •  Community",
    ["1. Actualiser les données"] = "1. Update data",
    ["2. Choisir le prochain talent"] = "2. Choose the next talent",
    ["2. Talents conseillés"] = "2. Recommended talents",
    ["3. Contexte et priorité"] = "3. Content and priority",
    ["4. Comparer l’équipement"] = "4. Compare gear",
    ["5. Analyse locale automatique"] = "5. Automatic local analysis",
    ["Analyser maintenant"] = "Analyze now",
    ["Actualiser + repérer #1"] = "Update + highlight #1",
    ["Surligner build BG"] = "Highlight BG build",
    ["Surligner build Mythic+"] = "Highlight Mythic+ build",
    ["Masquer le build"] = "Hide build",
    ["Minimum : 5 combats"] = "Minimum: 5 fights",
    ["Analyse locale : ON"] = "Local analysis: ON",
    ["Analyse locale : OFF"] = "Local analysis: OFF",
    ["Effacer l’historique local"] = "Clear local history",
    ["Astuce : déplace le bouton de minimap en le faisant glisser."] =
        "Tip: drag the minimap button to move it.",
    ["À utiliser après la connexion, un changement de niveau, de talents ou d’équipement. Pour détecter les talents, ouvre les arbres de classe et de spécialisation."] =
        "Use after logging in or changing level, talents, or gear. To detect talents, open the class and specialization trees.",
    ["Le profil choisi à l’étape 3 reclasse immédiatement tous les talents réellement achetables. Clique une carte pour repérer le talent dans l’arbre."] =
        "The profile selected in step 3 immediately reranks every talent you can actually buy. Click a card to highlight the talent in the tree.",
    ["Le profil choisi à l’étape 3 reclasse immédiatement tous les talents réellement achetables. Surligne aussi le build complet PvE ou PvP dans l’arbre."] =
        "The step 3 profile immediately reranks purchasable talents. You can also highlight the full PvE or PvP build in the tree.",
    ["Surlignage du build masqué."] = "Build highlighting hidden.",
    ["Aucun build complet publié pour cette spécialisation."] =
        "No complete published build is available for this specialization.",
    ["Ouvre les deux arbres de Character Advancement, puis clique à nouveau."] =
        "Open both Character Advancement trees, then click again.",
    ["vert = déjà pris"] = "green = already selected",
    ["or = requis manquant"] = "gold = required and missing",
    ["bleu F = choix flexible"] = "blue F = flexible choice",
    ["rouge X = à retirer"] = "red X = remove",
    ["Analyse privée et automatique : fins de combat, mana et morts. L’addon conseille une priorité, mais ne la change jamais sans ton clic. Les tooltips d’objets utilisent directement les besoins détectés."] =
        "Private automatic analysis: combat endings, resources, and deaths. The addon suggests a priority but never changes it without your click. Item tooltips directly use the detected needs.",

    -- Status and controls.
    ["Aucun scan disponible. Clique sur Analyser maintenant."] =
        "No scan available. Click Analyze now.",
    ["Indisponible"] = "Unavailable",
    ["Équipement non calibré"] = "Gear not calibrated",
    ["Conseils d’objets : ACTIVÉS"] = "Item advice: ENABLED",
    ["Conseils d’objets : DÉSACTIVÉS"] = "Item advice: DISABLED",
    ["Jets automatiques : CUPIDITÉ"] =
        "Automatic rolls: GREED",
    ["Jets automatiques : SIGNALER"] =
        "Automatic rolls: HIGHLIGHT",
    ["Jets automatiques"] = "Automatic rolls",
    ["1. Activer les jets automatiques"] =
        "1. Enable automatic rolls",
    ["2. Statistiques à exclure pour ce personnage"] =
        "2. Stats to exclude for this character",
    ["3. Résumé du filtre"] = "3. Filter summary",
    ["Cupidité automatique pour les matériaux sûrs, les équipements incompatibles confirmés et les statistiques exclues ci-dessous. La liaison est confirmée uniquement pour un jet lancé par CoA Analytics."] =
        "Automatic Greed for safe materials, confirmed incompatible gear, and the excluded stats below. Binding is confirmed only for a roll started by CoA Analytics.",
    ["Coche une statistique seulement si tu ne veux jamais faire Besoin sur un équipement qui la contient. Une seule correspondance suffit pour choisir Cupidité, même si l’objet est portable."] =
        "Select a stat only if you never want to roll Need on gear containing it. One match is enough to choose Greed, even when the item is usable.",
    ["Aucune statistique exclue. "] = "No excluded stat. ",
    ["Automatisation désactivée. "] = "Automation disabled. ",
    ["Les cases sont conservées, mais aucun jet automatique n’est effectué."] =
        "Selections are preserved, but no automatic roll is made.",
    ["Seuls les matériaux sûrs et les équipements incompatibles confirmés utilisent automatiquement Cupidité."] =
        "Only safe materials and confirmed incompatible gear automatically use Greed.",
    ["FILTRE STRICT ACTIF : "] = "STRICT FILTER ACTIVE: ",
    ["Cupidité automatique si l’objet contient au moins une de ces stats :"] =
        "Automatic Greed if the item contains at least one of these stats:",
    ["Tout décocher"] = "Clear all",
    ["Attention : "] = "Warning: ",
    ["Endurance, Intelligence et Résilience sont fréquentes. Les exclure peut envoyer en Cupidité des améliorations utiles."] =
        "Stamina, Intellect, and Resilience are common. Excluding them can Greed useful upgrades.",
    ["Force"] = "Strength",
    ["Agilité"] = "Agility",
    ["Intelligence"] = "Intellect",
    ["Esprit"] = "Spirit",
    ["Endurance"] = "Stamina",
    ["Puissance des sorts"] = "Spell Power",
    ["Bonus de soins"] = "Healing Bonus",
    ["Puissance d’attaque"] = "Attack Power",
    ["Hâte"] = "Haste",
    ["Critique"] = "Critical Strike",
    ["Toucher (Hit Rating)"] = "Hit Rating",
    ["Toucher"] = "Hit",
    ["Pénétration d’armure"] = "Armor Penetration",
    ["Pénétration des sorts"] = "Spell Penetration",
    ["Résilience"] = "Resilience",
    ["Mana par 5 s"] = "Mana per 5 sec",
    ["Vie par 5 s"] = "Health per 5 sec",
    ["Puissance JcE"] = "PvE Power",
    ["Puissance JcJ"] = "PvP Power",
    ["Mode sûr : l’addon choisit Cupidité pour l’équipement incompatible confirmé et pour les catégories Trade Goods, Gem et Reagent."] =
        "Safe mode: the addon chooses Greed for confirmed incompatible gear and for the Trade Goods, Gem, and Reagent categories.",
    ["La confirmation de liaison est automatique uniquement pour un jet lancé par CoA Analytics. Recettes, quêtes, consommables et objets incertains restent manuels."] =
        "Binding is confirmed automatically only for a roll started by CoA Analytics. Recipes, quest items, consumables, and uncertain items remain manual.",
    ["Cupidité automatique activée pour le butin incompatible confirmé et les matériaux sûrs."] =
        "Automatic Greed enabled for confirmed incompatible loot and safe materials.",
    ["Cupidité automatique désactivée. Les objets incompatibles restent signalés en rouge."] =
        "Automatic Greed disabled. Incompatible items remain highlighted in red.",
    ["jets de cupidité automatiques activés pour le butin incompatible confirmé et les matériaux sûrs."] =
        "automatic Greed rolls enabled for confirmed incompatible loot and safe materials.",
    ["jets de cupidité automatiques désactivés."] =
        "automatic Greed rolls disabled.",
    ["cupidité automatique sélectionnée : "] =
        "automatic Greed selected: ",
    [" — matériau sûr."] = " — safe material.",
    [" — statistique exclue : "] = " — excluded stat: ",
    ["liaison confirmée automatiquement pour le jet de cupidité : "] =
        "binding automatically confirmed for Greed roll: ",
    [" incompatible avec ce personnage."] =
        " is incompatible with this character.",
    ["Analyse désactivée"] = "Analysis disabled",
    ["Priorité déjà adaptée"] = "Priority already adapted",
    ["Analyse locale arrêtée. Aucun combat n’est observé."] =
        "Local analysis stopped. No combat is being observed.",
    ["Analyse locale automatique activée."] =
        "Automatic local analysis enabled.",
    ["Analyse locale automatique arrêtée."] =
        "Automatic local analysis stopped.",
    ["Analyse terminée : statistiques, équipement et talents actualisés."] =
        "Analysis complete: stats, gear, and talents updated.",
    ["Scan terminé, mais les talents manquent. Ouvre leur page et recommence."] =
        "Scan complete, but talents are missing. Open their page and try again.",
    ["Aucun changement local à appliquer."] =
        "No local change to apply.",
    ["La priorité conseillée localement a été appliquée."] =
        "The locally suggested priority was applied.",
    ["L’analyse locale de cette spécialisation a été effacée."] =
        "Local analysis for this specialization was cleared.",
    ["Les recommandations apparaîtront maintenant dans les tooltips."] =
        "Recommendations will now appear in tooltips.",
    ["Les recommandations de tooltip sont maintenant masquées."] =
        "Tooltip recommendations are now hidden.",
    ["Contexte appliqué : "] = "Content selected: ",
    ["Profil appliqué : "] = "Profile selected: ",
    ["Appliquer : "] = "Apply: ",
    ["fiabilité élevée"] = "high confidence",
    ["fiabilité moyenne"] = "medium confidence",
    ["première tendance"] = "early trend",
    ["échantillon insuffisant"] = "insufficient sample",

    -- Character summaries.
    ["Niveau "] = "Level ",
    ["Agilité "] = "Agility ",
    ["PA distance "] = "Ranged AP ",
    ["Crit distance "] = "Ranged crit ",
    ["Hâte distance : "] = "Ranged haste: ",
    ["Mana finale moyenne "] = "Average ending mana ",
    ["Focus final moyen "] = "Average ending Focus ",
    ["Focus sous 20% : "] = "Focus below 20%: ",
    ["Soins excédentaires "] = "Overhealing ",
    [" hors incantation, "] = " while not casting, ",
    [" en incantation"] = " while casting",
    [" talents sélectionnés"] = " talents selected",
    [" talents détectés"] = " talents detected",
    [" talent(s) achetable(s) détecté(s)"] = " purchasable talent(s) detected",
    [" objets équipés"] = " equipped items",
    [" objets"] = " items",
    [" combats"] = " fights",
    [" morts"] = " deaths",
    [" secondes"] = " seconds",
    [" du temps"] = " of the time",

    -- Talent UI and talent explanations.
    ["Talents indisponibles. "] = "Talents unavailable. ",
    ["Accessibilité non vérifiée. "] = "Availability not verified. ",
    ["Aucun talent réellement achetable détecté. "] =
        "No truly purchasable talent detected. ",
    ["Aucun talent accessible ne dépasse le seuil de recommandation. "] =
        "No accessible talent exceeds the recommendation threshold. ",
    ["Les choix situationnels ne sont plus présentés comme optimaux."] =
        "Situational choices are no longer presented as optimal.",
    ["Ouvre les arbres de classe et de spécialisation, laisse-les visibles, puis analyse."] =
        "Open the class and specialization trees, leave them visible, then analyze.",
    ["Ouvre les arbres de talents et relance l’analyse."] =
        "Open the talent trees and run the analysis again.",
    ["Vérifie qu’un point est disponible, ouvre les deux arbres, puis clique sur Actualiser."] =
        "Make sure a point is available, open both trees, then click Update.",
    ["Ouvre les arbres de talents de classe et de spécialisation, puis clique à nouveau."] =
        "Open the class and specialization talent trees, then click again.",
    ["Clique pour faire clignoter ce talent dans l’arbre."] =
        "Click to highlight this talent in the tree.",
    ["Rang actuel : "] = "Current rank: ",
    ["Score — "] = "Score — ",
    ["Situationnel : utile dans certains matchs, moins universel."] =
        "Situational: useful in some matches, less universally valuable.",
    ["Choix situationnel : classé, mais pénalisé par défaut"] =
        "Situational choice: ranked, but penalized by default",
    ["Choix accessible classé prudemment d’après son rôle et son type."] =
        "Accessible choice ranked cautiously from its role and type.",
    ["Description non capturée : classement provisoire, à confirmer avec DataProbe."] =
        "Description not captured: provisional ranking to confirm with DataProbe.",
    ["Moins prioritaire dans le build guide pour ce contexte."] =
        "Lower priority in the guide build for this content.",
    ["Bénéfices détectés : "] = "Detected benefits: ",
    ["valeur pour le profil"] = "profile value",
    ["profil actif"] = "active profile",
    ["rendement"] = "throughput",
    ["ressource / autonomie"] = "resource / sustain",
    ["survie"] = "survival",
    ["utilité"] = "utility",
    ["Talent pivot du build guide pour ce contexte."] =
        "Pivot talent in the guide build for this content.",
    ["Pour « "] = "For “",
    [" », son bénéfice principal est : "] = "”, its main benefit is: ",

    -- Curated Time and Archery talent explanations.
    ["Le Spirit augmente les soins et la régénération de mana."] =
        "Spirit increases healing and mana regeneration.",
    ["Convertit directement le Spirit en puissance de soin."] =
        "Directly converts Spirit into healing power.",
    ["Conserve davantage de régénération pendant les incantations."] =
        "Keeps more regeneration active while casting.",
    ["Améliore la régénération de mana en combat."] =
        "Improves mana regeneration in combat.",
    ["Ajoute du critique aux principaux soins Time."] =
        "Adds critical chance to the main Time heals.",
    ["La hâte accélère les soins et réduit le recul d’incantation."] =
        "Haste speeds up healing and reduces spell pushback.",
    ["La hâte améliore la réactivité et le rendement des soins."] =
        "Haste improves responsiveness and healing throughput.",
    ["Permet aux soins périodiques de devenir critiques."] =
        "Allows periodic healing to critically heal.",
    ["Accélère le principal soin direct."] = "Speeds up the main direct heal.",
    ["Ajoute un coefficient de soin à Reverse Wound."] =
        "Adds a healing coefficient to Reverse Wound.",
    ["Étend Accelerated Recovery à un allié supplémentaire."] =
        "Extends Accelerated Recovery to one additional ally.",
    ["Ajoute un soin Epoch aux cibles d’Accelerated Recovery."] =
        "Adds an Epoch heal to Accelerated Recovery targets.",
    ["Génère la ressource utilisée par plusieurs synergies Time."] =
        "Generates the resource used by several Time synergies.",
    ["Réduit le coût des sorts pendant Endless Sands."] =
        "Reduces spell costs during Endless Sands.",
    ["Augmente le soin d’Epoch grâce à Sands of Time."] =
        "Increases Epoch healing through Sands of Time.",
    ["Améliore la mana lors de l’utilisation des Aeons."] =
        "Improves mana when using Aeons.",
    ["Ajoute une absorption utile contre le burst en BG."] =
        "Adds a useful absorb against burst damage in BGs.",
    ["Rend les Epoch moins coûteux et plus rapides."] =
        "Makes Epoch casts cheaper and faster.",
    ["Ajoute un soin retardé contre la pression prolongée."] =
        "Adds delayed healing against sustained pressure.",
    ["Forte protection lorsque les ennemis ciblent le soigneur."] =
        "Strong protection when enemies focus the healer.",
    ["Ajoute un soin de groupe instantané et prolonge le HoT principal."] =
        "Adds an instant group heal and extends the main HoT.",
    ["Soin de groupe essentiel."] = "Essential group heal.",
    ["Soin de zone avec immunité aux étourdissements pendant la canalisation."] =
        "Area healing with stun immunity while channeling.",
    ["Réduit le coût en mana des sorts instantanés."] =
        "Reduces the mana cost of instant spells.",
    ["Dissipation supplémentaire situationnelle, hors du chemin Time conseillé par défaut."] =
        "Situational extra dispel outside the default recommended Time path.",
    ["Les soins critiques réduisent le temps de recharge de Ripple."] =
        "Critical heals reduce Ripple's cooldown.",
    ["Les critiques d'Epoch renforcent fortement le prochain Ripple."] =
        "Epoch criticals greatly empower the next Ripple.",
    ["Fortify Timeline prépare un Reverse Wound nettement renforcé."] =
        "Fortify Timeline prepares a substantially stronger Reverse Wound.",
    ["Prolonge les Aeons : soins, efficacité mana et protection supplémentaires."] =
        "Extends Aeons for additional healing, mana efficiency, and protection.",
    ["Correct the Mistake génère Endless Sands et accélère Reverse Wound."] =
        "Correct the Mistake generates Endless Sands and speeds up Reverse Wound.",
    ["Dissipation de masse puissante contre des effets magiques décisifs."] =
        "Powerful mass dispel against decisive magical effects.",
    ["Sauve et repositionne un allié tout en retirant roots et ralentissements."] =
        "Saves and repositions an ally while removing roots and slows.",
    ["Les critiques de Skullpiercer et Precision Shot ajoutent une forte blessure."] =
        "Skullpiercer and Precision Shot criticals add a powerful wound.",
    ["Augmente l'Agilité et réduit les ralentissements."] =
        "Increases Agility and reduces slows.",
    ["Renforce les tirs de précision et leurs synergies."] =
        "Strengthens precision shots and their synergies.",
    ["Améliore directement les tirs principaux d'Archery."] =
        "Directly improves Archery's main shots.",
    ["Precision Shot augmente les dégâts physiques subis par la cible."] =
        "Precision Shot increases physical damage taken by the target.",
    ["Excellent finisseur basé sur les dégâts de l'arme à distance."] =
        "Excellent finisher based on ranged weapon damage.",
    ["Accélère les dégâts de Toxic Dart et sa pression."] =
        "Speeds up Toxic Dart damage and pressure.",
    ["Les techniques à distance ignorent une partie de l'armure d'une cible empoisonnée."] =
        "Ranged abilities ignore part of a poisoned target's armor.",
    ["Dégâts de zone et génération d'Advantage."] =
        "Area damage and Advantage generation.",
    ["Le critique et le toucher renforcent presque toute la rotation."] =
        "Critical strike and hit improve nearly the entire rotation.",
    ["Renforce les techniques centrales de la spécialisation."] =
        "Strengthens the specialization's core abilities.",
    ["Technique centrale : dégâts élevés et nombreuses synergies."] =
        "Core ability: high damage and many synergies.",
    ["Les Auto Shots rendent du Focus et stabilisent la rotation."] =
        "Auto Shots restore Focus and stabilize the rotation.",
    ["Augmente les dégâts d'arme de Quick Shot."] =
        "Increases Quick Shot weapon damage.",
    ["Les critiques amplifient les saignements sur la cible."] =
        "Criticals amplify bleeds on the target.",
    ["Ajoute régulièrement des dégâts d'arme à distance."] =
        "Regularly adds ranged weapon damage.",
    ["Les attaques automatiques peuvent infliger une frappe supplémentaire."] =
        "Auto attacks can deal an additional strike.",
    ["Apporte hâte à distance au groupe et critique personnel."] =
        "Provides ranged haste to the group and personal critical chance.",
    ["Augmente le critique et réduit fortement les coûts en Focus."] =
        "Increases critical chance and greatly reduces Focus costs.",
    ["Récompense les fenêtres de tir favorables."] =
        "Rewards favorable shooting windows.",
    ["Améliore la pression à distance sans alourdir la rotation."] =
        "Improves ranged pressure without burdening the rotation.",
    ["Augmente la polyvalence des munitions et des tirs."] =
        "Increases ammunition and shot versatility.",
    ["Bonus de dégâts général pour la spécialisation."] =
        "General damage bonus for the specialization.",
    ["Améliore les fenêtres où le Focus est disponible."] =
        "Improves windows where Focus is available.",
    ["Les Auto Shots prolongent Serrated Shot."] =
        "Auto Shots extend Serrated Shot.",
    ["Améliore le rythme de la rotation et la mobilité."] =
        "Improves rotation tempo and mobility.",
    ["Bonus utile pour engager et maintenir la pression."] =
        "Useful bonus for engaging and maintaining pressure.",
    ["Choix défensif et mobile pour les combats BG."] =
        "Defensive and mobile choice for BG combat.",
    ["Soutient les phases de dégâts prolongées."] =
        "Supports sustained damage phases.",
    ["Améliore la durée d'engagement et la survie."] =
        "Improves engagement duration and survival.",

    -- Profile and content labels.
    ["BG équilibré"] = "Balanced BG",
    ["PvE équilibré"] = "Balanced PvE",
    ["Soins maximum"] = "Maximum healing",
    ["Autonomie mana"] = "Mana sustain",
    ["Progression PvE"] = "PvE progression",
    ["Survie BG"] = "BG survival",
    ["Survie & mobilité"] = "Survival & mobility",
    ["Dégâts maximum"] = "Maximum damage",
    ["Critique & Focus"] = "Critical & Focus",
    ["Précision & Focus"] = "Accuracy & Focus",
    ["Équilibré"] = "Balanced",
    ["Autonomie"] = "Sustain",
    ["Survie"] = "Survival",
    ["Ressource"] = "Resource",
    ["Mitigation"] = "Mitigation",
    ["Protection"] = "Protection",
    ["Soigneur équilibré"] = "Balanced healer",
    ["DPS équilibré"] = "Balanced DPS",
    ["Tank équilibré"] = "Balanced tank",
    ["Soutien équilibré"] = "Balanced support",
    ["Autonomie de ressource"] = "Resource sustain",
    ["Survie et utilité"] = "Survival and utility",
    ["Ressource et rythme"] = "Resource and tempo",
    ["Survie et contrôle"] = "Survival and control",
    ["Menace et dégâts"] = "Threat and damage",
    ["Menace / dégâts"] = "Threat / damage",
    ["Ressource et contrôle"] = "Resource and control",
    ["Mitigation maximum"] = "Maximum mitigation",
    ["Impact du groupe"] = "Group impact",
    ["Impact groupe"] = "Group impact",
    ["Ressource et disponibilité"] = "Resource and uptime",
    ["Protection et contrôle"] = "Protection and control",
    ["PvE / Donjons"] = "PvE / Dungeons",
    ["PvP / BG"] = "PvP / BG",
    ["Sécurité PvE"] = "PvE safety",
    ["Rendement"] = "Throughput",
    ["Ressource / autonomie"] = "Resource / sustain",
    ["Dégâts à distance"] = "Ranged damage",
    ["Rythme & Focus"] = "Tempo & Focus",
    ["Survie PvP"] = "PvP survival",
    ["Choisis entre équilibre BG, puissance de soin, autonomie mana ou survie."] =
        "Choose between balanced BG, healing power, mana sustain, or survival.",
    ["Choisis entre équilibre BG, dégâts maximum, critique/Focus ou survie."] =
        "Choose between balanced BG, maximum damage, critical/Focus, or survival.",
    ["L'addon sépare le rendement de soin, l'autonomie mana et la survie."] =
        "The addon separates healing throughput, mana sustain, and survival.",
    ["L'addon sépare dégâts à distance, rythme de rotation/Focus et survie."] =
        "The addon separates ranged damage, rotation tempo/Focus, and survival.",
    ["Les talents sont reclassés selon la priorité choisie. Une règle issue d'une infobulle est signalée comme provisoire."] =
        "Talents are reranked for the selected priority. A rule inferred from a tooltip is marked provisional.",
    ["Le profil de comparaison d'équipement n'est pas encore calibré."] =
        "The gear comparison profile is not calibrated yet.",
    ["Priorités PvP du guide. La Résilience et l’Endurance restent séparées du rendement afin d’exposer les compromis."] =
        "Guide PvP priorities. Resilience and Stamina remain separate from throughput to expose tradeoffs.",
    ["Priorités PvE du guide. Les caps de toucher, expertise ou défense restent provisoires jusqu’à mesure en jeu."] =
        "Guide PvE priorities. Hit, expertise, and defense caps remain provisional until measured in game.",
    ["Le rôle, les priorités PvE/PvP et le talent pivot viennent du guide publié. Les infobulles en jeu adaptent ensuite le classement à la priorité choisie."] =
        "The role, PvE/PvP priorities, and pivot talent come from the published guide. In-game tooltips then adapt the ranking to the selected priority.",
    ["Profil guide disponible, mais comparaison d’équipement désactivée jusqu’à calibration des conversions par DataProbe."] =
        "Guide profile available, but gear comparison is disabled until DataProbe calibrates the conversions.",
    ["Comparaison prudente par indice de priorité PvE/PvP. Elle reconnaît les statistiques fixes, mais ne chiffre pas les procs, caps ni synergies non mesurés."] =
        "Conservative PvE/PvP priority-index comparison. It recognizes fixed stats but does not quantify unmeasured procs, caps, or synergies.",
    ["Build de base vérifié : 26 points de classe + 25 points de spécialisation. Confiance contextuelle : moyenne."] =
        "Verified baseline build: 26 class points + 25 specialization points. Context confidence: medium.",
    ["Repères : Donjon "] = "Benchmarks: Dungeon ",
    ["BuildHub indexé : "] = "Indexed BuildHub: ",
    [" build(s) public(s) pour cette spécialisation."] =
        " public build(s) for this specialization.",
    [" • Raid "] = " • Raid ",
    [" • Arène "] = " • Arena ",
    [" • BG "] = " • BG ",
    ["Présent dans le build de base vérifié ; la priorité choisie départage ensuite son rendement, sa survie et son utilité."] =
        "Included in the verified baseline build; the selected priority then weighs its throughput, survival, and utility.",

    -- Item tooltip.
    ["Amélioration"] = "Upgrade",
    ["Forte amélioration"] = "Strong upgrade",
    ["Moins bon pour le BG"] = "Worse for BG",
    ["Moins bon"] = "Downgrade",
    ["Choix situationnel"] = "Situational choice",
    ["Paire incomplète"] = "Incomplete pair",
    ["Décision"] = "Decision",
    ["Sacrifice principal"] = "Main tradeoff",
    ["Priorité "] = "Priority ",
    ["Remplacer"] = "Replace",
    ["Emplacement vide"] = "Empty slot",
    ["Confiance"] = "Confidence",
    ["Conseils par set"] = "Recommendations by set",
    ["Set PvP / BG"] = "PvP / BG set",
    ["Set PvE / donjons"] = "PvE / dungeon set",
    ["Remplacer dans ce set"] = "Replace in this set",
    ["Détail actif : "] = "Active details: ",
    ["ÉQUIPER"] = "EQUIP",
    ["GARDER"] = "KEEP",
    ["OPTIONNEL"] = "OPTIONAL",
    ["SITUATIONNEL"] = "SITUATIONAL",
    ["VÉRIFIER"] = "CHECK",
    ["COMPARER"] = "COMPARE",
    ["ÉQUIPÉ"] = "EQUIPPED",
    ["Élevée"] = "High",
    ["Moyenne"] = "Medium",
    ["Faible"] = "Low",
    ["REMPLACER"] = "REPLACE",
    ["REMPLACER — ANALYSE LOCALE"] = "REPLACE — LOCAL ANALYSIS",
    ["REMPLACEMENT OPTIONNEL"] = "OPTIONAL REPLACEMENT",
    ["CHOIX SITUATIONNEL"] = "SITUATIONAL CHOICE",
    ["GARDER L'ACTUEL"] = "KEEP CURRENT",
    ["GARDER PAR DÉFAUT"] = "KEEP BY DEFAULT",
    ["GARDER — ANALYSE LOCALE"] = "KEEP — LOCAL ANALYSIS",
    ["VÉRIFIER MANUELLEMENT"] = "CHECK MANUALLY",
    ["COMPARER LA PAIRE"] = "COMPARE THE PAIR",
    ["DÉJÀ ÉQUIPÉ"] = "ALREADY EQUIPPED",
    ["Analyse locale : "] = "Local analysis: ",
    ["À envisager seulement si "] = "Consider only if ",
    ["Équiper seulement si "] = "Equip only if ",
    ["tu veux maximiser les soins"] = "you want to maximize healing",
    ["tu veux maximiser les dégâts"] = "you want to maximize damage",
    ["tu manques souvent de mana"] = "you often run out of mana",
    ["tu veux améliorer le rythme et la gestion du Focus"] =
        "you want to improve tempo and Focus management",
    ["tu dois mieux survivre"] = "you need more survival",
    ["tu dois mieux survivre en PvP"] = "you need more PvP survival",
    ["tu dois sécuriser la progression PvE"] =
        "you need safer PvE progression",
    ["L'écart est trop faible pour justifier le remplacement."] =
        "The difference is too small to justify replacing the item.",
    ["Aucun changement d'équipement."] = "No gear change.",
    ["Cette main gauche exige aussi une arme à une main compatible."] =
        "This off-hand also requires a compatible one-handed weapon.",
    ["Un effet spécial n'est pas évalué : aucun remplacement sûr."] =
        "A special effect is not evaluated: no replacement is safe.",
    ["OBJET INCOMPATIBLE"] = "ITEM INCOMPATIBLE",
    ["INCOMPATIBLE"] = "INCOMPATIBLE",
    ["Ce personnage ne peut pas équiper cet objet."] =
        "This character cannot equip this item.",
    ["Les stats ne compensent pas la perte de 8 % de vitesse."] =
        "The stats do not offset losing 8% movement speed.",
    ["Le gain principal ne compense pas ton besoin actuel."] =
        "The main gain does not offset your current need.",
    ["Le gain principal ne répond pas à ton besoin actuel."] =
        "The main gain does not address your current need.",
    ["Le nouvel objet n'apporte aucun avantage suffisant."] =
        "The new item provides no sufficient advantage.",
    ["Ton historique indique que "] = "Your history indicates that ",
    ["Ce gain n'est pas prioritaire pour ton style de jeu actuel."] =
        "This gain is not a priority for your current playstyle.",
    ["Cet objet sacrifie une priorité détectée dans tes combats."] =
        "This item sacrifices a priority detected in your fights.",
    ["Le petit gain ne répond pas à ton besoin actuel."] =
        "The small gain does not address your current need.",
    ["Petit gain, mais trop faible pour être une amélioration certaine."] =
        "Small gain, but too weak to be a certain upgrade.",
    ["À équiper contre les adversaires qui utilisent souvent des silences ou interruptions."] =
        "Equip against opponents who frequently use silences or interrupts.",
    ["Les statistiques sont trop proches ; à équiper seulement sur un combat avec des silences ou interruptions."] =
        "The stats are too close; equip only for an encounter with silences or interrupts.",
    ["Effet anti-silence reconnu : réduction de "] =
        "Recognized anti-silence effect: reduces duration by ",
    [" — utile en PvP"] = " — useful in PvP",
    [" — situationnel en PvE"] = " — situational in PvE",
    ["Meilleur pour le profil "] = "Better for the ",
    ["mana stable : "] = "mana stable: ",
    ["manque de mana détecté : "] = "mana shortage detected: ",
    [" de mana final moyen"] = " average ending mana",
    [" en moyenne à la fin des combats"] = " on average at the end of fights",
    [" de soins excédentaires : plus de puissance n'est pas prioritaire"] =
        " overhealing: more power is not a priority",
    ["Focus souvent faible pendant les combats ("] =
        "Focus often low during fights (",
    ["Focus stable : seulement "] = "Focus stable: only ",
    ["survie prioritaire : "] = "survival is a priority: ",
    ["survie stable : "] = "survival stable: ",
    [" des combats se terminent par une mort"] = " of fights end in death",
    [" de combats terminés par une mort"] = " of fights ended in death",
    ["Mana : régénération en incantation + réserve estimée sur 2 min"] =
        "Mana: casting regeneration + reserve estimated over 2 min",
    ["Rythme : critique, hâte et génération de Focus estimée"] =
        "Tempo: estimated critical, haste, and Focus generation",
    ["Comparaison incomplète : main gauche seule contre bâton."] =
        "Incomplete comparison: off-hand alone versus staff.",
    ["Ce type d’arme ne correspond pas au build conseillé."] =
        "This weapon type does not match the recommended build.",
    ["Choisis aussi une arme 1M pour comparer la paire complète."] =
        "Also choose a one-handed weapon to compare the complete pair.",
    ["arme 1M requise"] = "1H weapon required",
    ["Effet mana reconnu : +"] = "Recognized mana effect: +",
    ["Coût reconnu : "] = "Recognized cost: ",
    [" points de vie par utilisation"] = " health per use",
    ["Effet vitesse reconnu : +"] = "Recognized speed effect: +",
    ["Bonus vitesse conservé sur les deux objets : +"] =
        "Movement speed bonus kept on both items: +",
    ["Toucher : "] = "Hit: ",
    [" (profil provisoire)"] = " (provisional profile)",
    [" (à confirmer par DataProbe PvE)"] = " (to confirm with PvE DataProbe)",
    ["Special effect not scored - manual review required"] =
        "Special effect not scored — manual review required",
    ["Effet spécial non évalué — vérification manuelle requise"] =
        "Special effect not scored — manual review required",
    ["Ligne candidate : "] = "Candidate line: ",
    ["Ligne équipée : "] = "Equipped line: ",
    ["Indice de priorité : comparaison ordinale, pas un pourcentage de DPS, de soins ou de mitigation."] =
        "Priority index: ordinal comparison, not a DPS, healing, or mitigation percentage.",
    ["Un cap (toucher, expertise, défense ou pénétration) change dans cette comparaison : confirme le seuil en jeu."] =
        "A cap (hit, expertise, defense, or penetration) changes in this comparison: confirm the threshold in game.",
    ["indice "] = "index ",

    -- Stat labels generated by the addon.
    ["Ranged Weapon DPS"] = "Ranged Weapon DPS",
    ["Agility"] = "Agility",
    ["Attack Power"] = "Attack Power",
    ["Critical Strike Rating"] = "Critical Strike Rating",
    ["Haste Rating"] = "Haste Rating",
    ["Hit Rating"] = "Hit Rating",
    ["Armor Penetration"] = "Armor Penetration",
    ["Stamina"] = "Stamina",
    ["Resilience"] = "Resilience",
    ["Armor"] = "Armor",
    ["Health per 5"] = "Health per 5",
    ["Run Speed %"] = "Run Speed %",
    ["Strength (non valorisée)"] = "Strength (not valued)",
    ["DPS de l’arme à distance"] = "Ranged Weapon DPS",
    ["DPS de l’arme"] = "Weapon DPS",
    ["Score de coup critique"] = "Critical Strike Rating",
    ["Score de hâte"] = "Haste Rating",
    ["Score de toucher"] = "Hit Rating",
    ["Score d’expertise"] = "Expertise Rating",
    ["Score de défense"] = "Defense Rating",
    ["Score d’esquive"] = "Dodge Rating",
    ["Score de parade"] = "Parry Rating",
    ["Résistances"] = "Resistances",
    ["Armure"] = "Armor",
    ["Vitesse de course %"] = "Run Speed %",
    ["Force (non valorisée)"] = "Strength (not valued)",
    ["Agilité (sans valeur pour les soins)"] =
        "Agility (no healing value)",
    ["Force (sans valeur pour les soins)"] =
        "Strength (no healing value)",
    ["Spirit"] = "Spirit",
    ["Spell Power"] = "Spell Power",
    ["Intellect"] = "Intellect",

    -- Local automatic analysis.
    ["Donjon / raid"] = "Dungeon / raid",
    ["Monde / leveling"] = "World / leveling",
    ["Joue encore "] = "Play another ",
    [" combat(s) : aucune priorité ne sera modifiée avant un échantillon minimum."] =
        " fight(s): no priority will change before the minimum sample.",
    ["Aucune faiblesse dominante : conserve un profil équilibré."] =
        "No dominant weakness: keep a balanced profile.",
    ["Mana et survie sont stables : tu peux privilégier la puissance de soin."] =
        "Mana and survival are stable: you can prioritize healing power.",
    ["Tu passes souvent sous 35 % de vie : privilégie la survie."] =
        "You often fall below 35% health: prioritize survival.",
    ["Tes morts arrivent après "] = "Your deaths occur after ",
    [" s en moyenne : privilégie la survie."] =
        " s on average: prioritize survival.",
    [" s en moyenne : privilégie survie et contrôle."] =
        " s on average: prioritize survival and control.",
    ["Peu de morts : tu peux privilégier les dégâts maximum."] =
        "Few deaths: you can prioritize maximum damage.",
    ["Survie encore irrégulière : conserve un profil DPS équilibré."] =
        "Survival is still inconsistent: keep a balanced DPS profile.",
    ["Pression modérée : conserve un profil tank équilibré."] =
        "Moderate pressure: keep a balanced tank profile.",
    ["Survie stable : tu peux investir davantage dans menace et dégâts."] =
        "Stable survival: you can invest more in threat and damage.",

    -- DataProbe tabs and instructions.
    ["1. Prépare une contribution communautaire"] =
        "1. Prepare a community contribution",
    ["2. Capture le build avant de jouer"] =
        "2. Capture the build before playing",
    ["3. Survole ce qui décrit la spécialisation"] =
        "3. Hover over what describes the specialization",
    ["4. Joue normalement"] = "4. Play normally",
    ["5. Vérifie les données disponibles"] = "5. Check available data",
    ["6. Termine et partage le fichier"] = "6. Finish and share the file",
    ["DÉMARRER UNE SESSION"] = "START A SESSION",
    ["ARRÊTER LA COLLECTE"] = "STOP COLLECTION",
    ["D'ABORD : DÉMARRER UNE SESSION"] = "FIRST: START A SESSION",
    ["ARBRES OUVERTS — CAPTURER LE BUILD"] = "TREES OPEN — CAPTURE BUILD",
    ["AJOUTER AU MÊME FICHIER"] = "ADD TO THE SAME FILE",
    ["Terminer + exporter"] = "Finish + export",
    ["Effacer toutes les archives"] = "Clear all archives",
    ["Exporter l'archive"] = "Export archive",
    ["ÉTAPE 1 — DÉMARRE UNE SESSION"] = "STEP 1 — START A SESSION",
    ["ÉTAPE 1 TERMINÉE — COLLECTE ACTIVE, CONTEXTE AUTO"] =
        "STEP 1 COMPLETE — COLLECTION ACTIVE, AUTO CONTENT",
    ["Détection automatique : "] = "Automatic detection: ",
    ["BG, arène, donjon, raid, monde et PvP sauvage sont classés séparément pour chaque combat."] =
        "BG, arena, dungeon, raid, world, and open-world PvP are classified separately for each fight.",
    ["A. Ouvre Character Advancement.\nB. Affiche successivement l'arbre de classe et l'arbre de spécialisation.\nC. Laisse la fenêtre ouverte et clique le bouton à droite."] =
        "A. Open Character Advancement.\nB. Show the class tree and specialization tree in turn.\nC. Leave the window open and click the button on the right.",
    ["Les talents choisis et envisagés, puis les sorts importants du spellbook et des barres."] =
        "Chosen and considered talents, then important spells from the spellbook and action bars.",
    ["Tout l'équipement et plusieurs objets candidats, avec la comparaison visible."] =
        "All equipped gear and several candidate items, with comparison visible.",
    ["Retire un seul objet, attends 2 s, remets-le, attends 2 s."] =
        "Remove one item, wait 2 sec, equip it again, then wait 2 sec.",
    ["Répète avec Agilité, Spirit, critique, hâte, PA/SP, Stamina ou Resilience selon la classe."] =
        "Repeat with Agility, Spirit, critical, haste, AP/SP, Stamina, or Resilience as appropriate for the class.",
    ["Même build pendant 3–5 BG ou au moins 10 combats de donjon/leveling."] =
        "Keep the same build for 3–5 BGs or at least 10 dungeon/leveling fights.",
    ["DataProbe conserve localement sorts, dégâts, soins, ressources, critiques, ratés et auras."] =
        "DataProbe locally records spells, damage, healing, resources, criticals, misses, and auras.",
    ["OPTIONNEL — AUTRE BUILD : "] = "OPTIONAL — ANOTHER BUILD: ",
    ["ajoute une nouvelle série au même fichier final."] =
        "add a new series to the same final file.",
    ["Les scans déjà collectés sont conservés ; rien n'est effacé."] =
        "Previously collected scans are kept; nothing is deleted.",
    ["L'export arrête la collecte puis recharge l'interface. Envoie ensuite :"] =
        "Export stops collection and reloads the interface. Then send:",
    ["Aucun envoi automatique ; noms anonymisés et identifiant de contributeur aléatoire."] =
        "Nothing is sent automatically; names are anonymized and the contributor ID is random.",
    ["Archive en veille : elle n'est pas chargée en mémoire tant que DataProbe reste OFF."] =
        "Archive idle: it is not loaded into memory while DataProbe remains OFF.",
    ["Démarre une session ou clique Exporter pour charger les compteurs."] =
        "Start a session or click Export to load the counters.",
    ["Passe à l'étape 2 : ouvre les deux arbres puis clique Capturer."] =
        "Continue to step 2: open both trees, then click Capture.",
    ["Une nouvelle session efface l'archive précédente, même si elle n'a pas encore été envoyée."] =
        "A new session clears the previous archive, even if it has not been sent yet.",
    ["Les scans déjà collectés sont conservés."] =
        "Previously collected scans are kept.",
    ["Effacer définitivement toutes les sessions DataProbe enregistrées ?"] =
        "Permanently delete all saved DataProbe sessions?",
    ["Effacer l’analyse locale de cette spécialisation ?"] =
        "Clear local analysis for this specialization?",
    ["Tout effacer"] = "Clear all",
    ["Effacer"] = "Clear",
    ["Annuler"] = "Cancel",

    -- Community coverage.
    ["Couverture communautaire publiée"] = "Published community coverage",
    ["Progression globale intégrée à cette version"] =
        "Overall progress included in this version",
    ["Couverture totale"] = "Total coverage",
    ["Page précédente"] = "Previous page",
    ["Page suivante"] = "Next page",
    ["Comment ces données améliorent réellement les recommandations"] =
        "How this data actually improves recommendations",
    ["SCAN DU BUILD ET DE L'ÉQUIPEMENT — 60 % de la couverture"] =
        "BUILD AND GEAR SCAN — 60% of coverage",
    ["COMPORTEMENT EN COMBAT — 30 % de la couverture"] =
        "COMBAT BEHAVIOR — 30% of coverage",
    ["VARIÉTÉ — 10 %"] = "VARIETY — 10%",
    ["Build : talents, sorts, stats (poids 30 %)"] =
        "Build: talents, spells, stats (30% weight)",
    ["Équipement : changements, objets (poids 30 %)"] =
        "Gear: changes and items (30% weight)",
    ["Guide publié (poids 25 %)"] = "Published guide (25% weight)",
    ["Combat : événements, ressources"] = "Combat: events and resources",
    ["Variété DataProbe (poids 5 %)"] = "DataProbe variety (5% weight)",
    ["Variété : sessions, niveaux, contenus (poids 10 %)"] =
        "Variety: sessions, levels, contents (10% weight)",
    ["Contributeurs distincts"] = "Distinct contributors",
    ["État du modèle"] = "Model status",
    ["Collectes encore utiles"] = "Still useful to collect",
    ["Le total mesure la complétion du profil, pas une précision garantie."] =
        "The total measures profile completeness, not guaranteed accuracy.",
    ["Aucune donnée communautaire publiée."] =
        "No community data published.",
    ["Guide publié"] = "Published guide",
    ["Mise à jour : "] = "Updated: ",
    ["profils guide publiés"] = "published guide profiles",
    ["fichier(s)"] = "file(s)",
    ["contributeur(s)"] = "contributor(s)",
    ["captures"] = "snapshots",
    ["infobulles uniques"] = "unique tooltips",
    ["événements"] = "events",
    ["échantillons de ressource"] = "resource samples",
    ["Contexte auto : "] = "Automatic content: ",
    ["donjon/raid"] = "dungeon/raid",
    ["monde"] = "world",
    ["provisoire"] = "provisional",
    ["Complétion du profil : guide publié + preuves DataProbe communautaires."] =
        "Profile completion: published guide + community DataProbe evidence.",
    ["Profil couvert : poursuivre la validation après les équilibrages."] =
        "Covered profile: continue validation after balance updates.",
    ["Guide : priorités PvE/PvP à compléter ou vérifier."] =
        "Guide: PvE/PvP priorities still need completion or verification.",
    ["Variété : répéter à plusieurs niveaux, sessions ou types de contenu."] =
        "Variety: repeat at multiple levels, sessions, or content types.",
    ["guide provisoire — aucune archive DataProbe communautaire"] =
        "provisional guide — no community DataProbe archive",
    ["build et équipement partiels — combats manquants"] =
        "partial build and gear — combat data missing",
    ["identité de spécialisation et combats manquants"] =
        "specialization identity and combat data missing",
    ["combat BG calibré — coefficients d'arme encore provisoires"] =
        "BG combat calibrated — weapon coefficients still provisional",
    ["combat BG calibré — niveaux 33 et 36"] =
        "BG combat calibrated — levels 33 and 36",
    ["exploratoire — combat probablement réalisé hors BG"] =
        "exploratory — combat probably recorded outside a BG",
    ["Spécialisation inconnue"] = "Unknown specialization",

    -- Additional composite UI text and guide priority vocabulary.
    ["Survole simplement un objet. "] = "Simply hover over an item. ",
    ["Les effets inconnus restent signalés."] =
        "Unknown effects remain flagged.",
    ["Les talents sont disponibles, mais les objets ne seront activés qu'après calibration fiable de cette spécialisation."] =
        "Talent advice is available, but item advice will only be enabled after reliable calibration for this specialization.",
    ["Ce profil sera disponible après analyse des données."] =
        "This profile will become available after data analysis.",
    ["Priorité : "] = "Priority: ",
    ["non publiée"] = "not published",
    ["Guide : "] = "Guide: ",
    ["% complet. Le reste doit être mesuré avec DataProbe."] =
        "% complete. The remainder must be measured with DataProbe.",
    [" Les boutons règlent ensuite l'objectif du score."] =
        " The buttons then set the scoring goal.",
    ["Coup critique"] = "Critical Strike",
    ["Soins"] = "Healing",
    ["Utilité"] = "Utility",
    ["Fiabilité de l’analyse"] = "Analysis confidence",
    ["Le choix #"] = "Choice #",
    ["  →  prochain : "] = "  →  next: ",
    ["Classe non détectée"] = "Class not detected",
    ["spécialisation non détectée"] = "specialization not detected",
    ["Classe inconnue"] = "Unknown class",
    ["Équip. "] = "Gear ",
    [" à vérifier"] = " to review",
    ["% prévu, plafond "] = "% predicted, cap ",
    ["% de bonus"] = "% bonus",
    ["% (mesuré par DataProbe)"] = "% (measured by DataProbe)",
    [" | niveau "] = " | level ",
    ["Profils : "] = "Profiles: ",
    ["Aucun talent accessible et évalué n'a été trouvé au niveau actuel."] =
        "No accessible evaluated talent was found at the current level.",
    ["Ouvre les arbres de talents de classe et de spécialisation, laisse-les visibles, puis relance l'analyse."] =
        "Open the class and specialization talent trees, leave them visible, then run the analysis again.",
    ["analyse locale automatique activée."] =
        "automatic local analysis enabled.",
    ["analyse locale automatique désactivée."] =
        "automatic local analysis disabled.",
    ["% des soins sont excédentaires : inutile de forcer les soins maximum."] =
        "% of healing is overhealing: no need to force maximum healing.",
    ["Toucher jusqu'au cap"] = "Hit up to cap",
    ["Toucher (cap)"] = "Hit (cap)",
    ["Expertise (cap)"] = "Expertise (cap)",
    ["Pénétration d'armure"] = "Armor Penetration",
    ["Défense"] = "Defense",
    ["Précision"] = "Accuracy",
    ["Blocage"] = "Block",
    ["Défense (cap)"] = "Defense (cap)",
    ["Esprit / MP5"] = "Spirit / MP5",
    ["Esquive"] = "Dodge",
    ["Parade"] = "Parry",
    ["Parade / Esquive"] = "Parry / Dodge",
    ["Coup critique / Hâte"] = "Critical Strike / Haste",
    ["Intelligence / Endurance"] = "Intellect / Stamina",
    ["Taux/Valeur de Bloc"] = "Block Rating/Value",
    ["Toucher / Expertise (caps)"] = "Hit / Expertise (caps)",
    ["Toucher des sorts (cap)"] = "Spell Hit (cap)",
    ["Vigueur"] = "Vigor",
    ["Cette classe"] = "This class",
    [" n'a pas encore de profil de recommandations. "] =
        " does not have a recommendation profile yet. ",
    ["Utilise l'onglet DataProbe pour aider à le construire."] =
        "Use the DataProbe tab to help build it.",
    ["talents non détectés"] = "talents not detected",
    ["Les recommandations de talents ne sont pas encore disponibles pour cette spécialisation."] =
        "Talent recommendations are not available for this specialization yet.",
    ["Le modèle de recommandations sera ajouté après analyse des sessions DataProbe."] =
        "The recommendation model will be added after DataProbe sessions are analyzed.",
    ["Aucune donnée détaillée destinée à la communauté n’est collectée avant "] =
        "No detailed community contribution data is collected before ",
    ["Talents non détectés : ouvre les arbres puis capture."] =
        "Talents not detected: open the trees, then capture.",
    [" avec DataProbe communautaire"] = " with community DataProbe",
    ["% de complétion moyenne"] = "% average completion",
    [". Mise à jour uniquement entre les versions."] =
        ". Updated only between addon versions.",
    ["DataProbe build (poids 20 %)"] = "DataProbe build (20% weight)",
    ["DataProbe équipement (poids 20 %)"] = "DataProbe gear (20% weight)",
    ["DataProbe combat PvP (poids 15 %)"] =
        "DataProbe PvP combat (15% weight)",
    ["DataProbe combat PvE (poids 15 %)"] =
        "DataProbe PvE combat (15% weight)",
    ["Le fichier révèle les talents, sorts, coefficients visibles, conversions de stats, objets scalés et emplacements. Il sert à construire le modèle et à éviter les erreurs de parsing. Sans combat, les recommandations fonctionnent mais leurs poids restent provisoires."] =
        "The file reveals talents, spells, visible coefficients, stat conversions, scaled items, and slots. It is used to build the model and prevent parsing errors. Without combat data, recommendations work but their weights remain provisional.",
    ["Les événements et ressources montrent la rotation réelle, les sorts dominants, le manque de mana/Focus, les critiques, ratés, déplacements et dégâts reçus. Ils calibrent la valeur de hâte, critique, sustain et survie pour BG ou donjon."] =
        "Events and resources show the real rotation, dominant spells, mana/Focus shortages, criticals, misses, movement, and incoming damage. They calibrate the value of haste, critical, sustain, and survival for BGs or dungeons.",
    ["Plusieurs niveaux, builds et types de contenu évitent de sur-optimiser un seul personnage."] =
        "Multiple levels, builds, and content types avoid over-optimizing for one character.",
    ["La progression communautaire fusionne manuellement les archives reçues et est publiée avec chaque nouvelle version."] =
        "Community progress manually merges received archives and is published with each new version.",

    -- Minimap and chat.
    ["Clic gauche : ouvrir l’assistant"] = "Left-click: open the assistant",
    ["Clic droit : analyser maintenant"] = "Right-click: analyze now",
    ["Glisser : déplacer le bouton"] = "Drag: move the button",
    ["Aucun profil de recommandation pour cette spécialisation."] =
        "No recommendation profile for this specialization.",
    ["Prochains talents conseillés :"] = "Suggested next talents:",
    ["analyse locale : "] = "local analysis: ",
    ["profil combat : "] = "combat profile: ",
    ["part des soins principaux "] = "main healing share ",
    ["combats avec peu de mana "] = "low-mana fights ",
    ["soins effectifs "] = "effective healing ",
    ["soins périodiques "] = "periodic healing ",
    ["profil sélectionné : "] = "profile selected: ",
    ["contexte sélectionné : "] = "content selected: ",
    ["conseils d'objets activés."] = "item advice enabled.",
    ["conseils d'objets désactivés."] = "item advice disabled.",
    ["observations de combat effacées."] = "combat observations cleared.",
    ["historique local de cette spécialisation effacé."] =
        "local history for this specialization cleared.",
    ["aucun changement de priorité conseillé actuellement."] =
        "no priority change currently suggested.",
    ["/coaa advisor - ouvrir l'interface guidée."] =
        "/coaa advisor - open the guided interface.",
    ["/coaa advisor scan - actualiser personnage, équipement et talents."] =
        "/coaa advisor scan - update character, gear, and talents.",
    ["/coaa advisor status - afficher les données du modèle actif."] =
        "/coaa advisor status - show active model data.",
    ["/coaa advisor talents - afficher les trois prochains talents."] =
        "/coaa advisor talents - show the next three talents.",
    ["/coaa advisor combat - afficher la calibration de combat."] =
        "/coaa advisor combat - show combat calibration.",
    ["/coaa advisor profile NOM - changer la priorité."] =
        "/coaa advisor profile NAME - change priority.",
    ["/coaa advisor content pvp|pve - changer le type de contenu."] =
        "/coaa advisor content pvp|pve - change content type.",
    ["/coaa advisor on|off - activer ou désactiver les tooltips."] =
        "/coaa advisor on|off - enable or disable tooltips.",
    ["/coaa advisor probe - ouvrir l'onglet DataProbe."] =
        "/coaa advisor probe - open the DataProbe tab.",
    ["/coaa advisor language fr|en - changer la langue de l'interface."] =
        "/coaa advisor language fr|en - change the interface language.",
    ["DataProbe est OFF : aucune donnée collectée."] =
        "DataProbe is OFF: no data is being collected.",
    ["DataProbe est désactivé : aucune donnée collectée."] =
        "DataProbe is disabled: no data is being collected.",
    ["Archive DataProbe indisponible."] = "DataProbe archive unavailable.",
    ["DataProbe : aucune archive accessible à exporter."] =
        "DataProbe: no archive available to export.",
    ["DataProbe : toutes les archives ont été effacées."] =
        "DataProbe: all archives were cleared.",
    ["DataProbe : capture #"] = "DataProbe: snapshot #",
    [" enregistrée, "] = " saved, ",
    ["DataProbe activé : collecte locale démarrée. Aucune donnée n'est envoyée automatiquement."] =
        "DataProbe enabled: local collection started. No data is sent automatically.",
    ["DataProbe désactivé : événements et échantillonnage arrêtés."] =
        "DataProbe disabled: event collection and sampling stopped.",
    ["DataProbe : collecte terminée et export préparé. Le scanner est maintenant désactivé."] =
        "DataProbe: collection complete and export prepared. The scanner is now disabled.",
    ["impossible de charger DataProbe. Vérifie que le dossier "] =
        "unable to load DataProbe. Make sure the folder ",
    [" est installé et activé. "] = " is installed and enabled. ",
    ["DataProbe : aucun talent détecté. Ouvre l'arbre de classe et de spécialisation, puis capture à nouveau."] =
        "DataProbe: no talents detected. Open the class and specialization trees, then capture again.",
    ["DataProbe : autre build ajouté au même fichier final. Les scans déjà collectés sont conservés."] =
        "DataProbe: another build was added to the same final file. Previously collected scans are kept.",
    ["analyse terminée pour "] = "analysis complete for ",
    ["sélectionnés, "] = "selected, ",
    ["contenu dominant "] = "dominant content ",
    ["aucun profil pour cette spécialisation. DataProbe reste disponible pour aider à en construire un."] =
        "no profile for this specialization. DataProbe remains available to help build one.",
    ["Amélioration équilibrée pour Mythic+ : soins et autonomie progressent."] =
        "Balanced Mythic+ upgrade: both healing and sustain improve.",
    ["Meilleur débit de soins, avec une autonomie mana en baisse."] =
        "Higher healing throughput, with lower mana sustain.",
    ["Ce petit gain sacrifie une priorité détectée dans tes combats."] =
        "This small gain sacrifices a priority detected in your fights.",
    ["L'objectif principal progresse sans sacrifice important."] =
        "The primary goal improves without a significant sacrifice.",
    ["À envisager pour la progression : meilleure sécurité, mais rendement global inférieur."] =
        "Consider for progression: better safety, but lower overall performance.",
    ["Priorité Mythic Coins"] = "Mythic Coin priority",
    ["TRÈS HAUTE"] = "VERY HIGH",
    ["HAUTE"] = "HIGH",
    ["FAIBLE"] = "LOW",
    ["Pièce durable Time : Esprit, puissance des sorts et critique/hâte, sans statistique gaspillée."] =
        "Durable Time item: Spirit, Spell Power and Crit/Haste, with no wasted stat.",
    ["Déjà fortement amélioré : réserve d'abord les pièces aux objets parfaits de rang inférieur."] =
        "Already heavily upgraded: spend first on lower-rank items with perfect stats.",
    ["Très bonnes statistiques Time sans toucher ni pénétration inutiles."] =
        "Very strong Time stats without wasted Hit or Penetration.",
    ["Bonne base Time, mais vérifie qu'elle restera longtemps équipée."] =
        "Good Time base item, but make sure you will keep it for a long time.",
    ["Évite d'investir des pièces Mythic : une partie du budget est gaspillée pour Time."] =
        "Avoid spending Mythic Coins: part of the stat budget is wasted for Time.",
    ["Objet spécialisé : améliore-le seulement si tu comptes le conserver."] =
        "Specialized item: upgrade it only if you plan to keep it.",
    ["Puissance des sorts moyenne (activation)"] =
        "Average Spell Power (on-use)",
    ["Activation reconnue : +"] = "Recognized on-use: +",
    [" puissance des sorts pendant "] = " Spell Power for ",
    [" s, soit ~+"] = " sec, averaging ~+",
    [" en moyenne si utilisée à chaque recharge."] =
        " when used on cooldown.",

    -- Dynamic labels and sentence fragments that are assembled at runtime.
    ["Renforce Roll Back avec une dissipation supplémentaire, utile dans le chemin Mythic+ vérifié."] =
        "Improves Roll Back with an additional dispel, useful in the verified Mythic+ path.",
    ["Les Aeons accumulent un puissant bonus de dégâts et de soins."] =
        "Aeons build up a powerful damage and healing bonus.",
    ["Fortify Timeline prolonge davantage Accelerated Recovery sur le groupe."] =
        "Fortify Timeline extends Accelerated Recovery on the group even further.",
    ["Adapte Ripple à l'Aeon actif pour les soins, absorptions ou dégâts de zone."] =
        "Adapts Ripple to the active Aeon for healing, absorbs, or area damage.",
    ["Double repoussement frontal utile pour contrôler les groupes en Mythic+."] =
        "A double frontal knockback useful for controlling groups in Mythic+.",
    ["Réduit fortement la durée des maladies, un choix utilitaire du build Mythic+ vérifié."] =
        "Greatly reduces disease duration, a utility choice in the verified Mythic+ build.",
    ["Réduit le temps de recharge des Aeons et fluidifie les changements de posture."] =
        "Reduces Aeon cooldowns and smooths stance changes.",
    ["Les soins périodiques réduisent le temps de recharge de Fortify Timeline."] =
        "Periodic healing reduces Fortify Timeline's cooldown.",
    ["PvE : Toucher jusqu'au cap d'une cible +3 > Agilité > Critique > Pénétration > Hâte."] =
        "PvE: Hit to the cap against a +3 target > Agility > Critical Strike > Penetration > Haste.",
    ["priorité non publiée — DataProbe requis"] =
        "priority not published — DataProbe required",
    ["tu veux améliorer la ressource et le rythme"] =
        "you want to improve resource management and tempo",
    ["% des combats se terminent mort : privilégie la survie."] =
        "% of fights end in death: prioritize survival.",
    ["% des combats finissent sous 20 % de mana : privilégie mana et régénération."] =
        "% of fights end below 20% mana: prioritize mana and regeneration.",
    ["% de morts et forte pression de vie : privilégie la mitigation."] =
        "% deaths with heavy health pressure: prioritize mitigation.",
    ["% des combats se terminent mort : privilégie survie et contrôle."] =
        "% of fights end in death: prioritize survival and control.",
    [". Les objets et talents sont recalculés."] =
        ". Gear and talents are recalculated.",
    ["élevée"] = "high",
    ["Dégâts"] = "Damage",
    ["Classe"] = "Class",
    ["Spécialisation"] = "Specialization",
    ["spécialisation"] = "specialization",
    [" avec CoA Analytics"] = " with CoA Analytics",
    [" sélectionnés"] = " selected",
}

local replacements
local replacementBuckets
local localizedCache = {}
local localizedCacheCount = 0

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
    replacementBuckets = {}
    for index = 1, #replacements do
        local prefix = replacements[index][1]:sub(1, 3)
        local bucket = replacementBuckets[prefix]
        if not bucket then
            bucket = {}
            replacementBuckets[prefix] = bucket
        end
        bucket[#bucket + 1] = index
    end
end

function Advisor.GetLanguage()
    local db = _G.CoAAnalyticsDB
    if type(db) == "table" and db.language == "fr" then return "fr" end
    return "en"
end

function Advisor.LocalizeText(value)
    if value == nil then return "" end
    local text = tostring(value)
    if Advisor.GetLanguage() ~= "en" then return FRENCH[text] or text end
    local cached = localizedCache[text]
    if cached ~= nil then return cached end
    local direct = ENGLISH[text]
    if direct then
        if localizedCacheCount < 2000 then
            localizedCache[text] = direct
            localizedCacheCount = localizedCacheCount + 1
        end
        return direct
    end
    if not replacements then BuildReplacements() end
    local candidates = {}
    for position = 1, math.max(1, #text - 2) do
        local bucket = replacementBuckets[text:sub(position, position + 2)]
        if bucket then
            for bucketIndex = 1, #bucket do
                candidates[bucket[bucketIndex]] = true
            end
        end
    end
    for index = 1, #replacements do
        if candidates[index] then
            local pair = replacements[index]
            text = text:gsub(EscapePattern(pair[1]), function()
                return pair[2]
            end)
        end
    end
    if localizedCacheCount < 2000 then
        localizedCache[tostring(value)] = text
        localizedCacheCount = localizedCacheCount + 1
    end
    return text
end

function Advisor.SetLanguage(language, reloadUI)
    language = tostring(language or ""):lower()
    if language ~= "fr" and language ~= "en" then return false end
    if type(_G.CoAAnalyticsDB) ~= "table" then
        _G.CoAAnalyticsDB = {}
    end
    _G.CoAAnalyticsDB.language = language
    if type(_G.CoAAnalyticsAdvisorDB) == "table" then
        _G.CoAAnalyticsAdvisorDB.language = language
    end
    if reloadUI and type(ReloadUI) == "function" then ReloadUI() end
    return true
end
