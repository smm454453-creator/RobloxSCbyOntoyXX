local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")
local Mouse = LocalPlayer:GetMouse()

local CONFIG = {
    SilentAim    = false,
    SilentTarget = "Head",
    FastRun      = false,
    InfiniteJump = false,
    PlayerESP    = false,
    SkeletonESP  = false,
    SpeedPercent = 50,
    FOVEnabled   = true,
    FOVRadius    = 120,
}

local BASE_SPEED = 16
local MAX_SPEED  = 100

-- ── SILENT AIM ────────────────────────────────────────────────────────────────
local function GetClosestToCenter()
    local best, bestDist = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not plr.Character then continue end
        local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local sc, onScreen = Camera:WorldToScreenPoint(root.Position)
        if not onScreen then continue end
        local screenDist = (Vector2.new(sc.X, sc.Y) - center).Magnitude
        if CONFIG.FOVEnabled and screenDist > CONFIG.FOVRadius then continue end
        if screenDist < bestDist then
            bestDist = screenDist; best = plr
        end
    end
    return best
end

local function GetHitbox(plr)
    if not plr or not plr.Character then return nil end
    return plr.Character:FindFirstChild(CONFIG.SilentTarget == "Head" and "Head" or "HumanoidRootPart")
end

-- Hook via getrawmetatable — work di Synapse X, KRNL, Fluxus, Solara
local oldIndex
if getrawmetatable and hookmetamethod then
    local mouseMeta = getrawmetatable(Mouse)
    oldIndex = hookmetamethod(Mouse, "__index", function(self, key)
        if CONFIG.SilentAim then
            local target = GetClosestToCenter()
            local hitbox = GetHitbox(target)
            if hitbox then
                if key == "Hit" then
                    return CFrame.new(hitbox.Position)
                elseif key == "Target" then
                    return hitbox
                end
            end
        end
        return oldIndex(self, key)
    end)
end

-- ── MOVEMENT ──────────────────────────────────────────────────────────────────
local function GetTargetSpeed()
    return BASE_SPEED + (MAX_SPEED - BASE_SPEED) * (CONFIG.SpeedPercent / 100)
end

local function ApplySpeed()
    if not CONFIG.FastRun then return end
    local st = LocalHumanoid:GetState()
    if st == Enum.HumanoidStateType.GettingUp
    or st == Enum.HumanoidStateType.Seated then return end
    LocalHumanoid.WalkSpeed = GetTargetSpeed()
end

local jumpCount     = 0
local canDoubleJump = false

local function OnStateChanged(_, new)
    if new == Enum.HumanoidStateType.Jumping then
        if jumpCount == 0 then
            jumpCount = 1; canDoubleJump = false
            task.delay(0.15, function()
                local st = LocalHumanoid:GetState()
                if st == Enum.HumanoidStateType.Freefall
                or st == Enum.HumanoidStateType.Jumping then
                    canDoubleJump = true
                end
            end)
        end
    elseif new == Enum.HumanoidStateType.Landed
        or new == Enum.HumanoidStateType.Running
        or new == Enum.HumanoidStateType.RunningNoPhysics then
        jumpCount = 0; canDoubleJump = false
    end
end

local stateConn = LocalHumanoid.StateChanged:Connect(OnStateChanged)

UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        LocalHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ── ESP DRAWING ───────────────────────────────────────────────────────────────
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

local function NewLine(color, thick)
    local l = Drawing.new("Line")
    l.Thickness = thick or 1
    l.Color = color or Color3.fromRGB(255,255,255)
    l.Visible = false
    return l
end

local function NewFill(color)
    local f = Drawing.new("Square"); f.Filled = true
    f.Color = color or Color3.fromRGB(50,200,80); f.Visible = false
    return f
end

-- FOV circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Color = Color3.fromRGB(255,255,255)
fovCircle.Filled = false
fovCircle.Radius = CONFIG.FOVRadius
fovCircle.Visible = CONFIG.FOVEnabled
fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

