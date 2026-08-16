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

-- ── RARITY ────────────────────────────────────────────────────────────────────
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
    if RARITY_DATA[name] then return RARITY_DATA[name] end
    for key, data in pairs(RARITY_DATA) do
        if string.find(name, key, 1, true) then return data end
    end
    return nil
end

-- ── PLAYER CLASSIFICATION ─────────────────────────────────────────────────────
-- Set semua character model yang ada — biar IsLoot bisa exclude mereka
local function GetAllCharacterModels()
    local chars = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            chars[plr.Character] = true
        end
    end
    return chars
end

-- Cek apakah instance ini bagian dari character player/killer
local function IsCharacterPart(instance)
    local chars = GetAllCharacterModels()
    local obj = instance
    while obj do
        if chars[obj] then return true end
        obj = obj.Parent
    end
    return false
end

-- Cek apakah instance ada di dalam Backpack / Tool player
local function IsInPlayerBackpack(instance)
    local obj = instance
    while obj do
        if obj:IsA("Backpack") then return true end
        if obj:IsA("Tool") then
            local parent = obj.Parent
            if parent and (parent:IsA("Backpack") or parent == LocalCharacter) then
                return true
            end
        end
        obj = obj.Parent
    end
    return false
end

-- STK: killer biasanya punya tag "Killer" di name atau attribute,
-- atau satu-satunya player yang teamnya beda / health jauh lebih tinggi
local function IsKiller(plr)
    if not plr.Character then return false end
    local humanoid = plr.Character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return false end
    -- Heuristik: max health > 200 = killer (survivor default 100)
    if humanoid.MaxHealth > 200 then return true end
    -- Cek nama tag / label di atas kepala
    local overhead = plr.Character:FindFirstChild("Overhead")
        or plr.Character:FindFirstChild("HumanoidRootPart")
    if overhead then
        local billboards = overhead:GetDescendants()
        for _, v in ipairs(billboards) do
            if v:IsA("TextLabel") then
                local txt = v.Text:lower()
                if string.find(txt, "killer") then return true end
            end
        end
    end
    -- Fallback: cek team
    if plr.Team and plr.Team.Name:lower():find("killer") then return true end
    return false
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

-- ── DOUBLE JUMP ───────────────────────────────────────────────────────────────
local jumpCount     = 0
local maxJumps      = 2
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
        jumpCount     = 0
        canDoubleJump = false
    end
end

local stateConn = LocalHumanoid.StateChanged:Connect(OnStateChanged)

UserInputService.JumpRequest:Connect(function()
    if CONFIG.InfiniteJump then
        LocalHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        return
    end
    if CONFIG.DoubleJump and canDoubleJump and jumpCount < maxJumps then
        jumpCount     = jumpCount + 1
        canDoubleJump = false
        local rootPart = LocalCharacter:FindFirstChild("HumanoidRootPart")
        if rootPart and rootPart:IsA("BasePart") then
            local vel = rootPart.AssemblyLinearVelocity
            rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, 50, vel.Z)
        end
    end
end)

-- ── LOOT DETECTION ────────────────────────────────────────────────────────────
local function IsLootInstance(instance)
    -- Exclude: bukan part/model yang valid
    if not (instance:IsA("Model") or instance:IsA("Part")
        or instance:IsA("MeshPart") or instance:IsA("UnionOperation")) then
        return false
    end
    -- CRITICAL FIX: exclude semua yang ada Humanoid (player/NPC/killer character)
    if instance:IsA("Model") and instance:FindFirstChildWhichIsA("Humanoid") then
        return false
    end
    -- Exclude jika bagian dari character player
    if IsCharacterPart(instance) then return false end
    -- Exclude jika di dalam backpack/tool
    if IsInPlayerBackpack(instance) then return false end
    -- Cek nama match rarity
    if GetRarity(instance.Name) then return true end
    -- Cek parent folder name
    local parent = instance.Parent
    if parent then
        local pn = parent.Name:lower()
        if pn == "loot" or pn == "drops" or pn == "items" or pn == "weapons"
        or pn == "pickups" or pn == "collectibles" then
            return true
        end
    end
    return false
