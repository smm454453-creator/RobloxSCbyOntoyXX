local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

local CONFIG = {
    Mode1 = false, Mode2 = false, Mode3 = false,
    Mode4 = false, Mode5 = false, Mode6 = false,
    Mode7 = false, -- Silent Aim
    Mode8 = false, -- Fast Attack
    HitboxPercent   = 1,
    SpeedPercent    = 50,
    Radius          = 15,
    -- Fast Attack: berapa kali per detik nge-fire
    AttackHPS       = 10,   -- hits per second, range 1-30
    -- Silent Aim
    SilentAimFOV    = 120,  -- radius pixel dari center screen
}

local BASE_SPEED    = 16
local MAX_SPEED     = 500
local MIN_HITBOX    = 4
local MAX_HITBOX    = 80
local DASH_INTERVAL = 0.08

local OriginalLocalSize = nil
local ESP_Objects       = {}
local lastDashTime      = 0
local dashHolding       = false
local dashConn          = nil
local fastAttackConn    = nil
local lastAttackTick    = 0

-- ── NET BIND ─────────────────────────────────────────────────────────────────
local RegisterAttack = nil

task.spawn(function()
    -- coba path utama Blox Fruits
    local ok = pcall(function()
        local net = ReplicatedStorage
            :WaitForChild("Modules", 5)
            :WaitForChild("Net", 5)
        RegisterAttack = net:WaitForChild("RegisterAttack", 5)
    end)
    if not ok or not RegisterAttack then
        -- fallback: scan seluruh RS
        RegisterAttack = ReplicatedStorage:FindFirstChild("RegisterAttack", true)
    end
end)

-- ── SILENT AIM ───────────────────────────────────────────────────────────────
-- bukan overlay — hijack CFrame kamera ke arah target tiap frame
-- efek: semua jurus/projectile nge-hit target meski player ngarah ke mana aja

local silentTarget = nil  -- BasePart yang lagi di-lock

local function GetSilentTarget()
    local vp  = Camera.ViewportSize
    local cx  = vp.X / 2
    local cy  = vp.Y / 2
    local fov = CONFIG.SilentAimFOV

    local best, bestDist = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChild("Humanoid")
        if not (root and hum and hum.Health > 0) then continue end

        local screen, onScreen = Camera:WorldToScreenPoint(root.Position)
        if not onScreen then continue end

        local dx   = screen.X - cx
        local dy   = screen.Y - cy
        local dist = math.sqrt(dx*dx + dy*dy)

        -- hanya target yang masuk dalam FOV circle dari center
        if dist < fov and dist < bestDist then
            bestDist = dist
            best     = root
        end
    end

    return best
end

-- redirect CFrame kamera ke target — server nge-read arah kamera
-- pas FireServer, direction dihitung dari CFrame kamera bukan mouse
local function ApplySilentAim()
    if not CONFIG.Mode7 then
        silentTarget = nil
        return
    end

    silentTarget = GetSilentTarget()
    if not silentTarget then return end
    if not silentTarget.Parent then silentTarget = nil return end

    -- arahkan kamera ke target — smooth, satu frame
    local targetPos  = silentTarget.Position
    local camPos     = Camera.CFrame.Position
    local direction  = (targetPos - camPos).Unit
    local lookCFrame = CFrame.new(camPos, camPos + direction)

    Camera.CFrame = lookCFrame
end

-- ── FAST ATTACK ───────────────────────────────────────────────────────────────
-- FIX: AttackHPS = hits per second
-- interval = 1 / HPS
-- slider 1-30 → 1 hit/s sampai 30 hit/s
-- sebelumnya kebalik: slider 30 → delay 0.30s (malah lambat)

local function GetAttackInterval()
    return 1 / math.max(CONFIG.AttackHPS, 1)
end

local function GetFastTarget()
    -- prioritas: silent aim target yang udah di-lock
    if silentTarget and silentTarget.Parent then
        return silentTarget
    end
    -- fallback: nearest on-screen
    local best, bestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChild("Humanoid")
        if not (root and hum and hum.Health > 0) then continue end
        local _, onScreen = Camera:WorldToScreenPoint(root.Position)
        if not onScreen then continue end
        local dist = (root.Position - LocalRoot.Position).Magnitude
        if dist < bestDist then
            bestDist = dist
            best     = root
        end
    end
    return best
end

