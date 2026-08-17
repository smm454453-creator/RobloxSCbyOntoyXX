local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace      = game:GetService("Workspace")
local Camera         = Workspace.CurrentCamera

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")

local function GetChar()
	local c = LP.Character
	if not c then return nil, nil, nil end
	local r = c:FindFirstChild("HumanoidRootPart")
	local h = c:FindFirstChildOfClass("Humanoid")
	return c, r, h
end

local CONFIG = {
	SilentAim       = false,
	TargetBone      = "Head",
	SilentAimFOV    = 120,
	NoRecoil        = false,
	VehicleSpeed    = false,
	VehicleSpeedVal = 300,
	FastRun         = false,
	WalkSpeed       = 16,
	HighJump        = false,
	JumpPower       = 50,
	ESP             = false,
	Tracers         = false,
    -- [ NEW FEATURE ] Setup Config Baru
	InfAmmo         = false,
	Noclip          = false,
	AntiRagdoll     = false,
	AntiArrest      = false,
}

-- ============================================================
-- SILENT AIM: hook universal di __namecall
-- ============================================================
local function GetBestTarget()
	local vp   = Camera.ViewportSize
	local cx   = vp.X / 2
	local cy   = vp.Y / 2
	local fov  = CONFIG.SilentAimFOV
	local best, bestD = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		local pc = p.Character
		if not pc then continue end
		local bone = pc:FindFirstChild(CONFIG.TargetBone) or pc:FindFirstChild("HumanoidRootPart")
		local hum  = pc:FindFirstChildOfClass("Humanoid")
		if not (bone and hum and hum.Health > 0) then continue end
		local sc, on = Camera:WorldToViewportPoint(bone.Position)
		if not on then continue end
		local d = math.sqrt((sc.X-cx)^2 + (sc.Y-cy)^2)
		if d < fov and d < bestD then bestD = d; best = bone end
	end
	return best
end

local hooked = false
local function HookNamecall()
	if hooked then return end
	hooked = true
	local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
		if not CONFIG.SilentAim then return old(self, ...) end
		local m    = getnamecallmethod()
		local bone = GetBestTarget()
		if not (bone and bone.Parent) then return old(self, ...) end

		local bPos = bone.Position
		local camP = Camera.CFrame.Position
		local dir  = (bPos - camP).Unit

		if m == "FireServer" or m == "InvokeServer" or m == "Fire" then
			local args = {...}
			for i, v in ipairs(args) do
				if typeof(v) == "Instance" and v:IsA("BasePart") then
					args[i] = bone
				elseif typeof(v) == "Ray" then
					args[i] = Ray.new(camP, dir * 1000)
				elseif typeof(v) == "CFrame" then
					args[i] = CFrame.new(bPos)
				elseif typeof(v) == "Vector3" then
					args[i] = bPos
				end
			end
			return old(self, table.unpack(args))
		end

		if m == "Raycast" and self == Workspace then
			return old(self, camP, dir * 1000, select(3, ...))
		end

		if m == "FindPartOnRay"
		or m == "FindPartOnRayWithIgnoreList"
		or m == "FindPartOnRayWithWhitelist" then
			local args = {...}
			args[1] = Ray.new(camP, dir * 1000)
			return old(self, table.unpack(args))
		end

		return old(self, ...)
	end)
end
pcall(HookNamecall)

local function TickSilentAim()
	if not CONFIG.SilentAim then return end
	local bone = GetBestTarget()
	if not (bone and bone.Parent) then return end
	local camP = Camera.CFrame.Position
	local dir  = (bone.Position - camP).Unit
	Camera.CFrame = CFrame.new(camP, camP + dir)
end

-- ============================================================
-- AUTO ESCAPE
-- ============================================================
local POLICE_GATE = CFrame.new(-1135, 18, -1370)

local function DoEscape()
	local _, root, hum = GetChar()
	if not (root and hum and hum.Health > 0) then return end
	root.CFrame = POLICE_GATE
end

-- ============================================================
-- VEHICLE SPEED
-- ============================================================
local wHeld = false
UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.W then wHeld = true end
end)
UserInputService.InputEnded:Connect(function(inp)
	if inp.KeyCode == Enum.KeyCode.W then wHeld = false end
end)

local function GetOccupiedVehicle()
	local _, _, hum = GetChar()
	if not hum then return nil, nil end
	local seat = hum.SeatPart
	if not (seat and seat:IsA("VehicleSeat")) then return nil, nil end
	local car = seat.Parent
	local primary = (car and car.PrimaryPart) or seat
	return seat, primary
end

