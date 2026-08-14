local API = CoAAnalyticsAPI
local CreateFrame = API.CreateLocalizedFrame
local GameTooltip = API.CreateLocalizedTooltipProxy(GameTooltip)
local RawUIDropDownMenuSetText = UIDropDownMenu_SetText
local RawUIDropDownMenuAddButton = UIDropDownMenu_AddButton
local function UIDropDownMenu_SetText(dropdown, value)
	return RawUIDropDownMenuSetText(dropdown, API.LocalizeText(value))
end
local function UIDropDownMenu_AddButton(info, level)
	if info and info.text then
		info.text = API.LocalizeText(info.text)
	end
	return RawUIDropDownMenuAddButton(info, level)
end
local UI = CoAAnalyticsUI or {}
CoAAnalyticsUI = UI
CoAAnalyticsAddon.Modules.UI = UI

local config = API and API.Config or {}
local ADDON_VERSION = API and API.VERSION or "?"
local RANKING_MAX_VISIBLE_ROWS = config.RANKING_MAX_VISIBLE_ROWS or 20
local RANKING_ROW_HEIGHT = config.RANKING_ROW_HEIGHT or 33
local RANKING_TABLE_LEFT_INSET = config.RANKING_TABLE_LEFT_INSET or 12
local RANKING_TABLE_RIGHT_INSET = config.RANKING_TABLE_RIGHT_INSET or 24
local RANKING_SCORE_RIGHT_INSET = config.RANKING_SCORE_RIGHT_INSET or 83
local RANKING_PERCENT_RIGHT_INSET = config.RANKING_PERCENT_RIGHT_INSET or 10
local RANKING_POINT_EPSILON = config.RANKING_POINT_EPSILON or 0.000000001
local CalculateSpecializationRanking = API.CalculateSpecializationRanking
local PLAYER_RANKING_PRIOR_MATCHES = config.PLAYER_RANKING_PRIOR_MATCHES or 10
local PLAYER_RANKING_UNCERTAINTY_MARGIN =
	config.PLAYER_RANKING_UNCERTAINTY_MARGIN or 6
local PLAYER_RANKING_PLACEMENT_MATCHES =
	config.PLAYER_RANKING_PLACEMENT_MATCHES or 3
local PLAYER_SEARCH_MAX_SUGGESTIONS = config.PLAYER_SEARCH_MAX_SUGGESTIONS or 8
local ICON_POSITION_OPTIONS = config.ICON_POSITION_OPTIONS or {}

local NormalizePlayerName = API.NormalizePlayerName
local InitializeRankingDatabase = API.InitializeRankingDatabase
local CopyTextureCoordinates = API.CopyTextureCoordinates
local ClampRankingValue = API.ClampRankingValue
local ApplySpecializationTexture = API.ApplySpecializationTexture
local RefreshVisibleIconLayouts = API.RefreshVisibleIconLayouts

local addonDB
local ui = {
	languageButtons = {},
	playerSearchSuggestionButtons = {},
	playerSearchSuggestions = {},
	playerSearchSelection = 0,
	playerSearchIndex = {},
	playerSearchIndexDirty = true,
	rankingRows = {},
	playerRankingRows = {},
	activeSettingsTab = "home",
	activePerformanceTab = "ranking",
	activeSettingsMode = "general",
	activeRankingCategory = "dps",
	activeRankingMode = "specializations",
	activePlayerRankingCategory = "dps",
	activePlayerDpsFilter = "all",
}

local function GetVisibleRowCount(scrollFrame, rowHeight, maximum)
	local height = scrollFrame and tonumber(scrollFrame:GetHeight()) or 0
	if height <= 0 then
		return math.min(7, maximum)
	end
	return math.max(1, math.min(maximum, math.floor(height / rowHeight)))
end

local function FormatLocalDiagnosticDateTime(timestamp)
	timestamp = tonumber(timestamp)
	if not timestamp or timestamp <= 0 then
		return "date inconnue"
	end
	if type(date) == "function" then
		local dateFormat = API.GetLanguage() == "en"
			and "%m/%d/%Y %H:%M:%S" or "%d/%m/%Y %H:%M:%S"
		local success, formatted = pcall(
			date,
			dateFormat,
			timestamp
		)
		if success and formatted then
			return formatted
		end
	end
	return tostring(timestamp)
end

local function FormatDungeonDiagnosticHistoryLine(index, report)
	local timestamp = report and (
		report.endedAt or report.capturedAt or report.updatedAt or report.startedAt
	)
	return tostring(index) .. ". "
		.. tostring(report and report.instanceName or "Donjon inconnu")
		.. "  |  " .. FormatLocalDiagnosticDateTime(timestamp)
end

local function GetPositionLabel(value)
	for _, option in ipairs(ICON_POSITION_OPTIONS) do
		if option.value == value then
			return option.text
		end
	end
	return "Au-dessus - centre"
end

