local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
	Mode1 = false, Mode2 = false, Mode3 = false,
	Mode4 = false, Mode5 = false, Mode6 = false,
	Mode7 = false, Mode8 = false, Mode9 = false,
	Mode10 = false,
	HitboxPercent   = 1,
	SpeedPercent    = 50,
	Radius          = 15,
	AttackHPS       = 10,
	SilentAimFOV    = 120,
	FarmFlySpeed    = 300,
	FarmHoverHeight = 8.5,
}

local BASE_SPEED    = 16
local MAX_SPEED     = 500
local MIN_HITBOX    = 4
local MAX_HITBOX    = 80
local DASH_INTERVAL = 0.08
local MIN_FLY_Y     = 80
local QUEST_RADIUS  = 45

-- ============================================================
-- WORLD DETECTION
-- ============================================================
local World1, World2, World3 = false, false, false
local PlaceId = game.PlaceId
if PlaceId == 2753915549 or PlaceId == 85211729168715 then
	World1 = true
elseif PlaceId == 4442272183 or PlaceId == 79091703265657 then
	World2 = true
elseif PlaceId == 7449423635 or PlaceId == 100117331123089 then
	World3 = true
end

-- ============================================================
-- SERVICES & REMOTES
-- ============================================================
local Enemies   = Workspace:WaitForChild("Enemies")
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local CommF     = Remotes:WaitForChild("CommF_")
local Modules   = ReplicatedStorage:WaitForChild("Modules")
local Net       = require(Modules:WaitForChild("Net"))

local RegisterAttack, RegisterHit
pcall(function()
	RegisterAttack = Net:RemoteEvent("RegisterAttack", true)
	RegisterHit    = Net:RemoteEvent("RegisterHit", true)
end)
task.spawn(function()
	local ok = pcall(function()
		local net = ReplicatedStorage:WaitForChild("Modules",5):WaitForChild("Net",5)
		RegisterAttack = net:WaitForChild("RegisterAttack",5)
	end)
	if not ok or not RegisterAttack then
		RegisterAttack = ReplicatedStorage:FindFirstChild("RegisterAttack",true)
	end
end)

-- ============================================================
-- GLOBAL FARM STATE (from Relz)
-- ============================================================
local _G_Farm = {
	GlobalDelay        = 0.2,
	SelectedWeapon     = nil,
	SelectWeapon       = "Melee",
	FarmDistance       = 35,
	PlayerTweenSpeed   = 300,
	BringDistance      = 500,
	BringMob           = true,
	AttackAura         = false,
	MasteryHealth      = 25,
	SelectedFruitSkill = {"Z","X","C"},
	SelectedGunSkill   = {"Z","X"},
	-- toggles
	AutoFarmLevel      = false,
	AutoFarmNearest    = false,
	AutoFarmBoss       = false,
	AutoFarmAllBoss    = false,
	AutoFarmMon        = false,
	AutoFarmFruitMastery  = false,
	AutoFarmGunMastery    = false,
	AutoFarmSwordMastery  = false,
	SelectedMon        = nil,
	SelectedBoss       = nil,
	SelectedMasterySword  = nil,
	MasteryMethod      = "Level",
	AutoFarmMaterial   = false,
	SelectedMaterial   = nil,
	AutoFarmBone       = false,
	SelectedBoneFarmMethod = "No Quest",
	AutoFarmSeabeast   = false,
	AutoAttackSeabeasts= false,
	AutoFarmShark      = false,
	AutoFarmPiranha    = false,
	AutoFarmFishCrewMember = false,
	AutoFarmGhostShip  = false,
	AutoFarmPirateBrigade  = false,
	AutoFarmPirateGrandBrigade = false,
	AutoFarmTerrorshark= false,
	AutoFarmNearest    = false,
	SpinPosition       = false,
	Pos                = CFrame.new(0,35,0),
	StopTween          = false,
	-- bring state
	MonFarm            = "",
	PosMon             = CFrame.new(),
}

-- ============================================================
-- ONTOY STATE
-- ============================================================
local OriginalLocalSize = nil
local ESP_Objects       = {}
local lastDashTime      = 0
local dashHolding       = false
local dashConn          = nil
local fastAttackConn    = nil
local lastAttackTick    = 0
local currentFarmTween  = nil
local hoverAnchorPos    = nil
local hoverAnchorConn   = nil
local noclipConn        = nil
local silentTarget      = nil

-- ============================================================
-- LEVEL DATABASE (Ontoy)
-- ============================================================
local LevelDatabase = {
	{Sea=1,MinLvl=1,    MaxLvl=9,    Island="Starter Island",   MobFolder="Enemies",MobName="Bandit",             QuestName="BanditQuest",     QuestNum=1,NPCCFrame=CFrame.new(977.8,6.4,1574.1)},
	{Sea=1,MinLvl=10,   MaxLvl=14,   Island="Jungle",           MobFolder="Enemies",MobName="Monkey",             QuestName="JungleQuest",     QuestNum=1,NPCCFrame=CFrame.new(-1600,36,153)},
	{Sea=1,MinLvl=15,   MaxLvl=29,   Island="Jungle",           MobFolder="Enemies",MobName="Gorilla",            QuestName="JungleQuest",     QuestNum=2,NPCCFrame=CFrame.new(-1600,36,153)},
	{Sea=1,MinLvl=30,   MaxLvl=59,   Island="Pirate Village",   MobFolder="Enemies",MobName="Pirate",             QuestName="PirateQuest",     QuestNum=1,NPCCFrame=CFrame.new(-1142.2,4,3828.9)},
	{Sea=1,MinLvl=60,   MaxLvl=89,   Island="Desert",           MobFolder="Enemies",MobName="Desert Bandit",      QuestName="DesertQuest",     QuestNum=1,NPCCFrame=CFrame.new(924.5,5.5,4446.3)},
	{Sea=1,MinLvl=90,   MaxLvl=119,  Island="Frozen Village",   MobFolder="Enemies",MobName="Snow Bandit",        QuestName="SnowQuest",       QuestNum=1,NPCCFrame=CFrame.new(-1332,5,-3050)},
	{Sea=1,MinLvl=120,  MaxLvl=149,  Island="Marine Fortress",  MobFolder="Enemies",MobName="Marine",             QuestName="MarineQuest",     QuestNum=1,NPCCFrame=CFrame.new(4240,33,716)},
	{Sea=1,MinLvl=150,  MaxLvl=174,  Island="Skylands",         MobFolder="Enemies",MobName="Sky Bandit",         QuestName="SkyQuest",        QuestNum=1,NPCCFrame=CFrame.new(498,858,-1301)},
	{Sea=1,MinLvl=175,  MaxLvl=209,  Island="Prison",           MobFolder="Enemies",MobName="Prisoner",           QuestName="PrisonQuest",     QuestNum=1,NPCCFrame=CFrame.new(27,73,-3312)},
	{Sea=1,MinLvl=210,  MaxLvl=249,  Island="Colosseum",        MobFolder="Enemies",MobName="Toga Warrior",       QuestName="ColosseumQuest",  QuestNum=1,NPCCFrame=CFrame.new(-2027,7,-3009)},
	{Sea=1,MinLvl=250,  MaxLvl=299,  Island="Magma Village",    MobFolder="Enemies",MobName="Magma Ninja",        QuestName="MagmaQuest",      QuestNum=1,NPCCFrame=CFrame.new(450,126,-4800)},
	{Sea=1,MinLvl=300,  MaxLvl=374,  Island="Upper Skylands",   MobFolder="Enemies",MobName="Sky Pirate",         QuestName="UpperSkyQuest",   QuestNum=1,NPCCFrame=CFrame.new(-2418,1437,1887)},
	{Sea=1,MinLvl=375,  MaxLvl=424,  Island="Fountain City",    MobFolder="Enemies",MobName="Galley Pirate",      QuestName="FountainQuest",   QuestNum=1,NPCCFrame=CFrame.new(-779.8,72.5,-3463.8)},
	{Sea=1,MinLvl=425,  MaxLvl=474,  Island="Fountain City",    MobFolder="Enemies",MobName="Galley Pirate",      QuestName="FountainQuest",   QuestNum=2,NPCCFrame=CFrame.new(-779.8,72.5,-3463.8)},
	{Sea=1,MinLvl=475,  MaxLvl=524,  Island="Elegant Speedster",MobFolder="Enemies",MobName="Dark Master",        QuestName="DarkMasterQuest", QuestNum=1,NPCCFrame=CFrame.new(-1463,92,3846)},
	{Sea=1,MinLvl=525,  MaxLvl=624,  Island="Cafe",             MobFolder="Enemies",MobName="Assassin",           QuestName="AssassinQuest",   QuestNum=1,NPCCFrame=CFrame.new(3581.2,33.8,3281.6)},
	{Sea=2,MinLvl=625,  MaxLvl=699,  Island="Kingdom of Rose",  MobFolder="Enemies",MobName="Factory Staff",      QuestName="RoseQuest",       QuestNum=1,NPCCFrame=CFrame.new(-324,68,-1437.1)},
	{Sea=2,MinLvl=700,  MaxLvl=774,  Island="Kingdom of Rose",  MobFolder="Enemies",MobName="Citizen",            QuestName="RoseQuest",       QuestNum=2,NPCCFrame=CFrame.new(-324,68,-1437.1)},
	{Sea=2,MinLvl=775,  MaxLvl=849,  Island="Green Zone",       MobFolder="Enemies",MobName="Saber Expert",       QuestName="GreenZoneQuest",  QuestNum=1,NPCCFrame=CFrame.new(-4900,28,-1600)},
	{Sea=2,MinLvl=850,  MaxLvl=924,  Island="Graveyard",        MobFolder="Enemies",MobName="Zombie",             QuestName="GraveyardQuest",  QuestNum=1,NPCCFrame=CFrame.new(5212,17,3585)},
	{Sea=2,MinLvl=925,  MaxLvl=999,  Island="Snow Mountain",    MobFolder="Enemies",MobName="Snow Lurker",        QuestName="SnowMtnQuest",    QuestNum=1,NPCCFrame=CFrame.new(-4000,487,4200)},
	{Sea=2,MinLvl=1000, MaxLvl=1049, Island="Hot and Cold",     MobFolder="Enemies",MobName="Snow Demon",         QuestName="HotColdQuest",    QuestNum=1,NPCCFrame=CFrame.new(-2090,96,-2505)},
	{Sea=2,MinLvl=1050, MaxLvl=1099, Island="Hot and Cold",     MobFolder="Enemies",MobName="Ice Demon",          QuestName="HotColdQuest",    QuestNum=2,NPCCFrame=CFrame.new(-2090,96,-2505)},
	{Sea=2,MinLvl=1100, MaxLvl=1174, Island="Cursed Ship",      MobFolder="Enemies",MobName="Ship Deckhand",      QuestName="CursedShipQuest", QuestNum=1,NPCCFrame=CFrame.new(-4900,28,830)},
	{Sea=2,MinLvl=1175, MaxLvl=1249, Island="Ice Castle",       MobFolder="Enemies",MobName="Ice Cream Staff",    QuestName="IceCastleQuest",  QuestNum=1,NPCCFrame=CFrame.new(550,207,-5400)},
	{Sea=2,MinLvl=1250, MaxLvl=1349, Island="Forgotten Island", MobFolder="Enemies",MobName="Diablo",             QuestName="ForgottenQuest",  QuestNum=1,NPCCFrame=CFrame.new(1500,16,-2770)},
	{Sea=2,MinLvl=1350, MaxLvl=1474, Island="Labyrinth",        MobFolder="Enemies",MobName="Labyrinth Monster",  QuestName="LabyrinthQuest",  QuestNum=1,NPCCFrame=CFrame.new(-5680,285,-970)},
	{Sea=2,MinLvl=1475, MaxLvl=1574, Island="Labyrinth",        MobFolder="Enemies",MobName="Labyrinth Monster",  QuestName="LabyrinthQuest",  QuestNum=2,NPCCFrame=CFrame.new(-5680,285,-970)},
	{Sea=3,MinLvl=1575, MaxLvl=1674, Island="Port Town",        MobFolder="Enemies",MobName="Marine Lieutnant",   QuestName="PortTownQuest",   QuestNum=1,NPCCFrame=CFrame.new(-4033,35,-1714)},
	{Sea=3,MinLvl=1675, MaxLvl=1774, Island="Hydra Island",     MobFolder="Enemies",MobName="Giant Squid",        QuestName="HydraQuest",      QuestNum=1,NPCCFrame=CFrame.new(1299,70,1040)},
	{Sea=3,MinLvl=1775, MaxLvl=1874, Island="Great Tree",       MobFolder="Enemies",MobName="Forest Pirate",      QuestName="GreatTreeQuest",  QuestNum=1,NPCCFrame=CFrame.new(576,85,-5900)},
	{Sea=3,MinLvl=1875, MaxLvl=1974, Island="Floating Turtle",  MobFolder="Enemies",MobName="Fishman Pirate",     QuestName="TurtleQuest",     QuestNum=1,NPCCFrame=CFrame.new(-3345,483,5710)},
	{Sea=3,MinLvl=1975, MaxLvl=2074, Island="Floating Turtle",  MobFolder="Enemies",MobName="Mythological Pirate",QuestName="TurtleQuest",     QuestNum=2,NPCCFrame=CFrame.new(-3345,483,5710)},
	{Sea=3,MinLvl=2075, MaxLvl=2199, Island="Haunted Castle",   MobFolder="Enemies",MobName="Reborn Skeleton",    QuestName="HauntedQuest",    QuestNum=1,NPCCFrame=CFrame.new(5900,1000,-700)},
	{Sea=3,MinLvl=2200, MaxLvl=2374, Island="Sea of Treats",    MobFolder="Enemies",MobName="Cookie Crafter",     QuestName="TreatsQuest",     QuestNum=1,NPCCFrame=CFrame.new(-2200,57,-5500)},
	{Sea=3,MinLvl=2375, MaxLvl=2524, Island="Sea of Treats",    MobFolder="Enemies",MobName="Cake Guard",         QuestName="TreatsQuest",     QuestNum=2,NPCCFrame=CFrame.new(-2200,57,-5500)},
	{Sea=3,MinLvl=2525, MaxLvl=2674, Island="Tiki Outpost",     MobFolder="Enemies",MobName="Tiki Outpost Guard", QuestName="TikiQuest",       QuestNum=1,NPCCFrame=CFrame.new(-16550,85,-14.5)},
	{Sea=3,MinLvl=2675, MaxLvl=2799, Island="Tiki Outpost",     MobFolder="Enemies",MobName="Tiki Outpost Guard", QuestName="TikiQuest",       QuestNum=2,NPCCFrame=CFrame.new(-16550,85,-14.5)},
	{Sea=3,MinLvl=2800, MaxLvl=2999, Island="Mirage Island",    MobFolder="Enemies",MobName="Demonic Soul",       QuestName="MirageQuest",     QuestNum=1,NPCCFrame=CFrame.new(-2800,34,3050)},
	{Sea=3,MinLvl=3000, MaxLvl=9999, Island="Mirage Island",    MobFolder="Enemies",MobName="Demonic Soul",       QuestName="MirageQuest",     QuestNum=2,NPCCFrame=CFrame.new(-2800,34,3050)},
}