RunService.Heartbeat:Connect(function()
	if not (CONFIG.VehicleSpeed and wHeld) then return end
	local seat, primary = GetOccupiedVehicle()
	if not (seat and primary) then return end
	pcall(function()
		primary.AssemblyLinearVelocity = primary.CFrame.LookVector * CONFIG.VehicleSpeedVal
	end)
end)

-- ============================================================
-- FAST RUN
-- ============================================================
local wsConn = nil
local function ApplyWS()
	local _, _, hum = GetChar()
	if hum then pcall(function() hum.WalkSpeed = CONFIG.WalkSpeed end) end
end
local function StartFastRun()
	if wsConn then wsConn:Disconnect() wsConn = nil end
	if not CONFIG.FastRun then ApplyWS() return end
	ApplyWS()
	local _, _, hum = GetChar()
	if hum then
		wsConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if CONFIG.FastRun then task.defer(ApplyWS) end
		end)
	end
end

-- ============================================================
-- HIGH JUMP
-- ============================================================
local jpConn   = nil
local fallConn = nil
local function ApplyJP()
	local _, _, hum = GetChar()
	if not hum then return end
	pcall(function()
		hum.UseJumpPower = true
		hum.JumpPower    = CONFIG.JumpPower
	end)
end
local function StartHighJump()
	if jpConn   then jpConn:Disconnect()   jpConn   = nil end
	if fallConn then fallConn:Disconnect() fallConn = nil end
	if not CONFIG.HighJump then ApplyJP() return end
	ApplyJP()
	local _, _, hum = GetChar()
	if hum then
		jpConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
			if CONFIG.HighJump then task.defer(ApplyJP) end
		end)
	end
	fallConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.HighJump then return end
		local _, root = GetChar()
		if not root then return end
		local vel = root.AssemblyLinearVelocity
		if vel.Y < -80 then
			pcall(function()
				root.AssemblyLinearVelocity = Vector3.new(vel.X, -80, vel.Z)
			end)
		end
	end)
end

-- ============================================================
-- ESP
-- ============================================================
local ESP_HL  = {}
local ESP_LBL = {}
local ESP_TR  = {}

local function ESPColor(p)
	local t = string.lower(p.Team and p.Team.Name or "")
	if t:find("police") then return Color3.fromRGB(50,100,255), Color3.fromRGB(0,40,180) end
	if t:find("crim")   then return Color3.fromRGB(255,50,50),  Color3.fromRGB(140,0,0)  end
	return Color3.fromRGB(200,200,200), Color3.fromRGB(80,80,80)
end

local function MakeHL(p)
	if ESP_HL[p] then return end
	local pc = p.Character; if not pc then return end
	local fill, out = ESPColor(p)
	local hl = Instance.new("Highlight")
	hl.FillColor = fill; hl.OutlineColor = out
	hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = pc; hl.Parent = pc
	ESP_HL[p] = hl
	if not ESP_LBL[p] then
		local lbl = Drawing.new("Text")
		lbl.Size = 13; lbl.Center = true
		lbl.Outline = true; lbl.OutlineColor = Color3.new(0,0,0)
		lbl.Visible = false
		ESP_LBL[p] = lbl
	end
end

local function RemoveHL(p)
	if ESP_HL[p]  then pcall(function() ESP_HL[p]:Destroy() end); ESP_HL[p] = nil end
	if ESP_LBL[p] then ESP_LBL[p]:Remove(); ESP_LBL[p] = nil end
	if ESP_TR[p]  then ESP_TR[p]:Remove();  ESP_TR[p]  = nil end
end

local function UpdateESP()
	local _, myRoot = GetChar()
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		local pc    = p.Character
		local proot = pc and pc:FindFirstChild("HumanoidRootPart")
		local phum  = pc and pc:FindFirstChildOfClass("Humanoid")
		local lbl   = ESP_LBL[p]
		local tr    = ESP_TR[p]
		if not (proot and phum and phum.Health > 0) then
			if lbl then lbl.Visible = false end
			if tr  then tr.Visible  = false end
			continue
		end
		local sc, on = Camera:WorldToViewportPoint(proot.Position)
		local fill, _ = ESPColor(p)
		if lbl then
			if on and myRoot then
				local dist = math.floor((myRoot.Position - proot.Position).Magnitude)
				lbl.Position = Vector2.new(sc.X, sc.Y - 26)
				lbl.Text     = p.Name .. " [" .. dist .. "s]"
				lbl.Color    = fill
				lbl.Visible  = true
			else
				lbl.Visible = false
			end
		end
		if CONFIG.Tracers then
			local vp = Camera.ViewportSize
			if not tr then
				tr = Drawing.new("Line")
				tr.Thickness = 1
				ESP_TR[p] = tr
			end
			if on then
				tr.From    = Vector2.new(vp.X/2, vp.Y)
				tr.To      = Vector2.new(sc.X, sc.Y)
				tr.Color   = fill
				tr.Visible = true
			else
				tr.Visible = false
			end
		elseif tr then
			tr.Visible = false
		end
	end
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		if CONFIG.ESP then MakeHL(p) end
	end)