-- ── SKELETON BONES ────────────────────────────────────────────────────────────
-- Pasangan part yang dihubungin garis buat skeleton ESP
local BONE_PAIRS = {
    {"Head",              "UpperTorso"},
    {"UpperTorso",        "LowerTorso"},
    {"LowerTorso",        "LeftUpperLeg"},
    {"LowerTorso",        "RightUpperLeg"},
    {"LeftUpperLeg",      "LeftLowerLeg"},
    {"RightUpperLeg",     "RightLowerLeg"},
    {"LeftLowerLeg",      "LeftFoot"},
    {"RightLowerLeg",     "RightFoot"},
    {"UpperTorso",        "LeftUpperArm"},
    {"UpperTorso",        "RightUpperArm"},
    {"LeftUpperArm",      "LeftLowerArm"},
    {"RightUpperArm",     "RightLowerArm"},
    {"LeftLowerArm",      "LeftHand"},
    {"RightLowerArm",     "RightHand"},
}

-- R6 fallback
local BONE_PAIRS_R6 = {
    {"Head",       "Torso"},
    {"Torso",      "Left Leg"},
    {"Torso",      "Right Leg"},
    {"Torso",      "Left Arm"},
    {"Torso",      "Right Arm"},
}

local playerESPData = {}

local function CreatePlayerESP()
    local bones = {}
    for i = 1, #BONE_PAIRS + #BONE_PAIRS_R6 do
        bones[i] = NewLine(Color3.fromRGB(255, 255, 255), 1)
    end
    return {
        box      = NewBox(Color3.fromRGB(0, 200, 255), 1.5),
        nameTag  = NewText(13, Color3.fromRGB(0, 200, 255)),
        distTag  = NewText(11, Color3.fromRGB(200, 200, 200)),
        hpBG     = NewFill(Color3.fromRGB(30, 30, 30)),
        hpFill   = NewFill(Color3.fromRGB(50, 220, 80)),
        bones    = bones,
    }
end

local function RemovePlayerESP(d)
    d.box:Remove(); d.nameTag:Remove(); d.distTag:Remove()
    d.hpBG:Remove(); d.hpFill:Remove()
    for _, l in ipairs(d.bones) do l:Remove() end
end

local function HidePlayerESP(d)
    d.box.Visible = false; d.nameTag.Visible = false
    d.distTag.Visible = false; d.hpBG.Visible = false; d.hpFill.Visible = false
    for _, l in ipairs(d.bones) do l.Visible = false end
end

