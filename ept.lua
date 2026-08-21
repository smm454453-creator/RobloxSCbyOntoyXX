local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

-- CONFIG STATE
local CONFIG = {
    FastRun      = false,
    RunSpeed     = 50,
    HighJump     = false,
    JumpPower    = 100,
    NoClip       = false,
    InfiniteJump = false,
    PlayerESP    = false,
    AutoCollect  = false,
    AutoBuy      = false,
}

-- 1. NOCLIP SYSTEM
RunService.Stepped:Connect(function()
    if CONFIG.NoClip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- 2. MOVEMENT & JUMP SYSTEM
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if CONFIG.FastRun then
            hum.WalkSpeed = CONFIG.RunSpeed
        end
        if CONFIG.HighJump then
            hum.UseJumpPower = true
            hum.JumpPower = CONFIG.JumpPower
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- 3. TYCOON AUTOMATION (Auto Collect & Auto Buy)
local function TouchPart(part)
    if part and LocalRoot then
        firetouchinterest(LocalRoot, part, 0)
        task.wait(0.01)
        firetouchinterest(LocalRoot, part, 1)
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if CONFIG.AutoCollect then
            pcall(function()
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("collector") or v.Name:lower():find("giver") or v.Name:lower():find("claim")) then
                        TouchPart(v)
                    end
                end
            end)
        end
        
        if CONFIG.AutoBuy then
            pcall(function()
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Name == "Head" or v.Name == "Button" or v:FindFirstChildOfClass("TouchTransmitter")) then
                        if v.Parent and v.Parent.Name:lower():find("button") then
                            TouchPart(v)
                        end
                    end
                end
            end)
        end
    end
end)

-- 4. PLAYER ESP SYSTEM (Drawing Library)
local playerESP = {}

local function NewText(size, color)
    local t = Drawing.new("Text")
    t.Size = size or 13; t.Center = true; t.Outline = true
    t.OutlineColor = Color3.fromRGB(0,0,0)
    t.Color = color or Color3.fromRGB(255,255,255)
    t.Visible = false; t.Font = Drawing.Fonts.Plex
    return t
end

local function NewBox(color)
    local b = Drawing.new("Square")
    b.Thickness = 1.5; b.Filled = false
    b.Color = color or Color3.fromRGB(0,220,255); b.Visible = false
    return b
end

local function CreatePlayerDraw()
    return {
        nameTag = NewText(13, Color3.fromRGB(0,220,255)),
        distTag = NewText(11, Color3.fromRGB(200,200,200)),
        box     = NewBox(Color3.fromRGB(0,220,255)),
    }
end

local function RemovePlayerDraw(d)
    d.nameTag:Remove(); d.distTag:Remove(); d.box:Remove()
end

local function HidePlayerDraw(d)
    d.nameTag.Visible = false; d.distTag.Visible = false; d.box.Visible = false
end

RunService.RenderStepped:Connect(function()
    for plr, d in pairs(playerESP) do
        if not plr or not plr.Parent then
            RemovePlayerDraw(d); playerESP[plr] = nil
        end
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not playerESP[plr] then
            playerESP[plr] = CreatePlayerDraw()
        end
    end
    
    for plr, d in pairs(playerESP) do
        if not CONFIG.PlayerESP or not plr.Character then HidePlayerDraw(d); continue end
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        if not root then HidePlayerDraw(d); continue end
        
        local sc, on = Camera:WorldToScreenPoint(root.Position)
        if not on then HidePlayerDraw(d); continue end
        
        local dist = math.floor((root.Position - LocalRoot.Position).Magnitude)
        local scale = math.clamp(1 - dist/500, 0.3, 1)
        local bh = math.clamp(math.floor(80*scale), 20, 80)
        local bw = math.floor(bh * 0.55)
        local bx = sc.X - bw/2; local by = sc.Y - bh/2
        
        d.box.Size = Vector2.new(bw,bh); d.box.Position = Vector2.new(bx,by); d.box.Visible = true
        d.nameTag.Text = plr.DisplayName
        d.nameTag.Position = Vector2.new(sc.X, by - 14); d.nameTag.Visible = true
        d.distTag.Text = dist.."m"
        d.distTag.Position = Vector2.new(sc.X, by + bh + 2); d.distTag.Visible = true
    end
end)

