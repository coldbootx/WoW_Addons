-- GoldFarm Main File – Patched version (v1.0.2)
-- Added: proper repair tracking, removed Group Loot & Junk Sold
-- New feature: Gold per hour calculation

GoldFarm = {}
GoldFarm.version = "1.0.2"

-----------------------------------------------------------------------
-- Default saved‑variables profile
-----------------------------------------------------------------------
local defaults = {
    profile = {
        sessions       = {},
        currentSession = nil,
        isRunning      = false,
        guiPosition    = { x = 100, y = -100 },
        guiVisible     = true,
        minimapButton  = { hide = false, minimapPos = 220 }
    }
}

-----------------------------------------------------------------------
-- Utility / Fallback helpers
-----------------------------------------------------------------------
local function SafeCopyTable(t)
    if CopyTable then return CopyTable(t) end
    local copy = {}
    for k, v in pairs(t or {}) do copy[k] = type(v) == "table" and SafeCopyTable(v) or v end
    return copy
end

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

local function CoinsToCopper(g, s, c)
    return (g or 0) * 10000 + (s or 0) * 100 + (c or 0)
end

-----------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------
function GoldFarm:OnInitialize()
    if not GoldFarmDB then GoldFarmDB = SafeCopyTable(defaults.profile) end
    self.db = GoldFarmDB

    self.db.minimapButton = self.db.minimapButton or { hide = false, minimapPos = 220 }

    if not self.db.currentSession then self:CreateNewSession() end

    if self.CreateGUI then self:CreateGUI() end
    if self.CreateMinimapButton then self:CreateMinimapButton() end

    print(colors.addon.."GoldFarm"..colors.reset.." v"..colors.info..self.version..
          colors.reset.." loaded! Type "..colors.gold.."/goldfarm help"..colors.reset.." for commands.")
end

-----------------------------------------------------------------------
-- Session handling
-----------------------------------------------------------------------
function GoldFarm:CreateNewSession()
    local sessionName = "Session "..date("%m/%d %H:%M")
    self.db.currentSession = {
        name       = sessionName,
        startTime  = time(),
        goldLooted = 0,
        itemsSold  = 0,
        repairs    = 0,
        startGold  = self:GetCurrentMoney()
    }
end

function GoldFarm:GetCurrentMoney() return GetMoney() or 0 end

function GoldFarm:FormatMoney(copper)
    if copper == 0 then return "0"..colors.copper..GetCoinTextureString(0)..colors.reset end
    return GetCoinTextureString(copper)
end

function GoldFarm:StartSession()
    if self.db.isRunning then
        print(colors.addon.."GoldFarm:"..colors.reset.." Session already running!")
        return
    end
    self.db.isRunning = true
    self:CreateNewSession()
    self:RegisterEvents()
    self:StartTimer()
    print(colors.addon.."GoldFarm:"..colors.reset.." Session "..colors.session.."started!"..colors.reset)
    self:UpdateGUI()
end

function GoldFarm:StopSession()
    if not self.db.isRunning then
        print(colors.addon.."GoldFarm:"..colors.reset.." No session running!")
        return
    end
    self.db.isRunning = false
    self:UnregisterEvents()
    self:StopTimer()
    if self.db.currentSession then
        self.db.currentSession.endTime = time()
        table.insert(self.db.sessions, SafeCopyTable(self.db.currentSession))
    end
    print(colors.addon.."GoldFarm:"..colors.reset.." Session "..colors.negative.."stopped!"..colors.reset)
    self:UpdateGUI()
end

function GoldFarm:ResetSession()
    local wasRunning = self.db.isRunning
    if wasRunning then self:StopSession() end
    self:CreateNewSession()
    if wasRunning then
        self.db.isRunning = true
        self:RegisterEvents()
        self:StartTimer()
    end
    print(colors.addon.."GoldFarm:"..colors.reset.." Session "..colors.info.."reset!"..colors.reset)
    self:UpdateGUI()
end

-----------------------------------------------------------------------
-- Event registration
-----------------------------------------------------------------------
function GoldFarm:RegisterEvents()
    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("CHAT_MSG_MONEY")
    self.frame:RegisterEvent("CHAT_MSG_LOOT")
    self.frame:RegisterEvent("MERCHANT_SHOW")
    self.frame:RegisterEvent("MERCHANT_CLOSED")
    self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self.frame:SetScript("OnEvent", function(_, ev, ...) self:OnEvent(ev, ...) end)
