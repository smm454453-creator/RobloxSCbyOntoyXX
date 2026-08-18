local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

local ESP_Objects = {}
local noclipConn = nil
local flyConn = nil
local flyBodyVel = nil
local flyBodyGyro = nil
local fastShootConn = nil

local CFG = {
	WalkSpeed  = 50,
	JumpPower  = 80,
	FlySpeed   = 60,
}

local function GetRoot()
	local c = LocalPlayer.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
	local c = LocalPlayer.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetTool()
	local c = LocalPlayer.Character
	return c and c:FindFirstChildOfClass("Tool")
end

local function StartNoclip()
	if noclipConn then return end
	noclipConn = RunService.Stepped:Connect(function()
		local c = LocalPlayer.Character
		if not c then return end
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end)
end

local function StopNoclip()
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
end

local function StartFly()
	if flyConn then return end
	local root = GetRoot()
	if not root then return end

	flyBodyVel = Instance.new("BodyVelocity")
	flyBodyVel.Velocity = Vector3.zero
	flyBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBodyVel.Parent = root

	flyBodyGyro = Instance.new("BodyGyro")
	flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBodyGyro.D = 100
	flyBodyGyro.Parent = root

	local hum = GetHum()
	if hum then hum.PlatformStand = true end

	flyConn = RunService.RenderStepped:Connect(function()
		local r = GetRoot()
		local h = GetHum()
		if not r or not h then return end
		h.PlatformStand = true

		local dir = Vector3.zero
		local cf  = Camera.CFrame

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			dir = dir + cf.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			dir = dir - cf.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			dir = dir - cf.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			dir = dir + cf.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			dir = dir + Vector3.new(0,1,0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			dir = dir - Vector3.new(0,1,0)
		end

		if dir.Magnitude > 0 then
			dir = dir.Unit
		end

		flyBodyVel.Velocity = dir * CFG.FlySpeed
		flyBodyGyro.CFrame  = Camera.CFrame
	end)
end

local function StopFly()
	if flyConn then flyConn:Disconnect() flyConn = nil end
	if flyBodyVel  then flyBodyVel:Destroy()  flyBodyVel  = nil end
	if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
	local h = GetHum()
	if h then h.PlatformStand = false end
end

local function PatchGun(tool)
	if not tool then return end
	local config = tool:FindFirstChild("Configuration") or tool:FindFirstChild("Config")
	if config then
		pcall(function()
			if config:FindFirstChild("Spread")       then config.Spread.Value       = 0   end
			if config:FindFirstChild("FireRate")      then config.FireRate.Value     = 0   end
			if config:FindFirstChild("ReloadTime")    then config.ReloadTime.Value   = 0   end
			if config:FindFirstChild("ClipSize")      then config.ClipSize.Value     = 999 end
			if config:FindFirstChild("Damage")        then end
		end)
	end
	local gui = tool:FindFirstChildWhichIsA("ScreenGui", true)
	                or LocalPlayer.PlayerGui:FindFirstChild("WeaponGui")
	pcall(function()
		local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("ammo")
		if ammo and ammo:IsA("IntValue") then ammo.Value = 999 end
	end)
end

local function StartFastShoot()
	if fastShootConn then return end
	fastShootConn = RunService.Heartbeat:Connect(function()
		local tool = GetTool()
		if tool then PatchGun(tool) end
	end)
end

local function StopFastShoot()
	if fastShootConn then fastShootConn:Disconnect() fastShootConn = nil end
end

local function CreateESP(player)
	local esp = {
		Box       = Drawing.new("Square"),
		NameTag   = Drawing.new("Text"),
		HealthBar = Drawing.new("Square"),
		Line      = Drawing.new("Line"),
	}
	esp.Box.Thickness  = 1
	esp.Box.Color      = Color3.fromRGB(255,50,50)
	esp.Box.Filled     = false
	esp.Box.Visible    = false
	esp.NameTag.Size   = 13
	esp.NameTag.Color  = Color3.fromRGB(255,255,255)
	esp.NameTag.Center = true
	esp.NameTag.Outline      = true
	esp.NameTag.OutlineColor = Color3.fromRGB(0,0,0)
	esp.NameTag.Visible = false
	esp.HealthBar.Thickness = 1
	esp.HealthBar.Filled    = true
	esp.HealthBar.Visible   = false
	esp.Line.Thickness = 1
	esp.Line.Color     = Color3.fromRGB(0,255,255)
	esp.Line.Visible   = false
	return esp
end

local function CleanupESP(p)
	local esp = ESP_Objects[p]
	if not esp then return end
	esp.Box:Remove()
	esp.NameTag:Remove()
	esp.HealthBar:Remove()
	esp.Line:Remove()
	ESP_Objects[p] = nil
end

local function HideESP(esp)
	esp.Box.Visible       = false
	esp.NameTag.Visible   = false
	esp.HealthBar.Visible = false
	esp.Line.Visible      = false
end

local function HideAllESP()
	for _, esp in pairs(ESP_Objects) do HideESP(esp) end
end

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then ESP_Objects[p] = CreateESP(p) end
end
Players.PlayerAdded:Connect(function(p)    ESP_Objects[p] = CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) CleanupESP(p) end)

