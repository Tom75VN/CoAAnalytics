local Advisor = _G.CoAAnalyticsAdvisor

Advisor.StatModel = {}
local Model = Advisor.StatModel

local function EffectiveFromRaw(rawValue, multiplier, rounding)
    local scaled = rawValue * multiplier
    if rounding == "floor" then
        return math.floor(scaled + 0.000001)
    end
    return math.ceil(scaled - 0.000001)
end

local function ReverseEffective(effective, multiplier, rounding)
    if multiplier <= 1 then return effective end
    local estimate = math.floor(effective / multiplier)
    for raw = math.max(0, estimate - 3), estimate + 3 do
        if EffectiveFromRaw(raw, multiplier, rounding) == effective then
            return raw
        end
    end
    return estimate
end

local function ApplyRawDelta(currentEffective, rawDelta, multiplier, rounding)
    rawDelta = tonumber(rawDelta) or 0
    if math.abs(rawDelta) < 0.000001 then
        return currentEffective
    end

    local estimatedRaw =
        ReverseEffective(currentEffective, multiplier, rounding)
    local estimatedBaseline =
        EffectiveFromRaw(estimatedRaw, multiplier, rounding)
    local estimatedAfter = EffectiveFromRaw(
        math.max(0, estimatedRaw + rawDelta),
        multiplier,
        rounding
    )
    return math.max(
        0,
        currentEffective + (estimatedAfter - estimatedBaseline)
    )
end

local function HasAnyDelta(delta, keys)
    for _, key in ipairs(keys) do
        if math.abs(tonumber(delta[key]) or 0) >= 0.000001 then
            return true
        end
    end
    return false
end

local function TalentRank(name)
    return Advisor.TalentScanner.GetRank(name)
end

local function SpiritMultiplier()
    local rank = TalentRank("Rippling Power")
    if rank >= 2 then return 1.15 end
    if rank == 1 then return 1.08 end
    return 1
end

local function IntellectMultiplier()
    local _, raceToken = UnitRace("player")
    if raceToken == "Gnome" or raceToken == "GNOME" then return 1.05 end
    return 1
end

local function SandsCoefficient()
    local rank = TalentRank("Sands of Life")
    if rank >= 2 then return 0.50 end
    if rank == 1 then return 0.25 end
    return 0
end

local function TalentHaste()
    local perfect = TalentRank("Perfect Timing")
    local quickcaster = TalentRank("Quickcaster")
    return perfect * 4 + quickcaster * 4
end

local function TimeWizardBonus()
    local rank = TalentRank("Time Wizard")
    if rank >= 2 then return 15 end
    if rank == 1 then return 8 end
    return 0
end

local function RatingPercentPerPoint(currentRating, currentBonus, fallback)
    if currentRating and currentRating > 0 and currentBonus then
        return currentBonus / currentRating, true
    end
    return fallback, false
end

local function PercentChange(currentValue, newValue)
    if not currentValue or currentValue == 0 then return 0 end
    return (newValue / currentValue - 1) * 100
end

local function ContextPower(character, delta, contentMode, level, outputKind)
    local values = Advisor.Data.effectValues or {}
    local key, perPercent, active
    if contentMode == "pvp" then
        key = "pvpPower"
        perPercent = tonumber(values.pvpPowerPerPercent) or 10
        active = true
    else
        key = "pvePower"
        if outputKind == "healing" then
            perPercent = tonumber(values.pveHealingPowerPerPercent) or 50
        else
            perPercent = tonumber(values.pveDamagePowerPerPercent) or 20
        end
        active = (tonumber(level) or 1) >=
            (tonumber(values.pvePowerMinimumLevel) or 60)
    end
    local current = tonumber(character.itemTotals[key]) or 0
    local newValue = math.max(0, current + (tonumber(delta[key]) or 0))
    if not active then return 0, 0, key, false end
    return current, newValue, key, true, perPercent
end

