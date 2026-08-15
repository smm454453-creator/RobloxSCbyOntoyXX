local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

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

local OriginalLocalSize = nil
local ESP_Objects       = {}
local lastDashTime      = 0
local dashHolding       = false
local dashConn          = nil
local fastAttackConn    = nil
local lastAttackTick    = 0
local farmConn          = nil
local currentFarmTween  = nil

local RegisterAttack = nil
local RegisterHit = nil
local CommF = nil
local Net = nil

task.spawn(function()
    pcall(function()
        Net = require(ReplicatedStorage:WaitForChild("Modules",5):WaitForChild("Net",5))
    end)
end)

task.spawn(function()
    pcall(function()
        local net = Net or require(ReplicatedStorage:WaitForChild("Modules",5):WaitForChild("Net",5))
        if net and net.RemoteEvent then
            RegisterAttack = net:RemoteEvent("RegisterAttack", true)
            RegisterHit = net:RemoteEvent("RegisterHit", true)
        end
    end)
    if not RegisterAttack then
        RegisterAttack = ReplicatedStorage:FindFirstChild("RegisterAttack", true)
    end
    if not RegisterHit then
        RegisterHit = ReplicatedStorage:FindFirstChild("RegisterHit", true)
    end
end)

task.spawn(function()
    pcall(function()
        CommF = ReplicatedStorage:WaitForChild("Remotes",5):WaitForChild("CommF_",5)
    end)
end)

local World1, World2, World3 = false, false, false
local WorldName = "Sea1"
if game.PlaceId == 2753915549 or game.PlaceId == 85211729168715 then
    World1, World2, World3 = true, false, false
    WorldName = "Sea1"
elseif game.PlaceId == 4442272183 or game.PlaceId == 79091703265657 then
    World1, World2, World3 = false, true, false
    WorldName = "Sea2"
elseif game.PlaceId == 7449423635 or game.PlaceId == 100117331123089 then
    World1, World2, World3 = false, false, true
    WorldName = "Sea3"
end
_G.WorldName = WorldName
_G.AutoFarmLevel = false

local function requestEntrance(pos)
    if CommF then
        pcall(function() CommF:InvokeServer("requestEntrance", pos) end)
    end
end

