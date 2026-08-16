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
    PlayerESP    = false,
    KillerESP    = false,
    AutoLoot     = false,
    SpeedPercent = 50,
}

local BASE_SPEED = 16
local MAX_SPEED  = 100

local RARITY_DATA = {
    ["KnifeAttachment"] = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Knife"]           = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Bat"]             = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Frying Pan"]      = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Wrench"]          = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Katana"]          = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Scythe"]          = { rarity = "Epic",      color = Color3.fromRGB(160,50,255)  },
    ["Sword"]           = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Spear"]           = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Axe"]             = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Hammer"]          = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Trident"]         = { rarity = "Epic",      color = Color3.fromRGB(160,50,255)  },
    ["Scimitar"]        = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Nunchucks"]       = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Sickle"]          = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Cleaver"]         = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Pitchfork"]       = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Crowbar"]         = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Machete"]         = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Hatchet"]         = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Flail"]           = { rarity = "Epic",      color = Color3.fromRGB(160,50,255)  },
    ["Saber"]           = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Chainsaw"]        = { rarity = "Legendary", color = Color3.fromRGB(255,160,0)   },
    ["Death Scythe"]    = { rarity = "Legendary", color = Color3.fromRGB(255,160,0)   },
    ["Excalibur"]       = { rarity = "Legendary", color = Color3.fromRGB(255,160,0)   },
    ["Bear Trap"]       = { rarity = "Common",    color = Color3.fromRGB(180,180,180) },
    ["Medkit"]          = { rarity = "Uncommon",  color = Color3.fromRGB(80,200,80)   },
    ["Shield"]          = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Speed Potion"]    = { rarity = "Rare",      color = Color3.fromRGB(80,120,255)  },
    ["Invisibility"]    = { rarity = "Epic",      color = Color3.fromRGB(160,50,255)  },
    ["Jetpack"]         = { rarity = "Legendary", color = Color3.fromRGB(255,160,0)   },
}

local function GetRarity(name)
    if not name then return nil end
    if RARITY_DATA[name] then return RARITY_DATA[name] end
    for key, data in pairs(RARITY_DATA) do
        if string.find(name, key, 1, true) then return data end
    end
    return nil
end

local KILLER_TAG_NAMES = {
    killer = true, murderer = true, ["the killer"] = true, slasher = true,
}

local function IsKiller(plr)
    if not plr or not plr.Character then return false end
    local nameLow = plr.Name:lower()
    if KILLER_TAG_NAMES[nameLow] then return true end
    local char = plr.Character
    for _, v in ipairs(char:GetDescendants()) do
        if (v:IsA("TextLabel") or v:IsA("StringValue") or v:IsA("BillboardGui")) then
            local txt = (v:IsA("StringValue") and v.Value or v.Name):lower()
            if string.find(txt, "killer") or string.find(txt, "murderer") then
                return true
            end
        end
        if v:IsA("TextLabel") and string.find(v.Text:lower(), "killer") then
            return true
        end
    end
    if plr.Team and string.find(plr.Team.Name:lower(), "killer") then
        return true
    end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum and hum.MaxHealth >= 300 then return true end
    return false
end

local function GetAllPlayerCharacters()
    local set = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then set[plr.Character] = true end
    end
    return set
end

local function IsUnderCharacter(inst)
    local chars = GetAllPlayerCharacters()
    local obj = inst
    while obj do
        if chars[obj] then return true end
        obj = obj.Parent
    end
    return false
end

local function IsLootInstance(inst)
    if not inst or not inst.Parent then return false end
    if IsUnderCharacter(inst) then return false end
    local parent = inst.Parent
    if parent then
        local pname = parent.Name:lower()
        if pname == "backpack" or pname == "startergear"
        or pname == "startercharacter" then return false end
    end
    if inst:IsA("Model") and inst:FindFirstChildWhichIsA("Humanoid") then
        return false
    end
    if not (inst:IsA("Model") or inst:IsA("Part")
        or inst:IsA("MeshPart") or inst:IsA("UnionOperation")
        or inst:IsA("Tool")) then
        return false
    end
    return GetRarity(inst.Name) ~= nil
end

local function GetLootPart(inst)
    if inst:IsA("Model") then
        return inst.PrimaryPart
            or inst:FindFirstChildWhichIsA("MeshPart")
            or inst:FindFirstChildWhichIsA("Part")
    end
    if inst:IsA("Tool") then
        return inst:FindFirstChildWhichIsA("Part")
            or inst:FindFirstChildWhichIsA("MeshPart")
    end
    return inst
end

local function GetTargetSpeed()
    return BASE_SPEED + (MAX_SPEED - BASE_SPEED) * (CONFIG.SpeedPercent / 100)
end

local function ApplySpeed()
    if not CONFIG.FastRun then return end
    local st = LocalHumanoid:GetState()
    if st == Enum.HumanoidStateType.GettingUp
    or st == Enum.HumanoidStateType.Seated then return end
    LocalHumanoid.WalkSpeed = GetTargetSpeed()
