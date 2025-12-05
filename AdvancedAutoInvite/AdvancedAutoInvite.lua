local version = "1.2"

-- Enhanced configuration
local config = {
    inviteKeyword = "inv",
    autoInviteEnabled = true,
    sendWhisperResponse = true,
    whisperMessage = "Hello {name}, welcome to the party!",
    spamProtection = true,
    spamCooldown = 30, -- seconds
    securityChecks = true
}

-- Color codes for WoW Classic
local COLOR_GREEN = "|cFF00FF00"
local COLOR_RED = "|cFFFF0000"
local COLOR_YELLOW = "|cFFFFFF00"
local COLOR_CYAN = "|cFF00FFFF"
local COLOR_WHITE = "|cFFFFFFFF"
local COLOR_GOLD = "|cFFFFD700"
local COLOR_RESET = "|r"

-- Spam protection table
local recentInvites = {}

-- Validate configuration
local function ValidateConfig()
    -- Ensure keyword is valid
    if not config.inviteKeyword or config.inviteKeyword:len() < 2 then
        config.inviteKeyword = "inv"
        print(COLOR_YELLOW .. "AdvancedAutoInvite: Reset invalid keyword to default 'inv'" .. COLOR_RESET)
    end
    
    -- Remove any spaces from keyword and limit length
    config.inviteKeyword = config.inviteKeyword:gsub("%s+", ""):sub(1, 20):lower()
    
    -- Ensure whisper message is valid and not too long
    if not config.whisperMessage or config.whisperMessage:len() == 0 then
        config.whisperMessage = "Hello {name}, welcome to the party!"
    else
        config.whisperMessage = config.whisperMessage:sub(1, 255) -- WoW chat limit
    end
    
    -- Validate spam cooldown
    if not config.spamCooldown or config.spamCooldown < 5 then
        config.spamCooldown = 30
    elseif config.spamCooldown > 300 then
        config.spamCooldown = 300
    end
    
    -- Ensure boolean settings are valid
    config.spamProtection = config.spamProtection == true
    config.securityChecks = config.securityChecks == true
end

-- Function to send whisper message - UPDATED TO INCLUDE PLAYER NAME
local function SendWhisperMessage(playerName, message)
    if not playerName or playerName == "" then return end
    if not message or message:len() == 0 then return end
    
    -- Personalize the message by replacing {name} with the actual player name
    local personalizedMessage = message:gsub("{name}", playerName)
    
    SendChatMessage(personalizedMessage, "WHISPER", nil, playerName)
end

-- Enhanced keyword matching using config
local function isMatchingKeyword(msg)
    msg = msg:lower():gsub("^%s+", ""):gsub("%s+$", "") -- trim both sides
    
    -- Exact match
    if msg == config.inviteKeyword:lower() then
        return true
    end
    
    -- Match "keyword something" but not "keywordsomething"
    local keywordLength = #config.inviteKeyword
    if msg:sub(1, keywordLength) == config.inviteKeyword:lower() then
        -- Check if next character is space or end of string
        local nextChar = msg:sub(keywordLength + 1, keywordLength + 1)
        return nextChar == " " or nextChar == ""
    end
    
    return false
end

-- Enhanced party state checking for WoW Classic
local function canInvitePlayers()
    -- Not in a party or raid
    if not UnitInParty("player") and not UnitInRaid("player") then
        return true
    end
    
    -- In party and is leader (Classic API)
    if UnitInParty("player") and not UnitInRaid("player") and UnitIsPartyLeader("player") then
        return true
    end
    
    -- In raid and is leader (Classic API)
    if UnitInRaid("player") and UnitIsRaidLeader("player") then
        return true
    end
    
    return false
end

-- NEW: Check if group is full (WoW Classic API)
local function isGroupFull()
    if UnitInRaid("player") then
        return GetNumRaidMembers() >= 40
    elseif UnitInParty("player") then
        return GetNumPartyMembers() >= 4 -- Classic: 5 total including player
    end
    return false
end

-- NEW: Spam protection check
local function canInvitePlayer(playerName)
    if not config.spamProtection then
        return true
    end
    
    local lastInvite = recentInvites[playerName]
    if lastInvite and (GetTime() - lastInvite) < config.spamCooldown then
        return false, "Cooldown"
    end
    
    recentInvites[playerName] = GetTime()
    return true
end

