local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/aisisi-hui/libs/refs/heads/main/haze/Library.lua"))()

-- Example setup
--------------------------------------------------------------------
local Window = Library.new({
	Title = "haze",
	Build = "dev-build",
	ToggleKey = Enum.KeyCode.RightShift,
	ConfigFolder = "my_script_configs", -- Folder used to save configs
	Logo = "rbxassetid://9525535512",
})

local Combat = Window:Tab("Combat", "rbxassetid://135154486332477")
local Visuals = Window:Tab("Visuals", "rbxassetid://135154486332477")
local Movement = Window:Tab("Movement", "rbxassetid://135154486332477")
local Settings = Window:Tab("Settings", "rbxassetid://135154486332477")

-- Visuals: two columns with sections that resize to fit their content
do
	local player = Visuals:Section("Player ESP", 225, 1)
	player:Header("ESP Highlights")

	local box = player:Toggle({ Name = "Box ESP", Flag = "BoxESP", Default = true })
	box:AddColorPicker({ Flag = "BoxColor", Default = Color3.fromRGB(0, 255, 120) })
	local boxSettings = box:AddSetting({ Name = "Box settings" })
	boxSettings:Slider({ Name = "Thickness", Flag = "BoxThickness", Min = 1, Max = 5, Default = 1, Step = 1, Suffix = "px" })
	boxSettings:Toggle({ Name = "Outline", Flag = "BoxOutline", Default = true })
	boxSettings:Toggle({ Name = "Fill", Flag = "BoxFill", Default = false })

	local name = player:Toggle({ Name = "Name ESP", Flag = "NameESP", Default = true })
	name:AddColorPicker({ Flag = "NameColor", Default = Color3.fromRGB(240, 240, 240) })

	player:Toggle({ Name = "Health Bar", Flag = "HealthBar", Default = true })

	local chams = Visuals:Section("Chams", 225, 1)
	chams:Toggle({ Name = "Chams Glow", Flag = "ChamsGlow", Default = false })
	chams:Slider({ Name = "Opacity", Flag = "ChamsOpacity", Min = 0, Max = 1, Default = 0.5, Step = 0.05 })

	local world = Visuals:Section("World ESP", 237, 2)
	world:Header("World Lighting")
	local amb = world:Toggle({ Name = "Ambient Override", Flag = "AmbientOverride", Default = false })
	amb:AddColorPicker({ Flag = "AmbientColor", Default = Color3.fromRGB(120, 80, 255) })
	world:Slider({ Name = "World Exposure", Flag = "WorldExposure", Min = 0, Max = 5, Default = 1, Step = 0.1, Suffix = "x" })

	local cam = Visuals:Section("Camera", 237, 2)
	cam:Slider({ Name = "Field of View", Flag = "CameraFOV", Min = 30, Max = 120, Default = 70, Step = 1, Suffix = "°" })

	local misc = Visuals:Section("Misc", 237, 2)
	misc:Toggle({ Name = "Crosshair", Flag = "Crosshair", Default = false })
	misc:Toggle({ Name = "Fullbright", Flag = "Fullbright", Default = false })
end

-- Combat: demonstrate all attachments available for a toggle
do
	local c = Combat:Section("Combat", 225)
	c:Header("General")
	local f = c:Toggle({ Name = "Feature A", Flag = "FeatureA" })
	f:AddColorPicker({ Flag = "FeatureAColor", Default = Color3.fromRGB(255, 70, 70) })
	f:AddKeybind({ Flag = "FeatureABind", Default = Enum.UserInputType.MouseButton2, Mode = "Hold" })
	local fs = f:AddSetting({ Name = "Feature A settings" })
	fs:Slider({ Name = "Value", Flag = "FeatureAValue", Min = 0, Max = 100, Default = 50, Step = 1 })
	fs:Dropdown({ Name = "Target", Flag = "FeatureATarget", Options = { "Head", "Torso", "Random" }, Default = "Head" })
	fs:Toggle({ Name = "Extra option", Flag = "FeatureAExtra" })

	local g = c:Toggle({ Name = "Feature B", Flag = "FeatureB" })
	g:AddKeybind({ Flag = "FeatureBBind", Default = Enum.KeyCode.X, Mode = "Toggle" })

	c:Slider({ Name = "Value A", Flag = "CombatValueA", Min = 0, Max = 100, Default = 50, Step = 1 })
end

-- Movement: overflowing content scrolls with a fade at the top and bottom
do
	for i, label in ipairs({ "Group A", "Group B", "Group C", "Group D", "Group E" }) do
		local m = Movement:Section(label, 225, 1)
		m:Toggle({ Name = "Option " .. i, Flag = "MoveOption" .. i })
		m:Slider({ Name = "Value " .. i, Flag = "MoveValue" .. i, Min = 0, Max = 100, Default = 50, Step = 1 })
	end

	-- The second column is shorter; scroll height follows the tallest column
	local side = Movement:Section("Side panel", 237, 2)
	side:Toggle({ Name = "Option X", Flag = "MoveOptionX" })
	side:Slider({ Name = "Value X", Flag = "MoveValueX", Min = 0, Max = 10, Default = 5, Step = 0.5 })
end

