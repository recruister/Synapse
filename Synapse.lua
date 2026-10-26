	if delfile then
		pcall(delfile, "Synapse/Airflow_patched.luau")
		pcall(delfile, "Synapse/Airflow.luau")
	end
	
	if _G.SynapseLoaded then
		-- Если скрипт уже запущен, просто выводим сообщение и прерываем выполнение нового
		warn("[Synapse] Скрипт уже запущен! Нажми Unload в меню, если хочешь перезагрузить его.")
		return
	end
	_G.SynapseLoaded = true
	_G.SynapseUnloaded = false

	_G.KeybindRegistry = {}
	_G.RebindBtns = _G.RebindBtns or {}
	local Airflow
	local URL = "https://raw.githubusercontent.com/recruister/AFUFS/refs/heads/main/Source.lua"

	if isfile and isfile("Synapse/Airflow.luau") and readfile then
		local ok, cached = pcall(readfile, "Synapse/Airflow.luau")
		if ok and cached and #cached > 1000 then
			Airflow = loadstring(cached)()
		end
	end
	if not Airflow then
		local src = game:HttpGet(URL)
		if writefile and makefolder then
			if not isfolder("Synapse") then makefolder("Synapse") end
			pcall(writefile, "Synapse/Airflow.luau", src)
		end
		Airflow = loadstring(src)()
	end
	
	local CleanupRegistry = {}

	local function RegisterCleanup(name, fn)
		table.insert(CleanupRegistry, {Name = name, Fn = fn})
	end

		

	local function RunAllCleanups()
		pcall(function()
			local roots = {LocalPlayer:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
			for _, root in ipairs(roots) do
				if root then
					for _, obj in ipairs(root:GetDescendants()) do
						local n = obj.Name
						if n:find("NL_") or n:find("Synapse") or n:find("Airflow") or n:find("StartDoorESP") then
							obj:Destroy()
						end
					end
				end
			end
		end)
		
		for _, entry in ipairs(CleanupRegistry) do
			local ok, err = pcall(entry.Fn)
			if not ok then
				warn("[Synapse] Cleanup error for " .. entry.Name .. ": " .. tostring(err))
			end
		end
	end
	
		-- ═══ ОЧИСТКА ФАНТОМОВ ОТ ПРОШЛОГО ИНЖЕКТА ═══
	pcall(function()
		local roots = {LocalPlayer:FindFirstChild("PlayerGui"), game:GetService("CoreGui"), gethui and gethui()}
		for _, root in ipairs(roots) do
			if root then
				for _, obj in ipairs(root:GetDescendants()) do
					local n = obj.Name
					if n:find("NL_EntityESP") or n:find("NL_DoorESP") or n:find("NL_LeverESP") or n:find("NL_LockerESP") or n:find("NL_KeyESP") or n:find("NL_GenESP") then
						obj:Destroy()
					end
				end
			end
		end
	end)
	
	local Window = Airflow:Window({
		Name = "Synapse",
		Subtitle = "v1.5",
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
	local TweenService = game:GetService("TweenService")
	
	function GetPlayerRoom()
		local rooms = workspace:FindFirstChild("GameplayFolder") and workspace.GameplayFolder:FindFirstChild("Rooms")
		if not rooms then return nil end

		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end

		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = {char}
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude

		local touchingParts = workspace:GetPartBoundsInBox(hrp.CFrame, Vector3.new(2, 2, 2), overlapParams)
		
		for _, part in ipairs(touchingParts) do
			local p = part
			while p and p ~= workspace do
				if p.Parent == rooms then
					return p
				end
				p = p.Parent
			end
		end

		return nil
	end

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
	local OriginalSwimSpeed = 18
	local SpeedValue = 0
	local SpeedEnabled = false
	local SwimmingModule = nil
	local SpeedConn = nil

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

	-- ═══ Находим Swimming модуль ═══
	local function FindSwimming()
		for _, obj in ipairs(game:GetDescendants()) do
			if obj:IsA("ModuleScript") and obj.Name == "Swimming" 
			   and obj:GetFullName():find("MainClient") then
				local ok, mod = pcall(require, obj)
				if ok and type(mod) == "table" then return mod end
			end
		end
		return nil
	end

	SwimmingModule = FindSwimming()
	if SwimmingModule then
		OriginalSwimSpeed = SwimmingModule.SwimmingSpeed or 18
	end

	-- ═══ Основной цикл ═══
	SpeedConn = RunService.RenderStepped:Connect(function()
		if not SpeedEnabled then return end
		if SpeedValue <= 0 then return end

		local char = LocalPlayer.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end

		local target = OriginalWalkSpeed + SpeedValue
		hum.WalkSpeed = target

		-- Underwater
		if SwimmingModule then
			pcall(function()
				SwimmingModule.SwimmingSpeed = OriginalSwimSpeed + SpeedValue
				SwimmingModule.CurrentSwimSpeed = OriginalSwimSpeed + SpeedValue
			end)
		end

		if hum.MoveDirection.Magnitude < 0.1 then return end
		local md = hum.MoveDirection
		local isSwimming = (hum:GetState() == Enum.HumanoidStateType.Swimming)

		pcall(function()
			if isSwimming then
				local swimSpeed = target * 1.3
				local tv = Vector3.new(md.X, 0, md.Z).Unit * swimSpeed
				hrp.AssemblyLinearVelocity = Vector3.new(tv.X, hrp.AssemblyLinearVelocity.Y, tv.Z)
			else
				local tv = Vector3.new(md.X, 0, md.Z).Unit * target
				hrp.AssemblyLinearVelocity = Vector3.new(tv.X, hrp.AssemblyLinearVelocity.Y, tv.Z)
			end
		end)
	end)

	-- ═══ SPEED BOOST (Кастомный аккордеон) ═══
	local SpeedBoostValue = 0
	local SpeedToggle = nil
	local SpeedSlider = nil

	-- 1. Создаем Тумблер
	SpeedToggle = ExploitsTab:Toggle({
		Name = "Speed Boost",
		Desc = "Включить ускорение",
		Default = false,
		Flag = "SpeedBoostEnabled",
		Callback = function(val)
			SpeedEnabled = val
			if SpeedSlider and SpeedSlider._frame then
				if val then
					SpeedSlider._frame.Visible = true
					TweenService:Create(SpeedToggle._frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 120)
					}):Play()
				else
					TweenService:Create(SpeedToggle._frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
						Size = UDim2.new(1, 0, 0, 56)
					}):Play()
					task.delay(0.3, function()
						if not SpeedEnabled then SpeedSlider._frame.Visible = false end
					end)
				end
			end
			
			if _G.KeybindRegistry and _G.KeybindRegistry["SpeedBoost"] then
				_G.KeybindRegistry["SpeedBoost"].State = val
				if RefreshKeybindList then RefreshKeybindList() end
			end
		end
	})

	-- 2. Создаем Слайдер
	SpeedSlider = ExploitsTab:Slider({
		Name = "Speed Value",
		Min = 0, Max = 100, Default = 0,
		Callback = function(val)
			SpeedBoostValue = val
			SpeedValue = val
		end
	})

	-- 3. ═══ МАГИЯ СЛИЯНИЯ ═══
	local sliderFrame = SpeedSlider._frame
	local toggleFrame = SpeedToggle._frame
	
	sliderFrame.Parent = toggleFrame
	sliderFrame.Position = UDim2.new(0, 0, 0, 56)
	sliderFrame.Size = UDim2.new(1, 0, 0, 64)
	sliderFrame.ZIndex = 2 
	
	-- Убираем фон и обводку ТОЛЬКО у контейнера слайдера
	sliderFrame.BackgroundTransparency = 1 
	local stroke = sliderFrame:FindFirstChildOfClass("UIStroke")
	if stroke then stroke:Destroy() end
	
	-- Поднимаем ZIndex у всего, что внутри слайдера, чтобы он был поверх тумблера
	for _, obj in ipairs(sliderFrame:GetDescendants()) do
		if obj:IsA("Frame") or obj:IsA("TextLabel") then
			obj.ZIndex = obj.ZIndex + 2
		end
	end
	
	toggleFrame.ClipsDescendants = true
	toggleFrame.Size = UDim2.new(1, 0, 0, 56)

	-- Прибиваем переключатель к верху
	for _, child in ipairs(toggleFrame:GetChildren()) do
		if child:IsA("Frame") and child ~= sliderFrame then
			child.Position = UDim2.new(1, -14, 0, 28) 
		end
	end
	
	RegisterCleanup("Speed", function()
		SpeedEnabled = false
		SpeedValue = 0
		
		-- ═══ ФИКС: Отключаем цикл ═══
		if SpeedConn then 
			SpeedConn:Disconnect() 
			SpeedConn = nil 
		end
		
		-- Сбрасываем скорость
		local hum = GetHumanoid()
		if hum then hum.WalkSpeed = OriginalWalkSpeed end
		if SwimmingModule then
			pcall(function()
				SwimmingModule.SwimmingSpeed = OriginalSwimSpeed
				SwimmingModule.CurrentSwimSpeed = OriginalSwimSpeed
			end)
		end
	end)

	-- ═══ NOCLIP ═══
local NoclipEnabled = false
local NoclipToggle = nil
local SavedCollisions = {}   -- [part] = true только для частей которые МЫ отключили

local function ApplyNoclipCollision()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            -- Запоминаем только те, что были true
            SavedCollisions[part] = true
            part.CanCollide = false
        end
    end
end

-- Восстанавливаем только то, что трогали
local function RestoreCollisions()
    for part, _ in pairs(SavedCollisions) do
        if part and part.Parent then
            part.CanCollide = true
        end
    end
    SavedCollisions = {}
end

local function SetNoclip(value, fromUI)
    if NoclipEnabled == value and not fromUI then return end
    NoclipEnabled = value

    if value then
        ApplyNoclipCollision()
    else
        RestoreCollisions()
    end

    -- Keybind list
    if _G.KeybindRegistry and _G.KeybindRegistry["Noclip"] then
        _G.KeybindRegistry["Noclip"].State = value
        if RefreshKeybindList then RefreshKeybindList() end
    end

    -- Синхронизация toggle
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

-- Цикл: пока включен — держим false
RunService.Stepped:Connect(function()
    if not NoclipEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            SavedCollisions[part] = true
            part.CanCollide = false
        end
    end
end)

-- Респавн: пересобрать список
LocalPlayer.CharacterAdded:Connect(function()
    SavedCollisions = {}
    task.wait(0.5)
    if NoclipEnabled then
        ApplyNoclipCollision()
    end
end)

NoclipToggle = ExploitsTab:Toggle({
    Name = "Noclip",
    Desc = "Проход сквозь стены",
    Default = false,
    Flag = "Noclip",
    Callback = function(value)
        SetNoclip(value, true)
    end,
})