-- NEW: Security checks for WoW Classic - SIMPLIFIED IGNORE CHECK
local function isPlayerEligible(playerName)
    if not config.securityChecks then
        return true
    end
    
    -- In Classic, ignore checking is complex. For now, we'll skip this check
    -- to avoid API issues. Users can disable security checks if needed.
    -- Commenting out the problematic ignore check for now.
    
    -- Check if player is from same faction (Classic realm check)
    local playerRealm = GetRealmName()
    local targetName, targetRealm = strsplit("-", playerName)
    
    -- If realms don't match and we're not on the same realm, likely cross-faction in Classic
    if targetRealm and targetRealm ~= playerRealm then
        return false, "Cross-realm player"
    end
    
    return true
end

-- Load configuration from saved variables
local function LoadConfig()
    if AdvancedAutoInviteDB then
        -- Migrate old settings if they exist
        config.inviteKeyword = AdvancedAutoInviteDB.inviteKeyword or config.inviteKeyword
        config.autoInviteEnabled = AdvancedAutoInviteDB.autoInviteEnabled ~= nil and AdvancedAutoInviteDB.autoInviteEnabled or config.autoInviteEnabled
        config.sendWhisperResponse = AdvancedAutoInviteDB.sendWhisperResponse ~= nil and AdvancedAutoInviteDB.sendWhisperResponse or config.sendWhisperResponse
        config.whisperMessage = AdvancedAutoInviteDB.whisperMessage or config.whisperMessage
        config.spamProtection = AdvancedAutoInviteDB.spamProtection ~= nil and AdvancedAutoInviteDB.spamProtection or config.spamProtection
        config.spamCooldown = AdvancedAutoInviteDB.spamCooldown or config.spamCooldown
        config.securityChecks = AdvancedAutoInviteDB.securityChecks ~= nil and AdvancedAutoInviteDB.securityChecks or config.securityChecks
    else
        -- Initialize saved variables
        AdvancedAutoInviteDB = {}
    end
    
    -- Validate and clean config
    ValidateConfig()
    
    -- Save current config to DB
    AdvancedAutoInviteDB.inviteKeyword = config.inviteKeyword
    AdvancedAutoInviteDB.autoInviteEnabled = config.autoInviteEnabled
    AdvancedAutoInviteDB.sendWhisperResponse = config.sendWhisperResponse
    AdvancedAutoInviteDB.whisperMessage = config.whisperMessage
    AdvancedAutoInviteDB.spamProtection = config.spamProtection
    AdvancedAutoInviteDB.spamCooldown = config.spamCooldown
    AdvancedAutoInviteDB.securityChecks = config.securityChecks
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
        AdvancedAutoInviteDB.securityChecks = config.securityChecks
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_WHISPER")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
    if event == "ADDON_LOADED" then
        local addonName = arg1
        if addonName == "AdvancedAutoInvite" then
            LoadConfig()
            
            print(COLOR_CYAN .. "Advanced Auto Invite V" .. version .. COLOR_RESET .. 
                  COLOR_GREEN .. " loaded!" .. COLOR_RESET)
            print(COLOR_WHITE .. "Type " .. COLOR_YELLOW .. "/aai help" .. 
                  COLOR_WHITE .. " for commands" .. COLOR_RESET)
        end
    elseif event == "CHAT_MSG_WHISPER" then
        if not config.autoInviteEnabled then return end
        
        local playerName = arg2
        local message = arg1
        
        if canInvitePlayers() then
            if isMatchingKeyword(message) then
                -- Check if player is already in group (Classic API)
                local alreadyInGroup = false
                if UnitInRaid("player") then
                    for i = 1, GetNumRaidMembers() do
                        local name = UnitName("raid" .. i)
                        if name == playerName then
                            alreadyInGroup = true
                            break
                        end
                    end
                elseif UnitInParty("player") then
                    for i = 1, GetNumPartyMembers() do
                        local name = UnitName("party" .. i)
                        if name == playerName then
                            alreadyInGroup = true
                            break
                        end
                    end
                    -- Also check player themselves
                    if UnitName("player") == playerName then
                        alreadyInGroup = true
                    end
                end
                
                if not alreadyInGroup then
                    -- NEW: Check if group is full
                    if isGroupFull() then
                        print(COLOR_RED .. "AdvancedAutoInvite: Group is full, cannot invite " .. 
                              COLOR_YELLOW .. playerName .. COLOR_RESET)
                        return
                    end
                    
                    -- NEW: Check spam protection
                    local canInvite, spamReason = canInvitePlayer(playerName)
                    if not canInvite then
                        print(COLOR_RED .. "AdvancedAutoInvite: Spam protection - " .. 
                              COLOR_YELLOW .. playerName .. COLOR_RED .. " is on cooldown" .. COLOR_RESET)
                        return
                    end
                    
                    -- NEW: Check security
                    local isEligible, securityReason = isPlayerEligible(playerName)
                    if not isEligible then
                        print(COLOR_RED .. "AdvancedAutoInvite: Security check failed for " .. 
                              COLOR_YELLOW .. playerName .. COLOR_RED .. " - " .. securityReason .. COLOR_RESET)
                        return
                    end
                    
                    -- All checks passed, invite the player (Classic API)
                    InviteUnit(playerName)
                    print(COLOR_GREEN .. "AdvancedAutoInvite: Auto-invited " .. 
                          COLOR_YELLOW .. playerName .. COLOR_GREEN .. " based on whisper." .. COLOR_RESET)
                    
                    -- Send whisper confirmation if enabled
                    if config.sendWhisperResponse then
                        SendWhisperMessage(playerName, config.whisperMessage)
                        print(COLOR_CYAN .. "AdvancedAutoInvite: Sent personalized whisper to " .. 
                              COLOR_YELLOW .. playerName .. COLOR_RESET)
                    end
                end
            end
        end
    end
