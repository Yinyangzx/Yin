--[[
    Yin Yang - UI Ultimate Edition (v26.1)  SOUND BUG FIXED
    ============================================================
     ARREGLOS CRÍTICOS v26.1:
    
    1. FIX SONIDO GLOBAL: El slider ya NO reproduce sonido en inputs globales
       - Eliminado playSound en InputChanged (línea 1508)
       - Cambiado de UserInputService.InputEnded a SliderThumb.InputEnded
       - El sonido SOLO se escucha al ajustar el slider, no en todo input de pantalla
    
    2. AHORA COMPATIBLE: Puedes jugar EVADE sin escuchar sonidos del slider
    
     CARACTERÍSTICAS ORIGINALES MANTENIDAS:
    
    1. LOGO YIN-YANG ROTATIVO: Logo animado que gira continuamente
    2. SONIDOS INTEGRADOS:
       - Click al activar/desactivar (138567614125924)
       - Dragón aleatorio cuando está cerrado (7127123554) - cada 15 segundos, volumen reducido
    3. TOGGLES FLOTANTES: 
       - Pueden desprenderse de la UI principal
       - Se pueden fijar (+) o soltar (-) 
       - Se mueven libremente por la pantalla

--// ══════════════════════════════════════════════════════════════════════════════
--// GUÍA: CÓMO CREAR PESTAÑAS CON ASSETS (ICONOS)
--// ══════════════════════════════════════════════════════════════════════════════
--//
--// SINTAXIS BÁSICA:
--// local MiTab = Window:CreateTab("Nombre de la Pestaña", "rbxassetid://ASSET_ID")
--//
--// EJEMPLO 1: Crear una pestaña con icono de casa
--// local TabCasa = Window:CreateTab("Mi Casa", "rbxassetid://71085559019524")
--//
--// EJEMPLO 2: Crear una pestaña sin icono
--// local TabSimple = Window:CreateTab("Simple", nil)
--// O directamente sin el segundo parámetro:
--// local TabSimple = Window:CreateTab("Simple")
--//
--// EJEMPLO 3: Usar diferentes assets
--// local TabManzana = Window:CreateTab("Frutas", "rbxassetid://108938004711116")
--// local TabRayo = Window:CreateTab("Energía", "rbxassetid://132646825035547")
--// local TabAjustes = Window:CreateTab("Configuración", "rbxassetid://130729134186771")
--//
--// LISTA DE ASSETS DISPONIBLES EN LA LIBRERÍA:
--// • Casa: 124987849953130
--// • Manzana: 84419345138935
--// • Rayo: 114693810646148
--// • Ajustes: 86797720103644
--// • Candado: 115388161816720
--// • Llave: 135318845352652
--// • Lupa: 83456197177232
--// • Brújula: 121857625643442
--// • Y muchos más...
--//
--// NOTA IMPORTANTE:
--// • El icono se mostrará a la IZQUIERDA del nombre de la pestaña
--// • El icono es pequeño (16x16px) pero claramente visible
--// • El tamaño se ajusta automáticamente para no molestar el texto
--// • Los nombres de pestaña siempre permanecen visibles
--//
--// ══════════════════════════════════════════════════════════════════════════════

       - Persistencia de posición
    4. SISTEMA PROFESIONAL DE AUDIO
    5. MANEJO AVANZADO DE VENTANAS FLOTANTES
    
    TOKENS USADOS:
    - Yin-Yang: 84935900372278
    - Click Sound: 138567614125924
    - Dragon Sound: 7127123554
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

pcall(function()
    if LocalPlayer.PlayerGui:FindFirstChild("ZeroMobile") then
        LocalPlayer.PlayerGui.ZeroMobile:Destroy()
    end
end)

--// SONIDOS
local Sounds = {
    Click = "rbxassetid://138567614125924",
    Dragon = "rbxassetid://7127123554",
}

--// ═════════════════════════════════════════════════════════════════════════════
--// SISTEMA DE LENGUAJE BILINGÜE (v28 PRO)
--// ═════════════════════════════════════════════════════════════════════════════
local LanguageSystem = {
    CurrentLanguage = "es",  -- "es" = Español, "en" = English
    Config = { Language = "es" }
}

local function GetText(spanishText, englishText)
    if LanguageSystem.CurrentLanguage == "es" then
        return spanishText
    else
        return englishText
    end
end

local function ChangeLanguage(newLanguage)
    if newLanguage ~= "es" and newLanguage ~= "en" then
        error("Idioma no válido. Usa 'es' o 'en'")
        return
    end
    LanguageSystem.CurrentLanguage = newLanguage
    LanguageSystem.Config.Language = newLanguage
end

local function SaveLanguageConfig()
    pcall(function()
        if writefile then
            local configJson = HttpService:JSONEncode(LanguageSystem.Config)
            writefile("yin_yang_language_config.json", configJson)
        end
    end)
end

local function LoadLanguageConfig()
    pcall(function()
        if readfile and isfile and isfile("yin_yang_language_config.json") then
            local configJson = readfile("yin_yang_language_config.json")
            LanguageSystem.Config = HttpService:JSONDecode(configJson)
            LanguageSystem.CurrentLanguage = LanguageSystem.Config.Language or "es"
        end
    end)
end

LoadLanguageConfig()
--// ═════════════════════════════════════════════════════════════════════════════

--// VARIABLE DE ESTADO: Freeze Icono
local IconoCongelado = false

--//  SONIDOS DE CLICK PERSONALIZADOS POR TEMA (v26)
local ThemeClickSounds = {
    CatV1 = "rbxassetid://133371725828981",
    PinkV2 = "rbxassetid://136022651109523",
    PinkV1 = "rbxassetid://15675081158",
    PinkV3 = "rbxassetid://75880354609739",
    ErisV1 = "rbxassetid://137965684634919",
    VioletaV1 = "rbxassetid://115624890613221",
    GreenV1 = "rbxassetid://9112751731",
    DarkV2 = "rbxassetid://139804904213958",
    BlueV2 = "rbxassetid://118574877365368",
    WhiteV2 = "rbxassetid://140043289814504",
    WhiteAndDark = "rbxassetid://139239108826837",
    LightV1 = "rbxassetid://99071431420752",
    NaranjaV1 = "rbxassetid://124502189759941",
}

--// SISTEMA DE SONIDO DINÁMICO POR TEMA
local CurrentClickSound = Sounds.Click
local CurrentTheme = "Dark"

--//  v26: VARIABLE PARA ACTIVAR/DESACTIVAR SONIDOS PERSONALIZADOS
local DynamicClickSoundsEnabled = true  --  Cambiar a false para desactivar

--//  SISTEMA RAINBOW DARK-WHITE: Cambia lentamente de negro a blanco
local RainbowDarkWhiteActive = false
local RainbowDarkWhiteValue = 0
local RainbowDarkWhiteLabels = {}

--// 🌙 LETRAS DE "CANTO DE LUNA" PARA TÍTULO ANIMADO (v26)
local CantoLunaLetras = {
    "Yin Yang",
    "Canto de Luna",
    "la-la-la 🌙",
    "Canta, canta",
    "En mi corazón",
    "la-la-la ",
    "Eres lo que buscamos",
    "Con la luz 💫",
    "Canta, canta, canta",
    "Yo te vi",
}

--//  COLORES RAINBOW (Prioridad: BLANCO)
local RainbowColors = {
    Color3.fromRGB(255, 255, 0),      -- Amarillo
    Color3.fromRGB(255, 255, 255),    -- BLANCO ⭐
    Color3.fromRGB(255, 0, 0),        -- Rojo
    Color3.fromRGB(255, 255, 255),    -- BLANCO ⭐
    Color3.fromRGB(0, 255, 0),        -- Verde
    Color3.fromRGB(255, 255, 255),    -- BLANCO ⭐
    Color3.fromRGB(0, 0, 255),        -- Azul
    Color3.fromRGB(255, 255, 255),    -- BLANCO ⭐
    Color3.fromRGB(255, 165, 0),      -- Naranja
    Color3.fromRGB(255, 255, 255),    -- BLANCO ⭐
}

--//  COLORES DE BORDE ANIMADO PARA FLOATING TOGGLES (v26.1 PREMIUM)
local FloatingToggleBorderColors = {
    -- DARK THEMES (Azules y Cian)
    Dark = {
        Color3.fromRGB(100, 200, 255),    -- Cian claro
        Color3.fromRGB(150, 100, 255),    -- Púrpura
        Color3.fromRGB(100, 150, 255),    -- Azul
        Color3.fromRGB(200, 150, 255),    -- Púrpura claro
    },
    DarkV2 = {
        Color3.fromRGB(100, 180, 255),
        Color3.fromRGB(120, 200, 255),
        Color3.fromRGB(80, 150, 255),
        Color3.fromRGB(150, 180, 255),
    },
    
    -- RED THEMES (Rojos y Naranjas)
    Red = {
        Color3.fromRGB(255, 100, 100),    -- Rojo claro
        Color3.fromRGB(255, 150, 100),    -- Naranja-rojo
        Color3.fromRGB(255, 80, 120),     -- Rojo-rosa
        Color3.fromRGB(255, 120, 100),    -- Naranja
    },
    RedV2 = {
        Color3.fromRGB(255, 120, 100),
        Color3.fromRGB(255, 100, 150),
        Color3.fromRGB(255, 150, 80),
        Color3.fromRGB(255, 100, 100),
    },
    
    -- PINK THEMES (Rosas y Púrpuras)
    Pink = {
        Color3.fromRGB(255, 100, 200),    -- Rosa
        Color3.fromRGB(255, 150, 200),    -- Rosa claro
        Color3.fromRGB(200, 100, 200),    -- Púrpura-rosa
        Color3.fromRGB(255, 100, 150),    -- Rosa-rojo
    },
    PinkV2 = {
        Color3.fromRGB(255, 120, 200),
        Color3.fromRGB(255, 80, 180),
        Color3.fromRGB(220, 100, 200),
        Color3.fromRGB(255, 150, 200),
    },
    PinkV3 = {
        Color3.fromRGB(255, 100, 180),
        Color3.fromRGB(255, 150, 210),
        Color3.fromRGB(200, 80, 180),
        Color3.fromRGB(255, 120, 190),
    },
    
    -- BLUE THEMES (Azules y Cian)
    Blue = {
        Color3.fromRGB(100, 200, 255),    -- Cian
        Color3.fromRGB(150, 200, 255),    -- Azul claro
        Color3.fromRGB(100, 150, 200),    -- Azul
        Color3.fromRGB(200, 220, 255),    -- Azul muy claro
    },
    BlueV2 = {
        Color3.fromRGB(80, 180, 255),
        Color3.fromRGB(120, 200, 255),
        Color3.fromRGB(100, 160, 255),
        Color3.fromRGB(150, 210, 255),
    },
    
    -- WHITE THEMES (Blancos y Grises)
    White = {
        Color3.fromRGB(200, 200, 200),    -- Gris claro
        Color3.fromRGB(255, 255, 255),    -- Blanco
        Color3.fromRGB(220, 220, 220),    -- Gris
        Color3.fromRGB(240, 240, 240),    -- Blanco roto
    },
    WhiteV2 = {
        Color3.fromRGB(220, 220, 220),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(200, 200, 200),
        Color3.fromRGB(230, 230, 230),
    },
    WhiteV3 = {
        Color3.fromRGB(210, 210, 210),
        Color3.fromRGB(240, 240, 240),
        Color3.fromRGB(190, 190, 190),
        Color3.fromRGB(255, 255, 255),
    },
    WhiteAndDark = {
        Color3.fromRGB(100, 100, 100),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(150, 150, 150),
        Color3.fromRGB(200, 200, 200),
    },
    
    -- GREEN THEME (Verdes)
    Green = {
        Color3.fromRGB(100, 255, 150),    -- Verde claro
        Color3.fromRGB(150, 255, 100),    -- Verde-amarillo
        Color3.fromRGB(100, 200, 150),    -- Verde
        Color3.fromRGB(150, 255, 180),    -- Verde muy claro
    },
    
    -- SPECIAL THEMES
    NaranjaV1 = {
        Color3.fromRGB(255, 150, 50),     -- Naranja
        Color3.fromRGB(255, 100, 80),     -- Naranja-rojo
        Color3.fromRGB(255, 180, 100),    -- Naranja claro
        Color3.fromRGB(255, 120, 60),     -- Naranja oscuro
    },
    VioletaV1 = {
        Color3.fromRGB(180, 100, 255),    -- Púrpura
        Color3.fromRGB(200, 150, 255),    -- Púrpura claro
        Color3.fromRGB(150, 80, 255),     -- Púrpura oscuro
        Color3.fromRGB(220, 180, 255),    -- Púrpura muy claro
    },
    CatV1 = {
        Color3.fromRGB(255, 100, 150),    -- Rosa
        Color3.fromRGB(255, 150, 100),    -- Naranja
        Color3.fromRGB(200, 100, 200),    -- Púrpura
        Color3.fromRGB(255, 120, 120),    -- Rojo-rosa
    },
    LightV1 = {
        Color3.fromRGB(255, 220, 100),    -- Amarillo claro
        Color3.fromRGB(255, 255, 150),    -- Amarillo muy claro
        Color3.fromRGB(255, 200, 100),    -- Amarillo-naranja
        Color3.fromRGB(255, 240, 150),    -- Crema
    },
    ErisV1 = {
        Color3.fromRGB(255, 80, 80),      -- Rojo oscuro
        Color3.fromRGB(180, 50, 50),      -- Rojo muy oscuro
        Color3.fromRGB(255, 100, 100),    -- Rojo claro
        Color3.fromRGB(200, 60, 60),      -- Rojo
    },
    ShylfieV1 = {
        Color3.fromRGB(100, 180, 255),    -- Azul claro
        Color3.fromRGB(150, 200, 255),    -- Azul cielo
        Color3.fromRGB(80, 160, 255),     -- Azul
        Color3.fromRGB(200, 220, 255),    -- Azul muy claro
    },
}

--// 💾 SISTEMA DE GUARDADO/PERSISTENCIA (v26 - MEJORADO)
local ConfigFile = "Yin_Yang_Config.txt"
local SavedConfig = {
    CurrentTheme = "Dark",
    CurrentEffect = "Normal",
    Volume = 0.5,
}

local function SaveConfig()
    pcall(function()
        local configData = table.concat({
            "theme:" .. tostring(SavedConfig.CurrentTheme or CurrentTheme or "Dark"),
            "effect:" .. tostring(SavedConfig.CurrentEffect or "Normal"),
            "volume:" .. tostring(SavedConfig.Volume or 0.5),
            "libMode:" .. tostring(SavedConfig.LibrarySizeMode or "Small"),
            "libHeight:" .. tostring(SavedConfig.LibraryHeight or 340),
            "lang:" .. tostring(LanguageSystem.CurrentLanguage or "es"),
            "time:" .. tostring(os.time()),
        }, "|")
        writefile(ConfigFile, configData)
    end)
end

local function LoadConfig()
    local result = {
        theme = nil,
        effect = nil,
        volume = nil,
        libMode = nil,
        libHeight = nil,
        lang = nil,
    }

    pcall(function()
        if readfile(ConfigFile) then
            local content = readfile(ConfigFile)
            if content and content ~= "" then
                for part in content:gmatch("([^|]+)") do
                    local key, value = part:match("([^:]+):(.+)")
                    if key == "theme" then
                        result.theme = value
                    elseif key == "effect" then
                        result.effect = value
                    elseif key == "volume" then
                        result.volume = tonumber(value)
                    elseif key == "libMode" then
                        result.libMode = value
                    elseif key == "libHeight" then
                        result.libHeight = tonumber(value)
                    elseif key == "lang" then
                        result.lang = value
                    end
                end
            end
        end
    end)
    return result
end

--// POOL DE SONIDOS: reutiliza Instances en vez de crear/destruir una por cada click
local SoundPool = {}
local POOL_SIZE = 8
local poolCursor = 0

local function getPooledSound()
    -- 1) intenta encontrar uno libre (que no esté sonando)
    for _, s in ipairs(SoundPool) do
        if not s.IsPlaying then
            return s
        end
    end
    -- 2) si el pool no está lleno, crea uno nuevo y lo agrega
    if #SoundPool < POOL_SIZE then
        local s = Instance.new("Sound")
        s.Parent = SoundService
        table.insert(SoundPool, s)
        return s
    end
    -- 3) pool lleno y todos ocupados: reutiliza el siguiente en rotación (round robin)
    poolCursor = (poolCursor % #SoundPool) + 1
    return SoundPool[poolCursor]
end

local function playSound(soundId, volume)
    volume = volume or 0.5
    
    --//  v26: USAR SONIDO DINÁMICO SI ESTÁ ACTIVADO
    local finalSoundId = soundId
    
    -- Si sonidos dinámicos están activados, ignorar Sounds.Click y usar el del tema
    if DynamicClickSoundsEnabled and (soundId == Sounds.Click or not soundId) then
        if CurrentTheme and ThemeClickSounds[CurrentTheme] then
            finalSoundId = ThemeClickSounds[CurrentTheme]
        else
            finalSoundId = Sounds.Click
        end
    end
    
    if not finalSoundId or finalSoundId == "" then 
        finalSoundId = Sounds.Click
    end
    
    local sound = getPooledSound()
    if sound then
        pcall(function()
            sound.SoundId = finalSoundId
            sound.Volume = math.clamp(volume, 0, 1)
            sound.TimePosition = 0
            sound.Playing = false
            sound:Play()
        end)
    end
end

--// ASSETS & TEMAS
local Assets = {
    Utilities = {
        Settings = "rbxasset://textures/Cursor.png",
        Search = "rbxasset://textures/Cursor.png",
        Download = "rbxasset://textures/Cursor.png",
        Upload = "rbxasset://textures/Cursor.png",
        Copy = "rbxasset://textures/Cursor.png",
        Paste = "rbxasset://textures/Cursor.png",
        Refresh = "rbxasset://textures/Cursor.png",
        Delete = "rbxasset://textures/Cursor.png",
        Edit = "rbxasset://textures/Cursor.png",
        Save = "rbxasset://textures/Cursor.png",
        Export = "rbxasset://textures/Cursor.png",
        Import = "rbxasset://textures/Cursor.png",
        Help = "rbxasset://textures/Cursor.png",
        Info = "rbxasset://textures/Cursor.png",
    },
    Combat = {
        Aimbot = "rbxasset://textures/Cursor.png",
        ESP = "rbxasset://textures/Cursor.png",
        GodMode = "rbxasset://textures/Cursor.png",
        Combat = "rbxasset://textures/Cursor.png",
        Speed = "rbxasset://textures/Cursor.png",
        Flight = "rbxasset://textures/Cursor.png",
        Teleport = "rbxasset://textures/Cursor.png",
        Noclip = "rbxasset://textures/Cursor.png",
        Invisibility = "rbxasset://textures/Cursor.png",
        AutoCollect = "rbxasset://textures/Cursor.png",
        Movement = "rbxasset://textures/Cursor.png",
        Damage = "rbxasset://textures/Cursor.png",
    },
    Interface = {
        Home = "rbxasset://textures/Cursor.png",
        Back = "rbxasset://textures/Cursor.png",
        Forward = "rbxasset://textures/Cursor.png",
        Menu = "rbxasset://textures/Cursor.png",
        Close = "rbxasset://textures/Cursor.png",
        Plus = "rbxasset://textures/Cursor.png",
        Minus = "rbxasset://textures/Cursor.png",
        Folder = "rbxasset://textures/Cursor.png",
        File = "rbxasset://textures/Cursor.png",
        Pin = "rbxasset://textures/Cursor.png",
        Star = "rbxasset://textures/Cursor.png",
    },
}

function Assets:AddCustom(category, name, assetId)
    if not self[category] then
        self[category] = {}
    end
    self[category][name] = assetId
end

local ThemePalettes = {
    --// WHITE V1: Blanco puro, adaptado para fondos blancos claros
    White = {
        Background = Color3.fromRGB(255, 255, 255),
        Secondary = Color3.fromRGB(232, 232, 232),
        AccentOff = Color3.fromRGB(200, 200, 200),
        Text = Color3.fromRGB(0, 0, 0),
        TextDim = Color3.fromRGB(120, 120, 120),
        Stroke = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(0, 0, 0),
        ToggleOn = Color3.fromRGB(52, 199, 89),
    },
    Dark = {
        Background = Color3.fromRGB(24, 24, 27),
        Secondary = Color3.fromRGB(40, 40, 45),
        AccentOff = Color3.fromRGB(58, 58, 64),
        Text = Color3.fromRGB(240, 240, 240),
        TextDim = Color3.fromRGB(160, 160, 165),
        Stroke = Color3.fromRGB(90, 90, 96),
        Accent = Color3.fromRGB(255, 255, 255),
        ToggleOn = Color3.fromRGB(52, 199, 89),
    },
    --// DARK V2: Más oscuro y elegante, adaptado para fondos oscuros (105596249630448)
    DarkV2 = {
        Background = Color3.fromRGB(15, 15, 18),
        Secondary = Color3.fromRGB(30, 30, 36),
        AccentOff = Color3.fromRGB(50, 50, 58),
        Text = Color3.fromRGB(245, 245, 248),
        TextDim = Color3.fromRGB(165, 165, 172),
        Stroke = Color3.fromRGB(80, 80, 90),
        Accent = Color3.fromRGB(255, 255, 255),
        ToggleOn = Color3.fromRGB(52, 199, 89),
    },
    Purple = {
        Background = Color3.fromRGB(20, 10, 35),
        Secondary = Color3.fromRGB(40, 20, 60),
        AccentOff = Color3.fromRGB(70, 40, 100),
        Text = Color3.fromRGB(240, 240, 240),
        TextDim = Color3.fromRGB(180, 160, 200),
        Stroke = Color3.fromRGB(120, 80, 180),
        Accent = Color3.fromRGB(180, 100, 255),
        ToggleOn = Color3.fromRGB(180, 100, 255),
    },
    Blue = {
        Background = Color3.fromRGB(10, 20, 40),
        Secondary = Color3.fromRGB(20, 40, 70),
        AccentOff = Color3.fromRGB(40, 70, 120),
        Text = Color3.fromRGB(230, 240, 255),
        TextDim = Color3.fromRGB(150, 180, 220),
        Stroke = Color3.fromRGB(80, 140, 220),
        Accent = Color3.fromRGB(100, 180, 255),
        ToggleOn = Color3.fromRGB(100, 180, 255),
    },
    --// BLUE V2: Más claro y vibrante, adaptado para fondos azules brillantes (107573562621514)
    BlueV2 = {
        Background = Color3.fromRGB(30, 50, 90),
        Secondary = Color3.fromRGB(50, 80, 140),
        AccentOff = Color3.fromRGB(70, 110, 170),
        Text = Color3.fromRGB(240, 245, 255),
        TextDim = Color3.fromRGB(180, 200, 240),
        Stroke = Color3.fromRGB(100, 160, 240),
        Accent = Color3.fromRGB(120, 200, 255),
        ToggleOn = Color3.fromRGB(120, 200, 255),
    },
    Red = {
        Background = Color3.fromRGB(40, 10, 15),
        Secondary = Color3.fromRGB(70, 20, 30),
        AccentOff = Color3.fromRGB(120, 40, 60),
        Text = Color3.fromRGB(255, 230, 230),
        TextDim = Color3.fromRGB(220, 150, 160),
        Stroke = Color3.fromRGB(220, 80, 100),
        Accent = Color3.fromRGB(255, 100, 120),
        ToggleOn = Color3.fromRGB(255, 100, 120),
    },
    --// RED V2: Más oscuro y elegante, adaptado para fondos rojos profundos (118635431058555)
    RedV2 = {
        Background = Color3.fromRGB(50, 12, 20),
        Secondary = Color3.fromRGB(80, 25, 40),
        AccentOff = Color3.fromRGB(120, 45, 70),
        Text = Color3.fromRGB(255, 235, 235),
        TextDim = Color3.fromRGB(225, 160, 170),
        Stroke = Color3.fromRGB(220, 100, 130),
        Accent = Color3.fromRGB(255, 120, 150),
        ToggleOn = Color3.fromRGB(255, 120, 150),
    },
    Orange = {
        Background = Color3.fromRGB(40, 20, 10),
        Secondary = Color3.fromRGB(70, 35, 20),
        AccentOff = Color3.fromRGB(120, 60, 30),
        Text = Color3.fromRGB(255, 240, 230),
        TextDim = Color3.fromRGB(220, 180, 150),
        Stroke = Color3.fromRGB(220, 140, 60),
        Accent = Color3.fromRGB(255, 160, 80),
        ToggleOn = Color3.fromRGB(255, 160, 80),
    },
    Pink = {
        Background = Color3.fromRGB(35, 15, 25),
        Secondary = Color3.fromRGB(60, 25, 45),
        AccentOff = Color3.fromRGB(100, 50, 80),
        Text = Color3.fromRGB(255, 240, 245),
        TextDim = Color3.fromRGB(220, 170, 200),
        Stroke = Color3.fromRGB(230, 150, 200),
        Accent = Color3.fromRGB(255, 170, 220),
        ToggleOn = Color3.fromRGB(255, 170, 220),
    },
    --// PINK V2: Mucho más claro y luminoso, adaptado para fondos rosa brillante (140206818990660)
    PinkV2 = {
        Background = Color3.fromRGB(240, 200, 220),
        Secondary = Color3.fromRGB(255, 215, 235),
        AccentOff = Color3.fromRGB(230, 180, 210),
        Text = Color3.fromRGB(60, 20, 40),
        TextDim = Color3.fromRGB(100, 50, 80),
        Stroke = Color3.fromRGB(220, 150, 190),
        Accent = Color3.fromRGB(255, 100, 170),
        ToggleOn = Color3.fromRGB(255, 100, 170),
    },
    --// PINK V3: Versión intermedia, más adaptable (122685629557229)
    PinkV3 = {
        Background = Color3.fromRGB(200, 140, 180),
        Secondary = Color3.fromRGB(220, 160, 200),
        AccentOff = Color3.fromRGB(180, 120, 160),
        Text = Color3.fromRGB(255, 240, 250),
        TextDim = Color3.fromRGB(220, 180, 210),
        Stroke = Color3.fromRGB(230, 130, 190),
        Accent = Color3.fromRGB(255, 80, 160),
        ToggleOn = Color3.fromRGB(255, 80, 160),
    },
    --// WHITE V2: Blanco puro mejorado con mejor legibilidad (90931437124122)
    WhiteV2 = {
        Background = Color3.fromRGB(255, 255, 255),
        Secondary = Color3.fromRGB(245, 245, 245),
        AccentOff = Color3.fromRGB(220, 220, 220),
        Text = Color3.fromRGB(20, 20, 25),
        TextDim = Color3.fromRGB(100, 100, 110),
        Stroke = Color3.fromRGB(180, 180, 185),
        Accent = Color3.fromRGB(50, 50, 60),
        ToggleOn = Color3.fromRGB(52, 199, 89),
    },
    --// WHITE AND DARK: Tema mitad blanco, mitad oscuro (85320264713056)
    WhiteAndDark = {
        Background = Color3.fromRGB(240, 240, 240),
        Secondary = Color3.fromRGB(200, 200, 200),
        AccentOff = Color3.fromRGB(170, 170, 170),
        Text = Color3.fromRGB(40, 40, 45),
        TextDim = Color3.fromRGB(110, 110, 120),
        Stroke = Color3.fromRGB(100, 100, 110),
        Accent = Color3.fromRGB(0, 0, 0),
        ToggleOn = Color3.fromRGB(52, 199, 89),
    },
    Green = {
        Background = Color3.fromRGB(20, 50, 35),
        Secondary = Color3.fromRGB(35, 80, 55),
        AccentOff = Color3.fromRGB(60, 120, 90),
        Text = Color3.fromRGB(230, 255, 240),
        TextDim = Color3.fromRGB(160, 220, 190),
        Stroke = Color3.fromRGB(100, 200, 140),
        Accent = Color3.fromRGB(120, 220, 160),
        ToggleOn = Color3.fromRGB(100, 220, 140),
    },
    --// WHITE V3: Blanco puro con textos NEON brillantes y vibrantes (88768864762169)
    WhiteV3 = {
        Background = Color3.fromRGB(255, 255, 255),
        Secondary = Color3.fromRGB(248, 248, 248),
        AccentOff = Color3.fromRGB(230, 230, 230),
        Text = Color3.fromRGB(30, 30, 35),  -- Gris oscuro para verse sobre blanco
        TextDim = Color3.fromRGB(100, 100, 110),
        Stroke = Color3.fromRGB(150, 150, 160),
        Accent = Color3.fromRGB(0, 180, 220),
        ToggleOn = Color3.fromRGB(0, 180, 220),
    },
    --// NARANJA V1: Naranja vibrante y cálido, adaptado para fondos naranjas (90056518364273)
    NaranjaV1 = {
        Background = Color3.fromRGB(50, 30, 15),
        Secondary = Color3.fromRGB(80, 45, 25),
        AccentOff = Color3.fromRGB(120, 70, 40),
        Text = Color3.fromRGB(255, 245, 230),
        TextDim = Color3.fromRGB(230, 190, 150),
        Stroke = Color3.fromRGB(230, 160, 80),
        Accent = Color3.fromRGB(255, 180, 80),
        ToggleOn = Color3.fromRGB(255, 180, 80),
    },
    --// VIOLETA V1: Violeta profundo y elegante, adaptado para fondos violetas (112714301994517)
    VioletaV1 = {
        Background = Color3.fromRGB(40, 15, 50),
        Secondary = Color3.fromRGB(70, 30, 90),
        AccentOff = Color3.fromRGB(110, 50, 140),
        Text = Color3.fromRGB(240, 220, 255),
        TextDim = Color3.fromRGB(200, 150, 220),
        Stroke = Color3.fromRGB(180, 120, 200),
        Accent = Color3.fromRGB(200, 100, 255),
        ToggleOn = Color3.fromRGB(200, 100, 255),
    },
    --// CAT V1: Tema del gato en rama - Rosa-Blanco con efecto rainbow rápido (135950962141755)
    CatV1 = {
        Background = Color3.fromRGB(245, 235, 240),      -- Rosa muy claro
        Secondary = Color3.fromRGB(230, 210, 225),       -- Rosa pálido
        AccentOff = Color3.fromRGB(210, 180, 200),       -- Rosa apagado
        Text = Color3.fromRGB(40, 25, 35),               -- Marrón oscuro
        TextDim = Color3.fromRGB(120, 90, 110),          -- Marrón tenue
        Stroke = Color3.fromRGB(180, 140, 160),          -- Rosa medio
        Accent = Color3.fromRGB(0, 0, 0),                -- Negro puro
        ToggleOn = Color3.fromRGB(255, 100, 150),        -- Rosa caliente
    },
    --// LIGHT V1: Tema luminoso y angelical, inspirado en luz blanca pura
    LightV1 = {
        Background = Color3.fromRGB(250, 250, 252),      -- Blanco muy claro con toque azul
        Secondary = Color3.fromRGB(235, 235, 240),       -- Gris muy claro
        AccentOff = Color3.fromRGB(210, 210, 220),       -- Gris suave
        Text = Color3.fromRGB(40, 45, 55),               -- Gris azulado oscuro
        TextDim = Color3.fromRGB(130, 135, 150),         -- Gris azulado medio
        Stroke = Color3.fromRGB(180, 185, 200),          -- Gris azulado claro
        Accent = Color3.fromRGB(200, 210, 230),          -- Azul muy claro
        ToggleOn = Color3.fromRGB(100, 150, 220),        -- Azul celeste
    },
    --// ERIS V1: Tema rojo oscuro con énfasis en rojo-negro, efecto Rainbow automático Rojo→Dark→White
    ErisV1 = {
        Background = Color3.fromRGB(20, 10, 15),         -- Negro profundo con toque rojo
        Secondary = Color3.fromRGB(40, 15, 25),          -- Rojo muy oscuro
        AccentOff = Color3.fromRGB(60, 20, 40),          -- Rojo oscuro
        Text = Color3.fromRGB(255, 200, 200),            -- Rojo claro/Rosa
        TextDim = Color3.fromRGB(180, 120, 130),         -- Rojo medio/oscuro
        Stroke = Color3.fromRGB(200, 80, 100),           -- Rojo vibrante
        Accent = Color3.fromRGB(255, 80, 100),           -- Rojo puro
        ToggleOn = Color3.fromRGB(255, 100, 120),        -- Rojo caliente
    },
    --// SHYLFIE V1: Tema cálido atardecer - Verde oliva, dorado y crema (80301013485061)
    ShylfieV1 = {
        Background = Color3.fromRGB(35, 40, 28),         -- Verde oliva oscuro
        Secondary = Color3.fromRGB(58, 65, 42),          -- Verde oliva medio
        AccentOff = Color3.fromRGB(85, 90, 58),          -- Verde oliva claro
        Text = Color3.fromRGB(250, 245, 230),            -- Crema cálido
        TextDim = Color3.fromRGB(200, 190, 155),         -- Beige tenue
        Stroke = Color3.fromRGB(180, 165, 115),          -- Dorado apagado
        Accent = Color3.fromRGB(230, 195, 130),          -- Dorado atardecer
        ToggleOn = Color3.fromRGB(255, 215, 145),        -- Dorado brillante
    },
    --// SUKUNA V1: Tema nevado en blanco y negro con acentos rojo sangre (85949954769240)
    SukunaV1 = {
        Background = Color3.fromRGB(14, 14, 14),         -- Negro profundo
        Secondary = Color3.fromRGB(28, 28, 30),          -- Gris muy oscuro
        AccentOff = Color3.fromRGB(48, 48, 50),          -- Gris oscuro
        Text = Color3.fromRGB(235, 235, 235),            -- Blanco casi puro
        TextDim = Color3.fromRGB(160, 160, 160),         -- Gris medio
        Stroke = Color3.fromRGB(180, 25, 30),            -- Rojo sangre
        Accent = Color3.fromRGB(200, 20, 25),            -- Rojo intenso
        ToggleOn = Color3.fromRGB(220, 45, 50),          -- Rojo vibrante
    },
    --// V1: Rostro difuminado en mármol blanco y negro (85300188078480)
    V1 = {
        Background = Color3.fromRGB(232, 232, 232),
        Secondary = Color3.fromRGB(208, 208, 208),
        AccentOff = Color3.fromRGB(180, 180, 180),
        Text = Color3.fromRGB(20, 20, 20),
        TextDim = Color3.fromRGB(95, 95, 95),
        Stroke = Color3.fromRGB(140, 140, 140),
        Accent = Color3.fromRGB(35, 35, 35),
        ToggleOn = Color3.fromRGB(60, 60, 60),
    },
    --// V2: Rostro oscuro entre kanjis, negro con destellos rojos (73784070707058)
    V2 = {
        Background = Color3.fromRGB(10, 10, 14),
        Secondary = Color3.fromRGB(22, 22, 28),
        AccentOff = Color3.fromRGB(42, 42, 50),
        Text = Color3.fromRGB(235, 235, 240),
        TextDim = Color3.fromRGB(150, 150, 160),
        Stroke = Color3.fromRGB(180, 40, 50),
        Accent = Color3.fromRGB(200, 50, 60),
        ToggleOn = Color3.fromRGB(220, 70, 80),
    },
    --// V3: Chica con adorno floral explosivo, alto contraste B/N (75154906255157)
    V3 = {
        Background = Color3.fromRGB(8, 8, 8),
        Secondary = Color3.fromRGB(24, 24, 24),
        AccentOff = Color3.fromRGB(48, 48, 48),
        Text = Color3.fromRGB(245, 245, 245),
        TextDim = Color3.fromRGB(170, 170, 170),
        Stroke = Color3.fromRGB(205, 205, 205),
        Accent = Color3.fromRGB(255, 255, 255),
        ToggleOn = Color3.fromRGB(230, 230, 230),
    },
    --// V4: Silueta casi negra con headband, minimalista oscuro (135645850605905)
    V4 = {
        Background = Color3.fromRGB(5, 5, 5),
        Secondary = Color3.fromRGB(16, 16, 16),
        AccentOff = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(210, 210, 210),
        TextDim = Color3.fromRGB(110, 110, 110),
        Stroke = Color3.fromRGB(65, 65, 65),
        Accent = Color3.fromRGB(95, 95, 95),
        ToggleOn = Color3.fromRGB(150, 150, 150),
    },
    --// V5: Velo de encaje sobre el rostro, B/N suave (132161944582308)
    V5 = {
        Background = Color3.fromRGB(18, 18, 18),
        Secondary = Color3.fromRGB(36, 36, 36),
        AccentOff = Color3.fromRGB(56, 56, 56),
        Text = Color3.fromRGB(240, 240, 240),
        TextDim = Color3.fromRGB(160, 160, 160),
        Stroke = Color3.fromRGB(200, 200, 200),
        Accent = Color3.fromRGB(220, 220, 220),
        ToggleOn = Color3.fromRGB(235, 235, 235),
    },
    --// V6: Ángel con laúd, tono sepia clásico (99625131409582)
    V6 = {
        Background = Color3.fromRGB(28, 25, 20),
        Secondary = Color3.fromRGB(50, 45, 38),
        AccentOff = Color3.fromRGB(75, 68, 55),
        Text = Color3.fromRGB(240, 235, 220),
        TextDim = Color3.fromRGB(190, 180, 160),
        Stroke = Color3.fromRGB(160, 150, 130),
        Accent = Color3.fromRGB(210, 195, 160),
        ToggleOn = Color3.fromRGB(225, 205, 160),
    },
    --// V9: Ojos grandes en close-up, manga en gris (99554561815921)
    V9 = {
        Background = Color3.fromRGB(30, 30, 30),
        Secondary = Color3.fromRGB(50, 50, 50),
        AccentOff = Color3.fromRGB(75, 75, 75),
        Text = Color3.fromRGB(245, 245, 245),
        TextDim = Color3.fromRGB(175, 175, 175),
        Stroke = Color3.fromRGB(150, 150, 150),
        Accent = Color3.fromRGB(230, 230, 230),
        ToggleOn = Color3.fromRGB(255, 255, 255),
    },
    --// V10: Energía morada con rayos y detalles rojos (122520620665113)
    V10 = {
        Background = Color3.fromRGB(18, 10, 25),
        Secondary = Color3.fromRGB(35, 18, 50),
        AccentOff = Color3.fromRGB(60, 30, 85),
        Text = Color3.fromRGB(240, 225, 255),
        TextDim = Color3.fromRGB(190, 160, 220),
        Stroke = Color3.fromRGB(170, 90, 220),
        Accent = Color3.fromRGB(190, 100, 255),
        ToggleOn = Color3.fromRGB(210, 130, 255),
    },
    --// V11: Rostro con marco ornamentado rojizo (93259710745008)
    V11 = {
        Background = Color3.fromRGB(20, 10, 12),
        Secondary = Color3.fromRGB(38, 20, 24),
        AccentOff = Color3.fromRGB(62, 36, 40),
        Text = Color3.fromRGB(245, 225, 225),
        TextDim = Color3.fromRGB(200, 160, 165),
        Stroke = Color3.fromRGB(210, 160, 170),
        Accent = Color3.fromRGB(220, 150, 160),
        ToggleOn = Color3.fromRGB(230, 170, 180),
    },
    --// PIBBLE V1: Cachorro blanco sobre manta gris, tonos suaves (108798897997443)
    PibbleV1 = {
        Background = Color3.fromRGB(58, 63, 70),
        Secondary = Color3.fromRGB(88, 93, 100),
        AccentOff = Color3.fromRGB(118, 123, 128),
        Text = Color3.fromRGB(250, 248, 245),
        TextDim = Color3.fromRGB(200, 195, 190),
        Stroke = Color3.fromRGB(228, 180, 190),
        Accent = Color3.fromRGB(240, 200, 210),
        ToggleOn = Color3.fromRGB(255, 210, 220),
    },
}

--// IMÁGENES DE FONDO POR TEMA (decorativas, se muestran detrás del contenido)
local ThemeBackgroundImages = {
    Dark = "rbxassetid://138004303203419",
    DarkV2 = "rbxassetid://105596249630448",
    Pink = "rbxassetid://129299161197887",
    PinkV2 = "rbxassetid://140206818990660",
    PinkV3 = "rbxassetid://122685629557229",
    Blue = "rbxassetid://136072951221172",
    BlueV2 = "rbxassetid://107573562621514",
    Red = "rbxassetid://88289923848664",
    RedV2 = "rbxassetid://118635431058555",
    White = "rbxassetid://129555461947864",
    WhiteV2 = "rbxassetid://90931437124122",
    WhiteV3 = "rbxassetid://88768864762169",
    WhiteAndDark = "rbxassetid://85320264713056",
    Green = "rbxassetid://86357167554483",
    NaranjaV1 = "rbxassetid://90056518364273",
    VioletaV1 = "rbxassetid://112714301994517",
    CatV1 = "rbxassetid://135950962141755",  --  Gato en rama
    LightV1 = "rbxassetid://85339946380507",  --  Angel luminoso blanco
    ErisV1 = "rbxassetid://134043807878571",  -- 🔴 Personaje rojo-oscuro
    ShylfieV1 = "rbxassetid://80301013485061",  -- Chica orejas élficas atardecer (actualizado)
    SukunaV1 = "rbxassetid://85949954769240",  -- Personaje nevado B/N
    V1 = "rbxassetid://85300188078480",
    V2 = "rbxassetid://73784070707058",
    V3 = "rbxassetid://75154906255157",
    V4 = "rbxassetid://135645850605905",
    V5 = "rbxassetid://132161944582308",
    V6 = "rbxassetid://99625131409582",
    V9 = "rbxassetid://99554561815921",
    V10 = "rbxassetid://122520620665113",
    V11 = "rbxassetid://93259710745008",
    PibbleV1 = "rbxassetid://108798897997443",
}

--// Efectos automáticos por tema (se llena desde el repo externo)
local ThemeAutoEffects = {
    CatV1     = "CatRainbow",
    ErisV1    = "ErisRainbow",
    ShylfieV1 = "ShylfieRainbow",
    SukunaV1  = "SukunaRainbow",
}

--// Orden de temas (se reemplaza con el del repo externo si descarga ok)
local ThemeOrder = nil

--// ════════════════════════════════════════════════════════════════
--// SISTEMA DE TEMAS EXTERNOS (LoadThemes)
--// Siempre intenta descargar primero.
--// Solo usa caché si falla internet.
--// Solo usa embebido si no hay caché.
--// ════════════════════════════════════════════════════════════════
local THEMES_URL        = "https://raw.githubusercontent.com/Yinyangzx/Temas/refs/heads/main/YinYang_Themes.lua"
local THEMES_CACHE_FILE = "yin_yang_themes_cache.lua"

local function LoadThemes()
    local rawData = nil

    --// PASO 1: Intentar descargar siempre primero
    --// Usamos game:HttpGet() — funciona en Delta y la mayoría de executors
    --// HttpService:GetAsync() da "blocked" en executors móviles como Delta
    local dlOk, dlResult = pcall(function()
        return game:HttpGet(THEMES_URL, true)
    end)

    if dlOk and type(dlResult) == "string" and #dlResult > 20 then
        rawData = dlResult
        print("[YinYang Themes] ✅ Temas descargados desde repo")
        --// Actualizar caché con lo descargado
        pcall(function()
            if writefile then
                writefile(THEMES_CACHE_FILE, rawData)
                print("[YinYang Themes] 💾 Caché actualizada")
            end
        end)
    else
        --// PASO 2: Descarga falló → intentar caché local
        print("[YinYang Themes] ⚠️ Descarga falló, intentando caché...")
        pcall(function()
            if readfile and isfile and isfile(THEMES_CACHE_FILE) then
                rawData = readfile(THEMES_CACHE_FILE)
                print("[YinYang Themes] 📁 Usando caché local")
            end
        end)
    end

    --// PASO 3: Si tenemos datos (de descarga o caché), procesarlos
    if rawData then
        local parseOk, data = pcall(function()
            return loadstring(rawData)()
        end)

        if parseOk and type(data) == "table" and data.Themes then
            local count = 0
            --// Mergear temas externos en las tablas existentes
            for name, theme in pairs(data.Themes) do
                if theme.Palette then
                    ThemePalettes[name] = theme.Palette
                end
                if theme.Sound then
                    ThemeClickSounds[name] = theme.Sound
                end
                if theme.Background then
                    ThemeBackgroundImages[name] = theme.Background
                end
                if theme.Effect and theme.Effect ~= "Off" then
                    ThemeAutoEffects[name] = theme.Effect
                end
                count = count + 1
            end

            --// Guardar orden del repo
            if data.Order then
                ThemeOrder = data.Order
            end

            print("[YinYang Themes] ✅ " .. count .. " temas cargados (v" .. tostring(data.Version or "?") .. ")")
            return true
        else
            print("[YinYang Themes] ❌ Error al parsear datos de temas")
        end
    else
        print("[YinYang Themes] ❌ Sin datos disponibles, usando temas embebidos")
    end

    --// PASO 4: Todo falló → las tablas embebidas quedan intactas como fallback
    return false
end

LoadThemes()

--// ════════════════════════════════════════════════════════════════
--// TABLAS DE STICKERS (se rellenan con LoadStickers)
--// ⚠️ NO ELIMINAR — fallback embebido si el repo no está disponible
--// ════════════════════════════════════════════════════════════════
local StickerPalettes = {
    Sonrisa  = { Image = "rbxassetid://135857695171095", LabelES = "Sonrisa",  LabelEN = "Smile"     },
    Llorar   = { Image = "rbxassetid://138363247925206", LabelES = "Llorar",   LabelEN = "Crying"    },
    Amor     = { Image = "rbxassetid://76164124882568",  LabelES = "Amor",     LabelEN = "Love"      },
    Corazon  = { Image = "rbxassetid://76164124882568",  LabelES = "Corazón",  LabelEN = "Heart"     },
    Emoji    = { Image = "rbxassetid://133861773375312", LabelES = "Emoji",    LabelEN = "Emoji"     },
    Risa     = { Image = "rbxassetid://109165098870367", LabelES = "Risa",     LabelEN = "Laugh"     },
    Sorpresa = { Image = "rbxassetid://89213081637073",  LabelES = "Sorpresa", LabelEN = "Surprised" },
    Triste   = { Image = "rbxassetid://80817302481160",  LabelES = "Triste",   LabelEN = "Sad"       },
    Enojado  = { Image = "rbxassetid://72815688632249",  LabelES = "Enojado",  LabelEN = "Angry"     },
    Wink     = { Image = "rbxassetid://72602706593283",  LabelES = "Guiño",    LabelEN = "Wink"      },
    Cool     = { Image = "rbxassetid://129224642026377", LabelES = "Cool",     LabelEN = "Cool"      },
}

-- nil hasta que LoadStickers() corra exitosamente
local StickerOrder = nil

--// ════════════════════════════════════════════════════════════════
--// SISTEMA DE STICKERS EXTERNOS (LoadStickers)
--// Siempre intenta descargar primero.
--// Solo usa caché si falla internet.
--// Solo usa embebido si no hay caché.
--// ⚠️ NO ELIMINAR
--// ════════════════════════════════════════════════════════════════
local STICKERS_URL        = "https://raw.githubusercontent.com/Yinyangzx/Yin-Stickers/refs/heads/main/YinYang_Stickers.lua"
local STICKERS_CACHE_FILE = "yin_yang_stickers_cache.lua"

local function LoadStickers()
    local rawData = nil

    --// PASO 1: Intentar descargar siempre primero
    --// Usamos game:HttpGet() — funciona en Delta y la mayoría de executors
    --// HttpService:GetAsync() da "blocked" en executors móviles como Delta
    local dlOk, dlResult = pcall(function()
        return game:HttpGet(STICKERS_URL, true)
    end)

    if dlOk and type(dlResult) == "string" and #dlResult > 20 then
        rawData = dlResult
        print("[YinYang Stickers] ✅ Stickers descargados desde repo")
        --// Actualizar caché con lo descargado
        pcall(function()
            if writefile then
                writefile(STICKERS_CACHE_FILE, rawData)
                print("[YinYang Stickers] 💾 Caché actualizada")
            end
        end)
    else
        --// PASO 2: Descarga falló → intentar caché local
        print("[YinYang Stickers] ⚠️ Descarga falló, intentando caché...")
        pcall(function()
            if readfile and isfile and isfile(STICKERS_CACHE_FILE) then
                rawData = readfile(STICKERS_CACHE_FILE)
                print("[YinYang Stickers] 📁 Usando caché local")
            end
        end)
    end

    --// PASO 3: Si tenemos datos (de descarga o caché), procesarlos
    if rawData then
        local parseOk, data = pcall(function()
            return loadstring(rawData)()
        end)

        if parseOk and type(data) == "table" and data.Stickers then
            local count = 0
            --// Mergear stickers externos en la tabla embebida
            for name, sticker in pairs(data.Stickers) do
                if sticker.Image then
                    StickerPalettes[name] = {
                        Image   = sticker.Image,
                        LabelES = sticker.LabelES or name,
                        LabelEN = sticker.LabelEN or name,
                    }
                    count = count + 1
                end
            end

            --// Guardar orden del repo
            if data.Order then
                StickerOrder = data.Order
            end

            print("[YinYang Stickers] ✅ " .. count .. " stickers cargados (v" .. tostring(data.Version or "?") .. ")")
            return true
        else
            print("[YinYang Stickers] ❌ Error al parsear datos de stickers")
        end
    else
        print("[YinYang Stickers] ❌ Sin datos disponibles, usando stickers embebidos")
    end

    --// PASO 4: Todo falló → StickerPalettes embebida queda intacta como fallback
    return false
end

LoadStickers()

local Theme

--// UTILIDADES
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    pcall(function() o.Selectable = false end)
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
        pcall(function() o.AutoLocalize = false end)
    end
    if o:IsA("TextButton") or o:IsA("ImageButton") then
        pcall(function() o.AutoButtonColor = false end)
    end
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(p, r)
    mk("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p)
end

local function stroke(p, col, th, trans)
    local s = mk("UIStroke", {Color = col, Thickness = th or 1.5, Transparency = trans or 0}, p)
    s:SetAttribute("ThemeRole", "Stroke")
    return s
end

--// ════════════════════════════════════════════════════════════════
--// EFECTO DE BRILLO ANIMADO EN BORDES (v28 PRO)
--// Inner Glow + Outer Glow + Stroke Gradiente + Light Sweep
--// Basado en: UIStroke + UIGradient + TweenService
--// ════════════════════════════════════════════════════════════════

local ActiveGlowTweens = {}

local function stopGlowTweens(key)
    if ActiveGlowTweens[key] then
        for _, tw in ipairs(ActiveGlowTweens[key]) do
            pcall(function() tw:Cancel() end)
        end
        ActiveGlowTweens[key] = nil
    end
end

--// Limpia GlowLayers que pertenecen a un frame específico (por tag único)
local function cleanGlowLayers(frame)
    local tag = "GLOW_" .. tostring(frame)
    if frame.Parent then
        for _, child in ipairs(frame.Parent:GetChildren()) do
            if child:GetAttribute("GlowOwner") == tag then
                child:Destroy()
            end
        end
    end
end

--// GLOW PARA VENTANA PRINCIPAL: sibling en el mismo contenedor (NO en ScreenGui)
--// Solo se usa cuando el parent NO es ScreenGui
local function addGlowSibling(frame, thickness, transparency, color, cornerRadius)
    local container = frame.Parent
    -- NUNCA crear sibling si el parent es ScreenGui o PlayerGui
    if not container or container:IsA("ScreenGui") or container:IsA("PlayerGui") then
        return nil, nil
    end

    local tag = "GLOW_" .. tostring(frame)
    local layer = Instance.new("Frame")
    layer.Name = "GlowLayer"
    layer:SetAttribute("GlowOwner", tag)
    layer.BackgroundTransparency = 1
    layer.Size = frame.Size
    layer.Position = frame.Position
    layer.AnchorPoint = frame.AnchorPoint
    layer.ZIndex = math.max(1, frame.ZIndex - 1)
    layer.Parent = container

    local c = Instance.new("UICorner")
    c.CornerRadius = cornerRadius or UDim.new(0, 10)
    c.Parent = layer

    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Thickness = thickness
    s.Transparency = transparency
    s.Color = color
    s.LineJoinMode = Enum.LineJoinMode.Round
    s.Parent = layer

    return layer, s
end

--// GLOW DIRECTO: anima el UIStroke existente del frame (para FloatingToggle y casos en ScreenGui)
local function buildGlowOnStroke(frame, accentColor, cornerRadius)
    local key = tostring(frame)
    stopGlowTweens(key)

    local existingStroke = frame:FindFirstChildOfClass("UIStroke")
    if not existingStroke then return end

    -- Limpiar gradient anterior si existe
    local oldGrad = existingStroke:FindFirstChildOfClass("UIGradient")
    if oldGrad then oldGrad:Destroy() end

    local h, s, v = Color3.toHSV(accentColor)
    local accentLight = Color3.fromHSV(h, math.max(0, s - 0.3), math.min(1, v + 0.25))
    local accentDark  = Color3.fromHSV(h, math.min(1, s + 0.1), math.max(0, v - 0.25))

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accentDark),
        ColorSequenceKeypoint.new(0.5, accentLight),
        ColorSequenceKeypoint.new(1, accentDark),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.4),
    })
    grad.Offset = Vector2.new(-1.5, 0)
    grad.Parent = existingStroke

    local sweepTween = TweenService:Create(
        grad,
        TweenInfo.new(1.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        { Offset = Vector2.new(1.5, 0) }
    )
    sweepTween:Play()

    local pulseTween = TweenService:Create(
        existingStroke,
        TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Transparency = 0.0 }
    )
    pulseTween:Play()

    ActiveGlowTweens[key] = { sweepTween, pulseTween }