local function RenderESP()
    -- Cleanup
    for plr, d in pairs(playerESPData) do
        if not plr or not plr.Parent then
            RemovePlayerESP(d); playerESPData[plr] = nil
        end
    end
    -- Add new
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not playerESPData[plr] then
            playerESPData[plr] = CreatePlayerESP()
        end
    end

    for plr, d in pairs(playerESPData) do
        if not CONFIG.PlayerESP and not CONFIG.SkeletonESP then
            HidePlayerESP(d); continue
        end
        if not plr.Character then HidePlayerESP(d); continue end

        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        local hum  = plr.Character:FindFirstChildWhichIsA("Humanoid")
        local head = plr.Character:FindFirstChild("Head")
        if not root or not hum or not head then HidePlayerESP(d); continue end

        local rootSC, rootOn = Camera:WorldToScreenPoint(root.Position)
        local headSC, headOn = Camera:WorldToScreenPoint(head.Position + Vector3.new(0, 0.7, 0))
        if not rootOn or not headOn then HidePlayerESP(d); continue end

        local dist = math.floor((root.Position - LocalRoot.Position).Magnitude)
        if dist > 600 then HidePlayerESP(d); continue end

        -- Box ESP
        if CONFIG.PlayerESP then
            local boxH = math.abs(headSC.Y - rootSC.Y) * 2
            local boxW = boxH * 0.55
            local boxX = rootSC.X - boxW / 2
            local boxY = headSC.Y - 4
            local scale = math.clamp(1 - dist/600, 0.3, 1)
            local tsz = math.floor(10*scale + 3)

            d.box.Size     = Vector2.new(boxW, boxH)
            d.box.Position = Vector2.new(boxX, boxY)
            d.box.Visible  = true

            d.nameTag.Text     = plr.DisplayName
            d.nameTag.Size     = tsz
            d.nameTag.Position = Vector2.new(rootSC.X, boxY - tsz - 2)
            d.nameTag.Visible  = true

            d.distTag.Text     = dist .. "m"
            d.distTag.Size     = math.max(tsz - 2, 9)
            d.distTag.Position = Vector2.new(rootSC.X, boxY + boxH + 2)
            d.distTag.Visible  = true

            local hpPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            local barX  = boxX - 5
            local barY  = boxY
            local barH  = boxH

            d.hpBG.Size     = Vector2.new(3, barH)
            d.hpBG.Position = Vector2.new(barX, barY)
            d.hpBG.Visible  = true

            local fh = math.max(math.floor(barH * hpPct), 1)
            d.hpFill.Color    = Color3.fromRGB(
                math.floor(255*(1-hpPct)),
                math.floor(220*hpPct),
                50
            )
            d.hpFill.Size     = Vector2.new(3, fh)
            d.hpFill.Position = Vector2.new(barX, barY + barH - fh)
            d.hpFill.Visible  = true
        else
            d.box.Visible    = false
            d.nameTag.Visible = false
            d.distTag.Visible = false
            d.hpBG.Visible   = false
            d.hpFill.Visible  = false
        end

        -- Skeleton ESP
        if CONFIG.SkeletonESP then
            local isR15 = plr.Character:FindFirstChild("UpperTorso") ~= nil
            local pairs_to_use = isR15 and BONE_PAIRS or BONE_PAIRS_R6
            for i, pair in ipairs(pairs_to_use) do
                local partA = plr.Character:FindFirstChild(pair[1])
                local partB = plr.Character:FindFirstChild(pair[2])
                local line  = d.bones[i]
                if partA and partB then
                    local scA, onA = Camera:WorldToScreenPoint(partA.Position)
                    local scB, onB = Camera:WorldToScreenPoint(partB.Position)
                    if onA and onB then
                        line.From    = Vector2.new(scA.X, scA.Y)
                        line.To      = Vector2.new(scB.X, scB.Y)
                        line.Color   = Color3.fromRGB(255, 255, 255)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
            -- Hide unused bone lines
            for i = #pairs_to_use + 1, #d.bones do
                d.bones[i].Visible = false
            end
        else
            for _, l in ipairs(d.bones) do l.Visible = false end
        end
    end
end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Ontoy_HS"; screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local C = {
    BG         = Color3.fromRGB(10, 10, 14),
    BG2        = Color3.fromRGB(16, 16, 22),
    Accent     = Color3.fromRGB(80, 140, 255),
    AccentDim  = Color3.fromRGB(40, 80, 180),
    AccentGlow = Color3.fromRGB(120, 180, 255),
    TextMain   = Color3.fromRGB(230, 235, 255),
    TextSub    = Color3.fromRGB(100, 110, 140),
    Stroke     = Color3.fromRGB(40, 50, 80),
    ToggleOff  = Color3.fromRGB(35, 35, 45),
    SliderFill = Color3.fromRGB(80, 140, 255),
    SliderBG   = Color3.fromRGB(30, 32, 45),
    Red        = Color3.fromRGB(255, 70, 70),
    Green      = Color3.fromRGB(50, 210, 100),
    Orange     = Color3.fromRGB(255, 160, 40),
}

local mainWindow = Instance.new("Frame")
mainWindow.Size             = UDim2.new(0, 500, 0, 420)
mainWindow.Position         = UDim2.new(0.5, -250, 0.5, -210)
mainWindow.BackgroundColor3 = C.BG
mainWindow.BorderSizePixel  = 0
mainWindow.Active           = true
mainWindow.Draggable        = false
mainWindow.Parent           = screenGui
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0, 10)
local ms = Instance.new("UIStroke", mainWindow); ms.Color = C.Stroke; ms.Thickness = 1.5