local function StartFastAttack()
    if fastAttackConn then fastAttackConn:Disconnect() fastAttackConn = nil end

    fastAttackConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.Mode8 then return end
        if not RegisterAttack then return end

        local now = tick()
        if now - lastAttackTick < GetAttackInterval() then return end
        lastAttackTick = now

        local target = GetFastTarget()
        if not target then return end

        pcall(function()
            RegisterAttack:FireServer(target)
        end)
    end)
end

local function StopFastAttack()
    if fastAttackConn then fastAttackConn:Disconnect() fastAttackConn = nil end
end

-- ── HITBOX ────────────────────────────────────────────────────────────────────
local function PctToSize(pct)
    return MIN_HITBOX + (MAX_HITBOX - MIN_HITBOX) * ((pct - 1) / 99)
end

local function ExpandHitbox()
    if not OriginalLocalSize then OriginalLocalSize = LocalRoot.Size end
    local sz = PctToSize(CONFIG.HitboxPercent)
    LocalRoot.Size = Vector3.new(sz, sz, sz)
end

local function RestoreHitbox()
    if OriginalLocalSize then
        LocalRoot.Size = OriginalLocalSize
        OriginalLocalSize = nil
    end
end

local function GetTargetSpeed()
    return BASE_SPEED + (MAX_SPEED - BASE_SPEED) * (CONFIG.SpeedPercent / 100)
end

local function Mode2Func(pos)
    local p = Instance.new("Part")
    p.Name = "Ontoy_Part"
    p.Size = Vector3.new(CONFIG.Radius * 2, 10, CONFIG.Radius * 2)
    p.Position = pos; p.Anchored = true
    p.CanCollide = false; p.Transparency = 1
    p.Parent = Workspace
    game:GetService("Debris"):AddItem(p, 0.1)
end

-- ── DASH ─────────────────────────────────────────────────────────────────────
local function SimulateDash()
    pcall(function()
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    end)
    task.delay(0.03, function()
        pcall(function()
            game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)
    end)
end

local function StartDashLoop()
    if dashConn then dashConn:Disconnect() dashConn = nil end
    dashConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.Mode6 or not dashHolding then return end
        local now = tick()
        if now - lastDashTime >= DASH_INTERVAL then
            lastDashTime = now
            SimulateDash()
        end
    end)
end

local function StopDashLoop()
    if dashConn then dashConn:Disconnect() dashConn = nil end
    dashHolding = false
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Q and CONFIG.Mode6 then
        dashHolding = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then dashHolding = false end
end)

-- ── ESP ───────────────────────────────────────────────────────────────────────
local function CreateESP(player)
    local esp = {
        Box       = Drawing.new("Square"),
        Line      = Drawing.new("Line"),
        NameTag   = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
    }
    esp.Box.Thickness = 1; esp.Box.Color = Color3.fromRGB(255,50,50)
    esp.Box.Filled = false; esp.Box.Visible = false
    esp.Line.Thickness = 1; esp.Line.Color = Color3.fromRGB(0,255,255); esp.Line.Visible = false
    esp.NameTag.Size = 13; esp.NameTag.Color = Color3.fromRGB(255,255,255)
    esp.NameTag.Center = true; esp.NameTag.Outline = true
    esp.NameTag.OutlineColor = Color3.fromRGB(0,0,0); esp.NameTag.Visible = false
    esp.HealthBar.Thickness = 1; esp.HealthBar.Filled = true; esp.HealthBar.Visible = false
    return esp
end

local function CleanupESP(p)
    local esp = ESP_Objects[p]
    if esp then
        esp.Box:Remove(); esp.Line:Remove()
        esp.NameTag:Remove(); esp.HealthBar:Remove()
        ESP_Objects[p] = nil
    end
end

local function HideESP(esp)
    esp.Box.Visible = false; esp.NameTag.Visible = false
    esp.Line.Visible = false; esp.HealthBar.Visible = false
end

local function HideAllESP()
    for _, esp in pairs(ESP_Objects) do HideESP(esp) end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then ESP_Objects[p] = CreateESP(p) end
end
Players.PlayerAdded:Connect(function(p)    ESP_Objects[p] = CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) CleanupESP(p) end)

-- silent aim FOV circle — drawing overlay
local fovCircle = Drawing.new("Circle")
fovCircle.Radius    = CONFIG.SilentAimFOV
fovCircle.Color     = Color3.fromRGB(255, 60, 80)
fovCircle.Filled    = false
fovCircle.Thickness = 1
fovCircle.Visible   = false

