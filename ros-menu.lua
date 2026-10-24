-- ROS Reborn Cheat Panel — Luau / Roblox Executor
-- Load with: loadstring(game:HttpGet("YOUR_URL_HERE"))()

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ====== CONFIG ======
local Config = {
    ESPEnabled = false,
    AimbotEnabled = false,
    FlyEnabled = false,
    SpeedEnabled = false,
    KillAuraEnabled = false,
    FlySpeed = 50,
    WalkSpeed = 16,
    AimFOV = 120,
    KillAuraRange = 15,
}

-- ====== ESP ======
local espCache = {}
local function createESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 1
    box.Filled = false

    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true

    espCache[player] = {Box = box, Name = nameTag}
end

local function updateESP()
    for player, drawings in pairs(espCache) do
        if not Config.ESPEnabled or not player.Character then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            continue
        end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
        if not onScreen then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            continue
        end

        local size = (workspace.CurrentCamera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))).Y - screenPos.Y
        drawings.Box.Size = Vector2.new(size * 0.6, size)
        drawings.Box.Position = Vector2.new(screenPos.X - drawings.Box.Size.X / 2, screenPos.Y - drawings.Box.Size.Y / 2)
        drawings.Box.Visible = true

        drawings.Name.Text = player.Name .. " [" .. math.floor(player:GetDistanceFromCharacter(root.Position)) .. "m]"
        drawings.Name.Position = Vector2.new(screenPos.X, screenPos.Y - drawings.Box.Size.Y / 2 - 18)
        drawings.Name.Visible = true
    end
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    if espCache[p] then
        espCache[p].Box:Remove()
        espCache[p].Name:Remove()
        espCache[p] = nil
    end
end)
for _, p in ipairs(Players:GetPlayers()) do createESP(p) end

-- ====== AIMBOT ======
local function getClosestPlayerInFOV()
    local closest = nil
    local shortest = Config.AimFOV
    local camera = workspace.CurrentCamera
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        local part = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < shortest then
            shortest = dist
            closest = part
        end
    end
    return closest
end

local function runAimbot()
    if not Config.AimbotEnabled then return end
    local target = getClosestPlayerInFOV()
    if not target then return end
    workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, target.Position)
end

-- ====== FLY ======
local flyBodyVelocity, flyBodyGyro
local function toggleFly(state)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if state then
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBodyVelocity.Velocity = Vector3.zero
        flyBodyVelocity.Parent = root

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBodyGyro.CFrame = root.CFrame
        flyBodyGyro.Parent = root
    else
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        if flyBodyGyro then flyBodyGyro:Destroy() end
    end
end

local function updateFly()
    if not Config.FlyEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local moveDir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += workspace.CurrentCamera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= workspace.CurrentCamera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= workspace.CurrentCamera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += workspace.CurrentCamera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end

    if flyBodyVelocity then
        flyBodyVelocity.Velocity = moveDir * Config.FlySpeed
    end
    if flyBodyGyro then
        flyBodyGyro.CFrame = workspace.CurrentCamera.CFrame
    end
end

-- ====== SPEED ======
local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = Config.SpeedEnabled and Config.WalkSpeed or 16
    end
end

-- ====== KILL AURA ======
local function runKillAura()
    if not Config.KillAuraEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
        local targetHum = player.Character:FindFirstChild("Humanoid")
        if targetRoot and targetHum and (root.Position - targetRoot.Position).Magnitude <= Config.KillAuraRange then
            -- replace with your game's damage remote
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
        end
    end
end

-- ====== MAIN LOOP ======
RunService.RenderStepped:Connect(function()
    updateESP()
    runAimbot()
    updateFly()
    runKillAura()
end)

RunService.Heartbeat:Connect(function()
    applySpeed()
end)

-- ====== UI ======
local Window = Fluent:CreateWindow({
    Title = "ROS Reborn Cheat Panel",
    SubTitle = "made by Aoid",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 400),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.Insert
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "shield" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Tabs.Main:AddToggle("FlyToggle", {
    Title = "Fly",
    Default = false,
    Callback = function(v) Config.FlyEnabled = v; toggleFly(v) end
})

Tabs.Main:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(v) Config.FlySpeed = v end
})

Tabs.Main:AddToggle("SpeedToggle", {
    Title = "Speed Hack",
    Default = false,
    Callback = function(v) Config.SpeedEnabled = v end
})

Tabs.Main:AddSlider("WalkSpeed", {
    Title = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 0,
    Callback = function(v) Config.WalkSpeed = v end
})

Tabs.Main:AddToggle("KillAuraToggle", {
    Title = "Kill Aura",
    Default = false,
    Callback = function(v) Config.KillAuraEnabled = v end
})

Tabs.Main:AddSlider("KillAuraRange", {
    Title = "Kill Aura Range",
    Default = 15,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Callback = function(v) Config.KillAuraRange = v end
})

Tabs.Visuals:AddToggle("ESPToggle", {
    Title = "ESP",
    Default = false,
    Callback = function(v) Config.ESPEnabled = v end
})

Tabs.Visuals:AddToggle("AimbotToggle", {
    Title = "Aimbot",
    Default = false,
    Callback = function(v) Config.AimbotEnabled = v end
})

Tabs.Visuals:AddSlider("AimFOV", {
    Title = "Aimbot FOV",
    Default = 120,
    Min = 20,
    Max = 500,
    Rounding = 0,
    Callback = function(v) Config.AimFOV = v end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("ROSRebornCheat")
SaveManager:SetFolder("ROSRebornCheat/Configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)