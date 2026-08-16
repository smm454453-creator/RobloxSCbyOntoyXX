-- ============================================================
-- SEA NAVIGATION HUB — Standalone Script (Edited for Blox Fruits)
-- Style: Ontoy Hub (dark red theme)
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local function GetChar()
	return LocalPlayer.Character
end

local function GetRoot()
	local char = GetChar()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
	local char = GetChar()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetSeatAndBoat()
	local hum = GetHumanoid()
	if not hum then return nil, nil end
	local seat = hum.SeatPart
	if not seat then return nil, nil end
	local boat = seat.Parent
	if not boat or not boat:IsA("Model") then return nil, nil end
	return seat, boat
end

-- ── STATE — Semua variabel kontrol ada di sini ─────────────────────────────
local S = {
	waterWalkConn   = nil,
	waterPlatform   = nil,
	waterWalkHeight = 20,
	
	clearVisionConn = nil,
	
	hoverBoatConn   = nil,
	hoverHeight     = 45,
	
	boatSpeedConn   = nil,
	boatSpeedValue  = 100,
	
	collisionConn   = nil,
	
	walkSpeedConn   = nil,
	walkSpeedValue  = 16,
	
	jumpPowerConn   = nil,
	jumpPowerValue  = 50,
}

-- ────────────────────────────────────────────────────────────────────────────
-- 1. WATER WALK (Customizable Y Offset)
-- ────────────────────────────────────────────────────────────────────────────
local function StartWaterWalk()
	if S.waterWalkConn then return end

	local plat          = Instance.new("Part")
	plat.Name           = "SeaNav_WaterPlatform"
	plat.Size           = Vector3.new(50, 1, 50)
	plat.Anchored       = true
	plat.CanCollide     = true
	plat.Transparency   = 1
	plat.Parent         = Workspace
	S.waterPlatform     = plat

	S.waterWalkConn = RunService.RenderStepped:Connect(function()
		local root = GetRoot()
		if not root then return end
		plat.CFrame = CFrame.new(root.Position.X, S.waterWalkHeight, root.Position.Z)
	end)
end

local function StopWaterWalk()
	if S.waterWalkConn then
		S.waterWalkConn:Disconnect()
		S.waterWalkConn = nil
	end
	if S.waterPlatform then
		S.waterPlatform:Destroy()
		S.waterPlatform = nil
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- 2. CLEAR VISION
-- ────────────────────────────────────────────────────────────────────────────
local function StartClearVision()
	if S.clearVisionConn then return end
	S.clearVisionConn = true

	task.spawn(function()
		while S.clearVisionConn do
			Lighting.Brightness    = 2
			Lighting.ClockTime     = 12
			Lighting.FogEnd        = 100000
			Lighting.GlobalShadows = false
			for _, obj in ipairs(Lighting:GetChildren()) do
				if obj:IsA("Atmosphere") or obj:IsA("ColorCorrectionEffect") then
					pcall(function() obj.Enabled = false end)
				end
			end
			task.wait(1)
		end
	end)
end

local function StopClearVision()
	S.clearVisionConn = nil
end

-- ────────────────────────────────────────────────────────────────────────────
-- 3. HOVER BOAT (Customizable Y Offset)
-- ────────────────────────────────────────────────────────────────────────────
local function StartHoverBoat()
	if S.hoverBoatConn then return end
	S.hoverBoatConn = RunService.Heartbeat:Connect(function()
		local seat, boat = GetSeatAndBoat()
		if not seat or not boat then return end
		local primary = boat.PrimaryPart or seat
		if not primary then return end
		
		local pos = primary.Position
		if math.abs(pos.Y - S.hoverHeight) > 2 then
			local cf = primary.CFrame
			primary.CFrame = CFrame.new(pos.X, S.hoverHeight, pos.Z) * (cf - cf.Position)
		end
	end)
end

local function StopHoverBoat()
	if S.hoverBoatConn then
		S.hoverBoatConn:Disconnect()
		S.hoverBoatConn = nil
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- 4. BOAT SPEED (Bypass Internal Overwrite using CFrame + Throttle)
-- ────────────────────────────────────────────────────────────────────────────
local function StartBoatSpeed()
	if S.boatSpeedConn then return end
	S.boatSpeedConn = RunService.Heartbeat:Connect(function(deltaTime)
		local seat, boat = GetSeatAndBoat()
		if not seat or not boat then return end
		
		-- Cek apakah player lagi nekan tombol gas (W / Maju)
		if seat.Throttle == 1 then
			local primary = boat.PrimaryPart or seat
			if primary then
				-- Paksa kapal maju pakai CFrame
				primary.CFrame = primary.CFrame + (primary.CFrame.LookVector * (S.boatSpeedValue * deltaTime))
			end
		end
	end)