-- ============================================================
-- BOSS TABLES (from Relz)
-- ============================================================
local tableBoss = {}
if World1 then
	tableBoss = {"The Gorilla King","Bobby","Yeti","Mob Leader","Vice Admiral","Warden","Chief Warden","Swan","Magma Admiral","Fishman Lord","Wysper","Thunder God","Cyborg","Saber Expert"}
elseif World2 then
	tableBoss = {"Diamond","Jeremy","Fajita","Don Swan","Smoke Admiral","Cursed Captain","Darkbeard","Order","Awakened Ice Admiral","Tide Keeper"}
elseif World3 then
	tableBoss = {"Stone","Island Empress","Kilo Admiral","Captain Elephant","Beautiful Pirate","rip_indra True Form","Longma","Soul Reaper","Cake Queen","Tyrant Of The Skies"}
end

-- ============================================================
-- MATERIAL CONFIG (from Relz)
-- ============================================================
local MaterialMon, MaterialPos

local function getConfigMaterial(Material)
	if Material == "Magma Ore" and World1 then
		MaterialMon = {"Military Spy"}; MaterialPos = CFrame.new(-5850.28,77.29,8848.67)
	elseif Material == "Magma Ore" and World2 then
		MaterialMon = {"Lava Pirate"}; MaterialPos = CFrame.new(-5234.61,51.95,-4732.28)
	elseif Material == "Angel Wings" and World1 then
		MaterialMon = {"Royal Soldier"}; MaterialPos = CFrame.new(-7827.16,5606.91,-1705.58)
	elseif Material == "Leather" and World1 then
		MaterialMon = {"Pirate"}; MaterialPos = CFrame.new(-1211.88,4.79,3916.83)
	elseif Material == "Leather" and World2 then
		MaterialMon = {"Marine Captain"}; MaterialPos = CFrame.new(-2010.51,73.0,-3326.62)
	elseif Material == "Leather" and World3 then
		MaterialMon = {"Jungle Pirate"}; MaterialPos = CFrame.new(-11975.79,331.77,-10620.03)
	elseif Material == "Radioactive" and World2 then
		MaterialMon = {"Factory Staff"}; MaterialPos = CFrame.new(-507.79,73.0,-126.46)
	elseif Material == "Mystic Droplet" and World2 then
		MaterialMon = {"Water Fighter"}; MaterialPos = CFrame.new(-3352.9,285.02,-10534.84)
	elseif Material == "Scrap Metal" and World1 then
		MaterialMon = {"Brute"}; MaterialPos = CFrame.new(-1132.42,14.84,4293.31)
	elseif Material == "Scrap Metal" and World2 then
		MaterialMon = {"Mercenary"}; MaterialPos = CFrame.new(-972.31,73.04,1419.29)
	elseif Material == "Scrap Metal" and World3 then
		MaterialMon = {"Pirate Millionaire"}; MaterialPos = CFrame.new(-289.63,43.83,5583.66)
	elseif Material == "Conjured Cocoa" and World3 then
		MaterialMon = {"Chocolate Bar Battler"}; MaterialPos = CFrame.new(744.79,24.77,-12637.73)
	elseif Material == "Dragon Scale" and World3 then
		MaterialMon = {"Dragon Crew Warrior"}; MaterialPos = CFrame.new(5824.07,51.39,-1106.69)
	elseif Material == "Gunpowder" and World3 then
		MaterialMon = {"Pistol Billionaire"}; MaterialPos = CFrame.new(-379.61,73.84,5928.53)
	elseif Material == "Fish Tail" and World3 then
		MaterialMon = {"Fishman Captain"}; MaterialPos = CFrame.new(-10961.01,331.8,-8914.29)
	elseif Material == "Ectoplasm" and World2 then
		MaterialMon = {"Ship Deckhand","Ship Engineer","Ship Steward","Ship Officer"}
		MaterialPos = CFrame.new(911.36,125.96,33159.54)
	end
end

-- ============================================================
-- HELPER: GET LEVEL / FARM DATA
-- ============================================================
local function GetMyLevel()
	local ok, v = pcall(function() return LocalPlayer.Data.Level.Value end)
	return ok and v or 0
end

local function GetFarmData()
	local level = GetMyLevel()
	for _, data in ipairs(LevelDatabase) do
		if level >= data.MinLvl and level <= data.MaxLvl then
			return data, level
		end
	end
	return nil, level
end

-- ============================================================
-- RELZ HELPERS: TweenPlayer, Attack, AutoHaki, EquipWeapon
-- ============================================================
local isTeleporting = false

local function TweenPlayer(Pos)
	if not Pos then return end
	local char = LocalPlayer.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root and hum.Health > 0) then return end

	local distance = (Pos.Position - root.Position).Magnitude
	if not char:FindFirstChild("PartTele") then
		local p = Instance.new("Part", char)
		p.Size=Vector3.new(10,1,10); p.Name="PartTele"
		p.Anchored=true; p.CanCollide=true; p.Transparency=1
		p.CFrame = root.CFrame
		p:GetPropertyChangedSignal("CFrame"):Connect(function()
			if not isTeleporting then return end
			task.wait()
			local r = char and char:FindFirstChild("HumanoidRootPart")
			if r then r.CFrame = p.CFrame end
		end)
	end
	isTeleporting = true
	local tween = TweenService:Create(
		char.PartTele,
		TweenInfo.new(math.clamp(distance / _G_Farm.PlayerTweenSpeed, 0.05, 12), Enum.EasingStyle.Linear),
		{CFrame = Pos}
	)
	tween:Play()
	tween.Completed:Connect(function(s)
		if s == Enum.PlaybackState.Completed then isTeleporting = false end
	end)
end

local function InstantTp(cf)
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then root.CFrame = cf end
end

local function AutoHaki()
	local char = LocalPlayer.Character
	if char and not char:FindFirstChild("HasBuso") then
		pcall(function() CommF:InvokeServer("Buso") end)
	end
end

local function EquipWeapon(name)
	if not name then return end
	local char = LocalPlayer.Character
	if not char then return end
	if char:FindFirstChild(name) then return end
	local tool = LocalPlayer.Backpack:FindFirstChild(name)
	if tool then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum:EquipTool(tool) end
	end
end

local function GetSelectedWeapon()
	for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
		if v.ToolTip == _G_Farm.SelectWeapon then
			_G_Farm.SelectedWeapon = v.Name
			return v.Name
		end
	end
end

local function sendKeyEvent(skill)
	local kc = typeof(skill)=="EnumItem" and skill or Enum.KeyCode[skill]
	if not kc then return end
	VirtualInputManager:SendKeyEvent(true, kc, false, game)
	task.wait(0.05)
	VirtualInputManager:SendKeyEvent(false, kc, false, game)
end

local Skillaimbot    = false
local AimBotSkillPosition = Vector3.new()
local UseSkill       = false
local UseGunSkill    = false

-- Namecall hook for silent aim skill redirect
local gg = getrawmetatable(game)
local old_nc = gg.__namecall
setreadonly(gg, false)
gg.__namecall = newcclosure(function(...)
	local method = getnamecallmethod()
	local args   = {...}
	if tostring(method) == "FireServer" then
		if tostring(args[1]) == "RemoteEvent" then
			if tostring(args[2]) ~= "true" and tostring(args[2]) ~= "false" then
				if Skillaimbot then
					args[2] = AimBotSkillPosition
					return old_nc(unpack(args))
				end
			end
		end
	end
	return old_nc(...)
end)
setreadonly(gg, true)