local function RefreshSettingsControls()
	if not addonDB then
		return
	end

	if ui.rolePositionDropdown then
		UIDropDownMenu_SetSelectedValue(
			ui.rolePositionDropdown,
			addonDB.roleIconPosition
		)
		UIDropDownMenu_SetText(
			ui.rolePositionDropdown,
			GetPositionLabel(addonDB.roleIconPosition)
		)
	end
	if ui.specPositionDropdown then
		UIDropDownMenu_SetSelectedValue(
			ui.specPositionDropdown,
			addonDB.specIconPosition
		)
		UIDropDownMenu_SetText(
			ui.specPositionDropdown,
			GetPositionLabel(addonDB.specIconPosition)
		)
	end
	if ui.showSpecCheckButton then
		ui.showSpecCheckButton:SetChecked(addonDB.showSpecIcon and 1 or nil)
	end
	if ui.showDungeonOverlayCheckButton then
		ui.showDungeonOverlayCheckButton:SetChecked(
			addonDB.showDungeonPerformanceOverlay and 1 or nil
		)
	end
	if ui.enableKeystoneBossCheckButton then
		ui.enableKeystoneBossCheckButton:SetChecked(
			addonDB.enableKeystoneBossFeature and 1 or nil
		)
	end
	local raidMinimap = CoAAnalyticsAddon.Modules.RaidMinimap
	local raidMinimapSettings = raidMinimap and raidMinimap.GetSettings
		and raidMinimap.GetSettings()
	if ui.raidMinimapEnabledCheckButton and raidMinimapSettings then
		ui.raidMinimapEnabledCheckButton:SetChecked(
			raidMinimapSettings.enabled and 1 or nil
		)
	end
	if ui.raidMinimapSizeText and raidMinimapSettings then
		ui.raidMinimapSizeText:SetText(
			"Taille des points : " .. tostring(raidMinimapSettings.size) .. " px"
		)
	end
	if ui.diagnosticStatusText and CoAAnalyticsPvE
		and CoAAnalyticsPvE.GetDungeonDiagnosticStatus
	then
		local status = CoAAnalyticsPvE.GetDungeonDiagnosticStatus()
		if status.active then
			ui.diagnosticStatusText:SetText("Diagnostic actif pour le donjon actuel")
			ui.diagnosticStatusText:SetTextColor(0.18, 0.90, 0.45)
			ui.diagnosticToggleButton:SetText("Desactiver")
		elseif status.armed then
			ui.diagnosticStatusText:SetText("Suivi continu actif pour le prochain donjon")
			ui.diagnosticStatusText:SetTextColor(0.95, 0.78, 0.18)
			ui.diagnosticToggleButton:SetText("Desactiver")
		elseif status.last then
			ui.diagnosticStatusText:SetText(
				"Rapports complets : " .. tostring(status.count or 1)
					.. "/" .. tostring(status.limit or 10)
					.. " | Dernier : " .. tostring(status.last.instanceName or "Donjon")
			)
			ui.diagnosticStatusText:SetTextColor(0.38, 0.72, 0.95)
			ui.diagnosticToggleButton:SetText("Enregistrer le prochain")
		else
			ui.diagnosticStatusText:SetText("Aucun diagnostic complet enregistre")
			ui.diagnosticStatusText:SetTextColor(0.62, 0.66, 0.72)
			ui.diagnosticToggleButton:SetText("Enregistrer le prochain")
		end
		if ui.clearDiagnosticButton then
			if status.last then
				ui.clearDiagnosticButton:Enable()
			else
				ui.clearDiagnosticButton:Disable()
			end
		end
		if ui.exportDiagnosticButton then
			if status.last then
				ui.exportDiagnosticButton:Enable()
			else
				ui.exportDiagnosticButton:Disable()
			end
		end
		if ui.diagnosticHistoryText then
			local reports = status.reports or {}
			local visibleRows = math.max(1, #reports)
			ui.diagnosticHistoryRows = ui.diagnosticHistoryRows or {
				ui.diagnosticHistoryText,
			}
			for index = 1, visibleRows do
				local row = ui.diagnosticHistoryRows[index]
				if not row then
					row = ui.diagnosticHistoryContent:CreateFontString(
						nil, "OVERLAY", "GameFontHighlightSmall"
					)
					ui.diagnosticHistoryRows[index] = row
				end
				row:ClearAllPoints()
				row:SetPoint(
					"TOPLEFT", ui.diagnosticHistoryContent, "TOPLEFT", 0,
					-(index - 1) * 18
				)
				row:SetWidth(650)
				row:SetHeight(18)
				row:SetJustifyH("LEFT")
				row:SetJustifyV("MIDDLE")
				row:SetWordWrap(false)
				row:SetText(#reports > 0
					and FormatDungeonDiagnosticHistoryLine(index, reports[index])
					or "Aucun diagnostic complet conserve.")
				row:Show()
			end
			for index = visibleRows + 1, #ui.diagnosticHistoryRows do
				ui.diagnosticHistoryRows[index]:Hide()
			end
			if ui.diagnosticHistoryContent and ui.diagnosticHistoryScroll then
				local visibleHeight = ui.diagnosticHistoryScroll:GetHeight() or 0
				ui.diagnosticHistoryContent:SetHeight(
					math.max(visibleRows * 18 + 6, visibleHeight, 1)
				)
			end
		end
	end
end

local function CreatePositionDropdown(parent, globalName, settingKey, x, y)
	local dropdown = CreateFrame(
		"Frame",
		globalName,
		parent,
		"UIDropDownMenuTemplate"
	)
	dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	UIDropDownMenu_SetWidth(dropdown, 160)

	UIDropDownMenu_Initialize(dropdown, function()
		for _, option in ipairs(ICON_POSITION_OPTIONS) do
			local value = option.value
			local label = option.text
			local info = UIDropDownMenu_CreateInfo()
			info.text = label
			info.value = value
			info.checked = addonDB and addonDB[settingKey] == value
			info.func = function()
				addonDB[settingKey] = value
				UIDropDownMenu_SetSelectedValue(dropdown, value)
				UIDropDownMenu_SetText(dropdown, label)
				CloseDropDownMenus()
				RefreshVisibleIconLayouts()
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	return dropdown
end

local function CreateSolidTexture(parent, layer, r, g, b, a)
	local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
	texture:SetTexture("Interface\\Buttons\\WHITE8X8")
	texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
	return texture
end

local function CreateLanguageFlagButton(parent, language, x)
	local button = CreateFrame("Button", nil, parent)
	button:SetWidth(32)
	button:SetHeight(22)
	button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", x, -10)
	button:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 7,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	button:SetBackdropColor(0.05, 0.06, 0.08, 0.98)
	button.language = language

	local flag = CreateFrame("Frame", nil, button)
	flag:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
	flag:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 5)
	flag:EnableMouse(false)

	if language == "fr" then
		local blue = CreateSolidTexture(flag, "ARTWORK", 0.02, 0.22, 0.58, 1)
		blue:SetPoint("TOPLEFT", flag, "TOPLEFT", 0, 0)
		blue:SetPoint("BOTTOMLEFT", flag, "BOTTOMLEFT", 0, 0)
		blue:SetWidth(7.5)
		local white = CreateSolidTexture(flag, "ARTWORK", 0.96, 0.96, 0.96, 1)
		white:SetPoint("TOPLEFT", blue, "TOPRIGHT", 0, 0)
		white:SetPoint("BOTTOMLEFT", blue, "BOTTOMRIGHT", 0, 0)
		white:SetWidth(7.5)
		local red = CreateSolidTexture(flag, "ARTWORK", 0.82, 0.03, 0.08, 1)
		red:SetPoint("TOPLEFT", white, "TOPRIGHT", 0, 0)
		red:SetPoint("BOTTOMRIGHT", flag, "BOTTOMRIGHT", 0, 0)
	else
		local stripeHeight = 12 / 7
		for index = 1, 7 do
			local redStripe = index % 2 == 1
			local stripe = CreateSolidTexture(
				flag,
				"ARTWORK",
				redStripe and 0.76 or 0.96,
				redStripe and 0.04 or 0.96,
				redStripe and 0.07 or 0.96,
				1
			)
			stripe:SetPoint("TOPLEFT", flag, "TOPLEFT", 0, -(index - 1) * stripeHeight)
			stripe:SetPoint("TOPRIGHT", flag, "TOPRIGHT", 0, -(index - 1) * stripeHeight)
			stripe:SetHeight(stripeHeight + 0.2)
		end
		local canton = CreateSolidTexture(flag, "OVERLAY", 0.03, 0.12, 0.34, 1)
		canton:SetPoint("TOPLEFT", flag, "TOPLEFT", 0, 0)
		canton:SetWidth(9)
		canton:SetHeight(7)
		for index = 1, 5 do
			local star = CreateSolidTexture(flag, "OVERLAY", 1, 1, 1, 1)
			star:SetWidth(1)
			star:SetHeight(1)
			star:SetPoint(
				"TOPLEFT",
				canton,
				"TOPLEFT",
				1 + ((index - 1) % 3) * 3,
				-1 - math.floor((index - 1) / 3) * 3
			)
		end
	end

	button:SetScript("OnClick", function(self)
		if API.GetLanguage() ~= self.language then
			API.SetLanguage(self.language, true)
		end
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText(self.language == "fr" and "Francais" or "English (US)")
		GameTooltip:AddLine("Cliquer pour utiliser cette langue.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	ui.languageButtons[language] = button
	return button
end

local function RefreshLanguageButtons()
	local selected = API.GetLanguage()
	for language, button in pairs(ui.languageButtons) do
		local active = language == selected
		button:SetAlpha(active and 1 or 0.52)
		if active then
			button:SetBackdropBorderColor(1, 0.78, 0.12, 1)
		else
			button:SetBackdropBorderColor(0.28, 0.32, 0.38, 1)
		end
	end
end

local function CreateModernTab(parent, label, accentR, accentG, accentB)
	local button = CreateFrame("Button", nil, parent)
	button:SetWidth(150)
	button:SetHeight(28)
	button.background = CreateSolidTexture(button, "BACKGROUND", 0.10, 0.11, 0.13, 0.95)
	button.background:SetAllPoints(button)
	button.accent = CreateSolidTexture(button, "ARTWORK", accentR, accentG, accentB, 1)
	button.accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
	button.accent:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	button.accent:SetHeight(2)
	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	button.text:SetPoint("CENTER", button, "CENTER", 0, 1)
	button.text:SetText(label)
	button.accentColor = { accentR, accentG, accentB }
	button:SetScript("OnEnter", function(self)
		if not self.active then
			self.background:SetVertexColor(0.16, 0.17, 0.20, 1)
		end
	end)
	button:SetScript("OnLeave", function(self)
		if not self.active then
			self.background:SetVertexColor(0.10, 0.11, 0.13, 0.95)
		end
	end)
	return button
end

local function SetModernTabActive(button, active)
	if not button then
		return
	end
	button.active = active and true or false
	if active then
		button.background:SetVertexColor(0.20, 0.21, 0.24, 1)
		button.accent:Show()
		button.text:SetTextColor(1, 1, 1)
	else
		button.background:SetVertexColor(0.10, 0.11, 0.13, 0.95)
		button.accent:Hide()
		button.text:SetTextColor(0.68, 0.70, 0.74)
	end
end

local function GetRankingClassName(classToken)
	if not classToken then
		return "Classe inconnue"
	end
	local localized = LOCALIZED_CLASS_NAMES_MALE
		and LOCALIZED_CLASS_NAMES_MALE[classToken]
	if localized and localized ~= "" then
		return localized
	end

	local name = string.lower(tostring(classToken)):gsub("_", " ")
	return (name:gsub("(%a)([%w']*)", function(first, rest)
		return string.upper(first) .. rest
	end))
end

local function CreateRankingSummaryCard(parent, x, label, r, g, b)
	local card = CreateFrame("Frame", nil, parent)
	card:SetWidth(176)
	card:SetHeight(50)
	card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -42)
	card:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 10,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	card:SetBackdropColor(0.055, 0.06, 0.075, 0.96)
	card:SetBackdropBorderColor(0.18, 0.19, 0.22, 0.9)
	local accent = CreateSolidTexture(card, "ARTWORK", r, g, b, 1)
	accent:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -4)
	accent:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 4, 4)
	accent:SetWidth(3)
	card.value = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	card.value:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -8)
	card.value:SetText("0")
	card.label = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	card.label:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 14, 8)
	card.label:SetText(label)
	card:EnableMouse(true)
	card:SetScript("OnEnter", function(self)
		if not self.tooltipText then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(self.tooltipTitle or label)
		GameTooltip:AddLine(self.tooltipText, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	card:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return card
end

local function CreateRankingColumnHeader(parent, label, tooltipText, width)
	local header = CreateFrame("Button", nil, parent)
	header:SetWidth(width or 90)
	header:SetHeight(20)
	header.text = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	header.text:SetAllPoints(header)
	header.text:SetJustifyH("LEFT")
	header.text:SetText(label)
	header.tooltipText = tooltipText
	header:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(label, 1, 0.82, 0.20)
		GameTooltip:AddLine(self.tooltipText or "", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	header:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return header
end

local function CreateRankingRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetFrameLevel(parent:GetFrameLevel() + 2)
	local offsetY = -132 - ((index - 1) * RANKING_ROW_HEIGHT)
	row:SetPoint(
		"TOPLEFT",
		parent,
		"TOPLEFT",
		RANKING_TABLE_LEFT_INSET,
		offsetY
	)
	row:SetPoint(
		"TOPRIGHT",
		parent,
		"TOPRIGHT",
		-RANKING_TABLE_RIGHT_INSET,
		offsetY
	)
	row:SetHeight(RANKING_ROW_HEIGHT - 2)
	row.background = CreateSolidTexture(
		row,
		"BACKGROUND",
		index % 2 == 0 and 0.075 or 0.055,
		index % 2 == 0 and 0.08 or 0.06,
		index % 2 == 0 and 0.095 or 0.075,
		0.96
	)
	row.background:SetAllPoints(row)
	row.progress = CreateSolidTexture(row, "BORDER", 0.92, 0.64, 0.12, 0.20)
	row.progress:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
	row.progress:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)

	row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	row.rank:SetPoint("LEFT", row, "LEFT", 8, 0)
	row.rank:SetWidth(28)
	row.rank:SetJustifyH("CENTER")

	row.icon = row:CreateTexture(nil, "OVERLAY")
	row.icon:SetWidth(24)
	row.icon:SetHeight(24)
	row.icon:SetPoint("LEFT", row, "LEFT", 41, 0)

	row.classText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.classText:SetPoint("LEFT", row, "LEFT", 74, 5)
	row.classText:SetWidth(125)
	row.classText:SetJustifyH("LEFT")
	row.classText:SetWordWrap(false)

	row.specText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.specText:SetPoint("LEFT", row, "LEFT", 74, -8)
	row.specText:SetWidth(270)
	row.specText:SetJustifyH("LEFT")
	row.specText:SetWordWrap(false)

	row.scoreText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.scoreText:SetPoint(
		"RIGHT",
		row,
		"RIGHT",
		-RANKING_SCORE_RIGHT_INSET,
		0
	)
	row.scoreText:SetWidth(90)
	row.scoreText:SetJustifyH("RIGHT")

	row.percentText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	row.percentText:SetPoint(
		"RIGHT",
		row,
		"RIGHT",
		-RANKING_PERCENT_RIGHT_INSET,
		0
	)
	row.percentText:SetWidth(66)
	row.percentText:SetJustifyH("RIGHT")

	row:EnableMouse(true)
	row:SetScript("OnEnter", function(self)
		if not self.entry or not self.rankingResult then
			return
		end
		local result = self.rankingResult
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(
			GetRankingClassName(self.entry.classToken)
				.. " - " .. tostring(self.entry.specialization or "?")
		)
		GameTooltip:AddLine(
			string.format(
				"Score lisse : %.3f point par participation",
				tonumber(result.score) or 0
			),
			0.95,
			0.72,
			0.18
		)
		GameTooltip:AddLine(
			"Le score compare les performances moyennes, pas le nombre total de presences. Cinq participations virtuelles a la moyenne stabilisent les petits echantillons.",
			1,
			1,
			1,
			true
		)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(
			string.format(
				"Moyenne brute : %.3f - Points cumules : %.2f",
				tonumber(result.rawScore) or 0,
				tonumber(result.points) or 0
			),
			0.72,
			0.78,
			0.86
		)
		GameTooltip:AddLine(
			string.format(
				"Part du classement : %.1f%%",
				tonumber(self.performanceShare) or 0
			),
			0.95,
			0.72,
			0.18
		)
		GameTooltip:AddLine(
			"Part de cette specialisation dans la somme des scores normalises. Une presence frequente augmente la fiabilite, mais n'augmente plus directement ce pourcentage.",
			1,
			1,
			1,
			true
		)
		local top1 = tonumber(self.entry.top1Finishes)
			or tonumber(self.entry.wins)
			or 0
		GameTooltip:AddLine(
			"Top 1 : " .. tostring(top1),
			0.92,
			0.74,
			0.28,
			true
		)
		GameTooltip:AddLine(
			"Proche du meilleur (>= 90%) : "
				.. tostring(self.entry.nearTopBGs or 0),
			0.72,
			0.78,
			0.86
		)
		GameTooltip:AddLine(
			"Echantillon : " .. tostring(self.entry.appearances or 0)
				.. string.format(
					" BG (poids cumule %.2f)",
					tonumber(result.appearanceWeight) or 0
				),
			0.72,
			0.78,
			0.86,
			true
		)
		if self.entry.lastPlayer then
			GameTooltip:AddLine(
				"Derniere performance creditee : "
					.. tostring(self.entry.lastPlayer),
				0.65,
				0.68,
				0.74
			)
		end
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	row:Hide()
	return row
end

local function RefreshSpecializationRankingPanel()
	if not addonDB or not ui.rankingPanel or not ui.rankingScrollFrame then
		return
	end
	InitializeRankingDatabase()

	local rankings = addonDB.rankings
	local category = rankings[ui.activeRankingCategory]
	local analyzedBGs = tonumber(category.analyzedBGs) or 0
	local totalWeight = tonumber(category.totalWeight) or 0
	local entries, rankingStats = CalculateSpecializationRanking(category)
	local rankedSpecializationCount = #entries

	local averageMatchWeight = analyzedBGs > 0
		and (totalWeight / analyzedBGs) * 100
		or 0
	ui.rankingSummaryAnalyzed.value:SetText(tostring(analyzedBGs))
	ui.rankingSummaryBalance.value:SetText(string.format("%.0f%%", averageMatchWeight))
	ui.rankingSummarySpecializations.value:SetText(
		tostring(rankedSpecializationCount)
	)
	if ui.rankingMethodologyText then
		ui.rankingMethodologyText:SetText(string.format(
			"Score = performance par participation, lissee avec %.0f BG virtuels a la moyenne. "
				.. "Jouer souvent augmente la fiabilite, pas le score. Influence moyenne des BG : %.0f%% ; les stomps comptent moins.",
			rankingStats.priorWeight or 0,
			averageMatchWeight
		))
	end

	local visibleRows = GetVisibleRowCount(
		ui.rankingScrollFrame,
		RANKING_ROW_HEIGHT,
		RANKING_MAX_VISIBLE_ROWS
	)
	FauxScrollFrame_Update(
		ui.rankingScrollFrame,
		#entries,
		visibleRows,
		RANKING_ROW_HEIGHT
	)
	local offset = FauxScrollFrame_GetOffset(ui.rankingScrollFrame) or 0
	local leadingScore = entries[1]
		and (tonumber(entries[1].score) or 0)
		or 0
	for rowIndex = 1, RANKING_MAX_VISIBLE_ROWS do
		local row = ui.rankingRows[rowIndex]
		local rankingIndex = offset + rowIndex
		local result = rowIndex <= visibleRows and entries[rankingIndex]
		local entry = result and result.entry
		if row and entry then
			local score = tonumber(result.score) or 0
			local percent = (tonumber(result.share) or 0) * 100
			local relativeStrength = leadingScore > 0 and score / leadingScore or 0
			local color = RAID_CLASS_COLORS[entry.classToken]
				or { r = 0.85, g = 0.85, b = 0.85 }
			row.entry = entry
			row.rankingResult = result
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
			ApplySpecializationTexture(row.icon, entry, true)
			row.classText:SetText(GetRankingClassName(entry.classToken))
			row.classText:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
			local top1 = tonumber(entry.top1Finishes)
				or tonumber(entry.wins)
				or 0
			row.specText:SetText(
				tostring(entry.specialization or "?")
					.. "  |cff8f949e- Top 1 : " .. tostring(top1)
					.. " - " .. tostring(entry.appearances or 0) .. " BG|r"
			)
			row.scoreText:SetText(string.format("%.2f pt/BG", score))
			row.percentText:SetText(string.format("%.1f%%", percent))
			row.performanceShare = percent
			row.progress:SetVertexColor(
				ui.activeRankingCategory == "dps" and 0.95 or 0.20,
				ui.activeRankingCategory == "dps" and 0.58 or 0.82,
				ui.activeRankingCategory == "dps" and 0.10 or 0.42,
				0.20
			)
			local rowWidth = row:GetWidth()
			if not rowWidth or rowWidth <= 0 then
				rowWidth = math.max(
					1,
					(ui.rankingPanel:GetWidth() or 0)
						- RANKING_TABLE_LEFT_INSET
						- RANKING_TABLE_RIGHT_INSET
				)
			end
			row.progress:SetWidth(
				math.max(1, math.floor(rowWidth * relativeStrength))
			)
			row:Show()
		elseif row then
			row.entry = nil
			row.rankingResult = nil
			row.performanceShare = nil
			row:Hide()
		end
	end

	if #entries == 0 then
		ui.rankingNoDataText:Show()
	else
		ui.rankingNoDataText:Hide()
	end
end

local PLAYER_ROLE_LABELS = {
	MELEE_DAMAGER = "DPS melee",
	RANGED_DAMAGER = "DPS distance",
	DAMAGER = "DPS",
	HEALER = "Soigneur",
	TANK = "Tank",
	SUPPORT = "Support",
}

local function GetPlayerConfidence(appearances)
	appearances = tonumber(appearances) or 0
	if appearances < 5 then
		return "Provisoire", { 0.95, 0.62, 0.18 }
	elseif appearances < 20 then
		return "Moyenne", { 0.38, 0.72, 0.95 }
	end
	return "Fiable", { 0.18, 0.82, 0.46 }
end

local function GetActivePlayerRoleKeys()
	if ui.activePlayerRankingCategory == "healing" then
		return { "HEALER" }
	elseif ui.activePlayerRankingCategory == "tank" then
		return { "TANK" }
	elseif ui.activePlayerRankingCategory == "support" then
		return { "SUPPORT" }
	elseif ui.activePlayerDpsFilter == "melee" then
		return { "MELEE_DAMAGER" }
	elseif ui.activePlayerDpsFilter == "ranged" then
		return { "RANGED_DAMAGER" }
	end
	return { "MELEE_DAMAGER", "RANGED_DAMAGER", "DAMAGER" }
end

local function MergePlayerSpecializations(target, source)
	target.specializations = target.specializations or {}
	for key, specialization in pairs(source.specializations or {}) do
		local existing = target.specializations[key]
		if not existing then
			existing = {
				classToken = specialization.classToken,
				specializationID = specialization.specializationID,
				specialization = specialization.specialization,
				specializationTexture = specialization.specializationTexture,
				specializationTexCoords = CopyTextureCoordinates(
					specialization.specializationTexCoords
				),
				appearances = 0,
			}
			target.specializations[key] = existing
		end
		existing.appearances = (tonumber(existing.appearances) or 0)
			+ (tonumber(specialization.appearances) or 0)
		if existing.appearances >= (tonumber(target.mainSpecializationAppearances) or 0) then
			target.classToken = existing.classToken or target.classToken
			target.specializationID = existing.specializationID
			target.specialization = existing.specialization
			target.specializationTexture = existing.specializationTexture
			target.specializationTexCoords = CopyTextureCoordinates(
				existing.specializationTexCoords
			)
			target.mainSpecializationAppearances = existing.appearances
		end
	end
end

local function FormatPlayerLastSeen(timestamp)
	timestamp = tonumber(timestamp)
	if not timestamp or timestamp <= 0 then
		return "Inconnue"
	end
	local elapsed = math.max(0, time() - timestamp)
	if elapsed < 60 then
		return "A l'instant"
	elseif elapsed < 3600 then
		return "Il y a " .. tostring(math.floor(elapsed / 60)) .. " min"
	elseif elapsed < 86400 then
		return "Il y a " .. tostring(math.floor(elapsed / 3600)) .. " h"
	elseif elapsed < 604800 then
		local daySuffix = API.GetLanguage() == "en" and " d" or " j"
		return "Il y a " .. tostring(math.floor(elapsed / 86400)) .. daySuffix
	end
	if type(date) == "function" then
		return date(API.GetLanguage() == "en" and "%m/%d/%Y" or "%d/%m/%Y", timestamp)
	end
	return "Ancienne"
end

local function BuildPlayerRankingEntries()
	InitializeRankingDatabase()
	local rankings = addonDB and addonDB.rankings
	local playerRankings = rankings and rankings.players
	if not playerRankings then
		return {}, 0
	end
	local merged = {}
	for _, roleKey in ipairs(GetActivePlayerRoleKeys()) do
		local category = playerRankings.categories[roleKey]
		for key, source in pairs(category and category.entries or {}) do
			local entry = merged[key]
			if not entry then
				entry = {
					key = key,
					name = source.name,
					guid = source.guid,
					level = source.level,
					classToken = source.classToken,
					role = roleKey,
					scoreSum = 0,
					scoreWeight = 0,
					appearances = 0,
					participationTotal = 0,
					comparableBGs = 0,
					nearTopBGs = 0,
					top1Finishes = 0,
					specializations = {},
				}
				merged[key] = entry
			end
			entry.name = source.name or entry.name
			entry.guid = source.guid or entry.guid
			entry.level = source.level or entry.level
			entry.classToken = source.classToken or entry.classToken
			entry.scoreSum = entry.scoreSum + (tonumber(source.scoreSum) or 0)
			entry.scoreWeight = entry.scoreWeight + (tonumber(source.scoreWeight) or 0)
			entry.appearances = entry.appearances + (tonumber(source.appearances) or 0)
			entry.participationTotal = entry.participationTotal
				+ (tonumber(source.participationTotal)
					or tonumber(source.appearances) or 0)
			entry.lastSeen = math.max(
				tonumber(entry.lastSeen) or 0,
				tonumber(source.lastSeen) or 0
			)
			entry.comparableBGs = entry.comparableBGs
				+ (tonumber(source.comparableBGs) or 0)
			entry.nearTopBGs = entry.nearTopBGs + (tonumber(source.nearTopBGs) or 0)
			entry.top1Finishes = entry.top1Finishes
				+ (tonumber(source.top1Finishes) or 0)
			if (tonumber(source.appearances) or 0)
				>= (tonumber(entry.primaryRoleAppearances) or 0)
			then
				entry.role = roleKey
				entry.primaryRoleAppearances = tonumber(source.appearances) or 0
				entry.lastScore = source.lastScore
				entry.lastDamage = source.lastDamage
				entry.lastHealing = source.lastHealing
				entry.lastDeaths = source.lastDeaths
				entry.lastObjectives = source.lastObjectives
				entry.lastUtility = source.lastUtility
				entry.lastLevel = source.lastLevel
				entry.lastLevelFactor = source.lastLevelFactor
				entry.lastLevelReference = source.lastLevelReference
				entry.lastParticipationRatio = source.lastParticipationRatio
				entry.normalizationVersion = source.normalizationVersion
			end
			MergePlayerSpecializations(entry, source)
		end
	end

	local query = ui.playerSearchBox and NormalizePlayerName(ui.playerSearchBox:GetText())
	query = query and string.gsub(query, "^%s+", "")
	query = query and string.gsub(query, "%s+$", "")
	local rankedEntries = {}
	local provisionalEntries = {}
	for _, entry in pairs(merged) do
		if entry.scoreWeight > 0 and entry.appearances > 0 then
			local rawScore = entry.scoreSum / entry.scoreWeight
			local reliability = entry.scoreWeight
				/ (entry.scoreWeight + PLAYER_RANKING_PRIOR_MATCHES)
			entry.rawScore = rawScore
			entry.smoothedScore = 100 + (rawScore - 100) * reliability
			-- Une estimation ramenee vers 100 favorise sinon artificiellement les
			-- nouveaux joueurs : avec un seul BG, meme une performance moyenne peut
			-- passer devant un joueur deja mesure plusieurs fois. Le classement
			-- utilise donc une borne prudente dont la marge disparait avec les BG.
			entry.uncertaintyMargin = PLAYER_RANKING_UNCERTAINTY_MARGIN
				/ math.sqrt(math.max(entry.scoreWeight, 0.25))
			entry.score = entry.smoothedScore - entry.uncertaintyMargin
			entry.averageParticipation = entry.appearances > 0
				and entry.participationTotal / entry.appearances or 1
			entry.regularityAvailable = entry.comparableBGs > 0
			entry.regularity = entry.regularityAvailable
				and (100 * entry.nearTopBGs / entry.comparableBGs) or 0
			entry.confidence, entry.confidenceColor =
				GetPlayerConfidence(entry.appearances)
			entry.placementComplete =
				entry.appearances >= PLAYER_RANKING_PLACEMENT_MATCHES
			if entry.placementComplete then
				rankedEntries[#rankedEntries + 1] = entry
			else
				entry.confidence = string.format(
					"Placement %d/%d",
					entry.appearances,
					PLAYER_RANKING_PLACEMENT_MATCHES
				)
				entry.confidenceColor = { 0.95, 0.62, 0.18 }
				provisionalEntries[#provisionalEntries + 1] = entry
			end
		end
	end
	local function SortPlayerEntries(left, right)
		if math.abs(left.score - right.score) > RANKING_POINT_EPSILON then
			return left.score > right.score
		end
		if left.regularity ~= right.regularity then
			return left.regularity > right.regularity
		end
		if left.appearances ~= right.appearances then
			return left.appearances > right.appearances
		end
		return tostring(left.name or "") < tostring(right.name or "")
	end
	table.sort(rankedEntries, SortPlayerEntries)
	table.sort(provisionalEntries, SortPlayerEntries)
	local allEntries = {}
	for _, entry in ipairs(rankedEntries) do
		allEntries[#allEntries + 1] = entry
	end
	for _, entry in ipairs(provisionalEntries) do
		allEntries[#allEntries + 1] = entry
	end
	local entries = {}
	for index, entry in ipairs(allEntries) do
		entry.overallRank = entry.placementComplete and index or nil
		local normalizedName = NormalizePlayerName(entry.name) or ""
		if not query or query == ""
			or string.find(normalizedName, query, 1, true)
		then
			entries[#entries + 1] = entry
		end
	end
	local leader = rankedEntries[1] or provisionalEntries[1]
	return entries, #rankedEntries, leader and leader.score or 100
end

local function SetPlayerRankBadge(row, rank)
	if not rank then
		row.rankText:SetText("-")
		row.rankIcon:SetVertexColor(0.36, 0.40, 0.48)
		return
	end
	row.rankText:SetText(tostring(rank))
	if rank == 1 then
		row.rankIcon:SetVertexColor(1, 0.76, 0.12)
	elseif rank == 2 then
		row.rankIcon:SetVertexColor(0.78, 0.84, 0.92)
	elseif rank == 3 then
		row.rankIcon:SetVertexColor(0.82, 0.44, 0.18)
	else
		row.rankIcon:SetVertexColor(0.36, 0.40, 0.48)
	end
end

local function CreatePlayerRankingRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetFrameLevel(parent:GetFrameLevel() + 2)
	local offsetY = -132 - ((index - 1) * RANKING_ROW_HEIGHT)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", RANKING_TABLE_LEFT_INSET, offsetY)
	row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -RANKING_TABLE_RIGHT_INSET, offsetY)
	row:SetHeight(RANKING_ROW_HEIGHT - 2)
	row.background = CreateSolidTexture(
		row,
		"BACKGROUND",
		index % 2 == 0 and 0.075 or 0.055,
		index % 2 == 0 and 0.08 or 0.06,
		index % 2 == 0 and 0.095 or 0.075,
		0.96
	)
	row.background:SetAllPoints(row)
	row.progress = CreateSolidTexture(row, "BORDER", 0.68, 0.43, 0.95, 0.17)
	row.progress:SetPoint("TOPLEFT")
	row.progress:SetPoint("BOTTOMLEFT")
	row.progress:SetWidth(1)

	row.rankIcon = row:CreateTexture(nil, "OVERLAY")
	row.rankIcon:SetTexture("Interface\\AchievementFrame\\UI-Achievement-TinyShield")
	row.rankIcon:SetWidth(25)
	row.rankIcon:SetHeight(25)
	row.rankIcon:SetPoint("LEFT", 6, 0)
	row.rankText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.rankText:SetPoint("CENTER", row.rankIcon, "CENTER", 0, 0)

	row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.nameText:SetPoint("LEFT", 42, 0)
	row.nameText:SetWidth(148)
	row.nameText:SetJustifyH("LEFT")
	row.nameText:SetWordWrap(false)

	row.specButton = CreateFrame("Button", nil, row)
	row.specButton:SetWidth(24)
	row.specButton:SetHeight(24)
	row.specButton:SetPoint("LEFT", 194, 0)
	row.specButton.texture = row.specButton:CreateTexture(nil, "OVERLAY")
	row.specButton.texture:SetAllPoints()
	row.specButton:SetScript("OnEnter", function(self)
		local entry = self.entry
		if not entry then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Specialisations observees", 1, 0.82, 0.20)
		local specializations = {}
		for _, specialization in pairs(entry.specializations or {}) do
			specializations[#specializations + 1] = specialization
		end
		table.sort(specializations, function(left, right)
			return (tonumber(left.appearances) or 0)
				> (tonumber(right.appearances) or 0)
		end)
		for _, specialization in ipairs(specializations) do
			GameTooltip:AddLine(
				GetRankingClassName(specialization.classToken)
					.. " - " .. tostring(specialization.specialization or "?")
					.. " : " .. tostring(specialization.appearances or 0) .. " BG",
				1,
				1,
				1
			)
		end
		GameTooltip:Show()
	end)
	row.specButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

	row.lastSeenText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.lastSeenText:SetPoint("LEFT", 238, 0)
	row.lastSeenText:SetWidth(142)
	row.lastSeenText:SetJustifyH("LEFT")
	row.lastSeenText:SetWordWrap(false)

	row.scoreText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	row.scoreText:SetPoint("RIGHT", -315, 0)
	row.scoreText:SetWidth(62)
	row.scoreText:SetJustifyH("RIGHT")
	row.regularityText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.regularityText:SetPoint("RIGHT", -220, 0)
	row.regularityText:SetWidth(72)
	row.regularityText:SetJustifyH("RIGHT")
	row.matchesText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.matchesText:SetPoint("RIGHT", -145, 0)
	row.matchesText:SetWidth(46)
	row.matchesText:SetJustifyH("RIGHT")
	row.confidenceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.confidenceText:SetPoint("RIGHT", -8, 0)
	row.confidenceText:SetWidth(118)
	row.confidenceText:SetJustifyH("RIGHT")

	row:EnableMouse(true)
	row:SetScript("OnEnter", function(self)
		local entry = self.entry
		if not entry then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(tostring(entry.name or "Joueur"), 1, 0.82, 0.20)
		GameTooltip:AddLine(
			string.format("Score classant : %.1f", entry.score),
			1,
			1,
			1
		)
		GameTooltip:AddLine(
			string.format(
				"Estimation lissee : %.1f (brut %.1f)",
				entry.smoothedScore,
				entry.rawScore
			),
			0.72,
			0.80,
			0.90
		)
		GameTooltip:AddLine(
			string.format(
				"Marge d'incertitude : -%.1f point(s)",
				entry.uncertaintyMargin
			),
			0.72,
			0.80,
			0.90
		)
		GameTooltip:AddLine(
			entry.regularityAvailable
				and string.format("Regularite : %.1f%% (%d/%d BG comparables)", entry.regularity, entry.nearTopBGs, entry.comparableBGs)
				or "Regularite : en attente d'un adversaire du meme role",
			0.72,
			0.80,
			0.90
		)
		GameTooltip:AddLine("Top du role : " .. tostring(entry.top1Finishes or 0), 0.72, 0.80, 0.90)
		GameTooltip:AddLine(
			"Derniere rencontre : " .. FormatPlayerLastSeen(entry.lastSeen),
			0.72,
			0.80,
			0.90
		)
		if entry.lastParticipationRatio then
			GameTooltip:AddLine(
				string.format(
					"Presence au dernier BG : %.0f%%",
					100 * entry.lastParticipationRatio
				),
				0.72,
				0.80,
				0.90
			)
		end
		if entry.lastLevel and entry.lastLevelReference and entry.lastLevelFactor then
			GameTooltip:AddLine(
				string.format(
					"Dernier BG : niveau %d, mediane du role %.1f, coefficient x%.2f",
					entry.lastLevel,
					entry.lastLevelReference,
					entry.lastLevelFactor
				),
				0.72,
				0.80,
				0.90
			)
		end
		if not entry.placementComplete then
			GameTooltip:AddLine(
				string.format(
					"Placement : %d/%d BG valides avant le rang officiel.",
					entry.appearances,
					PLAYER_RANKING_PLACEMENT_MATCHES
				),
				0.95,
				0.62,
				0.18,
				true
			)
		end
		GameTooltip:AddLine("Confiance : " .. tostring(entry.confidence), 0.72, 0.80, 0.90)
		GameTooltip:AddLine("Le coefficient de stomp reduit l'influence du BG entier, jamais celle d'un joueur seul.", 0.58, 0.64, 0.72, true)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row:Hide()
	return row
end

local function RebuildPlayerSearchIndex()
	if not ui.playerSearchIndexDirty then
		return
	end
	ui.playerSearchIndex = {}
	local unique = {}
	local playerRankings = addonDB and addonDB.rankings
		and addonDB.rankings.players
	for roleKey, category in pairs(playerRankings and playerRankings.categories or {}) do
		for key, entry in pairs(category.entries or {}) do
			local candidate = unique[key]
			if not candidate or (tonumber(entry.appearances) or 0)
				> (tonumber(candidate.appearances) or 0)
			then
				unique[key] = {
					key = key,
					name = entry.name,
					classToken = entry.classToken,
					specialization = entry.specialization,
					role = roleKey,
					appearances = tonumber(entry.appearances) or 0,
				}
			end
		end
	end
	for _, candidate in pairs(unique) do
		ui.playerSearchIndex[#ui.playerSearchIndex + 1] = candidate
	end
	table.sort(ui.playerSearchIndex, function(left, right)
		return tostring(left.name or "") < tostring(right.name or "")
	end)
	ui.playerSearchIndexDirty = false
end

local function SetSearchSuggestionHighlight()
	for index, button in ipairs(ui.playerSearchSuggestionButtons) do
		button.background:SetVertexColor(
			0.15,
			0.17,
			0.22,
			index == ui.playerSearchSelection and 1 or 0.92
		)
	end
end

local function SelectPlayerSearchSuggestion(index)
	local suggestion = ui.playerSearchSuggestions[index]
	if not suggestion or not ui.playerSearchBox then
		return
	end
	if suggestion.role == "HEALER" then
		ui.activePlayerRankingCategory = "healing"
	elseif suggestion.role == "TANK" then
		ui.activePlayerRankingCategory = "tank"
	elseif suggestion.role == "SUPPORT" then
		ui.activePlayerRankingCategory = "support"
	else
		ui.activePlayerRankingCategory = "dps"
		ui.activePlayerDpsFilter = "all"
		if ui.playerDpsFilterDropdown then
			UIDropDownMenu_SetSelectedValue(ui.playerDpsFilterDropdown, "all")
			UIDropDownMenu_SetText(ui.playerDpsFilterDropdown, "Tous DPS")
		end
	end
	ui.playerSearchBox:SetText(tostring(suggestion.name or ""))
	ui.playerSearchBox:ClearFocus()
	ui.playerSearchSuggestionsFrame:Hide()
	ui.SetPlayerRankingCategory(ui.activePlayerRankingCategory)
end

local function RefreshPlayerSearchSuggestions()
	if not ui.playerSearchSuggestionsFrame or not ui.playerSearchBox then
		return
	end
	RebuildPlayerSearchIndex()
	local query = NormalizePlayerName(ui.playerSearchBox:GetText()) or ""
	query = string.gsub(query, "^%s+", "")
	query = string.gsub(query, "%s+$", "")
	ui.playerSearchSuggestions = {}
	if string.len(query) < 2 then
		ui.playerSearchSuggestionsFrame:Hide()
		return
	end
	local matches = {}
	for _, candidate in ipairs(ui.playerSearchIndex) do
		local name = NormalizePlayerName(candidate.name) or ""
		local position = string.find(name, query, 1, true)
		if position then
			candidate.searchPriority = position == 1 and 0 or 1
			matches[#matches + 1] = candidate
		end
	end
	table.sort(matches, function(left, right)
		if left.searchPriority ~= right.searchPriority then
			return left.searchPriority < right.searchPriority
		end
		if left.appearances ~= right.appearances then
			return left.appearances > right.appearances
		end
		return tostring(left.name or "") < tostring(right.name or "")
	end)
	for index = 1, math.min(#matches, PLAYER_SEARCH_MAX_SUGGESTIONS) do
		ui.playerSearchSuggestions[index] = matches[index]
	end
	ui.playerSearchSelection = #ui.playerSearchSuggestions > 0 and 1 or 0
	for index, button in ipairs(ui.playerSearchSuggestionButtons) do
		local suggestion = ui.playerSearchSuggestions[index]
		if suggestion then
			button.suggestionIndex = index
			button.nameText:SetText(tostring(suggestion.name or "?"))
			local color = RAID_CLASS_COLORS[suggestion.classToken]
				or { r = 0.86, g = 0.86, b = 0.86 }
			button.nameText:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
			button.detailText:SetText(
				tostring(PLAYER_ROLE_LABELS[suggestion.role] or "Role")
					.. " - " .. tostring(suggestion.appearances or 0) .. " BG"
			)
			button:Show()
		else
			button:Hide()
		end
	end
	SetSearchSuggestionHighlight()
	if #ui.playerSearchSuggestions > 0 then
		ui.playerSearchSuggestionsFrame:SetHeight(#ui.playerSearchSuggestions * 24 + 6)
		ui.playerSearchSuggestionsFrame:Show()
	else
		ui.playerSearchSuggestionsFrame:Hide()
	end
end

ui.RefreshPlayerRankingPanel = function()
	if not addonDB or not ui.playerRankingPanel or not ui.playerRankingScrollFrame then
		return
	end
	local entries, totalPlayers, leaderScore = BuildPlayerRankingEntries()
	local rankings = addonDB.rankings
	local playerRankings = rankings.players
	local totalBGs = tonumber(playerRankings.totalBattlegrounds) or 0
	local averageMatchWeight = (tonumber(rankings.stompEvaluatedBGs) or 0) > 0
		and (tonumber(rankings.matchWeightTotal) or 0)
			/ (tonumber(rankings.stompEvaluatedBGs) or 1) * 100
		or 0
	ui.playerRankingSummaryAnalyzed.value:SetText(tostring(totalBGs))
	ui.playerRankingSummaryBalance.value:SetText(string.format("%.0f%%", averageMatchWeight))
	ui.playerRankingSummaryPlayers.value:SetText(tostring(totalPlayers))
	ui.playerRankingMethodologyText:SetText(
		"Rang officiel apres 3 BG valides. Les arrivees en cours de partie sont corrigees au temps joue et pesent moins dans l'historique ; moins de 25% de presence ou une activite principale nulle sont ignores."
	)

	local visibleRows = GetVisibleRowCount(
		ui.playerRankingScrollFrame,
		RANKING_ROW_HEIGHT,
		RANKING_MAX_VISIBLE_ROWS
	)
	FauxScrollFrame_Update(
		ui.playerRankingScrollFrame,
		#entries,
		visibleRows,
		RANKING_ROW_HEIGHT
	)
	local offset = FauxScrollFrame_GetOffset(ui.playerRankingScrollFrame) or 0
	for rowIndex = 1, RANKING_MAX_VISIBLE_ROWS do
		local row = ui.playerRankingRows[rowIndex]
		local rankingIndex = offset + rowIndex
		local entry = rowIndex <= visibleRows and entries[rankingIndex]
		if entry then
			row.entry = entry
			row.specButton.entry = entry
			SetPlayerRankBadge(row, entry.overallRank)
			local color = RAID_CLASS_COLORS[entry.classToken]
				or { r = 0.86, g = 0.86, b = 0.86 }
			row.nameText:SetText(tostring(entry.name or "Joueur"))
			row.nameText:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
			ApplySpecializationTexture(row.specButton.texture, entry, true)
			row.lastSeenText:SetText(FormatPlayerLastSeen(entry.lastSeen))
			row.scoreText:SetText(string.format("%.1f", entry.score))
			row.regularityText:SetText(
				entry.regularityAvailable and string.format("%.0f%%", entry.regularity)
					or "--"
			)
			row.matchesText:SetText(tostring(entry.appearances))
			row.confidenceText:SetText(entry.confidence)
			row.confidenceText:SetTextColor(unpack(entry.confidenceColor))
			local relative = leaderScore > 0 and entry.score / leaderScore or 0
			local rowWidth = math.max(1, row:GetWidth() or 1)
			row.progress:SetWidth(math.max(1, math.floor(rowWidth * ClampRankingValue(relative, 0, 1))))
			row:Show()
		else
			row.entry = nil
			row.specButton.entry = nil
			row:Hide()
		end
	end
	if #entries == 0 then
		ui.playerRankingNoDataText:Show()
	else
		ui.playerRankingNoDataText:Hide()
	end
end

ui.RefreshRankingPanel = function()
	if ui.activeRankingMode == "players" then
		ui.RefreshPlayerRankingPanel()
	else
		RefreshSpecializationRankingPanel()
	end
end

local function SetRankingMode(mode)
	ui.activeRankingMode = mode == "players" and "players" or "specializations"
	SetModernTabActive(
		ui.specializationRankingTabButton,
		ui.activeRankingMode == "specializations"
	)
	SetModernTabActive(ui.playerRankingTabButton, ui.activeRankingMode == "players")
	if ui.activeRankingMode == "players" then
		ui.specializationRankingPanel:Hide()
		ui.playerRankingPanel:Show()
		ui.SetPlayerRankingCategory(ui.activePlayerRankingCategory)
	else
		ui.playerRankingPanel:Hide()
		if ui.playerSearchSuggestionsFrame then
			ui.playerSearchSuggestionsFrame:Hide()
		end
		ui.specializationRankingPanel:Show()
		ui.SetRankingCategory(ui.activeRankingCategory)
	end
end

ui.SetRankingCategory = function(categoryKey)
	ui.activeRankingCategory = categoryKey == "healing" and "healing" or "dps"
	SetModernTabActive(ui.damageRankingTabButton, ui.activeRankingCategory == "dps")
	SetModernTabActive(ui.healingRankingTabButton, ui.activeRankingCategory == "healing")
	ui.RefreshRankingPanel()
end

ui.SetPlayerRankingCategory = function(categoryKey)
	if categoryKey == "healing" or categoryKey == "tank"
		or categoryKey == "support"
	then
		ui.activePlayerRankingCategory = categoryKey
	else
		ui.activePlayerRankingCategory = "dps"
	end
	SetModernTabActive(ui.playerDpsTabButton, ui.activePlayerRankingCategory == "dps")
	SetModernTabActive(ui.playerHealingTabButton, ui.activePlayerRankingCategory == "healing")
	SetModernTabActive(ui.playerTankTabButton, ui.activePlayerRankingCategory == "tank")
	SetModernTabActive(ui.playerSupportTabButton, ui.activePlayerRankingCategory == "support")
	if ui.playerDpsFilterDropdown then
		if ui.activePlayerRankingCategory == "dps" then
			ui.playerDpsFilterDropdown:Show()
		else
			ui.playerDpsFilterDropdown:Hide()
		end
	end
	local scrollBar = _G["CoAAnalyticsPlayerRankingScrollFrameScrollBar"]
	if scrollBar then
		scrollBar:SetValue(0)
	end
	ui.RefreshRankingPanel()
end

local function SetSettingsMode(mode)
	if mode == "nameplates" or mode == "raidminimap" then
		ui.activeSettingsMode = mode
	else
		ui.activeSettingsMode = "general"
	end
	SetModernTabActive(
		ui.generalSettingsTabButton,
		ui.activeSettingsMode == "general"
	)
	SetModernTabActive(
		ui.nameplateSettingsTabButton,
		ui.activeSettingsMode == "nameplates"
	)
	SetModernTabActive(
		ui.raidMinimapSettingsTabButton,
		ui.activeSettingsMode == "raidminimap"
	)
	if ui.generalSettingsPanel then
		if ui.activeSettingsMode == "general" then
			ui.generalSettingsPanel:Show()
		else
			ui.generalSettingsPanel:Hide()
		end
	end
	if ui.nameplateOptionsPanel then
		if ui.activeSettingsMode == "nameplates" then
			ui.nameplateOptionsPanel:Show()
		else
			ui.nameplateOptionsPanel:Hide()
		end
	end
	if ui.raidMinimapOptionsPanel then
		if ui.activeSettingsMode == "raidminimap" then
			ui.raidMinimapOptionsPanel:Show()
		else
			ui.raidMinimapOptionsPanel:Hide()
		end
	end
end

function UI.RefreshMythicResetCard()
	if not ui.mythicResetStatusText then
		return
	end
	local module = CoAAnalyticsAddon.Modules.MythicReset
	local status = module and module.GetStatus and module.GetStatus()
	if not status then
		ui.mythicResetStatusText:SetText("Heure non disponible")
		ui.mythicResetStatusText:SetTextColor(0.95, 0.55, 0.20)
		ui.mythicResetDetailText:SetText(
			"Le module de suivi n'est pas charge. Fais /reload puis reouvre cette page."
		)
		return
	end
	ui.mythicResetStatusText:SetText(status.text)
	if status.known and status.confidence == "direct" then
		ui.mythicResetStatusText:SetTextColor(0.18, 0.90, 0.45)
	elseif status.known then
		ui.mythicResetStatusText:SetTextColor(0.95, 0.78, 0.18)
	else
		ui.mythicResetStatusText:SetTextColor(0.95, 0.55, 0.20)
	end
	local detail = status.detail or ""
	if status.counterText then
		detail = status.counterText .. "\n" .. detail
	end
	ui.mythicResetDetailText:SetText(detail)
end

local function SetSettingsSection(section)
	if section == "nameplates" then
		ui.activeSettingsMode = "nameplates"
		section = "settings"
	elseif section == "ranking" or section == "pve" or section == "pvesession" then
		ui.activePerformanceTab = section
		section = "performance"
	elseif section ~= "home" and section ~= "performance"
		and section ~= "advisor" and section ~= "loot"
		and section ~= "combat" and section ~= "collection"
		and section ~= "settings"
	then
		section = "home"
	end
	ui.activeSettingsTab = section
	SetModernTabActive(ui.homeTabButton, section == "home")
	SetModernTabActive(ui.performanceTabButton, section == "performance")
	SetModernTabActive(ui.advisorTabButton, section == "advisor")
	SetModernTabActive(ui.lootTabButton, section == "loot")
	SetModernTabActive(ui.combatTabButton, section == "combat")
	SetModernTabActive(ui.collectionTabButton, section == "collection")
	SetModernTabActive(ui.nameplateTabButton, section == "settings")
	SetModernTabActive(ui.rankingTabButton, ui.activePerformanceTab == "ranking")
	SetModernTabActive(ui.pveRankingTabButton, ui.activePerformanceTab == "pve")
	SetModernTabActive(ui.pveSessionTabButton, ui.activePerformanceTab == "pvesession")
	-- Toujours repartir d'un etat exclusif. Si un module optionnel manque ou si
	-- une creation precedente a ete interrompue, aucun panneau ne doit rester
	-- superpose au panneau actif.
	ui.nameplateSettingsPanel:Hide()
	ui.dashboardPanel:Hide()
	ui.performanceNavigationPanel:Hide()
	ui.advisorHostPanel:Hide()
	ui.combatPanel:Hide()
	ui.rankingPanel:Hide()
	if ui.pveRankingPanel then
		ui.pveRankingPanel:Hide()
	end
	if ui.pveSessionPanel then
		ui.pveSessionPanel:Hide()
	end
	if section == "home" then
		ui.dashboardPanel:Show()
		UI.RefreshMythicResetCard()
	elseif section == "performance" then
		ui.performanceNavigationPanel:Show()
		if ui.activePerformanceTab == "ranking" then
			ui.rankingPanel:Show()
			SetRankingMode(ui.activeRankingMode)
		elseif ui.activePerformanceTab == "pve" then
			if ui.pveRankingPanel then
				ui.pveRankingPanel:Show()
				if CoAAnalyticsPvE and CoAAnalyticsPvE.RefreshPanel then
					CoAAnalyticsPvE.RefreshPanel()
				end
			end
		elseif ui.pveSessionPanel then
			ui.pveSessionPanel:Show()
			if CoAAnalyticsPvE and CoAAnalyticsPvE.RefreshSessionPanel then
				CoAAnalyticsPvE.RefreshSessionPanel()
			end
		end
	elseif section == "advisor" or section == "loot" or section == "collection" then
		ui.advisorHostPanel:Show()
		local advisorUI = CoAAnalyticsAddon.Advisor and CoAAnalyticsAddon.Advisor.UI
		if advisorUI then
			advisorUI.Attach(ui.advisorHostPanel)
			advisorUI.SelectTab(
				section == "loot" and "autoloot"
				or section == "collection" and "dataprobe"
				or "advisor"
			)
		end
	elseif section == "combat" then
		ui.combatPanel:Show()
		if UI.RefreshCombatPanel then UI.RefreshCombatPanel() end
	elseif section == "settings" then
		ui.nameplateSettingsPanel:Show()
		SetSettingsMode(ui.activeSettingsMode)
	end
end

local function CreateSettingsFrame()
	if ui.settingsFrame then
		return ui.settingsFrame
	end

	local frame = CreateFrame(
		"Frame",
		"CoAAnalyticsSettingsFrame",
		UIParent
	)
	-- Un Frame nouvellement cree est visible par defaut. Le masquer tout de
	-- suite evite une interface partielle si une API du client est absente.
	frame:Hide()
	frame:SetWidth(960)
	frame:SetHeight(820)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 14,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0.025, 0.028, 0.038, 0.98)
	frame:SetBackdropBorderColor(0.20, 0.22, 0.27, 1)

	local titleAccent = CreateSolidTexture(frame, "ARTWORK", 0.10, 0.72, 0.52, 1)
	titleAccent:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -42)
	titleAccent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -42)
	titleAccent:SetHeight(1)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -17)
	title:SetText("CoA Analytics")

	local version = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	version:SetPoint("LEFT", title, "RIGHT", 8, -1)
	version:SetText("v" .. ADDON_VERSION)

	CreateLanguageFlagButton(frame, "fr", -80)
	CreateLanguageFlagButton(frame, "en", -42)
	RefreshLanguageButtons()

	local function CreateSidebarTab(label, y, r, g, b)
		local button = CreateModernTab(frame, label, r, g, b)
		button:SetWidth(142)
		button:SetHeight(32)
		button:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, y)
		return button
	end

	ui.homeTabButton = CreateSidebarTab("Accueil", -58, 0.10, 0.72, 0.52)
	ui.performanceTabButton = CreateSidebarTab("Performances", -98, 0.95, 0.61, 0.12)
	ui.advisorTabButton = CreateSidebarTab("Conseils", -138, 1.00, 0.82, 0.20)
	ui.lootTabButton = CreateSidebarTab("Butin", -178, 0.85, 0.48, 0.20)
	ui.combatTabButton = CreateSidebarTab("Combat", -218, 0.86, 0.25, 0.28)
	ui.collectionTabButton = CreateSidebarTab("Collecte", -258, 0.68, 0.43, 0.95)
	ui.nameplateTabButton = CreateSidebarTab("Parametres", -298, 0.10, 0.72, 0.52)

	local sidebarDivider = CreateSolidTexture(frame, "ARTWORK", 0.20, 0.22, 0.27, 1)
	sidebarDivider:SetPoint("TOPLEFT", frame, "TOPLEFT", 169, -52)
	sidebarDivider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 169, 18)
	sidebarDivider:SetWidth(1)

	ui.performanceNavigationPanel = CreateFrame("Frame", nil, frame)
	ui.performanceNavigationPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 184, -52)
	ui.performanceNavigationPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -52)
	ui.performanceNavigationPanel:SetHeight(34)
	ui.performanceNavigationPanel:Hide()
	ui.rankingTabButton = CreateModernTab(ui.performanceNavigationPanel, "BG", 0.95, 0.61, 0.12)
	ui.rankingTabButton:SetWidth(140)
	ui.rankingTabButton:SetPoint("TOPLEFT", ui.performanceNavigationPanel, "TOPLEFT", 0, 0)
	ui.pveRankingTabButton = CreateModernTab(ui.performanceNavigationPanel, "Classement PvE", 0.30, 0.62, 0.95)
	ui.pveRankingTabButton:SetWidth(155)
	ui.pveRankingTabButton:SetPoint("LEFT", ui.rankingTabButton, "RIGHT", 8, 0)
	ui.pveSessionTabButton = CreateModernTab(ui.performanceNavigationPanel, "Session PvE", 0.68, 0.43, 0.95)
	ui.pveSessionTabButton:SetWidth(145)
	ui.pveSessionTabButton:SetPoint("LEFT", ui.pveRankingTabButton, "RIGHT", 8, 0)

	ui.dashboardPanel = CreateFrame("Frame", nil, frame)
	ui.dashboardPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 184, -58)
	ui.dashboardPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
	ui.dashboardPanel:Hide()
	local dashboardTitle = ui.dashboardPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	dashboardTitle:SetPoint("TOPLEFT", ui.dashboardPanel, "TOPLEFT", 10, -8)
	dashboardTitle:SetText("Vue d'ensemble")
	local dashboardDescription = ui.dashboardPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	dashboardDescription:SetPoint("TOPLEFT", dashboardTitle, "BOTTOMLEFT", 0, -10)
	dashboardDescription:SetWidth(700)
	dashboardDescription:SetJustifyH("LEFT")
	dashboardDescription:SetText(
		"Un seul espace pour mesurer les performances, ameliorer le personnage, gerer le butin et contribuer aux donnees communautaires."
	)
	local dashboardItems = {
		{ "Performances", "Classements BG, donjons, raids et session en cours.", "performance", 0.95, 0.61, 0.12 },
		{ "Conseils", "Talents, priorites et comparaison d'equipement adaptes au personnage.", "advisor", 1.00, 0.82, 0.20 },
		{ "Butin", "Compatibilite des objets et regles de jets automatiques.", "loot", 0.85, 0.48, 0.20 },
		{ "Collecte", "DataProbe reste optionnel et charge uniquement a la demande.", "collection", 0.68, 0.43, 0.95 },
	}
	for index, item in ipairs(dashboardItems) do
		local card = CreateFrame("Frame", nil, ui.dashboardPanel)
		card:SetWidth(350)
		card:SetHeight(150)
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		card:SetPoint("TOPLEFT", ui.dashboardPanel, "TOPLEFT", 10 + column * 366, -222 - row * 168)
		card:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 10,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		card:SetBackdropColor(0.05, 0.055, 0.07, 0.96)
		card:SetBackdropBorderColor(item[4], item[5], item[6], 0.8)
		local cardTitle = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		cardTitle:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -16)
		cardTitle:SetText(item[1])
		local cardText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		cardText:SetPoint("TOPLEFT", cardTitle, "BOTTOMLEFT", 0, -10)
		cardText:SetWidth(315)
		cardText:SetHeight(48)
		cardText:SetJustifyH("LEFT")
		cardText:SetJustifyV("TOP")
		cardText:SetWordWrap(true)
		cardText:SetText(item[2])
		local openButton = CreateModernTab(card, "Ouvrir", item[4], item[5], item[6])
		openButton:SetWidth(110)
		openButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -14, 14)
		local targetSection = item[3]
		openButton:SetScript("OnClick", function() SetSettingsSection(targetSection) end)
	end

	local resetCard = CreateFrame("Frame", nil, ui.dashboardPanel)
	resetCard:SetPoint("TOPLEFT", ui.dashboardPanel, "TOPLEFT", 10, -82)
	resetCard:SetPoint("TOPRIGHT", ui.dashboardPanel, "TOPRIGHT", -10, -82)
	resetCard:SetHeight(126)
	resetCard:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 10,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	resetCard:SetBackdropColor(0.05, 0.055, 0.07, 0.96)
	resetCard:SetBackdropBorderColor(0.30, 0.72, 0.95, 0.8)
	local resetTitle = resetCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	resetTitle:SetPoint("TOPLEFT", resetCard, "TOPLEFT", 16, -14)
	resetTitle:SetText("Plafonds Mythic+")
	ui.mythicResetStatusText = resetCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ui.mythicResetStatusText:SetPoint("TOPLEFT", resetTitle, "BOTTOMLEFT", 0, -9)
	ui.mythicResetStatusText:SetWidth(535)
	ui.mythicResetStatusText:SetJustifyH("LEFT")
	ui.mythicResetDetailText = resetCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	ui.mythicResetDetailText:SetPoint("TOPLEFT", ui.mythicResetStatusText, "BOTTOMLEFT", 0, -7)
	ui.mythicResetDetailText:SetWidth(535)
	ui.mythicResetDetailText:SetHeight(44)
	ui.mythicResetDetailText:SetJustifyH("LEFT")
	ui.mythicResetDetailText:SetJustifyV("TOP")
	ui.mythicResetDetailText:SetWordWrap(true)
	local refreshResetButton = CreateModernTab(resetCard, "Actualiser", 0.30, 0.72, 0.95)
	refreshResetButton:SetWidth(125)
	refreshResetButton:SetPoint("RIGHT", resetCard, "RIGHT", -16, 0)
	refreshResetButton:SetScript("OnClick", function()
		local module = CoAAnalyticsAddon.Modules.MythicReset
		if module and module.RequestRefresh then
			module.RequestRefresh(false)
		end
	end)
	UI.RefreshMythicResetCard()

	ui.advisorHostPanel = CreateFrame("Frame", nil, frame)
	ui.advisorHostPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 184, -52)
	ui.advisorHostPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
	ui.advisorHostPanel:Hide()

	ui.combatPanel = CreateFrame("Frame", nil, frame)
	ui.combatPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 184, -58)
	ui.combatPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
	ui.combatPanel:Hide()
	local combatTitle = ui.combatPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	combatTitle:SetPoint("TOPLEFT", ui.combatPanel, "TOPLEFT", 10, -8)
	combatTitle:SetText("Analyse de combat")
	local combatIntro = ui.combatPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	combatIntro:SetPoint("TOPLEFT", combatTitle, "BOTTOMLEFT", 0, -12)
	combatIntro:SetWidth(710)
	combatIntro:SetJustifyH("LEFT")
	combatIntro:SetText(
		"Les deux collecteurs restent independants : les performances mesurent le groupe, tandis que les conseils calibrent uniquement ton personnage."
	)
	ui.combatPerformanceText = ui.combatPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	ui.combatPerformanceText:SetPoint("TOPLEFT", ui.combatPanel, "TOPLEFT", 24, -115)
	ui.combatPerformanceText:SetWidth(680)
	ui.combatPerformanceText:SetHeight(100)
	ui.combatPerformanceText:SetJustifyH("LEFT")
	ui.combatPerformanceText:SetJustifyV("TOP")
	ui.combatAdvisorText = ui.combatPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	ui.combatAdvisorText:SetPoint("TOPLEFT", ui.combatPanel, "TOPLEFT", 24, -260)
	ui.combatAdvisorText:SetWidth(680)
	ui.combatAdvisorText:SetHeight(150)
	ui.combatAdvisorText:SetJustifyH("LEFT")
	ui.combatAdvisorText:SetJustifyV("TOP")
	local openPerformanceButton = CreateModernTab(ui.combatPanel, "Voir les performances", 0.95, 0.61, 0.12)
	openPerformanceButton:SetWidth(180)
	openPerformanceButton:SetPoint("TOPLEFT", ui.combatPanel, "TOPLEFT", 24, -205)
	openPerformanceButton:SetScript("OnClick", function() SetSettingsSection("performance") end)
	ui.toggleLocalAnalysisButton = CreateModernTab(ui.combatPanel, "Analyse locale", 0.10, 0.72, 0.52)
	ui.toggleLocalAnalysisButton:SetWidth(170)
	ui.toggleLocalAnalysisButton:SetPoint("TOPLEFT", ui.combatPanel, "TOPLEFT", 24, -430)
	ui.toggleLocalAnalysisButton:SetScript("OnClick", function()
		local advisor = CoAAnalyticsAddon.Advisor
		if advisor and advisor.LocalAnalyzer then
			advisor.LocalAnalyzer.SetEnabled(not advisor.LocalAnalyzer.IsEnabled())
			UI.RefreshCombatPanel()
		end
	end)
	local resetCombatButton = CreateModernTab(ui.combatPanel, "Effacer l'historique", 0.86, 0.25, 0.28)
	resetCombatButton:SetWidth(170)
	resetCombatButton:SetPoint("LEFT", ui.toggleLocalAnalysisButton, "RIGHT", 10, 0)
	resetCombatButton:SetScript("OnClick", function()
		local advisor = CoAAnalyticsAddon.Advisor
		if advisor and advisor.LocalAnalyzer then advisor.LocalAnalyzer.Reset() end
		if advisor and advisor.CombatProfiler then advisor.CombatProfiler.Reset() end
		UI.RefreshCombatPanel()
	end)

	ui.nameplateSettingsPanel = CreateFrame("Frame", nil, frame)
	ui.nameplateSettingsPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 184, -52)
	ui.nameplateSettingsPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
	ui.nameplateSettingsPanel:Hide()

	ui.generalSettingsTabButton = CreateModernTab(
		ui.nameplateSettingsPanel,
		"General",
		0.10,
		0.72,
		0.52
	)
	ui.generalSettingsTabButton:SetWidth(150)
	ui.generalSettingsTabButton:SetPoint(
		"TOPLEFT",
		ui.nameplateSettingsPanel,
		"TOPLEFT",
		8,
		-6
	)
	ui.nameplateSettingsTabButton = CreateModernTab(
		ui.nameplateSettingsPanel,
		"Nameplates",
		0.10,
		0.72,
		0.52
	)
	ui.nameplateSettingsTabButton:SetWidth(150)
	ui.nameplateSettingsTabButton:SetPoint(
		"LEFT",
		ui.generalSettingsTabButton,
		"RIGHT",
		7,
		0
	)
	ui.raidMinimapSettingsTabButton = CreateModernTab(
		ui.nameplateSettingsPanel,
		"Minicarte BG",
		0.72,
		0.18,
		1.00
	)
	ui.raidMinimapSettingsTabButton:SetWidth(150)
	ui.raidMinimapSettingsTabButton:SetPoint(
		"LEFT",
		ui.nameplateSettingsTabButton,
		"RIGHT",
		7,
		0
	)

	ui.generalSettingsPanel = CreateFrame("Frame", nil, ui.nameplateSettingsPanel)
	ui.generalSettingsPanel:SetPoint("TOPLEFT", ui.nameplateSettingsPanel, "TOPLEFT", 0, -42)
	ui.generalSettingsPanel:SetPoint("BOTTOMRIGHT", ui.nameplateSettingsPanel, "BOTTOMRIGHT", 0, 0)
	ui.generalSettingsPanel:Hide()
	ui.nameplateOptionsPanel = CreateFrame("Frame", nil, ui.nameplateSettingsPanel)
	ui.nameplateOptionsPanel:SetPoint("TOPLEFT", ui.nameplateSettingsPanel, "TOPLEFT", 0, -42)
	ui.nameplateOptionsPanel:SetPoint("BOTTOMRIGHT", ui.nameplateSettingsPanel, "BOTTOMRIGHT", 0, 0)
	ui.nameplateOptionsPanel:Hide()
	ui.raidMinimapOptionsPanel = CreateFrame(
		"Frame", nil, ui.nameplateSettingsPanel
	)
	ui.raidMinimapOptionsPanel:SetPoint(
		"TOPLEFT", ui.nameplateSettingsPanel, "TOPLEFT", 0, -42
	)
	ui.raidMinimapOptionsPanel:SetPoint(
		"BOTTOMRIGHT", ui.nameplateSettingsPanel, "BOTTOMRIGHT", 0, 0
	)
	ui.raidMinimapOptionsPanel:Hide()

	local raidMinimapCard = CreateFrame(
		"Frame", nil, ui.raidMinimapOptionsPanel
	)
	raidMinimapCard:SetPoint(
		"TOPLEFT", ui.raidMinimapOptionsPanel, "TOPLEFT", 8, -8
	)
	raidMinimapCard:SetPoint(
		"TOPRIGHT", ui.raidMinimapOptionsPanel, "TOPRIGHT", -8, -8
	)
	raidMinimapCard:SetHeight(250)
	raidMinimapCard:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 10,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	raidMinimapCard:SetBackdropColor(0.05, 0.055, 0.07, 0.96)
	raidMinimapCard:SetBackdropBorderColor(0.32, 0.12, 0.46, 1)

	local raidMinimapTitle = raidMinimapCard:CreateFontString(
		nil, "OVERLAY", "GameFontNormalLarge"
	)
	raidMinimapTitle:SetPoint("TOPLEFT", raidMinimapCard, "TOPLEFT", 22, -20)
	raidMinimapTitle:SetText("Raid sur la minicarte")
	local raidMinimapDescription = raidMinimapCard:CreateFontString(
		nil, "OVERLAY", "GameFontHighlightSmall"
	)
	raidMinimapDescription:SetPoint(
		"TOPLEFT", raidMinimapCard, "TOPLEFT", 22, -50
	)
	raidMinimapDescription:SetPoint(
		"TOPRIGHT", raidMinimapCard, "TOPRIGHT", -22, -50
	)
	raidMinimapDescription:SetHeight(54)
	raidMinimapDescription:SetJustifyH("LEFT")
	raidMinimapDescription:SetWordWrap(true)
	raidMinimapDescription:SetText(
		"Affiche en BG les membres des autres sous-groupes en violet et les drapeaux de capture sur la minicarte normale."
	)

	ui.raidMinimapEnabledCheckButton = CreateFrame(
		"CheckButton",
		"CoAAnalyticsRaidMinimapEnabledCheckButton",
		raidMinimapCard,
		"UICheckButtonTemplate"
	)
	ui.raidMinimapEnabledCheckButton:SetWidth(24)
	ui.raidMinimapEnabledCheckButton:SetHeight(24)
	ui.raidMinimapEnabledCheckButton:SetPoint(
		"TOPLEFT", raidMinimapCard, "TOPLEFT", 21, -112
	)
	local raidMinimapEnabledLabel = raidMinimapCard:CreateFontString(
		nil, "OVERLAY", "GameFontHighlight"
	)
	raidMinimapEnabledLabel:SetPoint(
		"LEFT", ui.raidMinimapEnabledCheckButton, "RIGHT", 4, 0
	)
	raidMinimapEnabledLabel:SetText("Afficher le raid et les drapeaux en BG")
	ui.raidMinimapEnabledCheckButton:SetScript("OnClick", function(self)
		local module = CoAAnalyticsAddon.Modules.RaidMinimap
		if module and module.SetEnabled then
			module.SetEnabled(self:GetChecked() and true or false)
		end
	end)

	ui.raidMinimapSizeText = raidMinimapCard:CreateFontString(
		nil, "OVERLAY", "GameFontNormal"
	)
	ui.raidMinimapSizeText:SetPoint(
		"TOPLEFT", raidMinimapCard, "TOPLEFT", 26, -164
	)
	ui.raidMinimapSizeText:SetText("Taille des points : 7 px")

	local decreaseRaidMinimapSize = CreateFrame(
		"Button", nil, raidMinimapCard, "UIPanelButtonTemplate"
	)
	decreaseRaidMinimapSize:SetWidth(36)
	decreaseRaidMinimapSize:SetHeight(24)
	decreaseRaidMinimapSize:SetPoint(
		"TOPLEFT", raidMinimapCard, "TOPLEFT", 205, -157
	)
	decreaseRaidMinimapSize:SetText("-")
	local increaseRaidMinimapSize = CreateFrame(
		"Button", nil, raidMinimapCard, "UIPanelButtonTemplate"
	)
	increaseRaidMinimapSize:SetWidth(36)
	increaseRaidMinimapSize:SetHeight(24)
	increaseRaidMinimapSize:SetPoint(
		"LEFT", decreaseRaidMinimapSize, "RIGHT", 6, 0
	)
	increaseRaidMinimapSize:SetText("+")
	local function AdjustRaidMinimapSize(delta)
		local module = CoAAnalyticsAddon.Modules.RaidMinimap
		local moduleSettings = module and module.GetSettings
			and module.GetSettings()
		if module and module.SetSize and moduleSettings then
			module.SetSize((moduleSettings.size or 7) + delta)
			RefreshSettingsControls()
		end
	end
	decreaseRaidMinimapSize:SetScript("OnClick", function()
		AdjustRaidMinimapSize(-1)
	end)
	increaseRaidMinimapSize:SetScript("OnClick", function()
		AdjustRaidMinimapSize(1)
	end)

	local resetRaidMinimapSize = CreateFrame(
		"Button", nil, raidMinimapCard, "UIPanelButtonTemplate"
	)
	resetRaidMinimapSize:SetWidth(120)
	resetRaidMinimapSize:SetHeight(24)
	resetRaidMinimapSize:SetPoint(
		"BOTTOMLEFT", raidMinimapCard, "BOTTOMLEFT", 22, 18
	)
	resetRaidMinimapSize:SetText("Taille par defaut")
	resetRaidMinimapSize:SetScript("OnClick", function()
		local module = CoAAnalyticsAddon.Modules.RaidMinimap
		if module and module.SetSize then
			module.SetSize(7)
			RefreshSettingsControls()
		end
	end)

	local overlayCard = CreateFrame("Frame", nil, ui.generalSettingsPanel)
	overlayCard:SetPoint("TOPLEFT", ui.generalSettingsPanel, "TOPLEFT", 8, -8)
	overlayCard:SetPoint("TOPRIGHT", ui.generalSettingsPanel, "TOPRIGHT", -8, -8)
	overlayCard:SetHeight(160)
	overlayCard:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 10,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	overlayCard:SetBackdropColor(0.05, 0.055, 0.07, 0.96)
	overlayCard:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)

	local overlayTitle = overlayCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	overlayTitle:SetPoint("TOPLEFT", overlayCard, "TOPLEFT", 22, -20)
	overlayTitle:SetText("Performance du donjon a l'ecran")
	local overlayDescription = overlayCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	overlayDescription:SetPoint("TOPLEFT", overlayCard, "TOPLEFT", 22, -44)
	overlayDescription:SetPoint("TOPRIGHT", overlayCard, "TOPRIGHT", -22, -44)
	overlayDescription:SetHeight(38)
	overlayDescription:SetJustifyH("LEFT")
	overlayDescription:SetWordWrap(true)
	overlayDescription:SetText(
		"Affiche uniquement en donjon une liste compacte et deplacable : nom colore par classe et note sur 10. "
			.. "Le widget reutilise le snapshot PvE actualise chaque seconde, sans collecte supplementaire."
	)

	ui.showDungeonOverlayCheckButton = CreateFrame(
		"CheckButton",
		"CoAAnalyticsShowDungeonOverlayCheckButton",
		overlayCard,
		"UICheckButtonTemplate"
	)
	ui.showDungeonOverlayCheckButton:SetWidth(24)
	ui.showDungeonOverlayCheckButton:SetHeight(24)
	ui.showDungeonOverlayCheckButton:SetPoint("TOPLEFT", overlayCard, "TOPLEFT", 21, -88)
	local overlayCheckLabel = overlayCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	overlayCheckLabel:SetPoint("LEFT", ui.showDungeonOverlayCheckButton, "RIGHT", 4, 0)
	overlayCheckLabel:SetText("Afficher le widget de performance en donjon")
	ui.showDungeonOverlayCheckButton:SetScript("OnClick", function(self)
		addonDB.showDungeonPerformanceOverlay = self:GetChecked() and true or false
		local overlay = CoAAnalyticsAddon.Modules.DungeonOverlay
		if overlay and overlay.ApplySettings then
			overlay.ApplySettings()
		end
	end)

	ui.enableKeystoneBossCheckButton = CreateFrame(
		"CheckButton",
		"CoAAnalyticsEnableKeystoneBossCheckButton",
		overlayCard,
		"UICheckButtonTemplate"
	)
	ui.enableKeystoneBossCheckButton:SetWidth(24)
	ui.enableKeystoneBossCheckButton:SetHeight(24)
	ui.enableKeystoneBossCheckButton:SetPoint(
		"TOPLEFT",
		overlayCard,
		"TOPLEFT",
		21,
		-116
	)
	local keystoneBossCheckLabel = overlayCard:CreateFontString(
		nil,
		"OVERLAY",
		"GameFontHighlight"
	)
	keystoneBossCheckLabel:SetPoint(
		"LEFT",
		ui.enableKeystoneBossCheckButton,
		"RIGHT",
		4,
		0
	)
	keystoneBossCheckLabel:SetText("Afficher le boss de Keystone en Mythic 0")
	ui.enableKeystoneBossCheckButton:SetScript("OnClick", function(self)
		addonDB.enableKeystoneBossFeature = self:GetChecked() and true or false
		local module = CoAAnalyticsAddon.Modules.KeystoneBosses
		if module and module.ApplySettings then
			module.ApplySettings()
		end
	end)
	ui.enableKeystoneBossCheckButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Afficher le boss de Keystone en Mythic 0", 0.10, 0.72, 0.52)
		GameTooltip:AddLine(
			"Active la detection automatique, l'annonce, la localisation et le partage du boss de Keystone.",
			0.78,
			0.82,
			0.90,
			true
		)
		GameTooltip:Show()
	end)
	ui.enableKeystoneBossCheckButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local resetOverlayButton = CreateFrame(
		"Button",
		nil,
		overlayCard,
		"UIPanelButtonTemplate"
	)
	resetOverlayButton:SetWidth(150)
	resetOverlayButton:SetHeight(24)
	resetOverlayButton:SetPoint("TOPRIGHT", overlayCard, "TOPRIGHT", -22, -16)
	resetOverlayButton:SetText("Reinitialiser la position")
	resetOverlayButton:SetScript("OnClick", function()
		local overlay = CoAAnalyticsAddon.Modules.DungeonOverlay
		if overlay and overlay.ResetPosition then
			overlay.ResetPosition()
		end
	end)

	local diagnosticCard = CreateFrame("Frame", nil, ui.generalSettingsPanel)
	diagnosticCard:SetPoint("TOPLEFT", overlayCard, "BOTTOMLEFT", 0, -12)
	diagnosticCard:SetPoint("TOPRIGHT", overlayCard, "BOTTOMRIGHT", 0, -12)
	diagnosticCard:SetHeight(270)
	diagnosticCard:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 10,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	diagnosticCard:SetBackdropColor(0.05, 0.055, 0.07, 0.96)
	diagnosticCard:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)

	local diagnosticTitle = diagnosticCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	diagnosticTitle:SetPoint("TOPLEFT", diagnosticCard, "TOPLEFT", 22, -18)
	diagnosticTitle:SetText("Historique des diagnostics de donjon")
	local diagnosticDescription = diagnosticCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	diagnosticDescription:SetPoint("TOPLEFT", diagnosticCard, "TOPLEFT", 22, -45)
	diagnosticDescription:SetPoint("TOPRIGHT", diagnosticCard, "TOPRIGHT", -22, -45)
	diagnosticDescription:SetHeight(38)
	diagnosticDescription:SetJustifyH("LEFT")
	diagnosticDescription:SetWordWrap(true)
	diagnosticDescription:SetText(
		"Seuls les diagnostics complets et prets a etre envoyes pour analyse sont listes. "
			.. "Les 10 plus recents sont conserves."
	)

	ui.diagnosticStatusText = diagnosticCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	ui.diagnosticStatusText:SetPoint("TOPLEFT", diagnosticCard, "TOPLEFT", 22, -92)
	ui.diagnosticStatusText:SetText("Aucun diagnostic enregistre")
	ui.diagnosticHistoryScroll = CreateFrame(
		"ScrollFrame",
		"CoAAnalyticsDungeonHistoryScrollFrame",
		diagnosticCard,
		"UIPanelScrollFrameTemplate"
	)
	ui.diagnosticHistoryScroll:SetPoint("TOPLEFT", diagnosticCard, "TOPLEFT", 22, -110)
	ui.diagnosticHistoryScroll:SetPoint("BOTTOMRIGHT", diagnosticCard, "BOTTOMRIGHT", -42, 55)
	ui.diagnosticHistoryContent = CreateFrame("Frame", nil, ui.diagnosticHistoryScroll)
	ui.diagnosticHistoryContent:SetWidth(650)
	ui.diagnosticHistoryContent:SetHeight(1)
	ui.diagnosticHistoryScroll:SetScrollChild(ui.diagnosticHistoryContent)
	ui.diagnosticHistoryText = ui.diagnosticHistoryContent:CreateFontString(
		nil, "OVERLAY", "GameFontHighlightSmall"
	)
	ui.diagnosticHistoryText:SetPoint("TOPLEFT", ui.diagnosticHistoryContent, "TOPLEFT", 0, 0)
	ui.diagnosticHistoryText:SetWidth(650)
	ui.diagnosticHistoryText:SetJustifyH("LEFT")
	ui.diagnosticHistoryText:SetJustifyV("TOP")
	ui.diagnosticHistoryText:SetWordWrap(false)
	ui.diagnosticHistoryText:SetText("Aucun diagnostic complet conserve.")
	ui.diagnosticHistoryRows = { ui.diagnosticHistoryText }
	local diagnosticPath = diagnosticCard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	diagnosticPath:SetPoint("BOTTOMLEFT", diagnosticCard, "BOTTOMLEFT", 22, 40)
	diagnosticPath:SetPoint("BOTTOMRIGHT", diagnosticCard, "BOTTOMRIGHT", -22, 40)
	diagnosticPath:SetJustifyH("LEFT")
	diagnosticPath:SetText(
		"Exporter enregistre le fichier dans : WTF\\Account\\<compte>\\SavedVariables\\CoAAnalytics.lua"
	)

	ui.diagnosticToggleButton = CreateFrame("Button", nil, diagnosticCard, "UIPanelButtonTemplate")
	ui.diagnosticToggleButton:SetWidth(180)
	ui.diagnosticToggleButton:SetHeight(24)
	ui.diagnosticToggleButton:SetPoint("BOTTOMLEFT", diagnosticCard, "BOTTOMLEFT", 22, 12)
	ui.diagnosticToggleButton:SetText("Enregistrer le prochain")
	ui.diagnosticToggleButton:SetScript("OnClick", function()
		if not CoAAnalyticsPvE or not CoAAnalyticsPvE.GetDungeonDiagnosticStatus then
			return
		end
		local status = CoAAnalyticsPvE.GetDungeonDiagnosticStatus()
		CoAAnalyticsPvE.SetDungeonDiagnosticEnabled(not (status.active or status.armed))
		RefreshSettingsControls()
	end)

	ui.clearDiagnosticButton = CreateFrame("Button", nil, diagnosticCard, "UIPanelButtonTemplate")
	ui.clearDiagnosticButton:SetWidth(150)
	ui.clearDiagnosticButton:SetHeight(24)
	ui.clearDiagnosticButton:SetPoint("BOTTOMRIGHT", diagnosticCard, "BOTTOMRIGHT", -22, 12)
	ui.clearDiagnosticButton:SetText("Tout effacer")
	ui.clearDiagnosticButton:SetScript("OnClick", function()
		if CoAAnalyticsPvE and CoAAnalyticsPvE.ClearDungeonDiagnostic then
			CoAAnalyticsPvE.ClearDungeonDiagnostic()
			RefreshSettingsControls()
		end
	end)

	ui.exportDiagnosticButton = CreateFrame(
		"Button", nil, diagnosticCard, "UIPanelButtonTemplate"
	)
	ui.exportDiagnosticButton:SetWidth(160)
	ui.exportDiagnosticButton:SetHeight(24)
	ui.exportDiagnosticButton:SetPoint(
		"LEFT", ui.diagnosticToggleButton, "RIGHT", 10, 0
	)
	ui.exportDiagnosticButton:SetText("Exporter les rapports")
	ui.exportDiagnosticButton:SetScript("OnClick", function()
		StaticPopup_Show("COA_ANALYTICS_EXPORT_DUNGEON_DIAGNOSTIC")
	end)

	if not StaticPopupDialogs["COA_ANALYTICS_EXPORT_DUNGEON_DIAGNOSTIC"] then
		StaticPopupDialogs["COA_ANALYTICS_EXPORT_DUNGEON_DIAGNOSTIC"] = {
			text = API.LocalizeText("Exporter les diagnostics conserves ? L'interface sera rechargee automatiquement afin d'ecrire le fichier."),
			button1 = API.LocalizeText("Exporter"),
			button2 = API.LocalizeText("Annuler"),
			OnAccept = function()
				if CoAAnalyticsPvE and CoAAnalyticsPvE.ExportDungeonDiagnostic then
					CoAAnalyticsPvE.ExportDungeonDiagnostic()
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end

	local configurationCard = CreateFrame("Frame", nil, ui.nameplateOptionsPanel)
	configurationCard:SetPoint("TOPLEFT", ui.nameplateOptionsPanel, "TOPLEFT", 8, -8)
	configurationCard:SetPoint("TOPRIGHT", ui.nameplateOptionsPanel, "TOPRIGHT", -8, -8)
	configurationCard:SetHeight(300)
	configurationCard:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 10,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	configurationCard:SetBackdropColor(0.05, 0.055, 0.07, 0.96)
	configurationCard:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)

	local sectionTitle = configurationCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	sectionTitle:SetPoint("TOPLEFT", configurationCard, "TOPLEFT", 22, -20)
	sectionTitle:SetText("Affichage au-dessus des joueurs")

	local description = configurationCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	description:SetPoint("TOPLEFT", configurationCard, "TOPLEFT", 22, -48)
	description:SetPoint("TOPRIGHT", configurationCard, "TOPRIGHT", -22, -48)
	description:SetHeight(38)
	description:SetJustifyH("LEFT")
	description:SetWordWrap(true)
	description:SetText(
		"Emplacement des icones sur les nameplates ennemies. "
			.. "Si les deux utilisent le meme emplacement, elles sont alignees automatiquement."
	)

	local roleLabel = configurationCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	roleLabel:SetPoint("TOPLEFT", configurationCard, "TOPLEFT", 26, -108)
	roleLabel:SetText("Icone du role")

	ui.rolePositionDropdown = CreatePositionDropdown(
		configurationCard,
		"CoAAnalyticsRolePositionDropDown",
		"roleIconPosition",
		310,
		-91
	)

	local specLabel = configurationCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	specLabel:SetPoint("TOPLEFT", configurationCard, "TOPLEFT", 26, -158)
	specLabel:SetText("Icone de specialisation")

	ui.specPositionDropdown = CreatePositionDropdown(
		configurationCard,
		"CoAAnalyticsSpecPositionDropDown",
		"specIconPosition",
		310,
		-141
	)

	ui.showSpecCheckButton = CreateFrame(
		"CheckButton",
		"CoAAnalyticsShowSpecCheckButton",
		configurationCard,
		"UICheckButtonTemplate"
	)
	ui.showSpecCheckButton:SetWidth(24)
	ui.showSpecCheckButton:SetHeight(24)
	ui.showSpecCheckButton:SetPoint("TOPLEFT", configurationCard, "TOPLEFT", 21, -199)
	local checkLabel = configurationCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	checkLabel:SetPoint(
		"LEFT",
		ui.showSpecCheckButton,
		"RIGHT",
		4,
		0
	)
	checkLabel:SetText("Afficher l'icone de specialisation")
	ui.showSpecCheckButton:SetScript("OnClick", function(self)
		addonDB.showSpecIcon = self:GetChecked() and true or false
		RefreshVisibleIconLayouts()
	end)

	local resetButton = CreateFrame(
		"Button",
		nil,
		configurationCard,
		"UIPanelButtonTemplate"
	)
	resetButton:SetWidth(120)
	resetButton:SetHeight(24)
	resetButton:SetPoint("BOTTOMLEFT", configurationCard, "BOTTOMLEFT", 22, 18)
	resetButton:SetText("Par defaut")
	resetButton:SetScript("OnClick", function()
		addonDB.roleIconPosition = "ABOVE_CENTER"
		addonDB.specIconPosition = "ABOVE_RIGHT"
		addonDB.showSpecIcon = true
		RefreshSettingsControls()
		RefreshVisibleIconLayouts()
	end)

	local compatibility = ui.nameplateOptionsPanel:CreateFontString(
		nil,
		"OVERLAY",
		"GameFontDisableSmall"
	)
	compatibility:SetPoint("TOPLEFT", configurationCard, "BOTTOMLEFT", 14, -20)
	compatibility:SetPoint("TOPRIGHT", configurationCard, "BOTTOMRIGHT", -14, -20)
	compatibility:SetJustifyH("LEFT")
	compatibility:SetText(
		"Compatible avec les nameplates Blizzard et ElvUI. "
			.. "Les modifications sont appliquees immediatement."
	)

	ui.rankingPanel = CreateFrame("Frame", nil, frame)
	ui.rankingPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 184, -96)
	ui.rankingPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
	ui.rankingPanel:Hide()

	ui.specializationRankingTabButton = CreateModernTab(
		ui.rankingPanel,
		"Specialisations",
		0.95,
		0.61,
		0.12
	)
	ui.specializationRankingTabButton:SetWidth(150)
	ui.specializationRankingTabButton:SetPoint("TOPLEFT", ui.rankingPanel, "TOPLEFT", 8, -6)
	ui.playerRankingTabButton = CreateModernTab(
		ui.rankingPanel,
		"Joueurs",
		0.68,
		0.43,
		0.95
	)
	ui.playerRankingTabButton:SetWidth(120)
	ui.playerRankingTabButton:SetPoint("LEFT", ui.specializationRankingTabButton, "RIGHT", 7, 0)

	ui.specializationRankingPanel = CreateFrame("Frame", nil, ui.rankingPanel)
	ui.specializationRankingPanel:SetPoint("TOPLEFT", ui.rankingPanel, "TOPLEFT", 0, -36)
	ui.specializationRankingPanel:SetPoint("BOTTOMRIGHT", ui.rankingPanel, "BOTTOMRIGHT", 0, 0)
	ui.playerRankingPanel = CreateFrame("Frame", nil, ui.rankingPanel)
	ui.playerRankingPanel:SetPoint("TOPLEFT", ui.rankingPanel, "TOPLEFT", 0, -36)
	ui.playerRankingPanel:SetPoint("BOTTOMRIGHT", ui.rankingPanel, "BOTTOMRIGHT", 0, 0)

	ui.damageRankingTabButton = CreateModernTab(
		ui.specializationRankingPanel,
		"Degats",
		0.95,
		0.58,
		0.10
	)
	ui.damageRankingTabButton:SetWidth(120)
	ui.damageRankingTabButton:SetPoint("TOPLEFT", ui.specializationRankingPanel, "TOPLEFT", 8, -6)
	ui.healingRankingTabButton = CreateModernTab(
		ui.specializationRankingPanel,
		"Soins",
		0.20,
		0.82,
		0.42
	)
	ui.healingRankingTabButton:SetWidth(120)
	ui.healingRankingTabButton:SetPoint("LEFT", ui.damageRankingTabButton, "RIGHT", 7, 0)

	local rankingHint = ui.specializationRankingPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	rankingHint:SetPoint("TOPRIGHT", ui.specializationRankingPanel, "TOPRIGHT", -10, -15)
	rankingHint:SetWidth(310)
	rankingHint:SetJustifyH("RIGHT")
	rankingHint:SetText("Classement selon les performances cumulees en BG")

	ui.rankingSummaryAnalyzed = CreateRankingSummaryCard(
		ui.specializationRankingPanel,
		8,
		"BG analyses",
		0.10,
		0.72,
		0.52
	)
	ui.rankingSummaryAnalyzed.tooltipText =
		"BG complets ayant distribue des points dans l'onglet actuel."
	ui.rankingSummaryBalance = CreateRankingSummaryCard(
		ui.specializationRankingPanel,
		202,
		"Influence moyenne",
		0.30,
		0.62,
		0.95
	)
	ui.rankingSummaryBalance.tooltipText =
		"Un BG equilibre compte a 100%, soit 1 point. Plus l'ecart de morts et de degats entre les equipes est grand, plus l'influence du BG est reduite, jusqu'a 25%. Le meme coefficient est applique a toutes les specialisations du match."
	ui.rankingSummarySpecializations = CreateRankingSummaryCard(
		ui.specializationRankingPanel,
		396,
		"Specialisations classees",
		0.68,
		0.43,
		0.95
	)
	ui.rankingSummarySpecializations.tooltipText =
		"Nombre de specialisations ayant deja recu des points dans l'onglet actuel."

	local rankHeader = CreateRankingColumnHeader(
		ui.specializationRankingPanel,
		"RANG",
		"Position selon la performance moyenne par participation, apres lissage statistique.",
		55
	)
	rankHeader:SetPoint("TOPLEFT", ui.specializationRankingPanel, "TOPLEFT", 20, -103)
	local identityHeader = CreateRankingColumnHeader(
		ui.specializationRankingPanel,
		"CLASSE / SPECIALISATION",
		"Classe et specialisation CoA regroupees anonymement. Aucun nom de joueur n'est conserve dans cette vue.",
		250
	)
	identityHeader:SetPoint("TOPLEFT", ui.specializationRankingPanel, "TOPLEFT", 86, -103)
	local scoreHeader = CreateRankingColumnHeader(
		ui.specializationRankingPanel,
		"SCORE",
		"Points moyens par participation. Le score est lisse avec cinq BG virtuels a la moyenne pour eviter qu'un petit echantillon domine le classement.",
		80
	)
	scoreHeader.text:SetJustifyH("RIGHT")
	scoreHeader:SetPoint(
		"TOPRIGHT",
		ui.specializationRankingPanel,
		"TOPRIGHT",
		-(RANKING_TABLE_RIGHT_INSET + RANKING_SCORE_RIGHT_INSET),
		-103
	)
	local percentHeader = CreateRankingColumnHeader(
		ui.specializationRankingPanel,
		"PART (%)",
		"Part de la specialisation dans la somme des scores normalises. Le nombre de participations ne donne plus directement de points supplementaires.",
		76
	)
	percentHeader.text:SetJustifyH("RIGHT")
	percentHeader:SetPoint(
		"TOPRIGHT",
		ui.specializationRankingPanel,
		"TOPRIGHT",
		-(RANKING_TABLE_RIGHT_INSET + RANKING_PERCENT_RIGHT_INSET),
		-103
	)

	ui.rankingScrollFrame = CreateFrame(
		"ScrollFrame",
		"CoAAnalyticsRankingScrollFrame",
		ui.specializationRankingPanel,
		"FauxScrollFrameTemplate"
	)
	ui.rankingScrollFrame:SetPoint("TOPLEFT", ui.specializationRankingPanel, "TOPLEFT", 8, -130)
	ui.rankingScrollFrame:SetPoint("BOTTOMRIGHT", ui.specializationRankingPanel, "BOTTOMRIGHT", -24, 46)
	ui.rankingScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(
			self,
			offset,
			RANKING_ROW_HEIGHT,
			ui.RefreshRankingPanel
		)
	end)
	for index = 1, RANKING_MAX_VISIBLE_ROWS do
		ui.rankingRows[index] = CreateRankingRow(ui.specializationRankingPanel, index)
	end

	ui.rankingNoDataText = ui.specializationRankingPanel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	ui.rankingNoDataText:SetPoint("CENTER", ui.specializationRankingPanel, "CENTER", 0, -40)
	ui.rankingNoDataText:SetText(
		"Aucun score lisse pour le moment.\nLe classement commencera a la fin du prochain BG complet."
	)

	ui.rankingMethodologyText = ui.specializationRankingPanel:CreateFontString(
		nil,
		"OVERLAY",
		"GameFontDisableSmall"
	)
	ui.rankingMethodologyText:SetPoint(
		"BOTTOMLEFT",
		ui.specializationRankingPanel,
		"BOTTOMLEFT",
		12,
		9
	)
	ui.rankingMethodologyText:SetWidth(455)
	ui.rankingMethodologyText:SetHeight(42)
	ui.rankingMethodologyText:SetJustifyH("LEFT")
	ui.rankingMethodologyText:SetJustifyV("BOTTOM")
	ui.rankingMethodologyText:SetWordWrap(true)

	local clearRankingButton = CreateFrame(
		"Button",
		nil,
		ui.specializationRankingPanel,
		"UIPanelButtonTemplate"
	)
	clearRankingButton:SetWidth(130)
	clearRankingButton:SetHeight(23)
	clearRankingButton:SetPoint("BOTTOMRIGHT", ui.specializationRankingPanel, "BOTTOMRIGHT", -8, 7)
	clearRankingButton:SetText("Reinitialiser")
	clearRankingButton:SetScript("OnClick", function()
		StaticPopup_Show("COA_ANALYTICS_RESET_BG_RANKINGS")
	end)

	ui.playerDpsTabButton = CreateModernTab(ui.playerRankingPanel, "DPS", 0.95, 0.58, 0.10)
	ui.playerDpsTabButton:SetWidth(72)
	ui.playerDpsTabButton:SetPoint("TOPLEFT", ui.playerRankingPanel, "TOPLEFT", 8, -6)
	ui.playerHealingTabButton = CreateModernTab(ui.playerRankingPanel, "Soins", 0.20, 0.82, 0.42)
	ui.playerHealingTabButton:SetWidth(72)
	ui.playerHealingTabButton:SetPoint("LEFT", ui.playerDpsTabButton, "RIGHT", 6, 0)
	ui.playerTankTabButton = CreateModernTab(ui.playerRankingPanel, "Tanks", 0.30, 0.62, 0.95)
	ui.playerTankTabButton:SetWidth(72)
	ui.playerTankTabButton:SetPoint("LEFT", ui.playerHealingTabButton, "RIGHT", 6, 0)
	ui.playerSupportTabButton = CreateModernTab(ui.playerRankingPanel, "Supports", 0.68, 0.43, 0.95)
	ui.playerSupportTabButton:SetWidth(82)
	ui.playerSupportTabButton:SetPoint("LEFT", ui.playerTankTabButton, "RIGHT", 6, 0)

	ui.playerDpsFilterDropdown = CreateFrame(
		"Frame",
		"CoAAnalyticsPlayerDpsFilterDropDown",
		ui.playerRankingPanel,
		"UIDropDownMenuTemplate"
	)
	ui.playerDpsFilterDropdown:SetPoint("TOPLEFT", ui.playerRankingPanel, "TOPLEFT", 330, 1)
	UIDropDownMenu_SetWidth(ui.playerDpsFilterDropdown, 82)
	UIDropDownMenu_Initialize(ui.playerDpsFilterDropdown, function()
		local options = {
			{ value = "all", text = "Tous DPS" },
			{ value = "melee", text = "Melee" },
			{ value = "ranged", text = "Distance" },
		}
		for _, option in ipairs(options) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = option.text
			info.value = option.value
			info.checked = ui.activePlayerDpsFilter == option.value
			info.func = function()
				ui.activePlayerDpsFilter = option.value
				UIDropDownMenu_SetSelectedValue(ui.playerDpsFilterDropdown, option.value)
				UIDropDownMenu_SetText(ui.playerDpsFilterDropdown, option.text)
				local scrollBar = _G["CoAAnalyticsPlayerRankingScrollFrameScrollBar"]
				if scrollBar then scrollBar:SetValue(0) end
				ui.RefreshRankingPanel()
			end
			UIDropDownMenu_AddButton(info)
		end
	end)
	UIDropDownMenu_SetSelectedValue(ui.playerDpsFilterDropdown, "all")
	UIDropDownMenu_SetText(ui.playerDpsFilterDropdown, "Tous DPS")

	ui.playerSearchBox = CreateFrame(
		"EditBox",
		"CoAAnalyticsPlayerSearchBox",
		ui.playerRankingPanel,
		"InputBoxTemplate"
	)
	ui.playerSearchBox:SetWidth(190)
	ui.playerSearchBox:SetHeight(24)
	ui.playerSearchBox:SetPoint("TOPRIGHT", ui.playerRankingPanel, "TOPRIGHT", -10, -9)
	ui.playerSearchBox:SetAutoFocus(false)
	ui.playerSearchBox:SetMaxLetters(40)
	ui.playerSearchPlaceholder = ui.playerSearchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ui.playerSearchPlaceholder:SetPoint("LEFT", ui.playerSearchBox, "LEFT", 7, 0)
	ui.playerSearchPlaceholder:SetText("Rechercher un joueur...")
	ui.playerSearchBox:SetScript("OnEditFocusGained", function()
		ui.playerSearchPlaceholder:Hide()
	end)
	ui.playerSearchBox:SetScript("OnEditFocusLost", function(self)
		if self:GetText() == "" then ui.playerSearchPlaceholder:Show() end
	end)
	ui.playerSearchBox:SetScript("OnTextChanged", function(self)
		if self:GetText() == "" and not self:HasFocus() then
			ui.playerSearchPlaceholder:Show()
		else
			ui.playerSearchPlaceholder:Hide()
		end
		local scrollBar = _G["CoAAnalyticsPlayerRankingScrollFrameScrollBar"]
		if scrollBar then scrollBar:SetValue(0) end
		RefreshPlayerSearchSuggestions()
		if ui.activeRankingMode == "players" then ui.RefreshPlayerRankingPanel() end
	end)
	-- OnArrowPressed n'existe pas sur le client Ascension 3.3.5. La touche
	-- Tab fournit la navigation clavier sans interrompre la creation de l'UI.
	ui.playerSearchBox:SetScript("OnTabPressed", function()
		if #ui.playerSearchSuggestions == 0 then return end
		ui.playerSearchSelection = ui.playerSearchSelection + 1
		if ui.playerSearchSelection > #ui.playerSearchSuggestions then
			ui.playerSearchSelection = 1
		end
		SetSearchSuggestionHighlight()
	end)
	ui.playerSearchBox:SetScript("OnEnterPressed", function(self)
		if ui.playerSearchSelection > 0 then
			SelectPlayerSearchSuggestion(ui.playerSearchSelection)
		elseif #ui.playerSearchSuggestions > 0 then
			SelectPlayerSearchSuggestion(1)
		else
			self:ClearFocus()
		end
	end)
	ui.playerSearchBox:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
		ui.playerSearchSuggestionsFrame:Hide()
	end)

	ui.playerSearchSuggestionsFrame = CreateFrame("Frame", nil, ui.playerRankingPanel)
	ui.playerSearchSuggestionsFrame:SetWidth(224)
	ui.playerSearchSuggestionsFrame:SetPoint("TOPRIGHT", ui.playerSearchBox, "BOTTOMRIGHT", 0, -2)
	ui.playerSearchSuggestionsFrame:SetFrameStrata("TOOLTIP")
	ui.playerSearchSuggestionsFrame:SetFrameLevel(50)
	ui.playerSearchSuggestionsFrame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 10,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	ui.playerSearchSuggestionsFrame:SetBackdropColor(0.025, 0.03, 0.045, 0.99)
	ui.playerSearchSuggestionsFrame:SetBackdropBorderColor(0.24, 0.27, 0.34, 1)
	for index = 1, PLAYER_SEARCH_MAX_SUGGESTIONS do
		local button = CreateFrame("Button", nil, ui.playerSearchSuggestionsFrame)
		button:SetHeight(24)
		button:SetPoint("TOPLEFT", ui.playerSearchSuggestionsFrame, "TOPLEFT", 3, -3 - (index - 1) * 24)
		button:SetPoint("TOPRIGHT", ui.playerSearchSuggestionsFrame, "TOPRIGHT", -3, -3 - (index - 1) * 24)
		button.background = CreateSolidTexture(button, "BACKGROUND", 0.15, 0.17, 0.22, 0.92)
		button.background:SetAllPoints()
		button.nameText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		button.nameText:SetPoint("LEFT", 7, 0)
		button.nameText:SetWidth(122)
		button.nameText:SetJustifyH("LEFT")
		button.detailText = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		button.detailText:SetPoint("RIGHT", -7, 0)
		button.detailText:SetWidth(92)
		button.detailText:SetJustifyH("RIGHT")
		button:SetScript("OnEnter", function(self)
			ui.playerSearchSelection = self.suggestionIndex or 0
			SetSearchSuggestionHighlight()
		end)
		button:SetScript("OnClick", function(self)
			SelectPlayerSearchSuggestion(self.suggestionIndex)
		end)
		ui.playerSearchSuggestionButtons[index] = button
	end
	ui.playerSearchSuggestionsFrame:Hide()

	ui.playerRankingSummaryAnalyzed = CreateRankingSummaryCard(
		ui.playerRankingPanel, 8, "BG collectes", 0.10, 0.72, 0.52
	)
	ui.playerRankingSummaryAnalyzed.tooltipText =
		"Nombre de BG enregistres depuis l'activation du classement individuel. L'ancien historique anonyme ne contient aucun nom recuperable."
	ui.playerRankingSummaryBalance = CreateRankingSummaryCard(
		ui.playerRankingPanel, 202, "Influence moyenne", 0.30, 0.62, 0.95
	)
	ui.playerRankingSummaryBalance.tooltipText =
		"Poids moyen des BG. Un stomp influence moins le classement, avec le meme coefficient pour tous les joueurs du match."
	ui.playerRankingSummaryPlayers = CreateRankingSummaryCard(
		ui.playerRankingPanel, 396, "Joueurs classes", 0.68, 0.43, 0.95
	)
	ui.playerRankingSummaryPlayers.tooltipText =
		"Nombre de personnages ayant termine les trois BG de placement dans le role et le filtre affiches."

	local playerRankHeader = CreateRankingColumnHeader(
		ui.playerRankingPanel,
		"RANG",
		"Position officielle apres trois BG de placement. Les joueurs encore en placement affichent un tiret.",
		48
	)
	playerRankHeader:SetPoint("TOPLEFT", ui.playerRankingPanel, "TOPLEFT", 18, -103)
	local playerNameHeader = CreateRankingColumnHeader(
		ui.playerRankingPanel,
		"JOUEUR",
		"Nom complet du personnage. Sa couleur correspond a sa classe. L'icone voisine affiche ses specialisations au survol.",
		190
	)
	playerNameHeader:SetPoint("TOPLEFT", ui.playerRankingPanel, "TOPLEFT", 54, -103)
	local playerLastSeenHeader = CreateRankingColumnHeader(
		ui.playerRankingPanel,
		"DERNIERE VUE",
		"Moment de votre derniere rencontre avec ce personnage dans un BG enregistre.",
		142
	)
	playerLastSeenHeader:SetPoint(
		"TOPLEFT",
		ui.playerRankingPanel,
		"TOPLEFT",
		250,
		-103
	)
	local playerScoreHeader = CreateRankingColumnHeader(
		ui.playerRankingPanel,
		"SCORE",
		"Score classant = performance relative a la moyenne du role, corrigee selon le niveau et le pourcentage du BG effectivement joue, puis lissee avec 10 BG virtuels et une marge d'incertitude. Un joueur present moins de 25% ou sans degats/soins utiles a son role n'est pas enregistre.",
		64
	)
	playerScoreHeader.text:SetJustifyH("RIGHT")
	playerScoreHeader:SetPoint("TOPRIGHT", ui.playerRankingPanel, "TOPRIGHT", -339, -103)
	local playerRegularityHeader = CreateRankingColumnHeader(
		ui.playerRankingPanel,
		"REGULARITE",
		"Pourcentage de BG ou le joueur atteint au moins 90% du meilleur score de son role.",
		86
	)
	playerRegularityHeader.text:SetJustifyH("RIGHT")
	playerRegularityHeader:SetPoint("TOPRIGHT", ui.playerRankingPanel, "TOPRIGHT", -244, -103)
	local playerMatchesHeader = CreateRankingColumnHeader(
		ui.playerRankingPanel,
		"BG",
		"Nombre de BG valides observes avec ce role. Trois BG sont necessaires pour recevoir un rang officiel.",
		48
	)
	playerMatchesHeader.text:SetJustifyH("RIGHT")
	playerMatchesHeader:SetPoint("TOPRIGHT", ui.playerRankingPanel, "TOPRIGHT", -169, -103)
	local playerConfidenceHeader = CreateRankingColumnHeader(
		ui.playerRankingPanel,
		"CONFIANCE",
		"Placement jusqu'a 3 BG, puis confiance provisoire avant 5 BG, moyenne de 5 a 19 BG et fiable a partir de 20 BG.",
		120
	)
	playerConfidenceHeader.text:SetJustifyH("RIGHT")
	playerConfidenceHeader:SetPoint("TOPRIGHT", ui.playerRankingPanel, "TOPRIGHT", -32, -103)

	ui.playerRankingScrollFrame = CreateFrame(
		"ScrollFrame",
		"CoAAnalyticsPlayerRankingScrollFrame",
		ui.playerRankingPanel,
		"FauxScrollFrameTemplate"
	)
	ui.playerRankingScrollFrame:SetPoint("TOPLEFT", ui.playerRankingPanel, "TOPLEFT", 8, -130)
	ui.playerRankingScrollFrame:SetPoint("BOTTOMRIGHT", ui.playerRankingPanel, "BOTTOMRIGHT", -24, 46)
	ui.playerRankingScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(
			self,
			offset,
			RANKING_ROW_HEIGHT,
			ui.RefreshPlayerRankingPanel
		)
	end)
	for index = 1, RANKING_MAX_VISIBLE_ROWS do
		ui.playerRankingRows[index] = CreatePlayerRankingRow(ui.playerRankingPanel, index)
	end
	ui.playerRankingNoDataText = ui.playerRankingPanel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	ui.playerRankingNoDataText:SetPoint("CENTER", ui.playerRankingPanel, "CENTER", 0, -40)
	ui.playerRankingNoDataText:SetText(
		"Aucun joueur classe dans cette categorie.\n"
			.. "Le classement individuel commencera a la fin du prochain BG complet."
	)
	ui.playerRankingMethodologyText = ui.playerRankingPanel:CreateFontString(
		nil, "OVERLAY", "GameFontDisableSmall"
	)
	ui.playerRankingMethodologyText:SetPoint("BOTTOMLEFT", ui.playerRankingPanel, "BOTTOMLEFT", 12, 9)
	ui.playerRankingMethodologyText:SetWidth(540)
	ui.playerRankingMethodologyText:SetHeight(42)
	ui.playerRankingMethodologyText:SetJustifyH("LEFT")
	ui.playerRankingMethodologyText:SetJustifyV("BOTTOM")
	ui.playerRankingMethodologyText:SetWordWrap(true)
	local clearPlayerRankingButton = CreateFrame(
		"Button", nil, ui.playerRankingPanel, "UIPanelButtonTemplate"
	)
	clearPlayerRankingButton:SetWidth(130)
	clearPlayerRankingButton:SetHeight(23)
	clearPlayerRankingButton:SetPoint("BOTTOMRIGHT", ui.playerRankingPanel, "BOTTOMRIGHT", -8, 7)
	clearPlayerRankingButton:SetText("Reinitialiser")
	clearPlayerRankingButton:SetScript("OnClick", function()
		StaticPopup_Show("COA_ANALYTICS_RESET_BG_PLAYERS")
	end)

	if not StaticPopupDialogs["COA_ANALYTICS_RESET_BG_RANKINGS"] then
		StaticPopupDialogs["COA_ANALYTICS_RESET_BG_RANKINGS"] = {
			text = API.LocalizeText("Effacer les classements BG par specialisation et par joueur ?"),
			button1 = API.LocalizeText("Oui"),
			button2 = API.LocalizeText("Non"),
			OnAccept = function()
				local lastMatchSignature = addonDB.rankings
					and addonDB.rankings.lastMatchSignature
				addonDB.rankings = nil
				InitializeRankingDatabase()
				addonDB.rankings.lastMatchSignature = lastMatchSignature
				ui.playerSearchIndexDirty = true
				ui.playerSearchIndex = {}
				if ui.playerSearchBox then ui.playerSearchBox:SetText("") end
				local scrollBar = _G["CoAAnalyticsRankingScrollFrameScrollBar"]
				if scrollBar then
					scrollBar:SetValue(0)
				end
				local playerScrollBar =
					_G["CoAAnalyticsPlayerRankingScrollFrameScrollBar"]
				if playerScrollBar then
					playerScrollBar:SetValue(0)
				end
				ui.RefreshRankingPanel()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end
	if not StaticPopupDialogs["COA_ANALYTICS_RESET_BG_PLAYERS"] then
		StaticPopupDialogs["COA_ANALYTICS_RESET_BG_PLAYERS"] = {
			text = API.LocalizeText("Effacer uniquement le classement individuel des joueurs ? Le classement par specialisation sera conserve."),
			button1 = API.LocalizeText("Oui"),
			button2 = API.LocalizeText("Non"),
			OnAccept = function()
				if addonDB and addonDB.rankings then
					addonDB.rankings.players = nil
					InitializeRankingDatabase()
					ui.playerSearchIndexDirty = true
					ui.playerSearchIndex = {}
					if ui.playerSearchBox then ui.playerSearchBox:SetText("") end
					local scrollBar =
						_G["CoAAnalyticsPlayerRankingScrollFrameScrollBar"]
					if scrollBar then scrollBar:SetValue(0) end
					ui.RefreshRankingPanel()
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end

	if CoAAnalyticsPvE and CoAAnalyticsPvE.CreatePanel then
		ui.pveRankingPanel = CoAAnalyticsPvE.CreatePanel(frame)
		ui.pveRankingPanel:ClearAllPoints()
		ui.pveRankingPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 184, -96)
		ui.pveRankingPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
	end
	if CoAAnalyticsPvE and CoAAnalyticsPvE.CreateSessionPanel then
		ui.pveSessionPanel = CoAAnalyticsPvE.CreateSessionPanel(frame)
		ui.pveSessionPanel:ClearAllPoints()
		ui.pveSessionPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 184, -96)
		ui.pveSessionPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
	end

	ui.nameplateTabButton:SetScript("OnClick", function()
		SetSettingsSection("settings")
	end)
	ui.homeTabButton:SetScript("OnClick", function()
		SetSettingsSection("home")
	end)
	ui.performanceTabButton:SetScript("OnClick", function()
		SetSettingsSection("performance")
	end)
	ui.advisorTabButton:SetScript("OnClick", function()
		SetSettingsSection("advisor")
	end)
	ui.lootTabButton:SetScript("OnClick", function()
		SetSettingsSection("loot")
	end)
	ui.combatTabButton:SetScript("OnClick", function()
		SetSettingsSection("combat")
	end)
	ui.collectionTabButton:SetScript("OnClick", function()
		SetSettingsSection("collection")
	end)
	ui.generalSettingsTabButton:SetScript("OnClick", function()
		SetSettingsMode("general")
	end)
	ui.nameplateSettingsTabButton:SetScript("OnClick", function()
		SetSettingsMode("nameplates")
	end)
	ui.raidMinimapSettingsTabButton:SetScript("OnClick", function()
		SetSettingsMode("raidminimap")
	end)
	ui.rankingTabButton:SetScript("OnClick", function()
		ui.activePerformanceTab = "ranking"
		SetSettingsSection("performance")
	end)
	ui.pveRankingTabButton:SetScript("OnClick", function()
		ui.activePerformanceTab = "pve"
		SetSettingsSection("performance")
	end)
	ui.pveSessionTabButton:SetScript("OnClick", function()
		ui.activePerformanceTab = "pvesession"
		SetSettingsSection("performance")
	end)
	ui.specializationRankingTabButton:SetScript("OnClick", function()
		SetRankingMode("specializations")
	end)
	ui.playerRankingTabButton:SetScript("OnClick", function()
		SetRankingMode("players")
	end)
	ui.damageRankingTabButton:SetScript("OnClick", function()
		ui.SetRankingCategory("dps")
	end)
	ui.healingRankingTabButton:SetScript("OnClick", function()
		ui.SetRankingCategory("healing")
	end)
	ui.playerDpsTabButton:SetScript("OnClick", function()
		ui.SetPlayerRankingCategory("dps")
	end)
	ui.playerHealingTabButton:SetScript("OnClick", function()
		ui.SetPlayerRankingCategory("healing")
	end)
	ui.playerTankTabButton:SetScript("OnClick", function()
		ui.SetPlayerRankingCategory("tank")
	end)
	ui.playerSupportTabButton:SetScript("OnClick", function()
		ui.SetPlayerRankingCategory("support")
	end)

	local closeButton = CreateFrame(
		"Button",
		nil,
		frame,
		"UIPanelCloseButton"
	)
	closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

	frame:SetScript("OnShow", function()
		RefreshLanguageButtons()
		RefreshSettingsControls()
		SetSettingsSection(ui.activeSettingsTab)
	end)
	frame:Hide()
	ui.settingsFrame = frame
	table.insert(UISpecialFrames, "CoAAnalyticsSettingsFrame")
	return frame
