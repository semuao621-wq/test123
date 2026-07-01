local getinfo = getinfo or debug.getinfo
local DEBUG = false
local Hooked = {}

local Detected, Kill

setthreadidentity(2)

for i, v in getgc(true) do
    if typeof(v) == "table" then
        local DetectFunc = rawget(v, "Detected")
        local KillFunc = rawget(v, "Kill")
    
        if typeof(DetectFunc) == "function" and not Detected then
            Detected = DetectFunc
            
            local Old; Old = hookfunction(Detected, function(Action, Info, NoCrash)
                if Action ~= "_" then
                    if DEBUG then
                        warn(`Adonis AntiCheat flagged\nMethod: {Action}\nInfo: {Info}`)
                    end
                end
                
                return true
            end)

            table.insert(Hooked, Detected)
        end

        if rawget(v, "Variables") and rawget(v, "Process") and typeof(KillFunc) == "function" and not Kill then
            Kill = KillFunc
            local Old; Old = hookfunction(Kill, function(Info)
                if DEBUG then
                    warn(`Adonis AntiCheat tried to kill (fallback): {Info}`)
                end
            end)

            table.insert(Hooked, Kill)
        end
    end
end

local Old; Old = hookfunction(getrenv().debug.info, newcclosure(function(...)
    local LevelOrFunc, Info = ...

    if Detected and LevelOrFunc == Detected then
        if DEBUG then
            warn(`zins | adonis bypassed`)
        end

        return coroutine.yield(coroutine.running())
    end

    return Old(...)
end))
-- setthreadidentity(9)
setthreadidentity(7)


-- Matikan instance lama kalau ada
if _G.KingVypersRunning then
    _G.KingVypersRunning = false
end
task.wait(0.5)
_G.KingVypersRunning = true

-- Ã¢â€â‚¬Ã¢â€â‚¬ SNAPSHOT GUI SEBELUM VYPER LOAD Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
-- Catat nama semua GUI yang sudah ada SEBELUM Vyper dibuat,
-- supaya kita TIDAK salah hapus GUI milik game saat re-execute.
local function snapshotGuis(container)
    local names = {}
    pcall(function()
        for _, gui in ipairs(container:GetChildren()) do
            if gui:IsA("ScreenGui") or gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                names[gui] = true -- track by reference, bukan nama (bisa duplikat)
            end
        end
    end)
    return names
 end

local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local cg = game:GetService("CoreGui")
local pgBefore = snapshotGuis(pg)
local cgBefore = snapshotGuis(cg)

-- Hapus window Vyper lama kalau ada (dari execute sebelumnya)
pcall(function()
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:GetAttribute("VyperWindow") then gui:Destroy() end
    end
end)
pcall(function()
    for _, gui in ipairs(cg:GetChildren()) do
        if gui:GetAttribute("VyperWindow") then gui:Destroy() end
    end
end)

-- Tunggu game fully loaded sebelum apapun
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "King Vypers",
    Icon = "rbxassetid://139467646163013",
    Folder = "KingVypers",
    Background = "rbxassetid://97514324988224",
    BackgroundImageTransparency = 0.35,
    Size = UDim2.new(0, 530, 0, 300),
    MinSize = Vector2.new(530, 300),
    MaxSize = Vector2.new(530, 300),
    NewElements = true,
    OpenButton = { Enabled = false },
})

-- Colors --
local Kings = Color3.fromHex("#120324")
local Mains = Color3.fromHex("#110029")
local Purple = Color3.fromHex("#7775F2")

WindUI:AddTheme({ Name = "MachTheme", Background = Kings })
WindUI:SetTheme("MachTheme")

Window:Tag({ Title = "PREMIUM", Color = Mains })
Window:Tag({ Title = "BETA", Color = Purple })

local TweenService = game:GetService("TweenService")
local protectGui
local success, result = pcall(function()
    if gethui then return gethui()
    elseif syn and syn.protect_gui then
        local sg = Instance.new("ScreenGui")
        syn.protect_gui(sg)
        sg.Parent = game:GetService("CoreGui")
        return sg.Parent
    else return game:GetService("CoreGui") end
end)
if success then protectGui = result else protectGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MachFishingButton"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = protectGui

local buttonFrame = Instance.new("Frame")
buttonFrame.Size = UDim2.new(0, 42, 0, 42)
buttonFrame.Position = UDim2.new(0, 20, 0, 20)
buttonFrame.BackgroundTransparency = 1
buttonFrame.Parent = screenGui

local imageButton = Instance.new("ImageButton")
imageButton.Size = UDim2.new(1, 0, 1, 0)
imageButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
imageButton.BackgroundTransparency = 0.2
imageButton.Image = "rbxassetid://107726435417936"
imageButton.ScaleType = Enum.ScaleType.Fit
imageButton.Parent = buttonFrame

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = imageButton

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(60, 60, 60)
uiStroke.Parent = imageButton

local uiGradient = Instance.new("UIGradient")
uiGradient.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20), Color3.fromRGB(60, 60, 60))
uiGradient.Parent = uiStroke

local dragging = false
local dragInput, dragStart, startPos
local UserInputService = game:GetService("UserInputService")
imageButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = buttonFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

imageButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        buttonFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local clickStart = nil
imageButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        clickStart = input.Position
    end
end)

imageButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if clickStart then
            if (input.Position - clickStart).Magnitude < 10 then
                if Window and Window.Toggle then Window:Toggle() end
            end
            clickStart = nil
        end
    end
end)

imageButton.MouseEnter:Connect(function() TweenService:Create(imageButton, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play() end)
imageButton.MouseLeave:Connect(function() TweenService:Create(imageButton, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play() end)


-- Tag HANYA GUI baru yang muncul setelah Vyper dibuat (bukan snapshot lama)
task.defer(function()
    task.wait(0.5) -- beri waktu Vyper selesai bikin semua GUI-nya
    for _, gui in ipairs(pg:GetChildren()) do
        if not pgBefore[gui] and not gui:GetAttribute("VyperWindow") then
            gui:SetAttribute("VyperWindow", true)
        end
    end
    for _, gui in ipairs(cg:GetChildren()) do
        if not cgBefore[gui] and not gui:GetAttribute("VyperWindow") then
            -- Jangan tag GUI inti Roblox
            local n = gui.Name
            if not n:find("Roblox") and not n:find("Chat") and not n:find("TopBar") and not n:find("CoreGui") then
                gui:SetAttribute("VyperWindow", true)
            end
        end
    end
end)


-- INFO TAB

	local InfoTab = Window:Tab({
		Title = "Info",
		Icon = "solar:info-square-bold",
		IconColor = Mains,
		IconShape = "Square",
		Border = true,
	})






local HttpService = game:GetService("HttpService")

-- =============================================
-- UNIVERSAL UI CONFIG AUTO-SAVE
-- =============================================
local uiConfigPath = "KingVypers_DDSConfig.json"

local function loadUIConfig()
    local ok, data = pcall(readfile, uiConfigPath)
    if ok and data then
        local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok2 and decoded then return decoded end
    end
    return {}
end

local function saveUIConfig(cfg)
    pcall(writefile, uiConfigPath, HttpService:JSONEncode(cfg))
end

local uiConfig = loadUIConfig()
local isUILoading = true
-- Fungsi fetch member count
local memberCount = "N/A"
local onlineCount = "N/A"

local function fetchDiscordInfo()
    local req = request or http_request or syn and syn.request
    if not req then return end
    
    local success, result = pcall(function()
        return req({
            Url = "https://discord.com/api/v9/invites/XmWf3YQPpZ?with_counts=true",
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Mozilla/5.0"
            }
        })
    end)
    
    if success and result and result.StatusCode == 200 then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(result.Body)
        end)
        
        if ok and data then
            memberCount = tostring(data.approximate_member_count or "N/A")
            onlineCount = tostring(data.approximate_presence_count or "N/A")
        end
    end
end

-- Fetch dulu sebelum bikin UI
fetchDiscordInfo()

-- Info + buttons + banner semua dalam satu frame
local ServerInfo = InfoTab:Paragraph({
    Title = "King Vypers | Official",
    Desc = "â€¢ Member Count: " .. memberCount .. "\nâ€¢ Online Count: " .. onlineCount,
    Image = "rbxassetid://107726435417936",
    Thumbnail = "rbxassetid://83197533072664",
    ThumbnailSize = 80,
    Buttons = {
        {
            Title = "Copy Discord Invite",
            Color= Color3.fromHex("#5707AB"),
            Icon = "link",
            Callback = function()
                if setclipboard then
                    setclipboard("https://discord.gg/XmWf3YQPpZ")
                end
            end
        },
        {
            Title = "Update Info",
            Icon = "refresh-cw",
            Callback = function()
                fetchDiscordInfo()
                ServerInfo:SetDesc("â€¢ Member Count: " .. memberCount .. "\nâ€¢ Online Count: " .. onlineCount)
            end
        }
    }
})



local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local UIS = game:GetService("UserInputService")
local isMobileDevice = UIS.TouchEnabled and not UIS.KeyboardEnabled

local HttpService = game:GetService("HttpService")

-- =============================================
-- =============================================
-- AUTO SKIP MAIN MENU (jalan otomatis saat execute)
-- Dipakai saat rejoin: HOME -> pilih Barista -> masuk game
-- =============================================

task.spawn(function()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local mainMenu = playerGui:WaitForChild("mainMenuSystem", 10)
    if not mainMenu then return end
    if not mainMenu.Enabled then return end

    local mainUI = playerGui:FindFirstChild("MainUI")
    if mainUI and mainUI.Enabled then return end

    local baseFrame = mainMenu:FindFirstChild("baseFrame")
    if not baseFrame or not baseFrame.Visible then return end

    task.wait(1.5)

    local function clickBtn(btn)
        if not btn then return end
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() btn.MouseButton1Click:Fire() end)
        pcall(function() btn.Activated:Fire() end)
    end

    local applySelect = nil
    pcall(function()
        applySelect = baseFrame:FindFirstChild("homeFrame"):FindFirstChild("playFrame"):FindFirstChild("applySelect")
    end)
    -- print("[AutoSkip] applySelect found:", applySelect ~= nil)
    clickBtn(applySelect)
    task.wait(1.5)

    local baristaBtn = nil
    pcall(function()
        baristaBtn = baseFrame:FindFirstChild("playFrame"):FindFirstChild("ScrollingFrame"):FindFirstChild("teamFiveTeamSelect")
    end)
    -- print("[AutoSkip] baristaBtn found:", baristaBtn ~= nil)
    clickBtn(baristaBtn)
    task.wait(0.8)

    local deploySelect = nil
    pcall(function()
        deploySelect = baseFrame:FindFirstChild("playFrame"):FindFirstChild("deploySelect")
    end)
    -- print("[AutoSkip] deploySelect found:", deploySelect ~= nil)
    clickBtn(deploySelect)

    local timeout = tick() + 30
    local entered = false
    while tick() < timeout do
        local mui = playerGui:FindFirstChild("MainUI")
        if mui and mui.Enabled then
            entered = true
            break
        end
        task.wait(0.5)
    end
    -- print("[AutoSkip] Entered game:", entered)
    task.wait(3)

    if entered and baristaRunning == false and SpawnCar.SelectedCar and SpawnCar.SelectedCar ~= "Refresh dulu..." then
        -- print("[AutoSkip] Auto starting Barista loop...")
        task.spawn(startBaristaLoop)
    end
end)

-- HELPER: Ambil tombol Gas dari Interface
-- =============================================

local function getGasButton()
    local interface = LocalPlayer.PlayerGui:FindFirstChild("Interface")
    if not interface then return nil end
    local buttons = interface:FindFirstChild("Buttons")
    if not buttons then return nil end
    return buttons:FindFirstChild("Gas")
end

-- =============================================
-- VEHICLE SPEED MODULE
-- =============================================

local VehicleSpeed = {}
VehicleSpeed.Enabled = false
VehicleSpeed.CurrentSpeed = 100
VehicleSpeed.BoostActive = false
VehicleSpeed.BoostLoop = nil
VehicleSpeed.DecelActive = false
VehicleSpeed.DecelLoop = nil
VehicleSpeed.InputConn1 = nil
VehicleSpeed.InputConn2 = nil
VehicleSpeed._liveSpeed = 0

local function findMyMotor()
    local myName = LocalPlayer.Name
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name:match(myName) and v.Name:match("Montors") then
            return v
        end
    end
    return nil
end

local function getMotorPrimaryPart()
    local motor = findMyMotor()
    if not motor then return nil end
    return motor.PrimaryPart or motor:FindFirstChildWhichIsA("BasePart")
end

local function isRidingMotor()
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return false end
    return humanoid.Sit == true and humanoid.SeatPart ~= nil
end

-- KEY FIX: Hanya override X dan Z, biarkan Y fisika game yang handle
local function applyVelocity(p, dir, targetSpeed, blend)
    local vel = p.AssemblyLinearVelocity
    local newX = vel.X + (dir.X * targetSpeed - vel.X) * blend
    local newZ = vel.Z + (dir.Z * targetSpeed - vel.Z) * blend
    -- Y TIDAK diubah sama sekali Ã¢â‚¬â€ biarkan physics engine yang handle gravity & suspensi
    p.AssemblyLinearVelocity = Vector3.new(newX, vel.Y, newZ)