-- Skill loops
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		pcall(function()
			if UseSkill then
				for _, sk in pairs(_G_Farm.SelectedFruitSkill) do
					sendKeyEvent(sk); task.wait(0.1)
				end
			end
		end)
	end
end)
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		pcall(function()
			if UseGunSkill then
				for _, sk in pairs(_G_Farm.SelectedGunSkill) do
					sendKeyEvent(sk); task.wait(0.1)
				end
			end
		end)
	end
end)

local function NormalAttack()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if RegisterAttack then
		pcall(function()
			local best, dist = nil, math.huge
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character then
					local r = p.Character:FindFirstChild("HumanoidRootPart")
					local h = p.Character:FindFirstChild("Humanoid")
					if r and h and h.Health > 0 then
						local d = (r.Position - root.Position).Magnitude
						if d < dist then dist=d; best=r end
					end
				end
			end
			for _, e in pairs(Enemies:GetChildren()) do
				local r = e:FindFirstChild("HumanoidRootPart")
				local h = e:FindFirstChild("Humanoid")
				if r and h and h.Health > 0 then
					local d = (r.Position - root.Position).Magnitude
					if d < dist then dist=d; best=r end
				end
			end
			if best then
				RegisterAttack:FireServer(0)
				if RegisterHit then RegisterHit:FireServer(best, {}) end
			end
		end)
	end
	-- also firetouchinterest on equipped tool
	local tool = char:FindFirstChildOfClass("Tool")
	if tool and tool:FindFirstChild("Handle") then
		pcall(function()
			local head = tool.Handle
			for _, e in pairs(Enemies:GetChildren()) do
				local r = e:FindFirstChild("HumanoidRootPart")
				local h = e:FindFirstChild("Humanoid")
				if r and h and h.Health > 0 and (r.Position-root.Position).Magnitude < 120 then
					firetouchinterest(head, r, 0)
					firetouchinterest(head, r, 1)
				end
			end
		end)
	end
end

local function Attack()
	GetSelectedWeapon()
	EquipWeapon(_G_Farm.SelectedWeapon)
	AutoHaki()
	NormalAttack()
end

-- ============================================================
-- AttackTarget (blocking repeat until dead)
-- ============================================================
local function AttackTarget(v, bring, stateFn)
	if not v or not v.Parent then return end
	repeat
		task.wait()
		if not stateFn() then return end
		AutoHaki()
		EquipWeapon(_G_Farm.SelectedWeapon)
		local r = v:FindFirstChild("HumanoidRootPart")
		if not r then break end
		if bring then
			_G_Farm.MonFarm = v.Name
			_G_Farm.PosMon  = r.CFrame
		end
		TweenPlayer(r.CFrame * _G_Farm.Pos)
		Attack()
	until not v or not v.Parent or not v:FindFirstChild("Humanoid")
		or v.Humanoid.Health <= 0 or not stateFn() or _G_Farm.StopTween
end

-- ============================================================
-- ONTOY: Hover, Noclip, Farm helpers
-- ============================================================
local function StartHoverAnchor(pos)
	if hoverAnchorConn then hoverAnchorConn:Disconnect(); hoverAnchorConn=nil end
	hoverAnchorPos = pos
	hoverAnchorConn = RunService.Heartbeat:Connect(function()
		if not hoverAnchorPos then hoverAnchorConn:Disconnect(); hoverAnchorConn=nil; return end
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = true end
		root.CFrame = CFrame.new(hoverAnchorPos)
		root.AssemblyLinearVelocity = Vector3.zero
	end)
end

local function StopHoverAnchor()
	hoverAnchorPos = nil
	if hoverAnchorConn then hoverAnchorConn:Disconnect(); hoverAnchorConn=nil end
end

local function StartNoclip()
	if noclipConn then return end
	noclipConn = RunService.Stepped:Connect(function()
		local char = LocalPlayer.Character
		if not char then return end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end)
end

local function HasActiveQuest()
	local ok, v = pcall(function()
		return LocalPlayer.PlayerGui.Main.Quest.Visible
	end)
	return ok and v == true
end

local NPCCFrameCache = {}
local NPC_CACHE_TTL  = 3

local function ScanForNPC()
	local candidates = {"NPCs","QuestGivers","Quest","Island"}
	local searchRoots = {}
	for _, n in ipairs(candidates) do
		local f = Workspace:FindFirstChild(n)
		if f then table.insert(searchRoots, f) end
	end
	table.insert(searchRoots, Workspace)
	for _, root in ipairs(searchRoots) do
		local ok, desc = pcall(function() return root:GetDescendants() end)
		if ok then
			for _, obj in ipairs(desc) do
				if obj:IsA("Model") or obj:IsA("BasePart") then
					local low = string.lower(obj.Name)
					if string.find(low,"quest",1,true) or string.find(low,"npc",1,true) then
						local part = (obj:IsA("BasePart") and obj)
							or obj.PrimaryPart
							or obj:FindFirstChild("HumanoidRootPart")
							or obj:FindFirstChildWhichIsA("BasePart")
						if part then return part.CFrame end
					end
				end
			end
		end
	end
	return nil
end

local function GetNPCCFrame(farmData)
	local key    = farmData.QuestName .. farmData.QuestNum
	local cached = NPCCFrameCache[key]
	local now    = tick()
	if cached and (now - cached.time) < NPC_CACHE_TTL then return cached.cframe end
	local dyn   = ScanForNPC()
	local final = dyn or farmData.NPCCFrame
	if final then
		NPCCFrameCache[key] = {cframe=final, time=now}
		return final
	end
	return nil
end

local function FindNearestMob(mobName, mobFolder)
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local folder = Workspace:FindFirstChild(mobFolder or "Enemies")
	if not folder then return nil end
	local best, bestDist = nil, math.huge
	local lower = string.lower(mobName)
	for _, mob in ipairs(folder:GetChildren()) do
		if string.find(string.lower(mob.Name), lower, 1, true) then
			local hum = mob:FindFirstChild("Humanoid")
			local mr  = mob:FindFirstChild("HumanoidRootPart")
			if hum and mr and hum.Health > 0 then
				local d = (mr.Position - root.Position).Magnitude
				if d < bestDist then bestDist=d; best=mob end
			end
		end
	end
	return best
end

-- Fly tween used by ontoy farm
local function FlyTo(targetCFrame, onDone)
	if not targetCFrame then if onDone then onDone() end; return end
	local destPos = targetCFrame.Position
	if destPos == Vector3.zero then if onDone then onDone() end; return end
	if currentFarmTween then currentFarmTween:Cancel(); currentFarmTween=nil end
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then if onDone then onDone() end; return end
	local safeY    = math.max(destPos.Y, MIN_FLY_Y)
	local safeDest = CFrame.new(Vector3.new(destPos.X, safeY, destPos.Z))
	if root.Position.Y < MIN_FLY_Y then
		root.CFrame = CFrame.new(root.Position.X, MIN_FLY_Y, root.Position.Z)
		task.wait(0.05)
		char = LocalPlayer.Character
		root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then if onDone then onDone() end; return end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = true end
	local dist  = (safeDest.Position - root.Position).Magnitude
	local dur   = math.clamp(dist / CONFIG.FarmFlySpeed, 0.3, 12)
	local tween = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame=safeDest})
	currentFarmTween = tween
	local fired = false
	tween.Completed:Connect(function(status)
		if fired then return end; fired=true; currentFarmTween=nil
		if status ~= Enum.TweenStatus.Completed then return end
		if onDone then onDone() end
	end)
	tween:Play()
end

-- ============================================================
-- ONTOY EXECUTE ATTACK
-- ============================================================
local function ExecuteAttack(mob)
	local char = LocalPlayer.Character
	if not char or not mob then return end
	if not char:FindFirstChildOfClass("Tool") then
		local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
		if tool then
			local hum = char:FindFirstChild("Humanoid")
			if hum then hum:EquipTool(tool) end
			task.wait(0.15)
		end
	end
	local tool = char:FindFirstChildOfClass("Tool")
	if RegisterAttack then
		pcall(function() RegisterAttack:FireServer(mob:FindFirstChild("HumanoidRootPart")) end)
	end
	if tool and tool:FindFirstChild("Handle") then
		local head = mob:FindFirstChild("Head")
		local mr   = mob:FindFirstChild("HumanoidRootPart")
		if head then pcall(function() firetouchinterest(tool.Handle,head,0); firetouchinterest(tool.Handle,head,1) end) end
		if mr   then pcall(function() firetouchinterest(tool.Handle,mr,0);   firetouchinterest(tool.Handle,mr,1) end) end
	end
end

-- ============================================================
-- ONTOY AUTO FARM LOOP (Level farm — hover + attack)
-- ============================================================
local farmStatus  = "Idle"
local farmRunning = false
local FARM_STATE  = {IDLE="idle",WAIT_CHAR="wait_char",GO_QUEST="go_quest",TAKE_QUEST="take_quest",GO_MOB="go_mob",ATTACK="attack",WAIT_SPAWN="wait_spawn"}
local farmState   = FARM_STATE.IDLE

