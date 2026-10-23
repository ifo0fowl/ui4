local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or nil
if env and env.ArcaneLibrary then
    pcall(function() env.ArcaneLibrary:Unload() end)
end

local Library = {
    Flags = {},
    Options = {},
    Binds = {},
    Registry = {},
    Hooks = {},
    Localized = {},
    Connections = {},
    Windows = {},
    Language = "ENG",
    Translations = { RUS = {} },
    Theme = "Dark",
    MenuKey = Enum.KeyCode.RightShift,
    Listening = false,
    Unloaded = false,
}

Library.Themes = {
    Dark = {
        Background = Color3.fromRGB(17, 17, 21),
        Panel = Color3.fromRGB(25, 25, 30),
        Element = Color3.fromRGB(32, 32, 39),
        Stroke = Color3.fromRGB(44, 44, 53),
        Text = Color3.fromRGB(236, 236, 242),
        SubText = Color3.fromRGB(145, 145, 156),
        Accent = Color3.fromRGB(230, 20, 70),
        Knob = Color3.fromRGB(255, 255, 255),
    },
    Light = {
        Background = Color3.fromRGB(238, 238, 243),
        Panel = Color3.fromRGB(249, 249, 252),
        Element = Color3.fromRGB(228, 228, 235),
        Stroke = Color3.fromRGB(208, 208, 217),
        Text = Color3.fromRGB(26, 26, 32),
        SubText = Color3.fromRGB(105, 105, 118),
        Accent = Color3.fromRGB(230, 20, 70),
        Knob = Color3.fromRGB(255, 255, 255),
    },
}

local WHITE = Color3.new(1, 1, 1)
local SUCCESS = Color3.fromRGB(70, 200, 120)
local DANGER = Color3.fromRGB(235, 70, 70)

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------
local function T()
    return Library.Themes[Library.Theme]
end

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end

local function New(class, props)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then
        o.BorderSizePixel = 0
    end
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
        o.Font = Enum.Font.GothamMedium
        o.TextSize = 12
        o.BackgroundTransparency = 1
        o.Text = ""
    end
    if o:IsA("TextButton") then
        o.AutoButtonColor = false
    end
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else o[k] = v end
    end
    if parent then o.Parent = parent end
    return o
end

local function Theme(inst, prop, key)
    table.insert(Library.Registry, { inst = inst, prop = prop, key = key })
    inst[prop] = T()[key]
end

local function Hook(fn)
    table.insert(Library.Hooks, fn)
    fn()
end

local function Corner(parent, r)
    return New("UICorner", { CornerRadius = UDim.new(0, r), Parent = parent })
end

local function Stroke(parent, key)
    local s = New("UIStroke", {
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
    Theme(s, "Color", key or "Stroke")
    return s
end

local function Pad(parent, l, t, r, b)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        Parent = parent,
    })
end