end

local function GetLootPart(instance)
    if instance:IsA("Model") then
        return instance.PrimaryPart
            or instance:FindFirstChildWhichIsA("MeshPart")
            or instance:FindFirstChildWhichIsA("Part")
    end
    return instance
end

-- ── AUTO LOOT ─────────────────────────────────────────────────────────────────
local function GetAllLoot()
    local result = {}
    local function ScanFolder(folder)
        for _, child in ipairs(folder:GetChildren()) do
            if IsLootInstance(child) then
                table.insert(result, child)
            elseif child:IsA("Folder") or child:IsA("Model") then
                ScanFolder(child)
            end
        end
    end
    ScanFolder(Workspace)
    return result
end

local function TryPickup(instance)
    local prompt = instance:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then pcall(fireproximityprompt, prompt); return end
    local re = instance:FindFirstChildWhichIsA("RemoteEvent", true)
    if re then pcall(function() re:FireServer() end); return end
    local cd = instance:FindFirstChildWhichIsA("ClickDetector", true)
    if cd then pcall(fireclickdetector, cd); return end
end

local autoLootRunning = false

local function RunAutoLoot()
    if autoLootRunning then return end
    autoLootRunning = true
    local loots = GetAllLoot()
    table.sort(loots, function(a, b)
        local pa = GetLootPart(a)
        local pb = GetLootPart(b)
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
            task.wait(0.08)   -- turun dari 0.35 → 0.08, cukup buat server register
            TryPickup(loot)
            task.wait(0.05)
        end
    end
    autoLootRunning = false
end

-- ── TELEPORT ──────────────────────────────────────────────────────────────────
-- Cari BasePart yang valid di workspace — bukan milik karakter manapun,
-- bukan Terrain, CanCollide true, posisi Y > -50 (exclude void parts)
local function FindSafeLandingPart(root)
    local best = nil
    local bestDist = math.huge
    local chars = GetAllCharacterModels()

    local function ScanObj(obj)
        if obj:IsA("BasePart") and obj ~= Terrain
        and obj.CanCollide and obj.Size.Y >= 0.5
        and obj.Position.Y > -50 then
            -- Bukan bagian dari character
            local isChar = false
            local check = obj
            while check do
                if chars[check] then isChar = true; break end
                check = check.Parent
            end
            if not isChar then
                local dist = (obj.Position - (root or Vector3.new(0,0,0))).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    best = obj
                end
            end
        end
        for _, c in ipairs(obj:GetChildren()) do
            ScanObj(c)
        end
    end

    -- Scan nama-nama folder yang umum di STK dulu
    local mapFolders = {"Map", "GameArea", "Arena", "Stage", "Level", "PlayArea", "Round", "Game"}
    for _, name in ipairs(mapFolders) do
        local folder = Workspace:FindFirstChild(name)
        if folder then
            ScanObj(folder)
            if best then return best end
        end
    end
    -- Fallback: scan seluruh workspace tapi skip folder karakter
    for _, child in ipairs(Workspace:GetChildren()) do
        local isPlayerChar = false
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character == child then isPlayerChar = true; break end
        end
        if not isPlayerChar then
            ScanObj(child)
        end
    end
    return best
end

local function TeleportToMap()
    -- Referensi: cari player lain yang udah di dalam game (bukan lobby)
    -- sebagai anchor posisi, lalu cari BasePart di sekitar mereka
    local refPos = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root and root.Position.Y > -50 then
                refPos = root.Position
                break
            end
        end
    end

    -- Cari landing part yang paling dekat ke refPos (atau origin)
    local anchor = refPos or Vector3.new(0, 50, 0)
    local landPart = FindSafeLandingPart(anchor)
    if landPart then
        -- Raycast ke bawah dari part surface buat pastiin ada floor
        local rayOrigin = landPart.Position + Vector3.new(0, 5, 0)
        local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -20, 0))
        local landY = rayResult and (rayResult.Position.Y + 3) or (landPart.Position.Y + 3)
        LocalRoot.CFrame = CFrame.new(Vector3.new(landPart.Position.X, landY, landPart.Position.Z))
        return true
    end
    -- Last resort: teleport ke dekat player lain (offset 5 stud)
    if refPos then
        LocalRoot.CFrame = CFrame.new(refPos + Vector3.new(5, 3, 0))
        return true
    end
    return false
