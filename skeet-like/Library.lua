local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Lib = {}
Lib.Version = "0.1.0"
Lib.Flags = {}
Lib.ConfigFolder = "yourlib"

Lib.Icons = {
	Search = "rbxassetid://72296609649861",
	Settings = "rbxassetid://106205298246017",
	ChevronDown = "rbxassetid://71457658246709",
}

local hex = Color3.fromHex
local Theme = {
	Accent = hex("#b4e34a"),
	Outline = hex("#050506"),
	Border = hex("#26262c"),
	Window = hex("#0c0c0f"),
	Bar = hex("#09090b"),
	Divider = hex("#1f1f24"),
	DividerSoft = hex("#1c1c21"),
	Group = hex("#0f0f12"),
	GroupBorder = hex("#24242a"),
	Popup = hex("#0e0e11"),
	Control = hex("#141418"),
	ControlBorder = hex("#2a2a30"),
	ControlHover = hex("#3a3a42"),
	ButtonHover = hex("#1d1d22"),
	ItemHover = hex("#16161a"),
	Track = hex("#18181c"),
	BoxOff = hex("#1c1c21"),
	BoxBorderOff = hex("#3a3a42"),
	SwatchRing = hex("#2c2c33"),
	Input = hex("#09090b"),
	Text = hex("#e8e8ec"),
	TextBright = hex("#ececf0"),
	TextTitle = hex("#e4e4e8"),
	TextValue = hex("#d6d6da"),
	TextNormal = hex("#c8c8cc"),
	TextDim = hex("#9a9aa3"),
	TextMuted = hex("#8a8a93"),
	TextFaint = hex("#6f6f78"),
	Separator = "#55555d",
	TextSize = 13,
}

Lib.FontPresets = {
	Inter = {
		Medium = "https://raw.githubusercontent.com/rsms/inter/v3.19/docs/font-files/Inter-Medium.otf",
		SemiBold = "https://raw.githubusercontent.com/rsms/inter/v3.19/docs/font-files/Inter-SemiBold.otf",
		Bold = "https://raw.githubusercontent.com/rsms/inter/v3.19/docs/font-files/Inter-Bold.otf",
	},
	ProggyClean = {
		Regular = "https://raw.githubusercontent.com/ocornut/imgui/master/misc/fonts/ProggyClean.ttf",
	},
}

local function ensurePath(path)
	if typeof(isfolder) ~= "function" or typeof(makefolder) ~= "function" then
		return
	end
	local cur = ""
	for part in string.gmatch(path, "[^/\\]+") do
		cur = cur == "" and part or (cur .. "/" .. part)
		if not isfolder(cur) then
			makefolder(cur)
		end
	end
end

local FACE_WEIGHTS = { Thin = 100, Light = 300, Regular = 400, Medium = 500, SemiBold = 600, Bold = 700, Heavy = 900 }

function Lib:LoadFont(name, faces)
	assert(typeof(writefile) == "function" and typeof(getcustomasset) == "function", "writefile and getcustomasset are required")
	local dir = Lib.ConfigFolder .. "/fonts"
	ensurePath(dir)
	local list = {}
	for face, url in pairs(faces) do
		local weight = FACE_WEIGHTS[face]
		if weight then
			local ext = url:match("%.(%a+)$") or "ttf"
			local file = dir .. "/" .. name .. "-" .. face .. "." .. ext
			if typeof(isfile) ~= "function" or not isfile(file) then
				writefile(file, game:HttpGet(url))
			end
			table.insert(list, { name = face, weight = weight, style = "normal", assetId = getcustomasset(file) })
		end
	end
	local json = dir .. "/" .. name .. ".json"
	writefile(json, HttpService:JSONEncode({ name = name, faces = list }))
	return getcustomasset(json)
end

local function setFont(spec)
	local preset = type(spec) == "string" and Lib.FontPresets[spec]
	if preset or type(spec) == "table" then
		local name = type(spec) == "string" and spec or (spec.Name or "Custom")
		local faces = preset or spec
		local ok, asset = pcall(function()
			return Lib:LoadFont(name, faces)
		end)
		if ok and asset then
			Theme.FontFamily = name
			Theme.Font = Font.new(asset, Enum.FontWeight.Medium)
			Theme.FontBold = Font.new(asset, Enum.FontWeight.Bold)
			return true
		end
		warn("[your.lib] font " .. name .. " failed to load (" .. tostring(asset) .. "), using BuilderSans")
		spec = "BuilderSans"
	end
	local path = "rbxasset://fonts/families/" .. spec .. ".json"
	Theme.FontFamily = spec
	Theme.Font = Font.new(path, Enum.FontWeight.Medium)
	Theme.FontBold = Font.new(path, Enum.FontWeight.Bold)
	return true
end
setFont("BuilderSans")
Lib.SetFont = function(_, spec)
	return setFont(spec)
end
Lib.Theme = Theme

local MB1 = Enum.UserInputType.MouseButton1
local MB2 = Enum.UserInputType.MouseButton2
local TOUCH = Enum.UserInputType.Touch
local MOVE = Enum.UserInputType.MouseMovement

local GuiService = game:GetService("GuiService")
local mouseOffsetY = 0
local function calibrateOn(gui)
	local m = UserInputService:GetMouseLocation()
	local a, sz = gui.AbsolutePosition, gui.AbsoluteSize
	local inset = GuiService:GetGuiInset().Y
	if inset <= 0 or sz.Y <= 0 then
		return
	end
	local fit0 = m.Y >= a.Y and m.Y <= a.Y + sz.Y
	local fitI = m.Y - inset >= a.Y and m.Y - inset <= a.Y + sz.Y
	if fit0 ~= fitI then
		mouseOffsetY = fitI and inset or 0
	end
end

local function new(class, props, parent)
	local inst = Instance.new(class)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	if inst:IsA("GuiButton") then
		inst.AutoButtonColor = false
		inst.MouseEnter:Connect(function()
			calibrateOn(inst)
		end)
	end
	if inst:IsA("TextButton") or inst:IsA("TextBox") then
		inst.Text = ""
	end
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function tween(obj, time, props, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local widthCache = {}
local function textWidth(str, size, font)
	local key = str .. "|" .. size .. "|" .. font.Family .. "|" .. tostring(font.Weight)
	local cached = widthCache[key]
	if cached then
		return cached
	end
	local params = Instance.new("GetTextBoundsParams")
	params.Text = str
	params.Size = size
	params.Font = font
	params.Width = 10000
	local ok, bounds = pcall(function()
		return TextService:GetTextBoundsAsync(params)
	end)
	local w = ok and math.ceil(bounds.X) or math.ceil(#str * size * 0.55)
	widthCache[key] = w
	return w
end

local function label(parent, props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.TextNormal,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
	})
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	l.Parent = parent
	return l
end

local function box(parent, outline, border, fill, class)
	local outer = new(class or "Frame", { BackgroundColor3 = outline }, parent)
	local mid = new("Frame", {
		BackgroundColor3 = border,
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
	}, outer)
	local inner = new("Frame", {
		BackgroundColor3 = fill,
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
	}, mid)
	return outer, mid, inner
end

local FALLBACK = { Search = "", Settings = "*", ChevronDown = "v" }
local function icon(parent, name, size, color)
	local id = Lib.Icons[name]
	if id and id ~= "" then
		local img = new("ImageLabel", {
			BackgroundTransparency = 1,
			Image = id,
			ImageColor3 = color,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(size, size),
		}, parent)
		return img, "ImageColor3"
	end
	local l = label(parent, {
		Text = FALLBACK[name] or "",
		TextColor3 = color,
		TextSize = size + 2,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(size, size),
	})
	return l, "TextColor3"
end

local function inside(gui, pos)
	if not gui or not gui.Parent then
		return false
	end
	local a, s = gui.AbsolutePosition, gui.AbsoluteSize
	return pos.X >= a.X and pos.X <= a.X + s.X and pos.Y >= a.Y and pos.Y <= a.Y + s.Y
end

local function mouse()
	local m = UserInputService:GetMouseLocation()
	return Vector2.new(m.X, m.Y - mouseOffsetY)
end

local function escapeRich(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local KEY_NAMES = {
	MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3",
	LeftShift = "SHIFT", RightShift = "RSHIFT", LeftControl = "CTRL", RightControl = "RCTRL",
	LeftAlt = "ALT", RightAlt = "RALT", Space = "SPACE", Return = "ENTER", CapsLock = "CAPS",
	Insert = "INS", Delete = "DEL", PageUp = "PGUP", PageDown = "PGDN", Backquote = "`",
	Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
	Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
}
local function keyName(k)
	if not k then
		return "-"
	end
	return KEY_NAMES[k.Name] or k.Name:upper()
end

local function parseEnum(s)
	if type(s) ~= "string" then
		return nil
	end
	local et, name = s:match("^Enum%.(%w+)%.(%w+)$")
	if not et then
		return nil
	end
	local ok, v = pcall(function()
		return Enum[et][name]
	end)
	return ok and v or nil
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Container = {}
Container.__index = Container

local function newContainer(w, tab, frame, indent, level)
	return setmetatable({
		Window = w,
		Tab = tab,
		Frame = frame,
		Indent = indent,
		Level = level,
		_order = 0,
		_height = 0,
	}, Container)
end

function Container:_row(h)
	self._order += 1
	if self._order > 1 then
		self._height += 2
	end
	self._height += h
	local row = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, h),
		LayoutOrder = self._order,
	}, self.Frame)
	if self._onGrow then
		self._onGrow()
	end
	return row
end

function Container:_register(name, row)
	if self.Tab then
		table.insert(self.Tab._search, {
			Name = string.lower(name or ""),
			Row = row,
			Group = self.GroupRef,
		})
	end
end

function Window:_conn(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self._conns, c)
	return c
end

function Window:_accent(fn)
	table.insert(self._accentHooks, fn)
	fn(self.Accent)
end

function Window:SetAccent(color)
	self.Accent = color
	for _, fn in ipairs(self._accentHooks) do
		task.spawn(fn, color)
	end
end

