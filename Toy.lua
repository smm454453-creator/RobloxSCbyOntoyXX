local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

local CONFIG = {
    Mode1 = false,
    Mode2 = false,
    Mode3 = false,
    Mode4 = false,
    Mode5 = false,
    Mode6 = false,
    HitboxSize = 4,
    HitboxPercent = 1,
    SpeedPercent = 50,
    Radius = 15,
}

local BASE_SPEED = 16
local MAX_SPEED = 500
local MIN_HITBOX = 4
local MAX_HITBOX = 60
local DASH_INTERVAL = 0.05

local OriginalLocalSize = nil
local ESP_Objects = {}
local lastDashTime = 0
local dashHolding = false

local function ExpandHitbox()
    if not OriginalLocalSize then
        OriginalLocalSize = LocalRoot.Size
    end
    LocalRoot.Size = Vector3.new(CONFIG.HitboxSize, CONFIG.HitboxSize, CONFIG.HitboxSize)
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

local function Mode2Func(centerPosition)
    local hitboxPart = Instance.new("Part")
    hitboxPart.Name = "Ontoy_Part"
    hitboxPart.Size = Vector3.new(CONFIG.Radius * 2, 10, CONFIG.Radius * 2)
    hitboxPart.Position = centerPosition
    hitboxPart.Anchored = true
    hitboxPart.CanCollide = false
    hitboxPart.Transparency = 1
    hitboxPart.Parent = Workspace
    game:GetService("Debris"):AddItem(hitboxPart, 0.1)
end

local function CreateESP(player)
    local esp = {
        Box = Drawing.new("Square"),
        Line = Drawing.new("Line"),
        NameTag = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
    }
    esp.Box.Thickness = 1
    esp.Box.Color = Color3.fromRGB(255, 50, 50)
    esp.Box.Filled = false
    esp.Box.Visible = false
    esp.Line.Thickness = 1
    esp.Line.Color = Color3.fromRGB(0, 255, 255)
    esp.Line.Visible = false
    esp.NameTag.Size = 13
    esp.NameTag.Color = Color3.fromRGB(255, 255, 255)
    esp.NameTag.Center = true
    esp.NameTag.Outline = true
    esp.NameTag.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.NameTag.Visible = false
    esp.HealthBar.Thickness = 1
    esp.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.Filled = true
    esp.HealthBar.Visible = false
    return esp
end

local function CleanupESP(player)
    local esp = ESP_Objects[player]
    if esp then
        esp.Box:Remove()
        esp.Line:Remove()
        esp.NameTag:Remove()
        esp.HealthBar:Remove()
        ESP_Objects[player] = nil
    end
end

local function HideESP(esp)
    esp.Box.Visible = false
    esp.NameTag.Visible = false
    esp.Line.Visible = false
    esp.HealthBar.Visible = false
end

local function HideAllESP()
    for _, esp in pairs(ESP_Objects) do
        HideESP(esp)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        ESP_Objects[player] = CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    ESP_Objects[player] = CreateESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    CleanupESP(player)
end)

local function RenderESP()
    if not CONFIG.Mode3 then HideAllESP() return end
    for player, esp in pairs(ESP_Objects) do
        local character = player.Character
        if not character then HideESP(esp) continue end
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        if not (root and humanoid and head and humanoid.Health > 0) then HideESP(esp) continue end
        local rootScreen, onScreen = Camera:WorldToScreenPoint(root.Position)
        local headScreen = Camera:WorldToScreenPoint(head.Position)
        if not onScreen then HideESP(esp) continue end
        local height = math.abs(rootScreen.Y - headScreen.Y) * 2
        if height < 10 then height = 10 end
        local width = height * 0.5
        local boxPos = Vector2.new(rootScreen.X - width / 2, rootScreen.Y - height / 2)
        esp.Box.Color = Color3.fromRGB(255, 50, 50)
        esp.Box.Thickness = 1
        esp.Box.Size = Vector2.new(width, height)
        esp.Box.Position = boxPos
        esp.Box.Visible = true
        local hpRatio = humanoid.Health / humanoid.MaxHealth
        local barHeight = height * hpRatio
        esp.HealthBar.Size = Vector2.new(4, barHeight)
        esp.HealthBar.Position = Vector2.new(boxPos.X - 7, boxPos.Y + (height - barHeight))
        esp.HealthBar.Color = Color3.fromRGB(math.floor(255*(1-hpRatio)), math.floor(255*hpRatio), 0)
        esp.HealthBar.Visible = true
        local dist = math.floor((root.Position - LocalRoot.Position).Magnitude)
        esp.NameTag.Text = player.Name .. " [" .. math.floor(humanoid.Health) .. "hp | " .. dist .. "m]"
        esp.NameTag.Position = Vector2.new(rootScreen.X, boxPos.Y - 16)
        esp.NameTag.Visible = true
        if CONFIG.Mode4 then
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            esp.Line.From = screenCenter
            esp.Line.To = Vector2.new(rootScreen.X, rootScreen.Y)
            esp.Line.Color = Color3.fromRGB(0, 255, 255)
            esp.Line.Visible = true
        else
            esp.Line.Visible = false
        end
    end