end)
Players.PlayerRemoving:Connect(RemoveHL)
for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LP then
		p.CharacterAdded:Connect(function()
			task.wait(0.5)
			if CONFIG.ESP then MakeHL(p) end
		end)
	end
end

local fovCircle       = Drawing.new("Circle")
fovCircle.Filled      = false
fovCircle.Thickness   = 1
fovCircle.Color       = Color3.fromRGB(255,60,80)
fovCircle.Visible     = false

-- ============================================================
-- GUI SETUP
-- ============================================================
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

local sg = Instance.new("ScreenGui")
sg.Name = "OntoyJB"; sg.ResetOnSpawn = false; sg.Parent = PG

local win = Instance.new("Frame", sg)
win.Size = UDim2.new(0,580,0,420)
win.Position = UDim2.new(0.5,-290,0.5,-210)
win.BackgroundColor3 = REDZ.BG
win.BorderSizePixel = 0; win.Active = true
Instance.new("UICorner", win).CornerRadius = UDim.new(0,10)
local ws = Instance.new("UIStroke", win); ws.Color = REDZ.Stroke; ws.Thickness = 1.5

local titleBar = Instance.new("Frame", win)
titleBar.Size = UDim2.new(1,0,0,42)
titleBar.BackgroundColor3 = REDZ.BG2
titleBar.BorderSizePixel = 0; titleBar.Active = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local dragging, dStart, dPos = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true; dStart = Vector2.new(inp.Position.X,inp.Position.Y); dPos = win.Position
	end
end)
UserInputService.InputChanged:Connect(function(inp)
	if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
		local d = Vector2.new(inp.Position.X,inp.Position.Y) - dStart
		win.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X, dPos.Y.Scale, dPos.Y.Offset+d.Y)
	end
end)
UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local acLine = Instance.new("Frame", titleBar)
acLine.Size = UDim2.new(1,0,0,2); acLine.Position = UDim2.new(0,0,1,-2)
acLine.BackgroundColor3 = REDZ.Accent; acLine.BorderSizePixel = 0

local dot = Instance.new("Frame", titleBar)
dot.Size = UDim2.new(0,8,0,8); dot.Position = UDim2.new(0,14,0.5,-4)
dot.BackgroundColor3 = REDZ.AccentGlow; dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(0,4)

local tTxt = Instance.new("TextLabel", titleBar)
tTxt.Size = UDim2.new(1,-160,1,0); tTxt.Position = UDim2.new(0,30,0,0)
tTxt.BackgroundTransparency = 1
tTxt.Text = "ONTOY HUB  <font color='#C81E32'>·</font>  Jailbreak"
tTxt.RichText = true; tTxt.TextColor3 = REDZ.TextMain
tTxt.Font = Enum.Font.GothamBold; tTxt.TextSize = 13
tTxt.TextXAlignment = Enum.TextXAlignment.Left

local byL = Instance.new("TextLabel", titleBar)
byL.Size = UDim2.new(0,80,1,0); byL.Position = UDim2.new(0,195,0,0)
byL.BackgroundTransparency = 1; byL.Text = "by ontoy"
byL.TextColor3 = REDZ.TextSub; byL.Font = Enum.Font.Gotham
byL.TextSize = 11; byL.TextXAlignment = Enum.TextXAlignment.Left

local function WinBtn(xOff, bg, txt)
	local b = Instance.new("TextButton", titleBar)
	b.Size = UDim2.new(0,26,0,26); b.Position = UDim2.new(1,xOff,0.5,-13)
	b.BackgroundColor3 = bg; b.Text = txt
	b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold
	b.TextSize = 11; b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
	return b
end
local closeBtn = WinBtn(-34, REDZ.Accent, "✕")
local minBtn   = WinBtn(-66, REDZ.ToggleOff, "—")

local sidebar = Instance.new("Frame", win)
sidebar.Size = UDim2.new(0,148,1,-42); sidebar.Position = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = REDZ.BG2; sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", sidebar).Color = REDZ.Stroke
local sbl = Instance.new("UIListLayout", sidebar)
sbl.Padding = UDim.new(0,3); sbl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0,12)

