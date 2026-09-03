-- ShadowHawk | South Bronx Compatible Fix
-- Method: hook humanoid state, bypass game movement override

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG = {
    FastRun = { Enabled = false, TargetSpeed = 50 },
    HighJump = { Enabled = false, JumpPower = 100 },
}

-- ========== CORE: Anti-Override Engine ==========
-- Game reset WalkSpeed tiap frame? Kita juga set tiap frame.
-- Bukan ramp lagi — langsung override di Heartbeat priority tinggi.

local speedOverrideConn = nil
local jumpOverrideConn = nil

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function startSpeedOverride()
    if speedOverrideConn then speedOverrideConn:Disconnect() end
    speedOverrideConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.FastRun.Enabled then return end
        local hum = getHumanoid()
        if hum and hum.WalkSpeed ~= CONFIG.FastRun.TargetSpeed then
            hum.WalkSpeed = CONFIG.FastRun.TargetSpeed
        end
    end)
end

local function stopSpeedOverride()
    if speedOverrideConn then
        speedOverrideConn:Disconnect()
        speedOverrideConn = nil
    end
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = 16 end
end

local function startJumpOverride()
    if jumpOverrideConn then jumpOverrideConn:Disconnect() end
    jumpOverrideConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.HighJump.Enabled then return end
        local hum = getHumanoid()
        if hum then
            hum.UseJumpPower = true
            if hum.JumpPower ~= CONFIG.HighJump.JumpPower then
                hum.JumpPower = CONFIG.HighJump.JumpPower
            end
        end
    end)
end

local function stopJumpOverride()
    if jumpOverrideConn then
        jumpOverrideConn:Disconnect()
        jumpOverrideConn = nil
    end
    local hum = getHumanoid()
    if hum then hum.JumpPower = 50 end
end

-- Re-apply on respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    if CONFIG.FastRun.Enabled then startSpeedOverride() end
    if CONFIG.HighJump.Enabled then startJumpOverride() end
end)

-- ========== UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SHMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Icon
local IconBtn = Instance.new("ImageButton")
IconBtn.Size = UDim2.new(0, 48, 0, 48)
IconBtn.Position = UDim2.new(0, 16, 0.5, -24)
IconBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
IconBtn.BorderSizePixel = 0
IconBtn.AutoButtonColor = false
IconBtn.ZIndex = 10
IconBtn.Parent = ScreenGui

Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(1, 0)

local IconStroke = Instance.new("UIStroke")
IconStroke.Color = Color3.fromRGB(100, 80, 255)
IconStroke.Thickness = 2
IconStroke.Parent = IconBtn

local IconLabel = Instance.new("TextLabel")
IconLabel.Size = UDim2.new(1, 0, 1, 0)
IconLabel.BackgroundTransparency = 1
IconLabel.Text = "SH"
IconLabel.TextColor3 = Color3.fromRGB(180, 160, 255)
IconLabel.TextScaled = true
IconLabel.Font = Enum.Font.GothamBold
IconLabel.ZIndex = 11
IconLabel.Parent = IconBtn

-- Panel
local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 220, 0, 280)
Panel.Position = UDim2.new(0, 76, 0.5, -140)
Panel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Panel.BorderSizePixel = 0
Panel.ClipsDescendants = true
Panel.ZIndex = 5
Panel.Parent = ScreenGui

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 12)

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(100, 80, 255)
PanelStroke.Thickness = 1.5
PanelStroke.Parent = Panel

-- Title bar
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
Title.BorderSizePixel = 0
Title.Text = "  ShadowHawk"
Title.TextColor3 = Color3.fromRGB(200, 185, 255)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 6
Title.Parent = Panel

Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 12)

