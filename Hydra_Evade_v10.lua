--[[
    HYDRA - interfaz

    VENTANA
    - Arrastra la ventana desde la cabecera. Las pestanas de abajo son un carrusel: arrastralo de costado o toca una pestana.
    - "-" esconde la ventana y deja un boton flotante; tocalo para volver a abrirla. En PC tambien con la tecla K.
    - "" cierra el script.

    IDIOMA
    Detecta el idioma del jugador (primero el del dispositivo, despues el que eligio en Roblox). Espanol e ingles completos;
    otros idiomas usan el traductor de Roblox. Se puede forzar en AJUSTES -> Idioma.

    COMPONENTES (para armar las pestanas de Hydra en la seccion "pestanas y opciones")
    createTab, section, toggle, slider, actionButton, dropdown, infoCard, note, toast.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ==================== CONFIGURACION (se guarda en el executor) ====================
local CONFIG_FILE = "Hydra.json"
local Config = {
    language = "auto", -- "auto" (idioma de Roblox), "es" o "en"
    flags = {}, binds = {}, floats = {}, -- valores de las opciones, teclas de atajo y botones flotantes (API de Hydra)
}
local function loadConfig()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    pcall(function()
        if not isfile(CONFIG_FILE) then return end
        local data = game:GetService("HttpService"):JSONDecode(readfile(CONFIG_FILE))
        for key, value in pairs(data) do
            if Config[key] ~= nil and type(value) == type(Config[key]) then Config[key] = value end
        end
    end)
end
local saveToken = 0
local function saveConfig()
    if type(writefile) ~= "function" then return end
    saveToken = saveToken + 1
    local token = saveToken
    task.delay(0.5, function()
        if token ~= saveToken then return end
        pcall(function() writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(Config)) end)
    end)
end
loadConfig()

-- ==================== IDIOMA (detecta el idioma del jugador) ====================
-- Espanol e ingles vienen completos. Para otros idiomas se usa el traductor de Roblox;
-- si Roblox no tiene esa frase traducida, se muestra en ingles.
local LocalizationService = game:GetService("LocalizationService")
local Lang = {current = "en", system = "en", translator = nil, cache = {}, registry = setmetatable({}, {__mode = "k"}), onChange = nil}
local EN = {
    -- pestanas y titulos
    -- pestanas y titulos
    ["AJUSTES"] = "SETTINGS", ["Ajustes"] = "Settings", ["No hay nada para elegir"] = "Nothing to choose",
    ["RIESGO"] = "RISK",
    -- ajustes
    ["Idioma"] = "Language", ["Autom\195\161tico = el idioma de tu Roblox"] = "Automatic = your Roblox language", ["Autom\195\161tico"] = "Automatic",
    ["Ventana"] = "Window", ["Teclas"] = "Keys",
    -- inicio
    ["INICIO"] = "HOME", ["Inicio"] = "Home",
    ["Buenos d\195\173as"] = "Good morning", ["Buenas tardes"] = "Good afternoon", ["Buenas noches"] = "Good evening",
    ["Sesi\195\179n"] = "Session", ["En l\195\173nea"] = "Online",
    ["Rendimiento"] = "Performance", ["Ping"] = "Ping", ["Jugadores"] = "Players", ["Servidor abierto hace"] = "Server up for",
    ["Partida"] = "Match", ["Juego"] = "Game", ["Ejecutor"] = "Executor", ["Versi\195\179n"] = "Version",
    ["Accesos r\195\161pidos"] = "Quick actions", ["Copiar servidor"] = "Copy server", ["Reentrar"] = "Rejoin",
    ["ID del servidor copiado"] = "Server ID copied", ["Tu ejecutor no puede copiar"] = "Your executor can't copy",
    ["Reentrando..."] = "Rejoining...", ["No se pudo reentrar"] = "Couldn't rejoin",
    ["Bot\195\179n \226\128\147 : esconde la ventana. Toc\195\161 el bot\195\179n flotante para volver a abrirla. En PC tambi\195\169n con la tecla K. La \226\156\149 cierra el script."] = "\226\128\147 button: hides the window. Tap the floating button to open it again. On PC you can also press K. The \226\156\149 closes the script.",
}
local function normalizeLocale(localeId)
    return string.lower(tostring(localeId or "en")):match("^(%a+)") or "en"
end
local function tr(spanish)
    if Lang.current == "es" then return spanish end
    local english = EN[spanish] or spanish
    if Lang.current == "en" or not Lang.translator then return english end
    local cached = Lang.cache[english]
    if cached ~= nil then return cached or english end
    local translated
    pcall(function() translated = Lang.translator:Translate(game, english) end)
    if translated and translated ~= "" and translated ~= english then
        Lang.cache[english] = translated
        return translated
    end
    Lang.cache[english] = false
    return english
end
local function resolveLanguage()
    local mode = Config.language
    if mode == "es" or mode == "en" then return mode end
    return Lang.system
end
local function applyLanguage(force)
    local language = resolveLanguage()
    if language == Lang.current and not force then return end
    Lang.current, Lang.cache = language, {}
    for inst, key in pairs(Lang.registry) do
        if inst.Parent then inst.Text = tr(key) end
    end
    if Lang.onChange then pcall(Lang.onChange) end
end
pcall(function()
    local locale = LocalizationService.SystemLocaleId
    if locale and locale ~= "" then Lang.system = normalizeLocale(locale) end
end)
Lang.current = resolveLanguage()
-- el idioma que el jugador eligio en Roblox manda sobre el del sistema
task.spawn(function()
    local ok, translator = pcall(function() return LocalizationService:GetTranslatorForPlayerAsync(LocalPlayer) end)
    if not ok or not translator then return end
    Lang.translator = translator
    Lang.system = normalizeLocale(translator.LocaleId)
    Lang.cache = {}
    applyLanguage(true)
    pcall(function()
        translator:GetPropertyChangedSignal("LocaleId"):Connect(function()
            Lang.system = normalizeLocale(translator.LocaleId)
            applyLanguage()
        end)
    end)
end)


-- colores
local C = {
    -- tema oscuro tipo glass: fondo casi negro translucido, tarjetas de vidrio claro, acento blanco/plateado
    Bg = Color3.fromRGB(12, 14, 19), Card = Color3.fromRGB(30, 34, 43), Field = Color3.fromRGB(38, 43, 54),
    Glass = Color3.fromRGB(255, 255, 255),
    Stroke = Color3.fromRGB(150, 156, 172), Text = Color3.fromRGB(248, 249, 252), Dim = Color3.fromRGB(212, 216, 226),
    Accent = Color3.fromRGB(236, 239, 245), AccentDark = Color3.fromRGB(140, 146, 160), AccentSoft = Color3.fromRGB(62, 66, 78),
    On = Color3.fromRGB(236, 239, 245), Off = Color3.fromRGB(70, 75, 88),
    Warn = Color3.fromRGB(255, 176, 86),
    Good = Color3.fromRGB(46, 214, 170), Mid = Color3.fromRGB(255, 190, 80), Bad = Color3.fromRGB(255, 96, 110),
}

-- contenedor propio (fuera del Workspace del juego)
local guiParent = LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
    if typeof(gethui) == "function" then
        local hidden = gethui()
        if hidden then guiParent = hidden end
    end
end)
for _, name in ipairs({"Hydra"}) do
    local old = guiParent:FindFirstChild(name)
    if old then old:Destroy() end
end

local Connections = {}
local function track(connection) table.insert(Connections, connection) return connection end

-- ==================== UTILIDADES ====================
local function mk(class, props)
    local inst = Instance.new(class)
    for key, value in pairs(props) do
        if key ~= "Parent" then inst[key] = value end
    end
    -- si el texto es una frase conocida, se traduce y se anota para cambiarla si cambia el idioma
    local text = props.Text
    if type(text) == "string" and EN[text] then
        Lang.registry[inst] = text
        inst.Text = tr(text)
    end
    -- contorno oscuro suave en los textos: se leen bien aunque detras haya partes claras del fondo
    if class == "TextLabel" or class == "TextBox" then
        local outline = Instance.new("UIStroke")
        outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        outline.Color = Color3.new(0, 0, 0)
        outline.Thickness = 1.2
        outline.Transparency = 0.45
        outline.Parent = inst
    end
    inst.Parent = props.Parent
    return inst
end
local function corner(parent, radius) return mk("UICorner", {CornerRadius = UDim.new(0, radius), Parent = parent}) end
local function stroke(parent, color, transparency)
    return mk("UIStroke", {Color = color, Thickness = 1, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent})
end
local function tween(inst, time, goals, style)
    local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), goals)
    t:Play()
    return t
end

-- iconos: las letras     salen como cuadros en algunos celulares, asi que se dibujan como imagenes (ids del script Sapphire).
-- La clave es la letra que ya usa cada pestana/seccion; si una letra no esta aca se sigue dibujando como texto.
local ICON_IMAGES = {
    ["\226\158\164"] = "rbxassetid://7734058599", -- Blatant
    ["\226\156\166"] = "rbxassetid://7733954760", -- World
    ["\226\151\142"] = "rbxassetid://7734056608", -- Detection
    ["\226\156\142"] = "rbxassetid://7733917120", -- Misc
    ["\226\154\153"] = "rbxassetid://82447077635685", -- Ajustes
    ["\226\151\183"] = "rbxassetid://7733774602", -- Visual
    ["\226\150\162"] = "rbxassetid://7734053495", -- GUI
    ["\226\140\130"] = "rbxassetid://131051652075705", -- Inicio
}
local function mkIcon(glyph, color, imageProps, textProps)
    local image = ICON_IMAGES[glyph] or ((type(glyph) == "string" and string.sub(glyph, 1, 13) == "rbxassetid://") and glyph or nil)
    if image then
        imageProps.Image, imageProps.ImageColor3, imageProps.BackgroundTransparency = image, color, 1
        return mk("ImageLabel", imageProps), "ImageColor3"
    end
    textProps.Text, textProps.TextColor3 = glyph, color
    return mk("TextLabel", textProps), "TextColor3"
end

-- ==================== INTERFAZ ====================
local Gui = mk("ScreenGui", {Name = "Hydra", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 60, Parent = guiParent})
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local WIDTH, HEIGHT = isMobile and 480 or 590, isMobile and 350 or 445

local Window = mk("Frame", {
    Size = UDim2.fromOffset(WIDTH, HEIGHT), Position = UDim2.new(0.5, -WIDTH / 2, 0.5, -HEIGHT / 2),
    BackgroundColor3 = C.Bg, BackgroundTransparency = 0.06, BorderSizePixel = 0, ClipsDescendants = true, Parent = Gui,
})
-- brillo de vidrio: arriba un poco mas claro
mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 176, 190)), Parent = Window})
corner(Window, 18)
stroke(Window, C.Stroke, 0.1)
local WindowScale = mk("UIScale", {Scale = 0.9, Parent = Window})
-- imagen de fondo de la ventana: va detras de todo y un poco transparente para que el texto se lea
local BG_IMAGE_ID, BG_IMAGE_TRANSPARENCY = "rbxassetid://104092388902076", 0.3
local CARD_ALPHA, BAR_ALPHA = 0.9, 0.4 -- transparencia de las tarjetas de opciones y de la barra de pestanas (0 = blanco opaco, 1 = invisible)
local WindowBg = mk("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = BG_IMAGE_ID, ImageTransparency = BG_IMAGE_TRANSPARENCY, ScaleType = Enum.ScaleType.Crop, ZIndex = 0, Parent = Window})
corner(WindowBg, 18)

-- cabecera
local Header = mk("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = Window})

-- titulo
local TitleRow = mk("Frame", {Size = UDim2.new(1, -196, 0, 28), Position = UDim2.fromOffset(16, 6), BackgroundTransparency = 1, Parent = Header})
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TitleRow})
local TitleText = mk("TextLabel", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "Hydra", TextColor3 = C.Text, Font = Enum.Font.GothamBlack, TextSize = 25, MaxVisibleGraphemes = 0, LayoutOrder = 1, Parent = TitleRow})
do local outline = TitleText:FindFirstChildOfClass("UIStroke") if outline then outline:Destroy() end end
-- efecto del nombre (el mismo de "Ultra" en la libreria): un brillo recorre las letras y descansa un momento
local TitleGradient = mk("UIGradient", {Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.65), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.65),
}), Offset = Vector2.new(-1, 0), Parent = TitleText})
TweenService:Create(TitleGradient, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.6), {Offset = Vector2.new(1, 0)}):Play()
-- entrada: el titulo se escribe letra por letra
task.spawn(function()
    for count = 1, #"Hydra" do
        TitleText.MaxVisibleGraphemes = count
        task.wait(0.06)
    end
    TitleText.MaxVisibleGraphemes = -1
end)

local HeaderSub = mk("TextLabel", {Size = UDim2.new(1, -196, 0, 14), Position = UDim2.fromOffset(16, 36), BackgroundTransparency = 1, Text = "", TextColor3 = C.Dim, Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Header})
local function headerButton(text, offset, image)
    local button = mk("TextButton", {Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, offset, 0, 28), BackgroundColor3 = C.Card, AutoButtonColor = false, Text = image and "" or text, TextColor3 = C.Dim, Font = Enum.Font.GothamBold, TextSize = 14, Parent = Header})
    corner(button, 999)
    stroke(button, C.Stroke, 0.3)
    if image then
        mk("ImageLabel", {Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Image = image, ImageColor3 = C.Dim, ScaleType = Enum.ScaleType.Fit, Parent = button})
    end
    return button
end
local HideButton = headerButton("\226\128\147", -46, "rbxassetid://81811812656965")
local CloseButton = headerButton("\226\156\149", -12, "rbxassetid://115244780748239")
-- chip de estado: la pelota que te persigue, en vivo
local Chip = mk("Frame", {Size = UDim2.fromOffset(108, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -82, 0, 28), BackgroundColor3 = C.Card, BorderSizePixel = 0, Parent = Header})
corner(Chip, 999)
local ChipStroke = stroke(Chip, C.Stroke, 0.3)
local ChipDot = mk("Frame", {Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), BackgroundColor3 = C.Dim, BorderSizePixel = 0, Parent = Chip})
corner(ChipDot, 999)
local ChipText = mk("TextLabel", {Size = UDim2.new(1, -26, 1, 0), Position = UDim2.fromOffset(22, 0), BackgroundTransparency = 1, Text = "", TextColor3 = C.Dim, Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Chip})