local cArea = Instance.new("Frame", win)
cArea.Size = UDim2.new(1,-156,1,-50); cArea.Position = UDim2.new(0,152,0,46)
cArea.BackgroundTransparency = 1; cArea.BorderSizePixel = 0

local cScroll = Instance.new("ScrollingFrame", cArea)
cScroll.Size = UDim2.new(1,0,1,0); cScroll.BackgroundTransparency = 1
cScroll.BorderSizePixel = 0; cScroll.ScrollBarThickness = 3
cScroll.ScrollBarImageColor3 = REDZ.AccentDim
cScroll.CanvasSize = UDim2.new(0,0,0,0)
cScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local cLayout = Instance.new("UIListLayout", cScroll)
cLayout.Padding = UDim.new(0,6); cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", cScroll).PaddingTop = UDim.new(0,8)

local pages   = {}
local sideBtns= {}

local function MakePage()
	local pg = Instance.new("Frame", cScroll)
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
	bar.BackgroundColor3 = REDZ.Accent; bar.BorderSizePixel = 0; bar.Visible = false
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0,2)
	local ic = Instance.new("TextLabel", btn)
	ic.Size = UDim2.new(0,22,1,0); ic.Position = UDim2.new(0,10,0,0)
	ic.BackgroundTransparency = 1; ic.Text = icon
	ic.TextColor3 = REDZ.TextSub; ic.Font = Enum.Font.GothamBold; ic.TextSize = 14
	local lb = Instance.new("TextLabel", btn)
	lb.Size = UDim2.new(1,-38,1,0); lb.Position = UDim2.new(0,36,0,0)
	lb.BackgroundTransparency = 1; lb.Text = label
	lb.TextColor3 = REDZ.TextSub; lb.Font = Enum.Font.Gotham; lb.TextSize = 12
	lb.TextXAlignment = Enum.TextXAlignment.Left
	sideBtns[id] = {btn=btn,ic=ic,lb=lb,bar=bar}
	return btn
end

local function SetPage(id)
	for pid, pg in pairs(pages) do pg.Visible = (pid==id) end
	for bid, sb in pairs(sideBtns) do
		local a = (bid==id)
		sb.btn.BackgroundTransparency = a and 0 or 1
		sb.btn.BackgroundColor3       = a and Color3.fromRGB(30,18,22) or REDZ.ToggleOff
		sb.ic.TextColor3              = a and REDZ.AccentGlow or REDZ.TextSub
		sb.lb.TextColor3              = a and REDZ.TextMain   or REDZ.TextSub
		sb.bar.Visible                = a
	end
end

local function SecLabel(parent, txt)
	local l = Instance.new("TextLabel", parent)
	l.Size = UDim2.new(1,-8,0,18); l.BackgroundTransparency = 1
	l.Text = txt; l.TextColor3 = REDZ.Accent
	l.Font = Enum.Font.GothamBold; l.TextSize = 10
	l.TextXAlignment = Enum.TextXAlignment.Left
	return l
end

local function Toggle(parent, label, sub)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local sk = Instance.new("UIStroke", row); sk.Color = REDZ.Stroke; sk.Thickness = 1
	local tl = Instance.new("TextLabel", row)
	tl.Size = UDim2.new(1,-60,0,22); tl.Position = UDim2.new(0,14,0,8)
	tl.BackgroundTransparency = 1; tl.Text = label
	tl.TextColor3 = REDZ.TextMain; tl.Font = Enum.Font.GothamBold; tl.TextSize = 12
	tl.TextXAlignment = Enum.TextXAlignment.Left
	if sub then
		local sl = Instance.new("TextLabel", row)
		sl.Size = UDim2.new(1,-60,0,16); sl.Position = UDim2.new(0,14,0,28)
		sl.BackgroundTransparency = 1; sl.Text = sub
		sl.TextColor3 = REDZ.TextSub; sl.Font = Enum.Font.Gotham; sl.TextSize = 10
		sl.TextXAlignment = Enum.TextXAlignment.Left
	end
	local tbg = Instance.new("Frame", row)
	tbg.Size = UDim2.new(0,36,0,20); tbg.Position = UDim2.new(1,-48,0.5,-10)
	tbg.BackgroundColor3 = REDZ.ToggleOff; tbg.BorderSizePixel = 0
	Instance.new("UICorner", tbg).CornerRadius = UDim.new(0,10)
	local knob = Instance.new("Frame", tbg)
	knob.Size = UDim2.new(0,14,0,14); knob.Position = UDim2.new(0,3,0.5,-7)
	knob.BackgroundColor3 = REDZ.TextSub; knob.BorderSizePixel = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
	local tb = Instance.new("TextButton", tbg)
	tb.Size = UDim2.new(1,8,1,8); tb.Position = UDim2.new(0,-4,0,-4)
	tb.BackgroundTransparency = 1; tb.Text = ""; tb.BorderSizePixel = 0
	local state = false
	local function Set(s)
		state = s
		tbg.BackgroundColor3 = s and REDZ.Accent or REDZ.ToggleOff
		knob.BackgroundColor3 = s and Color3.new(1,1,1) or REDZ.TextSub
		knob.Position = s and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
		row.BackgroundColor3 = s and Color3.fromRGB(24,14,18) or REDZ.BG2
		sk.Color = s and REDZ.AccentDim or REDZ.Stroke
	end
	tb.MouseButton1Click:Connect(function() Set(not state) end)
	return row, function() return state end, Set