end

local function TeleportToLobby()
    -- Lobby di STK: SpawnLocation di Y yang valid (bukan void)
    -- Raycast ke bawah SpawnLocation dulu sebelum teleport
    local spawnLoc = Workspace:FindFirstChildWhichIsA("SpawnLocation")
    if spawnLoc and spawnLoc.Position.Y > -50 then
        local ray = Workspace:Raycast(
            spawnLoc.Position + Vector3.new(0, 10, 0),
            Vector3.new(0, -30, 0)
        )
        if ray then
            LocalRoot.CFrame = CFrame.new(ray.Position + Vector3.new(0, 3, 0))
            return true
        else
            -- SpawnLocation ada tapi raycast miss — pakai posisi spawn langsung
            LocalRoot.CFrame = CFrame.new(spawnLoc.Position + Vector3.new(0, 5, 0))
            return true
        end
    end

    -- Cari folder lobby by name
    local lobbyNames = {"Lobby", "Waiting", "WaitingRoom", "WaitArea", "Hub", "Menu"}
    for _, name in ipairs(lobbyNames) do
        local obj = Workspace:FindFirstChild(name)
            or Workspace:FindFirstChild(name, true)
        if obj then
            local function FindFloorPart(o)
                if o:IsA("BasePart") and o.CanCollide and o.Position.Y > -50 then
                    return o
                end
                for _, c in ipairs(o:GetChildren()) do
                    local f = FindFloorPart(c)
                    if f then return f end
                end
            end
            local p = FindFloorPart(obj)
            if p then
                LocalRoot.CFrame = CFrame.new(p.Position + Vector3.new(0, 5, 0))
                return true
            end
        end
    end

    -- STK fallback: scan semua SpawnLocation di workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") and obj.Position.Y > -50 then
            LocalRoot.CFrame = CFrame.new(obj.Position + Vector3.new(0, 5, 0))
            return true
        end
    end

    return false
end

local function TeleportToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local root = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    LocalRoot.CFrame = CFrame.new(root.Position + Vector3.new(3, 2, 0))
    return true
end

-- ── ESP DRAWING HELPERS ───────────────────────────────────────────────────────
local function NewText(size, color, outline)
    local t = Drawing.new("Text")
    t.Size = size or 13
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.fromRGB(0,0,0)
    t.Color = color or Color3.fromRGB(255,255,255)
    t.Visible = false
    t.Font = Drawing.Fonts.Plex
    return t
end

local function NewBox(color, thickness)
    local b = Drawing.new("Square")
    b.Thickness = thickness or 1.5
    b.Filled = false
    b.Color = color or Color3.fromRGB(255,255,255)
    b.Visible = false
    return b
end

local function NewLine(color, thickness)
    local l = Drawing.new("Line")
    l.Thickness = thickness or 1
    l.Color = color or Color3.fromRGB(255,255,255)
    l.Visible = false
    return l
end

-- ── LOOT ESP ──────────────────────────────────────────────────────────────────
local lootESP = {}

local function CreateLootESP()
    return {
        nameTag = NewText(13, Color3.fromRGB(255,255,255)),
        distTag = NewText(11, Color3.fromRGB(200,200,200)),
        box     = NewBox(Color3.fromRGB(255,255,255), 1),
    }
end

local function RemoveLootESP(obj)
    obj.nameTag:Remove(); obj.distTag:Remove(); obj.box:Remove()
end

local function HideLootESP(obj)
    obj.nameTag.Visible = false
    obj.distTag.Visible = false
    obj.box.Visible = false
end

local lastLootScan = 0

local function ScanLoot()
    -- Cleanup stale
    for inst, obj in pairs(lootESP) do
        if not inst or not inst.Parent then
            RemoveLootESP(obj)
            lootESP[inst] = nil
        end
    end
    -- Scan baru
    local function CheckAdd(inst)
        if not lootESP[inst] and IsLootInstance(inst) then
            lootESP[inst] = CreateLootESP()
        end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        CheckAdd(child)
        if child:IsA("Folder") or child:IsA("Model") then
            for _, sub in ipairs(child:GetChildren()) do
                CheckAdd(sub)
            end
        end
    end
