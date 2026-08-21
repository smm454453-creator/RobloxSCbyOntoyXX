local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

local CONFIG = {
    FastRun      = false,
    RunSpeed     = 50,
    HighJump     = false,
    JumpPower    = 100,
    Fly          = false,
    FlySpeed     = 50,
    Noclip       = false,
    GunMods      = false,
    PlayerESP    = false,
    ItemESP      = false,
}

-- Target Teleport Locations (Prison Life)
local TELEPORTS = {
    ["Armory"]         = Vector3.new(789, 99, 2260),
    ["Yard"]           = Vector3.new(779, 98, 2458),
    ["Criminal Base"]  = Vector3.new(-943, 94, 2063),
    ["Police Station"] = Vector3.new(836, 99, 2270),
    ["Sewers"]         = Vector3.new(916, 78, 2387),
}

-- Movement Logic (WalkSpeed & JumpPower)
RunService.RenderStepped:Connect(function()
    if LocalHumanoid then
        if CONFIG.FastRun then
            LocalHumanoid.WalkSpeed = CONFIG.RunSpeed
        end
        if CONFIG.HighJump then
            LocalHumanoid.UseJumpPower = true
            LocalHumanoid.JumpPower = CONFIG.JumpPower
        end
    end
end)

-- Noclip Logic
RunService.Stepped:Connect(function()
    if CONFIG.Noclip and LocalCharacter then
        for _, part in ipairs(LocalCharacter:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Fly Logic
local flyBV, flyBG
RunService.RenderStepped:Connect(function()
    if CONFIG.Fly and LocalRoot then
        if not flyBV then
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyBV.Parent = LocalRoot
        end
        if not flyBG then
            flyBG = Instance.new("BodyGyro")
            flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyBG.P = 9e4
            flyBG.Parent = LocalRoot
        end
        
        flyBG.CFrame = Camera.CFrame
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        
        flyBV.Velocity = moveDir * CONFIG.FlySpeed
    else
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
    end
end)

-- Prison Life Gun Mods Logic
local function ApplyGunMods(tool)
    if not tool or not tool:IsA("Tool") then return end
    local gunStates = tool:FindFirstChild("GunStates")
    if gunStates and gunStates:IsA("ModuleScript") then
        local stats = require(gunStates)
        stats["Auto"] = true
        stats["FireRate"] = 0.01
        stats["MaxAmmo"] = 999999
        stats["CurrentAmmo"] = 999999
        stats["StoredAmmo"] = 999999
    end
end

RunService.Heartbeat:Connect(function()
    if CONFIG.GunMods then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do ApplyGunMods(item) end
        end
        if LocalCharacter then
            for _, item in ipairs(LocalCharacter:GetChildren()) do ApplyGunMods(item) end
        end
    end
end)

-- Drawing ESP Functions
local function NewText(size, color)
    local t = Drawing.new("Text")
    t.Size = size or 13; t.Center = true; t.Outline = true
    t.OutlineColor = Color3.fromRGB(0,0,0)
    t.Color = color or Color3.fromRGB(255,255,255)
    t.Visible = false; t.Font = Drawing.Fonts.Plex
    return t
end

local function NewBox(color, thick)
    local b = Drawing.new("Square")
    b.Thickness = thick or 1.5; b.Filled = false
    b.Color = color or Color3.fromRGB(255,255,255); b.Visible = false
    return b
end

local playerESP = {}
local function GetTeamColor(plr)
    if plr.Team then
        if plr.Team.Name == "Guards" then return Color3.fromRGB(0, 120, 255) end
        if plr.Team.Name == "Inmates" then return Color3.fromRGB(255, 140, 0) end
        if plr.Team.Name == "Criminals" then return Color3.fromRGB(255, 40, 40) end
    end
    return Color3.fromRGB(200, 200, 200)
end

RunService.RenderStepped:Connect(function()
    if not CONFIG.PlayerESP then
        for _, d in pairs(playerESP) do
            d.box.Visible = false; d.nameTag.Visible = false
        end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if not playerESP[plr] then
                playerESP[plr] = { box = NewBox(), nameTag = NewText(12) }
            end
            local d = playerESP[plr]
            local root = plr.Character.HumanoidRootPart
            local sc, on = Camera:WorldToScreenPoint(root.Position)

            if on then
                local dist = math.floor((root.Position - LocalRoot.Position).Magnitude)
                local scale = math.clamp(1 - dist/500, 0.3, 1)
                local bh = math.clamp(math.floor(80 * scale), 20, 80)
                local bw = math.floor(bh * 0.55)
                local teamCol = GetTeamColor(plr)

                d.box.Color = teamCol
                d.box.Size = Vector2.new(bw, bh)
                d.box.Position = Vector2.new(sc.X - bw/2, sc.Y - bh/2)
                d.box.Visible = true

                d.nameTag.Text = plr.DisplayName .. " [" .. (plr.Team and plr.Team.Name or "None") .. "]"
                d.nameTag.Color = teamCol
                d.nameTag.Position = Vector2.new(sc.X, sc.Y - bh/2 - 14)
                d.nameTag.Visible = true
            else
                d.box.Visible = false; d.nameTag.Visible = false
            end
        end
    end
end)

-- UI Setup (Ontoy Hub Engine)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Ontoy_PrisonLife"; screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local REDZ = {
    BG         = Color3.fromRGB(14,12,16),
    BG2        = Color3.fromRGB(20,16,22),
    Accent     = Color3.fromRGB(200,30,50),
    AccentDim  = Color3.fromRGB(120,20,35),
    AccentGlow = Color3.fromRGB(255,60,80),
    TextMain   = Color3.fromRGB(240,220,225),
    TextSub    = Color3.fromRGB(130,100,110),
    Stroke     = Color3.fromRGB(60,30,40),
    ToggleOff  = Color3.fromRGB(40,32,36),
    SliderFill = Color3.fromRGB(200,30,50),
    SliderBG   = Color3.fromRGB(35,28,32),
}

local mainWindow = Instance.new("Frame", screenGui)
mainWindow.Size = UDim2.new(0,520,0,440); mainWindow.Position = UDim2.new(0.5,-260,0.5,-220)
mainWindow.BackgroundColor3 = REDZ.BG; mainWindow.BorderSizePixel = 0; mainWindow.Active = true
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", mainWindow).Color = REDZ.Stroke

local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size = UDim2.new(1,0,0,42); titleBar.BackgroundColor3 = REDZ.BG2; titleBar.Active = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1,-100,1,0); titleText.Position = UDim2.new(0,15,0,0)
titleText.BackgroundTransparency = 1; titleText.Text = "ONTOY HUB <font color='#C81E32'>·</font> Prison Life"
titleText.RichText = true; titleText.TextColor3 = REDZ.TextMain; titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13; titleText.TextXAlignment = Enum.TextXAlignment.Left