function Window:_draggable(handle, target)
	local dragging, startMouse, startPos = false, nil, nil
	self:_conn(handle.InputBegan, function(input)
		if input.UserInputType == MB1 or input.UserInputType == TOUCH then
			dragging = true
			startMouse = mouse()
			startPos = target.Position
			self:_closePopups(1)
		end
	end)
	self:_conn(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == MOVE or input.UserInputType == TOUCH) then
			local d = mouse() - startMouse
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
	self:_conn(UserInputService.InputEnded, function(input)
		if dragging and (input.UserInputType == MB1 or input.UserInputType == TOUCH) then
			dragging = false

			local screen = self:_screen()
			local a, sz = target.AbsolutePosition, target.AbsoluteSize
			local dx = math.max(0, -a.X) - math.max(0, a.X + sz.X - screen.X)
			local dy = math.max(0, -a.Y) - math.max(0, a.Y + sz.Y - screen.Y)
			if dx ~= 0 or dy ~= 0 then
				local p = target.Position
				tween(target, 0.25, { Position = UDim2.new(p.X.Scale, p.X.Offset + dx, p.Y.Scale, p.Y.Offset + dy) })
			end
		end
	end)
end

function Window:_popup(width)
	local w = self
	local root, mid, inner = box(self._overlay, Theme.Outline, Theme.ControlBorder, Theme.Popup, "CanvasGroup")
	root.Size = UDim2.fromOffset(width, 40)
	root.Visible = false
	root.GroupTransparency = 1
	root.ZIndex = 10

	local p = { Root = root, Mid = mid, Inner = inner, Open = false, Hovered = false }

	w:_conn(root.MouseEnter, function()
		p.Hovered = true
	end)
	w:_conn(root.MouseLeave, function()
		p.Hovered = false
	end)

	function p:Place(anchor, alignRight, gap)
		self.Anchor = anchor
		gap = gap or 2
		local o = w._overlay.AbsolutePosition
		local ap, as = anchor.AbsolutePosition - o, anchor.AbsoluteSize
		local size = root.Size
		local screen = w._overlay.AbsoluteSize
		local x = alignRight and (ap.X + as.X - size.X.Offset) or ap.X
		local y = ap.Y + as.Y + gap
		x = math.clamp(x, 4, math.max(4, screen.X - size.X.Offset - 4))
		if y + size.Y.Offset > screen.Y - 4 then
			y = ap.Y - size.Y.Offset - gap
		end
		self.Target = UDim2.fromOffset(x, y)
	end

	function p:Show()
		self.Open = true
		root.Visible = true
		root.Position = self.Target + UDim2.fromOffset(0, -4)
		tween(root, 0.18, { GroupTransparency = 0, Position = self.Target })
		if self.OnOpen then
			self.OnOpen()
		end
	end

	function p:Close()
		if not self.Open then
			return
		end
		self.Open = false
		if self.OnClose then
			self.OnClose()
		end
		local t = tween(root, 0.12, { GroupTransparency = 1 })
		t.Completed:Connect(function()
			if not self.Open then
				root.Visible = false
			end
		end)
	end

	return p
end

function Window:_closePopups(level)
	level = level or 1
	for i = #self._popups, level, -1 do
		local p = self._popups[i]
		self._popups[i] = nil
		if p then
			p:Close()
		end
	end
end

function Window:_togglePopup(p, anchor, level, alignRight)
	if p.Open then
		self:_closePopups(level)
		return
	end
	self:_closePopups(level)
	p:Place(anchor, alignRight)
	self._popups[level] = p
	p:Show()
end

function Window:_clickAway()
	if #self._popups == 0 then
		return
	end
	local pos = mouse()
	local keep = 0
	for i, p in ipairs(self._popups) do
		if p.Hovered or inside(p.Root, pos) or (p.Anchor and inside(p.Anchor, pos)) then
			keep = i
		end
	end
	self:_closePopups(keep + 1)
end

function Window:_bindInput(input, began)
	local key = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
	for _, b in ipairs(self._binds) do
		if b.Key ~= nil and b.Key == key then
			if b.Mode == "Toggle" then
				if began then
					b:_setActive(not b.Active)
				end
			elseif b.Mode == "Hold" then
				b:_setActive(began)
			end
		end
	end
end

function Window:_captureBind(input)
	local b = self._listening
	local t = input.UserInputType
	if t == Enum.UserInputType.Keyboard then
		local k = input.KeyCode
		if k == Enum.KeyCode.Escape then

		elseif k == Enum.KeyCode.Backspace or k == Enum.KeyCode.Delete then
			b.Key = nil
		else
			b.Key = k
		end
	elseif t == MB2 or t == Enum.UserInputType.MouseButton3 then
		b.Key = t
	elseif t == MB1 then

	else
		return
	end
	b:_stopListen()
	self:_refreshKeybinds()
end

