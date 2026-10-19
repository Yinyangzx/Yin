-- HYDRA - Evade (usa la libreria de forma externa)
-- La libreria (Hydra_Lib.lua) se carga desde GitHub
local HYDRA_URL = "https://raw.githubusercontent.com/ZINZEROX/Ni/refs/heads/main/UIV2"

local Hydra = loadstring(game:HttpGet(HYDRA_URL))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ==================== NUCLEO: acceso al movimiento de Evade ====================
-- Verificado en el codigo actual de Evade (extraccion 19/10):
--  - ReplicatedStorage.Objects.Game.Character.Client.Movement: el juego llama Movement:Update(dt) cada cuadro
--    (Character.lua), con self.DataRegistry ("Grounded", "Velocity" en unidades x90), self.JumpHeldDown y self:AttemptJump().
--  - CharacterService:GetCharacterFromPlayer(jugador).Movement.MoveStats: Modifiers + Reset() es lo mismo que hace
--    el evento ModifyMovement del juego. JumpCap = 1 en BaseStats (0 saltos en el aire); cada punto extra = 1 salto mas.
-- En Solara require() crea copias de los modulos: ahi se usa un modo sin require (Stepped) para Speed Front
-- y firesignal (si existe) para Jump Layers.
local Core = {steps = {}, hooked = false, safeMode = false}
pcall(function()
    if identifyexecutor then
        Core.safeMode = string.find(string.lower(tostring(identifyexecutor())), "solara", 1, true) ~= nil
    end
end)

function Core.module(...)
    local node = ReplicatedStorage
    for _, name in ipairs({...}) do
        node = node and node:FindFirstChild(name)
    end
    return node
end

-- engancha Movement.Update una sola vez; cada funcion de Core.steps corre despues del Update del juego
function Core.hook()
    if Core.hooked then return true end
    if Core.safeMode then
        RunService.Stepped:Connect(function(_, dt)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end
            local ctx = {char = char, root = hrp, hum = hum, dt = dt, grounded = hum.FloorMaterial ~= Enum.Material.Air,
                jumpHeld = hum.Jump == true, jump = function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end}
            for _, fn in pairs(Core.steps) do pcall(fn, ctx) end
        end)
        Core.hooked = true
        return true
    end
    local moduleScript = Core.module("Objects", "Game", "Character", "Client", "Movement")
    if not moduleScript then return false end
    local ok, Movement = pcall(require, moduleScript)
    if not ok or type(Movement) ~= "table" or type(Movement.Update) ~= "function" then return false end
    local old = Movement.Update
    Movement.Update = function(self, dt, ...)
        old(self, dt, ...)
        if not (self.Character and self.Character == LocalPlayer.Character) then return end
        local hrp = self.Character:FindFirstChild("HumanoidRootPart")
        local hum = self.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end
        local okG, g = pcall(function() return self.DataRegistry:Get("Grounded") end)
        local ctx = {char = self.Character, root = hrp, hum = hum, dt = tonumber(dt) or (1 / 60), registry = self.DataRegistry,
            grounded = (okG and g ~= nil) and (g == true) or (not (okG and g ~= nil) and hum.FloorMaterial ~= Enum.Material.Air),
            jumpHeld = self.JumpHeldDown == true, movement = self, jump = function() pcall(function() self:AttemptJump() end) end}
        for _, fn in pairs(Core.steps) do pcall(fn, ctx) end
    end
    Core.hooked = true
    return true
end

-- cambia un valor de movimiento del personaje (como el evento ModifyMovement del juego); nil = vuelve al normal
function Core.setModifier(name, value)
    if not Core.safeMode then
        local ok = pcall(function()
            local service = require(Core.module("Services", "Asset", "CharacterService"))
            local data = service:GetCharacterFromPlayer(LocalPlayer)
            local stats = data.Movement.MoveStats
            stats.Modifiers = stats.Modifiers or {}
            stats.Modifiers[name] = value
            stats:Reset()
        end)
        if ok then return true end
    end
    local fire = firesignal
    local char = LocalPlayer.Character
    local tag = char and char:GetAttribute("Tag")
    local event = Core.module("Events", "CharacterTask")
    if type(fire) ~= "function" or not tag or not event then return false end
    return (pcall(fire, event.OnClientEvent, tag, "ModifyMovement", {name, value}))
end

-- ==================== SPEED ====================
-- Velocidad del personaje en studs/s (la velocidad tope corriendo). Evade de fabrica: Speed 1500 y SprintCap 2 en
-- BaseStats (verificado) = 1500 x 2 / 90 = 33 studs/s. Se cambia "Speed" con un Modifier (lo mismo que hace el evento
-- ModifyMovement del juego), asi que siguen andando el arranque del sprint, agacharse, emotes y perks.
local SP = {Enabled = false, Value = 55, Token = 0, SPRINT_CAP = 2}
function SP.apply()
    if SP.Enabled then return Core.setModifier("Speed", SP.Value * 90 / SP.SPRINT_CAP) end
    return Core.setModifier("Speed", nil)
end
LocalPlayer.CharacterAdded:Connect(function()
    SP.Token = SP.Token + 1
    local token = SP.Token
    if not SP.Enabled then return end
    task.spawn(function()
        for _ = 1, 20 do
            task.wait(0.5)
            if token ~= SP.Token or not SP.Enabled then return end
            if SP.apply() then return end
        end
    end)
end)

-- ==================== ADJUST JUMP ====================
-- Altura del salto en studs: "JumpHeight" de MoveStats (BaseStats = 3, verificado). Movement:Jump hace
-- Humanoid.JumpHeight = JumpHeight de las stats, asi que con un Modifier vale para todos los saltos (tambien los del aire).
local AJ = {Enabled = false, Height = 10, Token = 0}
function AJ.apply()
    if AJ.Enabled then return Core.setModifier("JumpHeight", AJ.Height) end
    return Core.setModifier("JumpHeight", nil)
end
LocalPlayer.CharacterAdded:Connect(function()
    AJ.Token = AJ.Token + 1
    local token = AJ.Token
    if not AJ.Enabled then return end
    task.spawn(function()
        for _ = 1, 20 do
            task.wait(0.5)
            if token ~= AJ.Token or not AJ.Enabled then return end
            if AJ.apply() then return end
        end
    end)
end)

-- ==================== SPEED FRONT / BACK FRONT ====================
-- Movimiento de Dara Trimp (velocidad horizontal hacia donde miras, con aceleracion suave) + lo de Trimp x Frontal
-- para no trabarse: un rayo a la altura de la rodilla ve rampas y obstaculos. En el piso salta solo; en el aire los usa
-- de rampa. Multiplicador de rampa ajustable (sube con fuerza x multiplicador y gana velocidad por un momento).
-- Back Front es lo mismo pero hacia atras de la camara (sign = -1). Las dos no pueden estar prendidas a la vez.
local Front = {rays = RaycastParams.new()}
Front.rays.FilterType = Enum.RaycastFilterType.Exclude
pcall(function() Front.rays.RespectCanCollide = true end)

