local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

local CONFIG = {
	AutoEscape    = false,
	SilentAim     = false,
	TargetBone    = "Head",
	NoRecoil      = false,
	VehicleMods   = false,
	VehicleSpeed  = 250,
	VehicleTorque = 2,
	InfiniteNitro = false,
	ESP           = false,
	Tracers       = false,
	SilentAimFOV  = 120,
	FastRun       = false,
	WalkSpeed     = 16,
}

local ESP_Highlights = {}
local ESP_Tracers    = {}
local ESP_Labels     = {}
local silentTarget   = nil
local noRecoilConn   = nil
local vehiclePushConn= nil
local nitroConn      = nil
local walkSpeedConn  = nil
local escapeRunning  = false
local lastSeat       = nil

local ESCAPE_OUT = CFrame.new(-1160, 18, -1380)
local CRIM_BASE  = Vector3.new(-20, 18, -1600)

local function GetFreshChar()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	return char, root, hum
end

local function GetTeam(player)
	local ok, name = pcall(function()
		return player.Team and player.Team.Name or ""
	end)
	return ok and string.lower(name) or ""
end

local function IsEnemy(player)
	local mine   = GetTeam(LocalPlayer)
	local theirs = GetTeam(player)
	if mine == "" or theirs == "" then return false end
	return mine ~= theirs
end

local function GetSilentTarget()
	local vp    = Camera.ViewportSize
	local cx    = vp.X / 2
	local cy    = vp.Y / 2
	local fov   = CONFIG.SilentAimFOV
	local best, bestDist = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		if not IsEnemy(player) then continue end
		local pchar = player.Character
		if not pchar then continue end
		local bone = pchar:FindFirstChild(CONFIG.TargetBone)
			or pchar:FindFirstChild("HumanoidRootPart")
		local hum  = pchar:FindFirstChild("Humanoid")
		if not (bone and hum and hum.Health > 0) then continue end
		local screen, onScreen = Camera:WorldToViewportPoint(bone.Position)
		if not onScreen then continue end
		local dx   = screen.X - cx
		local dy   = screen.Y - cy
		local dist = math.sqrt(dx*dx + dy*dy)
		if dist < fov and dist < bestDist then
			bestDist = dist
			best     = bone
		end
	end
	return best
end

local hookedMeta = false
local function HookNamecall()
	if hookedMeta then return end
	hookedMeta = true
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()

		if CONFIG.SilentAim and silentTarget and silentTarget.Parent then
			if method == "FireServer" or method == "InvokeServer" then
				local args = {...}
				for i, v in ipairs(args) do
					if typeof(v) == "Instance" and v:IsA("BasePart") then
						args[i] = silentTarget
					elseif typeof(v) == "Ray" then
						local camPos = Camera.CFrame.Position
						local dir    = (silentTarget.Position - camPos).Unit
						args[i]      = Ray.new(camPos, dir * 1000)
					elseif typeof(v) == "CFrame" then
						args[i] = CFrame.new(silentTarget.Position)
					elseif typeof(v) == "Vector3" then
						args[i] = silentTarget.Position
					end
				end
				return oldNamecall(self, table.unpack(args))
			end

			if method == "Raycast" and self == Workspace then
				local args = {...}
				local camPos = Camera.CFrame.Position
				local dir    = (silentTarget.Position - camPos).Unit
				args[1] = camPos
				args[2] = dir * 1000
				return oldNamecall(self, table.unpack(args))
			end

			if method == "FindPartOnRayWithIgnoreList"
			or method == "FindPartOnRay"
			or method == "FindPartOnRayWithWhitelist" then
				local args = {...}
				local camPos = Camera.CFrame.Position
				local dir    = (silentTarget.Position - camPos).Unit
				args[1] = Ray.new(camPos, dir * 1000)
				return oldNamecall(self, table.unpack(args))
			end
		end

		return oldNamecall(self, ...)
	end)
end

pcall(HookNamecall)

local function ApplySilentAim()
	if not CONFIG.SilentAim then silentTarget = nil return end
	silentTarget = GetSilentTarget()
	if not silentTarget or not silentTarget.Parent then silentTarget = nil return end
	local camPos = Camera.CFrame.Position
	local dir    = (silentTarget.Position - camPos).Unit
	Camera.CFrame = CFrame.new(camPos, camPos + dir)
end