local function FarmLoop()
	farmState  = FARM_STATE.GO_QUEST
	farmStatus = "Starting..."
	while farmRunning do
		task.wait(0.1)
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not char or not root or not hum or hum.Health <= 0 then
			StopHoverAnchor()
			if currentFarmTween then currentFarmTween:Cancel(); currentFarmTween=nil end
			farmState  = FARM_STATE.WAIT_CHAR
			farmStatus = "Menunggu respawn..."
			task.wait(2); continue
		end
		if farmState == FARM_STATE.WAIT_CHAR then
			farmState = FARM_STATE.GO_QUEST; farmStatus = "Character loaded"; continue
		end
		local farmData, level = GetFarmData()
		if not farmData then farmStatus = "Level "..level.." tidak ada di database"; continue end

		if farmState == FARM_STATE.GO_QUEST then
			StopHoverAnchor()
			if HasActiveQuest() then farmState=FARM_STATE.GO_MOB; farmStatus="Quest aktif — hunting"; continue end
			local npcCFrame = GetNPCCFrame(farmData)
			if not npcCFrame then farmStatus="NPC belum ketemu..."; continue end
			local npcPos   = npcCFrame.Position
			local xzDist   = Vector2.new(npcPos.X-root.Position.X, npcPos.Z-root.Position.Z).Magnitude
			local hoverPos = Vector3.new(npcPos.X, math.max(npcPos.Y+10,MIN_FLY_Y), npcPos.Z)
			if xzDist > QUEST_RADIUS then
				farmStatus = "Terbang ke NPC quest..."
				local done = false
				FlyTo(CFrame.new(hoverPos), function() done=true end)
				local timeout = tick()+15
				while not done and farmRunning do task.wait(0.1); if tick()>timeout then break end end
				if not farmRunning then break end
			end
			StartHoverAnchor(hoverPos); farmState=FARM_STATE.TAKE_QUEST

		elseif farmState == FARM_STATE.TAKE_QUEST then
			if HasActiveQuest() then StopHoverAnchor(); farmState=FARM_STATE.GO_MOB; farmStatus="Quest diterima!"; continue end
			farmStatus = "Ambil quest: "..farmData.QuestName.." #"..farmData.QuestNum
			pcall(function() CommF:InvokeServer("StartQuest", farmData.QuestName, farmData.QuestNum) end)
			task.wait(2.0); StopHoverAnchor()
			farmState = FARM_STATE.GO_MOB
			farmStatus = HasActiveQuest() and "Quest diterima!" or "Quest timeout — force attack"

		elseif farmState == FARM_STATE.GO_MOB then
			StopHoverAnchor()
			if not HasActiveQuest() then farmState=FARM_STATE.GO_QUEST; farmStatus="Quest selesai — ambil baru"; continue end
			local mob = FindNearestMob(farmData.MobName, farmData.MobFolder)
			if not mob then farmState=FARM_STATE.WAIT_SPAWN; farmStatus="Nunggu mob spawn..."; continue end
			local mr = mob:FindFirstChild("HumanoidRootPart")
			if not mr or mr.Position==Vector3.zero then continue end
			local mobPos  = mr.Position
			local hoverY  = math.max(mobPos.Y+CONFIG.FarmHoverHeight, MIN_FLY_Y)
			local hoverCF = CFrame.new(Vector3.new(mobPos.X,hoverY,mobPos.Z))
			if (hoverCF.Position-root.Position).Magnitude > 8 then
				farmStatus = "Terbang ke "..farmData.MobName.."..."
				local done = false
				FlyTo(hoverCF, function() done=true end)
				local timeout = tick()+15
				while not done and farmRunning do task.wait(0.1); if tick()>timeout then break end end
				if not farmRunning then break end
			end
			farmState = FARM_STATE.ATTACK

		elseif farmState == FARM_STATE.ATTACK then
			if not HasActiveQuest() then farmState=FARM_STATE.GO_QUEST; farmStatus="Quest selesai — ambil baru"; continue end
			local mob = FindNearestMob(farmData.MobName, farmData.MobFolder)
			if not mob or not mob:FindFirstChild("HumanoidRootPart") then farmState=FARM_STATE.WAIT_SPAWN; farmStatus="Mob mati — nunggu respawn"; continue end
			local mr     = mob.HumanoidRootPart
			local mobPos = mr.Position
			if mobPos==Vector3.zero then continue end
			local hoverY = math.max(mobPos.Y+CONFIG.FarmHoverHeight, MIN_FLY_Y)
			local freshHum = char:FindFirstChildOfClass("Humanoid")
			if freshHum then freshHum.PlatformStand = true end
			root.CFrame = CFrame.new(Vector3.new(mobPos.X,hoverY,mobPos.Z))
			root.AssemblyLinearVelocity = Vector3.zero
			farmStatus = "Nyerang "..farmData.MobName
			ExecuteAttack(mob)

		elseif farmState == FARM_STATE.WAIT_SPAWN then
			local mob = FindNearestMob(farmData.MobName, farmData.MobFolder)
			if mob then farmState=FARM_STATE.GO_MOB; farmStatus="Mob ketemu!"
			else farmStatus="Nunggu mob spawn..."; task.wait(1.5) end
		end
	end
	farmState=FARM_STATE.IDLE; farmStatus="Idle"
end

local function StartFarm()
	if farmRunning then return end
	if currentFarmTween then currentFarmTween:Cancel(); currentFarmTween=nil end
	StopHoverAnchor(); farmRunning=true; task.spawn(FarmLoop)
end

local function StopFarm()
	farmRunning=false
	if currentFarmTween then currentFarmTween:Cancel(); currentFarmTween=nil end
	StopHoverAnchor()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then root.AssemblyLinearVelocity=Vector3.zero end
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand=false end
	if not CONFIG.Mode10 then
		if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
	end
	farmState=FARM_STATE.IDLE; farmStatus="Idle"
end

local function StopTween(state)
	if not state then
		_G_Farm.StopTween = true
		local char = LocalPlayer.Character
		local part = char and char:FindFirstChild("PartTele")
		if part then part:Destroy() end
		isTeleporting = false
		_G_Farm.StopTween = false
	end
end

-- ============================================================
-- RELZ FARM LOOPS (Boss, Mon, Nearest, Mastery, Material, Bone)
-- ============================================================

-- AUTO FARM NEAREST
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		if _G_Farm.AutoFarmNearest then
			pcall(function()
				for _, v in pairs(Enemies:GetChildren()) do
					local hum = v:FindFirstChild("Humanoid")
					local mr  = v:FindFirstChild("HumanoidRootPart")
					if hum and mr and hum.Health > 0 then
						local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
						if root and (mr.Position - root.Position).Magnitude <= 5000 then
							AttackTarget(v, true, function() return _G_Farm.AutoFarmNearest end)
						end
					end
				end
			end)
		end
	end
end)

-- AUTO FARM MON (specific mob)
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		if _G_Farm.AutoFarmMon and _G_Farm.SelectedMon then
			pcall(function()
				for _, v in pairs(Enemies:GetChildren()) do
					if v.Name == _G_Farm.SelectedMon then
						local hum = v:FindFirstChild("Humanoid")
						local mr  = v:FindFirstChild("HumanoidRootPart")
						if hum and mr and hum.Health > 0 then
							AttackTarget(v, true, function() return _G_Farm.AutoFarmMon end)
						end
					end
				end
			end)
		end
	end
end)

-- AUTO FARM BOSS (selected)
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		if _G_Farm.AutoFarmBoss and _G_Farm.SelectedBoss then
			pcall(function()
				local boss = Enemies:FindFirstChild(_G_Farm.SelectedBoss)
				if boss then
					AttackTarget(boss, true, function() return _G_Farm.AutoFarmBoss end)
				else
					local rsBoss = ReplicatedStorage:FindFirstChild(_G_Farm.SelectedBoss)
					if rsBoss and rsBoss:FindFirstChild("HumanoidRootPart") then
						TweenPlayer(rsBoss.HumanoidRootPart.CFrame * CFrame.new(5,10,2))
					end
				end
			end)
		end
	end
end)

-- AUTO FARM ALL BOSS
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		if _G_Farm.AutoFarmAllBoss then
			pcall(function()
				for _, name in pairs(tableBoss) do
					local v = Enemies:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
					if v and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
						AttackTarget(v, true, function() return _G_Farm.AutoFarmAllBoss end)
						break
					end
				end
			end)
		end
	end
end)

-- AUTO FARM SWORD MASTERY
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		if _G_Farm.AutoFarmSwordMastery then
			pcall(function()
				GetSelectedWeapon()
				if _G_Farm.MasteryMethod == "Level" then
					if not HasActiveQuest() then
						pcall(function() CommF:InvokeServer("StartQuest", ({GetFarmData()})[1] and ({GetFarmData()})[1].QuestName, ({GetFarmData()})[1] and ({GetFarmData()})[1].QuestNum) end)
					else
						local fd = GetFarmData()
						if fd then
							for _, v in pairs(Enemies:GetChildren()) do
								if v.Name == fd.MobName then
									local h=v:FindFirstChild("Humanoid"); local r=v:FindFirstChild("HumanoidRootPart")
									if h and r and h.Health > 0 then
										EquipWeapon(_G_Farm.SelectedMasterySword or _G_Farm.SelectedWeapon)
										AttackTarget(v, true, function() return _G_Farm.AutoFarmSwordMastery end)
									end
								end
							end
						end
					end
				elseif _G_Farm.MasteryMethod == "Nearest" then
					for _, v in pairs(Enemies:GetChildren()) do
						local h=v:FindFirstChild("Humanoid"); local r=v:FindFirstChild("HumanoidRootPart")
						local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
						if h and r and h.Health>0 and root and (r.Position-root.Position).Magnitude<=2000 then
							EquipWeapon(_G_Farm.SelectedMasterySword or _G_Farm.SelectedWeapon)
							AttackTarget(v, true, function() return _G_Farm.AutoFarmSwordMastery end)
						end
					end
				end
			end)
		end
	end
end)

-- AUTO FARM FRUIT MASTERY
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		if _G_Farm.AutoFarmFruitMastery then
			pcall(function()
				local fd = GetFarmData()
				if not fd then return end
				if not HasActiveQuest() then
					pcall(function() CommF:InvokeServer("StartQuest", fd.QuestName, fd.QuestNum) end)
					return
				end
				for _, v in pairs(Enemies:GetChildren()) do
					local h=v:FindFirstChild("Humanoid"); local r=v:FindFirstChild("HumanoidRootPart")
					if h and r and h.Health > 0 and v.Name == fd.MobName then
						AimBotSkillPosition = r.Position
						Skillaimbot = true
						TweenPlayer(r.CFrame * _G_Farm.Pos)
						AutoHaki()
						if h.Health <= h.MaxHealth * _G_Farm.MasteryHealth / 100 then
							EquipWeapon(LocalPlayer.Data.DevilFruit.Value)
							UseSkill = true
						else
							UseSkill = false; Skillaimbot = false
							EquipWeapon(_G_Farm.SelectedWeapon); NormalAttack()
						end
						break
					end
				end
			end)
		end
	end
end)

-- AUTO FARM GUN MASTERY
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		if _G_Farm.AutoFarmGunMastery then
			pcall(function()
				local fd = GetFarmData()
				if not fd then return end
				if not HasActiveQuest() then
					pcall(function() CommF:InvokeServer("StartQuest", fd.QuestName, fd.QuestNum) end)
					return
				end
				for _, v in pairs(Enemies:GetChildren()) do
					local h=v:FindFirstChild("Humanoid"); local r=v:FindFirstChild("HumanoidRootPart")
					if h and r and h.Health > 0 and v.Name == fd.MobName then
						AimBotSkillPosition = r.Position
						Skillaimbot = true
						TweenPlayer(r.CFrame * _G_Farm.Pos)
						AutoHaki()
						if h.Health <= h.MaxHealth * _G_Farm.MasteryHealth / 100 then
							UseGunSkill = true; Skillaimbot = true
						else
							UseGunSkill = false; Skillaimbot = false
							EquipWeapon(_G_Farm.SelectedWeapon); NormalAttack()
						end
						break
					end
				end
			end)
		end
	end
end)

-- AUTO FARM MATERIAL
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		if _G_Farm.AutoFarmMaterial and _G_Farm.SelectedMaterial then
			pcall(function()
				getConfigMaterial(_G_Farm.SelectedMaterial)
				if not MaterialMon or not MaterialPos then return end
				local char = LocalPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local found = false
				for _, mon in pairs(MaterialMon) do
					for _, v in pairs(Enemies:GetChildren()) do
						if v.Name == mon then
							local h=v:FindFirstChild("Humanoid"); local r=v:FindFirstChild("HumanoidRootPart")
							if h and r and h.Health > 0 then
								found = true
								AttackTarget(v, true, function() return _G_Farm.AutoFarmMaterial end)
							end
						end
					end
				end
				if not found and root then
					TweenPlayer(MaterialPos)
				end
			end)
		end
	end
end)

-- AUTO FARM BONE (no quest)
local BonePos = CFrame.new(-9506.23,172.13,6117.08)
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		if _G_Farm.AutoFarmBone and World3 then
			pcall(function()
				local boneNames = {"Reborn Skeleton","Living Zombie","Demonic Soul","Posessed Mummy"}
				local char = LocalPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local found = false
				for _, name in pairs(boneNames) do
					for _, v in pairs(Enemies:GetChildren()) do
						if v.Name == name then
							local h=v:FindFirstChild("Humanoid"); local r=v:FindFirstChild("HumanoidRootPart")
							if h and r and h.Health > 0 then
								found = true
								AttackTarget(v, true, function() return _G_Farm.AutoFarmBone end)
							end
						end
					end
				end
				if not found and root then TweenPlayer(BonePos) end
			end)
		end
	end