local function RenderESP()
    if not CONFIG.Mode3 then HideAllESP() return end
    for player, esp in pairs(ESP_Objects) do
        local character = player.Character
        if not character then HideESP(esp) continue end
        local root = character:FindFirstChild("HumanoidRootPart")
        local hum  = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        if not (root and hum and head and hum.Health > 0) then HideESP(esp) continue end
        local rs, onScreen = Camera:WorldToScreenPoint(root.Position)
        local hs           = Camera:WorldToScreenPoint(head.Position)
        if not onScreen then HideESP(esp) continue end
        local height = math.max(math.abs(rs.Y - hs.Y) * 2, 10)
        local width  = height * 0.5
        local boxPos = Vector2.new(rs.X - width/2, rs.Y - height/2)
        esp.Box.Size = Vector2.new(width, height); esp.Box.Position = boxPos; esp.Box.Visible = true
        local hpR  = hum.Health / hum.MaxHealth
        local barH = height * hpR
        esp.HealthBar.Size     = Vector2.new(4, barH)
        esp.HealthBar.Position = Vector2.new(boxPos.X - 7, boxPos.Y + (height - barH))
        esp.HealthBar.Color    = Color3.fromRGB(math.floor(255*(1-hpR)), math.floor(255*hpR), 0)
        esp.HealthBar.Visible  = true
        local dist = math.floor((root.Position - LocalRoot.Position).Magnitude)
        esp.NameTag.Text     = player.Name.." ["..math.floor(hum.Health).."hp | "..dist.."m]"
        esp.NameTag.Position = Vector2.new(rs.X, boxPos.Y - 16)
        esp.NameTag.Visible  = true
        if CONFIG.Mode4 then
            local sc = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            esp.Line.From = sc; esp.Line.To = Vector2.new(rs.X, rs.Y); esp.Line.Visible = true
        else
            esp.Line.Visible = false
        end
    end
end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Ontoy_Hub"; screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local REDZ = {
    BG         = Color3.fromRGB(14, 12, 16),
    BG2        = Color3.fromRGB(20, 16, 22),
    Accent     = Color3.fromRGB(200, 30, 50),
    AccentDim  = Color3.fromRGB(120, 20, 35),
    AccentGlow = Color3.fromRGB(255, 60, 80),
    TextMain   = Color3.fromRGB(240, 220, 225),
    TextSub    = Color3.fromRGB(130, 100, 110),
    Stroke     = Color3.fromRGB(60, 30, 40),
    ToggleOff  = Color3.fromRGB(40, 32, 36),
    SliderFill = Color3.fromRGB(200, 30, 50),
    SliderBG   = Color3.fromRGB(35, 28, 32),
}

local mainWindow = Instance.new("Frame")
mainWindow.Size             = UDim2.new(0, 580, 0, 400)
mainWindow.Position         = UDim2.new(0.5, -290, 0.5, -200)
mainWindow.BackgroundColor3 = REDZ.BG
mainWindow.BorderSizePixel  = 0
mainWindow.Active           = true
mainWindow.Draggable        = false
mainWindow.Parent           = screenGui
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", mainWindow)
mainStroke.Color = REDZ.Stroke; mainStroke.Thickness = 1.5

local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size             = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = REDZ.BG2
titleBar.BorderSizePixel  = 0
titleBar.Active           = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local draggingWindow = false
local dragStartMouse = Vector2.zero
local dragStartPos   = UDim2.new()

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = true
        dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
        dragStartPos   = mainWindow.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = Vector2.new(input.Position.X, input.Position.Y) - dragStartMouse
        mainWindow.Position = UDim2.new(
            dragStartPos.X.Scale, dragStartPos.X.Offset + d.X,
            dragStartPos.Y.Scale, dragStartPos.Y.Offset + d.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = false
    end
end)

local titleAccentLine = Instance.new("Frame", titleBar)
titleAccentLine.Size             = UDim2.new(1, 0, 0, 2)
titleAccentLine.Position         = UDim2.new(0, 0, 1, -2)
titleAccentLine.BackgroundColor3 = REDZ.Accent
titleAccentLine.BorderSizePixel  = 0