local function PowerMultiplier(value, perPercent)
    perPercent = math.max(0.001, tonumber(perPercent) or 10)
    return 1 + math.max(0, tonumber(value) or 0) /
        (perPercent * 100)
end

local function CalibratedLevelValue(
    values,
    level,
    fallback,
    scaleOutside
)
    if type(values) ~= "table" then return fallback, false end
    level = math.max(1, tonumber(level) or 1)
    local lowerLevel, lowerValue
    local upperLevel, upperValue
    for rawLevel, rawValue in pairs(values) do
        local pointLevel = tonumber(rawLevel)
        local pointValue = tonumber(rawValue)
        if pointLevel and pointValue then
            if pointLevel <= level and (
                not lowerLevel or pointLevel > lowerLevel
            ) then
                lowerLevel, lowerValue = pointLevel, pointValue
            end
            if pointLevel >= level and (
                not upperLevel or pointLevel < upperLevel
            ) then
                upperLevel, upperValue = pointLevel, pointValue
            end
        end
    end
    if lowerLevel and upperLevel then
        if lowerLevel == upperLevel then return lowerValue, true end
        local progress =
            (level - lowerLevel) / (upperLevel - lowerLevel)
        return lowerValue + (upperValue - lowerValue) * progress, true
    end
    local pointLevel = lowerLevel or upperLevel
    local pointValue = lowerValue or upperValue
    if not pointLevel then return fallback, false end
    if scaleOutside then
        return pointValue * pointLevel / level, true
    end
    return pointValue, true
end

