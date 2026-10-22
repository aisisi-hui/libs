local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/aisisi-hui/libs/refs/heads/main/skeet-like/Library.lua"))()

local Window = Lib:CreateWindow({
	Title = "LIB",
	Name = "your.lib",
	Accent = Color3.fromRGB(180, 227, 74),
	MenuKey = Enum.KeyCode.RightShift,
	ConfigFolder = "yourlib",
	TabsSide = "Right",
	Font = "BuilderSans",
})

local Combat = Window:AddTab("Combat")

local Aimbot = Combat:AddGroup("Aimbot", "Left")
local aim = Aimbot:AddToggle({ Name = "Enabled", Default = true, Flag = "aim_on" })
aim:AddKeybind({ Default = Enum.UserInputType.MouseButton2, Mode = "Hold" })
local aimExtra = aim:AddSettings()
aimExtra:AddToggle({ Name = "Prediction", Flag = "aim_pred" })
aimExtra:AddSlider({ Name = "Prediction amount", Min = 0, Max = 100, Default = 35, Suffix = "%", Flag = "aim_predv" })
aimExtra:AddToggle({ Name = "Sticky target", Default = true, Flag = "aim_sticky" })
Aimbot:AddToggle({ Name = "Visible only", Default = true, Flag = "aim_vis" })
Aimbot:AddToggle({ Name = "Team check", Flag = "aim_team" })
Aimbot:AddToggle({ Name = "Draw FOV", Default = true, Flag = "aim_fovc" }):AddColor({ Default = Color3.new(1, 1, 1), Flag = "aim_fovc_col" })
Aimbot:AddDropdown({ Name = "Target part", Options = { "Head", "Torso", "Closest" }, Default = "Head", Flag = "aim_part" })
Aimbot:AddSlider({ Name = "FOV", Min = 0, Max = 360, Default = 90, Suffix = "°", Flag = "aim_fov" })
Aimbot:AddSlider({ Name = "Smoothing", Min = 1, Max = 20, Default = 6, Flag = "aim_smooth" })

local Trigger = Combat:AddGroup("Triggerbot", "Right")
Trigger:AddToggle({ Name = "Enabled", Flag = "tb_on" }):AddKeybind({ Default = Enum.KeyCode.LeftAlt, Mode = "Hold" })
Trigger:AddToggle({ Name = "Wall check", Default = true, Flag = "tb_wall" })
Trigger:AddSlider({ Name = "Delay", Min = 0, Max = 300, Default = 45, Suffix = "ms", Flag = "tb_delay" })

local Other = Combat:AddGroup("Other", "Right")
Other:AddToggle({ Name = "Silent aim", Flag = "sa_on" })
Other:AddSlider({ Name = "Hit chance", Min = 0, Max = 100, Default = 100, Suffix = "%", Flag = "sa_hc" })

local Visuals = Window:AddTab("Visuals")

local Players = Visuals:AddGroup("Players", "Left")
local boxEsp = Players:AddToggle({ Name = "Box", Default = true, Flag = "esp_box" })
boxEsp:AddColor({ Default = Color3.new(1, 1, 1), Flag = "esp_box_col" })
local boxExtra = boxEsp:AddSettings()
boxExtra:AddDropdown({ Name = "Style", Options = { "2D", "Corner", "3D" }, Default = "Corner", Flag = "box_style" })
boxExtra:AddToggle({ Name = "Outline", Default = true, Flag = "box_out" })
boxExtra:AddToggle({ Name = "Filled", Flag = "box_fill" })
boxExtra:AddSlider({ Name = "Thickness", Min = 1, Max = 4, Default = 1, Suffix = "px", Flag = "box_th" })
Players:AddToggle({ Name = "Name", Default = true, Flag = "esp_name" }):AddColor({ Default = Color3.new(1, 1, 1), Flag = "esp_name_col" })
local hp = Players:AddToggle({ Name = "Health bar", Default = true, Flag = "esp_hp" })
local hpExtra = hp:AddSettings()
hpExtra:AddToggle({ Name = "Show number", Default = true, Flag = "hp_num" })
hpExtra:AddDropdown({ Name = "Position", Options = { "Left", "Right", "Bottom" }, Default = "Left", Flag = "hp_side" })
Players:AddToggle({ Name = "Distance", Flag = "esp_dist" })
local tracers = Players:AddToggle({ Name = "Tracers", Flag = "esp_tr" })
tracers:AddColor({ Default = Color3.fromHex("#ff5a6e"), Flag = "esp_tr_col" })
local trExtra = tracers:AddSettings()
trExtra:AddDropdown({ Name = "Origin", Options = { "Bottom", "Center", "Mouse" }, Default = "Bottom", Flag = "tr_from" })
trExtra:AddSlider({ Name = "Thickness", Min = 1, Max = 4, Default = 1, Suffix = "px", Flag = "tr_th" })

local World = Visuals:AddGroup("World", "Right")
World:AddToggle({ Name = "Fullbright", Flag = "w_bright" })
World:AddToggle({ Name = "No fog", Default = true, Flag = "w_fog" })
World:AddSlider({ Name = "Camera FOV", Min = 70, Max = 120, Default = 90, Suffix = "°", Flag = "w_fov" })

local Chams = Visuals:AddGroup("Chams", "Right")
local ch = Chams:AddToggle({ Name = "Enabled", Default = true, Flag = "ch_on" })
ch:AddColor({ Default = Color3.fromHex("#6ea8ff"), Flag = "ch_col" })
local chExtra = ch:AddSettings()
chExtra:AddDropdown({ Name = "Material", Options = { "Flat", "Glow", "Wireframe" }, Default = "Glow", Flag = "ch_mat" })
chExtra:AddSlider({ Name = "Transparency", Min = 0, Max = 100, Default = 40, Suffix = "%", Flag = "ch_tr" })
Chams:AddToggle({ Name = "Behind walls", Flag = "ch_occ" }):AddColor({ Default = Color3.fromHex("#c38bff"), Flag = "ch_occ_col" })

local Movement = Window:AddTab("Movement")

local Character = Movement:AddGroup("Character", "Left")
local speed = Character:AddToggle({ Name = "Speed", Flag = "mv_speed" })
speed:AddKeybind({ Default = Enum.KeyCode.X, Mode = "Toggle" })
speed:AddSettings():AddSlider({ Name = "Walkspeed", Min = 16, Max = 200, Default = 32, Flag = "mv_ws" })
Character:AddToggle({ Name = "Infinite jump", Default = true, Flag = "mv_ij" })
local fly = Character:AddToggle({ Name = "Fly", Default = true, Flag = "mv_fly" })
fly:AddKeybind({ Default = Enum.KeyCode.F, Mode = "Toggle" })
local flyExtra = fly:AddSettings()
flyExtra:AddDropdown({ Name = "Mode", Options = { "Velocity", "CFrame" }, Default = "Velocity", Flag = "mv_fm" })
flyExtra:AddSlider({ Name = "Speed", Min = 1, Max = 100, Default = 50, Flag = "mv_fs" })

local Misc = Movement:AddGroup("Misc", "Right")
Misc:AddToggle({ Name = "Noclip", Flag = "mv_nc" }):AddKeybind({ Default = Enum.KeyCode.N, Mode = "Toggle" })
Misc:AddToggle({ Name = "Anti-AFK", Default = true, Flag = "mv_afk" })

Window:AddSettingsTab()