local espEnabled     = false
local tracerEnabled  = false

local function RenderESP()
	if not espEnabled then HideAllESP() return end
	local localRoot = GetRoot()
	if not localRoot then HideAllESP() return end

	for player, esp in pairs(ESP_Objects) do
		local char = player.Character
		if not char then HideESP(esp) continue end
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum  = char:FindFirstChild("Humanoid")
		local head = char:FindFirstChild("Head")
		if not (root and hum and head and hum.Health > 0) then HideESP(esp) continue end

		local rs, onScreen = Camera:WorldToScreenPoint(root.Position)
		local hs           = Camera:WorldToScreenPoint(head.Position)
		if not onScreen then HideESP(esp) continue end

		local height = math.max(math.abs(rs.Y - hs.Y) * 2, 10)
		local width  = height * 0.5
		local boxPos = Vector2.new(rs.X - width/2, rs.Y - height/2)

		esp.Box.Size     = Vector2.new(width, height)
		esp.Box.Position = boxPos
		esp.Box.Visible  = true

		local hpR = hum.Health / hum.MaxHealth
		local barH = height * hpR
		esp.HealthBar.Size     = Vector2.new(4, barH)
		esp.HealthBar.Position = Vector2.new(boxPos.X - 7, boxPos.Y + (height - barH))
		esp.HealthBar.Color    = Color3.fromRGB(
			math.floor(255*(1-hpR)), math.floor(255*hpR), 0
		)
		esp.HealthBar.Visible = true

		local dist = math.floor((root.Position - localRoot.Position).Magnitude)
		esp.NameTag.Text     = player.Name .. " [" .. math.floor(hum.Health) .. "hp | " .. dist .. "m]"
		esp.NameTag.Position = Vector2.new(rs.X, boxPos.Y - 16)
		esp.NameTag.Visible  = true

		if tracerEnabled then
			local vp = Camera.ViewportSize
			esp.Line.From    = Vector2.new(vp.X/2, vp.Y)
			esp.Line.To      = Vector2.new(rs.X, rs.Y)
			esp.Line.Visible = true
		else
			esp.Line.Visible = false
		end
	end
end

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

local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "PrisonHub"
screenGui.ResetOnSpawn = false
screenGui.Parent       = LocalPlayer:WaitForChild("PlayerGui")

local mainWindow = Instance.new("Frame")
mainWindow.Size             = UDim2.new(0,520,0,460)
mainWindow.Position         = UDim2.new(0.5,-260,0.5,-230)
mainWindow.BackgroundColor3 = REDZ.BG
mainWindow.BorderSizePixel  = 0
mainWindow.Active           = true
mainWindow.Draggable        = false
mainWindow.Parent           = screenGui
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0,10)
local mStroke = Instance.new("UIStroke", mainWindow)
mStroke.Color = REDZ.Stroke; mStroke.Thickness = 1.5

local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size             = UDim2.new(1,0,0,42)
titleBar.BackgroundColor3 = REDZ.BG2
titleBar.BorderSizePixel  = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local accentLine = Instance.new("Frame", titleBar)
accentLine.Size             = UDim2.new(1,0,0,2)
accentLine.Position         = UDim2.new(0,0,1,-2)
accentLine.BackgroundColor3 = REDZ.Accent
accentLine.BorderSizePixel  = 0

