local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LP = Players.LocalPlayer

local function GetChar()
    local c = LP.Character
    if not c then return nil, nil, nil end
    local r = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChildOfClass("Humanoid")
    return c, r, h
end

local REMOTE_ATTACK   = "AttackPlayer"
local REMOTE_SKILL    = "UseSkill"

local CONFIG = {
    AutoAttack   = false,
    AttackRange  = 20,
    NoCooldown   = false,
    FastRun      = false,
    WalkSpeed    = 60,
    HighJump     = false,
    JumpPower    = 100,
    Noclip       = false,
}

local attackRemote = nil
local function FindAttackRemote()
    local rs = game:GetService("ReplicatedStorage")
    local found = rs:FindFirstChild(REMOTE_ATTACK, true)
    if not found then
        found = game:FindFirstChild(REMOTE_ATTACK, true)
    end
    return found
end

local lastAttack = 0
local ATTACK_RATE = 0.1

local function TickAutoAttack()
    if not CONFIG.AutoAttack then return end
    local _, myRoot, myHum = GetChar()
    if not myRoot or not myHum or myHum.Health <= 0 then return end

    if not attackRemote then
        attackRemote = FindAttackRemote()
    end

    local now = tick()
    if now - lastAttack < ATTACK_RATE then return end
    lastAttack = now

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP or not plr.Character then continue end
        local hum  = plr.Character:FindFirstChildOfClass("Humanoid")
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then continue end

        local dist = (root.Position - myRoot.Position).Magnitude
        if dist > CONFIG.AttackRange then continue end

        if attackRemote and attackRemote:IsA("RemoteEvent") then
            pcall(function()
                attackRemote:FireServer(plr.Character, root.Position)
            end)
        end

        local char = GetChar()
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local re = tool:FindFirstChildWhichIsA("RemoteEvent", true)
                if re then
                    pcall(function() re:FireServer(root.Position) end)
                end
            end
        end
    end
end

local noCDHooked = false
local function HookNoCooldown()
    if noCDHooked then return end
    noCDHooked = true
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if CONFIG.NoCooldown and typeof(self) == "Instance" then
            if (m == "FireServer" or m == "InvokeServer") then
                local name = self.Name
                if string.find(name:lower(), "skill")
                or string.find(name:lower(), "attack")
                or string.find(name:lower(), "ability")
                or string.find(name:lower(), "power")
                or name == REMOTE_SKILL then
                    pcall(function() old(self, ...) end)
                    return old(self, ...)
                end
            end
        end
        return old(self, ...)
    end)
end
pcall(HookNoCooldown)

local wsConn = nil
local function ApplyWS()
    local _, _, hum = GetChar()
    if hum then pcall(function() hum.WalkSpeed = CONFIG.WalkSpeed end) end
end
local function StartFastRun()
    if wsConn then wsConn:Disconnect(); wsConn = nil end
    if not CONFIG.FastRun then
        local _, _, hum = GetChar()
        if hum then pcall(function() hum.WalkSpeed = 16 end) end
        return
    end
    ApplyWS()
    local _, _, hum = GetChar()
    if hum then
        wsConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if CONFIG.FastRun then task.defer(ApplyWS) end
        end)
    end
end

local jpConn   = nil
local ijConn   = nil
local function ApplyJP()
    local _, _, hum = GetChar()
    if not hum then return end
    pcall(function()
        hum.UseJumpPower = true
        hum.JumpPower    = CONFIG.JumpPower
    end)
end
local function StartHighJump()
    if jpConn then jpConn:Disconnect(); jpConn = nil end
    if ijConn then ijConn:Disconnect(); ijConn = nil end
    if not CONFIG.HighJump then
        local _, _, hum = GetChar()
        if hum then pcall(function() hum.JumpPower = 50 end) end
        return
    end
    ApplyJP()
    local _, _, hum = GetChar()
    if hum then
        jpConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if CONFIG.HighJump then task.defer(ApplyJP) end
        end)
    end
    ijConn = UserInputService.JumpRequest:Connect(function()
        if not CONFIG.HighJump then return end
        local _, _, hum2 = GetChar()
        if hum2 then hum2:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

local noclipConn = nil
local function StartNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if not CONFIG.Noclip then
        local char = GetChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() p.CanCollide = true end)
                end
            end
        end
        return
    end
    noclipConn = RunService.Stepped:Connect(function()
        if not CONFIG.Noclip then return end
        local char = GetChar()
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = false end)
            end
        end
    end)
