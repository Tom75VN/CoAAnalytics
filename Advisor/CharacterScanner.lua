local Advisor = _G.CoAAnalyticsAdvisor

Advisor.CharacterScanner = {
    current = nil,
}
local Scanner = Advisor.CharacterScanner

local function GetSpellDamage()
    local maximum = 0
    for school = 2, 7 do
        local value = Advisor.SafeCall(GetSpellBonusDamage, school)
        if type(value) == "number" and value > maximum then maximum = value end
    end
    return maximum
end

local function NormalizeTransientCrit(
    critChance,
    critFromIntellect,
    critRatingBonus
)
    critChance = tonumber(critChance) or 0
    critFromIntellect = tonumber(critFromIntellect)
    critRatingBonus = tonumber(critRatingBonus) or 0
    if not critFromIntellect then return critChance, false end

    -- Ideal Time can temporarily make the 3.3.5 API report exactly +100
    -- percentage points. That guaranteed next-crit state is not an equipment
    -- stat and must not alter long-term gear comparisons.
    local transient =
        critChance - critFromIntellect - critRatingBonus
    if transient >= 99.5 and transient <= 100.5 then
        return math.max(0, critChance - 100), true
    end
    return critChance, false
end

local function GetRating(constantName)
    local id = _G[constantName]
    if not id then return 0, 0 end
    local rating = Advisor.SafeCall(GetCombatRating, id)
    local bonus = Advisor.SafeCall(GetCombatRatingBonus, id)
    return tonumber(rating) or 0, tonumber(bonus) or 0
end

local function GetFirstRating(...)
    for index = 1, select("#", ...) do
        local name = select(index, ...)
        if _G[name] then
            local rating, bonus = GetRating(name)
            return rating, bonus, name
        end
    end
    return 0, 0, nil
end

local function GetResistances()
    local total = 0
    for school = 1, 6 do
        local _, resistance = Advisor.SafeCall(UnitResistance, "player", school)
        total = total + (tonumber(resistance) or 0)
    end
    return total
end

local function ScanEquipment()
    local equipment = {}
    local totals = {}
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local parsed = Advisor.TooltipParser.ScanInventorySlot(slot)
            local name, _, quality, itemLevel, requiredLevel, itemType,
                itemSubType, _, equipLoc = Advisor.SafeCall(GetItemInfo, link)
            equipment[slot] = {
                slot = slot,
                name = name,
                link = link,
                quality = quality,
                itemLevel = itemLevel,
                requiredLevel = requiredLevel,
                itemType = itemType,
                itemSubType = itemSubType,
                equipLoc = equipLoc,
                stats = parsed.stats,
                source = parsed.source,
                unknownEffects = parsed.unknownEffects,
                recognizedEffects = parsed.recognizedEffects,
            }
            Advisor.AddStats(totals, parsed.stats)
        end
    end
    return equipment, totals
end