local logoDot = Instance.new("Frame", titleBar)
logoDot.Size             = UDim2.new(0,8,0,8)
logoDot.Position         = UDim2.new(0,14,0.5,-4)
logoDot.BackgroundColor3 = REDZ.AccentGlow
logoDot.BorderSizePixel  = 0
Instance.new("UICorner", logoDot).CornerRadius = UDim.new(0,4)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size                 = UDim2.new(1,-100,1,0)
titleText.Position             = UDim2.new(0,30,0,0)
titleText.BackgroundTransparency = 1
titleText.Text                 = "PRISON HUB  <font color='#C81E32'>·</font>  Prison Life"
titleText.RichText             = true
titleText.TextColor3           = REDZ.TextMain
titleText.Font                 = Enum.Font.GothamBold
titleText.TextSize             = 13
titleText.TextXAlignment       = Enum.TextXAlignment.Left

local byLabel = Instance.new("TextLabel", titleBar)
byLabel.Size                 = UDim2.new(0,60,1,0)
byLabel.Position             = UDim2.new(0,200,0,0)
byLabel.BackgroundTransparency = 1
byLabel.Text                 = "prison life"
byLabel.TextColor3           = REDZ.TextSub
byLabel.Font                 = Enum.Font.Gotham
byLabel.TextSize             = 11
byLabel.TextXAlignment       = Enum.TextXAlignment.Left

local dragging, dragStart, dragOrig = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = Vector2.new(i.Position.X, i.Position.Y)
		dragOrig  = mainWindow.Position
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local d = Vector2.new(i.Position.X, i.Position.Y) - dragStart
		mainWindow.Position = UDim2.new(
			dragOrig.X.Scale, dragOrig.X.Offset + d.X,
			dragOrig.Y.Scale, dragOrig.Y.Offset + d.Y
		)
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local function MakeWinBtn(xOff, bg, txt)
	local b = Instance.new("TextButton", titleBar)
	b.Size             = UDim2.new(0,26,0,26)
	b.Position         = UDim2.new(1,xOff,0.5,-13)
	b.BackgroundColor3 = bg
	b.Text             = txt
	b.TextColor3       = Color3.fromRGB(255,255,255)
	b.Font             = Enum.Font.GothamBold
	b.TextSize         = 11
	b.BorderSizePixel  = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
	return b
end
local closeBtn    = MakeWinBtn(-34, REDZ.Accent,    "✕")
local minimizeBtn = MakeWinBtn(-66, REDZ.ToggleOff, "—")

local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size             = UDim2.new(0,140,1,-42)
sidebar.Position         = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = REDZ.BG2
sidebar.BorderSizePixel  = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
local sideStroke = Instance.new("UIStroke", sidebar)
sideStroke.Color = REDZ.Stroke; sideStroke.Thickness = 1
local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding             = UDim.new(0,3)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0,12)

local contentArea = Instance.new("Frame", mainWindow)
contentArea.Size                 = UDim2.new(1,-148,1,-50)
contentArea.Position             = UDim2.new(0,144,0,46)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel      = 0

local contentScroll = Instance.new("ScrollingFrame", contentArea)
contentScroll.Size                 = UDim2.new(1,0,1,0)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel      = 0
contentScroll.ScrollBarThickness   = 3
contentScroll.ScrollBarImageColor3 = REDZ.AccentDim
contentScroll.CanvasSize           = UDim2.new(0,0,0,0)
contentScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y

local contentLayout = Instance.new("UIListLayout", contentScroll)
contentLayout.Padding             = UDim.new(0,6)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentScroll).PaddingTop = UDim.new(0,8)

local pages        = {}
local sidebarBtns  = {}

local function MakePage()
	local pg = Instance.new("Frame", contentScroll)
	pg.Size                 = UDim2.new(1,0,0,0)
	pg.AutomaticSize        = Enum.AutomaticSize.Y
	pg.BackgroundTransparency = 1
	pg.BorderSizePixel      = 0
	pg.Visible              = false
	local lay = Instance.new("UIListLayout", pg)
	lay.Padding             = UDim.new(0,6)
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Instance.new("UIPadding", pg).PaddingBottom = UDim.new(0,8)
	return pg
end

