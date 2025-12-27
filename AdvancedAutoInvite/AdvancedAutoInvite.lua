local version = "1.5"

-- Color codes
local COLOR_GREEN = "|cFF00FF00"
local COLOR_RED = "|cFFFF0000"
local COLOR_YELLOW = "|cFFFFFF00"
local COLOR_CYAN = "|cFF00FFFF"
local COLOR_WHITE = "|cFFFFFFFF"
local COLOR_GOLD = "|cFFFFD700"
local COLOR_BLUE = "|cFF0070DD"
local COLOR_RESET = "|r"

-- Basic configuration
local config = {
    inviteKeyword = "inv",
    autoInviteEnabled = true,
    sendWhisperResponse = true,
    whisperMessage = "Hello {name}, welcome to the party!",
    spamProtection = true,
    spamCooldown = 10,
    autoConvertToRaid = true
}

-- Spam protection
local recentInvites = {}

-- GUI Elements
local configFrame = nil
local lastFeedback = {
    message = "",
    color = COLOR_WHITE,
    time = 0
}

-- ============================================
-- CONFIG MANAGEMENT
-- ============================================

-- Validate configuration
local function ValidateConfig()
    if not config.inviteKeyword or config.inviteKeyword:len() < 2 then
        config.inviteKeyword = "inv"
        ShowFeedback("Reset invalid keyword to default 'inv'", COLOR_YELLOW)
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

-- ============================================
-- CORE FUNCTIONS
-- ============================================

-- Show feedback message
local function ShowFeedback(message, color)
    lastFeedback.message = message
    lastFeedback.color = color
    lastFeedback.time = GetTime()
    
    print(color .. "AAI: " .. message .. COLOR_RESET)
    
    if configFrame and configFrame:IsVisible() then
        UpdateConfigGUI()
    end
end

-- Send whisper message
local function SendWhisperMessage(playerName, message)
    if not playerName or playerName == "" then return end
    if not message or message:len() == 0 then return end
    
    local personalizedMessage = message:gsub("{name}", playerName)
    SendChatMessage(personalizedMessage, "WHISPER", nil, playerName)
end

-- Get display name (remove server suffix)
local function GetDisplayName(fullName)
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

-- Check if player can invite others (Classic Era simplified version)
local function CanPlayerInvite()
    if not IsInGroup() then
        return true
    end
    
    -- In Classic Era, UnitIsGroupLeader works for both party and raid
    if UnitIsGroupLeader("player") then
        return true
    end
    
    -- In Classic Era, only group leaders can invite
    return false
end

-- Try to get invite permissions
local function EnsureInvitePermissions()
    return CanPlayerInvite()
end

-- Check if player is in group (using improved name comparison)
local function IsPlayerInGroup(playerName)
    if IsInRaid() then
        for i = 1, 40 do
            local name = GetRaidRosterInfo(i)
            if name and ComparePlayerNames(name, playerName) then
                return true
            end
        end
    end
    
    if GetNumGroupMembers() > 0 then
        -- Check player themselves
        if ComparePlayerNames(UnitName("player"), playerName) then
            return true
        end
        
        -- Check party members
        for i = 1, 4 do
            local name = UnitName("party" .. i)
            if name and ComparePlayerNames(name, playerName) then
                return true
            end
        end
    end
    
    return false
end

-- Check if party is full
local function IsPartyFull()
    if IsInRaid() then
        return false
    end
    
    local totalMembers = GetNumGroupMembers()
    return totalMembers >= 5
end

-- Check if raid is full
local function IsRaidFull()
    if not IsInRaid() then
        return false
    end
    
    local raidCount = GetNumGroupMembers()
    return raidCount >= 40
end

-- Auto convert party to raid
local function AutoConvertToRaidIfNeeded()
    if not config.autoConvertToRaid then
        return false
    end
    
    if IsInRaid() then
        return false
    end
    
    if IsPartyFull() then
        -- Use UnitIsGroupLeader for Classic compatibility
        if not UnitIsGroupLeader("player") then
            ShowFeedback("Cannot convert to raid - not party leader", COLOR_YELLOW)
            return false
        end
        
        ConvertToRaid()
        ShowFeedback("Party full, auto-converted to raid!", COLOR_GREEN)
        return true
    end
    
    return false
