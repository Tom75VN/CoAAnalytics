local API = CoAAnalyticsAPI
local Module = {}
CoAAnalyticsAddon.Modules.MythicReset = Module

local WEEK_SECONDS = 7 * 24 * 60 * 60
local MAX_RESET_SECONDS = 8 * 24 * 60 * 60
local COUNTER_OBSERVATION_WINDOW = 8 * 60 * 60

local driver = CreateFrame("Frame")
local addonDB
local resetDB
local initialized = false

local function Chat(message)
	local chatFrame = DEFAULT_CHAT_FRAME or ChatFrame1
	if chatFrame then
		chatFrame:AddMessage("|cff00ba79CoA Analytics:|r " .. tostring(message))
	end
end

local function GetServerEpoch()
	if type(GetServerTime) == "function" then
		local ok, value = pcall(GetServerTime)
		if ok and type(value) == "number" and value > 0 then
			return value
		end
	end
	if type(time) == "function" then
		return time()
	end
	return 0
end

local function NormalizeRemaining(value)
	value = tonumber(value)
	if not value or value <= 0 then
		return nil
	end
	-- Some custom-client bridges expose durations in milliseconds.
	if value > MAX_RESET_SECONDS and value <= MAX_RESET_SECONDS * 1000 then
		value = value / 1000
	end
	if value > MAX_RESET_SECONDS then
		return nil
	end
	return value
end

