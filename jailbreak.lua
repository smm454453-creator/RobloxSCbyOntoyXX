    local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

local CONFIG = {
	AutoEscape     = false,
	SilentAim      = false,
	NoRecoil       = false,
	AutoWallbang   = false,
	VehicleMods    = false,
	InfiniteNitro  = false,
	ESP            = false,
	Tracers        = false,
	AutoHeist      = false,
	SilentAimFOV   = 120,
	VehicleSpeed   = 2.0,
	VehicleTorque  = 2.0,
}

local ESP_Objects   = {}
local silentTarget  = nil
local heistConn     = nil
local nitroConn     = nil
local vehicleConn   = nil
local escapeConn    = nil
local noRecoilConn  = nil

local CRIM_BASE     = Vector3.new(-20, 0, -1600)
local ESCAPE_POS    = Vector3.new(200, 5, -300)
local PRISON_MIN    = Vector3.new(-500, -20, -800)
local PRISON_MAX    = Vector3.new(500,  100, 200)

local HEIST_TARGETS = {
	{Name="Donut Shop",       Pos=Vector3.new(635, 18, 335),   CashPos=Vector3.new(640, 18, 340)},
	{Name="Gas Station",      Pos=Vector3.new(-400, 18, 800),  CashPos=Vector3.new(-405, 18, 805)},
	{Name="Bank",             Pos=Vector3.new(-830, 18, -990), CashPos=Vector3.new(-830, 18, -985)},
	{Name="Jewelry Store",    Pos=Vector3.new(430, 18, -780),  CashPos=Vector3.new(435, 18, -775)},
}

local function IsInPrison(pos)
	return pos.X >= PRISON_MIN.X and pos.X <= PRISON_MAX.X
		and pos.Y >= PRISON_MIN.Y and pos.Y <= PRISON_MAX.Y
		and pos.Z >= PRISON_MIN.Z and pos.Z <= PRISON_MAX.Z
end

local function GetFreshChar()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	return char, root, hum
end

local function TweenTo(targetPos, speed, onDone)
	local char, root, hum = GetFreshChar()
	if not root or not hum then if onDone then onDone() end return end
	if hum then hum.PlatformStand = true end
	local dist = (targetPos - root.Position).Magnitude
	local dur  = math.clamp(dist / (speed or 200), 0.5, 15)
	local info = TweenInfo.new(dur, Enum.EasingStyle.Linear)
	local tw   = TweenService:Create(root, info, {CFrame = CFrame.new(targetPos)})
	tw.Completed:Connect(function()
		local _, r2, h2 = GetFreshChar()
		if h2 then h2.PlatformStand = false end
		if onDone then onDone() end
	end)
	tw:Play()
	return tw
end

local function GetTeam(player)
	local ok, team = pcall(function() return player.Team and player.Team.Name or "" end)
	if not ok then return "" end
	return string.lower(team)
end

local function IsEnemy(player)
	local myTeam  = GetTeam(LocalPlayer)
	local theirTeam = GetTeam(player)
	if myTeam == "" or theirTeam == "" then return false end
	return myTeam ~= theirTeam
end

local function GetSilentTarget()
	local vp   = Camera.ViewportSize
	local cx   = vp.X / 2
	local cy   = vp.Y / 2
	local fov  = CONFIG.SilentAimFOV
	local best, bestDist = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		if not IsEnemy(player) then continue end
		local char = player.Character
		if not char then continue end
		local head = char:FindFirstChild("Head")
		local hum  = char:FindFirstChild("Humanoid")
		if not (head and hum and hum.Health > 0) then continue end
		local screen, onScreen = Camera:WorldToViewportPoint(head.Position)
		if not onScreen then continue end
		local dx   = screen.X - cx
		local dy   = screen.Y - cy
		local dist = math.sqrt(dx*dx + dy*dy)
		if dist < fov and dist < bestDist then
			bestDist = dist
			best     = head
		end
	end
	return best
end

