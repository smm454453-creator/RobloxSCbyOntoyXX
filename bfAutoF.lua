-- ============================================================
-- AUTO FARM HUB (REVISI AUTO HIT) — Standalone Script
-- Style: Ontoy Hub (dark red theme)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Config = {
	AutoFarm = false,
	SelectedWeapon = "Melee", 
	Weapons = {"Melee", "Sword", "Blox Fruit"},
	TargetDistance = 5, -- Posisi 5 stud di atas musuh
}

-- ── 1. LOGIKA AUTO EQUIP YANG LEBIH AKURAT ────────────────────────────
local function EquipWeapon()
	pcall(function()
		local char = LocalPlayer.Character
		if not char then return end
		
		-- Cari senjata di Backpack berdasarkan ToolTip
		for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.ToolTip == Config.SelectedWeapon then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:EquipTool(tool)
				end
				break
			end
		end
	end)
end

-- ── 2. LOGIKA AUTO HIT (Bypass Xeno Hub / Layar) ──────────────────────
local function AutoClick()
	local char = LocalPlayer.Character
	if not char then return end
	
	-- Cara 1: Paksa aktifkan senjata langsung dari karakternya
	local equippedTool = char:FindFirstChildOfClass("Tool")
	if equippedTool then
		equippedTool:Activate()
	end
	
	-- Cara 2: Virtual Input Manager (Klik kiri universal tanpa koordinat layar)
	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
		VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
	end)
end

-- ── 3. CORE LOOP FARMING (Membidik Musuh Terdekat) ────────────────────
task.spawn(function()
	while task.wait() do
		if Config.AutoFarm then
			local char = LocalPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			
			if root then
				EquipWeapon()
				AutoClick()
				
				local closestMob = nil
				local shortestDist = math.huge
				
				local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace
				for _, mob in ipairs(enemiesFolder:GetChildren()) do
					if mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") and mob.Humanoid.Health > 0 then
						local dist = (mob.HumanoidRootPart.Position - root.Position).Magnitude
						if dist < shortestDist and dist < 1500 then 
							shortestDist = dist
							closestMob = mob
						end
					end
				end
				
				if closestMob then
					-- Posisi lu dikunci tepat di atas musuh biar serangan kena
					root.CFrame = closestMob.HumanoidRootPart.CFrame * CFrame.new(0, Config.TargetDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
				end
			end
		end
	end
end)

-- ============================================================
-- GUI BUILDER (MINIMALIS UNTUK HEMAT BARIS)
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarm_Hub"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local REDZ = { BG = Color3.fromRGB(14,12,16), Accent = Color3.fromRGB(200,30,50), TextMain = Color3.fromRGB(240,220,225) }

local mainWindow = Instance.new("Frame", screenGui)
mainWindow.Size = UDim2.new(0,300,0,200)
mainWindow.Position = UDim2.new(0.5,-150,0.5,-100)
mainWindow.BackgroundColor3 = REDZ.BG
mainWindow.Active = true; mainWindow.Draggable = true

local titleText = Instance.new("TextLabel", mainWindow)
titleText.Size = UDim2.new(1,0,0,30)
titleText.BackgroundColor3 = REDZ.Accent
titleText.Text = "  AUTO FARM (NEAREST MOB)"
titleText.TextColor3 = REDZ.TextMain
titleText.Font = Enum.Font.GothamBold; titleText.TextSize = 12
titleText.TextXAlignment = Enum.TextXAlignment.Left

-- Tombol Select Weapon
local weaponBtn = Instance.new("TextButton", mainWindow)
weaponBtn.Size = UDim2.new(0.8,0,0,35)
weaponBtn.Position = UDim2.new(0.1,0,0.3,0)
weaponBtn.BackgroundColor3 = Color3.fromRGB(40,32,36)
weaponBtn.TextColor3 = REDZ.TextMain
weaponBtn.Font = Enum.Font.GothamBold
weaponBtn.Text = "Weapon: " .. Config.SelectedWeapon
local weaponIndex = 1
weaponBtn.MouseButton1Click:Connect(function()
	weaponIndex = weaponIndex + 1
	if weaponIndex > #Config.Weapons then weaponIndex = 1 end
	Config.SelectedWeapon = Config.Weapons[weaponIndex]
	weaponBtn.Text = "Weapon: " .. Config.SelectedWeapon
end)

-- Tombol Auto Farm
local farmBtn = Instance.new("TextButton", mainWindow)
farmBtn.Size = UDim2.new(0.8,0,0,35)
farmBtn.Position = UDim2.new(0.1,0,0.6,0)
farmBtn.BackgroundColor3 = Color3.fromRGB(40,32,36)
farmBtn.TextColor3 = REDZ.TextMain
farmBtn.Font = Enum.Font.GothamBold
farmBtn.Text = "Auto Farm: OFF"
farmBtn.MouseButton1Click:Connect(function()
	Config.AutoFarm = not Config.AutoFarm
	if Config.AutoFarm then
		farmBtn.Text = "Auto Farm: ON"
		farmBtn.BackgroundColor3 = REDZ.Accent
	else
		farmBtn.Text = "Auto Farm: OFF"
		farmBtn.BackgroundColor3 = Color3.fromRGB(40,32,36)
	end
end)

-- Tombol Close
local closeBtn = Instance.new("TextButton", mainWindow)
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-30,0,0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.MouseButton1Click:Connect(function()
	Config.AutoFarm = false
	screenGui:Destroy()
end)
