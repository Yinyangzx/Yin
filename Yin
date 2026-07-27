--[[
    ═══════════════════════════════════════════════════════════════════════════
    EVADE V7 BETA - FRONTAL JUMP + BETA NEW RAINBOW
    ═══════════════════════════════════════════════════════════════════════════
]]

print("\n" .. string.rep("=", 80))
print("EVADE v5.2 BETA - FRONTAL JUMP + BETA NEW")
print(string.rep("=", 80))

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

if not LocalPlayer then
    error("ERROR: No local player available")
    return
end

print("\nSERVICES: Initialized successfully")

--// ═════════════════════════════════════════════════════════════════════════════
--// MAIN CONFIGURATION
--// ═════════════════════════════════════════════════════════════════════════════

local Config = {
    --// BASIC MOVEMENT
    TeleportMovementSpeed = 5,
    EnableTeleportWalk = false,
    JumpHeight = 50,
    EnableEnhancedJump = false,
    AutoJump = false,
    
    --// GRAVITY MODIFICATION
    EnableGravityMod = false,
    GravityScale = 0.5,
    
    --// FRONTAL JUMP
    EnableFrontalJump = false,
}

--// Frontal Jump Variables
local camera = Workspace.CurrentCamera
getgenv().FrontalJumpSpeed = 42
getgenv().RampMultiplier = 1.55
local maxExtraSpeed = 80
local currentSpeed = getgenv().FrontalJumpSpeed
local airAccumulator = 0
local lastTick = tick()
local wasAir = false
local activeBV = nil
local lastJumpTime = tick()
local jumpInterval = 0.65

--// Variables to save options state
local savedOptions = {
    EnableTeleportWalk = false,
    EnableEnhancedJump = false,
    EnableGravityMod = false,
}

--// ═════════════════════════════════════════════════════════════════════════════
--// SETTINGS SAVE/LOAD SYSTEM
--// ═════════════════════════════════════════════════════════════════════════════

local HttpService = game:GetService("HttpService")
local SettingsFile = "EVADE_V52_Settings.json"

local function SaveSettings()
    pcall(function()
        local data = {
            EnableTeleportWalk = Config.EnableTeleportWalk,
            TeleportMovementSpeed = Config.TeleportMovementSpeed,
            EnableEnhancedJump = Config.EnableEnhancedJump,
            JumpHeight = Config.JumpHeight,
            AutoJump = Config.AutoJump,
            EnableGravityMod = Config.EnableGravityMod,
            GravityScale = Config.GravityScale,
            EnableFrontalJump = Config.EnableFrontalJump,
            FrontalJumpSpeed = getgenv().FrontalJumpSpeed,
            RampMultiplier = getgenv().RampMultiplier,
        }
        writefile(SettingsFile, HttpService:JSONEncode(data))
    end)
end

local function LoadSettings()
    local ok, result = pcall(function()
        if isfile and isfile(SettingsFile) then
            local content = readfile(SettingsFile)
            if content and content ~= "" then
                return HttpService:JSONDecode(content)
            end
        end
        return nil
    end)

    if ok and result then
        if result.EnableTeleportWalk ~= nil then Config.EnableTeleportWalk = result.EnableTeleportWalk end
        if result.TeleportMovementSpeed ~= nil then Config.TeleportMovementSpeed = result.TeleportMovementSpeed end
        if result.EnableEnhancedJump ~= nil then Config.EnableEnhancedJump = result.EnableEnhancedJump end
        if result.JumpHeight ~= nil then Config.JumpHeight = result.JumpHeight end
        if result.AutoJump ~= nil then Config.AutoJump = result.AutoJump end
        if result.EnableGravityMod ~= nil then Config.EnableGravityMod = result.EnableGravityMod end
        if result.GravityScale ~= nil then Config.GravityScale = result.GravityScale end
        if result.EnableFrontalJump ~= nil then Config.EnableFrontalJump = result.EnableFrontalJump end
        if result.FrontalJumpSpeed ~= nil then getgenv().FrontalJumpSpeed = result.FrontalJumpSpeed end
        if result.RampMultiplier ~= nil then getgenv().RampMultiplier = result.RampMultiplier end
        print("SETTINGS: Previous configuration loaded successfully")
    else
        print("SETTINGS: No saved configuration found, using defaults")
    end
