local API = CoAAnalyticsAPI
local RaidMinimap = {}
CoAAnalyticsAddon.Modules.RaidMinimap = RaidMinimap

local UPDATE_INTERVAL = 0.12
local MAP_REFRESH_INTERVAL = 2
local POSITION_GRACE_SECONDS = 1.5
local SETTINGS_SCHEMA_VERSION = 1
local FALLBACK_MAP_WIDTH = 1500
local FLAG_MARKER_SIZE = 24
local MARKER_TEXTURE =
	"Interface\\AddOns\\CoAAnalytics\\Textures\\raid_minimap_circle.tga"
local FLAG_TEXTURE_PATH = "Interface\\WorldStateFrame\\"

-- Diameter, in yards, displayed by the outdoor minimap at each zoom level.
local MINIMAP_DIAMETERS = {
	[0] = 466.6666667,
	[1] = 400,
	[2] = 333.3333333,
	[3] = 266.6666667,
	[4] = 200,
	[5] = 133.3333333,
}

-- Exact world-map dimensions for battlegrounds exposed by Ascension/CoA.
local MAP_SIZES = {
	alteracvalley = { 4237.4998779, 2824.9998779 },
	warsonggulch = { 1145.8333130, 764.5833130 },
	arathibasin = { 1756.2499237, 1170.8332520 },
	arathibasinwinter = { 1756.2499237, 1170.8332520 },
	netherstormarena = { 2270.8331909, 1514.5833740 },
	eyeofthestorm = { 2270.8331909, 1514.5833740 },
	strandoftheancients = { 1743.7499390, 1162.4999390 },
	northrendbg = { 1743.7499390, 1162.4999390 },
	isleofconquest = { 2650.0000000, 1766.6665840 },
	twinpeaks = { 1214.5832520, 810.4165039 },
	gilneasbattleground = { 1302.0832825, 868.7500000 },
	gilneasbattleground2 = { 1302.0832825, 868.7500000 },
	battleforgilneas = { 1302.0832825, 868.7500000 },
	templeofkotmogu = { 839.5830078, 560.4160156 },
	stvdiamondminebg = { 915.5059967, 610.3373108 },
	silvershardmines = { 915.5059967, 610.3373108 },
	goldrush = { 1083.3339844, 722.9179688 },
	deepwindgorge = { 1083.3339844, 722.9179688 },
}

local MAP_SIZES_BY_ID = {
	[401] = MAP_SIZES.alteracvalley,
	[443] = MAP_SIZES.warsonggulch,
	[461] = MAP_SIZES.arathibasin,
	[462] = MAP_SIZES.arathibasin,
	[482] = MAP_SIZES.netherstormarena,
	[512] = MAP_SIZES.strandoftheancients,
	[540] = MAP_SIZES.isleofconquest,
	[626] = MAP_SIZES.twinpeaks,
	[736] = MAP_SIZES.gilneasbattleground2,
	[813] = MAP_SIZES.netherstormarena,
	[856] = MAP_SIZES.templeofkotmogu,
	[860] = MAP_SIZES.stvdiamondminebg,
	[935] = MAP_SIZES.goldrush,
	[1139] = MAP_SIZES.arathibasin,
}

local MINIMAP_SHAPES = {
	SQUARE = { false, false, false, false },
	["CORNER-TOPLEFT"] = { true, false, false, false },
	["CORNER-TOPRIGHT"] = { false, false, true, false },
	["CORNER-BOTTOMLEFT"] = { true, true, false, false },
	["CORNER-BOTTOMRIGHT"] = { false, false, true, true },
	["SIDE-LEFT"] = { true, true, false, false },
	["SIDE-RIGHT"] = { false, false, true, true },
	["SIDE-TOP"] = { true, false, true, false },
	["SIDE-BOTTOM"] = { false, true, false, true },
	["TRICORNER-TOPLEFT"] = { true, true, true, false },
	["TRICORNER-TOPRIGHT"] = { true, false, true, true },
	["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
	["TRICORNER-BOTTOMRIGHT"] = { false, true, true, true },
}

local DEFAULT_COLOR = { 0.72, 0.18, 1.00 }
local addonDB
local settings
local markers = {}
local flagMarkers = {}
local positionStates = {}
local updateElapsed = 0
local mapRefreshElapsed = MAP_REFRESH_INTERVAL
local currentMapName
local currentMapID
local currentMapWidth = FALLBACK_MAP_WIDTH
local currentMapHeight = 1000
local currentMapIsExact = false
local initialized = false

local function Localize(message)
	return API and API.LocalizeText and API.LocalizeText(message) or message
end

local function Print(message)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cff00bb78CoA Analytics|r |cffb82effMinimap|r: "
				.. Localize(tostring(message))
		)
	end
end

local function ClampSize(value)
	return math.max(6, math.min(20, math.floor((tonumber(value) or 7) + 0.5)))