end

function UI.RefreshCombatPanel()
	if not ui.combatPerformanceText then return end
	local snapshot = CoAAnalyticsPvE and CoAAnalyticsPvE.GetCurrentDungeonSnapshot
		and CoAAnalyticsPvE.GetCurrentDungeonSnapshot()
	local dungeonState = snapshot and snapshot.active
		and ("Session de donjon active : " .. tostring(snapshot.instanceName or "Donjon"))
		or "Aucune session de donjon active."
	ui.combatPerformanceText:SetText(
		"|cffffb347Collecteur de performances|r\n"
			.. "Mesure le groupe en BG, donjon et raid pour les classements et les notes. "
			.. dungeonState
	)

	local advisor = CoAAnalyticsAddon.Advisor
	local analyzer = advisor and advisor.LocalAnalyzer
	local profiler = advisor and advisor.CombatProfiler
	local summary = analyzer and analyzer.GetSummary and analyzer.GetSummary()
	local profile = profiler and profiler.GetProfile and profiler.GetProfile()
	local enabled = analyzer and analyzer.IsEnabled and analyzer.IsEnabled()
	local fights = summary and summary.fights or profile and profile.fights or 0
	local deaths = summary and summary.deaths or 0
	local mode = summary and summary.dominantModeLabel or "inconnu"
	ui.combatAdvisorText:SetText(
		"|cff66ccffCollecteur de conseils|r\n"
			.. "Calibre les recommandations du personnage sans reutiliser les scores du groupe.\n\n"
			.. "Analyse locale : " .. (enabled and "active" or "inactive")
			.. " | Combats : " .. tostring(fights)
			.. " | Morts : " .. tostring(deaths)
			.. " | Contexte dominant : " .. tostring(mode)
			.. (summary and summary.reason and ("\n" .. summary.reason) or "")
	)
	if ui.toggleLocalAnalysisButton and ui.toggleLocalAnalysisButton.text then
		ui.toggleLocalAnalysisButton.text:SetText(
			enabled and "Analyse locale : ON" or "Analyse locale : OFF"
		)
	end
