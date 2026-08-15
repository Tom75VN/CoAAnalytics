local ItemLevels = {}
CoAAnalyticsAddon.Modules.CharacterItemLevels = ItemLevels

local SLOT_NAMES = {
	"Head",
	"Neck",
	"Shoulder",
	"Shirt",
	"Chest",
	"Waist",
	"Legs",
	"Feet",
	"Wrist",
	"Hands",
	"Finger0",
	"Finger1",
	"Trinket0",
	"Trinket1",
	"Back",
	"MainHand",
	"SecondaryHand",
	"Ranged",
	"Tabard",
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
	"AscensionCharacterFrame_UpdateCharacterInfo",
	"PaperDollItemSlotButton_Update",
}

local CHARACTER_FRAMES = {
	"AscensionCharacterFrame",
	"AscensionPaperDollPanel",
	"CharacterFrame",
	"PaperDollFrame",
}

local trackedButtons = setmetatable({}, { __mode = "k" })
local hookedFrames = setmetatable({}, { __mode = "k" })
local installedHooks = {}
local refreshPending = false
local refreshDelay = 0
local refreshRetries = 0
local driver = CreateFrame("Frame")

local ScheduleRefresh

local function GetEffectiveItemLevel(itemReference)
	if itemReference == nil or itemReference == "" then
		return nil
	end

	local detailedGetter = _G.GetDetailedItemLevelInfo
	if type(detailedGetter) ~= "function"
		and type(_G.C_Item) == "table"
	then
		detailedGetter = _G.C_Item.GetDetailedItemLevelInfo
	end
	if type(detailedGetter) == "function" then
		local ok, itemLevel = pcall(detailedGetter, itemReference)
		itemLevel = ok and tonumber(itemLevel) or nil
		if itemLevel and itemLevel > 0 then
			return itemLevel
		end
	end

	local itemLevel = tonumber(select(4, GetItemInfo(itemReference)))
	if itemLevel and itemLevel > 0 then
		return itemLevel
	end
	return nil
end

local function EnsureItemLevelText(button)
	local text = button.CoAAnalyticsItemLevelText
	if button.ItemLevel
		and type(button.ItemLevel.SetText) == "function"
		and button.ItemLevel ~= text
	then
		if text then
			text:SetText("")
		end
		text = button.ItemLevel
	end

	if not text then
		text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	end

	text:ClearAllPoints()
	text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
	text:SetJustifyH("RIGHT")
	text:SetJustifyV("BOTTOM")
	text:SetTextColor(1, 0.82, 0)
	text:Show()

	local font, size = text:GetFont()
	text:SetFont(
		font or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
		math.max(11, tonumber(size) or 11),
		"OUTLINE"
	)

	button.CoAAnalyticsItemLevelText = text
	return text
end

local function ResolveSlotID(button, slotName, fallbackSlotID)
	local slotID
	if type(GetInventorySlotInfo) == "function" then
		slotID = GetInventorySlotInfo(slotName .. "Slot")
	end
	if not slotID and button.GetID then
		slotID = button:GetID()
	end
	return tonumber(slotID) or fallbackSlotID
end

local function TrackButton(button, slotName, fallbackSlotID)
	if not button or type(button.CreateFontString) ~= "function" then
		return
	end

	trackedButtons[button] = ResolveSlotID(button, slotName, fallbackSlotID)
	EnsureItemLevelText(button)

	if not button.CoAAnalyticsItemLevelOnShow then
		button.CoAAnalyticsItemLevelOnShow = true
		button:HookScript("OnShow", function()
			ScheduleRefresh(0)
		end)
	end
end

local function InstallFrameHooks()
	for _, frameName in ipairs(CHARACTER_FRAMES) do
		local frame = _G[frameName]
		if frame and not hookedFrames[frame]
			and type(frame.HookScript) == "function"
		then
			frame:HookScript("OnShow", function()
				ScheduleRefresh(0)
			end)
			hookedFrames[frame] = true
		end
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
	InstallFrameHooks()
	for _, prefix in ipairs(FRAME_PREFIXES) do
		for fallbackSlotID, slotName in ipairs(SLOT_NAMES) do
			TrackButton(
				_G[prefix .. slotName .. "Slot"],
				slotName,
				fallbackSlotID
			)
		end
	end
end

local function RefreshButtons()
	DiscoverButtons()
	local waitingForItemInfo = false
	local buttonCount = 0

	for button, slotID in pairs(trackedButtons) do
		buttonCount = buttonCount + 1
		local text = EnsureItemLevelText(button)
		local itemLink = GetInventoryItemLink("player", slotID)
		local itemReference = itemLink
		if not itemReference and type(GetInventoryItemID) == "function" then
			itemReference = GetInventoryItemID("player", slotID)
		end
		local itemLevel = GetEffectiveItemLevel(itemReference)
		if itemLevel then
			text:SetText(math.floor(itemLevel + 0.5))
		else
			text:SetText("")
			if itemReference then
				waitingForItemInfo = true
			end
		end
	end

	return waitingForItemInfo, buttonCount
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
	local waitingForItemInfo, buttonCount = RefreshButtons()
	if buttonCount == 0 then
		refreshRetries = 0
		ScheduleRefresh(1, 0)
	elseif waitingForItemInfo and refreshRetries < 5 then
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
ScheduleRefresh(0, 0)