-- paginas
local Pages = mk("Frame", {Size = UDim2.new(1, -20, 1, -126), Position = UDim2.fromOffset(10, 60), BackgroundTransparency = 1, Parent = Window})

-- ==================== PESTANAS ABAJO EN CARRUSEL ====================
-- Carrusel: vuelta infinita,
-- arrastre con inercia, los iconos de los bordes se achican, giran un poco al moverse
-- y la pestana elegida se centra con animacion.
local TabBar = mk("Frame", {Size = UDim2.new(1, -16, 0, 54), Position = UDim2.new(0, 8, 1, -60), BackgroundColor3 = C.Card, BackgroundTransparency = BAR_ALPHA, BorderSizePixel = 0, ClipsDescendants = true, Parent = Window})
corner(TabBar, 16)
stroke(TabBar, C.Stroke, 0.2)
local Viewport = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Parent = TabBar})
for _, side in ipairs({0, 1}) do
    local fade = mk("Frame", {Size = UDim2.new(0, 30, 1, 0), AnchorPoint = Vector2.new(side, 0), Position = UDim2.fromScale(side, 0), BackgroundColor3 = C.Card, BackgroundTransparency = BAR_ALPHA, BorderSizePixel = 0, ZIndex = 5, Parent = TabBar})
    corner(fade, 16) -- mismas esquinas redondas que la barra, para que no sobresalgan
    mk("UIGradient", {Rotation = side == 0 and 0 or 180, Transparency = NumberSequence.new(0, 1), Parent = fade})
end

local TAB_SIZE, TAB_MIN_STEP = 48, 58
local Carousel = {items = {}, offset = 0, velocity = 0, viewW = 0, anim = nil, spin = 0, lastOffset = 0, step = TAB_MIN_STEP, press = nil}

local function renderCarousel()
    local count, viewW = #Carousel.items, Carousel.viewW
    if count == 0 or viewW <= 0 then return end
    local step = Carousel.step
    local length = count * step
    Carousel.offset = Carousel.offset % length
    local moved = ((Carousel.offset - Carousel.lastOffset + length / 2) % length) - length / 2
    Carousel.lastOffset = Carousel.offset
    Carousel.spin = math.clamp(Carousel.spin - moved * 0.6, -24, 24)
    for index, item in ipairs(Carousel.items) do
        local x = (((index - 1) * step - Carousel.offset + step) % length) - step
        item.button.Position = UDim2.new(0, x + step / 2, 0.5, 0)
        local d = math.clamp(math.abs((x + step / 2) - viewW / 2) / math.max(viewW / 2, 1), 0, 1)
        item.scale.Scale = 1 - 0.25 * math.clamp((d - 0.55) / 0.45, 0, 1)
        item.dist = d
        item.icon.Rotation = Carousel.spin * (0.6 + 0.8 * d)
    end
end

local function focusCarousel(name, animate)
    if Carousel.viewW <= 0 then return end
    local index
    for i, item in ipairs(Carousel.items) do
        if item.name == name then index = i break end
    end
    if not index then return end
    local length = #Carousel.items * Carousel.step
    local target = (index - 1) * Carousel.step + Carousel.step / 2 - Carousel.viewW / 2
    local delta = (target - Carousel.offset + length / 2) % length - length / 2
    Carousel.velocity = 0
    if animate then
        Carousel.anim = {from = Carousel.offset, to = Carousel.offset + delta, t0 = os.clock(), dur = 0.35}
    else
        Carousel.anim = nil
        Carousel.offset = Carousel.offset + delta
        renderCarousel()
    end
end

local Tabs, currentTab = {}, nil
local TabTitles = {Home = "Inicio", Settings = "Ajustes"}

local function relayoutCarousel()
    local scale = WindowScale.Scale
    if type(scale) ~= "number" or scale < 0.05 then scale = 1 end
    Carousel.viewW = Viewport.AbsoluteSize.X / scale
    local count = #Carousel.items
    -- el paso se estira para que la vuelta infinita nunca deje huecos visibles
    if count > 0 then Carousel.step = math.max(TAB_MIN_STEP, (Carousel.viewW + 2 * TAB_SIZE) / count) end
    Carousel.anim = nil
    Carousel.velocity = 0
    renderCarousel()
    if currentTab then focusCarousel(currentTab, false) end
end
track(Viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayoutCarousel))
Viewport.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
    Carousel.anim = nil
    Carousel.velocity = Carousel.velocity - input.Position.Z * 520
end)

local function selectTab(name)
    HeaderSub.Text = tr(TabTitles[name] or name)
    for tabName, tab in pairs(Tabs) do
        local on = tabName == name
        tab.page.Visible = on
        tween(tab.icon, 0.25, {[tab.iconProp] = on and C.Accent or C.Dim, [tab.iconProp == "ImageColor3" and "ImageTransparency" or "TextTransparency"] = on and 0 or 0.35})
        tween(tab.caption, 0.25, {TextColor3 = on and C.Accent or C.Dim, TextTransparency = on and 0 or 0.35})
        tween(tab.underline, 0.3, {Size = UDim2.fromOffset(on and 18 or 0, 3)}, Enum.EasingStyle.Back)
    end
    currentTab = name
    focusCarousel(name, true)
end

local function createTab(order, name, icon, caption)
    local button = mk("TextButton", {Size = UDim2.fromOffset(TAB_SIZE, 44), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C.Field, BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 2, Parent = Viewport})
    corner(button, 13)
    local buttonStroke = stroke(button, C.Stroke, 1)
    local underline = mk("Frame", {Size = UDim2.fromOffset(0, 3), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 2), BackgroundColor3 = C.Accent, BorderSizePixel = 0, ZIndex = 3, Parent = button})
    corner(underline, 99)
    local iconLabel, iconProp = mkIcon(icon, C.Dim, {Size = UDim2.fromOffset(22, 22), Position = UDim2.new(0.5, -11, 0, 4), ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = button},
        {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 3), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 17, ZIndex = 3, Parent = button})
    local captionLabel = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.fromOffset(0, 28), BackgroundTransparency = 1, Text = caption, TextColor3 = C.Dim, Font = Enum.Font.GothamBold, TextSize = 8, ZIndex = 3, Parent = button})
    local page = mk("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Accent, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, Parent = Pages,
    })
    mk("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page})
    mk("UIPadding", {PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 10), Parent = page})
    Tabs[name] = {button = button, icon = iconLabel, iconProp = iconProp, caption = captionLabel, stroke = buttonStroke, underline = underline, page = page, order = 0}
    local item = {name = name, button = button, icon = iconLabel, scale = mk("UIScale", {Scale = 1, Parent = button})}
    table.insert(Carousel.items, item)
    -- tocar sin arrastrar = elegir pestana; arrastrar = mover el carrusel
    button.InputBegan:Connect(function(input)
        local inputType = input.UserInputType
        if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then return end
        if Carousel.press then return end
        Carousel.anim, Carousel.velocity = nil, 0
        Carousel.press = {input = input, startX = input.Position.X, lastX = input.Position.X, lastT = os.clock(), moved = false, item = item}
    end)
    return Tabs[name]
end

track(UserInputService.InputChanged:Connect(function(input)
    local press = Carousel.press
    if not press then return end
    local pressType, inputType = press.input.UserInputType, input.UserInputType
    local matches = (inputType == Enum.UserInputType.MouseMovement and pressType == Enum.UserInputType.MouseButton1)
        or (inputType == Enum.UserInputType.Touch and pressType == Enum.UserInputType.Touch)
    if not matches then return end
    local x = input.Position.X
    if not press.moved and math.abs(x - press.startX) > 7 then press.moved = true end
    if press.moved then
        local now = os.clock()
        local dt = math.max(now - press.lastT, 1 / 240)
        local scale = (type(WindowScale.Scale) == "number" and WindowScale.Scale > 0.05) and WindowScale.Scale or 1
        local dx = (x - press.lastX) / scale
        Carousel.offset = Carousel.offset - dx
        Carousel.velocity = Carousel.velocity * 0.5 + (-dx / dt) * 0.5
        press.lastT = now
        renderCarousel()
    end
    press.lastX = x
end))
track(UserInputService.InputEnded:Connect(function(input)
    local press = Carousel.press
    if not press or input.UserInputType ~= press.input.UserInputType then return end
    Carousel.press = nil
    if press.moved then
        if os.clock() - press.lastT > 0.08 then Carousel.velocity = 0 end
    else
        selectTab(press.item.name)
    end
end))
track(RunService.Heartbeat:Connect(function(dt)
    if Carousel.spin ~= 0 then
        Carousel.spin = Carousel.spin * math.exp(-9 * dt)
        if math.abs(Carousel.spin) < 0.05 then Carousel.spin = 0 end
        for _, item in ipairs(Carousel.items) do item.icon.Rotation = Carousel.spin * (0.6 + 0.8 * (item.dist or 0)) end
    end
    if Carousel.press and Carousel.press.moved then return end
    local anim = Carousel.anim
    if anim then
        local t = math.min((os.clock() - anim.t0) / anim.dur, 1)
        Carousel.offset = anim.from + (anim.to - anim.from) * (1 - (1 - t) ^ 3)
        if t >= 1 then Carousel.anim = nil end
        renderCarousel()
    elseif math.abs(Carousel.velocity) > 8 then
        Carousel.offset = Carousel.offset + Carousel.velocity * dt
        Carousel.velocity = Carousel.velocity * math.exp(-4.2 * dt)
        renderCarousel()
    elseif Carousel.velocity ~= 0 then
        Carousel.velocity = 0
    end
end))

-- ---------- avisos tipo notificacion ----------
local ToastHolder = mk("Frame", {Size = UDim2.fromOffset(320, 0), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), BackgroundTransparency = 1, Parent = Gui})
mk("UIListLayout", {Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = ToastHolder})
local toastCount = 0
local function toast(text, color)
    toastCount = toastCount + 1
    local card = mk("Frame", {Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.Card, BorderSizePixel = 0, LayoutOrder = toastCount, Parent = ToastHolder})
    corner(card, 999)
    stroke(card, color or C.Stroke, 0.25)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = card})
    mk("TextLabel", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = text, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 12, Parent = card})
    local scale = mk("UIScale", {Scale = 0.85, Parent = card})
    tween(scale, 0.25, {Scale = 1}, Enum.EasingStyle.Back)
    task.delay(2.6, function()
        if card.Parent then card:Destroy() end
    end)
end

-- ---------- componentes ----------
local function nextOrder(tab) tab.order = tab.order + 1; return tab.order end

local function section(tab, text, icon)
    local row = mk("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = nextOrder(tab), Parent = tab.page})
    mkIcon(icon or "\226\128\162", C.Accent, {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(2, 5), ScaleType = Enum.ScaleType.Fit, Parent = row},
        {Size = UDim2.fromOffset(20, 26), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, Parent = row})
    mk("TextLabel", {Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(24, 0), BackgroundTransparency = 1, Text = text, TextColor3 = C.Text, Font = Enum.Font.GothamBlack, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
end

-- titulo (+ insignia RIESGO opcional) y subtitulo de una fila
local function labels(row, title, subtitle, x, right, risk)
    local line = mk("Frame", {Size = UDim2.new(1, -x - right, 0, 16), Position = UDim2.new(0, x, 0, subtitle and 9 or 12), BackgroundTransparency = 1, Parent = row})
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = line})
    mk("TextLabel", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = title, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 12, LayoutOrder = 1, Parent = line})
    if risk then
        local badge = mk("TextLabel", {Size = UDim2.fromOffset(46, 14), BackgroundColor3 = C.Warn, BackgroundTransparency = 0.82, Text = "RIESGO", TextColor3 = C.Warn, Font = Enum.Font.GothamBlack, TextSize = 8, LayoutOrder = 2, Parent = line})
        corner(badge, 999)
    end
    if subtitle then
        mk("TextLabel", {Size = UDim2.new(1, -x - right, 0, 14), Position = UDim2.new(0, x, 0, 27), BackgroundTransparency = 1, Text = subtitle, TextColor3 = C.Dim, Font = Enum.Font.GothamSemibold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
    end
end

-- PC: al pasar el mouse la fila se aclara un poco
local function hover(row)
    row.MouseEnter:Connect(function() tween(row, 0.15, {BackgroundTransparency = CARD_ALPHA - 0.06}) end)
    row.MouseLeave:Connect(function() tween(row, 0.2, {BackgroundTransparency = CARD_ALPHA}) end)
end

local function toggle(tab, key, title, subtitle, dotColor, onChange, risk)
    local row = mk("TextButton", {Size = UDim2.new(1, 0, 0, subtitle and 50 or 40), BackgroundColor3 = C.Glass, BackgroundTransparency = CARD_ALPHA, AutoButtonColor = false, Text = "", LayoutOrder = nextOrder(tab), Parent = tab.page})
    corner(row, 12)
    local rowStroke = stroke(row, C.Stroke, 0.5)
    hover(row)
    local x = 12
    if dotColor then
        local dot = mk("Frame", {Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 12, 0.5, -5), BackgroundColor3 = dotColor, BorderSizePixel = 0, Parent = row})
        corner(dot, 999)
        x = 30
    end
    labels(row, title, subtitle, x, 60, risk)
    local switch = mk("Frame", {Size = UDim2.fromOffset(40, 22), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), BackgroundColor3 = C.Off, BorderSizePixel = 0, Parent = row})
    corner(switch, 999)
    local knob = mk("Frame", {Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = switch})
    corner(knob, 999)
    local function paint(animate)
        local on = Config[key]
        local t = animate and 0.25 or 0
        tween(switch, t, {BackgroundColor3 = on and C.On or C.Off})
        tween(knob, t, {Position = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, Enum.EasingStyle.Back)
        tween(rowStroke, t, {Color = on and C.On or C.Stroke, Transparency = on and 0.35 or 0.5})
    end
    row.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        paint(true)
        saveConfig()
        if onChange then pcall(onChange, Config[key]) end
    end)
    paint(false)
end