local function PredictTime(character, delta, context)
    delta = delta or {}
    context = context or {}
    local contentMode = context.contentMode or
        (Advisor.GetSelectedContentMode and
            Advisor.GetSelectedContentMode()) or "pvp"
    local spiritMultiplier = SpiritMultiplier()
    local intellectMultiplier = IntellectMultiplier()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local calibration = classProfile and classProfile.calibration or {}

    local newSpirit = ApplyRawDelta(
        character.spirit,
        delta.spirit,
        spiritMultiplier,
        "floor"
    )
    local newIntellect = ApplyRawDelta(
        character.intellect,
        delta.intellect,
        intellectMultiplier,
        "ceil"
    )
    local newStamina = math.max(0, character.stamina + (delta.stamina or 0))

    local sands = SandsCoefficient()
    local currentSandsHealing = math.floor(character.spirit * sands)
    local otherHealing =
        character.healing - character.spellPower - currentSandsHealing
    local newSpellPower = character.spellPower + (delta.spellPower or 0)
    local currentOnUseSpellPower =
        tonumber(character.itemTotals.onUseSpellPowerAverage) or 0
    local newOnUseSpellPower = math.max(
        0,
        currentOnUseSpellPower +
            (tonumber(delta.onUseSpellPowerAverage) or 0)
    )
    local newHealing =
        newSpellPower + math.floor(newSpirit * sands) + otherHealing +
        (delta.bonusHealing or 0)
    local currentEffectiveHealing =
        character.healing + currentOnUseSpellPower
    local newEffectiveHealing = newHealing + newOnUseSpellPower

    local manaMax =
        character.manaMax + (newIntellect - character.intellect) * 15
    local healthMax =
        character.healthMax + (newStamina - character.stamina) * 10

    local currentMP5 = character.itemTotals.mp5 or 0
    local newMP5 = currentMP5 + (delta.mp5 or 0)
    local currentManaRestorePer120 =
        character.itemTotals.manaRestorePer120 or 0
    local newManaRestorePer120 =
        currentManaRestorePer120 +
        (delta.manaRestorePer120 or 0)
    local statRegen = math.max(0, character.manaRegen - currentMP5 / 5)
    local spiritRatio =
        character.spirit > 0 and newSpirit / character.spirit or 1
    local intellectRatio = 1
    if character.intellect > 0 then
        local rootOffset = CalibratedLevelValue(
            calibration.manaRegenIntellectRootOffsetByLevel,
            character.level,
            tonumber(calibration.manaRegenIntellectRootOffset) or 0,
            false
        )
        intellectRatio =
            (math.sqrt(newIntellect) + rootOffset) /
            (math.sqrt(character.intellect) + rootOffset)
    end
    local newStatRegen = statRegen * spiritRatio * intellectRatio
    local newManaRegen = newStatRegen + newMP5 / 5
    local castingFraction = 0
    if statRegen > 0 then
        castingFraction =
            (character.manaRegenCasting - currentMP5 / 5) / statRegen
    end
    castingFraction = Advisor.Clamp(castingFraction, 0, 1)
    local newManaRegenCasting =
        newStatRegen * castingFraction + newMP5 / 5

    local level = math.max(1, character.level or 30)
    local critPerIntellect
    local calibratedCritInt = false
    local referenceCrit =
        tonumber(calibration.critPerIntellectReference)
    local referenceLevel =
        tonumber(calibration.critPerIntellectReferenceLevel)
    critPerIntellect, calibratedCritInt = CalibratedLevelValue(
        calibration.critPerIntellectByLevel,
        level,
        nil,
        true
    )
    if not critPerIntellect and referenceCrit and referenceLevel then
        critPerIntellect =
            referenceCrit * referenceLevel / level
        calibratedCritInt = true
    elseif not critPerIntellect then
        critPerIntellect = 0.071111 * (30 / level)
    end

    local critPerRating, calibratedCritRating = RatingPercentPerPoint(
        character.critRating,
        character.critRatingBonus,
        0.44 * (30 / level)
    )
    local hastePerRating, calibratedHaste = RatingPercentPerPoint(
        character.hasteRating,
        character.hasteBonus,
        0.40 * (30 / level)
    )

    local newCritRating = character.critRating + (delta.crit or 0)
    local newHasteRating = character.hasteRating + (delta.haste or 0)
    local newCritChance =
        character.critChance +
        (newIntellect - character.intellect) * critPerIntellect +
        (newCritRating - character.critRating) * critPerRating
    local currentHaste =
        TalentHaste() + (character.hasteBonus or 0)
    local newHaste =
        TalentHaste() + newHasteRating * hastePerRating

    local mainHealShare = 0.70
    if Advisor.CombatProfiler then
        mainHealShare =
            Advisor.CombatProfiler.GetMainHealShare(contentMode)
    end
    local currentEffectiveCrit =
        character.critChance + TimeWizardBonus() * mainHealShare
    local newEffectiveCrit =
        newCritChance + TimeWizardBonus() * mainHealShare
    -- Le build Mythic+ post-refonte valorise chaque critique au-delà de son
    -- simple bonus de soin : Cadence of Time renforce Ripple, A Ripple In
    -- Time réduit son recharge, Ideal Time crée des fenêtres garanties et
    -- Eternity Warper propage cette valeur aux effets des Aeons. Le facteur
    -- ne modifie que la valeur marginale du score de critique sur l'objet ;
    -- il ne gonfle pas artificiellement les soins actuels du personnage.
    local critMarginalSynergy = contentMode == "pve" and 2.0 or 1.0
    local currentCritMultiplier =
        1 + currentEffectiveCrit * 0.5 / 100
    local newCritMultiplier = math.max(
        0.01,
        currentCritMultiplier +
            (newEffectiveCrit - currentEffectiveCrit) *
            0.5 * critMarginalSynergy / 100
    )
    local currentThroughput =
        currentEffectiveHealing *
        currentCritMultiplier *
        (1 + currentHaste / 100)
    local newThroughput =
        newEffectiveHealing *
        newCritMultiplier *
        (1 + newHaste / 100)
    local currentContextPower, newContextPower, contextPowerKey,
        contextPowerActive, powerPerPercent = ContextPower(
            character,
            delta,
            contentMode,
            level,
            "healing"
        )
    if contextPowerActive then
        currentThroughput = currentThroughput *
            PowerMultiplier(currentContextPower, powerPerPercent)
        newThroughput = newThroughput *
            PowerMultiplier(newContextPower, powerPerPercent)
    end

    -- GetManaRegen returns mana per second. Compare every contribution over
    -- the same 120-second window so that the mana pool, passive regeneration
    -- and explicit on-use restores use consistent units.
    local sustainWindowSeconds = 120
    local currentSustain =
        character.manaRegenCasting * sustainWindowSeconds +
        character.manaMax +
        currentManaRestorePer120
    local newSustain =
        newManaRegenCasting * sustainWindowSeconds +
        manaMax +
        newManaRestorePer120

    local currentResilience = character.itemTotals.resilience or 0
    local newResilience = currentResilience + (delta.resilience or 0)
    local currentArmor = character.armor
    local newArmor = currentArmor + (delta.armor or 0)
    local currentResistance = character.resistances
    local newResistance = currentResistance + (delta.resistance or 0)
    local currentHP5 = character.itemTotals.hp5 or 0
    local newHP5 = currentHP5 + (delta.hp5 or 0)
    local currentMovementSpeed =
        character.itemTotals.movementSpeed or 0
    local newMovementSpeed =
        currentMovementSpeed + (delta.movementSpeed or 0)
    local resilienceWeight = contentMode == "pvp" and 15 or 0
    local mobilityWeight = contentMode == "pvp" and Advisor.Clamp(
        tonumber(calibration.bgMovementRate) or 0.40,
        0.25,
        0.70
    ) or 0.15
    -- HP5 est converti sur la même fenêtre de deux minutes que le modèle
    -- de mana : 120 / 5 = 24 ticks potentiels.
    local currentSurvivalBase =
        character.healthMax +
        currentResilience * resilienceWeight +
        currentArmor * 0.15 +
        currentResistance +
        currentHP5 * 24
    local newSurvivalBase =
        healthMax +
        newResilience * resilienceWeight +
        newArmor * 0.15 +
        newResistance +
        newHP5 * 24
    local currentSurvival =
        currentSurvivalBase *
        (1 + currentMovementSpeed * mobilityWeight / 100)
    local newSurvival =
        newSurvivalBase *
        (1 + newMovementSpeed * mobilityWeight / 100)
    -- PvE Power also reduces damage taken at max level. Use the same
    -- documented linear power scale as a conservative effective-survival
    -- multiplier; PvP Power does not add defensive value.
    if contentMode == "pve" and contextPowerActive then
        local defensePerPercent = tonumber(
            (Advisor.Data.effectValues or {}).pveDefensePowerPerPercent
        ) or 14.285714
        currentSurvival = currentSurvival *
            PowerMultiplier(currentContextPower, defensePerPercent)
        newSurvival = newSurvival *
            PowerMultiplier(newContextPower, defensePerPercent)
    end

    local prediction = {
        spirit = newSpirit,
        intellect = newIntellect,
        stamina = newStamina,
        spellPower = newSpellPower,
        onUseSpellPowerAverage = newOnUseSpellPower,
        effectiveHealing = newEffectiveHealing,
        healing = newHealing,
        manaMax = manaMax,
        healthMax = healthMax,
        manaRegen = newManaRegen,
        manaRegenCasting = newManaRegenCasting,
        manaRestorePer120 = newManaRestorePer120,
        critChance = newCritChance,
        hastePercent = newHaste,
        resilience = newResilience,
        armor = newArmor,
        resistance = newResistance,
        hp5 = newHP5,
        movementSpeed = newMovementSpeed,
        contextPower = newContextPower,
        contextPowerKey = contextPowerKey,
        contentMode = contentMode,
        healingGain = PercentChange(currentThroughput, newThroughput),
        sustainGain = PercentChange(currentSustain, newSustain),
        survivalGain = PercentChange(currentSurvival, newSurvival),
        calibration = {
            critIntellect = calibratedCritInt,
            critRating = calibratedCritRating,
            hasteRating = calibratedHaste,
            critMarginalSynergy = critMarginalSynergy,
        },
    }

    -- Domain invariants: an item cannot alter one of these three scores when
    -- none of that score's input statistics changed. These guards prevent
    -- future rounding or calibration changes from creating phantom gains.
    if not HasAnyDelta(
        delta,
        { "spirit", "intellect", "mp5", "manaRestorePer120" }
    ) then
        prediction.sustainGain = 0
    end
    if not HasAnyDelta(
        delta,
        {
            "spirit", "spellPower", "onUseSpellPowerAverage",
            "bonusHealing", "intellect",
            "crit", "haste",
            "pvpPower", "pvePower",
        }
    ) then
        prediction.healingGain = 0
    end
    if not HasAnyDelta(
        delta,
        {
            "stamina", "resilience", "armor", "resistance", "hp5",
            "movementSpeed",
            "pvePower",
        }
    ) then
        prediction.survivalGain = 0
    end
    return prediction
