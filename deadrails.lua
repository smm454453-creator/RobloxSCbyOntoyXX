-- ShadowHawk | Dead Rail Edition
-- P = buka/tutup UI | K = Fast Run | J = High Jump

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG = {
    FastRun = { Enabled = false, TargetSpeed = 40 },
    HighJump = { Enabled = false, JumpPower = 120 },
}

-- ======== CORE ========
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local speedConn, jumpConn

local function startSpeed()
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.FastRun.Enabled then return end
        local h = getHum()
        if h and h.WalkSpeed ~= CONFIG.FastRun.TargetSpeed then
            h.WalkSpeed = CONFIG.FastRun.TargetSpeed
        end
    end)
end

local function stopSpeed()
    if speedConn then speedConn:Disconnect() speedConn = nil end
    local h = getHum()
    if h then h.WalkSpeed = 16 end
end

local function startJump()
    if jumpConn then jumpConn:Disconnect() end
    jumpConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.HighJump.Enabled then return end
        local h = getHum()
        if h then
            h.UseJumpPower = true
            if h.JumpPower ~= CONFIG.HighJump.JumpPower then
                h.JumpPower = CONFIG.HighJump.JumpPower
            end
        end
    end)
end

local function stopJump()
    if jumpConn then jumpConn:Disconnect() jumpConn = nil end
    local h = getHum()
    if h then h.JumpPower = 50 end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    if CONFIG.FastRun.Enabled then startSpeed() end
    if CONFIG.HighJump.Enabled then startJump() end
end)

-- ======== UI ========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SHDeadRail"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Hotkey hint (selalu visible, pojok kanan atas)
local HintFrame = Instance.new("Frame")
HintFrame.Size = UDim2.new(0, 180, 0, 56)
HintFrame.Position = UDim2.new(1, -192, 0, 12)
HintFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
HintFrame.BorderSizePixel = 0
HintFrame.ZIndex = 20
HintFrame.Parent = ScreenGui

Instance.new("UICorner", HintFrame).CornerRadius = UDim.new(0, 8)

local HintStroke = Instance.new("UIStroke")
HintStroke.Color = Color3.fromRGB(80, 65, 180)
HintStroke.Thickness = 1
HintStroke.Parent = HintFrame

local hints = {
    {text = "[P]  Menu", y = 6},
    {text = "[K]  Fast Run", y = 22},
    {text = "[J]  High Jump", y = 38},
}

for _, h in ipairs(hints) do
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 16)
    lbl.Position = UDim2.new(0, 10, 0, h.y)
    lbl.BackgroundTransparency = 1
    lbl.Text = h.text
    lbl.TextColor3 = Color3.fromRGB(160, 150, 210)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 21
    lbl.Parent = HintFrame
end

-- Status indicators di hint (berubah warna pas aktif)
local statusK = Instance.new("TextLabel")
statusK.Size = UDim2.new(0, 8, 0, 8)
statusK.Position = UDim2.new(1, -16, 0, 26)
statusK.BackgroundColor3 = Color3.fromRGB(60, 55, 90)
statusK.BorderSizePixel = 0
statusK.Text = ""
statusK.ZIndex = 22
statusK.Parent = HintFrame
Instance.new("UICorner", statusK).CornerRadius = UDim.new(1, 0)

local statusJ = Instance.new("TextLabel")
statusJ.Size = UDim2.new(0, 8, 0, 8)
statusJ.Position = UDim2.new(1, -16, 0, 42)
statusJ.BackgroundColor3 = Color3.fromRGB(60, 55, 90)
statusJ.BorderSizePixel = 0
statusJ.Text = ""
statusJ.ZIndex = 22
statusJ.Parent = HintFrame
Instance.new("UICorner", statusJ).CornerRadius = UDim.new(1, 0)

local function setStatusDot(dot, active)
    local tw = TweenInfo.new(0.15)
    TweenService:Create(dot, tw, {
        BackgroundColor3 = active
            and Color3.fromRGB(120, 100, 255)
            or  Color3.fromRGB(60, 55, 90)
    }):Play()
end

-- Main panel
local PANEL_W, PANEL_H = 240, 220
local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
Panel.Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
Panel.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
Panel.BorderSizePixel = 0
Panel.ClipsDescendants = true
Panel.Visible = false
Panel.ZIndex = 10
Panel.Parent = ScreenGui

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 12)

local PStroke = Instance.new("UIStroke")
PStroke.Color = Color3.fromRGB(100, 80, 255)
PStroke.Thickness = 1.5
PStroke.Parent = Panel

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 18, 42)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 11
TitleBar.Parent = Panel

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -12, 1, 0)
TitleLbl.Position = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "ShadowHawk  ·  Dead Rail"
TitleLbl.TextColor3 = Color3.fromRGB(195, 180, 255)
TitleLbl.TextScaled = true
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.ZIndex = 12
TitleLbl.Parent = TitleBar

-- Row builder (toggle + label + status dot)
local toggleRefs = {}  -- simpan referensi knob buat di-update dari hotkey

