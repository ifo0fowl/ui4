local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Library = {}
Library.UI_VERSION = "settings-tab-4"

local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Icon)
	if type(Icon) == "number" then return "rbxassetid://" .. Icon end
	if type(Icon) == "string" then
		if string.find(Icon, "://", 1, true) then return Icon end
		if string.match(Icon, "^%d+$") then return "rbxassetid://" .. Icon end
		local Name = string.lower(Icon)
		if type(Lucide) == "function" then
			local ok, Data = pcall(Lucide, Name)
			if ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Name]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
	end
	return "rbxassetid://0"
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Icon)
	if not Icon then return end
	local Image, Offset, Size = ResolveIcon(Icon)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local function IsCustomAsset(Value)
	if type(Value) == "number" then return true end
	if type(Value) == "string" then
		if string.find(Value, "://", 1, true) then return true end
		if string.match(Value, "^%d+$") then return true end
	end
	return false
end

local C = {
	Box = Color3.fromRGB(10, 8, 16),
	Line = Color3.fromRGB(93, 44, 168),
	Off = Color3.fromRGB(125, 115, 145),
	On = Color3.fromRGB(255, 255, 255),
	BoxStroke = Color3.fromRGB(60, 30, 110),
}
local DIM = Color3.fromRGB(130, 120, 150)
local FONT = Enum.Font.GothamMedium
local WHITE = Color3.new(1, 1, 1)
local MB1, TOUCH = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch
local DESIGN_W, DESIGN_H = 973, 840

local function New(Class, Props, Parent)
	local o = Instance.new(Class)
	for k, v in pairs(Props) do o[k] = v end
	o.Parent = Parent
	return o
end
local function Corner(o, r) return New("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function Stroke(o, col, t, tr)
	return New("UIStroke", { Color = col, Thickness = t or 1, Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function Grad(o, c0, c1, rot, mid)
	local seq = mid and ColorSequence.new({ ColorSequenceKeypoint.new(0, c0), ColorSequenceKeypoint.new(0.5, mid),
		ColorSequenceKeypoint.new(1, c1) }) or ColorSequence.new(c0, c1)
	return New("UIGradient", { Color = seq, Rotation = rot or 0 }, o)
end
local function Text(parent, txt, x, cy, w, size, col, align)
	return New("TextLabel", {
		BackgroundTransparency = 1, Text = txt, Font = FONT, TextSize = size or 22,
		TextColor3 = col or C.Off, TextXAlignment = align or Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(x, cy), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(w or 300, 30),
	}, parent)
end
local function Icon(parent, name, cx, cy, size, col)
	local i = New("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(size, size), ImageColor3 = col or C.Off }, parent)
	ApplyIcon(i, name)
	return i
end
local function Line(parent, x, y, w)
	return New("Frame", { BackgroundColor3 = C.Line, BackgroundTransparency = 0.35, BorderSizePixel = 0,
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 1) }, parent)
end

local Accent = Color3.fromRGB(124, 58, 237)
local Hooks = {}
local function AccentSeq() return ColorSequence.new(Accent:Lerp(WHITE, 0.35), Accent) end
local function OnAccent(obj, fn) table.insert(Hooks, { obj, fn }); fn() end
local function SetAccent(c)
	Accent = c
	for i = #Hooks, 1, -1 do
		local h = Hooks[i]
		if h[1].Parent == nil then table.remove(Hooks, i) else h[2]() end
	end
end

local Root, Scale, Popup, Blocker, Drop, DropBlocker, Listening, ActiveDrag, Notifier, WmOpts
local MenuKey = Enum.KeyCode.Insert
local Folder, AutoFile = "Paw", "Paw/autoload.txt"
local AllScrollers = {}
local Config, Callbacks, Registry, Refreshers = {}, {}, {}, {}
local Presets = {
	Color3.fromRGB(124, 58, 237), Color3.fromRGB(255, 120, 120), Color3.fromRGB(255, 185, 110),
	Color3.fromRGB(255, 235, 130), Color3.fromRGB(140, 235, 150), Color3.fromRGB(120, 220, 255),
	Color3.fromRGB(124, 58, 237),
}
local EaseList = { "Linear", "Sine", "Quad", "Cubic", "Quart", "Quint", "Exponential", "Back", "Bounce", "Elastic" }
local TypeMap = { Slider = "slider", Dropdown = "dropdown", MultiDropdown = "multi", SearchDropdown = "search",
	Keybind = "keybind", ColorPicker = "color", Toggle = "toggle", Input = "input", Button = "button", Label = "label" }

local function Cfg(key)
	if not Config[key] then Config[key] = { enabled = false, options = {}, cbs = {} } end
	return Config[key]
end
local function Call(key, ...)
	local cb = Callbacks[key]
	if cb then task.spawn(cb, ...) end
end
local function Refresh(obj, fn) table.insert(Refreshers, { obj, fn }) end
local function RefreshAll()
	for i = #Refreshers, 1, -1 do
		local r = Refreshers[i]
		if r[1].Parent == nil then table.remove(Refreshers, i) else pcall(r[2]) end
	end
end
local function Register(key, obj, fn)
	Registry[key] = Registry[key] or {}
	table.insert(Registry[key], { obj, fn })
end
local function SetEnabled(key, v)
	Cfg(key).enabled = v
	local r = Registry[key]
	if r then
		for i = #r, 1, -1 do
			if r[i][1].Parent == nil then table.remove(r, i) else r[i][2](v) end
		end
	end
	Call(key, v)
end

local function Tw(t, style, dir)
	local sp = Config["tween speed"]
	sp = sp and tonumber(sp.value) or 100
	local es = style
	if not es then
		local st = Config["easing style"]
		local okE, v = pcall(function() return Enum.EasingStyle[st and st.value or "Quart"] end)
		es = okE and v or Enum.EasingStyle.Quart
	end
	return TweenInfo.new(t / math.max(sp, 10) * 100, es, dir or Enum.EasingDirection.Out)
end

local function Spec(o)
	local t = TypeMap[o.Type]
	local e = { t = t, n = o.Name or (t == "keybind" and "keybind" or nil), min = o.Min, max = o.Max, def = o.Default,
		suf = o.Suffix, step = o.Step, list = o.List, ph = o.Placeholder, col = o.Color }
	if t == "button" then e.cb = o.Callback else e.on = o.Callback end
	return e
end

local function ExtScale() return math.clamp(Scale.Scale * 1.15, 0.5, 0.9) end
local function ViewportSize()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1920, 1080)
end
local function SetScrolling(b) for _, s in ipairs(AllScrollers) do s.ScrollingEnabled = b end end
local function KeyName(k) return k and k.Name:lower() or "none" end

local function CloseDrop()
	if Drop then Drop:Destroy(); Drop = nil end
	if DropBlocker then DropBlocker:Destroy(); DropBlocker = nil end
end
local function ClosePopup()
	CloseDrop()
	if Popup then Popup:Destroy(); Popup = nil end
	if Blocker then Blocker:Destroy(); Blocker = nil end
end

local function MakeCheck(parent, label, cx, cy, size, textSize, textX, width, get, set, regKey)
	local box = New("Frame", { BackgroundColor3 = C.Box, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(size, size) }, parent)
	Corner(box, 6)
	local g = New("UIGradient", { Rotation = 45, Enabled = false }, box)
	local chk = Icon(box, "check", size / 2, size / 2, size * 0.72, Color3.fromRGB(10, 5, 20))
	chk.Visible = false
	local lbl = Text(parent, label, textX, cy, width, textSize, C.Off)
	local first = true
	local function apply(v)
		box.BackgroundColor3 = v and WHITE or C.Box
		g.Enabled = v
		g.Color = AccentSeq()
		chk.Visible = v
		local col = v and C.On or C.Off
		if first then lbl.TextColor3 = col
		else TweenService:Create(lbl, Tw(0.15), { TextColor3 = col }):Play() end
	end
	OnAccent(box, function() g.Color = AccentSeq() end)
	if regKey then Register(regKey, box, apply) end
	apply(get())
	first = false
	if not regKey then Refresh(box, function() apply(get()) end) end
	local hit = New("TextButton", { Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(cx - 4, cy), Size = UDim2.fromOffset(width + (textX - cx), size + 12) }, parent)
	hit.MouseButton1Click:Connect(function()
		set(not get())
		if not regKey then apply(get()) end
	end)
end

local function MakeSlider(parent, x, y, w, e)
	Text(parent, e.n, x, y + 14, w - 160, 21, C.Off)
	local val = Text(parent, "", x + w - 150, y + 14, 150, 21, C.On, Enum.TextXAlignment.Right)
	local track = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = C.Box, BorderSizePixel = 0,
		Position = UDim2.fromOffset(x, y + 34), Size = UDim2.fromOffset(w, 10) }, parent)
	Corner(track, 5)
	local fill = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(0.02, 1) }, track)
	Corner(fill, 5)
	local g = New("UIGradient", {}, fill)
	OnAccent(fill, function() g.Color = AccentSeq() end)
	local knob = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.02, 0.5), Size = UDim2.fromOffset(20, 20), ZIndex = 2 }, track)
	Corner(knob, 10)
	local ks = Stroke(knob, Accent, 3, 0)
	OnAccent(knob, function() ks.Color = Accent end)
	local step = e.step or 1
	local TI = Tw(0.12)
	local function show(v, instant)
		local f = math.max((v - e.min) / (e.max - e.min), 0.012)
		if instant then
			fill.Size = UDim2.fromScale(f, 1)
			knob.Position = UDim2.fromScale(f, 0.5)
		else
			TweenService:Create(fill, TI, { Size = UDim2.fromScale(f, 1) }):Play()
			TweenService:Create(knob, TI, { Position = UDim2.fromScale(f, 0.5) }):Play()
		end
		val.Text = tostring(v) .. (e.suf or "")
	end
	local function fromPos(pos)
		local rel = math.clamp((pos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local v = math.clamp(math.floor((e.min + rel * (e.max - e.min)) / step + 0.5) * step, e.min, e.max)
		show(v)
		e.set(v)
	end
	local hitArea = New("TextButton", { Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 20, 0, 30), ZIndex = 3 }, track)
	hitArea.InputBegan:Connect(function(inp)
		if inp.UserInputType == MB1 or inp.UserInputType == TOUCH then
			ActiveDrag = fromPos
			SetScrolling(false)
			fromPos(inp.Position)
		end
	end)
	Refresh(track, function() show(e.get() or e.min, true) end)
	show(e.get() or e.min, true)
end

local function SmallBox(parent, txt, x, cy, w)
	local b = New("TextButton", { Text = txt, Font = FONT, TextSize = 20, TextColor3 = C.On, AutoButtonColor = false,
		BackgroundColor3 = C.Box, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromOffset(x, cy), Size = UDim2.fromOffset(w, 32) }, parent)
	Corner(b, 6)
	Stroke(b, C.BoxStroke, 1, 0.3)
	return b
end

local function DropButton(parent, x, cy, w, getText)
	local b = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = C.Box, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(x, cy), Size = UDim2.fromOffset(w, 32) }, parent)
	Corner(b, 6)
	Stroke(b, C.BoxStroke, 1, 0.3)
	local t = New("TextLabel", { BackgroundTransparency = 1, Font = FONT, TextSize = 19, TextColor3 = C.On,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0) }, b)
	Icon(b, "chevron-down", w - 16, 16, 16, C.Off)
	local function refresh() t.Text = getText() end
	refresh()
	return b, refresh
