local Advisor = _G.CoAAnalyticsAdvisor

Advisor.Data = {
    profiles = {
        bg = {
            label = "Time BG équilibré",
            shortLabel = "BG équilibré",
            healing = 0.45,
            sustain = 0.30,
            survival = 0.25,
            talent = {
                throughput = 0.30,
                sustain = 0.35,
                survival = 0.25,
                utility = 0.10,
            },
        },
        throughput = {
            label = "Time soins maximum",
            shortLabel = "Soins maximum",
            healing = 0.75,
            sustain = 0.15,
            survival = 0.10,
            talent = {
                throughput = 0.70,
                sustain = 0.10,
                survival = 0.10,
                utility = 0.10,
            },
        },
        sustain = {
            label = "Time autonomie mana",
            shortLabel = "Autonomie mana",
            healing = 0.35,
            sustain = 0.55,
            survival = 0.10,
            talent = {
                throughput = 0.25,
                sustain = 0.60,
                survival = 0.05,
                utility = 0.10,
            },
        },
        survival = {
            label = "Time survie BG",
            shortLabel = "Survie BG",
            healing = 0.30,
            sustain = 0.15,
            survival = 0.55,
            talent = {
                throughput = 0.20,
                sustain = 0.15,
                survival = 0.55,
                utility = 0.10,
            },
        },
    },

    timePveProfiles = {
        bg = {
            label = "Time PvE équilibré",
            shortLabel = "PvE équilibré",
            healing = 0.60,
            sustain = 0.40,
            survival = 0,
            talent = {
                throughput = 0.55,
                sustain = 0.30,
                survival = 0.05,
                utility = 0.10,
            },
        },
        throughput = {
            label = "Time PvE soins maximum",
            shortLabel = "Soins maximum",
            healing = 0.85,
            sustain = 0.15,
            survival = 0,
            talent = {
                throughput = 0.80,
                sustain = 0.10,
                survival = 0.02,
                utility = 0.08,
            },
        },
        sustain = {
            label = "Time PvE autonomie mana",
            shortLabel = "Autonomie mana",
            healing = 0.35,
            sustain = 0.65,
            survival = 0,
            talent = {
                throughput = 0.30,
                sustain = 0.60,
                survival = 0.02,
                utility = 0.08,
            },
        },
        survival = {
            label = "Time progression PvE",
            shortLabel = "Progression PvE",
            healing = 0.50,
            sustain = 0.30,
            survival = 0.20,
            talent = {
                throughput = 0.40,
                sustain = 0.25,
                survival = 0.25,
                utility = 0.10,
            },
        },
    },

    equipSlots = {
        INVTYPE_HEAD = { 1 },
        INVTYPE_NECK = { 2 },
        INVTYPE_SHOULDER = { 3 },
        INVTYPE_BODY = { 4 },
        INVTYPE_CHEST = { 5 },
        INVTYPE_ROBE = { 5 },
        INVTYPE_WAIST = { 6 },
        INVTYPE_LEGS = { 7 },
        INVTYPE_FEET = { 8 },
        INVTYPE_WRIST = { 9 },
        INVTYPE_HAND = { 10 },
        INVTYPE_FINGER = { 11, 12 },
        INVTYPE_TRINKET = { 13, 14 },
        INVTYPE_CLOAK = { 15 },
        INVTYPE_WEAPON = { 16 },
        INVTYPE_WEAPONMAINHAND = { 16 },
        INVTYPE_2HWEAPON = { 16, 17 },
        INVTYPE_WEAPONOFFHAND = { 17 },
        INVTYPE_HOLDABLE = { 17 },
        INVTYPE_SHIELD = { 17 },
        INVTYPE_RANGED = { 18 },
        INVTYPE_RANGEDRIGHT = { 18 },
        INVTYPE_THROWN = { 18 },
        INVTYPE_RELIC = { 18 },
        INVTYPE_TABARD = { 19 },
    },

    slotNames = {
        [1] = "Head", [2] = "Neck", [3] = "Shoulders", [4] = "Shirt",
        [5] = "Chest", [6] = "Waist", [7] = "Legs", [8] = "Feet",
        [9] = "Wrist", [10] = "Hands", [11] = "Ring 1", [12] = "Ring 2",
        [13] = "Trinket 1", [14] = "Trinket 2", [15] = "Back",
        [16] = "Main Hand", [17] = "Off Hand", [18] = "Ranged",
        [19] = "Tabard",
    },

    statKeys = {
        ITEM_MOD_STRENGTH_SHORT = "strength",
        ITEM_MOD_AGILITY_SHORT = "agility",
        ITEM_MOD_SPIRIT_SHORT = "spirit",
        ITEM_MOD_INTELLECT_SHORT = "intellect",
        ITEM_MOD_STAMINA_SHORT = "stamina",
        ITEM_MOD_ATTACK_POWER_SHORT = "attackPower",
        ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "attackPower",
        ITEM_MOD_SPELL_POWER_SHORT = "spellPower",
        ITEM_MOD_HASTE_RATING_SHORT = "haste",
        ITEM_MOD_CRIT_RATING_SHORT = "crit",
        ITEM_MOD_CRITICAL_STRIKE_RATING_SHORT = "crit",
        ITEM_MOD_HIT_RATING_SHORT = "hit",
        ITEM_MOD_EXPERTISE_RATING_SHORT = "expertise",
        ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "defense",
        ITEM_MOD_DODGE_RATING_SHORT = "dodge",
        ITEM_MOD_PARRY_RATING_SHORT = "parry",
        ITEM_MOD_BLOCK_RATING_SHORT = "block",
        ITEM_MOD_BLOCK_VALUE_SHORT = "block",
        ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "armorPenetration",
        ITEM_MOD_SPELL_PENETRATION_SHORT = "spellPenetration",
        ITEM_MOD_RESILIENCE_RATING_SHORT = "resilience",
        PVE_POWER = "pvePower",
        PVP_POWER = "pvpPower",
        ITEM_MOD_POWER_REGEN0_SHORT = "mp5",
        ITEM_MOD_HEALTH_REGEN_SHORT = "hp5",
        ITEM_MOD_HEALTH_REGENERATION_SHORT = "hp5",
        ITEM_MOD_HEALTH_REGEN_IN_COMBAT_SHORT = "hp5",
        ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "weaponDPS",
        RESISTANCE0_NAME = "armor",
        RESISTANCE1_NAME = "resistance",
        RESISTANCE2_NAME = "resistance",
        RESISTANCE3_NAME = "resistance",
        RESISTANCE4_NAME = "resistance",
        RESISTANCE5_NAME = "resistance",
        RESISTANCE6_NAME = "resistance",
    },

    effectValues = {
        -- Mesuré dans les échantillons DataProbe Time : vitesse normale 7,00,
        -- vitesse la plus fréquente avec Highlander's Cloth Boots 7,56.
        slightRunSpeedPercent = 8,
        -- Ascension documents 10 PvP Power as 1% output against players.
        -- PvE Power is the parallel max-level stat for damage/healing done
        -- and damage reduction. DataProbe keeps these values separate so a
        -- PvP piece cannot improve a PvE recommendation or vice versa.
        pvpPowerPerPercent = 10,
        -- Current community measurements around the 495-point cap report
        -- separate PvE scales: ~0.05% damage, ~0.02% healing/absorbs and
        -- ~0.07% damage reduction per point. Keep each role separate.
        pveDamagePowerPerPercent = 20,
        pveHealingPowerPerPercent = 50,
        pveDefensePowerPerPercent = 14.285714,
        pvePowerMinimumLevel = 60,
    },

    spellNameOverrides = {
        [520164] = "Luck",
        [706085] = "Perfect Timing",
        [92119] = "Unknown Time ability",
    },

    talentRules = {
        ["Rippling Power"] = {
            throughput = 9.5, sustain = 8.5, survival = 0, utility = 0,
            reason = "Le Spirit augmente les soins et la régénération de mana.",
        },
        ["Sands of Life"] = {
            throughput = 10, sustain = 0, survival = 0, utility = 0,
            reason = "Convertit directement le Spirit en puissance de soin.",
        },
        ["Luck"] = {
            throughput = 0, sustain = 10, survival = 2, utility = 0,
            reason = "Conserve davantage de régénération pendant les incantations.",
        },
        ["Temporal Restoration"] = {
            throughput = 0, sustain = 10, survival = 2, utility = 0,
            reason = "Améliore la régénération de mana en combat.",
        },
        ["Time Wizard"] = {
            throughput = 9.5, sustain = 0, survival = 0, utility = 1,
            reason = "Ajoute du critique aux principaux soins Time.",
        },
        ["Perfect Timing"] = {
            throughput = 8.5, sustain = 1, survival = 1, utility = 4,
            reason = "La hâte accélère les soins et réduit le recul d’incantation.",
        },
        ["Quickcaster"] = {
            throughput = 8.5, sustain = 0, survival = 1, utility = 3,
            reason = "La hâte améliore la réactivité et le rendement des soins.",
        },
        ["Impeccable Timing"] = {
            throughput = 8, sustain = 0, survival = 0, utility = 1,
            reason = "Permet aux soins périodiques de devenir critiques.",
        },
        ["Improved Reverse Wound"] = {
            throughput = 8.5, sustain = 1, survival = 0, utility = 2,
            reason = "Accélère le principal soin direct.",
        },
        ["Not Even A Scratch"] = {
            throughput = 9, sustain = 0, survival = 0, utility = 0,
            reason = "Ajoute un coefficient de soin à Reverse Wound.",
        },
        ["Keep Accelerating"] = {
            throughput = 8.5, sustain = 2, survival = 0, utility = 2,
            reason = "Étend Accelerated Recovery à un allié supplémentaire.",
        },
        ["Epic Recovery"] = {
            throughput = 8.5, sustain = 1, survival = 0, utility = 2,
            reason = "Ajoute un soin Epoch aux cibles d’Accelerated Recovery.",
        },
        ["Endless Sands"] = {
            throughput = 8, sustain = 7, survival = 0, utility = 1,
            reason = "Génère la ressource utilisée par plusieurs synergies Time.",
        },
        ["Timeless"] = {
            throughput = 1, sustain = 9, survival = 0, utility = 1,
            reason = "Réduit le coût des sorts pendant Endless Sands.",
        },
        ["Carbon Dating"] = {
            throughput = 8, sustain = 1, survival = 0, utility = 1,
            reason = "Augmente le soin d’Epoch grâce à Sands of Time.",
        },
        ["Through The Aeons"] = {
            throughput = 1, sustain = 8.5, survival = 1, utility = 1,
            reason = "Améliore la mana lors de l’utilisation des Aeons.",
        },
        ["Aeon of Protection"] = {
            throughput = 7, sustain = 0, survival = 9.5, utility = 2,
            reason = "Ajoute une absorption utile contre le burst en BG.",
        },
        ["Aeon of Resilience"] = {
            throughput = 7.5, sustain = 7, survival = 4, utility = 2,
            reason = "Rend les Epoch moins coûteux et plus rapides.",
        },
        ["Aeon of Renewal"] = {
            throughput = 8, sustain = 1, survival = 3, utility = 1,
            reason = "Ajoute un soin retardé contre la pression prolongée.",
        },
        ["Shield of the Ages"] = {
            throughput = 4, sustain = 0, survival = 10, utility = 1,
            reason = "Forte protection lorsque les ennemis ciblent le soigneur.",
        },
        ["Fortify Timeline"] = {
            throughput = 8.5, sustain = 0, survival = 2, utility = 2,
            reason = "Ajoute un soin de groupe instantané et prolonge le HoT principal.",
        },
        ["Correct the Mistake"] = {
            throughput = 8.5, sustain = 0, survival = 0, utility = 1,
            reason = "Soin de groupe essentiel.",
        },
        ["Ripple"] = {
            throughput = 8.5, sustain = 0, survival = 2, utility = 2,
            reason = "Soin de zone avec immunité aux étourdissements pendant la canalisation.",
        },
        ["Unearthed Pools"] = {
            throughput = 4, sustain = 6.5, survival = 0, utility = 2,
            reason = "Réduit le coût en mana des sorts instantanés.",
        },
        ["Time Skip"] = {
            throughput = 1, sustain = 0, survival = 5, utility = 9,
            reason =
                "Renforce Roll Back avec une dissipation supplémentaire, utile dans le chemin Mythic+ vérifié.",
        },
        ["A Ripple In Time"] = {
            throughput = 7, sustain = 0, survival = 1, utility = 4,
            reason = "Les soins critiques réduisent le temps de recharge de Ripple.",
        },
    },
}

