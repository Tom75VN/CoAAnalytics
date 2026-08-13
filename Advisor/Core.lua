local Advisor = _G.CoAAnalyticsAdvisor

local frame = CreateFrame("Frame")
local refreshAt
local refreshReason
Advisor.Actions = Advisor.Actions or {}

local function EnsureDB()
    if type(CoAAnalyticsAdvisorDB) ~= "table" then CoAAnalyticsAdvisorDB = {} end
    if CoAAnalyticsAdvisorDB.language ~= "en" and
        CoAAnalyticsAdvisorDB.language ~= "fr" then
        CoAAnalyticsAdvisorDB.language = "fr"
    end
    if CoAAnalyticsAdvisorDB.enabled == nil then CoAAnalyticsAdvisorDB.enabled = true end
    if CoAAnalyticsAdvisorDB.autoGreedIncompatibleLoot == nil then
        CoAAnalyticsAdvisorDB.autoGreedIncompatibleLoot =
            CoAAnalyticsAdvisorDB.autoPassIncompatibleLoot == true
    end
    if type(CoAAnalyticsAdvisorDB.autoGreedExcludedStatsByCharacter) ~= "table" then
        CoAAnalyticsAdvisorDB.autoGreedExcludedStatsByCharacter = {}
    end
    if type(CoAAnalyticsAdvisorDB.profilesBySpecialization) ~= "table" then
        CoAAnalyticsAdvisorDB.profilesBySpecialization = {}
    end
    if type(CoAAnalyticsAdvisorDB.contentModesBySpecialization) ~= "table" then
        CoAAnalyticsAdvisorDB.contentModesBySpecialization = {}
    end
    if type(CoAAnalyticsAdvisorDB.profilesBySpecializationContext) ~= "table" then
        CoAAnalyticsAdvisorDB.profilesBySpecializationContext = {}
    end

    local classProfile = Advisor.Data.GetActiveClassProfile()
    if classProfile then
        local contentMode = Advisor.Data.NormalizeContentMode(
            CoAAnalyticsAdvisorDB.contentModesBySpecialization[classProfile.key],
            classProfile
        )
        CoAAnalyticsAdvisorDB.contentModesBySpecialization[classProfile.key] =
            contentMode
        CoAAnalyticsAdvisorDB.contentMode = contentMode

        local contextKey = classProfile.key .. ":" .. contentMode
        local stored =
            CoAAnalyticsAdvisorDB.profilesBySpecializationContext[contextKey]
        if not stored and contentMode ==
            (classProfile.defaultContentMode or "pvp") then
            stored =
                CoAAnalyticsAdvisorDB.profilesBySpecialization[classProfile.key]
            if not stored and
                Advisor.Data.NormalizeProfileKey(
                    CoAAnalyticsAdvisorDB.profile,
                    classProfile,
                    contentMode
                ) == CoAAnalyticsAdvisorDB.profile then
                stored = CoAAnalyticsAdvisorDB.profile
            end
        end
        stored = Advisor.Data.NormalizeProfileKey(
            stored,
            classProfile,
            contentMode
        )
        CoAAnalyticsAdvisorDB.profilesBySpecialization[classProfile.key] = stored
        CoAAnalyticsAdvisorDB.profilesBySpecializationContext[contextKey] = stored
        CoAAnalyticsAdvisorDB.profile = stored
    else
        CoAAnalyticsAdvisorDB.profile = "bg"
        CoAAnalyticsAdvisorDB.contentMode = "pvp"
    end
    CoAAnalyticsAdvisorDB.version = Advisor.version
end

function Advisor.GetSelectedContentMode()
    EnsureDB()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    return Advisor.Data.NormalizeContentMode(
        CoAAnalyticsAdvisorDB.contentMode,
        classProfile
    )
end

