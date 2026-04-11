local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Murder Mystery 2 (2026)",
    SubTitle = "by angel_engine7",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,                   -- Blurred Background Glass Effect
    Theme = "Dark",                   -- Dark Theme
    MinimizeKey = Enum.KeyCode.Insert -- Hide/Show toggle
})

-- TABS
local Tabs = {
    Me = Window:AddTab({ Title = "ME", Icon = "user" }),
    Player = Window:AddTab({ Title = "ESP", Icon = "users" }),
    Murder = Window:AddTab({ Title = "MURDER", Icon = "skull" }),
    Sheriff = Window:AddTab({ Title = "SHERIFF", Icon = "shield" }),
    AutoFarm = Window:AddTab({ Title = "AUTO FARM", Icon = "coins" }),
    Teleport = Window:AddTab({ Title = "TELEPORT", Icon = "map-pin" }),
    Settings = Window:AddTab({ Title = "SETTINGS", Icon = "settings" })
}

-- SERVICES & VARS
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

_G.ChamsActiveV3 = false
_G.AuraActiveV3 = false
_G.AuraRangeV3 = 50
_G.AutoCoinV3 = false
_G.SilentAim = false
_G.SilentAimFOV = 150
_G.ShowFOV = false
_G.TargetPart = "Head"
_G.WallCheck = false
_G.ScriptUnloaded = false

-- ==========================================
-- CORE FUNCTIONS
-- ==========================================

