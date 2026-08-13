local Advisor = _G.CoAAnalyticsAdvisor

-- Cette photographie est reconstruite entre les versions à partir des
-- fichiers DataProbe envoyés volontairement. Elle ne contient aucune donnée
-- téléchargée en direct et permet de distinguer clairement la couverture
-- communautaire de l'archive présente sur ce client.
Advisor.CommunityData = {
    schemaVersion = 1,
    addonVersion = "0.11.1",
    updatedAt = "2026-08-06",
    contributors = 2,
    sourceFiles = 8,
    profiles = {
        {
            key = "RANGER:28",
            className = "Ranger",
            specializationName = "Archery",
            contributors = 2,
            sessions = 4,
            snapshots = 97,
            fights = 45,
            buildCoverage = 100,
            equipmentCoverage = 100,
            combatCoverage = 100,
            pvpCombatCoverage = 100,
            pveCombatCoverage = 0,
            varietyCoverage = 43,
            totalCoverage = 82,
            modelStatus =
                "combat BG calibré — coefficients d'arme encore provisoires",
            combatSummary = {
                segments = 45,
                seconds = 861.8,
                events = 6590,
                resourceSamples = 1737,
                deathRate = 0.289,
                movementRate = 0.683,
                focusLowSampleRate = 0.158,
                accuracyFailureRate = 0.011,
                pinpointFocusShare = 0.082,
            },
        },
        {
            key = "CHRONOMANCER:31",
            className = "Chronomancer",
            specializationName = "Time",
            contributors = 1,
            sessions = 5,
            snapshots = 100,
            -- Le profil local cumulatif contient 158 combats. Les 45 segments
            -- détaillés du DataProbe en font partie : ils ne sont pas ajoutés
            -- une seconde fois.
            fights = 158,
            buildCoverage = 100,
            equipmentCoverage = 100,
            combatCoverage = 100,
            pvpCombatCoverage = 100,
            pveCombatCoverage = 0,
            varietyCoverage = 60,
            totalCoverage = 83,
            modelStatus =
                "combat BG calibré — équipement niveaux 33, 36, 56 et 60",
            combatSummary = {
                segments = 45,
                seconds = 777.9,
                events = 4164,
                resourceSamples = 1571,
                deathRate = 0.333,
                movementRate = 0.374,
                overhealRate = 0.305,
                mainHealShare = 0.883,
                manaLowSampleRate = 0.052,
            },
        },
        {
            key = "SUNCLERIC:47",
            className = "Sun Cleric",
            specializationName = "Valkyrie",
            contributors = 1,
            sessions = 1,
            snapshots = 4,
            fights = 1,
            buildCoverage = 100,
            equipmentCoverage = 42,
            combatCoverage = 40,
            pvpCombatCoverage = 0,
            pveCombatCoverage = 40,
            varietyCoverage = 22,
            totalCoverage = 57,
            modelStatus =
                "exploratoire — combat probablement réalisé hors BG",
        },
        {
            key = "SONOFARUGAL:27",
            className = "Bloodmage",
            specializationName = "Accursed",
            contributors = 1,
            sessions = 2,
            snapshots = 4,
            fights = 0,
            buildCoverage = 59,
            equipmentCoverage = 55,
            combatCoverage = 0,
            pvpCombatCoverage = 0,
            pveCombatCoverage = 0,
            varietyCoverage = 23,
            totalCoverage = 36,
            modelStatus = "build et équipement partiels — combats manquants",
        },
        {
            key = "STARCALLER:0",
            className = "Starcaller",
            specializationName = "Spécialisation inconnue",
            contributors = 1,
            sessions = 1,
            snapshots = 3,
            fights = 0,
            buildCoverage = 43,
            equipmentCoverage = 23,
            combatCoverage = 0,
            pvpCombatCoverage = 0,
            pveCombatCoverage = 0,
            varietyCoverage = 22,
            totalCoverage = 22,
            modelStatus =
                "identité de spécialisation et combats manquants",
        },
    },
}

local function Round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function MeasurementForGuide(guide)
    if not Advisor.GuideProfiles then return nil end
    for _, measurement in ipairs(Advisor.CommunityData.profiles or {}) do
        local matched = Advisor.GuideProfiles.FindByNames(
            measurement.className,
            measurement.specializationName
        )
        if matched == guide then return measurement end
    end
    return nil
end

