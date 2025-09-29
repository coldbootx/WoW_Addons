-- Create main frame with transparent background
local frame = CreateFrame("Frame", "NetinfoFrame", UIParent, "BackdropTemplate")
frame:SetPoint("CENTER")
frame:SetSize(220, 180)
frame:SetBackdrop({
    bgFile = "Interface/ChatFrame/ChatFrameBackground",
    edgeFile = nil,
    tile = true,
    tileSize = 16,
    edgeSize = 0,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
frame:SetBackdropColor(0, 0, 0, 0.3) -- semi-transparent black

-- Make frame movable
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Title text
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -10)
title:SetText("Netinfo")
title:SetTextColor(0.5, 0.75, 1) -- Light blue

-- Create font strings for info
local fpsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
fpsText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)

local homeLatencyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
homeLatencyText:SetPoint("TOPLEFT", fpsText, "BOTTOMLEFT", 0, -8)

local worldLatencyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
worldLatencyText:SetPoint("TOPLEFT", homeLatencyText, "BOTTOMLEFT", 0, -8)

local memUsageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
memUsageText:SetPoint("TOPLEFT", worldLatencyText, "BOTTOMLEFT", 0, -8)

-- Colors
local blueColor = { r = 0.5, g = 0.75, b = 1 } -- Light blue
local redColor = { r = 1, g = 0, b = 0 } -- Red

-- Helper to get color based on latency
local function GetLatencyColor(latency)
    if latency > 25 then
        return redColor.r, redColor.g, redColor.b -- Red if > 25ms
    else
        return blueColor.r, blueColor.g, blueColor.b -- Blue otherwise
    end
end

-- Update function
local function UpdateInfo()
    -- FPS
    local fps = floor(GetFramerate())

    -- Latencies
    local homeLatency, worldLatency = select(3, GetNetStats()), select(4, GetNetStats())

    -- Memory usage
    local memoryUsageMB = (collectgarbage("count") / 1024)

    -- Set FPS
    fpsText:SetText("FPS: " .. fps)
    fpsText:SetTextColor(blueColor.r, blueColor.g, blueColor.b)

    -- Home Latency
    local r, g, b = GetLatencyColor(homeLatency)
    homeLatencyText:SetText(string.format("Home Latency: %d ms", homeLatency))
    homeLatencyText:SetTextColor(r, g, b)

    -- World Latency
    r, g, b = GetLatencyColor(worldLatency)
    worldLatencyText:SetText(string.format("World Latency: %d ms", worldLatency))
    worldLatencyText:SetTextColor(r, g, b)

    -- Memory
    memUsageText:SetText(string.format("Memory Usage: %.2f MB", memoryUsageMB))
    memUsageText:SetTextColor(blueColor.r, blueColor.g, blueColor.b)
end

-- Periodic update
local updateInterval = 1 -- seconds
local elapsed = 0

frame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed >= updateInterval then
        UpdateInfo()
        elapsed = 0
    end
end)