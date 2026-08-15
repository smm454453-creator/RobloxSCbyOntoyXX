local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")

local CONFIG = {
    Mode1 = false,
    Mode2 = false,
    Mode3 = false,
    Mode4 = false,
    Radius = 15,
    Jarak = 100,
}

local LockedTarget = nil
local ESP_Objects = {}

local function GetClosestToCursor()
    local closestPlayer = nil
    local closestDistance = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if root and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToScreenPoint(root.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < closestDistance then
                        closestDistance = dist
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end

local function GetClosestToBody()
    local closest = nil
    local shortestDistance = CONFIG.Jarak
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if root and humanoid and humanoid.Health > 0 then
                local distance = (root.Position - LocalRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closest = player
                end
            end
        end
    end
    return closest
end

local function Mode1Func()
    if not LockedTarget then return end
    local character = LockedTarget.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        LockedTarget = nil
        return
    end

    LocalRoot.CFrame = CFrame.new(
        LocalRoot.Position,
        Vector3.new(root.Position.X, LocalRoot.Position.Y, root.Position.Z)
    )

    Camera.CFrame = CFrame.new(Camera.CFrame.Position, root.Position)
end

local function Mode2Func(centerPosition)
    local hitboxPart = Instance.new("Part")
    hitboxPart.Name = "Ontoy_Part"
    hitboxPart.Size = Vector3.new(CONFIG.Radius * 2, 10, CONFIG.Radius * 2)
    hitboxPart.Position = centerPosition
    hitboxPart.Anchored = true
    hitboxPart.CanCollide = false
    hitboxPart.Transparency = 1
    hitboxPart.Parent = Workspace
    game:GetService("Debris"):AddItem(hitboxPart, 0.1)
end

local function CreateESP(player)
    local esp = {
        Box = Drawing.new("Square"),
        Line = Drawing.new("Line"),
        NameTag = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
    }

    esp.Box.Thickness = 1
    esp.Box.Color = Color3.fromRGB(255, 50, 50)
    esp.Box.Filled = false
    esp.Box.Visible = false

    esp.Line.Thickness = 1
    esp.Line.Color = Color3.fromRGB(0, 255, 255)
    esp.Line.Visible = false

    esp.NameTag.Size = 13
    esp.NameTag.Color = Color3.fromRGB(255, 255, 255)
    esp.NameTag.Center = true
    esp.NameTag.Outline = true
    esp.NameTag.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.NameTag.Visible = false

    esp.HealthBar.Thickness = 1
    esp.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.Filled = true
    esp.HealthBar.Visible = false

    return esp
end

local function CleanupESP(player)
    local esp = ESP_Objects[player]
    if esp then
        esp.Box:Remove()
        esp.Line:Remove()
        esp.NameTag:Remove()
        esp.HealthBar:Remove()
        ESP_Objects[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        ESP_Objects[player] = CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    ESP_Objects[player] = CreateESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if player == LockedTarget then LockedTarget = nil end
    CleanupESP(player)
end)

local function HideESP(esp)
    esp.Box.Visible = false
    esp.NameTag.Visible = false
    esp.Line.Visible = false
    esp.HealthBar.Visible = false
end

local function RenderESP()
    for player, esp in pairs(ESP_Objects) do
        local character = player.Character
        if not character or not CONFIG.Mode3 then
            HideESP(esp)
        else
            local root = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChild("Humanoid")
            local head = character:FindFirstChild("Head")

            if root and humanoid and head and humanoid.Health > 0 then
                local rootScreen, onScreen = Camera:WorldToScreenPoint(root.Position)
                local headScreen = Camera:WorldToScreenPoint(head.Position)

                if onScreen then
                    local height = math.abs(rootScreen.Y - headScreen.Y) * 2
                    if height < 10 then height = 10 end
                    local width = height * 0.5
                    local boxPos = Vector2.new(rootScreen.X - width / 2, rootScreen.Y - height / 2)

                    local isLocked = (player == LockedTarget)
                    esp.Box.Color = isLocked and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
                    esp.Box.Thickness = isLocked and 2 or 1
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = boxPos
                    esp.Box.Visible = true

                    local hpRatio = humanoid.Health / humanoid.MaxHealth
                    local barHeight = height * hpRatio
                    local barColor = Color3.fromRGB(
                        math.floor(255 * (1 - hpRatio)),
                        math.floor(255 * hpRatio),
                        0
                    )
                    esp.HealthBar.Size = Vector2.new(4, barHeight)
                    esp.HealthBar.Position = Vector2.new(boxPos.X - 7, boxPos.Y + (height - barHeight))
                    esp.HealthBar.Color = barColor
                    esp.HealthBar.Visible = true

                    local dist = math.floor((root.Position - LocalRoot.Position).Magnitude)
                    esp.NameTag.Text = player.Name .. " [" .. math.floor(humanoid.Health) .. "hp | " .. dist .. "m]"
                    esp.NameTag.Position = Vector2.new(rootScreen.X, boxPos.Y - 16)
                    esp.NameTag.Visible = true

                    if CONFIG.Mode4 then
                        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        esp.Line.From = screenCenter
                        esp.Line.To = Vector2.new(rootScreen.X, rootScreen.Y)
                        esp.Line.Color = isLocked and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(0, 255, 255)
                        esp.Line.Visible = true
                    else
                        esp.Line.Visible = false
                    end
                else
                    HideESP(esp)
                end
            else
                HideESP(esp)
            end
        end
    end
end

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Ontoy_Stress"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local outerFrame = Instance.new("Frame")
outerFrame.Size = UDim2.new(0, 110, 0, 30)
outerFrame.Position = UDim2.new(0, 10, 0, 10)
outerFrame.BackgroundTransparency = 1
outerFrame.Active = true
outerFrame.Draggable = true
outerFrame.Parent = screenGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, 0, 1, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
toggleButton.Text = "☰ Ontoy"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 12
toggleButton.BorderSizePixel = 0
toggleButton.Parent = outerFrame

local UICornerToggle = Instance.new("UICorner")
UICornerToggle.CornerRadius = UDim.new(0, 6)
UICornerToggle.Parent = toggleButton

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 280)
mainFrame.Position = UDim2.new(0, 10, 0, 48)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local UICornerMain = Instance.new("UICorner")
UICornerMain.CornerRadius = UDim.new(0, 10)
UICornerMain.Parent = mainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 80)
UIStroke.Thickness = 1
UIStroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local UICornerTitle = Instance.new("UICorner")
UICornerTitle.CornerRadius = UDim.new(0, 10)
UICornerTitle.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Ontoy Stress"
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -32, 0, 4)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 11
closeButton.BorderSizePixel = 0
closeButton.Parent = titleBar