end

local function AnchorRect(anchor)
	local s = Scale.Scale
	return (anchor.AbsolutePosition - Root.AbsolutePosition) / s, anchor.AbsoluteSize / s
end

local function MakeOverlay(x, y, w, h)
	CloseDrop()
	DropBlocker = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 65 }, Root)
	DropBlocker.MouseButton1Click:Connect(CloseDrop)
	Drop = New("Frame", { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, ZIndex = 70,
		Position = UDim2.fromOffset(x, y + 8), Size = UDim2.fromOffset(w, h) }, Root)
	Corner(Drop, 8)
	Grad(Drop, Color3.fromRGB(16, 12, 26), Color3.fromRGB(5, 3, 10), 60)
	Grad(Stroke(Drop, WHITE, 1, 0.1), Color3.fromRGB(60, 30, 110), Color3.fromRGB(168, 130, 255), 45)
	TweenService:Create(Drop, Tw(0.12), { Position = UDim2.fromOffset(x, y) }):Play()
	return Drop
end

local function OpenList(anchor, e, mode, refresh)
	local a, sz = AnchorRect(anchor)
	local w = math.max(sz.X, 190)
	local rowH = 34
	local top = (mode == "search") and 46 or 6
	local listH = math.min(#e.list, 6) * rowH
	local h = top + listH + 6
	local x = math.clamp(a.X + sz.X - w, 10, DESIGN_W - w - 10)
	local y = a.Y + sz.Y + 4
	if y + h > DESIGN_H - 10 then y = math.max(a.Y - h - 4, 10) end
	local D = MakeOverlay(x, y, w, h)

	local box
	if mode == "search" then
		box = New("TextBox", { PlaceholderText = "search...", Text = "", ClearTextOnFocus = false, Font = FONT, TextSize = 19,
			TextColor3 = C.On, PlaceholderColor3 = C.Off, BackgroundColor3 = C.Box, BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(w - 16, 30) }, D)
		Corner(box, 6)
		New("UIPadding", { PaddingLeft = UDim.new(0, 10) }, box)
		Icon(box, "search", w - 16 - 18, 15, 16, C.Off)
	end
	local sf = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(6, top),
		Size = UDim2.fromOffset(w - 12, listH), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(60, 30, 110) }, D)
	New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, sf)

	local function isSel(it)
		if mode == "multi" then return table.find(e.get() or {}, it) ~= nil end
		return e.get() == it
	end
	local rebuild
	rebuild = function()
		local pos = sf.CanvasPosition
		for _, c in ipairs(sf:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local f = box and box.Text:lower() or ""
		for i, it in ipairs(e.list) do
			if f == "" or it:lower():find(f, 1, true) then
				local sel = isSel(it)
				local b = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(12, 6, 22),
					BackgroundTransparency = sel and 0.45 or 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = i }, sf)
				Corner(b, 6)
				New("TextLabel", { BackgroundTransparency = 1, Text = it, Font = FONT, TextSize = 19,
					TextColor3 = sel and C.On or C.Off, TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -40, 1, 0) }, b)
				if sel then Icon(b, "check", w - 12 - 20, 16, 16, Accent) end
				b.MouseEnter:Connect(function() if not sel then b.BackgroundTransparency = 0.75 end end)
				b.MouseLeave:Connect(function() if not sel then b.BackgroundTransparency = 1 end end)
				b.MouseButton1Click:Connect(function()
					if mode == "multi" then
						local set = {}
						for _, v in ipairs(e.get() or {}) do set[v] = true end
						set[it] = not set[it] or nil
						local new = {}
						for _, v in ipairs(e.list) do if set[v] then table.insert(new, v) end end
						e.set(new)
						refresh()
						rebuild()
					else
						e.set(it)
						refresh()
						CloseDrop()
					end
				end)
			end
		end
		sf.CanvasPosition = pos
	end
	rebuild()
	if box then box:GetPropertyChangedSignal("Text"):Connect(rebuild) end
end