local function List(parent, pad, horizontal)
    return New("UIListLayout", {
        Padding = UDim.new(0, pad or 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        Parent = parent,
    })
end

local function Tween(o, t, props, style)
    TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

function Library:Tr(text)
    if self.Language ~= "ENG" then
        local tbl = self.Translations[self.Language]
        if tbl and tbl[text] then return tbl[text] end
    end
    return text
end

local function Localize(inst, text)
    inst.Text = Library:Tr(text)
    table.insert(Library.Localized, { inst = inst, text = text })
end

local function Lbl(props, key, text)
    local l = New("TextLabel", props)
    Theme(l, "TextColor3", key or "Text")
    if text then Localize(l, text) end
    return l
end

local function Decimals(n)
    local d = tostring(n):match("%.(%d+)")
    return d and #d or 0
end

local function Serialize(v)
    if typeof(v) == "Color3" then return { __c = v:ToHex() } end
    if typeof(v) == "EnumItem" then return { __k = v.Name } end
    return v
end

local function Deserialize(v)
    if type(v) == "table" then
        if v.__c then return Color3.fromHex(v.__c) end
        if v.__k then return Enum.KeyCode[v.__k] end
    end
    return v
end

local function BindDrag(frame, fn)
    local active = false
    Connect(frame.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            active = true
            fn(i.Position, true)
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if active and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            fn(i.Position, false)
        end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            active = false
        end
    end)
end

local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    Connect(handle.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = target.Position
        end
    end)
    Connect(UserInputService.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function Element(flag, value, callback)
    local self = { Value = value, Flag = flag, Callback = callback, Listeners = {} }
    function self:OnChanged(fn) table.insert(self.Listeners, fn) end
    function self:Get() return self.Value end
    function self:_commit(silent)
        if self.Flag then Library.Flags[self.Flag] = self.Value end
        if silent then return end
        if self.Callback then task.spawn(self.Callback, self.Value) end
        for _, f in ipairs(self.Listeners) do task.spawn(f, self.Value) end
    end
    if flag then
        Library.Flags[flag] = value
        Library.Options[flag] = self
    end
    return self
end

--------------------------------------------------------------------------------
-- gui root
--------------------------------------------------------------------------------
local Gui = New("ScreenGui", {
    Name = "ArcaneUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
})
if syn and syn.protect_gui then pcall(syn.protect_gui, Gui) end
local parented = false
if typeof(gethui) == "function" then
    parented = pcall(function() Gui.Parent = gethui() end) and Gui.Parent ~= nil
end
if not parented then
    parented = pcall(function() Gui.Parent = CoreGui end) and Gui.Parent ~= nil
end
if not parented then
    Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
Library.Gui = Gui

--------------------------------------------------------------------------------
-- vector icons (drawn from frames, 16x16 design grid)
--------------------------------------------------------------------------------
local IconBuilders = {}

IconBuilders.home = function(b)
    b.bar(5, 5, 8, 1.6, -40, 0.5)
    b.bar(11, 5, 8, 1.6, 40, 0.5)
    b.bar(3.6, 10.6, 1.6, 6.4, 0, 0.5)
    b.bar(12.4, 10.6, 1.6, 6.4, 0, 0.5)
    b.bar(8, 13.4, 10, 1.6, 0, 0.5)
    b.bar(8, 11.4, 2, 4, 0, 0.3)
end

IconBuilders.crosshair = function(b)
    b.ring(8, 8, 10.5, 10.5, 1.5)
    b.bar(8, 2.6, 1.6, 4.4, 0, 0.5)
    b.bar(8, 13.4, 1.6, 4.4, 0, 0.5)
    b.bar(2.6, 8, 4.4, 1.6, 0, 0.5)
    b.bar(13.4, 8, 4.4, 1.6, 0, 0.5)
    b.bar(8, 8, 2, 2, 0, 0.5)
end

IconBuilders.gear = function(b)
    b.ring(8, 8, 10, 10, 2)
    for k = 0, 7 do
        local a = math.rad(k * 45)
        b.bar(8 + 6 * math.sin(a), 8 - 6 * math.cos(a), 2.2, 3, k * 45, 0.2)
    end
end

IconBuilders.sun = function(b)
    b.bar(8, 8, 6, 6, 0, 0.5)
    for k = 0, 7 do
        local a = math.rad(k * 45)
        b.bar(8 + 5.8 * math.sin(a), 8 - 5.8 * math.cos(a), 1.5, 2.4, k * 45, 0.5)
    end
end

IconBuilders.moon = function(b)
    b.bar(8, 8, 11, 11, 0, 0.5)
    b.bar(11.2, 5.6, 9.4, 9.4, 0, 0.5, "cut")
end

IconBuilders.user = function(b)
    b.bar(8, 5, 6, 6, 0, 0.5)
    local c = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(8 / 16, 12 / 16),
        Size = UDim2.fromScale(12 / 16, 5 / 16), BackgroundTransparency = 1,
        ClipsDescendants = true, Parent = b.root,
    })
    local d = New("Frame", { Size = UDim2.fromScale(1, 2.4), BackgroundColor3 = WHITE, Parent = c })
    New("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = d })
    b.add(d, "fill")
end

IconBuilders.eye = function(b)
    b.ring(8, 8, 14, 9, 1.5)
    b.bar(8, 8, 4, 4, 0, 0.5)
end

IconBuilders.grid = function(b)
    b.bar(4.5, 4.5, 5, 5, 0, 0.2)
    b.bar(11.5, 4.5, 5, 5, 0, 0.2)
    b.bar(4.5, 11.5, 5, 5, 0, 0.2)
    b.bar(11.5, 11.5, 5, 5, 0, 0.2)
end

IconBuilders.dots = function(b)
    b.bar(3, 8, 2.8, 2.8, 0, 0.5)
    b.bar(8, 8, 2.8, 2.8, 0, 0.5)
    b.bar(13, 8, 2.8, 2.8, 0, 0.5)
end

-- aliases
IconBuilders.combat = IconBuilders.crosshair
IconBuilders.settings = IconBuilders.gear
IconBuilders.player = IconBuilders.user
IconBuilders.visuals = IconBuilders.eye
IconBuilders.misc = IconBuilders.grid

local function MakeIcon(name, parent, size, centered)
    local api = { SetColor = function() end, SetCut = function() end }
    if not name or name == "" then return api end
    local function place(o)
        if centered then
            o.AnchorPoint = Vector2.new(0.5, 0.5)
            o.Position = UDim2.fromScale(0.5, 0.5)
        end
    end

    local asNumber = tostring(name):match("^%d+$")
    if asNumber or tostring(name):find("rbxassetid") then
        local id = asNumber and ("rbxassetid://" .. name) or tostring(name)
        local img = New("ImageLabel", { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Image = id, Parent = parent })
        place(img)
        api.SetColor = function(c) img.ImageColor3 = c end
        return api
    end

    local builder = IconBuilders[string.lower(tostring(name))]
    if not builder then
        local l = New("TextLabel", { Size = UDim2.fromOffset(size, size), Text = tostring(name), TextSize = size, Parent = parent })
        place(l)
        api.SetColor = function(c) l.TextColor3 = c end
        return api
    end

    local root = New("Frame", { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Parent = parent })
    place(root)
    local parts = {}
    local b = { root = root }
    function b.add(inst, kind) parts[#parts + 1] = { inst = inst, kind = kind } end
    function b.bar(x, y, w, h, rot, round, kind)
        local f = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x / 16, y / 16),
            Size = UDim2.fromScale(w / 16, h / 16), Rotation = rot or 0, BackgroundColor3 = WHITE, Parent = root,
        })
        if round and round > 0 then New("UICorner", { CornerRadius = UDim.new(round, 0), Parent = f }) end
        b.add(f, kind or "fill")
    end
    function b.ring(x, y, w, h, th)
        local f = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x / 16, y / 16),
            Size = UDim2.fromScale((w - 2 * th) / 16, (h - 2 * th) / 16), BackgroundTransparency = 1, Parent = root,
        })
        New("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = f })
        local s = New("UIStroke", { Thickness = th * size / 16, Color = WHITE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f })
        b.add(s, "stroke")
    end
    builder(b)

    api.SetColor = function(c)
        for _, p in ipairs(parts) do
            if p.kind == "fill" then p.inst.BackgroundColor3 = c
            elseif p.kind == "stroke" then p.inst.Color = c end
        end
    end
    api.SetCut = function(c)
        for _, p in ipairs(parts) do
            if p.kind == "cut" then p.inst.BackgroundColor3 = c end
        end
    end
    api.Root = root
    return api
end
Library.MakeIcon = MakeIcon

--------------------------------------------------------------------------------
-- tooltip
--------------------------------------------------------------------------------
local Tip
local function EnsureTip()
    if Tip then return end
    Tip = {}
    Tip.Frame = New("Frame", {
        Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
        Visible = false, ZIndex = 200, Parent = Gui,
    })
    Theme(Tip.Frame, "BackgroundColor3", "Panel")
    Corner(Tip.Frame, 5)
    Stroke(Tip.Frame)
    Tip.Label = Lbl({
        Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, TextWrapped = true,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201, Parent = Tip.Frame,
    }, "Text")
    Pad(Tip.Label, 8, 5, 8, 5)
    New("UISizeConstraint", { MaxSize = Vector2.new(240, math.huge), Parent = Tip.Label })
    Connect(UserInputService.InputChanged, function(i)
        if Tip.Frame.Visible and i.UserInputType == Enum.UserInputType.MouseMovement then
            local m = UserInputService:GetMouseLocation()
            Tip.Frame.Position = UDim2.fromOffset(m.X + 14, m.Y + 14)
        end
    end)
end

local function HelpChip(parent, text, order)
    local chip = New("TextButton", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        Text = "[ ? ]", TextSize = 10, LayoutOrder = order or 2, Parent = parent,
    })
    Theme(chip, "TextColor3", "SubText")
    chip.MouseEnter:Connect(function()
        EnsureTip()
        Tip.Label.Text = text
        local m = UserInputService:GetMouseLocation()
        Tip.Frame.Position = UDim2.fromOffset(m.X + 14, m.Y + 14)
        Tip.Frame.Visible = true
        chip.TextColor3 = T().Accent
    end)
    chip.MouseLeave:Connect(function()
        if Tip then Tip.Frame.Visible = false end
        chip.TextColor3 = T().SubText
    end)
    return chip
end

-- name + optional tooltip chip on one line. returns row, label(button)
local function NameRow(parent, name, tip, size, order)
    local row = New("Frame", { Size = size, BackgroundTransparency = 1, LayoutOrder = order or 0, Parent = parent })
    local l = List(row, 4, true)
    l.VerticalAlignment = Enum.VerticalAlignment.Center
    local label = New("TextButton", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = row,
    })
    Theme(label, "TextColor3", "Text")
    Localize(label, name or "")
    if tip then HelpChip(row, tip, 2) end
    return row, label
end

--------------------------------------------------------------------------------
-- key chip + keybinds
--------------------------------------------------------------------------------
local KeyNames = {
    LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl",
    LeftAlt = "LAlt", RightAlt = "RAlt", Return = "Enter", Backspace = "Back", Escape = "Esc",
}
local function KeyText(k)
    if not k then return "None" end
    return KeyNames[k.Name] or k.Name
