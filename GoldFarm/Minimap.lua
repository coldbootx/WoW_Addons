-- GoldFarm Minimap Button

function GoldFarm:CreateMinimapButton()
    -- Create minimap button
    self.minimapButton = CreateFrame("Button", "GoldFarmMinimapButton", Minimap)
    self.minimapButton:SetSize(32, 32)
    self.minimapButton:SetFrameStrata("MEDIUM")
    self.minimapButton:SetFrameLevel(8)
    
    -- Button texture
    self.minimapButton:SetNormalTexture("Interface\\Icons\\INV_Misc_Coin_01")
    self.minimapButton:SetPushedTexture("Interface\\Icons\\INV_Misc_Coin_01")
    self.minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Position button
    self:UpdateMinimapButtonPosition()
    
    -- Make it draggable
    self.minimapButton:SetMovable(true)
    self.minimapButton:EnableMouse(true)
    self.minimapButton:RegisterForDrag("LeftButton")
    
    -- Click handlers
    self.minimapButton:SetScript("OnMouseUp", function(frame, button)
        if button == "LeftButton" then
            if self.db.isRunning then
                self:StopSession()
            else
                self:StartSession()
            end
        elseif button == "RightButton" then
            if self.db.isRunning then
                self:ResetSession()
            end
            self:ResetSession()
        end
    end)
    
    -- Drag handler
    self.minimapButton:SetScript("OnDragStart", function()
        self.minimapButton:StartMoving()
    end)
    
    self.minimapButton:SetScript("OnDragStop", function()
        self.minimapButton:StopMovingOrSizing()
        self:SaveMinimapButtonPosition()
    end)
    
    -- Tooltip
    self.minimapButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self.minimapButton, "ANCHOR_LEFT")
        GameTooltip:SetText("|cff00ff00GoldFarm|r", 1, 1, 1)
        if self.db.isRunning then
            GameTooltip:AddLine("|cff00ff00Session Running|r", 0, 1, 0)
        else
            GameTooltip:AddLine("|cffff0000Session Stopped|r", 1, 0, 0)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffff6600Left Click:|r Start/Stop", 1, 1, 1)
        GameTooltip:AddLine("|cffff6600Right Click:|r Reset", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    self.minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Show/hide based on settings
    if not self.db.minimapButton.hide then
        self.minimapButton:Show()
    else
        self.minimapButton:Hide()
    end
end

function GoldFarm:UpdateMinimapButtonPosition()
    if not self.minimapButton then return end
    
    local angle = math.rad(self.db.minimapButton.minimapPos or 220)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function GoldFarm:SaveMinimapButtonPosition()
    if not self.minimapButton then return end
    
    local centerX, centerY = Minimap:GetCenter()
    local buttonX, buttonY = self.minimapButton:GetCenter()
    
    if centerX and centerY and buttonX and buttonY then
        local angle = math.atan2(buttonY - centerY, buttonX - centerX)
        self.db.minimapButton.minimapPos = math.deg(angle)
    end
end
