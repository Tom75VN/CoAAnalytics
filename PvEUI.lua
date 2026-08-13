local API = CoAAnalyticsAPI
local PvE = CoAAnalyticsPvE
local CreateFrame = API.CreateLocalizedFrame
local GameTooltip = API.CreateLocalizedTooltipProxy(GameTooltip)

local MAX_VISIBLE_ROWS = 20
local ROW_HEIGHT = 34
local SESSION_MAX_VISIBLE_ROWS = 20
local SESSION_ROW_HEIGHT = 34
local RANKING_PROGRESS_ALPHA = 0.38
local SESSION_PROGRESS_ALPHA = 0.36

local function GetVisibleRowCount(frame, rowHeight, maximum)
	local height = frame and tonumber(frame:GetHeight()) or 0
	if height <= 0 then
		return math.min(7, maximum)
	end
	return math.max(1, math.min(maximum, math.floor(height / rowHeight)))
end
local TABLE_LEFT_INSET = 12
local TABLE_RIGHT_INSET = 27
local RANKING_COLUMNS = {
	rank = { left = 6, width = 36 },
	identity = { left = 84 },
	score = { right = 150, width = 72 },
	samples = { right = 82, width = 36 },
	confidence = { right = 9, width = 100 },
}
local SESSION_COLUMNS = {
	role = { left = 292, width = 90 },
	dps = { right = 275, width = 55 },
	hps = { right = 205, width = 55 },
	deaths = { right = 145, width = 44 },
	score = { right = 77, width = 50 },
	rating = { right = 8, width = 58 },
}

local panel
local rows = {}
local scrollFrame
local noDataText
local methodologyText
local summarySamples
local summaryReference
local summarySpecs
local roleButtons = {}
local scopeButtons = {}
local activeCategory = "dps"
local activeScope = "all"
local sessionPanel
local sessionRows = {}
local sessionScrollFrame
local sessionNoDataText
local sessionMethodologyText
local sessionStatusText
local sessionSummaryInstance
local sessionSummaryCombat
local sessionSummaryRating

local function Clamp(value, minimum, maximum)
	value = tonumber(value) or 0
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

local function SafeNumber(value)
	value = tonumber(value)
	if not value or value ~= value or value == math.huge or value == -math.huge then
		return 0
	end
	return value
end

local function CreateSolidTexture(parent, layer, r, g, b, a)
	local texture = parent:CreateTexture(nil, layer or "ARTWORK")
	texture:SetTexture(1, 1, 1, a or 1)
	texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
	return texture
end

local function CreateTab(parent, label, r, g, b)
	local button = CreateFrame("Button", nil, parent)
	button:SetWidth(110)
	button:SetHeight(34)
	button:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
	button:SetBackdropColor(0.09, 0.10, 0.13, 0.96)
	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	button.text:SetPoint("CENTER")
	button.text:SetText(label)
	button.accent = CreateSolidTexture(button, "OVERLAY", r, g, b, 1)
	button.accent:SetPoint("BOTTOMLEFT", 0, 0)
	button.accent:SetPoint("BOTTOMRIGHT", 0, 0)
	button.accent:SetHeight(3)
	button.activeColor = { r, g, b }
	return button
end

local function SetTabActive(button, active)
	if not button then
		return
	end
	button:SetBackdropColor(
		active and 0.16 or 0.07,
		active and 0.17 or 0.08,
		active and 0.21 or 0.10,
		0.98
	)
	button.accent:SetAlpha(active and 1 or 0.18)
	button.text:SetTextColor(active and 1 or 0.68, active and 1 or 0.70, active and 1 or 0.75)
end

local function CreateSummaryCard(parent, x, label, r, g, b)
	local card = CreateFrame("Frame", nil, parent)
	card:SetWidth(210)
	card:SetHeight(62)
	card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -52)
	card:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 9,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	card:SetBackdropColor(0.04, 0.045, 0.06, 0.96)
	card:SetBackdropBorderColor(0.14, 0.16, 0.20, 1)
	local accent = CreateSolidTexture(card, "ARTWORK", r, g, b, 1)
	accent:SetWidth(4)
	accent:SetPoint("TOPLEFT", 4, -4)
	accent:SetPoint("BOTTOMLEFT", 4, 4)
	card.value = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	card.value:SetPoint("TOPLEFT", 17, -10)
	card.value:SetText("0")
	card.label = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	card.label:SetPoint("BOTTOMLEFT", 17, 10)
	card.label:SetText(label)
	return card
end

