local Advisor = _G.CoAAnalyticsAdvisor

Advisor.LootAdvisor = Advisor.LootAdvisor or {}
local LootAdvisor = Advisor.LootAdvisor

local eventFrame = CreateFrame("Frame")
local popupDismissFrame = CreateFrame("Frame")
local pending = {}
local autoGreedRolls = {}
local popupDismissals = {}
local initialized = false
local compatibilityTooltip

-- Only item classes that are unambiguously crafting materials on an English
-- 3.3.5 client belong here.  Recipes, quest items, consumables and generic
-- Miscellaneous items intentionally remain manual.
local SAFE_MATERIAL_TYPES = {
    ["Trade Goods"] = true,
    ["Gem"] = true,
    ["Reagent"] = true,
}

-- Les Keystone ne doivent jamais recevoir un jet automatique. Ascension peut
-- les exposer comme Miscellaneous, Quest ou même Trade Goods selon la version
-- du contenu : la protection repose donc sur leur identité et leur tooltip,
-- jamais uniquement sur la classe d'objet renvoyée par GetItemInfo.
local PROTECTED_KEYSTONE_TERMS = {
    "keystone",
    "mythic key",
    "mythic+ key",
    "mythic dungeon key",
    "clé mythique",
    "cle mythique",
    "pierre mythique",
}

local EXCLUDABLE_STATS = {
    { key = "strength", label = "Force" },
    { key = "agility", label = "Agilité" },
    { key = "intellect", label = "Intelligence" },
    { key = "spirit", label = "Esprit" },
    { key = "stamina", label = "Endurance" },
    { key = "spellPower", label = "Puissance des sorts" },
    { key = "bonusHealing", label = "Bonus de soins" },
    { key = "attackPower", label = "Puissance d’attaque" },
    { key = "haste", label = "Hâte" },
    { key = "crit", label = "Critique" },
    { key = "hit", label = "Toucher (Hit Rating)" },
    { key = "armorPenetration", label = "Pénétration d’armure" },
    { key = "spellPenetration", label = "Pénétration des sorts" },
    { key = "resilience", label = "Résilience" },
    { key = "mp5", label = "Mana par 5 s" },
    { key = "hp5", label = "Vie par 5 s" },
    { key = "pvePower", label = "Puissance JcE" },
    { key = "pvpPower", label = "Puissance JcJ" },
}

local function IsTrue(value)
    return value == true or value == 1
end

local function EnsureSettings()
    local database = Advisor.GetDatabase and Advisor.GetDatabase() or
        _G.CoAAnalyticsAdvisorDB
    if type(database) ~= "table" then
        database = {}
        _G.CoAAnalyticsAdvisorDB = database
    end
    if database.autoGreedIncompatibleLoot == nil then
        database.autoGreedIncompatibleLoot =
            database.autoPassIncompatibleLoot == true
    end
    if type(database.autoGreedExcludedStatsByCharacter) ~= "table" then
        database.autoGreedExcludedStatsByCharacter = {}
    end
    return database
end

local function GetCharacterFilterKey()
    local guid = Advisor.SafeCall(UnitGUID, "player")
    if type(guid) ~= "string" or guid == "" then guid = nil end
    local name = UnitName("player") or "unknown"
    local realm = type(GetRealmName) == "function" and
        GetRealmName() or "unknown"
    local legacyKey = tostring(realm) .. ":" .. tostring(name)
    return guid and tostring(guid) or legacyKey, legacyKey
end

local function GetCharacterExcludedStats()
    local database = EnsureSettings()
    local key, legacyKey = GetCharacterFilterKey()
    local byCharacter = database.autoGreedExcludedStatsByCharacter
    if key ~= legacyKey and type(byCharacter[key]) ~= "table" and
        type(byCharacter[legacyKey]) == "table" then
        byCharacter[key] = byCharacter[legacyKey]
    end
    if type(byCharacter[key]) ~= "table" then byCharacter[key] = {} end
    return byCharacter[key]
end