-- Relz quest routing for farm.
function CheckQuest() if World1 then if MyLevel == 1 or MyLevel <= 9 then Mon = "Bandit"; LevelQuest = 1; NameQuest = "BanditQuest1"; NameMon = "Bandit"; CFrameQuest = CFrame.new(1059.37195, 15.4495068, 1550.4231, 0.939700544, -0, -0.341998369, 0, 1, -0, 0.341998369, 0, 0.939700544); CFrameMon = CFrame.new(1045.962646484375, 27.00250816345215, 1560.8203125); elseif MyLevel == 10 or MyLevel <= 14 then Mon = "Monkey"; LevelQuest = 1; NameQuest = "JungleQuest"; NameMon = "Monkey"; CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, -0, -1, 0, 0); CFrameMon = CFrame.new(-1448.51806640625, 67.85301208496094, 11.46579647064209); elseif MyLevel == 15 or MyLevel <= 29 then Mon = "Gorilla"; LevelQuest = 2; NameQuest = "JungleQuest"; NameMon = "Gorilla"; CFrameQuest = CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, -0, -1, 0, 0); CFrameMon = CFrame.new(-1129.8836669921875, 40.46354675292969, -525.4237060546875); elseif MyLevel == 30 or MyLevel <= 39 then Mon = "Pirate"; LevelQuest = 1; NameQuest = "BuggyQuest1"; NameMon = "Pirate"; CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627); CFrameMon = CFrame.new(-1103.513427734375, 13.752052307128906, 3896.091064453125); elseif MyLevel == 40 or MyLevel <= 59 then Mon = "Brute"; LevelQuest = 2; NameQuest = "BuggyQuest1"; NameMon = "Brute"; CFrameQuest = CFrame.new(-1141.07483, 4.10001802, 3831.5498, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627); CFrameMon = CFrame.new(-1140.083740234375, 14.809885025024414, 4322.92138671875); elseif MyLevel == 60 or MyLevel <= 74 then Mon = "Desert Bandit"; LevelQuest = 1; NameQuest = "DesertQuest"; NameMon = "Desert Bandit"; CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, 0.819155693, -0, -0.573571265, 0, 1, -0, 0.573571265, 0, 0.819155693); CFrameMon = CFrame.new(924.7998046875, 6.44867467880249, 4481.5859375); elseif MyLevel == 75 or MyLevel <= 89 then Mon = "Desert Officer"; LevelQuest = 2; NameQuest = "DesertQuest"; NameMon = "Desert Officer"; CFrameQuest = CFrame.new(894.488647, 5.14000702, 4392.43359, 0.819155693, -0, -0.573571265, 0, 1, -0, 0.573571265, 0, 0.819155693); CFrameMon = CFrame.new(1608.2822265625, 8.614224433898926, 4371.00732421875); elseif MyLevel == 90 or MyLevel <= 99 then Mon = "Snow Bandit"; LevelQuest = 1; NameQuest = "SnowQuest"; NameMon = "Snow Bandit"; CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685); CFrameMon = CFrame.new(1354.347900390625, 87.27277374267578, -1393.946533203125); elseif MyLevel == 100 or MyLevel <= 119 then Mon = "Snowman"; LevelQuest = 2; NameQuest = "SnowQuest"; NameMon = "Snowman"; CFrameQuest = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685); CFrameMon = CFrame.new(1201.6412353515625, 144.57958984375, -1550.0670166015625); elseif MyLevel == 120 or MyLevel <= 149 then Mon = "Chief Petty Officer"; LevelQuest = 1; NameQuest = "MarineQuest2"; NameMon = "Chief Petty Officer"; CFrameQuest = CFrame.new(-5039.58643, 27.3500385, 4324.68018, 0, 0, -1, 0, 1, 0, 1, 0, 0); CFrameMon = CFrame.new(-4881.23095703125, 22.65204429626465, 4273.75244140625); elseif MyLevel == 150 or MyLevel <= 174 then Mon = "Sky Bandit"; LevelQuest = 1; NameQuest = "SkyQuest"; NameMon = "Sky Bandit"; CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268); CFrameMon = CFrame.new(-4953.20703125, 295.74420166015625, -2899.22900390625); elseif MyLevel == 175 or MyLevel <= 189 then Mon = "Dark Master"; LevelQuest = 2; NameQuest = "SkyQuest"; NameMon = "Dark Master"; CFrameQuest = CFrame.new(-4839.53027, 716.368591, -2619.44165, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268); CFrameMon = CFrame.new(-5259.8447265625, 391.3976745605469, -2229.035400390625); elseif MyLevel == 190 or MyLevel <= 209 then Mon = "Prisoner"; LevelQuest = 1; NameQuest = "PrisonerQuest"; NameMon = "Prisoner"; CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, -0.0894274712, -0.00000000500292918, -0.995993316, 0.00000000160817859, 1, -0.00000000516744869, 0.995993316, -0.00000000206384709, -0.0894274712); CFrameMon = CFrame.new(5098.9736328125, -0.3204058110713959, 474.2373352050781); elseif MyLevel == 210 or MyLevel <= 249 then Mon = "Dangerous Prisoner"; LevelQuest = 2; NameQuest = "PrisonerQuest"; NameMon = "Dangerous Prisoner"; CFrameQuest = CFrame.new(5308.93115, 1.65517521, 475.120514, -0.0894274712, -0.00000000500292918, -0.995993316, 0.00000000160817859, 1, -0.00000000516744869, 0.995993316, -0.00000000206384709, -0.0894274712); CFrameMon = CFrame.new(5654.5634765625, 15.633401870727539, 866.2991943359375); elseif MyLevel == 250 or MyLevel <= 274 then Mon = "Toga Warrior"; LevelQuest = 1; NameQuest = "ColosseumQuest"; NameMon = "Toga Warrior"; CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, 0.857167721, 0, -0.515037298); CFrameMon = CFrame.new(-1820.21484375, 51.68385696411133, -2740.6650390625); elseif MyLevel == 275 or MyLevel <= 299 then Mon = "Gladiator"; LevelQuest = 2; NameQuest = "ColosseumQuest"; NameMon = "Gladiator"; CFrameQuest = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, 0.857167721, 0, -0.515037298); CFrameMon = CFrame.new(-1292.838134765625, 56.380882263183594, -3339.031494140625); elseif MyLevel == 300 or MyLevel <= 324 then Mon = "Military Soldier"; LevelQuest = 1; NameQuest = "MagmaQuest"; NameMon = "Military Soldier"; CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469); CFrameMon = CFrame.new(-5411.16455078125, 11.081554412841797, 8454.29296875); elseif MyLevel == 325 or MyLevel <= 374 then Mon = "Military Spy"; LevelQuest = 2; NameQuest = "MagmaQuest"; NameMon = "Military Spy"; CFrameQuest = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469); CFrameMon = CFrame.new(-5802.8681640625, 86.26241302490234, 8828.859375); elseif MyLevel == 375 or MyLevel <= 399 then Mon = "Fishman Warrior"; LevelQuest = 1; NameQuest = "FishmanQuest"; NameMon = "Fishman Warrior"; CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734); CFrameMon = CFrame.new(60878.30078125, 18.482830047607422, 1543.7574462890625); if _G.AutoFarmLevel and (CFrameQuest.Position - HumanoidRootPart.Position).Magnitude > 10000 then Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163.8515625, 11.6796875, 1819.7841796875)); end; elseif MyLevel == 400 or MyLevel <= 449 then Mon = "Fishman Commando"; LevelQuest = 2; NameQuest = "FishmanQuest"; NameMon = "Fishman Commando"; CFrameQuest = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734); CFrameMon = CFrame.new(61922.6328125, 18.482830047607422, 1493.934326171875); if _G.AutoFarmLevel and (CFrameQuest.Position - HumanoidRootPart.Position).Magnitude > 10000 then Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(61163.8515625, 11.6796875, 1819.7841796875)); end; elseif MyLevel == 450 or MyLevel <= 474 then Mon = "God's Guard"; LevelQuest = 1; NameQuest = "SkyExp1Quest"; NameMon = "God's Guard"; CFrameQuest = CFrame.new(-4721.88867, 843.874695, -1949.96643, 0.996191859, -0, -0.0871884301, 0, 1, -0, 0.0871884301, 0, 0.996191859); CFrameMon = CFrame.new(-4710.04296875, 845.2769775390625, -1927.3079833984375); if _G.AutoFarmLevel and (CFrameQuest.Position - HumanoidRootPart.Position).Magnitude > 10000 then Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-4607.82275, 872.54248, -1667.55688)); end; elseif MyLevel == 475 or MyLevel <= 524 then Mon = "Shanda"; LevelQuest = 2; NameQuest = "SkyExp1Quest"; NameMon = "Shanda"; CFrameQuest = CFrame.new(-7859.09814, 5544.19043, -381.476196, -0.422592998, 0, 0.906319618, 0, 1, 0, -0.906319618, 0, -0.422592998); CFrameMon = CFrame.new(-7678.48974609375, 5566.40380859375, -497.2156066894531); if _G.AutoFarmLevel and (CFrameQuest.Position - HumanoidRootPart.Position).Magnitude > 10000 then Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047)); end; elseif MyLevel == 525 or MyLevel <= 549 then Mon = "Royal Squad"; LevelQuest = 1; NameQuest = "SkyExp2Quest"; NameMon = "Royal Squad"; CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0); CFrameMon = CFrame.new(-7624.25244140625, 5658.13330078125, -1467.354248046875); elseif MyLevel == 550 or MyLevel <= 624 then Mon = "Royal Soldier"; LevelQuest = 2; NameQuest = "SkyExp2Quest"; NameMon = "Royal Soldier"; CFrameQuest = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0); CFrameMon = CFrame.new(-7836.75341796875, 5645.6640625, -1790.6236572265625); elseif MyLevel == 625 or MyLevel <= 649 then Mon = "Galley Pirate"; LevelQuest = 1; NameQuest = "FountainQuest"; NameMon = "Galley Pirate"; CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, 0.087131381, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, 0.087131381); CFrameMon = CFrame.new(5551.02197265625, 78.90135192871094, 3930.412841796875); elseif MyLevel >= 650 then Mon = "Galley Captain"; LevelQuest = 2; NameQuest = "FountainQuest"; NameMon = "Galley Captain"; CFrameQuest = CFrame.new(5259.81982, 37.3500175, 4050.0293, 0.087131381, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, 0.087131381); CFrameMon = CFrame.new(5441.95166015625, 42.50205993652344, 4950.09375); end; elseif World2 then if MyLevel == 700 or MyLevel <= 724 then Mon = "Raider"; LevelQuest = 1; NameQuest = "Area1Quest"; NameMon = "Raider"; CFrameQuest = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, 0.974368095, 0, -0.22495985); CFrameMon = CFrame.new(-728.3267211914062, 52.779319763183594, 2345.7705078125); elseif MyLevel == 725 or MyLevel <= 774 then Mon = "Mercenary"; LevelQuest = 2; NameQuest = "Area1Quest"; NameMon = "Mercenary"; CFrameQuest = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, 0.974368095, 0, -0.22495985); CFrameMon = CFrame.new(-1004.3244018554688, 80.15886688232422, 1424.619384765625); elseif MyLevel == 775 or MyLevel <= 799 then Mon = "Swan Pirate"; LevelQuest = 1; NameQuest = "Area2Quest"; NameMon = "Swan Pirate"; CFrameQuest = CFrame.new(638.43811, 71.769989, 918.282898, 0.139203906, 0, 0.99026376, 0, 1, 0, -0.99026376, 0, 0.139203906); CFrameMon = CFrame.new(1068.664306640625, 137.61428833007812, 1322.1060791015625); elseif MyLevel == 800 or MyLevel <= 874 then Mon = "Factory Staff"; NameQuest = "Area2Quest"; LevelQuest = 2; NameMon = "Factory Staff"; CFrameQuest = CFrame.new(632.698608, 73.1055908, 918.666321, -0.0319722369, 0.000000000896074881, -0.999488771, 0.000000000136326533, 1, 0.000000000892172336, 0.999488771, -0.000000000107732087, -0.0319722369); CFrameMon = CFrame.new(73.07867431640625, 81.86344146728516, -27.470672607421875); elseif MyLevel == 875 or MyLevel <= 899 then Mon = "Marine Lieutenant"; LevelQuest = 1; NameQuest = "MarineQuest3"; NameMon = "Marine Lieutenant"; CFrameQuest = CFrame.new(-2440.79639, 71.7140732, -3216.06812, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268); CFrameMon = CFrame.new(-2821.372314453125, 75.89727783203125, -3070.089111328125); elseif MyLevel == 900 or MyLevel <= 949 then Mon = "Marine Captain"; LevelQuest = 2; NameQuest = "MarineQuest3"; NameMon = "Marine Captain"; CFrameQuest = CFrame.new(-2440.79639, 71.7140732, -3216.06812, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268); CFrameMon = CFrame.new(-1861.2310791015625, 80.17658233642578, -3254.697509765625); elseif MyLevel == 950 or MyLevel <= 974 then Mon = "Zombie"; LevelQuest = 1; NameQuest = "ZombieQuest"; NameMon = "Zombie"; CFrameQuest = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, 0.95628953, 0, -0.29242146); CFrameMon = CFrame.new(-5657.77685546875, 78.96973419189453, -928.68701171875); elseif MyLevel == 975 or MyLevel <= 999 then Mon = "Vampire"; LevelQuest = 2; NameQuest = "ZombieQuest"; NameMon = "Vampire"; CFrameQuest = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, 0.95628953, 0, -0.29242146); CFrameMon = CFrame.new(-6037.66796875, 32.18463897705078, -1340.6597900390625); elseif MyLevel == 1000 or MyLevel <= 1049 then Mon = "Snow Trooper"; LevelQuest = 1; NameQuest = "SnowMountainQuest"; NameMon = "Snow Trooper"; CFrameQuest = CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, 0.92718488, 0, 1, 0, -0.92718488, 0, -0.374604106); CFrameMon = CFrame.new(549.1473388671875, 427.3870544433594, -5563.69873046875); elseif MyLevel == 1050 or MyLevel <= 1099 then Mon = "Winter Warrior"; LevelQuest = 2; NameQuest = "SnowMountainQuest"; NameMon = "Winter Warrior"; CFrameQuest = CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, 0.92718488, 0, 1, 0, -0.92718488, 0, -0.374604106); CFrameMon = CFrame.new(1142.7451171875, 475.6398010253906, -5199.41650390625); elseif MyLevel == 1100 or MyLevel <= 1124 then Mon = "Lab Subordinate"; LevelQuest = 1; NameQuest = "IceSideQuest"; NameMon = "Lab Subordinate"; CFrameQuest = CFrame.new(-6064.06885, 15.2422857, -4902.97852, 0.453972578, -0, -0.891015649, 0, 1, -0, 0.891015649, 0, 0.453972578); CFrameMon = CFrame.new(-5707.4716796875, 15.951709747314453, -4513.39208984375); elseif MyLevel == 1125 or MyLevel <= 1174 then Mon = "Horned Warrior"; LevelQuest = 2; NameQuest = "IceSideQuest"; NameMon = "Horned Warrior"; CFrameQuest = CFrame.new(-6064.06885, 15.2422857, -4902.97852, 0.453972578, -0, -0.891015649, 0, 1, -0, 0.891015649, 0, 0.453972578); CFrameMon = CFrame.new(-6341.36669921875, 15.951770782470703, -5723.162109375); elseif MyLevel == 1175 or MyLevel <= 1199 then Mon = "Magma Ninja"; LevelQuest = 1; NameQuest = "FireSideQuest"; NameMon = "Magma Ninja"; CFrameQuest = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.469463557, 0, -0.882952213); CFrameMon = CFrame.new(-5449.6728515625, 76.65874481201172, -5808.20068359375); elseif MyLevel == 1200 or MyLevel <= 1249 then Mon = "Lava Pirate"; LevelQuest = 2; NameQuest = "FireSideQuest"; NameMon = "Lava Pirate"; CFrameQuest = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.469463557, 0, -0.882952213); CFrameMon = CFrame.new(-5213.33154296875, 49.73788070678711, -4701.451171875); elseif MyLevel == 1250 or MyLevel <= 1274 then Mon = "Ship Deckhand"; LevelQuest = 1; NameQuest = "ShipQuest1"; NameMon = "Ship Deckhand"; CFrameQuest = CFrame.new(1037.80127, 125.092171, 32911.6016); CFrameMon = CFrame.new(1212.0111083984375, 150.79205322265625, 33059.24609375); if _G.AutoFarmLevel and (CFrameQuest.Position - HumanoidRootPart.Position).Magnitude > 10000 then Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)); end; elseif MyLevel == 1275 or MyLevel <= 1299 then Mon = "Ship Engineer"; LevelQuest = 2; NameQuest = "ShipQuest1"; NameMon = "Ship Engineer"; CFrameQuest = CFrame.new(1037.80127, 125.092171, 32911.6016); CFrameMon = CFrame.new(919.4786376953125, 43.54401397705078, 32779.96875); if _G.AutoFarmLevel and (CFrameQuest.Position - HumanoidRootPart.Position).Magnitude > 10000 then Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)); end; elseif MyLevel == 1300 or MyLevel <= 1324 then Mon = "Ship Steward"; LevelQuest = 1; NameQuest = "ShipQuest2"; NameMon = "Ship Steward"; CFrameQuest = CFrame.new(968.80957, 125.092171, 33244.125); CFrameMon = CFrame.new(919.4385375976562, 129.55599975585938, 33436.03515625); if _G.AutoFarmLevel and (CFrameQuest.Position - HumanoidRootPart.Position).Magnitude > 10000 then Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)); end; elseif MyLevel == 1325 or MyLevel <= 1349 then Mon = "Ship Officer"; LevelQuest = 2; NameQuest = "ShipQuest2"; NameMon = "Ship Officer"; CFrameQuest = CFrame.new(968.80957, 125.092171, 33244.125); CFrameMon = CFrame.new(1036.0179443359375, 181.4390411376953, 33315.7265625); if _G.AutoFarmLevel and (CFrameQuest.Position - HumanoidRootPart.Position).Magnitude > 10000 then Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)); end; elseif MyLevel == 1350 or MyLevel <= 1374 then Mon = "Arctic Warrior"; LevelQuest = 1; NameQuest = "FrostQuest"; NameMon = "Arctic Warrior"; CFrameQuest = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.933587909, 0, -0.358349502, 0, 1, 0, 0.358349502, 0, -0.933587909); CFrameMon = CFrame.new(5966.24609375, 62.97002029418945, -6179.3828125); if _G.AutoFarmLevel and (CFrameQuest.Position - HumanoidRootPart.Position).Magnitude > 10000 then Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-6508.5581054688, 5000.034996032715, -132.83953857422)); end; elseif MyLevel == 1375 or MyLevel <= 1424 then Mon = "Snow Lurker"; LevelQuest = 2; NameQuest = "FrostQuest"; NameMon = "Snow Lurker"; CFrameQuest = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.933587909, 0, -0.358349502, 0, 1, 0, 0.358349502, 0, -0.933587909); CFrameMon = CFrame.new(5407.07373046875, 69.19437408447266, -6880.88037109375); elseif MyLevel == 1425 or MyLevel <= 1449 then Mon = "Sea Soldier"; LevelQuest = 1; NameQuest = "ForgottenQuest"; NameMon = "Sea Soldier"; CFrameQuest = CFrame.new(-3054.44458, 235.544281, -10142.8193, 0.990270376, -0, -0.13915664, 0, 1, -0, 0.13915664, 0, 0.990270376); CFrameMon = CFrame.new(-3028.2236328125, 64.67451477050781, -9775.4267578125); elseif MyLevel >= 1450 then Mon = "Water Fighter"; LevelQuest = 2; NameQuest = "ForgottenQuest"; NameMon = "Water Fighter"; CFrameQuest = CFrame.new(-3054.44458, 235.544281, -10142.8193, 0.990270376, -0, -0.13915664, 0, 1, -0, 0.13915664, 0, 0.990270376); CFrameMon = CFrame.new(-3352.9013671875, 285.01556396484375, -10534.841796875); end; elseif World3 then if MyLevel == 1500 or MyLevel <= 1524 then Mon = "Pirate Millionaire"; LevelQuest = 1; NameQuest = "PiratePortQuest"; NameMon = "Pirate Millionaire"; CFrameQuest = CFrame.new(-290.074677, 42.9034653, 5581.58984, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627); CFrameMon = CFrame.new(-245.9963836669922, 47.30615234375, 5584.1005859375); elseif MyLevel == 1525 or MyLevel <= 1574 then Mon = "Pistol Billionaire"; LevelQuest = 2; NameQuest = "PiratePortQuest"; NameMon = "Pistol Billionaire"; CFrameQuest = CFrame.new(-290.074677, 42.9034653, 5581.58984, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627); CFrameMon = CFrame.new(-187.3301544189453, 86.23987579345703, 6013.513671875); elseif MyLevel == 1575 or MyLevel <= 1599 then Mon = "Dragon Crew Warrior"; LevelQuest = 1; NameQuest = "AmazonQuest"; NameMon = "Dragon Crew Warrior"; CFrameQuest = CFrame.new(5832.83594, 51.6806107, -1101.51563, 0.898790359, -0, -0.438378751, 0, 1, -0, 0.438378751, 0, 0.898790359); CFrameMon = CFrame.new(6141.140625, 51.35136413574219, -1340.738525390625); elseif MyLevel == 1600 or MyLevel <= 1624 then Mon = "Dragon Crew Archer [Lv. 1600]"; NameQuest = "AmazonQuest"; LevelQuest = 2; NameMon = "Dragon Crew Archer"; CFrameQuest = CFrame.new(5833.1147460938, 51.60498046875, -1103.0693359375); CFrameMon = CFrame.new(6616.41748046875, 441.7670593261719, 446.0469970703125); elseif MyLevel == 1625 or MyLevel <= 1649 then Mon = "Female Islander"; NameQuest = "AmazonQuest2"; LevelQuest = 1; NameMon = "Female Islander"; CFrameQuest = CFrame.new(5446.8793945313, 601.62945556641, 749.45672607422); CFrameMon = CFrame.new(4685.25830078125, 735.8078002929688, 815.3425903320312); elseif MyLevel == 1650 or MyLevel <= 1699 then Mon = "Giant Islander [Lv. 1650]"; NameQuest = "AmazonQuest2"; LevelQuest = 2; NameMon = "Giant Islander"; CFrameQuest = CFrame.new(5446.8793945313, 601.62945556641, 749.45672607422); CFrameMon = CFrame.new(4729.09423828125, 590.436767578125, -36.97627639770508); elseif MyLevel == 1700 or MyLevel <= 1724 then Mon = "Marine Commodore"; LevelQuest = 1; NameQuest = "MarineTreeIsland"; NameMon = "Marine Commodore"; CFrameQuest = CFrame.new(2180.54126, 27.8156815, -6741.5498, -0.965929747, 0, 0.258804798, 0, 1, 0, -0.258804798, 0, -0.965929747); CFrameMon = CFrame.new(2286.0078125, 73.13391876220703, -7159.80908203125); elseif MyLevel == 1725 or MyLevel <= 1774 then Mon = "Marine Rear Admiral [Lv. 1725]"; NameMon = "Marine Rear Admiral"; NameQuest = "MarineTreeIsland"; LevelQuest = 2; CFrameQuest = CFrame.new(2179.98828125, 28.731239318848, -6740.0551757813); CFrameMon = CFrame.new(3656.773681640625, 160.52406311035156, -7001.5986328125); elseif MyLevel == 1775 or MyLevel <= 1799 then Mon = "Fishman Raider"; LevelQuest = 1; NameQuest = "DeepForestIsland3"; NameMon = "Fishman Raider"; CFrameQuest = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.469463557, 0, -0.882952213); CFrameMon = CFrame.new(-10407.5263671875, 331.76263427734375, -8368.5166015625); elseif MyLevel == 1800 or MyLevel <= 1824 then Mon = "Fishman Captain"; LevelQuest = 2; NameQuest = "DeepForestIsland3"; NameMon = "Fishman Captain"; CFrameQuest = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.469463557, 0, -0.882952213); CFrameMon = CFrame.new(-10994.701171875, 352.38140869140625, -9002.1103515625); elseif MyLevel == 1825 or MyLevel <= 1849 then Mon = "Forest Pirate"; LevelQuest = 1; NameQuest = "DeepForestIsland"; NameMon = "Forest Pirate"; CFrameQuest = CFrame.new(-13234.04, 331.488495, -7625.40137, 0.707134247, -0, -0.707079291, 0, 1, -0, 0.707079291, 0, 0.707134247); CFrameMon = CFrame.new(-13274.478515625, 332.3781433105469, -7769.58056640625); elseif MyLevel == 1850 or MyLevel <= 1899 then Mon = "Mythological Pirate"; LevelQuest = 2; NameQuest = "DeepForestIsland"; NameMon = "Mythological Pirate"; CFrameQuest = CFrame.new(-13234.04, 331.488495, -7625.40137, 0.707134247, -0, -0.707079291, 0, 1, -0, 0.707079291, 0, 0.707134247); CFrameMon = CFrame.new(-13680.607421875, 501.08154296875, -6991.189453125); elseif MyLevel == 1900 or MyLevel <= 1924 then Mon = "Jungle Pirate"; LevelQuest = 1; NameQuest = "DeepForestIsland2"; NameMon = "Jungle Pirate"; CFrameQuest = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.0871315002, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, -0.0871315002); CFrameMon = CFrame.new(-12256.16015625, 331.73828125, -10485.8369140625); elseif MyLevel == 1925 or MyLevel <= 1974 then Mon = "Musketeer Pirate"; LevelQuest = 2; NameQuest = "DeepForestIsland2"; NameMon = "Musketeer Pirate"; CFrameQuest = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.0871315002, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, -0.0871315002); CFrameMon = CFrame.new(-13457.904296875, 391.545654296875, -9859.177734375); elseif MyLevel == 1975 or MyLevel <= 1999 then Mon = "Reborn Skeleton"; LevelQuest = 1; NameQuest = "HauntedQuest1"; NameMon = "Reborn Skeleton"; CFrameQuest = CFrame.new(-9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, -0, -1, 0, 0); CFrameMon = CFrame.new(-8763.7236328125, 165.72299194335938, 6159.86181640625); elseif MyLevel == 2000 or MyLevel <= 2024 then Mon = "Living Zombie"; LevelQuest = 2; NameQuest = "HauntedQuest1"; NameMon = "Living Zombie"; CFrameQuest = CFrame.new(-9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, -0, -1, 0, 0); CFrameMon = CFrame.new(-10144.1318359375, 138.62667846679688, 5838.0888671875); elseif MyLevel == 2025 or MyLevel <= 2049 then Mon = "Demonic Soul"; LevelQuest = 1; NameQuest = "HauntedQuest2"; NameMon = "Demonic Soul"; CFrameQuest = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0); CFrameMon = CFrame.new(-9505.8720703125, 172.10482788085938, 6158.9931640625); elseif MyLevel == 2050 or MyLevel <= 2074 then Mon = "Posessed Mummy"; LevelQuest = 2; NameQuest = "HauntedQuest2"; NameMon = "Posessed Mummy"; CFrameQuest = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0); CFrameMon = CFrame.new(-9582.0224609375, 6.251527309417725, 6205.478515625); elseif MyLevel == 2075 or MyLevel <= 2099 then Mon = "Peanut Scout"; LevelQuest = 1; NameQuest = "NutsIslandQuest"; NameMon = "Peanut Scout"; CFrameQuest = CFrame.new(-2104.3908691406, 38.104167938232, -10194.21875, 0, 0, -1, 0, 1, 0, 1, 0, 0); CFrameMon = CFrame.new(-2143.241943359375, 47.72198486328125, -10029.9951171875); elseif MyLevel == 2100 or MyLevel <= 2124 then Mon = "Peanut President"; LevelQuest = 2; NameQuest = "NutsIslandQuest"; NameMon = "Peanut President"; CFrameQuest = CFrame.new(-2104.3908691406, 38.104167938232, -10194.21875, 0, 0, -1, 0, 1, 0, 1, 0, 0); CFrameMon = CFrame.new(-1859.35400390625, 38.10316848754883, -10422.4296875); elseif MyLevel == 2125 or MyLevel <= 2149 then Mon = "Ice Cream Chef"; LevelQuest = 1; NameQuest = "IceCreamIslandQuest"; NameMon = "Ice Cream Chef"; CFrameQuest = CFrame.new(-820.64825439453, 65.819526672363, -10965.795898438, 0, 0, -1, 0, 1, 0, 1, 0, 0); CFrameMon = CFrame.new(-872.24658203125, 65.81957244873047, -10919.95703125); elseif MyLevel == 2150 or MyLevel <= 2199 then Mon = "Ice Cream Commander"; LevelQuest = 2; NameQuest = "IceCreamIslandQuest"; NameMon = "Ice Cream Commander"; CFrameQuest = CFrame.new(-820.64825439453, 65.819526672363, -10965.795898438, 0, 0, -1, 0, 1, 0, 1, 0, 0); CFrameMon = CFrame.new(-558.06103515625, 112.04895782470703, -11290.7744140625); elseif MyLevel == 2200 or MyLevel <= 2224 then Mon = "Cookie Crafter"; LevelQuest = 1; NameQuest = "CakeQuest1"; NameMon = "Cookie Crafter"; CFrameQuest = CFrame.new(-2021.32007, 37.7982254, -12028.7295, 0.957576931, -0.0000000880302053, 0.288177818, 0.000000069301187, 1, 0.0000000751931211, -0.288177818, -0.000000052032135, 0.957576931); CFrameMon = CFrame.new(-2374.13671875, 37.79826354980469, -12125.30859375); elseif MyLevel == 2225 or MyLevel <= 2249 then Mon = "Cake Guard"; LevelQuest = 2; NameQuest = "CakeQuest1"; NameMon = "Cake Guard"; CFrameQuest = CFrame.new(-2021.32007, 37.7982254, -12028.7295, 0.957576931, -0.0000000880302053, 0.288177818, 0.000000069301187, 1, 0.0000000751931211, -0.288177818, -0.000000052032135, 0.957576931); CFrameMon = CFrame.new(-1598.3070068359375, 43.773197174072266, -12244.5810546875); elseif MyLevel == 2250 or MyLevel <= 2274 then Mon = "Baking Staff"; LevelQuest = 1; NameQuest = "CakeQuest2"; NameMon = "Baking Staff"; CFrameQuest = CFrame.new(-1927.91602, 37.7981339, -12842.5391, -0.96804446, 0.0000000422142143, 0.250778586, 0.0000000474911062, 1, 0.0000000149904711, -0.250778586, 0.0000000264211941, -0.96804446); CFrameMon = CFrame.new(-1887.8099365234375, 77.6185073852539, -12998.3505859375); elseif MyLevel == 2275 or MyLevel <= 2299 then Mon = "Head Baker"; LevelQuest = 2; NameQuest = "CakeQuest2"; NameMon = "Head Baker"; CFrameQuest = CFrame.new(-1927.91602, 37.7981339, -12842.5391, -0.96804446, 0.0000000422142143, 0.250778586, 0.0000000474911062, 1, 0.0000000149904711, -0.250778586, 0.0000000264211941, -0.96804446); CFrameMon = CFrame.new(-2216.188232421875, 82.884521484375, -12869.2939453125); elseif MyLevel == 2300 or MyLevel <= 2324 then Mon = "Cocoa Warrior"; LevelQuest = 1; NameQuest = "ChocQuest1"; NameMon = "Cocoa Warrior"; CFrameQuest = CFrame.new(233.22836303710938, 29.876001358032227, -12201.2333984375); CFrameMon = CFrame.new(-21.55328369140625, 80.57499694824219, -12352.3876953125); elseif MyLevel == 2325 or MyLevel <= 2349 then Mon = "Chocolate Bar Battler"; LevelQuest = 2; NameQuest = "ChocQuest1"; NameMon = "Chocolate Bar Battler"; CFrameQuest = CFrame.new(233.22836303710938, 29.876001358032227, -12201.2333984375); CFrameMon = CFrame.new(582.590576171875, 77.18809509277344, -12463.162109375); elseif MyLevel == 2350 or MyLevel <= 2374 then Mon = "Sweet Thief"; LevelQuest = 1; NameQuest = "ChocQuest2"; NameMon = "Sweet Thief"; CFrameQuest = CFrame.new(150.5066375732422, 30.693693161010742, -12774.5029296875); CFrameMon = CFrame.new(165.1884765625, 76.05885314941406, -12600.8369140625); elseif MyLevel == 2375 or MyLevel <= 2399 then Mon = "Candy Rebel"; LevelQuest = 2; NameQuest = "ChocQuest2"; NameMon = "Candy Rebel"; CFrameQuest = CFrame.new(150.5066375732422, 30.693693161010742, -12774.5029296875); CFrameMon = CFrame.new(134.86563110351562, 77.2476806640625, -12876.5478515625); elseif MyLevel == 2400 or MyLevel <= 2424 then Mon = "Candy Pirate"; LevelQuest = 1; NameQuest = "CandyQuest1"; NameMon = "Candy Pirate"; CFrameQuest = CFrame.new(-1150.0400390625, 20.378934860229492, -14446.3349609375); CFrameMon = CFrame.new(-1310.5003662109375, 26.016523361206055, -14562.404296875); elseif MyLevel == 2425 or MyLevel <= 2449 then Mon = "Snow Demon"; LevelQuest = 2; NameQuest = "CandyQuest1"; NameMon = "Snow Demon"; CFrameQuest = CFrame.new(-1150.0400390625, 20.378934860229492, -14446.3349609375); CFrameMon = CFrame.new(-880.2006225585938, 71.24776458740234, -14538.609375); elseif MyLevel == 2450 or MyLevel <= 2474 then Mon = "Isle Outlaw"; LevelQuest = 1; NameQuest = "TikiQuest1"; NameMon = "Isle Outlaw"; CFrameQuest = CFrame.new(-16547.748046875, 61.13533401489258, -173.41360473632812); CFrameMon = CFrame.new(-16442.814453125, 116.13899993896484, -264.4637756347656); elseif MyLevel == 2475 or MyLevel <= 2524 then Mon = "Island Boy"; LevelQuest = 2; NameQuest = "TikiQuest1"; NameMon = "Island Boy"; CFrameQuest = CFrame.new(-16547.748046875, 61.13533401489258, -173.41360473632812); CFrameMon = CFrame.new(-16901.26171875, 84.06756591796875, -192.88906860351562); elseif MyLevel == 2525 or MyLevel <= 2549 then Mon = "Isle Champion"; LevelQuest = 2; NameQuest = "TikiQuest2"; NameMon = "Isle Champion"; CFrameQuest = CFrame.new(-16539.078125, 55.68632888793945, 1051.5738525390625); CFrameMon = CFrame.new(-16641.6796875, 235.7825469970703, 1031.282958984375); elseif MyLevel == 2550 or MyLevel <= 2574 then Mon = "Serpent Hunter"; LevelQuest = 1; NameQuest = "TikiQuest3"; NameMon = "Serpent Hunter"; CFrameQuest = CFrame.new(-16661.890625, 105.2862319946289, 1576.69775390625); CFrameMon = CFrame.new(-16587.896484375, 154.21299743652344, 1533.40966796875); elseif MyLevel == 2575 or MyLevel <= 2599 then Mon = "Skull Slayer"; LevelQuest = 2; NameQuest = "TikiQuest3"; NameMon = "Skull Slayer"; CFrameQuest = CFrame.new(-16661.890625, 105.2862319946289, 1576.69775390625); CFrameMon = CFrame.new(-16885.203125, 114.12911224365234, 1627.949951171875); elseif MyLevel == 2600 or MyLevel <= 2624 then Mon = "Reef Bandit"; LevelQuest = 1; NameQuest = "SubmergedQuest1"; NameMon = "Reef Bandit"; CFrameQuest = CFrame.new(10782.134765625, -2087.722412109375, 9268.5205078125); CFrameMon = CFrame.new(10918.134765625, -2115.56103515625, 9055.9892578125); elseif MyLevel == 2625 or MyLevel <= 2649 then Mon = "Coral Pirate"; LevelQuest = 2; NameQuest = "SubmergedQuest1"; NameMon = "Coral Pirate"; CFrameQuest = CFrame.new(10782.134765625, -2087.722412109375, 9268.5205078125); CFrameMon = CFrame.new(10656.0869140625, -2018.734375, 9258.4365234375); elseif MyLevel == 2650 or MyLevel <= 2674 then Mon = "Sea Chanter"; LevelQuest = 1; NameQuest = "SubmergedQuest2"; NameMon = "Sea Chanter"; CFrameQuest = CFrame.new(10879.5546875, -2086.19921875, 10027.486328125); CFrameMon = CFrame.new(10691.50390625, -2023.15234375, 10026.27734375); elseif MyLevel == 2675 or MyLevel <= 2699 then Mon = "Ocean Prophet"; LevelQuest = 2; NameQuest = "SubmergedQuest2"; NameMon = "Ocean Prophet"; CFrameQuest = CFrame.new(10879.5546875, -2086.19921875, 10027.486328125); CFrameMon = CFrame.new(10900.3876953125, -1973.1259765625, 10233.232421875); elseif MyLevel == 2700 or MyLevel >= 2700 then Mon = "Grand Devotee"; LevelQuest = 2; NameQuest = "SubmergedQuest3"; NameMon = "Grand Devotee"; CFrameQuest = CFrame.new(9634.6875, -1992.443603515625, 9608.3154296875); CFrameMon = CFrame.new(9653.1376953125, -1928.2684326171875, 9915.9423828125); end; end; end;

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
    {Sea=3,MinLvl=2525, MaxLvl=2674, Island="Tiki Outpost",     MobFolder="Enemies",MobName="Tiki Outpost Guard", QuestName="TikiQuest",       QuestNum=1,NPCCFrame=CFrame.new(3500,10,5400)},
    {Sea=3,MinLvl=2675, MaxLvl=2799, Island="Tiki Outpost",     MobFolder="Enemies",MobName="Tiki Outpost Guard", QuestName="TikiQuest",       QuestNum=2,NPCCFrame=CFrame.new(3500,10,5400)},
    {Sea=3,MinLvl=2800, MaxLvl=2999, Island="Mirage Island",    MobFolder="Enemies",MobName="Demonic Soul",       QuestName="MirageQuest",     QuestNum=1,NPCCFrame=CFrame.new(-2800,34,3050)},
    {Sea=3,MinLvl=3000, MaxLvl=9999, Island="Mirage Island",    MobFolder="Enemies",MobName="Demonic Soul",       QuestName="MirageQuest",     QuestNum=2,NPCCFrame=CFrame.new(-2800,34,3050)},
}