end

local function RangerAgilityMultiplier()
    local multiplier = 1
    local grace = TalentRank("Grace")
    if grace >= 3 then
        multiplier = multiplier + 0.10
    elseif grace == 2 then
        multiplier = multiplier + 0.07
    elseif grace == 1 then
        multiplier = multiplier + 0.04
    end
    if TalentRank("Boots of Elvenkind") > 0 then
        multiplier = multiplier + 0.05
    end
    return multiplier
end

local function PredictRanger(character, delta, context)
    delta = delta or {}
    context = context or {}
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local calibration = classProfile and classProfile.calibration or {}
    local contentMode = context.contentMode or
        (Advisor.GetSelectedContentMode and
            Advisor.GetSelectedContentMode()) or "pvp"
    local contentContext =
        Advisor.Data.GetContext(classProfile, contentMode) or {}
    local level = math.max(1, tonumber(character.level) or 43)
    local agilityMultiplier = RangerAgilityMultiplier()
    local newAgility = ApplyRawDelta(
        character.agility,
        delta.agility,
        agilityMultiplier
    )
    local agilityDelta = newAgility - character.agility
    local newStamina = math.max(
        0,
        character.stamina + (tonumber(delta.stamina) or 0)
    )
    local healthMax = math.max(
        1,
        character.healthMax + (newStamina - character.stamina) * 10
    )

    -- Les 39 instantanés du Ranger niveau 43 montrent qu'un point
    -- d'Agilité effective apporte un point de puissance d'attaque à distance.
    -- La Force n'entre volontairement pas dans le calcul Archery.
    local currentRAP = tonumber(character.rangedAttackPower) or 0
    local newRAP = math.max(
        0,
        currentRAP + agilityDelta + (tonumber(delta.attackPower) or 0)
    )

    local critPerAgility = 0.052799 * (43 / level)
    local critPerRating, calibratedCrit = RatingPercentPerPoint(
        character.rangedCritRating,
        character.rangedCritRatingBonus,
        0.1061224 * (43 / level)
    )
    local hastePerRating, calibratedHaste = RatingPercentPerPoint(
        character.rangedHasteRating,
        character.rangedHasteBonus,
        0.1485714 * (43 / level)
    )
    local hitPerRating, calibratedHit = RatingPercentPerPoint(
        character.rangedHitRating,
        character.rangedHitBonus,
        0.14 * (43 / level)
    )

    local currentCrit = tonumber(character.rangedCritChance) or 0
    local newCrit = currentCrit +
        agilityDelta * critPerAgility +
        (tonumber(delta.crit) or 0) * critPerRating
    local currentHaste = tonumber(character.rangedHasteBonus) or 0
    local newHaste = currentHaste +
        (tonumber(delta.haste) or 0) * hastePerRating

    local devastatingRank = TalentRank("Devastating Shots")
    local talentHit = math.min(2, devastatingRank)
    local currentItemHit = tonumber(character.rangedHitBonus) or 0
    local newItemHit = currentItemHit +
        (tonumber(delta.hit) or 0) * hitPerRating
    -- Le guide distingue explicitement le plafond PvP du plafond PvE contre
    -- une cible de trois niveaux supérieure. Ces valeurs restent marquées
    -- provisoires jusqu'à ce que DataProbe dispose d'assez de ratés PvE.
    local requiredHit = tonumber(contentContext.hitCap) or 5
    local baseHitChance = 100 - requiredHit
    local currentHitChance = Advisor.Clamp(
        baseHitChance + talentHit + currentItemHit,
        0,
        100
    )
    local newHitChance = Advisor.Clamp(
        baseHitChance + talentHit + newItemHit,
        0,
        100
    )

    local ranged = character.rangedDamage or {}
    local currentWeaponDPS = tonumber(ranged.weaponDPS) or 0
    local weaponDPSDelta = 0
    if context.candidateEquipLoc == "INVTYPE_RANGED" or
        context.candidateEquipLoc == "INVTYPE_RANGEDRIGHT" or
        context.candidateEquipLoc == "INVTYPE_THROWN" then
        weaponDPSDelta = tonumber(delta.weaponDPS) or 0
    end
    local currentBaseDamage = math.max(
        1,
        currentWeaponDPS + currentRAP / 14
    )
    -- Archery emploie de nombreux coefficients de dégâts d'arme. Le facteur
    -- 1,25 reflète ce rôle sans prétendre remplacer une rotation mesurée.
    local newBaseDamage = math.max(
        1,
        currentBaseDamage +
        weaponDPSDelta * 1.25 +
        (newRAP - currentRAP) / 14
    )

    local currentArmorPen = tonumber(character.armorPenetration) or 0
    local armorPenPerRating = 0.10 * (43 / level)
    if character.armorPenetrationRating and
        character.armorPenetrationRating > 0 and
        character.armorPenetrationBonus then
        armorPenPerRating =
            character.armorPenetrationBonus /
            character.armorPenetrationRating
    end
    local newArmorPen = currentArmorPen +
        (tonumber(delta.armorPenetration) or 0) * armorPenPerRating

    -- Les 45 segments BG contiennent 51 déclenchements de Pinpoint Accuracy,
    -- soit 204 Focus et 8,2 % de la génération de Focus observée. Cette
    -- synergie justifie une prime modérée au critique, sans prétendre avoir
    -- déjà mesuré tous les coefficients de dégâts des sorts.
    local critSynergy = 1.15
    if TalentRank("Pierced") == 0 and
        TalentRank("Pinpoint Accuracy") == 0 then
        critSynergy = 1
    end
    local currentDamage =
        currentBaseDamage *
        (1 + currentCrit * critSynergy / 100) *
        (1 + currentHaste / 100) *
        (currentHitChance / 100) *
        (1 + currentArmorPen * 0.35 / 100)
    local newDamage =
        newBaseDamage *
        (1 + newCrit * critSynergy / 100) *
        (1 + newHaste / 100) *
        (newHitChance / 100) *
        (1 + newArmorPen * 0.35 / 100)
    local currentContextPower, newContextPower, contextPowerKey,
        contextPowerActive, powerPerPercent = ContextPower(
            character,
            delta,
            contentMode,
            level,
            "damage"
        )
    if contextPowerActive then
        currentDamage = currentDamage *
            PowerMultiplier(currentContextPower, powerPerPercent)
        newDamage = newDamage *
            PowerMultiplier(newContextPower, powerPerPercent)
    end

    -- Critique = retours de Focus via Pinpoint Accuracy. Hâte = davantage
    -- d'Auto Shots, donc davantage de Focus via Superb Shot.
    local currentTempo = 100 + currentCrit * 0.35 + currentHaste * 0.80
    local newTempo = 100 + newCrit * 0.35 + newHaste * 0.80

    local currentResilience = character.itemTotals.resilience or 0
    local newResilience =
        currentResilience + (tonumber(delta.resilience) or 0)
    local currentArmor = tonumber(character.armor) or 0
    local newArmor = currentArmor + (tonumber(delta.armor) or 0)
    local currentResistance = tonumber(character.resistances) or 0
    local newResistance =
        currentResistance + (tonumber(delta.resistance) or 0)
    local currentHP5 = character.itemTotals.hp5 or 0
    local newHP5 = currentHP5 + (tonumber(delta.hp5) or 0)
    local currentMovementSpeed =
        character.itemTotals.movementSpeed or 0
    local newMovementSpeed =
        currentMovementSpeed + (tonumber(delta.movementSpeed) or 0)
    local resilienceWeight = contentMode == "pvp" and 15 or 0
    local mobilityWeight = contentMode == "pvp" and Advisor.Clamp(
        tonumber(calibration.bgMovementRate) or 0.50,
        0.25,
        0.70
    ) or 0.15
    local currentSurvivalBase =
        character.healthMax + currentResilience * resilienceWeight +
        currentArmor * 0.15 + currentResistance +
        character.agility * 5 + currentHP5 * 24
    local newSurvivalBase =
        healthMax + newResilience * resilienceWeight +
        newArmor * 0.15 + newResistance +
        newAgility * 5 + newHP5 * 24
    local currentSurvival =
        currentSurvivalBase *
        (1 + currentMovementSpeed * mobilityWeight / 100)
    local newSurvival =
        newSurvivalBase *
        (1 + newMovementSpeed * mobilityWeight / 100)
    if contentMode == "pve" and contextPowerActive then
        local defensePerPercent = tonumber(
            (Advisor.Data.effectValues or {}).pveDefensePowerPerPercent
        ) or 14.285714
        currentSurvival = currentSurvival *
            PowerMultiplier(currentContextPower, defensePerPercent)
        newSurvival = newSurvival *
            PowerMultiplier(newContextPower, defensePerPercent)
    end

    local prediction = {
        agility = newAgility,
        stamina = newStamina,
        rangedAttackPower = newRAP,
        rangedCritChance = newCrit,
        rangedHastePercent = newHaste,
        rangedHitChance = newHitChance,
        armorPenetration = newArmorPen,
        requiredHit = requiredHit,
        contentMode = contentMode,
        healthMax = healthMax,
        hp5 = newHP5,
        movementSpeed = newMovementSpeed,
        contextPower = newContextPower,
        contextPowerKey = contextPowerKey,
        damageGain = PercentChange(currentDamage, newDamage),
        tempoGain = PercentChange(currentTempo, newTempo),
        survivalGain = PercentChange(currentSurvival, newSurvival),
        calibration = {
            agility = true,
            weapon = currentWeaponDPS > 0,
            critRating = calibratedCrit,
            hasteRating = calibratedHaste,
            hitRating = calibratedHit,
            hitCapProvisional =
                contentContext.hitCapProvisional == true,
            combat = true,
        },
    }
    if not HasAnyDelta(
        delta,
        {
            "agility", "attackPower", "crit", "haste", "hit",
            "armorPenetration", "weaponDPS",
            "pvpPower", "pvePower",
        }
    ) then
        prediction.damageGain = 0
        prediction.tempoGain = 0
    elseif not HasAnyDelta(delta, { "agility", "crit", "haste" }) then
        prediction.tempoGain = 0
    end
    if not HasAnyDelta(
        delta,
        {
            "stamina", "resilience", "armor", "resistance", "agility",
            "hp5",
            "movementSpeed",
            "pvePower",
        }
    ) then
        prediction.survivalGain = 0
    end
    return prediction
