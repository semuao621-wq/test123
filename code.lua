
local Vyper = loadstring(game:HttpGet("https://raw.githubusercontent.com/semuao621-wq/test123/refs/heads/main/ui.lua"))()


-- EventResolver v7 (hash-safe, scan langsung dari net:GetChildren())
local EmbeddedEventResolver = (function()
    local RS = game:GetService("ReplicatedStorage")

    local self = {
        _initialized = false,
        _re = {},
        _rf = {},
        _netFolder = nil,
    }

    local function isHash(name)
        -- Hash = hex string panjang >= 32 char, hanya hex
        return #name >= 32 and name:match("^[0-9a-f]+$") ~= nil
    end

    local function stripPrefix(name)
        -- "RF/ChargeFishingRod" -> "ChargeFishingRod"
        -- "RE/FishCaught"       -> "FishCaught"
        -- "URE/TakeMeasurement" -> "TakeMeasurement"
        return name:match("^[A-Z]+/(.+)$") or name
    end

    local function findNetFolder()
        if self._netFolder and self._netFolder.Parent then
            return self._netFolder
        end

        local ok, net = pcall(function()
            return RS.Packages._Index["sleitnick_net@0.2.0"].net
        end)
        if ok and net then
            self._netFolder = net
            return net
        end

        -- Fallback: scan _Index cari folder yang ada child "net"/"Net"
        local idx = RS:FindFirstChild("Packages")
        idx = idx and idx:FindFirstChild("_Index")
        if not idx then return nil end

        for _, child in ipairs(idx:GetChildren()) do
            if child.Name:lower():find("net") then
                local n = child:FindFirstChild("net") or child:FindFirstChild("Net")
                if n then
                    self._netFolder = n
                    return n
                end
            end
        end

        return nil
    end

    local function clearCaches()
        self._re = {}
        self._rf = {}
    end

    local function scanPairs(netFolder)
        local children = netFolder:GetChildren()
        local i = 1

        while i <= #children do
            local curr = children[i]
            local nextChild = children[i + 1]

            local skip = false
            if nextChild then
                local currName = stripPrefix(curr.Name)
                local nextName = stripPrefix(nextChild.Name)
                local currClass = curr.ClassName
                local nextClass = nextChild.ClassName

                -- Pair valid: sama class, curr = nama asli, next = hash
                if currClass == nextClass
                    and not isHash(currName)
                    and isHash(nextName) then

                    if curr:IsA("RemoteFunction") then
                        self._rf[currName] = nextChild
                    elseif curr:IsA("RemoteEvent") or curr:IsA("UnreliableRemoteEvent") then
                        self._re[currName] = nextChild
                    end

                    i = i + 2
                    skip = true
                end
            end

            if not skip then
                -- Bukan pair: simpan apa adanya jika nama asli (tidak hash)
                local name = stripPrefix(curr.Name)
                if not isHash(name) then
                    if curr:IsA("RemoteFunction") and not self._rf[name] then
                        self._rf[name] = curr
                    elseif (curr:IsA("RemoteEvent") or curr:IsA("UnreliableRemoteEvent"))
                        and not self._re[name] then
                        self._re[name] = curr
                    end
                end

                i = i + 1
            end
        end
    end

    function self:Init()
        if self._initialized then return true end

        local net = findNetFolder()
        if not net then
            warn("[EmbeddedEventResolver] net folder tidak ditemukan!")
            return false
        end

        clearCaches()
        scanPairs(net)

        self._initialized = true
        _G.EventResolver = self
        _G.ResolvedNetEvents = { RE = self._re, RF = self._rf }

        return true
    end

    function self:GetRF(name)
        if not self._initialized then self:Init() end
        if self._rf[name] then return self._rf[name] end

        local net = findNetFolder()
        if net then
            scanPairs(net)
        end

        return self._rf[name]
    end

    function self:GetRE(name)
        if not self._initialized then self:Init() end
        if self._re[name] then return self._re[name] end

        local net = findNetFolder()
        if net then
            scanPairs(net)
        end

        return self._re[name]
    end

    function self:GetNetFolder()
        return findNetFolder()
    end

    function self:IsInitialized()
        return self._initialized
    end

    function self:Reset()
        self._initialized = false
        self._netFolder = nil
        clearCaches()
    end

    function self:Debug()
        local rfCount, reCount = 0, 0
        print("[EmbeddedEventResolver] === RemoteFunctions ===")
        for k, v in pairs(self._rf) do
            rfCount = rfCount + 1
            print(string.format("  %-40s -> %s", k, v.Name))
        end
        print("[EmbeddedEventResolver] === RemoteEvents ===")
        for k, v in pairs(self._re) do
            reCount = reCount + 1
            print(string.format("  %-40s -> %s", k, v.Name))
        end
        print(string.format("[EmbeddedEventResolver] Total: %d RF, %d RE", rfCount, reCount))
    end

    self:Init()
    return self
end)()

task.spawn(function() EmbeddedEventResolver:Init() end)

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace") or workspace
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = localPlayer
local player = localPlayer

localPlayer.CharacterAdded:Connect(function()
    task.wait(3)
    EmbeddedEventResolver:Reset()
    task.spawn(function() EmbeddedEventResolver:Init() end)
end)

local function safeFire(fn) pcall(fn) end

local NetEvents = {}
setmetatable(NetEvents, {
    __index = function(t, k)
        if k == "RF_ChargeFishingRod" then return EmbeddedEventResolver:GetRF("ChargeFishingRod")
        elseif k == "RF_RequestMinigame" then return EmbeddedEventResolver:GetRF("RequestFishingMinigameStarted")
        elseif k == "RF_CancelFishingInputs" then return EmbeddedEventResolver:GetRF("CancelFishingInputs")
        elseif k == "RF_UpdateAutoFishingState" then return EmbeddedEventResolver:GetRF("UpdateAutoFishingState")
        elseif k == "RE_FishingCompleted" then return EmbeddedEventResolver:GetRF("CatchFishCompleted")
        elseif k == "RE_UpdateChargeState" then return EmbeddedEventResolver:GetRE("UpdateChargeState")
        elseif k == "RE_MinigameChanged" or k == "RF_MinigameChange" then return EmbeddedEventResolver:GetRE("FishingMinigameChanged")
        elseif k == "RE_FishCaught" then return EmbeddedEventResolver:GetRE("FishCaught")
        elseif k == "RE_FishingStopped" then return EmbeddedEventResolver:GetRE("FishingStopped")
        elseif k == "netFolder" then return EmbeddedEventResolver:GetNetFolder()
        elseif k == "IsInitialized" then return EmbeddedEventResolver:IsInitialized()
        end
        return rawget(t, k)
    end,
    __newindex = function(t, k, v)
        if k == "IsInitialized" then return end
        rawset(t, k, v)
    end
})

-- Instant Fish module
local InstantV1 = (function()
    local Instant = {}
    Instant.Active = false
    Instant.Settings = { CompleteDelay = 0.04 }
    local spamThread = nil

    local function loop()
        while Instant.Active do
            if not EmbeddedEventResolver:IsInitialized() then
                task.wait(1)
            else
                local t = Workspace:GetServerTimeNow()
                safeFire(function() NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, t, nil) end)
                task.wait(0.3)
                safeFire(function() NetEvents.RF_RequestMinigame:InvokeServer(-1.2, 0.95, t) end)
                task.wait(Instant.Settings.CompleteDelay)
                safeFire(function()
                    local rf = NetEvents.RE_FishingCompleted
                    if rf then rf:InvokeServer() end
                end)
                task.wait(0.04)
            end
        end
    end

    function Instant.Start()
        if Instant.Active then return end
        if not EmbeddedEventResolver:IsInitialized() then return end
        Instant.Active = true
        spamThread = task.spawn(loop)
    end

    function Instant.Stop()
        if not Instant.Active then return end
        Instant.Active = false
        if spamThread then task.cancel(spamThread) spamThread = nil end
        safeFire(function()
            if NetEvents.RF_CancelFishingInputs then NetEvents.RF_CancelFishingInputs:InvokeServer() end
        end)
    end

    return Instant
end)()

-- Blatant V1 module
local BlatantV1 = (function()
    local Blatant = {}
    Blatant.Active = false
    Blatant.Settings = { SpamCastDelay = 0.05, CompleteDelay = 0.01, InstantComplete = true, ChargeSpam = 3 }
    local spamThread = nil

    local function loop()
        while Blatant.Active do
            if EmbeddedEventResolver:IsInitialized() then
                local t = Workspace:GetServerTimeNow()
                for i = 1, Blatant.Settings.ChargeSpam do
                    safeFire(function() NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, t, nil) end)
                    safeFire(function() NetEvents.RF_RequestMinigame:InvokeServer(-1.2331848144531, 0.89899236174132, t) end)
                    if i < Blatant.Settings.ChargeSpam then task.wait(0.05) end
                end
                if Blatant.Settings.InstantComplete then
                    task.wait(Blatant.Settings.CompleteDelay)
                    safeFire(function()
                        local rf = NetEvents.RE_FishingCompleted
                        if rf then rf:InvokeServer() end
                    end)
                    if NetEvents.RE_UpdateChargeState then safeFire(function() NetEvents.RE_UpdateChargeState:FireServer(true) end) end
                    if NetEvents.RF_MinigameChange then safeFire(function() NetEvents.RF_MinigameChange:FireServer(true) end) end
                    task.wait(0.01)
                end
                task.wait(Blatant.Settings.SpamCastDelay)
            else
                task.wait(1)
            end
        end
    end

    function Blatant.Start()
        if Blatant.Active then return end
        if not EmbeddedEventResolver:IsInitialized() then return end
        Blatant.Active = true
        spamThread = task.spawn(loop)
    end

    function Blatant.Stop()
        if not Blatant.Active then return end
        Blatant.Active = false
        if spamThread then task.cancel(spamThread) spamThread = nil end
    end

    return Blatant
end)()

-- Shared module container (for cross-feature modules)
local CombinedModules = rawget(getgenv(), "CombinedModules")
if type(CombinedModules) ~= "table" then
    CombinedModules = {}
    getgenv().CombinedModules = CombinedModules
end

-- Window + Fish tab (Instant Fish + Blatant only)
local Window = Vyper:Window({
    Title = "Bujang",
    Footer = "|Fish It",
    Color = Color3.fromRGB(100, 200, 255),
    ["Tab Width"] = 130,
    Version = 1,
    Image = "107726435417936"
})

local FishTab = Window:AddTab({ Name = "Fish", Icon = "fish" })

local AutoFishingSection = FishTab:AddSection("Instant Fishing")
AutoFishingSection:AddInput({
    Title = "Instant Delay",
    Default = "0.04",
    Callback = function(value)
        local v = tonumber(value)
        if v and InstantV1 then InstantV1.Settings.CompleteDelay = v end
    end
})
AutoFishingSection:AddToggle({
    Title = "Enable Instant",
    Default = false,
    Callback = function(on)
        if on then InstantV1.Start() else InstantV1.Stop() end
    end
})

local BlatantV1Section = FishTab:AddSection("Blatant V1 [BETA]")
BlatantV1Section:AddToggle({
    Title = "Enable Blatant V1",
    Default = false,
    Callback = function(on)
        if on then BlatantV1.Start() else BlatantV1.Stop() end
    end
})
BlatantV1Section:AddInput({
    Title = "Talon Delay V1",
    Default = "0.05",
    Callback = function(value)
        local v = tonumber(value)
        if v and BlatantV1 then BlatantV1.Settings.SpamCastDelay = v end
    end
})
BlatantV1Section:AddInput({
    Title = "Wildes Delay V1",
    Default = "0.01",
    Callback = function(value)
        local v = tonumber(value)
        if v and BlatantV1 then BlatantV1.Settings.CompleteDelay = v end
    end
})

-- ========== TELEPORT MODULE + TAB ==========
local TeleportModule = (function()
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer

    local M = {}

    M.Locations = {
        ["Ancient Jungle"]       = Vector3.new(1467.8480224609375, 7.447117328643799, -327.5971984863281),
        ["Ancient Ruin"]         = Vector3.new(6045.40234375, -588.600830078125, 4608.9375),
        ["Coral Reefs"]          = Vector3.new(-2921.858154296875, 3.249999761581421, 2083.2978515625),
        ["Crater Island"]        = Vector3.new(1078.454345703125, 5.0720038414001465, 5099.396484375),
        ["Esoteric Depths"]      = Vector3.new(3224.075927734375, -1302.85498046875, 1404.9346923828125),
        ["Fisherman Island"]     = Vector3.new(92.80695343017578, 9.531265258789062, 2762.082275390625),
        ["Kohana"]               = Vector3.new(-643.3051147460938, 16.03544807434082, 622.3605346679688),
        ["Kohana Volcano"]       = Vector3.new(-572.0244750976562, 39.4923210144043, 112.49259185791016),
        ["Lost Isle"]            = Vector3.new(-3701.1513671875, 5.425841808319092, -1058.9107666015625),
        ["Sysiphus Statue"]      = Vector3.new(-3656.56201171875, -134.5314178466797, -964.3167724609375),
        ["Sacred Temple"]        = Vector3.new(1476.30810546875, -21.8499755859375, -630.8220825195312),
        ["Treasure Room"]        = Vector3.new(-3601.568359375, -266.57373046875, -1578.998779296875),
        ["Tropical Grove"]       = Vector3.new(-2104.467041015625, 6.268016815185547, 3718.2548828125),
        ["Underground Cellar"]   = Vector3.new(2162.577392578125, -91.1981430053711, -725.591552734375),
        ["Pirate Cove"]          = Vector3.new(3334.47, 10.2, 3502.92),
        ["Leviathan Den"]        = Vector3.new(3471.41, -287.84, 3468.87),
        ["Pirate Treasure Room"] = Vector3.new(3337.64, -302.75, 3089.56),
        ["Crystal Depths"]       = Vector3.new(5729.04, -904.82, 15407.97),
        ["Vulcanic Cavern"]      = Vector3.new(1118.1817626953125, 85.990936279296875, -10250.158203125),
        ["Lava Basin"]           = Vector3.new(871.7166137695312, 96.93890380859375, -10176.6259765625),
        ["Heartfelt Island"]     = Vector3.new(1114.147705078125, 4.845647811889648, 2715.550048828125),
        ["Weather Machine"]      = Vector3.new(-1513.9249267578125, 6.499999523162842, 1892.10693359375),
    }

    function M.TeleportTo(name)
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")

        local target = M.Locations[name]
        if not target then
            return false
        end

        root.CFrame = CFrame.new(target)
        return true
    end

    return M
end)()

