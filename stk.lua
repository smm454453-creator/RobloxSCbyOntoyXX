local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalRoot = LocalCharacter:WaitForChild("HumanoidRootPart")
local LocalHumanoid = LocalCharacter:WaitForChild("Humanoid")

local CONFIG = {
    FastRun      = false,
    DoubleJump   = false,
    InfiniteJump = false,
    LootESP      = false,
    SpeedPercent = 50,
}

local BASE_SPEED = 16
local MAX_SPEED  = 100
local JUMP_POWER = 50

local RARITY_DATA = {
    ["Knife"]         = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Bat"]           = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Frying Pan"]    = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Wrench"]        = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Katana"]        = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Scythe"]        = { rarity = "Epic",      color = Color3.fromRGB(160,50,255)  },
    ["Sword"]         = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Spear"]         = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Axe"]           = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Hammer"]        = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Trident"]       = { rarity = "Epic",      color = Color3.fromRGB(160,50,255)  },
    ["Scimitar"]      = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Nunchucks"]     = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Sickle"]        = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Cleaver"]       = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Pitchfork"]     = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Crowbar"]       = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Machete"]       = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Hatchet"]       = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Flail"]         = { rarity = "Epic",      color = Color3.fromRGB(160,50,255)  },
    ["Saber"]         = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Chainsaw"]      = { rarity = "Legendary", color = Color3.fromRGB(255,160,0)   },
    ["Death Scythe"]  = { rarity = "Legendary", color = Color3.fromRGB(255,160,0)   },
    ["Excalibur"]     = { rarity = "Legendary", color = Color3.fromRGB(255,160,0)   },
    ["Bear Trap"]     = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Medkit"]        = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Shield"]        = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Speed Potion"]  = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Invisibility"]  = { rarity = "Epic",      color = Color3.fromRGB(160,50,255)  },
    ["Jetpack"]       = { rarity = "Legendary", color = Color3.fromRGB(255,160,0)   },
}

local function GetRarity(name)
    if RARITY_DATA[name] then return RARITY_DATA[name] end
    for key, data in pairs(RARITY_DATA) do
        if string.find(name, key, 1, true) then return data end
    end
    return { rarity = "Unknown", color = Color3.fromRGB(200,200,200) }
end

-- ── MOVEMENT ──────────────────────────────────────────────────────────────────
local function GetTargetSpeed()
    return BASE_SPEED + (MAX_SPEED - BASE_SPEED) * (CONFIG.SpeedPercent / 100)
end

local function ApplySpeed()
    if not CONFIG.FastRun then return end
    local state = LocalHumanoid:GetState()
    if state == Enum.HumanoidStateType.GettingUp
    or state == Enum.HumanoidStateType.Seated then return end
    LocalHumanoid.WalkSpeed = GetTargetSpeed()
end

-- ── JUMP ──────────────────────────────────────────────────────────────────────
local jumpCount  = 0
local maxJumps   = 2
local isGrounded = false

local function OnStateChanged(_, new)
    if new == Enum.HumanoidStateType.Landed
    or new == Enum.HumanoidStateType.Running then
        jumpCount  = 0
        isGrounded = true
    elseif new == Enum.HumanoidStateType.Freefall then
        isGrounded = false
    end
end

local stateConn = LocalHumanoid.StateChanged:Connect(OnStateChanged)

UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        LocalHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        return
    end
    if CONFIG.DoubleJump then
        if jumpCount < maxJumps then
            jumpCount = jumpCount + 1
            LocalHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ── LOOT ESP ──────────────────────────────────────────────────────────────────
local lootESP_Objects = {}

local function IsLoot(instance)
    if not instance:IsA("Model") and not instance:IsA("Part")
    and not instance:IsA("MeshPart") and not instance:IsA("UnionOperation") then
        return false
    end
    if GetRarity(instance.Name).rarity ~= "Unknown" then return true end
    local parent = instance.Parent
    if parent then
        local pn = parent.Name:lower()
        if pn == "loot" or pn == "drops" or pn == "items" or pn == "weapons" then
            return true
        end
    end
    return false
end

local function GetLootPart(instance)
    if instance:IsA("Model") then
        return instance.PrimaryPart
            or instance:FindFirstChildWhichIsA("Part")
            or instance:FindFirstChildWhichIsA("MeshPart")
    end
    return instance
end

local function CreateLootLabel()
    local nameTag = Drawing.new("Text")
    nameTag.Size         = 13
    nameTag.Center       = true
    nameTag.Outline      = true
    nameTag.OutlineColor = Color3.fromRGB(0,0,0)
    nameTag.Visible      = false
    nameTag.Font         = Drawing.Fonts.Plex

    local distTag = Drawing.new("Text")
    distTag.Size         = 11
    distTag.Center       = true
    distTag.Outline      = true
    distTag.OutlineColor = Color3.fromRGB(0,0,0)
    distTag.Color        = Color3.fromRGB(200,200,200)
    distTag.Visible      = false
    distTag.Font         = Drawing.Fonts.Plex

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled    = false
    box.Visible   = false

    return { nameTag = nameTag, distTag = distTag, box = box }