end

local parentGui = (gethui and gethui()) or game:GetService("CoreGui")
local sg = Instance.new("ScreenGui")
sg.Name = "Ontoy_EPT"
sg.ResetOnSpawn = false
sg.Parent = parentGui

local C = {
    BG         = Color3.fromRGB(10, 12, 18),
    BG2        = Color3.fromRGB(16, 20, 28),
    Accent     = Color3.fromRGB(100, 60, 255),
    AccentDim  = Color3.fromRGB(60, 35, 160),
    AccentGlow = Color3.fromRGB(140, 100, 255),
    TextMain   = Color3.fromRGB(230, 225, 255),
    TextSub    = Color3.fromRGB(110, 100, 150),
    Stroke     = Color3.fromRGB(50, 40, 90),
    ToggleOff  = Color3.fromRGB(35, 30, 50),
    SliderFill = Color3.fromRGB(100, 60, 255),
    SliderBG   = Color3.fromRGB(28, 24, 45),
    Red        = Color3.fromRGB(255, 70, 70),
    Green      = Color3.fromRGB(50, 210, 100),
    Orange     = Color3.fromRGB(255, 160, 40),
}

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 500, 0, 440)
win.Position = UDim2.new(0.5, -250, 0.5, -220)
win.BackgroundColor3 = C.BG
win.BorderSizePixel = 0
win.Active = true
win.Draggable = false
win.Parent = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local ws = Instance.new("UIStroke", win)
ws.Color = C.Stroke
ws.Thickness = 1.5

local titleBar = Instance.new("Frame", win)
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = C.BG2
titleBar.BorderSizePixel = 0
titleBar.Active = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local drag, dragM, dragP = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true
        dragM = Vector2.new(i.Position.X, i.Position.Y)
        dragP = win.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = Vector2.new(i.Position.X, i.Position.Y) - dragM
        win.Position = UDim2.new(dragP.X.Scale, dragP.X.Offset+d.X, dragP.Y.Scale, dragP.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
end)

local al = Instance.new("Frame", titleBar)
al.Size = UDim2.new(1,0,0,2)
al.Position = UDim2.new(0,0,1,-2)
al.BackgroundColor3 = C.Accent
al.BorderSizePixel = 0

local dot = Instance.new("Frame", titleBar)
dot.Size = UDim2.new(0,8,0,8)
dot.Position = UDim2.new(0,14,0.5,-4)
dot.BackgroundColor3 = C.AccentGlow
dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(0,4)

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(1,-140,1,0)
titleLbl.Position = UDim2.new(0,30,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "ONTOY HUB  <font color='#6438FF'>·</font>  Elemental Powers Tycoon"
titleLbl.RichText = true
titleLbl.TextColor3 = C.TextMain
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 12
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local byLbl = Instance.new("TextLabel", titleBar)
byLbl.Size = UDim2.new(0,60,1,0)
byLbl.Position = UDim2.new(0,290,0,0)
byLbl.BackgroundTransparency = 1
byLbl.Text = "by ontoy"
byLbl.TextColor3 = C.TextSub
byLbl.Font = Enum.Font.Gotham
byLbl.TextSize = 11
byLbl.TextXAlignment = Enum.TextXAlignment.Left

local function WinBtn(xOff, bg, txt)
    local b = Instance.new("TextButton", titleBar)
    b.Size = UDim2.new(0,26,0,26)
    b.Position = UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3 = bg
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end
local closeBtn = WinBtn(-34, C.Red, "✕")
local minBtn   = WinBtn(-66, C.ToggleOff, "—")

local sidebar = Instance.new("Frame", win)
sidebar.Size = UDim2.new(0,130,1,-42)
sidebar.Position = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = C.BG2
sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", sidebar).Color = C.Stroke
local sbl = Instance.new("UIListLayout", sidebar)
sbl.Padding = UDim.new(0,3)
sbl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0,12)