-- 5. GUI CONSTRUCTION (Ontoy Hub Style)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Ontoy_ElementalTycoon"; screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local REDZ = {
    BG         = Color3.fromRGB(14,12,16),
    BG2        = Color3.fromRGB(20,16,22),
    Accent     = Color3.fromRGB(200,30,50),
    AccentGlow = Color3.fromRGB(255,60,80),
    TextMain   = Color3.fromRGB(240,220,225),
    TextSub    = Color3.fromRGB(130,100,110),
    Stroke     = Color3.fromRGB(60,30,40),
    ToggleOff  = Color3.fromRGB(40,32,36),
    SliderFill = Color3.fromRGB(200,30,50),
    SliderBG   = Color3.fromRGB(35,28,32),
    Cyan       = Color3.fromRGB(0,200,255),
    Green      = Color3.fromRGB(50,200,80),
}

local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(0,500,0,420); mainWindow.Position = UDim2.new(0.5,-250,0.5,-210)
mainWindow.BackgroundColor3 = REDZ.BG; mainWindow.BorderSizePixel = 0
mainWindow.Active = true; mainWindow.Parent = screenGui
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0,10)
local mainStroke = Instance.new("UIStroke", mainWindow)
mainStroke.Color = REDZ.Stroke; mainStroke.Thickness = 1.5

-- Title Bar & Dragging
local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size = UDim2.new(1,0,0,42); titleBar.BackgroundColor3 = REDZ.BG2; titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local draggingWindow, dragStartMouse, dragStartPos = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = true; dragStartMouse = Vector2.new(i.Position.X, i.Position.Y)
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
titleText.Size = UDim2.new(1,-120,1,0); titleText.Position = UDim2.new(0,16,0,0)
titleText.BackgroundTransparency = 1
titleText.Text = "ONTOY HUB  <font color='#C81E32'>·</font>  Elemental Tycoon"
titleText.RichText = true; titleText.TextColor3 = REDZ.TextMain
titleText.Font = Enum.Font.GothamBold; titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left

-- Buttons (Minimize & Close)
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

-- Hide/Show Hotkey (Right Control)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        mainWindow.Visible = not mainWindow.Visible
    end
end)

-- Sidebar & Pages
local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size = UDim2.new(0,130,1,-42); sidebar.Position = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = REDZ.BG2; sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
local sl = Instance.new("UIListLayout", sidebar)
sl.Padding = UDim.new(0,4); sl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0,10)

local contentScroll = Instance.new("ScrollingFrame", mainWindow)
contentScroll.Size = UDim2.new(1,-138,1,-50); contentScroll.Position = UDim2.new(0,134,0,46)
contentScroll.BackgroundTransparency = 1; contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 3; contentScroll.CanvasSize = UDim2.new(0,0,0,0)
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
    btn.Size = UDim2.new(1,-12,0,36); btn.BackgroundTransparency = 1; btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    
    local txt = Instance.new("TextLabel", btn)
    txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1
    txt.Text = icon .. " " .. label; txt.TextColor3 = REDZ.TextSub
    txt.Font = Enum.Font.Gotham; txt.TextSize = 12
    sidebarButtons[id] = {btn=btn, txt=txt}
    return btn
end

local function SetActivePage(id)
    for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
    for bid, sb in pairs(sidebarButtons) do
        local a = (bid == id)
        sb.btn.BackgroundTransparency = a and 0 or 1
        sb.btn.BackgroundColor3 = a and Color3.fromRGB(30,18,22) or REDZ.ToggleOff
        sb.txt.TextColor3 = a and REDZ.TextMain or REDZ.TextSub
    end
end

-- UI Component Helpers
local function MakeToggle(parent, label, key)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,44); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
    
    local t = Instance.new("TextLabel", row)
    t.Size = UDim2.new(1,-50,1,0); t.Position = UDim2.new(0,12,0,0)
    t.BackgroundTransparency = 1; t.Text = label; t.TextColor3 = REDZ.TextMain
    t.Font = Enum.Font.GothamBold; t.TextSize = 11; t.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0,32,0,18); btn.Position = UDim2.new(1,-42,0.5,-9)
    btn.BackgroundColor3 = REDZ.ToggleOff; btn.Text = ""; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,9)
    
    btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        btn.BackgroundColor3 = CONFIG[key] and REDZ.Accent or REDZ.ToggleOff
    end)