end

local GUIDE_SURVIVAL_STATS = {
    stamina = true,
    resilience = true,
    armor = true,
    resistance = true,
    defense = true,
    dodge = true,
    parry = true,
    block = true,
    hp5 = true,
}

local GUIDE_SUSTAIN_STATS = {
    mp5 = true,
    manaRestorePer120 = true,
}

local function AddGuideDimension(result, key, value)
    result[key] = (result[key] or 0) + value
end

local function AddGuideStatScore(result, key, score, role)
    if GUIDE_SURVIVAL_STATS[key] then
        AddGuideDimension(result, "survivalGain", score)
    elseif GUIDE_SUSTAIN_STATS[key] then
        AddGuideDimension(result, "sustainGain", score)
    elseif key == "spirit" then
        local throughputShare = role == "HEALER" and 0.55 or 0.75
        AddGuideDimension(
            result,
            "throughputGain",
            score * throughputShare
        )
        AddGuideDimension(
            result,
            "sustainGain",
            score * (1 - throughputShare)
        )
    elseif key == "intellect" then
        AddGuideDimension(result, "throughputGain", score * 0.70)
        AddGuideDimension(result, "sustainGain", score * 0.30)
    elseif key == "haste" then
        AddGuideDimension(result, "throughputGain", score * 0.85)
        AddGuideDimension(result, "sustainGain", score * 0.15)
    else
        AddGuideDimension(result, "throughputGain", score)
    end
