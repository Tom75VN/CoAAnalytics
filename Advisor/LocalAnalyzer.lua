local Advisor = _G.CoAAnalyticsAdvisor

Advisor.LocalAnalyzer = {}
local Analyzer = Advisor.LocalAnalyzer

local frame = CreateFrame("Frame")
local active
local sampleElapsed = 0
local CombatUpdate
local MAX_HISTORY = 50
local ANALYSIS_WINDOW = 30
local MIN_DURATION = 4

local MODE_LABELS = {
    pvp = "BG / PvP",
    pve = "Donjon / raid",
    world = "Monde / leveling",
}

local function DB()
    if type(CoAAnalyticsAdvisorDB) ~= "table" then CoAAnalyticsAdvisorDB = {} end
    if type(CoAAnalyticsAdvisorDB.localAnalysis) ~= "table" then
        CoAAnalyticsAdvisorDB.localAnalysis = {}
    end
    local db = CoAAnalyticsAdvisorDB.localAnalysis
    if db.enabled == nil then db.enabled = true end
    if type(db.profiles) ~= "table" then db.profiles = {} end
    db.schemaVersion = 1
    return db
end

local function CurrentMode()
    local _, instanceType = Advisor.SafeCall(GetInstanceInfo)
    if instanceType == "pvp" or instanceType == "arena" then
        return "pvp"
    elseif instanceType == "party" or instanceType == "raid" or
        instanceType == "scenario" then
        return "pve"
    end
    return "world"
end

local function Ratio(current, maximum)
    current = tonumber(current) or 0
    maximum = tonumber(maximum) or 0
    if maximum <= 0 then return nil end
    return Advisor.Clamp(current / maximum, 0, 1)
end

local function HealthRatio()
    return Ratio(
        Advisor.SafeCall(UnitHealth, "player"),
        Advisor.SafeCall(UnitHealthMax, "player")
    )
end

local function ManaRatio()
    local current = Advisor.SafeCall(UnitMana, "player")
    local maximum = Advisor.SafeCall(UnitManaMax, "player")
    if not maximum or maximum <= 0 then
        current = Advisor.SafeCall(UnitPower, "player", 0)
        maximum = Advisor.SafeCall(UnitPowerMax, "player", 0)
    end
    return Ratio(current, maximum)
end

local function ResourceRatio()
    local powerID = Advisor.SafeCall(UnitPowerType, "player")
    if type(powerID) ~= "number" then powerID = 0 end
    return Ratio(
        Advisor.SafeCall(UnitPower, "player", powerID),
        Advisor.SafeCall(UnitPowerMax, "player", powerID)
    ), powerID
end

local function ProfileStore(key)
    local db = DB()
    local store = db.profiles[key]
    if type(store) ~= "table" then
        store = { history = {} }
        db.profiles[key] = store
    end
    if type(store.history) ~= "table" then store.history = {} end
    return store
end

local function StartCombat()
    if not DB().enabled or active then return end
    local classProfile = Advisor.Data.GetActiveClassProfile()
    if not classProfile then return end
    active = {
        profileKey = classProfile.key,
        role = classProfile.role or "DAMAGER",
        mode = CurrentMode(),
        startedAt = GetTime(),
        died = false,
        manaSamples = 0,
        lowManaSamples = 0,
        resourceSamples = 0,
        lowResourceSamples = 0,
        healthSamples = 0,
        lowHealthSamples = 0,
    }
    sampleElapsed = 0
    frame:SetScript("OnUpdate", CombatUpdate)
end

local function SampleCombat()
    if not active then return end
    local health = HealthRatio()
    if health then
        active.healthSamples = active.healthSamples + 1
        if health <= 0.35 then
            active.lowHealthSamples = active.lowHealthSamples + 1
        end
    end
    if active.role == "HEALER" then
        local mana = ManaRatio()
        if mana then
            active.manaSamples = active.manaSamples + 1
            if mana <= 0.20 then
                active.lowManaSamples = active.lowManaSamples + 1
            end
        end
    else
        local resource = ResourceRatio()
        if resource then
            active.resourceSamples = active.resourceSamples + 1
            if resource <= 0.20 then
                active.lowResourceSamples =
                    active.lowResourceSamples + 1
            end
        end
    end
