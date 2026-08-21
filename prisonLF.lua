-- ONTOY HUB — Prison Life | Full Rewrite
-- Executor: Synapse X / KRNL / Fluxus
-- Game: Prison Life (Roblox)

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace      = game:GetService("Workspace")
local Camera         = Workspace.CurrentCamera

local LocalPlayer   = Players.LocalPlayer
local LocalCharacter, LocalRoot, LocalHumanoid

local function RefreshChar(char)
    LocalCharacter = char
    LocalRoot      = char:WaitForChild("HumanoidRootPart")
    LocalHumanoid  = char:WaitForChild("Humanoid")
end

if LocalPlayer.Character then RefreshChar(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(RefreshChar)

-- ─── CONFIG ──────────────────────────────────────────────────────────────────
local CFG = {
    FastRun    = false, RunSpeed   = 50,
    HighJump   = false, JumpPower  = 100,
    Fly        = false, FlySpeed   = 50,
    Noclip     = false,
    CarSpeed   = false, CarSpeedVal = 100,
    CarFly     = false,
    GunMods    = false,
    NoRecoil   = false,
    NoSpread   = false,
    InfAmmo    = false,
    SilentAim  = false,
    PlayerESP  = false,
    ItemESP    = false,
}

-- ─── TELEPORTS ───────────────────────────────────────────────────────────────
local TELEPORTS = {
    ["Armory"]         = Vector3.new(789,  99, 2260),
    ["Yard"]           = Vector3.new(779,  98, 2458),
    ["Criminal Base"]  = Vector3.new(-943, 94, 2063),
    ["Police Station"] = Vector3.new(836,  99, 2270),
    ["Sewers"]         = Vector3.new(916,  78, 2387),
}

-- ─── SILENT AIM — TARGET ─────────────────────────────────────────────────────
local function GetClosestTarget()
    local best, bestDist = nil, 250
    local mpos = UserInputService:GetMouseLocation()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local sc, onScreen = Camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(sc.X, sc.Y) - mpos).Magnitude
                    if d < bestDist then bestDist = d; best = head end
                end
            end
        end
    end
    return best
end

-- ─── NAMECALL HOOK — SilentAim / NoRecoil / NoSpread ─────────────────────────
local rawNamecall
rawNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args   = {...}
    local method = getnamecallmethod()

    if method == "FireServer" then
        local name = tostring(self.Name or "")

        -- Silent Aim + No Recoil + No Spread on shoot events
        if (name == "ShootEvent" or name == "RemoteEvent") then
            local bulletTable = args[1]
            if type(bulletTable) == "table" then
                local target = CFG.SilentAim and GetClosestTarget()
                for _, bullet in ipairs(bulletTable) do
                    if type(bullet) == "table" then
                        -- Silent Aim
                        if target and CFG.SilentAim then
                            bullet.Part   = target
                            bullet.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
                        end
                        -- No Spread: force direction straight to target or camera look
                        if CFG.NoSpread then
                            local dir = target and (target.Position - Camera.CFrame.Position).Unit
                                or Camera.CFrame.LookVector
                            if bullet.CFrame then
                                bullet.CFrame = CFrame.new(bullet.CFrame.Position, bullet.CFrame.Position + dir)
                            end
                        end
                        -- No Recoil: zero out any recoil vector field
                        if CFG.NoRecoil then
                            if bullet.Recoil then bullet.Recoil = Vector3.zero end
                        end
                    end
                end
            end
        end
    end

    return rawNamecall(self, unpack(args))
end))

-- ─── NOCLIP ──────────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if CFG.Noclip and LocalCharacter then
        for _, p in ipairs(LocalCharacter:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- ─── MOVEMENT ────────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not LocalHumanoid then return end
    if CFG.FastRun then LocalHumanoid.WalkSpeed = CFG.RunSpeed end
    if CFG.HighJump then
        LocalHumanoid.UseJumpPower = true
        LocalHumanoid.JumpPower    = CFG.JumpPower
    end
end)

-- ─── FLY ─────────────────────────────────────────────────────────────────────
local flyBV, flyBG
RunService.RenderStepped:Connect(function()
    if not LocalRoot then return end
    if CFG.Fly then
        if not flyBV then
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
            flyBV.Parent   = LocalRoot
        end
        if not flyBG then
            flyBG = Instance.new("BodyGyro")
            flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
            flyBG.P         = 9e4
            flyBG.Parent    = LocalRoot
        end
        flyBG.CFrame = Camera.CFrame
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.yAxis end
        flyBV.Velocity = dir * CFG.FlySpeed
    else
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
    end
end)

