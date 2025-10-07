-- NetInfo Addon (Classic Only)
-- Blue Border + Right Alignment Added Alternating Row Striping

local addonName, NetInfoAddon = ...
NetInfoAddon.L = NetInfoAddon.L or {}
local L = NetInfoAddon.L

local function ColorPrint(prefix, message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff0000ff" .. prefix .. "|r: |cFFFFFFFF" .. message .. "|r")
    end
end

-- =========================
-- Localization loader
-- =========================
local locale = GetLocale()
local supportedLocales = {
    "enUS","deDE","frFR","esES","esMX","ruRU","koKR","zhCN","zhTW"
}
local loaded=false
for _,loc in ipairs(supportedLocales) do
    if locale==loc and L and next(L) then
        loaded=true
        ColorPrint("NetInfo","Loaded localization for "..loc)
        break
    end
end
if not loaded then ColorPrint("NetInfo","Using default English localization") end

-- =========================
-- Frame setup
-- =========================
local NetInfo = CreateFrame("Frame","NetInfoFrame",UIParent,"BackdropTemplate")
NetInfo:SetSize(300,400)
NetInfo:SetPoint("CENTER")
NetInfo:SetBackdrop({
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true,tileSize=16,edgeSize=16,
    insets={left=4,right=4,top=4,bottom=4}
})
NetInfo:SetBackdropBorderColor(0,0.44,0.87,1)
NetInfo:SetMovable(true)
NetInfo:EnableMouse(true)
NetInfo:SetResizable(true)
NetInfo.version="1.3"

-- =========================
-- Title
-- =========================

local titleBG = NetInfo:CreateTexture(nil, "BACKGROUND")
titleBG:SetColorTexture(0, 0, 0, 0.4)  -- black background
titleBG:SetPoint("TOPLEFT", NetInfo, "TOPLEFT", 6, -6)
titleBG:SetPoint("TOPRIGHT", NetInfo, "TOPRIGHT", -6, -6)
titleBG:SetHeight(30)

local title=NetInfo:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
title:SetPoint("TOP",0,-15)
title:SetTextColor(0,0,1)
title:SetText("NetInfo")

-- Optional accent line
local titleLine = NetInfo:CreateTexture(nil, "BORDER")
titleLine:SetColorTexture(0, 0.4, 0.8, 0.7)
titleLine:SetPoint("BOTTOMLEFT", titleBG, "BOTTOMLEFT", 0, 0)
titleLine:SetPoint("BOTTOMRIGHT", titleBG, "BOTTOMRIGHT", 0, 0)
titleLine:SetHeight(1)

-- =========================
-- ScrollFrame
-- =========================
local scrollFrame=CreateFrame("ScrollFrame","NetInfoScrollFrame",NetInfo,"UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT",20,-50)
scrollFrame:SetPoint("BOTTOMRIGHT",-40,20)

local scrollChild=CreateFrame("Frame","NetInfoScrollChild",scrollFrame)
scrollChild:SetSize(NetInfo:GetWidth()-60,1)
scrollFrame:SetScrollChild(scrollChild)

scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel",function(self,delta)
    local sb=_G[self:GetName().."ScrollBar"]
    if not sb then return end
    local cur=sb:GetValue()
    local step=20
    sb:SetValue(cur-(delta>0 and step or -step))
end)

-- =========================
-- Resizer
-- =========================
local resizer=CreateFrame("Button",nil,NetInfo)
resizer:SetSize(16,16)
resizer:SetPoint("BOTTOMRIGHT")
resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizer:SetScript("OnMouseDown",function(self,btn)
    if btn=="LeftButton" then
        NetInfo:StartSizing("BOTTOMRIGHT")
        NetInfo:SetUserPlaced(true)
    end
end)
resizer:SetScript("OnMouseUp",function()
    NetInfo:StopMovingOrSizing()
end)

-- =========================
-- Tooltip
-- =========================
NetInfo:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_TOPLEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(L["TITLE"] or "NetInfo")
    GameTooltipTextLeft1:SetTextColor(0,0,1)
    GameTooltip:AddLine("|cff87CEFAShift + Left Click:|r |cFFFFFFFFMove|r")
    GameTooltip:AddLine("|cff87CEFAShift + Right Click:|r |cFFFFFFFFHide/Show|r")
    GameTooltip:AddLine("|cff87CEFAResize:|r |cFFFFFFFFDrag bottom-right corner|r")
    GameTooltip:Show()
end)
NetInfo:SetScript("OnLeave",function() GameTooltip:Hide() end)

-- =========================
-- Dynamic Rows
-- =========================
local rows={}
local stripes={}

