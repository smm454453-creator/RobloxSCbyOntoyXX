-- ShadowHawk v3 | Noclip + Ghost Walk + Click Teleport
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local CONFIG = {
    FastRun    = { Enabled = false, TargetSpeed = 50 },
    HighJump   = { Enabled = false, JumpPower = 100 },
    NoClip     = { Enabled = false },
    GhostWalk  = { Enabled = false, Speed = 40 },
    TeleClick  = { Enabled = false },
}

-- ======== CORE UTILS ========
local function getChar()
    return LocalPlayer.Character
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ======== FAST RUN ========
local speedConn
local function startSpeedOverride()
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.FastRun.Enabled then return end
        local h = getHum()
        if h and h.WalkSpeed ~= CONFIG.FastRun.TargetSpeed then
            h.WalkSpeed = CONFIG.FastRun.TargetSpeed
        end
    end)
end

local function stopSpeedOverride()
    if speedConn then speedConn:Disconnect() speedConn = nil end
    local h = getHum()
    if h then h.WalkSpeed = 16 end
end

-- ======== HIGH JUMP ========
local jumpConn
local function startJumpOverride()
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

local function stopJumpOverride()
    if jumpConn then jumpConn:Disconnect() jumpConn = nil end
    local h = getHum()
    if h then h.JumpPower = 50 end
end

-- ======== NO-CLIP ========
-- Collision dimatiin tiap Stepped — paling reliable
local noclipConn
local function setNoClip(state)
    CONFIG.NoClip.Enabled = state
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end

    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local char = getChar()
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    else
        local char = getChar()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ======== GHOST WALK ========
-- Badan (HRP) freeze di titik asal via Anchoring
-- Camera + visual ikut gerak bebas
-- Pas off: commit posisi camera ke HRP (teleport)

local ghostConn
local ghostOrigin = nil         -- posisi HRP waktu ON
local ghostCFrame = nil         -- CFrame current ghost position
local ghostCamera = nil         -- CFrame camera saat ghost aktif

local function setGhostWalk(state)
    CONFIG.GhostWalk.Enabled = state

    if ghostConn then ghostConn:Disconnect() ghostConn = nil end

    local root = getRoot()
    local hum  = getHum()

    if state then
        if not root then return end

        -- Simpan origin, anchor badan
        ghostOrigin = root.CFrame
        ghostCFrame = root.CFrame
        root.Anchored = true

        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end

        -- Ghost movement: WASD gerakin ghostCFrame, bukan badan
        ghostConn = RunService.RenderStepped:Connect(function(dt)
            local moveDir = Vector3.new(0, 0, 0)
            local camLook = Camera.CFrame.LookVector
            local camRight = Camera.CFrame.RightVector

            -- Flatten biar ga terbang kalau kamera ngadah
            local forward = Vector3.new(camLook.X, 0, camLook.Z).Unit
            local right   = Vector3.new(camRight.X, 0, camRight.Z).Unit

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + forward
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - forward
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - right
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + right
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDir = moveDir + Vector3.new(0, -1, 0)
            end

            if moveDir.Magnitude > 0 then
                ghostCFrame = ghostCFrame * CFrame.new(
                    moveDir.Unit * CONFIG.GhostWalk.Speed * dt
                )
            end

            -- Lock camera ke ghost position
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = CFrame.new(ghostCFrame.Position + Vector3.new(0, 8, 12),
                ghostCFrame.Position)
        end)

    else
        -- Commit: pindah HRP ke posisi ghost, lepas anchor
        if root and ghostCFrame then
            root.Anchored = false
            root.CFrame = ghostCFrame

            -- Kasih server sepersekian detik buat "nerima"
            task.wait(0.1)
        end

        -- Restore camera
        Camera.CameraType = Enum.CameraType.Custom

        if hum then
            hum.WalkSpeed = CONFIG.FastRun.Enabled and CONFIG.FastRun.TargetSpeed or 16
            hum.JumpPower = CONFIG.HighJump.Enabled and CONFIG.HighJump.JumpPower or 50
        end

        ghostOrigin = nil
        ghostCFrame  = nil
    end
end

-- ======== CLICK TELEPORT ========
-- Raycast ke titik yang diklik, teleport HRP ke sana
local teleClickConn
local function setTeleClick(state)
    CONFIG.TeleClick.Enabled = state
    if teleClickConn then teleClickConn:Disconnect() teleClickConn = nil end

    if state then
        teleClickConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end

            local unitRay = Camera:ScreenPointToRay(
                input.Position.X, input.Position.Y
            )
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local char = getChar()
            if char then rayParams.FilterDescendantsInstances = {char} end

            local result = workspace:Raycast(
                unitRay.Origin, unitRay.Direction * 500, rayParams
            )

            if result then
                local root = getRoot()
                if root then
                    -- Offset sedikit dari ground biar ga stuck
                    root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
                end
            end
        end)
    end
