local Advisor = _G.CoAAnalyticsAdvisor

Advisor.ProcTracker = Advisor.ProcTracker or {}
local Tracker = Advisor.ProcTracker

local eventFrame = CreateFrame("Frame")
local display
local icons = {}
local initialized = false
local updateElapsed = 0
local idealWasActive = false
local idealNextProcAt
local lastAeonCooldownStart
local throughEstimatedExpiresAt

local PROCS = {
    ideal = {
        name = "Ideal Time",
        spellID = 807036,
        icon = "Interface\\icons\\nhi_corruptionknowledge_Border",
    },
    aeons = {
        name = "Through The Aeons",
        spellID = 560310,
        icon = "Interface\\icons\\nhi_timewarp_Border",
    },
}

local AEON_SPELL_IDS = { 806290, 806292, 806293, 92119 }

local function L(text)
    return Advisor.LocalizeText and Advisor.LocalizeText(text) or text
end

local function EnsureDB()
    local database = Advisor.GetDatabase()
    if type(database.procTracker) ~= "table" then
        database.procTracker = {}
    end
    return database.procTracker
end

local function NormalizeName(value)
    return string.lower(tostring(value or "")):gsub("[^%w]", "")
end

local function AuraMatches(name, spellID, definition)
    if tonumber(spellID) == definition.spellID then return true end
    local auraName = NormalizeName(name)
    local wantedName = NormalizeName(definition.name)
    return auraName == wantedName or
        string.find(auraName, wantedName, 1, true) ~= nil
end

local function FindPlayerBuff(definition)
    local reader = UnitBuff or UnitAura
    if type(reader) ~= "function" then return nil end
    for index = 1, 40 do
        local ok
        local name, rank, icon, count, auraType, duration, expirationTime,
            caster, stealable, consolidate, spellID
        ok, name, rank, icon, count, auraType, duration, expirationTime,
            caster, stealable, consolidate, spellID =
            pcall(reader, "player", index)
        if not ok then return nil end
        if not name then break end
        if AuraMatches(name, spellID, definition) then
            return {
                icon = icon,
                duration = tonumber(duration) or 0,
                expirationTime = tonumber(expirationTime) or 0,
            }
        end
    end
    return nil
end

local function TalentIsMissing(definition)
    if not Advisor.TalentScanner or not Advisor.TalentScanner.GetTalent then
        return false
    end
    local talent = Advisor.TalentScanner.GetTalent(
        definition.name, definition.spellID
    )
    return talent and (tonumber(talent.rank) or 0) <= 0 or false
end

local function SavePosition(frame)
    local db = EnsureDB()
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    db.point = point or "CENTER"
    db.relativePoint = relativePoint or db.point
    db.x = tonumber(x) or 0
    db.y = tonumber(y) or 0
end

local function RestorePosition(frame)
    local db = EnsureDB()
    frame:ClearAllPoints()
    frame:SetPoint(
        db.point or "CENTER",
        UIParent,
        db.relativePoint or db.point or "CENTER",
        tonumber(db.x) or 0,
        tonumber(db.y) or -180
    )
end

local function SetCooldown(cooldown, start, duration)
    start = tonumber(start) or 0
    duration = tonumber(duration) or 0
    if duration <= 0 then
        if cooldown.coaStart == 0 and cooldown.coaDuration == 0 then return end
        cooldown.coaStart = 0
        cooldown.coaDuration = 0
        if type(CooldownFrame_SetTimer) == "function" then
            CooldownFrame_SetTimer(cooldown, 0, 0, 0)
        elseif type(cooldown.SetCooldown) == "function" then
            cooldown:SetCooldown(0, 0)
        end
        cooldown:Hide()
        return
    end
    if cooldown.coaStart == start and cooldown.coaDuration == duration then
        return
    end
    cooldown.coaStart = start
    cooldown.coaDuration = duration
    cooldown:Show()
    if type(CooldownFrame_SetTimer) == "function" then
        CooldownFrame_SetTimer(cooldown, start, duration, 1)
    elseif type(cooldown.SetCooldown) == "function" then
        cooldown:SetCooldown(start, duration)
    end
end

local function CreateProcIcon(parent, key, x)
    local button = CreateFrame("Frame", nil, parent)
    button:SetWidth(46)
    button:SetHeight(46)
    button:SetPoint("LEFT", parent, "LEFT", x, 0)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(button)
    background:SetTexture("Interface\\Buttons\\WHITE8X8")
    background:SetVertexColor(0.015, 0.02, 0.03, 0.92)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
    icon:SetTexture(PROCS[key].icon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local cooldown = CreateFrame(
        "Cooldown", nil, button, "CooldownFrameTemplate"
    )
    cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
    cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    cooldown.noCooldownCount = true
    cooldown:Hide()

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(button)
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")

    local glow = button:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("TOPLEFT", button, "TOPLEFT", -6, 6)
    glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 6, -6)
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1.00, 0.78, 0.10)
    glow:SetAlpha(0)

    local timerLayer = CreateFrame("Frame", nil, button)
    timerLayer:SetAllPoints(button)
    timerLayer:SetFrameLevel(cooldown:GetFrameLevel() + 1)
    local timer = timerLayer:CreateFontString(
        nil, "OVERLAY", "NumberFontNormalLarge"
    )
    timer:SetPoint("CENTER", button, "CENTER", 0, 0)
    timer:SetShadowOffset(1, -1)
    timer:SetShadowColor(0, 0, 0, 1)

    icons[key] = {
        frame = button,
        icon = icon,
        cooldown = cooldown,
        border = border,
        glow = glow,
        timer = timer,
        timerLayer = timerLayer,
    }
