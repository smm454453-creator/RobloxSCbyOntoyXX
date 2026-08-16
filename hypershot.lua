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

local CONFIG = {
	SilentAim    = false,
	TargetBone   = "Head",
	SilentFOV    = 120,
	Smoothness   = 1,
	FastRun      = false,
	WalkSpeed    = 50,
	InfiniteJump = false,
	JumpPower    = 80,
	PlayerESP    = false,
	EnemyLineESP = false,
}

local function GetBestTarget()
	local vp = Camera.ViewportSize
	local cx, cy = vp.X / 2, vp.Y / 2
	local best, bestD = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LP then continue end
		local pc = p.Character
		if not pc then continue end
		local bone = pc:FindFirstChild(CONFIG.TargetBone) or pc:FindFirstChild("HumanoidRootPart")
		local hum  = pc:FindFirstChildOfClass("Humanoid")
		if not (bone and hum and hum.Health > 0) then continue end
		local sc, on = Camera:WorldToViewportPoint(bone.Position)
		local d = math.sqrt((sc.X - cx)^2 + (sc.Y - cy)^2)
		if (on or sc.Z > 0) and d < CONFIG.SilentFOV and d < bestD then
			bestD = d
			best  = bone
		end
	end
	if not best then
		for _, p in ipairs(Players:GetPlayers()) do
			if p == LP then continue end
			local pc = p.Character
			if not pc then continue end
			local bone = pc:FindFirstChild(CONFIG.TargetBone) or pc:FindFirstChild("HumanoidRootPart")
			local hum  = pc:FindFirstChildOfClass("Humanoid")
			if not (bone and hum and hum.Health > 0) then continue end
			local sc = Camera:WorldToViewportPoint(bone.Position)
			if sc.Z > 0 then
				local d = math.sqrt((sc.X - cx)^2 + (sc.Y - cy)^2)
				if d < bestD then bestD = d best = bone end
			end
		end
	end
	return best
end

local namecallHooked = false
local function HookNamecall()
	if namecallHooked then return end
	namecallHooked = true
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
					args[i] = Ray.new(camP, dir * 5000)
				elseif typeof(v) == "CFrame" then
					args[i] = CFrame.new(bPos)
				elseif typeof(v) == "Vector3" then
					args[i] = bPos
				end
			end
			return old(self, table.unpack(args))
		end
		if m == "Raycast" and self == Workspace then
			local params = select(3, ...)
			return old(self, camP, dir * 5000, params)
		end
		if m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList" or m == "FindPartOnRayWithWhitelist" then
			local args = {...}
			args[1] = Ray.new(camP, dir * 5000)
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
	local camP    = Camera.CFrame.Position
	local dir     = (bone.Position - camP).Unit
	local targetCF = CFrame.new(camP, camP + dir)
	local smooth   = math.clamp(CONFIG.Smoothness, 1, 30)
	Camera.CFrame  = Camera.CFrame:Lerp(targetCF, 1 / smooth)
end

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

local jpConn = nil
local ijConn = nil
local function ApplyJP()
	local _, _, hum = GetChar()
	if not hum then return end
	pcall(function()
		hum.UseJumpPower = true
		hum.JumpPower    = CONFIG.JumpPower
	end)