end

local function Slider(parent, label, mn, mx, pct0, unit, cb)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,-8,0,66); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local sk = Instance.new("UIStroke", row); sk.Color = REDZ.Stroke; sk.Thickness = 1
	local tl = Instance.new("TextLabel", row)
	tl.Size = UDim2.new(1,-80,0,20); tl.Position = UDim2.new(0,14,0,8)
	tl.BackgroundTransparency = 1; tl.Text = label
	tl.TextColor3 = REDZ.TextMain; tl.Font = Enum.Font.GothamBold; tl.TextSize = 12
	tl.TextXAlignment = Enum.TextXAlignment.Left
	local vl = Instance.new("TextLabel", row)
	vl.Size = UDim2.new(0,70,0,20); vl.Position = UDim2.new(1,-78,0,8)
	vl.BackgroundTransparency = 1; vl.Font = Enum.Font.GothamBold; vl.TextSize = 12
	vl.TextColor3 = REDZ.AccentGlow; vl.TextXAlignment = Enum.TextXAlignment.Right
	local sbg = Instance.new("Frame", row)
	sbg.Size = UDim2.new(1,-28,0,5); sbg.Position = UDim2.new(0,14,0,42)
	sbg.BackgroundColor3 = REDZ.SliderBG; sbg.BorderSizePixel = 0
	Instance.new("UICorner", sbg).CornerRadius = UDim.new(0,3)
	local hb = Instance.new("TextButton", sbg)
	hb.Size = UDim2.new(1,0,0,28); hb.Position = UDim2.new(0,0,0.5,-14)
	hb.BackgroundTransparency = 1; hb.Text = ""; hb.BorderSizePixel = 0; hb.ZIndex = 5
	local fill = Instance.new("Frame", sbg)
	fill.Size = UDim2.new(pct0,0,1,0); fill.BackgroundColor3 = REDZ.SliderFill; fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)
	local kn = Instance.new("Frame", sbg)
	kn.Size = UDim2.new(0,14,0,14); kn.Position = UDim2.new(pct0,-7,0.5,-7)
	kn.BackgroundColor3 = Color3.new(1,1,1); kn.BorderSizePixel = 0
	Instance.new("UICorner", kn).CornerRadius = UDim.new(0,7)
	local kr = Instance.new("UIStroke", kn); kr.Color = REDZ.Accent; kr.Thickness = 2
	local isd = false
	local function Compute(px)
		local bx = sbg.AbsolutePosition.X; local bw = sbg.AbsoluteSize.X
		local p  = math.clamp((px-bx)/bw, 0, 1)
		return p, math.floor(mn + (mx-mn)*p)
	end
	local function Apply(p, v)
		fill.Size = UDim2.new(p,0,1,0); kn.Position = UDim2.new(p,-7,0.5,-7)
		vl.Text = v..(unit or "")
		if cb then cb(v, p) end
	end
	Apply(pct0, math.floor(mn+(mx-mn)*pct0))
	hb.MouseButton1Down:Connect(function() isd = true end)
	UserInputService.InputChanged:Connect(function(inp)
		if isd and (inp.UserInputType == Enum.UserInputType.MouseMovement
			or inp.UserInputType == Enum.UserInputType.Touch) then
			Apply(Compute(inp.Position.X))
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then isd = false end
	end)
	hb.MouseButton1Click:Connect(function()
		Apply(Compute(UserInputService:GetMouseLocation().X))
	end)
	return row
end