end

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Ontoy_Hub"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main window
local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(0, 560, 0, 380)
mainWindow.Position = UDim2.new(0.5, -280, 0.5, -190)
mainWindow.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainWindow.BorderSizePixel = 0
mainWindow.Active = true
mainWindow.Draggable = true
mainWindow.Parent = screenGui
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", mainWindow)
mainStroke.Color = Color3.fromRGB(55, 55, 75)
mainStroke.Thickness = 1

-- Title bar
local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.Position = UDim2.new(0, 16, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Ontoy Hub  ·  Blox Fruits"
titleText.TextColor3 = Color3.fromRGB(230, 230, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left

local byLabel = Instance.new("TextLabel", titleBar)
byLabel.Size = UDim2.new(0, 120, 1, 0)
byLabel.Position = UDim2.new(0, 200, 0, 0)
byLabel.BackgroundTransparency = 1
byLabel.Text = "by ontoy"
byLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
byLabel.Font = Enum.Font.Gotham
byLabel.TextSize = 11
byLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local minimizeBtn = Instance.new("TextButton", titleBar)
minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
minimizeBtn.Position = UDim2.new(1, -70, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(200,200,220)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 11
minimizeBtn.BorderSizePixel = 0
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

-- Sidebar
local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size = UDim2.new(0, 150, 1, -40)
sidebar.Position = UDim2.new(0, 0, 0, 40)
sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

local sidebarLayout = Instance.new("UIListLayout", sidebar)
sidebarLayout.Padding = UDim.new(0, 2)
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 10)

-- Content area
local contentArea = Instance.new("Frame", mainWindow)
contentArea.Size = UDim2.new(1, -158, 1, -48)
contentArea.Position = UDim2.new(0, 154, 0, 44)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0

local contentScroll = Instance.new("ScrollingFrame", contentArea)
contentScroll.Size = UDim2.new(1, 0, 1, 0)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 3
contentScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local contentLayout = Instance.new("UIListLayout", contentScroll)
contentLayout.Padding = UDim.new(0, 6)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentScroll).PaddingTop = UDim.new(0, 8)

-- Pages
local pages = {}
local currentPage = nil
local sidebarButtons = {}

local function MakeSidebarBtn(icon, label, id)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -16, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local iconL = Instance.new("TextLabel", btn)
    iconL.Size = UDim2.new(0, 22, 1, 0)
    iconL.Position = UDim2.new(0, 8, 0, 0)
    iconL.BackgroundTransparency = 1
    iconL.Text = icon
    iconL.TextColor3 = Color3.fromRGB(140, 140, 180)
    iconL.Font = Enum.Font.GothamBold
    iconL.TextSize = 14

    local labelL = Instance.new("TextLabel", btn)
    labelL.Size = UDim2.new(1, -36, 1, 0)
    labelL.Position = UDim2.new(0, 34, 0, 0)
    labelL.BackgroundTransparency = 1
    labelL.Text = label
    labelL.TextColor3 = Color3.fromRGB(160, 160, 200)
    labelL.Font = Enum.Font.Gotham
    labelL.TextSize = 12
    labelL.TextXAlignment = Enum.TextXAlignment.Left

    sidebarButtons[id] = {btn = btn, icon = iconL, label = labelL}
    return btn
end

local function SetActivePage(id)
    for pid, pg in pairs(pages) do
        pg.Visible = (pid == id)
    end
    for bid, sb in pairs(sidebarButtons) do
        if bid == id then
            sb.btn.BackgroundTransparency = 0
            sb.btn.BackgroundColor3 = Color3.fromRGB(38, 38, 58)
            sb.icon.TextColor3 = Color3.fromRGB(120, 180, 255)
            sb.label.TextColor3 = Color3.fromRGB(220, 220, 255)
        else
            sb.btn.BackgroundTransparency = 1
            sb.icon.TextColor3 = Color3.fromRGB(140, 140, 180)
            sb.label.TextColor3 = Color3.fromRGB(160, 160, 200)
        end
    end
    currentPage = id
end

local function MakePage()
    local pg = Instance.new("Frame", contentScroll)
    pg.Size = UDim2.new(1, 0, 0, 0)
    pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1
    pg.BorderSizePixel = 0
    pg.Visible = false
    local layout = Instance.new("UIListLayout", pg)
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Instance.new("UIPadding", pg).PaddingBottom = UDim.new(0, 8)
    return pg
end

local function MakeSectionLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, -8, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(100, 100, 140)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local function MakeToggleRow(parent, label, sublabel)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 52)
    row.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", row)
    stroke.Color = Color3.fromRGB(45, 45, 65)
    stroke.Thickness = 1

    local title = Instance.new("TextLabel", row)
    title.Size = UDim2.new(1, -60, 0, 22)
    title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = label
    title.TextColor3 = Color3.fromRGB(220, 220, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left

    if sublabel then
        local sub = Instance.new("TextLabel", row)
        sub.Size = UDim2.new(1, -60, 0, 16)
        sub.Position = UDim2.new(0, 14, 0, 28)
        sub.BackgroundTransparency = 1
        sub.Text = sublabel
        sub.TextColor3 = Color3.fromRGB(100, 100, 140)
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
    end

    -- Toggle switch
    local toggleBG = Instance.new("Frame", row)
    toggleBG.Size = UDim2.new(0, 36, 0, 20)
    toggleBG.Position = UDim2.new(1, -48, 0.5, -10)
    toggleBG.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    toggleBG.BorderSizePixel = 0
    Instance.new("UICorner", toggleBG).CornerRadius = UDim.new(0, 10)

    local toggleKnob = Instance.new("Frame", toggleBG)
    toggleKnob.Size = UDim2.new(0, 14, 0, 14)
    toggleKnob.Position = UDim2.new(0, 3, 0.5, -7)
    toggleKnob.BackgroundColor3 = Color3.fromRGB(150, 150, 180)
    toggleKnob.BorderSizePixel = 0
    Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(0, 7)

    local togBtn = Instance.new("TextButton", row)
    togBtn.Size = UDim2.new(1, 0, 1, 0)
    togBtn.BackgroundTransparency = 1
    togBtn.Text = ""
    togBtn.BorderSizePixel = 0

    local state = false
    local function SetState(s)
        state = s
        if s then
            toggleBG.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
            toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            toggleKnob.Position = UDim2.new(1, -17, 0.5, -7)
            row.BackgroundColor3 = Color3.fromRGB(28, 32, 48)
            stroke.Color = Color3.fromRGB(60, 100, 200)
        else
            toggleBG.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            toggleKnob.BackgroundColor3 = Color3.fromRGB(150, 150, 180)
            toggleKnob.Position = UDim2.new(0, 3, 0.5, -7)
            row.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
            stroke.Color = Color3.fromRGB(45, 45, 65)
        end
    end

    togBtn.MouseButton1Click:Connect(function()
        SetState(not state)
    end)

    return row, togBtn, function() return state end, SetState
end

local function MakeSliderRow(parent, label, minVal, maxVal, initPct, unit)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 62)
    row.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", row)
    stroke.Color = Color3.fromRGB(45, 45, 65)
    stroke.Thickness = 1

    local valLabel = Instance.new("TextLabel", row)
    valLabel.Size = UDim2.new(0, 60, 0, 20)
    valLabel.Position = UDim2.new(1, -68, 0, 8)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 12
    valLabel.TextColor3 = Color3.fromRGB(120, 180, 255)
    valLabel.TextXAlignment = Enum.TextXAlignment.Right

    local title = Instance.new("TextLabel", row)
    title.Size = UDim2.new(1, -80, 0, 20)
    title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = label
    title.TextColor3 = Color3.fromRGB(220, 220, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left

    local sliderBG = Instance.new("Frame", row)
    sliderBG.Size = UDim2.new(1, -28, 0, 6)
    sliderBG.Position = UDim2.new(0, 14, 0, 38)
    sliderBG.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
    sliderBG.BorderSizePixel = 0
    Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0, 3)

    local sliderFill = Instance.new("Frame", sliderBG)
    sliderFill.Size = UDim2.new(initPct, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
    sliderFill.BorderSizePixel = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 3)

    local knob = Instance.new("Frame", sliderBG)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(initPct, -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 6)

    local currentPct = initPct
    local dragging = false

    local function UpdateSlider(px)
        local bg = sliderBG.AbsolutePosition.X
        local bw = sliderBG.AbsoluteSize.X
        local pct = math.clamp((px - bg) / bw, 0, 1)
        currentPct = pct
        sliderFill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -6, 0.5, -6)
        local val = math.floor(minVal + (maxVal - minVal) * pct)
        valLabel.Text = val .. (unit or "")
        return val
    end

    valLabel.Text = math.floor(minVal + (maxVal - minVal) * initPct) .. (unit or "")

    local dragConn
    sliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateSlider(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return row, UpdateSlider, function() return currentPct end
end

-- Build pages
-- Combat page
local combatPage = MakePage()
pages["combat"] = combatPage
local combatBtn = MakeSidebarBtn("⚔", "Combat", "combat")

MakeSectionLabel(combatPage, "HITBOX")
local hbRow, hbTogBtn, hbGetState, hbSetState = MakeToggleRow(combatPage, "Hitbox Expand", "Expand LocalRoot hitbox size")
local hbSliderRow, hbSliderUpdate = MakeSliderRow(combatPage, "Hitbox Size", MIN_HITBOX, MAX_HITBOX, 0.01, " sz")

MakeSectionLabel(combatPage, "COMBAT")
local hbSpamRow, hbSpamBtn, hbSpamGet, hbSpamSet = MakeToggleRow(combatPage, "Hitbox Spam", "Spawn hitbox parts at position")
local dashRow, dashBtn, dashGet, dashSet = MakeToggleRow(combatPage, "Dash Spam", "Hold Q to spam dash no delay")

-- Visual page
local visualPage = MakePage()
pages["visual"] = visualPage
local visualBtn = MakeSidebarBtn("👁", "Visual", "visual")

MakeSectionLabel(visualPage, "ESP")
local espRow, espTogBtn, espGet, espSet = MakeToggleRow(visualPage, "ESP", "Player boxes, health, distance")
local tracerRow, tracerTogBtn, tracerGet, tracerSet = MakeToggleRow(visualPage, "Tracers", "Lines from screen to players")

-- Movement page
local movePage = MakePage()
pages["movement"] = movePage
local moveBtn = MakeSidebarBtn("🏃", "Movement", "movement")

MakeSectionLabel(movePage, "SPEED")
local speedRow, speedTogBtn, speedGet, speedSet = MakeToggleRow(movePage, "Fast Run", "Override WalkSpeed every frame")
local speedSliderRow, speedSliderUpdate = MakeSliderRow(movePage, "Speed", BASE_SPEED, MAX_SPEED, 0.5, " ws")

-- Wire toggles
hbTogBtn.MouseButton1Click:Connect(function()
    CONFIG.Mode1 = hbGetState()
    if not CONFIG.Mode1 then RestoreHitbox() end
end)

hbSliderUpdate = (function()
    local _, fn = MakeSliderRow(combatPage, "", MIN_HITBOX, MAX_HITBOX, 0.01, "")
    return fn
end)

-- Rewire hitbox slider properly via InputChanged on sliderBG
-- Already wired in MakeSliderRow — patch CONFIG on every drag
local _hbPatchConn
local hbSliderBG = hbSliderRow:FindFirstChildWhichIsA("Frame")

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local val = math.floor(MIN_HITBOX + (MAX_HITBOX - MIN_HITBOX) * (function()
            if not hbSliderRow then return 0.01 end
            local bg = hbSliderRow:FindFirstChild("Frame")
            if not bg then return 0.01 end
            local bw = bg.AbsoluteSize.X
            if bw == 0 then return 0.01 end
            return math.clamp((input.Position.X - bg.AbsolutePosition.X) / bw, 0, 1)
        end)())
        -- Only update if slider is being dragged — handled inside MakeSliderRow
    end
end)

