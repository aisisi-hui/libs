 local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/aisisi-hui/libs/refs/heads/main/stellar/Library.lua"))()

function Library:Round(Number, Float)
    if not Float or Float == 0 then
        return math.floor(Number + 0.5)
    end
    local Multiplier = 1 / Float
    return math.floor((Number * Multiplier) + 0.5) / Multiplier
end

local Watermark = Library:Watermark("stellar | showcase", "rbxassetid://81441172534384")

local Window = Library:Window({
    Name = "Stellar",
    SubName = "Showcase v1.0",
    Logo = "rbxassetid://81441172534384"
})

local CombatTab = Window:Page({
    Name = "Combat",
    Icon = "rbxassetid://72196061405823"
})

local AimbotSection = CombatTab:Section({
    Name = "Aimbot",
    Side = 1
})

local AimbotToggle = AimbotSection:Toggle({
    Name = "Enable Aimbot",
    Flag = "aim_enable",
    Default = false,
    Callback = function(State)
        print("[Stellar] Aimbot state:", State)
    end
})

AimbotToggle:Keybind({
    Flag = "aim_key",
    Default = Enum.KeyCode.E,
    Mode = "Toggle"
})

AimbotToggle:Colorpicker({
    Flag = "aim_target_col",
    Default = Color3.fromRGB(255, 65, 65),
    Callback = function(Col)
        print("[Stellar] Aimbot target color:", Col)
    end
})

local AimbotPopup = AimbotToggle:AddSettingPopup({
    Name = "Aimbot Settings"
})

AimbotPopup:Toggle({
    Name = "Visible Check",
    Flag = "aim_vischeck",
    Default = true,
    Callback = function(State)
        print("[Stellar] Visible check:", State)
    end
})

AimbotPopup:Slider({
    Name = "Smoothness",
    Flag = "aim_smooth",
    Min = 1,
    Max = 30,
    Default = 6,
    Decimals = 1,
    Callback = function(Value)
        print("[Stellar] Smoothness:", Value)
    end
})