end

local function RenderLootESP()
    local now = tick()
    if now - lastLootScan > 2 then
        ScanLoot()
        lastLootScan = now
    end
    if not CONFIG.LootESP then
        for _, obj in pairs(lootESP) do HideLootESP(obj) end
        return
    end
    for inst, obj in pairs(lootESP) do
        if inst and inst.Parent then
            local part = GetLootPart(inst)
            if part then
                local screen, onScreen = Camera:WorldToScreenPoint(part.Position)
                if onScreen then
                    local dist = math.floor((part.Position - LocalRoot.Position).Magnitude)
                    if dist <= 300 then
                        local rd = GetRarity(inst.Name) or { rarity = "?", color = Color3.fromRGB(200,200,200) }
                        local scale = math.clamp(1 - dist/300, 0.4, 1)
                        local tsz = math.floor(11*scale + 4)
                        obj.nameTag.Text = inst.Name .. " [" .. rd.rarity .. "]"
                        obj.nameTag.Color = rd.color
                        obj.nameTag.Size = tsz
                        obj.nameTag.Position = Vector2.new(screen.X, screen.Y - 18)
                        obj.nameTag.Visible = true
                        obj.distTag.Text = dist .. "m"
                        obj.distTag.Size = math.max(tsz - 2, 9)
                        obj.distTag.Position = Vector2.new(screen.X, screen.Y - 4)
                        obj.distTag.Visible = true
                        local boxSz = math.clamp(40*scale, 14, 40)
                        obj.box.Color = rd.color
                        obj.box.Size = Vector2.new(boxSz, boxSz)
                        obj.box.Position = Vector2.new(screen.X - boxSz/2, screen.Y - boxSz/2)
                        obj.box.Visible = true
                    else HideLootESP(obj) end
                else HideLootESP(obj) end
            else HideLootESP(obj) end
        else HideLootESP(obj) end
    end
end

-- ── PLAYER ESP ────────────────────────────────────────────────────────────────
-- Survivor: warna cyan. Killer: warna merah/orange.
-- Box ESP + nama + distance + health bar

local playerESP = {}  -- key: Player instance

local function CreatePlayerESPObj(isKillerFlag)
    local boxColor = isKillerFlag and Color3.fromRGB(255,60,60) or Color3.fromRGB(0,220,255)
    return {
        nameTag  = NewText(13, boxColor),
        distTag  = NewText(11, Color3.fromRGB(200,200,200)),
        box      = NewBox(boxColor, 1.5),
        hpBar    = Drawing.new("Square"),   -- background
        hpFill   = Drawing.new("Square"),   -- fill
        isKiller = isKillerFlag,
    }
end

local function RemovePlayerESPObj(obj)
    obj.nameTag:Remove(); obj.distTag:Remove()
    obj.box:Remove(); obj.hpBar:Remove(); obj.hpFill:Remove()
end

local function HidePlayerESPObj(obj)
    obj.nameTag.Visible = false; obj.distTag.Visible = false
    obj.box.Visible = false; obj.hpBar.Visible = false; obj.hpFill.Visible = false
end

local function InitHPBar(obj)
    obj.hpBar.Filled = true
    obj.hpBar.Color = Color3.fromRGB(30,30,30)
    obj.hpBar.Visible = false

    obj.hpFill.Filled = true
    obj.hpFill.Color = Color3.fromRGB(50,220,80)
    obj.hpFill.Visible = false
end

