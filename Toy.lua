local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

local CONFIG = {
    Mode1 = false,
    Mode2 = false,
    Mode3 = false,
    Mode4 = false,
    Mode5 = false,
    Mode6 = false,
    Radius = 15,
    HitboxSize = 20,
    SpeedPercent = 50,
}

local BASE_SPEED = 16
local MAX_SPEED = 500
local DASH_INTERVAL = 0.05

local OriginalLocalSize = nil
local ESP_Objects = {}
local lastDashTime = 0
local dashHolding = false

local function ExpandHitbox()
    if not OriginalLocalSize then
        OriginalLocalSize = LocalRoot.Size
    end
    LocalRoot.Size = Vector3.new(CONFIG.HitboxSize, CONFIG.HitboxSize, CONFIG.HitboxSize)
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

local function HideESP(esp)
    esp.Box.Visible = false
    esp.NameTag.Visible = false
    esp.Line.Visible = false
    esp.HealthBar.Visible = false
end

local function HideAllESP()
    for _, esp in pairs(ESP_Objects) do
        HideESP(esp)
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
    CleanupESP(player)
end)

local function RenderESP()
    if not CONFIG.Mode3 then
        HideAllESP()
        return
    end
    for player, esp in pairs(ESP_Objects) do
        local character = player.Character
        if not character then HideESP(esp) continue end
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        if not (root and humanoid and head and humanoid.Health > 0) then
            HideESP(esp) continue
        end
        local rootScreen, onScreen = Camera:WorldToScreenPoint(root.Position)
        local headScreen = Camera:WorldToScreenPoint(head.Position)
        if not onScreen then HideESP(esp) continue end

        local height = math.abs(rootScreen.Y - headScreen.Y) * 2
        if height < 10 then height = 10 end
        local width = height * 0.5
        local boxPos = Vector2.new(rootScreen.X - width / 2, rootScreen.Y - height / 2)

        esp.Box.Color = Color3.fromRGB(255, 50, 50)
        esp.Box.Thickness = 1
        esp.Box.Size = Vector2.new(width, height)
        esp.Box.Position = boxPos
        esp.Box.Visible = true

        local hpRatio = humanoid.Health / humanoid.MaxHealth
        local barHeight = height * hpRatio
        esp.HealthBar.Size = Vector2.new(4, barHeight)
        esp.HealthBar.Position = Vector2.new(boxPos.X - 7, boxPos.Y + (height - barHeight))
        esp.HealthBar.Color = Color3.fromRGB(
            math.floor(255 * (1 - hpRatio)),
            math.floor(255 * hpRatio),
            0
        )
        esp.HealthBar.Visible = true

        local dist = math.floor((root.Position - LocalRoot.Position).Magnitude)
        esp.NameTag.Text = player.Name .. " [" .. math.floor(humanoid.Health) .. "hp | " .. dist .. "m]"
        esp.NameTag.Position = Vector2.new(rootScreen.X, boxPos.Y - 16)
        esp.NameTag.Visible = true

        if CONFIG.Mode4 then
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            esp.Line.From = screenCenter
            esp.Line.To = Vector2.new(rootScreen.X, rootScreen.Y)
            esp.Line.Color = Color3.fromRGB(0, 255, 255)
            esp.Line.Visible = true
        else
            esp.Line.Visible = false
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
local c0 = Instance.new("UICorner")
c0.CornerRadius = UDim.new(0, 6)
c0.Parent = toggleButton

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 230, 0, 470)
mainFrame.Position = UDim2.new(0, 10, 0, 48)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui
local c1 = Instance.new("UICorner")
c1.CornerRadius = UDim.new(0, 10)
c1.Parent = mainFrame
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 80)
stroke.Thickness = 1
stroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
local c2 = Instance.new("UICorner")
c2.CornerRadius = UDim.new(0, 10)
c2.Parent = titleBar

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
local c3 = Instance.new("UICorner")
c3.CornerRadius = UDim.new(0, 6)
c3.Parent = closeButton

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

local mode1Button = MakeButton("MODE 1  —  Hitbox Expand", 44)
local mode2Button = MakeButton("MODE 2  —  Hitbox Spam", 82)
local mode3Button = MakeButton("MODE 3  —  ESP", 120)
local mode4Button = MakeButton("MODE 4  —  Tracers", 158)
local mode5Button = MakeButton("MODE 5  —  Fast Run", 196)