end

local function EnsureSettings()
	addonDB = API and API.GetDatabase and API.GetDatabase() or addonDB
	if type(addonDB) ~= "table" then
		return nil
	end

	if type(addonDB.raidMinimap) ~= "table" then
		addonDB.raidMinimap = {}
	end
	settings = addonDB.raidMinimap

	local schemaVersion = tonumber(settings.schemaVersion) or 0
	if schemaVersion < SETTINGS_SCHEMA_VERSION then
		-- Version 3.1.1 enables the newly integrated feature once for every
		-- existing installation. Later user changes remain persistent.
		settings.enabled = true
		settings.schemaVersion = SETTINGS_SCHEMA_VERSION
	elseif settings.enabled == nil then
		settings.enabled = true
	end
	settings.size = ClampSize(settings.size)
	if type(settings.color) ~= "table" then
		settings.color = {
			DEFAULT_COLOR[1], DEFAULT_COLOR[2], DEFAULT_COLOR[3],
		}
	end

	return settings
end

local function NormalizeMapName(name)
	if not name then
		return ""
	end
	return string.lower((string.gsub(name, "[^%w]", "")))
end

local function InBattleground()
	local inInstance, instanceType = IsInInstance()
	return inInstance and instanceType == "pvp"
end

local function IsWorldMapOpen()
	return WorldMapFrame and WorldMapFrame:IsShown()
end

local function IsValidMapPosition(x, y)
	return x and y and x >= 0 and y >= 0 and x <= 1 and y <= 1
		and not (x == 0 and y == 0)
end

local function RefreshMap()
	if not InBattleground() or IsWorldMapOpen() then
		return
	end
	SetMapToCurrentZone()
	local mapName, textureHeight, textureWidth = GetMapInfo()
	local mapID = GetCurrentMapAreaID and GetCurrentMapAreaID() or nil
	local mapKey = NormalizeMapName(mapName)
	local exactSize = MAP_SIZES[mapKey]
	if not exactSize and mapKey == "" and mapID then
		exactSize = MAP_SIZES_BY_ID[mapID]
	end
	currentMapName = mapName or "?"
	currentMapID = mapID
	if exactSize then
		currentMapWidth = exactSize[1]
		currentMapHeight = exactSize[2]
		currentMapIsExact = true
	else
		local aspect = 1.5
		if textureWidth and textureHeight
			and textureWidth > 0 and textureHeight > 0
		then
			aspect = textureWidth / textureHeight
		end
		currentMapWidth = FALLBACK_MAP_WIDTH
		currentMapHeight = FALLBACK_MAP_WIDTH / aspect
		currentMapIsExact = false
	end
end

local function ApplyMarkerAppearance(marker)
	local size = settings and settings.size or 7
	marker:SetWidth(size)
	marker:SetHeight(size)
	local innerSize = math.max(2, size - 2)
	marker.inner:SetWidth(innerSize)
	marker.inner:SetHeight(innerSize)
	local color = settings and settings.color or DEFAULT_COLOR
	marker.outer:SetVertexColor(0, 0, 0, 1)
	marker.inner:SetVertexColor(color[1], color[2], color[3], 1)
end

