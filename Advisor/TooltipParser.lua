local Advisor = _G.CoAAnalyticsAdvisor

local scanTooltip = CreateFrame(
    "GameTooltip",
    "CoAAnalyticsAdvisorScanTooltip",
    UIParent,
    "GameTooltipTemplate"
)
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
scanTooltip:SetAlpha(0)

Advisor.TooltipParser = {}
local Parser = Advisor.TooltipParser

local resistanceNames = {
    arcane = true, fire = true, frost = true, nature = true,
    shadow = true, holy = true,
}

local primaryStatKeys = {
    "strength", "agility", "spirit", "intellect", "stamina",
}

local function Add(stats, key, value)
    value = tonumber(value)
    if value then stats[key] = (stats[key] or 0) + value end
end

local function NormalizeLine(value)
    value = tostring(value or "")
    value = string.gsub(value, "|c%x%x%x%x%x%x%x%x", "")
    value = string.gsub(value, "|r", "")
    return value
end

local function IsSetBonusLine(line)
    return string.match(line, "^%s*%(%d+%)%s*set%s*:") or
        string.match(line, "^%s*set%s*:")
end

local function IsActiveSetBonus(pair)
    local red = tonumber(pair and pair.leftR)
    local green = tonumber(pair and pair.leftG)
    local blue = tonumber(pair and pair.leftB)
    if not red or not green or not blue then return false end
    return green > red + 0.12 and green > blue + 0.12
end

local function ParseCooldownSeconds(line)
    local minutes, seconds = string.match(
        line,
        "%(([%d%.]+)%s*min%s+([%d%.]+)%s*sec%s+cooldown%)"
    )
    if minutes and seconds then
        return tonumber(minutes) * 60 + tonumber(seconds)
    end
    local value, unit = string.match(
        line,
        "%(([%d%.]+)%s*(%a+)%s+cooldown%)"
    )
    value = tonumber(value)
    unit = string.lower(tostring(unit or ""))
    if not value then return nil end
    if string.find(unit, "min", 1, true) then return value * 60 end
    if string.find(unit, "sec", 1, true) then return value end
    return nil
end

local function HasRecognizedEffect(result, kind)
    for _, effect in ipairs(result.recognizedEffects or {}) do
        if effect.kind == kind then return true end
    end
    return false
end

local function AddSpellPowerOnUse(
    result,
    amount,
    durationSeconds,
    cooldownSeconds,
    line,
    source
)
    amount = tonumber(amount)
    durationSeconds = tonumber(durationSeconds)
    cooldownSeconds = tonumber(cooldownSeconds)
    if not amount or not durationSeconds or not cooldownSeconds or
        durationSeconds <= 0 or cooldownSeconds <= 0 or
        HasRecognizedEffect(result, "spellPowerOnUse") then
        return false
    end
    local average = amount * math.min(1, durationSeconds / cooldownSeconds)
    Add(result.stats, "onUseSpellPowerAverage", average)
    result.recognizedEffects[#result.recognizedEffects + 1] = {
        kind = "spellPowerOnUse",
        amount = amount,
        durationSeconds = durationSeconds,
        cooldownSeconds = cooldownSeconds,
        averageSpellPower = average,
        line = line,
        source = source or "tooltip",
    }
    return true
end

local function ApplyKnownItemEffects(result, itemLink)
    local itemID = tonumber(string.match(tostring(itemLink or ""), "item:(%d+)"))
    -- Le client 3.3.5 omet parfois la ligne Use du Draconic Infused
    -- Emblem lors d'un scan d'emplacement, malgré sa présence au survol.
    if itemID == 222268 then
        AddSpellPowerOnUse(
            result,
            105,
            15,
            75,
            "Use: Increases your spell power by 105 for 15 sec. (1 Min 15 Sec Cooldown)",
            "verified-tooltip"
        )
    end
    return result
end