end

local function buildAnimatedBorder(frame, accentColor, cornerRadius, forceStrokeOnly)
    local key = tostring(frame)
    stopGlowTweens(key)
    cleanGlowLayers(frame)

    local cr = cornerRadius or UDim.new(0, 10)
    local h, s, v = Color3.toHSV(accentColor)
    local accentLight = Color3.fromHSV(h, math.max(0, s - 0.3), math.min(1, v + 0.25))
    local accentDark  = Color3.fromHSV(h, math.min(1, s + 0.1), math.max(0, v - 0.25))

    -- Si forceStrokeOnly=true, o el parent es ScreenGui: solo animar stroke existente
    local parentIsScreenGui = frame.Parent and (frame.Parent:IsA("ScreenGui") or frame.Parent:IsA("PlayerGui"))
    
    if forceStrokeOnly or parentIsScreenGui then
        buildGlowOnStroke(frame, accentColor, cr)
        return
    end

    -- Para Main window (parent es un Frame normal): sibling con glow fino
    local _, outerStroke = addGlowSibling(frame, 10, 0.55, accentColor, cr)
    local _, innerStroke = addGlowSibling(frame, 3, 0.20, accentLight, cr)

    if not outerStroke or not innerStroke then
        -- Fallback: solo stroke
        buildGlowOnStroke(frame, accentColor, cr)
        return
    end

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accentDark),
        ColorSequenceKeypoint.new(0.5, accentLight),
        ColorSequenceKeypoint.new(1, accentDark),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.2),
    })
    grad.Offset = Vector2.new(-1.5, 0)
    grad.Parent = innerStroke

    local sweepTween = TweenService:Create(
        grad,
        TweenInfo.new(1.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        { Offset = Vector2.new(1.5, 0) }
    )
    sweepTween:Play()

    local pulseTween = TweenService:Create(
        outerStroke,
        TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Transparency = 0.30, Thickness = 14 }
    )
    pulseTween:Play()

    ActiveGlowTweens[key] = { sweepTween, pulseTween }