local function ApplySilentAim()
	if not CONFIG.SilentAim then silentTarget = nil return end
	silentTarget = GetSilentTarget()
	if not silentTarget or not silentTarget.Parent then silentTarget = nil return end
	local targetPos = silentTarget.Position
	local camPos    = Camera.CFrame.Position
	local dir       = (targetPos - camPos).Unit
	Camera.CFrame   = CFrame.new(camPos, camPos + dir)
end

local function ApplyNoRecoil()
	if noRecoilConn then noRecoilConn:Disconnect() noRecoilConn = nil end
	if not CONFIG.NoRecoil then return end
	noRecoilConn = RunService.Heartbeat:Connect(function()
		local char = LocalPlayer.Character
		if not char then return end
		local tool = char:FindFirstChildOfClass("Tool")
		if not tool then return end
		for _, v in ipairs(tool:GetDescendants()) do
			if v:IsA("NumberValue") or v:IsA("IntValue") then
				local n = string.lower(v.Name)
				if string.find(n, "recoil") or string.find(n, "spread") or string.find(n, "kick") then
					v.Value = 0
				end
			end
		end
		pcall(function()
			local gunModule = tool:FindFirstChild("GunSystem") or tool:FindFirstChild("Shared")
			if gunModule and gunModule:IsA("ModuleScript") then end
		end)
	end)
end

local function ApplyWallbang()
	if not CONFIG.AutoWallbang then return end
	RunService.Heartbeat:Connect(function()
		if not CONFIG.AutoWallbang then return end
		local char = LocalPlayer.Character
		if not char then return end
		local tool = char:FindFirstChildOfClass("Tool")
		if not tool then return end
		for _, v in ipairs(tool:GetDescendants()) do
			if v:IsA("RaycastParams") then
				pcall(function() v.FilterDescendantsInstances = {} end)
			end
		end
	end)
end

local function StartVehicleMods()
	if vehicleConn then vehicleConn:Disconnect() vehicleConn = nil end
	if not CONFIG.VehicleMods then return end
	vehicleConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.VehicleMods then return end
		local char = LocalPlayer.Character
		if not char then return end
		local seat = char:FindFirstChildOfClass("VehicleSeat")
		if not seat then
			for _, v in ipairs(Workspace:GetDescendants()) do
				if v:IsA("VehicleSeat") and v.Occupant then
					local occ = v.Occupant
					local occChar = occ.Parent
					if occChar == char then seat = v break end
				end
			end
		end
		if not seat then return end
		local chassis = seat.Parent
		if not chassis then return end
		for _, v in ipairs(chassis:GetDescendants()) do
			if v:IsA("VehicleSeat") then
				pcall(function() v.MaxSpeed = 100 * CONFIG.VehicleSpeed end)
				pcall(function() v.Torque   = 50  * CONFIG.VehicleTorque end)
			end
			if v:IsA("BodyVelocity") or v:IsA("LinearVelocityConstraint") then
				pcall(function() v.MaxForce = Vector3.new(1e6, 1e6, 1e6) end)
			end
		end
	end)
end

local function StartInfiniteNitro()
	if nitroConn then nitroConn:Disconnect() nitroConn = nil end
	if not CONFIG.InfiniteNitro then return end
	nitroConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.InfiniteNitro then return end
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("NumberValue") and string.lower(v.Name) == "nitro" then
				v.Value = 100
			end
		end
	end)
end

local function StartAutoEscape()
	if escapeConn then escapeConn:Disconnect() escapeConn = nil end
	if not CONFIG.AutoEscape then return end
	escapeConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.AutoEscape then return end
		local char, root, hum = GetFreshChar()
		if not root or not hum or hum.Health <= 0 then return end
		if not IsInPrison(root.Position) then return end
		local team = GetTeam(LocalPlayer)
		if string.find(team, "police") then return end
		escapeConn:Disconnect()
		escapeConn = nil
		TweenTo(ESCAPE_POS, 300, function()
			task.wait(0.5)
			TweenTo(CRIM_BASE, 400)
		end)
	end)
end