local function MakeSidebarBtn(icon, label, id)
	local btn = Instance.new("TextButton", sidebar)
	btn.Size                 = UDim2.new(1,-14,0,38)
	btn.BackgroundColor3     = REDZ.ToggleOff
	btn.BackgroundTransparency = 1
	btn.Text                 = ""
	btn.BorderSizePixel      = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
	local bar = Instance.new("Frame", btn)
	bar.Size             = UDim2.new(0,3,0.6,0)
	bar.Position         = UDim2.new(0,0,0.2,0)
	bar.BackgroundColor3 = REDZ.Accent
	bar.BorderSizePixel  = 0
	bar.Visible          = false
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0,2)
	local iconL = Instance.new("TextLabel", btn)
	iconL.Size                 = UDim2.new(0,22,1,0)
	iconL.Position             = UDim2.new(0,10,0,0)
	iconL.BackgroundTransparency = 1
	iconL.Text                 = icon
	iconL.TextColor3           = REDZ.TextSub
	iconL.Font                 = Enum.Font.GothamBold
	iconL.TextSize             = 14
	local labelL = Instance.new("TextLabel", btn)
	labelL.Size                 = UDim2.new(1,-38,1,0)
	labelL.Position             = UDim2.new(0,36,0,0)
	labelL.BackgroundTransparency = 1
	labelL.Text                 = label
	labelL.TextColor3           = REDZ.TextSub
	labelL.Font                 = Enum.Font.Gotham
	labelL.TextSize             = 12
	labelL.TextXAlignment       = Enum.TextXAlignment.Left
	sidebarBtns[id] = {btn=btn, icon=iconL, label=labelL, bar=bar}
	return btn
end

local function SetActivePage(id)
	for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
	for bid, sb in pairs(sidebarBtns) do
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
	lbl.Size                 = UDim2.new(1,-8,0,18)
	lbl.BackgroundTransparency = 1
	lbl.Text                 = text
	lbl.TextColor3           = REDZ.Accent
	lbl.Font                 = Enum.Font.GothamBold
	lbl.TextSize             = 10
	lbl.TextXAlignment       = Enum.TextXAlignment.Left
end

local function MakeToggleRow(parent, label, sublabel, accentColor)
	accentColor = accentColor or REDZ.Accent
	local row = Instance.new("Frame", parent)
	row.Size             = UDim2.new(1,-8,0,52)
	row.BackgroundColor3 = REDZ.BG2
	row.BorderSizePixel  = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row)
	stroke.Color = REDZ.Stroke; stroke.Thickness = 1
	local titleLbl = Instance.new("TextLabel", row)
	titleLbl.Size                 = UDim2.new(1,-60,0,22)
	titleLbl.Position             = UDim2.new(0,14,0,8)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                 = label
	titleLbl.TextColor3           = REDZ.TextMain
	titleLbl.Font                 = Enum.Font.GothamBold
	titleLbl.TextSize             = 12
	titleLbl.TextXAlignment       = Enum.TextXAlignment.Left
	if sublabel then
		local sub = Instance.new("TextLabel", row)
		sub.Size                 = UDim2.new(1,-60,0,16)
		sub.Position             = UDim2.new(0,14,0,28)
		sub.BackgroundTransparency = 1
		sub.Text                 = sublabel
		sub.TextColor3           = REDZ.TextSub
		sub.Font                 = Enum.Font.Gotham
		sub.TextSize             = 10
		sub.TextXAlignment       = Enum.TextXAlignment.Left
	end
	local tBG = Instance.new("Frame", row)
	tBG.Size             = UDim2.new(0,36,0,20)
	tBG.Position         = UDim2.new(1,-48,0.5,-10)
	tBG.BackgroundColor3 = REDZ.ToggleOff
	tBG.BorderSizePixel  = 0
	Instance.new("UICorner", tBG).CornerRadius = UDim.new(0,10)
	local knob = Instance.new("Frame", tBG)
	knob.Size             = UDim2.new(0,14,0,14)
	knob.Position         = UDim2.new(0,3,0.5,-7)
	knob.BackgroundColor3 = REDZ.TextSub
	knob.BorderSizePixel  = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
	local hitbox = Instance.new("TextButton", tBG)
	hitbox.Size                 = UDim2.new(1,8,1,8)
	hitbox.Position             = UDim2.new(0,-4,0,-4)
	hitbox.BackgroundTransparency = 1
	hitbox.Text                 = ""
	hitbox.BorderSizePixel      = 0
	local state = false
	local function SetState(s)
		state = s
		if s then
			tBG.BackgroundColor3  = accentColor
			knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
			knob.Position         = UDim2.new(1,-17,0.5,-7)
			row.BackgroundColor3  = Color3.fromRGB(24,14,18)
			stroke.Color          = REDZ.AccentDim
		else
			tBG.BackgroundColor3  = REDZ.ToggleOff
			knob.BackgroundColor3 = REDZ.TextSub
			knob.Position         = UDim2.new(0,3,0.5,-7)
			row.BackgroundColor3  = REDZ.BG2
			stroke.Color          = REDZ.Stroke
		end
	end
	hitbox.MouseButton1Click:Connect(function() SetState(not state) end)
	return function() return state end, SetState
