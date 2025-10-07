-- GoldFarm Minimap Button (patched v1.0.2)
-- Fixes: Right-click reset logic, adds circular dragging, better tooltip refresh

function GoldFarm:CreateMinimapButton()
    -----------------------------------------------------------------------
    -- Safety: ensure DB structure exists
    -----------------------------------------------------------------------
    self.db = self.db or {}
    self.db.minimapButton = self.db.minimapButton or { hide = false, minimapPos = 220 }

    -----------------------------------------------------------------------
    -- Create button frame
    -----------------------------------------------------------------------
    self.minimapButton = CreateFrame("Button", "GoldFarmMinimapButton", Minimap)
    self.minimapButton:SetSize(32, 32)
    self.minimapButton:SetFrameStrata("HIGH")
    self.minimapButton:SetFrameLevel(10)

    -----------------------------------------------------------------------
    -- Set textures
    -----------------------------------------------------------------------
    self.minimapButton:SetNormalTexture("Interface\\Icons\\INV_Misc_Coin_01")
    self.minimapButton:SetPushedTexture("Interface\\Icons\\INV_Misc_Coin_01")
    self.minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -----------------------------------------------------------------------
    -- Position
    -----------------------------------------------------------------------
    self:UpdateMinimapButtonPosition()

    -----------------------------------------------------------------------
    -- Mouse handlers
    -----------------------------------------------------------------------
    self.minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self.minimapButton:RegisterForDrag("LeftButton")
    self.minimapButton:EnableMouse(true)

    -- Click handler: left = start/stop, right = reset (with Shift confirm)
    self.minimapButton:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            if self.db.isRunning then
                self:StopSession()
            else
                self:StartSession()
            end
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                self:ResetSession()
            else
                print("|cff00ff00GoldFarm:|r Hold Shift + Right Click to reset session.")
            end
        end
        self:UpdateMinimapTooltip() -- Refresh tooltip after actions
    end)

    -----------------------------------------------------------------------
    -- Circular drag handling
    -----------------------------------------------------------------------
    self.minimapButton:SetScript("OnDragStart", function()
        self.isDragging = true
        self.minimapButton:SetScript("OnUpdate", function()
            if self.isDragging then
                local mx, my = GetCursorPosition()
                local cx, cy = Minimap:GetCenter()
                local scale = UIParent:GetScale()
                local dx, dy = mx / scale - cx, my / scale - cy
                local angle = math.deg(math.atan2(dy, dx))
                self.db.minimapButton.minimapPos = angle
                self:UpdateMinimapButtonPosition()
            end
        end)
    end)

    self.minimapButton:SetScript("OnDragStop", function()
        self.isDragging = false
        self.minimapButton:SetScript("OnUpdate", nil)
    end)

    -----------------------------------------------------------------------
    -- Tooltip handlers
    -----------------------------------------------------------------------
    self.minimapButton:SetScript("OnEnter", function()
        self:UpdateMinimapTooltip()
    end)

    self.minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -----------------------------------------------------------------------
    -- Visibility
    -----------------------------------------------------------------------
    if self.db.minimapButton.hide then
        self.minimapButton:Hide()
    else
        self.minimapButton:Show()
    end
end

-----------------------------------------------------------------------
-- Update position based on stored angle
-----------------------------------------------------------------------
function GoldFarm:UpdateMinimapButtonPosition()
    if not self.minimapButton then return end

    local angle = math.rad(self.db.minimapButton.minimapPos or 220)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-----------------------------------------------------------------------
-- Tooltip helper
-----------------------------------------------------------------------
function GoldFarm:UpdateMinimapTooltip()
    if not self.minimapButton or not GameTooltip then return end

    GameTooltip:SetOwner(self.minimapButton, "ANCHOR_LEFT")
    GameTooltip:ClearLines()

    GameTooltip:AddLine("|cff00ff00GoldFarm|r", 1, 1, 1)
    if self.db.isRunning then
        GameTooltip:AddLine("|cff00ff00Session Running|r", 0, 1, 0)
    else
        GameTooltip:AddLine("|cffff0000Session Stopped|r", 1, 0, 0)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffffcc00Left Click:|r Start/Stop", 1, 1, 1)
    GameTooltip:AddLine("|cffffcc00Shift + Right Click:|r Reset Session", 1, 1, 1)
    GameTooltip:AddLine("|cffffcc00Drag:|r Move around minimap", 1, 1, 1)

    GameTooltip:Show()
end
