-- GoldFarm GUI

function GoldFarm:StartTimer()
    self:StopTimer()
    if C_Timer and C_Timer.NewTicker then
        self.gui.updateTimer = C_Timer.NewTicker(1, function()
            self:UpdateGUI()
        end)
    else
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

function GoldFarm:StopTimer()
    if self.gui then
        if self.gui.updateTimer then
            self.gui.updateTimer:Cancel()
            self.gui.updateTimer = nil
        end
        if self.gui.timerFrame then
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
        self.gui:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.gui:SetBackdropColor(0, 0, 0, 0.8)
        self.gui:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    else
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

    -- Stats (all light blue)
    local lightBlue = {0, 0.8, 1, 1}
    local stats = {
        { key = "goldLoot", label = "Gold loot:", color = lightBlue },
        { key = "groupLoot", label = "Group loot:", color = lightBlue },
        { key = "junkSold", label = "Junk sold:", color = lightBlue },
        { key = "itemsSold", label = "Items sold:", color = lightBlue },
        { key = "repairs", label = "Repairs:", color = lightBlue },
        { key = "total", label = "Total:", color = lightBlue }
    }

    self.gui.stats = {}
    for i, stat in ipairs(stats) do
        yOffset = yOffset - 20

        local label = self.gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", 8, yOffset)
        label:SetText(stat.label)
        label:SetTextColor(unpack(stat.color))

        local value = self.gui:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        value:SetPoint("TOPRIGHT", -8, yOffset)
        value:SetTextColor(unpack(stat.color))

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

    self:StartTimer()

    if self.db.guiVisible then
        self.gui:Show()
    else
        self.gui:Hide()
    end

    self:UpdateGUI()
end

function GoldFarm:UpdateGUI()
    if not self.gui then return end

    self.gui.title:SetText("GoldFarm")
    local currentMoney = self:GetCurrentMoney()
    self.gui.currentGold:SetText(GetCoinTextureString(currentMoney))

    if self.db.currentSession then
        local session = self.db.currentSession
        self.gui.sessionName:SetText(session.name or "")
        self.gui.timer:SetText(self:GetSessionTimer() or "")

        -- Debug print to verify values
        print("UpdateGUI junkSold:", session.junkSold, "repairs:", session.repairs)

        self.gui.stats.goldLoot.value:SetText(self:FormatMoneyForGUI(tonumber(session.goldLooted) or 0))
        self.gui.stats.groupLoot.value:SetText(self:FormatMoneyForGUI(tonumber(session.groupLoot) or 0))
        self.gui.stats.junkSold.value:SetText(self:FormatMoneyForGUI(tonumber(session.junkSold) or 0))
        self.gui.stats.itemsSold.value:SetText(self:FormatMoneyForGUI(tonumber(session.itemsSold) or 0))
        self.gui.stats.repairs.value:SetText(self:FormatMoneyForGUI(tonumber(session.repairs) or 0))
        self.gui.stats.total.value:SetText(self:FormatMoneyForGUI(self:GetSessionTotal() or 0))
    end
end

function GoldFarm:FormatMoneyForGUI(copper)
    local absCopper = math.abs(copper)
    local coinString = GetCoinTextureString(absCopper)
    if copper < 0 then
        return "-" .. coinString
    else
        return coinString
    end
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