end

function GoldFarm:UnregisterEvents()
    if self.frame then self.frame:UnregisterAllEvents() end
    self:StopTimer()
end

-----------------------------------------------------------------------
-- Central event dispatcher
-----------------------------------------------------------------------
function GoldFarm:OnEvent(event, ...)
    if not self.db.isRunning or not self.db.currentSession then return end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:HandleCombatLog(CombatLogGetCurrentEventInfo())
    elseif event == "CHAT_MSG_MONEY" then
        self:HandleMoneyMessage(...)
    elseif event == "CHAT_MSG_LOOT" then
        self:HandleLootMessage(...)
    elseif event == "MERCHANT_SHOW" then
        self.preRepairMoney = self:GetCurrentMoney()
        self.merchantMoney   = self:GetCurrentMoney()
    elseif event == "MERCHANT_CLOSED" then
        self:HandleMerchantClosed()
        self:HandleRepairClosed()
    end
end

-----------------------------------------------------------------------
-- Combat‑log handling (numeric, language‑independent)
-----------------------------------------------------------------------
function GoldFarm:HandleCombatLog(_, subevent, _, sourceGUID, _, _, _, _, _, _, _, _, _, _, amount)
    local s = self.db.currentSession
    if not s then return end

    if subevent == "LOOT_MONEY" then
        if sourceGUID == UnitGUID("player") then
            s.goldLooted = (s.goldLooted or 0) + (amount or 0)
        end
        self:UpdateGUI()
        return
    elseif subevent == "SELL_ITEM" then
        s.itemsSold = (s.itemsSold or 0) + (amount or 0)
        self:UpdateGUI()
        return
    elseif subevent == "REPAIR_ITEM" then
        -- No longer needed – repairs are handled via money‑difference.
    end
end

-----------------------------------------------------------------------
-- Chat fallback parsers
-----------------------------------------------------------------------
function GoldFarm:HandleMoneyMessage(message)
    local gold   = tonumber(string.match(message, "(%d+)%s*Gold"))   or 0
    local silver = tonumber(string.match(message, "(%d+)%s*Silver")) or 0
    local copper = tonumber(string.match(message, "(%d+)%s*Copper")) or 0
    local money  = CoinsToCopper(gold, silver, copper)
    if money > 0 then
        self.db.currentSession.goldLooted = (self.db.currentSession.goldLooted or 0) + money
        self:UpdateGUI()
    end
end

function GoldFarm:HandleLootMessage(message)
    local s = self.db.currentSession
    if not s then return end

    local gold   = tonumber(string.match(message, "(%d+)%s*Gold"))   or 0
    local silver = tonumber(string.match(message, "(%d+)%s*Silver")) or 0
    local copper = tonumber(string.match(message, "(%d+)%s*Copper")) or 0
    local money  = CoinsToCopper(gold, silver, copper)

    if message:find("^You loot") then
        s.goldLooted = (s.goldLooted or 0) + money
    end
    self:UpdateGUI()
end

-----------------------------------------------------------------------
-- Merchant closed – calculate vendor profit
-----------------------------------------------------------------------
function GoldFarm:HandleMerchantClosed()
    if not self.merchantMoney then return end
    local diff = self:GetCurrentMoney() - self.merchantMoney
    if diff > 0 then
        local s = self.db.currentSession
        s.itemsSold = (s.itemsSold or 0) + diff
        self:UpdateGUI()
    end
    self.merchantMoney = nil
end

-----------------------------------------------------------------------
-- NEW – Repair handling (money before/after merchant window)
-----------------------------------------------------------------------
function GoldFarm:HandleRepairClosed()
    if not self.preRepairMoney then return end
    local after = self:GetCurrentMoney()
    local diff  = self.preRepairMoney - after          -- gold spent on repairs
    if diff > 0 then
        local s = self.db.currentSession
        s.repairs = (s.repairs or 0) + diff
        self:UpdateGUI()
    end
    self.preRepairMoney = nil
end