-- Toggle builder
local function makeToggle(parent, labelText, yPos, onToggle)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 38)
    Row.Position = UDim2.new(0, 12, 0, yPos)
    Row.BackgroundTransparency = 1
    Row.ZIndex = 6
    Row.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(210, 205, 230)
    Label.TextScaled = true
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 7
    Label.Parent = Row

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(0, 46, 0, 24)
    Track.Position = UDim2.new(1, -46, 0.5, -12)
    Track.BackgroundColor3 = Color3.fromRGB(50, 45, 70)
    Track.BorderSizePixel = 0
    Track.ZIndex = 7
    Track.Parent = Row

    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.Position = UDim2.new(0, 3, 0.5, -9)
    Knob.BackgroundColor3 = Color3.fromRGB(140, 130, 180)
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 8
    Knob.Parent = Track

    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.ZIndex = 9
    Btn.Parent = Track

    local enabled = false
    local tw = TweenInfo.new(0.2, Enum.EasingStyle.Quad)

    Btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            TweenService:Create(Track, tw, {BackgroundColor3 = Color3.fromRGB(100, 80, 255)}):Play()
            TweenService:Create(Knob, tw, {
                Position = UDim2.new(0, 25, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        else
            TweenService:Create(Track, tw, {BackgroundColor3 = Color3.fromRGB(50, 45, 70)}):Play()
            TweenService:Create(Knob, tw, {
                Position = UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(140, 130, 180)
            }):Play()
        end
        onToggle(enabled)
    end)
end

-- Slider builder
local function makeSlider(parent, labelText, yPos, minVal, maxVal, defaultVal, onChange)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 46)
    Row.Position = UDim2.new(0, 12, 0, yPos)
    Row.BackgroundTransparency = 1
    Row.ZIndex = 6
    Row.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 20)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(180, 170, 210)
    Label.TextScaled = true
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 7
    Label.Parent = Row

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(0.35, 0, 0, 20)
    ValLabel.Position = UDim2.new(0.65, 0, 0, 0)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = tostring(defaultVal)
    ValLabel.TextColor3 = Color3.fromRGB(160, 140, 255)
    ValLabel.TextScaled = true
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValLabel.ZIndex = 7
    ValLabel.Parent = Row

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, 0, 0, 6)
    Track.Position = UDim2.new(0, 0, 0, 28)
    Track.BackgroundColor3 = Color3.fromRGB(50, 45, 70)
    Track.BorderSizePixel = 0
    Track.ZIndex = 7
    Track.Parent = Row

    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(100, 80, 255)
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 8
    Fill.Parent = Track

    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Dragger = Instance.new("TextButton")
    Dragger.Size = UDim2.new(1, 0, 0, 18)
    Dragger.Position = UDim2.new(0, 0, 0.5, -9)
    Dragger.BackgroundTransparency = 1
    Dragger.Text = ""
    Dragger.ZIndex = 9
    Dragger.Parent = Track

    local dragging = false

    Dragger.MouseButton1Down:Connect(function() dragging = true end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local rel = math.clamp(
            (i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1
        )
        local val = math.floor(minVal + rel * (maxVal - minVal))
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        ValLabel.Text = tostring(val)
        onChange(val)
    end)
end

-- Build controls
makeToggle(Panel, "Fast Run", 44, function(state)
    CONFIG.FastRun.Enabled = state
    if state then startSpeedOverride() else stopSpeedOverride() end
end)

makeSlider(Panel, "Speed", 90, 17, 100, 50, function(val)
    CONFIG.FastRun.TargetSpeed = val
end)

makeToggle(Panel, "High Jump", 148, function(state)
    CONFIG.HighJump.Enabled = state
    if state then startJumpOverride() else stopJumpOverride() end
end)

makeSlider(Panel, "Jump Power", 194, 51, 300, 100, function(val)
    CONFIG.HighJump.JumpPower = val
end)

-- Hide/show panel
local panelVisible = true

IconBtn.MouseButton1Click:Connect(function()
    panelVisible = not panelVisible
    local tw = TweenInfo.new(0.25, Enum.EasingStyle.Quart)
    if panelVisible then
        Panel.Visible = true
        TweenService:Create(Panel, tw, {Size = UDim2.new(0, 220, 0, 280)}):Play()
        TweenService:Create(IconStroke, tw, {Color = Color3.fromRGB(100, 80, 255)}):Play()
    else
        TweenService:Create(Panel, tw, {Size = UDim2.new(0, 0, 0, 280)}):Play()
        TweenService:Create(IconStroke, tw, {Color = Color3.fromRGB(60, 55, 90)}):Play()
        task.delay(0.25, function() Panel.Visible = false end)
    end
end)

-- Draggable icon + panel follow
local draggingIcon, dragStart, startPos = false, nil, nil

IconBtn.MouseButton1Down:Connect(function(x, y)
    draggingIcon = true
    dragStart = Vector2.new(x, y)
    startPos = IconBtn.Position
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingIcon = false
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if not draggingIcon then return end
    if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local delta = Vector2.new(i.Position.X, i.Position.Y) - dragStart
    local newX = startPos.X.Offset + delta.X
    local newY = startPos.Y.Offset + delta.Y
    IconBtn.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
    Panel.Position = UDim2.new(0, newX + 60, startPos.Y.Scale, newY - 116)
end)

print("[SH] Loaded | Anti-override engine active")