end

-- Spam protection check (using improved name comparison)
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

-- Security check
local function isPlayerEligible(playerName)
    if not playerName or playerName == "" or playerName:match("[%c%z]") then
        return false, "Invalid player name"
    end
    
    return true
end

-- ============================================
-- GUI FUNCTIONS
-- ============================================

-- Create configuration elements
local function CreateConfigElements()
    if not configFrame or not configFrame.scrollChild then return end
    
    local yOffset = -10
    local spacing = 35
    
    -- 1. Enable/Disable
    configFrame.enableCheckbox = CreateFrame("CheckButton", nil, configFrame.scrollChild, "UICheckButtonTemplate")
    configFrame.enableCheckbox:SetPoint("TOPLEFT", 10, yOffset)
    configFrame.enableCheckbox.text:SetText(" Enable Auto Invite")
    configFrame.enableCheckbox.text:SetTextColor(1, 1, 1)
    configFrame.enableCheckbox:SetChecked(config.autoInviteEnabled)
    configFrame.enableCheckbox:SetScript("OnClick", function(self)
        config.autoInviteEnabled = self:GetChecked()
        SaveConfig()
        ShowFeedback("Auto invite " .. (config.autoInviteEnabled and "enabled" or "disabled"), 
                    config.autoInviteEnabled and COLOR_GREEN or COLOR_RED)
    end)
    yOffset = yOffset - spacing
    
    -- 2. Keyword
    configFrame.keywordLabel = configFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    configFrame.keywordLabel:SetPoint("TOPLEFT", 10, yOffset)
    configFrame.keywordLabel:SetText("Invite Keyword:")
    configFrame.keywordLabel:SetTextColor(1, 1, 1)
    
    configFrame.keywordEditBox = CreateFrame("EditBox", nil, configFrame.scrollChild)
    configFrame.keywordEditBox:SetPoint("TOPLEFT", 110, yOffset - 5)
    configFrame.keywordEditBox:SetSize(150, 20)
    configFrame.keywordEditBox:SetFontObject("GameFontHighlight")
    configFrame.keywordEditBox:SetTextInsets(5, 5, 0, 0)
    configFrame.keywordEditBox:SetText(config.inviteKeyword)
    configFrame.keywordEditBox:SetAutoFocus(false)
    
    -- Add background
    local keywordBg = configFrame.keywordEditBox:CreateTexture(nil, "BACKGROUND")
    keywordBg:SetAllPoints()
    keywordBg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Add border
    local keywordBorder = configFrame.keywordEditBox:CreateTexture(nil, "BORDER")
    keywordBorder:SetAllPoints()
    keywordBorder:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    
    -- Store original text for comparison
    configFrame.keywordEditBox.originalText = config.inviteKeyword
    
    configFrame.keywordEditBox:SetScript("OnEditFocusGained", function(self)
        self.originalText = self:GetText()
    end)
    
    configFrame.keywordEditBox:SetScript("OnEditFocusLost", function(self)
        local newText = self:GetText() or ""
        if newText ~= self.originalText then
            config.inviteKeyword = newText
            ValidateConfig()
            SaveConfig()
            ShowFeedback("Keyword set to: " .. config.inviteKeyword, COLOR_YELLOW)
        end
        self:ClearFocus()
    end)
    
    configFrame.keywordEditBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    
    configFrame.keywordEditBox:SetScript("OnEscapePressed", function(self)
        self:SetText(self.originalText)
        self:ClearFocus()
    end)
    
    yOffset = yOffset - spacing
    
    -- 3. Whisper Response
    configFrame.whisperCheckbox = CreateFrame("CheckButton", nil, configFrame.scrollChild, "UICheckButtonTemplate")
    configFrame.whisperCheckbox:SetPoint("TOPLEFT", 10, yOffset)
    configFrame.whisperCheckbox.text:SetText(" Send Whisper Response")
    configFrame.whisperCheckbox.text:SetTextColor(1, 1, 1)
    configFrame.whisperCheckbox:SetChecked(config.sendWhisperResponse)
    configFrame.whisperCheckbox:SetScript("OnClick", function(self)
        config.sendWhisperResponse = self:GetChecked()
        SaveConfig()
        ShowFeedback("Whisper responses " .. (config.sendWhisperResponse and "enabled" or "disabled"), 
                    config.sendWhisperResponse and COLOR_GREEN or COLOR_RED)
    end)
    yOffset = yOffset - spacing
    
    -- 4. Whisper Message (Classic Era Reliable Solution)
    configFrame.messageLabel = configFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    configFrame.messageLabel:SetPoint("TOPLEFT", 10, yOffset)
    configFrame.messageLabel:SetText("Whisper Message:")
    configFrame.messageLabel:SetTextColor(1, 1, 1)
    
    -- Create a frame container for better control
    configFrame.messageContainer = CreateFrame("Frame", nil, configFrame.scrollChild)
    configFrame.messageContainer:SetPoint("TOPLEFT", 10, yOffset - 25)
    configFrame.messageContainer:SetSize(310, 30)
    
    -- Create the EditBox
    configFrame.messageEditBox = CreateFrame("EditBox", nil, configFrame.messageContainer)
    configFrame.messageEditBox:SetPoint("TOPLEFT", 5, -5)
    configFrame.messageEditBox:SetPoint("BOTTOMRIGHT", -5, 5)
    configFrame.messageEditBox:SetFontObject("GameFontHighlight")
    configFrame.messageEditBox:SetTextInsets(5, 5, 0, 0)
    configFrame.messageEditBox:SetText(config.whisperMessage)
    configFrame.messageEditBox:SetAutoFocus(false)
    configFrame.messageEditBox:SetMultiLine(false)
    configFrame.messageEditBox:SetMaxLetters(255)
    
    -- Add background to container
    configFrame.messageContainer.bg = configFrame.messageContainer:CreateTexture(nil, "BACKGROUND")
    configFrame.messageContainer.bg:SetAllPoints()
    configFrame.messageContainer.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
    
    -- Add border to container
    configFrame.messageContainer.border = configFrame.messageContainer:CreateTexture(nil, "BORDER")
    configFrame.messageContainer.border:SetAllPoints()
    configFrame.messageContainer.border:SetColorTexture(0.3, 0.3, 0.3, 1)
    
    -- Store original text for comparison
    configFrame.messageEditBox.originalText = config.whisperMessage
    
    -- When focus is gained, store the current text
    configFrame.messageEditBox:SetScript("OnEditFocusGained", function(self)
        self.originalText = self:GetText()
        self:HighlightText()
    end)
    
    -- When focus is lost, save if changed (Most reliable in Classic)
    configFrame.messageEditBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        local newText = self:GetText() or ""
        if newText ~= self.originalText then
            config.whisperMessage = newText
            SaveConfig()
            ShowFeedback("Whisper message updated", COLOR_YELLOW)
        end
    end)
    
    -- Save on Enter key
    configFrame.messageEditBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    
    -- Reset on Escape key
    configFrame.messageEditBox:SetScript("OnEscapePressed", function(self)
        self:SetText(self.originalText)
        self:ClearFocus()
    end)
    
    yOffset = yOffset - 60
    
    -- 5. Spam Protection
    configFrame.spamCheckbox = CreateFrame("CheckButton", nil, configFrame.scrollChild, "UICheckButtonTemplate")
    configFrame.spamCheckbox:SetPoint("TOPLEFT", 10, yOffset)
    configFrame.spamCheckbox.text:SetText(" Spam Protection")
    configFrame.spamCheckbox.text:SetTextColor(1, 1, 1)
    configFrame.spamCheckbox:SetChecked(config.spamProtection)
    configFrame.spamCheckbox:SetScript("OnClick", function(self)
        config.spamProtection = self:GetChecked()
        SaveConfig()
        ShowFeedback("Spam protection " .. (config.spamProtection and "enabled" or "disabled"), 
                    config.spamProtection and COLOR_GREEN or COLOR_RED)
    end)
    yOffset = yOffset - spacing
    
    -- 6. Cooldown
    configFrame.cooldownLabel = configFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    configFrame.cooldownLabel:SetPoint("TOPLEFT", 10, yOffset)
    configFrame.cooldownLabel:SetText("Cooldown: " .. config.spamCooldown .. "s")
    configFrame.cooldownLabel:SetTextColor(1, 1, 1)
    
    configFrame.cooldownSlider = CreateFrame("Slider", nil, configFrame.scrollChild, "OptionsSliderTemplate")
    configFrame.cooldownSlider:SetPoint("TOPLEFT", 10, yOffset - 25)
    configFrame.cooldownSlider:SetSize(200, 17)
    configFrame.cooldownSlider:SetMinMaxValues(5, 300)
    configFrame.cooldownSlider:SetValueStep(5)
    configFrame.cooldownSlider:SetValue(config.spamCooldown)
    configFrame.cooldownSlider:SetScript("OnValueChanged", function(self, value)
        config.spamCooldown = math.floor(value)
        configFrame.cooldownLabel:SetText("Cooldown: " .. config.spamCooldown .. "s")
        SaveConfig()
    end)
    yOffset = yOffset - 50
    
    -- 7. Auto Raid
    configFrame.raidCheckbox = CreateFrame("CheckButton", nil, configFrame.scrollChild, "UICheckButtonTemplate")
    configFrame.raidCheckbox:SetPoint("TOPLEFT", 10, yOffset)
    configFrame.raidCheckbox.text:SetText(" Auto Convert to Raid")
    configFrame.raidCheckbox.text:SetTextColor(1, 1, 1)
    configFrame.raidCheckbox:SetChecked(config.autoConvertToRaid)
    configFrame.raidCheckbox:SetScript("OnClick", function(self)
        config.autoConvertToRaid = self:GetChecked()
        SaveConfig()
        ShowFeedback("Auto raid conversion " .. (config.autoConvertToRaid and "enabled" or "disabled"), 
                    config.autoConvertToRaid and COLOR_GREEN or COLOR_RED)
    end)
    yOffset = yOffset - spacing
    
    -- 8. Feedback Area
    configFrame.feedbackLabel = configFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    configFrame.feedbackLabel:SetPoint("TOPLEFT", 10, yOffset)
    configFrame.feedbackLabel:SetText("Last Action:")
    configFrame.feedbackLabel:SetTextColor(1, 1, 1)
    
    configFrame.feedbackText = configFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    configFrame.feedbackText:SetPoint("TOPLEFT", 10, yOffset - 25)
    configFrame.feedbackText:SetSize(310, 40)
    configFrame.feedbackText:SetJustifyH("LEFT")
    configFrame.feedbackText:SetText("No recent actions")
    configFrame.feedbackText:SetTextColor(0.8, 0.8, 0.8)
    yOffset = yOffset - 70
    
    -- 9. Status
    configFrame.statusLabel = configFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    configFrame.statusLabel:SetPoint("TOPLEFT", 10, yOffset)
    configFrame.statusLabel:SetText("Current Status:")
    configFrame.statusLabel:SetTextColor(1, 1, 1)
    
    configFrame.statusText = configFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    configFrame.statusText:SetPoint("TOPLEFT", 10, yOffset - 25)
    configFrame.statusText:SetSize(310, 60)
    configFrame.statusText:SetJustifyH("LEFT")
    yOffset = yOffset - 90
    
    -- 10. Action Buttons
    configFrame.clearBtn = CreateFrame("Button", nil, configFrame.scrollChild, "UIPanelButtonTemplate")
    configFrame.clearBtn:SetPoint("TOPLEFT", 10, yOffset)
    configFrame.clearBtn:SetSize(120, 25)
    configFrame.clearBtn:SetText("Clear Cache")
    configFrame.clearBtn:SetScript("OnClick", function()
        recentInvites = {}
        ShowFeedback("Cache cleared", COLOR_GREEN)
    end)
    
    configFrame.testBtn = CreateFrame("Button", nil, configFrame.scrollChild, "UIPanelButtonTemplate")
    configFrame.testBtn:SetPoint("TOPLEFT", 140, yOffset)
    configFrame.testBtn:SetSize(120, 25)
    configFrame.testBtn:SetText("Test Permissions")
    configFrame.testBtn:SetScript("OnClick", function()
        local canInvite = CanPlayerInvite()
        ShowFeedback("Can invite: " .. (canInvite and "YES" or "NO"), 
                    canInvite and COLOR_GREEN or COLOR_RED)
    end)