local function ActionBtn(parent, label, sub, btnTxt, onClick)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,-8,0,62); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	Instance.new("UIStroke", row).Color = REDZ.Stroke
	local tl = Instance.new("TextLabel", row)
	tl.Size = UDim2.new(1,-120,0,22); tl.Position = UDim2.new(0,14,0,8)
	tl.BackgroundTransparency = 1; tl.Text = label
	tl.TextColor3 = REDZ.TextMain; tl.Font = Enum.Font.GothamBold; tl.TextSize = 12
	tl.TextXAlignment = Enum.TextXAlignment.Left
	if sub then
		local sl = Instance.new("TextLabel", row)
		sl.Size = UDim2.new(1,-120,0,16); sl.Position = UDim2.new(0,14,0,28)
		sl.BackgroundTransparency = 1; sl.Text = sub
		sl.TextColor3 = REDZ.TextSub; sl.Font = Enum.Font.Gotham; sl.TextSize = 10
		sl.TextXAlignment = Enum.TextXAlignment.Left
	end
	local btn = Instance.new("TextButton", row)
	btn.Size = UDim2.new(0,90,0,30); btn.Position = UDim2.new(1,-100,0.5,-15)
	btn.BackgroundColor3 = REDZ.Accent; btn.BorderSizePixel = 0
	btn.Text = btnTxt; btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
	btn.MouseButton1Click:Connect(onClick)
	return row
end