-- Les modèles sont enregistrés par classe et spécialisation. Cette couche
-- garde le cœur de l'addon générique : l'interface, les boutons et les
-- tooltips lisent toujours le profil actif au lieu de supposer une classe.
Advisor.Data.talentRules["Cadence of Time"] = {
    throughput = 8.5, sustain = 1, survival = 1, utility = 2,
    reason = "Les critiques d'Epoch renforcent fortement le prochain Ripple.",
}
Advisor.Data.talentRules["Mark of Order"] = {
    throughput = 8, sustain = 1, survival = 2, utility = 2,
    reason = "Fortify Timeline prépare un Reverse Wound nettement renforcé.",
}
Advisor.Data.talentRules["Time Beacon"] = {
    throughput = 7, sustain = 8, survival = 3.5, utility = 3,
    reason =
        "Prolonge les Aeons : soins, efficacité mana et protection supplémentaires.",
}
Advisor.Data.talentRules["Bronze Timeways"] = {
    throughput = 8.5, sustain = 4, survival = 1, utility = 2,
    reason =
        "Correct the Mistake génère Endless Sands et accélère Reverse Wound.",
}
Advisor.Data.talentRules["Continuum Restoration"] = {
    throughput = 1, sustain = 0, survival = 7.5, utility = 10,
    situational = true,
    reason =
        "Dissipation de masse puissante contre des effets magiques décisifs.",
}
Advisor.Data.talentRules["Displacement"] = {
    throughput = 1, sustain = 0, survival = 8, utility = 9.5,
    situational = true,
    reason =
        "Sauve et repositionne un allié tout en retirant roots et ralentissements.",
}
Advisor.Data.talentRules["Shimmering Shard"] = {
    throughput = 9, sustain = 2, survival = 2, utility = 1,
    reason =
        "Les Aeons accumulent un puissant bonus de dégâts et de soins.",
}
Advisor.Data.talentRules["Chronicler"] = {
    throughput = 8.5, sustain = 2, survival = 1, utility = 2,
    reason =
        "Fortify Timeline prolonge davantage Accelerated Recovery sur le groupe.",
}
Advisor.Data.talentRules["Eternity Warper"] = {
    throughput = 9, sustain = 1, survival = 4, utility = 2,
    reason =
        "Adapte Ripple à l'Aeon actif pour les soins, absorptions ou dégâts de zone.",
}
Advisor.Data.talentRules["Waves of Time"] = {
    throughput = 0, sustain = 0, survival = 5, utility = 8,
    reason =
        "Double repoussement frontal utile pour contrôler les groupes en Mythic+.",
}
Advisor.Data.talentRules["Entropy Reversal"] = {
    throughput = 0, sustain = 0, survival = 4, utility = 5,
    reason =
        "Réduit fortement la durée des maladies, un choix utilitaire du build Mythic+ vérifié.",
}
Advisor.Data.talentRules["Cycling Aeons"] = {
    throughput = 7.5, sustain = 6, survival = 3, utility = 5,
    reason =
        "Réduit le temps de recharge des Aeons et fluidifie les changements de posture.",
}
Advisor.Data.talentRules["Timeline Tether"] = {
    throughput = 8.5, sustain = 1, survival = 1, utility = 2,
    reason =
        "Les soins périodiques réduisent le temps de recharge de Fortify Timeline.",
}

