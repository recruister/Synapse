
-- ═══════════════════════════════════════════════════════════
-- AIRFLOW LOADER (безопасный патч)
-- ═══════════════════════════════════════════════════════════

if delfile then
    pcall(delfile, "Synapse/Airflow_patched.luau")
    pcall(delfile, "Synapse/Airflow.luau")
end

-- ═══════════════════════════════════════════════════════════
-- 1. ЗАГРУЗКА AIRFLOW
-- ═══════════════════════════════════════════════════════════
local Airflow
local URL = "https://raw.githubusercontent.com/recruister/AFUFS/refs/heads/main/Source.lua"

if isfile and isfile("Synapse/Airflow.luau") and readfile then
    local ok, cached = pcall(readfile, "Synapse/Airflow.luau")
    if ok and cached and #cached > 1000 then
        Airflow = loadstring(cached)()
        print("[Airflow] Загружен из кэша")
    end
end
if not Airflow then
    local src = game:HttpGet(URL)
    if writefile and makefolder then
        if not isfolder("Synapse") then makefolder("Synapse") end
        pcall(writefile, "Synapse/Airflow.luau", src)
    end
    Airflow = loadstring(src)()
    print("[Airflow] Загружен с GitHub")
end

-- ═══════════════════════════════════════════════════════════
-- 2. CLEANUP REGISTRY
-- ═══════════════════════════════════════════════════════════
local CleanupRegistry = {}

local function RegisterCleanup(name, fn)
    table.insert(CleanupRegistry, {Name = name, Fn = fn})
end

	

local function RunAllCleanups()
    print("[Synapse] Cleanup start, functions: " .. #CleanupRegistry)
    for _, entry in ipairs(CleanupRegistry) do
        local ok, err = pcall(entry.Fn)
        if not ok then
            warn("[Synapse] Cleanup error for " .. entry.Name .. ": " .. tostring(err))
        end
    end
    print("[Synapse] Cleanup complete")
end

-- ═══════════════════════════════════════════════════════════
-- 3. СОЗДАНИЕ ОКНА
-- ═══════════════════════════════════════════════════════════
local Window = Airflow:Window({
    Name = "Synapse",
    Subtitle = "v1.2",
    Keybind = Enum.KeyCode.RightShift,
    Size = UDim2.fromOffset(640, 480),
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AirflowUI",
        FileName = "Synapse"
    }
})

-- ═══════════════════════════════════════════════════════════
-- 4. СВОБОДНАЯ МЫШЬ ПРИ ОТКРЫТОМ МЕНЮ
-- ═══════════════════════════════════════════════════════════
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ContextActionService = game:GetService("ContextActionService")

_G.NL_MouseUnlockConn = nil

local function SetMenuMouseState(isOpen)
    if isOpen then
        -- Меню открыто — мышь свободна
        pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
        pcall(function() UserInputService.MouseIconEnabled = true end)
        
        if not _G.NL_MouseUnlockConn then
            _G.NL_MouseUnlockConn = RunService.RenderStepped:Connect(function()
                pcall(function()
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end)
            end)
        end
    else
        -- Меню закрыто — мышь скрыта, камера крутится
        if _G.NL_MouseUnlockConn then
            _G.NL_MouseUnlockConn:Disconnect()
            _G.NL_MouseUnlockConn = nil
        end
        pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end)
        pcall(function() UserInputService.MouseIconEnabled = false end)
    end
end

-- Следим за состоянием окна
task.spawn(function()
    local lastState = Window.Open
    while task.wait(0.1) do
        if Window.Open ~= lastState then
            lastState = Window.Open
            SetMenuMouseState(lastState)
        end
    end
end)

SetMenuMouseState(Window.Open)

RegisterCleanup("Mouse", function()
    if _G.NL_MouseUnlockConn then
        _G.NL_MouseUnlockConn:Disconnect()
        _G.NL_MouseUnlockConn = nil
    end
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end)
end)

-- ═══════════════════════════════════════════════════════════
-- 5. ТАБЫ
-- ═══════════════════════════════════════════════════════════
local InfoTab     = Window:Tab({Name = "Info"})
local ExploitsTab = Window:Tab({Name = "Exploits"})

-- ═══════════════════════════════════════════════════════════
-- EXPLOITS → PLAYER
-- ═══════════════════════════════════════════════════════════
ExploitsTab:Section({Name = "Player"})

-- ═══ SPEED BOOST ═══
local OriginalWalkSpeed = 16
local SpeedValue = 0          -- значение ползунка (НЕ управляет биндом)
local SpeedEnabled = false    -- управляется ТОЛЬКО биндом B

pcall(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then OriginalWalkSpeed = hum.WalkSpeed end
end)

local function GetHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- Применяем скорость если биnd включён
RunService.RenderStepped:Connect(function()
    if not SpeedEnabled then return end
    if SpeedValue <= 0 then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local target = OriginalWalkSpeed + SpeedValue
    hum.WalkSpeed = target
    if hum.MoveDirection.Magnitude < 0.1 then return end
    local md = hum.MoveDirection
    local tv = Vector3.new(md.X, 0, md.Z).Unit * target
    hrp.AssemblyLinearVelocity = Vector3.new(tv.X, hrp.AssemblyLinearVelocity.Y, tv.Z)
end)

ExploitsTab:Slider({
    Name = "Speed Boost",
	Flag = "SpeedBoostValue",
    Min = 0, Max = 100, Default = 0, Step = 1, Suffix = "",
    Callback = function(value)
        SpeedValue = value
    end,
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    local hum = GetHumanoid()
    if hum and OriginalWalkSpeed == 16 then OriginalWalkSpeed = hum.WalkSpeed end
end)

RegisterCleanup("Speed", function()
    SpeedEnabled = false
    SpeedValue = 0
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = OriginalWalkSpeed end
end)

-- ═══ NOCLIP ═══
local NoclipEnabled = false
local NoclipToggle = nil
local SavedCollisions = {}

local function ApplyNoclipCollision()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- Сохраняем ОРИГИНАЛ перед включением
local function SaveCollisions()
    SavedCollisions = {}
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            SavedCollisions[part] = part.CanCollide
        end
    end
end

-- Восстанавливаем из сохранённых
local function RestoreCollisions()
    if next(SavedCollisions) then
        for part, value in pairs(SavedCollisions) do
            if part and part.Parent then
                part.CanCollide = value
            end
        end
        SavedCollisions = {}
    else
        -- Fallback: если нет сохранённых — восстанавливаем "по имени"
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = (part.Name ~= "HumanoidRootPart")
            end
        end
    end
end

local function SetNoclip(value, fromUI)
    -- ⚠️ Никаких `return if syncing` — флаг может зависнуть
    local wasEnabled = NoclipEnabled
    if wasEnabled == value and not fromUI then return end
    NoclipEnabled = value
    
    if value then
        if not next(SavedCollisions) then SaveCollisions() end
        ApplyNoclipCollision()
    else
        RestoreCollisions()
    end
    
    -- Keybind list
    if KeybindRegistry and KeybindRegistry["Noclip"] then
        KeybindRegistry["Noclip"].State = value
        if RefreshKeybindList then RefreshKeybindList() end
    end
    
    -- Синхронизация toggle — через spawn, БЕЗ блокировки
    if not fromUI and NoclipToggle then
        task.spawn(function()
            local methods = {"Set", "SetValue", "Update", "UpdateValue", "SetState"}
            for _, m in ipairs(methods) do
                if NoclipToggle[m] then
                    pcall(function() NoclipToggle[m](NoclipToggle, value) end)
                    break
                end
            end
        end)
    end
end

-- Цикл: держит false пока включено
RunService.Stepped:Connect(function()
    if not NoclipEnabled then return end
    ApplyNoclipCollision()
end)

LocalPlayer.CharacterAdded:Connect(function()
    SavedCollisions = {}
    task.wait(0.5)
    if NoclipEnabled then
        SaveCollisions()
        ApplyNoclipCollision()
    end
end)

NoclipToggle = ExploitsTab:Toggle({
    Name = "Noclip",
    Desc = "Проход сквозь стены",
	Flag = "Noclip",
    Default = false,
    Callback = function(value)
        SetNoclip(value, true)
    end,
})

RegisterCleanup("Noclip", function()
    NoclipEnabled = false
    RestoreCollisions()
    SavedCollisions = {}
end)

-- ═══ JUMP FEATURES ═══
local InfinityJumpEnabled = false
local InfinityJumpToggle = nil
local AllowJumpEnabled = false
local AllowJumpToggle = nil
local JumpConn = nil
local SitBlockConn = nil
local SitHeartbeatConn = nil
local SitChangedConn = nil
local SeatedConn = nil
local SitGuard = false

-- ═══ В воздухе? ═══
local function IsInAir(hum)
    local state = hum:GetState()
    return state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.FallingDown
        or state == Enum.HumanoidStateType.PlatformStanding
end

-- ═══ МОМЕНТАЛЬНЫЙ перехват ═══
local function HookSitProtection(hum)
    if not hum then return end
    if SitChangedConn then SitChangedConn:Disconnect() end
    if SeatedConn then SeatedConn:Disconnect() end

    -- 1) Ловим момент когда Sit становится true
    SitChangedConn = hum:GetPropertyChangedSignal("Sit"):Connect(function()
        if SitGuard then return end
        if not AllowJumpEnabled then return end
        if hum.Sit and IsInAir(hum) then
            SitGuard = true
            hum.Sit = false
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end)
            SitGuard = false
        end
    end)

    -- 2) Ловим событие Seated
    SeatedConn = hum.Seated:Connect(function(active, _)
        if not AllowJumpEnabled then return end
        if active and IsInAir(hum) then
            hum.Sit = false
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Freefall)
            end)
        end
    end)
end

local function ApplyHooks()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then HookSitProtection(hum) end
end

ApplyHooks()
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    HookSitProtection(hum)
end)

-- ═══ RenderStepped (перед физикой) ═══
SitBlockConn = RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if AllowJumpEnabled then
        if not hum.UseJumpPower then
            hum.UseJumpPower = true
            hum.JumpPower = 50
        end
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
    else
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end)
    end

    -- Только в воздухе
    if IsInAir(hum) then
        if hum.Sit then hum.Sit = false end
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)
    else
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
    end
end)

-- ═══ Heartbeat (после физики — добиваем то что проскочило) ═══
SitHeartbeatConn = RunService.Heartbeat:Connect(function()
    if not AllowJumpEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum.Sit and IsInAir(hum) then
        hum.Sit = false
    end
end)

-- ═══ Пробел ═══
JumpConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode ~= Enum.KeyCode.Space then return end
    if gameProcessed then return end
    if not AllowJumpEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if hum.Sit then hum.Sit = false end

    local state = hum:GetState()
    local onGround = (state == Enum.HumanoidStateType.Running
                      or state == Enum.HumanoidStateType.Landed
                      or state == Enum.HumanoidStateType.RunningNoPhysics)

    if onGround then
        -- На земле — обычный прыжок
        hum.Jump = true
    elseif InfinityJumpEnabled then
        -- В воздухе + Infinity — velocity-толчок
        local jumpPower = hum.JumpPower > 0 and hum.JumpPower or 50
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X,
            jumpPower,
            hrp.AssemblyLinearVelocity.Z
        )
    end
end)