end

local function StopBoatSpeed()
	if S.boatSpeedConn then
		S.boatSpeedConn:Disconnect()
		S.boatSpeedConn = nil
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- 5. SMOOTH BOAT COLLISION (Noclip Kapal Tembus Objek di Stepped)
-- ────────────────────────────────────────────────────────────────────────────
local function StartSmoothCollision()
	if S.collisionConn then return end
	-- Dipindah ke Stepped agar jalan sebelum physics engine kalkulasi tabrakan
	S.collisionConn = RunService.Stepped:Connect(function()
		local seat, boat = GetSeatAndBoat()
		if not seat or not boat then return end
		for _, part in ipairs(boat:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
end

local function StopSmoothCollision()
	if S.collisionConn then
		S.collisionConn:Disconnect()
		S.collisionConn = nil
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- 6. CHARACTER MOVEMENT (Custom WalkSpeed & JumpPower)
-- ────────────────────────────────────────────────────────────────────────────
local function StartWalkSpeed()
	if S.walkSpeedConn then return end
	S.walkSpeedConn = RunService.Heartbeat:Connect(function()
		local hum = GetHumanoid()
		if hum then
			hum.WalkSpeed = S.walkSpeedValue
		end
	end)
end

local function StopWalkSpeed()
	if S.walkSpeedConn then
		S.walkSpeedConn:Disconnect()
		S.walkSpeedConn = nil
	end
end

local function StartJumpPower()
	if S.jumpPowerConn then return end
	S.jumpPowerConn = RunService.Heartbeat:Connect(function()
		local hum = GetHumanoid()
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = S.jumpPowerValue
		end
	end)
end

local function StopJumpPower()
	if S.jumpPowerConn then
		S.jumpPowerConn:Disconnect()
		S.jumpPowerConn = nil
	end
end

-- ============================================================
-- GUI — Ontoy Hub style (dark red theme), standalone ScreenGui
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "SeaNav_Hub"
screenGui.ResetOnSpawn = false
screenGui.Parent       = LocalPlayer:WaitForChild("PlayerGui")

local REDZ = {
	BG        = Color3.fromRGB(14,12,16),
	BG2       = Color3.fromRGB(20,16,22),
	Accent    = Color3.fromRGB(200,30,50),
	AccentDim = Color3.fromRGB(120,20,35),
	AccentGlow= Color3.fromRGB(255,60,80),
	TextMain  = Color3.fromRGB(240,220,225),
	TextSub   = Color3.fromRGB(130,100,110),
	Stroke    = Color3.fromRGB(60,30,40),
	ToggleOff = Color3.fromRGB(40,32,36),
	SliderFill= Color3.fromRGB(200,30,50),
	SliderBG  = Color3.fromRGB(35,28,32),
}

-- MAIN WINDOW
local mainWindow = Instance.new("Frame")
mainWindow.Size             = UDim2.new(0,420,0,480)
mainWindow.Position         = UDim2.new(0.5,-210,0.5,-240)
mainWindow.BackgroundColor3 = REDZ.BG
mainWindow.BorderSizePixel  = 0
mainWindow.Active           = true
mainWindow.Draggable        = false
mainWindow.Parent           = screenGui
Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0,10)
local mStroke = Instance.new("UIStroke", mainWindow)
mStroke.Color = REDZ.Stroke; mStroke.Thickness = 1.5

-- TITLE BAR
local titleBar = Instance.new("Frame", mainWindow)
titleBar.Size             = UDim2.new(1,0,0,42)
titleBar.BackgroundColor3 = REDZ.BG2
titleBar.BorderSizePixel  = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local accentLine = Instance.new("Frame", titleBar)
accentLine.Size             = UDim2.new(1,0,0,2)
accentLine.Position         = UDim2.new(0,0,1,-2)
accentLine.BackgroundColor3 = REDZ.Accent
accentLine.BorderSizePixel  = 0

local logoDot = Instance.new("Frame", titleBar)
logoDot.Size             = UDim2.new(0,8,0,8)
logoDot.Position         = UDim2.new(0,14,0.5,-4)
logoDot.BackgroundColor3 = REDZ.AccentGlow
logoDot.BorderSizePixel  = 0
Instance.new("UICorner", logoDot).CornerRadius = UDim.new(0,4)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size               = UDim2.new(1,-80,1,0)
titleText.Position           = UDim2.new(0,30,0,0)
titleText.BackgroundTransparency = 1
titleText.Text               = "SEA NAVIGATION  <font color='#C81E32'>·</font>  Environment Control"
titleText.RichText           = true
titleText.TextColor3         = REDZ.TextMain
titleText.Font               = Enum.Font.GothamBold
titleText.TextSize           = 12
titleText.TextXAlignment     = Enum.TextXAlignment.Left

-- Drag Logic
local dragging, dragStart, dragPos = false, Vector2.zero, UDim2.new()
titleBar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = Vector2.new(i.Position.X, i.Position.Y)
		dragPos   = mainWindow.Position
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local d = Vector2.new(i.Position.X, i.Position.Y) - dragStart
		mainWindow.Position = UDim2.new(
			dragPos.X.Scale, dragPos.X.Offset + d.X,
			dragPos.Y.Scale, dragPos.Y.Offset + d.Y
		)
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Close & Minimize Buttons
local function MakeBtn(xOff, bg, txt)
	local btn = Instance.new("TextButton", titleBar)
	btn.Size             = UDim2.new(0,26,0,26)
	btn.Position         = UDim2.new(1,xOff,0.5,-13)
	btn.BackgroundColor3 = bg
	btn.Text             = txt
	btn.TextColor3       = Color3.fromRGB(255,255,255)
	btn.Font             = Enum.Font.GothamBold
	btn.TextSize         = 11
	btn.BorderSizePixel  = 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
	return btn
end
local closeBtn    = MakeBtn(-34, REDZ.Accent,    "✕")
local minimizeBtn = MakeBtn(-66, REDZ.ToggleOff, "—")

-- SCROLL CONTENT
local contentScroll = Instance.new("ScrollingFrame", mainWindow)
contentScroll.Size                 = UDim2.new(1,-16,1,-54)
contentScroll.Position             = UDim2.new(0,8,0,50)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel      = 0
contentScroll.ScrollBarThickness   = 3
contentScroll.ScrollBarImageColor3 = REDZ.AccentDim
contentScroll.CanvasSize           = UDim2.new(0,0,0,0)
contentScroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y

local contentLayout = Instance.new("UIListLayout", contentScroll)
contentLayout.Padding              = UDim.new(0,6)
contentLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", contentScroll).PaddingTop = UDim.new(0,8)

-- ── WIDGET FACTORIES ─────────────────────────────────────────────────────────

local function MakeSectionLabel(text)
	local lbl = Instance.new("TextLabel", contentScroll)
	lbl.Size                 = UDim2.new(1,-8,0,18)
	lbl.BackgroundTransparency = 1
	lbl.Text                 = text
	lbl.TextColor3           = REDZ.Accent
	lbl.Font                 = Enum.Font.GothamBold
	lbl.TextSize             = 10
	lbl.TextXAlignment       = Enum.TextXAlignment.Left
end

local function MakeToggleRow(label, sublabel, accentColor)
	accentColor = accentColor or REDZ.Accent

	local row = Instance.new("Frame", contentScroll)
	row.Size             = UDim2.new(1,-8,0,52)
	row.BackgroundColor3 = REDZ.BG2
	row.BorderSizePixel  = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row)
	stroke.Color = REDZ.Stroke; stroke.Thickness = 1

	local titleLbl = Instance.new("TextLabel", row)
	titleLbl.Size                 = UDim2.new(1,-60,0,22)
	titleLbl.Position             = UDim2.new(0,14,0,8)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                 = label
	titleLbl.TextColor3           = REDZ.TextMain
	titleLbl.Font                 = Enum.Font.GothamBold
	titleLbl.TextSize             = 12
	titleLbl.TextXAlignment       = Enum.TextXAlignment.Left

	if sublabel then
		local sub = Instance.new("TextLabel", row)
		sub.Size                 = UDim2.new(1,-60,0,16)
		sub.Position             = UDim2.new(0,14,0,28)
		sub.BackgroundTransparency = 1
		sub.Text                 = sublabel
		sub.TextColor3           = REDZ.TextSub
		sub.Font                 = Enum.Font.Gotham
		sub.TextSize             = 10
		sub.TextXAlignment       = Enum.TextXAlignment.Left
	end

	local toggleBG = Instance.new("Frame", row)
	toggleBG.Size             = UDim2.new(0,36,0,20)
	toggleBG.Position         = UDim2.new(1,-48,0.5,-10)
	toggleBG.BackgroundColor3 = REDZ.ToggleOff
	toggleBG.BorderSizePixel  = 0
	Instance.new("UICorner", toggleBG).CornerRadius = UDim.new(0,10)

	local knob = Instance.new("Frame", toggleBG)
	knob.Size             = UDim2.new(0,14,0,14)
	knob.Position         = UDim2.new(0,3,0.5,-7)
	knob.BackgroundColor3 = REDZ.TextSub
	knob.BorderSizePixel  = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)

	local hitbox = Instance.new("TextButton", toggleBG)
	hitbox.Size                 = UDim2.new(1,8,1,8)
	hitbox.Position             = UDim2.new(0,-4,0,-4)
	hitbox.BackgroundTransparency = 1
	hitbox.Text                 = ""
	hitbox.BorderSizePixel      = 0

	local state = false
	local function SetState(s)
		state = s
		if s then
			toggleBG.BackgroundColor3 = accentColor
			knob.BackgroundColor3     = Color3.fromRGB(255,255,255)
			knob.Position             = UDim2.new(1,-17,0.5,-7)
			row.BackgroundColor3      = Color3.fromRGB(24,14,18)
			stroke.Color              = REDZ.AccentDim
		else
			toggleBG.BackgroundColor3 = REDZ.ToggleOff
			knob.BackgroundColor3     = REDZ.TextSub
			knob.Position             = UDim2.new(0,3,0.5,-7)
			row.BackgroundColor3      = REDZ.BG2
			stroke.Color              = REDZ.Stroke
		end
	end
	hitbox.MouseButton1Click:Connect(function() SetState(not state) end)
	return function() return state end