end

-- Create configuration frame
local function CreateConfigFrame()
    if configFrame then
        configFrame:Show()
        UpdateConfigGUI()
        return
    end
    
    configFrame = CreateFrame("Frame", "AdvancedAutoInviteConfig", UIParent)
    configFrame:SetSize(365, 245)
    configFrame:SetPoint("CENTER")
    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:Hide()
    
    -- Background
    configFrame.bg = configFrame:CreateTexture(nil, "BACKGROUND")
    configFrame.bg:SetAllPoints()
    configFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
    
    -- Title bar
    configFrame.titleBar = CreateFrame("Frame", nil, configFrame)
    configFrame.titleBar:SetPoint("TOPLEFT", 0, 0)
    configFrame.titleBar:SetPoint("TOPRIGHT", 0, 0)
    configFrame.titleBar:SetHeight(30)
    
    configFrame.titleBar.bg = configFrame.titleBar:CreateTexture(nil, "BACKGROUND")
    configFrame.titleBar.bg:SetAllPoints()
    configFrame.titleBar.bg:SetColorTexture(0, 0, 0, 0.30)
    
    configFrame.titleText = configFrame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    configFrame.titleText:SetPoint("CENTER", configFrame.titleBar, "CENTER", 0, 0)
    configFrame.titleText:SetText(COLOR_BLUE .. "Advanced Auto Invite " .. COLOR_YELLOW .. "V-" .. version .. COLOR_RESET)
    
    -- Close button
    configFrame.closeBtn = CreateFrame("Button", nil, configFrame.titleBar, "UIPanelCloseButton")
    configFrame.closeBtn:SetSize(24, 24)
    configFrame.closeBtn:SetPoint("RIGHT", configFrame.titleBar, "RIGHT", -3, 0)
    configFrame.closeBtn:SetScript("OnClick", function()
        configFrame:Hide()
    end)
    
    -- Make title bar draggable
    configFrame.titleBar:EnableMouse(true)
    configFrame.titleBar:RegisterForDrag("LeftButton")
    configFrame.titleBar:SetScript("OnDragStart", function(self)
        configFrame:StartMoving()
    end)
    configFrame.titleBar:SetScript("OnDragStop", function(self)
        configFrame:StopMovingOrSizing()
    end)
    
    -- Create content area
    configFrame.content = CreateFrame("Frame", nil, configFrame)
    configFrame.content:SetPoint("TOPLEFT", 10, -35)
    configFrame.content:SetPoint("BOTTOMRIGHT", -10, 10)
    
    -- Create scroll frame manually
    configFrame.scrollFrame = CreateFrame("ScrollFrame", nil, configFrame.content)
    configFrame.scrollFrame:SetPoint("TOPLEFT", 0, 0)
    configFrame.scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    
    configFrame.scrollChild = CreateFrame("Frame", nil, configFrame.scrollFrame)
    configFrame.scrollChild:SetSize(320, 600)
    configFrame.scrollFrame:SetScrollChild(configFrame.scrollChild)
    
    -- Create scroll bar manually
    configFrame.scrollBar = CreateFrame("Slider", nil, configFrame.scrollFrame, "UIPanelScrollBarTemplate")
    configFrame.scrollBar:SetPoint("TOPLEFT", configFrame.scrollFrame, "TOPRIGHT", -20, -20)
    configFrame.scrollBar:SetPoint("BOTTOMLEFT", configFrame.scrollFrame, "BOTTOMRIGHT", -20, 20)
    configFrame.scrollBar:SetWidth(16)
    configFrame.scrollBar:SetMinMaxValues(0, 300)
    configFrame.scrollBar:SetValue(0)
    
    configFrame.scrollBar:SetScript("OnValueChanged", function(self, value)
        configFrame.scrollFrame:SetVerticalScroll(value)
    end)
    
    configFrame.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = configFrame.scrollBar:GetValue()
        local newValue = current - (delta * 30)
        
        if newValue < 0 then newValue = 0 end
        if newValue > 300 then newValue = 300 end
        
        configFrame.scrollBar:SetValue(newValue)
    end)
    
    -- Create GUI elements
    CreateConfigElements()
