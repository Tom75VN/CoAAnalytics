local Advisor = _G.CoAAnalyticsAdvisor

Advisor.TalentScanner = {
    cache = {
        all = {}, selected = {}, byName = {}, bySpellID = {},
        capturedAt = 0,
    },
}
local Scanner = Advisor.TalentScanner

local function ReadMaxRank(globalName, currentRank)
    local rankRegion = _G[globalName .. "RankFrameRank"]
    local text = Advisor.GetFrameText(rankRegion)
    local _, maximum = string.match(text or "", "(%d+)%s*/%s*(%d+)")
    return tonumber(maximum) or math.max(tonumber(currentRank) or 0, 1)
end

local function IsTalentButton(globalName)
    if not string.find(globalName, "^CoATalentFrameTreeView") then return nil end
    local tree
    if string.find(globalName, "TreeViewClassTreePoolFrame", 1, true) then
        tree = "class"
    elseif string.find(globalName, "TreeViewSpecTreePoolFrame", 1, true) then
        tree = "specialization"
    else
        return nil
    end
    local circle = string.match(globalName, "CoATalentButtonCircleTemplate%d+$")
    local square = string.match(globalName, "CoATalentButtonSquareTemplate%d+$")
    if not circle and not square then return nil end
    return tree, circle and "passive" or "ability"
end

local function SpellName(spellID)
    local name, rank, icon = Advisor.SafeCall(GetSpellInfo, spellID)
    name = name or Advisor.Data.spellNameOverrides[spellID]
    return name or ("Spell " .. tostring(spellID)), rank, icon
end

local function DescriptionStore(identity)
    if not CoAAnalyticsAdvisorDB then return nil end
    CoAAnalyticsAdvisorDB.talentDescriptions =
        CoAAnalyticsAdvisorDB.talentDescriptions or {}
    CoAAnalyticsAdvisorDB.talentDescriptions[identity] =
        CoAAnalyticsAdvisorDB.talentDescriptions[identity] or {}
    return CoAAnalyticsAdvisorDB.talentDescriptions[identity]
end

local function SavedDescription(store, spellID, spellName)
    if type(store) ~= "table" then return nil end
    return store[tostring(spellID)] or store[spellName]
end

local function CaptureDescription(frame, spellName)
    if not GameTooltip or not Advisor.TalentEngine then return nil end
    local onEnter = Advisor.SafeCall(frame.GetScript, frame, "OnEnter")
    if type(onEnter) ~= "function" then return nil end

    Advisor.SafeCall(GameTooltip.Hide, GameTooltip)
    local ok = pcall(onEnter, frame)
    if not ok then
        Advisor.SafeCall(GameTooltip.Hide, GameTooltip)
        return nil
    end
    local lines = Advisor.GetTooltipLines(GameTooltip)
    local description =
        Advisor.TalentEngine.ExtractDescription(lines, spellName)
    local onLeave = Advisor.SafeCall(frame.GetScript, frame, "OnLeave")
    if type(onLeave) == "function" then pcall(onLeave, frame) end
    Advisor.SafeCall(GameTooltip.Hide, GameTooltip)
    return description
end

local function ToBoolean(value)
    if type(value) == "boolean" then return value end
    if type(value) == "number" then return value ~= 0 end
    return nil
end

local function ReadBooleanField(object, fieldName)
    if not object then return nil, false end
    local ok, value = pcall(function() return object[fieldName] end)
    if not ok then return nil, false end
    value = ToBoolean(value)
    return value, value ~= nil
end

local function CallBooleanMethod(object, methodName)
    if not object then return nil, false end
    local ok, method = pcall(function() return object[methodName] end)
    if not ok or type(method) ~= "function" then return nil, false end
    local value = Advisor.SafeCall(method, object)
    value = ToBoolean(value)
    return value, value ~= nil
end

local function ReadDesaturation(texture)
    local value, known = CallBooleanMethod(texture, "IsDesaturated")
    if known then return value, true end
    value, known = CallBooleanMethod(texture, "GetDesaturated")
    if known then return value, true end
    return nil, false
end

