local Advisor = _G.CoAAnalyticsAdvisor

Advisor.UI = Advisor.UI or {}
local UI = Advisor.UI

local mainFrame
local statusText
local talentText
local talentCards = {}
local talentHighlighter
local talentBuildButton
local talentBuildHighlighters = {}
local highlightedTalentBuildMode
local combatText
local adviceButton
local autoGreedLootButton
local profileButtons = {}
local contentModeButtons = {}
local feedbackText
local advisorWidgets = {}
local dataProbePanel
local autoLootPanel
local advisorTabButton
local autoLootTabButton
local dataProbeTabButton
local activeMainTab = "advisor"
local embeddedMode = false
local dataProbeStatusText
local dataProbeProgressText
local dataProbeToggleButton
local dataProbeCaptureButton
local dataProbeNewSessionButton
local dataProbeExportButton
local dataProbeCollectionPanel
local dataProbeCoveragePanel
local dataProbeCollectTabButton
local dataProbeCommunityTabButton
local activeDataProbeSubTab = "collect"
local coverageSummaryText
local coverageTitleText
local coverageListTitleText
local coverageRows = {}
local coveragePageText
local coveragePage = 1
local coverageProfiles = {}
local profileDescriptionText
local itemDescriptionText
local combatDescriptionText
local combatTitleText
local resetCombatButton
local localSuggestionButton
local localAnalysisToggleButton
local languageButtons = {}
local autoLootStatChecks = {}
local autoLootStatusText

local PRIORITY_COLORS = {
    [1] = { 1.00, 0.82, 0.10 },
    [2] = { 0.78, 0.84, 0.92 },
    [3] = { 0.88, 0.48, 0.16 },
}

local COLORS = {
    gold = "|cffffd200",
    green = "|cff48df74",
    red = "|cffff6060",
    blue = "|cff6ebeff",
    gray = "|cffb8b8b8",
    white = "|cffffffff",
    close = "|r",
}

-- Flat, high-contrast theme shared by every CoA Analytics page.  The palette and
-- spacing intentionally match the visual language used by CoA Analytics while
-- remaining completely self-contained for the 3.3.5 client.
local THEME = {
    window = { 0.016, 0.020, 0.028, 0.985 },
    surface = { 0.048, 0.060, 0.078, 0.985 },
    surfaceHover = { 0.085, 0.105, 0.135, 0.995 },
    surfaceActive = { 0.135, 0.160, 0.195, 1.00 },
    border = { 0.240, 0.285, 0.350, 1.00 },
    borderStrong = { 0.360, 0.420, 0.500, 1.00 },
    teal = { 0.100, 0.720, 0.520, 1.00 },
    gold = { 1.000, 0.780, 0.120, 1.00 },
    orange = { 0.950, 0.580, 0.100, 1.00 },
    muted = { 0.680, 0.700, 0.740, 1.00 },
}

local function CreateSolidTexture(parent, layer, r, g, b, a)
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
    texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
    return texture
end

local function ApplyModernBackdrop(frame, background, border, edgeSize)
    background = background or THEME.surface
    border = border or THEME.border
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = edgeSize or 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(
        background[1], background[2], background[3], background[4]
    )
    frame:SetBackdropBorderColor(
        border[1], border[2], border[3], border[4] or 1
    )
end

local CreateButton

local function CreateLanguageFlagButton(parent, language, x)
    local button = CreateButton(
        parent, "", 32, 22,
        "TOPRIGHT", parent, "TOPRIGHT", x, -11
    )
    button.language = language

    local flag = CreateFrame("Frame", nil, button)
    flag:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
    flag:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 5)
    flag:EnableMouse(false)

    if language == "fr" then
        local blue = CreateSolidTexture(flag, "ARTWORK", 0.02, 0.22, 0.58, 1)
        blue:SetPoint("TOPLEFT", flag, "TOPLEFT", 0, 0)
        blue:SetPoint("BOTTOMLEFT", flag, "BOTTOMLEFT", 0, 0)
        blue:SetWidth(7.5)
        local white = CreateSolidTexture(flag, "ARTWORK", 0.96, 0.96, 0.96, 1)
        white:SetPoint("TOPLEFT", blue, "TOPRIGHT", 0, 0)
        white:SetPoint("BOTTOMLEFT", blue, "BOTTOMRIGHT", 0, 0)
        white:SetWidth(7.5)
        local red = CreateSolidTexture(flag, "ARTWORK", 0.82, 0.03, 0.08, 1)
        red:SetPoint("TOPLEFT", white, "TOPRIGHT", 0, 0)
        red:SetPoint("BOTTOMRIGHT", flag, "BOTTOMRIGHT", 0, 0)
    else
        local white = CreateSolidTexture(
            flag, "ARTWORK", 0.98, 0.98, 0.98, 1
        )
        white:SetAllPoints(flag)

        -- Compact United States flag: seven red stripes over a white field,
        -- with a blue canton and a few visible star points at this UI size.
        for stripe = 0, 6 do
            local red = CreateSolidTexture(
                flag, "ARTWORK", 0.70, 0.03, 0.08, 1
            )
            red:SetPoint("TOPLEFT", flag, "TOPLEFT", 0, -stripe * 2)
            red:SetPoint("TOPRIGHT", flag, "TOPRIGHT", 0, -stripe * 2)
            red:SetHeight(1)
        end

        local canton = CreateSolidTexture(
            flag, "ARTWORK", 0.02, 0.12, 0.38, 1
        )
        canton:SetPoint("TOPLEFT", flag, "TOPLEFT", 0, 0)
        canton:SetWidth(10)
        canton:SetHeight(7)

        local starPoints = {
            { 2, 1.5 }, { 5, 1.5 }, { 8, 1.5 },
            { 3.5, 3.5 }, { 6.5, 3.5 },
            { 2, 5.5 }, { 5, 5.5 }, { 8, 5.5 },
        }
        for _, point in ipairs(starPoints) do
            local star = CreateSolidTexture(
                flag, "OVERLAY", 1, 1, 1, 1
            )
            star:SetPoint(
                "TOPLEFT", canton, "TOPLEFT", point[1], -point[2]
            )
            star:SetWidth(1)
            star:SetHeight(1)
        end
    end
    button.flag = flag
    return button
end

local function Color(color, text)
    return (COLORS[color] or "") .. tostring(text or "") .. COLORS.close
end

local function Localized(value)
    return Advisor.LocalizeText and Advisor.LocalizeText(value) or value
end

local function LocalizeTextRegion(region)
    if not region or region.coaLocalized then return region end
    local originalSetText = region.SetText
    if type(originalSetText) == "function" then
        region.SetText = function(self, value)
            originalSetText(self, Localized(value))
        end
    end
    region.coaLocalized = true
    return region
end

local function AddTooltipLine(tooltip, value, ...)
    tooltip:AddLine(Localized(value), ...)
end

local function AddTooltipDoubleLine(tooltip, left, right, ...)
    tooltip:AddDoubleLine(Localized(left), Localized(right), ...)
end

local function CreateText(parent, template, text, x, y, width, justify)
    local font = parent:CreateFontString(nil, "ARTWORK", template)
    LocalizeTextRegion(font)
    font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then
        font:SetWidth(width)
        font:SetJustifyH(justify or "LEFT")
        font:SetJustifyV("TOP")
    end
    font:SetText(text or "")
    return font
end

local function CreateSection(parent, top, height)
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, top)
    section:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, top)
    section:SetHeight(height)
    ApplyModernBackdrop(section, THEME.surface, THEME.border, 8)
    local accent = CreateSolidTexture(
        section, "ARTWORK",
        THEME.teal[1], THEME.teal[2], THEME.teal[3], 0.9
    )
    accent:SetPoint("TOPLEFT", section, "TOPLEFT", 4, -4)
    accent:SetPoint("BOTTOMLEFT", section, "BOTTOMLEFT", 4, 4)
    accent:SetWidth(2)
    section.accent = accent
    return section
end

CreateButton = function(parent, text, width, height, point, relative, relativePoint, x, y)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetPoint(point, relative or parent, relativePoint or point, x or 0, y or 0)
    ApplyModernBackdrop(button, THEME.surfaceHover, THEME.borderStrong, 7)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetJustifyH("CENTER")
    button:SetFontString(label)
    button.label = label

    local highlight = CreateSolidTexture(
        button, "HIGHLIGHT",
        THEME.teal[1], THEME.teal[2], THEME.teal[3], 0.18
    )
    highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
    highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
    button:SetHighlightTexture(highlight)

    local pressed = CreateSolidTexture(
        button, "ARTWORK",
        THEME.gold[1], THEME.gold[2], THEME.gold[3], 0.14
    )
    pressed:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
    pressed:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
    button:SetPushedTexture(pressed)

    local originalSetText = button.SetText
    button.SetText = function(self, value)
        originalSetText(self, Localized(value))
    end
    local originalDisable = button.Disable
    button.Disable = function(self)
        originalDisable(self)
        self:GetFontString():SetTextColor(0.42, 0.44, 0.48)
        self:SetBackdropColor(0.035, 0.038, 0.048, 0.92)
    end
    local originalEnable = button.Enable
    button.Enable = function(self)
        originalEnable(self)
        self:GetFontString():SetTextColor(0.90, 0.92, 0.95)
        self:SetBackdropColor(
            THEME.surfaceHover[1], THEME.surfaceHover[2],
            THEME.surfaceHover[3], THEME.surfaceHover[4]
        )
    end
    button:SetText(text)
    return button
end

local function CreateTab(parent, text, width, point, relative, relativePoint, x, y)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(34)
    button:SetPoint(
        point,
        relative or parent,
        relativePoint or point,
        x or 0,
        y or 0
    )
    ApplyModernBackdrop(button, THEME.surface, THEME.border, 7)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", button, "CENTER", 0, 1)
    label:SetText(Localized(text))
    button.label = label
    local activeLine = button:CreateTexture(nil, "OVERLAY")
    activeLine:SetHeight(3)
    activeLine:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    activeLine:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    activeLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    activeLine:SetVertexColor(
        THEME.orange[1], THEME.orange[2], THEME.orange[3], 1
    )
    activeLine:Hide()
    button.activeLine = activeLine
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlight:SetVertexColor(
        THEME.teal[1], THEME.teal[2], THEME.teal[3], 0.12
    )
    button.SetText = function(self, value)
        self.label:SetText(Localized(value or ""))
    end
    button.SetActive = function(self, active)
        if active then
            self:SetBackdropColor(
                THEME.surfaceActive[1], THEME.surfaceActive[2],
                THEME.surfaceActive[3], THEME.surfaceActive[4]
            )
            self:SetBackdropBorderColor(
                THEME.borderStrong[1], THEME.borderStrong[2],
                THEME.borderStrong[3], THEME.borderStrong[4]
            )
            self.label:SetTextColor(1, 1, 1)
            self.activeLine:Show()
        else
            self:SetBackdropColor(
                THEME.surface[1], THEME.surface[2],
                THEME.surface[3], THEME.surface[4]
            )
            self:SetBackdropBorderColor(
                THEME.border[1], THEME.border[2],
                THEME.border[3], THEME.border[4]
            )
            self.label:SetTextColor(
                THEME.muted[1], THEME.muted[2], THEME.muted[3]
            )
            self.activeLine:Hide()
        end
    end
    button:SetActive(false)
    return button