local function PatchGunModule(mod)
	local ok, result = pcall(require, mod)
	if not ok or type(result) ~= "table" then return end
	local keys = {"Spread","Recoil","RecoilControl","RecoilAmount",
	              "SpreadAmount","HipSpread","AimSpread","BloomDecay",
	              "MinSpread","MaxSpread","RecoilUp","RecoilRight"}
	for _, k in ipairs(keys) do
		if result[k] ~= nil and type(result[k]) == "number" then
			pcall(function() result[k] = 0 end)
		end
	end
end

local function ScanAndPatchGuns()
	local roots = {
		game:GetService("ReplicatedStorage"),
		game:GetService("StarterPlayer"),
	}
	for _, root in ipairs(roots) do
		pcall(function()
			for _, v in ipairs(root:GetDescendants()) do
				if v:IsA("ModuleScript") then
					local n = string.lower(v.Name)
					if string.find(n,"gun") or string.find(n,"weapon")
					or string.find(n,"shoot") or string.find(n,"bullet")
					or string.find(n,"fire") or string.find(n,"ammo") then
						PatchGunModule(v)
					end
				end
			end
		end)
	end
end

local function ApplyNoRecoil()
	if noRecoilConn then noRecoilConn:Disconnect() noRecoilConn = nil end
	if not CONFIG.NoRecoil then return end
	ScanAndPatchGuns()
	noRecoilConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.NoRecoil then return end
		local char = LocalPlayer.Character
		if not char then return end
		local tool = char:FindFirstChildOfClass("Tool")
		if not tool then return end
		for _, v in ipairs(tool:GetDescendants()) do
			if v:IsA("NumberValue") or v:IsA("IntValue") then
				local n = string.lower(v.Name)
				if string.find(n,"recoil") or string.find(n,"spread")
				or string.find(n,"kick")   or string.find(n,"bloom") then
					if v.Value ~= 0 then v.Value = 0 end
				end
			end
		end
	end)
end

local wHeld = false
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.W then wHeld = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then wHeld = false end
end)

local function GetCurrentSeat()
	local _, _, hum = GetFreshChar()
	if not hum then return nil end
	local seat = hum.SeatPart
	if seat and seat:IsA("VehicleSeat") then return seat end
	return nil
end

local function StartVehiclePush()
	if vehiclePushConn then vehiclePushConn:Disconnect() vehiclePushConn = nil end
	if not CONFIG.VehicleMods then return end
	vehiclePushConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.VehicleMods or not wHeld then return end
		local seat = GetCurrentSeat()
		if not seat then return end
		local car     = seat.Parent
		local primary = (car and car.PrimaryPart) or seat
		local lookVec = primary.CFrame.LookVector
		pcall(function()
			primary.AssemblyLinearVelocity = lookVec * CONFIG.VehicleSpeed
		end)
	end)
end

local function WatchSeat()
	RunService.Heartbeat:Connect(function()
		if not CONFIG.VehicleMods then return end
		local seat = GetCurrentSeat()
		if seat == lastSeat then return end
		lastSeat = seat
		if seat then
			pcall(function()
				seat.MaxSpeed = math.max(CONFIG.VehicleSpeed, 100)
				seat.Torque   = CONFIG.VehicleTorque
			end)
		end
	end)
end

local function StartInfiniteNitro()
	if nitroConn then nitroConn:Disconnect() nitroConn = nil end
	if not CONFIG.InfiniteNitro then return end
	local function LockNitro()
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("NumberValue") and string.lower(v.Name) == "nitro" then
				pcall(function() v.Value = 100 end)
			end
		end
	end
	nitroConn = UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if not CONFIG.InfiniteNitro then return end
		if input.KeyCode == Enum.KeyCode.LeftShift
		or input.KeyCode == Enum.KeyCode.RightShift
		or input.KeyCode == Enum.KeyCode.Q then
			LockNitro()
		end
	end)
	LockNitro()
end

-- AUTO ESCAPE: physics-based bypass — bungkus CFrame dalam velocity loop pendek
-- bukan raw teleport, lebih susah dideteksi anti-cheat Jailbreak
local function PhysicsEscape(targetCF)
	local char, root, hum = GetFreshChar()
	if not root or not hum or hum.Health <= 0 then return end
	local origin = root.CFrame
	local steps  = 18
	for i = 1, steps do
		if not CONFIG.AutoEscape then break end
		local alpha  = i / steps
		local nextCF = origin:Lerp(targetCF, alpha)
		root.CFrame  = nextCF
		local diff   = (nextCF.Position - root.Position)
		pcall(function()
			root.AssemblyLinearVelocity = diff * 20
		end)
		task.wait(0.04)
	end
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
	end)