-- ═══ Allow Jump ═══
AllowJumpToggle = ExploitsTab:Toggle({
    Name = "Allow Jump",
	Flag = "AllowJump",
    Desc = "Разрешить прыжки (выкл — прыгать нельзя, садиться можно)",
    Default = false,
    Callback = function(value)
        AllowJumpEnabled = value
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if value then
                    hum.UseJumpPower = true
                    hum.JumpPower = 50
                    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
                else
                    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end)
                end
            end
        end
        if KeybindRegistry and KeybindRegistry["AllowJump"] then
            KeybindRegistry["AllowJump"].State = value
            if RefreshKeybindList then RefreshKeybindList() end
        end
    end,
})

-- ═══ Infinity Jump ═══
InfinityJumpToggle = ExploitsTab:Toggle({
    Name = "Infinity Jump",
    Desc = "Прыжки в воздухе (нужен Allow Jump)",
	Flag = "InfinityJump",
    Default = false,
    Callback = function(value)
        InfinityJumpEnabled = value
        if KeybindRegistry and KeybindRegistry["InfinityJump"] then
            KeybindRegistry["InfinityJump"].State = value
            if RefreshKeybindList then RefreshKeybindList() end
        end
    end,
})

RegisterCleanup("JumpFeatures", function()
    AllowJumpEnabled = false
    InfinityJumpEnabled = false
    SitGuard = false
    if JumpConn then JumpConn:Disconnect() JumpConn = nil end
    if SitBlockConn then SitBlockConn:Disconnect() SitBlockConn = nil end
    if SitHeartbeatConn then SitHeartbeatConn:Disconnect() SitHeartbeatConn = nil end
    if SitChangedConn then SitChangedConn:Disconnect() SitChangedConn = nil end
    if SeatedConn then SeatedConn:Disconnect() SeatedConn = nil end
    -- Сбрасываем toggle в UI
    if AllowJumpToggle then
        pcall(function() AllowJumpToggle:Set(false) end)
        pcall(function() AllowJumpToggle:SetValue(false) end)
    end
    if InfinityJumpToggle then
        pcall(function() InfinityJumpToggle:Set(false) end)
        pcall(function() InfinityJumpToggle:SetValue(false) end)
    end
    -- Восстанавливаем Humanoid
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            -- НЕ трогаем Jumping — Pressure сам управляет
            -- Только снимаем Sit если был
            if hum.Sit then hum.Sit = false end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- EXPLOITS → AUTOMATION
-- ═══════════════════════════════════════════════════════════
ExploitsTab:Section({Name = "Automation"})

local AutoCodeEnter_Enabled = false
local AutoCodeEnter_Conn = nil
local LastEnteredCode = nil
local LastEnteredDoor = nil

-- ═══ Кэш кодов: door → code (чтобы не читать каждый раз) ═══
local DoorCodeCache = {}

-- ═══ Читаем код с бумаги ═══
local function ExtractPaperCode(paper)
    if not paper then return nil end
    -- Ищем Code.SurfaceGui.TextLabel
    local code = paper:FindFirstChild("Code", true)
    if code then
        local sg = code:FindFirstChildWhichIsA("SurfaceGui", true)
        if sg then
            local lbl = sg:FindFirstChildWhichIsA("TextLabel", true)
            if lbl and lbl.Text then
                local t = lbl.Text:match("^%d+$")
                if t then return t end
            end
        end
    end
    -- Fallback: любой SurfaceGui с 3-6 цифрами
    for _, d in ipairs(paper:GetDescendants()) do
        if d:IsA("SurfaceGui") then
            local lbl = d:FindFirstChildWhichIsA("TextLabel", true)
            if lbl and lbl.Text then
                local t = lbl.Text:match("^%d+$")
                if t and #t >= 3 and #t <= 6 then return t end
            end
        end
    end
    return nil
end

-- ═══ Ищем ближайший code paper ═══
local function FindNearestPaper(maxDist)
    maxDist = maxDist or 20
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position

    local nearest, nearestDist = nil, maxDist
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("passwordpaper") then
            local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if pp then
                local dist = (myPos - pp.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

-- ═══ Ищем ближайший Keypad ═══
local function FindNearestKeypad(maxDist)
    maxDist = maxDist or 15
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position

    -- Ищем Lock с детьми Keypad*
    local nearest, nearestDist = nil, maxDist
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Lock" then
            local kp = obj:FindFirstChild("Keypad1")
            if kp then
                local pp = kp:FindFirstChildWhichIsA("BasePart", true)
                if pp then
                    local dist = (myPos - pp.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = obj
                    end
                end
            end
        end
    end
    return nearest, nearestDist
end

-- ═══ Клик по кнопке Keypad через ClickDetector ═══
local function ClickKeypad(keypadPart)
    if not keypadPart then return false end
    local cd = keypadPart:FindFirstChildWhichIsA("ClickDetector", true)
    if cd then
        pcall(function() fireclickdetector(cd) end)
        return true
    end
    return false
end

-- ═══ Получить часть кнопки по цифре ═══
local function GetKeypadPart(lock, digit)
    if not lock then return nil end
    local name = "Keypad" .. tostring(digit)
    return lock:FindFirstChild(name, true)
end

local function GetBackspacePart(lock)
    if not lock then return nil end
    return lock:FindFirstChild("KeypadBackspace", true)
end

-- ═══ Ввод кода в Keypad ═══
local function EnterCodeInKeypad(lock, code)
    if not lock or not code then return false end
    print("[AutoCode] Ввожу код:", code)

    -- Разбиваем на цифры
    local digits = {}
    for i = 1, #code do
        table.insert(digits, code:sub(i, i))
    end

    -- Вводим с задержкой между кнопками
    task.spawn(function()
        for _, d in ipairs(digits) do
            local keypad = GetKeypadPart(lock, d)
            if keypad then
                ClickKeypad(keypad)
                task.wait(0.15)
            end
        end
    end)
    return true
end

-- ═══ Основная логика ═══
local function EnterCodeInKeypad(lock, code)
    if not lock or not code then 
        print("[AutoCode] EnterCodeInKeypad: нет lock/code")
        return false 
    end
    print("[AutoCode] EnterCodeInKeypad старт | Lock:", lock:GetFullName(), "| Code:", code)

    local digits = {}
    for i = 1, #code do
        table.insert(digits, code:sub(i, i))
    end
    print("[AutoCode] Цифры:", table.concat(digits, ","))

    task.spawn(function()
        for _, d in ipairs(digits) do
            local keypad = GetKeypadPart(lock, d)
            print("[AutoCode] Ищу Keypad" .. d .. ":", keypad and keypad:GetFullName() or "НЕ НАЙДЕН")
            if keypad then
                local cd = keypad:FindFirstChildWhichIsA("ClickDetector", true)
                print("[AutoCode] ClickDetector:", cd and cd:GetFullName() or "НЕ НАЙДЕН")
                local ok, err = pcall(function() fireclickdetector(cd) end)
                print("[AutoCode] fireclickdetector:", ok, err or "")
                task.wait(0.15)
            end
        end
    end)
    return true
end

local function TryAutoCode()
    if not AutoCodeEnter_Enabled then return end

    local char = LocalPlayer.Character
    if not char then return end

    local lock, dist = FindNearestKeypad(15)
    print("[AutoCode] Ближайший Lock:", lock and lock:GetFullName() or "НЕТ", "| dist:", dist and math.floor(dist) or "?")
    if not lock then return end
    if dist > 12 then 
        print("[AutoCode] Слишком далеко:", math.floor(dist))
        return 
    end

    if LastEnteredDoor == lock and LastEnteredCode then
        return
    end

    local paper = FindNearestPaper(30)
    print("[AutoCode] Бумага:", paper and paper:GetFullName() or "НЕТ")
    if not paper then return end

    local code = ExtractPaperCode(paper)
    print("[AutoCode] Код с бумаги:", code or "НЕ НАЙДЕН")
    if not code then return end

    LastEnteredDoor = lock
    LastEnteredCode = code

    EnterCodeInKeypad(lock, code)

    pcall(function()
        Window:Notify({
            Title = "AutoCodeEnter",
            Content = "Введён код: " .. code,
            Type = "Success",
            Duration = 3,
        })
    end)
end

AutoCodeEnter_Conn = RunService.Heartbeat:Connect(function()
    if not AutoCodeEnter_Enabled then return end
    pcall(TryAutoCode)
end)

ExploitsTab:Toggle({
    Name = "AutoCodeEnter",
    Desc = "Автоматически вводит код с бумаги в закрытую дверь",
    Default = false,
    Flag = "AutoCodeEnter",   -- для сохранения в конфиг
    Callback = function(value)
        AutoCodeEnter_Enabled = value
        if not value then
            -- Сброс кэша при выключении
            LastEnteredCode = nil
            LastEnteredDoor = nil
        end
    end,
})

RegisterCleanup("AutoCodeEnter", function()
    AutoCodeEnter_Enabled = false
    if AutoCodeEnter_Conn then AutoCodeEnter_Conn:Disconnect() AutoCodeEnter_Conn = nil end
    LastEnteredCode = nil
    LastEnteredDoor = nil
end)

local VisualsTab  = Window:Tab({Name = "Visuals"})
local SettingsTab = Window:Tab({Name = "Settings"})

-- ═══════════════════════════════════════════════════════════
-- KEYBIND SYSTEM
-- ═══════════════════════════════════════════════════════════
local KeybindRegistry = {}
local KeybindGui = nil
local KeybindListEnabled = false
local RebindingId = nil

local function RegisterKeybind(id, name, defaultKey, callback, mode)
    KeybindRegistry[id] = {
        Id = id, Name = name, Key = defaultKey,
        Callback = callback, Mode = mode or "Toggle", State = false,
    }
end

local function RefreshKeybindList()
    if not KeybindGui then return end
    -- Удаляем старые Row
    for _, child in ipairs(KeybindGui:GetChildren()) do
        if child:IsA("Frame") and child.Name == "Row" then child:Destroy() end
    end
    local sorted = {}
    for _, kb in pairs(KeybindRegistry) do table.insert(sorted, kb) end
    table.sort(sorted, function(a, b) return a.Name < b.Name end)

    for i, kb in ipairs(sorted) do
        local row = Instance.new("Frame")
        row.Name = "Row"
        row.Size = UDim2.new(1, 0, 0, 20)
        row.BackgroundTransparency = 1
        row.LayoutOrder = 100 + i
        row.Parent = KeybindGui

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.7, 0, 1, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = kb.Name
        nameLbl.TextColor3 = kb.State and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(200, 200, 210)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextSize = 13
        nameLbl.Font = Enum.Font.Gotham
        nameLbl.Parent = row

        local keyLbl = Instance.new("TextLabel")
        keyLbl.Size = UDim2.new(0.3, 0, 1, 0)
        keyLbl.Position = UDim2.new(0.7, 0, 0, 0)
        keyLbl.BackgroundTransparency = 1
        keyLbl.Text = kb.Key and kb.Key.Name or "?"
        keyLbl.TextColor3 = kb.State and Color3.fromRGB(180, 130, 255) or Color3.fromRGB(150, 150, 160)
        keyLbl.TextXAlignment = Enum.TextXAlignment.Right
        keyLbl.TextSize = 13
        keyLbl.Font = Enum.Font.GothamBold
        keyLbl.Parent = row
    end
end

local function CreateKeybindGui()
    if KeybindGui then return end
    local screen = Instance.new("ScreenGui")
    screen.Name = "Synapse_Keybinds"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.new(0, 200, 0, 0)
    frame.Position = UDim2.new(0, 20, 0, 100)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 60, 120)
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    stroke.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Keybinds"
    title.TextColor3 = Color3.fromRGB(220, 220, 230)
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.LayoutOrder = 0
    title.Parent = frame

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = Color3.fromRGB(60, 50, 80)
    divider.BorderSizePixel = 0
    divider.LayoutOrder = 1
    divider.Parent = frame

    -- Drag только за заголовок
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    KeybindGui = frame
    RefreshKeybindList()
end

local function DestroyKeybindGui()
    if KeybindGui and KeybindGui.Parent then
        KeybindGui.Parent:Destroy()
    end
    KeybindGui = nil
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- ═══ REBIND ═══
    if RebindingId then
        if input.UserInputType == Enum.UserInputType.Keyboard
           and input.KeyCode ~= Enum.KeyCode.Unknown
           and input.KeyCode ~= Enum.KeyCode.RightShift then
            local rebindId = RebindingId
            local kb = KeybindRegistry[rebindId]
            if kb then
                -- Снимаем клавишу с других биндов (защита от дубликатов)
                for _, other in pairs(KeybindRegistry) do
                    if other.Id ~= rebindId and other.Key == input.KeyCode then
                        other.Key = Enum.KeyCode.Unknown
                    end
                end
                kb.Key = input.KeyCode
                RebindingId = nil
                -- Обновляем UI через spawn — не блокируем input loop
                task.spawn(function()
                    RefreshKeybindList()
                    if _G.UpdateRebindDesc then pcall(_G.UpdateRebindDesc, rebindId) end
                end)
                pcall(function()
                    Window:Notify({
                        Title = "Keybind",
                        Content = kb.Name .. " → " .. input.KeyCode.Name,
                        Type = "Success",
                        Duration = 3,
                    })
                end)
            else
                RebindingId = nil
            end
        end
        return
    end
    
    -- ═══ ОБЫЧНЫЕ БИНДЫ ═══
    if gameProcessed then return end
    
    for _, kb in pairs(KeybindRegistry) do
        if kb.Key and kb.Key ~= Enum.KeyCode.Unknown and kb.Key == input.KeyCode then
            if kb.Mode == "Toggle" then
                kb.State = not kb.State
                if kb.Callback then pcall(kb.Callback, kb.State) end
            else
                kb.State = true
                if kb.Callback then pcall(kb.Callback, true) end
            end
            RefreshKeybindList()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- 6. INFO TAB
-- ═══════════════════════════════════════════════════════════
InfoTab:Section({Name = "Player Info"})
InfoTab:Label({Name = "Name: " .. LocalPlayer.Name})
InfoTab:Label({Name = "Display: " .. LocalPlayer.DisplayName})
InfoTab:Label({Name = "User ID: " .. tostring(LocalPlayer.UserId)})

InfoTab:Section({Name = "Executor Info"})
local ExecName = "Unknown"
pcall(function() ExecName = identifyexecutor() end)
InfoTab:Label({Name = "Executor: " .. tostring(ExecName)})

-- ═══════════════════════════════════════════════════════════
-- 7. VISUALS TAB
-- ═══════════════════════════════════════════════════════════
VisualsTab:Section({Name = "Main"})

-- ═══ FOV ═══
local OriginalFOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
local DesiredFOV = OriginalFOV
local FOVForceConn = nil

VisualsTab:Slider({
    Name = "FOV",
	Flag = "FOV",
    Min = 70,
    Max = 120,
    Default = OriginalFOV,
    Step = 1,
    Callback = function(value)
        DesiredFOV = value
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = value
        end
    end
})

-- ═══ Форсим FOV каждый кадр (перебивает сброс Pressure) ═══
FOVForceConn = RunService.RenderStepped:Connect(function()
    if DesiredFOV == OriginalFOV then return end
    local cam = workspace.CurrentCamera
    if cam and cam.FieldOfView ~= DesiredFOV then
        cam.FieldOfView = DesiredFOV
    end
end)

RegisterCleanup("FOV", function()
    if FOVForceConn then FOVForceConn:Disconnect() FOVForceConn = nil end
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = OriginalFOV
    end
end)

-- ═══ FULLBRIGHT ═══
local FullBrightEnabled = false
local OriginalLighting = {}

local function SaveLighting()
    local L = game:GetService("Lighting")
    OriginalLighting = {
        Ambient = L.Ambient,
        OutdoorAmbient = L.OutdoorAmbient,
        Brightness = L.Brightness,
        ClockTime = L.ClockTime,
        GlobalShadows = L.GlobalShadows,
        FogEnd = L.FogEnd,
        FogStart = L.FogStart,
        EnvironmentDiffuseScale = L.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = L.EnvironmentSpecularScale,
        ExposureCompensation = L.ExposureCompensation,
    }
end

local function ApplyFullBright()
    local L = game:GetService("Lighting")
    L.Ambient = Color3.fromRGB(178, 178, 178)
    L.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    L.Brightness = 3
    L.ClockTime = 14
    L.GlobalShadows = false
    L.FogEnd = 100000
    L.FogStart = 100000
    L.EnvironmentDiffuseScale = 1
    L.EnvironmentSpecularScale = 1
    L.ExposureCompensation = 0
end

local function RestoreLighting()
    if not next(OriginalLighting) then return end
    local L = game:GetService("Lighting")
    for k, v in pairs(OriginalLighting) do
        pcall(function() L[k] = v end)
    end
    OriginalLighting = {}
end

VisualsTab:Toggle({
    Name = "FullBright",
	Flag = "FullBright",
    Desc = "Полное освещение",
    Default = false,
    Callback = function(value)
        FullBrightEnabled = value
        if value then
            if not next(OriginalLighting) then SaveLighting() end
            ApplyFullBright()
        else
            RestoreLighting()
        end
    end,
})

RegisterCleanup("FullBright", function()
    FullBrightEnabled = false
    RestoreLighting()
end)

-- ═══════════════════════════════════════════════════════════
-- DOOR ESP (v13 — чистая заливка через Box)
-- ═══════════════════════════════════════════════════════════
local DoorESP_Enabled = false
local DoorESP_Color = Color3.fromRGB(220, 60, 60)
local DoorESP_Objects = {}
local DoorESP_Conn = nil
local RoomNumberCache = {}

-- Размеры бокса (подбираем вручную)
local DOOR_SCALE_X = 76       -- % ширины
local DOOR_SCALE_Y = 92       -- % высоты
local DOOR_THICKNESS_Z = 0.15 -- studs (тонкий бокс как сама дверь)

local DOOR_NAMES = {
    ["NormalDoor"] = true, ["UpperDoor"] = true, ["DeadEndDoor"] = true,
    ["BrokenDoor"] = true, ["BigDoor"] = true,
}

local BAD_KEYWORDS = {
    "collision", "root", "gear", "handle",
    "signpart", "recolor", "proxy", "number", "cyl", "sphere",
    "lopee", "torso", "mr_", "keypad", "lock", "doorpart1"
}

local function IsBadName(name)
    local n = name:lower()
    for _, kw in ipairs(BAD_KEYWORDS) do
        if n:find(kw) then return true end
    end
    return false
end

local function IsWorkingDoor(model)
    if not model or not model:IsA("Model") then return false end
    local n = model.Name:lower()
    if n == "lock" or n:find("cantspawn") then return false end
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then return true end
    end
    return false
end

local function GetDoorPanels(door)
    local candidates = {}
    for _, obj in ipairs(door:GetDescendants()) do
        if (obj:IsA("MeshPart") or obj:IsA("BasePart")) and not IsBadName(obj.Name) then
            local s = obj.Size
            local vol = s.X * s.Y * s.Z
            if vol > 0 then
                table.insert(candidates, {Part = obj, Volume = vol})
            end
        end
    end
    table.sort(candidates, function(a, b) return a.Volume > b.Volume end)
    local panels = {}
    if #candidates > 0 then
        local maxVol = candidates[1].Volume
        for i, c in ipairs(candidates) do
            if c.Volume >= maxVol * 0.4 then table.insert(panels, c.Part) end
            if i >= 6 then break end
        end
    end
    return panels
end

local function GetCombinedBounds(parts)
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for _, p in ipairs(parts) do
        local cf, sz = p.CFrame, p.Size
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    local corner = cf * Vector3.new(sz.X/2*x, sz.Y/2*y, sz.Z/2*z)
                    minX = math.min(minX, corner.X); maxX = math.max(maxX, corner.X)
                    minY = math.min(minY, corner.Y); maxY = math.max(maxY, corner.Y)
                    minZ = math.min(minZ, corner.Z); maxZ = math.max(maxZ, corner.Z)
                end
            end
        end
    end
    local center = Vector3.new((minX+maxX)/2, (minY+maxY)/2, (minZ+maxZ)/2)
    local size = Vector3.new(maxX-minX, maxY-minY, maxZ-minZ)
    return CFrame.new(center), size
end

local function GetRoomNumber(door)
    -- Не кэшируем результат сразу — пробуем каждый раз
    local p, depth = door, 0
    local roomFolder = nil
    while p and p ~= workspace and depth < 15 do
        if p.Name == "Rooms" then roomFolder = p break end
        p = p.Parent
        depth = depth + 1
    end
    if not roomFolder then return nil end

    local roomName = door:GetFullName():match("Rooms%.([^%.]+)%.")
    if not roomName then return nil end

    local room = roomFolder:FindFirstChild(roomName)
    if not room then return nil end

    local lights = room:FindFirstChild("Lights")
    if lights then
        local sign = lights:FindFirstChild("Sign")
        if sign then
            local sg = sign:FindFirstChild("SurfaceGui")
            if sg then
                local lbl = sg:FindFirstChildWhichIsA("TextLabel", true)
                if lbl and lbl.Text then
                    local num = tonumber(lbl.Text)
                    if num then
                        local r = num - 1
                        RoomNumberCache[door] = r
                        return r
                    end
                end
            end
        end
    end

    for _, obj in ipairs(room:GetDescendants()) do
        if obj:IsA("SurfaceGui") then
            local lbl = obj:FindFirstChildWhichIsA("TextLabel", true)
            if lbl and lbl.Text then
                local num = tonumber(lbl.Text)
                if num and num > 9 and num <= 200 then
                    local r = num - 1
                    RoomNumberCache[door] = r
                    return r
                end
            end
        end
    end
    return RoomNumberCache[door]  -- возвращаем кэш, если уже был
end

local function GetUIContainer()
    return LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
end

local function CreateDoorESP(door)
    if DoorESP_Objects[door] then return end

    local container = GetUIContainer()

    -- Мусор (петли, знаки, декор)
    local BAD_KEYWORDS = {
        "collision", "root", "gear", "handle",
        "signpart", "recolor", "proxy", "number", "cyl", "sphere",
        "lopee", "torso", "mr_", "keypad", "lock", "doorpart1"
    }

    local function isBadName(name)
        local n = name:lower()
        for _, kw in ipairs(BAD_KEYWORDS) do
            if n:find(kw) then return true end
        end
        return false
    end

    local doorParts = {}
    for _, d in ipairs(door:GetDescendants()) do
        if d:IsA("MeshPart") or d:IsA("BasePart") then
            local n = d.Name:lower()
            if not isBadName(n) and d.Transparency < 0.99 then
                local sx, sy, sz = d.Size.X, d.Size.Y, d.Size.Z
                local sides = {sx, sy, sz}
                table.sort(sides)
                local minSide = sides[1]
                local midSide = sides[2]
                local maxSide = sides[3]

                -- ═══ 1) Створка-меш (BigDoor, DeadEndDoor) ═══
                local isDoorMesh = n:find("door")

                -- ═══ 2) Створка-панель (NormalDoor: Base, BaseAddition) ═══
                local isPanel = (n == "base" or n == "baseaddition")

                -- ═══ 3) Рама ═══
                local isFrame = n:find("frame")

                if isDoorMesh or isPanel or isFrame then
                    table.insert(doorParts, d)
                end
            end
        end
    end

    if #doorParts == 0 then return end

    -- Highlight на каждую часть
    local highlights = {}
    for _, part in ipairs(doorParts) do
        local hl = Instance.new("Highlight")
        hl.Name = "NL_DoorESP"
        hl.Adornee = part
        hl.FillColor = DoorESP_Color
        hl.FillTransparency = 0.5
        hl.OutlineColor = DoorESP_Color
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = container
        table.insert(highlights, hl)
    end

    -- Billboard
    local mainPanel = doorParts[1]
    for _, p in ipairs(doorParts) do
        if p.Size.X * p.Size.Y * p.Size.Z > mainPanel.Size.X * mainPanel.Size.Y * mainPanel.Size.Z then
            mainPanel = p
        end
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "NL_DoorESP_Billboard"
    bb.Adornee = mainPanel
    bb.Size = UDim2.new(0, 200, 0, 22)
    bb.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.LightInfluence = 0
    bb.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Door ? [0]"
    lbl.TextColor3 = DoorESP_Color
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.TextStrokeTransparency = 0
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.Parent = bb

    local num = GetRoomNumber(door)

    DoorESP_Objects[door] = {
        Highlights = highlights,
        Billboard = bb,
        Label = lbl,
        MainPanel = mainPanel,
        LastRoom = num,
    }