end

local jumpCount     = 0
local canDoubleJump = false

local function OnStateChanged(_, new)
    if new == Enum.HumanoidStateType.Jumping then
        if jumpCount == 0 then
            jumpCount = 1
            canDoubleJump = false
            task.delay(0.15, function()
                local st = LocalHumanoid:GetState()
                if st == Enum.HumanoidStateType.Freefall
                or st == Enum.HumanoidStateType.Jumping then
                    canDoubleJump = true
                end
            end)
        end
    elseif new == Enum.HumanoidStateType.Landed
        or new == Enum.HumanoidStateType.Running
        or new == Enum.HumanoidStateType.RunningNoPhysics then
        jumpCount = 0; canDoubleJump = false
    end
end

local stateConn = LocalHumanoid.StateChanged:Connect(OnStateChanged)

UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        LocalHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        return
    end
    if CONFIG.DoubleJump and canDoubleJump and jumpCount < 2 then
        jumpCount = jumpCount + 1
        canDoubleJump = false
        local rp = LocalCharacter:FindFirstChild("HumanoidRootPart")
        if rp then
            local v = rp.AssemblyLinearVelocity
            rp.AssemblyLinearVelocity = Vector3.new(v.X, 50, v.Z)
        end
    end
end)

local function CollectLoots()
    local result = {}
    local function Scan(folder)
        for _, c in ipairs(folder:GetChildren()) do
            if IsLootInstance(c) then
                table.insert(result, c)
            elseif c:IsA("Folder") then
                Scan(c)
            end
        end
    end
    Scan(Workspace)
    return result
end

local function TryPickup(inst)
    local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then pcall(fireproximityprompt, prompt); return end
    local re = inst:FindFirstChildWhichIsA("RemoteEvent", true)
    if re then pcall(function() re:FireServer() end); return end
    local cd = inst:FindFirstChildWhichIsA("ClickDetector", true)
    if cd then pcall(fireclickdetector, cd) end
end

local autoLootRunning = false

local function RunAutoLoot()
    if autoLootRunning then return end
    autoLootRunning = true
    local loots = CollectLoots()
    table.sort(loots, function(a, b)
        local pa, pb = GetLootPart(a), GetLootPart(b)
        if not pa or not pb then return false end
        return (pa.Position - LocalRoot.Position).Magnitude
             < (pb.Position - LocalRoot.Position).Magnitude
    end)
    for _, loot in ipairs(loots) do
        if not CONFIG.AutoLoot then break end
        if not loot.Parent then continue end
        local part = GetLootPart(loot)
        if part then
            LocalRoot.CFrame = CFrame.new(part.Position + Vector3.new(0, 2.5, 0))
            task.wait(0.08)
            TryPickup(loot)
            task.wait(0.05)
        end
    end
    autoLootRunning = false
end

local function FindValidFloor(searchRoot, maxDist)
    local chars = GetAllPlayerCharacters()
    local best, bestDist = nil, maxDist or 9999
    local function Scan(obj)
        if obj:IsA("BasePart") and obj.CanCollide
        and obj.Size.Y >= 0.3 and obj.Position.Y > -200 then
            local isChar = false
            local check = obj
            while check do
                if chars[check] then isChar = true; break end
                check = check.Parent
            end
            if not isChar then
                local dist = searchRoot and (obj.Position - searchRoot).Magnitude or 0
                if dist < bestDist then
                    bestDist = dist; best = obj
                end
            end
        end
        for _, c in ipairs(obj:GetChildren()) do Scan(c) end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        local isChar = false
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character == child then isChar = true; break end
        end
        if not isChar then Scan(child) end
    end
    return best
end

local function SafeTeleport(pos)
    local ray = Workspace:Raycast(pos + Vector3.new(0, 5, 0), Vector3.new(0, -15, 0))
    local landY = ray and (ray.Position.Y + 3) or (pos.Y + 3)
    LocalRoot.CFrame = CFrame.new(Vector3.new(pos.X, landY, pos.Z))
end

local function TeleportToMap()
    local refPos
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local r = plr.Character:FindFirstChild("HumanoidRootPart")
            if r and r.Position.Y > -100 then refPos = r.Position; break end
        end
    end
    if refPos then
        SafeTeleport(refPos + Vector3.new(5, 0, 0))
        return
    end
    local floor = FindValidFloor(Vector3.new(0, 50, 0), 500)
    if floor then SafeTeleport(floor.Position) end
end