-- Settings: configs on the left, interface settings on the right
do
	local cfg = Settings:Section("Configs", 225, 1)
	local ui = Settings:Section("Interface", 237, 2)

	-- Interface settings are stored separately from configs
	ui:Header("Menu")
	ui:Toggle({
		Name = "Watermark", Flag = "Watermark", Default = true, NoSave = true,
		Callback = function(v) Window:SetWatermark(v) end,
	})
	ui:Toggle({
		Name = "Keybind list", Flag = "KeybindList", Default = true, NoSave = true,
		Callback = function(v) Window:SetKeybindList(v) end,
	})
	ui:Keybind({
		Name = "Menu key", Flag = "__MenuKeyBind", NoSave = true,
		Default = Window.MenuKey,
		Callback = function(key) Window:SetMenuKey(key) end,
	})
	ui:Button({ Name = "Unload", Callback = function() Window:Destroy() end })
	ui:Header("Appearance")
	ui:Dropdown({
		Name = "Theme", Flag = "__Theme", NoSave = true,
		Options = { "Default", "Graphite", "Midnight", "Amber", "Azure" }, Default = Window.Preferences.Theme,
		Callback = function(name)
			if name == Window.Preferences.Theme then return end
			local ok, err = Window:SetTheme(name)
			Window:Notify({ Title = "Theme", Text = ok and (name .. " applied") or err })
		end,
	})

	-- Configs
	local nameInput, listDD
	local options = {}
	local pendingDelete, deleteButton
	local autoloadButton
	local function cancelDelete()
		pendingDelete = nil
		if deleteButton then deleteButton.SetText("Delete") end
	end
	local function report(message)
		Window:Notify({ Title = "Configs", Text = message })
	end
	local function updateAutoloadStatus()
		if autoloadButton then
			local selected = Library.FS.normalize(listDD.Get())
			local active = selected ~= nil and Window.Preferences.Autoload == selected
			autoloadButton.SetColorRole(active and "Text" or "Dim")
		end
	end

	local function currentName()
		local n = nameInput.Get():gsub("^%s+", ""):gsub("%s+$", "")
		if n == "" then
			n = listDD.Get()
		end
		return n
	end

	local function refresh()
		local list, err = Window:RefreshConfigs()
		if not list then
			listDD.SetOptions({})
			report(err)
			return false
		end
		listDD.SetOptions(list)
		updateAutoloadStatus()
		return true
	end

	cfg:Header("Configs")
	listDD = cfg:Dropdown({
		Name = "Config list", Flag = "__cfgList", Options = options, NoSave = true,
		Callback = function(v)
			cancelDelete()
			if nameInput and v ~= "" then
				nameInput.Set(v)
			end
			updateAutoloadStatus()
		end,
	})
	nameInput = cfg:Input({
		Name = "Config name", Flag = "__cfgName", Placeholder = "new config",
		Callback = cancelDelete,
	})

	local function saveConfig()
		cancelDelete()
		local name = currentName()
		if name == "" then
			report("Enter a config name")
			return
		end
		local ok, err = Window:SaveConfig(name)
		if ok then
			report("Saved '" .. name .. "'")
			refresh()
			listDD.Set(Library.FS.normalize(name))
		else
			report(err)
		end
	end

	local function loadConfig()
		cancelDelete()
		local name = currentName()
		if name == "" then
			report("Select a config")
			return
		end
		local ok, err = Window:LoadConfig(name)
		if ok then
			report("Loaded '" .. name .. "'")
		else
			report(err)
		end
	end

	local function deleteConfig()
		local name = currentName()
		if name == "" then
			cancelDelete()
			report("Select a config")
			return
		end
		if pendingDelete ~= name then
			pendingDelete = name
			deleteButton.SetText("Sure?")
			return
		end
		cancelDelete()
		local ok, err = Window:DeleteConfig(name)
		updateAutoloadStatus()
		if ok then
			report("Deleted '" .. name .. "'")
			nameInput.Set("")
			refresh()
		else
			report(err)
		end
	end

	local function refreshConfigs()
		cancelDelete()
		if refresh() then
			report("List updated")
		end
	end

	cfg:ButtonRow({
		{ Name = "Save", Callback = saveConfig },
		{ Name = "Load", Callback = loadConfig },
	})
	local configActions = cfg:ButtonRow({
		{ Name = "Delete", Callback = deleteConfig },
		{ Name = "Refresh", Callback = refreshConfigs },
	})
	deleteButton = configActions[1]
	autoloadButton = cfg:Button({ Name = "Autoload", Callback = function()
		local name = Library.FS.normalize(listDD.Get())
		if not name then report("Select a saved config") return end
		local active = Window.Preferences.Autoload == name
		local target = name
		if active then target = false end
		local ok, err = Window:SetAutoload(target)
		updateAutoloadStatus()
		if ok then
			report(active and "Autoload disabled" or ("Autoload: " .. name))
		else
			report(err)
		end
	end })
	updateAutoloadStatus()
	refresh()
	if Window.Preferences.Autoload then
		local name = Window.Preferences.Autoload
		local ok, err = Window:LoadConfig(name)
		if ok then
			listDD.Set(Library.FS.normalize(name))
			nameInput.Set(name)
			report("Autoloaded '" .. name .. "'")
		else
			report("Autoload failed: " .. tostring(err))
		end
	end
end

-- Startup notification demo. Call Window:Notify from game event callbacks too.
for i = 1, 10 do
	local number = i
	task.delay((number - 1) * 0.4, function()
		if _G.HazeMenu ~= Window then return end
		Window:Notify({
			Title = "haze",
			Text = "Notification " .. number .. " / 10",
			Duration = 4,
		})
	end)
end

-- Library.Flags.BoxESP, Library.Flags.BoxColor, Library.Flags.FeatureABind,