-- ─── CAR MODS ────────────────────────────────────────────────────────────────
local carBV, carBG
RunService.RenderStepped:Connect(function()
    local seat = LocalCharacter and LocalCharacter:FindFirstChildOfClass("Seat")
        or LocalCharacter and LocalCharacter:FindFirstChildOfClass("VehicleSeat")
    -- also check if occupying a seat in Workspace
    if not seat then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if (v:IsA("VehicleSeat") or v:IsA("Seat")) and v.Occupant == LocalHumanoid then
                seat = v; break
            end
        end
    end

    if seat and CFG.CarSpeed then
        seat.MaxSpeed      = CFG.CarSpeedVal
        seat.Torque        = 9999
        seat.TurnSpeed     = 2
    end

    local vehicle = seat and seat.Parent
    if CFG.CarFly and vehicle then
        local primaryPart = vehicle:FindFirstChildOfClass("BasePart")
        if primaryPart then
            if not carBV then
                carBV = Instance.new("BodyVelocity")
                carBV.MaxForce = Vector3.new(1e9,1e9,1e9)
                carBV.Parent   = primaryPart
            end
            if not carBG then
                carBG = Instance.new("BodyGyro")
                carBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
                carBG.P = 9e4
                carBG.Parent = primaryPart
            end
            carBG.CFrame = Camera.CFrame
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
            carBV.Velocity = dir * CFG.CarSpeedVal
        end
    else
        if carBV then carBV:Destroy(); carBV = nil end
        if carBG then carBG:Destroy(); carBG = nil end
    end
end)

-- ─── GUN MODS / INF AMMO ─────────────────────────────────────────────────────
local function PatchGun(tool)
    if not tool or not tool:IsA("Tool") then return end
    local gs = tool:FindFirstChild("GunStates")
    if gs and gs:IsA("ModuleScript") then
        local ok, stats = pcall(require, gs)
        if ok and type(stats) == "table" then
            if CFG.GunMods then
                stats["Auto"]         = true
                stats["FireRate"]     = 0.01
            end
            if CFG.InfAmmo then
                stats["MaxAmmo"]      = 999999
                stats["CurrentAmmo"]  = 999999
                stats["StoredAmmo"]   = 999999
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not (CFG.GunMods or CFG.InfAmmo) then return end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then for _, t in ipairs(bp:GetChildren()) do PatchGun(t) end end
    if LocalCharacter then for _, t in ipairs(LocalCharacter:GetChildren()) do PatchGun(t) end end
end)

-- ─── ESP DRAWING HELPERS ─────────────────────────────────────────────────────
local function NewText(size, color)
    local t = Drawing.new("Text")
    t.Size         = size or 12
    t.Center       = true
    t.Outline      = true
    t.OutlineColor = Color3.fromRGB(0,0,0)
    t.Color        = color or Color3.fromRGB(255,255,255)
    t.Visible      = false
    t.Font         = Drawing.Fonts.Plex
    return t
end

local function NewBox(color)
    local b = Drawing.new("Square")
    b.Thickness = 1.5
    b.Filled    = false
    b.Color     = color or Color3.fromRGB(255,255,255)
    b.Visible   = false
    return b
end

local playerESP, itemESP = {}, {}

RunService.RenderStepped:Connect(function()
    -- Player ESP
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            if playerESP[plr] then
                playerESP[plr].box.Visible     = false
                playerESP[plr].nameTag.Visible = false
            end
            continue
        end
        if not playerESP[plr] then
            playerESP[plr] = { box = NewBox(), nameTag = NewText() }
        end
        local d = playerESP[plr]
        if not CFG.PlayerESP then
            d.box.Visible = false; d.nameTag.Visible = false; continue
        end
        local sc, on = Camera:WorldToScreenPoint(root.Position)
        if on then
            local teamCol
            if plr.Team then
                local tn = plr.Team.Name
                teamCol = tn == "Guards"  and Color3.fromRGB(0,120,255)
                    or    tn == "Inmates" and Color3.fromRGB(255,140,0)
                    or    Color3.fromRGB(255,40,40)
            else teamCol = Color3.fromRGB(200,200,200) end
            local scale = math.clamp(1 - (root.Position - LocalRoot.Position).Magnitude/500, 0.3, 1)
            local bh = math.clamp(math.floor(80*scale), 20, 80)
            local bw = math.floor(bh*0.55)
            d.box.Color    = teamCol
            d.box.Size     = Vector2.new(bw, bh)
            d.box.Position = Vector2.new(sc.X - bw/2, sc.Y - bh/2)
            d.box.Visible  = true
            d.nameTag.Text     = plr.DisplayName
            d.nameTag.Color    = teamCol
            d.nameTag.Position = Vector2.new(sc.X, sc.Y - bh/2 - 14)
            d.nameTag.Visible  = true
        else
            d.box.Visible = false; d.nameTag.Visible = false
        end
    end

    -- Item ESP
    for _, item in ipairs(Workspace:GetDescendants()) do
        if (item:IsA("Tool") or item.Name == "Keycard") and not item:IsDescendantOf(LocalCharacter or Instance.new("Folder")) then
            local part = item:FindFirstChildWhichIsA("BasePart")
            if part then
                if not itemESP[item] then
                    itemESP[item] = NewText(11, Color3.fromRGB(255,220,0))
                end
                if not CFG.ItemESP then
                    itemESP[item].Visible = false; continue
                end
                local sc, on = Camera:WorldToScreenPoint(part.Position)
                itemESP[item].Visible  = on
                if on then
                    itemESP[item].Text     = item.Name
                    itemESP[item].Position = Vector2.new(sc.X, sc.Y)
                end
            end
        end
    end
end)