local function slider(tab, key, title, minValue, maxValue, step, suffix, zeroText, onChange, subtitle)
    local row = mk("Frame", {Size = UDim2.new(1, 0, 0, subtitle and 66 or 58), BackgroundColor3 = C.Glass, BackgroundTransparency = CARD_ALPHA, BorderSizePixel = 0, LayoutOrder = nextOrder(tab), Parent = tab.page})
    corner(row, 12)
    stroke(row, C.Stroke, 0.5)
    labels(row, title, subtitle, 12, 90)
    local valueLabel = mk("TextLabel", {Size = UDim2.fromOffset(80, 16), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 9), BackgroundTransparency = 1, Text = "", TextColor3 = C.Accent, Font = Enum.Font.GothamBlack, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = row})
    local barY = subtitle and 48 or 38
    local bar = mk("Frame", {Size = UDim2.new(1, -24, 0, 6), Position = UDim2.fromOffset(12, barY), BackgroundColor3 = C.Field, BorderSizePixel = 0, Parent = row})
    corner(bar, 99)
    local fill = mk("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.Accent, BorderSizePixel = 0, Parent = bar})
    corner(fill, 99)
    local thumb = mk("Frame", {Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = bar})
    corner(thumb, 999)
    stroke(thumb, C.Accent, 0.2)
    local function paint()
        local value = Config[key]
        local alpha = math.clamp((value - minValue) / (maxValue - minValue), 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = (zeroText and value == minValue) and tr(zeroText) or (tostring(value) .. (suffix or ""))
    end
    local dragging = false
    local function setFrom(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        local value = minValue + (maxValue - minValue) * alpha
        value = math.floor(value / step + 0.5) * step
        if value ~= Config[key] then
            Config[key] = value
            paint()
            if onChange then pcall(onChange, value) end
        end
    end
    local hit = mk("TextButton", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, barY - 12), BackgroundTransparency = 1, Text = "", Parent = row})
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFrom(input.Position.X)
        end
    end)
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFrom(input.Position.X)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            saveConfig()
        end
    end))
    paint()
end

-- boton de accion (fila con icono a la derecha)
local function actionButton(tab, title, subtitle, icon, onClick, risk)
    local row = mk("TextButton", {Size = UDim2.new(1, 0, 0, subtitle and 50 or 40), BackgroundColor3 = C.Glass, BackgroundTransparency = CARD_ALPHA, AutoButtonColor = false, Text = "", LayoutOrder = nextOrder(tab), Parent = tab.page})
    corner(row, 12)
    stroke(row, C.Stroke, 0.5)
    labels(row, title, subtitle, 12, 52, risk)
    hover(row)
    local iconBox = mk("Frame", {Size = UDim2.fromOffset(30, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), BackgroundColor3 = C.Field, BorderSizePixel = 0, Parent = row})
    corner(iconBox, 9)
    local iconLabel, iconProp = mkIcon(icon or "\226\158\164", C.Accent, {Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0.5, -9, 0.5, -9), ScaleType = Enum.ScaleType.Fit, Parent = iconBox},
        {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, Parent = iconBox})
    row.MouseButton1Click:Connect(function()
        tween(iconBox, 0.08, {BackgroundColor3 = C.Accent})
        tween(iconLabel, 0.08, {[iconProp] = Color3.new(1, 1, 1)})
        task.delay(0.2, function()
            tween(iconBox, 0.3, {BackgroundColor3 = C.Field})
            tween(iconLabel, 0.3, {[iconProp] = C.Accent})
        end)
        if onClick then
            local ok, err = pcall(onClick)
            if not ok then toast("Error: " .. tostring(err), C.Accent) end
        end
    end)
end

-- desplegable (lista que se abre debajo de la fila)
local function dropdown(tab, title, subtitle, getOptions, onSelect)
    local row = mk("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = C.Glass, BackgroundTransparency = CARD_ALPHA, BorderSizePixel = 0, LayoutOrder = nextOrder(tab), Parent = tab.page})
    corner(row, 12)
    stroke(row, C.Stroke, 0.5)
    labels(row, title, subtitle, 12, 160)
    local pill = mk("TextButton", {Size = UDim2.fromOffset(144, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), BackgroundColor3 = C.Field, AutoButtonColor = false, Text = "", Parent = row})
    corner(pill, 10)
    stroke(pill, C.Stroke, 0.4)
    local pillText = mk("TextLabel", {Size = UDim2.new(1, -32, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = "\226\128\148", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = pill})
    local arrow = mk("TextLabel", {Size = UDim2.fromOffset(20, 30), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), BackgroundTransparency = 1, Text = "\226\150\190", TextColor3 = C.Dim, Font = Enum.Font.GothamBold, TextSize = 14, Parent = pill})
    local list = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Field, BorderSizePixel = 0, Visible = false, LayoutOrder = nextOrder(tab), Parent = tab.page})
    corner(list, 12)
    stroke(list, C.Stroke, 0.5)
    mk("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
    mk("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = list})
    local api = {value = nil}
    local function close()
        list.Visible = false
        arrow.Text = "\226\150\190"
    end
    local function open()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        local options = getOptions()
        if #options == 0 then
            mk("TextLabel", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "No hay nada para elegir", TextColor3 = C.Dim, Font = Enum.Font.GothamMedium, TextSize = 11, Parent = list})
        end
        for index, option in ipairs(options) do
            local selected = option.value == api.value
            local item = mk("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = selected and C.AccentSoft or C.Card, BackgroundTransparency = CARD_ALPHA, AutoButtonColor = false, Text = "", LayoutOrder = index, Parent = list})
            corner(item, 9)
            if option.color then
                local dot = mk("Frame", {Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, 10, 0.5, -4), BackgroundColor3 = option.color, BorderSizePixel = 0, Parent = item})
                corner(dot, 999)
            end
            mk("TextLabel", {Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(26, 0), BackgroundTransparency = 1, Text = option.text, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = item})
            item.MouseButton1Click:Connect(function()
                api.value = option.value
                pillText.Text = option.short or option.text
                close()
                if onSelect then pcall(onSelect, option.value) end
            end)
        end
        list.Visible = true
        arrow.Text = "\226\150\180"
    end
    pill.MouseButton1Click:Connect(function()
        if list.Visible then close() else open() end
    end)
    function api.clear()
        api.value = nil
        pillText.Text = "\226\128\148"
    end
    function api.set(value, text)
        api.value = value
        pillText.Text = text or "\226\128\148"
    end
    return api
end

local function infoCard(tab, rows)
    local card = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Glass, BackgroundTransparency = CARD_ALPHA, BorderSizePixel = 0, LayoutOrder = nextOrder(tab), Parent = tab.page})
    corner(card, 12)
    stroke(card, C.Stroke, 0.5)
    mk("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = card})
    mk("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card})
    local values = {}
    for index, title in ipairs(rows) do
        local line = mk("Frame", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = index, Parent = card})
        mk("TextLabel", {Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = title, TextColor3 = C.Dim, Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = line})
        values[title] = mk("TextLabel", {Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromScale(0.5, 0), BackgroundTransparency = 1, Text = "\226\128\148", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = line})
    end
    return values
end

local function note(tab, text)
    mk("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = text, TextColor3 = C.Dim, Font = Enum.Font.GothamSemibold, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(tab), Parent = tab.page})
end

-- ---------- pestanas y opciones ----------
local TabHome = createTab(1, "Home", "\226\140\130", "INICIO")
local TabSettings = createTab(2, "Settings", "\226\154\153", "AJUSTES")

-- INICIO
local Home = {start = os.clock(), frames = 0, acc = 0, fps = 0, bars = {}, history = {}, values = {}}
do
    local function service(name)
        local ok, found = pcall(function() return game:GetService(name) end)
        return ok and found or nil
    end
    Home.stats, Home.market, Home.teleport = service("Stats"), service("MarketplaceService"), service("TeleportService")

    -- tarjeta de bienvenida
    local hero = mk("Frame", {Size = UDim2.new(1, 0, 0, 108), BackgroundColor3 = C.Glass, BackgroundTransparency = CARD_ALPHA, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = nextOrder(TabHome), Parent = TabHome.page})
    corner(hero, 16)
    stroke(hero, C.Stroke, 0.45)
    -- franja de luz diagonal que cruza la tarjeta de vez en cuando
    local shine = mk("Frame", {Size = UDim2.new(0, 60, 2, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(-0.2, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.93, BorderSizePixel = 0, Parent = hero})
    mk("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = shine})
    TweenService:Create(shine, TweenInfo.new(2.4, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, -1, false, 3.5), {Position = UDim2.new(1.2, 0, 0.5, 0)}):Play()
    -- resplandor del acento en la esquina
    local glow = mk("Frame", {Size = UDim2.fromOffset(220, 220), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -20, 0, 0), BackgroundColor3 = C.Accent, BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = hero})
    corner(glow, 999)
    mk("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0.55), NumberSequenceKeypoint.new(1, 1)}), Rotation = 45, Parent = glow})

    -- avatar con anillo que gira
    local ring = mk("Frame", {Size = UDim2.fromOffset(70, 70), Position = UDim2.new(0, 16, 0.5, -35), BackgroundColor3 = C.Field, BorderSizePixel = 0, Parent = hero})
    corner(ring, 999)
    local ringStroke = mk("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2.5, Parent = ring})
    local ringGradient = mk("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C.Accent), ColorSequenceKeypoint.new(0.5, C.Field), ColorSequenceKeypoint.new(1, C.Accent)}), Rotation = 0, Parent = ringStroke})
    Home.ringGradient = ringGradient
    local avatar = mk("ImageLabel", {Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = C.AccentSoft, BorderSizePixel = 0, Image = "", ScaleType = Enum.ScaleType.Crop, Parent = ring})
    corner(avatar, 999)
    local online = mk("Frame", {Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), BackgroundColor3 = C.Good, BorderSizePixel = 0, ZIndex = 3, Parent = ring})
    corner(online, 999)
    mk("UIStroke", {Color = C.Card, Thickness = 2.5, Parent = online})
    task.spawn(function()
        local ok, image = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and type(image) == "string" and avatar.Parent then avatar.Image = image end
    end)

    -- saludo segun la hora
    local function greetingKey()
        local hour = tonumber(os.date("%H")) or 12
        if hour >= 6 and hour < 12 then return "Buenos d\195\173as" end
        if hour >= 12 and hour < 20 then return "Buenas tardes" end
        return "Buenas noches"
    end
    Home.greeting = mk("TextLabel", {Size = UDim2.new(1, -112, 0, 24), Position = UDim2.fromOffset(100, 20), BackgroundTransparency = 1, Text = "", TextColor3 = C.Text, Font = Enum.Font.GothamBlack, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = hero})
    mk("TextLabel", {Size = UDim2.new(1, -112, 0, 14), Position = UDim2.fromOffset(100, 45), BackgroundTransparency = 1, Text = "@" .. LocalPlayer.Name, TextColor3 = C.Dim, Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = hero})
    local function chip(x)
        local frame = mk("Frame", {Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.fromOffset(x, 68), BackgroundColor3 = C.AccentSoft, BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = hero})
        corner(frame, 999)
        mk("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = frame})
        mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 5), Parent = frame})
        local dot = mk("Frame", {Size = UDim2.fromOffset(6, 6), BackgroundColor3 = C.Accent, BorderSizePixel = 0, Parent = frame})
        corner(dot, 999)
        local label = mk("TextLabel", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "", TextColor3 = C.Accent, Font = Enum.Font.GothamBold, TextSize = 10, Parent = frame})
        return frame, label, dot
    end
    local onlineChip, onlineLabel = chip(100)
    Home.onlineLabel = onlineLabel
    local sessionChip, sessionLabel = chip(100)
    Home.sessionLabel = sessionLabel
    -- el segundo chip se acomoda al lado del primero
    local function placeChips() sessionChip.Position = UDim2.fromOffset(100 + onlineChip.AbsoluteSize.X / math.max(WindowScale.Scale, 0.05) + 6, 68) end
    track(onlineChip:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeChips))

    function Home.refreshTexts()
        Home.greeting.Text = tr(greetingKey()) .. ", " .. LocalPlayer.DisplayName
        onlineLabel.Text = tr("En l\195\173nea")
    end
    Home.refreshTexts()

    -- tarjetas de datos en vivo (2 x 2)
    section(TabHome, "Rendimiento", "\226\151\183")
    local grid = mk("Frame", {Size = UDim2.new(1, 0, 0, 144), BackgroundTransparency = 1, LayoutOrder = nextOrder(TabHome), Parent = TabHome.page})
    mk("UIGridLayout", {CellSize = UDim2.new(0.5, -4, 0, 68), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid})
    local function tile(order, caption, glyph)
        local card = mk("Frame", {BackgroundColor3 = C.Glass, BackgroundTransparency = CARD_ALPHA, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = order, Parent = grid})
        corner(card, 14)
        stroke(card, C.Stroke, 0.5)
        local badge = mk("Frame", {Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = C.AccentSoft, BorderSizePixel = 0, Parent = card})
        corner(badge, 7)
        mkIcon(glyph, C.Accent, {Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(4, 4), ScaleType = Enum.ScaleType.Fit, Parent = badge},
            {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, Parent = badge})
        mk("TextLabel", {Size = UDim2.new(1, -44, 0, 22), Position = UDim2.fromOffset(38, 10), BackgroundTransparency = 1, Text = caption, TextColor3 = C.Dim, Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
        local value = mk("TextLabel", {Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 36), BackgroundTransparency = 1, Text = "\226\128\148", TextColor3 = C.Text, Font = Enum.Font.GothamBlack, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = card})
        return card, value
    end
    local fpsCard
    fpsCard, Home.values.fps = tile(1, "FPS", "\226\151\183")
    _, Home.values.ping = tile(2, "Ping", "\226\151\142")
    _, Home.values.players = tile(3, "Jugadores", "\226\156\166")
    _, Home.values.uptime = tile(4, "Servidor abierto hace", "\226\150\162")
    -- mini grafico de FPS de los ultimos segundos
    local graph = mk("Frame", {Size = UDim2.fromOffset(66, 24), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -10), BackgroundTransparency = 1, Parent = fpsCard})
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = graph})
    for i = 1, 16 do
        local bar = mk("Frame", {Size = UDim2.new(0, 2, 0, 2), BackgroundColor3 = C.Accent, BackgroundTransparency = 0.25, BorderSizePixel = 0, LayoutOrder = i, Parent = graph})
        corner(bar, 2)
        Home.bars[i] = bar
    end

    -- datos de la partida
    section(TabHome, "Partida", "\226\156\142")
    Home.info = infoCard(TabHome, {"Juego", "Ejecutor", "Versi\195\179n"})
    Home.info["Versi\195\179n"].Text = "Hydra 1.0"
    do
        local name = "?"
        pcall(function()
            local a, b = identifyexecutor()
            name = tostring(a) .. (b and (" " .. tostring(b)) or "")
        end)
        Home.info["Ejecutor"].Text = name
    end
    task.spawn(function()
        local ok, product = pcall(function() return Home.market:GetProductInfo(game.PlaceId) end)
        local label = Home.info["Juego"]
        if label.Parent then label.Text = (ok and type(product) == "table" and product.Name) or tostring(game.PlaceId) end
    end)

    -- accesos rapidos
    section(TabHome, "Accesos r\195\161pidos", "\226\158\164")
    local quick = mk("Frame", {Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, LayoutOrder = nextOrder(TabHome), Parent = TabHome.page})
    mk("UIGridLayout", {CellSize = UDim2.new(1 / 3, -6, 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = quick})
    local function quickButton(order, glyph, caption, onClick)
        local button = mk("TextButton", {BackgroundColor3 = C.Glass, BackgroundTransparency = CARD_ALPHA, AutoButtonColor = false, Text = "", LayoutOrder = order, Parent = quick})
        corner(button, 14)
        local buttonStroke = stroke(button, C.Stroke, 0.5)
        hover(button)
        local scale = mk("UIScale", {Scale = 1, Parent = button})
        mkIcon(glyph, C.Accent, {Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0.5, -9, 0, 9), ScaleType = Enum.ScaleType.Fit, Parent = button},
            {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 7), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, Parent = button})
        mk("TextLabel", {Size = UDim2.new(1, -8, 0, 14), Position = UDim2.new(0, 4, 1, -20), BackgroundTransparency = 1, Text = caption, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = button})
        button.MouseButton1Down:Connect(function() tween(scale, 0.08, {Scale = 0.94}) end)
        button.MouseButton1Up:Connect(function() tween(scale, 0.3, {Scale = 1}, Enum.EasingStyle.Back) end)
        button.MouseLeave:Connect(function() tween(scale, 0.3, {Scale = 1}, Enum.EasingStyle.Back) end)
        button.MouseButton1Click:Connect(function()
            tween(buttonStroke, 0.08, {Color = C.Accent, Transparency = 0})
            task.delay(0.25, function() tween(buttonStroke, 0.4, {Color = C.Stroke, Transparency = 0.5}) end)
            local ok, err = pcall(onClick)
            if not ok then toast("Error: " .. tostring(err), C.Bad) end
        end)
    end
    quickButton(1, "\226\156\142", "Copiar servidor", function()
        local copy = setclipboard or toclipboard
        if type(copy) ~= "function" then toast(tr("Tu ejecutor no puede copiar"), C.Bad) return end
        copy(tostring(game.JobId))
        toast(tr("ID del servidor copiado"), C.Accent)
    end)
    quickButton(2, "\226\158\164", "Reentrar", function()
        toast(tr("Reentrando..."), C.Accent)
        local ok = pcall(function() Home.teleport:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
        if not ok then toast(tr("No se pudo reentrar"), C.Bad) end
    end)
    quickButton(3, "\226\154\153", "Idioma", function() selectTab("Settings") end)
end

-- datos en vivo: FPS siempre (chip de la cabecera); el resto solo con la pestana Inicio abierta
local function fpsColor(fps)
    if fps >= 50 then return C.Good end
    if fps >= 30 then return C.Mid end
    return C.Bad
end
local function clockText(seconds)
    seconds = math.max(0, math.floor(seconds))
    local h, m, sec = math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, sec) end
    return string.format("%02d:%02d", m, sec)