local heistActive = false
local function StartAutoHeist()
	if heistConn then heistConn:Disconnect() heistConn = nil end
	if not CONFIG.AutoHeist then return end
	heistActive = true
	task.spawn(function()
		while CONFIG.AutoHeist do
			local char, root, hum = GetFreshChar()
			if not root or not hum or hum.Health <= 0 then task.wait(1) continue end
			local team = GetTeam(LocalPlayer)
			if string.find(team, "police") then task.wait(1) continue end

			local nearest, nearestDist = nil, math.huge
			for _, target in ipairs(HEIST_TARGETS) do
				local dist = (target.Pos - root.Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearest     = target
				end
			end
			if not nearest then task.wait(1) continue end

			TweenTo(nearest.Pos, 350)
			task.wait(3)

			local char2, root2 = GetFreshChar()
			if not root2 then task.wait(1) continue end

			for _, obj in ipairs(Workspace:GetDescendants()) do
				if not CONFIG.AutoHeist then break end
				local dist = (obj.AbsolutePosition and (obj.AbsolutePosition - nearest.CashPos).Magnitude)
					or (obj:IsA("BasePart") and (obj.Position - nearest.CashPos).Magnitude)
					or math.huge
				if dist < 30 then
					pcall(function()
						for _, pp in ipairs(obj:GetDescendants()) do
							if pp:IsA("ProximityPrompt") then
								fireproximityprompt(pp)
							end
						end
					end)
				end
			end
			task.wait(2)

			local char3, root3 = GetFreshChar()
			if root3 then
				TweenTo(CRIM_BASE, 400)
				task.wait(5)
			end
		end
		heistActive = false
	end)
end

local fovCircle    = Drawing.new("Circle")
fovCircle.Radius   = CONFIG.SilentAimFOV
fovCircle.Color    = Color3.fromRGB(255, 60, 80)
fovCircle.Filled   = false
fovCircle.Thickness = 1
fovCircle.Visible  = false

local function GetESPColor(player)
	local team = GetTeam(player)
	if string.find(team, "police") then return Color3.fromRGB(50, 100, 255) end
	if string.find(team, "crim")   then return Color3.fromRGB(255, 50, 50)  end
	return Color3.fromRGB(200, 200, 200)
end

local function CreateESP(player)
	local color = GetESPColor(player)
	local esp = {
		Box       = Drawing.new("Square"),
		Line      = Drawing.new("Line"),
		NameTag   = Drawing.new("Text"),
		HealthBar = Drawing.new("Square"),
	}
	esp.Box.Thickness  = 1
	esp.Box.Color      = color
	esp.Box.Filled     = false
	esp.Box.Visible    = false
	esp.Line.Thickness = 1
	esp.Line.Color     = color
	esp.Line.Visible   = false
	esp.NameTag.Size   = 13
	esp.NameTag.Color  = Color3.fromRGB(255, 255, 255)
	esp.NameTag.Center = true
	esp.NameTag.Outline = true
	esp.NameTag.OutlineColor = Color3.fromRGB(0, 0, 0)
	esp.NameTag.Visible = false
	esp.HealthBar.Thickness = 1
	esp.HealthBar.Filled    = true
	esp.HealthBar.Visible   = false
	return esp
end

local function CleanupESP(p)
	local esp = ESP_Objects[p]
	if not esp then return end
	esp.Box:Remove(); esp.Line:Remove()
	esp.NameTag:Remove(); esp.HealthBar:Remove()
	ESP_Objects[p] = nil
end

local function HideESP(esp)
	esp.Box.Visible      = false
	esp.NameTag.Visible  = false
	esp.Line.Visible     = false
	esp.HealthBar.Visible = false
end

local function HideAllESP()
	for _, esp in pairs(ESP_Objects) do HideESP(esp) end
end

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then ESP_Objects[p] = CreateESP(p) end
end
Players.PlayerAdded:Connect(function(p)
	ESP_Objects[p] = CreateESP(p)
end)
Players.PlayerRemoving:Connect(function(p)
	CleanupESP(p)
end)

local function RenderESP()
	local char, lroot = GetFreshChar()
	if not lroot then HideAllESP() return end
	for player, esp in pairs(ESP_Objects) do
		if not CONFIG.ESP then HideESP(esp) continue end
		local pchar = player.Character
		if not pchar then HideESP(esp) continue end
		local root = pchar:FindFirstChild("HumanoidRootPart")
		local hum  = pchar:FindFirstChild("Humanoid")
		local head = pchar:FindFirstChild("Head")
		if not (root and hum and head and hum.Health > 0) then HideESP(esp) continue end
		local rs, onScreen = Camera:WorldToViewportPoint(root.Position)
		local hs           = Camera:WorldToViewportPoint(head.Position)
		if not onScreen then HideESP(esp) continue end
		local color  = GetESPColor(player)
		local height = math.max(math.abs(rs.Y - hs.Y) * 2, 10)
		local width  = height * 0.5
		local boxPos = Vector2.new(rs.X - width/2, rs.Y - height/2)
		esp.Box.Size     = Vector2.new(width, height)
		esp.Box.Position = boxPos
		esp.Box.Color    = color
		esp.Box.Visible  = true
		local hpR  = hum.Health / hum.MaxHealth
		local barH = height * hpR
		esp.HealthBar.Size     = Vector2.new(4, barH)
		esp.HealthBar.Position = Vector2.new(boxPos.X - 7, boxPos.Y + (height - barH))
		esp.HealthBar.Color    = Color3.fromRGB(math.floor(255*(1-hpR)), math.floor(255*hpR), 0)
		esp.HealthBar.Visible  = true
		local dist = math.floor((root.Position - lroot.Position).Magnitude)
		esp.NameTag.Text     = player.Name .. " [" .. math.floor(hum.Health) .. "hp | " .. dist .. "m]"
		esp.NameTag.Position = Vector2.new(rs.X, boxPos.Y - 16)
		esp.NameTag.Visible  = true
		if CONFIG.Tracers then
			local sc = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
			esp.Line.From    = sc
			esp.Line.To      = Vector2.new(rs.X, rs.Y)
			esp.Line.Color   = color
			esp.Line.Visible = true
		else
			esp.Line.Visible = false
		end
	end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "OntoyJB"
screenGui.ResetOnSpawn = false
screenGui.Parent       = LocalPlayer:WaitForChild("PlayerGui")

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
	Blue       = Color3.fromRGB(30, 100, 220),
	BlueDim    = Color3.fromRGB(20, 60, 140),
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

local dragging = false; local dragStart = Vector2.zero; local dragPos = UDim2.new()
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = Vector2.new(input.Position.X, input.Position.Y)
		dragPos   = mainWindow.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = Vector2.new(input.Position.X, input.Position.Y) - dragStart
		mainWindow.Position = UDim2.new(
			dragPos.X.Scale, dragPos.X.Offset + d.X,
			dragPos.Y.Scale, dragPos.Y.Offset + d.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
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
titleText.Text                   = "ONTOY HUB  <font color='#C81E32'>·</font>  Jailbreak"
titleText.RichText               = true
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
	btn.Size             = UDim2.new(0, 26, 0, 26)
	btn.Position         = UDim2.new(1, xOff, 0.5, -13)
	btn.BackgroundColor3 = bg
	btn.Text             = txt
	btn.TextColor3       = Color3.fromRGB(255, 255, 255)
	btn.Font             = Enum.Font.GothamBold
	btn.TextSize         = 11
	btn.BorderSizePixel  = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	return btn
end
local closeBtn    = MakeWindowBtn(titleBar, -34, REDZ.Accent,    "✕")
local minimizeBtn = MakeWindowBtn(titleBar, -66, REDZ.ToggleOff, "—")

local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size             = UDim2.new(0, 148, 1, -42)
sidebar.Position         = UDim2.new(0, 0, 0, 42)
sidebar.BackgroundColor3 = REDZ.BG2
sidebar.BorderSizePixel  = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
local sideStroke = Instance.new("UIStroke", sidebar)
sideStroke.Color = REDZ.Stroke; sideStroke.Thickness = 1
local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding = UDim.new(0, 3)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 12)

local contentArea = Instance.new("Frame", mainWindow)
contentArea.Size             = UDim2.new(1, -156, 1, -50)
contentArea.Position         = UDim2.new(0, 152, 0, 46)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel  = 0

local contentScroll = Instance.new("ScrollingFrame", contentArea)
contentScroll.Size                   = UDim2.new(1, 0, 1, 0)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel        = 0
contentScroll.ScrollBarThickness     = 3
contentScroll.ScrollBarImageColor3   = REDZ.AccentDim
contentScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
contentScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
local contentLayout = Instance.new("UIListLayout", contentScroll)
contentLayout.Padding = UDim.new(0, 6)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentScroll).PaddingTop = UDim.new(0, 8)