-- Arbres Time complets utilisés par le surlignage de Character Advancement.
-- "core" désigne un point attendu dans le preset général ; "flex" signale
-- un point que le joueur peut déplacer selon le donjon ou la composition BG.
-- Les rangs sont volontairement stockés ici plutôt que déduits du score : un
-- score classe le prochain achat, alors qu'un build décrit l'arbre final.
Advisor.Data.timeRecommendedTalentBuilds = {
    pvp = {
        label = "Time PvP / BG",
        confidence = "medium-high",
        source = "Ascension Sidekick + historique de combats PvP local",
        talents = {
            ["Rippling Power"] = { rank = 2 },
            ["Expediting Time"] = { rank = 1 },
            ["Ahead of the Game"] = { rank = 1 },
            ["Perfect Timing"] = { rank = 1 },
            ["Fortify Timeline"] = { rank = 1 },
            ["Desynchronization"] = { rank = 1 },
            ["Improved Reverse Wound"] = { rank = 1 },
            ["Temporal Focus"] = { rank = 1, kind = "flex" },
            ["Eternal"] = { rank = 1 },
            ["Entropy Overload"] = { rank = 1 },
            ["Luck"] = { rank = 2 },
            ["Infinite Shield"] = { rank = 1 },
            ["Infinity"] = { rank = 1 },
            ["Impeccable Timing"] = { rank = 1 },
            ["Mind Over Matter"] = { rank = 1 },
            ["Clasp of Infinity"] = { rank = 1 },
            ["Temporal Anomaly"] = { rank = 1 },
            ["Timeguard"] = { rank = 1 },
            ["Constant Recovery"] = { rank = 1 },
            ["Accelerated Recovery"] = { rank = 1 },
            ["Unearthed Pools"] = { rank = 1 },
            ["Timekeeper"] = { rank = 1 },
            ["Timewalking"] = { rank = 1, kind = "flex" },
            ["Unmaker of Realities"] = { rank = 1, kind = "flex" },

            ["Time Wizard"] = { rank = 2 },
            ["Time Beacon"] = { rank = 2 },
            ["Keep Accelerating"] = { rank = 1 },
            ["Epic Recovery"] = { rank = 1 },
            ["Timeless"] = { rank = 1 },
            ["Through The Aeons"] = { rank = 1 },
            ["Carbon Dating"] = { rank = 1 },
            ["Endless Sands"] = { rank = 1 },
            ["Continuum Restoration"] = { rank = 1, kind = "flex" },
            ["Fabric of Time"] = { rank = 1 },
            ["Sands of Life"] = { rank = 2 },
            ["Correct the Mistake"] = { rank = 1 },
            ["Wonders of Time"] = { rank = 1 },
            ["Cadence of Time"] = { rank = 1 },
            ["Buy Time"] = { rank = 1 },
            ["Mark of Order"] = { rank = 1 },
            ["A Ripple In Time"] = { rank = 1 },
            ["Displacement"] = { rank = 1, kind = "flex" },
            ["Ideal Time"] = { rank = 1, kind = "flex" },
            ["Ripple"] = { rank = 1 },
            ["Overcorrection"] = { rank = 1 },
            ["Shimmering Shard"] = { rank = 1 },

            -- Les quatre Aeons sont des nœuds de spécialisation accordés par
            -- le chemin Time et peuvent apparaître comme déjà acquis.
            ["Aeon of Resilience"] = { rank = 1 },
            ["Aeon of Renewal"] = { rank = 1 },
            ["Aeon of Protection"] = { rank = 1 },
            ["Aeon of Oblivion"] = { rank = 1, kind = "flex" },
        },
    },
    pve = {
        label = "Time PvE / Mythic+",
        confidence = "high",
        source = "Guide Mythic+ post-refonte + historique de combats PvE local",
        talents = {
            ["Rippling Power"] = { rank = 2 },
            ["Expediting Time"] = { rank = 1 },
            ["Ahead of the Game"] = { rank = 1 },
            ["Perfect Timing"] = { rank = 2 },
            ["Fortify Timeline"] = { rank = 1 },
            ["Desynchronization"] = { rank = 1 },
            ["Eternal"] = { rank = 1 },
            ["Luck"] = { rank = 2 },
            ["Infinite Shield"] = { rank = 1 },
            ["Infinity"] = { rank = 1 },
            ["Impeccable Timing"] = { rank = 1 },
            ["Mind Over Matter"] = { rank = 1 },
            ["Clasp of Infinity"] = { rank = 1 },
            ["Temporal Anomaly"] = { rank = 1 },
            ["Timeguard"] = { rank = 1 },
            ["Constant Recovery"] = { rank = 1 },
            ["Accelerated Recovery"] = { rank = 1 },
            ["Unearthed Pools"] = { rank = 1 },
            ["Timekeeper"] = { rank = 1 },
            ["Timewalking"] = { rank = 1, kind = "flex" },
            ["Maker of Realities"] = { rank = 1, kind = "flex" },
            ["Waves of Time"] = { rank = 1 },
            ["Entropy Reversal"] = { rank = 1 },

            ["Time Wizard"] = { rank = 2 },
            ["Time Beacon"] = { rank = 2 },
            ["Keep Accelerating"] = { rank = 1 },
            ["Epic Recovery"] = { rank = 1 },
            ["Timeless"] = { rank = 1 },
            ["Through The Aeons"] = { rank = 1 },
            ["Carbon Dating"] = { rank = 1 },
            ["Sands of Life"] = { rank = 2 },
            ["Correct the Mistake"] = { rank = 1 },
            ["Wonders of Time"] = { rank = 1 },
            ["Cadence of Time"] = { rank = 1 },
            ["Mark of Order"] = { rank = 1 },
            ["A Ripple In Time"] = { rank = 1 },
            ["Ripple"] = { rank = 1 },
            ["Time Skip"] = { rank = 1 },
            ["Cycling Aeons"] = {
                rank = 1,
                descriptionContains = "cooldown of your Aeons by 50%",
            },
            ["Timeline Tether"] = { rank = 1 },
            ["Shimmering Shard"] = { rank = 1 },
            ["Chronicler"] = { rank = 1 },
            ["Eternity Warper"] = { rank = 1 },
            ["Aeon of Renewal"] = { rank = 1 },
            ["Aeon of Protection"] = { rank = 1 },
            ["Aeon of Resilience"] = { rank = 1 },
            ["Aeon of Oblivion"] = { rank = 1, kind = "flex" },
            ["Ideal Time"] = { rank = 1, kind = "flex" },
            ["Continuum Restoration"] = { rank = 1, kind = "flex" },
            ["Displacement"] = { rank = 1, kind = "flex" },
        },
        excluded = {
            ["Improved Reverse Wound"] = true,
            ["Endless Sands"] = true,
            ["Buy Time"] = true,
            ["Fabric of Time"] = true,
            ["Converge the Infinite"] = true,
            ["Orderly Protector"] = true,
        },
    },
}

