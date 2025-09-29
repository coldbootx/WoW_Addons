-- GoldFarm Main File with Capitalized "Sold junk for" and "Repaired for" Fix

GoldFarm = {}
GoldFarm.version = "1.0.0"

local defaults = {
    profile = {
        sessions = {},
        currentSession = nil,
        isRunning = false,
        guiPosition = { x = 100, y = -100 },
        guiVisible = true,
        minimapButton = { hide = false, minimapPos = 220 }
    }
}

local colors = {
    addon = "|cff00ff00",
    session = "|cffff6600",
    gold = "|cffffff00",
    silver = "|cffc0c0c0",
    copper = "|cffcd7f32",
    positive = "|cff00ff00",
    negative = "|cffff0000",
    info = "|cff00ccff",
    reset = "|r"
}

function GoldFarm:OnInitialize()
    if not GoldFarmDB then
        GoldFarmDB = CopyTable(defaults.profile)
    end
    self.db = GoldFarmDB

    if not self.db.currentSession then
        self:CreateNewSession()
    end

    print(colors.addon .. "GoldFarm" .. colors.reset .. " v" .. colors.info .. self.version .. colors.reset .. " loaded! Type " .. colors.gold .. "/goldfarm help" .. colors.reset .. " for commands.")
end

function GoldFarm:CreateNewSession()
    local sessionName = "Session " .. date("%m/%d %H:%M")
    self.db.currentSession = {
        name = sessionName,
        startTime = time(),
        goldLooted = 0,
        groupLoot = 0,
        junkSold = 0,
        itemsSold = 0,
        repairs = 0,
        startGold = self:GetCurrentMoney()
    }
end

function GoldFarm:GetCurrentMoney()
    return GetMoney() or 0
end

function GoldFarm:FormatMoney(copper)
    if copper == 0 then return "0" .. colors.copper .. GetCoinTextureString(0) .. colors.reset end
    return GetCoinTextureString(copper)
end

function GoldFarm:StartSession()
    if self.db.isRunning then
        print(colors.addon .. "GoldFarm:" .. colors.reset .. " Session already running!")
        return
    end

    self.db.isRunning = true
    self:CreateNewSession()
    self:RegisterEvents()
    self:StartTimer()
    print(colors.addon .. "GoldFarm:" .. colors.reset .. " Session " .. colors.session .. "started!" .. colors.reset)
    self:UpdateGUI()
end

function GoldFarm:StopSession()
    if not self.db.isRunning then
        print(colors.addon .. "GoldFarm:" .. colors.reset .. " No session running!")
        return
    end

    self.db.isRunning = false
    self:UnregisterEvents()

    if self.db.currentSession then
        self.db.currentSession.endTime = time()
        table.insert(self.db.sessions, CopyTable(self.db.currentSession))
    end

    self:StopTimer()
    print(colors.addon .. "GoldFarm:" .. colors.reset .. " Session " .. colors.negative .. "stopped!" .. colors.reset)
    self:UpdateGUI()
end

function GoldFarm:ResetSession()
    local wasRunning = self.db.isRunning
    if wasRunning then
        self:StopSession()
    end

    self:CreateNewSession()

    if wasRunning then
        self.db.isRunning = true
        self:RegisterEvents()
        self:StartTimer()
    end

    print(colors.addon .. "GoldFarm:" .. colors.reset .. " Session " .. colors.info .. "reset!" .. colors.reset)
    self:UpdateGUI()
end

function GoldFarm:RegisterEvents()
    self.frame = self.frame or CreateFrame("Frame")
    self.frame:RegisterEvent("CHAT_MSG_MONEY")
    self.frame:RegisterEvent("CHAT_MSG_LOOT")
    self.frame:RegisterEvent("MERCHANT_SHOW")
    self.frame:RegisterEvent("MERCHANT_CLOSED")
    self.frame:SetScript("OnEvent", function(frame, event, ...)
        self:OnEvent(event, ...)
    end)
end

function GoldFarm:UnregisterEvents()
    if self.frame then
        self.frame:UnregisterAllEvents()
    end
end

function GoldFarm:OnEvent(event, ...)
    if not self.db.isRunning or not self.db.currentSession then return end

    if event == "CHAT_MSG_MONEY" then
        local message = ...
        self:HandleMoneyMessage(message)
    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        self:HandleLootMessage(message)
    elseif event == "MERCHANT_SHOW" then
        self.merchantMoney = self:GetCurrentMoney()
    elseif event == "MERCHANT_CLOSED" then
        self:HandleMerchantClosed()
    end
end