end

local function MakeSlider(parent, label, minVal, maxVal, key)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,54); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
    
    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(1,-60,0,20); tl.Position = UDim2.new(0,12,0,6)
    tl.BackgroundTransparency = 1; tl.Text = label; tl.TextColor3 = REDZ.TextMain
    tl.Font = Enum.Font.GothamBold; tl.TextSize = 11; tl.TextXAlignment = Enum.TextXAlignment.Left
    
    local vl = Instance.new("TextLabel", row)
    vl.Size = UDim2.new(0,50,0,20); vl.Position = UDim2.new(1,-58,0,6)
    vl.BackgroundTransparency = 1; vl.Text = tostring(CONFIG[key])
    vl.TextColor3 = REDZ.AccentGlow; vl.Font = Enum.Font.GothamBold; vl.TextSize = 11
    
    local sbg = Instance.new("Frame", row)
    sbg.Size = UDim2.new(1,-24,0,4); sbg.Position = UDim2.new(0,12,0,36)
    sbg.BackgroundColor3 = REDZ.SliderBG; sbg.BorderSizePixel = 0
    
    local fill = Instance.new("Frame", sbg)
    fill.Size = UDim2.new((CONFIG[key]-minVal)/(maxVal-minVal),0,1,0); fill.BackgroundColor3 = REDZ.SliderFill
    
    local hit = Instance.new("TextButton", sbg)
    hit.Size = UDim2.new(1,0,0,20); hit.Position = UDim2.new(0,0,0.5,-10)
    hit.BackgroundTransparency = 1; hit.Text = ""
    
    local drag = false
    local function Apply(i)
        local pct = math.clamp((i.Position.X - sbg.AbsolutePosition.X)/sbg.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * pct)
        CONFIG[key] = val
        vl.Text = tostring(val)
        fill.Size = UDim2.new(pct, 0, 1, 0)
    end
    hit.MouseButton1Down:Connect(function() drag = true end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then Apply(i) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- PAGE BUILD
local movePage = MakePage(); pages["move"] = movePage
local moveBtn  = MakeSidebarBtn("🏃", "Movement", "move")
MakeToggle(movePage, "Fast Run", "FastRun")
MakeSlider(movePage, "WalkSpeed", 16, 250, "RunSpeed")
MakeToggle(movePage, "High Jump", "HighJump")
MakeSlider(movePage, "JumpPower", 50, 300, "JumpPower")
MakeToggle(movePage, "No Clip (Tembus Dinding)", "NoClip")
MakeToggle(movePage, "Infinite Jump", "InfiniteJump")

local visPage = MakePage(); pages["vis"] = visPage
local visBtn  = MakeSidebarBtn("👁", "Visuals", "vis")
MakeToggle(visPage, "Player ESP", "PlayerESP")

local utilPage = MakePage(); pages["util"] = utilPage
local utilBtn  = MakeSidebarBtn("⚡", "Tycoon Auto", "util")
MakeToggle(utilPage, "Auto Collect Cash", "AutoCollect")
MakeToggle(utilPage, "Auto Buy Buttons", "AutoBuy")

moveBtn.MouseButton1Click:Connect(function() SetActivePage("move") end)
visBtn.MouseButton1Click:Connect(function() SetActivePage("vis") end)
utilBtn.MouseButton1Click:Connect(function() SetActivePage("util") end)
SetActivePage("move")

-- Window Controls
local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
    contentVisible = not contentVisible
    sidebar.Visible = contentVisible
    contentScroll.Visible = contentVisible
    mainWindow.Size = contentVisible and UDim2.new(0,500,0,420) or UDim2.new(0,500,0,42)
end)

closeBtn.MouseButton1Click:Connect(function()
    for _, d in pairs(playerESP) do RemovePlayerDraw(d) end
    screenGui:Destroy()
end)
