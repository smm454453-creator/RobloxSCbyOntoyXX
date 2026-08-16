-- ============================================================
-- AUTO FARM HUB — Standalone Script (Blox Fruits)
-- Style: Ontoy Hub (dark red theme)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ── CONFIGURATION & STATE ──────────────────────────────────────────────────
local Config = {
	AutoFarm = false,
	AutoMastery = false,
	SelectedWeapon = "Melee", -- Default
	Weapons = {"Melee", "Sword", "Blox Fruit"},
	TargetDistance = 5, -- Jarak teleport di atas musuh
}

-- ── CORE FUNCTIONS ─────────────────────────────────────────────────────────

-- Fungsi untuk mendapatkan nama tool berdasarkan tipe senjata
local function GetWeaponName()
	-- Catatan: Di Blox Fruits, kategori senjata ada di tooltip atau tipe.
	-- Untuk script sederhana, kita asumsikan player memegang item dengan tipe ini.
	for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == Config.SelectedWeapon then
			return tool.Name
		end
	end
	for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == Config.SelectedWeapon then
			return tool.Name
		end
	end
	return nil
end

-- Fungsi Auto Equip Senjata
local function EquipWeapon()
	pcall(function()
		local char = LocalPlayer.Character
		if not char then return end
		
		local weaponName = GetWeaponName()
		if weaponName then
			local tool = LocalPlayer.Backpack:FindFirstChild(weaponName)
			if tool then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:EquipTool(tool)
				end
			end
		end
	end)
end

-- Fungsi Auto Click (VirtualUser Bypass)
local function AutoClick()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton1(Vector2.new(851, 158))
	end)
end

-- Fungsi Auto Farm Logic
task.spawn(function()
	while task.wait() do
		if Config.AutoFarm or Config.AutoMastery then
			local char = LocalPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			
			if root then
				EquipWeapon()
				AutoClick()
				
				-- ============================================================
				-- CATATAN LOGIKA TELEPORT:
				-- Di script Auto Farm sungguhan, di sini tempat memasukkan 
				-- logika pengecekan Level -> Ambil Quest -> Cari NPC sesuai Quest.
				-- Contoh basic teleport ke musuh terdekat:
				-- ============================================================
				
				local closestMob = nil
				local shortestDist = math.huge
				
				-- Cari musuh di workspace (sesuaikan nama folder Enemies di BF)
				local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace
				for _, mob in ipairs(enemiesFolder:GetChildren()) do
					if mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
						local dist = (mob.HumanoidRootPart.Position - root.Position).Magnitude
						if dist < shortestDist and dist < 1000 then -- Batas deteksi 1000 stud
							shortestDist = dist
							closestMob = mob
						end
					end
				end
				
				if closestMob then
					-- Teleport tepat di atas kepala musuh (Bypass hit)
					root.CFrame = closestMob.HumanoidRootPart.CFrame * CFrame.new(0, Config.TargetDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
					
					if Config.AutoMastery then
						-- Jika Auto Mastery nyala, spam skill Z, X, C, V (opsional)
						-- VirtualInputManager bisa dipakai di sini
					end
				end
			end
		end
	end
end)

-- ============================================================
-- GUI — Ontoy Hub style (dark red theme)
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarm_Hub"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local REDZ = {
	BG = Color3.fromRGB(14,12,16), BG2 = Color3.fromRGB(20,16,22),
	Accent = Color3.fromRGB(200,30,50), AccentDim = Color3.fromRGB(120,20,35),
	AccentGlow= Color3.fromRGB(255,60,80), TextMain = Color3.fromRGB(240,220,225),
	TextSub = Color3.fromRGB(130,100,110), Stroke = Color3.fromRGB(60,30,40),
	ToggleOff = Color3.fromRGB(40,32,36),
}

local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(0,400,0,320)
mainWindow.Position = UDim2.new(0.5,-200,0.5,-160)
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
titleText.Text = "AUTO FARM  <font color='#C81E32'>·</font>  Level & Mastery"
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

-- Buttons
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
contentScroll.CanvasSize = UDim2.new(0,0,0,0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local contentLayout = Instance.new("UIListLayout", contentScroll)
contentLayout.Padding = UDim.new(0,6)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentScroll).PaddingTop = UDim.new(0,8)

-- ── WIDGET FACTORIES ─────────────────────────────────────────────────────────

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

