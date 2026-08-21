local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- CONFIG STATE
local CONFIG = {
    FastRun = false, RunSpeed = 50,
    HighJump = false, JumpPower = 100,
    ESP = false,
    Aimbot = false,
    FOVChanger = false, FOVValue = 90,
    GunMods = false -- No Recoil & Inf Ammo (Eksperimental)
}

-- 1. MOVEMENT & FOV
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if CONFIG.FastRun then hum.WalkSpeed = CONFIG.RunSpeed end
        if CONFIG.HighJump then
            hum.UseJumpPower = true
            hum.JumpPower = CONFIG.JumpPower
        end
    end
    if CONFIG.FOVChanger then
        Camera.FieldOfView = CONFIG.FOVValue
    end
end)

-- 2. BASIC AIMBOT (Closest to Mouse)
local function GetClosestPlayer()
    local closest, maxDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < maxDist then maxDist = dist; closest = plr.Character.Head end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if CONFIG.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

-- 3. ESP SYSTEM
local playerESP = {}
local function NewText(size, color)
    local t = Drawing.new("Text"); t.Size = size; t.Center = true; t.Outline = true
    t.Color = color; t.Visible = false; t.Font = Drawing.Fonts.Plex; return t
end
local function NewBox(color)
    local b = Drawing.new("Square"); b.Thickness = 1.5; b.Filled = false
    b.Color = color; b.Visible = false; return b
end
local function CreateESP()
    return { name = NewText(13, Color3.new(1,1,1)), box = NewBox(Color3.new(1,0,0)), hp = NewText(11, Color3.new(0,1,0)) }
end

RunService.RenderStepped:Connect(function()
    for plr, d in pairs(playerESP) do
        if not plr or not plr.Parent then d.name:Remove(); d.box:Remove(); d.hp:Remove(); playerESP[plr] = nil end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not playerESP[plr] then playerESP[plr] = CreateESP() end
    end
    for plr, d in pairs(playerESP) do
        if not CONFIG.ESP or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            d.name.Visible = false; d.box.Visible = false; d.hp.Visible = false; continue
        end
        local root = plr.Character.HumanoidRootPart
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        local sc, on = Camera:WorldToScreenPoint(root.Position)
        if on then
            local dist = (root.Position - Camera.CFrame.Position).Magnitude
            local h = math.clamp(1000/dist, 20, 1000); local w = h * 0.5
            d.box.Size = Vector2.new(w, h); d.box.Position = Vector2.new(sc.X - w/2, sc.Y - h/2); d.box.Visible = true
            d.name.Text = plr.DisplayName; d.name.Position = Vector2.new(sc.X, sc.Y - h/2 - 15); d.name.Visible = true
            if hum then d.hp.Text = math.floor(hum.Health).." HP"; d.hp.Position = Vector2.new(sc.X, sc.Y + h/2 + 2); d.hp.Visible = true end
        else
            d.name.Visible = false; d.box.Visible = false; d.hp.Visible = false
        end
    end
end)

-- 4. WEAPON MODS (Universal Loop)
task.spawn(function()
    while task.wait(1) do
        if CONFIG.GunMods and LocalPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                for _, v in ipairs(tool:GetDescendants()) do
                    if v:IsA("ValueBase") then
                        local n = v.Name:lower()
                        if n:find("ammo") then v.Value = 999 end
                        if n:find("recoil") or n:find("spread") then v.Value = 0 end
                    end
                end
            end
        end
    end
end)

-- 5. GUI CONSTRUCTION (Ontoy Hub)
local sg = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
sg.ResetOnSpawn = false

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0,500,0,380); main.Position = UDim2.new(0.5,-250,0.5,-190)
main.BackgroundColor3 = Color3.fromRGB(14,12,16)
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", main).Color = Color3.fromRGB(60,30,40)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1,0,0,40); title.BackgroundColor3 = Color3.fromRGB(20,16,22)
title.Text = "  ONTOY HUB · Hypershot"; title.TextColor3 = Color3.fromRGB(240,220,225)
title.Font = Enum.Font.GothamBold; title.TextSize = 13; title.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", title).CornerRadius = UDim.new(0,10)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then main.Visible = not main.Visible end
end)

local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1,-20,1,-50); scroll.Position = UDim2.new(0,10,0,45)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 2
local lay = Instance.new("UIListLayout", scroll); lay.Padding = UDim.new(0,5)

local function MakeToggle(label, key)
    local btn = Instance.new("TextButton", scroll)
    btn.Size = UDim2.new(1,0,0,35); btn.BackgroundColor3 = Color3.fromRGB(20,16,22)
    btn.Text = "  [OFF] " .. label; btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        btn.Text = (CONFIG[key] and "  [ON] " or "  [OFF] ") .. label
        btn.TextColor3 = CONFIG[key] and Color3.fromRGB(255,60,80) or Color3.fromRGB(200,200,200)
    end)
end

MakeToggle("Fast Run (50 WS)", "FastRun")
MakeToggle("High Jump (100 JP)", "HighJump")
MakeToggle("Aimbot (Tahan Klik Kanan)", "Aimbot")
MakeToggle("ESP Player (Box, Name, HP)", "ESP")
MakeToggle("FOV Changer (90)", "FOVChanger")
MakeToggle("Gun Mods (No Recoil & Inf Ammo)", "GunMods")