Advisor.Data.rangerTalentRules = {
    ["Pierced"] = {
        throughput = 9.5, sustain = 2, survival = 0, utility = 0,
        reason = "Les critiques de Skullpiercer et Precision Shot ajoutent une forte blessure.",
    },
    ["Boots of Elvenkind"] = {
        throughput = 7.5, sustain = 0, survival = 7, utility = 4,
        reason = "Augmente l'Agilité et réduit les ralentissements.",
    },
    ["Hunting with Precision"] = {
        throughput = 8.5, sustain = 2, survival = 0, utility = 2,
        reason = "Renforce les tirs de précision et leurs synergies.",
    },
    ["Deadeye"] = {
        throughput = 9, sustain = 1, survival = 0, utility = 1,
        reason = "Améliore directement les tirs principaux d'Archery.",
    },
    ["Swiftshot"] = {
        throughput = 9, sustain = 1, survival = 0, utility = 2,
        reason = "Precision Shot augmente les dégâts physiques subis par la cible.",
    },
    ["Deadshot"] = {
        throughput = 9, sustain = 0, survival = 0, utility = 2,
        reason = "Excellent finisseur basé sur les dégâts de l'arme à distance.",
    },
    ["Skirmisher"] = {
        throughput = 8, sustain = 4, survival = 0, utility = 3,
        reason = "Accélère les dégâts de Toxic Dart et sa pression.",
    },
    ["Corrosive Poison"] = {
        throughput = 9, sustain = 0, survival = 0, utility = 2,
        reason = "Les techniques à distance ignorent une partie de l'armure d'une cible empoisonnée.",
    },
    ["Hunting Shot"] = {
        throughput = 8, sustain = 6, survival = 0, utility = 3,
        reason = "Dégâts de zone et génération d'Advantage.",
    },
    ["Devastating Shots"] = {
        throughput = 10, sustain = 2, survival = 0, utility = 0,
        reason = "Le critique et le toucher renforcent presque toute la rotation.",
    },
    ["New-Age Archery"] = {
        throughput = 8.5, sustain = 2, survival = 0, utility = 2,
        reason = "Renforce les techniques centrales de la spécialisation.",
    },
    ["Precision Shot"] = {
        throughput = 10, sustain = 1, survival = 0, utility = 1,
        reason = "Technique centrale : dégâts élevés et nombreuses synergies.",
    },
    ["Superb Shot"] = {
        throughput = 6, sustain = 10, survival = 0, utility = 1,
        reason = "Les Auto Shots rendent du Focus et stabilisent la rotation.",
    },
    ["Studded Arrows"] = {
        throughput = 9, sustain = 1, survival = 0, utility = 0,
        reason = "Augmente les dégâts d'arme de Quick Shot.",
    },
    ["Strike Where It Hurts"] = {
        throughput = 9.5, sustain = 1, survival = 0, utility = 1,
        reason = "Les critiques amplifient les saignements sur la cible.",
    },
    ["Hawkeye"] = {
        throughput = 9.5, sustain = 1, survival = 0, utility = 2,
        reason = "Ajoute régulièrement des dégâts d'arme à distance.",
    },
    ["Rapid Strikes"] = {
        throughput = 9, sustain = 3, survival = 0, utility = 0,
        reason = "Les attaques automatiques peuvent infliger une frappe supplémentaire.",
    },
    ["Double The Pace"] = {
        throughput = 8.5, sustain = 5, survival = 0, utility = 5,
        reason = "Apporte hâte à distance au groupe et critique personnel.",
    },
    ["Skirmish"] = {
        throughput = 9, sustain = 9, survival = 2, utility = 2,
        reason = "Augmente le critique et réduit fortement les coûts en Focus.",
    },
    ["Opportunist"] = {
        throughput = 7.5, sustain = 2, survival = 0, utility = 4,
        reason = "Récompense les fenêtres de tir favorables.",
    },
    ["Light Arrows"] = {
        throughput = 7.5, sustain = 3, survival = 0, utility = 3,
        reason = "Améliore la pression à distance sans alourdir la rotation.",
    },
    ["An Arrow for Everything"] = {
        throughput = 8, sustain = 3, survival = 0, utility = 6,
        reason = "Augmente la polyvalence des munitions et des tirs.",
    },
    ["Masterful Archery"] = {
        throughput = 9, sustain = 2, survival = 0, utility = 1,
        reason = "Bonus de dégâts général pour la spécialisation.",
    },
    ["Maximum Power"] = {
        throughput = 8, sustain = 8, survival = 0, utility = 1,
        reason = "Améliore les fenêtres où le Focus est disponible.",
    },
    ["A Quick Demise"] = {
        throughput = 8.5, sustain = 2, survival = 0, utility = 2,
        reason = "Les Auto Shots prolongent Serrated Shot.",
    },
    ["Elven Tactics"] = {
        throughput = 7.5, sustain = 7, survival = 2, utility = 4,
        reason = "Améliore le rythme de la rotation et la mobilité.",
    },
    ["Woodland Stalker"] = {
        throughput = 7.5, sustain = 2, survival = 4, utility = 4,
        reason = "Bonus utile pour engager et maintenir la pression.",
    },
    ["Forest Dweller"] = {
        throughput = 2, sustain = 1, survival = 9, utility = 6,
        reason = "Choix défensif et mobile pour les combats BG.",
    },
    ["Onslaught"] = {
        throughput = 8.5, sustain = 7, survival = 1, utility = 2,
        reason = "Soutient les phases de dégâts prolongées.",
    },
    ["Endurance Training"] = {
        throughput = 1, sustain = 8, survival = 6, utility = 2,
        reason = "Améliore la durée d'engagement et la survie.",
    },
}

Advisor.Data.rangerProfiles = {
    bg = {
        label = "Archery BG équilibré",
        shortLabel = "BG équilibré",
        damage = 0.55, tempo = 0.15, survival = 0.30,
        talent = {
            throughput = 0.50, sustain = 0.15,
            survival = 0.25, utility = 0.10,
        },
    },
    damage = {
        label = "Archery dégâts à distance",
        shortLabel = "Dégâts maximum",
        damage = 0.80, tempo = 0.15, survival = 0.05,
        talent = {
            throughput = 0.80, sustain = 0.10,
            survival = 0.03, utility = 0.07,
        },
    },
    precision = {
        label = "Archery critique et Focus",
        shortLabel = "Critique & Focus",
        damage = 0.60, tempo = 0.30, survival = 0.10,
        talent = {
            throughput = 0.55, sustain = 0.30,
            survival = 0.05, utility = 0.10,
        },
    },
    survival = {
        label = "Archery survie BG",
        shortLabel = "Survie & mobilité",
        damage = 0.35, tempo = 0.10, survival = 0.55,
        talent = {
            throughput = 0.30, sustain = 0.10,
            survival = 0.45, utility = 0.15,
        },
    },
}

Advisor.Data.rangerPveProfiles = {
    bg = {
        label = "Archery PvE équilibré",
        shortLabel = "PvE équilibré",
        damage = 0.72, tempo = 0.28, survival = 0,
        talent = {
            throughput = 0.72, sustain = 0.18,
            survival = 0.02, utility = 0.08,
        },
    },
    damage = {
        label = "Archery PvE dégâts maximum",
        shortLabel = "Dégâts maximum",
        damage = 0.90, tempo = 0.10, survival = 0,
        talent = {
            throughput = 0.88, sustain = 0.06,
            survival = 0.01, utility = 0.05,
        },
    },
    precision = {
        label = "Archery PvE précision et Focus",
        shortLabel = "Précision & Focus",
        damage = 0.60, tempo = 0.40, survival = 0,
        talent = {
            throughput = 0.62, sustain = 0.28,
            survival = 0.02, utility = 0.08,
        },
    },
    survival = {
        label = "Archery progression PvE",
        shortLabel = "Progression PvE",
        damage = 0.55, tempo = 0.15, survival = 0.30,
        talent = {
            throughput = 0.52, sustain = 0.13,
            survival = 0.27, utility = 0.08,
        },
    },
}