end

local function EndCombat(reason)
    frame:SetScript("OnUpdate", nil)
    if not active then return end
    SampleCombat()
    local endedAt = GetTime()
    local duration = endedAt - (active.startedAt or endedAt)
    local deadState = Advisor.SafeCall(UnitIsDeadOrGhost, "player")
    local died = active.died or deadState == true or deadState == 1
    local record = {
        endedAt = Advisor.Now(),
        duration = duration,
        mode = active.mode,
        role = active.role,
        died = died and true or false,
        endMana = active.role == "HEALER" and ManaRatio() or nil,
        endResource =
            active.role ~= "HEALER" and ResourceRatio() or nil,
        manaSamples = active.manaSamples,
        lowManaSamples = active.lowManaSamples,
        resourceSamples = active.resourceSamples,
        lowResourceSamples = active.lowResourceSamples,
        healthSamples = active.healthSamples,
        lowHealthSamples = active.lowHealthSamples,
        endReason = reason,
    }
    local key = active.profileKey
    active = nil
    sampleElapsed = 0

    if duration < MIN_DURATION and not record.died then return end
    local store = ProfileStore(key)
    store.history[#store.history + 1] = record
    while #store.history > MAX_HISTORY do
        table.remove(store.history, 1)
    end
    store.lastUpdatedAt = record.endedAt
    if Advisor.UI and Advisor.UI.RefreshIfVisible then
        Advisor.UI.RefreshIfVisible()
    end
end

local function ProfileKeyFor(classProfile, dimension)
    local order = classProfile and classProfile.profileOrder or {}
    if dimension == "throughput" then return order[2] end
    if dimension == "sustain" then return order[3] end
    if dimension == "survival" then return order[4] end
    return classProfile and classProfile.defaultProfile or "bg"
end

local function RoundPercent(value)
    return Advisor.Round((tonumber(value) or 0) * 100, 0)
end

function Analyzer.IsEnabled()
    return DB().enabled == true
end

function Analyzer.SetEnabled(enabled)
    local db = DB()
    db.enabled = enabled and true or false
    if not db.enabled then
        active = nil
        sampleElapsed = 0
        frame:SetScript("OnUpdate", nil)
    end
end

function Analyzer.Reset(profileKey)
    local db = DB()
    profileKey = profileKey or
        (Advisor.Data.GetActiveClassProfile() or {}).key
    if profileKey then db.profiles[profileKey] = nil end
end

function Analyzer.GetSummary(classProfile, contentMode)
    classProfile = classProfile or Advisor.Data.GetActiveClassProfile()
    if not classProfile then return nil end
    local store = DB().profiles[classProfile.key] or { history = {} }
    local history = store.history or {}
    local selectedMode = contentMode or
        (Advisor.GetSelectedContentMode and
            Advisor.GetSelectedContentMode()) or nil
    local records = {}
    for index = #history, 1, -1 do
        local record = history[index]
        if not classProfile.contexts or
            not selectedMode or record.mode == selectedMode then
            table.insert(records, 1, record)
            if #records >= ANALYSIS_WINDOW then break end
        end
    end
    local summary = {
        enabled = DB().enabled == true,
        profileKey = classProfile.key,
        role = classProfile.role or "DAMAGER",
        fights = 0,
        seconds = 0,
        deaths = 0,
        deathSeconds = 0,
        manaFights = 0,
        lowManaFinishes = 0,
        endingManaSum = 0,
        resourceFights = 0,
        endingResourceSum = 0,
        manaSamples = 0,
        lowManaSamples = 0,
        resourceSamples = 0,
        lowResourceSamples = 0,
        healthSamples = 0,
        lowHealthSamples = 0,
        modes = {},
        contentMode = selectedMode,
    }

    for index = 1, #records do
        local record = records[index]
        summary.fights = summary.fights + 1
        summary.seconds = summary.seconds + (record.duration or 0)
        if record.died then
            summary.deaths = summary.deaths + 1
            summary.deathSeconds =
                summary.deathSeconds + (record.duration or 0)
        end
        summary.modes[record.mode or "world"] =
            (summary.modes[record.mode or "world"] or 0) + 1
        summary.manaSamples =
            summary.manaSamples + (record.manaSamples or 0)
        summary.lowManaSamples =
            summary.lowManaSamples + (record.lowManaSamples or 0)
        summary.resourceSamples =
            summary.resourceSamples + (record.resourceSamples or 0)
        summary.lowResourceSamples =
            summary.lowResourceSamples + (record.lowResourceSamples or 0)
        summary.healthSamples =
            summary.healthSamples + (record.healthSamples or 0)
        summary.lowHealthSamples =
            summary.lowHealthSamples + (record.lowHealthSamples or 0)
        if type(record.endMana) == "number" then
            summary.manaFights = summary.manaFights + 1
            summary.endingManaSum =
                summary.endingManaSum + record.endMana
            if record.endMana <= 0.20 then
                summary.lowManaFinishes =
                summary.lowManaFinishes + 1
            end
        end
        if type(record.endResource) == "number" then
            summary.resourceFights = summary.resourceFights + 1
            summary.endingResourceSum =
                summary.endingResourceSum + record.endResource
        end
    end

    summary.deathRate = summary.fights > 0 and
        summary.deaths / summary.fights or 0
    summary.averageDeathDuration = summary.deaths > 0 and
        summary.deathSeconds / summary.deaths or nil
    summary.quickDeathPressure =
        summary.deaths >= 2 and
        (summary.averageDeathDuration or 999) <= 15
    summary.averageEndMana = summary.manaFights > 0 and
        summary.endingManaSum / summary.manaFights or nil
    summary.lowManaFinishRate = summary.manaFights > 0 and
        summary.lowManaFinishes / summary.manaFights or 0
    summary.lowManaTimeRate = summary.manaSamples > 0 and
        summary.lowManaSamples / summary.manaSamples or 0
    summary.averageEndResource = summary.resourceFights > 0 and
        summary.endingResourceSum / summary.resourceFights or nil
    summary.lowResourceTimeRate = summary.resourceSamples > 0 and
        summary.lowResourceSamples / summary.resourceSamples or 0
    summary.lowHealthTimeRate = summary.healthSamples > 0 and
        summary.lowHealthSamples / summary.healthSamples or 0
    if classProfile.role == "HEALER" and
        Advisor.CombatProfiler and
        Advisor.CombatProfiler.GetOverhealRate then
        summary.overhealRate =
            Advisor.CombatProfiler.GetOverhealRate(selectedMode)
    end

    local dominantMode = selectedMode or "world"
    local dominantCount = -1
    for mode, count in pairs(summary.modes) do
        if count > dominantCount then
            dominantMode = mode
            dominantCount = count
        end
    end
    summary.dominantMode = dominantMode
    summary.dominantModeLabel =
        MODE_LABELS[dominantMode] or dominantMode

    if summary.fights < 5 then
        summary.confidence = "insufficient"
    elseif summary.fights < 10 then
        summary.confidence = "low"
    elseif summary.fights < 20 then
        summary.confidence = "medium"
    else
        summary.confidence = "high"
    end

    local currentKey = Advisor.GetSelectedProfileKey and
        Advisor.GetSelectedProfileKey() or classProfile.defaultProfile
    local suggestedKey = currentKey
    local reason

    if summary.fights < 5 then
        reason =
            "Joue encore " .. tostring(5 - summary.fights) ..
            " combat(s) : aucune priorité ne sera modifiée avant un échantillon minimum."
    elseif summary.role == "HEALER" then
        local survivalPressure =
            summary.deathRate >= 0.25 or
            summary.quickDeathPressure or
            summary.lowHealthTimeRate >= 0.35
        local manaPressure =
            summary.manaFights >= 5 and (
                summary.lowManaFinishRate >= 0.35 or
                (summary.averageEndMana or 1) <= 0.22 or
                summary.lowManaTimeRate >= 0.30
            )
        if survivalPressure and (
            summary.deathRate >= 0.25 or
            summary.quickDeathPressure
        ) then
            suggestedKey = ProfileKeyFor(classProfile, "survival")
            if summary.quickDeathPressure then
                reason =
                    "Tes morts arrivent après " ..
                    tostring(Advisor.Round(
                        summary.averageDeathDuration or 0,
                        0
                    )) ..
                    " s en moyenne : privilégie la survie."
            else
                reason =
                    tostring(RoundPercent(summary.deathRate)) ..
                    "% des combats se terminent mort : privilégie la survie."
            end
        elseif manaPressure then
            suggestedKey = ProfileKeyFor(classProfile, "sustain")
            reason =
                tostring(RoundPercent(summary.lowManaFinishRate)) ..
                "% des combats finissent sous 20 % de mana : privilégie mana et régénération."
        elseif survivalPressure then
            suggestedKey = ProfileKeyFor(classProfile, "survival")
            reason =
                "Tu passes souvent sous 35 % de vie : privilégie la survie."
        elseif summary.overhealRate and summary.overhealRate >= 0.45 then
            suggestedKey = classProfile.defaultProfile
            reason =
                tostring(RoundPercent(summary.overhealRate)) ..
                "% des soins sont excédentaires : inutile de forcer les soins maximum."
        elseif summary.fights >= 10 and
            summary.deathRate <= 0.10 and
            summary.lowManaFinishRate <= 0.15 and
            (not summary.overhealRate or summary.overhealRate <= 0.35) then
            suggestedKey = ProfileKeyFor(classProfile, "throughput")
            reason =
                "Mana et survie sont stables : tu peux privilégier la puissance de soin."
        else
            suggestedKey = classProfile.defaultProfile
            reason =
                "Aucune faiblesse dominante : conserve un profil équilibré."
        end
    elseif summary.role == "TANK" then
        if summary.deathRate >= 0.20 or
            summary.quickDeathPressure or
            summary.lowHealthTimeRate >= 0.30 then
            suggestedKey = ProfileKeyFor(classProfile, "survival")
            reason =
                tostring(RoundPercent(summary.deathRate)) ..
                "% de morts et forte pression de vie : privilégie la mitigation."
        elseif summary.fights >= 10 and summary.deathRate <= 0.05 then
            suggestedKey = ProfileKeyFor(classProfile, "throughput")
            reason =
                "Survie stable : tu peux investir davantage dans menace et dégâts."
        else
            suggestedKey = classProfile.defaultProfile
            reason =
                "Pression modérée : conserve un profil tank équilibré."
        end
    else
        if summary.deathRate >= 0.25 or
            summary.quickDeathPressure or
            summary.lowHealthTimeRate >= 0.35 then
            suggestedKey = ProfileKeyFor(classProfile, "survival")
            if summary.quickDeathPressure then
                reason =
                    "Tes morts arrivent après " ..
                    tostring(Advisor.Round(
                        summary.averageDeathDuration or 0,
                        0
                    )) ..
                    " s en moyenne : privilégie survie et contrôle."
            else
                reason =
                    tostring(RoundPercent(summary.deathRate)) ..
                    "% des combats se terminent mort : privilégie survie et contrôle."
            end
        elseif summary.fights >= 10 and summary.deathRate <= 0.10 then
            suggestedKey = ProfileKeyFor(classProfile, "throughput")
            reason =
                "Peu de morts : tu peux privilégier les dégâts maximum."
        else
            suggestedKey = classProfile.defaultProfile
            reason =
                "Survie encore irrégulière : conserve un profil DPS équilibré."
        end
    end

    suggestedKey = Advisor.Data.NormalizeProfileKey(
        suggestedKey,
        classProfile,
        selectedMode
    )
    summary.currentKey = currentKey
    summary.suggestedKey = suggestedKey
    summary.suggestedProfile =
        Advisor.Data.GetProfile(suggestedKey, classProfile, selectedMode)
    summary.reason = reason
    summary.hasSuggestion =
        summary.fights >= 5 and suggestedKey ~= currentKey
    return summary
end

function Analyzer.Initialize()
    DB()
end

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_DEAD")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        StartCombat()
    elseif event == "PLAYER_REGEN_ENABLED" then
        EndCombat("combat-ended")
    elseif event == "PLAYER_DEAD" and active then
        active.died = true
        EndCombat("death")
    end
end)
CombatUpdate = function(self, elapsed)
    if not active then return end
    sampleElapsed = sampleElapsed + (tonumber(elapsed) or 0)
    if sampleElapsed >= 1 then
        sampleElapsed = 0
        SampleCombat()
    end
end
