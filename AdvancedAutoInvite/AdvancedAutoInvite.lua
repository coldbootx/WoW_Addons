local version = "1.4"

-- Basic configuration
local config = {
    inviteKeyword = "inv",
    autoInviteEnabled = true,
    sendWhisperResponse = true,
    whisperMessage = "Hello {name}, welcome to the party!",
    spamProtection = true,
    spamCooldown = 5,
    autoConvertToRaid = true
}

-- Color codes
local COLOR_GREEN = "|cFF00FF00"
local COLOR_RED = "|cFFFF0000"
local COLOR_YELLOW = "|cFFFFFF00"
local COLOR_CYAN = "|cFF00FFFF"
local COLOR_WHITE = "|cFFFFFFFF"
local COLOR_GOLD = "|cFFFFD700"
local COLOR_RESET = "|r"

-- Spam protection
local recentInvites = {}

-- Validate configuration
local function ValidateConfig()
    if not config.inviteKeyword or config.inviteKeyword:len() < 2 then
        config.inviteKeyword = "inv"
        print(COLOR_YELLOW .. "Advance Auto Invite: Reset invalid keyword to default 'inv'" .. COLOR_RESET)
    end
    
    config.inviteKeyword = config.inviteKeyword:gsub("%s+", ""):sub(1, 20):lower()
    
    if not config.whisperMessage or config.whisperMessage:len() == 0 then
        config.whisperMessage = "Hello {name}, welcome to the party!"
    else
        config.whisperMessage = config.whisperMessage:sub(1, 255)
    end
    
    if not config.spamCooldown or config.spamCooldown < 5 then
        config.spamCooldown = 30
    elseif config.spamCooldown > 300 then
        config.spamCooldown = 300
    end
    
    config.spamProtection = config.spamProtection == true
    config.autoConvertToRaid = config.autoConvertToRaid == true
end

-- Send whisper message
local function SendWhisperMessage(playerName, message)
    if not playerName or playerName == "" then return end
    if not message or message:len() == 0 then return end
    
    local personalizedMessage = message:gsub("{name}", playerName)
    SendChatMessage(personalizedMessage, "WHISPER", nil, playerName)
end

-- Extract just the player name (remove server suffix if present)
local function GetDisplayName(fullName)
    -- Remove server suffix if present (e.g., "John-Westfall" -> "John")
    return fullName:match("^([^-]+)") or fullName
end

-- Get the full name with server (for comparison)
local function GetFullName(name)
    -- If name already has server suffix, return as-is
    if name:find("-") then
        return name
    end
    -- Otherwise add current realm
    local currentRealm = GetRealmName()
    return name .. "-" .. currentRealm
end

-- Compare two player names (handles connected realms)
local function ComparePlayerNames(name1, name2)
    -- Get full names with server suffixes
    local fullName1 = GetFullName(name1):lower()
    local fullName2 = GetFullName(name2):lower()
    
    -- Compare full names
    return fullName1 == fullName2
end

-- Keyword matching
local function isMatchingKeyword(msg)
    msg = msg:lower():gsub("^%s+", ""):gsub("%s+$", "")
    
    if msg == config.inviteKeyword:lower() then
        return true
    end
    
    local keywordLength = #config.inviteKeyword
    if msg:sub(1, keywordLength) == config.inviteKeyword:lower() then
        local nextChar = msg:sub(keywordLength + 1, keywordLength + 1)
        return nextChar == " " or nextChar == ""
    end
    
    return false
end

-- Check if already in group (handles connected realms)
local function IsPlayerInGroup(playerName)
    local displayName = GetDisplayName(playerName):lower()
    local fullNameToCheck = GetFullName(playerName):lower()
    
    -- Check if player is in raid
    if IsInRaid() then
        for i = 1, 40 do
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
            if name then
                local fullNameInRaid = GetFullName(name):lower()
                if fullNameInRaid == fullNameToCheck then
                    return true
                end
            end
        end
    end
    
    -- Check if player is in party (including yourself)
    if GetNumGroupMembers() > 0 then
        -- Check yourself
        local playerFullName = GetFullName(UnitName("player")):lower()
        if playerFullName == fullNameToCheck then
            return true
        end
        
        -- Check party members
        for i = 1, 4 do
            local name = UnitName("party" .. i)
            if name then
                local partyFullName = GetFullName(name):lower()
                if partyFullName == fullNameToCheck then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Check if party is full (5 members including player)
local function IsPartyFull()
    if IsInRaid() then
        return false  -- Already in raid
    end
    
    -- In Classic, GetNumGroupMembers() returns total members including yourself
    -- Party is full when we have 5 total members
    local totalMembers = GetNumGroupMembers()
    return totalMembers >= 5
