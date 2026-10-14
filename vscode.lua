local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local VSCode = {}

local Theme = {
	Title = Color3.fromRGB(24, 24, 24),
	Activity = Color3.fromRGB(24, 24, 24),
	Side = Color3.fromRGB(24, 24, 24),
	Editor = Color3.fromRGB(31, 31, 31),
	TabBar = Color3.fromRGB(24, 24, 24),
	TabActive = Color3.fromRGB(31, 31, 31),
	TabInactive = Color3.fromRGB(24, 24, 24),
	Status = Color3.fromRGB(0, 120, 212),
	Border = Color3.fromRGB(43, 43, 43),
	Input = Color3.fromRGB(49, 49, 49),
	InputBorder = Color3.fromRGB(68, 68, 68),
	Button = Color3.fromRGB(0, 120, 212),
	ButtonHover = Color3.fromRGB(2, 110, 193),
	Text = Color3.fromRGB(204, 204, 204),
	Bright = Color3.fromRGB(255, 255, 255),
	Dim = Color3.fromRGB(157, 157, 157),
	Faint = Color3.fromRGB(120, 120, 120),
	Accent = Color3.fromRGB(0, 120, 212),
	Green = Color3.fromRGB(137, 209, 133),
	Blue = Color3.fromRGB(79, 193, 255),
	Purple = Color3.fromRGB(197, 134, 192),
	Yellow = Color3.fromRGB(220, 220, 170),
	Hover = Color3.fromRGB(42, 45, 46),
	Select = Color3.fromRGB(4, 57, 94),
	Danger = Color3.fromRGB(231, 72, 86),
}

local function New(class, props)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then pcall(function() o[k] = v end) end
	end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function Corner(r, p) local c = New("UICorner", {CornerRadius = UDim.new(0, r or 5)}) c.Parent = p return c end
local function Stroke(c, t, p) local s = New("UIStroke", {Color = c, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) s.Parent = p return s end
local function Pad(x, y, p) local u = New("UIPadding", {PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, x), PaddingTop = UDim.new(0, y == nil and x or y), PaddingBottom = UDim.new(0, y == nil and x or y)}) u.Parent = p return u end
local function List(pad, dir, horiz, vert, p)
	local l = New("UIListLayout", {Padding = UDim.new(0, pad or 4), FillDirection = dir or Enum.FillDirection.Vertical, HorizontalAlignment = horiz or Enum.HorizontalAlignment.Left, VerticalAlignment = vert or Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder})
	l.Parent = p return l
end
local function fileColor(n)
	n = (n or ""):lower()
	if n:find("%.luau") then return Theme.Purple end
	if n:find("%.lua") then return Theme.Blue end
	if n:find("%.json") then return Theme.Yellow end
	if n:find("%.txt") then return Theme.Dim end
	return Theme.Green
end
local function safeCall(fn, ...)
	local a = {...}
	task.spawn(function() pcall(fn, table.unpack(a)) end)
end
local function resolveParent()
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	local lp = Players.LocalPlayer
	if lp then
		local ok2, pg = pcall(function() return lp:WaitForChild("PlayerGui", 3) end)
		if ok2 and pg then return pg end
		if lp:FindFirstChild("PlayerGui") then return lp.PlayerGui end
	end
	return CoreGui
end

local function rect(parent, sx, sy, px, py, color, round, rot)
	local f = New("Frame", {Size = UDim2.new(0, sx, 0, sy), Position = UDim2.new(0, px, 0, py), BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Parent = parent})
	if round then Corner(round, f) end
	if rot then f.Rotation = rot end
	return f
end
local function dot(parent, d, px, py, color)
	local f = New("Frame", {Size = UDim2.new(0, d, 0, d), Position = UDim2.new(0, px, 0, py), BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Parent = parent})
	Corner(math.floor(d / 2), f)
	return f
end