end

local function CleanLootESP(obj)
    obj.nameTag:Remove()
    obj.distTag:Remove()
    obj.box:Remove()
end

local function HideLootObj(obj)
    obj.nameTag.Visible = false
    obj.distTag.Visible = false
    obj.box.Visible     = false
end

local function ScanLoot()
    for instance, obj in pairs(lootESP_Objects) do
        if not instance or not instance.Parent then
            CleanLootESP(obj)
            lootESP_Objects[instance] = nil
        end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        if not lootESP_Objects[child] and IsLoot(child) then
            lootESP_Objects[child] = CreateLootLabel()
        end
        if child:IsA("Folder") or child:IsA("Model") then
            for _, sub in ipairs(child:GetChildren()) do
                if not lootESP_Objects[sub] and IsLoot(sub) then
                    lootESP_Objects[sub] = CreateLootLabel()
                end
            end
        end
    end
end

local lastLootScan = 0

-- FIX: RenderLootESP bersih — duplicate block di luar fungsi dihapus,
-- goto/continue diganti if-else chain biar kompatibel semua executor
local function RenderLootESP()
    local now = tick()
    if now - lastLootScan > 2 then
        ScanLoot()
        lastLootScan = now
    end

    if not CONFIG.LootESP then
        for _, obj in pairs(lootESP_Objects) do
            HideLootObj(obj)
        end
        return
    end

    for instance, obj in pairs(lootESP_Objects) do
        local valid = instance and instance.Parent
        if valid then
            local part = GetLootPart(instance)
            if part then
                local screen, onScreen = Camera:WorldToScreenPoint(part.Position)
                if onScreen then
                    local dist = math.floor((part.Position - LocalRoot.Position).Magnitude)
                    if dist <= 300 then
                        local rd      = GetRarity(instance.Name)
                        local scale   = math.clamp(1 - (dist / 300), 0.4, 1)
                        local tagSize = math.floor(11 * scale + 4)

                        obj.nameTag.Text     = instance.Name .. "  [" .. rd.rarity .. "]"
                        obj.nameTag.Color    = rd.color
                        obj.nameTag.Size     = tagSize
                        obj.nameTag.Position = Vector2.new(screen.X, screen.Y - 18)
                        obj.nameTag.Visible  = true

                        obj.distTag.Text     = dist .. "m"
                        obj.distTag.Size     = math.max(tagSize - 2, 9)
                        obj.distTag.Position = Vector2.new(screen.X, screen.Y - 4)
                        obj.distTag.Visible  = true

                        local boxSize        = math.clamp(40 * scale, 14, 40)
                        obj.box.Color        = rd.color
                        obj.box.Size         = Vector2.new(boxSize, boxSize)
                        obj.box.Position     = Vector2.new(screen.X - boxSize/2, screen.Y - boxSize/2)
                        obj.box.Visible      = true
                    else
                        HideLootObj(obj)
                    end
                else
                    HideLootObj(obj)
                end
            else
                HideLootObj(obj)
            end
        else
            HideLootObj(obj)
        end
    end
end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Ontoy_STK"; screenGui.ResetOnSpawn = false
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
}

local mainWindow = Instance.new("Frame")
mainWindow.Size             = UDim2.new(0, 480, 0, 380)
mainWindow.Position         = UDim2.new(0.5, -240, 0.5, -190)
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
titleBar.BorderSizePixel  = 0; titleBar.Active = true
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = false
    end
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
titleText.Text                   = "ONTOY HUB  <font color='#C81E32'>·</font>  Survive The Killer"
titleText.RichText                = true
titleText.TextColor3             = REDZ.TextMain
titleText.Font                   = Enum.Font.GothamBold
titleText.TextSize               = 13
titleText.TextXAlignment         = Enum.TextXAlignment.Left

local byLabel = Instance.new("TextLabel", titleBar)
byLabel.Size                   = UDim2.new(0, 80, 1, 0)
byLabel.Position               = UDim2.new(0, 270, 0, 0)
byLabel.BackgroundTransparency = 1
byLabel.Text                   = "by ontoy"
byLabel.TextColor3             = REDZ.TextSub
byLabel.Font                   = Enum.Font.Gotham; byLabel.TextSize = 11
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
sidebar.Size = UDim2.new(0, 138, 1, -42); sidebar.Position = UDim2.new(0, 0, 0, 42)
sidebar.BackgroundColor3 = REDZ.BG2; sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", sidebar).Color = REDZ.Stroke
local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding = UDim.new(0, 3)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 12)