local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size = UDim2.new(1, 0, 0, 42); titleBar.BackgroundColor3 = C.BG2
titleBar.BorderSizePixel = 0; titleBar.Active = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local dragging, dragMouse, dragPos = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragMouse = Vector2.new(i.Position.X, i.Position.Y)
        dragPos = mainWindow.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = Vector2.new(i.Position.X, i.Position.Y) - dragMouse
        mainWindow.Position = UDim2.new(
            dragPos.X.Scale, dragPos.X.Offset + d.X,
            dragPos.Y.Scale, dragPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local accentLine = Instance.new("Frame", titleBar)
accentLine.Size = UDim2.new(1,0,0,2); accentLine.Position = UDim2.new(0,0,1,-2)
accentLine.BackgroundColor3 = C.Accent; accentLine.BorderSizePixel = 0

local dot = Instance.new("Frame", titleBar)
dot.Size = UDim2.new(0,8,0,8); dot.Position = UDim2.new(0,14,0.5,-4)
dot.BackgroundColor3 = C.AccentGlow; dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(0,4)

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(1,-120,1,0); titleLbl.Position = UDim2.new(0,30,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "ONTOY HUB  <font color='#507AFF'>·</font>  HyperShot"
titleLbl.RichText = true; titleLbl.TextColor3 = C.TextMain
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local byLbl = Instance.new("TextLabel", titleBar)
byLbl.Size = UDim2.new(0,60,1,0); byLbl.Position = UDim2.new(0,260,0,0)
byLbl.BackgroundTransparency = 1; byLbl.Text = "by ontoy"
byLbl.TextColor3 = C.TextSub; byLbl.Font = Enum.Font.Gotham
byLbl.TextSize = 11; byLbl.TextXAlignment = Enum.TextXAlignment.Left

local function MakeWinBtn(xOff, bg, txt)
    local b = Instance.new("TextButton", titleBar)
    b.Size = UDim2.new(0,26,0,26); b.Position = UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3 = bg; b.Text = txt; b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end
local closeBtn    = MakeWinBtn(-34, C.Red,      "✕")
local minimizeBtn = MakeWinBtn(-66, C.ToggleOff, "—")

local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size = UDim2.new(0,130,1,-42); sidebar.Position = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = C.BG2; sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", sidebar).Color = C.Stroke
local sbl = Instance.new("UIListLayout", sidebar)
sbl.Padding = UDim.new(0,3); sbl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0,12)

local contentArea = Instance.new("Frame", mainWindow)
contentArea.Size = UDim2.new(1,-138,1,-50); contentArea.Position = UDim2.new(0,134,0,46)
contentArea.BackgroundTransparency = 1; contentArea.BorderSizePixel = 0

local scroll = Instance.new("ScrollingFrame", contentArea)
scroll.Size = UDim2.new(1,0,1,0); scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C.AccentDim
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local scl = Instance.new("UIListLayout", scroll)
scl.Padding = UDim.new(0,6); scl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", scroll).PaddingTop = UDim.new(0,8)

local pages, sideBtns = {}, {}

local function MakePage()
    local pg = Instance.new("Frame", scroll)
    pg.Size = UDim2.new(1,0,0,0); pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1; pg.BorderSizePixel = 0; pg.Visible = false
    local l = Instance.new("UIListLayout", pg)
    l.Padding = UDim.new(0,6); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Instance.new("UIPadding", pg).PaddingBottom = UDim.new(0,8)
    return pg
end

local function MakeSideBtn(icon, label, id)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1,-14,0,38); btn.BackgroundTransparency = 1
    btn.Text = ""; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    local bar = Instance.new("Frame", btn)
    bar.Size = UDim2.new(0,3,0.6,0); bar.Position = UDim2.new(0,0,0.2,0)
    bar.BackgroundColor3 = C.Accent; bar.BorderSizePixel = 0; bar.Visible = false
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,2)
    local ic = Instance.new("TextLabel", btn)
    ic.Size = UDim2.new(0,22,1,0); ic.Position = UDim2.new(0,10,0,0)
    ic.BackgroundTransparency = 1; ic.Text = icon
    ic.TextColor3 = C.TextSub; ic.Font = Enum.Font.GothamBold; ic.TextSize = 14
    local lb = Instance.new("TextLabel", btn)
    lb.Size = UDim2.new(1,-38,1,0); lb.Position = UDim2.new(0,36,0,0)
    lb.BackgroundTransparency = 1; lb.Text = label
    lb.TextColor3 = C.TextSub; lb.Font = Enum.Font.Gotham; lb.TextSize = 12
    lb.TextXAlignment = Enum.TextXAlignment.Left
    sideBtns[id] = {btn=btn, icon=ic, label=lb, bar=bar}
    return btn