end

local function MakeKeyChip(parent, order, default, onChange)
    local state = { Key = default, Listening = false }
    local chip = New("TextButton", {
        Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = order,
        Font = Enum.Font.GothamBold, TextSize = 11, Parent = parent,
    })
    Pad(chip, 3, 0, 3, 0)
    Theme(chip, "TextColor3", "SubText")
    local function refresh() chip.Text = "[" .. KeyText(state.Key) .. "]" end
    refresh()
    state.Button = chip
    function state:Set(k)
        self.Key = k
        refresh()
        if onChange then onChange(k) end
    end
    chip.MouseButton1Click:Connect(function()
        if state.Listening then return end
        state.Listening = true
        Library.Listening = true
        chip.Text = "[...]"
        chip.TextColor3 = T().Accent
        local c
        c = UserInputService.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Keyboard then
                c:Disconnect()
                state.Listening = false
                chip.TextColor3 = T().SubText
                task.defer(function() Library.Listening = false end)
                if i.KeyCode == Enum.KeyCode.Escape then state:Set(nil) else state:Set(i.KeyCode) end
            end
        end)
    end)
    return state
end

local function AttachKeybind(holder, obj, name, default, order, mode)
    local bind = { Name = name, Obj = obj, Mode = mode or "Toggle" }
    bind.Chip = MakeKeyChip(holder, order, typeof(default) == "EnumItem" and default or nil, function(k)
        bind.Key = k
        Library:RefreshKeybindList()
    end)
    bind.Key = bind.Chip.Key
    bind.Chip.Button.MouseButton2Click:Connect(function()
        bind.Mode = (bind.Mode == "Toggle") and "Hold" or "Toggle"
        Library:Notify(tostring(name) .. ": " .. bind.Mode .. " mode", 2)
        Library:RefreshKeybindList()
    end)
    table.insert(Library.Binds, bind)
    obj:OnChanged(function() Library:RefreshKeybindList() end)
    obj.Bind = bind
    return bind
end

Connect(UserInputService.InputBegan, function(input, processed)
    if processed or Library.Listening then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if Library.MenuKey and input.KeyCode == Library.MenuKey then
        Library:Toggle()
        return
    end
    for _, b in ipairs(Library.Binds) do
        if b.Key and b.Key == input.KeyCode then
            if b.Fire then
                b.Fire()
            elseif b.Mode == "Hold" then
                b.Obj:Set(true)
            else
                b.Obj:Set(not b.Obj.Value)
            end
        end
    end
end)

Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    for _, b in ipairs(Library.Binds) do
        if b.Mode == "Hold" and b.Obj and b.Key == input.KeyCode then
            b.Obj:Set(false)
        end
    end
end)

--------------------------------------------------------------------------------
-- switch widget (shared by toggles and section header toggles)
--------------------------------------------------------------------------------
local function CreateSwitch(cfg, holder, name)
    local obj = Element(cfg.Flag, cfg.Default and true or false, cfg.Callback)
    local sw = New("TextButton", {
        Size = UDim2.fromOffset(30, 14), LayoutOrder = 3, BackgroundTransparency = 0, Parent = holder,
    })
    Corner(sw, 7)
    local knob = New("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(2, 2), Parent = sw })
    Theme(knob, "BackgroundColor3", "Knob")
    Corner(knob, 5)

    local function apply(instant)
        local col = obj.Value and T().Accent or T().Stroke
        local pos = obj.Value and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)
        if instant then
            sw.BackgroundColor3 = col
            knob.Position = pos
        else
            Tween(sw, 0.14, { BackgroundColor3 = col })
            Tween(knob, 0.14, { Position = pos }, Enum.EasingStyle.Back)
        end
    end
    apply(true)
    table.insert(Library.Hooks, function() apply(true) end)

    function obj:Set(v, silent)
        v = v and true or false
        if self.Value == v then return end
        self.Value = v
        apply(false)
        self:_commit(silent)
    end
    sw.MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)

    if cfg.Keybind ~= nil and cfg.Keybind ~= false then
        AttachKeybind(holder, obj, name, cfg.Keybind, 2, cfg.Mode)
    end
    obj.Button = sw
    return obj
end

--------------------------------------------------------------------------------
-- Section
--------------------------------------------------------------------------------
local Section = {}
Section.__index = Section

function Section:_Order()
    self._n = self._n + 1
    return self._n
end

function Section:AddToggle(cfg)
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = self:_Order(), Parent = self.Body })
    local _, label = NameRow(row, cfg.Name, cfg.Tooltip, UDim2.new(1, -70, 1, 0))
    local holder = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1, Parent = row,
    })
    local l = List(holder, 6, true)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Right
    l.VerticalAlignment = Enum.VerticalAlignment.Center
    local obj = CreateSwitch(cfg, holder, cfg.Name)
    label.MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)
    return obj
end

