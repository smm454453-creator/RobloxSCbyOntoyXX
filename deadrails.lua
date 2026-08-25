local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

local BASE_SPEED = 16
local BASE_JUMP = 50

local CONFIG = {
    FastRun      = false,
    HighJump     = false,
    InfiniteJump = false,
    RunSpeed     = 50,  -- Default slider speed
    JumpPower    = 100, -- Default slider jump
    Fullbright   = false,
    NoFog        = false,
}

-- Biar lompat tanpa batas jalan terus kalau diaktifin
UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump and LocalHumanoid then
        LocalHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- UI SETUP (Ontoy Base)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Ontoy_DeadRails"; screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local REDZ = {
    BG         = Color3.fromRGB(14,12,16),
    BG2        = Color3.fromRGB(20,16,22),
    Accent     = Color3.fromRGB(200,30,50),
    ToggleOff  = Color3.fromRGB(40,32,36),
    TextMain   = Color3.fromRGB(240,220,225),
    Stroke     = Color3.fromRGB(60,30,40),
}

local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(0,520,0,460); mainWindow.Position = UDim2.new(0.5,-260,0.5,-230)
mainWindow.BackgroundColor3 = REDZ.BG; mainWindow.BorderSizePixel = 0
mainWindow.Active = true; mainWindow.Parent = screenGui
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", mainWindow).Color = REDZ.Stroke; Instance.new("UIStroke", mainWindow).Thickness = 1.5

local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size = UDim2.new(1,0,0,42); titleBar.BackgroundColor3 = REDZ.BG2
titleBar.BorderSizePixel = 0; titleBar.Active = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

-- Fitur Drag Window
local draggingWindow, dragStartMouse, dragStartPos = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = true
        dragStartMouse = Vector2.new(i.Position.X, i.Position.Y)
        dragStartPos = mainWindow.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if draggingWindow and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = Vector2.new(i.Position.X, i.Position.Y) - dragStartMouse
        mainWindow.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset+d.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingWindow = false end
end)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1,-160,1,0); titleText.Position = UDim2.new(0,30,0,0)
titleText.BackgroundTransparency = 1; titleText.Text = "ONTOY HUB <font color='#C81E32'>·</font> Dead Rails"
titleText.RichText = true; titleText.TextColor3 = REDZ.TextMain
titleText.Font = Enum.Font.GothamBold; titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left

local function MakeWinBtn(parent, xOff, bg, txt)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0,26,0,26); b.Position = UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3 = bg; b.Text = txt; b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end
local closeBtn    = MakeWinBtn(titleBar, -34, REDZ.Accent, "✕")
local minimizeBtn = MakeWinBtn(titleBar, -66, REDZ.ToggleOff, "—")

local contentArea = Instance.new("ScrollingFrame", mainWindow)
contentArea.Size = UDim2.new(1,-16,1,-50); contentArea.Position = UDim2.new(0,8,0,46)
contentArea.BackgroundTransparency = 1; contentArea.BorderSizePixel = 0
contentArea.ScrollBarThickness = 3
contentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y

local lay = Instance.new("UIListLayout", contentArea)
lay.Padding = UDim.new(0,6); lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentArea).PaddingBottom = UDim.new(0, 10)

local function MakeToggle(parent, label, key)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,40); row.BackgroundColor3 = REDZ.BG2
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    
    local t = Instance.new("TextLabel", row)
    t.Size = UDim2.new(1,-60,1,0); t.Position = UDim2.new(0,14,0,0)
    t.BackgroundTransparency = 1; t.Text = label; t.TextColor3 = REDZ.TextMain
    t.Font = Enum.Font.GothamBold; t.TextSize = 12; t.TextXAlignment = Enum.TextXAlignment.Left
    
    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(0,36,0,20); bg.Position = UDim2.new(1,-48,0.5,-10)
    bg.BackgroundColor3 = REDZ.ToggleOff; bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,10)
    local btn = Instance.new("TextButton", bg)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    
    btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        bg.BackgroundColor3 = CONFIG[key] and REDZ.Accent or REDZ.ToggleOff
    end)
end