end

-- Update config GUI
function UpdateConfigGUI()
    if not configFrame or not configFrame:IsVisible() then return end
    
    -- Update status
    local status = ""
    status = status .. "Group: " .. (IsInRaid() and "Raid" or (IsInGroup() and "Party" or "Solo")) .. "\n"
    status = status .. "Can Invite: " .. (CanPlayerInvite() and "YES" or "NO") .. "\n"
    status = status .. "Members: " .. GetNumGroupMembers() .. "/" .. (IsInRaid() and "40" or "5") .. "\n"
    status = status .. "Leader: " .. (UnitIsGroupLeader("player") and "You" or "Other")
    
    configFrame.statusText:SetText(status)
    
    -- Update feedback
    if lastFeedback.message and (GetTime() - lastFeedback.time) < 30 then
        configFrame.feedbackText:SetText(lastFeedback.message)
        
        local r, g, b = 1, 1, 1
        if lastFeedback.color == COLOR_GREEN then r, g, b = 0, 1, 0
        elseif lastFeedback.color == COLOR_RED then r, g, b = 1, 0, 0
        elseif lastFeedback.color == COLOR_YELLOW then r, g, b = 1, 1, 0
        elseif lastFeedback.color == COLOR_CYAN then r, g, b = 0, 1, 1
        elseif lastFeedback.color == COLOR_BLUE then r, g, b = 0, 0.44, 0.87
        elseif lastFeedback.color == COLOR_GOLD then r, g, b = 1, 0.84, 0 end
        
        configFrame.feedbackText:SetTextColor(r, g, b)
    else
        configFrame.feedbackText:SetText("No recent actions")
        configFrame.feedbackText:SetTextColor(0.8, 0.8, 0.8)
    end