function Section:AddSlider(cfg)
    local min, max, inc = cfg.Min or 0, cfg.Max or 100, cfg.Increment or 1
    local dec = Decimals(inc)
    local suffix = cfg.Suffix or ""
    local function snap(v)
        v = math.floor((v - min) / inc + 0.5) * inc + min
        v = math.clamp(v, min, max)
        return tonumber(string.format("%." .. dec .. "f", v))
    end
    local obj = Element(cfg.Flag, snap(cfg.Default or min), cfg.Callback)

    local holder = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = self:_Order(), Parent = self.Body })
    local _, nameLabel = NameRow(holder, cfg.Name, cfg.Tooltip, UDim2.new(0.6, 0, 0, 14))
    nameLabel.TextColor3 = T().SubText
    Theme(nameLabel, "TextColor3", "SubText")
    local valueLabel = Lbl({
        Size = UDim2.new(0.4, 0, 0, 14), Position = UDim2.fromScale(0.6, 0),
        TextXAlignment = Enum.TextXAlignment.Right, Parent = holder,
    }, "Text")
    local track = New("TextButton", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 17), Parent = holder })
    local bar = New("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2), Parent = track })
    Theme(bar, "BackgroundColor3", "Stroke")
    Corner(bar, 2)
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), Parent = bar })
    Theme(fill, "BackgroundColor3", "Accent")
    Corner(fill, 2)
    local knob = New("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), Parent = bar })
    Theme(knob, "BackgroundColor3", "Knob")
    Corner(knob, 3)

    local function update()
        local a = (max == min) and 0 or (obj.Value - min) / (max - min)
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        valueLabel.Text = string.format("%." .. dec .. "f", obj.Value) .. suffix
    end
    update()

    function obj:Set(v, silent)
        v = snap(tonumber(v) or min)
        local changed = v ~= self.Value
        self.Value = v
        update()
        if changed then self:_commit(silent) end
    end
    BindDrag(track, function(pos, began)
        local a = math.clamp((pos.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        obj:Set(min + (max - min) * a)
        if began then Tween(knob, 0.1, { Size = UDim2.fromOffset(12, 12) }) end
    end)
    Connect(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            Tween(knob, 0.1, { Size = UDim2.fromOffset(10, 10) })
        end
    end)
    return obj
end

function Section:AddRangeSlider(cfg)
    local min, max, inc = cfg.Min or 0, cfg.Max or 100, cfg.Increment or 1
    local dec = Decimals(inc)
    local suffix = cfg.Suffix or ""
    local function snap(v)
        v = math.floor((v - min) / inc + 0.5) * inc + min
        v = math.clamp(v, min, max)
        return tonumber(string.format("%." .. dec .. "f", v))
    end
    local d = cfg.Default or { min, max }
    local obj = Element(cfg.Flag, { snap(d[1]), snap(d[2]) }, cfg.Callback)

    local holder = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = self:_Order(), Parent = self.Body })
    local _, nameLabel = NameRow(holder, cfg.Name, cfg.Tooltip, UDim2.new(0.5, 0, 0, 14))
    Theme(nameLabel, "TextColor3", "SubText")
    local valueLabel = Lbl({
        Size = UDim2.new(0.5, 0, 0, 14), Position = UDim2.fromScale(0.5, 0),
        TextXAlignment = Enum.TextXAlignment.Right, Parent = holder,
    }, "Text")
    local track = New("TextButton", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 17), Parent = holder })
    local bar = New("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2), Parent = track })
    Theme(bar, "BackgroundColor3", "Stroke")
    Corner(bar, 2)
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), Parent = bar })
    Theme(fill, "BackgroundColor3", "Accent")
    Corner(fill, 2)
    local knobs = {}
    for i = 1, 2 do
        knobs[i] = New("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), Parent = bar })
        Theme(knobs[i], "BackgroundColor3", "Knob")
        Corner(knobs[i], 3)
    end

    local function alpha(v) return (max == min) and 0 or (v - min) / (max - min) end
    local function update()
        local lo, hi = alpha(obj.Value[1]), alpha(obj.Value[2])
        fill.Position = UDim2.fromScale(lo, 0)
        fill.Size = UDim2.fromScale(hi - lo, 1)
        knobs[1].Position = UDim2.new(lo, 0, 0.5, 0)
        knobs[2].Position = UDim2.new(hi, 0, 0.5, 0)
        valueLabel.Text = obj.Value[1] .. suffix .. ", " .. obj.Value[2] .. suffix
    end
    update()

    function obj:Set(v, silent)
        local lo, hi = snap(v[1]), snap(v[2])
        if lo > hi then lo, hi = hi, lo end
        local changed = lo ~= self.Value[1] or hi ~= self.Value[2]
        self.Value = { lo, hi }
        update()
        if changed then self:_commit(silent) end
    end

    local activeKnob = 1
    BindDrag(track, function(pos, began)
        local a = math.clamp((pos.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        local val = min + (max - min) * a
        if began then
            local aLo, aHi = alpha(obj.Value[1]), alpha(obj.Value[2])
            if a < aLo then activeKnob = 1
            elseif a > aHi then activeKnob = 2
            else activeKnob = (math.abs(a - aLo) <= math.abs(a - aHi)) and 1 or 2 end
        end
        local cur = { obj.Value[1], obj.Value[2] }
        if activeKnob == 1 then cur[1] = math.min(val, cur[2]) else cur[2] = math.max(val, cur[1]) end
        obj:Set(cur)
    end)
    return obj
end

function Section:AddDropdown(cfg)
    local multi = cfg.Multi and true or false
    local values = cfg.Values or {}
    local function normalize(v)
        if multi then
            local n = {}
            if type(v) == "table" then
                for k, val in pairs(v) do
                    if type(k) == "number" then n[val] = true elseif val then n[k] = true end
                end
            end
            return n
        end
        return v
    end
    local obj = Element(cfg.Flag, normalize(multi and cfg.Default or (cfg.Default or values[1])), cfg.Callback)

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = self:_Order(), Parent = self.Body,
    })
    List(holder, 4)
    if cfg.Name then
        local _, nl = NameRow(holder, cfg.Name, cfg.Tooltip, UDim2.new(1, 0, 0, 14), 1)
        Theme(nl, "TextColor3", "SubText")
    end
    local box = New("TextButton", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 0, LayoutOrder = 2, Parent = holder })
    Theme(box, "BackgroundColor3", "Element")
    Corner(box, 4)
    local boxText = Lbl({
        Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(10, 0),
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = box,
    }, "Text")
    local arrow = Lbl({
        Size = UDim2.fromOffset(18, 26), Position = UDim2.new(1, -22, 0, 0), TextSize = 9, Text = "▼", Parent = box,
    }, "SubText")
    box.MouseEnter:Connect(function() Tween(box, 0.1, { BackgroundColor3 = T().Stroke }) end)
    box.MouseLeave:Connect(function() Tween(box, 0.1, { BackgroundColor3 = T().Element }) end)

    local list = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0,
        Visible = false, LayoutOrder = 3, ScrollBarThickness = 2, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = holder,
    })
    Theme(list, "BackgroundColor3", "Element")
    Theme(list, "ScrollBarImageColor3", "Accent")
    Corner(list, 4)
    List(list, 0)
    New("UISizeConstraint", { MaxSize = Vector2.new(math.huge, 138), Parent = list })

    local records = {}
    local function isSelected(v)
        if multi then return obj.Value[v] == true end
        return obj.Value == v
    end
    local function refresh()
        local text
        if multi then
            local t = {}
            for _, v in ipairs(values) do if obj.Value[v] then t[#t + 1] = tostring(v) end end
            text = #t > 0 and table.concat(t, ", ") or "None"
        else
            text = tostring(obj.Value or "None")
        end
        boxText.Text = text
        for _, r in ipairs(records) do
            local sel = isSelected(r.value)
            r.check.Visible = sel
            r.label.TextColor3 = sel and T().Text or T().SubText
            r.check.TextColor3 = T().Accent
        end
    end
    local function build()
        for _, r in ipairs(records) do r.item:Destroy() end
        records = {}
        for i, v in ipairs(values) do
            local item = New("TextButton", { Size = UDim2.new(1, 0, 0, 22), LayoutOrder = i, Parent = list })
            local check = New("TextLabel", {
                Size = UDim2.fromOffset(18, 22), Position = UDim2.fromOffset(8, 0),
                Text = "✓", Font = Enum.Font.GothamBold, Parent = item,
            })
            local label = New("TextLabel", {
                Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(28, 0),
                Text = tostring(v), TextXAlignment = Enum.TextXAlignment.Left, Parent = item,
            })
            item.MouseButton1Click:Connect(function()
                if multi then
                    local n = {}
                    for k, val in pairs(obj.Value) do n[k] = val end
                    n[v] = (not n[v]) or nil
                    obj:Set(n)
                else
                    obj:Set(v)
                    list.Visible = false
                    arrow.Text = "▼"
                end
            end)
            records[#records + 1] = { item = item, check = check, label = label, value = v }
        end
        refresh()
    end
    table.insert(Library.Hooks, refresh)
    build()

    function obj:Set(v, silent)
        self.Value = normalize(v)
        refresh()
        self:_commit(silent)
    end
    function obj:SetValues(newValues)
        values = newValues
        build()
    end
    box.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        arrow.Text = list.Visible and "▲" or "▼"
    end)
    return obj
end

function Section:AddButton(cfg)
    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 0,
        LayoutOrder = self:_Order(), Parent = self.Body,
    })
    Theme(btn, "BackgroundColor3", "Element")
    Theme(btn, "TextColor3", "Text")
    Localize(btn, cfg.Name or "Button")
    Corner(btn, 4)
    btn.MouseEnter:Connect(function() Tween(btn, 0.12, { BackgroundColor3 = T().Stroke }) end)
    btn.MouseLeave:Connect(function() Tween(btn, 0.12, { BackgroundColor3 = T().Element }) end)
    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = T().Accent
        Tween(btn, 0.3, { BackgroundColor3 = T().Element })
        if cfg.Callback then task.spawn(cfg.Callback) end
    end)
    return { Button = btn }