local farmStatus = "Idle"

local function GetFarmData()
    local ok, level = pcall(function() return LocalPlayer.Data.Level.Value end)
    if not ok then return nil, 0 end
    MyLevel = level
    local okQuest = pcall(CheckQuest)
    if not okQuest or not Mon or not NameQuest or not CFrameQuest or not CFrameMon then
        return nil, level
    end
    local sea = World3 and 3 or (World2 and 2 or 1)
    return {
        Sea = sea,
        MinLvl = level,
        MaxLvl = level,
        Island = World3 and "Sea 3" or (World2 and "Sea 2" or "Sea 1"),
        MobFolder = "Enemies",
        MobName = Mon,
        QuestName = NameQuest,
        QuestNum = LevelQuest,
        NPCCFrame = CFrameQuest,
        MobCFrame = CFrameMon,
    }, level
end

local noclipConn = nil

local function StartNoclip()
    if noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end

local function StopNoclip()
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
end

local function SetPlatformStand(state)
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = state end
end

local function FlyTo(targetCFrame, onDone)
    if currentFarmTween then
        currentFarmTween:Cancel()
        currentFarmTween = nil
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        if onDone then onDone() end
        return
    end

    local destPos  = targetCFrame.Position
    local safeY    = math.max(destPos.Y, MIN_FLY_Y)
    local safeDest = CFrame.new(Vector3.new(destPos.X, safeY, destPos.Z))

    if root.Position.Y < MIN_FLY_Y then
        root.CFrame = CFrame.new(root.Position.X, MIN_FLY_Y, root.Position.Z)
        task.wait(0.05)
        char = LocalPlayer.Character
        root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then if onDone then onDone() end return end
    end

    SetPlatformStand(true)

    local dist  = (safeDest.Position - root.Position).Magnitude
    local dur   = math.clamp(dist / CONFIG.FarmFlySpeed, 0.3, 12)
    local info  = TweenInfo.new(dur, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, info, {CFrame = safeDest})
    currentFarmTween = tween

    local fired = false
    tween.Completed:Connect(function(state)
        if fired then return end
        fired = true
        currentFarmTween = nil
        SetPlatformStand(false)
        if onDone then onDone() end
    end)

    tween:Play()
    return tween
