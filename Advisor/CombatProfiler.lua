local Advisor = _G.CoAAnalyticsAdvisor

Advisor.CombatProfiler = {
    active = false,
    startedAt = 0,
    manaStart = 0,
}
local Profiler = Advisor.CombatProfiler
local frame = CreateFrame("Frame")
local playerGUID
local bitBand =
    type(bit) == "table" and type(bit.band) == "function" and bit.band or
    type(bit32) == "table" and type(bit32.band) == "function" and bit32.band
local TIME_PROFILE_KEY = "CHRONOMANCER:31"

local mainHeals = {
    ["Reverse Wound"] = true,
    ["Epoch"] = true,
    ["Correct the Mistake"] = true,
}

local function NewProfile()
    return {
        fights = 0,
        seconds = 0,
        totalEffective = 0,
        totalOverheal = 0,
        mainEffective = 0,
        periodicEffective = 0,
        lowManaFights = 0,
        spells = {},
    }
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

local function EnsureProfiles()
    local database = Advisor.GetDatabase()
    local specializationKey = Profiler.specializationKey or
        ((Advisor.Data.GetActiveClassProfile() or {}).key) or "UNKNOWN"
    if specializationKey ~= TIME_PROFILE_KEY then
        if type(database.combatProfilesBySpecialization) ~= "table" then
            database.combatProfilesBySpecialization = {}
        end
        local profiles =
            database.combatProfilesBySpecialization[specializationKey]
        if type(profiles) ~= "table" then
            profiles = {}
            database.combatProfilesBySpecialization[
                specializationKey
            ] = profiles
        end
        return profiles
    end
    if type(database.combatProfiles) ~= "table" then
        database.combatProfiles = {}
        -- Les versions précédentes ne collectaient que les sessions BG du
        -- profil Time livré. On les conserve dans le compartiment PvP.
        if type(database.combatProfile) == "table" then
            database.combatProfiles.pvp = database.combatProfile
        end
    end
    return database.combatProfiles
end

local function EnsureProfile(mode)
    local profiles = EnsureProfiles()
    mode = mode or
        (Profiler.active and Profiler.mode) or
        (Advisor.GetSelectedContentMode and
            Advisor.GetSelectedContentMode()) or "pvp"
    if type(profiles[mode]) ~= "table" then
        profiles[mode] = NewProfile()
    end
    if type(profiles[mode].spells) ~= "table" then
        profiles[mode].spells = {}
    end
    return profiles[mode]
end

local function CurrentMana()
    return Advisor.SafeCall(UnitMana, "player") or
        Advisor.SafeCall(UnitPower, "player", 0) or 0
end

local function MaximumMana()
    return Advisor.SafeCall(UnitManaMax, "player") or
        Advisor.SafeCall(UnitPowerMax, "player", 0) or 0
end

local function StartCombat()
    Profiler.active = true
    Profiler.mode = CurrentMode()
    Profiler.profile = EnsureProfile(Profiler.mode)
    Profiler.startedAt = GetTime()
    Profiler.manaStart = CurrentMana()
end

local function EndCombat()
    if not Profiler.active then return end
    local profile = Profiler.profile or EnsureProfile(Profiler.mode)
    profile.fights = profile.fights + 1
    profile.seconds = profile.seconds + math.max(0, GetTime() - Profiler.startedAt)
    local manaMax = MaximumMana()
    if manaMax > 0 and CurrentMana() / manaMax < 0.25 then
        profile.lowManaFights = profile.lowManaFights + 1
    end
    Profiler.active = false
    Profiler.profile = nil
end

local function RecordHeal(eventType, spellID, spellName, amount, overhealing)
    local profile = Profiler.profile or EnsureProfile(Profiler.mode)
    amount = tonumber(amount) or 0
    overhealing = tonumber(overhealing) or 0
    local effective = math.max(0, amount - overhealing)
    profile.totalEffective = profile.totalEffective + effective
    profile.totalOverheal = profile.totalOverheal + overhealing
    if Profiler.isTime and mainHeals[spellName] then
        profile.mainEffective = profile.mainEffective + effective
    end
    if eventType == "SPELL_PERIODIC_HEAL" then
        profile.periodicEffective = profile.periodicEffective + effective
    end
    local spell = profile.spells[spellName] or {
        spellID = spellID,
        casts = 0,
        effective = 0,
        overheal = 0,
    }
    spell.casts = spell.casts + 1
    spell.effective = spell.effective + effective
    spell.overheal = spell.overheal + overhealing
    profile.spells[spellName] = spell