local function MakeToggleRow(label, sublabel, callback)
	local row = Instance.new("Frame", contentScroll)
	row.Size = UDim2.new(1,-8,0,52)
	row.BackgroundColor3 = REDZ.BG2
	row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row)
	stroke.Color = REDZ.Stroke; stroke.Thickness = 1

	local titleLbl = Instance.new("TextLabel", row)
	titleLbl.Size = UDim2.new(1,-60,0,22)
	titleLbl.Position = UDim2.new(0,14,0,8)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = label
	titleLbl.TextColor3 = REDZ.TextMain
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 12
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left

	local sub = Instance.new("TextLabel", row)
	sub.Size = UDim2.new(1,-60,0,16)
	sub.Position = UDim2.new(0,14,0,28)
	sub.BackgroundTransparency = 1
	sub.Text = sublabel
	sub.TextColor3 = REDZ.TextSub
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 10
	sub.TextXAlignment = Enum.TextXAlignment.Left

	local toggleBG = Instance.new("Frame", row)
	toggleBG.Size = UDim2.new(0,36,0,20)
	toggleBG.Position = UDim2.new(1,-48,0.5,-10)
	toggleBG.BackgroundColor3 = REDZ.ToggleOff
	toggleBG.BorderSizePixel = 0
	Instance.new("UICorner", toggleBG).CornerRadius = UDim.new(0,10)

	local knob = Instance.new("Frame", toggleBG)
	knob.Size = UDim2.new(0,14,0,14)
	knob.Position = UDim2.new(0,3,0.5,-7)
	knob.BackgroundColor3 = REDZ.TextSub
	knob.BorderSizePixel = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)

	local hitbox = Instance.new("TextButton", toggleBG)
	hitbox.Size = UDim2.new(1,8,1,8)
	hitbox.Position = UDim2.new(0,-4,0,-4)
	hitbox.BackgroundTransparency = 1
	hitbox.Text = ""

	local state = false
	hitbox.MouseButton1Click:Connect(function()
		state = not state
		if state then
			toggleBG.BackgroundColor3 = REDZ.Accent
			knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
			knob.Position = UDim2.new(1,-17,0.5,-7)
			row.BackgroundColor3 = Color3.fromRGB(24,14,18)
			stroke.Color = REDZ.AccentDim
		else
			toggleBG.BackgroundColor3 = REDZ.ToggleOff
			knob.BackgroundColor3 = REDZ.TextSub
			knob.Position = UDim2.new(0,3,0.5,-7)
			row.BackgroundColor3 = REDZ.BG2
			stroke.Color = REDZ.Stroke
		end
		if callback then callback(state) end
	end)
end

local function MakeCycleRow(label, options, initIndex, callback)
	local row = Instance.new("Frame", contentScroll)
	row.Size = UDim2.new(1,-8,0,42)
	row.BackgroundColor3 = REDZ.BG2
	row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row)
	stroke.Color = REDZ.Stroke; stroke.Thickness = 1

	local titleLbl = Instance.new("TextLabel", row)
	titleLbl.Size = UDim2.new(0,150,1,0)
	titleLbl.Position = UDim2.new(0,14,0,0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = label
	titleLbl.TextColor3 = REDZ.TextMain
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 12
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", row)
	btn.Size = UDim2.new(0,120,0,26)
	btn.Position = UDim2.new(1,-134,0.5,-13)
	btn.BackgroundColor3 = REDZ.ToggleOff
	btn.BorderSizePixel = 0
	btn.TextColor3 = REDZ.AccentGlow
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
	local bStroke = Instance.new("UIStroke", btn)
	bStroke.Color = REDZ.Stroke; bStroke.Thickness = 1

	local currentIndex = initIndex or 1
	btn.Text = options[currentIndex]

	btn.MouseButton1Click:Connect(function()
		currentIndex = currentIndex + 1
		if currentIndex > #options then currentIndex = 1 end
		btn.Text = options[currentIndex]
		if callback then callback(options[currentIndex]) end
	end)
end

-- ── BUILD UI CONTENT ──────────────────────────────────────────────────────────

MakeSectionLabel("WEAPON CONFIGURATION")
MakeCycleRow("Select Weapon", Config.Weapons, 1, function(selected)
	Config.SelectedWeapon = selected
end)

MakeSectionLabel("AUTO FARMING")
MakeToggleRow("Auto Farm Level", "Otomatis farming musuh sesuai level", function(state)
	Config.AutoFarm = state
end)

MakeToggleRow("Auto Farm Mastery", "Otomatis farming untuk naikin mastery senjata", function(state)
	Config.AutoMastery = state
end)

-- ── MINIMIZE & CLOSE ──────────────────────────────────────────────────────────
local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
	contentVisible = not contentVisible
	contentScroll.Visible = contentVisible
	mainWindow.Size = contentVisible and UDim2.new(0,400,0,320) or UDim2.new(0,400,0,42)
end)

closeBtn.MouseButton1Click:Connect(function()
	Config.AutoFarm = false
	Config.AutoMastery = false
	screenGui:Destroy()
end)