end

local function RemoveDoorESP(door)
    local data = DoorESP_Objects[door]
    if not data then return end
    if data.Highlights then
        for _, hl in ipairs(data.Highlights) do
            pcall(function() hl:Destroy() end)
        end
    end
    pcall(function() if data.Billboard then data.Billboard:Destroy() end end)
    DoorESP_Objects[door] = nil
    RoomNumberCache[door] = nil
end

local function ClearAllDoors()
    for door in pairs(DoorESP_Objects) do RemoveDoorESP(door) end
    DoorESP_Objects = {}
    RoomNumberCache = {}
    pcall(function()
        local roots = {LocalPlayer:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
        for _, root in ipairs(roots) do
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    local n = obj.Name
                    if n == "NL_DoorESP_Billboard" or n == "NL_DoorESP"
                       or n == "NL_DoorESP_Sel" or n == "NL_DoorESP_Box" then
                        obj:Destroy()
                    end
                end
            end
        end
    end)
end

local function IsRealDoor(door)
    -- ═══ 1) Только в папке Entrances ═══
    if not door.Parent or door.Parent.Name ~= "Entrances" then
        return false
    end

    -- ═══ 2) Должен быть ProximityPrompt ═══
    for _, d in ipairs(door:GetDescendants()) do
        if d:IsA("ProximityPrompt") then return true end
    end
    return false