end

local function MakeSliderRow(label, dMin, dMax, initPct, unit, onChanged)
	local row = Instance.new("Frame", contentScroll)
	row.Size             = UDim2.new(1,-8,0,66)
	row.BackgroundColor3 = REDZ.BG2
	row.BorderSizePixel  = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", row)
	stroke.Color = REDZ.Stroke; stroke.Thickness = 1

	local titleLbl = Instance.new("TextLabel", row)
	titleLbl.Size                 = UDim2.new(1,-80,0,20)
	titleLbl.Position             = UDim2.new(0,14,0,8)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                 = label
	titleLbl.TextColor3           = REDZ.TextMain
	titleLbl.Font                 = Enum.Font.GothamBold
	titleLbl.TextSize             = 12
	titleLbl.TextXAlignment       = Enum.TextXAlignment.Left

	local valLbl = Instance.new("TextLabel", row)
	valLbl.Size                 = UDim2.new(0,70,0,20)
	valLbl.Position             = UDim2.new(1,-78,0,8)
	valLbl.BackgroundTransparency = 1
	valLbl.Font                 = Enum.Font.GothamBold
	valLbl.TextSize             = 12
	valLbl.TextColor3           = REDZ.AccentGlow
	valLbl.TextXAlignment       = Enum.TextXAlignment.Right

	local sliderBG = Instance.new("Frame", row)
	sliderBG.Size             = UDim2.new(1,-28,0,5)
	sliderBG.Position         = UDim2.new(0,14,0,42)
	sliderBG.BackgroundColor3 = REDZ.SliderBG
	sliderBG.BorderSizePixel  = 0
	Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0,3)

	local fill = Instance.new("Frame", sliderBG)
	fill.Size             = UDim2.new(initPct,0,1,0)
	fill.BackgroundColor3 = REDZ.SliderFill
	fill.BorderSizePixel  = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)

	local knob = Instance.new("Frame", sliderBG)
	knob.Size             = UDim2.new(0,14,0,14)
	knob.Position         = UDim2.new(initPct,-7,0.5,-7)
	knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
	knob.BorderSizePixel  = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(0,7)
	local kr = Instance.new("UIStroke", knob)
	kr.Color = REDZ.Accent; kr.Thickness = 2

	local hitbox = Instance.new("TextButton", sliderBG)
	hitbox.Size                 = UDim2.new(1,0,0,28)
	hitbox.Position             = UDim2.new(0,0,0.5,-14)
	hitbox.BackgroundTransparency = 1
	hitbox.Text                 = ""
	hitbox.BorderSizePixel      = 0
	hitbox.ZIndex               = 5

	local draggingSlider = false

	local function Compute(px)
		local bg  = sliderBG.AbsolutePosition.X
		local bw  = sliderBG.AbsoluteSize.X
		local pct = math.clamp((px - bg) / bw, 0, 1)
		return pct, math.floor(dMin + (dMax - dMin) * pct)
	end
	local function Apply(pct, val)
		fill.Size     = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, -7, 0.5, -7)
		valLbl.Text   = tostring(val) .. (unit or "")
		if onChanged then onChanged(val) end
	end
	Apply(initPct, math.floor(dMin + (dMax - dMin) * initPct))

	hitbox.MouseButton1Down:Connect(function() draggingSlider = true end)
	UserInputService.InputChanged:Connect(function(i)
		if not draggingSlider then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement
			or i.UserInputType == Enum.UserInputType.Touch then
			Apply(Compute(i.Position.X))
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = false
		end
	end)
	hitbox.MouseButton1Click:Connect(function()
		Apply(Compute(UserInputService:GetMouseLocation().X))
	end)