end

-- ============================================
-- EVENT HANDLER
-- ============================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
    if event == "ADDON_LOADED" then
        local addonName = arg1
        if addonName == "AdvancedAutoInvite" then
            LoadConfig()
            
            -- Create GUI
            CreateConfigFrame()
            
            print(COLOR_BLUE .. "Advanced Auto Invite " .. COLOR_YELLOW .. "V-" .. version .. COLOR_RESET .. 
              COLOR_BLUE .. " loaded!" .. COLOR_RESET)
            print(COLOR_WHITE .. "Type " .. COLOR_YELLOW .. "/aai help" .. 
              COLOR_WHITE .. " for commands" .. COLOR_RESET)
        end
    elseif event == "CHAT_MSG_WHISPER" then
        if not config.autoInviteEnabled then return end
        
        local playerName = arg2
        local message = arg1
        
        if isMatchingKeyword(message) then
            if not EnsureInvitePermissions() then
                ShowFeedback("No permission to invite", COLOR_RED)
                if config.sendWhisperResponse then
                    SendWhisperMessage(playerName, "Sorry, I can't invite right now.")
                end
                return
            end
            
            if IsPlayerInGroup(playerName) then
                ShowFeedback(GetDisplayName(playerName) .. " already in group", COLOR_YELLOW)
                return
            end
            
            if IsRaidFull() then
                ShowFeedback("Raid full (40/40)", COLOR_RED)
                return
            end
            
            if IsPartyFull() then
                if config.autoConvertToRaid then
                    AutoConvertToRaidIfNeeded()
                else
                    ShowFeedback("Party full (5/5)", COLOR_RED)
                    return
                end
            end
            
            local canInvite = canInvitePlayer(playerName)
            if not canInvite then
                ShowFeedback(GetDisplayName(playerName) .. " on cooldown", COLOR_RED)
                return
            end
            
            local isEligible = isPlayerEligible(playerName)
            if not isEligible then
                ShowFeedback("Invalid name: " .. GetDisplayName(playerName), COLOR_RED)
                return
            end
            
            local success = pcall(InviteUnit, playerName)
            if not success then
                ShowFeedback("Failed to invite " .. GetDisplayName(playerName), COLOR_RED)
                return
            end
            
            ShowFeedback("Invited " .. GetDisplayName(playerName), COLOR_GREEN)
            
            if config.sendWhisperResponse then
                SendWhisperMessage(playerName, config.whisperMessage)
            end
        end
    end