end)

-- AUTO FARM SEABEAST
task.spawn(function()
	while task.wait(_G_Farm.GlobalDelay) do
		if _G_Farm.AutoFarmSeabeast then
			pcall(function()
				local sb = Workspace:FindFirstChild("SeaBeasts")
				if not sb then return end
				local char = LocalPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if not root then return end
				for _, v in pairs(sb:GetChildren()) do
					local h=v:FindFirstChild("Humanoid"); local r=v:FindFirstChild("HumanoidRootPart")
					if h and r and h.Health > 0 then
						AimBotSkillPosition = r.Position; Skillaimbot = true
						AutoHaki()
						TweenPlayer(r.CFrame * CFrame.new(0,400,0))
					end
				end
			end)
		end
	end
end)

-- BRING MOB
RunService.RenderStepped:Connect(function()
	if _G_Farm.BringMob and _G_Farm.MonFarm ~= "" then
		pcall(function()
			for _, v in pairs(Enemies:GetChildren()) do
				if v.Name == _G_Farm.MonFarm then
					local r = v:FindFirstChild("HumanoidRootPart")
					local h = v:FindFirstChild("Humanoid")
					local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if r and h and root and (r.Position-root.Position).Magnitude <= _G_Farm.BringDistance then
						v.PrimaryPart.CFrame = _G_Farm.PosMon
						r.CFrame = _G_Farm.PosMon
						h.JumpPower = 0; h.WalkSpeed = 0
						r.Size = Vector3.new(1,1,1); r.Transparency = 1
						r.CanCollide = false
						if h:FindFirstChild("Animator") then h.Animator:Destroy() end
						h:ChangeState(11); h:ChangeState(14)
						pcall(function() sethiddenproperty(LocalPlayer,"SimulationRadius",math.huge) end)
					end
				end
			end
		end)
	end
end)

-- ATTACK AURA
task.spawn(function()
	while task.wait(0.1) do
		if _G_Farm.AttackAura and not _G_Farm.AutoFarmFruitMastery and not _G_Farm.AutoFarmGunMastery then
			pcall(Attack)
		end
	end
end)

-- SimulationRadius
task.spawn(function()
	RunService.RenderStepped:Connect(function()
		pcall(function()
			if setscriptable then setscriptable(LocalPlayer,"SimulationRadius",true) end
			if sethiddenproperty then sethiddenproperty(LocalPlayer,"SimulationRadius",math.huge) end
		end)
	end)
end)

-- Spin position
task.spawn(function()
	local angle = 0
	while task.wait() do
		if _G_Farm.SpinPosition then
			local r=math.rad(angle)
			_G_Farm.Pos = CFrame.new(math.cos(r)*20, _G_Farm.FarmDistance, math.sin(r)*20)
			angle = (angle+30)%360
		else
			_G_Farm.Pos = CFrame.new(0, _G_Farm.FarmDistance, 0)
		end
	end
end)

-- Keep weapon synced
task.spawn(function()
	while task.wait(0.2) do
		pcall(function()
			for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
				if v.ToolTip == _G_Farm.SelectWeapon then
					_G_Farm.SelectedWeapon = v.Name
				end
			end
		end)
	end
end)

-- ============================================================
-- ONTOY: Silent aim, fast attack, hitbox, speed, dash, ESP
-- ============================================================
local function GetSilentTarget()
	local vp=Camera.ViewportSize; local cx,cy=vp.X/2,vp.Y/2
	local fov=CONFIG.SilentAimFOV; local best,bestDist=nil,math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player==LocalPlayer then continue end
		local char=player.Character; if not char then continue end
		local root=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChild("Humanoid")
		if not (root and hum and hum.Health>0) then continue end
		local screen,onScreen=Camera:WorldToScreenPoint(root.Position)
		if not onScreen then continue end
		local dist=math.sqrt((screen.X-cx)^2+(screen.Y-cy)^2)
		if dist<fov and dist<bestDist then bestDist=dist; best=root end
	end
	return best
end

local function ApplySilentAim()
	if not CONFIG.Mode7 then silentTarget=nil; return end
	silentTarget=GetSilentTarget()
	if not silentTarget or not silentTarget.Parent then silentTarget=nil; return end
	local dir=(silentTarget.Position-Camera.CFrame.Position).Unit
	Camera.CFrame=CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position+dir)
end

local function GetAttackInterval() return 1/math.max(CONFIG.AttackHPS,1) end

local function GetFastTarget()
	if silentTarget and silentTarget.Parent then return silentTarget end
	local char=LocalPlayer.Character
	local lroot=char and char:FindFirstChild("HumanoidRootPart")
	if not lroot then return nil end
	local best,bestDist=nil,math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player==LocalPlayer then continue end
		local pchar=player.Character; if not pchar then continue end
		local root=pchar:FindFirstChild("HumanoidRootPart")
		local hum=pchar:FindFirstChild("Humanoid")
		if not (root and hum and hum.Health>0) then continue end
		local _,onScreen=Camera:WorldToScreenPoint(root.Position)
		if not onScreen then continue end
		local d=(root.Position-lroot.Position).Magnitude
		if d<bestDist then bestDist=d; best=root end
	end
	return best
end

local function StartFastAttack()
	if fastAttackConn then fastAttackConn:Disconnect(); fastAttackConn=nil end
	fastAttackConn=RunService.Heartbeat:Connect(function()
		if not CONFIG.Mode8 or not RegisterAttack then return end
		local now=tick()
		if now-lastAttackTick<GetAttackInterval() then return end
		lastAttackTick=now
		local target=GetFastTarget()
		if not target then return end
		pcall(function() RegisterAttack:FireServer(target) end)
	end)
end

local function StopFastAttack()
	if fastAttackConn then fastAttackConn:Disconnect(); fastAttackConn=nil end
end

local function PctToSize(pct) return MIN_HITBOX+(MAX_HITBOX-MIN_HITBOX)*((pct-1)/99) end

local function ExpandHitbox()
	local char=LocalPlayer.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if not OriginalLocalSize then OriginalLocalSize=root.Size end
	local sz=PctToSize(CONFIG.HitboxPercent)
	root.Size=Vector3.new(sz,sz,sz)
end

local function RestoreHitbox()
	if not OriginalLocalSize then return end
	local char=LocalPlayer.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if root then root.Size=OriginalLocalSize end
	OriginalLocalSize=nil
end

local function GetTargetSpeed() return BASE_SPEED+(MAX_SPEED-BASE_SPEED)*(CONFIG.SpeedPercent/100) end

local function Mode2Func(pos)
	local p=Instance.new("Part")
	p.Name="Ontoy_Part"; p.Size=Vector3.new(CONFIG.Radius*2,10,CONFIG.Radius*2)
	p.Position=pos; p.Anchored=true; p.CanCollide=false; p.Transparency=1
	p.Parent=Workspace
	game:GetService("Debris"):AddItem(p,0.1)
end

local function SimulateDash()
	pcall(function() VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Q,false,game) end)
	task.delay(0.03, function()
		pcall(function() VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Q,false,game) end)
	end)
end

local function StartDashLoop()
	if dashConn then dashConn:Disconnect(); dashConn=nil end
	dashConn=RunService.Heartbeat:Connect(function()
		if not CONFIG.Mode6 or not dashHolding then return end
		local now=tick()
		if now-lastDashTime>=DASH_INTERVAL then lastDashTime=now; SimulateDash() end
	end)
end

local function StopDashLoop()
	if dashConn then dashConn:Disconnect(); dashConn=nil end
	dashHolding=false
end

UserInputService.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.KeyCode==Enum.KeyCode.Q and CONFIG.Mode6 then dashHolding=true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode==Enum.KeyCode.Q then dashHolding=false end
end)

-- ============================================================
-- ESP
-- ============================================================
local function CreateESP(player)
	local esp={Box=Drawing.new("Square"),Line=Drawing.new("Line"),NameTag=Drawing.new("Text"),HealthBar=Drawing.new("Square")}
	esp.Box.Thickness=1; esp.Box.Color=Color3.fromRGB(255,50,50); esp.Box.Filled=false; esp.Box.Visible=false
	esp.Line.Thickness=1; esp.Line.Color=Color3.fromRGB(0,255,255); esp.Line.Visible=false
	esp.NameTag.Size=13; esp.NameTag.Color=Color3.fromRGB(255,255,255); esp.NameTag.Center=true
	esp.NameTag.Outline=true; esp.NameTag.OutlineColor=Color3.fromRGB(0,0,0); esp.NameTag.Visible=false
	esp.HealthBar.Thickness=1; esp.HealthBar.Filled=true; esp.HealthBar.Visible=false
	return esp
end

local function CleanupESP(p)
	local esp=ESP_Objects[p]
	if esp then esp.Box:Remove(); esp.Line:Remove(); esp.NameTag:Remove(); esp.HealthBar:Remove(); ESP_Objects[p]=nil end
end

local function HideESP(esp) esp.Box.Visible=false; esp.NameTag.Visible=false; esp.Line.Visible=false; esp.HealthBar.Visible=false end
local function HideAllESP() for _,esp in pairs(ESP_Objects) do HideESP(esp) end end

for _, p in ipairs(Players:GetPlayers()) do
	if p ~= LocalPlayer then ESP_Objects[p]=CreateESP(p) end
end
Players.PlayerAdded:Connect(function(p) ESP_Objects[p]=CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) CleanupESP(p) end)

local fovCircle=Drawing.new("Circle")
fovCircle.Radius=CONFIG.SilentAimFOV; fovCircle.Color=Color3.fromRGB(255,60,80)
fovCircle.Filled=false; fovCircle.Thickness=1; fovCircle.Visible=false

local function RenderESP()
	if not CONFIG.Mode3 then HideAllESP(); return end
	local char=LocalPlayer.Character
	local lroot=char and char:FindFirstChild("HumanoidRootPart")
	if not lroot then HideAllESP(); return end
	for player,esp in pairs(ESP_Objects) do
		local character=player.Character
		if not character then HideESP(esp); continue end
		local root=character:FindFirstChild("HumanoidRootPart")
		local hum=character:FindFirstChild("Humanoid")
		local head=character:FindFirstChild("Head")
		if not (root and hum and head and hum.Health>0) then HideESP(esp); continue end
		local rs,onScreen=Camera:WorldToScreenPoint(root.Position)
		local hs=Camera:WorldToScreenPoint(head.Position)
		if not onScreen then HideESP(esp); continue end
		local height=math.max(math.abs(rs.Y-hs.Y)*2,10)
		local width=height*0.5
		local boxPos=Vector2.new(rs.X-width/2,rs.Y-height/2)
		esp.Box.Size=Vector2.new(width,height); esp.Box.Position=boxPos; esp.Box.Visible=true
		local hpR=hum.Health/hum.MaxHealth
		local barH=height*hpR
		esp.HealthBar.Size=Vector2.new(4,barH)
		esp.HealthBar.Position=Vector2.new(boxPos.X-7,boxPos.Y+(height-barH))
		esp.HealthBar.Color=Color3.fromRGB(math.floor(255*(1-hpR)),math.floor(255*hpR),0)
		esp.HealthBar.Visible=true
		local dist=math.floor((root.Position-lroot.Position).Magnitude)
		esp.NameTag.Text=player.Name.." ["..math.floor(hum.Health).."hp | "..dist.."m]"
		esp.NameTag.Position=Vector2.new(rs.X,boxPos.Y-16); esp.NameTag.Visible=true
		if CONFIG.Mode4 then
			local sc=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
			esp.Line.From=sc; esp.Line.To=Vector2.new(rs.X,rs.Y); esp.Line.Visible=true
		else
			esp.Line.Visible=false
		end
	end
