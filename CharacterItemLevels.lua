local ItemLevels = {}
CoAAnalyticsAddon.Modules.CharacterItemLevels = ItemLevels

local SLOT_NAMES = {
	[1] = "Head",
	[2] = "Neck",
	[3] = "Shoulder",
	[4] = "Shirt",
	[5] = "Chest",
	[6] = "Waist",
	[7] = "Legs",
	[8] = "Feet",
	[9] = "Wrist",
	[10] = "Hands",
	[11] = "Finger0",
	[12] = "Finger1",
	[13] = "Trinket0",
	[14] = "Trinket1",
	[15] = "Back",
	[16] = "MainHand",
	[17] = "SecondaryHand",
	[18] = "Ranged",
	[19] = "Tabard",
}

local FRAME_PREFIXES = {
	"AscensionCharacter",
	"Character",
}

local REFRESH_HOOKS = {
	"ToggleCharacter",
	"CharacterFrame_ShowSubFrame",
	"ToggleAscensionCharacterFrame",
	"AscensionCharacterFrame_Show",
}

local trackedButtons = setmetatable({}, { __mode = "k" })
local installedHooks = {}
local refreshPending = false
local refreshDelay = 0
local refreshRetries = 0
local driver = CreateFrame("Frame")

local ScheduleRefresh

local function GetEffectiveItemLevel(itemLink)
	if type(itemLink) ~= "string" or itemLink == "" then
		return nil
	end

	local detailedGetter = _G.GetDetailedItemLevelInfo
	if type(detailedGetter) ~= "function"
		and type(_G.C_Item) == "table"
	then
		detailedGetter = _G.C_Item.GetDetailedItemLevelInfo
	end
	if type(detailedGetter) == "function" then
		local ok, itemLevel = pcall(detailedGetter, itemLink)
		itemLevel = ok and tonumber(itemLevel) or nil
		if itemLevel and itemLevel > 0 then
			return itemLevel
		end
	end

	local itemLevel = tonumber(select(4, GetItemInfo(itemLink)))
	if itemLevel and itemLevel > 0 then
		return itemLevel
	end
	return nil
end

local function EnsureItemLevelText(button)
	if button.CoAAnalyticsItemLevelText then
		return button.CoAAnalyticsItemLevelText
	end

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	local buttonName = button.GetName and button:GetName()
	local anchor = buttonName and _G[buttonName .. "IconTexture"] or button
	text:ClearAllPoints()
	text:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -1, 1)
	text:SetJustifyH("RIGHT")
	text:SetJustifyV("BOTTOM")
	text:SetTextColor(1, 0.82, 0)

	local font, size = text:GetFont()
	if font then
		text:SetFont(font, math.max(10, tonumber(size) or 10), "OUTLINE")
	end

	button.CoAAnalyticsItemLevelText = text
	return text
end

local function TrackButton(button, slotID)
	if not button or type(button.CreateFontString) ~= "function" then
		return
	end

	trackedButtons[button] = slotID
	EnsureItemLevelText(button)

	if not button.CoAAnalyticsItemLevelOnShow then
		button.CoAAnalyticsItemLevelOnShow = true
		button:HookScript("OnShow", function()
			ScheduleRefresh(0)
		end)
	end
end

local function InstallRefreshHooks()
	if type(hooksecurefunc) ~= "function" then
		return
	end

	for _, functionName in ipairs(REFRESH_HOOKS) do
		if not installedHooks[functionName]
			and type(_G[functionName]) == "function"
		then
			hooksecurefunc(functionName, function()
				ScheduleRefresh(0)
			end)
			installedHooks[functionName] = true
		end
	end
end

local function DiscoverButtons()
	InstallRefreshHooks()
	for _, prefix in ipairs(FRAME_PREFIXES) do
		for slotID, slotName in pairs(SLOT_NAMES) do
			TrackButton(_G[prefix .. slotName .. "Slot"], slotID)
		end
	end
end

local function RefreshButtons()
	DiscoverButtons()
	local waitingForItemInfo = false

	for button, slotID in pairs(trackedButtons) do
		local text = EnsureItemLevelText(button)
		local itemLink = GetInventoryItemLink("player", slotID)
		local itemLevel = GetEffectiveItemLevel(itemLink)
		if itemLevel then
			text:SetText(math.floor(itemLevel + 0.5))
		else
			text:SetText("")
			if itemLink then
				waitingForItemInfo = true
			end
		end
	end

	return waitingForItemInfo
end

ScheduleRefresh = function(delay, retries)
	delay = math.max(0, tonumber(delay) or 0)
	if not refreshPending or delay < refreshDelay then
		refreshDelay = delay
	end
	refreshPending = true
	refreshRetries = math.max(refreshRetries, tonumber(retries) or 0)
	driver:Show()
end

function ItemLevels.Refresh()
	refreshPending = false
	refreshDelay = 0
	local waitingForItemInfo = RefreshButtons()
	if waitingForItemInfo and refreshRetries < 5 then
		refreshRetries = refreshRetries + 1
		ScheduleRefresh(0.5, refreshRetries)
	else
		refreshRetries = 0
		if not refreshPending then
			driver:Hide()
		end
	end
end

driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
driver:RegisterEvent("UNIT_INVENTORY_CHANGED")
pcall(driver.RegisterEvent, driver, "GET_ITEM_INFO_RECEIVED")
driver:SetScript("OnEvent", function(_, event, unit)
	if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then
		return
	end
	ScheduleRefresh(0, 0)
end)
driver:SetScript("OnUpdate", function(_, elapsed)
	if not refreshPending then
		driver:Hide()
		return
	end

	refreshDelay = refreshDelay - elapsed
	if refreshDelay <= 0 then
		ItemLevels.Refresh()
	end
end)
driver:Hide()
