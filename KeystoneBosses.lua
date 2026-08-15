local API = CoAAnalyticsAPI
local Module = {}
CoAAnalyticsAddon.Modules.KeystoneBosses = Module

-- Cette table est la copie chargeable par le client du CSV livre avec l'addon.
-- Les noms propres restent en anglais, comme dans le client Ascension.
local DUNGEONS = {
	{
		dungeon = "Ragefire Chasm", boss = "Taragaman the Hungerer",
		aliases = { "Ragefire Chasm", "Gouffre de Ragefeu" },
		hintFr = "Suivez la route principale jusqu'a la grande salle de lave au fond du gouffre.",
		hintEn = "Follow the main route to the large lava chamber deep inside the chasm.",
	},
	{
		dungeon = "Wailing Caverns", boss = "Mutanus the Devourer",
		aliases = { "Wailing Caverns", "Cavernes des lamentations" },
		hintFr = "Tuez les quatre Seigneurs du Croc, puis terminez l'escorte du Disciple de Naralex; Mutanus est la derniere embuscade.",
		hintEn = "Kill the four Fanglords, then finish the Disciple of Naralex escort; Mutanus is the final ambush.",
		routeNoteFr = "Route historique du donjon; confirmation publique CoA encore indisponible.",
		routeNoteEn = "Legacy dungeon route; public CoA confirmation is not available yet.",
		routeFr = {
			"Lady Anacondra", "Lord Cobrahn", "Lord Pythas",
			"Lord Serpentis", "Escorte du Disciple de Naralex",
			"Mutanus the Devourer",
		},
		routeEn = {
			"Lady Anacondra", "Lord Cobrahn", "Lord Pythas",
			"Lord Serpentis", "Disciple of Naralex escort",
			"Mutanus the Devourer",
		},
	},
	{
		dungeon = "The Deadmines", boss = "Edwin VanCleef",
		aliases = { "The Deadmines", "Deadmines", "Les Mortemines", "Mortemines" },
		hintFr = "Au bout de la route principale, sur le pont superieur du navire dans la caverne.",
		hintEn = "At the end of the main route, on the upper deck of the ship in the cavern.",
	},
	{
		dungeon = "Shadowfang Keep", boss = "Archmage Arugal",
		aliases = { "Shadowfang Keep", "Donjon d'Ombrecroc" },
		hintFr = "Tout en haut de la derniere tour du chateau, apres la cour et les remparts.",
		hintEn = "At the top of the keep's final tower, beyond the courtyard and ramparts.",
	},
	{
		dungeon = "The Stockade", boss = "Bazil Thredd",
		aliases = { "The Stockade", "The Stockades", "Stormwind Stockade", "Stormwind Stockades", "La Prison", "Prison de Hurlevent" },
		hintFr = "Dans le bloc de cellules du fond; suivez le couloir principal jusqu'a la section de haute securite.",
		hintEn = "In the rear cell block; follow the main corridor to the high-security section.",
	},
	{
		dungeon = "Blackfathom Deeps", boss = "Aku'mai",
		aliases = { "Blackfathom Deeps", "Profondeurs de Brassenoire" },
		hintFr = "Dans la derniere caverne du sanctuaire, au-dela des ruines et de l'autel d'Aku'mai.",
		hintEn = "In the shrine's final cavern, beyond the ruins and Aku'mai's altar.",
		routeNoteFr = "Route historique du donjon; confirmation publique CoA encore indisponible.",
		routeNoteEn = "Legacy dungeon route; public CoA confirmation is not available yet.",
		routeFr = {
			"Twilight Lord Kelris", "Allumer les quatre flammes",
			"Vaincre les vagues de l'evenement", "Aku'mai",
		},
		routeEn = {
			"Twilight Lord Kelris", "Light all four flames",
			"Defeat the event waves", "Aku'mai",
		},
	},
	{
		dungeon = "Gnomeregan", boss = "Mekgineer Thermaplugg",
		aliases = { "Gnomeregan" },
		hintFr = "Descendez jusqu'aux laboratoires d'ingenierie; il attend dans la grande salle de lancement finale.",
		hintEn = "Descend through the engineering labs; he waits in the large final launch bay.",
	},
	{
		dungeon = "Razorfen Kraul", boss = "Charlga Razorflank",
		aliases = { "Razorfen Kraul", "Kraal de Tranchebauge" },
		hintFr = "Au sommet du dernier tertre d'epines, tout au fond de la route superieure.",
		hintEn = "Atop the final thorn mound, at the far end of the upper route.",
	},
	{
		dungeon = "Scarlet Graveyard", boss = "Bloodmage Thalnos",
		aliases = { "Scarlet Graveyard", "Scarlet Monastery - Graveyard", "Graveyard", "Monastere ecarlate - Cimetiere" },
		hintFr = "Dans la crypte principale au fond de l'aile Cimetiere.",
		hintEn = "Inside the main crypt at the back of the Graveyard wing.",
	},
	{
		dungeon = "Scarlet Library", boss = "Arcanist Doan",
		aliases = { "Scarlet Library", "Scarlet Monastery - Library", "The Library", "Monastere ecarlate - Bibliotheque" },
		hintFr = "Dans la derniere salle de l'aile Bibliotheque, derriere les longues galeries de livres.",
		hintEn = "In the last room of the Library wing, beyond the long book galleries.",
	},
	{
		dungeon = "Scarlet Armory", boss = "Herod",
		aliases = { "Scarlet Armory", "Scarlet Monastery - Armory", "The Armory", "Monastere ecarlate - Armurerie" },
		hintFr = "Dans la grande salle d'entrainement au bout de l'aile Armurerie.",
		hintEn = "In the large training hall at the end of the Armory wing.",
	},
	{
		dungeon = "Scarlet Cathedral", boss = "High Inquisitor Whitemane",
		aliases = { "Scarlet Cathedral", "Scarlet Monastery - Cathedral", "The Cathedral", "Monastere ecarlate - Cathedrale" },
		hintFr = "Dans la chapelle finale. Tuez Mograine pour faire apparaitre Whitemane, puis terminez leur combat combine.",
		hintEn = "In the final chapel. Defeat Mograine to make Whitemane appear, then finish their combined encounter.",
		routeNoteFr = "Route historique du donjon; confirmation publique CoA encore indisponible.",
		routeNoteEn = "Legacy dungeon route; public CoA confirmation is not available yet.",
		routeFr = {
			"Scarlet Commander Mograine", "High Inquisitor Whitemane",
			"Mograine ressuscite + Whitemane",
		},
		routeEn = {
			"Scarlet Commander Mograine", "High Inquisitor Whitemane",
			"Resurrected Mograine + Whitemane",
		},
	},
	{
		dungeon = "Razorfen Downs", boss = "Amnennar the Coldbringer",
		aliases = { "Razorfen Downs", "Souilles de Tranchebauge" },
		hintFr = "Au sommet de la spirale d'epines, dans la derniere zone du donjon.",
		hintEn = "At the top of the thorn spiral in the dungeon's final area.",
	},
	{
		dungeon = "Uldaman", boss = "Archaedas",
		aliases = { "Uldaman" },
		hintFr = "Dans le Hall des Gardiens, tout au fond du complexe des Titans; activez l'autel pour l'eveiller.",
		hintEn = "In the Hall of the Keepers at the far end of the titan complex; use the altar to awaken him.",
	},
	{
		dungeon = "Zul'Farrak", boss = "Chief Ukorz Sandscalp",
		aliases = { "Zul'Farrak", "Zul Farrak" },
		hintFr = "Dans le temple d'Ukorz au fond de Zul'Farrak, au-dela de la zone de la pyramide.",
		hintEn = "In Ukorz's temple at the back of Zul'Farrak, beyond the pyramid area.",
	},
	{
		dungeon = "Maraudon - Purple / Wicked Grotto", boss = "Lord Vyletongue",
		aliases = { "Maraudon - Purple", "Maraudon Purple", "Wicked Grotto", "The Wicked Grotto" },
		hintFr = "Prenez l'entree aux cristaux violets et suivez la Grotte Maudite jusqu'a sa derniere salle.",
		hintEn = "Take the purple-crystal entrance and follow the Wicked Grotto to its final room.",
	},
	{
		dungeon = "Maraudon - Orange / Foulspore Cavern", boss = "Razorlash",
		aliases = { "Maraudon - Orange", "Maraudon Orange", "Foulspore Cavern", "The Foulspore Cavern" },
		hintFr = "Prenez l'entree aux cristaux orange et suivez la Caverne Vilespore jusqu'a Razorlash.",
		hintEn = "Take the orange-crystal entrance and follow Foulspore Cavern to Razorlash.",
	},
	{
		dungeon = "Maraudon - Inner / Earth Song Falls", boss = "Princess Theradras",
		aliases = { "Maraudon - Inner", "Inner Maraudon", "Earth Song Falls", "Zaetar's Grave" },
		hintFr = "Dans la Tombe de Zaetar, au plus profond de Maraudon, au-dela des chutes.",
		hintEn = "In Zaetar's Grave, deep inside Maraudon beyond the falls.",
	},
	{
		dungeon = "Sunken Temple / Temple of Atal'Hakkar", boss = "Shade of Eranikus",
		aliases = { "Sunken Temple", "The Sunken Temple", "Temple of Atal'Hakkar", "Temple of Atal Hakkar", "Temple englouti", "Temple d'Atal'Hakkar" },
		hintFr = "Dans la grande chambre inferieure centrale, apres avoir ouvert la voie dans le temple.",
		hintEn = "In the large lower central chamber after opening the route through the temple.",
		routeNoteFr = "Route historique du donjon; confirmation publique CoA encore indisponible.",
		routeNoteEn = "Legacy dungeon route; public CoA confirmation is not available yet.",
		routeFr = {
			"Gasher", "Hukku", "Loro", "Mijan", "Zolo", "Zul'Lor",
			"Jammal'an the Prophet + Ogom the Wretched",
			"Shade of Eranikus",
		},
		routeEn = {
			"Gasher", "Hukku", "Loro", "Mijan", "Zolo", "Zul'Lor",
			"Jammal'an the Prophet + Ogom the Wretched",
			"Shade of Eranikus",
		},
	},
	{
		dungeon = "Blackrock Depths", boss = "Emperor Dagran Thaurissan",
		aliases = { "Blackrock Depths", "Profondeurs de Rochenoire" },
		hintFr = "Sur le Trone imperial, tout au fond de la cite, apres Magmus.",
		hintEn = "At the Imperial Seat, at the far end of the city beyond Magmus.",
	},
	{
		dungeon = "Lower Blackrock Spire", boss = "Overlord Wyrmthalak",
		aliases = { "Lower Blackrock Spire", "Blackrock Spire - Lower", "LBRS", "Pic Rochenoire inferieur" },
		hintFr = "Dans la derniere chambre de la ville d'Hordemar, au bout de la route basse.",
		hintEn = "In Hordemar City's final chamber, at the end of the lower route.",
	},
	{
		dungeon = "Upper Blackrock Spire", boss = "General Drakkisath",
		aliases = { "Upper Blackrock Spire", "Blackrock Spire - Upper", "UBRS", "Pic Rochenoire superieur" },
		hintFr = "Dans les Halls de l'Ascension, derniere salle au-dela de la Bete.",
		hintEn = "In the Halls of Ascension, in the final room beyond The Beast.",
	},
	{
		dungeon = "Dire Maul East", boss = "Alzzin the Wildshaper",
		aliases = { "Dire Maul East", "Dire Maul - East", "Warpwood Quarter", "Hache Tripes Est" },
		hintFr = "Au niveau inferieur du Quartier Crochebois, dans la derniere salle de l'aile Est.",
		hintEn = "On the lower level of the Warpwood Quarter, in the East wing's final room.",
	},
	{
		dungeon = "Dire Maul North", boss = "King Gordok",
		aliases = { "Dire Maul North", "Dire Maul - North", "Gordok Commons", "Hache Tripes Nord" },
		hintFr = "Au Siege des Gordok, au bout de l'aile Nord, apres le capitaine Kromcrush.",
		hintEn = "At Gordok's Seat at the end of the North wing, beyond Captain Kromcrush.",
	},
	{
		dungeon = "Dire Maul West", boss = "Prince Tortheldrin",
		aliases = { "Dire Maul West", "Dire Maul - West", "Capital Gardens", "Hache Tripes Ouest" },
		hintFr = "Dans l'Athenaeum. Desactivez les pylones et battez Immol'thar pour ouvrir la route.",
		hintEn = "In the Athenaeum. Disable the pylons and defeat Immol'thar to open the route.",
		routeNoteFr = "Boss requis confirmes par Ascension DB, quete Mythic #81085.",
		routeNoteEn = "Required bosses confirmed by Ascension DB Mythic quest #81085.",
		routeFr = {
			"Tendris Warpwood", "Desactiver les cinq pylones",
			"Immol'thar", "Prince Tortheldrin",
		},
		routeEn = {
			"Tendris Warpwood", "Disable all five pylons",
			"Immol'thar", "Prince Tortheldrin",
		},
	},
	{
		dungeon = "Scholomance", boss = "Darkmaster Gandling",
		aliases = { "Scholomance" },
		hintFr = "Dans le Bureau du Directeur, au terme de Lower Scholomance.",
		hintEn = "In the Headmaster's Study, at the end of Lower Scholomance.",
		routeNoteFr = "CoA confirme uniquement Gandling (Ascension DB #81079); aucun ordre de prerequis n'est publie.",
		routeNoteEn = "CoA confirms Gandling only (Ascension DB #81079); no prerequisite order is published.",
		routeFr = {
			"Darkmaster Gandling",
		},
		routeEn = {
			"Darkmaster Gandling",
		},
	},
	{
		dungeon = "Stratholme - Main Gate", boss = "Balnazzar",
		aliases = { "Stratholme - Main Gate", "Stratholme Main Gate", "Stratholme - Live", "Crusaders' Square", "Scarlet Bastion", "Stratholme - Grande porte" },
		hintFr = "Dans la derniere salle du Bastion ecarlate, au fond de la route de la Porte principale.",
		hintEn = "In the Scarlet Bastion's final hall, at the end of the Main Gate route.",
		routeNoteFr = "Boss requis confirmes par Ascension DB, quete Mythic #81077.",
		routeNoteEn = "Required bosses confirmed by Ascension DB Mythic quest #81077.",
		routeFr = {
			"Timmy the Cruel", "Cannon Master Willey",
			"Archivist Galford", "Balnazzar",
		},
		routeEn = {
			"Timmy the Cruel", "Cannon Master Willey",
			"Archivist Galford", "Balnazzar",
		},
	},
	{
		dungeon = "Stratholme - Service Entrance", boss = "Baron Rivendare",
		aliases = { "Stratholme - Service Entrance", "Stratholme Service Entrance", "Stratholme - Undead", "The Gauntlet", "Slaughter Square", "Stratholme - Entree de service" },
		hintFr = "Dans le Square du Massacre, au terme de la route Entree de service.",
		hintEn = "In Slaughter Square, at the end of the Service Entrance route.",
		routeNoteFr = "CoA confirme uniquement Rivendare (Ascension DB #81078); aucun ordre de prerequis n'est publie.",
		routeNoteEn = "CoA confirms Rivendare only (Ascension DB #81078); no prerequisite order is published.",
		routeFr = {
			"Baron Rivendare",
		},
		routeEn = {
			"Baron Rivendare",
		},
	},
	{
		dungeon = "Blackrock Caverns", boss = "Ascendant Lord Obsidius",
		aliases = { "Blackrock Caverns", "Cavernes de Rochenoire" },
		hintFr = "A l'Ascension de l'Ascendant, dans la derniere caverne apres Beauty.",
		hintEn = "At Ascendant's Rise, in the final cavern beyond Beauty.",
	},
}