end

LoadSettings()

--// Resync currentSpeed with the loaded FrontalJumpSpeed value
currentSpeed = getgenv().FrontalJumpSpeed

print("CONFIGURATION: Initialized")

--// ═════════════════════════════════════════════════════════════════════════════
--// LOAD YIN YANG v28 FINAL
--// ═════════════════════════════════════════════════════════════════════════════

print("\nLoading Yin Yang v28 Final from GitHub...")

local success = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Yinyangzx/Yin/refs/heads/main/Yin"))()
end)

if not success or not _G.YinYang then
    error("ERROR: Failed to load Yin Yang v28 Final")
    return
end

print("LIBRARY: Yin Yang v28 Final loaded successfully")
task.wait(0.5)

print("SYSTEM: Initialization completed")

--// ═════════════════════════════════════════════════════════════════════════════
--// CREATE UI
--// ═════════════════════════════════════════════════════════════════════════════

print("\nCreating EVADE v5.2 Beta interface...")

--// Read the theme saved by the Yin Yang library itself (Yin_Yang_Config.txt)
--// The library saves the theme correctly on change, but its own CreateWindow
--// never re-applies it on load - so we read the same file here and pass it in.
local function GetSavedTheme()
    local theme = "Dark"
    pcall(function()
        if isfile and isfile("Yin_Yang_Config.txt") then
            local content = readfile("Yin_Yang_Config.txt")
            if content and content ~= "" then
                local value = content:match("theme:([^|]+)")
                if value then
                    theme = value
                end
            end
        end
    end)
    return theme
end

local UI = _G.YinYang:CreateWindow("EVADE v7 BETA", GetSavedTheme())

--// ═════════════════════════════════════════════════════════════════════════════
--// INVERSE RAINBOW EFFECT FOR TITLE
--// ═════════════════════════════════════════════════════════════════════════════

local function setupRainbowInversedTitle()
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    task.wait(0.8)
    
    if PlayerGui:FindFirstChild("Yin") then
        local ScreenGui = PlayerGui.Yin
        local TitleLabel = ScreenGui:FindFirstChild("TitleLabel")
        
        if TitleLabel then
            print("Creating inverse rainbow effect with two TextLabels...")
            
            --// Get position and size of the original title
            local origText = TitleLabel.Text
            local origSize = TitleLabel.Size
            local origPos = TitleLabel.Position
            local origFont = TitleLabel.Font
            local origTextSize = TitleLabel.TextSize
            
            --// Make original title invisible
            TitleLabel.TextTransparency = 1
            
            --// Create TextLabel for "EVADE" (White → Black)
            local EvadeLabel = Instance.new("TextLabel")
            EvadeLabel.Name = "EvadeLabel"
            EvadeLabel.Text = "EVADE"
            EvadeLabel.Font = origFont
            EvadeLabel.TextSize = origTextSize
            EvadeLabel.BackgroundTransparency = 1
            EvadeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            EvadeLabel.Size = UDim2.new(0.6, 0, 1, 0)
            EvadeLabel.Position = UDim2.new(0, 0, 0, 0)
            EvadeLabel.TextXAlignment = Enum.TextXAlignment.Left
            EvadeLabel.ZIndex = TitleLabel.ZIndex + 1
            EvadeLabel.Parent = TitleLabel.Parent
            
            --// Create TextLabel for "Beta" (Black → White)
            local BetaLabel = Instance.new("TextLabel")
            BetaLabel.Name = "BetaLabel"
            BetaLabel.Text = "v5.2 Beta"
            BetaLabel.Font = origFont
            BetaLabel.TextSize = origTextSize
            BetaLabel.BackgroundTransparency = 1
            BetaLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            BetaLabel.Size = UDim2.new(0.4, 0, 1, 0)
            BetaLabel.Position = UDim2.new(0.6, 0, 0, 0)
            BetaLabel.TextXAlignment = Enum.TextXAlignment.Left
            BetaLabel.ZIndex = TitleLabel.ZIndex + 1
            BetaLabel.Parent = TitleLabel.Parent
            
            print("✅ Labels created: EvadeLabel + BetaLabel")
            
            --// Animate INVERSE colors
            local cycleCount = 0
            local rainbow = RunService.RenderStepped:Connect(function()
                if not EvadeLabel or not EvadeLabel.Parent or not BetaLabel or not BetaLabel.Parent then
                    rainbow:Disconnect()
                    return
                end
                
                cycleCount = cycleCount + 1
                local progress = (cycleCount % 120) / 120
                
                if progress < 0.5 then
                    local t = progress * 2
                    
                    local evadeBrightness = 1 - t
                    EvadeLabel.TextColor3 = Color3.fromRGB(
                        math.floor(255 * evadeBrightness),
                        math.floor(255 * evadeBrightness),
                        math.floor(255 * evadeBrightness)
                    )
                    
                    local betaBrightness = t
                    BetaLabel.TextColor3 = Color3.fromRGB(
                        math.floor(255 * betaBrightness),
                        math.floor(255 * betaBrightness),
                        math.floor(255 * betaBrightness)
                    )
                else
                    local t = (progress - 0.5) * 2
                    
                    local evadeBrightness = t
                    EvadeLabel.TextColor3 = Color3.fromRGB(
                        math.floor(255 * evadeBrightness),
                        math.floor(255 * evadeBrightness),
                        math.floor(255 * evadeBrightness)
                    )
                    
                    local betaBrightness = 1 - t
                    BetaLabel.TextColor3 = Color3.fromRGB(
                        math.floor(255 * betaBrightness),
                        math.floor(255 * betaBrightness),
                        math.floor(255 * betaBrightness)
                    )
                end
            end)
            
            print("✅ Inverse rainbow effect activated")
        end
    end