local function GetPlayerRole(player)
    if not player.Character then return "Innocent" end
    local function CheckItems(folder)
        if not folder then return nil end
        for _, item in pairs(folder:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("knife") or name:find("blade") or name:find("saw") or name:find("scythe") or name:find("axe") or name:find("bat") then
                    return "Murderer"
                elseif name:find("gun") or name:find("revolver") or name:find("blaster") or name:find("laser") or name:find("pistol") then
                    return "Sheriff"
                end
            end
        end
        return nil
    end
    return CheckItems(player.Character) or CheckItems(player:FindFirstChild("Backpack")) or "Innocent"
end

local function GetKnifeItem(player)
    local function CheckItems(folder)
        if not folder then return nil end
        for _, item in pairs(folder:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("knife") or name:find("blade") or name:find("saw") or name:find("scythe") or name:find("axe") or name:find("bat") then
                    return item
                end
            end
        end
        return nil
    end
    return CheckItems(player.Character) or CheckItems(player:FindFirstChild("Backpack"))
end

local function SilentHit(targetPlayer, noWait)
    local lp = game.Players.LocalPlayer
    local char = lp.Character
    local knife = GetKnifeItem(lp)
    if knife and knife:FindFirstChild("Handle") and char and char:FindFirstChild("HumanoidRootPart") and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local tRoot = targetPlayer.Character.HumanoidRootPart
        local lRoot = char.HumanoidRootPart
        local wasInBackpack = (knife.Parent == lp.Backpack)
        local dist = (lRoot.Position - tRoot.Position).Magnitude
        local oldPos = lRoot.CFrame
        if dist > 12 then
            lRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.2)
            if not noWait then task.wait(0.04) end
        end
        if wasInBackpack then knife.Parent = char end
        if firetouchinterest then
            firetouchinterest(knife.Handle, tRoot, 0)
            firetouchinterest(knife.Handle, tRoot, 1)
            -- Double check hit with head
            local head = targetPlayer.Character:FindFirstChild("Head")
            if head then
                firetouchinterest(knife.Handle, head, 0); firetouchinterest(knife.Handle, head, 1)
            end
        end
        if dist > 12 and not noWait then
            task.wait(0.04)
            lRoot.CFrame = oldPos
        end
        if wasInBackpack and not noWait then
            task.wait(0.01)
            knife.Parent = lp.Backpack
        end
    end
end

-- ==========================================
-- AUTO COIN FARM
-- ==========================================
local runningFarms = {}
local function OnNewRound(CoinContainer)
    if runningFarms[CoinContainer] then return end
    runningFarms[CoinContainer] = true
 
    task.spawn(function()
        local lp = game.Players.LocalPlayer
        local RunService = game:GetService("RunService")
        local cam = workspace.CurrentCamera
 
        while _G.AutoCoinV3 and CoinContainer.Parent do
            local char = lp.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local hrp = char.HumanoidRootPart
 
                -- Snapshot: take only current coins
                local coins = {}
                for _, coin in pairs(CoinContainer:GetChildren()) do
                    if coin.Name == "Coin_Server" and coin:IsA("BasePart") then
                        table.insert(coins, coin)
                    end
                end
 
                for _, coin in ipairs(coins) do
                    if not _G.AutoCoinV3 or not CoinContainer.Parent or char.Humanoid.Health <= 0 then break end
                    -- Is the coin still there?
                    if not coin.Parent then continue end
 
                    local distance = (hrp.Position - coin.Position).Magnitude
                    local speed = 25
                    local tweenTime = math.clamp(distance / speed, 0.1, 10) -- Reverted to original 0.1s minimum
 
                    -- Noclip
                    local noclipConn = RunService.Stepped:Connect(function()
                        if char then
                            for _, part in pairs(char:GetDescendants()) do
                                if part:IsA("BasePart") and part.CanCollide then
                                    part.CanCollide = false
                                end
                            end
                        end
                    end)
 
                    -- BodyVelocity
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = Vector3.new(0, 0, 0)
                    bv.MaxForce = Vector3.new(100000, 100000, 100000)
                    bv.Parent = hrp
 
                    -- BodyGyro: Keeps the character perfectly upright
                    local bg = Instance.new("BodyGyro")
                    bg.MaxTorque = Vector3.new(999999, 0, 999999)
                    bg.P = 999999
                    bg.D = 1000
                    bg.CFrame = CFrame.new(Vector3.new(0, 0, 0))
                    bg.Parent = hrp
 
                    -- Camera: follows position, rotation remains static
                    local camOffset = cam.CFrame.Position - hrp.Position
                    local camRot = cam.CFrame - cam.CFrame.Position
                    local savedCamType = cam.CameraType
                    cam.CameraType = Enum.CameraType.Scriptable
                    local camConn = RunService.RenderStepped:Connect(function()
                        cam.CFrame = CFrame.new(hrp.Position + camOffset) * camRot
                    end)
 
                    local _, ry, _ = hrp.CFrame:ToEulerAnglesYXZ()
                    local targetCFrame = CFrame.new(coin.Position) * CFrame.Angles(0, ry, 0)
 
                    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                    tween:Play()
 
                    local timeWaited = 0
                    local shouldBreak = false
                    while tween.PlaybackState == Enum.PlaybackState.Playing and timeWaited < tweenTime do
                        if not _G.AutoCoinV3 or char.Humanoid.Health <= 0 then
                            tween:Cancel()
                            shouldBreak = true
                            break
                        end
                        if not coin.Parent then
                            tween:Cancel()
                            break
                        end
                        -- Check if we are close enough to move instantly
                        if (hrp.Position - coin.Position).Magnitude < 2 then break end

                        task.wait(0.01)
                        timeWaited = timeWaited + 0.01
                    end

                    -- Always cleanup physics & camera, even on early break
                    if camConn then camConn:Disconnect() end
                    cam.CameraType = savedCamType
                    if noclipConn then noclipConn:Disconnect() end
                    if bv and bv.Parent then bv:Destroy() end
                    if bg and bg.Parent then bg:Destroy() end

                    -- Re-enable collision & platform stand
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid.PlatformStand = false
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                pcall(function() part.CanCollide = true end)
                            end
                        end
                    end

                    if shouldBreak then break end

                    task.wait(0.01)
                end
            end

            -- Safety Limit Check (40 coins)
            local coinData = lp:FindFirstChild("CoinData")
            if coinData and coinData.Value >= 40 then
                _G.AutoCoinV3 = false
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local lobby = workspace:FindFirstChild("Lobby")
                    if lobby then
                        local spawn = lobby:FindFirstChild("SpawnLocation", true) or lobby:FindFirstChild("Spawn", true)
                        if spawn and spawn:IsA("BasePart") then
                            hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
                        end
                    else
                        hrp.CFrame = CFrame.new(-108, 140, 18)
                    end
                end
                Fluent:Notify({ Title = "Safe Exit", Content = "Bag full (40/40). Teleported to Lobby.", Duration = 10 })
                break
            end

            task.wait(0.1)
        end
        runningFarms[CoinContainer] = nil
    end)
end
 
workspace.DescendantAdded:Connect(function(desc)
    if _G.AutoCoinV3 and desc.Name == "CoinContainer" then
        OnNewRound(desc)
    end
end)

-- ==========================================
-- ANTI-KICK
-- ==========================================
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    while true do
        task.wait(55)
        if game.Players.LocalPlayer then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end
    end
end)

-- ==========================================
-- TAB 1: ME
-- ==========================================
_G.WalkSpeedValue = 16
Tabs.Me:AddSlider("WalkSpeed", {
    Title = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 35,
    Rounding = 1,
    Callback = function(Value)
        _G.WalkSpeedValue = Value
    end
})

_G.InfJumpActive = false
Tabs.Me:AddToggle("InfJump", {
    Title = "Infinite Jump",
    Default = false,
    Callback = function(Value)
        _G.InfJumpActive = Value
    end
})