local function GetRow(index)
    if rows[index] then return rows[index] end
    local row=CreateFrame("Frame",nil,scrollChild)
    row:SetHeight(14)
    if index==1 then
        row:SetPoint("TOPLEFT",scrollChild,"TOPLEFT",0,0)
        row:SetPoint("TOPRIGHT",scrollChild,"TOPRIGHT",0,0)
    else
        row:SetPoint("TOPLEFT",rows[index-1],"BOTTOMLEFT",0,-2)
        row:SetPoint("TOPRIGHT",rows[index-1],"BOTTOMRIGHT",0,-2)
    end

    stripes[index]=row:CreateTexture(nil,"BACKGROUND")
    stripes[index]:SetAllPoints(row)
    stripes[index]:SetColorTexture(0.2,0.3,0.5,(index%2==0) and 0.10 or 0.05)

    row.label=row:CreateFontString(nil,"OVERLAY","GameFontNormal")
    row.label:SetPoint("LEFT",row,"LEFT",0,0)
    row.label:SetJustifyH("LEFT")

    row.value=row:CreateFontString(nil,"OVERLAY","GameFontNormal")
    row.value:SetPoint("RIGHT",row,"RIGHT",0,0)
    row.value:SetJustifyH("RIGHT")

    rows[index]=row
    return row
end

local function HideAllRows(start)
    for i=start,#rows do
        rows[i]:Hide()
    end
end

-- =========================
-- Update Info Function
-- =========================
local function UpdateInfo()
    local fps=GetFramerate()
    local _,_,home,world=GetNetStats()
    home=home or 0
    world=world or 0
    local homeColor=home>25 and "|cFFFF0000" or "|cFFFFFFFF"
    local worldColor=world>25 and "|cFFFF0000" or "|cFFFFFFFF"

    UpdateAddOnMemoryUsage()
    local n=GetNumAddOns()
    local total=0
    local rowIndex=1

    local function AddLine(label,value)
        local r=GetRow(rowIndex)
        r:Show()
        r.label:SetText(label)
        r.value:SetText(value)
        stripes[rowIndex]:SetColorTexture(0.2,0.3,0.5,(rowIndex%2==0) and 0.10 or 0.05)
        rowIndex=rowIndex+1
    end

    AddLine("|cff87CEFAFrames Per Second:|r",string.format("|cFFFFFFFF%d|r",math.floor(fps+0.5)))
    AddLine("|cff87CEFAHome Latency:|r",string.format("%s%d|r ms",homeColor,home))
    AddLine("|cff87CEFAWorld Latency:|r",string.format("%s%d|r ms",worldColor,world))
    AddLine(" "," ")
    AddLine("|cff87CEFAAddOns:|r"," ")

    for i=1,n do
        if IsAddOnLoaded(i) then
            local mem=GetAddOnMemoryUsage(i)
            total=total+mem
            local name=GetAddOnInfo(i)
            AddLine("  "..name..":",string.format("|cFFFFFFFF%.2f MB|r",mem/1024))
        end
    end

    AddLine(" "," ")
    AddLine("|cff87CEFAAddon Memory Total:|r",string.format("|cFFFFFFFF%.2f MB|r",total/1024))
    HideAllRows(rowIndex)
end

-- =========================
-- OnUpdate
-- =========================
local elapsed=0
NetInfo:SetScript("OnUpdate",function(self,e)
    elapsed=elapsed+e
    if elapsed>1 then
        UpdateInfo()
        elapsed=0
    end
end)

-- =========================
-- Mouse Controls
-- =========================
NetInfo:SetScript("OnMouseDown",function(self,button)
    if IsShiftKeyDown() then
        if button=="LeftButton" then
            self:StartMoving()
        elseif button=="RightButton" then
            if self:IsShown() then self:Hide() else self:Show() end
        end
    end
end)
NetInfo:SetScript("OnMouseUp",function(self,button)
    if button=="LeftButton" then
        self:StopMovingOrSizing()
    end
end)

-- =========================
-- Slash Commands
-- =========================
SLASH_NETINFO1="/netinfo"
SlashCmdList["NETINFO"]=function(msg)
    msg=(msg or ""):lower():gsub("^%s*(.-)%s*$","%1")
    local function P(t) ColorPrint("NetInfo",t) end
    if msg=="" or msg=="help" then
        P("/netinfo help - Show help")
        P("/netinfo version - Show version")
        P("/netinfo show - Show the frame")
        P("/netinfo hide - Hide the frame")
    elseif msg=="version" then
        P("Version: "..NetInfo.version)
    elseif msg=="show" then
        NetInfo:Show() P("Frame shown")
    elseif msg=="hide" then
        NetInfo:Hide() P("Frame hidden")
    else
        P("Unknown command. Type /netinfo help")
    end
end

-- =========================
-- Auto-show on login
-- =========================
NetInfo:RegisterEvent("PLAYER_LOGIN")
NetInfo:SetScript("OnEvent",function(self,event)
    if event=="PLAYER_LOGIN" then
        NetInfo:Show()
    end
end)