local function TeleportToLobby()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") and obj.Position.Y > -100 then
            SafeTeleport(obj.Position + Vector3.new(0, 3, 0))
            return
        end
    end
    local lobbyNames = {"Lobby","Waiting","WaitingRoom","WaitArea","Hub","Menu"}
    for _, name in ipairs(lobbyNames) do
        local obj = Workspace:FindFirstChild(name, true)
        if obj then
            local function FindFloor(o)
                if o:IsA("BasePart") and o.CanCollide and o.Position.Y > -100 then return o end
                for _, c in ipairs(o:GetChildren()) do
                    local f = FindFloor(c); if f then return f end
                end
            end
            local p = FindFloor(obj)
            if p then SafeTeleport(p.Position); return end
        end
    end
    SafeTeleport(Vector3.new(0, 10, 0))
end

local function TeleportToPlayer(plr)
    if not plr or not plr.Character then return end
    local r = plr.Character:FindFirstChild("HumanoidRootPart")
    if r then LocalRoot.CFrame = CFrame.new(r.Position + Vector3.new(3, 2, 0)) end
end

local function NewText(size, color)
    local t = Drawing.new("Text")
    t.Size = size or 13; t.Center = true; t.Outline = true
    t.OutlineColor = Color3.fromRGB(0,0,0)
    t.Color = color or Color3.fromRGB(255,255,255)
    t.Visible = false; t.Font = Drawing.Fonts.Plex
    return t
end

local function NewBox(color, thick)
    local b = Drawing.new("Square")
    b.Thickness = thick or 1.5; b.Filled = false
    b.Color = color or Color3.fromRGB(255,255,255); b.Visible = false
    return b
end

local function NewFill(color)
    local f = Drawing.new("Square"); f.Filled = true
    f.Color = color or Color3.fromRGB(50,200,80); f.Visible = false
    return f
end

local lootESP = {}

local function CreateLootDraw()
    return {
        nameTag = NewText(13, Color3.fromRGB(255,255,255)),
        distTag = NewText(11, Color3.fromRGB(200,200,200)),
        box     = NewBox(Color3.fromRGB(255,255,255), 1),
    }
end

local function RemoveLootDraw(d)
    d.nameTag:Remove(); d.distTag:Remove(); d.box:Remove()
end

local function HideLootDraw(d)
    d.nameTag.Visible = false; d.distTag.Visible = false; d.box.Visible = false
end

local lastLootScan = 0

local function ScanLootESP()
    for inst, d in pairs(lootESP) do
        if not inst or not inst.Parent then
            RemoveLootDraw(d); lootESP[inst] = nil
        end
    end
    local function Check(inst)
        if not lootESP[inst] and IsLootInstance(inst) then
            lootESP[inst] = CreateLootDraw()
        end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        Check(child)
        if child:IsA("Folder") or child:IsA("Model") then
            for _, sub in ipairs(child:GetChildren()) do Check(sub) end
        end
    end
end

local function RenderLootESP()
    local now = tick()
    if now - lastLootScan > 1.5 then ScanLootESP(); lastLootScan = now end
    if not CONFIG.LootESP then
        for _, d in pairs(lootESP) do HideLootDraw(d) end; return
    end
    for inst, d in pairs(lootESP) do
        if inst and inst.Parent then
            local part = GetLootPart(inst)
            if part then
                local sc, on = Camera:WorldToScreenPoint(part.Position)
                if on then
                    local dist = math.floor((part.Position - LocalRoot.Position).Magnitude)
                    if dist <= 300 then
                        local rd = GetRarity(inst.Name) or {rarity="?",color=Color3.fromRGB(200,200,200)}
                        local scale = math.clamp(1 - dist/300, 0.4, 1)
                        local tsz = math.floor(11*scale + 4)
                        d.nameTag.Text = inst.Name .. " [" .. rd.rarity .. "]"
                        d.nameTag.Color = rd.color; d.nameTag.Size = tsz
                        d.nameTag.Position = Vector2.new(sc.X, sc.Y - 18); d.nameTag.Visible = true
                        d.distTag.Text = dist .. "m"; d.distTag.Size = math.max(tsz-2,9)
                        d.distTag.Position = Vector2.new(sc.X, sc.Y - 4); d.distTag.Visible = true
                        local bsz = math.clamp(40*scale, 14, 40)
                        d.box.Color = rd.color; d.box.Size = Vector2.new(bsz, bsz)
                        d.box.Position = Vector2.new(sc.X - bsz/2, sc.Y - bsz/2); d.box.Visible = true
                    else HideLootDraw(d) end
                else HideLootDraw(d) end
            else HideLootDraw(d) end
        else HideLootDraw(d) end
    end
end

local playerESP = {}

local function CreatePlayerDraw(killerFlag)
    local bc = killerFlag and Color3.fromRGB(255,60,60) or Color3.fromRGB(0,220,255)
    local obj = {
        nameTag  = NewText(13, bc),
        distTag  = NewText(11, Color3.fromRGB(200,200,200)),
        box      = NewBox(bc, 1.5),
        hpBG     = NewFill(Color3.fromRGB(30,30,30)),
        hpFill   = NewFill(Color3.fromRGB(50,220,80)),
        isKiller = killerFlag,
    }
    return obj