end
track(RunService.Heartbeat:Connect(function(dt)
    Home.frames = Home.frames + 1
    Home.acc = Home.acc + dt
    if Home.ringGradient and Window.Visible then Home.ringGradient.Rotation = (Home.ringGradient.Rotation + dt * 90) % 360 end
    if Home.acc < 0.5 then return end
    Home.fps = math.floor(Home.frames / Home.acc + 0.5)
    Home.frames, Home.acc = 0, 0
    table.insert(Home.history, Home.fps)
    if #Home.history > #Home.bars then table.remove(Home.history, 1) end
    if not Window.Visible then return end
    local color = fpsColor(Home.fps)
    ChipText.Text = Home.fps .. " FPS"
    ChipText.TextColor3 = color
    ChipDot.BackgroundColor3 = color
    ChipStroke.Color = color
    if currentTab ~= "Home" then return end
    Home.values.fps.Text = Home.fps .. " FPS"
    Home.values.fps.TextColor3 = color
    for i, bar in ipairs(Home.bars) do
        local value = Home.history[#Home.history - #Home.bars + i]
        bar.Size = UDim2.new(0, 2, 0, value and math.clamp(math.floor(value / 60 * 24), 2, 24) or 2)
        bar.BackgroundColor3 = value and fpsColor(value) or C.Off
    end
    local ping
    pcall(function() ping = math.floor(Home.stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
    Home.values.ping.Text = ping and (ping .. " ms") or "\226\128\148"
    Home.values.ping.TextColor3 = not ping and C.Text or (ping < 120 and C.Good or (ping < 250 and C.Mid or C.Bad))
    Home.values.players.Text = #Players:GetPlayers() .. " / " .. tostring(Players.MaxPlayers)
    Home.values.uptime.Text = clockText(workspace.DistributedGameTime)
    Home.sessionLabel.Text = tr("Sesi\195\179n") .. " " .. clockText(os.clock() - Home.start)
end))

-- AJUSTES
section(TabSettings, "Idioma", "\226\156\142")
local LANGUAGE_NAMES = {auto = "Autom\195\161tico", es = "Espa\195\177ol", en = "English"}
local LanguagePicker = dropdown(TabSettings, "Idioma", "Autom\195\161tico = el idioma de tu Roblox", function()
    return {
        {value = "auto", text = tr("Autom\195\161tico")},
        {value = "es", text = "Espa\195\177ol"},
        {value = "en", text = "English"},
    }
end, function(value)
    Config.language = value
    saveConfig()
    applyLanguage()
end)
LanguagePicker.set(Config.language, tr(LANGUAGE_NAMES[Config.language] or "Autom\195\161tico"))
section(TabSettings, "Ventana", "\226\150\162")
note(TabSettings, "Bot\195\179n \226\128\147 : esconde la ventana. Toc\195\161 el bot\195\179n flotante para volver a abrirla. En PC tambi\195\169n con la tecla K. La \226\156\149 cierra el script.")

relayoutCarousel()
selectTab("Home")
-- al cambiar el idioma: titulo de la pestana y nombres elegidos
Lang.onChange = function()
    if currentTab then HeaderSub.Text = tr(TabTitles[currentTab] or currentTab) end
    Home.refreshTexts()
    LanguagePicker.set(Config.language, tr(LANGUAGE_NAMES[Config.language] or "Autom\195\161tico"))
end

-- ---------- boton flotante para reabrir ----------
local Bubble = mk("TextButton", {Size = UDim2.fromOffset(73, 73), Position = UDim2.new(0, 16, 0.5, -36), BackgroundColor3 = C.Accent, AutoButtonColor = false, Text = "H", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 22, Visible = false, Parent = Gui})
corner(Bubble, 999)
local BubbleStroke = stroke(Bubble, Color3.new(1, 1, 1), 0.6)
-- logo del boton flotante; mientras no cargue (o si falla) se queda la H
local BubbleLogo = mk("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://114974832117287", ScaleType = Enum.ScaleType.Crop, Parent = Bubble})
corner(BubbleLogo, 999)
-- con logo se ve solo la imagen, sin circulo ni borde. Si el logo no carga a los 5 s de aparecer el boton, vuelve la H con su circulo.
if BubbleLogo.Image ~= "" then
    Bubble.Text = ""
    Bubble.BackgroundTransparency = 1
    BubbleStroke.Transparency = 1
    local checked = false
    Bubble:GetPropertyChangedSignal("Visible"):Connect(function()
        if checked or not Bubble.Visible then return end
        checked = true
        task.delay(5, function()
            -- si el logo no carga, solo se muestra la H (sin circulo de fondo)
            if Bubble.Parent and not BubbleLogo.IsLoaded then Bubble.Text = "H" end
        end)
    end)
end

local function setWindowVisible(visible)
    if visible then
        Window.Visible = true
        Bubble.Visible = false
        WindowScale.Scale = 0.9
        tween(WindowScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back)
    else
        tween(WindowScale, 0.15, {Scale = 0.9})
        task.delay(0.15, function()
            Window.Visible = false
            Bubble.Visible = true
        end)
    end
end
HideButton.MouseButton1Click:Connect(function() setWindowVisible(false) end)

-- arrastrar (ventana desde la cabecera y burbuja)
local function draggable(handle, target, onTap)
    local dragging, dragStart, startPos, moved = false, nil, nil, false
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos, moved = true, input.Position, target.Position, false
        end
    end)
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then moved = true end
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not moved and onTap then onTap() end
        end
    end))
end
draggable(Header, Window)
draggable(Bubble, Bubble, function() setWindowVisible(true) end)

track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.K then setWindowVisible(not Window.Visible) end
end))

-- ==================== ARRANQUE Y CIERRE ====================
CloseButton.MouseButton1Click:Connect(function()
    for _, connection in ipairs(Connections) do pcall(function() connection:Disconnect() end) end
    tween(WindowScale, 0.18, {Scale = 0.85})
    task.delay(0.2, function()
        Gui:Destroy()
    end)
    loadConfig() -- se recupera la configuracion guardada (para la proxima vez), sin aplicarla
end)

-- ==================== HYDRA: API PARA USAR LA LIBRERIA DESDE AFUERA ====================
-- local Hydra = loadstring(...)()
-- local Tab = Hydra:Tab({Title = "Movimiento", Caption = "MOVER", Icon = "rbxassetid://..."})
-- Tab:Section("Salto", icono)
-- local Bhop = Tab:Toggle({Id = "bhop", Title = "Bunny Hop", Desc = "...", Icon = "rbxassetid://...", Default = false,
--     Keybind = true, Floating = true, Callback = function(on) end})
-- Bhop:Slider({Id = "bhopAccel", Title = "Aceleracion", Min = -3, Max = 0, Step = 0.1, Default = -0.2, Suffix = "", Callback = function(v) end})
-- Bhop:Toggle({Id = "bhopHold", Title = "Mantener salto", Callback = function(on) end})   -- sub-opciones dentro del desplegable
-- Tab:Slider({...})  -- slider suelto, misma forma
-- Cada opcion devuelve :Set(valor), :Get() y guarda su valor solo (Config.flags).
local Hydra = {Options = {}, Binds = {}, Floats = {}}
Config.flags, Config.binds, Config.floats = Config.flags or {}, Config.binds or {}, Config.floats or {}

