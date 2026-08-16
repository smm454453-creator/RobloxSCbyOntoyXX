-- ============================================================
-- ONTOY HUB — Blox Fruits Auto Farm & Quest Framework (REACH & SPAM FIX)
-- Style: Ontoy Hub (Dark Red Theme - Full UI)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Config = {
	AutoFarm = false,
	AutoQuest = false,
	SelectedWeapon = "Melee",
	Weapons = {"Melee", "Sword", "Blox Fruit"},
	TargetDistance = 19, -- Diset 19 sesuai screenshot kamu
}

local State = {
	FarmConn = nil,
	AttackLoop = false,
	CurrentTarget = nil
}

-- ── CORE FUNCTIONS ─────────────────────────────────────────────────────────

local function GetWeapon()
	local char = LocalPlayer.Character
	if not char then return nil end
	for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == Config.SelectedWeapon then
			return tool
		end
	end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == Config.SelectedWeapon then
			return tool
		end
	end
	return nil
end

local function FindNearestMob()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	
	local closestMob = nil
	local shortestDist = 1500
	
	local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace
	for _, mob in ipairs(enemiesFolder:GetChildren()) do
		if mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
			local dist = (mob.HumanoidRootPart.Position - root.Position).Magnitude
			if dist < shortestDist then 
				shortestDist = dist
				closestMob = mob
			end
		end
	end
	return closestMob
end

-- ── FARMING & QUEST LOOP ───────────────────────────────────────────────────

local function StartFarming()
	if State.AttackLoop then return end
	State.AttackLoop = true
	
	task.spawn(function()
		while State.AttackLoop do
			if Config.AutoFarm then
				State.CurrentTarget = FindNearestMob()
			end
			task.wait(0.2) 
		end
	end)
	
	-- Loop Posisi & HITBOX EXPANDER (Jangkauan Luas)
	State.FarmConn = RunService.Heartbeat:Connect(function()
		if not Config.AutoFarm then return end
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		
		if State.CurrentTarget and State.CurrentTarget:FindFirstChild("HumanoidRootPart") and State.CurrentTarget:FindFirstChild("Humanoid") and State.CurrentTarget.Humanoid.Health > 0 then
			local targetHRP = State.CurrentTarget.HumanoidRootPart
			
			-- [FITUR BARU] Hitbox Expander: Bikin badan musuh jadi raksasa (60x60x60)
			-- Biar walaupun kamu terbang jauh, pukulanmu tetep kena "badan" nya
			targetHRP.Size = Vector3.new(60, 60, 60)
			targetHRP.Transparency = 0.8 -- Dibikin sedikit transparan biar layar ga ketutup musuh
			targetHRP.CanCollide = false
			
			local targetCFrame = targetHRP.CFrame
			root.CFrame = targetCFrame * CFrame.new(0, Config.TargetDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
			root.Velocity = Vector3.zero
		else
			State.CurrentTarget = nil
		end
	end)
	
	-- Loop Serangan (FAST ATTACK / SPAM HIT)
	task.spawn(function()
		while State.AttackLoop do
			if Config.AutoFarm and State.CurrentTarget then
				local char = LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				
				if char and hum then
					local weapon = GetWeapon()
					if weapon and weapon.Parent == LocalPlayer.Backpack then
						hum:EquipTool(weapon)
					end
					
					if weapon and weapon.Parent == char then
						weapon:Activate()
						pcall(function()
							VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
							VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
						end)
					end
				end
			end
			task.wait(0.05) -- [FITUR BARU] Delay dikurangi drastis jadi 0.05 detik biar nge-spam banget!
		end
	end)
end

local function StopFarming()
	State.AttackLoop = false
	if State.FarmConn then
		State.FarmConn:Disconnect()
		State.FarmConn = nil
	end
end

-- ============================================================
-- GUI — Ontoy Hub Style (Full Dark Red Theme)
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OntoyHub_AutoFarm"
screenGui.ResetOnSpawn = false
if LocalPlayer.PlayerGui:FindFirstChild("OntoyHub_AutoFarm") then
	LocalPlayer.PlayerGui:FindFirstChild("OntoyHub_AutoFarm"):Destroy()
end
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local REDZ = {
	BG = Color3.fromRGB(14,12,16), BG2 = Color3.fromRGB(20,16,22),
	Accent = Color3.fromRGB(200,30,50), AccentDim = Color3.fromRGB(120,20,35),
	AccentGlow= Color3.fromRGB(255,60,80), TextMain = Color3.fromRGB(240,220,225),
	TextSub = Color3.fromRGB(130,100,110), Stroke = Color3.fromRGB(60,30,40),
	ToggleOff = Color3.fromRGB(40,32,36), SliderFill = Color3.fromRGB(200,30,50),
	SliderBG = Color3.fromRGB(35,28,32),
}

local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(0,420,0,440) 
mainWindow.Position = UDim2.new(0.5,-210,0.5,-190)
mainWindow.BackgroundColor3 = REDZ.BG
mainWindow.BorderSizePixel = 0
mainWindow.Active = true
mainWindow.Parent = screenGui
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0,10)
local mStroke = Instance.new("UIStroke", mainWindow)
mStroke.Color = REDZ.Stroke; mStroke.Thickness = 1.5

