local Addon = _G.CoAAnalyticsAddon or {}
_G.CoAAnalyticsAddon = Addon
Addon.Modules = Addon.Modules or {}

local Advisor = Addon.Advisor or {}
Addon.Advisor = Advisor
Addon.Modules.Advisor = Advisor
_G.CoAAnalyticsAdvisor = Advisor

-- Advisor conserve son propre schema interne, mais ses donnees font maintenant
-- partie de l'unique SavedVariable de CoA Analytics.
if type(_G.CoAAnalyticsDB) ~= "table" then
    _G.CoAAnalyticsDB = {}
end
if type(_G.CoAAnalyticsDB.advisor) ~= "table" then
    _G.CoAAnalyticsDB.advisor = {}
end
_G.CoAAnalyticsAdvisorDB = _G.CoAAnalyticsDB.advisor

Advisor.name = "CoAAnalytics"
Advisor.version = Addon.VERSION or "2.17.3"
Advisor.interface = 30300

function Advisor.GetDatabase()
    if type(_G.CoAAnalyticsDB) ~= "table" then
        _G.CoAAnalyticsDB = {}
    end
    if type(_G.CoAAnalyticsDB.advisor) ~= "table" then
        _G.CoAAnalyticsDB.advisor = {}
    end
    _G.CoAAnalyticsAdvisorDB = _G.CoAAnalyticsDB.advisor
    return _G.CoAAnalyticsAdvisorDB
end

function Advisor.SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil, "unavailable" end
    local ok, a, b, c, d, e, f, g, h, i, j = pcall(fn, ...)
    if not ok then return nil, tostring(a) end
    return a, b, c, d, e, f, g, h, i, j
end

function Advisor.Print(message)
    if DEFAULT_CHAT_FRAME then
        if type(Advisor.LocalizeText) == "function" then
            message = Advisor.LocalizeText(message)
        end
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff66ccffCoA Analytics:|r " .. tostring(message)
        )
    end
end

local function ChatFrameHasMessageGroup(chatFrame, windowIndex, wantedGroup)
    wantedGroup = string.upper(tostring(wantedGroup or ""))
    if type(GetChatWindowMessages) == "function" then
        local groups = { GetChatWindowMessages(windowIndex) }
        for groupIndex = 1, #groups do
            if string.upper(tostring(groups[groupIndex] or "")) ==
                wantedGroup then
                return true
            end
        end
    end
    for _, group in pairs(chatFrame.messageTypeList or {}) do
        if string.upper(tostring(group or "")) == wantedGroup then
            return true
        end
    end
    return false
end

function Advisor.PrintLoot(message)
    if type(Advisor.LocalizeText) == "function" then
        message = Advisor.LocalizeText(message)
    end
    local formatted =
        "|cff66ccffCoA Analytics:|r " .. tostring(message or "")
    local lootColor = ChatTypeInfo and ChatTypeInfo["LOOT"] or {}
    local red = tonumber(lootColor.r) or 0.1
    local green = tonumber(lootColor.g) or 1
    local blue = tonumber(lootColor.b) or 0.1
    local colorID = lootColor.id
    local delivered = false
    local windowCount = tonumber(NUM_CHAT_WINDOWS) or 10

    for index = 1, windowCount do
        local chatFrame = _G["ChatFrame" .. tostring(index)]
        if chatFrame and type(chatFrame.AddMessage) == "function" and
            ChatFrameHasMessageGroup(chatFrame, index, "LOOT") then
            chatFrame:AddMessage(
                formatted, red, green, blue, colorID
            )
            delivered = true
        end
    end

    if not delivered and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            formatted, red, green, blue, colorID
        )
    end
end

function Advisor.Round(value, digits)
    local scale = 10 ^ (digits or 0)
    if value >= 0 then
        return math.floor(value * scale + 0.5) / scale
    end
    return math.ceil(value * scale - 0.5) / scale
end

function Advisor.Clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function Advisor.CopyStats(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = tonumber(value) or 0
    end
    return result
end

function Advisor.AddStats(target, source, multiplier)
    multiplier = multiplier or 1
    for key, value in pairs(source or {}) do
        if type(value) == "number" then
            target[key] = (target[key] or 0) + value * multiplier
        end
    end
    return target
end

function Advisor.SubtractStats(left, right)
    local result = Advisor.CopyStats(left)
    Advisor.AddStats(result, right, -1)
    return result
end

function Advisor.TableCount(value)
    local count = 0
    for _ in pairs(value or {}) do count = count + 1 end
    return count
end

function Advisor.FormatSigned(value, digits, suffix)
    value = Advisor.Round(value or 0, digits or 1)
    local prefix = value > 0 and "+" or ""
    return prefix .. tostring(value) .. (suffix or "")
end

function Advisor.GetFrameText(region)
    if region and type(region.GetText) == "function" then
        return Advisor.SafeCall(region.GetText, region)
    end
    return nil
end

function Advisor.GetTooltipLines(tooltip)
    local result = {}
    if not tooltip or type(tooltip.NumLines) ~= "function" then return result end
    local tooltipName = tooltip:GetName()
    local count = tooltip:NumLines() or 0
    for index = 1, count do
        local leftRegion = tooltipName and
            _G[tooltipName .. "TextLeft" .. index]
        local rightRegion = tooltipName and
            _G[tooltipName .. "TextRight" .. index]
        local left = Advisor.GetFrameText(leftRegion)
        local right = Advisor.GetFrameText(rightRegion)
        local leftR, leftG, leftB, leftA
        if leftRegion and type(leftRegion.GetTextColor) == "function" then
            leftR, leftG, leftB, leftA =
                Advisor.SafeCall(leftRegion.GetTextColor, leftRegion)
        end
        result[#result + 1] = {
            left = left,
            right = right,
            leftR = tonumber(leftR),
            leftG = tonumber(leftG),
            leftB = tonumber(leftB),
            leftA = tonumber(leftA),
        }
    end
    return result
end

function Advisor.GetUnitStat(index)
    local _, effective = Advisor.SafeCall(UnitStat, "player", index)
    return tonumber(effective) or 0
end

function Advisor.Now()
    local value = Advisor.SafeCall(time)
    return tonumber(value) or 0
end

function Advisor.IsSupportedCharacter()
    return Advisor.Data and Advisor.Data.GetActiveClassProfile and
        Advisor.Data.GetActiveClassProfile() ~= nil
end

function Advisor.IsItemSupportedCharacter()
    local profile = Advisor.Data and Advisor.Data.GetActiveClassProfile and
        Advisor.Data.GetActiveClassProfile()
    if not profile or profile.itemModelAvailable == false then return false end
    return profile.model == "time_healer" or
        profile.model == "ranger_archery" or
        profile.model == "guide_priority"
end

function Advisor.IsTimeCharacter()
    local profile = Advisor.Data and Advisor.Data.GetActiveClassProfile and
        Advisor.Data.GetActiveClassProfile()
    return profile and profile.model == "time_healer" or false
end

function Advisor.IsHealerCharacter()
    local profile = Advisor.Data and Advisor.Data.GetActiveClassProfile and
        Advisor.Data.GetActiveClassProfile()
    return profile and profile.role == "HEALER" or false
end