RegisterCleanup("Noclip", function()
    NoclipEnabled = false
    RestoreCollisions()
    SavedCollisions = {}
end)

	-- ═══════════════════════════════════════════════════════════
	-- POSITION SPOOF (Bypass NDAngler)
	-- ═══════════════════════════════════════════════════════════
	if ExploitsTab then
		local SpoofEnabled = false
		local OriginalHipHeight = 2.1427671909332275
		local OriginalC1 = nil
		local SpoofConnection = nil
		local CrouchEvent = game:GetService("ReplicatedStorage"):FindFirstChild("CrouchEvent")

		local SpoofLoopConn = nil
		local SPOOF_DEPTH = 2.346 -- Точная цифра Абиссала

		local SpoofSavedCollisions = {} -- ═══ Новая таблица для запоминания коллизий ═══

		local function ApplySpoof()
			local char = LocalPlayer.Character
			if not char then return end
			
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			
			if hrp and hum then
				-- ═══ ФИКС: Запоминаем изначальные коллизии и отключаем их ═══
				SpoofSavedCollisions = {}
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						SpoofSavedCollisions[part] = part.CanCollide
						part.CanCollide = false
					end
				end

				-- 1. Двигаем HRP вниз
				hrp.CFrame = hrp.CFrame * CFrame.new(0, -SPOOF_DEPTH, 0)
				hum.HipHeight = 0.05
				
				-- 2. Постоянный цикл
				if SpoofLoopConn then SpoofLoopConn:Disconnect() end
				SpoofLoopConn = RunService.RenderStepped:Connect(function()
					if not SpoofEnabled then return end
					local currentChar = LocalPlayer.Character
					if not currentChar then return end
					
					local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
					local currentCollision = currentChar:FindFirstChild("Collision")
					local currentCollisionPart = currentChar:FindFirstChild("CollisionPart") or currentCollision
					
					if currentHrp then
						if currentCollision then
							currentCollision.Position = currentHrp.Position + Vector3.new(0, 2.328, 0)
						end
						if currentCollisionPart then
							currentCollisionPart.Position = currentHrp.Position + Vector3.new(0, 2.328, 0)
						end
						
						if CrouchEvent then
							pcall(function() CrouchEvent:FireServer(true, true) end)
						end
					end
				end)
			end
		end

		local function RemoveSpoof()
			local char = LocalPlayer.Character
			if not char then return end
			
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			
			if hrp and hum then
				-- Возвращаем HRP наверх
				hrp.CFrame = hrp.CFrame * CFrame.new(0, SPOOF_DEPTH, 0)
				hum.HipHeight = OriginalHipHeight
				
				-- ═══ ФИКС: Возвращаем ТОЛЬКО то, что было изначально ═══
				for part, originalState in pairs(SpoofSavedCollisions) do
					if part and part.Parent then
						part.CanCollide = originalState
					end
				end
				SpoofSavedCollisions = {}
				
				if SpoofLoopConn then 
					SpoofLoopConn:Disconnect() 
					SpoofLoopConn = nil 
				end
				
				if CrouchEvent then
					pcall(function() CrouchEvent:FireServer(false, true) end)
				end
			end
		end

		      PositionSpoofToggle = ExploitsTab:Toggle({
			Name = "Position Spoof",
			Desc = "Меняет позицию для сервера,против сущностей(НЕРАБОЧАЯ)",
			Default = false,
			Flag = "PositionSpoof",
			Callback = function(value)
				SpoofEnabled = value
				
				if value then
					ApplySpoof()
					if SpoofConnection then SpoofConnection:Disconnect() end
					SpoofConnection = RunService.Heartbeat:Connect(function()
						if SpoofEnabled then
							if tick() % 0.1 < 0.02 then
								if CrouchEvent then
									pcall(function() CrouchEvent:FireServer(true, true) end)
								end
							end
						end
					end)
				else
					RemoveSpoof()
					if SpoofConnection then
						SpoofConnection:Disconnect()
						SpoofConnection = nil
					end
				end
				
				-- ═══ СИНХРОНИЗАЦИЯ С КЕЙБИНДОМ ═══
				if _G.KeybindRegistry and _G.KeybindRegistry["PositionSpoof"] then
					_G.KeybindRegistry["PositionSpoof"].State = value
					if RefreshKeybindList then RefreshKeybindList() end
				end
			end
		})

		RegisterCleanup("PositionSpoof", function()
			SpoofEnabled = false
			RemoveSpoof()
			if SpoofConnection then
				SpoofConnection:Disconnect()
				SpoofConnection = nil
			end
		end)
	else
		warn("[Synapse] ОШИБКА: ExploitsTab не найден! Проверь, не удалил ли ты строку local ExploitsTab = Window:Tab({Name = 'Exploits'})")
	end

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
	if _G.SynapseUnloaded then return end
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
		Desc = "Позволяет прыгать",
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
			if _G.KeybindRegistry and _G.KeybindRegistry["AllowJump"] then
				_G.KeybindRegistry["AllowJump"].State = value
				if RefreshKeybindList then RefreshKeybindList() end
			end
		end,
	})

	-- ═══ Infinity Jump ═══
	InfinityJumpToggle = ExploitsTab:Toggle({
		Name = "Infinity Jump",
		Desc = "Позволяет бесконечно прыгать",
		Flag = "InfinityJump",
		Default = false,
		Callback = function(value)
			InfinityJumpEnabled = value
			if _G.KeybindRegistry and _G.KeybindRegistry["InfinityJump"] then
				_G.KeybindRegistry["InfinityJump"].State = value
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
-- EXPLOITS → BYPASS
-- ═══════════════════════════════════════════════════════════
ExploitsTab:Section({Name = "Bypass"})

	local AntiVoid_Enabled = false
	local LastSafePos = nil
	local LastSafeTime = 0

	ExploitsTab:Toggle({
		Name = "Bypass Void",
		Desc = "Телепорт назад при падении в бездну",
		Default = false,
		Flag = "BypassVoid",
		Callback = function(value)
			AntiVoid_Enabled = value
			if value then
				local char = LocalPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then LastSafePos = hrp.Position end
			else
				LastSafePos = nil
			end
		end,
	})

	task.spawn(function()
		while task.wait(0.1) do
			if _G.SynapseUnloaded then break end
			if not AntiVoid_Enabled then continue end

			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hrp or not hum then continue end

			local myPos = hrp.Position

			-- ═══ Стоим на земле → сохраняем позицию ═══
			if hum.FloorMaterial ~= Enum.Material.Air then
				LastSafePos = myPos
				LastSafeTime = tick()
			end

			-- ═══ Если мы в воздухе, проверяем, что под нами ═══
			if hum.FloorMaterial == Enum.Material.Air then
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {char}
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				
				-- Пускаем луч вниз на 1000 студов
				local result = workspace:Raycast(myPos, Vector3.new(0, -1000, 0), rayParams)
				
				if result and result.Instance then
					local hit = result.Instance
					local isVoid = false
					
					-- ═══ 1. Проверяем имя (Ocean / Ocena, как в диагностике) ═══
					if hit.Name:lower():find("ocean") or hit.Name:lower():find("ocena") then
						isVoid = true
					end
					
					-- ═══ 2. Проверяем черный неон (на всякий случай) ═══
					if hit:IsA("BasePart") and hit.Material == Enum.Material.Neon then
						local c = hit.Color
						if c.R < 0.1 and c.G < 0.1 and c.B < 0.1 then
							isVoid = true
						end
					end
					
					-- ═══ 3. Если это бездна — телепортируем ═══
					if isVoid then
						if LastSafePos and tick() - LastSafeTime > 0.2 then
							hrp.CFrame = CFrame.new(LastSafePos + Vector3.new(0, 3, 0))
							hrp.AssemblyLinearVelocity = Vector3.zero
						end
					end
				end
			end
		end
	end)

	RegisterCleanup("BypassVoid", function()
		AntiVoid_Enabled = false
		LastSafePos = nil
	end)

	-- ═══════════════════════════════════════════════════════════
	-- EXPLOITS → AUTOMATION
	-- ═══════════════════════════════════════════════════════════
	ExploitsTab:Section({Name = "Automation"})
	
	-- ═══════════════════════════════════════════════════════════
	-- AUTO INTERACT (Приоритет на сбор предметов)
	-- ═══════════════════════════════════════════════════════════
	local AutoInteract_Enabled = false
	local InteractCooldowns = {}

	local AutoInteract_Blacklist = {
		"Keypad", "Lock", "PasswordPaper", "HidePrompt", "ClimbPrompt", 
		"Elevator", "Tram"
	}

	-- ═══════════════════════════════════════════════════════════
	-- БАЗЫ ДАННЫХ (ЕДИНЫЙ ИСТОЧНИК ИСТИНЫ)
	-- ═══════════════════════════════════════════════════════════
	local ItemDB = {
		["NormalKeyCard"] = true,
		["CodeBreacher"] = true,
		["FlashBeacon"] = true,
		["Flashlight"] = true,
		["Medkit"] = true,
		["Lantern"] = true,
	}

	-- ═══ База номиналов (с дефисом на конце) ═══
	local CurrencyDB = {
		["Currency5-"] = 5,
		["Currency10-"] = 10,
		["Currency15-"] = 15,
		["Currency25-"] = 25,
		["Currency50-"] = 50,
		["Currency100-"] = 100,
		["Currency200-"] = 200,
		["Currency500-"] = 500,
	}
	
	CurrencyFilter = {
		[5] = true, [10] = true, [15] = true, [25] = true,
		[50] = true, [100] = true, [200] = true, [500] = true,
	}

	-- Умный парсер, который проверяет начало строки
	local function GetCurrencyValue(name)
		if not name then return nil end
		for prefix, val in pairs(CurrencyDB) do
			if string.sub(name, 1, #prefix) == prefix then
				return val
			end
		end
		return nil
	end

	local function IsBlacklisted(name)
		local n = name:lower()
		for _, word in ipairs(AutoInteract_Blacklist) do
			if n:find(word:lower()) then return true end
		end
		return false
	end

	-- ═══ ПОИСК СОСТОЯНИЯ ХРАНИЛИЩА (OpenValue / Closed) ═══
	local function GetStorageState(prompt)
		local current = prompt
		for i = 1, 10 do
			if not current or current == workspace then break end
			local openVal = current:FindFirstChild("OpenValue")
			if openVal and openVal:IsA("BoolValue") then return openVal.Value end
			local closedVal = current:FindFirstChild("Closed")
			if closedVal and closedVal:IsA("BoolValue") then return not closedVal.Value end
			current = current.Parent
		end
		return nil
	end

	task.spawn(function()
		while task.wait(0.1) do
			if _G.SynapseUnloaded then break end
			if not AutoInteract_Enabled then continue end

			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			local params = OverlapParams.new()
			params.FilterDescendantsInstances = {char}
			params.FilterType = Enum.RaycastFilterType.Exclude
			
			local parts = workspace:GetPartBoundsInRadius(hrp.Position, 20, params)
			local processedPrompts = {}
			
			local ItemsToGrab = {}
			local StoragesToOpen = {}

			-- 1. Собираем все доступные промпты
			for _, part in ipairs(parts) do
				local prompts = {}
				for _, d in ipairs(part:GetDescendants()) do
					if d:IsA("ProximityPrompt") then table.insert(prompts, d) end
				end
				if part.Parent then
					for _, d in ipairs(part.Parent:GetDescendants()) do
						if d:IsA("ProximityPrompt") then table.insert(prompts, d) end
					end
				end

				for _, prompt in ipairs(prompts) do
					if prompt.Enabled and not processedPrompts[prompt] then
						processedPrompts[prompt] = true
						
						local pName = "Unknown"
						local current = prompt.Parent
						while current and current ~= workspace do
							if ItemDB[current.Name] or GetCurrencyValue(current.Name) then
								pName = current.Name
								break
							elseif current:IsA("Model") then
								pName = current.Name
								break
							end
							current = current.Parent
						end

						local promptPart = prompt.Parent
						if not promptPart:IsA("BasePart") then
							promptPart = promptPart:FindFirstChildWhichIsA("BasePart", true) or part
						end
						local dist = (hrp.Position - promptPart.Position).Magnitude
						
						if dist <= (prompt.MaxActivationDistance + 10) and not IsBlacklisted(pName) then
							local currencyVal = GetCurrencyValue(pName)
							
							if ItemDB[pName] or currencyVal then
								local isKeycard = pName:lower():find("keycard")
								
								if isKeycard and HasKeycard() then
									-- Пропускаем карту
								else
									if not InteractCooldowns[prompt] or (tick() - InteractCooldowns[prompt]) > 1.5 then
										table.insert(ItemsToGrab, prompt)
									end
								end
							else
								local isOpen = GetStorageState(prompt)
								local isItemLocker = pName:lower():find("itemlocker")
								
								if isItemLocker and isOpen ~= nil then
									isOpen = not isOpen
								end

								if isOpen ~= true then 
									if not InteractCooldowns[prompt] or (tick() - InteractCooldowns[prompt]) > 2 then
										table.insert(StoragesToOpen, prompt)
									end
								end
							end
						end
					end
				end
			end

			-- 2. ═══ ПРИОРИТЕТ 1: Сначала собираем предметы ═══
			if #ItemsToGrab > 0 then
				for _, prompt in ipairs(ItemsToGrab) do
					pcall(function() fireproximityprompt(prompt) end)
					break -- Один предмет за тик
				end
			-- 3. ═══ ПРИОРИТЕТ 2: Если предметов нет, открываем ящики ═══
			elseif #StoragesToOpen > 0 then
				local now = tick()
				for _, prompt in ipairs(StoragesToOpen) do
					-- Кулдаун 1.5 сек, чтобы не спамить
					if not InteractCooldowns[prompt] or (now - InteractCooldowns[prompt]) > 1.5 then
						pcall(function() fireproximityprompt(prompt) end)
						InteractCooldowns[prompt] = now
						break -- Один ящик за тик
					end
				end
			end

			-- Очистка кулдаунов
			for p, t in pairs(InteractCooldowns) do
				if (tick() - t) > 10 then InteractCooldowns[p] = nil end
			end
		end
	end)

	     AutoInteractToggle = ExploitsTab:Toggle({
		Name = "Auto Interact",
		Desc = "Автоматическое взаимодействие(ПОЛУРАБОТАЮЩИЙ)",
		Default = false,
		Flag = "AutoInteract",
		Callback = function(value)
			AutoInteract_Enabled = value
			
			-- ═══ СИНХРОНИЗАЦИЯ С КЕЙБИНДОМ ═══
			if _G.KeybindRegistry and _G.KeybindRegistry["AutoInteract"] then
				_G.KeybindRegistry["AutoInteract"].State = value
				if RefreshKeybindList then RefreshKeybindList() end
			end
		end
	})

	RegisterCleanup("AutoInteract", function()
		AutoInteract_Enabled = false
		InteractCooldowns = {}
	end)

	local AutoCodeEnter_Enabled = false
	local LastEnteredDoor = nil
	local VIM = game:GetService("VirtualInputManager")

	local digitMap = {
		["0"] = Enum.KeyCode.Zero, ["1"] = Enum.KeyCode.One,
		["2"] = Enum.KeyCode.Two, ["3"] = Enum.KeyCode.Three,
		["4"] = Enum.KeyCode.Four, ["5"] = Enum.KeyCode.Five,
		["6"] = Enum.KeyCode.Six, ["7"] = Enum.KeyCode.Seven,
		["8"] = Enum.KeyCode.Eight, ["9"] = Enum.KeyCode.Nine,
	}

	local function ExtractCode(paper)
		if not paper then return nil end
		local cp = paper:FindFirstChild("Code", true)
		if cp then
			for _, d in ipairs(cp:GetDescendants()) do
				if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
					local lbl = d:FindFirstChildWhichIsA("TextLabel", true)
					if lbl and lbl.Text then
						local t = lbl.Text:match("^%d+$")
						if t then return t end
					end
				end
			end
		end
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

	local function FindLock()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local myPos = hrp.Position

		local nearest, nearestDist = nil, 12
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj.Name == "Lock" then
				local kp = obj:FindFirstChild("Keypad1")
				if kp then
					-- ═══ Keypad1 сам BasePart ИЛИ содержит BasePart ═══
					local pos = nil
					if kp:IsA("BasePart") then
						pos = kp.Position
					elseif kp:IsA("Model") then
						local pp = kp.PrimaryPart or kp:FindFirstChildWhichIsA("BasePart", true)
						if pp then pos = pp.Position end
					else
						local pp = kp:FindFirstChildWhichIsA("BasePart", true)
						if pp then pos = pp.Position end
					end

					if pos then
						local dist = (myPos - pos).Magnitude
						if dist < nearestDist then
							nearestDist = dist
							nearest = obj
						end
					end
				end
			end
		end
		return nearest
	end

	local function FindPaper()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local myPos = hrp.Position

		local nearest, nearestDist = nil, 150
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

local function EnterCode(lock, code)

    -- ═══ Находим UseKeypad ═══
    local uk = nil
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name == "UseKeypad" 
           and obj:GetFullName():find("MainClient") then
            local ok, mod = pcall(require, obj)
            if ok and type(mod) == "table" then uk = mod break end
        end
    end
    if not uk then 
        return 
    end

    -- ═══ Сохраняем камеру ДО ═══
    local cam = workspace.CurrentCamera
    local oldType = cam.CameraType
    local oldSubject = cam.CameraSubject
    local oldCFrame = cam.CFrame

    -- ═══ UI Keypad ═══
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local m = pg and pg:FindFirstChild("Main")
    local kpUI = nil
    if m then kpUI = m:FindFirstChild("Keypad") end

    -- ═══ БЛОКИРОВЩИК: каждый кадр скрывает UI + возвращает камеру ═══
    local blocker = RunService.RenderStepped:Connect(function()
        if kpUI and kpUI.Visible then kpUI.Visible = false end
        if uk.UI and uk.UI.Visible then uk.UI.Visible = false end
        if cam.CameraType ~= oldType then
            cam.CameraType = oldType
            cam.CameraSubject = oldSubject
            cam.CFrame = oldCFrame
        end
    end)

    -- ═══ МГНОВЕННО: Start без ожидания HoldDuration ═══
    pcall(function() uk.Start(lock) end)
    task.wait()  -- 1 кадр

    -- Ещё раз скрываем UI (мог появиться)
    if kpUI then kpUI.Visible = false end
    if uk.UI then uk.UI.Visible = false end

    -- ═══ ВВОД ЦИФР ═══
    for i = 1, #code do
        local kc = digitMap[code:sub(i, i)]
        if kc then
            VIM:SendKeyEvent(true, kc, false, game)
            VIM:SendKeyEvent(false, kc, false, game)
            task.wait(0.03)
        end
    end

    task.wait(0.05)

    -- ═══ Закрываем ═══
    pcall(function() uk.Stop() end)

    task.wait(0.02)

    -- ═══ Восстановление ═══
    if blocker then blocker:Disconnect() end
    pcall(function()
        cam.CameraType = oldType
        cam.CameraSubject = oldSubject
        cam.CFrame = oldCFrame
    end)

end

task.spawn(function()
    while task.wait(1) do
        if _G.SynapseUnloaded then break end
        if not AutoCodeEnter_Enabled then continue end

        local lock = FindLock()
        if not lock then 
            LastEnteredDoor = nil
            continue 
        end
        if LastEnteredDoor == lock then continue end

        local paper = FindPaper()
        if not paper then continue end

        local code = ExtractCode(paper)
        if not code then continue end

        LastEnteredDoor = lock
        task.spawn(function()
            EnterCode(lock, code)
        end)
    end
end)

	-- ═══ Toggle ═══
	ExploitsTab:Toggle({
		Name = "AutoCodeEnter",
		Desc = "Моментально вводит код от двери",
		Default = false,
		Flag = "AutoCodeEnter",
		Callback = function(value)
			AutoCodeEnter_Enabled = value
			if not value then LastEnteredDoor = nil end
		end,
	})

	RegisterCleanup("AutoCodeEnter", function()
		AutoCodeEnter_Enabled = false
		LastEnteredDoor = nil
	end)
	
	-- ═══════════════════════════════════════════════════════════
	-- AUTO KEYCARD (Мгновенное открытие дверей картой)
	-- ═══════════════════════════════════════════════════════════
	local AutoKeycard_Enabled = false
	local LastKeycardFire = 0

	-- ═══ ФИКС: Проверяем наличие карты через UI (AuxItems) ═══
	local function HasKeycard()
		if LocalPlayer.Backpack:FindFirstChild("NormalKeyCard") or LocalPlayer.Character:FindFirstChild("NormalKeyCard") then return true end
		if LocalPlayer.Backpack:FindFirstChild("InnerKeyCard") or LocalPlayer.Character:FindFirstChild("InnerKeyCard") then return true end
		
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		local main = pg and pg:FindFirstChild("Main")
		local health = main and main:FindFirstChild("Health")
		local aux = health and health:FindFirstChild("AuxItems")
		if aux then
			local normalCard = aux:FindFirstChild("NormalKeyCard")
			local innerCard = aux:FindFirstChild("InnerKeyCard")
			if normalCard and normalCard.Visible then return true end
			if innerCard and innerCard.Visible then return true end
		end
		return false
	end

	-- ═══ ФИКС: Ищем именно замок (Lock) у двери ═══
	local function FindKeycardPrompt()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		
		local myPos = hrp.Position
		local nearestPrompt = nil
		local minDist = 15 -- Радиус действия
		
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt") and obj.Enabled then
				local parent = obj.Parent
				-- В логе промпт лежит в Lock.Main.ProximityPrompt
				if parent and parent.Name == "Main" and parent.Parent and parent.Parent.Name == "Lock" then
					local part = parent:FindFirstChildWhichIsA("BasePart") or parent.Parent:FindFirstChildWhichIsA("BasePart", true)
					if part then
						local dist = (myPos - part.Position).Magnitude
						if dist < minDist then
							minDist = dist
							nearestPrompt = obj
						end
					end
				end
			end
		end
		return nearestPrompt
	end

	task.spawn(function()
		while task.wait(0.1) do
			if _G.SynapseUnloaded then break end
			if not AutoKeycard_Enabled then continue end
			if tick() - LastKeycardFire < 0.5 then continue end -- Кулдаун от спама
			
			if HasKeycard() then
				local prompt = FindKeycardPrompt()
				if prompt then
					-- Мгновенно триггерим промпт (обходим HoldDuration = 2)
					pcall(function()
						fireproximityprompt(prompt)
					end)
					
					LastKeycardFire = tick()
				end
			end
		end
	end)

	ExploitsTab:Toggle({
		Name = "Auto Keycard",
		Desc = "Моментально открывает двери картой",
		Default = false,
		Flag = "AutoKeycard",
		Callback = function(value)
			AutoKeycard_Enabled = value
		end
	})

	RegisterCleanup("AutoKeycard", function()
		AutoKeycard_Enabled = false
	end)
	
-- ═══════════════════════════════════════════════════════════
-- AutoPipePuzzle v14 (Строгий DFS, фикс дистанции и выключения)
-- ═══════════════════════════════════════════════════════════

local AutoPipe_Enabled = false
local AutoPipe_Conn = nil
local AutoPipe_LastRun = 0
local AutoPipe_Running = false
local AutoPipe_Marker = nil
local AutoPipe_Pipes = nil

local GREEN_COLOR = Color3.fromRGB(0, 167, 97)
local COLOR_TOL = 0.08
local ROTATE_DELAY = 0.2
local MARKER_RADIUS = 10 -- Увеличил маркер

local RunService = game:GetService("RunService")

local function IsGreenPipe(model)
    if not model then return false end
    local lp = model:FindFirstChild("LightPart")
    if not lp then return false end
    local c = lp.Color
    return math.abs(c.R - GREEN_COLOR.R) < COLOR_TOL
       and math.abs(c.G - GREEN_COLOR.G) < COLOR_TOL
       and math.abs(c.B - GREEN_COLOR.B) < COLOR_TOL
end

local function FindPuzzle()
    local rooms = workspace:FindFirstChild("GameplayFolder", true)
    rooms = rooms and rooms:FindFirstChild("Rooms", true)
    if not rooms then return nil end
    for _, room in ipairs(rooms:GetChildren()) do
        if room.Name:lower():find("pipe") then
            for _, board in ipairs(room:GetChildren()) do
                if board:IsA("Model") and board.Name:lower():find("board") then
                    local pf = board:FindFirstChild("puzzle")
                    if pf then return board, pf, room end
                end
            end
        end
    end
    return nil
end

local function GetPipePos(model)
    local hl = model:FindFirstChild("Highlight")
    if hl then return hl.Position end
    return nil
end

-- ═══ Универсальный поиск соседей ═══
local function GetNeighbors(pipe, allPipes)
    local myPos = GetPipePos(pipe)
    if not myPos then return {} end
    local neighbors = {}
    for _, other in ipairs(allPipes) do
        if other ~= pipe then
            local otherPos = GetPipePos(other)
            if otherPos then
                local d = myPos - otherPos
                local dist = d.Magnitude
                -- Ищем в радиусе 2.5 studs и проверяем, что это сосед по оси
                if dist > 0.5 and dist < 2.5 then
                    local dx, dy, dz = math.abs(d.X), math.abs(d.Y), math.abs(d.Z)
                    local smallDiffs = 0
                    if dx < 0.5 then smallDiffs = smallDiffs + 1 end
                    if dy < 0.5 then smallDiffs = smallDiffs + 1 end
                    if dz < 0.5 then smallDiffs = smallDiffs + 1 end
                    
                    if smallDiffs >= 2 then
                        table.insert(neighbors, other)
                    end
                end
            end
        end
    end
    return neighbors
end

local function CreateMarker(position)
    if AutoPipe_Marker then AutoPipe_Marker:Destroy() end
    local marker = Instance.new("Part")
    marker.Name = "NL_PipePuzzleMarker"
    marker.Shape = Enum.PartType.Cylinder
    marker.Size = Vector3.new(0.3, MARKER_RADIUS * 2, MARKER_RADIUS * 2)
    marker.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0)
    marker.Color = Color3.fromRGB(255, 140, 0)
    marker.Material = Enum.Material.Neon
    marker.Transparency = 0.5
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanQuery = false
    marker.CanTouch = false
    marker.Parent = workspace
    AutoPipe_Marker = marker
end

local function IsPlayerAtMarker()
    if not AutoPipe_Marker then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local dx = hrp.Position.X - AutoPipe_Marker.Position.X
    local dz = hrp.Position.Z - AutoPipe_Marker.Position.Z
    return math.sqrt(dx*dx + dz*dz) < MARKER_RADIUS + 2
end

-- ═══ Поворот с проверкой выключения ═══
local function RotatePipeSafe(model)
    if not AutoPipe_Enabled then return false end -- Мгновенный выход
    
    local hl = model:FindFirstChild("Highlight")
    if not hl then return false end
    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then return false end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Ограничение 15 studs (вместо стандартных 7)
    if (hrp.Position - hl.Position).Magnitude > 15 then
        return false
    end
    
    local beforeZ = hl.Orientation.Z
    local ok = pcall(function() fireproximityprompt(prompt) end)
    if not ok then return false end
    task.wait(ROTATE_DELAY)
    
    return math.abs(beforeZ - hl.Orientation.Z) > 1
end

-- ═══ Строгий DFS ═══
local function SolveDFS(currentPipe, allPipes, visited, depth)
    if not AutoPipe_Enabled then return false end
    if depth > 50 then return false end
    
    if currentPipe.Name == "End" and IsGreenPipe(currentPipe) then return true end
    
    visited[currentPipe] = true
    local neighbors = GetNeighbors(currentPipe, allPipes)
    
    -- Шаг 1: Ищем ТОЛЬКО серых соседей
    local grayNeighbors = {}
    for _, n in ipairs(neighbors) do
        if not IsGreenPipe(n) and n.Name ~= "End" and n.Name ~= "First" and not visited[n] then
            table.insert(grayNeighbors, n)
        end
    end
    
    for _, neighbor in ipairs(grayNeighbors) do
        if not AutoPipe_Enabled then return false end
        
        -- Крутим соседа 4 раза
        for rot = 1, 4 do
            if RotatePipeSafe(neighbor) then
                if IsGreenPipe(neighbor) then
                    if SolveDFS(neighbor, allPipes, visited, depth + 1) then return true end
                    break -- Если вглубь не пробились, переходим к следующему соседу
                end
            end
        end
    end
    
    -- Шаг 2: Если все серые тупики - крутим САМУ текущую трубу
    if currentPipe.Name ~= "First" then
        
        for rot = 1, 4 do
            if not AutoPipe_Enabled then return false end
            
            if RotatePipeSafe(currentPipe) then
                if IsGreenPipe(currentPipe) then
                    -- Ищем новых соседей после поворота
                    local newNeighbors = GetNeighbors(currentPipe, allPipes)
                    for _, n in ipairs(newNeighbors) do
                        if not visited[n] and n.Name ~= "First" then
                            if IsGreenPipe(n) then
                                if SolveDFS(n, allPipes, visited, depth + 1) then return true end
                            elseif n.Name ~= "End" then
                                for r2 = 1, 4 do
                                    if RotatePipeSafe(n) then
                                        if IsGreenPipe(n) then
                                            if SolveDFS(n, allPipes, visited, depth + 1) then return true end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    visited[currentPipe] = nil
    return false
end

-- ═══ Запуск ═══
local function SolvePuzzle(pf, pipes)
    local first = nil
    for _, p in ipairs(pipes) do
        if p.Name == "First" then first = p break end
    end
    if not first then return end

    local visited = {}
    local success = SolveDFS(first, pipes, visited, 1)

    if success then
    else
    end
end

local function SetupPuzzle()
    local board, pf, room = FindPuzzle()
    if not pf then return false end

    local pipes = {}
    for _, obj in ipairs(pf:GetChildren()) do
        if obj:IsA("Model") and (obj.Name == "Straight" or obj.Name == "Corner" 
           or obj.Name == "3Way" or obj.Name == "End" or obj.Name == "First") then
            table.insert(pipes, obj)
        end
    end
    if #pipes == 0 then return false end
    AutoPipe_Pipes = pipes

    -- ═══ ФИКС ДИСТАНЦИИ: Увеличиваем радиус активации промптов ═══
    for _, p in ipairs(pipes) do
        local prompt = p:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            prompt.MaxActivationDistance = 20
        end
    end

    local minY = math.huge
    local sumX, sumZ, count = 0, 0, 0
    for _, p in ipairs(pipes) do
        local pos = GetPipePos(p)
        if pos then
            if pos.Y < minY then minY = pos.Y end
            sumX = sumX + pos.X
            sumZ = sumZ + pos.Z
            count = count + 1
        end
    end
    local centerX = sumX / count
    local centerZ = sumZ / count

    CreateMarker(Vector3.new(centerX, minY - 3, centerZ))
    return true
end

ExploitsTab:Toggle({
    Name = "AutoPipePuzzle",
    Desc = "Сам собирает паззл с трубами(НЕРАБОЧАЯ)",
    Default = false, Flag = "AutoPipePuzzle",
    Callback = function(value)
        AutoPipe_Enabled = value
        if value then 
            SetupPuzzle() 
        else 
            if AutoPipe_Marker then AutoPipe_Marker:Destroy() AutoPipe_Marker = nil end
            AutoPipe_Pipes = nil
        end
    end,
})

AutoPipe_Conn = RunService.Heartbeat:Connect(function()
    if _G.SynapseUnloaded then return end
    if not AutoPipe_Enabled or AutoPipe_Running or not AutoPipe_Pipes then return end
    if not IsPlayerAtMarker() then return end
    if tick() - AutoPipe_LastRun < 5 then return end
    AutoPipe_LastRun = tick()
    
    AutoPipe_Running = true
    task.spawn(function()
        pcall(function()
            local pf = AutoPipe_Pipes[1].Parent
            if pf then SolvePuzzle(pf, AutoPipe_Pipes) end
        end)
        AutoPipe_Running = false
    end)
end)

RegisterCleanup("AutoPipePuzzle", function()
    AutoPipe_Enabled = false
    AutoPipe_Pipes = nil
    if AutoPipe_Marker then AutoPipe_Marker:Destroy() end
    if AutoPipe_Conn then AutoPipe_Conn:Disconnect() AutoPipe_Conn = nil end
end)

-- ═══════════════════════════════════════════════════════════
-- AutoGenerator (Ждет открытия UI и жмет кнопку)
-- ═══════════════════════════════════════════════════════════
local AutoGen_Enabled = false
local AutoGen_CurrentGen = nil

local function FindGenerator()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position

    local nearest, nearestDist = nil, 20
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("generator") or obj.Name:lower():find("gen")) then
            local part = obj:FindFirstChild("ProxyPart") or obj:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local dist = (myPos - part.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

local function FixGenerator(gen)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local proxy = gen:FindFirstChild("ProxyPart")
    local proxyPos = proxy and proxy.Position or gen:GetPivot().Position
    
    -- Сервер требует быть в 5 студах
    if (hrp.Position - proxyPos).Magnitude > 5 then return end

    local remoteFunc = gen:FindFirstChild("RemoteFunction")
    local remoteEvent = gen:FindFirstChild("RemoteEvent")
    
    if not remoteFunc or not remoteEvent then
        return
    end

    -- 1. Занимаем генератор (InvokeServer)
    local success, result = pcall(function()
        return remoteFunc:InvokeServer()
    end)
    
    if not success or not result then
        return -- Не удалось занять (например, далеко или занят)
    end

    -- 2. Отправляем "Успех" 5 раз с задержкой
    for i = 1, 5 do
        if not AutoGen_Enabled then break end
        if not hrp or not gen.Parent then break end
        
        -- Проверяем, не отошли ли мы
        if (hrp.Position - proxyPos).Magnitude > 6.5 then break end
        
        -- Проверяем, не починили ли его уже
        local fixedVal = gen:FindFirstChild("Fixed", true)
        if fixedVal and fixedVal.Value >= 100 then break end
        
        -- Отправляем true на сервер (обходим кулдаун 0.3с)
        pcall(function()
            remoteEvent:FireServer(true)
        end)
        
        task.wait(0.35) 
    end
    
end

ExploitsTab:Toggle({
    Name = "AutoGenerator",
    Desc = "Сам чинит генераторы",
    Default = false, 
    Flag = "AutoGenerator",
    Callback = function(value)
        AutoGen_Enabled = value
        if not value then AutoGen_CurrentGen = nil end
    end,
})

task.spawn(function()
    while task.wait(0.2) do
        if _G.SynapseUnloaded then break end
        if not AutoGen_Enabled then 
            AutoGen_CurrentGen = nil
            continue 
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        local gen = FindGenerator()
        if gen then
            local proxy = gen:FindFirstChild("ProxyPart")
            local proxyPos = proxy and proxy.Position or gen:GetPivot().Position
            local dist = (hrp.Position - proxyPos).Magnitude
            
            -- Ждем, пока подойдем на 5 студов
            if dist <= 5 then
                if gen ~= AutoGen_CurrentGen then
                    AutoGen_CurrentGen = gen
                    task.spawn(function()
                        FixGenerator(gen)
                        -- Кулдаун после попытки, чтобы не спамить
                        task.wait(2) 
                        AutoGen_CurrentGen = nil 
                    end)
                end
            end
        else
            AutoGen_CurrentGen = nil
        end
    end
end)

RegisterCleanup("AutoGenerator", function()
    AutoGen_Enabled = false
    AutoGen_CurrentGen = nil
end)

	local VisualsTab  = Window:Tab({Name = "Visuals"})
	local SettingsTab = Window:Tab({Name = "Settings"})

	-- ═══════════════════════════════════════════════════════════
	-- KEYBIND SYSTEM
	-- ═══════════════════════════════════════════════════════════
	      _G.KeybindRegistry = {}
	local KeybindGui = nil
	local KeybindListEnabled = false
	local RebindingId = nil
	local CurRomGui = nil
	local CurRomLabel = nil
	local CurRomEnabled = false
	local DBListEnabled = false

	function RegisterKeybind(id, name, defaultKey, callback, mode)
		_G.KeybindRegistry = _G.KeybindRegistry or {}
		_G.KeybindRegistry[id] = {
			Id = id, Name = name, Key = defaultKey,
			Callback = callback, Mode = mode or "Toggle", State = false,
		}
	end
	
	function CreateKeybindSquare(toggle, id)
		if not toggle or not toggle._frame then return end
		_G.KeybindRegistry = _G.KeybindRegistry or {}
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(24, 24)
		btn.AnchorPoint = Vector2.new(0.5, 0.5)
		
		if id == "SpeedBoost" then
			btn.Position = UDim2.new(1, -70, 0, 28)
		else
			btn.Position = UDim2.new(1, -70, 0.5, 0)
		end
		btn.ZIndex = 10
		
		-- ═══ ТЕМНЫЕ ЦВЕТА КАК У МЕНЮ ═══
		btn.BackgroundColor3 = Color3.fromRGB(45, 38, 50) -- Темный, с легким фиолетовым оттенком
		btn.TextColor3 = Color3.fromRGB(200, 200, 210) -- Светло-серый текст
		
		local kb = _G.KeybindRegistry[id]
		btn.Text = kb and kb.Key and kb.Key.Name or "?"
		
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.AutoButtonColor = false
		btn.BorderSizePixel = 0
		btn.Parent = toggle._frame
		
		local corner = Instance.new("UICorner", btn)
		corner.CornerRadius = UDim.new(0, 6)
		
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = Color3.fromRGB(70, 55, 80) -- Темно-фиолетовая обводка
		stroke.Thickness = 1
		stroke.Transparency = 0.2
		
		-- ═══ ЭФФЕКТ НАВЕДЕНИЯ ═══
		btn.MouseEnter:Connect(function()
			if RebindingState ~= id then
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 50, 65)}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if RebindingState ~= id then
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 38, 50)}):Play()
			end
		end)

		btn.MouseButton1Click:Connect(function()
			RebindingState = id
			btn.Text = "..."
			btn.TextColor3 = Color3.fromRGB(255, 200, 100) -- Оранжевый при ребинде
			
			local conn
			conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				
				if input.KeyCode == Enum.KeyCode.Escape then
					conn:Disconnect()
					btn.Text = kb and kb.Key and kb.Key.Name or "?"
					btn.TextColor3 = Color3.fromRGB(200, 200, 210)
					RebindingState = nil
					return
				end
				
				if _G.KeybindRegistry[id] then
					_G.KeybindRegistry[id].Key = input.KeyCode
				end
				if Window and Window._autoSave then pcall(function() Window:_autoSave() end) end
				
				btn.Text = input.KeyCode.Name
				btn.TextColor3 = Color3.fromRGB(200, 200, 210)
				RebindingState = nil
				conn:Disconnect()
				
				if RefreshKeybindList then RefreshKeybindList() end
			end)
		end)
		
		_G.RebindBtns[id] = btn
		
	end

	     function RefreshKeybindList()
		if not KeybindGui then return end
		_G.KeybindRegistry = _G.KeybindRegistry or {}
		for _, child in ipairs(KeybindGui:GetChildren()) do
			if child:IsA("Frame") and child.Name == "Row" then child:Destroy() end
		end
		local sorted = {}
		for _, kb in pairs(_G.KeybindRegistry) do table.insert(sorted, kb) end
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
	
		-- ═══ НОВОЕ: Создание экранчика CurRom ═══
	local function CreateCurRomGui()
		if CurRomGui then return end
		local screen = Instance.new("ScreenGui")
		screen.Name = "Synapse_CurRom"
		screen.ResetOnSpawn = false
		screen.Parent = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

		local frame = Instance.new("Frame")
		frame.Name = "Main"
		-- ═══ ФИКС: Базовый размер 0, включена авто-подстройка ═══
		frame.Size = UDim2.new(0, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.XY
		frame.Position = UDim2.new(0, 20, 0, 150)
		frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		frame.BackgroundTransparency = 0.15
		frame.BorderSizePixel = 0
		frame.Active = true
		frame.Parent = screen

		local corner = Instance.new("UICorner", frame)
		corner.CornerRadius = UDim.new(0, 6)

		local stroke = Instance.new("UIStroke", frame)
		stroke.Color = Color3.fromRGB(80, 60, 120)
		stroke.Thickness = 1
		stroke.Transparency = 0.3

		-- ═══ ФИКС: Внутренние отступы, чтобы текст не прилипал к краям ═══
		local padding = Instance.new("UIPadding", frame)
		padding.PaddingTop = UDim.new(0, 8)
		padding.PaddingBottom = UDim.new(0, 8)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)

		local layout = Instance.new("UIListLayout", frame)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 2)

		local title = Instance.new("TextLabel", frame)
		title.Name = "Title"
		title.Size = UDim2.new(0, 0, 0, 20)
		title.AutomaticSize = Enum.AutomaticSize.X
		title.BackgroundTransparency = 1
		title.Text = "Current Room"
		title.TextColor3 = Color3.fromRGB(220, 220, 230)
		title.TextSize = 12
		title.Font = Enum.Font.GothamBold
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.LayoutOrder = 1

		CurRomLabel = Instance.new("TextLabel", frame)
		CurRomLabel.Size = UDim2.new(0, 0, 0, 20)
		CurRomLabel.AutomaticSize = Enum.AutomaticSize.X
		CurRomLabel.BackgroundTransparency = 1
		CurRomLabel.Text = "Unknown"
		CurRomLabel.TextColor3 = Color3.fromRGB(180, 130, 255)
		CurRomLabel.TextSize = 14
		CurRomLabel.Font = Enum.Font.GothamBold
		CurRomLabel.TextXAlignment = Enum.TextXAlignment.Left
		CurRomLabel.LayoutOrder = 2

		-- Перетаскивание (оставляем как было)
		local dragging, dragStart, startPos
		title.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = frame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)

		CurRomGui = frame
	end
	
		local DBListGui = nil
	local DBListLabel = nil

	local function CreateDBListGui()
		if DBListGui then return end
		local screen = Instance.new("ScreenGui")
		screen.Name = "Synapse_DBList"
		screen.ResetOnSpawn = false
		screen.Parent = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

		local frame = Instance.new("Frame")
		frame.Name = "Main"
		frame.Size = UDim2.new(0, 0, 0, 0)
		frame.AutomaticSize = Enum.AutomaticSize.XY
		frame.Position = UDim2.new(0, 20, 0, 220)
		frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		frame.BackgroundTransparency = 0.15
		frame.BorderSizePixel = 0
		frame.Active = true
		frame.Parent = screen

		local corner = Instance.new("UICorner", frame)
		corner.CornerRadius = UDim.new(0, 6)

		local stroke = Instance.new("UIStroke", frame)
		stroke.Color = Color3.fromRGB(80, 60, 120)
		stroke.Thickness = 1
		stroke.Transparency = 0.3

		local padding = Instance.new("UIPadding", frame)
		padding.PaddingTop = UDim.new(0, 8)
		padding.PaddingBottom = UDim.new(0, 8)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)

		local layout = Instance.new("UIListLayout", frame)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 2)

		local title = Instance.new("TextLabel", frame)
		title.Name = "Title"
		title.Size = UDim2.new(0, 0, 0, 20)
		title.AutomaticSize = Enum.AutomaticSize.X
		title.BackgroundTransparency = 1
		title.Text = "DB List"
		title.TextColor3 = Color3.fromRGB(220, 220, 230)
		title.TextSize = 12
		title.Font = Enum.Font.GothamBold
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.LayoutOrder = 1

		DBListLabel = Instance.new("TextLabel", frame)
		DBListLabel.Size = UDim2.new(0, 0, 0, 20)
		DBListLabel.AutomaticSize = Enum.AutomaticSize.XY
		DBListLabel.BackgroundTransparency = 1
		DBListLabel.Text = "..."
		DBListLabel.TextColor3 = Color3.fromRGB(180, 130, 255)
		DBListLabel.TextSize = 14
		DBListLabel.Font = Enum.Font.Gotham
		DBListLabel.TextXAlignment = Enum.TextXAlignment.Left
		DBListLabel.TextYAlignment = Enum.TextYAlignment.Top
		DBListLabel.LayoutOrder = 2

		local dragging, dragStart, startPos
		title.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = frame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)

		DBListGui = frame
	end

	local function DestroyDBListGui()
		if DBListGui and DBListGui.Parent then
			DBListGui.Parent:Destroy()
		end
		DBListGui = nil
	end

	local function DestroyCurRomGui()
		if CurRomGui and CurRomGui.Parent then
			CurRomGui.Parent:Destroy()
		end
		CurRomGui = nil
	end

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
	
	
   do
   	-- ═══ ЦВЕТА (выносим наверх, чтобы RegisterESP их видел) ═══
	DoorESP_Color = Color3.fromRGB(220, 60, 60)
	KeyESP_Color = Color3.fromRGB(80, 200, 255)
	LockerESP_Color = Color3.fromRGB(255, 180, 60)
	LeverESP_Color = Color3.fromRGB(255, 80, 80)
	EntityESP_Color = Color3.fromRGB(255, 50, 50)
	
	-- ═══════════════════════════════════════════════════════════
	-- КАСТОМНЫЕ ТУМБЛЕРЫ С КВАДРАТИКОМ ЦВЕТА
	-- ═══════════════════════════════════════════════════════════
	local activePicker = nil
	local CurrentRoomModel = nil
	local LastRoomModel = nil

	local function GetRoomFromObject(obj)
		local rooms = workspace:FindFirstChild("GameplayFolder") and workspace.GameplayFolder:FindFirstChild("Rooms")
		if not rooms then return nil end
		
		local p = obj
		while p and p ~= workspace do
			-- Если родитель этого объекта — сама папка Rooms, значит мы нашли модель комнаты
			if p.Parent == rooms then
				return p
			end
			p = p.Parent
		end
		return nil
	end
	
		local TweenService = game:GetService("TweenService")
	local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear)
	
	-- Плавное появление/исчезновение ESP
	local function FadeESP(data, visible)
		local fill = visible and 0.5 or 1
		local outline = visible and 0 or 1
		local text = visible and 0 or 1

		if data.Highlights then
			for _, hl in ipairs(data.Highlights) do
				TweenService:Create(hl, fadeInfo, {FillTransparency = fill, OutlineTransparency = outline}):Play()
			end
		elseif data.Highlight then
			TweenService:Create(data.Highlight, fadeInfo, {FillTransparency = fill, OutlineTransparency = outline}):Play()
		end

		if data.Billboard then
			for _, obj in ipairs(data.Billboard:GetDescendants()) do
				if obj:IsA("TextLabel") then
					TweenService:Create(obj, fadeInfo, {TextTransparency = text, TextStrokeTransparency = text}):Play()
				end
			end
		end
		if data.BillboardText then
			 for _, obj in ipairs(data.BillboardText:GetDescendants()) do
				if obj:IsA("TextLabel") then
					TweenService:Create(obj, fadeInfo, {TextTransparency = text, TextStrokeTransparency = text}):Play()
				end
			end
		end
		if data.CircleFrame then
			TweenService:Create(data.CircleFrame, fadeInfo, {BackgroundTransparency = visible and 0.85 or 1}):Play()
		end
		if data.Stroke then
			TweenService:Create(data.Stroke, fadeInfo, {Transparency = outline}):Play()
		end
	end

	local LastPlayerRoomModel = nil

	local function GetPlayerRoom()
		local rooms = workspace:FindFirstChild("GameplayFolder") and workspace.GameplayFolder:FindFirstChild("Rooms")
		if not rooms then return nil end

		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end

		-- ═══ ФИКС: Рейкаст в пол (он всегда находит правильную комнату) ═══
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {char}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local result = workspace:Raycast(hrp.Position, Vector3.new(0, -20, 0), rayParams)

		if result and result.Instance then
			local p = result.Instance
			while p and p ~= workspace do
				if p.Parent == rooms then return p end
				p = p.Parent
			end
		end
		return nil
	end

	    -- ═══ HELPER: номер комнаты ═══
    local function GetRoomNumberFromModel(room)
        if not room then return nil end
        local lights = room:FindFirstChild("Lights")
        local sign = lights and lights:FindFirstChild("Sign")
        if sign then
            local sg = sign:FindFirstChild("SurfaceGui") or sign:FindFirstChildWhichIsA("SurfaceGui", true)
            if sg then
                local lbl = sg:FindFirstChildWhichIsA("TextLabel", true)
                if lbl and lbl.Text then
                    local num = tonumber(lbl.Text)
                    if num then return num end
                end
            end
        end
        return nil
    end

    -- ═══ HELPER: реальная дверь (фильтр от фейков) ═══
    local function IsDoorValid(door)
        if not door or not door.Parent then return false end
        
        local success, result = pcall(function()
            local n = door.Name:lower()
            if not n:find("door") then return false end
            
            -- ═══ ФИКС: Проверяем Exit/Enter и у самой двери, и у её родителя ═══
            local hasExit = door:FindFirstChild("Exit") or door:FindFirstChild("Enter")
            if not hasExit and door.Parent then
                hasExit = door.Parent:FindFirstChild("Exit") or door.Parent:FindFirstChild("Enter")
            end
            
            if not hasExit then return false end

            local hasPrompt = false
            for _, d in ipairs(door:GetDescendants()) do
                if d:IsA("ProximityPrompt") then hasPrompt = true break end
            end
            local isBroken = n:find("broken")
            if not hasPrompt and not isBroken then return false end
            
            for _, part in ipairs(door:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "Collision" then
                    if part.Size.Y > 5 and (part.Size.X > 5 or part.Size.Z > 5) then
                        return true
                    end
                end
            end
            return false
        end)
        
        return success and result
    end

		      function MakeESP(name, desc, defaultColor, flag, colorFlag, toggleCallback, colorCallback)
		local toggle = VisualsTab:Toggle({
			Name = name,
			Desc = desc,
			Default = false,
			Flag = flag,
			Callback = toggleCallback
		})
		
		-- Сдвигаем сам переключатель влево, чтобы освободить место
		local switch = toggle._frame:FindFirstChildWhichIsA("Frame")
		if switch then
			switch.Position = UDim2.new(1, -50, 0.5, 0)
		end
		
		-- Создаем квадратик (только если передан colorFlag)
		if colorFlag then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.fromOffset(20, 20)
			btn.AnchorPoint = Vector2.new(0.5, 0.5)
			btn.Position = UDim2.new(1, -26, 0.5, 0)
			btn.BackgroundColor3 = defaultColor
			btn.Text = ""
			btn.AutoButtonColor = false
			btn.Parent = toggle._frame
			
			local corner = Instance.new("UICorner", btn)
			corner.CornerRadius = UDim.new(0, 4)
			local stroke = Instance.new("UIStroke", btn)
			stroke.Color = Color3.fromRGB(60, 60, 60)
			
			-- Создаем скрытую палитру, которая будет выезжать при клике
			local picker = VisualsTab:ColorPicker({
				Name = name .. " Color",
				Flag = colorFlag,
				Default = defaultColor,
				Callback = function(color)
					btn.BackgroundColor3 = color
					if colorCallback then colorCallback(color) end
				end
			})
			
			-- Изначально прячем палитру
			if picker._frame then
				picker._frame.Visible = false
			end
			
			-- Клик по квадратику открывает/закрывает палитру
			btn.MouseButton1Click:Connect(function()
				if picker._frame then
					if activePicker and activePicker ~= picker then
						activePicker._frame.Visible = false
					end
					picker._frame.Visible = not picker._frame.Visible
					activePicker = picker
				end
			end)
			
			-- Применяем цвет при загрузке (для конфига)
			if colorCallback then colorCallback(defaultColor) end
		end -- ═══ ВОТ ЭТОТ END ЗАКРЫВАЕТ IF colorFlag ═══
	end
	
	-- ═══════════════════════════════════════════════════════════
	-- DOOR ESP
	-- ═══════════════════════════════════════════════════════════
	local DoorESP_Enabled = false
	local DoorESP_Color = Color3.fromRGB(220, 60, 60)
	      DoorESP_Objects = {}
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

	-- ═══ БАЗА ДАННЫХ КОМНАТ ═══
	local getgenv = getgenv or function() return _G end
	local SavedState = getgenv().SynapseDoorState

	local RoomDB = {}
	local RoomByNumber = {}
	local LastRoomModel = nil
	local CurrentRoomNum = -999
	local LastKnownNum = -999
	local DB_Ready = false

	-- ═══ ВОССТАНАВЛИВАЕМ БАЗУ ПРИ РЕИНЖЕКТЕ ═══
	if SavedState and SavedState.RoomDB then
		RoomDB = SavedState.RoomDB
		RoomByNumber = SavedState.RoomByNumber
		CurrentRoomNum = SavedState.CurrentRoomNum or -999
		LastKnownNum = SavedState.LastKnownNum or -999
		LastRoomModel = SavedState.LastRoomModel
		
		-- Чистим битые ссылки (если комнату выгрузили, пока скрипт был выключен)
		for roomModel, num in pairs(RoomDB) do
			if not roomModel.Parent then
				RoomDB[roomModel] = nil
				RoomByNumber[num] = nil
			end
		end
	end

	-- ═══ ФУНКЦИЯ СОХРАНЕНИЯ ═══
	local function SaveState()
		getgenv().SynapseDoorState = {
			RoomDB = RoomDB,
			RoomByNumber = RoomByNumber,
			CurrentRoomNum = CurrentRoomNum,
			LastKnownNum = LastKnownNum,
			LastRoomModel = LastRoomModel
		}
	end

	local function GetPlayerRoom()
		local rooms = workspace:FindFirstChild("GameplayFolder") and workspace.GameplayFolder:FindFirstChild("Rooms")
		if not rooms then return nil end

		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end

		-- ═══ ФИКС: Рейкаст в пол (он всегда находит правильную комнату) ═══
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {char}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local result = workspace:Raycast(hrp.Position, Vector3.new(0, -20, 0), rayParams)

		if result and result.Instance then
			local p = result.Instance
			while p and p ~= workspace do
				if p.Parent == rooms then return p end
				p = p.Parent
			end
		end
		return nil
	end

	local function ProcessRoomChanges()
		DB_Ready = false
		task.spawn(function()
			local startTime = tick()
			local foundNew = false
			
			while tick() - startTime < 3 do
				task.wait(0.1) -- Наша ускоренная задержка
				
				local roomsFolder = workspace:FindFirstChild("GameplayFolder") and workspace.GameplayFolder:FindFirstChild("Rooms")
				if not roomsFolder then continue end
				
				-- 1. Очистка выгруженных комнат
				for roomModel, roomNum in pairs(RoomDB) do
					if roomModel.Name ~= "Start" then
						if roomModel.Parent ~= roomsFolder then
							RoomDB[roomModel] = nil
							RoomByNumber[roomNum] = nil
							for door, data in pairs(DoorESP_Objects) do
								if data.RoomModel == roomModel then
									-- ═══ ФИКС: Защита от краша сканера ═══
									pcall(function()
										if RemoveDoorESP then
											RemoveDoorESP(door)
										else
											-- Если функции нет, чистим вручную
											if data.Highlights then
												for _, hl in ipairs(data.Highlights) do hl:Destroy() end
											elseif data.Highlight then
												data.Highlight:Destroy()
											end
											if data.Billboard then data.Billboard:Destroy() end
											DoorESP_Objects[door] = nil
										end
									end)
								end
							end
						end
					end
				end
				
				-- 2. Добавление новых
				foundNew = false
				for _, room in ipairs(roomsFolder:GetChildren()) do
					if (room:IsA("Model") or room:IsA("Folder")) and not RoomDB[room] and room.Name:lower() ~= "start" then
						local nextNum = LastKnownNum - 1
						while RoomByNumber[nextNum] do nextNum = nextNum - 1 end
						RoomDB[room] = nextNum
						RoomByNumber[nextNum] = room
						LastKnownNum = nextNum
						foundNew = true
					end
				end
				
				if foundNew then break end
			end
			
			SaveState() -- ═══ СОХРАНЯЕМ В ПАМЯТЬ ═══
			DB_Ready = true
		end)
	end

	local function UpdateCurrentRoom()
		local currentRoom = GetPlayerRoom()
		if not currentRoom then return end

		if currentRoom.Name:lower() == "start" then
			CurrentRoomNum = 101
			LastRoomModel = currentRoom
		elseif currentRoom ~= LastRoomModel then
			if RoomDB[currentRoom] then
				CurrentRoomNum = RoomDB[currentRoom]
			else
				-- Если мы зашли в комнату, которую сканер еще не успел записать (редкость)
				CurrentRoomNum = LastKnownNum - 1
				RoomDB[currentRoom] = CurrentRoomNum
				RoomByNumber[CurrentRoomNum] = currentRoom
				LastKnownNum = CurrentRoomNum
				SaveState()
			end
			LastRoomModel = currentRoom
			
		end
	end
	
	-- ═══ МГНОВЕННЫЙ РАДАР КОМНАТ (Циклический сканер) ═══
	local function SetupRoomScanner()
		task.spawn(function()
			while task.wait(0.1) do
				if _G.SynapseUnloaded then break end
				
				local roomsFolder = workspace:FindFirstChild("GameplayFolder") and workspace.GameplayFolder:FindFirstChild("Rooms")
				if not roomsFolder then continue end

				-- 1. Инициализация Старта
				if LastKnownNum == -999 then
					LastKnownNum = 101
					local startRoom = roomsFolder:FindFirstChild("Start")
					if startRoom then
						RoomDB[startRoom] = 101
						RoomByNumber[101] = startRoom
					end
				end
				
				-- 2. Поиск новых комнат
				for _, room in ipairs(roomsFolder:GetChildren()) do
					if (room:IsA("Model") or room:IsA("Folder")) and room.Name:lower() ~= "start" then
						if not RoomDB[room] then
							local nextNum = LastKnownNum - 1
							while RoomByNumber[nextNum] do nextNum = nextNum - 1 end
							
							RoomDB[room] = nextNum
							RoomByNumber[nextNum] = room
							LastKnownNum = nextNum
							SaveState()
						end
					end
				end
				
				-- 3. Очистка выгруженных комнат
				for roomModel, num in pairs(RoomDB) do
					if roomModel.Name:lower() ~= "start" then
						if roomModel.Parent ~= roomsFolder then
							RoomDB[roomModel] = nil
							RoomByNumber[num] = nil
							SaveState()
							
							for door, data in pairs(DoorESP_Objects) do
								if data.RoomModel == roomModel then
									-- ═══ ФИКС: Удаляем ESP напрямую, без вызова функции ═══
									if data.Highlights then
										for _, hl in ipairs(data.Highlights) do
											pcall(function() hl:Destroy() end)
										end
									elseif data.Highlight then
										pcall(function() data.Highlight:Destroy() end)
									end
									pcall(function() if data.Billboard then data.Billboard:Destroy() end end)
									DoorESP_Objects[door] = nil
								end
							end
						end
					end
				end
			end
		end)
	end
	
	-- Запускаем радар
	SetupRoomScanner()

	local function GetUIContainer()
		return LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
	end
	
	local function GetRoomNumber(door)
		if not door then return nil end
		
		local exitVal = door:FindFirstChild("Exit") or door:FindFirstChild("Enter")
		if exitVal and exitVal:IsA("StringValue") then
			local num = tonumber(exitVal.Value:match("(-?%d+)")) -- ═══ ФИКС: Поддержка минуса ═══
			if num then
				RoomNumberCache[door] = num
				return num
			end
		end

		for _, d in ipairs(door:GetDescendants()) do
			if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
				local lbl = d:FindFirstChildWhichIsA("TextLabel", true)
				if lbl and lbl.Text then
					local num = tonumber(lbl.Text:match("(-?%d+)")) or tonumber(lbl.Text)
					if num then
						RoomNumberCache[door] = num
						return num
					end
				end
			end
		end
		
		return RoomNumberCache[door]
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

					local isDoorMesh = n:find("door")
					local isPanel = (n == "base" or n == "baseaddition")
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

		local roomModel = GetRoomFromObject(door)

		DoorESP_Objects[door] = {
			Highlights = highlights,
			Billboard = bb,
			Label = lbl,
			MainPanel = mainPanel,
			LastRoom = num,
			IsVisible = false, 
			RoomModel = roomModel, -- ═══ ТЕПЕРЬ ХРАНИМ МОДЕЛЬ ═══
		}
		
		-- Сразу гасим
		FadeESP(DoorESP_Objects[door], false)
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
		if not door or not door.Parent then return false end
		
		-- ═══ ФАКТ 1: Атрибуты (Самый надежный способ) ═══
		if door:GetAttribute("ServerUse") or door:GetAttribute("ClientUse") then
			return true
		end
		-- ═══ ФАКТ 2: Большие двери (BigDoor) ═══
		if door:GetAttribute("InteractionType") == "BigDoor" then
			return true
		end
		
		-- ═══ ФАКТ 3: Если атрибутов нет, но есть связь Exit/Enter и рабочий промпт ═══
		local hasExit = door:FindFirstChild("Exit") or door:FindFirstChild("Enter")
		if not hasExit and door.Parent then
			hasExit = door.Parent:FindFirstChild("Exit") or door.Parent:FindFirstChild("Enter")
		end
		
		local hasPrompt = false
		for _, d in ipairs(door:GetDescendants()) do
			if d:IsA("ProximityPrompt") and d.Enabled then 
				hasPrompt = true 
				break 
			end
		end
		
		-- Если есть связь с комнатой И активный промпт — это дверь (например, сейф или специфичная дверь)
		if hasExit and hasPrompt then return true end
		
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
	
    local function UpdateNormalDoorESP()
        if not DoorESP_Enabled then return end
        
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local myPos = hrp.Position

        UpdateCurrentRoom()

        if not CurrentRoomNum or CurrentRoomNum == -999 or not CurrentRoomModel then
            for _, data in pairs(DoorESP_Objects) do
                if data.IsVisible ~= false then data.IsVisible = false FadeESP(data, false) end
            end
            return
        end

        -- ═══ БЕРЕМ СЛЕДУЮЩУЮ КОМНАТУ (98) ═══
        local targetNum = CurrentRoomNum - 1
        local validDoors = {}
        local targetRoomModel = RoomByNumber[targetNum]

        -- 1. Если знаем модель следующей комнаты, ищем двери ВНУТРИ неё
        if targetRoomModel and targetRoomModel.Parent then
            for door, data in pairs(DoorESP_Objects) do
                if door.Parent and IsDoorValid(door) then
                    if door:IsDescendantOf(targetRoomModel) then
                        table.insert(validDoors, door)
                    end
                end
            end
        end

        -- 2. Если не нашли (или модель не прогрузилась), ищем в текущей комнате дверь с нужным номером на табличке
        if #validDoors == 0 then
            for door, data in pairs(DoorESP_Objects) do
                if door.Parent and IsDoorValid(door) and door:IsDescendantOf(CurrentRoomModel) then
                    local doorNum = GetRoomNumber(door)
                    if doorNum == targetNum then
                        table.insert(validDoors, door)
                    end
                end
            end
        end

        -- 3. Фоллбек: самая дальняя дверь в текущей комнате (если табличка и модель сломаны)
        if #validDoors == 0 then
            local maxDist = -1
            local fallbackDoor = nil
            for door, data in pairs(DoorESP_Objects) do
                if door.Parent and IsDoorValid(door) and door:IsDescendantOf(CurrentRoomModel) then
                    local part = door:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local dist = (myPos - part.Position).Magnitude
                        if dist > maxDist then
                            maxDist = dist
                            fallbackDoor = door
                        end
                    end
                end
            end
            if fallbackDoor then table.insert(validDoors, fallbackDoor) end
        end

        -- Применяем видимость
        local targetNumStr = tostring(targetNum)
        for door, data in pairs(DoorESP_Objects) do
            if not door.Parent then continue end
            
            local isVisible = false
            for _, vDoor in ipairs(validDoors) do
                if door == vDoor then
                    isVisible = true
                    break
                end
            end
            
            if data.IsVisible ~= isVisible then
                data.IsVisible = isVisible
                FadeESP(data, isVisible)
            end
            
            if isVisible and data.Highlights then
                for _, hl in ipairs(data.Highlights) do
                    if hl.Parent and hl.Enabled then
                        hl.Enabled = false
                        hl.Enabled = true
                    end
                end
            end
            
            if isVisible and data.Label then
                local part = door:FindFirstChildWhichIsA("BasePart", true)
                local dist = part and math.floor((myPos - part.Position).Magnitude) or 0
                local newText = "Door " .. targetNumStr .. " [" .. dist .. "]"
                if data.Label.Text ~= newText then data.Label.Text = newText end
            end
        end
    end
	
	-- ═══════════════════════════════════════════════════════════
	-- START DOOR (текст над дверью, без обводки)
	-- ═══════════════════════════════════════════════════════════
	local StartDoorBillboard = nil
	local StartDoorLabel = nil
	local StartDoorHighlight = nil

	local function UpdateStartDoorESP()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local myPos = hrp and hrp.Position or Vector3.zero
		
		local startRoom = workspace:FindFirstChild("GameplayFolder") and workspace.GameplayFolder:FindFirstChild("Rooms") and workspace.GameplayFolder.Rooms:FindFirstChild("Start")
		local normalDoor = startRoom and startRoom:FindFirstChild("NormalDoor", true)
		
		if not normalDoor then
			if StartDoorBillboard then StartDoorBillboard.Enabled = false end
			if StartDoorHighlight then StartDoorHighlight.Enabled = false end
			return
		end
		
		-- ═══ Создаем Highlight ОДИН РАЗ ═══
		if not StartDoorHighlight then
			StartDoorHighlight = Instance.new("Highlight")
			StartDoorHighlight.Name = "NL_StartDoorESP"
			StartDoorHighlight.FillColor = DoorESP_Color
			StartDoorHighlight.FillTransparency = 0.5
			StartDoorHighlight.OutlineColor = DoorESP_Color
			StartDoorHighlight.OutlineTransparency = 0
			StartDoorHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			StartDoorHighlight.Parent = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
		end
		
		-- Обновляем обводку
		StartDoorHighlight.Adornee = normalDoor
		StartDoorHighlight.Enabled = true
		StartDoorHighlight.FillColor = DoorESP_Color
		StartDoorHighlight.OutlineColor = DoorESP_Color

		-- ═══ Создаем Billboard ОДИН РАЗ ═══
		if not StartDoorBillboard then
			StartDoorBillboard = Instance.new("BillboardGui")
			StartDoorBillboard.Name = "StartDoorESP_Billboard"
			StartDoorBillboard.Size = UDim2.new(0, 240, 0, 30)
			StartDoorBillboard.AlwaysOnTop = true
			StartDoorBillboard.MaxDistance = 1000
			StartDoorBillboard.LightInfluence = 0
			StartDoorBillboard.Parent = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
			
			StartDoorLabel = Instance.new("TextLabel")
			StartDoorLabel.Size = UDim2.new(1, 0, 1, 0)
			StartDoorLabel.BackgroundTransparency = 1
			StartDoorLabel.TextColor3 = DoorESP_Color
			StartDoorLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
			StartDoorLabel.TextStrokeTransparency = 0
			StartDoorLabel.TextSize = 18
			StartDoorLabel.Font = Enum.Font.GothamBold
			StartDoorLabel.Parent = StartDoorBillboard
		end
		
		StartDoorBillboard.Adornee = normalDoor
		StartDoorBillboard.Enabled = true
		StartDoorBillboard.StudsOffsetWorldSpace = Vector3.new(2.5, 11, 0) 
		
		StartDoorLabel.TextColor3 = DoorESP_Color
		local dist = math.floor((myPos - normalDoor.Position).Magnitude)
		StartDoorLabel.Text = "Door 100 [" .. dist .. "]"
	end

	-- ═══════════════════════════════════════════════════════════
	-- ДИСПЕТЧЕР (Вызывает нужную функцию в зависимости от комнаты)
	-- ═══════════════════════════════════════════════════════════
    local function UpdateDoorTexts()
        if not DoorESP_Enabled then return end
        local pRoom = GetPlayerRoom()
        if pRoom and pRoom ~= CurrentRoomModel then CurrentRoomModel = pRoom end
        if not CurrentRoomModel then return end

        local name = CurrentRoomModel.Name:lower()

        -- ChaseStart / ChaseEnd / SearchlightsTramStart: дверей нет
        if name == "chasestart" or name == "chaseend" or name == "searchlightstramstart" then
            for _, data in pairs(DoorESP_Objects) do
                if data.IsVisible ~= false then data.IsVisible = false FadeESP(data, false) end
            end
            if StartDoorHighlight then StartDoorHighlight.Enabled = false end
            return
        end

        -- Для ВСЕХ остальных комнат (включая Start) используем новую пуленепробиваемую логику
        if StartDoorHighlight then StartDoorHighlight.Enabled = false end
        UpdateNormalDoorESP()
    end

	local function StopDoorESP()
		if DoorESP_Conn then DoorESP_Conn:Disconnect() DoorESP_Conn = nil end
		-- ═══ ПРЯЧЕМ ТЕКСТ СТАРТА ПРИ ВЫКЛЮЧЕНИИ ═══
		if StartDoorBillboard then StartDoorBillboard.Enabled = false end
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
	
		local ItemESP_Enabled = false
	local CurrencyESP_Enabled = false
	local ESP_Objects = {} -- Хранилище для подсвеченных объектов
	local ItemESP_Color = Color3.fromRGB(80, 200, 255) -- Голубой для предметов
	local CurrencyESP_Color = Color3.fromRGB(255, 215, 0) -- Золотой для денег

	local function CreateGenericESP(obj, name, isCurrency, val)
		if ESP_Objects[obj] then return end
		
		local color = isCurrency and CurrencyESP_Color or ItemESP_Color
		local container_ui = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

		local hl = Instance.new("Highlight")
		hl.Name = "NL_ItemESP"
		hl.Adornee = obj
		hl.FillColor = color
		hl.FillTransparency = 0.5
		hl.OutlineColor = color
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = container_ui

		local bb = Instance.new("BillboardGui")
		bb.Name = "NL_ItemESP_Billboard"
		bb.Adornee = obj
		bb.Size = UDim2.new(0, 180, 0, 22)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 500
		bb.LightInfluence = 0
		bb.Parent = container_ui

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		
		-- ═══ ФИКС: Переименование для денег ═══
		if isCurrency then
			lbl.Text = "Researchers (" .. tostring(val) .. ") [0]"
		else
			lbl.Text = name .. " [0]"
		end
		
		lbl.TextColor3 = color
		lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		lbl.TextStrokeTransparency = 0
		lbl.TextSize = 14
		lbl.Font = Enum.Font.GothamBold
		lbl.Parent = bb

		ESP_Objects[obj] = {Highlight = hl, Billboard = bb, Label = lbl, IsCurrency = isCurrency, Value = val, IsVisible = true}
	end

	local function ScanForItems()
		if not ItemESP_Enabled and not CurrencyESP_Enabled then return end
		
		local function scanFolder(folder)
			if not folder then return end
			for _, obj in ipairs(folder:GetDescendants()) do
				if obj:IsA("Model") or obj:IsA("BasePart") then
					local foundName = nil
					local currencyVal = nil
					local isItem = false
					local current = obj
					local depth = 0
					
					while current and current ~= folder and depth < 4 do
						local cName = current.Name
						local cVal = GetCurrencyValue(cName)
						
						if cVal then
							currencyVal = cVal
							foundName = cName
							break
						end
						
						if ItemDB[cName] then
							isItem = true
							foundName = cName
							break
						end

						current = current.Parent
						depth = depth + 1
					end

					if foundName then
						if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") and obj.Parent.Name == foundName then
							continue
						end

						local nLower = foundName:lower()
						local isKeyOrNote = nLower:find("keycard") or nLower:find("passwordpaper") or nLower:find("password")

						if currencyVal and CurrencyESP_Enabled then
							if CurrencyFilter[currencyVal] then
								CreateGenericESP(obj, foundName, true, currencyVal)
							end
						elseif isItem and ItemESP_Enabled and not isKeyOrNote then
							CreateGenericESP(obj, foundName, false, nil)
						end
					end
				end
			end
		end

		scanFolder(workspace:FindFirstChild("DroppedItems"))
		scanFolder(workspace:FindFirstChild("GameplayFolder") and workspace.GameplayFolder:FindFirstChild("Rooms"))
	end

	-- Toggle
	MakeESP("Door ESP", "Подсвечивает Двери", Color3.fromRGB(220, 60, 60), "DoorESP", "DoorESPColor", function(value)
		DoorESP_Enabled = value
		if value then StartDoorESP() else StopDoorESP() ClearAllDoors() end
	end, function(color)
		DoorESP_Color = color
		for _, data in pairs(DoorESP_Objects) do
			if data.Highlights then
				for _, hl in ipairs(data.Highlights) do
					pcall(function() hl.FillColor = color hl.OutlineColor = color end)
				end
			end
			pcall(function() if data.Label then data.Label.TextColor3 = color end end)
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
	      KeyESP_Objects = {}
	local KeyESP_Conn = nil

	-- Точные фрагменты имён (lowercase)
	local KEYCARD_KEYS = {"keycard"}
	local NOTE_KEYS = {"passwordpaper", "password"}
	
	-- Что игнорить (чтобы не путать с другими предметами)
	local IGNORE_KEYS = {
		"currency", "drawer", "locker", "lockerunderwater", "highlight", "door", "panel", "cabinet", "shelf", 
		"skip", "navipanel", "spawn", "itemlocker", "catwalk", "room", "zone", "area", "hallway",
		"lever", "switch", "button", "generate", "generator", "valve", "computer", "screen", "terminal"
	}

	    function ContainsAny(str, list)
		local s = str:lower()
		for _, kw in ipairs(list) do
			if s:find(kw, 1, true) then return true end
		end
		return false
	end

	-- От ProximityPrompt поднимаемся до Model и определяем категорию
	-- ═══ Проверка: контейнер маленький (карта/бумага), а не зона/комната ═══
	    function IsSmallItem(container)
		if not container then return false end
		-- Считаем bounding box
		local cf, sz
		local ok, bcf, bsz = pcall(function() return container:GetBoundingBox() end)
		if ok and bcf and bsz then
			cf, sz = bcf, bsz
		else
			-- Fallback: считаем вручную
			local minV = Vector3.new(math.huge, math.huge, math.huge)
			local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
			local has = false
			for _, d in ipairs(container:GetDescendants()) do
				if d:IsA("BasePart") or d:IsA("MeshPart") then
					has = true
					local pos = d.Position
					local half = d.Size / 2
					minV = Vector3.new(
						math.min(minV.X, pos.X - half.X),
						math.min(minV.Y, pos.Y - half.Y),
						math.min(minV.Z, pos.Z - half.Z)
					)
					maxV = Vector3.new(
						math.max(maxV.X, pos.X + half.X),
						math.max(maxV.Y, pos.Y + half.Y),
						math.max(maxV.Z, pos.Z + half.Z)
					)
				end
			end
			if not has then return false end
			sz = maxV - minV
		end
		
		-- Максимальная сторона < 5 studs = предмет; больше = зона/комната
		local maxDim = math.max(sz.X, sz.Y, sz.Z)
		return maxDim < 5
	end

	    function DetectItemCategory(prompt)
		if not prompt or not prompt:IsA("ProximityPrompt") then return nil end
		local p = prompt.Parent
		local depth = 0
		while p and p ~= workspace and depth < 6 do
			local n = p.Name:lower()
			
			-- ═══ Жесткий фильтр на мебель, растения и технику ═══
			local isFurniture = n:find("table") or n:find("desk") or n:find("console") or n:find("panel") 
			                 or n:find("monitor") or n:find("computer") or n:find("screen") or n:find("cabinet")
			                 or n:find("plant") or n:find("pot") or n:find("flower") or n:find("tree") or n:find("bush")
			                 or n:find("chair") or n:find("sofa") or n:find("couch") or n:find("drawer")
			
			if not isFurniture then
				-- ═══ ФИКС: Карты (Keycard) ищем просто по имени, даже без цифрового экрана ═══
				if ContainsAny(n, KEYCARD_KEYS) or n:find("card") or n:find("key") then 
					return "Keycard", p 
				end
				
				-- ═══ Бумаги (Note) все еще требуют наличия цифр, чтобы не ловить мусор ═══
				if ContainsAny(n, NOTE_KEYS) or n:find("paper") or n:find("note") then 
					local hasCodeUI = false
					for _, d in ipairs(p:GetDescendants()) do
						if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
							local lbl = d:FindFirstChildWhichIsA("TextLabel", true)
							if lbl and lbl.Text and lbl.Text:match("^%d+$") then
								hasCodeUI = true
								break
							end
						end
					end
					if hasCodeUI then return "Note", p end
				end
			end
			p = p.Parent
			depth = depth + 1
		end
		return nil
	end

	    function GetKeyUIContainer()
		return LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
	end

	-- Читаем код с бумаги (часть "Code" содержит SurfaceGui с текстом)
	    function ExtractCode(container)
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

	    function CreateKeyESP(container, category, prompt)
		if KeyESP_Objects[container] then return end

		-- ═══ ФИКС: Увеличили лимит размеров, чтобы карты в ящиках не отсеивались ═══
		local cf, sz
		local ok, bcf, bsz = pcall(function() return container:GetBoundingBox() end)
		if ok and bcf and bsz then
			cf, sz = bcf, bsz
		else
			local minV = Vector3.new(math.huge, math.huge, math.huge)
			local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
			local has = false
			for _, d in ipairs(container:GetDescendants()) do
				if d:IsA("BasePart") then
					has = true
					local pos = d.Position
					local half = d.Size / 2
					minV = Vector3.new(math.min(minV.X, pos.X - half.X), math.min(minV.Y, pos.Y - half.Y), math.min(minV.Z, pos.Z - half.Z))
					maxV = Vector3.new(math.max(maxV.X, pos.X + half.X), math.max(maxV.Y, pos.Y + half.Y), math.max(maxV.Z, pos.Z + half.Z))
				end
			end
			if has then sz = maxV - minV end
		end

		-- Если объект слишком большой (больше 10 studs) - это мебель.
		if sz and (sz.X > 10 or sz.Y > 10 or sz.Z > 10) then
			return 
		end
		-- ═══════════════════════════════════════════════════════════

		local container_ui = GetKeyUIContainer()

		-- ═══ Highlight прямо на контейнер (Model или Part) ═══
		local hl = Instance.new("Highlight")
		hl.Name = "NL_KeyESP"
		hl.Adornee = container          
		hl.FillColor = KeyESP_Color
		hl.FillTransparency = 0.5
		hl.OutlineColor = KeyESP_Color
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = container_ui

		-- ═══ Billboard на позицию карты/бумаги ═══
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
		bb.Adornee = targetPart        
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
			IsVisible = true,
		}
	end

	    function RemoveKeyESP(container)
		local data = KeyESP_Objects[container]
		if not data then return end
		pcall(function() if data.Highlight then data.Highlight:Destroy() end end)
		pcall(function() if data.Billboard then data.Billboard:Destroy() end end)
		KeyESP_Objects[container] = nil
	end

	    function ClearAllKeyESP()
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
	    function ScanKeyItems()
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

        function UpdateKeyTexts()
        if not KeyESP_Enabled then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local myPos = hrp.Position

        local name = CurrentRoomModel.Name
        if name == "ChaseStart" or name == "ChaseEnd" or name == "SearchlightsTramStart" then
            for _, data in pairs(KeyESP_Objects) do
                if data.IsVisible ~= false then data.IsVisible = false FadeESP(data, false) end
            end
            return
        end

        for c, data in pairs(KeyESP_Objects) do
            if not c.Parent then RemoveKeyESP(c) continue end
            local targetPart = c:FindFirstChildWhichIsA("BasePart", true)
            local pos = targetPart and targetPart.Position or c:GetPivot().Position
            local dist = math.floor((myPos - pos).Magnitude)

            local isVisible = c:IsDescendantOf(CurrentRoomModel)

            if data.IsVisible ~= isVisible then
                data.IsVisible = isVisible
                FadeESP(data, isVisible)
            end
            if isVisible and data.Label then
                local newText = data.Category .. " [" .. dist .. "]"
                if data.Label.Text ~= newText then data.Label.Text = newText end
            end
        end
    end

	    function StartKeyESP()
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

	    function StopKeyESP()
		if KeyESP_Conn then KeyESP_Conn:Disconnect() KeyESP_Conn = nil end
	end

	-- Toggle
	MakeESP("Key/Pass ESP", "Подсвечивает Ключ и Бумагу", Color3.fromRGB(80, 200, 255), "KeyESP", "KeyESPColor", function(value)
		KeyESP_Enabled = value
		if value then StartKeyESP() else StopKeyESP() ClearAllKeyESP() end
	end, function(color)
		KeyESP_Color = color
		for _, data in pairs(KeyESP_Objects) do
			pcall(function() data.Highlight.FillColor = color data.Highlight.OutlineColor = color end)
			pcall(function() data.Label.TextColor3 = color end)
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
	      LockerESP_Objects = {}
	local LockerESP_Conn = nil

	-- ═══ Только "Locker" (без ItemLocker, SmallCabinet, LockerShelf) ═══
	    function IsRealLocker(name)
		local n = name:lower()
		-- Обычный шкаф + подводный шкаф (только НАСТОЯЩИЕ, без полочек)
		if n == "locker" then return true end
		if n == "lockerunderwater" then return true end
		return false
	end

	    function CreateLockerESP(container)
		if LockerESP_Objects[container] then return end

		local container_ui = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

		-- ═══ Основной Highlight (работает на земле) ═══
		local hl = Instance.new("Highlight")
		hl.Name = "NL_LockerESP"
		hl.Adornee = container
		hl.FillColor = LockerESP_Color
		hl.FillTransparency = 0.5
		hl.OutlineColor = LockerESP_Color
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = container_ui

		-- ═══ Water Highlight (для подводных шкафов) ═══
		local hlWater = nil
		local containerName = container.Name:lower()
		local isUnderwater = containerName:find("underwater") ~= nil

		if isUnderwater then
			hlWater = Instance.new("Highlight")
			hlWater.Name = "NL_LockerESP_Water"
			hlWater.Adornee = container
			hlWater.FillColor = LockerESP_Color
			hlWater.FillTransparency = 0.3
			hlWater.OutlineColor = LockerESP_Color
			hlWater.OutlineTransparency = 0
			hlWater.DepthMode = Enum.HighlightDepthMode.Occluded  -- ← виден сквозь воду
			hlWater.Parent = container_ui
			
			-- Отключаем основной — под водой он невиден
			hl.Enabled = false
		end

		-- ═══ Billboard ═══
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
			if hlWater then pcall(function() hlWater:Destroy() end) end
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
			HighlightWater = hlWater,   -- ← сохраняем
			Billboard = bb,
			Label = lbl,
			AnchorPos = cf.Position,
			IsVisible = true,
		}
	end

	    function RemoveLockerESP(container)
		local data = LockerESP_Objects[container]
		if not data then return end
		pcall(function() if data.Highlight then data.Highlight:Destroy() end end)
		pcall(function() if data.HighlightWater then data.HighlightWater:Destroy() end end)
		pcall(function() if data.Billboard then data.Billboard:Destroy() end end)
		LockerESP_Objects[container] = nil
	end

	    function ClearAllLockerESP()
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

	    function ScanLockers()
		if not LockerESP_Enabled then return end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and IsRealLocker(obj.Name) then
				if not LockerESP_Objects[obj] then
					CreateLockerESP(obj)
				end
			end
		end
	end

        function UpdateLockerTexts()
        if not LockerESP_Enabled then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local myPos = hrp.Position

        -- ChaseStart: вырубаем
        if CurrentRoomModel.Name == "ChaseStart" then
            for _, data in pairs(LockerESP_Objects) do
                if data.IsVisible ~= false then data.IsVisible = false FadeESP(data, false) end
            end
            return
        end

        -- ═══ ФИКС: Проверяем, включен ли режим серчлайта ═══
        local isSearchlight = CurrentRoomModel.Name:find("Searchlights")

        for c, data in pairs(LockerESP_Objects) do
            if not c.Parent then RemoveLockerESP(c) continue end
            local pos = c:GetPivot().Position
            local dist = math.floor((myPos - pos).Magnitude)

            local isVisible = false
            if isSearchlight then
                -- В комнате с прожекторами - только в радиусе 100
                isVisible = dist < 100
            else
                -- В обычных комнатах - вся комната (старая логика)
                isVisible = c:IsDescendantOf(CurrentRoomModel)
            end

            if data.IsVisible ~= isVisible then
                data.IsVisible = isVisible
                FadeESP(data, isVisible)
            end
            if isVisible and data.Label then
                local newText = "Locker [" .. dist .. "]"
                if data.Label.Text ~= newText then data.Label.Text = newText end
            end
        end
    end

	    function StartLockerESP()
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

	    function StopLockerESP()
		if LockerESP_Conn then LockerESP_Conn:Disconnect() LockerESP_Conn = nil end
	end

	MakeESP("Locker ESP", "Подсвечивает шкафчики", Color3.fromRGB(255, 180, 60), "LockerESP", "LockerESPColor", function(value)
		LockerESP_Enabled = value
		if value then StartLockerESP() else StopLockerESP() ClearAllLockerESP() end
	end, function(color)
		LockerESP_Color = color
		for _, data in pairs(LockerESP_Objects) do
			pcall(function() data.Highlight.FillColor = color data.Highlight.OutlineColor = color end)
			pcall(function() if data.HighlightWater then data.HighlightWater.FillColor = color end end)
			pcall(function() data.Label.TextColor3 = color end)
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
	      LeverESP_Objects = {}
	local LeverESP_Conn = nil

	-- ═══ Имена рычагов в Pressure ═══
	local LEVER_KEYWORDS = {"lever", "switch", "button"}
	-- ═══ Игнор — что НЕ рычаг ═══
	local LEVER_IGNORE = {"light", "lamp", "bulb", "sign"}

	    function MatchesLever(name)
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
	    function HasPrompt(model)
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("ProximityPrompt") then return true end
		end
		return false
	end

	    function CreateLeverESP(container)
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
			IsVisible = true,
		}
	end

	    function RemoveLeverESP(container)
		local data = LeverESP_Objects[container]
		if not data then return end
		pcall(function() if data.Highlight then data.Highlight:Destroy() end end)
		pcall(function() if data.Billboard then data.Billboard:Destroy() end end)
		LeverESP_Objects[container] = nil
	end

	    function ClearAllLeverESP()
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

	    function ScanLevers()
		if not LeverESP_Enabled then return end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and MatchesLever(obj.Name) and HasPrompt(obj) then
				-- ═══ ФИКС: Отсеиваем декоративные рычаги (у них нет ServerUse/ClientUse) ═══
				if obj:GetAttribute("ServerUse") or obj:GetAttribute("ClientUse") then
					if not LeverESP_Objects[obj] then
						CreateLeverESP(obj)
					end
				end
			end
		end
	end

        function UpdateLeverTexts()
        if not LeverESP_Enabled then return end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local myPos = hrp.Position

        local name = CurrentRoomModel.Name
        if name == "ChaseStart" or name == "ChaseEnd" or name == "SearchlightsTramStart" then
            for _, data in pairs(LeverESP_Objects) do
                if data.IsVisible ~= false then data.IsVisible = false FadeESP(data, false) end
            end
            return
        end

        for c, data in pairs(LeverESP_Objects) do
            if not c.Parent then RemoveLeverESP(c) continue end
            local pos = c:GetPivot().Position
            local dist = math.floor((myPos - pos).Magnitude)

            -- ═══ ФИКС: Вместо привязки к комнате используем дистанцию (до 100 студов) ═══
            local isVisible = dist < 100

            if data.IsVisible ~= isVisible then
                data.IsVisible = isVisible
                FadeESP(data, isVisible)
            end
            if isVisible and data.Label then
                local newText = "Lever [" .. dist .. "]"
                if data.Label.Text ~= newText then data.Label.Text = newText end
            end
        end
    end

	    function StartLeverESP()
		ScanLevers()
		LeverESP_Conn = workspace.DescendantAdded:Connect(function(obj)
			if not LeverESP_Enabled then return end
			if obj:IsA("Model") and MatchesLever(obj.Name) then
				task.wait(0.1)
				-- ═══ ФИКС: Проверяем атрибуты перед созданием ESP ═══
				if HasPrompt(obj) and (obj:GetAttribute("ServerUse") or obj:GetAttribute("ClientUse")) then
					if not LeverESP_Objects[obj] then
						CreateLeverESP(obj)
					end
				end
			end
		end)
	end

	    function StopLeverESP()
		if LeverESP_Conn then LeverESP_Conn:Disconnect() LeverESP_Conn = nil end
	end

	MakeESP("Lever ESP", "Подсвечивает рычаги", Color3.fromRGB(255, 80, 80), "LeverESP", "LeverESPColor", function(value)
		LeverESP_Enabled = value
		if value then StartLeverESP() else StopLeverESP() ClearAllLeverESP() end
	end, function(color)
		LeverESP_Color = color
		for _, data in pairs(LeverESP_Objects) do
			pcall(function() data.Highlight.FillColor = color data.Highlight.OutlineColor = color end)
			pcall(function() data.Label.TextColor3 = color end)
		end
	end)

	RegisterCleanup("LeverESP", function()
		LeverESP_Enabled = false
		StopLeverESP()
		ClearAllLeverESP()
	end)
	
	-- ═══════════════════════════════════════════════════════════
	-- GENERATOR ESP (Table-based, идеальная проверка по свету)
	-- ═══════════════════════════════════════════════════════════
	    GenESP_Data = {
		Enabled = false,
		Color = Color3.fromRGB(255, 100, 50),
		Objects = {},
		Conn = nil
	}

	local GenESP_Utils = {}

	GenESP_Utils.IsBroken = function(gen)
		local success, result = pcall(function()
			if not gen or not gen:IsA("Model") then return false end
			
			-- Ищем Fixed по всем потомкам (true)
			local fixedVal = gen:FindFirstChild("Fixed", true)
			if fixedVal and fixedVal:IsA("ValueBase") then
				local val = tonumber(fixedVal.Value)
				if val then
					return val < 100 -- Если меньше 100 (например 0), значит сломан
				end
			end
			
			-- Запасной вариант: проверяем кнопку
			local prompt = gen:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				return prompt.Enabled
			end
			
			return false
		end)
		return success and result
	end

	GenESP_Utils.Create = function(container)
		if GenESP_Data.Objects[container] then return end

		local container_ui = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

		local targetModel = container:FindFirstChild("Model") or container
		local targetPart = nil
		local maxVol = 0
		for _, d in ipairs(targetModel:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 0.9 then
				local vol = d.Size.X * d.Size.Y * d.Size.Z
				if vol > maxVol then
					maxVol = vol
					targetPart = d
				end
			end
		end
		
		if not targetPart then
			targetPart = targetModel:FindFirstChildWhichIsA("BasePart", true) or container
		end

		local hl = Instance.new("Highlight")
		hl.Name = "NL_GenESP"
		hl.Adornee = targetModel
		hl.FillColor = GenESP_Data.Color
		hl.FillTransparency = 0.5
		hl.OutlineColor = GenESP_Data.Color
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = container_ui

		local bb = Instance.new("BillboardGui")
		bb.Name = "NL_GenESP_Billboard"
		bb.Adornee = targetPart
		bb.Size = UDim2.new(0, 140, 0, 40) -- Увеличили высоту под 2 строки
		bb.StudsOffsetWorldSpace = Vector3.new(0, (targetPart.Size.Y / 2) + 1.5, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 500
		bb.LightInfluence = 0
		bb.Parent = container_ui

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 20)
		lbl.Position = UDim2.new(0, 0, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = "Generator [0]"
		lbl.TextColor3 = GenESP_Data.Color
		lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		lbl.TextStrokeTransparency = 0
		lbl.TextSize = 14
		lbl.Font = Enum.Font.GothamBold
		lbl.Parent = bb

		-- ═══ НОВЫЙ ТЕКСТ: Показывает проценты ═══
		local statusLbl = Instance.new("TextLabel")
		statusLbl.Size = UDim2.new(1, 0, 0, 20)
		statusLbl.Position = UDim2.new(0, 0, 0, 20)
		statusLbl.BackgroundTransparency = 1
		statusLbl.Text = "Fixed: 0%"
		statusLbl.TextColor3 = Color3.fromRGB(255, 80, 80) -- Красный по умолчанию
		statusLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		statusLbl.TextStrokeTransparency = 0
		statusLbl.TextSize = 12
		statusLbl.Font = Enum.Font.Gotham
		statusLbl.Parent = bb

		GenESP_Data.Objects[container] = {
			Highlight = hl,
			Billboard = bb,
			Label = lbl,
			StatusLabel = statusLbl, -- Сохраняем для обновления
			AnchorPos = targetPart.Position,
			IsVisible = true,
		}
	end

	GenESP_Utils.Remove = function(container)
		local data = GenESP_Data.Objects[container]
		if not data then return end
		pcall(function() if data.Highlight then data.Highlight:Destroy() end end)
		pcall(function() if data.Billboard then data.Billboard:Destroy() end end)
		GenESP_Data.Objects[container] = nil
	end

	GenESP_Utils.ClearAll = function()
		for c in pairs(GenESP_Data.Objects) do GenESP_Utils.Remove(c) end
		GenESP_Data.Objects = {}
		pcall(function()
			local roots = {LocalPlayer:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
			for _, root in ipairs(roots) do
				if root then
					for _, obj in ipairs(root:GetDescendants()) do
						local n = obj.Name
						if n == "NL_GenESP_Billboard" or n == "NL_GenESP" then
							obj:Destroy()
						end
					end
				end
			end
		end)
	end

	GenESP_Utils.Scan = function()
		if not GenESP_Data.Enabled then return end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj.Name:lower():find("generator") then
				if GenESP_Utils.IsBroken(obj) and not GenESP_Data.Objects[obj] then
					GenESP_Utils.Create(obj)
				end
			end
		end
	end

	GenESP_Utils.UpdateTexts = function()
		if not GenESP_Data.Enabled then return end
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local myPos = hrp.Position

		-- Увеличил дистанцию, чтобы не пропадали
		local maxDist = 200
		if CurrentRoomModel and CurrentRoomModel.Name:find("Searchlights") then
			maxDist = 150
		end

		for c, data in pairs(GenESP_Data.Objects) do
			if not c.Parent then GenESP_Utils.Remove(c) continue end
			
			-- Если 100%, удаляем
			if not GenESP_Utils.IsBroken(c) then 
				GenESP_Utils.Remove(c) 
				continue 
			end

			local pos = c:GetPivot().Position
			local dist = math.floor((myPos - pos).Magnitude)
			
			local isVisible = dist <= maxDist

			if data.IsVisible ~= isVisible then
				data.IsVisible = isVisible
				FadeESP(data, isVisible)
			end
			
			if isVisible then
				if data.Label then
					local newText = "Generator [" .. dist .. "]"
					if data.Label.Text ~= newText then data.Label.Text = newText end
				end
				
				-- ═══ ОБНОВЛЯЕМ ПРОЦЕНТЫ ═══
				if data.StatusLabel then
					local fixedVal = c:FindFirstChild("Fixed", true)
					local fixedNum = 0
					if fixedVal and fixedVal:IsA("ValueBase") then
						fixedNum = tonumber(fixedVal.Value) or 0
					end
					
					local statusText = "Fixed: " .. fixedNum .. "%"
					if data.StatusLabel.Text ~= statusText then
						data.StatusLabel.Text = statusText
						-- Красим в зависимости от прогресса
						if fixedNum >= 100 then
							data.StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 120) -- Зеленый
						elseif fixedNum > 0 then
							data.StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 80) -- Желтый
						else
							data.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- Красный
						end
					end
				end
			end
		end
	end

	GenESP_Utils.Start = function()
		GenESP_Utils.Scan()
		GenESP_Data.Conn = workspace.DescendantAdded:Connect(function(obj)
			if not GenESP_Data.Enabled then return end
			if obj:IsA("Model") and obj.Name:lower():find("generator") then
				task.wait(0.1)
				if GenESP_Utils.IsBroken(obj) and not GenESP_Data.Objects[obj] then
					GenESP_Utils.Create(obj)
				end
			end
		end)
		
		-- Каждую секунду делаем пере-скан, чтобы точно ничего не пропустить
		task.spawn(function()
			while GenESP_Data.Enabled do
				task.wait(1)
				GenESP_Utils.Scan()
			end
		end)
	end

	GenESP_Utils.Stop = function()
		if GenESP_Data.Conn then GenESP_Data.Conn:Disconnect() GenESP_Data.Conn = nil end
	end

	MakeESP("Generator ESP", "Подсвечивает сломанные генераторы", Color3.fromRGB(255, 100, 50), "GenESP", "GenESPColor", function(value)
		GenESP_Data.Enabled = value
		if value then GenESP_Utils.Start() else GenESP_Utils.Stop() GenESP_Utils.ClearAll() end
	end, function(color)
		GenESP_Data.Color = color
		for _, data in pairs(GenESP_Data.Objects) do
			pcall(function() data.Highlight.FillColor = color data.Highlight.OutlineColor = color end)
			pcall(function() data.Label.TextColor3 = color end)
		end
	end)

	RegisterCleanup("GenESP", function()
		GenESP_Data.Enabled = false
		GenESP_Utils.Stop()
		GenESP_Utils.ClearAll()
	end)
	
	ItemESP_Enabled = false
	CurrencyESP_Enabled = false

	-- ═══ ITEM ESP (Зеленый кубик) ═══
	MakeESP("Item ESP", "Подсвечивает предметы", Color3.fromRGB(0, 255, 100), "ItemESP", "ItemESPColor", function(value)
		ItemESP_Enabled = value
		if not value then 
			for k, _ in pairs(ESP_Objects) do 
				if not ESP_Objects[k].IsCurrency then 
					pcall(function() ESP_Objects[k].Highlight:Destroy() end)
					pcall(function() ESP_Objects[k].Billboard:Destroy() end)
					ESP_Objects[k] = nil 
				end 
			end 
		end
	end, function(color)
		ItemESP_Color = color
		for _, data in pairs(ESP_Objects) do
			if not data.IsCurrency then
				pcall(function() data.Highlight.FillColor = color data.Highlight.OutlineColor = color end)
				pcall(function() data.Label.TextColor3 = color end)
			end
		end
	end)
	-- ═══ CURRENCY ESP (Серый кубик, как документы) ═══
	MakeESP("Currency ESP", "Подсвечивает деньги", Color3.fromRGB(180, 180, 180), "CurrencyESP", "CurrencyESPColor", function(value)
		CurrencyESP_Enabled = value
		if not value then 
			for k, _ in pairs(ESP_Objects) do 
				if ESP_Objects[k].IsCurrency then 
					pcall(function() ESP_Objects[k].Highlight:Destroy() end)
					pcall(function() ESP_Objects[k].Billboard:Destroy() end)
					ESP_Objects[k] = nil 
				end 
			end 
		end
	end, function(color)
		CurrencyESP_Color = color
		for _, data in pairs(ESP_Objects) do
			if data.IsCurrency then
				pcall(function() data.Highlight.FillColor = color data.Highlight.OutlineColor = color end)
				pcall(function() data.Label.TextColor3 = color end)
			end
		end
	end)

	VisualsTab:Dropdown({
		Name = "Currency Filter",
		Desc = "Выбери номиналы для подсветки",
		Options = {"5", "10", "15", "25", "50", "100", "200", "500"},
		Default = {"5", "10", "15", "25", "50", "100", "200", "500"},
		Multi = true,
		Callback = function(selected)
			for k in pairs(CurrencyFilter) do CurrencyFilter[k] = false end
			for _, val in ipairs(selected) do
				CurrencyFilter[tonumber(val)] = true
			end
			-- ═══ Мгновенная очистка выключенных ═══
			for obj, data in pairs(ESP_Objects) do
				if data.IsCurrency and not CurrencyFilter[data.Value] then
					if data.Highlight then data.Highlight:Destroy() end
					if data.Billboard then data.Billboard:Destroy() end
					ESP_Objects[obj] = nil
				end
			end
		end
	})

	-- ═══════════════════════════════════════════════════════════
	-- УВЕДОМЛЕНИЯ (Только Airflow)
	-- ═══════════════════════════════════════════════════════════
	NotificationSound = Instance.new("Sound")
	NotificationSound.SoundId = "rbxassetid://4590662766"
	NotificationSound.Volume = 5
	NotificationSound.Parent = game:GetService("SoundService")

	function ShowNotify(title, content, notifyType, duration)
		-- Играем звук
		pcall(function() 
			NotificationSound:Stop()
			NotificationSound:Play() 
		end)

		-- Вызываем встроенный нотификатор Airflow
		pcall(function()
			Window:Notify({
				Title = title,
				Content = content,
				Type = notifyType or "Info",
				Duration = duration or 5
			})
		end)
	end
	
-- ═══════════════════════════════════════════════════════════
-- ENTITY ESP v5 (Table-based + Fix Register Limit)
-- ═══════════════════════════════════════════════════════════
EntityESP_Data = {
	Enabled = false,
	Color = Color3.fromRGB(255, 50, 50),
	Objects = {},
	Conn = nil,
	NotifyEnabled = false,
	NotifiedEntities = {},
	ALL_ENTITIES = {"Angler", "Blitz", "Chainsmoker", "Froger", "Pinkie", "Pandemonium", "Good People"},
	ENTITY_ALIASES = {
		["Trickster"] = "Good People"
	},
	SelectedEntities = {}
}

for _, name in ipairs(EntityESP_Data.ALL_ENTITIES) do
	EntityESP_Data.SelectedEntities[name] = true
end

-- Проверка имени
-- ═══ ОБЪЕДИНЯЕМ ФУНКЦИИ В ТАБЛИЦУ (Фикс лимита регистров) ═══
local EntityUtils = {}

EntityUtils.MatchEntity = function(name)
    local n = name:lower()
    
    -- Отсеиваем комнаты
    if n:find("room") then return false, nil end

    for displayName, isSelected in pairs(EntityESP_Data.SelectedEntities) do
        if isSelected then
            -- ═══ ФИКС: Для Good People ищем ТОЛЬКО TricksterDoor ═══
            if displayName == "Good People" then
                if n == "tricksterdoor" then
                    return true, displayName
                end
            else
                -- Для остальных оставляем поиск по подстроке
                local searchName = displayName
                for realName, alias in pairs(EntityESP_Data.ENTITY_ALIASES) do
                    if alias == displayName then searchName = realName break end
                end
                if n:find(searchName:lower(), 1, true) then
                    return true, displayName
                end
            end
        end
    end
    return false, nil
end

EntityUtils.Create = function(container, entityName)
    if EntityESP_Data.Objects[container] then return end
    
    local container_ui = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    local highlights = {}
    local spoofedParts = {} -- ═══ ВЫНОСИМ СЮДА, ЧТОБЫ БЫЛО ВИДНО В КОНЦЕ ═══

    if entityName == "Good People" then
        -- 1. Скрываем табличку с номером
        for _, part in ipairs(container:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                local n = part.Name:lower()
                if n:find("sign") or n:find("recolor") or n:find("neon") then
                    part.LocalTransparencyModifier = 1
                end
            end
        end

        -- 2. ═══ ФИКС: Накладываем Highlight на ВСЕ видимые детали, но делаем заливку прозрачной ═══
        local BAD_KEYWORDS = { "collision", "root", "gear", "handle", "signpart", "recolor", "proxy", "number", "cyl", "sphere", "lopee", "torso", "mr_", "keypad", "lock" }
        local function isBadName(name)
            local n = name:lower()
            for _, kw in ipairs(BAD_KEYWORDS) do if n:find(kw) then return true end end
            return false
        end

        for _, d in ipairs(container:GetDescendants()) do
            if d:IsA("MeshPart") or d:IsA("BasePart") then
                local n = d.Name:lower()
                if not isBadName(n) then
                    -- Спуфим прозрачность для створок
                    if d.Transparency >= 0.99 then
                        d.Transparency = 0.99
                        table.insert(spoofedParts, d)
                    end

                    local hl = Instance.new("Highlight")
                    hl.Name = "NL_EntityESP"
                    hl.Adornee = d
                    hl.FillColor = EntityESP_Data.Color
                    hl.FillTransparency = 0.99  -- ═══ 90% прозрачности ═══
                    hl.OutlineColor = EntityESP_Data.Color
                    hl.OutlineTransparency = 0 -- Обводка остается четкой
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = container_ui
                    table.insert(highlights, hl)
                end
            end
        end
    else
        local hl = Instance.new("Highlight")
        hl.Name = "NL_EntityESP"
        hl.Adornee = container
        hl.FillColor = EntityESP_Data.Color
        hl.FillTransparency = 0.85
        hl.OutlineColor = EntityESP_Data.Color
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = container_ui
        table.insert(highlights, hl)
    end

    local bbCircle = Instance.new("BillboardGui")
    bbCircle.Name = "NL_EntityESP_Circle"
    bbCircle.Adornee = container
    bbCircle.Size = UDim2.new(16, 0, 16, 0)
    bbCircle.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
    bbCircle.AlwaysOnTop = true
    bbCircle.MaxDistance = 800
    bbCircle.LightInfluence = 0
    bbCircle.Parent = container_ui

    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.Size = UDim2.new(0.8, 0, 0.8, 0)
    circle.BackgroundColor3 = EntityESP_Data.Color
    circle.BackgroundTransparency = 0.85
    circle.BorderSizePixel = 0
    circle.Parent = bbCircle

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = circle

    local stroke = Instance.new("UIStroke")
    stroke.Color = EntityESP_Data.Color
    stroke.Thickness = 3
    stroke.Transparency = 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = circle

    if entityName == "Good People" then
        bbCircle.Enabled = false
    end

    local bbText = Instance.new("BillboardGui")
    bbText.Name = "NL_EntityESP_Billboard"
    bbText.Adornee = container
    bbText.Size = UDim2.new(0, 200, 0, 24)
    bbText.StudsOffset = Vector3.new(0, 8, 0)
    bbText.AlwaysOnTop = true
    bbText.MaxDistance = 1000
    bbText.LightInfluence = 0
    bbText.Parent = container_ui

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = entityName .. " [0]"
    lbl.TextColor3 = EntityESP_Data.Color
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.TextStrokeTransparency = 0
    lbl.TextSize = 16
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bbText

    EntityESP_Data.Objects[container] = {
        Highlights = highlights,
        Circle = bbCircle,
        CircleFrame = circle,
        Stroke = stroke,
        Billboard = bbText,
        Label = lbl,
        Anchor = container,
        EntityName = entityName,
        IsVisible = true,
        SpoofedParts = spoofedParts -- ═══ ТЕПЕРЬ ТУТ ВСЕ ЧАСТИ ═══
    }
end

EntityUtils.Remove = function(container)
    local data = EntityESP_Data.Objects[container]
    if not data then return end

    if data.SpoofedParts then
        for _, part in ipairs(data.SpoofedParts) do
            if part and part.Parent then
                part.Transparency = 1
            end
        end
    end

    pcall(function() 
        if data.Highlights then
            for _, hl in ipairs(data.Highlights) do hl:Destroy() end
        elseif data.Highlight then 
            data.Highlight:Destroy() 
        end
    end)
    pcall(function() if data.Circle then data.Circle:Destroy() end end)
    pcall(function() if data.Billboard then data.Billboard:Destroy() end end)
    
    -- Возвращаем табличку
    if data.EntityName == "Good People" and container.Parent then
        for _, part in ipairs(container:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                if part.LocalTransparencyModifier == 1 then
                    part.LocalTransparencyModifier = 0
                end
            end
        end
    end
    EntityESP_Data.Objects[container] = nil
end

EntityUtils.ClearAll = function()
    for c in pairs(EntityESP_Data.Objects) do EntityUtils.Remove(c) end
    EntityESP_Data.Objects = {}
    pcall(function()
        local roots = {LocalPlayer:FindFirstChild("PlayerGui"), game:GetService("CoreGui")}
        for _, root in ipairs(roots) do
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    local n = obj.Name
                    if n == "NL_EntityESP_Billboard" or n == "NL_EntityESP" or n == "NL_EntityESP_Circle" then 
                        obj:Destroy() 
                    end
                end
            end
        end
    end)
end

EntityUtils.Scan = function()
    if not EntityESP_Data.Enabled and not EntityESP_Data.NotifyEnabled then return end
    
    local charactersFolder = workspace:FindFirstChild("GameplayFolder") and workspace.GameplayFolder:FindFirstChild("Characters")
    local roomsFolder = workspace:FindFirstChild("GameplayFolder") and workspace.GameplayFolder:FindFirstChild("Rooms")
    
    local function checkObj(obj)
        if obj:IsA("Model") or obj:IsA("BasePart") then
            -- Игнорируем части внутри моделей (фикс двойного текста)
            if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") then
                local isParentSelected = EntityUtils.MatchEntity(obj.Parent.Name)
                if isParentSelected then return end
            end

            local isSelected, matchedName = EntityUtils.MatchEntity(obj.Name)
            
            if isSelected then
                -- ═══ ФИКС: Создаем ESP ТОЛЬКО если Entity ESP включен ═══
                if EntityESP_Data.Enabled then
                    local hasParentESP = false
                    local parent = obj.Parent
                    while parent and parent ~= workspace do
                        if EntityESP_Data.Objects[parent] then
                            hasParentESP = true
                            break
                        end
                        parent = parent.Parent
                    end
                    
                    if not hasParentESP and not EntityESP_Data.Objects[obj] then
                        EntityUtils.Create(obj, matchedName)
                    end
                end

                -- ═══ Notify логика (без Good People) ═══
                if EntityESP_Data.NotifyEnabled and matchedName ~= "Good People" then
                    if not EntityESP_Data.NotifiedEntities[obj] then
                        EntityESP_Data.NotifiedEntities[obj] = true
                        
                        local now = tick()
                        if not EntityESP_Data.LastNotifyTime or (now - EntityESP_Data.LastNotifyTime) > 1.5 then
                            EntityESP_Data.LastNotifyTime = now
                            task.spawn(function() 
                                task.wait(0.05)
                                pcall(function()
                                    Window:Notify({
                                        Title = "Synapse | Entity",
                                        Content = tostring(matchedName) .. " заспавнился",
                                        Type = "Warning",
                                        Duration = 5
                                    })
                                end)
                                pcall(function()
                                    local s = Instance.new("Sound", game:GetService("SoundService"))
                                    s.SoundId = "rbxassetid://4590662766"
                                    s.Volume = 5
                                    s.PlayOnRemove = true
                                    s:Destroy()
                                end)
                            end)
                        end
                    end
                end
            end
        end
    end
    
    -- 1. Сканируем Characters
    if charactersFolder then
        for _, obj in ipairs(charactersFolder:GetDescendants()) do
            checkObj(obj)
        end
    end
    
    -- 2. Сканируем прямых детей Workspace
    for _, obj in ipairs(workspace:GetChildren()) do
        checkObj(obj)
    end
    
    -- 3. Сканируем комнаты (только прямых детей, чтобы не лагало)
    if roomsFolder then
        for _, obj in ipairs(roomsFolder:GetChildren()) do
            checkObj(obj)
        end
    end
    
    -- Очистка мертвых объектов
    for obj in pairs(EntityESP_Data.NotifiedEntities) do
        if not obj.Parent then 
            EntityESP_Data.NotifiedEntities[obj] = nil 
        end
    end
end

EntityUtils.UpdateTexts = function()
    if not EntityESP_Data.Enabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local myPos = hrp.Position
    
    local pRoom = GetPlayerRoom()
    if pRoom and pRoom ~= CurrentRoomModel then CurrentRoomModel = pRoom end
    
    for c, data in pairs(EntityESP_Data.Objects) do
        if not c.Parent then 
            EntityUtils.Remove(c) 
            continue 
        end
        
        local isVisible = true
        
        -- ═══ ФИКС 2+2=4: Скрываем всё, что не в текущей комнате ═══
        if data.EntityName == "Good People" then
            if CurrentRoomModel then
                isVisible = c:IsDescendantOf(CurrentRoomModel)
            else
                isVisible = false
            end
        end
        
        -- ═══ Плавное скрытие/показ (FadeESP) ═══

        local fill = isVisible and (data.EntityName == "Good People" and 0.5 or 0.85) or 1
        local outline = isVisible and 0 or 1
        local text = isVisible and 0 or 1
        
        if data.Highlights then
            for _, hl in ipairs(data.Highlights) do
                hl.FillTransparency = fill
                hl.OutlineTransparency = outline
            end
        elseif data.Highlight then
            data.Highlight.FillTransparency = fill
            data.Highlight.OutlineTransparency = outline
        end
        if data.CircleFrame then
            data.CircleFrame.BackgroundTransparency = isVisible and 0.85 or 1
        end
        if data.Stroke then
            data.Stroke.Transparency = outline
        end
        if data.Billboard then
            for _, obj in ipairs(data.Billboard:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    obj.TextTransparency = text
                    obj.TextStrokeTransparency = text
                end
            end
        end
        
        -- Обновляем текст, только если видно
        if isVisible and data.Label then
            local pos = Vector3.zero
            -- ═══ ФИКС: Безопасно берем позицию (чтобы не было [0]) ═══
            if data.Anchor and data.Anchor.Parent then
                if data.Anchor:IsA("Model") then
                    local ok, pivot = pcall(function() return data.Anchor:GetPivot().Position end)
                    if ok and pivot then pos = pivot else pos = data.Anchor.Position end
                elseif data.Anchor:IsA("BasePart") then
                    pos = data.Anchor.Position
                end
            else
                EntityUtils.Remove(c)
                continue
            end
            
            local dist = math.floor((myPos - pos).Magnitude)
            local newText = data.EntityName .. " [" .. dist .. "]"
            if data.Label.Text ~= newText then data.Label.Text = newText end
        end
	end
end

EntityUtils.Start = function()
    EntityUtils.Scan()
    
    if EntityESP_Data.SpoofRenderConn then EntityESP_Data.SpoofRenderConn:Disconnect() end
    EntityESP_Data.SpoofRenderConn = RunService.RenderStepped:Connect(function()
        if not EntityESP_Data.Enabled then return end
        for _, data in pairs(EntityESP_Data.Objects) do
            if data.EntityName == "Good People" and data.SpoofedParts then
                for _, part in ipairs(data.SpoofedParts) do
                    if part and part.Parent and part.Transparency ~= 0.99 then
                        part.Transparency = 0.99
                    end
                end
            end
        end
    end)

    EntityESP_Data.Conn = workspace.DescendantAdded:Connect(function(obj)
        if not EntityESP_Data.Enabled and not EntityESP_Data.NotifyEnabled then return end
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local isSelected = EntityUtils.MatchEntity(obj.Name)
            if isSelected then
                task.wait(0.1)
                if obj.Parent then
                    EntityUtils.Scan()
                end
            end
        end
    end)
end

EntityUtils.Stop = function()
    if EntityESP_Data.SpoofRenderConn then
        EntityESP_Data.SpoofRenderConn:Disconnect()
        EntityESP_Data.SpoofRenderConn = nil
    end
    if EntityESP_Data.Conn then 
        EntityESP_Data.Conn:Disconnect() 
        EntityESP_Data.Conn = nil 
    end
end

-- ═══ ТОГГЛ ═══
MakeESP("Entity ESP", "Подсвечивает монстров", Color3.fromRGB(255, 50, 50), "EntityESP", "EntityESPColor", function(value)
    EntityESP_Data.Enabled = value
    if value then 
        EntityESP_Data.NotifiedEntities = {}
        EntityUtils.Start() 
    else 
        EntityUtils.Stop() 
        EntityUtils.ClearAll() 
    end
end, function(color)
    EntityESP_Data.Color = color
    for _, data in pairs(EntityESP_Data.Objects) do
        pcall(function() 
            if data.Highlights then
                for _, hl in ipairs(data.Highlights) do
                    hl.FillColor = color 
                    hl.OutlineColor = color
                end
            elseif data.Highlight then
                data.Highlight.FillColor = color 
                data.Highlight.OutlineColor = color 
            end
        end)
        pcall(function() if data.CircleFrame then data.CircleFrame.BackgroundColor3 = color end end)
        pcall(function() if data.Stroke then data.Stroke.Color = color end end)
        pcall(function() if data.Label then data.Label.TextColor3 = color end end)
    end
end)

-- ═══ NOTIFY ENTITY ═══
VisualsTab:Toggle({
    Name = "Notify Entity",
    Desc = "Уведомляет о появлении монстров",
    Default = false,
    Flag = "NotifyEntity",
    Callback = function(value)
        EntityESP_Data.NotifyEnabled = value
    end
})

-- ═══ ФИЛЬТР ═══
VisualsTab:Dropdown({
    Name = "Entity Filter",
    Desc = "Cписок сущностей",
    Options = EntityESP_Data.ALL_ENTITIES,
    Default = EntityESP_Data.ALL_ENTITIES,
    Multi = true,
    Callback = function(selectedList)
        for name in pairs(EntityESP_Data.SelectedEntities) do EntityESP_Data.SelectedEntities[name] = false end
        for _, name in ipairs(selectedList) do EntityESP_Data.SelectedEntities[name] = true end
        if EntityESP_Data.Enabled then EntityUtils.Scan() end
    end
})

-- ═══ ЕДИНЫЙ ЦИКЛ ОБНОВЛЕНИЯ ═══
task.spawn(function()
    while task.wait(0.3) do
        if EntityESP_Data.Enabled or EntityESP_Data.NotifyEnabled then 
            EntityUtils.Scan() 
            if EntityESP_Data.Enabled then EntityUtils.UpdateTexts() end
        end
    end
end)

RegisterCleanup("EntityESP", function()
    EntityESP_Data.Enabled = false
    EntityUtils.Stop()
    EntityUtils.ClearAll()
end)

    task.spawn(function()
        local lastItemScan = 0
        while task.wait(0.1) do
            if _G.SynapseUnloaded then break end
            
            -- ═══ ОПТИМИЗАЦИЯ: Обновляем комнату ОДИН раз за тик ═══
            local pRoom = GetPlayerRoom()
            if pRoom then CurrentRoomModel = pRoom end

            if DoorESP_Enabled   then pcall(UpdateDoorTexts)   end
            if LockerESP_Enabled then pcall(UpdateLockerTexts) end
            if KeyESP_Enabled    then pcall(UpdateKeyTexts)    end
            if LeverESP_Enabled  then pcall(UpdateLeverTexts)  end
            if GenESP_Data.Enabled then pcall(GenESP_Utils.UpdateTexts) end

            -- ═══ ОПТИМИЗАЦИЯ: Сканируем предметы раз в 1 секунду, а не 10 ═══
            if (ItemESP_Enabled or CurrencyESP_Enabled) and tick() - lastItemScan > 1 then
                lastItemScan = tick()
                pcall(function()
                    ScanForItems()
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local myPos = hrp and hrp.Position or Vector3.zero
                    
                    for obj, data in pairs(ESP_Objects) do
                        local remove = false
                        if not obj.Parent then remove = true
                        elseif data.IsCurrency and (not CurrencyESP_Enabled or not CurrencyFilter[data.Value]) then remove = true
                        elseif not data.IsCurrency and not ItemESP_Enabled then remove = true
                        end
                        
                        if remove then
                            if data.Highlight then data.Highlight:Destroy() end
                            if data.Billboard then data.Billboard:Destroy() end
                            ESP_Objects[obj] = nil
                        else
                            local isVisible = true
                            if CurrentRoomModel then isVisible = obj:IsDescendantOf(CurrentRoomModel) end
                            
                            if data.IsVisible ~= isVisible then
                                data.IsVisible = isVisible
                                FadeESP(data, isVisible)
                            end
                            
                            if isVisible then
                                local pos = Vector3.zero
                                if obj:IsA("Model") then
                                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                                    if part then pos = part.Position else
                                        local ok, pivot = pcall(function() return obj:GetPivot().Position end)
                                        if ok then pos = pivot end
                                    end
                                elseif obj:IsA("BasePart") then pos = obj.Position end
                                
                                local dist = math.floor((myPos - pos).Magnitude)
                                if data.Label then
                                    local prefix = data.Label.Text:match("^(.*)%[")
                                    if prefix then data.Label.Text = prefix .. "[" .. dist .. "]" end
                                end
                            end
                        end
                    end
                end)
            end

            if CurRomEnabled and CurRomLabel then
                if LastRoomModel and LastRoomModel.Name:lower() == "start" then
                    CurRomLabel.Text = "Start (101)"
                elseif CurrentRoomNum == -999 then
                    CurRomLabel.Text = (LastRoomModel and LastRoomModel.Name or "nil") .. " (nil)"
                else
                    CurRomLabel.Text = (LastRoomModel and LastRoomModel.Name or "nil") .. " (" .. tostring(CurrentRoomNum) .. ")"
                end
            end

            if DBListEnabled and DBListLabel then
                local text = ""
                local sortedNums = {}
                for num, _ in pairs(RoomByNumber) do table.insert(sortedNums, num) end
                table.sort(sortedNums, function(a, b) return a > b end)
                
                for _, num in ipairs(sortedNums) do
                    local roomModel = RoomByNumber[num]
                    local name = roomModel and roomModel.Name or "Unknown"
                    text = text .. name .. " = " .. num .. "\n"
                end
                if DBListLabel.Text ~= text then DBListLabel.Text = text end
            end
        end
    end)

	
	end

	-- ═══════════════════════════════════════════════════════════
	-- 8. SETTINGS TAB
	-- ═══════════════════════════════════════════════════════════
	SettingsTab:Section({Name = "Menu"})

	SettingsTab:Button({
		Name = "Unload",
		Desc = "Выгрузить скрипт",
		Icon = "lucide:power",
		Style = "Danger",
		Callback = function()
			_G.SynapseUnloaded = true
			_G.SynapseLoaded = false
			
			-- ═══ ФОРС-СБРОС JUMP ═══
			AllowJumpEnabled = false
			InfinityJumpEnabled = false
			SitGuard = false
			if JumpConn then JumpConn:Disconnect() JumpConn = nil end
			if SitBlockConn then SitBlockConn:Disconnect() SitBlockConn = nil end
			if SitHeartbeatConn then SitHeartbeatConn:Disconnect() SitHeartbeatConn = nil end
			if SitChangedConn then SitChangedConn:Disconnect() SitChangedConn = nil end
			if SeatedConn then SeatedConn:Disconnect() SeatedConn = nil end
			
			pcall(function()
				local char = LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Sit then hum.Sit = false end
			end)
			
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
			
			-- ═══ Даем библиотеке закончить анимацию ═══
			task.wait(0.2)
			
			-- ═══ Уничтожаем UI ═══
			pcall(function()
				if Window and Window.Destroy then
					Window:Destroy()
				end
			end)
			
			-- ═══ ТОТАЛЬНАЯ ЗАЧИСТКА ВСЕХ ИНТЕРФЕЙСОВ ═══
			pcall(function()
				local roots = {LocalPlayer:FindFirstChild("PlayerGui"), game:GetService("CoreGui"), gethui and gethui()}
				for _, root in ipairs(roots) do
					if root then
						for _, obj in ipairs(root:GetDescendants()) do
							local n = obj.Name
							if n:find("Synapse") or n:find("Airflow") or n:find("NL_") then
								obj:Destroy()
							end
						end
					end
				end
			end)
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

    data.SpeedValue = SpeedValue
    data.SpeedEnabled = SpeedEnabled
    
    data.Keybinds = {}
    data.KeybindStates = {}
    if _G.KeybindRegistry then
        for id, kb in pairs(_G.KeybindRegistry) do
            if kb.Key then data.Keybinds[id] = kb.Key.Name end
            data.KeybindStates[id] = kb.State or false
        end
    end
    return data
end

local function ApplyExtra(data)
    if type(data) ~= "table" then return end

    -- Дальше твой старый код (Speed, Keybinds и т.д.)
    if data.MenuKeybind then
        local kc = Enum.KeyCode[data.MenuKeybind]
        if kc and Window.SetKeybind then pcall(function() Window:SetKeybind(kc) end) end
    end
    if data.KeybindListEnabled ~= nil then
        KeybindListEnabled = data.KeybindListEnabled
        if KeybindListEnabled then
            if CreateKeybindGui then pcall(CreateKeybindGui) end
            if RefreshKeybindList then pcall(RefreshKeybindList) end
        else
            if DestroyKeybindGui then pcall(DestroyKeybindGui) end
        end
    end
    if data.Keybinds and _G.KeybindRegistry then
        for id, keyName in pairs(data.Keybinds) do
            local kc = Enum.KeyCode[keyName]
            if kc and _G.KeybindRegistry[id] then _G.KeybindRegistry[id].Key = kc end
        end
    end
    if RefreshKeybindList then pcall(RefreshKeybindList) end
    if _G.RefreshRebindSquares then pcall(_G.RefreshRebindSquares) end
    if data.KeybindStates and _G.KeybindRegistry then
        for id, state in pairs(data.KeybindStates) do
            local kb = _G.KeybindRegistry[id]
            if kb then
                kb.State = state
                if kb.Callback then pcall(kb.Callback, state) end
            end
        end
    end
    if RefreshKeybindList then pcall(RefreshKeybindList) end
    if data.SpeedValue ~= nil then SpeedValue = data.SpeedValue end
	    -- ═══ ФИКС: Обновляем визуально ползунок ═══
    if SpeedSlider and SpeedSlider.Set then
        pcall(function() SpeedSlider:Set(SpeedValue, true) end) -- true = не вызывать Callback повторно
    end
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
		Desc = "Сохранить конфиг/Перезаписать",
		Icon = "lucide:save",
		Style = "Primary",
		Callback = function()
			local name = ConfigNameInput:Get()
			if not name or #name == 0 then
				Window:Notify({Title = "Config", Content = "Введи имя", Type = "Warning", Duration = 3})
				return
			end
			name = tostring(name) -- На всякий случай
			local ok, err = Window:SaveConfig(name)
			SaveExtra(name)
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
		Desc = "Загрузить конфиг",
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
	
	RegisterKeybind("SpeedBoost", "Speed Boost", Enum.KeyCode.B, function(state)
		SpeedEnabled = state
		if SpeedToggle then
			local methods = {"Set", "SetValue", "Update", "UpdateValue", "SetState"}
			for _, m in ipairs(methods) do
				if SpeedToggle[m] then
					pcall(function() SpeedToggle[m](SpeedToggle, state) end)
					break
				end
			end
		end
	end, "Toggle")

	RegisterKeybind("Noclip", "Noclip", Enum.KeyCode.N, function(state)
		SetNoclip(state, false)
	end, "Toggle")
	
		RegisterKeybind("PositionSpoof", "Position Spoof", Enum.KeyCode.P, function(state)
		if PositionSpoofToggle then
			local methods = {"Set", "SetValue", "Update", "UpdateValue", "SetState"}
			for _, m in ipairs(methods) do
				if PositionSpoofToggle[m] then
					pcall(function() PositionSpoofToggle[m](PositionSpoofToggle, state) end)
					break
				end
			end
		end
	end, "Toggle")

	RegisterKeybind("AutoInteract", "Auto Interact", Enum.KeyCode.F, function(state)
		if AutoInteractToggle then
			local methods = {"Set", "SetValue", "Update", "UpdateValue", "SetState"}
			for _, m in ipairs(methods) do
				if AutoInteractToggle[m] then
					pcall(function() AutoInteractToggle[m](AutoInteractToggle, state) end)
					break
				end
			end
		end
	end, "Toggle")

	CreateKeybindSquare(SpeedToggle, "SpeedBoost")
	CreateKeybindSquare(NoclipToggle, "Noclip")
	CreateKeybindSquare(PositionSpoofToggle, "PositionSpoof")
	CreateKeybindSquare(AutoInteractToggle, "AutoInteract")
	
		-- ═══ Settings -> DEV ═══
	SettingsTab:Section({Name = "DEV"})

	SettingsTab:Toggle({
		Name = "CurRom",
		Desc = "Показывает комнату, в которой ты находишься",
		Flag = "CurRomUI",
		Default = false,
		Callback = function(value)
			CurRomEnabled = value
			if value then CreateCurRomGui() else DestroyCurRomGui() end
		end
	})

	SettingsTab:Toggle({
		Name = "DB List",
		Desc = "Показывает все комнаты в базе данных",
		Flag = "DBListUI",
		Default = false,
		Callback = function(value)
			DBListEnabled = value
			if value then CreateDBListGui() else DestroyDBListGui() end
		end
	})

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
					-- Вызываем нашу новую чистую функцию загрузки!
					ApplyExtra(data)
				end
			end
		end
		
		-- ═══ Обновляем Desc у Rebind-кнопок ═══
		if _G.UpdateRebindDesc then
			pcall(_G.UpdateRebindDesc, "SpeedBoost")
			pcall(_G.UpdateRebindDesc, "Noclip")
		end
		
		pcall(function()
			Window:Notify({Title = "Auto Load", Content = "Загружен: " .. name, Type = "Success", Duration = 4})
		end)
	end)
	
		-- ═══ СИНХРОНИЗАЦИЯ КВАДРАТИКОВ БИНДОВ ═══
	_G.RefreshRebindSquares = function()
		if not _G.RebindBtns then return end
		for id, btn in pairs(_G.RebindBtns) do
			if btn and btn.Parent and RebindingState ~= id then
				local kb = _G.KeybindRegistry[id]
				local keyName = kb and kb.Key and kb.Key.Name or "?"
				if btn.Text ~= keyName and btn.Text ~= "..." then
					btn.Text = keyName
				end
			end
		end
	end

	-- Запускаем цикл обновления (если его нет)
	task.spawn(function()
		while task.wait(0.5) do
			if _G.SynapseUnloaded then break end
			_G.RefreshRebindSquares()
		end
	end)

	if _G.SynapseInputConn then _G.SynapseInputConn:Disconnect() end
	
	_G.SynapseInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if _G.SynapseUnloaded then return end
		if gameProcessed then return end
		if RebindingId or RebindingState then return end
		
		if not _G.KeybindRegistry then return end
		
		for id, kb in pairs(_G.KeybindRegistry) do
			if kb.Key and kb.Key ~= Enum.KeyCode.Unknown and kb.Key == input.KeyCode then
				if kb.Mode == "Toggle" then
					kb.State = not kb.State
					if kb.Callback then pcall(kb.Callback, kb.State) end
				else
					kb.State = true
					if kb.Callback then pcall(kb.Callback, true) end
				end
				if RefreshKeybindList then RefreshKeybindList() end
			end
		end
	end)
	
	print("FROV")
