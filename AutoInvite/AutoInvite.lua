local inviteKeyword = "inv"
local version = "1.0"

-- Create frame to listen to chat whispers
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_WHISPER")
f:SetScript("OnEvent", function(self, event, arg1, arg2)
    -- Check if whisper matches the invite keyword
    if (not UnitExists("party1") or IsPartyLeader("player")) and arg1:lower():match("^" .. inviteKeyword .. "$") then
        InviteUnit(arg2)
    end
end)

-- Slash command setup
SLASH_AUTOINVITE1 = "/autoinvite"
SlashCmdList["AUTOINVITE"] = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "help" or command == "" then
        print("AutoInvite Addon Commands:")
        print("/autoinvite help - Show this help message")
        print("/autoinvite version - Show addon version")
        print("/autoinvite setinv [word] - Set the whisper keyword for invite")
    elseif command == "version" then
        print("AutoInvite Version: " .. version)
    elseif command == "setinv" then
        if rest and rest ~= "" then
            inviteKeyword = rest:lower()
            print("Invite whisper keyword set to: " .. inviteKeyword)
        else
            print("Usage: /autoinvite setinv [word]")
        end
    else
        print("Unknown command. Type /autoinvite help for options.")
    end
end