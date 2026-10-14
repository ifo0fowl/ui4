local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
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
	Line = Color3.fromRGB(42, 45, 46),
	Input = Color3.fromRGB(49, 49, 49),
	InputBorder = Color3.fromRGB(60, 60, 60),
	Button = Color3.fromRGB(0, 120, 212),
	ButtonHover = Color3.fromRGB(2, 110, 193),
	Text = Color3.fromRGB(204, 204, 204),
	Bright = Color3.fromRGB(255, 255, 255),
	Dim = Color3.fromRGB(157, 157, 157),
	Faint = Color3.fromRGB(133, 133, 133),
	Accent = Color3.fromRGB(0, 120, 212),
	Green = Color3.fromRGB(137, 209, 133),
	Blue = Color3.fromRGB(79, 193, 255),
	Purple = Color3.fromRGB(197, 134, 192),
	Yellow = Color3.fromRGB(220, 220, 170),
	Hover = Color3.fromRGB(42, 45, 46),
	Select = Color3.fromRGB(4, 57, 94),
	RowHover = Color3.fromRGB(42, 45, 46),
}

local Glyph = {
	Explorer = "▤",
	Search = "⌕",
	Source = "⎇",
	Run = "▷",
	Ext = "◫",
	Account = "◯",
	Gear = "⚙",
	File = "◈",
	Close = "×",
	ChevronD = "⌄",
	ChevronR = "›",
	Dot = "●",
	Check = "✓",
	Bell = "✦",
	Warn = "⚠",
	Err = "⊗",
	Branch = "⎇",
	Play = "▷",
	Remote = "><",
}

local function fileColor(n)
	n = n:lower()
	if n:find("%.luau") then return Theme.Purple end
	if n:find("%.lua") then return Theme.Blue end
	if n:find("%.json") then return Theme.Yellow end
	if n:find("%.txt") then return Theme.Dim end
	return Theme.Green
end

local function New(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then pcall(function() o[k] = v end) end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function Corner(r) return New("UICorner", {CornerRadius = UDim.new(0, r or 4)}) end
local function Stroke(c, t) return New("UIStroke", {Color = c, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) end
local function Pad(x, y) return New("UIPadding", {PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, x), PaddingTop = UDim.new(0, y or x), PaddingBottom = UDim.new(0, y or x)}) end
local function List(pad, dir) return New("UIListLayout", {Padding = UDim.new(0, pad or 4), FillDirection = dir or Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder}) end
local function T(o, t, p) pcall(function() TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play() end) end

local function Drag(frame, handle)
	local s, sp, gp = false, nil, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			s, sp, gp = true, frame.Position, i.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then s = false end end)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if s and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - gp
			frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)
end