end

function Section:AddLabel(text)
    local l = Lbl({
        Size = UDim2.new(1, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.Y,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
        LayoutOrder = self:_Order(), Parent = self.Body,
    }, "SubText", text)
    local obj = { Label = l }
    function obj:SetText(t) Localize(l, t) end
    return obj
end

function Section:AddDivider()
    local d = New("Frame", { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = self:_Order(), Parent = self.Body })
    Theme(d, "BackgroundColor3", "Stroke")
end

function Section:AddTextbox(cfg)
    local obj = Element(cfg.Flag, cfg.Default or "", cfg.Callback)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = self:_Order(), Parent = self.Body,
    })
    List(holder, 4)
    if cfg.Name then
        local _, nl = NameRow(holder, cfg.Name, cfg.Tooltip, UDim2.new(1, 0, 0, 14), 1)
        Theme(nl, "TextColor3", "SubText")
    end
    local box = New("TextBox", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 0,
        Text = obj.Value, PlaceholderText = cfg.Placeholder or "",
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2, Parent = holder,
    })
    Theme(box, "BackgroundColor3", "Element")
    Theme(box, "TextColor3", "Text")
    Theme(box, "PlaceholderColor3", "SubText")
    Corner(box, 4)
    Pad(box, 10, 0, 10, 0)
    local st = Stroke(box, "Element")
    box.Focused:Connect(function() st.Color = T().Accent end)

    function obj:Set(v, silent)
        self.Value = v
        box.Text = tostring(v)
        self:_commit(silent)
    end
    box.FocusLost:Connect(function()
        st.Color = T().Element
        local t = box.Text
        if cfg.Numeric then t = tonumber(t) or obj.Value end
        obj.Value = t
        box.Text = tostring(t)
        obj:_commit()
    end)
    return obj
end

function Section:AddColorPicker(cfg)
    local obj = Element(cfg.Flag, cfg.Default or Color3.fromRGB(255, 255, 255), cfg.Callback)
    local h, s, v = obj.Value:ToHSV()

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, LayoutOrder = self:_Order(), Parent = self.Body,
    })
    List(holder, 4)
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 1, Parent = holder })
    NameRow(row, cfg.Name, cfg.Tooltip, UDim2.new(1, -50, 1, 0))
    local swatch = New("TextButton", {
        Size = UDim2.fromOffset(34, 16), AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), BackgroundTransparency = 0, Parent = row,
    })
    Corner(swatch, 4)

    local panel = New("Frame", { Size = UDim2.new(1, 0, 0, 96), BackgroundTransparency = 1, Visible = false, LayoutOrder = 2, Parent = holder })
    local sv = New("Frame", { Size = UDim2.new(1, -22, 1, 0), BackgroundTransparency = 0, Parent = panel })
    Corner(sv, 4)
    local white = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, Parent = sv })
    Corner(white, 4)
    New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
    local black = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv })
    Corner(black, 4)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
    local cursor = New("Frame", {
        Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = WHITE, ZIndex = 3, Parent = sv,
    })
    Corner(cursor, 4)
    New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = cursor })
    local svHit = New("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = sv })

    local hue = New("Frame", {
        Size = UDim2.new(0, 14, 1, 0), Position = UDim2.new(1, -14, 0, 0),
        BackgroundColor3 = WHITE, Parent = panel,
    })
    Corner(hue, 4)
    New("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
        }),
        Parent = hue,
    })
    local hueCursor = New("Frame", {
        Size = UDim2.new(1, 4, 0, 2), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = WHITE, ZIndex = 3, Parent = hue,
    })
    New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = hueCursor })
    local hueHit = New("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = hue })

    local function update()
        obj.Value = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = obj.Value
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(0.5, h)
    end
    update()

    function obj:Set(color, silent)
        local nh, ns, nv = color:ToHSV()
        if ns > 0.01 then h = nh end
        s, v = ns, nv
        update()
        self.Value = color
        self:_commit(silent)
    end
    BindDrag(svHit, function(pos)
        s = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
        v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
        update()
        obj:_commit()
    end)
    BindDrag(hueHit, function(pos)
        h = math.clamp((pos.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 1)
        update()
        obj:_commit()
    end)
    swatch.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)
    return obj
end

function Section:AddKeybind(cfg)
    local obj = Element(cfg.Flag, cfg.Default, nil)
    local row = New("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = self:_Order(), Parent = self.Body })
    NameRow(row, cfg.Name, cfg.Tooltip, UDim2.new(1, -70, 1, 0))
    local holder = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1, Parent = row,
    })
    local l = List(holder, 0, true)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Right
    l.VerticalAlignment = Enum.VerticalAlignment.Center

    local bind = { NoList = true }
    bind.Fire = function() if cfg.Callback then task.spawn(cfg.Callback) end end
    bind.Chip = MakeKeyChip(holder, 1, cfg.Default, function(k)
        bind.Key = k
        obj.Value = k
        obj:_commit(true)
        if cfg.OnChanged then task.spawn(cfg.OnChanged, k) end
    end)
    bind.Key = bind.Chip.Key
    table.insert(Library.Binds, bind)

    function obj:Set(k)
        bind.Chip:Set(k)
    end
    return obj
end

--------------------------------------------------------------------------------
-- keybind list / watermark / notifications
--------------------------------------------------------------------------------
function Library:CreateKeybindList()
    if self.KeyList then return self.KeyList end
    local frame = New("Frame", {
        Name = "KeybindList", Size = UDim2.fromOffset(200, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 50, 0.5, -20), Parent = self.Gui,
    })
    Theme(frame, "BackgroundColor3", "Panel")
    Corner(frame, 6)
    Stroke(frame)
    List(frame, 0)
    local title = Lbl({
        Size = UDim2.new(1, 0, 0, 26), Text = "Keybinds", Font = Enum.Font.GothamBold,
        TextSize = 12, LayoutOrder = 1, Parent = frame,
    }, "Text")
    local underline = New("Frame", { Size = UDim2.new(1, 0, 0, 2), LayoutOrder = 2, Parent = frame })
    Theme(underline, "BackgroundColor3", "Accent")
    local spacer = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = frame })
    List(spacer, 0)
    Pad(spacer, 10, 4, 10, 6)
    MakeDraggable(title, frame)
    self.KeyList = { Frame = frame, Container = spacer, Rows = {} }
    Hook(function() Library:RefreshKeybindList() end)
    return self.KeyList