local current
local initialized = false
local lastAnnouncedSignature
local mythicPlusRun = false
local aliasLookup = {}

local function IsEnabled()
	local addonDB = API and API.GetDatabase and API.GetDatabase()
	return not addonDB or addonDB.enableKeystoneBossFeature ~= false
end

local function Normalize(value)
	value = tostring(value or "")
	value = value:gsub("(%l)(%u)", "%1 %2")
	value = string.lower(value)
	value = value:gsub("\195\160", "a"):gsub("\195\162", "a"):gsub("\195\164", "a")
	value = value:gsub("\195\167", "c")
	value = value:gsub("\195\168", "e"):gsub("\195\169", "e")
		:gsub("\195\170", "e"):gsub("\195\171", "e")
	value = value:gsub("\195\174", "i"):gsub("\195\175", "i")
	value = value:gsub("\195\180", "o"):gsub("\195\182", "o")
	value = value:gsub("\195\185", "u"):gsub("\195\187", "u"):gsub("\195\188", "u")
	value = value:gsub("[^%w]+", " ")
	return value:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
end

for index = 1, #DUNGEONS do
	local entry = DUNGEONS[index]
	entry.index = index
	aliasLookup[Normalize(entry.dungeon)] = entry
	for aliasIndex = 1, #(entry.aliases or {}) do
		aliasLookup[Normalize(entry.aliases[aliasIndex])] = entry
	end
