local API = CoAAnalyticsAPI
local Module = {}
CoAAnalyticsAddon.Modules.MythicReset = Module

local WEEK_SECONDS = 7 * 24 * 60 * 60
local MAX_RESET_SECONDS = 8 * 24 * 60 * 60
local COUNTER_OBSERVATION_WINDOW = 8 * 60 * 60
local MYTHIC_COIN_CURRENCY_ID = 55
local MYTHICAL_CACHE_ITEM_ID = 2093995
local COUNTER_POLL_INTERVAL = 5

local driver = CreateFrame("Frame")
local addonDB
local resetDB
local initialized = false
local counterPollElapsed = 0
local counterScanPending = false
local ObserveCounters

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
		resetDB.source = "cycle hebdomadaire memorise"
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
	seconds = QueryEstimatedWednesdayReset()
	if seconds then
		resetDB.nextResetAt = now + seconds
		resetDB.observedAt = now
		resetDB.source = "reset de raid hebdomadaire"
		resetDB.confidence = "estimated"
		return seconds, resetDB.source, resetDB.confidence
	end
	seconds = AdvanceStoredCycle(now)
	if seconds then
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
			"Mythic Coins %d/%d",
			tonumber(counters.coins.current) or 0,
			tonumber(counters.coins.maximum) or 0
		)
	end
	return #values > 0 and table.concat(values, "  |  ") or nil
end

function Module.GetStatus()
	if ObserveCounters then
		ObserveCounters(true)
	end
	local seconds, source, confidence = Module.Refresh()
	if not seconds then
		return {
			known = false,
			text = "Hausse des plafonds M+ : heure non detectee",
			detail = "Actualiser interroge les timers hebdomadaires du client. Sans timer direct, l'addon affiche une estimation sur le reset de raid.",
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
		text = (confidence == "direct"
			and "Hausse des plafonds M+ : "
			or "Hausse estimee des plafonds M+ : ")
			.. FormatDuration(seconds),
		detail = (localDate and ("Prochaine augmentation : " .. localDate .. " (heure locale). ") or "")
			.. (confidence == "direct"
				and "Timer hebdomadaire lu directement depuis le client."
				or "Estimation basee sur le reset de raid hebdomadaire."),
	}
end

function Module.GetDisplayLine()
	return Module.GetStatus().text
end