local UICornerClose = Instance.new("UICorner")
UICornerClose.CornerRadius = UDim.new(0, 6)
UICornerClose.Parent = closeButton

local lockLabel = Instance.new("TextLabel")
lockLabel.Size = UDim2.new(1, -20, 0, 18)
lockLabel.Position = UDim2.new(0, 10, 0, 42)
lockLabel.BackgroundTransparency = 1
lockLabel.Text = "TARGET: none"
lockLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
lockLabel.Font = Enum.Font.Gotham
lockLabel.TextSize = 11
lockLabel.TextXAlignment = Enum.TextXAlignment.Left
lockLabel.Parent = mainFrame

local function MakeButton(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = "◻  " .. text
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = mainFrame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    return btn
end

local mode1Button = MakeButton("MODE 1  —  Body Lock", 68)
local mode2Button = MakeButton("MODE 2  —  Hitbox", 108)
local mode3Button = MakeButton("MODE 3  —  ESP", 148)
local mode4Button = MakeButton("MODE 4  —  Tracers", 188)

local selectButton = Instance.new("TextButton")
selectButton.Size = UDim2.new(1, -20, 0, 28)
selectButton.Position = UDim2.new(0, 10, 0, 242)
selectButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
selectButton.Text = "🎯  Select Target"
selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
selectButton.Font = Enum.Font.GothamBold
selectButton.TextSize = 11
selectButton.BorderSizePixel = 0
selectButton.Parent = mainFrame
local UICornerSel = Instance.new("UICorner")
UICornerSel.CornerRadius = UDim.new(0, 6)
UICornerSel.Parent = selectButton

local function SetToggle(btn, state, label)
    if state then
        btn.Text = "◼  " .. label
        btn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        btn.Text = "◻  " .. label
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    end
end

toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

selectButton.MouseButton1Click:Connect(function()
    local target = GetClosestToCursor()
    if target then
        LockedTarget = target
        lockLabel.Text = "TARGET: " .. target.Name
        lockLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        LockedTarget = nil
        lockLabel.Text = "TARGET: none"
        lockLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    end
end)

mode1Button.MouseButton1Click:Connect(function()
    CONFIG.Mode1 = not CONFIG.Mode1
    SetToggle(mode1Button, CONFIG.Mode1, "MODE 1  —  Body Lock")
    if not CONFIG.Mode1 then
        LockedTarget = nil
        lockLabel.Text = "TARGET: none"
        lockLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    end
end)

mode2Button.MouseButton1Click:Connect(function()
    CONFIG.Mode2 = not CONFIG.Mode2
    SetToggle(mode2Button, CONFIG.Mode2, "MODE 2  —  Hitbox")
end)

mode3Button.MouseButton1Click:Connect(function()
    CONFIG.Mode3 = not CONFIG.Mode3
    SetToggle(mode3Button, CONFIG.Mode3, "MODE 3  —  ESP")
    if not CONFIG.Mode3 then
        CONFIG.Mode4 = false
        SetToggle(mode4Button, false, "MODE 4  —  Tracers")
    end
end)

mode4Button.MouseButton1Click:Connect(function()
    if not CONFIG.Mode3 then
        CONFIG.Mode3 = true
        SetToggle(mode3Button, true, "MODE 3  —  ESP")
    end
    CONFIG.Mode4 = not CONFIG.Mode4
    SetToggle(mode4Button, CONFIG.Mode4, "MODE 4  —  Tracers")
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot = char:WaitForChild("HumanoidRootPart")
end)

RunService.RenderStepped:Connect(function()
    if CONFIG.Mode1 and LocalRoot then
        Mode1Func()
    end
    if CONFIG.Mode2 and LocalRoot then
        Mode2Func(LocalRoot.Position)
    end
    if CONFIG.Mode3 then
        RenderESP()
    end

    if LockedTarget then
        local char = LockedTarget.Character
        if not char then
            LockedTarget = nil
            lockLabel.Text = "TARGET: none"
            lockLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
        else
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health <= 0 then
                LockedTarget = nil
                lockLabel.Text = "TARGET: none"
                lockLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
            end
        end
    end
end)