end
local function StartInfiniteJump()
	if jpConn then jpConn:Disconnect(); jpConn = nil end
	if ijConn then ijConn:Disconnect(); ijConn = nil end
	if not CONFIG.InfiniteJump then
		local _, _, hum = GetChar()
		if hum then pcall(function() hum.JumpPower = 50 end) end
		return
	end
	ApplyJP()
	local _, _, hum = GetChar()
	if hum then
		jpConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
			if CONFIG.InfiniteJump then task.defer(ApplyJP) end
		end)
	end
	ijConn = UserInputService.JumpRequest:Connect(function()
		if not CONFIG.InfiniteJump then return end
		local _, _, hum2 = GetChar()
		if hum2 then hum2:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
end

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
	l.Color = color or Color3.fromRGB(255,255,255); l.Visible = false
	return l
end
local function NewFill(color)
	local f = Drawing.new("Square"); f.Filled = true
	f.Color = color or Color3.fromRGB(30,30,30); f.Visible = false
	return f
end

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.2
fovCircle.Color = Color3.fromRGB(255,255,255)
fovCircle.Filled = false
fovCircle.Radius = CONFIG.SilentFOV
fovCircle.Visible = false
fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

local espData = {}

local function CreateESP()
	return {
		box     = NewBox(Color3.fromRGB(0,200,255), 1.5),
		nameTag = NewText(13, Color3.fromRGB(0,200,255)),
		distTag = NewText(11, Color3.fromRGB(200,200,200)),
		hpBG    = NewFill(Color3.fromRGB(30,30,30)),
		hpFill  = NewFill(Color3.fromRGB(50,220,80)),
	}
end

local function RemoveESP(d)
	d.box:Remove(); d.nameTag:Remove(); d.distTag:Remove()
	d.hpBG:Remove(); d.hpFill:Remove()
end

local function HideESP(d)
	d.box.Visible = false; d.nameTag.Visible = false
	d.distTag.Visible = false; d.hpBG.Visible = false; d.hpFill.Visible = false
end

local function GetFootPos(char)
	local isR15 = char:FindFirstChild("UpperTorso") ~= nil
	if isR15 then
		local lf = char:FindFirstChild("LeftFoot")
		local rf = char:FindFirstChild("RightFoot")
		if lf and rf then return lf.Position.Y < rf.Position.Y and lf.Position or rf.Position end
		local lt = char:FindFirstChild("LowerTorso")
		return lt and (lt.Position - Vector3.new(0,1.2,0)) or Vector3.new(0,0,0)
	else
		local ll = char:FindFirstChild("Left Leg")
		local rl = char:FindFirstChild("Right Leg")
		if ll and rl then return ll.Position.Y < rl.Position.Y and ll.Position or rl.Position end
		local t = char:FindFirstChild("Torso")
		return t and (t.Position - Vector3.new(0,2,0)) or Vector3.new(0,0,0)
	end
end

local enemyLines = {}

local function GetOrCreateEnemyLine(mob)
	if not enemyLines[mob] then
		enemyLines[mob] = NewLine(Color3.fromRGB(255,50,50), 1.2)
	end
	return enemyLines[mob]
end

local function CleanDeadEnemyLines()
	for mob, line in pairs(enemyLines) do
		if not mob or not mob.Parent then
			line:Remove()
			enemyLines[mob] = nil
		end
	end
end

local function UpdateEnemyLines()
	CleanDeadEnemyLines()
	if not CONFIG.EnemyLineESP then
		for _, line in pairs(enemyLines) do line.Visible = false end
		return
	end
	local vp     = Camera.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y)
	local folder = Workspace:FindFirstChild("Enemies")
	local activeThisFrame = {}
	if folder then
		for _, mob in ipairs(folder:GetChildren()) do
			local mr  = mob:FindFirstChild("HumanoidRootPart")
			local hum = mob:FindFirstChildOfClass("Humanoid")
			if not (mr and hum and hum.Health > 0) then continue end
			local sc, on = Camera:WorldToViewportPoint(mr.Position)
			if not (on or sc.Z > 0) then continue end
			local line = GetOrCreateEnemyLine(mob)
			line.From    = center
			line.To      = Vector2.new(sc.X, sc.Y)
			line.Visible = true
			activeThisFrame[mob] = true
		end
	end
	for mob, line in pairs(enemyLines) do
		if not activeThisFrame[mob] then line.Visible = false end
	end
end