end

local function HasActiveQuest()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return false end
    local main = gui:FindFirstChild("Main")
    if not main then return false end
    local questFrame = main:FindFirstChild("Quest")
    return questFrame and questFrame.Visible
end

local function FindNearestMob(mobName, mobFolder)
    local root = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local folder = Workspace:FindFirstChild(mobFolder or "Enemies")
    if not folder then return nil end
    local best, bestDist = nil, math.huge
    for _, mob in ipairs(folder:GetChildren()) do
        if mob.Name == mobName then
            local hum = mob:FindFirstChild("Humanoid")
            local mr  = mob:FindFirstChild("HumanoidRootPart")
            if hum and mr and hum.Health > 0 then
                local dist = (mr.Position - root.Position).Magnitude
                if dist < bestDist then bestDist = dist best = mob end
            end
        end
    end
    return best
end

local lastFarmAttack = 0
local FARM_ATTACK_INTERVAL = 0.075
local RelzNet = nil
local RelzRegisterAttack = nil
local RelzRegisterHit = nil

local function EnsureRelzAttackRemotes()
    if RelzRegisterAttack and RelzRegisterHit then
        return true
    end
    local ok = pcall(function()
        RelzNet = RelzNet or require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"))
        RelzRegisterAttack = RelzNet:RemoteEvent("RegisterAttack", true)
        RelzRegisterHit = RelzNet:RemoteEvent("RegisterHit", true)
    end)
    return ok and RelzRegisterAttack ~= nil and RelzRegisterHit ~= nil