local logoDot = Instance.new("Frame", titleBar)
logoDot.Size             = UDim2.new(0, 8, 0, 8)
logoDot.Position         = UDim2.new(0, 14, 0.5, -4)
logoDot.BackgroundColor3 = REDZ.AccentGlow
logoDot.BorderSizePixel  = 0
Instance.new("UICorner", logoDot).CornerRadius = UDim.new(0, 4)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size                   = UDim2.new(1, -160, 1, 0)
titleText.Position               = UDim2.new(0, 30, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text                   = "ONTOY HUB  <font color='#C81E32'>·</font>  Blox Fruits"
titleText.RichText                = true
titleText.TextColor3             = REDZ.TextMain
titleText.Font                   = Enum.Font.GothamBold
titleText.TextSize               = 13
titleText.TextXAlignment         = Enum.TextXAlignment.Left

local byLabel = Instance.new("TextLabel", titleBar)
byLabel.Size                   = UDim2.new(0, 80, 1, 0)
byLabel.Position               = UDim2.new(0, 195, 0, 0)
byLabel.BackgroundTransparency = 1
byLabel.Text                   = "by ontoy"
byLabel.TextColor3             = REDZ.TextSub
byLabel.Font                   = Enum.Font.Gotham
byLabel.TextSize               = 11
byLabel.TextXAlignment         = Enum.TextXAlignment.Left

local function MakeWindowBtn(parent, xOff, bg, txt)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 26, 0, 26); btn.Position = UDim2.new(1, xOff, 0.5, -13)
    btn.BackgroundColor3 = bg; btn.Text = txt
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local closeBtn    = MakeWindowBtn(titleBar, -34, REDZ.Accent,    "✕")
local minimizeBtn = MakeWindowBtn(titleBar, -66, REDZ.ToggleOff, "—")

local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size = UDim2.new(0, 148, 1, -42); sidebar.Position = UDim2.new(0, 0, 0, 42)
sidebar.BackgroundColor3 = REDZ.BG2; sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
local sideStroke = Instance.new("UIStroke", sidebar)
sideStroke.Color = REDZ.Stroke; sideStroke.Thickness = 1
local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding = UDim.new(0, 3)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 12)

local contentArea = Instance.new("Frame", mainWindow)
contentArea.Size = UDim2.new(1, -156, 1, -50); contentArea.Position = UDim2.new(0, 152, 0, 46)
contentArea.BackgroundTransparency = 1; contentArea.BorderSizePixel = 0

local contentScroll = Instance.new("ScrollingFrame", contentArea)
contentScroll.Size = UDim2.new(1, 0, 1, 0); contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0; contentScroll.ScrollBarThickness = 3
contentScroll.ScrollBarImageColor3 = REDZ.AccentDim
contentScroll.CanvasSize = UDim2.new(0,0,0,0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local contentLayout = Instance.new("UIListLayout", contentScroll)
contentLayout.Padding = UDim.new(0, 6)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentScroll).PaddingTop = UDim.new(0, 8)

local pages = {}; local sidebarButtons = {}

local function MakePage()
    local pg = Instance.new("Frame", contentScroll)
    pg.Size = UDim2.new(1, 0, 0, 0); pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1; pg.BorderSizePixel = 0; pg.Visible = false
    local lay = Instance.new("UIListLayout", pg)
    lay.Padding = UDim.new(0, 6); lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Instance.new("UIPadding", pg).PaddingBottom = UDim.new(0, 8)
    return pg
end

local function MakeSidebarBtn(icon, label, id)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -14, 0, 38); btn.BackgroundColor3 = REDZ.ToggleOff
    btn.BackgroundTransparency = 1; btn.Text = ""; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local accentBar = Instance.new("Frame", btn)
    accentBar.Size = UDim2.new(0, 3, 0.6, 0); accentBar.Position = UDim2.new(0, 0, 0.2, 0)
    accentBar.BackgroundColor3 = REDZ.Accent; accentBar.BorderSizePixel = 0; accentBar.Visible = false
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)
    local iconL = Instance.new("TextLabel", btn)
    iconL.Size = UDim2.new(0, 22, 1, 0); iconL.Position = UDim2.new(0, 10, 0, 0)
    iconL.BackgroundTransparency = 1; iconL.Text = icon
    iconL.TextColor3 = REDZ.TextSub; iconL.Font = Enum.Font.GothamBold; iconL.TextSize = 14
    local labelL = Instance.new("TextLabel", btn)
    labelL.Size = UDim2.new(1, -38, 1, 0); labelL.Position = UDim2.new(0, 36, 0, 0)
    labelL.BackgroundTransparency = 1; labelL.Text = label
    labelL.TextColor3 = REDZ.TextSub; labelL.Font = Enum.Font.Gotham; labelL.TextSize = 12
    labelL.TextXAlignment = Enum.TextXAlignment.Left
    sidebarButtons[id] = {btn=btn, icon=iconL, label=labelL, bar=accentBar}
    return btn