hbSpamBtn.MouseButton1Click:Connect(function()
    CONFIG.Mode2 = hbSpamGet()
end)

dashBtn.MouseButton1Click:Connect(function()
    CONFIG.Mode6 = dashGet()
end)

espTogBtn.MouseButton1Click:Connect(function()
    CONFIG.Mode3 = espGet()
    if not CONFIG.Mode3 then HideAllESP() end
end)

tracerTogBtn.MouseButton1Click:Connect(function()
    CONFIG.Mode4 = tracerGet()
    if not CONFIG.Mode4 then
        for _, esp in pairs(ESP_Objects) do esp.Line.Visible = false end
    end
end)

speedTogBtn.MouseButton1Click:Connect(function()
    CONFIG.Mode5 = speedGet()
    if not CONFIG.Mode5 then LocalHumanoid.WalkSpeed = BASE_SPEED end
end)

-- Sidebar navigation
combatBtn.MouseButton1Click:Connect(function() SetActivePage("combat") end)
visualBtn.MouseButton1Click:Connect(function() SetActivePage("visual") end)
moveBtn.MouseButton1Click:Connect(function() SetActivePage("movement") end)

SetActivePage("combat")

-- Minimize / close
local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
    contentVisible = not contentVisible
    sidebar.Visible = contentVisible
    contentArea.Visible = contentVisible
    mainWindow.Size = contentVisible and UDim2.new(0, 560, 0, 380) or UDim2.new(0, 560, 0, 40)