local function UpdateESP()
	local myChar, myRoot = GetChar()
	for plr, d in pairs(espData) do
		if not plr or not plr.Parent then RemoveESP(d); espData[plr] = nil end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and not espData[plr] then espData[plr] = CreateESP() end
	end
	for plr, d in pairs(espData) do
		if not CONFIG.PlayerESP then HideESP(d); continue end
		if not plr.Character then HideESP(d); continue end
		local char = plr.Character
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum  = char:FindFirstChildOfClass("Humanoid")
		local head = char:FindFirstChild("Head")
		if not root or not hum or not head then HideESP(d); continue end
		local dist = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 0
		if dist > 600 then HideESP(d); continue end
		local headTop = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
		local footPos = GetFootPos(char)
		local scHead, onHead = Camera:WorldToViewportPoint(headTop)
		local scFoot, onFoot = Camera:WorldToViewportPoint(footPos)
		if not onHead or not onFoot then HideESP(d); continue end
		local topY    = math.min(scHead.Y, scFoot.Y)
		local bottomY = math.max(scHead.Y, scFoot.Y)
		local boxH    = math.max(bottomY - topY, 10)
		local boxW    = boxH * 0.5
		local boxX    = scHead.X - boxW / 2
		local scale   = math.clamp(1 - dist/600, 0.3, 1)
		local tsz     = math.floor(10*scale + 3)
		d.box.Size     = Vector2.new(boxW, boxH)
		d.box.Position = Vector2.new(boxX, topY)
		d.box.Visible  = true
		d.nameTag.Text     = plr.DisplayName
		d.nameTag.Size     = tsz
		d.nameTag.Position = Vector2.new(scHead.X, topY - tsz - 2)
		d.nameTag.Visible  = true
		d.distTag.Text     = dist .. "m"
		d.distTag.Size     = math.max(tsz - 2, 9)
		d.distTag.Position = Vector2.new(scHead.X, bottomY + 2)
		d.distTag.Visible  = true
		local hpPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		local barX  = boxX - 5
		d.hpBG.Size     = Vector2.new(3, boxH)
		d.hpBG.Position = Vector2.new(barX, topY)
		d.hpBG.Visible  = true
		local fh = math.max(math.floor(boxH * hpPct), 1)
		d.hpFill.Color    = Color3.fromRGB(math.floor(255*(1-hpPct)), math.floor(220*hpPct), 50)
		d.hpFill.Size     = Vector2.new(3, fh)
		d.hpFill.Position = Vector2.new(barX, topY + boxH - fh)
		d.hpFill.Visible  = true
	end
end

local sg = Instance.new("ScreenGui")
sg.Name = "Ontoy_HS"; sg.ResetOnSpawn = false
sg.Parent = LP:WaitForChild("PlayerGui")

local C = {
	BG         = Color3.fromRGB(10,10,14),
	BG2        = Color3.fromRGB(16,16,22),
	Accent     = Color3.fromRGB(80,140,255),
	AccentDim  = Color3.fromRGB(40,80,180),
	AccentGlow = Color3.fromRGB(120,180,255),
	TextMain   = Color3.fromRGB(230,235,255),
	TextSub    = Color3.fromRGB(100,110,140),
	Stroke     = Color3.fromRGB(40,50,80),
	ToggleOff  = Color3.fromRGB(35,35,45),
	SliderFill = Color3.fromRGB(80,140,255),
	SliderBG   = Color3.fromRGB(30,32,45),
	Red        = Color3.fromRGB(255,70,70),
}

local win = Instance.new("Frame")
win.Size = UDim2.new(0,500,0,420); win.Position = UDim2.new(0.5,-250,0.5,-210)
win.BackgroundColor3 = C.BG; win.BorderSizePixel = 0
win.Active = true; win.Draggable = false; win.Parent = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0,10)
local ws = Instance.new("UIStroke", win); ws.Color = C.Stroke; ws.Thickness = 1.5

