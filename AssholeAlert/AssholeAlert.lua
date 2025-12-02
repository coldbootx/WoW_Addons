-- AssholeAlert.lua (integrated flashing-text alert only)

local ADDON_NAME, ns = "AssholeAlert", {}
local frame = CreateFrame("Frame")
local lightBlue = {0, 0.8, 1, 1}
local white = {1, 1, 1, 1}
local red       = {1, 0, 0, 1}
local yellow    = {1, 1, 0, 1}
local purple    = {0.6, 0, 0.8, 1}

-- Color palette for outputs
local colors = {
    addon    = "|cff00ff00",
    session  = "|cffff6600",
    gold     = "|cffffff00",
    silver   = "|cffc0c0c0",
    copper   = "|cffcd7f32",
    positive = "|cff00ff00",
    negative = "|cffff0000",
    info     = "|cff00ccff",
    reset    = "|r"
}

-- Create alert text at top center (no GUI frame, just text)
-- Create an alert frame with a child fontstring so we can control strata/position safely
local alertFrame = CreateFrame("Frame", "AA_AlertFrame", UIParent)
alertFrame:SetSize(20, 20)
alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
alertFrame:SetFrameStrata("HIGH")

local alertText = alertFrame:CreateFontString(nil, "OVERLAY")
alertText:SetPoint("CENTER", alertFrame, "CENTER")
alertText:SetTextColor(1, 0.2, 0.2)
alertText:SetJustifyH("CENTER")
alertText:SetScale(1.2)
if STANDARD_TEXT_FONT then
    alertText:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
end
alertText:Hide()

-- Function to flash the text multiple times
local function FlashText(message, flashes)
    alertText:SetText(message)
    alertText:Show()
    alertText:SetAlpha(1)

    local count = 0
    local function FlashCycle()
        if count >= flashes * 2 then
            alertText:Hide()
            return
        end
        if alertText:GetAlpha() > 0 then
            alertText:SetAlpha(0)
        else
            alertText:SetAlpha(1)
        end
        count = count + 1
        C_Timer.After(0.5, FlashCycle)
    end
    FlashCycle()
end

-- Debug: dump nameplates
-- Debugging has been removed. Keep stub functions so any calls are harmless.
local function DebugDumpNamePlates()
    -- Intentionally left blank: debugging removed.
    return
end

-- Default configuration
local defaultConfig = {
    checkInterval = 1.0,
    alertDistance = 500,
    alertCooldown = 3,
    enableSound = true,
    enableFlashing = true,
    enableZoneFiltering = true,
    enableGUIDFallback = true,
    debugMode = false,
    alertWhenEmpty = false
}
defaultConfig.enableNameplateRangeFallback = true

-- New: allow noisy detection of any named nameplate (will alert on NPCs too)
defaultConfig.enableDetectAny = false

-- Current config (will be loaded from saved variables)
local config = {}
local trackedPlayers = {}
local isInitialized = false
local lastAlertTime = 0
local lastCheckTime = 0  -- For OnUpdate timer

-- Excluded zones (safe areas)
local excludedZones = {
    ["Orgrimmar"] = true,
    --["Stormwind City"] = true,
    ["Ironforge"] = true,
    ["Thunder Bluff"] = true,
    --["Darnassus"] = true,
    ["Undercity"] = true,
}

-- Debug print function
-- Debugging removed: no-op DebugPrint to avoid any debug output
local function DebugPrint(message) end

-- Name validation
local function ValidatePlayerName(playerName)
    if not playerName or playerName == "" then
        return false, "No player name provided"
    end
    playerName = strtrim(playerName)
    if string.len(playerName) < 2 or string.len(playerName) > 12 then
        return false, "Player name must be between 2-12 characters"
    end
    -- if string.match(playerName, "[^a-zA-Z]") then
    --    return false, "Player name contains invalid characters"
    --end
    return true, string.upper(playerName)
end

-- Zone filtering
local function ShouldCheckInCurrentZone()
    if not config.enableZoneFiltering then
        return true
    end
    local currentZone = GetRealZoneText() or GetZoneText()
    local isExcluded = excludedZones[currentZone]
    DebugPrint("Current zone: " .. (currentZone or "Unknown") .. ", Excluded: " .. tostring(isExcluded))

    return not isExcluded
end