end

local function CreateModernCheckbox(parent, x, y)
    local checkbox = CreateFrame("CheckButton", nil, parent)
    checkbox:SetWidth(20)
    checkbox:SetHeight(20)
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    ApplyModernBackdrop(checkbox, THEME.surface, THEME.borderStrong, 6)

    local checked = CreateSolidTexture(
        checkbox, "ARTWORK",
        THEME.gold[1], THEME.gold[2], THEME.gold[3], 1
    )
    checked:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 5, -5)
    checked:SetPoint("BOTTOMRIGHT", checkbox, "BOTTOMRIGHT", -5, 5)
    checkbox:SetCheckedTexture(checked)

    local highlight = CreateSolidTexture(
        checkbox, "HIGHLIGHT",
        THEME.teal[1], THEME.teal[2], THEME.teal[3], 0.20
    )
    highlight:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 3, -3)
    highlight:SetPoint("BOTTOMRIGHT", checkbox, "BOTTOMRIGHT", -3, 3)
    checkbox:SetHighlightTexture(highlight)
    return checkbox
end

local function SetFeedback(text, isError)
    if not feedbackText then return end
    feedbackText:SetText(Color(isError and "red" or "green", text or ""))
end

local function RefreshLanguageButtons()
    local selected = Advisor.GetLanguage and Advisor.GetLanguage() or "fr"
    for language, button in pairs(languageButtons) do
        local active = language == selected
        button:SetAlpha(active and 1 or 0.58)
        if active then
            button:SetBackdropBorderColor(
                THEME.gold[1], THEME.gold[2], THEME.gold[3], 1
            )
        else
            button:SetBackdropBorderColor(
                THEME.borderStrong[1], THEME.borderStrong[2],
                THEME.borderStrong[3], THEME.borderStrong[4]
            )
        end
    end
end

local function SelectLanguage(language)
    if Advisor.GetLanguage and Advisor.GetLanguage() == language then return end
    if Advisor.SetLanguage then Advisor.SetLanguage(language, true) end
end

local function GetProfile()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local key = CoAAnalyticsAdvisorDB and CoAAnalyticsAdvisorDB.profile or "bg"
    local contentMode = Advisor.GetSelectedContentMode and
        Advisor.GetSelectedContentMode() or "pvp"
    return Advisor.Data.NormalizeProfileKey(
        key,
        classProfile,
        contentMode
    )
end

local function EnsureTalentHighlighter()
    if talentHighlighter then return talentHighlighter end

    talentHighlighter = CreateFrame(
        "Frame",
        "CoAAnalyticsAdvisorTalentHighlighter",
        UIParent
    )
    talentHighlighter:SetWidth(72)
    talentHighlighter:SetHeight(72)
    talentHighlighter:SetFrameStrata("TOOLTIP")
    talentHighlighter:SetFrameLevel(250)
    talentHighlighter:Hide()

    local glow = talentHighlighter:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints(talentHighlighter)
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    talentHighlighter.glow = glow

    local label = talentHighlighter:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )
    label:SetPoint("BOTTOM", talentHighlighter, "TOP", 0, 1)
    talentHighlighter.label = label

    talentHighlighter:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        self:SetAlpha(0.55 + math.abs(math.sin(self.elapsed * 4)) * 0.45)
        if self.elapsed >= 8 then self:Hide() end
    end)
    return talentHighlighter
end

local function HighlightTalent(recommendation, priority)
    if not recommendation or not recommendation.globalName then return end
    local target = _G[recommendation.globalName]
    local visible
    if target and type(target.IsVisible) == "function" then
        visible = Advisor.SafeCall(target.IsVisible, target)
    elseif target and type(target.IsShown) == "function" then
        visible = Advisor.SafeCall(target.IsShown, target)
    end
    if not visible then
        SetFeedback(
            "Ouvre les arbres de talents de classe et de spécialisation, puis clique à nouveau.",
            true
        )
        return
    end

    local highlighter = EnsureTalentHighlighter()
    local color = PRIORITY_COLORS[priority] or PRIORITY_COLORS[1]
    local width = tonumber(Advisor.SafeCall(target.GetWidth, target)) or 42
    local height = tonumber(Advisor.SafeCall(target.GetHeight, target)) or 42
    local size = math.max(width, height) + 28
    highlighter:SetWidth(size)
    highlighter:SetHeight(size)
    highlighter:ClearAllPoints()
    highlighter:SetPoint("CENTER", target, "CENTER", 0, 0)
    highlighter.glow:SetVertexColor(color[1], color[2], color[3])
    highlighter.label:SetText(
        "#" .. tostring(priority) .. "  " .. recommendation.name
    )
    highlighter.label:SetTextColor(color[1], color[2], color[3])
    highlighter.elapsed = 0
    highlighter:SetAlpha(1)
    highlighter:Show()
    SetFeedback(
        "Le choix #" .. tostring(priority) ..
        " clignote maintenant dans l’arbre pendant 8 secondes."
    )
end

local function ClearRecommendedTalentHighlights(silent)
    for _, highlighter in ipairs(talentBuildHighlighters) do
        highlighter:Hide()
        highlighter.target = nil
    end
    talentBuildHighlighters = {}
    highlightedTalentBuildMode = nil
    if talentBuildButton then
        local mode = Advisor.GetSelectedContentMode and
            Advisor.GetSelectedContentMode() or "pvp"
        talentBuildButton:SetText(
            mode == "pve" and "Surligner build Mythic+" or
            "Surligner build BG"
        )
    end
    if not silent then
        SetFeedback("Surlignage du build masqué.")
    end
end

local function CreateRecommendedTalentHighlighter(target, recommendation)
    local highlighter = CreateFrame("Frame", nil, UIParent)
    local width = tonumber(Advisor.SafeCall(target.GetWidth, target)) or 42
    local height = tonumber(Advisor.SafeCall(target.GetHeight, target)) or 42
    local size = math.max(width, height) + 18
    highlighter:SetWidth(size)
    highlighter:SetHeight(size)
    highlighter:SetFrameStrata("TOOLTIP")
    highlighter:SetFrameLevel(240)
    highlighter:SetPoint("CENTER", target, "CENTER", 0, 0)
    highlighter:EnableMouse(false)
    highlighter.target = target

    local glow = highlighter:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints(highlighter)
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    highlighter.glow = glow

    local badge = highlighter:CreateFontString(
        nil, "OVERLAY", "GameFontNormalSmall"
    )
    badge:SetPoint("BOTTOM", highlighter, "BOTTOM", 0, 2)
    highlighter.badge = badge

    local wantedRank = tonumber(recommendation.rank) or 1
    local currentRank = tonumber(recommendation.currentRank) or 0
    local complete = currentRank >= wantedRank
    local flexible = recommendation.kind == "flex"
    local color
    if recommendation.remove then
        color = { 1.00, 0.20, 0.20 }
        badge:SetText("X")
        complete = false
    elseif complete then
        color = { 0.20, 1.00, 0.35 }
        badge:SetText("OK")
    elseif flexible then
        color = { 0.20, 0.75, 1.00 }
        badge:SetText("F " .. tostring(wantedRank))
    else
        color = { 1.00, 0.78, 0.10 }
        badge:SetText(tostring(wantedRank))
    end
    if recommendation.root then badge:SetText("") end
    glow:SetVertexColor(color[1], color[2], color[3])
    badge:SetTextColor(color[1], color[2], color[3])
    highlighter.complete = complete
    highlighter.elapsed = 0
    highlighter:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        local visible = self.target and
            Advisor.SafeCall(self.target.IsVisible, self.target)
        if not visible then
            self:SetAlpha(0)
        elseif self.complete then
            self:SetAlpha(0.82)
        else
            self:SetAlpha(
                0.55 + math.abs(math.sin(self.elapsed * 3.5)) * 0.45
            )
        end
    end)
    highlighter:Show()
    return highlighter
end

local function ReadFrameBounds(frame)
    if not frame then return nil end
    local visible = Advisor.SafeCall(frame.IsVisible, frame)
    if not visible then return nil end
    local centerX, centerY = Advisor.SafeCall(frame.GetCenter, frame)
    local width = tonumber(Advisor.SafeCall(frame.GetWidth, frame)) or 0
    local height = tonumber(Advisor.SafeCall(frame.GetHeight, frame)) or 0
    if not centerX or not centerY or width <= 0 or height <= 0 then return nil end
    return {
        left = centerX - width / 2,
        right = centerX + width / 2,
        bottom = centerY - height / 2,
        top = centerY + height / 2,
        width = width,
        height = height,
    }
end

local function ChoiceRootOverlap(left, right)
    local overlapX = math.min(left.right, right.right) -
        math.max(left.left, right.left)
    local overlapY = math.min(left.top, right.top) -
        math.max(left.bottom, right.bottom)
    if overlapX <= 0 or overlapY <= 0 then return false end

    -- Choice talents are separate CoA buttons drawn on top of the same node.
    -- Requiring a meaningful overlap prevents adjacent tree nodes from being
    -- mistaken for the common root.
    return overlapX >= math.min(left.width, right.width) * 0.20 and
        overlapY >= math.min(left.height, right.height) * 0.20
end