function Advisor.GetSelectedProfileKey()
    EnsureDB()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local contentMode = Advisor.Data.NormalizeContentMode(
        CoAAnalyticsAdvisorDB.contentMode,
        classProfile
    )
    return Advisor.Data.NormalizeProfileKey(
        CoAAnalyticsAdvisorDB.profile,
        classProfile,
        contentMode
    )
end

local function IsSupportedCharacter()
    return Advisor.IsSupportedCharacter()
end

local function Refresh(reason, announce)
    EnsureDB()
    if not IsSupportedCharacter() then
        if Advisor.UI then Advisor.UI.Refresh() end
        return
    end
    local captureDescriptions =
        reason == "manual" or
        reason == "CHARACTER_POINTS_CHANGED" or
        reason == "PLAYER_TALENT_UPDATE"
    Advisor.TalentScanner.Refresh(captureDescriptions)
    local character = Advisor.CharacterScanner.Scan(reason)
    if announce then
        local selected = #(Advisor.TalentScanner.cache.selected or {})
        local classProfile = Advisor.Data.GetActiveClassProfile()
        Advisor.Print(
            "analyse terminée pour " .. classProfile.title .. " : " ..
            selected .. " talents sélectionnés, " ..
            tostring(Advisor.TableCount(character.equipment)) ..
            " objets équipés."
        )
    end
    if Advisor.UI then Advisor.UI.Refresh() end
end

local function ScheduledRefreshUpdate(self)
    if not refreshAt or GetTime() < refreshAt then return end
    local reason = refreshReason
    refreshAt = nil
    refreshReason = nil
    self:SetScript("OnUpdate", nil)
    Refresh(reason, false)
end

local function ScheduleRefresh(delay, reason)
    refreshAt = GetTime() + (tonumber(delay) or 0)
    refreshReason = reason
    frame:SetScript("OnUpdate", ScheduledRefreshUpdate)
end

local function CancelScheduledRefresh()
    refreshAt = nil
    refreshReason = nil
    frame:SetScript("OnUpdate", nil)
end