end

local function SetActivePage(id)
    for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
    for bid, sb in pairs(sidebarButtons) do
        local active = (bid == id)
        sb.btn.BackgroundTransparency = active and 0 or 1
        sb.btn.BackgroundColor3       = active and Color3.fromRGB(30,18,22) or REDZ.ToggleOff
        sb.icon.TextColor3            = active and REDZ.AccentGlow or REDZ.TextSub
        sb.label.TextColor3           = active and REDZ.TextMain   or REDZ.TextSub
        sb.bar.Visible                = active
    end
end

local function MakeSectionLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, -8, 0, 18); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = REDZ.Accent
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local function MakeToggleRow(parent, label, sublabel)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 52); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1
    local title = Instance.new("TextLabel", row)
    title.Size = UDim2.new(1, -60, 0, 22); title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1; title.Text = label
    title.TextColor3 = REDZ.TextMain; title.Font = Enum.Font.GothamBold; title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    if sublabel then
        local sub = Instance.new("TextLabel", row)
        sub.Size = UDim2.new(1, -60, 0, 16); sub.Position = UDim2.new(0, 14, 0, 28)
        sub.BackgroundTransparency = 1; sub.Text = sublabel
        sub.TextColor3 = REDZ.TextSub; sub.Font = Enum.Font.Gotham; sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
    end
    local toggleBG = Instance.new("Frame", row)
    toggleBG.Size = UDim2.new(0, 36, 0, 20); toggleBG.Position = UDim2.new(1, -48, 0.5, -10)
    toggleBG.BackgroundColor3 = REDZ.ToggleOff; toggleBG.BorderSizePixel = 0
    Instance.new("UICorner", toggleBG).CornerRadius = UDim.new(0, 10)
    local toggleKnob = Instance.new("Frame", toggleBG)
    toggleKnob.Size = UDim2.new(0, 14, 0, 14); toggleKnob.Position = UDim2.new(0, 3, 0.5, -7)
    toggleKnob.BackgroundColor3 = REDZ.TextSub; toggleKnob.BorderSizePixel = 0
    Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(0, 7)
    local togBtn = Instance.new("TextButton", toggleBG)
    togBtn.Size = UDim2.new(1, 8, 1, 8); togBtn.Position = UDim2.new(0, -4, 0, -4)
    togBtn.BackgroundTransparency = 1; togBtn.Text = ""; togBtn.BorderSizePixel = 0
    local state = false
    local function SetState(s)
        state = s
        if s then
            toggleBG.BackgroundColor3   = REDZ.Accent
            toggleKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            toggleKnob.Position         = UDim2.new(1, -17, 0.5, -7)
            row.BackgroundColor3        = Color3.fromRGB(24, 14, 18)
            stroke.Color                = REDZ.AccentDim
        else
            toggleBG.BackgroundColor3   = REDZ.ToggleOff
            toggleKnob.BackgroundColor3 = REDZ.TextSub
            toggleKnob.Position         = UDim2.new(0, 3, 0.5, -7)
            row.BackgroundColor3        = REDZ.BG2
            stroke.Color                = REDZ.Stroke
        end
    end
    togBtn.MouseButton1Click:Connect(function() SetState(not state) end)
    return row, function() return state end, SetState
end

