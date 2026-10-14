local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local VSCode = {}
VSCode.__index = VSCode

local Theme = {
	Title = Color3.fromRGB(60, 60, 60),
	Activity = Color3.fromRGB(51, 51, 51),
	Side = Color3.fromRGB(37, 37, 38),
	Editor = Color3.fromRGB(30, 30, 30),
	TabBar = Color3.fromRGB(37, 37, 38),
	TabActive = Color3.fromRGB(30, 30, 30),
	TabInactive = Color3.fromRGB(45, 45, 45),
	Status = Color3.fromRGB(0, 122, 204),
	StatusHover = Color3.fromRGB(0, 145, 234),
	Border = Color3.fromRGB(60, 60, 60),
	Line = Color3.fromRGB(45, 45, 45),
	Input = Color3.fromRGB(60, 60, 60),
	Button = Color3.fromRGB(14, 99, 156),
	ButtonHover = Color3.fromRGB(17, 119, 187),
	Text = Color3.fromRGB(204, 204, 204),
	Dim = Color3.fromRGB(133, 133, 133),
	Faint = Color3.fromRGB(110, 110, 110),
	Accent = Color3.fromRGB(0, 122, 204),
	Green = Color3.fromRGB(137, 209, 133),
	Blue = Color3.fromRGB(86, 156, 214),
	Yellow = Color3.fromRGB(220, 220, 170),
	Orange = Color3.fromRGB(206, 145, 120),
	Hover = Color3.fromRGB(42, 45, 46),
	Select = Color3.fromRGB(55, 55, 61),
}

local function New(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			pcall(function() o[k] = v end)
		end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end

local function Pad(p, b) return New("UIPadding", {PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p), PaddingTop = UDim.new(0, b or p), PaddingBottom = UDim.new(0, b or p)}) end
local function Corner(r) return New("UICorner", {CornerRadius = UDim.new(0, r or 3)}) end
local function Stroke(c, t) return New("UIStroke", {Color = c, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) end
local function List(pad, dir, h, v) return New("UIListLayout", {Padding = UDim.new(0, pad or 4), FillDirection = dir or Enum.FillDirection.Vertical, HorizontalAlignment = h or Enum.HorizontalAlignment.Left, VerticalAlignment = v or Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder}) end

local function Drag(frame, handle)
	local s, sp, gp = false, nil, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			s, sp, gp = true, frame.Position, i.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then s = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if s and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - gp
			frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)
end