end

-- ── BUILD UI CONTENT ──────────────────────────────────────────────────────────

MakeSectionLabel("WATER SURFACE PLATFORM")
local waterWalkGet = MakeToggleRow(
	"Water Walk",
	"Part transparan agar bisa jalan di atas air"
)
MakeSliderRow(
	"Platform Y Offset", 0, 100, 0.2, " Y",
	function(val) S.waterWalkHeight = val end
)

MakeSectionLabel("CHARACTER MOVEMENT")
local walkSpeedGet = MakeToggleRow(
	"Fast Run",
	"Custom WalkSpeed untuk lari kencang"
)
MakeSliderRow(
	"WalkSpeed", 16, 300, 0, "",
	function(val) S.walkSpeedValue = val end
)

local jumpPowerGet = MakeToggleRow(
	"High Jump",
	"Custom JumpPower untuk lompat tinggi"
)
MakeSliderRow(
	"JumpPower", 50, 500, 0, "",
	function(val) S.jumpPowerValue = val end
)

MakeSectionLabel("LIGHTING")
local clearVisionGet = MakeToggleRow(
	"Clear Vision",
	"Hapus kabut dan jadikan terang benderang"
)

MakeSectionLabel("VEHICLE PHYSICS")
local hoverBoatGet = MakeToggleRow(
	"Hover Boat",
	"Paksa kapal melayang di atas permukaan air"
)
MakeSliderRow(
	"Hover Height", 0, 100, 0.45, " Y",
	function(val) S.hoverHeight = val end
)