-- ─── THEME ───────────────────────────────────────────────────────────────────
local REDZ = {
    BG         = Color3.fromRGB(14,12,16),
    BG2        = Color3.fromRGB(20,16,22),
    Accent     = Color3.fromRGB(200,30,50),
    AccentGlow = Color3.fromRGB(255,60,80),
    TextMain   = Color3.fromRGB(240,220,225),
    TextSub    = Color3.fromRGB(130,100,110),
    Stroke     = Color3.fromRGB(60,30,40),
    ToggleOff  = Color3.fromRGB(40,32,36),
    SliderBG   = Color3.fromRGB(35,28,32),
}

-- ─── SCREEN GUI ──────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "Ontoy_PrisonLife"
screenGui.ResetOnSpawn  = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent        = LocalPlayer:WaitForChild("PlayerGui")

local mainWindow = Instance.new("Frame", screenGui)
mainWindow.Size              = UDim2.new(0,540,0,460)
mainWindow.Position          = UDim2.new(0.5,-270,0.5,-230)
mainWindow.BackgroundColor3  = REDZ.BG
mainWindow.BorderSizePixel   = 0
mainWindow.Active            = true
Instance.new("UICorner",  mainWindow).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke",  mainWindow).Color        = REDZ.Stroke

-- ─── TITLE BAR ───────────────────────────────────────────────────────────────
local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size             = UDim2.new(1,0,0,42)
titleBar.BackgroundColor3 = REDZ.BG2
titleBar.Active           = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size                = UDim2.new(1,-140,1,0)
titleText.Position            = UDim2.new(0,15,0,0)
titleText.BackgroundTransparency = 1
titleText.Text                = "ONTOY HUB <font color='#C81E32'>·</font> Prison Life"
titleText.RichText            = true
titleText.TextColor3          = REDZ.TextMain
titleText.Font                = Enum.Font.GothamBold
titleText.TextSize            = 13
titleText.TextXAlignment      = Enum.TextXAlignment.Left

-- Window drag
local dragging, dragStart, dragPos = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = Vector2.new(i.Position.X, i.Position.Y)
        dragPos   = mainWindow.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = Vector2.new(i.Position.X, i.Position.Y) - dragStart
        mainWindow.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset+d.X, dragPos.Y.Scale, dragPos.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Window buttons helper
local function MakeWinBtn(xOff, bg, txt)
    local b = Instance.new("TextButton", titleBar)
    b.Size            = UDim2.new(0,26,0,26)
    b.Position        = UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3 = bg
    b.Text            = txt
    b.TextColor3      = Color3.fromRGB(255,255,255)
    b.Font            = Enum.Font.GothamBold
    b.TextSize        = 11
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

local closeBtn    = MakeWinBtn(-34,  REDZ.Accent,     "✕")
local minimizeBtn = MakeWinBtn(-66,  REDZ.ToggleOff,  "—")
local hideBtn     = MakeWinBtn(-98,  REDZ.ToggleOff,  "👁")  -- HUD hide toggle

local uiVisible   = true
local uiMinimized = false

minimizeBtn.MouseButton1Click:Connect(function()
    uiMinimized = not uiMinimized
    mainWindow.Size = uiMinimized and UDim2.new(0,540,0,42) or UDim2.new(0,540,0,460)
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- HUD hide button (same as RightControl)
hideBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    mainWindow.Visible = uiVisible
end)

-- RightControl keybind — hide/show entire window
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        uiVisible = not uiVisible
        mainWindow.Visible = uiVisible
    end
end)