local function OpenPicker(anchor, title, get, set)
	local a, sz = AnchorRect(anchor)
	local w, h = 300, 362
	local x = math.clamp(a.X + sz.X - w, 10, DESIGN_W - w - 10)
	local y = a.Y + sz.Y + 6
	if y + h > DESIGN_H - 10 then y = math.max(a.Y - h - 6, 10) end
	local D = MakeOverlay(x, y, w, h)
	Text(D, title, 16, 26, 260, 21, Color3.fromRGB(255, 255, 255))

	local hh, ss, vv = (get() or Presets[1]):ToHSV()

	local sv = New("Frame", { BackgroundColor3 = Color3.fromHSV(hh, 1, 1), BorderSizePixel = 0,
		Position = UDim2.fromOffset(16, 50), Size = UDim2.fromOffset(268, 170) }, D)
	Corner(sv, 6)
	local wo = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, sv)
	Corner(wo, 6)
	New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, wo)
	local bo = New("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, sv)
	Corner(bo, 6)
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, bo)
	local svBtn = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, sv)
	local svCur = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16) }, sv)
	Corner(svCur, 8)
	Stroke(svCur, WHITE, 2, 0)
	local svCur2 = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18) }, svCur)
	Corner(svCur2, 9)
	Stroke(svCur2, Color3.new(0, 0, 0), 1, 0.4)

	local hue = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0,
		Position = UDim2.fromOffset(16, 232), Size = UDim2.fromOffset(268, 16) }, D)
	Corner(hue, 8)
	New("UIGradient", { Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) }) }, hue)
	local hueBtn = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, hue)
	local hueCur = New("Frame", { BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(8, 24), BorderSizePixel = 0 }, hue)
	Corner(hueCur, 4)
	Stroke(hueCur, Color3.new(0, 0, 0), 1, 0.5)

	local hex = New("TextBox", { Text = "", ClearTextOnFocus = false, Font = FONT, TextSize = 19, TextColor3 = C.On,
		BackgroundColor3 = C.Box, BorderSizePixel = 0, Position = UDim2.fromOffset(16, 262), Size = UDim2.fromOffset(116, 34) }, D)
	Corner(hex, 6)
	Stroke(hex, C.BoxStroke, 1, 0.3)
	local prev = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(142, 262),
		Size = UDim2.fromOffset(40, 34) }, D)
	Corner(prev, 6)
	Stroke(prev, Color3.fromRGB(60, 30, 110), 1, 0.2)
	local rgb = Text(D, "", 192, 279, 92, 17, C.Off, Enum.TextXAlignment.Right)

	local function update(fire)
		local c = Color3.fromHSV(hh, ss, vv)
		sv.BackgroundColor3 = Color3.fromHSV(hh, 1, 1)
		svCur.Position = UDim2.fromScale(ss, 1 - vv)
		hueCur.Position = UDim2.fromScale(hh, 0.5)
		prev.BackgroundColor3 = c
		hex.Text = "#" .. c:ToHex():upper()
		rgb.Text = math.floor(c.R * 255 + 0.5) .. ", " .. math.floor(c.G * 255 + 0.5) .. ", " .. math.floor(c.B * 255 + 0.5)
		if fire then set(c) end
	end

	svBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType == MB1 or inp.UserInputType == TOUCH then
			local function f(pos)
				ss = math.clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
				vv = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
				update(true)
			end
			ActiveDrag = f
			SetScrolling(false)
			f(inp.Position)
		end
	end)
	hueBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType == MB1 or inp.UserInputType == TOUCH then
			local function f(pos)
				hh = math.clamp((pos.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 0.999)
				update(true)
			end
			ActiveDrag = f
			SetScrolling(false)
			f(inp.Position)
		end
	end)
	hex.FocusLost:Connect(function()
		local okc, c = pcall(Color3.fromHex, hex.Text)
		if okc and c then hh, ss, vv = c:ToHSV(); update(true) else update(false) end
	end)

	Text(D, "presets", 16, 316, 100, 16, C.Off)
	for i, col in ipairs(Presets) do
		local b = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = col, BorderSizePixel = 0,
			Position = UDim2.fromOffset(16 + (i - 1) * 39, 328), Size = UDim2.fromOffset(30, 22) }, D)
		Corner(b, 6)
		Stroke(b, Color3.fromRGB(0, 0, 0), 1, 0.6)
		b.MouseButton1Click:Connect(function() hh, ss, vv = col:ToHSV(); update(true) end)
	end
	update(false)
end

local function WH(e) return e.t == "slider" and 62 or (e.t == "label" and 36 or 44.5) end

local function AddWidget(parent, e, x, y, w)
	if type(y) ~= "number" then
		warn("[Paw] AddWidget bad y=" .. tostring(y) .. " row=" .. tostring(e and e.n) .. " type=" .. tostring(e and e.t))
		warn(debug.traceback())
		y = 0
	end
	local h = WH(e)
	local cy = y + h / 2
	local t = e.t
	local extra
	if t == "enabled" then
		MakeCheck(parent, e.n or "enabled", x, cy, 28, 22, x + 44, w - 44,
			function() return Cfg(e.key).enabled end, function(v) SetEnabled(e.key, v) end, e.key)
	elseif t == "toggle" then
		MakeCheck(parent, e.n, x, cy, 28, 22, x + 44, w - 44, e.get, e.set)
	elseif t == "slider" then
		MakeSlider(parent, x, y, w, e)
	elseif t == "dropdown" or t == "multi" or t == "search" then
		Text(parent, e.n, x, cy, w - 175, 21, C.Off)
		local b, refresh
		local function txt()
			if t == "multi" then
				local v = e.get() or {}
				return #v == 0 and "none" or table.concat(v, ", ")
			end
			return tostring(e.get() or "none")
		end
		b, refresh = DropButton(parent, x + w, cy, 165, txt)
		b.MouseButton1Click:Connect(function() OpenList(b, e, t, refresh) end)
		Refresh(b, refresh)
		if e.onCreate then e.onCreate(b, refresh) end
	elseif t == "keybind" then
		Text(parent, e.n, x, cy, w - 175, 21, C.Off)
		local b = SmallBox(parent, KeyName(e.get()), x + w, cy, 165)
		Refresh(b, function() b.Text = KeyName(e.get()) end)
		b.MouseButton1Click:Connect(function()
			b.Text = "..."
			b.TextColor3 = Accent
			Listening = function(k) e.set(k); b.Text = KeyName(k); b.TextColor3 = C.On end
		end)
	elseif t == "color" then
		Text(parent, e.n, x, cy, w - 100, 21, C.Off)
		local sw = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = e.get() or Presets[1],
			BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(x + w, cy),
			Size = UDim2.fromOffset(56, 30) }, parent)
		Corner(sw, 6)
		Stroke(sw, Color3.fromRGB(0, 0, 0), 1, 0.55)
		Refresh(sw, function() sw.BackgroundColor3 = e.get() or Presets[1] end)
		sw.MouseButton1Click:Connect(function()
			OpenPicker(sw, e.n, e.get, function(c) e.set(c); sw.BackgroundColor3 = c end)
		end)
	elseif t == "input" then
		Text(parent, e.n, x, cy, w - 175, 21, C.Off)
		local tb = New("TextBox", { Text = e.get() or "", PlaceholderText = e.ph or "type...", ClearTextOnFocus = false,
			Font = FONT, TextSize = 19, TextColor3 = C.On, PlaceholderColor3 = C.Off, BackgroundColor3 = C.Box,
			BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromOffset(x + w, cy), Size = UDim2.fromOffset(165, 32) }, parent)
		Corner(tb, 6)
		Stroke(tb, C.BoxStroke, 1, 0.3)
		New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, tb)
		tb.FocusLost:Connect(function() e.set(tb.Text) end)
		Refresh(tb, function() tb.Text = e.get() or "" end)
	elseif t == "label" then
		extra = Text(parent, e.n, x, cy, w, 19, e.col or C.Off)
	elseif t == "button" then
		local bg = New("Frame", { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Position = UDim2.fromOffset(x, cy - 17),
			Size = UDim2.fromOffset(w, 34) }, parent)
		Corner(bg, 8)
		Grad(bg, Color3.fromRGB(12, 6, 22), Color3.fromRGB(10, 6, 18), 0)
		Grad(Stroke(bg, WHITE, 1, 0.2), Color3.fromRGB(60, 30, 110), Color3.fromRGB(168, 130, 255), 45)
		local b = New("TextButton", { Text = e.n, Font = FONT, TextSize = 20, TextColor3 = C.On, AutoButtonColor = false,
			BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, bg)
		b.MouseButton1Click:Connect(function()
			b.TextColor3 = Accent
			task.delay(0.15, function() b.TextColor3 = C.On end)
			if e.cb then e.cb() end
		end)
		extra = b
	end
	return h, extra
end

local function DefaultFor(o)
	if o.t == "slider" then return o.def or o.min
	elseif o.t == "dropdown" or o.t == "search" then return o.def or o.list[1]
	elseif o.t == "multi" then return o.def or {}
	elseif o.t == "color" then return o.def or Presets[1]
	elseif o.t == "toggle" then return o.def or false
	elseif o.t == "input" then return o.def or "" end
	return nil
end

local function PlaceNear(anchor, w, h)
	local a, sz = AnchorRect(anchor)
	local x = a.X + 6
	local y = a.Y + sz.Y + 6
	if x + w > DESIGN_W - 12 then x = DESIGN_W - 12 - w end
	if y + h > DESIGN_H - 12 then y = a.Y - h - 6 end
	return Vector2.new(math.max(x, 10), math.max(y, 10))
end

local function OpenPopup(title, anchor, entries, posFn, popName)
	ClosePopup()
	local w, h = 389, 52
	for _, e in ipairs(entries) do h += WH(e) end
	h += 8
	Blocker = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40 }, Root)
	Blocker.MouseButton1Click:Connect(ClosePopup)
	local pos = posFn and posFn(w, h) or PlaceNear(anchor, w, h)
	Popup = New("Frame", { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, ZIndex = 50,
		Position = UDim2.fromOffset(pos.X, pos.Y + 10), Size = UDim2.fromOffset(w, h) }, Root)
	Popup.Name = popName or "Popup"
	Corner(Popup, 8)
	Grad(Popup, Color3.fromRGB(16, 12, 26), Color3.fromRGB(5, 3, 10), 60)
	Grad(Stroke(Popup, WHITE, 1, 0.1), Color3.fromRGB(60, 30, 110), Color3.fromRGB(168, 130, 255), 45)
	TweenService:Create(Popup, Tw(0.12), { Position = UDim2.fromOffset(pos.X, pos.Y) }):Play()
	Text(Popup, title, 16, 28, 300, 21, Color3.fromRGB(255, 255, 255))
	local y = 52
	for _, e in ipairs(entries) do y += AddWidget(Popup, e, 16, y, 357) end