end

local function ToggleSettingsFrame(section)
	local frame = CreateSettingsFrame()
	if frame:IsShown() then
		frame:Hide()
	else
		if section then ui.activeSettingsTab = section end
		if not ui.activeSettingsTab then ui.activeSettingsTab = "home" end
		frame:Show()
	end
end

-- Le bouton de minimap est charge depuis Minimap.lua.

function UI.Initialize()
	addonDB = API and API.GetDatabase and API.GetDatabase()
	if not addonDB then
		return false
	end
	return true
end

function UI.NotifyRankingChanged()
	ui.playerSearchIndexDirty = true
	if ui.RefreshRankingPanel then
		ui.RefreshRankingPanel()
	end
end

function UI.Open(section, rankingMode)
	addonDB = API and API.GetDatabase and API.GetDatabase() or addonDB
	if not addonDB then
		return
	end
	if rankingMode == "players" or rankingMode == "specializations" then
		ui.activeRankingMode = rankingMode
	end
	local frame = CreateSettingsFrame()
	SetSettingsSection(section or "home")
	frame:Show()
end

function UI.Toggle(section)
	addonDB = API and API.GetDatabase and API.GetDatabase() or addonDB
	if addonDB then
		ToggleSettingsFrame(section)
	end
end

function UI.RefreshSettings()
	RefreshSettingsControls()
end

API.GetClassDisplayName = GetRankingClassName

CoAAnalyticsAddon.Events:Register("BG_RANKING_UPDATED", UI.NotifyRankingChanged)
CoAAnalyticsAddon.Events:Register("PVE_DIAGNOSTIC_STATUS_UPDATED", function()
	RefreshSettingsControls()
end)
CoAAnalyticsAddon.Events:Register("MYTHIC_RESET_UPDATED", function()
	UI.RefreshMythicResetCard()
end)