-- Save / Load data
local function SaveData()
    AssholeAlertDB = {
        config = config,
        trackedPlayers = trackedPlayers
    }
    -- Unconditional save confirmation so users see persistence without debug enabled
    -- Use inline counting here to avoid calling GetTableSize before it's defined
    local count = 0
    for _ in pairs(trackedPlayers) do count = count + 1 end
    print(colors.addon .. "Saved " .. tostring(count) .. " tracked player(s)." .. colors.reset)
end

local function LoadData()
    -- If no saved table exists, initialize with defaults
    if not AssholeAlertDB then
        config = {}
        for k, v in pairs(defaultConfig) do
            config[k] = v
        end
        trackedPlayers = {}
        return
    end

    -- Ensure saved table has expected subtables
    if type(AssholeAlertDB.config) ~= "table" then
        AssholeAlertDB.config = {}
    end
    if type(AssholeAlertDB.trackedPlayers) ~= "table" then
        AssholeAlertDB.trackedPlayers = {}
    end

    -- Merge defaults into saved config when missing
    for k, v in pairs(defaultConfig) do
        if AssholeAlertDB.config[k] == nil then
            AssholeAlertDB.config[k] = v
        end
    end

    -- Load config
    config = AssholeAlertDB.config

    -- Normalize tracked player names to uppercase keys to ensure matching
    trackedPlayers = {}
    for name, val in pairs(AssholeAlertDB.trackedPlayers or {}) do
        if type(name) == "string" and val then
            local ok, clean = pcall(function() return string.upper(strtrim(name)) end)
            if ok and clean ~= "" then
                trackedPlayers[clean] = true
            end
        end
    end
    -- Persist normalized trackedPlayers back to saved table so future loads are consistent
    AssholeAlertDB.trackedPlayers = trackedPlayers
end

-- Helper function to count table size
local function GetTableSize(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Enhanced detection for ANY nearby player
local function CheckForNearbyPlayers()
    if not isInitialized then 
        DebugPrint("Addon not initialized")
        return 
    end
    
    if not ShouldCheckInCurrentZone() then 
        DebugPrint("Zone filtering active - skipping detection")
        return 
    end
    
    local currentTime = GetTime()
    if currentTime - lastAlertTime < config.alertCooldown then 
        DebugPrint("Alert on cooldown")
        return 
    end

    local playerX, playerY = UnitPosition("player")
    if not playerX then 
        DebugPrint("Unable to get player position")
        return 
    end

    DebugPrint("Starting comprehensive player scan...")
    DebugPrint("Tracked players count: " .. GetTableSize(trackedPlayers))

    -- Check nameplates (visible players)
    local nameplates = C_NamePlate.GetNamePlates()
    local playersFound = 0
    
    for _, nameplate in pairs(nameplates) do
        if nameplate and nameplate.UnitFrame and nameplate.UnitFrame.unit then
            local unit = nameplate.UnitFrame.unit
            local guid = UnitGUID(unit)
            local isPlayerDetected = UnitIsPlayer(unit)
            if (not isPlayerDetected) and config.enableGUIDFallback and guid then
                if string.find(tostring(guid), "Player") then
                    isPlayerDetected = true
                    DebugPrint("GUID fallback: treating unit " .. tostring(UnitName(unit)) .. " as player (GUID=" .. tostring(guid) .. ")")
                end
            end

            if UnitExists(unit) and isPlayerDetected and not UnitIsUnit(unit, "player") then
                local unitX, unitY = UnitPosition(unit)
                local distance = nil
                if unitX and unitY then
                    local dx = unitX - playerX
                    local dy = unitY - playerY
                    distance = math.sqrt(dx*dx + dy*dy)
                    playersFound = playersFound + 1
                    DebugPrint("Found player: " .. (UnitName(unit) or "Unknown") .. " at " .. string.format("%.1f", distance) .. " yards")
                else
                    DebugPrint("UnitPosition unavailable for " .. tostring(UnitName(unit)) .. "; using nameplate-range fallback: " .. tostring(config.enableNameplateRangeFallback))
                    -- Count it as found (nameplate visible) even if precise position missing
                    playersFound = playersFound + 1
                end

                local inRange = false
                if distance then
                    inRange = (distance <= config.alertDistance)
                else
                    inRange = config.enableNameplateRangeFallback
                end

                if inRange then
                        local rawName = UnitName(unit)
                        -- Strip realm or server suffixes (e.g. Name-Realm) to match stored names
                        local playerName = rawName and Ambiguate(rawName, "none") or nil

                        -- If noisy detection is enabled, or there are no tracked players configured, treat this as "alert on any player"
                        if (config.enableDetectAny and playerName and playerName ~= "") then
                            -- notify-only behavior handled below for non-tracked names
                        end

                        local success, cleanName = ValidatePlayerName(playerName)
                        if not success then
                            DebugPrint("Skipping unit due to invalid name: '" .. tostring(playerName) .. "' reason: " .. tostring(cleanName))
                        else
                            if trackedPlayers[cleanName] then
                                DebugPrint("*** ALERT TRIGGERED FOR: " .. cleanName .. " ***")
                            else
                                DebugPrint("Player " .. cleanName .. " not in tracked list")
                            end
                        end
                        if success and trackedPlayers[cleanName] then
                            DebugPrint("*** ALERT TRIGGERED FOR: " .. cleanName .. " ***")

                            -- Trigger alert (flashing text + chat fallback)
                            lastAlertTime = currentTime
                            FlashText("ASSHOLE ALERT: " .. cleanName, 3)
                            print(colors.negative .. "ALERT: Player detected: " .. cleanName .. colors.reset)
                            if config.enableSound then
                                PlaySound(8959)  -- RAID_WARNING (wrapped to avoid runtime error)
                            end
                            return true  -- Alert triggered
                        end
                    end
                end
            end
        end
    
    DebugPrint("Scan complete. Players found: " .. playersFound)
    return false  -- No alert
end

-- Start detection ticker
local function StartDetectionTicker()
    lastCheckTime = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        lastCheckTime = lastCheckTime + elapsed
        if lastCheckTime >= config.checkInterval then
            lastCheckTime = 0
            CheckForNearbyPlayers()
        end
    end)