end

local function SetPage(id)
    for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
    for bid, sb in pairs(sideBtns) do
        local a = (bid == id)
        sb.btn.BackgroundTransparency = a and 0 or 1
        sb.btn.BackgroundColor3 = a and Color3.fromRGB(18,20,34) or C.ToggleOff
        sb.icon.TextColor3 = a and C.AccentGlow or C.TextSub
        sb.label.TextColor3 = a and C.TextMain or C.TextSub
        sb.bar.Visible = a
    end
end

local function MakeSection(parent, text, color)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1,-8,0,18); l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = color or C.Accent
    l.Font = Enum.Font.GothamBold; l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function MakeToggle(parent, label, sub, ac)
    ac = ac or C.Accent
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = C.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", row); stroke.Color = C.Stroke; stroke.Thickness = 1
    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(1,-60,0,22); tl.Position = UDim2.new(0,14,0,8)
    tl.BackgroundTransparency = 1; tl.Text = label; tl.TextColor3 = C.TextMain
    tl.Font = Enum.Font.GothamBold; tl.TextSize = 12; tl.TextXAlignment = Enum.TextXAlignment.Left
    if sub then
        local s = Instance.new("TextLabel", row)
        s.Size = UDim2.new(1,-60,0,16); s.Position = UDim2.new(0,14,0,28)
        s.BackgroundTransparency = 1; s.Text = sub; s.TextColor3 = C.TextSub
        s.Font = Enum.Font.Gotham; s.TextSize = 10; s.TextXAlignment = Enum.TextXAlignment.Left
    end
    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(0,36,0,20); bg.Position = UDim2.new(1,-48,0.5,-10)
    bg.BackgroundColor3 = C.ToggleOff; bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,10)
    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0,14,0,14); knob.Position = UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3 = C.TextSub; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
    local btn = Instance.new("TextButton", bg)
    btn.Size = UDim2.new(1,8,1,8); btn.Position = UDim2.new(0,-4,0,-4)
    btn.BackgroundTransparency = 1; btn.Text = ""; btn.BorderSizePixel = 0
    local state = false
    local function Set(s)
        state = s
        if s then
            bg.BackgroundColor3 = ac; knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            knob.Position = UDim2.new(1,-17,0.5,-7)
            row.BackgroundColor3 = Color3.fromRGB(14,16,26); stroke.Color = C.AccentDim
        else
            bg.BackgroundColor3 = C.ToggleOff; knob.BackgroundColor3 = C.TextSub
            knob.Position = UDim2.new(0,3,0.5,-7)
            row.BackgroundColor3 = C.BG2; stroke.Color = C.Stroke
        end
    end
    btn.MouseButton1Click:Connect(function() Set(not state) end)
    return row, function() return state end, Set
end