local function FindChoiceRootTargets(talent, target)
    local roots = {}
    local seen = { [target] = true }
    local targetBounds = ReadFrameBounds(target)
    if not targetBounds then return roots end

    for _, candidate in ipairs(Advisor.TalentScanner.cache.all or {}) do
        if candidate ~= talent and candidate.tree == talent.tree and
            candidate.globalName then
            local candidateTarget = _G[candidate.globalName]
            if candidateTarget and not seen[candidateTarget] then
                local candidateBounds = ReadFrameBounds(candidateTarget)
                if candidateBounds and
                    ChoiceRootOverlap(targetBounds, candidateBounds) then
                    seen[candidateTarget] = true
                    roots[#roots + 1] = candidateTarget
                end
            end
        end
    end
    return roots
end

local function FindRecommendedTalent(name, wanted)
    wanted = wanted or {}
    local talent = Advisor.TalentScanner.GetTalent(name, wanted.spellID)
    if talent then return talent end

    for _, alias in ipairs(wanted.aliases or {}) do
        talent = Advisor.TalentScanner.GetTalent(alias)
        if talent then return talent end
    end

    local needle = wanted.descriptionContains and
        string.lower(wanted.descriptionContains) or nil
    if needle then
        for _, candidate in ipairs(
            Advisor.TalentScanner.cache.all or {}
        ) do
            local description = string.lower(candidate.description or "")
            if string.find(description, needle, 1, true) then
                return candidate
            end
        end
    end
    return nil
end

local function HighlightRecommendedTalentBuild()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local mode = Advisor.GetSelectedContentMode and
        Advisor.GetSelectedContentMode() or "pvp"
    local build = Advisor.Data.GetRecommendedTalentBuild and
        Advisor.Data.GetRecommendedTalentBuild(classProfile, mode)
    if not build then
        SetFeedback(
            "Aucun build complet publié pour cette spécialisation.", true
        )
        return
    end
    if highlightedTalentBuildMode == mode and
        #talentBuildHighlighters > 0 then
        ClearRecommendedTalentHighlights(false)
        return
    end

    ClearRecommendedTalentHighlights(true)
    Advisor.TalentScanner.Refresh(false)
    local found, visibleCount, completeCount, missingCount, flexCount,
        removeCount = 0, 0, 0, 0, 0, 0
    local highlightedTargets = {}
    for name, wanted in pairs(build.talents or {}) do
        local talent = FindRecommendedTalent(name, wanted)
        if talent and talent.globalName then
            found = found + 1
            local target = _G[talent.globalName]
            if target then
                local visible = Advisor.SafeCall(target.IsVisible, target)
                if visible then visibleCount = visibleCount + 1 end
                local display = {
                    rank = math.min(
                        tonumber(wanted.rank) or 1,
                        tonumber(talent.maxRank) or tonumber(wanted.rank) or 1
                    ),
                    currentRank = talent.rank,
                    kind = wanted.kind,
                }
                local highlighter = CreateRecommendedTalentHighlighter(
                    target, display
                )
                talentBuildHighlighters[#talentBuildHighlighters + 1] =
                    highlighter
                highlightedTargets[target] = true
                for _, rootTarget in ipairs(
                    FindChoiceRootTargets(talent, target)
                ) do
                    if not highlightedTargets[rootTarget] then
                        highlightedTargets[rootTarget] = true
                        talentBuildHighlighters[#talentBuildHighlighters + 1] =
                            CreateRecommendedTalentHighlighter(rootTarget, {
                                rank = display.rank,
                                currentRank = display.currentRank,
                                kind = display.kind,
                                root = true,
                            })
                    end
                end
                if (tonumber(display.currentRank) or 0) >= display.rank then
                    completeCount = completeCount + 1
                elseif display.kind == "flex" then
                    flexCount = flexCount + 1
                else
                    missingCount = missingCount + 1
                end
            end
        end
    end
    for name in pairs(build.excluded or {}) do
        local talent = Advisor.TalentScanner.GetTalent(name)
        if talent and (tonumber(talent.rank) or 0) > 0 and talent.globalName then
            local target = _G[talent.globalName]
            if target then
                found = found + 1
                local visible = Advisor.SafeCall(target.IsVisible, target)
                if visible then visibleCount = visibleCount + 1 end
                talentBuildHighlighters[#talentBuildHighlighters + 1] =
                    CreateRecommendedTalentHighlighter(target, {
                        rank = 1,
                        currentRank = talent.rank,
                        remove = true,
                    })
                removeCount = removeCount + 1
            end
        end
    end

    if found == 0 or visibleCount == 0 then
        ClearRecommendedTalentHighlights(true)
        SetFeedback(
            "Ouvre les deux arbres de Character Advancement, puis clique à nouveau.",
            true
        )
        return
    end

    highlightedTalentBuildMode = mode
    if talentBuildButton then talentBuildButton:SetText("Masquer le build") end
    SetFeedback(
        build.label .. " : vert = déjà pris (" .. tostring(completeCount) ..
        "), or = requis manquant (" .. tostring(missingCount) ..
        "), bleu F = choix flexible (" .. tostring(flexCount) ..
        "), rouge X = à retirer (" .. tostring(removeCount) .. ")."
    )
end

local function HideTalentCards()
    for _, card in ipairs(talentCards) do
        card.recommendation = nil
        card:Hide()
    end
end

local function RefreshProfileButtons()
    local selected = GetProfile()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local contentMode = Advisor.GetSelectedContentMode and
        Advisor.GetSelectedContentMode() or "pvp"
    for index, button in ipairs(profileButtons) do
        local key = classProfile and classProfile.profileOrder[index]
        local profile = key and Advisor.Data.GetProfile(
            key,
            classProfile,
            contentMode
        )
        button.profileKey = key
        if profile then
            button:SetText(profile.shortLabel or profile.label)
            button:Enable()
            button:Show()
        else
            button:SetText("Indisponible")
            button:Disable()
        end
        if key and key == selected then
            button:LockHighlight()
            button:GetFontString():SetTextColor(1, 0.82, 0.2)
        else
            button:UnlockHighlight()
            button:GetFontString():SetTextColor(1, 1, 1)
        end
    end
end

local function RefreshContentModeButtons()
    local selected = Advisor.GetSelectedContentMode and
        Advisor.GetSelectedContentMode() or "pvp"
    local classProfile = Advisor.Data.GetActiveClassProfile()
    for mode, button in pairs(contentModeButtons) do
        local context = Advisor.Data.GetContext(classProfile, mode)
        if context then
            button:SetText(context.label)
            button:Enable()
            button:Show()
        else
            button:Disable()
            button:Hide()
        end
        if context and mode == selected then
            button:LockHighlight()
            button:GetFontString():SetTextColor(1, 0.82, 0.2)
        else
            button:UnlockHighlight()
            button:GetFontString():SetTextColor(1, 1, 1)
        end
    end
end

local function RefreshTalentBuildButton()
    if not talentBuildButton then return end
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local mode = Advisor.GetSelectedContentMode and
        Advisor.GetSelectedContentMode() or "pvp"
    local build = Advisor.Data.GetRecommendedTalentBuild and
        Advisor.Data.GetRecommendedTalentBuild(classProfile, mode)
    if build then
        talentBuildButton:Enable()
        talentBuildButton:Show()
        talentBuildButton:SetText(
            highlightedTalentBuildMode == mode and "Masquer le build" or
            (mode == "pve" and "Surligner build Mythic+" or
                "Surligner build BG")
        )
    else
        talentBuildButton:Disable()
        talentBuildButton:Hide()
    end
end

local function RefreshStatus()
    if not statusText then return end
    if not Advisor.IsSupportedCharacter() then
        local className = UnitClass("player") or "Cette classe"
        statusText:SetText(
            Color("gray", className .. " n'a pas encore de profil de recommandations. ") ..
            Color("blue", "Utilise l'onglet DataProbe pour aider à le construire.")
        )
        return
    end
    local character = Advisor.CharacterScanner.Get()
    if not character or not character.level then
        statusText:SetText(Color("gray", "Aucun scan disponible. Clique sur Analyser maintenant."))
        return
    end

    local equipmentCount = Advisor.TableCount(character.equipment or {})
    local selectedCount = #(Advisor.TalentScanner.cache.selected or {})
    local talentCount = #(Advisor.TalentScanner.cache.all or {})
    local talentStatus
    if talentCount == 0 then
        talentStatus = Color("red", "talents non détectés")
    else
        talentStatus = Color("green", selectedCount .. " talents sélectionnés")
    end

    local classProfile = Advisor.Data.GetActiveClassProfile()
    local contentMode = Advisor.GetSelectedContentMode and
        Advisor.GetSelectedContentMode() or "pvp"
    local context = Advisor.Data.GetContext(classProfile, contentMode)
    local contextLabel = context and context.label or contentMode
    if classProfile.model == "ranger_archery" then
        statusText:SetText(
            Color("white", "Niveau " .. tostring(character.level)) ..
            "  •  Agilité " .. tostring(character.agility or 0) ..
            "  •  PA distance " ..
            tostring(character.rangedAttackPower or 0) ..
            "  •  Crit distance " ..
            tostring(Advisor.Round(character.rangedCritChance or 0, 2)) ..
            "%  •  " .. tostring(contextLabel) ..
            "\nHâte distance : " ..
            tostring(Advisor.Round(character.rangedHasteBonus or 0, 2)) ..
            "%  •  Focus : " ..
            tostring(character.power and character.power.current or 0) ..
            "/" ..
            tostring(character.power and character.power.maximum or 0) ..
            "  •  " .. equipmentCount .. " objets  •  " .. talentStatus
        )
    elseif classProfile.model == "time_healer" then
        statusText:SetText(
            Color("white", "Niveau " .. tostring(character.level)) ..
            "  •  Esprit " .. tostring(character.spirit or 0) ..
            "  •  Soins " .. tostring(character.healing or 0) ..
            "  •  Critique " ..
            tostring(Advisor.Round(character.critChance or 0, 2)) ..
            "%  •  " .. tostring(contextLabel) .. "\n" ..
            "Mana/5 s : " ..
            tostring(Advisor.Round((character.manaRegen or 0) * 5, 1)) ..
            " hors incantation, " ..
            tostring(
                Advisor.Round((character.manaRegenCasting or 0) * 5, 1)
            ) ..
            " en incantation  •  " .. equipmentCount ..
            " objets  •  " .. talentStatus
        )
    else
        local availableCount = 0
        for _, talent in ipairs(Advisor.TalentScanner.cache.all or {}) do
            if talent.available and talent.rank < talent.maxRank then
                availableCount = availableCount + 1
            end
        end
        statusText:SetText(
            Color("white", classProfile.title) ..
            "  •  Niveau " .. tostring(character.level) ..
            "  •  " .. equipmentCount .. " objets\n" ..
            talentStatus .. "  •  " ..
            Color(
                availableCount > 0 and "green" or "gold",
                tostring(availableCount) ..
                " talent(s) achetable(s) détecté(s)"
            )
        )
    end
end

local function RefreshTalents()
    if not talentText then return end
    HideTalentCards()
    if #(Advisor.TalentScanner.cache.all or {}) == 0 then
        talentText:Show()
        talentText:SetText(
            Color("red", "Talents indisponibles. ") ..
            "Ouvre les arbres de classe et de spécialisation, laisse-les visibles, puis analyse."
        )
        return
    end
    if Advisor.TalentScanner.cache.availabilityVersion ~= 2 then
        talentText:Show()
        talentText:SetText(
            Color("red", "Accessibilité non vérifiée. ") ..
            "Ouvre les arbres de talents et relance l’analyse."
        )
        return
    end

    local recommendations = Advisor.TalentScanner.GetRecommendations(GetProfile())
    if #recommendations == 0 then
        talentText:Show()
        talentText:SetText(
            Color("gold", "Aucun talent réellement achetable détecté. ") ..
            "Vérifie qu’un point est disponible, ouvre les deux arbres, " ..
            "puis clique sur Actualiser."
        )
        return
    end

    talentText:Hide()
    for index = 1, math.min(3, #recommendations) do
        local result = recommendations[index]
        local card = talentCards[index]
        if card then
            local color = PRIORITY_COLORS[index] or PRIORITY_COLORS[1]
            card.recommendation = result
            card.priority = index
            card.icon:SetTexture(
                result.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
            )
            card.nameText:SetText(result.name)
            card.nameText:SetTextColor(color[1], color[2], color[3])
            card.rankText:SetText(
                tostring(result.nextRank) .. "/" ..
                tostring(result.maxRank) .. "  •  " ..
                tostring(Advisor.Round(result.score, 1)) .. "/10"
            )
            card.priorityText:SetText("#" .. tostring(index))
            card.priorityText:SetTextColor(color[1], color[2], color[3])
            card:SetBackdropBorderColor(color[1], color[2], color[3], 0.95)
            card:Show()
        end
    end
end

local function RefreshCombat()
    if not combatText then return end
    local classProfile = Advisor.Data.GetActiveClassProfile()
    local summary = Advisor.LocalAnalyzer and
        Advisor.LocalAnalyzer.GetSummary(classProfile)
    if not summary then return end

    if localAnalysisToggleButton then
        localAnalysisToggleButton:SetText(
            summary.enabled and "Analyse locale : ON" or
            "Analyse locale : OFF"
        )
        localAnalysisToggleButton:GetFontString():SetTextColor(
            summary.enabled and 0.3 or 1,
            summary.enabled and 1 or 0.35,
            summary.enabled and 0.45 or 0.35
        )
    end

    if not summary.enabled then
        combatText:SetText(
            Color("gold",
                "Analyse locale arrêtée. Aucun combat n’est observé."
            )
        )
        if localSuggestionButton then
            localSuggestionButton:SetText("Analyse désactivée")
            localSuggestionButton:Disable()
        end
        return
    end

    local confidence =
        summary.confidence == "high" and "fiabilité élevée" or
        summary.confidence == "medium" and "fiabilité moyenne" or
        summary.confidence == "low" and "première tendance" or
        "échantillon insuffisant"
    local extra = ""
    if summary.role == "HEALER" and summary.averageEndMana then
        extra =
            "  •  Mana finale moyenne " ..
            tostring(Advisor.Round(summary.averageEndMana * 100, 0)) .. "%"
    elseif classProfile.model == "ranger_archery" and
        summary.averageEndResource then
        extra =
            "  •  Focus final moyen " ..
            tostring(
                Advisor.Round(summary.averageEndResource * 100, 0)
            ) .. "%  •  Focus sous 20% : " ..
            tostring(
                Advisor.Round(summary.lowResourceTimeRate * 100, 0)
            ) .. "% du temps"
    end
    if summary.overhealRate then
        extra = extra .. "  •  Soins excédentaires " ..
            tostring(Advisor.Round(summary.overhealRate * 100, 0)) .. "%"
    end
    combatText:SetText(
        Color("white",
            tostring(summary.fights) .. " combats  •  " ..
            tostring(Advisor.Round(summary.deathRate * 100, 0)) ..
            "% de morts"
        ) ..
        "\n" .. Color("gray",
            summary.dominantModeLabel .. "  •  " .. confidence .. extra
        ) ..
        "\n" .. tostring(summary.reason or "")
    )

    if localSuggestionButton then
        if summary.hasSuggestion and summary.suggestedProfile then
            localSuggestionButton:SetText(
                "Appliquer : " ..
                tostring(
                    summary.suggestedProfile.shortLabel or
                    summary.suggestedProfile.label
                )
            )
            localSuggestionButton:Enable()
        elseif summary.fights < 5 then
            localSuggestionButton:SetText("Minimum : 5 combats")
            localSuggestionButton:Disable()
        else
            localSuggestionButton:SetText("Priorité déjà adaptée")
            localSuggestionButton:Disable()
        end
    end
end

local function RefreshAdviceButton()
    if not adviceButton then return end
    if not Advisor.IsItemSupportedCharacter() then
        adviceButton:SetText("Équipement non calibré")
        adviceButton:GetFontString():SetTextColor(0.7, 0.7, 0.7)
        adviceButton:Disable()
        return
    end
    adviceButton:Enable()
    local enabled = not CoAAnalyticsAdvisorDB or CoAAnalyticsAdvisorDB.enabled ~= false
    if enabled then
        adviceButton:SetText("Conseils d’objets : ACTIVÉS")
        adviceButton:GetFontString():SetTextColor(0.3, 1, 0.45)
    else
        adviceButton:SetText("Conseils d’objets : DÉSACTIVÉS")
        adviceButton:GetFontString():SetTextColor(1, 0.35, 0.35)
    end
end

local function RefreshAutoGreedLootButton()
    if not autoGreedLootButton then return end
    local enabled = Advisor.LootAdvisor and
        Advisor.LootAdvisor.IsAutoGreedEnabled()
    autoGreedLootButton:SetText(
        enabled and
        "Jets automatiques : CUPIDITÉ" or
        "Jets automatiques : SIGNALER"
    )
    autoGreedLootButton:GetFontString():SetTextColor(
        enabled and 0.3 or 1,
        enabled and 1 or 0.78,
        enabled and 0.45 or 0.2
    )
    for key, checkbox in pairs(autoLootStatChecks) do
        checkbox:SetChecked(
            Advisor.LootAdvisor.IsStatExcluded and
            Advisor.LootAdvisor.IsStatExcluded(key) or false
        )
    end
    if autoLootStatusText and Advisor.LootAdvisor.GetExcludedStatLabels then
        local labels = Advisor.LootAdvisor.GetExcludedStatLabels()
        if not enabled then
            autoLootStatusText:SetText(
                Color("gray", "Automatisation désactivée. ") ..
                "Les cases sont conservées, mais aucun jet automatique " ..
                "n’est effectué."
            )
        elseif #labels == 0 then
            autoLootStatusText:SetText(
                Color("green", "Aucune statistique exclue. ") ..
                "Seuls les matériaux sûrs et les équipements incompatibles " ..
                "confirmés utilisent automatiquement Cupidité."
            )
        else
            autoLootStatusText:SetText(
                Color("red", "FILTRE STRICT ACTIF : ") ..
                "Cupidité automatique si l’objet contient au moins une de ces stats :\n" ..
                Color("gold", table.concat(labels, ", "))
            )
        end
    end
end

function UI.Refresh()
    RefreshLanguageButtons()
    local classProfile = Advisor.Data.GetActiveClassProfile()
    if advisorTabButton then
        advisorTabButton:SetText(
            classProfile and
            ("Conseils  •  " ..
                tostring(classProfile.shortTitle or classProfile.title)) or
            "Conseils de spécialisation"
        )
    end
    if profileDescriptionText then
        local contentMode = Advisor.GetSelectedContentMode and
            Advisor.GetSelectedContentMode() or "pvp"
        local context = Advisor.Data.GetContext(classProfile, contentMode)
        if context then
            local details = context.description ..
                "\nPriorité : " ..
                tostring(context.priority or "non publiée")
            local research = classProfile and classProfile.guideResearch
            local tiers = classProfile and classProfile.contentTiers
            if research and research.build then
                details = details ..
                    "\nBuild de base vérifié : 26 points de classe + " ..
                    "25 points de spécialisation. Confiance contextuelle : moyenne."
                if research.buildHub then
                    details = details ..
                        "\nBuildHub indexé : " ..
                        tostring(research.buildHub.buildCount or 0) ..
                        " build(s) public(s) pour cette spécialisation."
                end
            elseif classProfile and classProfile.guideCoverage then
                details = details ..
                    "\nGuide : " ..
                    tostring(classProfile.guideCoverage) ..
                    "% complet. Le reste doit être mesuré avec DataProbe."
            end
            if tiers then
                details = details ..
                    "\nRepères : Donjon " .. tostring(tiers.dungeon or "?") ..
                    " • Raid " .. tostring(tiers.raid or "?") ..
                    " • Arène " .. tostring(tiers.arena or "?") ..
                    " • BG " .. tostring(tiers.battleground or "?") .. "."
            end
            profileDescriptionText:SetText(
                details ..
                " Les boutons règlent ensuite l'objectif du score."
            )
        else
            profileDescriptionText:SetText(
                classProfile and classProfile.priorityDescription or
                "Ce profil sera disponible après analyse des données."
            )
        end
    end
    if itemDescriptionText then
        itemDescriptionText:SetText(
            classProfile and Advisor.IsItemSupportedCharacter() and
            ("Survole simplement un objet. " ..
                classProfile.itemDescription ..
                " Les effets inconnus restent signalés.") or
            "Les talents sont disponibles, mais les objets ne seront activés " ..
            "qu'après calibration fiable de cette spécialisation."
        )
    end
    if combatDescriptionText then
        combatDescriptionText:SetText(
            "Analyse privée et automatique : fins de combat, mana et morts. " ..
            "L’addon conseille une priorité, mais ne la change jamais sans ton clic. " ..
            "Les tooltips d’objets utilisent directement les besoins détectés."
        )
    end
    if resetCombatButton then resetCombatButton:Enable() end
    RefreshStatus()
    if Advisor.IsSupportedCharacter() then
        RefreshTalents()
        RefreshCombat()
    else
        HideTalentCards()
        if talentText then
            talentText:Show()
            talentText:SetText(
                Color("gray",
                    "Les recommandations de talents ne sont pas encore " ..
                    "disponibles pour cette spécialisation."
                )
            )
        end
        if combatText then
            combatText:SetText(
                Color("gray",
                    "Le modèle de recommandations sera ajouté après " ..
                    "analyse des sessions DataProbe."
                )
            )
        end
    end
    RefreshAdviceButton()
    RefreshAutoGreedLootButton()
    RefreshContentModeButtons()
    RefreshProfileButtons()
    RefreshTalentBuildButton()
    if UI.RefreshDataProbe then UI.RefreshDataProbe() end
end

function UI.RefreshIfVisible()
    if mainFrame and mainFrame:IsShown() then
        UI.Refresh()
    end
end

function UI.IsVisible()
    return mainFrame and mainFrame:IsShown() or false
end

local function RunScan()
    if Advisor.Actions and Advisor.Actions.Scan then
        Advisor.Actions.Scan(false)
        UI.Refresh()
        if #(Advisor.TalentScanner.cache.all or {}) == 0 then
            SetFeedback(
                "Scan terminé, mais les talents manquent. Ouvre leur page et recommence.",
                true
            )
        else
            SetFeedback("Analyse terminée : statistiques, équipement et talents actualisés.")
        end
    end
end

local function RecalculateTalents()
    RunScan()
    local recommendations =
        Advisor.TalentScanner.GetRecommendations(GetProfile())
    if recommendations[1] then
        HighlightTalent(recommendations[1], 1)
    else
        SetFeedback(
            "Aucun talent accessible ne dépasse le seuil de recommandation. " ..
            "Les choix situationnels ne sont plus présentés comme optimaux.",
            true
        )
    end
end

local function SelectProfile(key)
    if Advisor.Actions and Advisor.Actions.SetProfile then
        Advisor.Actions.SetProfile(key, false)
        UI.Refresh()
        local classProfile = Advisor.Data.GetActiveClassProfile()
        local profile = Advisor.Data.GetProfile(key, classProfile)
        SetFeedback("Profil appliqué : " .. profile.label .. ".")
    end
end

local function SelectContentMode(mode)
    if Advisor.Actions and Advisor.Actions.SetContentMode then
        ClearRecommendedTalentHighlights(true)
        Advisor.Actions.SetContentMode(mode, false)
        UI.Refresh()
        local classProfile = Advisor.Data.GetActiveClassProfile()
        local context = Advisor.Data.GetContext(classProfile, mode)
        SetFeedback(
            "Contexte appliqué : " ..
            tostring(context and context.label or mode) ..
            ". Les objets et talents sont recalculés."
        )
    end
end

local function ToggleAdvice()
    local enabled = not CoAAnalyticsAdvisorDB or CoAAnalyticsAdvisorDB.enabled ~= false
    if Advisor.Actions and Advisor.Actions.SetEnabled then
        Advisor.Actions.SetEnabled(not enabled, false)
    end
    UI.Refresh()
    SetFeedback(
        not enabled and
        "Les recommandations apparaîtront maintenant dans les tooltips." or
        "Les recommandations de tooltip sont maintenant masquées."
    )
end

local function ToggleAutoGreedLoot()
    local enabled = Advisor.LootAdvisor and
        Advisor.LootAdvisor.IsAutoGreedEnabled()
    if Advisor.Actions and Advisor.Actions.SetAutoGreedIncompatibleLoot then
        Advisor.Actions.SetAutoGreedIncompatibleLoot(not enabled, false)
    end
    UI.Refresh()
    SetFeedback(
        not enabled and
        "Cupidité automatique activée pour le butin incompatible confirmé et les matériaux sûrs." or
        "Cupidité automatique désactivée. Les objets incompatibles restent signalés en rouge."
    )
end

local function ResetCombat()
    if Advisor.Actions and Advisor.Actions.ResetLocalAnalysis then
        Advisor.Actions.ResetLocalAnalysis(false)
    end
    UI.Refresh()
    SetFeedback("L’analyse locale de cette spécialisation a été effacée.")
end

StaticPopupDialogs["COA_ANALYTICS_ADVISOR_RESET_COMBAT"] = {
    text = Localized("Effacer l’analyse locale de cette spécialisation ?"),
    button1 = Localized("Effacer"),
    button2 = Localized("Annuler"),
    OnAccept = ResetCombat,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function ToggleLocalAnalysis()
    local enabled = Advisor.LocalAnalyzer.IsEnabled()
    Advisor.Actions.SetLocalAnalysis(not enabled, false)
    UI.Refresh()
    SetFeedback(
        enabled and
        "Analyse locale automatique arrêtée." or
        "Analyse locale automatique activée."
    )
end

local function ApplyLocalSuggestion()
    if Advisor.Actions.ApplyLocalSuggestion(false) then
        UI.Refresh()
        SetFeedback("La priorité conseillée localement a été appliquée.")
    else
        SetFeedback("Aucun changement local à appliquer.", true)
    end
end

local function CreateTalentCard(parent, priority, x)
    local color = PRIORITY_COLORS[priority] or PRIORITY_COLORS[1]
    local card = CreateFrame("Button", nil, parent)
    card:SetWidth(204)
    card:SetHeight(52)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -67)
    ApplyModernBackdrop(card, THEME.surface, color, 8)
    card:SetBackdropBorderColor(color[1], color[2], color[3], 0.95)

    local accent = CreateSolidTexture(
        card, "ARTWORK", color[1], color[2], color[3], 1
    )
    accent:SetPoint("TOPLEFT", card, "TOPLEFT", 3, -3)
    accent:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 3, 3)
    accent:SetWidth(3)

    local highlight = card:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(card)
    highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlight:SetVertexColor(
        THEME.teal[1], THEME.teal[2], THEME.teal[3], 0.14
    )

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(38)
    icon:SetHeight(38)
    icon:SetPoint("LEFT", card, "LEFT", 7, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card.icon = icon

    local iconBorder = card:CreateTexture(nil, "OVERLAY")
    iconBorder:SetWidth(46)
    iconBorder:SetHeight(46)
    iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
    iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    iconBorder:SetBlendMode("ADD")
    iconBorder:SetVertexColor(color[1], color[2], color[3])

    local nameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOPLEFT", card, "TOPLEFT", 51, -8)
    nameText:SetWidth(128)
    nameText:SetHeight(17)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    card.nameText = nameText

    local rankText = card:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    rankText:SetPoint("TOPLEFT", card, "TOPLEFT", 51, -29)
    rankText:SetWidth(120)
    rankText:SetJustifyH("LEFT")
    card.rankText = rankText

    local priorityText = card:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )
    priorityText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -6, -5)
    priorityText:SetText("#" .. tostring(priority))
    priorityText:SetTextColor(color[1], color[2], color[3])
    card.priorityText = priorityText

    card:SetScript("OnEnter", function(self)
        local result = self.recommendation
        if not result then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(
            "#" .. tostring(self.priority) .. "  " .. result.name,
            color[1], color[2], color[3]
        )
        AddTooltipLine(GameTooltip,
            "Rang actuel : " .. tostring(result.rank) .. "/" ..
            tostring(result.maxRank) .. "  →  prochain : " ..
            tostring(result.nextRank) .. "/" .. tostring(result.maxRank),
            1, 1, 1
        )
        AddTooltipDoubleLine(GameTooltip,
            "Score — " .. tostring(result.profileLabel),
            tostring(Advisor.Round(result.score, 1)) .. "/10",
            1, 0.82, 0.2,
            1, 1, 1
        )
        AddTooltipLine(GameTooltip, result.reason, 0.8, 0.8, 0.8, true)
        AddTooltipLine(GameTooltip, result.profileReason, 0.35, 0.85, 1, true)
        AddTooltipLine(GameTooltip, " ")
        AddTooltipDoubleLine(GameTooltip,
            "Rendement",
            "+" .. tostring(Advisor.Round(
                result.components and result.components.throughput or 0, 1
            ))
        )
        AddTooltipDoubleLine(GameTooltip,
            "Ressource / autonomie",
            "+" .. tostring(Advisor.Round(
                result.components and result.components.sustain or 0, 1
            ))
        )
        AddTooltipDoubleLine(GameTooltip,
            "Survie",
            "+" .. tostring(Advisor.Round(
                result.components and result.components.survival or 0, 1
            ))
        )
        AddTooltipDoubleLine(GameTooltip,
            "Utilité",
            "+" .. tostring(Advisor.Round(
                result.components and result.components.utility or 0, 1
            ))
        )
        if result.situational then
            AddTooltipLine(GameTooltip,
                "Situationnel : utile dans certains matchs, moins universel.",
                1, 0.55, 0.15, true
            )
        end
        local confidenceText =
            result.confidence == "high" and "élevée" or
            result.confidence == "medium" and "moyenne" or "provisoire"
        AddTooltipDoubleLine(GameTooltip,
            "Fiabilité de l’analyse",
            confidenceText,
            0.65, 0.65, 0.65,
            result.confidence == "high" and 0.3 or 1,
            result.confidence == "high" and 1 or 0.82,
            0.3
        )
        AddTooltipLine(GameTooltip, " ")
        AddTooltipLine(GameTooltip,
            "Clique pour faire clignoter ce talent dans l’arbre.",
            0.35, 0.85, 1, true
        )
        GameTooltip:Show()
    end)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    card:SetScript("OnClick", function(self)
        GameTooltip:Hide()
        HighlightTalent(self.recommendation, self.priority)
    end)
    card:Hide()
    return card
end

local function DataProbeIdentity(status)
    local session = status and (status.current or status.latest)
    local identity = session and session.identity
    if not identity then
        local className = UnitClass("player")
        return className or "Classe non détectée", "spécialisation non détectée"
    end
    local specialization = identity.specialization or {}
    return identity.class or identity.classToken or "Classe inconnue",
        specialization.name or
        ("spécialisation " .. tostring(
            specialization.id or specialization.active or "?"
        ))
end

local function DataProbeTalentSummary(status)
    local session = status and (status.current or status.latest)
    local snapshots = session and session.snapshots or {}
    for index = #snapshots, 1, -1 do
        local talents = snapshots[index].talents
        if talents then
            return #(talents.all or {}), #(talents.selected or {})
        end
    end
    return 0, 0
end

local function CoveragePercent(value)
    value = tonumber(value) or 0
    if value >= 75 then
        return Color("green", tostring(value) .. "%")
    elseif value >= 45 then
        return Color("gold", tostring(value) .. "%")
    end
    return Color("red", tostring(value) .. "%")
end

local function RefreshCoverage()
    if not coverageSummaryText then return end
    local coverage
    if Advisor.CommunityData then
        coverage = Advisor.CommunityData.GetCoverage()
    else
        coverage = { profiles = {} }
    end
    coverageProfiles = coverage.profiles or {}
    local pageSize = #coverageRows
    local pageCount = math.max(
        1,
        math.ceil(#coverageProfiles / math.max(1, pageSize))
    )
    coveragePage = Advisor.Clamp(coveragePage, 1, pageCount)

    if coverageTitleText then
        coverageTitleText:SetText("Couverture communautaire publiée")
    end
    if coverageListTitleText then
        coverageListTitleText:SetText(
            "Progression globale intégrée à cette version"
        )
    end

    if #coverageProfiles == 0 then
        coverageSummaryText:SetText(
            Color("red", "Aucune donnée communautaire publiée.")
        )
    else
        coverageSummaryText:SetText(
            Color("white",
                tostring(coverage.guideProfiles or #coverageProfiles) ..
                " profils guide publiés"
            ) ..
            "  •  " .. tostring(coverage.dataProbeProfiles or 0) ..
            " avec DataProbe communautaire  •  " ..
            tostring(coverage.averageCoverage or 0) ..
            "% de complétion moyenne\n" ..
            tostring(coverage.contributors or 0) ..
            " contributeur(s)  •  " ..
            tostring(coverage.sourceFiles or 0) .. " fichier(s)\n" ..
            "Mise à jour : " .. tostring(coverage.updatedAt or "?") ..
            " avec CoA Analytics " ..
            tostring(coverage.addonVersion or "?") ..
            ". Mise à jour uniquement entre les versions."
        )
    end

    for index, row in ipairs(coverageRows) do
        local profileIndex = (coveragePage - 1) * pageSize + index
        local profile = coverageProfiles[profileIndex]
        row.profile = profile
        if profile then
            row.nameText:SetText(
                profile.className .. " — " .. profile.specializationName
            )
            row.percentText:SetText(
                CoveragePercent(profile.totalCoverage)
            )
            row.detailText:SetText(
                "Guide " .. tostring(profile.guideCoverage or 0) ..
                "%  •  Build " .. tostring(profile.buildCoverage) ..
                "%  •  Équip. " ..
                tostring(profile.equipmentCoverage) ..
                "%  •  PvP " ..
                tostring(profile.pvpCombatCoverage or 0) ..
                "%  •  PvE " ..
                tostring(profile.pveCombatCoverage or 0) .. "%"
            )
            row.bar:SetMinMaxValues(0, 100)
            row.bar:SetValue(profile.totalCoverage)
            if profile.totalCoverage >= 75 then
                row.bar:SetStatusBarColor(0.20, 0.85, 0.35)
            elseif profile.totalCoverage >= 45 then
                row.bar:SetStatusBarColor(1, 0.72, 0.10)
            else
                row.bar:SetStatusBarColor(0.90, 0.22, 0.18)
            end
            row:Show()
        else
            row:Hide()
        end
    end
    if coveragePageText then
        coveragePageText:SetText(
            "Page " .. tostring(coveragePage) .. "/" .. tostring(pageCount)
        )
    end
end

local function SelectDataProbeSubTab(tab)
    if tab == "community" then
        activeDataProbeSubTab = "community"
    else
        activeDataProbeSubTab = "collect"
    end
    local collectVisible = activeDataProbeSubTab == "collect"
    if dataProbeCollectionPanel then
        if collectVisible then
            dataProbeCollectionPanel:Show()
        else
            dataProbeCollectionPanel:Hide()
        end
    end
    if dataProbeCoveragePanel then
        if collectVisible then
            dataProbeCoveragePanel:Hide()
        else
            dataProbeCoveragePanel:Show()
        end
    end
    if dataProbeCollectTabButton then
        dataProbeCollectTabButton:SetActive(collectVisible)
    end
    if dataProbeCommunityTabButton then
        dataProbeCommunityTabButton:SetActive(
            activeDataProbeSubTab == "community"
        )
    end
    if not collectVisible then
        coveragePage = 1
        RefreshCoverage()
    end
end

function UI.RefreshDataProbe()
    if not dataProbeStatusText or not Advisor.DataProbe then return end
    local status = Advisor.DataProbe.GetStatus()
    local className, specializationName = DataProbeIdentity(status)
    local talentCount, selectedTalentCount =
        DataProbeTalentSummary(status)
    if status.enabled then
        dataProbeStatusText:SetText(
            Color("green", "ÉTAPE 1 TERMINÉE — COLLECTE ACTIVE, CONTEXTE AUTO") ..
            "\n" .. Color("white", className .. " — " .. specializationName) ..
            "\nPasse à l'étape 2 : ouvre les deux arbres puis clique Capturer."
        )
        dataProbeToggleButton:SetText("ARRÊTER LA COLLECTE")
        dataProbeToggleButton:GetFontString():SetTextColor(1, 0.35, 0.35)
        if dataProbeCaptureButton then dataProbeCaptureButton:Enable() end
        if dataProbeCaptureButton then
            dataProbeCaptureButton:SetText(
                "ARBRES OUVERTS — CAPTURER LE BUILD"
            )
        end
        if dataProbeNewSessionButton then dataProbeNewSessionButton:Enable() end
    else
        dataProbeStatusText:SetText(
            Color("gold", "ÉTAPE 1 — DÉMARRE UNE SESSION") ..
            "\nAucune donnée détaillée destinée à la communauté n’est collectée " ..
            "avant " .. Color("green", "DÉMARRER UNE SESSION") ..
            ".\n" ..
            "Une nouvelle session efface l'archive précédente, même si elle " ..
            "n'a pas encore été envoyée."
        )
        dataProbeToggleButton:SetText("DÉMARRER UNE SESSION")
        dataProbeToggleButton:GetFontString():SetTextColor(0.35, 1, 0.45)
        if dataProbeCaptureButton then dataProbeCaptureButton:Disable() end
        if dataProbeCaptureButton then
            dataProbeCaptureButton:SetText(
                "D'ABORD : DÉMARRER UNE SESSION"
            )
        end
        if dataProbeNewSessionButton then dataProbeNewSessionButton:Disable() end
    end

    if dataProbeProgressText then
        if status.archiveLoaded == false then
            dataProbeProgressText:SetText(
                Color("gray",
                    "Archive en veille : elle n'est pas chargée en mémoire " ..
                    "tant que DataProbe reste OFF.\nDémarre une session ou " ..
                    "clique Exporter pour charger les compteurs."
                )
            )
        else
            local modes = status.detectedModes or {}
            dataProbeProgressText:SetText(
                Color("white", tostring(status.sessions) .. " session(s)") ..
                "  •  " .. tostring(status.snapshots) .. " captures" ..
                "  •  " .. tostring(status.observations) .. " infobulles uniques\n" ..
                tostring(status.fights) .. " combats  •  " ..
                tostring(status.combatEvents) .. " événements  •  " ..
                tostring(status.resourceSamples) .. " échantillons de ressource\n" ..
                "Contexte auto : " ..
                tostring(modes.bg or 0) .. " PvP  •  " ..
                tostring(modes.pve or 0) .. " donjon/raid  •  " ..
                tostring(modes.leveling or 0) .. " monde  •  " ..
                tostring(modes.unknown or 0) .. " à vérifier\n" ..
                (talentCount > 0 and
                    Color("green",
                        tostring(talentCount) .. " talents détectés, " ..
                        tostring(selectedTalentCount) .. " sélectionnés"
                    ) or
                    Color("red",
                        "Talents non détectés : ouvre les arbres puis capture."
                    ))
            )
        end
    end
    if dataProbeExportButton then
        dataProbeExportButton:SetText(
            status.enabled and
            "Terminer + exporter" or
            "Exporter l'archive"
        )
    end
    if dataProbeTabButton then
        dataProbeTabButton:SetText(
            status.enabled and "DataProbe  |cff48df74ON|r" or
            "DataProbe  |cffff6060OFF|r"
        )
    end
    if activeDataProbeSubTab == "community" then
        RefreshCoverage()
    end
end

local function SelectMainTab(tab)
    if tab == "dataprobe" or tab == "autoloot" then
        activeMainTab = tab
    else
        activeMainTab = "advisor"
    end
    local advisorVisible = activeMainTab == "advisor"
    local autoLootVisible = activeMainTab == "autoloot"
    local dataProbeVisible = activeMainTab == "dataprobe"
    for _, widget in ipairs(advisorWidgets) do
        if advisorVisible then widget:Show() else widget:Hide() end
    end
    if dataProbePanel then
        if dataProbeVisible then dataProbePanel:Show() else dataProbePanel:Hide() end
    end
    if autoLootPanel then
        if autoLootVisible then autoLootPanel:Show() else autoLootPanel:Hide() end
    end
    if advisorTabButton then
        advisorTabButton:SetActive(advisorVisible)
    end
    if dataProbeTabButton then
        dataProbeTabButton:SetActive(dataProbeVisible)
    end
    if autoLootTabButton then
        autoLootTabButton:SetActive(autoLootVisible)
    end
    UI.Refresh()
end

local function ToggleExcludedLootStat(key, checkbox)
    if not Advisor.LootAdvisor or
        not Advisor.LootAdvisor.SetStatExcluded then
        return
    end
    Advisor.LootAdvisor.SetStatExcluded(
        key,
        checkbox and checkbox:GetChecked() and true or false
    )
    UI.Refresh()
end

local function ResetExcludedLootStats()
    if Advisor.LootAdvisor and Advisor.LootAdvisor.ResetExcludedStats then
        Advisor.LootAdvisor.ResetExcludedStats()
    end
    UI.Refresh()
end

local function ToggleDataProbe()
    local enabled = Advisor.DataProbe.IsEnabled()
    Advisor.DataProbe.SetEnabled(not enabled, true)
    UI.RefreshDataProbe()
end

local function CaptureDataProbe()
    local snapshot =
        Advisor.DataProbe.CaptureSnapshot("guided-button", true, true)
    if snapshot and snapshot.talents and
        #(snapshot.talents.all or {}) == 0 then
        Advisor.Print(
            "DataProbe : aucun talent détecté. Ouvre l'arbre de classe " ..
            "et de spécialisation, puis capture à nouveau."
        )
    end
    UI.RefreshDataProbe()
end

local function NewDataProbeSession()
    if Advisor.DataProbe.NewSession() then
        Advisor.Print(
            "DataProbe : autre build ajouté au même fichier final. " ..
            "Les scans déjà collectés sont conservés."
        )
    end
    UI.RefreshDataProbe()
end

StaticPopupDialogs["COA_ANALYTICS_ADVISOR_RESET_DATA_PROBE"] = {
    text = Localized("Effacer définitivement toutes les sessions DataProbe enregistrées ?"),
    button1 = Localized("Tout effacer"),
    button2 = Localized("Annuler"),
    OnAccept = function()
        Advisor.DataProbe.ResetArchive()
        UI.RefreshDataProbe()
        Advisor.Print("DataProbe : toutes les archives ont été effacées.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function CreateCoverageRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -31 - (index - 1) * 34)
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, -31 - (index - 1) * 34)
    row:SetHeight(31)

    local nameText = row:CreateFontString(
        nil, "OVERLAY", "GameFontNormalSmall"
    )
    LocalizeTextRegion(nameText)
    nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 3, -2)
    nameText:SetWidth(330)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    local percentText = row:CreateFontString(
        nil, "OVERLAY", "GameFontNormal"
    )
    percentText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -3, -1)
    row.percentText = percentText

    local detailText = row:CreateFontString(
        nil, "OVERLAY", "GameFontHighlightSmall"
    )
    LocalizeTextRegion(detailText)
    detailText:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 3, 5)
    detailText:SetWidth(520)
    detailText:SetJustifyH("LEFT")
    detailText:SetTextColor(0.70, 0.74, 0.80)
    row.detailText = detailText

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 3, 0)
    bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -3, 0)
    bar:SetHeight(3)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    row.bar = bar

    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        local profile = self.profile
        if not profile then return end
        local publishedProfile = profile.guideCoverage ~= nil
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        AddTooltipLine(GameTooltip,
            profile.className .. " — " .. profile.specializationName,
            1, 0.82, 0.2
        )
        AddTooltipDoubleLine(GameTooltip,
            "Couverture totale",
            tostring(profile.totalCoverage) .. "%",
            1, 1, 1, 1, 1, 1
        )
        AddTooltipLine(GameTooltip, " ")
        if publishedProfile then
            AddTooltipDoubleLine(GameTooltip,
                "Guide publié (poids 25 %)",
                tostring(profile.guideCoverage) .. "%"
            )
        end
        AddTooltipDoubleLine(GameTooltip,
            publishedProfile and
                "DataProbe build (poids 20 %)" or
                "Build : talents, sorts, stats (poids 30 %)",
            tostring(profile.buildCoverage) .. "%"
        )
        AddTooltipDoubleLine(GameTooltip,
            publishedProfile and
                "DataProbe équipement (poids 20 %)" or
                "Équipement : changements, objets (poids 30 %)",
            tostring(profile.equipmentCoverage) .. "%"
        )
        if publishedProfile then
            AddTooltipDoubleLine(GameTooltip,
                "DataProbe combat PvP (poids 15 %)",
                tostring(profile.pvpCombatCoverage) .. "%"
            )
            AddTooltipDoubleLine(GameTooltip,
                "DataProbe combat PvE (poids 15 %)",
                tostring(profile.pveCombatCoverage) .. "%"
            )
        else
            AddTooltipDoubleLine(GameTooltip,
                "Combat : événements, ressources",
                tostring(profile.combatCoverage) .. "%"
            )
        end
        AddTooltipDoubleLine(GameTooltip,
            publishedProfile and
                "Variété DataProbe (poids 5 %)" or
                "Variété : sessions, niveaux, contenus (poids 10 %)",
            tostring(profile.varietyCoverage) .. "%"
        )
        AddTooltipLine(GameTooltip, " ")
        AddTooltipLine(GameTooltip,
            tostring(profile.sessions) .. " session(s), " ..
            tostring(profile.snapshots) .. " captures, " ..
            tostring(profile.fights) .. " combats",
            0.75, 0.78, 0.84, true
        )
        if profile.contributors then
            AddTooltipDoubleLine(GameTooltip,
                "Contributeurs distincts",
                tostring(profile.contributors)
            )
        end
        if profile.modelStatus then
            AddTooltipDoubleLine(GameTooltip,
                "État du modèle",
                tostring(profile.modelStatus)
            )
        end
        if profile.nextNeed then
            AddTooltipLine(GameTooltip, " ")
            AddTooltipLine(GameTooltip,
                "Collectes encore utiles",
                1, 0.82, 0.2
            )
            if type(profile.needs) == "table" then
                for index = 1, math.min(5, #profile.needs) do
                    AddTooltipLine(GameTooltip,
                        "• " .. tostring(profile.needs[index]),
                        index == 1 and 0.75 or 0.68,
                        index == 1 and 0.85 or 0.74,
                        index == 1 and 1 or 0.82,
                        true
                    )
                end
            else
                AddTooltipLine(GameTooltip,
                    tostring(profile.nextNeed),
                    0.75, 0.85, 1, true
                )
            end
        end
        AddTooltipLine(GameTooltip,
            "Le total mesure la complétion du profil, pas une précision garantie.",
            1, 0.55, 0.15, true
        )
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

local function BuildCoveragePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    local summarySection = CreateSection(panel, -2, 82)
    coverageTitleText = CreateText(
        summarySection, "GameFontNormal",
        "Couverture communautaire publiée", 12, -10, 520
    )
    coverageSummaryText = CreateText(
        summarySection, "GameFontHighlightSmall", "", 12, -32, 548
    )

    local listSection = CreateSection(panel, -92, 260)
    coverageListTitleText = CreateText(
        listSection, "GameFontNormal",
        "Progression globale intégrée à cette version", 12, -10, 500
    )
    for index = 1, 6 do
        coverageRows[index] = CreateCoverageRow(listSection, index)
    end
    local previousButton = CreateButton(
        listSection, "Page précédente", 130, 22,
        "BOTTOMLEFT", listSection, "BOTTOMLEFT", 12, 5
    )
    previousButton:SetScript("OnClick", function()
        coveragePage = math.max(1, coveragePage - 1)
        RefreshCoverage()
    end)
    local nextButton = CreateButton(
        listSection, "Page suivante", 130, 22,
        "BOTTOMRIGHT", listSection, "BOTTOMRIGHT", -12, 5
    )
    nextButton:SetScript("OnClick", function()
        coveragePage = coveragePage + 1
        RefreshCoverage()
    end)
    coveragePageText = CreateText(
        listSection, "GameFontHighlightSmall", "Page 1/1",
        235, -235, 110, "CENTER"
    )

    local explanationSection = CreateSection(panel, -360, 205)
    CreateText(
        explanationSection, "GameFontNormal",
        "Comment ces données améliorent réellement les recommandations", 12, -10, 560
    )
    CreateText(
        explanationSection, "GameFontHighlightSmall",
        Color("blue", "SCAN DU BUILD ET DE L'ÉQUIPEMENT — 60 % de la couverture") ..
        "\nLe fichier révèle les talents, sorts, coefficients visibles, conversions de stats, " ..
        "objets scalés et emplacements. Il sert à construire le modèle et à éviter les erreurs " ..
        "de parsing. Sans combat, les recommandations fonctionnent mais leurs poids restent provisoires.",
        12, -33, 548
    )
    CreateText(
        explanationSection, "GameFontHighlightSmall",
        Color("green", "COMPORTEMENT EN COMBAT — 30 % de la couverture") ..
        "\nLes événements et ressources montrent la rotation réelle, les sorts dominants, le manque " ..
        "de mana/Focus, les critiques, ratés, déplacements et dégâts reçus. Ils calibrent la valeur " ..
        "de hâte, critique, sustain et survie pour BG ou donjon.",
        12, -101, 548
    )
    CreateText(
        explanationSection, "GameFontHighlightSmall",
        Color("gold", "VARIÉTÉ — 10 %") ..
        "  Plusieurs niveaux, builds et types de contenu évitent de sur-optimiser un seul personnage.\n" ..
        Color("gray",
            "La progression communautaire fusionne manuellement les archives reçues " ..
            "et est publiée avec chaque nouvelle version."
        ),
        12, -169, 548
    )
    panel:Hide()
    return panel
end

local function BuildCollectionPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    local statusSection = CreateSection(panel, -2, 132)
    CreateText(
        statusSection, "GameFontNormal",
        "1. Prépare une contribution communautaire", 12, -10, 360
    )
    dataProbeStatusText = CreateText(
        statusSection, "GameFontHighlightSmall", "", 12, -32, 360
    )
    dataProbeToggleButton = CreateButton(
        statusSection, "", 190, 32,
        "TOPRIGHT", statusSection, "TOPRIGHT", -13, -16
    )
    dataProbeToggleButton:SetScript("OnClick", ToggleDataProbe)
    CreateText(
        statusSection, "GameFontHighlightSmall",
        Color("blue", "Détection automatique : ") ..
        "BG, arène, donjon, raid, monde et PvP sauvage sont classés " ..
        "séparément pour chaque combat.",
        12, -90, 548
    )

    local instructionsSection = CreateSection(panel, -142, 250)
    CreateText(
        instructionsSection, "GameFontNormal",
        "2. Capture le build avant de jouer", 12, -10, 330
    )
    CreateText(
        instructionsSection, "GameFontHighlightSmall",
        "A. Ouvre Character Advancement.\n" ..
        "B. Affiche successivement l'arbre de classe et l'arbre de spécialisation.\n" ..
        "C. Laisse la fenêtre ouverte et clique le bouton à droite.",
        12, -32, 340
    )
    dataProbeCaptureButton = CreateButton(
        instructionsSection, "D'ABORD : DÉMARRER UNE SESSION", 220, 34,
        "TOPRIGHT", instructionsSection, "TOPRIGHT", -13, -20
    )
    dataProbeCaptureButton:SetScript("OnClick", CaptureDataProbe)
    CreateText(
        instructionsSection, "GameFontHighlightSmall",
        Color("gold", "3. Survole ce qui décrit la spécialisation") ..
        "\n• Les talents choisis et envisagés, puis les sorts importants du spellbook et des barres.\n" ..
        "• Tout l'équipement et plusieurs objets candidats, avec la comparaison visible.\n" ..
        "• Retire un seul objet, attends 2 s, remets-le, attends 2 s. Répète avec Agilité, " ..
        "Spirit, critique, hâte, PA/SP, Stamina ou Resilience selon la classe.\n\n" ..
        Color("gold", "4. Joue normalement") ..
        "\n• Même build pendant 3–5 BG ou au moins 10 combats de donjon/leveling.\n" ..
        "• DataProbe conserve localement sorts, dégâts, soins, ressources, critiques, ratés et auras.",
        12, -92, 548
    )
    CreateText(
        instructionsSection, "GameFontHighlightSmall",
        Color("blue", "OPTIONNEL — AUTRE BUILD : ") ..
        "ajoute une nouvelle série au même fichier final.\n" ..
        "Les scans déjà collectés sont conservés ; rien n'est effacé.",
        12, -207, 430
    )
    dataProbeNewSessionButton = CreateButton(
        instructionsSection, "AJOUTER AU MÊME FICHIER", 220, 30,
        "BOTTOMRIGHT", instructionsSection, "BOTTOMRIGHT", -12, 10
    )
    dataProbeNewSessionButton:SetScript("OnClick", NewDataProbeSession)

    local progressSection = CreateSection(panel, -400, 92)
    CreateText(
        progressSection, "GameFontNormal",
        "5. Vérifie les données disponibles", 12, -10, 520
    )
    dataProbeProgressText = CreateText(
        progressSection, "GameFontHighlightSmall", "", 12, -32, 548
    )

    local exportSection = CreateSection(panel, -500, 105)
    CreateText(
        exportSection, "GameFontNormal",
        "6. Termine et partage le fichier", 12, -10, 350
    )
    CreateText(
        exportSection, "GameFontHighlightSmall",
        "L'export arrête la collecte puis recharge l'interface. Envoie ensuite :\n" ..
        "WTF\\Account\\TON_COMPTE\\SavedVariables\\CoAAnalytics_DataProbe.lua\n" ..
        "Aucun envoi automatique ; noms anonymisés et identifiant de contributeur aléatoire.",
        12, -31, 355
    )
    dataProbeExportButton = CreateButton(
        exportSection, "Terminer + exporter", 190, 30,
        "TOPRIGHT", exportSection, "TOPRIGHT", -13, -17
    )
    dataProbeExportButton:SetScript("OnClick", function()
        Advisor.DataProbe.Export()
    end)
    local resetButton = CreateButton(
        exportSection, "Effacer toutes les archives", 190, 26,
        "BOTTOMRIGHT", exportSection, "BOTTOMRIGHT", -13, 13
    )
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("COA_ANALYTICS_ADVISOR_RESET_DATA_PROBE")
    end)
    return panel
end

local function BuildDataProbePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -101)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 9)

    dataProbeCollectTabButton = CreateTab(
        panel, "1  •  Export", 280,
        "TOPLEFT", panel, "TOPLEFT", 67, -2
    )
    dataProbeCollectTabButton:SetScript("OnClick", function()
        SelectDataProbeSubTab("collect")
    end)
    dataProbeCommunityTabButton = CreateTab(
        panel, "2  •  Communauté", 280,
        "TOPLEFT", dataProbeCollectTabButton, "TOPRIGHT", 6, 0
    )
    dataProbeCommunityTabButton:SetScript("OnClick", function()
        SelectDataProbeSubTab("community")
    end)

    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -40)
    content:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    dataProbeCollectionPanel = BuildCollectionPanel(content)
    dataProbeCoveragePanel = BuildCoveragePanel(content)
    SelectDataProbeSubTab(activeDataProbeSubTab)
    panel:Hide()
    return panel