end

local function PredictGuide(character, delta, context)
    delta = delta or {}
    context = context or {}
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local contentMode = context.contentMode or
        (Advisor.GetSelectedContentMode and
            Advisor.GetSelectedContentMode()) or "pvp"
    local contentContext =
        Advisor.Data.GetContext(classProfile, contentMode) or {}
    local weights = contentContext.statWeights or {}
    local result = {
        throughputGain = 0,
        sustainGain = 0,
        survivalGain = 0,
        priorityGain = 0,
        contentMode = contentMode,
        scoreKind = "priority_index",
        statWeights = weights,
        calibration = {
            guidePriority = true,
            hasteRating = false,
            critRating = false,
            hitRating = false,
            combat = false,
        },
    }

    -- Dix points de budget pondéré représentent un point d'indice. Cet
    -- indice sert uniquement à trier des statistiques fixes ; ce n'est pas
    -- une estimation de DPS, de soins ou de mitigation.
    for key, weight in pairs(weights) do
        local value = tonumber(delta[key]) or 0
        if value ~= 0 then
            local score = value * weight / 10
            result.priorityGain = result.priorityGain + score
            AddGuideStatScore(
                result,
                key,
                score,
                classProfile and classProfile.role or "DAMAGER"
            )
            if key == "hit" or key == "expertise" or
                key == "defense" or key == "spellPenetration" then
                result.capSensitive = true
            end
        end
    end
    return result