function Parser.ParseLines(lines)
    local result = {
        stats = {},
        unknownEffects = {},
        recognizedEffects = {},
        setBonusLines = {},
        lines = lines or {},
        source = "tooltip",
    }

    for _, pair in ipairs(lines or {}) do
        local original = NormalizeLine(pair.left)
        local line = string.lower(original)
        local number

        local mythicRank = string.match(line, "^mythic%s+(%d+)%s*$")
        if mythicRank then
            result.isMythic = true
            result.mythicRank = tonumber(mythicRank) or 0
        elseif string.match(line, "^mythic%s+dungeon%s*$") then
            result.isMythic = true
            result.mythicRank = 0
        end

        -- Comparison tooltips append a synthetic stat-delta block after the
        -- real equipped item. Those lines are not item stats and must never
        -- enter the equipment cache. Stop before both Blizzard's comparison
        -- block and our own previously appended advice.
        if string.find(
            line,
            "if you replace this item",
            1,
            true
        ) or string.find(
            line,
            "the following stat changes will occur",
            1,
            true
        ) or string.find(line, "coa advisor", 1, true) then
            break
        end

        -- Un tooltip de pièce de set répète tous les bonus du set. Ces lignes
        -- ne sont pas des statistiques propres à l'objet et les compter ici
        -- inventerait une perte à chaque remplacement. Les bonus actifs sont
        -- conservés comme effets non évalués pour imposer une revue manuelle.
        local setBonusLine = IsSetBonusLine(line)
        if setBonusLine then
            result.setBonusLines[#result.setBonusLines + 1] = original
            if IsActiveSetBonus(pair) then
                result.unknownEffects[#result.unknownEffects + 1] =
                    "Active set bonus not scored: " .. original
            end
        end

        if not setBonusLine then
        local recognizedActiveEffect = false
        number = string.match(line, "^%+(%d+)%s+strength")
        if number then Add(result.stats, "strength", number) end

        number = string.match(line, "^%+(%d+)%s+agility")
        if number then Add(result.stats, "agility", number) end

        number = string.match(line, "^%+(%d+)%s+spirit")
        if number then Add(result.stats, "spirit", number) end

        number = string.match(line, "^%+(%d+)%s+intellect")
        if number then Add(result.stats, "intellect", number) end

        number = string.match(line, "^%+(%d+)%s+stamina")
        if number then Add(result.stats, "stamina", number) end

        number = string.match(line, "increases spell power by (%d+)")
        if string.match(line, "^use:") then number = nil end
        if number then Add(result.stats, "spellPower", number) end

        -- Certains objets CoA conservent l'ancien couple TBC : puissance des
        -- sorts commune + bonus de soins supplémentaire. Ce bonus n'est pas
        -- inclus dans la ligne "spell power" du tooltip et doit donc être
        -- compté séparément (ex. Glowing Thorium Band of the Physician).
        number = string.match(line, "^%+(%d+)%s+spell healing")
        if not number then
            number = string.match(line, "^%+(%d+)%s+healing")
        end
        if number then Add(result.stats, "bonusHealing", number) end

        number = string.match(line, "increases healing done.-by up to (%d+)")
        if number and not result.stats.spellPower then
            Add(result.stats, "spellPower", number)
        end

        number = string.match(line, "increases ranged attack power by (%d+)")
        if not number then
            number = string.match(line, "increases attack power by (%d+)")
        end
        if not number then number = string.match(line, "^%+(%d+)%s+attack power") end
        if number then Add(result.stats, "attackPower", number) end

        number = string.match(line, "haste rating by (%d+)")
        if not number then number = string.match(line, "^%+(%d+)%s+haste rating") end
        if number then Add(result.stats, "haste", number) end

        number = string.match(line, "critical strike rating by (%d+)")
        if not number then
            number = string.match(line, "^%+(%d+)%s+critical strike rating")
        end
        if number then Add(result.stats, "crit", number) end

        number = string.match(line, "hit rating by (%d+)")
        if not number then number = string.match(line, "^%+(%d+)%s+hit rating") end
        if number then Add(result.stats, "hit", number) end

        number = string.match(line, "expertise rating by (%d+)")
        if not number then
            number = string.match(line, "^%+(%d+)%s+expertise rating")
        end
        if number then Add(result.stats, "expertise", number) end

        number = string.match(line, "defense rating by (%d+)")
        if not number then
            number = string.match(line, "^%+(%d+)%s+defense rating")
        end
        if number then Add(result.stats, "defense", number) end

        number = string.match(line, "dodge rating by (%d+)")
        if not number then
            number = string.match(line, "^%+(%d+)%s+dodge rating")
        end
        if number then Add(result.stats, "dodge", number) end

        number = string.match(line, "parry rating by (%d+)")
        if not number then
            number = string.match(line, "^%+(%d+)%s+parry rating")
        end
        if number then Add(result.stats, "parry", number) end

        number = string.match(line, "block rating by (%d+)")
        if not number then
            number = string.match(line, "^%+(%d+)%s+block rating")
        end
        if number then Add(result.stats, "block", number) end

        number = string.match(line, "increases the block value of your shield by (%d+)")
        if number then Add(result.stats, "block", number) end

        number = string.match(line, "armor penetration rating by (%d+)")
        if not number then
            number = string.match(line, "^%+(%d+)%s+armor penetration")
        end
        if number then Add(result.stats, "armorPenetration", number) end

        -- Spell penetration is a regular item statistic, not an unknown proc.
        -- It has no healing value for Chronomancer Time, but it still needs to
        -- be parsed so replacing an item carrying it does not force a manual
        -- review (for example Skullsmoke Pants).
        number = string.match(line, "spell penetration by (%d+)")
        if not number then
            number = string.match(line, "^%+(%d+)%s+spell penetration")
        end
        if number then Add(result.stats, "spellPenetration", number) end

        number = string.match(line, "resilience rating by (%d+)")
        if not number then number = string.match(line, "^%+(%d+)%s+resilience") end
        if number then Add(result.stats, "resilience", number) end

        number = string.match(line, "increases pve power by (%d+)")
        if not number then number = string.match(line, "^%+(%d+)%s+pve power") end
        if number then Add(result.stats, "pvePower", number) end

        number = string.match(line, "increases pvp power by (%d+)")
        if not number then number = string.match(line, "^%+(%d+)%s+pvp power") end
        if number then Add(result.stats, "pvpPower", number) end

        number = string.match(line, "restores (%d+) mana per 5 sec")
        if number then Add(result.stats, "mp5", number) end

        number = string.match(line, "restores (%d+) health per 5 sec")
        if number then Add(result.stats, "hp5", number) end

        local restoredMana =
            string.match(line, "^use:%s*restores%s+(%d+)%s+mana")
        local cooldownSeconds = restoredMana and
            ParseCooldownSeconds(line) or nil
        if restoredMana and cooldownSeconds and cooldownSeconds > 0 then
            restoredMana = tonumber(restoredMana)
            local manaPer120 =
                restoredMana * 120 / cooldownSeconds
            Add(result.stats, "manaRestorePer120", manaPer120)
            result.recognizedEffects[#result.recognizedEffects + 1] = {
                kind = "manaRestore",
                amount = restoredMana,
                cooldownSeconds = cooldownSeconds,
                manaPer120 = manaPer120,
                line = original,
            }
            recognizedActiveEffect = true
        end

        local onUseSpellPower, onUseDuration = string.match(
            line,
            "^use:%s*increases%s+.-spell power by%s+(%d+)%s+for%s+([%d%.]+)%s+sec"
        )
        local onUseCooldown = onUseSpellPower and
            ParseCooldownSeconds(line) or nil
        if AddSpellPowerOnUse(
            result,
            onUseSpellPower,
            onUseDuration,
            onUseCooldown,
            original,
            "tooltip"
        ) then
            recognizedActiveEffect = true
        end

        -- Circle of Flame et quelques objets anciens convertissent une
        -- quantité explicite de vie en la même quantité de mana à intervalle
        -- fixe. La valeur sur 120 s peut être calculée sans inventer de proc.
        local healthToMana, tickSeconds, durationSeconds = string.match(
            line,
            "^use:%s*channels%s+(%d+)%s+health%s+into%s+mana%s+every%s+([%d%.]+)%s+sec%s+for%s+([%d%.]+)%s+sec"
        )
        local conversionCooldown = healthToMana and
            ParseCooldownSeconds(line) or nil
        if healthToMana and tickSeconds and durationSeconds and
            conversionCooldown and conversionCooldown > 0 then
            healthToMana = tonumber(healthToMana)
            tickSeconds = tonumber(tickSeconds)
            durationSeconds = tonumber(durationSeconds)
            if tickSeconds and tickSeconds > 0 then
                local restored =
                    healthToMana * durationSeconds / tickSeconds
                local manaPer120 =
                    restored * 120 / conversionCooldown
                Add(result.stats, "manaRestorePer120", manaPer120)
                result.recognizedEffects[#result.recognizedEffects + 1] = {
                    kind = "manaRestore",
                    amount = restored,
                    healthCost = restored,
                    cooldownSeconds = conversionCooldown,
                    manaPer120 = manaPer120,
                    line = original,
                }
                recognizedActiveEffect = true
            end
        end

        if string.match(
            line,
            "^equip:%s*run speed increased slightly"
        ) then
            local percent =
                Advisor.Data.effectValues.slightRunSpeedPercent or 8
            Add(result.stats, "movementSpeed", percent)
            result.recognizedEffects[#result.recognizedEffects + 1] = {
                kind = "runSpeed",
                effectKey = "run_speed_slight",
                percent = percent,
                line = original,
                source = "DataProbe",
            }
            recognizedActiveEffect = true
        end

        -- This deterministic utility effect is fully described by the
        -- tooltip. It is context-dependent rather than unknown: useful
        -- against silences/interrupts, but it must not invent throughput.
        local silenceInterruptReduction = string.match(
            line,
            "^equip:%s*reduces the duration of any silence or interrupt effects used against the wearer by ([%d%.]+)%%"
        )
        if silenceInterruptReduction then
            result.recognizedEffects[#result.recognizedEffects + 1] = {
                kind = "silenceInterruptReduction",
                effectKey = "silence_interrupt_duration_reduction",
                percent = tonumber(silenceInterruptReduction),
                line = original,
            }
            recognizedActiveEffect = true
        end

        -- The Satin glove bonus only modifies Mind Blast pushback. It is a
        -- deterministic class-specific effect, not an unknown proc. Neither
        -- currently scored model (Time healer or Ranger Archery) uses it.
        if string.match(
            line,
            "^equip:%s*gives you a [%d]+%% chance to avoid interruption.-mind blast"
        ) then
            result.recognizedEffects[#result.recognizedEffects + 1] = {
                kind = "classSpecific",
                ability = "Mind Blast",
                line = original,
            }
            recognizedActiveEffect = true
        end

        number = string.match(line, "^(%d+)%s+armor")
        if number then Add(result.stats, "armor", number) end

        local minimumDamage, maximumDamage =
            string.match(line, "^(%d+)%s*%-%s*(%d+)%s+damage")
        if minimumDamage and maximumDamage then
            result.stats.weaponMin = tonumber(minimumDamage)
            result.stats.weaponMax = tonumber(maximumDamage)
            local speed = NormalizeLine(pair.right)
            speed = string.match(string.lower(speed), "speed%s+([%d%.]+)")
            if speed then result.stats.weaponSpeed = tonumber(speed) end
        end

        number = string.match(line, "%(([%d%.]+)%s+damage per second%)")
        if number then Add(result.stats, "weaponDPS", number) end

        local resistValue, resistName =
            string.match(line, "^%+(%d+)%s+(%a+)%s+resistance")
        if resistValue and resistanceNames[resistName] then
            Add(result.stats, "resistance", resistValue)
        end

        if string.match(line, "^equip:") or string.match(line, "^use:") then
            local recognized =
                recognizedActiveEffect or
                string.find(line, "spell power", 1, true) or
                string.find(line, "attack power", 1, true) or
                string.find(line, "haste rating", 1, true) or
                string.find(line, "critical strike rating", 1, true) or
                string.find(line, "hit rating", 1, true) or
                string.find(line, "expertise rating", 1, true) or
                string.find(line, "defense rating", 1, true) or
                string.find(line, "dodge rating", 1, true) or
                string.find(line, "parry rating", 1, true) or
                string.find(line, "block rating", 1, true) or
                string.find(line, "block value", 1, true) or
                string.find(line, "armor penetration", 1, true) or
                string.find(line, "spell penetration", 1, true) or
                string.find(line, "resilience rating", 1, true) or
                string.find(line, "pve power", 1, true) or
                string.find(line, "pvp power", 1, true) or
                string.find(line, "mana per 5 sec", 1, true) or
                string.find(line, "health per 5 sec", 1, true)
            if not recognized then
                result.unknownEffects[#result.unknownEffects + 1] = original
            end
        end
        end
    end
    return result
end

function Parser.FromAPI(itemLink)
    local parsed = {
        stats = {},
        unknownEffects = {},
        recognizedEffects = {},
        setBonusLines = {},
        lines = {},
        source = "api-fallback",
    }
    local rawStats = Advisor.SafeCall(GetItemStats, itemLink)
    if type(rawStats) == "table" then
        for key, value in pairs(rawStats) do
            local normalized = Advisor.Data.statKeys[key]
            if normalized and type(value) == "number" then
                parsed.stats[normalized] =
                    (parsed.stats[normalized] or 0) + value
            end
        end

        -- Sur les objets utilisant les anciennes statistiques séparées,
        -- HEALING_DONE contient le total destiné aux soins tandis que
        -- DAMAGE_DONE contient la partie commune. Leur différence est le
        -- bonus de soins pur. On évite ainsi de compter deux fois le SP.
        local apiSpellPower = tonumber(
            rawStats.ITEM_MOD_SPELL_POWER_SHORT or
            rawStats.ITEM_MOD_SPELL_DAMAGE_DONE_SHORT
        ) or 0
        local apiHealing = tonumber(
            rawStats.ITEM_MOD_SPELL_HEALING_DONE_SHORT
        ) or 0
        if not parsed.stats.spellPower and apiSpellPower > 0 then
            parsed.stats.spellPower = apiSpellPower
        end
        if apiHealing > apiSpellPower then
            parsed.stats.bonusHealing = apiHealing - apiSpellPower
        end
    end
    return ApplyKnownItemEffects(parsed, itemLink)
end

local function FillMissingPrimaryStats(parsed, itemLink)
    if not itemLink then return parsed end
    local api = Parser.FromAPI(itemLink)
    local filled = false
    for _, key in ipairs(primaryStatKeys) do
        if parsed.stats[key] == nil and api.stats[key] ~= nil then
            parsed.stats[key] = api.stats[key]
            filled = true
        end
    end
    if filled then parsed.apiPrimaryFallback = true end
    return parsed
end

function Parser.FromTooltip(tooltip, itemLink)
    local parsed = Parser.ParseLines(Advisor.GetTooltipLines(tooltip))
    if not itemLink and tooltip and type(tooltip.GetItem) == "function" then
        local _, tooltipLink = Advisor.SafeCall(tooltip.GetItem, tooltip)
        itemLink = tooltipLink
    end
    parsed = FillMissingPrimaryStats(parsed, itemLink)
    return ApplyKnownItemEffects(parsed, itemLink)
end

function Parser.ScanInventorySlot(slot)
    local link = GetInventoryItemLink("player", slot)
    scanTooltip:ClearLines()
    scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    local ok = pcall(scanTooltip.SetInventoryItem, scanTooltip, "player", slot)
    if ok then
        scanTooltip:Show()
        local parsed = Parser.FromTooltip(scanTooltip, link)
        scanTooltip:Hide()
        if #parsed.lines > 0 then return parsed end
    end

    return link and Parser.FromAPI(link) or {
        stats = {},
        unknownEffects = {},
        recognizedEffects = {},
        setBonusLines = {},
        lines = {},
        source = "none",
    }
end