end

local function StopDetectionTicker()
    frame:SetScript("OnUpdate", nil)
    lastCheckTime = 0
end

-- Initialize detection
local function InitializeDetection()
    StartDetectionTicker()
    print(colors.addon .. "PlayerAlert detection started" .. colors.reset .. " - monitoring for nearby players.")
end

-- Add, Remove, List functions
local function AddPlayerToList(playerName)
    if not playerName or playerName == "" then
        return false, "No player name provided"
    end
    -- Strip realm suffixes and any extra formatting (e.g. Name-Realm)
    local raw = tostring(playerName)
    local stripped = Ambiguate(raw, "none") or raw
    local success, cleanName = ValidatePlayerName(stripped)
    if not success then return false, cleanName end
    if trackedPlayers[cleanName] then
        return false, "Player already in list"
    end
    trackedPlayers[cleanName] = true
    SaveData()
    DebugPrint("Saved trackedPlayers, total=" .. GetTableSize(trackedPlayers))
    return true, "Added " .. cleanName
end

local function RemovePlayerFromList(playerName)
    if not playerName or playerName == "" then
        return false, "No player name provided"
    end
    local raw = tostring(playerName)
    local stripped = Ambiguate(raw, "none") or raw
    local success, cleanName = ValidatePlayerName(stripped)
    if not success then return false, cleanName end
    if not trackedPlayers[cleanName] then
        return false, "Player not in list"
    end
    trackedPlayers[cleanName] = nil
    SaveData()
    DebugPrint("Saved trackedPlayers, total=" .. GetTableSize(trackedPlayers))
    return true, "Removed " .. cleanName
end

local function ShowPlayerList()
    if next(trackedPlayers) == nil then
        print(colors.info .. "No players in tracking list." .. colors.reset)
        return
    end
    print(colors.info .. "Tracked players:" .. colors.reset)
    for name in pairs(trackedPlayers) do
        print(" - " .. name)
    end
end

local function ClearPlayerList()
    trackedPlayers = {}
    SaveData()
    return true, "Tracking list cleared"
end

-- Apply common nameplate CVars to try to ensure player nameplates are visible
local function FixNameplates()
    local cvars = {
        nameplateShowEnemies = "1",
        nameplateShowAll = "1",
        nameplateShowFriends = "1",
        nameplateShowEnemyMinions = "1",
    }
    for k, v in pairs(cvars) do
        local ok, err = pcall(SetCVar, k, v)
        if not ok then
            print(colors.negative .. "Failed to set CVar " .. tostring(k) .. colors.reset)
        end
    end
    print(colors.addon .. "Nameplate CVars set (may require reload)." .. colors.reset)
    SaveData()
end