end)

-- ============================================
-- SLASH COMMANDS
-- ============================================

SLASH_ADVANCEDAUTOINVITE1 = "/advancedautoinvite"
SLASH_ADVANCEDAUTOINVITE2 = "/aai"

SlashCmdList["ADVANCEDAUTOINVITE"] = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "help" or command == "" then
        print(COLOR_BLUE .. "=== Advanced Auto Invite ===" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai help" .. COLOR_WHITE .. " - Show commands" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai config" .. COLOR_WHITE .. " - Open config GUI" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai toggle" .. COLOR_WHITE .. " - Toggle auto-invite" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai status" .. COLOR_WHITE .. " - Show status" .. COLOR_RESET)
        print(COLOR_YELLOW .. "/aai clearcache" .. COLOR_WHITE .. " - Clear spam cache" .. COLOR_RESET)
        
    elseif command == "config" then
        CreateConfigFrame()
        configFrame:Show()
        ShowFeedback("Config opened", COLOR_GREEN)
        
    elseif command == "toggle" then
        config.autoInviteEnabled = not config.autoInviteEnabled
        SaveConfig()
        ShowFeedback("Auto-invite " .. (config.autoInviteEnabled and "enabled" or "disabled"), 
                    config.autoInviteEnabled and COLOR_GREEN or COLOR_RED)
        
    elseif command == "status" then
        print(COLOR_BLUE .. "=== Status ===" .. COLOR_RESET)
        print(COLOR_WHITE .. "Enabled: " .. (config.autoInviteEnabled and COLOR_GREEN .. "Yes" or COLOR_RED .. "No") .. COLOR_RESET)
        print(COLOR_WHITE .. "Keyword: " .. COLOR_YELLOW .. config.inviteKeyword .. COLOR_RESET)
        print(COLOR_WHITE .. "Group: " .. COLOR_CYAN .. 
              (IsInRaid() and "Raid" or (IsInGroup() and "Party" or "Solo")) .. COLOR_RESET)
        print(COLOR_WHITE .. "Can Invite: " .. (CanPlayerInvite() and COLOR_GREEN .. "Yes" or COLOR_RED .. "No") .. COLOR_RESET)
        print(COLOR_WHITE .. "Members: " .. GetNumGroupMembers() .. "/" .. (IsInRaid() and "40" or "5") .. COLOR_RESET)
        
    elseif command == "clearcache" then
        recentInvites = {}
        ShowFeedback("Cache cleared", COLOR_GREEN)
        
    else
        ShowFeedback("Unknown command. Type /aai help", COLOR_RED)
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