end

local function GetClosestRelzEnemy(distance)
    local target, others = nil, {}
    local folder = Workspace:FindFirstChild("Enemies")
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not folder or not root then return nil, others end

    for _, enemy in pairs(folder:GetChildren()) do
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = LocalPlayer:DistanceFromCharacter(hrp.Position)
            if dist < distance then
                if not target then
                    target = hrp
                else
                    table.insert(others, {enemy, hrp})
                end
            end
        end
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = LocalPlayer:DistanceFromCharacter(hrp.Position)
                if dist < distance then
                    if not target then
                        target = hrp
                    else
                        table.insert(others, {player, hrp})
                    end
                end
            end
        end
    end

    return target, others
end

local function DoRelzM1(tool)
    if not tool then return end
    pcall(function()
        if tool.Activate then
            tool:Activate()
        end
    end)
    pcall(function()
        local leftClickRemote = tool:FindFirstChild("LeftClickRemote")
        if leftClickRemote and tostring(tool.ToolTip) == "Blox Fruit" then
            leftClickRemote:FireServer(Vector3.new(0.01,-500,0.01), 1, true)
            leftClickRemote:FireServer(false)
        end
    end)
end

local function AttackNearestRelz(tool)
    local now = os.clock()
    if now - lastFarmAttack < FARM_ATTACK_INTERVAL then return end
    lastFarmAttack = now

    local target, others = GetClosestRelzEnemy(120)
    if not target then return end
    if not EnsureRelzAttackRemotes() then
        farmStatus = "Attack remotes belum siap"
        return
    end

    DoRelzM1(tool)
    pcall(function()
        RelzRegisterAttack:FireServer(0)
        RelzRegisterHit:FireServer(target, others)
    end)
end

local function IsCombatTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local tip = tostring(tool.ToolTip or "")
    return tip == "Melee" or tip == "Sword" or tip == "Gun" or tip == "Blox Fruit"
end

local function GetFarmWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end

    local active = char:FindFirstChildOfClass("Tool")
    if IsCombatTool(active) then
        return active
    end

    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if IsCombatTool(tool) then
            return tool
        end
    end
    return nil
end

local function EquipFarmWeapon()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return nil end

    local tool = GetFarmWeapon()
    if tool and tool.Parent ~= char then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.05)
    end
    return char:FindFirstChildOfClass("Tool") or tool
end

local function ExecuteAttack(mob)
    local char = LocalPlayer.Character
    if not char or not mob then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local mr = mob:FindFirstChild("HumanoidRootPart")
    local mh = mob:FindFirstChildOfClass("Humanoid")
    if not hum or not root or not mr or not mh or mh.Health <= 0 then return end

    local tool = EquipFarmWeapon()
    if not tool then
        farmStatus = "No combat weapon"
        return
    end

    pcall(function()
        if CommF and not char:FindFirstChild("HasBuso") then
            CommF:InvokeServer("Buso")
        end
    end)

    -- Relz-style farm position: stay directly above the target.
    pcall(function()
        root.CFrame = mr.CFrame * CFrame.new(0, CONFIG.FarmHoverHeight, 0)
    end)

    farmStatus = "Nyerang " .. tostring(mob.Name) .. " dengan " .. tostring(tool.Name)
    AttackNearestRelz(tool)
end

local FARM_STATE = {
    IDLE       = "idle",
    GO_QUEST   = "go_quest",
    TAKE_QUEST = "take_quest",
    GO_MOB     = "go_mob",
    ATTACK     = "attack",
    WAIT_SPAWN = "wait_spawn",
}

local farmState      = FARM_STATE.IDLE
local waitingFly     = false
local waitSpawnTimer = 0