Advisor.Data.genericProfiles = {
    HEALER = {
        bg = {
            label = "Soigneur équilibré",
            shortLabel = "Équilibré",
            talent = {
                throughput = 0.40, sustain = 0.25,
                survival = 0.25, utility = 0.10,
            },
        },
        throughput = {
            label = "Soins maximum",
            shortLabel = "Soins maximum",
            talent = {
                throughput = 0.75, sustain = 0.12,
                survival = 0.05, utility = 0.08,
            },
        },
        sustain = {
            label = "Autonomie de ressource",
            shortLabel = "Autonomie",
            talent = {
                throughput = 0.22, sustain = 0.60,
                survival = 0.08, utility = 0.10,
            },
        },
        survival = {
            label = "Survie et utilité",
            shortLabel = "Survie",
            talent = {
                throughput = 0.18, sustain = 0.10,
                survival = 0.57, utility = 0.15,
            },
        },
    },
    DAMAGER = {
        bg = {
            label = "DPS équilibré",
            shortLabel = "Équilibré",
            talent = {
                throughput = 0.55, sustain = 0.15,
                survival = 0.20, utility = 0.10,
            },
        },
        throughput = {
            label = "Dégâts maximum",
            shortLabel = "Dégâts maximum",
            talent = {
                throughput = 0.80, sustain = 0.08,
                survival = 0.05, utility = 0.07,
            },
        },
        sustain = {
            label = "Ressource et rythme",
            shortLabel = "Ressource",
            talent = {
                throughput = 0.42, sustain = 0.43,
                survival = 0.05, utility = 0.10,
            },
        },
        survival = {
            label = "Survie et contrôle",
            shortLabel = "Survie",
            talent = {
                throughput = 0.28, sustain = 0.08,
                survival = 0.49, utility = 0.15,
            },
        },
    },
    TANK = {
        bg = {
            label = "Tank équilibré",
            shortLabel = "Équilibré",
            talent = {
                throughput = 0.30, sustain = 0.20,
                survival = 0.40, utility = 0.10,
            },
        },
        throughput = {
            label = "Menace et dégâts",
            shortLabel = "Menace / dégâts",
            talent = {
                throughput = 0.68, sustain = 0.12,
                survival = 0.15, utility = 0.05,
            },
        },
        sustain = {
            label = "Ressource et contrôle",
            shortLabel = "Ressource",
            talent = {
                throughput = 0.25, sustain = 0.42,
                survival = 0.18, utility = 0.15,
            },
        },
        survival = {
            label = "Mitigation maximum",
            shortLabel = "Mitigation",
            talent = {
                throughput = 0.12, sustain = 0.13,
                survival = 0.65, utility = 0.10,
            },
        },
    },
    SUPPORT = {
        bg = {
            label = "Soutien équilibré",
            shortLabel = "Équilibré",
            talent = {
                throughput = 0.38, sustain = 0.18,
                survival = 0.18, utility = 0.26,
            },
        },
        throughput = {
            label = "Impact du groupe",
            shortLabel = "Impact groupe",
            talent = {
                throughput = 0.58, sustain = 0.10,
                survival = 0.07, utility = 0.25,
            },
        },
        sustain = {
            label = "Ressource et disponibilité",
            shortLabel = "Ressource",
            talent = {
                throughput = 0.28, sustain = 0.42,
                survival = 0.08, utility = 0.22,
            },
        },
        survival = {
            label = "Protection et contrôle",
            shortLabel = "Protection",
            talent = {
                throughput = 0.18, sustain = 0.08,
                survival = 0.42, utility = 0.32,
            },
        },
    },
}

Advisor.Data.classProfiles = {
    ["CHRONOMANCER:31"] = {
        key = "CHRONOMANCER:31",
        classToken = "CHRONOMANCER",
        specialization = 31,
        title = "Chronomancer — Time",
        shortTitle = "Time",
        role = "HEALER",
        model = "time_healer",
        defaultProfile = "bg",
        defaultContentMode = "pvp",
        profileOrder = { "bg", "throughput", "sustain", "survival" },
        profiles = Advisor.Data.profiles,
        contexts = {
            pvp = {
                label = "PvP / BG",
                profiles = Advisor.Data.profiles,
                priority =
                    "Résilience > Endurance > Esprit > Puissance des sorts > Hâte > Intelligence > Critique",
                description =
                    "PvP : Résilience > Endurance > Esprit > Puissance des sorts > Hâte > Intelligence > Critique.",
                survivalCondition = "tu dois mieux survivre en PvP",
                talentPriority = {
                    ["Shield of the Ages"] = 1.00,
                    ["Aeon of Protection"] = 0.90,
                    ["Buy Time"] = 0.85,
                    ["Continuum Restoration"] = 0.75,
                    ["Displacement"] = 0.75,
                    ["Temporal Focus"] = 0.65,
                    ["Desynchronization"] = 0.60,
                    ["Entropy Overload"] = 0.60,
                    ["Timeguard"] = 0.60,
                    ["Shimmering Shard"] = 0.65,
                },
                source =
                    "Ascension Sidekick + historique de combats PvP local",
            },
            pve = {
                label = "PvE / Donjons",
                profiles = Advisor.Data.timePveProfiles,
                provisional = true,
                priority =
                    "Esprit > Puissance des sorts > Critique > Hâte > Intelligence > MP5",
                description =
                    "PvE Mythic+ : Esprit > Puissance des sorts > Critique > Hâte > Intelligence > MP5.",
                statWeights = {
                    spirit = 10,
                    spellPower = 8.5,
                    crit = 7,
                    haste = 6,
                    intellect = 4.5,
                    mp5 = 3,
                },
                scoreLabels = { third = "Sécurité PvE" },
                survivalCondition =
                    "tu dois sécuriser la progression PvE",
                talentPriority = {
                    ["Epic Recovery"] = 1.00,
                    ["Keep Accelerating"] = 0.85,
                    ["Aeon of Renewal"] = 0.85,
                    ["Aeon of Protection"] = 0.75,
                    ["Infinite Shield"] = 0.75,
                    ["Wonders of Time"] = 0.70,
                    ["Unearthed Pools"] = 0.65,
                    ["Through The Aeons"] = 0.60,
                    ["Shimmering Shard"] = 0.70,
                    ["Chronicler"] = 0.65,
                    ["Eternity Warper"] = 0.70,
                    ["Perfect Timing"] = 0.70,
                    ["Waves of Time"] = 0.55,
                    ["Entropy Reversal"] = 0.45,
                    ["Time Skip"] = 0.65,
                    ["Cycling Aeons"] = 0.75,
                    ["Timeline Tether"] = 0.80,
                },
                talentDeprioritized = {
                    ["Eternity Shaper"] = true,
                    ["Buy Time"] = true,
                    ["Nozdormu's Gaze"] = true,
                    ["Titan's Gaze"] = true,
                    ["Shield of the Ages"] = true,
                    ["Time Blender"] = true,
                    ["Fabric of Time"] = true,
                    ["Improved Reverse Wound"] = true,
                    ["Endless Sands"] = true,
                    ["Converge the Infinite"] = true,
                    ["Orderly Protector"] = true,
                    ["Temporal Focus"] = true,
                    ["Entropy Overload"] = true,
                    ["Bronze Timeways"] = true,
                    ["Overcorrection"] = true,
                },
                source =
                    "CoA Build Hub, guide Mythic+ post-refonte + historique PvE local",
            },
        },
        talentRules = Advisor.Data.talentRules,
        scoreLabels = {
            first = "Soins",
            second = "Autonomie mana",
            third = "Survie PvP",
        },
        priorityDescription =
            "Choisis entre équilibre BG, puissance de soin, autonomie mana ou survie.",
        itemDescription =
            "L'addon sépare le rendement de soin, l'autonomie mana et la survie.",
        provisional = false,
        minimumTalentScore = 3.0,
        calibration = {
            source =
                "DataProbe Chronomancer Time niveaux 33, 36, 56 et 60 + combats BG",
            sessions = 5,
            snapshots = 100,
            tooltipObservations = 648,
            equipmentTransitions = 72,
            contextPowerTooltipSamples = 44,
            combats = 158,
            combatSessions = 1,
            combatSegments = 45,
            combatSeconds = 777.9,
            combatEvents = 4164,
            resourceSamples = 1571,
            bgDeathRate = 0.333,
            bgOverhealRate = 0.305,
            bgMainHealShare = 0.883,
            bgMovementRate = 0.374,
            slightRunSpeedPercent = 8,
            slightRunSpeedSamples = 387,
            -- Les changements d'objets Intelligence montrent que la composante
            -- sqrt(Intellect) varie avec l'état observé du personnage. Les
            -- points mesurés évitent de surestimer l'autonomie au niveau 36.
            manaRegenIntellectRootOffset = 3.593,
            manaRegenIntellectRootOffsetByLevel = {
                [33] = 3.593170,
                [36] = 0.000530,
                -- 14 transitions aller-retour au niveau 56 convergent entre
                -- 5,809 et 5,821 ; 5,815 reproduit leur médiane.
                [56] = 5.815000,
            },
            critPerIntellectReference = 0.064426,
            critPerIntellectReferenceLevel = 33,
            critPerIntellectByLevel = {
                [33] = 0.064427,
                [36] = 0.058280,
                -- Mesuré sans changement de score de critique sur
                -- Corpseshroud et Highborne Crown au niveau 56.
                [56] = 0.017297,
            },
        },
    },
    ["RANGER:28"] = {
        key = "RANGER:28",
        classToken = "RANGER",
        specialization = 28,
        title = "Ranger — Archery",
        shortTitle = "Archery",
        role = "DAMAGER",
        model = "ranger_archery",
        defaultProfile = "bg",
        defaultContentMode = "pvp",
        profileOrder = { "bg", "damage", "precision", "survival" },
        profiles = Advisor.Data.rangerProfiles,
        contexts = {
            pvp = {
                label = "PvP / BG",
                profiles = Advisor.Data.rangerProfiles,
                priority =
                    "Résilience > Endurance > Toucher (cap) > Agilité > Critique",
                description =
                    "PvP : Résilience > Endurance > Toucher jusqu'au cap > Agilité > Critique.",
                survivalCondition = "tu dois mieux survivre en PvP",
                hitCap = 5,
                hitCapProvisional = true,
                source = "Kami Labs, 23 juillet 2026",
            },
            pve = {
                label = "PvE / Donjons",
                profiles = Advisor.Data.rangerPveProfiles,
                provisional = true,
                priority =
                    "Toucher (cible +3, cap) > Agilité > Critique > Pénétration d'armure > Hâte",
                description =
                    "PvE : Toucher jusqu'au cap d'une cible +3 > Agilité > Critique > Pénétration > Hâte.",
                scoreLabels = { third = "Sécurité PvE" },
                survivalCondition =
                    "tu dois sécuriser la progression PvE",
                talentPriority = {
                    ["Precision Shot"] = 0.75,
                },
                talentDeprioritized = {
                    ["Opportunist"] = true,
                    ["Light Arrows"] = true,
                    ["Studded Arrows"] = true,
                    ["Boots of Elvenkind"] = true,
                    ["Serrations"] = true,
                    ["Strike Where It Hurts"] = true,
                    ["Lethal Wounds"] = true,
                    ["Snatch"] = true,
                    ["Dirty Fighter"] = true,
                    ["Camper"] = true,
                    ["Silent But Deadly"] = true,
                },
                hitCap = 8,
                hitCapProvisional = true,
                source = "Kami Labs, 23 juillet 2026",
            },
        },
        talentRules = Advisor.Data.rangerTalentRules,
        scoreLabels = {
            first = "Dégâts à distance",
            second = "Rythme & Focus",
            third = "Survie PvP",
        },
        priorityDescription =
            "Choisis entre équilibre BG, dégâts maximum, critique/Focus ou survie.",
        itemDescription =
            "L'addon sépare dégâts à distance, rythme de rotation/Focus et survie.",
        provisional = true,
        minimumTalentScore = 3.5,
        calibration = {
            source =
                "DataProbe Ranger Archery niveaux 34, 35 et 43 + combats BG",
            sessions = 4,
            snapshots = 97,
            tooltipObservations = 369,
            equipmentTransitions = 86,
            combats = 45,
            combatSessions = 1,
            combatSegments = 45,
            combatSeconds = 861.8,
            combatEvents = 6590,
            resourceSamples = 1737,
            bgDeathRate = 0.289,
            bgMovementRate = 0.683,
            bgFocusLowSampleRate = 0.158,
            bgAccuracyFailureRate = 0.011,
            pinpointFocusShare = 0.082,
        },
    },
}

