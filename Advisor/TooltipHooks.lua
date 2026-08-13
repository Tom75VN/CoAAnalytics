local Advisor = _G.CoAAnalyticsAdvisor

Advisor.TooltipHooks = {
    processingItem = false,
    processingSpell = false,
}
local Hooks = Advisor.TooltipHooks

local function Localized(value)
    return Advisor.LocalizeText and Advisor.LocalizeText(value) or value
end

local function OnTooltipSetItem(tooltip)
    if Hooks.processingItem or not CoAAnalyticsAdvisorDB.enabled or
        not Advisor.IsItemSupportedCharacter() then return end
    Hooks.processingItem = true

    local _, itemLink = Advisor.SafeCall(tooltip.GetItem, tooltip)
    if itemLink then
        local parsed = Advisor.TooltipParser.FromTooltip(tooltip, itemLink)
        Advisor.CharacterScanner.UpdateEquipmentItem(itemLink, parsed)
        local result = Advisor.ItemAdvisor.Evaluate(itemLink, parsed)
        Advisor.ItemAdvisor.AddToTooltip(tooltip, result)
    end

    Hooks.processingItem = false
end

local function CaptureComparisonTooltip(tooltip)
    if not Advisor.IsItemSupportedCharacter() then return end
    local _, itemLink = Advisor.SafeCall(tooltip.GetItem, tooltip)
    if not itemLink then return end
    local parsed = Advisor.TooltipParser.FromTooltip(tooltip, itemLink)
    Advisor.CharacterScanner.UpdateEquipmentItem(itemLink, parsed)
end

local function TalentRuleForTooltip(tooltip)
    local spellName, _, spellID = Advisor.SafeCall(tooltip.GetSpell, tooltip)
    if not spellName and spellID then
        local override = Advisor.Data.spellNameOverrides[spellID]
        spellName = override
    end
    local talent = Advisor.TalentScanner.GetTalent(spellName, spellID)
    if not talent then return spellName, nil end

    local description = Advisor.TalentEngine.ExtractDescription(
        Advisor.GetTooltipLines(tooltip),
        spellName
    )
    if description and description ~= "" then
        talent.description = description
    end

    local classProfile = Advisor.Data.GetActiveClassProfile()
    local contentMode = Advisor.GetSelectedContentMode and
        Advisor.GetSelectedContentMode() or "pvp"
    local profile = Advisor.Data.GetProfile(
        Advisor.GetSelectedProfileKey(),
        classProfile,
        contentMode
    )
    local manaPressure = classProfile.role == "HEALER" and
        Advisor.CombatProfiler.GetManaPressure() or 0
    return spellName, Advisor.TalentEngine.Evaluate(
        talent,
        profile,
        classProfile,
        {
            manaPressure = manaPressure,
            contentMode = contentMode,
        }
    )
end

local function OnTooltipSetSpell(tooltip)
    if Hooks.processingSpell or not CoAAnalyticsAdvisorDB.enabled or
        not Advisor.IsSupportedCharacter() then return end
    local spellName, result = TalentRuleForTooltip(tooltip)
    if not result then return end

    Hooks.processingSpell = true
    tooltip:AddLine(" ")
    tooltip:AddLine("CoA Talent Advisor", 0.4, 0.8, 1)
    tooltip:AddDoubleLine(
        Localized(result.profileLabel),
        tostring(Advisor.Round(result.score, 1)) .. "/10",
        0.8, 0.8, 0.8,
        result.score >= 7.0 and 0.3 or 1,
        result.score >= 7.0 and 1 or 0.82,
        0.3
    )
    if result.situational then
        tooltip:AddLine(
            Localized("Choix situationnel : classé, mais pénalisé par défaut"),
            1, 0.55, 0.15, true
        )
    end
    tooltip:AddLine(Localized(result.reason), 0.75, 0.75, 0.75, true)
    tooltip:AddLine(Localized(result.profileReason), 0.35, 0.85, 1, true)
    tooltip:Show()
    Hooks.processingSpell = false
end

function Hooks.Install()
    if not GameTooltip or GameTooltip.CoAAnalyticsAdvisorHooked then return end
    local itemOK = pcall(
        GameTooltip.HookScript,
        GameTooltip,
        "OnTooltipSetItem",
        OnTooltipSetItem
    )
    local spellOK = pcall(
        GameTooltip.HookScript,
        GameTooltip,
        "OnTooltipSetSpell",
        OnTooltipSetSpell
    )
    GameTooltip.CoAAnalyticsAdvisorHooked = itemOK or spellOK

    for _, tooltipName in ipairs({ "ShoppingTooltip1", "ShoppingTooltip2" }) do
        local comparisonTooltip = _G[tooltipName]
        if comparisonTooltip and
            type(comparisonTooltip.HookScript) == "function" and
            not comparisonTooltip.CoAAnalyticsAdvisorHooked then
            local ok = pcall(
                comparisonTooltip.HookScript,
                comparisonTooltip,
                "OnTooltipSetItem",
                CaptureComparisonTooltip
            )
            comparisonTooltip.CoAAnalyticsAdvisorHooked = ok
        end
    end
end