local cArea = Instance.new("Frame", win)
cArea.Size = UDim2.new(1,-138,1,-50)
cArea.Position = UDim2.new(0,134,0,46)
cArea.BackgroundTransparency = 1
cArea.BorderSizePixel = 0

local scroll = Instance.new("ScrollingFrame", cArea)
scroll.Size = UDim2.new(1,0,1,0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C.AccentDim
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local scl = Instance.new("UIListLayout", scroll)
scl.Padding = UDim.new(0,6)
scl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", scroll).PaddingTop = UDim.new(0,8)

local pages, sideBtns = {}, {}

local function MakePage()
    local pg = Instance.new("Frame", scroll)
    pg.Size = UDim2.new(1,0,0,0)
    pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1
    pg.BorderSizePixel = 0
    pg.Visible = false
    local l = Instance.new("UIListLayout", pg)
    l.Padding = UDim.new(0,6)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Instance.new("UIPadding", pg).PaddingBottom = UDim.new(0,8)
    return pg
end

local function MakeSideBtn(icon, label, id)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1,-14,0,38)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    local bar = Instance.new("Frame", btn)
    bar.Size = UDim2.new(0,3,0.6,0)
    bar.Position = UDim2.new(0,0,0.2,0)
    bar.BackgroundColor3 = C.Accent
    bar.BorderSizePixel = 0
    bar.Visible = false
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,2)
    local ic = Instance.new("TextLabel", btn)
    ic.Size = UDim2.new(0,22,1,0)
    ic.Position = UDim2.new(0,10,0,0)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.TextColor3 = C.TextSub
    ic.Font = Enum.Font.GothamBold
    ic.TextSize = 14
    local lb = Instance.new("TextLabel", btn)
    lb.Size = UDim2.new(1,-38,1,0)
    lb.Position = UDim2.new(0,36,0,0)
    lb.BackgroundTransparency = 1
    lb.Text = label
    lb.TextColor3 = C.TextSub
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 12
    lb.TextXAlignment = Enum.TextXAlignment.Left
    sideBtns[id] = {btn=btn, icon=ic, label=lb, bar=bar}
    return btn
end

local function SetPage(id)
    for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
    for bid, sb in pairs(sideBtns) do
        local a = (bid == id)
        sb.btn.BackgroundTransparency = a and 0 or 1
        sb.btn.BackgroundColor3 = a and Color3.fromRGB(18,14,34) or C.ToggleOff
        sb.icon.TextColor3 = a and C.AccentGlow or C.TextSub
        sb.label.TextColor3 = a and C.TextMain or C.TextSub
        sb.bar.Visible = a
    end
end

local function SecLabel(parent, text, color)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1,-8,0,18)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or C.Accent
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function Toggle(parent, label, sub, ac)
    ac = ac or C.Accent
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,52)
    row.BackgroundColor3 = C.BG2
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", row)
    stroke.Color = C.Stroke
    stroke.Thickness = 1
    local tll = Instance.new("TextLabel", row)
    tll.Size = UDim2.new(1,-60,0,22)
    tll.Position = UDim2.new(0,14,0,8)
    tll.BackgroundTransparency = 1
    tll.Text = label
    tll.TextColor3 = C.TextMain
    tll.Font = Enum.Font.GothamBold
    tll.TextSize = 12
    tll.TextXAlignment = Enum.TextXAlignment.Left
    if sub then
        local s = Instance.new("TextLabel", row)
        s.Size = UDim2.new(1,-60,0,16)
        s.Position = UDim2.new(0,14,0,28)
        s.BackgroundTransparency = 1
        s.Text = sub
        s.TextColor3 = C.TextSub
        s.Font = Enum.Font.Gotham
        s.TextSize = 10
        s.TextXAlignment = Enum.TextXAlignment.Left
    end
    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(0,36,0,20)
    bg.Position = UDim2.new(1,-48,0.5,-10)
    bg.BackgroundColor3 = C.ToggleOff
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,10)
    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3 = C.TextSub
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
    local btn = Instance.new("TextButton", bg)
    btn.Size = UDim2.new(1,8,1,8)
    btn.Position = UDim2.new(0,-4,0,-4)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    local state = false
    local function Set(s)
        state = s
        if s then
            bg.BackgroundColor3 = ac
            knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            knob.Position = UDim2.new(1,-17,0.5,-7)
            row.BackgroundColor3 = Color3.fromRGB(14,10,28)
            stroke.Color = C.AccentDim
        else
            bg.BackgroundColor3 = C.ToggleOff
            knob.BackgroundColor3 = C.TextSub
            knob.Position = UDim2.new(0,3,0.5,-7)
            row.BackgroundColor3 = C.BG2
            stroke.Color = C.Stroke
        end
    end
    btn.MouseButton1Click:Connect(function() Set(not state) end)
    return row, function() return state end, Set