end)

closeBtn.MouseButton1Click:Connect(function()
    RestoreHitbox()
    LocalHumanoid.WalkSpeed = BASE_SPEED
    HideAllESP()
    screenGui:Destroy()
end)

-- Q hold detection for dash
UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.Q and CONFIG.Mode6 then
        dashHolding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then
        dashHolding = false
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot = char:WaitForChild("HumanoidRootPart")
    LocalHumanoid = char:WaitForChild("Humanoid")
    OriginalLocalSize = nil
    dashHolding = false
    if CONFIG.Mode5 then LocalHumanoid.WalkSpeed = GetTargetSpeed() end
end)

-- Patch slider CONFIG updates via RenderStepped read
-- Sliders update their own internal state; read them each frame for CONFIG sync
local function GetSliderPct(sliderRowFrame)
    local bg = sliderRowFrame:FindFirstChildWhichIsA("Frame")
    if not bg then return 0 end
    local fill = bg:FindFirstChildWhichIsA("Frame")
    if not fill then return 0 end
    return fill.Size.X.Scale
end

RunService.RenderStepped:Connect(function()
    -- Sync slider values to CONFIG each frame
    local hbPct = GetSliderPct(hbSliderRow)
    CONFIG.HitboxSize = MIN_HITBOX + (MAX_HITBOX - MIN_HITBOX) * hbPct

    local spPct = GetSliderPct(speedSliderRow)
    CONFIG.SpeedPercent = spPct * 100

    if CONFIG.Mode1 then ExpandHitbox() end
    if CONFIG.Mode2 and LocalRoot then Mode2Func(LocalRoot.Position) end
    if CONFIG.Mode5 then LocalHumanoid.WalkSpeed = GetTargetSpeed() end

    if CONFIG.Mode6 and dashHolding then
        local now = tick()
        if now - lastDashTime >= DASH_INTERVAL then
            lastDashTime = now
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, nil)
            task.delay(0.02, function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, nil)
            end)
        end
    end

    RenderESP()
end)