-- ─── LAYOUT ──────────────────────────────────────────────────────────────────
local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size             = UDim2.new(0,138,1,-42)
sidebar.Position         = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = REDZ.BG2
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
local sbl = Instance.new("UIListLayout", sidebar)
sbl.Padding              = UDim.new(0,3)
sbl.HorizontalAlignment  = Enum.HorizontalAlignment.Center
local sbp = Instance.new("UIPadding", sidebar)
sbp.PaddingTop = UDim.new(0,12)

local contentScroll = Instance.new("ScrollingFrame", mainWindow)
contentScroll.Size              = UDim2.new(1,-146,1,-50)
contentScroll.Position          = UDim2.new(0,142,0,46)
contentScroll.BackgroundTransparency = 1
contentScroll.ScrollBarThickness = 3
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local cl = Instance.new("UIListLayout", contentScroll)
cl.Padding             = UDim.new(0,6)
cl.HorizontalAlignment = Enum.HorizontalAlignment.Center

local pages, sidebarBtns = {}, {}

local function MakePage()
    local pg = Instance.new("Frame", contentScroll)
    pg.Size              = UDim2.new(1,0,0,0)
    pg.AutomaticSize     = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1
    pg.Visible           = false
    local lay = Instance.new("UIListLayout", pg)
    lay.Padding             = UDim.new(0,6)
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    return pg
end

local function MakeSidebarBtn(icon, label, id)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size               = UDim2.new(1,-14,0,38)
    btn.BackgroundTransparency = 1
    btn.Text               = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size               = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = icon .. " " .. label
    lbl.TextColor3         = REDZ.TextSub
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 12
    sidebarBtns[id]        = { btn = btn, label = lbl }
    return btn
end

local function SetActivePage(id)
    for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
    for bid, sb in pairs(sidebarBtns) do
        local a = (bid == id)
        sb.btn.BackgroundTransparency = a and 0 or 1
        sb.btn.BackgroundColor3       = a and Color3.fromRGB(30,18,22) or REDZ.ToggleOff
        sb.label.TextColor3           = a and REDZ.TextMain or REDZ.TextSub
    end
    -- reset scroll
    contentScroll.CanvasPosition = Vector2.zero
end

-- ─── UI COMPONENTS ───────────────────────────────────────────────────────────
local function MakeToggle(parent, label, onChange)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1,-8,0,46)
    row.BackgroundColor3 = REDZ.BG2
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local tl = Instance.new("TextLabel", row)
    tl.Size              = UDim2.new(1,-60,1,0)
    tl.Position          = UDim2.new(0,12,0,0)
    tl.BackgroundTransparency = 1
    tl.Text              = label
    tl.TextColor3        = REDZ.TextMain
    tl.Font              = Enum.Font.GothamBold
    tl.TextSize          = 12
    tl.TextXAlignment    = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", row)
    btn.Size             = UDim2.new(0,36,0,20)
    btn.Position         = UDim2.new(1,-44,0.5,-10)
    btn.BackgroundColor3 = REDZ.ToggleOff
    btn.Text             = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and REDZ.Accent or REDZ.ToggleOff
        if onChange then onChange(state) end
    end)
    return btn
end

local function MakeSlider(parent, label, minVal, maxVal, defVal, onChange)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1,-8,0,54)
    row.BackgroundColor3 = REDZ.BG2
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local tl = Instance.new("TextLabel", row)
    tl.Size              = UDim2.new(1,-80,0,20)
    tl.Position          = UDim2.new(0,12,0,6)
    tl.BackgroundTransparency = 1
    tl.Text              = label
    tl.TextColor3        = REDZ.TextMain
    tl.Font              = Enum.Font.GothamBold
    tl.TextSize          = 12
    tl.TextXAlignment    = Enum.TextXAlignment.Left
    local vl = Instance.new("TextLabel", row)
    vl.Size              = UDim2.new(0,70,0,20)
    vl.Position          = UDim2.new(1,-78,0,6)
    vl.BackgroundTransparency = 1
    vl.Text              = tostring(defVal)
    vl.TextColor3        = REDZ.AccentGlow
    vl.Font              = Enum.Font.GothamBold
    vl.TextSize          = 12
    vl.TextXAlignment    = Enum.TextXAlignment.Right
    local hit = Instance.new("TextButton", row)
    hit.Size             = UDim2.new(1,-24,0,16)
    hit.Position         = UDim2.new(0,12,0,30)
    hit.BackgroundColor3 = REDZ.SliderBG
    hit.Text             = ""
    Instance.new("UICorner", hit).CornerRadius = UDim.new(0,4)
    local fill = Instance.new("Frame", hit)
    fill.Size            = UDim2.new((defVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = REDZ.Accent
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,4)
    local draggingSlider = false
    local function Update(i)
        local pct = math.clamp((i.Position.X - hit.AbsolutePosition.X)/hit.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal-minVal)*pct)
        fill.Size = UDim2.new(pct,0,1,0)
        vl.Text   = tostring(val)
        if onChange then onChange(val) end
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = true; Update(i) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then Update(i) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
    end)