end

local function Slider(parent, label, sub, dMin, dMax, initVal, unit, onChange)
    local initPct = (initVal - dMin) / (dMax - dMin)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,72)
    row.BackgroundColor3 = C.BG2
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", row).Color = C.Stroke
    local tll = Instance.new("TextLabel", row)
    tll.Size = UDim2.new(1,-80,0,20)
    tll.Position = UDim2.new(0,14,0,8)
    tll.BackgroundTransparency = 1
    tll.Text = label
    tll.TextColor3 = C.TextMain
    tll.Font = Enum.Font.GothamBold
    tll.TextSize = 12
    tll.TextXAlignment = Enum.TextXAlignment.Left
    if sub then
        local s = Instance.new("TextLabel", row)
        s.Size = UDim2.new(1,-80,0,14)
        s.Position = UDim2.new(0,14,0,26)
        s.BackgroundTransparency = 1
        s.Text = sub
        s.TextColor3 = C.TextSub
        s.Font = Enum.Font.Gotham
        s.TextSize = 10
        s.TextXAlignment = Enum.TextXAlignment.Left
    end
    local vl = Instance.new("TextLabel", row)
    vl.Size = UDim2.new(0,70,0,20)
    vl.Position = UDim2.new(1,-78,0,8)
    vl.BackgroundTransparency = 1
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 12
    vl.TextColor3 = C.AccentGlow
    vl.TextXAlignment = Enum.TextXAlignment.Right
    local sbg = Instance.new("Frame", row)
    sbg.Size = UDim2.new(1,-28,0,5)
    sbg.Position = UDim2.new(0,14,0,50)
    sbg.BackgroundColor3 = C.SliderBG
    sbg.BorderSizePixel = 0
    Instance.new("UICorner", sbg).CornerRadius = UDim.new(0,3)
    local hit = Instance.new("TextButton", sbg)
    hit.Size = UDim2.new(1,0,0,28)
    hit.Position = UDim2.new(0,0,0.5,-14)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.BorderSizePixel = 0
    hit.ZIndex = 5
    local fill = Instance.new("Frame", sbg)
    fill.Size = UDim2.new(initPct,0,1,0)
    fill.BackgroundColor3 = C.SliderFill
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)
    local knob = Instance.new("Frame", sbg)
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = UDim2.new(initPct,-7,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke", knob).Color = C.Accent
    local dragS = false
    local function Compute(px)
        local pct = math.clamp((px - sbg.AbsolutePosition.X)/sbg.AbsoluteSize.X, 0, 1)
        return pct, math.floor(dMin + (dMax-dMin)*pct)
    end
    local function Apply(pct, val)
        fill.Size = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,-7,0.5,-7)
        vl.Text = val..(unit or "")
        if onChange then onChange(val) end
    end
    Apply(initPct, initVal)
    hit.MouseButton1Down:Connect(function() dragS = true end)
    UserInputService.InputChanged:Connect(function(i)
        if dragS and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local p,v = Compute(i.Position.X)
            Apply(p,v)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragS = false end
    end)
    hit.MouseButton1Click:Connect(function()
        local m = UserInputService:GetMouseLocation()
        local p,v = Compute(m.X)
        Apply(p,v)
    end)