local function StartFarm()
    if farmConn then farmConn:Disconnect() farmConn = nil end
    farmState      = FARM_STATE.GO_QUEST
    waitingFly     = false
    waitSpawnTimer = 0
    farmStatus     = "Starting..."

    farmConn = RunService.Heartbeat:Connect(function(dt)
        if not CONFIG.Mode9 then return end
        if waitingFly then return end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local farmData, level = GetFarmData()
        if not farmData then
            farmStatus = "Level " .. tostring(level) .. " tidak ada di database"
            return
        end

        if farmState == FARM_STATE.GO_QUEST then
            if HasActiveQuest() then
                farmState  = FARM_STATE.GO_MOB
                farmStatus = "Quest aktif — hunting"
                return
            end
            local dist = (farmData.NPCCFrame.Position - root.Position).Magnitude
            if dist > 20 then
                farmStatus = "Terbang ke NPC quest..."
                waitingFly = true
                FlyTo(farmData.NPCCFrame, function()
                    waitingFly = false
                    farmState  = FARM_STATE.TAKE_QUEST
                end)
            else
                farmState = FARM_STATE.TAKE_QUEST
            end

        elseif farmState == FARM_STATE.TAKE_QUEST then
            if HasActiveQuest() then
                farmState  = FARM_STATE.GO_MOB
                farmStatus = "Quest diterima!"
                return
            end
            local npcDist = (farmData.NPCCFrame.Position - root.Position).Magnitude
            if npcDist > 30 then
                farmState = FARM_STATE.GO_QUEST
                return
            end
            farmStatus = "Ambil quest: " .. farmData.QuestName
            if CommF then
                pcall(function()
                    CommF:InvokeServer("StartQuest", farmData.QuestName, farmData.QuestNum)
                end)
            end
            task.wait(0.8)
            if HasActiveQuest() then
                farmState = FARM_STATE.GO_MOB
            else
                farmStatus = "Quest gagal, retry..."
            end

        elseif farmState == FARM_STATE.GO_MOB then
            if not HasActiveQuest() then
                farmState  = FARM_STATE.GO_QUEST
                farmStatus = "Quest selesai — ambil baru"
                return
            end
            local mob = FindNearestMob(farmData.MobName, farmData.MobFolder)
            if not mob then
                farmState      = FARM_STATE.WAIT_SPAWN
                waitSpawnTimer = 0
                farmStatus     = "Nunggu mob spawn..."
                return
            end
            local mr = mob:FindFirstChild("HumanoidRootPart")
            if not mr then farmStatus = "Mob no root" return end

            local mobPos  = mr.Position
            local hoverY  = math.max(mobPos.Y + CONFIG.FarmHoverHeight, MIN_FLY_Y)
            local hoverCF = CFrame.new(Vector3.new(mobPos.X, hoverY, mobPos.Z))
            local dist    = (hoverCF.Position - root.Position).Magnitude

            if dist > 8 then
                farmStatus = "Terbang ke " .. farmData.MobName .. "..."
                waitingFly = true
                FlyTo(hoverCF, function()
                    waitingFly = false
                    farmState  = FARM_STATE.ATTACK
                end)
            else
                farmState = FARM_STATE.ATTACK
            end

        elseif farmState == FARM_STATE.ATTACK then
            if not HasActiveQuest() then
                farmState  = FARM_STATE.GO_QUEST
                farmStatus = "Quest selesai — ambil baru"
                return
            end
            local mob = FindNearestMob(farmData.MobName, farmData.MobFolder)
            if not mob or not mob:FindFirstChild("HumanoidRootPart") then
                farmState      = FARM_STATE.WAIT_SPAWN
                waitSpawnTimer = 0
                farmStatus     = "Mob mati — nunggu respawn"
                return
            end
            local mr     = mob.HumanoidRootPart
            local mobPos = mr.Position
            local hoverY = math.max(mobPos.Y + CONFIG.FarmHoverHeight, MIN_FLY_Y)
            root.CFrame  = CFrame.new(Vector3.new(mobPos.X, hoverY, mobPos.Z))
            farmStatus   = "Nyerang " .. farmData.MobName
            ExecuteAttack(mob)

        elseif farmState == FARM_STATE.WAIT_SPAWN then
            waitSpawnTimer = waitSpawnTimer + dt
            if waitSpawnTimer < 1.5 then return end
            waitSpawnTimer = 0
            local mob = FindNearestMob(farmData.MobName, farmData.MobFolder)
            if mob then
                farmState  = FARM_STATE.GO_MOB
                farmStatus = "Mob ketemu!"
            end
        end
    end)
end

local function StopFarm()
    if farmConn then farmConn:Disconnect() farmConn = nil end
    if currentFarmTween then currentFarmTween:Cancel() currentFarmTween = nil end
    SetPlatformStand(false)
    StopNoclip()
    farmState      = FARM_STATE.IDLE
    farmStatus     = "Idle"
    waitingFly     = false
    waitSpawnTimer = 0
end

local silentTarget = nil

local function GetSilentTarget()
    local vp  = Camera.ViewportSize
    local cx  = vp.X / 2
    local cy  = vp.Y / 2
    local fov = CONFIG.SilentAimFOV
    local best, bestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChild("Humanoid")
        if not (root and hum and hum.Health > 0) then continue end
        local screen, onScreen = Camera:WorldToScreenPoint(root.Position)
        if not onScreen then continue end
        local dx   = screen.X - cx
        local dy   = screen.Y - cy
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < fov and dist < bestDist then bestDist = dist best = root end
    end
    return best
end

local function ApplySilentAim()
    if not CONFIG.Mode7 then silentTarget = nil return end
    silentTarget = GetSilentTarget()
    if not silentTarget then return end
    if not silentTarget.Parent then silentTarget = nil return end
    local targetPos = silentTarget.Position
    local camPos    = Camera.CFrame.Position
    local direction = (targetPos - camPos).Unit
    Camera.CFrame   = CFrame.new(camPos, camPos + direction)
end

local function GetAttackInterval()
    return 1 / math.max(CONFIG.AttackHPS, 1)
end

local function GetFastTarget()
    if silentTarget and silentTarget.Parent then return silentTarget end
    local best, bestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChild("Humanoid")
        if not (root and hum and hum.Health > 0) then continue end
        local _, onScreen = Camera:WorldToScreenPoint(root.Position)
        if not onScreen then continue end
        local dist = (root.Position - LocalRoot.Position).Magnitude
        if dist < bestDist then bestDist = dist best = root end
    end
    return best
end

local function StartFastAttack()
    if fastAttackConn then fastAttackConn:Disconnect() fastAttackConn = nil end
    fastAttackConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.Mode8 then return end
        if not RegisterAttack then return end
        local now = tick()
        if now - lastAttackTick < GetAttackInterval() then return end
        lastAttackTick = now
        local target = GetFastTarget()
        if not target then return end
        pcall(function() RegisterAttack:FireServer(target) end)
    end)
end

local function StopFastAttack()
    if fastAttackConn then fastAttackConn:Disconnect() fastAttackConn = nil end
end

local function PctToSize(pct)
    return MIN_HITBOX + (MAX_HITBOX - MIN_HITBOX) * ((pct - 1) / 99)
end

local function ExpandHitbox()
    if not OriginalLocalSize then OriginalLocalSize = LocalRoot.Size end
    local sz = PctToSize(CONFIG.HitboxPercent)
    LocalRoot.Size = Vector3.new(sz, sz, sz)
end

local function RestoreHitbox()
    if OriginalLocalSize then
        LocalRoot.Size = OriginalLocalSize
        OriginalLocalSize = nil
    end
end

local function GetTargetSpeed()
    return BASE_SPEED + (MAX_SPEED - BASE_SPEED) * (CONFIG.SpeedPercent / 100)
end

local function Mode2Func(pos)
    local p = Instance.new("Part")
    p.Name = "Ontoy_Part"
    p.Size = Vector3.new(CONFIG.Radius * 2, 10, CONFIG.Radius * 2)
    p.Position = pos; p.Anchored = true
    p.CanCollide = false; p.Transparency = 1
    p.Parent = Workspace
    game:GetService("Debris"):AddItem(p, 0.1)
end

local function SimulateDash()
    pcall(function()
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    end)
    task.delay(0.03, function()
        pcall(function()
            game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)
    end)
end

local function StartDashLoop()
    if dashConn then dashConn:Disconnect() dashConn = nil end
    dashConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.Mode6 or not dashHolding then return end
        local now = tick()
        if now - lastDashTime >= DASH_INTERVAL then
            lastDashTime = now
            SimulateDash()
        end
    end)
end

local function StopDashLoop()
    if dashConn then dashConn:Disconnect() dashConn = nil end
    dashHolding = false
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Q and CONFIG.Mode6 then dashHolding = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then dashHolding = false end
end)

local function CreateESP(player)
    local esp = {
        Box       = Drawing.new("Square"),
        Line      = Drawing.new("Line"),
        NameTag   = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
    }
    esp.Box.Thickness = 1; esp.Box.Color = Color3.fromRGB(255,50,50)
    esp.Box.Filled = false; esp.Box.Visible = false
    esp.Line.Thickness = 1; esp.Line.Color = Color3.fromRGB(0,255,255); esp.Line.Visible = false
    esp.NameTag.Size = 13; esp.NameTag.Color = Color3.fromRGB(255,255,255)
    esp.NameTag.Center = true; esp.NameTag.Outline = true
    esp.NameTag.OutlineColor = Color3.fromRGB(0,0,0); esp.NameTag.Visible = false
    esp.HealthBar.Thickness = 1; esp.HealthBar.Filled = true; esp.HealthBar.Visible = false
    return esp
end

local function CleanupESP(p)
    local esp = ESP_Objects[p]
    if esp then
        esp.Box:Remove(); esp.Line:Remove()
        esp.NameTag:Remove(); esp.HealthBar:Remove()
        ESP_Objects[p] = nil
    end
end

local function HideESP(esp)
    esp.Box.Visible = false; esp.NameTag.Visible = false
    esp.Line.Visible = false; esp.HealthBar.Visible = false
end

local function HideAllESP()
    for _, esp in pairs(ESP_Objects) do HideESP(esp) end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then ESP_Objects[p] = CreateESP(p) end
end
Players.PlayerAdded:Connect(function(p)    ESP_Objects[p] = CreateESP(p) end)
Players.PlayerRemoving:Connect(function(p) CleanupESP(p) end)

local fovCircle = nil
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Radius = CONFIG.SilentAimFOV
    fovCircle.Color = Color3.fromRGB(255, 60, 80)
    fovCircle.Filled = false
    fovCircle.Thickness = 1
    if fovCircle then fovCircle.Visible = false end
end)

local function RenderESP()
    if not CONFIG.Mode3 then HideAllESP() return end
    for player, esp in pairs(ESP_Objects) do
        local character = player.Character
        if not character then HideESP(esp) continue end
        local root = character:FindFirstChild("HumanoidRootPart")
        local hum  = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        if not (root and hum and head and hum.Health > 0) then HideESP(esp) continue end
        local rs, onScreen = Camera:WorldToScreenPoint(root.Position)
        local hs           = Camera:WorldToScreenPoint(head.Position)
        if not onScreen then HideESP(esp) continue end
        local height = math.max(math.abs(rs.Y - hs.Y) * 2, 10)
        local width  = height * 0.5
        local boxPos = Vector2.new(rs.X - width/2, rs.Y - height/2)
        esp.Box.Size = Vector2.new(width, height); esp.Box.Position = boxPos; esp.Box.Visible = true
        local hpR  = hum.Health / hum.MaxHealth
        local barH = height * hpR
        esp.HealthBar.Size     = Vector2.new(4, barH)
        esp.HealthBar.Position = Vector2.new(boxPos.X - 7, boxPos.Y + (height - barH))
        esp.HealthBar.Color    = Color3.fromRGB(math.floor(255*(1-hpR)), math.floor(255*hpR), 0)
        esp.HealthBar.Visible  = true
        local dist = math.floor((root.Position - LocalRoot.Position).Magnitude)
        esp.NameTag.Text     = player.Name.." ["..math.floor(hum.Health).."hp | "..dist.."m]"
        esp.NameTag.Position = Vector2.new(rs.X, boxPos.Y - 16)
        esp.NameTag.Visible  = true
        if CONFIG.Mode4 then
            local sc = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            esp.Line.From = sc; esp.Line.To = Vector2.new(rs.X, rs.Y); esp.Line.Visible = true
        else
            esp.Line.Visible = false
        end
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Ontoy_Hub"; screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

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
    Green      = Color3.fromRGB(30, 180, 80),
    GreenDim   = Color3.fromRGB(20, 100, 50),
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