local function ShowStatus()
    if not IsSupportedCharacter() then
        Advisor.Print("Aucun profil de recommandation pour cette spécialisation.")
        return
    end
    local character = Advisor.CharacterScanner.Get()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local profile = Advisor.Data.GetProfile(
        Advisor.GetSelectedProfileKey(),
        classProfile,
        Advisor.GetSelectedContentMode()
    )
    Advisor.Print(
        classProfile.title .. " | " .. profile.label ..
        " | niveau " .. tostring(character.level)
    )
    if classProfile.model == "ranger_archery" then
        Advisor.Print(
            "Agilité " .. tostring(character.agility) ..
            " | PA distance " .. tostring(character.rangedAttackPower) ..
            " | Crit distance " ..
            tostring(Advisor.Round(character.rangedCritChance, 2)) .. "%" ..
            " | Hâte " ..
            tostring(Advisor.Round(character.rangedHasteBonus, 2)) .. "%"
        )
    elseif classProfile.model == "time_healer" then
        Advisor.Print(
            "Esprit " .. tostring(character.spirit) ..
            " | Soins " .. tostring(character.healing) ..
            " | Puissance des sorts " .. tostring(character.spellPower) ..
            " | Critique " ..
            tostring(Advisor.Round(character.critChance, 2)) .. "%"
        )
    else
        Advisor.Print(
            tostring(#(Advisor.TalentScanner.cache.selected or {})) ..
            " talents sélectionnés | " ..
            tostring(#(Advisor.TalentScanner.cache.all or {})) ..
            " talents détectés."
        )
    end
end

local function ShowTalents()
    local recommendations = Advisor.TalentScanner.GetRecommendations(
        Advisor.GetSelectedProfileKey()
    )
    if #Advisor.TalentScanner.cache.all == 0 then
        Advisor.Print(
            "Ouvre les arbres de talents de classe et de spécialisation, " ..
            "laisse-les visibles, puis relance l'analyse."
        )
        return
    end
    if #recommendations == 0 then
        Advisor.Print(
            "Aucun talent accessible et évalué n'a été trouvé au niveau actuel."
        )
        return
    end
    Advisor.Print("Prochains talents conseillés :")
    for index = 1, math.min(3, #recommendations) do
        local result = recommendations[index]
        Advisor.Print(
            index .. ". " .. result.name .. " " ..
            result.nextRank .. "/" .. result.maxRank ..
            " - " .. result.reason
        )
    end
end

local function ShowCombat()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    if not classProfile then return end
    local localSummary = Advisor.LocalAnalyzer.GetSummary(classProfile)
    if not localSummary then return end
    Advisor.Print(
        "analyse locale : " .. tostring(localSummary.fights) ..
        " combats, " .. tostring(localSummary.deaths) ..
        " morts, contenu dominant " ..
        tostring(localSummary.dominantModeLabel) .. "."
    )
    Advisor.Print(localSummary.reason)
    if classProfile.role ~= "HEALER" then
        return
    end
    local profile = Advisor.CombatProfiler.GetProfile()
    local mainShare = Advisor.CombatProfiler.GetMainHealShare()
    local manaPressure = Advisor.CombatProfiler.GetManaPressure()
    local overhealRate = Advisor.CombatProfiler.GetOverhealRate()
    Advisor.Print(
        "profil combat : " .. profile.fights .. " combats, " ..
        tostring(Advisor.Round(profile.seconds, 0)) .. " secondes."
    )
    if classProfile.model == "time_healer" then
        Advisor.Print(
            "part des soins principaux " ..
            tostring(Advisor.Round(mainShare * 100, 1)) ..
            "% | combats avec peu de mana " ..
            tostring(Advisor.Round(manaPressure * 100, 1)) ..
            "% | overheal " ..
            tostring(Advisor.Round(overhealRate * 100, 1)) .. "%."
        )
    else
        Advisor.Print(
            "soins effectifs " ..
            tostring(Advisor.Round(profile.totalEffective or 0, 0)) ..
            " | soins périodiques " ..
            tostring(Advisor.Round(profile.periodicEffective or 0, 0)) ..
            " | combats avec peu de mana " ..
            tostring(Advisor.Round(manaPressure * 100, 1)) ..
            "% | overheal " ..
            tostring(Advisor.Round(overhealRate * 100, 1)) .. "%."
        )
    end
end

local function SetProfile(profileKey, announce)
    profileKey = string.lower(profileKey or "")
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local contentMode = Advisor.GetSelectedContentMode()
    local normalized = Advisor.Data.NormalizeProfileKey(
        profileKey,
        classProfile,
        contentMode
    )
    if not classProfile or normalized ~= profileKey then
        if announce ~= false and classProfile then
            Advisor.Print(
                "Profils : " .. table.concat(classProfile.profileOrder, ", ")
            )
        end
        return false
    end
    EnsureDB()
    CoAAnalyticsAdvisorDB.profile = profileKey
    CoAAnalyticsAdvisorDB.profilesBySpecialization[classProfile.key] = profileKey
    CoAAnalyticsAdvisorDB.profilesBySpecializationContext[
        classProfile.key .. ":" .. contentMode
    ] = profileKey
    if announce ~= false then
        Advisor.Print(
            "profil sélectionné : " ..
            Advisor.Data.GetProfile(
                profileKey,
                classProfile,
                contentMode
            ).label
        )
    end
    if Advisor.UI then Advisor.UI.Refresh() end
    return true
end

local function SetContentMode(contentMode, announce)
    local classProfile = Advisor.Data.GetActiveClassProfile()
    if not classProfile then return false end
    contentMode = Advisor.Data.NormalizeContentMode(contentMode, classProfile)
    EnsureDB()
    CoAAnalyticsAdvisorDB.contentModesBySpecialization[classProfile.key] =
        contentMode
    CoAAnalyticsAdvisorDB.contentMode = contentMode

    local contextKey = classProfile.key .. ":" .. contentMode
    local stored =
        CoAAnalyticsAdvisorDB.profilesBySpecializationContext[contextKey]
    stored = Advisor.Data.NormalizeProfileKey(
        stored,
        classProfile,
        contentMode
    )
    CoAAnalyticsAdvisorDB.profilesBySpecializationContext[contextKey] = stored
    CoAAnalyticsAdvisorDB.profilesBySpecialization[classProfile.key] = stored
    CoAAnalyticsAdvisorDB.profile = stored

    if announce ~= false then
        local context = Advisor.Data.GetContext(classProfile, contentMode)
        Advisor.Print(
            "contexte sélectionné : " ..
            tostring(context and context.label or contentMode)
        )
    end
    if Advisor.UI then Advisor.UI.Refresh() end
    return true
end

local function Help()
    Advisor.Print("/coaa advisor - ouvrir l'interface guidée.")
    Advisor.Print("/coaa advisor scan - actualiser personnage, équipement et talents.")
    Advisor.Print("/coaa advisor status - afficher les données du modèle actif.")
    Advisor.Print("/coaa advisor talents - afficher les trois prochains talents.")
    Advisor.Print("/coaa advisor combat - afficher la calibration de combat.")
    Advisor.Print("/coaa advisor profile NOM - changer la priorité.")
    Advisor.Print("/coaa advisor content pvp|pve - changer le type de contenu.")
    Advisor.Print("/coaa advisor on|off - activer ou désactiver les tooltips.")
    Advisor.Print("/coaa advisor probe - ouvrir l'onglet DataProbe.")
    Advisor.Print("/coaa advisor language fr|en - changer la langue de l'interface.")
end

Advisor.Actions.Scan = function(announce)
    Refresh("manual", announce ~= false)
end

Advisor.Actions.SetProfile = function(profileKey, announce)
    return SetProfile(profileKey, announce)
end

Advisor.Actions.SetContentMode = function(contentMode, announce)
    return SetContentMode(contentMode, announce)
end

Advisor.Actions.SetEnabled = function(enabled, announce)
    EnsureDB()
    CoAAnalyticsAdvisorDB.enabled = enabled and true or false
    if announce ~= false then
        Advisor.Print(
            CoAAnalyticsAdvisorDB.enabled and
            "conseils d'objets activés." or
            "conseils d'objets désactivés."
        )
    end
    if Advisor.UI then Advisor.UI.Refresh() end
end

Advisor.Actions.SetAutoGreedIncompatibleLoot = function(enabled, announce)
    if Advisor.LootAdvisor then
        Advisor.LootAdvisor.SetAutoGreedEnabled(enabled, announce)
    end
end

Advisor.Actions.ResetCombat = function(announce)
    Advisor.CombatProfiler.Reset()
    if announce ~= false then
        Advisor.Print("observations de combat effacées.")
    end
    if Advisor.UI then Advisor.UI.Refresh() end
end

Advisor.Actions.SetLocalAnalysis = function(enabled, announce)
    Advisor.LocalAnalyzer.SetEnabled(enabled)
    if announce ~= false then
        Advisor.Print(
            enabled and
            "analyse locale automatique activée." or
            "analyse locale automatique désactivée."
        )
    end
    if Advisor.UI then Advisor.UI.Refresh() end
end

Advisor.Actions.ApplyLocalSuggestion = function(announce)
    local summary = Advisor.LocalAnalyzer.GetSummary()
    if not summary or not summary.hasSuggestion then
        if announce ~= false then
            Advisor.Print("aucun changement de priorité conseillé actuellement.")
        end
        return false
    end
    return SetProfile(summary.suggestedKey, announce)
end

Advisor.Actions.ResetLocalAnalysis = function(announce)
    Advisor.LocalAnalyzer.Reset()
    if announce ~= false then
        Advisor.Print("historique local de cette spécialisation effacé.")
    end
    if Advisor.UI then Advisor.UI.Refresh() end
end

Advisor.Actions.ShowDataProbe = function()
    if Advisor.UI then Advisor.UI.ShowDataProbe() end
end

Advisor.Actions.SetLanguage = function(language)
    language = string.lower(language or "")
    if language ~= "fr" and language ~= "en" then
        Advisor.Print("Langues disponibles : fr, en.")
        return false
    end
    return Advisor.SetLanguage(language, true)
end

function Advisor.HandleCommand(input)
    EnsureDB()
    local command, argument =
        string.match(input or "", "^%s*(%S*)%s*(.-)%s*$")
    command = string.lower(command or "")
    if command == "" or command == "ui" or command == "show" then
        if Advisor.UI then Advisor.UI.Toggle() end
    elseif command == "scan" then
        Advisor.Actions.Scan(true)
    elseif command == "status" then
        ShowStatus()
    elseif command == "talents" then
        ShowTalents()
    elseif command == "combat" then
        ShowCombat()
    elseif command == "profile" then
        Advisor.Actions.SetProfile(argument, true)
    elseif command == "content" or command == "contenu" then
        Advisor.Actions.SetContentMode(argument, true)
    elseif command == "on" then
        Advisor.Actions.SetEnabled(true, true)
    elseif command == "off" then
        Advisor.Actions.SetEnabled(false, true)
    elseif command == "resetcombat" then
        Advisor.Actions.ResetCombat(true)
    elseif command == "probe" or command == "dataprobe" then
        Advisor.Actions.ShowDataProbe()
    elseif command == "language" or command == "lang" or
        command == "langue" then
        Advisor.Actions.SetLanguage(argument)
    else
        Help()
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
for _, event in ipairs({
    "PLAYER_EQUIPMENT_CHANGED",
    "UNIT_INVENTORY_CHANGED",
    "CHARACTER_POINTS_CHANGED",
    "PLAYER_TALENT_UPDATE",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "PLAYER_LEVEL_UP",
    "PLAYER_SPECIALIZATION_CHANGED",
}) do
    pcall(frame.RegisterEvent, frame, event)
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == Advisor.name then
        EnsureDB()
        Advisor.TalentScanner.LoadCache()
    elseif event == "PLAYER_LOGIN" then
        Advisor.Data.InvalidateActiveClassProfile()
        EnsureDB()
        Advisor.LocalAnalyzer.Initialize()
        Advisor.CombatProfiler.SetRuntimeEnabled(Advisor.IsHealerCharacter())
        Advisor.TooltipHooks.Install()
        if Advisor.LootAdvisor then Advisor.LootAdvisor.Initialize() end
        if Advisor.DataProbe then Advisor.DataProbe.Initialize() end
        if Advisor.UI then Advisor.UI.Initialize() end
        if Advisor.ProcTracker then Advisor.ProcTracker.Initialize() end
        if not IsSupportedCharacter() then
            Advisor.Print(
                "aucun profil pour cette spécialisation. DataProbe reste " ..
                "disponible pour aider à en construire un."
            )
        else
            ScheduleRefresh(3, "login")
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or
        event == "ACTIVE_TALENT_GROUP_CHANGED" then
        CancelScheduledRefresh()
        Advisor.Data.InvalidateActiveClassProfile()
        EnsureDB()
        Advisor.TalentScanner.cache =
            {
                all = {}, selected = {}, byName = {}, bySpellID = {},
                capturedAt = 0,
            }
        Advisor.TalentScanner.LoadCache()
        Advisor.CombatProfiler.SetRuntimeEnabled(Advisor.IsHealerCharacter())
        if Advisor.ProcTracker then
            Advisor.ProcTracker.RefreshVisibility()
        end
        if IsSupportedCharacter() then
            ScheduleRefresh(1, event)
        elseif Advisor.UI then
            Advisor.UI.Refresh()
        end
        return
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then
        return
    elseif not IsSupportedCharacter() then
        return
    else
        ScheduleRefresh(1, event)
    end
end)