end

task.delay(1, setupRainbowInversedTitle)

--// ════════════════════════════════════════════════════════════════════════════
--// CREATE TABS
--// ════════════════════════════════════════════════════════════════════════════

local TabMovement = UI:CreateTab("Movement", "rbxassetid://102227126804065")
local TabCreditos = UI:CreateTab("Credits", "rbxassetid://92077096693208")

print("TABS: Created (Movement + Credits)")

--// ═════════════════════════════════════════════════════════════════════════════
--// TAB: MOVEMENT
--// ═════════════════════════════════════════════════════════════════════════════

print("\nConfiguring Movement tab...")

TabMovement:CreateLabel("BASIC MOVEMENT", 14)
TabMovement:CreateDivider()

TabMovement:CreateFloatingToggle("Teleport Walk", Config.EnableTeleportWalk, function(state)
    Config.EnableTeleportWalk = state
    print(state and "✅ Teleport Walk ENABLED" or "❌ Teleport Walk DISABLED")
    SaveSettings()
end)

TabMovement:CreateSlider(
    "Teleport Speed",
    1, 50, Config.TeleportMovementSpeed,
    function(value)
        Config.TeleportMovementSpeed = value
        print("✓ Teleport speed: " .. value)
        SaveSettings()
    end
)

TabMovement:CreateDivider()

TabMovement:CreateFloatingToggle("Enhanced Jump", Config.EnableEnhancedJump, function(state)
    Config.EnableEnhancedJump = state
    print(state and "✅ Enhanced Jump ENABLED" or "❌ Enhanced Jump DISABLED")
    SaveSettings()
end)

TabMovement:CreateSlider(
    "Jump Height",
    20, 300, Config.JumpHeight,
    function(value)
        Config.JumpHeight = value
        print("✓ Jump height: " .. value)
        SaveSettings()
    end
)

TabMovement:CreateDivider()

TabMovement:CreateFloatingToggle("Auto Jump", Config.AutoJump, function(state)
    Config.AutoJump = state
    print(state and "✅ Auto Jump ENABLED" or "❌ Auto Jump DISABLED")
    SaveSettings()
end)