end

local function MakeSliderRow(parent, label, dMin, dMax, initPct, unit, onChanged)
	local row = Instance.new("Frame", parent)
	row.Size             = UDim2.new(1,-8,0,66)
	row.BackgroundColor3 = REDZ.BG2
	row.BorderSizePixel  = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row)
	stroke.Color = REDZ.Stroke; stroke.Thickness = 1
	local titleLbl = Instance.new("TextLabel", row)
	titleLbl.Size                 = UDim2.new(1,-80,0,20)
	titleLbl.Position             = UDim2.new(0,14,0,8)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                 = label
	titleLbl.TextColor3           = REDZ.TextMain
	titleLbl.Font                 = Enum.Font.GothamBold
	titleLbl.TextSize             = 12
	titleLbl.TextXAlignment       = Enum.TextXAlignment.Left
	local valLbl = Instance.new("TextLabel", row)
	valLbl.Size                 = UDim2.new(0,70,0,20)
	valLbl.Position             = UDim2.new(1,-78,0,8)
	valLbl.BackgroundTransparency = 1
	valLbl.Font                 = Enum.Font.GothamBold
	valLbl.TextSize             = 12
	valLbl.TextColor3           = REDZ.AccentGlow
	valLbl.TextXAlignment       = Enum.TextXAlignment.Right
	local sliderBG = Instance.new("Frame", row)
	sliderBG.Size             = UDim2.new(1,-28,0,5)
	sliderBG.Position         = UDim2.new(0,14,0,42)
	sliderBG.BackgroundColor3 = REDZ.SliderBG
	sliderBG.BorderSizePixel  = 0
	Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0,3)
	local fill = Instance.new("Frame", sliderBG)
	fill.Size             = UDim2.new(initPct,0,1,0)
	fill.BackgroundColor3 = REDZ.SliderFill
	fill.BorderSizePixel  = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)
	local knob = Instance.new("Frame", sliderBG)
	knob.Size             = UDim2.new(0,14,0,14)
	knob.Position         = UDim2.new(initPct,-7,0.5,-7)
	knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
	knob.BorderSizePixel  = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
	local kr = Instance.new("UIStroke", knob)
	kr.Color = REDZ.Accent; kr.Thickness = 2
	local hitbox = Instance.new("TextButton", sliderBG)
	hitbox.Size                 = UDim2.new(1,0,0,28)
	hitbox.Position             = UDim2.new(0,0,0.5,-14)
	hitbox.BackgroundTransparency = 1
	hitbox.Text                 = ""
	hitbox.BorderSizePixel      = 0
	hitbox.ZIndex               = 5
	local draggingSlider = false
	local function Compute(px)
		local bg  = sliderBG.AbsolutePosition.X
		local bw  = sliderBG.AbsoluteSize.X
		local pct = math.clamp((px - bg) / bw, 0, 1)
		return pct, math.floor(dMin + (dMax - dMin) * pct)
	end
	local function Apply(pct, val)
		fill.Size     = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, -7, 0.5, -7)
		valLbl.Text   = tostring(val) .. (unit or "")
		if onChanged then onChanged(val) end
	end
	Apply(initPct, math.floor(dMin + (dMax - dMin) * initPct))
	hitbox.MouseButton1Down:Connect(function() draggingSlider = true end)
	UserInputService.InputChanged:Connect(function(i)
		if not draggingSlider then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement
			or i.UserInputType == Enum.UserInputType.Touch then
			Apply(Compute(i.Position.X))
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = false
		end
	end)
	hitbox.MouseButton1Click:Connect(function()
		Apply(Compute(UserInputService:GetMouseLocation().X))
	end)