local draggingWindow = false
local dragStartMouse = Vector2.zero
local dragStartPos   = UDim2.new()

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = true
        dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
        dragStartPos   = mainWindow.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingWindow and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = Vector2.new(input.Position.X, input.Position.Y) - dragStartMouse
        mainWindow.Position = UDim2.new(
            dragStartPos.X.Scale, dragStartPos.X.Offset + d.X,
            dragStartPos.Y.Scale, dragStartPos.Y.Offset + d.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingWindow = false end
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
titleText.Text                   = "ONTOY HUB  <font color='#C81E32'>·</font>  Blox Fruits"
titleText.RichText                = true
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
    btn.Size = UDim2.new(0, 26, 0, 26); btn.Position = UDim2.new(1, xOff, 0.5, -13)
    btn.BackgroundColor3 = bg; btn.Text = txt
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local closeBtn    = MakeWindowBtn(titleBar, -34, REDZ.Accent,    "✕")
local minimizeBtn = MakeWindowBtn(titleBar, -66, REDZ.ToggleOff, "—")

local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size = UDim2.new(0, 148, 1, -42); sidebar.Position = UDim2.new(0, 0, 0, 42)
sidebar.BackgroundColor3 = REDZ.BG2; sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
local sideStroke = Instance.new("UIStroke", sidebar)
sideStroke.Color = REDZ.Stroke; sideStroke.Thickness = 1
local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding = UDim.new(0, 3)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 12)

local contentArea = Instance.new("Frame", mainWindow)
contentArea.Size = UDim2.new(1, -156, 1, -50); contentArea.Position = UDim2.new(0, 152, 0, 46)
contentArea.BackgroundTransparency = 1; contentArea.BorderSizePixel = 0

local contentScroll = Instance.new("ScrollingFrame", contentArea)
contentScroll.Size = UDim2.new(1, 0, 1, 0); contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0; contentScroll.ScrollBarThickness = 3
contentScroll.ScrollBarImageColor3 = REDZ.AccentDim
contentScroll.CanvasSize = UDim2.new(0,0,0,0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local contentLayout = Instance.new("UIListLayout", contentScroll)
contentLayout.Padding = UDim.new(0, 6)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentScroll).PaddingTop = UDim.new(0, 8)

local pages = {}; local sidebarButtons = {}

local function MakePage()
    local pg = Instance.new("Frame", contentScroll)
    pg.Size = UDim2.new(1, 0, 0, 0); pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1; pg.BorderSizePixel = 0; pg.Visible = false
    local lay = Instance.new("UIListLayout", pg)
    lay.Padding = UDim.new(0, 6); lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Instance.new("UIPadding", pg).PaddingBottom = UDim.new(0, 8)
    return pg
end

local function MakeSidebarBtn(icon, label, id)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -14, 0, 38); btn.BackgroundColor3 = REDZ.ToggleOff
    btn.BackgroundTransparency = 1; btn.Text = ""; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local accentBar = Instance.new("Frame", btn)
    accentBar.Size = UDim2.new(0, 3, 0.6, 0); accentBar.Position = UDim2.new(0, 0, 0.2, 0)
    accentBar.BackgroundColor3 = REDZ.Accent; accentBar.BorderSizePixel = 0; accentBar.Visible = false
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)
    local iconL = Instance.new("TextLabel", btn)
    iconL.Size = UDim2.new(0, 22, 1, 0); iconL.Position = UDim2.new(0, 10, 0, 0)
    iconL.BackgroundTransparency = 1; iconL.Text = icon
    iconL.TextColor3 = REDZ.TextSub; iconL.Font = Enum.Font.GothamBold; iconL.TextSize = 14
    local labelL = Instance.new("TextLabel", btn)
    labelL.Size = UDim2.new(1, -38, 1, 0); labelL.Position = UDim2.new(0, 36, 0, 0)
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
    lbl.Size = UDim2.new(1, -8, 0, 18); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = REDZ.Accent
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local function MakeToggleRow(parent, label, sublabel, accentColor)
    accentColor = accentColor or REDZ.Accent
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 52); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1
    local title = Instance.new("TextLabel", row)
    title.Size = UDim2.new(1, -60, 0, 22); title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1; title.Text = label
    title.TextColor3 = REDZ.TextMain; title.Font = Enum.Font.GothamBold; title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    if sublabel then
        local sub = Instance.new("TextLabel", row)
        sub.Size = UDim2.new(1, -60, 0, 16); sub.Position = UDim2.new(0, 14, 0, 28)
        sub.BackgroundTransparency = 1; sub.Text = sublabel
        sub.TextColor3 = REDZ.TextSub; sub.Font = Enum.Font.Gotham; sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
    end
    local toggleBG = Instance.new("Frame", row)
    toggleBG.Size = UDim2.new(0, 36, 0, 20); toggleBG.Position = UDim2.new(1, -48, 0.5, -10)
    toggleBG.BackgroundColor3 = REDZ.ToggleOff; toggleBG.BorderSizePixel = 0
    Instance.new("UICorner", toggleBG).CornerRadius = UDim.new(0, 10)
    local toggleKnob = Instance.new("Frame", toggleBG)
    toggleKnob.Size = UDim2.new(0, 14, 0, 14); toggleKnob.Position = UDim2.new(0, 3, 0.5, -7)
    toggleKnob.BackgroundColor3 = REDZ.TextSub; toggleKnob.BorderSizePixel = 0
    Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(0, 7)
    local togBtn = Instance.new("TextButton", toggleBG)
    togBtn.Size = UDim2.new(1, 8, 1, 8); togBtn.Position = UDim2.new(0, -4, 0, -4)
    togBtn.BackgroundTransparency = 1; togBtn.Text = ""; togBtn.BorderSizePixel = 0
    local state = false
    local function SetState(s)
        state = s
        if s then
            toggleBG.BackgroundColor3   = accentColor
            toggleKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
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

local function MakeSliderRow(parent, label, displayMin, displayMax, initPct, unit, onChanged)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 66); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1
    local title = Instance.new("TextLabel", row)
    title.Size = UDim2.new(1, -80, 0, 20); title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1; title.Text = label
    title.TextColor3 = REDZ.TextMain; title.Font = Enum.Font.GothamBold; title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    local valLabel = Instance.new("TextLabel", row)
    valLabel.Size = UDim2.new(0, 70, 0, 20); valLabel.Position = UDim2.new(1, -78, 0, 8)
    valLabel.BackgroundTransparency = 1; valLabel.Font = Enum.Font.GothamBold; valLabel.TextSize = 12
    valLabel.TextColor3 = REDZ.AccentGlow; valLabel.TextXAlignment = Enum.TextXAlignment.Right
    local sliderBG = Instance.new("Frame", row)
    sliderBG.Size = UDim2.new(1, -28, 0, 5); sliderBG.Position = UDim2.new(0, 14, 0, 42)
    sliderBG.BackgroundColor3 = REDZ.SliderBG; sliderBG.BorderSizePixel = 0
    Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0, 3)
    local sliderHitbox = Instance.new("TextButton", sliderBG)
    sliderHitbox.Size = UDim2.new(1, 0, 0, 28); sliderHitbox.Position = UDim2.new(0, 0, 0.5, -14)
    sliderHitbox.BackgroundTransparency = 1; sliderHitbox.Text = ""
    sliderHitbox.BorderSizePixel = 0; sliderHitbox.ZIndex = 5
    local sliderFill = Instance.new("Frame", sliderBG)
    sliderFill.Size = UDim2.new(initPct, 0, 1, 0); sliderFill.BackgroundColor3 = REDZ.SliderFill
    sliderFill.BorderSizePixel = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 3)
    local fillGlow = Instance.new("Frame", sliderFill)
    fillGlow.Size = UDim2.new(0, 6, 0, 6); fillGlow.Position = UDim2.new(1, -3, 0.5, -3)
    fillGlow.BackgroundColor3 = REDZ.AccentGlow; fillGlow.BorderSizePixel = 0
    Instance.new("UICorner", fillGlow).CornerRadius = UDim.new(0, 3)
    local knob = Instance.new("Frame", sliderBG)
    knob.Size = UDim2.new(0, 14, 0, 14); knob.Position = UDim2.new(initPct, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 7)
    local knobRing = Instance.new("UIStroke", knob)
    knobRing.Color = REDZ.Accent; knobRing.Thickness = 2
    local dragging = false
    local function Compute(px)
        local bg = sliderBG.AbsolutePosition.X; local bw = sliderBG.AbsoluteSize.X
        local pct = math.clamp((px - bg) / bw, 0, 1)
        return pct, math.floor(displayMin + (displayMax - displayMin) * pct)
    end
    local function Apply(pct, val)
        sliderFill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, -7, 0.5, -7)
        valLabel.Text = val .. (unit or "")
        if onChanged then onChanged(val, pct) end
    end
    Apply(initPct, math.floor(displayMin + (displayMax - displayMin) * initPct))
    sliderHitbox.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            local p, v = Compute(input.Position.X); Apply(p, v)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    sliderHitbox.MouseButton1Click:Connect(function()
        local mouse = UserInputService:GetMouseLocation()
        local p, v = Compute(mouse.X); Apply(p, v)
    end)
    return row
end

local combatPage = MakePage(); pages["combat"] = combatPage
local combatBtn  = MakeSidebarBtn("⚔", "Combat", "combat")