end

local function StartAutoEscape()
	if escapeRunning then return end
	task.spawn(function()
		escapeRunning = true
		while CONFIG.AutoEscape do
			task.wait(0.25)
			local char, root, hum = GetFreshChar()
			if not root or not hum or hum.Health <= 0 then continue end
			if string.find(GetTeam(LocalPlayer), "police") then continue end
			local pos = root.Position
			local inPrison = pos.X > -500 and pos.X < 500
				and pos.Y > -20 and pos.Y < 100
				and pos.Z > -800 and pos.Z < 200
			if not inPrison then continue end
			CONFIG.AutoEscape = false
			PhysicsEscape(ESCAPE_OUT)
			task.wait(0.6)
			local _, r2 = GetFreshChar()
			if r2 then
				PhysicsEscape(CFrame.new(CRIM_BASE))
			end
			break
		end
		escapeRunning = false
	end)
end

-- FAST RUN: GetPropertyChangedSignal buat tangkap reset WalkSpeed dari server
local function ApplyWalkSpeed()
	local _, _, hum = GetFreshChar()
	if not hum then return end
	pcall(function() hum.WalkSpeed = CONFIG.WalkSpeed end)
end

local function StartFastRun()
	if walkSpeedConn then walkSpeedConn:Disconnect() walkSpeedConn = nil end
	if not CONFIG.FastRun then
		local _, _, hum = GetFreshChar()
		if hum then pcall(function() hum.WalkSpeed = 16 end) end
		return
	end
	ApplyWalkSpeed()
	local _, _, hum = GetFreshChar()
	if hum then
		walkSpeedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if CONFIG.FastRun then
				task.defer(ApplyWalkSpeed)
			end
		end)
	end
end

local function GetESPColor(player)
	local team = GetTeam(player)
	if string.find(team, "police") then return Color3.fromRGB(50,100,255), Color3.fromRGB(0,40,180) end
	if string.find(team, "crim")   then return Color3.fromRGB(255,50,50),  Color3.fromRGB(140,0,0)  end
	return Color3.fromRGB(200,200,200), Color3.fromRGB(80,80,80)
end

local function UpdateESPLabel(player)
	local label = ESP_Labels[player]
	if not label then return end
	local pchar = player.Character
	local proot = pchar and pchar:FindFirstChild("HumanoidRootPart")
	local _, root = GetFreshChar()
	if not (proot and root) then label.Visible = false return end
	local dist = math.floor((root.Position - proot.Position).Magnitude)
	local screen, onScreen = Camera:WorldToViewportPoint(proot.Position)
	if not onScreen then label.Visible = false return end
	local fill, _ = GetESPColor(player)
	label.Position = Vector2.new(screen.X, screen.Y - 24)
	label.Text     = player.Name .. "  [" .. dist .. "s]"
	label.Color    = fill
	label.Visible  = true
end

local function CreateHighlight(player)
	if ESP_Highlights[player] then return end
	local pchar = player.Character
	if not pchar then return end
	local fill, outline = GetESPColor(player)
	local hl = Instance.new("Highlight")
	hl.FillColor           = fill
	hl.OutlineColor        = outline
	hl.FillTransparency    = 0.5
	hl.OutlineTransparency = 0
	hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee             = pchar
	hl.Parent              = pchar
	ESP_Highlights[player] = hl

	if not ESP_Labels[player] then
		local lbl = Drawing.new("Text")
		lbl.Size    = 13
		lbl.Center  = true
		lbl.Outline = true
		lbl.OutlineColor = Color3.fromRGB(0,0,0)
		lbl.Visible = false
		ESP_Labels[player] = lbl
	end
end

local function RemoveHighlight(player)
	local hl = ESP_Highlights[player]
	if hl then pcall(function() hl:Destroy() end) ESP_Highlights[player] = nil end
	local lbl = ESP_Labels[player]
	if lbl then lbl:Remove() ESP_Labels[player] = nil end
end

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then
		p.CharacterAdded:Connect(function()
			task.wait(0.5)
			if CONFIG.ESP then CreateHighlight(p) end
		end)
	end
end
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		if CONFIG.ESP then CreateHighlight(p) end
	end)
end)
Players.PlayerRemoving:Connect(function(p)
	RemoveHighlight(p)
	local line = ESP_Tracers[p]
	if line then line:Remove() ESP_Tracers[p] = nil end
end)