-----------------------------------------------------------------------
-- Timer helpers
-----------------------------------------------------------------------
function GoldFarm:GetSessionTimer()
    if not self.db.currentSession then return "00:00:00" end
    local endTime = self.db.isRunning and time() or (self.db.currentSession.endTime or time())
    local elapsed = endTime - (self.db.currentSession.startTime or time())
    local h = math.floor(elapsed/3600)
    local m = math.floor((elapsed%3600)/60)
    local s = elapsed%60
    return string.format("%02d:%02d:%02d", h, m, s)
end

function GoldFarm:GetSessionTotal()
    if not self.db.currentSession then return 0 end
    local s = self.db.currentSession
    return (s.goldLooted or 0) + (s.itemsSold or 0) - (s.repairs or 0)
end

-----------------------------------------------------------------------
-- Gold‑per‑hour calculation (new)
-----------------------------------------------------------------------
function GoldFarm:GoldPerHour()
    local s = self.db.currentSession
    if not s or not s.startTime then return 0 end

    local elapsed = time() - s.startTime               -- seconds since start
    if elapsed <= 0 then return 0 end

    local totalGold = self:GetSessionTotal()           -- net copper
    local goldPerHour = (totalGold / elapsed) * 3600   -- copper per hour

    s.gph = goldPerHour                               -- cache for GUI/export
    return goldPerHour
end

-----------------------------------------------------------------------
-- Export data (now includes GPH)
-----------------------------------------------------------------------
function GoldFarm:ExportData()
    local s = self.db.currentSession
    if not s then
        print(colors.addon.."GoldFarm:"..colors.reset.." No session data to export!")
        return
    end

    -- Ensure the latest GPH value is calculated before exporting
    self:GoldPerHour()

    local output = string.format(
        "=== GoldFarm Session Export ===\n"..
        "Session: %s\n"..
        "Duration: %s\n"..
        "Gold Looted: %s\n"..
        "Items Sold: %s\n"..
        "Repairs: %s\n"..
        "Total: %s\n"..
        "Gold / hour: %s",
        s.name,
        self:GetSessionTimer(),
        self:FormatMoney(s.goldLooted or 0),
        self:FormatMoney(s.itemsSold or 0),
        self:FormatMoney(s.repairs or 0),
        self:FormatMoney(self:GetSessionTotal()),
        self:FormatMoney(math.floor(s.gph or 0))
    )
    print(output)
end

-----------------------------------------------------------------------
-- Slash commands
-----------------------------------------------------------------------
SLASH_GOLDFARM1 = "/goldfarm"
SLASH_GOLDFARM2 = "/gf"

SlashCmdList["GOLDFARM"] = function(msg)
    local cmd = string.lower(msg or "")
    if cmd == "help" then
        print(colors.addon.."GoldFarm Commands:"..colors.reset)
        print(colors.gold.."/goldfarm start"..colors.reset.." - Start tracking session")
        print(colors.gold.."/goldfarm stop"..colors.reset.." - Stop tracking session")
        print(colors.gold.."/goldfarm reset"..colors.reset.." - Reset current session")
        print(colors.gold.."/goldfarm show"..colors.reset.." - Show GUI")
        print(colors.gold.."/goldfarm hide"..colors.reset.." - Hide GUI")
        print(colors.gold.."/goldfarm export"..colors.reset.." - Export session data")
        print(colors.gold.."/goldfarm version"..colors.reset.." - Show version")
    elseif cmd == "start" then GoldFarm:StartSession()
    elseif cmd == "stop"  then GoldFarm:StopSession()
    elseif cmd == "reset" then GoldFarm:ResetSession()
    elseif cmd == "show"  then GoldFarm.db.guiVisible = true GoldFarm:ShowGUI()
    elseif cmd == "hide"  then GoldFarm.db.guiVisible = false GoldFarm:HideGUI()
    elseif cmd == "export" then GoldFarm:ExportData()
    elseif cmd == "version" then
        print(colors.addon.."GoldFarm version "..colors.info..GoldFarm.version..colors.reset)
    else
        print(colors.addon.."GoldFarm:"..colors.reset.." Unknown command. Type /goldfarm help.")
    end
end

-----------------------------------------------------------------------
-- Ensure initialization after ADDON_LOADED
-----------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName == "GoldFarm" then
        GoldFarm:OnInitialize()
        initFrame:UnregisterEvent("ADDON_LOADED")
    end
end)