function Window:_colorPicker(initial, onChange)
	local w = self
	local p = self:_popup(198)
	local inner = p.Inner
	local h, s, v = initial:ToHSV()

	local sv = new("TextButton", {
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(176, 120),
	}, inner)
	local white = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1) }, sv)
	new("UIGradient", { Transparency = NumberSequence.new(0, 1) }, white)
	local black = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 1) }, sv)
	new("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90 }, black)

	local cursor = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		ZIndex = 3,
	}, sv)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, cursor)
	new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1 }, cursor)
	local ring = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
	}, cursor)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
	new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }, ring)

	local hue = new("TextButton", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = UDim2.fromOffset(10, 138),
		Size = UDim2.fromOffset(176, 10),
	}, inner)
	local kps = {}
	for i = 0, 6 do
		table.insert(kps, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 1, 1)))
	end
	new("UIGradient", { Color = ColorSequence.new(kps) }, hue)
	local marker = new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(3, 14),
		ZIndex = 3,
	}, hue)
	new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }, marker)

	local prevOuter, _, preview = box(inner, Theme.ControlBorder, Theme.Outline, initial)
	prevOuter.Position = UDim2.fromOffset(10, 156)
	prevOuter.Size = UDim2.fromOffset(24, 20)

	local hexBorder = new("Frame", {
		BackgroundColor3 = Theme.GroupBorder,
		Position = UDim2.fromOffset(40, 156),
		Size = UDim2.fromOffset(146, 20),
	}, inner)
	local hexBox = new("TextBox", {
		BackgroundColor3 = Theme.Input,
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		FontFace = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.TextValue,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	}, hexBorder)
	new("UIPadding", { PaddingLeft = UDim.new(0, 6) }, hexBox)

	p.Root.Size = UDim2.fromOffset(198, 190)

	local picker = { Popup = p }

	local function render(fire)
		local col = Color3.fromHSV(h, s, v)
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		cursor.Position = UDim2.fromOffset(s * 176, (1 - v) * 120)
		marker.Position = UDim2.new(h, 0, 0, -2)
		preview.BackgroundColor3 = col
		if not hexBox:IsFocused() then
			hexBox.Text = "#" .. col:ToHex():upper()
		end
		if fire then
			onChange(col)
		end
	end

	function picker:Set(col, silent)
		h, s, v = col:ToHSV()
		render(not silent)
	end

	function picker:Get()
		return Color3.fromHSV(h, s, v)
	end

	local dragging
	local function update()
		local m = mouse()
		if dragging == "sv" then
			s = math.clamp((m.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
			v = 1 - math.clamp((m.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
		elseif dragging == "hue" then
			h = math.clamp((m.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 0.999)
		end
		render(true)
	end

	w:_conn(sv.MouseButton1Down, function()
		dragging = "sv"
		update()
	end)
	w:_conn(hue.MouseButton1Down, function()
		dragging = "hue"
		update()
	end)
	w:_conn(UserInputService.InputChanged, function(i)
		if dragging and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
			update()
		end
	end)
	w:_conn(UserInputService.InputEnded, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			dragging = nil
		end
	end)
	w:_conn(hexBox.FocusLost, function()
		local ok, col = pcall(Color3.fromHex, (hexBox.Text:gsub("#", "")))
		if ok and col then
			picker:Set(col)
		else
			render(false)
		end
	end)

	render(false)
	return picker
end

local function colorSwatch(w, parent, o)
	o = o or {}
	local c = {
		Window = w,
		Value = o.Default or Color3.new(1, 1, 1),
		Callback = o.Callback or function() end,
		Flag = o.Flag,
	}
	local outer, _, fill = box(parent, Theme.SwatchRing, Theme.Outline, c.Value, "TextButton")
	outer.Size = UDim2.fromOffset(18, 10)

	c.Picker = w:_colorPicker(c.Value, function(col)
		c.Value = col
		fill.BackgroundColor3 = col
		task.spawn(c.Callback, col)
	end)
	local p = c.Picker.Popup
	p.OnOpen = function()
		tween(outer, 0.12, { BackgroundColor3 = w.Accent })
	end
	p.OnClose = function()
		tween(outer, 0.12, { BackgroundColor3 = Theme.SwatchRing })
	end
	w:_accent(function(col)
		if p.Open then
			outer.BackgroundColor3 = col
		end
	end)

	function c:Set(col, silent)
		self.Picker:Set(col, silent)
		if silent then
			self.Value = col
			fill.BackgroundColor3 = col
		end
	end
	function c:Get()
		return self.Value
	end
	function c:_save()
		return self.Value:ToHex()
	end
	function c:_load(d)
		local ok, col = pcall(Color3.fromHex, d)
		if ok then
			self:Set(col)
		end
	end
	if c.Flag then
		Lib.Flags[c.Flag] = c
	end
	return c, outer
end

local function checkbox(parent, gapColor)
	local outer = new("Frame", { BackgroundColor3 = Theme.BoxBorderOff, Size = UDim2.fromOffset(10, 10) }, parent)
	local gap = new("Frame", {
		BackgroundColor3 = gapColor,
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
	}, outer)
	local fill = new("Frame", {
		BackgroundColor3 = Theme.BoxOff,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -2, 1, -2),
	}, gap)
	local cb = { Outer = outer, Fill = fill }
	function cb:Paint(on, accent, animate, pop)
		local f = on and accent or Theme.BoxOff
		local b = on and accent or Theme.BoxBorderOff
		if pop and on then
			fill.Size = UDim2.fromOffset(0, 0)
			tween(fill, 0.25, { Size = UDim2.new(1, -2, 1, -2) }, Enum.EasingStyle.Back)
		end
		if animate then
			tween(fill, 0.15, { BackgroundColor3 = f })
			tween(outer, 0.15, { BackgroundColor3 = b })
		else
			fill.BackgroundColor3 = f
			outer.BackgroundColor3 = b
		end
	end
	return cb
end

local function hoverBg(w, btn)
	w:_conn(btn.MouseEnter, function()
		tween(btn, 0.12, { BackgroundTransparency = 0 })
	end)
	w:_conn(btn.MouseLeave, function()
		tween(btn, 0.12, { BackgroundTransparency = 1 })
	end)
end

function Container:AddToggle(o)
	o = o or {}
	local w, level = self.Window, self.Level
	local t = {
		Window = w,
		Name = o.Name or "Toggle",
		Value = o.Default == true,
		Callback = o.Callback or function() end,
		Flag = o.Flag,
		_hover = false,
	}
	t.ListName = o.ListName or ((t.Name == "Enabled" and self.Title) or t.Name)

	local row = self:_row(20)
	local hit = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, row)
	local cb = checkbox(row, level > 0 and Theme.Popup or Theme.Group)
	cb.Outer.Position = UDim2.new(0, 0, 0.5, -5)
	local text = label(row, {
		Text = t.Name,
		Position = UDim2.fromOffset(19, 0),
		Size = UDim2.new(1, -19, 1, 0),
		TextColor3 = Theme.TextDim,
	})
	local right = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
	}, row)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}, right)
	t.Row, t.Right = row, right

	local function paint(animate, pop)
		cb:Paint(t.Value, w.Accent, animate, pop)
		local c = (t.Value or t._hover) and Theme.Text or Theme.TextDim
		if animate then
			tween(text, 0.15, { TextColor3 = c })
		else
			text.TextColor3 = c
		end
	end

	function t:Set(v, silent)
		v = v == true
		if self.Value == v then
			return
		end
		self.Value = v
		paint(true, true)
		if not silent then
			task.spawn(self.Callback, v)
		end
		w:_refreshKeybinds()
	end
	function t:Get()
		return self.Value
	end
	function t:IsActive()
		if self.Keybind then
			return self.Value and self.Keybind.Active
		end
		return self.Value
	end

	w:_conn(hit.MouseButton1Click, function()
		t:Set(not t.Value)
	end)
	w:_conn(hit.MouseEnter, function()
		t._hover = true
		paint(true)
	end)
	w:_conn(hit.MouseLeave, function()
		t._hover = false
		paint(true)
	end)
	w:_accent(function()
		paint(false)
	end)

	function t:AddKeybind(bo)
		bo = bo or {}
		local b = {
			Toggle = t,
			Key = bo.Default,
			Mode = bo.Mode or "Toggle",
			ShowInList = bo.ShowInList ~= false,
			Active = false,
			Callback = bo.Callback or function() end,
			Listening = false,
		}
		b.Active = b.Mode == "Always"
		t.Keybind = b
		table.insert(w._binds, b)

		local btn = new("TextButton", {
			BackgroundTransparency = 1,
			FontFace = Theme.Font,
			TextSize = 12,
			TextColor3 = Theme.TextMuted,
			LayoutOrder = 1,
			Size = UDim2.fromOffset(24, 20),
		}, right)
		local pulse
		local menuOpen, bindHover = false, false

		local function refresh()
			btn.Text = b.Listening and "[...]" or ("[" .. keyName(b.Key) .. "]")
			btn.Size = UDim2.fromOffset(textWidth(btn.Text, 12, Theme.Font) + 4, 20)
			local c = (b.Listening or menuOpen) and w.Accent or (bindHover and Theme.TextBright or Theme.TextMuted)
			tween(btn, 0.12, { TextColor3 = c })
		end
		w:_conn(btn.MouseEnter, function()
			bindHover = true
			refresh()
		end)
		w:_conn(btn.MouseLeave, function()
			bindHover = false
			refresh()
		end)

		function b:_setActive(v)
			if self.Active == v then
				return
			end
			self.Active = v
			task.spawn(self.Callback, v)
			w:_refreshKeybinds()
		end
		function b:_startListen()
			self.Listening = true
			w._listening = self
			refresh()
			pulse = TweenService:Create(
				btn,
				TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ TextTransparency = 0.65 }
			)
			pulse:Play()
		end
		function b:_stopListen()
			self.Listening = false
			if w._listening == self then
				w._listening = nil
			end
			if pulse then
				pulse:Cancel()
				pulse = nil
			end
			btn.TextTransparency = 0
			self._stopTick = os.clock()
			refresh()
			if self._paintMenu then
				self._paintMenu()
			end
		end
		function b:SetKey(k)
			self.Key = k
			refresh()
			w:_refreshKeybinds()
		end
		function b:SetMode(m)
			self.Mode = m
			self:_setActive(m == "Always")
			if self._paintMenu then
				self._paintMenu()
			end
			w:_refreshKeybinds()
		end
		function b:SetShowInList(v)
			self.ShowInList = v
			if self._paintMenu then
				self._paintMenu()
			end
			w:_refreshKeybinds()
		end

		local menu = w:_popup(160)
		local mi = menu.Inner
		local header = label(mi, {
			Position = UDim2.fromOffset(10, 4),
			Size = UDim2.new(1, -20, 0, 16),
			TextSize = 12,
			TextColor3 = Theme.TextMuted,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local y = 22
		local modeRows = {}
		for _, m in ipairs({ "Hold", "Toggle", "Always" }) do
			local r = new("TextButton", {
				BackgroundColor3 = Theme.ItemHover,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, y),
				Size = UDim2.new(1, 0, 0, 20),
			}, mi)
			local l = label(r, { Text = m, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0) })
			modeRows[m] = { Btn = r, Label = l, Hover = false }
			w:_conn(r.MouseEnter, function()
				modeRows[m].Hover = true
				b._paintMenu()
			end)
			w:_conn(r.MouseLeave, function()
				modeRows[m].Hover = false
				b._paintMenu()
			end)
			w:_conn(r.MouseButton1Click, function()
				b:SetMode(m)
				w:_closePopups(level + 1)
			end)
			y += 20
		end
		new("Frame", {
			BackgroundColor3 = Theme.Divider,
			Position = UDim2.fromOffset(0, y + 4),
			Size = UDim2.new(1, 0, 0, 1),
		}, mi)
		y += 9
		local showRow = new("TextButton", {
			BackgroundColor3 = Theme.ItemHover,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.new(1, 0, 0, 20),
		}, mi)
		local showCb = checkbox(showRow, Theme.Popup)
		showCb.Outer.Position = UDim2.new(0, 10, 0.5, -5)
		label(showRow, { Text = "Show in keybinds", Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -36, 1, 0) })
		hoverBg(w, showRow)
		w:_conn(showRow.MouseButton1Click, function()
			b:SetShowInList(not b.ShowInList)
		end)
		y += 20
		menu.Root.Size = UDim2.fromOffset(160, y + 4 + 4)

		b._paintMenu = function()
			header.Text = t.ListName .. "  ·  [" .. keyName(b.Key) .. "]"
			for m, r in pairs(modeRows) do
				local on = b.Mode == m

				tween(r.Label, 0.12, { TextColor3 = on and w.Accent or Theme.TextNormal })
				tween(r.Btn, 0.12, { BackgroundTransparency = (on or r.Hover) and 0 or 1 })
			end
			showCb:Paint(b.ShowInList, w.Accent, true)
		end
		menu.OnOpen = function()
			menuOpen = true
			b._paintMenu()
			refresh()
		end
		menu.OnClose = function()
			menuOpen = false
			refresh()
		end

		w:_conn(btn.MouseButton1Click, function()
			if b._stopTick and os.clock() - b._stopTick < 0.3 then
				return
			end
			if b.Listening then
				b:_stopListen()
			else
				if w._listening then
					w._listening:_stopListen()
				end
				w:_closePopups(1)
				b:_startListen()
			end
		end)
		w:_conn(btn.MouseButton2Click, function()
			if b.Listening then
				b:_stopListen()
			end
			w:_togglePopup(menu, btn, level + 1, true)
		end)
		w:_accent(function()
			refresh()
			if menuOpen then
				b._paintMenu()
			end
		end)

		refresh()
		b._paintMenu()
		w:_refreshKeybinds()
		return b
	end

	function t:AddColor(co)
		local c, outer = colorSwatch(w, right, co)
		outer.LayoutOrder = 3
		w:_conn(outer.MouseButton1Click, function()
			w:_togglePopup(c.Picker.Popup, outer, level + 1, true)
		end)
		t.Color = c
		return c
	end
	t.AddColorpicker = t.AddColor

	function t:AddSettings()
		local gear = new("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(14, 20),
			LayoutOrder = 2,
		}, right)
		local ic, prop = icon(gear, "Settings", 12, Theme.TextFaint)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.fromScale(0.5, 0.5)

		local p = w:_popup(214)
		local pi = p.Inner
		label(pi, {
			Text = t.ListName,
			FontFace = Theme.FontBold,
			TextColor3 = Theme.TextTitle,
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(1, -20, 0, 18),
		})
		label(pi, {
			Text = "settings",
			TextSize = 12,
			TextColor3 = Theme.TextFaint,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(1, -20, 0, 18),
		})
		new("Frame", {
			BackgroundColor3 = Theme.Divider,
			Position = UDim2.fromOffset(10, 28),
			Size = UDim2.new(1, -20, 0, 1),
		}, pi)
		local content = new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 34),
			Size = UDim2.new(1, -20, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, pi)
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, content)

		local sub = newContainer(w, nil, content, 0, level + 1)
		sub.Title = t.ListName
		sub._onGrow = function()
			p.Root.Size = UDim2.fromOffset(214, 34 + sub._height + 10 + 4)
		end
		sub._onGrow()

		local open, hovered = false, false
		local function paintGear()
			local c = open and w.Accent or (hovered and Theme.TextValue or Theme.TextFaint)
			tween(ic, 0.12, { [prop] = c })
		end
		p.OnOpen = function()
			open = true
			paintGear()
			tween(ic, 0.35, { Rotation = 90 })
		end
		p.OnClose = function()
			open = false
			paintGear()
			tween(ic, 0.35, { Rotation = 0 })
		end
		w:_conn(gear.MouseEnter, function()
			hovered = true
			paintGear()
		end)
		w:_conn(gear.MouseLeave, function()
			hovered = false
			paintGear()
		end)
		w:_conn(gear.MouseButton1Click, function()
			w:_togglePopup(p, gear, level + 1, true)
		end)
		w:_accent(function()
			if open then
				paintGear()
			end
		end)
		return sub
	end

	function t:_save()
		local d = { v = self.Value }
		if self.Keybind then
			d.k = self.Keybind.Key and tostring(self.Keybind.Key) or false
			d.m = self.Keybind.Mode
			d.s = self.Keybind.ShowInList
		end
		return d
	end
	function t:_load(d)
		if type(d) ~= "table" then
			return
		end
		self:Set(d.v == true)
		local b = self.Keybind
		if b then
			if d.k == false then
				b:SetKey(nil)
			elseif d.k then
				b:SetKey(parseEnum(d.k))
			end
			if d.m then
				b:SetMode(d.m)
			end
			if d.s ~= nil then
				b:SetShowInList(d.s)
			end
		end
	end

	if t.Flag then
		Lib.Flags[t.Flag] = t
	end
	self:_register(t.Name, row)
	return t
