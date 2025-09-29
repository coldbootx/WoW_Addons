-- GoldFarm Main File
   GoldFarm = {}
   GoldFarm.version = "1.0.0"
   
   -- Default settings
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
   
   -- Color codes
   local colors = {
       addon = "|cff00ff00", -- Green
       session = "|cffff6600", -- Orange
       gold = "|cffffff00", -- Yellow
       silver = "|cffc0c0c0", -- Silver
       copper = "|cffcd7f32", -- Copper
       positive = "|cff00ff00", -- Green
       negative = "|cffff0000", -- Red
       info = "|cff00ccff", -- Light blue
       reset = "|r"
   }
   
   -- Initialize addon
   function GoldFarm:OnInitialize()
       -- Initialize saved variables
       if not GoldFarmDB then
           GoldFarmDB = CopyTable(defaults.profile)
       end
       
       self.db = GoldFarmDB
       
       -- Create new session if none exists
       if not self.db.currentSession then
           self:CreateNewSession()
       end
       
       print(colors.addon .. "GoldFarm" .. colors.reset .. " v" .. colors.info .. self.version .. colors.reset .. " loaded! Type " .. colors.gold .. "/goldfarm help" .. colors.reset .. " for commands.")
   end
   
   -- Create new session
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
   
   -- Get current money in copper
   function GoldFarm:GetCurrentMoney()
       return GetMoney() or 0
   end
   
   -- Format money display
   function GoldFarm:FormatMoney(copper)
       if copper == 0 then return "0" .. colors.copper .. GetCoinTextureString(0) .. colors.reset end
       
       -- Use the built-in WoW function to get coin icons
       return GetCoinTextureString(copper)
   end
   
   -- Start session
   function GoldFarm:StartSession()
       if self.db.isRunning then
           print(colors.addon .. "GoldFarm:" .. colors.reset .. " Session already running!")
           return
       end
       
       self.db.isRunning = true
       self:CreateNewSession()
       self:RegisterEvents()
       
       -- Start the timer
       self:StartTimer()
       
       print(colors.addon .. "GoldFarm:" .. colors.reset .. " Session " .. colors.session .. "started!" .. colors.reset)
       self:UpdateGUI()
   end
   
   -- Stop session
   function GoldFarm:StopSession()
       if not self.db.isRunning then
           print(colors.addon .. "GoldFarm:" .. colors.reset .. " No session running!")
           return
       end
       
       self.db.isRunning = false
       self:UnregisterEvents()
       
       -- Save session to history
       if self.db.currentSession then
           self.db.currentSession.endTime = time()
           table.insert(self.db.sessions, CopyTable(self.db.currentSession))
       end
       
       -- Stop the timer
       self:StopTimer()
       
       print(colors.addon .. "GoldFarm:" .. colors.reset .. " Session " .. colors.negative .. "stopped!" .. colors.reset)
       self:UpdateGUI()
   end
   
   -- Reset session
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
   
   -- Register events
   function GoldFarm:RegisterEvents()
       self.frame = self.frame or CreateFrame("Frame")
       self.frame:RegisterEvent("CHAT_MSG_MONEY")
       self.frame:RegisterEvent("CHAT_MSG_LOOT")
       self.frame:RegisterEvent("MERCHANT_SHOW")
       self.frame:RegisterEvent("MERCHANT_CLOSED")
       self.frame:SetScript("OnEvent", function(frame, event, ...) self:OnEvent(event, ...) end)
   end
   
   -- Unregister events
   function GoldFarm:UnregisterEvents()
       if self.frame then
           self.frame:UnregisterAllEvents()
       end
   end
   
   -- Event handler
   function GoldFarm:OnEvent(event, ...)
       if not self.db.isRunning or not self.db.currentSession then return end
       
       if event == "CHAT_MSG_MONEY" then
           self:HandleMoneyMessage(...)
       elseif event == "CHAT_MSG_LOOT" then
           self:HandleLootMessage(...)
       elseif event == "MERCHANT_SHOW" then
           self.merchantMoney = self:GetCurrentMoney()
       elseif event == "MERCHANT_CLOSED" then
           self:HandleMerchantClosed()
       end
   end
   
   -- Handle money messages
   function GoldFarm:HandleMoneyMessage(message)
       -- Parse repair costs
       local repairCost = string.match(message, "(%d+) gold") or 0
       if repairCost > 0 then
           self.db.currentSession.repairs = self.db.currentSession.repairs + (repairCost * 10000)
           self:UpdateGUI()
       end
   end
   
   -- Handle loot messages
   function GoldFarm:HandleLootMessage(message)
       local money = string.match(message, "(%d+) gold") or 0
       money = money * 10000
       
       local silver = string.match(message, "(%d+) silver") or 0
       money = money + (silver * 100)
       
       local copper = string.match(message, "(%d+) copper") or 0
       money = money + copper
       
       if money > 0 then
           if string.find(message, "receives loot") then
               self.db.currentSession.groupLoot = self.db.currentSession.groupLoot + money
           else
               self.db.currentSession.goldLooted = self.db.currentSession.goldLooted + money
           end
           self:UpdateGUI()
       end
   end
   
   -- Handle merchant transactions
   function GoldFarm:HandleMerchantClosed()
       if self.merchantMoney then
           local currentMoney = self:GetCurrentMoney()
           local diff = currentMoney - self.merchantMoney
           
           if diff > 0 then
               -- Sold items
               self.db.currentSession.itemsSold = self.db.currentSession.itemsSold + diff
               self:UpdateGUI()
           end
           
           self.merchantMoney = nil
       end
   end
   
   -- Get session timer
   function GoldFarm:GetSessionTimer()
       if not self.db.currentSession then return "00:00:00" end
       
       local endTime = self.db.isRunning and time() or (self.db.currentSession.endTime or time())
       local elapsed = endTime - self.db.currentSession.startTime
       local hours = math.floor(elapsed / 3600)
       local minutes = math.floor((elapsed % 3600) / 60)
       local seconds = elapsed % 60
       
       return string.format("%02d:%02d:%02d", hours, minutes, seconds)
   end
   
   -- Calculate total
   function GoldFarm:GetSessionTotal()
       if not self.db.currentSession then return 0 end
       
       local session = self.db.currentSession
       return session.goldLooted + session.groupLoot + session.junkSold + session.itemsSold - session.repairs
   end
   
   -- Export data
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
   
   -- Slash commands
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
   
   -- Initialize on addon loaded
   local initFrame = CreateFrame("Frame")
   initFrame:RegisterEvent("ADDON_LOADED")
   initFrame:SetScript("OnEvent", function(self, event, addonName)
       if addonName == "GoldFarm" then
           GoldFarm:OnInitialize()
           GoldFarm:CreateGUI()
           GoldFarm:CreateMinimapButton()
           self:UnregisterEvent("ADDON_LOADED")
       end
   end)