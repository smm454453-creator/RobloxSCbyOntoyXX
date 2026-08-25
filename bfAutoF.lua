-- ==========================================================
-- BLOX FRUITS SILENT AIM / AUTO AIM SKILL (XENO SUPPORT)
-- BY ONTOY HUB — FIXED BY AXIOM
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

getgenv().SilentAim = {
    Enabled = true,
    FOV = 250,
    ShowFOV = true,
    TargetPart = "HumanoidRootPart",
    ToggleKey = Enum.KeyCode.RightControl
}

-- FOV Circle — untouched, works fine
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

-- Closest target in FOV — untouched logic, your version was correct
local function GetClosestTarget()
    local closestPlayer = nil
    local shortestDistance = getgenv().SilentAim.FOV

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer
            and plr.Character
            and plr.Character:FindFirstChild("Humanoid")
            and plr.Character.Humanoid.Health > 0
        then
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

-- Returns the locked CFrame aimed at the target's part
-- Used by both __index hook and camera redirect
local function GetTargetCFrame()
    local target = GetClosestTarget()
    if target and target.Character then
        local part = target.Character:FindFirstChild(getgenv().SilentAim.TargetPart)
        if part then
            return part.CFrame
        end
    end
    return nil
end

-- __index hook — same as before but also catches "lookVector" style reads
-- Blox Fruits skills read Mouse.Hit for projectile origin CFrame
local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
    if getgenv().SilentAim.Enabled and not checkcaller() then
        local idx = tostring(index):lower()

        -- Mouse.Hit / Mouse.Target interception (original, kept)
        if self == Mouse then
            if idx == "hit" then
                local cf = GetTargetCFrame()
                if cf then return cf end
            elseif idx == "target" then
                local target = GetClosestTarget()
                if target and target.Character then
                    local part = target.Character:FindFirstChild(getgenv().SilentAim.TargetPart)
                    if part then return part end
                end
            end
        end

        -- Camera.CFrame interception — catches skills that aim off camera LookVector
        -- Blox Fruits sword skills (X, Z) source their direction from Camera.CFrame
        if self == Camera and idx == "cframe" then
            local cf = GetTargetCFrame()
            if cf then
                -- Point camera CFrame toward the target, keep camera position fixed
                -- so the world doesn't snap — only the aim direction changes
                local origin = oldIndex(Camera, "CFrame").Position
                local targetPos = cf.Position
                return CFrame.lookAt(origin, targetPos)
            end
        end
    end

    return oldIndex(self, index)
end))

-- Toggle key — untouched
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == getgenv().SilentAim.ToggleKey then
        getgenv().SilentAim.Enabled = not getgenv().SilentAim.Enabled
        print("[Ontoy Hub] Silent Aim Status:", getgenv().SilentAim.Enabled)
    end
end)
