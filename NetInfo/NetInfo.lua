-- NetInfo Addon (Classic Only) with Automatic Localization Loader and Colored Messages

local addonName, NetInfoAddon = ...
NetInfoAddon.L = NetInfoAddon.L or {}
local L = NetInfoAddon.L

-- =========================
-- Helper for colored chat messages
-- =========================
local function ColorPrint(prefix, message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff" .. prefix .. "|r: |cFFFFFFFF" .. message .. "|r")
    end
end

-- =========================
-- Automatic Localization Loader
-- =========================
local locale = GetLocale()
local supportedLocales = {
    "enUS", "deDE", "frFR", "esES", "esMX", "ruRU", "koKR", "zhCN", "zhTW"
}

-- Fallback flag
local loaded = false

for _, loc in ipairs(supportedLocales) do
    if locale == loc and L and next(L) then
        loaded = true
        ColorPrint("NetInfo", "Loaded localization for " .. loc)
        break
    end
end

if not loaded then
    -- Fallback to English
    ColorPrint("NetInfo", "Using default English localization")
end

-- =========================
-- Main Frame
-- =========================
local NetInfo = CreateFrame("Frame", "NetInfoFrame", UIParent, "BackdropTemplate")
NetInfo:SetSize(300, 400)
NetInfo:SetPoint("CENTER")
NetInfo:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
NetInfo:SetMovable(true)
NetInfo:EnableMouse(true)
NetInfo:SetResizable(true)
NetInfo.version = "1.1"

-- =========================
-- Title
-- =========================
local title = NetInfo:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -15)
title:SetTextColor(0, 0, 1)
title:SetText("NetInfo")

-- =========================
-- Content
-- =========================
local content = NetInfo:CreateFontString(nil, "OVERLAY", "GameFontNormal")
content:SetPoint("TOPLEFT", 20, -50)
content:SetJustifyH("LEFT")
content:SetWidth(NetInfo:GetWidth() - 40)

-- =========================
-- Tooltip
-- =========================
NetInfo:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(L["TITLE"])
    GameTooltipTextLeft1:SetTextColor(0, 0, 1)
    GameTooltipTextLeft1:SetJustifyH("CENTER")
    GameTooltip:AddLine("|cff87CEFAShift + Left Click:|r |cFFFFFFFF" .. (L["MOVE"] or "Move") .. "|r")
    GameTooltip:AddLine("|cff87CEFAShift + Right Click:|r |cFFFFFFFF" .. (L["HIDE_SHOW"] or "Hide/Show") .. "|r")
    GameTooltip:AddLine("|cff87CEFA" .. (L["RESIZE"] or "Resize:") .. "|r |cFFFFFFFF" .. (L["DRAG_CORNER"] or "Drag bottom-right corner") .. "|r")
    GameTooltip:Show()
end)

NetInfo:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- =========================
-- Resizer
-- =========================
local resizer = CreateFrame("Button", nil, NetInfo)
resizer:SetSize(16, 16)
resizer:SetPoint("BOTTOMRIGHT")
resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

resizer:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        NetInfo:StartSizing("BOTTOMRIGHT")
        NetInfo:SetUserPlaced(true)
    end
end)

resizer:SetScript("OnMouseUp", function()
    NetInfo:StopMovingOrSizing()
    content:SetWidth(NetInfo:GetWidth() - 40)
end)

-- =========================
-- Update Info Function
-- =========================
local function UpdateInfo()
    local fps = GetFramerate()
    local _, _, latencyHome, latencyWorld = GetNetStats()
    latencyHome = latencyHome or 0
    latencyWorld = latencyWorld or 0

    local displayFPS = math.floor(fps + 0.5)
    local displayHome = math.floor(latencyHome + 0.5)
    local displayWorld = math.floor(latencyWorld + 0.5)

    UpdateAddOnMemoryUsage()
    local numAddons = GetNumAddOns()
    local totalMemory = 0

    local text = ""
    text = text .. string.format("|cff87CEFAFrames Per Second:|r |cFFFFFFFF%d|r\n", displayFPS)

    local homeColor = displayHome > 25 and "|cFFFF0000" or "|cFFFFFFFF"
    local worldColor = displayWorld > 25 and "|cFFFF0000" or "|cFFFFFFFF"
    text = text .. string.format("|cff87CEFAHome Latency:|r %s%d|r ms\n", homeColor, displayHome)
    text = text .. string.format("|cff87CEFAWorld Latency:|r %s%d|r ms\n\n", worldColor, displayWorld)

    text = text .. "|cff87CEFAAddOns:|r\n"
    for i = 1, numAddons do
        if IsAddOnLoaded(i) then
            local mem = GetAddOnMemoryUsage(i)
            totalMemory = totalMemory + mem
            local addonName = GetAddOnInfo(i)
            text = text .. string.format("  %s - |cFFFFFFFF%.2f MB|r\n", addonName, mem / 1024)
        end
    end

    text = text .. string.format("\n|cff87CEFAAddon Memory Total:|r |cFFFFFFFF%.2f MB|r", totalMemory / 1024)
    content:SetText(text)
end

-- =========================
-- OnUpdate
-- =========================
local elapsed = 0
NetInfo:SetScript("OnUpdate", function(self, e)
    elapsed = elapsed + e
    if elapsed > 1 then
        UpdateInfo()
        elapsed = 0
    end
end)

-- =========================
-- Mouse Controls
-- =========================
NetInfo:SetScript("OnMouseDown", function(self, button)
    if IsShiftKeyDown() then
        if button == "LeftButton" then
            self:StartMoving()
        elseif button == "RightButton" then
            if self:IsShown() then self:Hide() else self:Show() end
        end
    end
end)

NetInfo:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then
        self:StopMovingOrSizing()
    end
end)

-- =========================
-- Slash Commands
-- =========================
SLASH_NETINFO1 = "/netinfo"
SlashCmdList["NETINFO"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s*(.-)%s*$", "%1")

    local function PrintCommand(text)
        ColorPrint("NetInfo", text)
    end

    if msg == "help" or msg == "" then
        PrintCommand("Commands:")
        PrintCommand("/netinfo help - " .. (L["COMMAND_HELP"] or "Show this help"))
        PrintCommand("/netinfo version - " .. (L["COMMAND_VERSION"] or "Show addon version"))
        PrintCommand("/netinfo show - " .. (L["COMMAND_SHOW"] or "Show the frame"))
        PrintCommand("/netinfo hide - " .. (L["COMMAND_HIDE"] or "Hide the frame"))
    elseif msg == "version" then
        PrintCommand("Version: " .. NetInfo.version)
    elseif msg == "show" then
        NetInfo:Show()
        PrintCommand("Frame shown")
    elseif msg == "hide" then
        NetInfo:Hide()
        PrintCommand("Frame hidden")
    else
        ColorPrint("NetInfo", (L["UNKNOWN_COMMAND"] or "Unknown command. Type /netinfo help"))
    end
end

-- =========================
-- Auto-show on login
-- =========================
NetInfo:RegisterEvent("PLAYER_LOGIN")
NetInfo:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        NetInfo:Show()
    end
end)