local function UpdateTracers()
	if not CONFIG.Tracers then
		for p, line in pairs(ESP_Tracers) do line:Remove() ESP_Tracers[p] = nil end
		return
	end
	local vp     = Camera.ViewportSize
	local origin = Vector2.new(vp.X/2, vp.Y)
	local seen   = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		local pchar = player.Character
		local proot = pchar and pchar:FindFirstChild("HumanoidRootPart")
		local phum  = pchar and pchar:FindFirstChild("Humanoid")
		if not (proot and phum and phum.Health > 0) then
			local old = ESP_Tracers[player]
			if old then old:Remove() ESP_Tracers[player] = nil end
			continue
		end
		local screen, onScreen = Camera:WorldToViewportPoint(proot.Position)
		if not onScreen then
			local old = ESP_Tracers[player]
			if old then old:Remove() ESP_Tracers[player] = nil end
			continue
		end
		seen[player] = true
		local fill, _ = GetESPColor(player)
		local line = ESP_Tracers[player]
		if not line then
			line = Drawing.new("Line")
			line.Thickness = 1
			ESP_Tracers[player] = line
		end
		line.From    = origin
		line.To      = Vector2.new(screen.X, screen.Y)
		line.Color   = fill
		line.Visible = true
	end
	for player, line in pairs(ESP_Tracers) do
		if not seen[player] then line:Remove() ESP_Tracers[player] = nil end
	end
end

local fovCircle     = Drawing.new("Circle")
fovCircle.Radius    = CONFIG.SilentAimFOV
fovCircle.Color     = Color3.fromRGB(255, 60, 80)
fovCircle.Filled    = false
fovCircle.Thickness = 1
fovCircle.Visible   = false

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
}

local mainWindow = Instance.new("Frame")
mainWindow.Size             = UDim2.new(0, 580, 0, 420)
mainWindow.Position         = UDim2.new(0.5, -290, 0.5, -210)
mainWindow.BackgroundColor3 = REDZ.BG
mainWindow.BorderSizePixel  = 0
mainWindow.Active           = true
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
		dragging  = true
		dragStart = Vector2.new(input.Position.X, input.Position.Y)
		dragPos   = mainWindow.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = Vector2.new(input.Position.X, input.Position.Y) - dragStart
		mainWindow.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset+d.X, dragPos.Y.Scale, dragPos.Y.Offset+d.Y)
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
titleText.Size = UDim2.new(1,-160,1,0); titleText.Position = UDim2.new(0,30,0,0)
titleText.BackgroundTransparency = 1
titleText.Text = "ONTOY HUB  <font color='#C81E32'>·</font>  Jailbreak"
titleText.RichText = true; titleText.TextColor3 = REDZ.TextMain
titleText.Font = Enum.Font.GothamBold; titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left

local byLabel = Instance.new("TextLabel", titleBar)
byLabel.Size = UDim2.new(0,80,1,0); byLabel.Position = UDim2.new(0,195,0,0)
byLabel.BackgroundTransparency = 1; byLabel.Text = "by ontoy"
byLabel.TextColor3 = REDZ.TextSub; byLabel.Font = Enum.Font.Gotham
byLabel.TextSize = 11; byLabel.TextXAlignment = Enum.TextXAlignment.Left

local function MakeWindowBtn(parent, xOff, bg, txt)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(0,26,0,26); btn.Position = UDim2.new(1,xOff,0.5,-13)
	btn.BackgroundColor3 = bg; btn.Text = txt
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.BorderSizePixel = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
	return btn
end
local closeBtn    = MakeWindowBtn(titleBar, -34, REDZ.Accent,    "✕")
local minimizeBtn = MakeWindowBtn(titleBar, -66, REDZ.ToggleOff, "—")

local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size = UDim2.new(0,148,1,-42); sidebar.Position = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = REDZ.BG2; sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", sidebar).Color = REDZ.Stroke
local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding = UDim.new(0,3)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0,12)

local contentArea = Instance.new("Frame", mainWindow)
contentArea.Size = UDim2.new(1,-156,1,-50); contentArea.Position = UDim2.new(0,152,0,46)
contentArea.BackgroundTransparency = 1; contentArea.BorderSizePixel = 0

local contentScroll = Instance.new("ScrollingFrame", contentArea)
contentScroll.Size = UDim2.new(1,0,1,0); contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0; contentScroll.ScrollBarThickness = 3
contentScroll.ScrollBarImageColor3 = REDZ.AccentDim
contentScroll.CanvasSize = UDim2.new(0,0,0,0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local contentLayout = Instance.new("UIListLayout", contentScroll)
contentLayout.Padding = UDim.new(0,6)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentScroll).PaddingTop = UDim.new(0,8)