local genericClassProfiles = {}
local activeClassProfileCache
local activeClassProfileCacheValid = false

local function GetSpecializationIdentity()
    local active = Advisor.SafeCall(GetSpecialization)
    local id, name, description, icon, role, class
    if active and type(GetSpecializationInfoByID) == "function" then
        id, name, description, icon, role, class =
            Advisor.SafeCall(GetSpecializationInfoByID, active)
    end
    if active and not name and type(GetSpecializationInfo) == "function" then
        id, name, description, icon, role, class =
            Advisor.SafeCall(GetSpecializationInfo, active)
    end
    return active, id, name, description, icon, role, class
end

local function BuildGenericClassProfile(classToken, className)
    local active, id, name, description, icon, role =
        GetSpecializationIdentity()
    role = Advisor.Data.genericProfiles[role] and role or "DAMAGER"
    local key =
        tostring(classToken or "UNKNOWN") .. ":" .. tostring(active or 0)
    if genericClassProfiles[key] then return genericClassProfiles[key] end

    local specName = name or
        ("Spécialisation " .. tostring(active or "?"))
    local profile = {
        key = key,
        classToken = classToken,
        specialization = id or active,
        title = tostring(className or classToken or "Classe") ..
            " — " .. specName,
        shortTitle = specName,
        role = role,
        model = "generic_talents",
        itemModelAvailable = false,
        defaultProfile = "bg",
        profileOrder = { "bg", "throughput", "sustain", "survival" },
        profiles = Advisor.Data.genericProfiles[role],
        talentRules = {},
        scoreLabels = {
            first = "Rendement",
            second = "Ressource",
            third = "Survie",
        },
        priorityDescription =
            "Les talents sont reclassés selon la priorité choisie. " ..
            "Une règle issue d'une infobulle est signalée comme provisoire.",
        itemDescription =
            "Le profil de comparaison d'équipement n'est pas encore calibré.",
        provisional = true,
        minimumTalentScore = 0,
        specializationDescription = description,
        specializationIcon = icon,
    }
    genericClassProfiles[key] = profile
    return profile
end

local function BuildGuideTalentMaps(guide)
    local priority = {}
    local deprioritized = {}
    local baseline = {}

    local build = guide and guide.recommendedBuild
    for _, talent in ipairs((build and build.talents) or {}) do
        local name = talent[1]
        local points = tonumber(talent[2]) or 1
        local tree = talent[3]
        if name and name ~= "" then
            local bonus = 0.65 + math.min(2, points - 1) * 0.12
            if tree == "spec" then bonus = bonus + 0.15 end
            priority[name] = math.max(priority[name] or 0, bonus)
            baseline[name] = true
        end
    end

    local pivot = guide and guide.pivot
    if pivot then
        if pivot.name and pivot.name ~= "" then
            priority[pivot.name] = math.max(
                priority[pivot.name] or 0,
                1.75
            )
        end
        if tonumber(pivot.spellID) and tonumber(pivot.spellID) > 0 then
            priority[tonumber(pivot.spellID)] = 1.75
        end
    end
    for _, talent in ipairs((guide and guide.deprioritized) or {}) do
        if talent.name and talent.name ~= "" and
            not baseline[talent.name] then
            deprioritized[talent.name] = true
        end
        if tonumber(talent.spellID) and tonumber(talent.spellID) > 0 then
            deprioritized[tonumber(talent.spellID)] = true
        end
    end
    return priority, deprioritized, baseline
end

local STAT_PRIORITY_SCALE = {
    1.00, 0.88, 0.77, 0.67, 0.58, 0.50, 0.43, 0.37,
}