local pages = {}; local sidebarButtons = {}

local function MakePage()
	local pg = Instance.new("Frame", contentScroll)
	pg.Size               = UDim2.new(1, 0, 0, 0)
	pg.AutomaticSize      = Enum.AutomaticSize.Y
	pg.BackgroundTransparency = 1
	pg.BorderSizePixel    = 0
	pg.Visible            = false
	local lay = Instance.new("UIListLayout", pg)
	lay.Padding = UDim.new(0, 6)
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Instance.new("UIPadding", pg).PaddingBottom = UDim.new(0, 8)
	return pg
end

local function MakeSidebarBtn(icon, label, id)
	local btn = Instance.new("TextButton", sidebar)
	btn.Size                   = UDim2.new(1, -14, 0, 38)
	btn.BackgroundColor3       = REDZ.ToggleOff
	btn.BackgroundTransparency = 1
	btn.Text                   = ""
	btn.BorderSizePixel        = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
	local accentBar = Instance.new("Frame", btn)
	accentBar.Size             = UDim2.new(0, 3, 0.6, 0)
	accentBar.Position         = UDim2.new(0, 0, 0.2, 0)
	accentBar.BackgroundColor3 = REDZ.Accent
	accentBar.BorderSizePixel  = 0
	accentBar.Visible          = false
	Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)
	local iconL = Instance.new("TextLabel", btn)
	iconL.Size               = UDim2.new(0, 22, 1, 0)
	iconL.Position           = UDim2.new(0, 10, 0, 0)
	iconL.BackgroundTransparency = 1
	iconL.Text               = icon
	iconL.TextColor3         = REDZ.TextSub
	iconL.Font               = Enum.Font.GothamBold
	iconL.TextSize           = 14
	local labelL = Instance.new("TextLabel", btn)
	labelL.Size              = UDim2.new(1, -38, 1, 0)
	labelL.Position          = UDim2.new(0, 36, 0, 0)
	labelL.BackgroundTransparency = 1
	labelL.Text              = label
	labelL.TextColor3        = REDZ.TextSub
	labelL.Font              = Enum.Font.Gotham
	labelL.TextSize          = 12
	labelL.TextXAlignment    = Enum.TextXAlignment.Left
	sidebarButtons[id] = {btn=btn, icon=iconL, label=labelL, bar=accentBar}
	return btn