end

-- Check if raid is full (40 members)
local function IsRaidFull()
    if not IsInRaid() then
        return false  -- Not in raid
    end
    
    local raidCount = GetNumGroupMembers()
    return raidCount >= 40
end

-- Auto convert party to raid when full
local function AutoConvertToRaidIfNeeded()
    if not config.autoConvertToRaid then
        return false
    end
    
    if IsInRaid() then
        return false  -- Already in raid
    end
    
    if IsPartyFull() then
        -- Convert to raid in Classic
        ConvertToRaid()
        print(COLOR_GREEN .. "Advance Auto Invite: Party is full, auto-converted to raid!" .. COLOR_RESET)
        return true
    end
    
    return false
end

-- Spam protection check
local function canInvitePlayer(playerName)
    if not config.spamProtection then
        return true
    end
    
    local fullName = GetFullName(playerName)
    local lastInvite = recentInvites[fullName]
    if lastInvite and (GetTime() - lastInvite) < config.spamCooldown then
        return false, "Cooldown"
    end
    
    recentInvites[fullName] = GetTime()
    return true
end

-- Security checks
local function isPlayerEligible(playerName)
    -- Basic name validation only
    if not playerName or playerName == "" or playerName:match("[%c%z]") then
        return false, "Invalid player name"
    end
    
    return true
end

-- Load configuration
local function LoadConfig()
    if AdvancedAutoInviteDB then
        config.inviteKeyword = AdvancedAutoInviteDB.inviteKeyword or config.inviteKeyword
        config.autoInviteEnabled = AdvancedAutoInviteDB.autoInviteEnabled ~= nil and AdvancedAutoInviteDB.autoInviteEnabled or config.autoInviteEnabled
        config.sendWhisperResponse = AdvancedAutoInviteDB.sendWhisperResponse ~= nil and AdvancedAutoInviteDB.sendWhisperResponse or config.sendWhisperResponse
        config.whisperMessage = AdvancedAutoInviteDB.whisperMessage or config.whisperMessage
        config.spamProtection = AdvancedAutoInviteDB.spamProtection ~= nil and AdvancedAutoInviteDB.spamProtection or config.spamProtection
        config.spamCooldown = AdvancedAutoInviteDB.spamCooldown or config.spamCooldown
        config.autoConvertToRaid = AdvancedAutoInviteDB.autoConvertToRaid ~= nil and AdvancedAutoInviteDB.autoConvertToRaid or config.autoConvertToRaid
    else
        AdvancedAutoInviteDB = {}
    end
    
    ValidateConfig()
    
    AdvancedAutoInviteDB.inviteKeyword = config.inviteKeyword
    AdvancedAutoInviteDB.autoInviteEnabled = config.autoInviteEnabled
    AdvancedAutoInviteDB.sendWhisperResponse = config.sendWhisperResponse
    AdvancedAutoInviteDB.whisperMessage = config.whisperMessage
    AdvancedAutoInviteDB.spamProtection = config.spamProtection
    AdvancedAutoInviteDB.spamCooldown = config.spamCooldown
    AdvancedAutoInviteDB.autoConvertToRaid = config.autoConvertToRaid
end

-- Save configuration
local function SaveConfig()
    if AdvancedAutoInviteDB then
        AdvancedAutoInviteDB.inviteKeyword = config.inviteKeyword
        AdvancedAutoInviteDB.autoInviteEnabled = config.autoInviteEnabled
        AdvancedAutoInviteDB.sendWhisperResponse = config.sendWhisperResponse
        AdvancedAutoInviteDB.whisperMessage = config.whisperMessage
        AdvancedAutoInviteDB.spamProtection = config.spamProtection
        AdvancedAutoInviteDB.spamCooldown = config.spamCooldown
        AdvancedAutoInviteDB.autoConvertToRaid = config.autoConvertToRaid
    end
end