-- TITLE BAR
local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size = UDim2.new(1,0,0,42)
titleBar.BackgroundColor3 = REDZ.BG2
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local accentLine = Instance.new("Frame", titleBar)
accentLine.Size = UDim2.new(1,0,0,2)
accentLine.Position = UDim2.new(0,0,1,-2)
accentLine.BackgroundColor3 = REDZ.Accent
accentLine.BorderSizePixel = 0

local logoDot = Instance.new("Frame", titleBar)
logoDot.Size = UDim2.new(0,8,0,8)
logoDot.Position = UDim2.new(0,14,0.5,-4)
logoDot.BackgroundColor3 = REDZ.AccentGlow
logoDot.BorderSizePixel = 0
Instance.new("UICorner", logoDot).CornerRadius = UDim.new(0,4)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1,-80,1,0)
titleText.Position = UDim2.new(0,30,0,0)
titleText.BackgroundTransparency = 1
titleText.Text = "ONTOY HUB  <font color='#C81E32'>·</font>  Blox Fruits Auto Farm"
titleText.RichText = true
titleText.TextColor3 = REDZ.TextMain
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 12
titleText.TextXAlignment = Enum.TextXAlignment.Left

-- Drag Logic
local dragging, dragStart, dragPos = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true; dragStart = Vector2.new(i.Position.X, i.Position.Y); dragPos = mainWindow.Position
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local d = Vector2.new(i.Position.X, i.Position.Y) - dragStart
		mainWindow.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + d.X, dragPos.Y.Scale, dragPos.Y.Offset + d.Y)
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local function MakeBtn(xOff, bg, txt)
	local btn = Instance.new("TextButton", titleBar)
	btn.Size = UDim2.new(0,26,0,26)
	btn.Position = UDim2.new(1,xOff,0.5,-13)
	btn.BackgroundColor3 = bg
	btn.Text = txt
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.BorderSizePixel = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
	return btn
end
local closeBtn = MakeBtn(-34, REDZ.Accent, "✕")
local minimizeBtn = MakeBtn(-66, REDZ.ToggleOff, "—")

-- SCROLL CONTENT
local contentScroll = Instance.new("ScrollingFrame", mainWindow)
contentScroll.Size = UDim2.new(1,-16,1,-54)
contentScroll.Position = UDim2.new(0,8,0,50)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 3
contentScroll.ScrollBarImageColor3 = REDZ.AccentDim
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local contentLayout = Instance.new("UIListLayout", contentScroll)
contentLayout.Padding = UDim.new(0,6)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentScroll).PaddingTop = UDim.new(0,8)
Instance.new("UIPadding", contentScroll).PaddingBottom = UDim.new(0,8)

local function MakeSectionLabel(text)
	local lbl = Instance.new("TextLabel", contentScroll)
	lbl.Size = UDim2.new(1,-8,0,18)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = REDZ.Accent
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function MakeCycleRow(label, options, initIndex, callback)
	local row = Instance.new("Frame", contentScroll)
	row.Size = UDim2.new(1,-8,0,42)
	row.BackgroundColor3 = REDZ.BG2
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1
	local titleLbl = Instance.new("TextLabel", row)
	titleLbl.Size = UDim2.new(0,150,1,0); titleLbl.Position = UDim2.new(0,14,0,0)
	titleLbl.BackgroundTransparency = 1; titleLbl.Text = label
	titleLbl.TextColor3 = REDZ.TextMain; titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 12
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", row)
	btn.Size = UDim2.new(0,130,0,26); btn.Position = UDim2.new(1,-144,0.5,-13)
	btn.BackgroundColor3 = REDZ.ToggleOff; btn.TextColor3 = REDZ.AccentGlow
	btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
	local bStroke = Instance.new("UIStroke", btn); bStroke.Color = REDZ.Stroke; bStroke.Thickness = 1

	local currentIndex = initIndex or 1
	btn.Text = options[currentIndex]
	btn.MouseButton1Click:Connect(function()
		currentIndex = currentIndex + 1
		if currentIndex > #options then currentIndex = 1 end
		btn.Text = options[currentIndex]
		if callback then callback(options[currentIndex]) end
	end)
end