end

local function stopDecelLoop()
    VehicleSpeed.DecelActive = false
    if VehicleSpeed.DecelLoop then
        task.cancel(VehicleSpeed.DecelLoop)
        VehicleSpeed.DecelLoop = nil
    end
end

local function startBoostLoop()
    stopDecelLoop()
    if VehicleSpeed.BoostActive then return end
    VehicleSpeed.BoostActive = true
    VehicleSpeed.BoostLoop = task.spawn(function()
        local currentSpeed = VehicleSpeed._liveSpeed
        local p = getMotorPrimaryPart()
        if p then
            local vel = p.AssemblyLinearVelocity
            local flatMag = Vector3.new(vel.X, 0, vel.Z).Magnitude
            currentSpeed = math.max(currentSpeed, flatMag)
        end

        while VehicleSpeed.BoostActive and VehicleSpeed.Enabled do
            if isRidingMotor() then
                p = getMotorPrimaryPart()
                if p then
                    local dir = -p.CFrame.LookVector
                    currentSpeed = currentSpeed + (VehicleSpeed.CurrentSpeed - currentSpeed) * 0.2
                    VehicleSpeed._liveSpeed = currentSpeed
                    applyVelocity(p, dir, currentSpeed, 0.35)
                end
            end
            task.wait(0.05)
        end
    end)
end

local function stopBoostLoop()
    VehicleSpeed.BoostActive = false
    if VehicleSpeed.BoostLoop then
        task.cancel(VehicleSpeed.BoostLoop)
        VehicleSpeed.BoostLoop = nil
    end
    VehicleSpeed._liveSpeed = 0
end

function VehicleSpeed.Start()
    if VehicleSpeed.Enabled then return end
    VehicleSpeed.Enabled = true

    if isMobileDevice then
        task.spawn(function()
            local gasBtn = nil
            while VehicleSpeed.Enabled and not gasBtn do
                gasBtn = getGasButton()
                if not gasBtn then task.wait(0.5) end
            end
            if not gasBtn then return end

            VehicleSpeed.InputConn1 = gasBtn.MouseButton1Down:Connect(function()
                if VehicleSpeed.Enabled then startBoostLoop() end
            end)
            VehicleSpeed.InputConn2 = gasBtn.MouseButton1Up:Connect(function()
                if VehicleSpeed.Enabled then stopBoostLoop() end
            end)
        end)
    else
        VehicleSpeed.InputConn1 = UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if not VehicleSpeed.Enabled then return end
            if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
                startBoostLoop()
            end
        end)
        VehicleSpeed.InputConn2 = UIS.InputEnded:Connect(function(input, gpe)
            if not VehicleSpeed.Enabled then return end
            if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
                if not UIS:IsKeyDown(Enum.KeyCode.W) and not UIS:IsKeyDown(Enum.KeyCode.Up) then
                    stopBoostLoop()
                end
            end
        end)
    end
end

function VehicleSpeed.Stop()
    if not VehicleSpeed.Enabled then return end
    VehicleSpeed.Enabled = false
    VehicleSpeed.BoostActive = false
    if VehicleSpeed.BoostLoop then task.cancel(VehicleSpeed.BoostLoop) VehicleSpeed.BoostLoop = nil end
    VehicleSpeed._liveSpeed = 0
    if VehicleSpeed.InputConn1 then VehicleSpeed.InputConn1:Disconnect() VehicleSpeed.InputConn1 = nil end
    if VehicleSpeed.InputConn2 then VehicleSpeed.InputConn2:Disconnect() VehicleSpeed.InputConn2 = nil end
end

function VehicleSpeed.SetSpeed(speed)
    VehicleSpeed.CurrentSpeed = speed
end

-- =============================================
-- SLOW RACE MODULE (Gradual Acceleration)
-- =============================================

local SlowRace = {}
SlowRace.Enabled = false
SlowRace.MaxSpeed = 200
SlowRace.AccelMultiplier = 3
SlowRace.BoostActive = false
SlowRace.BoostLoop = nil
SlowRace.DecelActive = false
SlowRace.DecelLoop = nil
SlowRace.InputConn1 = nil
SlowRace.InputConn2 = nil
SlowRace._liveSpeed = 0

local function stopSlowDecelLoop()
    SlowRace.DecelActive = false
    if SlowRace.DecelLoop then
        task.cancel(SlowRace.DecelLoop)
        SlowRace.DecelLoop = nil
    end
end

local function startSlowRaceLoop()
    stopSlowDecelLoop()
    if SlowRace.BoostActive then return end
    SlowRace.BoostActive = true
    SlowRace.BoostLoop = task.spawn(function()
        local currentSpeed = SlowRace._liveSpeed
        local p = getMotorPrimaryPart()
        if p then
            local vel = p.AssemblyLinearVelocity
            local flatMag = Vector3.new(vel.X, 0, vel.Z).Magnitude
            currentSpeed = math.max(currentSpeed, flatMag)
        end

        while SlowRace.BoostActive and SlowRace.Enabled do
            if isRidingMotor() then
                p = getMotorPrimaryPart()
                if p then
                    currentSpeed = math.min(
                        currentSpeed + (SlowRace.AccelMultiplier * 0.5),
                        SlowRace.MaxSpeed
                    )
                    SlowRace._liveSpeed = currentSpeed
                    local dir = -p.CFrame.LookVector
                    applyVelocity(p, dir, currentSpeed, 0.3)
                end
            end
            task.wait(0.05)
        end
    end)
end

local function stopSlowRaceLoop()
    SlowRace.BoostActive = false
    if SlowRace.BoostLoop then
        task.cancel(SlowRace.BoostLoop)
        SlowRace.BoostLoop = nil
    end
    SlowRace._liveSpeed = 0
end

function SlowRace.Start()
    if SlowRace.Enabled then return end
    SlowRace.Enabled = true

    if isMobileDevice then
        task.spawn(function()
            local gasBtn = nil
            while SlowRace.Enabled and not gasBtn do
                gasBtn = getGasButton()
                if not gasBtn then task.wait(0.5) end
            end
            if not gasBtn then return end

            SlowRace.InputConn1 = gasBtn.MouseButton1Down:Connect(function()
                if SlowRace.Enabled then startSlowRaceLoop() end
            end)
            SlowRace.InputConn2 = gasBtn.MouseButton1Up:Connect(function()
                if SlowRace.Enabled then stopSlowRaceLoop() end
            end)
        end)
    else
        SlowRace.InputConn1 = UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if not SlowRace.Enabled then return end
            if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
                startSlowRaceLoop()
            end
        end)
        SlowRace.InputConn2 = UIS.InputEnded:Connect(function(input, gpe)
            if not SlowRace.Enabled then return end
            if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
                if not UIS:IsKeyDown(Enum.KeyCode.W) and not UIS:IsKeyDown(Enum.KeyCode.Up) then
                    stopSlowRaceLoop()
                end
            end
        end)
    end
end

function SlowRace.Stop()
    if not SlowRace.Enabled then return end
    SlowRace.Enabled = false
    SlowRace.BoostActive = false
    if SlowRace.BoostLoop then task.cancel(SlowRace.BoostLoop) SlowRace.BoostLoop = nil end
    SlowRace._liveSpeed = 0
    if SlowRace.InputConn1 then SlowRace.InputConn1:Disconnect() SlowRace.InputConn1 = nil end
    if SlowRace.InputConn2 then SlowRace.InputConn2:Disconnect() SlowRace.InputConn2 = nil end
end

-- =============================================
-- SPAWN CAR MODULE
-- =============================================

local SpawnCar = {}
_G.SpawnCar = SpawnCar
SpawnCar.SelectedCar = nil
SpawnCar.CarList = {}
SpawnCar.AutoRide = false
SpawnCar.AutoRideAlways = false

local function exitMotor()
    local motor = findMyMotor()
    if not motor then return false end
    local char = LocalPlayer.Character
    if not char then return false end

    local anims = motor:FindFirstChild("Anims")
    if anims then
        pcall(function() anims:FireServer("RemovePlayer", char, nil) end)
        task.wait(0.3)
    end

    local driveSeat = motor:FindFirstChild("DriveSeat", true)
    if driveSeat then
        pcall(function() driveSeat:Sit(nil) end)
        task.wait(0.3)
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function() humanoid.Jump = true end)
    end

    return true
end

local function rideMotor()
    local motor = findMyMotor()
    if not motor then return false end

    local char = LocalPlayer.Character
    if not char then return false end

    local anims = motor:FindFirstChild("Anims")
    if anims then
        pcall(function() anims:FireServer("CreatePlayer", char) end)
        task.wait(0.2)
        pcall(function() anims:FireServer("RegisterPlayer", char) end)
        task.wait(0.2)
    end

    local kickstand = motor:FindFirstChild("Kickstand")
    if kickstand then
        pcall(function() kickstand:FireServer("StandUp", 0, 0, 0, 0, false) end)
        task.wait(0.2)
    end

    local driveSeat = motor:FindFirstChild("DriveSeat", true)
    if driveSeat then
        pcall(function()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = driveSeat.CFrame end
            driveSeat:Sit(char:FindFirstChildOfClass("Humanoid"))
        end)
    end
    return true
end

local function getCarList()
    local carNames = {}
    pcall(function()
        local mainUI = LocalPlayer.PlayerGui:WaitForChild("MainUI")
        local frame = mainUI:WaitForChild("Frame")
        local spawnBtn = mainUI:WaitForChild("Spawn"):WaitForChild("SpawnCar")
        frame.Visible = false
        firesignal(spawnBtn.MouseButton1Click)
        task.wait(2)
        local sf = frame:WaitForChild("MainFrame"):WaitForChild("ScrollingFrame")
        for _, v in ipairs(sf:GetChildren()) do
            if v.ClassName:sub(1,2) ~= "UI" then
                table.insert(carNames, v.Name)
            end
        end
        frame.Visible = false
    end)
    SpawnCar.CarList = carNames
    return #carNames > 0 and carNames or { "Refresh dulu..." }
end

function SpawnCar.Spawn()
    if not SpawnCar.SelectedCar or SpawnCar.SelectedCar == "Refresh dulu..." then return end
    local ok = pcall(function()
        ReplicatedStorage:WaitForChild("SpawnCarEvents"):WaitForChild("SpawnCar"):FireServer(SpawnCar.SelectedCar)
    end)
    if ok and SpawnCar.AutoRide then
        task.spawn(function()
            task.wait(4)
            rideMotor()
        end)
    end
end

function SpawnCar.Despawn()
    pcall(function()
        ReplicatedStorage:WaitForChild("SpawnCarEvents"):WaitForChild("DespawnCar"):FireServer()
    end)
end

local autoRideLoop = nil
function SpawnCar.StartAutoRideAlways()
    if autoRideLoop then return end
    autoRideLoop = task.spawn(function()
        while SpawnCar.AutoRideAlways do
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and not humanoid.Sit and findMyMotor() then
                rideMotor()
            end
            task.wait(2)
        end
        autoRideLoop = nil
    end)
end

function SpawnCar.StopAutoRideAlways()
    SpawnCar.AutoRideAlways = false
    if autoRideLoop then task.cancel(autoRideLoop) autoRideLoop = nil end
end

-- =============================================
-- =============================================
-- AUTO JOB BARISTA MODULE
-- =============================================