local function ReadAvailability(frame, globalName, rank, maxRank, lockShown)
    if rank >= maxRank then return false, "maximum-rank" end
    if lockShown then return false, "lock-icon" end

    for _, fieldName in ipairs({
        "locked", "isLocked", "disabled", "unavailable",
    }) do
        local value, known = ReadBooleanField(frame, fieldName)
        if known and value then return false, fieldName end
    end
    for _, methodName in ipairs({
        "IsLocked", "IsUnavailable",
    }) do
        local value, known = CallBooleanMethod(frame, methodName)
        if known and value then return false, methodName end
    end

    for _, fieldName in ipairs({
        "available", "isAvailable", "canLearn", "canPurchase",
        "meetsPrerequisites", "unlocked",
    }) do
        local value, known = ReadBooleanField(frame, fieldName)
        if known then
            return value, value and fieldName or ("not-" .. fieldName)
        end
    end
    for _, methodName in ipairs({
        "IsAvailable", "CanLearn", "CanPurchase", "MeetsPrerequisites",
    }) do
        local value, known = CallBooleanMethod(frame, methodName)
        if known then
            return value, value and methodName or ("not-" .. methodName)
        end
    end

    -- A partially learned talent is already on a valid path. Its next rank is
    -- a safe recommendation even when the player currently has zero points.
    if rank > 0 then return true, "selected-next-rank" end

    local iconButton = _G[globalName .. "Icon"]
    local iconEnabled, enabledKnown =
        CallBooleanMethod(iconButton, "IsEnabled")
    if enabledKnown and not iconEnabled then
        return false, "icon-disabled"
    end

    local iconTexture = _G[globalName .. "IconIcon"]
    local desaturated, desaturationKnown = ReadDesaturation(iconTexture)
    if desaturationKnown and desaturated then
        return false, "icon-desaturated"
    end

    -- For a new node, require two positive UI signals. This deliberately
    -- prefers omitting an uncertain choice over recommending a distant node.
    if enabledKnown and iconEnabled and
        desaturationKnown and not desaturated then
        return true, "icon-enabled-and-colored"
    end
    return false, "availability-unverified"
end

