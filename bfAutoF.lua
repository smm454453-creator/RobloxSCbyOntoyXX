-- ── SKILL LOCK (tambahan module, standalone — plug ke script existing) ────────
local SkillLock = {}

local SKILL_KEYS = {
    [Enum.KeyCode.Z] = true,
    [Enum.KeyCode.X] = true,
    [Enum.KeyCode.C] = true,
    [Enum.KeyCode.V] = true,
    [Enum.KeyCode.F] = true, -- melee M1 alt bind sebagian device
}

CONFIG.Mode10 = false          -- Skill Lock toggle
CONFIG.SkillLockRange = 60     -- studs, jarak maksimal target

local function GetSkillLockTarget()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, bestScore = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local pRoot = char:FindFirstChild("HumanoidRootPart")
        local hum   = char:FindFirstChild("Humanoid")
        if not (pRoot and hum and hum.Health > 0) then continue end

        local dist = (pRoot.Position - root.Position).Magnitude
        if dist > CONFIG.SkillLockRange then continue end

        local screenPos, onScreen = Camera:WorldToScreenPoint(pRoot.Position)
        if not onScreen then continue end

        local vp = Camera.ViewportSize
        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(vp.X/2, vp.Y/2)).Magnitude
        local score = dist * 0.3 + screenDist * 0.7

        if score < bestScore then
            bestScore = score
            best = char
        end
    end
    return best
end

-- Snap sesaat pas skill fire, restore sesudahnya — kamera lo kaga kebawa jauh
local function ExecuteSkillLock()
    if not CONFIG.Mode10 then return end
    local target = GetSkillLockTarget()
    if not target then return end
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot or not myRoot then return end

    -- rotate root menghadap target — cukup buat sebagian besar skill fruit/sword yang directional
    local lookCF = CFrame.new(myRoot.Position, Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z))
    myRoot.CFrame = lookCF

    -- fire attack registration langsung ke target biar hitbox kena walau delay animasi
    if RegisterAttack then
        pcall(function() RegisterAttack:FireServer(targetRoot) end)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if SKILL_KEYS[input.KeyCode] then
        task.spawn(ExecuteSkillLock)
    end
end)

-- Support klik M1 (mouse) sebagai melee trigger juga
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and CONFIG.Mode10 then
        task.spawn(ExecuteSkillLock)
    end
end)