local function makeIcon(kind, size, color)
	size = size or 20
	color = color or Theme.Faint
	local w = New("Frame", {Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1, Name = "icon_" .. kind})
	local c = size / 2
	if kind == "explorer" then
		local outer = rect(w, size * 0.66, size * 0.72, c, c, color, 2)
		outer.BackgroundTransparency = 1
		Stroke(color, 2, outer)
		rect(w, 2, size * 0.6, c - 1, c, color, 0)
	elseif kind == "search" then
		local r = dot(w, size * 0.52, c - 2, c - 2, color)
		r.BackgroundTransparency = 1
		Stroke(color, 2, r)
		rect(w, size * 0.42, 2, c + 5, c + 5, color, 1, 45)
	elseif kind == "source" then
		rect(w, 2, size * 0.7, c, c, color, 1)
		dot(w, 6, c, c - size * 0.32, color)
		dot(w, 6, c, c + size * 0.32, color)
		rect(w, 2, size * 0.34, c + 3, c - 5, color, 1, 35)
		dot(w, 5, c + 6, c - 10, color)
	elseif kind == "run" then
		local t = New("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "▶", Font = Enum.Font.GothamBold, TextSize = math.floor(size * 0.72), TextColor3 = color, Parent = w})
		t.Position = UDim2.new(0, 1, 0, 0)
	elseif kind == "ext" then
		local s, g = size * 0.32, size * 0.38
		rect(w, s, s, c - g / 2, c - g / 2, color, 1)
		rect(w, s, s, c + g / 2, c - g / 2, color, 1)
		rect(w, s, s, c - g / 2, c + g / 2, color, 1)
		rect(w, s, s, c + g / 2, c + g / 2, color, 1)
	elseif kind == "account" then
		dot(w, size * 0.4, c, c - 4, color)
		rect(w, size * 0.62, size * 0.3, c, c + 6, color, 4)
	elseif kind == "gear" then
		rect(w, size * 0.7, 3, c, c, color, 1)
		rect(w, 3, size * 0.7, c, c, color, 1)
		rect(w, size * 0.55, 3, c, c, color, 1, 45)
		rect(w, size * 0.55, 3, c, c, color, 1, -45)
		local m = dot(w, size * 0.42, c, c, color)
		m.BackgroundTransparency = 1
		m.Name = "ring"
		Stroke(color, 2, m)
	elseif kind == "file" then
		rect(w, size * 0.55, size * 0.75, c, c, color, 1)
		rect(w, size * 0.45, 2, c, c - 4, Theme.Activity, 0)
		rect(w, size * 0.45, 2, c, c, Theme.Activity, 0)
		rect(w, size * 0.45, 2, c, c + 4, Theme.Activity, 0)
	elseif kind == "close" then
		rect(w, size * 0.6, 2, c, c, color, 1, 45)
		rect(w, size * 0.6, 2, c, c, color, 1, -45)
	elseif kind == "chevD" then
		rect(w, size * 0.4, 2, c - 3, c - 1, color, 1, 45)
		rect(w, size * 0.4, 2, c + 3, c - 1, color, 1, -45)
	elseif kind == "chevR" then
		rect(w, 2, size * 0.32, c + 1, c - 3, color, 1, 45)
		rect(w, 2, size * 0.32, c + 1, c + 3, color, 1, -45)
	elseif kind == "bell" then
		rect(w, size * 0.44, size * 0.5, c, c - 2, color, 3)
		dot(w, 4, c, c + 8, color)
	elseif kind == "check" then
		local t = New("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "✓", Font = Enum.Font.GothamBold, TextSize = math.floor(size * 0.8), TextColor3 = color, Parent = w})
	else
		dot(w, size * 0.3, c, c, color)
	end
	return w
end

local function paintIcon(icon, color)
	for _, d in ipairs(icon:GetDescendants()) do
		if d:IsA("Frame") then
			if d.BackgroundTransparency >= 1 then continue end
			if d.Name == "cut" or d.Name == "ring" then continue end
			d.BackgroundColor3 = color
		elseif d:IsA("TextLabel") then
			d.TextColor3 = color
		elseif d:IsA("UIStroke") then
			d.Color = color
		end
	end
end

function VSCode:CreateWindow(opt)
	opt = opt or {}
	local title = opt.Title or "ExternalNew"
	local toggleKey = opt.ToggleKey or Enum.KeyCode.RightShift
	local accent = opt.Accent or Theme.Status

	local parent = resolveParent()
	if getgenv and getgenv().VSCodeGui then pcall(function() getgenv().VSCodeGui:Destroy() end) end
	local Gui = New("ScreenGui", {Name = "VSCode_" .. tostring(math.random(100000, 999999)), ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parent})
	if getgenv then getgenv().VSCodeGui = Gui end
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(Gui) end end)

	local Win = {Tabs = {}, TabsMap = {}, Flags = {}, Handles = {}, Binds = {}, Current = nil, _openDrop = nil, _pendingKey = nil, _onExec = nil, _onAttach = nil, _sideOpen = true, _miniOpen = true}

	local Main = New("Frame", {Size = UDim2.new(0, 940, 0, 600), Position = UDim2.new(0.5, -470, 0.5, -300), BackgroundColor3 = Theme.Editor, BorderSizePixel = 0, Active = true, ClipsDescendants = true, Parent = Gui})
	Corner(8, Main) Stroke(Theme.Border, 1, Main)

	local TitleBar = New("Frame", {Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Theme.Title, BorderSizePixel = 0, Parent = Main})
	local MenuRow = New("Frame", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = TitleBar})
	Pad(10, 0, MenuRow) List(0, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center, MenuRow)

	local SearchWrap = New("Frame", {Size = UDim2.new(0, 330, 0, 24), Position = UDim2.new(0.5, -165, 0.5, -12), BackgroundColor3 = Color3.fromRGB(36, 36, 36), BorderSizePixel = 0, Parent = TitleBar})
	Corner(6, SearchWrap) Stroke(Color3.fromRGB(58, 58, 58), 1, SearchWrap)
	local sIco = makeIcon("search", 14, Theme.Faint) sIco.Position = UDim2.new(0, 16, 0.5, -7) sIco.Parent = SearchWrap
	local SearchBox = New("TextBox", {Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 30, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = title .. "  —  Ctrl+P", PlaceholderColor3 = Theme.Faint, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 11, ClearTextOnFocus = false, Parent = SearchWrap})

	local WC = New("Frame", {Size = UDim2.new(0, 138, 1, 0), Position = UDim2.new(1, -138, 0, 0), BackgroundTransparency = 1, Parent = TitleBar})
	List(0, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center, WC)
	local function winBtn(glyphKind, glyphText, red)
		local b = New("TextButton", {Size = UDim2.new(0, 46, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = WC})
		if glyphKind then local ic = makeIcon(glyphKind, 13, Theme.Text) ic.Position = UDim2.new(0.5, -6.5, 0.5, -6.5) ic.Parent = b
		else New("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = glyphText, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text, Parent = b}) end
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 b.BackgroundColor3 = red and Color3.fromRGB(232, 17, 35) or Color3.fromRGB(58, 58, 58) end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		return b
	end
	local btnMin = winBtn(nil, "─")
	local btnMax = winBtn(nil, "□")
	local btnX = winBtn("close", nil, true)

	local Body = New("Frame", {Size = UDim2.new(1, 0, 1, -59), Position = UDim2.new(0, 0, 0, 35), BackgroundTransparency = 1, Parent = Main})
	local Activity = New("Frame", {Size = UDim2.new(0, 48, 1, 0), BackgroundColor3 = Theme.Activity, BorderSizePixel = 0, Parent = Body})
	local Side = New("Frame", {Size = UDim2.new(0, 205, 1, 0), Position = UDim2.new(0, 48, 0, 0), BackgroundColor3 = Theme.Side, BorderSizePixel = 0, ClipsDescendants = true, Parent = Body})
	local EditorWrap = New("Frame", {Size = UDim2.new(1, -253, 1, 0), Position = UDim2.new(0, 253, 0, 0), BackgroundColor3 = Theme.Editor, BorderSizePixel = 0, ClipsDescendants = true, Parent = Body})

	local function layoutEditor()
		local left = Win._sideOpen and 253 or 48
		local right = left
		EditorWrap.Position = UDim2.new(0, left, 0, 0)
		EditorWrap.Size = UDim2.new(1, -left, 1, 0)
		Side.Visible = Win._sideOpen
		Side.Size = UDim2.new(0, 205, 1, 0)
	end

	local dragOn, dragSP, dragGP = false, nil, nil
	TitleBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragOn, dragSP, dragGP = true, Main.Position, i.Position end
	end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragOn = false end end)
	UserInputService.InputChanged:Connect(function(i)
		if dragOn and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - dragGP
			Main.Position = UDim2.new(dragSP.X.Scale, dragSP.X.Offset + d.X, dragSP.Y.Scale, dragSP.Y.Offset + d.Y)
			if Win._openDrop then Win:CloseDrops() end
		end
	end)

	local minimized, full = false, false
	local oldSize, oldPos = Main.Size, Main.Position
	btnX.MouseButton1Click:Connect(function() Gui.Enabled = false end)
	btnMin.MouseButton1Click:Connect(function()
		minimized = not minimized
		Body.Visible = not minimized
		Main.Size = minimized and UDim2.new(0, Main.Size.X.Offset, 0, 59) or oldSize
		if not minimized then Main.Size, Main.Position = oldSize, oldPos end
	end)
	btnMax.MouseButton1Click:Connect(function()
		full = not full
		if full then oldSize, oldPos = Main.Size, Main.Position Main.Size = UDim2.new(1, -60, 1, -60) Main.Position = UDim2.new(0, 30, 0, 30)
		else Main.Size, Main.Position = oldSize, oldPos end
	end)

	local actBtns = {}
	local actIcons = {}
	local acts = {{"explorer", "Explorer"}, {"search", "Search"}, {"source", "Source Control"}, {"run", "Run and Debug"}, {"ext", "Extensions"}}
	for i, v in ipairs(acts) do
		local b = New("TextButton", {Size = UDim2.new(1, 0, 0, 50), Position = UDim2.new(0, 0, 0, (i - 1) * 50), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = Activity})
		local ic = makeIcon(v[1], 21, i == 1 and Theme.Bright or Theme.Faint) ic.Position = UDim2.new(0.5, -10.5, 0.5, -10.5) ic.Parent = b
		actIcons[b] = ic
		if i == 1 then New("Frame", {Name = "Sel", Size = UDim2.new(0, 2, 0, 32), Position = UDim2.new(0, 0, 0.5, -16), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = b}) end
		b.MouseEnter:Connect(function() local o = actIcons[b] if o then paintIcon(o, Theme.Bright) end end)
		b.MouseLeave:Connect(function()
			local sel = b:FindFirstChild("Sel") ~= nil
			paintIcon(actIcons[b], sel and Theme.Bright or Theme.Faint)
		end)
		b.MouseButton1Click:Connect(function()
			for _, o in ipairs(actBtns) do
				if o:FindFirstChild("Sel") then o.Sel:Destroy() end
				paintIcon(actIcons[o], Theme.Faint)
			end
			New("Frame", {Name = "Sel", Size = UDim2.new(0, 2, 0, 32), Position = UDim2.new(0, 0, 0.5, -16), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = b})
			paintIcon(ic, Theme.Bright)
			if v[2] == "Explorer" then Win._sideOpen = true else Win._sideOpen = (v[2] ~= "Explorer" and false or true) end
			if v[2] ~= "Explorer" then Win._sideOpen = false Win:Notify({Title = v[2], Message = "Panel is decorative in this build. Explorer holds your scripts."}) else Win._sideOpen = true end
			layoutEditor()
		end)
		actBtns[i] = b
	end
	local accB = New("TextButton", {Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -88), BackgroundTransparency = 1, Text = "", Parent = Activity})
	local a1 = makeIcon("account", 19, Theme.Faint) a1.Position = UDim2.new(0.5, -9.5, 0.5, -9.5) a1.Parent = accB
	local setB = New("TextButton", {Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -44), BackgroundTransparency = 1, Text = "", Parent = Activity})
	local s1 = makeIcon("gear", 19, Theme.Faint) s1.Position = UDim2.new(0.5, -9.5, 0.5, -9.5) s1.Parent = setB
	setB.MouseButton1Click:Connect(function() Win:Palette() end)

	local SideList = New("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = Side})
	List(0, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, SideList)
	New("TextLabel", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "    EXPLORER", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Left, Parent = SideList, LayoutOrder = 1})
	local projH = New("TextButton", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = SideList, LayoutOrder = 2})
	New("TextLabel", {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "⌄ " .. string.upper(title), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = projH})
	local FileList = New("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = SideList, LayoutOrder = 3})
	List(1, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, FileList)
	local con = New("UISizeConstraint", {MaxSize = Vector2.new(9999, 300), Parent = FileList})
	local projOpen = true
	projH.MouseButton1Click:Connect(function() projOpen = not projOpen FileList.Visible = projOpen projH:GetChildren()[1].Text = (projOpen and "⌄ " or "› ") .. string.upper(title) end)
	for oi, sec in ipairs({"OUTLINE", "TIMELINE"}) do
		local h = New("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = SideList, LayoutOrder = 10 + oi})
		New("TextLabel", {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "› " .. sec, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Left, Parent = h})
		h.MouseButton1Click:Connect(function() Win:Notify(sec .. " is empty") end)
	end

	local TabBar = New("Frame", {Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Theme.TabBar, BorderSizePixel = 0, Parent = EditorWrap})
	local TabHold = New("ScrollingFrame", {Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X, Parent = TabBar})
	List(1, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, TabHold)
	local Crumb = New("Frame", {Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 35), BackgroundColor3 = Theme.Editor, BorderSizePixel = 0, Parent = EditorWrap})
	New("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = Crumb})
	local CrumbPath = New("TextLabel", {Size = UDim2.new(1, -190, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = title .. " › welcome", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Crumb})
	local FilterBox = New("TextBox", {Size = UDim2.new(0, 160, 0, 19), Position = UDim2.new(1, -170, 0.5, -9.5), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Faint, PlaceholderText = "Filter settings", Text = "", Font = Enum.Font.Gotham, TextSize = 10, ClearTextOnFocus = false, Parent = Crumb})
	Corner(4, FilterBox) Pad(8, 2, FilterBox)
	local PageHold = New("Frame", {Size = UDim2.new(1, 0, 1, -60), Position = UDim2.new(0, 0, 0, 60), BackgroundTransparency = 1, ClipsDescendants = true, Parent = EditorWrap})
	local MiniMap = New("Frame", {Size = UDim2.new(0, 62, 1, -68), Position = UDim2.new(1, -62, 0, 64), BackgroundColor3 = Theme.Editor, BackgroundTransparency = 0, BorderSizePixel = 0, Active = false, Parent = EditorWrap})
	New("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, BackgroundTransparency = 0.5, Parent = MiniMap})
	for i = 1, 52 do
		local indent = math.random(0, 4) * 5
		local wdt = math.random(14, 44 - indent)
		New("Frame", {Size = UDim2.new(0, wdt, 0, 2), Position = UDim2.new(0, 5 + indent, 0, 4 + (i - 1) * 9), BackgroundColor3 = ({Theme.Blue, Theme.Green, Theme.Yellow, Theme.Purple, Color3.fromRGB(110, 110, 110)})[math.random(1, 5)], BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = MiniMap})
	end

	local StatusBar = New("Frame", {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -24), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = Main})
	local SL = New("Frame", {Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Parent = StatusBar})
	List(2, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center, SL)
	local SR = New("Frame", {Size = UDim2.new(0.4, -12, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1, Parent = StatusBar})
	List(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center, SR)
	local function statBtn(txt, left, bold)
		local b = New("TextButton", {AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, Text = " " .. txt .. " ", Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Bright, AutoButtonColor = false, Parent = left and SL or SR})
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.7 b.BackgroundColor3 = Theme.Bright end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		return b
	end
	local stRemote = statBtn("><", true, true)
	local stBranch = statBtn("⎇ main*", true)
	local stErr = statBtn("⊗ 0  ⚠ 0", true)
	local stExec = statBtn("▷ Execute", true)
	local stAttach = statBtn("⇄ Attach", true)
	local stLn = statBtn("Ln 1, Col 1", false)
	local stSp = statBtn("Spaces: 4", false)
	local stEnc = statBtn("UTF-8", false)
	local stLang = statBtn("{} Lua", false)

	local ClickBlock = New("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Visible = false, ZIndex = 39, Parent = Main})

	local Toasts = New("Frame", {Size = UDim2.new(0, 330, 0, 300), Position = UDim2.new(1, -340, 1, -34), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, Parent = Main})
	List(8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Bottom, Toasts)

	local Palette = New("Frame", {Size = UDim2.new(0, 500, 0, 330), Position = UDim2.new(0.5, -250, 0, 44), BackgroundColor3 = Color3.fromRGB(37, 37, 38), BorderSizePixel = 0, Visible = false, ZIndex = 60, Parent = Main})
	Corner(8, Palette) Stroke(Theme.Border, 1, Palette)
	local PIn = New("TextBox", {Size = UDim2.new(1, -16, 0, 32), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Dim, PlaceholderText = "> file, command...", Text = "", Font = Enum.Font.Code, TextSize = 12, ClearTextOnFocus = false, Parent = Palette})
	Corner(6, PIn) Pad(10, 4, PIn)
	local PList = New("ScrollingFrame", {Size = UDim2.new(1, -16, 1, -56), Position = UDim2.new(0, 8, 0, 48), BackgroundTransparency = 1, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Palette})
	List(2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, PList)

	function Win:CloseDrops()
		if self._openDrop then pcall(function() self._openDrop:Destroy() end) self._openDrop = nil end
		ClickBlock.Visible = false
	end
	ClickBlock.MouseButton1Click:Connect(function() Win:CloseDrops() Palette.Visible = false end)

	function Win:Notify(o)
		o = type(o) == "string" and {Message = o} or o
		local box = New("CanvasGroup", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(37, 37, 38), BackgroundTransparency = 0, GroupTransparency = 1, BorderSizePixel = 0, Parent = Toasts})
		Corner(6, box) Stroke(Theme.Border, 1, box)
		New("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = box})
		New("TextLabel", {Size = UDim2.new(1, -46, 0, 18), Position = UDim2.new(0, 30, 0, 6), BackgroundTransparency = 1, Text = o.Title or title, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Bright, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = box})
		local xb = New("TextButton", {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -28, 0, 2), BackgroundTransparency = 1, Text = "×", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Theme.Dim, Parent = box})
		xb.MouseButton1Click:Connect(function() box:Destroy() end)
		New("TextLabel", {Size = UDim2.new(1, -44, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 30, 0, 24), BackgroundTransparency = 1, Text = o.Message or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, TextYAlignment = Top, TextWrapped = true, Parent = box})
		if o.Actions then
			local ar = New("Frame", {Size = UDim2.new(1, -44, 0, 28), Position = UDim2.new(0, 30, 1, -32), BackgroundTransparency = 1, Parent = box})
			Pad(0, 0, ar) List(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center, ar)
			for _, a in ipairs(o.Actions) do
				local ab = New("TextButton", {Size = UDim2.new(0, 0, 0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.Button, TextColor3 = Theme.Bright, Text = "  " .. a.Text .. "  ", Font = Enum.Font.Gotham, TextSize = 11, Parent = ar})
				Corner(4, ab)
				ab.MouseButton1Click:Connect(function() safeCall(a.Callback or function() end) box:Destroy() end)
			end
		else
			Pad(0, 0, box) local p = box:FindFirstChildOfClass("UIPadding") if p then p.PaddingBottom = UDim.new(0, 10) end
		end
		TweenService:Create(box, TweenInfo.new(0.2), {GroupTransparency = 0}):Play()
		task.delay(o.Duration or 4.5, function() pcall(function() TweenService:Create(box, TweenInfo.new(0.25), {GroupTransparency = 1}):Play() task.wait(0.26) box:Destroy() end) end)
	end

	local palItems, palSel = {}, 1
	local function fuzzy(hay, needle)
		hay, needle = hay:lower(), needle:lower()
		if needle == "" then return true end
		local hi = 1
		for i = 1, #needle do
			hi = hay:find(needle:sub(i, i), hi, true)
			if not hi then return false end
			hi = hi + 1
		end
		return true
	end
	local function refreshPalette()
		for _, c in ipairs(PList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		palItems = {}
		local q = PIn.Text:gsub("^>%s*", "")
		local function addRow(icon, text, sub, fn, col)
			if not fuzzy(text .. " " .. (sub or ""), q) then return end
			local b = New("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", Parent = PList})
			if col then local ic = makeIcon("file", 14, col) ic.Position = UDim2.new(0, 8, 0.5, -7) ic.Parent = b
			else New("TextLabel", {Size = UDim2.new(0, 26, 1, 0), Position = UDim2.new(0, 4, 0, 0), BackgroundTransparency = 1, Text = icon, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Dim, Parent = b}) end
			New("TextLabel", {Size = UDim2.new(1, -40, 0, 16), Position = UDim2.new(0, 30, 0, 2), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b})
			if sub then New("TextLabel", {Size = UDim2.new(1, -40, 0, 12), Position = UDim2.new(0, 30, 0, 17), BackgroundTransparency = 1, Text = sub, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.Dim, TextXAlignment = Left, Parent = b}) end
			table.insert(palItems, {Btn = b, Fn = fn})
			b.MouseButton1Click:Connect(function() Palette.Visible = false safeCall(fn) end)
		end
		for _, tb in ipairs(Win.Tabs) do addRow("◈", tb.Name, "open file", function() Win:SelectTab(tb.Name) end, fileColor(tb.Name)) end
		addRow("▷", "Execute current file", "run", function() Win:FireExecute() end)
		addRow("⇄", "Attach", "executor", function() Win:FireAttach() end)
		addRow("◫", "Toggle sidebar", "view", function() Win._sideOpen = not Win._sideOpen layoutEditor() end)
		addRow("◈", "Toggle minimap", "view", function() Win._miniOpen = not Win._miniOpen MiniMap.Visible = Win._miniOpen Win:LayoutPages() end)
		palSel = 1
		for i, it in ipairs(palItems) do
			it.Btn.BackgroundTransparency = (i == 1) and 0 or 1
			if i == 1 then it.Btn.BackgroundColor3 = Theme.Hover end
		end
	end
	PIn:GetPropertyChangedSignal("Text"):Connect(refreshPalette)
	function Win:Palette() Palette.Visible = not Palette.Visible if Palette.Visible then self:CloseDrops() PIn.Text = "" refreshPalette() PIn:CaptureFocus() end end

	local menus = {
		File = {{"New Tab", function() Win:NewTab("untitled-" .. (#Win.Tabs + 1) .. ".lua") end}, {"Close Tab", function() if Win.Current then Win:CloseTab(Win.Current.Name) end end}, {"Hide UI  (RightShift)", function() Win:Toggle() end}},
		View = {{"Command Palette", function() Win:Palette() end}, {"Toggle Sidebar", function() Win._sideOpen = not Win._sideOpen layoutEditor() end}, {"Toggle Minimap", function() Win._miniOpen = not Win._miniOpen MiniMap.Visible = Win._miniOpen Win:LayoutPages() end}},
		Run = {{"Execute", function() Win:FireExecute() end}, {"Attach", function() Win:FireAttach() end}},
		Help = {{"Test Notification", function() Win:Notify({Title = title, Message = "UI build OK. " .. #Win.Tabs .. " tabs open."}) end}},
	}
	for _, name in ipairs({"File", "Edit", "Selection", "View", "Go", "Run", "Terminal", "Help"}) do
		local b = New("TextButton", {Size = UDim2.new(0, 0, 0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = " " .. name .. " ", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, AutoButtonColor = false, Parent = MenuRow})
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 b.BackgroundColor3 = Theme.Hover end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		b.MouseButton1Click:Connect(function()
			local items = menus[name]
			if not items then Win:Notify(name .. " has no actions in this build") return end
			Win:CloseDrops()
			local m = New("Frame", {Size = UDim2.new(0, 220, 0, #items * 28 + 8), Position = UDim2.new(0, b.AbsolutePosition.X - Main.AbsolutePosition.X, 0, 35), BackgroundColor3 = Color3.fromRGB(37, 37, 38), ZIndex = 50, Parent = Main})
			Corner(6, m) Stroke(Theme.Border, 1, m)
			List(0, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, m) Pad(4, 4, m)
			for _, it in ipairs(items) do
				local ib = New("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "  " .. it[1], Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = m})
				ib.MouseEnter:Connect(function() ib.BackgroundTransparency = 0 ib.BackgroundColor3 = Theme.Hover end)
				ib.MouseLeave:Connect(function() ib.BackgroundTransparency = 1 end)
				ib.MouseButton1Click:Connect(function() Win:CloseDrops() safeCall(it[2]) end)
			end
			Win._openDrop = m ClickBlock.Visible = true
		end)
	end

	function Win:LayoutPages()
		for _, t in ipairs(self.Tabs) do
			t.Page.Size = self._miniOpen and UDim2.new(1, -76, 1, -10) or UDim2.new(1, -16, 1, -10)
		end
	end
	function Win:FireExecute()
		if self._onExec then safeCall(self._onExec, self.Current and self.Current.Name) end
		self:Notify({Title = "Run", Message = "Executed " .. (self.Current and self.Current.Name or "script")})
	end
	function Win:FireAttach()
		if self._onAttach then safeCall(self._onAttach) end
		self:Notify({Title = "Attach", Message = "Attached to Roblox"})
	end
	function Win:OnExecute(fn) self._onExec = fn end
	function Win:OnAttach(fn) self._onAttach = fn end
	stExec.MouseButton1Click:Connect(function() Win:FireExecute() end)
	stAttach.MouseButton1Click:Connect(function() Win:FireAttach() end)
	stBranch.MouseButton1Click:Connect(function() Win:Notify("⎇ main* — clean") end)
	stErr.MouseButton1Click:Connect(function() Win:Notify("0 errors, 0 warnings") end)

	local sliderDrag = nil
	UserInputService.InputChanged:Connect(function(i)
		if sliderDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
			local bar, fn = sliderDrag[1], sliderDrag[2]
			if bar and bar.Parent then
				local pr = math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
				fn(pr)
			else sliderDrag = nil end
		end
	end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliderDrag = nil end end)

	UserInputService.InputBegan:Connect(function(i, g)
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if Palette.Visible and not g then
			if i.KeyCode == Enum.KeyCode.Up or i.KeyCode == Enum.KeyCode.Down then
				palSel = math.clamp(palSel + (i.KeyCode == Enum.KeyCode.Down and 1 or -1), 1, math.max(1, #palItems))
				for n, it in ipairs(palItems) do it.Btn.BackgroundTransparency = (n == palSel) and 0 or 1 if n == palSel then it.Btn.BackgroundColor3 = Theme.Hover end end
				return
			elseif i.KeyCode == Enum.KeyCode.Enter then
				local it = palItems[palSel] if it then Palette.Visible = false safeCall(it.Fn) end return
			elseif i.KeyCode == Enum.KeyCode.Escape then Palette.Visible = false return
			end
		end
		if Win._pendingKey and not g then
			local h = Win.Handles[Win._pendingKey]
			if h and h._keyBtn then
				if i.KeyCode == Enum.KeyCode.Escape then h:Set(h:Get())
				elseif i.KeyCode == Enum.KeyCode.Backspace then h:Set(nil)
				else h:Set(i.KeyCode) end
			end
			Win._pendingKey = nil
			return
		end
		if g then return end
		if i.KeyCode == toggleKey then Win:Toggle() return end
		if i.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then Win:Palette() return end
		for _, bd in ipairs(Win.Binds) do
			if bd.Key and i.KeyCode == bd.Key then safeCall(bd.Callback, i.KeyCode) end
		end
	end)

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = SearchBox.Text:lower()
		for _, t in ipairs(Win.Tabs) do t.Row.Visible = q == "" or t.Name:lower():find(q, 1, true) ~= nil end
		if SearchBox.Text:sub(1, 1) == ">" then if not Palette.Visible then Win:Palette() end PIn.Text = SearchBox.Text end
	end)
	FilterBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = FilterBox.Text:lower()
		local cur = Win.Current
		if not cur or not cur.Api then return end
		for _, c in ipairs(cur.Api._controls) do
			c.Visible = q == "" or (c:GetAttribute("search") or ""):lower():find(q, 1, true) ~= nil
		end
	end)

	local Ctrl = {}
	local function reg(api, frame, search)
		frame:SetAttribute("search", search or "")
		table.insert(api._controls, frame)
		return frame
	end
	local function rowBox(api, h, search)
		local r = New("Frame", {Size = UDim2.new(1, 0, 0, h or 36), BackgroundTransparency = 1, Parent = api._group})
		reg(api, r, search)
		r.MouseEnter:Connect(function() r.BackgroundTransparency = 0.85 r.BackgroundColor3 = Theme.Hover end)
		r.MouseLeave:Connect(function() r.BackgroundTransparency = 1 end)
		return r
	end
	local function flagKey(o)
		return o.Flag or o.Name or ("ctrl_" .. tostring(math.random(100000, 999999)))
	end
	local function track(api, key, val, handle)
		Win.Flags[key] = val
		Win.Handles[key] = handle
	end

	function Ctrl:AddSection(name)
		local open = true
		local h = New("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = self.Page})
		local ch = makeIcon("chevD", 13, Theme.Bright) ch.Position = UDim2.new(0, 10, 0.5, -6.5) ch.Parent = h
		New("TextLabel", {Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 28, 0, 0), BackgroundTransparency = 1, Text = (name or "Section"):upper(), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Bright, TextXAlignment = Left, Parent = h})
		local g = New("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self.Page})
		List(2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, g)
		self._group = g
		h.MouseButton1Click:Connect(function()
			open = not open g.Visible = open ch:Destroy()
			ch = makeIcon(open and "chevD" or "chevR", 13, Theme.Bright) ch.Position = UDim2.new(0, 10, 0.5, -6.5) ch.Parent = h
		end)
		return h
	end
	function Ctrl:AddDivider()
		local f = New("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = self._group})
		reg(self, f, "")
		return f
	end
	function Ctrl:AddLabel(txt, sub)
		local w = New("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self._group})
		reg(self, w, (txt or "") .. " " .. (sub or ""))
		New("TextLabel", {Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = txt or "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextWrapped = true, Parent = w})
		local s
		if sub then s = New("TextLabel", {Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = sub, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Left, TextWrapped = true, Parent = w}) end
		List(2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, w)
		return w
	end
	function Ctrl:AddButton(o)
		o = type(o) == "string" and {Name = o} or o
		local r = rowBox(self, 40, o.Name)
		local secondary = o.Style == "secondary"
		local b = New("TextButton", {Size = UDim2.new(0, math.clamp(o.Width or 200, 80, 400), 0, 29), Position = UDim2.new(0, 4, 0, 5), BackgroundColor3 = secondary and Theme.Input or Theme.Button, TextColor3 = Theme.Bright, Text = o.Name or "Execute", Font = Enum.Font.Gotham, TextSize = 12, AutoButtonColor = false, Parent = r})
		Corner(4, b) if secondary then Stroke(Theme.InputBorder, 1, b) end
		b.MouseEnter:Connect(function() b.BackgroundColor3 = secondary and Color3.fromRGB(62, 62, 62) or Theme.ButtonHover end)
		b.MouseLeave:Connect(function() b.BackgroundColor3 = secondary and Theme.Input or Theme.Button end)
		b.MouseButton1Click:Connect(function() safeCall(o.Callback or function() end) end)
		local h = {Frame = r, Fire = function() safeCall(o.Callback or function() end) end}
		local key = flagKey(o) track(self, key, true, h)
		return h
	end
	function Ctrl:AddToggle(o)
		local val = o.Default and true or false
		local cb = o.Callback or function() end
		local key = flagKey(o)
		local r = rowBox(self, o.Desc and 44 or 34, (o.Name or "") .. " " .. (o.Desc or ""))
		New("TextLabel", {Size = UDim2.new(1, -120, 0, 16), Position = UDim2.new(0, 6, 0, o.Desc and 2 or 9), BackgroundTransparency = 1, Text = o.Name or "Toggle", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		if o.Desc then New("TextLabel", {Size = UDim2.new(1, -120, 0, 14), Position = UDim2.new(0, 6, 0, 20), BackgroundTransparency = 1, Text = o.Desc, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.Dim, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r}) end
		local box = New("TextButton", {Size = UDim2.new(0, 36, 0, 20), Position = UDim2.new(1, -44, 0, 7), BackgroundColor3 = val and accent or Color3.fromRGB(62, 62, 62), Text = "", AutoButtonColor = false, Parent = r})
		Corner(10, box)
		local knob = New("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = val and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = Theme.Bright, BorderSizePixel = 0, Parent = box})
		Corner(7, knob)
		local h
		local function set(_, v)
			if v == nil then v = _ end
			val = v and true or false
			TweenService:Create(box, TweenInfo.new(0.15), {BackgroundColor3 = val and accent or Color3.fromRGB(62, 62, 62)}):Play()
			TweenService:Create(knob, TweenInfo.new(0.15), {Position = val and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}):Play()
			Win.Flags[key] = val
			safeCall(cb, val)
		end
		box.MouseButton1Click:Connect(function() set(nil, not val) end)
		h = {Frame = r, Set = set, Get = function() return val end}
		track(self, key, val, h)
		if val then safeCall(cb, val) end
		return h
	end
	function Ctrl:AddCheck(o)
		local val = o.Default and true or false
		local cb = o.Callback or function() end
		local key = flagKey(o)
		local r = rowBox(self, 30, o.Name)
		local box = New("TextButton", {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 6, 0.5, -9), BackgroundColor3 = val and accent or Theme.Input, Text = "", AutoButtonColor = false, Parent = r})
		Corner(4, box) Stroke(val and accent or Theme.InputBorder, 1, box)
		local mark = New("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "✓", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Bright, Visible = val, Parent = box})
		New("TextLabel", {Size = UDim2.new(1, -34, 1, 0), Position = UDim2.new(0, 30, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Check", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local h
		local function set(_, v)
			if v == nil then v = _ end
			val = v and true or false
			box.BackgroundColor3 = val and accent or Theme.Input
			mark.Visible = val
			Win.Flags[key] = val
			safeCall(cb, val)
		end
		box.MouseButton1Click:Connect(function() set(nil, not val) end)
		h = {Frame = r, Set = set, Get = function() return val end}
		track(self, key, val, h)
		return h
	end
	function Ctrl:AddSlider(o)
		local min, max = o.Min or 0, o.Max or 100
		local step = o.Step or 1
		local val = o.Default == nil and min or math.clamp(o.Default, min, max)
		local cb = o.Callback or function() end
		local key = flagKey(o)
		local suf = o.Suffix or ""
		local r = rowBox(self, 54, o.Name)
		New("TextLabel", {Size = UDim2.new(1, -76, 0, 18), Position = UDim2.new(0, 6, 0, 2), BackgroundTransparency = 1, Text = o.Name or "Slider", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local badge = New("TextLabel", {Size = UDim2.new(0, 60, 0, 19), Position = UDim2.new(1, -66, 0, 2), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, Text = tostring(val) .. suf, Font = Enum.Font.Code, TextSize = 11, Parent = r})
		Corner(4, badge)
		local bar = New("Frame", {Size = UDim2.new(1, -24, 0, 4), Position = UDim2.new(0, 12, 0, 36), BackgroundColor3 = Color3.fromRGB(62, 62, 62), BorderSizePixel = 0, Parent = r})
		Corner(2, bar)
		local fill = New("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = bar})
		Corner(2, fill)
		local knob = New("Frame", {Size = UDim2.new(0, 15, 0, 15), BackgroundColor3 = Theme.Bright, BorderSizePixel = 0, ZIndex = 2, Parent = bar})
		Corner(8, knob) Stroke(Color3.fromRGB(130, 130, 130), 1, knob)
		local h
		local function render()
			local pr = (val - min) / math.max(1e-6, max - min)
			fill.Size = UDim2.new(pr, 0, 1, 0)
			knob.Position = UDim2.new(pr, -7, 0.5, -7.5)
			badge.Text = tostring(val) .. suf
		end
		local function apply(pr, fire)
			local raw = min + (max - min) * math.clamp(pr, 0, 1)
			val = math.clamp(math.floor(raw / step + 0.5) * step, min, max)
			render()
			Win.Flags[key] = val
			if fire ~= false then safeCall(cb, val) end
		end
		render()
		bar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				local pr = (i.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X)
				apply(pr)
				sliderDrag = {bar, function(p2) apply(p2) end}
			end
		end)
		knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliderDrag = {bar, function(p2) apply(p2) end} end end)
		h = {Frame = r, Set = function(_, v) apply(((v - min) / math.max(1e-6, max - min)), true) end, Get = function() return val end}
		track(self, key, val, h)
		return h
	end
	function Ctrl:AddDropdown(o)
		local opts = o.Options or {"Option 1"}
		local val = o.Default or opts[1]
		local cb = o.Callback or function() end
		local key = flagKey(o)
		local r = rowBox(self, 36, (o.Name or "") .. " " .. table.concat(opts, " "))
		New("TextLabel", {Size = UDim2.new(0.46, 0, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Dropdown", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local b = New("TextButton", {Size = UDim2.new(0.54, -16, 0, 25), Position = UDim2.new(0.46, 6, 0.5, -12.5), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, Text = " " .. tostring(val), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		Corner(4, b) Stroke(Theme.InputBorder, 1, b)
		local ch = makeIcon("chevD", 12, Theme.Dim) ch.Position = UDim2.new(1, -18, 0.5, -6) ch.Parent = b
		local h
		b.MouseButton1Click:Connect(function()
			Win:CloseDrops()
			local drop = New("Frame", {Size = UDim2.new(0, math.max(180, b.AbsoluteSize.X), 0, math.min(#opts * 28 + 8, 172)), Position = UDim2.new(0, b.AbsolutePosition.X - Main.AbsolutePosition.X, 0, b.AbsolutePosition.Y - Main.AbsolutePosition.Y + 27), BackgroundColor3 = Color3.fromRGB(37, 37, 38), ZIndex = 50, Parent = Main})
			Corner(6, drop) Stroke(Theme.Border, 1, drop)
			local sl = New("ScrollingFrame", {Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4), BackgroundTransparency = 1, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = drop})
			List(1, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, sl)
			for _, op in ipairs(opts) do
				local sel = op == val
				local ob = New("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = sel and 0 or 1, BackgroundColor3 = sel and Theme.Select or Color3.fromRGB(37, 37, 38), Text = (sel and "✓  " or "     ") .. tostring(op), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = sl})
				ob.MouseEnter:Connect(function() if op ~= val then ob.BackgroundTransparency = 0 ob.BackgroundColor3 = Theme.Hover end end)
				ob.MouseLeave:Connect(function() if op ~= val then ob.BackgroundTransparency = 1 end end)
				ob.MouseButton1Click:Connect(function()
					val = op b.Text = " " .. tostring(val)
					Win.Flags[key] = val Win:CloseDrops() safeCall(cb, val)
				end)
			end
			Win._openDrop = drop ClickBlock.Visible = true
		end)
		h = {Frame = r, Set = function(_, v) val = v b.Text = " " .. tostring(val) Win.Flags[key] = val safeCall(cb, val) end, Get = function() return val end}
		track(self, key, val, h)
		return h
	end
	function Ctrl:AddTextbox(o)
		local cb = o.Callback or function() end
		local key = flagKey(o)
		local r = rowBox(self, 36, o.Name)
		New("TextLabel", {Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Input", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local t = New("TextBox", {Size = UDim2.new(0.6, -16, 0, 25), Position = UDim2.new(0.4, 6, 0.5, -12.5), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Faint, PlaceholderText = o.Placeholder or "", Text = o.Default or "", Font = Enum.Font.Code, TextSize = 11, ClearTextOnFocus = false, Parent = r})
		Corner(4, t)
		local st = Stroke(Theme.InputBorder, 1, t) Pad(8, 2, t)
		t.Focused:Connect(function() st.Color = accent end)
		t.FocusLost:Connect(function(enter)
			st.Color = Theme.InputBorder
			local v = t.Text
			if o.NumbersOnly then v = v:gsub("[^%d%.%-]", "") t.Text = v end
			Win.Flags[key] = v
			if enter then safeCall(cb, v) end
		end)
		local h = {Frame = r, Set = function(_, v) t.Text = tostring(v) Win.Flags[key] = t.Text end, Get = function() return t.Text end}
		track(self, key, t.Text, h)
		return h
	end
	function Ctrl:AddKeybind(o)
		local val = o.Default
		if val == nil then val = Enum.KeyCode.F end
		local cb = o.Callback or function() end
		local key = flagKey(o)
		local r = rowBox(self, 36, o.Name)
		New("TextLabel", {Size = UDim2.new(1, -116, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Keybind", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local b = New("TextButton", {Size = UDim2.new(0, 94, 0, 25), Position = UDim2.new(1, -104, 0.5, -12.5), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, Text = (val and val.Name) or "None", Font = Enum.Font.Code, TextSize = 11, Parent = r})
		Corner(4, b) Stroke(Theme.InputBorder, 1, b)
		local h
		local function set(v)
			val = v
			b.Text = (v and v.Name) or "None"
			Win.Flags[key] = v and v.Name or "None"
			for _, bd in ipairs(Win.Binds) do if bd.Id == key then bd.Key = v end end
		end
		b.MouseButton1Click:Connect(function()
			Win._pendingKey = key b.Text = "···" b.BackgroundColor3 = Theme.Select
			task.delay(0.2, function()
				if Win._pendingKey == key and b and b.Parent then
					task.spawn(function()
						task.wait(5)
						if Win._pendingKey == key then Win._pendingKey = nil b.Text = (val and val.Name) or "None" b.BackgroundColor3 = Theme.Input end
					end)
				end
			end)
		end)
		table.insert(Win.Binds, {Id = key, Key = val, Callback = cb})
		h = {Frame = r, Set = set, Get = function() return val end, _keyBtn = b}
		Win.Handles[key] = h Win.Flags[key] = val and val.Name or "None"
		local origSet = set
		h.Set = function(_, v)
			origSet(v)
			b.BackgroundColor3 = Theme.Input
			if Win._pendingKey == key then Win._pendingKey = nil end
		end
		return h
	end
	function Ctrl:AddColorPicker(o)
		local val = o.Default or Color3.fromRGB(0, 120, 212)
		local cb = o.Callback or function() end
		local key = flagKey(o)
		local r = rowBox(self, 36, o.Name)
		New("TextLabel", {Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Accent", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local hex = New("TextLabel", {Size = UDim2.new(0, 66, 0, 22), Position = UDim2.new(1, -112, 0.5, -11), BackgroundTransparency = 1, Text = string.format("#%02X%02X%02X", math.floor(val.R * 255), math.floor(val.G * 255), math.floor(val.B * 255)), Font = Enum.Font.Code, TextSize = 10, TextColor3 = Theme.Dim, TextXAlignment = Right, Parent = r})
		local b = New("TextButton", {Size = UDim2.new(0, 36, 0, 21), Position = UDim2.new(1, -42, 0.5, -10.5), BackgroundColor3 = val, Text = "", Parent = r})
		Corner(4, b) Stroke(Theme.Bright, 1, b)
		local presets = {Color3.fromRGB(0,120,212), Color3.fromRGB(79,193,255), Color3.fromRGB(197,134,192), Color3.fromRGB(137,209,133), Color3.fromRGB(220,220,170), Color3.fromRGB(206,145,120), Color3.fromRGB(231,72,86), Color3.fromRGB(255,255,255), Color3.fromRGB(30,30,30), Color3.fromRGB(255,170,0), Color3.fromRGB(0,200,140), Color3.fromRGB(150,120,255)}
		local h
		b.MouseButton1Click:Connect(function()
			Win:CloseDrops()
			local pop = New("Frame", {Size = UDim2.new(0, 196, 0, 150), Position = UDim2.new(0, b.AbsolutePosition.X - Main.AbsolutePosition.X - 150, 0, b.AbsolutePosition.Y - Main.AbsolutePosition.Y + 25), BackgroundColor3 = Color3.fromRGB(37, 37, 38), ZIndex = 50, Parent = Main})
			Corner(6, pop) Stroke(Theme.Border, 1, pop) Pad(8, 8, pop)
			local grid = New("Frame", {Size = UDim2.new(1, 0, 0, 76), BackgroundTransparency = 1, Parent = pop})
			local gl = New("UIGridLayout", {CellSize = UDim2.new(0, 26, 0, 22), CellPadding = UDim2.new(0, 4, 0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid})
			for _, c in ipairs(presets) do
				local sb = New("TextButton", {BackgroundColor3 = c, Text = "", AutoButtonColor = false, Parent = grid})
				Corner(4, sb) Stroke(Color3.fromRGB(80, 80, 80), 1, sb)
				sb.MouseButton1Click:Connect(function()
					val = c b.BackgroundColor3 = val
					hex.Text = string.format("#%02X%02X%02X", math.floor(val.R * 255), math.floor(val.G * 255), math.floor(val.B * 255))
					Win.Flags[key] = {R = val.R, G = val.G, B = val.B}
					Win:CloseDrops() safeCall(cb, val)
				end)
			end
			local hb = New("TextButton", {Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, Text = "Close", Font = Enum.Font.Gotham, TextSize = 11, Parent = pop})
			Corner(4, hb)
			hb.MouseButton1Click:Connect(function() Win:CloseDrops() end)
			Win._openDrop = pop ClickBlock.Visible = true
		end)
		h = {Frame = r, Set = function(_, v) val = v b.BackgroundColor3 = v hex.Text = string.format("#%02X%02X%02X", math.floor(v.R * 255), math.floor(v.G * 255), math.floor(v.B * 255)) end, Get = function() return val end}
		track(self, key, {R = val.R, G = val.G, B = val.B}, h)
		return h
	end

	function Win:NewTab(name)
		name = name or ("untitled-" .. (#self.Tabs + 1) .. ".lua")
		if self.TabsMap[name] then self:SelectTab(name) return self.TabsMap[name].Api end
		local tabBtn = New("TextButton", {Size = UDim2.new(0, 150, 1, 0), BackgroundColor3 = Theme.TabInactive, Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = TabHold})
		local fi = makeIcon("file", 13, fileColor(name)) fi.Position = UDim2.new(0, 10, 0.5, -6.5) fi.Parent = tabBtn
		New("TextLabel", {Size = UDim2.new(1, -42, 1, 0), Position = UDim2.new(0, 27, 0, 0), BackgroundTransparency = 1, Text = name, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = tabBtn})
		local x = New("TextButton", {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -26, 0.5, -12), BackgroundTransparency = 1, Text = "", Parent = tabBtn})
		local xi = makeIcon("close", 10, Theme.Dim) xi.Position = UDim2.new(0.5, -5, 0.5, -5) xi.Parent = x
		x.MouseEnter:Connect(function() x.BackgroundTransparency = 0 x.BackgroundColor3 = Theme.Hover end)
		x.MouseLeave:Connect(function() x.BackgroundTransparency = 1 end)

		local fileRow = New("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = FileList})
		local fri = makeIcon("file", 13, fileColor(name)) fri.Position = UDim2.new(0, 28, 0.5, -6.5) fri.Parent = fileRow
		New("TextLabel", {Size = UDim2.new(1, -52, 1, 0), Position = UDim2.new(0, 46, 0, 0), BackgroundTransparency = 1, Text = name, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = fileRow})

		local page = New("ScrollingFrame", {Size = UDim2.new(1, -76, 1, -10), Position = UDim2.new(0, 8, 0, 5), BackgroundTransparency = 1, ScrollBarThickness = 5, ScrollBarImageColor3 = Color3.fromRGB(85, 85, 85), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, Parent = PageHold})
		List(4, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top, page) Pad(6, 8, page)

		local api = {Name = name, Page = page, _group = page, _controls = {}}
		setmetatable(api, {__index = Ctrl})
		local entry = {Name = name, Btn = tabBtn, Row = fileRow, Page = page, Api = api}
		table.insert(self.Tabs, entry)
		self.TabsMap[name] = entry
		tabBtn.MouseButton1Click:Connect(function() self:SelectTab(name) end)
		fileRow.MouseButton1Click:Connect(function() self:SelectTab(name) end)
		x.MouseButton1Click:Connect(function() self:CloseTab(name) end)
		self:SelectTab(name)
		self:LayoutPages()
		return api
	end
	function Win:CloseTab(name)
		if #self.Tabs <= 1 then self:Notify("Keep at least one tab open") return end
		for i, t in ipairs(self.Tabs) do
			if t.Name == name then table.remove(self.Tabs, i) break end
		end
		local e = self.TabsMap[name]
		if e then e.Btn:Destroy() e.Row:Destroy() e.Page:Destroy() end
		self.TabsMap[name] = nil
		self:SelectTab(self.Tabs[1].Name)
	end
	function Win:SelectTab(name)
		self:CloseDrops()
		for _, t in ipairs(self.Tabs) do
			local on = t.Name == name
			t.Page.Visible = on
			t.Btn.BackgroundColor3 = on and Theme.TabActive or Theme.TabInactive
			t.Row.BackgroundTransparency = on and 0 or 1
			t.Row.BackgroundColor3 = Theme.Hover
			for _, c in ipairs(t.Btn:GetChildren()) do if c:IsA("Frame") and c.Name == "Top" then c:Destroy() end end
			if on then
				New("Frame", {Name = "Top", Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = t.Btn})
				self.Current = t
				CrumbPath.Text = title .. "  ›  " .. name
				stLang.Text = " {} " .. (name:match("%.(%w+)$") or "Lua") .. "  "
				FilterBox.Text = ""
				for _, c in ipairs(t.Api._controls) do c.Visible = true end
			end
		end
	end
	function Win:SetStatus(left, right)
		if left then stExec.Text = " " .. left .. " " end
		if right then stLn.Text = " " .. right .. " " end
	end
	function Win:Toggle() Gui.Enabled = not Gui.Enabled end
	function Win:Destroy() Gui:Destroy() end
	function Win:SaveConfig(slot)
		slot = slot or "default"
		local ok, js = pcall(HttpService.JSONEncode, HttpService, self.Flags)
		if not ok then return false end
		pcall(function() if writefile then writefile("vscode_" .. slot .. ".json", js) end end)
		if getgenv then getgenv()["VSCodeCfg_" .. slot] = js end
		self:Notify({Title = "Config", Message = "Saved slot '" .. slot .. "'"})
		return true
	end
	function Win:LoadConfig(slot)
		slot = slot or "default"
		local js = nil
		pcall(function() if readfile and isfile and isfile("vscode_" .. slot .. ".json") then js = readfile("vscode_" .. slot .. ".json") end end)
		if not js and getgenv then js = getgenv()["VSCodeCfg_" .. slot] end
		if not js then self:Notify("No saved config '" .. slot .. "'") return false end
		local ok, data = pcall(HttpService.JSONDecode, HttpService, js)
		if not ok or type(data) ~= "table" then return false end
		for k, v in pairs(data) do
			local h = self.Handles[k]
			if h and h.Set then
				if typeof(v) == "table" and v.R and h.Frame and h.Frame.Parent then
					pcall(function() h:Set(Color3.new(v.R, v.G, v.B)) end)
				elseif typeof(v) == "string" and Enum.KeyCode:FindFirstChild(v) and h.Get and type(h.Get()) ~= "string" then
					pcall(function() h:Set(Enum.KeyCode[v]) end)
				else
					pcall(function() h:Set(v) end)
				end
			else self.Flags[k] = v end
		end
		self:Notify({Title = "Config", Message = "Loaded slot '" .. slot .. "'"})
		return true
	end

	local grip = New("TextButton", {Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -22, 1, -46), BackgroundTransparency = 1, Text = "◢", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Faint, Parent = Main})
	local rs, sp2, ss = false, nil, nil
	grip.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then rs, sp2, ss = true, i.Position, Main.Size end end)
	UserInputService.InputChanged:Connect(function(i)
		if rs and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - sp2
			Main.Size = UDim2.new(0, math.clamp(ss.X.Offset + d.X, 640, 1400), 0, math.clamp(ss.Y.Offset + d.Y, 400, 900))
			oldSize = Main.Size
		end
	end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then rs = false end end)

	layoutEditor()
	return Win
end

return VSCode