local function NormalizeGuideStatText(value)
    value = tostring(value or "")
    local replacements = {
        { "É", "E" }, { "È", "E" }, { "Ê", "E" }, { "Ë", "E" },
        { "À", "A" }, { "Â", "A" }, { "Ä", "A" },
        { "Î", "I" }, { "Ï", "I" },
        { "Ô", "O" }, { "Ö", "O" },
        { "Ù", "U" }, { "Û", "U" }, { "Ü", "U" },
        { "Ç", "C" }, { "Œ", "OE" },
        { "é", "e" }, { "è", "e" }, { "ê", "e" }, { "ë", "e" },
        { "à", "a" }, { "â", "a" }, { "ä", "a" },
        { "î", "i" }, { "ï", "i" },
        { "ô", "o" }, { "ö", "o" },
        { "ù", "u" }, { "û", "u" }, { "ü", "u" },
        { "ç", "c" }, { "œ", "oe" },
    }
    for _, pair in ipairs(replacements) do
        value = string.gsub(value, pair[1], pair[2])
    end
    return string.lower(value)
end

local function HasText(value, needle)
    return string.find(value, needle, 1, true) ~= nil
end

local function AddStatWeight(weights, key, weight)
    weights[key] = math.max(weights[key] or 0, weight)
end

local function AddGuideStatLabel(weights, label, weight)
    local value = NormalizeGuideStatText(label)
    local armorPen = HasText(value, "armor penetration") or
        HasText(value, "penetration d'armure") or
        HasText(value, "penetration d’armure")
    local spellPen = HasText(value, "spell penetration") or
        HasText(value, "penetration des sorts") or
        HasText(value, "penetration de sort")

    if HasText(value, "expertise") then
        AddStatWeight(weights, "expertise", weight)
    end
    if HasText(value, "hit") or HasText(value, "toucher") or
        HasText(value, "precision") then
        AddStatWeight(weights, "hit", weight)
    end
    if HasText(value, "defense") then
        AddStatWeight(weights, "defense", weight)
    end
    if HasText(value, "stamina") or HasText(value, "endurance") or
        HasText(value, "vigueur") then
        AddStatWeight(weights, "stamina", weight)
    end
    if HasText(value, "strength") or HasText(value, "force") then
        AddStatWeight(weights, "strength", weight)
    end
    if HasText(value, "agility") or HasText(value, "agilite") then
        AddStatWeight(weights, "agility", weight)
    end
    if HasText(value, "intellect") or HasText(value, "intelligence") then
        AddStatWeight(weights, "intellect", weight)
    end
    if HasText(value, "spirit") or HasText(value, "esprit") then
        AddStatWeight(weights, "spirit", weight)
    end
    if HasText(value, "attack power") or
        HasText(value, "puissance d'attaque") or
        HasText(value, "puissance d’attaque") then
        AddStatWeight(weights, "attackPower", weight)
    end
    if HasText(value, "spell power") or
        HasText(value, "puissance des sorts") then
        AddStatWeight(weights, "spellPower", weight)
    end
    if HasText(value, "healing power") or
        HasText(value, "puissance de soin") or
        HasText(value, "bonus de soins") then
        AddStatWeight(weights, "spellPower", weight)
        AddStatWeight(weights, "bonusHealing", weight)
    end
    if HasText(value, "haste") or HasText(value, "hate") or
        HasText(value, "celerite") then
        AddStatWeight(weights, "haste", weight)
    end
    if HasText(value, "critical") or HasText(value, "critique") then
        AddStatWeight(weights, "crit", weight)
    end
    if armorPen then
        AddStatWeight(weights, "armorPenetration", weight)
    end
    if spellPen then
        AddStatWeight(weights, "spellPenetration", weight)
    end
    if HasText(value, "resilience") then
        AddStatWeight(weights, "resilience", weight)
    end
    if HasText(value, "dodge") or HasText(value, "esquive") then
        AddStatWeight(weights, "dodge", weight)
    end
    if HasText(value, "parry") or HasText(value, "parade") then
        AddStatWeight(weights, "parry", weight)
    end
    if HasText(value, "block") or HasText(value, "blocage") or
        HasText(value, "valeur de bloc") or
        HasText(value, "taux de bloc") then
        AddStatWeight(weights, "block", weight)
    end
    if not armorPen and (HasText(value, "armor") or
        HasText(value, "armure")) then
        AddStatWeight(weights, "armor", weight)
    end
    if HasText(value, "mp5") or HasText(value, "mana per 5") then
        AddStatWeight(weights, "mp5", weight)
    end
end

local function BuildGuideStatWeights(guide, contentMode)
    local values = contentMode == "pvp" and
        (guide.pvpPriorityDisplay or guide.pvpPriority) or
        (guide.pvePriorityDisplay or guide.pvePriority)
    local weights = {}
    for index, label in ipairs(values or {}) do
        AddGuideStatLabel(
            weights,
            label,
            STAT_PRIORITY_SCALE[index] or 0.32
        )
    end

    if contentMode == "pvp" then
        AddStatWeight(weights, "pvpPower", 1.05)
    else
        AddStatWeight(weights, "pvePower", 1.05)
    end
    if weights.attackPower or weights.armorPenetration or
        (weights.agility and not weights.spellPower) or
        (weights.strength and not weights.spellPower) then
        AddStatWeight(weights, "weaponDPS", 1.00)
    end
    return weights
end

local function GuidePriority(values)
    if type(values) ~= "table" or #values == 0 then
        return "priorité non publiée — DataProbe requis"
    end
    return table.concat(values, " > ")
end

local function BuildGuideClassProfile(
    classToken,
    className,
    active,
    id,
    name,
    description,
    icon,
    guide
)
    local key =
        tostring(classToken or guide.classKey or "UNKNOWN") ..
        ":" .. tostring(active or id or guide.specializationName)
    if genericClassProfiles[key] and
        genericClassProfiles[key].guideAvailable then
        return genericClassProfiles[key]
    end

    local role = Advisor.Data.genericProfiles[guide.role] and
        guide.role or "DAMAGER"
    local talentPriority, talentDeprioritized, talentBaseline =
        BuildGuideTalentMaps(guide)
    local profiles = Advisor.Data.genericProfiles[role]
    local firstScoreLabel = "Dégâts"
    if role == "HEALER" then
        firstScoreLabel = "Soins"
    elseif role == "SUPPORT" then
        firstScoreLabel = "Impact du groupe"
    elseif role == "TANK" then
        firstScoreLabel = "Menace / impact"
    end
    local profile = {
        key = key,
        classToken = classToken or guide.classKey,
        specialization = id or active,
        title = tostring(className or guide.className) ..
            " — " .. tostring(name or guide.specializationName),
        shortTitle = name or guide.specializationName,
        role = role,
        guideRole = guide.guideRole,
        resource = guide.resource,
        primary = guide.primary,
        model = guide.research and "guide_priority" or
            "guide_provisional",
        itemModelAvailable = guide.research ~= nil,
        defaultProfile = "bg",
        defaultContentMode = "pvp",
        profileOrder = { "bg", "throughput", "sustain", "survival" },
        profiles = profiles,
        contexts = {
            pvp = {
                label = "PvP/BG",
                description =
                    "Priorités PvP du guide. La Résilience et l’Endurance " ..
                    "restent séparées du rendement afin d’exposer les compromis.",
                priority = GuidePriority(
                    guide.pvpPriorityDisplay or guide.pvpPriority
                ),
                profiles = profiles,
                talentPriority = talentPriority,
                talentDeprioritized = talentDeprioritized,
                talentBaseline = talentBaseline,
                statWeights = BuildGuideStatWeights(guide, "pvp"),
                statConfidence = guide.analysisConfidence == "official" and
                    "medium" or "low",
                provisional = true,
            },
            pve = {
                label = "PvE",
                description =
                    "Priorités PvE du guide. Les caps de toucher, expertise " ..
                    "ou défense restent provisoires jusqu’à mesure en jeu.",
                priority = GuidePriority(
                    guide.pvePriorityDisplay or guide.pvePriority
                ),
                profiles = profiles,
                talentPriority = talentPriority,
                talentDeprioritized = talentDeprioritized,
                talentBaseline = talentBaseline,
                statWeights = BuildGuideStatWeights(guide, "pve"),
                statConfidence = guide.analysisConfidence == "official" and
                    "medium" or "low",
                provisional = true,
            },
        },
        talentRules = {},
        scoreLabels = {
            first = firstScoreLabel,
            second = "Ressource / rythme",
            third = "Survie",
        },
        priorityDescription =
            "Le rôle, les priorités PvE/PvP et le talent pivot viennent du " ..
            "guide publié. Les infobulles en jeu adaptent ensuite le classement " ..
            "à la priorité choisie.",
        itemDescription = guide.research and
            (
                "Comparaison prudente par indice de priorité PvE/PvP. " ..
                "Elle reconnaît les statistiques fixes, mais ne chiffre pas " ..
                "les procs, caps ni synergies non mesurés."
            ) or
            (
                "Profil guide disponible, mais comparaison d’équipement " ..
                "désactivée jusqu’à calibration des conversions par DataProbe."
            ),
        provisional = true,
        guideAvailable = true,
        guideCoverage = guide.guideCoverage or 0,
        guideSource = guide.source,
        guideStatNote = guide.statNote,
        guidePivot = guide.pivot,
        guideResearch = guide.research,
        recommendedBuild = guide.recommendedBuild,
        rotation = guide.rotation,
        weapons = guide.weapons,
        contentTiers = guide.contentTiers,
        strengths = guide.strengths,
        weaknesses = guide.weaknesses,
        gearAdvice = guide.gearAdvice,
        buildHubEvidence = guide.buildHubEvidence,
        minimumTalentScore = 0,
        specializationDescription = description,
        specializationIcon = icon,
    }
    genericClassProfiles[key] = profile
    return profile