end

local function ScanAllDoors()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and DOOR_NAMES[obj.Name] then
            if IsRealDoor(obj) and not DoorESP_Objects[obj] then
                CreateDoorESP(obj)
            end
        end
    end
end

local function StartDoorESP()
    ScanAllDoors()
    DoorESP_Conn = workspace.DescendantAdded:Connect(function(obj)
        if not DoorESP_Enabled then return end
        if obj:IsA("Model") and DOOR_NAMES[obj.Name] then
            task.wait(0.1)
            if IsRealDoor(obj) and not DoorESP_Objects[obj] then
                CreateDoorESP(obj)
            end
        end
    end)
end

local function UpdateDoorColors()
    print("[DoorESP] UpdateColors | color:", tostring(DoorESP_Color))
    for _, data in pairs(DoorESP_Objects) do
        pcall(function()
            data.Highlight.FillColor = DoorESP_Color
            data.Highlight.OutlineColor = DoorESP_Color
        end)
        pcall(function()
            data.Selection.Color3 = DoorESP_Color
            data.Selection.SurfaceColor3 = DoorESP_Color
        end)
        pcall(function() data.BHA.Color3 = DoorESP_Color end)
        pcall(function() data.Label.TextColor3 = DoorESP_Color end)
    end
end

local function UpdateDoorTexts()
    if not DoorESP_Enabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local myPos = hrp.Position
    for door, data in pairs(DoorESP_Objects) do
        if not door.Parent then RemoveDoorESP(door) continue end
        if data.MainPanel and data.Label then
            local panelPos = data.MainPanel.Position
            local dist = math.floor((myPos - panelPos).Magnitude)
            local rn = RoomNumberCache[door]
            if not rn then rn = GetRoomNumber(door) end
            local roomStr = rn and tostring(rn) or "?"
            local newText = "Door " .. roomStr .. " [" .. dist .. "]"
            if data.Label.Text ~= newText then data.Label.Text = newText end
        end
    end
end

local function StopDoorESP()
    if DoorESP_Conn then DoorESP_Conn:Disconnect() DoorESP_Conn = nil end
end

-- ═══ Screen Section ═══
VisualsTab:Section({Name = "Screen"})

VisualsTab:Toggle({
    Name = "KeyBinds List",
    Desc = "Показывает список биндов на экране",
	Flag = "KeybindList",
    Default = false,
    Callback = function(value)
        KeybindListEnabled = value
        if value then
            CreateKeybindGui()
            RefreshKeybindList()
        else
            DestroyKeybindGui()
        end
    end
})

RegisterCleanup("KeybindList", function()
    KeybindListEnabled = false
    DestroyKeybindGui()
end)

-- ═══ ESP Section ═══
VisualsTab:Section({Name = "ESP"})