-- =============================================
-- AUTO JOB COURIER MODULE
-- =============================================
-- =================================================================
-- DATA KOORDINAT (MANUAL SPOTS)
-- =================================================================
local PackageData = {
    ["1"] = {
        Tween     = CFrame.new(Vector3.new(-6794.09, 3.23, -454.48), Vector3.new(-6794.09, 3.23, -454.48) + Vector3.new(0.0649, 0, 0.9979)),
        Walk      = Vector3.new(-6794.78, 3.23, -445.22),
        WalkLook  = Vector3.new(-0.1029, 0, 0.9947),
        AfterLook = Vector3.new(0.0865, 0, -0.9963),
    },
    ["2"] = {
        Tween     = CFrame.new(Vector3.new(-8401.35, 2.76, -3819.80), Vector3.new(-8401.35, 2.76, -3819.80) + Vector3.new(1, 0, -0.0087)),
        Walk      = Vector3.new(-8383.13, 2.19, -3819.85),
        WalkLook  = Vector3.new(0.9998, 0, -0.0175),
        AfterLook = Vector3.new(-0.9971, 0, -0.0764),
    },
    ["3"] = {
        Tween     = CFrame.new(Vector3.new(-8788.36, 2.54, 652.26), Vector3.new(-8788.36, 2.54, 652.26) + Vector3.new(0.8879, 0, -0.4600)),
        Walk      = Vector3.new(-8776.65, 3.15, 645.71),
        WalkLook  = Vector3.new(0.8627, 0, -0.5057),
        AfterLook = Vector3.new(-0.8474, 0, 0.5310),
    },
    ["4"] = {
        Tween     = CFrame.new(Vector3.new(714.63, 3.24, -3980.11), Vector3.new(714.63, 3.24, -3980.11) + Vector3.new(0.0438, 0, 0.9990)),
        Walk      = Vector3.new(715.22, 3.24, -3961.31),
        WalkLook  = Vector3.new(0.0312, 0, 0.9995),
        AfterLook = Vector3.new(-0.0312, 0, -0.9995),
    },
    ["5"] = {
        Tween     = CFrame.new(Vector3.new(-6745.15, 3.76, 2964.32), Vector3.new(-6745.15, 3.76, 2964.32) + Vector3.new(0.4324, 0, 0.9017)),
        Walk      = Vector3.new(-6739.83, 3.76, 2974.46),
        WalkLook  = Vector3.new(0.4652, 0, 0.8852),
        AfterLook = Vector3.new(-0.5570, 0, -0.8305),
    },
    ["6"] = {
        Tween     = CFrame.new(Vector3.new(-3343.03, 31.66, -8173.29), Vector3.new(-3343.03, 31.66, -8173.29) + Vector3.new(-0.3950, 0, 0.9187)),
        Walk      = Vector3.new(-3351.09, 29.90, -8156.99),
        WalkLook  = Vector3.new(-0.4268, 0, 0.9043),
        AfterLook = Vector3.new(0.3799, 0, -0.9250),
    },
    ["7"] = {
        Tween     = CFrame.new(Vector3.new(-9980.91, 3.38, -4056.40), Vector3.new(-9980.91, 3.38, -4056.40) + Vector3.new(0.9826, 0, 0.1855)),
        Walk      = Vector3.new(-9963.65, 3.38, -4053.40),
        WalkLook  = Vector3.new(0.9905, 0, 0.1375),
        AfterLook = Vector3.new(-0.9853, 0, -0.1707),
    },
    ["8"] = {
        Tween     = CFrame.new(Vector3.new(-17039.63, 104.47, 6560.34), Vector3.new(-17039.63, 104.47, 6560.34) + Vector3.new(-0.8874, 0, 0.4610)),
        Walk      = Vector3.new(-17053.56, 105.04, 6567.01),
        WalkLook  = Vector3.new(-0.8930, 0, 0.4501),
        AfterLook = Vector3.new(0.7705, 0, -0.6375),
    },
}

-- =================================================================
-- SHARED STATE
-- =================================================================
local CourierJob = { Name = "Courier", TeamId = 11378976, X = -5158.57, Y = 4.41, Z = -3757.87 }
local courierRunning   = false
local ServiceEventConn = nil
local TWEEN_DURATION   = 60
local uangAwalCourier = nil
local totalCourierCycle = 0
local sendCourierWebhook


-- =================================================================
-- HELPERS
-- =================================================================

local function jumpAndWait()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    task.wait(0.3)

    local t = tick()
    while tick() - t < 3 do
        local state = hum:GetState()
        if state ~= Enum.HumanoidStateType.Jumping
        and state ~= Enum.HumanoidStateType.Freefall then
            break
        end
        task.wait(0.1)
    end
    task.wait(0.2)
end

local function faceDirection(lookVec)
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos    = hrp.Position
    local target = pos + Vector3.new(lookVec.X, 0, lookVec.Z)
    hrp.CFrame = CFrame.new(pos, target)
end

local function setCameraBehindPlayer()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local back   = hrp.CFrame.LookVector * -10
    local camPos = hrp.Position + back + Vector3.new(0, 5, 0)
    local lookAt = hrp.Position + hrp.CFrame.LookVector * 5
    cam.CFrame = CFrame.new(camPos, lookAt)
end

local function lookToDirection(lookVec)
    faceDirection(lookVec)
    task.wait(0.3)
end

local function findCourierMotor()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest, closestDist = nil, 50
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("DriveSeat", true) then
            local mp = model.PrimaryPart
            if mp and (mp.Position - hrp.Position).Magnitude < closestDist then
                closestDist = (mp.Position - hrp.Position).Magnitude
                closest     = model
            end
        end
    end
    return closest
end

local function rideCourierMotor()
    local motor = findCourierMotor()
    if not motor then return end
    local char      = LocalPlayer.Character
    local driveSeat = motor:FindFirstChild("DriveSeat", true)
    if driveSeat then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = driveSeat.CFrame end
        driveSeat:Sit(char:FindFirstChildOfClass("Humanoid"))
    end
    task.wait(0.5)
end

