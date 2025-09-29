-- GoldFarm GUI
   
   -- Start the GUI update timer
   function GoldFarm:StartTimer()
       -- Clear any existing timer
       self:StopTimer()
       
       -- Create a new timer based on WoW version
       if C_Timer and C_Timer.NewTicker then
           -- Modern WoW
           self.gui.updateTimer = C_Timer.NewTicker(1, function()
               self:UpdateGUI()
           end)
       else
           -- Classic WoW - create our own timer
           self.gui.timerFrame = self.gui.timerFrame or CreateFrame("Frame")
           self.gui.timerFrame.elapsed = 0
           self.gui.timerFrame:SetScript("OnUpdate", function(frame, elapsed)
               frame.elapsed = frame.elapsed + elapsed
               if frame.elapsed >= 1 then
                   frame.elapsed = 0
                   self:UpdateGUI()
               end
           end)
           self.gui.timerFrame:Show()
       end
   end
   
   -- Stop the GUI update timer
   function GoldFarm:StopTimer()
       if self.gui then
           if self.gui.updateTimer then
               -- Modern WoW
               self.gui.updateTimer:Cancel()
               self.gui.updateTimer = nil
           end
           
           if self.gui.timerFrame then
               -- Classic WoW
               self.gui.timerFrame:SetScript("OnUpdate", nil)
           end
       end
   end
   
   function GoldFarm:CreateGUI()
       -- Main frame
       self.gui = CreateFrame("Frame", "GoldFarmGUI", UIParent)
       self.gui:SetSize(250, 180)
       self.gui:SetPoint("TOPLEFT", self.db.guiPosition.x, self.db.guiPosition.y)
       
       -- Handle backdrop compatibility between WoW versions
       if self.gui.SetBackdrop then
           -- Classic versions
           self.gui:SetBackdrop({
               bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
               edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
               tile = true, tileSize = 16, edgeSize = 16,
               insets = { left = 4, right = 4, top = 4, bottom = 4 }
           })
           self.gui:SetBackdropColor(0, 0, 0, 0.8)
           self.gui:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
       else
           -- Modern WoW versions - use BackdropTemplate
           if BackdropTemplateMixin then
               Mixin(self.gui, BackdropTemplateMixin)
           end
           
           self.gui:SetBackdrop({
               bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
               edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
               tile = true, tileSize = 16, edgeSize = 16,
               insets = { left = 4, right = 4, top = 4, bottom = 4 }
           })
           
           if self.gui.SetBackdropColor then
               self.gui:SetBackdropColor(0, 0, 0, 0.8)
               self.gui:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
           end
       end
       
       self.gui:SetMovable(true)
       self.gui:EnableMouse(true)
       
       -- Title and current gold
       self.gui.title = self.gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
       self.gui.title:SetPoint("TOPLEFT", 8, -8)
       self.gui.title:SetTextColor(0, 1, 0, 1) -- Green
       
       self.gui.currentGold = self.gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
       self.gui.currentGold:SetPoint("TOPRIGHT", -8, -8)
       self.gui.currentGold:SetTextColor(1, 1, 0, 1) -- Yellow
       
       -- Session info
       local yOffset = -25
       self.gui.sessionName = self.gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
       self.gui.sessionName:SetPoint("TOPLEFT", 8, yOffset)
       self.gui.sessionName:SetTextColor(1, 0.4, 0, 1) -- Orange
       
       self.gui.timer = self.gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
       self.gui.timer:SetPoint("TOPRIGHT", -8, yOffset)
       self.gui.timer:SetTextColor(0, 0.8, 1, 1) -- Light blue
       
       -- Stats
       local stats = {
           { key = "goldLoot", label = "Gold loot:", color = {1, 1, 0} },
           { key = "groupLoot", label = "Group loot:", color = {0, 1, 1} },
           { key = "junkSold", label = "Junk sold:", color = {0.5, 0.5, 0.5} },
           { key = "itemsSold", label = "Items sold:", color = {0, 1, 0} },
           { key = "repairs", label = "Repairs:", color = {1, 0, 0} },
           { key = "total", label = "Total:", color = {1, 1, 1} }
       }
       
       self.gui.stats = {}
       for i, stat in ipairs(stats) do
           yOffset = yOffset - 20
           
           local label = self.gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
           label:SetPoint("TOPLEFT", 8, yOffset)
           label:SetText(stat.label)
           label:SetTextColor(stat.color[1], stat.color[2], stat.color[3], 1)
           
           local value = self.gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
           value:SetPoint("TOPRIGHT", -8, yOffset)
           value:SetTextColor(stat.color[1], stat.color[2], stat.color[3], 1)
           
           self.gui.stats[stat.key] = { label = label, value = value }
       end
       
       -- Mouse interactions
       self.gui:SetScript("OnMouseDown", function(frame, button)
           if button == "LeftButton" and IsShiftKeyDown() then
               frame:StartMoving()
               frame.isMoving = true
           end
       end)
       
       self.gui:SetScript("OnMouseUp", function(frame, button)
           if frame.isMoving then
               frame:StopMovingOrSizing()
               frame.isMoving = false
               -- Save position
               local point, _, _, x, y = frame:GetPoint()
               self.db.guiPosition.x = x
               self.db.guiPosition.y = y
           end
       end)
       
       self.gui:SetScript("OnEnter", function()
           GameTooltip:SetOwner(self.gui, "ANCHOR_CURSOR")
           GameTooltip:SetText("|cff00ff00GoldFarm|r", 1, 1, 1)
           GameTooltip:AddLine("Shift + Left Click to move", 0, 1, 1)
           GameTooltip:Show()
       end)
       
       self.gui:SetScript("OnLeave", function()
           GameTooltip:Hide()
       end)
       
       -- Initialize the timer
       self:StartTimer()
       
       -- Set initial visibility
       if self.db.guiVisible then
           self.gui:Show()
       else
           self.gui:Hide()
       end
       
       self:UpdateGUI()
   end
   
   function GoldFarm:UpdateGUI()
       if not self.gui then return end
       
       -- Update title and current gold
       self.gui.title:SetText("GoldFarm")
       
       -- Use GetCoinTextureString for current gold display
       local currentMoney = self:GetCurrentMoney()
       self.gui.currentGold:SetText(GetCoinTextureString(currentMoney))
       
       if self.db.currentSession then
           local session = self.db.currentSession
           
           -- Update session info
           self.gui.sessionName:SetText(session.name)
           self.gui.timer:SetText(self:GetSessionTimer())
           
           -- Update stats - format money for GUI display
           self.gui.stats.goldLoot.value:SetText(self:FormatMoneyForGUI(session.goldLooted))
           self.gui.stats.groupLoot.value:SetText(self:FormatMoneyForGUI(session.groupLoot))
           self.gui.stats.junkSold.value:SetText(self:FormatMoneyForGUI(session.junkSold))
           self.gui.stats.itemsSold.value:SetText(self:FormatMoneyForGUI(session.itemsSold))
           self.gui.stats.repairs.value:SetText("-" .. self:FormatMoneyForGUI(session.repairs))
           self.gui.stats.total.value:SetText(self:FormatMoneyForGUI(self:GetSessionTotal()))
       end
   end
   
   -- Format money for GUI (using coin icons)
   function GoldFarm:FormatMoneyForGUI(copper)
       if copper == 0 then return GetCoinTextureString(0) end
       
       -- Use the built-in WoW function to get coin icons
       return GetCoinTextureString(copper)
   end
   
   function GoldFarm:ShowGUI()
       if self.gui then
           self.gui:Show()
       end
   end
   
   function GoldFarm:HideGUI()
       if self.gui then
           self.gui:Hide()
       end
   end