end

local function InitOpts(key, opts)
	local c = Cfg(key)
	for _, o in ipairs(opts) do
		if o.t ~= "keybind" and o.t ~= "button" and o.t ~= "label" then
			if c.options[o.n] == nil then c.options[o.n] = DefaultFor(o) end
			if o.on then
				c.cbs[o.n] = o.on
				task.defer(o.on, c.options[o.n])
			end
		end
	end
end

local function FeatureEntries(key, opts)
	local c = Cfg(key)
	local entries = { { t = "enabled", key = key } }
	for _, o in ipairs(opts) do
		local e = table.clone(o)
		if o.t == "keybind" then
			e.get = function() return c.bind end
			e.set = function(v) c.bind = v end
		else
			e.get = function() return c.options[o.n] end
			e.set = function(v)
				c.options[o.n] = v
				if o.on then task.spawn(o.on, v) end
			end
		end
		table.insert(entries, e)
	end
	return entries
end

local function InlineEntry(it)
	local key = it.key or it.n
	local c = Cfg(key)
	local e = table.clone(it)
	Callbacks[key] = it.on
	if it.t == "keybind" then
		c.keybindOnly = true
		c.kind = "keybind"
		if it.def and not c.bind then c.bind = it.def end
		e.get = function() return c.bind end
		e.set = function(v) c.bind = v end
	else
		c.kind = "value"
		if c.value == nil then c.value = DefaultFor(it) end
		e.get = function() return c.value end
		e.set = function(v) c.value = v; Call(key, v) end
		if it.on then task.defer(it.on, c.value) end
	end
	return e
end

local function MakeDraggable(handle, target, clamp, canDrag)
	local dragging, moved, startInput, startPos = false, false, nil, nil
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == MB1 or inp.UserInputType == TOUCH then
			if canDrag and not canDrag() then return end
			dragging, moved = true, false
			startInput, startPos = inp.Position, target.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == TOUCH) then
			local d = inp.Position - startInput
			if not moved and d.Magnitude < 6 then return end
			moved = true
			local nx, ny = startPos.X.Offset + d.X, startPos.Y.Offset + d.Y
			if clamp then nx, ny = clamp(nx, ny) end
			target.Position = UDim2.new(startPos.X.Scale, nx, startPos.Y.Scale, ny)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == MB1 or inp.UserInputType == TOUCH then dragging = false end
	end)
	return function() return moved end
end

local function WindowClamp(x, y)
	local vp = ViewportSize()
	return math.clamp(x, -vp.X / 2 + 90, vp.X / 2 - 90), math.clamp(y, -vp.Y / 2 + 40, vp.Y / 2 - 40)
end
local function KbClamp(x, y)
	local vp = ViewportSize()
	return math.clamp(x, -vp.X + 140, 120), math.clamp(y, -vp.Y / 2 + 30, vp.Y / 2 - 30)
end
local function WmClamp(x, y)
	local vp = ViewportSize()
	return math.clamp(x, -vp.X + 100, 100), math.clamp(y, 0, vp.Y - 40)
end

local FS_OK = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local MemStore, MemAuto = {}, nil

local function CleanName(n)
	n = tostring(n or ""):gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	return n ~= "" and n or nil
end
local function KeyFromName(n)
	local okk, k = pcall(function() return Enum.KeyCode[n] end)
	return okk and k or nil
end

local Store = {}
local function CfgPath(n) return Folder .. "/" .. n .. ".json" end
function Store.List()
	local names = {}
	if FS_OK and type(listfiles) == "function" then
		local okl, files = pcall(listfiles, Folder)
		if okl and type(files) == "table" then
			for _, path in ipairs(files) do
				local n = tostring(path):match("([^/\\]+)%.json$")
				if n then table.insert(names, n) end
			end
		end
	else
		for n in pairs(MemStore) do table.insert(names, n) end
	end
	table.sort(names, function(a, b) return a:lower() < b:lower() end)
	return names
end
function Store.Exists(n)
	if FS_OK then return isfile(CfgPath(n)) end
	return MemStore[n] ~= nil
end
function Store.Write(n, json)
	if FS_OK then writefile(CfgPath(n), json) else MemStore[n] = json end
end
function Store.Read(n)
	if FS_OK then
		local okr, d = pcall(readfile, CfgPath(n))
		return okr and d or nil
	end
	return MemStore[n]
end
function Store.GetAuto()
	if FS_OK then
		if not isfile(AutoFile) then return nil end
		local okr, d = pcall(readfile, AutoFile)
		return okr and CleanName(d) or nil
	end
	return MemAuto
end
function Store.SetAuto(n)
	if FS_OK then
		if n then writefile(AutoFile, n)
		elseif type(delfile) == "function" and isfile(AutoFile) then delfile(AutoFile)
		else writefile(AutoFile, "") end
	else
		MemAuto = n
	end
end

local function Enc(v)
	local t = typeof(v)
	if t == "Color3" then return { __t = "c", r = v.R, g = v.G, b = v.B }
	elseif t == "EnumItem" then return { __t = "k", n = v.Name }
	elseif t == "table" then
		local o = {}
		for k, x in pairs(v) do o[k] = Enc(x) end
		return o
	end
	return v
end
local function Dec(v)
	if type(v) == "table" then
		if v.__t == "c" then return Color3.new(v.r, v.g, v.b) end
		if v.__t == "k" then return KeyFromName(v.n) end
		local o = {}
		for k, x in pairs(v) do o[k] = Dec(x) end
		return o
	end
	return v
end

local function Serialize()
	local data = {}
	for k, c in pairs(Config) do
		if next(c.options) ~= nil or c.value ~= nil or c.bind or c.enabled then
			data[k] = { e = c.enabled, o = Enc(c.options), v = Enc(c.value), b = c.bind and c.bind.Name or nil }
		end
	end
	return HttpService:JSONEncode({ ver = 1, accent = Enc(Accent), menukey = MenuKey.Name, data = data })
end

local function ApplyConfig(tbl)
	local okA = pcall(function()
		if tbl.accent then
			local ac = Dec(tbl.accent)
			if typeof(ac) == "Color3" then SetAccent(ac) end
		end
		if tbl.menukey then MenuKey = KeyFromName(tbl.menukey) or MenuKey end
		for k, s in pairs(tbl.data or {}) do
			if type(s) == "table" then
				local c = Cfg(k)
				if type(s.o) == "table" then
					for oname, ov in pairs(Dec(s.o)) do
						c.options[oname] = ov
						local f = c.cbs[oname]
						if f then task.spawn(f, ov) end
					end
				end
				if s.v ~= nil then
					c.value = Dec(s.v)
					if c.kind == "value" then Call(k, c.value) end
				end
				if s.b then c.bind = KeyFromName(s.b) elseif c.kind ~= "value" then c.bind = nil end
				if c.kind == "toggle" then SetEnabled(k, s.e == true) end
			end
		end
		RefreshAll()
	end)
	return okA
end

local Configs = {}
local CfgName, CfgSel = "", nil
local CfgList = {}

local function RefreshList()
	table.clear(CfgList)
	for _, n in ipairs(Store.List()) do table.insert(CfgList, n) end
	if CfgSel and not table.find(CfgList, CfgSel) then CfgSel = nil end
	if not CfgSel then CfgSel = Store.GetAuto() and table.find(CfgList, Store.GetAuto()) and Store.GetAuto() or CfgList[1] end
end
local function Note(title, info, icon)
	if Notifier then Notifier(title, info, icon, 3) end
end
local function UpdateAutoLabel()
	local a = Store.GetAuto()
	if Configs.AutoLabel and Configs.AutoLabel.Parent then
		Configs.AutoLabel.Text = "autoload: " .. (a or "none")
		Configs.AutoLabel.TextColor3 = a and Accent or C.Off
	end
end

function Configs.Save(name)
	name = CleanName(name)
	if not name then Note("config", "enter a name first", "info"); return false end
	if Store.Exists(name) then Note("config", '"' .. name .. '" already exists, use overwrite', "info"); return false end
	local okw = pcall(function() Store.Write(name, Serialize()) end)
	if not okw then Note("config", "could not save", "x"); return false end
	CfgSel = name
	RefreshList()
	Note("config saved", '"' .. name .. '"', "check")
	return true
end

function Configs.Overwrite(name)
	name = CleanName(name or CfgSel)
	if not name or not Store.Exists(name) then Note("config", "select a config first", "info"); return false end
	local okw = pcall(function() Store.Write(name, Serialize()) end)
	Note(okw and "config overwritten" or "config", okw and ('"' .. name .. '"') or "could not save", okw and "check" or "x")
	return okw
end