local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size = UDim2.new(0,138,1,-42); sidebar.Position = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = REDZ.BG2; Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
local sl = Instance.new("UIListLayout", sidebar)
sl.Padding = UDim.new(0,3); sl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0,12)

local contentScroll = Instance.new("ScrollingFrame", mainWindow)
contentScroll.Size = UDim2.new(1,-146,1,-50); contentScroll.Position = UDim2.new(0,142,0,46)
contentScroll.BackgroundTransparency = 1; contentScroll.ScrollBarThickness = 3
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local cl = Instance.new("UIListLayout", contentScroll)
cl.Padding = UDim.new(0,6); cl.HorizontalAlignment = Enum.HorizontalAlignment.Center

local pages, sidebarButtons = {}, {}

local function MakePage()
    local pg = Instance.new("Frame", contentScroll)
    pg.Size = UDim2.new(1,0,0,0); pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1; pg.Visible = false
    local lay = Instance.new("UIListLayout", pg)
    lay.Padding = UDim.new(0,6); lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    return pg
end

local function MakeSidebarBtn(icon, label, id)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1,-14,0,38); btn.BackgroundTransparency = 1; btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    local labelL = Instance.new("TextLabel", btn)
    labelL.Size = UDim2.new(1,0,1,0); labelL.BackgroundTransparency = 1
    labelL.Text = icon .. " " .. label; labelL.TextColor3 = REDZ.TextSub
    labelL.Font = Enum.Font.Gotham; labelL.TextSize = 12
    sidebarButtons[id] = {btn = btn, label = labelL}
    return btn
end

local function SetActivePage(id)
    for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
    for bid, sb in pairs(sidebarButtons) do
        local a = (bid == id)
        sb.btn.BackgroundTransparency = a and 0 or 1
        sb.btn.BackgroundColor3 = a and Color3.fromRGB(30,18,22) or REDZ.ToggleOff
        sb.label.TextColor3 = a and REDZ.TextMain or REDZ.TextSub
    end
end

local function MakeToggle(parent, label, sub, onChange)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,46); row.BackgroundColor3 = REDZ.BG2
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local t = Instance.new("TextLabel", row)
    t.Size = UDim2.new(1,-60,1,0); t.Position = UDim2.new(0,12,0,0)
    t.BackgroundTransparency = 1; t.Text = label; t.TextColor3 = REDZ.TextMain
    t.Font = Enum.Font.GothamBold; t.TextSize = 12; t.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0,36,0,20); btn.Position = UDim2.new(1,-44,0.5,-10)
    btn.BackgroundColor3 = REDZ.ToggleOff; btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and REDZ.Accent or REDZ.ToggleOff
        if onChange then onChange(state) end
    end)
