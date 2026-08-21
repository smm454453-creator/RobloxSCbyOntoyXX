local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local CONFIG = {
    FastRun = false, RunSpeed = 50,
    HighJump = false, JumpPower = 100,
    ESP = false,
    Aimbot = false
}

-- BIKIN GUI
local sg = Instance.new("ScreenGui")
sg.Name = "OntoyHubFixed"
sg.Parent = LP:WaitForChild("PlayerGui")
sg.ResetOnSpawn = false

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 400, 0, 320)
main.Position = UDim2.new(0.5, -200, 0.5, -160)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", main).Color = Color3.fromRGB(255, 60, 80)

-- TITLE BAR & DRAG SYSTEM
local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleTxt = Instance.new("TextLabel", titleBar)
titleTxt.Size = UDim2.new(1, -50, 1, 0)
titleTxt.Position = UDim2.new(0, 15, 0, 0)
titleTxt.BackgroundTransparency = 1
titleTxt.Text = "ONTOY HUB | Hypershot Fix"
titleTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
titleTxt.Font = Enum.Font.GothamBold
titleTxt.TextSize = 14
titleTxt.TextXAlignment = Enum.TextXAlignment.Left

-- TOMBOL HIDE
local hideBtn = Instance.new("TextButton", titleBar)
hideBtn.Size = UDim2.new(0, 30, 0, 30)
hideBtn.Position = UDim2.new(1, -35, 0, 2)
hideBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
hideBtn.Text = "X"
hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hideBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 6)

local guiVisible = true
hideBtn.MouseButton1Click:Connect(function()
    sg:Destroy() -- Skrip berhenti jika di-close
end)

local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- WADAH KONTEN
local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, -20, 1, -50)
scroll.Position = UDim2.new(0, 10, 0, 45)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 2
local lay = Instance.new("UIListLayout", scroll)
lay.Padding = UDim.new(0, 8)

-- FUNGSI TOGGLE
local function MakeToggle(label, key)
    local btn = Instance.new("TextButton", scroll)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = "  [OFF] " .. label
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        btn.Text = (CONFIG[key] and "  [ON] " or "  [OFF] ") .. label
        btn.TextColor3 = CONFIG[key] and Color3.fromRGB(255, 60, 80) or Color3.fromRGB(200, 200, 200)
    end)
end

-- FUNGSI SLIDER
local function MakeSlider(label, key, minVal, maxVal)
    local frame = Instance.new("Frame", scroll)
    frame.Size = UDim2.new(1, 0, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)
    
    local txt = Instance.new("TextLabel", frame)
    txt.Size = UDim2.new(1, -10, 0, 20)
    txt.Position = UDim2.new(0, 10, 0, 2)
    txt.BackgroundTransparency = 1
    txt.Text = label .. " : " .. CONFIG[key]
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 12
    txt.TextXAlignment = Enum.TextXAlignment.Left
    
    local sliderBg = Instance.new("TextButton", frame)
    sliderBg.Size = UDim2.new(1, -20, 0, 10)
    sliderBg.Position = UDim2.new(0, 10, 0, 25)
    sliderBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    sliderBg.Text = ""
    
    local fill = Instance.new("Frame", sliderBg)
    fill.Size = UDim2.new((CONFIG[key] - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
    fill.BorderSizePixel = 0
    
    local draggingSlider = false
    local function Update(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + ((maxVal - minVal) * pos))
        CONFIG[key] = val
        txt.Text = label .. " : " .. val
        fill.Size = UDim2.new(pos, 0, 1, 0)
    end
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = true; Update(input) end
    end)
    UIS.InputChanged:Connect(function(input)
        if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then Update(input) end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
    end)
end

-- ISI MENU
MakeToggle("Enable Fast Run", "FastRun")
MakeSlider("Set Speed", "RunSpeed", 16, 150)
MakeToggle("Enable High Jump", "HighJump")
MakeSlider("Set Jump", "JumpPower", 50, 300)
MakeToggle("Aimbot (Tahan Klik Kanan)", "Aimbot")
MakeToggle("ESP Highlight (Menyala Merah)", "ESP")

-- LOGIC ESP HIGHLIGHT
RunService.RenderStepped:Connect(function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hl = plr.Character:FindFirstChild("OntoyESP")
            if CONFIG.ESP then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "OntoyESP"
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = plr.Character
                end
            else
                if hl then hl:Destroy() end
            end
        end
    end
end)

-- LOGIC MOVEMENT
RunService.RenderStepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local hum = LP.Character.Humanoid
        if CONFIG.FastRun then hum.WalkSpeed = CONFIG.RunSpeed end
        if CONFIG.HighJump then
            hum.UseJumpPower = true
            hum.JumpPower = CONFIG.JumpPower
        end
    end
end)

-- LOGIC AIMBOT (Klik Kanan)
local aiming = false
UIS.InputBegan:Connect(function(i, gpe)
    if not gpe and i.UserInputType == Enum.UserInputType.MouseButton2 then aiming = true end
end)
UIS.InputEnded:Connect(function(i, gpe)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then aiming = false end
end)

RunService.RenderStepped:Connect(function()
    if aiming and CONFIG.Aimbot then
        local closest = nil
        local minDist = math.huge
        local mousePos = UIS:GetMouseLocation()
        
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = plr.Character.HumanoidRootPart
                    end
                end
            end
        end
        
        if closest then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, closest.Position)
        end
    end
end)