-- Toggle noisy detection: treat any named nameplate as a potential player
local function SetDetectAny(on)
    config.enableDetectAny = on and true or false
    SaveData()
    print(colors.info .. "Any-nameplate detection: " .. (config.enableDetectAny and "ON" or "OFF") .. colors.reset)
end

-- Test function to trigger alert manually (via slash or test command)
local function TestAlert()
    FlashText("TEST ALERT - SYSTEM WORKING", 2)
end

-- Event registration and handler
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        LoadData()
        -- Always disable debug on start to avoid noisy output from saved state
        if config then config.debugMode = false end
        InitializeDetection()
        isInitialized = true
        print(colors.addon .. "PlayerAlert loaded" .. colors.reset .. " - monitoring for nearby players.")
        print(colors.session .. "Type /aa help for commands." .. colors.reset)
        -- Debugging removed; no debug status shown
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        DebugPrint("Zone changed, restarting detection.")
        InitializeDetection()
        -- No automatic nameplate dumps on zone change
    end
end)

-- Slash command setup
SLASH_AA1 = "/aa"
SLASH_AA2 = "/assholealert"

SlashCmdList["AA"] = function(msg)
    msg = msg:lower()
    if msg == "" or msg == "help" then
        print(colors.info .. "PlayerAlert Commands:" .. colors.reset)
        print(colors.session .. " /aa help" .. colors.reset .. " - Show this help")
        print(colors.session .. " /aa add <playername>" .. colors.reset .. " - Add player to tracking list")
        print(colors.session .. " /aa remove <playername>" .. colors.reset .. " - Remove player")
        print(colors.session .. " /aa list" .. colors.reset .. " - Show tracked players")
        print(colors.session .. " /aa clear" .. colors.reset .. " - Clear tracking list")
        print(colors.session .. " /aa test" .. colors.reset .. " - Test alert system")
        print(colors.session .. " /aa scan" .. colors.reset .. " - Force immediate scan")
        print(colors.session .. " /aa zone" .. colors.reset .. " - Show current zone info")
        -- Debug commands removed
        print(colors.session .. " /aa nameplatefix" .. colors.reset .. " - Attempt to enable player nameplates via CVars")
        print(colors.session .. " /aa any on|off" .. colors.reset .. " - Enable/disable noisy any-nameplate detection")
        print(colors.session .. " /aa range <yards>" .. colors.reset .. " - Set alert detection distance (yards)")
        return
    end

    if msg:sub(1, 4) == "add " then
        local pname = msg:sub(5)
        local success, resp = AddPlayerToList(pname)
        print((resp) and (colors.addon .. resp .. colors.reset) or resp)
    elseif msg:sub(1, 7) == "remove " then
        local pname = msg:sub(8)
        local success, resp = RemovePlayerFromList(pname)
        print((resp) and (colors.addon .. resp .. colors.reset) or resp)
    elseif msg == "list" then
        ShowPlayerList()
    elseif msg == "clear" then
        local success, resp = ClearPlayerList()
        print(resp)
    elseif msg == "test" then
        TestAlert()
    elseif msg == "scan" then
        print(colors.info .. "Forcing scan..." .. colors.reset)
        CheckForNearbyPlayers()
    elseif msg:sub(1,6) == "range " then
        local val = tonumber(msg:sub(7))
        if val and val > 0 then
            config.alertDistance = val
            SaveData()
            print(colors.info .. "Alert distance set to " .. tostring(val) .. " yards" .. colors.reset)
        else
            print(colors.info .. "Usage: /aa range <yards> (positive number)" .. colors.reset)
        end
    elseif msg == "range" then
        print(colors.info .. "Current alert distance: " .. tostring(config.alertDistance) .. " yards" .. colors.reset)
    elseif msg == "nameplatefix" then
        FixNameplates()
    elseif msg == "zone" then
        local zone = GetRealZoneText() or GetZoneText()
        local isExcluded = excludedZones[zone]
        print(colors.info .. "Current zone: " .. (zone or "Unknown") .. ", Excluded: " .. tostring(isExcluded) .. colors.reset)
    -- debug commands removed
    elseif msg:sub(1,3) == "any" then
        local arg = msg:match("^any%s+(%w+)")
        if arg == "on" then
            SetDetectAny(true)
        elseif arg == "off" then
            SetDetectAny(false)
        else
            print(colors.info .. "Usage: /aa any on|off" .. colors.reset)
        end
    else
        print(colors.negative .. "Unknown command. Type /aa help for help." .. colors.reset)
    end
end