end

function Container:AddSlider(o)
	o = o or {}
	local w, ind = self.Window, self.Indent
	local s = {
		Window = w,
		Name = o.Name or "Slider",
		Min = o.Min or 0,
		Max = o.Max or 100,
		Decimals = o.Decimals or 0,
		Suffix = o.Suffix or "",
		Callback = o.Callback or function() end,
		Flag = o.Flag,
	}
	s.Value = math.clamp(o.Default or s.Min, s.Min, s.Max)

	local function fmt(v)
		if s.Decimals == 0 then
			return tostring(math.floor(v + 0.5))
		end
		return string.format("%." .. s.Decimals .. "f", v)
	end

	local row = self:_row(34)
	label(row, {
		Text = s.Name,
		Position = UDim2.fromOffset(ind, 2),
		Size = UDim2.new(1, -ind - 60, 0, 14),
		TextColor3 = Theme.TextDim,
	})
	local sufW = s.Suffix ~= "" and textWidth(s.Suffix, Theme.TextSize, Theme.Font) or 0
	label(row, {
		Text = s.Suffix,
		TextColor3 = Theme.TextMuted,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Size = UDim2.fromOffset(sufW, 14),
	})
	local boxW = math.max(
		textWidth(fmt(s.Max), Theme.TextSize, Theme.Font),
		textWidth(fmt(s.Min), Theme.TextSize, Theme.Font)
	) + 8
	local input = new("TextBox", {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.TextTitle,
		TextXAlignment = Enum.TextXAlignment.Right,
		ClearTextOnFocus = false,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -sufW - 1, 0, 2),
		Size = UDim2.fromOffset(boxW, 14),
	}, row)
	local under = new("Frame", {
		BackgroundColor3 = Theme.ControlBorder,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
	}, input)

	local outer, _, track = box(row, Theme.Border, Theme.Outline, Theme.Track)
	outer.Position = UDim2.fromOffset(ind, 20)
	outer.Size = UDim2.new(1, -ind, 0, 11)
	local fill = new("Frame", { BackgroundColor3 = w.Accent, Size = UDim2.fromScale(0, 1) }, track)

	local function render(animate)
		local pct = (s.Value - s.Min) / math.max(s.Max - s.Min, 1e-9)
		local target = UDim2.fromScale(pct, 1)
		if animate then
			tween(fill, 0.12, { Size = target })
		else
			fill.Size = target
		end
		if not input:IsFocused() then
			input.Text = fmt(s.Value)
		end
	end

	function s:Set(v, silent)
		local m = 10 ^ self.Decimals
		v = math.clamp(math.floor(v * m + 0.5) / m, self.Min, self.Max)
		if v == self.Value then
			render(true)
			return
		end
		self.Value = v
		render(true)
		if not silent then
			task.spawn(self.Callback, v)
		end
	end
	function s:Get()
		return self.Value
	end
	function s:_save()
		return self.Value
	end
	function s:_load(d)
		if type(d) == "number" then
			self:Set(d)
		end
	end

	local dragging, hovered = false, false
	local function fromMouse()
		local rel = math.clamp((mouse().X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		s:Set(s.Min + rel * (s.Max - s.Min))
	end
	w:_conn(outer.InputBegan, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			dragging = true
			fromMouse()
		end
	end)
	w:_conn(UserInputService.InputChanged, function(i)
		if dragging and (i.UserInputType == MOVE or i.UserInputType == TOUCH) then
			fromMouse()
		end
	end)
	w:_conn(UserInputService.InputEnded, function(i)
		if i.UserInputType == MB1 or i.UserInputType == TOUCH then
			dragging = false
			if not hovered then
				tween(outer, 0.12, { BackgroundColor3 = Theme.Border })
			end
		end
	end)
	w:_conn(outer.MouseEnter, function()
		hovered = true
		tween(outer, 0.12, { BackgroundColor3 = Theme.ControlHover })
	end)
	w:_conn(outer.MouseLeave, function()
		hovered = false
		if not dragging then
			tween(outer, 0.12, { BackgroundColor3 = Theme.Border })
		end
	end)

	w:_conn(input.Focused, function()
		tween(under, 0.12, { BackgroundColor3 = w.Accent, BackgroundTransparency = 0 })
	end)
	w:_conn(input.FocusLost, function()
		tween(under, 0.12, { BackgroundTransparency = 1 })
		local cleaned = input.Text:gsub("[^%d%.%-]", "")
		local n = tonumber(cleaned)
		if n then
			s:Set(n)
		end
		input.Text = fmt(s.Value)
	end)

	w:_accent(function(c)
		fill.BackgroundColor3 = c
		if input:IsFocused() then
			under.BackgroundColor3 = c
		end
	end)
	render(false)

	if s.Flag then
		Lib.Flags[s.Flag] = s
	end
	self:_register(s.Name, row)
	return s
end

function Container:AddDropdown(o)
	o = o or {}
	local w, ind, level = self.Window, self.Indent, self.Level
	local d = {
		Window = w,
		Name = o.Name or "Dropdown",
		Options = o.Options or {},
		Callback = o.Callback or function() end,
		Flag = o.Flag,
	}
	d.Value = o.Default or d.Options[1]

	local row = self:_row(42)
	label(row, {
		Text = d.Name,
		Position = UDim2.fromOffset(ind, 2),
		Size = UDim2.new(1, -ind, 0, 14),
		TextColor3 = Theme.TextDim,
	})
	local outer, mid, inner = box(row, Theme.Outline, Theme.ControlBorder, Theme.Control, "TextButton")
	outer.Position = UDim2.fromOffset(ind, 20)
	outer.Size = UDim2.new(1, -ind, 0, 20)
	local valueLbl = label(inner, {
		Text = tostring(d.Value or ""),
		Position = UDim2.fromOffset(7, 0),
		Size = UDim2.new(1, -26, 1, 0),
		TextColor3 = Theme.TextValue,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local chev, chevProp = icon(inner, "ChevronDown", 10, Theme.TextMuted)
	chev.AnchorPoint = Vector2.new(1, 0.5)
	chev.Position = UDim2.new(1, -6, 0.5, 0)

	local list = w:_popup(100)
	local open, hovered = false, false
	local rows = {}

	local function paintBorder()
		tween(mid, 0.12, {
			BackgroundColor3 = open and w.Accent or (hovered and Theme.ControlHover or Theme.ControlBorder),
		})
		tween(chev, 0.12, { [chevProp] = open and w.Accent or Theme.TextMuted })
	end

	local function build()
		for _, r in ipairs(rows) do
			r:Destroy()
		end
		table.clear(rows)
		for i, opt in ipairs(d.Options) do
			local sel = opt == d.Value
			local r = new("TextButton", {
				BackgroundColor3 = Theme.ItemHover,
				BackgroundTransparency = sel and 0 or 1,
				Position = UDim2.fromOffset(0, 2 + (i - 1) * 20),
				Size = UDim2.new(1, 0, 0, 20),
			}, list.Inner)
			local l = label(r, {
				Text = tostring(opt),
				Position = UDim2.fromOffset(7, 0),
				Size = UDim2.new(1, -14, 1, 0),
				TextColor3 = sel and w.Accent or Theme.TextNormal,
				TextTransparency = 1,
			})
			task.delay(0.02 * i, function()
				tween(l, 0.18, { TextTransparency = 0 })
			end)
			if not sel then
				r.MouseEnter:Connect(function()
					tween(r, 0.1, { BackgroundTransparency = 0 })
				end)
				r.MouseLeave:Connect(function()
					tween(r, 0.1, { BackgroundTransparency = 1 })
				end)
			end
			r.MouseButton1Click:Connect(function()
				d:Set(opt)
				w:_closePopups(level + 1)
			end)
			table.insert(rows, r)
		end
		list.Root.Size = UDim2.fromOffset(outer.AbsoluteSize.X, #d.Options * 20 + 4 + 4)
	end

	list.OnOpen = function()
		open = true
		paintBorder()
		tween(chev, 0.25, { Rotation = 180 })
		local full = list.Root.Size
		list.Root.Size = UDim2.fromOffset(full.X.Offset, 6)
		tween(list.Root, 0.22, { Size = full })
	end
	list.OnClose = function()
		open = false
		paintBorder()
		tween(chev, 0.25, { Rotation = 0 })
	end

	w:_conn(outer.MouseButton1Click, function()
		if not list.Open then
			build()
		end
		w:_togglePopup(list, outer, level + 1, false)
	end)
	w:_conn(outer.MouseEnter, function()
		hovered = true
		paintBorder()
	end)
	w:_conn(outer.MouseLeave, function()
		hovered = false
		paintBorder()
	end)
	w:_accent(function()
		if open then
			paintBorder()
		end
	end)

	function d:Set(v, silent)
		self.Value = v
		valueLbl.Text = v ~= nil and tostring(v) or "-"
		if not silent then
			task.spawn(self.Callback, v)
		end
	end
	function d:Get()
		return self.Value
	end
	function d:SetOptions(opts)
		self.Options = opts
		if not table.find(opts, self.Value) then
			self:Set(opts[1])
		end
	end
	function d:_save()
		return self.Value
	end
	function d:_load(v)
		if v ~= nil then
			self:Set(v)
		end
	end

	if d.Flag then
		Lib.Flags[d.Flag] = d
	end
	self:_register(d.Name, row)
	return d
end

local function makeButton(w, parent, name, callback)
	callback = callback or function() end
	local outer, mid, inner = box(parent, Theme.Outline, Theme.ControlBorder, Theme.Control, "TextButton")
	local l = label(inner, {
		Text = name or "Button",
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Theme.TextValue,
	})
	local hovered = false
	w:_conn(outer.MouseEnter, function()
		hovered = true
		tween(inner, 0.12, { BackgroundColor3 = Theme.ButtonHover })
		tween(mid, 0.12, { BackgroundColor3 = Theme.ControlHover })
	end)
	w:_conn(outer.MouseLeave, function()
		hovered = false
		tween(inner, 0.12, { BackgroundColor3 = Theme.Control })
		tween(mid, 0.12, { BackgroundColor3 = Theme.ControlBorder })
	end)
	w:_conn(outer.MouseButton1Click, function()
		mid.BackgroundColor3 = w.Accent
		l.TextColor3 = w.Accent
		tween(mid, 0.45, { BackgroundColor3 = hovered and Theme.ControlHover or Theme.ControlBorder })
		tween(l, 0.45, { TextColor3 = Theme.TextValue })
		task.spawn(callback)
	end)
	local api = {
		Button = outer,
		SetText = function(_, s)
			l.Text = s
		end,
		GetText = function()
			return l.Text
		end,
	}
	return outer, api
end

function Container:AddButton(o)
	o = o or {}
	local row = self:_row(26)
	local outer, api = makeButton(self.Window, row, o.Name, o.Callback)
	outer.Position = UDim2.fromOffset(self.Indent, 2)
	outer.Size = UDim2.new(1, -self.Indent, 0, 24)
	api.Row = row
	self:_register(o.Name, row)
	return api
end

function Container:AddButtons(list)
	local ind = self.Indent
	local row = self:_row(26)
	local holder = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(ind, 2),
		Size = UDim2.new(1, -ind, 0, 24),
	}, row)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}, holder)
	local n = #list
	local apis, names = {}, {}
	for i, b in ipairs(list) do
		local outer, api = makeButton(self.Window, holder, b.Name, b.Callback)
		outer.LayoutOrder = i
		outer.Size = UDim2.new(1 / n, -6 * (n - 1) / n, 1, 0)
		apis[i] = api
		table.insert(names, b.Name or "")
	end
	self:_register(table.concat(names, " "), row)
	return apis
end

function Container:AddTextbox(o)
	o = o or {}
	local w, ind = self.Window, self.Indent
	local tb = {
		Value = o.Default or "",
		Callback = o.Callback or function() end,
		Flag = o.Flag,
	}
	local hasLabel = o.Name ~= nil and o.Name ~= ""
	local row = self:_row(hasLabel and 42 or 24)
	local y = 2
	if hasLabel then
		label(row, {
			Text = o.Name,
			Position = UDim2.fromOffset(ind, 2),
			Size = UDim2.new(1, -ind, 0, 14),
			TextColor3 = Theme.TextDim,
		})
		y = 20
	end
	local outer, mid, inner = box(row, Theme.Outline, Theme.ControlBorder, Theme.Control)
	outer.Position = UDim2.fromOffset(ind, y)
	outer.Size = UDim2.new(1, -ind, 0, 20)
	inner.ClipsDescendants = true
	local input = new("TextBox", {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.TextValue,
		PlaceholderText = o.Placeholder or "",
		PlaceholderColor3 = Theme.TextFaint,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Text = tb.Value,
		Position = UDim2.fromOffset(7, 0),
		Size = UDim2.new(1, -14, 1, 0),
	}, inner)

	local hovered = false
	w:_conn(outer.MouseEnter, function()
		hovered = true
		if not input:IsFocused() then
			tween(mid, 0.12, { BackgroundColor3 = Theme.ControlHover })
		end
	end)
	w:_conn(outer.MouseLeave, function()
		hovered = false
		if not input:IsFocused() then
			tween(mid, 0.12, { BackgroundColor3 = Theme.ControlBorder })
		end
	end)
	w:_conn(input.Focused, function()
		tween(mid, 0.12, { BackgroundColor3 = w.Accent })
	end)
	w:_accent(function(col)
		if input:IsFocused() then
			mid.BackgroundColor3 = col
		end
	end)
	w:_conn(input.FocusLost, function(enter)
		tween(mid, 0.12, { BackgroundColor3 = hovered and Theme.ControlHover or Theme.ControlBorder })
		tb.Value = input.Text
		task.spawn(tb.Callback, tb.Value, enter)
	end)

	function tb:Set(v)
		input.Text = tostring(v or "")
		self.Value = input.Text
	end
	function tb:Get()
		return self.Value
	end
	function tb:_save()
		return self.Value
	end
	function tb:_load(v)
		self:Set(v)
	end
	if tb.Flag then
		Lib.Flags[tb.Flag] = tb
	end
	self:_register(o.Name, row)
	return tb
end

function Container:AddKeyPicker(o)
	o = o or {}
	local w, ind = self.Window, self.Indent
	local k = {
		Key = o.Default,
		Callback = o.Callback or function() end,
		Flag = o.Flag,
		AllowNone = o.AllowNone == true,
		Listening = false,
	}
	local row = self:_row(20)
	local l = label(row, {
		Text = o.Name or "Key",
		Position = UDim2.fromOffset(ind, 0),
		Size = UDim2.new(1, -ind - 60, 1, 0),
		TextColor3 = Theme.TextNormal,
	})
	local btn = new("TextButton", {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		TextSize = 12,
		TextColor3 = Theme.TextMuted,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(40, 20),
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)
	local hovered, pulse = false, nil

	local function refresh()
		btn.Text = k.Listening and "[...]" or ("[" .. keyName(k.Key) .. "]")
		btn.Size = UDim2.fromOffset(textWidth(btn.Text, 12, Theme.Font) + 4, 20)
		local c = k.Listening and w.Accent or (hovered and Theme.TextBright or Theme.TextMuted)
		tween(btn, 0.12, { TextColor3 = c })
		tween(l, 0.12, { TextColor3 = hovered and Theme.Text or Theme.TextNormal })
	end

	function k:_startListen()
		self._prev = self.Key
		self.Listening = true
		w._listening = self
		refresh()
		pulse = TweenService:Create(
			btn,
			TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ TextTransparency = 0.65 }
		)
		pulse:Play()
	end
	function k:_stopListen()
		self.Listening = false
		if w._listening == self then
			w._listening = nil
		end
		if pulse then
			pulse:Cancel()
			pulse = nil
		end
		btn.TextTransparency = 0
		self._stopTick = os.clock()
		if self.Key == nil and not self.AllowNone then
			self.Key = self._prev
		end
		refresh()
		if self.Key ~= self._prev then
			task.spawn(self.Callback, self.Key)
		end
	end
	function k:Set(key, silent)
		self.Key = key
		refresh()
		if not silent then
			task.spawn(self.Callback, key)
		end
	end
	function k:Get()
		return self.Key
	end
	function k:_save()
		return self.Key and tostring(self.Key) or false
	end
	function k:_load(d)
		local key = parseEnum(d)
		if not key and type(d) == "string" then
			pcall(function()
				key = Enum.KeyCode[d]
			end)
		end
		if key then
			self:Set(key)
		end
	end

	w:_conn(btn.MouseEnter, function()
		hovered = true
		refresh()
	end)
	w:_conn(btn.MouseLeave, function()
		hovered = false
		refresh()
	end)
	w:_conn(btn.MouseButton1Click, function()
		if k._stopTick and os.clock() - k._stopTick < 0.3 then
			return
		end
		if k.Listening then
			k:_stopListen()
		else
			if w._listening then
				w._listening:_stopListen()
			end
			w:_closePopups(1)
			k:_startListen()
		end
	end)
	w:_accent(function()
		if k.Listening then
			refresh()
		end
	end)
	refresh()

	if k.Flag then
		Lib.Flags[k.Flag] = k
	end
	self:_register(o.Name, row)
	return k
end

function Container:AddColor(o)
	o = o or {}
	local w, ind, level = self.Window, self.Indent, self.Level
	local row = self:_row(20)
	local hit = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, row)
	local l = label(row, {
		Text = o.Name or "Color",
		Position = UDim2.fromOffset(ind, 0),
		Size = UDim2.new(1, -ind - 24, 1, 0),
		TextColor3 = Theme.TextNormal,
	})
	local c, swatch = colorSwatch(w, row, o)
	swatch.AnchorPoint = Vector2.new(1, 0.5)
	swatch.Position = UDim2.new(1, 0, 0.5, 0)
	local function open()
		w:_togglePopup(c.Picker.Popup, row, level + 1, true)
	end
	w:_conn(hit.MouseButton1Click, open)
	w:_conn(swatch.MouseButton1Click, open)
	w:_conn(hit.MouseEnter, function()
		tween(l, 0.12, { TextColor3 = Theme.Text })
	end)
	w:_conn(hit.MouseLeave, function()
		tween(l, 0.12, { TextColor3 = Theme.TextNormal })
	end)
	self:_register(o.Name, row)
	return c
