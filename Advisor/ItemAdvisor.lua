local Advisor = _G.CoAAnalyticsAdvisor

Advisor.ItemAdvisor = {}
local ItemAdvisor = Advisor.ItemAdvisor

local function Localized(value)
    return Advisor.LocalizeText and Advisor.LocalizeText(value) or value
end

local function AddLine(tooltip, value, ...)
    tooltip:AddLine(Localized(value), ...)
end

local function AddDoubleLine(tooltip, left, right, ...)
    tooltip:AddDoubleLine(Localized(left), Localized(right), ...)
end

local function SumSlotStats(character, slots)
    local result = {}
    local names = {}
    local links = {}
    local unknownEffects = {}
    local usedFallback = false
    for _, slot in ipairs(slots) do
        local item = character.equipment[slot]
        if item then
            Advisor.AddStats(result, item.stats)
            names[#names + 1] = item.name or Advisor.Data.slotNames[slot]
            links[#links + 1] = item.link
            if item.source == "api-fallback" then usedFallback = true end
            for _, effect in ipairs(item.unknownEffects or {}) do
                unknownEffects[#unknownEffects + 1] = effect
            end
        end
    end
    return result, names, links, unknownEffects, usedFallback
end

local function CandidateSlots(equipLoc, character)
    local slots = Advisor.Data.equipSlots[equipLoc]
    if not slots then return {}, false end
    if equipLoc == "INVTYPE_FINGER" or equipLoc == "INVTYPE_TRINKET" then
        return { { slots[1] }, { slots[2] } }, false
    elseif equipLoc == "INVTYPE_2HWEAPON" then
        return { { 16, 17 } }, false
    elseif equipLoc == "INVTYPE_WEAPONOFFHAND" or
        equipLoc == "INVTYPE_HOLDABLE" or
        equipLoc == "INVTYPE_SHIELD" then
        local mainHand = character and character.equipment and
            character.equipment[16]
        if mainHand and (
            mainHand.equipLoc == "INVTYPE_2HWEAPON" or
            string.find(
                string.lower(mainHand.itemSubType or ""),
                "staff",
                1,
                true
            )
        ) then
            return { { 16, 17 } }, true
        end
    end
    return { slots }, false
end

local function IsWeaponEquipLocation(equipLoc)
    return equipLoc == "INVTYPE_WEAPON" or
        equipLoc == "INVTYPE_WEAPONMAINHAND" or
        equipLoc == "INVTYPE_WEAPONOFFHAND" or
        equipLoc == "INVTYPE_2HWEAPON" or
        equipLoc == "INVTYPE_HOLDABLE" or
        equipLoc == "INVTYPE_SHIELD"
end

local function IsStaffSubtype(itemSubType)
    local subtype = string.lower(tostring(itemSubType or ""))
    return string.find(subtype, "staff", 1, true) ~= nil or
        string.find(subtype, "staves", 1, true) ~= nil or
        string.find(subtype, "bâton", 1, true) ~= nil or
        string.find(subtype, "baton", 1, true) ~= nil
end

local function GuideWeaponMismatch(classProfile, equipLoc, itemSubType)
    local weapons = classProfile and classProfile.weapons
    local style = string.lower(tostring(weapons and weapons.style or ""))
    if style == "" or not IsWeaponEquipLocation(equipLoc) then return false end

    if style == "two-handed" then
        return equipLoc ~= "INVTYPE_2HWEAPON"
    elseif style == "1h + shield" then
        if equipLoc == "INVTYPE_2HWEAPON" then return true end
        if equipLoc == "INVTYPE_WEAPONOFFHAND" or
            equipLoc == "INVTYPE_HOLDABLE" then
            return true
        end
    elseif style == "one-hand melee" then
        return equipLoc == "INVTYPE_2HWEAPON" or
            equipLoc == "INVTYPE_SHIELD" or
            equipLoc == "INVTYPE_HOLDABLE"
    elseif style == "caster weapon" then
        if equipLoc == "INVTYPE_SHIELD" or
            equipLoc == "INVTYPE_WEAPONOFFHAND" then
            return true
        end
        if equipLoc == "INVTYPE_2HWEAPON" then
            return not IsStaffSubtype(itemSubType)
        end
    end
    return false
end

local PROVEN_ARMOR_SLOTS = {
    INVTYPE_HEAD = true,
    INVTYPE_SHOULDER = true,
    INVTYPE_CHEST = true,
    INVTYPE_ROBE = true,
    INVTYPE_WAIST = true,
    INVTYPE_LEGS = true,
    INVTYPE_FEET = true,
    INVTYPE_WRIST = true,
    INVTYPE_HAND = true,
    INVTYPE_CLOAK = true,
}

-- Ascension can report IsUsableItem=false for an equippable loot item that
-- is not in the player's bags yet. Wearing the same armor subtype in the
-- target slot is stronger evidence that the candidate is compatible.
local function AlreadyWearsArmorSubtype(character, equipLoc, itemSubType)
    if not PROVEN_ARMOR_SLOTS[equipLoc] then return false end
    local wanted = string.lower(tostring(itemSubType or ""))
    if wanted == "" then return false end
    for _, slot in ipairs(Advisor.Data.equipSlots[equipLoc] or {}) do
        local equipped = character.equipment and character.equipment[slot]
        if equipped and
            string.lower(tostring(equipped.itemSubType or "")) == wanted then
            return true
        end
    end
    return false
end

local function Verdict(gain)
    if gain >= 5 then return "Forte amélioration", 0.2, 1, 0.2 end
    if gain >= 1 then return "Amélioration", 0.3, 1, 0.3 end
    if gain > -1 then return "Choix situationnel", 1, 0.82, 0 end
    return "Moins bon", 1, 0.25, 0.25
end

local function FormatGain(prediction, value)
    value = tonumber(value) or 0
    if prediction and prediction.scoreKind == "priority_index" then
        return "indice " .. Advisor.FormatSigned(value, 1)
    end
    return Advisor.FormatSigned(value, 1, "%")
end

local function Confidence(
    candidateParsed,
    prediction,
    equippedUnknown,
    usedFallback,
    contentMode
)
    if candidateParsed.unknownEffects and #candidateParsed.unknownEffects > 0 then
        return "Low"
    end
    if equippedUnknown and #equippedUnknown > 0 then return "Low" end
    if not prediction.calibration.hasteRating and
        ((candidateParsed.stats.haste or 0) ~= 0) then
        return "Medium"
    end
    if not prediction.calibration.critRating and
        ((candidateParsed.stats.crit or 0) ~= 0) then
        return "Medium"
    end
    if prediction.calibration.hitRating == false and
        ((candidateParsed.stats.hit or 0) ~= 0) then
        return "Medium"
    end
    if candidateParsed.source == "api-fallback" or usedFallback then
        return "Medium"
    end
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local context = Advisor.Data.GetContext(classProfile, contentMode)
    if context and context.provisional then return "Medium" end
    if classProfile and classProfile.provisional then return "Medium" end
    return "High"
end

function ItemAdvisor.Evaluate(itemLink, candidateParsed)
    if not Advisor.IsItemSupportedCharacter() then return nil end
    local character = Advisor.CharacterScanner.Get()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local name, _, quality, itemLevel, requiredLevel, itemType,
        itemSubType, _, equipLoc = Advisor.SafeCall(GetItemInfo, itemLink)
    if not equipLoc or equipLoc == "" then return nil end

    -- IsUsableItem is available on the 3.3.5 client and accounts for armor
    -- proficiencies and other character restrictions. Keep the check
    -- defensive for Ascension clients where the function may differ. A level
    -- requirement is handled separately so a future-level item is not called
    -- incompatible with the character's armor type.
    local usable = nil
    local usabilityKnown = false
    if type(IsUsableItem) == "function" then
        local rawUsable, detail = Advisor.SafeCall(IsUsableItem, itemLink)
        if not (rawUsable == nil and type(detail) == "string") then
            usable = rawUsable and true or false
            usabilityKnown = true
        end
    end
    local playerLevel = tonumber(character.level) or UnitLevel("player") or 1
    local specIncompatible = GuideWeaponMismatch(
        classProfile,
        equipLoc,
        itemSubType
    )
    local armorCompatibilityProven = itemType == "Armor" and
        AlreadyWearsArmorSubtype(character, equipLoc, itemSubType)
    local incompatible = (usabilityKnown and usable == false and
        (tonumber(requiredLevel) or 0) <= playerLevel and
        not armorCompatibilityProven
    ) or specIncompatible

    local options, requiresTwoHandRemoval = CandidateSlots(equipLoc, character)
    if #options == 0 then return nil end

    -- Une même pièce peut être excellente en PvE et mauvaise en PvP. Les
    -- deux contextes sont toujours calculés contre l'équipement porté afin
    -- que le tooltip indique clairement dans quel set ranger l'objet.
    local contentModes = { "pvp", "pve" }
    local bestByContent = {}
    for _, slots in ipairs(options) do
        local equippedStats, equippedNames, equippedLinks,
            equippedUnknown, usedFallback =
            SumSlotStats(character, slots)
        local sameItem = false
        for _, equippedLink in ipairs(equippedLinks) do
            if equippedLink == itemLink then sameItem = true end
        end

        local delta = Advisor.SubtractStats(
            candidateParsed.stats,
            equippedStats
        )
        for _, contentMode in ipairs(contentModes) do
            local prediction = Advisor.StatModel.Score(
                character,
                delta,
                CoAAnalyticsAdvisorDB.profile,
                {
                    candidateEquipLoc = equipLoc,
                    replacedSlots = slots,
                    contentMode = contentMode,
                }
            )
            local result = {
                itemLink = itemLink,
                itemName = name,
                itemLevel = itemLevel,
                requiredLevel = requiredLevel,
                itemType = itemType,
                itemSubType = itemSubType,
                equipLoc = equipLoc,
                slots = slots,
                replacementNames = equippedNames,
                equippedStats = equippedStats,
                candidateStats = candidateParsed.stats,
                delta = delta,
                prediction = prediction,
                unknownEffects = candidateParsed.unknownEffects,
                recognizedEffects = candidateParsed.recognizedEffects or {},
                isMythic = candidateParsed.isMythic and true or false,
                mythicRank = tonumber(candidateParsed.mythicRank) or 0,
                equippedUnknownEffects = equippedUnknown,
                source = candidateParsed.source,
                usedFallback = usedFallback,
                sameItem = sameItem,
                requiresTwoHandRemoval = requiresTwoHandRemoval,
                incompatible = incompatible,
                specIncompatible = specIncompatible,
                keepsMovementSpeed =
                    (candidateParsed.stats.movementSpeed or 0) > 0 and
                    math.abs(delta.movementSpeed or 0) < 0.001,
                losesMovementSpeed = (delta.movementSpeed or 0) < 0,
                contentMode = contentMode,
            }
            if sameItem then result.prediction.overallGain = 0 end
            result.verdict, result.red, result.green, result.blue =
                Verdict(result.prediction.overallGain)
            if requiresTwoHandRemoval then
                result.verdict = "Paire incomplète"
                result.red, result.green, result.blue = 1, 0.82, 0
            elseif contentMode == "pvp" and
                result.losesMovementSpeed and
                result.prediction.overallGain < 1 then
                result.verdict = "Moins bon pour le BG"
                result.red, result.green, result.blue = 1, 0.3, 0.3
            end
            result.confidence = Confidence(
                candidateParsed,
                prediction,
                equippedUnknown,
                usedFallback,
                contentMode
            )

            local currentBest = bestByContent[contentMode]
            if not currentBest or
                result.prediction.overallGain >
                    currentBest.prediction.overallGain then
                bestByContent[contentMode] = result
            end
        end
    end

    local selectedMode = Advisor.GetSelectedContentMode and
        Advisor.GetSelectedContentMode() or "pvp"
    local best = bestByContent[selectedMode] or bestByContent.pvp or
        bestByContent.pve
    if best then best.contextResults = bestByContent end
    return best
end

local function AddScoreLine(tooltip, label, value, prediction)
    AddDoubleLine(tooltip,
        label,
        FormatGain(prediction, value),
        0.85, 0.85, 0.85,
        value >= 0 and 0.3 or 1,
        value >= 0 and 1 or 0.3,
        0.3
    )
end

local function DecisionDimensions(classProfile, prediction, contentMode)
    local order = classProfile.profileOrder or {}
    local context = Advisor.Data.GetContext(classProfile, contentMode)
    local labels = classProfile.scoreLabels or {}
    local contextLabels = context and context.scoreLabels or {}
    local survivalLabel = contextLabels.third or labels.third
    local survivalCondition =
        context and context.survivalCondition or
        "tu dois mieux survivre"
    if classProfile.model == "guide_priority" then
        local throughputCondition = "tu veux maximiser le rendement principal"
        if classProfile.role == "HEALER" then
            throughputCondition = "tu veux maximiser les soins"
        elseif classProfile.role == "TANK" then
            throughputCondition = "tu veux maximiser la menace"
        elseif classProfile.role == "DAMAGER" then
            throughputCondition = "tu veux maximiser les dégâts"
        end
        return {
            {
                label = labels.first,
                value = prediction.throughputGain or 0,
                profileKey = order[2],
                kind = "throughput",
                condition = throughputCondition,
            },
            {
                label = labels.second,
                value = prediction.sustainGain or 0,
                profileKey = order[3],
                kind = classProfile.role == "HEALER" and
                    "sustain" or "resource",
                condition = "tu veux améliorer la ressource et le rythme",
            },
            {
                label = survivalLabel,
                value = prediction.survivalGain or 0,
                profileKey = order[4],
                kind = "survival",
                condition = survivalCondition,
            },
        }
    elseif classProfile.model == "ranger_archery" then
        return {
            {
                label = labels.first,
                value = prediction.damageGain or 0,
                profileKey = order[2],
                kind = "throughput",
                condition = "tu veux maximiser les dégâts",
            },
            {
                label = labels.second,
                value = prediction.tempoGain or 0,
                profileKey = order[3],
                kind = "resource",
                condition =
                    "tu veux améliorer le rythme et la gestion du Focus",
            },
            {
                label = survivalLabel,
                value = prediction.survivalGain or 0,
                profileKey = order[4],
                kind = "survival",
                condition = survivalCondition,
            },
        }
    end
    return {
        {
            label = labels.first,
            value = prediction.healingGain or 0,
            profileKey = order[2],
            kind = "throughput",
            condition = "tu veux maximiser les soins",
        },
        {
            label = labels.second,
            value = prediction.sustainGain or 0,
            profileKey = order[3],
            kind = "sustain",
            condition = "tu manques souvent de mana",
        },
        {
            label = survivalLabel,
            value = prediction.survivalGain or 0,
            profileKey = order[4],
            kind = "survival",
            condition = survivalCondition,
        },
    }
end

local function LocalPercent(value)
    return tostring(Advisor.Round((tonumber(value) or 0) * 100, 0)) .. "%"
end

local function LocalDimensionEvidence(summary, classProfile, dimension)
    if not summary or (summary.fights or 0) < 5 then
        return "unknown", nil
    end

    local kind = dimension.kind
    local role = classProfile.role or "DAMAGER"
    if kind == "sustain" and role == "HEALER" then
        if (summary.manaFights or 0) < 5 then return "unknown", nil end
        local manaPressure =
            (summary.lowManaFinishRate or 0) >= 0.35 or
            (summary.averageEndMana or 1) <= 0.22 or
            (summary.lowManaTimeRate or 0) >= 0.30
        if manaPressure then
            return "needed",
                "manque de mana détecté : " ..
                LocalPercent(summary.averageEndMana) ..
                " de mana final moyen"
        end
        local manaStable =
            (summary.averageEndMana or 0) >= 0.45 and
            (summary.lowManaFinishRate or 0) <= 0.15 and
            (summary.lowManaTimeRate or 0) <= 0.15
        if manaStable then
            return "not_needed",
                "mana stable : " ..
                LocalPercent(summary.averageEndMana) ..
                " en moyenne à la fin des combats"
        end
    elseif kind == "resource" and
        classProfile.model == "ranger_archery" then
        if (summary.resourceSamples or 0) < 10 then return "unknown", nil end
        if (summary.lowResourceTimeRate or 0) >= 0.45 then
            return "needed",
                "Focus souvent faible pendant les combats (" ..
                LocalPercent(summary.lowResourceTimeRate) .. " du temps)"
        end
        if (summary.lowResourceTimeRate or 0) <= 0.15 and
            (summary.averageEndResource or 0) >= 0.35 then
            return "not_needed",
                "Focus stable : seulement " ..
                LocalPercent(summary.lowResourceTimeRate) ..
                " du temps sous 20%"
        end
    elseif kind == "survival" then
        local deathLimit = role == "TANK" and 0.20 or 0.25
        local healthLimit = role == "TANK" and 0.30 or 0.35
        if (summary.deathRate or 0) >= deathLimit or
            summary.quickDeathPressure or
            (summary.lowHealthTimeRate or 0) >= healthLimit then
            return "needed",
                "survie prioritaire : " ..
                LocalPercent(summary.deathRate) ..
                " des combats se terminent par une mort"
        end
        if (summary.fights or 0) >= 10 and
            (summary.deathRate or 0) <= 0.10 and
            (summary.lowHealthTimeRate or 0) <= 0.15 then
            return "not_needed",
                "survie stable : " ..
                LocalPercent(summary.deathRate) ..
                " de combats terminés par une mort"
        end
    elseif kind == "throughput" then
        if summary.suggestedKey == dimension.profileKey then
            return "needed", summary.reason
        end
        if role == "HEALER" and
            type(summary.overhealRate) == "number" and
            summary.overhealRate >= 0.45 then
            return "not_needed",
                LocalPercent(summary.overhealRate) ..
                " de soins excédentaires : plus de puissance n'est pas prioritaire"
        end
    end

    if summary.suggestedKey == dimension.profileKey then
        return "needed", summary.reason
    end
    if summary.suggestedKey and
        summary.suggestedKey ~= classProfile.defaultProfile and
        summary.suggestedKey ~= dimension.profileKey then
        return "deprioritized", summary.reason
    end
    return "unknown", nil
end

local function FindDecisionExtremes(dimensions)
    local best = dimensions[1]
    local worst = dimensions[1]
    for index = 2, #dimensions do
        local dimension = dimensions[index]
        if dimension.value > best.value then best = dimension end
        if dimension.value < worst.value then worst = dimension end
    end
    return best, worst
end

local function FindRecognizedEffect(result, kind)
    for _, effect in ipairs(result.recognizedEffects or {}) do
        if effect.kind == kind then return effect end
    end
    return nil
end

function ItemAdvisor.GetDecision(result, classProfile, profile)
    local prediction = result.prediction
    local overall = prediction.overallGain or 0
    local dimensions = DecisionDimensions(
        classProfile,
        prediction,
        result.contentMode
    )
    local best, worst = FindDecisionExtremes(dimensions)
    local localSummary = Advisor.LocalAnalyzer and
        Advisor.LocalAnalyzer.GetSummary(classProfile, result.contentMode)
    local bestLocalState, bestLocalEvidence =
        LocalDimensionEvidence(localSummary, classProfile, best)
    local worstLocalState, worstLocalEvidence =
        LocalDimensionEvidence(localSummary, classProfile, worst)
    local decision = {
        action = "GARDER L'ACTUEL",
        reason = "L'écart est trop faible pour justifier le remplacement.",
        red = 1,
        green = 0.82,
        blue = 0,
        best = best,
        worst = worst,
        bestLocalState = bestLocalState,
        worstLocalState = worstLocalState,
    }

    if result.sameItem then
        decision.action = "DÉJÀ ÉQUIPÉ"
        decision.reason = "Aucun changement d'équipement."
        return decision
    end

    if result.requiresTwoHandRemoval then
        decision.action = "COMPARER LA PAIRE"
        decision.reason =
            "Cette main gauche exige aussi une arme à une main compatible."
        decision.red, decision.green, decision.blue = 1, 0.82, 0
        return decision
    end

    if result.incompatible then
        decision.action = "OBJET INCOMPATIBLE"
        decision.reason = result.specIncompatible and
            "Ce type d’arme ne correspond pas au build conseillé." or
            "Ce personnage ne peut pas équiper cet objet."
        decision.red, decision.green, decision.blue = 1, 0.25, 0.25
        return decision
    end

    if result.confidence == "Low" then
        decision.action = "VÉRIFIER MANUELLEMENT"
        decision.reason =
            "Un effet spécial n'est pas évalué : aucun remplacement sûr."
        decision.red, decision.green, decision.blue = 1, 0.55, 0.1
        return decision
    end

    if result.losesMovementSpeed and overall < 1 then
        decision.action = "GARDER L'ACTUEL"
        decision.reason =
            "Les stats ne compensent pas la perte de 8 % de vitesse."
        decision.red, decision.green, decision.blue = 1, 0.3, 0.3
        return decision
    end

    local antiSilence = FindRecognizedEffect(
        result,
        "silenceInterruptReduction"
    )
    if antiSilence and overall > -1 and overall < 1 then
        if result.contentMode == "pvp" then
            decision.action = "CHOIX SITUATIONNEL"
            decision.reason =
                "À équiper contre les adversaires qui utilisent souvent " ..
                "des silences ou interruptions."
            decision.red, decision.green, decision.blue = 0.4, 0.85, 1
        else
            decision.action = "GARDER PAR DÉFAUT"
            decision.reason =
                "Les statistiques sont trop proches ; à équiper seulement " ..
                "sur un combat avec des silences ou interruptions."
        end
        return decision
    end

    if overall >= 1 then
        -- L'historique local affine une recommandation, mais ne doit pas
        -- annuler une amélioration globale parce qu'un autre axe est déjà
        -- stable. Il ne bloque que si l'objet sacrifie réellement (au moins
        -- 1 %) une dimension dont les combats montrent le besoin.
        if worst.value <= -1 and worstLocalState == "needed" then
            decision.action = "GARDER — ANALYSE LOCALE"
            decision.reason =
                "Cet objet sacrifie une priorité détectée dans tes combats."
            decision.localEvidence = worstLocalEvidence
            return decision
        end
        decision.action = "REMPLACER"
        if result.contentMode == "pve" and
            (prediction.healingGain or 0) > 0 and
            (prediction.sustainGain or 0) > 0 and
            (prediction.survivalGain or 0) >= 0 then
            decision.reason =
                "Amélioration équilibrée pour Mythic+ : soins et autonomie progressent."
        elseif result.contentMode == "pve" and
            (prediction.healingGain or 0) >= 1 and
            (prediction.sustainGain or 0) <= -1 then
            decision.reason =
                "Meilleur débit de soins, avec une autonomie mana en baisse."
        else
            decision.reason =
                "Meilleur pour le profil " ..
                tostring(profile.shortLabel or profile.label) .. "."
        end
        decision.red, decision.green, decision.blue = 0.3, 1, 0.3
        if bestLocalState == "needed" then
            decision.localEvidence = bestLocalEvidence
        end
        return decision
    end

    if overall <= -1 then
        decision.action = "GARDER L'ACTUEL"
        if best.value >= 1 then
            if bestLocalState == "not_needed" or
                bestLocalState == "deprioritized" then
                decision.reason =
                    "Le gain principal ne répond pas à ton besoin actuel."
                decision.localEvidence = bestLocalEvidence
            else
                decision.reason =
                    "À envisager seulement si " .. best.condition .. "."
                if bestLocalState == "needed" then
                    decision.localEvidence = bestLocalEvidence
                end
            end
        else
            decision.reason =
                "Le nouvel objet n'apporte aucun avantage suffisant."
        end
        decision.red, decision.green, decision.blue = 1, 0.3, 0.3
        return decision
    end

    -- Entre -1 % et +1 %, le résultat est dans la marge d'incertitude du
    -- modèle. Un échange entre deux dimensions devient donc un choix
    -- conditionnel, pas une recommandation de remplacement automatique.
    if best.value >= 1 and worst.value <= -1 then
        if bestLocalState == "needed" then
            if overall < 0 then
                -- Une amélioration défensive locale ne transforme pas un
                -- score global négatif en véritable upgrade. Elle reste un
                -- choix de progression, affiché en orange et non en vert.
                decision.action = "CHOIX SITUATIONNEL"
                decision.reason =
                    "À envisager pour la progression : meilleure sécurité, " ..
                    "mais rendement global inférieur."
                decision.red, decision.green, decision.blue = 1, 0.65, 0.1
            else
                decision.action = "REMPLACER — ANALYSE LOCALE"
                decision.reason =
                    "Ton historique indique que " .. best.condition .. "."
                decision.red, decision.green, decision.blue = 0.3, 1, 0.3
            end
            decision.localEvidence = bestLocalEvidence
        elseif bestLocalState == "not_needed" or
            bestLocalState == "deprioritized" then
            decision.action = "GARDER — ANALYSE LOCALE"
            decision.reason =
                "Ce gain n'est pas prioritaire pour ton style de jeu actuel."
            decision.localEvidence = bestLocalEvidence
        elseif worstLocalState == "needed" then
            decision.action = "GARDER — ANALYSE LOCALE"
            decision.reason =
                "Cet objet sacrifie une priorité détectée dans tes combats."
            decision.localEvidence = worstLocalEvidence
        else
            decision.action = "GARDER PAR DÉFAUT"
            decision.reason =
                "Équiper seulement si " .. best.condition .. "."
        end
        return decision
    end

    if overall >= 0.3 and worst.value > -1 then
        if worst.value < 0 and worstLocalState == "needed" then
            decision.action = "GARDER — ANALYSE LOCALE"
            decision.reason =
                "Ce petit gain sacrifie une priorité détectée dans tes combats."
            decision.localEvidence = worstLocalEvidence
            return decision
        end
        local primary = dimensions[1]
        if primary and primary.value >= 1 then
            decision.action = "REMPLACER"
            decision.reason =
                "L'objectif principal progresse sans sacrifice important."
            decision.red, decision.green, decision.blue = 0.3, 1, 0.3
            return decision
        end
        decision.action = "REMPLACEMENT OPTIONNEL"
        decision.reason =
            "Petit gain, mais trop faible pour être une amélioration certaine."
        decision.red, decision.green, decision.blue = 1, 0.82, 0
        return decision
    end

    return decision
end

local function MythicCoinAdvice(result, classProfile)
    if not result or not result.isMythic or
        not classProfile or classProfile.model ~= "time_healer" then
        return nil
    end

    local stats = result.candidateStats or {}
    local mythicRank = tonumber(result.mythicRank) or 0
    local idealCount = 0
    for _, key in ipairs({ "spirit", "spellPower", "crit", "haste" }) do
        if (tonumber(stats[key]) or 0) > 0 then
            idealCount = idealCount + 1
        end
    end
    local wasted =
        (tonumber(stats.hit) or 0) +
        (tonumber(stats.spellPenetration) or 0) +
        (tonumber(stats.armorPenetration) or 0) +
        (tonumber(stats.strength) or 0) +
        (tonumber(stats.agility) or 0) +
        (tonumber(stats.attackPower) or 0)
    local isIdealStaff = result.equipLoc == "INVTYPE_2HWEAPON" and
        IsStaffSubtype(result.itemSubType) and
        (tonumber(stats.spirit) or 0) > 0 and
        (tonumber(stats.spellPower) or 0) > 0 and
        ((tonumber(stats.crit) or 0) > 0 or
            (tonumber(stats.haste) or 0) > 0) and
        wasted == 0

    if isIdealStaff then
        return "TRÈS HAUTE",
            "Pièce durable Time : Esprit, puissance des sorts et critique/hâte, sans statistique gaspillée."
    end
    if mythicRank >= 6 then
        return "MOYENNE",
            "Déjà fortement amélioré : réserve d'abord les pièces aux objets parfaits de rang inférieur."
    end
    if idealCount >= 3 and wasted == 0 then
        return "HAUTE",
            "Très bonnes statistiques Time sans toucher ni pénétration inutiles."
    end
    if idealCount >= 2 and wasted == 0 then
        return "MOYENNE",
            "Bonne base Time, mais vérifie qu'elle restera longtemps équipée."
    end
    if wasted > 0 then
        return "FAIBLE",
            "Évite d'investir des pièces Mythic : une partie du budget est gaspillée pour Time."
    end
    return "MOYENNE",
        "Objet spécialisé : améliore-le seulement si tu comptes le conserver."
end

local function ShortDecision(decision)
    local action = decision and decision.action or "GARDER L'ACTUEL"
    if action == "REMPLACER" or
        action == "REMPLACER — ANALYSE LOCALE" then
        return "ÉQUIPER", true
    elseif action == "REMPLACEMENT OPTIONNEL" then
        return "OPTIONNEL", false
    elseif action == "CHOIX SITUATIONNEL" then
        return "SITUATIONNEL", false
    elseif action == "VÉRIFIER MANUELLEMENT" then
        return "VÉRIFIER", false
    elseif action == "OBJET INCOMPATIBLE" then
        return "INCOMPATIBLE", false
    elseif action == "COMPARER LA PAIRE" then
        return "COMPARER", false
    elseif action == "DÉJÀ ÉQUIPÉ" then
        return "ÉQUIPÉ", false
    end
    return "GARDER", false
end

local function AddContextSummary(tooltip, classProfile, contextResult)
    if not contextResult then return end
    local profile = Advisor.Data.GetProfile(
        CoAAnalyticsAdvisorDB.profile,
        classProfile,
        contextResult.contentMode
    )
    if not profile then return end
    local decision = ItemAdvisor.GetDecision(
        contextResult,
        classProfile,
        profile
    )
    local action, equips = ShortDecision(decision)
    local label = contextResult.contentMode == "pvp" and
        "Set PvP / BG" or "Set PvE / donjons"
    local gain = contextResult.incompatible and "" or
        contextResult.requiresTwoHandRemoval and
        Localized("arme 1M requise") or
        FormatGain(
            contextResult.prediction,
            contextResult.prediction.overallGain or 0
        )
    AddDoubleLine(
        tooltip,
        label,
        Localized(action) .. (gain ~= "" and "  " .. gain or ""),
        0.4, 0.8, 1,
        decision.red, decision.green, decision.blue
    )
    if equips and #contextResult.replacementNames > 0 then
        AddDoubleLine(
            tooltip,
            "Remplacer dans ce set",
            table.concat(contextResult.replacementNames, " + "),
            0.7, 0.7, 0.7,
            1, 1, 1
        )
    end
end

local function StatOrder(classProfile)
    if classProfile.model == "guide_priority" then
        return {
            { "weaponDPS", "DPS de l’arme" },
            { "strength", "Force" },
            { "agility", "Agilité" },
            { "intellect", "Intelligence" },
            { "spirit", "Esprit" },
            { "stamina", "Endurance" },
            { "attackPower", "Puissance d’attaque" },
            { "spellPower", "Puissance des sorts" },
            { "onUseSpellPowerAverage", "Puissance des sorts moyenne (activation)" },
            { "bonusHealing", "Bonus de soins" },
            { "hit", "Score de toucher" },
            { "expertise", "Score d’expertise" },
            { "crit", "Score de coup critique" },
            { "haste", "Score de hâte" },
            { "armorPenetration", "Pénétration d’armure" },
            { "spellPenetration", "Pénétration des sorts" },
            { "defense", "Score de défense" },
            { "dodge", "Score d’esquive" },
            { "parry", "Score de parade" },
            { "block", "Blocage" },
            { "resilience", "Résilience" },
            { "pvpPower", "Puissance JcJ" },
            { "pvePower", "Puissance JcE" },
            { "mp5", "MP5" },
            { "armor", "Armure" },
            { "resistance", "Résistances" },
            { "hp5", "Vie par 5 s" },
            { "movementSpeed", "Vitesse de course %" },
        }
    elseif classProfile.model == "ranger_archery" then
        return {
            { "weaponDPS", "DPS de l’arme à distance" },
            { "agility", "Agilité" },
            { "attackPower", "Puissance d’attaque" },
            { "crit", "Score de coup critique" },
            { "haste", "Score de hâte" },
            { "hit", "Score de toucher" },
            { "armorPenetration", "Pénétration d’armure" },
            { "stamina", "Endurance" },
            { "resilience", "Résilience" },
            { "pvpPower", "Puissance JcJ" },
            { "pvePower", "Puissance JcE" },
            { "armor", "Armure" },
            { "hp5", "Vie par 5 s" },
            { "movementSpeed", "Vitesse de course %" },
            { "strength", "Force (non valorisée)" },
        }
    end
    return {
        { "spirit", "Esprit" },
        { "spellPower", "Puissance des sorts" },
        { "onUseSpellPowerAverage", "Puissance des sorts moyenne (activation)" },
        { "bonusHealing", "Bonus de soins" },
        { "haste", "Score de hâte" },
        { "intellect", "Intelligence" },
        { "crit", "Score de coup critique" },
        { "spellPenetration", "Pénétration des sorts" },
        { "mp5", "MP5" },
        { "stamina", "Endurance" },
        { "resilience", "Résilience" },
        { "pvpPower", "Puissance JcJ" },
        { "pvePower", "Puissance JcE" },
        { "armor", "Armure" },
        { "hp5", "Vie par 5 s" },
        { "movementSpeed", "Vitesse de course %" },
        { "agility", "Agilité (sans valeur pour les soins)" },
        { "strength", "Force (sans valeur pour les soins)" },
    }
end

function ItemAdvisor.AddToTooltip(tooltip, result)
    if not result then return end
    local classProfile = Advisor.Data.GetActiveClassProfile()
    if not classProfile then return end
    local prediction = result.prediction
    local profile = Advisor.Data.GetProfile(
        CoAAnalyticsAdvisorDB.profile,
        classProfile,
        result.contentMode
    )
    local contentContext =
        Advisor.Data.GetContext(classProfile, result.contentMode)
    local scoreLabels = classProfile.scoreLabels or {}
    local contextScoreLabels =
        contentContext and contentContext.scoreLabels or {}

    AddLine(tooltip, " ")
    AddLine(
        tooltip,
        "CoA Analytics - " ..
            tostring(classProfile.shortTitle or classProfile.title),
        0.4, 0.8, 1
    )
    AddLine(tooltip, "Conseils par set", 1, 0.82, 0)
    local contextResults = result.contextResults or {
        [result.contentMode] = result,
    }
    AddContextSummary(tooltip, classProfile, contextResults.pvp)
    AddContextSummary(tooltip, classProfile, contextResults.pve)
    AddLine(
        tooltip,
        "Détail actif : " ..
            tostring(contentContext and contentContext.label or "") ..
            " — " .. tostring(profile.shortLabel or profile.label),
        0.58, 0.68, 0.78, true
    )
    if contentContext and contentContext.priority then
        AddLine(tooltip,
            "Priorité " .. tostring(contentContext.label) .. " : " ..
            tostring(contentContext.priority),
            0.58, 0.68, 0.78, true
        )
    end
    local verdictValue = result.requiresTwoHandRemoval and
        "arme 1M requise" or
        FormatGain(prediction, prediction.overallGain)
    AddDoubleLine(tooltip,
        result.verdict,
        verdictValue,
        result.red, result.green, result.blue,
        result.red, result.green, result.blue
    )
    local decision = ItemAdvisor.GetDecision(result, classProfile, profile)
    AddDoubleLine(tooltip,
        "Décision",
        decision.action,
        0.9, 0.9, 0.9,
        decision.red, decision.green, decision.blue
    )
    AddLine(tooltip,
        decision.reason,
        decision.red, decision.green, decision.blue, true
    )
    if decision.localEvidence then
        AddLine(tooltip,
            "Analyse locale : " .. decision.localEvidence,
            0.35, 0.85, 1, true
        )
    end
    local mythicPriority, mythicReason =
        MythicCoinAdvice(result, classProfile)
    if mythicPriority then
        AddDoubleLine(tooltip,
            "Priorité Mythic Coins",
            mythicPriority,
            0.85, 0.85, 0.85,
            mythicPriority == "FAIBLE" and 1 or 0.3,
            mythicPriority == "FAIBLE" and 0.35 or 1,
            0.3
        )
        AddLine(tooltip, mythicReason, 0.65, 0.82, 1, true)
    end
    if decision.worst and decision.worst.value <= -1 then
        AddDoubleLine(tooltip,
            "Sacrifice principal",
            decision.worst.label .. " " ..
                FormatGain(prediction, decision.worst.value),
            0.75, 0.75, 0.75,
            1, 0.35, 0.35
        )
    end
    if #result.replacementNames > 0 then
        tooltip:AddDoubleLine(
            Localized("Remplacer"),
            table.concat(result.replacementNames, " + "),
            0.8, 0.8, 0.8,
            1, 1, 1
        )
    else
        AddDoubleLine(tooltip,
            "Emplacement vide",
            Advisor.Data.slotNames[result.slots[1]] or "",
            0.8, 0.8, 0.8,
            0.3, 1, 0.3
        )
    end
    if result.requiresTwoHandRemoval then
        AddLine(tooltip,
            "Comparaison incomplète : main gauche seule contre bâton.",
            1, 0.55, 0.1, true
        )
        AddLine(tooltip,
            "Choisis aussi une arme 1M pour comparer la paire complète.",
            1, 0.55, 0.1, true
        )
    end

    if classProfile.model == "guide_priority" then
        AddScoreLine(
            tooltip,
            scoreLabels.first,
            prediction.throughputGain,
            prediction
        )
        AddScoreLine(
            tooltip,
            scoreLabels.second,
            prediction.sustainGain,
            prediction
        )
        AddLine(tooltip,
            "Indice de priorité : comparaison ordinale, pas un pourcentage " ..
            "de DPS, de soins ou de mitigation.",
            1, 0.72, 0.2, true
        )
        if prediction.capSensitive then
            AddLine(tooltip,
                "Un cap (toucher, expertise, défense ou pénétration) change " ..
                "dans cette comparaison : confirme le seuil en jeu.",
                1, 0.55, 0.1, true
            )
        end
    elseif classProfile.model == "ranger_archery" then
        AddScoreLine(
            tooltip,
            scoreLabels.first,
            prediction.damageGain,
            prediction
        )
        AddScoreLine(
            tooltip,
            scoreLabels.second,
            prediction.tempoGain,
            prediction
        )
        AddLine(tooltip,
            "Rythme : critique, hâte et génération de Focus estimée",
            0.58, 0.68, 0.78, true
        )
        if prediction.requiredHit then
            AddLine(tooltip,
                "Toucher : " ..
                tostring(Advisor.Round(prediction.rangedHitChance or 0, 1)) ..
                "% prévu, plafond " ..
                tostring(Advisor.Round(prediction.requiredHit, 1)) ..
                "% de bonus" ..
                (prediction.calibration.hitCapProvisional and
                    " (à confirmer par DataProbe PvE)" or ""),
                0.58, 0.68, 0.78, true
            )
        end
    else
        AddScoreLine(
            tooltip,
            scoreLabels.first,
            prediction.healingGain,
            prediction
        )
        AddScoreLine(
            tooltip,
            scoreLabels.second,
            prediction.sustainGain,
            prediction
        )
        AddLine(tooltip,
            "Mana : régénération en incantation + réserve estimée sur 2 min",
            0.58, 0.68, 0.78, true
        )
    end
    AddScoreLine(
        tooltip,
        contextScoreLabels.third or scoreLabels.third,
        prediction.survivalGain,
        prediction
    )

    local changes = {}
    for _, entry in ipairs(StatOrder(classProfile)) do
        local value = result.delta[entry[1]] or 0
        if math.abs(value) > 0.001 then
            changes[#changes + 1] =
                Advisor.FormatSigned(value, 1) .. " " .. entry[2]
        end
    end
    if #changes > 0 then
        AddLine(tooltip, table.concat(changes, ", "), 0.75, 0.75, 0.75, true)
    end

    for _, effect in ipairs(result.recognizedEffects or {}) do
        if effect.kind == "manaRestore" then
            local cooldownMinutes =
                (tonumber(effect.cooldownSeconds) or 0) / 60
            AddLine(tooltip,
                "Effet mana reconnu : +" ..
                tostring(Advisor.Round(effect.amount or 0, 1)) ..
                " / " ..
                tostring(Advisor.Round(cooldownMinutes, 1)) ..
                " min (~" ..
                tostring(Advisor.Round(effect.manaPer120 or 0, 1)) ..
                " par 2 min)",
                0.4, 0.85, 1, true
            )
            if effect.healthCost then
                AddLine(
                    tooltip,
                    "Coût reconnu : " ..
                        tostring(Advisor.Round(effect.healthCost, 1)) ..
                        " points de vie par utilisation",
                    0.8, 0.65, 0.35, true
                )
            end
        elseif effect.kind == "spellPowerOnUse" then
            AddLine(tooltip,
                "Activation reconnue : +" ..
                tostring(Advisor.Round(effect.amount or 0, 1)) ..
                " puissance des sorts pendant " ..
                tostring(Advisor.Round(effect.durationSeconds or 0, 1)) ..
                " s, soit ~+" ..
                tostring(Advisor.Round(effect.averageSpellPower or 0, 1)) ..
                " en moyenne si utilisée à chaque recharge.",
                0.4, 0.85, 1, true
            )
        elseif effect.kind == "runSpeed" then
            local label = result.keepsMovementSpeed and
                "Bonus vitesse conservé sur les deux objets : +" or
                "Effet vitesse reconnu : +"
            AddLine(tooltip,
                label ..
                tostring(Advisor.Round(effect.percent or 0, 1)) ..
                "% (mesuré par DataProbe)",
                0.4, 0.85, 1, true
            )
        elseif effect.kind == "silenceInterruptReduction" then
            local contextNote = result.contentMode == "pvp" and
                " — utile en PvP" or " — situationnel en PvE"
            AddLine(tooltip,
                "Effet anti-silence reconnu : réduction de " ..
                tostring(Advisor.Round(effect.percent or 0, 1)) ..
                "%" .. contextNote,
                0.4, 0.85, 1, true
            )
        end
    end

    if (result.unknownEffects and #result.unknownEffects > 0) or
        (result.equippedUnknownEffects and
            #result.equippedUnknownEffects > 0) then
        AddLine(tooltip,
            "Effet spécial non évalué — vérification manuelle requise",
            1, 0.55, 0.1, true
        )
        for _, effect in ipairs(result.unknownEffects or {}) do
            AddLine(
                tooltip,
                Localized("Ligne candidate : ") .. tostring(effect),
                1, 0.65, 0.25, true
            )
        end
        for _, effect in ipairs(result.equippedUnknownEffects or {}) do
            AddLine(
                tooltip,
                Localized("Ligne équipée : ") .. tostring(effect),
                1, 0.65, 0.25, true
            )
        end
    end
    local confidence =
        result.confidence == "High" and "Élevée" or
        result.confidence == "Medium" and "Moyenne" or
        result.confidence == "Low" and "Faible" or
        tostring(result.confidence)
    if classProfile.provisional or
        (contentContext and contentContext.provisional) then
        confidence = confidence .. " (profil provisoire)"
    end
    AddDoubleLine(tooltip,
        "Confiance",
        confidence,
        0.65, 0.65, 0.65,
        result.confidence == "High" and 0.3 or 1,
        result.confidence == "High" and 1 or 0.75,
        0.3
    )
    tooltip:Show()
end