end

local pgCombat = MakePage(); pages["combat"]   = pgCombat
local pgMove   = MakePage(); pages["movement"] = pgMove
local pgMisc   = MakePage(); pages["misc"]     = pgMisc

local sbCombat = MakeSideBtn("⚔",  "Combat",   "combat")
local sbMove   = MakeSideBtn("🏃", "Movement", "movement")
local sbMisc   = MakeSideBtn("⚙",  "Misc",     "misc")

SecLabel(pgCombat, "KILL AURA", C.Orange)
local _, aaGet, _ = Toggle(pgCombat, "Auto Attack", "Fire RemoteEvent serangan ke player dalam range", C.Orange)
Slider(pgCombat, "Attack Range", "Radius kill aura (stud)", 5, 100, CONFIG.AttackRange, " stud", function(v)
    CONFIG.AttackRange = v
end)

SecLabel(pgCombat, "SKILL", C.Accent)
local _, ncGet, _ = Toggle(pgCombat, "No Cooldown", "Namecall hook — bypass cooldown skill/ability", C.Accent)

SecLabel(pgMove, "WALK SPEED")
local _, frGet, _ = Toggle(pgMove, "Fast Run", "WalkSpeed lock — reset-proof")
Slider(pgMove, "Walk Speed", "Default: 16, Max: 300", 16, 300, CONFIG.WalkSpeed, " stud/s", function(v)
    CONFIG.WalkSpeed = v
    if CONFIG.FastRun then ApplyWS() end
end)

SecLabel(pgMove, "JUMP")
local _, hjGet, _ = Toggle(pgMove, "High Jump", "JumpPower lock + JumpRequest hook")
Slider(pgMove, "Jump Power", "Default: 50, Max: 300", 50, 300, CONFIG.JumpPower, "", function(v)
    CONFIG.JumpPower = v
    if CONFIG.HighJump then ApplyJP() end
end)

SecLabel(pgMisc, "MOVEMENT HACK")
local _, ncClipGet, _ = Toggle(pgMisc, "Noclip", "RunService.Stepped — CanCollide false tiap frame", C.Green)

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

Wire(aaGet,     "AutoAttack")
Wire(ncGet,     "NoCooldown")
Wire(frGet,     "FastRun",      StartFastRun, StartFastRun)
Wire(hjGet,     "HighJump",     StartHighJump, StartHighJump)
Wire(ncClipGet, "Noclip",       StartNoclip, StartNoclip)

sbCombat.MouseButton1Click:Connect(function() SetPage("combat")   end)
sbMove.MouseButton1Click:Connect(function()   SetPage("movement") end)
sbMisc.MouseButton1Click:Connect(function()   SetPage("misc")     end)
SetPage("combat")

local vis = true
minBtn.MouseButton1Click:Connect(function()
    vis = not vis
    sidebar.Visible = vis; cArea.Visible = vis
    win.Size = vis and UDim2.new(0,500,0,440) or UDim2.new(0,500,0,42)
end)
closeBtn.MouseButton1Click:Connect(function()
    CONFIG.AutoAttack = false; CONFIG.NoCooldown = false
    CONFIG.FastRun = false; CONFIG.HighJump = false; CONFIG.Noclip = false
    local _, _, hum = GetChar()
    if hum then pcall(function()
        hum.WalkSpeed = 16; hum.JumpPower = 50
    end) end
    if wsConn   then wsConn:Disconnect()   end
    if jpConn   then jpConn:Disconnect()   end
    if ijConn   then ijConn:Disconnect()   end
    if noclipConn then noclipConn:Disconnect() end
    local char = GetChar()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
    end
    sg:Destroy()
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    attackRemote = nil
    if CONFIG.FastRun  then StartFastRun()  end
    if CONFIG.HighJump then StartHighJump() end
    if CONFIG.Noclip   then StartNoclip()   end
end)

RunService.Heartbeat:Connect(function()
    TickAutoAttack()
end)