end
Container.AddColorpicker = Container.AddColor

function Container:AddLabel(text)
	local row = self:_row(16)
	local l = label(row, {
		Text = text or "",
		Position = UDim2.fromOffset(self.Indent, 0),
		Size = UDim2.new(1, -self.Indent, 1, 0),
		TextColor3 = Theme.TextMuted,
		TextWrapped = true,
	})
	self:_register(text, row)
	return {
		SetText = function(_, s)
			l.Text = s
		end,
	}
end

function Tab:AddGroup(title, side)
	local w = self.Window
	local col = (side == "Right" or side == 2) and self._right or self._left
	self._gcount += 1

	local g = new("Frame", {
		BackgroundColor3 = Theme.Group,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._gcount,
	}, col)
	new("UIStroke", { Color = Theme.GroupBorder, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, g)

	local t = label(g, {
		Text = title,
		FontFace = Theme.FontBold,
		TextColor3 = Theme.TextTitle,
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Window,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 14),
		Position = UDim2.fromOffset(10, -7),
		ZIndex = 2,
	})
	new("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, t)

	local content = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, g)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 9),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 8),
	}, content)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, content)

	local c = newContainer(w, self, content, 19, 0)
	c.Title = title
	c.Box = g
	c.GroupRef = c
	table.insert(self.Groups, c)
	return c
end
Tab.AddSection = Tab.AddGroup