local pages = {}; local sidebarButtons = {}

local function MakePage()
	local pg = Instance.new("Frame", contentScroll)
	pg.Size = UDim2.new(1,0,0,0); pg.AutomaticSize = Enum.AutomaticSize.Y
	pg.BackgroundTransparency = 1; pg.BorderSizePixel = 0; pg.Visible = false
	local lay = Instance.new("UIListLayout", pg)
	lay.Padding = UDim.new(0,6); lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Instance.new("UIPadding", pg).PaddingBottom = UDim.new(0,8)
	return pg
end

local function MakeSidebarBtn(icon, label, id)
	local btn = Instance.new("TextButton", sidebar)
	btn.Size = UDim2.new(1,-14,0,38); btn.BackgroundTransparency = 1
	btn.Text = ""; btn.BorderSizePixel = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
	local accentBar = Instance.new("Frame", btn)
	accentBar.Size = UDim2.new(0,3,0.6,0); accentBar.Position = UDim2.new(0,0,0.2,0)
	accentBar.BackgroundColor3 = REDZ.Accent; accentBar.BorderSizePixel = 0; accentBar.Visible = false
	Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0,2)
	local iconL = Instance.new("TextLabel", btn)
	iconL.Size = UDim2.new(0,22,1,0); iconL.Position = UDim2.new(0,10,0,0)
	iconL.BackgroundTransparency = 1; iconL.Text = icon
	iconL.TextColor3 = REDZ.TextSub; iconL.Font = Enum.Font.GothamBold; iconL.TextSize = 14
	local labelL = Instance.new("TextLabel", btn)
	labelL.Size = UDim2.new(1,-38,1,0); labelL.Position = UDim2.new(0,36,0,0)
	labelL.BackgroundTransparency = 1; labelL.Text = label
	labelL.TextColor3 = REDZ.TextSub; labelL.Font = Enum.Font.Gotham; labelL.TextSize = 12
	labelL.TextXAlignment = Enum.TextXAlignment.Left
	sidebarButtons[id] = {btn=btn, icon=iconL, label=labelL, bar=accentBar}
	return btn
end

local function SetActivePage(id)
	for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
	for bid, sb in pairs(sidebarButtons) do
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
	lbl.Size = UDim2.new(1,-8,0,18); lbl.BackgroundTransparency = 1
	lbl.Text = text; lbl.TextColor3 = REDZ.Accent
	lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	return lbl
end

local function MakeToggleRow(parent, label, sublabel, accentColor)
	accentColor = accentColor or REDZ.Accent
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1
	local title = Instance.new("TextLabel", row)
	title.Size = UDim2.new(1,-60,0,22); title.Position = UDim2.new(0,14,0,8)
	title.BackgroundTransparency = 1; title.Text = label
	title.TextColor3 = REDZ.TextMain; title.Font = Enum.Font.GothamBold; title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	if sublabel then
		local sub = Instance.new("TextLabel", row)
		sub.Size = UDim2.new(1,-60,0,16); sub.Position = UDim2.new(0,14,0,28)
		sub.BackgroundTransparency = 1; sub.Text = sublabel
		sub.TextColor3 = REDZ.TextSub; sub.Font = Enum.Font.Gotham; sub.TextSize = 10
		sub.TextXAlignment = Enum.TextXAlignment.Left
	end
	local toggleBG = Instance.new("Frame", row)
	toggleBG.Size = UDim2.new(0,36,0,20); toggleBG.Position = UDim2.new(1,-48,0.5,-10)
	toggleBG.BackgroundColor3 = REDZ.ToggleOff; toggleBG.BorderSizePixel = 0
	Instance.new("UICorner", toggleBG).CornerRadius = UDim.new(0,10)
	local toggleKnob = Instance.new("Frame", toggleBG)
	toggleKnob.Size = UDim2.new(0,14,0,14); toggleKnob.Position = UDim2.new(0,3,0.5,-7)
	toggleKnob.BackgroundColor3 = REDZ.TextSub; toggleKnob.BorderSizePixel = 0
	Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(0,7)
	local togBtn = Instance.new("TextButton", toggleBG)
	togBtn.Size = UDim2.new(1,8,1,8); togBtn.Position = UDim2.new(0,-4,0,-4)
	togBtn.BackgroundTransparency = 1; togBtn.Text = ""; togBtn.BorderSizePixel = 0
	local state = false
	local function SetState(s)
		state = s
		if s then
			toggleBG.BackgroundColor3   = accentColor
			toggleKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
			toggleKnob.Position         = UDim2.new(1,-17,0.5,-7)
			row.BackgroundColor3        = Color3.fromRGB(24,14,18)
			stroke.Color                = REDZ.AccentDim
		else
			toggleBG.BackgroundColor3   = REDZ.ToggleOff
			toggleKnob.BackgroundColor3 = REDZ.TextSub
			toggleKnob.Position         = UDim2.new(0,3,0.5,-7)
			row.BackgroundColor3        = REDZ.BG2
			stroke.Color                = REDZ.Stroke
		end
	end
	togBtn.MouseButton1Click:Connect(function() SetState(not state) end)
	return row, function() return state end, SetState