AimbotPopup:Dropdown({
    Name = "Hitbox Priority",
    Flag = "aim_hitbox",
    Items = {"Head", "Torso", "Neck", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(Option)
        print("[Stellar] Target hitbox:", Option)
    end
})

AimbotPopup:Textbox({
    Name = "Target Player",
    Flag = "aim_custom_target",
    Placeholder = "Username...",
    Callback = function(Text)
        print("[Stellar] Target player set:", Text)
    end
})

AimbotSection:Slider({
    Name = "FOV Radius",
    Flag = "aim_fov",
    Min = 10,
    Max = 360,
    Default = 90,
    Suffix = "°",
    Decimals = 1,
    Callback = function(Value)
        print("[Stellar] FOV changed:", Value)
    end
})

AimbotSection:Dropdown({
    Name = "Target Priority",
    Flag = "aim_priority",
    Items = {"Crosshair", "Distance", "Lowest Health"},
    Default = "Crosshair",
    Callback = function(Selected)
        print("[Stellar] Target priority:", Selected)
    end
})

AimbotSection:Textbox({
    Name = "Prediction Ping",
    Flag = "aim_ping_pred",
    Placeholder = "Ping ms...",
    Default = "50",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        print("[Stellar] Prediction ping:", Value)
    end
})

AimbotSection:Button({
    Name = "Reset Aimbot Defaults",
    Callback = function()
        Library.Flags["aim_fov"] = 90
        print("[Stellar] Aimbot reset to defaults")
    end
})

local TriggerSection = CombatTab:Section({
    Name = "Triggerbot & Weapon",
    Side = 2
})

local TriggerToggle = TriggerSection:Toggle({
    Name = "Auto Shoot",
    Flag = "trigger_enable",
    Default = false,
    Callback = function(State)
        print("[Stellar] Triggerbot state:", State)
    end
})

TriggerToggle:Keybind({
    Flag = "trigger_key",
    Default = Enum.UserInputType.MouseButton2,
    Mode = "Hold"
})

TriggerSection:Slider({
    Name = "Trigger Delay",
    Flag = "trigger_delay",
    Min = 0,
    Max = 300,
    Default = 25,
    Suffix = "ms",
    Decimals = 1,
    Callback = function(Value)
        print("[Stellar] Trigger delay:", Value)
    end
})

TriggerSection:Dropdown({
    Name = "Weapon Whitelist",
    Flag = "trigger_whitelist",
    Items = {"Rifles", "Pistols", "Snipers", "Shotguns", "SMGs"},
    Default = {"Rifles", "Snipers"},
    Multi = true,
    Callback = function(Values)
        print("[Stellar] Whitelisted weapons:", table.concat(Values, ", "))
    end
})

TriggerSection:Textbox({
    Name = "Hit Sound Asset",
    Flag = "trigger_hitsound",
    Default = "rbxassetid://9114223170",
    Placeholder = "rbxassetid://...",
    Finished = true,
    Callback = function(Value)
        print("[Stellar] Custom hit sound:", Value)
    end
})

local PanicLabel = TriggerSection:Label("Emergency Panic Key")
PanicLabel:Keybind({
    Flag = "panic_key",
    Default = Enum.KeyCode.Delete,
    Mode = "Toggle"
})

TriggerSection:Button({
    Name = "Check Weapon States",
    Callback = function()
        local selected = Library.Flags["trigger_whitelist"] or {}
        print("[Stellar] Active whitelist:", table.concat(selected, ", "))
    end
})

local VisualsTab = Window:Page({
    Name = "Visuals",
    Icon = "rbxassetid://128742673777519"
})

local EspSection = VisualsTab:Section({
    Name = "Player ESP",
    Side = 1
})

local BoxToggle = EspSection:Toggle({
    Name = "Box ESP",
    Flag = "esp_box",
    Default = true,
    Callback = function(State)
        print("[Stellar] Box ESP state:", State)
    end
})

BoxToggle:Colorpicker({
    Flag = "esp_box_color",
    Default = Color3.fromRGB(0, 255, 140),
    Callback = function(Col)
        print("[Stellar] Box color:", Col)
    end
})

BoxToggle:Keybind({
    Flag = "esp_box_key",
    Default = Enum.KeyCode.X,
    Mode = "Toggle"
})

local BoxPopup = BoxToggle:AddSettingPopup({
    Name = "Box Styling"
})

BoxPopup:Toggle({
    Name = "Show Outline",
    Flag = "esp_box_outline",
    Default = true
})

BoxPopup:Slider({
    Name = "Outline Thickness",
    Flag = "esp_box_thick",
    Min = 1,
    Max = 5,
    Default = 1,
    Suffix = "px",
    Decimals = 1
})

BoxPopup:Dropdown({
    Name = "Box Type",
    Flag = "esp_box_type",
    Items = {"2D Full", "Corner Box", "3D Bounding"},
    Default = "2D Full"
})

local NameToggle = EspSection:Toggle({
    Name = "Player Names",
    Flag = "esp_names",
    Default = false
})

NameToggle:Colorpicker({
    Flag = "esp_names_col",
    Default = Color3.fromRGB(255, 255, 255)
})

EspSection:Slider({
    Name = "Max Distance",
    Flag = "esp_distance",
    Min = 50,
    Max = 3000,
    Default = 1200,
    Suffix = "m",
    Decimals = 1,
    Callback = function(Value)
        print("[Stellar] Max ESP distance:", Value)
    end
})

EspSection:Dropdown({
    Name = "ESP Flags",
    Flag = "esp_flags",
    Items = {"Distance", "Health Bar", "Equipped Weapon", "Armor", "Chams"},
    Default = {"Distance", "Health Bar"},
    Multi = true,
    Callback = function(Flags)
        print("[Stellar] Active ESP flags:", table.concat(Flags, ", "))
    end
})

local ChamsLabel = EspSection:Label("Chams Color")
ChamsLabel:Colorpicker({
    Flag = "esp_chams_col",
    Default = Color3.fromRGB(160, 32, 240),
    Callback = function(Col)
        print("[Stellar] Chams color:", Col)
    end
})

EspSection:Button({
    Name = "Toggle All ESP Off",
    Callback = function()
        print("[Stellar] Cleared visuals cache")
    end
})

local WorldSection = VisualsTab:Section({
    Name = "World & Interface",
    Side = 2
})

local AmbientToggle = WorldSection:Toggle({
    Name = "World Ambient",
    Flag = "world_ambient_enabled",
    Default = false,
    Callback = function(State)
        print("[Stellar] World ambient:", State)
    end
})

AmbientToggle:Colorpicker({
    Flag = "world_ambient_col",
    Default = Color3.fromRGB(120, 120, 255),
    Callback = function(Col)
        print("[Stellar] Ambient color:", Col)
    end
})

WorldSection:Slider({
    Name = "Camera FOV",
    Flag = "world_cam_fov",
    Min = 60,
    Max = 120,
    Default = 90,
    Suffix = "°",
    Decimals = 1,
    Callback = function(Value)
        local cam = workspace.CurrentCamera
        if cam then
            cam.FieldOfView = Value
        end
    end
})

WorldSection:Dropdown({
    Name = "Skybox Preset",
    Flag = "world_skybox",
    Items = {"Default", "Night Sky", "Purple Nebula", "Sunset", "Vaporwave"},
    Default = "Default",
    Callback = function(Sky)
        print("[Stellar] Skybox selected:", Sky)
    end
})

WorldSection:Textbox({
    Name = "Watermark Text",
    Flag = "ui_watermark_text",
    Default = "stellar | showcase",
    Placeholder = "Enter watermark...",
    Finished = true,
    Callback = function(NewText)
        if NewText and NewText ~= "" then
            Watermark:SetText(NewText)
            print("[Stellar] Watermark updated:", NewText)
        end
    end
})

local MenuBindLabel = WorldSection:Label("Menu Toggle Key")
MenuBindLabel:Keybind({
    Flag = "ui_menu_toggle_key",
    Default = Enum.KeyCode.RightControl,
    Mode = "Toggle"
})

local UiPreferences = WorldSection:AddSettingPopup({
    Name = "UI Preferences"
})

UiPreferences:Toggle({
    Name = "Show Watermark",
    Flag = "ui_show_watermark",
    Default = true,
    Callback = function(Visible)
        Watermark:SetVisibility(Visible)
    end
})

UiPreferences:Slider({
    Name = "Fade Speed",
    Flag = "ui_fade_speed",
    Min = 0.1,
    Max = 1.0,
    Default = 0.2,
    Decimals = 0.05,
    Suffix = "s",
    Callback = function(Speed)
        Library.FadeSpeed = Speed
    end
})

WorldSection:Button({
    Name = "Unload UI",
    Callback = function()
        task.defer(function()
            Library:Unload()
            print("[Stellar] Unloaded")
        end)
    end
})