local function BoneCycle(parent)
	local bones = {"Head","HumanoidRootPart","Torso"}
	local idx = 1
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	Instance.new("UIStroke", row).Color = REDZ.Stroke
	local tl = Instance.new("TextLabel", row)
	tl.Size = UDim2.new(1,-120,0,22); tl.Position = UDim2.new(0,14,0,8)
	tl.BackgroundTransparency = 1; tl.Text = "Target Bone"
	tl.TextColor3 = REDZ.TextMain; tl.Font = Enum.Font.GothamBold; tl.TextSize = 12
	tl.TextXAlignment = Enum.TextXAlignment.Left
	local sl = Instance.new("TextLabel", row)
	sl.Size = UDim2.new(1,-120,0,16); sl.Position = UDim2.new(0,14,0,28)
	sl.BackgroundTransparency = 1; sl.Text = "Klik untuk ganti"
	sl.TextColor3 = REDZ.TextSub; sl.Font = Enum.Font.Gotham; sl.TextSize = 10
	sl.TextXAlignment = Enum.TextXAlignment.Left
	local cb = Instance.new("TextButton", row)
	cb.Size = UDim2.new(0,100,0,28); cb.Position = UDim2.new(1,-108,0.5,-14)
	cb.BackgroundColor3 = REDZ.AccentDim; cb.BorderSizePixel = 0
	cb.Text = bones[idx]; cb.TextColor3 = REDZ.AccentGlow
	cb.Font = Enum.Font.GothamBold; cb.TextSize = 11
	Instance.new("UICorner", cb).CornerRadius = UDim.new(0,6)
	cb.MouseButton1Click:Connect(function()
		idx = (idx % #bones) + 1
		CONFIG.TargetBone = bones[idx]; cb.Text = bones[idx]
	end)
	return row
end

-- PAGES
local pgEscape  = MakePage(); pages["escape"]   = pgEscape
local pgCombat  = MakePage(); pages["combat"]   = pgCombat
local pgVehicle = MakePage(); pages["vehicle"]  = pgVehicle
local pgMove    = MakePage(); pages["movement"] = pgMove
local pgESP     = MakePage(); pages["esp"]      = pgESP

local sbEscape  = MakeSideBtn("🔓","Escape","escape")
local sbCombat  = MakeSideBtn("⚔","Combat","combat")
local sbVehicle = MakeSideBtn("🚗","Vehicle","vehicle")
local sbMove    = MakeSideBtn("👟","Movement","movement")
local sbESP     = MakeSideBtn("👁","ESP","esp")

-- [ NEW FEATURE UI ] Escape page (Added Anti-Arrest toggle)
SecLabel(pgEscape, "DEFENSE")
local _, antiArrestGet, _ = Toggle(pgEscape, "Anti-Arrest", "Teleport ke atas kalau polisi dekat (<15 stud)")

SecLabel(pgEscape, "TELEPORT")
ActionBtn(pgEscape, "Escape to Police Gate",
	"Direct CFrame ke CFrame.new(-1135,18,-1370)",
	"Teleport", DoEscape)

-- [ NEW FEATURE UI ] Combat page (Added Inf Ammo toggle)
SecLabel(pgCombat, "SILENT AIM")
local _, silentGet, _ = Toggle(pgCombat, "Silent Aim",
	"Namecall hook: Fire/FireServer/Raycast → bone target")
BoneCycle(pgCombat)
Slider(pgCombat, "FOV Radius", 30, 400, (CONFIG.SilentAimFOV-30)/370, " px", function(v)
	CONFIG.SilentAimFOV = v; fovCircle.Radius = v
end)
SecLabel(pgCombat, "WEAPON")
local _, noRecoilGet, _ = Toggle(pgCombat, "No Recoil / No Spread",
	"Lock NumberValue recoil/spread di tool ke 0")
local _, infAmmoGet, _ = Toggle(pgCombat, "Infinite Ammo",
	"Set NumberValue ammo di tool ke 999")

-- Vehicle page
SecLabel(pgVehicle, "SPEED PUSH")
local _, vehicleGet, _ = Toggle(pgVehicle, "Vehicle Speed Push",
	"AssemblyLinearVelocity ke PrimaryPart saat W")
Slider(pgVehicle, "Push Speed", 50, 1000, (CONFIG.VehicleSpeedVal-50)/950, " stud/s", function(v)
	CONFIG.VehicleSpeedVal = v
end)

-- [ NEW FEATURE UI ] Movement page (Added Noclip & Anti-Ragdoll toggles)
SecLabel(pgMove, "HACKS")
local _, noclipGet, _ = Toggle(pgMove, "Noclip", "Jalan nembus tembok / BasePart collision off")
local _, antiRagdollGet, _ = Toggle(pgMove, "Anti-Ragdoll", "Mencegah karakter jatuh/PlatformStand")

SecLabel(pgMove, "WALK SPEED")
local _, fastRunGet, _ = Toggle(pgMove, "Fast Run",
	"GetPropertyChangedSignal — reset-proof")
Slider(pgMove, "Walk Speed", 16, 150, (CONFIG.WalkSpeed-16)/134, " stud/s", function(v)
	CONFIG.WalkSpeed = v
	if CONFIG.FastRun then ApplyWS() end
end)
SecLabel(pgMove, "JUMP POWER")
local _, highJumpGet, _ = Toggle(pgMove, "High Jump",
	"JumpPower lock + fall guard cap -80 stud/s")
Slider(pgMove, "Jump Power", 50, 300, (CONFIG.JumpPower-50)/250, "", function(v)
	CONFIG.JumpPower = v
	if CONFIG.HighJump then ApplyJP() end
end)

-- ESP page
SecLabel(pgESP, "WALLHACK")
local _, espGet, _    = Toggle(pgESP, "ESP Highlight",
	"Highlight + label jarak [Ns] — Biru=Police Merah=Crim")
local _, tracerGet, _ = Toggle(pgESP, "Tracers",
	"Drawing Line — cleanup per frame")

-- Wire toggles via Heartbeat diff check
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

Wire(silentGet,   "SilentAim",    nil, function() fovCircle.Visible = false end)
Wire(noRecoilGet, "NoRecoil", nil, nil)
-- [ NEW FEATURE WIRING ]
Wire(infAmmoGet, "InfAmmo", nil, nil)
Wire(noclipGet, "Noclip", nil, nil)
Wire(antiRagdollGet, "AntiRagdoll", nil, nil)
Wire(antiArrestGet, "AntiArrest", nil, nil)

Wire(vehicleGet,  "VehicleSpeed", nil, nil)
Wire(fastRunGet,  "FastRun",  StartFastRun, StartFastRun)
Wire(highJumpGet, "HighJump", StartHighJump, StartHighJump)
Wire(espGet, "ESP",
	function()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then MakeHL(p) end
		end
	end,
	function() for p in pairs(ESP_HL) do RemoveHL(p) end end
)
Wire(tracerGet, "Tracers", nil, function()
	for p, ln in pairs(ESP_TR) do ln:Remove(); ESP_TR[p] = nil end
end)

-- ============================================================
-- [ NEW FEATURE LOGIC ] 
-- ============================================================

-- Modifikasi Heartbeat NoRecoil biar sekalian ngurus Infinite Ammo
RunService.Heartbeat:Connect(function()
	local c = LP.Character; if not c then return end
	local tool = c:FindFirstChildOfClass("Tool"); if not tool then return end
	for _, v in ipairs(tool:GetDescendants()) do
		if v:IsA("NumberValue") or v:IsA("IntValue") then
			local n = string.lower(v.Name)
			-- No Recoil
			if CONFIG.NoRecoil and (n:find("recoil") or n:find("spread") or n:find("kick") or n:find("bloom")) then
				if v.Value ~= 0 then pcall(function() v.Value = 0 end) end
			end
			-- Infinite Ammo
			if CONFIG.InfAmmo and (n == "ammo" or n == "clip" or n == "mag" or n == "maxammo") then
				if v.Value < 999 then pcall(function() v.Value = 999 end) end
			end
		end
	end
end)

-- Noclip dijalankan di RenderStepped/Stepped biar Physics engine ga sempet nabrak
RunService.Stepped:Connect(function()
	if not CONFIG.Noclip then return end
	local c = LP.Character
	if c then
		for _, v in ipairs(c:GetDescendants()) do
			if v:IsA("BasePart") and v.CanCollide then
				v.CanCollide = false
			end
		end
	end
end)

-- Anti-Ragdoll 
RunService.Heartbeat:Connect(function()
	if not CONFIG.AntiRagdoll then return end
	local _, _, hum = GetChar()
	if hum then
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			if hum.PlatformStand then hum.PlatformStand = false end
		end)
	end
end)