function GoldFarm:HandleMoneyMessage(message)
    -- print("HandleMoneyMessage got:", message) -- Debug
    -- Parse loot: "You loot X Gold, Y Silver, Z Copper."
    local gold = tonumber(string.match(message, "You loot (%d+) Gold")) or 0
    local silver = tonumber(string.match(message, "You loot %d+ Gold, (%d+) Silver"))
                or tonumber(string.match(message, "You loot (%d+) Silver")) or 0
    local copper = tonumber(string.match(message, "You loot %d+ Gold, %d+ Silver, (%d+) Copper"))
                or tonumber(string.match(message, "You loot %d+ Gold, (%d+) Copper"))
                or tonumber(string.match(message, "You loot %d+ Silver, (%d+) Copper"))
                or tonumber(string.match(message, "You loot (%d+) Copper")) or 0
    local money = gold * 10000 + silver * 100 + copper

    if money > 0 then
        self.db.currentSession.goldLooted = (self.db.currentSession.goldLooted or 0) + money
        self:UpdateGUI()
        return
    end

    -- Parse repairs: "Repaired for X Gold, Y Silver, Z Copper."
    local rgold = tonumber(string.match(message, "Repaired for (%d+) Gold")) or 0
    local rsilver = tonumber(string.match(message, "Repaired for %d+ Gold, (%d+) Silver"))
                or tonumber(string.match(message, "Repaired for (%d+) Silver")) or 0
    local rcopper = tonumber(string.match(message, "Repaired for %d+ Gold, %d+ Silver, (%d+) Copper"))
                or tonumber(string.match(message, "Repaired for %d+ Gold, (%d+) Copper"))
                or tonumber(string.match(message, "Repaired for %d+ Silver, (%d+) Copper"))
                or tonumber(string.match(message, "Repaired for (%d+) Copper")) or 0
    local repairCost = rgold * 10000 + rsilver * 100 + rcopper

    if repairCost > 0 then
        self.db.currentSession.repairs = (self.db.currentSession.repairs or 0) + repairCost
        self:UpdateGUI()
        return
    end

    -- Parse junk sold: "Sold junk for X Gold, Y Silver, Z Copper."
    local jgold = tonumber(string.match(message, "Sold junk for (%d+) Gold")) or 0
    local jsilver = tonumber(string.match(message, "Sold junk for %d+ Gold, (%d+) Silver"))
                or tonumber(string.match(message, "Sold junk for (%d+) Silver")) or 0
    local jcopper = tonumber(string.match(message, "Sold junk for %d+ Gold, %d+ Silver, (%d+) Copper"))
                or tonumber(string.match(message, "Sold junk for %d+ Gold, (%d+) Copper"))
                or tonumber(string.match(message, "Sold junk for %d+ Silver, (%d+) Copper"))
                or tonumber(string.match(message, "Sold junk for (%d+) Copper")) or 0
    local junkMoney = jgold * 10000 + jsilver * 100 + jcopper

    if junkMoney > 0 then
        self.db.currentSession.junkSold = (self.db.currentSession.junkSold or 0) + junkMoney
        self:UpdateGUI()
        return
    end
end

function GoldFarm:HandleLootMessage(message)
    -- Solo loot: "You loot X Gold, Y Silver, Z Copper."
    if message:find("^You loot") then
        local gold = tonumber(string.match(message, "You loot (%d+) Gold")) or 0
        local silver = tonumber(string.match(message, "You loot %d+ Gold, (%d+) Silver"))
                    or tonumber(string.match(message, "You loot (%d+) Silver")) or 0
        local copper = tonumber(string.match(message, "You loot %d+ Gold, %d+ Silver, (%d+) Copper"))
                    or tonumber(string.match(message, "You loot %d+ Gold, (%d+) Copper"))
                    or tonumber(string.match(message, "You loot %d+ Silver, (%d+) Copper"))
                    or tonumber(string.match(message, "You loot (%d+) Copper")) or 0
        local money = gold * 10000 + silver * 100 + copper

        if money > 0 then
            self.db.currentSession.goldLooted = (self.db.currentSession.goldLooted or 0) + money
            self:UpdateGUI()
        end

    elseif message:find("^Your share of the loot is") then
        local gold = tonumber(string.match(message, "Your share of the loot is (%d+) Gold")) or 0
        local silver = tonumber(string.match(message, "Your share of the loot is %d+ Gold, (%d+) Silver"))
                    or tonumber(string.match(message, "Your share of the loot is (%d+) Silver")) or 0
        local copper = tonumber(string.match(message, "Your share of the loot is %d+ Gold, %d+ Silver, (%d+) Copper"))
                    or tonumber(string.match(message, "Your share of the loot is %d+ Gold, (%d+) Copper"))
                    or tonumber(string.match(message, "Your share of the loot is %d+ Silver, (%d+) Copper"))
                    or tonumber(string.match(message, "Your share of the loot is (%d+) Copper")) or 0
        local money = gold * 10000 + silver * 100 + copper

        if money > 0 then
            self.db.currentSession.groupLoot = (self.db.currentSession.groupLoot or 0) + money
            self:UpdateGUI()
        end
    end