function Window:_layoutTop(animate)
	local W = self._size.X - 4
	local total = 0
	for _, t in ipairs(self.Tabs) do
		total += t._w
	end
	local x
	if self.TabsSide == "Right" then
		self._searchBox.AnchorPoint = Vector2.new(0, 0.5)
		x = W - 8 - total
	else
		self._searchBox.AnchorPoint = Vector2.new(0, 0.5)
		x = self._logoEnd + 2
	end

	local searchX = self.TabsSide == "Right" and (self._logoEnd + 8) or (W - 8 - 130)
	local function place(obj, pos)
		if animate then
			tween(obj, 0.3, { Position = pos })
		else
			obj.Position = pos
		end
	end
	place(self._searchBox, UDim2.new(0, searchX, 0.5, 0))
	for _, t in ipairs(self.Tabs) do
		t._x = x
		place(t.Button, UDim2.fromOffset(x, 0))
		x += t._w
	end
	if self.ActiveTab then
		place(self._indicator, UDim2.fromOffset(self.ActiveTab._x, 33))
		self._indicator.Size = UDim2.fromOffset(self.ActiveTab._w, 2)
	end
end

function Window:SetTabsSide(side)
	self.TabsSide = side == "Right" and "Right" or "Left"
	self:_layoutTop(true)
end

Lib.MinSize = Vector2.new(480, 340)
Lib.MaxSize = Vector2.new(900, 680)

function Window:_screen()
	local a = self._gui and self._gui.AbsoluteSize
	if a and a.X > 0 then
		return a
	end
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1920, 1080)
end

function Window:SetSize(v)
	local scale = self._baseScale or 1
	local screen = self:_screen()

	local fitX = math.floor((screen.X - 40) / scale)
	local fitY = math.floor((screen.Y - 40) / scale)
	local maxX = math.min(Lib.MaxSize.X, fitX)
	local maxY = math.min(Lib.MaxSize.Y, fitY)
	local minX = math.min(Lib.MinSize.X, maxX)
	local minY = math.min(Lib.MinSize.Y, maxY)
	v = Vector2.new(math.clamp(math.floor(v.X), minX, maxX), math.clamp(math.floor(v.Y), minY, maxY))
	self._size = v
	self._root.Size = UDim2.fromOffset(v.X, v.Y)
	self:_closePopups(1)
	self:_layoutTop()
end

function Window:_clampToScreen(animate)
	local root = self._root
	local screen = self:_screen()
	local half = self._size * (self._baseScale or 1) / 2
	local p = root.Position
	local cx = p.X.Scale * screen.X + p.X.Offset
	local cy = p.Y.Scale * screen.Y + p.Y.Offset
	cx = math.clamp(cx, half.X, math.max(half.X, screen.X - half.X))
	cy = math.clamp(cy, half.Y, math.max(half.Y, screen.Y - half.Y))
	local target = UDim2.fromOffset(cx, cy)
	if animate then
		tween(root, 0.25, { Position = target })
	else
		root.Position = target
	end
end

function Window:AddTab(name)
	local tab = setmetatable({
		Window = self,
		Name = name,
		Groups = {},
		_search = {},
		_gcount = 0,
	}, Tab)
	tab._w = textWidth(name, 13, Theme.FontBold) + 18

	local btn = new("TextButton", {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		TextSize = 13,
		TextColor3 = Theme.TextMuted,
		Text = name,
		Size = UDim2.fromOffset(tab._w, 35),
		ZIndex = 2,
	}, self._top)
	tab.Button = btn

	local page = new("CanvasGroup", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		GroupTransparency = 1,
	}, self._pages)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.ControlHover,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, page)

	local holder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, scroll)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 17),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
	}, holder)
	local function column(xs, xo)
		local c = new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(xs, xo, 0, 0),
			Size = UDim2.new(0.5, -4, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, holder)
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 16) }, c)
		return c
	end
	tab._left = column(0, 0)
	tab._right = column(0.5, 4)
	tab.Page, tab.Scroll = page, scroll

	self:_conn(scroll:GetPropertyChangedSignal("CanvasPosition"), function()
		self:_closePopups(1)
	end)
	self:_conn(btn.MouseEnter, function()
		if self.ActiveTab ~= tab then
			tween(btn, 0.15, { TextColor3 = Theme.TextTitle })
		end
	end)
	self:_conn(btn.MouseLeave, function()
		if self.ActiveTab ~= tab then
			tween(btn, 0.15, { TextColor3 = Theme.TextMuted })
		end
	end)
	self:_conn(btn.MouseButton1Click, function()
		self:SelectTab(tab)
	end)

	table.insert(self.Tabs, tab)
	self:_layoutTop()
	if not self.ActiveTab then
		self:SelectTab(tab, true)
	end
	return tab
end

function Window:SelectTab(tab, instant)
	if self.ActiveTab == tab then
		return
	end
	local old = self.ActiveTab
	self.ActiveTab = tab
	self:_closePopups(1)

	for _, t in ipairs(self.Tabs) do
		local active = t == tab
		t.Button.FontFace = active and Theme.FontBold or Theme.Font
		tween(t.Button, 0.2, { TextColor3 = active and Theme.TextBright or Theme.TextMuted })
	end

	local pos, size = UDim2.fromOffset(tab._x, 33), UDim2.fromOffset(tab._w, 2)
	if instant then
		self._indicator.Position, self._indicator.Size = pos, size
	else
		tween(self._indicator, 0.3, { Position = pos, Size = size })
	end

	if old then
		local op = old.Page
		local t = tween(op, 0.1, { GroupTransparency = 1 })
		t.Completed:Connect(function()
			if self.ActiveTab ~= old then
				op.Visible = false
			end
		end)
	end
	local p = tab.Page
	p.Visible = true
	if instant then
		p.GroupTransparency = 0
		p.Position = UDim2.new()
	else
		p.GroupTransparency = 1
		p.Position = UDim2.fromOffset(0, 8)
		tween(p, 0.25, { GroupTransparency = 0, Position = UDim2.new() })
	end
	self:_applySearch()
end

function Window:_applySearch()
	local tab = self.ActiveTab
	if not tab then
		return
	end
	local q = string.lower(self._search.Text or "")
	local groupVis = {}
	for _, e in ipairs(tab._search) do
		local vis = q == "" or e.Name:find(q, 1, true) ~= nil
		e.Row.Visible = vis
		if e.Group then
			groupVis[e.Group] = groupVis[e.Group] or vis
		end
	end
	for _, g in ipairs(tab.Groups) do
		g.Box.Visible = q == "" or groupVis[g] == true
	end
end

function Window:_buildWatermark()
	local outer, _, inner = box(self._gui, Theme.Outline, Theme.Border, Theme.Window)
	outer.Position = UDim2.fromOffset(16, 16)
	outer.Size = UDim2.fromOffset(160, 29)
	outer.ZIndex = 2
	self._wm = outer

	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = self.Accent }, inner)
	local text = label(inner, {
		RichText = true,
		Position = UDim2.fromOffset(10, 2),
		Size = UDim2.new(1, -20, 1, -2),
		TextColor3 = Theme.TextValue,
	})

	local fps = 60
	local function render()
		local acc = "#" .. self.Accent:ToHex()
		local sep = '  <font color="' .. Theme.Separator .. '">|</font>  '
		text.Text = '<font color="' .. acc .. '"><b>' .. escapeRich(self.Name) .. "</b></font>"
			.. sep .. escapeRich(LocalPlayer and LocalPlayer.Name or "user")
			.. sep .. fps .. " fps"
	end
	self:_conn(text:GetPropertyChangedSignal("TextBounds"), function()
		outer.Size = UDim2.fromOffset(text.TextBounds.X + 24, 29)
	end)

	local frames, last = 0, os.clock()
	self:_conn(RunService.RenderStepped, function()
		frames += 1
		local now = os.clock()
		if now - last >= 1 then
			fps = math.floor(frames / (now - last) + 0.5)
			frames, last = 0, now
			render()
		end
	end)

	self:_accent(function(c)
		bar.BackgroundColor3 = c
		render()
	end)
	self:_draggable(outer, outer)
end

function Window:_buildKeybinds()
	local outer, _, inner = box(self._gui, Theme.Outline, Theme.Border, Theme.Window)
	outer.AnchorPoint = Vector2.new(1, 0)
	outer.Position = UDim2.new(1, -16, 0, 200)
	outer.Size = UDim2.fromOffset(196, 59)
	outer.ClipsDescendants = true
	outer.ZIndex = 2
	self._kbOuter = outer

	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = self.Accent }, inner)
	label(inner, {
		Text = "Keybinds",
		FontFace = Theme.FontBold,
		TextColor3 = Theme.TextTitle,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.new(1, 0, 0, 24),
	})
	new("Frame", {
		BackgroundColor3 = Theme.DividerSoft,
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 1),
	}, inner)
	self._kbList = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 33),
		Size = UDim2.new(1, -20, 1, -33),
	}, inner)
	self._kbEmpty = label(self._kbList, {
		Text = "no binds",
		TextColor3 = Theme.TextFaint,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 14),
	})

	self:_accent(function(c)
		bar.BackgroundColor3 = c
		self:_refreshKeybinds()
	end)
	self:_draggable(outer, outer)
end

local BIND_STATUS = { Hold = "held", Toggle = "toggled", Always = "always" }
local BIND_HINT = { Hold = "hold", Toggle = "toggle", Always = "always" }