end

local function SetActivePage(id)
	for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
	for bid, sb in pairs(sidebarButtons) do
		local active = (bid == id)
		sb.btn.BackgroundTransparency = active and 0 or 1
		sb.btn.BackgroundColor3       = active and Color3.fromRGB(30, 18, 22) or REDZ.ToggleOff
		sb.icon.TextColor3            = active and REDZ.AccentGlow or REDZ.TextSub
		sb.label.TextColor3           = active and REDZ.TextMain   or REDZ.TextSub
		sb.bar.Visible                = active
	end
end

local function MakeSectionLabel(parent, text)
	local lbl = Instance.new("TextLabel", parent)
	lbl.Size             = UDim2.new(1, -8, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.Text             = text
	lbl.TextColor3       = REDZ.Accent
	lbl.Font             = Enum.Font.GothamBold
	lbl.TextSize         = 10
	lbl.TextXAlignment   = Enum.TextXAlignment.Left
	return lbl
end

local function MakeToggleRow(parent, label, sublabel, accentColor)
	accentColor = accentColor or REDZ.Accent
	local row = Instance.new("Frame", parent)
	row.Size             = UDim2.new(1, -8, 0, 52)
	row.BackgroundColor3 = REDZ.BG2
	row.BorderSizePixel  = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", row)
	stroke.Color = REDZ.Stroke; stroke.Thickness = 1
	local title = Instance.new("TextLabel", row)
	title.Size             = UDim2.new(1, -60, 0, 22)
	title.Position         = UDim2.new(0, 14, 0, 8)
	title.BackgroundTransparency = 1
	title.Text             = label
	title.TextColor3       = REDZ.TextMain
	title.Font             = Enum.Font.GothamBold
	title.TextSize         = 12
	title.TextXAlignment   = Enum.TextXAlignment.Left
	if sublabel then
		local sub = Instance.new("TextLabel", row)
		sub.Size           = UDim2.new(1, -60, 0, 16)
		sub.Position       = UDim2.new(0, 14, 0, 28)
		sub.BackgroundTransparency = 1
		sub.Text           = sublabel
		sub.TextColor3     = REDZ.TextSub
		sub.Font           = Enum.Font.Gotham
		sub.TextSize       = 10
		sub.TextXAlignment = Enum.TextXAlignment.Left
	end
	local toggleBG = Instance.new("Frame", row)
	toggleBG.Size             = UDim2.new(0, 36, 0, 20)
	toggleBG.Position         = UDim2.new(1, -48, 0.5, -10)
	toggleBG.BackgroundColor3 = REDZ.ToggleOff
	toggleBG.BorderSizePixel  = 0
	Instance.new("UICorner", toggleBG).CornerRadius = UDim.new(0, 10)
	local toggleKnob = Instance.new("Frame", toggleBG)
	toggleKnob.Size             = UDim2.new(0, 14, 0, 14)
	toggleKnob.Position         = UDim2.new(0, 3, 0.5, -7)
	toggleKnob.BackgroundColor3 = REDZ.TextSub
	toggleKnob.BorderSizePixel  = 0
	Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(0, 7)
	local togBtn = Instance.new("TextButton", toggleBG)
	togBtn.Size               = UDim2.new(1, 8, 1, 8)
	togBtn.Position           = UDim2.new(0, -4, 0, -4)
	togBtn.BackgroundTransparency = 1
	togBtn.Text               = ""
	togBtn.BorderSizePixel    = 0
	local state = false
	local function SetState(s)
		state = s
		if s then
			toggleBG.BackgroundColor3   = accentColor
			toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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

local function MakeSliderRow(parent, label, dMin, dMax, initPct, unit, onChanged)
	local row = Instance.new("Frame", parent)
	row.Size             = UDim2.new(1, -8, 0, 66)
	row.BackgroundColor3 = REDZ.BG2
	row.BorderSizePixel  = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", row)
	stroke.Color = REDZ.Stroke; stroke.Thickness = 1
	local title = Instance.new("TextLabel", row)
	title.Size           = UDim2.new(1, -80, 0, 20)
	title.Position       = UDim2.new(0, 14, 0, 8)
	title.BackgroundTransparency = 1
	title.Text           = label
	title.TextColor3     = REDZ.TextMain
	title.Font           = Enum.Font.GothamBold
	title.TextSize       = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	local valLabel = Instance.new("TextLabel", row)
	valLabel.Size        = UDim2.new(0, 70, 0, 20)
	valLabel.Position    = UDim2.new(1, -78, 0, 8)
	valLabel.BackgroundTransparency = 1
	valLabel.Font        = Enum.Font.GothamBold
	valLabel.TextSize    = 12
	valLabel.TextColor3  = REDZ.AccentGlow
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	local sliderBG = Instance.new("Frame", row)
	sliderBG.Size        = UDim2.new(1, -28, 0, 5)
	sliderBG.Position    = UDim2.new(0, 14, 0, 42)
	sliderBG.BackgroundColor3 = REDZ.SliderBG
	sliderBG.BorderSizePixel  = 0
	Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0, 3)
	local sliderHitbox = Instance.new("TextButton", sliderBG)
	sliderHitbox.Size    = UDim2.new(1, 0, 0, 28)
	sliderHitbox.Position = UDim2.new(0, 0, 0.5, -14)
	sliderHitbox.BackgroundTransparency = 1
	sliderHitbox.Text    = ""
	sliderHitbox.BorderSizePixel = 0
	sliderHitbox.ZIndex  = 5
	local sliderFill = Instance.new("Frame", sliderBG)
	sliderFill.Size      = UDim2.new(initPct, 0, 1, 0)
	sliderFill.BackgroundColor3 = REDZ.SliderFill
	sliderFill.BorderSizePixel  = 0
	Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 3)
	local knob = Instance.new("Frame", sliderBG)
	knob.Size        = UDim2.new(0, 14, 0, 14)
	knob.Position    = UDim2.new(initPct, -7, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel  = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 7)
	local knobRing = Instance.new("UIStroke", knob)
	knobRing.Color = REDZ.Accent; knobRing.Thickness = 2
	local isDragging = false
	local function Compute(px)
		local bg  = sliderBG.AbsolutePosition.X
		local bw  = sliderBG.AbsoluteSize.X
		local pct = math.clamp((px - bg) / bw, 0, 1)
		return pct, math.floor(dMin + (dMax - dMin) * pct)
	end
	local function Apply(pct, val)
		sliderFill.Size  = UDim2.new(pct, 0, 1, 0)
		knob.Position    = UDim2.new(pct, -7, 0.5, -7)
		valLabel.Text    = val .. (unit or "")
		if onChanged then onChanged(val, pct) end
	end
	Apply(initPct, math.floor(dMin + (dMax - dMin) * initPct))
	sliderHitbox.MouseButton1Down:Connect(function() isDragging = true end)
	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local p, v = Compute(input.Position.X); Apply(p, v)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end)
	sliderHitbox.MouseButton1Click:Connect(function()
		local mouse = UserInputService:GetMouseLocation()
		local p, v = Compute(mouse.X); Apply(p, v)
	end)
	return row
