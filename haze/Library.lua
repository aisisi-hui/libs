local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local previousMenu = _G.HazeMenu or _G.IosMenu
if previousMenu then
	pcall(function()
		previousMenu:Destroy()
	end)
end
_G.HazeMenu = nil
_G.IosMenu = nil

local Theme = {
	Window = Color3.fromRGB(14, 14, 14),
	Panel = Color3.fromRGB(17, 17, 17),
	Stroke = Color3.fromRGB(40, 40, 40),
	WindowStroke = Color3.fromRGB(52, 52, 52),
	Hover = Color3.fromRGB(26, 26, 26),
	Pressed = Color3.fromRGB(44, 44, 44),
	HoverText = Color3.fromRGB(190, 190, 190),
	Text = Color3.fromRGB(240, 240, 240),
	Accent = Color3.fromRGB(240, 240, 240),
	Dim = Color3.fromRGB(125, 125, 125),
	Faint = Color3.fromRGB(90, 90, 90),
	Off = Color3.fromRGB(24, 24, 24),
	Track = Color3.fromRGB(42, 42, 42),
	Font = Font.new("rbxasset://fonts/families/Inter.json", Enum.FontWeight.Medium),
	FontBold = Font.new("rbxasset://fonts/families/Inter.json", Enum.FontWeight.Bold),
}

local CHECK = 13

local ThemePresets = { Default = table.clone(Theme) }
ThemePresets.Graphite = table.clone(Theme)
ThemePresets.Midnight = table.clone(Theme)
ThemePresets.Amber = table.clone(Theme)
ThemePresets.Azure = table.clone(Theme)
for role, color in pairs({
	Window = Color3.fromRGB(20, 22, 25), Panel = Color3.fromRGB(25, 28, 32),
	Stroke = Color3.fromRGB(48, 53, 60), WindowStroke = Color3.fromRGB(61, 68, 77),
	Off = Color3.fromRGB(32, 36, 41), Hover = Color3.fromRGB(38, 43, 49),
	Pressed = Color3.fromRGB(53, 60, 68), HoverText = Color3.fromRGB(190, 207, 220),
	Faint = Color3.fromRGB(102, 115, 127), Track = Color3.fromRGB(51, 57, 64),
	Text = Color3.fromRGB(223, 235, 244), Dim = Color3.fromRGB(142, 154, 165),
}) do ThemePresets.Graphite[role] = color end
ThemePresets.Graphite.Accent = ThemePresets.Graphite.Text
for role, color in pairs({
	Window = Color3.fromRGB(17, 17, 27), Panel = Color3.fromRGB(23, 23, 35),
	Stroke = Color3.fromRGB(47, 45, 68), WindowStroke = Color3.fromRGB(61, 58, 89),
	Off = Color3.fromRGB(31, 30, 46), Hover = Color3.fromRGB(37, 35, 55),
	Pressed = Color3.fromRGB(55, 50, 78), HoverText = Color3.fromRGB(190, 177, 233),
	Faint = Color3.fromRGB(105, 99, 129), Track = Color3.fromRGB(55, 52, 74),
	Text = Color3.fromRGB(218, 207, 255), Dim = Color3.fromRGB(149, 141, 176),
}) do ThemePresets.Midnight[role] = color end
ThemePresets.Midnight.Accent = ThemePresets.Midnight.Text
for role, value in pairs({
	Window = Color3.fromRGB(29, 29, 32), Panel = Color3.fromRGB(34, 34, 38),
	Stroke = Color3.fromRGB(53, 53, 58), WindowStroke = Color3.fromRGB(65, 65, 70),
	Off = Color3.fromRGB(43, 43, 47), Hover = Color3.fromRGB(52, 49, 44),
	Pressed = Color3.fromRGB(70, 59, 43), Track = Color3.fromRGB(58, 58, 63),
	Text = Color3.fromRGB(236, 236, 239), Dim = Color3.fromRGB(151, 151, 157),
	Faint = Color3.fromRGB(105, 105, 112), HoverText = Color3.fromRGB(255, 190, 85),
	Accent = Color3.fromRGB(255, 166, 38),
}) do ThemePresets.Amber[role] = value end
for role, value in pairs({
	Window = Color3.fromRGB(8, 12, 13), Panel = Color3.fromRGB(15, 21, 23),
	Stroke = Color3.fromRGB(31, 43, 47), WindowStroke = Color3.fromRGB(42, 58, 64),
	Off = Color3.fromRGB(23, 32, 36), Hover = Color3.fromRGB(28, 43, 50),
	Pressed = Color3.fromRGB(35, 59, 71), Track = Color3.fromRGB(36, 48, 54),
	Text = Color3.fromRGB(226, 237, 241), Dim = Color3.fromRGB(125, 147, 156),
	Faint = Color3.fromRGB(79, 105, 117), HoverText = Color3.fromRGB(102, 202, 244),
	Accent = Color3.fromRGB(0, 174, 239),
}) do ThemePresets.Azure[role] = value end

-- Keep bindings alive while Roblox owns the instances in the GUI hierarchy.
local themeBindings = {}
local themeTweens = setmetatable({}, { __mode = "k" })
local function trackTheme(inst, props)
	local bindings = themeBindings[inst] or {}
	local themed = false
	for property, value in pairs(props) do
		if typeof(value) == "Color3" then
			bindings[property] = nil
			for role, color in pairs(Theme) do
				if role ~= "Accent" and typeof(color) == "Color3" and color == value then
					bindings[property] = role
					themed = true
					break
				end
			end
		end
	end
	themeBindings[inst] = bindings
	return themed
end

local HttpService = game:GetService("HttpService")

local Library = { Flags = {}, Setters = {} }

local function encodeValue(v)
	local t = typeof(v)
	if t == "Color3" then
		return { __c = { v.R, v.G, v.B } }
	elseif t == "EnumItem" then
		return { __e = { tostring(v.EnumType), v.Name } }
	elseif t == "boolean" or t == "number" or t == "string" then
		return v
	end
	return nil
end

local function decodeValue(v)
	if type(v) == "table" then
		if v.__c then
			return Color3.new(v.__c[1], v.__c[2], v.__c[3])
		elseif v.__e then
			local ok, item = pcall(function()
				return Enum[v.__e[1]][v.__e[2]]
			end)
			return ok and item or nil
		end
	end
	return v
end

function Library.Export()
	local data = {}
	for flag in pairs(Library.Setters) do
		local v = Library.Flags[flag]
		if v == nil then
			v = false
		end
		local e = encodeValue(v)
		if e ~= nil then
			data[flag] = e
		end
	end
	return HttpService:JSONEncode(data)
end

function Library.Import(json)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(data) ~= "table" then
		return false
	end
	for pass = 1, 2 do
		for flag, raw in pairs(data) do
			local isMode = flag:sub(-5) == "_Mode"
			if (pass == 1) == isMode then
				local setter = Library.Setters[flag]
				local v = decodeValue(raw)
				if setter and v ~= nil then
					pcall(setter, v)
				end
			end
		end
	end
	return true
end