local function MakeSliderRow(parent, label, displayMin, displayMax, initPct, unit, onChanged)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 66); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1
    local title = Instance.new("TextLabel", row)
    title.Size = UDim2.new(1, -80, 0, 20); title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1; title.Text = label
    title.TextColor3 = REDZ.TextMain; title.Font = Enum.Font.GothamBold; title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    local valLabel = Instance.new("TextLabel", row)
    valLabel.Size = UDim2.new(0, 70, 0, 20); valLabel.Position = UDim2.new(1, -78, 0, 8)
    valLabel.BackgroundTransparency = 1; valLabel.Font = Enum.Font.GothamBold; valLabel.TextSize = 12
    valLabel.TextColor3 = REDZ.AccentGlow; valLabel.TextXAlignment = Enum.TextXAlignment.Right
    local sliderBG = Instance.new("Frame", row)
    sliderBG.Size = UDim2.new(1, -28, 0, 5); sliderBG.Position = UDim2.new(0, 14, 0, 42)
    sliderBG.BackgroundColor3 = REDZ.SliderBG; sliderBG.BorderSizePixel = 0
    Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0, 3)
    local sliderHitbox = Instance.new("TextButton", sliderBG)
    sliderHitbox.Size = UDim2.new(1, 0, 0, 28); sliderHitbox.Position = UDim2.new(0, 0, 0.5, -14)
    sliderHitbox.BackgroundTransparency = 1; sliderHitbox.Text = ""
    sliderHitbox.BorderSizePixel = 0; sliderHitbox.ZIndex = 5
    local sliderFill = Instance.new("Frame", sliderBG)
    sliderFill.Size = UDim2.new(initPct, 0, 1, 0); sliderFill.BackgroundColor3 = REDZ.SliderFill
    sliderFill.BorderSizePixel = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 3)
    local fillGlow = Instance.new("Frame", sliderFill)
    fillGlow.Size = UDim2.new(0, 6, 0, 6); fillGlow.Position = UDim2.new(1, -3, 0.5, -3)
    fillGlow.BackgroundColor3 = REDZ.AccentGlow; fillGlow.BorderSizePixel = 0
    Instance.new("UICorner", fillGlow).CornerRadius = UDim.new(0, 3)
    local knob = Instance.new("Frame", sliderBG)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.Position = UDim2.new(initPct, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 7)
    local knobRing = Instance.new("UIStroke", knob)
    knobRing.Color = REDZ.Accent; knobRing.Thickness = 2
    local dragging = false
    local function Compute(px)
        local bg = sliderBG.AbsolutePosition.X; local bw = sliderBG.AbsoluteSize.X
        local pct = math.clamp((px - bg) / bw, 0, 1)
        return pct, math.floor(displayMin + (displayMax - displayMin) * pct)
    end
    local function Apply(pct, val)
        sliderFill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, -7, 0.5, -7)
        valLabel.Text = val .. (unit or "")
        if onChanged then onChanged(val, pct) end
    end
    Apply(initPct, math.floor(displayMin + (displayMax - displayMin) * initPct))
    sliderHitbox.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            local p, v = Compute(input.Position.X); Apply(p, v)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    sliderHitbox.MouseButton1Click:Connect(function()
        local mouse = UserInputService:GetMouseLocation()
        local p, v = Compute(mouse.X); Apply(p, v)
    end)
    return row
end

-- ── PAGES ─────────────────────────────────────────────────────────────────────
local combatPage = MakePage(); pages["combat"] = combatPage
local combatBtn  = MakeSidebarBtn("⚔", "Combat", "combat")

MakeSectionLabel(combatPage, "HITBOX")
local _, hbGet, _     = MakeToggleRow(combatPage, "Hitbox Expand", "Expand LocalRoot hitbox size")
MakeSliderRow(combatPage, "Hitbox Size", 1, 100, 0.0, "%", function(val)
    CONFIG.HitboxPercent = val
end)

MakeSectionLabel(combatPage, "COMBAT")
local _, hbSpamGet, _ = MakeToggleRow(combatPage, "Hitbox Spam", "Spawn hitbox parts at position")
local _, dashGet, _   = MakeToggleRow(combatPage, "Dash Spam",   "Hold Q — auto dash no delay")

MakeSectionLabel(combatPage, "SILENT AIM")
local _, silentGet, _ = MakeToggleRow(combatPage, "Silent Aim",
    "Kamera redirect ke target — semua jurus kena")

-- FOV slider: 30-300 pixel dari center
MakeSliderRow(combatPage, "Silent Aim FOV", 30, 300,
    (CONFIG.SilentAimFOV - 30) / 270,
    " px",
    function(val)
        CONFIG.SilentAimFOV = val
        fovCircle.Radius    = val
    end
)

MakeSectionLabel(combatPage, "FAST ATTACK")
local _, fastAtkGet, _ = MakeToggleRow(combatPage, "Fast Attack",
    "FireServer RegisterAttack tanpa delay animasi")