function LootAdvisor.IsAutoGreedEnabled()
    local database = EnsureSettings()
    return database.autoGreedIncompatibleLoot == true
end

function LootAdvisor.SetAutoGreedEnabled(enabled, announce)
    local database = EnsureSettings()
    database.autoGreedIncompatibleLoot = enabled and true or false
    if announce ~= false then
        Advisor.Print(
            enabled and
            "jets de cupidité automatiques activés pour le butin incompatible confirmé et les matériaux sûrs." or
            "jets de cupidité automatiques désactivés."
        )
    end
    if Advisor.UI and Advisor.UI.RefreshIfVisible then
        Advisor.UI.RefreshIfVisible()
    end
end

function LootAdvisor.GetExcludableStats()
    return EXCLUDABLE_STATS
end

function LootAdvisor.IsStatExcluded(key)
    return GetCharacterExcludedStats()[key] == true
end

function LootAdvisor.SetStatExcluded(key, excluded)
    local excludedStats = GetCharacterExcludedStats()
    local known = false
    for _, option in ipairs(EXCLUDABLE_STATS) do
        if option.key == key then known = true break end
    end
    if not known then return false end
    if excluded then
        excludedStats[key] = true
    else
        excludedStats[key] = nil
    end
    return true
end

function LootAdvisor.ResetExcludedStats()
    local database = EnsureSettings()
    local key = GetCharacterFilterKey()
    database.autoGreedExcludedStatsByCharacter[key] = {}
end