_G.NoclipActive = false
Tabs.Me:AddToggle("Noclip", {
    Title = "Noclip",
    Default = false,
    Callback = function(Value)
        _G.NoclipActive = Value
        if not Value then
            local lp = game.Players.LocalPlayer
            local char = lp.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

Tabs.Me:AddToggle("Fly", {
    Title = "Fly",
    Default = false,
    Callback = function(Value)
        _G.FlyActive = Value
        local lp = game.Players.LocalPlayer
        local char = lp.Character
        if char and char:FindFirstChild("Humanoid") then
            if not Value then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function() if hrp:FindFirstChild("MM2_Bypass_V") then hrp.MM2_Bypass_V:Destroy() end end)
                    pcall(function() if hrp:FindFirstChild("MM2_Bypass_G") then hrp.MM2_Bypass_G:Destroy() end end)
                end
                char.Humanoid.PlatformStand = false
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            end
        end
    end
})

_G.FlySpeed = 50
Tabs.Me:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Default = 50,
    Min = 0,
    Max = 300,
    Rounding = 1,
    Callback = function(Value)
        _G.FlySpeed = Value
    end
})

-- ==========================================
-- TAB 2: PLAYER
-- ==========================================
Tabs.Player:AddToggle("PlayerGunToggle", {
    Title = "Player/Gun Chams",
    Default = false,
    Callback = function(Value)
        _G.ChamsActiveV3 = Value
        if not Value then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("PlayerChams") then
                    player.Character.PlayerChams.Enabled = false
                end
            end
            local gunDrop = workspace:FindFirstChild("GunDrop", true) or workspace:FindFirstChild("Gun Drop", true)
            if gunDrop and gunDrop:FindFirstChild("GunChams") then
                gunDrop.GunChams.Enabled = false
            end
        end
    end
})

_G.SkeletonESP = false
Tabs.Player:AddToggle("Skeleton", {
    Title = "Skeleton",
    Default = false,
    Callback = function(Value)
        _G.SkeletonESP = Value
    end
})

_G.BoxESP = false
Tabs.Player:AddToggle("Box", {
    Title = "Box",
    Default = false,
    Callback = function(Value)
        _G.BoxESP = Value
    end
})

_G.DistanceESP = false
Tabs.Player:AddToggle("Distance", {
    Title = "Distance",
    Default = false,
    Callback = function(Value)
        _G.DistanceESP = Value
    end
})

-- ==========================================
-- TAB 3: MURDER
-- ==========================================
local function IsLocalMurderer()
    local lp = game.Players.LocalPlayer
    if not lp then return false end
    return GetPlayerRole(lp) == "Murderer"
end