-- Toggle
VisualsTab:Toggle({
    Name = "Door ESP",
	Flag = "DoorESP",
    Desc = "Подсвечивает Двери",
    Default = false,
    Callback = function(value)
        DoorESP_Enabled = value
        if value then StartDoorESP() else StopDoorESP() ClearAllDoors() end
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if DoorESP_Enabled then UpdateDoorTexts() end
    end
end)

RegisterCleanup("DoorESP", function()
    DoorESP_Enabled = false
    StopDoorESP()
    ClearAllDoors()
end)

-- ═══════════════════════════════════════════════════════════
-- KEY/PASS ESP (v2 — точная детекция по ProximityPrompt)
-- ═══════════════════════════════════════════════════════════
local KeyESP_Enabled = false
local KeyESP_Color = Color3.fromRGB(80, 200, 255)
local KeyESP_Objects = {}
local KeyESP_Conn = nil

-- Точные фрагменты имён (lowercase)
local KEYCARD_KEYS = {"keycard"}
local NOTE_KEYS = {"passwordpaper", "password"}

-- Что игнорить (чтобы не путать с другими предметами)
local IGNORE_KEYS = {
    "currency", "drawer", "locker", "highlight", "door", "panel",
    "cabinet", "shelf", "skip", "navipanel", "spawn", "itemlocker"
}

local function ContainsAny(str, list)
    local s = str:lower()
    for _, kw in ipairs(list) do
        if s:find(kw, 1, true) then return true end
    end
    return false
end

-- От ProximityPrompt поднимаемся до Model и определяем категорию
local function DetectItemCategory(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return nil end
    local p = prompt.Parent
    local depth = 0
    while p and p ~= workspace and depth < 6 do
        local n = p.Name
        -- Пропускаем игнор-имена
        if not ContainsAny(n, IGNORE_KEYS) then
            if ContainsAny(n, KEYCARD_KEYS) then return "Keycard", p end
            if ContainsAny(n, NOTE_KEYS) then return "Note", p end
        end
        p = p.Parent
        depth = depth + 1
    end
    return nil
end

local function GetKeyBounds(parts)
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    for _, p in ipairs(parts) do
        local cf, sz = p.CFrame, p.Size
        for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
            local c = cf * Vector3.new(sz.X/2*x, sz.Y/2*y, sz.Z/2*z)
            minX = math.min(minX, c.X); maxX = math.max(maxX, c.X)
            minY = math.min(minY, c.Y); maxY = math.max(maxY, c.Y)
            minZ = math.min(minZ, c.Z); maxZ = math.max(maxZ, c.Z)
        end end end
    end
    local center = Vector3.new((minX+maxX)/2, (minY+maxY)/2, (minZ+maxZ)/2)
    local size = Vector3.new(maxX-minX, maxY-minY, maxZ-minZ)
    return CFrame.new(center), size
end

local function GetKeyUIContainer()
    return LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
end

-- Собрать все части контейнера (для bounding box)
local function GetContainerParts(container)
    local parts = {}
    if container:IsA("BasePart") or container:IsA("MeshPart") then
        table.insert(parts, container)
    else
        for _, d in ipairs(container:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("MeshPart") then
                table.insert(parts, d)
            end
        end
    end
    return parts
end

-- Читаем код с бумаги (часть "Code" содержит SurfaceGui с текстом)
local function ExtractCode(container)
    if not container then return nil end

    -- 1) Приоритет: часть с именем "Code" (точное место кода)
    local codeParts = {}
    if container.Name:lower() == "code" then
        table.insert(codeParts, container)
    else
        local found = container:FindFirstChild("Code", true)
        if found then table.insert(codeParts, found) end
    end

    for _, cp in ipairs(codeParts) do
        for _, d in ipairs(cp:GetDescendants()) do
            if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
                local lbl = d:FindFirstChildWhichIsA("TextLabel", true)
                if lbl and lbl.Text and #lbl.Text > 0 and #lbl.Text <= 12 then
                    return lbl.Text
                end
            end
        end
        -- Если сам cp имеет SurfaceGui прямо
        for _, d in ipairs(cp:GetChildren()) do
            if d:IsA("SurfaceGui") then
                local lbl = d:FindFirstChildWhichIsA("TextLabel", true)
                if lbl and lbl.Text and #lbl.Text > 0 then return lbl.Text end
            end
        end
    end

    -- 2) Fallback: ищем любой SurfaceGui с коротким числовым текстом
    for _, d in ipairs(container:GetDescendants()) do
        if d:IsA("SurfaceGui") then
            local lbl = d:FindFirstChildWhichIsA("TextLabel", true)
            if lbl and lbl.Text then
                local t = lbl.Text
                if #t > 0 and #t <= 6 and t:match("^%d+$") then
                    return t
                end
            end
        end
    end
    return nil
end

-- Жёсткие размеры (studs) — подобраны под Pressure
local KEY_SIZES = {
    ["Keycard"] = Vector3.new(0.75, 0.60, 0.05),   -- ширина × высота × толщина
    ["Note"]    = Vector3.new(1.10, 1.75, 0.05),
}

local function CreateKeyESP(container, category, prompt)
    if KeyESP_Objects[container] then return end

    local container_ui = GetKeyUIContainer()

    -- ═══ Highlight прямо на контейнер (Model или Part) ═══
    -- Roblox сам рисует контур по всем видимым мешам внутри
    local hl = Instance.new("Highlight")
    hl.Name = "NL_KeyESP"
    hl.Adornee = container          -- ← прямо модель/часть, без Box
    hl.FillColor = KeyESP_Color
    hl.FillTransparency = 0.5
    hl.OutlineColor = KeyESP_Color
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = container_ui

    -- ═══ Billboard на позицию карты/бумаги ═══
    -- Берём позицию самой крупной видимой части (для центра текста)
    local targetPart, targetVol = nil, 0
    for _, d in ipairs(container:GetDescendants()) do
        if (d:IsA("BasePart") or d:IsA("MeshPart"))
           and not d.Name:lower():find("proxy")
           and d.Transparency < 0.99 then
            local vol = d.Size.X * d.Size.Y * d.Size.Z
            if vol > targetVol then
                targetVol = vol
                targetPart = d
            end
        end
    end
    if not targetPart and (container:IsA("BasePart") or container:IsA("MeshPart")) then
        targetPart = container
    end
    if not targetPart then
        pcall(function() hl:Destroy() end)
        return
    end

    local codeText = nil
    if category == "Note" then
        codeText = ExtractCode(container)
    end

    local bbHeight = codeText and 42 or 22

    local bb = Instance.new("BillboardGui")
    bb.Name = "NL_KeyESP_Billboard"
    bb.Adornee = targetPart        -- ← на реальную часть
    bb.Size = UDim2.new(0, 180, 0, bbHeight)
    bb.StudsOffset = Vector3.new(0, 1.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.LightInfluence = 0
    bb.Parent = container_ui

    local lbl = Instance.new("TextLabel")
    lbl.Name = "NL_KeyESP_MainLabel"
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = category .. " [0]"
    lbl.TextColor3 = KeyESP_Color
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.TextStrokeTransparency = 0
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb

    local codeLbl = nil
    if codeText then
        codeLbl = Instance.new("TextLabel")
        codeLbl.Name = "NL_KeyESP_CodeLabel"
        codeLbl.Size = UDim2.new(1, 0, 0, 20)
        codeLbl.Position = UDim2.new(0, 0, 0, 20)
        codeLbl.BackgroundTransparency = 1
        codeLbl.Text = codeText
        codeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        codeLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
        codeLbl.TextStrokeTransparency = 0
        codeLbl.TextSize = 16
        codeLbl.Font = Enum.Font.GothamBold
        codeLbl.Parent = bb
    end

    KeyESP_Objects[container] = {
        Highlight = hl,
        Billboard = bb,
        Label = lbl,
        CodeLabel = codeLbl,
        AnchorPos = targetPart.Position,
        Category = category,
        Code = codeText,
    }
end

local function RemoveKeyESP(container)
    local data = KeyESP_Objects[container]
    if not data then return end
    pcall(function() if data.Highlight then data.Highlight:Destroy() end end)
    pcall(function() if data.Billboard then data.Billboard:Destroy() end end)
    KeyESP_Objects[container] = nil
end

local function ClearAllKeyESP()
    for c in pairs(KeyESP_Objects) do RemoveKeyESP(c) end
    KeyESP_Objects = {}
    pcall(function()
        local roots = {LocalPlayer:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
        for _, root in ipairs(roots) do
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    local n = obj.Name
                    if n == "NL_KeyESP_Billboard" or n == "NL_KeyESP" then
                        obj:Destroy()
                    end
                end
            end
        end
    end)
end

-- Скан: идём только по ProximityPrompt'ам (точно и быстро)
local function ScanKeyItems()
    if not KeyESP_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local cat, container = DetectItemCategory(obj)
            if cat and container and not KeyESP_Objects[container] then
                CreateKeyESP(container, cat, obj)
            end
        end
    end
end

local function UpdateKeyTexts()
    if not KeyESP_Enabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local myPos = hrp.Position
    for c, data in pairs(KeyESP_Objects) do
        if not c.Parent then RemoveKeyESP(c) continue end
        if data.AnchorPos and data.Label then
            local dist = math.floor((myPos - data.AnchorPos).Magnitude)
            local newText = data.Category .. " [" .. dist .. "]"
            if data.Label.Text ~= newText then data.Label.Text = newText end
        end
    end
end

local function StartKeyESP()
    ScanKeyItems()
    KeyESP_Conn = workspace.DescendantAdded:Connect(function(obj)
        if not KeyESP_Enabled then return end
        if obj:IsA("ProximityPrompt") then
            task.wait(0.1)
            local cat, container = DetectItemCategory(obj)
            if cat and container and not KeyESP_Objects[container] then
                CreateKeyESP(container, cat, obj)
            end
        end
    end)
end

local function StopKeyESP()
    if KeyESP_Conn then KeyESP_Conn:Disconnect() KeyESP_Conn = nil end
end

-- Toggle
VisualsTab:Toggle({
    Name = "Key/Pass ESP",
    Flag = "KeyESP",
    Desc = "Подсвечивает Keycard и PasswordPaper",
    Default = false,
    Callback = function(value)
        KeyESP_Enabled = value
        if value then StartKeyESP() else StopKeyESP() ClearAllKeyESP() end
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if KeyESP_Enabled then UpdateKeyTexts() end
    end
end)

RegisterCleanup("KeyESP", function()
    KeyESP_Enabled = false
    StopKeyESP()
    ClearAllKeyESP()
end)

-- ═══════════════════════════════════════════════════════════
-- LOCKER ESP (v2 — только Highlight, только настоящие шкафы)
-- ═══════════════════════════════════════════════════════════
local LockerESP_Enabled = false
local LockerESP_Color = Color3.fromRGB(255, 180, 60)
local LockerESP_Objects = {}
local LockerESP_Conn = nil

-- ═══ Только "Locker" (без ItemLocker, SmallCabinet, LockerShelf) ═══
local function IsRealLocker(name)
    local n = name:lower()
    -- Точное имя "locker"
    if n == "locker" then return true end
    return false
end

local function CreateLockerESP(container)
    if LockerESP_Objects[container] then return end

    local container_ui = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

    -- ═══ Только Highlight на модель ═══
    local hl = Instance.new("Highlight")
    hl.Name = "NL_LockerESP"
    hl.Adornee = container
    hl.FillColor = LockerESP_Color
    hl.FillTransparency = 0.5
    hl.OutlineColor = LockerESP_Color
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = container_ui

    -- ═══ Billboard над шкафом ═══
    -- Ищем центр по bounding box модели
    local cf, sz
    local ok, bcf, bsz = pcall(function() return container:GetBoundingBox() end)
    if ok and bcf and bsz then
        cf, sz = bcf, bsz
    else
        -- Fallback: от первой части
        for _, d in ipairs(container:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("MeshPart") then
                cf = d.CFrame
                sz = d.Size
                break
            end
        end
    end

    if not cf then
        pcall(function() hl:Destroy() end)
        return
    end

    local bb = Instance.new("BillboardGui")
    bb.Name = "NL_LockerESP_Billboard"
    bb.Adornee = container
    bb.Size = UDim2.new(0, 160, 0, 22)
    bb.StudsOffsetWorldSpace = Vector3.new(0, (sz and sz.Y/2 or 3) + 1, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.LightInfluence = 0
    bb.Parent = container_ui

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Locker [0]"
    lbl.TextColor3 = LockerESP_Color
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.TextStrokeTransparency = 0
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb

    LockerESP_Objects[container] = {
        Highlight = hl,
        Billboard = bb,
        Label = lbl,
        AnchorPos = cf.Position,
    }
end

local function RemoveLockerESP(container)
    local data = LockerESP_Objects[container]
    if not data then return end
    pcall(function() if data.Highlight then data.Highlight:Destroy() end end)
    pcall(function() if data.Billboard then data.Billboard:Destroy() end end)
    LockerESP_Objects[container] = nil
end

local function ClearAllLockerESP()
    for c in pairs(LockerESP_Objects) do RemoveLockerESP(c) end
    LockerESP_Objects = {}
    pcall(function()
        local roots = {LocalPlayer:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
        for _, root in ipairs(roots) do
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    local n = obj.Name
                    if n == "NL_LockerESP_Billboard" or n == "NL_LockerESP" then
                        obj:Destroy()
                    end
                end
            end
        end
    end)
end

local function ScanLockers()
    if not LockerESP_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and IsRealLocker(obj.Name) then
            if not LockerESP_Objects[obj] then
                CreateLockerESP(obj)
            end
        end
    end
end

local function UpdateLockerTexts()
    if not LockerESP_Enabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local myPos = hrp.Position
    for c, data in pairs(LockerESP_Objects) do
        if not c.Parent then RemoveLockerESP(c) continue end
        if data.AnchorPos and data.Label then
            local dist = math.floor((myPos - data.AnchorPos).Magnitude)
            local newText = "Locker [" .. dist .. "]"
            if data.Label.Text ~= newText then data.Label.Text = newText end
        end
    end
end

local function StartLockerESP()
    ScanLockers()
    LockerESP_Conn = workspace.DescendantAdded:Connect(function(obj)
        if not LockerESP_Enabled then return end
        if obj:IsA("Model") and IsRealLocker(obj.Name) then
            task.wait(0.1)
            if not LockerESP_Objects[obj] then
                CreateLockerESP(obj)
            end
        end
    end)
end

local function StopLockerESP()
    if LockerESP_Conn then LockerESP_Conn:Disconnect() LockerESP_Conn = nil end
end

VisualsTab:Toggle({
    Name = "Locker ESP",
	Flag = "LockerESP",
    Desc = "Подсвечивает настоящие шкафчики",
    Default = false,
    Callback = function(value)
        LockerESP_Enabled = value
        if value then StartLockerESP() else StopLockerESP() ClearAllLockerESP() end
    end,
})

task.spawn(function()
    while task.wait(0.5) do
        if LockerESP_Enabled then UpdateLockerTexts() end
    end
end)

RegisterCleanup("LockerESP", function()
    LockerESP_Enabled = false
    StopLockerESP()
    ClearAllLockerESP()
end)

-- ═══════════════════════════════════════════════════════════
-- LEVER ESP (только Highlight)
-- ═══════════════════════════════════════════════════════════
local LeverESP_Enabled = false
local LeverESP_Color = Color3.fromRGB(255, 80, 80)
local LeverESP_Objects = {}
local LeverESP_Conn = nil

-- ═══ Имена рычагов в Pressure ═══
local LEVER_KEYWORDS = {"lever", "switch", "valve", "button"}
-- ═══ Игнор — что НЕ рычаг ═══
local LEVER_IGNORE = {"light", "lamp", "bulb", "sign"}

local function MatchesLever(name)
    local n = name:lower()
    for _, kw in ipairs(LEVER_IGNORE) do
        if n:find(kw, 1, true) then return false end
    end
    for _, kw in ipairs(LEVER_KEYWORDS) do
        if n:find(kw, 1, true) then return true end
    end
    return false
end

-- ═══ Модель должна иметь ProximityPrompt (иначе это декорация) ═══
local function HasPrompt(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") then return true end
    end
    return false
end

local function CreateLeverESP(container)
    if LeverESP_Objects[container] then return end

    local container_ui = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

    -- ═══ Highlight ═══
    local hl = Instance.new("Highlight")
    hl.Name = "NL_LeverESP"
    hl.Adornee = container
    hl.FillColor = LeverESP_Color
    hl.FillTransparency = 0.5
    hl.OutlineColor = LeverESP_Color
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = container_ui

    -- ═══ Bounding box ═══
    local cf, sz
    local ok, bcf, bsz = pcall(function() return container:GetBoundingBox() end)
    if ok and bcf and bsz then
        cf, sz = bcf, bsz
    else
        for _, d in ipairs(container:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("MeshPart") then
                cf = d.CFrame
                sz = d.Size
                break
            end
        end
    end

    if not cf then
        pcall(function() hl:Destroy() end)
        return
    end

    -- ═══ Billboard ═══
    local bb = Instance.new("BillboardGui")
    bb.Name = "NL_LeverESP_Billboard"
    bb.Adornee = container
    bb.Size = UDim2.new(0, 140, 0, 22)
    bb.StudsOffsetWorldSpace = Vector3.new(0, (sz and sz.Y/2 or 2) + 1, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.LightInfluence = 0
    bb.Parent = container_ui

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Lever [0]"
    lbl.TextColor3 = LeverESP_Color
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.TextStrokeTransparency = 0
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb

    LeverESP_Objects[container] = {
        Highlight = hl,
        Billboard = bb,
        Label = lbl,
        AnchorPos = cf.Position,
    }
end

local function RemoveLeverESP(container)
    local data = LeverESP_Objects[container]
    if not data then return end
    pcall(function() if data.Highlight then data.Highlight:Destroy() end end)
    pcall(function() if data.Billboard then data.Billboard:Destroy() end end)
    LeverESP_Objects[container] = nil
end

local function ClearAllLeverESP()
    for c in pairs(LeverESP_Objects) do RemoveLeverESP(c) end
    LeverESP_Objects = {}
    pcall(function()
        local roots = {LocalPlayer:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
        for _, root in ipairs(roots) do
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    local n = obj.Name
                    if n == "NL_LeverESP_Billboard" or n == "NL_LeverESP" then
                        obj:Destroy()
                    end
                end
            end
        end
    end)
end

local function ScanLevers()
    if not LeverESP_Enabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and MatchesLever(obj.Name) and HasPrompt(obj) then
            if not LeverESP_Objects[obj] then
                CreateLeverESP(obj)
            end
        end
    end
end

local function UpdateLeverTexts()
    if not LeverESP_Enabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local myPos = hrp.Position
    for c, data in pairs(LeverESP_Objects) do
        if not c.Parent then RemoveLeverESP(c) continue end
        if data.AnchorPos and data.Label then
            local dist = math.floor((myPos - data.AnchorPos).Magnitude)
            local newText = "Lever [" .. dist .. "]"
            if data.Label.Text ~= newText then data.Label.Text = newText end
        end
    end
end

local function StartLeverESP()
    ScanLevers()
    LeverESP_Conn = workspace.DescendantAdded:Connect(function(obj)
        if not LeverESP_Enabled then return end
        if obj:IsA("Model") and MatchesLever(obj.Name) then
            task.wait(0.1)
            if HasPrompt(obj) and not LeverESP_Objects[obj] then
                CreateLeverESP(obj)
            end
        end
    end)
end

local function StopLeverESP()
    if LeverESP_Conn then LeverESP_Conn:Disconnect() LeverESP_Conn = nil end
end

VisualsTab:Toggle({
    Name = "Lever ESP",
    Desc = "Подсвечивает рычаги и кнопки",
    Default = false,
    Flag = "LeverESP",
    Callback = function(value)
        LeverESP_Enabled = value
        if value then StartLeverESP() else StopLeverESP() ClearAllLeverESP() end
    end,
})

task.spawn(function()
    while task.wait(0.5) do
        if LeverESP_Enabled then UpdateLeverTexts() end
    end
end)

RegisterCleanup("LeverESP", function()
    LeverESP_Enabled = false
    StopLeverESP()
    ClearAllLeverESP()
end)

-- ═══════════════════════════════════════════════════════════
-- ESP COLOR SYSTEM (Global / Local)
-- ═══════════════════════════════════════════════════════════
local ESPRegistry = {}          -- key → {Name, ApplyColor}
local ESPColorGlobal = true
local ESPColorActive = {}       -- key → true/false
local GlobalColor = Color3.fromRGB(220, 60, 60)

local function RegisterESP(key, displayName, applyColorFn)
    ESPRegistry[key] = {Name = displayName, ApplyColor = applyColorFn}
    ESPColorActive[key] = true
    print("[ESP] Registered:", key, "→", displayName)
end

local function ApplyColorToESP(key, color)
    local e = ESPRegistry[key]
    if e and e.ApplyColor then pcall(e.ApplyColor, color) end
end

local function ApplyColorByMode(color)
    if ESPColorGlobal then
        -- Global ON → все ESP
        for key, _ in pairs(ESPRegistry) do
            ApplyColorToESP(key, color)
        end
    else
        -- Global OFF → только выбранные
        for key, active in pairs(ESPColorActive) do
            if active then ApplyColorToESP(key, color) end
        end
    end
end

local function GetESPNameList()
    local list = {}
    for _, esp in pairs(ESPRegistry) do table.insert(list, esp.Name) end
    table.sort(list)
    return list
end

RegisterESP("DoorESP", "Door ESP", function(color)
    DoorESP_Color = color
    for _, data in pairs(DoorESP_Objects) do
        if data.Highlights then
            for _, hl in ipairs(data.Highlights) do
                pcall(function()
                    hl.FillColor = color
                    hl.OutlineColor = color
                end)
            end
        end
        pcall(function() if data.Label then data.Label.TextColor3 = color end end)
    end
end)

-- ═══ Регистрируем Key/Pass ESP ═══
RegisterESP("KeyESP", "Key/Pass ESP", function(color)
    KeyESP_Color = color
    for _, data in pairs(KeyESP_Objects) do
        pcall(function()
            data.Highlight.FillColor = color
            data.Highlight.OutlineColor = color
        end)
        pcall(function() data.Label.TextColor3 = color end)
    end
end)

-- ═══ Регистрируем Locker ESP ═══
RegisterESP("LockerESP", "Locker ESP", function(color)
    LockerESP_Color = color
    for _, data in pairs(LockerESP_Objects) do
        pcall(function()
            data.Highlight.FillColor = color
            data.Highlight.OutlineColor = color
        end)
        pcall(function() data.Label.TextColor3 = color end)
    end
end)

-- ═══ Регистрируем Lever ESP ═══
RegisterESP("LeverESP", "Lever ESP", function(color)
    LeverESP_Color = color
    for _, data in pairs(LeverESP_Objects) do
        pcall(function()
            data.Highlight.FillColor = color
            data.Highlight.OutlineColor = color
        end)
        pcall(function() data.Label.TextColor3 = color end)
    end
end)

-- ═══ UI ═══
local ESPListDropdown = nil

-- 1) ColorPicker "Color"
VisualsTab:ColorPicker({
    Name = "Color",
	Flag = "ESPColor",
    Default = GlobalColor,
    Callback = function(color)
        if typeof(color) ~= "Color3" then
            print("[Color] invalid type:", typeof(color))
            return
        end
        GlobalColor = color
        ApplyColorByMode(color)
    end
})

-- ═══ Apply to (взаимоисключающе, Global ↔ ESP) ═══
local GLOBAL_OPT = "Global"
local ESPListDropdown = nil
local IsProcessingDropdown = false
local prevGlobal = true
local prevESPs = {}   -- set имён выбранных ESP

local function GetMergedOptions()
    local list = {GLOBAL_OPT}
    for _, esp in pairs(ESPRegistry) do
        table.insert(list, esp.Name)
    end
    table.sort(list, function(a, b)
        if a == GLOBAL_OPT then return true end
        if b == GLOBAL_OPT then return false end
        return a < b
    end)
    return list
end

-- Собрать текущее состояние в массив для Set()
local function BuildSelectionArray()
    local arr = {}
    if ESPColorGlobal then
        table.insert(arr, GLOBAL_OPT)
    else
        for espKey, active in pairs(ESPColorActive) do
            if active and ESPRegistry[espKey] then
                table.insert(arr, ESPRegistry[espKey].Name)
            end
        end
    end
    table.sort(arr, function(a, b)
        if a == GLOBAL_OPT then return true end
        if b == GLOBAL_OPT then return false end
        return a < b
    end)
    return arr
end

ESPListDropdown = VisualsTab:Dropdown({
    Name = "Apply to",
	Flag = "ESPApplyTo",
    Desc = "",
    Options = GetMergedOptions(),
    Default = {GLOBAL_OPT},
    Multi = true,
    Callback = function(values)
        if IsProcessingDropdown then return end
        IsProcessingDropdown = true

        -- Парсим выделенные
        local selected = {}
        if type(values) == "table" then
            for k, v in pairs(values) do
                if type(k) == "string" and v == true then
                    selected[k] = true
                elseif type(v) == "string" then
                    selected[v] = true
                end
            end
        elseif type(values) == "string" then
            selected[values] = true
        end

        local nowGlobal = selected[GLOBAL_OPT] == true
        local nowESPs = {}
        for name, _ in pairs(selected) do
            if name ~= GLOBAL_OPT then table.insert(nowESPs, name) end
        end
        local nowESPSet = {}
        for _, n in ipairs(nowESPs) do nowESPSet[n] = true end

        -- Определяем что именно изменилось
        local globalChanged = (nowGlobal ~= prevGlobal)
        local addedESP = false
        local removedESP = false
        for _, n in ipairs(nowESPs) do
            if not prevESPs[n] then addedESP = true end
        end
        for n, _ in pairs(prevESPs) do
            if not nowESPSet[n] then removedESP = true end
        end

        -- ═══ Резолвим финальное состояние ═══
        local newSelection
        if nowGlobal and #nowESPs > 0 then
            -- Оба выбраны → смотрим что юзер только что нажал
            if addedESP and not globalChanged then
                -- был Global → нажал ESP → убираем Global
                newSelection = nowESPs
            else
                -- был ESP(ы) → нажал Global → убираем все ESP
                newSelection = {GLOBAL_OPT}
            end
        elseif nowGlobal then
            newSelection = {GLOBAL_OPT}
        elseif #nowESPs > 0 then
            newSelection = nowESPs
        else
            newSelection = {}
        end

        -- Применяем к системе
        ESPColorGlobal = false
        for k, _ in pairs(ESPColorActive) do ESPColorActive[k] = false end
        for _, name in ipairs(newSelection) do
            if name == GLOBAL_OPT then
                ESPColorGlobal = true
            else
                for espKey, esp in pairs(ESPRegistry) do
                    if esp.Name == name or espKey == name then
                        ESPColorActive[espKey] = true
                    end
                end
            end
        end

        -- Сохраняем prev
        prevGlobal = ESPColorGlobal
        prevESPs = {}
        for espKey, active in pairs(ESPColorActive) do
            if active and ESPRegistry[espKey] then
                prevESPs[ESPRegistry[espKey].Name] = true
            end
        end

        print("[Color] Global:", ESPColorGlobal, "| ESPs:", #nowESPs > 0 and table.concat(nowESPs, ",") or "—")

        -- ═══ Отложенный apply + синхронизация UI ═══
        local colorToApply = GlobalColor
        local arrayToSet = BuildSelectionArray()
        task.spawn(function()
            task.wait()
            ApplyColorByMode(colorToApply)

            -- Синхронизируем визуально чекбоксы дропдауна
            if ESPListDropdown then
                pcall(function() ESPListDropdown:Set(arrayToSet) end)
                pcall(function() ESPListDropdown:SetValue(arrayToSet) end)
                pcall(function() ESPListDropdown:Update(arrayToSet) end)
            end

            task.wait(0.05)
            IsProcessingDropdown = false
        end)
    end
})

-- ═══════════════════════════════════════════════════════════
-- 8. SETTINGS TAB
-- ═══════════════════════════════════════════════════════════
SettingsTab:Section({Name = "Menu"})

SettingsTab:Button({
    Name = "Unload",
    Desc = "Выгрузить скрипт (все функции + UI)",
    Icon = "lucide:power",
    Style = "Danger",
Callback = function()
    _G.SynapseUnloaded = true
    print("[Synapse] === UNLOAD START ===")
    
    -- ═══ ФОРС-СБРОС JUMP (до всего) ═══
    AllowJumpEnabled = false
    InfinityJumpEnabled = false
    SitGuard = false
    if JumpConn then JumpConn:Disconnect() JumpConn = nil end
    if SitBlockConn then SitBlockConn:Disconnect() SitBlockConn = nil end
    if SitHeartbeatConn then SitHeartbeatConn:Disconnect() SitHeartbeatConn = nil end
    if SitChangedConn then SitChangedConn:Disconnect() SitChangedConn = nil end
    if SeatedConn then SeatedConn:Disconnect() SeatedConn = nil end
    
    -- ═══ Снимаем только наш Sit, НЕ трогаем Jumping ═══
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.Sit then hum.Sit = false end
            -- НЕ восстанавливаем Jumping / Seated — Pressure сам
        end
    end)
    
    -- ═══ Останавливаем polling keybind list ═══
    _G.SynapseUnloaded = true
    
    -- ═══ Обычный cleanup ═══
    pcall(RunAllCleanups)
    
    -- ═══ Сбрасываем мышь ═══
    pcall(function()
        if _G.NL_MouseUnlockConn then
            _G.NL_MouseUnlockConn:Disconnect()
            _G.NL_MouseUnlockConn = nil
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end)
    
    -- ═══ Сбрасываем камеру ═══
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then cam.CameraSubject = hum end
            end
        end
    end)
    
    -- ═══ Уничтожаем UI ═══
    pcall(function()
        if Window and Window.Destroy then
            Window:Destroy()
        end
    end)
    
    -- ═══ Финальная очистка ═══
    pcall(function()
        local root = gethui and gethui() or game:GetService("CoreGui")
        for _, gui in ipairs(root:GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name == "AirflowUI" or gui.Name == "Synapse") then
                gui:Destroy()
            end
        end
    end)
    
    print("[Synapse] === UNLOAD COMPLETE ===")
end
})

-- ═══════════════════════════════════════════════════════════
-- CONFIGS
-- ═══════════════════════════════════════════════════════════
SettingsTab:Section({Name = "Configs"})

local HttpService = game:GetService("HttpService")
local AUTOLOAD_FILE = "Synapse/autoload.txt"
local EXTRA_SUFFIX = "_extra.json"

local function GetExtraPath(name)
    return "AirflowUI/" .. name .. EXTRA_SUFFIX
end

local function EnsureFolder(path)
    if not makefolder or not isfolder then return end
    local current = ""
    for part in string.gmatch(path, "[^/]+") do
        current = (current == "" and part) or (current .. "/" .. part)
        if not isfolder(current) then pcall(makefolder, current) end
    end
end

-- ═══ Сбор всего extra состояния ═══
local function CollectExtra()
    local data = {}
    data.MenuKeybind = (Window.Keybind and Window.Keybind.Name) or nil
    data.KeybindListEnabled = KeybindListEnabled
    data.ESPColorGlobal = ESPColorGlobal
    data.ESPColorActive = ESPColorActive
    data.GlobalColor = {GlobalColor.R, GlobalColor.G, GlobalColor.B}
    data.DoorESP_Color = {DoorESP_Color.R, DoorESP_Color.G, DoorESP_Color.B}
    data.KeyESP_Color = {KeyESP_Color.R, KeyESP_Color.G, KeyESP_Color.B}
    data.LockerESP_Color = {LockerESP_Color.R, LockerESP_Color.G, LockerESP_Color.B}
    data.SpeedValue = SpeedValue
    data.SpeedEnabled = SpeedEnabled
    
    -- Keybinds: клавиши + состояние
    data.Keybinds = {}
    data.KeybindStates = {}
    if KeybindRegistry then
        for id, kb in pairs(KeybindRegistry) do
            if kb.Key then data.Keybinds[id] = kb.Key.Name end
            data.KeybindStates[id] = kb.State or false
        end
    end
    return data
end

local function ApplyExtra(data)
    if type(data) ~= "table" then return end
    
    -- Menu keybind
    if data.MenuKeybind then
        local kc = Enum.KeyCode[data.MenuKeybind]
        if kc and Window.SetKeybind then
            pcall(function() Window:SetKeybind(kc) end)
        end
    end
    
    -- Keybind list
    if data.KeybindListEnabled ~= nil then
        KeybindListEnabled = data.KeybindListEnabled
        if KeybindListEnabled then
            if CreateKeybindGui then pcall(CreateKeybindGui) end
            if RefreshKeybindList then pcall(RefreshKeybindList) end
        else
            if DestroyKeybindGui then pcall(DestroyKeybindGui) end
        end
    end
    
    -- ═══ Восстанавливаем per-ESP цвета ДО применения ═══
    if data.GlobalColor then
        GlobalColor = Color3.new(data.GlobalColor[1], data.GlobalColor[2], data.GlobalColor[3])
    end
    if data.DoorESP_Color then
        DoorESP_Color = Color3.new(data.DoorESP_Color[1], data.DoorESP_Color[2], data.DoorESP_Color[3])
    end
    if data.KeyESP_Color then
        KeyESP_Color = Color3.new(data.KeyESP_Color[1], data.KeyESP_Color[2], data.KeyESP_Color[3])
    end
    if data.LockerESP_Color then
        LockerESP_Color = Color3.new(data.LockerESP_Color[1], data.LockerESP_Color[2], data.LockerESP_Color[3])
    end
    
    -- ESP mode
    if data.ESPColorGlobal ~= nil then ESPColorGlobal = data.ESPColorGlobal end
    if data.ESPColorActive then
        for k, v in pairs(data.ESPColorActive) do ESPColorActive[k] = v end
    end
    
    -- ═══ Применяем КАЖДЫЙ цвет ОТДЕЛЬНО, не через ApplyColorByMode ═══
    if ApplyColorToESP then
        pcall(ApplyColorToESP, "DoorESP", DoorESP_Color)
        pcall(ApplyColorToESP, "KeyESP", KeyESP_Color)
        pcall(ApplyColorToESP, "LockerESP", LockerESP_Color)
    end
    
    -- Keybinds (клавиши)
    if data.Keybinds and KeybindRegistry then
        for id, keyName in pairs(data.Keybinds) do
            local kc = Enum.KeyCode[keyName]
            if kc and KeybindRegistry[id] then
                KeybindRegistry[id].Key = kc
            end
        end
    end
    
    -- ═══ Keybind states + вызываем callback ═══
    if data.KeybindStates and KeybindRegistry then
        for id, state in pairs(data.KeybindStates) do
            local kb = KeybindRegistry[id]
            if kb then
                kb.State = state
                if kb.Callback then
                    pcall(kb.Callback, state)
                end
            end
        end
    end
    
    if RefreshKeybindList then pcall(RefreshKeybindList) end
    
    -- Speed (без вызова callback — чтобы не запускать бинд)
    if data.SpeedValue ~= nil then SpeedValue = data.SpeedValue end
    if data.SpeedEnabled ~= nil then SpeedEnabled = data.SpeedEnabled end
end

-- ═══ Сохранение ═══
local function SaveExtra(name)
    if not writefile then return end
    EnsureFolder("AirflowUI")
    local data = CollectExtra()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then pcall(writefile, GetExtraPath(name), encoded) end
end

-- ═══ Загрузка ═══
local function LoadExtra(name)
    if not (readfile and isfile) then return end
    local path = GetExtraPath(name)
    if not isfile(path) then return end
    local ok, content = pcall(readfile, path)
    if not ok or not content then return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if ok2 then ApplyExtra(data) end
end

-- ═══ AutoLoad helpers ═══
local function GetAutoLoadConfig()
    if not (isfile and readfile and isfile(AUTOLOAD_FILE)) then return nil end
    local ok, name = pcall(readfile, AUTOLOAD_FILE)
    if ok and name and #name > 0 then return name:gsub("%s+$", "") end
    return nil
end
local function SetAutoLoadConfig(name)
    if not writefile then return end
    if not isfolder("Synapse") and makefolder then makefolder("Synapse") end
    pcall(writefile, AUTOLOAD_FILE, name or "")
end
local function ClearAutoLoadConfig()
    if delfile and isfile and isfile(AUTOLOAD_FILE) then pcall(delfile, AUTOLOAD_FILE) end
end

-- ═══ UI ═══
local ConfigNameInput = SettingsTab:Input({
    Name = "Config Name",
    Placeholder = "my_config",
    Default = "",
})

local ConfigListDropdown = SettingsTab:Dropdown({
    Name = "Saved Configs",
    Options = Window:ListConfigs(),
    Default = nil,
    Callback = function(value)
        if value then
            pcall(function() ConfigNameInput:Set(value, true) end)
        end
    end,
})

local function RefreshConfigList()
    pcall(function() ConfigListDropdown:Refresh(Window:ListConfigs(), true) end)
end

SettingsTab:Button({
    Name = "Save Config",
    Desc = "Сохранить ВСЁ (тоглы, цвета, бинды)",
    Icon = "lucide:save",
    Style = "Primary",
    Callback = function()
        local name = ConfigNameInput:Get()
        if not name or #name == 0 then
            Window:Notify({Title = "Config", Content = "Введи имя", Type = "Warning", Duration = 3})
            return
        end
        local ok, err = Window:SaveConfig(name)
        SaveExtra(name)  -- ← сохраняем extra
        if ok then
            RefreshConfigList()
            Window:Notify({Title = "Config", Content = "Сохранён: " .. name, Type = "Success", Duration = 3})
        else
            Window:Notify({Title = "Config", Content = "Ошибка: " .. tostring(err), Type = "Error", Duration = 4})
        end
    end,
})

SettingsTab:Button({
    Name = "Load Config",
    Desc = "Загрузить ВСЁ",
    Icon = "lucide:folder-open",
    Callback = function()
        local name = ConfigNameInput:Get()
        if not name or #name == 0 then
            Window:Notify({Title = "Config", Content = "Выбери конфиг", Type = "Warning", Duration = 3})
            return
        end
        local ok, err = Window:LoadConfig(name)
        LoadExtra(name)  -- ← загружаем extra
        if ok then
            Window:Notify({Title = "Config", Content = "Загружен: " .. name, Type = "Success", Duration = 3})
        else
            Window:Notify({Title = "Config", Content = "Ошибка: " .. tostring(err), Type = "Error", Duration = 4})
        end
    end,
})

SettingsTab:Button({
    Name = "Delete Config",
    Desc = "Удалить конфиг",
    Icon = "lucide:trash-2",
    Style = "Danger",
    Callback = function()
        local name = ConfigNameInput:Get()
        if not name or #name == 0 then
            Window:Notify({Title = "Config", Content = "Выбери конфиг", Type = "Warning", Duration = 3})
            return
        end
        Window:Confirm({
            Title = "Delete Config",
            Content = "Удалить '" .. name .. "'?",
            ConfirmText = "Удалить",
            Callback = function()
                local ok = Window:DeleteConfig(name)
                -- удаляем extra файл
                if delfile and isfile and isfile(GetExtraPath(name)) then
                    pcall(delfile, GetExtraPath(name))
                end
                if ok then
                    RefreshConfigList()
                    if GetAutoLoadConfig() == name then ClearAutoLoadConfig() end
                    Window:Notify({Title = "Config", Content = "Удалён: " .. name, Type = "Success", Duration = 3})
                end
            end,
        })
    end,
})

SettingsTab:Toggle({
    Name = "Auto Save",
    Desc = "Автосохранение",
    Default = false,
    Callback = function(value) Window:SetAutoSave(value) end,
})

local AutoLoadToggle = SettingsTab:Toggle({
    Name = "Auto Load",
    Desc = "Загружать при старте",
    Default = GetAutoLoadConfig() ~= nil,
    Callback = function(value)
        if value then
            local name = ConfigNameInput:Get()
            if not name or #name == 0 then
                Window:Notify({Title = "Auto Load", Content = "Введи имя", Type = "Warning", Duration = 3})
                task.spawn(function() task.wait(0.05)
                    pcall(function() AutoLoadToggle:Set(false) end)
                    pcall(function() AutoLoadToggle:SetValue(false) end)
                end)
                return
            end
            local configs = Window:ListConfigs()
            local exists = false
            for _, c in ipairs(configs) do if c == name then exists = true break end end
            if not exists then
                Window:Notify({Title = "Auto Load", Content = "Не найден: " .. name, Type = "Warning", Duration = 3})
                task.spawn(function() task.wait(0.05)
                    pcall(function() AutoLoadToggle:Set(false) end)
                    pcall(function() AutoLoadToggle:SetValue(false) end)
                end)
                return
            end
            SetAutoLoadConfig(name)
            Window:Notify({Title = "Auto Load", Content = "При старте: " .. name, Type = "Success", Duration = 3})
        else
            ClearAutoLoadConfig()
            Window:Notify({Title = "Auto Load", Content = "Отключён", Type = "Info", Duration = 3})
        end
    end,
})

-- ═══════════════════════════════════════════════════════════
-- 9. УВЕДОМЛЕНИЕ
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(1)
    pcall(function()
        Window:Notify({
            Title = "Synapse",
            Content = "Загружено! RightShift — открыть",
            Type = "Success",
            Duration = 5
        })
    end)
end)

-- ═══ Keybind: Speed Boost (просто toggle) ═══
-- Speed Boost — только toggle ON/OFF
RegisterKeybind("SpeedBoost", "Speed Boost", Enum.KeyCode.B, function(state)
    SpeedEnabled = state
end, "Toggle")

-- Noclip — через общую точку SetNoclip
RegisterKeybind("Noclip", "Noclip", Enum.KeyCode.N, function(state)
    SetNoclip(state, false)
end, "Toggle")

-- ═══ Rebind UI в Settings ═══

SettingsTab:Section({Name = "Keybinds"})

local RebindBtns = {}

local function GetKeyName(id)
    local kb = KeybindRegistry[id]
    return kb and kb.Key and kb.Key.Name or "?"
end

RebindBtns.Speed = SettingsTab:Button({
    Name = "Rebind Speed Boost",
    Desc = "Клавиша: " .. GetKeyName("SpeedBoost"),
    Icon = "lucide:keyboard",
    Callback = function()
        RebindingId = "SpeedBoost"
        pcall(function()
            Window:Notify({Title = "Rebind", Content = "Нажми новую клавишу", Type = "Info", Duration = 3})
        end)
    end,
})

RebindBtns.Noclip = SettingsTab:Button({
    Name = "Rebind Noclip",
    Desc = "Клавиша: " .. GetKeyName("Noclip"),
    Icon = "lucide:keyboard",
    Callback = function()
        RebindingId = "Noclip"
        pcall(function()
            Window:Notify({Title = "Rebind", Content = "Нажми новую клавишу", Type = "Info", Duration = 3})
        end)
    end,
})

-- ═══ Функция обновления описания (только при rebind) ═══
_G.UpdateRebindDesc = function(id)
    local keyName = GetKeyName(id)
    if id == "SpeedBoost" and RebindBtns.Speed then
        pcall(function() RebindBtns.Speed:SetDesc("Клавиша: " .. keyName) end)
        lastRebindDesc.Speed = keyName
    elseif id == "Noclip" and RebindBtns.Noclip then
        pcall(function() RebindBtns.Noclip:SetDesc("Клавиша: " .. keyName) end)
        lastRebindDesc.Noclip = keyName
    end
end

-- ═══ Polling: обновляем Desc у Rebind-кнопок ═══
local lastRebindDesc = {}
task.spawn(function()
    while task.wait(0.5) do
        if _G.SynapseUnloaded then break end
        if not KeybindRegistry then continue end
        
        -- SpeedBoost
        local kb = KeybindRegistry["SpeedBoost"]
        if kb and RebindBtns.Speed then
            local currentKey = kb.Key and kb.Key.Name or "?"
            if lastRebindDesc.Speed ~= currentKey then
                lastRebindDesc.Speed = currentKey
                pcall(function() RebindBtns.Speed:SetDesc("Клавиша: " .. currentKey) end)
            end
        end
        
        -- Noclip
        kb = KeybindRegistry["Noclip"]
        if kb and RebindBtns.Noclip then
            local currentKey = kb.Key and kb.Key.Name or "?"
            if lastRebindDesc.Noclip ~= currentKey then
                lastRebindDesc.Noclip = currentKey
                pcall(function() RebindBtns.Noclip:SetDesc("Клавиша: " .. currentKey) end)
            end
        end
    end
end)

-- ═══ Polling: синхронизация keybind list с флагами ═══
_G.SynapseUnloaded = false

task.spawn(function()
    while task.wait(0.3) do
        if _G.SynapseUnloaded then break end
        if KeybindRegistry and RefreshKeybindList then
            local changed = false
            if KeybindRegistry["Noclip"] and KeybindRegistry["Noclip"].State ~= NoclipEnabled then
                KeybindRegistry["Noclip"].State = NoclipEnabled
                changed = true
            end
            if KeybindRegistry["SpeedBoost"] and KeybindRegistry["SpeedBoost"].State ~= SpeedEnabled then
                KeybindRegistry["SpeedBoost"].State = SpeedEnabled
                changed = true
            end
            if changed then pcall(RefreshKeybindList) end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO LOAD AT STARTUP
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(1.5)
    local HttpService = game:GetService("HttpService")
    local AUTOLOAD_FILE = "Synapse/autoload.txt"
    if not (isfile and readfile and isfile(AUTOLOAD_FILE)) then return end

    local ok, name = pcall(readfile, AUTOLOAD_FILE)
    if not ok or not name then return end
    name = name:gsub("%s+$", "")
    if #name == 0 then return end

    local configs = Window:ListConfigs()
    local exists = false
    for _, c in ipairs(configs) do if c == name then exists = true break end end

    if not exists then
        warn("[AutoLoad] Конфиг '" .. name .. "' не найден")
        if delfile then pcall(delfile, AUTOLOAD_FILE) end
        return
    end

    local success, err = Window:LoadConfig(name)
    if not success then
        warn("[AutoLoad] Ошибка: " .. tostring(err))
        return
    end

    -- ═══ Загружаем extra ═══
    local extraPath = "AirflowUI/" .. name .. "_extra.json"
    if isfile and isfile(extraPath) and readfile then
        local ok2, content = pcall(readfile, extraPath)
        if ok2 and content then
            local ok3, data = pcall(function() return HttpService:JSONDecode(content) end)
            if ok3 and type(data) == "table" then
                -- Menu keybind
                if data.MenuKeybind then
                    local kc = Enum.KeyCode[data.MenuKeybind]
                    if kc and Window.SetKeybind then
                        pcall(function() Window:SetKeybind(kc) end)
                    end
                end
                -- Keybind list
                if data.KeybindListEnabled ~= nil then
                    KeybindListEnabled = data.KeybindListEnabled
                    if KeybindListEnabled and CreateKeybindGui then pcall(CreateKeybindGui) end
                end
                -- Colors: восстанавливаем перед применением
                if data.GlobalColor then
                    GlobalColor = Color3.new(data.GlobalColor[1], data.GlobalColor[2], data.GlobalColor[3])
                end
                if data.DoorESP_Color then
                    DoorESP_Color = Color3.new(data.DoorESP_Color[1], data.DoorESP_Color[2], data.DoorESP_Color[3])
                end
                if data.KeyESP_Color then
                    KeyESP_Color = Color3.new(data.KeyESP_Color[1], data.KeyESP_Color[2], data.KeyESP_Color[3])
                end
                if data.LockerESP_Color then
                    LockerESP_Color = Color3.new(data.LockerESP_Color[1], data.LockerESP_Color[2], data.LockerESP_Color[3])
                end
                if data.ESPColorGlobal ~= nil then ESPColorGlobal = data.ESPColorGlobal end
                if data.ESPColorActive then
                    for k, v in pairs(data.ESPColorActive) do ESPColorActive[k] = v end
                end
                
                -- ═══ Применяем per-ESP цвета ОТДЕЛЬНО ═══
                if ApplyColorToESP then
                    pcall(ApplyColorToESP, "DoorESP", DoorESP_Color)
                    pcall(ApplyColorToESP, "KeyESP", KeyESP_Color)
                    pcall(ApplyColorToESP, "LockerESP", LockerESP_Color)
                end
                
                -- Keybinds: клавиши
                if data.Keybinds and KeybindRegistry then
                    for id, keyName in pairs(data.Keybinds) do
                        local kc = Enum.KeyCode[keyName]
                        if kc and KeybindRegistry[id] then
                            KeybindRegistry[id].Key = kc
                        end
                    end
                end
                -- Keybind states + callback
                if data.KeybindStates and KeybindRegistry then
                    for id, state in pairs(data.KeybindStates) do
                        local kb = KeybindRegistry[id]
                        if kb then
                            kb.State = state
                            if kb.Callback then pcall(kb.Callback, state) end
                        end
                    end
                end
                if RefreshKeybindList then pcall(RefreshKeybindList) end
            end
        end
    end

    print("[AutoLoad] Загружен: " .. name)
    
    -- ═══ Обновляем Desc у Rebind-кнопок ═══
    if _G.UpdateRebindDesc then
        pcall(_G.UpdateRebindDesc, "SpeedBoost")
        pcall(_G.UpdateRebindDesc, "Noclip")
    end
    
    pcall(function()
        Window:Notify({Title = "Auto Load", Content = "Загружен: " .. name, Type = "Success", Duration = 4})
    end)
end)

print("FROV")