-- rampa u obstaculo en la direccion de avance (ignora jugadores, bots, piso plano, pendientes suaves y paredes de costado)
function Front.obstacle(char, root, dir, speed)
    local ignore = {char}
    for _, name in ipairs({"Players", "Rigs"}) do
        local folder = workspace:FindFirstChild(name)
        if folder then ignore[#ignore + 1] = folder end
    end
    Front.rays.FilterDescendantsInstances = ignore
    local dist = math.clamp(speed * 0.15, 5, 12)
    local hit = workspace:Raycast(root.Position - Vector3.new(0, 1.5, 0), dir * dist, Front.rays)
    if not hit or hit.Normal.Y > 0.9 then return nil end
    local isRamp = hit.Normal.Y >= 0.2
    if not isRamp then
        local n = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
        if n.Magnitude > 0.05 and dir:Dot(-n.Unit) < 0.3 then return nil end
    end
    return hit, isRamp
end

function Front.lift(root, vy)
    local v = root.AssemblyLinearVelocity
    if v.Y < vy then root.AssemblyLinearVelocity = Vector3.new(v.X, vy, v.Z) end
end

function Front.new(sign)
    local F = {
        Enabled = false, Sign = sign, MaxSpeed = 99, Accel = 9, Smooth = true, FollowMove = false,
        RampPower = 42, RampMult = 1.55, RampSpeedBoost = true,
        Speed = 0, Dir = Vector3.new(1, 0, 0), Seen = 0, LastAuto = 0, LastAir = 0, BoostUntil = 0,
    }
    function F.wantedDir(hum)
        if F.FollowMove then
            local md = hum.MoveDirection
            return md.Magnitude > 0.05 and Vector3.new(md.X, 0, md.Z).Unit or nil
        end
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local look = cam.CFrame.LookVector * F.Sign
        local flat = Vector3.new(look.X, 0, look.Z)
        return flat.Magnitude > 0.05 and flat.Unit or nil
    end
    function F.step(ctx)
        if not F.Enabled then F.Speed = 0 return end
        local dir = F.wantedDir(ctx.hum)
        local moving = dir ~= nil and (not F.FollowMove or ctx.hum.MoveDirection.Magnitude > 0.05)
        if dir then F.Dir = dir end
        local now = os.clock()
        local target = moving and F.MaxSpeed or 0
        -- despues de una rampa, un empujon de velocidad que se va apagando (multiplicador de rampa)
        if F.RampSpeedBoost and now < F.BoostUntil and moving then
            local left = (F.BoostUntil - now) / 0.8
            target = target * (1 + (F.RampMult - 1) * 0.5 * left)
        end
        if F.Smooth then
            local rate = target > F.Speed and F.Accel or F.Accel * 0.6
            F.Speed = F.Speed + (target - F.Speed) * math.min(rate * ctx.dt, 1)
        else
            F.Speed = target
        end
        local vel = F.Dir * F.Speed
        if ctx.registry then pcall(function() ctx.registry:Set("Velocity", vel * 90) end) end
        local cur = ctx.root.AssemblyLinearVelocity
        ctx.root.AssemblyLinearVelocity = Vector3.new(vel.X, cur.Y, vel.Z)

        if not moving or F.Speed <= 3 then F.Seen = 0 return end
        local hit, isRamp = Front.obstacle(ctx.char, ctx.root, F.Dir, F.Speed)
        F.Seen = hit and F.Seen + 1 or 0 -- tiene que verse 2 cuadros seguidos
        if F.Seen < 2 then return end
        local lift = F.RampPower * F.RampMult * 0.8
        if ctx.grounded and now - F.LastAuto > 0.45 then
            F.LastAuto = now
            if isRamp then F.BoostUntil = now + 0.8 end
            ctx.jump()
            local root = ctx.root
            task.delay(0.1, function() if root.Parent then Front.lift(root, lift) end end)
        elseif not ctx.grounded and now - F.LastAir > 0.3 then
            F.LastAir = now
            Front.lift(ctx.root, lift * 0.6)
        end
    end
    return F
end

local SF = Front.new(1)
local BF = Front.new(-1)
Core.steps.speedFront = SF.step
Core.steps.backFront = BF.step

-- ==================== SPEED WITH JUMP ====================
-- Salta solo como un conejo y en el aire seguis caminando normal: Evade no deja acelerar hacia adelante en el aire
-- (Functions.Air anula el "adelante" de MoveDirection, verificado en el codigo del juego), asi que en el aire se
-- pone la velocidad hacia donde caminas con la misma rapidez que traias en el piso (x el multiplicador).
local SWJ = {Enabled = false, Power = 34, Delay = 0, AirMult = 1, OnlyMoving = true, GroundSpeed = 0, Last = 0}
Core.steps.speedWithJump = function(ctx)
    if not SWJ.Enabled then return end
    local md = ctx.hum.MoveDirection
    local moving = md.Magnitude > 0.05
    local now = os.clock()
    local flat = Vector3.new(ctx.root.AssemblyLinearVelocity.X, 0, ctx.root.AssemblyLinearVelocity.Z)
    if ctx.grounded then
        if moving then SWJ.GroundSpeed = flat.Magnitude end
        if (moving or not SWJ.OnlyMoving) and now - SWJ.Last >= SWJ.Delay + 0.15 then
            SWJ.Last = now
            ctx.jump()
            local root = ctx.root
            task.delay(0.05, function() if root.Parent then Front.lift(root, SWJ.Power) end end)
        end
    elseif moving and not SF.Enabled and not BF.Enabled and SWJ.GroundSpeed > 1 then
        local vel = Vector3.new(md.X, 0, md.Z).Unit * SWJ.GroundSpeed * SWJ.AirMult
        if ctx.registry then pcall(function() ctx.registry:Set("Velocity", vel * 90) end) end
        ctx.root.AssemblyLinearVelocity = Vector3.new(vel.X, ctx.root.AssemblyLinearVelocity.Y, vel.Z)
    end
end

-- ==================== AUTO CROUCH ====================
-- Se agacha y se levanta solo, las veces por segundo que elijas. Usa la misma entrada que la tecla de agacharse del
-- juego (Movement:KeyUsed con Key = "Crouching" pone "CrouchKey", verificado en el codigo): anda en PC y celular.
local AC = {Enabled = false, Rate = 1.5, Down = false, Next = 0, Movement = nil}
Core.steps.autoCrouch = function(ctx)
    if not AC.Enabled or not ctx.movement then return end
    AC.Movement = ctx.movement
    local now = os.clock()
    if now < AC.Next then return end
    AC.Next = now + 1 / math.max(AC.Rate, 0.5)
    AC.Down = not AC.Down
    pcall(function() ctx.movement:KeyUsed({Key = "Crouching", Down = AC.Down}) end)
end
function AC.release()
    if AC.Down and AC.Movement then pcall(function() AC.Movement:KeyUsed({Key = "Crouching", Down = false}) end) end
    AC.Down = false
end

-- ==================== JUMP LAYERS ====================
-- Saltos en el aire: JumpCap del juego. Capas = saltos extra en el aire (1 a 50) -> JumpCap = capas + 1.
local JL = {Enabled = false, Layers = 3, Token = 0}
function JL.apply()
    if JL.Enabled then return Core.setModifier("JumpCap", JL.Layers + 1) end
    return Core.setModifier("JumpCap", nil)
end
-- despues de morir el personaje nuevo tarda en armarse: reintenta unos segundos
LocalPlayer.CharacterAdded:Connect(function()
    JL.Token = JL.Token + 1
    local token = JL.Token
    if not JL.Enabled then return end
    task.spawn(function()
        for _ = 1, 20 do
            task.wait(0.5)
            if token ~= JL.Token or not JL.Enabled then return end
            if JL.apply() then return end
        end
    end)
end)

-- ==================== COLORES DE HYDRA (siempre activos, sin opcion) ====================
-- Verificado en el codigo de Evade:
--  - Derribados fuera de la pantalla: Fear/Notices/NoticeCreator pinta cada cuadro Notice.Skull y Notice.Arrow.ImageLabel
--    con rojo (255,102,102) que se oscurece hacia (20,8,8) segun el tiempo que le queda al derribado. Viven en
--    PlayerGui.Game.HUD.Notices. Aca pasan a blanco, conservando el oscurecimiento (asi se sigue viendo cuanto le queda).
--  - Vida: CharacterStatus.SetHealth pinta HealthIcon, el texto Health y BackgroundStroke.UIStroke de verde (rojo con poca
--    vida) en PlayerGui.Game.HUD.Overlay.CharacterStatus.BottomLeft.Health. Aca quedan siempre en blanco.
-- No se toca ningun modulo del juego: cada vez que el juego cambia el color, se vuelve a poner el nuestro al instante.
local Paint = {WHITE = Color3.new(1, 1, 1), DARK = Color3.fromRGB(28, 28, 32), last = setmetatable({}, {__mode = "k"})}

-- mantiene inst[prop] con el color que devuelve convert(color que puso el juego)
function Paint.lock(inst, prop, convert)
    if not inst then return end
    local function apply()
        local current = inst[prop]
        if Paint.last[inst] == current then return end
        local wanted = convert(current)
        Paint.last[inst] = wanted
        if current ~= wanted then inst[prop] = wanted end
    end
    inst:GetPropertyChangedSignal(prop):Connect(apply)
    apply()
end

function Paint.white() return Paint.WHITE end
-- rojo del juego -> blanco con el mismo oscurecimiento (R va de 255 a 20 mientras se le acaba el tiempo)
function Paint.downed(color)
    local t = math.clamp((1 - color.R) / (1 - 20 / 255), 0, 1)
    return Paint.WHITE:Lerp(Paint.DARK, t)
end

function Paint.notice(frame)
    local skull = frame:FindFirstChild("Skull")
    local arrow = frame:FindFirstChild("Arrow")
    local arrowImage = arrow and arrow:FindFirstChild("ImageLabel")
    if skull and skull:IsA("ImageLabel") then Paint.lock(skull, "ImageColor3", Paint.downed) end
    if arrowImage and arrowImage:IsA("ImageLabel") then Paint.lock(arrowImage, "ImageColor3", Paint.downed) end
end

-- Reloj de la ronda (RoundState, verificado): el juego muestra Overlay.RoundOverlay.RoundTimer.RoundTimer solo en el
-- intermedio (RoundStatus 1) y lo esconde al empezar la ronda (2); en la ronda escribe el tiempo en IngameRoundTimer.Timer.
-- Aca el reloj grande queda siempre visible, copia el tiempo de la ronda, todo en blanco y con efectos: brillo que
-- cruza los numeros, luz que recorre el borde y un pulso en cada segundo (mas fuerte en los ultimos 10).
Paint.spin = {}
RunService.Heartbeat:Connect(function(dt)
    for gradient in pairs(Paint.spin) do
        if gradient.Parent then
            gradient.Rotation = (gradient.Rotation + dt * 45) % 360
        else
            Paint.spin[gradient] = nil
        end
    end
end)

function Paint.shine(label)
    if not label then return end
    local gradient = label:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(Paint.WHITE)
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.3),
    })
    gradient.Rotation = 0
    gradient.Offset = Vector2.new(-1, 0)
    gradient.Parent = label
    game:GetService("TweenService"):Create(gradient, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1), {Offset = Vector2.new(1, 0)}):Play()
