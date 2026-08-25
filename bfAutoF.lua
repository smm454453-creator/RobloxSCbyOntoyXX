-- ==========================================================
-- BLOX FRUITS SILENT AIM / AUTO AIM SKILL (XENO SUPPORT)
-- BY ONTOY HUB
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- SETTINGAN UTAMA
getgenv().SilentAim = {
    Enabled = true,              -- Status fitur (true / false)
    FOV = 250,                   -- Jarak/Radius area kunci musuh (dalam pixel)
    ShowFOV = true,              -- Nampilin lingkaran FOV merah
    TargetPart = "HumanoidRootPart", -- "Head" atau "HumanoidRootPart"
    ToggleKey = Enum.KeyCode.RightControl -- Tombol buat On/Off script (Ctrl Kanan)
}

-- Bikin Lingkaran FOV (Biar Kelihatan Musuh yang Masuk Target)
local Circle = Drawing.new("Circle")
Circle.Thickness = 1.5
Circle.Color = Color3.fromRGB(255, 60, 60)
Circle.Filled = false
Circle.Transparency = 1
Circle.NumSides = 64
Circle.Radius = getgenv().SilentAim.FOV
Circle.Visible = getgenv().SilentAim.ShowFOV

RunService.RenderStepped:Connect(function()
    Circle.Position = UserInputService:GetMouseLocation()
    Circle.Radius = getgenv().SilentAim.FOV
    Circle.Visible = getgenv().SilentAim.ShowFOV and getgenv().SilentAim.Enabled
end)

-- Fungsi Cari Player Terdekat di Dalam FOV
local function GetClosestTarget()
    local closestPlayer = nil
    local shortestDistance = getgenv().SilentAim.FOV

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local targetPart = plr.Character:FindFirstChild(getgenv().SilentAim.TargetPart)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestPlayer = plr
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Hook Metamethod __index (Inti dari Silent Aim Skill)
local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
    if getgenv().SilentAim.Enabled and not checkcaller() and self == Mouse then
        local idx = tostring(index):lower()
        if idx == "hit" or idx == "target" then
            local target = GetClosestTarget()
            if target and target.Character and target.Character:FindFirstChild(getgenv().SilentAim.TargetPart) then
                local targetPart = target.Character[getgenv().SilentAim.TargetPart]
                if idx == "hit" then
                    return targetPart.CFrame
                elseif idx == "target" then
                    return targetPart
                end
            end
        end
    end
    return oldIndex(self, index)
end))

-- Shortcut On/Off (Default: RCtrl)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == getgenv().SilentAim.ToggleKey then
        getgenv().SilentAim.Enabled = not getgenv().SilentAim.Enabled
        print("[Ontoy Hub] Silent Aim Status:", getgenv().SilentAim.Enabled)
    end
end)