function LootAdvisor.GetExcludedStatLabels()
    local labels = {}
    for _, option in ipairs(EXCLUDABLE_STATS) do
        if LootAdvisor.IsStatExcluded(option.key) then
            labels[#labels + 1] = option.label
        end
    end
    return labels
end

local function GetCompatibilityTooltip()
    if compatibilityTooltip then return compatibilityTooltip end
    compatibilityTooltip = CreateFrame(
        "GameTooltip",
        "CoAAnalyticsAdvisorCompatibilityTooltip",
        UIParent,
        "GameTooltipTemplate"
    )
    compatibilityTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    return compatibilityTooltip
end

local function ContainsProtectedKeystoneTerm(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
    value = string.gsub(value, "|r", "")
    for _, term in ipairs(PROTECTED_KEYSTONE_TERMS) do
        if string.find(value, term, 1, true) then return true end
    end
    return false
end

local function TooltipIdentifiesKeystone(itemLink)
    if not itemLink then return false end
    local tooltip = GetCompatibilityTooltip()
    tooltip:Hide()
    tooltip:ClearLines()
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    local ok = pcall(tooltip.SetHyperlink, tooltip, itemLink)
    if not ok then
        tooltip:Hide()
        return false
    end
    tooltip:Show()
    local lines = Advisor.GetTooltipLines(tooltip)
    tooltip:Hide()
    for _, pair in ipairs(lines or {}) do
        if ContainsProtectedKeystoneTerm(pair.left) or
            ContainsProtectedKeystoneTerm(pair.right) then
            return true
        end
    end
    return false
end

local function IsProtectedKeystone(roll, itemName, itemType, itemSubtype)
    if ContainsProtectedKeystoneTerm(itemName) or
        ContainsProtectedKeystoneTerm(itemType) or
        ContainsProtectedKeystoneTerm(itemSubtype) or
        ContainsProtectedKeystoneTerm(roll and roll.name) or
        ContainsProtectedKeystoneTerm(roll and roll.itemLink) then
        return true
    end
    return TooltipIdentifiesKeystone(roll and roll.itemLink)
end

local function NormalizeSubtype(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[%p%s]", "")
    local aliases = {
        staves = "staff",
        staff = "staff",
        polearms = "polearm",
        fistweapons = "fistweapon",
        thrown = "thrown",
    }
    if aliases[value] then return aliases[value] end
    if string.sub(value, -1) == "s" then
        value = string.sub(value, 1, -2)
    end
    return value
end

local function IsRedText(region)
    if not region or type(region.GetTextColor) ~= "function" then
        return false
    end
    local red, green, blue = Advisor.SafeCall(region.GetTextColor, region)
    red = tonumber(red)
    green = tonumber(green)
    blue = tonumber(blue)
    return red and green and blue and
        red >= 0.80 and green <= 0.42 and blue <= 0.42 and
        red >= green * 1.65
end

local function ScanSubtypeColor(itemLink, itemSubtype)
    local wanted = NormalizeSubtype(itemSubtype)
    if wanted == "" then return nil end

    local tooltip = GetCompatibilityTooltip()
    tooltip:Hide()
    tooltip:ClearLines()
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    local ok = pcall(tooltip.SetHyperlink, tooltip, itemLink)
    if not ok then
        tooltip:Hide()
        return nil
    end

    local tooltipName = tooltip:GetName()
    local lineCount = tonumber(tooltip:NumLines()) or 0
    local foundRed = false
    local foundNormal = false
    local visibleSubtype
    local function InspectRegion(region)
        local text = Advisor.GetFrameText(region)
        if text and NormalizeSubtype(text) == wanted then
            visibleSubtype = text
            if IsRedText(region) then
                foundRed = true
            else
                foundNormal = true
            end
        end
    end
    for line = 1, math.min(lineCount, 9) do
        local left = _G[tooltipName .. "TextLeft" .. line]
        local right = _G[tooltipName .. "TextRight" .. line]
        InspectRegion(left)
        InspectRegion(right)
    end
    tooltip:Hide()

    if foundRed and not foundNormal then return true, visibleSubtype end
    if foundNormal then return false, visibleSubtype end
    return nil
end

local function ScanItemStats(itemLink)
    local tooltip = GetCompatibilityTooltip()
    tooltip:Hide()
    tooltip:ClearLines()
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    local ok = pcall(tooltip.SetHyperlink, tooltip, itemLink)
    if not ok then
        tooltip:Hide()
        return nil
    end
    tooltip:Show()
    local parsed
    if Advisor.TooltipParser and Advisor.TooltipParser.FromTooltip then
        parsed = Advisor.TooltipParser.FromTooltip(tooltip, itemLink)
    end
    tooltip:Hide()

    -- START_LOOT_ROLL may fire before every tooltip line is populated. Merge
    -- missing values from GetItemStats so filters such as Hit Rating still
    -- trigger during that short cache window without double-counting stats.
    local stats = {}
    local found = false
    local function MergeMissing(source)
        for key, value in pairs(source or {}) do
            value = tonumber(value)
            if value and value > 0 then
                found = true
                if stats[key] == nil then stats[key] = value end
            end
        end
    end
    MergeMissing(parsed and parsed.stats)
    if Advisor.TooltipParser and Advisor.TooltipParser.FromAPI then
        local apiParsed = Advisor.TooltipParser.FromAPI(itemLink)
        MergeMissing(apiParsed and apiParsed.stats)
    end
    return found and stats or nil
end

local function GetMatchedExcludedStats(itemLink)
    EnsureSettings()
    local hasExcludedStat = false
    for _, option in ipairs(EXCLUDABLE_STATS) do
        if LootAdvisor.IsStatExcluded(option.key) then
            hasExcludedStat = true
            break
        end
    end
    if not hasExcludedStat then return {}, true end

    local stats = ScanItemStats(itemLink)
    if type(stats) ~= "table" then return nil, false end
    local matches = {}
    for _, option in ipairs(EXCLUDABLE_STATS) do
        if LootAdvisor.IsStatExcluded(option.key) and
            (tonumber(stats[option.key]) or 0) > 0 then
            matches[#matches + 1] = option.label
        end
    end
    return matches, true
end

local function FindRollFrame(rollID)
    for index = 1, 20 do
        for _, prefix in ipairs({ "ElvUI_GroupLootFrame", "GroupLootFrame" }) do
            local frame = _G[prefix .. tostring(index)]
            if frame and
                (frame.rollID == rollID or
                    (frame.itemButton and frame.itemButton.rollID == rollID)) then
                return frame
            end
        end
    end
    return nil
end

local function MarkRollFrame(rollID, itemName, confirmedForAutoGreed)
    local frame = FindRollFrame(rollID)
    if not frame then return false end
    local nameRegion = frame.itemName
    if not nameRegion and type(frame.GetName) == "function" then
        local frameName = frame:GetName()
        if frameName then nameRegion = _G[frameName .. "Name"] end
    end
    if not nameRegion or type(nameRegion.SetText) ~= "function" then
        return false
    end
    local current = Advisor.GetFrameText(nameRegion) or itemName or ""
    if not string.find(current, "INCOMPATIBLE", 1, true) then
        local label
        if confirmedForAutoGreed then
            label = "INCOMPATIBLE"
        elseif Advisor.GetLanguage and Advisor.GetLanguage() == "en" then
            label = "INCOMPATIBLE - MANUAL"
        else
            label = "INCOMPATIBLE - MANUEL"
        end
        nameRegion:SetText("|cffff3030[" .. label .. "]|r " .. current)
    end
    return true
end

local function GetRollInformation(rollID)
    if type(GetLootRollItemInfo) ~= "function" or
        type(GetLootRollItemLink) ~= "function" then
        return nil
    end
    local ok, texture, name, count, quality, bindOnPickUp, canNeed,
        canGreed, canDisenchant, reasonNeed =
        pcall(GetLootRollItemInfo, rollID)
    if not ok then return nil end
    local linkOk, itemLink = pcall(GetLootRollItemLink, rollID)
    if not linkOk or not itemLink then return nil end
    return {
        texture = texture,
        name = name,
        count = count,
        quality = quality,
        bindOnPickUp = IsTrue(bindOnPickUp),
        canNeed = IsTrue(canNeed),
        canGreed = IsTrue(canGreed),
        canDisenchant = IsTrue(canDisenchant),
        reasonNeed = tonumber(reasonNeed),
        itemLink = itemLink,
    }
end

function LootAdvisor.EvaluateRoll(rollID)
    local roll = GetRollInformation(rollID)
    if not roll then return { retry = true } end

    local ok, itemName, itemLink, rarity, itemLevel, requiredLevel,
        itemType, itemSubtype, stackCount, equipLocation =
        pcall(GetItemInfo, roll.itemLink)
    if not ok or not itemName then return { retry = true } end
    -- Ce test précède volontairement SAFE_MATERIAL_TYPES et les statistiques
    -- exclues. Une Keystone mal classée par le serveur reste toujours manuelle.
    if IsProtectedKeystone(roll, itemName, itemType, itemSubtype) then
        return {
            state = "protectedKeystone",
            confirmed = true,
            reason = "Keystone protégée : aucun jet automatique",
            autoGreedEligible = false,
            roll = roll,
        }
    end
    if SAFE_MATERIAL_TYPES[itemType] then
        return {
            state = "material",
            confirmed = true,
            subtype = itemSubtype or itemType,
            reason = "catégorie de matériau sûre",
            autoGreedEligible = roll.canGreed,
            roll = roll,
        }
    end
    if not equipLocation or equipLocation == "" then
        return { state = "ignored", roll = roll }
    end
    if itemType ~= "Armor" and itemType ~= "Weapon" then
        return { state = "ignored", roll = roll }
    end

    local excludedStatMatches, excludedStatsScanned =
        GetMatchedExcludedStats(roll.itemLink)
    if not excludedStatsScanned then return { retry = true } end
    if excludedStatMatches and #excludedStatMatches > 0 then
        return {
            state = "statExcluded",
            confirmed = true,
            matchedStats = excludedStatMatches,
            reason = "statistique exclue par l’utilisateur",
            autoGreedEligible = roll.canGreed,
            roll = roll,
        }
    end

    requiredLevel = tonumber(requiredLevel) or 0
    local playerLevel = tonumber(UnitLevel("player")) or 0
    if requiredLevel > playerLevel then
        return {
            state = "uncertain",
            reason = "niveau requis non atteint",
            roll = roll,
        }
    end

    local usabilityKnown = type(IsUsableItem) == "function"
    local usable
    if usabilityKnown then
        local usableOk, result = pcall(IsUsableItem, roll.itemLink)
        usabilityKnown = usableOk
        usable = IsTrue(result)
    end

    local subtypeRed, visibleSubtype =
        ScanSubtypeColor(roll.itemLink, itemSubtype)
    if usabilityKnown and usable == false and subtypeRed == true then
        local serverClassRestriction =
            roll.canNeed == false and roll.reasonNeed == 1
        return {
            state = "incompatible",
            confirmed = serverClassRestriction,
            subtype = visibleSubtype or itemSubtype,
            reason = serverClassRestriction and
                "restriction de classe confirmée par le serveur" or
                "incompatibilité actuelle sans confirmation permanente du serveur",
            autoGreedEligible =
                roll.canGreed and serverClassRestriction,
            roll = roll,
        }
    end
    if usabilityKnown and usable == true and subtypeRed == false then
        return { state = "compatible", roll = roll }
    end
    return {
        state = "uncertain",
        reason = "compatibilité non confirmée",
        roll = roll,
    }
end

local function ApplyEvaluation(rollID, evaluation)
    if not evaluation or not evaluation.roll then return end
    if evaluation.state ~= "incompatible" and
        evaluation.state ~= "material" and
        evaluation.state ~= "statExcluded" then
        return
    end

    local roll = evaluation.roll
    if evaluation.state == "incompatible" then
        MarkRollFrame(rollID, roll.name, evaluation.confirmed)
    end
    if not evaluation.confirmed then return end
    if not LootAdvisor.IsAutoGreedEnabled() or
        not evaluation.autoGreedEligible then
        return
    end

    -- Verrou final indépendant de l'évaluation précédente : même si le cache
    -- ou la catégorie de l'objet change entre START_LOOT_ROLL et maintenant,
    -- RollOnLoot ne sera jamais appelé pour une Keystone reconnue.
    if IsProtectedKeystone(
        roll,
        roll.name,
        nil,
        evaluation.subtype
    ) then
        autoGreedRolls[rollID] = nil
        return
    end

    if type(GetLootRollTimeLeft) == "function" then
        local ok, timeLeft = pcall(GetLootRollTimeLeft, rollID)
        if ok and tonumber(timeLeft) and tonumber(timeLeft) <= 0 then return end
    end
    if type(RollOnLoot) ~= "function" then return end
    autoGreedRolls[rollID] = {
        itemLink = roll.itemLink,
        state = evaluation.state,
        subtype = evaluation.subtype,
        bindOnPickUp = roll.bindOnPickUp,
    }
    local ok = pcall(RollOnLoot, rollID, 2)
    if ok then
        if evaluation.state == "material" then
            Advisor.PrintLoot(
                "cupidité automatique sélectionnée : " ..
                tostring(roll.itemLink) .. " — matériau sûr."
            )
        elseif evaluation.state == "statExcluded" then
            Advisor.PrintLoot(
                "cupidité automatique sélectionnée : " ..
                tostring(roll.itemLink) .. " — statistique exclue : " ..
                table.concat(evaluation.matchedStats or {}, ", ") .. "."
            )
        else
            Advisor.PrintLoot(
                "cupidité automatique sélectionnée : " ..
                tostring(roll.itemLink) .. " — " ..
                tostring(evaluation.subtype or "équipement") ..
                " incompatible avec ce personnage."
            )
        end
    else
        autoGreedRolls[rollID] = nil
    end
end

local function HasPopupDismissals()
    for _ in pairs(popupDismissals) do return true end
    return false
end

local function DismissConfirmedPopup(self)
    for rollID, request in pairs(popupDismissals) do
        request.attempts = request.attempts + 1
        local dismissed = false
        local popupCount = tonumber(STATICPOPUP_NUMDIALOGS) or 4
        for index = 1, popupCount do
            local dialog = _G["StaticPopup" .. tostring(index)]
            if dialog and dialog:IsShown() and
                dialog.which == "CONFIRM_LOOT_ROLL" and
                (tonumber(dialog.data) or dialog.data) == rollID and
                tonumber(dialog.data2) == request.rollType then
                dialog:Hide()
                dismissed = true
            end
        end
        if dismissed or request.attempts >= 5 then
            popupDismissals[rollID] = nil
        end
    end
    if not HasPopupDismissals() then self:SetScript("OnUpdate", nil) end
end

local function QueuePopupDismissal(rollID, rollType)
    popupDismissals[rollID] = {
        rollType = tonumber(rollType),
        attempts = 0,
    }
    popupDismissFrame:SetScript("OnUpdate", DismissConfirmedPopup)
end

local function ConfirmTrackedGreed(rollID, rollType)
    rollID = tonumber(rollID) or rollID
    rollType = tonumber(rollType)
    local tracked = autoGreedRolls[rollID]
    -- Never confirm a manual player choice, a Need roll or Disenchant.
    if not tracked or rollType ~= 2 then return false end
    if tracked.bindingConfirmed then return true end
    if type(ConfirmLootRoll) ~= "function" then return false end

    local ok = pcall(ConfirmLootRoll, rollID, 2)
    if not ok then return false end
    tracked.bindingConfirmed = true
    QueuePopupDismissal(rollID, rollType)
    Advisor.PrintLoot(
        "liaison confirmée automatiquement pour le jet de cupidité : " ..
        tostring(tracked.itemLink or "objet") .. "."
    )
    return true
end

local function HasPendingRolls()
    for _ in pairs(pending) do return true end
    return false
end

local function ProcessPending(self)
    local now = GetTime()
    for rollID, request in pairs(pending) do
        if now >= request.nextAttempt then
            request.attempts = request.attempts + 1
            local evaluation = LootAdvisor.EvaluateRoll(rollID)
            if evaluation and evaluation.retry and now < request.deadline and
                request.attempts < 20 then
                request.nextAttempt = now + 0.10
            else
                pending[rollID] = nil
                ApplyEvaluation(rollID, evaluation)
            end
        end
    end
    if not HasPendingRolls() then self:SetScript("OnUpdate", nil) end
end

local function QueueRoll(rollID)
    rollID = tonumber(rollID)
    if not rollID then return end
    local now = GetTime()
    pending[rollID] = {
        attempts = 0,
        nextAttempt = now,
        deadline = now + 2,
    }
    eventFrame:SetScript("OnUpdate", ProcessPending)
end

local function RemoveRoll(rollID)
    rollID = tonumber(rollID) or rollID
    pending[rollID] = nil
    autoGreedRolls[rollID] = nil
    if not HasPendingRolls() then eventFrame:SetScript("OnUpdate", nil) end
end

function LootAdvisor.Initialize()
    if initialized then return end
    initialized = true
    EnsureSettings()
    if type(GetLootRollItemInfo) ~= "function" or
        type(GetLootRollItemLink) ~= "function" or
        type(RollOnLoot) ~= "function" then
        return
    end
    eventFrame:RegisterEvent("START_LOOT_ROLL")
    eventFrame:RegisterEvent("CANCEL_LOOT_ROLL")
    pcall(eventFrame.RegisterEvent, eventFrame, "CONFIRM_LOOT_ROLL")
    pcall(eventFrame.RegisterEvent, eventFrame, "LOOT_ROLLS_COMPLETE")
    eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
        if event == "START_LOOT_ROLL" then
            QueueRoll(arg1)
        elseif event == "CANCEL_LOOT_ROLL" then
            RemoveRoll(arg1)
        elseif event == "CONFIRM_LOOT_ROLL" then
            ConfirmTrackedGreed(arg1, arg2)
        elseif event == "LOOT_ROLLS_COMPLETE" then
            pending = {}
            autoGreedRolls = {}
            eventFrame:SetScript("OnUpdate", nil)
        end
    end)
end