end

local function RemovePlayerDraw(d)
    d.nameTag:Remove(); d.distTag:Remove()
    d.box:Remove(); d.hpBG:Remove(); d.hpFill:Remove()
end

local function HidePlayerDraw(d)
    d.nameTag.Visible = false; d.distTag.Visible = false
    d.box.Visible = false; d.hpBG.Visible = false; d.hpFill.Visible = false
end

local function RenderPlayerESP()
    for plr, d in pairs(playerESP) do
        if not plr or not plr.Parent then
            RemovePlayerDraw(d); playerESP[plr] = nil
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not playerESP[plr] then
            playerESP[plr] = CreatePlayerDraw(IsKiller(plr))
        end
    end
    for plr, d in pairs(playerESP) do
        local showThis = (d.isKiller and CONFIG.KillerESP)
                      or (not d.isKiller and CONFIG.PlayerESP)
        if not showThis or not plr.Character then HidePlayerDraw(d); continue end
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        local hum  = plr.Character:FindFirstChildWhichIsA("Humanoid")
        if not root or not hum then HidePlayerDraw(d); continue end
        local sc, on = Camera:WorldToScreenPoint(root.Position)
        if not on then HidePlayerDraw(d); continue end
        local dist = math.floor((root.Position - LocalRoot.Position).Magnitude)
        if dist > 500 then HidePlayerDraw(d); continue end
        local scale = math.clamp(1 - dist/500, 0.3, 1)
        local bh = math.clamp(math.floor(80*scale), 20, 80)
        local bw = math.floor(bh * 0.55)
        local bx = sc.X - bw/2; local by = sc.Y - bh/2
        local bc = d.isKiller and Color3.fromRGB(255,60,60) or Color3.fromRGB(0,220,255)
        d.box.Color = bc; d.box.Size = Vector2.new(bw,bh); d.box.Position = Vector2.new(bx,by); d.box.Visible = true
        local tsz = math.floor(10*scale+3)
        d.nameTag.Text = plr.DisplayName .. (d.isKiller and " [KILLER]" or "")
        d.nameTag.Color = bc; d.nameTag.Size = tsz
        d.nameTag.Position = Vector2.new(sc.X, by - tsz - 2); d.nameTag.Visible = true
        d.distTag.Text = dist.."m"; d.distTag.Size = math.max(tsz-2,9)
        d.distTag.Position = Vector2.new(sc.X, by+bh+2); d.distTag.Visible = true
        local hpPct = math.clamp(hum.Health / math.max(hum.MaxHealth,1), 0, 1)
        local barW, barX, barY = 3, bx - 5, by
        d.hpBG.Size = Vector2.new(barW,bh); d.hpBG.Position = Vector2.new(barX,barY); d.hpBG.Visible = true
        local fh = math.floor(bh*hpPct)
        d.hpFill.Color = Color3.fromRGB(math.floor(255*(1-hpPct)), math.floor(220*hpPct), 50)
        d.hpFill.Size = Vector2.new(barW,math.max(fh,1))
        d.hpFill.Position = Vector2.new(barX, barY+bh-fh); d.hpFill.Visible = true
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Ontoy_STK"; screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local REDZ = {
    BG         = Color3.fromRGB(14,12,16),
    BG2        = Color3.fromRGB(20,16,22),
    Accent     = Color3.fromRGB(200,30,50),
    AccentDim  = Color3.fromRGB(120,20,35),
    AccentGlow = Color3.fromRGB(255,60,80),
    TextMain   = Color3.fromRGB(240,220,225),
    TextSub    = Color3.fromRGB(130,100,110),
    Stroke     = Color3.fromRGB(60,30,40),
    ToggleOff  = Color3.fromRGB(40,32,36),
    SliderFill = Color3.fromRGB(200,30,50),
    SliderBG   = Color3.fromRGB(35,28,32),
    Cyan       = Color3.fromRGB(0,200,255),
    Red        = Color3.fromRGB(255,60,60),
    Green      = Color3.fromRGB(50,200,80),
}

local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(0,520,0,440); mainWindow.Position = UDim2.new(0.5,-260,0.5,-220)
mainWindow.BackgroundColor3 = REDZ.BG; mainWindow.BorderSizePixel = 0
mainWindow.Active = true; mainWindow.Draggable = false; mainWindow.Parent = screenGui
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0,10)
local mainStroke = Instance.new("UIStroke", mainWindow)
mainStroke.Color = REDZ.Stroke; mainStroke.Thickness = 1.5

local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size = UDim2.new(1,0,0,42); titleBar.BackgroundColor3 = REDZ.BG2
titleBar.BorderSizePixel = 0; titleBar.Active = true
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local draggingWindow, dragStartMouse, dragStartPos = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingWindow = true
        dragStartMouse = Vector2.new(i.Position.X, i.Position.Y)
        dragStartPos = mainWindow.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if draggingWindow and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = Vector2.new(i.Position.X, i.Position.Y) - dragStartMouse
        mainWindow.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset+d.X,
                                        dragStartPos.Y.Scale, dragStartPos.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingWindow = false end
