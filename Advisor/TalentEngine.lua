local Advisor = _G.CoAAnalyticsAdvisor

Advisor.TalentEngine = {}
local Engine = Advisor.TalentEngine

local DIMENSIONS = {
    "throughput", "sustain", "survival", "utility",
}

local DIMENSION_LABELS = {
    throughput = "rendement",
    sustain = "ressource / autonomie",
    survival = "survie",
    utility = "utilité",
}

local function CopyRule(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function NormalizeText(value)
    value = tostring(value or "")
    value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
    value = string.gsub(value, "|r", "")
    value = string.gsub(value, "|T.-|t", "")
    value = string.gsub(value, "\r", " ")
    value = string.gsub(value, "\n", " ")
    value = string.gsub(value, "%s+", " ")
    return value
end

local function IsMetadataLine(text, talentName)
    local lower = string.lower(text or "")
    if text == "" or text == talentName then return true end
    if string.find(lower, "characteradvancement id", 1, true) or
        string.find(lower, "coa talent advisor", 1, true) or
        string.find(lower, "profile value", 1, true) or
        string.find(lower, "valeur pour le profil", 1, true) then
        return true
    end
    if string.match(lower, "^id%s+%d+") or
        string.match(lower, "^%d+%s+mana$") or
        string.match(lower, "^%d+%s+focus$") or
        string.match(lower, "^%d+%s+yd range$") or
        string.match(lower, "^instant cast") or
        string.match(lower, "^passive$") or
        string.match(lower, "^rank%s+%d+") then
        return true
    end
    return false
end

function Engine.ExtractDescription(lines, talentName)
    local descriptions = {}
    for _, pair in ipairs(lines or {}) do
        local text = NormalizeText(pair.left)
        if string.find(
            string.lower(text),
            "coa talent advisor",
            1,
            true
        ) then
            break
        end
        if not IsMetadataLine(text, talentName) then
            descriptions[#descriptions + 1] = text
        end
    end
    return table.concat(descriptions, " ")
end

local function ContainsAny(text, values)
    for _, value in ipairs(values) do
        if string.find(text, value, 1, true) then return true end
    end
    return false
end

local function Raise(rule, dimension, value)
    rule[dimension] = math.max(rule[dimension] or 0, value)
end

local function AddSignal(signals, key)
    if not signals[key] then signals[key] = true end
end

local function InferredReason(signals, hasDescription)
    local labels = {}
    for _, dimension in ipairs(DIMENSIONS) do
        if signals[dimension] then
            labels[#labels + 1] = DIMENSION_LABELS[dimension]
        end
    end
    if #labels == 0 then
        return hasDescription and
            "Choix accessible classé prudemment d’après son rôle et son type." or
            "Description non capturée : classement provisoire, à confirmer avec DataProbe."
    end
    return "Bénéfices détectés : " .. table.concat(labels, ", ") .. "."
end

function Engine.InferRule(talent, classProfile)
    local role = classProfile and classProfile.role or "DAMAGER"
    local description = NormalizeText(talent.description)
    local hasDescription = description ~= ""
    local text = string.lower(
        (talent.name or "") .. " " .. description
    )
    local rule = {
        throughput = role == "TANK" and 3.5 or 4.5,
        sustain = 2.5,
        survival = role == "TANK" and 4.5 or 2.5,
        utility = 2.5,
        source = hasDescription and "tooltip-analysis" or "safe-fallback",
        confidence = hasDescription and "medium" or "low",
    }
    local signals = {}

    if ContainsAny(text, {
        "damage", "healing", "spell power", "attack power",
        "weapon damage", "critical strike", "critical strikes",
        "haste", "agility", "spirit", "bleed", "poison",
        "additional target", "additional time", "tick rate",
    }) then
        Raise(rule, "throughput", 7.0)
        AddSignal(signals, "throughput")
    end
    if ContainsAny(text, {
        "increases the damage", "increases damage", "increases the healing",
        "increased damage", "increased healing", "guaranteed to critically",
        "guarantees", "strike an additional", "ignores",
    }) then
        Raise(rule, "throughput", 8.0)
        AddSignal(signals, "throughput")
    end

    if ContainsAny(text, {
        "mana", "focus", "resource", "cost", "regenerat",
        "restores", "restore", "refund", "cooldown", "charge",
        "advantage", "endless sands",
    }) then
        Raise(rule, "sustain", 6.5)
        AddSignal(signals, "sustain")
    end
    if ContainsAny(text, {
        "reduces the mana cost", "reduces the focus cost",
        "maximum focus", "mana regeneration", "restores focus",
        "restores mana", "no cooldown or cost",
    }) then
        Raise(rule, "sustain", 8.5)
        AddSignal(signals, "sustain")
    end

    if ContainsAny(text, {
        "damage taken", "absorb", "shield", "maximum health",
        "regenerate", "armor", "dodge", "parry", "resist",
        "immun", "protection", "protect", "defensive",
        "no longer breaks on damage",
    }) then
        Raise(rule, "survival", 7.5)
        AddSignal(signals, "survival")
    end
    if ContainsAny(text, {
        "reduces damage taken", "increases maximum health",
        "damage reduction", "cannot be", "immune",
    }) then
        Raise(rule, "survival", 9.0)
        AddSignal(signals, "survival")
    end

    if ContainsAny(text, {
        "movement", "speed", "root", "snare", "stun", "silence",
        "interrupt", "dispel", "remove", "pull", "range",
        "threat", "slow", "fear", "control", "additional harmful effect",
    }) then
        Raise(rule, "utility", 7.5)
        AddSignal(signals, "utility")
    end
    if ContainsAny(text, {
        "all party and raid", "party or raid", "normally undispellable",
        "removing all beneficial", "removing all harmful",
    }) then
        Raise(rule, "utility", 9.0)
        AddSignal(signals, "utility")
    end

    if role == "HEALER" and ContainsAny(text, {
        "healing", "spirit", "mana", "ally", "allies", "aeon",
    }) then
        rule.throughput = math.min(10, rule.throughput + 0.5)
    elseif role == "DAMAGER" and ContainsAny(text, {
        "damage", "critical", "attack power", "weapon",
    }) then
        rule.throughput = math.min(10, rule.throughput + 0.5)
    elseif role == "SUPPORT" and ContainsAny(text, {
        "damage", "healing", "ally", "allies", "party", "raid",
        "buff", "aura",
    }) then
        rule.throughput = math.min(10, rule.throughput + 0.25)
        rule.utility = math.min(10, rule.utility + 0.5)
    elseif role == "TANK" and signals.survival then
        rule.survival = math.min(10, rule.survival + 0.5)
    end

    if talent.talentType == "ability" then
        rule.utility = math.min(10, rule.utility + 0.5)
    end

    rule.reason = InferredReason(signals, hasDescription)
    return rule
end

function Engine.ResolveRule(talent, classProfile)
    local rules = Advisor.Data.GetTalentRules(classProfile)
    local source = rules[talent.name] or
        (talent.spellID and rules[talent.spellID])
    if source then
        local rule = CopyRule(source)
        rule.source = rule.source or "verified-profile"
        rule.confidence = rule.confidence or "high"
        if rule.excludeFromRecommendations then
            rule.situational = true
        end
        return rule
    end
    return Engine.InferRule(talent, classProfile)
end

local function DominantDimension(components)
    local bestDimension = "throughput"
    local bestValue = -1
    for _, dimension in ipairs(DIMENSIONS) do
        local value = components[dimension] or 0
        if value > bestValue then
            bestDimension = dimension
            bestValue = value
        end
    end
    return bestDimension, bestValue
end

function Engine.Evaluate(talent, profile, classProfile, context)
    context = context or {}
    local rule = Engine.ResolveRule(talent, classProfile)
    local contentContext =
        Advisor.Data.GetContext(classProfile, context.contentMode)
    local weights = profile and profile.talent or {
        throughput = 0.45,
        sustain = 0.20,
        survival = 0.25,
        utility = 0.10,
    }
    local components = {}
    local score = 0
    for _, dimension in ipairs(DIMENSIONS) do
        components[dimension] =
            (rule[dimension] or 0) * (weights[dimension] or 0)
        score = score + components[dimension]
    end

    if context.manaPressure and context.manaPressure > 0 then
        local adjustment =
            (rule.sustain or 0) * context.manaPressure * 0.10
        components.sustain = components.sustain + adjustment
        score = score + adjustment
    end
    if (talent.rank or 0) > 0 then score = score + 0.25 end
    if rule.situational then score = score - 0.60 end
    if rule.confidence == "medium" then
        score = score - 0.10
    elseif rule.confidence == "low" then
        -- Un talent sans description reste proposé s'il est achetable, mais
        -- ne doit pas dépasser un choix dont l'effet a réellement été lu.
        score = score - 0.50
    end

    local guideNote
    local priorityBonus = contentContext and
        contentContext.talentPriority and
        (
            contentContext.talentPriority[talent.name] or
            (talent.spellID and
                contentContext.talentPriority[talent.spellID])
        )
    if priorityBonus then
        score = score + priorityBonus
        if contentContext.talentBaseline and
            contentContext.talentBaseline[talent.name] then
            guideNote =
                "Présent dans le build de base vérifié ; la priorité choisie " ..
                "départage ensuite son rendement, sa survie et son utilité."
        else
            guideNote = "Talent pivot du build guide pour ce contexte."
        end
    elseif contentContext and
        contentContext.talentDeprioritized and
        (
            contentContext.talentDeprioritized[talent.name] or
            (talent.spellID and
                contentContext.talentDeprioritized[talent.spellID])
        ) then
        -- Le guide ne fournit pas de valeur chiffrée. Une pénalité modérée
        -- évite donc d'exclure définitivement un talent accessible.
        score = score - 1.50
        rule.situational = true
        guideNote =
            "Moins prioritaire dans le build guide pour ce contexte."
    end

    local dominant = DominantDimension(components)
    local result = {
        name = talent.name,
        rank = talent.rank,
        nextRank = (talent.rank or 0) + 1,
        maxRank = talent.maxRank,
        score = Advisor.Clamp(score, 0, 10),
        reason = guideNote and
            (tostring(rule.reason or "") .. " " .. guideNote) or
            rule.reason,
        tree = talent.tree,
        spellID = talent.spellID,
        icon = talent.icon,
        globalName = talent.globalName,
        talentType = talent.talentType,
        description = talent.description,
        components = components,
        dominantDimension = dominant,
        dominantLabel = DIMENSION_LABELS[dominant],
        source = rule.source,
        confidence = rule.confidence,
        situational = rule.situational == true,
        profileLabel = profile and
            (profile.shortLabel or profile.label) or "profil actif",
    }
    result.profileReason =
        "Pour « " .. result.profileLabel .. " », son bénéfice principal est : " ..
        result.dominantLabel .. "."
    return result
end

function Engine.GetDimensionLabel(dimension)
    return DIMENSION_LABELS[dimension] or tostring(dimension or "")
end