end

-- ============================================================
-- GUI — ONTOY HUB STYLE (unchanged look, extra tabs added)
-- ============================================================
local screenGui=Instance.new("ScreenGui")
screenGui.Name="Ontoy_Hub"; screenGui.ResetOnSpawn=false
screenGui.Parent=LocalPlayer:WaitForChild("PlayerGui")

local REDZ={
	BG=Color3.fromRGB(14,12,16), BG2=Color3.fromRGB(20,16,22),
	Accent=Color3.fromRGB(200,30,50), AccentDim=Color3.fromRGB(120,20,35),
	AccentGlow=Color3.fromRGB(255,60,80), TextMain=Color3.fromRGB(240,220,225),
	TextSub=Color3.fromRGB(130,100,110), Stroke=Color3.fromRGB(60,30,40),
	ToggleOff=Color3.fromRGB(40,32,36), SliderFill=Color3.fromRGB(200,30,50),
	SliderBG=Color3.fromRGB(35,28,32), Green=Color3.fromRGB(30,180,80),
	GreenDim=Color3.fromRGB(20,100,50),
}

local mainWindow=Instance.new("Frame")
mainWindow.Size=UDim2.new(0,620,0,420); mainWindow.Position=UDim2.new(0.5,-310,0.5,-210)
mainWindow.BackgroundColor3=REDZ.BG; mainWindow.BorderSizePixel=0
mainWindow.Active=true; mainWindow.Draggable=false; mainWindow.Parent=screenGui
Instance.new("UICorner",mainWindow).CornerRadius=UDim.new(0,10)
local mainStroke=Instance.new("UIStroke",mainWindow); mainStroke.Color=REDZ.Stroke; mainStroke.Thickness=1.5

local titleBar=Instance.new("Frame",mainWindow)
titleBar.Size=UDim2.new(1,0,0,42); titleBar.BackgroundColor3=REDZ.BG2; titleBar.BorderSizePixel=0
Instance.new("UICorner",titleBar).CornerRadius=UDim.new(0,10)

local draggingWindow=false; local dragStartMouse=Vector2.zero; local dragStartPos=UDim2.new()
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then
		draggingWindow=true; dragStartMouse=Vector2.new(input.Position.X,input.Position.Y); dragStartPos=mainWindow.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if draggingWindow and input.UserInputType==Enum.UserInputType.MouseMovement then
		local d=Vector2.new(input.Position.X,input.Position.Y)-dragStartMouse
		mainWindow.Position=UDim2.new(dragStartPos.X.Scale,dragStartPos.X.Offset+d.X,dragStartPos.Y.Scale,dragStartPos.Y.Offset+d.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 then draggingWindow=false end
end)

local titleAccentLine=Instance.new("Frame",titleBar)
titleAccentLine.Size=UDim2.new(1,0,0,2); titleAccentLine.Position=UDim2.new(0,0,1,-2)
titleAccentLine.BackgroundColor3=REDZ.Accent; titleAccentLine.BorderSizePixel=0

local logoDot=Instance.new("Frame",titleBar)
logoDot.Size=UDim2.new(0,8,0,8); logoDot.Position=UDim2.new(0,14,0.5,-4)
logoDot.BackgroundColor3=REDZ.AccentGlow; logoDot.BorderSizePixel=0
Instance.new("UICorner",logoDot).CornerRadius=UDim.new(0,4)

local titleText=Instance.new("TextLabel",titleBar)
titleText.Size=UDim2.new(1,-160,1,0); titleText.Position=UDim2.new(0,30,0,0)
titleText.BackgroundTransparency=1; titleText.Text="ONTOY HUB  <font color='#C81E32'>·</font>  Blox Fruits"
titleText.RichText=true; titleText.TextColor3=REDZ.TextMain
titleText.Font=Enum.Font.GothamBold; titleText.TextSize=13; titleText.TextXAlignment=Enum.TextXAlignment.Left

local byLabel=Instance.new("TextLabel",titleBar)
byLabel.Size=UDim2.new(0,80,1,0); byLabel.Position=UDim2.new(0,195,0,0)
byLabel.BackgroundTransparency=1; byLabel.Text="by ontoy"
byLabel.TextColor3=REDZ.TextSub; byLabel.Font=Enum.Font.Gotham
byLabel.TextSize=11; byLabel.TextXAlignment=Enum.TextXAlignment.Left

local function MakeWindowBtn(parent,xOff,bg,txt)
	local btn=Instance.new("TextButton",parent)
	btn.Size=UDim2.new(0,26,0,26); btn.Position=UDim2.new(1,xOff,0.5,-13)
	btn.BackgroundColor3=bg; btn.Text=txt; btn.TextColor3=Color3.fromRGB(255,255,255)
	btn.Font=Enum.Font.GothamBold; btn.TextSize=11; btn.BorderSizePixel=0
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
	return btn
end

local closeBtn   =MakeWindowBtn(titleBar,-34,REDZ.Accent,"✕")
local minimizeBtn=MakeWindowBtn(titleBar,-66,REDZ.ToggleOff,"—")

-- SIDEBAR
local sidebar=Instance.new("Frame",mainWindow)
sidebar.Size=UDim2.new(0,148,1,-42); sidebar.Position=UDim2.new(0,0,0,42)
sidebar.BackgroundColor3=REDZ.BG2; sidebar.BorderSizePixel=0
Instance.new("UICorner",sidebar).CornerRadius=UDim.new(0,10)
local sideStroke=Instance.new("UIStroke",sidebar); sideStroke.Color=REDZ.Stroke; sideStroke.Thickness=1
local sideLayout=Instance.new("UIListLayout",sidebar)
sideLayout.Padding=UDim.new(0,3); sideLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
Instance.new("UIPadding",sidebar).PaddingTop=UDim.new(0,12)

local contentArea=Instance.new("Frame",mainWindow)
contentArea.Size=UDim2.new(1,-156,1,-50); contentArea.Position=UDim2.new(0,152,0,46)
contentArea.BackgroundTransparency=1; contentArea.BorderSizePixel=0

local contentScroll=Instance.new("ScrollingFrame",contentArea)
contentScroll.Size=UDim2.new(1,0,1,0); contentScroll.BackgroundTransparency=1
contentScroll.BorderSizePixel=0; contentScroll.ScrollBarThickness=3
contentScroll.ScrollBarImageColor3=REDZ.AccentDim
contentScroll.CanvasSize=UDim2.new(0,0,0,0); contentScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y

local contentLayout=Instance.new("UIListLayout",contentScroll)
contentLayout.Padding=UDim.new(0,6); contentLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
Instance.new("UIPadding",contentScroll).PaddingTop=UDim.new(0,8)

local pages={}; local sidebarButtons={}

local function MakePage()
	local pg=Instance.new("Frame",contentScroll)
	pg.Size=UDim2.new(1,0,0,0); pg.AutomaticSize=Enum.AutomaticSize.Y
	pg.BackgroundTransparency=1; pg.BorderSizePixel=0; pg.Visible=false
	local lay=Instance.new("UIListLayout",pg)
	lay.Padding=UDim.new(0,6); lay.HorizontalAlignment=Enum.HorizontalAlignment.Center
	Instance.new("UIPadding",pg).PaddingBottom=UDim.new(0,8)
	return pg
end

local function MakeSidebarBtn(icon,label,id)
	local btn=Instance.new("TextButton",sidebar)
	btn.Size=UDim2.new(1,-14,0,38); btn.BackgroundColor3=REDZ.ToggleOff
	btn.BackgroundTransparency=1; btn.Text=""; btn.BorderSizePixel=0
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
	local accentBar=Instance.new("Frame",btn)
	accentBar.Size=UDim2.new(0,3,0.6,0); accentBar.Position=UDim2.new(0,0,0.2,0)
	accentBar.BackgroundColor3=REDZ.Accent; accentBar.BorderSizePixel=0; accentBar.Visible=false
	Instance.new("UICorner",accentBar).CornerRadius=UDim.new(0,2)
	local iconL=Instance.new("TextLabel",btn)
	iconL.Size=UDim2.new(0,22,1,0); iconL.Position=UDim2.new(0,10,0,0)
	iconL.BackgroundTransparency=1; iconL.Text=icon
	iconL.TextColor3=REDZ.TextSub; iconL.Font=Enum.Font.GothamBold; iconL.TextSize=14
	local labelL=Instance.new("TextLabel",btn)
	labelL.Size=UDim2.new(1,-38,1,0); labelL.Position=UDim2.new(0,36,0,0)
	labelL.BackgroundTransparency=1; labelL.Text=label
	labelL.TextColor3=REDZ.TextSub; labelL.Font=Enum.Font.Gotham; labelL.TextSize=12
	labelL.TextXAlignment=Enum.TextXAlignment.Left
	sidebarButtons[id]={btn=btn,icon=iconL,label=labelL,bar=accentBar}
	return btn
end

local function SetActivePage(id)
	for pid,pg in pairs(pages) do pg.Visible=(pid==id) end
	for bid,sb in pairs(sidebarButtons) do
		local active=(bid==id)
		sb.btn.BackgroundTransparency=active and 0 or 1
		sb.btn.BackgroundColor3=active and Color3.fromRGB(30,18,22) or REDZ.ToggleOff
		sb.icon.TextColor3=active and REDZ.AccentGlow or REDZ.TextSub
		sb.label.TextColor3=active and REDZ.TextMain or REDZ.TextSub
		sb.bar.Visible=active
	end
end

local function MakeSectionLabel(parent,text)
	local lbl=Instance.new("TextLabel",parent)
	lbl.Size=UDim2.new(1,-8,0,18); lbl.BackgroundTransparency=1
	lbl.Text=text; lbl.TextColor3=REDZ.Accent
	lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left
	return lbl
end