local function CreateRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(ROW_HEIGHT - 1)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", TABLE_LEFT_INSET, -151 - (index - 1) * ROW_HEIGHT)
	row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -TABLE_RIGHT_INSET, -151 - (index - 1) * ROW_HEIGHT)
	row.background = CreateSolidTexture(row, "BACKGROUND", 0.07, 0.075, 0.09, 0.96)
	row.background:SetAllPoints()
	row.progress = CreateSolidTexture(
		row,
		"ARTWORK",
		0.30,
		0.62,
		0.95,
		RANKING_PROGRESS_ALPHA
	)
	row.progress:SetPoint("TOPLEFT")
	row.progress:SetPoint("BOTTOMLEFT")
	row.progress:SetWidth(1)
	row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	row.rank:SetPoint("LEFT", RANKING_COLUMNS.rank.left, 0)
	row.rank:SetWidth(RANKING_COLUMNS.rank.width)
	row.rank:SetJustifyH("CENTER")
	row.icon = row:CreateTexture(nil, "OVERLAY")
	row.icon:SetWidth(28)
	row.icon:SetHeight(28)
	row.icon:SetPoint("LEFT", 48, 0)
	row.classText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.classText:SetPoint("TOPLEFT", RANKING_COLUMNS.identity.left, -5)
	row.specText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.specText:SetPoint("BOTTOMLEFT", RANKING_COLUMNS.identity.left, 5)
	row.scoreText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.scoreText:SetPoint("RIGHT", -RANKING_COLUMNS.score.right, 0)
	row.scoreText:SetWidth(RANKING_COLUMNS.score.width)
	row.scoreText:SetJustifyH("RIGHT")
	row.scoreText:SetWordWrap(false)
	row.samplesText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.samplesText:SetPoint("RIGHT", -RANKING_COLUMNS.samples.right, 0)
	row.samplesText:SetWidth(RANKING_COLUMNS.samples.width)
	row.samplesText:SetJustifyH("RIGHT")
	row.samplesText:SetWordWrap(false)
	row.confidenceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.confidenceText:SetPoint("RIGHT", -RANKING_COLUMNS.confidence.right, 0)
	row.confidenceText:SetWidth(RANKING_COLUMNS.confidence.width)
	row.confidenceText:SetJustifyH("RIGHT")
	row.confidenceText:SetWordWrap(false)
	row:EnableMouse(true)
	row:SetScript("OnEnter", function(self)
		if not self.entry then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(
			tostring(self.entry.specialization or "Specialisation"),
			1,
			0.82,
			0.20
		)
		GameTooltip:AddLine(string.format("Score stabilise : %.1f", self.entry.score), 1, 1, 1)
		GameTooltip:AddLine(string.format("Indice brut : %.1f", self.entry.rawScore), 0.72, 0.78, 0.86)
		GameTooltip:AddLine("Echantillons : " .. tostring(self.entry.samples), 0.72, 0.78, 0.86)
		GameTooltip:AddLine("Confiance : " .. tostring(self.entry.confidence), 0.72, 0.78, 0.86)
		GameTooltip:AddLine("Top 1 observes : " .. tostring(self.entry.top1), 0.72, 0.78, 0.86)
		GameTooltip:AddLine("Le score est ramene vers 100 tant que l'echantillon est faible.", 0.58, 0.62, 0.70, true)
		if activeCategory == "dps" then
			GameTooltip:AddLine(
				"Les nouveaux echantillons DPS sont corriges selon le niveau median du groupe, avec une correction limitee pour conserver l'effet de la build et de l'equipement.",
				0.58,
				0.64,
				0.72,
				true
			)
			if SafeNumber(self.entry.levelAdjustedSamples) > 0 then
				GameTooltip:AddLine(
					"Echantillons ajustes au niveau : "
						.. tostring(self.entry.levelAdjustedSamples),
					0.72,
					0.78,
					0.86
				)
			end
		end
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	row:Hide()
	return row
end

local function UpdateTabs()
	for key, button in pairs(roleButtons) do
		SetTabActive(button, key == activeCategory)
	end
	for key, button in pairs(scopeButtons) do
		SetTabActive(button, key == activeScope)
	end
end

function PvE.RefreshPanel()
	if not panel or not scrollFrame then
		return
	end
	local entries, summary = PvE.GetLeaderboard(activeCategory, activeScope)
	UpdateTabs()
	summarySamples.value:SetText(tostring(summary.samples or 0))
	summaryReference.value:SetText("100")
	summarySpecs.value:SetText(tostring(summary.specializations or 0))
	local categoryLabels = { dps = "DPS", healing = "soigneurs", tank = "tanks" }
	local scopeLabels = { all = "donjons et raids", dungeon = "donjons", raid = "boss de raid" }
	local levelMethod = activeCategory == "dps"
		and " Pour les DPS, les degats sont aussi ajustes au niveau median du groupe." or ""
	methodologyText:SetText(
		"100 = performance moyenne dans un contexte comparable. Le score est ajuste au contenu, puis stabilise avec 10 echantillons virtuels."
			.. levelMethod .. " Vue : " .. categoryLabels[activeCategory]
			.. " / " .. scopeLabels[activeScope] .. "."
	)

	local visibleRows = GetVisibleRowCount(scrollFrame, ROW_HEIGHT, MAX_VISIBLE_ROWS)
	FauxScrollFrame_Update(scrollFrame, #entries, visibleRows, ROW_HEIGHT)
	local offset = FauxScrollFrame_GetOffset(scrollFrame) or 0
	local leader = entries[1] and entries[1].score or 100
	for index = 1, MAX_VISIBLE_ROWS do
		local row = rows[index]
		local rankingIndex = offset + index
		local entry = index <= visibleRows and entries[rankingIndex]
		if entry then
			row.entry = entry
			row.rank:SetText(tostring(rankingIndex))
			if rankingIndex == 1 then
				row.rank:SetTextColor(1, 0.78, 0.18)
			elseif rankingIndex == 2 then
				row.rank:SetTextColor(0.78, 0.82, 0.88)
			elseif rankingIndex == 3 then
				row.rank:SetTextColor(0.80, 0.48, 0.23)
			else
				row.rank:SetTextColor(0.65, 0.68, 0.74)
			end
			if API and API.ApplySpecializationTexture then
				API.ApplySpecializationTexture(row.icon, entry, true)
			end
			local color = RAID_CLASS_COLORS[entry.classToken] or { r = 0.86, g = 0.86, b = 0.86 }
			local className = API and API.GetClassDisplayName
				and API.GetClassDisplayName(entry.classToken) or entry.classToken
			row.classText:SetText(className or "Classe inconnue")
			row.classText:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
			row.specText:SetText(tostring(entry.specialization or "?"))
			row.scoreText:SetText(string.format("%.1f", entry.score))
			row.samplesText:SetText(tostring(entry.samples))
			row.confidenceText:SetText(entry.confidence)
			row.confidenceText:SetTextColor(unpack(entry.confidenceColor))
			local relative = leader > 0 and entry.score / leader or 0
			row.progress:SetWidth(math.max(1, math.floor((row:GetWidth() or 1) * Clamp(relative, 0, 1))))
			if activeCategory == "dps" then
				row.progress:SetVertexColor(
					0.95,
					0.58,
					0.10,
					RANKING_PROGRESS_ALPHA
				)
			elseif activeCategory == "healing" then
				row.progress:SetVertexColor(
					0.20,
					0.82,
					0.42,
					RANKING_PROGRESS_ALPHA
				)
			else
				row.progress:SetVertexColor(
					0.30,
					0.62,
					0.95,
					RANKING_PROGRESS_ALPHA
				)
			end
			row:Show()
		else
			row.entry = nil
			row:Hide()
		end
	end
	if #entries == 0 then
		noDataText:Show()
	else
		noDataText:Hide()
	end
end

local function SelectCategory(category)
	activeCategory = category
	local scrollBar = _G["CoAAnalyticsPvERankingScrollFrameScrollBar"]
	if scrollBar then
		scrollBar:SetValue(0)
	end
	PvE.RefreshPanel()
end

local function SelectScope(scope)
	activeScope = scope
	local scrollBar = _G["CoAAnalyticsPvERankingScrollFrameScrollBar"]
	if scrollBar then
		scrollBar:SetValue(0)
	end
	PvE.RefreshPanel()
end

function PvE.CreatePanel(parent)
	if panel then
		return panel
	end
	panel = CreateFrame("Frame", nil, parent)
	panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -88)
	panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -18, 18)

	roleButtons.dps = CreateTab(panel, "Degats", 0.95, 0.58, 0.10)
	roleButtons.dps:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -6)
	roleButtons.healing = CreateTab(panel, "Soins", 0.20, 0.82, 0.42)
	roleButtons.healing:SetPoint("LEFT", roleButtons.dps, "RIGHT", 7, 0)
	roleButtons.tank = CreateTab(panel, "Tanks", 0.30, 0.62, 0.95)
	roleButtons.tank:SetPoint("LEFT", roleButtons.healing, "RIGHT", 7, 0)
	roleButtons.dps:SetScript("OnClick", function() SelectCategory("dps") end)
	roleButtons.healing:SetScript("OnClick", function() SelectCategory("healing") end)
	roleButtons.tank:SetScript("OnClick", function() SelectCategory("tank") end)

	scopeButtons.raid = CreateTab(panel, "Raids", 0.68, 0.43, 0.95)
	scopeButtons.raid:SetWidth(82)
	scopeButtons.raid:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -6)
	scopeButtons.dungeon = CreateTab(panel, "Donjons", 0.68, 0.43, 0.95)
	scopeButtons.dungeon:SetWidth(82)
	scopeButtons.dungeon:SetPoint("RIGHT", scopeButtons.raid, "LEFT", -6, 0)
	scopeButtons.all = CreateTab(panel, "Tous", 0.68, 0.43, 0.95)
	scopeButtons.all:SetWidth(70)
	scopeButtons.all:SetPoint("RIGHT", scopeButtons.dungeon, "LEFT", -6, 0)
	scopeButtons.all:SetScript("OnClick", function() SelectScope("all") end)
	scopeButtons.dungeon:SetScript("OnClick", function() SelectScope("dungeon") end)
	scopeButtons.raid:SetScript("OnClick", function() SelectScope("raid") end)

	summarySamples = CreateSummaryCard(panel, 8, "Echantillons analyses", 0.10, 0.72, 0.52)
	summaryReference = CreateSummaryCard(panel, 238, "Reference moyenne", 0.30, 0.62, 0.95)
	summarySpecs = CreateSummaryCard(panel, 468, "Specialisations classees", 0.68, 0.43, 0.95)

	local rankHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	rankHeader:SetPoint(
		"TOPLEFT", panel, "TOPLEFT",
		TABLE_LEFT_INSET + RANKING_COLUMNS.rank.left, -133
	)
	rankHeader:SetWidth(RANKING_COLUMNS.rank.width)
	rankHeader:SetJustifyH("CENTER")
	rankHeader:SetText("RANG")
	local identityHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	identityHeader:SetPoint(
		"TOPLEFT", panel, "TOPLEFT",
		TABLE_LEFT_INSET + RANKING_COLUMNS.identity.left, -133
	)
	identityHeader:SetText("CLASSE / SPECIALISATION")
	local scoreHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	scoreHeader:SetPoint(
		"TOPRIGHT", panel, "TOPRIGHT",
		-(TABLE_RIGHT_INSET + RANKING_COLUMNS.score.right), -133
	)
	scoreHeader:SetWidth(RANKING_COLUMNS.score.width)
	scoreHeader:SetJustifyH("RIGHT")
	scoreHeader:SetText("SCORE")
	local samplesHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	samplesHeader:SetPoint(
		"TOPRIGHT", panel, "TOPRIGHT",
		-(TABLE_RIGHT_INSET + RANKING_COLUMNS.samples.right), -133
	)
	samplesHeader:SetWidth(RANKING_COLUMNS.samples.width)
	samplesHeader:SetJustifyH("RIGHT")
	samplesHeader:SetText("NB")
	local confidenceHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	confidenceHeader:SetPoint(
		"TOPRIGHT", panel, "TOPRIGHT",
		-(TABLE_RIGHT_INSET + RANKING_COLUMNS.confidence.right), -133
	)
	confidenceHeader:SetWidth(RANKING_COLUMNS.confidence.width)
	confidenceHeader:SetJustifyH("RIGHT")
	confidenceHeader:SetText("CONFIANCE")

	scrollFrame = CreateFrame(
		"ScrollFrame",
		"CoAAnalyticsPvERankingScrollFrame",
		panel,
		"FauxScrollFrameTemplate"
	)
	scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -149)
	scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -24, 52)
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, PvE.RefreshPanel)
	end)
	for index = 1, MAX_VISIBLE_ROWS do
		rows[index] = CreateRow(panel, index)
	end

	noDataText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	noDataText:SetPoint("CENTER", panel, "CENTER", 0, -38)
	noDataText:SetText(
		"Aucune performance PvE valide pour le moment.\n"
			.. "Le classement commencera apres un donjon termine ou un boss de raid vaincu."
	)

	methodologyText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	methodologyText:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 9)
	methodologyText:SetWidth(540)
	methodologyText:SetHeight(40)
	methodologyText:SetJustifyH("LEFT")
	methodologyText:SetJustifyV("BOTTOM")
	methodologyText:SetWordWrap(true)

	local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	reset:SetWidth(130)
	reset:SetHeight(23)
	reset:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 7)
	reset:SetText("Reinitialiser")
	reset:SetScript("OnClick", function()
		StaticPopup_Show("COA_ANALYTICS_RESET_PVE")
	end)
	if not StaticPopupDialogs["COA_ANALYTICS_RESET_PVE"] then
		StaticPopupDialogs["COA_ANALYTICS_RESET_PVE"] = {
			text = API.LocalizeText("Effacer tout l'historique du classement PvE ?"),
			button1 = API.LocalizeText("Oui"),
			button2 = API.LocalizeText("Non"),
			OnAccept = function()
				local addonDB = API and API.GetDatabase and API.GetDatabase()
				if addonDB then
					local currentDungeon = addonDB.pveRankings
						and addonDB.pveRankings.currentDungeon
					local lastDungeonDiagnostic = addonDB.pveRankings
						and addonDB.pveRankings.lastDungeonDiagnostic
					addonDB.pveRankings = nil
					local root = PvE.InitializeDatabase()
					if root then
						root.currentDungeon = currentDungeon
						root.lastDungeonDiagnostic = lastDungeonDiagnostic
					end
					PvE.RefreshPanel()
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end

	panel:Hide()
	PvE.RefreshPanel()
	return panel
end

local SESSION_ROLE_LABELS = {
	TANK = "Tank",
	HEALER = "Soigneur",
	DAMAGER = "DPS",
	MELEE_DAMAGER = "DPS melee",
	RANGED_DAMAGER = "DPS distance",
	SUPPORT = "Support",
}

local function FormatCompactNumber(value)
	value = SafeNumber(value)
	if value >= 1000000 then
		return string.format("%.1f M", value / 1000000)
	elseif value >= 1000 then
		return string.format("%.1f k", value / 1000)
	end
	return tostring(math.floor(value + 0.5))
end

local function FormatCombatTime(seconds)
	seconds = math.floor(SafeNumber(seconds) + 0.5)
	local minutes = math.floor(seconds / 60)
	local remaining = seconds - minutes * 60
	return string.format("%d:%02d", minutes, remaining)
end

local function GetRatingColor(rating)
	if PvE and PvE.GetRatingColor then
		return PvE.GetRatingColor(rating)
	end
	return 1, 1, 1
end

local function CreateSessionRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(SESSION_ROW_HEIGHT - 1)
	row:SetPoint(
		"TOPLEFT",
		parent,
		"TOPLEFT",
		TABLE_LEFT_INSET,
		-151 - (index - 1) * SESSION_ROW_HEIGHT
	)
	row:SetPoint(
		"TOPRIGHT",
		parent,
		"TOPRIGHT",
		-TABLE_RIGHT_INSET,
		-151 - (index - 1) * SESSION_ROW_HEIGHT
	)
	row.background = CreateSolidTexture(row, "BACKGROUND", 0.07, 0.075, 0.09, 0.96)
	row.background:SetAllPoints()
	row.progress = CreateSolidTexture(
		row,
		"ARTWORK",
		0.68,
		0.43,
		0.95,
		SESSION_PROGRESS_ALPHA
	)
	row.progress:SetPoint("TOPLEFT")
	row.progress:SetPoint("BOTTOMLEFT")
	row.progress:SetWidth(1)

	row.specIcon = row:CreateTexture(nil, "OVERLAY")
	row.specIcon:SetWidth(27)
	row.specIcon:SetHeight(27)
	row.specIcon:SetPoint("LEFT", 7, 0)
	row.roleIcon = row:CreateTexture(nil, "OVERLAY")
	row.roleIcon:SetWidth(20)
	row.roleIcon:SetHeight(20)
	row.roleIcon:SetPoint("LEFT", 40, 0)
	row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.nameText:SetPoint("TOPLEFT", 67, -4)
	row.nameText:SetWidth(215)
	row.nameText:SetJustifyH("LEFT")
	row.specText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.specText:SetPoint("BOTTOMLEFT", 67, 4)
	row.specText:SetWidth(215)
	row.specText:SetJustifyH("LEFT")
	row.roleText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.roleText:SetPoint("LEFT", SESSION_COLUMNS.role.left, 0)
	row.roleText:SetWidth(SESSION_COLUMNS.role.width)
	row.roleText:SetJustifyH("LEFT")
	row.dpsText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.dpsText:SetPoint("RIGHT", -SESSION_COLUMNS.dps.right, 0)
	row.dpsText:SetWidth(SESSION_COLUMNS.dps.width)
	row.dpsText:SetJustifyH("RIGHT")
	row.dpsText:SetWordWrap(false)
	row.hpsText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.hpsText:SetPoint("RIGHT", -SESSION_COLUMNS.hps.right, 0)
	row.hpsText:SetWidth(SESSION_COLUMNS.hps.width)
	row.hpsText:SetJustifyH("RIGHT")
	row.hpsText:SetWordWrap(false)
	row.deathsText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.deathsText:SetPoint("RIGHT", -SESSION_COLUMNS.deaths.right, 0)
	row.deathsText:SetWidth(SESSION_COLUMNS.deaths.width)
	row.deathsText:SetJustifyH("RIGHT")
	row.deathsText:SetWordWrap(false)
	row.scoreText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.scoreText:SetPoint("RIGHT", -SESSION_COLUMNS.score.right, 0)
	row.scoreText:SetWidth(SESSION_COLUMNS.score.width)
	row.scoreText:SetJustifyH("RIGHT")
	row.scoreText:SetWordWrap(false)
	row.ratingText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	row.ratingText:SetPoint("RIGHT", -SESSION_COLUMNS.rating.right, 0)
	row.ratingText:SetWidth(SESSION_COLUMNS.rating.width)
	row.ratingText:SetJustifyH("RIGHT")
	row.ratingText:SetWordWrap(false)

	row:EnableMouse(true)
	row:SetScript("OnEnter", function(self)
		local entry = self.entry
		if not entry then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(tostring(entry.name or "Joueur"), 1, 0.82, 0.20)
		GameTooltip:AddLine(
			tostring(entry.specialization or "Specialisation inconnue")
				.. " - " .. tostring(SESSION_ROLE_LABELS[entry.role] or "Role inconnu"),
			0.78,
			0.82,
			0.90
		)
		if entry.rating then
			GameTooltip:AddLine("Note : " .. PvE.FormatRating(entry.rating) .. " / 10", 1, 1, 1)
			GameTooltip:AddLine(string.format("Score de role : %.1f", entry.score), 0.72, 0.78, 0.86)
		else
			GameTooltip:AddLine(
				entry.exclusionReason
					and ("Non classe : " .. tostring(entry.exclusionReason))
					or "Note en attente de donnees suffisantes.",
				0.72, 0.78, 0.86, true
			)
		end
		GameTooltip:AddLine(
			"Degats : " .. FormatCompactNumber(entry.damage)
				.. " | Soins utiles : " .. FormatCompactNumber(entry.healing)
				.. " | Morts : " .. tostring(entry.deaths or 0),
			0.72,
			0.78,
			0.86
		)
		if PvE.IsDamageRole(entry.role) then
			GameTooltip:AddLine("DPS : poids boss adapte au donjon, reference robuste entre DPS, puis correction prudente du niveau, de la participation et du temps en vie. Une phase trop courte ou isolee est ignoree.", 0.58, 0.64, 0.72, true)
			if entry.level and entry.levelReference and entry.levelFactor then
				GameTooltip:AddLine(
					string.format(
						"Niveau %d | niveau median DPS %.1f | coefficient x%.2f",
						entry.level,
						entry.levelReference,
						entry.levelFactor
					),
					0.72,
					0.78,
					0.86
				)
				GameTooltip:AddLine("Ce coefficient corrige uniquement la comparaison de la note; le DPS affiche reste la valeur reelle.", 0.58, 0.64, 0.72, true)
			end
		elseif entry.role == "HEALER" then
			GameTooltip:AddLine("Soigneur : stabilite, recuperation, couverture, disponibilite et gestion du mana. L'overheal a un impact presque nul. En soigneur unique, les morts hors portee et pendant un retour de wipe sont exclues.", 0.58, 0.64, 0.72, true)
			local breakdown = entry.healerBreakdown
			if breakdown then
				GameTooltip:AddLine(
					string.format(
						"Stabilite %.0f%% | Couverture %.0f%% | Reactivite %.0f%%",
						SafeNumber(breakdown.stability) * 100,
						SafeNumber(breakdown.coverage) * 100,
						SafeNumber(breakdown.responsiveness) * 100
					),
			0.72, 0.78, 0.86
		)
		if SafeNumber(entry.petDamage) > 0 or SafeNumber(entry.summonCount) > 0 then
			GameTooltip:AddLine(
				string.format(
					API.LocalizeText("Degats directs : %s | Degats des pets : %s (%.0f%%) | Invocations : %d"),
					FormatCompactNumber(entry.directDamage),
					FormatCompactNumber(entry.petDamage),
					SafeNumber(entry.petDamageShare) * 100,
					SafeNumber(entry.summonCount)
				),
				0.58, 0.64, 0.72
			)
		end
				GameTooltip:AddLine(
					string.format(
						"Disponibilite %.0f%% | Mana %.0f%% | Prevention %.0f%%",
						SafeNumber(breakdown.aliveRate) * 100,
						SafeNumber(breakdown.manaManagement) * 100,
						SafeNumber(breakdown.prevention) * 100
					),
					0.72, 0.78, 0.86
				)
				if breakdown.averageUrgentRecovery then
					GameTooltip:AddLine(
						string.format(
							"Sortie de danger : %.1fs | Remontee a 80%% : %s",
							SafeNumber(breakdown.averageUrgentRecovery),
							breakdown.averageRecovery
								and string.format("%.1fs", breakdown.averageRecovery) or "--"
						),
						0.72, 0.78, 0.86
					)
				end
				GameTooltip:AddLine(
					string.format(
						"Confiance %.0f%% (%s) | Overheal : influence 2%%",
						SafeNumber(breakdown.opportunity) * 100,
						tostring(breakdown.confidence or "inconnue")
					),
					0.72, 0.78, 0.86
				)
			end
		elseif entry.role == "TANK" then
			GameTooltip:AddLine("Tank : controle d'aggro prioritaire, resistance stabilisee, survie et utilitaires. Les degats et soins ajoutent seulement un bonus secondaire.", 0.58, 0.64, 0.72, true)
			local breakdown = entry.tankBreakdown
			if breakdown then
				GameTooltip:AddLine(
					string.format(
						"Aggro %.0f%% | Resistance %.0f%% | Survie %.0f%%",
						SafeNumber(breakdown.aggro) * 100,
						SafeNumber(breakdown.resilience) * 100,
						SafeNumber(breakdown.survival) * 100
					),
					0.72, 0.78, 0.86
				)
				GameTooltip:AddLine(
					string.format(
						"Controle %.0f%% | Perte %.1f%% | Acquisition %.1fs",
						SafeNumber(breakdown.uptime) * 100,
						SafeNumber(breakdown.lossRate) * 100,
						SafeNumber(breakdown.pickup)
					),
					0.72, 0.78, 0.86
				)
				GameTooltip:AddLine(
					string.format(
						"Reference : %d echantillon(s), confiance %.0f%% | Bonus utilitaire +%.1f",
						SafeNumber(breakdown.referenceSamples),
						SafeNumber(breakdown.referenceConfidence) * 100,
						SafeNumber(breakdown.utilityBonus)
					),
					0.58, 0.64, 0.72
				)
				GameTooltip:AddLine(
					string.format(
						API.LocalizeText("Contribution : degats %.0f%% (+%.1f) | soins %.0f%% (+%.1f)"),
						SafeNumber(breakdown.damageShare) * 100,
						SafeNumber(breakdown.damageBonus),
						SafeNumber(breakdown.healingShare) * 100,
						SafeNumber(breakdown.healingBonus)
					),
					0.58, 0.64, 0.72
				)
			end
		elseif entry.role == "SUPPORT" then
			GameTooltip:AddLine("Support : degats et soins mesurables. Les bonus, controles et utilitaires non exposes par le client ne peuvent pas tous etre notes.", 0.58, 0.64, 0.72, true)
		end
		GameTooltip:AddLine("7/10 correspond a la performance attendue pour le role dans ce groupe.", 0.58, 0.64, 0.72, true)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	row:Hide()
	return row
end

function PvE.RefreshSessionPanel()
	if not sessionPanel or not sessionScrollFrame then
		return
	end
	PvE.RefreshCurrentDungeonSnapshot()
	local snapshot = PvE.GetCurrentDungeonSnapshot()
	local entries = snapshot and snapshot.rows or {}
	if snapshot then
		sessionSummaryInstance.value:SetText(tostring(snapshot.instanceName or "Donjon"))
		sessionSummaryCombat.value:SetText(FormatCombatTime(snapshot.activeTime))
		if snapshot.averageRating then
			sessionSummaryRating.value:SetText(PvE.FormatRating(snapshot.averageRating) .. " / 10")
		else
			sessionSummaryRating.value:SetText("--")
		end
		if snapshot.active then
			sessionStatusText:SetText("SUIVI EN TEMPS REEL")
			sessionStatusText:SetTextColor(0.18, 0.90, 0.45)
		else
			sessionStatusText:SetText("DERNIER DONJON CONSERVE")
			sessionStatusText:SetTextColor(0.38, 0.72, 0.98)
		end
	else
		sessionSummaryInstance.value:SetText("Aucun")
		sessionSummaryCombat.value:SetText("0:00")
		sessionSummaryRating.value:SetText("--")
		sessionStatusText:SetText("EN ATTENTE D'UN DONJON")
		sessionStatusText:SetTextColor(0.62, 0.65, 0.72)
	end

	local visibleRows = GetVisibleRowCount(
		sessionScrollFrame,
		SESSION_ROW_HEIGHT,
		SESSION_MAX_VISIBLE_ROWS
	)
	FauxScrollFrame_Update(
		sessionScrollFrame,
		#entries,
		visibleRows,
		SESSION_ROW_HEIGHT
	)
	local offset = FauxScrollFrame_GetOffset(sessionScrollFrame) or 0
	for index = 1, SESSION_MAX_VISIBLE_ROWS do
		local row = sessionRows[index]
		local entry = index <= visibleRows and entries[offset + index]
		if entry then
			row.entry = entry
			if API and API.ApplySpecializationTexture then
				API.ApplySpecializationTexture(row.specIcon, entry, true)
			end
			if entry.role and API and API.ApplyRoleTexture then
				API.ApplyRoleTexture(row.roleIcon, entry.role)
				row.roleIcon:Show()
			else
				row.roleIcon:Hide()
			end
			local color = RAID_CLASS_COLORS[entry.classToken]
				or { r = 0.86, g = 0.86, b = 0.86 }
			row.nameText:SetText(tostring(entry.name or "Joueur inconnu"))
			row.nameText:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
			local className = API and API.GetClassDisplayName
				and API.GetClassDisplayName(entry.classToken) or entry.classToken
			row.specText:SetText(
				tostring(className or "Classe inconnue")
					.. " - " .. tostring(entry.specialization or "Specialisation inconnue")
			)
			row.roleText:SetText(SESSION_ROLE_LABELS[entry.role] or "Inconnu")
			row.dpsText:SetText(FormatCompactNumber(entry.dps))
			row.hpsText:SetText(FormatCompactNumber(entry.hps))
			row.deathsText:SetText(tostring(math.floor(SafeNumber(entry.deaths))))
			row.scoreText:SetText(entry.score and string.format("%.0f", entry.score) or "--")
			if entry.rating then
				row.ratingText:SetText(PvE.FormatRating(entry.rating))
				local ratingR, ratingG, ratingB = GetRatingColor(entry.rating)
				row.ratingText:SetTextColor(ratingR, ratingG, ratingB)
				row.progress:SetVertexColor(
					ratingR,
					ratingG,
					ratingB,
					SESSION_PROGRESS_ALPHA
				)
				local width = math.max(1, row:GetWidth() or 1)
				row.progress:SetWidth(math.max(1, math.floor(width * entry.rating / 10)))
			else
				row.ratingText:SetText("--")
				row.ratingText:SetTextColor(0.58, 0.62, 0.70)
				row.progress:SetWidth(1)
			end
			row:Show()
		else
			row.entry = nil
			row:Hide()
		end
	end
	if #entries == 0 then
		sessionNoDataText:Show()
	else
		sessionNoDataText:Hide()
	end
	sessionMethodologyText:SetText(
		"La note compare chaque personnage aux attentes de son propre role : 7/10 = performance attendue, 10/10 = exceptionnelle. "
			.. "Le resultat reste visible apres la sortie et sera remplace uniquement au debut du prochain donjon."
	)
end

function PvE.CreateSessionPanel(parent)
	if sessionPanel then
		return sessionPanel
	end
	sessionPanel = CreateFrame("Frame", nil, parent)
	sessionPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -88)
	sessionPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -18, 18)

	local title = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", sessionPanel, "TOPLEFT", 10, -15)
	title:SetText("Performance du donjon")
	sessionStatusText = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	sessionStatusText:SetPoint("TOPRIGHT", sessionPanel, "TOPRIGHT", -10, -18)

	sessionSummaryInstance = CreateSummaryCard(sessionPanel, 8, "Donjon suivi", 0.10, 0.72, 0.52)
	sessionSummaryInstance.value:SetWidth(180)
	sessionSummaryInstance.value:SetJustifyH("LEFT")
	sessionSummaryCombat = CreateSummaryCard(sessionPanel, 238, "Temps de combat", 0.30, 0.62, 0.95)
	sessionSummaryRating = CreateSummaryCard(sessionPanel, 468, "Note moyenne du groupe", 0.68, 0.43, 0.95)

	local identityHeader = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	identityHeader:SetPoint("TOPLEFT", sessionPanel, "TOPLEFT", 20, -133)
	identityHeader:SetText("PERSONNAGE / SPECIALISATION")
	local roleHeader = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	roleHeader:SetPoint(
		"TOPLEFT", sessionPanel, "TOPLEFT",
		TABLE_LEFT_INSET + SESSION_COLUMNS.role.left, -133
	)
	roleHeader:SetWidth(SESSION_COLUMNS.role.width)
	roleHeader:SetJustifyH("LEFT")
	roleHeader:SetText("ROLE")
	local dpsHeader = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	dpsHeader:SetPoint(
		"TOPRIGHT", sessionPanel, "TOPRIGHT",
		-(TABLE_RIGHT_INSET + SESSION_COLUMNS.dps.right), -133
	)
	dpsHeader:SetWidth(SESSION_COLUMNS.dps.width)
	dpsHeader:SetJustifyH("RIGHT")
	dpsHeader:SetText("DPS")
	local hpsHeader = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hpsHeader:SetPoint(
		"TOPRIGHT", sessionPanel, "TOPRIGHT",
		-(TABLE_RIGHT_INSET + SESSION_COLUMNS.hps.right), -133
	)
	hpsHeader:SetWidth(SESSION_COLUMNS.hps.width)
	hpsHeader:SetJustifyH("RIGHT")
	hpsHeader:SetText("HPS")
	local deathsHeader = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	deathsHeader:SetPoint(
		"TOPRIGHT", sessionPanel, "TOPRIGHT",
		-(TABLE_RIGHT_INSET + SESSION_COLUMNS.deaths.right), -133
	)
	deathsHeader:SetWidth(SESSION_COLUMNS.deaths.width)
	deathsHeader:SetJustifyH("RIGHT")
	deathsHeader:SetText("MORTS")
	local scoreHeader = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	scoreHeader:SetPoint(
		"TOPRIGHT", sessionPanel, "TOPRIGHT",
		-(TABLE_RIGHT_INSET + SESSION_COLUMNS.score.right), -133
	)
	scoreHeader:SetWidth(SESSION_COLUMNS.score.width)
	scoreHeader:SetJustifyH("RIGHT")
	scoreHeader:SetText("SCORE")
	local ratingHeader = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ratingHeader:SetPoint(
		"TOPRIGHT", sessionPanel, "TOPRIGHT",
		-(TABLE_RIGHT_INSET + SESSION_COLUMNS.rating.right), -133
	)
	ratingHeader:SetWidth(SESSION_COLUMNS.rating.width)
	ratingHeader:SetJustifyH("RIGHT")
	ratingHeader:SetText("NOTE /10")

	sessionScrollFrame = CreateFrame(
		"ScrollFrame",
		"CoAAnalyticsPvESessionScrollFrame",
		sessionPanel,
		"FauxScrollFrameTemplate"
	)
	sessionScrollFrame:SetPoint("TOPLEFT", sessionPanel, "TOPLEFT", 8, -149)
	sessionScrollFrame:SetPoint("BOTTOMRIGHT", sessionPanel, "BOTTOMRIGHT", -24, 52)
	sessionScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(
			self,
			offset,
			SESSION_ROW_HEIGHT,
			PvE.RefreshSessionPanel
		)
	end)
	for index = 1, SESSION_MAX_VISIBLE_ROWS do
		sessionRows[index] = CreateSessionRow(sessionPanel, index)
	end

	sessionNoDataText = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	sessionNoDataText:SetPoint("CENTER", sessionPanel, "CENTER", 0, -35)
	sessionNoDataText:SetText(
		"Aucun donjon memorise pour le moment.\n"
			.. "Le suivi commencera automatiquement a l'entree du prochain donjon."
	)
	sessionMethodologyText = sessionPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	sessionMethodologyText:SetPoint("BOTTOMLEFT", sessionPanel, "BOTTOMLEFT", 12, 9)
	sessionMethodologyText:SetPoint("BOTTOMRIGHT", sessionPanel, "BOTTOMRIGHT", -12, 9)
	sessionMethodologyText:SetHeight(40)
	sessionMethodologyText:SetJustifyH("LEFT")
	sessionMethodologyText:SetJustifyV("BOTTOM")
	sessionMethodologyText:SetWordWrap(true)

	sessionPanel:Hide()
	PvE.RefreshSessionPanel()
	return sessionPanel
end

function PvE.IsRankingPanelShown()
	return panel and panel:IsShown() or false
end

function PvE.IsSessionPanelShown()
	return sessionPanel and sessionPanel:IsShown() or false
end