function Scanner.Scan(reason)
    local _, classToken = UnitClass("player")
    local activeSpec = Advisor.SafeCall(GetSpecialization)
    local specID, specName, specDescription, specIcon, specRole, specClass
    if activeSpec and type(GetSpecializationInfoByID) == "function" then
        specID, specName, specDescription, specIcon, specRole, specClass =
            Advisor.SafeCall(GetSpecializationInfoByID, activeSpec)
    end

    local equipment, itemTotals = ScanEquipment()
    local hasteRating, hasteBonus = GetRating("CR_HASTE_SPELL")
    local critRating, critRatingBonus = GetRating("CR_CRIT_SPELL")
    local rangedHasteRating, rangedHasteBonus =
        GetFirstRating("CR_HASTE_RANGED", "CR_HASTE")
    local rangedCritRating, rangedCritRatingBonus =
        GetFirstRating("CR_CRIT_RANGED", "CR_CRIT_MELEE")
    local rangedHitRating, rangedHitBonus =
        GetFirstRating("CR_HIT_RANGED", "CR_HIT_MELEE")
    local armorPenetrationRating, armorPenetrationBonus =
        GetFirstRating("CR_ARMOR_PENETRATION")
    local resilienceRating = 0
    if itemTotals.resilience then resilienceRating = itemTotals.resilience end

    local regen, regenCasting = Advisor.SafeCall(GetManaRegen)
    local armorBase, armorEffective = Advisor.SafeCall(UnitArmor, "player")
    local critChance = Advisor.SafeCall(GetSpellCritChance, 2)
    local critFromIntellect =
        Advisor.SafeCall(_G.GetSpellCritChanceFromIntellect, "player")
    local critWasNormalized
    critChance, critWasNormalized = NormalizeTransientCrit(
        critChance,
        critFromIntellect,
        critRatingBonus
    )
    local attackBase, attackPositive, attackNegative =
        Advisor.SafeCall(UnitAttackPower, "player")
    local rangedAPBase, rangedAPPositive, rangedAPNegative =
        Advisor.SafeCall(UnitRangedAttackPower, "player")
    local rangedSpeed, rangedMinimum, rangedMaximum, rangedPositive,
        rangedNegative, rangedPercent =
        Advisor.SafeCall(UnitRangedDamage, "player")
    local activePowerID, activePowerToken =
        Advisor.SafeCall(UnitPowerType, "player")
    local activePower = Advisor.SafeCall(
        UnitPower, "player", activePowerID or 0
    )
    local activePowerMax = Advisor.SafeCall(
        UnitPowerMax, "player", activePowerID or 0
    )
    local rangedWeapon = equipment[18]

    local snapshot = {
        reason = reason or "manual",
        capturedAt = Advisor.Now(),
        level = UnitLevel("player"),
        classToken = classToken,
        specialization = {
            active = activeSpec,
            id = specID,
            name = specName,
            description = specDescription,
            icon = specIcon,
            role = specRole,
            class = specClass,
        },
        strength = Advisor.GetUnitStat(1),
        agility = Advisor.GetUnitStat(2),
        stamina = Advisor.GetUnitStat(3),
        intellect = Advisor.GetUnitStat(4),
        spirit = Advisor.GetUnitStat(5),
        health = UnitHealth("player"),
        healthMax = UnitHealthMax("player"),
        mana = Advisor.SafeCall(UnitMana, "player") or
            Advisor.SafeCall(UnitPower, "player", 0),
        manaMax = Advisor.SafeCall(UnitManaMax, "player") or
            Advisor.SafeCall(UnitPowerMax, "player", 0),
        spellPower = GetSpellDamage(),
        healing = Advisor.SafeCall(GetSpellBonusHealing) or 0,
        critChance = tonumber(critChance) or 0,
        critTransientNormalized = critWasNormalized,
        critFromIntellect = tonumber(critFromIntellect),
        hasteRating = hasteRating,
        hasteBonus = hasteBonus,
        critRating = critRating,
        critRatingBonus = critRatingBonus,
        rangedHasteRating = rangedHasteRating,
        rangedHasteBonus = rangedHasteBonus,
        rangedCritRating = rangedCritRating,
        rangedCritRatingBonus = rangedCritRatingBonus,
        rangedHitRating = rangedHitRating,
        rangedHitBonus = rangedHitBonus,
        armorPenetrationRating = armorPenetrationRating,
        armorPenetrationBonus = armorPenetrationBonus,
        resilienceRating = resilienceRating,
        manaRegen = tonumber(regen) or 0,
        manaRegenCasting = tonumber(regenCasting) or 0,
        armor = tonumber(armorEffective) or tonumber(armorBase) or 0,
        resistances = GetResistances(),
        dodge = tonumber(Advisor.SafeCall(GetDodgeChance)) or 0,
        parry = tonumber(Advisor.SafeCall(GetParryChance)) or 0,
        attackPower =
            (tonumber(attackBase) or 0) +
            (tonumber(attackPositive) or 0) +
            (tonumber(attackNegative) or 0),
        rangedAttackPower =
            (tonumber(rangedAPBase) or 0) +
            (tonumber(rangedAPPositive) or 0) +
            (tonumber(rangedAPNegative) or 0),
        rangedAttackPowerParts = {
            base = tonumber(rangedAPBase) or 0,
            positive = tonumber(rangedAPPositive) or 0,
            negative = tonumber(rangedAPNegative) or 0,
        },
        rangedDamage = {
            speed = tonumber(rangedSpeed) or 0,
            minimum = tonumber(rangedMinimum) or 0,
            maximum = tonumber(rangedMaximum) or 0,
            positive = tonumber(rangedPositive) or 0,
            negative = tonumber(rangedNegative) or 0,
            percent = tonumber(rangedPercent) or 1,
            weaponDPS = rangedWeapon and
                tonumber(rangedWeapon.stats.weaponDPS) or 0,
            weaponMin = rangedWeapon and
                tonumber(rangedWeapon.stats.weaponMin) or 0,
            weaponMax = rangedWeapon and
                tonumber(rangedWeapon.stats.weaponMax) or 0,
            weaponSpeed = rangedWeapon and
                tonumber(rangedWeapon.stats.weaponSpeed) or 0,
        },
        rangedCritChance =
            tonumber(Advisor.SafeCall(GetRangedCritChance)) or 0,
        armorPenetration =
            tonumber(Advisor.SafeCall(GetArmorPenetration)) or 0,
        power = {
            id = activePowerID,
            token = activePowerToken,
            current = tonumber(activePower) or 0,
            maximum = tonumber(activePowerMax) or 0,
        },
        equipment = equipment,
        itemTotals = itemTotals,
    }

    Scanner.current = snapshot
    if CoAAnalyticsAdvisorDB then
        CoAAnalyticsAdvisorDB.lastCharacter = snapshot
    end
    return snapshot
end

function Scanner.Get()
    return Scanner.current or Scanner.Scan("lazy")
end

function Scanner.UpdateEquipmentItem(itemLink, parsed)
    local current = Scanner.current
    if not current or not itemLink or not parsed then return false end
    local updated = false
    for _, item in pairs(current.equipment or {}) do
        if item.link == itemLink then
            Advisor.AddStats(current.itemTotals, item.stats, -1)
            item.stats = Advisor.CopyStats(parsed.stats)
            item.source = parsed.source
            item.unknownEffects = parsed.unknownEffects or {}
            item.recognizedEffects = parsed.recognizedEffects or {}
            Advisor.AddStats(current.itemTotals, item.stats)
            updated = true
        end
    end
    return updated
end