TabMovement:CreateDivider()

--// FRONTAL JUMP WITH BETA NEW RAINBOW
TabMovement:CreateLabel("FRONTAL JUMP", 14)
TabMovement:CreateDivider()

TabMovement:CreateFloatingToggle("Frontal Jump", Config.EnableFrontalJump, function(state)
    Config.EnableFrontalJump = state
    if state then
        --// SAVE CURRENT OPTIONS STATE
        savedOptions.EnableTeleportWalk = Config.EnableTeleportWalk
        savedOptions.EnableEnhancedJump = Config.EnableEnhancedJump
        savedOptions.EnableGravityMod = Config.EnableGravityMod
        
        --// DISABLE CONFLICTING OPTIONS
        Config.EnableTeleportWalk = false
        Config.EnableEnhancedJump = false
        Config.EnableGravityMod = false
        
        --// INITIALIZE FRONTAL JUMP
        lastJumpTime = tick()
        currentSpeed = getgenv().FrontalJumpSpeed
        airAccumulator = 0
        
        print("✅ Frontal Jump ENABLED - Beta")
        print("   - Teleport Walk disabled")
        print("   - Enhanced Jump disabled")
        print("   - Gravity Mod disabled")
    else
        --// RESTORE SAVED OPTIONS
        Config.EnableTeleportWalk = savedOptions.EnableTeleportWalk
        Config.EnableEnhancedJump = savedOptions.EnableEnhancedJump
        Config.EnableGravityMod = savedOptions.EnableGravityMod
        
        if activeBV then activeBV:Destroy() end
        activeBV = nil
        currentSpeed = getgenv().FrontalJumpSpeed
        
        print("❌ Frontal Jump DISABLED")
        print("   - Options restored")
    end
    SaveSettings()
end)

TabMovement:CreateSlider(
    "Movement Speed",
    50, 110, getgenv().FrontalJumpSpeed,
    function(value)
        getgenv().FrontalJumpSpeed = value
        currentSpeed = value
        print("✓ Frontal Jump Speed: " .. value)
        SaveSettings()
    end
)

TabMovement:CreateSlider(
    "Ramp Multiplier",
    1.0, 5.0, getgenv().RampMultiplier,
    function(value)
        getgenv().RampMultiplier = value
        print("✓ Ramp Multiplier: " .. value)
        SaveSettings()
    end
)

TabMovement:CreateDivider()
TabMovement:CreateLabel("GRAVITY MODIFICATION", 14)
TabMovement:CreateDivider()

TabMovement:CreateFloatingToggle("Gravity Mod Enabled", Config.EnableGravityMod, function(state)
    Config.EnableGravityMod = state
    print(state and "✅ Gravity Mod ENABLED" or "❌ Gravity Mod DISABLED")
    SaveSettings()
end)

TabMovement:CreateSlider(
    "Gravity Scale",
    0.1, 2, Config.GravityScale,
    function(value)
        Config.GravityScale = value
        print("✓ Gravity Scale: " .. value)
        SaveSettings()
    end
)

print("✅ MOVEMENT: Tab completed")