local function keyName(code)
    if not code then return "\226\128\148" end
    local name = tostring(code.Name or code)
    local short = {LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl", LeftAlt = "LAlt", RightAlt = "RAlt", Space = "Space"}
    return short[name] or name
end

function Hydra.formatValue(value, step)
    local decimals = 0
    local text = tostring(step or 1)
    local dot = string.find(text, "%.")
    if dot then decimals = #text - dot end
    return string.format("%." .. decimals .. "f", value)
end

-- pestana nueva: queda antes de Ajustes en el carrusel
function Hydra:Tab(info)
    local name = info.Id or info.Title
    TabTitles[name] = info.Title
    local tab = createTab(0, name, info.Icon or "\226\156\166", info.Caption or string.upper(info.Title))
    local last = table.remove(Carousel.items)
    local at = #Carousel.items + 1
    for i, item in ipairs(Carousel.items) do
        if item.name == "Settings" then at = i break end
    end
    table.insert(Carousel.items, at, last)
    relayoutCarousel()
    local api = {raw = tab}
    function api:Section(title, icon) section(tab, title, icon or "\226\128\162") end
    function api:Note(text) note(tab, text) end
    function api:Toggle(o) return Hydra.toggle(tab.page, function() return nextOrder(tab) end, o, false) end
    function api:Slider(o) return Hydra.slider(tab.page, function() return nextOrder(tab) end, o, false) end
    function api:Button(o) return Hydra.button(tab.page, function() return nextOrder(tab) end, o, false) end
    function api:Dropdown(o) return Hydra.dropdown(tab.page, function() return nextOrder(tab) end, o, false) end
    function api:PlayerSearch(o) return Hydra.playerSearch(tab.page, function() return nextOrder(tab) end, o) end
    return api
end

-- ---------- slider ----------
function Hydra.slider(parent, order, o, nested)
    local minValue, maxValue, step = o.Min or 0, o.Max or 100, o.Step or 1
    local default = math.clamp(o.Default or minValue, minValue, maxValue)
    local id = o.Id or o.Title
    local value = tonumber(Config.flags[id]) or default
    local card = mk("Frame", {Size = UDim2.new(1, 0, 0, o.Desc and 76 or 64), BackgroundColor3 = C.Glass, BackgroundTransparency = nested and 0.94 or CARD_ALPHA, BorderSizePixel = 0, LayoutOrder = order(), Parent = parent})
    corner(card, nested and 11 or 14)
    stroke(card, C.Stroke, nested and 0.65 or 0.5)
    mk("TextLabel", {Size = UDim2.new(1, -150, 0, 16), Position = UDim2.fromOffset(14, 10), BackgroundTransparency = 1, Text = o.Title, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
    if o.Desc then
        mk("TextLabel", {Size = UDim2.new(1, -150, 0, 13), Position = UDim2.fromOffset(14, 27), BackgroundTransparency = 1, Text = o.Desc, TextColor3 = C.Dim, Font = Enum.Font.GothamSemibold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
    end
    -- caja del valor (se puede escribir) + boton de reset
    local box = mk("Frame", {Size = UDim2.fromOffset(74, 24), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 9), BackgroundColor3 = C.Bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = card})
    corner(box, 8)
    local boxStroke = stroke(box, C.Stroke, 0.5)
    local input = mk("TextBox", {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(5, 0), BackgroundTransparency = 1, Text = "", TextColor3 = C.Accent, Font = Enum.Font.GothamBlack, TextSize = 12, ClearTextOnFocus = false, Parent = box})
    local reset = mk("TextButton", {Size = UDim2.fromOffset(44, 20), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -92, 0, 11), BackgroundColor3 = C.AccentSoft, BackgroundTransparency = 1, AutoButtonColor = false, Text = "Reset", TextColor3 = C.Accent, TextTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 9, Parent = card})
    corner(reset, 999)
    local barY = o.Desc and 52 or 42
    local bar = mk("Frame", {Size = UDim2.new(1, -28, 0, 6), Position = UDim2.fromOffset(14, barY), BackgroundColor3 = C.Off, BorderSizePixel = 0, Parent = card})
    corner(bar, 99)
    local fill = mk("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = bar})
    corner(fill, 99)
    mk("UIGradient", {Color = ColorSequence.new(C.AccentDark, C.Accent), Parent = fill})
    local thumb = mk("Frame", {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C.Bg, BorderSizePixel = 0, ZIndex = 3, Parent = bar})
    corner(thumb, 999)
    local thumbStroke = mk("UIStroke", {Color = C.Accent, Thickness = 2.5, Parent = thumb})
    local halo = mk("Frame", {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2, Parent = thumb})
    corner(halo, 999)
    -- globito con el valor mientras arrastras
    local bubble = mk("Frame", {Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -8), BackgroundColor3 = C.Accent, BorderSizePixel = 0, Visible = false, ZIndex = 6, Parent = thumb})
    corner(bubble, 8)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = bubble})
    local bubbleText = mk("TextLabel", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "", TextColor3 = C.Bg, Font = Enum.Font.GothamBlack, TextSize = 11, ZIndex = 7, Parent = bubble})
    mk("Frame", {Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, 0), Rotation = 45, BackgroundColor3 = C.Accent, BorderSizePixel = 0, ZIndex = 6, Parent = bubble})
    local bubbleScale = mk("UIScale", {Scale = 0.6, Parent = bubble})

    local obj = {Type = "Slider", Id = id}
    local function paint(animate)
        local alpha = (maxValue == minValue) and 0 or math.clamp((value - minValue) / (maxValue - minValue), 0, 1)
        local t = animate and 0.12 or 0
        tween(fill, t, {Size = UDim2.new(alpha, 0, 1, 0)})
        tween(thumb, t, {Position = UDim2.new(alpha, 0, 0.5, 0)})
        local text = Hydra.formatValue(value, step) .. (o.Suffix or "")
        if not input:IsFocused() then input.Text = text end
        bubbleText.Text = text
        local changed = math.abs(value - default) > step / 2
        tween(reset, 0.2, {BackgroundTransparency = changed and 0.2 or 1, TextTransparency = changed and 0 or 1})
        reset.Active = changed
    end
    function obj:Set(newValue, silent)
        newValue = tonumber(newValue)
        if not newValue then paint(true) return end
        newValue = math.clamp(math.floor((newValue - minValue) / step + 0.5) * step + minValue, minValue, maxValue)
        local changed = newValue ~= value
        value = newValue
        Config.flags[id] = value
        paint(true)
        if changed then
            saveConfig()
            if o.Callback and not silent then pcall(o.Callback, value) end
        end
    end
    function obj:Get() return value end

    local dragging = false
    local function setFrom(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        obj:Set(minValue + (maxValue - minValue) * alpha)
    end
    local function grab(on)
        dragging = on
        bubble.Visible = true
        tween(bubbleScale, on and 0.18 or 0.12, {Scale = on and 1 or 0.6}, on and Enum.EasingStyle.Back or Enum.EasingStyle.Quad)
        tween(halo, 0.18, {Size = on and UDim2.fromOffset(34, 34) or UDim2.fromOffset(18, 18), BackgroundTransparency = on and 0.75 or 1})
        tween(thumbStroke, 0.18, {Thickness = on and 3.5 or 2.5})
        if not on then task.delay(0.12, function() if not dragging then bubble.Visible = false end end) end
    end
    local hit = mk("TextButton", {Size = UDim2.new(1, -14, 0, 30), Position = UDim2.fromOffset(7, barY - 12), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = card})
    hit.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            grab(true)
            setFrom(inp.Position.X)
        end
    end)
    track(UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then setFrom(inp.Position.X) end
    end))
    track(UserInputService.InputEnded:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then grab(false) end
    end))
    input.Focused:Connect(function()
        tween(boxStroke, 0.15, {Color = C.Accent, Transparency = 0})
        input.Text = Hydra.formatValue(value, step)
    end)
    input.FocusLost:Connect(function()
        tween(boxStroke, 0.2, {Color = C.Stroke, Transparency = 0.5})
        local typed = tonumber((string.gsub(input.Text, ",", ".")))
        if typed then obj:Set(typed) else paint(false) end
        input.Text = Hydra.formatValue(value, step) .. (o.Suffix or "")
    end)
    reset.MouseButton1Click:Connect(function()
        if reset.Active then obj:Set(default) end
    end)
    paint(false)
    Hydra.Options[id] = obj
    return obj
end

-- ---------- boton flotante de un toggle ----------
-- Pastilla de vidrio oscuro: el fondo tiene un brillo que gira despacio, el borde una luz que lo recorre
-- y el nombre un destello que lo cruza (como el titulo). Prendido = todo mas intenso; apagado = tenue.
Hydra.FloatFx = {}
track(RunService.Heartbeat:Connect(function(dt)
    for pill, fx in pairs(Hydra.FloatFx) do
        if not pill.Parent then
            Hydra.FloatFx[pill] = nil
        else
            fx.angle = (fx.angle + dt * (fx.on and 40 or 18)) % 360
            fx.border.Rotation = fx.angle
            fx.bg.Rotation = (360 - fx.angle * 0.5) % 360
        end
    end
end))
-- deja un boton flotante siempre adentro de la pantalla (x, y = esquina de arriba a la izquierda, en pixeles)
function Hydra.placeOnScreen(pill, x, y)
    local screen, size = Gui.AbsoluteSize, pill.AbsoluteSize
    if screen.X <= 0 or screen.Y <= 0 then return end
    local margin = 6
    x = math.clamp(x, margin, math.max(margin, screen.X - size.X - margin))
    y = math.clamp(y, margin, math.max(margin, screen.Y - size.Y - margin))
    pill.Position = UDim2.fromOffset(x, y)
end
-- si cambia el tamano de la pantalla (o del boton), vuelve a meterlos adentro
track(Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    for _, pill in pairs(Hydra.Floats) do
        if pill.Parent then Hydra.placeOnScreen(pill, pill.Position.X.Offset, pill.Position.Y.Offset) end
    end
end))
function Hydra.floatButton(obj, o)
    local id = obj.Id
    if Hydra.Floats[id] then
        Hydra.Floats[id]:Destroy()
        Hydra.Floats[id] = nil
        Config.floats[id] = nil
        saveConfig()
        return false
    end
    local saved = Config.floats[id]
    local pill = mk("TextButton", {Size = UDim2.fromOffset(0, 42), AutomaticSize = Enum.AutomaticSize.X, Position = (type(saved) == "table" and saved.x) and UDim2.fromOffset(saved.x, saved.y) or UDim2.fromOffset(Gui.AbsoluteSize.X / 2 - 70, Gui.AbsoluteSize.Y * 0.18),
        BackgroundColor3 = Color3.fromRGB(10, 11, 15), BackgroundTransparency = 0.45, AutoButtonColor = false, Text = "", Parent = Gui})
    corner(pill, 999)
    -- fondo: una capa con un brillo plateado muy suave que gira lento (va debajo del contenido)
    local sheen = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, BorderSizePixel = 0, Parent = pill})
    corner(sheen, 999)
    local bg = mk("UIGradient", {Transparency = NumberSequence.new(0.93), Parent = sheen})
    -- borde: una luz que recorre el contorno
    local border = mk("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 1.6, Transparency = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = pill})
    local borderGradient = mk("UIGradient", {Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 64, 76)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 64, 76)),
    }), Parent = border})
    local content = mk("Frame", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 2, Parent = pill})
    mk("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 18), Parent = content})
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content})
    -- icono suelto, sin fondo
    local icon, iconProp = mkIcon(o.Icon or "\226\156\166", C.Dim, {Size = UDim2.fromOffset(18, 18), ScaleType = Enum.ScaleType.Fit, LayoutOrder = 1, Parent = content},
        {Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15, LayoutOrder = 1, Parent = content})
    -- nombre con destello que lo cruza
    local label = mk("TextLabel", {Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = o.Title, TextColor3 = C.Text, Font = Enum.Font.GothamBlack, TextSize = 13, LayoutOrder = 2, Parent = content})
    local shine = mk("UIGradient", {Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.45),
    }), Offset = Vector2.new(-1, 0), Parent = label})
    local shineTween = TweenService:Create(shine, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.9), {Offset = Vector2.new(1, 0)})
    -- puntito de estado a la derecha
    local dot = mk("Frame", {Size = UDim2.fromOffset(7, 7), BackgroundColor3 = C.Off, BorderSizePixel = 0, LayoutOrder = 3, Parent = content})
    corner(dot, 999)
    local fx = {angle = math.random(0, 359), border = borderGradient, bg = bg, on = false}
    Hydra.FloatFx[pill] = fx
    local function paint(animate)
        local on = obj:Get()
        fx.on = on
        local t = animate and 0.45 or 0
        tween(pill, t, {BackgroundTransparency = on and 0.38 or 0.5})
        bg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, on and 0.78 or 0.9), NumberSequenceKeypoint.new(1, 1),
        })
        tween(border, t, {Thickness = on and 2 or 1.4, Transparency = on and 0 or 0.45})
        tween(icon, t, {[iconProp] = on and C.Accent or C.Dim})
        tween(label, t, {TextColor3 = on and C.Text or C.Dim})
        tween(dot, t, {BackgroundColor3 = on and C.Accent or C.Off, Size = on and UDim2.fromOffset(8, 8) or UDim2.fromOffset(7, 7)})
        if on then
            shineTween:Play()
        else
            shineTween:Cancel()
            shine.Offset = Vector2.new(-1, 0)
        end
    end
    obj._floatPaint = function() paint(true) end
    paint(false)
    local dragStart, startPos, moved
    pill.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragStart, startPos, moved = inp.Position, pill.Position, false
        end
    end)
    track(UserInputService.InputChanged:Connect(function(inp)
        if dragStart and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragStart
            if delta.Magnitude > 6 then moved = true end
            if moved then Hydra.placeOnScreen(pill, startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y) end
        end
    end))
    track(UserInputService.InputEnded:Connect(function(inp)
        if dragStart and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
            dragStart = nil
            if moved then
                Config.floats[id] = {x = pill.AbsolutePosition.X, y = pill.AbsolutePosition.Y}
                saveConfig()
            else
                obj:Set(not obj:Get())
            end
        end
    end))
    Hydra.Floats[id] = pill
    pill:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() Hydra.placeOnScreen(pill, pill.Position.X.Offset, pill.Position.Y.Offset) end)
    task.defer(function() if pill.Parent then Hydra.placeOnScreen(pill, pill.Position.X.Offset, pill.Position.Y.Offset) end end)
    if not (type(saved) == "table" and saved.x) then Config.floats[id] = {} saveConfig() end
    return true
end