end

function GoldFarm:HandleMerchantClosed()
    if self.merchantMoney then
        local currentMoney = self:GetCurrentMoney()
        local diff = currentMoney - self.merchantMoney

        if diff > 0 then
            self.db.currentSession.itemsSold = self.db.currentSession.itemsSold + diff
            self:UpdateGUI()
        end

        self.merchantMoney = nil
    end
end

function GoldFarm:GetSessionTimer()
    if not self.db.currentSession then return "00:00:00" end

    local endTime = self.db.isRunning and time() or (self.db.currentSession.endTime or time())
    local elapsed = endTime - self.db.currentSession.startTime
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = elapsed % 60

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function GoldFarm:GetSessionTotal()
    if not self.db.currentSession then return 0 end
    local session = self.db.currentSession
    return session.goldLooted + session.groupLoot + session.junkSold + session.itemsSold - session.repairs
end

function GoldFarm:ExportData()
    if not self.db.currentSession then
        print(colors.addon .. "GoldFarm:" .. colors.reset .. " No session data to export!")
        return
    end

    local session = self.db.currentSession
    local output = string.format(
        "=== GoldFarm Session Export ===\n" ..
        "Session: %s\n" ..
        "Duration: %s\n" ..
        "Gold Looted: %s\n" ..
        "Group Loot: %s\n" ..
        "Junk Sold: %s\n" ..
        "Items Sold: %s\n" ..
        "Repairs: %s\n" ..
        "Total: %s",
        session.name,
        self:GetSessionTimer(),
        self:FormatMoney(session.goldLooted),
        self:FormatMoney(session.groupLoot),
        self:FormatMoney(session.junkSold),
        self:FormatMoney(session.itemsSold),
        self:FormatMoney(session.repairs),
        self:FormatMoney(self:GetSessionTotal())
    )

    print(output)
end

SLASH_GOLDFARM1 = "/goldfarm"
SLASH_GOLDFARM2 = "/gf"

SlashCmdList["GOLDFARM"] = function(msg)
    local cmd = string.lower(msg or "")

    if cmd == "help" then
        print(colors.addon .. "GoldFarm Commands:" .. colors.reset)
        print(colors.gold .. "/goldfarm start" .. colors.reset .. " - Start tracking session")
        print(colors.gold .. "/goldfarm stop" .. colors.reset .. " - Stop tracking session")
        print(colors.gold .. "/goldfarm reset" .. colors.reset .. " - Reset current session")
        print(colors.gold .. "/goldfarm show" .. colors.reset .. " - Show GUI")
        print(colors.gold .. "/goldfarm hide" .. colors.reset .. " - Hide GUI")
        print(colors.gold .. "/goldfarm export" .. colors.reset .. " - Export session data")
        print(colors.gold .. "/goldfarm version" .. colors.reset .. " - Show version")
    elseif cmd == "start" then
        GoldFarm:StartSession()
    elseif cmd == "stop" then
        GoldFarm:StopSession()
    elseif cmd == "reset" then
        GoldFarm:ResetSession()
    elseif cmd == "show" then
        GoldFarm.db.guiVisible = true
        GoldFarm:ShowGUI()
        print(colors.addon .. "GoldFarm:" .. colors.reset .. " GUI " .. colors.positive .. "shown" .. colors.reset)
    elseif cmd == "hide" then
        GoldFarm.db.guiVisible = false
        GoldFarm:HideGUI()
        print(colors.addon .. "GoldFarm:" .. colors.reset .. " GUI " .. colors.negative .. "hidden" .. colors.reset)
    elseif cmd == "export" then
        GoldFarm:ExportData()
    elseif cmd == "version" then
        print(colors.addon .. "GoldFarm" .. colors.reset .. " version " .. colors.info .. GoldFarm.version .. colors.reset)
    else
        print(colors.addon .. "GoldFarm:" .. colors.reset .. " Unknown command. Type " .. colors.gold .. "/goldfarm help" .. colors.reset .. " for help.")
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "GoldFarm" then
        GoldFarm:OnInitialize()
        GoldFarm:CreateGUI()
        if GoldFarm.CreateMinimapButton then
            GoldFarm:CreateMinimapButton()
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