end

local escapePage = MakePage(); pages["escape"] = escapePage
local escapeBtn  = MakeSidebarBtn("🔓", "Escape", "escape")
MakeSectionLabel(escapePage, "AUTO ESCAPE")
local _, escGet, _ = MakeToggleRow(escapePage, "Auto Escape", "Tween keluar penjara ke Crim Base otomatis")

local combatPage = MakePage(); pages["combat"] = combatPage
local combatBtn2 = MakeSidebarBtn("⚔", "Combat", "combat")
MakeSectionLabel(combatPage, "SILENT AIM")
local _, silentGet, _ = MakeToggleRow(combatPage, "Silent Aim", "Redirect kamera ke Head musuh terdekat")
MakeSliderRow(combatPage, "FOV Radius", 30, 400, (CONFIG.SilentAimFOV-30)/370, " px", function(val)
	CONFIG.SilentAimFOV = val
	fovCircle.Radius    = val
end)
MakeSectionLabel(combatPage, "WEAPON")
local _, noRecoilGet, _ = MakeToggleRow(combatPage, "No Recoil / No Spread", "Set recoil & spread values ke 0")
local _, wallbangGet, _ = MakeToggleRow(combatPage, "Auto Wallbang", "Bypass raycast filter — peluru tembus dinding")