local function AddNeed(needs, condition, text)
    if condition then needs[#needs + 1] = text end
end

local function BuildPublishedProfile(guide)
    local measurement = MeasurementForGuide(guide)
    local guideCoverage = tonumber(guide.guideCoverage) or 0
    local buildCoverage = measurement and
        tonumber(measurement.buildCoverage) or 0
    local equipmentCoverage = measurement and
        tonumber(measurement.equipmentCoverage) or 0
    local pvpCombatCoverage = measurement and
        tonumber(measurement.pvpCombatCoverage) or 0
    local pveCombatCoverage = measurement and
        tonumber(measurement.pveCombatCoverage) or 0
    local varietyCoverage = measurement and
        tonumber(measurement.varietyCoverage) or 0
    local totalCoverage = Round(
        guideCoverage * 0.25 +
        buildCoverage * 0.20 +
        equipmentCoverage * 0.20 +
        pvpCombatCoverage * 0.15 +
        pveCombatCoverage * 0.15 +
        varietyCoverage * 0.05
    )

    local needs = {}
    AddNeed(
        needs,
        guideCoverage < 100,
        "Guide : priorités PvE/PvP à compléter ou vérifier."
    )
    AddNeed(
        needs,
        buildCoverage < 100,
        "DataProbe build : ouvrir les deux arbres, capturer les talents et survoler les sorts clés."
    )
    AddNeed(
        needs,
        equipmentCoverage < 100,
        "DataProbe équipement : survoler les pièces et mesurer plusieurs retraits/remises avec des stats différentes."
    )
    AddNeed(
        needs,
        pvpCombatCoverage < 100,
        "DataProbe PvP : enregistrer 3 à 5 BG représentatifs avec le même build."
    )
    AddNeed(
        needs,
        pveCombatCoverage < 100,
        "DataProbe PvE : enregistrer au moins 10 combats de donjon/raid ou monde."
    )
    AddNeed(
        needs,
        varietyCoverage < 75,
        "Variété : répéter à plusieurs niveaux, sessions ou types de contenu."
    )

    return {
        key = measurement and measurement.key or
            (guide.classKey .. ":" .. guide.specializationName),
        className = guide.className,
        specializationName = guide.specializationName,
        contributors = measurement and measurement.contributors or 0,
        sessions = measurement and measurement.sessions or 0,
        snapshots = measurement and measurement.snapshots or 0,
        fights = measurement and measurement.fights or 0,
        guideCoverage = guideCoverage,
        buildCoverage = buildCoverage,
        equipmentCoverage = equipmentCoverage,
        combatCoverage = Round(
            (pvpCombatCoverage + pveCombatCoverage) / 2
        ),
        pvpCombatCoverage = pvpCombatCoverage,
        pveCombatCoverage = pveCombatCoverage,
        varietyCoverage = varietyCoverage,
        totalCoverage = totalCoverage,
        modelStatus = measurement and measurement.modelStatus or
            "guide provisoire — aucune archive DataProbe communautaire",
        combatSummary = measurement and measurement.combatSummary,
        guideSource = guide.source,
        guideRole = guide.guideRole,
        resource = guide.resource,
        primary = guide.primary,
        nextNeed = needs[1] or
            "Profil couvert : poursuivre la validation après les équilibrages.",
        needs = needs,
    }
end

function Advisor.CommunityData.GetCoverage()
    local profiles = {}
    local dataProbeProfiles = 0
    local total = 0
    for _, guide in ipairs(
        (Advisor.GuideProfiles and Advisor.GuideProfiles.GetAll()) or {}
    ) do
        local profile = BuildPublishedProfile(guide)
        profiles[#profiles + 1] = profile
        total = total + profile.totalCoverage
        if profile.contributors > 0 then
            dataProbeProfiles = dataProbeProfiles + 1
        end
    end
    table.sort(profiles, function(left, right)
        if left.totalCoverage == right.totalCoverage then
            return (left.className .. left.specializationName) <
                (right.className .. right.specializationName)
        end
        return left.totalCoverage > right.totalCoverage
    end)
    return {
        profiles = profiles,
        contributors = Advisor.CommunityData.contributors,
        sourceFiles = Advisor.CommunityData.sourceFiles,
        updatedAt = Advisor.CommunityData.updatedAt,
        addonVersion = Advisor.CommunityData.addonVersion,
        guideProfiles = #profiles,
        dataProbeProfiles = dataProbeProfiles,
        averageCoverage = #profiles > 0 and Round(total / #profiles) or 0,
        weights = {
            guide = 25,
            build = 20,
            equipment = 20,
            pvpCombat = 15,
            pveCombat = 15,
            variety = 5,
        },
        description =
            "Complétion du profil : guide publié + preuves DataProbe communautaires.",
    }
end
