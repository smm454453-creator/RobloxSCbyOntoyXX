local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
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
    HitboxSize = 20,
}

local LockedTarget = nil
local OriginalSizes = {}
local ESP_Objects = {}

local function ExpandHitbox(player)
    if not player or not player.Character then return end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not OriginalSizes[player] then
        OriginalSizes[player] = root.Size
    end
    root.Size = Vector3.new(CONFIG.HitboxSize, CONFIG.HitboxSize, CONFIG.HitboxSize)
end

local function RestoreHitbox(player)
    if not player or not player.Character then return end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if OriginalSizes[player] then
        root.Size = OriginalSizes[player]
        OriginalSizes[player] = nil
    end
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
    if player == LockedTarget then
        RestoreHitbox(player)
        LockedTarget = nil
    end
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
mainFrame.Size = UDim2.new(0, 230, 0, 400)
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

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, -20, 0, 16)
targetLabel.Position = UDim2.new(0, 10, 0, 44)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "SELECT TARGET"
targetLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
targetLabel.Font = Enum.Font.GothamBold
targetLabel.TextSize = 10
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = mainFrame

local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(1, -20, 0, 100)
playerListFrame.Position = UDim2.new(0, 10, 0, 62)
playerListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
playerListFrame.BorderSizePixel = 0
playerListFrame.ScrollBarThickness = 3
playerListFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
playerListFrame.Parent = mainFrame
local c4 = Instance.new("UICorner")
c4.CornerRadius = UDim.new(0, 6)
c4.Parent = playerListFrame
local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = playerListFrame

local lockLabel = Instance.new("TextLabel")
lockLabel.Size = UDim2.new(1, -20, 0, 16)
lockLabel.Position = UDim2.new(0, 10, 0, 170)
lockLabel.BackgroundTransparency = 1
lockLabel.Text = "TARGET: none"
lockLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
lockLabel.Font = Enum.Font.Gotham
lockLabel.TextSize = 11
lockLabel.TextXAlignment = Enum.TextXAlignment.Left
lockLabel.Parent = mainFrame

local function SetLockLabel(player)
    if player then
        lockLabel.Text = "TARGET: " .. player.Name
        lockLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        lockLabel.Text = "TARGET: none"
        lockLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    end
end

local playerButtons = {}

local function RefreshPlayerList()
    for _, btn in pairs(playerButtons) do
        btn:Destroy()
    end
    playerButtons = {}
    local totalHeight = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 28)
            btn.BackgroundColor3 = (LockedTarget == player) and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(35, 35, 48)
            btn.Text = "  " .. player.Name
            btn.TextColor3 = Color3.fromRGB(220, 220, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.BorderSizePixel = 0
            btn.Parent = playerListFrame
            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 4)
            bc.Parent = btn
            btn.MouseButton1Click:Connect(function()
                if LockedTarget == player then
                    if CONFIG.Mode1 then RestoreHitbox(player) end
                    LockedTarget = nil
                    SetLockLabel(nil)
                else
                    if LockedTarget and CONFIG.Mode1 then RestoreHitbox(LockedTarget) end
                    LockedTarget = player
                    SetLockLabel(player)
                    if CONFIG.Mode1 then ExpandHitbox(player) end
                end
                RefreshPlayerList()
            end)
            playerButtons[player] = btn
            totalHeight = totalHeight + 30
        end
    end
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

RefreshPlayerList()
Players.PlayerAdded:Connect(function() RefreshPlayerList() end)
Players.PlayerRemoving:Connect(function() RefreshPlayerList() end)

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

local mode1Button = MakeButton("MODE 1  —  Hitbox Expand", 194)
local mode2Button = MakeButton("MODE 2  —  Hitbox Spam", 232)
local mode3Button = MakeButton("MODE 3  —  ESP", 270)
local mode4Button = MakeButton("MODE 4  —  Tracers", 308)

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
    if mainFrame.Visible then RefreshPlayerList() end
end)

closeButton.MouseButton1Click:Connect(function()
    if LockedTarget then RestoreHitbox(LockedTarget) end
    screenGui:Destroy()
end)

mode1Button.MouseButton1Click:Connect(function()
    CONFIG.Mode1 = not CONFIG.Mode1
    SetToggle(mode1Button, CONFIG.Mode1, "MODE 1  —  Hitbox Expand")
    if CONFIG.Mode1 then
        if LockedTarget then ExpandHitbox(LockedTarget) end
    else
        if LockedTarget then RestoreHitbox(LockedTarget) end
    end
end)

mode2Button.MouseButton1Click:Connect(function()
    CONFIG.Mode2 = not CONFIG.Mode2
    SetToggle(mode2Button, CONFIG.Mode2, "MODE 2  —  Hitbox Spam")
end)

mode3Button.MouseButton1Click:Connect(function()
    CONFIG.Mode3 = not CONFIG.Mode3
    SetToggle(mode3Button, CONFIG.Mode3, "MODE 3  —  ESP")
end)

mode4Button.MouseButton1Click:Connect(function()
    CONFIG.Mode4 = not CONFIG.Mode4
    SetToggle(mode4Button, CONFIG.Mode4, "MODE 4  —  Tracers")
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot = char:WaitForChild("HumanoidRootPart")
end)

RunService.RenderStepped:Connect(function()
    if CONFIG.Mode1 and LockedTarget then
        ExpandHitbox(LockedTarget)
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
            SetLockLabel(nil)
            RefreshPlayerList()
        else
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health <= 0 then
                RestoreHitbox(LockedTarget)
                LockedTarget = nil
                SetLockLabel(nil)
                RefreshPlayerList()
            end
        end
    end
end)