--// CREATE YELLOW-BLACK RAINBOW EFFECT FOR "Beta New"
local function setupBetaNewRainbow()
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    task.wait(1.2)
    
    if PlayerGui:FindFirstChild("Yin") then
        local ScreenGui = PlayerGui.Yin
        
        --// Find the "Frontal Jump" toggle in TabMovement
        for _, child in pairs(ScreenGui:GetDescendants()) do
            if child:IsA("TextLabel") and child.Text:find("Frontal Jump") then
                local parentFrame = child.Parent
                
                if parentFrame then
                    --// Create label for "Beta" with rainbow
                    local BetaNewLabel = Instance.new("TextLabel")
                    BetaNewLabel.Name = "BetaLabel"
                    BetaNewLabel.Text = "Beta"
                    BetaNewLabel.Font = Enum.Font.GothamBold
                    BetaNewLabel.TextSize = 12
                    BetaNewLabel.BackgroundTransparency = 1
                    BetaNewLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                    BetaNewLabel.Size = UDim2.new(0.25, 0, 1, 0)
                    BetaNewLabel.Position = UDim2.new(0.7, 0, 0, 0)
                    BetaNewLabel.TextXAlignment = Enum.TextXAlignment.Right
                    BetaNewLabel.ZIndex = child.ZIndex + 2
                    BetaNewLabel.Parent = parentFrame
                    
                    print("✨ Creating Yellow-Black rainbow effect for Beta...")
                    
                    --// Animate Yellow ↔ Black colors
                    local cycleCount = 0
                    local rainbowBetaNew = RunService.RenderStepped:Connect(function()
                        if not BetaNewLabel or not BetaNewLabel.Parent then
                            rainbowBetaNew:Disconnect()
                            return
                        end
                        
                        cycleCount = cycleCount + 1
                        local progress = (cycleCount % 120) / 120
                        
                        if progress < 0.5 then
                            --// Yellow (255, 255, 0) → Black (0, 0, 0)
                            local t = progress * 2
                            local brightness = 1 - t
                            
                            BetaNewLabel.TextColor3 = Color3.fromRGB(
                                math.floor(255 * brightness),
                                math.floor(255 * brightness),
                                0
                            )
                        else
                            --// Black (0, 0, 0) → Yellow (255, 255, 0)
                            local t = (progress - 0.5) * 2
                            local brightness = t
                            
                            BetaNewLabel.TextColor3 = Color3.fromRGB(
                                math.floor(255 * brightness),
                                math.floor(255 * brightness),
                                0
                            )
                        end
                    end)
                    
                    print("✅ Yellow-Black rainbow effect activated for Beta")
                    return
                end
            end
        end
    end
end

task.delay(1.5, setupBetaNewRainbow)

--// ═════════════════════════════════════════════════════════════════════════════
--// TAB: CREDITS
--// ═════════════════════════════════════════════════════════════════════════════

print("\nConfiguring Credits tab...")

TabCreditos:CreateLabel("EVADE v5.2 Beta", 14)
TabCreditos:CreateDivider()
TabCreditos:CreateLabel("Developed by: MOFUZII", 12)
TabCreditos:CreateLabel("Framework: Yin Yang v27 Final", 11)
TabCreditos:CreateLabel("Status: Fully Functional ✅", 11)
TabCreditos:CreateDivider()
TabCreditos:CreateLabel("Features:", 12)
TabCreditos:CreateLabel("✓ Teleport Walk (Floating)", 11)
TabCreditos:CreateLabel("✓ Enhanced Jump (Floating)", 11)
TabCreditos:CreateLabel("✓ Auto Jump (Floating)", 11)
TabCreditos:CreateLabel("✓ Frontal Jump (Floating) NEW", 11)
TabCreditos:CreateLabel("✓ Gravity Modification (Floating)", 11)
TabCreditos:CreateDivider()
TabCreditos:CreateLabel("SPECIAL EFFECT:", 12)
TabCreditos:CreateLabel("Inverse Rainbow Title", 11)
TabCreditos:CreateLabel("Beta New (Yellow ↔ Black)", 11)

print("✅ CREDITS: Tab completed")

print("\n✅ OK: INTERFACE FULLY CONFIGURED")

--// ═════════════════════════════════════════════════════════════════════════════
--// MOVEMENT FUNCTIONS
--// ═════════════════════════════════════════════════════════════════════════════

print("\nLoading movement functions...")

local function applyTeleportWalk()
    if not Config.EnableTeleportWalk then return end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    
    if hum.MoveDirection.Magnitude > 0 then
        pcall(function()
            char:TranslateBy(hum.MoveDirection * Config.TeleportMovementSpeed * 0.1)
        end)
    end
end

local function applyEnhancedJump()
    if not Config.EnableEnhancedJump then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    
    local hum = char.Humanoid
    if hum.Health <= 0 then return end
    
    if hum:GetState() ~= Enum.HumanoidStateType.Jumping then
        pcall(function()
            hum.JumpPower = Config.JumpHeight
            hum.UseJumpPower = true
        end)
    end