local vehiclePage = MakePage(); pages["vehicle"] = vehiclePage
local vehicleBtn  = MakeSidebarBtn("🚗", "Vehicle", "vehicle")
MakeSectionLabel(vehiclePage, "MODS")
local _, vehicleGet, _ = MakeToggleRow(vehiclePage, "Vehicle Mods", "Override MaxSpeed dan Torque kendaraan")
MakeSliderRow(vehiclePage, "Speed Multiplier", 1, 10, 0.1, "x", function(val)
	CONFIG.VehicleSpeed = val
end)
MakeSliderRow(vehiclePage, "Torque Multiplier", 1, 10, 0.1, "x", function(val)
	CONFIG.VehicleTorque = val
end)
MakeSectionLabel(vehiclePage, "NITRO")
local _, nitroGet, _ = MakeToggleRow(vehiclePage, "Infinite Nitro", "Lock nitro value ke 100% setiap frame")

local espPage = MakePage(); pages["esp"] = espPage
local espBtn  = MakeSidebarBtn("👁", "ESP", "esp")
MakeSectionLabel(espPage, "WALLHACK")
local _, espGet, _     = MakeToggleRow(espPage, "ESP",     "Box, Health, Name — Biru=Police Merah=Crim")
local _, tracerGet, _  = MakeToggleRow(espPage, "Tracers", "Lines dari tengah layar ke player")