end

local function BuildAutoLootPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -101)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 9)

    local masterSection = CreateSection(panel, -5, 120)
    CreateText(
        masterSection, "GameFontNormal",
        "1. Activer les jets automatiques", 12, -10, 330
    )
    CreateText(
        masterSection, "GameFontHighlightSmall",
        "Cupidité automatique pour les matériaux sûrs, les équipements " ..
        "incompatibles confirmés et les statistiques exclues ci-dessous. " ..
        "La liaison est confirmée uniquement pour un jet lancé par CoA Analytics.",
        12, -34, 375
    )
    autoGreedLootButton = CreateButton(
        masterSection, "Jets automatiques : SIGNALER", 205, 30,
        "TOPRIGHT", masterSection, "TOPRIGHT", -14, -18
    )
    autoGreedLootButton:SetScript("OnClick", ToggleAutoGreedLoot)

    local statsSection = CreateSection(panel, -134, 365)
    CreateText(
        statsSection, "GameFontNormal",
        "2. Statistiques à exclure pour ce personnage", 12, -10, 340
    )
    CreateText(
        statsSection, "GameFontHighlightSmall",
        "Coche une statistique seulement si tu ne veux jamais faire Besoin " ..
        "sur un équipement qui la contient. Une seule correspondance suffit " ..
        "pour choisir Cupidité, même si l’objet est portable.",
        12, -32, 565
    )

    local options = Advisor.LootAdvisor and
        Advisor.LootAdvisor.GetExcludableStats and
        Advisor.LootAdvisor.GetExcludableStats() or {}
    for index, option in ipairs(options) do
        local column = math.floor((index - 1) / 9)
        local row = (index - 1) % 9
        local x = 18 + column * 300
        local y = -88 - row * 29
        local checkbox = CreateModernCheckbox(statsSection, x, y)
        checkbox.statKey = option.key
        checkbox:SetScript("OnClick", function(self)
            ToggleExcludedLootStat(self.statKey, self)
        end)
        CreateText(
            statsSection, "GameFontHighlightSmall",
            option.label, x + 27, y - 2, 255
        )
        autoLootStatChecks[option.key] = checkbox
    end

    local statusSection = CreateSection(panel, -508, 132)
    CreateText(
        statusSection, "GameFontNormal",
        "3. Résumé du filtre", 12, -10, 300
    )
    autoLootStatusText = CreateText(
        statusSection, "GameFontHighlightSmall", "", 12, -34, 400
    )
    local resetButton = CreateButton(
        statusSection, "Tout décocher", 155, 28,
        "TOPRIGHT", statusSection, "TOPRIGHT", -14, -18
    )
    resetButton:SetScript("OnClick", ResetExcludedLootStats)
    CreateText(
        statusSection, "GameFontHighlightSmall",
        Color("red", "Attention : ") ..
        "Endurance, Intelligence et Résilience sont fréquentes. Les exclure " ..
        "peut envoyer en Cupidité des améliorations utiles.",
        12, -84, 560
    )

    panel:Hide()
    return panel