function Configs.Load(name, silent)
	name = CleanName(name or CfgSel)
	if not name or not Store.Exists(name) then
		if not silent then Note("config", "select a config first", "info") end
		return false
	end
	local json = Store.Read(name)
	local okd, tbl = pcall(function() return HttpService:JSONDecode(json) end)
	if not okd or type(tbl) ~= "table" then Note("config", "file is broken", "x"); return false end
	local oka = ApplyConfig(tbl)
	Note(silent and "autoload" or "config loaded", '"' .. name .. '"', oka and "check" or "x")
	return oka
end

function Configs.SetAutoload(name)
	name = CleanName(name or CfgSel)
	if not name or not Store.Exists(name) then Note("config", "select a config first", "info"); return false end
	pcall(Store.SetAuto, name)
	UpdateAutoLabel()
	Note("autoload set", '"' .. name .. '"', "check")
	return true
end

function Configs.RemoveAutoload()
	pcall(Store.SetAuto, nil)
	UpdateAutoLabel()
	Note("autoload removed", "no config loads on start", "check")
end

function Configs.RunAutoload()
	local a = Store.GetAuto()
	if a and Store.Exists(a) then Configs.Load(a, true) end
end



local SectionMT = {}
SectionMT.__index = SectionMT

local function AddEntry(sec, e)
	local h, obj = AddWidget(sec.Panel, e, 19, sec.Y, 374)
	sec.Y += h
	sec.Panel.Size = UDim2.fromOffset(412, sec.Y + 10)
	return obj
end

local function Value(sec, t, o)
	local e = Spec(o)
	e.t = t
	e.n = o.Name
	e.key = o.Flag or o.Name
	e = InlineEntry(e)
	AddEntry(sec, e)
	return {
		Get = function() return e.get() end,
		Set = function(_, v) e.set(v) end,
	}
end

function SectionMT:Toggle(o)
	local key = o.Flag or o.Name
	local c = Cfg(key)
	c.kind = "toggle"
	Callbacks[key] = o.Callback
	if o.Default then c.enabled = true end
	local y = self.Y
	local cy = y + 22.25
	MakeCheck(self.Panel, o.Name, 19, cy, 30, 22, 62, 260, function() return c.enabled end,
		function(v) SetEnabled(key, v) end, key)
	if o.Options then
		local specs = {}
		for _, s in ipairs(o.Options) do table.insert(specs, Spec(s)) end
		InitOpts(key, specs)
		local dots = New("TextButton", { Text = "···", Font = FONT, TextSize = 26, TextColor3 = C.Off,
			TextTransparency = 0.3, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(358, cy), Size = UDim2.fromOffset(44, 30) }, self.Panel)
		dots.MouseButton1Click:Connect(function()
			OpenPopup(o.Name, dots, FeatureEntries(key, specs))
		end)
	end
	self.Y += 44.5
	self.Panel.Size = UDim2.fromOffset(412, self.Y + 10)
	if o.Default and o.Callback then task.defer(o.Callback, true) end
	return {
		Get = function() return c.enabled end,
		Set = function(_, v) SetEnabled(key, v == true) end,
		Options = c.options,
	}
end

function SectionMT:Slider(o) return Value(self, "slider", o) end
function SectionMT:Dropdown(o) return Value(self, "dropdown", o) end
function SectionMT:MultiDropdown(o) return Value(self, "multi", o) end
function SectionMT:SearchDropdown(o) return Value(self, "search", o) end
function SectionMT:Keybind(o) return Value(self, "keybind", o) end
function SectionMT:ColorPicker(o) return Value(self, "color", o) end
function SectionMT:Input(o) return Value(self, "input", o) end

function SectionMT:Button(o)
	AddEntry(self, { t = "button", n = o.Name, cb = function()
		if o.Callback then task.spawn(o.Callback) end
	end })
end

function SectionMT:Label(o)
	if type(o) == "string" then o = { Text = o } end
	local lbl = AddEntry(self, { t = "label", n = o.Text or "", col = o.Color })
	return {
		SetText = function(_, txt, col)
			lbl.Text = tostring(txt)
			if col then lbl.TextColor3 = col end
		end,
	}
end

function SectionMT:Separator()
	Line(self.Panel, 13, self.Y + 8, 386)
	self.Y += 16
	self.Panel.Size = UDim2.fromOffset(412, self.Y + 10)
end

local function MakePanel(parent, title, icon, order)
	local p = New("Frame", { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromOffset(412, 75),
		LayoutOrder = order }, parent)
	Corner(p, 10)
	local g = Grad(p, Color3.fromRGB(16, 12, 26), Color3.fromRGB(5, 3, 10), 90)
	Grad(Stroke(p, WHITE, 1, 0.2), Color3.fromRGB(60, 30, 110), Color3.fromRGB(168, 130, 255), 55)
	local bar = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0,
		Position = UDim2.fromOffset(13, 15), Size = UDim2.fromOffset(6, 26) }, p)
	Corner(bar, 3)
	local bg = New("UIGradient", { Rotation = 90 }, bar)
	OnAccent(bar, function() bg.Color = AccentSeq() end)
	local pic = Icon(p, icon, 44, 28, 22, WHITE)
	local pig = New("UIGradient", { Rotation = 45 }, pic)
	OnAccent(pic, function() pig.Color = AccentSeq() end)
	Text(p, title, 64, 28, 280, 21, Color3.fromRGB(255, 255, 255))
	Line(p, 13, 55, 386)
	return p
end

local SubMT = {}
SubMT.__index = SubMT

function SubMT:Section(o)
	o = o or {}
	local right = tostring(o.Side or "Left"):lower() == "right"
	self.Count += 1
	local panel = MakePanel(right and self.Right or self.Left, o.Name or "section", o.Icon or "layout-grid", self.Count)
	return setmetatable({ Panel = panel, Y = 65 }, SectionMT)
end