end

local function MergeMissing(target, source)
    target = target or {}
    for key, value in pairs(source or {}) do
        if target[key] == nil then target[key] = value end
    end
    return target
end

local function AttachGuideResearch(profile, guide)
    if not profile or not guide or profile.guideResearchAttached then
        return profile
    end
    local talentPriority, talentDeprioritized, talentBaseline =
        BuildGuideTalentMaps(guide)
    for mode, context in pairs(profile.contexts or {}) do
        context.talentPriority = MergeMissing(
            context.talentPriority,
            talentPriority
        )
        context.talentDeprioritized = MergeMissing(
            context.talentDeprioritized,
            talentDeprioritized
        )
        context.talentBaseline = MergeMissing(
            context.talentBaseline,
            talentBaseline
        )
        context.statWeights = context.statWeights or
            BuildGuideStatWeights(guide, mode)
        context.statConfidence = context.statConfidence or "high"
    end
    profile.guideAvailable = true
    profile.guideCoverage = guide.guideCoverage or 0
    profile.guideSource = guide.source
    profile.guideStatNote = guide.statNote
    profile.guidePivot = guide.pivot
    profile.guideResearch = guide.research
    profile.recommendedBuild = guide.recommendedBuild
    profile.rotation = guide.rotation
    profile.weapons = guide.weapons
    profile.contentTiers = guide.contentTiers
    profile.strengths = guide.strengths
    profile.weaknesses = guide.weaknesses
    profile.gearAdvice = guide.gearAdvice
    profile.buildHubEvidence = guide.buildHubEvidence
    profile.guideResearchAttached = true
    return profile
end

function Advisor.Data.InvalidateActiveClassProfile()
    activeClassProfileCache = nil
    activeClassProfileCacheValid = false
end

function Advisor.Data.GetActiveClassProfile()
    if activeClassProfileCacheValid then
        return activeClassProfileCache
    end

    local className, classToken = UnitClass("player")
    local specialization, id, name, description, icon =
        GetSpecializationIdentity()
    local profile = Advisor.Data.classProfiles[
        tostring(classToken or "") .. ":" .. tostring(specialization or "")
    ]
    if profile then
        local calibratedGuide = Advisor.GuideProfiles and
            Advisor.GuideProfiles.Find(
                classToken,
                className,
                name
            )
        if calibratedGuide then
            AttachGuideResearch(profile, calibratedGuide)
        end
        activeClassProfileCache = profile
        activeClassProfileCacheValid = true
        return profile
    end

    local guide = Advisor.GuideProfiles and
        Advisor.GuideProfiles.Find(
            classToken,
            className,
            name
        )
    if guide then
        activeClassProfileCache = BuildGuideClassProfile(
            classToken,
            className,
            specialization,
            id,
            name,
            description,
            icon,
            guide
        )
        activeClassProfileCacheValid = true
        return activeClassProfileCache
    end
    activeClassProfileCache = BuildGenericClassProfile(classToken, className)
    activeClassProfileCacheValid = true
    return activeClassProfileCache
end

function Advisor.Data.GetDefaultProfileKey(classProfile)
    classProfile = classProfile or Advisor.Data.GetActiveClassProfile()
    return classProfile and classProfile.defaultProfile or "bg"
end

function Advisor.Data.NormalizeContentMode(contentMode, classProfile)
    classProfile = classProfile or Advisor.Data.GetActiveClassProfile()
    if not classProfile then return "pvp" end
    local contexts = classProfile.contexts
    if type(contexts) ~= "table" then
        return classProfile.defaultContentMode or "pvp"
    end
    if contexts[contentMode] then return contentMode end
    return classProfile.defaultContentMode or "pvp"
end

function Advisor.Data.GetContext(classProfile, contentMode)
    classProfile = classProfile or Advisor.Data.GetActiveClassProfile()
    if not classProfile then return nil end
    contentMode = Advisor.Data.NormalizeContentMode(contentMode, classProfile)
    return classProfile.contexts and classProfile.contexts[contentMode]
end

local function ResolveProfiles(classProfile, contentMode)
    local context = Advisor.Data.GetContext(classProfile, contentMode)
    return (context and context.profiles) or classProfile.profiles
end

function Advisor.Data.GetProfile(profileKey, classProfile, contentMode)
    classProfile = classProfile or Advisor.Data.GetActiveClassProfile()
    if not classProfile then return nil end
    if not contentMode and Advisor.GetSelectedContentMode then
        contentMode = Advisor.GetSelectedContentMode()
    end
    local profiles = ResolveProfiles(classProfile, contentMode)
    return profiles[profileKey] or profiles[classProfile.defaultProfile]
end

function Advisor.Data.NormalizeProfileKey(profileKey, classProfile, contentMode)
    classProfile = classProfile or Advisor.Data.GetActiveClassProfile()
    if not classProfile then return "bg" end
    if not contentMode and Advisor.GetSelectedContentMode then
        contentMode = Advisor.GetSelectedContentMode()
    end
    local profiles = ResolveProfiles(classProfile, contentMode)
    if profiles[profileKey] then return profileKey end
    return classProfile.defaultProfile
end

function Advisor.Data.GetStatPriority(classProfile, contentMode)
    local context = Advisor.Data.GetContext(classProfile, contentMode)
    return context and context.priority
end

function Advisor.Data.GetTalentRules(classProfile)
    classProfile = classProfile or Advisor.Data.GetActiveClassProfile()
    return classProfile and classProfile.talentRules or {}
end

function Advisor.Data.GetRecommendedTalentBuild(classProfile, contentMode)
    classProfile = classProfile or Advisor.Data.GetActiveClassProfile()
    if not classProfile or classProfile.model ~= "time_healer" then return nil end
    contentMode = Advisor.Data.NormalizeContentMode(contentMode, classProfile)
    return Advisor.Data.timeRecommendedTalentBuilds[contentMode]
end