end)

local accentLine = Instance.new("Frame", titleBar)
accentLine.Size = UDim2.new(1,0,0,2); accentLine.Position = UDim2.new(0,0,1,-2)
accentLine.BackgroundColor3 = REDZ.Accent; accentLine.BorderSizePixel = 0

local dot = Instance.new("Frame", titleBar)
dot.Size = UDim2.new(0,8,0,8); dot.Position = UDim2.new(0,14,0.5,-4)
dot.BackgroundColor3 = REDZ.AccentGlow; dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(0,4)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size = UDim2.new(1,-160,1,0); titleText.Position = UDim2.new(0,30,0,0)
titleText.BackgroundTransparency = 1
titleText.Text = "ONTOY HUB  <font color='#C81E32'>·</font>  Survive The Killer"
titleText.RichText = true; titleText.TextColor3 = REDZ.TextMain
titleText.Font = Enum.Font.GothamBold; titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left

local byLabel = Instance.new("TextLabel", titleBar)
byLabel.Size = UDim2.new(0,80,1,0); byLabel.Position = UDim2.new(0,270,0,0)
byLabel.BackgroundTransparency = 1; byLabel.Text = "by ontoy"
byLabel.TextColor3 = REDZ.TextSub; byLabel.Font = Enum.Font.Gotham
byLabel.TextSize = 11; byLabel.TextXAlignment = Enum.TextXAlignment.Left

local function MakeWinBtn(parent, xOff, bg, txt)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0,26,0,26); b.Position = UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3 = bg; b.Text = txt; b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end
local closeBtn    = MakeWinBtn(titleBar, -34, REDZ.Accent, "✕")
local minimizeBtn = MakeWinBtn(titleBar, -66, REDZ.ToggleOff, "—")

local sidebar = Instance.new("Frame", mainWindow)
sidebar.Size = UDim2.new(0,138,1,-42); sidebar.Position = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = REDZ.BG2; sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", sidebar).Color = REDZ.Stroke
local sl = Instance.new("UIListLayout", sidebar)
sl.Padding = UDim.new(0,3); sl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0,12)

local contentArea = Instance.new("Frame", mainWindow)
contentArea.Size = UDim2.new(1,-146,1,-50); contentArea.Position = UDim2.new(0,142,0,46)
contentArea.BackgroundTransparency = 1; contentArea.BorderSizePixel = 0

local contentScroll = Instance.new("ScrollingFrame", contentArea)
contentScroll.Size = UDim2.new(1,0,1,0); contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0; contentScroll.ScrollBarThickness = 3
contentScroll.ScrollBarImageColor3 = REDZ.AccentDim
contentScroll.CanvasSize = UDim2.new(0,0,0,0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local cl = Instance.new("UIListLayout", contentScroll)
cl.Padding = UDim.new(0,6); cl.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentScroll).PaddingTop = UDim.new(0,8)

local pages, sidebarButtons = {}, {}

local function MakePage()
    local pg = Instance.new("Frame", contentScroll)
    pg.Size = UDim2.new(1,0,0,0); pg.AutomaticSize = Enum.AutomaticSize.Y
    pg.BackgroundTransparency = 1; pg.BorderSizePixel = 0; pg.Visible = false
    local lay = Instance.new("UIListLayout", pg)
    lay.Padding = UDim.new(0,6); lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Instance.new("UIPadding", pg).PaddingBottom = UDim.new(0,8)
    return pg
end

local function MakeSidebarBtn(icon, label, id)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1,-14,0,38); btn.BackgroundTransparency = 1
    btn.Text = ""; btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    local bar = Instance.new("Frame", btn)
    bar.Size = UDim2.new(0,3,0.6,0); bar.Position = UDim2.new(0,0,0.2,0)
    bar.BackgroundColor3 = REDZ.Accent; bar.BorderSizePixel = 0; bar.Visible = false
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,2)
    local iconL = Instance.new("TextLabel", btn)
    iconL.Size = UDim2.new(0,22,1,0); iconL.Position = UDim2.new(0,10,0,0)
    iconL.BackgroundTransparency = 1; iconL.Text = icon
    iconL.TextColor3 = REDZ.TextSub; iconL.Font = Enum.Font.GothamBold; iconL.TextSize = 14
    local labelL = Instance.new("TextLabel", btn)
    labelL.Size = UDim2.new(1,-38,1,0); labelL.Position = UDim2.new(0,36,0,0)
    labelL.BackgroundTransparency = 1; labelL.Text = label
    labelL.TextColor3 = REDZ.TextSub; labelL.Font = Enum.Font.Gotham; labelL.TextSize = 12
    labelL.TextXAlignment = Enum.TextXAlignment.Left
    sidebarButtons[id] = {btn=btn,icon=iconL,label=labelL,bar=bar}
    return btn