end

local function resetScrollTop(scrollingFrame)
    task.defer(function()
        if scrollingFrame and scrollingFrame.Parent then
            scrollingFrame.CanvasPosition = Vector2.new(0, 0)
        end
    end)
end

local function formatDuration(totalSeconds)
    totalSeconds = math.floor(totalSeconds)
    local h = math.floor(totalSeconds / 3600)
    local m = math.floor((totalSeconds % 3600) / 60)
    local s = totalSeconds % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function createStatGrid(parent)
    local Grid = mk("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 9
    })
    mk("UIGridLayout", {
        CellPadding = UDim2.new(0, 8, 0, 8),
        CellSize = UDim2.new(0.5, -4, 0, 54),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, Grid)
    return Grid
end

local function createStatTile(grid, labelSpanish, labelEnglish)
    labelEnglish = labelEnglish or labelSpanish
    local Tile = mk("Frame", {
        Parent = grid,
        BackgroundColor3 = Theme.Secondary,
        ZIndex = 9
    })
    Tile:SetAttribute("ThemeRole", "Secondary")
    corner(Tile, 6)
    stroke(Tile, Color3.fromRGB(0, 0, 0), 1, 0.6)

    local TileLabel = mk("TextLabel", {
        Parent = Tile,
        Size = UDim2.new(1, -16, 0, 16),
        Position = UDim2.new(0, 8, 0, 6),
        BackgroundTransparency = 1,
        Text = GetText(labelSpanish, labelEnglish),
        TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 10
    })
    TileLabel:SetAttribute("ThemeRole", "TextDim")
    TileLabel:SetAttribute("TextSpanish", labelSpanish)
    TileLabel:SetAttribute("TextEnglish", labelEnglish)

    local ValueText = mk("TextLabel", {
        Parent = Tile,
        Size = UDim2.new(1, -16, 0, 22),
        Position = UDim2.new(0, 8, 0, 24),
        BackgroundTransparency = 1,
        Text = "...",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 10
    })
    ValueText:SetAttribute("ThemeRole", "Text")

    return Tile, ValueText
end

--// Calcula si un texto/símbolo debe ser blanco o negro según el brillo del fondo
-- Así garantizamos contraste SIN cambiar el color de acento de ningún tema (ej: el blanco de Dark)
local function getContrastColor(bgColor)
    local luminance = 0.299 * bgColor.R + 0.587 * bgColor.G + 0.114 * bgColor.B
    if luminance > 0.6 then
        return Color3.fromRGB(25, 25, 25)
    end
    return Color3.fromRGB(255, 255, 255)
end

-- ThemeRole -> controla BackgroundColor3 (o Color en UIStroke)
-- ThemeTextRole -> controla TextColor3, independiente del rol de fondo
local function swapThemeColor(obj, palette)
    local bgRole = obj:GetAttribute("ThemeRole")
    if bgRole and palette[bgRole] then
        if obj:IsA("UIStroke") then
            obj.Color = palette[bgRole]
        elseif obj:IsA("GuiObject") then
            pcall(function() obj.BackgroundColor3 = palette[bgRole] end)
        end
    end

    local textRole = obj:GetAttribute("ThemeTextRole")
    if textRole and palette[textRole] then
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            obj.TextColor3 = palette[textRole]
        end
    end
end

--// Centraliza el cambio de tema: clona la paleta y calcula el color de contraste (AccentText)
-- para que cualquier texto/símbolo sobre un fondo Accent (ej: blanco en Dark) siga siendo legible
-- sin tener que tocar el color de acento del tema.
local function setActiveTheme(name)
    local palette = ThemePalettes[name]
    if not palette then return false end
    Theme = table.clone(palette)
    Theme.AccentText = getContrastColor(Theme.Accent)
    return true
end

setActiveTheme("Dark")

--// MAIN OBJECT - Global para que otros scripts puedan usarlo
_G.YinYang = {}
local YinYang = _G.YinYang
YinYang.__index = YinYang

function YinYang:CreateWindow(title_text, startTheme)
    startTheme = startTheme or "Dark"

    local ConfigCargada = LoadConfig()
    if ConfigCargada then
        if ConfigCargada.libMode then
            SavedConfig.LibrarySizeMode = ConfigCargada.libMode
        end
        if ConfigCargada.libHeight then
            SavedConfig.LibraryHeight = ConfigCargada.libHeight
        end
        if ConfigCargada.effect then
            SavedConfig.CurrentEffect = ConfigCargada.effect
        end
        if ConfigCargada.volume then
            SavedConfig.Volume = ConfigCargada.volume
        end
    end

    setActiveTheme(startTheme)

    local globalConnections = {}
    local function track(conn)
        table.insert(globalConnections, conn)
        return conn
    end

    local ScreenGui = mk("ScreenGui", {
        Name = "ZeroMobile",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 100
    }, LocalPlayer:WaitForChild("PlayerGui"))

    pcall(function()
        ScreenGui.AutoLocalize = false
    end)

    --// BOTÓN TOGGLE CON LOGO YIN-YANG
    local ToggleButton = mk("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.new(0, 46, 0, 46),
        Position = UDim2.new(0, 24, 0, 70),
        BackgroundColor3 = Theme.Accent,
        Text = "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        ZIndex = 30,
    }, ScreenGui)
    ToggleButton:SetAttribute("ThemeRole", "Accent")
    corner(ToggleButton, 999)
    stroke(ToggleButton, Theme.Accent, 1.5)

    --// LOGO YIN-YANG ROTATIVO
    local YinYangLogo = mk("ImageLabel", {
        Parent = ToggleButton,
        Size = UDim2.new(2, 0, 2, 0),
        Position = UDim2.new(-0.5, 0, -0.5, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://84935900372278",
        ZIndex = 31
    })

    --// ROTACIÓN CONTINUA DEL YIN-YANG
    local YinYangRotation = mk("UIAspectRatioConstraint", {
        AspectRatio = 1
    }, YinYangLogo)

    local rotationSpeed = 0
    game:GetService("RunService").RenderStepped:Connect(function()
        rotationSpeed = rotationSpeed + 2
        if rotationSpeed > 360 then rotationSpeed = 0 end
        YinYangLogo.Rotation = rotationSpeed
    end)

    --// SONIDO DE DRAGÓN ALEATORIO CUANDO ESTÁ CERRADO
    local dragonTimer = 0
    local dragonConnection
    dragonConnection = game:GetService("RunService").Heartbeat:Connect(function()
        dragonTimer = dragonTimer + 1
        if dragonTimer > 900 then -- Cada 15 segundos
            dragonTimer = 0
            if not Main or not Main.Visible then
                playSound(Sounds.Dragon, 0.15)
            end
        end
    end)

    local ToggleScale = mk("UIScale", {Scale = 1}, ToggleButton)
    local idlePulse = TweenService:Create(
        ToggleScale,
        TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Scale = 1.08}
    )
    idlePulse:Play()

    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            idlePulse:Pause()
            playSound(Sounds.Click, 0.6)
            TweenService:Create(ToggleScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.88}):Play()
        end
    end)
    ToggleButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local backTween = TweenService:Create(ToggleScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
            backTween:Play()
            backTween.Completed:Once(function()
                idlePulse:Play()
            end)
        end
    end)

    --// VENTANA PRINCIPAL - SOMBRA MEJORADA
    local shownSize = UDim2.new(0, 420, 0, 340)
    local ShadowFrame = mk("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.98,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = ScreenGui
    })
    corner(ShadowFrame, 10)
    ShadowFrame:SetAttribute("ThemeRole", "Stroke")

    local Main = mk("Frame", {
        Name = "Main",
        Size = shownSize,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = true,
        ZIndex = 5
    }, ScreenGui)
    Main:SetAttribute("ThemeRole", "Background")
    corner(Main, 10)
    stroke(Main, Theme.Stroke, 1.5)

    -- Efecto de brillo animado en el borde de la ventana principal
    buildAnimatedBorder(Main, Theme.Accent, UDim.new(0, 10))

    local BackgroundArt -- se crea más abajo, dentro de ContentArea (ver comentario ahí)

    local function updateShadowPos()
        ShadowFrame.Size = UDim2.new(Main.Size.X.Scale, Main.Size.X.Offset + 4, Main.Size.Y.Scale, Main.Size.Y.Offset + 4)
        ShadowFrame.Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset - 2, Main.Position.Y.Scale, Main.Position.Y.Offset - 2)
    end
    Main:GetPropertyChangedSignal("Size"):Connect(updateShadowPos)
    Main:GetPropertyChangedSignal("Position"):Connect(updateShadowPos)

    local uiVisible = true
    ToggleButton.MouseButton1Click:Connect(function()
        uiVisible = not uiVisible
        if uiVisible then
            Main.Visible = true
            Main.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = shownSize}):Play()
        else
            local tw = TweenService:Create(Main, TweenInfo.new(0.18, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
            tw:Play()
            tw.Completed:Wait()
            Main.Visible = false
        end
    end)

    do
        local drag = false
        local dragStart, startPos
        ToggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if not IconoCongelado then  -- 🔒 SOLO permitir drag si NO está congelado
                    drag = true
                    dragStart = input.Position
                    startPos = ToggleButton.Position
                end
            end
        end)
        track(UserInputService.InputChanged:Connect(function(input)
            if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                ToggleButton.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
            end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                drag = false
            end
        end))
    end

    local TopBar = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Background,
        ZIndex = 6,
    }, Main)
    TopBar:SetAttribute("ThemeRole", "Background")
    corner(TopBar, 10)
    local TitleDivider = mk("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Stroke, ZIndex = 7}, TopBar)
    TitleDivider:SetAttribute("ThemeRole", "Stroke")

    --// Efecto glow animado en la línea divisora del título
    local divStroke = Instance.new("UIStroke")
    divStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    divStroke.Thickness = 1
    divStroke.Transparency = 0.4
    divStroke.Color = Theme.Accent
    divStroke.LineJoinMode = Enum.LineJoinMode.Round
    divStroke.Parent = TitleDivider

    local divGrad = Instance.new("UIGradient")
    divGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(Color3.toHSV(Theme.Accent))),
        ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(Color3.toHSV(Theme.Accent))),
    })
    divGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.7),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.7),
    })
    divGrad.Offset = Vector2.new(-1.5, 0)
    divGrad.Parent = divStroke

    TweenService:Create(
        divGrad,
        TweenInfo.new(2.0, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        { Offset = Vector2.new(1.5, 0) }
    ):Play()

    local TitleLabel = mk("TextLabel", {
        Size = UDim2.new(0, 120, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = title_text or "ZERO UI",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7
    }, TopBar)
    TitleLabel:SetAttribute("ThemeTextRole", "Text")


    --// BOOMBOX: Píldora en el centro del TopBar
    local BoomboxSound = nil

    local BoomboxPill = mk("Frame", {
        Size = UDim2.new(0, 155, 0, 28),
        Position = UDim2.new(0.5, -77, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(5, 5, 8),
        BackgroundTransparency = 0,
        ZIndex = 10,
    }, TopBar)
    corner(BoomboxPill, 999)

    --// Stroke con glow animado IGUAL al de los bordes de la librería
    local boomStroke = mk("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 2,
        Transparency = 0.2,
        Color = Color3.new(1, 1, 1),
        LineJoinMode = Enum.LineJoinMode.Round,
    }, BoomboxPill)

    local boomGrad = mk("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 160, 160)),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.5),
        }),
        Offset = Vector2.new(-1.5, 0),
    }, boomStroke)

    TweenService:Create(boomGrad,
        TweenInfo.new(1.6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        { Offset = Vector2.new(1.5, 0) }
    ):Play()

    TweenService:Create(boomStroke,
        TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Transparency = 0.0, Thickness = 3 }
    ):Play()

    --// Icono compás (sin emoji, solo asset)
    mk("ImageLabel", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 6, 0.5, -9),
        BackgroundTransparency = 1,
        Image = "rbxassetid://75018103027872",
        ScaleType = Enum.ScaleType.Fit,
        ImageColor3 = Color3.new(1, 1, 1),
        ZIndex = 12,
    }, BoomboxPill)

    --// Placeholder "boombox" (TextLabel, se oculta al escribir)
    local BoomboxPlaceholder = mk("TextLabel", {
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.new(0, 28, 0, 0),
        BackgroundTransparency = 1,
        Text = "boombox",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 11,
    }, BoomboxPill)

    --// TextBox encima (captura el input, sin texto ni placeholder propio)
    local BoomboxInput = mk("TextBox", {
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.new(0, 28, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        ZIndex = 13,
    }, BoomboxPill)

    --// Al escribir 1 carácter: placeholder desaparece
    BoomboxInput:GetPropertyChangedSignal("Text"):Connect(function()
        BoomboxPlaceholder.Visible = BoomboxInput.Text == ""
    end)

    local function playBoombox(id)
        if BoomboxSound then
            pcall(function() BoomboxSound:Stop() BoomboxSound:Destroy() end)
            BoomboxSound = nil
        end
        if not id or id == "" then return end
        local cleanId = id:match("%d+")
        if not cleanId then return end
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = "rbxassetid://" .. cleanId
            s.Volume = 0.8
            s.Looped = true
            s.Parent = workspace
            s:Play()
            BoomboxSound = s
            print("Boombox: reproduciendo " .. cleanId)
        end)
    end

    BoomboxInput.FocusLost:Connect(function()
        local text = BoomboxInput.Text:gsub("%s+", "")
        if text == "" then
            if BoomboxSound then
                pcall(function() BoomboxSound:Stop() BoomboxSound:Destroy() end)
                BoomboxSound = nil
            end
            BoomboxPlaceholder.Visible = true
        else
            playBoombox(text)
        end
    end)

    --//  ANIMACIÓN YIN-YANG ÉPICA EN EL TÍTULO (v27)
    --// Si el título contiene "Yin" o "Yang", aplica animación especial
    if title_text and (string.find(title_text, "Yin") or string.find(title_text, "Yang")) then
        local animValue = 0
        local animSpeed = 0.3  -- Muy lentamente
        local origColor = TitleLabel.TextColor3
        
        track(RunService.RenderStepped:Connect(function()
            animValue = (animValue + animSpeed) % 360
            
            -- Calcular valor de interpolación (0 a 1 a 0)
            local sine = (math.sin(math.rad(animValue)) + 1) / 2  -- 0 a 1
            
            -- Si contiene "Yin", cambia Negro↔Blanco
            -- Si contiene "Yang", cambia Blanco↔Negro (inverso)
            if string.find(title_text, "Yin Yang") or string.find(title_text, "yin yang") then
                -- Ambos presentes: Yin va Negro→Blanco, Yang va Blanco→Negro
                TitleLabel.TextColor3 = Color3.fromRGB(
                    math.floor(255 * sine),
                    math.floor(255 * sine),
                    math.floor(255 * sine)
                )
            else
                TitleLabel.TextColor3 = Color3.fromRGB(
                    math.floor(255 * sine),
                    math.floor(255 * sine),
                    math.floor(255 * sine)
                )
            end
        end))
    end

    do
        local drag = false
        local dragStart, startPos
        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                drag = true
                dragStart = input.Position
                startPos = Main.Position
            end
        end)
        track(UserInputService.InputChanged:Connect(function(input)
            if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                drag = false
            end
        end))
    end

    local Body = mk("Frame", {
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        ZIndex = 6
    }, Main)

    local TabList = mk("ScrollingFrame", {
        Size = UDim2.new(0, 110, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        CanvasPosition = Vector2.new(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 7
    }, Body)
    TabList:SetAttribute("ThemeRole", "Secondary")
    corner(TabList, 10)
    mk("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }, TabList)
    mk("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, TabList)
    mk("Frame", {Parent = Body, Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0, 109, 0, 0), BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.82, BorderSizePixel = 0, ZIndex = 8}, Body):SetAttribute("ThemeRole", "Stroke")

    local ContentArea = mk("Frame", {
        Size = UDim2.new(1, -110, 1, 0),
        Position = UDim2.new(0, 110, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 7
    }, Body)
    mk("UIPadding", {PaddingTop = UDim.new(0, 0), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15)}, ContentArea)

    --// FONDO DECORATIVO SEGÚN EL TEMA
    -- IMPORTANTE: vive DENTRO de ContentArea (no de todo Main). Antes cubría toda la
    -- ventana pero el TabList (110px) tapaba la mitad izquierda, así que lo que se
    -- veía era un recorte descentrado de la imagen. Al vivir solo en el área visible,
    -- con AnchorPoint centrado, la imagen queda realmente centrada en lo que el usuario ve.
    BackgroundArt = mk("ImageLabel", {
        Name = "BackgroundArt",
        Parent = ContentArea,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 30, 1, 30),  -- Agrandado +15px por lado para desbordar el padding (15px)
        BackgroundTransparency = 1,
        Image = ThemeBackgroundImages[startTheme] or "",
        ImageTransparency = 0.1,
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 5
    })
    corner(BackgroundArt, 8)

    local Overlay = mk("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 200,
    }, Main)

    local currentDropdownClose = nil

    local function attachDropdownBehavior(Holder, Click, Chevron, optionsCount, buildPopupContents)
        local isOpen = false
        local closePopup

        local function open()
            if currentDropdownClose then currentDropdownClose() end
            isOpen = true
            Chevron.Text = "^"

            local backdrop = mk("TextButton", {
                Parent = Overlay,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 201
            })

            local relX = Holder.AbsolutePosition.X - Main.AbsolutePosition.X
            local relY = Holder.AbsolutePosition.Y - Main.AbsolutePosition.Y + Holder.AbsoluteSize.Y + 4
            local itemH = 32
            local maxH = 160
            local contentH = math.max(optionsCount, 1) * (itemH + 4) + 8
            local popupH = math.min(contentH, maxH)

            local Popup = mk("ScrollingFrame", {
                Parent = Overlay,
                Position = UDim2.new(0, relX, 0, relY),
                Size = UDim2.new(0, Holder.AbsoluteSize.X, 0, popupH),
                BackgroundColor3 = Theme.Background,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ElasticBehavior = Enum.ElasticBehavior.Never,
                CanvasPosition = Vector2.new(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ZIndex = 202
            })
            Popup:SetAttribute("ThemeRole", "Background")
            corner(Popup, 6)
            stroke(Popup, Theme.Stroke, 1.5, 0)
            mk("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, Popup)
            mk("UIPadding", {
                PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)
            }, Popup)

            closePopup = function()
                isOpen = false
                Chevron.Text = "v"
                backdrop:Destroy()
                Popup:Destroy()
                currentDropdownClose = nil
            end
            currentDropdownClose = closePopup
            backdrop.MouseButton1Click:Connect(function() closePopup() end)

            buildPopupContents(Popup, closePopup)
        end

        Click.MouseButton1Click:Connect(function()
            if isOpen then
                if closePopup then closePopup() end
            else
                open()
            end
        end)
    end

    local Window = setmetatable({}, ZeroUI)
    Window.Tabs = {}
    Window.Assets = Assets
    Window.CurrentTheme = startTheme
    Window.AllThemes = ThemePalettes
    Window.FloatingToggles = {}
    Window.ScreenGui = ScreenGui
    Window.BackgroundArt = BackgroundArt

    --// TAMAÑO DE LA VENTANA: solo dos versiones fijas (sin sliders intermedios)
    local LibrarySizePresets = {
        Small = { Width = 420, Height = 340 },
        Large = { Width = 560, Height = 680 },
    }

    local LibrarySizeMode = ((SavedConfig.LibrarySizeMode or "Small") == "Large") and "Large" or "Small"

    local function getCurrentLibraryPreset()
        return LibrarySizePresets[LibrarySizeMode] or LibrarySizePresets.Small
    end

    local function updateWindowSize()
        local preset = getCurrentLibraryPreset()
        local screen = ScreenGui.AbsoluteSize
        local width = preset.Width
        local height = preset.Height

        if screen.X > 0 and screen.Y > 0 then
            width = math.min(width, math.floor(screen.X * 0.92))
            height = math.min(height, math.floor(screen.Y * 0.92))
        end

        shownSize = UDim2.new(0, width, 0, height)
        if Main then
            Main.Size = shownSize
        end
    end

    updateWindowSize()
    ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateWindowSize)

    function Window:SetLibraryVersion(isLarge)
        LibrarySizeMode = isLarge and "Large" or "Small"
        self.LibrarySizeMode = LibrarySizeMode
        self.LibraryHeight = getCurrentLibraryPreset().Height
        SavedConfig.LibrarySizeMode = LibrarySizeMode
        SavedConfig.LibraryHeight = self.LibraryHeight
        SaveConfig()
        updateWindowSize()
    end

    Window.LibrarySizeMode = LibrarySizeMode
    Window.LibraryHeight = getCurrentLibraryPreset().Height

    function Window:CreateTab(nameSpanish, nameEnglishOrIcon, iconAsset)
        --// COMPATIBILIDAD: Si nameEnglishOrIcon es un icon (rbxassetid), tratarlo como antes
        local nameEnglish = nameSpanish
        if nameEnglishOrIcon and string.find(nameEnglishOrIcon, "rbxassetid") then
            --// Código antiguo: CreateTab(name, iconAsset)
            iconAsset = nameEnglishOrIcon
            nameEnglish = nameSpanish
        elseif nameEnglishOrIcon then
            --// Código nuevo: CreateTab(nameSpanish, nameEnglish, iconAsset)
            nameEnglish = nameEnglishOrIcon
        end
        
        local displayName = GetText(nameSpanish, nameEnglish)
        
        local TabButton = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Theme.AccentOff,
            Text = "",
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.None,
            ClipsDescendants = false,
            ZIndex = 8
        }, TabList)
        TabButton:SetAttribute("ThemeRole", "AccentOff")
        TabButton:SetAttribute("TextSpanish", nameSpanish)
        TabButton:SetAttribute("TextEnglish", nameEnglish)
        corner(TabButton, 6)

        local textStart = 38
        if iconAsset then
            local iconSize = 24
            local iconPos = 7
            mk("ImageLabel", {
                Parent = TabButton,
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Position = UDim2.new(0, iconPos, 0.5, -(iconSize / 2)),
                BackgroundTransparency = 1,
                Image = iconAsset,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 9
            })
        end

        local TabNameLabel = mk("TextLabel", {
            Parent = TabButton,
            Size = UDim2.new(1, -(textStart + 10), 1, 0),
            Position = UDim2.new(0, textStart, 0, 0),
            BackgroundTransparency = 1,
            Text = displayName,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextTruncate = Enum.TextTruncate.None,
            ClipsDescendants = false,
            ZIndex = 9
        })
        TabNameLabel:SetAttribute("TextSpanish", nameSpanish)
        TabNameLabel:SetAttribute("TextEnglish", nameEnglish)

        resetScrollTop(TabList)

        local TabPage = mk("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            CanvasPosition = Vector2.new(0, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            ZIndex = 8,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, ContentArea)
        mk("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }, TabPage)

        local Tab = {Button = TabButton, Page = TabPage}

        local function Select()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                t.Button.TextColor3 = Theme.Text
                t.Button.BackgroundColor3 = Theme.AccentOff
            end
            TabPage.Visible = true
            TabPage.CanvasPosition = Vector2.new(0, 0)
            task.defer(function()
                if TabPage and TabPage.Parent then
                    TabPage.CanvasPosition = Vector2.new(0, 0)
                end
            end)
            TabButton.TextColor3 = Theme.AccentText
            TabButton.BackgroundColor3 = Theme.Accent
        end

        TabButton.MouseButton1Click:Connect(Select)
        if #Window.Tabs == 0 then Select() end
        table.insert(Window.Tabs, Tab)

        --// NUEVO: TOGGLE FLOTANTE

        --//  FLOATING TOGGLE v2.0 - COMPLETAMENTE RECONSTRUIDO
        function Tab:CreateFloatingToggle(textSpanish, textEnglishOrDefault, defaultOrCallback, callback)
            --// COMPATIBILIDAD: si el 2do argumento es string, es modo bilingüe.
            --// Si es boolean/nil, es la firma antigua: (text, default, callback)
            local textEnglish = textSpanish
            local default, cb

            if type(textEnglishOrDefault) == "string" then
                textEnglish = textEnglishOrDefault
                default = defaultOrCallback
                cb = callback
            else
                default = textEnglishOrDefault
                cb = defaultOrCallback
            end

            local displayText = GetText(textSpanish, textEnglish)
            local state = default or false
            local isFloating = false
            local isLocked = false
            
            --// ═════════════════════════════════════════════════════════════════════════
            --// PARTE 1: ELEMENTO EN LA PESTAÑA (PEQUEÑO)
            --// ═════════════════════════════════════════════════════════════════════════
            
            local Holder = mk("Frame", {
                Parent = TabPage,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Secondary,
                ZIndex = 9
            })
            Holder:SetAttribute("ThemeRole", "Secondary")
            corner(Holder, 6)
            stroke(Holder, Theme.Stroke, 1, 0.6)
            
            --// Texto
            local HolderLabel = mk("TextLabel", {
                Parent = Holder,
                Size = UDim2.new(1, -100, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = displayText,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 10
            })
            HolderLabel:SetAttribute("ThemeTextRole", "Text")
            HolderLabel:SetAttribute("TextSpanish", textSpanish)
            HolderLabel:SetAttribute("TextEnglish", textEnglish)
            
            --// Botón Desprender
            local DetachBtn = mk("TextButton", {
                Parent = Holder,
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(1, -70, 0.5, -12),
                BackgroundColor3 = Theme.Accent,
                Text = "↗",
                TextColor3 = Color3.fromRGB(0, 0, 0),
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                ZIndex = 13
            })
            corner(DetachBtn, 4)
            
            --// Switch Compacto (16x16 knob, 40x20 track)
            local HolderSwitch = mk("Frame", {
                Parent = Holder,
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -40, 0.5, -10),
                BackgroundColor3 = state and Theme.ToggleOn or Theme.AccentOff,
                ZIndex = 10
            })
            HolderSwitch:SetAttribute("ThemeRole", state and "ToggleOn" or "AccentOff")
            corner(HolderSwitch, 999)
            
            local HolderKnob = mk("Frame", {
                Parent = HolderSwitch,
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = 11
            })
            corner(HolderKnob, 999)
            
            --// Área clickeable en la pestaña
            local HolderClick = mk("TextButton", {
                Parent = Holder,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 12
            })
            
            --// ═════════════════════════════════════════════════════════════════════════
            --// PARTE 2: VENTANA FLOTANTE (RECONSTRUIDA)
            --// ═════════════════════════════════════════════════════════════════════════
            
            local FloatingWindow = nil
            local FloatingGlow = nil
            local animationConnection = nil
            
            local function createFloatingWindow()
                
                --// GLOW EXTERIOR - INVISIBLE
                FloatingGlow = mk("Frame", {
                    Parent = Window.ScreenGui,
                    Size = UDim2.fromOffset(200, 40),
                    Position = UDim2.new(0.5, -100, 0.5, -20),
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 1,  -- INVISIBLE
                    BorderSizePixel = 0,
                    ZIndex = 149
                })
                corner(FloatingGlow, 20)
                
                --// VENTANA PRINCIPAL (Más pequeña)
                FloatingWindow = mk("Frame", {
                    Parent = Window.ScreenGui,
                    Size = UDim2.fromOffset(200, 40),  -- TAMAÑO REDUCIDO
                    Position = UDim2.new(0.5, -100, 0.5, -20),
                    BackgroundColor3 = Theme.Secondary,
                    BackgroundTransparency = 0.35,  -- MÁS TRANSPARENTE
                    BorderSizePixel = 0,
                    ZIndex = 150
                })
                corner(FloatingWindow, 999)
                
                --// Borde del tema con efecto de brillo animado (solo stroke, es pequeño)
                stroke(FloatingWindow, Theme.Accent, 2, 0.5)
                buildAnimatedBorder(FloatingWindow, Theme.Accent, UDim.new(1, 0), true)
                
                --// LAYOUT HORIZONTAL
                local UILayout = mk("UIListLayout", {
                    Parent = FloatingWindow,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                --// TEXTO (Visible y pequeño)
                local FloatLabel = mk("TextLabel", {
                    Parent = FloatingWindow,
                    Size = UDim2.new(0, 60, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text = displayText,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 151,
                    LayoutOrder = 1
                })
                FloatLabel:SetAttribute("ThemeTextRole", "Text")
                FloatLabel:SetAttribute("TextSpanish", textSpanish)
                FloatLabel:SetAttribute("TextEnglish", textEnglish)
                
                --// BOTÓN + (Pequeño)
                local PlusBtn = mk("TextButton", {
                    Parent = FloatingWindow,
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundColor3 = Theme.Accent,
                    Text = "+",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    ZIndex = 151,
                    LayoutOrder = 2
                })
                corner(PlusBtn, 3)
                
                --// BOTÓN - (Pequeño)
                local MinusBtn = mk("TextButton", {
                    Parent = FloatingWindow,
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundColor3 = Theme.Accent,
                    Text = "-",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    ZIndex = 151,
                    LayoutOrder = 3
                })
                corner(MinusBtn, 3)
                
                --// SWITCH (Pequeño)
                local FloatSwitch = mk("Frame", {
                    Parent = FloatingWindow,
                    Size = UDim2.fromOffset(40, 20),
                    BackgroundColor3 = state and Theme.ToggleOn or Theme.AccentOff,
                    ZIndex = 151,
                    LayoutOrder = 4
                })
                FloatSwitch:SetAttribute("ThemeRole", state and "ToggleOn" or "AccentOff")
                corner(FloatSwitch, 999)
                
                local FloatKnob = mk("Frame", {
                    Parent = FloatSwitch,
                    Size = UDim2.fromOffset(16, 16),
                    Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = 152
                })
                corner(FloatKnob, 999)
                
                --// SINCRONIZAR GLOW CON VENTANA
                local function syncGlow()
                    if FloatingGlow and FloatingGlow.Parent then
                        FloatingGlow.Size = UDim2.fromOffset(FloatingWindow.Size.X.Offset + 16, FloatingWindow.Size.Y.Offset + 16)
                        FloatingGlow.Position = UDim2.new(FloatingWindow.Position.X.Scale, FloatingWindow.Position.X.Offset - 8, FloatingWindow.Position.Y.Scale, FloatingWindow.Position.Y.Offset - 8)
                    end
                end
                syncGlow()
                track(FloatingWindow:GetPropertyChangedSignal("Position"):Connect(syncGlow))
                
                --// ═════════════════════════════════════════════════════════════════════
                --// INTERACTIVIDAD
                --// ═════════════════════════════════════════════════════════════════════
                
                --// Click en Switch Flotante
                local FloatClick = mk("TextButton", {
                    Parent = FloatSwitch,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 152
                })
                
                FloatClick.MouseButton1Click:Connect(function()
                    state = not state
                    playSound(Sounds.Click, 0.5)
                    
                    --// Tween 1: Color del track
                    TweenService:Create(FloatSwitch, TweenInfo.new(0.15), 
                        {BackgroundColor3 = state and Theme.ToggleOn or Theme.AccentOff}):Play()
                    
                    --// Tween 2: Movimiento del knob
                    TweenService:Create(FloatKnob, TweenInfo.new(0.15), 
                        {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                    
                    --// NO ANIMAR GLOW - MANTENERLO INVISIBLE
                    FloatingGlow.BackgroundTransparency = 1.0
                    
                    --// Sincronizar con pestaña
                    TweenService:Create(HolderSwitch, TweenInfo.new(0.15), 
                        {BackgroundColor3 = state and Theme.ToggleOn or Theme.AccentOff}):Play()
                    TweenService:Create(HolderKnob, TweenInfo.new(0.15), 
                        {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                    
                    pcall(cb, state)
                end)
                
                --// Fijar con +
                PlusBtn.MouseButton1Click:Connect(function()
                    isLocked = true
                    playSound(Sounds.Click, 0.5)
                    TweenService:Create(PlusBtn, TweenInfo.new(0.3), 
                        {BackgroundColor3 = Color3.fromRGB(100, 200, 100)}):Play()
                    task.wait(0.3)
                    TweenService:Create(PlusBtn, TweenInfo.new(0.3), 
                        {BackgroundColor3 = Theme.Accent}):Play()
                end)
                
                --// Soltar con -
                MinusBtn.MouseButton1Click:Connect(function()
                    isLocked = false
                    playSound(Sounds.Click, 0.5)
                end)
                
                --// ═════════════════════════════════════════════════════════════════════
                --// DRAG (Solo si no está locked)
                --// ═════════════════════════════════════════════════════════════════════
                
                local dragging = false
                local dragStart, startPos
                
                FloatingWindow.InputBegan:Connect(function(input)
                    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not isLocked then
                        dragging = true
                        dragStart = input.Position
                        startPos = FloatingWindow.Position
                    end
                end)
                
                track(UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local delta = input.Position - dragStart
                        FloatingWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    end
                end))
                
                track(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end))
                
                table.insert(Window.FloatingToggles, {Window = FloatingWindow, Name = displayText})
            end
            
            --// ═════════════════════════════════════════════════════════════════════════
            --// BOTÓN DESPRENDER EN PESTAÑA
            --// ═════════════════════════════════════════════════════════════════════════
            
            DetachBtn.MouseButton1Click:Connect(function()
                playSound(Sounds.Click, 0.6)
                if not isFloating then
                    isFloating = true
                    createFloatingWindow()
                    DetachBtn.Text = "←"
                else
                    isFloating = false
                    if animationConnection then
                        animationConnection:Disconnect()
                        animationConnection = nil
                    end
                    if FloatingWindow then
                        FloatingWindow:Destroy()
                        FloatingWindow = nil
                    end
                    if FloatingGlow then
                        FloatingGlow:Destroy()
                        FloatingGlow = nil
                    end
                    DetachBtn.Text = "↗"
                end
            end)
            
            --// ═════════════════════════════════════════════════════════════════════════
            --// CLICK EN SWITCH DE PESTAÑA
            --// ═════════════════════════════════════════════════════════════════════════
            
            HolderClick.MouseButton1Click:Connect(function()
                state = not state
                playSound(Sounds.Click, 0.5)
                
                --// Tween 1: Color
                TweenService:Create(HolderSwitch, TweenInfo.new(0.15), 
                    {BackgroundColor3 = state and Theme.ToggleOn or Theme.AccentOff}):Play()
                
                --// Tween 2: Knob
                TweenService:Create(HolderKnob, TweenInfo.new(0.15), 
                    {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                
                --// Sincronizar con flotante si existe
                if isFloating and FloatingWindow and FloatingWindow.Parent then
                    for _, child in ipairs(FloatingWindow:GetDescendants()) do
                        if child:IsA("Frame") and child.Size.X.Offset == 55 and child.Size.Y.Offset == 28 then
                            TweenService:Create(child, TweenInfo.new(0.15), 
                                {BackgroundColor3 = state and Theme.ToggleOn or Theme.AccentOff}):Play()
                            
                            local knob = child:FindFirstChildWhichIsA("Frame")
                            if knob then
                                TweenService:Create(knob, TweenInfo.new(0.15), 
                                    {Position = state and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)}):Play()
                            end
                            break
                        end
                    end
                end
                
                pcall(cb, state)
            end)
            
            resetScrollTop(TabPage)
        end


        --// TOGGLE ESTÁNDAR
        function Tab:CreateToggle(textSpanish, textEnglishOrDefault, defaultOrCallback, callback)
            --// COMPATIBILIDAD: si el 2do argumento es string, es modo bilingüe.
            --// Si es boolean/nil, es la firma antigua: (text, default, callback)
            local textEnglish = textSpanish
            local default, cb

            if type(textEnglishOrDefault) == "string" then
                textEnglish = textEnglishOrDefault
                default = defaultOrCallback
                cb = callback
            else
                default = textEnglishOrDefault
                cb = defaultOrCallback
            end

            local displayText = GetText(textSpanish, textEnglish)
            local state = default or false
            local Holder = mk("Frame", {
                Parent = TabPage,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Secondary,
                BackgroundTransparency = 0.5,
                ZIndex = 9
            })
            Holder:SetAttribute("ThemeRole", "Secondary")
            corner(Holder, 6)
            stroke(Holder, Theme.Stroke, 1, 0.6)

            local LabelTxt = mk("TextLabel", {
                Parent = Holder,
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = displayText,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 10
            })
            LabelTxt:SetAttribute("ThemeTextRole", "Text")
            LabelTxt:SetAttribute("TextSpanish", textSpanish)
            LabelTxt:SetAttribute("TextEnglish", textEnglish)

            local Switch = mk("Frame", {
                Parent = Holder,
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10),
                BackgroundColor3 = state and Theme.ToggleOn or Theme.AccentOff,
                ZIndex = 10
            })
            Switch:SetAttribute("ThemeRole", state and "ToggleOn" or "AccentOff")
            corner(Switch, 999)

            local Knob = mk("Frame", {
                Parent = Switch,
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = Color3.new(1, 1, 1),
                ZIndex = 11
            })
            corner(Knob, 999)

            local Click = mk("TextButton", {
                Parent = Holder,
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 12
            })
            Click.MouseButton1Click:Connect(function()
                state = not state
                playSound(Sounds.Click, 0.5)
                TweenService:Create(Switch, TweenInfo.new(0.15), {BackgroundColor3 = state and Theme.ToggleOn or Theme.AccentOff}):Play()
                TweenService:Create(Knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                pcall(cb, state)
            end)
            resetScrollTop(TabPage)
            
            --// ✨ RETORNAR CONTROLADOR DEL TOGGLE (ChatGPT v1)
            return {
                SetValue = function(value)
                    state = value
                    playSound(Sounds.Click, 0.3)
                    TweenService:Create(Switch, TweenInfo.new(0.15), {BackgroundColor3 = state and Theme.ToggleOn or Theme.AccentOff}):Play()
                    TweenService:Create(Knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                    --// NO dispara el callback, solo cambia visualmente
                end,

                GetValue = function()
                    return state
                end
            }
        end

        --//  FLOATING TOGGLE SIMPLE (CÁPSULA ELEGANTE)
        function Tab:CreateFloatingToggleSimple(text, default, callback)
            local state = default or false
            local TweenService = game:GetService("TweenService")
            
            --// CREAR FRAME PRINCIPAL (Cápsula)
            local FloatingWindow = mk("Frame", {
                Name = "FloatingToggleSimple_" .. text,
                Size = UDim2.new(0, 220, 0, 50),
                Position = UDim2.new(0.5, -110, 0.1, 0),
                BackgroundColor3 = Theme.Secondary,
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                ZIndex = 150,
                CanQuery = true
            }, Window.ScreenGui)
            
            --// ESQUINAS REDONDEADAS
            corner(FloatingWindow, 999)
            
            --// BORDE
            stroke(FloatingWindow, Theme.Accent, 2, 0.5)
            
            --// FRAME CONTENEDOR PARA TEXTOS
            local TextContainer = mk("Frame", {
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.new(0, 5, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 151
            }, FloatingWindow)
            
            --// TEXTO DEL NOMBRE (Izquierda)
            local NameLabel = mk("TextLabel", {
                Size = UDim2.new(0.6, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 151
            }, TextContainer)
            NameLabel:SetAttribute("ThemeTextRole", "Text")
            
            --// TEXTO DEL ESTADO (Derecha)
            local StateLabel = mk("TextLabel", {
                Size = UDim2.new(0.35, 0, 1, 0),
                Position = UDim2.new(0.65, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = state and "ON" or "OFF",
                TextColor3 = state and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(155, 155, 155),
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 151
            }, TextContainer)
            
            --// EFECTO SHIMMER (UIGradient)
            local shimmerGradient = Instance.new("UIGradient")
            shimmerGradient.Rotation = 90
            shimmerGradient.ColorSequence = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255), 0.9),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255), 0),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255), 0.9)
            })
            shimmerGradient.Parent = FloatingWindow
            
            --// ANIMAR SHIMMER
            local shimmerTween = TweenService:Create(
                shimmerGradient,
                TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0),
                {Offset = Vector2.new(1, 0)}
            )
            shimmerTween:Play()
            track(shimmerTween)
            
            --// EFECTO BREATHING (Pulsación)
            local originalSize = FloatingWindow.Size
            local pulseSize = UDim2.new(0, 230, 0, 55)
            
            local pulseTween = TweenService:Create(
                FloatingWindow,
                TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0),
                {Size = pulseSize}
            )
            pulseTween:Play()
            track(pulseTween)
            
            --// DETECTOR DE CLICKS
            local ClickDetector = mk("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 152
            }, FloatingWindow)
            
            --// VARIABLES DE INTERACCIÓN
            local isDragging = false
            local dragStart = nil
            local dragStartPos = nil
            local isHovering = false
            
            --// FUNCIÓN PARA ACTUALIZAR ESTADO
            local function updateState()
                if state then
                    StateLabel.Text = "ON"
                    StateLabel.TextColor3 = Color3.fromRGB(76, 175, 80)
                else
                    StateLabel.Text = "OFF"
                    StateLabel.TextColor3 = Color3.fromRGB(155, 155, 155)
                end
            end
            
            --// HOVER EFFECT
            track(FloatingWindow.MouseEnter:Connect(function()
                isHovering = true
                TweenService:Create(
                    FloatingWindow,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundTransparency = 0.15}
                ):Play()
            end))
            
            track(FloatingWindow.MouseLeave:Connect(function()
                isHovering = false
                TweenService:Create(
                    FloatingWindow,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundTransparency = 0.3}
                ):Play()
            end))
            
            --// CLICK EFFECT Y TOGGLE
            track(ClickDetector.MouseButton1Click:Connect(function()
                state = not state
                updateState()
                
                --// SONIDO
                pcall(function() playSound(Sounds.Click, 0.6) end)
                
                --// EFECTO VISUAL DE PRESIÓN
                local pressSize = UDim2.new(0, 210, 0, 45)
                TweenService:Create(
                    FloatingWindow,
                    TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {Size = pressSize, BackgroundTransparency = 0.5}
                ):Play()
                
                task.wait(0.08)
                
                --// VOLVER AL TAMAÑO NORMAL
                TweenService:Create(
                    FloatingWindow,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = originalSize, BackgroundTransparency = isHovering and 0.15 or 0.3}
                ):Play()
                
                --// EJECUTAR CALLBACK
                if callback then
                    pcall(function() callback(state) end)
                end
                
                print("[" .. text .. "] " .. (state and " ACTIVADO" or " DESACTIVADO"))
            end))
            
            --// DRAG AND DROP
            track(FloatingWindow.InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and isHovering then
                    isDragging = true
                    dragStart = input.Position
                    dragStartPos = FloatingWindow.Position
                end
            end))
            
            track(UserInputService.InputChanged:Connect(function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local delta = input.Position - dragStart
                    FloatingWindow.Position = UDim2.new(
                        dragStartPos.X.Scale,
                        dragStartPos.X.Offset + delta.X,
                        dragStartPos.Y.Scale,
                        dragStartPos.Y.Offset + delta.Y
                    )
                end
            end))
            
            track(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end))
            
            return FloatingWindow
        end

        --// 🎚️ SLIDER PREMIUM v2.0 (OTRO NIVEL - Zero Lag + GV2 Glow + Rango Visible)
        function Tab:CreateSlider(text, min, max, default, callback)
            local value = default or min
            local isDragging = false
            local lastUpdateTime = 0
            local UPDATE_THROTTLE = 0.008  -- 120fps smoothness
            
            --// CONTAINER PRINCIPAL
            local Holder = mk("Frame", {
                Parent = TabPage,
                Size = UDim2.new(1, 0, 0, 72),
                BackgroundColor3 = Theme.Secondary,
                BackgroundTransparency = 0.5,
                ZIndex = 9
            })
            Holder:SetAttribute("ThemeRole", "Secondary")
            Holder:SetAttribute("IsSliderHolder", true)
            corner(Holder, 12)
            stroke(Holder, Theme.Stroke, 1.5, 0.6)
            buildAnimatedBorder(Holder, Theme.Accent, UDim.new(0, 12), true)

            --// LABEL PRINCIPAL
            local LabelTxt = mk("TextLabel", {
                Parent = Holder,
                Size = UDim2.new(0, 200, 0, 22),
                Position = UDim2.new(0, 16, 0, 10),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10
            })
            LabelTxt:SetAttribute("ThemeRole", "Text")

            --// VALUE LABEL (Dinámico a la derecha)
            local ValueLabel = mk("TextLabel", {
                Parent = Holder,
                Size = UDim2.new(0, 70, 0, 22),
                Position = UDim2.new(1, -86, 0, 10),
                BackgroundTransparency = 1,
                Text = tostring(math.floor(value * 100) / 100),
                TextColor3 = Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 11
            })
            ValueLabel:SetAttribute("ThemeRole", "Accent")

            --// RANGO MÍNIMO (Abajo a la izquierda)
            local MinLabel = mk("TextLabel", {
                Parent = Holder,
                Size = UDim2.new(0, 50, 0, 16),
                Position = UDim2.new(0, 16, 0, 52),
                BackgroundTransparency = 1,
                Text = tostring(min),
                TextColor3 = Theme.AccentOff,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10
            })
            MinLabel:SetAttribute("ThemeRole", "AccentOff")

            --// RANGO MÁXIMO (Abajo a la derecha)
            local MaxLabel = mk("TextLabel", {
                Parent = Holder,
                Size = UDim2.new(0, 50, 0, 16),
                Position = UDim2.new(1, -66, 0, 52),
                BackgroundTransparency = 1,
                Text = tostring(max),
                TextColor3 = Theme.AccentOff,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 10
            })
            MaxLabel:SetAttribute("ThemeRole", "AccentOff")

            --// SLIDER BACKGROUND (Barra de fondo)
            local SliderBackground = mk("Frame", {
                Parent = Holder,
                Size = UDim2.new(1, -32, 0, 5),
                Position = UDim2.new(0, 16, 0, 44),
                BackgroundColor3 = Theme.AccentOff,
                BorderSizePixel = 0,
                ZIndex = 10
            })
            SliderBackground:SetAttribute("ThemeRole", "AccentOff")
            corner(SliderBackground, 2)

            --// SLIDER FILL (La barra que se llena)
            local SliderFill = mk("Frame", {
                Parent = SliderBackground,
                Size = UDim2.new(0, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 11
            })
            SliderFill:SetAttribute("ThemeRole", "Accent")
            corner(SliderFill, 2)

            --// SLIDER THUMB PRINCIPAL (El círculo/rectángulo que arrastramos)
            local SliderThumb = mk("Frame", {
                Parent = Holder,
                Size = UDim2.new(0, 14, 0, 22),
                Position = UDim2.new(0, 16, 0, 37),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 13
            })
            SliderThumb:SetAttribute("ThemeRole", "Accent")
            corner(SliderThumb, 8)

            --// GLOW EFFECT (sin asset externo)
            local ThumbGlow = mk("Frame", {
                Parent = SliderThumb,
                Size = UDim2.new(1, 6, 1, 6),
                Position = UDim2.new(0, -3, 0, -3),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.7,
                BorderSizePixel = 0,
                ZIndex = 12
            })
            ThumbGlow:SetAttribute("ThemeRole", "Accent")
            corner(ThumbGlow, 10)

            --// BORDE ELEGANTE DEL THUMB
            stroke(SliderThumb, Theme.Stroke, 1, 0.7)

            --// FUNCIÓN: Actualizar slider (OPTIMIZADA)
            local function UpdateSlider(percentage)
                percentage = math.clamp(percentage, 0, 1)
                value = min + (max - min) * percentage
                
                --// Animar el fill suavemente
                local barWidth = SliderBackground.AbsoluteSize.X
                local targetSize = UDim2.new(percentage, 0, 1, 0)
                TweenService:Create(SliderFill, TweenInfo.new(0.05), {Size = targetSize}):Play()
                
                --// Posición del thumb (SUAVE con Tween)
                local thumbTargetX = 16 + (barWidth) * percentage - 7
                local tweenThumb = TweenService:Create(
                    SliderThumb, 
                    TweenInfo.new(0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Position = UDim2.new(0, thumbTargetX, 0, 37)}
                )
                tweenThumb:Play()

                --// GLOW PULSE cuando se mueve
                local tweenGlow = TweenService:Create(
                    ThumbGlow,
                    TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {BackgroundTransparency = 0.4}
                )
                tweenGlow:Play()
                
                --// Actualizar valor en label (sin delays)
                ValueLabel.Text = tostring(math.floor(value * 100) / 100)
                
                --// Callback sin lag
                task.spawn(function()
                    pcall(callback, value)
                end)
            end

            --// FUNCIÓN: Manejar clicks del slider
            local function OnSliderClick(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    
                    --// EFECTO: El thumb se agranda ligeramente cuando lo agarras
                    TweenService:Create(
                        SliderThumb,
                        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Size = UDim2.new(0, 16, 0, 26)}
                    ):Play()
                end
            end

            --// FUNCIÓN: Manejar soltar el slider
            local function OnSliderRelease(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    isDragging = false
                    
                    --// EFECTO: El thumb vuelve a su tamaño normal
                    TweenService:Create(
                        SliderThumb,
                        TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Size = UDim2.new(0, 14, 0, 22)}
                    ):Play()
                    
                    --// SONIDO al soltar
                    playSound(Sounds.Click, 0.5)
                    
                    --// GLOW vuelve a transparency normal
                    TweenService:Create(
                        ThumbGlow,
                        TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {BackgroundTransparency = 0.7}
                    ):Play()
                end
            end

            --// CONECTAR EVENTOS DE CLICK
            SliderBackground.InputBegan:Connect(OnSliderClick)
            SliderThumb.InputBegan:Connect(OnSliderClick)

            --// INPUT MOVEMENT (OPTIMIZADO - Sin tartamudeos) 🚀
            track(UserInputService.InputChanged:Connect(function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local currentTime = tick()
                    
                    --// THROTTLE: Solo actualizar cada 8ms (120fps max)
                    if currentTime - lastUpdateTime >= UPDATE_THROTTLE then
                        lastUpdateTime = currentTime
                        
                        local relativeX = input.Position.X - SliderBackground.AbsolutePosition.X
                        local barWidth = SliderBackground.AbsoluteSize.X
                        local percentage = math.clamp(relativeX / barWidth, 0, 1)
                        
                        UpdateSlider(percentage)
                    end
                end
            end))

            --// SOLTAR SLIDER - GLOBAL para celular (evita que se quede pegado)
            track(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    OnSliderRelease(input)
                end
            end))

            --// ACTUALIZAR INICIAL
            UpdateSlider((value - min) / (max - min))
            resetScrollTop(TabPage)
            
            --// RETORNAR TABLA CON MÉTODOS
            return {
                Set = function(newValue)
                    value = math.clamp(newValue, min, max)
                    UpdateSlider((value - min) / (max - min))
                end,
                Get = function()
                    return value
                end,
                SetMin = function(newMin)
                    min = newMin
                    MinLabel.Text = tostring(min)
                end,
                SetMax = function(newMax)
                    max = newMax
                    MaxLabel.Text = tostring(max)
                end
            }
        end

        --// BOTÓN ESTÁNDAR
        function Tab:CreateButton(textSpanish, textEnglishOrCallback, callbackOrIcon, iconAsset)
            --// COMPATIBILIDAD: si el 2do argumento es string, es modo bilingüe.
            --// Si es function (o nil), es la firma antigua: (text, callback, iconAsset)
            local textEnglish = textSpanish
            local callback, icon

            if type(textEnglishOrCallback) == "string" then
                textEnglish = textEnglishOrCallback
                callback = callbackOrIcon
                icon = iconAsset
            else
                callback = textEnglishOrCallback
                icon = callbackOrIcon
            end

            local displayText = GetText(textSpanish, textEnglish)
            local iconAsset = icon

            local Btn = mk("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Secondary,
                Text = iconAsset and "" or displayText,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 9
            }, TabPage)
            Btn:SetAttribute("ThemeRole", "Secondary")
            corner(Btn, 6)
            stroke(Btn, Theme.Stroke, 1, 0.6)
            resetScrollTop(TabPage)

            if iconAsset then
                mk("ImageLabel", {
                    Parent = Btn,
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(0, 8, 0.5, -10),
                    BackgroundTransparency = 1,
                    Image = iconAsset,
                    ZIndex = 10
                })
                local BtnLabel = mk("TextLabel", {
                    Parent = Btn,
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.new(0, 32, 0, 0),
                    BackgroundTransparency = 1,
                    Text = displayText,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 10
                })
                BtnLabel:SetAttribute("ThemeTextRole", "Text")
                BtnLabel:SetAttribute("TextSpanish", textSpanish)
                BtnLabel:SetAttribute("TextEnglish", textEnglish)
            else
                --// Sin icono: el texto vive directo en el TextButton
                Btn:SetAttribute("TextSpanish", textSpanish)
                Btn:SetAttribute("TextEnglish", textEnglish)
            end

            Btn.MouseButton1Click:Connect(function()
                playSound(Sounds.Click, 0.6)
                TweenService:Create(Btn, TweenInfo.new(0.08), {BackgroundColor3 = Theme.Accent}):Play()
                task.wait(0.08)
                TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Secondary}):Play()
                pcall(callback)
            end)
            return Btn
        end

        --// LABEL
        function Tab:CreateLabel(textSpanish, textEnglishOrSize, fontSize)
            --// COMPATIBILIDAD: Si textEnglishOrSize es un número, es fontSize (código antiguo)
            local textEnglish = textSpanish
            if type(textEnglishOrSize) == "number" then
                --// Código antiguo: CreateLabel(text, fontSize)
                fontSize = textEnglishOrSize
                textEnglish = textSpanish
            elseif type(textEnglishOrSize) == "string" then
                --// Código nuevo: CreateLabel(textSpanish, textEnglish, fontSize)
                textEnglish = textEnglishOrSize
            end
            
            fontSize = fontSize or 14
            local displayText = GetText(textSpanish, textEnglish)
            
            local Label = mk("TextLabel", {
                Parent = TabPage,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = displayText,
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = fontSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                ZIndex = 9
            })
            Label:SetAttribute("ThemeTextRole", "Text")
            Label:SetAttribute("TextSpanish", textSpanish)
            Label:SetAttribute("TextEnglish", textEnglish)
            resetScrollTop(TabPage)
            return Label
        end

        --// DIVISOR
        function Tab:CreateDivider()
            local Divider = mk("Frame", {
                Parent = TabPage,
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.Stroke,
                ZIndex = 9
            })
            Divider:SetAttribute("ThemeRole", "Stroke")
            return Divider
        end

        --// WELCOME CARD CON AVATAR DEL JUGADOR
        function Tab:CreateWelcomeCard()
            local Card = mk("Frame", {
                Parent = TabPage,
                Size = UDim2.new(1, 0, 0, 64),
                BackgroundColor3 = Theme.Secondary,
                ZIndex = 9
            })
            Card:SetAttribute("ThemeRole", "Secondary")
            corner(Card, 8)
            stroke(Card, Color3.fromRGB(0, 0, 0), 1, 0.6)

            local Avatar = mk("ImageLabel", {
                Parent = Card,
                Size = UDim2.new(0, 48, 0, 48),
                Position = UDim2.new(0, 8, 0.5, -24),
                BackgroundColor3 = Theme.AccentOff,
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 10
            })
            Avatar:SetAttribute("ThemeRole", "AccentOff")
            corner(Avatar, 999)

            local WelcomeLabel = mk("TextLabel", {
                Parent = Card,
                Size = UDim2.new(1, -68, 0, 20),
                Position = UDim2.new(0, 64, 0, 12),
                BackgroundTransparency = 1,
                Text = GetText("Bienvenido,", "Welcome,"),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10
            })
            WelcomeLabel:SetAttribute("ThemeRole", "TextDim")
            WelcomeLabel:SetAttribute("TextSpanish", "Bienvenido,")
            WelcomeLabel:SetAttribute("TextEnglish", "Welcome,")

            mk("TextLabel", {
                Parent = Card,
                Size = UDim2.new(1, -68, 0, 24),
                Position = UDim2.new(0, 64, 0, 30),
                BackgroundTransparency = 1,
                Text = LocalPlayer.Name,
                Font = Enum.Font.GothamBold,
                TextSize = 16,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 10
            }):SetAttribute("ThemeRole", "Text")

            task.spawn(function()
                local ok, content = pcall(function()
                    local thumb = Players:GetUserThumbnailAsync(
                        LocalPlayer.UserId,
                        Enum.ThumbnailType.HeadShot,
                        Enum.ThumbnailSize.Size100x100
                    )
                    return thumb
                end)
                if ok and content and Avatar.Parent then
                    Avatar.Image = content
                end
            end)

            resetScrollTop(TabPage)
            return Card
        end

        --// SERVER INFO CARD CON ESTADÍSTICAS DEL SERVIDOR
        function Tab:CreateServerInfoCard()
            local Card = mk("Frame", {
                Parent = TabPage,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ZIndex = 9
            })
            mk("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, Card)

            local ServerLabel = mk("TextLabel", {
                Parent = Card,
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = GetText("Servidor", "Server"),
                Font = Enum.Font.GothamBold,
                TextSize = 15,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 9
            })
            ServerLabel:SetAttribute("ThemeRole", "Text")
            ServerLabel:SetAttribute("TextSpanish", "Servidor")
            ServerLabel:SetAttribute("TextEnglish", "Server")

            local Grid = createStatGrid(Card)
            local _, playersVal = createStatTile(Grid, "Jugadores", "Players")
            local _, maxVal = createStatTile(Grid, "Máximo de jugadores", "Max players")
            local _, pingVal = createStatTile(Grid, "Latencia", "Latency")
            local _, idVal = createStatTile(Grid, "ID del servidor", "Server ID")
            local joinTile, joinVal = createStatTile(Grid, "Script de unión", "Join script")
            local _, timeVal = createStatTile(Grid, "Tiempo en el servidor", "Server time")

            idVal.Text = (game.JobId ~= "" and game.JobId) or "N/A (Studio)"
            joinVal.Text = GetText("Tocar para copiar", "Tap to copy")

            local JoinClick = mk("TextButton", {
                Parent = joinTile,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 11
            })
            JoinClick.MouseButton1Click:Connect(function()
                local snippet = string.format(
                    'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)',
                    game.PlaceId, game.JobId
                )
                local ok = pcall(function() setclipboard(snippet) end)
                joinVal.Text = ok and GetText("¡Copiado!", "Copied!") or GetText("No disponible", "Not available")
                task.delay(2, function()
                    if joinVal and joinVal.Parent then
                        joinVal.Text = GetText("Tocar para copiar", "Tap to copy")
                    end
                end)
            end)

            local startClock = os.clock()
            local StatsService = game:GetService("Stats")

            task.spawn(function()
                while Card.Parent do
                    playersVal.Text = tostring(#Players:GetPlayers())
                    maxVal.Text = tostring(Players.MaxPlayers)

                    local ok, ping = pcall(function()
                        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
                    end)
                    pingVal.Text = (ok and ping) and (math.floor(ping) .. " ms") or "N/A"

                    timeVal.Text = formatDuration(os.clock() - startClock)
                    task.wait(1)
                end
            end)

            resetScrollTop(TabPage)
            return Card
        end

        return Tab
    end

    --// ════════════════════════════════════════════════════════════════
    --// FUNCIONES DE EFECTOS DE TEXTO (ANTES DE SetTheme - IMPORTANTE)
    --// ════════════════════════════════════════════════════════════════
    local textEffectConnection = nil
    Window.CurrentTextEffect = "Off"

    local function getAllTextObjects()
        local list = {}
        for _, obj in ipairs(Main:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                table.insert(list, obj)
            end
        end
        return list
    end

    local function applyTextColorToAll(color)
        for _, obj in ipairs(getAllTextObjects()) do
            pcall(function()
                obj.TextColor3 = color
            end)
        end
    end

    local function stopTextEffect()
        if textEffectConnection then
            textEffectConnection:Disconnect()
            textEffectConnection = nil
        end
    end

    --// ════════════════════════════════════════════════════════════════
    --// CAMBIO DE TEMA (SetTheme) 
    --// ════════════════════════════════════════════════════════════════

    function Window:SetTheme(themeName)
        if not setActiveTheme(themeName) then
            warn("Tema no encontrado: " .. tostring(themeName))
            return
        end
        
        self.CurrentTheme = themeName
        CurrentTheme = themeName  --  v26: Actualizar variable global

        for _, obj in ipairs(Main:GetDescendants()) do
            swapThemeColor(obj, Theme)
        end

        -- 🔧 RESETEAR TODOS LOS COLORES DE TEXTO AL NUEVO TEMA
        applyTextColorToAll(Theme.Text)

        if BackgroundArt then
            pcall(function()
                BackgroundArt.Image = ThemeBackgroundImages[themeName] or ""
                print(" Imagen de fondo actualizada")
            end)
        end

        --// 💾 v26: GUARDAR CONFIGURACIÓN AUTOMÁTICAMENTE
        SavedConfig.CurrentTheme = themeName
        SaveConfig()

        --//  v26: SONIDO DE CLICK DINÁMICO POR TEMA
        if ThemeClickSounds[themeName] then
            CurrentClickSound = ThemeClickSounds[themeName]
            print(" Tema " .. themeName .. " - Sonido de click personalizado activado")
        else
            CurrentClickSound = Sounds.Click
        end

        --// SISTEMA DE EFECTO DINÁMICO POR TEMA (desde ThemeAutoEffects)
        local autoEffect = ThemeAutoEffects[themeName]
        if autoEffect and autoEffect ~= "Off" then
            self:SetTextEffect(autoEffect)
        else
            self:SetTextEffect("Off")
        end
        
        CurrentTheme = themeName

        -- Actualizar efecto de brillo animado con el nuevo color de acento
        buildAnimatedBorder(Main, Theme.Accent, UDim.new(0, 10))

        -- Actualizar efecto en floating toggles activos
        for _, floatData in ipairs(Window.FloatingToggles or {}) do
            if floatData.Window and floatData.Window.Parent then
                buildAnimatedBorder(floatData.Window, Theme.Accent, UDim.new(1, 0), true)
            end
        end

        -- Actualizar borde animado de todos los sliders
        for _, obj in ipairs(Main:GetDescendants()) do
            if obj:GetAttribute("IsSliderHolder") then
                buildAnimatedBorder(obj, Theme.Accent, UDim.new(0, 12), true)
            end
        end
    end

    -- mode: "Off" | "WhiteCyan" | "WhitePink" | "Rainbow"
    function Window:SetTextEffect(mode)
        stopTextEffect()
        Window.CurrentTextEffect = mode

        if mode == "Off" then
            -- Devuelve cada texto al color que le corresponde según su rol de tema actual
            for _, obj in ipairs(getAllTextObjects()) do
                local role = obj:GetAttribute("ThemeTextRole")
                if role and Theme[role] then
                    obj.TextColor3 = Theme[role]
                end
            end
            return
        end

        local elapsed = 0
        local RunService = game:GetService("RunService")

        if mode == "WhiteCyan" then
            -- Pulso suave entre blanco y celeste, "a ratos" (va y viene)
            local colorA = Color3.fromRGB(255, 255, 255)
            local colorB = Color3.fromRGB(120, 225, 255)
            textEffectConnection = track(RunService.Heartbeat:Connect(function(dt)
                elapsed = elapsed + dt
                local alpha = (math.sin(elapsed * 1.6) + 1) / 2
                applyTextColorToAll(colorA:Lerp(colorB, alpha))
            end))

        elseif mode == "WhitePink" then
            -- Igual que el anterior pero más lento y entre blanco y rosa
            local colorA = Color3.fromRGB(255, 255, 255)
            local colorB = Color3.fromRGB(255, 130, 205)
            textEffectConnection = track(RunService.Heartbeat:Connect(function(dt)
                elapsed = elapsed + dt
                local alpha = (math.sin(elapsed * 0.6) + 1) / 2
                applyTextColorToAll(colorA:Lerp(colorB, alpha))
            end))

        elseif mode == "Rainbow" then
            -- Recorre todo el espectro de color de forma continua y pareja
            textEffectConnection = track(RunService.Heartbeat:Connect(function(dt)
                elapsed = elapsed + dt
                local hue = (elapsed * 0.12) % 1
                applyTextColorToAll(Color3.fromHSV(hue, 0.85, 1))
            end))

        elseif mode == "CatRainbow" then
            --  EFECTO ESPECIAL PARA CAT V1: Oscilación rápida entre Rosa y Blanco
            -- 5x más rápido que Rainbow normal (0.2 seg por ciclo)
            textEffectConnection = track(RunService.Heartbeat:Connect(function(dt)
                elapsed = elapsed + dt
                local cycle = (elapsed * 5) % 1  -- 5 ciclos por segundo
                
                local color
                if cycle < 0.5 then
                    -- Primera mitad: Rosa (255, 100, 150) → Blanco (255, 255, 255)
                    local t = cycle * 2
                    color = Color3.fromRGB(
                        255,
                        math.floor(100 + (255 - 100) * t),
                        math.floor(150 + (255 - 150) * t)
                    )
                else
                    -- Segunda mitad: Blanco (255, 255, 255) → Rosa (255, 100, 150)
                    local t = (cycle - 0.5) * 2
                    color = Color3.fromRGB(
                        255,
                        math.floor(255 - (255 - 100) * t),
                        math.floor(255 - (255 - 150) * t)
                    )
                end
                
                applyTextColorToAll(color)
            end))

        elseif mode == "RainbowDarkWhite" then
            --  EFECTO RAINBOW DARK-WHITE: Transición lenta de Negro a Blanco
            -- Cambia muy lentamente (un ciclo cada 4 segundos)
            textEffectConnection = track(RunService.Heartbeat:Connect(function(dt)
                elapsed = elapsed + dt
                local cycle = (elapsed * 0.25) % 1  -- Un ciclo cada 4 segundos
                
                -- Interpola lentamente entre negro (0, 0, 0) y blanco (255, 255, 255)
                local color = Color3.fromRGB(
                    math.floor(255 * cycle),
                    math.floor(255 * cycle),
                    math.floor(255 * cycle)
                )
                
                applyTextColorToAll(color)
            end))

        elseif mode == "ErisRainbow" then
            -- 🔴 EFECTO ESPECIAL PARA ERIS V1: Transición lenta Rojo → Negro → Blanco
            -- 3 fases en un ciclo de 6 segundos: Rojo (2s) → Negro (2s) → Blanco (2s)
            textEffectConnection = track(RunService.Heartbeat:Connect(function(dt)
                elapsed = elapsed + dt
                local cycle = (elapsed * 0.167) % 1  -- Un ciclo cada 6 segundos (1/6 = 0.167)
                
                local color
                if cycle < 0.333 then
                    -- Primera fase (0-2s): Rojo (255, 0, 0) → Negro (0, 0, 0)
                    local t = cycle / 0.333
                    color = Color3.fromRGB(
                        math.floor(255 - 255 * t),  -- Rojo: 255 → 0
                        0,
                        0
                    )
                elseif cycle < 0.667 then
                    -- Segunda fase (2-4s): Negro (0, 0, 0) → Blanco (255, 255, 255)
                    local t = (cycle - 0.333) / 0.334
                    color = Color3.fromRGB(
                        math.floor(255 * t),
                        math.floor(255 * t),
                        math.floor(255 * t)
                    )
                else
                    -- Tercera fase (4-6s): Blanco (255, 255, 255) → Rojo (255, 0, 0)
                    local t = (cycle - 0.667) / 0.333
                    color = Color3.fromRGB(
                        255,
                        math.floor(255 - 255 * t),  -- Rojo: 255 → 0
                        math.floor(255 - 255 * t)   -- Azul: 255 → 0
                    )
                end
                
                applyTextColorToAll(color)
            end))

        elseif mode == "ShylfieRainbow" then
            --  EFECTO ESPECIAL PARA SHYLFIE V1: Oscilación entre Amarillo y Blanco
            textEffectConnection = track(RunService.Heartbeat:Connect(function(dt)
                elapsed = elapsed + dt
                local cycle = (elapsed * 0.4) % 1

                local color
                if cycle < 0.5 then
                    -- Amarillo (255, 215, 0) → Blanco (255, 255, 255)
                    local t = cycle * 2
                    color = Color3.fromRGB(
                        255,
                        math.floor(215 + (255 - 215) * t),
                        math.floor(0 + 255 * t)
                    )
                else
                    -- Blanco (255, 255, 255) → Amarillo (255, 215, 0)
                    local t = (cycle - 0.5) * 2
                    color = Color3.fromRGB(
                        255,
                        math.floor(255 - (255 - 215) * t),
                        math.floor(255 - 255 * t)
                    )
                end

                applyTextColorToAll(color)
            end))

        elseif mode == "SukunaRainbow" then
            --  EFECTO ESPECIAL PARA SUKUNA V1: Oscilación entre Negro y Rojo
            textEffectConnection = track(RunService.Heartbeat:Connect(function(dt)
                elapsed = elapsed + dt
                local cycle = (elapsed * 0.4) % 1

                local color
                if cycle < 0.5 then
                    -- Negro (0, 0, 0) → Rojo (200, 20, 25)
                    local t = cycle * 2
                    color = Color3.fromRGB(
                        math.floor(200 * t),
                        math.floor(20 * t),
                        math.floor(25 * t)
                    )
                else
                    -- Rojo (200, 20, 25) → Negro (0, 0, 0)
                    local t = (cycle - 0.5) * 2
                    color = Color3.fromRGB(
                        math.floor(200 - 200 * t),
                        math.floor(20 - 20 * t),
                        math.floor(25 - 25 * t)
                    )
                end

                applyTextColorToAll(color)
            end))

        else
            warn("Efecto de texto no reconocido: " .. tostring(mode))
        end
    end

    function Window:Destroy()
        for _, conn in ipairs(globalConnections) do
            pcall(function() conn:Disconnect() end)
        end
        dragonConnection:Disconnect()
        ScreenGui:Destroy()
    end

    --// ════════════════════════════════════════════════════════════════
    --// CREAR AUTOMÁTICAMENTE LAS 3 PESTAÑAS SAGRADAS (v26 MEJORADO)
    --// ════════════════════════════════════════════════════════════════
    
    -- TAB 1: INICIO (Automático)
    local AutoTabInicio = Window:CreateTab("Inicio", "Home", "rbxassetid://71085559019524")
    AutoTabInicio:CreateWelcomeCard()
    AutoTabInicio:CreateDivider()
    AutoTabInicio:CreateServerInfoCard()
    
    -- TAB 2: TEMAS (Automático)
    local AutoTabTemas = Window:CreateTab("Temas", "Themes", "rbxassetid://108938004711116")
    AutoTabTemas:CreateLabel("Temas Personalizados", 14)
    AutoTabTemas:CreateDivider()

    --// ════════════════════════════════════════════════════════════════
    --// BUSCADOR DE TEMAS
    --// ════════════════════════════════════════════════════════════════
    local ThemeSearchHolder = mk("Frame", {
        Parent = AutoTabTemas.Page,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        ZIndex = 9,
    })
    ThemeSearchHolder:SetAttribute("ThemeRole", "Secondary")
    corner(ThemeSearchHolder, 6)
    stroke(ThemeSearchHolder, Theme.Stroke, 1, 0.6)

    mk("ImageLabel", {
        Parent = ThemeSearchHolder,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 10, 0.5, -8),
        BackgroundTransparency = 1,
        Image = "rbxassetid://83456197177232",
        ImageColor3 = Theme.TextDim,
        ZIndex = 10,
    })

    local ThemeSearchBox = mk("TextBox", {
        Parent = ThemeSearchHolder,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        ClearTextOnFocus = false,
        PlaceholderText = "Buscar tema...",
        PlaceholderColor3 = Theme.TextDim,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
    })
    ThemeSearchBox:SetAttribute("ThemeTextRole", "Text")
    resetScrollTop(AutoTabTemas.Page)

    local temas = ThemeOrder or {
        "Dark", "DarkV2",
        "Red", "RedV2",
        "Pink", "PinkV2", "PinkV3",
        "Blue", "BlueV2",
        "White", "WhiteV2", "WhiteV3", "WhiteAndDark",
        "Green", "NaranjaV1", "VioletaV1",
        "CatV1",
        "LightV1",
        "ErisV1",
        "ShylfieV1",
        "SukunaV1", "SukunaV2",
        "V1", "V2", "V3", "V4", "V5", "V6", "V9", "V10", "V11", "V14",
        "PibbleV1",
    }

    --// Guardamos referencia {boton, nombreTema} para poder filtrarlos
    local ThemeButtons = {}

    for _, tema in ipairs(temas) do
        local btn = AutoTabTemas:CreateButton(tema, function()
            Window:SetTheme(tema)
        end)
        table.insert(ThemeButtons, {Button = btn, Name = tema})
    end

    --// Filtro dinámico: oculta los botones que no coincidan con la búsqueda
    ThemeSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = ThemeSearchBox.Text:lower()
        for _, entry in ipairs(ThemeButtons) do
            if query == "" or entry.Name:lower():find(query, 1, true) then
                entry.Button.Visible = true
            else
                entry.Button.Visible = false
            end
        end
        resetScrollTop(AutoTabTemas.Page)
    end)
    
    -- TAB 3: EFECTOS (Automático)
    local AutoTabEfectos = Window:CreateTab("Efectos", "Effects", "rbxassetid://132646825035547")
    AutoTabEfectos:CreateLabel("Efectos de Texto", "Text Effects", 14)
    AutoTabEfectos:CreateDivider()
    
    AutoTabEfectos:CreateButton("⚪ Normal (Blanco)", "⚪ Normal (White)", function()
        Window:SetTextEffect("Off")
    end)
    
    AutoTabEfectos:CreateButton("💫 Blanco-Celeste", "💫 White-Cyan", function()
        Window:SetTextEffect("WhiteCyan")
    end)
    
    AutoTabEfectos:CreateButton("💗 Blanco-Rosa", "💗 White-Pink", function()
        Window:SetTextEffect("WhitePink")
    end)
    
    AutoTabEfectos:CreateButton(" Arcoiris", " Rainbow", function()
        Window:SetTextEffect("Rainbow")
    end)
    
    AutoTabEfectos:CreateButton(" Dark-White", " Dark-White", function()
        Window:SetTextEffect("RainbowDarkWhite")
    end)

    --//  4TA PESTAÑA PERMANENTE: AJUSTES
    local AutoTabAjustes = Window:CreateTab("Ajustes", "Settings", "rbxassetid://130729134186771")
    AutoTabAjustes:CreateLabel("Configuración", "Settings", 14)
    AutoTabAjustes:CreateDivider()
    
    AutoTabAjustes:CreateToggle("Freeze Icono", "Freeze Icon", false, function(state)
        IconoCongelado = state
        if Window.Dragon and Window.Dragon.Draggable then
            Window.Dragon.Draggable = not state
        end
        if state then
            AutoTabAjustes:CreateLabel("Icono congelado (No se puede mover)", "Icon frozen (Cannot be moved)", 11)
        end
    end)
    
    --// ════════════════════════════════════════════════════════════════
    AutoTabAjustes:CreateDivider()
    AutoTabAjustes:CreateLabel("Sonidos", "Sounds", 12)
    AutoTabAjustes:CreateToggle("Sonidos Dinámicos", "Dynamic Sounds", DynamicClickSoundsEnabled, function(state)
        DynamicClickSoundsEnabled = state
        AutoTabAjustes:CreateLabel(
            state and " Sonidos por tema activados" or " Sonidos desactivados",
            state and " Theme sounds enabled"      or " Sounds disabled",
            11
        )
    end)

    --// ════════════════════════════════════════════════════════════════
    --// IDIOMA / LANGUAGE
    --// ════════════════════════════════════════════════════════════════
    AutoTabAjustes:CreateDivider()
    AutoTabAjustes:CreateLabel("Idioma", "Language", 12)

    local toggleES, toggleEN

    toggleES = AutoTabAjustes:CreateToggle(
        "Español", "Spanish",
        LanguageSystem.CurrentLanguage == "es",
        function(state)
            if state then
                LanguageSystem.CurrentLanguage = "es"
                LanguageSystem.Config.Language = "es"
                SaveConfig()
                if toggleEN then toggleEN.SetValue(false) end
            else
                toggleES.SetValue(true)
            end
        end
    )

    toggleEN = AutoTabAjustes:CreateToggle(
        "English", "English",
        LanguageSystem.CurrentLanguage == "en",
        function(state)
            if state then
                LanguageSystem.CurrentLanguage = "en"
                LanguageSystem.Config.Language = "en"
                SaveConfig()
                if toggleES then toggleES.SetValue(false) end
            else
                toggleEN.SetValue(true)
            end
        end
    )

    AutoTabAjustes:CreateDivider()
    AutoTabAjustes:CreateLabel(" Apariencia", " Appearance", 12)
    AutoTabAjustes:CreateLabel("Versión: v28 ULTRA MEJORADA", "Version: v28 ULTRA IMPROVED", 10)
    AutoTabAjustes:CreateLabel("Chat Fullscreen:  ACTIVO", "Chat Fullscreen:  ACTIVE", 10)
    AutoTabAjustes:CreateLabel("Colores Dinámicos:  ACTIVO", "Dynamic Colors:  ACTIVE", 10)

    
    --//  SISTEMA DE CHAT v27 (NUEVO)
    --// ════════════════════════════════════════════════════════════════
    

    --// CHAT SYSTEM
    --// ═════════════════════════════════════════════════════════════════════

    local ChatMessages = {}
    local MAX_MESSAGES = 100
    local MAX_CHAR = 500

    local function AddChatMessage(playerName, playerUserId, message, timestamp)
    	if #ChatMessages >= MAX_MESSAGES then
    		table.remove(ChatMessages, 1)
    	end

    	table.insert(ChatMessages, {
    		playerName = playerName or "Unknown",
    		playerUserId = playerUserId or 0,
    		message = message or "",
    		timestamp = timestamp or os.date("%H:%M:%S"),
    	})
    end

    local function GetChatHistory()
    	return ChatMessages
    end

    local function GetPlayerAvatar(userId)
    	userId = tonumber(userId) or 0
    	return ("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48"):format(userId)
    end

    --// ═════════════════════════════════════════════════════════════════════
    --// CHAT GLOBAL BACKEND SYNC (v28 - Tiempo Real)
    --// ═════════════════════════════════════════════════════════════════════
    --// Backend: Node.js + Express corriendo en Replit
    --// Sincroniza mensajes entre TODOS los jugadores conectados
    --// ═════════════════════════════════════════════════════════════════════

    local BACKEND_URL = "https://global-chat-sync--tomasmichi13.replit.app"
    local ChatSyncPollRate = 2  -- segundos entre cada consulta al backend
    local knownServerIds = {}   -- IDs de mensajes de servidor ya renderizados
    local backendConnected = false

    --// Función universal de HTTP request
    --// Usa la función nativa del executor si existe (evita el error
    --// "The current thread cannot call this function (blocked)" que da
    --// HttpService:PostAsync en algunos executors móviles como Delta).
    --// Si no encuentra ninguna, cae a HttpService como último recurso.
    local UniversalRequest = (syn and syn.request)
        or (http and http.request)
        or fluxus_request
        or http_request
        or request
        or (function(opts)
            -- Fallback: HttpService (puede fallar en algunos executors)
            local method = opts.Method or "GET"
            local ok, body = pcall(function()
                if method == "POST" then
                    return HttpService:PostAsync(opts.Url, opts.Body or "", Enum.HttpContentType.ApplicationJson)
                else
                    return HttpService:GetAsync(opts.Url)
                end
            end)
            if ok then
                return { Success = true, Body = body, StatusCode = 200 }
            else
                return { Success = false, Body = tostring(body), StatusCode = 0 }
            end
        end)

    --// Enviar mensaje al backend (no bloqueante)
    local function BackendSendMessage(playerName, playerId, message)
        task.spawn(function()
            local body = HttpService:JSONEncode({
                playerName = tostring(playerName),
                playerId = tostring(playerId),
                message = tostring(message),
            })

            local ok, result = pcall(function()
                return UniversalRequest({
                    Url = BACKEND_URL .. "/api/chat/send",
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = body,
                })
            end)

            if not ok or not result or (result.Success == false) then
                warn("[ChatGlobal] Error al enviar mensaje al backend:", ok and (result and result.StatusCode) or result)
            end
        end)
    end

    --// Traducir un mensaje bajo demanda (botón manual por mensaje)
    --// callback(translatedText, sourceLanguage, targetLanguage, errorMessage)
    local function TranslateMessage(text, targetLanguage, callback)
        task.spawn(function()
            local body = HttpService:JSONEncode({
                text = tostring(text),
                auto = true, -- el backend detecta el idioma de origen
                to = targetLanguage, -- el destino siempre es el idioma elegido por el lector
            })

            local ok, result = pcall(function()
                return UniversalRequest({
                    Url = BACKEND_URL .. "/api/translate",
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = body,
                })
            end)

            if not ok or not result or result.Success == false then
                warn("[ChatGlobal] Error al traducir:", ok and (result and result.StatusCode) or result)
                callback(nil, nil, targetLanguage, "request_failed")
                return
            end

            local decodeOk, data = pcall(function()
                return HttpService:JSONDecode(result.Body)
            end)

            if decodeOk and data and data.success and data.translated then
                callback(data.translated, data.from, data.to, nil)
            else
                warn("[ChatGlobal] Respuesta de /api/translate inválida:", result.Body)
                callback(nil, nil, targetLanguage, "invalid_response")
            end
        end)
    end

    --// Polling: pide mensajes nuevos cada ChatSyncPollRate segundos
    --// Se conecta después de crear el ChatTab (usa RenderMessage y AddChatMessage)
    local function StartBackendPolling(onNewMessage)
        task.spawn(function()
            while true do
                local ok, response = pcall(function()
                    return UniversalRequest({
                        Url = BACKEND_URL .. "/api/chat/messages",
                        Method = "GET",
                    })
                end)

                if ok and response and response.Body then
                    local success, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
                    if success and data and data.messages then
                        if not backendConnected then
                            backendConnected = true
                            print("[ChatGlobal] Conectado al backend correctamente")
                        end

                        for _, msg in ipairs(data.messages) do
                            if not knownServerIds[msg.id] then
                                knownServerIds[msg.id] = true
                                -- Evitar re-mostrar el mensaje que YO mismo envié
                                if tostring(msg.playerId) ~= tostring(LocalPlayer.UserId) then
                                    task.spawn(onNewMessage, msg)
                                end
                            end
                        end

                        -- ACTUALIZAR CONTADOR DE USUARIOS ONLINE
                        if data.onlineCount then
                            pcall(function()
                                OnlineLabel.Text = tostring(data.onlineCount)
                            end)
                        elseif data.messages then
                            -- Contar IDs únicos de los últimos mensajes como estimado
                            local uniqueIds = {}
                            for _, msg in ipairs(data.messages) do
                                if msg.playerId then
                                    uniqueIds[tostring(msg.playerId)] = true
                                end
                            end
                            local count = 0
                            for _ in pairs(uniqueIds) do count = count + 1 end
                            pcall(function()
                                OnlineLabel.Text = tostring(count)
                            end)
                        end
                    end
                else
                    if backendConnected then
                        warn("[ChatGlobal] Se perdió conexión con el backend")
                    end
                    backendConnected = false
                    pcall(function()
                        OnlineLabel.Text = "0"
                    end)
                end

                task.wait(ChatSyncPollRate)
            end
        end)
    end

    local ChatTab = Window:CreateTab("Chat", "Chat", "rbxassetid://115216752353020")
    local ChatTabPage = ChatTab.Page
    
    --// Deshabilitar el scroll de ChatTab.Page - Solo ChatContainer debe scrollear
    ChatTabPage.AutomaticCanvasSize = Enum.AutomaticSize.None
    ChatTabPage.CanvasSize = UDim2.new()
    ChatTabPage.ScrollBarThickness = 0
    ChatTabPage.ScrollingEnabled = false

    local ChatRoot = mk("Frame", {
    	Parent = ChatTabPage,
    	Size = UDim2.new(1, 0, 1, 0),
    	BackgroundTransparency = 1,
    	BorderSizePixel = 0,
    	LayoutOrder = 1,
    	ZIndex = 10,
    })

    --// Mini-header dentro de ChatRoot
    local ChatHeader = mk("Frame", {
    	Parent = ChatRoot,
    	Size = UDim2.new(1, 0, 0, 50),
    	Position = UDim2.new(0, 0, 0, 0),
    	BackgroundTransparency = 1,
    	BorderSizePixel = 0,
    	ZIndex = 10,
    })

    mk("UIListLayout", {
    	Parent = ChatHeader,
    	Padding = UDim.new(0, 8),
    	SortOrder = Enum.SortOrder.LayoutOrder,
    	VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    local HeaderLabel = mk("TextLabel", {
    	Parent = ChatHeader,
    	Size = UDim2.new(1, 0, 0, 20),
    	BackgroundTransparency = 1,
    	Text = "🌐 Global Chat ° New",
    	Font = Enum.Font.GothamBold,
    	TextSize = 14,
    	TextColor3 = Theme.Text,
    	TextXAlignment = Enum.TextXAlignment.Left,
    	LayoutOrder = 1,
    	ZIndex = 11,
    })

    -- CONTADOR DE USUARIOS ONLINE
    local OnlineCounter = mk("Frame", {
        Parent = ChatHeader,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(1, -8, 0, 4),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 12,
        AutomaticSize = Enum.AutomaticSize.X,
    })

    local OnlineIcon = mk("ImageLabel", {
        Parent = OnlineCounter,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 0, 0.5, -9),
        BackgroundTransparency = 1,
        Image = "rbxassetid://74246983577629",
        ImageColor3 = Theme.Accent,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 13,
    })

    local OnlineLabel = mk("TextLabel", {
        Parent = OnlineCounter,
        Size = UDim2.new(0, 40, 0, 18),
        Position = UDim2.new(0, 22, 0.5, -9),
        BackgroundTransparency = 1,
        Text = "...",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    })

    local HeaderDivider = mk("Frame", {
    	Parent = ChatHeader,
    	Size = UDim2.new(1, 0, 0, 1),
    	BackgroundColor3 = Theme.Stroke,
    	BorderSizePixel = 0,
    	LayoutOrder = 2,
    	ZIndex = 11,
    })

    local ChatContainer = mk("ScrollingFrame", {
    	Parent = ChatRoot,
    	Size = UDim2.new(1, 0, 1, -94),
    	Position = UDim2.new(0, 0, 0, 50),
    	BackgroundColor3 = Theme.Background,
    	BackgroundTransparency = 1,
    	BorderSizePixel = 0,
    	ScrollBarThickness = 2,
    	CanvasSize = UDim2.new(0, 0, 0, 0),
    	AutomaticCanvasSize = Enum.AutomaticSize.Y,
    	ScrollingDirection = Enum.ScrollingDirection.Y,
    	ClipsDescendants = true,
    	ZIndex = 11,
    })
    corner(ChatContainer, 6)

    mk("UIListLayout", {
    	Parent = ChatContainer,
    	Padding = UDim.new(0, 8),
    	SortOrder = Enum.SortOrder.LayoutOrder,
    	VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    mk("UIPadding", {
    	Parent = ChatContainer,
    	PaddingTop = UDim.new(0, 6),
    	PaddingLeft = UDim.new(0, 8),
    	PaddingRight = UDim.new(0, 8),
    	PaddingBottom = UDim.new(0, 6),
    })

    local ChatFooter = mk("Frame", {
    	Parent = ChatRoot,
    	Size = UDim2.new(1, 0, 0, 44),
    	Position = UDim2.new(0, 0, 1, -44),
    	BackgroundTransparency = 1,
    	BorderSizePixel = 0,
    	ZIndex = 20,
    })

    local MessageInput = mk("TextBox", {
    	Parent = ChatFooter,
    	Size = UDim2.new(1, -120, 0, 36),
    	Position = UDim2.new(0, 50, 0.5, -18),
    	BackgroundColor3 = Theme.Secondary,
    	BackgroundTransparency = 0.25,
    	BorderSizePixel = 0,
    	Text = "",
    	ClearTextOnFocus = false,
    	PlaceholderText = "Escribir...",
    	PlaceholderColor3 = Theme.TextDim,
    	TextColor3 = Theme.Text,
    	TextSize = 13,
    	Font = Enum.Font.Gotham,
    	TextXAlignment = Enum.TextXAlignment.Left,
    	ZIndex = 21,
    })
    MessageInput:SetAttribute("ThemeRole", "Secondary")
    corner(MessageInput, 8)
    mk("UIPadding", {Parent = MessageInput, PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})

    local SendButton = mk("ImageButton", {
    	Parent = ChatFooter,
    	Size = UDim2.new(0, 60, 0, 36),
    	Position = UDim2.new(1, -68, 0.5, -18),
    	BackgroundColor3 = Theme.Accent,
    	BorderSizePixel = 0,
    	Image = "rbxassetid://132362297660069",
    	ImageColor3 = Color3.fromRGB(255, 255, 255),
    	ScaleType = Enum.ScaleType.Fit,
    	ZIndex = 21,
    })
    SendButton:SetAttribute("ThemeRole", "Accent")
    corner(SendButton, 8)

    local CharLabel = mk("TextLabel", {
    	Parent = ChatFooter,
    	Size = UDim2.new(0, 90, 0, 12),
    	Position = UDim2.new(0, 0, 1, -10),
    	BackgroundTransparency = 1,
    	Text = "0 / 500",
    	Font = Enum.Font.Gotham,
    	TextSize = 9,
    	TextColor3 = Theme.TextDim,
    	TextXAlignment = Enum.TextXAlignment.Left,
    	ZIndex = 21,
    })

    -- BOTÓN STICKER (izquierda del input)
    local StickerButton = mk("ImageButton", {
        Parent = ChatFooter,
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 8, 0.5, -18),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Image = "rbxassetid://70677501354748",
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 21,
    })
    StickerButton:SetAttribute("ThemeRole", "Secondary")
    corner(StickerButton, 8)

    -- PANEL DE STICKERS
    local StickerPanel = mk("Frame", {
        Parent = ChatRoot,
        Size = UDim2.new(1, -16, 0, 230),
        Position = UDim2.new(0, 8, 1, -280),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 50,
    })
    StickerPanel:SetAttribute("ThemeRole", "Background")
    corner(StickerPanel, 12)
    stroke(StickerPanel, Theme.Stroke, 1, 0.5)

    -- HEADER DEL PANEL
    local PanelHeader = mk("Frame", {
        Parent = StickerPanel,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 51,
    })

    local TabStickers = mk("TextButton", {
        Parent = PanelHeader,
        Size = UDim2.new(0, 90, 0, 28),
        Position = UDim2.new(0, 8, 0.5, -14),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Text = "Stickers",
        TextColor3 = Theme.AccentText,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 52,
    })
    corner(TabStickers, 6)

    local TabMisStickers = mk("TextButton", {
        Parent = PanelHeader,
        Size = UDim2.new(0, 100, 0, 28),
        Position = UDim2.new(0, 106, 0.5, -14),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Text = "Mis Stickers",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 52,
    })
    corner(TabMisStickers, 6)

    -- BOTÓN CERRAR CON ASSET X
    local PanelClose = mk("ImageButton", {
        Parent = PanelHeader,
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -36, 0.5, -14),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "rbxassetid://132418587917225",
        ImageColor3 = Theme.TextDim,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 52,
    })

    -- GRID STICKERS DEFAULT
    local StickerGrid = mk("ScrollingFrame", {
        Parent = StickerPanel,
        Size = UDim2.new(1, -16, 1, -46),
        Position = UDim2.new(0, 8, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 51,
    })
    mk("UIGridLayout", {
        Parent = StickerGrid,
        CellSize = UDim2.new(0, 68, 0, 68),
        CellPadding = UDim2.new(0, 8, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    })
    mk("UIPadding", {
        Parent = StickerGrid,
        PaddingTop = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
    })

    -- GRID MIS STICKERS
    local MisStickerGrid = mk("ScrollingFrame", {
        Parent = StickerPanel,
        Size = UDim2.new(1, -16, 1, -46),
        Position = UDim2.new(0, 8, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        ZIndex = 51,
    })
    mk("UIGridLayout", {
        Parent = MisStickerGrid,
        CellSize = UDim2.new(0, 68, 0, 68),
        CellPadding = UDim2.new(0, 8, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
    })
    mk("UIPadding", {
        Parent = MisStickerGrid,
        PaddingTop = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
    })

    -- BOTÓN "+" AGREGAR STICKER CUSTOM
    local AddStickerBtn = mk("TextButton", {
        Parent = MisStickerGrid,
        Size = UDim2.new(0, 68, 0, 68),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Text = "+",
        TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamBold,
        TextSize = 28,
        ZIndex = 53,
        LayoutOrder = 999,
    })
    corner(AddStickerBtn, 8)
    stroke(AddStickerBtn, Theme.Stroke, 1.5, 0.3)

    -- INPUT PARA ID CUSTOM
    local AddStickerInput = mk("TextBox", {
        Parent = StickerPanel,
        Size = UDim2.new(1, -80, 0, 30),
        Position = UDim2.new(0, 8, 1, -38),
        BackgroundColor3 = Theme.Secondary,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "rbxassetid://...",
        PlaceholderColor3 = Theme.TextDim,
        TextColor3 = Theme.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        ZIndex = 53,
        Visible = false,
    })
    corner(AddStickerInput, 6)

    local ConfirmAddBtn = mk("TextButton", {
        Parent = StickerPanel,
        Size = UDim2.new(0, 64, 0, 30),
        Position = UDim2.new(1, -72, 1, -38),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Text = "Agregar",
        TextColor3 = Theme.AccentText,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        ZIndex = 53,
        Visible = false,
    })
    corner(ConfirmAddBtn, 6)

    -- STICKERS PERSONALIZADOS
    local DefaultStickers = {
        {id = "rbxassetid://135857695171095", name = "Sonrisa"},
        {id = "rbxassetid://138363247925206", name = "Llorar"},
        {id = "rbxassetid://76164124882568", name = "Amor"},
        {id = "rbxassetid://76164124882568", name = "Corazón"},
        {id = "rbxassetid://133861773375312", name = "Emoji"},
        {id = "rbxassetid://109165098870367", name = "Risa"},
        {id = "rbxassetid://89213081637073", name = "Sorpresa"},
        {id = "rbxassetid://80817302481160", name = "Triste"},
        {id = "rbxassetid://72815688632249", name = "Enojado"},
        {id = "rbxassetid://72602706593283", name = "Wink"},
        {id = "rbxassetid://129224642026377", name = "Cool"},
    }

    -- CARGAR STICKERS CUSTOM GUARDADOS
    local CustomStickers = {}
    if readfile and isfile then
        pcall(function()
            if isfile("YinYang_CustomStickers.json") then
                local data = game:GetService("HttpService"):JSONDecode(readfile("YinYang_CustomStickers.json"))
                if type(data) == "table" then
                    CustomStickers = data
                end
            end
        end)
    end

    local function SaveCustomStickers()
        pcall(function()
            if writefile then
                writefile("YinYang_CustomStickers.json",
                    game:GetService("HttpService"):JSONEncode(CustomStickers))
            end
        end)
    end

    local function ScrollChatToBottom()
    	task.defer(function()
    		task.wait()
    		if ChatContainer and ChatContainer.Parent then
    			ChatContainer.CanvasPosition = Vector2.new(0, math.max(0, ChatContainer.AbsoluteCanvasSize.Y))
    		end
    	end)
    end

    --// ════════════════════════════════════════════════════════════════
    --// SISTEMA DE BURBUJAS POR USUARIO
    --// ════════════════════════════════════════════════════════════════

    local UserBubbleAssets = {}
    local UserBubbleStyles = {}

    local function NormalizeUserId(userId)
        return tonumber(userId) or 0
    end

    local function GetContrast(bgColor)
        if typeof(bgColor) ~= "Color3" then
            return Color3.fromRGB(255, 255, 255)
        end

        local luminance = (bgColor.R * 0.299) + (bgColor.G * 0.587) + (bgColor.B * 0.114)
        if luminance >= 0.58 then
            return Color3.fromRGB(25, 25, 25)
        end

        return Color3.fromRGB(255, 255, 255)
    end

    function Window:SetUserBubbleAsset(userId, assetId)
        userId = NormalizeUserId(userId)
        if userId == 0 then
            return
        end

        if assetId == nil or assetId == "" then
            UserBubbleAssets[userId] = nil
            return
        end

        UserBubbleAssets[userId] = tostring(assetId)
    end

    function Window:SetUserBubbleStyle(userId, style)
        userId = NormalizeUserId(userId)
        if userId == 0 then
            return
        end

        if type(style) ~= "table" then
            UserBubbleStyles[userId] = nil
            return
        end

        UserBubbleStyles[userId] = table.clone(style)
    end

    local function GetUserBubbleAsset(userId)
        return UserBubbleAssets[NormalizeUserId(userId)]
    end

    local function GetUserBubbleStyle(userId)
        return UserBubbleStyles[NormalizeUserId(userId)] or {}
    end

    --// ════════════════════════════════════════════════════════════════
    --// SISTEMA DE EFECTOS ESPECIALES - ADMIN (MOUSOZA)
    --// ════════════════════════════════════════════════════════════════
    
    local ADMIN_USER_ID = 9549448191
    local ADMIN_ASSET = "rbxassetid://81745105398770"   -- fondo burbuja
    local ADMIN_FLOAT_ASSET = "rbxassetid://71845994976179"  -- asset flotante encima
    
    -- Ciclos de colores para mousoza (Rainbow épico)
    local MouseozaNameColors = {
        Color3.fromRGB(255, 80,  80),     -- Rojo
        Color3.fromRGB(255, 160, 40),     -- Naranja
        Color3.fromRGB(255, 240, 40),     -- Amarillo
        Color3.fromRGB(80,  255, 120),    -- Verde
        Color3.fromRGB(40,  200, 255),    -- Cyan
        Color3.fromRGB(140, 80,  255),    -- Violeta
        Color3.fromRGB(255, 80,  200),    -- Rosa
    }

    local MouseozaBorderColors = {
        Color3.fromRGB(255, 255, 255),    -- Blanco
        Color3.fromRGB(0,   0,   0),      -- Negro
    }
    
    local function StartMouseozaNameCycle(UsernameLabel)
        local colorIndex = 1
        local cycleDuration = 2.0
        local colorCount = #MouseozaNameColors

        -- UIStroke para el borde del nombre
        local nameStroke = Instance.new("UIStroke")
        nameStroke.Thickness = 1.5
        nameStroke.Transparency = 0.0
        nameStroke.Color = MouseozaNameColors[1]
        nameStroke.Parent = UsernameLabel

        task.spawn(function()
            local elapsed = 0
            while UsernameLabel and UsernameLabel.Parent do
                local dt = task.wait(0.05)
                elapsed = elapsed + dt

                -- Color principal del nombre (ciclo suave)
                local t = (elapsed / cycleDuration) % 1
                local idxA = math.floor(t * colorCount) + 1
                local idxB = (idxA % colorCount) + 1
                local alpha = (t * colorCount) % 1

                local colorA = MouseozaNameColors[idxA]
                local colorB = MouseozaNameColors[idxB]
                local lerpedColor = colorA:Lerp(colorB, alpha)

                UsernameLabel.TextColor3 = lerpedColor

                -- UIStroke con color opuesto al texto (desfasado 180°)
                local tOffset = (t + 0.5) % 1
                local idxC = math.floor(tOffset * colorCount) + 1
                local idxD = (idxC % colorCount) + 1
                local alphaD = (tOffset * colorCount) % 1
                nameStroke.Color = MouseozaNameColors[idxC]:Lerp(MouseozaNameColors[idxD], alphaD)

                -- Brillo sinusoidal (TextStrokeTransparency)
                UsernameLabel.TextStrokeTransparency = 0.4 + 0.4 * math.sin(elapsed * math.pi * 1.5)
                UsernameLabel.TextStrokeColor3 = lerpedColor
            end
        end)
    end
    
    local function StartMouseozaBorderCycle(Bubble, strokeThickness)
        task.spawn(function()
            local elapsed = 0
            while Bubble and Bubble.Parent do
                local dt = task.wait(0.05)
                elapsed = elapsed + dt

                local stroke = Bubble:FindFirstChild("UIStroke")
                if stroke then
                    -- Sinusoidal Blanco ↔ Negro (mismo efecto que la librería)
                    local t = (math.sin(elapsed * math.pi * 0.6) + 1) / 2
                    stroke.Color = Color3.fromRGB(
                        math.floor(255 * t),
                        math.floor(255 * t),
                        math.floor(255 * t)
                    )
                    -- Grosor pulsante suave
                    stroke.Thickness = strokeThickness + 0.6 * math.abs(math.sin(elapsed * math.pi * 0.8))
                end
            end
        end)
    end

    local function RenderMessage(playerName, userId, messageText, timeStamp, isSelf)
    	-- DETECCIÓN DE STICKER
    	local stickerAsset = messageText:match("^%[%[STICKER:(rbxassetid://%d+)%]%]$")
    	if stickerAsset then
    		local StickerFrame = mk("Frame", {
    			Parent = ChatContainer,
    			Size = UDim2.new(1, 0, 0, 172),
    			BackgroundTransparency = 1,
    			BorderSizePixel = 0,
    			LayoutOrder = #ChatMessages,
    			ZIndex = 12,
    		})

    		-- Nombre + timestamp
    		mk("TextLabel", {
    			Parent = StickerFrame,
    			Size = UDim2.new(1, -12, 0, 16),
    			Position = UDim2.new(0, 12, 0, 4),
    			BackgroundTransparency = 1,
    			Text = (isSelf and "Tú" or tostring(playerName)) .. " • " .. tostring(timeStamp),
    			Font = Enum.Font.GothamBold,
    			TextSize = 11,
    			TextColor3 = isSelf and Theme.Accent or Theme.TextDim,
    			TextXAlignment = Enum.TextXAlignment.Left,
    			ZIndex = 13,
    		})

    		-- Sticker grande (igual a referencia)
    		mk("ImageLabel", {
    			Parent = StickerFrame,
    			Size = UDim2.new(0, 148, 0, 148),
    			Position = UDim2.new(0, 12, 0, 22),
    			BackgroundTransparency = 1,
    			Image = stickerAsset,
    			ScaleType = Enum.ScaleType.Fit,
    			ZIndex = 13,
    		})

    		ScrollChatToBottom()
    		return
    	end
    	local style = GetUserBubbleStyle(userId)
    	local assetId = GetUserBubbleAsset(userId)

    	local baseColor = style.BackgroundColor3 or (isSelf and Theme.Accent or Theme.Secondary)
    	local baseTransparency = style.BackgroundTransparency
    	    or (assetId and 0.16 or (isSelf and 0.14 or 0.22))

    	local frameTextColor = style.TextColor3 or (assetId and GetContrast(baseColor) or (isSelf and Color3.fromRGB(255, 255, 255) or Theme.Text))
    	local nameColor = style.NameColor3 or (assetId and GetContrast(baseColor) or (isSelf and Color3.fromRGB(200, 255, 200) or Theme.Accent))
    	local strokeColor = style.StrokeColor3 or Theme.Stroke
    	local cornerRadius = style.CornerRadius or 12

    	--// ════════════════════════════════════════════════════════════════
    	--// ESTRUCTURA PROFESIONAL: TARJETA INDEPENDIENTE
    	--// ════════════════════════════════════════════════════════════════

    	-- CONTENEDOR PRINCIPAL DE LA TARJETA
    	local MessageFrame = mk("Frame", {
    	    Parent = ChatContainer,
    	    Size = UDim2.new(1, 0, 0, 0),
    	    AutomaticSize = Enum.AutomaticSize.Y,
    	    BackgroundTransparency = 1,
    	    BorderSizePixel = 0,
    	    ClipsDescendants = false,
    	    LayoutOrder = #ChatMessages,
    	    ZIndex = 12,
    	})

    	-- AVATAR: Arriba izquierda, alineado al inicio
    	local AvatarLabel = mk("ImageLabel", {
    	    Parent = MessageFrame,
    	    Size = UDim2.new(0, 36, 0, 36),
    	    Position = UDim2.new(0, 0, 0, 0),
    	    BackgroundColor3 = style.AvatarBgColor3 or (isSelf and Theme.Accent or Theme.AccentOff),
    	    BackgroundTransparency = style.AvatarBgTransparency or 0.05,
    	    BorderSizePixel = 0,
    	    Image = GetPlayerAvatar(userId),
    	    ScaleType = Enum.ScaleType.Crop,
    	    ZIndex = 14,
    	})
    	corner(AvatarLabel, 999)
    	stroke(AvatarLabel, strokeColor, 1, 0.45)

    	-- CONTENEDOR DE CONTENIDO (Header + Bubble)
    	local ContentFrame = mk("Frame", {
    	    Parent = MessageFrame,
    	    Size = UDim2.new(1, -46, 0, 0),
    	    Position = UDim2.new(0, 46, 0, 0),
    	    AutomaticSize = Enum.AutomaticSize.Y,
    	    BackgroundTransparency = 1,
    	    BorderSizePixel = 0,
    	    ClipsDescendants = false,
    	    ZIndex = 12,
    	})

    	-- LAYOUT VERTICAL PARA HEADER + BUBBLE
    	mk("UIListLayout", {
    	    Parent = ContentFrame,
    	    Padding = UDim.new(0, 4),
    	    SortOrder = Enum.SortOrder.LayoutOrder,
    	    VerticalAlignment = Enum.VerticalAlignment.Top,
    	})

    	--// HEADER: Nombre y Hora
    	local HeaderFrame = mk("Frame", {
    	    Parent = ContentFrame,
    	    Size = UDim2.new(1, 0, 0, 16),
    	    BackgroundTransparency = 1,
    	    BorderSizePixel = 0,
    	    LayoutOrder = 1,
    	    ZIndex = 15,
    	})

    	-- Nombre del usuario (Destacado)
    	local UsernameLabel = mk("TextLabel", {
    	    Parent = HeaderFrame,
    	    Size = UDim2.new(0, 0, 1, 0),
    	    Position = UDim2.new(0, 0, 0, 0),
    	    BackgroundTransparency = 1,
    	    Text = (isSelf and "Tú" or tostring(playerName or "Unknown")),
    	    Font = Enum.Font.GothamBold,
    	    TextSize = 12,
    	    TextColor3 = nameColor,
    	    TextXAlignment = Enum.TextXAlignment.Left,
    	    TextYAlignment = Enum.TextYAlignment.Center,
    	    AutomaticSize = Enum.AutomaticSize.X,
    	    ZIndex = 15,
    	})
    	UsernameLabel:SetAttribute("ThemeTextRole", "Text")

    	--// EFECTOS ESPECIALES PARA MOUSOZA
    	if userId == ADMIN_USER_ID then
    	    StartMouseozaNameCycle(UsernameLabel)
    	    -- Configurar asset especial para mousoza
    	    if not assetId then
    	        assetId = ADMIN_ASSET
    	    end
    	end

    	-- Hora (Discreta, gris)
    	local TimeLabel = mk("TextLabel", {
    	    Parent = HeaderFrame,
    	    Size = UDim2.new(1, 0, 1, 0),
    	    Position = UDim2.new(0, 0, 0, 0),
    	    BackgroundTransparency = 1,
    	    Text = tostring(timeStamp or os.date("%H:%M:%S")),
    	    Font = Enum.Font.Gotham,
    	    TextSize = 10,
    	    TextColor3 = Theme.TextDim,
    	    TextXAlignment = Enum.TextXAlignment.Right,
    	    TextYAlignment = Enum.TextYAlignment.Center,
    	    ZIndex = 15,
    	})
    	TimeLabel:SetAttribute("ThemeTextRole", "Text")

    	--// BURBUJA: Contenedor adaptativo para el texto
    	local Bubble = mk("Frame", {
    	    Parent = ContentFrame,
    	    Size = UDim2.new(1, 0, 0, 0),
    	    AutomaticSize = Enum.AutomaticSize.Y,
    	    BackgroundColor3 = baseColor,
    	    BackgroundTransparency = baseTransparency,
    	    BorderSizePixel = 0,
    	    ClipsDescendants = true,
    	    LayoutOrder = 2,
    	    ZIndex = 12,
    	})
    	Bubble:SetAttribute("ThemeRole", isSelf and "Accent" or "Secondary")
    	corner(Bubble, cornerRadius)
    	stroke(Bubble, strokeColor, 1.25, 0.35)

    	--// EFECTOS DE BORDES PARA MOUSOZA
    	if userId == ADMIN_USER_ID then
    	    StartMouseozaBorderCycle(Bubble, 1.25)

    	    -- Asset flotante: Parent = MessageFrame (sin ClipsDescendants)
    	    -- Bubble empieza en y=20 del MessageFrame (header 16 + padding 4)
    	    -- Pibble 95x85: patas en el borde superior de la burbuja
    	    local FloatAsset = mk("ImageLabel", {
    	        Parent = MessageFrame,
    	        Size = UDim2.new(0, 95, 0, 85),
    	        Position = UDim2.new(0, 60, 0, -20),
    	        AnchorPoint = Vector2.new(0, 0),
    	        BackgroundTransparency = 1,
    	        Image = ADMIN_FLOAT_ASSET,
    	        ScaleType = Enum.ScaleType.Fit,
    	        ZIndex = 20,
    	    })
    	end

    	-- PADDING INTERNO: 10px en todos lados
    	mk("UIPadding", {
    	    Parent = Bubble,
    	    PaddingTop = UDim.new(0, 10),
    	    PaddingBottom = UDim.new(0, 10),
    	    PaddingLeft = UDim.new(0, 10),
    	    PaddingRight = UDim.new(0, 10),
    	})

    	-- Asset de fondo opcional
    	if assetId then
    	    local BubbleAsset = mk("ImageLabel", {
    	        Parent = Bubble,
    	        Size = UDim2.new(1, 20, 1, 20),
    	        Position = UDim2.new(0, -10, 0, -10),
    	        BackgroundTransparency = 1,
    	        Image = assetId,
    	        ImageTransparency = style.ImageTransparency or 0.0,  -- Completamente visible
    	        ImageColor3 = style.AssetTintColor3 or Color3.fromRGB(255, 255, 255),
    	        ScaleType = Enum.ScaleType.Crop,
    	        ZIndex = 11,
    	    })
    	    corner(BubbleAsset, cornerRadius)

    	    local Wash = mk("Frame", {
    	        Parent = Bubble,
    	        Size = UDim2.new(1, 20, 1, 20),
    	        Position = UDim2.new(0, -10, 0, -10),
    	        BackgroundColor3 = style.AssetWashColor3 or baseColor,
    	        BackgroundTransparency = style.AssetWashTransparency or 0.92,  -- Wash casi invisible
    	        BorderSizePixel = 0,
    	        ZIndex = 11,
    	    })
    	    corner(Wash, cornerRadius)
    	    Wash.Active = false
    	end

    	-- TEXTO DEL MENSAJE: Solo texto en la burbuja
    	local MessageLabel = mk("TextLabel", {
    	    Parent = Bubble,
    	    Size = UDim2.new(1, 0, 0, 0),
    	    BackgroundTransparency = 1,
    	    Text = tostring(messageText or ""),
    	    Font = Enum.Font.GothamBold,
    	    TextSize = 13,
    	    TextColor3 = frameTextColor,
    	    TextWrapped = true,
    	    TextXAlignment = Enum.TextXAlignment.Left,
    	    TextYAlignment = Enum.TextYAlignment.Top,
    	    AutomaticSize = Enum.AutomaticSize.Y,
    	    ZIndex = 15,
    	})
    	MessageLabel:SetAttribute("ThemeTextRole", "Text")

    	--// ════════════════════════════════════════════════════════════════
    	--// BOTÓN DE TRADUCCIÓN MANUAL (por mensaje, bajo demanda)
    	--// Se agrega como nueva fila de ContentFrame (usa su UIListLayout ya
    	--// existente) — no toca la Bubble ni el MessageLabel original.
    	--// ════════════════════════════════════════════════════════════════
    	local TranslateBtn = mk("TextButton", {
    	    Parent = ContentFrame,
    	    Size = UDim2.new(0, 0, 0, 14),
    	    AutomaticSize = Enum.AutomaticSize.X,
    	    BackgroundTransparency = 1,
    	    Text = GetText("Traducir", "Translate"),
    	    Font = Enum.Font.GothamBold,
    	    TextSize = 10,
    	    TextColor3 = Theme.Accent,
    	    TextXAlignment = Enum.TextXAlignment.Left,
    	    LayoutOrder = 3,
    	    ZIndex = 15,
    	})

    	local translatedBubble, isTranslated, isLoadingTranslation = nil, false, false

    	local function ClearTranslation()
    	    if translatedBubble then
    	        translatedBubble:Destroy()
    	        translatedBubble = nil
    	    end
    	    isTranslated = false
    	    TranslateBtn.Text = GetText("Traducir", "Translate")
    	end

    	local function ShowTranslation(translatedText)
    	    translatedBubble = mk("Frame", {
    	        Parent = ContentFrame,
    	        Size = UDim2.new(1, 0, 0, 0),
    	        AutomaticSize = Enum.AutomaticSize.Y,
    	        BackgroundColor3 = baseColor,
    	        BackgroundTransparency = 1,
    	        BorderSizePixel = 0,
    	        ClipsDescendants = true,
    	        LayoutOrder = 4,
    	        ZIndex = 12,
    	    })
    	    corner(translatedBubble, cornerRadius)
    	    stroke(translatedBubble, Theme.Accent, 1, 0.6)
    	    mk("UIPadding", {
    	        Parent = translatedBubble,
    	        PaddingTop = UDim.new(0, 8),
    	        PaddingBottom = UDim.new(0, 8),
    	        PaddingLeft = UDim.new(0, 10),
    	        PaddingRight = UDim.new(0, 10),
    	    })
    	    local TranslatedLabel = mk("TextLabel", {
    	        Parent = translatedBubble,
    	        Size = UDim2.new(1, 0, 0, 0),
    	        BackgroundTransparency = 1,
    	        Text = tostring(translatedText),
    	        Font = Enum.Font.Gotham,
    	        TextSize = 12,
    	        TextColor3 = Theme.TextDim,
    	        TextWrapped = true,
    	        TextXAlignment = Enum.TextXAlignment.Left,
    	        TextYAlignment = Enum.TextYAlignment.Top,
    	        AutomaticSize = Enum.AutomaticSize.Y,
    	        ZIndex = 15,
    	    })
    	    TranslatedLabel:SetAttribute("ThemeTextRole", "TextDim")
    	    isTranslated = true
    	    TranslateBtn.Text = GetText("Ocultar traducción", "Hide translation")
    	    ScrollChatToBottom()
    	end

    	TranslateBtn.MouseButton1Click:Connect(function()
    	    if isLoadingTranslation then return end

    	    if isTranslated then
    	        ClearTranslation()
    	        return
    	    end

    	    isLoadingTranslation = true
    	    TranslateBtn.Text = GetText("Traduciendo...", "Translating...")

    	    local targetLanguage = LanguageSystem.CurrentLanguage == "en" and "en" or "es"

    	    TranslateMessage(messageText, targetLanguage, function(translated, fromLang, toLang, err)
    	        isLoadingTranslation = false

    	        if translated and translated ~= "" and translated ~= messageText then
    	            ShowTranslation(translated)
    	        else
    	            local sameLanguage = (fromLang and fromLang == targetLanguage) or (toLang and toLang == targetLanguage)
    	            if sameLanguage or translated == messageText then
    	                TranslateBtn.Text = GetText("Ya estaba en este idioma", "Already in this language")
    	            else
    	                TranslateBtn.Text = GetText("Error, reintentar", "Error, retry")
    	            end
    	            task.delay(2, function()
    	                if TranslateBtn and TranslateBtn.Parent then
    	                    TranslateBtn.Text = GetText("Traducir", "Translate")
    	                end
    	            end)
    	        end
    	    end)
    	end)

    	--// ANIMACIÓN DE APARICIÓN: Transición suave (0.15s)
    	Bubble.BackgroundTransparency = baseTransparency + 1
    	AvatarLabel.ImageTransparency = 1

    	local tweenInfo = TweenInfo.new(
    	    0.15,
    	    Enum.EasingStyle.Quad,
    	    Enum.EasingDirection.Out
    	)

    	local tweenBubble = TweenService:Create(Bubble, tweenInfo, {BackgroundTransparency = baseTransparency})
    	local tweenAvatar = TweenService:Create(AvatarLabel, tweenInfo, {ImageTransparency = 0})

    	tweenBubble:Play()
    	tweenAvatar:Play()

    	ScrollChatToBottom()
    end

    local function SendMessage()
    	local messageText = MessageInput.Text or ""
    	messageText = messageText:sub(1, MAX_CHAR)

    	if messageText:match("^%s*$") then
    		return
    	end

    	local localPlayer = Players.LocalPlayer
    	local timestamp = os.date("%H:%M:%S")

    	AddChatMessage(localPlayer.Name, localPlayer.UserId, messageText, timestamp)
    	RenderMessage(localPlayer.Name, localPlayer.UserId, messageText, timestamp, true)

    	-- Sincronizar con el backend para que otros jugadores lo reciban
    	BackendSendMessage(localPlayer.Name, localPlayer.UserId, messageText)

    	MessageInput.Text = ""
    	CharLabel.Text = "0 / 500"
    end

    MessageInput.Changed:Connect(function(property)
    	if property ~= "Text" then
    		return
    	end

    	if #MessageInput.Text > MAX_CHAR then
    		MessageInput.Text = MessageInput.Text:sub(1, MAX_CHAR)
    	end

    	CharLabel.Text = tostring(#MessageInput.Text) .. " / " .. tostring(MAX_CHAR)
    end)

    SendButton.MouseButton1Click:Connect(SendMessage)

    --// ════════════════════════════════════════════════════════════════
    --// LÓGICA DE STICKERS (DESPUÉS de RenderMessage)
    --// ════════════════════════════════════════════════════════════════

    local function SendSticker(assetId)
        local localPlayer = Players.LocalPlayer
        local timestamp = os.date("%H:%M:%S")
        local stickerMsg = "[[STICKER:" .. assetId .. "]]"
        AddChatMessage(localPlayer.Name, localPlayer.UserId, stickerMsg, timestamp)
        RenderMessage(localPlayer.Name, localPlayer.UserId, stickerMsg, timestamp, true)
        BackendSendMessage(localPlayer.Name, localPlayer.UserId, stickerMsg)
        StickerPanel.Visible = false
    end

    local function CreateStickerBtn(parent, assetId, isCustom)
        local StickerBtn = mk("ImageButton", {
            Parent = parent,
            Size = UDim2.new(0, 68, 0, 68),
            BackgroundColor3 = Theme.Secondary,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Image = assetId,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 53,
        })
        corner(StickerBtn, 8)

        StickerBtn.MouseButton1Click:Connect(function()
            SendSticker(assetId)
        end)

        StickerBtn.MouseEnter:Connect(function()
            TweenService:Create(StickerBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0.1}):Play()
        end)
        StickerBtn.MouseLeave:Connect(function()
            TweenService:Create(StickerBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0.5}):Play()
        end)

        if isCustom then
            local DelBtn = mk("TextButton", {
                Parent = StickerBtn,
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(1, -20, 0, 2),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                BorderSizePixel = 0,
                Text = "✕",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                ZIndex = 54,
            })
            corner(DelBtn, 4)
            DelBtn.MouseButton1Click:Connect(function()
                for i, s in ipairs(CustomStickers) do
                    if s.id == assetId then
                        table.remove(CustomStickers, i)
                        break
                    end
                end
                SaveCustomStickers()
                StickerBtn:Destroy()
            end)
        end
        return StickerBtn
    end

    -- CARGAR STICKERS DEL REPO EN GRID
    -- Usa StickerOrder del repo si LoadStickers() funcionó,
    -- si no, usa el orden de la tabla embebida como fallback
    local stickerOrder = StickerOrder or {
        "Sonrisa","Llorar","Amor","Corazon",
        "Emoji","Risa","Sorpresa","Triste",
        "Enojado","Wink","Cool",
    }
    for _, name in ipairs(stickerOrder) do
        local sticker = StickerPalettes[name]
        if sticker and sticker.Image then
            CreateStickerBtn(StickerGrid, sticker.Image, false)
        end
    end

    -- CARGAR CUSTOM STICKERS
    for _, s in ipairs(CustomStickers) do
        CreateStickerBtn(MisStickerGrid, s.id, true)
    end

    -- LÓGICA TABS
    local function ShowStickerTab(tab)
        if tab == "stickers" then
            StickerGrid.Visible = true
            MisStickerGrid.Visible = false
            AddStickerInput.Visible = false
            ConfirmAddBtn.Visible = false
            TabStickers.BackgroundColor3 = Theme.Accent
            TabStickers.BackgroundTransparency = 0
            TabStickers.TextColor3 = Theme.AccentText
            TabMisStickers.BackgroundColor3 = Theme.Secondary
            TabMisStickers.BackgroundTransparency = 0.4
            TabMisStickers.TextColor3 = Theme.Text
        else
            StickerGrid.Visible = false
            MisStickerGrid.Visible = true
            TabStickers.BackgroundColor3 = Theme.Secondary
            TabStickers.BackgroundTransparency = 0.4
            TabStickers.TextColor3 = Theme.Text
            TabMisStickers.BackgroundColor3 = Theme.Accent
            TabMisStickers.BackgroundTransparency = 0
            TabMisStickers.TextColor3 = Theme.AccentText
        end
    end

    TabStickers.MouseButton1Click:Connect(function() ShowStickerTab("stickers") end)
    TabMisStickers.MouseButton1Click:Connect(function() ShowStickerTab("mis") end)

    PanelClose.MouseButton1Click:Connect(function()
        StickerPanel.Visible = false
        AddStickerInput.Visible = false
        ConfirmAddBtn.Visible = false
    end)

    AddStickerBtn.MouseButton1Click:Connect(function()
        AddStickerInput.Visible = not AddStickerInput.Visible
        ConfirmAddBtn.Visible = not ConfirmAddBtn.Visible
    end)

    ConfirmAddBtn.MouseButton1Click:Connect(function()
        local newId = AddStickerInput.Text:match("^%s*(.-)%s*$")
        if newId == "" then return end
        if not newId:find("rbxassetid://") then
            newId = "rbxassetid://" .. newId
        end
        table.insert(CustomStickers, {id = newId, name = "Custom"})
        SaveCustomStickers()
        CreateStickerBtn(MisStickerGrid, newId, true)
        AddStickerInput.Text = ""
        AddStickerInput.Visible = false
        ConfirmAddBtn.Visible = false
    end)

    StickerButton.MouseButton1Click:Connect(function()
        StickerPanel.Visible = not StickerPanel.Visible
        if StickerPanel.Visible then
            ShowStickerTab("stickers")
        end
    end)

    MessageInput.FocusLost:Connect(function(enterPressed)
    	if enterPressed then
    		SendMessage()
    	end
    end)

    function Window:SendChatMessage(text)
    	MessageInput.Text = tostring(text or ""):sub(1, MAX_CHAR)
    	SendMessage()
    end

    function Window:GetChatHistory()
    	return GetChatHistory()
    end

    function Window:ReceiveMessage(playerName, userId, message)
    	local timestamp = os.date("%H:%M:%S")
    	AddChatMessage(playerName, userId, message, timestamp)
    	RenderMessage(playerName, userId, message, timestamp, false)
    end

    Window.ChatMessages = ChatMessages
    Window.ChatRoot = ChatRoot
    Window.ChatContainer = ChatContainer
    Window.ChatFooter = ChatFooter
    Window.MessageInput = MessageInput
    Window.SendButton = SendButton
    Window.CharLabel = CharLabel
    Window.AddChatMessage = AddChatMessage
    Window.RenderChatMessage = RenderMessage
    Window.SendMessage = SendMessage

    --// Iniciar sincronización en tiempo real con el backend
    --// Cada mensaje nuevo de OTRO jugador se agrega y renderiza automáticamente
    StartBackendPolling(function(msg)
        AddChatMessage(msg.playerName, msg.playerId, msg.message, os.date("%H:%M:%S", msg.timestamp))
        RenderMessage(msg.playerName, msg.playerId, msg.message, os.date("%H:%M:%S", msg.timestamp), false)
    end)

    --// ════════════════════════════════════════════════════════════════
    --// UPDATE LOOP — Cambio instantáneo de idioma (v28 PRO)
    --// Detecta cambios en LanguageSystem.CurrentLanguage y actualiza
    --// TODOS los elementos que tengan atributos TextSpanish/TextEnglish
    --// ════════════════════════════════════════════════════════════════
    local lastLanguage = LanguageSystem.CurrentLanguage
    RunService.Heartbeat:Connect(function()
        local currentLang = LanguageSystem.CurrentLanguage
        if currentLang == lastLanguage then return end
        lastLanguage = currentLang

        for _, tabData in ipairs(Window.Tabs) do
            --// Actualizar el botón de la tab (nombre)
            if tabData.Button then
                for _, child in ipairs(tabData.Button:GetChildren()) do
                    if child:IsA("TextLabel") then
                        local sp = child:GetAttribute("TextSpanish")
                        local en = child:GetAttribute("TextEnglish")
                        if sp and en then
                            child.Text = GetText(sp, en)
                        end
                    end
                end
            end

            --// Actualizar TODOS los descendientes de la página
            if tabData.Page then
                for _, el in ipairs(tabData.Page:GetDescendants()) do
                    if el:IsA("TextLabel") or el:IsA("TextButton") then
                        local sp = el:GetAttribute("TextSpanish")
                        local en = el:GetAttribute("TextEnglish")
                        if sp and en then
                            el.Text = GetText(sp, en)
                        end
                    end
                end
            end
        end
    end)

    --// ════════════════════════════════════════════════════════════════
    --// TAB: CRÉDITOS (todo en una pantalla, sin scroll)
    --// ════════════════════════════════════════════════════════════════
    local TabCreditos = Window:CreateTab("Créditos", "Credits", "rbxassetid://72420970081590")
    local CredPage = TabCreditos.Page

    CredPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    CredPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    CredPage.ScrollBarThickness = 2
    CredPage.ScrollingEnabled = true

    local CB  = Theme.Background
    local CC  = Theme.Secondary
    local CW  = Theme.Text
    local CG  = Theme.TextDim
    local CDG = Theme.Stroke
    local CGR = Color3.fromRGB(80, 210, 100)
    local CS  = Theme.Stroke

    -- Frame principal opaco que cubre TODO el fondo
    --// CredPage necesita fondo opaco para tapar el BackgroundArt del tema
    CredPage.BackgroundColor3 = CB
    CredPage.BackgroundTransparency = 0

    local CredRoot = mk("Frame", {
        Parent = CredPage,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = CB,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 10,
        AutomaticSize = Enum.AutomaticSize.Y,
    })

    mk("UIListLayout", {
        Parent = CredRoot,
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    })

    mk("UIPadding", {
        Parent = CredRoot,
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 8),
    })

    --// HEADER (84px)
    local CR_Header = mk("Frame", {
        Parent = CredRoot,
        Size = UDim2.new(1, 0, 0, 84),
        BackgroundColor3 = CC,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        LayoutOrder = 1, ZIndex = 10,
    })
    corner(CR_Header, 10)
    mk("UIStroke", { Parent = CR_Header, Thickness = 1, Color = CS })

    local CR_BackImg = mk("ImageLabel", {
        Parent = CR_Header,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://125311226076728",
        ImageTransparency = 0.55,
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 10,
    })
    corner(CR_BackImg, 10)

    local CR_Overlay = mk("Frame", {
        Parent = CR_Header,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = CC,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    corner(CR_Overlay, 10)

    local CR_TitleLabel = mk("TextLabel", {
        Parent = CR_Header, Size = UDim2.new(0.6, 0, 0, 28),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1, Text = GetText("Créditos", "Credits"),
        Font = Enum.Font.GothamBold, TextSize = 22,
        TextColor3 = CW, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13,
    })
    CR_TitleLabel:SetAttribute("TextSpanish", "Créditos")
    CR_TitleLabel:SetAttribute("TextEnglish", "Credits")

    mk("Frame", {
        Parent = CR_Header, Size = UDim2.new(0, 48, 0, 2),
        Position = UDim2.new(0, 12, 0, 38),
        BackgroundColor3 = CW, BorderSizePixel = 0, ZIndex = 13,
    })

    local CR_SubLabel = mk("TextLabel", {
        Parent = CR_Header, Size = UDim2.new(0.55, 0, 0, 36),
        Position = UDim2.new(0, 12, 0, 44),
        BackgroundTransparency = 1,
        Text = GetText("Gracias por usar Yin Yang v28.\nHecho con dedicación para la comunidad.",
                       "Thank you for using Yin Yang v28.\nMade with dedication for the community."),
        Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = CG, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 13,
    })
    CR_SubLabel:SetAttribute("TextSpanish", "Gracias por usar Yin Yang v28.\nHecho con dedicación para la comunidad.")
    CR_SubLabel:SetAttribute("TextEnglish", "Thank you for using Yin Yang v28.\nMade with dedication for the community.")

    mk("ImageLabel", {
        Parent = CR_Header, Size = UDim2.new(0, 82, 0, 82),
        Position = UDim2.new(1, -88, 0, 1),
        BackgroundTransparency = 1, Image = "rbxassetid://117780544348814",
        ScaleType = Enum.ScaleType.Fit, ZIndex = 14,
    })

    --// LABEL DESARROLLADOR (18px)
    local CR_DevLbl = mk("Frame", {
        Parent = CredRoot, Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1, LayoutOrder = 2, ZIndex = 10,
    })
    mk("ImageLabel", {
        Parent = CR_DevLbl, Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 2, 0.5, -7),
        BackgroundTransparency = 1, Image = "rbxassetid://131335187671764",
        ImageColor3 = CG, ScaleType = Enum.ScaleType.Fit, ZIndex = 11,
    })
    local CR_DevLblText = mk("TextLabel", {
        Parent = CR_DevLbl, Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.new(0, 22, 0, 0),
        BackgroundTransparency = 1, Text = GetText("Desarrollador", "Developer"),
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = CG, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11,
    })
    CR_DevLblText:SetAttribute("TextSpanish", "Desarrollador")
    CR_DevLblText:SetAttribute("TextEnglish", "Developer")

    --// CARD DEV (82px)
    local CR_DevCard = mk("Frame", {
        Parent = CredRoot, Size = UDim2.new(1, 0, 0, 82),
        BackgroundColor3 = CC, BackgroundTransparency = 0,
        BorderSizePixel = 0, LayoutOrder = 3, ZIndex = 10,
    })
    corner(CR_DevCard, 10)
    mk("UIStroke", { Parent = CR_DevCard, Thickness = 1, Color = CS })

    local CR_Avatar = mk("ImageLabel", {
        Parent = CR_DevCard, Size = UDim2.new(0, 64, 0, 64),
        Position = UDim2.new(0, 12, 0.5, -32),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BorderSizePixel = 0, Image = "rbxassetid://125311226076728",
        ScaleType = Enum.ScaleType.Crop, ZIndex = 11,
    })
    corner(CR_Avatar, 8)
    mk("UIStroke", { Parent = CR_Avatar, Thickness = 1, Color = CS })

    mk("Frame", {
        Parent = CR_DevCard, Size = UDim2.new(0, 1, 0, 58),
        Position = UDim2.new(0, 88, 0.5, -29),
        BackgroundColor3 = CS, BorderSizePixel = 0, ZIndex = 11,
    })

    mk("TextLabel", {
        Parent = CR_DevCard, Size = UDim2.new(1, -102, 0, 22),
        Position = UDim2.new(0, 98, 0, 10),
        BackgroundTransparency = 1, Text = "Nick",
        Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = CW, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11,
    })
    local CR_DevRole = mk("TextLabel", {
        Parent = CR_DevCard, Size = UDim2.new(1, -102, 0, 16),
        Position = UDim2.new(0, 98, 0, 33),
        BackgroundTransparency = 1, Text = GetText("Desarrollador Principal", "Lead Developer"),
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = CG, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11,
    })
    CR_DevRole:SetAttribute("TextSpanish", "Desarrollador Principal")
    CR_DevRole:SetAttribute("TextEnglish", "Lead Developer")

    local CR_DevDesc = mk("TextLabel", {
        Parent = CR_DevCard, Size = UDim2.new(1, -102, 0, 28),
        Position = UDim2.new(0, 98, 0, 50),
        BackgroundTransparency = 1,
        Text = GetText("Creador de Yin Yang v28\nApasionado por la programación y la comunidad.",
                       "Creator of Yin Yang v28\nPassionate about programming and the community."),
        Font = Enum.Font.Gotham, TextSize = 10,
        TextColor3 = CDG, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, ZIndex = 11,
    })
    CR_DevDesc:SetAttribute("TextSpanish", "Creador de Yin Yang v28\nApasionado por la programación y la comunidad.")
    CR_DevDesc:SetAttribute("TextEnglish", "Creator of Yin Yang v28\nPassionate about programming and the community.")

    --// CARD DISCORD (86px)
    local CR_DC = mk("Frame", {
        Parent = CredRoot, Size = UDim2.new(1, 0, 0, 86),
        BackgroundColor3 = CC, BackgroundTransparency = 0,
        BorderSizePixel = 0, LayoutOrder = 4, ZIndex = 10,
    })
    corner(CR_DC, 10)
    mk("UIStroke", { Parent = CR_DC, Thickness = 1, Color = CS })

    mk("ImageLabel", {
        Parent = CR_DC, Size = UDim2.new(0, 19, 0, 19),
        Position = UDim2.new(0, 12, 0, 10),
        BackgroundTransparency = 1, Image = "rbxassetid://132202203337109",
        ImageColor3 = CW, ScaleType = Enum.ScaleType.Fit, ZIndex = 11,
    })
    local CR_DCTitle = mk("TextLabel", {
        Parent = CR_DC, Size = UDim2.new(1, -42, 0, 20),
        Position = UDim2.new(0, 37, 0, 9),
        BackgroundTransparency = 1, Text = GetText("Únete a nuestro Discord", "Join our Discord"),
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = CW, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11,
    })
    CR_DCTitle:SetAttribute("TextSpanish", "Únete a nuestro Discord")
    CR_DCTitle:SetAttribute("TextEnglish", "Join our Discord")

    mk("Frame", {
        Parent = CR_DC, Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 0, 33),
        BackgroundColor3 = CS, BorderSizePixel = 0, ZIndex = 11,
    })

    local CR_DCDesc = mk("TextLabel", {
        Parent = CR_DC, Size = UDim2.new(0.5, 0, 0, 44),
        Position = UDim2.new(0, 12, 0, 38),
        BackgroundTransparency = 1,
        Text = GetText("Forma parte de nuestra comunidad para recibir soporte, actualizaciones y mucho más.",
                       "Join our community to receive support, updates and much more."),
        Font = Enum.Font.Gotham, TextSize = 10,
        TextColor3 = CG, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, ZIndex = 11,
    })
    CR_DCDesc:SetAttribute("TextSpanish", "Forma parte de nuestra comunidad para recibir soporte, actualizaciones y mucho más.")
    CR_DCDesc:SetAttribute("TextEnglish", "Join our community to receive support, updates and much more.")

    local CR_CopyBtn = mk("TextButton", {
        Parent = CR_DC, Size = UDim2.new(0, 106, 0, 38),
        Position = UDim2.new(1, -118, 0.5, -4),
        BackgroundColor3 = Color3.fromRGB(12, 12, 15),
        BackgroundTransparency = 0, BorderSizePixel = 0,
        Text = "", ZIndex = 12,
    })
    corner(CR_CopyBtn, 19)
    mk("UIStroke", { Parent = CR_CopyBtn, Thickness = 1.5, Color = CW })
    mk("ImageLabel", {
        Parent = CR_CopyBtn, Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 10, 0.5, -8),
        BackgroundTransparency = 1, Image = "rbxassetid://127734233169485",
        ImageColor3 = CW, ScaleType = Enum.ScaleType.Fit, ZIndex = 13,
    })
    local CR_CopyLabel = mk("TextLabel", {
        Parent = CR_CopyBtn, Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1, Text = GetText("Copiar", "Copy"),
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = CW, ZIndex = 13,
    })
    CR_CopyLabel:SetAttribute("TextSpanish", "Copiar")
    CR_CopyLabel:SetAttribute("TextEnglish", "Copy")

    local CR_Copied = mk("TextLabel", {
        Parent = CR_DC, Size = UDim2.new(0, 148, 0, 13),
        Position = UDim2.new(1, -158, 1, -15),
        BackgroundTransparency = 1, Text = "",
        Font = Enum.Font.Gotham, TextSize = 10,
        TextColor3 = CGR, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 12,
    })

    CR_CopyBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard("https://discord.gg/KAtgYysjp") end)
        CR_Copied.Text = GetText("✓ Link copiado al portapapeles", "✓ Link copied to clipboard")
        task.delay(3, function()
            if CR_Copied and CR_Copied.Parent then CR_Copied.Text = "" end
        end)
    end)

    --// FOOTER (28px)
    local CR_Footer = mk("Frame", {
        Parent = CredRoot, Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1, LayoutOrder = 5, ZIndex = 10,
    })

    mk("Frame", {
        Parent = CR_Footer, Size = UDim2.new(0.38, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 8),
        BackgroundColor3 = CS, BorderSizePixel = 0, ZIndex = 11,
    })
    mk("Frame", {
        Parent = CR_Footer, Size = UDim2.new(0.38, 0, 0, 1),
        Position = UDim2.new(0.62, 0, 0, 8),
        BackgroundColor3 = CS, BorderSizePixel = 0, ZIndex = 11,
    })
    mk("ImageLabel", {
        Parent = CR_Footer, Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0.5, -7, 0, 1),
        BackgroundTransparency = 1, Image = "rbxassetid://132202203337109",
        ImageColor3 = CDG, ScaleType = Enum.ScaleType.Fit, ZIndex = 12,
    })
    local CR_FooterText = mk("TextLabel", {
        Parent = CR_Footer, Size = UDim2.new(1, 0, 0, 13),
        Position = UDim2.new(0, 0, 0, 15),
        BackgroundTransparency = 1,
        Text = GetText("© 2026 Yin Yang | Script Hub  •  Todos los derechos reservados.",
                       "© 2026 Yin Yang | Script Hub  •  All rights reserved."),
        Font = Enum.Font.Gotham, TextSize = 9,
        TextColor3 = CDG, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 11,
    })
    CR_FooterText:SetAttribute("TextSpanish", "© 2026 Yin Yang | Script Hub  •  Todos los derechos reservados.")
    CR_FooterText:SetAttribute("TextEnglish", "© 2026 Yin Yang | Script Hub  •  All rights reserved.")

    return Window