-- Anti-Arrest 
RunService.Heartbeat:Connect(function()
	if not CONFIG.AntiArrest then return end
	local _, root, hum = GetChar()
	if not (root and hum and hum.Health > 0) then return end

	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		local t = string.lower(p.Team and p.Team.Name or "")
		if t:find("police") then
			local pc = p.Character
			local proot = pc and pc:FindFirstChild("HumanoidRootPart")
			local phum  = pc and pc:FindFirstChildOfClass("Humanoid")
			if proot and phum and phum.Health > 0 then
				local dist = (root.Position - proot.Position).Magnitude
				if dist < 15 then
					-- Lontarkan/teleport karakter lu ke atas setinggi 15 stud kalau jarak polisi < 15 stud
					root.CFrame = root.CFrame + Vector3.new(0, 15, 0)
				end
			end
		end
	end
end)


-- Sidebar clicks
sbEscape.MouseButton1Click:Connect(function()  SetPage("escape")   end)
sbCombat.MouseButton1Click:Connect(function()  SetPage("combat")   end)
sbVehicle.MouseButton1Click:Connect(function() SetPage("vehicle")  end)
sbMove.MouseButton1Click:Connect(function()    SetPage("movement") end)
sbESP.MouseButton1Click:Connect(function()     SetPage("esp")      end)
SetPage("combat")

local visible = true
minBtn.MouseButton1Click:Connect(function()
	visible = not visible
	sidebar.Visible = visible; cArea.Visible = visible
	win.Size = visible and UDim2.new(0,580,0,420) or UDim2.new(0,580,0,42)
end)

closeBtn.MouseButton1Click:Connect(function()
	CONFIG.SilentAim = false; CONFIG.NoRecoil = false
	CONFIG.VehicleSpeed = false; CONFIG.FastRun = false
	CONFIG.HighJump = false; CONFIG.ESP = false; CONFIG.Tracers = false
    -- [ NEW FEATURE CLEANUP ] Reset saat di-close
	CONFIG.InfAmmo = false; CONFIG.Noclip = false; 
	CONFIG.AntiRagdoll = false; CONFIG.AntiArrest = false;

	for p in pairs(ESP_HL)  do RemoveHL(p) end
	for p, ln in pairs(ESP_TR) do ln:Remove(); ESP_TR[p] = nil end
	if wsConn   then wsConn:Disconnect()   end
	if jpConn   then jpConn:Disconnect()   end
	if fallConn then fallConn:Disconnect() end
	fovCircle:Remove(); sg:Destroy()
end)

-- CharacterAdded reconnect
LP.CharacterAdded:Connect(function(char)
	local root = char:WaitForChild("HumanoidRootPart")
	local hum  = char:WaitForChild("Humanoid")
	if wsConn then wsConn:Disconnect() wsConn = nil end
	if jpConn then jpConn:Disconnect() jpConn = nil end
	task.wait(1)
	if CONFIG.ESP then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP and p.Character then MakeHL(p) end
		end
	end
	if CONFIG.FastRun  then StartFastRun()  end
	if CONFIG.HighJump then StartHighJump() end
end)

-- RenderStepped
local espTick = 0
RunService.RenderStepped:Connect(function()
	if CONFIG.SilentAim then
		TickSilentAim()
		local vp = Camera.ViewportSize
		fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
		fovCircle.Radius   = CONFIG.SilentAimFOV
		fovCircle.Visible  = true
	else
		fovCircle.Visible = false
	end
	local now = tick()
	if CONFIG.ESP and (now - espTick) >= 0.05 then
		espTick = now
		UpdateESP()
	elseif not CONFIG.ESP then
		for _, lbl in pairs(ESP_LBL) do lbl.Visible = false end
		for _, tr in pairs(ESP_TR)  do tr.Visible  = false end
	end
end)