do
	local FS = {}
	Library.FS = FS

	local hasFiles = typeof(writefile) == "function"
		and typeof(readfile) == "function"
		and typeof(listfiles) == "function"
		and typeof(isfolder) == "function"
		and typeof(makefolder) == "function"
	_G.HazeConfigMemory = _G.HazeConfigMemory or {}
	local mem = _G.HazeConfigMemory

	local function clean(s)
		s = tostring(s or ""):gsub("[^%w%._%- ]", "_")
		s = s:gsub("^%s+", ""):gsub("%s+$", "")
		if s == "" or s:find("^%.+$") then
			return nil
		end
		return s
	end
	FS.normalize = clean

	function FS.mode()
		return hasFiles and "files" or "memory"
	end

	function FS.list(folder)
		folder = clean(folder)
		if not folder then
			return nil, "Invalid folder name"
		end
		local out = {}
		if hasFiles then
			local ok, exists = pcall(isfolder, folder)
			if ok and exists then
				local ok2, files = pcall(listfiles, folder)
				if ok2 and type(files) == "table" then
					for _, path in ipairs(files) do
						local n = tostring(path):match("([^/\\]+)%.json$")
						if n then
							out[#out + 1] = n
						end
					end
				end
			end
		else
			for n in pairs(mem[folder] or {}) do
				out[#out + 1] = n
			end
		end
		table.sort(out, function(a, b)
			return a:lower() < b:lower()
		end)
		return out
	end

	function FS.save(folder, name, data)
		folder, name = clean(folder), clean(name)
		if not folder then
			return false, "Invalid folder name"
		end
		if not name then
			return false, "Invalid config name"
		end
		if hasFiles then
			local ok = pcall(function()
				if not isfolder(folder) then
					makefolder(folder)
				end
				writefile(folder .. "/" .. name .. ".json", data)
			end)
			if not ok then
				return false, "Write failed"
			end
		else
			mem[folder] = mem[folder] or {}
			mem[folder][name] = data
		end
		return true
	end

	function FS.read(folder, name)
		folder, name = clean(folder), clean(name)
		if not folder then
			return nil, "Invalid folder name"
		end
		if not name then
			return nil, "Invalid config name"
		end
		if hasFiles then
			local path = folder .. "/" .. name .. ".json"
			local ok, data = pcall(function()
				if typeof(isfile) == "function" and not isfile(path) then
					return nil
				end
				return readfile(path)
			end)
			if ok and data then
				return data
			end
			return nil, "Config not found"
		end
		local data = mem[folder] and mem[folder][name]
		if data then
			return data
		end
		return nil, "Config not found"
	end

	function FS.delete(folder, name)
		folder, name = clean(folder), clean(name)
		if not folder then
			return false, "Invalid folder name"
		end
		if not name then
			return false, "Invalid config name"
		end
		if hasFiles then
			if typeof(delfile) ~= "function" then
				return false, "delfile unavailable"
			end
			local ok = pcall(delfile, folder .. "/" .. name .. ".json")
			return ok, ok and nil or "Delete failed"
		end
		if mem[folder] and mem[folder][name] then
			mem[folder][name] = nil
			return true
		end
		return false, "Config not found"
	end
end

local function create(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		if k == "Font" and typeof(v) == "Font" then
			inst.FontFace = v
		else
			inst[k] = v
		end
	end
	inst.Parent = parent
	trackTheme(inst, props)
	return inst
end

local function corner(inst, r)
	return create("UICorner", { CornerRadius = UDim.new(0, r) }, inst)
end

local function stroke(inst, color, thickness)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, inst)
end

local function tween(inst, props, t, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(
		t or 0.2,
		style or Enum.EasingStyle.Quint,
		dir or Enum.EasingDirection.Out
	), props)
	if trackTheme(inst, props) then themeTweens[tw] = true end
	tw:Play()
	return tw
end

local function apply(inst, props, instant, t, style, dir)
	if instant then
		trackTheme(inst, props)
		for k, v in pairs(props) do
			inst[k] = v
		end
	else
		tween(inst, props, t, style, dir)
	end
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function inside(guiObj, pos)
	local p, s = guiObj.AbsolutePosition, guiObj.AbsoluteSize
	return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
end

local function sinkButton(props, parent)
	props.Text = props.Text or ""
	props.AutoButtonColor = false
	props.BorderSizePixel = 0
	return create("TextButton", props, parent)
end

local function bindText(key)
	if not key then
		return "[None]"
	end
	if key == Enum.UserInputType.MouseButton1 then return "[MB1]" end
	if key == Enum.UserInputType.MouseButton2 then return "[MB2]" end
	if key == Enum.UserInputType.MouseButton3 then return "[MB3]" end
	local n = key.Name
	n = n:gsub("^Left", "L"):gsub("^Right", "R")
	return "[" .. n .. "]"
end

local function matchesKey(key, input)
	if typeof(key) ~= "EnumItem" then
		return false
	end
	if key.EnumType == Enum.KeyCode then
		return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key
	end
	return input.UserInputType == key
end

local function decodeHudPosition(data)
	if type(data) ~= "table" then return nil end
	for _, key in ipairs({ "XScale", "XOffset", "YScale", "YOffset" }) do
		local value = data[key]
		if type(value) ~= "number" or value ~= value or math.abs(value) > 1000000 then
			return nil
		end
	end
	return UDim2.new(data.XScale, data.XOffset, data.YScale, data.YOffset)
end

function Library.new(opts)
	opts = opts or {}
	local title = opts.Title or "haze"
	local build = opts.Build or "dev-build"
	local configFolder = opts.ConfigFolder or "haze_menu"
	local preferenceFolder = configFolder .. "_preferences"
	local preferences = { Theme = "Default", Autoload = false }
	local savedPreferences = Library.FS.read(preferenceFolder, "settings")
	if savedPreferences then
		local ok, data = pcall(HttpService.JSONDecode, HttpService, savedPreferences)
		if ok and type(data) == "table" then
			if ThemePresets[data.Theme] then preferences.Theme = data.Theme end
			if type(data.Autoload) == "string" then preferences.Autoload = data.Autoload end
			for _, key in ipairs({ "WatermarkPosition", "KeybindPosition" }) do
				if decodeHudPosition(data[key]) then preferences[key] = data[key] end
			end
		end
	end
	for role, value in pairs(ThemePresets[preferences.Theme]) do Theme[role] = value end

	local window = { Flags = Library.Flags, ConfigFolder = configFolder }
	window.Preferences = table.clone(preferences)
	function window:SetPreference(key, value)
		local updated = table.clone(preferences)
		updated[key] = value
		local ok, err = Library.FS.save(preferenceFolder, "settings", HttpService:JSONEncode(updated))
		if ok then
			preferences = updated
			self.Preferences = table.clone(updated)
		end
		return ok, err
	end
	local destroyed = false
	local connections = {}
	local function connect(signal, callback)
		local connection = signal:Connect(callback)
		connections[#connections + 1] = connection
		return connection
	end
	local menuKey = opts.ToggleKey or Enum.KeyCode.RightShift
	window.Tabs = {}
	window.MenuKey = menuKey
	function window:SetMenuKey(key)
		menuKey = key
		self.MenuKey = key
	end

	local picker, panelFrame, panelAnchor, anchorBtn
	local pickerOpen = false
	local ddFrame, ddOpen, ddAnchor, ddChevron = nil, false, nil, nil
	local closePicker, closePanel, closeDropdown, closeAll
	local refreshBindList
	local attach, newPanel
	local binds = {}
	local listening
	local bindFinishedAt = 0
	local popupToken = {}

	local gui = create("ScreenGui", {
		Name = "HazeMenu",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
	}, LocalPlayer:WaitForChild("PlayerGui"))
	window.Gui = gui
	function window:Destroy()
		if destroyed then return end
		destroyed = true
		listening = nil
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		table.clear(connections)
		if _G.HazeMenu == self then
			_G.HazeMenu = nil
		end
		for inst in pairs(themeBindings) do
			if inst == gui or inst:IsDescendantOf(gui) or not inst.Parent then
				themeBindings[inst] = nil
			end
		end
		gui:Destroy()
	end
	connect(gui.Destroying, function() window:Destroy() end)
	_G.HazeMenu = window
	function window:SetTheme(name)
		local preset = ThemePresets[name]
		if destroyed or not preset then return false, "Unknown theme" end
		local ok, err = self:SetPreference("Theme", name)
		if not ok then return false, err end
		for animation in pairs(themeTweens) do animation:Cancel() end
		table.clear(themeTweens)
		for role, value in pairs(preset) do Theme[role] = value end
		for inst, bindings in pairs(themeBindings) do
			if inst:IsDescendantOf(gui) then
				for property, role in pairs(bindings) do inst[property] = Theme[role] end
			elseif not inst.Parent then
				themeBindings[inst] = nil
			end
		end
		return true
	end

	local notifications = {}
	local function layoutNotifications()
		for i, notification in ipairs(notifications) do
			local offset = (#notifications - i) * 46
			tween(notification, { Position = UDim2.new(0, 12, 1, -12 - offset) }, 0.28)
		end
	end

	function window:Notify(options)
		if destroyed then return end
		options = options or {}
		local duration = math.max(0.5, tonumber(options.Duration) or 4)
		local notification = create("CanvasGroup", {
			Name = "Notification",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, -256, 1, -12),
			Size = UDim2.fromOffset(240, 42),
			BackgroundColor3 = Theme.Window,
			BorderSizePixel = 0,
			GroupTransparency = 1,
			ZIndex = 100,
		}, gui)
		corner(notification, 5)
		local border = create("Frame", {
			Position = UDim2.fromOffset(1, 1),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, notification)
		corner(border, 4)
		stroke(border, Theme.WindowStroke)
		create("TextLabel", {
			Position = UDim2.fromOffset(9, 5),
			Size = UDim2.new(1, -18, 0, 14),
			BackgroundTransparency = 1,
			Text = options.Title or title,
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, notification)
		create("TextLabel", {
			Position = UDim2.fromOffset(9, 21),
			Size = UDim2.new(1, -18, 0, 14),
			BackgroundTransparency = 1,
			Text = options.Text or "",
			Font = Theme.Font,
			TextSize = 11,
			TextColor3 = Theme.Dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, notification)
		local progress = create("Frame", {
			Position = UDim2.new(0, 7, 1, -3),
			Size = UDim2.new(1, -14, 0, 1),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
		}, notification)
		themeBindings[progress].BackgroundColor3 = "Accent"
		notifications[#notifications + 1] = notification
		layoutNotifications()
		tween(notification, { GroupTransparency = 0 }, 0.25)
		tween(progress, { Size = UDim2.fromOffset(0, 1) }, duration, Enum.EasingStyle.Linear)
		task.delay(duration, function()
			if destroyed then return end
			local index = table.find(notifications, notification)
			if index then table.remove(notifications, index) end
			tween(notification, {
				Position = UDim2.new(0, -256, 1, notification.Position.Y.Offset),
				GroupTransparency = 1,
			}, 0.22)
			layoutNotifications()
			task.delay(0.22, function()
				if destroyed then return end
				notification:Destroy()
			end)
		end)
	end

	local function blocked(guiObj, pos)
		local function over(frame)
			return not (guiObj and guiObj:IsDescendantOf(frame)) and inside(frame, pos)
		end
		if ddOpen and over(ddFrame) then
			return true
		end
		if pickerOpen and over(picker) then
			return true
		end
		if panelFrame and over(panelFrame) then
			return true
		end
		return false
	end

	local function clickable(btn, fn)
		connect(btn.InputBegan, function(input)
			if isPointer(input) then
				if blocked(btn, input.Position) then
					return
				end
				fn(input)
			end
		end)
	end

	local function makeDraggable(handle, target, onStart, onFinish)
		local dragging, dragStart, startPos, dragInput
		connect(handle.InputBegan, function(input)
			if isPointer(input) then
				if blocked(handle, input.Position) then
					return
				end
				if onStart then
					onStart()
				end
				dragging = true
				dragInput = input
				dragStart = input.Position
				startPos = target.Position
			end
		end)
		connect(UserInputService.InputEnded, function(input)
			if dragging and input == dragInput then
				dragging = false
				dragInput = nil
				if onFinish and target.Position ~= startPos then onFinish() end
			end
		end)
		connect(UserInputService.InputChanged, function(input)
			if dragging and isMove(input) then
				local d = input.Position - dragStart
				target.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end)
	end

	local function clampHudPosition(target)
		local screen, size = gui.AbsoluteSize, target.AbsoluteSize
		if screen.X <= 0 or screen.Y <= 0 then return end
		local position, anchor = target.Position, target.AnchorPoint
		local x = screen.X * position.X.Scale + position.X.Offset - size.X * anchor.X
		local y = screen.Y * position.Y.Scale + position.Y.Offset - size.Y * anchor.Y
		local dx = math.clamp(x, 8, math.max(8, screen.X - size.X - 8)) - x
		local dy = math.clamp(y, 8, math.max(8, screen.Y - size.Y - 8)) - y
		target.Position = UDim2.new(position.X.Scale, position.X.Offset + dx,
			position.Y.Scale, position.Y.Offset + dy)
	end

	local function persistHudPosition(target, key)
		local saved = decodeHudPosition(preferences[key])
		if saved then target.Position = saved end
		task.defer(function()
			if not destroyed then clampHudPosition(target) end
		end)
		makeDraggable(target, target, nil, function()
			clampHudPosition(target)
			local position = target.Position
			local ok, err = window:SetPreference(key, {
				XScale = position.X.Scale, XOffset = position.X.Offset,
				YScale = position.Y.Scale, YOffset = position.Y.Offset,
			})
			if not ok then window:Notify({ Title = "Layout", Text = err }) end
		end)
	end

	local function makePopup(size, z, radius)
		local f = create("CanvasGroup", {
			Visible = false,
			Size = size,
			BackgroundColor3 = Theme.Window,
			BorderSizePixel = 0,
			ZIndex = z,
			Active = true,
			GroupTransparency = 1,
		}, gui)
		corner(f, radius)
		local b = create("Frame", {
			Name = "Border",
			Position = UDim2.fromOffset(1, 1),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 0,
		}, f)
		corner(b, radius - 1)
		stroke(b, Theme.WindowStroke, 1)
		return f
	end

	local function popupShow(frame, x, y)
		popupToken[frame] = (popupToken[frame] or 0) + 1
		frame.Visible = true
		frame.GroupTransparency = 1
		frame.Position = UDim2.fromOffset(x, y - 8)
		tween(frame, {
			GroupTransparency = 0,
			Position = UDim2.fromOffset(x, y),
		}, 0.24)
	end

	local function popupHide(frame)
		local tok = (popupToken[frame] or 0) + 1
		popupToken[frame] = tok
		tween(frame, { GroupTransparency = 1 }, 0.14, Enum.EasingStyle.Quad)
		task.delay(0.14, function()
			if destroyed then return end
			if popupToken[frame] == tok then
				frame.Visible = false
			end
		end)
	end

	local main = create("CanvasGroup", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(678, 470),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
		Active = true,
		GroupTransparency = 1,
		Visible = false,
	}, gui)
	corner(main, 8)
	do
		local border = create("Frame", {
			Name = "Border",
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.new(1, -4, 1, -4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 0,
		}, main)
		corner(border, 6)
		stroke(border, Theme.WindowStroke, 2)
	end
	local mainScale = create("UIScale", { Scale = 0.94 }, main)
	window.Main = main

	local menuOpen = false
	local menuToken = 0
	local function setMenu(v)
		if menuOpen == v then
			return
		end
		menuOpen = v
		menuToken += 1
		local tok = menuToken
		if v then
			main.Visible = true
			tween(main, { GroupTransparency = 0 }, 0.25)
			tween(mainScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
		else
			closeAll()
			tween(main, { GroupTransparency = 1 }, 0.18, Enum.EasingStyle.Quad)
			tween(mainScale, { Scale = 0.95 }, 0.18, Enum.EasingStyle.Quad)
			task.delay(0.18, function()
				if destroyed then return end
				if menuToken == tok then
					main.Visible = false
				end
			end)
		end
	end
	function window:SetVisible(v)
		setMenu(v)
	end

	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundTransparency = 1,
	}, main)
	makeDraggable(header, main, function()
		closeAll()
	end)

	if opts.Logo then
		create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(55, 37),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			Image = opts.Logo,
			ScaleType = Enum.ScaleType.Fit,
		}, header)
	end
	create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(opts.Logo and 116 or 97, 37),
			Size = UDim2.fromOffset(100, 30),
			BackgroundTransparency = 1,
			Text = "haze",
			Font = Theme.FontBold,
			TextSize = 27,
			TextColor3 = Theme.Text,
		}, header)

	local sidebar = create("Frame", {
		Position = UDim2.fromOffset(19, 70),
		Size = UDim2.fromOffset(156, 383),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	}, main)
	corner(sidebar, 6)
	stroke(sidebar, Theme.Stroke)

	local tabList = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, sidebar)
	create("UIPadding", { PaddingTop = UDim.new(0, 4) }, tabList)
	create("UIListLayout", {
		Padding = UDim.new(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, tabList)

	local pages = create("Frame", {
		Position = UDim2.fromOffset(189, 13),
		Size = UDim2.fromOffset(481, 442),
		BackgroundTransparency = 1,
	}, main)

	picker = makePopup(UDim2.fromOffset(172, 140), 50, 6)

	local sv = sinkButton({
		Position = UDim2.fromOffset(11, 11),
		Size = UDim2.fromOffset(150, 100),
		BackgroundColor3 = Color3.new(1, 0, 0),
	}, picker)
	corner(sv, 4)
	local white = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, sv)
	corner(white, 4)
	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, white)
	local black = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, sv)
	corner(black, 4)
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
	}, black)
	local svKnob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, sv)
	corner(svKnob, 4)
	stroke(svKnob, Color3.new(1, 1, 1), 1.5)

	local hue = sinkButton({
		Position = UDim2.fromOffset(11, 119),
		Size = UDim2.fromOffset(150, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
	}, picker)
	corner(hue, 3)
	local hueKeys = {}
	for i = 0, 6 do
		hueKeys[#hueKeys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, 0.999), 1, 1))
	end
	create("UIGradient", { Color = ColorSequence.new(hueKeys) }, hue)
	local hueKnob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(4, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, hue)
	corner(hueKnob, 2)
	stroke(hueKnob, Color3.fromRGB(20, 20, 20), 1)

	local ph, ps, pv = 0, 1, 1
	local dragMode, onChange

	local function refreshPicker(fire)
		sv.BackgroundColor3 = Color3.fromHSV(ph, 1, 1)
		svKnob.Position = UDim2.new(ps, 0, 1 - pv, 0)
		hueKnob.Position = UDim2.new(ph, 0, 0.5, 0)
		if fire and onChange then
			onChange(Color3.fromHSV(ph, ps, pv))
		end
	end

	local function updateSV(pos)
		ps = math.clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
		pv = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
		refreshPicker(true)
	end

	local function updateHue(pos)
		ph = math.clamp((pos.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 0.999)
		refreshPicker(true)
	end

	connect(sv.InputBegan, function(input)
		if isPointer(input) then
			dragMode = "sv"
			updateSV(input.Position)
		end
	end)
	connect(hue.InputBegan, function(input)
		if isPointer(input) then
			dragMode = "hue"
			updateHue(input.Position)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragMode and isMove(input) then
			if dragMode == "sv" then
				updateSV(input.Position)
			else
				updateHue(input.Position)
			end
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if isPointer(input) then
			dragMode = nil
		end
	end)

	closePicker = function()
		if pickerOpen then
			pickerOpen = false
			popupHide(picker)
		end
		anchorBtn, onChange = nil, nil
		dragMode = nil
	end

	local function openPicker(btn, color, cb)
		if pickerOpen and anchorBtn == btn then
			closePicker()
			return
		end
		closeDropdown()
		anchorBtn, onChange = btn, cb
		ph, ps, pv = color:ToHSV()
		refreshPicker(false)
		local screen = gui.AbsoluteSize
		local x = btn.AbsolutePosition.X + btn.AbsoluteSize.X - picker.AbsoluteSize.X
		local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 6
		x = math.clamp(x, 4, screen.X - picker.AbsoluteSize.X - 4)
		y = math.clamp(y, 4, screen.Y - picker.AbsoluteSize.Y - 4)
		pickerOpen = true
		popupShow(picker, x, y)
	end

	ddFrame = makePopup(UDim2.fromOffset(120, 40), 60, 5)
	local ddItems = {}

	closeDropdown = function()
		if ddOpen then
			ddOpen = false
			popupHide(ddFrame)
			if ddChevron then
				tween(ddChevron, { Rotation = 0 }, 0.2)
			end
		end
		ddAnchor, ddChevron = nil, nil
	end

	local function openDropdown(btn, options, current, cb, chevron)
		if #options == 0 then
			return
		end
		if ddOpen and ddAnchor == btn then
			closeDropdown()
			return
		end
		closePicker()
		closeDropdown()

		for _, it in ipairs(ddItems) do
			it:Destroy()
		end
		ddItems = {}

		local w = btn.AbsoluteSize.X
		local h = #options * 27 + 8
		ddFrame.Size = UDim2.fromOffset(w, h)

		for i, opt in ipairs(options) do
			local selected = (opt == current)
			local b = sinkButton({
				Position = UDim2.fromOffset(4, 4 + (i - 1) * 27),
				Size = UDim2.new(1, -8, 0, 27),
				BackgroundColor3 = Theme.Hover,
				BackgroundTransparency = 1,
				Font = Theme.Font,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = selected and Theme.Text or Theme.Dim,
				Text = opt,
			}, ddFrame)
			corner(b, 4)
			create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)
			connect(b.MouseEnter, function()
				tween(b, { BackgroundTransparency = 0, TextColor3 = Theme.Text }, 0.12)
			end)
			connect(b.MouseLeave, function()
				tween(b, {
					BackgroundTransparency = 1,
					TextColor3 = selected and Theme.Text or Theme.Dim,
				}, 0.18)
			end)
			connect(b.InputBegan, function(input)
				if isPointer(input) then
					cb(opt)
					closeDropdown()
				end
			end)
			ddItems[#ddItems + 1] = b
		end

		local screen = gui.AbsoluteSize
		local x = math.clamp(btn.AbsolutePosition.X, 4, math.max(4, screen.X - w - 4))
		local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 4
		if y + h > screen.Y - 4 then
			y = btn.AbsolutePosition.Y - h - 4
		end

		ddOpen, ddAnchor, ddChevron = true, btn, chevron
		tween(chevron, { Rotation = 180 }, 0.2)
		popupShow(ddFrame, x, y)
	end

	closePanel = function()
		if panelFrame then
			if anchorBtn and anchorBtn:IsDescendantOf(panelFrame) then
				closePicker()
			end
			if ddAnchor and ddAnchor:IsDescendantOf(panelFrame) then
				closeDropdown()
			end
			popupHide(panelFrame)
			panelFrame, panelAnchor = nil, nil
		end
	end

	closeAll = function()
		closePicker()
		closeDropdown()
		closePanel()
	end

	local function togglePanel(frame, anchor)
		if panelFrame == frame then
			closePanel()
			return
		end
		closeAll()
		panelFrame, panelAnchor = frame, anchor
		local screen = gui.AbsoluteSize
		local w, h = frame.Size.X.Offset, frame.Size.Y.Offset
		local x = math.clamp(anchor.AbsolutePosition.X + anchor.AbsoluteSize.X - w, 4, math.max(4, screen.X - w - 4))
		local y = math.clamp(anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 6, 4, math.max(4, screen.Y - h - 4))
		popupShow(frame, x, y)
	end

	newPanel = function(width)
		local frame = makePopup(UDim2.fromOffset(width, 12), 40, 6)
		local sub = {}
		local y = 6
		attach(sub, function(h)
			local row = create("Frame", {
				Position = UDim2.fromOffset(0, y),
				Size = UDim2.new(1, 0, 0, h),
				BackgroundTransparency = 1,
			}, frame)
			y += h
			frame.Size = UDim2.fromOffset(width, y + 6)
			return row
		end, true)
		return frame, sub
	end

	connect(UserInputService.InputBegan, function(input)
		if not (isPointer(input) or input.UserInputType == Enum.UserInputType.MouseButton2) then
			return
		end
		local pos = input.Position
		if ddOpen and not inside(ddFrame, pos) and not (ddAnchor and inside(ddAnchor, pos)) then
			closeDropdown()
		end
		if pickerOpen and not inside(picker, pos) and not (anchorBtn and inside(anchorBtn, pos)) then
			closePicker()
		end
		if panelFrame
			and not inside(panelFrame, pos)
			and not (panelAnchor and inside(panelAnchor, pos))
			and not (pickerOpen and inside(picker, pos))
			and not (ddOpen and inside(ddFrame, pos))
		then
			closePanel()
		end
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if listening then
			local l = listening
			local ut = input.UserInputType
			if ut == Enum.UserInputType.Keyboard then
				listening = nil
				if input.KeyCode == Enum.KeyCode.Escape then
					l.finish(l.bind.Key)
				elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
					l.finish(nil)
				else
					l.finish(input.KeyCode)
				end
			elseif ut == Enum.UserInputType.MouseButton2 or ut == Enum.UserInputType.MouseButton3 then
				listening = nil
				l.finish(ut)
			elseif isPointer(input) then
				if os.clock() - l.t > 0.2 then
					listening = nil
					l.finish(l.bind.Key)
				end
			end
			return
		end

		if processed then
			return
		end

		if matchesKey(menuKey, input) then
			setMenu(not menuOpen)
			return
		end

		for _, b in ipairs(binds) do
			if b.Toggle.Get() and b.Key and b.Mode ~= "Always" and matchesKey(b.Key, input) then
				if b.Mode == "Hold" then
					b.SetActive(true)
				else
					b.SetActive(not b.Active)
				end
			end
		end
	end)

	connect(UserInputService.InputEnded, function(input)
		for _, b in ipairs(binds) do
			if b.Mode == "Hold" and b.Key and matchesKey(b.Key, input) then
				b.SetActive(false)
			end
		end
	end)

	local wm = create("CanvasGroup", {
		Name = "Watermark",
		Visible = false,
		GroupTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.fromOffset(0, 38),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
	}, gui)
	corner(wm, 6)
	-- Keep the stroke inside the CanvasGroup's clipping bounds.
	local wmBorder = create("Frame", {
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, wm)
	corner(wmBorder, 5)
	stroke(wmBorder, Theme.WindowStroke, 1)
	local wmContent = create("Frame", {
		Size = UDim2.fromOffset(0, 38),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, wm)
	create("UIPadding", { PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11) }, wmContent)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, wmContent)
	persistHudPosition(wm, "WatermarkPosition")

	local function wmLabel(text, order, bold, color)
		return create("TextLabel", {
			LayoutOrder = order,
			Size = UDim2.fromOffset(0, 14),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = text,
			Font = bold and Theme.FontBold or Theme.Font,
			TextSize = 14,
			TextColor3 = color,
		}, wmContent)
	end
	local function wmSeparator(order)
		create("Frame", {
			LayoutOrder = order,
			Size = UDim2.fromOffset(1, 12),
			BackgroundColor3 = Theme.Stroke,
			BorderSizePixel = 0,
		}, wmContent)
	end
	local wmTitle = wmLabel(title, 1, true, Theme.Accent)
	themeBindings[wmTitle].TextColor3 = "Accent"
	wmSeparator(2)
	local fpsLabel = wmLabel("-- fps", 3, false, Theme.Dim)
	wmSeparator(4)
	wmLabel(build, 5, false, Theme.Faint)

	local frames, acc = 0, 0
	connect(RunService.RenderStepped, function(dt)
		frames += 1
		acc += dt
		if acc >= 0.25 then
			fpsLabel.Text = string.format("%d fps", math.floor(frames / acc + 0.5))
			frames, acc = 0, 0
		end
	end)

	local wmEnabled = false
	local wmToken = 0
	function window:SetWatermark(v)
		v = v == true
		if destroyed or wmEnabled == v then return end
		wmEnabled = v
		wmToken += 1
		local token = wmToken
		if v then
			wm.Visible = true
			tween(wm, { GroupTransparency = 0 }, 0.3)
		else
			tween(wm, { GroupTransparency = 1 }, 0.18)
			task.delay(0.18, function()
				if destroyed then return end
				if wmToken == token then wm.Visible = false end
			end)
		end
	end
	task.defer(function()
		if destroyed or wmToken ~= 0 then return end
		window:SetWatermark(true)
	end)

	local KB_W = 190
	local kb = makePopup(UDim2.fromOffset(KB_W, 38), 5, 6)
	kb.AnchorPoint = Vector2.new(1, 0)
	kb.Position = UDim2.new(1, -16, 0, 62)
	create("TextLabel", {
		Position = UDim2.fromOffset(11, 8),
		Size = UDim2.new(1, -22, 0, 18),
		BackgroundTransparency = 1,
		Text = "Keybinds",
		Font = Theme.FontBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
	}, kb)
	persistHudPosition(kb, "KeybindPosition")

	local kbEnabled = true
	local kbShown = false

	local function modeText(mode, active)
		if mode == "Always" then
			return "[always]"
		elseif mode == "Hold" then
			return active and "[held]" or "[hold]"
		end
		return active and "[toggled]" or "[toggle]"
	end

	refreshBindList = function()
		local n = 0
		for _, bd in ipairs(binds) do
			local r = bd.kb
			if r then
				if kbEnabled and bd.Show and bd.Toggle.Get() then
					local y = 32 + n * 22
					if not r.laid then
						r.row.Position = UDim2.fromOffset(0, y)
						r.laid = true
					else
						tween(r.row, { Position = UDim2.fromOffset(0, y) }, 0.2)
					end
					r.row.Visible = true
					n += 1
				else
					r.row.Visible = false
					r.laid = false
				end
				local active = bd.Active
				tween(r.name, { TextColor3 = active and Theme.Text or Theme.Dim }, 0.2)
				tween(r.mode, { TextColor3 = active and Theme.HoverText or Theme.Faint }, 0.2)
				r.mode.Text = modeText(bd.Mode, active)
			end
		end

		if n > 0 then
			local h = 38 + n * 22
			if not kbShown then
				kbShown = true
				popupToken[kb] = (popupToken[kb] or 0) + 1
				kb.Size = UDim2.fromOffset(KB_W, h)
				kb.Visible = true
				tween(kb, { GroupTransparency = 0 }, 0.25)
			else
				tween(kb, { Size = UDim2.fromOffset(KB_W, h) }, 0.22)
			end
		elseif kbShown then
			kbShown = false
			local tok = (popupToken[kb] or 0) + 1
			popupToken[kb] = tok
			tween(kb, { GroupTransparency = 1 }, 0.2, Enum.EasingStyle.Quad)
			task.delay(0.2, function()
				if destroyed then return end
				if popupToken[kb] == tok then
					kb.Visible = false
				end
			end)
		end
	end

	function window:SetKeybindList(v)
		kbEnabled = v
		refreshBindList()
	end

	attach = function(obj, addRow, nested)
		function obj:Header(text)
			local row = addRow(23)
			create("TextLabel", {
				Position = UDim2.fromOffset(11, 0),
				Size = UDim2.new(1, -22, 1, 0),
				BackgroundTransparency = 1,
				Text = string.upper(text),
				Font = Theme.FontBold,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Faint,
			}, row)
		end

		function obj:Label(text)
			local row = addRow(23)
			local lbl = create("TextLabel", {
				Position = UDim2.fromOffset(11, 0),
				Size = UDim2.new(1, -22, 1, 0),
				BackgroundTransparency = 1,
				Text = text,
				Font = Theme.Font,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextColor3 = Theme.Dim,
			}, row)
			return {
				Set = function(t)
					lbl.Text = t
				end,
			}
		end

		function obj:Input(o)
			local row = addRow(55)
			local flag = o.Flag or o.Name

			create("TextLabel", {
				Position = UDim2.fromOffset(11, 4),
				Size = UDim2.new(1, -22, 0, 17),
				BackgroundTransparency = 1,
				Text = o.Name,
				Font = Theme.Font,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Text,
			}, row)

			local box = create("TextBox", {
				Position = UDim2.fromOffset(11, 25),
				Size = UDim2.new(1, -22, 0, 26),
				BackgroundColor3 = Theme.Off,
				BorderSizePixel = 0,
				ClearTextOnFocus = false,
				Font = Theme.Font,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Text,
				PlaceholderText = o.Placeholder or "",
				PlaceholderColor3 = Theme.Faint,
				Text = o.Default or "",
			}, row)
			corner(box, 4)
			create("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}, box)
			local bs = stroke(box, Theme.Stroke)
			Library.Flags[flag] = box.Text

			connect(box.MouseEnter, function()
				if not box:IsFocused() then
					tween(bs, { Color = Theme.Faint }, 0.15)
				end
			end)
			connect(box.MouseLeave, function()
				if not box:IsFocused() then
					tween(bs, { Color = Theme.Stroke }, 0.2)
				end
			end)
			connect(box.Focused, function()
				tween(bs, { Color = Theme.Dim }, 0.15)
				tween(box, { BackgroundColor3 = Theme.Hover }, 0.15)
			end)
			connect(box.FocusLost, function(enter)
				tween(bs, { Color = Theme.Stroke }, 0.2)
				tween(box, { BackgroundColor3 = Theme.Off }, 0.2)
				Library.Flags[flag] = box.Text
				if o.Callback then
					task.spawn(o.Callback, box.Text, enter)
				end
			end)

			return {
				Set = function(v)
					box.Text = v
					Library.Flags[flag] = v
				end,
				Get = function()
					return box.Text
				end,
			}
		end

		local function addButton(row, o, position, size)
			local hovered, pressed = false, false
			local b = sinkButton({
				Position = position,
				Size = size,
				BackgroundColor3 = Theme.Off,
				Font = Theme.Font,
				TextSize = 14,
				TextColor3 = o.Color or Theme.Text,
				Text = o.Name,
			}, row)
			corner(b, 4)
			local bs = stroke(b, Theme.Stroke)
			connect(b.MouseEnter, function()
				hovered = true
				tween(b, { BackgroundColor3 = pressed and Theme.Pressed or Theme.Hover }, 0.18)
				tween(bs, { Color = Theme.Faint }, 0.18)
			end)
			connect(b.MouseLeave, function()
				hovered = false
				tween(b, { BackgroundColor3 = pressed and Theme.Pressed or Theme.Off }, 0.25)
				tween(bs, { Color = Theme.Stroke }, 0.25)
			end)
			connect(b.InputBegan, function(input)
				if isPointer(input) and not blocked(b, input.Position) then
					pressed = true
					tween(b, { BackgroundColor3 = Theme.Pressed }, 0.08)
				end
			end)
			connect(b.InputEnded, function(input)
				if isPointer(input) then
					pressed = false
					tween(b, { BackgroundColor3 = hovered and Theme.Hover or Theme.Off }, 0.2)
				end
			end)
			clickable(b, function()
				if o.Callback then
					task.spawn(o.Callback)
				end
			end)
			return {
				SetText = function(text) b.Text = text end,
				SetColor = function(color)
					trackTheme(b, { TextColor3 = color })
					b.TextColor3 = color
				end,
				SetColorRole = function(role)
					b.TextColor3 = Theme[role]
					themeBindings[b].TextColor3 = role
				end,
			}
		end

		function obj:Button(o)
			return addButton(addRow(33), o, UDim2.fromOffset(11, 5), UDim2.new(1, -22, 0, 25))
		end

		function obj:ButtonRow(buttons)
			if #buttons == 0 then return {} end
			local row = addRow(33)
			local content = create("Frame", {
				Position = UDim2.fromOffset(11, 5),
				Size = UDim2.new(1, -22, 0, 25),
				BackgroundTransparency = 1,
			}, row)
			local result = {}
			local count, gap = #buttons, 6
			for i, options in ipairs(buttons) do
				result[i] = addButton(content, options,
					UDim2.new((i - 1) / count, (i - 1) * gap / count, 0, 0),
					UDim2.new(1 / count, -gap * (count - 1) / count, 1, 0))
			end
			return result
		end

		function obj:Dropdown(o)
			local row = addRow(55)
			local flag = o.Flag or o.Name
			local options = o.Options
			local value = o.Default or options[1] or ""

			create("TextLabel", {
				Position = UDim2.fromOffset(11, 4),
				Size = UDim2.new(1, -22, 0, 17),
				BackgroundTransparency = 1,
				Text = o.Name,
				Font = Theme.Font,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Text,
			}, row)

			local btn = sinkButton({
				Position = UDim2.fromOffset(11, 25),
				Size = UDim2.new(1, -22, 0, 26),
				BackgroundColor3 = Theme.Off,
			}, row)
			corner(btn, 4)
			local bs = stroke(btn, Theme.Stroke)

			local valText = create("TextLabel", {
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -30, 1, 0),
				BackgroundTransparency = 1,
				Font = Theme.Font,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Text,
			}, btn)

			local chevron = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(12, 8),
				BackgroundTransparency = 1,
			}, btn)
			for _, arm in ipairs({ { 3.75, 45 }, { 8.25, -45 } }) do
				local a = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(arm[1], 3.75),
					Size = UDim2.fromOffset(6.5, 1.5),
					Rotation = arm[2],
					BackgroundColor3 = Theme.Dim,
					BorderSizePixel = 0,
				}, chevron)
				corner(a, 1)
			end

			local function set(v)
				value = v
				valText.Text = (v ~= "") and v or "—"
				Library.Flags[flag] = v
				if o.Callback then
					task.spawn(o.Callback, v)
				end
			end

			local function setOptions(list)
				for i = #options, 1, -1 do
					options[i] = nil
				end
				for i, n in ipairs(list) do
					options[i] = n
				end
				if #options == 0 then
					if value ~= "" then
						set("")
					else
						valText.Text = "—"
					end
				elseif not table.find(options, value) then
					set(options[1])
				end
			end

			connect(btn.MouseEnter, function()
				tween(bs, { Color = Theme.Faint }, 0.15)
				tween(btn, { BackgroundColor3 = Theme.Hover }, 0.15)
			end)
			connect(btn.MouseLeave, function()
				tween(bs, { Color = Theme.Stroke }, 0.2)
				tween(btn, { BackgroundColor3 = Theme.Off }, 0.2)
			end)
			clickable(btn, function()
				openDropdown(btn, o.Options, value, set, chevron)
			end)

			if not o.NoSave then
				Library.Setters[flag] = set
			end
			set(value)
			return { Set = set, Get = function() return value end, SetOptions = setOptions }
		end

		function obj:Slider(o)
			local row = addRow(43)
			local flag = o.Flag or o.Name
			local min, max = o.Min or 0, o.Max or 1
			local step = o.Step or 0.05
			local suffix = o.Suffix or ""
			local value = o.Default or min

			create("TextLabel", {
				Position = UDim2.fromOffset(11, 4),
				Size = UDim2.new(0.6, 0, 0, 17),
				BackgroundTransparency = 1,
				Text = o.Name,
				Font = Theme.Font,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Text,
			}, row)
			local valLabel = create("TextBox", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0, 3),
				Size = UDim2.fromOffset(68, 19),
				BackgroundColor3 = Theme.Off,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ClearTextOnFocus = false,
				Font = Theme.Font,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Theme.Dim,
				Text = "",
			}, row)
			corner(valLabel, 3)
			create("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}, valLabel)

			local track = create("Frame", {
				Position = UDim2.fromOffset(11, 30),
				Size = UDim2.new(1, -22, 0, 4),
				BackgroundColor3 = Theme.Track,
				BorderSizePixel = 0,
			}, row)
			corner(track, 2)
			local fill = create("Frame", {
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = Theme.Text,
				BorderSizePixel = 0,
			}, track)
			fill.BackgroundColor3 = Theme.Accent
			themeBindings[fill].BackgroundColor3 = "Accent"
			corner(fill, 2)
			local knob = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(10, 10),
				BackgroundColor3 = Theme.Text,
				BorderSizePixel = 0,
			}, track)
			knob.BackgroundColor3 = Theme.Accent
			themeBindings[knob].BackgroundColor3 = "Accent"
			corner(knob, 6)

			local hovering, dragging = false, false
			local function refreshKnob()
				local s = (hovering or dragging) and 13 or 10
				tween(knob, { Size = UDim2.fromOffset(s, s) }, 0.15)
			end

			local smooth = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local editing = false
			local function set(v, instant, exact)
				v = math.clamp(v, min, max)
				if not exact then
					v = math.floor(v / step + 0.5) * step
				end
				v = math.clamp(math.floor(v * 1000 + 0.5) / 1000, min, max)
				value = v
				Library.Flags[flag] = v
				local a = (max == min) and 0 or (v - min) / (max - min)
				if instant then
					fill.Size = UDim2.fromScale(a, 1)
					knob.Position = UDim2.new(a, 0, 0.5, 0)
				else
					TweenService:Create(fill, smooth, { Size = UDim2.fromScale(a, 1) }):Play()
					TweenService:Create(knob, smooth, { Position = UDim2.new(a, 0, 0.5, 0) }):Play()
				end
				if not editing then
					valLabel.Text = string.format("%g", v) .. suffix
				end
				if o.Callback then
					task.spawn(o.Callback, v)
				end
			end

			local hit = sinkButton({
				Position = UDim2.fromOffset(11, 22),
				Size = UDim2.new(1, -22, 0, 21),
				BackgroundTransparency = 1,
			}, row)

			local function fromX(x)
				local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				set(min + (max - min) * a)
			end
			connect(hit.MouseEnter, function()
				hovering = true
				refreshKnob()
				tween(valLabel, { TextColor3 = Theme.Text }, 0.15)
			end)
			connect(hit.MouseLeave, function()
				hovering = false
				refreshKnob()
				if not dragging then
					tween(valLabel, { TextColor3 = Theme.Dim }, 0.2)
				end
			end)
			connect(hit.InputBegan, function(input)
				if isPointer(input) and not blocked(hit, input.Position) then
					dragging = true
					refreshKnob()
					fromX(input.Position.X)
				end
			end)
			connect(UserInputService.InputChanged, function(input)
				if dragging and isMove(input) then
					fromX(input.Position.X)
				end
			end)
			connect(UserInputService.InputEnded, function(input)
				if dragging and isPointer(input) then
					dragging = false
					refreshKnob()
					if not hovering then
						tween(valLabel, { TextColor3 = Theme.Dim }, 0.2)
					end
				end
			end)

			local cancelled = false
			connect(valLabel.MouseEnter, function()
				if not editing then
					tween(valLabel, { BackgroundTransparency = 0, TextColor3 = Theme.Text }, 0.15)
				end
			end)
			connect(valLabel.MouseLeave, function()
				if not editing then
					tween(valLabel, { BackgroundTransparency = 1, TextColor3 = Theme.Dim }, 0.2)
				end
			end)
			connect(valLabel.Focused, function()
				editing = true
				cancelled = false
				valLabel.Text = string.format("%g", value)
				tween(valLabel, { BackgroundTransparency = 0, TextColor3 = Theme.Text }, 0.12)
				task.defer(function()
					if destroyed then return end
					if valLabel:IsFocused() then
						valLabel.SelectionStart = 1
						valLabel.CursorPosition = #valLabel.Text + 1
					end
				end)
			end)
			connect(valLabel.FocusLost, function()
				editing = false
				local txt = valLabel.Text:gsub(",", ".")
				local num = tonumber(txt:match("^%s*(-?%d*%.?%d+)"))
				if num and not cancelled then
					set(num, false, true)
				else
					valLabel.Text = string.format("%g", value) .. suffix
				end
				tween(valLabel, { BackgroundTransparency = 1, TextColor3 = Theme.Dim }, 0.2)
			end)
			connect(UserInputService.InputBegan, function(input)
				if editing and input.KeyCode == Enum.KeyCode.Escape then
					cancelled = true
					valLabel:ReleaseFocus()
				end
			end)

			if not o.NoSave then
				Library.Setters[flag] = function(v)
					set(v, false, true)
				end
			end
			set(value, true)
		end

		function obj:Keybind(o)
			local row = addRow(30)
			local flag = o.Flag or o.Name
			local bind = { Key = o.Default }
			create("TextLabel", {
				Position = UDim2.fromOffset(11, 0),
				Size = UDim2.new(1, -96, 1, 0),
				BackgroundTransparency = 1,
				Text = o.Name,
				Font = Theme.Font,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Dim,
			}, row)
			local chip = sinkButton({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Font = Theme.FontBold,
				TextSize = 12,
				TextColor3 = Theme.Dim,
				Text = bindText(bind.Key),
			}, row)
			local function finish(key)
				bind.Key = key
				bindFinishedAt = os.clock()
				Library.Flags[flag] = key
				chip.Text = bindText(key)
				tween(chip, { TextColor3 = Theme.Dim }, 0.25)
				if o.Callback then
					o.Callback(key)
				end
			end
			Library.Flags[flag] = bind.Key
			if not o.NoSave then
				Library.Setters[flag] = function(key)
					if key == false then key = nil end
					finish(key)
				end
			end
			connect(chip.MouseEnter, function()
				if not listening then
					tween(chip, { TextColor3 = Theme.Text }, 0.15)
				end
			end)
			connect(chip.MouseLeave, function()
				if not (listening and listening.bind == bind) then
					tween(chip, { TextColor3 = Theme.Dim }, 0.2)
				end
			end)
			connect(chip.InputBegan, function(input)
				if not isPointer(input) or blocked(chip, input.Position) then
					return
				end
				if listening then
					listening.finish(listening.bind.Key)
				end
				listening = { bind = bind, finish = finish, t = os.clock() }
				chip.Text = "[...]"
				tween(chip, { TextColor3 = Theme.Text }, 0.15)
			end)
			return { Set = finish, Get = function() return bind.Key end }
		end

		function obj:Toggle(o)
			local row = addRow(30)
			local flag = o.Flag or o.Name
			local state = o.Default or false
			local t = {}

			local hit = sinkButton({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, row)

			local box = create("Frame", {
				Position = UDim2.new(0, 11, 0.5, -CHECK / 2),
				Size = UDim2.fromOffset(CHECK, CHECK),
				BackgroundColor3 = Theme.Off,
				BorderSizePixel = 0,
			}, row)
			corner(box, 3)
			local boxStroke = stroke(box, Theme.Stroke)
			local boxFill = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = Theme.Text,
				BorderSizePixel = 0,
			}, box)
			boxFill.BackgroundColor3 = Theme.Accent
			themeBindings[boxFill].BackgroundColor3 = "Accent"
			corner(boxFill, 3)

			local lbl = create("TextLabel", {
				Position = UDim2.fromOffset(11 + CHECK + 8, 0),
				Size = UDim2.new(1, -(11 + CHECK + 8), 1, 0),
				BackgroundTransparency = 1,
				Text = o.Name,
				Font = Theme.Font,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Dim,
			}, row)

			local holder = create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(0, 20),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
			}, row)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 7),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, holder)

			local function set(v, instant)
				state = v
				Library.Flags[flag] = v
				if t._keybind then
					local b = t._keybind
					b.SetActive(v and b.Mode == "Always")
				end
				if v then
					apply(boxFill, { Size = UDim2.fromOffset(CHECK, CHECK) }, instant, 0.28, Enum.EasingStyle.Back)
				else
					apply(boxFill, { Size = UDim2.fromOffset(0, 0) }, instant, 0.2, Enum.EasingStyle.Quint)
				end
				apply(boxStroke, { Color = v and Theme.Accent or Theme.Stroke }, instant, 0.2)
				themeBindings[boxStroke].Color = v and "Accent" or "Stroke"
				apply(lbl, { TextColor3 = v and Theme.Text or Theme.Dim }, instant, 0.22)
				themeBindings[lbl].TextColor3 = v and "Text" or "Dim"
				if o.Callback then
					task.spawn(o.Callback, v)
				end
				if refreshBindList then
					refreshBindList()
				end
			end
			t.Set = set
			t.Get = function()
				return state
			end
			-- Effective feature state; Get() remains the toggle's enabled state.
			t.IsActive = function()
				return state and (not t._keybind or t._keybind.Active)
			end
			if not o.NoSave then
				Library.Setters[flag] = function(v)
					set(v)
				end
			end

			connect(hit.InputBegan, function(input)
				if blocked(hit, input.Position) then
					return
				end
				if isPointer(input) then
					if holder.AbsoluteSize.X > 0 and inside(holder, input.Position) then
						return
					end
					set(not state)
				elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
					if t._openBindOptions and not listening and os.clock() - bindFinishedAt > 0.15 then
						t._openBindOptions()
					end
				end
			end)
			connect(hit.MouseEnter, function()
				if not state then
					tween(boxStroke, { Color = Theme.Faint }, 0.15)
					tween(lbl, { TextColor3 = Theme.HoverText }, 0.15)
				end
			end)
			connect(hit.MouseLeave, function()
				if not state then
					tween(boxStroke, { Color = Theme.Stroke }, 0.2)
					tween(lbl, { TextColor3 = Theme.Dim }, 0.2)
				end
			end)

			function t:AddColorPicker(c)
				if t._color then
					warn("[menu] у тоггла '" .. o.Name .. "' уже есть колорпикер")
					return t
				end
				t._color = true
				c = c or {}
				local cflag = c.Flag or (flag .. "_Color")
				local current = c.Default or Color3.new(1, 1, 1)
				Library.Flags[cflag] = current

				local sw = sinkButton({
					LayoutOrder = 1,
					Size = UDim2.fromOffset(19, 13),
					BackgroundColor3 = current,
				}, holder)
				themeBindings[sw] = nil -- User-selected colors are independent of the UI theme.
				corner(sw, 3)
				local swStroke = stroke(sw, Color3.new(1, 1, 1), 1)
				swStroke.Transparency = 1
				connect(sw.MouseEnter, function()
					tween(swStroke, { Transparency = 0.6 }, 0.15)
				end)
				connect(sw.MouseLeave, function()
					tween(swStroke, { Transparency = 1 }, 0.2)
				end)
				local function applyColor(newColor)
					current = newColor
					sw.BackgroundColor3 = newColor
					Library.Flags[cflag] = newColor
					if c.Callback then
						task.spawn(c.Callback, newColor)
					end
				end
				clickable(sw, function()
					openPicker(sw, current, applyColor)
				end)
				if not c.NoSave then
					Library.Setters[cflag] = applyColor
				end
				return t
			end

			function t:AddKeybind(k)
				if t._bind then
					warn("[menu] у тоггла '" .. o.Name .. "' уже есть бинд")
					return t
				end
				t._bind = true
				k = k or {}
				local bflag = k.Flag or (flag .. "_Bind")
				local bind = {
					Key = k.Default,
					Mode = k.Mode or "Toggle",
					Show = (k.Show ~= false),
					Name = o.Name,
					Toggle = t,
					Active = false,
				}
				t._keybind = bind
				Library.Flags[bflag .. "_Active"] = false
				bind.SetActive = function(active)
					active = active == true and t.Get()
					if bind.Active == active then return end
					bind.Active = active
					Library.Flags[bflag .. "_Active"] = active
					if k.OnChanged then
						task.spawn(k.OnChanged, active)
					end
					refreshBindList()
				end
				Library.Flags[bflag] = bind.Key
				Library.Flags[bflag .. "_Mode"] = bind.Mode
				Library.Flags[bflag .. "_Show"] = bind.Show

				local chip = sinkButton({
					LayoutOrder = 2,
					Size = UDim2.fromOffset(0, 18),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Font = Theme.FontBold,
					TextSize = 12,
					TextColor3 = Theme.Dim,
					Text = bindText(bind.Key),
				}, holder)

				local function finish(key)
					bind.Key = key
					bind.SetActive(bind.Mode == "Always")
					bindFinishedAt = os.clock()
					Library.Flags[bflag] = key
					chip.Text = bindText(key)
					tween(chip, { TextColor3 = Theme.Dim }, 0.25)
					if k.Callback then
						task.spawn(k.Callback, key)
					end
				end

				local function setMode(m)
					bind.Mode = m
					Library.Flags[bflag .. "_Mode"] = m
					bind.SetActive(m == "Always")
					refreshBindList()
				end

				Library.Setters[bflag] = function(v)
					if v == false then
						v = nil
					end
					finish(v)
				end
				Library.Setters[bflag .. "_Mode"] = function(m)
					if m ~= bind.Mode then
						setMode(m)
					end
					if bind.modeDD then
						bind.modeDD.Set(m)
					end
				end
				Library.Setters[bflag .. "_Show"] = function(v)
					bind.Show = v
					Library.Flags[bflag .. "_Show"] = v
					refreshBindList()
					if bind.showToggle then
						bind.showToggle.Set(v, true)
					end
				end

				local function openOptions()
					if not bind.panel then
						local frame, sub = newPanel(215)
						sub:Header("Bind options")
						bind.modeDD = sub:Dropdown({
							NoSave = true,
							Name = "Mode",
							Flag = bflag .. "_ModeDD",
							Options = { "Always", "Hold", "Toggle" },
							Default = bind.Mode,
							Callback = function(m)
								if m ~= bind.Mode then
									setMode(m)
								end
							end,
						})
						bind.showToggle = sub:Toggle({
							NoSave = true,
							Name = "Show in keybind list",
							Flag = bflag .. "_ShowToggle",
							Default = bind.Show,
							Callback = function(v)
								bind.Show = v
								Library.Flags[bflag .. "_Show"] = v
								refreshBindList()
							end,
						})
						bind.panel = frame
					end
					togglePanel(bind.panel, chip)
				end
				t._openBindOptions = openOptions

				connect(chip.MouseEnter, function()
					if not listening then
						tween(chip, { TextColor3 = Theme.Text }, 0.15)
					end
				end)
				connect(chip.MouseLeave, function()
					if not (listening and listening.bind == bind) then
						tween(chip, { TextColor3 = Theme.Dim }, 0.2)
					end
				end)
				connect(chip.InputBegan, function(input)
					if blocked(chip, input.Position) then
						return
					end
					if isPointer(input) then
						if listening then
							listening.finish(listening.bind.Key)
						end
						listening = { bind = bind, finish = finish, t = os.clock() }
						chip.Text = "[...]"
						tween(chip, { TextColor3 = Theme.Text }, 0.15)
					elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
						if not listening and os.clock() - bindFinishedAt > 0.15 then
							openOptions()
						end
					end
				end)

				local kbRow = create("Frame", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					Visible = false,
				}, kb)
				local kbName = create("TextLabel", {
					Position = UDim2.fromOffset(11, 0),
					Size = UDim2.new(1, -96, 1, 0),
					BackgroundTransparency = 1,
					Text = o.Name,
					Font = Theme.Font,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextColor3 = Theme.Dim,
				}, kbRow)
				local kbMode = create("TextLabel", {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -11, 0, 0),
					Size = UDim2.fromOffset(80, 22),
					BackgroundTransparency = 1,
					Font = Theme.Font,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextColor3 = Theme.Faint,
				}, kbRow)
				bind.kb = { row = kbRow, name = kbName, mode = kbMode, laid = false }

				binds[#binds + 1] = bind
				bind.SetActive(bind.Mode == "Always")
				refreshBindList()
				return t
			end

			function t:AddSetting(s)
				if nested then
					warn("[menu] AddSetting внутри панели настроек не поддерживается")
					return nil
				end
				if t._setting then
					return t._setting
				end
				s = s or {}

				local dots = sinkButton({
					LayoutOrder = 0,
					Size = UDim2.fromOffset(20, 16),
					BackgroundTransparency = 1,
				}, holder)
				local dotRow = create("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(0, 3),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
				}, dots)
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 2),
				}, dotRow)
				local dotFrames = {}
				for i = 1, 3 do
					local d = create("Frame", {
						Size = UDim2.fromOffset(3, 3),
						BackgroundColor3 = Theme.Dim,
						BorderSizePixel = 0,
					}, dotRow)
					corner(d, 2)
					dotFrames[i] = d
				end
				local function dotColor(c)
					for i, d in ipairs(dotFrames) do
						task.delay((i - 1) * 0.03, function()
							if destroyed then return end
							tween(d, { BackgroundColor3 = c }, 0.18)
						end)
					end
				end
				connect(dots.MouseEnter, function()
					dotColor(Theme.Text)
				end)
				connect(dots.MouseLeave, function()
					dotColor(Theme.Dim)
				end)

				local frame, sub = newPanel(s.Width or 232)
				if s.Name then
					sub:Header(s.Name)
				end

				clickable(dots, function()
					togglePanel(frame, dots)
				end)

				t._setting = sub
				return sub
			end

			set(state, true)
			return t
		end
	end

	local activeTab

	local function pageIn(page, instant)
		page.Visible = true
		if instant then
			page.GroupTransparency = 0
			page.Position = UDim2.fromOffset(0, 0)
			return
		end
		page.GroupTransparency = 1
		page.Position = UDim2.fromOffset(0, 10)
		tween(page, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.3)
	end

	local function pageOut(page)
		tween(page, { GroupTransparency = 1 }, 0.14, Enum.EasingStyle.Quad)
		task.delay(0.14, function()
			if destroyed then return end
			if not activeTab or activeTab.Page ~= page then
				page.Visible = false
			end
		end)
	end

	local function selectTab(tab, instant)
		if activeTab == tab then
			return
		end
		closeAll()
		local old = activeTab
		activeTab = tab
		if old then
			old.setActive(false)
			pageOut(old.Page)
		end
		tab.setActive(true)
		pageIn(tab.Page, instant)
	end

	function window:Tab(name, iconId)
		local tab = { _x = 2, _cols = {} }

		local btn = sinkButton({
			LayoutOrder = #window.Tabs + 1,
			Size = UDim2.new(1, -8, 0, 35),
			BackgroundColor3 = Theme.Hover,
			BackgroundTransparency = 1,
		}, tabList)
		corner(btn, 5)

		local setIconColor
		if iconId then
			local img = create("ImageLabel", {
				Position = UDim2.fromOffset(12, 10),
				Size = UDim2.fromOffset(16, 16),
				BackgroundTransparency = 1,
				Image = iconId,
				ImageColor3 = Theme.Dim,
			}, btn)
			setIconColor = function(c)
				tween(img, { ImageColor3 = c }, 0.22)
			end
		else
			local dot = create("Frame", {
				Position = UDim2.fromOffset(12, 10),
				Size = UDim2.fromOffset(16, 16),
				BackgroundTransparency = 1,
			}, btn)
			corner(dot, 8)
			local ds = stroke(dot, Theme.Dim, 1.5)
			setIconColor = function(c)
				tween(ds, { Color = c }, 0.22)
			end
		end

		local label = create("TextLabel", {
			Position = UDim2.fromOffset(40, 0),
			Size = UDim2.new(1, -40, 1, 0),
			BackgroundTransparency = 1,
			Text = name,
			Font = Theme.Font,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Dim,
		}, btn)

		tab.Page = create("CanvasGroup", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			GroupTransparency = 1,
		}, pages)

		local VIEW_H = 442
		tab.Scroll = create("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 0,
			ScrollBarImageColor3 = Theme.Faint,
			ScrollBarImageTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(),
		}, tab.Page)
		local fade = create("UIGradient", { Rotation = 90 }, tab.Page)
		tab.contentH = 0

		tab.updateFade = function()
			local maxScroll = math.max(0, tab.contentH - VIEW_H)
			local pos = tab.Scroll.CanvasPosition.Y
			local topT, botT = 0, 0
			if maxScroll > 0 then
				topT = math.clamp(pos / 40, 0, 1) * 0.9
				botT = math.clamp((maxScroll - pos) / 40, 0, 1) * 0.9
			end
			local f = 34 / VIEW_H
			fade.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, topT),
				NumberSequenceKeypoint.new(f, 0),
				NumberSequenceKeypoint.new(1 - f, 0),
				NumberSequenceKeypoint.new(1, botT),
			})
		end

		tab.relayout = function()
			local h = 0
			for _, c in ipairs(tab._cols) do
				h = math.max(h, c.contentH)
			end
			tab.contentH = h + 2
			tab.Scroll.CanvasSize = UDim2.fromOffset(0, tab.contentH)
			tab.Scroll.ScrollBarThickness = (tab.contentH > VIEW_H) and 2 or 0
			tab.updateFade()
		end

		local barToken = 0
		local function showBar()
			if tab.contentH <= VIEW_H then
				return
			end
			barToken += 1
			local tok = barToken
			tween(tab.Scroll, { ScrollBarImageTransparency = 0.15 }, 0.15)
			task.delay(0.35, function()
				if destroyed then return end
				if barToken == tok then
					tween(tab.Scroll, { ScrollBarImageTransparency = 1 }, 0.18, Enum.EasingStyle.Quad)
				end
			end)
		end

		connect(tab.Scroll:GetPropertyChangedSignal("CanvasPosition"), function()
			showBar()
			tab.updateFade()
			if pickerOpen or ddOpen or panelFrame then
				closeAll()
			end
		end)

		tab.setActive = function(on)
			tween(label, { TextColor3 = on and Theme.Text or Theme.Dim }, 0.22)
			setIconColor(on and Theme.Text or Theme.Dim)
			tween(btn, { BackgroundTransparency = on and 0 or 1 }, 0.22)
		end
		connect(btn.MouseEnter, function()
			if activeTab ~= tab then
				tween(label, { TextColor3 = Theme.HoverText }, 0.15)
			end
		end)
		connect(btn.MouseLeave, function()
			if activeTab ~= tab then
				tween(label, { TextColor3 = Theme.Dim }, 0.2)
			end
		end)
		clickable(btn, function()
			selectTab(tab)
		end)

		function tab:Section(secName, width, column)
			local col
			if column and tab._cols[column] then
				col = tab._cols[column]
			else
				col = { x = tab._x, width = width or 225, sections = {}, contentH = 0 }
				tab._cols[#tab._cols + 1] = col
				tab._x += col.width + 9
			end
			local w = col.width
			local section = { _y = 32 }

			local frame = create("Frame", {
				Position = UDim2.fromOffset(col.x, 2),
				Size = UDim2.fromOffset(w, 38),
				BackgroundColor3 = Theme.Panel,
				BorderSizePixel = 0,
			}, tab.Scroll)
			corner(frame, 6)
			local frameStroke = stroke(frame, Theme.Stroke)
			col.sections[#col.sections + 1] = frame

			local function layoutColumn()
				local y = 2
				for _, f in ipairs(col.sections) do
					f.Position = UDim2.fromOffset(col.x, y)
					y += f.Size.Y.Offset + 9
				end
				col.contentH = y - 9
				tab.relayout()
			end
			layoutColumn()

			create("TextLabel", {
				Position = UDim2.fromOffset(11, 8),
				Size = UDim2.new(1, -22, 0, 18),
				BackgroundTransparency = 1,
				Text = secName,
				Font = Theme.FontBold,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Text,
			}, frame)

			attach(section, function(h)
				local row = create("Frame", {
					Position = UDim2.fromOffset(0, section._y),
					Size = UDim2.new(1, 0, 0, h),
					BackgroundTransparency = 1,
				}, frame)
				section._y += h
				frame.Size = UDim2.fromOffset(w, section._y + 6)
				layoutColumn()
				return row
			end, false)

			return section
		end

		window.Tabs[#window.Tabs + 1] = tab
		if #window.Tabs == 1 then
			selectTab(tab, true)
		end
		return tab
	end

	function window:SaveConfig(name)
		if not name or name == "" then
			return false, "Config name is empty"
		end
		local ok, err = Library.FS.save(configFolder, name, Library.Export())
		return ok, err
	end

	function window:LoadConfig(name)
		if not name or name == "" then
			return false, "Config name is empty"
		end
		local data, err = Library.FS.read(configFolder, name)
		if not data then
			return false, err
		end
		if Library.Import(data) then
			return true
		else
			return false, "Config is corrupted"
		end
	end

	function window:DeleteConfig(name)
		if not name or name == "" then
			return false, "Config name is empty"
		end
		name = Library.FS.normalize(name)
		local previousAutoload = preferences.Autoload
		if name == previousAutoload then
			local ok, err = self:SetPreference("Autoload", false)
			if not ok then return false, err end
		end
		local ok, err = Library.FS.delete(configFolder, name)
		if not ok and name == previousAutoload then
			self:SetPreference("Autoload", previousAutoload)
		end
		return ok, err
	end

	function window:SetAutoload(name)
		if name == false then return self:SetPreference("Autoload", false) end
		name = Library.FS.normalize(name)
		local data, err = Library.FS.read(configFolder, name)
		if not data then return false, err end
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, data)
		if not ok or type(decoded) ~= "table" then return false, "Config is corrupted" end
		return self:SetPreference("Autoload", name)
	end

	function window:RefreshConfigs()
		return Library.FS.list(configFolder)
	end

	task.defer(function()
		if destroyed then return end
		setMenu(true)
	end)

	return window
end

return Library