end

local function RecordCombatHeal(
    eventType,
    sourceGUID,
    sourceFlags,
    spellID,
    spellName,
    amount,
    overhealing
)
    local mine = sourceGUID == playerGUID
    if not mine and bitBand and type(sourceFlags) == "number" then
        mine = bitBand(
            sourceFlags,
            _G.COMBATLOG_OBJECT_AFFILIATION_MINE or 1
        ) ~= 0
    end
    if not mine or not spellName then return end
    RecordHeal(eventType, spellID, spellName, amount, overhealing)
end

local function ProcessCombatLog(...)
    local argumentCount = select("#", ...)
    if argumentCount == 0 then
        if type(CombatLogGetCurrentEventInfo) ~= "function" then return end
        local _, eventType, _, sourceGUID, _, sourceFlags, _, _, _, _, _,
            spellID, spellName, _, amount, overhealing =
            CombatLogGetCurrentEventInfo()
        if eventType ~= "SPELL_HEAL" and
            eventType ~= "SPELL_PERIODIC_HEAL" then
            return
        end
        RecordCombatHeal(
            eventType,
            sourceGUID,
            sourceFlags,
            spellID,
            spellName,
            amount,
            overhealing
        )
        return
    end

    local eventType = select(2, ...)
    if eventType ~= "SPELL_HEAL" and eventType ~= "SPELL_PERIODIC_HEAL" then
        return
    end

    if type(select(9, ...)) == "number" and
        type(select(10, ...)) == "string" then
        RecordCombatHeal(
            eventType,
            select(3, ...),
            select(5, ...),
            select(9, ...),
            select(10, ...),
            select(12, ...),
            select(13, ...)
        )
    else
        RecordCombatHeal(
            eventType,
            select(4, ...),
            select(6, ...),
            select(12, ...),
            select(13, ...),
            select(15, ...),
            select(16, ...)
        )
    end
end

function Profiler.GetMainHealShare(mode)
    local profile = EnsureProfile(mode)
    if not Profiler.isTime then return 0.70, false end
    if profile.totalEffective < 500 then return 0.70, false end
    return Advisor.Clamp(
        profile.mainEffective / profile.totalEffective,
        0,
        1
    ), true
end

function Profiler.GetManaPressure(mode)
    local profile = EnsureProfile(mode)
    if profile.fights == 0 then return 0 end
    return profile.lowManaFights / profile.fights
end

function Profiler.GetOverhealRate(mode)
    local profile = EnsureProfile(mode)
    local attempted =
        (profile.totalEffective or 0) + (profile.totalOverheal or 0)
    if attempted <= 0 then return 0, false end
    return (profile.totalOverheal or 0) / attempted, true
end

function Profiler.GetAverageFightSeconds(mode)
    local profile = EnsureProfile(mode)
    if (profile.fights or 0) <= 0 then return 0 end
    return (profile.seconds or 0) / profile.fights
end

function Profiler.GetProfile(mode)
    return EnsureProfile(mode)
end

function Profiler.Reset(mode)
    mode = mode or
        (Advisor.GetSelectedContentMode and
            Advisor.GetSelectedContentMode()) or "pvp"
    local profiles = EnsureProfiles()
    profiles[mode] = nil
    local profile = EnsureProfile(mode)
    if Profiler.active and Profiler.mode == mode then
        Profiler.profile = profile
    end
end

function Profiler.SetRuntimeEnabled(enabled)
    frame:UnregisterAllEvents()
    EndCombat()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    enabled = enabled and classProfile and classProfile.role == "HEALER"
    if enabled then
        Profiler.specializationKey = classProfile.key
        Profiler.isTime = classProfile.model == "time_healer"
        playerGUID = UnitGUID("player")
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        Profiler.specializationKey = nil
        Profiler.isTime = false
        playerGUID = nil
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        StartCombat()
    elseif event == "PLAYER_REGEN_ENABLED" then
        EndCombat()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        ProcessCombatLog(...)
    end
end)