local function makeRow(parent, labelText, keyHint, yPos, onToggle)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 36)
    Row.Position = UDim2.new(0, 12, 0, yPos)
    Row.BackgroundTransparency = 1
    Row.ZIndex = 11
    Row.Parent = parent

    -- Key badge
    local Badge = Instance.new("TextLabel")
    Badge.Size = UDim2.new(0, 22, 0, 20)
    Badge.Position = UDim2.new(0, 0, 0.5, -10)
    Badge.BackgroundColor3 = Color3.fromRGB(35, 30, 60)
    Badge.BorderSizePixel = 0
    Badge.Text = keyHint
    Badge.TextColor3 = Color3.fromRGB(140, 120, 220)
    Badge.TextScaled = true
    Badge.Font = Enum.Font.Code
    Badge.ZIndex = 12
    Badge.Parent = Row

    Instance.new("UICorner", Badge).CornerRadius = UDim.new(0, 4)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.Position = UDim2.new(0, 28, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(210, 205, 230)
    Label.TextScaled = true
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 12
    Label.Parent = Row

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(0, 46, 0, 24)
    Track.Position = UDim2.new(1, -46, 0.5, -12)
    Track.BackgroundColor3 = Color3.fromRGB(50, 45, 70)
    Track.BorderSizePixel = 0
    Track.ZIndex = 12
    Track.Parent = Row

    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.Position = UDim2.new(0, 3, 0.5, -9)
    Knob.BackgroundColor3 = Color3.fromRGB(140, 130, 180)
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 13
    Knob.Parent = Track

    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.ZIndex = 14
    Btn.Parent = Track

    local enabled = false
    local twi = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

    local function applyVisual(state)
        if state then
            TweenService:Create(Track, twi, {BackgroundColor3 = Color3.fromRGB(100, 80, 255)}):Play()
            TweenService:Create(Knob, twi, {
                Position = UDim2.new(0, 25, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        else
            TweenService:Create(Track, twi, {BackgroundColor3 = Color3.fromRGB(50, 45, 70)}):Play()
            TweenService:Create(Knob, twi, {
                Position = UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(140, 130, 180)
            }):Play()
        end
    end

    Btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        applyVisual(enabled)
        onToggle(enabled)
    end)

    -- Return fungsi buat trigger dari hotkey
    return function()
        enabled = not enabled
        applyVisual(enabled)
        onToggle(enabled)
        return enabled
    end
end

-- Slider builder
local function makeSlider(parent, labelText, yPos, minVal, maxVal, defaultVal, onChange)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 50)
    Row.Position = UDim2.new(0, 12, 0, yPos)
    Row.BackgroundTransparency = 1
    Row.ZIndex = 11
    Row.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 20)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(160, 150, 200)
    Label.TextScaled = true
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 12
    Label.Parent = Row

    local ValLbl = Instance.new("TextLabel")
    ValLbl.Size = UDim2.new(0.35, 0, 0, 20)
    ValLbl.Position = UDim2.new(0.65, 0, 0, 0)
    ValLbl.BackgroundTransparency = 1
    ValLbl.Text = tostring(defaultVal)
    ValLbl.TextColor3 = Color3.fromRGB(160, 140, 255)
    ValLbl.TextScaled = true
    ValLbl.Font = Enum.Font.GothamBold
    ValLbl.TextXAlignment = Enum.TextXAlignment.Right
    ValLbl.ZIndex = 12
    ValLbl.Parent = Row

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, 0, 0, 6)
    Track.Position = UDim2.new(0, 0, 0, 30)
    Track.BackgroundColor3 = Color3.fromRGB(45, 40, 65)
    Track.BorderSizePixel = 0
    Track.ZIndex = 12
    Track.Parent = Row

    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((defaultVal - minVal)/(maxVal - minVal), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(100, 80, 255)
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 13
    Fill.Parent = Track

    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Dragger = Instance.new("TextButton")
    Dragger.Size = UDim2.new(1, 0, 0, 20)
    Dragger.Position = UDim2.new(0, 0, 0.5, -10)
    Dragger.BackgroundTransparency = 1
    Dragger.Text = ""
    Dragger.ZIndex = 14
    Dragger.Parent = Track

    local dragging = false
    Dragger.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local rel = math.clamp((i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + rel * (maxVal - minVal))
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        ValLbl.Text = tostring(val)
        onChange(val)
    end)
end

-- Build rows
local toggleK = makeRow(Panel, "Fast Run", "K", 46, function(s)
    CONFIG.FastRun.Enabled = s
    setStatusDot(statusK, s)
    if s then startSpeed() else stopSpeed() end
end)

makeSlider(Panel, "Speed", 86, 17, 100, 40, function(v)
    CONFIG.FastRun.TargetSpeed = v
end)

local toggleJ = makeRow(Panel, "High Jump", "J", 142, function(s)
    CONFIG.HighJump.Enabled = s
    setStatusDot(statusJ, s)
    if s then startJump() else stopJump() end
end)

makeSlider(Panel, "Jump Power", 182, 51, 250, 120, function(v)
    CONFIG.HighJump.JumpPower = v
end)

-- ======== HOTKEYS ========
local panelOpen = false

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- P: toggle panel
    if input.KeyCode == Enum.KeyCode.P then
        panelOpen = not panelOpen
        local tw = TweenInfo.new(0.2, Enum.EasingStyle.Quart)
        if panelOpen then
            Panel.Visible = true
            Panel.Size = UDim2.new(0, 0, 0, PANEL_H)
            TweenService:Create(Panel, tw, {Size = UDim2.new(0, PANEL_W, 0, PANEL_H)}):Play()
        else
            TweenService:Create(Panel, tw, {Size = UDim2.new(0, 0, 0, PANEL_H)}):Play()
            task.delay(0.2, function() Panel.Visible = false end)
        end
    end

    -- K: toggle fast run (works even kalau panel tutup)
    if input.KeyCode == Enum.KeyCode.K then
        local state = toggleK()
        setStatusDot(statusK, state)
    end

    -- J: toggle high jump
    if input.KeyCode == Enum.KeyCode.J then
        local state = toggleJ()
        setStatusDot(statusJ, state)
    end
end)

print("[SH] Dead Rail loaded | P=Menu  K=FastRun  J=HighJump")