end

--// ============================================================
--// LIBRERÍA GLOBAL - LISTA PARA USAR
--// ============================================================
--// YinYang es accesible globalmente como _G.YinYang
--// Uso desde otros scripts:
--//
--// local YinYang = _G.YinYang
--// local UI = YinYang:CreateWindow("Mi UI", "Dark")
--// local Tab = UI:CreateTab("Inicio")
--// Tab:CreateWelcomeCard()
--// Tab:CreateServerInfoCard()
--// Tab:CreateButton("Mi Botón", function() print("Click!") end)
--// Tab:CreateToggle("Toggle", false, function(state) print(state) end)
--// Tab:CreateDropdown("Category", {"Op1", "Op2"}, "Op1", function(val) print(val) end)
--// Tab:CreateMultiDropdown("Blacklist", {"A", "B", "C"}, {}, function(tbl) print(table.concat(tbl, ",")) end)
--//
--// ============================================================

print(" Yin Yang v24 CON TEMA CAT V1  - ¡Librería cargada y lista para usar!")

--// ============================================================
--// DEMO VISUAL - MUESTRA TODAS LAS CARACTERÍSTICAS
--// ============================================================
--// INSTRUCCIONES:
--// - Para ACTIVAR la demo: Cambia "DEMO_ACTIVO" a true
--// - Para DESACTIVAR: Cambia "DEMO_ACTIVO" a false
--// ============================================================