local TeleportTab = Window:AddTab({ Name = "Teleport", Icon = "teleport" })

local IslandSection = TeleportTab:AddSection("Teleport to Island")

local islandNames = {}
for name, _ in pairs(TeleportModule.Locations) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

local selectedIsland = nil

IslandSection:AddDropdown({
    Title = "Select Island",
    Content = "Choose destination island",
    Multi = false,
    Options = islandNames,
    Default = nil,
    Callback = function(selected)
        selectedIsland = selected
    end
})

IslandSection:AddButton({
    Title = "Teleport",
    Callback = function()
        if not selectedIsland or selectedIsland == "" then
            Vyper:MakeNotify({
                Title = "Teleport",
                Description = "No island selected",
                Content = "",
                Color = Color3.fromRGB(255, 179, 71),
                Delay = 2,
            })
            return
        end

        local ok = TeleportModule.TeleportTo(selectedIsland)
        if not ok then
            Vyper:MakeNotify({
                Title = "Teleport",
                Description = "Failed to teleport to " .. tostring(selectedIsland),
                Content = "",
                Color = Color3.fromRGB(255, 85, 127),
                Delay = 3,
            })
        else
            Vyper:MakeNotify({
                Title = "Teleport",
                Description = "Teleported to " .. tostring(selectedIsland),
                Content = "",
                Color = Color3.fromRGB(123, 239, 178),
                Delay = 2,
            })
        end
    end
})

-- Section: Teleport to Player
local PlayerTPSection = TeleportTab:AddSection("Teleport to Player", false)

local playerItems = {}
local selectedPlayer = nil
local playerDropdown = nil

local function updatePlayerList()
    table.clear(playerItems)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            table.insert(playerItems, plr.Name)
        end
    end
    table.sort(playerItems)
end
updatePlayerList()

playerDropdown = PlayerTPSection:AddDropdown({
    Title = "Select Player",
    Content = "Choose player to teleport to",
    Multi = false,
    Options = playerItems,
    Default = nil,
    Callback = function(selected)
        selectedPlayer = selected
    end
})

PlayerTPSection:AddButton({
    Title = "Teleport Now",
    Callback = function()
        if selectedPlayer and selectedPlayer ~= "" then
            if CombinedModules and CombinedModules.TeleportToPlayer and CombinedModules.TeleportToPlayer.TeleportTo then
                CombinedModules.TeleportToPlayer.TeleportTo(selectedPlayer)
            else
                Vyper:MakeNotify({
                    Title = "Teleport",
                    Description = "TeleportToPlayer module not available",
                    Content = "",
                    Color = Color3.fromRGB(255, 85, 127),
                    Delay = 3,
                })
            end
        else
            Vyper:MakeNotify({
                Title = "Teleport",
                Description = "Please select a player first!",
                Content = "",
                Color = Color3.fromRGB(255, 179, 71),
                Delay = 2,
            })
        end
    end
})

PlayerTPSection:AddButton({
    Title = "Refresh Player List",
    Callback = function()
        updatePlayerList()
        if playerDropdown and playerDropdown.SetValues then
            playerDropdown:SetValues(playerItems, nil)
        end
    end
})

-- ========== SUPPORT FISHING MODULES ==========
local NoFishingAnimation = (function()
    local M = {}
    M.Enabled = false
    M.Connection = nil
    function M.StartWithDelay()
        task.wait(0.5)
        M.Start()
    end
    function M.Start()
        if M.Enabled then return end
        M.Enabled = true
        local function blockAnimations()
            local char = LocalPlayer.Character
            if not char then return end
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if not animator then return end
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                if track.Name:find("Reel") or track.Name:find("Fish") then track:Stop() end
            end
        end
        M.Connection = RunService.Heartbeat:Connect(function()
            if M.Enabled then blockAnimations() end
        end)
    end
    function M.Stop()
        if not M.Enabled then return end
        M.Enabled = false
        if M.Connection then M.Connection:Disconnect() M.Connection = nil end
    end
    return M
end)()

local AutoEquipRod = (function()
    local M = {}
    local v0 = { Players = Players, RS = ReplicatedStorage }
    local v5Success, v5 = pcall(function()
        return {
            PlayerStatsUtility = require(v0.RS.Shared.PlayerStatsUtility),
            ItemUtility = require(v0.RS.Shared.ItemUtility)
        }
    end)
    if not v5Success then
        M.isSupported = false
        M.Start = function() end
        M.Stop = function() end
        return M
    end
    local function getREEquip() return EmbeddedEventResolver:GetRE("EquipToolFromHotbar") end
    local v7Success, v7 = pcall(function()
        return { Data = require(v0.RS.Packages.Replion).Client:WaitReplion("Data") }
    end)
    if not v7Success then
        M.isSupported = false
        M.Start = function() end
        M.Stop = function() end
        return M
    end
    M.isSupported = true
    local v8 = { autoEquipRod = false, loopConnection = nil }
    local function isRodEquipped()
        local success, result = pcall(function()
            local v217 = v7.Data:Get("EquippedId")
            if not v217 then return false end
            local equippedItem = v5.PlayerStatsUtility:GetItemFromInventory(v7.Data, function(v218) return v218.UUID == v217 end)
            if not equippedItem then return false end
            local itemData = v5.ItemUtility:GetItemData(equippedItem.Id)
            return itemData and itemData.Data.Type == "Fishing Rods"
        end)
        return success and result or false
    end
    local function equipRod()
        pcall(function()
            if not isRodEquipped() then
                local reEquip = getREEquip()
                if reEquip then reEquip:FireServer(1) end
            end
        end)
    end
    function M.Start()
        v8.autoEquipRod = true
        if v8.loopConnection then v8.loopConnection:Disconnect() end
        v8.loopConnection = task.spawn(function()
            while v8.autoEquipRod do equipRod() task.wait(1) end
        end)
    end
    function M.Stop()
        v8.autoEquipRod = false
        if v8.loopConnection then task.cancel(v8.loopConnection) v8.loopConnection = nil end
    end
    return M
end)()

local LockPosition = (function()
    local M = {}
    M.Enabled = false
    M.LockedPos = nil
    M.Connection = nil
    function M.Start()
        if M.Enabled then return end
        M.Enabled = true
        local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        M.LockedPos = hrp.CFrame
        M.Connection = RunService.Heartbeat:Connect(function()
            if not M.Enabled then return end
            local c = player.Character
            if not c then return end
            local hrp2 = c:FindFirstChild("HumanoidRootPart")
            if not hrp2 then return end
            hrp2.CFrame = M.LockedPos
        end)
    end
    function M.Stop()
        M.Enabled = false
        if M.Connection then M.Connection:Disconnect() M.Connection = nil end
    end
    return M
end)()

local DisableCutscenes = (function()
    local CutsceneController = nil
    local OldPlayCutscene = nil
    local isDisabled = false
    local function initializeCutsceneHook()
        pcall(function()
            CutsceneController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CutsceneController"))
            if CutsceneController and CutsceneController.Play then
                OldPlayCutscene = CutsceneController.Play
                CutsceneController.Play = function(self, ...)
                    if isDisabled then return end
                    return OldPlayCutscene(self, ...)
                end
            end
        end)
    end
    initializeCutsceneHook()
    local M = {}
    function M.Start()
        if isDisabled then return end
        isDisabled = true
        if not CutsceneController then initializeCutsceneHook() end
    end
    function M.Stop()
        if not isDisabled then return end
        isDisabled = false
    end
    return M
end)()

local DisableExtras = (function()
    local VFXFolder = ReplicatedStorage:WaitForChild("VFX")
    local DisableNotificationConnection = nil
    local isVFXDisabled = false
    local supportsModuleOverride = false
    local VFXControllerModule = nil
    local originalVFXHandle, originalRenderAtPoint, originalRenderInstance
    pcall(function()
        VFXControllerModule = require(ReplicatedStorage:WaitForChild("Controllers").VFXController)
        originalVFXHandle = VFXControllerModule.Handle
        originalRenderAtPoint = VFXControllerModule.RenderAtPoint
        originalRenderInstance = VFXControllerModule.RenderInstance
        supportsModuleOverride = true
    end)
    local M = {}
    function M.StartSmallNotification()
        if DisableNotificationConnection then return end
        local PlayerGui = Players.LocalPlayer.PlayerGui
        local SmallNotification = PlayerGui:FindFirstChild("Small Notification") or PlayerGui:WaitForChild("Small Notification", 5)
        if not SmallNotification then return end
        SmallNotification.Enabled = false
        DisableNotificationConnection = SmallNotification:GetPropertyChangedSignal("Enabled"):Connect(function()
            if SmallNotification.Enabled then SmallNotification.Enabled = false end
        end)
    end
    function M.StopSmallNotification()
        if DisableNotificationConnection then
            DisableNotificationConnection:Disconnect()
            DisableNotificationConnection = nil
        end
        local SmallNotification = Players.LocalPlayer.PlayerGui:FindFirstChild("Small Notification")
        if SmallNotification then SmallNotification.Enabled = true end
    end
    function M.StartSkinEffect()
        if isVFXDisabled then return end
        isVFXDisabled = true
        if supportsModuleOverride then
            VFXControllerModule.Handle = function() end
            VFXControllerModule.RenderAtPoint = function() end
            VFXControllerModule.RenderInstance = function() end
            local cf = workspace:FindFirstChild("CosmeticFolder")
            if cf then pcall(function() cf:ClearAllChildren() end) end
        else
            for _, child in pairs(VFXFolder:GetChildren()) do
                if child.Name:match("Dive$") then child:Destroy() end
            end
            local cf = workspace:FindFirstChild("CosmeticFolder")
            if cf then pcall(function() cf:ClearAllChildren() end) end
            VFXFolder.ChildAdded:Connect(function(child)
                if isVFXDisabled and child.Name:match("Dive$") then child:Destroy() end
            end)
            if cf then cf.ChildAdded:Connect(function(child) if isVFXDisabled then child:Destroy() end end) end
        end
    end
    function M.StopSkinEffect()
        if not isVFXDisabled then return end
        isVFXDisabled = false
        if supportsModuleOverride then
            VFXControllerModule.Handle = originalVFXHandle
            VFXControllerModule.RenderAtPoint = originalRenderAtPoint
            VFXControllerModule.RenderInstance = originalRenderInstance
        end
    end
    return M
end)()

local StableResult = (function()
    local M = {}
    M.Enabled = false
    local function GetAutoFishingRemote()
        return EmbeddedEventResolver:GetRF("UpdateAutoFishingState")
    end
    function M.Start()
        if M.Enabled then return false end
        if not GetAutoFishingRemote() then return false end
        M.Enabled = true
        local remote = GetAutoFishingRemote()
        local ok = pcall(function() remote:InvokeServer(true) end)
        if not ok then M.Enabled = false return false end
        pcall(function() LocalPlayer:SetAttribute("Loading", nil) end)
        return true
    end
    function M.Stop()
        if not M.Enabled then return false end
        M.Enabled = false
        local remote = GetAutoFishingRemote()
        if remote then pcall(function() remote:InvokeServer(false) end) end
        pcall(function() LocalPlayer:SetAttribute("Loading", false) end)
        return true
    end
    return M
end)()

local WalkOnWater = (function()
    local M = { Enabled = false, Platform = nil, AlignPos = nil, Connection = nil }
    local PLATFORM_SIZE = 14
    local OFFSET = 3
    local LAST_WATER_Y = nil
    local function GetCharacterReferences()
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then return end
        return char, humanoid, hrp
    end
    local function ForceSurfaceLift()
        local _, humanoid, hrp = GetCharacterReferences()
        if not humanoid or not hrp then return end
        if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then return end
        for _ = 1, 60 do
            hrp.Velocity = Vector3.new(0, 80, 0)
            task.wait(0.03)
            if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then break end
        end
        hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
    end
    local function GetWaterHeight()
        local _, _, hrp = GetCharacterReferences()
        if not hrp then return LAST_WATER_Y end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = { LocalPlayer.Character }
        params.IgnoreWater = false
        local result = Workspace:Raycast(hrp.Position + Vector3.new(0, 5, 0), Vector3.new(0, -600, 0), params)
        if result then LAST_WATER_Y = result.Position.Y return LAST_WATER_Y end
        return LAST_WATER_Y
    end
    local function CreatePlatform()
        if M.Platform then M.Platform:Destroy() end
        local p = Instance.new("Part")
        p.Size = Vector3.new(PLATFORM_SIZE, 1, PLATFORM_SIZE)
        p.Anchored = true
        p.CanCollide = true
        p.Transparency = 1
        p.CanQuery = false
        p.CanTouch = false
        p.Name = "WaterLockPlatform"
        p.Parent = Workspace
        M.Platform = p
    end
    local function SetupAlign()
        local _, _, hrp = GetCharacterReferences()
        if not hrp then return false end
        if M.AlignPos then M.AlignPos:Destroy() end
        local att = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment")
        if not att.Parent then att.Name = "RootAttachment" att.Parent = hrp end
        local ap = Instance.new("AlignPosition")
        ap.Attachment0 = att
        ap.MaxForce = math.huge
        ap.MaxVelocity = math.huge
        ap.Responsiveness = 200
        ap.RigidityEnabled = true
        ap.Parent = hrp
        M.AlignPos = ap
        return true
    end
    local function Cleanup()
        if M.Connection then M.Connection:Disconnect() M.Connection = nil end
        if M.AlignPos then M.AlignPos:Destroy() M.AlignPos = nil end
        if M.Platform then M.Platform:Destroy() M.Platform = nil end
    end
    function M.Start()
        if M.Enabled then return end
        local char, humanoid, hrp = GetCharacterReferences()
        if not char or not humanoid or not hrp then return end
        ForceSurfaceLift()
        M.Enabled = true
        LAST_WATER_Y = nil
        CreatePlatform()
        if not SetupAlign() then M.Enabled = false Cleanup() return end
        M.Connection = RunService.Heartbeat:Connect(function()
            if not M.Enabled then return end
            local _, _, currentHRP = GetCharacterReferences()
            if not currentHRP then return end
            local waterY = GetWaterHeight()
            if not waterY then return end
            if M.Platform then M.Platform.CFrame = CFrame.new(currentHRP.Position.X, waterY - 0.5, currentHRP.Position.Z) end
            if M.AlignPos then M.AlignPos.Position = Vector3.new(currentHRP.Position.X, waterY + OFFSET, currentHRP.Position.Z) end
        end)
    end
    function M.Stop()
        M.Enabled = false
        Cleanup()
    end
    LocalPlayer.CharacterAdded:Connect(function()
        if M.Enabled then task.wait(0.5) Cleanup() M.Enabled = false M.Start() end
    end)
    return M
end)()