-- ---------- toggle ----------
function Hydra.toggle(parent, order, o, nested)
    local id = o.Id or o.Title
    local state = Config.flags[id]
    if type(state) ~= "boolean" then state = o.Default == true end
    local obj = {Type = "Toggle", Id = id}
    local card = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Glass, BackgroundTransparency = nested and 0.94 or CARD_ALPHA, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = order(), Parent = parent})
    corner(card, nested and 11 or 14)
    local cardStroke = stroke(card, C.Stroke, nested and 0.65 or 0.5)
    mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = card})
    local headH = nested and 44 or (o.Desc and 60 or 52)
    local head = mk("TextButton", {Size = UDim2.new(1, 0, 0, headH), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", LayoutOrder = 1, Parent = card})
    -- barrita de acento a la izquierda (crece al prender)
    local glowBar = mk("Frame", {Size = UDim2.fromOffset(3, 0), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C.Accent, BorderSizePixel = 0, Parent = head})
    corner(glowBar, 99)
    local x = 14
    local badge, icon, iconProp
    if not nested then
        badge = mk("Frame", {Size = UDim2.fromOffset(34, 34), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), BackgroundColor3 = C.AccentSoft, BorderSizePixel = 0, Parent = head})
        corner(badge, 10)
        icon, iconProp = mkIcon(o.Icon or "\226\156\166", C.Accent, {Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(8, 8), ScaleType = Enum.ScaleType.Fit, Parent = badge},
            {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15, Parent = badge})
        x = 56
    end
    -- lado derecho: switch, tecla, flotante y flechita (de derecha a izquierda)
    local right = mk("Frame", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), BackgroundTransparency = 1, Parent = head})
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = right})
    local switch = mk("Frame", {Size = UDim2.fromOffset(44, 24), BackgroundColor3 = C.Off, BorderSizePixel = 0, LayoutOrder = 10, Parent = right})
    corner(switch, 999)
    local switchGradient = mk("UIGradient", {Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)), Rotation = 90, Parent = switch})
    local knob = mk("Frame", {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = switch})
    corner(knob, 999)
    local knobShadow = mk("UIStroke", {Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.75, Parent = knob})
    local miniButtons = {}
    local function mini(orderIndex, width)
        local b = mk("TextButton", {Size = UDim2.fromOffset(width or 26, 24), BackgroundColor3 = C.Bg, BackgroundTransparency = 0.35, AutoButtonColor = false, Text = "", LayoutOrder = orderIndex, Parent = right})
        corner(b, 8)
        local s = stroke(b, C.Stroke, 0.55)
        b.MouseEnter:Connect(function() tween(s, 0.15, {Color = C.Accent, Transparency = 0.2}) end)
        b.MouseLeave:Connect(function() tween(s, 0.2, {Color = C.Stroke, Transparency = 0.55}) end)
        miniButtons[#miniButtons + 1] = b
        return b, s
    end
    -- tecla de atajo (PC)
    local bindButton
    if o.Keybind and not nested then
        local b = mini(5, 0)
        b.AutomaticSize = Enum.AutomaticSize.X
        mk("UIPadding", {PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7), Parent = b})
        b.TextColor3, b.Font, b.TextSize = C.Dim, Enum.Font.GothamBold, 10
        local saved = Config.binds[id]
        local code = saved and Enum.KeyCode[saved] or nil
        Hydra.Binds[id] = {code = code, obj = obj, title = o.Title}
        if Hydra.refreshKeys then task.defer(Hydra.refreshKeys) end
        b.Text = keyName(code)
        bindButton = b
        b.MouseButton1Click:Connect(function()
            Hydra.listening = {id = id, button = b}
            b.Text = "..."
            b.TextColor3 = C.Accent
        end)
    end
    -- boton para sacarlo flotando (dibujo de una ventanita)
    local floatButton
    if o.Floating and not nested then
        local b = mini(4, 26)
        local frameIcon = mk("Frame", {Size = UDim2.fromOffset(12, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -1, 0.5, 1), BackgroundTransparency = 1, Parent = b})
        corner(frameIcon, 3)
        local fiStroke = mk("UIStroke", {Color = C.Dim, Thickness = 1.5, Parent = frameIcon})
        local corner2 = mk("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.new(1, -3, 0, -3), BackgroundColor3 = C.Dim, BorderSizePixel = 0, Parent = frameIcon})
        corner(corner2, 2)
        floatButton = {button = b, stroke = fiStroke, dot = corner2}
        b.MouseButton1Click:Connect(function()
            local on = Hydra.floatButton(obj, o)
            tween(fiStroke, 0.2, {Color = on and C.Accent or C.Dim})
            tween(corner2, 0.2, {BackgroundColor3 = on and C.Accent or C.Dim})
        end)
    end
    -- desplegable de sub-opciones
    local options, chevron
    local function ensureOptions()
        if options then return options end
        options = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 2, Parent = card})
        mk("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = options})
        mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = options})
        local line = mk("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = 0, Parent = options})
        mk("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = line})
        local b = mini(6, 26)
        chevron = mk("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "\226\128\186", TextColor3 = C.Dim, Font = Enum.Font.GothamBlack, TextSize = 18, Rotation = 90, Parent = b})
        b.MouseButton1Click:Connect(function()
            options.Visible = not options.Visible
            tween(chevron, 0.25, {Rotation = options.Visible and 270 or 90, TextColor3 = options.Visible and C.Accent or C.Dim})
        end)
        return options
    end
    -- textos
    local textArea = mk("Frame", {Size = UDim2.new(1, -x - 12, 1, 0), Position = UDim2.fromOffset(x, 0), BackgroundTransparency = 1, Parent = head})
    local titleLabel = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 0.5, o.Desc and -15 or -8), BackgroundTransparency = 1, Text = o.Title, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = nested and 12 or 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = textArea})
    if o.Desc then
        mk("TextLabel", {Size = UDim2.new(1, 0, 0, 13), Position = UDim2.new(0, 0, 0.5, 3), BackgroundTransparency = 1, Text = o.Desc, TextColor3 = C.Dim, Font = Enum.Font.GothamSemibold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = textArea})
    end
    -- el texto no se mete debajo de los botones de la derecha
    local function fitText()
        local scale = (type(WindowScale.Scale) == "number" and WindowScale.Scale > 0.05) and WindowScale.Scale or 1
        textArea.Size = UDim2.new(1, -x - 18 - right.AbsoluteSize.X / scale, 1, 0)
    end
    right:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitText)

    local function paint(animate)
        local t = animate and 0.25 or 0
        tween(switch, t, {BackgroundColor3 = state and C.On or C.Off})
        switchGradient.Enabled = state
        tween(knob, t, {Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = state and C.Bg or Color3.new(1, 1, 1)}, Enum.EasingStyle.Back)
        if animate then
            tween(knob, 0.1, {Size = UDim2.fromOffset(23, 16)})
            task.delay(0.1, function() tween(knob, 0.2, {Size = UDim2.fromOffset(18, 18)}, Enum.EasingStyle.Back) end)
        end
        knobShadow.Transparency = state and 0.6 or 0.75
        tween(cardStroke, t, {Color = state and C.Accent or C.Stroke, Transparency = state and 0.35 or (nested and 0.65 or 0.5)})
        tween(glowBar, t, {Size = UDim2.fromOffset(3, state and headH - 22 or 0)})
        tween(titleLabel, t, {TextColor3 = state and C.Text or C.Text})
        if badge then
            tween(badge, t, {BackgroundColor3 = state and C.Accent or C.AccentSoft})
            tween(icon, t, {[iconProp] = state and C.Bg or C.Accent})
        end
        if obj._floatPaint then pcall(obj._floatPaint) end
    end
    function obj:Set(newState, silent)
        newState = newState == true
        if newState == state then return end
        state = newState
        Config.flags[id] = state
        saveConfig()
        paint(true)
        if o.Callback and not silent then pcall(o.Callback, state) end
    end
    function obj:Get() return state end
    function obj:Toggle(sub) return Hydra.toggle(ensureOptions(), function() return #options:GetChildren() + 1 end, sub, true) end
    function obj:Slider(sub) return Hydra.slider(ensureOptions(), function() return #options:GetChildren() + 1 end, sub, true) end
    function obj:Button(sub) return Hydra.button(ensureOptions(), function() return #options:GetChildren() + 1 end, sub, true) end
    function obj:Dropdown(sub) return Hydra.dropdown(ensureOptions(), function() return #options:GetChildren() + 1 end, sub, true) end
    function obj:Open(open)
        local opts = ensureOptions()
        opts.Visible = open ~= false
        chevron.Rotation = opts.Visible and 270 or 90
    end

    head.MouseButton1Click:Connect(function() obj:Set(not state) end)
    head.MouseEnter:Connect(function() tween(card, 0.15, {BackgroundTransparency = (nested and 0.94 or CARD_ALPHA) - 0.06}) end)
    head.MouseLeave:Connect(function() tween(card, 0.2, {BackgroundTransparency = nested and 0.94 or CARD_ALPHA}) end)
    paint(false)
    task.defer(fitText)
    Hydra.Options[id] = obj
    -- si el valor guardado estaba prendido, se avisa al script al arrancar
    if state and o.Callback then task.defer(function() pcall(o.Callback, true) end) end
    if o.Floating and type(Config.floats[id]) == "table" and floatButton then
        task.defer(function()
            if Hydra.floatButton(obj, o) then
                floatButton.stroke.Color = C.Accent
                floatButton.dot.BackgroundColor3 = C.Accent
            end
        end)
    end
    return obj
end

-- ---------- boton ----------
-- Tab:Button({Title, Desc, Icon, Callback}) o Toggle:Button({...}) dentro del desplegable
function Hydra.button(parent, order, o, nested)
    local card = mk("TextButton", {Size = UDim2.new(1, 0, 0, nested and 44 or (o.Desc and 60 or 52)), BackgroundColor3 = C.Glass, BackgroundTransparency = nested and 0.94 or CARD_ALPHA,
        AutoButtonColor = false, Text = "", LayoutOrder = order(), Parent = parent})
    corner(card, nested and 11 or 14)
    local cardStroke = stroke(card, C.Stroke, nested and 0.65 or 0.5)
    local x = 14
    if not nested then
        local badge = mk("Frame", {Size = UDim2.fromOffset(34, 34), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), BackgroundColor3 = C.AccentSoft, BorderSizePixel = 0, Parent = card})
        corner(badge, 10)
        mkIcon(o.Icon or "\226\158\164", C.Accent, {Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(8, 8), ScaleType = Enum.ScaleType.Fit, Parent = badge},
            {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15, Parent = badge})
        x = 56
    end
    mk("TextLabel", {Size = UDim2.new(1, -x - 60, 0, 16), Position = UDim2.new(0, x, 0.5, o.Desc and -15 or -8), BackgroundTransparency = 1, Text = o.Title, TextColor3 = C.Text,
        Font = Enum.Font.GothamBold, TextSize = nested and 12 or 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
    if o.Desc then
        mk("TextLabel", {Size = UDim2.new(1, -x - 60, 0, 13), Position = UDim2.new(0, x, 0.5, 3), BackgroundTransparency = 1, Text = o.Desc, TextColor3 = C.Dim,
            Font = Enum.Font.GothamSemibold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})
    end
    -- flechita a la derecha que se ilumina al tocar
    local go = mk("Frame", {Size = UDim2.fromOffset(30, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = C.Bg, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = card})
    corner(go, 9)
    local goStroke = stroke(go, C.Stroke, 0.55)
    local arrow = mk("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "\226\128\186", TextColor3 = C.Dim, Font = Enum.Font.GothamBlack, TextSize = 18, Parent = go})
    local scale = mk("UIScale", {Scale = 1, Parent = card})
    card.MouseEnter:Connect(function() tween(card, 0.15, {BackgroundTransparency = (nested and 0.94 or CARD_ALPHA) - 0.06}) end)
    card.MouseLeave:Connect(function()
        tween(card, 0.2, {BackgroundTransparency = nested and 0.94 or CARD_ALPHA})
        tween(scale, 0.25, {Scale = 1})
    end)
    card.MouseButton1Down:Connect(function() tween(scale, 0.08, {Scale = 0.98}) end)
    card.MouseButton1Up:Connect(function() tween(scale, 0.25, {Scale = 1}, Enum.EasingStyle.Back) end)
    card.MouseButton1Click:Connect(function()
        tween(goStroke, 0.1, {Color = C.Accent, Transparency = 0})
        tween(arrow, 0.1, {TextColor3 = C.Accent})
        tween(cardStroke, 0.1, {Color = C.Accent, Transparency = 0.35})
        task.delay(0.35, function()
            tween(goStroke, 0.4, {Color = C.Stroke, Transparency = 0.55})
            tween(arrow, 0.4, {TextColor3 = C.Dim})
            tween(cardStroke, 0.4, {Color = C.Stroke, Transparency = nested and 0.65 or 0.5})
        end)
        if o.Callback then
            local ok, err = pcall(o.Callback)
            if not ok then toast("Error: " .. tostring(err), C.Bad) end
        end
    end)
    return {Holder = card}
end

-- ---------- lista desplegable ----------
-- Tab:Dropdown({Id, Title, Desc, Options = {{value = ..., text = "..."}, ...} o function() return {...} end,
--   Default = valor, Callback = function(valor) end}) o Toggle:Dropdown({...}). Guarda la eleccion (Config.flags).
function Hydra.dropdown(parent, order, o, nested)
    local id = o.Id or o.Title
    local obj = {Type = "Dropdown", Id = id, value = nil, text = nil}
    local card = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Glass, BackgroundTransparency = nested and 0.94 or CARD_ALPHA,
        BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = order(), Parent = parent})
    corner(card, nested and 11 or 14)
    local cardStroke = stroke(card, C.Stroke, nested and 0.65 or 0.5)
    mk("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = card})
    local headH = nested and 46 or (o.Desc and 60 or 52)
    local head = mk("Frame", {Size = UDim2.new(1, 0, 0, headH), BackgroundTransparency = 1, LayoutOrder = 1, Parent = card})
    mk("TextLabel", {Size = UDim2.new(1, -190, 0, 16), Position = UDim2.new(0, 14, 0.5, o.Desc and -15 or -8), BackgroundTransparency = 1, Text = o.Title, TextColor3 = C.Text,
        Font = Enum.Font.GothamBold, TextSize = nested and 12 or 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head})
    if o.Desc then
        mk("TextLabel", {Size = UDim2.new(1, -190, 0, 13), Position = UDim2.new(0, 14, 0.5, 3), BackgroundTransparency = 1, Text = o.Desc, TextColor3 = C.Dim,
            Font = Enum.Font.GothamSemibold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head})
    end
    local pill = mk("TextButton", {Size = UDim2.fromOffset(160, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = C.Bg, BackgroundTransparency = 0.3,
        AutoButtonColor = false, Text = "", Parent = head})
    corner(pill, 10)
    local pillStroke = stroke(pill, C.Stroke, 0.5)
    local pillText = mk("TextLabel", {Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = "\226\128\148", TextColor3 = C.Text,
        Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = pill})
    local chevron = mk("TextLabel", {Size = UDim2.fromOffset(24, 30), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 0), BackgroundTransparency = 1, Text = "\226\128\186",
        TextColor3 = C.Dim, Font = Enum.Font.GothamBlack, TextSize = 18, Rotation = 90, Parent = pill})
    -- lista (con scroll si son muchas)
    local listWrap = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 2, Parent = card})
    mk("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = listWrap})
    local list = mk("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Accent,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = listWrap})
    local listLayout = mk("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
    local function options()
        local raw = type(o.Options) == "function" and o.Options() or o.Options or {}
        return type(raw) == "table" and raw or {}
    end
    local function textFor(value)
        for _, option in ipairs(options()) do
            if option.value == value then return option.text end
        end
        return nil
    end
    function obj:Set(value, silent)
        obj.value = value
        obj.text = textFor(value) or (value ~= nil and tostring(value)) or nil
        pillText.Text = obj.text or "\226\128\148"
        Config.flags[id] = value
        saveConfig()
        if o.Callback and not silent then pcall(o.Callback, value) end
    end
    function obj:Get() return obj.value end
    local function close()
        listWrap.Visible = false
        tween(chevron, 0.25, {Rotation = 90, TextColor3 = C.Dim})
        tween(pillStroke, 0.2, {Color = C.Stroke, Transparency = 0.5})
        tween(cardStroke, 0.2, {Color = C.Stroke, Transparency = nested and 0.65 or 0.5})
    end
    local function open()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        local all = options()
        if #all == 0 then
            mk("TextLabel", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "No hay nada para elegir", TextColor3 = C.Dim, Font = Enum.Font.GothamSemibold, TextSize = 11, Parent = list})
        end
        for index, option in ipairs(all) do
            local selected = option.value == obj.value
            local item = mk("TextButton", {Size = UDim2.new(1, -6, 0, 32), BackgroundColor3 = selected and C.Accent or C.Glass, BackgroundTransparency = selected and 0.82 or 0.94,
                AutoButtonColor = false, Text = "", LayoutOrder = index, Parent = list})
            corner(item, 9)
            if selected then stroke(item, C.Accent, 0.4) end
            mk("TextLabel", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = option.text or tostring(option.value),
                TextColor3 = selected and C.Accent or C.Text, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = item})
            item.MouseEnter:Connect(function() if option.value ~= obj.value then tween(item, 0.12, {BackgroundTransparency = 0.88}) end end)
            item.MouseLeave:Connect(function() if option.value ~= obj.value then tween(item, 0.15, {BackgroundTransparency = 0.94}) end end)
            item.MouseButton1Click:Connect(function()
                obj:Set(option.value)
                close()
            end)
        end
        local height = math.min(#all, 6) * 36
        list.Size = UDim2.new(1, 0, 0, math.max(height, 28))
        listWrap.Visible = true
        tween(chevron, 0.25, {Rotation = 270, TextColor3 = C.Accent})
        tween(pillStroke, 0.2, {Color = C.Accent, Transparency = 0.2})
        tween(cardStroke, 0.2, {Color = C.Accent, Transparency = 0.45})
    end
    pill.MouseButton1Click:Connect(function()
        if listWrap.Visible then close() else open() end
    end)
    local saved = Config.flags[id]
    if saved ~= nil then obj:Set(saved, true) elseif o.Default ~= nil then obj:Set(o.Default, true) end
    if obj.value ~= nil and o.Callback then task.defer(function() pcall(o.Callback, obj.value) end) end
    -- para refrescar el texto si las opciones cargan despues
    function obj:Refresh() obj.text = textFor(obj.value) or obj.text pillText.Text = obj.text or "\226\128\148" end
    Hydra.Options[id] = obj
    return obj
end

-- teclas: asignar y usar
track(UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local listening = Hydra.listening
    if listening then
        Hydra.listening = nil
        local code = input.KeyCode
        if code == Enum.KeyCode.Backspace or code == Enum.KeyCode.Escape then code = nil end
        Hydra.Binds[listening.id].code = code
        Config.binds[listening.id] = code and code.Name or nil
        saveConfig()
        listening.button.Text = keyName(code)
        listening.button.TextColor3 = code and C.Text or C.Dim
        if Hydra.refreshKeys then Hydra.refreshKeys() end
        return
    end
    if processed then return end
    for _, bind in pairs(Hydra.Binds) do
        if bind.code and input.KeyCode == bind.code then bind.obj:Set(not bind.obj:Get()) end
    end
end))


-- ---------- buscador de jugadores (con vista previa del avatar) ----------
-- Tab:PlayerSearch({Placeholder, ButtonText, Callback = function(info) return ok, mensaje end})
--   info = {id = UserId, user = "@usuario", display = "nombre visible"}
-- Arriba: caja para escribir el nombre y el boton. Al escribir, despues de una pausa corta, busca el usuario y muestra
-- su avatar de cuerpo entero (miniatura oficial rbxthumb), su nombre y su @usuario. Abajo: los jugadores del servidor
-- (toca uno y se completa el nombre). El Callback corre aparte (puede esperar); lo que devuelve se muestra en el chip.
-- Devuelve: obj:Fill(nombre), obj:SetStatus(texto, "ok" | "bad" | "busy"), obj:Get() (el ultimo usuario encontrado).
EN["Nombre de usuario"] = "Username"
EN["Aplicar"] = "Apply"
EN["Buscando\226\128\166"] = "Searching\226\128\166"
EN["No existe ese usuario"] = "That user doesn't exist"
EN["\226\156\147 Listo para aplicar"] = "\226\156\147 Ready to apply"
EN["\226\156\149 Revis\195\161 el nombre"] = "\226\156\149 Check the name"
EN["Escrib\195\173 un nombre primero"] = "Type a name first"
EN["Aplicando\226\128\166"] = "Applying\226\128\166"
EN["En el servidor"] = "In this server"
EN["No hay nadie m\195\161s en el servidor"] = "There is nobody else in the server"
function Hydra.playerSearch(parent, order, o)
    local UserService = game:GetService("UserService")
    local S = {gen = 0, cache = {}, info = nil, busy = false}
    local obj = {Type = "PlayerSearch"}
    local card = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Glass, BackgroundTransparency = CARD_ALPHA,
        BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = order(), Parent = parent})
    corner(card, 14)
    local cardStroke = stroke(card, C.Stroke, 0.5)
    mk("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = card})
    mk("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card})

    -- 1) barra de busqueda: lupa dibujada + caja + boton
    local bar = mk("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.Bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = 1, Parent = card})
    corner(bar, 12)
    local barStroke = stroke(bar, C.Stroke, 0.55)
    local lens = mk("Frame", {Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(12, 11), BackgroundTransparency = 1, Parent = bar})
    corner(lens, 99)
    local lensStroke = mk("UIStroke", {Color = C.Dim, Thickness = 2, Parent = lens})
    local handle = mk("Frame", {Size = UDim2.fromOffset(6, 2), Position = UDim2.fromOffset(22, 25), Rotation = 45, BackgroundColor3 = C.Dim, BorderSizePixel = 0, Parent = bar})
    corner(handle, 99)
    local box = mk("TextBox", {Size = UDim2.new(1, -140, 1, 0), Position = UDim2.fromOffset(36, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = tr(o.Placeholder or "Nombre de usuario"),
        PlaceholderColor3 = C.Dim, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 13, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = bar})
    local apply = mk("TextButton", {Size = UDim2.fromOffset(92, 30), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), BackgroundColor3 = C.Accent,
        AutoButtonColor = false, Text = "", Parent = bar})
    corner(apply, 10)
    mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(178, 183, 195)), Parent = apply})
    local applyLabel = mk("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = o.ButtonText or "Aplicar", TextColor3 = C.Bg, Font = Enum.Font.GothamBlack, TextSize = 12, Parent = apply})
    local applyScale = mk("UIScale", {Scale = 1, Parent = apply})
    box.Focused:Connect(function()
        tween(barStroke, 0.2, {Color = C.Accent, Transparency = 0.15})
        tween(lensStroke, 0.2, {Color = C.Accent})
        tween(handle, 0.2, {BackgroundColor3 = C.Accent})
    end)
    box.FocusLost:Connect(function()
        tween(barStroke, 0.25, {Color = C.Stroke, Transparency = 0.55})
        tween(lensStroke, 0.25, {Color = C.Dim})
        tween(handle, 0.25, {BackgroundColor3 = C.Dim})
    end)

    -- 2) vista previa: un "escenario" con el avatar centrado sobre una base de luz, el nombre debajo
    -- y una barra de estado fina abajo de todo (se abre al encontrar a alguien)
    local OPEN = 214
    local preview = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = C.Bg, BackgroundTransparency = 0.4, BorderSizePixel = 0, ClipsDescendants = true,
        Visible = false, LayoutOrder = 2, Parent = card})
    corner(preview, 12)
    stroke(preview, C.Stroke, 0.6)
    -- luz desde arriba (degradado vertical)
    local stage = mk("Frame", {Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, BorderSizePixel = 0, Parent = preview})
    mk("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(0.7, 0.97), NumberSequenceKeypoint.new(1, 1)}), Parent = stage})
    -- base de luz debajo de los pies (dos ovalos)
    local glow = mk("Frame", {Size = UDim2.fromOffset(150, 20), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 136), BackgroundColor3 = C.Accent,
        BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = preview})
    corner(glow, 999)
    local base = mk("Frame", {Size = UDim2.fromOffset(96, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 136), BackgroundColor3 = C.Accent,
        BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = preview})
    corner(base, 999)
    mk("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = base})
    -- el avatar
    local body = mk("ImageLabel", {Size = UDim2.fromOffset(136, 136), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 2), BackgroundTransparency = 1, Image = "",
        ImageTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 2, Parent = preview})
    -- linea que escanea de arriba a abajo mientras busca
    local scan = mk("Frame", {Size = UDim2.fromOffset(150, 2), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), BackgroundColor3 = C.Accent, BorderSizePixel = 0,
        Visible = false, ZIndex = 3, Parent = preview})
    mk("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = scan})
    TweenService:Create(scan, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(0.5, 0, 0, 132)}):Play()
    -- textos centrados
    local displayLabel = mk("TextLabel", {Size = UDim2.new(1, -24, 0, 20), Position = UDim2.fromOffset(12, 150), BackgroundTransparency = 1, Text = "", TextColor3 = C.Text,
        Font = Enum.Font.GothamBlack, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Parent = preview})
    local userLabel = mk("TextLabel", {Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(12, 171), BackgroundTransparency = 1, Text = "", TextColor3 = C.Dim,
        Font = Enum.Font.GothamSemibold, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Parent = preview})
    -- estado: texto chico + barra fina
    local statusLabel = mk("TextLabel", {Size = UDim2.new(1, -28, 0, 12), Position = UDim2.fromOffset(14, 189), BackgroundTransparency = 1, Text = "", TextColor3 = C.Dim,
        Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = preview})
    local track_ = mk("Frame", {Size = UDim2.new(1, -28, 0, 3), Position = UDim2.fromOffset(14, 204), BackgroundColor3 = C.Field, BorderSizePixel = 0, ClipsDescendants = true, Parent = preview})
    corner(track_, 99)
    local fill = mk("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0, Parent = track_})
    corner(fill, 99)
    local fillLoop = nil
    -- la vieja variable "chip" la usa el resto: ahora es el texto de estado
    local chip = statusLabel

    local function show(open)
        if open then
            if not preview.Visible then
                preview.Size = UDim2.new(1, 0, 0, 0)
                preview.Visible = true
            end
            tween(preview, 0.3, {Size = UDim2.new(1, 0, 0, OPEN)})
        elseif preview.Visible then
            local t = tween(preview, 0.2, {Size = UDim2.new(1, 0, 0, 0)}, Enum.EasingStyle.Quad)
            t.Completed:Connect(function(state)
                if state == Enum.PlaybackState.Completed and preview.Size.Y.Offset == 0 then preview.Visible = false end
            end)
        end
    end
    local KIND = {ok = C.Good, bad = C.Bad, busy = C.Accent}
    local function setChip(textValue, kind)
        local color = KIND[kind] or C.Accent
        chip.Text = tr(textValue)
        chip.TextColor3 = (kind == "ok" or kind == "bad") and color or C.Dim
        if fillLoop then fillLoop:Cancel() fillLoop = nil end
        fill.BackgroundColor3 = color
        if kind == "busy" then
            -- barra que corre de un lado al otro (esperando)
            fill.Size = UDim2.fromScale(0.3, 1)
            fill.Position = UDim2.fromScale(-0.3, 0)
            fillLoop = TweenService:Create(fill, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1), {Position = UDim2.fromScale(1, 0)})
            fillLoop:Play()
        else
            fill.Position = UDim2.fromScale(0, 0)
            fill.Size = UDim2.fromScale(0, 1)
            tween(fill, 0.45, {Size = UDim2.fromScale(1, 1)})
        end
        tween(base, 0.3, {BackgroundColor3 = color})
        tween(glow, 0.3, {BackgroundColor3 = color})
        tween(cardStroke, 0.25, {Color = (kind == "ok" or kind == "bad") and color or C.Stroke, Transparency = (kind == "ok" or kind == "bad") and 0.35 or 0.5})
    end
    local function setLoading(name)
        scan.Visible = true
        tween(body, 0.2, {ImageTransparency = 0.75})
        displayLabel.TextColor3 = C.Text
        displayLabel.Text = name
        userLabel.Text = tr("Buscando\226\128\166")
        setChip("Buscando\226\128\166", "busy")
        show(true)
    end
    local function setFound(info)
        scan.Visible = false
        body.Image = "rbxthumb://type=Avatar&id=" .. tostring(info.id) .. "&w=420&h=420"
        -- entra subiendo desde la base
        body.ImageTransparency = 1
        body.Position = UDim2.new(0.5, 0, 0, 14)
        tween(body, 0.45, {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0, 2)})
        displayLabel.TextColor3 = C.Text
        displayLabel.Text = info.display or info.user
        userLabel.Text = "@" .. info.user .. "  \194\183  ID " .. tostring(info.id)
        setChip("\226\156\147 Listo para aplicar")
        show(true)
    end
    local function setMissing(name)
        scan.Visible = false
        tween(body, 0.2, {ImageTransparency = 1})
        displayLabel.Text = name
        displayLabel.TextColor3 = C.Bad
        userLabel.Text = tr("No existe ese usuario")
        setChip("\226\156\149 Revis\195\161 el nombre", "bad")
        show(true)
    end
    -- busca el usuario (con cache: cada nombre se pide una sola vez)
    local function lookup(name)
        local key = string.lower(name)
        local cached = S.cache[key]
        if cached == nil then
            local okId, id = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
            if not okId or not id then
                cached = false
            else
                local info = {id = id, user = name, display = nil}
                pcall(function()
                    local list = UserService:GetUserInfosByUserIdsAsync({id})
                    local u = list and list[1]
                    if u then info.user, info.display = u.Username or name, u.DisplayName end
                end)
                cached = info
            end
            S.cache[key] = cached
        end
        return cached
    end
    local function cleanName() return (tostring(box.Text or ""):match("^%s*(.-)%s*$")) end
    local function validName(name) return #name >= 3 and #name <= 20 and not name:find("[^%w_]") end
    box:GetPropertyChangedSignal("Text"):Connect(function()
        S.gen = S.gen + 1
        local gen = S.gen
        local name = cleanName()
        S.info = nil
        -- los nombres de Roblox tienen de 3 a 20 caracteres: letras, numeros y _
        if not validName(name) then show(false) return end
        task.delay(0.55, function()
            if gen ~= S.gen then return end
            setLoading(name)
            local info = lookup(name)
            if gen ~= S.gen then return end -- ya escribio otra cosa
            S.info = info or nil
            if info then setFound(info) else setMissing(name) end
        end)
    end)

    function obj:SetStatus(textValue, kind) setChip(textValue, kind) show(true) end
    function obj:Fill(name) box.Text = tostring(name or "") end
    function obj:Get() return S.info end
    local function run()
        if S.busy then return end
        local name = cleanName()
        if not validName(name) then toast(tr("Escrib\195\173 un nombre primero"), C.Bad) return end
        S.busy = true
        tween(applyScale, 0.08, {Scale = 0.94})
        task.delay(0.1, function() tween(applyScale, 0.25, {Scale = 1}, Enum.EasingStyle.Back) end)
        applyLabel.Text = tr("Aplicando\226\128\166")
        task.spawn(function()
            local info = S.info
            if not info then
                setLoading(name)
                info = lookup(name)
                if info then setFound(info) S.info = info else setMissing(name) end
            end
            if info and o.Callback then
                setChip("Aplicando\226\128\166", "busy")
                local okRun, ok, message = pcall(o.Callback, info)
                if not okRun then ok, message = false, tostring(ok) end
                if message then setChip(message, ok and "ok" or "bad") end
            end
            applyLabel.Text = tr(o.ButtonText or "Aplicar")
            S.busy = false
        end)
    end
    apply.MouseButton1Click:Connect(run)
    box.FocusLost:Connect(function(enter) if enter then run() end end)

    -- 3) jugadores del servidor: toca uno y se completa el nombre
    local serverHead = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = "En el servidor", TextColor3 = C.Dim, Font = Enum.Font.GothamBlack,
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3, Parent = card})
    local strip = mk("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = C.Accent,
        ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, LayoutOrder = 4, Parent = card})
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = strip})
    local empty = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "No hay nadie m\195\161s en el servidor", TextColor3 = C.Dim,
        Font = Enum.Font.GothamSemibold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Visible = false, LayoutOrder = 0, Parent = strip})
    local bubbles = {}
    local function addPlayer(player)
        if player == LocalPlayer or bubbles[player] then return end
        local b = mk("TextButton", {Size = UDim2.fromOffset(54, 62), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", LayoutOrder = #strip:GetChildren(), Parent = strip})
        local face = mk("ImageLabel", {Size = UDim2.fromOffset(42, 42), Position = UDim2.fromOffset(6, 2), BackgroundColor3 = C.Field, BorderSizePixel = 0,
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150", Parent = b})
        corner(face, 99)
        local faceStroke = stroke(face, C.Stroke, 0.5)
        mk("TextLabel", {Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 47), BackgroundTransparency = 1, Text = player.DisplayName, TextColor3 = C.Text,
            Font = Enum.Font.GothamBold, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b})
        local faceScale = mk("UIScale", {Scale = 1, Parent = face})
        b.MouseEnter:Connect(function() tween(faceStroke, 0.15, {Color = C.Accent, Transparency = 0.1}) end)
        b.MouseLeave:Connect(function() tween(faceStroke, 0.2, {Color = C.Stroke, Transparency = 0.5}) end)
        b.MouseButton1Click:Connect(function()
            tween(faceScale, 0.08, {Scale = 0.9})
            task.delay(0.1, function() tween(faceScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back) end)
            -- ya se sabe quien es: se guarda en la cache para no buscarlo
            S.cache[string.lower(player.Name)] = {id = player.UserId, user = player.Name, display = player.DisplayName}
            box.Text = player.Name
        end)
        bubbles[player] = b
        empty.Visible = false
    end
    local function removePlayer(player)
        if bubbles[player] then bubbles[player]:Destroy() bubbles[player] = nil end
        empty.Visible = next(bubbles) == nil
    end
    for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
    empty.Visible = next(bubbles) == nil
    track(Players.PlayerAdded:Connect(addPlayer))
    track(Players.PlayerRemoving:Connect(removePlayer))
    -- al cambiar el idioma: el texto de ayuda de la caja
    local previous = Lang.onChange
    Lang.onChange = function()
        if previous then previous() end
        box.PlaceholderText = tr(o.Placeholder or "Nombre de usuario")
        if not S.busy then applyLabel.Text = tr(o.ButtonText or "Aplicar") end
    end
    obj.Holder = card
    obj.header = serverHead
    return obj
end

-- ---------- Ajustes: teclado con las teclas asignadas ----------
-- Dibuja un teclado y marca las teclas que tienen una opcion (las de los chips de tecla de cada toggle).
-- Las teclas tienen relieve y se hunden cuando las apretas; las asignadas quedan plateadas con un brillo que pasa.
-- Debajo, la lista "tecla -> opcion" (traducida). Se actualiza cuando asignas o borras una tecla y al cambiar el idioma.
EN["Teclado"] = "Keyboard"
EN["en uso"] = "in use"
EN["Abrir / cerrar Hydra"] = "Open / close Hydra"
EN["Toc\195\161 el chip de tecla de cualquier opci\195\179n para asignarle una"] = "Tap the key chip of any option to give it a key"
Hydra.Keyboard = {keys = {}, ROWS = {
    {{"`", "Backquote"}, {"1", "One"}, {"2", "Two"}, {"3", "Three"}, {"4", "Four"}, {"5", "Five"}, {"6", "Six"}, {"7", "Seven"}, {"8", "Eight"}, {"9", "Nine"}, {"0", "Zero"}, {"-", "Minus"}, {"=", "Equals"}, {"Back", "Backspace", 2}},
    {{"Tab", "Tab", 1.5}, {"Q", "Q"}, {"W", "W"}, {"E", "E"}, {"R", "R"}, {"T", "T"}, {"Y", "Y"}, {"U", "U"}, {"I", "I"}, {"O", "O"}, {"P", "P"}, {"[", "LeftBracket"}, {"]", "RightBracket"}, {"\\", "BackSlash", 1.5}},
    {{"Caps", "CapsLock", 1.75}, {"A", "A"}, {"S", "S"}, {"D", "D"}, {"F", "F"}, {"G", "G"}, {"H", "H"}, {"J", "J"}, {"K", "K"}, {"L", "L"}, {";", "Semicolon"}, {"'", "Quote"}, {"Enter", "Return", 2.25}},
    {{"Shift", "LeftShift", 2.25}, {"Z", "Z"}, {"X", "X"}, {"C", "C"}, {"V", "V"}, {"B", "B"}, {"N", "N"}, {"M", "M"}, {",", "Comma"}, {".", "Period"}, {"/", "Slash"}, {"Shift", "RightShift", 2.75}},
    {{"Ctrl", "LeftControl", 1.5}, {"Alt", "LeftAlt", 1.5}, {"", "Space", 9}, {"Alt", "RightAlt", 1.5}, {"Ctrl", "RightControl", 1.5}},
}}
-- brillo que cruza la tecla (lo mueve TweenService en bucle, sin codigo corriendo cada frame)
Hydra.Keyboard.SHEEN = TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.8)
Hydra.Keyboard.TOP_LIGHT = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(178, 183, 195))
do
    local KB = Hydra.Keyboard
    section(TabSettings, "Teclas", "\226\150\162")
    local card = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Glass, BackgroundTransparency = CARD_ALPHA,
        BorderSizePixel = 0, LayoutOrder = nextOrder(TabSettings), Parent = TabSettings.page})
    corner(card, 14)
    stroke(card, C.Stroke, 0.5)
    mk("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = card})
    mk("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card})
    -- cabecera: titulo y contador de teclas en uso
    local head = mk("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 0, Parent = card})
    mk("TextLabel", {Size = UDim2.new(1, -90, 1, 0), BackgroundTransparency = 1, Text = "Teclado", TextColor3 = C.Text, Font = Enum.Font.GothamBlack, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = head})
    KB.counter = mk("TextLabel", {Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.Accent, BackgroundTransparency = 0.82, Text = "0", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 10, Parent = head})
    corner(KB.counter, 10)
    stroke(KB.counter, C.Accent, 0.55)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = KB.counter})
    -- el teclado: base oscura con degradado y las teclas con relieve
    local board = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Bg, BackgroundTransparency = 0.25,
        BorderSizePixel = 0, LayoutOrder = 1, Parent = card})
    corner(board, 12)
    stroke(board, C.Stroke, 0.6)
    mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(70, 76, 90), Color3.new(1, 1, 1)), Parent = board})
    mk("UIPadding", {PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7), PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7), Parent = board})
    mk("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = board})
    for rowIndex, row in ipairs(KB.ROWS) do
        local units = 0
        for _, key in ipairs(row) do units = units + (key[3] or 1) end
        local line = mk("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = rowIndex, Parent = board})
        mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = line})
        local gap = 3 * (#row - 1) / #row
        for keyIndex, key in ipairs(row) do
            local slot = mk("Frame", {Size = UDim2.new((key[3] or 1) / units, -gap, 1, 0), BackgroundTransparency = 1, LayoutOrder = keyIndex, Parent = line})
            -- sombra de abajo (da el relieve)
            local base = mk("Frame", {Size = UDim2.new(1, 0, 1, -2), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
                BorderSizePixel = 0, Parent = slot})
            corner(base, 6)
            local cap = mk("Frame", {Size = UDim2.new(1, 0, 1, -2), Position = UDim2.fromOffset(0, 0), BackgroundColor3 = C.Field, BackgroundTransparency = 0.1,
                BorderSizePixel = 0, ClipsDescendants = true, Parent = slot})
            corner(cap, 6)
            mk("UIGradient", {Rotation = 90, Color = KB.TOP_LIGHT, Parent = cap})
            local capStroke = stroke(cap, C.Stroke, 0.65)
            local sheen = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, BorderSizePixel = 0, Visible = false, Parent = cap})
            corner(sheen, 6)
            local sheenGrad = mk("UIGradient", {Rotation = 20, Offset = Vector2.new(-1, 0), Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.35),
                NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1)}), Parent = sheen})
            local label = mk("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = key[1], TextColor3 = C.Dim,
                Font = Enum.Font.GothamBold, TextSize = 10, TextScaled = false, ZIndex = 2, Parent = cap})
            KB.keys[key[2]] = {cap = cap, base = base, stroke = capStroke, label = label, sheen = sheen, sheenGrad = sheenGrad}
        end
    end
    -- lista de asignaciones
    KB.list = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = card})
    mk("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = KB.list})
    -- las teclas se hunden cuando las apretas en el teclado de verdad
    local function press(input, down)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local key = KB.keys[input.KeyCode.Name]
        if not key then return end
        tween(key.cap, down and 0.06 or 0.18, {Position = UDim2.fromOffset(0, down and 2 or 0)})
        tween(key.base, down and 0.06 or 0.18, {BackgroundTransparency = down and 0.8 or 0.45})
    end
    track(UserInputService.InputBegan:Connect(function(input) press(input, true) end))
    track(UserInputService.InputEnded:Connect(function(input) press(input, false) end))
    -- al cambiar el idioma se vuelve a armar la lista con los nombres traducidos
    local previous = Lang.onChange
    Lang.onChange = function()
        if previous then previous() end
        if Hydra.refreshKeys then Hydra.refreshKeys() end
    end
end

function Hydra.refreshKeys()
    local KB = Hydra.Keyboard
    local used, count = {}, 0
    -- K abre y cierra la ventana (de la libreria)
    used.K = {tr("Abrir / cerrar Hydra")}
    for _, bind in pairs(Hydra.Binds) do
        if bind.code then
            local name = bind.code.Name
            if not used[name] then count = count + 1 end
            used[name] = used[name] or {}
            table.insert(used[name], tr(bind.title or "?"))
        end
    end
    KB.counter.Text = tostring(count) .. " " .. tr("en uso")
    for name, key in pairs(KB.keys) do
        local on = used[name] ~= nil
        tween(key.cap, 0.3, {BackgroundColor3 = on and C.Accent or C.Field, BackgroundTransparency = on and 0 or 0.1})
        tween(key.label, 0.3, {TextColor3 = on and C.Bg or C.Dim})
        tween(key.stroke, 0.3, {Color = on and Color3.new(1, 1, 1) or C.Stroke, Transparency = on and 0.1 or 0.65})
        key.label.Font = on and Enum.Font.GothamBlack or Enum.Font.GothamBold
        if on and not key.loop then
            key.sheen.Visible = true
            key.sheenGrad.Offset = Vector2.new(-1, 0)
            key.loop = TweenService:Create(key.sheenGrad, KB.SHEEN, {Offset = Vector2.new(1, 0)})
            key.loop:Play()
        elseif not on and key.loop then
            key.loop:Cancel()
            key.loop = nil
            key.sheen.Visible = false
        end
    end
    for _, child in ipairs(KB.list:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    local names = {}
    for name in pairs(used) do names[#names + 1] = name end
    -- primero las teclas de las opciones, la K de la ventana al final
    table.sort(names, function(a, b)
        if (a == "K") ~= (b == "K") then return b == "K" end
        return a < b
    end)
    for index, name in ipairs(names) do
        local row = mk("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.Glass, BackgroundTransparency = 0.93, BorderSizePixel = 0, LayoutOrder = index, Parent = KB.list})
        corner(row, 9)
        stroke(row, C.Stroke, 0.78)
        -- chip con forma de tecla
        local chipBase = mk("Frame", {Size = UDim2.fromOffset(60, 20), Position = UDim2.new(0, 6, 0.5, -9), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
            BorderSizePixel = 0, Parent = row})
        corner(chipBase, 6)
        local chip = mk("TextLabel", {Size = UDim2.fromOffset(60, 20), Position = UDim2.new(0, 6, 0.5, -11), BackgroundColor3 = C.Accent,
            Text = keyName(Enum.KeyCode[name]), TextColor3 = C.Bg, Font = Enum.Font.GothamBlack, TextSize = 10, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
        corner(chip, 6)
        mk("UIGradient", {Rotation = 90, Color = KB.TOP_LIGHT, Parent = chip})
        mk("TextLabel", {Size = UDim2.new(1, -84, 1, 0), Position = UDim2.fromOffset(76, 0), BackgroundTransparency = 1, Text = table.concat(used[name], "  \194\183  "),
            TextColor3 = name == "K" and C.Dim or C.Text, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
    end
    -- todavia no asignaste ninguna: una pista de como hacerlo
    if count == 0 then
        mk("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = #names + 1,
            Text = "Toc\195\161 el chip de tecla de cualquier opci\195\179n para asignarle una", TextColor3 = C.Dim, Font = Enum.Font.Gotham, TextSize = 11,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = KB.list})
    end
end
task.defer(Hydra.refreshKeys)

function Hydra:Notify(text, color) toast(text, color) end
-- traduce un texto (en espanol) al idioma del jugador, con las traducciones cargadas
function Hydra:T(text) return tr(text) end
-- traducciones de los textos de un script externo: {["texto en espanol"] = "english text"}
function Hydra:AddTranslations(list)
    for spanish, english in pairs(list) do EN[spanish] = english end
end
function Hydra:Select(name) selectTab(name) end

return Hydra