local function RenderPlayerESP()
    -- Sync player list
    for plr, obj in pairs(playerESP) do
        if not plr or not plr.Parent then
            RemovePlayerESPObj(obj)
            playerESP[plr] = nil
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not playerESP[plr] then
            local killerFlag = IsKiller(plr)
            local obj = CreatePlayerESPObj(killerFlag)
            InitHPBar(obj)
            playerESP[plr] = obj
        end
    end

    for plr, obj in pairs(playerESP) do
        -- Cek toggle: killer atau survivor
        local showThis = (obj.isKiller and CONFIG.KillerESP)
                      or (not obj.isKiller and CONFIG.PlayerESP)

        if not showThis then HidePlayerESPObj(obj); continue end
        if not plr.Character then HidePlayerESPObj(obj); continue end

        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        local hum  = plr.Character:FindFirstChildWhichIsA("Humanoid")
        if not root or not hum then HidePlayerESPObj(obj); continue end

        local screen, onScreen = Camera:WorldToScreenPoint(root.Position)
        if not onScreen then HidePlayerESPObj(obj); continue end

        local dist = math.floor((root.Position - LocalRoot.Position).Magnitude)
        if dist > 500 then HidePlayerESPObj(obj); continue end

        local scale = math.clamp(1 - dist/500, 0.3, 1)
        local boxH  = math.clamp(math.floor(80 * scale), 20, 80)
        local boxW  = math.floor(boxH * 0.55)
        local boxX  = screen.X - boxW/2
        local boxY  = screen.Y - boxH/2

        local boxColor = obj.isKiller
            and Color3.fromRGB(255,60,60)
            or  Color3.fromRGB(0,220,255)

        -- Box
        obj.box.Color    = boxColor
        obj.box.Size     = Vector2.new(boxW, boxH)
        obj.box.Position = Vector2.new(boxX, boxY)
        obj.box.Visible  = true

        -- Name
        local tsz = math.floor(10*scale + 3)
        obj.nameTag.Text     = plr.DisplayName .. (obj.isKiller and " [KILLER]" or "")
        obj.nameTag.Color    = boxColor
        obj.nameTag.Size     = tsz
        obj.nameTag.Position = Vector2.new(screen.X, boxY - tsz - 2)
        obj.nameTag.Visible  = true

        -- Distance
        obj.distTag.Text     = dist .. "m"
        obj.distTag.Size     = math.max(tsz - 2, 9)
        obj.distTag.Position = Vector2.new(screen.X, boxY + boxH + 2)
        obj.distTag.Visible  = true

        -- HP bar (kiri box, vertikal)
        local hpPct  = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local barH   = boxH
        local barW   = 3
        local barX   = boxX - barW - 2
        local barY   = boxY

        obj.hpBar.Size     = Vector2.new(barW, barH)
        obj.hpBar.Position = Vector2.new(barX, barY)
        obj.hpBar.Visible  = true

        obj.hpFill.Color   = Color3.fromRGB(
            math.floor(255*(1-hpPct)),
            math.floor(220*hpPct),
            50
        )
        obj.hpFill.Size     = Vector2.new(barW, math.floor(barH * hpPct))
        obj.hpFill.Position = Vector2.new(barX, barY + barH - math.floor(barH * hpPct))
        obj.hpFill.Visible  = true
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
    Cyan       = Color3.fromRGB(0, 200, 255),
    CyanDim    = Color3.fromRGB(0, 120, 180),
    Orange     = Color3.fromRGB(255, 140, 0),
    Green      = Color3.fromRGB(50, 200, 80),
    GreenDim   = Color3.fromRGB(30, 120, 50),
}

local mainWindow = Instance.new("Frame")
mainWindow.Size             = UDim2.new(0, 520, 0, 440)
mainWindow.Position         = UDim2.new(0.5, -260, 0.5, -220)
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

local function MakeSectionLabel(parent, text, color)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, -8, 0, 18); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = color or REDZ.Accent
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local function MakeToggleRow(parent, label, sublabel, accentColor)
    local ac = accentColor or REDZ.Accent
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
            toggleBG.BackgroundColor3   = ac
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
    Instance.new("UIStroke", row).Color = REDZ.Stroke
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
    Instance.new("UIStroke", knob).Color = REDZ.Accent
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