-- Section: Support Features (Support Fishing)
local SupportSection = FishTab:AddSection("Support Features")
SupportSection:AddToggle({
    Title = "No Fishing Animation",
    Default = false,
    Callback = function(on)
        if on then NoFishingAnimation.StartWithDelay() else NoFishingAnimation.Stop() end
    end
})
SupportSection:AddToggle({
    Title = "Auto Equip Rod" .. (AutoEquipRod.isSupported and "" or " (Not Supported)"),
    Default = false,
    Callback = function(on)
        if AutoEquipRod and AutoEquipRod.isSupported then
            if on then AutoEquipRod.Start() else AutoEquipRod.Stop() end
        elseif on then
            warn("Auto Equip Rod tidak support di executor ini")
        end
    end
})
SupportSection:AddToggle({
    Title = "Lock Position",
    Default = false,
    Callback = function(on)
        if on then LockPosition.Start() else LockPosition.Stop() end
    end
})
SupportSection:AddToggle({
    Title = "Disable Cutscenes",
    Default = false,
    Callback = function(on)
        if on then DisableCutscenes.Start() else DisableCutscenes.Stop() end
    end
})
SupportSection:AddToggle({
    Title = "Disable Obtained Fish Notification",
    Default = false,
    Callback = function(on)
        if on then DisableExtras.StartSmallNotification() else DisableExtras.StopSmallNotification() end
    end
})
SupportSection:AddToggle({
    Title = "Disable Skin Effect",
    Default = false,
    Callback = function(on)
        if on then DisableExtras.StartSkinEffect() else DisableExtras.StopSkinEffect() end
    end
})
SupportSection:AddToggle({
    Title = "Walk On Water",
    Default = false,
    Callback = function(on)
        if on then WalkOnWater.Start() else WalkOnWater.Stop() end
    end
})
SupportSection:AddToggle({
    Title = "Stable Result Perfection",
    Default = false,
    Callback = function(on)
        if on then StableResult.Start() else StableResult.Stop() end
    end
})