end

local function MakeSlider(parent, label, minVal, maxVal, defaultVal, onChange)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,54); row.BackgroundColor3 = REDZ.BG2
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(1,-80,0,20); tl.Position = UDim2.new(0,12,0,6)
    tl.BackgroundTransparency = 1; tl.Text = label; tl.TextColor3 = REDZ.TextMain
    tl.Font = Enum.Font.GothamBold; tl.TextSize = 12; tl.TextXAlignment = Enum.TextXAlignment.Left
    local vl = Instance.new("TextLabel", row)
    vl.Size = UDim2.new(0,70,0,20); vl.Position = UDim2.new(1,-78,0,6)
    vl.BackgroundTransparency = 1; vl.Text = tostring(defaultVal); vl.TextColor3 = REDZ.AccentGlow
    vl.Font = Enum.Font.GothamBold; vl.TextSize = 12; vl.TextXAlignment = Enum.TextXAlignment.Right
    
    local hit = Instance.new("TextButton", row)
    hit.Size = UDim2.new(1,-24,0,16); hit.Position = UDim2.new(0,12,0,30)
    hit.BackgroundColor3 = REDZ.SliderBG; hit.Text = ""
    Instance.new("UICorner", hit).CornerRadius = UDim.new(0,4)
    
    local fill = Instance.new("Frame", hit)
    fill.Size = UDim2.new((defaultVal - minVal)/(maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = REDZ.SliderFill; Instance.new("UICorner", fill).CornerRadius = UDim.new(0,4)

    local dragging = false
    local function Update(input)
        local pct = math.clamp((input.Position.X - hit.AbsolutePosition.X) / hit.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * pct)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        vl.Text = tostring(val)
        if onChange then onChange(val) end
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; Update(i) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then Update(i) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

local function MakeActionBtn(parent, label, onClick)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,40); row.BackgroundColor3 = REDZ.BG2
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1
    btn.Text = label; btn.TextColor3 = REDZ.TextMain; btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
end

-- Pages Initialization
local movePage = MakePage(); pages["move"] = movePage
local moveBtn = MakeSidebarBtn("🏃", "Movement", "move")
MakeToggle(movePage, "Fast Run", "", function(s) CONFIG.FastRun = s end)
MakeSlider(movePage, "Run Speed", 16, 250, 50, function(v) CONFIG.RunSpeed = v end)
MakeToggle(movePage, "High Jump", "", function(s) CONFIG.HighJump = s end)
MakeSlider(movePage, "Jump Power", 50, 300, 100, function(v) CONFIG.JumpPower = v end)
MakeToggle(movePage, "Fly", "", function(s) CONFIG.Fly = s end)
MakeSlider(movePage, "Fly Speed", 20, 200, 50, function(v) CONFIG.FlySpeed = v end)
MakeToggle(movePage, "Noclip", "", function(s) CONFIG.Noclip = s end)

local combatPage = MakePage(); pages["combat"] = combatPage
local combatBtn = MakeSidebarBtn("🔫", "Combat", "combat")
MakeToggle(combatPage, "Gun Mods (Auto/Ammo/Rate)", "", function(s) CONFIG.GunMods = s end)

local visualPage = MakePage(); pages["visual"] = visualPage
local visualBtn = MakeSidebarBtn("👁", "Visuals", "visual")
MakeToggle(visualPage, "Player ESP", "", function(s) CONFIG.PlayerESP = s end)

local tpPage = MakePage(); pages["tp"] = tpPage
local tpBtn = MakeSidebarBtn("⚡", "Teleports", "tp")
for name, pos in pairs(TELEPORTS) do
    MakeActionBtn(tpPage, "TP to " .. name, function()
        if LocalRoot then LocalRoot.CFrame = CFrame.new(pos) end
    end)
end

-- Sidebar Navigation Connections
moveBtn.MouseButton1Click:Connect(function() SetActivePage("move") end)
combatBtn.MouseButton1Click:Connect(function() SetActivePage("combat") end)
visualBtn.MouseButton1Click:Connect(function() SetActivePage("visual") end)
tpBtn.MouseButton1Click:Connect(function() SetActivePage("tp") end)
SetActivePage("move")

-- Character Auto-Refresh Listener
LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot = char:WaitForChild("HumanoidRootPart")
    LocalHumanoid = char:WaitForChild("Humanoid")
end)