local function _tweenVehicle(vehicle, targetCFrame, duration)
    local TweenService = game:GetService("TweenService")
    local RunService   = game:GetService("RunService")
    local mainPart = vehicle.PrimaryPart
    if not mainPart then return end
    local parts = {}
    for _, part in ipairs(vehicle:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(parts, part) end
    end
    for _, part in ipairs(parts) do part.Anchored = true end
    local mainCFrame  = mainPart.CFrame
    local partOffsets = {}
    for _, part in ipairs(parts) do
        if part ~= mainPart then partOffsets[part] = mainCFrame:ToObjectSpace(part.CFrame) end
    end
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(mainPart, tweenInfo, { CFrame = targetCFrame })
    tween:Play()
    local conn = RunService.Heartbeat:Connect(function()
        local currentMain = mainPart.CFrame
        for _, part in ipairs(parts) do
            if part ~= mainPart and partOffsets[part] then
                part.CFrame = currentMain:ToWorldSpace(partOffsets[part])
            end
        end
    end)
    tween.Completed:Wait()
    conn:Disconnect()
    for _, part in ipairs(parts) do part.Anchored = false end
end

local function walkToAndFace(hum, char, targetPos, lookVec, radiusOK)
    radiusOK = radiusOK or 4

    for attempt = 1, 10 do
        if not courierRunning then break end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then break end

        local dist = (hrp.Position - targetPos).Magnitude
        if dist <= radiusOK then
            print("[Courier] Sudah di lokasi! (dist: " .. math.floor(dist) .. ")")
            break
        end

        faceDirection(lookVec)

        print("[Courier] Walk attempt #" .. attempt .. " | dist: " .. math.floor(dist))
        hum:MoveTo(targetPos)

        local t = tick()
        repeat
            task.wait(0.1)
            hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then break end
        until not courierRunning
            or (hrp and (hrp.Position - targetPos).Magnitude <= radiusOK)
            or (tick() - t >= 8)
    end

    lookToDirection(lookVec)
end

local function stopCourierLoop()
    courierRunning = false
    if ServiceEventConn then ServiceEventConn:Disconnect() ServiceEventConn = nil end
    local cam = Workspace.CurrentCamera
    if cam then cam.CameraType = Enum.CameraType.Custom end
    print("[Courier] Stopped.")
end

-- =================================================================
-- MAIN COURIER LOOP
-- =================================================================
local function startCourierLoop()
    local job = CourierJob
    if courierRunning then return end
    courierRunning = true
    print("[Courier] Loop Dimulai - Manual Spot Mode")

    local activePackageNum = nil

    local serviceEvent = ReplicatedStorage:FindFirstChild("ServiceEvent", true)
    if serviceEvent then
        ServiceEventConn = serviceEvent.OnClientEvent:Connect(function(eventName, action, paketNum)
            if action == "Create" then
                activePackageNum = tostring(paketNum)
                print("[Courier] Paket #" .. activePackageNum .. " Terdeteksi!")
            elseif action == "Remove" then
                if activePackageNum == tostring(paketNum) then activePackageNum = nil end
            end
        end)
    end

    pcall(function() ReplicatedStorage:WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest"):FireServer(job.Name, job.TeamId, 1, 0, "Detector") end)
    task.wait(1.5)

    local SELECTED_CAR = SpawnCar.SelectedCar or "Yamahax-MioSporty"
    
    -- Spawn Awal & Ambil Paket Pertama
    pcall(function() ReplicatedStorage:WaitForChild("SpawnCarEvents"):WaitForChild("SpawnCar"):FireServer(SELECTED_CAR) end)
    task.wait(5)
    rideCourierMotor()
    task.wait(1)
    local motor = findCourierMotor()
    if motor then motor:SetPrimaryPartCFrame(CFrame.new(job.X, job.Y, job.Z)) end
    task.wait(0.5)

    jumpAndWait()

    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:MoveTo(Vector3.new(-5109.06, 5.18, -3758.69))
        task.wait(3)
        
        setCameraBehindPlayer()
        task.wait(0.5)
        
        pcall(function()
            local prompt = Workspace.Livrason.Take1.Take.ProximityPrompt
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.1)
            prompt:InputHoldEnd()
        end)
        
        local cam = Workspace.CurrentCamera
        if cam then cam.CameraType = Enum.CameraType.Custom end
    end
    task.wait(2)

    -- =============================================================
    -- LOOP ANTAR PAKET
    -- =============================================================
    while courierRunning do
        while courierRunning and not activePackageNum do task.wait(0.5) end
        if not courierRunning then break end

        local data = PackageData[activePackageNum]
        if not data then
            warn("[Courier] Data koordinat untuk paket #" .. activePackageNum .. " tidak ditemukan!")
            activePackageNum = nil
            continue
        end

        -- 1. Cari motor yang ada dulu, kalau tidak ada baru spawn
        print("[Courier] Cek motor untuk paket #" .. activePackageNum)
        local existingMotor = findCourierMotor()
        if existingMotor then
            print("[Courier] Motor ditemukan, langsung naik!")
            rideCourierMotor()
            task.wait(1)
        else
            print("[Courier] Motor tidak ada, spawn baru...")
            pcall(function() ReplicatedStorage:WaitForChild("SpawnCarEvents"):WaitForChild("SpawnCar"):FireServer(SELECTED_CAR) end)
            task.wait(4)
            rideCourierMotor()
            task.wait(1)
        end

        -- 2. Tween ke Spot Teleport
        local currentMotor = findCourierMotor()
        if currentMotor then
            print("[Courier] Tweening ke spot aman paket #" .. activePackageNum)
            _tweenVehicle(currentMotor, data.Tween, TWEEN_DURATION)
        end

        -- 3. Sampai di lokasi tween → wait 2 detik → jump keluar kendaraan
        print("[Courier] Tiba di spot, wait 2 detik lalu jump keluar...")
        task.wait(2)
        jumpAndWait()
        print("[Courier] Sudah keluar kendaraan, mulai walk!")

        -- 4. Walk ke lokasi paket
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            print("[Courier] Walking ke titik paket #" .. activePackageNum)
            walkToAndFace(hum, char, data.Walk, data.WalkLook, 4)
        end
        task.wait(0.3)

        -- 5. Rotate player ke arah paket, kamera di belakang player, wait 1 detik
        print("[Courier] Rotate player + kamera, wait 1 detik...")
        faceDirection(data.WalkLook)
        task.wait(0.5)
        setCameraBehindPlayer()
        task.wait(1)

        -- 6. Hold paket setelah dipastikan sudah di lokasi
        print("[Courier] Mencoba hold paket #" .. activePackageNum)
        pcall(function()
            local LocationFolder = Workspace.Livrason.Location
            local paketModel     = LocationFolder:FindFirstChild(activePackageNum)
            local block          = paketModel and paketModel:FindFirstChild("Block")
            if block then
                local prompt = block:FindFirstChild("ProximityPrompt")
                if prompt then
                    local box = LocalPlayer.Backpack:FindFirstChild("Box") or char:FindFirstChild("Box")
                    if box and hum then hum:EquipTool(box) task.wait(0.3) end
                    prompt:InputHoldBegin()
                    task.wait(prompt.HoldDuration + 0.1)
                    prompt:InputHoldEnd()
                end
            end
        end)
        task.wait(0.5)

        -- Kembalikan kamera ke Custom setelah hold paket
        local cam = Workspace.CurrentCamera
        if cam then cam.CameraType = Enum.CameraType.Custom end

        -- 6. Look ke arah AfterLook
        print("[Courier] Memutar arah sebelum spawn kendaraan...")
        lookToDirection(data.AfterLook)

        print("[Courier] Paket #" .. activePackageNum .. " Selesai!")
        totalCourierCycle = totalCourierCycle + 1
        activePackageNum = nil
        
        task.wait(3)
        if sendCourierWebhook then pcall(sendCourierWebhook) end
        
        task.wait(1)
    end

    stopCourierLoop()
end


-- CINEMATIC MODULE
-- =============================================
local cinemaPlayer = Players.LocalPlayer
local cinemaCamera = workspace.CurrentCamera

local SHOTS = {
    { name = "Sorot depan motor",     targetPart = "chassis",        offset = Vector3.new(0, 1.5, -12),   fov = 40, duration = 7 },
    { name = "Close up roda depan",   targetPart = "ban",            offset = Vector3.new(3, 1, -2),      fov = 28, duration = 7 },
    { name = "Velg roda depan",       targetPart = "RIMS",           offset = Vector3.new(3, 0.5, -1),    fov = 22, duration = 7 },
    { name = "Roda belakang",         targetPart = "ban.001",        offset = Vector3.new(-3, 1, 2),      fov = 28, duration = 7 },
    { name = "Body & Tangki",         targetPart = "PAINT",          offset = Vector3.new(4, 2.5, 0),     fov = 38, duration = 7 },
    { name = "Jok motor",             targetPart = "jok",            offset = Vector3.new(3, 2, 0),       fov = 30, duration = 7 },
    { name = "Dek depan",             targetPart = "dekdepan",       offset = Vector3.new(3, 1.5, -2),    fov = 28, duration = 7 },
    { name = "Dek belakang",          targetPart = "DDS_RearFender", offset = Vector3.new(-3, 1.5, 2),    fov = 28, duration = 7 },
    { name = "Lampu depan",           targetPart = "refdepan",       offset = Vector3.new(0, 1, -5),      fov = 22, duration = 7 },
    { name = "Lampu belakang",        targetPart = "stoplamp",       offset = Vector3.new(0, 1, -5),       fov = 22, duration = 7 },
    { name = "Spion",                 targetPart = "SPION",          offset = Vector3.new(0, 2, -3),      fov = 25, duration = 7 },
    { name = "Dashboard speedometer", targetPart = "dashboard",      offset = Vector3.new(0, 2.5, -3),    fov = 22, duration = 7 },
    { name = "Stang motor",           targetPart = "stang",          offset = Vector3.new(0, 2.5, -3),    fov = 25, duration = 7 },
    { name = "Mesin",                 targetPart = "mesineee",       offset = Vector3.new(3, 0.5, 1),     fov = 28, duration = 7 },
    { name = "Knalpot silencer",      targetPart = "silencer",       offset = Vector3.new(-4, 1, 2),      fov = 25, duration = 7 },
    { name = "Knalpot",               targetPart = "knalpot",        offset = Vector3.new(-3, 0.5, 1),    fov = 22, duration = 7 },
    { name = "Plat depan",            targetPart = "Plat",           offset = Vector3.new(0, 1, -3),      fov = 20, duration = 7 },
    { name = "Hero shot samping",     targetPart = "chassis",        offset = Vector3.new(12, 4, 0),      fov = 45, duration = 7 },
    { name = "Hero shot depan",       targetPart = "chassis",        offset = Vector3.new(0, 3, -12),     fov = 45, duration = 7 },
    { name = "Hero shot atas",        targetPart = "chassis",        offset = Vector3.new(0, 15, 0),      fov = 50, duration = 7 },
}

local DRIFT_PATTERNS = {
    Vector3.new( 0.8,  0.3,  0),
    Vector3.new(-0.8,  0.2,  0),
    Vector3.new( 0,    0.5, -0.4),
    Vector3.new( 0.5, -0.2,  0.3),
    Vector3.new(-0.5,  0.4, -0.3),
}

local function getCinemaMotor()
    local username = cinemaPlayer.Name
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(username, 1, true) then
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("VehicleSeat") then return obj end
            end
        end
    end
    return nil
end

local function findCinemaPart(motor, partName)
    local best, bestMag = nil, 0
    for _, part in ipairs(motor:GetDescendants()) do
        if part.Name == partName and part:IsA("BasePart") then
            local m = part.Size.Magnitude
            if m > bestMag then best = part; bestMag = m end
        end
    end
    if not best then
        for _, part in ipairs(motor:GetDescendants()) do
            if part.Name == "chassis" and part:IsA("BasePart") then return part end
        end
    end
    return best
end

local function easeInOutSine(t)
    return -(math.cos(math.pi * t) - 1) / 2
end

local hiddenUIs = {}

local function hideAllUI()
    hiddenUIs = {}
    for _, gui in ipairs(cinemaPlayer.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") or gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            table.insert(hiddenUIs, { gui = gui, enabled = gui.Enabled })
            gui.Enabled = false
        end
    end
    local StarterGui = game:GetService("StarterGui")
    for _, item in ipairs({
        Enum.CoreGuiType.Backpack,
        Enum.CoreGuiType.Chat,
        Enum.CoreGuiType.Health,
        Enum.CoreGuiType.PlayerList,
        Enum.CoreGuiType.EmotesMenu,
    }) do
        pcall(function() StarterGui:SetCoreGuiEnabled(item, false) end)
    end
end

local function showAllUI()
    for _, data in ipairs(hiddenUIs) do
        if data.gui and data.gui.Parent then
            data.gui.Enabled = data.enabled
        end
    end
    hiddenUIs = {}
    local StarterGui = game:GetService("StarterGui")
    for _, item in ipairs({
        Enum.CoreGuiType.Backpack,
        Enum.CoreGuiType.Chat,
        Enum.CoreGuiType.Health,
        Enum.CoreGuiType.PlayerList,
        Enum.CoreGuiType.EmotesMenu,
    }) do
        pcall(function() StarterGui:SetCoreGuiEnabled(item, true) end)
    end
end

local cinematicRunning = false

local function playCinematic()
    if cinematicRunning then return end
    local motor = getCinemaMotor()
    if not motor then
        -- warn("Motor ga ketemu! Spawn motor dulu bro.")
        return
    end

    cinematicRunning = true
    hideAllUI()

    cinemaCamera.CameraType = Enum.CameraType.Scriptable
    -- print("Cinematic mulai: " .. motor.Name)
    -- print("Total: " .. #SHOTS .. " shot | " .. (#SHOTS * 7) .. " detik")

    local initPart = findCinemaPart(motor, SHOTS[1].targetPart)
    if initPart then
        local motorCF = motor:GetBoundingBox()
        local initOffset = motorCF:VectorToWorldSpace(SHOTS[1].offset)
        cinemaCamera.CFrame = CFrame.new(initPart.Position + initOffset, initPart.Position)
        cinemaCamera.FieldOfView = SHOTS[1].fov
    end

    for i, shot in ipairs(SHOTS) do
        if not cinematicRunning then break end

        local targetPart = findCinemaPart(motor, shot.targetPart)
        if not targetPart then
            -- warn("Skip: " .. shot.targetPart)
            continue
        end

        -- print("Ã¢â€“Âº Shot " .. i .. "/" .. #SHOTS .. " - " .. shot.name)

        local motorCF = motor:GetBoundingBox()
        local worldOffset = motorCF:VectorToWorldSpace(shot.offset)
        local partPos = targetPart.Position
        local shotTargetCF = CFrame.new(partPos + worldOffset, partPos)

        local transStart = cinemaCamera.CFrame
        local transElapsed = 0
        local transDone = false
        local transConn

        game:GetService("TweenService"):Create(cinemaCamera,
            TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { FieldOfView = shot.fov }
        ):Play()

        transConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
            transElapsed = transElapsed + dt
            local alpha = math.min(transElapsed / 3, 1)
            local smooth = easeInOutSine(alpha)
            cinemaCamera.CFrame = transStart:Lerp(shotTargetCF, smooth)
            if alpha >= 1 then transDone = true; transConn:Disconnect() end
        end)
        repeat task.wait(0.05) until transDone

        local holdTime = shot.duration - 3
        local holdElapsed = 0
        local driftDir = DRIFT_PATTERNS[(i - 1) % #DRIFT_PATTERNS + 1]
        local holdDone = false
        local holdConn

        holdConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
            holdElapsed = holdElapsed + dt
            local driftProgress = math.sin(holdElapsed * 0.4)
            local driftOffset = driftDir * driftProgress * 1.5
            local currentPartPos = targetPart.Position
            local driftedCamPos = (partPos + worldOffset) + driftOffset
            local driftCF = CFrame.new(driftedCamPos, currentPartPos)
            cinemaCamera.CFrame = cinemaCamera.CFrame:Lerp(driftCF, 0.02)
            if holdElapsed >= holdTime then
                holdDone = true
                holdConn:Disconnect()
            end
        end)
        repeat task.wait(0.05) until holdDone
    end

    -- print("Cinematic selesai! Balik ke balapan...")
    game:GetService("TweenService"):Create(cinemaCamera,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { FieldOfView = 70 }
    ):Play()
    task.wait(2)
    cinemaCamera.CameraType = Enum.CameraType.Custom

    showAllUI()
    cinematicRunning = false
end

local function stopCinematic()
    cinematicRunning = false
    cinemaCamera.CameraType = Enum.CameraType.Custom
    cinemaCamera.FieldOfView = 70
    showAllUI()
    -- print("Cinematic dihentikan")
end

-- =============================================
-- GUI - TAB RACE
-- =============================================


local RaceTab = Window:Tab({
    Title = "Race",
    Icon = "motorbike",
	IconColor = Mains,
	IconShape = "Square",
	Border = true,
})

local SpeedSection = RaceTab:Section({ Title = "Speed Hack", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = false })

local speedValueInput = SpeedSection:Input({
    Type = "Input", 
    Title = "Speed Value",
    Value = uiConfig.SpeedValue or "100",
    Placeholder = "Enter speed (10-1000)",
    Callback = function(value)
        local speed = tonumber(value)
        if speed and speed >= 10 and speed <= 1000 then
            VehicleSpeed.SetSpeed(speed)
        end
        if not isUILoading then
            uiConfig.SpeedValue = value
            saveUIConfig(uiConfig)
        end
    end
})
VehicleSpeed.SetSpeed(tonumber(uiConfig.SpeedValue) or 100)

local speedHackToggle = SpeedSection:Toggle({
    Title = "Enable Speed Hack",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.SpeedHack = on
            saveUIConfig(uiConfig)
        end
        if on then VehicleSpeed.Start() else VehicleSpeed.Stop() end
    end
})

local SlowSection = RaceTab:Section({ Title = "Slow Race (Gradual)", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = false })

local slowMaxSpeedInput = SlowSection:Input({
    Type = "Input", 
    Title = "Max Speed",
    Value = uiConfig.SlowMaxSpeed or "200",
    Placeholder = "Batas max speed (10-1000)",
    Callback = function(value)
        local v = tonumber(value)
        if v and v >= 10 and v <= 1000 then
            SlowRace.MaxSpeed = v
        end
        if not isUILoading then
            uiConfig.SlowMaxSpeed = value
            saveUIConfig(uiConfig)
        end
    end
})
SlowRace.MaxSpeed = tonumber(uiConfig.SlowMaxSpeed) or 200

local slowAccelInput = SlowSection:Input({
    Type = "Input", 
    Title = "Acceleration (kelipatan)",
    Value = uiConfig.SlowAccel or "3",
    Placeholder = "Kelipatan akselerasi (1-20)",
    Callback = function(value)
        local v = tonumber(value)
        if v and v >= 1 and v <= 20 then
            SlowRace.AccelMultiplier = v
        end
        if not isUILoading then
            uiConfig.SlowAccel = value
            saveUIConfig(uiConfig)
        end
    end
})
SlowRace.AccelMultiplier = tonumber(uiConfig.SlowAccel) or 3

local slowRaceToggle = SlowSection:Toggle({
    Title = "Enable Slow Race",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.SlowRace = on
            saveUIConfig(uiConfig)
        end
        if on then SlowRace.Start() else SlowRace.Stop() end
    end
})

local CinematicSection = RaceTab:Section({ Title = "Cinematic", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = false })

CinematicSection:Toggle({
    Title = "Enable Cinematic",
    Value = false,
    Callback = function(on)
        if on then
            task.spawn(playCinematic)
        else
            stopCinematic()
        end
    end
})

local LightingService = game:GetService("Lighting")
local originalLighting = {}

local ultraGrafikToggle = CinematicSection:Toggle({
    Title = "Grafik Mode Ultra",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.UltraGrafik = on
            saveUIConfig(uiConfig)
        end
        if on then
            if not originalLighting.saved then
                pcall(function() originalLighting.Technology = LightingService.Technology end)
                originalLighting.Brightness = LightingService.Brightness
                originalLighting.ExposureCompensation = LightingService.ExposureCompensation
                originalLighting.Ambient = LightingService.Ambient
                originalLighting.OutdoorAmbient = LightingService.OutdoorAmbient
                originalLighting.ColorShift_Top = LightingService.ColorShift_Top
                originalLighting.ColorShift_Bottom = LightingService.ColorShift_Bottom
                originalLighting.GlobalShadows = LightingService.GlobalShadows
                originalLighting.ShadowSoftness = LightingService.ShadowSoftness
                originalLighting.saved = true
            end

            -- Hapus effect lama
            for _, e in ipairs(LightingService:GetChildren()) do
                if e.Name == "Blur" 
                or e.Name == "menuBlur"
                or e.ClassName == "BloomEffect"
                or e.ClassName == "SunRaysEffect"
                or e.ClassName == "DepthOfFieldEffect"
                or e.ClassName == "ColorCorrectionEffect"
                or e.ClassName == "Atmosphere" then
                    e:Destroy()
                end
            end

            -- Technology ke Future
            pcall(function() LightingService.Technology = Enum.Technology.Future end)
            LightingService.Brightness           = 3
            LightingService.ExposureCompensation = 0.3
            LightingService.Ambient              = Color3.fromRGB(80, 80, 90)
            LightingService.OutdoorAmbient       = Color3.fromRGB(100, 110, 130)
            LightingService.ColorShift_Top       = Color3.fromRGB(255, 240, 200)
            LightingService.ColorShift_Bottom    = Color3.fromRGB(20, 20, 40)
            LightingService.GlobalShadows        = true
            LightingService.ShadowSoftness       = 0.1

            -- Bloom (cahaya highlight doang, ga blur)
            local bloom = Instance.new("BloomEffect")
            bloom.Name      = "UltraBloom"
            bloom.Intensity = 0.4
            bloom.Size      = 16
            bloom.Threshold = 0.98
            bloom.Parent    = LightingService

            -- Sun Rays
            local sunRays = Instance.new("SunRaysEffect")
            sunRays.Name      = "UltraSunRays"
            sunRays.Intensity = 0.12
            sunRays.Spread    = 0.5
            sunRays.Parent    = LightingService

            -- Color Correction (warna cinematic, NO blur)
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name       = "UltraCC"
            cc.Brightness = 0.02
            cc.Contrast   = 0.2
            cc.Saturation = 0.25
            cc.TintColor  = Color3.fromRGB(255, 248, 235)
            cc.Parent     = LightingService

            -- Atmosphere
            local atm = Instance.new("Atmosphere")
            atm.Name    = "UltraAtm"
            atm.Density = 0.25
            atm.Offset  = 0.2
            atm.Color   = Color3.fromRGB(199, 210, 230)
            atm.Decay   = Color3.fromRGB(90, 100, 120)
            atm.Glare   = 0.3
            atm.Haze    = 1.2
            atm.Parent  = LightingService

            -- print("ULTRA HD AKTIF - NO BLUR!")
            -- print("Technology: " .. tostring(LightingService.Technology))
        else
            for _, e in ipairs(LightingService:GetChildren()) do
                if e.Name == "UltraBloom" or e.Name == "UltraSunRays" or e.Name == "UltraCC" or e.Name == "UltraAtm" then
                    e:Destroy()
                end
            end
            if originalLighting.saved then
                pcall(function() LightingService.Technology = originalLighting.Technology end)
                LightingService.Brightness = originalLighting.Brightness
                LightingService.ExposureCompensation = originalLighting.ExposureCompensation
                LightingService.Ambient = originalLighting.Ambient
                LightingService.OutdoorAmbient = originalLighting.OutdoorAmbient
                LightingService.ColorShift_Top = originalLighting.ColorShift_Top
                LightingService.ColorShift_Bottom = originalLighting.ColorShift_Bottom
                LightingService.GlobalShadows = originalLighting.GlobalShadows
                LightingService.ShadowSoftness = originalLighting.ShadowSoftness
            end
            -- print("ULTRA HD NONAKTIF")
        end
    end
})

-- =============================================
-- GUI - TAB GARAGE
-- =============================================

local initialCarList = getCarList()

local GarageTab = Window:Tab({
    Title = "Garasi",
    Icon = "warehouse",
	IconColor = Mains,
	IconShape = "Square",
	Border = true,
})

local GarageSection = GarageTab:Section({ Title = "Spawn Kendaraan", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = true })

local carDropdown = GarageSection:Dropdown({
    Title = "Pilih Kendaraan",
    Multi = false,
    Options = initialCarList,
    Value = initialCarList[1],
    Callback = function(selected)
        if selected ~= "Refresh dulu..." then
            SpawnCar.SelectedCar = selected
        end
    end
})
SpawnCar.SelectedCar = initialCarList[1] ~= "Refresh dulu..." and initialCarList[1] or nil

GarageSection:Button({
    Title = "Refresh List Kendaraan",
    Callback = function()
        local cars = getCarList()
        if cars[1] ~= "Refresh dulu..." then
            pcall(function()
                carDropdown:Refresh(cars, cars[1])
            end)
            SpawnCar.SelectedCar = cars[1]
        end
    end
})

GarageSection:Button({
    Title = "Spawn Kendaraan",
    Callback = function() SpawnCar.Spawn() end
})

GarageSection:Button({
    Title = "Despawn Kendaraan",
    Callback = function() SpawnCar.Despawn() end
})

GarageSection:Button({
    Title = "Ride Motor",
    Callback = function() rideMotor() end
})

local autoRideToggle = GarageSection:Toggle({
    Title = "Auto Ride after Spawn",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.AutoRide = on
            saveUIConfig(uiConfig)
        end
        SpawnCar.AutoRide = on
    end
})

local autoRideAlwaysToggle = GarageSection:Toggle({
    Title = "Auto Ride Always",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.AutoRideAlways = on
            saveUIConfig(uiConfig)
        end
        SpawnCar.AutoRideAlways = on
        if on then SpawnCar.StartAutoRideAlways()
        else SpawnCar.StopAutoRideAlways() end
    end
})

-- =============================================
-- FUNGSI UTAMA INJECTOR A-CHASSIS (AMAN DARI DETEKSI)
-- =============================================
local function InjectMesin(HP_Mult, RPM_Add, Ratio_Mult, FD_Mult, NamaMode)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
        local vehicle = char.Humanoid.SeatPart.Parent
        while vehicle and not vehicle:IsA("Model") do vehicle = vehicle.Parent end
        
        if vehicle then
            local foundTune = false
            for _, s in pairs(vehicle:GetDescendants()) do
                if s:IsA("LocalScript") then
                    local name = string.lower(s.Name)
                    if string.find(name, "limit") or string.find(name, "speed") or string.find(name, "cap") then
                        if name ~= "a-chassis interface" and name ~= "drive" then
                            pcall(function() s.Disabled = true s:Destroy() end)
                        end
                    end
                end
            end
            for _, v in pairs(vehicle:GetDescendants()) do
                if v:IsA("ModuleScript") and (v.Name == "Tune" or string.find(string.lower(v.Name), "tune")) then
                    pcall(function()
                        local tune = require(v)
                        if tune.Horsepower then tune.Horsepower = tune.Horsepower * HP_Mult end
                        if tune.Redline then tune.Redline = tune.Redline + RPM_Add end
                        if tune.Ratios then
                            for i, ratio in pairs(tune.Ratios) do
                                if type(ratio) == "number" and ratio > 0 then tune.Ratios[i] = ratio * Ratio_Mult end
                            end
                        end
                        if tune.FinalDrive then tune.FinalDrive = tune.FinalDrive * FD_Mult end
                        if tune.Limiter ~= nil then tune.Limiter = false end
                        if tune.RevLimit then tune.RevLimit = 999999 end
                        if tune.SpeedLimit then tune.SpeedLimit = false end
                        if tune.TopSpeed then tune.TopSpeed = 999999 end
                        if tune.MaxSpeed then tune.MaxSpeed = 999999 end
                        if tune.DragMult then tune.DragMult = tune.DragMult * 0.05 end 
                        if tune.Weight then tune.Weight = tune.Weight * 0.7 end
                        foundTune = true
                    end)
                end
            end
            
            if foundTune then
                WindUI:Notify({ Title = "âœ… " .. NamaMode, Content = "Aman! Turun lalu naik motor lagi ya bosku!", Duration = 5 })
            else
                WindUI:Notify({ Title = "âŒ Gagal Inject", Content = "Bukan A-Chassis standar.", Duration = 4 })
            end
        end
    else
        WindUI:Notify({ Title = "âš ï¸ Woi Bosku!", Content = "Naik ke motornya dulu!", Duration = 3 })
    end
end

-- =============================================
-- GUI - TAB INJECTION
-- =============================================

local InjectionTab = Window:Tab({
    Title = "Injection",
    Icon = "syringe",
    IconColor = Mains,
    IconShape = "Square",
    Border = true,
})

local PresetSection = InjectionTab:Section({ Title = "Preset Injection", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = false })

PresetSection:Button({ Title = "MODE SUNMORI", Callback = function() InjectMesin(1.5, 2000, 0.9, 0.9, "Mode Sunmori Aktif") end })
PresetSection:Button({ Title = "MODE BALAP LIAR", Callback = function() InjectMesin(3.5, 5000, 0.75, 0.75, "Mode Balap Aktif") end })
PresetSection:Button({ Title = "MODE DEWA", Callback = function() InjectMesin(8, 15000, 0.45, 0.45, "Mode Dewa Aktif") end })
PresetSection:Button({ Title = "RESET STANDAR PABRIK", Callback = function() WindUI:Notify({ Title = "â„¹ï¸ Info", Content = "Respawn kendaraan dari menu game untuk reset.", Duration = 5 }) end })

local CustomSection = InjectionTab:Section({ Title = "Custom Injection", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = false })

local customHP, customRPM, customRatio, customFD = 2, 5000, 0.8, 0.8

customHP    = tonumber(uiConfig.CustomHP)    or customHP
customRPM   = tonumber(uiConfig.CustomRPM)   or customRPM
customRatio = tonumber(uiConfig.CustomRatio) or customRatio
customFD    = tonumber(uiConfig.CustomFD)    or customFD

CustomSection:Input({ Type = "Input", Title = "Pengali Tenaga (HP)", Value = uiConfig.CustomHP or "3", Placeholder = "Contoh: 3", Callback = function(Text) local val = tonumber(Text) if val then customHP = val end if not isUILoading then uiConfig.CustomHP = Text saveUIConfig(uiConfig) end end })
CustomSection:Input({ Type = "Input", Title = "Tambahan RPM", Value = uiConfig.CustomRPM or "8000", Placeholder = "Contoh: 8000", Callback = function(Text) local val = tonumber(Text) if val then customRPM = val end if not isUILoading then uiConfig.CustomRPM = Text saveUIConfig(uiConfig) end end })
CustomSection:Input({ Type = "Input", Title = "Pengali Rasio Gigi", Value = uiConfig.CustomRatio or "0.6", Placeholder = "Contoh: 0.6", Callback = function(Text) local val = tonumber(Text) if val then customRatio = val end if not isUILoading then uiConfig.CustomRatio = Text saveUIConfig(uiConfig) end end })
CustomSection:Input({ Type = "Input", Title = "Pengali Final Drive", Value = uiConfig.CustomFD or "0.6", Placeholder = "Contoh: 0.6", Callback = function(Text) local val = tonumber(Text) if val then customFD = val end if not isUILoading then uiConfig.CustomFD = Text saveUIConfig(uiConfig) end end })
CustomSection:Button({ Title = "INJECT CUSTOM TUNE SEKARANG", Callback = function() InjectMesin(customHP, customRPM, customRatio, customFD, "Custom Tune Aktif") end })

-- =============================================
-- =============================================
-- GUI - TAB JOB
-- =============================================


-- =============================================
-- CONFIG LOADER & WEBHOOK LOGIC
-- =============================================
local HttpService = game:GetService("HttpService")

local jobConfigPath = "DDS_JobConfig.json"
local function loadJobConfig()
    local ok, data = pcall(readfile, jobConfigPath)
    if ok and data then
        local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok2 then return decoded end
    end
    return {}
end
local function saveJobConfig(data) pcall(writefile, jobConfigPath, HttpService:JSONEncode(data)) end
local jobConfig = loadJobConfig()
if jobConfig.CourierTweenDuration then TWEEN_DURATION = jobConfig.CourierTweenDuration end
local isJobLoading = true

local webhookConfigPath = "DDS_WebhookConfig.json"
local function loadWebhookConfig()
    local ok, data = pcall(readfile, webhookConfigPath)
    if ok and data then
        local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok2 then return decoded end
    end
    return {}
end
local function saveWebhookConfig(data) pcall(writefile, webhookConfigPath, HttpService:JSONEncode(data)) end
local whConfig      = loadWebhookConfig()
local isWhLoading   = true
local webhookURL    = whConfig.URL    or ""
local webhookActive = whConfig.Active or false
local webhookDelay  = whConfig.Delay  or 10

local uangAwal  = nil
local totalCycle = 0

local function parseUang(text)
    local clean = text:gsub("Rp%.", ""):gsub("%s+", "")
    return tonumber(clean) or 0
end

local function formatUang(num)
    local s      = tostring(math.floor(num))
    local result = ""
    local count  = 0
    for i = #s, 1, -1 do
        count  = count + 1
        result = s:sub(i, i) .. result
        if count % 3 == 0 and i ~= 1 then result = "." .. result end
    end
    return "Rp. " .. result
end

local function sendWebhook(uangAwalNum, uangSekarangNum, profit, cycle)
    if webhookURL == "" then return end
    local payload = {
        embeds = {{
            title       = "Monitoring Profit DDS Script By king Vypers!",
            description = "**Status:** `🟢 Farming Aktif`",
            color       = 3066993,
            fields      = {
                { name = "💰 Uang Awal",    value = "**" .. formatUang(uangAwalNum) .. "**",        inline = false },
                { name = "💵 Uang Sekarang",value = "**" .. formatUang(uangSekarangNum) .. "**",    inline = false },
                { name = "📈 Total Profit", value = "```diff\n+ " .. formatUang(profit) .. "\n```", inline = false },
                { name = "🔄 Total Cycle",  value = "**" .. tostring(cycle) .. "x**",               inline = false },
            },
            footer = { text = "DDS Premium Script • Time: " .. os.date("%H:%M:%S") }
        }}
    }
    local body = HttpService:JSONEncode(payload)
    task.spawn(function()
        pcall(function()
            if syn and syn.request then syn.request({ Url = webhookURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
            elseif request then request({ Url = webhookURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
        end)
    end)
end

task.spawn(function()
    while true do
        task.wait(webhookDelay)
        if not webhookActive or webhookURL == "" then continue end
        local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
        local moneyLabel  = nil
        pcall(function() moneyLabel = PlayerGui.MainUI.Frame4.TextLabel end)
        if not moneyLabel then continue end
        local uangSekarangNum = parseUang(moneyLabel.Text)
        if uangAwal == nil then uangAwal = uangSekarangNum end
        local profit = uangSekarangNum - uangAwal
        sendWebhook(uangAwal, uangSekarangNum, profit, totalCycle)
    end
end)

local whCourierConfigPath = "DDS_WebhookCourierConfig.json"
local function loadCourierWebhookConfig()
    local ok, data = pcall(readfile, whCourierConfigPath)
    if ok and data then
        local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok2 then return decoded end
    end
    return {}
end
local function saveCourierWebhookConfig(data) pcall(writefile, whCourierConfigPath, HttpService:JSONEncode(data)) end
local whCourierConfig      = loadCourierWebhookConfig()
local isWhCourierLoading   = true
local webhookCourierURL    = whCourierConfig.URL    or ""
local webhookCourierActive = whCourierConfig.Active or false

function sendCourierWebhook()
    if not webhookCourierActive or webhookCourierURL == "" then return end
    local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
    local moneyLabel  = nil
    pcall(function() moneyLabel = PlayerGui.MainUI.Frame4.TextLabel end)
    if not moneyLabel then return end
    
    local uangSekarangNum = parseUang(moneyLabel.Text)
    if uangAwalCourier == nil then uangAwalCourier = uangSekarangNum end
    local profit = uangSekarangNum - uangAwalCourier

    local payload = {
        embeds = {{
            title       = "⚙️ Courier Job - Monitoring Profit",
            description = "**Status:** `🟢 Farming Courier Aktif`",
            color       = 15507969,
            fields      = {
                { name = "💰 Uang Awal",    value = "**" .. formatUang(uangAwalCourier) .. "**",     inline = false },
                { name = "💵 Uang Sekarang",value = "**" .. formatUang(uangSekarangNum) .. "**", inline = false },
                { name = "📈 Total Profit", value = "```diff\n+ " .. formatUang(profit) .. "\n```", inline = false },
                { name = "🔄 Total Cycle",  value = "**" .. tostring(totalCourierCycle) .. "x**",        inline = false },
            },
            footer = { text = "DDS Premium Script • Time: " .. os.date("%H:%M:%S") }
        }}
    }
    local body = HttpService:JSONEncode(payload)
    task.spawn(function()
        pcall(function()
            if syn and syn.request then syn.request({ Url = webhookCourierURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
            elseif request then request({ Url = webhookCourierURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
        end)
    end)
end

local function sendWebhookRepairEvent(msg)
    if not webhookActive or webhookURL == "" then return end
    local payload = {
        embeds = {{
            title       = "⚙️ Auto Repair Event",
            description = "**Notice:** " .. tostring(msg),
            color       = 16711680,
            footer      = { text = "DDS Premium Script • Time: " .. os.date("%H:%M:%S") }
        }}
    }
    local body = HttpService:JSONEncode(payload)
    task.spawn(function()
        pcall(function()
            if syn and syn.request then syn.request({ Url = webhookURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
            elseif request then request({ Url = webhookURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
        end)
    end)
end

local function sendWebhookKickEvent(msg)
    if not webhookActive or webhookURL == "" then return end
    local payload = {
        embeds = {{
            title       = "🛑 Auto Kick Triggered",
            description = "**Notice:** " .. tostring(msg),
            color       = 16711680,
            footer      = { text = "DDS Premium Script • Time: " .. os.date("%H:%M:%S") }
        }}
    }
    local body = HttpService:JSONEncode(payload)
    task.spawn(function()
        pcall(function()
            if syn and syn.request then syn.request({ Url = webhookURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
            elseif request then request({ Url = webhookURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
        end)
    end)
end

-- =============================================
-- AUTO JOB BARISTA LOADER
-- =============================================

-- ① Load module dari GitHub
local BaristaModule = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SapuLidi-Eak/mantaplek123/refs/heads/main/lapuks.lua"
))()

-- ② Sambungkan webhook repair & kick event dari dds.lua ke module
BaristaModule.onRepairEvent = sendWebhookRepairEvent
BaristaModule.onKickEvent   = sendWebhookKickEvent

-- ③ Sync totalCycle tiap detik untuk webhook profit
task.spawn(function()
    while true do
        task.wait(1)
        totalCycle = BaristaModule.totalCycle
    end
end)

-- =============================================
-- CONFIG SAVE/LOAD (barista section)
-- =============================================
local baristaConfigPath = "DDS_BaristaConfig.json"

local function loadBaristaConfig()
    local ok, data = pcall(readfile, baristaConfigPath)
    if ok and data then
        local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok2 and decoded then return decoded end
    end
    return {}
end

local function saveBaristaConfig(data)
    pcall(writefile, baristaConfigPath, HttpService:JSONEncode(data))
end

local bCfg       = loadBaristaConfig()
local isBLoading = true

-- Apply saved config ke module
if bCfg.TimeoutMax     then BaristaModule.timeoutMax     = bCfg.TimeoutMax     end
if bCfg.TimeoutEnabled ~= nil then BaristaModule.timeoutEnabled = bCfg.TimeoutEnabled end
if bCfg.KickLimitMinutes then BaristaModule.kickLimitMinutes = bCfg.KickLimitMinutes end
if bCfg.KickLimitEnabled ~= nil then BaristaModule.kickLimitEnabled = bCfg.KickLimitEnabled end

-- =============================================
-- UI — JOB SECTION 
-- =============================================

local AutoJobTabSection = Window:Section({
    Title = "Auto Job",
    Opened = true,
})

local BaristaTab = AutoJobTabSection:Tab({
    Title = "Barista & Monitoring",
    Icon = "coffee",
    IconColor = Purple,
    IconShape = "Square",
    Border = true,
})

local CourierTab = AutoJobTabSection:Tab({
    Title = "Courier",
    Icon = "package",
    IconColor = Color3.fromHex("#ECA201"), -- Yellow
    IconShape = "Square",
    Border = true,
})

-- =============================================
-- BARISTA (Inside BaristaTab)
-- =============================================

local JobSection = BaristaTab:Section({
    Title          = "Auto Job Barista",
    Box            = true,
    TextXAlignment = "Center",
    TextSize       = 15,
    Opened         = true,
})

-- Toggle Auto Barista
local baristaToggle = JobSection:Toggle({
    Title = "Auto Barista",
    Value = false,
    Callback = function(on)
        if not isBLoading then
            bCfg.AutoBarista = on
            saveBaristaConfig(bCfg)
        end
        if on then
            BaristaModule:Start()
        else
            BaristaModule:Stop()
        end
    end
})

JobSection:Space()

-- ---- AUTO RESTART TIMEOUT ----
JobSection:Paragraph({ Title = "Auto Restart Jika Timeout" })

JobSection:Input({
    Type        = "Input",
    Title       = "Timeout (detik)",
    Value       = tostring(BaristaModule.timeoutMax),
    Placeholder = "Contoh: 90",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            BaristaModule.timeoutMax = num
            if not isBLoading then
                bCfg.TimeoutMax = num
                saveBaristaConfig(bCfg)
            end
        end
    end
})

local restartToggle = JobSection:Toggle({
    Title = "Auto Restart",
    Value = false,
    Callback = function(on)
        BaristaModule.timeoutEnabled = on
        if not isBLoading then
            bCfg.TimeoutEnabled = on
            saveBaristaConfig(bCfg)
        end
        if on then BaristaModule.lastServeTime = tick() end
    end
})

JobSection:Space()

-- ---- KICK LIMIT ----
JobSection:Paragraph({ Title = "Limit Auto Job (Auto Kick)" })

JobSection:Input({
    Type        = "Input",
    Title       = "Limit Menit",
    Value       = tostring(BaristaModule.kickLimitMinutes),
    Placeholder = "Contoh: 120",
    Callback    = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            BaristaModule.kickLimitMinutes = num
            if not isBLoading then
                bCfg.KickLimitMinutes = num
                saveBaristaConfig(bCfg)
            end
        end
    end
})

local kickToggle = JobSection:Toggle({
    Title = "Toggle Auto Kick",
    Value = false,
    Callback = function(on)
        BaristaModule.kickLimitEnabled = on
        if not isBLoading then
            bCfg.KickLimitEnabled = on
            saveBaristaConfig(bCfg)
        end
    end
})

-- =============================================
-- WEBHOOK SECTION (merged into BaristaTab)
-- =============================================

local WebhookSection = BaristaTab:Section({ Title = "Discord Webhook", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = true })

local whUrlInput = WebhookSection:Input({
    Type = "Input",
    Title = "Webhook URL",
    Value = whConfig.URL or "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(v)
        webhookURL = v
        if not isWhLoading then
            whConfig.URL = v
            saveWebhookConfig(whConfig)
            print("Webhook URL disimpan!")
        end
    end
})

local whDelayInput = WebhookSection:Input({
    Type = "Input",
    Title = "Delay Kirim (detik)",
    Value = tostring(whConfig.Delay or 10),
    Placeholder = "Contoh: 10",
    Callback = function(v)
        local num = tonumber(v)
        if num and num > 0 then
            webhookDelay = num
            if not isWhLoading then
                whConfig.Delay = num
                saveWebhookConfig(whConfig)
                print("Webhook delay di-set ke: " .. num .. " detik.")
            end
        end
    end
})

WebhookSection:Button({
    Title = "Test Webhook",
    Callback = function()
        if webhookURL == "" then
            print("Masukkan webhook URL dulu!")
            return
        end
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local moneyLabel = nil
        pcall(function() moneyLabel = PlayerGui.MainUI.Frame4.TextLabel end)
        
        if moneyLabel then
            local uangSekarang = parseUang(moneyLabel.Text)
            if uangAwal == nil then uangAwal = uangSekarang end
            local profit = uangSekarang - uangAwal
            sendWebhook(uangAwal, uangSekarang, profit, totalCycle)
        else
            print("Gagal membaca uang dari UI!")
        end
    end
})

local whToggle = WebhookSection:Toggle({
    Title = "Aktifkan Webhook",
    Value = false,
    Callback = function(v)
        webhookActive = v
        if not isWhLoading then
            whConfig.Active = v
            saveWebhookConfig(whConfig)
            
            if v then
                local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
                local moneyLabel = nil
                pcall(function() moneyLabel = PlayerGui.MainUI.Frame4.TextLabel end)
                if moneyLabel then
                    uangAwal = parseUang(moneyLabel.Text)
                    totalCycle = 0
                    print("Webhook aktif! Uang awal: " .. formatUang(uangAwal))
                end
            else
                print("Webhook dimatikan!")
            end
        end
    end
})

-- =============================================
-- COURIER (Inside CourierTab)
-- =============================================

local CourierSection = CourierTab:Section({ Title = "Auto Job Courier", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = true })

CourierSection:Button({
    Title = "Accept Job Courier",
    Callback = function()
        setJob(CourierJob)
    end
})

local courierToggle = CourierSection:Toggle({
    Title = "Auto Work Courier",
    Value = false,
    Callback = function(on)
        if not isJobLoading then
            jobConfig.AutoCourier = on
            saveJobConfig(jobConfig)
        end
        if on then
            task.spawn(startCourierLoop)
        else
            stopCourierLoop()
        end
    end
})

CourierSection:Input({
    Title       = "Kecepatan Tween (detik)",
    Desc        = "Durasi tween kendaraan ke spot. Makin kecil makin cepat.",
    Value       = tostring(TWEEN_DURATION),
    Placeholder = "Contoh: 60",
    Type        = "Input",
    Callback    = function(input)
        local val = tonumber(input)
        if val and val > 0 then
            TWEEN_DURATION = val
            if not isJobLoading then
                jobConfig.CourierTweenDuration = val
                saveJobConfig(jobConfig)
            end
            print("[Courier] Tween duration diset ke " .. val .. " detik")
        else
            print("[Courier] Input tidak valid, tetap " .. TWEEN_DURATION .. " detik")
        end
    end
})

CourierSection:Button({
    Title    = "Stop Manual",
    Callback = function() stopCourierLoop() end
})

local CourierWebhookSection = CourierTab:Section({ Title = "Discord Webhook Courier", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = true })

local whCourierUrlInput = CourierWebhookSection:Input({
    Type = "Input",
    Title = "Webhook URL",
    Value = whCourierConfig.URL or "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(v)
        webhookCourierURL = v
        if not isWhCourierLoading then
            whCourierConfig.URL = v
            saveCourierWebhookConfig(whCourierConfig)
            print("Webhook Courier URL disimpan!")
        end
    end
})

CourierWebhookSection:Button({
    Title = "Test Courier Webhook",
    Callback = function()
        if webhookCourierURL == "" then
            print("Masukkan webhook URL dulu!")
            return
        end
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        local moneyLabel = nil
        pcall(function() moneyLabel = PlayerGui.MainUI.Frame4.TextLabel end)
        
        if moneyLabel then
            local uangSekarang = parseUang(moneyLabel.Text)
            if uangAwalCourier == nil then uangAwalCourier = uangSekarang end
            local profit = uangSekarang - uangAwalCourier
            
            local payload = {
                embeds = {{
                    title       = "⚙️ Courier Job - Test Webhook",
                    description = "**Status:** `🟢 Test Connection`",
                    color       = 15507969,
                    fields      = {
                        { name = "💰 Uang Awal",    value = "**" .. formatUang(uangAwalCourier) .. "**",     inline = false },
                        { name = "💵 Uang Sekarang",value = "**" .. formatUang(uangSekarang) .. "**", inline = false },
                        { name = "📈 Total Profit", value = "```diff\n+ " .. formatUang(profit) .. "\n```", inline = false },
                        { name = "🔄 Total Cycle",  value = "**" .. tostring(totalCourierCycle) .. "x**",        inline = false },
                    },
                    footer = { text = "DDS Premium Script • Time: " .. os.date("%H:%M:%S") }
                }}
            }
            local body = HttpService:JSONEncode(payload)
            task.spawn(function()
                pcall(function()
                    if syn and syn.request then syn.request({ Url = webhookCourierURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
                    elseif request then request({ Url = webhookCourierURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end
                end)
            end)
        else
            print("Gagal membaca uang dari UI!")
        end
    end
})

local whCourierToggle = CourierWebhookSection:Toggle({
    Title = "Aktifkan Webhook Courier",
    Value = false,
    Callback = function(v)
        webhookCourierActive = v
        if not isWhCourierLoading then
            whCourierConfig.Active = v
            saveCourierWebhookConfig(whCourierConfig)
            
            if v then
                local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
                local moneyLabel = nil
                pcall(function() moneyLabel = PlayerGui.MainUI.Frame4.TextLabel end)
                if moneyLabel then
                    uangAwalCourier = parseUang(moneyLabel.Text)
                    totalCourierCycle = 0
                    print("Webhook Courier aktif! Uang awal: " .. formatUang(uangAwalCourier))
                end
            else
                print("Webhook Courier dimatikan!")
            end
        end
    end
})

task.spawn(function()
    task.wait(0.5)
    if whCourierConfig.Active then
        whCourierToggle:Set(true)
    end
    isWhCourierLoading = false
end)

task.spawn(function()
    task.wait(0.5)
    if jobConfig.TimeoutEnabled then
        restartToggle:Set(true)
    end
    if jobConfig.AutoBarista then
        baristaToggle:Set(true)
    end
    if jobConfig.AutoCourier then
        courierToggle:Set(true)
    end
    if jobConfig.KickLimitEnabled then
        kickToggle:Set(true)
    end
    if whConfig.Active then
        whToggle:Set(true)
    end
    isJobLoading = false
    isWhLoading = false
end)

-- CHARACTER ADDED
-- =============================================

local function onCharacterAdded(char)
    Character = char
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if Character then onCharacterAdded(Character) end

-- =============================================
-- HIDE STATS MODULE
-- =============================================

local HideStats = (function()
    local HS = {}

    local enabled = false
    local FakeName = "King Vypers"
    local FakeRank = "King Vypers Ã°Å¸â€˜â€˜"
    local updateLoop = nil

    local function getRankTags()
        local char = LocalPlayer.Character
        if not char then return nil end
        local head = char:FindFirstChild("Head")
        if not head then return nil end
        return head:FindFirstChild("RankTags")
    end

    local function updateStats()
        if not enabled then return end
        local rankTags = getRankTags()
        if not rankTags then return end

        local username = rankTags:FindFirstChild("Player_Username")
        local rank = rankTags:FindFirstChild("Player_Rank")

        if username then
            username.Text = FakeName
            local shadow = username:FindFirstChild("Shadow")
            if shadow then shadow.Text = FakeName end
        end
        if rank then rank.Text = FakeRank end
    end

    local function restoreStats()
        local rankTags = getRankTags()
        if not rankTags then return end

        local username = rankTags:FindFirstChild("Player_Username")
        local rank = rankTags:FindFirstChild("Player_Rank")

        if username then
            username.Text = LocalPlayer.Name
            local shadow = username:FindFirstChild("Shadow")
            if shadow then shadow.Text = LocalPlayer.Name end
        end
        if rank then rank.Text = "Member" end
    end

    local function startLoop()
        if updateLoop then return end
        updateLoop = true
        task.spawn(function()
            while updateLoop do
                task.wait(0.2)
                if enabled then updateStats() end
            end
        end)
    end

    function HS.Enable()
        enabled = true
        startLoop()
        updateStats()
    end

    function HS.Disable()
        enabled = false
        updateLoop = false
        restoreStats()
    end

    function HS.SetFakeName(name)
        FakeName = name or LocalPlayer.Name
        if enabled then updateStats() end
    end

    function HS.SetFakeRank(rank)
        FakeRank = rank or "Member"
        if enabled then updateStats() end
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if enabled then updateStats() end
    end)

    return HS
end)()

-- =============================================
-- ANTI-AFK MODULE
-- =============================================
local AntiAFK = (function()
    local AA = {
        Enabled = false,
        Thread = nil,
    }

    function AA.Start()
        if AA.Enabled then return end
        AA.Enabled = true

        AA.Thread = task.spawn(function()
            while AA.Enabled do
                task.wait(1100)
                if not AA.Enabled then break end
                pcall(function()
                    local char = game.Players.LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChild("Humanoid")
                    if not hrp or not hum then return end

                    -- Simulasi tekan W sebentar
                    keypress(0x57)
                    task.wait(0.1)
                    keyrelease(0x57)
                    task.wait(0.1)

                    -- Simulasi tekan space
                    keypress(0x20)
                    task.wait(0.1)
                    keyrelease(0x20)

                    print("Anti AFK: keypress fired!")
                end)
            end
        end)
    end

    function AA.Stop()
        if not AA.Enabled then return end
        AA.Enabled = false
        if AA.Thread then
            task.cancel(AA.Thread)
            AA.Thread = nil
        end
    end

    return AA
end)()
-- =============================================
-- ANTI-STAFF MODULE
-- =============================================

local AntiStaff = (function()
    local AS = {}
    AS.Active = false

    local GROUP_ID = 35102746
    local STAFF_RANKS = {
        [2]=true, [3]=true, [4]=true, [75]=true, [79]=true,
        [145]=true, [250]=true, [252]=true, [254]=true, [255]=true,
        [55]=true, [30]=true, [35]=true, [100]=true, [76]=true
    }

    local function checkLoop()
        while AS.Active do
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local ok, rank = pcall(function()
                        return player:GetRankInGroup(GROUP_ID)
                    end)
                    if ok and STAFF_RANKS[rank] then
                        LocalPlayer:Kick("Staff Detected! Auto Kicked for Safety.")
                        return
                    end
                end
            end
            task.wait(1)
        end
    end

    function AS.Start()
        if AS.Active then return end
        AS.Active = true
        task.spawn(checkLoop)
    end

    function AS.Stop()
        AS.Active = false
    end

    return AS
end)()

-- =============================================
-- AUTO RECONNECT + AUTO EXECUTE MODULE
-- =============================================

local AutoRejoin = (function()
    local AR = {}
    AR.Enabled = false
    AR.AutoExecEnabled = false

    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local disconnectSetup = false
    local hasTriggered = false

    -- URL script yang akan di-execute otomatis setelah rejoin
    -- WARNING: Ganti SCRIPT_URL dengan URL script UTAMA (misal pastebin/github raw cobadds.lua lo)
    -- JANGAN pakai URL vyperui.lua karena itu cuma UI-nya saja!
    local SCRIPT_URL = "https://raw.githubusercontent.com/SapuLidi-Eak/Asallahyakan/refs/heads/main/d_d_s.lua" 
    local EXEC_DELAY = 20 -- detik tunggu sebelum execute setelah rejoin (dilebihin dikit biar game load)

    -- Cari queue_on_teleport dari berbagai executor secara aman
    local function getQueueOnTeleport()
        local getQueue = nil
        pcall(function() getQueue = queue_on_teleport end)
        if getQueue then return getQueue end
        pcall(function() getQueue = queueonteleport end)
        if getQueue then return getQueue end
        pcall(function() getQueue = syn and syn.queue_on_teleport end)
        if getQueue then return getQueue end
        pcall(function() getQueue = fluxus and fluxus.queue_on_teleport end)
        if getQueue then return getQueue end
        return nil
    end

    local autoExecQueued = false
    local function setupAutoExecuteQueue()
        if autoExecQueued then return true end
        local queueTeleport = getQueueOnTeleport()
        if not queueTeleport then return false end
        if not AR.AutoExecEnabled then return false end

        local autoExecCode = string.format([[
            task.wait(%d)
            pcall(function()
                loadstring(game:HttpGet("%s"))()
            end)
        ]], EXEC_DELAY, SCRIPT_URL)

        local ok = pcall(function() queueTeleport(autoExecCode) end)
        if ok then autoExecQueued = true end
        return ok
    end

    local function doRejoin()
        if hasTriggered then return end
        if not AR.Enabled then return end
        hasTriggered = true

        -- Queue auto execute dulu sebelum teleport kalau fitur aktif
        if AR.AutoExecEnabled then
            setupAutoExecuteQueue()
        end

        task.spawn(function()
            while true do
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
                task.wait(3) -- Loop terus misal teleport gagal
            end
        end)
    end

    local function setupDetection()
        if disconnectSetup then return end
        disconnectSetup = true

        -- Method 1: GuiService ErrorMessageChanged
        pcall(function()
            game:GetService("GuiService").ErrorMessageChanged:Connect(function(message)
                if message and message ~= "" and AR.Enabled then
                    task.wait(1)
                    doRejoin()
                end
            end)
        end)

        -- Method 2: CoreGui RobloxPromptGui Ã¢â‚¬â€ popup "You were kicked" / error
        pcall(function()
            local CoreGui = game:GetService("CoreGui")
            local RobloxPromptGui = CoreGui:WaitForChild("RobloxPromptGui", 5)
            if RobloxPromptGui then
                local promptOverlay = RobloxPromptGui:WaitForChild("promptOverlay", 5)
                if promptOverlay then
                    promptOverlay.ChildAdded:Connect(function(child)
                        if child.Name == "ErrorPrompt" and AR.Enabled then
                            task.wait(0.5)
                            doRejoin()
                        end
                    end)
                end
            end
        end)

        -- Method 3: LocalPlayer.Idled Ã¢â‚¬â€ kicked karena idle terlalu lama
        pcall(function()
            LocalPlayer.Idled:Connect(function(t)
                if t > 1150 and AR.Enabled then -- 1150 detik biar gakeduluan Roblox
                    doRejoin()
                end
            end)
        end)

        -- Method 4: OnTeleport Ã¢â‚¬â€ fallback
        pcall(function()
            LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.RequestedFromServer and AR.Enabled then
                    task.wait(1)
                    doRejoin()
                end
            end)
        end)
    end

    function AR.Start()
        if AR.Enabled then return end
        AR.Enabled = true
        hasTriggered = false
        setupDetection()
        
        if AR.AutoExecEnabled then
            setupAutoExecuteQueue()
        end
    end

    function AR.Stop()
        AR.Enabled = false
        hasTriggered = false
    end

    function AR.EnableAutoExec()
        AR.AutoExecEnabled = true
        if AR.Enabled then
            setupAutoExecuteQueue()
        end
    end

    function AR.DisableAutoExec()
        AR.AutoExecEnabled = false
    end

    function AR.SetScriptURL(url)
        if type(url) == "string" and url ~= "" then
            SCRIPT_URL = url
        end
    end

    function AR.IsQueueSupported()
        return getQueueOnTeleport() ~= nil
    end

    return AR
end)()

-- =============================================
-- POTATO MODE MODULE
-- =============================================

local PotatoMode = (function()
    local PM = {}
    PM.Enabled = false

    local Lighting = game:GetService("Lighting")
    local StarterGui = game:GetService("StarterGui")
    local Terrain = Workspace:FindFirstChildOfClass("Terrain")

    local originalStates = { lighting = {}, waterProperties = {}, camera = {} }
    local pmConnections = {}
    local processedObjects = setmetatable({}, {__mode = "k"})

    local DESTROY_CLASSES = {
        BloomEffect=true, BlurEffect=true, ColorCorrectionEffect=true,
        SunRaysEffect=true, DepthOfFieldEffect=true, Atmosphere=true,
    }

    local function shouldDestroy(obj) return DESTROY_CLASSES[obj.ClassName] end

    local function isInVehicle(obj)
        local parent = obj.Parent
        while parent and parent ~= Workspace do
            if parent.Name:find("Montors") or parent.Name:find("Vehicle") or parent.Name:find("Car") then
                return true
            end
            parent = parent.Parent
        end
        return false
    end

    local function safeDestroy(obj)
        local ok, locked = pcall(function() return obj.Locked end)
        if ok and locked then return end
        if isInVehicle(obj) then return end
        pcall(function() obj:Destroy() end)
    end

    local function optimizeObject(obj)
        if not PM.Enabled or processedObjects[obj] then return end
        processedObjects[obj] = true
        if shouldDestroy(obj) then safeDestroy(obj) return end
        pcall(function()
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.CastShadow = false
                obj.Reflectance = 0
                obj.TopSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.RightSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.BackSurface = Enum.SurfaceType.SmoothNoOutlines
            elseif obj:IsA("Sound") then
                obj.Volume = 0
            end
        end)
    end

    local function optimizeCharacter(character)
        if not character or processedObjects[character] then return end
        processedObjects[character] = true
        pcall(function()
            for _, obj in ipairs(character:GetDescendants()) do
                if shouldDestroy(obj) then
                    local okL, isLocked = pcall(function() return obj.Locked end)
                    if not (okL and isLocked) then
                        pcall(function() obj:Destroy() end)
                    end
                elseif obj:IsA("BasePart") then
                    if obj.Name == "Head" then obj.Transparency = 1 end
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.CastShadow = false
                    obj.CanCollide = obj.Name == "HumanoidRootPart" or obj.Name == "Head"
                    obj.Reflectance = 0
                    obj.TopSurface = Enum.SurfaceType.SmoothNoOutlines
                    obj.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
                    obj.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
                    obj.RightSurface = Enum.SurfaceType.SmoothNoOutlines
                    obj.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
                    obj.BackSurface = Enum.SurfaceType.SmoothNoOutlines
                elseif obj:IsA("Humanoid") then
                    for _, t in ipairs(obj:GetPlayingAnimationTracks()) do t:Stop() end
                    obj.HealthDisplayDistance = 0
                    obj.NameDisplayDistance = 0
                elseif obj:IsA("Sound") then
                    obj.Volume = 0
                end
            end
        end)
    end

    function PM.Enable()
        if PM.Enabled then return end
        PM.Enabled = true

        task.spawn(function()
            local all = Workspace:GetDescendants()
            for i = 1, #all, 200 do
                if not PM.Enabled then break end
                for j = i, math.min(i+199, #all) do optimizeObject(all[j]) end
                task.wait()
            end
        end)

        if LocalPlayer.Character then optimizeCharacter(LocalPlayer.Character) end

        table.insert(pmConnections, LocalPlayer.CharacterAdded:Connect(function(char)
            if PM.Enabled then task.wait(0.2) optimizeCharacter(char) end
        end))

        if Terrain then
            pcall(function()
                originalStates.waterProperties = {
                    WaterReflectance = Terrain.WaterReflectance,
                    WaterWaveSize = Terrain.WaterWaveSize,
                    WaterWaveSpeed = Terrain.WaterWaveSpeed,
                    WaterTransparency = Terrain.WaterTransparency
                }
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1
                Terrain.Decoration = false
            end)
            local clouds = Terrain:FindFirstChildOfClass("Clouds")
            if clouds then clouds:Destroy() end
        end

        for _, sky in ipairs(Lighting:GetChildren()) do
            if sky:IsA("Sky") then
                sky.SkyboxBk="" sky.SkyboxDn="" sky.SkyboxFt=""
                sky.SkyboxLf="" sky.SkyboxRt="" sky.SkyboxUp=""
                sky.StarCount=0 sky.SunAngularSize=0 sky.MoonAngularSize=0
                sky.CelestialBodiesShown=false
            end
        end

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then atmosphere:Destroy() end

        originalStates.lighting = {
            GlobalShadows = Lighting.GlobalShadows,
            Brightness = Lighting.Brightness,
            Technology = Lighting.Technology
        }
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 0
        Lighting.Brightness = 0
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.Technology = Enum.Technology.Legacy
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ShadowSoftness = 0

        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then effect.Enabled = false end
        end

        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function()
            local cam = Workspace.CurrentCamera
            originalStates.camera = { FieldOfView = cam.FieldOfView }
            cam.FieldOfView = 70
        end)

        table.insert(pmConnections, Workspace.DescendantAdded:Connect(function(obj)
            if PM.Enabled then
                if shouldDestroy(obj) then safeDestroy(obj)
                else task.defer(optimizeObject, obj) end
            end
        end))

        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
        end)
    end

    function PM.Disable()
        if not PM.Enabled then return end
        PM.Enabled = false

        if Terrain and originalStates.waterProperties then
            pcall(function()
                Terrain.WaterReflectance = originalStates.waterProperties.WaterReflectance or 0
                Terrain.WaterWaveSize = originalStates.waterProperties.WaterWaveSize or 0
                Terrain.WaterWaveSpeed = originalStates.waterProperties.WaterWaveSpeed or 0
                Terrain.WaterTransparency = originalStates.waterProperties.WaterTransparency or 0
                Terrain.Decoration = true
            end)
        end

        if originalStates.lighting.GlobalShadows ~= nil then
            Lighting.GlobalShadows = originalStates.lighting.GlobalShadows
            Lighting.Brightness = originalStates.lighting.Brightness
            Lighting.Technology = originalStates.lighting.Technology
        end

        if originalStates.camera.FieldOfView then
            pcall(function() Workspace.CurrentCamera.FieldOfView = originalStates.camera.FieldOfView end)
        end

        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
        end)

        for _, conn in ipairs(pmConnections) do conn:Disconnect() end
        pmConnections = {}
        processedObjects = setmetatable({}, {__mode = "k"})
        originalStates = { lighting = {}, waterProperties = {}, camera = {} }
        pcall(function() collectgarbage("collect") end)
    end

    return PM
end)()

-- =============================================
-- DISABLE RENDERING MODULE
-- =============================================

local DisableRendering = (function()
    local DR = {}
    DR.Enabled = false
    local renderConn = nil

    function DR.Start()
        if DR.Enabled then return end
        DR.Enabled = true
        renderConn = RunService.RenderStepped:Connect(function()
            pcall(function() RunService:Set3dRenderingEnabled(false) end)
        end)
    end

    function DR.Stop()
        if not DR.Enabled then return end
        DR.Enabled = false
        if renderConn then renderConn:Disconnect() renderConn = nil end
        pcall(function() RunService:Set3dRenderingEnabled(true) end)
    end

    return DR
end)()

-- =============================================
-- UNLOCK FPS MODULE
-- =============================================

local UnlockFPS = (function()
    local UF = {}
    UF.Enabled = false
    UF.CurrentCap = 60

    function UF.SetCap(fps)
        UF.CurrentCap = fps
        if UF.Enabled and setfpscap then setfpscap(fps) end
    end

    function UF.Start()
        if UF.Enabled then return end
        UF.Enabled = true
        if setfpscap then setfpscap(UF.CurrentCap) end
    end

    function UF.Stop()
        if not UF.Enabled then return end
        UF.Enabled = false
        if setfpscap then setfpscap(60) end
    end

    return UF
end)()

-- =============================================
-- GUI - TAB SETTINGS
-- =============================================

local FreecamTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
	IconColor = Mains,
	IconShape = "Square",
	Border = true,
})

local HideStatsSection = FreecamTab:Section({ Title = "Hide Stats", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = false })

local hideStatsToggle = HideStatsSection:Toggle({
    Title = "Enable Hide Stats",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.HideStats = on
            saveUIConfig(uiConfig)
        end
        if on then HideStats.Enable() else HideStats.Disable() end
    end
})

local fakeNameInput = HideStatsSection:Input({
    Type = "Input", 
    Title = "Fake Name",
    Value = uiConfig.FakeName or "King Vypers",
    Placeholder = "Nama palsu",
    Callback = function(value)
        HideStats.SetFakeName(value)
        if not isUILoading then
            uiConfig.FakeName = value
            saveUIConfig(uiConfig)
        end
    end
})
HideStats.SetFakeName(uiConfig.FakeName or "King Vypers")

local fakeRankInput = HideStatsSection:Input({
    Type = "Input", 
    Title = "Fake Rank",
    Value = uiConfig.FakeRank or "King Vypers 👑",
    Placeholder = "Rank palsu",
    Callback = function(value)
        HideStats.SetFakeRank(value)
        if not isUILoading then
            uiConfig.FakeRank = value
            saveUIConfig(uiConfig)
        end
    end
})
HideStats.SetFakeRank(uiConfig.FakeRank or "King Vypers 👑")

-- =============================================
-- GUI - PERFORMANCE SECTION (di Settings tab)
-- =============================================

local PerformanceSection = FreecamTab:Section({ Title = "Performance", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = false })

local potatoToggle = PerformanceSection:Toggle({
    Title = "FPS Booster (Potato Mode)",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.PotatoMode = on
            saveUIConfig(uiConfig)
        end
        if on then PotatoMode.Enable() else PotatoMode.Disable() end
    end
})

local disableRenderToggle = PerformanceSection:Toggle({
    Title = "Disable 3D Rendering",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.DisableRendering = on
            saveUIConfig(uiConfig)
        end
        if on then DisableRendering.Start() else DisableRendering.Stop() end
    end
})

local selectedFpsCap = 60

local fpscapDropdown = PerformanceSection:Dropdown({
    Title = "FPS Cap",
    Options = {"60", "90", "120", "240"},
    Value = uiConfig.FpsCap or "60",
    Callback = function(value)
        selectedFpsCap = tonumber(value) or 60
        UnlockFPS.SetCap(selectedFpsCap)
        if not isUILoading then
            uiConfig.FpsCap = value
            saveUIConfig(uiConfig)
        end
    end
})
selectedFpsCap = tonumber(uiConfig.FpsCap) or 60

local fpsUnlockToggle = PerformanceSection:Toggle({
    Title = "Enable FPS Unlock",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.FpsUnlock = on
            saveUIConfig(uiConfig)
        end
        if on then
            UnlockFPS.CurrentCap = selectedFpsCap
            UnlockFPS.Start()
        else
            UnlockFPS.Stop()
        end
    end
})

-- =============================================
-- GUI - PROTECTION SECTION (di Settings tab)
-- =============================================

local ProtectionSection = FreecamTab:Section({ Title = "Protection", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = false })

local antiAfkToggle = ProtectionSection:Toggle({
    Title = "Anti-AFK",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.AntiAFK = on
            saveUIConfig(uiConfig)
        end
        if on then AntiAFK.Start() else AntiAFK.Stop() end
    end
})

local antiStaffToggle = ProtectionSection:Toggle({
    Title = "Anti Staff (Auto Kick)",
    Value = false,
    Callback = function(on)
        if not isUILoading then
            uiConfig.AntiStaff = on
            saveUIConfig(uiConfig)
        end
        if on then AntiStaff.Start() else AntiStaff.Stop() end
    end
})

-- =============================================
-- GUI - AUTO RECONNECT + AUTO EXECUTE SECTION
-- =============================================

local settingsConfigPath = "DDS_SettingsConfig.json"

local function loadSettingsConfig()
    local ok, data = pcall(readfile, settingsConfigPath)
    if ok and data then
        local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok2 then return decoded end
    end
    return {}
end

local function saveSettingsConfig(data)
    pcall(writefile, settingsConfigPath, HttpService:JSONEncode(data))
end

local settingsConfig = loadSettingsConfig()
local isSettingsLoading = true

local ReconnectSection = FreecamTab:Section({ Title = "Auto Reconnect & Execute", Box = true, TextXAlignment = "Center", TextSize = 15, Opened = false })

-- Toggle combined: Auto Reconnect
local reconnectToggle = ReconnectSection:Toggle({
    Title = "Enable Auto Reconnect",
    Value = false,
    Callback = function(on)
        if not isSettingsLoading then
            settingsConfig.AutoReconnect = on
            saveSettingsConfig(settingsConfig)
        end
        if on then
            AutoRejoin.Start()
        else
            AutoRejoin.Stop()
        end
    end
})

-- Toggle: Auto Execute setelah rejoin
-- Kalau ON, script King Vypers akan otomatis ke-load lagi setelah rejoin
local autoExecToggle = ReconnectSection:Toggle({
    Title = "Auto Execute Setelah Rejoin",
    Value = false,
    Callback = function(on)
        if not isSettingsLoading then
            settingsConfig.AutoExecute = on
            saveSettingsConfig(settingsConfig)
        end
        if on then
            if AutoRejoin.IsQueueSupported() then
                AutoRejoin.EnableAutoExec()
            else
                -- Executor tidak support queue_on_teleport, fitur tidak akan jalan
                -- Toggle tetap bisa di-ON tapi tidak akan ada efek
                AutoRejoin.EnableAutoExec()
            end
        else
            AutoRejoin.DisableAutoExec()
        end
    end
})

task.spawn(function()
    task.wait(0.5)

    if bCfg.TimeoutEnabled   then restartToggle:Set(true)  end
    if bCfg.KickLimitEnabled then kickToggle:Set(true)     end
    if bCfg.AutoBarista      then baristaToggle:Set(true)  end
    isBLoading = false

    -- Restore Auto Reconnect & Execute (config lama)
    if settingsConfig.AutoReconnect then reconnectToggle:Set(true) end
    if settingsConfig.AutoExecute then autoExecToggle:Set(true) end
    isSettingsLoading = false

    -- Restore semua UI config
    if uiConfig.SpeedHack then speedHackToggle:Set(true) end
    if uiConfig.SlowRace then slowRaceToggle:Set(true) end
    if uiConfig.UltraGrafik then ultraGrafikToggle:Set(true) end
    if uiConfig.AutoRide then autoRideToggle:Set(true) end
    if uiConfig.AutoRideAlways then autoRideAlwaysToggle:Set(true) end
    if uiConfig.HideStats then hideStatsToggle:Set(true) end
    if uiConfig.PotatoMode then potatoToggle:Set(true) end
    if uiConfig.DisableRendering then disableRenderToggle:Set(true) end
    if uiConfig.FpsUnlock then fpsUnlockToggle:Set(true) end
    if uiConfig.AntiAFK then antiAfkToggle:Set(true) end
    if uiConfig.AntiStaff then antiStaffToggle:Set(true) end

    isUILoading = false
end)
