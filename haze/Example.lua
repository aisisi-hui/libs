local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/aisisi-hui/libs/refs/heads/main/haze/Library.lua"))()

-- Example setup
--------------------------------------------------------------------
local Window = Library.new({
	Title = "haze",
	Build = "dev-build",
	ToggleKey = Enum.KeyCode.RightShift,
	ConfigFolder = "my_script_configs", -- Folder used to save configs
	Logo = "rbxassetid://9525535512",
	Watermark = { "haze", "fps", "ping", "dev-build" }, -- First item uses the accent; fps/ping update automatically
})

local Combat = Window:Tab("Combat", "rbxassetid://135154486332477")
local Visuals = Window:Tab("Visuals", "rbxassetid://135154486332477")
local Movement = Window:Tab("Movement", "rbxassetid://135154486332477")

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

-- Build the ready-made config and interface settings after all feature controls.
Window:SettingsTab({ Icon = "rbxassetid://135154486332477" })

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
