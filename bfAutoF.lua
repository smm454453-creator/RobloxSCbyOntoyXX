-- Fast Run & High Jump | Xeno Compatible + UI
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ========== CONFIG ==========
local CONFIG = {
    FastRun = {
        Enabled = false,
        TargetSpeed = 50,
        RampStep = 2,
        RampInterval = 0.05,
    },
    HighJump = {
        Enabled = false,
        JumpPower = 100,
    },
}
-- ============================

-- ========== CORE LOGIC ==========
local currentRamping = false

local function getHumanoid()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function startRamp(target)
    if currentRamping then return end
    currentRamping = true
    task.spawn(function()
        while currentRamping do
            local hum = getHumanoid()
            if hum then
                if math.abs(hum.WalkSpeed - target) < CONFIG.FastRun.RampStep then
                    hum.WalkSpeed = target
                    currentRamping = false
                    break
                elseif hum.WalkSpeed < target then
                    hum.WalkSpeed = hum.WalkSpeed + CONFIG.FastRun.RampStep
                else
                    hum.WalkSpeed = hum.WalkSpeed - CONFIG.FastRun.RampStep
                end
            end
            task.wait(CONFIG.FastRun.RampInterval)
        end
    end)
end

local function stopRamp()
    currentRamping = false
    startRamp(16)
end

local function applyJump(state)
    local hum = getHumanoid()
    if not hum then return end
    hum.UseJumpPower = true
    hum.JumpPower = state and CONFIG.HighJump.JumpPower or 50
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if CONFIG.FastRun.Enabled then startRamp(CONFIG.FastRun.TargetSpeed) end
    if CONFIG.HighJump.Enabled then applyJump(true) end
end)

RunService.Heartbeat:Connect(function()
    local hum = getHumanoid()
    if not hum then return end
    if CONFIG.FastRun.Enabled and not currentRamping then
        if hum.WalkSpeed ~= CONFIG.FastRun.TargetSpeed then
            startRamp(CONFIG.FastRun.TargetSpeed)
        end
    end
    if CONFIG.HighJump.Enabled and hum.JumpPower ~= CONFIG.HighJump.JumpPower then
        hum.JumpPower = CONFIG.HighJump.JumpPower
    end
end)

-- ========== UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SHMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Floating icon button (toggle show/hide panel)
local IconBtn = Instance.new("ImageButton")
IconBtn.Name = "IconBtn"
IconBtn.Size = UDim2.new(0, 48, 0, 48)
IconBtn.Position = UDim2.new(0, 16, 0.5, -24)
IconBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
IconBtn.BorderSizePixel = 0
IconBtn.AutoButtonColor = false
IconBtn.ZIndex = 10
IconBtn.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = IconBtn

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

-- Main panel
local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.new(0, 220, 0, 180)
Panel.Position = UDim2.new(0, 76, 0.5, -90)
Panel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Panel.BorderSizePixel = 0
Panel.ClipsDescendants = true
Panel.ZIndex = 5
Panel.Parent = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 12)
PanelCorner.Parent = Panel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(100, 80, 255)
PanelStroke.Thickness = 1.5
PanelStroke.Parent = Panel

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
Title.BorderSizePixel = 0
Title.Text = "  ShadowHawk"
Title.TextColor3 = Color3.fromRGB(200, 185, 255)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 6
Title.Parent = Panel

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = Title