local titleBar = Instance.new("Frame", win)
titleBar.Size = UDim2.new(1,0,0,42); titleBar.BackgroundColor3 = C.BG2
titleBar.BorderSizePixel = 0; titleBar.Active = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local drag, dragM, dragP = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		drag = true; dragM = Vector2.new(i.Position.X, i.Position.Y); dragP = win.Position
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
al.Size = UDim2.new(1,0,0,2); al.Position = UDim2.new(0,0,1,-2)
al.BackgroundColor3 = C.Accent; al.BorderSizePixel = 0

local dot = Instance.new("Frame", titleBar)
dot.Size = UDim2.new(0,8,0,8); dot.Position = UDim2.new(0,14,0.5,-4)
dot.BackgroundColor3 = C.AccentGlow; dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(0,4)

local tl = Instance.new("TextLabel", titleBar)
tl.Size = UDim2.new(1,-120,1,0); tl.Position = UDim2.new(0,30,0,0)
tl.BackgroundTransparency = 1
tl.Text = "ONTOY HUB  <font color='#507AFF'>·</font>  HyperShot"
tl.RichText = true; tl.TextColor3 = C.TextMain
tl.Font = Enum.Font.GothamBold; tl.TextSize = 13
tl.TextXAlignment = Enum.TextXAlignment.Left

local byl = Instance.new("TextLabel", titleBar)
byl.Size = UDim2.new(0,60,1,0); byl.Position = UDim2.new(0,260,0,0)
byl.BackgroundTransparency = 1; byl.Text = "by ontoy"
byl.TextColor3 = C.TextSub; byl.Font = Enum.Font.Gotham
byl.TextSize = 11; byl.TextXAlignment = Enum.TextXAlignment.Left

local function WinBtn(xOff, bg, txt)
	local b = Instance.new("TextButton", titleBar)
	b.Size = UDim2.new(0,26,0,26); b.Position = UDim2.new(1,xOff,0.5,-13)
	b.BackgroundColor3 = bg; b.Text = txt; b.TextColor3 = Color3.fromRGB(255,255,255)
	b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
	return b
end
local closeBtn = WinBtn(-34, C.Red, "✕")
local minBtn   = WinBtn(-66, C.ToggleOff, "—")

local sidebar = Instance.new("Frame", win)
sidebar.Size = UDim2.new(0,130,1,-42); sidebar.Position = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = C.BG2; sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", sidebar).Color = C.Stroke
local sbl = Instance.new("UIListLayout", sidebar)
sbl.Padding = UDim.new(0,3); sbl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0,12)

local cArea = Instance.new("Frame", win)
cArea.Size = UDim2.new(1,-138,1,-50); cArea.Position = UDim2.new(0,134,0,46)
cArea.BackgroundTransparency = 1; cArea.BorderSizePixel = 0

local scroll = Instance.new("ScrollingFrame", cArea)
scroll.Size = UDim2.new(1,0,1,0); scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C.AccentDim
scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
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

local function SecLabel(parent, text, color)
	local l = Instance.new("TextLabel", parent)
	l.Size = UDim2.new(1,-8,0,18); l.BackgroundTransparency = 1
	l.Text = text; l.TextColor3 = color or C.Accent
	l.Font = Enum.Font.GothamBold; l.TextSize = 10
	l.TextXAlignment = Enum.TextXAlignment.Left
end

local function Toggle(parent, label, sub, ac)
	ac = ac or C.Accent
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = C.BG2; row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row); stroke.Color = C.Stroke; stroke.Thickness = 1
	local tll = Instance.new("TextLabel", row)
	tll.Size = UDim2.new(1,-60,0,22); tll.Position = UDim2.new(0,14,0,8)
	tll.BackgroundTransparency = 1; tll.Text = label; tll.TextColor3 = C.TextMain
	tll.Font = Enum.Font.GothamBold; tll.TextSize = 12; tll.TextXAlignment = Enum.TextXAlignment.Left
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