local function MakeToggleRow(parent,label,sublabel,accentColor)
	accentColor=accentColor or REDZ.Accent
	local row=Instance.new("Frame",parent)
	row.Size=UDim2.new(1,-8,0,52); row.BackgroundColor3=REDZ.BG2; row.BorderSizePixel=0
	Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
	local stroke=Instance.new("UIStroke",row); stroke.Color=REDZ.Stroke; stroke.Thickness=1
	local title=Instance.new("TextLabel",row)
	title.Size=UDim2.new(1,-60,0,22); title.Position=UDim2.new(0,14,0,8)
	title.BackgroundTransparency=1; title.Text=label
	title.TextColor3=REDZ.TextMain; title.Font=Enum.Font.GothamBold; title.TextSize=12
	title.TextXAlignment=Enum.TextXAlignment.Left
	if sublabel then
		local sub=Instance.new("TextLabel",row)
		sub.Size=UDim2.new(1,-60,0,16); sub.Position=UDim2.new(0,14,0,28)
		sub.BackgroundTransparency=1; sub.Text=sublabel
		sub.TextColor3=REDZ.TextSub; sub.Font=Enum.Font.Gotham; sub.TextSize=10
		sub.TextXAlignment=Enum.TextXAlignment.Left
	end
	local toggleBG=Instance.new("Frame",row)
	toggleBG.Size=UDim2.new(0,36,0,20); toggleBG.Position=UDim2.new(1,-48,0.5,-10)
	toggleBG.BackgroundColor3=REDZ.ToggleOff; toggleBG.BorderSizePixel=0
	Instance.new("UICorner",toggleBG).CornerRadius=UDim.new(0,10)
	local toggleKnob=Instance.new("Frame",toggleBG)
	toggleKnob.Size=UDim2.new(0,14,0,14); toggleKnob.Position=UDim2.new(0,3,0.5,-7)
	toggleKnob.BackgroundColor3=REDZ.TextSub; toggleKnob.BorderSizePixel=0
	Instance.new("UICorner",toggleKnob).CornerRadius=UDim.new(0,7)
	local togBtn=Instance.new("TextButton",toggleBG)
	togBtn.Size=UDim2.new(1,8,1,8); togBtn.Position=UDim2.new(0,-4,0,-4)
	togBtn.BackgroundTransparency=1; togBtn.Text=""; togBtn.BorderSizePixel=0
	local state=false
	local function SetState(s)
		state=s
		if s then
			toggleBG.BackgroundColor3=accentColor
			toggleKnob.BackgroundColor3=Color3.fromRGB(255,255,255)
			toggleKnob.Position=UDim2.new(1,-17,0.5,-7)
			row.BackgroundColor3=Color3.fromRGB(24,14,18); stroke.Color=REDZ.AccentDim
		else
			toggleBG.BackgroundColor3=REDZ.ToggleOff
			toggleKnob.BackgroundColor3=REDZ.TextSub
			toggleKnob.Position=UDim2.new(0,3,0.5,-7)
			row.BackgroundColor3=REDZ.BG2; stroke.Color=REDZ.Stroke
		end
	end
	togBtn.MouseButton1Click:Connect(function() SetState(not state) end)
	return row, function() return state end, SetState
end

local function MakeSliderRow(parent,label,displayMin,displayMax,initPct,unit,onChanged)
	local row=Instance.new("Frame",parent)
	row.Size=UDim2.new(1,-8,0,66); row.BackgroundColor3=REDZ.BG2; row.BorderSizePixel=0
	Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
	local stroke=Instance.new("UIStroke",row); stroke.Color=REDZ.Stroke; stroke.Thickness=1
	local title=Instance.new("TextLabel",row)
	title.Size=UDim2.new(1,-80,0,20); title.Position=UDim2.new(0,14,0,8)
	title.BackgroundTransparency=1; title.Text=label
	title.TextColor3=REDZ.TextMain; title.Font=Enum.Font.GothamBold; title.TextSize=12
	title.TextXAlignment=Enum.TextXAlignment.Left
	local valLabel=Instance.new("TextLabel",row)
	valLabel.Size=UDim2.new(0,70,0,20); valLabel.Position=UDim2.new(1,-78,0,8)
	valLabel.BackgroundTransparency=1; valLabel.Font=Enum.Font.GothamBold; valLabel.TextSize=12
	valLabel.TextColor3=REDZ.AccentGlow; valLabel.TextXAlignment=Enum.TextXAlignment.Right
	local sliderBG=Instance.new("Frame",row)
	sliderBG.Size=UDim2.new(1,-28,0,5); sliderBG.Position=UDim2.new(0,14,0,42)
	sliderBG.BackgroundColor3=REDZ.SliderBG; sliderBG.BorderSizePixel=0
	Instance.new("UICorner",sliderBG).CornerRadius=UDim.new(0,3)
	local sliderHitbox=Instance.new("TextButton",sliderBG)
	sliderHitbox.Size=UDim2.new(1,0,0,28); sliderHitbox.Position=UDim2.new(0,0,0.5,-14)
	sliderHitbox.BackgroundTransparency=1; sliderHitbox.Text=""
	sliderHitbox.BorderSizePixel=0; sliderHitbox.ZIndex=5
	local sliderFill=Instance.new("Frame",sliderBG)
	sliderFill.Size=UDim2.new(initPct,0,1,0); sliderFill.BackgroundColor3=REDZ.SliderFill; sliderFill.BorderSizePixel=0
	Instance.new("UICorner",sliderFill).CornerRadius=UDim.new(0,3)
	local knob=Instance.new("Frame",sliderBG)
	knob.Size=UDim2.new(0,14,0,14); knob.Position=UDim2.new(initPct,-7,0.5,-7)
	knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0
	Instance.new("UICorner",knob).CornerRadius=UDim.new(0,7)
	local knobRing=Instance.new("UIStroke",knob); knobRing.Color=REDZ.Accent; knobRing.Thickness=2
	local dragging=false
	local function Compute(px)
		local bg=sliderBG.AbsolutePosition.X; local bw=sliderBG.AbsoluteSize.X
		local pct=math.clamp((px-bg)/bw,0,1)
		return pct,math.floor(displayMin+(displayMax-displayMin)*pct)
	end
	local function Apply(pct,val)
		sliderFill.Size=UDim2.new(pct,0,1,0); knob.Position=UDim2.new(pct,-7,0.5,-7)
		valLabel.Text=val..(unit or "")
		if onChanged then onChanged(val,pct) end
	end
	Apply(initPct,math.floor(displayMin+(displayMax-displayMin)*initPct))
	sliderHitbox.MouseButton1Down:Connect(function() dragging=true end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			local p,v=Compute(input.Position.X); Apply(p,v)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
	end)
	sliderHitbox.MouseButton1Click:Connect(function()
		local mouse=UserInputService:GetMouseLocation()
		local p,v=Compute(mouse.X); Apply(p,v)
	end)
	return row
end