end

local function applyAutoJump()
    if not Config.AutoJump then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    
    if hum:GetState() == Enum.HumanoidStateType.Running then
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end

local function applyGravityModification()
    if not Config.EnableGravityMod then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hum = char.Humanoid
    local rootPart = char.HumanoidRootPart
    
    if hum.Health <= 0 then return end
    
    pcall(function()
        local velocity = rootPart.AssemblyLinearVelocity
        
        if velocity.Y < 0 then
            rootPart.AssemblyLinearVelocity = Vector3.new(
                velocity.X,
                velocity.Y * Config.GravityScale,
                velocity.Z
            )
        end
    end)
end

--// FRONTAL JUMP FUNCTION
local function ActivateFrontalJump()
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        
        if root and humanoid then
            local humanoidState = humanoid:GetState()
            local isOnGround = (humanoidState == Enum.HumanoidStateType.Landed or humanoidState == Enum.HumanoidStateType.Running)
            
            if isOnGround then
                --// Detect if there's a structure ahead to apply vertical impulse
                local lookDir = camera.CFrame.LookVector
                lookDir = Vector3.new(lookDir.X, 0, lookDir.Z)
                if lookDir.Magnitude ~= 0 then
                    lookDir = lookDir.Unit
                end
                
                local rayOriginFront = root.Position
                local rayDirectionFront = lookDir * 10
                local raycastParamsFront = RaycastParams.new()
                raycastParamsFront.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParamsFront.FilterDescendantsInstances = {char}
                
                local raycastResultFront = Workspace:Raycast(rayOriginFront, rayDirectionFront, raycastParamsFront)
                
                if raycastResultFront then
                    --// Structure ahead - make jump more powerful
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    
                    --// Apply vertical impulse after a small delay
                    task.delay(0.1, function()
                        if char and root then
                            local jumpBoost = getgenv().FrontalJumpSpeed * getgenv().RampMultiplier * 0.8
                            pcall(function()
                                root.AssemblyLinearVelocity = Vector3.new(
                                    root.AssemblyLinearVelocity.X,
                                    jumpBoost,
                                    root.AssemblyLinearVelocity.Z
                                )
                            end)
                        end
                    end)
                else
                    --// No structure, normal jump
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                
                lastJumpTime = tick()
            end
        end
    end
end