function Scanner.Refresh(captureDescriptions)
    local _, classToken = UnitClass("player")
    local specialization = Advisor.SafeCall(GetSpecialization)
    local identity =
        tostring(classToken or "") .. ":" .. tostring(specialization or "")
    local result = {
        all = {},
        selected = {},
        byName = {},
        bySpellID = {},
        capturedAt = Advisor.Now(),
        availabilityVersion = 2,
        identity = identity,
    }
    local descriptions = DescriptionStore(identity)

    for globalName, frame in pairs(_G) do
        if type(globalName) == "string" and
            (type(frame) == "table" or type(frame) == "userdata") then
            local tree, talentType = IsTalentButton(globalName)
            if tree and type(frame.spellID) == "number" then
                local rank = tonumber(frame.rank) or 0
                local maxRank = ReadMaxRank(globalName, rank)
                local spellName, spellRank, icon = SpellName(frame.spellID)
                local lock = _G[globalName .. "IconLockIcon"]
                local locked = lock and Advisor.SafeCall(lock.IsShown, lock) and true or false
                local enabled = Advisor.SafeCall(frame.IsEnabled, frame)
                local available, availabilityReason =
                    ReadAvailability(
                        frame,
                        globalName,
                        rank,
                        maxRank,
                        locked
                    )
                local description =
                    SavedDescription(descriptions, frame.spellID, spellName)
                if captureDescriptions then
                    local captured = CaptureDescription(frame, spellName)
                    if captured and captured ~= "" then
                        description = captured
                        if descriptions then
                            descriptions[tostring(frame.spellID)] = captured
                            descriptions[spellName] = captured
                        end
                    end
                end
                local talent = {
                    globalName = globalName,
                    tree = tree,
                    talentType = talentType,
                    spellID = frame.spellID,
                    name = spellName,
                    spellRank = spellRank,
                    icon = icon,
                    rank = rank,
                    maxRank = maxRank,
                    locked = locked,
                    enabled = enabled and true or false,
                    available = available,
                    availabilityReason = availabilityReason,
                    description = description,
                }
                result.all[#result.all + 1] = talent
                if rank > 0 then result.selected[#result.selected + 1] = talent end
                result.byName[spellName] = talent
                result.bySpellID[frame.spellID] = talent
            end
        end
    end

    table.sort(result.all, function(a, b)
        if a.tree ~= b.tree then return a.tree < b.tree end
        return a.globalName < b.globalName
    end)

    if #result.all > 0 then
        Scanner.cache = result
        if CoAAnalyticsAdvisorDB then
            CoAAnalyticsAdvisorDB.talentCache = result
            CoAAnalyticsAdvisorDB.talentCaches =
                CoAAnalyticsAdvisorDB.talentCaches or {}
            CoAAnalyticsAdvisorDB.talentCaches[identity] = result
        end
    elseif CoAAnalyticsAdvisorDB and
        type(CoAAnalyticsAdvisorDB.talentCaches) == "table" and
        type(CoAAnalyticsAdvisorDB.talentCaches[identity]) == "table" then
        Scanner.cache = CoAAnalyticsAdvisorDB.talentCaches[identity]
    elseif CoAAnalyticsAdvisorDB and
        type(CoAAnalyticsAdvisorDB.talentCache) == "table" and
        CoAAnalyticsAdvisorDB.talentCache.identity == identity then
        Scanner.cache = CoAAnalyticsAdvisorDB.talentCache
    end
    return Scanner.cache
end

function Scanner.LoadCache()
    local _, classToken = UnitClass("player")
    local specialization = Advisor.SafeCall(GetSpecialization)
    local identity =
        tostring(classToken or "") .. ":" .. tostring(specialization or "")
    if CoAAnalyticsAdvisorDB and
        type(CoAAnalyticsAdvisorDB.talentCaches) == "table" and
        type(CoAAnalyticsAdvisorDB.talentCaches[identity]) == "table" then
        Scanner.cache = CoAAnalyticsAdvisorDB.talentCaches[identity]
    elseif CoAAnalyticsAdvisorDB and
        type(CoAAnalyticsAdvisorDB.talentCache) == "table" and
        CoAAnalyticsAdvisorDB.talentCache.identity == identity then
        Scanner.cache = CoAAnalyticsAdvisorDB.talentCache
    end
    Scanner.cache.byName = Scanner.cache.byName or {}
    Scanner.cache.bySpellID = Scanner.cache.bySpellID or {}
    for _, talent in ipairs(Scanner.cache.all or {}) do
        Scanner.cache.byName[talent.name] = talent
        Scanner.cache.bySpellID[talent.spellID] = talent
    end
end

function Scanner.GetRank(name)
    local talent = Scanner.cache.byName and Scanner.cache.byName[name]
    return talent and talent.rank or 0
end

function Scanner.GetTalent(name, spellID)
    if spellID and Scanner.cache.bySpellID then
        local talent = Scanner.cache.bySpellID[spellID]
        if talent then return talent end
    end
    return name and Scanner.cache.byName and Scanner.cache.byName[name]
end

function Scanner.GetRecommendations(profileKey)
    if not Scanner.cache or #(Scanner.cache.all or {}) == 0 then
        Scanner.Refresh(false)
    end
    local classProfile = Advisor.Data.GetActiveClassProfile()
    if not classProfile then return {} end
    local contentMode = Advisor.GetSelectedContentMode and
        Advisor.GetSelectedContentMode() or "pvp"
    local profile = Advisor.Data.GetProfile(
        profileKey,
        classProfile,
        contentMode
    )
    local manaPressure = classProfile.role == "HEALER" and
        Advisor.CombatProfiler and
        Advisor.CombatProfiler.GetManaPressure() or 0
    local recommendations = {}
    local evaluation = {
        availableCount = 0,
        inferredCount = 0,
        situationalCount = 0,
        unavailable = 0,
    }

    for _, talent in ipairs(Scanner.cache.all or {}) do
        if talent.rank < talent.maxRank then
            if talent.available then
                evaluation.availableCount =
                    evaluation.availableCount + 1
                local result = Advisor.TalentEngine.Evaluate(
                    talent,
                    profile,
                    classProfile,
                    {
                        manaPressure = manaPressure,
                        contentMode = contentMode,
                    }
                )
                if result then
                    recommendations[#recommendations + 1] = result
                    if result.source == "tooltip-analysis" or
                        result.source == "safe-fallback" then
                        evaluation.inferredCount =
                            evaluation.inferredCount + 1
                    end
                    if result.situational then
                        evaluation.situationalCount =
                            evaluation.situationalCount + 1
                    end
                end
            else
                evaluation.unavailable = evaluation.unavailable + 1
            end
        end
    end

    local confidenceOrder = { high = 3, medium = 2, low = 1 }
    table.sort(recommendations, function(a, b)
        if a.score == b.score then
            if a.situational ~= b.situational then
                return not a.situational
            end
            local aConfidence = confidenceOrder[a.confidence] or 0
            local bConfidence = confidenceOrder[b.confidence] or 0
            if aConfidence ~= bConfidence then
                return aConfidence > bConfidence
            end
            return a.name < b.name
        end
        return a.score > b.score
    end)
    Scanner.lastEvaluation = evaluation
    return recommendations
end