MakeSectionLabel(combatPage, "HITBOX")
local _, hbGet, _      = MakeToggleRow(combatPage, "Hitbox Expand", "Expand LocalRoot hitbox size")
MakeSliderRow(combatPage, "Hitbox Size", 1, 100, 0.0, "%", function(val) CONFIG.HitboxPercent = val end)

MakeSectionLabel(combatPage, "COMBAT")
local _, hbSpamGet, _  = MakeToggleRow(combatPage, "Hitbox Spam",  "Spawn hitbox parts at position")
local _, dashGet, _    = MakeToggleRow(combatPage, "Dash Spam",    "Hold Q — auto dash no delay")

MakeSectionLabel(combatPage, "SILENT AIM")
local _, silentGet, _  = MakeToggleRow(combatPage, "Silent Aim",   "Kamera redirect ke target — semua jurus kena")
MakeSliderRow(combatPage, "Silent Aim FOV", 30, 300, (CONFIG.SilentAimFOV-30)/270, " px", function(val)
    CONFIG.SilentAimFOV = val
    if fovCircle then fovCircle.Radius = val end
end)

MakeSectionLabel(combatPage, "FAST ATTACK")
local _, fastAtkGet, _ = MakeToggleRow(combatPage, "Fast Attack",  "FireServer RegisterAttack tanpa delay animasi")
MakeSliderRow(combatPage, "Attack HPS", 1, 30, (CONFIG.AttackHPS-1)/29, " HPS", function(val) CONFIG.AttackHPS = val end)

local visualPage = MakePage(); pages["visual"] = visualPage
local visualBtn  = MakeSidebarBtn("👁", "Visual", "visual")
MakeSectionLabel(visualPage, "ESP")
local _, espGet, _     = MakeToggleRow(visualPage, "ESP",     "Player boxes, health, distance")
local _, tracerGet, _  = MakeToggleRow(visualPage, "Tracers", "Lines from screen to players")

local movePage  = MakePage(); pages["movement"] = movePage
local moveBtn   = MakeSidebarBtn("🏃", "Movement", "movement")
MakeSectionLabel(movePage, "SPEED")
local _, speedGet, _ = MakeToggleRow(movePage, "Fast Run", "Override WalkSpeed every frame")
MakeSliderRow(movePage, "Speed", BASE_SPEED, MAX_SPEED, 0.5, " ws", function(val, pct)
    CONFIG.SpeedPercent = pct * 100
end)

local farmPage = MakePage(); pages["farm"] = farmPage
local farmBtn  = MakeSidebarBtn("🌾", "Auto Farm", "farm")

local statusCard = Instance.new("Frame", farmPage)
statusCard.Size = UDim2.new(1, -8, 0, 52); statusCard.BackgroundColor3 = REDZ.BG2
statusCard.BorderSizePixel = 0
Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 8)
local statusStroke = Instance.new("UIStroke", statusCard)
statusStroke.Color = REDZ.Stroke; statusStroke.Thickness = 1

local statusIcon = Instance.new("TextLabel", statusCard)
statusIcon.Size = UDim2.new(0, 20, 1, 0); statusIcon.Position = UDim2.new(0, 12, 0, 0)
statusIcon.BackgroundTransparency = 1; statusIcon.Text = "○"
statusIcon.TextColor3 = REDZ.TextSub; statusIcon.Font = Enum.Font.GothamBold; statusIcon.TextSize = 14

local statusTitle = Instance.new("TextLabel", statusCard)
statusTitle.Size = UDim2.new(1, -60, 0, 20); statusTitle.Position = UDim2.new(0, 36, 0, 6)
statusTitle.BackgroundTransparency = 1; statusTitle.Text = "AUTO FARM"
statusTitle.TextColor3 = REDZ.TextSub; statusTitle.Font = Enum.Font.GothamBold; statusTitle.TextSize = 10
statusTitle.TextXAlignment = Enum.TextXAlignment.Left

local statusText = Instance.new("TextLabel", statusCard)
statusText.Size = UDim2.new(1, -60, 0, 18); statusText.Position = UDim2.new(0, 36, 0, 26)
statusText.BackgroundTransparency = 1; statusText.Text = "Idle"
statusText.TextColor3 = REDZ.TextMain; statusText.Font = Enum.Font.Gotham; statusText.TextSize = 11
statusText.TextXAlignment = Enum.TextXAlignment.Left

local levelCard = Instance.new("Frame", farmPage)
levelCard.Size = UDim2.new(1, -8, 0, 52); levelCard.BackgroundColor3 = REDZ.BG2
levelCard.BorderSizePixel = 0
Instance.new("UICorner", levelCard).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", levelCard).Color = REDZ.Stroke

local levelText = Instance.new("TextLabel", levelCard)
levelText.Size = UDim2.new(1, -16, 1, 0); levelText.Position = UDim2.new(0, 12, 0, 0)
levelText.BackgroundTransparency = 1
levelText.Text = "Level: — | Island: — | Target: —"
levelText.TextColor3 = REDZ.TextSub; levelText.Font = Enum.Font.Gotham; levelText.TextSize = 11
levelText.TextXAlignment = Enum.TextXAlignment.Left
levelText.TextWrapped = true

MakeSectionLabel(farmPage, "MAIN")
local _, farmGet, farmSet = MakeToggleRow(farmPage, "Auto Farm",
    "Detect level → fly ke NPC → quest → hover attack", REDZ.Green)

MakeSectionLabel(farmPage, "SETTINGS")
local _, noclipGet, _ = MakeToggleRow(farmPage, "Noclip", "CanCollide = false saat farm aktif")

MakeSliderRow(farmPage, "Fly Speed", 50, 700, (CONFIG.FarmFlySpeed-50)/650, " stud/s",
    function(val) CONFIG.FarmFlySpeed = val end)

MakeSliderRow(farmPage, "Hover Height", 2, 20, (CONFIG.FarmHoverHeight-2)/18, " stud",
    function(val) CONFIG.FarmHoverHeight = val end)

RunService.Heartbeat:Connect(function()
    local farmData, level = GetFarmData()
    if CONFIG.Mode9 then
        statusIcon.TextColor3       = REDZ.Green
        statusIcon.Text             = "●"
        statusTitle.TextColor3      = REDZ.Green
        statusCard.BackgroundColor3 = Color3.fromRGB(12, 22, 14)
        statusStroke.Color          = REDZ.GreenDim
    else
        statusIcon.TextColor3       = REDZ.TextSub
        statusIcon.Text             = "○"
        statusTitle.TextColor3      = REDZ.TextSub
        statusCard.BackgroundColor3 = REDZ.BG2
        statusStroke.Color          = REDZ.Stroke
    end
    statusText.Text = farmStatus
    if farmData then
        levelText.Text = ("Lv %d  |  Sea %d  |  %s  |  Target: %s  [Lv %d-%d]"):format(
            level or 0, farmData.Sea or 1, farmData.Island, farmData.MobName, farmData.MinLvl, farmData.MaxLvl)
    else
        levelText.Text = ("Lv %d  |  Data tidak ditemukan"):format(level or 0)
    end
end)

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

WireToggle(hbGet,      "Mode1", nil, RestoreHitbox)
WireToggle(hbSpamGet,  "Mode2")
WireToggle(espGet,     "Mode3", nil, HideAllESP)
WireToggle(tracerGet,  "Mode4", nil, function()
    for _, esp in pairs(ESP_Objects) do esp.Line.Visible = false end
end)
WireToggle(speedGet,   "Mode5", nil, function() LocalHumanoid.WalkSpeed = BASE_SPEED end)
WireToggle(dashGet,    "Mode6", StartDashLoop, StopDashLoop)
WireToggle(silentGet,  "Mode7", nil, function()
    silentTarget = nil
    if fovCircle then fovCircle.Visible = false end
end)
WireToggle(fastAtkGet, "Mode8", StartFastAttack, StopFastAttack)
WireToggle(farmGet,    "Mode9",
    function() StartNoclip() StartFarm() farmStatus = "Starting..." end,
    function() StopFarm() farmStatus = "Idle" end
)
WireToggle(noclipGet, "Mode10",
    function() if not CONFIG.Mode9 then StartNoclip() end end,
    function() if not CONFIG.Mode9 then StopNoclip()  end end
)

combatBtn.MouseButton1Click:Connect(function() SetActivePage("combat")   end)
visualBtn.MouseButton1Click:Connect(function() SetActivePage("visual")   end)
moveBtn.MouseButton1Click:Connect(function()   SetActivePage("movement") end)
farmBtn.MouseButton1Click:Connect(function()   SetActivePage("farm")     end)
SetActivePage("combat")

local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
    contentVisible = not contentVisible
    sidebar.Visible = contentVisible; contentArea.Visible = contentVisible
    mainWindow.Size = contentVisible and UDim2.new(0, 580, 0, 400) or UDim2.new(0, 580, 0, 42)
end)

closeBtn.MouseButton1Click:Connect(function()
    RestoreHitbox(); LocalHumanoid.WalkSpeed = BASE_SPEED
    HideAllESP(); StopDashLoop(); StopFastAttack(); StopFarm()
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    screenGui:Destroy()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot      = char:WaitForChild("HumanoidRootPart")
    LocalHumanoid  = char:WaitForChild("Humanoid")
    OriginalLocalSize = nil; dashHolding = false; silentTarget = nil
    if CONFIG.Mode9 then
        farmState      = FARM_STATE.GO_QUEST
        waitingFly     = false
        waitSpawnTimer = 0
        farmStatus     = "Respawned — restarting"
    end
    if CONFIG.Mode5 then LocalHumanoid.WalkSpeed = GetTargetSpeed() end
end)

RunService.RenderStepped:Connect(function()
    if CONFIG.Mode1 then ExpandHitbox() end
    if CONFIG.Mode2 and LocalRoot then Mode2Func(LocalRoot.Position) end
    if CONFIG.Mode5 then LocalHumanoid.WalkSpeed = GetTargetSpeed() end
    if CONFIG.Mode7 then
        ApplySilentAim()
        local vp = Camera.ViewportSize
        if fovCircle then
            fovCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
            fovCircle.Radius   = CONFIG.SilentAimFOV
            fovCircle.Visible  = true
        end
    else
        if fovCircle then fovCircle.Visible = false end
    end
    RenderESP()
end)