function Window:_refreshKeybinds()
	if not self._kbList then
		return
	end

	local list = {}
	for _, b in ipairs(self._binds) do
		if b.ShowInList and (b.Key ~= nil or b.Mode == "Always") then
			table.insert(list, b)
		end
	end

	local present = {}
	for i, b in ipairs(list) do
		present[b] = true
		local y = (i - 1) * 18
		local active = b.Toggle.Value and b.Active
		local r = self._kbRows[b]
		if not r then
			local f = new("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(-8, y),
				Size = UDim2.new(1, 0, 0, 14),
			}, self._kbList)
			r = {
				Frame = f,
				Left = label(f, { Size = UDim2.fromScale(1, 1), TextColor3 = Theme.TextFaint, TextTransparency = 1 }),
				Right = label(f, {
					Size = UDim2.fromScale(1, 1),
					TextColor3 = Theme.TextFaint,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextTransparency = 1,
				}),
			}
			self._kbRows[b] = r
			tween(f, 0.25, { Position = UDim2.fromOffset(0, y) })
			tween(r.Left, 0.25, { TextTransparency = 0 })
			tween(r.Right, 0.25, { TextTransparency = 0 })
		else
			tween(r.Frame, 0.2, { Position = UDim2.fromOffset(0, y) })
		end
		r.Left.Text = b.Toggle.ListName
		r.Right.Text = "[" .. keyName(b.Key) .. "] " .. (active and BIND_STATUS[b.Mode] or BIND_HINT[b.Mode])
		tween(r.Left, 0.18, { TextColor3 = active and Theme.TextValue or Theme.TextFaint })
		tween(r.Right, 0.18, { TextColor3 = active and self.Accent or Theme.TextFaint })
	end

	for b, r in pairs(self._kbRows) do
		if not present[b] then
			self._kbRows[b] = nil
			tween(r.Left, 0.15, { TextTransparency = 1 })
			local t = tween(r.Right, 0.15, { TextTransparency = 1 })
			t.Completed:Connect(function()
				r.Frame:Destroy()
			end)
		end
	end

	tween(self._kbEmpty, 0.15, { TextTransparency = #list == 0 and 0 or 1 })
	local n = math.max(#list, 1)
	tween(self._kbOuter, 0.22, { Size = UDim2.fromOffset(196, 33 + n * 18 - 4 + 8 + 4) })
end

function Window:SetOpen(v)
	self.Open = v
	self:_closePopups(1)
	if self._listening then
		self._listening:_stopListen()
	end
	local root = self._root
	if v then
		root.Visible = true
		self._modal.Visible = true
		root.GroupTransparency = 1
		self._uiScale.Scale = self._baseScale * 0.96
		tween(root, 0.22, { GroupTransparency = 0 })
		tween(self._uiScale, 0.3, { Scale = self._baseScale }, Enum.EasingStyle.Back)
	else
		self._modal.Visible = false
		tween(self._uiScale, 0.16, { Scale = self._baseScale * 0.96 })
		local t = tween(root, 0.16, { GroupTransparency = 1 })
		t.Completed:Connect(function()
			if not self.Open then
				root.Visible = false
			end
		end)
	end
end

function Window:Toggle()
	self:SetOpen(not self.Open)
end

function Window:SetWatermarkVisible(v)
	self._wm.Visible = v
end

function Window:SetKeybindListVisible(v)
	self._kbOuter.Visible = v
end

function Window:SetScale(s)
	self._baseScale = s
	if self.Open then
		self._uiScale.Scale = s
	end

	self:SetSize(self._size)
	self:_clampToScreen(true)
end

function Window:Destroy()
	for _, c in ipairs(self._conns) do
		c:Disconnect()
	end
	table.clear(self._conns)
	self._gui:Destroy()
	table.clear(Lib.Flags)
end
Window.Unload = Window.Destroy

function Window:AddSettingsTab(name)
	local tab = self:AddTab(name or "Settings")

	local menu = tab:AddGroup("Menu", "Left")
	menu:AddKeyPicker({
		Name = "Menu key",
		Default = self.MenuKey,
		Flag = "__menukey",
		Callback = function(k)
			self.MenuKey = k
		end,
	})
	menu:AddDropdown({
		Name = "Tabs side",
		Options = { "Left", "Right" },
		Default = self.TabsSide,
		Flag = "__tabs",
		Callback = function(v)
			self:SetTabsSide(v)
		end,
	})
	menu:AddToggle({
		Name = "Watermark",
		Default = true,
		Flag = "__watermark",
		Callback = function(v)
			self:SetWatermarkVisible(v)
		end,
	})
	menu:AddToggle({
		Name = "Keybind list",
		Default = true,
		Flag = "__keybinds",
		Callback = function(v)
			self:SetKeybindListVisible(v)
		end,
	})
	menu:AddColor({
		Name = "Accent color",
		Default = self.Accent,
		Flag = "__accent",
		Callback = function(c)
			self:SetAccent(c)
		end,
	})
	menu:AddSlider({
		Name = "UI scale",
		Min = 75,
		Max = 150,
		Default = 100,
		Suffix = "%",
		Flag = "__scale",
		Callback = function(v)
			self:SetScale(v / 100)
		end,
	})

	local cfg = tab:AddGroup("Configs", "Right")
	local nameBox = cfg:AddTextbox({ Name = "Config name", Placeholder = "new config..." })
	local list = cfg:AddDropdown({ Name = "Configs", Options = Lib:ListConfigs() })
	local autoLbl

	local function refresh(select)
		list:SetOptions(Lib:ListConfigs())
		if select then
			list:Set(select, true)
		end
		local a = Lib:GetAutoload()
		autoLbl:SetText("autoload: " .. (a or "none"))
	end

	local function notify(_, text)
		self:Notify("Configs", text, 3)
	end

	cfg:AddButtons({
		{
			Name = "Create",
			Callback = function()
				local ok, res = Lib:SaveConfig(nameBox.Value)
				if ok then
					nameBox:Set("")
					refresh(res)
					notify(true, "created " .. res)
				else
					notify(false, res)
				end
			end,
		},
		{
			Name = "Save",
			Callback = function()
				if not list.Value then
					return notify(false, "select or create a config first")
				end
				local ok, res = Lib:SaveConfig(list.Value)
				notify(ok, ok and ("saved " .. res) or res)
			end,
		},
	})

	local deleteArmed = false
	local btns
	btns = cfg:AddButtons({
		{
			Name = "Load",
			Callback = function()
				if not list.Value then
					return notify(false, "no config selected")
				end
				local ok, res = Lib:LoadConfig(list.Value)
				notify(ok, ok and ("loaded " .. list.Value) or res)
			end,
		},
		{
			Name = "Delete",
			Callback = function()
				if not list.Value then
					return notify(false, "no config selected")
				end

				if not deleteArmed then
					deleteArmed = true
					btns[2]:SetText("Sure?")
					task.delay(2, function()
						if deleteArmed then
							deleteArmed = false
							btns[2]:SetText("Delete")
						end
					end)
					return
				end
				deleteArmed = false
				btns[2]:SetText("Delete")
				local name = list.Value
				local ok, res = Lib:DeleteConfig(name)
				refresh()
				notify(ok, ok and ("deleted " .. name) or res)
			end,
		},
	})

	cfg:AddButtons({
		{
			Name = "Autoload",
			Callback = function()
				if not list.Value then
					return notify(false, "no config selected")
				end
				if Lib:GetAutoload() == list.Value then
					Lib:SetAutoload(nil)
					notify(true, "autoload disabled")
				else
					local ok, res = Lib:SetAutoload(list.Value)
					notify(ok, ok and ("autoload: " .. list.Value) or res)
				end
				refresh()
			end,
		},
		{
			Name = "Refresh",
			Callback = function()
				refresh()
			end,
		},
	})
	autoLbl = cfg:AddLabel("autoload: none")
	refresh(Lib:GetAutoload())

	task.defer(function()
		local a = Lib:GetAutoload()
		if a then
			local ok = Lib:LoadConfig(a)
			if ok then
				notify(true, "autoloaded " .. a)
			end
		end
	end)
	return tab
end

function Window:Notify(title, text, duration)
	duration = duration or 3
	self._toastN += 1
	local h = (text and text ~= "") and 48 or 32
	local holder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(240, h),
		LayoutOrder = self._toastN,
	}, self._toasts)
	local outer, _, inner = box(holder, Theme.Outline, Theme.Border, Theme.Window, "CanvasGroup")
	outer.Size = UDim2.fromScale(1, 1)
	outer.Position = UDim2.fromOffset(30, 0)
	outer.GroupTransparency = 1
	local col = self.Accent
	new("Frame", { BackgroundColor3 = col, Size = UDim2.new(1, 0, 0, 2) }, inner)
	label(inner, {
		Text = title or "",
		FontFace = Theme.FontBold,
		TextColor3 = Theme.TextTitle,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -20, 0, 16),
	})
	if text and text ~= "" then
		label(inner, {
			Text = text,
			TextColor3 = Theme.TextDim,
			Position = UDim2.fromOffset(10, 23),
			Size = UDim2.new(1, -20, 0, 16),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end
	local progress = new("Frame", {
		BackgroundColor3 = col,
		BackgroundTransparency = 0.4,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
	}, inner)

	tween(outer, 0.3, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 })
	tween(progress, duration, { Size = UDim2.new(0, 0, 0, 1) }, Enum.EasingStyle.Linear)
	task.delay(duration, function()
		local t = tween(outer, 0.25, { Position = UDim2.fromOffset(30, 0), GroupTransparency = 1 })
		t.Completed:Wait()
		tween(holder, 0.2, { Size = UDim2.fromOffset(240, 0) }).Completed:Wait()
		holder:Destroy()
	end)
end

function Lib:Notify(title, text, duration)
	if Lib._window then
		Lib._window:Notify(title, text, duration)
	end
end

function Lib:CreateWindow(o)
	o = o or {}
	if o.ConfigFolder then

		local parts = {}
		for part in string.gmatch(tostring(o.ConfigFolder), "[^/\\]+") do
			if part ~= "." and part ~= ".." then
				table.insert(parts, part)
			end
		end
		if #parts > 0 then
			Lib.ConfigFolder = table.concat(parts, "/")
		end
	end
	if o.Font then
		setFont(o.Font)
	end
	local self = setmetatable({}, Window)
	self.Name = o.Name or "your.lib"
	self.Title = o.Title or "LIB"
	self.Accent = o.Accent or Theme.Accent
	self.MenuKey = o.MenuKey or Enum.KeyCode.RightShift
	self.TabsSide = o.TabsSide or "Left"
	self._size = o.Size or Vector2.new(600, 500)
	self.Tabs = {}
	self._accentHooks = {}
	self._conns = {}
	self._popups = {}
	self._binds = {}
	self._kbRows = {}
	self._baseScale = 1
	self.Open = true

	local gui = new("ScreenGui", {
		Name = "yourlib_" .. HttpService:GenerateGUID(false):sub(1, 8),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
	})
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.None
	end)
	local parented = false
	if gethui then
		parented = pcall(function()
			gui.Parent = gethui()
		end)
	end
	if not parented then
		parented = pcall(function()
			gui.Parent = game:GetService("CoreGui")
		end)
	end
	if not parented then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	self._gui = gui

	local root = new("CanvasGroup", {
		BackgroundColor3 = Theme.Outline,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(self._size.X, self._size.Y),
		ZIndex = 1,
	}, gui)
	self._root = root
	self._uiScale = new("UIScale", {}, root)
	local border = new("Frame", {
		BackgroundColor3 = Theme.Border,
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
	}, root)
	local main = new("Frame", {
		BackgroundColor3 = Theme.Window,
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
	}, border)

	local topLine = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = self.Accent }, main)

	local top = new("Frame", {
		BackgroundColor3 = Theme.Bar,
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.new(1, 0, 0, 36),
	}, main)
	self._top = top
	new("Frame", {
		BackgroundColor3 = Theme.Divider,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
	}, top)

	local logoW = textWidth(self.Title, 14, Theme.FontBold)
	local logo = label(top, {
		Text = self.Title,
		FontFace = Theme.FontBold,
		TextSize = 14,
		TextColor3 = self.Accent,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0, logoW, 1, -1),
	})
	new("Frame", {
		BackgroundColor3 = Theme.Divider,
		Position = UDim2.fromOffset(12 + logoW + 12, 0),
		Size = UDim2.new(0, 1, 1, -1),
	}, top)
	self._logoEnd = 12 + logoW + 12 + 1

	self._indicator = new("Frame", {
		BackgroundColor3 = self.Accent,
		Size = UDim2.fromOffset(0, 2),
		Position = UDim2.fromOffset(0, 33),
		ZIndex = 3,
	}, top)

	local sBorder = new("Frame", {
		BackgroundColor3 = Theme.GroupBorder,
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.fromOffset(130, 22),
		ZIndex = 2,
		Active = true,
	}, top)
	local sInner = new("Frame", {
		BackgroundColor3 = Theme.Popup,
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
	}, sBorder)
	local sIcon, sProp = icon(sInner, "Search", 12, Theme.TextFaint)
	sIcon.AnchorPoint = Vector2.new(0, 0.5)
	sIcon.Position = UDim2.new(0, 7, 0.5, 0)
	local search = new("TextBox", {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		TextSize = Theme.TextSize,
		TextColor3 = Theme.TextValue,
		PlaceholderText = "Search",
		PlaceholderColor3 = Theme.TextFaint,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Position = UDim2.fromOffset(24, 0),
		Size = UDim2.new(1, -30, 1, 0),
	}, sInner)
	self._search, self._searchBox = search, sBorder
	self:_conn(search.Focused, function()
		tween(sBorder, 0.15, { BackgroundColor3 = self.Accent })
		tween(sIcon, 0.15, { [sProp] = self.Accent })
	end)
	self:_conn(search.FocusLost, function()
		tween(sBorder, 0.15, { BackgroundColor3 = Theme.GroupBorder })
		tween(sIcon, 0.15, { [sProp] = Theme.TextFaint })
	end)
	self:_conn(search:GetPropertyChangedSignal("Text"), function()
		self:_applySearch()
	end)

	self._pages = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, 0, 1, -38),
		ClipsDescendants = true,
	}, main)

	self._modal = new("TextButton", {
		Modal = true,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 0),
	}, main)

	self._overlay = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
	}, gui)
	Lib._window = self

	self._toasts = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(250, 400),
		ZIndex = 11,
	}, gui)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
	}, self._toasts)
	self._toastN = 0

	self:_draggable(top, root)

	local grip = new("TextButton", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 20,
	}, main)
	local gripDots = {}
	for i, off in ipairs({ { 9, 3 }, { 9, 6 }, { 9, 9 }, { 6, 6 }, { 6, 9 }, { 3, 9 } }) do
		gripDots[i] = new("Frame", {
			BackgroundColor3 = Theme.ControlHover,
			Position = UDim2.fromOffset(off[1], off[2]),
			Size = UDim2.fromOffset(2, 2),
			ZIndex = 21,
		}, grip)
	end
	local resizing, rsMouse, rsSize, rsPos = false, nil, nil, nil
	local gripHover = false
	local function paintGrip()
		local c = (resizing or gripHover) and self.Accent or Theme.ControlHover
		for _, d in ipairs(gripDots) do
			tween(d, 0.12, { BackgroundColor3 = c })
		end
	end
	self:_conn(grip.MouseEnter, function()
		gripHover = true
		paintGrip()
	end)
	self:_conn(grip.MouseLeave, function()
		gripHover = false
		paintGrip()
	end)
	self:_conn(grip.MouseButton1Down, function()
		resizing, rsMouse, rsSize, rsPos = true, mouse(), self._size, root.Position
		self:_closePopups(1)
		paintGrip()
	end)
	self:_conn(UserInputService.InputChanged, function(input)
		if resizing and (input.UserInputType == MOVE or input.UserInputType == TOUCH) then
			local scale = self._uiScale.Scale
			local d = (mouse() - rsMouse) / scale
			self:SetSize(rsSize + d)

			local grow = (self._size - rsSize) * scale / 2
			root.Position = UDim2.new(rsPos.X.Scale, rsPos.X.Offset + grow.X, rsPos.Y.Scale, rsPos.Y.Offset + grow.Y)
		end
	end)
	self:_conn(UserInputService.InputEnded, function(input)
		if resizing and (input.UserInputType == MB1 or input.UserInputType == TOUCH) then
			resizing = false
			paintGrip()
			self:_clampToScreen(true)
		end
	end)
	self:_accent(function()
		if resizing or gripHover then
			paintGrip()
		end
	end)
	self:_buildWatermark()
	self:_buildKeybinds()

	self:_accent(function(c)
		topLine.BackgroundColor3 = c
		logo.TextColor3 = c
		self._indicator.BackgroundColor3 = c
		if search:IsFocused() then
			sBorder.BackgroundColor3 = c
		end
	end)

	self:_conn(UserInputService.InputBegan, function(input)
		local t = input.UserInputType
		if t == MB1 or t == MB2 or t == TOUCH then
			self:_clickAway()
		end
		if self._listening then
			self:_captureBind(input)
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		local key = t == Enum.UserInputType.Keyboard and input.KeyCode or t
		if self.MenuKey and key == self.MenuKey then
			self:Toggle()
			return
		end
		self:_bindInput(input, true)
	end)
	self:_conn(UserInputService.InputEnded, function(input)
		self:_bindInput(input, false)
	end)

	local function packUDim2(u)
		return { u.X.Scale, u.X.Offset, u.Y.Scale, u.Y.Offset }
	end
	local function unpackUDim2(t)
		if type(t) ~= "table" or #t < 4 then
			return nil
		end
		return UDim2.new(t[1], t[2], t[3], t[4])
	end
	Lib.Flags.__layout = {
		_save = function()
			return {
				window = packUDim2(root.Position),
				size = { self._size.X, self._size.Y },
				watermark = packUDim2(self._wm.Position),
				keybinds = packUDim2(self._kbOuter.Position),
			}
		end,
		_load = function(_, d)
			if type(d) ~= "table" then
				return
			end
			if type(d.size) == "table" and d.size[1] and d.size[2] then
				self:SetSize(Vector2.new(d.size[1], d.size[2]))
			end
			local wp, mp, kp = unpackUDim2(d.window), unpackUDim2(d.watermark), unpackUDim2(d.keybinds)
			if wp then
				root.Position = wp
				self:_clampToScreen()
			end
			if mp then
				tween(self._wm, 0.3, { Position = mp })
			end
			if kp then
				tween(self._kbOuter, 0.3, { Position = kp })
			end
		end,
	}

	self:_layoutTop()
	self:SetOpen(true)
	return self