local function MakeActionButton(parent, label, sublabel, color, onClick)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -8, 0, 52); row.BackgroundColor3 = REDZ.BG2; row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", row).Color = REDZ.Stroke
    local title = Instance.new("TextLabel", row)
    title.Size = UDim2.new(1, -80, 0, 22); title.Position = UDim2.new(0, 14, 0, 8)
    title.BackgroundTransparency = 1; title.Text = label
    title.TextColor3 = REDZ.TextMain; title.Font = Enum.Font.GothamBold; title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    if sublabel then
        local sub = Instance.new("TextLabel", row)
        sub.Size = UDim2.new(1, -80, 0, 16); sub.Position = UDim2.new(0, 14, 0, 28)
        sub.BackgroundTransparency = 1; sub.Text = sublabel
        sub.TextColor3 = REDZ.TextSub; sub.Font = Enum.Font.Gotham; sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
    end
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0, 52, 0, 28); btn.Position = UDim2.new(1, -62, 0.5, -14)
    btn.BackgroundColor3 = color or REDZ.Accent; btn.BorderSizePixel = 0
    btn.Text = "GO"; btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
    return row, btn
end

local function MakePlayerTeleportWidget(parent)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -8, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundColor3 = REDZ.BG2; container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", container).Color = REDZ.Stroke
    local lay = Instance.new("UIListLayout", container)
    lay.Padding = UDim.new(0, 4)
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local pad = Instance.new("UIPadding", container)
    pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)

    local header = Instance.new("TextLabel", container)
    header.Size = UDim2.new(1, -16, 0, 18)
    header.BackgroundTransparency = 1; header.Text = "TELEPORT TO PLAYER"
    header.TextColor3 = REDZ.Accent; header.Font = Enum.Font.GothamBold
    header.TextSize = 10; header.TextXAlignment = Enum.TextXAlignment.Left

    local function Refresh()
        for _, child in ipairs(container:GetChildren()) do
            if child ~= header and child:IsA("Frame") then child:Destroy() end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local killerFlag = IsKiller(plr)
                local row = Instance.new("Frame", container)
                row.Size = UDim2.new(1, -8, 0, 36)
                row.BackgroundColor3 = Color3.fromRGB(26,18,22); row.BorderSizePixel = 0
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                local nameLabel = Instance.new("TextLabel", row)
                nameLabel.Size = UDim2.new(1, -60, 1, 0); nameLabel.Position = UDim2.new(0, 10, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = plr.DisplayName .. (killerFlag and " 🔪" or "")
                nameLabel.TextColor3 = killerFlag and Color3.fromRGB(255,100,100) or REDZ.TextMain
                nameLabel.Font = Enum.Font.Gotham; nameLabel.TextSize = 12
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                local tpBtn = Instance.new("TextButton", row)
                tpBtn.Size = UDim2.new(0, 44, 0, 24); tpBtn.Position = UDim2.new(1, -52, 0.5, -12)
                tpBtn.BackgroundColor3 = killerFlag and Color3.fromRGB(180,40,40) or REDZ.Accent
                tpBtn.BorderSizePixel = 0; tpBtn.Text = "TP"
                tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
                tpBtn.Font = Enum.Font.GothamBold; tpBtn.TextSize = 11
                Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 5)
                tpBtn.MouseButton1Click:Connect(function() TeleportToPlayer(plr) end)
            end
        end
    end

    Refresh()
    Players.PlayerAdded:Connect(Refresh)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); Refresh() end)
    return container
end

-- ── BUILD PAGES ───────────────────────────────────────────────────────────────
local movePage = MakePage(); pages["movement"] = movePage
local moveBtn  = MakeSidebarBtn("🏃", "Movement", "movement")

MakeSectionLabel(movePage, "SPEED")
local _, fastRunGet, _ = MakeToggleRow(movePage, "Fast Run", "Override WalkSpeed")
MakeSliderRow(movePage, "Run Speed", BASE_SPEED, MAX_SPEED, 0.5, " ws", function(val, pct)
    CONFIG.SpeedPercent = pct * 100
end)
MakeSectionLabel(movePage, "JUMP")
local _, doubleGet,   _ = MakeToggleRow(movePage, "Double Jump",   "Velocity-based — timing fixed")
local _, infiniteGet, _ = MakeToggleRow(movePage, "Infinite Jump", "Lompat terus tanpa batas")