end

function Library:RefreshKeybindList()
    local kl = self.KeyList
    if not kl then return end
    for _, r in ipairs(kl.Rows) do r:Destroy() end
    kl.Rows = {}
    local th = T()
    for i, b in ipairs(self.Binds) do
        if b.Key and b.Name and not b.NoList then
            local on = b.Obj and b.Obj.Value
            local row = New("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = i, Parent = kl.Container })
            New("TextLabel", {
                Size = UDim2.new(0.5, 0, 1, 0), Text = Library:Tr(b.Name), TextColor3 = on and th.Text or th.SubText,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
            })
            New("TextLabel", {
                Size = UDim2.fromOffset(44, 18), Position = UDim2.new(1, -108, 0, 0),
                Text = "[" .. KeyText(b.Key) .. "]", TextColor3 = on and th.Accent or th.SubText,
                Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
            })
            New("TextLabel", {
                Size = UDim2.fromOffset(56, 18), Position = UDim2.new(1, -56, 0, 0),
                Text = on and (b.Mode == "Hold" and "Held" or "Toggled") or "Off",
                TextColor3 = on and th.Text or th.SubText,
                TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
            })
            kl.Rows[#kl.Rows + 1] = row
        end
    end
end

function Library:CreateWatermark(text)
    if self.Watermark then return self.Watermark end
    local holder = New("Frame", {
        Name = "Watermark", Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
        BackgroundTransparency = 1, Parent = self.Gui,
    })
    local layout = List(holder, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right

    local function pill(order, txt)
        local p = New("Frame", { Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = order, Parent = holder })
        Theme(p, "BackgroundColor3", "Panel")
        Corner(p, 8)
        Stroke(p)
        local l = Lbl({ Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, Text = txt, Parent = p }, "Text")
        Pad(l, 10, 0, 10, 0)
        return l
    end
    pill(1, "◆  " .. (text or "Arcane"))
    local fpsLabel = pill(2, "0 FPS")
    local pingLabel = pill(3, "0 ping")

    local acc, frames = 0, 0
    Connect(RunService.RenderStepped, function(dt)
        acc = acc + dt
        frames = frames + 1
        if acc >= 0.5 then
            fpsLabel.Text = math.floor(frames / acc + 0.5) .. " FPS"
            local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
            pingLabel.Text = (ok and math.floor(ping) or 0) .. " ping"
            acc, frames = 0, 0
        end
    end)
    self.Watermark = holder
    return holder
end

-- kind: "info" (default) | "success" | "error"
function Library:Notify(text, duration, kind)
    duration = duration or 4
    if not self.NotifyHolder then
        local h = New("Frame", {
            Size = UDim2.new(0, 260, 1, -32), AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, -16), BackgroundTransparency = 1, Parent = self.Gui,
        })
        local l = List(h, 6)
        l.VerticalAlignment = Enum.VerticalAlignment.Bottom
        l.HorizontalAlignment = Enum.HorizontalAlignment.Right
        self.NotifyHolder = h
    end
    local card = New("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        GroupTransparency = 1, Parent = self.NotifyHolder,
    })
    Theme(card, "BackgroundColor3", "Panel")
    Corner(card, 6)
    Stroke(card)
    List(card, 0)
    local lbl = Lbl({
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(text), LayoutOrder = 1, Parent = card,
    }, "Text")
    Pad(lbl, 12, 9, 12, 9)
    local barHolder = New("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1, LayoutOrder = 2, Parent = card })
    local fill = New("Frame", { Size = UDim2.fromScale(1, 1), Parent = barHolder })
    if kind == "success" then fill.BackgroundColor3 = SUCCESS
    elseif kind == "error" then fill.BackgroundColor3 = DANGER
    else Theme(fill, "BackgroundColor3", "Accent") end

    Tween(card, 0.2, { GroupTransparency = 0 })
    Tween(fill, duration, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        if card.Parent then
            Tween(card, 0.25, { GroupTransparency = 1 })
            task.wait(0.3)
            if card.Parent then card:Destroy() end
        end
    end)
end

--------------------------------------------------------------------------------
-- library level api
--------------------------------------------------------------------------------
function Library:SetTheme(name)
    local th = self.Themes[name]
    if not th then return end
    self.Theme = name
    local alive = {}
    for _, e in ipairs(self.Registry) do
        if e.inst and e.inst.Parent then
            alive[#alive + 1] = e
            Tween(e.inst, 0.2, { [e.prop] = th[e.key] })
        end
    end
    self.Registry = alive
    for _, h in ipairs(self.Hooks) do pcall(h) end
end

function Library:SetAccent(color)
    for _, th in pairs(self.Themes) do th.Accent = color end
    self:SetTheme(self.Theme)
end

function Library:SetLanguage(lang)
    self.Language = lang
    for _, e in ipairs(self.Localized) do
        if e.inst.Parent then e.inst.Text = self:Tr(e.text) end
    end
    for _, h in ipairs(self.Hooks) do pcall(h) end
end

function Library:Toggle(state)
    for _, w in ipairs(self.Windows) do
        local show = state
        if show == nil then show = not w.Open end
        if show then
            w.Open = true
            w.Main.Visible = true
            w.Scale.Scale = 0.94
            Tween(w.Scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
        else
            w.Open = false
            Tween(w.Scale, 0.12, { Scale = 0.94 })
            task.delay(0.12, function()
                if not w.Open then w.Main.Visible = false end
            end)
        end
    end
end

function Library:ListConfigs()
    local out = {}
    if typeof(listfiles) == "function" then
        local ok, files = pcall(listfiles, "ArcaneConfigs")
        if ok then
            for _, f in ipairs(files) do
                local n = tostring(f):match("([^/\\]+)%.json$")
                if n then out[#out + 1] = n end
            end
        end
    end
    table.sort(out)
    return out
end

function Library:SaveConfig(name)
    if typeof(writefile) ~= "function" then
        self:Notify("Your executor has no writefile support.", 4, "error")
        return false
    end
    local data = {}
    for flag, obj in pairs(self.Options) do
        data[flag] = Serialize(obj.Value)
        if obj.Bind then
            if obj.Bind.Key then data[flag .. "__key"] = obj.Bind.Key.Name end
            data[flag .. "__mode"] = obj.Bind.Mode
        end
    end
    local folder = "ArcaneConfigs"
    if typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder(folder) then
        pcall(makefolder, folder)
    end
    local ok = pcall(writefile, folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    self:Notify(ok and ("Saved config '" .. name .. "'") or "Failed to save config", 3, ok and "success" or "error")
    return ok
end

function Library:LoadConfig(name)
    if typeof(readfile) ~= "function" then
        self:Notify("Your executor has no readfile support.", 4, "error")
        return false
    end
    local ok, raw = pcall(readfile, "ArcaneConfigs/" .. name .. ".json")
    if not ok then
        self:Notify("Config '" .. name .. "' not found", 3, "error")
        return false
    end
    local data = HttpService:JSONDecode(raw)
    for flag, value in pairs(data) do
        local obj = self.Options[flag]
        if obj and obj.Set then
            pcall(function() obj:Set(Deserialize(value)) end)
        end
        local base = flag:match("^(.*)__key$")
        if base and self.Options[base] and self.Options[base].Bind then
            pcall(function() self.Options[base].Bind.Chip:Set(Enum.KeyCode[value]) end)
        end
        local mbase = flag:match("^(.*)__mode$")
        if mbase and self.Options[mbase] and self.Options[mbase].Bind then
            self.Options[mbase].Bind.Mode = value
        end
    end
    self:RefreshKeybindList()
    self:Notify("Loaded config '" .. name .. "'", 3, "success")
    return true
end

function Library:Unload()
    self.Unloaded = true
    for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
    if self.Gui then self.Gui:Destroy() end
    if env then env.ArcaneLibrary = nil end
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local W = (cfg.Size and cfg.Size.X) or 500
    local H = (cfg.Size and cfg.Size.Y) or 500
    local Window = { AllTabs = {}, Open = true }

    local Main = New("Frame", {
        Name = "Main", Size = UDim2.fromOffset(W, H), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), ClipsDescendants = true, Parent = self.Gui,
    })
    Theme(Main, "BackgroundColor3", "Background")
    Corner(Main, 8)
    Stroke(Main)
    Window.Main = Main
    Window.Scale = New("UIScale", { Scale = 1, Parent = Main })

    -- title bar
    local Top = New("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = Main })
    local logoIcon = cfg.Logo
    if logoIcon then
        local holder = New("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(12, 8), BackgroundTransparency = 1, Parent = Top })
        local ic = MakeIcon(logoIcon, holder, 18, true)
        Hook(function() ic.SetColor(T().Accent) end)
    end
    Lbl({
        Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromOffset(logoIcon and 36 or 12, 0),
        Text = logoIcon and string.upper(cfg.Title or "ARCANE") or ("◆  " .. string.upper(cfg.Title or "ARCANE")),
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Top,
    }, "Accent")
    Lbl({
        Size = UDim2.new(0.5, -12, 1, 0), Position = UDim2.fromScale(0.5, 0),
        Text = cfg.Username or LocalPlayer.DisplayName, TextXAlignment = Enum.TextXAlignment.Right, Parent = Top,
    }, "SubText")
    MakeDraggable(Top, Main)

    local function divider(y)
        local d = New("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = y, Parent = Main })
        Theme(d, "BackgroundColor3", "Stroke")
    end
    divider(UDim2.fromOffset(0, 34))
    divider(UDim2.fromOffset(0, 81))
    divider(UDim2.new(0, 0, 1, -46))

    local TopStrip = New("Frame", { Size = UDim2.new(0.7, -8, 0, 36), Position = UDim2.fromOffset(8, 40), BackgroundTransparency = 1, Parent = Main })
    local l1 = List(TopStrip, 4, true)
    l1.VerticalAlignment = Enum.VerticalAlignment.Center
    local BottomStrip = New("Frame", { Size = UDim2.new(0.5, -8, 0, 36), Position = UDim2.new(0, 8, 1, -41), BackgroundTransparency = 1, Parent = Main })
    local l2 = List(BottomStrip, 4, true)
    l2.VerticalAlignment = Enum.VerticalAlignment.Center

    local Pages = New("Frame", { Size = UDim2.new(1, 0, 1, -128), Position = UDim2.fromOffset(0, 82), BackgroundTransparency = 1, ClipsDescendants = true, Parent = Main })

    -- theme switch (top right)
    local themeBox = New("Frame", { Size = UDim2.fromOffset(68, 34), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 41), Parent = Main })
    Theme(themeBox, "BackgroundColor3", "Panel")
    Corner(themeBox, 6)
    Pad(themeBox, 2, 2, 2, 2)
    List(themeBox, 0, true)
    local themeButtons = {}
    for i, def in ipairs({ { "Dark", "moon" }, { "Light", "sun" } }) do
        local b = New("TextButton", { Size = UDim2.fromOffset(32, 30), LayoutOrder = i, Parent = themeBox })
        Corner(b, 5)
        local ic = MakeIcon(def[2], b, 15, true)
        b.MouseButton1Click:Connect(function() Library:SetTheme(def[1]) end)
        themeButtons[def[1]] = { button = b, icon = ic }
    end
    Hook(function()
        for name, t in pairs(themeButtons) do
            local on = Library.Theme == name
            t.button.BackgroundTransparency = on and 0 or 1
            t.button.BackgroundColor3 = T().Element
            t.icon.SetColor(on and T().Accent or T().SubText)
            t.icon.SetCut(on and T().Element or T().Panel)
        end
    end)

    -- bottom right: settings + language
    local settingsBtn = New("TextButton", {
        Size = UDim2.fromOffset(34, 34), AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -92, 1, -6), Parent = Main,
    })
    Corner(settingsBtn, 6)
    local settingsIcon = MakeIcon("gear", settingsBtn, 17, true)
    local langBox = New("Frame", { Size = UDim2.fromOffset(78, 34), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -6), Parent = Main })
    Theme(langBox, "BackgroundColor3", "Panel")
    Corner(langBox, 6)
    Pad(langBox, 2, 2, 2, 2)
    List(langBox, 0, true)
    local langButtons = {}
    for i, code in ipairs({ "ENG", "RUS" }) do
        local b = New("TextButton", { Size = UDim2.fromOffset(37, 30), Text = code, Font = Enum.Font.GothamBold, LayoutOrder = i, Parent = langBox })
        Corner(b, 5)
        b.MouseButton1Click:Connect(function() Library:SetLanguage(code) end)
        langButtons[code] = b
    end
    Hook(function()
        for code, b in pairs(langButtons) do
            local on = Library.Language == code
            b.BackgroundTransparency = on and 0 or 1
            b.BackgroundColor3 = T().Element
            b.TextColor3 = on and T().Accent or T().SubText
        end
    end)

    -- tabs
    local function NewTab(tcfg, strip)
        local Tab = { Active = false, Window = Window }
        local page = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = Pages })

        local function column(x, ox)
            local c = New("ScrollingFrame", {
                Size = UDim2.new(0.5, -12, 1, -8), Position = UDim2.new(x, ox, 0, 4),
                BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
                BorderSizePixel = 0, Parent = page,
            })
            Theme(c, "ScrollBarImageColor3", "Accent")
            List(c, 8)
            Pad(c, 0, 0, 3, 4)
            return c
        end
        Tab.Left = column(0, 8)
        Tab.Right = column(0.5, 4)
        Tab._n = 0

        local apply
        if strip then
            local btn = New("TextButton", { Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X, Parent = strip })
            Corner(btn, 6)
            Pad(btn, 12, 0, 12, 0)
            local bl = List(btn, 7, true)
            bl.VerticalAlignment = Enum.VerticalAlignment.Center
            local icon
            if tcfg.Icon then
                local ih = New("Frame", { Size = UDim2.fromOffset(15, 15), BackgroundTransparency = 1, LayoutOrder = 1, Parent = btn })
                icon = MakeIcon(tcfg.Icon, ih, 15, true)
            end
            local name = New("TextLabel", {
                Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
                LayoutOrder = 2, Font = Enum.Font.GothamBold, TextSize = 12, Parent = btn,
            })
            Localize(name, tcfg.Name)
            local hovered = false
            apply = function()
                local th = T()
                btn.BackgroundColor3 = th.Element
                btn.BackgroundTransparency = Tab.Active and 0 or (hovered and 0.55 or 1)
                if icon then icon.SetColor(Tab.Active and th.Accent or th.SubText) end
                name.TextColor3 = Tab.Active and th.Text or th.SubText
            end
            Hook(apply)
            btn.MouseEnter:Connect(function() hovered = true apply() end)
            btn.MouseLeave:Connect(function() hovered = false apply() end)
            btn.MouseButton1Click:Connect(function() Tab:Select() end)
        end

        function Tab:_SetActive(b)
            self.Active = b
            page.Visible = b
            if apply then apply() end
        end
        function Tab:Select()
            for _, t in ipairs(Window.AllTabs) do t:_SetActive(false) end
            self:_SetActive(true)
            Window.Current = self
            if Window.RefreshGear then Window.RefreshGear() end
        end

        function Tab:AddSection(scfg)
            if type(scfg) == "string" then scfg = { Name = scfg } end
            local col = (scfg.Side == "Right") and self.Right or self.Left
            self._n = self._n + 1
            local sec = setmetatable({ Tab = self, _n = 0 }, Section)

            local frame = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = self._n, Parent = col,
            })
            Theme(frame, "BackgroundColor3", "Panel")
            Corner(frame, 6)
            List(frame, 4)
            Pad(frame, 8, 7, 8, 8)

            local header = New("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 0, Parent = frame })
            Lbl({
                Size = UDim2.new(1, -90, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.GothamBold, TextSize = 12, Parent = header,
            }, "Text", scfg.Name)
            local right = New("Frame", {
                Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1, Parent = header,
            })
            local rl = List(right, 8, true)
            rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
            rl.VerticalAlignment = Enum.VerticalAlignment.Center

            local body = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, LayoutOrder = 1, Parent = frame,
            })
            List(body, 6)
            sec.Body = body
            sec.Frame = frame

            local function headerIcon(iconName, order, size, onClick)
                local b = New("TextButton", { Size = UDim2.fromOffset(18, 18), LayoutOrder = order, Parent = right })
                local ic = MakeIcon(iconName, b, size, true)
                local hover = false
                local function paint() ic.SetColor(hover and T().Text or T().SubText) end
                Hook(paint)
                b.MouseEnter:Connect(function() hover = true paint() end)
                b.MouseLeave:Connect(function() hover = false paint() end)
                b.MouseButton1Click:Connect(onClick)
                return b
            end

            if scfg.Collapsible ~= false and (scfg.Collapsible or scfg.Toggle) then
                headerIcon("dots", 1, 16, function() body.Visible = not body.Visible end)
            end
            if scfg.OnSettings then
                headerIcon("gear", 2, 14, function() task.spawn(scfg.OnSettings) end)
            end
            if scfg.Toggle then
                local tcfg2 = type(scfg.Toggle) == "table" and scfg.Toggle or {}
                sec.Toggle = CreateSwitch(tcfg2, right, scfg.Name)
            end
            return sec
        end

        table.insert(Window.AllTabs, Tab)
        return Tab
    end

    function Window:AddTab(tcfg)
        if type(tcfg) == "string" then tcfg = { Name = tcfg } end
        local tab = NewTab(tcfg, (tcfg.Position == "Bottom") and BottomStrip or TopStrip)
        if not Window.Current then tab:Select() end
        return tab
    end

    -- built-in settings page
    local SettingsTab = NewTab({ Name = "Settings" }, nil)
    Window.SettingsTab = SettingsTab
    settingsBtn.MouseButton1Click:Connect(function() SettingsTab:Select() end)
    local function paintGear()
        local on = Window.Current == SettingsTab
        settingsBtn.BackgroundTransparency = on and 0 or 1
        settingsBtn.BackgroundColor3 = T().Element
        settingsIcon.SetColor(on and T().Accent or T().SubText)
    end
    Window.RefreshGear = paintGear
    Hook(paintGear)

    local ui = SettingsTab:AddSection({ Name = "Interface", Side = "Left" })
    ui:AddToggle({ Name = "Keybind list", Default = cfg.KeybindList ~= false, Callback = function(v)
        if Library.KeyList then Library.KeyList.Frame.Visible = v end
    end })
    ui:AddToggle({ Name = "Watermark", Default = cfg.Watermark ~= false, Callback = function(v)
        if Library.Watermark then Library.Watermark.Visible = v end
    end })
    ui:AddKeybind({ Name = "Menu key", Default = Library.MenuKey, Tooltip = "Shows / hides the menu.", OnChanged = function(k) Library.MenuKey = k end })
    ui:AddColorPicker({ Name = "Accent color", Default = T().Accent, Callback = function(c) Library:SetAccent(c) end })

    local cfgSec = SettingsTab:AddSection({ Name = "Config", Side = "Right" })
    local nameBox = cfgSec:AddTextbox({ Name = "Config name", Default = "default", Placeholder = "name" })
    local saved = cfgSec:AddDropdown({
        Name = "Saved configs", Values = Library:ListConfigs(),
        Tooltip = "Pick an existing config to load or overwrite.",
        Callback = function(v) if v then nameBox:Set(v) end end,
    })
    cfgSec:AddButton({ Name = "Save config", Callback = function()
        Library:SaveConfig(nameBox.Value ~= "" and nameBox.Value or "default")
        saved:SetValues(Library:ListConfigs())
    end })
    cfgSec:AddButton({ Name = "Load config", Callback = function() Library:LoadConfig(nameBox.Value ~= "" and nameBox.Value or "default") end })
    cfgSec:AddButton({ Name = "Refresh list", Callback = function() saved:SetValues(Library:ListConfigs()) end })
    cfgSec:AddButton({ Name = "Unload", Callback = function() Library:Unload() end })

    table.insert(self.Windows, Window)
    if cfg.KeybindList ~= false then self:CreateKeybindList() end
    if cfg.Watermark ~= false then self:CreateWatermark(cfg.WatermarkText or cfg.Title or "Arcane") end
    if cfg.MenuKey then self.MenuKey = cfg.MenuKey end

    Library:RefreshKeybindList()
    return Window
end

if env then env.ArcaneLibrary = Library end
return Library