local function AddCandidate(candidates, value)
	value = NormalizeRemaining(value)
	if value then
		candidates[#candidates + 1] = value
	end
end

local function CollectNamedTimes(candidates, value, depth)
	if type(value) ~= "table" or depth > 3 then
		return
	end
	for key, nested in pairs(value) do
		local normalizedKey = string.lower(tostring(key or ""))
		if type(nested) == "number"
			and (normalizedKey:find("timeremaining", 1, true)
				or normalizedKey:find("time_remaining", 1, true)
				or normalizedKey:find("reset", 1, true))
		then
			AddCandidate(candidates, nested)
		elseif type(nested) == "table" then
			CollectNamedTimes(candidates, nested, depth + 1)
		end
	end
end

local function Median(candidates)
	if #candidates == 0 then
		return nil
	end
	table.sort(candidates)
	return candidates[math.floor((#candidates + 1) / 2)]
end

local function QueryDateAndTimeAPI()
	if type(C_DateAndTime) ~= "table"
		or type(C_DateAndTime.GetSecondsUntilWeeklyReset) ~= "function"
	then
		return nil
	end
	local ok, value = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
	return ok and NormalizeRemaining(value) or nil
end

local function QueryAscensionLootLockouts()
	if type(C_LootLockout) ~= "table" then
		return nil
	end
	local candidates = {}
	if type(C_LootLockout.GetLootLockoutTimeRemaining) == "function" then
		local ok, value = pcall(C_LootLockout.GetLootLockoutTimeRemaining)
		if ok then
			AddCandidate(candidates, value)
		end
	end
	if type(C_LootLockout.GetLootLockouts) == "function" then
		local results = { pcall(C_LootLockout.GetLootLockouts) }
		if table.remove(results, 1) then
			local lockoutCount
			for index = 1, #results do
				if type(results[index]) == "number" and results[index] >= 1
					and results[index] <= 100
				then
					lockoutCount = math.floor(results[index])
				end
				CollectNamedTimes(candidates, results[index], 1)
			end
			-- Ascension client revisions have exposed both no-argument and
			-- index-based variants of this function.
			if type(C_LootLockout.GetLootLockoutTimeRemaining) == "function" then
				for index = 1, (lockoutCount or 0) do
					local ok, value = pcall(
						C_LootLockout.GetLootLockoutTimeRemaining,
						index
					)
					if ok then
						AddCandidate(candidates, value)
					end
				end
			end
		end
	end
	return Median(candidates)
end

local function QuerySavedRaidLockouts()
	if type(GetNumSavedInstances) ~= "function"
		or type(GetSavedInstanceInfo) ~= "function"
	then
		return nil
	end
	local candidates = {}
	for index = 1, (GetNumSavedInstances() or 0) do
		local _, _, reset, _, locked, _, _, isRaid = GetSavedInstanceInfo(index)
		if locked and isRaid then
			AddCandidate(candidates, reset)
		end
	end
	return Median(candidates)
end

local function QueryEstimatedWednesdayReset()
	if type(GetQuestResetTime) ~= "function" or type(date) ~= "function" then
		return nil
	end
	local ok, dailySeconds = pcall(GetQuestResetTime)
	dailySeconds = ok and NormalizeRemaining(dailySeconds) or nil
	if not dailySeconds then
		return nil
	end
	local nextDailyReset = GetServerEpoch() + dailySeconds
	local resetDate = date("!*t", nextDailyReset)
	if type(resetDate) ~= "table" or type(resetDate.wday) ~= "number" then
		return nil
	end
	-- Lua: Sunday=1, Wednesday=4. Community observations on Vol'jin place
	-- the M+ weekly rollover on Wednesday's normal server reset.
	local daysUntilWednesday = (4 - resetDate.wday) % 7
	return dailySeconds + daysUntilWednesday * 86400
end

local function AdvanceStoredCycle(now)
	local nextResetAt = resetDB and tonumber(resetDB.nextResetAt)
	if not nextResetAt then
		return nil
	end
	while nextResetAt <= now do
		nextResetAt = nextResetAt + WEEK_SECONDS
		resetDB.source = "cycle memorise"
		resetDB.confidence = "estimated"
	end
	resetDB.nextResetAt = nextResetAt
	return nextResetAt - now
end

local function StoreDirectTimer(seconds, source)
	if not resetDB then
		return
	end
	local now = GetServerEpoch()
	resetDB.nextResetAt = now + seconds
	resetDB.observedAt = now
	resetDB.source = source
	resetDB.confidence = "direct"
end

function Module.Refresh()
	if not resetDB then
		return nil
	end
	local seconds = QueryDateAndTimeAPI()
	local source = "API hebdomadaire du client"
	if not seconds then
		seconds = QueryAscensionLootLockouts()
		source = "verrouillage Ascension"
	end
	if not seconds then
		seconds = QuerySavedRaidLockouts()
		source = "verrouillage de raid"
	end
	if seconds then
		StoreDirectTimer(seconds, source)
		return seconds, source, "direct"
	end
	local now = GetServerEpoch()
	seconds = AdvanceStoredCycle(now)
	if seconds then
		return seconds, resetDB.source, resetDB.confidence
	end
	seconds = QueryEstimatedWednesdayReset()
	if seconds then
		resetDB.nextResetAt = now + seconds
		resetDB.observedAt = now
		resetDB.source = "reset serveur du mercredi"
		resetDB.confidence = "estimated"
		return seconds, resetDB.source, resetDB.confidence
	end
	return nil
end

local function FormatDuration(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	if days > 0 then
		return string.format("%dj %02dh %02dm", days, hours, minutes)
	end
	if hours > 0 then
		return string.format("%dh %02dm", hours, minutes)
	end
	return string.format("%dm", minutes)
end

local function GetCounterText()
	local counters = resetDB and resetDB.counters
	if type(counters) ~= "table" then
		return nil
	end
	local values = {}
	if type(counters.caches) == "table" then
		values[#values + 1] = string.format(
			"Caches %d/%d",
			tonumber(counters.caches.current) or 0,
			tonumber(counters.caches.maximum) or 0
		)
	end
	if type(counters.coins) == "table" then
		values[#values + 1] = string.format(
			"Coins %d/%d",
			tonumber(counters.coins.current) or 0,
			tonumber(counters.coins.maximum) or 0
		)
	end
	return #values > 0 and table.concat(values, "  |  ") or nil
end

function Module.GetStatus()
	local seconds, source, confidence = Module.Refresh()
	if not seconds then
		return {
			known = false,
			text = "Reset M+ : heure non detectee",
			detail = "Mesure exacte : vaincre un boss de raid, puis cliquer sur Actualiser.",
			counterText = GetCounterText(),
		}
	end
	local nextResetAt = resetDB and tonumber(resetDB.nextResetAt)
	local localDate
	if nextResetAt and type(date) == "function" then
		localDate = date("%d/%m a %H:%M", nextResetAt)
	end
	return {
		known = true,
		seconds = seconds,
		nextResetAt = nextResetAt,
		source = source,
		confidence = confidence,
		localDate = localDate,
		counterText = GetCounterText(),
		text = (confidence == "direct" and "Reset M+ : " or "Reset M+ estime : ")
			.. FormatDuration(seconds),
		detail = (localDate and ("Prochain reset : " .. localDate .. " (heure locale). ") or "")
			.. (confidence == "direct"
				and "Timer hebdomadaire lu directement sur le serveur."
				or "Estimation basee sur le reset serveur du mercredi."),
	}
end

function Module.GetDisplayLine()
	return Module.GetStatus().text
end

function Module.PrintStatus()
	local status = Module.GetStatus()
	if not status.known then
		Chat("Heure du reset M+ non detectee. Pour une mesure exacte : vaincs au moins un boss de raid, puis utilise /coaa reset actualiser. Ouvrir Edrim ne fournit que les compteurs, pas l'heure.")
		return
	end
	local precision = status.confidence == "direct" and "mesure directe" or "estimation"
	local dateText = status.localDate and (", " .. status.localDate .. " heure locale") or ""
	Chat(string.format(
		"Reset des limites M+ dans %s%s (%s, %s).",
		FormatDuration(status.seconds),
		dateText,
		tostring(status.source or "source inconnue"),
		precision
	))
end

function Module.RequestRefresh(showResult)
	if not initialized then
		Module.Initialize()
	end
	if type(C_LootLockout) == "table"
		and type(C_LootLockout.QueryInstanceBinds) == "function"
	then
		pcall(C_LootLockout.QueryInstanceBinds)
	end
	if type(RequestRaidInfo) == "function" then
		pcall(RequestRaidInfo)
	end
	local function FinishRefresh()
		Module.Refresh()
		if CoAAnalyticsAddon.Events then
			CoAAnalyticsAddon.Events:Fire("MYTHIC_RESET_UPDATED")
		end
		if showResult then
			Module.PrintStatus()
		end
	end
	if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
		C_Timer.After(0.75, FinishRefresh)
	else
		FinishRefresh()
	end
end

local function SaveCounter(kind, current, maximum)
	if not resetDB then
		return
	end
	local now = GetServerEpoch()
	local previous = resetDB.counters and resetDB.counters[kind]
	if previous and current < (tonumber(previous.current) or 0) then
		local previousSeenAt = tonumber(previous.seenAt) or 0
		if previousSeenAt > 0 and now - previousSeenAt <= COUNTER_OBSERVATION_WINDOW then
			resetDB.nextResetAt = now + WEEK_SECONDS
			resetDB.observedAt = now
			resetDB.source = "reset des compteurs observe"
			resetDB.confidence = "estimated"
		end
	end
	resetDB.counters = resetDB.counters or {}
	resetDB.counters[kind] = {
		current = current,
		maximum = maximum,
		seenAt = now,
	}
end

function Module.CaptureCountersFromText(text)
	if type(text) ~= "string" then
		return false
	end
	local current, maximum = text:match("Mythical Caches Opened:%s*(%d+)%s*/%s*(%d+)")
	if current then
		SaveCounter("caches", tonumber(current), tonumber(maximum))
		return true
	end
	current, maximum = text:match("Mythic Coins Obtained:%s*(%d+)%s*/%s*(%d+)")
	if current then
		SaveCounter("coins", tonumber(current), tonumber(maximum))
		return true
	end
	return false
end

local function ScanVisibleFrameText()
	if type(EnumerateFrames) ~= "function" then
		return
	end
	local frame
	local inspected = 0
	repeat
		frame = EnumerateFrames(frame)
		inspected = inspected + 1
		if frame and frame.IsVisible and frame:IsVisible() and frame.GetRegions then
			local regions = { frame:GetRegions() }
			for index = 1, #regions do
				local region = regions[index]
				if region and region.GetText then
					local ok, text = pcall(region.GetText, region)
					if ok then
						Module.CaptureCountersFromText(text)
					end
				end
			end
		end
	until not frame or inspected >= 5000
end

local function ScheduleScans()
	ScanVisibleFrameText()
	if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
		C_Timer.After(0.25, ScanVisibleFrameText)
		C_Timer.After(1.00, ScanVisibleFrameText)
	end
end

local function RegisterOptionalEvent(eventName)
	pcall(driver.RegisterEvent, driver, eventName)
end

function Module.Initialize()
	if initialized then
		return true
	end
	addonDB = API and API.GetDatabase and API.GetDatabase()
	if not addonDB then
		return false
	end
	addonDB.mythicReset = type(addonDB.mythicReset) == "table"
		and addonDB.mythicReset or {}
	resetDB = addonDB.mythicReset
	initialized = true
	Module.Refresh()
	if type(C_LootLockout) == "table"
		and type(C_LootLockout.QueryInstanceBinds) == "function"
	then
		pcall(C_LootLockout.QueryInstanceBinds)
	end
	if type(RequestRaidInfo) == "function" then
		pcall(RequestRaidInfo)
	end
	ScheduleScans()
	return true
end

RegisterOptionalEvent("PLAYER_LOGIN")
RegisterOptionalEvent("PLAYER_ENTERING_WORLD")
RegisterOptionalEvent("UPDATE_INSTANCE_INFO")
RegisterOptionalEvent("QUERY_INSTANCE_BINDS_RESULT")
RegisterOptionalEvent("GOSSIP_SHOW")
RegisterOptionalEvent("ASCENSION_UNKNOWN_WINDOW_VISIBILITY_CHANGED")

driver:SetScript("OnEvent", function(_, eventName)
	if eventName == "PLAYER_LOGIN" then
		Module.Initialize()
	elseif initialized then
		if eventName == "GOSSIP_SHOW"
			or eventName == "ASCENSION_UNKNOWN_WINDOW_VISIBILITY_CHANGED"
		then
			ScheduleScans()
		else
			Module.Refresh()
		end
	end
end)