end

local combatPage = MakePage(); pages["combat"] = combatPage
local combatBtn  = MakeSidebarBtn("🔫", "Combat", "combat")

MakeSectionLabel(combatPage, "GUN")
local fastShootGet, _ = MakeToggleRow(combatPage, "Rapid Fire", "No spread + fast fire rate + infinite ammo")

local movePage = MakePage(); pages["move"] = movePage
local moveBtn  = MakeSidebarBtn("🏃", "Movement", "move")

MakeSectionLabel(movePage, "SPEED")
local fastRunGet, _  = MakeToggleRow(movePage, "Fast Run", "Override WalkSpeed setiap frame")
MakeSliderRow(movePage, "Walk Speed", 16, 500, 0.07, " ws", function(val)
	CFG.WalkSpeed = val
end)

MakeSectionLabel(movePage, "JUMP")
local highJumpGet, _ = MakeToggleRow(movePage, "High Jump", "Override JumpPower setiap frame")
MakeSliderRow(movePage, "Jump Power", 50, 500, 0.06, " jp", function(val)
	CFG.JumpPower = val
end)

MakeSectionLabel(movePage, "FLY")
local flyGet, _      = MakeToggleRow(movePage, "Fly Mode", "WASD + Space/Shift — terbang bebas")
MakeSliderRow(movePage, "Fly Speed", 10, 300, 0.17, " stud/s", function(val)
	CFG.FlySpeed = val
end)

MakeSectionLabel(movePage, "NOCLIP")
local noclipGet, _   = MakeToggleRow(movePage, "No Clip", "CanCollide = false semua part karakter")

local visualPage = MakePage(); pages["visual"] = visualPage
local visualBtn  = MakeSidebarBtn("👁", "Visual", "visual")

MakeSectionLabel(visualPage, "ESP")
local espGet, _      = MakeToggleRow(visualPage, "ESP", "Box, health bar, nama + jarak semua player")
local tracerGet, _   = MakeToggleRow(visualPage, "Tracers", "Garis dari bawah layar ke semua player")

RunService.RenderStepped:Connect(function()
	local hum  = GetHum()
	local root = GetRoot()

	if fastShootGet() then StartFastShoot() else StopFastShoot() end

	if fastRunGet() and hum then
		hum.WalkSpeed = CFG.WalkSpeed
	elseif not fastRunGet() and hum then
		hum.WalkSpeed = 16
	end

	if highJumpGet() and hum then
		hum.JumpPower = CFG.JumpPower
	elseif not highJumpGet() and hum then
		hum.JumpPower = 50
	end

	if flyGet() then
		if not flyConn then StartFly() end
	else
		if flyConn then StopFly() end
	end

	if noclipGet() then
		if not noclipConn then StartNoclip() end
	else
		if noclipConn then StopNoclip() end
	end

	espEnabled    = espGet()
	tracerEnabled = tracerGet()
	RenderESP()
end)

combatBtn.MouseButton1Click:Connect(function() SetActivePage("combat") end)
moveBtn.MouseButton1Click:Connect(function()   SetActivePage("move")   end)
visualBtn.MouseButton1Click:Connect(function() SetActivePage("visual") end)
SetActivePage("combat")

local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
	contentVisible = not contentVisible
	sidebar.Visible      = contentVisible
	contentArea.Visible  = contentVisible
	mainWindow.Size = contentVisible
		and UDim2.new(0,520,0,460)
		or  UDim2.new(0,520,0,42)
end)

closeBtn.MouseButton1Click:Connect(function()
	StopFastShoot()
	StopFly()
	StopNoclip()
	HideAllESP()
	local h = GetHum()
	if h then h.WalkSpeed = 16; h.JumpPower = 50; h.PlatformStand = false end
	screenGui:Destroy()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	LocalCharacter = char
	LocalRoot      = char:WaitForChild("HumanoidRootPart")
	LocalHumanoid  = char:WaitForChild("Humanoid")
	if flyConn then StopFly() end
	currentFarmMob = nil
end)