-- Main event handler
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_WHISPER")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
    if event == "ADDON_LOADED" then
        local addonName = arg1
        if addonName == "AdvancedAutoInvite" then
            LoadConfig()
            
            print(COLOR_CYAN .. "Advance Auto Invite V" .. version .. COLOR_RESET .. 
                  COLOR_GREEN .. " loaded!" .. COLOR_RESET)
            print(COLOR_WHITE .. "Type " .. COLOR_YELLOW .. "/aai help" .. 
                  COLOR_WHITE .. " for commands" .. COLOR_RESET)
        end
    elseif event == "CHAT_MSG_WHISPER" then
        if not config.autoInviteEnabled then return end
        
        local playerName = arg2
        local message = arg1
        
        -- ALWAYS try to invite if keyword matches
        if isMatchingKeyword(message) then
            -- Check if already in group
            if IsPlayerInGroup(playerName) then
                print(COLOR_YELLOW .. "Advance Auto Invite: " .. GetDisplayName(playerName) .. " is already in group." .. COLOR_RESET)
                return
            end
            
            -- Check if raid is full
            if IsRaidFull() then
                print(COLOR_RED .. "Advance Auto Invite: Raid is full (40/40), cannot invite " .. 
                      COLOR_YELLOW .. GetDisplayName(playerName) .. COLOR_RESET)
                return
            end
            
            -- Check if party is full and auto-convert to raid
            if IsPartyFull() then
                if config.autoConvertToRaid then
                    AutoConvertToRaidIfNeeded()
                else
                    print(COLOR_RED .. "Advance Auto Invite: Party is full (5/5), cannot invite " .. 
                          COLOR_YELLOW .. GetDisplayName(playerName) .. COLOR_RESET)
                    return
                end
            end
            
            -- Check spam protection
            local canInvite, spamReason = canInvitePlayer(playerName)
            if not canInvite then
                print(COLOR_RED .. "Advance Auto Invite: Spam protection - " .. 
                      COLOR_YELLOW .. GetDisplayName(playerName) .. COLOR_RED .. " is on cooldown" .. COLOR_RESET)
                return
            end
            
            -- Check basic eligibility
            local isEligible, securityReason = isPlayerEligible(playerName)
            if not isEligible then
                print(COLOR_RED .. "Advance Auto Invite: Invalid player name: " .. 
                      COLOR_YELLOW .. GetDisplayName(playerName) .. COLOR_RESET)
                return
            end
            
            -- All checks passed, invite player
            InviteUnit(playerName)
            print(COLOR_GREEN .. "Advance Auto Invite: Auto-invited " .. 
                  COLOR_YELLOW .. GetDisplayName(playerName) .. COLOR_GREEN .. " based on whisper." .. COLOR_RESET)
            
            -- Send whisper confirmation
            if config.sendWhisperResponse then
                SendWhisperMessage(playerName, config.whisperMessage)
                print(COLOR_CYAN .. "Advance Auto Invite: Sent personalized whisper to " .. 
                      COLOR_YELLOW .. GetDisplayName(playerName) .. COLOR_RESET)
            end
        end
    end
end)

-- Slash commands
SLASH_ADVANCEDAUTOINVITE1 = "/advancedautoinvite"
SLASH_ADVANCEDAUTOINVITE2 = "/aai"