function Module.PrintStatus()
	local status = Module.GetStatus()
	if not status.known then
		Chat("Heure de la prochaine hausse M+ non detectee. Utilise /coaa reset actualiser pour interroger les timers hebdomadaires. Edrim fournit les compteurs, mais pas l'heure.")
		return
	end
	local precision = status.confidence == "direct" and "mesure directe" or "estimation"
	local dateText = status.localDate and (", " .. status.localDate .. " heure locale") or ""
	Chat(string.format(
		"Augmentation des plafonds M+ dans %s%s (%s, %s).",
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
	local counterRolledOver = previous
		and current < (tonumber(previous.current) or 0)
	local capIncreased = previous
		and maximum > (tonumber(previous.maximum) or 0)
	if counterRolledOver or capIncreased then
		local previousSeenAt = tonumber(previous.seenAt) or 0
		if previousSeenAt > 0 and now - previousSeenAt <= COUNTER_OBSERVATION_WINDOW then
			resetDB.nextResetAt = now + WEEK_SECONDS
			resetDB.observedAt = now
			resetDB.source = capIncreased
				and "augmentation des plafonds observee"
				or "cycle des compteurs observe"
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

local function GetCharacterObservationKey()
	if type(UnitGUID) == "function" then
		local guid = UnitGUID("player")
		if guid and guid ~= "" then
			return guid
		end
	end
	if type(UnitName) == "function" then
		local name, realm = UnitName("player")
		if name and name ~= "" then
			return realm and realm ~= "" and (name .. "-" .. realm) or name
		end
	end
	return "player"
end

local function GetObservationStore()
	if not resetDB then
		return
	end
	resetDB.observations = type(resetDB.observations) == "table"
		and resetDB.observations or {}
	resetDB.observations.coinBalances =
		type(resetDB.observations.coinBalances) == "table"
		and resetDB.observations.coinBalances or {}
	resetDB.observations.cacheItemCounts =
		type(resetDB.observations.cacheItemCounts) == "table"
		and resetDB.observations.cacheItemCounts or {}
	return resetDB.observations
end

local function IncrementTrackedCounter(kind, amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 or not resetDB or type(resetDB.counters) ~= "table" then
		return false
	end
	local counter = resetDB.counters[kind]
	if type(counter) ~= "table" then
		return false
	end
	counter.current = math.max(0, (tonumber(counter.current) or 0) + amount)
	counter.seenAt = GetServerEpoch()
	counter.source = "automatic client observation"
	return true
end

local function IsNamedCounter(name, kind)
	name = string.lower(tostring(name or ""))
	if kind == "coins" then
		return name:find("mythic", 1, true)
			and name:find("coin", 1, true)
	end
	return name:find("myth", 1, true)
		and name:find("cache", 1, true)
end

local function ApplyDirectCurrencyCounter(kind, name, current, maximum)
	current = tonumber(current)
	maximum = tonumber(maximum)
	if not IsNamedCounter(name, kind)
		or not current or current < 0
		or not maximum or maximum <= 0
	then
		return false
	end

	local previous = resetDB and resetDB.counters and resetDB.counters[kind]
	local previousCurrent = previous and tonumber(previous.current) or 0
	local previousMaximum = previous and tonumber(previous.maximum) or 0
	-- Never replace the cumulative NPC counter with a smaller weekly currency
	-- limit or with a spendable balance that dropped after a purchase.
	if maximum < previousMaximum or current < previousCurrent then
		return false
	end
	SaveCounter(kind, current, maximum)
	if resetDB.counters and resetDB.counters[kind] then
		resetDB.counters[kind].source = "currency API"
	end
	return true
end

local function SyncCacheMaximumFromCoinCap()
	local counters = resetDB and resetDB.counters
	local coins = counters and counters.coins
	local caches = counters and counters.caches
	local coinMaximum = coins and tonumber(coins.maximum)
	if not coinMaximum or coinMaximum <= 0 or type(caches) ~= "table" then
		return false
	end
	-- Ascension publishes both limits on the same progression track: the
	-- initial 2,750-coin cap corresponds to 40 cache openings. This also
	-- matches the later 8,250/120 and 12,375/180 cap pairs.
	local inferredMaximum = math.floor(coinMaximum * 40 / 2750 + 0.5)
	if inferredMaximum <= (tonumber(caches.maximum) or 0) then
		return false
	end
	caches.maximum = inferredMaximum
	caches.seenAt = GetServerEpoch()
	caches.source = "derived from Mythic Coin currency cap"
	return true
end

local function ReadCurrencyInfoTable(info, kind)
	if type(info) ~= "table" then
		return nil, false
	end
	local name = info.name or info.currencyName
	if not IsNamedCounter(name, kind) then
		return tonumber(info.quantity), false
	end
	local balance = tonumber(info.quantity or info.amount)
	local earned = tonumber(
		info.quantityEarnedThisWeek
			or info.currentWeeklyAmount
			or info.earnedThisWeek
	)
	local weeklyMaximum = tonumber(
		info.maxWeeklyQuantity
			or info.weeklyMaximum
			or info.maxWeeklyAmount
	)
	local captured = ApplyDirectCurrencyCounter(
		kind,
		name,
		earned,
		weeklyMaximum
	)
	return balance, captured
end

local function QueryMythicCoinCurrency()
	local balance
	local captured = false
	if type(C_CurrencyInfo) == "table"
		and type(C_CurrencyInfo.GetCurrencyInfo) == "function"
	then
		local ok, info = pcall(
			C_CurrencyInfo.GetCurrencyInfo,
			MYTHIC_COIN_CURRENCY_ID
		)
		if ok then
			balance, captured = ReadCurrencyInfoTable(info, "coins")
		end
	end
	if not balance and type(GetCurrencyInfo) == "function" then
		local results = { pcall(GetCurrencyInfo, MYTHIC_COIN_CURRENCY_ID) }
		if table.remove(results, 1) then
			local name = results[1]
			if IsNamedCounter(name, "coins") then
				balance = tonumber(results[2])
				local earned = tonumber(results[4])
				local weeklyMaximum = tonumber(results[5])
				captured = ApplyDirectCurrencyCounter(
					"coins",
					name,
					earned,
					weeklyMaximum
				) or captured
			end
		end
	end
	return balance, captured
end

local function ScanCurrencyListCounters()
	local coinBalance
	local directCoinCounter = false
	if type(C_CurrencyInfo) == "table"
		and type(C_CurrencyInfo.GetCurrencyListSize) == "function"
		and type(C_CurrencyInfo.GetCurrencyListInfo) == "function"
	then
		local ok, size = pcall(C_CurrencyInfo.GetCurrencyListSize)
		if ok and type(size) == "number" then
			for index = 1, math.min(size, 500) do
				local infoOK, info = pcall(C_CurrencyInfo.GetCurrencyListInfo, index)
				if infoOK and type(info) == "table" then
					local balance, captured = ReadCurrencyInfoTable(info, "coins")
					if IsNamedCounter(info.name or info.currencyName, "coins") then
						coinBalance = balance or coinBalance
						directCoinCounter = captured or directCoinCounter
					end
					ReadCurrencyInfoTable(info, "caches")
				end
			end
		end
	end

	if type(GetCurrencyListSize) == "function"
		and type(GetCurrencyListInfo) == "function"
	then
		local ok, size = pcall(GetCurrencyListSize)
		if ok and type(size) == "number" then
			for index = 1, math.min(size, 500) do
				local values = { pcall(GetCurrencyListInfo, index) }
				if table.remove(values, 1) then
					local name = values[1]
					local balance = tonumber(values[6])
					local current = tonumber(values[10])
					local maximum = tonumber(values[8])
					local captured = ApplyDirectCurrencyCounter(
						"coins",
						name,
						current,
						maximum
					)
					if IsNamedCounter(name, "coins") then
						coinBalance = balance or coinBalance
						directCoinCounter = captured or directCoinCounter
					end
					ApplyDirectCurrencyCounter("caches", name, current, maximum)
				end
			end
		end
	end
	return coinBalance, directCoinCounter
end

ObserveCounters = function(scanCurrencyList)
	if not initialized or not resetDB then
		return false
	end
	local observations = GetObservationStore()
	if not observations then
		return false
	end
	local characterKey = GetCharacterObservationKey()
	local changed = false

	local coinBalance, directCoinCounter = QueryMythicCoinCurrency()
	if scanCurrencyList then
		local listedBalance, listedDirectCounter = ScanCurrencyListCounters()
		coinBalance = coinBalance or listedBalance
		directCoinCounter = directCoinCounter or listedDirectCounter
	end
	if coinBalance then
		local previousBalance = tonumber(observations.coinBalances[characterKey])
		if previousBalance and coinBalance > previousBalance and not directCoinCounter then
			changed = IncrementTrackedCounter(
				"coins",
				coinBalance - previousBalance
			) or changed
		end
		observations.coinBalances[characterKey] = coinBalance
	end

	if type(GetItemCount) == "function" then
		local ok, cacheCount = pcall(GetItemCount, MYTHICAL_CACHE_ITEM_ID, false)
		cacheCount = ok and tonumber(cacheCount) or nil
		if cacheCount then
			local previousCount = tonumber(observations.cacheItemCounts[characterKey])
			if previousCount and cacheCount < previousCount then
				changed = IncrementTrackedCounter(
					"caches",
					previousCount - cacheCount
				) or changed
			end
			observations.cacheItemCounts[characterKey] = cacheCount
		end
	end
	changed = SyncCacheMaximumFromCoinCap() or changed

	if changed and CoAAnalyticsAddon.Events then
		CoAAnalyticsAddon.Events:Fire("MYTHIC_RESET_UPDATED")
	end
	return changed
end

local function ScheduleCounterObservation(delay, scanCurrencyList)
	if counterScanPending then
		return
	end
	counterScanPending = true
	local function Run()
		counterScanPending = false
		ObserveCounters(scanCurrencyList)
	end
	if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
		C_Timer.After(delay or 0, Run)
	else
		Run()
	end
end

function Module.CaptureCountersFromText(text)
	if type(text) ~= "string" then
		return false
	end
	local current, maximum = text:match("Mythical Caches Opened:%s*(%d+)%s*/%s*(%d+)")
	local captured = false
	if current then
		SaveCounter("caches", tonumber(current), tonumber(maximum))
		captured = true
	end
	current, maximum = text:match("Mythic Coins Obtained:%s*(%d+)%s*/%s*(%d+)")
	if current then
		SaveCounter("coins", tonumber(current), tonumber(maximum))
		captured = true
	end
	if captured then
		ScheduleCounterObservation(0, false)
	end
	return captured
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
	ScheduleCounterObservation(1, true)
	return true
end

RegisterOptionalEvent("PLAYER_LOGIN")
RegisterOptionalEvent("PLAYER_ENTERING_WORLD")
RegisterOptionalEvent("UPDATE_INSTANCE_INFO")
RegisterOptionalEvent("QUERY_INSTANCE_BINDS_RESULT")
RegisterOptionalEvent("GOSSIP_SHOW")
RegisterOptionalEvent("ASCENSION_UNKNOWN_WINDOW_VISIBILITY_CHANGED")
RegisterOptionalEvent("CURRENCY_DISPLAY_UPDATE")
RegisterOptionalEvent("BAG_UPDATE_DELAYED")
RegisterOptionalEvent("CHAT_MSG_CURRENCY")

driver:SetScript("OnEvent", function(_, eventName)
	if eventName == "PLAYER_LOGIN" then
		Module.Initialize()
	elseif initialized then
		if eventName == "GOSSIP_SHOW"
			or eventName == "ASCENSION_UNKNOWN_WINDOW_VISIBILITY_CHANGED"
		then
			ScheduleScans()
		elseif eventName == "CURRENCY_DISPLAY_UPDATE"
			or eventName == "BAG_UPDATE_DELAYED"
			or eventName == "CHAT_MSG_CURRENCY"
		then
			ScheduleCounterObservation(0.25, true)
		else
			Module.Refresh()
			ScheduleCounterObservation(0.75, true)
		end
	end
end)

driver:SetScript("OnUpdate", function(_, elapsed)
	if not initialized then
		return
	end
	counterPollElapsed = counterPollElapsed + elapsed
	if counterPollElapsed >= COUNTER_POLL_INTERVAL then
		counterPollElapsed = 0
		ObserveCounters(true)
	end
end)