end

local function AddCandidate(candidates, value)
	local normalized = Normalize(value)
	if normalized ~= "" then
		candidates[#candidates + 1] = normalized
	end
end

local function GetLFGDungeonName()
	if type(GetPartyLFGID) ~= "function" or type(GetLFGDungeonInfo) ~= "function" then
		return
	end
	local ok, dungeonID = pcall(GetPartyLFGID)
	if (not ok or not dungeonID) and _G.LE_LFG_CATEGORY_LFD then
		ok, dungeonID = pcall(GetPartyLFGID, _G.LE_LFG_CATEGORY_LFD)
	end
	if not ok or not dungeonID then
		return
	end
	local okInfo, dungeonName = pcall(GetLFGDungeonInfo, dungeonID)
	if okInfo and type(dungeonName) == "string" then
		return dungeonName
	end
end

local function IsKeystoneActive()
	if type(C_MythicPlus) ~= "table"
		or type(C_MythicPlus.IsKeystoneActive) ~= "function"
	then
		return false
	end
	local ok, active = pcall(C_MythicPlus.IsKeystoneActive)
	return ok and active and true or false
end

local function IsMythicZero(instanceType, difficultyID, difficultyName)
	if instanceType ~= "party" then
		return false
	end
	if mythicPlusRun or IsKeystoneActive() then
		return false
	end
	local normalizedDifficulty = Normalize(difficultyName)
	return tonumber(difficultyID) == 3
		or normalizedDifficulty == "mythic"
		or normalizedDifficulty == "mythic 0"
		or normalizedDifficulty == "mythic zero"
end

local function FindDungeon(candidates)
	for index = 1, #candidates do
		local exact = aliasLookup[candidates[index]]
		if exact then
			return exact
		end
	end

	local best, bestLength
	for alias, entry in pairs(aliasLookup) do
		if #alias >= 7 then
			for index = 1, #candidates do
				if candidates[index]:find(alias, 1, true)
					and (not bestLength or #alias > bestLength)
				then
					best = entry
					bestLength = #alias
				end
			end
		end
	end
	return best
end

local function BuildCurrentInfo()
	if not IsEnabled() then
		return
	end
	local inInstance, instanceType = IsInInstance()
	if not inInstance or instanceType ~= "party" then
		return
	end
	local instanceName, returnedType, difficultyID, difficultyName = GetInstanceInfo()
	instanceType = returnedType or instanceType
	if not IsMythicZero(instanceType, difficultyID, difficultyName) then
		return
	end

	local candidates = {}
	AddCandidate(candidates, GetLFGDungeonName())
	AddCandidate(candidates, instanceName)
	if type(GetRealZoneText) == "function" then
		AddCandidate(candidates, GetRealZoneText())
	end
	if type(GetSubZoneText) == "function" then
		AddCandidate(candidates, GetSubZoneText())
	end
	if type(GetMapInfo) == "function" then
		local ok, mapName = pcall(GetMapInfo)
		if ok then
			AddCandidate(candidates, mapName)
		end
	end

	local entry = FindDungeon(candidates)
	if not entry then
		return {
			unknown = true,
			dungeon = instanceName or "Instance inconnue",
			boss = API.GetLanguage() == "en" and "Unknown boss" or "Boss inconnu",
			hint = API.GetLanguage() == "en"
				and "This Mythic 0 dungeon is not identified in the local list."
				or "Ce donjon Mythic 0 n'est pas identifie dans la liste locale.",
			hintEn = "This Mythic 0 dungeon is not identified in the local list.",
			difficultyID = difficultyID,
			difficultyName = difficultyName,
		}
	end

	return {
		dungeon = entry.dungeon,
		boss = entry.boss,
		bossAliases = entry.bossAliases,
		hint = API.GetLanguage() == "en" and entry.hintEn or entry.hintFr,
		hintEn = entry.hintEn,
		route = API.GetLanguage() == "en" and entry.routeEn or entry.routeFr,
		routeFr = entry.routeFr,
		routeEn = entry.routeEn,
		routeNote = API.GetLanguage() == "en"
			and entry.routeNoteEn or entry.routeNoteFr,
		routeNoteFr = entry.routeNoteFr,
		routeNoteEn = entry.routeNoteEn,
		difficultyID = difficultyID,
		difficultyName = difficultyName,
		index = entry.index,
	}
end

local function Notify(message)
	local chatFrame = DEFAULT_CHAT_FRAME or ChatFrame1
	if chatFrame then
		chatFrame:AddMessage(
			"|cff12c98aCoA Analytics:|r "
				.. API.LocalizeText(tostring(message or ""))
		)
	end
end

local function AnnounceIfNeeded(info)
	if not info then
		lastAnnouncedSignature = nil
		return
	end
	local signature = Normalize(info.dungeon) .. ":" .. Normalize(info.boss)
	if signature == lastAnnouncedSignature then
		return
	end
	lastAnnouncedSignature = signature
	Notify("|cffffd100Keystone Boss:|r |cffffffff" .. tostring(info.boss) .. "|r")
	Notify("|cffb8c0cc" .. tostring(info.hint) .. "|r")
end

function Module.Refresh()
	local previousBoss = current and current.boss
	local previousDungeon = current and current.dungeon
	current = BuildCurrentInfo()
	AnnounceIfNeeded(current)
	if previousBoss ~= (current and current.boss)
		or previousDungeon ~= (current and current.dungeon)
	then
		CoAAnalyticsAddon.Events:Fire("KEYSTONE_BOSS_UPDATED", current)
	end
	return current
end

function Module.GetCurrent()
	if not IsEnabled() or mythicPlusRun or IsKeystoneActive() then
		return nil
	end
	return current
end

function Module.GetDungeons()
	return DUNGEONS
end

function Module.IsEnabled()
	return IsEnabled()
end

function Module.ApplySettings()
	return Module.Refresh()
end

local function GetShareChannel()
	if GetNumRaidMembers and GetNumRaidMembers() > 0 then
		return "RAID"
	elseif GetNumPartyMembers and GetNumPartyMembers() > 0 then
		return "PARTY"
	end
end

function Module.ShareCurrent()
	if not IsEnabled() or mythicPlusRun or IsKeystoneActive() then
		return false
	end
	local info = current or Module.Refresh()
	if not info or info.unknown then
		Notify(API.LocalizeText("aucun boss de Keystone a partager"))
		return false
	end
	-- Party and raid chat must remain understandable regardless of the
	-- language selected for the local addon UI.
	local message = "Keystone Boss: " .. tostring(info.boss)
		.. " - " .. tostring(info.hintEn or info.hint)
	local channel = GetShareChannel()
	if channel and type(SendChatMessage) == "function" then
		SendChatMessage(message, channel)
	else
		Notify(message)
	end
	return true
end

local function TargetMatchesBoss(info)
	if not UnitExists("target") then
		return false
	end
	local targetName = Normalize(UnitName("target"))
	if targetName == Normalize(info.boss) then
		return true
	end
	for index = 1, #(info.bossAliases or {}) do
		if targetName == Normalize(info.bossAliases[index]) then
			return true
		end
	end
	return false
end

function Module.LocateCurrent()
	if not IsEnabled() or mythicPlusRun or IsKeystoneActive() then
		return false
	end
	local info = current or Module.Refresh()
	if not info or info.unknown then
		Notify(info and info.hint or API.LocalizeText("aucun boss de Keystone dans ce donjon"))
		return false
	end

	if type(TargetByName) == "function" then
		pcall(TargetByName, info.boss, true)
	end
	if TargetMatchesBoss(info) then
		if type(GetRaidTargetIndex) == "function"
			and type(SetRaidTarget) == "function"
			and not GetRaidTargetIndex("target")
		then
			pcall(SetRaidTarget, "target", 8)
		end
		Notify("|cffffd100" .. tostring(info.boss) .. "|r "
			.. API.LocalizeText("est cible et marque s'il est a portee"))
		return true
	end

	Notify("|cffffd100" .. tostring(info.boss) .. ":|r " .. tostring(info.hint))
	Notify(API.LocalizeText("Le client ne fournit pas de coordonnees fiables dans ce donjon; le bouton ciblera le boss des qu'il sera charge a proximite."))
	return false
end

local function ScheduleRefresh()
	if not initialized then
		return
	end
	Module.Refresh()
	if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
		C_Timer.After(1, Module.Refresh)
	end
end

function Module.Initialize()
	if initialized then
		return true
	end
	initialized = true
	ScheduleRefresh()
	return true
end

local eventFrame = CreateFrame("Frame")
local function RegisterOptionalEvent(eventName)
	pcall(eventFrame.RegisterEvent, eventFrame, eventName)
end

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("LFG_UPDATE")
RegisterOptionalEvent("MYTHIC_PLUS_COUNTDOWN_STARTED")
RegisterOptionalEvent("MYTHIC_PLUS_STARTED")
RegisterOptionalEvent("MYTHIC_PLUS_COMPLETE")
RegisterOptionalEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:SetScript("OnEvent", function(_, eventName)
	if eventName == "MYTHIC_PLUS_COUNTDOWN_STARTED"
		or eventName == "MYTHIC_PLUS_STARTED"
		or eventName == "MYTHIC_PLUS_COMPLETE"
		or eventName == "CHALLENGE_MODE_COMPLETED"
	then
		-- Difficulty ID 3 is shared by M0 and M+ on this client. Once a
		-- Keystone countdown begins, keep the helper suppressed until the
		-- player leaves or reloads the instance, even if the active-key API
		-- briefly reports false during a transition.
		mythicPlusRun = true
		Module.Refresh()
		return
	end

	if eventName == "PLAYER_ENTERING_WORLD"
		or eventName == "ZONE_CHANGED_NEW_AREA"
	then
		local inInstance, instanceType = IsInInstance()
		mythicPlusRun = inInstance and instanceType == "party"
			and IsKeystoneActive() or false
	end
	ScheduleRefresh()
end)