local function applyFrontalJump()
    if not Config.EnableFrontalJump then return end
    
    local deltaTime = tick() - lastTick
    lastTick = tick()
    
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        
        if root and humanoid then
            local isAir = humanoid.FloorMaterial == Enum.Material.Air
            local humanoidState = humanoid:GetState()
            local isOnGround = (humanoidState == Enum.HumanoidStateType.Landed or humanoidState == Enum.HumanoidStateType.Running) and not isAir
            
            local hitObject = false
            if wasAir and isOnGround then
                hitObject = true
                currentSpeed = getgenv().FrontalJumpSpeed
                airAccumulator = 0
            end
            wasAir = isAir
            
            if isAir then
                if activeBV then activeBV:Destroy() end
                
                local lookDir = camera.CFrame.LookVector
                lookDir = Vector3.new(lookDir.X, 0, lookDir.Z)
                
                if lookDir.Magnitude ~= 0 then
                    lookDir = lookDir.Unit
                end
                
                --// Detect frontal impact with structures WHILE in the air
                local rayOriginFront = root.Position
                local rayDirectionFront = lookDir * 10
                local raycastParamsFront = RaycastParams.new()
                raycastParamsFront.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParamsFront.FilterDescendantsInstances = {char}
                
                local raycastResultFront = Workspace:Raycast(rayOriginFront, rayDirectionFront, raycastParamsFront)
                
                if raycastResultFront then
                    --// There's a structure ahead WHILE IN AIR
                    local impactForce = currentSpeed * getgenv().RampMultiplier
                    
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = Vector3.new(
                        lookDir.X * impactForce,
                        impactForce * 1.2,  --// Vertical impulse too
                        lookDir.Z * impactForce
                    )
                    bv.MaxForce = Vector3.new(4e5, 4e5, 4e5)
                    bv.P = 1250
                    bv.Parent = root
                    
                    Debris:AddItem(bv, 0.1)
                    activeBV = bv
                else
                    --// No structure, normal impulse
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = lookDir * currentSpeed
                    bv.MaxForce = Vector3.new(4e5, 0, 4e5)
                    bv.P = 1250
                    bv.Parent = root
                    
                    Debris:AddItem(bv, 0.1)
                    activeBV = bv
                end
            else
                --// On ground: Apply impulse AND accelerate to gain power
                airAccumulator = airAccumulator + deltaTime
                while airAccumulator >= 0.04 do
                    airAccumulator = airAccumulator - 0.04
                    --// Accelerate slowly but CAPPED at base speed
                    currentSpeed = math.min(getgenv().FrontalJumpSpeed + 10, currentSpeed + 0.3)
                end
                
                if activeBV then activeBV:Destroy() end
                
                local lookDir = camera.CFrame.LookVector
                lookDir = Vector3.new(lookDir.X, 0, lookDir.Z)
                
                if lookDir.Magnitude ~= 0 then
                    lookDir = lookDir.Unit
                end
                
                --// FRONTAL RAYCAST - Detect ANY structure ahead
                local rayOrigin = root.Position
                local rayDirection = Vector3.new(0, -5, 0)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.FilterDescendantsInstances = {char}
                
                local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                
                --// FRONTAL RAYCAST - Detect structures ahead (cars, ramps, etc)
                local rayOriginFront = root.Position
                local rayDirectionFront = lookDir * 8
                local raycastParamsFront = RaycastParams.new()
                raycastParamsFront.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParamsFront.FilterDescendantsInstances = {char}
                
                local raycastResultFront = Workspace:Raycast(rayOriginFront, rayDirectionFront, raycastParamsFront)
                
                local impulsePower = currentSpeed
                local hasStructureAhead = false
                
                --// If there's structure ahead, use multiplier
                if raycastResultFront then
                    hasStructureAhead = true
                    impulsePower = currentSpeed * getgenv().RampMultiplier
                end
                
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = lookDir * impulsePower
                bv.MaxForce = Vector3.new(4e5, 0, 4e5)
                bv.P = 1250
                bv.Parent = root
                
                Debris:AddItem(bv, 0.1)
                activeBV = bv
                
                currentSpeed = math.max(getgenv().FrontalJumpSpeed, currentSpeed - 2.5 * deltaTime)
                
                if tick() - lastJumpTime >= jumpInterval then
                    ActivateFrontalJump()
                end
            end
        end
    end
end

print("✅ MOVEMENT: Functions loaded successfully")

--// ═════════════════════════════════════════════════════════════════════════════
--// MAIN LOOP
--// ═════════════════════════════════════════════════════════════════════════════

print("\nActivating main loop...")

local connection = RunService.Heartbeat:Connect(function()
    pcall(function()
        applyTeleportWalk()
        applyEnhancedJump()
        applyAutoJump()
        applyGravityModification()
        applyFrontalJump()
    end)
end)

print("✅ LOOP: Main loop started")

print("\n" .. string.rep("=", 80))
print("OK: EVADE v5.2 BETA - FULLY FUNCTIONAL")
print(string.rep("=", 80))

print("\nSUMMARY:")
print("   ✅ Yin Yang v27 Final library loaded")
print("   ✅ UI with 2 tabs (Movement + Credits)")
print("   ✅ FloatingToggle on all options")
print("   ✅ Frontal Jump ADDED to Movement")
print("   ✅ Beta with Yellow-Black rainbow")
print("   ✅ Movement functions COMPLETE")

print("\nHOW TO USE:")
print("   1. Go to the MOVEMENT tab")
print("   2. Enable 'Frontal Jump' (you'll see 'Beta' in yellow-black)")
print("   3. The rainbow effect stays when changing theme")
print("   4. FloatingToggles can be moved freely")

print("\n" .. string.rep("=", 80) .. "\n")

return UI