end

local function MakeSliderRow(parent, label, dMin, dMax, initPct, unit, onChanged)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,-8,0,66); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1
	local title = Instance.new("TextLabel", row)
	title.Size = UDim2.new(1,-80,0,20); title.Position = UDim2.new(0,14,0,8)
	title.BackgroundTransparency = 1; title.Text = label
	title.TextColor3 = REDZ.TextMain; title.Font = Enum.Font.GothamBold; title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	local valLabel = Instance.new("TextLabel", row)
	valLabel.Size = UDim2.new(0,70,0,20); valLabel.Position = UDim2.new(1,-78,0,8)
	valLabel.BackgroundTransparency = 1; valLabel.Font = Enum.Font.GothamBold; valLabel.TextSize = 12
	valLabel.TextColor3 = REDZ.AccentGlow; valLabel.TextXAlignment = Enum.TextXAlignment.Right
	local sliderBG = Instance.new("Frame", row)
	sliderBG.Size = UDim2.new(1,-28,0,5); sliderBG.Position = UDim2.new(0,14,0,42)
	sliderBG.BackgroundColor3 = REDZ.SliderBG; sliderBG.BorderSizePixel = 0
	Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0,3)
	local sliderHitbox = Instance.new("TextButton", sliderBG)
	sliderHitbox.Size = UDim2.new(1,0,0,28); sliderHitbox.Position = UDim2.new(0,0,0.5,-14)
	sliderHitbox.BackgroundTransparency = 1; sliderHitbox.Text = ""
	sliderHitbox.BorderSizePixel = 0; sliderHitbox.ZIndex = 5
	local sliderFill = Instance.new("Frame", sliderBG)
	sliderFill.Size = UDim2.new(initPct,0,1,0); sliderFill.BackgroundColor3 = REDZ.SliderFill
	sliderFill.BorderSizePixel = 0
	Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0,3)
	local knob = Instance.new("Frame", sliderBG)
	knob.Size = UDim2.new(0,14,0,14); knob.Position = UDim2.new(initPct,-7,0.5,-7)
	knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.BorderSizePixel = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
	local knobRing = Instance.new("UIStroke", knob); knobRing.Color = REDZ.Accent; knobRing.Thickness = 2
	local isDragging = false
	local function Compute(px)
		local bg = sliderBG.AbsolutePosition.X; local bw = sliderBG.AbsoluteSize.X
		local pct = math.clamp((px-bg)/bw, 0, 1)
		return pct, math.floor(dMin + (dMax-dMin)*pct)
	end
	local function Apply(pct, val)
		sliderFill.Size = UDim2.new(pct,0,1,0); knob.Position = UDim2.new(pct,-7,0.5,-7)
		valLabel.Text = val..(unit or "")
		if onChanged then onChanged(val, pct) end
	end
	Apply(initPct, math.floor(dMin+(dMax-dMin)*initPct))
	sliderHitbox.MouseButton1Down:Connect(function() isDragging = true end)
	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local p, v = Compute(input.Position.X); Apply(p, v)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then isDragging = false end
	end)
	sliderHitbox.MouseButton1Click:Connect(function()
		local mouse = UserInputService:GetMouseLocation()
		local p, v = Compute(mouse.X); Apply(p, v)
	end)
	return row
end