end

local function canFS()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local ensureFolder = ensurePath

local function configDir()
	ensureFolder(Lib.ConfigFolder)
	local d = Lib.ConfigFolder .. "/configs"
	ensureFolder(d)
	return d
end

local function cleanName(name)
	name = tostring(name or "")
	name = name:gsub("^%s+", "")
	name = name:gsub("%s+$", "")
	if name == "" then
		return nil, "enter a config name"
	end
	if name:find('[/\\:%*%?"<>|]') then
		return nil, "name cannot contain / \\ : * ? \" < > |"
	end
	return name
end

function Lib:ListConfigs()
	local out = {}
	if not canFS() or typeof(listfiles) ~= "function" then
		return out
	end
	local ok, files = pcall(listfiles, configDir())
	if ok then
		for _, f in ipairs(files) do
			local n = f:match("([^/\\]+)%.json$")
			if n then
				table.insert(out, n)
			end
		end
	end
	table.sort(out, function(a, b)
		return a:lower() < b:lower()
	end)
	return out
end

function Lib:SaveConfig(name)
	if not canFS() then
		return false, "writefile is not available"
	end
	local n, err = cleanName(name)
	if not n then
		return false, err
	end
	local data = {}
	for flag, obj in pairs(Lib.Flags) do
		if obj._save then
			local ok, v = pcall(obj._save, obj)
			if ok then
				data[flag] = v
			end
		end
	end
	local ok, e = pcall(writefile, configDir() .. "/" .. n .. ".json", HttpService:JSONEncode(data))
	if not ok then
		return false, tostring(e)
	end
	return true, n
end

function Lib:LoadConfig(name)
	if not canFS() then
		return false, "readfile is not available"
	end
	local n, err = cleanName(name)
	if not n then
		return false, err
	end
	local path = configDir() .. "/" .. n .. ".json"
	if not isfile(path) then
		return false, "no config named " .. n
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok or type(data) ~= "table" then
		return false, "config is corrupted"
	end
	for flag, val in pairs(data) do
		local obj = Lib.Flags[flag]
		if obj and obj._load then
			pcall(obj._load, obj, val)
		end
	end
	return true, n
end

function Lib:DeleteConfig(name)
	if not canFS() or typeof(delfile) ~= "function" then
		return false, "delfile is not available"
	end
	local n, err = cleanName(name)
	if not n then
		return false, err
	end
	local path = configDir() .. "/" .. n .. ".json"
	if not isfile(path) then
		return false, "no config named " .. n
	end
	delfile(path)
	if Lib:GetAutoload() == n then
		Lib:SetAutoload(nil)
	end
	return true, n
end

function Lib:GetAutoload()
	if not canFS() then
		return nil
	end
	local path = Lib.ConfigFolder .. "/autoload.txt"
	if not isfile(path) then
		return nil
	end
	local ok, n = pcall(readfile, path)
	if not ok or n == "" then
		return nil
	end
	if not isfile(configDir() .. "/" .. n .. ".json") then
		return nil
	end
	return n
end

function Lib:SetAutoload(name)
	if not canFS() then
		return false, "writefile is not available"
	end
	ensureFolder(Lib.ConfigFolder)
	local path = Lib.ConfigFolder .. "/autoload.txt"
	if name == nil then
		if typeof(delfile) == "function" and isfile(path) then
			delfile(path)
		else
			writefile(path, "")
		end
		return true
	end
	local n, err = cleanName(name)
	if not n then
		return false, err
	end
	writefile(path, n)
	return true, n
end

return Lib