local function MakeSlider(parent, label, minV, maxV, defaultV, configKey)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,54); row.BackgroundColor3 = REDZ.BG2
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local t = Instance.new("TextLabel", row)
    t.Size = UDim2.new(1,-60,0,20); t.Position = UDim2.new(0,14,0,8)
    t.BackgroundTransparency = 1; t.Text = label; t.TextColor3 = REDZ.TextMain
    t.Font = Enum.Font.GothamBold; t.TextSize = 12; t.TextXAlignment = Enum.TextXAlignment.Left

    local val = Instance.new("TextLabel", row)
    val.Size = UDim2.new(0,50,0,20); val.Position = UDim2.new(1,-64,0,8)
    val.BackgroundTransparency = 1; val.Text = tostring(defaultV); val.TextColor3 = REDZ.Accent
    val.Font = Enum.Font.GothamBold; val.TextSize = 12; val.TextXAlignment = Enum.TextXAlignment.Right

    local sbg = Instance.new("Frame", row)
    sbg.Size = UDim2.new(1,-28,0,6); sbg.Position = UDim2.new(0,14,0,36)
    sbg.BackgroundColor3 = REDZ.ToggleOff; sbg.BorderSizePixel = 0
    Instance.new("UICorner", sbg).CornerRadius = UDim.new(0,3)

    local fill = Instance.new("Frame", sbg)
    local initPct = (defaultV - minV) / (maxV - minV)
    fill.Size = UDim2.new(initPct,0,1,0); fill.BackgroundColor3 = REDZ.Accent; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)
    
    local btn = Instance.new("TextButton", sbg)
    btn.Size = UDim2.new(1,0,1,16); btn.Position = UDim2.new(0,0,0,-8)
    btn.BackgroundTransparency = 1; btn.Text = ""

    local dragging = false
    local function Update(input)
        local pct = math.clamp((input.Position.X - sbg.AbsolutePosition.X) / sbg.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        local realValue = math.floor(minV + ((maxV - minV) * pct))
        val.Text = tostring(realValue)
        CONFIG[configKey] = realValue
    end

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; Update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then Update(input) end
    end)
end

-- Bikin Menu UI
MakeToggle(contentArea, "Enable Fast Run", "FastRun")
MakeSlider(contentArea, "Set Run Speed", 16, 200, 50, "RunSpeed")

MakeToggle(contentArea, "Enable High Jump", "HighJump")
MakeSlider(contentArea, "Set Jump Power", 50, 300, 100, "JumpPower")

MakeToggle(contentArea, "Infinite Jump (Lompat Di Udara)", "InfiniteJump")
MakeToggle(contentArea, "Fullbright", "Fullbright")
MakeToggle(contentArea, "No Fog", "NoFog")

-- Tombol Minimize & Close
local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
    contentVisible = not contentVisible
    contentArea.Visible = contentVisible
    mainWindow.Size = contentVisible and UDim2.new(0,520,0,460) or UDim2.new(0,520,0,42)
end)

closeBtn.MouseButton1Click:Connect(function()
    if LocalHumanoid then 
        LocalHumanoid.WalkSpeed = BASE_SPEED
        LocalHumanoid.UseJumpPower = true
        LocalHumanoid.JumpPower = BASE_JUMP
    end
    screenGui:Destroy()
end)

-- Update Humanoid pas respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalHumanoid = char:WaitForChild("Humanoid")
end)

local originalFog = Lighting.FogEnd
RunService.RenderStepped:Connect(function()
    -- Logika Movement (Paksa Update Biar Gak Nyangkut)
    if LocalHumanoid then
        if CONFIG.FastRun then
            LocalHumanoid.WalkSpeed = CONFIG.RunSpeed
        else
            LocalHumanoid.WalkSpeed = BASE_SPEED
        end
        
        if CONFIG.HighJump then
            LocalHumanoid.UseJumpPower = true
            LocalHumanoid.JumpPower = CONFIG.JumpPower
        else
            LocalHumanoid.UseJumpPower = true
            LocalHumanoid.JumpPower = BASE_JUMP
        end
    end
    
    -- Logika Visuals
    if CONFIG.Fullbright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ClockTime = 12
    end
    
    if CONFIG.NoFog then
        Lighting.FogEnd = 100000
    else
        Lighting.FogEnd = originalFog
    end
end)