-- FIX: slider display = hits per second (1-30)
-- interval = 1/HPS — makin kanan makin cepet
MakeSliderRow(combatPage, "Attack HPS", 1, 30,
    (CONFIG.AttackHPS - 1) / 29,
    " HPS",
    function(val)
        CONFIG.AttackHPS = val
    end
)

local visualPage = MakePage(); pages["visual"] = visualPage
local visualBtn  = MakeSidebarBtn("👁", "Visual", "visual")
MakeSectionLabel(visualPage, "ESP")
local _, espGet, _    = MakeToggleRow(visualPage, "ESP",     "Player boxes, health, distance")
local _, tracerGet, _ = MakeToggleRow(visualPage, "Tracers", "Lines from screen to players")

local movePage    = MakePage(); pages["movement"] = movePage
local moveBtn     = MakeSidebarBtn("🏃", "Movement", "movement")
MakeSectionLabel(movePage, "SPEED")
local _, speedGet, _ = MakeToggleRow(movePage, "Fast Run", "Override WalkSpeed every frame")
MakeSliderRow(movePage, "Speed", BASE_SPEED, MAX_SPEED, 0.5, " ws", function(val, pct)
    CONFIG.SpeedPercent = pct * 100
end)

-- ── WIRE ─────────────────────────────────────────────────────────────────────
local function WireToggle(getter, configKey, onEnable, onDisable)
    RunService.Heartbeat:Connect(function()
        local s = getter()
        if CONFIG[configKey] ~= s then
            CONFIG[configKey] = s
            if s then if onEnable  then onEnable()  end
            else      if onDisable then onDisable()  end
            end
        end
    end)
end

WireToggle(hbGet,      "Mode1", nil, RestoreHitbox)
WireToggle(hbSpamGet,  "Mode2")
WireToggle(espGet,     "Mode3", nil, HideAllESP)
WireToggle(tracerGet,  "Mode4", nil, function()
    for _, esp in pairs(ESP_Objects) do esp.Line.Visible = false end
end)
WireToggle(speedGet,   "Mode5", nil, function()
    LocalHumanoid.WalkSpeed = BASE_SPEED
end)
WireToggle(dashGet,    "Mode6", StartDashLoop, StopDashLoop)
WireToggle(silentGet,  "Mode7", nil, function()
    silentTarget = nil
    fovCircle.Visible = false
end)
WireToggle(fastAtkGet, "Mode8", StartFastAttack, StopFastAttack)

combatBtn.MouseButton1Click:Connect(function() SetActivePage("combat")   end)
visualBtn.MouseButton1Click:Connect(function() SetActivePage("visual")   end)
moveBtn.MouseButton1Click:Connect(function()   SetActivePage("movement") end)
SetActivePage("combat")

local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
    contentVisible = not contentVisible
    sidebar.Visible = contentVisible; contentArea.Visible = contentVisible
    mainWindow.Size = contentVisible and UDim2.new(0, 580, 0, 400) or UDim2.new(0, 580, 0, 42)
end)

closeBtn.MouseButton1Click:Connect(function()
    RestoreHitbox(); LocalHumanoid.WalkSpeed = BASE_SPEED
    HideAllESP(); StopDashLoop(); StopFastAttack()
    fovCircle:Remove(); screenGui:Destroy()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot      = char:WaitForChild("HumanoidRootPart")
    LocalHumanoid  = char:WaitForChild("Humanoid")
    OriginalLocalSize = nil; dashHolding = false; silentTarget = nil
    if CONFIG.Mode5 then LocalHumanoid.WalkSpeed = GetTargetSpeed() end
end)

-- ── RENDER LOOP ───────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if CONFIG.Mode1 then ExpandHitbox() end
    if CONFIG.Mode2 and LocalRoot then Mode2Func(LocalRoot.Position) end
    if CONFIG.Mode5 then LocalHumanoid.WalkSpeed = GetTargetSpeed() end

    -- silent aim: redirect kamera tiap frame ke target terdekat dalam FOV
    if CONFIG.Mode7 then
        ApplySilentAim()
        -- tampilkan FOV circle di center screen
        local vp = Camera.ViewportSize
        fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
        fovCircle.Radius   = CONFIG.SilentAimFOV
        fovCircle.Visible  = true
    else
        fovCircle.Visible = false
    end

    RenderESP()
end)