local function Slider(parent, label, dMin, dMax, initPct, unit, onChange)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,-8,0,66); row.BackgroundColor3 = C.BG2; row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	Instance.new("UIStroke", row).Color = C.Stroke
	local tll = Instance.new("TextLabel", row)
	tll.Size = UDim2.new(1,-80,0,20); tll.Position = UDim2.new(0,14,0,8)
	tll.BackgroundTransparency = 1; tll.Text = label; tll.TextColor3 = C.TextMain
	tll.Font = Enum.Font.GothamBold; tll.TextSize = 12; tll.TextXAlignment = Enum.TextXAlignment.Left
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
	local dragS = false
	local function Compute(px)
		local pct = math.clamp((px - sbg.AbsolutePosition.X)/sbg.AbsoluteSize.X,0,1)
		return pct, math.floor(dMin + (dMax-dMin)*pct)
	end
	local function Apply(pct, val)
		fill.Size = UDim2.new(pct,0,1,0); knob.Position = UDim2.new(pct,-7,0.5,-7)
		vl.Text = val..(unit or ""); if onChange then onChange(val) end
	end
	Apply(initPct, math.floor(dMin+(dMax-dMin)*initPct))
	hit.MouseButton1Down:Connect(function() dragS = true end)
	UserInputService.InputChanged:Connect(function(i)
		if dragS and (i.UserInputType == Enum.UserInputType.MouseMovement
			or i.UserInputType == Enum.UserInputType.Touch) then
			local p,v = Compute(i.Position.X); Apply(p,v)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then dragS = false end
	end)
	hit.MouseButton1Click:Connect(function()
		local m = UserInputService:GetMouseLocation()
		local p,v = Compute(m.X); Apply(p,v)
	end)
end