local function Tooltip(btn, txt)
	local tip = nil
	btn.MouseEnter:Connect(function()
		if tip then return end
		tip = New("TextLabel", {Size = UDim2.new(0, 0, 0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(37, 37, 38), TextColor3 = Theme.Text, Text = "  " .. txt .. "  ", Font = Enum.Font.Gotham, TextSize = 11, BorderSizePixel = 0, ZIndex = 100, Parent = btn})
		Corner(4).Parent = tip Stroke(Theme.Border).Parent = tip
		tip.Position = UDim2.new(1, 6, 0.5, -12)
	end)
	btn.MouseLeave:Connect(function() if tip then tip:Destroy() tip = nil end end)
end

function VSCode:CreateWindow(opt)
	opt = opt or {}
	local title = opt.Title or "ExternalNew"
	local toggleKey = opt.ToggleKey or Enum.KeyCode.RightShift
	local accent = opt.Accent or Theme.Status

	local parent = nil
	pcall(function() if gethui then parent = gethui() end end)
	if not parent then parent = CoreGui end
	if getgenv and getgenv().VSCodeGui then pcall(function() getgenv().VSCodeGui:Destroy() end) end

	local Gui = New("ScreenGui", {Name = "VSCode_" .. math.random(100000, 999999), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parent})
	if getgenv then getgenv().VSCodeGui = Gui end
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(Gui) end end)

	local Main = New("Frame", {Size = UDim2.new(0, 920, 0, 580), Position = UDim2.new(0.5, -460, 0.5, -290), BackgroundColor3 = Theme.Editor, BorderSizePixel = 0, Active = true, Parent = Gui})
	Corner(8).Parent = Main Stroke(Theme.Border).Parent = Main
	Drag(Main, Main)

	local Body, Side, StatusBar

	local TitleBar = New("Frame", {Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Theme.Title, BorderSizePixel = 0, Parent = Main})
	New("UICorner", {CornerRadius = UDim.new(0, 8), Parent = TitleBar})
	New("Frame", {Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = Theme.Title, BorderSizePixel = 0, Parent = TitleBar})

	local menus = {"File", "Edit", "Selection", "View", "Go", "Run", "Terminal", "Help"}
	local mx = 12
	for _, m in ipairs(menus) do
		local b = New("TextButton", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = " " .. m .. " ", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, AutoButtonColor = false, Parent = TitleBar})
		b.Position = UDim2.new(0, mx, 0, 0)
		mx = mx + 52
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.8 b.BackgroundColor3 = Theme.Hover end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
	end

	local SearchWrap = New("Frame", {Size = UDim2.new(0, 340, 0, 24), Position = UDim2.new(0.5, -170, 0.5, -12), BackgroundColor3 = Color3.fromRGB(36, 36, 36), BorderSizePixel = 0, Parent = TitleBar})
	Corner(6).Parent = SearchWrap Stroke(Color3.fromRGB(55, 55, 55)).Parent = SearchWrap
	New("TextLabel", {Size = UDim2.new(0, 26, 1, 0), BackgroundTransparency = 1, Text = Glyph.Search, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Faint, Parent = SearchWrap})
	local SearchBox = New("TextBox", {Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 26, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = title, PlaceholderColor3 = Theme.Faint, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 11, ClearTextOnFocus = false, Parent = SearchWrap})

	local function WinBtn(txt, x, hoverRed)
		local b = New("TextButton", {Size = UDim2.new(0, 46, 1, 0), Position = UDim2.new(1, x, 0, 0), BackgroundTransparency = 1, Text = txt, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text, AutoButtonColor = false, Parent = TitleBar})
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 b.BackgroundColor3 = hoverRed and Color3.fromRGB(232, 17, 35) or Color3.fromRGB(60, 60, 60) end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		return b
	end
	local btnMin = WinBtn("─", -138)
	local btnMax = WinBtn("□", -92)
	local btnX = WinBtn(Glyph.Close, -46, true)
	btnX.MouseButton1Click:Connect(function() Gui.Enabled = false end)
	local minimized, full = false, false
	local oldSize = Main.Size
	local oldPos = Main.Position
	btnMin.MouseButton1Click:Connect(function()
		minimized = not minimized
		if Body then Body.Visible = not minimized end
		Main.Size = minimized and UDim2.new(0, 920, 0, 59) or oldSize
	end)
	btnMax.MouseButton1Click:Connect(function()
		full = not full
		Main.Size = full and UDim2.new(1, -40, 1, -40) or UDim2.new(0, 920, 0, 580)
		Main.Position = full and UDim2.new(0, 20, 0, 20) or UDim2.new(0.5, -460, 0.5, -290)
	end)

	Body = New("Frame", {Size = UDim2.new(1, 0, 1, -59), Position = UDim2.new(0, 0, 0, 35), BackgroundTransparency = 1, Parent = Main})

	local Activity = New("Frame", {Size = UDim2.new(0, 48, 1, 0), BackgroundColor3 = Theme.Activity, BorderSizePixel = 0, Parent = Body})
	local acts = {{Glyph.Explorer, "Explorer"}, {Glyph.Search, "Search"}, {Glyph.Source, "Source Control"}, {Glyph.Run, "Run and Debug"}, {Glyph.Ext, "Extensions"}}
	local actBtns = {}
	for i, v in ipairs(acts) do
		local b = New("TextButton", {Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Text = v[1], Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = i == 1 and Theme.Bright or Theme.Faint, AutoButtonColor = false, Parent = Activity})
		Tooltip(b, v[2])
		if i == 1 then New("Frame", {Name = "Sel", Size = UDim2.new(0, 2, 0, 32), Position = UDim2.new(0, 0, 0.5, -16), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = b}) end
		b.MouseEnter:Connect(function() if b.TextColor3 ~= Theme.Bright then b.TextColor3 = Theme.Text end end)
		b.MouseLeave:Connect(function()
			local sel = b:FindFirstChild("Sel") ~= nil
			b.TextColor3 = sel and Theme.Bright or Theme.Faint
		end)
		b.MouseButton1Click:Connect(function()
			for _, o in ipairs(actBtns) do o.TextColor3 = Theme.Faint if o:FindFirstChild("Sel") then o.Sel:Destroy() end end
			b.TextColor3 = Theme.Bright
			New("Frame", {Name = "Sel", Size = UDim2.new(0, 2, 0, 32), Position = UDim2.new(0, 0, 0.5, -16), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = b})
			if Side then Side.Visible = (v[2] == "Explorer") end
		end)
		actBtns[i] = b
	end
	local accBtn = New("TextButton", {Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -88), BackgroundTransparency = 1, Text = Glyph.Account, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Theme.Faint, Parent = Activity})
	Tooltip(accBtn, "Accounts")
	local setBtn = New("TextButton", {Size = UDim2.new(1, 0, 0, 44), Position = UDim2.new(0, 0, 1, -44), BackgroundTransparency = 1, Text = Glyph.Gear, Font = Enum.Font.Gotham, TextSize = 19, TextColor3 = Theme.Faint, Parent = Activity})
	Tooltip(setBtn, "Manage")

	Side = New("Frame", {Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, 48, 0, 0), BackgroundColor3 = Theme.Side, BorderSizePixel = 0, Parent = Body})
	New("TextLabel", {Size = UDim2.new(1, -40, 0, 32), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = "EXPLORER", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Left, Parent = Side})
	New("TextButton", {Size = UDim2.new(0, 28, 0, 22), Position = UDim2.new(1, -32, 0, 5), BackgroundTransparency = 1, Text = "···", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Dim, Parent = Side})
	New("TextLabel", {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 30), BackgroundTransparency = 1, Text = "  ⌄ " .. string.upper(title), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = Side})
	local FileList = New("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 220), Position = UDim2.new(0, 0, 0, 54), BackgroundTransparency = 1, ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Side})
	List(1).Parent = FileList
	for _, sec in ipairs({"OUTLINE", "TIMELINE"}) do
		local h = New("TextButton", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 274 + (#sec == 7 and 0 or 26)), BackgroundTransparency = 1, Text = "  › " .. sec, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = Side})
		h.MouseButton1Click:Connect(function()
			local open = h.Text:find("›") ~= nil
			h.Text = open and ("  ⌄ " .. sec) or ("  › " .. sec)
		end)
	end

	local EditorWrap = New("Frame", {Size = UDim2.new(1, -248, 1, 0), Position = UDim2.new(0, 248, 0, 0), BackgroundColor3 = Theme.Editor, BorderSizePixel = 0, Parent = Body})
	local TabBar = New("Frame", {Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Theme.TabBar, BorderSizePixel = 0, Parent = EditorWrap})
	local TabHold = New("ScrollingFrame", {Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X, Parent = TabBar})
	New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabHold})
	New("TextLabel", {Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(1, -70, 0, 0), BackgroundTransparency = 1, Text = "▭  ▤  ⋯", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Dim, Parent = TabBar})

	local Crumb = New("Frame", {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 35), BackgroundColor3 = Theme.Editor, BorderSizePixel = 0, Parent = EditorWrap})
	New("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = Crumb})
	local CrumbPath = New("TextLabel", {Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = title .. " › welcome", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Crumb})
	local FilterBox = New("TextBox", {Size = UDim2.new(0, 150, 0, 18), Position = UDim2.new(1, -160, 0.5, -9), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Faint, PlaceholderText = "⌕ Filter settings", Text = "", Font = Enum.Font.Gotham, TextSize = 10, ClearTextOnFocus = false, Parent = Crumb})
	Corner(4).Parent = FilterBox Pad(6, 2).Parent = FilterBox

	local PageHold = New("Frame", {Size = UDim2.new(1, 0, 1, -59), Position = UDim2.new(0, 0, 0, 59), BackgroundTransparency = 1, ClipsDescendants = true, Parent = EditorWrap})

	local MiniMap = New("Frame", {Size = UDim2.new(0, 64, 1, -67), Position = UDim2.new(1, -64, 0, 63), BackgroundColor3 = Theme.Editor, BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = EditorWrap})
	for i = 1, 48 do
		local indent = math.random(0, 3) * 6
		local w = math.random(16, 48 - indent)
		local c = ({Theme.Blue, Theme.Green, Theme.Yellow, Theme.Purple, Color3.fromRGB(120, 120, 120)})[math.random(1, 5)]
		New("Frame", {Size = UDim2.new(0, w, 0, 2), Position = UDim2.new(0, 4 + indent, 0, (i - 1) * 10 + 4), BackgroundColor3 = c, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = MiniMap})
	end
	New("Frame", {Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0, 80), BackgroundColor3 = Theme.Bright, BackgroundTransparency = 0.92, BorderSizePixel = 0, Parent = MiniMap})

	StatusBar = New("Frame", {Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -24), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = Main})
	New("UICorner", {CornerRadius = UDim.new(0, 8), Parent = StatusBar})
	New("Frame", {Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = StatusBar})
	local SL = New("Frame", {Size = UDim2.new(0.62, 0, 1, 0), BackgroundTransparency = 1, Parent = StatusBar})
	New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = SL})
	local SR = New("Frame", {Size = UDim2.new(0.38, -10, 1, 0), Position = UDim2.new(0.62, 0, 0, 0), BackgroundTransparency = 1, Parent = StatusBar})
	New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = SR})

	local function StatBtn(txt, left, bold)
		local b = New("TextButton", {AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, Text = " " .. txt .. " ", Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Bright, AutoButtonColor = false, Parent = left and SL or SR})
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.75 b.BackgroundColor3 = Theme.Bright end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		return b
	end
	local stRemote = StatBtn(Glyph.Remote, true, true)
	local stBranch = StatBtn(Glyph.Branch .. " main*", true)
	local stErr = StatBtn(Glyph.Err .. " 0  " .. Glyph.Warn .. " 0", true)
	local stExec = StatBtn(Glyph.Play .. " Execute", true)
	local stAttach = StatBtn("⇄ Attach", true)
	local stLn = StatBtn("Ln 21, Col 66", false)
	local stSp = StatBtn("Spaces: 4", false)
	local stEnc = StatBtn("UTF-8", false)
	local stLang = StatBtn("{} Lua", false)
	local stBell = StatBtn(Glyph.Bell, false)

	local Win = {Gui = Gui, Tabs = {}, Current = nil, TabsMap = {}}
	local Toasts = New("Frame", {Size = UDim2.new(0, 320, 1, -70), Position = UDim2.new(1, -330, 0, 10), BackgroundTransparency = 1, Parent = Main})

	function Win:Notify(o)
		o = type(o) == "string" and {Message = o} or o
		local t = New("Frame", {Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = Color3.fromRGB(37, 37, 38), BorderSizePixel = 0, Parent = Toasts})
		Corner(6).Parent = t Stroke(Theme.Border).Parent = t
		New("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = t})
		New("TextLabel", {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1, Text = Glyph.Dot, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = accent, Parent = t})
		New("TextLabel", {Size = UDim2.new(1, -44, 0, 18), Position = UDim2.new(0, 28, 0, 6), BackgroundTransparency = 1, Text = o.Title or title, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Bright, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = t})
		local xb = New("TextButton", {Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -26, 0, 4), BackgroundTransparency = 1, Text = Glyph.Close, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Dim, Parent = t})
		xb.MouseButton1Click:Connect(function() t:Destroy() end)
		New("TextLabel", {Size = UDim2.new(1, -40, 0, 28), Position = UDim2.new(0, 28, 0, 24), BackgroundTransparency = 1, Text = o.Message or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, TextYAlignment = Top, TextWrapped = true, Parent = t})
		t.Position = UDim2.new(0, 340, 0, 0)
		T(t, 0.25, {Position = UDim2.new(0, 0, 0, 0)})
		task.delay(o.Duration or 4, function() pcall(function() T(t, 0.25, {Position = UDim2.new(0, 340, 0, 0)}) task.wait(0.25) t:Destroy() end) end)
	end

	local Palette = New("Frame", {Size = UDim2.new(0, 480, 0, 320), Position = UDim2.new(0.5, -240, 0, 44), BackgroundColor3 = Color3.fromRGB(37, 37, 38), BorderSizePixel = 0, Visible = false, ZIndex = 50, Parent = Main})
	Corner(8).Parent = Palette Stroke(Theme.Border).Parent = Palette
	local PIn = New("TextBox", {Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Dim, PlaceholderText = "> Type a file name...", Text = "", Font = Enum.Font.Code, TextSize = 12, Parent = Palette})
	Corner(6).Parent = PIn Pad(10, 4).Parent = PIn
	local PList = New("ScrollingFrame", {Size = UDim2.new(1, -16, 1, -54), Position = UDim2.new(0, 8, 0, 46), BackgroundTransparency = 1, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Palette})
	List(2).Parent = PList
	local function refreshPalette(q)
		for _, c in ipairs(PList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		q = (q or ""):lower()
		for _, tb in ipairs(Win.Tabs) do
			if tb.Name:lower():find(q, 1, true) then
				local b = New("TextButton", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "", Parent = PList})
				New("TextLabel", {Size = UDim2.new(0, 24, 1, 0), BackgroundTransparency = 1, Text = Glyph.File, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = fileColor(tb.Name), Parent = b})
				New("TextLabel", {Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 26, 0, 0), BackgroundTransparency = 1, Text = tb.Name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = b})
				b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 b.BackgroundColor3 = Theme.Hover end)
				b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
				b.MouseButton1Click:Connect(function() Win:SelectTab(tb.Name) Palette.Visible = false end)
			end
		end
	end
	PIn:GetPropertyChangedSignal("Text"):Connect(function() refreshPalette(PIn.Text:gsub("^>", "")) end)
	function Win:Palette() Palette.Visible = not Palette.Visible if Palette.Visible then refreshPalette("") PIn.Text = "" PIn:CaptureFocus() end end

	local function row(parent, h)
		local r = New("Frame", {Size = UDim2.new(1, -12, 0, h or 34), BackgroundTransparency = 1, Parent = parent})
		r.MouseEnter:Connect(function() r.BackgroundTransparency = 0.85 r.BackgroundColor3 = Theme.RowHover end)
		r.MouseLeave:Connect(function() r.BackgroundTransparency = 1 end)
		return r
	end
	local function curGroup(api) return api._group or api.Page end

	local Ctrl = {}
	function Ctrl:AddSection(name)
		local open = true
		local h = New("TextButton", {Size = UDim2.new(1, -12, 0, 28), BackgroundTransparency = 1, Text = "  ⌄ " .. name:upper(), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Bright, TextXAlignment = Left, Parent = self.Page})
		local g = New("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self.Page})
		List(2).Parent = g
		self._group = g
		h.MouseButton1Click:Connect(function()
			open = not open
			h.Text = open and ("  ⌄ " .. name:upper()) or ("  › " .. name:upper())
			g.Visible = open
		end)
		return h
	end
	function Ctrl:AddDivider()
		local p = curGroup(self)
		New("Frame", {Size = UDim2.new(1, -12, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = p})
	end
	function Ctrl:AddLabel(txt, sub)
		local p = curGroup(self)
		New("TextLabel", {Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = txt, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextWrapped = true, Parent = p})
		if sub then
			local s = New("TextLabel", {Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = sub, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Left, TextWrapped = true, Parent = p})
			return s
		end
	end
	function Ctrl:AddButton(o)
		o = type(o) == "string" and {Name = o} or o
		local p = curGroup(self)
		local r = row(p, 38)
		local secondary = o.Style == "secondary"
		local b = New("TextButton", {Size = UDim2.new(0, o.Width or 180, 0, 28), Position = UDim2.new(0, 4, 0, 5), BackgroundColor3 = secondary and Color3.fromRGB(49, 49, 49) or Theme.Button, TextColor3 = Theme.Bright, Text = o.Name or "Execute", Font = Enum.Font.Gotham, TextSize = 12, AutoButtonColor = false, Parent = r})
		Corner(4).Parent = b
		if secondary then Stroke(Theme.InputBorder).Parent = b end
		b.MouseEnter:Connect(function() b.BackgroundColor3 = secondary and Color3.fromRGB(60, 60, 60) or Theme.ButtonHover end)
		b.MouseLeave:Connect(function() b.BackgroundColor3 = secondary and Color3.fromRGB(49, 49, 49) or Theme.Button end)
		b.MouseButton1Click:Connect(function() T(b, 0.08, {Size = UDim2.new(0, (o.Width or 180) - 4, 0, 26)}) task.wait(0.08) T(b, 0.08, {Size = UDim2.new(0, o.Width or 180, 0, 28)}) pcall(o.Callback or function() end) end)
		return {Fire = function() pcall(o.Callback or function() end) end}
	end
	function Ctrl:AddToggle(o)
		local val = o.Default or false
		local cb = o.Callback or function() end
		local p = curGroup(self)
		local r = row(p, 34)
		New("TextLabel", {Size = UDim2.new(1, -120, 0, 16), Position = UDim2.new(0, 6, 0, 2), BackgroundTransparency = 1, Text = o.Name or "Toggle", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		if o.Desc then New("TextLabel", {Size = UDim2.new(1, -120, 0, 12), Position = UDim2.new(0, 6, 0, 18), BackgroundTransparency = 1, Text = o.Desc, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.Dim, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r}) end
		local box = New("TextButton", {Size = UDim2.new(0, 34, 0, 19), Position = UDim2.new(1, -42, 0, 7), BackgroundColor3 = val and accent or Color3.fromRGB(60, 60, 60), Text = "", AutoButtonColor = false, Parent = r})
		Corner(10).Parent = box
		local dot = New("Frame", {Size = UDim2.new(0, 13, 0, 13), Position = val and UDim2.new(1, -16, 0.5, -6.5) or UDim2.new(0, 3, 0.5, -6.5), BackgroundColor3 = Theme.Bright, BorderSizePixel = 0, Parent = box})
		Corner(7).Parent = dot
		local function set(v)
			val = v
			T(box, 0.15, {BackgroundColor3 = val and accent or Color3.fromRGB(60, 60, 60)})
			T(dot, 0.15, {Position = val and UDim2.new(1, -16, 0.5, -6.5) or UDim2.new(0, 3, 0.5, -6.5)})
			pcall(cb, val)
		end
		box.MouseButton1Click:Connect(function() set(not val) end)
		if val then pcall(cb, val) end
		return {Set = set, Get = function() return val end}
	end
	function Ctrl:AddSlider(o)
		local min, max, val = o.Min or 0, o.Max or 100, o.Default or 50
		local cb = o.Callback or function() end
		local p = curGroup(self)
		local r = row(p, 52)
		local lab = New("TextLabel", {Size = UDim2.new(1, -70, 0, 18), Position = UDim2.new(0, 6, 0, 2), BackgroundTransparency = 1, Text = o.Name or "Slider", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local badge = New("TextLabel", {Size = UDim2.new(0, 52, 0, 18), Position = UDim2.new(1, -58, 0, 2), BackgroundColor3 = Color3.fromRGB(49, 49, 49), TextColor3 = Theme.Text, Text = tostring(val), Font = Enum.Font.Code, TextSize = 11, Parent = r})
		Corner(4).Parent = badge
		local bar = New("Frame", {Size = UDim2.new(1, -24, 0, 3), Position = UDim2.new(0, 12, 0, 34), BackgroundColor3 = Color3.fromRGB(60, 60, 60), BorderSizePixel = 0, Parent = r})
		Corner(2).Parent = bar
		local fill = New("Frame", {Size = UDim2.new((val - min) / math.max(1, max - min), 0, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = bar})
		Corner(2).Parent = fill
		local knob = New("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new((val - min) / math.max(1, max - min), -7, 0.5, -7), BackgroundColor3 = Theme.Bright, BorderSizePixel = 0, ZIndex = 2, Parent = bar})
		Corner(7).Parent = knob Stroke(Color3.fromRGB(120, 120, 120)).Parent = knob
		local drag = false
		local function upd(x)
			local pr = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
			val = math.floor(min + (max - min) * pr + 0.5)
			fill.Size = UDim2.new(pr, 0, 1, 0)
			knob.Position = UDim2.new(pr, -7, 0.5, -7)
			badge.Text = tostring(val)
			pcall(cb, val)
		end
		bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true upd(i.Position.X) end end)
		knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
		UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
		return {Set = function(_, v) val = math.clamp(v, min, max) local pr = (val - min) / math.max(1, max - min) fill.Size = UDim2.new(pr, 0, 1, 0) knob.Position = UDim2.new(pr, -7, 0.5, -7) badge.Text = tostring(val) pcall(cb, val) end, Get = function() return val end}
	end
	function Ctrl:AddDropdown(o)
		local opts = o.Options or {"Option 1"}
		local val = o.Default or opts[1]
		local cb = o.Callback or function() end
		local p = curGroup(self)
		local r = row(p, 34)
		New("TextLabel", {Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Dropdown", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local b = New("TextButton", {Size = UDim2.new(0.5, -16, 0, 24), Position = UDim2.new(0.5, 6, 0.5, -12), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, Text = " " .. tostring(val) .. "   ﹀", Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		Corner(4).Parent = b Stroke(Theme.InputBorder).Parent = b
		b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end)
		b.MouseLeave:Connect(function() b.BackgroundColor3 = Theme.Input end)
		local drop, open = nil, false
		b.MouseButton1Click:Connect(function()
			open = not open
			if drop then drop:Destroy() drop = nil end
			if not open then return end
			drop = New("Frame", {Size = UDim2.new(0, math.max(160, b.AbsoluteSize.X), 0, math.min(#opts * 26 + 8, 140)), Position = UDim2.new(0, b.AbsolutePosition.X - Main.AbsolutePosition.X, 0, b.AbsolutePosition.Y - Main.AbsolutePosition.Y + 26), BackgroundColor3 = Color3.fromRGB(37, 37, 38), ZIndex = 40, Parent = Main})
			Corner(6).Parent = drop Stroke(Theme.Border).Parent = drop
			local sl = New("ScrollingFrame", {Size = UDim2.new(1, -6, 1, -6), Position = UDim2.new(0, 3, 0, 3), BackgroundTransparency = 1, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = drop})
			List(1).Parent = sl
			for _, op in ipairs(opts) do
				local sel = op == val
				local ob = New("TextButton", {Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = sel and Theme.Select or Color3.fromRGB(37, 37, 38), BackgroundTransparency = sel and 0 or 1, Text = (sel and "✓ " or "   ") .. tostring(op), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = sl})
				ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0 ob.BackgroundColor3 = Theme.Hover end)
				ob.MouseLeave:Connect(function() if op == val then ob.BackgroundTransparency = 0 ob.BackgroundColor3 = Theme.Select else ob.BackgroundTransparency = 1 end end)
				ob.MouseButton1Click:Connect(function() val = op b.Text = " " .. tostring(val) .. "   ﹀" open = false drop:Destroy() drop = nil pcall(cb, val) end)
			end
		end)
		return {Set = function(_, v) val = v b.Text = " " .. tostring(val) .. "   ﹀" pcall(cb, val) end, Get = function() return val end}
	end
	function Ctrl:AddTextbox(o)
		local cb = o.Callback or function() end
		local p = curGroup(self)
		local r = row(p, 34)
		New("TextLabel", {Size = UDim2.new(0.42, 0, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Input", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local t = New("TextBox", {Size = UDim2.new(0.58, -16, 0, 24), Position = UDim2.new(0.42, 6, 0.5, -12), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Faint, PlaceholderText = o.Placeholder or "", Text = o.Default or "", Font = Enum.Font.Code, TextSize = 11, ClearTextOnFocus = false, Parent = r})
		Corner(4).Parent = t
		local st = Stroke(Theme.InputBorder) st.Parent = t
		t.Focused:Connect(function() st.Color = accent end)
		t.FocusLost:Connect(function(e) st.Color = Theme.InputBorder if e then pcall(cb, t.Text) end end)
		return {Set = function(_, v) t.Text = v end, Get = function() return t.Text end}
	end
	function Ctrl:AddKeybind(o)
		local val = o.Default or Enum.KeyCode.F
		local cb = o.Callback or function() end
		local p = curGroup(self)
		local r = row(p, 34)
		New("TextLabel", {Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Keybind", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local b = New("TextButton", {Size = UDim2.new(0, 88, 0, 24), Position = UDim2.new(1, -98, 0.5, -12), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, Text = val.Name, Font = Enum.Font.Code, TextSize = 11, Parent = r})
		Corner(4).Parent = b Stroke(Theme.InputBorder).Parent = b
		local waiting = false
		b.MouseButton1Click:Connect(function() waiting = true b.Text = "···" b.BackgroundColor3 = Theme.Select end)
		UserInputService.InputBegan:Connect(function(i, g)
			if waiting and i.UserInputType == Enum.UserInputType.Keyboard then waiting = false val = i.KeyCode b.Text = val.Name b.BackgroundColor3 = Theme.Input return end
			if not g and i.KeyCode == val then pcall(cb, val) end
		end)
		return {Set = function(_, v) val = v b.Text = val.Name end, Get = function() return val end}
	end
	function Ctrl:AddColorPicker(o)
		local val = o.Default or Color3.fromRGB(0, 120, 212)
		local cb = o.Callback or function() end
		local p = curGroup(self)
		local r = row(p, 34)
		New("TextLabel", {Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Accent", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = r})
		local hex = New("TextLabel", {Size = UDim2.new(0, 64, 0, 22), Position = UDim2.new(1, -106, 0.5, -11), BackgroundTransparency = 1, Text = ("#%02X%02X%02X"):format(val.R * 255, val.G * 255, val.B * 255), Font = Enum.Font.Code, TextSize = 10, TextColor3 = Theme.Dim, TextXAlignment = Right, Parent = r})
		local b = New("TextButton", {Size = UDim2.new(0, 34, 0, 20), Position = UDim2.new(1, -40, 0.5, -10), BackgroundColor3 = val, Text = "", Parent = r})
		Corner(4).Parent = b Stroke(Theme.Bright, 1).Parent = b
		local presets = {Color3.fromRGB(0,120,212), Color3.fromRGB(197,134,192), Color3.fromRGB(137,209,133), Color3.fromRGB(220,220,170), Color3.fromRGB(206,145,120), Color3.fromRGB(231,72,86), Color3.fromRGB(79,193,255)}
		b.MouseButton1Click:Connect(function()
			local idx = 1
			for n, c in ipairs(presets) do if math.abs(c.R - val.R) < 0.01 and math.abs(c.G - val.G) < 0.01 then idx = n break end end
			val = presets[(idx % #presets) + 1]
			b.BackgroundColor3 = val
			hex.Text = ("#%02X%02X%02X"):format(val.R * 255, val.G * 255, val.B * 255)
			pcall(cb, val)
		end)
		return {Set = function(_, v) val = v b.BackgroundColor3 = v end, Get = function() return val end}
	end

	function Win:NewTab(name)
		name = name or ("untitled-" .. (#self.Tabs + 1) .. ".lua")
		if self.TabsMap[name] then self:SelectTab(name) return self.TabsMap[name].Api end
		local tabBtn = New("TextButton", {Size = UDim2.new(0, 10, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.TabInactive, Text = "", AutoButtonColor = false, Parent = TabHold})
		New("TextLabel", {Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = Glyph.File, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = fileColor(name), Parent = tabBtn})
		local nt = New("TextLabel", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(0, 28, 0, 0), BackgroundTransparency = 1, Text = name .. "   ", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = tabBtn})
		local x = New("TextButton", {Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -24, 0.5, -11), BackgroundTransparency = 1, Text = Glyph.Close, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Dim, Parent = tabBtn})
		x.MouseEnter:Connect(function() x.BackgroundTransparency = 0.8 x.BackgroundColor3 = Theme.Hover end)
		x.MouseLeave:Connect(function() x.BackgroundTransparency = 1 end)

		local fileRow = New("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = FileList})
		New("TextLabel", {Size = UDim2.new(0, 18, 1, 0), Position = UDim2.new(0, 22, 0, 0), BackgroundTransparency = 1, Text = Glyph.File, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = fileColor(name), Parent = fileRow})
		New("TextLabel", {Size = UDim2.new(1, -48, 1, 0), Position = UDim2.new(0, 40, 0, 0), BackgroundTransparency = 1, Text = name, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = fileRow})

		local page = New("ScrollingFrame", {Size = UDim2.new(1, -78, 1, -10), Position = UDim2.new(0, 8, 0, 5), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = PageHold})
		List(3).Parent = page
		Pad(6, 8).Parent = page

		local api = {Name = name, Page = page, _group = page}
		setmetatable(api, {__index = Ctrl})
		local entry = {Name = name, Btn = tabBtn, Row = fileRow, Page = page, Api = api}
		table.insert(self.Tabs, entry)
		self.TabsMap[name] = entry
		tabBtn.MouseButton1Click:Connect(function() self:SelectTab(name) end)
		fileRow.MouseButton1Click:Connect(function() self:SelectTab(name) end)
		x.MouseButton1Click:Connect(function()
			if #self.Tabs <= 1 then return end
			for i, t in ipairs(self.Tabs) do if t.Name == name then table.remove(self.Tabs, i) break end end
			self.TabsMap[name] = nil
			tabBtn:Destroy() fileRow:Destroy() page:Destroy()
			self:SelectTab(self.Tabs[1].Name)
		end)
		self:SelectTab(name)
		return api
	end

	function Win:SelectTab(name)
		for _, t in ipairs(self.Tabs) do
			local on = t.Name == name
			t.Page.Visible = on
			t.Btn.BackgroundColor3 = on and Theme.TabActive or Theme.TabInactive
			t.Row.BackgroundTransparency = on and 0 or 1
			t.Row.BackgroundColor3 = Theme.RowHover
			for _, c in ipairs(t.Btn:GetChildren()) do if c:IsA("Frame") and c.Name == "Top" then c:Destroy() end end
			if on then
				New("Frame", {Name = "Top", Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = t.Btn})
				self.Current = t
				CrumbPath.Text = title .. " › " .. name
				stLang.Text = " {} " .. (name:match("%.(%w+)$") or "Lua") .. "  "
			end
		end
	end
	function Win:SetStatus(left, right)
		if left then stExec.Text = " " .. left .. " " end
		if right then stLn.Text = " " .. right .. " " end
	end
	function Win:Toggle() Gui.Enabled = not Gui.Enabled end
	function Win:Destroy() Gui:Destroy() end

	stExec.MouseButton1Click:Connect(function() Win:Notify({Title = "Run", Message = "Executed " .. (Win.Current and Win.Current.Name or "script")}) end)
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = SearchBox.Text:lower()
		for _, t in ipairs(Win.Tabs) do
			t.Row.Visible = q == "" or t.Name:lower():find(q, 1, true) ~= nil
		end
	end)
	FilterBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = FilterBox.Text:lower()
		local cur = Win.Current
		if not cur then return end
		for _, sec in ipairs(cur.Page:GetDescendants()) do
			if sec:IsA("TextLabel") and sec.TextSize == 12 then
				local rp = sec.Parent
				if rp and rp:IsA("Frame") and rp.Parent ~= cur.Page then
					rp.Visible = q == "" or sec.Text:lower():find(q, 1, true) ~= nil
				end
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(i, g)
		if g then return end
		if i.KeyCode == toggleKey then Win:Toggle() end
		if i.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then Win:Palette() end
	end)

	local grip = New("TextButton", {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -20, 1, -44), BackgroundTransparency = 1, Text = "◢", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Faint, Parent = Main})
	local rs, sp2, ss = false, nil, nil
	grip.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then rs, sp2, ss = true, i.Position, Main.Size end end)
	UserInputService.InputChanged:Connect(function(i)
		if rs and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - sp2
			Main.Size = UDim2.new(0, math.max(600, ss.X.Offset + d.X), 0, math.max(380, ss.Y.Offset + d.Y))
		end
	end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then rs = false end end)

	return Win
end

return VSCode