local contentArea = Instance.new("Frame", mainWindow)
contentArea.Size = UDim2.new(1, -146, 1, -50); contentArea.Position = UDim2.new(0, 142, 0, 46)
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

local function MakeToggleRow(parent, label, sublabel)
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
            toggleBG.BackgroundColor3   = REDZ.Accent
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

local function MakeSliderRow(parent, label, dMin, dMax, initPct, unit, onChanged)
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
    local knobRing = Instance.new("UIStroke", knob); knobRing.Color = REDZ.Accent; knobRing.Thickness = 2
    local dragging = false
    local function Compute(px)
        local bg = sliderBG.AbsolutePosition.X; local bw = sliderBG.AbsoluteSize.X
        local pct = math.clamp((px - bg) / bw, 0, 1)
        return pct, math.floor(dMin + (dMax - dMin) * pct)
    end
    local function Apply(pct, val)
        sliderFill.Size = UDim2.new(pct, 0, 1, 0); knob.Position = UDim2.new(pct, -7, 0.5, -7)
        valLabel.Text = val .. (unit or "")
        if onChanged then onChanged(val, pct) end
    end
    Apply(initPct, math.floor(dMin + (dMax - dMin) * initPct))
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

-- ── BUILD PAGES ───────────────────────────────────────────────────────────────
local movePage = MakePage(); pages["movement"] = movePage
local moveBtn  = MakeSidebarBtn("🏃", "Movement", "movement")

MakeSectionLabel(movePage, "SPEED")
local _, fastRunGet, _ = MakeToggleRow(movePage, "Fast Run", "Override WalkSpeed — patch crouch juga")
MakeSliderRow(movePage, "Run Speed", BASE_SPEED, MAX_SPEED, 0.5, " ws", function(val, pct)
    CONFIG.SpeedPercent = pct * 100
end)

MakeSectionLabel(movePage, "JUMP")
local _, doubleGet,   _ = MakeToggleRow(movePage, "Double Jump",   "Lompat dua kali di udara")
local _, infiniteGet, _ = MakeToggleRow(movePage, "Infinite Jump", "Lompat terus tanpa batas")

local visualPage = MakePage(); pages["visual"] = visualPage
local visualBtn  = MakeSidebarBtn("👁", "Visual", "visual")

MakeSectionLabel(visualPage, "LOOT ESP")
local _, lootGet, _ = MakeToggleRow(visualPage, "Loot ESP", "Nama + rarity + jarak semua loot di map")

-- ── WIRE ─────────────────────────────────────────────────────────────────────
local function WireToggle(getter, configKey, onEnable, onDisable)
    RunService.Heartbeat:Connect(function()
        local s = getter()
        if CONFIG[configKey] ~= s then
            CONFIG[configKey] = s
            if s then if onEnable  then onEnable()  end
            else      if onDisable then onDisable()  end
            end
        end
    end)
end

WireToggle(fastRunGet,  "FastRun", nil, function()
    LocalHumanoid.WalkSpeed = BASE_SPEED
end)
WireToggle(doubleGet,   "DoubleJump", function()
    CONFIG.InfiniteJump = false
end)
WireToggle(infiniteGet, "InfiniteJump", function()
    CONFIG.DoubleJump = false
end)
WireToggle(lootGet, "LootESP")

moveBtn.MouseButton1Click:Connect(function()   SetActivePage("movement") end)
visualBtn.MouseButton1Click:Connect(function() SetActivePage("visual")   end)
SetActivePage("movement")

local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
    contentVisible = not contentVisible
    sidebar.Visible = contentVisible; contentArea.Visible = contentVisible
    mainWindow.Size = contentVisible and UDim2.new(0, 480, 0, 380) or UDim2.new(0, 480, 0, 42)
end)

closeBtn.MouseButton1Click:Connect(function()
    LocalHumanoid.WalkSpeed = BASE_SPEED
    for _, obj in pairs(lootESP_Objects) do CleanLootESP(obj) end
    screenGui:Destroy()
end)

-- ── RESPAWN ───────────────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot      = char:WaitForChild("HumanoidRootPart")
    LocalHumanoid  = char:WaitForChild("Humanoid")
    jumpCount      = 0; isGrounded = true
    if stateConn then stateConn:Disconnect() end
    stateConn = LocalHumanoid.StateChanged:Connect(OnStateChanged)
    if CONFIG.FastRun then LocalHumanoid.WalkSpeed = GetTargetSpeed() end
end)

-- ── RENDER LOOP ───────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if CONFIG.FastRun then ApplySpeed() end
    RenderLootESP()
end)