end

local function ShowTooltip(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(L("Procs Time"), 0.35, 0.82, 1.00)
    GameTooltip:AddLine(
        L("Ideal Time : le timer indique le temps restant pour crit."),
        1.00, 0.82, 0.20
    )
    GameTooltip:AddLine(
        L("Through : le timer indique le prochain changement d'Aeon."),
        0.30, 0.90, 1.00
    )
    GameTooltip:AddLine(L("Glisser pour déplacer"), 0.60, 0.65, 0.72)
    GameTooltip:Show()
end

local function CreateDisplay()
    if display then return display end
    display = CreateFrame("Frame", "CoAAnalyticsAdvisorTimeProcTracker", UIParent)
    display:SetWidth(100)
    display:SetHeight(50)
    -- Combat information should stay above the 3D world, but never above
    -- full UI panels such as the world map.
    display:SetFrameStrata("LOW")
    display:SetFrameLevel(5)
    display:SetMovable(true)
    display:SetClampedToScreen(true)
    display:EnableMouse(true)
    display:RegisterForDrag("LeftButton")

    CreateProcIcon(display, "ideal", 2)
    CreateProcIcon(display, "aeons", 52)

    display:SetScript("OnDragStart", function(self)
        if not InCombatLockdown or not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    display:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)
    display:SetScript("OnEnter", ShowTooltip)
    display:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    RestorePosition(display)
    display:Hide()
    return display
end

local function GetAeonCooldown(now)
    if type(GetSpellCooldown) ~= "function" then return nil end
    local best
    for _, spellID in ipairs(AEON_SPELL_IDS) do
        local start, duration, enabled =
            Advisor.SafeCall(GetSpellCooldown, spellID)
        start = tonumber(start) or 0
        duration = tonumber(duration) or 0
        local remaining = start > 0 and duration > 0 and
            math.max(0, start + duration - now) or 0
        -- Ignore the normal global cooldown. The Aeon shared cooldown is
        -- longer (4 sec with the current Time build).
        if enabled ~= 0 and duration > 2 and remaining > 0 and
            (not best or remaining > best.remaining) then
            best = {
                start = start,
                duration = duration,
                remaining = remaining,
            }
        end
    end
    return best
end

local function SetUnavailable(procIcon)
    SetCooldown(procIcon.cooldown, 0, 0)
    procIcon.icon:SetAlpha(0.30)
    procIcon.border:SetAlpha(1)
    procIcon.glow:SetAlpha(0)
    procIcon.timer:SetAlpha(1)
    procIcon.border:SetVertexColor(0.35, 0.35, 0.38)
    procIcon.timer:SetText("X")
    procIcon.timer:SetTextColor(0.65, 0.65, 0.68)
end

local function UpdateIdeal(now, aura)
    local procIcon = icons.ideal
    if TalentIsMissing(PROCS.ideal) then
        SetUnavailable(procIcon)
        return false
    end
    if aura then
        local remaining = aura.expirationTime and aura.expirationTime > now and
            aura.expirationTime - now or nil
        if remaining and aura.duration and aura.duration > 0 then
            SetCooldown(
                procIcon.cooldown,
                aura.expirationTime - aura.duration,
                aura.duration
            )
        else
            SetCooldown(procIcon.cooldown, 0, 0)
        end
        procIcon.icon:SetAlpha(1)
        local pulse = 0.35 + math.abs(math.sin(now * 5.5)) * 0.65
        procIcon.border:SetAlpha(pulse)
        procIcon.border:SetVertexColor(1.00, 0.78, 0.10)
        procIcon.glow:SetAlpha(pulse)
        procIcon.timer:SetAlpha(0.72 + pulse * 0.28)
        procIcon.timer:SetText(
            remaining and string.format("%.1f", remaining) or "!"
        )
        procIcon.timer:SetTextColor(1.00, 0.88, 0.20)
        return true
    end
    procIcon.icon:SetAlpha(0.62)
    procIcon.border:SetAlpha(1)
    procIcon.glow:SetAlpha(0)
    procIcon.timer:SetAlpha(1)
    local remaining = idealNextProcAt and
        math.max(0, idealNextProcAt - now) or nil
    if remaining and remaining > 0 then
        SetCooldown(procIcon.cooldown, idealNextProcAt - 30, 30)
        procIcon.border:SetVertexColor(0.75, 0.48, 0.12)
        procIcon.timer:SetText(tostring(math.ceil(remaining)))
        procIcon.timer:SetTextColor(1.00, 0.72, 0.15)
    else
        SetCooldown(procIcon.cooldown, 0, 0)
        procIcon.border:SetVertexColor(0.42, 0.44, 0.50)
        procIcon.timer:SetText("…")
        procIcon.timer:SetTextColor(0.75, 0.75, 0.78)
    end
    return false
end

local function UpdateAeons(now, aura)
    local procIcon = icons.aeons
    if TalentIsMissing(PROCS.aeons) then
        SetUnavailable(procIcon)
        return false
    end
    local cooldown = GetAeonCooldown(now)
    local cooldownActive = cooldown and cooldown.remaining > 0.05
    if cooldownActive and cooldown.start ~= lastAeonCooldownStart then
        throughEstimatedExpiresAt = now + 8
        lastAeonCooldownStart = cooldown.start
    end
    if aura and aura.expirationTime and aura.expirationTime > now then
        throughEstimatedExpiresAt = aura.expirationTime
    end
    local throughActive = aura ~= nil or
        (throughEstimatedExpiresAt and throughEstimatedExpiresAt > now)

    procIcon.glow:SetAlpha(0)
    procIcon.timer:SetAlpha(1)
    if cooldownActive then
        SetCooldown(procIcon.cooldown, cooldown.start, cooldown.duration)
        procIcon.icon:SetAlpha(0.68)
        procIcon.border:SetAlpha(1)
        procIcon.border:SetVertexColor(1.00, 0.42, 0.08)
        procIcon.timer:SetText(string.format("%.1f", cooldown.remaining))
        procIcon.timer:SetTextColor(1.00, 0.68, 0.16)
        return throughActive and true or false
    end
    SetCooldown(procIcon.cooldown, 0, 0)
    procIcon.icon:SetAlpha(1)
    if throughActive then
        procIcon.border:SetAlpha(1)
        procIcon.border:SetVertexColor(0.20, 0.90, 1.00)
        local remaining = throughEstimatedExpiresAt and
            math.max(0, throughEstimatedExpiresAt - now) or nil
        procIcon.timer:SetText(
            remaining and tostring(math.ceil(remaining)) or "GO"
        )
        procIcon.timer:SetTextColor(0.35, 0.95, 1.00)
        return true
    end
    procIcon.border:SetVertexColor(1.00, 0.12, 0.08)
    procIcon.border:SetAlpha(1)
    procIcon.glow:SetVertexColor(1.00, 0.10, 0.05)
    procIcon.glow:SetAlpha(0.55)
    procIcon.timer:SetText("!")
    procIcon.timer:SetTextColor(1.00, 0.22, 0.15)
    return false
end

local function UpdateDisplay()
    CreateDisplay()
    local shouldShow = Advisor.IsTimeCharacter and Advisor.IsTimeCharacter() and
        (not CoAAnalyticsAdvisorDB or CoAAnalyticsAdvisorDB.enabled ~= false)
    local mapVisible = WorldMapFrame and
        Advisor.SafeCall(WorldMapFrame.IsShown, WorldMapFrame)
    if mapVisible then
        display:Hide()
        return
    end
    if not shouldShow then
        display:Hide()
        idealWasActive = false
        idealNextProcAt = nil
        lastAeonCooldownStart = nil
        throughEstimatedExpiresAt = nil
        return
    end
    display:Show()

    local now = GetTime()
    local idealAura = FindPlayerBuff(PROCS.ideal)
    local aeonsAura = FindPlayerBuff(PROCS.aeons)
    local idealActive = idealAura ~= nil
    if idealActive and not idealWasActive then
        idealNextProcAt = now + 30
    end
    idealWasActive = idealActive

    UpdateIdeal(now, idealAura)
    UpdateAeons(now, aeonsAura)
end

function Tracker.RefreshVisibility()
    UpdateDisplay()
end

function Tracker.Initialize()
    if initialized then return end
    initialized = true
    EnsureDB()
    CreateDisplay()
    for _, event in ipairs({
        "UNIT_AURA",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_TALENT_UPDATE",
        "ACTIVE_TALENT_GROUP_CHANGED",
        "PLAYER_SPECIALIZATION_CHANGED",
        "WORLD_MAP_UPDATE",
    }) do
        pcall(eventFrame.RegisterEvent, eventFrame, event)
    end
    eventFrame:SetScript("OnEvent", function(self, event, unit)
        if event ~= "UNIT_AURA" or unit == "player" then UpdateDisplay() end
    end)
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        updateElapsed = updateElapsed + elapsed
        if updateElapsed < 0.10 then return end
        updateElapsed = 0
        UpdateDisplay()
    end)
    UpdateDisplay()
end