end

local function Build(parent)
    if mainFrame then return mainFrame end

    embeddedMode = parent ~= nil
    mainFrame = CreateFrame(
        "Frame",
        "CoAAnalyticsAdvisorPanel",
        parent or UIParent
    )
    if embeddedMode then
        mainFrame:SetAllPoints(parent)
    else
        mainFrame:SetWidth(700)
        mainFrame:SetHeight(760)
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
        mainFrame:SetFrameStrata("DIALOG")
        mainFrame:SetToplevel(true)
        mainFrame:SetMovable(true)
        mainFrame:EnableMouse(true)
        mainFrame:RegisterForDrag("LeftButton")
        mainFrame:SetClampedToScreen(true)
        mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        ApplyModernBackdrop(mainFrame, THEME.window, THEME.borderStrong, 12)
    end
    mainFrame:Hide()

    local titleAccent = CreateSolidTexture(
        mainFrame, "ARTWORK",
        THEME.teal[1], THEME.teal[2], THEME.teal[3], 1
    )
    titleAccent:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 18, -55)
    titleAccent:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -18, -55)
    titleAccent:SetHeight(1)

    local close = CreateButton(
        mainFrame, "X", 22, 22,
        "TOPRIGHT", mainFrame, "TOPRIGHT", -10, -10
    )
    close:GetFontString():SetTextColor(1, 0.35, 0.28)
    close:SetScript("OnClick", function()
        if embeddedMode and CoAAnalyticsAddon.Modules.UI then
            CoAAnalyticsAddon.Modules.UI.Toggle()
        else
            mainFrame:Hide()
        end
    end)

    for index, language in ipairs({ "fr", "en" }) do
        local selectedLanguage = language
        local button = CreateLanguageFlagButton(
            mainFrame, language, -48 - (2 - index) * 38
        )
        button:SetScript("OnClick", function()
            SelectLanguage(selectedLanguage)
        end)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            AddTooltipLine(
                GameTooltip,
                "Langue de l’interface uniquement. Le parseur conserve les tooltips anglais.",
                1, 1, 1, true
            )
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        languageButtons[language] = button
    end
    if embeddedMode then
        close:Hide()
        for _, button in pairs(languageButtons) do
            button:Hide()
        end
    end

    local title = CreateText(
        mainFrame, "GameFontNormalLarge",
        "Conseils de personnage", 22, -16
    )
    title:SetTextColor(1, 0.82, 0.2)
    local version = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    version:SetPoint("LEFT", title, "RIGHT", 8, -1)
    version:SetText("v" .. tostring(Advisor.version or "3.0.0"))
    local subtitle = CreateText(
        mainFrame, "GameFontDisableSmall",
        "Recommandations de classe et collecte communautaire DataProbe",
        22, -38, 530, "LEFT"
    )
    subtitle:SetTextColor(0.62, 0.66, 0.72)

    advisorTabButton = CreateTab(
        mainFrame, "Conseils", 205,
        "TOPLEFT", mainFrame, "TOPLEFT", 34, -66
    )
    advisorTabButton:SetScript("OnClick", function()
        SelectMainTab("advisor")
    end)
    autoLootTabButton = CreateTab(
        mainFrame, "Jets automatiques", 205,
        "TOPLEFT", advisorTabButton, "TOPRIGHT", 6, 0
    )
    autoLootTabButton:SetScript("OnClick", function()
        SelectMainTab("autoloot")
    end)
    dataProbeTabButton = CreateTab(
        mainFrame, "DataProbe  OFF", 205,
        "TOPLEFT", autoLootTabButton, "TOPRIGHT", 6, 0
    )
    dataProbeTabButton:SetScript("OnClick", function()
        SelectMainTab("dataprobe")
    end)
    if embeddedMode then
        advisorTabButton:Hide()
        autoLootTabButton:Hide()
        dataProbeTabButton:Hide()
    end

    local scanSection = CreateSection(mainFrame, -106, 118)
    advisorWidgets[#advisorWidgets + 1] = scanSection
    CreateText(
        scanSection, "GameFontNormal",
        "1. Actualiser les données", 12, -10, 360
    )
    CreateText(
        scanSection, "GameFontHighlightSmall",
        "À utiliser après la connexion, un changement de niveau, de talents ou d’équipement. " ..
        "Pour détecter les talents, ouvre les arbres de classe et de spécialisation.",
        12, -31, 390
    )
    local scanButton = CreateButton(
        scanSection, "Analyser maintenant", 165, 30,
        "TOPRIGHT", scanSection, "TOPRIGHT", -13, -16
    )
    scanButton:SetScript("OnClick", RunScan)
    statusText = CreateText(
        scanSection, "GameFontHighlightSmall", "", 12, -76, 548
    )

    local talentSection = CreateSection(mainFrame, -232, 125)
    advisorWidgets[#advisorWidgets + 1] = talentSection
    CreateText(
        talentSection, "GameFontNormal",
        "2. Talents conseillés", 12, -10, 315
    )
    CreateText(
        talentSection, "GameFontHighlightSmall",
        "Le profil choisi à l’étape 3 reclasse immédiatement tous les talents " ..
        "réellement achetables. Surligne aussi le build complet PvE ou PvP dans l’arbre.",
        12, -31, 320
    )
    local talentButton = CreateButton(
        talentSection, "Actualiser + repérer #1", 170, 30,
        "TOPRIGHT", talentSection, "TOPRIGHT", -13, -16
    )
    talentButton:SetScript("OnClick", RecalculateTalents)
    talentBuildButton = CreateButton(
        talentSection, "Surligner build BG", 170, 30,
        "TOPRIGHT", talentButton, "TOPLEFT", -6, 0
    )
    talentBuildButton:SetScript("OnClick", HighlightRecommendedTalentBuild)
    talentText = CreateText(
        talentSection, "GameFontHighlightSmall", "", 12, -72, 548
    )
    for priority = 1, 3 do
        talentCards[priority] =
            CreateTalentCard(talentSection, priority, 12 + (priority - 1) * 214)
    end

    local profileSection = CreateSection(mainFrame, -365, 147)
    advisorWidgets[#advisorWidgets + 1] = profileSection
    CreateText(
        profileSection, "GameFontNormal",
        "3. Contexte et priorité", 12, -10, 300
    )
    for index, mode in ipairs({ "pvp", "pve" }) do
        local selectedMode = mode
        local button = CreateButton(
            profileSection, "", 108, 22,
            "TOPRIGHT", profileSection, "TOPRIGHT",
            -13 - (2 - index) * 112, -7
        )
        button:SetScript("OnClick", function()
            SelectContentMode(selectedMode)
        end)
        contentModeButtons[selectedMode] = button
    end
    profileDescriptionText = CreateText(
        profileSection, "GameFontHighlightSmall",
        "",
        12, -37, 548
    )

    for index = 1, 4 do
        local button = CreateButton(
            profileSection, "", 158, 28,
            "BOTTOMLEFT", profileSection, "BOTTOMLEFT",
            12 + (index - 1) * 161, 12
        )
        button:SetScript("OnClick", function(self)
            if self.profileKey then SelectProfile(self.profileKey) end
        end)
        profileButtons[index] = button
    end

    local itemSection = CreateSection(mainFrame, -520, 83)
    advisorWidgets[#advisorWidgets + 1] = itemSection
    CreateText(
        itemSection, "GameFontNormal",
        "4. Comparer l’équipement", 12, -10, 300
    )
    itemDescriptionText = CreateText(
        itemSection, "GameFontHighlightSmall",
        "",
        12, -31, 390
    )
    adviceButton = CreateButton(
        itemSection, "", 190, 24,
        "TOPRIGHT", itemSection, "TOPRIGHT", -13, -8
    )
    adviceButton:SetScript("OnClick", ToggleAdvice)
    local combatSection = CreateSection(mainFrame, -611, 128)
    advisorWidgets[#advisorWidgets + 1] = combatSection
    combatTitleText = CreateText(
        combatSection, "GameFontNormal",
        "5. Analyse locale automatique", 12, -10, 280
    )
    combatDescriptionText = CreateText(
        combatSection, "GameFontHighlightSmall",
        "",
        12, -31, 410
    )
    localSuggestionButton = CreateButton(
        combatSection, "Minimum : 5 combats", 175, 24,
        "TOPRIGHT", combatSection, "TOPRIGHT", -13, -9
    )
    localSuggestionButton:SetScript("OnClick", ApplyLocalSuggestion)
    localAnalysisToggleButton = CreateButton(
        combatSection, "Analyse locale : ON", 175, 24,
        "TOPRIGHT", combatSection, "TOPRIGHT", -13, -43
    )
    localAnalysisToggleButton:SetScript("OnClick", ToggleLocalAnalysis)
    resetCombatButton = CreateButton(
        combatSection, "Effacer l’historique local", 175, 24,
        "TOPRIGHT", combatSection, "TOPRIGHT", -13, -77
    )
    resetCombatButton:SetScript("OnClick", function()
        StaticPopup_Show("COA_ANALYTICS_ADVISOR_RESET_COMBAT")
    end)
    combatText = CreateText(
        combatSection, "GameFontHighlightSmall", "", 12, -78, 410
    )

    feedbackText = CreateText(
        mainFrame, "GameFontHighlightSmall",
        "Astuce : déplace le bouton de minimap en le faisant glisser.",
        22, -746, 656, "CENTER"
    )
    advisorWidgets[#advisorWidgets + 1] = feedbackText

    dataProbePanel = BuildDataProbePanel(mainFrame)
    autoLootPanel = BuildAutoLootPanel(mainFrame)

    mainFrame:SetScript("OnShow", function()
        SelectMainTab(activeMainTab)
        UI.Refresh()
    end)
    if not embeddedMode and type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "CoAAnalyticsAdvisorPanel")
    end

    return mainFrame
end

function UI.Initialize()
    if mainFrame then UI.Refresh() end
    return true
end

function UI.Attach(parent)
    if not parent then return nil end
    Build(parent)
    mainFrame:Show()
    SelectMainTab(activeMainTab)
    UI.Refresh()
    return mainFrame
end

function UI.SelectTab(tab)
    if not mainFrame then return false end
    SelectMainTab(tab)
    UI.Refresh()
    return true
end

function UI.Show(tab)
    local analyticsUI = CoAAnalyticsAddon
        and CoAAnalyticsAddon.Modules
        and CoAAnalyticsAddon.Modules.UI
    if analyticsUI and analyticsUI.Open then
        local section = tab == "autoloot" and "loot"
            or tab == "dataprobe" and "collection"
            or "advisor"
        analyticsUI.Open(section)
        return
    end
    Build()
    if tab then SelectMainTab(tab) end
    mainFrame:Show()
    UI.Refresh()
end

function UI.ShowDataProbe()
    UI.Show("dataprobe")
end

function UI.Hide()
    if mainFrame then mainFrame:Hide() end
end

function UI.Toggle()
    local analyticsUI = CoAAnalyticsAddon
        and CoAAnalyticsAddon.Modules
        and CoAAnalyticsAddon.Modules.UI
    if analyticsUI and analyticsUI.Toggle then
        analyticsUI.Toggle("advisor")
        return
    end
    UI.Show("advisor")
end