local function MakeSlider(parent, label, dMin, dMax, initPct, unit, onChange)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,66); row.BackgroundColor3 = C.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", row).Color = C.Stroke
    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(1,-80,0,20); tl.Position = UDim2.new(0,14,0,8)
    tl.BackgroundTransparency = 1; tl.Text = label; tl.TextColor3 = C.TextMain
    tl.Font = Enum.Font.GothamBold; tl.TextSize = 12; tl.TextXAlignment = Enum.TextXAlignment.Left
    local vl = Instance.new("TextLabel", row)
    vl.Size = UDim2.new(0,70,0,20); vl.Position = UDim2.new(1,-78,0,8)
    vl.BackgroundTransparency = 1; vl.Font = Enum.Font.GothamBold; vl.TextSize = 12
    vl.TextColor3 = C.AccentGlow; vl.TextXAlignment = Enum.TextXAlignment.Right
    local sbg = Instance.new("Frame", row)
    sbg.Size = UDim2.new(1,-28,0,5); sbg.Position = UDim2.new(0,14,0,42)
    sbg.BackgroundColor3 = C.SliderBG; sbg.BorderSizePixel = 0
    Instance.new("UICorner", sbg).CornerRadius = UDim.new(0,3)
    local hit = Instance.new("TextButton", sbg)
    hit.Size = UDim2.new(1,0,0,28); hit.Position = UDim2.new(0,0,0.5,-14)
    hit.BackgroundTransparency = 1; hit.Text = ""; hit.BorderSizePixel = 0; hit.ZIndex = 5
    local fill = Instance.new("Frame", sbg)
    fill.Size = UDim2.new(initPct,0,1,0); fill.BackgroundColor3 = C.SliderFill; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)
    local knob = Instance.new("Frame", sbg)
    knob.Size = UDim2.new(0,14,0,14); knob.Position = UDim2.new(initPct,-7,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke", knob).Color = C.Accent
    local drag = false
    local function Compute(px)
        local pct = math.clamp((px - sbg.AbsolutePosition.X)/sbg.AbsoluteSize.X,0,1)
        return pct, math.floor(dMin + (dMax-dMin)*pct)
    end
    local function Apply(pct, val)
        fill.Size = UDim2.new(pct,0,1,0); knob.Position = UDim2.new(pct,-7,0.5,-7)
        vl.Text = val..(unit or ""); if onChange then onChange(val,pct) end
    end
    Apply(initPct, math.floor(dMin+(dMax-dMin)*initPct))
    hit.MouseButton1Down:Connect(function() drag = true end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local p,v = Compute(i.Position.X); Apply(p,v)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    hit.MouseButton1Click:Connect(function()
        local m = UserInputService:GetMouseLocation()
        local p,v = Compute(m.X); Apply(p,v)
    end)
end

-- Selector row buat Head / Body
local function MakeSelector(parent, label, options, default, onChange)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = C.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", row).Color = C.Stroke
    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(0.5,0,1,0); tl.Position = UDim2.new(0,14,0,0)
    tl.BackgroundTransparency = 1; tl.Text = label; tl.TextColor3 = C.TextMain
    tl.Font = Enum.Font.GothamBold; tl.TextSize = 12; tl.TextXAlignment = Enum.TextXAlignment.Left
    local btnFrame = Instance.new("Frame", row)
    btnFrame.Size = UDim2.new(0, #options * 58, 0, 30)
    btnFrame.Position = UDim2.new(1, -( #options * 58 + 10), 0.5, -15)
    btnFrame.BackgroundTransparency = 1; btnFrame.BorderSizePixel = 0
    local selected = default
    local btns = {}
    for i, opt in ipairs(options) do
        local b = Instance.new("TextButton", btnFrame)
        b.Size = UDim2.new(0,54,1,0); b.Position = UDim2.new(0,(i-1)*58,0,0)
        b.Text = opt; b.Font = Enum.Font.GothamBold; b.TextSize = 11
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        btns[opt] = b
        local function Refresh()
            for o, bb in pairs(btns) do
                bb.BackgroundColor3 = (o == selected) and C.Accent or C.ToggleOff
                bb.TextColor3 = (o == selected) and Color3.fromRGB(255,255,255) or C.TextSub
            end
        end
        b.MouseButton1Click:Connect(function()
            selected = opt; Refresh()
            if onChange then onChange(opt) end
        end)
        if opt == default then
            b.BackgroundColor3 = C.Accent; b.TextColor3 = Color3.fromRGB(255,255,255)
        else
            b.BackgroundColor3 = C.ToggleOff; b.TextColor3 = C.TextSub
        end
    end
end

-- ── BUILD PAGES ───────────────────────────────────────────────────────────────
local aimPage  = MakePage(); pages["aim"]      = aimPage
local movePageP = MakePage(); pages["movement"] = movePageP
local espPage  = MakePage(); pages["esp"]      = espPage

local aimBtn  = MakeSideBtn("🎯", "Aimbot",   "aim")
local moveBtn = MakeSideBtn("🏃", "Movement", "movement")
local espBtn  = MakeSideBtn("👁",  "ESP",      "esp")

-- Aim page
MakeSection(aimPage, "SILENT AIM")
local _, saGet, _ = MakeToggle(aimPage, "Silent Aim", "Redirect Mouse.Hit ke hitbox target", C.Red)
MakeSelector(aimPage, "Target", {"Head", "Body"}, "Head", function(val)
    CONFIG.SilentTarget = val == "Head" and "Head" or "HumanoidRootPart"
end)

MakeSection(aimPage, "FOV")
local _, fovGet, fovSet = MakeToggle(aimPage, "FOV Circle", "Lingkaran area silent aim aktif")
fovSet(true)
MakeSlider(aimPage, "FOV Radius", 10, 400, CONFIG.FOVRadius/400, " px", function(val)
    CONFIG.FOVRadius = val
    fovCircle.Radius = val
end)

-- Movement page
MakeSection(movePageP, "SPEED")
local _, frGet, _ = MakeToggle(movePageP, "Fast Run", "Override WalkSpeed")
MakeSlider(movePageP, "Run Speed", BASE_SPEED, MAX_SPEED, 0.5, " ws", function(val, pct)
    CONFIG.SpeedPercent = pct * 100
end)
MakeSection(movePageP, "JUMP")
local _, ijGet, _ = MakeToggle(movePageP, "Infinite Jump", "Lompat terus tanpa batas")

-- ESP page
MakeSection(espPage, "PLAYER ESP")
local _, peGet, _ = MakeToggle(espPage, "Player ESP",   "Box + nama + HP bar — cyan")
MakeSection(espPage, "SKELETON ESP")
local _, seGet, _ = MakeToggle(espPage, "Skeleton ESP", "Garis tulang seluruh body — R15 + R6")

-- ── WIRE ──────────────────────────────────────────────────────────────────────
local function Wire(getter, key, onOn, onOff)
    RunService.Heartbeat:Connect(function()
        local s = getter()
        if CONFIG[key] ~= s then
            CONFIG[key] = s
            if s then if onOn  then onOn()  end
            else      if onOff then onOff() end end
        end
    end)
end

Wire(saGet,  "SilentAim")
Wire(fovGet, "FOVEnabled", function()
    fovCircle.Visible = true
end, function()
    fovCircle.Visible = false
end)
Wire(frGet,  "FastRun", nil, function() LocalHumanoid.WalkSpeed = BASE_SPEED end)
Wire(ijGet,  "InfiniteJump")
Wire(peGet,  "PlayerESP")
Wire(seGet,  "SkeletonESP")

aimBtn.MouseButton1Click:Connect(function()  SetPage("aim")      end)
moveBtn.MouseButton1Click:Connect(function() SetPage("movement") end)
espBtn.MouseButton1Click:Connect(function()  SetPage("esp")      end)
SetPage("aim")

local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
    contentVisible = not contentVisible
    sidebar.Visible = contentVisible; contentArea.Visible = contentVisible
    mainWindow.Size = contentVisible and UDim2.new(0,500,0,420) or UDim2.new(0,500,0,42)
end)
closeBtn.MouseButton1Click:Connect(function()
    CONFIG.SilentAim = false; CONFIG.FastRun = false
    LocalHumanoid.WalkSpeed = BASE_SPEED
    fovCircle:Remove()
    for _, d in pairs(playerESPData) do RemovePlayerESP(d) end
    screenGui:Destroy()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot      = char:WaitForChild("HumanoidRootPart")
    LocalHumanoid  = char:WaitForChild("Humanoid")
    jumpCount = 0; canDoubleJump = false
    if stateConn then stateConn:Disconnect() end
    stateConn = LocalHumanoid.StateChanged:Connect(OnStateChanged)
    if CONFIG.FastRun then LocalHumanoid.WalkSpeed = GetTargetSpeed() end
end)

RunService.RenderStepped:Connect(function()
    if CONFIG.FastRun then ApplySpeed() end
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    RenderESP()
end)