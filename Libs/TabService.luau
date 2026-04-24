--[[
]]

local function assertStr(v, name)
    assert(type(v) == "string" and #v > 0,
        "TabService: '" .. name .. "' must be a non-empty string.")
end

local function assertFn(v, name)
    assert(type(v) == "function",
        "TabService: '" .. name .. "' must be a function.")
end

local function assertNum(v, name)
    assert(type(v) == "number",
        "TabService: '" .. name .. "' must be a number.")
end

local Section = {}
Section.__index = Section

function Section._new(raw, subTabs)
    local self = setmetatable({}, Section)
    self._raw = raw
    if subTabs then
        self.page = raw.page
    end
    return self
end

function Section:text(content)
    assert(type(content) == "string", "TabService: Section:text() expects a string.")
    self._raw:Text(content)
end

function Section:spacing()
    self._raw:Spacing()
end

function Section:button(label, w, h, fn)
    assertStr(label, "label")
    if type(w) == "function" then
        fn = w
        self._raw:Button(label, fn)
    else
        assertFn(fn, "fn")
        self._raw:Button(label, w, h, fn)
    end
end

function Section:toggle(key, label, default)
    assertStr(key,   "key")
    assertStr(label, "label")
    local init = (default == true) and true or false
    self._raw:Toggle(key, label, init)
    local val = UI.GetValue(key)
    return (val == true or val == 1)
end

function Section:checkbox(key, label, default)
    assertStr(key,   "key")
    assertStr(label, "label")
    local init = (default == true) and true or false
    self._raw:Checkbox(key, label, init)
    local val = UI.GetValue(key)
    return (val == true or val == 1)
end

function Section:slider(key, label, min, max, default)
    assertStr(key,   "key")
    assertStr(label, "label")
    assertNum(min,   "min")
    assertNum(max,   "max")
    local init = (type(default) == "number") and default or min
    self._raw:Slider(key, label, min, max, init)
    return UI.GetValue(key) or init
end

function Section:inputText(key, placeholder, default)
    assertStr(key,         "key")
    assertStr(placeholder, "placeholder")
    self._raw:InputText(key, placeholder, default or "")
end

function Section:combo(key, label, options, idx)
    assertStr(key,   "key")
    assertStr(label, "label")
    assert(type(options) == "table", "TabService: combo options must be a table.")
    self._raw:Combo(key, label, options, idx or 0)
end

local Ctx = {}
Ctx.__index = Ctx

function Ctx._new(tab, rawTab)
    local self = setmetatable({}, Ctx)
    self._tab    = tab
    self._rawTab = rawTab
    return self
end

function Ctx:_ns(key)
    -- prefix key with tab name to avoid global collisions
    return self._tab._name .. "::" .. key
end

function Ctx:get(key)
    return UI.GetValue(self:_ns(key))
end

function Ctx:set(key, value)
    UI.SetValue(self:_ns(key), value)
end

function Ctx:leftSection(title, subTabs)
    assertStr(title, "title")
    local raw = self._rawTab:Section(title, "Left", subTabs)
    return Section._new(raw, subTabs)
end

function Ctx:rightSection(title, subTabs)
    assertStr(title, "title")
    local raw = self._rawTab:Section(title, "Right", subTabs)
    return Section._new(raw, subTabs)
end

local Tab = {}
Tab.__index = Tab

function Tab._new(name)
    assertStr(name, "tabName")
    local self = setmetatable({}, Tab)
    self._name    = name
    self._builder = nil
    self._mounted = false
    self._ready   = false
    return self
end

function Tab:setBuilder(fn)
    assertFn(fn, "fn")
    assert(not self._mounted,
        "TabService: setBuilder() must be called before mount().")
    self._builder = fn
end

function Tab:mount()
    assert(self._builder,
        "TabService: call setBuilder() before mount().")
    assert(not self._mounted,
        "TabService: tab '" .. self._name .. "' is already mounted.")

    self._mounted = true
    local self_ = self

    UI.AddTab(self._name, function(rawTab)
        local ctx = Ctx._new(self_, rawTab)

        if not self_._ready then
            local s = rawTab:Section("Please wait", "Left")
            s:Text("[ " .. self_._name .. " ] Loading...")
            return
        end

        local ok, err = pcall(self_._builder, ctx)
        if not ok then
            local errSec = rawTab:Section("TabService Error", "Left")
            errSec:Text("Builder crashed:")
            errSec:Spacing()
            errSec:Text(tostring(err))
            warn("[TabService] Builder error in '" .. self_._name .. "': " .. tostring(err))
        end
    end)
end

function Tab:ready()
    assert(self._mounted,
        "TabService: call mount() before ready().")
    self._ready = true
end

function Tab:unmount()
    if not self._mounted then return end
    pcall(UI.RemoveTab, self._name)
    self._mounted = false
    self._ready   = false
end

function Tab:notify(message, duration)
    assert(type(message) == "string", "TabService: notify message must be a string.")
    notify(message, self._name, duration or 5)
end

local TabService = {}

function TabService.new(tabName)
    return Tab._new(tabName)
end

return TabService