-- Speed slider
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 14)
speedLabel.Position = UDim2.new(0, 10, 0, 234)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "SPEED: 50%"
speedLabel.TextColor3 = Color3.fromRGB(160, 160, 200)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 10
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = mainFrame

local sliderBG = Instance.new("Frame")
sliderBG.Size = UDim2.new(1, -20, 0, 10)
sliderBG.Position = UDim2.new(0, 10, 0, 252)
sliderBG.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
sliderBG.BorderSizePixel = 0
sliderBG.Parent = mainFrame
local sliderBGCorner = Instance.new("UICorner")
sliderBGCorner.CornerRadius = UDim.new(0, 5)
sliderBGCorner.Parent = sliderBG

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBG
local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(0, 5)
sliderFillCorner.Parent = sliderFill

local mode6Button = MakeButton("MODE 6  —  Dash Spam  [hold Q]", 272)

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

local sliderDragging = false

local function UpdateSlider(inputX)
    local bgPos = sliderBG.AbsolutePosition.X
    local bgSize = sliderBG.AbsoluteSize.X
    local pct = math.clamp((inputX - bgPos) / bgSize, 0, 1)
    CONFIG.SpeedPercent = math.floor(pct * 100)
    sliderFill.Size = UDim2.new(pct, 0, 1, 0)
    speedLabel.Text = "SPEED: " .. CONFIG.SpeedPercent .. "%"
end

sliderBG.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        UpdateSlider(input.Position.X)
    end
end)

sliderBG.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateSlider(input.Position.X)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

closeButton.MouseButton1Click:Connect(function()
    RestoreHitbox()
    LocalHumanoid.WalkSpeed = BASE_SPEED
    HideAllESP()
    screenGui:Destroy()
end)

mode1Button.MouseButton1Click:Connect(function()
    CONFIG.Mode1 = not CONFIG.Mode1
    SetToggle(mode1Button, CONFIG.Mode1, "MODE 1  —  Hitbox Expand")
    if not CONFIG.Mode1 then RestoreHitbox() end
end)

mode2Button.MouseButton1Click:Connect(function()
    CONFIG.Mode2 = not CONFIG.Mode2
    SetToggle(mode2Button, CONFIG.Mode2, "MODE 2  —  Hitbox Spam")
end)

mode3Button.MouseButton1Click:Connect(function()
    CONFIG.Mode3 = not CONFIG.Mode3
    SetToggle(mode3Button, CONFIG.Mode3, "MODE 3  —  ESP")
    if not CONFIG.Mode3 then HideAllESP() end
end)

mode4Button.MouseButton1Click:Connect(function()
    CONFIG.Mode4 = not CONFIG.Mode4
    SetToggle(mode4Button, CONFIG.Mode4, "MODE 4  —  Tracers")
    if not CONFIG.Mode4 then
        for _, esp in pairs(ESP_Objects) do
            esp.Line.Visible = false
        end
    end
end)

mode5Button.MouseButton1Click:Connect(function()
    CONFIG.Mode5 = not CONFIG.Mode5
    SetToggle(mode5Button, CONFIG.Mode5, "MODE 5  —  Fast Run")
    if not CONFIG.Mode5 then
        LocalHumanoid.WalkSpeed = BASE_SPEED
    end
end)

mode6Button.MouseButton1Click:Connect(function()
    CONFIG.Mode6 = not CONFIG.Mode6
    SetToggle(mode6Button, CONFIG.Mode6, "MODE 6  —  Dash Spam  [hold Q]")
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Q and CONFIG.Mode6 then
        dashHolding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then
        dashHolding = false
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot = char:WaitForChild("HumanoidRootPart")
    LocalHumanoid = char:WaitForChild("Humanoid")
    OriginalLocalSize = nil
    dashHolding = false
end)

RunService.RenderStepped:Connect(function()
    if CONFIG.Mode1 then
        ExpandHitbox()
    end

    if CONFIG.Mode2 and LocalRoot then
        Mode2Func(LocalRoot.Position)
    end

    if CONFIG.Mode5 then
        LocalHumanoid.WalkSpeed = GetTargetSpeed()
    end

    if CONFIG.Mode6 and dashHolding then
        local now = tick()
        if now - lastDashTime >= DASH_INTERVAL then
            lastDashTime = now
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, nil)
            task.delay(0.02, function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, nil)
            end)
        end
    end

    RenderESP()
end)