end

local function MakeActionBtn(parent, label, onClick)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1,-8,0,40)
    row.BackgroundColor3 = REDZ.BG2
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local btn = Instance.new("TextButton", row)
    btn.Size             = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text             = label
    btn.TextColor3       = REDZ.TextMain
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 12
    btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
end

local function MakeSectionLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size             = UDim2.new(1,-8,0,22)
    lbl.BackgroundTransparency = 1
    lbl.Text             = text
    lbl.TextColor3       = REDZ.AccentGlow
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 11
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
end

-- ─── PAGES ───────────────────────────────────────────────────────────────────

-- MOVEMENT
local movePage = MakePage(); pages["move"] = movePage
local moveBtn  = MakeSidebarBtn("🏃","Movement","move")
MakeSectionLabel(movePage, "  CHARACTER")
MakeToggle(movePage, "Fast Run",   function(s) CFG.FastRun  = s end)
MakeSlider(movePage, "Run Speed",  16, 250, 50,  function(v) CFG.RunSpeed  = v end)
MakeToggle(movePage, "High Jump",  function(s) CFG.HighJump = s end)
MakeSlider(movePage, "Jump Power", 50, 300, 100, function(v) CFG.JumpPower = v end)
MakeToggle(movePage, "Fly",        function(s) CFG.Fly      = s end)
MakeSlider(movePage, "Fly Speed",  20, 200, 50,  function(v) CFG.FlySpeed  = v end)
MakeToggle(movePage, "Noclip",     function(s) CFG.Noclip   = s end)

-- VEHICLE
local carPage = MakePage(); pages["car"] = carPage
local carBtn  = MakeSidebarBtn("🚗","Vehicle","car")
MakeSectionLabel(carPage, "  VEHICLE MODS")
MakeToggle(carPage, "Car Speed Boost", function(s) CFG.CarSpeed = s end)
MakeSlider(carPage, "Car Speed",  50, 500, 100, function(v) CFG.CarSpeedVal = v end)
MakeToggle(carPage, "Car Fly",    function(s) CFG.CarFly = s end)

-- COMBAT
local combatPage = MakePage(); pages["combat"] = combatPage
local combatBtn  = MakeSidebarBtn("🔫","Combat","combat")
MakeSectionLabel(combatPage, "  WEAPONS")
MakeToggle(combatPage, "Gun Mods  (Auto · Rate)",  function(s) CFG.GunMods   = s end)
MakeToggle(combatPage, "Infinite Ammo",             function(s) CFG.InfAmmo   = s end)
MakeToggle(combatPage, "No Recoil",                 function(s) CFG.NoRecoil  = s end)
MakeToggle(combatPage, "No Spread",                 function(s) CFG.NoSpread  = s end)
MakeToggle(combatPage, "Silent Aimbot",             function(s) CFG.SilentAim = s end)

-- VISUALS
local visualPage = MakePage(); pages["visual"] = visualPage
local visualBtn  = MakeSidebarBtn("👁","Visuals","visual")
MakeSectionLabel(visualPage, "  ESP")
MakeToggle(visualPage, "Player ESP  (team colors)", function(s) CFG.PlayerESP = s end)
MakeToggle(visualPage, "Item / Keycard ESP",         function(s) CFG.ItemESP   = s end)

-- TELEPORTS
local tpPage = MakePage(); pages["tp"] = tpPage
local tpBtn  = MakeSidebarBtn("⚡","Teleports","tp")
MakeSectionLabel(tpPage, "  FAST TRAVEL")
for name, pos in pairs(TELEPORTS) do
    MakeActionBtn(tpPage, "→  " .. name, function()
        if LocalRoot then
            LocalRoot.CFrame = CFrame.new(pos)
        end
    end)
end

-- ─── WIRE SIDEBAR ────────────────────────────────────────────────────────────
moveBtn.MouseButton1Click:Connect(function()   SetActivePage("move")   end)
carBtn.MouseButton1Click:Connect(function()    SetActivePage("car")    end)
combatBtn.MouseButton1Click:Connect(function() SetActivePage("combat") end)
visualBtn.MouseButton1Click:Connect(function() SetActivePage("visual") end)
tpBtn.MouseButton1Click:Connect(function()     SetActivePage("tp")     end)

SetActivePage("move")