local function MakeSliderRow(label, min, max, default, callback)
	local row = Instance.new("Frame", contentScroll)
	row.Size = UDim2.new(1,-8,0,52)
	row.BackgroundColor3 = REDZ.BG2
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1

	local titleLbl = Instance.new("TextLabel", row)
	titleLbl.Size = UDim2.new(1,-28,0,22); titleLbl.Position = UDim2.new(0,14,0,6)
	titleLbl.BackgroundTransparency = 1; titleLbl.Text = label .. " : " .. tostring(default)
	titleLbl.TextColor3 = REDZ.TextMain; titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 12; titleLbl.TextXAlignment = Enum.TextXAlignment.Left

	local sliderBG = Instance.new("TextButton", row)
	sliderBG.Size = UDim2.new(1,-28,0,10); sliderBG.Position = UDim2.new(0,14,0,32)
	sliderBG.BackgroundColor3 = REDZ.SliderBG; sliderBG.Text = ""
	Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0,5)

	local sliderFill = Instance.new("Frame", sliderBG)
	sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	sliderFill.BackgroundColor3 = REDZ.SliderFill
	Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0,5)
	
	local draggingSlider = false
	local function updateSlider(input)
		local pos = math.clamp((input.Position.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
		sliderFill.Size = UDim2.new(pos, 0, 1, 0)
		local val = math.floor(min + ((max - min) * pos))
		titleLbl.Text = label .. " : " .. tostring(val)
		if callback then callback(val) end
	end

	sliderBG.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = true
			updateSlider(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input)
		end
	end)
end

local function MakeToggleRow(label, sublabel, callback)
	local row = Instance.new("Frame", contentScroll)
	row.Size = UDim2.new(1,-8,0,52)
	row.BackgroundColor3 = REDZ.BG2
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1

	local titleLbl = Instance.new("TextLabel", row)
	titleLbl.Size = UDim2.new(1,-60,0,22); titleLbl.Position = UDim2.new(0,14,0,8)
	titleLbl.BackgroundTransparency = 1; titleLbl.Text = label
	titleLbl.TextColor3 = REDZ.TextMain; titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 12; titleLbl.TextXAlignment = Enum.TextXAlignment.Left

	local sub = Instance.new("TextLabel", row)
	sub.Size = UDim2.new(1,-60,0,16); sub.Position = UDim2.new(0,14,0,28)
	sub.BackgroundTransparency = 1; sub.Text = sublabel
	sub.TextColor3 = REDZ.TextSub; sub.Font = Enum.Font.Gotham
	sub.TextSize = 10; sub.TextXAlignment = Enum.TextXAlignment.Left

	local toggleBG = Instance.new("Frame", row)
	toggleBG.Size = UDim2.new(0,36,0,20); toggleBG.Position = UDim2.new(1,-48,0.5,-10)
	toggleBG.BackgroundColor3 = REDZ.ToggleOff; Instance.new("UICorner", toggleBG).CornerRadius = UDim.new(0,10)
	local knob = Instance.new("Frame", toggleBG)
	knob.Size = UDim2.new(0,14,0,14); knob.Position = UDim2.new(0,3,0.5,-7)
	knob.BackgroundColor3 = REDZ.TextSub; Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)

	local hitbox = Instance.new("TextButton", toggleBG)
	hitbox.Size = UDim2.new(1,8,1,8); hitbox.Position = UDim2.new(0,-4,0,-4)
	hitbox.BackgroundTransparency = 1; hitbox.Text = ""

	local state = false
	hitbox.MouseButton1Click:Connect(function()
		state = not state
		if state then
			toggleBG.BackgroundColor3 = REDZ.Accent; knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
			knob.Position = UDim2.new(1,-17,0.5,-7); row.BackgroundColor3 = Color3.fromRGB(24,14,18)
			stroke.Color = REDZ.AccentDim
		else
			toggleBG.BackgroundColor3 = REDZ.ToggleOff; knob.BackgroundColor3 = REDZ.TextSub
			knob.Position = UDim2.new(0,3,0.5,-7); row.BackgroundColor3 = REDZ.BG2
			stroke.Color = REDZ.Stroke
		end
		if callback then callback(state) end
	end)
end

-- ── BUILD UI COMPONENTS ──────────────────────────────────────────────────────

MakeSectionLabel("WEAPON CONFIGURATION")
MakeCycleRow("Select Weapon", Config.Weapons, 1, function(selected)
	Config.SelectedWeapon = selected
end)

MakeSectionLabel("FARMING MODES")

MakeSliderRow("Fly Distance (Tinggi dari NPC)", 5, 30, Config.TargetDistance, function(value)
	Config.TargetDistance = value
end)

MakeToggleRow("Auto Farm Level (Quest)", "(BETA) Perlu update database NPC", function(state)
	Config.AutoQuest = state
end)

MakeToggleRow("Auto Farm (Nearest Mob)", "Otomatis serang + Hitbox Expander + Fast Attack", function(state)
	Config.AutoFarm = state
	if state then StartFarming() else StopFarming() end
end)

-- ── MINIMIZE & CLOSE ──────────────────────────────────────────────────────────
local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
	contentVisible = not contentVisible
	contentScroll.Visible = contentVisible
	mainWindow.Size = contentVisible and UDim2.new(0,420,0,440) or UDim2.new(0,420,0,42)
end)

closeBtn.MouseButton1Click:Connect(function()
	Config.AutoFarm = false
	Config.AutoQuest = false
	StopFarming()
	screenGui:Destroy()
end)