local visualPage = MakePage(); pages["visual"] = visualPage
local visualBtn  = MakeSidebarBtn("👁", "Visual", "visual")

MakeSectionLabel(visualPage, "SURVIVOR ESP", REDZ.Cyan)
local _, playerESPGet, _ = MakeToggleRow(visualPage, "Player ESP",
    "Box + nama + HP — cyan", REDZ.Cyan)

MakeSectionLabel(visualPage, "KILLER ESP", Color3.fromRGB(255,60,60))
local _, killerESPGet, _ = MakeToggleRow(visualPage, "Killer ESP",
    "Box + nama + HP — merah", Color3.fromRGB(255,60,60))

MakeSectionLabel(visualPage, "LOOT ESP")
local _, lootGet, _ = MakeToggleRow(visualPage, "Loot ESP",
    "Nama + rarity + jarak — color per rarity")

local utilPage = MakePage(); pages["utility"] = utilPage
local utilBtn  = MakeSidebarBtn("⚡", "Utility", "utility")

MakeSectionLabel(utilPage, "AUTO LOOT", REDZ.Green)
local _, autoLootGet, _ = MakeToggleRow(utilPage, "Auto Loot",
    "TP + ambil otomatis — 0.08s per item", REDZ.Green)
MakeActionButton(utilPage, "Run Auto Loot", "Sekali jalan — semua loot di map",
    REDZ.Green, function() task.spawn(RunAutoLoot) end)

MakeSectionLabel(utilPage, "TELEPORT")
MakeActionButton(utilPage, "Teleport to Map",   "Masuk ke area game aktif",  REDZ.Accent, TeleportToMap)
MakeActionButton(utilPage, "Teleport to Lobby", "Balik ke lobby — raycast fixed", REDZ.AccentDim, TeleportToLobby)

MakeSectionLabel(utilPage, "TELEPORT TO PLAYER")
MakePlayerTeleportWidget(utilPage)

-- ── WIRE ──────────────────────────────────────────────────────────────────────
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

WireToggle(fastRunGet,    "FastRun", nil, function() LocalHumanoid.WalkSpeed = BASE_SPEED end)
WireToggle(doubleGet,     "DoubleJump",   function() CONFIG.InfiniteJump = false end)
WireToggle(infiniteGet,   "InfiniteJump", function() CONFIG.DoubleJump   = false end)
WireToggle(lootGet,       "LootESP")
WireToggle(playerESPGet,  "PlayerESP")
WireToggle(killerESPGet,  "KillerESP")
WireToggle(autoLootGet,   "AutoLoot", function() task.spawn(RunAutoLoot) end)

moveBtn.MouseButton1Click:Connect(function()   SetActivePage("movement") end)
visualBtn.MouseButton1Click:Connect(function() SetActivePage("visual")   end)
utilBtn.MouseButton1Click:Connect(function()   SetActivePage("utility")  end)
SetActivePage("movement")

local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
    contentVisible = not contentVisible
    sidebar.Visible = contentVisible; contentArea.Visible = contentVisible
    mainWindow.Size = contentVisible and UDim2.new(0, 520, 0, 440) or UDim2.new(0, 520, 0, 42)
end)

closeBtn.MouseButton1Click:Connect(function()
    LocalHumanoid.WalkSpeed = BASE_SPEED
    CONFIG.AutoLoot = false
    for _, obj in pairs(lootESP)    do RemoveLootESP(obj)    end
    for _, obj in pairs(playerESP)  do RemovePlayerESPObj(obj) end
    screenGui:Destroy()
end)

-- ── RESPAWN ───────────────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalRoot      = char:WaitForChild("HumanoidRootPart")
    LocalHumanoid  = char:WaitForChild("Humanoid")
    jumpCount = 0; canDoubleJump = false
    if stateConn then stateConn:Disconnect() end
    stateConn = LocalHumanoid.StateChanged:Connect(OnStateChanged)
    if CONFIG.FastRun then LocalHumanoid.WalkSpeed = GetTargetSpeed() end
end)

-- ── RENDER LOOP ───────────────────────────────────────────────────────────────
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