function VSCode:CreateWindow(opt)
	opt = opt or {}
	local title = opt.Title or "ExternalNew"
	local toggleKey = opt.ToggleKey or Enum.KeyCode.RightShift
	local accent = opt.Accent or Theme.Status

	local guiName = "VSCode_" .. tostring(math.random(100000, 999999))
	local parent
	pcall(function()
		if gethui then parent = gethui()
		elseif syn and syn.protect_gui then parent = CoreGui end
	end)
	if not parent then parent = CoreGui end
	if getgenv and getgenv().VSCodeGui then pcall(function() getgenv().VSCodeGui:Destroy() end) end

	local Gui = New("ScreenGui", {Name = guiName, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parent})
	if getgenv then getgenv().VSCodeGui = Gui end
	if syn and syn.protect_gui then pcall(syn.protect_gui, Gui) end

	local Main = New("Frame", {Name = "Main", Size = UDim2.new(0, 880, 0, 560), Position = UDim2.new(0.5, -440, 0.5, -280), BackgroundColor3 = Theme.Editor, BorderSizePixel = 0, Active = true, Parent = Gui})
	New("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = Main})
	New("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Main})
	Drag(Main, Main)

	local TitleBar = New("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Title, BorderSizePixel = 0, Parent = Main})
	New("UICorner", {CornerRadius = UDim.new(0, 6), Parent = TitleBar})
	New("Frame", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = Theme.Title, BorderSizePixel = 0, Parent = TitleBar})

	local menus = {"File", "Edit", "Selection", "View", "Go", "Run", "Terminal", "Help"}
	local mx = 10
	for _, m in ipairs(menus) do
		local l = New("TextLabel", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(0, mx, 0, 0), BackgroundTransparency = 1, Text = m, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, Parent = TitleBar})
		mx = mx + l.TextBounds.X + 14
		l:GetPropertyChangedSignal("TextBounds"):Connect(function() end)
	end

	local SearchBox = New("TextBox", {Size = UDim2.new(0, 300, 0, 22), Position = UDim2.new(0.5, -150, 0.5, -11), BackgroundColor3 = Color3.fromRGB(45, 45, 45), TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Dim, PlaceholderText = title, Text = "", Font = Enum.Font.Gotham, TextSize = 11, ClearTextOnFocus = false, Parent = TitleBar})
	Corner(4).Parent = SearchBox
	Stroke(Color3.fromRGB(70, 70, 70)).Parent = SearchBox
	Pad(8, 2).Parent = SearchBox

	local function WinBtn(txt, x, hover)
		local b = New("TextButton", {Size = UDim2.new(0, 42, 1, 0), Position = UDim2.new(1, x, 0, 0), BackgroundTransparency = 1, Text = txt, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, Parent = TitleBar, AutoButtonColor = false})
		b.MouseEnter:Connect(function() b.BackgroundTransparency = hover == "red" and 0 or 0.85 b.BackgroundColor3 = hover == "red" and Color3.fromRGB(196, 43, 28) or Color3.fromRGB(80, 80, 80) end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		return b
	end
	local btnMin = WinBtn("_", -126)
	local btnMax = WinBtn("□", -84)
	local btnX = WinBtn("✕", -42, "red")
	btnX.MouseButton1Click:Connect(function() Gui.Enabled = false end)
	local minimized, full = false, false
	local oldSize, oldPos = Main.Size, Main.Position
	btnMin.MouseButton1Click:Connect(function()
		minimized = not minimized
		Body.Visible = not minimized
		StatusBar.Visible = true
		Main.Size = minimized and UDim2.new(0, 880, 0, 54) or oldSize
	end)
	btnMax.MouseButton1Click:Connect(function()
		full = not full
		Main.Size = full and UDim2.new(1, -40, 1, -40) or UDim2.new(0, 880, 0, 560)
		Main.Position = full and UDim2.new(0, 20, 0, 20) or UDim2.new(0.5, -440, 0.5, -280)
	end)

	local Body = New("Frame", {Name = "Body", Size = UDim2.new(1, 0, 1, -54), Position = UDim2.new(0, 0, 0, 32), BackgroundTransparency = 1, Parent = Main})

	local Activity = New("Frame", {Size = UDim2.new(0, 48, 1, 0), BackgroundColor3 = Theme.Activity, BorderSizePixel = 0, Parent = Body})
	local actIcons = {{"⿻", "Explorer"}, {"⌕", "Search"}, {"⑂", "Source"}, {"▷", "Run"}, {"⧉", "Extensions"}}
	local actBtns = {}
	for i, v in ipairs(actIcons) do
		local b = New("TextButton", {Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Text = v[1], Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = i == 1 and Color3.new(1, 1, 1) or Theme.Faint, Parent = Activity, AutoButtonColor = false})
		if i == 1 then New("Frame", {Name = "Sel", Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = b}) end
		b.MouseButton1Click:Connect(function()
			for _, o in ipairs(actBtns) do o.TextColor3 = Theme.Faint if o:FindFirstChild("Sel") then o.Sel:Destroy() end end
			b.TextColor3 = Color3.new(1, 1, 1)
			New("Frame", {Name = "Sel", Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = b})
			Side.Visible = (v[2] == "Explorer")
		end)
		actBtns[i] = b
	end
	New("TextButton", {Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 1, -80), BackgroundTransparency = 1, Text = "◯", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Theme.Faint, Parent = Activity})
	New("TextButton", {Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 1, -40), BackgroundTransparency = 1, Text = "⚙", Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = Theme.Faint, Parent = Activity})

	local Side = New("Frame", {Name = "Side", Size = UDim2.new(0, 178, 1, 0), Position = UDim2.new(0, 48, 0, 0), BackgroundColor3 = Theme.Side, BorderSizePixel = 0, Parent = Body})
	New("TextLabel", {Size = UDim2.new(1, -12, 0, 28), Position = UDim2.new(0, 12, 0, 2), BackgroundTransparency = 1, Text = "EXPLORER", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.Dim, TextXAlignment = Left, Parent = Side})
	local outline = New("TextLabel", {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 30), BackgroundTransparency = 1, Text = "  ⌄ " .. string.upper(title), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = Side})
	local FileList = New("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -56), Position = UDim2.new(0, 0, 0, 54), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Side})
	List(1).Parent = FileList

	local EditorWrap = New("Frame", {Size = UDim2.new(1, -226, 1, 0), Position = UDim2.new(0, 226, 0, 0), BackgroundColor3 = Theme.Editor, BorderSizePixel = 0, Parent = Body})
	local TabBar = New("Frame", {Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Theme.TabBar, BorderSizePixel = 0, Parent = EditorWrap})
	local TabHold = New("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X, Parent = TabBar})
	local THL = New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabHold})

	local PageHold = New("Frame", {Size = UDim2.new(1, 0, 1, -35), Position = UDim2.new(0, 0, 0, 35), BackgroundTransparency = 1, ClipsDescendants = true, Parent = EditorWrap})

	local MiniMap = New("Frame", {Size = UDim2.new(0, 52, 1, -35), Position = UDim2.new(1, -52, 0, 35), BackgroundTransparency = 0.15, BackgroundColor3 = Theme.Editor, BorderSizePixel = 0, Parent = EditorWrap})
	for i = 1, 42 do
		local w = math.random(18, 44)
		local c = ({Theme.Blue, Theme.Green, Theme.Yellow, Theme.Orange, Color3.fromRGB(150, 120, 200)})[math.random(1, 5)]
		New("Frame", {Size = UDim2.new(0, w, 0, 2), Position = UDim2.new(0, 4, 0, (i - 1) * 12 + 4), BackgroundColor3 = c, BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = MiniMap})
	end

	local StatusBar = New("Frame", {Name = "Status", Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, -22), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = Main})
	New("UICorner", {CornerRadius = UDim.new(0, 6), Parent = StatusBar})
	New("Frame", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = StatusBar})
	local SL = New("Frame", {Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Parent = StatusBar})
	local SLL = New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = SL})
	local SR = New("Frame", {Size = UDim2.new(0.4, -8, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1, Parent = StatusBar})
	local SRL = New("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = SR})

	local function StatBtn(txt, left)
		local b = New("TextButton", {AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, Text = " " .. txt .. " ", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, Parent = left and SL or SR})
		Pad(2, 0).Parent = b
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.75 b.BackgroundColor3 = Color3.new(1, 1, 1) end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		return b
	end
	local stExec = StatBtn("▷ Execute", true)
	local stAttach = StatBtn("⇄ Attach", true)
	local stErr = StatBtn("⊗ 0  ⚠ 0", true)
	local stLn = StatBtn("Ln 21, Col 66", false)
	local stSp = StatBtn("Spaces: 4", false)
	local stEnc = StatBtn("UTF-8", false)
	local stLang = StatBtn("{} Lua", false)

	local Win = {}
	Win.Gui = Gui
	Win.Tabs = {}
	Win.Current = nil

	local Toasts = New("Frame", {Size = UDim2.new(0, 300, 1, -60), Position = UDim2.new(1, -310, 0, 10), BackgroundTransparency = 1, Parent = Main})

	function Win:Notify(o)
		o = type(o) == "string" and {Message = o} or o
		local t = New("Frame", {Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = Theme.Side, BorderSizePixel = 0, Parent = Toasts})
		Corner(4).Parent = t Stroke(Theme.Border).Parent = t
		New("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = t})
		New("TextLabel", {Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 12, 0, 4), BackgroundTransparency = 1, Text = o.Title or title, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = t})
		New("TextLabel", {Size = UDim2.new(1, -16, 0, 26), Position = UDim2.new(0, 12, 0, 22), BackgroundTransparency = 1, Text = o.Message or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Left, TextYAlignment = Top, TextWrapped = true, Parent = t})
		t.Position = UDim2.new(0, 320, 0, 0)
		TweenService:Create(t, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
		task.delay(o.Duration or 4, function()
			pcall(function()
				TweenService:Create(t, TweenInfo.new(0.25), {Position = UDim2.new(0, 320, 0, 0)}):Play()
				task.wait(0.25) t:Destroy()
			end)
		end)
		local n = 0 for _, c in ipairs(Toasts:GetChildren()) do if c:IsA("Frame") then n = n + 1 c.LayoutOrder = -n end end
	end

	local Palette = New("Frame", {Size = UDim2.new(0, 440, 0, 300), Position = UDim2.new(0.5, -220, 0, 40), BackgroundColor3 = Theme.Side, BorderSizePixel = 0, Visible = false, ZIndex = 50, Parent = Main})
	Corner(6).Parent = Palette Stroke(Theme.Border).Parent = Palette
	local PIn = New("TextBox", {Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Dim, PlaceholderText = "> Type a command...", Text = "", Font = Enum.Font.Code, TextSize = 12, Parent = Palette})
	Corner(4).Parent = PIn Pad(8, 4).Parent = PIn
	local PList = New("ScrollingFrame", {Size = UDim2.new(1, -16, 1, -52), Position = UDim2.new(0, 8, 0, 44), BackgroundTransparency = 1, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Palette})
	List(2).Parent = PList
	local function refreshPalette(q)
		for _, c in ipairs(PList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		q = (q or ""):lower()
		for _, tb in ipairs(Win.Tabs) do
			if tb.Name:lower():find(q, 1, true) then
				local b = New("TextButton", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "  ◈ " .. tb.Name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = PList})
				b.MouseEnter:Connect(function() b.BackgroundColor3 = Theme.Select b.BackgroundTransparency = 0 end)
				b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
				b.MouseButton1Click:Connect(function() Win:SelectTab(tb.Name) Palette.Visible = false end)
			end
		end
	end
	PIn:GetPropertyChangedSignal("Text"):Connect(function() refreshPalette(PIn.Text:gsub("^>", "")) end)

	function Win:Palette() Palette.Visible = not Palette.Visible if Palette.Visible then refreshPalette("") PIn.Text = "" PIn:CaptureFocus() end end

	local function makeRow(page, h)
		local r = New("Frame", {Size = UDim2.new(1, -14, 0, h or 32), BackgroundTransparency = 1, Parent = page})
		r.MouseEnter:Connect(function() r.BackgroundTransparency = 0.85 r.BackgroundColor3 = Theme.Hover end)
		r.MouseLeave:Connect(function() r.BackgroundTransparency = 1 end)
		return r
	end

	local Ctrl = {}

	function Ctrl:AddSection(name)
		local s = New("TextLabel", {Size = UDim2.new(1, -14, 0, 24), BackgroundTransparency = 1, Text = "⌄ " .. name:upper(), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = self.Page})
		return s
	end

	function Ctrl:AddLabel(txt)
		local l = New("TextLabel", {Size = UDim2.new(1, -14, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = txt, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Left, TextWrapped = true, Parent = self.Page})
		Pad(0, 4).Parent = l
		return {Set = function(_, t) l.Text = t end}
	end

	function Ctrl:AddButton(o)
		o = type(o) == "string" and {Name = o} or o
		local r = makeRow(self.Page, 36)
		local b = New("TextButton", {Size = UDim2.new(1, -8, 0, 26), Position = UDim2.new(0, 4, 0, 5), BackgroundColor3 = Theme.Button, TextColor3 = Color3.new(1, 1, 1), Text = o.Name or "Execute", Font = Enum.Font.Gotham, TextSize = 12, AutoButtonColor = false, Parent = r})
		Corner(3).Parent = b
		b.MouseEnter:Connect(function() b.BackgroundColor3 = Theme.ButtonHover end)
		b.MouseLeave:Connect(function() b.BackgroundColor3 = Theme.Button end)
		b.MouseButton1Click:Connect(function() pcall(o.Callback or function() end) end)
		return {Fire = function() pcall(o.Callback or function() end) end}
	end

	function Ctrl:AddToggle(o)
		local val = o.Default or false
		local cb = o.Callback or function() end
		local r = makeRow(self.Page, 30)
		New("TextLabel", {Size = UDim2.new(1, -52, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Toggle", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local box = New("TextButton", {Size = UDim2.new(0, 32, 0, 18), Position = UDim2.new(1, -40, 0.5, -9), BackgroundColor3 = val and Theme.Accent or Color3.fromRGB(60, 60, 60), Text = "", AutoButtonColor = false, Parent = r})
		Corner(9).Parent = box
		local dot = New("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = val and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = box})
		Corner(7).Parent = dot
		local function set(v)
			val = v
			TweenService:Create(box, TweenInfo.new(0.15), {BackgroundColor3 = val and Theme.Accent or Color3.fromRGB(60, 60, 60)}):Play()
			TweenService:Create(dot, TweenInfo.new(0.15), {Position = val and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
			pcall(cb, val)
		end
		box.MouseButton1Click:Connect(function() set(not val) end)
		if val then pcall(cb, val) end
		return {Set = set, Get = function() return val end}
	end

	function Ctrl:AddSlider(o)
		local min, max, val = o.Min or 0, o.Max or 100, o.Default or 50
		local cb = o.Callback or function() end
		local r = makeRow(self.Page, 46)
		New("TextLabel", {Size = UDim2.new(1, -14, 0, 16), Position = UDim2.new(0, 6, 0, 2), BackgroundTransparency = 1, Text = (o.Name or "Slider") .. "  <font color=\"#858585\">" .. tostring(val) .. "</font>", RichText = true, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = r})
		local bar = New("Frame", {Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 0, 28), BackgroundColor3 = Color3.fromRGB(60, 60, 60), BorderSizePixel = 0, Parent = r})
		Corner(2).Parent = bar
		local fill = New("Frame", {Size = UDim2.new((val - min) / math.max(1, max - min), 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = bar})
		Corner(2).Parent = fill
		local knob = New("Frame", {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new((val - min) / math.max(1, max - min), -6, 0.5, -6), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = bar})
		Corner(6).Parent = knob
		local drag = false
		local function upd(x)
			local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			val = math.floor(min + (max - min) * p)
			fill.Size = UDim2.new(p, 0, 1, 0)
			knob.Position = UDim2.new(p, -6, 0.5, -6)
			r:FindFirstChildWhichIsA("TextLabel").Text = (o.Name or "Slider") .. "  <font color=\"#858585\">" .. tostring(val) .. "</font>"
			pcall(cb, val)
		end
		bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true upd(i.Position.X) end end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
		UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
		return {Set = function(_, v) val = math.clamp(v, min, max) local p = (val - min) / math.max(1, max - min) fill.Size = UDim2.new(p, 0, 1, 0) knob.Position = UDim2.new(p, -6, 0.5, -6) pcall(cb, val) end, Get = function() return val end}
	end

	function Ctrl:AddDropdown(o)
		local opts = o.Options or {"Option 1"}
		local val = o.Default or opts[1]
		local cb = o.Callback or function() end
		local open = false
		local r = makeRow(self.Page, 30)
		New("TextLabel", {Size = UDim2.new(0.55, 0, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Dropdown", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local b = New("TextButton", {Size = UDim2.new(0.45, -14, 0, 22), Position = UDim2.new(0.55, 4, 0.5, -11), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, Text = " " .. tostring(val) .. "  ▾", Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		Corner(3).Parent = b
		local drop
		b.MouseButton1Click:Connect(function()
			open = not open
			if drop then drop:Destroy() drop = nil end
			if not open then return end
			drop = New("Frame", {Size = UDim2.new(0, b.AbsoluteSize.X, 0, math.min(#opts * 24 + 6, 130)), Position = UDim2.new(0, b.AbsolutePosition.X - Main.AbsolutePosition.X, 0, b.AbsolutePosition.Y - Main.AbsolutePosition.Y + 24), BackgroundColor3 = Theme.Side, ZIndex = 40, Parent = Main})
			Corner(4).Parent = drop Stroke(Theme.Border).Parent = drop
			local sl = New("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = drop})
			List(1).Parent = sl
			for _, op in ipairs(opts) do
				local ob = New("TextButton", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "  " .. tostring(op), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = sl})
				ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0 ob.BackgroundColor3 = Theme.Select end)
				ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1 end)
				ob.MouseButton1Click:Connect(function() val = op b.Text = " " .. tostring(val) .. "  ▾" open = false drop:Destroy() drop = nil pcall(cb, val) end)
			end
		end)
		return {Set = function(_, v) val = v b.Text = " " .. tostring(val) .. "  ▾" pcall(cb, val) end, Get = function() return val end}
	end

	function Ctrl:AddTextbox(o)
		local cb = o.Callback or function() end
		local r = makeRow(self.Page, 30)
		New("TextLabel", {Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Input", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		local t = New("TextBox", {Size = UDim2.new(0.55, -14, 0, 22), Position = UDim2.new(0.45, 4, 0.5, -11), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Faint, PlaceholderText = o.Placeholder or "", Text = o.Default or "", Font = Enum.Font.Code, TextSize = 11, ClearTextOnFocus = false, Parent = r})
		Corner(3).Parent = t Pad(6, 2).Parent = t
		t.FocusLost:Connect(function(e) if e then pcall(cb, t.Text) end end)
		return {Set = function(_, v) t.Text = v end, Get = function() return t.Text end}
	end

	function Ctrl:AddKeybind(o)
		local val = o.Default or Enum.KeyCode.F
		local cb = o.Callback or function() end
		local r = makeRow(self.Page, 30)
		New("TextLabel", {Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Keybind", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = r})
		local b = New("TextButton", {Size = UDim2.new(0, 80, 0, 22), Position = UDim2.new(1, -90, 0.5, -11), BackgroundColor3 = Theme.Input, TextColor3 = Theme.Text, Text = val.Name, Font = Enum.Font.Gotham, TextSize = 11, Parent = r})
		Corner(3).Parent = b
		local waiting = false
		b.MouseButton1Click:Connect(function() waiting = true b.Text = "..." end)
		UserInputService.InputBegan:Connect(function(i, g)
			if waiting and i.UserInputType == Enum.UserInputType.Keyboard then waiting = false val = i.KeyCode b.Text = val.Name return end
			if not g and i.KeyCode == val then pcall(cb, val) end
		end)
		return {Set = function(_, v) val = v b.Text = val.Name end, Get = function() return val end}
	end

	function Ctrl:AddColorPicker(o)
		local val = o.Default or Color3.fromRGB(0, 122, 204)
		local cb = o.Callback or function() end
		local r = makeRow(self.Page, 30)
		New("TextLabel", {Size = UDim2.new(1, -52, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = o.Name or "Accent", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, TextXAlignment = Left, Parent = r})
		local b = New("TextButton", {Size = UDim2.new(0, 30, 0, 18), Position = UDim2.new(1, -40, 0.5, -9), BackgroundColor3 = val, Text = "", Parent = r})
		Corner(3).Parent = b Stroke(Color3.fromRGB(90, 90, 90)).Parent = b
		local presets = {Color3.fromRGB(0,122,204), Color3.fromRGB(197,134,192), Color3.fromRGB(137,209,133), Color3.fromRGB(220,220,170), Color3.fromRGB(206,145,120), Color3.fromRGB(220,80,80)}
		b.MouseButton1Click:Connect(function()
			local i = 1
			for n, c in ipairs(presets) do if c == val then i = n break end end
			val = presets[(i % #presets) + 1]
			b.BackgroundColor3 = val
			pcall(cb, val)
		end)
		return {Set = function(_, v) val = v b.BackgroundColor3 = v end, Get = function() return val end}
	end

	function Win:NewTab(name, icon)
		name = name or ("untitled-" .. (#self.Tabs + 1) .. ".lua")
		if self.TabsMap and self.TabsMap[name] then self:SelectTab(name) return self.TabsMap[name].Api end
		self.TabsMap = self.TabsMap or {}

		local tabBtn = New("TextButton", {Size = UDim2.new(0, 130, 1, 0), BackgroundColor3 = Theme.TabInactive, Text = "", AutoButtonColor = false, Parent = TabHold})
		New("TextLabel", {Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = "◈", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.Blue, TextYAlignment = Center, Parent = tabBtn})
		New("TextLabel", {Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 24, 0, 0), BackgroundTransparency = 1, Text = name, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = tabBtn})
		local x = New("TextButton", {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -22, 0.5, -10), BackgroundTransparency = 1, Text = "✕", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.Dim, Parent = tabBtn})

		local fileRow = New("TextButton", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = FileList})
		New("TextLabel", {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 22, 0, 0), BackgroundTransparency = 1, Text = "◈  " .. name, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text, TextXAlignment = Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = fileRow})

		local page = New("ScrollingFrame", {Size = UDim2.new(1, -64, 1, -8), Position = UDim2.new(0, 6, 0, 4), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = PageHold})
		List(4).Parent = page
		Pad(4, 4).Parent = page

		local api = {Name = name, Page = page}
		setmetatable(api, {__index = Ctrl})

		local entry = {Name = name, Btn = tabBtn, Row = fileRow, Page = page, Api = api}
		table.insert(self.Tabs, entry)
		self.TabsMap[name] = entry

		local function select()
			self:SelectTab(name)
		end
		tabBtn.MouseButton1Click:Connect(select)
		fileRow.MouseButton1Click:Connect(select)
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
			t.Row.BackgroundColor3 = Theme.Select
			for _, c in ipairs(t.Btn:GetChildren()) do if c:IsA("Frame") and c.Name == "Top" then c:Destroy() end end
			if on then
				New("Frame", {Name = "Top", Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = accent, BorderSizePixel = 0, Parent = t.Btn})
				self.Current = t
				stLn.Text = " Ln 1, Col 1  "
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
			local show = q == "" or t.Name:lower():find(q, 1, true)
			t.Row.Visible = show ~= nil and show ~= false
		end
	end)

	UserInputService.InputBegan:Connect(function(i, g)
		if g then return end
		if i.KeyCode == toggleKey then Win:Toggle() end
		if i.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then Win:Palette() end
	end)

	local grip = New("TextButton", {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -18, 1, -40), BackgroundTransparency = 1, Text = "◢", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Faint, Parent = Main})
	local rs, sp2, ss = false, nil, nil
	grip.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then rs, sp2, ss = true, i.Position, Main.Size end end)
	UserInputService.InputChanged:Connect(function(i)
		if rs and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - sp2
			Main.Size = UDim2.new(0, math.max(560, ss.X.Offset + d.X), 0, math.max(360, ss.Y.Offset + d.Y))
		end
	end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then rs = false end end)

	return Win
end

return VSCode