local DEMO_ACTIVO = false  -- Demo desactivada para usar la librería desde otro script

if DEMO_ACTIVO then
    task.wait(0.5)
    
    print("\n" .. string.rep("=", 60))
    print("INICIANDO DEMO VISUAL DE YIN YANG v24 - LIBRERÍA PROFESIONAL")
    print(string.rep("=", 60))
    
    --// 💾 v26: CARGAR CONFIGURACIÓN GUARDADA AL INICIAR
    local ConfigCargada = LoadConfig()
    local TemaInicial = "Dark"
    if ConfigCargada and ConfigCargada.theme then
        TemaInicial = ConfigCargada.theme
    end
    if ConfigCargada and ConfigCargada.lang then
        LanguageSystem.CurrentLanguage = ConfigCargada.lang
    end

    local DemoUI = _G.YinYang:CreateWindow("Yin Yang - DEMO v26", TemaInicial)
    
    --//  APLICAR TEMA GUARDADO - Re-pinta TODOS los colores, no solo la variable
    DemoUI:SetTheme(TemaInicial)
    
    -- =========================================================
    -- TAB INICIO (PROTEGIDA Y PERMANENTE)
    -- =========================================================
    local TabFeatures = DemoUI:CreateTab("Features")
    
    TabFeatures:CreateLabel("Toggles Flotantes", 14)
    TabFeatures:CreateDivider()
    
    TabFeatures:CreateFloatingToggle("Aimbot", false, function(state)
        print("Aimbot: " .. (state and "ON" or "OFF"))
    end)
    
    TabFeatures:CreateFloatingToggle("ESP", false, function(state)
        print("ESP: " .. (state and "ON" or "OFF"))
    end)
    
    TabFeatures:CreateFloatingToggle("GodMode", false, function(state)
        print("GodMode: " .. (state and "ON" or "OFF"))
    end)

    --// ========================================================
    --// SECCIÓN: SLIDERS PREMIUM v2.0 (TESTING & SHOWCASE)
    --// ========================================================
    TabFeatures:CreateDivider()
    TabFeatures:CreateLabel("Sliders Premium v2.0 🚀", 14)
    TabFeatures:CreateDivider()

    --// SLIDER 1: TELEPORT SPEED
    local SliderTeleportSpeed = TabFeatures:CreateSlider("Teleport Speed", 1.0, 100.0, 23.1, function(val)
        print("🚀 Teleport Speed: " .. string.format("%.2f", val))
    end)

    --// SLIDER 2: JUMP HEIGHT
    local SliderJumpHeight = TabFeatures:CreateSlider("Jump Height", 10.0, 300.0, 139.24, function(val)
        print("⬆️  Jump Height: " .. string.format("%.2f", val))
    end)

    --// SLIDER 3: SPEED MULTIPLIER
    local SliderSpeed = TabFeatures:CreateSlider("Speed Multiplier", 0.5, 3.0, 1.5, function(val)
        print("💨 Speed: " .. string.format("%.2f", val) .. "x")
    end)

    --// SLIDER 4: FOV (Field of View)
    local SliderFOV = TabFeatures:CreateSlider("FOV", 30, 120, 70, function(val)
        print("👁️  FOV: " .. string.format("%.0f", val))
    end)

    --// SLIDER 5: VOLUME
    local SliderVolume = TabFeatures:CreateSlider("Volume", 0, 1.0, 0.5, function(val)
        print("🔊 Volume: " .. string.format("%.1f%%", val * 100))
    end)

    print("\n DEMO v24 INICIADA")
    print("TABS: Inicio (Protegida) | Temas (16 colores sin duplicados) | Features | Dropdowns | Efectos")
    print(" MEJORAS: Sin duplicados, Pestañas permanentes, Efectos de texto mejorados")
    print("Para desactivar la demo, cambia DEMO_ACTIVO a false\n")
    print(string.rep("=", 60) .. "\n")
    
    -- Aplicar efecto Rainbow al tema cargado
    task.wait(0.2)
    DemoUI:SetTextEffect("Rainbow")
    print(" Efecto: " .. TemaInicial .. " + Rainbow (Yin-Yang Theme)")
else
    print("Yin Yang v24 - DEMO DESACTIVADA (DEMO_ACTIVO = false)")
    print("Solo la librería está cargada y lista para usar")
end

--// ============================================================
--// FIN DE LA DEMO
--// ============================================================
