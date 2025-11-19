local version = "1.0"

-- Default configuration
local config = {
    inviteKeyword = "inv",
    autoInviteEnabled = true
}

-- Color codes for WoW Classic
local COLOR_GREEN = "|cFF00FF00"
local COLOR_RED = "|cFFFF0000"
local COLOR_YELLOW = "|cFFFFFF00"
local COLOR_CYAN = "|cFF00FFFF"
local COLOR_WHITE = "|cFFFFFFFF"
local COLOR_GOLD = "|cFFFFD700"
local COLOR_RESET = "|r"

-- Load configuration from saved variables
local function LoadConfig()
    if AdvancedAutoInviteDB then
        -- Migrate old settings if they exist
        if AdvancedAutoInviteDB.inviteKeyword then
            config.inviteKeyword = AdvancedAutoInviteDB.inviteKeyword
        end
        if AdvancedAutoInviteDB.autoInviteEnabled ~= nil then
            config.autoInviteEnabled = AdvancedAutoInviteDB.autoInviteEnabled
        end
    else
        -- Initialize saved variables
        AdvancedAutoInviteDB = {}
    end
    
    -- Save current config to DB
    AdvancedAutoInviteDB.inviteKeyword = config.inviteKeyword
    AdvancedAutoInviteDB.autoInviteEnabled = config.autoInviteEnabled
end

-- Save configuration
local function SaveConfig()
    if AdvancedAutoInviteDB then
        AdvancedAutoInviteDB.inviteKeyword = config.inviteKeyword
        AdvancedAutoInviteDB.autoInviteEnabled = config.autoInviteEnabled
    end
end

-- Default invite keyword
local inviteKeyword = config.inviteKeyword
local autoInviteEnabled = config.autoInviteEnabled

local function isMatchingKeyword(msg)
    msg = msg:lower():gsub("^%s+", ""):gsub("%s+$", "") -- trim both sides
    
    -- Only match exactly "inv" (no other text allowed)
    return msg == "inv"
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_WHISPER")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
    if event == "ADDON_LOADED" then
        local addonName = arg1
        if addonName == "AdvancedAutoInvite" then
            LoadConfig()
            -- Update local variables with loaded config
            inviteKeyword = config.inviteKeyword
            autoInviteEnabled = config.autoInviteEnabled
            
            print(COLOR_CYAN .. "AdvancedAutoInvite v" .. version .. COLOR_RESET .. 
                  COLOR_GREEN .. " loaded!" .. COLOR_RESET)
            print(COLOR_WHITE .. "Type " .. COLOR_YELLOW .. "/advancedautoinvite help" .. 
                  COLOR_WHITE .. " for commands" .. COLOR_RESET)
        end
    elseif event == "CHAT_MSG_WHISPER" then
        if not autoInviteEnabled then return end
        if (not UnitExists("party1") or IsPartyLeader("player")) then
            if isMatchingKeyword(arg1) then
                if not UnitInParty("player") then
                    InviteUnit(arg2)
                    print(COLOR_GREEN .. "AdvancedAutoInvite: Auto-invited " .. 
                      COLOR_YELLOW .. arg2 .. COLOR_GREEN .. " based on whisper." .. COLOR_RESET)
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
        print(COLOR_GOLD .. "=== AdvancedAutoInvite Commands ===" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite help" .. COLOR_WHITE .. " - Show this help message" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite version" .. COLOR_WHITE .. " - Show addon version" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite setinv [word]" .. COLOR_WHITE .. " - Set the invite keyword" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite toggle" .. COLOR_WHITE .. " - Enable/disable auto-invite" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/advancedautoinvite status" .. COLOR_WHITE .. " - Show current settings" .. COLOR_RESET)
        print(COLOR_CYAN .. "Alias: " .. COLOR_YELLOW .. "/aai" .. COLOR_RESET)
    elseif command == "version" then
        print(COLOR_CYAN .. "AdvancedAutoInvite Version: " .. COLOR_GREEN .. version .. COLOR_RESET)
    elseif command == "setinv" then
        if rest and rest ~= "" then
            config.inviteKeyword = rest:lower()
            inviteKeyword = config.inviteKeyword
            SaveConfig()
            print(COLOR_GREEN .. "Invite keyword set to: " .. COLOR_YELLOW .. config.inviteKeyword .. COLOR_RESET)
        else
            print(COLOR_RED .. "Usage: " .. COLOR_YELLOW .. "/advancedautoinvite setinv [word]" .. COLOR_RESET)
        end
    elseif command == "toggle" then
        config.autoInviteEnabled = not config.autoInviteEnabled
        autoInviteEnabled = config.autoInviteEnabled
        SaveConfig()
        if config.autoInviteEnabled then
            print(COLOR_GREEN .. "AdvancedAutoInvite " .. COLOR_YELLOW .. "enabled" .. COLOR_GREEN .. "." .. COLOR_RESET)
        else
            print(COLOR_RED .. "AdvancedAutoInvite " .. COLOR_YELLOW .. "disabled" .. COLOR_RED .. "." .. COLOR_RESET)
        end
    elseif command == "status" then
        print(COLOR_GOLD .. "=== AdvancedAutoInvite Status ===" .. COLOR_RESET)
        print(COLOR_WHITE .. "Version: " .. COLOR_CYAN .. version .. COLOR_RESET)
        print(COLOR_WHITE .. "Enabled: " .. 
              (config.autoInviteEnabled and (COLOR_GREEN .. "Yes") or (COLOR_RED .. "No")) .. COLOR_RESET)
        print(COLOR_WHITE .. "Keyword: " .. COLOR_YELLOW .. config.inviteKeyword .. COLOR_RESET)
        print(COLOR_WHITE .. "Ready: " .. 
              ((not UnitExists("party1") or IsPartyLeader("player")) and 
              (COLOR_GREEN .. "Yes") or (COLOR_RED .. "No")) .. COLOR_RESET)
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