-- ========== AUTO FAVORITE MODULE ==========
local AutoFavorite = (function()
    local M = {}
    local v0 = { RS = ReplicatedStorage, Players = Players }
    local v5, v6, v7
    local referencesInitialized = false

    local function InitializeReferences()
        if referencesInitialized then return true end
        local success = pcall(function()
            v5 = {
                ItemUtility = require(v0.RS.Shared.ItemUtility),
                PlayerStatsUtility = require(v0.RS.Shared.PlayerStatsUtility)
            }
            v6 = { Events = { REFav = EmbeddedEventResolver:GetRE("FavoriteItem") } }
            v7 = {
                Data = require(v0.RS.Packages.Replion).Client:WaitReplion("Data"),
                Items = v0.RS:WaitForChild("Items"),
                Variants = v0.RS:WaitForChild("Variants")
            }
            referencesInitialized = true
        end)
        return success
    end

    local v8 = { selectedName = {}, selectedRarity = {}, selectedVariant = {}, autoFavEnabled = false, autoFavRubyGemstone = false }
    local v22 = {}
    local listenerRegistered = false

    local function toSet(arr)
        local set = {}
        for _, v in ipairs(arr) do set[v] = true end
        return set
    end

    local function getVariantNameFromId(id)
        if type(id) == "string" then return id end
        if not v7 or not v7.Variants then return nil end
        for _, mod in ipairs(v7.Variants:GetChildren()) do
            if mod:IsA("ModuleScript") then
                local ok, d = pcall(require, mod)
                if ok and d and d.Data and (d.Data.Id == id or d.Data.Name == id or tostring(mod.Name) == tostring(id)) then
                    return mod.Name
                end
            end
        end
        return nil
    end

    local function EnsureInventoryListener()
        if not referencesInitialized or listenerRegistered then return end
        if v7 and v7.Data then
            pcall(function() v7.Data:OnChange({"Inventory", "Items"}, scanInventory) end)
            listenerRegistered = true
        end
    end

    local v11 = {}
    local function BuildFishList()
        v11 = {}
        if not referencesInitialized then InitializeReferences() end
        if not v7 or not v7.Items then return v11 end
        pcall(function()
            for _, itemFolder in ipairs(v7.Items:GetChildren()) do
                if itemFolder:IsA("Folder") then
                    for _, fishModule in ipairs(itemFolder:GetChildren()) do
                        if fishModule:IsA("ModuleScript") then
                            local success, fishData = pcall(require, fishModule)
                            if success and fishData and fishData.Data then
                                local displayName = fishData.Data.DisplayName or fishData.Data.Name
                                if displayName and not table.find(v11, displayName) then table.insert(v11, displayName) end
                            end
                        end
                    end
                elseif itemFolder:IsA("ModuleScript") then
                    local success, fishData = pcall(require, itemFolder)
                    if success and fishData and fishData.Data then
                        local displayName = fishData.Data.DisplayName or fishData.Data.Name
                        if displayName and not table.find(v11, displayName) then table.insert(v11, displayName) end
                    end
                end
            end
            table.sort(v11)
        end)
        return v11
    end

    local variantList = {}
    local function BuildVariantList()
        variantList = {}
        if not referencesInitialized then InitializeReferences() end
        if not v7 or not v7.Variants then return variantList end
        pcall(function()
            for _, variantModule in ipairs(v7.Variants:GetChildren()) do
                if variantModule:IsA("ModuleScript") then
                    local variantName = variantModule.Name
                    if variantName and variantName ~= "1x1x1x1" and not table.find(variantList, variantName) then
                        table.insert(variantList, variantName)
                    end
                end
            end
            table.sort(variantList)
        end)
        return variantList
    end

    local function scanInventory()
        if not v8.autoFavEnabled and not v8.autoFavRubyGemstone then return end
        if not referencesInitialized then return end
        pcall(function()
            local inventory = v7.Data:GetExpect({"Inventory", "Items"})
            for _, item in ipairs(inventory) do
                local isFavorited = rawget(v22, item.UUID)
                if isFavorited == nil then isFavorited = item.Favorited end
                if not isFavorited then
                    local shouldFavorite = false
                    local fishData = v5.ItemUtility:GetItemData(item.Id)
                    if fishData then
                        local fishName = fishData.Data.DisplayName or fishData.Data.Name
                        local fishTier = fishData.Data.Tier
                        local variantId = item.Metadata and item.Metadata.VariantId or "None"
                        local variantDisplayName = (variantId == "None" or not variantId) and "None" or (type(variantId) == "string" and variantId or getVariantNameFromId(variantId) or tostring(variantId))
                        -- Spesifik: Ruby + Variant Gemstone
                        if v8.autoFavRubyGemstone and fishName == "Ruby" and (variantDisplayName == "Gemstone" or variantId == "Gemstone") then
                            shouldFavorite = true
                        end
                        if not shouldFavorite and next(v8.selectedName) and next(v8.selectedVariant) and fishName then
                            if v8.selectedName[fishName] and variantId ~= "None" and (v8.selectedVariant[variantId] or v8.selectedVariant[variantDisplayName]) then
                                shouldFavorite = true
                            end
                        end
                        if not shouldFavorite and next(v8.selectedVariant) and not next(v8.selectedName) then
                            if variantId ~= "None" and (v8.selectedVariant[variantId] or v8.selectedVariant[variantDisplayName]) then shouldFavorite = true end
                        end
                        if not shouldFavorite and next(v8.selectedName) and not next(v8.selectedVariant) and fishName then
                            if v8.selectedName[fishName] then shouldFavorite = true end
                        end
                        if not shouldFavorite and next(v8.selectedRarity) and not next(v8.selectedName) and not next(v8.selectedVariant) and fishTier then
                            local tierNames = { [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic", [5] = "Legendary", [6] = "Mythic", [7] = "Secret" }
                            local tierName = tierNames[fishTier]
                            if tierName and v8.selectedRarity[tierName] then shouldFavorite = true end
                        end
                        if shouldFavorite then
                            task.spawn(function()
                                task.wait(0.1)
                                if v6.Events.REFav then v6.Events.REFav:FireServer(item.UUID) end
                                rawset(v22, item.UUID, true)
                            end)
                        end
                    end
                end
            end
        end)
    end

    function M.GetAllFishNames()
        if #v11 == 0 then BuildFishList() end
        return #v11 > 0 and v11 or {"No Fish Found"}
    end

    function M.GetAllVariants()
        if #variantList == 0 then BuildVariantList() end
        return #variantList > 0 and variantList or {"No Variants Found"}
    end

    function M.GetAllTiers()
        return {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"}
    end

    function M.SetSelectedNames(names)
        v8.selectedName = toSet(names)
        if v8.autoFavEnabled then scanInventory() end
    end

    function M.SetSelectedRarity(rarities)
        v8.selectedRarity = toSet(rarities)
        if v8.autoFavEnabled then scanInventory() end
    end

    function M.SetSelectedVariants(variants)
        v8.selectedVariant = toSet(variants)
        if v8.autoFavEnabled or v8.autoFavRubyGemstone then scanInventory() end
    end

    function M.SetRubyGemstoneOnly(enabled)
        v8.autoFavRubyGemstone = enabled
        if enabled then
            if not referencesInitialized then InitializeReferences() end
            EnsureInventoryListener()
            scanInventory()
        end
    end

    function M.IsRubyGemstoneOnly()
        return v8.autoFavRubyGemstone
    end

    function M.GetCurrentMode()
        local hasNames = next(v8.selectedName) ~= nil
        local hasVariants = next(v8.selectedVariant) ~= nil
        local hasRarity = next(v8.selectedRarity) ~= nil
        if hasNames and hasVariants then return "Name + Variant (Specific)"
        elseif hasVariants and not hasNames then return "Variant Only (All Fish)"
        elseif hasNames and not hasVariants then return "Name Only (Any Variant)"
        elseif hasRarity then return "Rarity Only"
        else return "No Filter Selected" end
    end

    function M.Start()
        if not referencesInitialized then
            local success = InitializeReferences()
            if not success then return false, "Failed to initialize" end
        end
        v8.autoFavEnabled = true
        EnsureInventoryListener()
        scanInventory()
        return true, "Started"
    end

    function M.Stop()
        v8.autoFavEnabled = false
        return true, "Stopped"
    end

    function M.UnfavoriteAll()
        if not referencesInitialized then return end
        pcall(function()
            local inventory = v7.Data:GetExpect({"Inventory", "Items"})
            for _, item in ipairs(inventory) do
                local isFavorited = rawget(v22, item.UUID)
                if isFavorited == nil then isFavorited = item.Favorited end
                if isFavorited then
                    if v6.Events.REFav then v6.Events.REFav:FireServer(item.UUID) end
                    rawset(v22, item.UUID, false)
                end
            end
        end)
    end

    function M.RefreshLists()
        v11 = {}
        variantList = {}
        BuildFishList()
        BuildVariantList()
        return { FishCount = #v11, VariantCount = #variantList }
    end

    function M.IsEnabled()
        return v8.autoFavEnabled
    end

    task.spawn(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
        task.wait(1)
        local success = InitializeReferences()
        if success then
            BuildFishList()
            BuildVariantList()
        else
            task.wait(2)
            InitializeReferences()
            BuildFishList()
            BuildVariantList()
        end
    end)

    -- So UI can wait until lists are ready
    function M.WaitUntilReady(timeout)
        timeout = timeout or 8
        local t0 = tick()
        while not referencesInitialized do
            if tick() - t0 > timeout then break end
            task.wait(0.2)
        end
        BuildFishList()
        BuildVariantList()
    end

    return M
end)()

-- Tab: Favorite — tunggu list siap dulu baru isi dropdown (sync)
local FavoriteTab = Window:AddTab({ Name = "Favorite", Icon = "star" })
local AutoFavSection = FavoriteTab:AddSection("Auto Favorite")

local isAutoFavRunning = false

-- Tunggu game + init AutoFavorite (block sebentar biar list ke-load)
if not game:IsLoaded() then game.Loaded:Wait() end
AutoFavorite.WaitUntilReady(5)
task.wait(0.2)

AutoFavSection:AddDropdown({
    Title = "Name",
    Content = "Select specific fish names",
    Multi = true,
    Options = AutoFavorite.GetAllFishNames(),
    Default = {},
    Callback = function(selected)
        AutoFavorite.SetSelectedNames(selected)
        if isAutoFavRunning then
            AutoFavorite.Stop()
            task.wait(0.1)
            AutoFavorite.Start()
        end
    end
})

AutoFavSection:AddDropdown({
    Title = "Variant",
    Content = "Works alone OR with Name",
    Multi = true,
    Options = AutoFavorite.GetAllVariants(),
    Default = {},
    Callback = function(selected)
        AutoFavorite.SetSelectedVariants(selected)
        if isAutoFavRunning then
            AutoFavorite.Stop()
            task.wait(0.1)
            AutoFavorite.Start()
        end
    end
})

AutoFavSection:AddDropdown({
    Title = "Rarity",
    Content = "Filter by rarity (Optional)",
    Multi = true,
    Options = AutoFavorite.GetAllTiers(),
    Default = {},
    Callback = function(selected)
        AutoFavorite.SetSelectedRarity(selected)
        if isAutoFavRunning then
            AutoFavorite.Stop()
            task.wait(0.1)
            AutoFavorite.Start()
        end
    end
})

AutoFavSection:AddToggle({
    Title = "Auto Favorite",
    Default = false,
    Callback = function(on)
        if on then
            AutoFavorite.Start()
            isAutoFavRunning = true
        else
            AutoFavorite.Stop()
            isAutoFavRunning = false
        end
    end
})

AutoFavSection:AddToggle({
    Title = "Auto Favorite Ruby Gemstone",
    Default = false,
    Callback = function(on)
        AutoFavorite.SetRubyGemstoneOnly(on)
    end
})

AutoFavSection:AddButton({
    Title = "Refresh Lists",
    Callback = function()
        AutoFavorite.RefreshLists()
    end
})

AutoFavSection:AddButton({
    Title = "Unfavorite Fish",
    Callback = function()
        AutoFavorite.UnfavoriteAll()
    end
})

-- ========== AUTO SELL MODULE ==========
local AutoSellSystem = (function()
    local M = {}
    M.Timer = {}
    M.Count = {}

    local function getSellRemote()
        return EmbeddedEventResolver:GetRF("SellAllItems")
    end

    local function parseNumber(text)
        if not text or text == "" then return 0 end
        local cleaned = tostring(text):gsub("%D", "")
        if cleaned == "" then return 0 end
        return tonumber(cleaned) or 0
    end

    local function getBagCount()
        local gui = localPlayer:FindFirstChild("PlayerGui")
        if not gui then return 0, 0 end
        local inv = gui:FindFirstChild("Inventory")
        if not inv then return 0, 0 end
        local label = inv:FindFirstChild("Main")
            and inv.Main:FindFirstChild("Top")
            and inv.Main.Top:FindFirstChild("Options")
            and inv.Main.Top.Options:FindFirstChild("Fish")
            and inv.Main.Top.Options.Fish:FindFirstChild("Label")
            and inv.Main.Top.Options.Fish.Label:FindFirstChild("BagSize")
        if not label or not label:IsA("TextLabel") then return 0, 0 end
        local curText, maxText = label.Text:match("(.+)%/(.+)")
        if not curText or not maxText then return 0, 0 end
        return parseNumber(curText), parseNumber(maxText)
    end

    local state = { totalSells = 0, lastSellTime = 0 }
    local timerMode = { enabled = false, interval = 5, task = nil, sellCount = 0 }
    local countMode = { enabled = false, target = 235, checkDelay = 1.5, lastSell = 0, task = nil }

    local function executeSell()
        local remote = getSellRemote()
        if not remote then return false end
        local success = pcall(function() return remote:InvokeServer() end)
        if success then
            state.totalSells = state.totalSells + 1
            state.lastSellTime = tick()
            return true
        end
        return false
    end

    function M.SellOnce()
        if not getSellRemote() then return false end
        if tick() - state.lastSellTime < 0.5 then return false end
        return executeSell()
    end

    function M.Timer.Start(interval)
        if timerMode.enabled then return false end
        if not getSellRemote() then return false end
        if interval and tonumber(interval) and tonumber(interval) >= 1 then
            timerMode.interval = tonumber(interval)
        end
        timerMode.enabled = true
        timerMode.sellCount = 0
        timerMode.task = task.spawn(function()
            while timerMode.enabled do
                task.wait(timerMode.interval)
                if not timerMode.enabled then break end
                if executeSell() then timerMode.sellCount = timerMode.sellCount + 1 end
            end
        end)
        return true
    end

    function M.Timer.Stop()
        if not timerMode.enabled then return false end
        timerMode.enabled = false
        if timerMode.task then task.cancel(timerMode.task) timerMode.task = nil end
        return true
    end

    function M.Timer.SetInterval(seconds)
        if tonumber(seconds) and tonumber(seconds) >= 1 then
            timerMode.interval = tonumber(seconds)
            return true
        end
        return false
    end

    function M.Count.Start(target)
        if countMode.enabled then return false end
        if not getSellRemote() then return false end
        if target and tonumber(target) and tonumber(target) > 0 then
            countMode.target = tonumber(target)
        end
        countMode.enabled = true
        countMode.task = task.spawn(function()
            while countMode.enabled do
                task.wait(countMode.checkDelay)
                if not countMode.enabled then break end
                local current, max = getBagCount()
                if countMode.target > 0 and current >= countMode.target then
                    if tick() - countMode.lastSell >= 3 then
                        countMode.lastSell = tick()
                        executeSell()
                        task.wait(2)
                    end
                end
            end
        end)
        return true
    end

    function M.Count.Stop()
        if not countMode.enabled then return false end
        countMode.enabled = false
        if countMode.task then task.cancel(countMode.task) countMode.task = nil end
        return true
    end

    function M.Count.SetTarget(count)
        if tonumber(count) and tonumber(count) > 0 then
            countMode.target = tonumber(count)
            return true
        end
        return false
    end

    return M
end)()

-- ========== AUTO BUY WEATHER MODULE ==========
local AutoBuyWeather = (function()
    local M = {}
    local function getWeatherRemote()
        return EmbeddedEventResolver:GetRF("PurchaseWeatherEvent")
    end
    local isRunning = false
    local selected = {}

    M.AllWeathers = { "Cloudy", "Storm", "Wind", "Snow", "Radiant", "Shark Hunt" }

    function M.SetSelected(list)
        selected = list or {}
    end

    function M.Start()
        if isRunning then return false end
        if not getWeatherRemote() then return false end
        if #selected == 0 then return false end
        isRunning = true
        local loopThread = task.spawn(function()
            while isRunning do
                for _, weather in ipairs(selected) do
                    if not isRunning then break end
                    pcall(function()
                        local remote = getWeatherRemote()
                        if remote then remote:InvokeServer(weather) end
                    end)
                    task.wait(0.1)
                end
                task.wait(10)
            end
        end)
        M._loopThread = loopThread
        return true
    end

    function M.Stop()
        if not isRunning then return false end
        isRunning = false
        if M._loopThread then task.cancel(M._loopThread) M._loopThread = nil end
        return true
    end

    function M.IsAvailable()
        return getWeatherRemote() ~= nil
    end

    return M
end)()

-- Tab: Shop (Auto Sell + Auto Buy Weather only)
local ShopTab = Window:AddTab({ Name = "Shop", Icon = "cart" })

local SellSection = ShopTab:AddSection("Auto Sell")
SellSection:AddButton({
    Title = "Sell All Now",
    Callback = function()
        AutoSellSystem.SellOnce()
    end
})

local autoSellMode = "Timer"
local autoSellEnabled = false
SellSection:AddDropdown({
    Title = "Auto Sell Mode",
    Options = {"Timer", "By Count"},
    Default = "Timer",
    Callback = function(selected)
        local previousMode = autoSellMode
        autoSellMode = selected
        if autoSellEnabled then
            if previousMode == "Timer" then AutoSellSystem.Timer.Stop() else AutoSellSystem.Count.Stop() end
            task.wait(0.1)
            if selected == "Timer" then AutoSellSystem.Timer.Start() else AutoSellSystem.Count.Start() end
        end
    end
})

SellSection:AddInput({
    Title = "Value (Seconds / Fish Count)",
    Default = "5",
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue then
            AutoSellSystem.Timer.SetInterval(numValue)
            AutoSellSystem.Count.SetTarget(numValue)
        end
    end
})

SellSection:AddToggle({
    Title = "Enable Auto Sell",
    Default = false,
    Callback = function(on)
        autoSellEnabled = on
        if on then
            if autoSellMode == "Timer" then
                AutoSellSystem.Timer.Start()
            else
                AutoSellSystem.Count.Start()
            end
        else
            AutoSellSystem.Timer.Stop()
            AutoSellSystem.Count.Stop()
        end
    end
})

local WeatherSection = ShopTab:AddSection("Auto Buy Weather")
local selectedWeathers = {"Cloudy", "Storm", "Wind"}
AutoBuyWeather.SetSelected(selectedWeathers)

WeatherSection:AddDropdown({
    Title = "Weather (multi)",
    Content = "Select weathers to auto buy",
    Multi = true,
    Options = AutoBuyWeather.AllWeathers,
    Default = selectedWeathers,
    Callback = function(selected)
        if selected and #selected > 0 then
            selectedWeathers = selected
            AutoBuyWeather.SetSelected(selectedWeathers)
        end
    end
})

WeatherSection:AddToggle({
    Title = "Enable Auto Weather",
    Content = "Auto buys selected weathers",
    Default = false,
    Callback = function(on)
        if on then
            AutoBuyWeather.SetSelected(selectedWeathers)
            if not AutoBuyWeather.IsAvailable() then return end
            AutoBuyWeather.Start()
        else
            AutoBuyWeather.Stop()
        end
    end
})

-- ========== AUTO BUY CHARM MODULE ==========
local BuyCharm = (function()
    local M = {}
    M.IsBuying = false
    M.AutoLoop = false
    M.Settings = { CharmType = 1, Amount = 1, Delay = 0.5 }

    local function getPurchaseRemote()
        return EmbeddedEventResolver:GetRF("PurchaseCharm")
    end

    local function purchaseCharm(charmType)
        local remote = getPurchaseRemote()
        if not remote then return false end
        local success = pcall(function() return remote:InvokeServer(charmType) end)
        return success
    end

    function M.SetCharmType(charmID)
        if charmID >= 1 and charmID <= 4 then
            M.Settings.CharmType = charmID
            return true
        end
        return false
    end

    function M.SetAmount(amount)
        amount = tonumber(amount)
        if amount and amount > 0 and amount <= 1000 then
            M.Settings.Amount = math.floor(amount)
            return true
        end
        return false
    end

    function M.SetDelay(delay)
        delay = tonumber(delay)
        if delay and delay >= 0 and delay <= 10 then
            M.Settings.Delay = delay
            return true
        end
        return false
    end

    function M.Start(amount, charmType)
        if M.IsBuying then return false end
        if amount then M.SetAmount(amount) end
        if charmType then M.SetCharmType(charmType) end
        if not getPurchaseRemote() then return false end
        M.IsBuying = true
        task.spawn(function()
            local targetAmount = M.Settings.Amount
            local charmID = M.Settings.CharmType
            for i = 1, targetAmount do
                if not M.IsBuying then break end
                purchaseCharm(charmID)
                if i < targetAmount and M.IsBuying then task.wait(M.Settings.Delay) end
            end
            M.IsBuying = false
        end)
        return true
    end

    function M.Stop()
        M.IsBuying = false
        M.AutoLoop = false
        return true
    end

    function M.EnableAutoLoop()
        if M.AutoLoop then return false end
        if not getPurchaseRemote() then return false end
        M.AutoLoop = true
        task.spawn(function()
            while M.AutoLoop do
                if not M.IsBuying then M.Start() end
                while M.IsBuying and M.AutoLoop do task.wait(0.5) end
                if M.AutoLoop then task.wait(1) end
            end
        end)
        return true
    end

    function M.DisableAutoLoop()
        M.AutoLoop = false
        M.IsBuying = false
        return true
    end

    function M.TestConnection()
        return getPurchaseRemote() ~= nil
    end

    return M
end)()

-- ========== AUTO CLAIM PIRATE CHEST MODULE ==========
local AutoClaimPirateChest = (function()
    local M = {}
    local enabled = false
    local claimInterval = 0.3
    local lastClaimTime = 0
    local claimConnection
    local newChestConnection

    local function getClaimRemote()
        return EmbeddedEventResolver:GetRE("ClaimPirateChest")
    end

    local function getPirateChests()
        local chests = {}
        local chestStorage = Workspace:FindFirstChild("PirateChestStorage")
        if chestStorage then
            for _, chest in pairs(chestStorage:GetChildren()) do
                if chest:IsA("Model") then table.insert(chests, chest.Name) end
            end
        end
        return chests
    end

    local function claimChest(chestId)
        pcall(function()
            local remote = getClaimRemote()
            if remote then remote:FireServer(chestId) end
        end)
    end

    function M.Start()
        if enabled then return end
        enabled = true
        claimConnection = task.spawn(function()
            while enabled do
                local chests = getPirateChests()
                for _, chestId in ipairs(chests) do
                    if not enabled then break end
                    claimChest(chestId)
                    task.wait(1.0)
                end
                task.wait(claimInterval)
            end
        end)
        newChestConnection = Workspace.DescendantAdded:Connect(function(descendant)
            if enabled and descendant.Parent and descendant.Parent.Name == "PirateChestStorage" then
                task.wait(0.2)
                if descendant:IsA("Model") then claimChest(descendant.Name) end
            end
        end)
    end

    function M.Stop()
        if not enabled then return end
        enabled = false
        if claimConnection then pcall(function() task.cancel(claimConnection) end) claimConnection = nil end
        if newChestConnection then newChestConnection:Disconnect() newChestConnection = nil end
    end

    function M.IsRunning()
        return enabled
    end

    return M
end)()

-- ========== SKIN ANIMATION MODULE ==========
local SkinSwapAnimation = (function()
    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local Animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

    local SkinAnimation = {}
    SkinAnimation.Connections = {}

    local SkinDatabase = {
        ["Eclipse"] = "rbxassetid://107940819382815",
        ["HolyTrident"] = "rbxassetid://128167068291703",
        ["SoulScythe"] = "rbxassetid://82259219343456",
        ["OceanicHarpoon"] = "rbxassetid://76325124055693",
        ["BinaryEdge"] = "rbxassetid://109653945741202",
        ["Vanquisher"] = "rbxassetid://93884986836266",
        ["KrampusScythe"] = "rbxassetid://134934781977605",
        ["BanHammer"] = "rbxassetid://96285280763544",
        ["CorruptionEdge"] = "rbxassetid://126613975718573",
        ["PrincessParasol"] = "rbxassetid://99143072029495"
    }

    local CurrentSkin = nil
    local AnimationPool = {}
    local IsEnabled = false
    local POOL_SIZE = 3
    local killedTracks = {}
    local replaceCount = 0
    local currentPoolIndex = 1

    local function LoadAnimationPool(skinId)
        local animId = SkinDatabase[skinId]
        if not animId then return false end
        for _, track in ipairs(AnimationPool) do
            pcall(function() track:Stop(0) track:Destroy() end)
        end
        AnimationPool = {}
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        anim.Name = "CUSTOM_SKIN_ANIM"
        for i = 1, POOL_SIZE do
            local track = Animator:LoadAnimation(anim)
            track.Priority = Enum.AnimationPriority.Action4
            track.Looped = false
            track.Name = "SKIN_POOL_" .. i
            table.insert(AnimationPool, track)
        end
        currentPoolIndex = 1
        return true
    end

    local function GetNextTrack()
        for i = 1, POOL_SIZE do
            local track = AnimationPool[i]
            if track and not track.IsPlaying then return track end
        end
        currentPoolIndex = currentPoolIndex % POOL_SIZE + 1
        return AnimationPool[currentPoolIndex]
    end

    local function IsFishCaughtAnimation(track)
        if not track or not track.Animation then return false end
        local trackName = string.lower(track.Name or "")
        local animName = string.lower(track.Animation.Name or "")
        return (string.find(trackName, "fishcaught") or string.find(animName, "fishcaught") or string.find(trackName, "caught") or string.find(animName, "caught"))
    end

    local function InstantReplace(originalTrack)
        local nextTrack = GetNextTrack()
        if not nextTrack then return end
        replaceCount = replaceCount + 1
        killedTracks[originalTrack] = tick()
        task.spawn(function()
            for i = 1, 10 do
                pcall(function()
                    if originalTrack.IsPlaying then
                        originalTrack:Stop(0)
                        originalTrack:AdjustSpeed(0)
                        originalTrack.TimePosition = 0
                    end
                end)
                task.wait()
            end
        end)
        pcall(function()
            if nextTrack.IsPlaying then nextTrack:Stop(0) end
            nextTrack:Play(0, 1, 1)
            nextTrack:AdjustSpeed(1)
        end)
        task.delay(1, function() killedTracks[originalTrack] = nil end)
    end

    localPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(1.5)
        char = newChar
        humanoid = char:WaitForChild("Humanoid")
        Animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        killedTracks = {}
        replaceCount = 0
        if IsEnabled and CurrentSkin then
            task.wait(0.5)
            LoadAnimationPool(CurrentSkin)
            if SkinAnimation.Connections.AnimationPlayed then SkinAnimation.Connections.AnimationPlayed:Disconnect() end
            SkinAnimation.Connections.AnimationPlayed = humanoid.AnimationPlayed:Connect(function(track)
                if not IsEnabled then return end
                if IsFishCaughtAnimation(track) then task.spawn(function() InstantReplace(track) end) end
            end)
        end
    end)

    function SkinAnimation.SwitchSkin(skinId)
        if not SkinDatabase[skinId] then return false end
        CurrentSkin = skinId
        if IsEnabled then return LoadAnimationPool(skinId) end
        return true
    end

    function SkinAnimation.Enable()
        if IsEnabled then return false end
        if not CurrentSkin then return false end
        local success = LoadAnimationPool(CurrentSkin)
        if success then
            IsEnabled = true
            killedTracks = {}
            replaceCount = 0
            SkinAnimation.Connections.AnimationPlayed = humanoid.AnimationPlayed:Connect(function(track)
                if not IsEnabled then return end
                if IsFishCaughtAnimation(track) then task.spawn(function() InstantReplace(track) end) end
            end)
            SkinAnimation.Connections.Heartbeat = RunService.Heartbeat:Connect(function()
                if not IsEnabled then return end
                for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                    if not string.find(string.lower(track.Name or ""), "skin_pool") then
                        if killedTracks[track] then
                            if track.IsPlaying then pcall(function() track:Stop(0) track:AdjustSpeed(0) end) end
                        else
                            if track.IsPlaying and IsFishCaughtAnimation(track) then
                                task.spawn(function() InstantReplace(track) end)
                            end
                        end
                    end
                end
            end)
            return true
        end
        return false
    end

    function SkinAnimation.Disable()
        if not IsEnabled then return false end
        IsEnabled = false
        killedTracks = {}
        replaceCount = 0
        for _, conn in pairs(SkinAnimation.Connections) do
            if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
        end
        SkinAnimation.Connections = {}
        for _, track in ipairs(AnimationPool) do pcall(function() track:Stop(0) end) end
        return true
    end

    function SkinAnimation.IsEnabled()
        return IsEnabled
    end

    function SkinAnimation.GetCurrentSkin()
        return CurrentSkin
    end

    function SkinAnimation.GetReplaceCount()
        return replaceCount
    end

    return SkinAnimation
end)()

-- Tab: Auto (Auto Buy Charm, Auto Claim Pirate, Skin Animation)
local AutoTab = Window:AddTab({ Name = "Auto", Icon = "auto" })

-- Section: Auto Buy Charm
local CharmSection = AutoTab:AddSection("Auto Buy Charm", false)
local selectedCharmType = 1
CharmSection:AddDropdown({
    Title = "Charm Type",
    Options = {"Bone Charm", "Algae Charm", "Magma Charm", "Clover Charm"},
    Default = "Bone Charm",
    Callback = function(selected)
        if selected == "Bone Charm" then selectedCharmType = 1
        elseif selected == "Algae Charm" then selectedCharmType = 2
        elseif selected == "Magma Charm" then selectedCharmType = 3
        elseif selected == "Clover Charm" then selectedCharmType = 4
        end
        BuyCharm.SetCharmType(selectedCharmType)
    end
})
CharmSection:AddInput({
    Title = "Amount",
    Default = "1",
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue then BuyCharm.SetAmount(numValue) end
    end
})
CharmSection:AddInput({
    Title = "Delay (sec)",
    Default = "0.5",
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue then BuyCharm.SetDelay(numValue) end
    end
})
CharmSection:AddButton({
    Title = "Buy Charm",
    Callback = function()
        if BuyCharm.IsBuying then return end
        if not BuyCharm.TestConnection() then return end
        BuyCharm.Start(nil, selectedCharmType)
    end
})
CharmSection:AddToggle({
    Title = "Auto Loop Buy Charm",
    Default = false,
    Callback = function(on)
        if on then BuyCharm.EnableAutoLoop() else BuyCharm.DisableAutoLoop() end
    end
})

-- Section: Auto Claim Pirate Chest
local AutoClaimSection = AutoTab:AddSection("Auto Claim Pirate Chest", false)
AutoClaimSection:AddToggle({
    Title = "Enable Auto Claim",
    Default = false,
    Callback = function(on)
        if on then AutoClaimPirateChest.Start() else AutoClaimPirateChest.Stop() end
    end
})

-- Section: Skin Animation
local SkinSection = AutoTab:AddSection("Skin Animation", false)
local skinNames = {"Eclipse Katana", "Holy Trident", "Soul Scythe", "Oceanic Harpoon", "Binary Edge", "The Vanquisher", "Frozen Krampus Scythe", "1x1x1x1 Ban Hammer", "Corruption Edge", "Princess Parasol"}
local skinInfo = {
    ["Eclipse Katana"] = "Eclipse",
    ["Holy Trident"] = "HolyTrident",
    ["Soul Scythe"] = "SoulScythe",
    ["Oceanic Harpoon"] = "OceanicHarpoon",
    ["Binary Edge"] = "BinaryEdge",
    ["The Vanquisher"] = "Vanquisher",
    ["Frozen Krampus Scythe"] = "KrampusScythe",
    ["1x1x1x1 Ban Hammer"] = "BanHammer",
    ["Corruption Edge"] = "CorruptionEdge",
    ["Princess Parasol"] = "PrincessParasol"
}
local selectedSkin = "Eclipse Katana"
SkinSection:AddDropdown({
    Title = "Select Skin",
    Options = skinNames,
    Default = "Eclipse Katana",
    Callback = function(selected)
        selectedSkin = selected
        if SkinSwapAnimation.IsEnabled() and skinInfo[selected] then
            SkinSwapAnimation.SwitchSkin(skinInfo[selected])
        end
    end
})
SkinSection:AddToggle({
    Title = "Enable Skin Animation",
    Default = false,
    Callback = function(on)
        if on then
            local skinParams = skinInfo[selectedSkin] or "Eclipse"
            SkinSwapAnimation.SwitchSkin(skinParams)
            SkinSwapAnimation.Enable()
        else
            SkinSwapAnimation.Disable()
        end
    end
})

-- Module: Auto Spawn Totem
CombinedModules.AutoSpawnTotem = (function()
    local AutoSpawnTotem = {}

    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local SpawnTotemRemote = nil
    local clientData = nil

    local function InitializeRemotes()
        local success = pcall(function()
            -- Resolve SpawnTotem via EmbeddedEventResolver (hash-safe)
            SpawnTotemRemote = EmbeddedEventResolver:GetRE("SpawnTotem")

            -- Replion client data (same pattern as AutoEquipRod)
            local Replion = require(ReplicatedStorage.Packages.Replion)
            clientData = Replion.Client:WaitReplion("Data")
        end)

        return success and SpawnTotemRemote ~= nil and clientData ~= nil
    end

    local TOTEM_DATA = {
        ["Luck Totem"]     = { Id = 1, Duration = 3600 },
        ["Mutation Totem"] = { Id = 2, Duration = 3600 },
        ["Shiny Totem"]    = { Id = 3, Duration = 3600 },
    }

    local TOTEM_NAMES = { "Luck Totem", "Mutation Totem", "Shiny Totem" }

    AutoSpawnTotem.Settings = {
        SelectedTotem = "Luck Totem",
        IsRunning = false,
        SpawnInterval = 3605
    }

    local AUTO_SPAWN_THREAD = nil

    local function GetTotemUUIDByName(totemName)
        if not clientData then return nil end

        local ok, inv = pcall(function()
            return clientData:Get("Inventory")
        end)

        if not ok or not inv or not inv.Totems then
            return nil
        end

        local entry = TOTEM_DATA[totemName]
        local targetId = entry and entry.Id
        if not targetId then return nil end

        for _, item in pairs(inv.Totems) do
            if item and item.UUID and tonumber(item.Id) == targetId then
                if (item.Count or 1) >= 1 then
                    return item.UUID
                end
            end
        end

        return nil
    end

    local function SpawnSingleTotem()
        local selectedTotemName = AutoSpawnTotem.Settings.SelectedTotem

        local totemUUID = GetTotemUUIDByName(selectedTotemName)

        if not totemUUID then
            warn(string.format("[AutoSpawnTotem] No %s available in inventory!", selectedTotemName))
            return false
        end

        if not SpawnTotemRemote then
            warn("[AutoSpawnTotem] SpawnTotemRemote not initialized!")
            return false
        end

        local ok = pcall(function()
            SpawnTotemRemote:FireServer(totemUUID)
        end)

        if ok then
            print(string.format("[AutoSpawnTotem] ✓ Spawned %s", selectedTotemName))
            return true
        else
            warn(string.format("[AutoSpawnTotem] Failed to spawn %s", selectedTotemName))
            return false
        end
    end

    local function RunAutoSpawnLoop()
        if AUTO_SPAWN_THREAD then
            pcall(function() task.cancel(AUTO_SPAWN_THREAD) end)
        end

        AUTO_SPAWN_THREAD = task.spawn(function()
            print("[AutoSpawnTotem] Started! Spawning every ~60m 5s...")

            SpawnSingleTotem()

            while AutoSpawnTotem.Settings.IsRunning do
                task.wait(AutoSpawnTotem.Settings.SpawnInterval)

                if AutoSpawnTotem.Settings.IsRunning then
                    SpawnSingleTotem()
                end
            end
        end)
    end

    function AutoSpawnTotem.SetTotem(totemName)
        if TOTEM_DATA[totemName] then
            AutoSpawnTotem.Settings.SelectedTotem = totemName
            print(string.format("[AutoSpawnTotem] Selected: %s", totemName))
            return true
        end
        return false
    end

    function AutoSpawnTotem.GetTotemNames()
        return TOTEM_NAMES
    end

    function AutoSpawnTotem.Start()
        if AutoSpawnTotem.Settings.IsRunning then
            warn("[AutoSpawnTotem] Already running!")
            return false
        end

        if not SpawnTotemRemote or not clientData then
            if not InitializeRemotes() then
                warn("[AutoSpawnTotem] Failed to initialize remotes")
                return false
            end
        end

        AutoSpawnTotem.Settings.IsRunning = true
        RunAutoSpawnLoop()
        return true
    end

    function AutoSpawnTotem.Stop()
        if not AutoSpawnTotem.Settings.IsRunning then
            warn("[AutoSpawnTotem] Not running!")
            return false
        end

        AutoSpawnTotem.Settings.IsRunning = false

        if AUTO_SPAWN_THREAD then
            pcall(function() task.cancel(AUTO_SPAWN_THREAD) end)
            AUTO_SPAWN_THREAD = nil
        end

        print("[AutoSpawnTotem] Stopped!")
        return true
    end

    function AutoSpawnTotem.IsRunning()
        return AutoSpawnTotem.Settings.IsRunning
    end

    function AutoSpawnTotem.GetCurrentTotem()
        return AutoSpawnTotem.Settings.SelectedTotem
    end

    function AutoSpawnTotem.SetInterval(seconds)
        if seconds and seconds > 0 then
            AutoSpawnTotem.Settings.SpawnInterval = seconds
            print(string.format("[AutoSpawnTotem] Interval set to %d seconds", seconds))
            return true
        end
        return false
    end

    function AutoSpawnTotem.GetInterval()
        return AutoSpawnTotem.Settings.SpawnInterval
    end

    function AutoSpawnTotem.SpawnNow()
        if not AutoSpawnTotem.Settings.IsRunning then
            warn("[AutoSpawnTotem] Not running! Start the module first.")
            return false
        end
        return SpawnSingleTotem()
    end

    task.spawn(function()
        task.wait(1)
        InitializeRemotes()
    end)

    return AutoSpawnTotem
end)()

if CombinedModules.AutoSpawnTotem then
    local AutoSpawnSection = AutoTab:AddSection("Auto Spawn Totem", false)

    AutoSpawnSection:AddDropdown({
        Title = "Totem Type",
        Content = "Select which totem to auto-spawn",
        Options = CombinedModules.AutoSpawnTotem.GetTotemNames(),
        Default = CombinedModules.AutoSpawnTotem.GetCurrentTotem(),
        Callback = function(selected)
            CombinedModules.AutoSpawnTotem.SetTotem(selected)
        end
    })

    AutoSpawnSection:AddToggle({
        Title = "Enable Auto Spawn",
        Default = false,
        NoSave = true,
        Callback = function(on)
            if on then
                CombinedModules.AutoSpawnTotem.Start()
            else
                CombinedModules.AutoSpawnTotem.Stop()
            end
        end
    })
end

-- ══════════════════════════════════════════
-- MODULE: WEBHOOK (Fish + Disconnect)
-- ══════════════════════════════════════════
local WebhookModule = (function()
    local M = {}
    local function getHTTPRequest()
        local requestFunctions = {
            request,
            http_request,
            (syn and syn.request),
            (fluxus and fluxus.request),
            (http and http.request),
            (solara and solara.request),
            (game and game.HttpGet and function(opts)
                if opts.Method == "GET" then
                    return { Body = game:HttpGet(opts.Url) }
                end
            end)
        }
        for _, func in ipairs(requestFunctions) do
            if func and type(func) == "function" then
                return func
            end
        end
        return nil
    end
    local httpRequest = getHTTPRequest()

    M.FishConfig = {
        WebhookURL = "",
        DiscordUserID = "",
        HideIdentity = "",
        DebugMode = false,
        EnabledRarities = {},
        UseSimpleMode = false
    }
    M.DisconnectConfig = {
        WebhookURL = "",
        DiscordUserID = "",
        HideIdentity = "",
        Enabled = false
    }

    local Items, Variants
    local function loadGameModules()
        local ok, err = pcall(function()
            Items = require(ReplicatedStorage:WaitForChild("Items"))
            Variants = require(ReplicatedStorage:WaitForChild("Variants"))
        end)
        return ok
    end

    local TIER_NAMES = {
        [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic",
        [5] = "Legendary", [6] = "Mythic", [7] = "SECRET"
    }
    local TIER_COLORS = {
        [1] = 9807270, [2] = 3066993, [3] = 3447003, [4] = 10181046,
        [5] = 15844367, [6] = 16711680, [7] = 65535
    }

    local isFishRunning = false
    local fishEventConnection = nil
    local isDisconnectEnabled = false
    local disconnectSetup = false

    local function getPlayerDisplayName()
        if M.FishConfig.HideIdentity and M.FishConfig.HideIdentity ~= "" then
            return M.FishConfig.HideIdentity
        end
        return localPlayer.DisplayName or localPlayer.Name
    end

    local function getDiscordImageUrl(assetId)
        if not assetId then return nil end
        local thumbnailUrl = string.format(
            "https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false",
            tostring(assetId)
        )
        local rbxcdnUrl = string.format("https://tr.rbxcdn.com/180DAY-%s/420/420/Image/Png", tostring(assetId))
        if httpRequest then
            local success, result = pcall(function()
                local response = httpRequest({ Url = thumbnailUrl, Method = "GET" })
                if response and response.Body then
                    local data = HttpService:JSONDecode(response.Body)
                    if data and data.data and data.data[1] and data.data[1].imageUrl then
                        return data.data[1].imageUrl
                    end
                end
            end)
            if success and result then return result end
        end
        return rbxcdnUrl
    end

    local function getFishImageUrl(fish)
        local assetId = nil
        if fish.Data.Icon then
            assetId = tostring(fish.Data.Icon):match("%d+")
        elseif fish.Data.ImageId then
            assetId = tostring(fish.Data.ImageId)
        elseif fish.Data.Image then
            assetId = tostring(fish.Data.Image):match("%d+")
        end
        if assetId then
            local discordUrl = getDiscordImageUrl(assetId)
            if discordUrl then return discordUrl end
        end
        return "https://i.imgur.com/UMWNYK7.png"
    end

    local function getFish(itemId)
        if not Items then return nil end
        for _, f in pairs(Items) do
            if f.Data and f.Data.Id == itemId then return f end
        end
        return nil
    end

    local function getVariant(id)
        if not id or not Variants then return nil end
        local idStr = tostring(id)
        for _, v in pairs(Variants) do
            if v.Data then
                if tostring(v.Data.Id) == idStr or tostring(v.Data.Name) == idStr then
                    return v
                end
            end
        end
        return nil
    end

    local function formatPrice(price)
        local formatted = tostring(math.floor(price))
        return formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end

    local function sendFishWebhook(fish, meta, extra)
        if not M.FishConfig.WebhookURL or M.FishConfig.WebhookURL == "" then return end
        if not httpRequest then return end
        local tier = TIER_NAMES[fish.Data.Tier] or "Unknown"
        local color = TIER_COLORS[fish.Data.Tier] or 3447003
        local enabledRarities = M.FishConfig.EnabledRarities
        if enabledRarities then
            local raritySet = {}
            local hasAnyFilter = false
            for k, v in pairs(enabledRarities) do
                if type(k) == "number" and type(v) == "string" then
                    raritySet[v] = true
                    hasAnyFilter = true
                elseif type(k) == "string" and v == true then
                    raritySet[k] = true
                    hasAnyFilter = true
                end
            end
            if hasAnyFilter and not raritySet[tier] then return end
        end
        local mutationText = "None"
        local finalPrice = fish.SellPrice or 0
        local variantId = nil
        if extra then variantId = extra.Variant or extra.Mutation or extra.VariantId or extra.MutationId end
        if not variantId and meta then variantId = meta.Variant or meta.Mutation or meta.VariantId or meta.MutationId end
        local isShiny = (meta and meta.Shiny) or (extra and extra.Shiny)
        if isShiny then mutationText = "Shiny"; finalPrice = finalPrice * 2 end
        if variantId then
            local v = getVariant(variantId)
            if v then
                mutationText = v.Data.Name .. " (" .. v.SellMultiplier .. "x)"
                finalPrice = finalPrice * v.SellMultiplier
            else
                mutationText = variantId
            end
        end
        local imageUrl = getFishImageUrl(fish)
        local playerDisplayName = getPlayerDisplayName()
        local mention = M.FishConfig.DiscordUserID ~= "" and "<@" .. M.FishConfig.DiscordUserID .. ">" or ""
        local congratsMsg = string.format("%s **%s** has caught a new **%s** tier fish!", mention, playerDisplayName, tier)
        local fields = {
            { name = "Fish Name", value = "```" .. fish.Data.Name .. "```", inline = false },
            { name = "Tier", value = "```" .. tier .. "```", inline = true },
            { name = "Weight", value = "```" .. string.format("%.2f Kg", meta.Weight or 0) .. "```", inline = true },
            { name = "Mutation", value = "```" .. mutationText .. "```", inline = true },
            { name = "Base Price", value = "```$" .. formatPrice(fish.SellPrice or 0) .. "```", inline = true },
            { name = "Final Price", value = "```$" .. formatPrice(finalPrice) .. "```", inline = true },
            { name = "Shiny", value = "```" .. (isShiny and "Yes" or "No") .. "```", inline = true }
        }
        local payload = {
            username = "King Vypers",
            avatar_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg",
            embeds = {{
                author = { name = "King Vypers | Fish Caught Notification" },
                description = congratsMsg,
                color = color,
                fields = fields,
                image = { url = imageUrl },
                footer = { text = "King Vypers • " .. os.date("%m/%d/%Y at %I:%M %p"), icon_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        pcall(function()
            httpRequest({
                Url = M.FishConfig.WebhookURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end

    local function sendDisconnectWebhook(reason)
        if not isDisconnectEnabled then return end
        local webhookURL = M.DisconnectConfig.WebhookURL
        if not webhookURL or webhookURL == "" or not webhookURL:match("discord") then return end
        if not httpRequest then return end
        local playerName = "Unknown"
        if M.DisconnectConfig.HideIdentity and M.DisconnectConfig.HideIdentity ~= "" then
            playerName = M.DisconnectConfig.HideIdentity
        elseif localPlayer and localPlayer.Name then
            playerName = localPlayer.Name
        end
        local mention = M.DisconnectConfig.DiscordUserID ~= "" and "<@" .. M.DisconnectConfig.DiscordUserID:gsub("%D", "") .. ">" or ""
        local disconnectReason = reason and reason ~= "" and reason or "Disconnected from server"
        local contentMsg = mention ~= "" and mention .. " Your account has been disconnected from the server!" or "Account disconnected from server!"
        local payload = {
            content = contentMsg,
            username = "King Vypers",
            avatar_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg",
            embeds = {{
                author = { name = "King Vypers | Disconnect Alert" },
                title = "Connection Lost",
                description = "**Your Roblox session has been disconnected.**\n\nAttempting to rejoin the server...",
                color = 9055487,
                fields = {
                    { name = "Account", value = "```" .. playerName .. "```", inline = true },
                    { name = "Time", value = "```" .. os.date("%m/%d/%Y at %I:%M %p") .. "```", inline = true },
                    { name = "Reason", value = "```" .. disconnectReason .. "```", inline = false }
                },
                footer = { text = "King Vypers • Auto-rejoin enabled", icon_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        task.spawn(function()
            pcall(function()
                httpRequest({
                    Url = webhookURL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(payload)
                })
            end)
        end)
    end

    local function setupDisconnectDetection()
        if disconnectSetup then return end
        disconnectSetup = true
        local hasDisconnected = false
        local function handleDisconnect(reason)
            if not hasDisconnected and isDisconnectEnabled then
                hasDisconnected = true
                sendDisconnectWebhook(reason or "Disconnected from server")
                task.wait(2)
                local TeleportService = game:GetService("TeleportService")
                TeleportService:Teleport(game.PlaceId, localPlayer)
            end
        end
        game:GetService("GuiService").ErrorMessageChanged:Connect(function(message)
            if message and message ~= "" then handleDisconnect(message) end
        end)
        pcall(function()
            local CoreGui = game:GetService("CoreGui")
            local RobloxPromptGui = CoreGui:FindFirstChild("RobloxPromptGui")
            if RobloxPromptGui then
                local promptOverlay = RobloxPromptGui:FindFirstChild("promptOverlay")
                if promptOverlay then
                    promptOverlay.ChildAdded:Connect(function(child)
                        if child.Name == "ErrorPrompt" then
                            task.wait(1)
                            local textLabel = child:FindFirstChildWhichIsA("TextLabel", true)
                            local reason = textLabel and textLabel.Text or "Disconnected"
                            handleDisconnect(reason)
                        end
                    end)
                end
            end
        end)
    end

    function M:SetFishWebhookURL(url) self.FishConfig.WebhookURL = url end
    function M:SetFishDiscordUserID(id) self.FishConfig.DiscordUserID = id end
    function M:SetFishEnabledRarities(rarities) self.FishConfig.EnabledRarities = rarities end
    function M:SetFishHideIdentity(name) self.FishConfig.HideIdentity = name end
    function M:SetDisconnectWebhookURL(url) self.DisconnectConfig.WebhookURL = url end
    function M:SetDisconnectDiscordUserID(id) self.DisconnectConfig.DiscordUserID = id end
    function M:SetDisconnectHideIdentity(name) self.DisconnectConfig.HideIdentity = name end
    function M:EnableDisconnectWebhook(enabled)
        self.DisconnectConfig.Enabled = enabled
        isDisconnectEnabled = enabled
        if enabled then setupDisconnectDetection() end
    end

    function M:StartFishWebhook()
        if isFishRunning then return false end
        if not self.FishConfig.WebhookURL or self.FishConfig.WebhookURL == "" then return false end
        if not httpRequest then return false end
        if not loadGameModules() then return false end
        local re = EmbeddedEventResolver:GetRE("ObtainedNewFishNotification")
        if not re or not re.OnClientEvent then return false end
        fishEventConnection = re.OnClientEvent:Connect(function(itemId, metadata, extraData)
            local fish = getFish(itemId)
            if fish then
                task.spawn(function() sendFishWebhook(fish, metadata or {}, extraData or {}) end)
            end
        end)
        isFishRunning = true
        return true
    end

    function M:StopFishWebhook()
        if not isFishRunning then return false end
        if fishEventConnection then
            fishEventConnection:Disconnect()
            fishEventConnection = nil
        end
        isFishRunning = false
        return true
    end

    function M:TestDisconnectWebhook()
        if not httpRequest then return false, "HTTP request not supported" end
        if not self.DisconnectConfig.WebhookURL or self.DisconnectConfig.WebhookURL == "" then
            return false, "Webhook URL not set"
        end
        sendDisconnectWebhook("Test Successfully :3")
        task.wait(2)
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, localPlayer)
        return true
    end

    function M:IsFishRunning() return isFishRunning end
    function M:IsDisconnectEnabled() return isDisconnectEnabled end
    function M:GetTierNames() return TIER_NAMES end
    function M:IsSupported() return httpRequest ~= nil end
    return M
end)()

-- ══════════════════════════════════════════
-- TAB: DISCORD WEBHOOK
-- ══════════════════════════════════════════
local WebhookTab = Window:AddTab({ Name = "Webhook", Icon = "discord" })

-- Section: Fish Caught Webhook
local FishCaughtSection = WebhookTab:AddSection("Fish Caught Webhook")
local currentWebhookURL = ""
local currentDiscordID = ""
local currentFishHideIdentity = ""
local fishWebhookToggle = nil

FishCaughtSection:AddInput({
    Title = "Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(value)
        currentWebhookURL = value:gsub("^%s*(.-)%s*$", "%1")
        if WebhookModule and WebhookModule.SetFishWebhookURL then
            pcall(function() WebhookModule:SetFishWebhookURL(currentWebhookURL) end)
        end
    end
})
FishCaughtSection:AddInput({
    Title = "Discord User ID (for mention)",
    Default = "",
    Placeholder = "123456789012345678",
    Callback = function(value)
        currentDiscordID = value:gsub("^%s*(.-)%s*$", "%1")
        if WebhookModule and WebhookModule.SetFishDiscordUserID then
            pcall(function() WebhookModule:SetFishDiscordUserID(currentDiscordID) end)
        end
    end
})
FishCaughtSection:AddInput({
    Title = "Hide Identity (Custom Name)",
    Default = "",
    Placeholder = "Enter custom name...",
    Callback = function(value)
        currentFishHideIdentity = value:gsub("^%s*(.-)%s*$", "%1")
        if WebhookModule and WebhookModule.SetFishHideIdentity then
            pcall(function() WebhookModule:SetFishHideIdentity(currentFishHideIdentity) end)
        end
    end
})
FishCaughtSection:AddDropdown({
    Title = "Rarity Filter",
    Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET" },
    Multi = true,
    Default = {},
    Callback = function(selected)
        if WebhookModule and WebhookModule.SetFishEnabledRarities then
            pcall(function() WebhookModule:SetFishEnabledRarities(selected) end)
        end
    end
})
fishWebhookToggle = FishCaughtSection:AddToggle({
    Title = "Enable Fish Webhook",
    Default = false,
    Callback = function(on)
        if not WebhookModule then return end
        if on then
            if currentWebhookURL == "" then
                if fishWebhookToggle and fishWebhookToggle.SetValue then
                    fishWebhookToggle:SetValue(false)
                end
                return
            end
            pcall(function()
                if WebhookModule.SetFishWebhookURL then WebhookModule:SetFishWebhookURL(currentWebhookURL) end
                if WebhookModule.SetFishDiscordUserID and currentDiscordID ~= "" then
                    WebhookModule:SetFishDiscordUserID(currentDiscordID)
                end
                if WebhookModule.SetFishHideIdentity and currentFishHideIdentity ~= "" then
                    WebhookModule:SetFishHideIdentity(currentFishHideIdentity)
                end
                if WebhookModule.StartFishWebhook then WebhookModule:StartFishWebhook() end
            end)
        else
            pcall(function()
                if WebhookModule.StopFishWebhook then WebhookModule:StopFishWebhook() end
            end)
        end
    end
})
FishCaughtSection:AddButton({
    Title = "Test Webhook",
    Callback = function()
        if currentWebhookURL == "" then
            warn("⚠️ Webhook URL belum diisi!")
            return
        end
        local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
        if requestFunc then
            local success, response = pcall(function()
                return requestFunc({
                    Url = currentWebhookURL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode({
                        username = "King Vypers",
                        avatar_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg",
                        embeds = {{
                            title = "🎣 Webhook Connection Test",
                            description = "**Connection Status:** ✅ Successfully Connected!\n\n*Your webhook is now ready to receive fish catch notifications.*",
                            color = 9055487,
                            fields = {
                                { name = "📊 System Status", value = "```diff\n+ Webhook Active\n+ Logger Ready\n+ Notifications Enabled```", inline = true },
                                { name = "⚙️ Features", value = "```yaml\nAuto-Logging: ON\nReal-time: ON\nGame: Fish It```", inline = true }
                            },
                            footer = { text = "King Vypers • Test Successful", icon_url = "https://raw.githubusercontent.com/semuao621-wq/Kamunanya/main/Kingvyperslogo.jpg" },
                            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                        }}
                    })
                })
            end)
            if success then
                print("✅ [Webhook] Test message sent successfully!")
            else
                warn("❌ [Webhook] Failed to send test message: " .. tostring(response))
            end
        else
            warn("❌ [Webhook] Request function not found! Executor might not support webhooks.")
        end
    end
})

-- Section: Disconnect Webhook
local DisconnectWebhookSection = WebhookTab:AddSection("Disconnect Webhook", false)
local disconnectWebhookURL = ""
local disconnectDiscordID = ""
local disconnectHideIdentity = ""

DisconnectWebhookSection:AddParagraph({
    Title = "Info",
    Content = "Kirim notifikasi ke Discord saat Roblox disconnect, dan otomatis rejoin."
})
DisconnectWebhookSection:AddInput({
    Title = "Disconnect Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(value)
        disconnectWebhookURL = value:gsub("^%s*(.-)%s*$", "%1")
        if WebhookModule and WebhookModule.SetDisconnectWebhookURL then
            pcall(function() WebhookModule:SetDisconnectWebhookURL(disconnectWebhookURL) end)
        end
    end
})
DisconnectWebhookSection:AddInput({
    Title = "Discord User ID (for mention)",
    Default = "",
    Placeholder = "123456789012345678",
    Callback = function(value)
        disconnectDiscordID = value:gsub("^%s*(.-)%s*$", "%1")
        if WebhookModule and WebhookModule.SetDisconnectDiscordUserID then
            pcall(function() WebhookModule:SetDisconnectDiscordUserID(disconnectDiscordID) end)
        end
    end
})
DisconnectWebhookSection:AddInput({
    Title = "Hide Identity (Custom Name)",
    Default = "",
    Placeholder = "Enter custom name...",
    Callback = function(value)
        disconnectHideIdentity = value:gsub("^%s*(.-)%s*$", "%1")
        if WebhookModule and WebhookModule.SetDisconnectHideIdentity then
            pcall(function() WebhookModule:SetDisconnectHideIdentity(disconnectHideIdentity) end)
        end
    end
})
DisconnectWebhookSection:AddToggle({
    Title = "Enable Disconnect Webhook",
    Default = false,
    Callback = function(on)
        if WebhookModule and WebhookModule.EnableDisconnectWebhook then
            pcall(function() WebhookModule:EnableDisconnectWebhook(on) end)
        end
    end
})
DisconnectWebhookSection:AddButton({
    Title = "Test Disconnect Webhook",
    Callback = function()
        if disconnectWebhookURL == "" then return end
        if WebhookModule and WebhookModule.TestDisconnectWebhook then
            pcall(function() WebhookModule:TestDisconnectWebhook() end)
        end
    end
})

-- Tab Player (Stay Active - disable Idled kick, no VirtualUser)
local StayActiveEnabled = false
local disabledIdledConns = {}

local function startStayActive()
    if StayActiveEnabled then return end
    StayActiveEnabled = true
    -- Nonaktifkan koneksi Idled game = kick idle ga pernah jalan (tanpa VirtualUser)
    if getconnections and type(getconnections) == "function" then
        pcall(function()
            for _, c in ipairs(getconnections(localPlayer.Idled)) do
                if c then
                    if c.Disable then pcall(c.Disable, c) end
                    if c.DisableConnection then pcall(c.DisableConnection, c) end
                    table.insert(disabledIdledConns, c)
                end
            end
        end)
    end
    -- Fallback: kalau executor ga punya getconnections, pakai VirtualUser jarang-jarang (random 40–90 detik)
    if #disabledIdledConns == 0 then
        local VirtualUser = game:GetService("VirtualUser")
        task.spawn(function()
            while StayActiveEnabled do
                task.wait(math.random() * 50 + 40)
                if not StayActiveEnabled then break end
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(), workspace.CurrentCamera.CFrame)
                end)
            end
        end)
    end
end

local function stopStayActive()
    if not StayActiveEnabled then return end
    StayActiveEnabled = false
    -- Aktifkan lagi koneksi Idled yang tadi dimatikan
    pcall(function()
        for _, c in ipairs(disabledIdledConns) do
            if c then
                if c.Enable then pcall(c.Enable, c) end
                if c.EnableConnection then pcall(c.EnableConnection, c) end
            end
        end
        disabledIdledConns = {}
    end)
end

local PlayerTab = Window:AddTab({ Name = "Player", Icon = "settings" })
local ProtectionSection = PlayerTab:AddSection("Protection", false)
ProtectionSection:AddToggle({
    Title = "Stay Active",
    Default = false,
    Callback = function(on)
        if on then startStayActive() else stopStayActive() end
    end
})

-- =================================================================
-- PERFORMANCE MODULES
-- =================================================================

CombinedModules.PotatoMode = (function()
    local PotatoMode = {}
    PotatoMode.Enabled = false

    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local StarterGui = game:GetService("StarterGui")

    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local originalStates = {
        lighting = {},
        waterProperties = {},
        camera = {}
    }

    local connections = {}
    local processedObjects = setmetatable({}, { __mode = "k" })

    local DESTROY_CLASSES = {
        ParticleEmitter = true, Trail = true, Beam = true, Fire = true,
        Smoke = true, Sparkles = true, PointLight = true, SpotLight = true,
        SurfaceLight = true, ForceField = true, Explosion = true,
        BloomEffect = true, BlurEffect = true, ColorCorrectionEffect = true,
        SunRaysEffect = true, DepthOfFieldEffect = true, Atmosphere = true,
        Decal = true, Texture = true, SurfaceAppearance = true,
        SpecialMesh = true, BlockMesh = true, CylinderMesh = true,
        Accessory = true, Hat = true, Shirt = true, Pants = true,
        ShirtGraphic = true, CharacterMesh = true, BodyColors = true,
        Clothing = true, HumanoidDescription = true
    }

    local function shouldDestroy(obj)
        return DESTROY_CLASSES[obj.ClassName]
    end

    local function optimizeCharacter(character)
        if not character or processedObjects[character] then return end
        processedObjects[character] = true

        pcall(function()
            local descendants = character:GetDescendants()
            for i = 1, #descendants do
                local obj = descendants[i]

                if shouldDestroy(obj) then
                    obj:Destroy()

                elseif obj:IsA("BasePart") then
                    if obj.Name == "Head" then
                        obj.Transparency = 1
                    end

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
                    for _, track in ipairs(obj:GetPlayingAnimationTracks()) do
                        track:Stop()
                    end
                    obj.HealthDisplayDistance = 0
                    obj.NameDisplayDistance = 0

                elseif obj:IsA("Sound") then
                    obj.Volume = 0
                end
            end
        end)
    end

    local function optimizeObject(obj)
        if not PotatoMode.Enabled or processedObjects[obj] then return end
        processedObjects[obj] = true

        if shouldDestroy(obj) then
            obj:Destroy()
            return
        end

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

    function PotatoMode.Enable()
        if PotatoMode.Enabled then return false end
        PotatoMode.Enabled = true

        task.spawn(function()
            local allObjects = Workspace:GetDescendants()
            local batchSize = 200
            for i = 1, #allObjects, batchSize do
                if not PotatoMode.Enabled then break end
                for j = i, math.min(i + batchSize - 1, #allObjects) do
                    optimizeObject(allObjects[j])
                end
                task.wait()
            end
        end)

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                optimizeCharacter(plr.Character)
            end
        end

        table.insert(connections, Players.PlayerAdded:Connect(function(plr)
            plr.CharacterAdded:Connect(function(character)
                if PotatoMode.Enabled then
                    task.wait(0.2)
                    optimizeCharacter(character)
                end
            end)
            if plr.Character then
                optimizeCharacter(plr.Character)
            end
        end))

        if LocalPlayer then
            table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(character)
                if PotatoMode.Enabled then
                    task.wait(0.2)
                    optimizeCharacter(character)
                end
            end))
            if LocalPlayer.Character then
                optimizeCharacter(LocalPlayer.Character)
            end
        end

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
        end

        for _, sky in ipairs(Lighting:GetChildren()) do
            if sky:IsA("Sky") then
                sky.SkyboxBk = ""
                sky.SkyboxDn = ""
                sky.SkyboxFt = ""
                sky.SkyboxLf = ""
                sky.SkyboxRt = ""
                sky.SkyboxUp = ""
                sky.StarCount = 0
                sky.SunAngularSize = 0
                sky.MoonAngularSize = 0
                sky.CelestialBodiesShown = false
            end
        end

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then atmosphere:Destroy() end

        if Terrain then
            local clouds = Terrain:FindFirstChildOfClass("Clouds")
            if clouds then clouds:Destroy() end
        end

        originalStates.lighting = {
            GlobalShadows = Lighting.GlobalShadows,
            Brightness = Lighting.Brightness,
            Technology = Lighting.Technology
        }

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 0
        Lighting.Brightness = 0
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Technology = Enum.Technology.Legacy
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ShadowSoftness = 0

        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end

        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        pcall(function()
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            settings().Rendering.EditQualityLevel = Enum.QualityLevel.Level01
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
            UserSettings():GetService("UserGameSettings").GraphicsQualityLevel = 1
        end)

        pcall(function()
            if Camera then
                originalStates.camera = { FieldOfView = Camera.FieldOfView }
                Camera.FieldOfView = 70
            end
        end)

        table.insert(connections, Workspace.DescendantAdded:Connect(function(obj)
            if PotatoMode.Enabled then
                if shouldDestroy(obj) then
                    obj:Destroy()
                else
                    task.defer(optimizeObject, obj)
                end
            end
        end))

        task.spawn(function()
            while PotatoMode.Enabled do
                task.wait(30)
                pcall(function() collectgarbage("collect") end)
            end
        end)

        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
        end)

        return true
    end

    function PotatoMode.Disable()
        if not PotatoMode.Enabled then return false end
        PotatoMode.Enabled = false

        if Terrain and originalStates.waterProperties then
            pcall(function()
                Terrain.WaterReflectance = originalStates.waterProperties.WaterReflectance
                Terrain.WaterWaveSize = originalStates.waterProperties.WaterWaveSize
                Terrain.WaterWaveSpeed = originalStates.waterProperties.WaterWaveSpeed
                Terrain.WaterTransparency = originalStates.waterProperties.WaterTransparency
                Terrain.Decoration = true
            end)
        end

        if originalStates.lighting.GlobalShadows ~= nil then
            Lighting.GlobalShadows = originalStates.lighting.GlobalShadows
            Lighting.Brightness = originalStates.lighting.Brightness
            Lighting.Technology = originalStates.lighting.Technology
        end

        if originalStates.camera.FieldOfView then
            pcall(function()
                if Camera then
                    Camera.FieldOfView = originalStates.camera.FieldOfView
                end
            end)
        end

        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end)
        pcall(function()
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.DistanceBased
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.Automatic
        end)

        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
        end)

        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        connections = {}

        processedObjects = setmetatable({}, { __mode = "k" })
        originalStates = { lighting = {}, waterProperties = {}, camera = {} }

        pcall(function() collectgarbage("collect") end)

        return true
    end

    function PotatoMode.IsEnabled()
        return PotatoMode.Enabled
    end

    return PotatoMode
end)()

CombinedModules.DisableRendering = (function()
    local DisableRendering = {}

    DisableRendering.Settings = {
        AutoPersist = true
    }

    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local State = {
        RenderingDisabled = false,
        RenderConnection = nil
    }

    function DisableRendering.Start()
        if State.RenderingDisabled then
            return false, "Already disabled"
        end

        local success, err = pcall(function()
            State.RenderConnection = RunService.RenderStepped:Connect(function()
                pcall(function()
                    RunService:Set3dRenderingEnabled(false)
                end)
            end)
            State.RenderingDisabled = true
        end)

        if not success then
            warn("[DisableRendering] Failed to start:", err)
            return false, "Failed to start"
        end

        return true, "Rendering disabled"
    end

    function DisableRendering.Stop()
        if not State.RenderingDisabled then
            return false, "Already enabled"
        end

        local success, err = pcall(function()
            if State.RenderConnection then
                State.RenderConnection:Disconnect()
                State.RenderConnection = nil
            end
            RunService:Set3dRenderingEnabled(true)
            State.RenderingDisabled = false
        end)

        if not success then
            warn("[DisableRendering] Failed to stop:", err)
            return false, "Failed to stop"
        end

        return true, "Rendering enabled"
    end

    function DisableRendering.Toggle()
        if State.RenderingDisabled then
            return DisableRendering.Stop()
        else
            return DisableRendering.Start()
        end
    end

    function DisableRendering.IsDisabled()
        return State.RenderingDisabled
    end

    if DisableRendering.Settings.AutoPersist and LocalPlayer then
        LocalPlayer.CharacterAdded:Connect(function()
            if State.RenderingDisabled then
                task.wait(0.5)
                pcall(function()
                    RunService:Set3dRenderingEnabled(false)
                end)
            end
        end)
    end

    function DisableRendering.Cleanup()
        if State.RenderingDisabled then
            pcall(function()
                RunService:Set3dRenderingEnabled(true)
            end)
        end
        if State.RenderConnection then
            State.RenderConnection:Disconnect()
        end
    end

    return DisableRendering
end)()

CombinedModules.UnlockFPS = (function()
    local UnlockFPS = {
        Enabled = false,
        CurrentCap = 60,
        AvailableCaps = { 60, 90, 120, 240 },
    }

    function UnlockFPS.SetCap(fps)
        UnlockFPS.CurrentCap = fps
        if UnlockFPS.Enabled and setfpscap then
            setfpscap(fps)
        elseif not setfpscap then
            warn("setfpscap() tidak tersedia di executor kamu.")
        end
    end

    function UnlockFPS.Start()
        if UnlockFPS.Enabled then return end
        UnlockFPS.Enabled = true
        if setfpscap then
            setfpscap(UnlockFPS.CurrentCap)
        end
    end

    function UnlockFPS.Stop()
        if not UnlockFPS.Enabled then return end
        UnlockFPS.Enabled = false
        if setfpscap then
            setfpscap(60)
        end
    end

    return UnlockFPS
end)()

-- Section: Performance (Player tab)
local PerformanceSection = PlayerTab:AddSection("Performance", false)

PerformanceSection:AddToggle({
    Title = "FPS Booster (Potato Mode)",
    Default = false,
    Callback = function(on)
        if CombinedModules.PotatoMode then
            if on then
                CombinedModules.PotatoMode.Enable()
            else
                CombinedModules.PotatoMode.Disable()
            end
        end
    end
})

PerformanceSection:AddToggle({
    Title = "Disable 3D Rendering",
    Default = false,
    Callback = function(on)
        if CombinedModules.DisableRendering then
            if on then
                CombinedModules.DisableRendering.Start()
            else
                CombinedModules.DisableRendering.Stop()
            end
        end
    end
})

local selectedFpsCap = 60
PerformanceSection:AddDropdown({
    Title = "FPS Cap",
    Content = "Select FPS limit (requires unlock enabled)",
    Options = { "60", "90", "120", "240" },
    Default = "60",
    Callback = function(value)
        selectedFpsCap = tonumber(value) or 60
        if CombinedModules.UnlockFPS then
            CombinedModules.UnlockFPS.SetCap(selectedFpsCap)
        end
    end
})

PerformanceSection:AddToggle({
    Title = "Enable FPS Unlock",
    Default = false,
    Callback = function(on)
        if CombinedModules.UnlockFPS then
            CombinedModules.UnlockFPS.CurrentCap = selectedFpsCap
            if on then
                CombinedModules.UnlockFPS.Start()
            else
                CombinedModules.UnlockFPS.Stop()
            end
        end
    end
})

-- =========================================================
-- VYPER PERFORMANCE MONITOR MODULE
-- =========================================================
local PerformanceMonitor = (function()
    local Monitor = {}
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local UserInputService = game:GetService("UserInputService")
    local PlayerGui = localPlayer:WaitForChild("PlayerGui")
    local TweenService = game:GetService("TweenService")
    local perfPanel = nil
    local notifPanel = nil
    local renderConnection = nil
    local heartbeatConnection = nil
    local notifConnection = nil
    local Theme = {
        BgColor = Color3.fromRGB(15, 15, 20),
        StrokeColor = Color3.fromRGB(100, 200, 255),
        NotifStrokeColor = Color3.fromRGB(0, 255, 128),
        TextColor = Color3.fromRGB(255, 255, 255),
        SubTextColor = Color3.fromRGB(180, 180, 180),
        Good = Color3.fromRGB(0, 255, 128),
        Warn = Color3.fromRGB(255, 200, 0),
        Bad = Color3.fromRGB(255, 50, 80),
        NotifColor = Color3.fromRGB(0, 255, 128),
        CornerRadius = UDim.new(0, 8),
        Font = Enum.Font.GothamBold
    }
    local function getNotificationCount()
        local count, activeCount = 0, 0
        pcall(function()
            if PlayerGui then
                local tn = PlayerGui:FindFirstChild("Text Notifications")
                if tn then
                    local frame = tn:FindFirstChild("Frame")
                    if frame then
                        for _, child in ipairs(frame:GetChildren()) do
                            if child.Name == "Tile" and child:IsA("Frame") then
                                count = count + 1
                                if child.Visible then activeCount = activeCount + 1 end
                            end
                        end
                    end
                end
            end
        end)
        return count, activeCount
    end
    local function MakeDraggable(frame, stroke)
        local dragging, dragInput, dragStart, startPos
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
                TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundTransparency = 0.05}):Play()
            end
        end)
        frame.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.3}):Play()
                TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 0.15}):Play()
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
    local function CreatePerformancePanel()
        if perfPanel then return perfPanel end
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "VyperPerformance"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.Parent = PlayerGui
        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 280, 0, 45)
        MainFrame.Position = UDim2.new(0.5, -140, 0, 10)
        MainFrame.BackgroundColor3 = Theme.BgColor
        MainFrame.BackgroundTransparency = 0.15
        MainFrame.BorderSizePixel = 0
        MainFrame.ClipsDescendants = true
        MainFrame.Parent = ScreenGui
        local Gradient = Instance.new("UIGradient")
        Gradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Theme.BgColor), ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35)) }
        Gradient.Rotation = 90
        Gradient.Parent = MainFrame
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = Theme.CornerRadius
        Corner.Parent = MainFrame
        local Stroke = Instance.new("UIStroke")
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Color = Theme.StrokeColor
        Stroke.Thickness = 1.2
        Stroke.Transparency = 0.3
        Stroke.Parent = MainFrame
        local Layout = Instance.new("UIListLayout")
        Layout.Parent = MainFrame
        Layout.FillDirection = Enum.FillDirection.Horizontal
        Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        Layout.VerticalAlignment = Enum.VerticalAlignment.Center
        Layout.Padding = UDim.new(0, 12)
        local function MakeSep()
            local S = Instance.new("Frame")
            S.Size = UDim2.new(0, 1, 0, 18)
            S.BackgroundColor3 = Color3.fromRGB(255,255,255)
            S.BackgroundTransparency = 0.8
            S.BorderSizePixel = 0
            S.Parent = MainFrame
        end
        local function MakeStatInfo(name, labelText)
            local Container = Instance.new("Frame")
            Container.Name = name
            Container.BackgroundTransparency = 1
            Container.Size = UDim2.new(0, 75, 1, 0)
            Container.Parent = MainFrame
            local Val = Instance.new("TextLabel")
            Val.Name = "Value"
            Val.Parent = Container
            Val.BackgroundTransparency = 1
            Val.Size = UDim2.new(1, 0, 0, 20)
            Val.Position = UDim2.new(0, 0, 0.5, -10)
            Val.Font = Theme.Font
            Val.Text = "--"
            Val.TextColor3 = Theme.TextColor
            Val.TextSize = 16
            Val.TextXAlignment = Enum.TextXAlignment.Center
            Val.RichText = true
            local Lab = Instance.new("TextLabel")
            Lab.Name = "Label"
            Lab.Parent = Container
            Lab.BackgroundTransparency = 1
            Lab.Size = UDim2.new(1, 0, 0, 12)
            Lab.Position = UDim2.new(0, 0, 1, -14)
            Lab.Font = Enum.Font.GothamMedium
            Lab.Text = labelText
            Lab.TextColor3 = Theme.SubTextColor
            Lab.TextSize = 9
            Lab.TextXAlignment = Enum.TextXAlignment.Center
            return Val
        end
        local FPSVal = MakeStatInfo("FPS", "FPS")
        MakeSep()
        local PingVal = MakeStatInfo("Ping", "PING ms")
        MakeSep()
        local CPUVal = MakeStatInfo("CPU", "CPU %")
        MakeDraggable(MainFrame, Stroke)
        perfPanel = { Gui = ScreenGui, FPS = FPSVal, Ping = PingVal, CPU = CPUVal, Frame = MainFrame, Stroke = Stroke }
        return perfPanel
    end
    local function CreateNotificationPanel()
        if notifPanel then return notifPanel end
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "VyperNotifications"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.Parent = PlayerGui
        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 100, 0, 45)
        MainFrame.Position = UDim2.new(0.5, -50, 0, 65)
        MainFrame.BackgroundColor3 = Theme.BgColor
        MainFrame.BackgroundTransparency = 0.15
        MainFrame.BorderSizePixel = 0
        MainFrame.ClipsDescendants = true
        MainFrame.Parent = ScreenGui
        local Gradient = Instance.new("UIGradient")
        Gradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Theme.BgColor), ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35)) }
        Gradient.Rotation = 90
        Gradient.Parent = MainFrame
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = Theme.CornerRadius
        Corner.Parent = MainFrame
        local Stroke = Instance.new("UIStroke")
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Color = Theme.NotifStrokeColor
        Stroke.Thickness = 1.2
        Stroke.Transparency = 0.3
        Stroke.Parent = MainFrame
        local Container = Instance.new("Frame")
        Container.Name = "Notif"
        Container.BackgroundTransparency = 1
        Container.Size = UDim2.new(1, -20, 1, 0)
        Container.Parent = MainFrame
        local Val = Instance.new("TextLabel")
        Val.Name = "Value"
        Val.Parent = Container
        Val.BackgroundTransparency = 1
        Val.Size = UDim2.new(1, 0, 0, 20)
        Val.Position = UDim2.new(0, 0, 0.5, -10)
        Val.Font = Theme.Font
        Val.Text = "--"
        Val.TextColor3 = Theme.NotifColor
        Val.TextSize = 16
        Val.TextXAlignment = Enum.TextXAlignment.Center
        Val.RichText = true
        local Lab = Instance.new("TextLabel")
        Lab.Name = "Label"
        Lab.Parent = Container
        Lab.BackgroundTransparency = 1
        Lab.Size = UDim2.new(1, 0, 0, 12)
        Lab.Position = UDim2.new(0, 0, 1, -14)
        Lab.Font = Enum.Font.GothamMedium
        Lab.Text = "NOTIFS"
        Lab.TextColor3 = Theme.SubTextColor
        Lab.TextSize = 9
        Lab.TextXAlignment = Enum.TextXAlignment.Center
        MakeDraggable(MainFrame, Stroke)
        notifPanel = { Gui = ScreenGui, Notif = Val, Frame = MainFrame, Stroke = Stroke }
        return notifPanel
    end
    local function CleanupPerformance()
        if renderConnection then renderConnection:Disconnect() renderConnection = nil end
        if heartbeatConnection then heartbeatConnection:Disconnect() heartbeatConnection = nil end
        if perfPanel and perfPanel.Gui then perfPanel.Gui:Destroy() end
        perfPanel = nil
        if PlayerGui then
            for _, c in ipairs(PlayerGui:GetChildren()) do
                if c.Name == "VyperPerformance" then c:Destroy() end
            end
        end
    end
    local function CleanupNotifications()
        if notifConnection then notifConnection:Disconnect() notifConnection = nil end
        if notifPanel and notifPanel.Gui then notifPanel.Gui:Destroy() end
        notifPanel = nil
        if PlayerGui then
            for _, c in ipairs(PlayerGui:GetChildren()) do
                if c.Name == "VyperNotifications" then c:Destroy() end
            end
        end
    end
    function Monitor:StartPerformance()
        CleanupPerformance()
        local ui = CreatePerformancePanel()
        if not ui then return end
        ui.Gui.Enabled = true
        local fpsAccumulator = 0
        renderConnection = RunService.RenderStepped:Connect(function(dt)
            fpsAccumulator = fpsAccumulator + dt
            if fpsAccumulator >= 0.5 then
                local fps = math.floor(1 / dt)
                local fpsColor = (fps >= 50 and Theme.Good) or (fps >= 30 and Theme.Warn) or Theme.Bad
                if ui.FPS then ui.FPS.Text = tostring(fps); ui.FPS.TextColor3 = fpsColor end
                fpsAccumulator = 0
            end
        end)
        local lastUpdate = tick()
        local cpuSmooth = 0
        heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
            if not ui.Gui or not ui.Gui.Parent then CleanupPerformance(); return end
            local rawLoad = math.clamp((dt / 0.01667) * 35, 0, 100)
            cpuSmooth = (cpuSmooth * 0.9) + (rawLoad * 0.1)
            local now = tick()
            if now - lastUpdate >= 0.35 then
                local displayLoad = math.floor(cpuSmooth)
                local cpuColor = (displayLoad < 50 and Theme.Good) or (displayLoad < 80 and Theme.Warn) or Theme.Bad
                if ui.CPU then ui.CPU.Text = tostring(displayLoad) .. "<font size='10'>%</font>"; ui.CPU.TextColor3 = cpuColor end
                local ping = 0
                pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                if ping <= 0 then ping = math.floor(localPlayer:GetNetworkPing() * 1000) end
                local pingColor = (ping < 100 and Theme.Good) or (ping < 200 and Theme.Warn) or Theme.Bad
                if ui.Ping then ui.Ping.Text = tostring(ping); ui.Ping.TextColor3 = pingColor end
                lastUpdate = now
            end
        end)
    end
    function Monitor:StopPerformance()
        CleanupPerformance()
    end
    function Monitor:StartNotifications()
        CleanupNotifications()
        local ui = CreateNotificationPanel()
        if not ui then return end
        ui.Gui.Enabled = true
        local lastNotifCount = 0
        local updateConnection
        updateConnection = RunService.Heartbeat:Connect(function()
            if not ui.Gui or not ui.Gui.Parent then
                if updateConnection then updateConnection:Disconnect() end
                CleanupNotifications()
                return
            end
            local totalNotifs, activeNotifs = getNotificationCount()
            if ui.Notif then
                ui.Notif.Text = tostring(totalNotifs) .. "<font size='10'>/" .. tostring(activeNotifs) .. "</font>"
                ui.Notif.TextColor3 = Theme.NotifColor
                if totalNotifs > lastNotifCount then
                    TweenService:Create(ui.Frame, TweenInfo.new(0.15), {BackgroundTransparency = 0.05}):Play()
                    TweenService:Create(ui.Stroke, TweenInfo.new(0.15), {Transparency = 0, Color = Theme.NotifColor}):Play()
                    task.delay(0.15, function()
                        TweenService:Create(ui.Frame, TweenInfo.new(0.3), {BackgroundTransparency = 0.15}):Play()
                        TweenService:Create(ui.Stroke, TweenInfo.new(0.3), {Transparency = 0.3, Color = Theme.NotifStrokeColor}):Play()
                    end)
                    lastNotifCount = totalNotifs
                end
            end
        end)
        pcall(function()
            local tn = localPlayer.PlayerGui and localPlayer.PlayerGui:FindFirstChild("Text Notifications")
            if tn then
                local frame = tn:FindFirstChild("Frame")
                if frame then
                    notifConnection = frame.ChildAdded:Connect(function(child)
                        if child.Name == "Tile" and notifPanel and notifPanel.Notif then
                            TweenService:Create(notifPanel.Stroke, TweenInfo.new(0.1), {Transparency = 0, Color = Theme.NotifColor, Thickness = 2}):Play()
                            task.delay(0.2, function()
                                TweenService:Create(notifPanel.Stroke, TweenInfo.new(0.3), {Transparency = 0.3, Color = Theme.NotifStrokeColor, Thickness = 1.2}):Play()
                            end)
                        end
                    end)
                end
            end
        end)
    end
    function Monitor:StopNotifications()
        CleanupNotifications()
    end
    return Monitor
end)()

-- Section: Vyper Manager (Performance + Notifications)
local MonitorSection = PlayerTab:AddSection("Vyper Manager", false)
MonitorSection:AddToggle({
    Title = "Show Performance Panel",
    Default = false,
    Callback = function(on)
        if on then
            PerformanceMonitor:StartPerformance()
        else
            PerformanceMonitor:StopPerformance()
        end
    end
})
MonitorSection:AddToggle({
    Title = "Show Notifications Panel",
    Default = false,
    Callback = function(on)
        if on then
            PerformanceMonitor:StartNotifications()
        else
            PerformanceMonitor:StopNotifications()
        end
    end
})
