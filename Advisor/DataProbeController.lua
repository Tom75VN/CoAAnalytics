local Advisor = _G.CoAAnalyticsAdvisor

Advisor.DataProbe = Advisor.DataProbe or {}
local Controller = Advisor.DataProbe

local function Settings()
    if type(CoAAnalyticsAdvisorDB) ~= "table" then CoAAnalyticsAdvisorDB = {} end
    if type(CoAAnalyticsAdvisorDB.dataProbeSettings) ~= "table" then
        CoAAnalyticsAdvisorDB.dataProbeSettings = {}
    end
    local settings = CoAAnalyticsAdvisorDB.dataProbeSettings
    if settings.enabled == nil then settings.enabled = false end
    return settings
end

local function Engine()
    return Advisor.DataProbeEngine
end

local function LoadEngine(announceError)
    local engine = Engine()
    if engine then return engine end
    local loaded, reason = Advisor.SafeCall(
        LoadAddOn,
        "CoAAnalytics_DataProbe"
    )
    engine = Engine()
    if not engine and announceError ~= false then
        Advisor.Print(
            "impossible de charger DataProbe. Vérifie que le dossier " ..
            "CoAAnalytics_DataProbe est installé et activé. " ..
            tostring(reason or loaded or "")
        )
    end
    return engine
end

function Controller.IsLoaded()
    return Engine() ~= nil
end

function Controller.IsEnabled()
    return Settings().enabled == true
end

function Controller.SetEnabled(enabled, announce)
    enabled = enabled and true or false
    local settings = Settings()
    if enabled then
        local engine = LoadEngine(true)
        if not engine then
            settings.enabled = false
            return false
        end
        settings.enabled = true
        engine.SetEnabled(true, announce)
    else
        settings.enabled = false
        local engine = Engine()
        if engine then engine.SetEnabled(false, announce) end
    end
    return true
end

function Controller.SetMode(mode)
    -- Conservé pour les appels provenant d’une ancienne interface.
    -- Depuis la 0.9.2, chaque combat est classé automatiquement.
    local engine = Engine()
    if engine and engine.SetMode then return engine.SetMode("automatic") end
    return mode == nil or type(mode) == "string"
end

function Controller.CaptureSnapshot(reason, full, announce)
    if not Settings().enabled then
        if announce ~= false then
            Advisor.Print("DataProbe est OFF : aucune donnée collectée.")
        end
        return nil
    end
    local engine = LoadEngine(true)
    return engine and engine.CaptureSnapshot(reason, full, announce)
end

function Controller.NewSession()
    local engine = LoadEngine(true)
    return engine and engine.NewSession() or false
end

function Controller.ResetArchive()
    local engine = LoadEngine(true)
    if engine then engine.ResetArchive() end
    Settings().enabled = false
end

function Controller.Export()
    local engine = LoadEngine(true)
    if engine then
        engine.Export()
    else
        Advisor.Print("DataProbe : aucune archive accessible à exporter.")
    end
end

function Controller.GetStatus()
    local settings = Settings()
    local engine = Engine()
    if engine then return engine.GetStatus() end
    return {
        enabled = settings.enabled,
        mode = "automatic",
        detectedModes = {
            bg = 0, pve = 0, leveling = 0, unknown = 0,
        },
        archiveLoaded = false,
        sessions = 0,
        snapshots = 0,
        observations = 0,
        fights = 0,
        combatEvents = 0,
        resourceSamples = 0,
    }
end

function Controller.GetCoverage()
    -- Charger l'archive pour la consulter ne démarre jamais la collecte.
    local engine = LoadEngine(false)
    if engine and engine.GetCoverage then
        return engine.GetCoverage()
    end
    return {
        profiles = {},
        weights = {
            build = 30, equipment = 30, combat = 30, variety = 10,
        },
        description = "Archive DataProbe indisponible.",
    }
end

function Controller.Initialize()
    local settings = Settings()
    if not settings.enabled then return end
    local engine = LoadEngine(true)
    if engine then engine.Initialize() end
end