end

local function SetActivePage(id)
    for pid, pg in pairs(pages) do pg.Visible = (pid == id) end
    for bid, sb in pairs(sidebarButtons) do
        local a = (bid == id)
        sb.btn.BackgroundTransparency = a and 0 or 1
        sb.btn.BackgroundColor3 = a and Color3.fromRGB(30,18,22) or REDZ.ToggleOff
        sb.icon.TextColor3 = a and REDZ.AccentGlow or REDZ.TextSub
        sb.label.TextColor3 = a and REDZ.TextMain or REDZ.TextSub
        sb.bar.Visible = a
    end
end

local function MakeSection(parent, text, color)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1,-8,0,18); l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = color or REDZ.Accent
    l.Font = Enum.Font.GothamBold; l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function MakeToggle(parent, label, sub, ac)
    ac = ac or REDZ.Accent
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", row); stroke.Color = REDZ.Stroke; stroke.Thickness = 1
    local t = Instance.new("TextLabel", row)
    t.Size = UDim2.new(1,-60,0,22); t.Position = UDim2.new(0,14,0,8)
    t.BackgroundTransparency = 1; t.Text = label; t.TextColor3 = REDZ.TextMain
    t.Font = Enum.Font.GothamBold; t.TextSize = 12; t.TextXAlignment = Enum.TextXAlignment.Left
    if sub then
        local s = Instance.new("TextLabel", row)
        s.Size = UDim2.new(1,-60,0,16); s.Position = UDim2.new(0,14,0,28)
        s.BackgroundTransparency = 1; s.Text = sub; s.TextColor3 = REDZ.TextSub
        s.Font = Enum.Font.Gotham; s.TextSize = 10; s.TextXAlignment = Enum.TextXAlignment.Left
    end
    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(0,36,0,20); bg.Position = UDim2.new(1,-48,0.5,-10)
    bg.BackgroundColor3 = REDZ.ToggleOff; bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,10)
    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0,14,0,14); knob.Position = UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3 = REDZ.TextSub; knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
    local btn = Instance.new("TextButton", bg)
    btn.Size = UDim2.new(1,8,1,8); btn.Position = UDim2.new(0,-4,0,-4)
    btn.BackgroundTransparency = 1; btn.Text = ""; btn.BorderSizePixel = 0
    local state = false
    local function Set(s)
        state = s
        if s then
            bg.BackgroundColor3 = ac; knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            knob.Position = UDim2.new(1,-17,0.5,-7)
            row.BackgroundColor3 = Color3.fromRGB(24,14,18); stroke.Color = REDZ.AccentDim
        else
            bg.BackgroundColor3 = REDZ.ToggleOff; knob.BackgroundColor3 = REDZ.TextSub
            knob.Position = UDim2.new(0,3,0.5,-7)
            row.BackgroundColor3 = REDZ.BG2; stroke.Color = REDZ.Stroke
        end
    end
    btn.MouseButton1Click:Connect(function() Set(not state) end)
    return row, function() return state end, Set
end