end)

SLASH_ADVANCEDAUTOINVITE1 = "/advancedautoinvite"
SLASH_ADVANCEDAUTOINVITE2 = "/aai"  -- Added shorter alias

SlashCmdList["ADVANCEDAUTOINVITE"] = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "help" or command == "" then
        print(COLOR_GOLD .. "=== Advanced Auto Invite Commands ===" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite help" .. COLOR_WHITE .. " - Show this help message" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite version" .. COLOR_WHITE .. " - Show addon version" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite setinv [word]" .. COLOR_WHITE .. " - Set the invite keyword" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite toggle" .. COLOR_WHITE .. " - Enable/disable auto-invite" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite whisper [on/off]" .. COLOR_WHITE .. " - Enable/disable whisper responses" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite setmessage [text]" .. COLOR_WHITE .. " - Set custom whisper message" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite spam [on/off]" .. COLOR_WHITE .. " - Enable/disable spam protection" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite cooldown [seconds]" .. COLOR_WHITE .. " - Set spam cooldown (5-300)" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite security [on/off]" .. COLOR_WHITE .. " - Enable/disable security checks" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite status" .. COLOR_WHITE .. " - Show current settings" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite clearcache" .. COLOR_WHITE .. " - Clear spam protection cache" .. COLOR_RESET)
        print(COLOR_CYAN .. "Alias: " .. COLOR_YELLOW .. "/aai" .. COLOR_RESET)
        print(COLOR_WHITE .. "Note: Use " .. COLOR_YELLOW .. "{name}" .. COLOR_WHITE .. " in your whisper message to include the player's name." .. COLOR_RESET)
    elseif command == "version" then
        print(COLOR_CYAN .. "AdvancedAutoInvite Version: " .. COLOR_GREEN .. version .. COLOR_RESET)
    elseif command == "setinv" then
        if rest and rest ~= "" then
            config.inviteKeyword = rest:lower()
            ValidateConfig()
            SaveConfig()
            print(COLOR_GREEN .. "Invite keyword set to: " .. COLOR_YELLOW .. config.inviteKeyword .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/advancedautoinvite setinv [word]" .. COLOR_RESET)
        end
    elseif command == "toggle" then
        config.autoInviteEnabled = not config.autoInviteEnabled
        SaveConfig()
        if config.autoInviteEnabled then
            print(COLOR_GREEN .. "AdvancedAutoInvite " .. COLOR_YELLOW .. "enabled" .. COLOR_GREEN .. "." .. COLOR_RESET)
        else
            print(COLOR_RED .. "AdvancedAutoInvite " .. COLOR_YELLOW .. "disabled" .. COLOR_RED .. "." .. COLOR_RESET)
        end
    elseif command == "whisper" then
        if rest == "on" then
            config.sendWhisperResponse = true
            SaveConfig()
            print(COLOR_GREEN .. "Whisper responses " .. COLOR_YELLOW .. "enabled" .. COLOR_GREEN .. "." .. COLOR_RESET)
        elseif rest == "off" then
            config.sendWhisperResponse = false
            SaveConfig()
            print(COLOR_RED .. "Whisper responses " .. COLOR_YELLOW .. "disabled" .. COLOR_RED .. "." .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/advancedautoinvite whisper [on/off]" .. COLOR_RESET)
        end
    elseif command == "setmessage" then
        if rest and rest ~= "" then
            config.whisperMessage = rest
            SaveConfig()
            print(COLOR_GREEN .. "Whisper message set to: " .. COLOR_YELLOW .. config.whisperMessage .. COLOR_RESET)
            print(COLOR_CYAN .. "Tip: Use " .. COLOR_YELLOW .. "{name}" .. COLOR_CYAN .. " to include the player's name automatically." .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/advancedautoinvite setmessage [text]" .. COLOR_RESET)
        end
    elseif command == "spam" then
        if rest == "on" then
            config.spamProtection = true
            SaveConfig()
            print(COLOR_GREEN .. "Spam protection " .. COLOR_YELLOW .. "enabled" .. COLOR_GREEN .. "." .. COLOR_RESET)
        elseif rest == "off" then
            config.spamProtection = false
            SaveConfig()
            print(COLOR_RED .. "Spam protection " .. COLOR_YELLOW .. "disabled" .. COLOR_RED .. "." .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/advancedautoinvite spam [on/off]" .. COLOR_RESET)
        end
    elseif command == "cooldown" then
        local cooldown = tonumber(rest)
        if cooldown and cooldown >= 5 and cooldown <= 300 then
            config.spamCooldown = cooldown
            SaveConfig()
            print(COLOR_GREEN .. "Spam cooldown set to: " .. COLOR_YELLOW .. config.spamCooldown .. " seconds" .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/advancedautoinvite cooldown [5-300]" .. COLOR_RESET)
        end
    elseif command == "security" then
        if rest == "on" then
            config.securityChecks = true
            SaveConfig()
            print(COLOR_GREEN .. "Security checks " .. COLOR_YELLOW .. "enabled" .. COLOR_GREEN .. "." .. COLOR_RESET)
        elseif rest == "off" then
            config.securityChecks = false
            SaveConfig()
            print(COLOR_RED .. "Security checks " .. COLOR_YELLOW .. "disabled" .. COLOR_RED .. "." .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/advancedautoinvite security [on/off]" .. COLOR_RESET)
        end
    elseif command == "clearcache" then
        recentInvites = {}
        print(COLOR_GREEN .. "Spam protection cache cleared." .. COLOR_RESET)
    elseif command == "status" then
        print(COLOR_GOLD .. "=== Advanced Auto Invite Status ===" .. COLOR_RESET)
        print(COLOR_WHITE .. "Version: " .. COLOR_CYAN .. version .. COLOR_RESET)
        print(COLOR_WHITE .. "Enabled: " .. 
              (config.autoInviteEnabled and (COLOR_GREEN .. "Yes") or (COLOR_RED .. "No")) .. COLOR_RESET)
        print(COLOR_WHITE .. "Keyword: " .. COLOR_YELLOW .. config.inviteKeyword .. COLOR_RESET)
        print(COLOR_WHITE .. "Whisper Responses: " .. 
              (config.sendWhisperResponse and (COLOR_GREEN .. "Yes") or (COLOR_RED .. "No")) .. COLOR_RESET)
        if config.sendWhisperResponse then
            print(COLOR_WHITE .. "Whisper Message: " .. COLOR_YELLOW .. config.whisperMessage .. COLOR_RESET)
            print(COLOR_CYAN .. "  (Will be personalized with player name using {name})" .. COLOR_RESET)
        end
        print(COLOR_WHITE .. "Spam Protection: " .. 
              (config.spamProtection and (COLOR_GREEN .. "Yes") or (COLOR_RED .. "No")) .. COLOR_RESET)
        if config.spamProtection then
            print(COLOR_WHITE .. "Spam Cooldown: " .. COLOR_YELLOW .. config.spamCooldown .. " seconds" .. COLOR_RESET)
        end
        print(COLOR_WHITE .. "Security Checks: " .. 
              (config.securityChecks and (COLOR_GREEN .. "Yes") or (COLOR_RED .. "No")) .. COLOR_RESET)
        print(COLOR_WHITE .. "Ready: " .. 
              (canInvitePlayers() and (COLOR_GREEN .. "Yes") or (COLOR_RED .. "No")) .. COLOR_RESET)
        print(COLOR_WHITE .. "Group Full: " .. 
              (isGroupFull() and (COLOR_RED .. "Yes") or (COLOR_GREEN .. "No")) .. COLOR_RESET)
    else
        print(COLOR_RED .. "Unknown command. Type " .. 
              COLOR_YELLOW .. "/advancedautoinvite help" .. 
              COLOR_RED .. " for options." .. COLOR_RESET)
    end
end

-- Initialize when addon loads
if IsLoggedIn() then
    LoadConfig()
else
    -- Wait for login if addon is loaded at login
    local loginFrame = CreateFrame("Frame")
    loginFrame:RegisterEvent("PLAYER_LOGIN")
    loginFrame:SetScript("OnEvent", function()
        LoadConfig()
    end)
end