function Library:Window(o)
	o = o or {}
	pcall(function() print("[Paw] ui version: " .. tostring(Library.UI_VERSION or "unknown")) end)
	local Title = tostring(o.Title or "Paw")
	local Logo = o.Logo or "rbxassetid://81441172534384"
	Folder = tostring(o.ConfigFolder or "Paw")
	AutoFile = Folder .. "/autoload.txt"
	if o.MenuKey then MenuKey = o.MenuKey end

	pcall(function()
		if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder(Folder) then
			makefolder(Folder)
		end
	end)

	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		local old = host:FindFirstChild("Paw")
		if old then old:Destroy() end
	end)

	local Gui = New("ScreenGui", { Name = "Paw", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
	local okp = pcall(function() Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not okp or not Gui.Parent then Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

	Root = New("Frame", { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(DESIGN_W, DESIGN_H), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0,
		BorderSizePixel = 0, ZIndex = 1 }, Gui)
	Corner(Root, 18)
	Grad(Root, Color3.fromRGB(16, 12, 26), Color3.fromRGB(5, 3, 10), 55, Color3.fromRGB(10, 7, 18))
	Grad(Stroke(Root, WHITE, 1.5, 0.15), Color3.fromRGB(60, 30, 110), Color3.fromRGB(168, 130, 255), 45)
	Scale = New("UIScale", {}, Root)

	local function UpdateScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		Scale.Scale = math.clamp(math.min(vp.X * 0.92 / DESIGN_W, vp.Y * 0.92 / DESIGN_H), 0.15, 0.7)
	end
	local camConn
	local function HookCamera()
		if camConn then camConn:Disconnect() end
		if workspace.CurrentCamera then
			camConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
		end
		UpdateScale()
	end
	HookCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(HookCamera)

	UIS.InputBegan:Connect(function(inp, gp)
		if Listening and inp.UserInputType == Enum.UserInputType.Keyboard then
			local f = Listening
			Listening = nil
			f(inp.KeyCode ~= Enum.KeyCode.Escape and inp.KeyCode or nil)
			return
		end
		if gp or inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if inp.KeyCode == MenuKey then
			Root.Visible = not Root.Visible
			if not Root.Visible then ClosePopup() end
			return
		end
		for k, c in pairs(Config) do
			if c.bind and c.bind == inp.KeyCode then
				if c.keybindOnly then Call(k, inp.KeyCode) else SetEnabled(k, not c.enabled) end
			end
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if ActiveDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == TOUCH) then
			ActiveDrag(inp.Position)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if ActiveDrag and (inp.UserInputType == MB1 or inp.UserInputType == TOUCH) then
			ActiveDrag = nil
			SetScrolling(true)
		end
	end)

	local Sidebar = New("Frame", { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromOffset(97, DESIGN_H) }, Root)
	Corner(Sidebar, 18)
	Grad(Sidebar, Color3.fromRGB(16, 12, 26), Color3.fromRGB(5, 3, 10), 90)
	local Filler = New("Frame", { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0,
		Position = UDim2.fromOffset(60, 0), Size = UDim2.fromOffset(37, DESIGN_H) }, Sidebar)
	Grad(Filler, Color3.fromRGB(16, 12, 26), Color3.fromRGB(5, 3, 10), 90)

	local Mark = Icon(Sidebar, Logo, 46, 45, 46, WHITE)
	if IsCustomAsset(Logo) then
		Mark.ImageColor3 = WHITE
		Mark.ScaleType = Enum.ScaleType.Fit
	else
		local markGrad = New("UIGradient", {}, Mark)
		OnAccent(Mark, function() markGrad.Color = AccentSeq() end)
	end
	Line(Sidebar, 22, 90, 52)

	local SideSel = New("Frame", { BackgroundColor3 = Color3.fromRGB(12, 6, 22), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(46, 143), Size = UDim2.fromOffset(62, 62), Visible = false }, Sidebar)
	Corner(SideSel, 12)
	Grad(SideSel, Color3.fromRGB(30, 14, 55), Color3.fromRGB(12, 6, 22), 45)

	MakeDraggable(Sidebar, Root, WindowClamp)
	local TopHandle = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		Position = UDim2.fromOffset(97, 0), Size = UDim2.fromOffset(DESIGN_W - 97, 77) }, Root)
	MakeDraggable(TopHandle, Root, WindowClamp)
	Line(Root, 97, 77, 865)

	local NF_W, NF_TEXT_W, NF_MAX = 300, 224, 6
	local NfHolder = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(NF_W, 700), ZIndex = 10 }, Gui)
	local NfScale = New("UIScale", { Scale = ExtScale() }, NfHolder)
	New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom }, NfHolder)
	local NfOrder, NfActive = 0, {}
	local ExtScales = { NfScale }
	Scale:GetPropertyChangedSignal("Scale"):Connect(function()
		for _, s in ipairs(ExtScales) do s.Scale = ExtScale() end
	end)

	local function NfDismiss(item)
		if item.dead then return end
		item.dead = true
		local idx = table.find(NfActive, item)
		if idx then table.remove(NfActive, idx) end
		TweenService:Create(item.card, Tw(0.25, nil, Enum.EasingDirection.In),
			{ Position = UDim2.fromOffset(NF_W + 40, 0), GroupTransparency = 1 }):Play()
		task.delay(0.25, function()
			if not item.wrap.Parent then return end
			local tw = TweenService:Create(item.wrap, Tw(0.2), { Size = UDim2.fromOffset(NF_W, 0) })
			tw:Play()
			tw.Completed:Wait()
			item.wrap:Destroy()
		end)
	end

	local function Notify(a, b, c, d)
		local n = type(a) == "table" and a or { Title = a, Info = b, Icon = c, Duration = d }
		local title = tostring(n.Title or n.title or "notification")
		local info = tostring(n.Info or n.info or n.Content or n.content or "")
		local icon = n.Icon or n.icon or "bell"
		local dur = tonumber(n.Duration or n.duration) or 4

		local textH = 0
		if info ~= "" then
			local okb, bounds = pcall(TextService.GetTextSize, TextService, info, 18, FONT, Vector2.new(NF_TEXT_W, 10000))
			textH = okb and bounds.Y or 20
		end
		local hasInfo = info ~= ""
		local h = hasInfo and math.max(68, 40 + textH + 18) or 56

		while #NfActive >= NF_MAX do NfDismiss(NfActive[1]) end

		NfOrder += 1
		local wrap = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(NF_W, h), LayoutOrder = NfOrder }, NfHolder)
		local card = New("CanvasGroup", { BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1,
			Position = UDim2.fromOffset(NF_W + 40, 0), Size = UDim2.fromScale(1, 1) }, wrap)
		Corner(card, 8)

		local bg = New("Frame", { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, card)
		Corner(bg, 8)
		Grad(bg, Color3.fromRGB(16, 12, 26), Color3.fromRGB(5, 3, 10), 60)
		Grad(Stroke(bg, WHITE, 1, 0.1), Color3.fromRGB(60, 30, 110), Color3.fromRGB(168, 130, 255), 45)

		local bar = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 12),
			Size = UDim2.fromOffset(4, h - 28) }, card)
		Corner(bar, 2)
		local bgr = New("UIGradient", { Rotation = 90 }, bar)
		OnAccent(bar, function() bgr.Color = AccentSeq() end)

		local ic = Icon(card, icon, 40, hasInfo and 30 or (h - 4) / 2, 26, IsCustomAsset(icon) and WHITE or Accent)
		if IsCustomAsset(icon) then
			ic.ScaleType = Enum.ScaleType.Fit
		else
			OnAccent(ic, function() ic.ImageColor3 = Accent end)
		end

		Text(card, title, 62, hasInfo and 24 or (h - 4) / 2, NF_TEXT_W, 21, C.On)
		if hasInfo then
			New("TextLabel", { BackgroundTransparency = 1, Text = info, Font = FONT, TextSize = 18, TextColor3 = C.Off,
				TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
				Position = UDim2.fromOffset(62, 40), Size = UDim2.fromOffset(NF_TEXT_W, textH) }, card)
		end

		local fill
		if dur > 0 then
			local track = New("Frame", { BackgroundColor3 = C.Box, BackgroundTransparency = 0.3, BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, h - 4), Size = UDim2.fromOffset(NF_W, 4) }, card)
			fill = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, track)
			local fg = New("UIGradient", {}, fill)
			OnAccent(fill, function() fg.Color = AccentSeq() end)
		end

		local item = { wrap = wrap, card = card, dead = false }
		table.insert(NfActive, item)

		local click = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 10 }, card)
		click.MouseButton1Click:Connect(function() NfDismiss(item) end)

		TweenService:Create(card, Tw(0.3), { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }):Play()
		if fill then
			TweenService:Create(fill, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) }):Play()
			task.delay(dur, function() NfDismiss(item) end)
		end

		return { Close = function() NfDismiss(item) end }
	end
	Notifier = Notify

	local Tabs, CurTab = {}, nil
	local PageTweens, LastPage = {}, nil
	local TAB_GAP, TAB_PAD = 14, 13
	local TabMT = {}
	TabMT.__index = TabMT

	local function Layout(tab)
		local n = #tab.Subs
		local scrolling = n > 4
		tab.Scrolling = scrolling
		local avail = DESIGN_W - 97 - TAB_PAD * 2
		local tabW = scrolling and 200 or math.min(274, math.floor((avail - (n - 1) * TAB_GAP) / math.max(n, 1)))
		tab.Scroll.ScrollBarThickness = scrolling and 3 or 0
		tab.Spacer.Position = UDim2.fromOffset(TAB_PAD + n * (tabW + TAB_GAP), 0)
		tab.Pill.Size = UDim2.fromOffset(tabW, 54)
		local ISZ, GAP = 26, 10
		for i, s in ipairs(tab.Subs) do
			local x = TAB_PAD + (i - 1) * (tabW + TAB_GAP)
			s.X = x
			s.Btn.Position = UDim2.fromOffset(x, 11)
			s.Btn.Size = UDim2.fromOffset(tabW, 54)
			local lw = math.min(s.TextW, tabW - ISZ - GAP - 20)
			local startX = (tabW - (ISZ + GAP + lw)) / 2
			s.Ico.Position = UDim2.new(0, startX, 0.5, 0)
			s.Lbl.Position = UDim2.new(0, startX + ISZ + GAP, 0.5, 0)
			s.Lbl.Size = UDim2.fromOffset(lw, 40)
		end
	end

	local function ShowPage(animate)
		ClosePopup()
		local target = CurTab and CurTab.Current and CurTab.Current.Page
		for _, t in ipairs(Tabs) do
			for _, s in ipairs(t.Subs) do
				if s.Page ~= target then
					if PageTweens[s.Page] then PageTweens[s.Page]:Cancel(); PageTweens[s.Page] = nil end
					s.Page.Visible = false
				end
			end
		end
		if target then
			if PageTweens[target] then PageTweens[target]:Cancel(); PageTweens[target] = nil end
			if animate and LastPage ~= target then
				target.GroupTransparency = 1
				target.Position = UDim2.fromOffset(97, 77 + 22)
				target.Visible = true
				local tw = TweenService:Create(target, Tw(0.28), { GroupTransparency = 0, Position = UDim2.fromOffset(97, 77) })
				PageTweens[target] = tw
				tw:Play()
			else
				target.GroupTransparency = 0
				target.Position = UDim2.fromOffset(97, 77)
				target.Visible = true
			end
			LastPage = target
		end
		for _, t in ipairs(Tabs) do
			local active = t == CurTab
			t.Scroll.Visible = active
			t.Pill.Visible = active and t.Current ~= nil
			if t.Current then
				if animate and active and t.Pill.Position.X.Offset ~= t.Current.X then
					TweenService:Create(t.Pill, Tw(0.28), { Position = UDim2.fromOffset(t.Current.X, 11) }):Play()
				else
					t.Pill.Position = UDim2.fromOffset(t.Current.X, 11)
				end
			end
			for _, s in ipairs(t.Subs) do
				local col = (t.Current == s) and C.On or C.Off
				s.Btn.Visible = active
				if animate and active then
					TweenService:Create(s.Lbl, Tw(0.2), { TextColor3 = col }):Play()
					TweenService:Create(s.Ico, Tw(0.2), { ImageColor3 = col }):Play()
				else
					s.Lbl.TextColor3 = col
					s.Ico.ImageColor3 = col
				end
			end
			local icol = active and C.On or C.Off
			if animate then TweenService:Create(t.Icon, Tw(0.2), { ImageColor3 = icol }):Play()
			else t.Icon.ImageColor3 = icol end
		end
	end

	function TabMT:SubTab(so)
		so = so or {}
		local name = tostring(so.Name or "tab")
		local tab = self
		local sub = setmetatable({ Name = name, Count = 0 }, SubMT)

		local page = New("CanvasGroup", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
			Position = UDim2.fromOffset(97, 77), Size = UDim2.fromOffset(DESIGN_W - 97, DESIGN_H - 85) }, Root)
		local sf = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
			ScrollBarImageColor3 = Color3.fromRGB(60, 30, 110), ScrollingDirection = Enum.ScrollingDirection.Y }, page)
		table.insert(AllScrollers, sf)
		local function Column(x)
			local col = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 18),
				Size = UDim2.fromOffset(412, 0), AutomaticSize = Enum.AutomaticSize.Y }, sf)
			New("UIListLayout", { Padding = UDim.new(0, 17), SortOrder = Enum.SortOrder.LayoutOrder }, col)
			New("UIPadding", { PaddingBottom = UDim.new(0, 24) }, col)
			return col
		end
		sub.Page = page
		sub.Left = Column(19)
		sub.Right = Column(442)

		local btn = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Visible = false,
			Size = UDim2.fromOffset(200, 54) }, tab.Scroll)
		local ico = New("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(26, 26), ImageColor3 = C.Off }, btn)
		ApplyIcon(ico, so.Icon)
		local lbl = New("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Text = name,
			Font = FONT, TextSize = 22, TextColor3 = C.Off, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd }, btn)
		local okT, tb = pcall(TextService.GetTextSize, TextService, name, 22, FONT, Vector2.new(600, 50))
		sub.Btn, sub.Ico, sub.Lbl, sub.X = btn, ico, lbl, TAB_PAD
		sub.TextW = (okT and tb.X or 100) + 4

		local dragged = MakeDraggable(btn, Root, WindowClamp, function() return not tab.Scrolling end)
		btn.MouseButton1Click:Connect(function()
			if not tab.Scrolling and dragged() then return end
			if tab.Current ~= sub then
				tab.Current = sub
				ShowPage(true)
			end
		end)

		table.insert(tab.Subs, sub)
		if not tab.Current then tab.Current = sub end
		Layout(tab)
		if tab == CurTab then ShowPage() end
		return sub
	end

	local WindowObj = {}

	function WindowObj:Tab(to)
		to = to or {}
		local idx = #Tabs + 1
		local y = 143 + (idx - 1) * 74
		local tab = setmetatable({ Subs = {}, Current = nil, Scrolling = false }, TabMT)
		tab.Icon = Icon(Sidebar, to.Icon or "box", 46, y, 34, C.Off)
		tab.Icon.ZIndex = 2
		local b = New("TextButton", { Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(46, y), Size = UDim2.fromOffset(70, 70), ZIndex = 2 }, Sidebar)

		tab.Scroll = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
			Position = UDim2.fromOffset(97, 0), Size = UDim2.fromOffset(DESIGN_W - 97, 77), CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X,
			ScrollBarThickness = 0, ScrollBarImageColor3 = Color3.fromRGB(60, 30, 110) }, Root)
		tab.Spacer = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1) }, tab.Scroll)
		tab.Pill = New("Frame", { BackgroundColor3 = Color3.fromRGB(124, 58, 237), BackgroundTransparency = 0, BorderSizePixel = 0, Visible = false,
			Position = UDim2.fromOffset(TAB_PAD, 11), Size = UDim2.fromOffset(274, 54) }, tab.Scroll)
		Corner(tab.Pill, 10)
		Grad(tab.Pill, Color3.fromRGB(168, 130, 255), Color3.fromRGB(124, 58, 237), 0)
		tab.Scroll.InputChanged:Connect(function(inp)
			if tab.Scrolling and inp.UserInputType == Enum.UserInputType.MouseWheel then
				local maxX = math.max(0, (tab.Scroll.AbsoluteCanvasSize.X - tab.Scroll.AbsoluteSize.X) / Scale.Scale)
				tab.Scroll.CanvasPosition = Vector2.new(math.clamp(tab.Scroll.CanvasPosition.X - inp.Position.Z * 60, 0, maxX), 0)
			end
		end)

		table.insert(Tabs, tab)
		b.MouseButton1Click:Connect(function()
			CurTab = tab
			TweenService:Create(SideSel, Tw(0.18), { Position = UDim2.fromOffset(46, y) }):Play()
			ShowPage(true)
		end)
		if not CurTab then
			CurTab = tab
			SideSel.Position = UDim2.fromOffset(46, y)
			SideSel.Visible = true
			ShowPage()
		else
			ShowPage()
		end
		return tab
	end

	function WindowObj:Notify(a, b, c, d) return Notify(a, b, c, d) end

	function WindowObj:SetAccent(col) SetAccent(col) end

	function WindowObj:Destroy() Gui:Destroy() end


	function WindowObj:CreateConfigSystem()
		if WindowObj._hasConfig then return Configs end
		WindowObj._hasConfig = true
		task.defer(Configs.RunAutoload)
		return Configs
	end

	function WindowObj:CreateKeybindList()
		if WindowObj._hasKeybinds then return end
		WindowObj._hasKeybinds = true
		local KbRoot = New("CanvasGroup", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(300, 90),
			ZIndex = 3 }, Gui)
		table.insert(ExtScales, New("UIScale", { Scale = ExtScale() }, KbRoot))

		local KbBg = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1) }, KbRoot)
		Corner(KbBg, 8)
		Grad(KbBg, Color3.fromRGB(16, 12, 26), Color3.fromRGB(5, 3, 10), 60)
		Grad(Stroke(KbBg, WHITE, 1, 0.1), Color3.fromRGB(60, 30, 110), Color3.fromRGB(168, 130, 255), 45)
		MakeDraggable(KbBg, KbRoot, KbClamp)

		local bar = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(13, 14),
			Size = UDim2.fromOffset(5, 24) }, KbBg)
		Corner(bar, 3)
		local bg = New("UIGradient", { Rotation = 90 }, bar)
		OnAccent(bar, function() bg.Color = AccentSeq() end)
		Text(KbBg, "keybind list", 30, 26, 240, 21, Color3.fromRGB(255, 255, 255))
		Line(KbBg, 13, 50, 274)
		local KbHolder = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 56),
			Size = UDim2.new(1, 0, 0, 0) }, KbBg)

		local kc = Cfg("keybind list")
		kc.kind = "toggle"
		kc.enabled = true
		InitOpts("keybind list", { Spec({ Type = "Slider", Name = "opacity", Min = 10, Max = 100, Default = 100, Suffix = "%" }) })

		local kbSig
		local function Rebuild()
			local items = {}
			for k, c in pairs(Config) do
				if c.bind then table.insert(items, { k = k, c = c }) end
			end
			table.sort(items, function(a, b) return a.k < b.k end)
			local sig = ""
			for _, it in ipairs(items) do sig ..= it.k .. it.c.bind.Name .. tostring(it.c.enabled) .. ";" end
			if sig == kbSig then return end
			kbSig = sig
			KbHolder:ClearAllChildren()
			for i, it in ipairs(items) do
				local cy = (i - 1) * 32 + 16
				local on = it.c.enabled and not it.c.keybindOnly
				local dot = New("Frame", { BackgroundColor3 = on and WHITE or C.Box, BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(24, cy), Size = UDim2.fromOffset(11, 11) }, KbHolder)
				Corner(dot, 6)
				if on then
					local dg = New("UIGradient", { Rotation = 45 }, dot)
					OnAccent(dot, function() dg.Color = AccentSeq() end)
				else
					Stroke(dot, C.Off, 1.5, 0.2)
				end
				Text(KbHolder, it.k, 42, cy, 165, 20, on and C.On or DIM)
				local kt = Text(KbHolder, "[" .. KeyName(it.c.bind) .. "]", 205, cy, 80, 19, DIM, Enum.TextXAlignment.Right)
				if on then OnAccent(kt, function() kt.TextColor3 = Accent end) end
			end
			if #items == 0 then Text(KbHolder, "no keybinds set yet", 16, 16, 268, 19, DIM) end
			KbRoot.Size = UDim2.fromOffset(300, 56 + math.max(#items, 1) * 32 + 12)
		end

		local lastKb = 0
		RunService.Heartbeat:Connect(function()
			if not Gui.Parent then return end
			local on = kc.enabled
			KbRoot.Visible = on
			if on then
				KbRoot.GroupTransparency = 1 - math.clamp((kc.options.opacity or 100) / 100, 0.1, 1)
				local now = os.clock()
				if now - lastKb >= 0.25 then
					lastKb = now
					Rebuild()
				end
			end
		end)
	end

	local TeleportService = game:GetService("TeleportService")
	local function ServerNote(title, info)
		if Notifier then Notifier(title, info, "server", 3) end
	end
	local function FetchServerPage(cursor)
		local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
		if type(cursor) == "string" and cursor ~= "" then url ..= "&cursor=" .. cursor end
		local ok, body = pcall(function() return game:HttpGet(url) end)
		if not ok or type(body) ~= "string" or body == "" then return nil end
		local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
		if not ok2 or type(data) ~= "table" then return nil end
		return data
	end
	local function EachServer(fn)
		local cursor = nil
		for _ = 1, 5 do
			local data = FetchServerPage(cursor)
			if not data or type(data.data) ~= "table" then break end
			for _, s in ipairs(data.data) do
				if type(s) == "table" and s.id ~= game.JobId then
					local playing, maxP = tonumber(s.playing), tonumber(s.maxPlayers)
					if playing and maxP and playing < maxP then
						if fn(s) == true then return end
					end
				end
			end
			if type(data.nextPageCursor) ~= "string" or data.nextPageCursor == "" then break end
			cursor = data.nextPageCursor
		end
	end
	local function HopToServer(id, label)
		local ok, err = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, tostring(id)) end)
		if ok then ServerNote(label, "joining...") else ServerNote("teleport failed", tostring(err)) end
	end
	local function RejoinServer()
		local ok, err = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
		if ok then ServerNote("rejoining", "joining...") else ServerNote("rejoin failed", tostring(err)) end
	end
	local function HopServer()
		local pool = {}
		EachServer(function(s) table.insert(pool, s.id) end)
		if #pool == 0 then ServerNote("server hop", "no servers found") return end
		HopToServer(pool[math.random(1, #pool)], "server hop")
	end
	local function JoinLowestPlayers()
		local best = nil
		EachServer(function(s)
			if best == nil or tonumber(s.playing) < tonumber(best.playing) then best = s end
		end)
		if not best then ServerNote("join lowest", "no servers found") return end
		HopToServer(best.id, "join lowest")
	end
	local function JoinLowestPing()
		local best, bestPing = nil, nil
		EachServer(function(s)
			local p = tonumber(s.ping)
			if p then
				if bestPing == nil or p < bestPing then best, bestPing = s, p end
			elseif best == nil then best = s end
		end)
		if not best then ServerNote("join lowest ping", "no servers found") return end
		HopToServer(best.id, "join lowest ping")
	end

	function WindowObj:CreateSettingSystem()
		if WindowObj._hasSettings then return end
		WindowObj._hasSettings = true
		WmOpts = {
			Spec({ Type = "MultiDropdown", Name = "show", List = { "fps", "ping", "time", "name" }, Default = { "fps", "ping" } }),
			Spec({ Type = "Input", Name = "icon", Placeholder = "lucide icon...", Default = Logo }),
			Spec({ Type = "Toggle", Name = "custom color", Default = false }),
			Spec({ Type = "ColorPicker", Name = "color" }),
		}
		local wc = Cfg("watermark")
		wc.kind = "toggle"
		wc.enabled = true
		
		local function build(label, fn)
		local ok, err = pcall(fn)
		if not ok then warn("[Paw] settings '" .. tostring(label) .. "' failed: " .. tostring(err)) end
		end

		local side = WindowObj:Tab(WindowObj, { Icon = "sliders-horizontal" })
		local sub = side:SubTab({ Name = "settings", Icon = "sliders-horizontal" })

		build("menu", function()
		local menu = sub:Section({ Name = "menu", Side = "Left", Icon = "sliders-horizontal" })
		Cfg("menu key").bind = MenuKey
		local menuKeyEntry = InlineEntry({ t = "keybind", n = "menu key", def = MenuKey })
		local origMenuSet = menuKeyEntry.set
		menuKeyEntry.set = function(v)
			origMenuSet(v)
			if v then MenuKey = v end
		end
		AddEntry(menu, menuKeyEntry)
		AddEntry(menu, InlineEntry({ t = "slider", n = "tween speed", min = 25, max = 200, def = 100, suf = "%", step = 5 }))
		AddEntry(menu, InlineEntry({ t = "dropdown", n = "easing style", list = EaseList, def = "Quart" }))
		AddEntry(menu, { t = "color", n = "accent color", get = function() return Accent end, set = SetAccent })
		end)

		build("keybinds", function()
		local kb = sub:Section({ Name = "keybinds", Side = "Left", Icon = "keyboard" })
		kb:Toggle({ Name = "show keybinds", Flag = "keybind list", Default = true })
		AddEntry(kb, { t = "slider", n = "opacity", min = 10, max = 100, suf = "%", step = 5,
			get = function() return Cfg("keybind list").options.opacity or 100 end,
			set = function(v) Cfg("keybind list").options.opacity = v end })
		end)

		build("watermark", function()
		local wm = sub:Section({ Name = "watermark", Side = "Right", Icon = "eye" })
		wm:Toggle({ Name = "watermark", Default = true, Options = WmOpts })
		end)

		build("server", function()
		local srv = sub:Section({ Name = "server", Side = "Right", Icon = "server" })
		srv:Button({ Name = "rejoin", Callback = RejoinServer })
		srv:Button({ Name = "server hop", Callback = HopServer })
		srv:Button({ Name = "join lowest players", Callback = JoinLowestPlayers })
		srv:Button({ Name = "join lowest ping", Callback = JoinLowestPing })
		end)

		build("configs", function()
		RefreshList()
		local cfg = sub:Section({ Name = "configs", Side = "Right", Icon = "file" })
		AddEntry(cfg, { t = "input", n = "config name", ph = "enter name...",
			get = function() return CfgName end, set = function(v) CfgName = v end })
		cfg:Button({ Name = "save config", Callback = function() Configs.Save(CfgName); RefreshAll() end })
		AddEntry(cfg, { t = "dropdown", n = "configs", list = CfgList,
			get = function() return CfgSel end, set = function(v) CfgSel = v end })
		cfg:Button({ Name = "load config", Callback = function() Configs.Load(CfgSel); RefreshAll() end })
		cfg:Button({ Name = "overwrite config", Callback = function() Configs.Overwrite(CfgSel); RefreshAll() end })
		cfg:Button({ Name = "set as autoload", Callback = function() Configs.SetAutoload(CfgSel); RefreshAll() end })
		cfg:Button({ Name = "remove autoload", Callback = function() Configs.RemoveAutoload(); RefreshAll() end })
		Configs.AutoLabel = AddEntry(cfg, { t = "label", n = "autoload: " .. (Store.GetAuto() or "none"), col = C.Off })
		UpdateAutoLabel()
		end)
	end

	if UIS.TouchEnabled then
		local T = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			Position = UDim2.new(0, 12, 0.5, -22), Size = UDim2.fromOffset(44, 44) }, Gui)
		Corner(T, 12)
		Grad(T, Color3.fromRGB(10, 6, 18), Color3.fromRGB(0, 0, 0), 90)
		Stroke(T, Color3.fromRGB(60, 30, 110), 1, 0.2)
		local TM = Icon(T, "rbxassetid://99047291822954", 22, 22, 26, WHITE)
		TM.ScaleType = Enum.ScaleType.Fit
		T.MouseButton1Click:Connect(function()
			Root.Visible = not Root.Visible
			if not Root.Visible then ClosePopup() end
		end)
	end

	task.delay(0.6, function()
		Notify("menu loaded", "press " .. KeyName(MenuKey) .. " to open or close the menu", Logo, 5)
	end)

	WindowObj.Config = Config
	WindowObj.Configs = Configs
	task.defer(function()
		pcall(function() WindowObj:CreateConfigSystem() end)
		pcall(function() WindowObj:CreateKeybindList() end)
		pcall(function() WindowObj:CreateSettingSystem() end)
	end)
	return WindowObj
end

return Library