-- Helper: buat toggle row
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

    local ToggleTrack = Instance.new("Frame")
    ToggleTrack.Size = UDim2.new(0, 46, 0, 24)
    ToggleTrack.Position = UDim2.new(1, -46, 0.5, -12)
    ToggleTrack.BackgroundColor3 = Color3.fromRGB(50, 45, 70)
    ToggleTrack.BorderSizePixel = 0
    ToggleTrack.ZIndex = 7
    ToggleTrack.Parent = Row

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = ToggleTrack

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.Position = UDim2.new(0, 3, 0.5, -9)
    Knob.BackgroundColor3 = Color3.fromRGB(140, 130, 180)
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 8
    Knob.Parent = ToggleTrack

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local enabled = false

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
    ToggleBtn.BackgroundTransparency = 1
    ToggleBtn.Text = ""
    ToggleBtn.ZIndex = 9
    ToggleBtn.Parent = ToggleTrack

    ToggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
        if enabled then
            TweenService:Create(ToggleTrack, tweenInfo, {BackgroundColor3 = Color3.fromRGB(100, 80, 255)}):Play()
            TweenService:Create(Knob, tweenInfo, {Position = UDim2.new(0, 25, 0.5, -9), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        else
            TweenService:Create(ToggleTrack, tweenInfo, {BackgroundColor3 = Color3.fromRGB(50, 45, 70)}):Play()
            TweenService:Create(Knob, tweenInfo, {Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.fromRGB(140, 130, 180)}):Play()
        end
        onToggle(enabled)
    end)

    return Row
end

-- Speed slider helper
local function makeSlider(parent, labelText, yPos, minVal, maxVal, defaultVal, onChange)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 42)
    Row.Position = UDim2.new(0, 12, 0, yPos)
    Row.BackgroundTransparency = 1
    Row.ZIndex = 6
    Row.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 18)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(180, 170, 210)
    Label.TextScaled = true
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 7
    Label.Parent = Row

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(0.35, 0, 0, 18)
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
    Track.Position = UDim2.new(0, 0, 0, 26)
    Track.BackgroundColor3 = Color3.fromRGB(50, 45, 70)
    Track.BorderSizePixel = 0
    Track.ZIndex = 7
    Track.Parent = Row

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = Track

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(100, 80, 255)
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 8
    Fill.Parent = Track

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Dragger = Instance.new("TextButton")
    Dragger.Size = UDim2.new(1, 0, 0, 14)
    Dragger.Position = UDim2.new(0, 0, 0.5, -7)
    Dragger.BackgroundTransparency = 1
    Dragger.Text = ""
    Dragger.ZIndex = 9
    Dragger.Parent = Track

    local dragging = false

    Dragger.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local trackPos = Track.AbsolutePosition.X
            local trackWidth = Track.AbsoluteSize.X
            local relative = math.clamp((i.Position.X - trackPos) / trackWidth, 0, 1)
            local value = math.floor(minVal + relative * (maxVal - minVal))
            Fill.Size = UDim2.new(relative, 0, 1, 0)
            ValLabel.Text = tostring(value)
            onChange(value)
        end
    end)
end

-- Panel size dinamis
Panel.Size = UDim2.new(0, 220, 0, 280)

makeToggle(Panel, "Fast Run", 44, function(state)
    CONFIG.FastRun.Enabled = state
    if state then startRamp(CONFIG.FastRun.TargetSpeed) else stopRamp() end
end)

makeSlider(Panel, "Speed", 90, 17, 150, 50, function(val)
    CONFIG.FastRun.TargetSpeed = val
    if CONFIG.FastRun.Enabled then
        currentRamping = false
        startRamp(val)
    end
end)

makeToggle(Panel, "High Jump", 142, function(state)
    CONFIG.HighJump.Enabled = state
    applyJump(state)
end)

makeSlider(Panel, "Jump Power", 188, 51, 300, 100, function(val)
    CONFIG.HighJump.JumpPower = val
    if CONFIG.HighJump.Enabled then applyJump(true) end
end)

-- Hide/show panel dengan klik icon
local panelVisible = true

IconBtn.MouseButton1Click:Connect(function()
    panelVisible = not panelVisible
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart)
    if panelVisible then
        Panel.Visible = true
        TweenService:Create(Panel, tweenInfo, {
            Size = UDim2.new(0, 220, 0, 280),
            BackgroundTransparency = 0
        }):Play()
        TweenService:Create(IconStroke, tweenInfo, {Color = Color3.fromRGB(100, 80, 255)}):Play()
    else
        TweenService:Create(Panel, tweenInfo, {
            Size = UDim2.new(0, 0, 0, 280),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.25, function() Panel.Visible = false end)
        TweenService:Create(IconStroke, tweenInfo, {Color = Color3.fromRGB(60, 55, 90)}):Play()
    end
end)

-- Draggable icon
local draggingIcon = false
local dragStart, startPos

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
    if draggingIcon and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(i.Position.X, i.Position.Y) - dragStart
        IconBtn.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        Panel.Position = UDim2.new(
            0,
            IconBtn.Position.X.Offset + 60,
            0.5,
            -140
        )
    end
end)

print("[SH] Loaded | Klik icon SH buat hide/show panel")