SlashCmdList["ADVANCEDAUTOINVITE"] = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "help" or command == "" then
        print(COLOR_GOLD .. "=== Advance Auto Invite Commands ===" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai help" .. COLOR_WHITE .. " - Show this help" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai version" .. COLOR_WHITE .. " - Show version" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai setinv [word]" .. COLOR_WHITE .. " - Set invite keyword" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai toggle" .. COLOR_WHITE .. " - Enable/disable auto-invite" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai whisper [on/off]" .. COLOR_WHITE .. " - Enable/disable whispers" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai setmessage [text]" .. COLOR_WHITE .. " - Set whisper message" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai spam [on/off]" .. COLOR_WHITE .. " - Enable/disable spam protection" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai cooldown [seconds]" .. COLOR_WHITE .. " - Set spam cooldown (5-300)" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai autoraid [on/off]" .. COLOR_WHITE .. " - Enable/disable auto raid conversion" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai status" .. COLOR_WHITE .. " - Show current settings" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai clearcache" .. COLOR_WHITE .. " - Clear spam cache" .. COLOR_RESET)
        print(COLOR_CYAN .. "Use {name} in whisper message to include player name" .. COLOR_RESET)
        
    elseif command == "version" then
        print(COLOR_CYAN .. "Advance Auto Invite Version: " .. COLOR_GREEN .. version .. COLOR_RESET)
        
    elseif command == "setinv" then
        if rest and rest ~= "" then
            config.inviteKeyword = rest:lower()
            ValidateConfig()
            SaveConfig()
            print(COLOR_GREEN .. "Invite keyword set to: " .. COLOR_YELLOW .. config.inviteKeyword .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/aai setinv [word]" .. COLOR_RESET)
        end
        
    elseif command == "toggle" then
        config.autoInviteEnabled = not config.autoInviteEnabled
        SaveConfig()
        print(COLOR_GREEN .. "Auto-invite " .. 
              (config.autoInviteEnabled and COLOR_YELLOW .. "enabled" or COLOR_YELLOW .. "disabled") .. 
              COLOR_RESET)
        
    elseif command == "whisper" then
        if rest == "on" then
            config.sendWhisperResponse = true
            SaveConfig()
            print(COLOR_GREEN .. "Whisper responses enabled" .. COLOR_RESET)
        elseif rest == "off" then
            config.sendWhisperResponse = false
            SaveConfig()
            print(COLOR_RED .. "Whisper responses disabled" .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/aai whisper [on/off]" .. COLOR_RESET)
        end
        
    elseif command == "setmessage" then
        if rest and rest ~= "" then
            config.whisperMessage = rest
            SaveConfig()
            print(COLOR_GREEN .. "Whisper message set to: " .. COLOR_YELLOW .. config.whisperMessage .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/aai setmessage [text]" .. COLOR_RESET)
        end
        
    elseif command == "spam" then
        if rest == "on" then
            config.spamProtection = true
            SaveConfig()
            print(COLOR_GREEN .. "Spam protection enabled" .. COLOR_RESET)
        elseif rest == "off" then
            config.spamProtection = false
            SaveConfig()
            print(COLOR_RED .. "Spam protection disabled" .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/aai spam [on/off]" .. COLOR_RESET)
        end
        
    elseif command == "cooldown" then
        local cooldown = tonumber(rest)
        if cooldown and cooldown >= 5 and cooldown <= 300 then
            config.spamCooldown = cooldown
            SaveConfig()
            print(COLOR_GREEN .. "Spam cooldown set to: " .. COLOR_YELLOW .. config.spamCooldown .. " seconds" .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/aai cooldown [5-300]" .. COLOR_RESET)
        end
        
    elseif command == "autoraid" then
        if rest == "on" then
            config.autoConvertToRaid = true
            SaveConfig()
            print(COLOR_GREEN .. "Auto raid conversion enabled" .. COLOR_RESET)
        elseif rest == "off" then
            config.autoConvertToRaid = false
            SaveConfig()
            print(COLOR_RED .. "Auto raid conversion disabled" .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/aai autoraid [on/off]" .. COLOR_RESET)
        end
        
    elseif command == "clearcache" then
        recentInvites = {}
        print(COLOR_GREEN .. "Spam protection cache cleared" .. COLOR_RESET)
        
    elseif command == "status" then
        print(COLOR_GOLD .. "=== Advance Auto Invite Status ===" .. COLOR_RESET)
        print(COLOR_WHITE .. "Version: " .. COLOR_CYAN .. version .. COLOR_RESET)
        print(COLOR_WHITE .. "Enabled: " .. (config.autoInviteEnabled and COLOR_GREEN .. "Yes" or COLOR_RED .. "No") .. COLOR_RESET)
        print(COLOR_WHITE .. "Keyword: " .. COLOR_YELLOW .. config.inviteKeyword .. COLOR_RESET)
        print(COLOR_WHITE .. "Whisper Responses: " .. (config.sendWhisperResponse and COLOR_GREEN .. "Yes" or COLOR_RED .. "No") .. COLOR_RESET)
        if config.sendWhisperResponse then
            print(COLOR_WHITE .. "Whisper Message: " .. COLOR_YELLOW .. config.whisperMessage .. COLOR_RESET)
        end
        print(COLOR_WHITE .. "Spam Protection: " .. (config.spamProtection and COLOR_GREEN .. "Yes" or COLOR_RED .. "No") .. COLOR_RESET)
        if config.spamProtection then
            print(COLOR_WHITE .. "Spam Cooldown: " .. COLOR_YELLOW .. config.spamCooldown .. " seconds" .. COLOR_RESET)
        end
        print(COLOR_WHITE .. "Auto Raid Conversion: " .. (config.autoConvertToRaid and COLOR_GREEN .. "Yes" or COLOR_RED .. "No") .. COLOR_RESET)
        print(COLOR_WHITE .. "Party Full: " .. (IsPartyFull() and COLOR_RED .. "Yes" or COLOR_GREEN .. "No") .. COLOR_RESET)
        print(COLOR_WHITE .. "Raid Full: " .. (IsRaidFull() and COLOR_RED .. "Yes" or COLOR_GREEN .. "No") .. COLOR_RESET)
        
    else
        print(COLOR_RED .. "Unknown command. Type " .. COLOR_YELLOW .. "/aai help" .. COLOR_RED .. " for options" .. COLOR_RESET)
    end
end

-- Initialize
if IsLoggedIn() then
    LoadConfig()
else
    local loginFrame = CreateFrame("Frame")
    loginFrame:RegisterEvent("PLAYER_LOGIN")
    loginFrame:SetScript("OnEvent", function()
        LoadConfig()
    end)
end