local function MakeSlider(parent, label, dMin, dMax, initPct, unit, onChange)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,66); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", row).Color = REDZ.Stroke
    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(1,-80,0,20); tl.Position = UDim2.new(0,14,0,8)
    tl.BackgroundTransparency = 1; tl.Text = label; tl.TextColor3 = REDZ.TextMain
    tl.Font = Enum.Font.GothamBold; tl.TextSize = 12; tl.TextXAlignment = Enum.TextXAlignment.Left
    local vl = Instance.new("TextLabel", row)
    vl.Size = UDim2.new(0,70,0,20); vl.Position = UDim2.new(1,-78,0,8)
    vl.BackgroundTransparency = 1; vl.Font = Enum.Font.GothamBold; vl.TextSize = 12
    vl.TextColor3 = REDZ.AccentGlow; vl.TextXAlignment = Enum.TextXAlignment.Right
    local sbg = Instance.new("Frame", row)
    sbg.Size = UDim2.new(1,-28,0,5); sbg.Position = UDim2.new(0,14,0,42)
    sbg.BackgroundColor3 = REDZ.SliderBG; sbg.BorderSizePixel = 0
    Instance.new("UICorner", sbg).CornerRadius = UDim.new(0,3)
    local hit = Instance.new("TextButton", sbg)
    hit.Size = UDim2.new(1,0,0,28); hit.Position = UDim2.new(0,0,0.5,-14)
    hit.BackgroundTransparency = 1; hit.Text = ""; hit.BorderSizePixel = 0; hit.ZIndex = 5
    local fill = Instance.new("Frame", sbg)
    fill.Size = UDim2.new(initPct,0,1,0); fill.BackgroundColor3 = REDZ.SliderFill; fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)
    local knob = Instance.new("Frame", sbg)
    knob.Size = UDim2.new(0,14,0,14); knob.Position = UDim2.new(initPct,-7,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke", knob).Color = REDZ.Accent
    local drag = false
    local function Compute(px)
        local pct = math.clamp((px - sbg.AbsolutePosition.X)/sbg.AbsoluteSize.X,0,1)
        return pct, math.floor(dMin + (dMax-dMin)*pct)
    end
    local function Apply(pct, val)
        fill.Size = UDim2.new(pct,0,1,0); knob.Position = UDim2.new(pct,-7,0.5,-7)
        vl.Text = val..(unit or ""); if onChange then onChange(val,pct) end
    end
    Apply(initPct, math.floor(dMin+(dMax-dMin)*initPct))
    hit.MouseButton1Down:Connect(function() drag = true end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local p,v = Compute(i.Position.X); Apply(p,v)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    hit.MouseButton1Click:Connect(function()
        local m = UserInputService:GetMouseLocation()
        local p,v = Compute(m.X); Apply(p,v)
    end)
end

local function MakeActionBtn(parent, label, sub, color, onClick)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-8,0,52); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", row).Color = REDZ.Stroke
    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(1,-80,0,22); tl.Position = UDim2.new(0,14,0,8)
    tl.BackgroundTransparency = 1; tl.Text = label; tl.TextColor3 = REDZ.TextMain
    tl.Font = Enum.Font.GothamBold; tl.TextSize = 12; tl.TextXAlignment = Enum.TextXAlignment.Left
    if sub then
        local s = Instance.new("TextLabel", row)
        s.Size = UDim2.new(1,-80,0,16); s.Position = UDim2.new(0,14,0,28)
        s.BackgroundTransparency = 1; s.Text = sub; s.TextColor3 = REDZ.TextSub
        s.Font = Enum.Font.Gotham; s.TextSize = 10; s.TextXAlignment = Enum.TextXAlignment.Left
    end
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0,52,0,28); btn.Position = UDim2.new(1,-62,0.5,-14)
    btn.BackgroundColor3 = color or REDZ.Accent; btn.BorderSizePixel = 0
    btn.Text = "GO"; btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
end

local function MakePlayerTPWidget(parent)
    local con = Instance.new("Frame", parent)
    con.Size = UDim2.new(1,-8,0,0); con.AutomaticSize = Enum.AutomaticSize.Y
    con.BackgroundColor3 = REDZ.BG2; con.BorderSizePixel = 0
    Instance.new("UICorner", con).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", con).Color = REDZ.Stroke
    local lay = Instance.new("UIListLayout", con)
    lay.Padding = UDim.new(0,4); lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local pad = Instance.new("UIPadding", con)
    pad.PaddingTop = UDim.new(0,8); pad.PaddingBottom = UDim.new(0,8)
    local hdr = Instance.new("TextLabel", con)
    hdr.Size = UDim2.new(1,-16,0,18); hdr.BackgroundTransparency = 1
    hdr.Text = "TELEPORT TO PLAYER"; hdr.TextColor3 = REDZ.Accent
    hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 10
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    local function Refresh()
        for _, c in ipairs(con:GetChildren()) do
            if c ~= hdr and c:IsA("Frame") then c:Destroy() end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local kf = IsKiller(plr)
                local row = Instance.new("Frame", con)
                row.Size = UDim2.new(1,-8,0,36)
                row.BackgroundColor3 = Color3.fromRGB(26,18,22); row.BorderSizePixel = 0
                Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)
                local nl = Instance.new("TextLabel", row)
                nl.Size = UDim2.new(1,-60,1,0); nl.Position = UDim2.new(0,10,0,0)
                nl.BackgroundTransparency = 1
                nl.Text = plr.DisplayName .. (kf and " 🔪" or "")
                nl.TextColor3 = kf and Color3.fromRGB(255,100,100) or REDZ.TextMain
                nl.Font = Enum.Font.Gotham; nl.TextSize = 12
                nl.TextXAlignment = Enum.TextXAlignment.Left
                local tb = Instance.new("TextButton", row)
                tb.Size = UDim2.new(0,44,0,24); tb.Position = UDim2.new(1,-52,0.5,-12)
                tb.BackgroundColor3 = kf and Color3.fromRGB(180,40,40) or REDZ.Accent
                tb.BorderSizePixel = 0; tb.Text = "TP"
                tb.TextColor3 = Color3.fromRGB(255,255,255)
                tb.Font = Enum.Font.GothamBold; tb.TextSize = 11
                Instance.new("UICorner", tb).CornerRadius = UDim.new(0,5)
                tb.MouseButton1Click:Connect(function() TeleportToPlayer(plr) end)
            end
        end
    end
    Refresh()
    Players.PlayerAdded:Connect(Refresh)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); Refresh() end)
end