local function MakeDropdownRow(parent, label, options, onChanged)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	Instance.new("UIStroke", row).Color = REDZ.Stroke
	local title = Instance.new("TextLabel", row)
	title.Size = UDim2.new(0.5,0,0,22); title.Position = UDim2.new(0,14,0,8)
	title.BackgroundTransparency = 1; title.Text = label
	title.TextColor3 = REDZ.TextMain; title.Font = Enum.Font.GothamBold; title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	local dropBtn = Instance.new("TextButton", row)
	dropBtn.Size = UDim2.new(0.45,0,0,28); dropBtn.Position = UDim2.new(0.52,0,0.5,-14)
	dropBtn.BackgroundColor3 = REDZ.ToggleOff; dropBtn.Text = options[1] or "None"
	dropBtn.TextColor3 = REDZ.TextMain; dropBtn.Font = Enum.Font.Gotham; dropBtn.TextSize = 11
	dropBtn.BorderSizePixel = 0
	Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0,6)
	local idx = 1
	dropBtn.MouseButton1Click:Connect(function()
		idx = (idx % #options) + 1
		dropBtn.Text = options[idx]
		if onChanged then onChanged(options[idx]) end
	end)
	return row
end

-- ============================================================
-- PAGES
-- ============================================================

-- COMBAT PAGE (original)
local combatPage=MakePage(); pages["combat"]=combatPage
local combatBtn=MakeSidebarBtn("⚔","Combat","combat")

MakeSectionLabel(combatPage,"HITBOX")
local _,hbGet,_=MakeToggleRow(combatPage,"Hitbox Expand","Expand LocalRoot hitbox size")
MakeSliderRow(combatPage,"Hitbox Size",1,100,0.0,"%",function(val) CONFIG.HitboxPercent=val end)
MakeSectionLabel(combatPage,"COMBAT")
local _,hbSpamGet,_=MakeToggleRow(combatPage,"Hitbox Spam","Spawn hitbox parts at position")
local _,dashGet,_=MakeToggleRow(combatPage,"Dash Spam","Hold Q — auto dash no delay")
MakeSectionLabel(combatPage,"SILENT AIM")
local _,silentGet,_=MakeToggleRow(combatPage,"Silent Aim","Kamera redirect ke target")
MakeSliderRow(combatPage,"Silent Aim FOV",30,300,(CONFIG.SilentAimFOV-30)/270," px",function(val)
	CONFIG.SilentAimFOV=val; fovCircle.Radius=val
end)
MakeSectionLabel(combatPage,"FAST ATTACK")
local _,fastAtkGet,_=MakeToggleRow(combatPage,"Fast Attack","FireServer RegisterAttack tanpa delay animasi")
MakeSliderRow(combatPage,"Attack HPS",1,30,(CONFIG.AttackHPS-1)/29," HPS",function(val) CONFIG.AttackHPS=val end)

-- VISUAL PAGE (original)
local visualPage=MakePage(); pages["visual"]=visualPage
local visualBtn=MakeSidebarBtn("👁","Visual","visual")

MakeSectionLabel(visualPage,"ESP")
local _,espGet,_=MakeToggleRow(visualPage,"ESP","Player boxes, health, distance")
local _,tracerGet,_=MakeToggleRow(visualPage,"Tracers","Lines from screen to players")

-- MOVEMENT PAGE (original)
local movePage=MakePage(); pages["movement"]=movePage
local moveBtn=MakeSidebarBtn("🏃","Movement","movement")

MakeSectionLabel(movePage,"SPEED")
local _,speedGet,_=MakeToggleRow(movePage,"Fast Run","Override WalkSpeed every frame")
MakeSliderRow(movePage,"Speed",BASE_SPEED,MAX_SPEED,0.5," ws",function(val,pct)
	CONFIG.SpeedPercent=pct*100
end)

-- ONTOY FARM PAGE
local farmPage=MakePage(); pages["farm"]=farmPage
local farmBtn=MakeSidebarBtn("🌾","Auto Farm","farm")

local statusCard=Instance.new("Frame",farmPage)
statusCard.Size=UDim2.new(1,-8,0,52); statusCard.BackgroundColor3=REDZ.BG2; statusCard.BorderSizePixel=0
Instance.new("UICorner",statusCard).CornerRadius=UDim.new(0,8)
local statusStroke=Instance.new("UIStroke",statusCard); statusStroke.Color=REDZ.Stroke; statusStroke.Thickness=1
local statusIcon=Instance.new("TextLabel",statusCard)
statusIcon.Size=UDim2.new(0,20,1,0); statusIcon.Position=UDim2.new(0,12,0,0)
statusIcon.BackgroundTransparency=1; statusIcon.Text="○"; statusIcon.TextColor3=REDZ.TextSub
statusIcon.Font=Enum.Font.GothamBold; statusIcon.TextSize=14
local statusTitle=Instance.new("TextLabel",statusCard)
statusTitle.Size=UDim2.new(1,-60,0,20); statusTitle.Position=UDim2.new(0,36,0,6)
statusTitle.BackgroundTransparency=1; statusTitle.Text="AUTO FARM"
statusTitle.TextColor3=REDZ.TextSub; statusTitle.Font=Enum.Font.GothamBold; statusTitle.TextSize=10
statusTitle.TextXAlignment=Enum.TextXAlignment.Left
local statusText=Instance.new("TextLabel",statusCard)
statusText.Size=UDim2.new(1,-60,0,18); statusText.Position=UDim2.new(0,36,0,26)
statusText.BackgroundTransparency=1; statusText.Text="Idle"
statusText.TextColor3=REDZ.TextMain; statusText.Font=Enum.Font.Gotham; statusText.TextSize=11
statusText.TextXAlignment=Enum.TextXAlignment.Left

local levelCard=Instance.new("Frame",farmPage)
levelCard.Size=UDim2.new(1,-8,0,52); levelCard.BackgroundColor3=REDZ.BG2; levelCard.BorderSizePixel=0
Instance.new("UICorner",levelCard).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",levelCard).Color=REDZ.Stroke
local levelText=Instance.new("TextLabel",levelCard)
levelText.Size=UDim2.new(1,-16,1,0); levelText.Position=UDim2.new(0,12,0,0)
levelText.BackgroundTransparency=1; levelText.Text="Level: — | Island: — | Target: —"
levelText.TextColor3=REDZ.TextSub; levelText.Font=Enum.Font.Gotham; levelText.TextSize=11
levelText.TextXAlignment=Enum.TextXAlignment.Left; levelText.TextWrapped=true

MakeSectionLabel(farmPage,"MAIN")
local _,farmGet,farmSet=MakeToggleRow(farmPage,"Auto Farm Level","Detect level → fly ke NPC → quest → hover attack",REDZ.Green)
MakeSectionLabel(farmPage,"SETTINGS")
local _,noclipGet,_=MakeToggleRow(farmPage,"Noclip","CanCollide = false saat farm aktif")
MakeSliderRow(farmPage,"Fly Speed",50,700,(CONFIG.FarmFlySpeed-50)/650," stud/s",function(val) CONFIG.FarmFlySpeed=val end)
MakeSliderRow(farmPage,"Hover Height",2,20,(CONFIG.FarmHoverHeight-2)/18," stud",function(val) CONFIG.FarmHoverHeight=val end)

-- RELZ FARM PAGE (new)
local relzPage=MakePage(); pages["relzfarm"]=relzPage
local relzBtn=MakeSidebarBtn("⚡","Farm+","relzfarm")

MakeSectionLabel(relzPage,"NEAREST & MON")
local _,nearestGet,_=MakeToggleRow(relzPage,"Farm Nearest","Serang semua mob terdekat")
local _,attackAuraGet,_=MakeToggleRow(relzPage,"Attack Aura","Auto attack nearest, no logic needed")

MakeSectionLabel(relzPage,"BOSS FARM")
local _,bossGet,_=MakeToggleRow(relzPage,"Farm Boss (Selected)","Auto serang boss pilihan")
local _,allBossGet,_=MakeToggleRow(relzPage,"Farm All Boss","Auto serang semua boss yang spawn")

local bossDropdown = MakeDropdownRow(relzPage,"Boss Target",#tableBoss>0 and tableBoss or {"None"},function(v)
	_G_Farm.SelectedBoss = v
end)
if #tableBoss > 0 then _G_Farm.SelectedBoss = tableBoss[1] end

MakeSectionLabel(relzPage,"MASTERY FARM")
local _,fruitMastGet,_=MakeToggleRow(relzPage,"Fruit Mastery","Farm mastery buah (quest level method)")
local _,gunMastGet,_=MakeToggleRow(relzPage,"Gun Mastery","Farm mastery gun (quest level method)")
local _,swordMastGet,_=MakeToggleRow(relzPage,"Sword Mastery","Farm mastery sword (quest level method)")
MakeSliderRow(relzPage,"Mastery Health%",1,100,0.25,"%",function(val) _G_Farm.MasteryHealth=val end)

MakeSectionLabel(relzPage,"MATERIAL & BONE")
local _,materialGet,_=MakeToggleRow(relzPage,"Farm Material","Farm material dari mob tertentu")

local matList = {}
if World1 then matList={"Magma Ore","Angel Wings","Leather","Scrap Metal"}
elseif World2 then matList={"Radioactive","Mystic Droplet","Magma Ore","Leather","Ectoplasm","Scrap Metal"}
elseif World3 then matList={"Leather","Scrap Metal","Conjured Cocoa","Dragon Scale","Gunpowder","Fish Tail","Mini Tusk"}
end
if #matList > 0 then
	_G_Farm.SelectedMaterial = matList[1]
	MakeDropdownRow(relzPage,"Material",matList,function(v) _G_Farm.SelectedMaterial=v end)
end

if World3 then
	local _,boneGet,_=MakeToggleRow(relzPage,"Farm Bone","Farm skeleton/zombie di Sea 3")
	RunService.Heartbeat:Connect(function()
		local b=boneGet()
		if _G_Farm.AutoFarmBone ~= b then _G_Farm.AutoFarmBone = b end
	end)
end

MakeSectionLabel(relzPage,"SETTINGS")
local _,bringGet,_=MakeToggleRow(relzPage,"Bring Mob","Tarik mob ke posisi player")
MakeSliderRow(relzPage,"Bring Distance",100,1000,0.44," stud",function(val) _G_Farm.BringDistance=val end)
MakeSliderRow(relzPage,"Farm Distance",10,50,0.5," stud",function(val) _G_Farm.FarmDistance=val end)
MakeSliderRow(relzPage,"Tween Speed",50,350,0.71," stud/s",function(val) _G_Farm.PlayerTweenSpeed=val end)
local _,spinGet,_=MakeToggleRow(relzPage,"Spin Position","Berputar saat farm")

-- Seabeast
if World2 or World3 then
	MakeSectionLabel(relzPage,"SEA BEAST")
	local _,sbGet,_=MakeToggleRow(relzPage,"Farm Seabeast","Attack semua sea beast")
	RunService.Heartbeat:Connect(function()
		local s=sbGet()
		if _G_Farm.AutoFarmSeabeast ~= s then _G_Farm.AutoFarmSeabeast=s end
	end)
end

-- STATUS UPDATE
RunService.Heartbeat:Connect(function()
	local farmData,level=GetFarmData()
	if CONFIG.Mode9 then
		statusIcon.TextColor3=REDZ.Green; statusIcon.Text="●"
		statusTitle.TextColor3=REDZ.Green
		statusCard.BackgroundColor3=Color3.fromRGB(12,22,14)
		statusStroke.Color=REDZ.GreenDim
	else
		statusIcon.TextColor3=REDZ.TextSub; statusIcon.Text="○"
		statusTitle.TextColor3=REDZ.TextSub
		statusCard.BackgroundColor3=REDZ.BG2; statusStroke.Color=REDZ.Stroke
	end
	statusText.Text=farmStatus
	if farmData then
		levelText.Text=("Lv %d  |  Sea %d  |  %s  |  Target: %s  [Lv %d-%d]"):format(
			level or 0,farmData.Sea or 1,farmData.Island,farmData.MobName,farmData.MinLvl,farmData.MaxLvl)
	else
		levelText.Text=("Lv %d  |  Data tidak ditemukan"):format(level or 0)
	end
end)

-- Wire relz toggles
RunService.Heartbeat:Connect(function()
	_G_Farm.AutoFarmNearest   = nearestGet()
	_G_Farm.AttackAura        = attackAuraGet()
	_G_Farm.AutoFarmBoss      = bossGet()
	_G_Farm.AutoFarmAllBoss   = allBossGet()
	_G_Farm.AutoFarmFruitMastery = fruitMastGet()
	_G_Farm.AutoFarmGunMastery   = gunMastGet()
	_G_Farm.AutoFarmSwordMastery = swordMastGet()
	_G_Farm.AutoFarmMaterial  = materialGet()
	_G_Farm.BringMob          = bringGet()
	_G_Farm.SpinPosition      = spinGet()
end)

-- ============================================================
-- WIRE ONTOY TOGGLES
-- ============================================================
local function WireToggle(getter,configKey,onEnable,onDisable)
	RunService.Heartbeat:Connect(function()
		local s=getter()
		if CONFIG[configKey]~=s then
			CONFIG[configKey]=s
			if s then if onEnable then onEnable() end
			else      if onDisable then onDisable() end end
		end
	end)
end

WireToggle(hbGet,     "Mode1",nil,RestoreHitbox)
WireToggle(hbSpamGet, "Mode2")
WireToggle(espGet,    "Mode3",nil,HideAllESP)
WireToggle(tracerGet, "Mode4",nil,function()
	for _,esp in pairs(ESP_Objects) do esp.Line.Visible=false end
end)
WireToggle(speedGet,  "Mode5",nil,function()
	local char=LocalPlayer.Character
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed=BASE_SPEED end
end)
WireToggle(dashGet,   "Mode6",StartDashLoop,StopDashLoop)
WireToggle(silentGet, "Mode7",nil,function() silentTarget=nil; fovCircle.Visible=false end)
WireToggle(fastAtkGet,"Mode8",StartFastAttack,StopFastAttack)
WireToggle(farmGet,   "Mode9",
	function() StartNoclip(); StartFarm(); farmStatus="Starting..." end,
	function() StopFarm() end
)
WireToggle(noclipGet, "Mode10",
	function() StartNoclip() end,
	function()
		if not CONFIG.Mode9 then
			if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
		end
	end
)

-- Sidebar button clicks
combatBtn.MouseButton1Click:Connect(function() SetActivePage("combat") end)
visualBtn.MouseButton1Click:Connect(function() SetActivePage("visual") end)
moveBtn.MouseButton1Click:Connect(function()   SetActivePage("movement") end)
farmBtn.MouseButton1Click:Connect(function()   SetActivePage("farm") end)
relzBtn.MouseButton1Click:Connect(function()   SetActivePage("relzfarm") end)
SetActivePage("combat")

-- Minimize / Close
local contentVisible=true
minimizeBtn.MouseButton1Click:Connect(function()
	contentVisible=not contentVisible
	sidebar.Visible=contentVisible; contentArea.Visible=contentVisible
	mainWindow.Size=contentVisible and UDim2.new(0,620,0,420) or UDim2.new(0,620,0,42)
end)

closeBtn.MouseButton1Click:Connect(function()
	RestoreHitbox()
	local char=LocalPlayer.Character
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed=BASE_SPEED end
	HideAllESP(); StopDashLoop(); StopFastAttack(); StopFarm(); StopHoverAnchor()
	if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
	fovCircle:Remove(); screenGui:Destroy()
end)

-- ============================================================
-- CHARACTER RESPAWN
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
	LocalCharacter=char
	LocalRoot=char:WaitForChild("HumanoidRootPart")
	LocalHumanoid=char:WaitForChild("Humanoid")
	OriginalLocalSize=nil; dashHolding=false; silentTarget=nil; isTeleporting=false
	if currentFarmTween then currentFarmTween:Cancel(); currentFarmTween=nil end
	StopHoverAnchor()
	if CONFIG.Mode9 then
		farmState=FARM_STATE.WAIT_CHAR; farmStatus="Respawned — restarting"
	end
	if CONFIG.Mode5 then
		local hum=char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed=GetTargetSpeed() end
	end
end)

-- ============================================================
-- RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
	local char=LocalPlayer.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	local hum =char and char:FindFirstChildOfClass("Humanoid")
	if CONFIG.Mode1 and root then ExpandHitbox() end
	if CONFIG.Mode2 and root then Mode2Func(root.Position) end
	if CONFIG.Mode5 and hum  then hum.WalkSpeed=GetTargetSpeed() end
	if CONFIG.Mode7 then
		ApplySilentAim()
		local vp=Camera.ViewportSize
		fovCircle.Position=Vector2.new(vp.X/2,vp.Y/2)
		fovCircle.Radius=CONFIG.SilentAimFOV; fovCircle.Visible=true
	else
		fovCircle.Visible=false
	end
	RenderESP()
end)