local function CreateMarker()
	local marker = CreateFrame("Frame", nil, Minimap)
	marker:SetFrameStrata("HIGH")
	marker:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
	marker:EnableMouse(false)
	marker.outer = marker:CreateTexture(nil, "OVERLAY")
	marker.outer:SetTexture(MARKER_TEXTURE)
	marker.outer:SetAllPoints(marker)
	marker.inner = marker:CreateTexture(nil, "OVERLAY")
	marker.inner:SetTexture(MARKER_TEXTURE)
	marker.inner:SetPoint("CENTER", marker, "CENTER", 0, 0)
	ApplyMarkerAppearance(marker)
	marker:Hide()
	markers[#markers + 1] = marker
	return marker
end

local function AcquireMarker(index)
	return markers[index] or CreateMarker()
end

local function HideMarkersFrom(index)
	for markerIndex = index, #markers do
		markers[markerIndex]:Hide()
	end
end

local function CreateFlagMarker()
	local marker = CreateFrame("Frame", nil, Minimap)
	marker:SetWidth(FLAG_MARKER_SIZE)
	marker:SetHeight(FLAG_MARKER_SIZE)
	marker:SetFrameStrata("HIGH")
	marker:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 10)
	marker:EnableMouse(false)
	marker.texture = marker:CreateTexture(nil, "OVERLAY")
	marker.texture:SetAllPoints(marker)
	marker:Hide()
	flagMarkers[#flagMarkers + 1] = marker
	return marker
end

local function AcquireFlagMarker(index)
	return flagMarkers[index] or CreateFlagMarker()
end

local function HideFlagMarkersFrom(index)
	for markerIndex = index, #flagMarkers do
		flagMarkers[markerIndex]:Hide()
	end
end

local function HideAllMarkers()
	HideMarkersFrom(1)
	HideFlagMarkersFrom(1)
end

local function GetPlayerSubgroup()
	for index = 1, GetNumRaidMembers() do
		local unit = "raid" .. index
		if UnitExists(unit) and UnitIsUnit(unit, "player") then
			local _, _, subgroup = GetRaidRosterInfo(index)
			return subgroup
		end
	end
end

local function GetStablePosition(unit, key, now)
	local x, y = GetPlayerMapPosition(unit)
	local state = positionStates[key]
	if IsValidMapPosition(x, y) then
		if not state then
			state = {}
			positionStates[key] = state
		end
		state.x = x
		state.y = y
		state.lastSeen = now
		return x, y
	end
	if state and state.lastSeen
		and now - state.lastSeen <= POSITION_GRACE_SECONDS
	then
		return state.x, state.y
	end
end

local function GetMinimapShapeData()
	if not GetMinimapShape then
		return nil
	end
	return MINIMAP_SHAPES[GetMinimapShape()]
end

local function PlaceMarker(marker, xYards, yYards, size)
	local zoom = Minimap:GetZoom() or 0
	local diameter = MINIMAP_DIAMETERS[zoom] or MINIMAP_DIAMETERS[0]
	local minimapWidth = Minimap:GetWidth()
	local minimapHeight = Minimap:GetHeight()
	size = size or (settings and settings.size) or 7
	if GetCVar("rotateMinimap") ~= "0" then
		local angle = GetPlayerFacing() or 0
		local sine = math.sin(angle)
		local cosine = math.cos(angle)
		local oldX, oldY = xYards, yYards
		xYards = oldX * cosine - oldY * sine
		yYards = oldX * sine + oldY * cosine
	end
	local distance = math.sqrt(xYards * xYards + yYards * yYards)
	local radiusYards = diameter / 2
	local iconMarginYards = ((size / 2) + 2) * diameter
		/ math.min(minimapWidth, minimapHeight)
	local allowedRadius = math.max(1, radiusYards - iconMarginYards)
	local isRound = true
	local shape = GetMinimapShapeData()
	if shape and xYards ~= 0 and yYards ~= 0 then
		local quadrant = xYards < 0 and 1 or 3
		if yYards >= 0 then
			quadrant = quadrant + 1
		end
		isRound = shape[quadrant]
	end
	if isRound then
		if distance > allowedRadius then
			local factor = allowedRadius / distance
			xYards = xYards * factor
			yYards = yYards * factor
		end
	else
		xYards = math.max(-allowedRadius, math.min(allowedRadius, xYards))
		yYards = math.max(-allowedRadius, math.min(allowedRadius, yYards))
	end
	marker:ClearAllPoints()
	marker:SetPoint(
		"CENTER", Minimap, "CENTER",
		xYards * minimapWidth / diameter,
		-yYards * minimapHeight / diameter
	)
end

local function UpdateMarkers()
	if not settings or not settings.enabled or not InBattleground()
		or not Minimap:IsShown() or IsWorldMapOpen()
	then
		HideMarkersFrom(1)
		return
	end
	local raidCount = GetNumRaidMembers()
	if raidCount <= 0 then
		HideMarkersFrom(1)
		return
	end
	local playerX, playerY = GetPlayerMapPosition("player")
	if not IsValidMapPosition(playerX, playerY) then
		HideMarkersFrom(1)
		return
	end
	local playerSubgroup = GetPlayerSubgroup()
	local now = GetTime()
	local markerIndex = 1
	for raidIndex = 1, raidCount do
		local unit = "raid" .. raidIndex
		local name, _, subgroup, _, _, _, _, online =
			GetRaidRosterInfo(raidIndex)
		if name and online and UnitExists(unit)
			and not UnitIsUnit(unit, "player")
			and (not playerSubgroup or subgroup ~= playerSubgroup)
		then
			local key = UnitGUID(unit) or name
			local unitX, unitY = GetStablePosition(unit, key, now)
			if unitX and unitY then
				local marker = AcquireMarker(markerIndex)
				PlaceMarker(
					marker,
					(unitX - playerX) * currentMapWidth,
					(unitY - playerY) * currentMapHeight
				)
				marker:SetAlpha(UnitIsDeadOrGhost(unit) and 0.45 or 1)
				marker:Show()
				markerIndex = markerIndex + 1
			end
		end
	end
	HideMarkersFrom(markerIndex)
end

local function UpdateFlagMarkers()
	if not settings or not settings.enabled or not InBattleground()
		or not Minimap:IsShown() or IsWorldMapOpen()
		or not GetNumBattlefieldFlagPositions
		or not GetBattlefieldFlagPosition
	then
		HideFlagMarkersFrom(1)
		return
	end
	local playerX, playerY = GetPlayerMapPosition("player")
	if not IsValidMapPosition(playerX, playerY) then
		HideFlagMarkersFrom(1)
		return
	end
	local markerIndex = 1
	for flagIndex = 1, (GetNumBattlefieldFlagPositions() or 0) do
		local flagX, flagY, flagToken = GetBattlefieldFlagPosition(flagIndex)
		if IsValidMapPosition(flagX, flagY)
			and flagToken and flagToken ~= ""
		then
			local marker = AcquireFlagMarker(markerIndex)
			if marker.flagToken ~= flagToken then
				marker.texture:SetTexture(FLAG_TEXTURE_PATH .. flagToken)
				marker.flagToken = flagToken
			end
			PlaceMarker(
				marker,
				(flagX - playerX) * currentMapWidth,
				(flagY - playerY) * currentMapHeight,
				FLAG_MARKER_SIZE
			)
			marker:SetAlpha(1)
			marker:Show()
			markerIndex = markerIndex + 1
		end
	end
	HideFlagMarkersFrom(markerIndex)
end

local function RefreshMarkerAppearance()
	for index = 1, #markers do
		ApplyMarkerAppearance(markers[index])
	end
end

function RaidMinimap.GetSettings()
	return EnsureSettings()
end

function RaidMinimap.SetEnabled(enabled)
	if not EnsureSettings() then
		return
	end
	settings.enabled = enabled and true or false
	if not settings.enabled then
		HideAllMarkers()
	end
end

function RaidMinimap.SetSize(size)
	if not EnsureSettings() then
		return nil
	end
	settings.size = ClampSize(size)
	RefreshMarkerAppearance()
	return settings.size
end

function RaidMinimap.PrintStatus()
	if not EnsureSettings() then
		return
	end
	RefreshMap()
	local scaleText = currentMapIsExact and "echelle exacte" or "mode universel"
	Print(settings.enabled and "active" or "desactive")
	Print("BG : " .. tostring(currentMapName or "?")
		.. " | ID : " .. tostring(currentMapID) .. " | " .. scaleText)
	local flagCount = GetNumBattlefieldFlagPositions
		and GetNumBattlefieldFlagPositions() or 0
	Print("taille : " .. settings.size .. " | raid : "
		.. GetNumRaidMembers() .. " | drapeaux : " .. flagCount)
end

function RaidMinimap.HandleCommand(message)
	EnsureSettings()
	local command, argument = string.match(
		message or "", "^%s*(%S*)%s*(.-)%s*$"
	)
	command = string.lower(command or "")
	if command == "on" then
		RaidMinimap.SetEnabled(true)
		Print("active")
	elseif command == "off" then
		RaidMinimap.SetEnabled(false)
		Print("desactive")
	elseif command == "toggle" then
		RaidMinimap.SetEnabled(not settings.enabled)
		Print(settings.enabled and "active" or "desactive")
	elseif command == "size" then
		local size = tonumber(argument)
		if not size or size < 6 or size > 20 then
			Print("utilisation : /coaa minimap size 6-20")
			return
		end
		Print("taille des points : " .. RaidMinimap.SetSize(size))
	elseif command == "" or command == "status" then
		RaidMinimap.PrintStatus()
	else
		Print("commandes : /coaa minimap on, off, toggle, size 6-20, status")
	end
	local UI = CoAAnalyticsAddon.Modules.UI
	if UI and UI.RefreshSettings then
		UI.RefreshSettings()
	end
end

function RaidMinimap.Initialize()
	if initialized then
		return settings ~= nil
	end
	if not EnsureSettings() then
		return false
	end
	initialized = true
	mapRefreshElapsed = MAP_REFRESH_INTERVAL
	return true
end

SLASH_COARAIDMINIMAP1 = "/coarm"
SLASH_COARAIDMINIMAP2 = "/armm"
SlashCmdList.COARAIDMINIMAP = RaidMinimap.HandleCommand

local driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("ZONE_CHANGED_NEW_AREA")
driver:RegisterEvent("RAID_ROSTER_UPDATE")
driver:SetScript("OnEvent", function()
	positionStates = {}
	mapRefreshElapsed = MAP_REFRESH_INTERVAL
end)
driver:SetScript("OnUpdate", function(_, elapsed)
	if not initialized or not settings then
		return
	end
	updateElapsed = updateElapsed + elapsed
	mapRefreshElapsed = mapRefreshElapsed + elapsed
	if mapRefreshElapsed >= MAP_REFRESH_INTERVAL then
		mapRefreshElapsed = 0
		RefreshMap()
	end
	if updateElapsed < UPDATE_INTERVAL then
		return
	end
	updateElapsed = 0
	UpdateMarkers()
	UpdateFlagMarkers()
end)