local boatSpeedGet = MakeToggleRow(
	"Boat Speed",
	"Dorong kapal maju saat W ditekan (CFrame Bypass)"
)
MakeSliderRow(
	"Speed Value", 10, 500, 0.18, " stud/s",
	function(val) S.boatSpeedValue = val end
)

MakeSectionLabel("COLLISION MODIFIER")
local collisionGet = MakeToggleRow(
	"Smooth Boat Collision",
	"Noclip Kapal Tembus Batu (RunService.Stepped)"
)

-- ── MAIN TOGGLE WIRE LOOP ─────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
	-- Water Walk
	local ww = waterWalkGet()
	if ww  and not S.waterWalkConn   then StartWaterWalk()       end
	if not ww and S.waterWalkConn    then StopWaterWalk()        end

	-- Fast Run (WalkSpeed)
	local ws = walkSpeedGet()
	if ws  and not S.walkSpeedConn   then StartWalkSpeed()       end
	if not ws and S.walkSpeedConn    then StopWalkSpeed()        end

	-- High Jump (JumpPower)
	local jp = jumpPowerGet()
	if jp  and not S.jumpPowerConn   then StartJumpPower()       end
	if not jp and S.jumpPowerConn    then StopJumpPower()        end

	-- Clear Vision
	local cv = clearVisionGet()
	if cv  and not S.clearVisionConn then StartClearVision()     end
	if not cv and S.clearVisionConn  then StopClearVision()      end

	-- Hover Boat
	local hb = hoverBoatGet()
	if hb  and not S.hoverBoatConn   then StartHoverBoat()       end
	if not hb and S.hoverBoatConn    then StopHoverBoat()        end

	-- Boat Speed
	local bs = boatSpeedGet()
	if bs  and not S.boatSpeedConn   then StartBoatSpeed()       end
	if not bs and S.boatSpeedConn    then StopBoatSpeed()        end

	-- Smooth Collision
	local sc = collisionGet()
	if sc  and not S.collisionConn   then StartSmoothCollision() end
	if not sc and S.collisionConn    then StopSmoothCollision()  end
end)

-- ── MINIMIZE & CLOSE ──────────────────────────────────────────────────────────
local contentVisible = true
minimizeBtn.MouseButton1Click:Connect(function()
	contentVisible = not contentVisible
	contentScroll.Visible = contentVisible
	mainWindow.Size = contentVisible
		and UDim2.new(0,420,0,480)
		or  UDim2.new(0,420,0,42)
end)

closeBtn.MouseButton1Click:Connect(function()
	-- cleanup semua loop sebelum destroy
	StopWaterWalk()
	StopWalkSpeed()
	StopJumpPower()
	StopClearVision()
	StopHoverBoat()
	StopBoatSpeed()
	StopSmoothCollision()
	screenGui:Destroy()
end)
