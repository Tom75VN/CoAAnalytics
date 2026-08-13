local API = CoAAnalyticsAPI
local GameTooltip = API.CreateLocalizedTooltipProxy(GameTooltip)
local MinimapModule = {}
CoAAnalyticsAddon.Modules.Minimap = MinimapModule

local config = API and API.Config or {}
local MINIMAP_BUTTON_RADIUS = config.MINIMAP_BUTTON_RADIUS or 80
local BUTTON_BORDER_OVERHANG = 10
local ROLE_FALLBACK_TEXTURES = config.ROLE_FALLBACK_TEXTURES or {}
local addonDB
local minimapButton

local function Atan2(y, x)
	if x > 0 then
		return math.atan(y / x)
	elseif x < 0 and y >= 0 then
		return math.atan(y / x) + math.pi
	elseif x < 0 and y < 0 then
		return math.atan(y / x) - math.pi
	elseif x == 0 and y > 0 then
		return math.pi / 2
	elseif x == 0 and y < 0 then
		return -math.pi / 2
	end
	return 0
end

local function SetMinimapButtonPosition()
	if not minimapButton or not addonDB then
		return
	end

	local angle = math.rad(addonDB.minimapButtonAngle or 225)
	local cosine = math.cos(angle)
	local sine = math.sin(angle)
	local offsetX = cosine * MINIMAP_BUTTON_RADIUS
	local offsetY = sine * MINIMAP_BUTTON_RADIUS

	-- ElvUI expose une minimap carree. L'angle sauvegarde reste identique,
	-- mais il est projete sur le bord du carre au lieu d'un cercle invisible.
	-- Cette conversion ne modifie jamais la position enregistree.
	if type(GetMinimapShape) == "function" and
		GetMinimapShape() == "SQUARE" then
		local horizontalRadius =
			(tonumber(Minimap:GetWidth()) or 0) / 2 + BUTTON_BORDER_OVERHANG
		local verticalRadius =
			(tonumber(Minimap:GetHeight()) or 0) / 2 + BUTTON_BORDER_OVERHANG
		local horizontalScale
		local verticalScale

		if horizontalRadius > 0 and math.abs(cosine) > 0.0001 then
			horizontalScale = horizontalRadius / math.abs(cosine)
		end
		if verticalRadius > 0 and math.abs(sine) > 0.0001 then
			verticalScale = verticalRadius / math.abs(sine)
		end

		local edgeScale = horizontalScale or verticalScale
		if verticalScale and (not edgeScale or verticalScale < edgeScale) then
			edgeScale = verticalScale
		end
		if edgeScale then
			offsetX = cosine * edgeScale
			offsetY = sine * edgeScale
		end
	end

	minimapButton:ClearAllPoints()
	minimapButton:SetPoint(
		"CENTER",
		Minimap,
		"CENTER",
		offsetX,
		offsetY
	)
end

local function UpdateMinimapButtonDrag()
	local cursorX, cursorY = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	cursorX = cursorX / scale
	cursorY = cursorY / scale

	local centerX, centerY = Minimap:GetCenter()
	if not centerX or not centerY then
		return
	end

	addonDB.minimapButtonAngle = math.deg(
		Atan2(cursorY - centerY, cursorX - centerX)
	)
	SetMinimapButtonPosition()
end

local function CreateMinimapButton()
	if minimapButton or not Minimap then
		return
	end

	local button = CreateFrame(
		"Button",
		"CoAAnalyticsMinimapButton",
		Minimap
	)
	-- CoAMiniButton regroupe automatiquement les enfants de la minimap. Cette
	-- marque garde volontairement le bouton CoA Analytics autour de la carte.
	button.coaMiniButtonIgnore = true
	button:SetWidth(32)
	button:SetHeight(32)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
	button:SetClampedToScreen(true)
	button:RegisterForClicks("LeftButtonUp")
	button:RegisterForDrag("LeftButton")

	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetWidth(22)
	icon:SetHeight(22)
	icon:SetPoint("CENTER", button, "CENTER", 0, 0)
	icon:SetTexture(ROLE_FALLBACK_TEXTURES.SUPPORT)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetWidth(54)
	border:SetHeight(54)
	border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetWidth(32)
	highlight:SetHeight(32)
	highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
	highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	highlight:SetBlendMode("ADD")

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("CoA Analytics", 0, 0.73, 0.47)
		GameTooltip:AddLine("Clic gauche : reglages", 1, 1, 1)
		GameTooltip:AddLine("Glisser : deplacer le bouton", 0.72, 0.72, 0.72)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	button:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", UpdateMinimapButtonDrag)
		GameTooltip:Hide()
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
		SetMinimapButtonPosition()
	end)
	button:SetScript("OnClick", function()
		local UI = CoAAnalyticsAddon.Modules.UI
		if UI and UI.Toggle then
			UI.Toggle()
		end
	end)

	minimapButton = button
	Minimap:HookScript("OnSizeChanged", SetMinimapButtonPosition)
	SetMinimapButtonPosition()
	button:Show()
end

function MinimapModule.Initialize()
	addonDB = API and API.GetDatabase and API.GetDatabase()
	if not addonDB then
		return false
	end
	CreateMinimapButton()
	return minimapButton ~= nil
end