end

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.5)
    -- Reset ghost kalau lagi aktif
    if CONFIG.GhostWalk.Enabled then
        CONFIG.GhostWalk.Enabled = false
        Camera.CameraType = Enum.CameraType.Custom
    end
    if CONFIG.FastRun.Enabled then startSpeedOverride() end
    if CONFIG.HighJump.Enabled then startJumpOverride() end
    if CONFIG.NoClip.Enabled then setNoClip(true) end
    if CONFIG.TeleClick.Enabled then setTeleClick(true) end
end)

-- ======== UI ========
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
local PANEL_H = 460
local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 220, 0, PANEL_H)
Panel.Position = UDim2.new(0, 76, 0.5, -PANEL_H/2)
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

-- Section label helper
local function makeSection(parent, text, yPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 18)
    lbl.Position = UDim2.new(0, 12, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(120, 100, 200)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 6
    lbl.Parent = parent
end

-- Toggle helper
local function makeToggle(parent, labelText, yPos, onToggle)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 36)
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

-- Slider helper
local function makeSlider(parent, labelText, yPos, minVal, maxVal, defaultVal, onChange)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -24, 0, 44)
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
    Fill.Size = UDim2.new((defaultVal - minVal)/(maxVal - minVal), 0, 1, 0)
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
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local rel = math.clamp((i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + rel * (maxVal - minVal))
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        ValLabel.Text = tostring(val)
        onChange(val)
    end)
end

-- Hint label helper
local function makeHint(parent, text, yPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 16)
    lbl.Position = UDim2.new(0, 12, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(90, 85, 120)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 6
    lbl.Parent = parent
end

-- ---- Build controls ----
-- Movement
makeSection(Panel, "MOVEMENT", 42)
makeToggle(Panel, "Fast Run", 62, function(s)
    CONFIG.FastRun.Enabled = s
    if s then startSpeedOverride() else stopSpeedOverride() end
end)
makeSlider(Panel, "Speed", 100, 17, 100, 50, function(v)
    CONFIG.FastRun.TargetSpeed = v
end)
makeToggle(Panel, "High Jump", 148, function(s)
    CONFIG.HighJump.Enabled = s
    if s then startJumpOverride() else stopJumpOverride() end
end)
makeSlider(Panel, "Jump Power", 186, 51, 300, 100, function(v)
    CONFIG.HighJump.JumpPower = v
end)

-- Utility
makeSection(Panel, "UTILITY", 238)
makeToggle(Panel, "No-Clip", 258, function(s)
    setNoClip(s)
end)
makeHint(Panel, "Tembus semua object/wall", 296)

makeToggle(Panel, "Ghost Walk", 318, function(s)
    setGhostWalk(s)
end)
makeHint(Panel, "WASD ghost, Off = teleport ke sana", 356)
makeSlider(Panel, "Ghost Speed", 374, 10, 120, 40, function(v)
    CONFIG.GhostWalk.Speed = v
end)

makeToggle(Panel, "Click Teleport", 420, function(s)
    setTeleClick(s)
end)
makeHint(Panel, "Right-click permukaan = teleport", 458)

-- ---- Hide/Show ----
local panelVisible = true
IconBtn.MouseButton1Click:Connect(function()
    panelVisible = not panelVisible
    local tw = TweenInfo.new(0.25, Enum.EasingStyle.Quart)
    if panelVisible then
        Panel.Visible = true
        TweenService:Create(Panel, tw, {Size = UDim2.new(0, 220, 0, PANEL_H)}):Play()
        TweenService:Create(IconStroke, tw, {Color = Color3.fromRGB(100, 80, 255)}):Play()
    else
        TweenService:Create(Panel, tw, {Size = UDim2.new(0, 0, 0, PANEL_H)}):Play()
        TweenService:Create(IconStroke, tw, {Color = Color3.fromRGB(60, 55, 90)}):Play()
        task.delay(0.25, function() Panel.Visible = false end)
    end
end)

-- ---- Draggable icon ----
local draggingIcon, dragStart, startPos = false, nil, nil
IconBtn.MouseButton1Down:Connect(function(x, y)
    draggingIcon = true
    dragStart = Vector2.new(x, y)
    startPos = IconBtn.Position
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingIcon = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if not draggingIcon or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local delta = Vector2.new(i.Position.X, i.Position.Y) - dragStart
    local newX = startPos.X.Offset + delta.X
    local newY = startPos.Y.Offset + delta.Y
    IconBtn.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
    Panel.Position = UDim2.new(0, newX + 60, startPos.Y.Scale, newY - PANEL_H/2 + 24)
end)

print("[SH] v3 Loaded | Noclip + GhostWalk + ClickTeleport")