Tabs.Murder:AddButton({
    Title = "Kill All",
    Description = "Eliminates all players instantly",
    Callback = function()
        local lp = game.Players.LocalPlayer
        if not lp or not lp.Character or not lp.Character:FindFirstChild("Humanoid") then return end
        if not IsLocalMurderer() then
            Fluent:Notify({ Title = "Error", Content = "You can only use it while you're Murderer.", Duration = 3 })
            return
        end
        local knife = GetKnifeItem(lp)
        if not knife then
            Fluent:Notify({ Title = "Error", Content = "Knife not found.", Duration = 3 })
            return
        end
        
        task.spawn(function()
            local originalPos = lp.Character.HumanoidRootPart.CFrame
            local targets = {}
            for _, p in pairs(game.Players:GetPlayers()) do
                if p ~= lp and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    table.insert(targets, p)
                end
            end
            
            if #targets == 0 then
                Fluent:Notify({ Title = "Info", Content = "No targets found.", Duration = 3 })
                return
            end
            
            Fluent:Notify({ Title = "Exterminate", Content = "Killing " .. #targets .. " players...", Duration = 2 })
            
            local function ensureKnifeEquipped()
                if not lp.Character or not knife then return false end
                if knife.Parent ~= lp.Character then
                    knife.Parent = lp.Character
                    task.wait(0.05)
                end
                return true
            end

            -- Pre-equip knife for the whole sequence
            ensureKnifeEquipped()
            task.wait(0.1) -- Small overhead to ensure tool is active

            for _, target in ipairs(targets) do
                if not lp.Character or not lp.Character:FindFirstChild("Humanoid") or lp.Character.Humanoid.Health <= 0 then break end
                if target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
                    local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                    local tHead = target.Character:FindFirstChild("Head")
                    if tRoot then
                        -- Instant Teleport
                        lp.Character.HumanoidRootPart.CFrame = tRoot.CFrame
                        -- Instant Multiple Touches
                        if firetouchinterest then
                            firetouchinterest(knife.Handle, tRoot, 0)
                            firetouchinterest(knife.Handle, tRoot, 1)
                            if tHead then
                                firetouchinterest(knife.Handle, tHead, 0)
                                firetouchinterest(knife.Handle, tHead, 1)
                            end
                        end
                        -- Ultra-small delay to allow server registration without being "too fast"
                        task.wait(0.01)
                    end
                end
            end
            
            lp.Character.HumanoidRootPart.CFrame = originalPos
            Fluent:Notify({ Title = "Success", Content = "Kill All Completed.", Duration = 3 })
        end)
    end
})

-- ==========================================
-- TAB 4: SHERIFF
-- ==========================================
Tabs.Sheriff:AddToggle("SilentAim", {
    Title = "Silent Aim",
    Default = false,
    Callback = function(Value)
        _G.SilentAim = Value
    end
})

Tabs.Sheriff:AddToggle("ShowFOV", {
    Title = "Show FOV Circle",
    Default = false,
    Callback = function(Value)
        _G.ShowFOV = Value
    end
})

Tabs.Sheriff:AddSlider("SilentAimFOV", {
    Title = "Silent Aim FOV",
    Default = 150,
    Min = 50,
    Max = 800,
    Rounding = 0,
    Callback = function(Value)
        _G.SilentAimFOV = Value
    end
})

Tabs.Sheriff:AddDropdown("TargetPart", {
    Title = "Target Part",
    Values = { "Head", "UpperTorso", "Random" },
    Default = "Head",
    Callback = function(Value)
        _G.TargetPart = Value
    end
})

Tabs.Sheriff:AddToggle("WallCheck", {
    Title = "Wall Check",
    Default = false,
    Callback = function(Value)
        _G.WallCheck = Value
    end
})

local getGunBind = Tabs.Sheriff:AddKeybind("GetGunKeybind", {
    Title = "Get Dropped Gun",
    Mode = "Toggle",
    Default = "G",
    Callback = function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "GunDrop" or obj.Name == "Gun Drop" then
                local lp = game.Players.LocalPlayer
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    local originalCFrame = lp.Character.HumanoidRootPart.CFrame
                    local targetCFrame = obj:IsA("Model") and obj:GetPivot() or obj.CFrame
                    lp.Character.HumanoidRootPart.CFrame = targetCFrame
                    task.wait(0.25)
                    lp.Character.HumanoidRootPart.CFrame = originalCFrame
                    Fluent:Notify({ Title = "Success", Content = "Gun collected", Duration = 3 })
                end
                return
            end
        end
        Fluent:Notify({ Title = "Error", Content = "No dropped gun found", Duration = 3 })
    end
})

Tabs.Sheriff:AddButton({
    Title = "Reset Get Gun Keybind",
    Callback = function()
        pcall(function()
            getGunBind:SetValue("G", "Toggle")
        end)
        Fluent:Notify({ Title = "Reset", Content = "Get Dropped Gun keybind set to G.", Duration = 3 })
    end
})

-- ==========================================
-- TAB 5: AUTO FARM
-- ==========================================
Tabs.AutoFarm:AddToggle("AutoFarmCoin", {
    Title = "Coin Farm",
    Default = false,
    Callback = function(Value)
        _G.AutoCoinV3 = Value
        if Value then
            local cc = workspace:FindFirstChild("CoinContainer", true)
            if cc then OnNewRound(cc) end
        end
    end
})

-- ==========================================
-- TAB 6: TELEPORT
-- ==========================================
Tabs.Teleport:AddButton({
    Title = "Teleport to Murderer",
    Callback = function()
        local lp = game.Players.LocalPlayer
        if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= lp and GetPlayerRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
                Fluent:Notify({ Title = "Success", Content = "Teleported to Murderer (" .. p.Name .. ")", Duration = 3 })
                return
            end
        end
        Fluent:Notify({ Title = "Error", Content = "Murderer not found or not alive!", Duration = 3 })
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport to Sheriff",
    Callback = function()
        local lp = game.Players.LocalPlayer
        if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= lp and GetPlayerRole(p) == "Sheriff" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
                Fluent:Notify({ Title = "Success", Content = "Teleported to Sheriff (" .. p.Name .. ")", Duration = 3 })
                return
            end
        end
        Fluent:Notify({ Title = "Error", Content = "Sheriff not found or not alive!", Duration = 3 })
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport Lobby",
    Callback = function()
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local lobby = workspace:FindFirstChild("Lobby")
            if lobby then
                local spawn = lobby:FindFirstChild("SpawnLocation", true) or lobby:FindFirstChild("Spawn", true)
                if spawn and spawn:IsA("BasePart") then
                    lp.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
                    return
                end
            end
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(-108, 140, 18)
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport Map",
    Callback = function()
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local map = nil
            for _, v in pairs(workspace:GetDescendants()) do
                if v.Name == "CoinContainer" then
                    map = v.Parent
                    break
                end
            end
            if not map then
                local normal = workspace:FindFirstChild("Normal")
                if normal then map = normal:GetChildren()[1] or normal end
            end
            if not map then
                for _, v in pairs(workspace:GetChildren()) do
                    if v:IsA("Model") and v.Name ~= "Lobby" and v.Name ~= lp.Name then
                        if v:FindFirstChild("Spawn", true) or v:FindFirstChild("Spawns", true) or v:FindFirstChild("SpawnLocation", true) then
                            map = v
                            break
                        end
                    end
                end
            end
            if map then
                local spawns = map:FindFirstChild("Spawns", true) or map:FindFirstChild("Spawn", true)
                if spawns and (spawns:IsA("Folder") or spawns:IsA("Model")) then
                    local spawnParts = spawns:GetChildren()
                    if #spawnParts > 0 then
                        local randomSpawn = spawnParts[math.random(1, #spawnParts)]
                        if randomSpawn and randomSpawn:IsA("BasePart") then
                            lp.Character.HumanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 5, 0)
                            return
                        end
                    end
                end
                local spawnObj = map:FindFirstChild("SpawnLocation", true) or map:FindFirstChild("Spawn", true)
                if spawnObj and spawnObj:IsA("BasePart") then
                    lp.Character.HumanoidRootPart.CFrame = spawnObj.CFrame + Vector3.new(0, 5, 0)
                    return
                end
                for _, v in pairs(map:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide and v.Transparency == 0 and v.Size.X > 15 and v.Size.Z > 15 then
                        lp.Character.HumanoidRootPart.CFrame = v.CFrame + Vector3.new(0, 6, 0)
                        return
                    end
                end
                for _, v in pairs(map:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide and v.Transparency < 1 then
                        lp.Character.HumanoidRootPart.CFrame = v.CFrame + Vector3.new(0, 5, 0)
                        return
                    end
                end
            end
            Fluent:Notify({ Title = "Error", Content = "Map not found! Wait for round to start.", Duration = 3 })
        end
    end
})

-- ==========================================
-- TAB 7: SETTINGS
-- ==========================================
local InterfaceManager = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("MM2Hub")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)

-- ==========================================
-- SYSTEM LOOPS
-- ==========================================

game:GetService("UserInputService").JumpRequest:Connect(function()
    if _G.InfJumpActive then
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

game:GetService("RunService").Stepped:Connect(function()
    if _G.ScriptUnloaded then return end
    local lp = game.Players.LocalPlayer
    if not lp.Character then return end


    if _G.NoclipActive then
        for _, part in pairs(lp.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if _G.WalkSpeedValue and _G.WalkSpeedValue > 16 and lp.Character:FindFirstChild("Humanoid") then
        lp.Character.Humanoid.WalkSpeed = _G.WalkSpeedValue
    end

    if _G.SilentAim then
        -- Silent Aim logic is now handled by the Metatable Hook and Target Selection loop
    end
end)

-- ==========================================
-- SUPER FLY ENGINE (HEARTBEAT)
-- ==========================================
task.spawn(function()
    while true do
        task.wait()
        if _G.ScriptUnloaded then break end

        local lp = game.Players.LocalPlayer
        if _G.FlyActive and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character:FindFirstChild("Humanoid") then
            local hrp = lp.Character.HumanoidRootPart
            local hum = lp.Character.Humanoid
            local cam = workspace.CurrentCamera
            local uis = game:GetService("UserInputService")

            -- Bypass Design
            local bvName = "MM2_Bypass_V"
            local bgName = "MM2_Bypass_G"

            local bv = hrp:FindFirstChild(bvName) or Instance.new("BodyVelocity")
            if not bv.Parent then
                bv.Name = bvName
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Parent = hrp
            end

            local bg = hrp:FindFirstChild(bgName) or Instance.new("BodyGyro")
            if not bg.Parent then
                bg.Name = bgName
                bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.Parent = hrp
            end

            hum.PlatformStand = true

            local moveVector = Vector3.new(0, 0, 0)
            if uis:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector = moveVector - Vector3.new(0, 1, 0) end

            bv.Velocity = moveVector * (_G.FlySpeed or 50)
            bg.CFrame = cam.CFrame
        end
    end
end)

workspace.DescendantAdded:Connect(function(desc)
    if desc.Name == "GunDrop" or desc.Name == "Gun Drop" then
        Fluent:Notify({ Title = "SHERIFF DEAD", Content = "Gun dropped!", Duration = 10 })
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        local lp = game.Players.LocalPlayer
        if not lp then continue end
        if _G.ChamsActiveV3 then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= lp and player.Character then
                    local char = player.Character
                    local highlight = char:FindFirstChild("PlayerChams")
                    if char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                        local role = GetPlayerRole(player)
                        local color = Color3.fromRGB(0, 255, 0)
                        if role == "Murderer" then
                            color = Color3.fromRGB(255, 0, 0)
                        elseif role == "Sheriff" then
                            color = Color3.fromRGB(255, 255, 0)
                        end

                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "PlayerChams"
                            highlight.Parent = char
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        end
                        if highlight.FillColor ~= color then
                            highlight.FillColor = color; highlight.OutlineColor = color
                        end
                        if highlight.FillTransparency ~= 0.5 then
                            highlight.FillTransparency = 0.5; highlight.OutlineTransparency = 0
                        end
                        if not highlight.Enabled then highlight.Enabled = true end
                    elseif highlight and highlight.Enabled then
                        highlight.Enabled = false
                    end
                end
            end
            local gunDrop = workspace:FindFirstChild("GunDrop", true) or workspace:FindFirstChild("Gun Drop", true)
            if gunDrop and (gunDrop:IsA("BasePart") or gunDrop:IsA("Model")) then
                local highlight = gunDrop:FindFirstChild("GunChams")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "GunChams"
                    highlight.Parent = gunDrop
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.FillColor = Color3.fromRGB(0, 0, 255)
                    highlight.OutlineColor = Color3.fromRGB(0, 0, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                end
                if not highlight.Enabled then highlight.Enabled = true end
            end
        end
        if _G.AuraActiveV3 and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            local knife = GetKnifeItem(lp)
            if knife then
                for _, v in pairs(game.Players:GetPlayers()) do
                    if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
                        local dist = (lp.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position)
                            .Magnitude
                        if dist <= _G.AuraRangeV3 then SilentHit(v) end
                    end
                end
            end
        end
    end
end)

local Skeletons = {}
local function DrawLine()
    local success, line = pcall(function() return Drawing.new("Line") end)
    if success and line then
        line.Visible = false
        line.Color = Color3.fromRGB(0, 0, 0)
        line.Thickness = 1
        line.Transparency = 0.6
        return line
    end
    return nil
end

local function DrawCircle()
    local success, circ = pcall(function() return Drawing.new("Circle") end)
    if success and circ then
        circ.Visible = false
        circ.Color = Color3.fromRGB(0, 0, 0)
        circ.Thickness = 1
        circ.Transparency = 1
        circ.Filled = false
        return circ
    end
    return nil
end

local function DrawText()
    local success, txt = pcall(function() return Drawing.new("Text") end)
    if success and txt then
        txt.Visible = false
        txt.Center = true
        txt.Outline = true
        txt.Font = 2
        txt.Size = 13
        txt.Color = Color3.fromRGB(255, 255, 255)
        return txt
    end
    return nil
end

local function DrawSquare()
    local success, sq = pcall(function() return Drawing.new("Square") end)
    if success and sq then
        sq.Visible = false
        sq.Color = Color3.fromRGB(255, 255, 255)
        sq.Thickness = 1
        sq.Transparency = 1
        sq.Filled = false
        return sq
    end
    return nil
end

local skelConnections = {
    { "Head",       "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
    { "Head",       "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" }, { "Torso", "Left Leg" }, { "Torso", "Right Leg" }
}

game:GetService("RunService").RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            if not Skeletons[player] then
                Skeletons[player] = { Lines = {}, Head = DrawCircle(), DistText = DrawText(), Box = DrawSquare() }
                for i = 1, #skelConnections do
                    local l = DrawLine()
                    if l then Skeletons[player].Lines[i] = l end
                end
            end
            local hasChar = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and
                player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
            
            if Skeletons[player] then
                if _G.DistanceESP and hasChar then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local hrpPos, hrpVis = cam:WorldToViewportPoint(hrp.Position)
                        local dist = (cam.CFrame.Position - hrp.Position).Magnitude
                        local distObj = Skeletons[player].DistText
                        if distObj then
                            if hrpVis then
                                distObj.Position = Vector2.new(hrpPos.X, hrpPos.Y)
                                distObj.Text = string.format("[%d m]", math.floor(dist))
                                if dist >= 40 then
                                    distObj.Color = Color3.fromRGB(0, 255, 0)
                                elseif dist <= 20 then
                                    distObj.Color = Color3.fromRGB(255, 0, 0)
                                else
                                    distObj.Color = Color3.fromRGB(255, 255, 0)
                                end
                                distObj.Visible = true
                            else
                                distObj.Visible = false
                            end
                        end
                    end
                else
                    if Skeletons[player].DistText then Skeletons[player].DistText.Visible = false end
                end

                if _G.BoxESP and hasChar then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    local box = Skeletons[player].Box
                    if hrp and box then
                        local top, tvis = cam:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, 3, 0)).Position)
                        local bottom, bvis = cam:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, -3.5, 0)).Position)
                        if tvis or bvis then
                            local height = math.abs(top.Y - bottom.Y)
                            local width = height / 1.8
                            box.Size = Vector2.new(width, height)
                            box.Position = Vector2.new(top.X - width / 2, top.Y)

                            local role = GetPlayerRole(player)
                            local color = Color3.fromRGB(0, 255, 0)
                            if role == "Murderer" then
                                color = Color3.fromRGB(255, 0, 0)
                            elseif role == "Sheriff" then
                                color = Color3.fromRGB(255, 255, 0)
                            end
                            box.Color = color
                            box.Visible = true
                        else
                            box.Visible = false
                        end
                    end
                else
                    if Skeletons[player].Box then Skeletons[player].Box.Visible = false end
                end
                if _G.SkeletonESP and hasChar then
                    for i, conn in ipairs(skelConnections) do
                        local line = Skeletons[player].Lines[i]
                        if line then
                            local p1 = player.Character:FindFirstChild(conn[1])
                            local p2 = player.Character:FindFirstChild(conn[2])
                            if p1 and p2 then
                                local pos1, vis1 = cam:WorldToViewportPoint(p1.Position)
                                local pos2, vis2 = cam:WorldToViewportPoint(p2.Position)
                                if vis1 or vis2 then
                                    line.From = Vector2.new(pos1.X, pos1.Y)
                                    line.To = Vector2.new(pos2.X, pos2.Y)
                                    line.Visible = true
                                else
                                    line.Visible = false
                                end
                            else
                                line.Visible = false
                            end
                        end
                    end
                    local headObj = Skeletons[player].Head
                    local headPart = player.Character:FindFirstChild("Head")
                    if headObj and headPart then
                        local headPos, headVis = cam:WorldToViewportPoint(headPart.Position)
                        if headVis then
                            local t, tv = cam:WorldToViewportPoint((headPart.CFrame * CFrame.new(0, headPart.Size.Y / 2, 0))
                                .Position)
                            local b, bv = cam:WorldToViewportPoint((headPart.CFrame * CFrame.new(0, -headPart.Size.Y / 2, 0))
                                .Position)
                            headObj.Position = Vector2.new(headPos.X, headPos.Y)
                            if tv and bv then
                                headObj.Radius = math.clamp(math.abs(t.Y - b.Y) / 2, 1, 60)
                            else
                                local dist = (cam.CFrame.Position - headPart.Position).Magnitude
                                headObj.Radius = math.clamp(150 / dist, 1, 60)
                            end
                            headObj.Visible = true
                        else
                            headObj.Visible = false
                        end
                    elseif headObj then
                        headObj.Visible = false
                    end
                else
                    for i = 1, #skelConnections do
                        if Skeletons[player].Lines[i] then Skeletons[player].Lines[i].Visible = false end
                    end
                    if Skeletons[player].Head then Skeletons[player].Head.Visible = false end
                end
            end
        end
    end
end)

game.Players.PlayerRemoving:Connect(function(player)
    if Skeletons[player] then
        for _, line in pairs(Skeletons[player].Lines) do
            if line and type(line) == "table" and line.Remove then line:Remove() end
        end
        if Skeletons[player].Head and type(Skeletons[player].Head) == "table" and Skeletons[player].Head.Remove then
            Skeletons[player].Head:Remove()
        end
        if Skeletons[player].DistText and type(Skeletons[player].DistText) == "table" and Skeletons[player].DistText.Remove then
            Skeletons[player].DistText:Remove()
        end
        if Skeletons[player].Box and type(Skeletons[player].Box) == "table" and Skeletons[player].Box.Remove then
            Skeletons[player].Box:Remove()
        end
        Skeletons[player] = nil
    end
end)

-- ==========================================
-- MENU TOGGLE NOTIFIER
-- ==========================================
local UIS = game:GetService("UserInputService")
local wasKeyDown = false
local isMenuOpen = true

game:GetService("RunService").RenderStepped:Connect(function()
    if typeof(Window.MinimizeKey) == "EnumItem" then
        local isDown = UIS:IsKeyDown(Window.MinimizeKey)
        if isDown and not wasKeyDown then
            if not UIS:GetFocusedTextBox() then
                isMenuOpen = not isMenuOpen
                if not isMenuOpen then
                    Fluent:Notify({
                        Title = "Menu Hidden",
                        Content = "Press [" .. Window.MinimizeKey.Name .. "] to reopen the menu.",
                        Duration = 10
                    })
                end
            end
        end
        wasKeyDown = isDown
    end
end)

-- ==========================================
-- REAL SILENT AIM ENGINE
-- ==========================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 100
FOVCircle.Radius = 150
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 0.5

local LastTarget = nil
local function GetClosestMurdererToCursor()
    local cam = workspace.CurrentCamera
    local lp = game.Players.LocalPlayer
    local mousePos = game:GetService("UserInputService"):GetMouseLocation()
    local fov = _G.SilentAimFOV or 150

    -- Sticky Target Logic: Keep targeting the same person if they are still valid and in FOV
    if LastTarget and LastTarget.Parent and LastTarget.Parent:FindFirstChild("Humanoid") and LastTarget.Parent.Humanoid.Health > 0 then
        local pos, vis = cam:WorldToViewportPoint(LastTarget.Position)
        if vis then
            local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
            if dist < fov then
                return LastTarget
            end
        end
    end

    local target = nil
    local shortestDistance = fov

    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= lp and GetPlayerRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            
            local hitPart = nil
            if _G.TargetPart == "Random" then
                local possible = {"Head", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"}
                local available = {}
                for _, name in pairs(possible) do
                    local prt = p.Character:FindFirstChild(name)
                    if prt then table.insert(available, prt) end
                end
                if #available > 0 then hitPart = available[math.random(1, #available)] end
            else
                hitPart = p.Character:FindFirstChild(_G.TargetPart)
                if not hitPart then
                    -- Fallback for R6/R15 differences
                    if _G.TargetPart == "Head" then hitPart = p.Character:FindFirstChild("Head")
                    elseif _G.TargetPart == "UpperTorso" then hitPart = p.Character:FindFirstChild("Torso") or p.Character:FindFirstChild("HumanoidRootPart")
                    end
                end
            end

            if hitPart then
                local pos, vis = cam:WorldToViewportPoint(hitPart.Position)
                if vis then
                    local mousePos = game:GetService("UserInputService"):GetMouseLocation()
                    local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    
                    if distance < shortestDistance then
                        -- Wall Check
                        if _G.WallCheck then
                            local params = RaycastParams.new()
                            params.FilterDescendantsInstances = { cam, lp.Character, p.Character }
                            params.FilterType = Enum.RaycastFilterType.Exclude
                            local rayResult = workspace:Raycast(cam.CFrame.Position, hitPart.Position - cam.CFrame.Position, params)
                            if rayResult then 
                                -- If we hit something that isn't transparent/non-collidable, it's a wall
                                if rayResult.Instance.CanCollide and rayResult.Instance.Transparency < 1 then
                                    continue 
                                end
                            end 
                        end
                        
                        target = hitPart
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    LastTarget = target
    return target
end

local CurrentTarget = nil
game:GetService("RunService").RenderStepped:Connect(function()
    if _G.ScriptUnloaded then return end
    local UIS = game:GetService("UserInputService")
    FOVCircle.Position = UIS:GetMouseLocation()
    FOVCircle.Radius = _G.SilentAimFOV or 150
    FOVCircle.Visible = _G.ShowFOV and _G.SilentAim

    if _G.SilentAim then
        CurrentTarget = GetClosestMurdererToCursor()
        
        -- Silent Rotation (Snap character to target without moving camera)
        if CurrentTarget then
            local lp = game.Players.LocalPlayer
            local char = lp.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local hrp = char.HumanoidRootPart
                -- Only rotate if not dead and target is valid
                local tPos = CurrentTarget.Position
                local lookPos = Vector3.new(tPos.X, hrp.Position.Y, tPos.Z)
                hrp.CFrame = CFrame.new(hrp.Position, lookPos)
            end
        end
    else
        CurrentTarget = nil
        LastTarget = nil
    end
end)

local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__index = newcclosure(function(t, k)
    if not checkcaller() and _G.SilentAim and CurrentTarget then
        if t:IsA("Mouse") and (k == "Hit" or k == "Target") then
            if k == "Hit" then
                return CurrentTarget.CFrame
            else
                return CurrentTarget
            end
        end
    end
    return oldIndex(t, k)
end)

mt.__namecall = newcclosure(function(t, ...)
    local args = { ... }
    local method = getnamecallmethod()

    if not checkcaller() and _G.SilentAim and CurrentTarget then
        if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
            args[1] = Ray.new(workspace.CurrentCamera.CFrame.Position, (CurrentTarget.Position - workspace.CurrentCamera.CFrame.Position).Unit * 1000)
            return oldNamecall(t, unpack(args))
        elseif method == "Raycast" or method == "raycast" then
            -- args[1] is origin, args[2] is direction
            args[2] = (CurrentTarget.Position - args[1]).Unit * 1000
            return oldNamecall(t, unpack(args))
        end
    end
    return oldNamecall(t, ...)
end)

setreadonly(mt, true)


Fluent:Notify({
    Title = "MM2 Hub Loaded!",
    Content = "Welcome to the custom interface. Watermark added to top-right.",
    Duration = 10
})