local heistPage = MakePage(); pages["heist"] = heistPage
local heistBtn  = MakeSidebarBtn("💰", "Heist", "heist")
MakeSectionLabel(heistPage, "AUTO HEIST")
local _, heistGet, _ = MakeToggleRow(heistPage, "Auto Heist",
	"Tween ke store → ambil cash → balik Crim Base", REDZ.Blue)

local function WireToggle(getter, configKey, onEnable, onDisable)
	RunService.Heartbeat:Connect(function()
		local s = getter()
		if CONFIG[configKey] ~= s then
			CONFIG[configKey] = s
			if s then if onEnable  then onEnable()  end
			else      if onDisable then onDisable()  end end
		end
	end)
end

WireToggle(escGet,      "AutoEscape",    StartAutoEscape,   function() if escapeConn then escapeConn:Disconnect() escapeConn = nil end end)
WireToggle(silentGet,   "SilentAim",     nil,               function() silentTarget = nil fovCircle.Visible = false end)
WireToggle(noRecoilGet, "NoRecoil",      ApplyNoRecoil,     ApplyNoRecoil)
WireToggle(wallbangGet, "AutoWallbang",  ApplyWallbang)
WireToggle(vehicleGet,  "VehicleMods",   StartVehicleMods,  function() if vehicleConn then vehicleConn:Disconnect() vehicleConn = nil end end)
WireToggle(nitroGet,    "InfiniteNitro", StartInfiniteNitro,function() if nitroConn  then nitroConn:Disconnect()   nitroConn = nil   end end)
WireToggle(espGet,      "ESP",           nil,               HideAllESP)
WireToggle(tracerGet,   "Tracers",       nil,               function() for _, esp in pairs(ESP_Objects) do esp.Line.Visible = false end end)
WireToggle(heistGet,    "AutoHeist",     StartAutoHeist,    function() CONFIG.AutoHeist = false end)

escapeBtn.MouseButton1Click:Connect(function()  SetActivePage("escape")  end)
combatBtn2.MouseButton1Click:Connect(function() SetActivePage("combat")  end)
vehicleBtn.MouseButton1Click:Connect(function() SetActivePage("vehicle") end)
espBtn.MouseButton1Click:Connect(function()     SetActivePage("esp")     end)
heistBtn.MouseButton1Click:Connect(function()   SetActivePage("heist")   end)
SetActivePage("escape")

local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
	contentVisible = not contentVisible
	sidebar.Visible      = contentVisible
	contentArea.Visible  = contentVisible
	mainWindow.Size = contentVisible and UDim2.new(0, 580, 0, 400) or UDim2.new(0, 580, 0, 42)
end)

closeBtn.MouseButton1Click:Connect(function()
	CONFIG.AutoEscape    = false
	CONFIG.SilentAim     = false
	CONFIG.NoRecoil      = false
	CONFIG.AutoWallbang  = false
	CONFIG.VehicleMods   = false
	CONFIG.InfiniteNitro = false
	CONFIG.ESP           = false
	CONFIG.AutoHeist     = false
	HideAllESP()
	if escapeConn  then escapeConn:Disconnect()  end
	if vehicleConn then vehicleConn:Disconnect() end
	if nitroConn   then nitroConn:Disconnect()   end
	if noRecoilConn then noRecoilConn:Disconnect() end
	fovCircle:Remove()
	screenGui:Destroy()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	LocalCharacter = char
	LocalRoot      = char:WaitForChild("HumanoidRootPart")
	LocalHumanoid  = char:WaitForChild("Humanoid")
	silentTarget   = nil
	if CONFIG.AutoEscape then
		task.wait(1)
		StartAutoEscape()
	end
end)

RunService.RenderStepped:Connect(function()
	if CONFIG.SilentAim then
		ApplySilentAim()
		local vp = Camera.ViewportSize
		fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
		fovCircle.Radius   = CONFIG.SilentAimFOV
		fovCircle.Visible  = true
	else
		fovCircle.Visible = false
	end
	RenderESP()
end)