end

function Model.Predict(character, delta, context)
    local classProfile = Advisor.Data.GetActiveClassProfile()
    if classProfile and classProfile.model == "ranger_archery" then
        return PredictRanger(character, delta, context)
    elseif classProfile and classProfile.model == "guide_priority" then
        return PredictGuide(character, delta, context)
    end
    return PredictTime(character, delta, context)
end

function Model.Score(character, delta, profileKey, context)
    local prediction = Model.Predict(character, delta, context)
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local contentMode = context and context.contentMode or
        (Advisor.GetSelectedContentMode and
            Advisor.GetSelectedContentMode()) or nil
    local profile = Advisor.Data.GetProfile(
        profileKey,
        classProfile,
        contentMode
    )
    if not classProfile or not profile then
        prediction.overallGain = 0
        return prediction
    end
    if classProfile.model == "ranger_archery" then
        prediction.overallGain =
            prediction.damageGain * profile.damage +
            prediction.tempoGain * profile.tempo +
            prediction.survivalGain * profile.survival
    elseif classProfile.model == "guide_priority" then
        local talentWeights = profile.talent or {}
        local throughputWeight = talentWeights.throughput or 0.50
        local sustainWeight = talentWeights.sustain or 0.20
        local survivalWeight = talentWeights.survival or 0.20
        local totalWeight = math.max(
            0.01,
            throughputWeight + sustainWeight + survivalWeight
        )
        prediction.overallGain =
            (
                prediction.throughputGain * throughputWeight +
                prediction.sustainGain * sustainWeight +
                prediction.survivalGain * survivalWeight
            ) / totalWeight
    else
        prediction.overallGain =
            prediction.healingGain * profile.healing +
            prediction.sustainGain * profile.sustain +
            prediction.survivalGain * profile.survival
    end
    return prediction
end