local function MakeBoneCycleRow(parent)
	local bones = {"Head", "HumanoidRootPart", "Torso"}
	local idx   = 1
	local row   = Instance.new("Frame", parent)
	row.Size             = UDim2.new(1,-8,0,52)
	row.BackgroundColor3 = REDZ.BG2
	row.BorderSizePixel  = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1
	local title = Instance.new("TextLabel", row)
	title.Size = UDim2.new(1,-120,0,22); title.Position = UDim2.new(0,14,0,8)
	title.BackgroundTransparency = 1; title.Text = "Target Bone"
	title.TextColor3 = REDZ.TextMain; title.Font = Enum.Font.GothamBold; title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	local sub = Instance.new("TextLabel", row)
	sub.Size = UDim2.new(1,-120,0,16); sub.Position = UDim2.new(0,14,0,28)
	sub.BackgroundTransparency = 1; sub.Text = "Klik untuk ganti target bone"
	sub.TextColor3 = REDZ.TextSub; sub.Font = Enum.Font.Gotham; sub.TextSize = 10
	sub.TextXAlignment = Enum.TextXAlignment.Left
	local cycleBtn = Instance.new("TextButton", row)
	cycleBtn.Size             = UDim2.new(0,100,0,28)
	cycleBtn.Position         = UDim2.new(1,-108,0.5,-14)
	cycleBtn.BackgroundColor3 = REDZ.AccentDim
	cycleBtn.BorderSizePixel  = 0
	cycleBtn.Text             = bones[idx]
	cycleBtn.TextColor3       = REDZ.AccentGlow
	cycleBtn.Font             = Enum.Font.GothamBold
	cycleBtn.TextSize         = 11
	Instance.new("UICorner", cycleBtn).CornerRadius = UDim.new(0,6)
	cycleBtn.MouseButton1Click:Connect(function()
		idx = (idx % #bones) + 1
		CONFIG.TargetBone = bones[idx]
		cycleBtn.Text     = bones[idx]
	end)
	return row
end

local escapePage = MakePage(); pages["escape"]  = escapePage
local escapeBtn  = MakeSidebarBtn("🔓","Escape","escape")
MakeSectionLabel(escapePage, "AUTO ESCAPE")
local _, escGet, _ = MakeToggleRow(escapePage, "Auto Escape",
	"Physics-bypass TP keluar penjara ke Crim Base")

local combatPage = MakePage(); pages["combat"]  = combatPage
local combatSBtn = MakeSidebarBtn("⚔","Combat","combat")
MakeSectionLabel(combatPage, "SILENT AIM")
local _, silentGet, _ = MakeToggleRow(combatPage, "Silent Aim",
	"Namecall + Raycast hook — redirect hit ke target bone")
MakeBoneCycleRow(combatPage)
MakeSliderRow(combatPage, "FOV Radius", 30, 400, (CONFIG.SilentAimFOV-30)/370, " px", function(val)
	CONFIG.SilentAimFOV = val; fovCircle.Radius = val
end)
MakeSectionLabel(combatPage, "WEAPON")
local _, noRecoilGet, _ = MakeToggleRow(combatPage, "No Recoil / No Spread",
	"Patch gun module + lock NumberValues ke 0")

local vehiclePage = MakePage(); pages["vehicle"] = vehiclePage
local vehicleSBtn = MakeSidebarBtn("🚗","Vehicle","vehicle")
MakeSectionLabel(vehiclePage, "SPEED PUSH")
local _, vehicleGet, _ = MakeToggleRow(vehiclePage, "Vehicle Speed Push",
	"AssemblyLinearVelocity saat W ditekan — chassis-safe")
MakeSliderRow(vehiclePage, "Push Speed", 50, 800, (CONFIG.VehicleSpeed-50)/750, " stud/s", function(val)
	CONFIG.VehicleSpeed = val
end)
MakeSectionLabel(vehiclePage, "NITRO")
local _, nitroGet, _ = MakeToggleRow(vehiclePage, "Infinite Nitro",
	"Lock nitro ke 100% on Shift/Q keydown — no loop lag")

local espPage  = MakePage(); pages["esp"]  = espPage
local espSBtn  = MakeSidebarBtn("👁","ESP","esp")
MakeSectionLabel(espPage, "WALLHACK")
local _, espGet, _    = MakeToggleRow(espPage, "ESP Highlight",
	"Highlight + distance label [Ns] — Biru=Police Merah=Crim")
local _, tracerGet, _ = MakeToggleRow(espPage, "Tracers",
	"Drawing Line — cleanup per frame, no memory leak")

local movePage  = MakePage(); pages["movement"]  = movePage
local moveSBtn  = MakeSidebarBtn("👟","Movement","movement")
MakeSectionLabel(movePage, "WALK SPEED")
local _, fastRunGet, _ = MakeToggleRow(movePage, "Fast Run",
	"GetPropertyChangedSignal — reset proof, no Heartbeat loop")
MakeSliderRow(movePage, "Walk Speed", 16, 150,
	(CONFIG.WalkSpeed - 16) / 134, " stud/s",
	function(val)
		CONFIG.WalkSpeed = val
		if CONFIG.FastRun then ApplyWalkSpeed() end
	end
)

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

WireToggle(escGet,      "AutoEscape",  StartAutoEscape, nil)
WireToggle(silentGet,   "SilentAim",   nil, function() silentTarget = nil fovCircle.Visible = false end)
WireToggle(noRecoilGet, "NoRecoil",    ApplyNoRecoil, ApplyNoRecoil)
WireToggle(vehicleGet,  "VehicleMods",
	function() lastSeat = nil StartVehiclePush() end,
	function()
		if vehiclePushConn then vehiclePushConn:Disconnect() vehiclePushConn = nil end
		lastSeat = nil
	end
)
WireToggle(nitroGet, "InfiniteNitro", StartInfiniteNitro,
	function() if nitroConn then nitroConn:Disconnect() nitroConn = nil end end)
WireToggle(espGet, "ESP",
	function()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then CreateHighlight(p) end
		end
	end,
	function()
		for p in pairs(ESP_Highlights) do RemoveHighlight(p) end
	end
)
WireToggle(tracerGet, "Tracers", nil, function()
	for p, line in pairs(ESP_Tracers) do line:Remove() ESP_Tracers[p] = nil end
end)
WireToggle(fastRunGet, "FastRun", StartFastRun, StartFastRun)

escapeBtn.MouseButton1Click:Connect(function()   SetActivePage("escape")   end)
combatSBtn.MouseButton1Click:Connect(function()   SetActivePage("combat")   end)
vehicleSBtn.MouseButton1Click:Connect(function()  SetActivePage("vehicle")  end)
espSBtn.MouseButton1Click:Connect(function()      SetActivePage("esp")      end)
moveSBtn.MouseButton1Click:Connect(function()     SetActivePage("movement") end)
SetActivePage("combat")

local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
	contentVisible = not contentVisible
	sidebar.Visible = contentVisible; contentArea.Visible = contentVisible
	mainWindow.Size = contentVisible and UDim2.new(0,580,0,420) or UDim2.new(0,580,0,42)
end)