local movePage = MakePage(); pages["movement"] = movePage
local moveBtn  = MakeSidebarBtn("🏃","Movement","movement")
MakeSection(movePage, "SPEED")
local _, fastRunGet = MakeToggle(movePage, "Fast Run", "Override WalkSpeed")
MakeSlider(movePage, "Run Speed", BASE_SPEED, MAX_SPEED, 0.5, " ws", function(val, pct)
    CONFIG.SpeedPercent = pct * 100
end)
MakeSection(movePage, "JUMP")
local _, doubleGet   = MakeToggle(movePage, "Double Jump",   "Velocity-based — timing fixed")
local _, infiniteGet = MakeToggle(movePage, "Infinite Jump", "Lompat terus tanpa batas")

local visualPage = MakePage(); pages["visual"] = visualPage
local visualBtn  = MakeSidebarBtn("👁","Visual","visual")
MakeSection(visualPage, "SURVIVOR ESP", REDZ.Cyan)
local _, playerESPGet = MakeToggle(visualPage, "Player ESP", "Box + nama + HP — cyan", REDZ.Cyan)
MakeSection(visualPage, "KILLER ESP", REDZ.Red)
local _, killerESPGet = MakeToggle(visualPage, "Killer ESP", "Box + nama + HP — merah", REDZ.Red)
MakeSection(visualPage, "LOOT ESP")
local _, lootGet = MakeToggle(visualPage, "Loot ESP", "Nama + rarity + jarak — color per rarity")

local utilPage = MakePage(); pages["utility"] = utilPage
local utilBtn  = MakeSidebarBtn("⚡","Utility","utility")
MakeSection(utilPage, "AUTO LOOT", REDZ.Green)
local _, autoLootGet = MakeToggle(utilPage, "Auto Loot", "TP + ambil otomatis — whitelist only", REDZ.Green)
MakeActionBtn(utilPage, "Run Auto Loot", "Sekali jalan — semua loot di map", REDZ.Green, function()
    task.spawn(RunAutoLoot)
end)
MakeSection(utilPage, "TELEPORT")
MakeActionBtn(utilPage, "Teleport to Map",   "Ke area game aktif",        REDZ.Accent,    TeleportToMap)
MakeActionBtn(utilPage, "Teleport to Lobby", "Ke lobby — SpawnLocation",  REDZ.AccentDim, TeleportToLobby)
MakeSection(utilPage, "TELEPORT TO PLAYER")
MakePlayerTPWidget(utilPage)

local function Wire(getter, key, onOn, onOff)
    RunService.Heartbeat:Connect(function()
        local s = getter()
        if CONFIG[key] ~= s then
            CONFIG[key] = s
            if s then if onOn  then onOn()  end
            else      if onOff then onOff() end end
        end
    end)
end

Wire(fastRunGet,   "FastRun",      nil, function() LocalHumanoid.WalkSpeed = BASE_SPEED end)
Wire(doubleGet,    "DoubleJump",   function() CONFIG.InfiniteJump = false end)
Wire(infiniteGet,  "InfiniteJump", function() CONFIG.DoubleJump   = false end)
Wire(lootGet,      "LootESP")
Wire(playerESPGet, "PlayerESP")
Wire(killerESPGet, "KillerESP")
Wire(autoLootGet,  "AutoLoot",     function() task.spawn(RunAutoLoot) end)

moveBtn.MouseButton1Click:Connect(function()   SetActivePage("movement") end)
visualBtn.MouseButton1Click:Connect(function() SetActivePage("visual")   end)
utilBtn.MouseButton1Click:Connect(function()   SetActivePage("utility")  end)
SetActivePage("movement")

local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
    contentVisible = not contentVisible
    sidebar.Visible = contentVisible; contentArea.Visible = contentVisible
    mainWindow.Size = contentVisible and UDim2.new(0,520,0,440) or UDim2.new(0,520,0,42)
end)
closeBtn.MouseButton1Click:Connect(function()
    LocalHumanoid.WalkSpeed = BASE_SPEED; CONFIG.AutoLoot = false
    for _, d in pairs(lootESP)   do RemoveLootDraw(d)    end
    for _, d in pairs(playerESP) do RemovePlayerDraw(d)  end
    screenGui:Destroy()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot     = char:WaitForChild("HumanoidRootPart")
    LocalHumanoid = char:WaitForChild("Humanoid")
    jumpCount = 0; canDoubleJump = false
    if stateConn then stateConn:Disconnect() end
    stateConn = LocalHumanoid.StateChanged:Connect(OnStateChanged)
    if CONFIG.FastRun then LocalHumanoid.WalkSpeed = GetTargetSpeed() end
end)

RunService.RenderStepped:Connect(function()
    if CONFIG.FastRun then ApplySpeed() end
    RenderLootESP()
    RenderPlayerESP()
end)

task.spawn(function()
    while task.wait(0.5) do
        if CONFIG.AutoLoot and not autoLootRunning then
            RunAutoLoot()
        end
    end
end)