end

function Paint.roundTimer(container)
    local box = container:WaitForChild("RoundTimer", 15)
    if not box then return end
    local timer = box:FindFirstChild("Timer")
    local about = box:FindFirstChild("About")
    local stroke = box:FindFirstChildOfClass("UIStroke")
    -- siempre visible (tambien el contenedor)
    Paint.lock(container, "Visible", function() return true end)
    Paint.lock(box, "Visible", function() return true end)
    -- blanco
    Paint.lock(timer, "TextColor3", Paint.white)
    Paint.lock(about, "TextColor3", Paint.white)
    Paint.lock(box:FindFirstChild("ImageLabel"), "ImageColor3", Paint.white)
    Paint.lock(stroke, "Color", Paint.white)
    -- efectos
    Paint.shine(timer)
    Paint.shine(about)
    if stroke then
        local light = stroke:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
        light.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 74, 86)), ColorSequenceKeypoint.new(0.45, Paint.WHITE),
            ColorSequenceKeypoint.new(0.55, Paint.WHITE), ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 74, 86)),
        })
        light.Transparency = NumberSequence.new(0)
        light.Rotation = 0
        light.Parent = stroke
        Paint.spin[light] = true
    end
    if timer then
        local pulse = timer:FindFirstChild("HydraPulse") or Instance.new("UIScale")
        pulse.Name = "HydraPulse"
        pulse.Parent = timer
        local tweens = game:GetService("TweenService")
        timer:GetPropertyChangedSignal("Text"):Connect(function()
            local seconds = tonumber(string.match(timer.Text, ":(%d+)$"))
            local minutes = tonumber(string.match(timer.Text, "^(%d+):"))
            local last = minutes == 0 and seconds and seconds <= 10
            pulse.Scale = last and 1.18 or 1.07
            tweens:Create(pulse, TweenInfo.new(last and 0.45 or 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        end)
    end
    -- en la ronda el juego escribe el tiempo en el reloj chico: se copia al grande y el chico se esconde
    local ingame = container:FindFirstChild("IngameRoundTimer")
    local ingameTimer = ingame and ingame:FindFirstChild("Timer")
    if ingameTimer and timer then
        Paint.lock(ingame, "Visible", function() return false end)
        ingameTimer:GetPropertyChangedSignal("Text"):Connect(function()
            if timer.Text ~= ingameTimer.Text then timer.Text = ingameTimer.Text end
        end)
    end
end

function Paint.hookGame(gameGui)
    task.spawn(function()
        local hud = gameGui:WaitForChild("HUD", 15)
        if not hud then return end
        local notices = hud:WaitForChild("Notices", 15)
        if notices then
            for _, child in ipairs(notices:GetChildren()) do Paint.notice(child) end
            notices.ChildAdded:Connect(function(child) task.defer(Paint.notice, child) end)
        end
        local ok, health = pcall(function()
            return hud:WaitForChild("Overlay", 15):WaitForChild("CharacterStatus", 15):WaitForChild("BottomLeft", 15):WaitForChild("Health", 15)
        end)
        if ok and health then
            Paint.lock(health:FindFirstChild("HealthIcon"), "ImageColor3", Paint.white)
            Paint.lock(health:FindFirstChild("Health"), "TextColor3", Paint.white)
            local background = health:FindFirstChild("BackgroundStroke")
            Paint.lock(background and background:FindFirstChildOfClass("UIStroke"), "Color", Paint.white)
        end
        local okRound, roundTimer = pcall(function()
            return hud:WaitForChild("Overlay", 15):WaitForChild("RoundOverlay", 15):WaitForChild("RoundTimer", 15)
        end)
        if okRound and roundTimer then Paint.roundTimer(roundTimer) end
    end)
end

do
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local current = playerGui:FindFirstChild("Game")
    if current then Paint.hookGame(current) end
    -- si el juego vuelve a crear su interfaz (respawn), se engancha a la nueva
    playerGui.ChildAdded:Connect(function(child)
        if child.Name == "Game" and child:IsA("ScreenGui") then Paint.hookGame(child) end
    end)
end

-- ==================== PESTANA MOVIMIENTO ====================
Hydra:AddTranslations({
    ["Movimiento"] = "Movement", ["MOVER"] = "MOVE", ["Velocidad"] = "Speed", ["Salto"] = "Jump",
    ["Te lleva hacia adelante sin trabarse"] = "Takes you forward without getting stuck",
    ["Velocidad m\195\161xima"] = "Max speed", ["Hasta qu\195\169 velocidad llega"] = "How fast it gets",
    ["Aceleraci\195\179n"] = "Acceleration", ["Qu\195\169 tan r\195\161pido llega a la velocidad"] = "How fast it reaches the speed",
    ["Multiplicador de rampa"] = "Ramp multiplier", ["Cu\195\161nto te impulsa una rampa"] = "How hard a ramp launches you",
    ["Fuerza de rampa"] = "Ramp power", ["Fuerza base del salto en rampas"] = "Base jump power on ramps",
    ["Acelerar en rampas"] = "Speed up on ramps", ["Gana velocidad un momento al pasar una rampa"] = "Gains speed for a moment after a ramp",
    ["Suave"] = "Smooth", ["Acelera y frena de a poco"] = "Speeds up and slows down gradually",
    ["Seguir movimiento"] = "Follow movement", ["Va hacia donde camin\195\161s, no hacia la c\195\161mara"] = "Goes where you walk, not where the camera looks",
    ["Saltos extra en el aire"] = "Extra jumps in the air",
    ["Capas"] = "Layers", ["Cu\195\161ntas veces pod\195\169s saltar en el aire"] = "How many times you can jump in the air",
    ["No disponible en este ejecutor"] = "Not available on this executor",
    ["Te lleva hacia atr\195\161s sin trabarse"] = "Takes you backwards without getting stuck",
    ["Va hacia donde camin\195\161s, no hacia atr\195\161s de la c\195\161mara"] = "Goes where you walk, not behind the camera",
    ["Salta solo y segu\195\173s caminando normal en el aire"] = "Jumps by itself and you keep walking normally in the air",
    ["Fuerza de salto"] = "Jump power", ["Qu\195\169 tan alto salta"] = "How high it jumps",
    ["Espera entre saltos"] = "Delay between jumps", ["Pausa al tocar el piso"] = "Pause when touching the ground",
    ["Velocidad en el aire"] = "Air speed", ["1x = la misma que al caminar"] = "1x = the same as walking",
    ["Solo al caminar"] = "Only while walking", ["Si no te mov\195\169s, no salta"] = "If you don't move, it doesn't jump",
    ["Se agacha y se levanta solo"] = "Crouches and stands up by itself",
    ["Cambia qu\195\169 tan r\195\161pido corr\195\169s"] = "Changes how fast you run",
    ["Qu\195\169 tan alto salt\195\161s"] = "How high you jump", ["Altura"] = "Height", ["Normal del juego: 3"] = "Game default: 3", ["Normal del juego: 33"] = "Game default: 33",
    ["Ritmo"] = "Rate", ["Cambios por segundo"] = "Changes per second",
})

local TabMove = Hydra:Tab({Id = "Move", Title = "Movimiento", Caption = "MOVER", Icon = "rbxassetid://130468910849957"})

TabMove:Section("Velocidad", "\226\151\183")
local Speed
Speed = TabMove:Toggle({Id = "speedMain", Title = "Speed", Desc = "Cambia qu\195\169 tan r\195\161pido corr\195\169s", Icon = "\226\151\183", Keybind = true, Floating = true,
    Callback = function(on)
        SP.Enabled = on
        if not SP.apply() and on then
            Hydra:Notify("Speed: No disponible en este ejecutor")
            SP.Enabled = false
            task.defer(function() Speed:Set(false, true) end)
        end
    end})
Speed:Slider({Id = "speedValue", Title = "Velocidad", Desc = "Normal del juego: 33", Min = 1, Max = 400, Step = 1, Default = 55,
    Callback = function(v)
        SP.Value = v
        if SP.Enabled then SP.apply() end
    end})
SP.Value = Hydra.Options.speedValue:Get()

-- arma un toggle de movimiento frontal con sus sub-opciones (prefix = ids guardados)
local function frontToggle(F, other, otherId, prefix, title, desc, icon, followDesc)
    local toggle
    toggle = TabMove:Toggle({Id = prefix == "sf" and "speedFront" or "backFront", Title = title, Desc = desc, Icon = icon, Keybind = true, Floating = true,
        Callback = function(on)
            if on and not Core.hook() then
                Hydra:Notify(title .. ": No disponible en este ejecutor")
                task.defer(function() toggle:Set(false, true) end)
                return
            end
            F.Enabled = on
            F.Speed = 0
            -- no pueden ir los dos a la vez
            if on and other.Enabled and Hydra.Options[otherId] then Hydra.Options[otherId]:Set(false) end
        end})
    toggle:Slider({Id = prefix .. "Speed", Title = "Velocidad m\195\161xima", Desc = "Hasta qu\195\169 velocidad llega", Min = 10, Max = 200, Step = 1, Default = 99,
        Callback = function(v) F.MaxSpeed = v end})
    toggle:Slider({Id = prefix .. "Accel", Title = "Aceleraci\195\179n", Desc = "Qu\195\169 tan r\195\161pido llega a la velocidad", Min = 1, Max = 30, Step = 1, Default = 9,
        Callback = function(v) F.Accel = v end})
    toggle:Slider({Id = prefix .. "RampMult", Title = "Multiplicador de rampa", Desc = "Cu\195\161nto te impulsa una rampa", Min = 0.1, Max = 5, Step = 0.05, Default = 1.55, Suffix = "x",
        Callback = function(v) F.RampMult = v end})
    toggle:Slider({Id = prefix .. "RampPower", Title = "Fuerza de rampa", Desc = "Fuerza base del salto en rampas", Min = 30, Max = 110, Step = 1, Default = 42,
        Callback = function(v) F.RampPower = v end})
    toggle:Toggle({Id = prefix .. "RampSpeed", Title = "Acelerar en rampas", Desc = "Gana velocidad un momento al pasar una rampa", Default = true,
        Callback = function(on) F.RampSpeedBoost = on end})
    toggle:Toggle({Id = prefix .. "Smooth", Title = "Suave", Desc = "Acelera y frena de a poco", Default = true,
        Callback = function(on) F.Smooth = on end})
    toggle:Toggle({Id = prefix .. "Follow", Title = "Seguir movimiento", Desc = followDesc,
        Callback = function(on) F.FollowMove = on end})
    -- los valores guardados se cargan al iniciar (el Callback solo corre cuando cambian)
    F.MaxSpeed = Hydra.Options[prefix .. "Speed"]:Get()
    F.Accel = Hydra.Options[prefix .. "Accel"]:Get()
    F.RampMult = Hydra.Options[prefix .. "RampMult"]:Get()
    F.RampPower = Hydra.Options[prefix .. "RampPower"]:Get()
    F.RampSpeedBoost = Hydra.Options[prefix .. "RampSpeed"]:Get()
    F.Smooth = Hydra.Options[prefix .. "Smooth"]:Get()
    F.FollowMove = Hydra.Options[prefix .. "Follow"]:Get()
    return toggle
end
frontToggle(SF, BF, "backFront", "sf", "Speed Front", "Te lleva hacia adelante sin trabarse", "rbxassetid://116954340494960", "Va hacia donde camin\195\161s, no hacia la c\195\161mara")
frontToggle(BF, SF, "speedFront", "bf", "Back Front", "Te lleva hacia atr\195\161s sin trabarse", "rbxassetid://116954340494960", "Va hacia donde camin\195\161s, no hacia atr\195\161s de la c\195\161mara")

local SpeedWithJump
SpeedWithJump = TabMove:Toggle({Id = "speedWithJump", Title = "Speed with jump", Desc = "Salta solo y segu\195\173s caminando normal en el aire", Icon = "\226\151\142", Keybind = true, Floating = true,
    Callback = function(on)
        if on and not Core.hook() then
            Hydra:Notify("Speed with jump: No disponible en este ejecutor")
            task.defer(function() SpeedWithJump:Set(false, true) end)
            return
        end
        SWJ.Enabled = on
        SWJ.GroundSpeed = 0
    end})
SpeedWithJump:Slider({Id = "swjPower", Title = "Fuerza de salto", Desc = "Qu\195\169 tan alto salta", Min = 20, Max = 90, Step = 1, Default = 34,
    Callback = function(v) SWJ.Power = v end})
SpeedWithJump:Slider({Id = "swjDelay", Title = "Espera entre saltos", Desc = "Pausa al tocar el piso", Min = 0, Max = 1, Step = 0.05, Default = 0, Suffix = " s",
    Callback = function(v) SWJ.Delay = v end})
SpeedWithJump:Slider({Id = "swjAir", Title = "Velocidad en el aire", Desc = "1x = la misma que al caminar", Min = 0.5, Max = 2, Step = 0.05, Default = 1, Suffix = "x",
    Callback = function(v) SWJ.AirMult = v end})
SpeedWithJump:Toggle({Id = "swjOnlyMoving", Title = "Solo al caminar", Desc = "Si no te mov\195\169s, no salta", Default = true,
    Callback = function(on) SWJ.OnlyMoving = on end})
SWJ.Power = Hydra.Options.swjPower:Get()
SWJ.Delay = Hydra.Options.swjDelay:Get()
SWJ.AirMult = Hydra.Options.swjAir:Get()
SWJ.OnlyMoving = Hydra.Options.swjOnlyMoving:Get()

local AutoCrouch
AutoCrouch = TabMove:Toggle({Id = "autoCrouch", Title = "Auto Crouch", Desc = "Se agacha y se levanta solo", Icon = "\226\156\166", Keybind = true, Floating = true,
    Callback = function(on)
        if on and (Core.safeMode or not Core.hook()) then
            Hydra:Notify("Auto Crouch: No disponible en este ejecutor")
            task.defer(function() AutoCrouch:Set(false, true) end)
            return
        end
        AC.Enabled = on
        AC.Next = 0
        if not on then AC.release() end
    end})
AutoCrouch:Slider({Id = "acRate", Title = "Ritmo", Desc = "Cambios por segundo", Min = 0.5, Max = 100, Step = 0.5, Default = 1.5, Suffix = "/s",
    Callback = function(v) AC.Rate = v end})
AC.Rate = Hydra.Options.acRate:Get()

TabMove:Section("Salto", "\226\151\142")
local JumpLayers
JumpLayers = TabMove:Toggle({Id = "jumpLayers", Title = "Jump Layers", Desc = "Saltos extra en el aire", Icon = "rbxassetid://88035054740813", Keybind = true, Floating = true,
    Callback = function(on)
        JL.Enabled = on
        if not JL.apply() and on then
            Hydra:Notify("Jump Layers: No disponible en este ejecutor")
            JL.Enabled = false
            task.defer(function() JumpLayers:Set(false, true) end)
        end
    end})
JumpLayers:Slider({Id = "jlLayers", Title = "Capas", Desc = "Cu\195\161ntas veces pod\195\169s saltar en el aire", Min = 1, Max = 50, Step = 1, Default = 3,
    Callback = function(v)
        JL.Layers = v
        if JL.Enabled then JL.apply() end
    end})

-- valor guardado de las capas
JL.Layers = Hydra.Options.jlLayers:Get()

local AdjustJump
AdjustJump = TabMove:Toggle({Id = "adjustJump", Title = "Adjust Jump", Desc = "Qu\195\169 tan alto salt\195\161s", Icon = "\226\151\142", Keybind = true, Floating = true,
    Callback = function(on)
        AJ.Enabled = on
        if not AJ.apply() and on then
            Hydra:Notify("Adjust Jump: No disponible en este ejecutor")
            AJ.Enabled = false
            task.defer(function() AdjustJump:Set(false, true) end)
        end
    end})
AdjustJump:Slider({Id = "ajHeight", Title = "Altura", Desc = "Normal del juego: 3", Min = 1, Max = 100, Step = 0.5, Default = 10,
    Callback = function(v)
        AJ.Height = v
        if AJ.Enabled then AJ.apply() end
    end})
AJ.Height = Hydra.Options.ajHeight:Get()

-- ==================== PESTANA MORE ====================
-- Todo verificado en el codigo actual de Evade:
--  - Events.Interact:FireServer("Revive", tag, true) empieza a revivir y ("Revive", tag) lo termina; ("Carry", tag) carga
--    (InteractionService/InteractionTypes). El tiempo de revivir es "ReviveLength" del derribado.
--  - Events.SetPlayerMode:FireServer(true) es "jugar" (menu); Auto Spawn lo usa al quedar derribado (como Yin Yang).
--  - CharacterService: DataRegistry "Downed", "DownedPeriod" (1 -> 0 mientras se acaba el tiempo), "Carried",
--    "Carrying", "CanBeCarried", "Ragdolling", "Health".
--  - Tickets: modelos en workspace.Effects.Tickets; el juego los junta solo cuando estas a 14 studs (CollectionMethods.Distance).
local More = {}
function More.service()
    if More.svc then return More.svc end
    local ok, svc = pcall(function() return require(Core.module("Services", "Asset", "CharacterService")) end)
    if ok and type(svc) == "table" then More.svc = svc end
    return More.svc
end
function More.data(player)
    local svc = More.service()
    if not svc then return nil end
    local ok, data = pcall(function() return svc:GetCharacterFromPlayer(player) end)
    return ok and data or nil
end
function More.reg(data, key)
    local ok, value = pcall(function() return data.DataRegistry:Get(key) end)
    if ok then return value end
    return nil
end
function More.isSet(value) return value ~= nil and value ~= false and value ~= 0 end
function More.myRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
function More.event(name) return Core.module("Events", name) end

-- ---------- Auto Carry ----------
local AutoCarry = {Enabled = false, Range = 30, Interval = 0.2}
task.spawn(function()
    while true do
        task.wait(AutoCarry.Interval)
        if AutoCarry.Enabled then
            pcall(function()
                local root = More.myRoot()
                local me = More.data(LocalPlayer)
                local interact = More.event("Interact")
                if not root or not me or not interact then return end
                if More.isSet(More.reg(me, "Carrying")) or More.reg(me, "Downed") then return end
                for _, other in ipairs(Players:GetPlayers()) do
                    local char = other ~= LocalPlayer and other.Character
                    local otherRoot = char and char:FindFirstChild("HumanoidRootPart")
                    local data = otherRoot and More.data(other)
                    if data and More.reg(data, "Downed") and not More.isSet(More.reg(data, "Carried"))
                        and More.reg(data, "CanBeCarried") ~= false and not More.reg(data, "Ragdolling")
                        and (otherRoot.Position - root.Position).Magnitude <= AutoCarry.Range then
                        local tag = char:GetAttribute("Tag")
                        if tag then
                            interact:FireServer("Carry", tag)
                            return
                        end
                    end
                end
            end)
        end
    end
end)

-- ---------- Auto Revive ----------
local AutoRevive = {Enabled = false, Range = 30}
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoRevive.Enabled then
            pcall(function()
                local root = More.myRoot()
                local interact = More.event("Interact")
                local me = More.data(LocalPlayer)
                if not root or not interact or (me and More.reg(me, "Downed")) then return end
                for _, other in ipairs(Players:GetPlayers()) do
                    if not AutoRevive.Enabled then return end
                    local char = other ~= LocalPlayer and other.Character
                    local otherRoot = char and char:FindFirstChild("HumanoidRootPart")
                    local data = otherRoot and More.data(other)
                    local tag = char and char:GetAttribute("Tag")
                    if data and tag and More.reg(data, "Downed") and (otherRoot.Position - root.Position).Magnitude <= AutoRevive.Range then
                        interact:FireServer("Revive", tag, true)
                        task.wait(tonumber(More.reg(data, "ReviveLength")) or 1.5)
                        if AutoRevive.Enabled and More.reg(data, "Downed") and otherRoot.Parent
                            and (otherRoot.Position - root.Position).Magnitude <= AutoRevive.Range then
                            interact:FireServer("Revive", tag)
                        end
                    end
                end
            end)
        end
    end
end)

-- ---------- Auto Spawn ----------
local AutoSpawn = {Enabled = false, Last = 0}
task.spawn(function()
    while true do
        task.wait(0.2)
        if AutoSpawn.Enabled and os.clock() - AutoSpawn.Last >= 3 then
            pcall(function()
                local me = More.data(LocalPlayer)
                local remote = More.event("SetPlayerMode")
                if me and remote and More.reg(me, "Downed") then
                    AutoSpawn.Last = os.clock()
                    remote:FireServer(true)
                end
            end)
        end
    end
end)

-- ---------- ESP ----------
-- Jugadores: contorno a traves de paredes, nombre, distancia y vida arriba de la cabeza, lineas opcionales y flechas en
-- el borde de la pantalla que apuntan a los que no ves (con su distancia). Derribados: lo mismo en rojo, con el tiempo
-- que le queda (barra) y si lo estan cargando.
local ESP = {
    entries = {},
    Players = {Enabled = false, MaxDist = 1500, Names = true, Health = true, Arrows = true, Tracers = false, Outline = true},
    Downed = {Enabled = false, MaxDist = 3000, Arrows = true, Outline = true},
    WHITE = Color3.new(1, 1, 1), RED = Color3.fromRGB(255, 92, 92), DIM = Color3.fromRGB(190, 196, 210),
}
function ESP.gui()
    if ESP.screen and ESP.screen.Parent then return ESP.screen end
    local screen = Instance.new("ScreenGui")
    screen.Name = "HydraESP"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.DisplayOrder = 5
    local ok = pcall(function() screen.Parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui") end)
    if not ok or not screen.Parent then screen.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    ESP.screen = screen
    return screen
end
function ESP.label(parent, size, font, color)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, size + 3)
    label.Font = font
    label.TextSize = size
    label.TextColor3 = color
    label.Text = ""
    local outline = Instance.new("UIStroke")
    outline.Thickness = 1.3
    outline.Transparency = 0.25
    outline.Parent = label
    label.Parent = parent
    return label
end
function ESP.bar(parent, width)
    local back = Instance.new("Frame")
    back.Size = UDim2.fromOffset(width, 4)
    back.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
    back.BackgroundTransparency = 0.25
    back.BorderSizePixel = 0
    Instance.new("UICorner", back).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = ESP.WHITE
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    fill.Parent = back
    back.Parent = parent
    return back, fill
end
-- piezas de un jugador (se crean una vez y se reusan)
function ESP.entry(player)
    local e = ESP.entries[player]
    if e then return e end
    local screen = ESP.gui()
    e = {}
    local bb = Instance.new("BillboardGui")
    bb.Name = "HydraESP_" .. player.Name
    bb.Size = UDim2.fromOffset(170, 58)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Enabled = false
    local list = Instance.new("UIListLayout")
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.Padding = UDim.new(0, 2)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = bb
    e.tag = ESP.label(bb, 10, Enum.Font.GothamBlack, ESP.RED)
    e.tag.LayoutOrder = 1
    e.name = ESP.label(bb, 13, Enum.Font.GothamBold, ESP.WHITE)
    e.name.LayoutOrder = 2
    e.info = ESP.label(bb, 11, Enum.Font.GothamSemibold, ESP.DIM)
    e.info.LayoutOrder = 3
    e.barBack, e.bar = ESP.bar(bb, 64)
    e.barBack.LayoutOrder = 4
    bb.Parent = screen
    e.bb = bb
    -- flecha del borde: un rombo que apunta + la distancia
    local arrow = Instance.new("Frame")
    arrow.Size = UDim2.fromOffset(46, 46)
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.BackgroundTransparency = 1
    arrow.Visible = false
    local tip = Instance.new("Frame")
    tip.Size = UDim2.fromOffset(12, 12)
    tip.AnchorPoint = Vector2.new(0.5, 0.5)
    tip.Position = UDim2.new(0.5, 0, 0, 4)
    tip.Rotation = 45
    tip.BorderSizePixel = 0
    tip.BackgroundColor3 = ESP.WHITE
    tip.Parent = arrow
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(30, 30)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.fromScale(0.5, 0.55)
    dot.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
    dot.BackgroundTransparency = 0.25
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local dotStroke = Instance.new("UIStroke")
    dotStroke.Thickness = 1.5
    dotStroke.Color = ESP.WHITE
    dotStroke.Parent = dot
    dot.Parent = arrow
    local dist = Instance.new("TextLabel")
    dist.BackgroundTransparency = 1
    dist.Size = UDim2.fromScale(1, 1)
    dist.Font = Enum.Font.GothamBlack
    dist.TextSize = 10
    dist.TextColor3 = ESP.WHITE
    dist.Parent = dot
    arrow.Parent = screen
    e.arrow, e.tip, e.dot, e.dotStroke, e.arrowText = arrow, tip, dot, dotStroke, dist
    -- linea desde abajo de la pantalla
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BorderSizePixel = 0
    line.BackgroundTransparency = 0.35
    line.Visible = false
    line.Parent = screen
    e.line = line
    ESP.entries[player] = e
    return e
end
function ESP.remove(player)
    local e = ESP.entries[player]
    if not e then return end
    pcall(function() e.bb:Destroy() end)
    pcall(function() e.arrow:Destroy() end)
    pcall(function() e.line:Destroy() end)
    if e.hl then pcall(function() e.hl:Destroy() end) end
    ESP.entries[player] = nil
end
Players.PlayerRemoving:Connect(ESP.remove)
function ESP.hide(e)
    e.bb.Enabled = false
    e.arrow.Visible = false
    e.line.Visible = false
    if e.hl then e.hl.Enabled = false end
end
function ESP.outline(e, char, color, on)
    if not on then
        if e.hl then e.hl.Enabled = false end
        return
    end
    if not e.hl or e.hl.Parent ~= char then
        if e.hl then pcall(function() e.hl:Destroy() end) end
        local hl = Instance.new("Highlight")
        hl.Name = "HydraHL"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Adornee = char
        hl.Parent = char
        e.hl = hl
    end
    e.hl.Adornee = char
    e.hl.FillColor = color
    e.hl.OutlineColor = color
    e.hl.Enabled = true
end
function ESP.step()
    local cam = workspace.CurrentCamera
    local myRoot = More.myRoot()
    local screen = ESP.screen
    if not cam or not screen then return end
    local view = cam.ViewportSize
    local center = Vector2.new(view.X / 2, view.Y / 2)
    local radius = math.min(view.X, view.Y) * 0.36
    local anyOn = ESP.Players.Enabled or ESP.Downed.Enabled
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local e = anyOn and root and ESP.entry(player)
            if e then
                local data = More.data(player)
                local downed = data and More.reg(data, "Downed") == true
                local cfg = downed and ESP.Downed or ESP.Players
                -- si el derribado no tiene su ESP prendido, se muestra con el de jugadores (sin datos de derribado)
                if downed and not ESP.Downed.Enabled then cfg, downed = ESP.Players, false end
                local distance = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                if not cfg.Enabled or distance > cfg.MaxDist then
                    ESP.hide(e)
                else
                    local color = downed and ESP.RED or ESP.WHITE
                    ESP.outline(e, char, color, cfg.Outline)
                    -- cartel arriba de la cabeza
                    e.bb.Adornee = char:FindFirstChild("Head") or root
                    e.bb.Enabled = true
                    e.tag.Visible = downed
                    if downed then
                        local carried = More.isSet(More.reg(data, "Carried"))
                        e.tag.Text = Hydra:T(carried and "CARGADO" or "DERRIBADO")
                    end
                    e.name.Visible = downed or cfg.Names
                    e.name.Text = player.DisplayName
                    e.name.TextColor3 = color
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local health = data and tonumber(More.reg(data, "Health")) or (hum and hum.Health) or 0
                    e.info.Text = math.floor(distance + 0.5) .. "m" .. ((not downed and cfg.Health) and ("  \194\183  " .. math.floor(health + 0.5) .. " hp") or "")
                    local showBar = downed or cfg.Health
                    e.barBack.Visible = showBar
                    if showBar then
                        local fraction
                        if downed then
                            fraction = math.clamp(tonumber(More.reg(data, "DownedPeriod")) or 1, 0, 1)
                        else
                            local maxHealth = hum and hum.MaxHealth or 100
                            fraction = math.clamp(health / math.max(maxHealth, 1), 0, 1)
                        end
                        e.bar.Size = UDim2.fromScale(fraction, 1)
                        e.bar.BackgroundColor3 = downed and ESP.RED:Lerp(Color3.fromRGB(90, 20, 20), 1 - fraction) or ESP.WHITE
                    end
                    -- en pantalla o flecha en el borde
                    local point, onScreen = cam:WorldToViewportPoint(root.Position)
                    local visible = onScreen and point.Z > 0
                    if not visible and cfg.Arrows then
                        local rel = cam.CFrame:PointToObjectSpace(root.Position)
                        local angle = math.atan2(rel.X, -rel.Z)
                        e.arrow.Position = UDim2.fromOffset(center.X + math.sin(angle) * radius, center.Y - math.cos(angle) * radius)
                        e.arrow.Rotation = math.deg(angle)
                        e.dot.Rotation = -math.deg(angle)
                        e.tip.BackgroundColor3 = color
                        e.dotStroke.Color = color
                        e.arrowText.Text = math.floor(distance + 0.5) .. ""
                        e.arrowText.TextColor3 = color
                        e.arrow.Visible = true
                    else
                        e.arrow.Visible = false
                    end
                    if visible and not downed and cfg.Tracers then
                        local from = Vector2.new(center.X, view.Y - 6)
                        local to = Vector2.new(point.X, point.Y)
                        local delta = to - from
                        e.line.Size = UDim2.fromOffset(delta.Magnitude, 1.5)
                        e.line.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
                        e.line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                        e.line.BackgroundColor3 = color
                        e.line.Visible = true
                    else
                        e.line.Visible = false
                    end
                end
            elseif ESP.entries[player] then
                ESP.hide(ESP.entries[player])
            end
        end
    end
end
RunService.RenderStepped:Connect(function()
    if ESP.Players.Enabled or ESP.Downed.Enabled then
        pcall(ESP.step)
    elseif ESP.screen then
        for _, e in pairs(ESP.entries) do ESP.hide(e) end
    end
end)

-- ---------- Auto Farm de tickets ----------
local Farm = {Enabled = false, Return = true, Busy = false}
function Farm.tickets()
    local effects = workspace:FindFirstChild("Effects")
    local folder = effects and effects:FindFirstChild("Tickets")
    local list = {}
    if folder then
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") and model.PrimaryPart then list[#list + 1] = model end
        end
    end
    return list
end
function Farm.canMove()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local me = More.data(LocalPlayer)
    return hum and hum.Health > 0 and not (me and More.reg(me, "Downed"))
end
-- se teletransporta directo a la posicion
function Farm.travel(root, target)
    if not Farm.Enabled or not root.Parent then return false end
    root.CFrame = CFrame.new(target)
    root.AssemblyLinearVelocity = Vector3.zero
    return true
end
task.spawn(function()
    while true do
        task.wait(0.5)
        if Farm.Enabled and not Farm.Busy and Farm.canMove() then
            local list = Farm.tickets()
            local root = More.myRoot()
            if #list > 0 and root then
                Farm.Busy = true
                pcall(function()
                    local home = root.CFrame
                    for _ = 1, #list do
                        if not Farm.Enabled or not Farm.canMove() then break end
                        -- el mas cercano primero
                        local best, bestDist
                        for _, model in ipairs(Farm.tickets()) do
                            local d = (model.PrimaryPart.Position - root.Position).Magnitude
                            if not bestDist or d < bestDist then best, bestDist = model, d end
                        end
                        if not best then break end
                        -- se queda en ese ticket hasta que el juego lo junte (el modelo se borra al juntarlo, o cuando vence a
                        -- los 60 s). Si algo lo mueve, vuelve al ticket. No va por otro hasta terminar con este.
                        local target = best.PrimaryPart.Position + Vector3.new(0, 2, 0)
                        local stopped = false
                        while best.Parent and best.PrimaryPart do
                            if not Farm.Enabled or not Farm.canMove() or not root.Parent then stopped = true break end
                            if (root.Position - target).Magnitude > 6 then Farm.travel(root, target) end
                            task.wait(0.1)
                        end
                        if stopped then break end
                    end
                    -- con el AFK prendido siempre vuelve al bloque; si no, a donde estaba (si "Volver" esta prendido)
                    if More.afkReturn and More.afkReturn() then return end
                    if Farm.Return and Farm.Enabled and Farm.canMove() and root.Parent then Farm.travel(root, home.Position) end
                end)
                Farm.Busy = false
            end
        end
    end
end)

-- ---------- AFK ----------
-- Te lleva a una plataforma en el cielo, muy lejos del mapa (los bots no llegan). La plataforma es local, grande, con el
-- logo de Hydra de fondo. Si reapareces con el AFK prendido, te vuelve a llevar. Ademas evita que Roblox te saque por
-- estar quieto (Players.LocalPlayer.Idled). Al apagarlo volves a donde estabas.
-- Con el auto farm: sale de la plataforma a juntar los tickets y despues vuelve a ella.
local AFK = {Enabled = false, Home = nil, Platform = nil, SPOT = Vector3.new(9000, 1600, 9000), LOGO = "rbxassetid://114974832117287"}
function AFK.build()
    if AFK.Platform and AFK.Platform.Parent then return AFK.Platform end
    local model = Instance.new("Model")
    model.Name = "HydraAFK"
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(70, 4, 70)
    base.Anchored = true
    base.CanCollide = true
    base.Material = Enum.Material.SmoothPlastic
    base.Color = Color3.fromRGB(14, 15, 20)
    base.CFrame = CFrame.new(AFK.SPOT)
    base.Parent = model
    for _, face in ipairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
        local decal = Instance.new("Decal")
        decal.Face = face
        decal.Texture = AFK.LOGO
        decal.Parent = base
    end
    -- borde con brillo y una luz suave
    local edge = Instance.new("SelectionBox")
    edge.Adornee = base
    edge.LineThickness = 0.25
    edge.Color3 = Color3.fromRGB(235, 238, 245)
    edge.SurfaceTransparency = 1
    edge.Parent = base
    local light = Instance.new("PointLight")
    light.Range = 40
    light.Brightness = 1.5
    light.Color = Color3.fromRGB(235, 238, 245)
    light.Parent = base
    model.PrimaryPart = base
    model.Parent = workspace
    AFK.Platform = model
    return model
end
function AFK.goUp()
    local root = More.myRoot()
    if not root then return false end
    AFK.build()
    root.CFrame = CFrame.new(AFK.SPOT + Vector3.new(0, 6, 0))
    root.AssemblyLinearVelocity = Vector3.zero
    return true
end
function AFK.set(on)
    AFK.Enabled = on
    More.afkReturn = on and function() return AFK.Enabled and AFK.goUp() end or nil
    local root = More.myRoot()
    if on then
        AFK.Home = root and root.CFrame or nil
        AFK.goUp()
    else
        if root and AFK.Home then
            root.CFrame = AFK.Home
            root.AssemblyLinearVelocity = Vector3.zero
        end
        AFK.Home = nil
        if AFK.Platform then AFK.Platform:Destroy() AFK.Platform = nil end
    end
end
-- si reapareces o el juego te mueve de la plataforma, te vuelve a subir
task.spawn(function()
    while true do
        task.wait(0.25)
        if AFK.Enabled then
            pcall(function()
                local root = More.myRoot()
                -- mientras el auto farm junta tickets no se lo interrumpe: al terminar vuelve solo a la plataforma
                if root and not Farm.Busy and (root.Position - AFK.SPOT).Magnitude > 80 then AFK.goUp() end
            end)
        end
    end
end)
-- anti-AFK de Roblox (no te saca a los 20 minutos)
LocalPlayer.Idled:Connect(function()
    if not AFK.Enabled then return end
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)

-- ---------- interfaz ----------
Hydra:AddTranslations({
    ["Ayuda"] = "Help", ["Visual"] = "Visual", ["Farm"] = "Farm",
    ["Carga solo a los derribados cerca tuyo"] = "Carries nearby downed players by itself",
    ["Distancia"] = "Range", ["Hasta qu\195\169 distancia act\195\186a"] = "How far it works", ["Espera"] = "Delay", ["Entre intentos"] = "Between attempts",
    ["Revive solo a los derribados cerca tuyo"] = "Revives nearby downed players by itself",
    ["Si qued\195\161s derribado, vuelve a aparecer solo"] = "If you get downed, you respawn by itself",
    ["ESP jugadores"] = "Player ESP", ["Encontr\195\161 a todos, incluso a trav\195\169s de paredes"] = "Find everyone, even through walls",
    ["Distancia m\195\161xima"] = "Max distance", ["M\195\161s lejos no se muestra"] = "Farther away is hidden",
    ["Nombres"] = "Names", ["Vida"] = "Health", ["Flechas en el borde"] = "Edge arrows", ["Apuntan a los que no ves"] = "Point at the ones you can't see",
    ["L\195\173neas"] = "Lines", ["Desde abajo de la pantalla hasta cada uno"] = "From the bottom of the screen to each one",
    ["Contorno"] = "Outline", ["Silueta a trav\195\169s de paredes"] = "Silhouette through walls",
    ["ESP derribados"] = "Downed ESP", ["Derribados con su tiempo restante"] = "Downed players with their remaining time",
    ["Auto farm tickets"] = "Auto farm tickets", ["Junta los tickets del mapa solo"] = "Collects the map tickets by itself",
    ["Velocidad de viaje"] = "Travel speed", ["Qu\195\169 tan r\195\161pido va a cada ticket"] = "How fast it goes to each ticket",
    ["Directo"] = "Instant", ["Aparece en el ticket sin deslizarse"] = "Appears on the ticket without gliding",
    ["Volver"] = "Return", ["Al terminar vuelve a donde estabas"] = "When done, goes back to where you were",
    ["DERRIBADO"] = "DOWNED", ["CARGADO"] = "CARRIED",
    ["Te deja en una plataforma en el cielo, lejos de todo"] = "Leaves you on a platform in the sky, far from everything",
})
ESP.gui()
local TabMore = Hydra:Tab({Id = "More", Title = "More", Caption = "MORE", Icon = "rbxassetid://114688401779019"})

TabMore:Section("Ayuda", "\226\156\166")
local CarryToggle = TabMore:Toggle({Id = "autoCarry", Title = "Auto Carry", Desc = "Carga solo a los derribados cerca tuyo", Icon = "\226\156\166", Keybind = true, Floating = true,
    Callback = function(on) AutoCarry.Enabled = on end})
CarryToggle:Slider({Id = "carryRange", Title = "Distancia", Desc = "Hasta qu\195\169 distancia act\195\186a", Min = 5, Max = 60, Step = 1, Default = 30, Suffix = " m",
    Callback = function(v) AutoCarry.Range = v end})
CarryToggle:Slider({Id = "carryDelay", Title = "Espera", Desc = "Entre intentos", Min = 0.05, Max = 1, Step = 0.05, Default = 0.2, Suffix = " s",
    Callback = function(v) AutoCarry.Interval = v end})
local ReviveToggle = TabMore:Toggle({Id = "autoRevive", Title = "Auto Revive", Desc = "Revive solo a los derribados cerca tuyo", Icon = "\226\156\166", Keybind = true, Floating = true,
    Callback = function(on) AutoRevive.Enabled = on end})
ReviveToggle:Slider({Id = "reviveRange", Title = "Distancia", Desc = "Hasta qu\195\169 distancia act\195\186a", Min = 5, Max = 30, Step = 1, Default = 30, Suffix = " m",
    Callback = function(v) AutoRevive.Range = v end})
TabMore:Toggle({Id = "autoSpawn", Title = "Auto Spawn", Desc = "Si qued\195\161s derribado, vuelve a aparecer solo", Icon = "\226\156\166", Keybind = true, Floating = true,
    Callback = function(on) AutoSpawn.Enabled = on end})

TabMore:Section("Visual", "\226\151\142")
local EspToggle = TabMore:Toggle({Id = "espPlayers", Title = "ESP jugadores", Desc = "Encontr\195\161 a todos, incluso a trav\195\169s de paredes", Icon = "\226\151\142", Keybind = true, Floating = true,
    Callback = function(on) ESP.Players.Enabled = on end})
EspToggle:Slider({Id = "espDist", Title = "Distancia m\195\161xima", Desc = "M\195\161s lejos no se muestra", Min = 50, Max = 5000, Step = 50, Default = 1500, Suffix = " m",
    Callback = function(v) ESP.Players.MaxDist = v end})
EspToggle:Toggle({Id = "espNames", Title = "Nombres", Default = true, Callback = function(on) ESP.Players.Names = on end})
EspToggle:Toggle({Id = "espHealth", Title = "Vida", Default = true, Callback = function(on) ESP.Players.Health = on end})
EspToggle:Toggle({Id = "espArrows", Title = "Flechas en el borde", Desc = "Apuntan a los que no ves", Default = true, Callback = function(on) ESP.Players.Arrows = on end})
EspToggle:Toggle({Id = "espLines", Title = "L\195\173neas", Desc = "Desde abajo de la pantalla hasta cada uno", Callback = function(on) ESP.Players.Tracers = on end})
EspToggle:Toggle({Id = "espOutline", Title = "Contorno", Desc = "Silueta a trav\195\169s de paredes", Default = true, Callback = function(on) ESP.Players.Outline = on end})
local DownToggle = TabMore:Toggle({Id = "espDowned", Title = "ESP derribados", Desc = "Derribados con su tiempo restante", Icon = "\226\151\142", Keybind = true, Floating = true,
    Callback = function(on) ESP.Downed.Enabled = on end})
DownToggle:Slider({Id = "espDownDist", Title = "Distancia m\195\161xima", Desc = "M\195\161s lejos no se muestra", Min = 50, Max = 5000, Step = 50, Default = 3000, Suffix = " m",
    Callback = function(v) ESP.Downed.MaxDist = v end})
DownToggle:Toggle({Id = "espDownArrows", Title = "Flechas en el borde", Desc = "Apuntan a los que no ves", Default = true, Callback = function(on) ESP.Downed.Arrows = on end})
DownToggle:Toggle({Id = "espDownOutline", Title = "Contorno", Desc = "Silueta a trav\195\169s de paredes", Default = true, Callback = function(on) ESP.Downed.Outline = on end})

TabMore:Section("Farm", "\226\158\164")
TabMore:Toggle({Id = "afk", Title = "AFK", Desc = "Te deja en una plataforma en el cielo, lejos de todo", Icon = "\226\158\164", Keybind = true, Floating = true,
    Callback = function(on) AFK.set(on) end})
local FarmToggle = TabMore:Toggle({Id = "ticketFarm", Title = "Auto farm tickets", Desc = "Junta los tickets del mapa solo", Icon = "\226\158\164", Keybind = true, Floating = true,
    Callback = function(on) Farm.Enabled = on end})
FarmToggle:Toggle({Id = "farmReturn", Title = "Volver", Desc = "Al terminar vuelve a donde estabas", Default = true, Callback = function(on) Farm.Return = on end})

-- valores guardados (el Callback de los sliders y sub-opciones solo corre cuando cambian)
AutoCarry.Range, AutoCarry.Interval = Hydra.Options.carryRange:Get(), Hydra.Options.carryDelay:Get()
AutoRevive.Range = Hydra.Options.reviveRange:Get()
ESP.Players.MaxDist, ESP.Players.Names, ESP.Players.Health = Hydra.Options.espDist:Get(), Hydra.Options.espNames:Get(), Hydra.Options.espHealth:Get()
ESP.Players.Arrows, ESP.Players.Tracers, ESP.Players.Outline = Hydra.Options.espArrows:Get(), Hydra.Options.espLines:Get(), Hydra.Options.espOutline:Get()
ESP.Downed.MaxDist, ESP.Downed.Arrows, ESP.Downed.Outline = Hydra.Options.espDownDist:Get(), Hydra.Options.espDownArrows:Get(), Hydra.Options.espDownOutline:Get()
Farm.Return = Hydra.Options.farmReturn:Get()