closeBtn.MouseButton1Click:Connect(function()
	CONFIG.AutoEscape = false; CONFIG.SilentAim = false
	CONFIG.NoRecoil   = false; CONFIG.VehicleMods = false
	CONFIG.InfiniteNitro = false; CONFIG.ESP = false
	CONFIG.Tracers = false; CONFIG.FastRun = false
	for p in pairs(ESP_Highlights) do RemoveHighlight(p) end
	for p, line in pairs(ESP_Tracers) do line:Remove() ESP_Tracers[p] = nil end
	for p, lbl in pairs(ESP_Labels) do lbl:Remove() ESP_Labels[p] = nil end
	if noRecoilConn    then noRecoilConn:Disconnect()    end
	if nitroConn       then nitroConn:Disconnect()       end
	if vehiclePushConn then vehiclePushConn:Disconnect() end
	if walkSpeedConn   then walkSpeedConn:Disconnect()   end
	fovCircle:Remove(); screenGui:Destroy()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	LocalCharacter = char
	LocalRoot      = char:WaitForChild("HumanoidRootPart")
	LocalHumanoid  = char:WaitForChild("Humanoid")
	silentTarget   = nil; lastSeat = nil
	if walkSpeedConn then walkSpeedConn:Disconnect() walkSpeedConn = nil end
	task.wait(1)
	if CONFIG.ESP then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then CreateHighlight(p) end
		end
	end
	if CONFIG.AutoEscape  then StartAutoEscape()  end
	if CONFIG.VehicleMods then StartVehiclePush() end
	if CONFIG.FastRun     then StartFastRun()     end
end)

WatchSeat()

local tracerTick = 0
local espLabelTick = 0
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

	local now = tick()

	if CONFIG.Tracers and (now - tracerTick) >= 0.05 then
		tracerTick = now
		UpdateTracers()
	elseif not CONFIG.Tracers then
		for p, line in pairs(ESP_Tracers) do line:Remove() ESP_Tracers[p] = nil end
	end

	if CONFIG.ESP and (now - espLabelTick) >= 0.05 then
		espLabelTick = now
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				UpdateESPLabel(player)
			end
		end
	elseif not CONFIG.ESP then
		for _, lbl in pairs(ESP_Labels) do lbl.Visible = false end
	end
end)