local function BoneCycle(parent)
	local bones = {"Head", "HumanoidRootPart", "UpperTorso"}
	local idx = 1
	CONFIG.TargetBone = bones[idx]
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = C.BG2; row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	Instance.new("UIStroke", row).Color = C.Stroke
	local tll = Instance.new("TextLabel", row)
	tll.Size = UDim2.new(1,-120,0,22); tll.Position = UDim2.new(0,14,0,8)
	tll.BackgroundTransparency = 1; tll.Text = "Target Bone"
	tll.TextColor3 = C.TextMain; tll.Font = Enum.Font.GothamBold; tll.TextSize = 12
	tll.TextXAlignment = Enum.TextXAlignment.Left
	local sl = Instance.new("TextLabel", row)
	sl.Size = UDim2.new(1,-120,0,16); sl.Position = UDim2.new(0,14,0,28)
	sl.BackgroundTransparency = 1; sl.Text = "Klik untuk ganti"
	sl.TextColor3 = C.TextSub; sl.Font = Enum.Font.Gotham; sl.TextSize = 10
	sl.TextXAlignment = Enum.TextXAlignment.Left
	local cb = Instance.new("TextButton", row)
	cb.Size = UDim2.new(0,110,0,28); cb.Position = UDim2.new(1,-118,0.5,-14)
	cb.BackgroundColor3 = C.AccentDim; cb.BorderSizePixel = 0
	cb.Text = bones[idx]; cb.TextColor3 = C.AccentGlow
	cb.Font = Enum.Font.GothamBold; cb.TextSize = 11
	Instance.new("UICorner", cb).CornerRadius = UDim.new(0,6)
	cb.MouseButton1Click:Connect(function()
		idx = (idx % #bones) + 1
		CONFIG.TargetBone = bones[idx]; cb.Text = bones[idx]
	end)
end

local pgCombat = MakePage(); pages["combat"]   = pgCombat
local pgMove   = MakePage(); pages["movement"] = pgMove
local pgESP    = MakePage(); pages["esp"]      = pgESP

local sbCombat = MakeSideBtn("🎯","Combat",   "combat")
local sbMove   = MakeSideBtn("🏃","Movement", "movement")
local sbESP    = MakeSideBtn("👁","ESP",       "esp")

SecLabel(pgCombat, "SILENT AIM")
local _, saGet, _ = Toggle(pgCombat, "Silent Aim", "Namecall hook: Fire/FireServer/Raycast", C.Red)
BoneCycle(pgCombat)
Slider(pgCombat, "FOV Radius", 30, 400, (CONFIG.SilentFOV-30)/370, " px", function(v)
	CONFIG.SilentFOV = v; fovCircle.Radius = v
end)
Slider(pgCombat, "Smoothness", 1, 30, 0, "", function(v)
	CONFIG.Smoothness = v
end)

SecLabel(pgMove, "WALK SPEED")
local _, frGet, _ = Toggle(pgMove, "Fast Run", "WalkSpeed lock — reset-proof")
Slider(pgMove, "Walk Speed", 16, 200, (CONFIG.WalkSpeed-16)/184, " stud/s", function(v)
	CONFIG.WalkSpeed = v
	if CONFIG.FastRun then ApplyWS() end
end)
SecLabel(pgMove, "JUMP")
local _, ijGet, _ = Toggle(pgMove, "Infinite Jump", "JumpPower lock + JumpRequest hook")
Slider(pgMove, "Jump Power", 50, 300, (CONFIG.JumpPower-50)/250, "", function(v)
	CONFIG.JumpPower = v
	if CONFIG.InfiniteJump then ApplyJP() end
end)

SecLabel(pgESP, "PLAYER ESP")
local _, peGet, _ = Toggle(pgESP, "Player ESP",    "Box + nama + HP — foot-to-head anchor")
SecLabel(pgESP, "ENEMY ESP")
local _, elGet, _ = Toggle(pgESP, "Enemy Lines",   "Garis merah ke workspace.Enemies", C.Red)

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

Wire(saGet, "SilentAim")
Wire(frGet, "FastRun",      StartFastRun, StartFastRun)
Wire(ijGet, "InfiniteJump", StartInfiniteJump, StartInfiniteJump)
Wire(peGet, "PlayerESP")
Wire(elGet, "EnemyLineESP")

sbCombat.MouseButton1Click:Connect(function() SetPage("combat")   end)
sbMove.MouseButton1Click:Connect(function()   SetPage("movement") end)
sbESP.MouseButton1Click:Connect(function()    SetPage("esp")      end)
SetPage("combat")

local vis = true
minBtn.MouseButton1Click:Connect(function()
	vis = not vis
	sidebar.Visible = vis; cArea.Visible = vis
	win.Size = vis and UDim2.new(0,500,0,420) or UDim2.new(0,500,0,42)
end)
closeBtn.MouseButton1Click:Connect(function()
	CONFIG.SilentAim = false; CONFIG.FastRun = false; CONFIG.InfiniteJump = false
	local _, _, hum = GetChar()
	if hum then pcall(function() hum.WalkSpeed = 16; hum.JumpPower = 50 end) end
	if wsConn then wsConn:Disconnect() end
	if jpConn then jpConn:Disconnect() end
	if ijConn then ijConn:Disconnect() end
	fovCircle:Remove()
	for _, d in pairs(espData) do RemoveESP(d) end
	for _, line in pairs(enemyLines) do line:Remove() end
	sg:Destroy()
end)

LP.CharacterAdded:Connect(function(char)
	task.wait(1)
	if CONFIG.FastRun then StartFastRun() end
	if CONFIG.InfiniteJump then StartInfiniteJump() end
end)

local espTick = 0
RunService.RenderStepped:Connect(function()
	TickSilentAim()
	local vp = Camera.ViewportSize
	fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
	fovCircle.Visible  = CONFIG.SilentAim
	fovCircle.Radius   = CONFIG.SilentFOV
	local now = tick()
	if now - espTick >= 0.05 then
		espTick = now
		UpdateESP()
		UpdateEnemyLines()
	end
end)
