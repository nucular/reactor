--[[Reactor Graphical User Interface]]--
--by nucular

--[[

Features
========
- Easy widget creation using object-oriented Widget classes
- JavaScript-like realtime interval and timeout functions and event callbacks

A few notes
===========

The draw function is called every frame and thus depends on the frame rate the
game is running on. If you want to have something running real-time, you can
use rgui.setTimeout and rgui.setInterval to schedule functions to be called
after or every x milliseconds, respectively.

TODO
====
- Better rgui.drawText function that doesn't ignore newlines

################################################################################
  THIS LIBRARY IS CURRENTLY IN ALHPA STAGE AND IT IS NOT ADVISED TO USE IT!
  THE WORKING ELEMENTS ARE USED INSIDE THE REACTOR ELEMENT GENERATOR BUT ALL
  OTHER WIDGETS ARE PROBABLY BUGGY OR UNUSABLE!
################################################################################

]]--

require "reactor/rgui/class"
require "reactor/rgui/stablesort"
require "socket" -- thanks for copying that one in

-- Some nice constants
EVENT_KEYDOWN = 1
EVENT_KEYUP = 2
EVENT_MOUSEDOWN = 1
EVENT_MOUSEUP = 2
EVENT_MOUSEHOLD = 3

KEY_RETURN = 13
KEY_SPACE = 32
KEY_ESCAPE = 27

RET_BLOCK = 1
RET_ALLOW = 2

rgui = {}
rgui.timeouts = {}
rgui.intervals = {}

local start_time = socket.gettime() * 1000


-- The main functions and some function shortcuts


function rgui.start()
    rgui.global = rgui.Global()

    tpt.register_step(rgui.step)
    tpt.register_mouseclick(rgui.onmouse)
    tpt.register_keypress(rgui.onkey)
end

function rgui.quit()
    tpt.unregister_step(rgui.step)
    tpt.unregister_mouseclick(rgui.onmouse)
    tpt.unregister_keypress(rgui.onkey)
end

function rgui.step()
    -- if the mouse was moved
    if rgui.global.active == true and
        (rgui.mousex ~= tpt.mousex or rgui.mousey ~= tpt.mousey) then
        rgui.mousex = tpt.mousex
        rgui.mousey = tpt.mousey
        rgui.global:onhover(rgui.mousex, rgui.mousey)
    end

    -- draw everything
    if rgui.global.active then
        rgui.global:draw(0, 0)
    end

    -- calculate frame rate and delta
    local now = socket.gettime() * 1000
    local delta = (now - start_time) + 0.2
    start_time = now

    -- and process intervals and timeouts
    for i, v in ipairs(rgui.timeouts) do
        v.time = v.time - delta
        if v.time <= 0 then
            v.func(v.args)
            table.remove(rgui.timeouts, i)
        end
    end

    for i, v in ipairs(rgui.intervals) do
        v.time = v.time - delta
        if v.time <= 0 then
            v.func(v.args)
            v.time = v.start
        end
    end
end

function rgui.onmouse(...)
    return rgui.global:onmouse(...)
end

function rgui.onkey(...)
    return rgui.global:onkey(...)
end

function rgui.add(child)
    rgui.global:add(child)
end

function rgui.remove(child, n)
    rgui.global:remove(child, n)
end

function rgui.setTimeout(func, time, ...)
    d = {}
    d.func = func
    d.time = time
    d.args = ...
    table.insert(rgui.timeouts, d)
    return #rgui.timeouts
end

function rgui.setInterval(func, time, ...)
    d = {}
    d.func = func
    d.time = time
    d.start = time
    d.args = ...
    table.insert(rgui.intervals, d)
    return #rgui.intervals
end

function rgui.clearTimeout(id, n)
    if type(id) == "number" then
        if id > 0 and id <= #rgui.timeouts then
            table.remove(rgui.timeouts, id)
            return true
        else
            return false
        end
    else
        local ret = 0
        local n = n or 1

        for i, v in ipairs(rgui.timeouts) do
            if v == id then
                table.remove(rgui.timeouts, i)
                ret = ret + 1
                if ret >= n then
                    return ret
                end
            end
        end
        return 0
    end
end

function rgui.clearInterval(id)
    if type(id) == "number" then
        if id > 0 and id <= #rgui.intervals then
            table.remove(rgui.intervals, id)
            return true
        else
            return false
        end
    else
        local ret = 0
        local n = n or 1

        for i, v in ipairs(rgui.intervals) do
            if v == id then
                table.remove(rgui.intervals, i)
                ret = ret + 1
                if ret >= n then
                    return ret
                end
            end
        end
        return 0
    end
end


-- Easing effects


function rgui.ease(func, easing, begin, change, duration)
    local id = #rgui.intervals + 1

    -- A little hack
    rgui.setInterval(
        function(obj, id)
            func(easing(obj.time_, begin, change, duration))
            obj.time_ = obj.time_ + 10
            if obj.time_ >= duration then
                rgui.clearInterval(id)
            end
        end
    , 10)
    local obj = rgui.intervals[id]
    obj.time_ = 0
    obj.args = {obj, id}
end

function rgui.linearEasing(t, b, c, d)
    return c * t / d + b
end

function rgui.outBounce(t, b, c, d)
  t = t / d
  if t < 1 / 2.75 then
    return c * (7.5625 * t * t) + b
  elseif t < 2 / 2.75 then
    t = t - (1.5 / 2.75)
    return c * (7.5625 * t * t + 0.75) + b
  elseif t < 2.5 / 2.75 then
    t = t - (2.25 / 2.75)
    return c * (7.5625 * t * t + 0.9375) + b
  else
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
  end
end


-- Utility functions


function rgui.wrapText(str, width, lines)
    local text = ""
    local buffer = ""
    local l = 1

    for word in str:gmatch("%w+") do
        local nex = buffer .. word

        if gfx.textSize(nex) >= width then
            text = text .. buffer .. "\n"
            buffer = word .. " "
            l = l + 1
            if l >= lines then
                break
            end
        else
            buffer = nex .. " "
        end
    end

    if not text == "" then
        text = text .. "\n" .. buffer
    else
        text = text .. buffer
    end

    return text, gfx.textSize(text) - 5, l * 11
end


-- A set of constrainted drawing functions
-- Shouldn't be too slow hopefully :/


function rgui.drawRect(parent, x, y, width, height, r, g, b, a)
    local up, right, down, left = true, true, true, true

    if x < parent.consts[1] + 1 then
        width = width - (parent.consts[1] - x) - 1
        x = parent.consts[1] + 1
        left = false
    end
    if x + width > parent.consts[3] - 1 then
        width = width - ((x + width) - parent.consts[3])
        right = false
    end

    if y < parent.consts[2] + 1 then
        height = height - (parent.consts[2] - y) - 1
        y = parent.consts[2] + 1
        up = false
        down = false
    end
    if y + height > parent.consts[4] - 1 then
        height = height - ((y + height) - parent.consts[4])
        down = false
    end

    if up then
        gfx.drawRect(x, y, width + 1, 1, r, g, b, a)
    end
    if left and height > 1 then
        gfx.drawRect(x, y, 1, height + 1, r, g, b, a)
    end
    if down then
        gfx.drawRect(x, y + height, width + 1, 1, r, g, b, a)
    end
    if right then
        gfx.drawRect(x + width, y, 1, height + 1, r, g, b, a)
    end
end

function rgui.fillRect(parent, x, y, width, height, r, g, b, a)
    if x < parent.consts[1] + 1 then
        width = width - (parent.consts[1] - x)
        x = parent.consts[1] + 1
    elseif x + width > parent.consts[3] - 1 then
        width = width - ((x + width) - parent.consts[3])
    end

    if y < parent.consts[2] + 1 then
        height = height - (parent.consts[2] - y)
        y = parent.consts[2] + 1
    elseif y + height > parent.consts[4] - 1 then
        height = height - ((y + height) - parent.consts[4])
    end

    gfx.fillRect(x, y, width + 1, height + 1, r, g, b, a)
end

function rgui.drawText(parent, x, y, text, r, g, b, a)
    if y < parent.consts[2] or y + 10 > parent.consts[4] then
        return
    end

    while text ~= "" and x < parent.consts[1] + 1 do
        local c = text:sub(1, 1)
        text = text:sub(2)
        x = x + gfx.textSize(c)
    end

    while text ~= "" and gfx.textSize(text) + x > parent.consts[3] do
        text = text:sub(1, #text - 1)
    end

    gfx.drawText(x, y, text, r, g, b, a)
end


-- A style class for colouring widgets


rgui.Style = class()
function rgui.Style:__init(fill_default, outline_default, text_default,
    fill_hover, outline_hover, text_hover,
    fill_focused, outline_focused, text_focused,
    fill_down, outline_down, text_down,
    invalid, ignore_hovered, ignore_focused, ignore_down)
    self.fill = fill or {0, 0, 0, 255}
    self.outline = outline or {200, 200, 200, 255}
    self.text = text or {255, 255, 255, 255}
    self.fill_hover = fill_hover or {20, 20, 20, 255}
    self.outline_hover = outline_hover or {255, 255, 255, 255}
    self.text_hover = text_hover or {255, 255, 255, 255}
    self.fill_focused = fill_focused or {10, 10, 10, 255}
    self.outline_focused = outline_focused or {255, 255, 255, 255}
    self.text_focused = text_focused or {255, 255, 255, 255}
    self.fill_down = fill_down or {255, 255, 255, 255}
    self.outline_down = outline_down or {200, 200, 200, 0}
    self.text_down = text_down or {0, 0, 0, 255}
    self.invalid = invalid or {255, 0, 0, 255}
    self.ignore_hovered = ignore_hovered or false
    self.ignore_focused = ignore_focused or false
    self.ignore_down = ignore_down or false
    -- For fading
    self.visibility = 1
end

function rgui.Style:get(widget, name)
    local ret
    if name == "fill" then
        if widget.down and not self.ignore_down then
            ret = self.fill_down
        elseif widget.hovered and not self.ignore_hovered then
            ret = self.fill_hover
        elseif widget.focused and not self.ignore_focused then
            ret = self.fill_focused
        else
            ret = self.fill
        end
    elseif name == "outline" then
        if widget.down and not self.ignore_down then
            ret = self.outline_down
        elseif widget.hovered and not self.ignore_hovered then
            ret = self.outline_hover
        elseif widget.focused and not self.ignore_focused then
            ret = self.outline_focused
        else
            ret = self.outline
        end
    elseif name == "text" then
        if widget.down and not self.ignore_down then
            ret = self.text_down
        elseif widget.hovered and not self.ignore_hovered then
            ret = self.text_hover
        elseif widget.focused and not self.ignore_focused then
            ret = self.text_focused
        else
            ret = self.text
        end
    else
        ret = self.invalid
    end

    ret[4] = (ret[4] or 255) * self.visibility

    return unpack(ret)
end


-- The main Widget class


rgui.Widget = class()
function rgui.Widget:__init(x, y, w, h)
    self.x = x or 0
    self.y = y or 0
    self.w = w or 0
    self.h = h or 0
    self.focused = false
    self.hovered = false
    self.down = false
    self.pressed = {}

    self.active = true
    self.visible = true

    self.parent = rgui.global
    self.layer = 0

    self.dragged = false
    self.lastdrag = {}

    -- These are the constraints used for drawing childs of this element
    self.consts = {self.x, self.y, self.w, self.h}
end

function rgui.Widget:hit(x, y)
    return x >= self.x and y >= self.y and x < self.x + self.w and y < self.y + self.h
end

function rgui.Widget:show()
    if not self.visible then
        self.visible = true
    end
end

function rgui.Widget:hide()
    if self.visible then
        self.visible = false
    end
end

function rgui.Widget:setPos(x, y)
    self.x = x or self.x
    self.y = y or self.y
    self:updateConsts()
end

function rgui.Widget:setSize(w, h)
    self.w = w or self.w
    self.h = h or self.h
    self:updateConsts()
end

function rgui.Widget:setLayer(n)
    self.layer = n
    if self.parent then
        self.parent:sort()
    end
end

function rgui.Widget:updateConsts()
    if self.parent then
        self.consts = {
            self.x + self.parent.consts[1],
            self.y + self.parent.consts[2],
            math.min(self.x + self.w + self.parent.consts[1], self.parent.consts[3]) - 1,
            math.min(self.y + self.h + self.parent.consts[2], self.parent.consts[4]) - 1
        }
    end
    if self.childs then
        for i, v in ipairs(self.childs) do
            v:updateConsts()
        end
    end
end

function rgui.Widget:draw(offx, offy)
    -- Gets called every frame while the widget is visible
end

-- And here are all those cool callbacks

function rgui.Widget:onmouse(x, y, button, event)
    -- Gets called when a mouse event hits the widget
end

function rgui.Widget:onmousedown(x, y, button)
    -- Gets called when a mouse button gets pressed down on the widget
end

function rgui.Widget:onmouseup(x, y, button)
    -- Gets called when a mouse button gets released while on the widget
end

function rgui.Widget:onclick(x, y, button)
    -- Called when a button gets pressed and then released on the widget
end

function rgui.Widget:onkey(key, keynum, modifier, event)
    -- Gets called when a key press appears while the widget is focused
end

function rgui.Widget:onkeydown(key, keynum, modifier)
end

function rgui.Widget:onkeyup(key, keynum, modifier)
end

function rgui.Widget:onfocus(button)
    -- Called when a mousedown appears on the unfocused widget
end

function rgui.Widget:onblur(button)
    -- Called when a mousedown appears on another widget of the same parent
end

function rgui.Widget:onhover(mousex, mousey)
    -- Called when the mouse gets moved inside the widget
end

function rgui.Widget:onenter(mousex, mousey)
    -- Called when the mouse enters the widget
end

function rgui.Widget:onleave(mousex, mousey)
    -- Called when the mouse leaves the widget
end

function rgui.Widget:ondragstart(offx, offy)
    -- Called when the user starts to drag the element
end

function rgui.Widget:ondrag(dx, dy)
    -- Called while dragging
end

function rgui.Widget:ondragend()
    -- Called when the user releases the left mouse key after dragging
end

function rgui.Widget:onadded(parent)
    -- Called when the widget gets added to a parent frame
end

function rgui.Widget:onremoved(parent)
    -- Called when the widget gets removed from a parent Frame
end


-- The Frame class is similar important since that one handles the callbacks
-- and element moving and so on


rgui.Frame = class(rgui.Widget)
function rgui.Frame:__init(x, y, w, h, ...)
    rgui.Widget.__init(self, x, y, w, h)
    self.childs = ... or {}
    self.focusedChild = nil
end

function rgui.Frame:draw(offx, offy)
    local i = #self.childs
    while i > 0 do
        local v = self.childs[i]
        if v.visible == true then
            v:draw(self.x + offx, self.y + offy)
        end
        i = i - 1
    end
end

function rgui.Frame.comp(a, b)
    -- compare two frames (call this using the "frame.comp(a, b)" notation!)
    if a.focused and not b.focused then
        return true
    elseif b.focused and not a.focused then
        return false
    else
        return a.layer > b.layer
    end
end

function rgui.Frame:sort()
    -- sort the childs by layer and focused-attribute
    stable_sort(self.childs, self.comp)
end


function rgui.Frame:onmouse(x, y, button, event)
    local ret = true

    for i, v in ipairs(self.childs) do

        if event == EVENT_MOUSEUP and v.dragged then
            rgui.global.draggedChild = nil
            v.dragged = false
            v:ondragend()
        end

        if v.active and v:hit(x, y) then
            ret = false

            if event == EVENT_MOUSEDOWN and not v.focused then
                -- another child was focused
                if self.focusedChild then
                    self.focusedChild.focused = false
                    self.focusedChild:onblur(button)
                end
                v.focused = true
                v:onfocus(button)
                self:sort()
                self.focusedChild = v
            end

            v:onmouse(x - v.x, y - v.y, button, event)

            if event == EVENT_MOUSEDOWN then
                v:onmousedown(x - v.x, y - v.y, button)
                v.down = true
                v.pressed[button] = true
            elseif event == EVENT_MOUSEUP then
                v:onmouseup(x - v.x, y - v.y, button)
                v.down = false

                if v.pressed[button] then
                    v.pressed[button] = false
                    v:onclick(x - v.x, y - v.y, button)
                else
                    -- let mouseup pass through to avoid a bug
                    ret = true
                end
            end
            -- block other childs from being called
            return ret
        end
    end

    -- nothing was hit
    if self.focusedChild and event == 1 then
        self.focusedChild.focused = false
        self.focusedChild:onblur(button)
        self.focusedChild = nil
    end

    return ret
end

function rgui.Frame:onkey(key, keynum, modifier, event)
    local ret = RET_ALLOW
    if self.focusedChild and self.focusedChild.active == true then
        if event == EVENT_KEYUP then
            ret = self.focusedChild:onkeyup(key, keynum, modifier) or ret
        else
            ret = self.focusedChild:onkeydown(key, keynum, modifier) or ret
        end
        ret = self.focusedChild:onkey(key, keynum, modifier, event) or ret
    end
    return ret == RET_ALLOW
end

function rgui.Frame:onhover(mousex, mousey)
    for i, v in ipairs(self.childs) do

        if v.active == true and v:hit(mousex, mousey) then
            if v.hovered == false then
                v.hovered = true
                v:onenter(mousex, mousey)
            end

            v:onhover(mousex - v.x, mousey - v.y)

            if v.dragged == false and v.pressed[1] then
                rgui.global.draggedChild = v
                v:ondragstart(mousex - v.x, mousey - v.y)
                v.dragged = true
                v.lastdrag = {mousex, mousey}
            end

        elseif v.hovered == true then
            v.hovered = false
            v.pressed = {}
            v:onleave()
        elseif v.down == true then
            v.down = false
            v.pressed = {}
        end

        if v.active == true and v.dragged == true then
            local vx = mousex - v.lastdrag[1]
            local vy = mousey - v.lastdrag[2]

            v:ondrag(vx, vy)
            v.lastdrag = {mousex, mousey}
        end
    end
end

function rgui.Frame:onleave(mousex, mousey)
    -- Workaround for a little bug
    for i, v in ipairs(self.childs) do
        if v.hovered then
            v.hovered = false
            v:onleave(mousex, mousey)
        end
        if v.down then
            v.down = false
        end
        if v.dragged then
            v.dragged = false
            v:ondragend()
            rgui.global.draggedChild = nil
        end
        -- reset the pressed mouse keys
        v.pressed = {}
    end
end

function rgui.Frame:onblur(button)
    if self.focusedChild then
        self.focusedChild.focused = false
        self.focusedChild:onblur(button)
        self.focusedChild = nil
    end
    self:sort()
end

function rgui.Frame:add(...)
    for i, child in ipairs({...}) do
        if child.parent then
            child.parent:remove(child)
        end

        table.insert(self.childs, child)
        child.parent = self
        child:onadded(self)
    end

    self:sort()
    self:updateConsts()
end

function rgui.Frame:remove(child, n)
    num = 0

    for i, v in ipairs(self.childs) do
        if v == child then
            if not n or num < n then
                table.remove(self.childs, i)
                v.parent = nil
                v:onremoved(self)
                num = num + 1
            end
        end
    end
    self:sort()
    return num
end


-- The Global class is a large Frame that has to contain all other Widgets.


rgui.Global = class(rgui.Frame)
function rgui.Global:__init(...)
    rgui.Frame.__init(self, 0, 0, gfx.WIDTH, gfx.HEIGHT)
    self.focused = true
    self.modal = false

    self.consts = {0, 0, gfx.WIDTH, gfx.HEIGHT}
end

function rgui.Global:draw(offx, offy)
    rgui.Frame.draw(self, offx, offy)
    if self.modal then
        gfx.fillRect(0, 0, gfx.WIDTH, gfx.HEIGHT, 0, 0, 0, 150)
    end
end

function rgui.Global:hit(x, y)
    return true
end

function rgui.Global:onmouse(mousex, mousey, button, event)
    if event == 2 then
        self:onmouseup(mousex, mousey, button)
    end
    return rgui.Frame.onmouse(self, mousex, mousey, button, event)
end

function rgui.Global:onmouseup(mousex, mousey, button)
    if button == 1 and self.draggedChild then
        self.draggedChild.dragged = false
        self.draggedChild.ondragend()
        self.draggedChild = nil
    end
end

function rgui.Global:updateConsts()
    for i, v in ipairs(self.childs) do
        v:updateConsts()
    end
end


-- A simple text label


rgui.Label = class(rgui.Widget)
rgui.Label.style = rgui.Style(
    nil, nil, {255, 255, 255, 255},
    nil, nil, nil,
    nil, nil, nil,
    nil, nil, nil,
    {255, 0, 0, 255},
    true, true, true)
function rgui.Label:__init(text, x, y, style)
    rgui.Widget.__init(self, x, y, tpt.textwidth(text), 6)
    self.text = text or ""
    self.style = style or rgui.Label.style
end

function rgui.Label:draw(offx, offy)
    self.w = tpt.textwidth(self.text)
    rgui.drawText(self.parent, self.x + offx, self.y + offy, self.text,
        self.style:get(self, "text"))
end


-- A simple button


rgui.Button = class(rgui.Widget)
function rgui.Button:__init(text, x, y, style)
    local w, h = gfx.textSize(text)
    rgui.Widget.__init(self, x, y, w + 7, h + 3)
    self.text = text or ""
    self.style = style or rgui.Style()
end

function rgui.Button:draw(offx, offy)
    rgui.fillRect(self.parent, self.x + offx, self.y + offy, self.w, self.h,
        self.style:get(self, "fill"))
    rgui.drawRect(self.parent, self.x + offx, self.y + offy, self.w, self.h,
        self.style:get(self, "outline"))
    gfx.drawText(self.x + offx + 3, self.y + offy + 3, self.text,
        self.style:get(self, "text"))
end

function rgui.Button:onkeydown(key, keynum, modifier)
    if keynum == KEY_RETURN or keynum == KEY_SPACE then
        self.down = true
        return RET_BLOCK
    end
    return RET_ALLOW
end

function rgui.Button:onkeyup(key, keynum, modifier)
    if (keynum == KEY_RETURN or keynum == KEY_SPACE) and self.down then
        self.down = false
        self:onclick(0, 0)
    end
    return false
end


-- The TitleBar is there to contain things like the caption label and exit
-- buttons


rgui.TitleBar = class(rgui.Frame)
rgui.TitleBar.style = rgui.Style(
    {0, 0, 0, 200}, {255, 255, 255, 255}, {200, 200, 200, 255},
    nil, nil, nil,
    {20, 20, 20, 200}, {255, 255, 0, 255}, {255, 255, 255, 255},
    nil, nil, nil,
    {255, 0, 0, 255},
    true, false, true)
function rgui.TitleBar:__init(window, caption, x, y, w, h, style, ...)
    rgui.Frame.__init(self, x, y, w, h, ...)
    self.window = window
    self.caption = caption
    self.style = style or rgui.TitleBar.style
end

function rgui.TitleBar:ondrag(dx, dy)
    self:setPos(self.x + dx, self.y + dy)
    if self.window then
        self.window:setPos(self.window.x + dx, self.window.y + dy)
    end
end

function rgui.TitleBar:draw(offx, offy)
    rgui.fillRect(self.parent, self.x + offx, self.y + offy, self.w, self.h,
        self.style:get(self, "fill"))
    rgui.drawRect(self.parent, self.x + offx, self.y + offy, self.w, self.h,
        self.style:get(self, "outline"))
    if self.caption then
        rgui.drawText(self.parent, self.x + offx + 3, self.y + offy + 3,
            self.caption, self.style:get(self, "text"))
    end
    rgui.Frame.draw(self, offx, offy)
end

function rgui.TitleBar:onfocus()
    if self.window then
        self.window.focused = true
    end
end

function rgui.TitleBar:onblur()
    if self.window then
        self.window.focused = false
    end
end

function rgui.TitleBar:setLayer(n)
    rgui.Widget.setLayer(self, n)
    if self.window and self.window.layer ~= n then
        self.window:setLayer(n)
    end
end


-- The Window is basically just a frame that draws itself and holds an
-- TitleBar object


rgui.Window = class(rgui.Frame)
function rgui.Window:__init(caption, x, y, w, h, style, ...)
    rgui.Frame.__init(self, x, y + 14, w, h, ...)
    self.style = style or rgui.Style()
    self.bar = rgui.TitleBar(self, caption, x, y, w, 15, style)
end

function rgui.Window:draw(offx, offy)
    rgui.fillRect(self.parent, self.x + offx, self.y + offy, self.w, self.h,
        0, 0, 0, 200)
    if self.focused then
        rgui.drawRect(self.parent, self.x + offx, self.y + offy, self.w, self.h,
            255, 255, 0, 255)
    else
        rgui.drawRect(self.parent, self.x + offx, self.y + offy, self.w, self.h,
            255, 255, 255, 255)
    end
    rgui.Frame.draw(self, offx, offy)
end

function rgui.Window:onadded(parent)
    parent:add(self.bar)
end

function rgui.Window:onremoved(parent)
    parent:remove(self.bar)
end

function rgui.Window:onfocus()
    self.bar.focused = true
end

function rgui.Window:onblur()
    rgui.Frame.onblur(self)
    self.bar.focused = false
end

function rgui.Window:setLayer(n)
    rgui.Widget.setLayer(self, n)
    self.bar:setLayer(n)
end


-- A text input widget


rgui.TextBox = class(rgui.Widget)
function rgui.TextBox:__init(x, y, w, text, placeholder)
    rgui.Widget.__init(self, x, y, w, 14)
    self.text = text or ""
    self.placeholder = placeholder or ""
    self.cursorpos = 10
    self.cursorstate = false
end

function rgui.TextBox:onkey(key, keynum, modifier, event)
    if event == 2 then
        self.text = self.text .. key
    end
    return RET_BLOCK
end

function rgui.TextBox:draw(offx, offy)
    rgui.fillRect(self.parent, self.x + offx, self.y + offy, self.w, self.h,
        0, 0, 0, 255)

    rgui.drawRect(self.parent, self.x + offx, self.y + offy, self.w, self.h,
        255, 255, 255, 255)

    gfx.drawText(self.x + offx + 3, self.y + offy + 3,
        self.text, 255, 255, 255, 255)

    if self.cursorstate and self.focused then
        rgui.drawRect(self.parent, self.x + self.cursorpos + offx, self.y + offy,
            1, 14)
    end
end

function rgui.TextBox:flashCursor()
    self.cursorstate = not self.cursorstate
end

function rgui.TextBox:onadded(parent)
    self.cursorinterval = rgui.setInterval(self.flashCursor, 60, self)
end

function rgui.TextBox:onremoved(parent)
    rgui.clearInterval(self.cursorinterval)
end


rgui.TestRect = class(rgui.Widget)
function rgui.TestRect:__init()
    rgui.Widget.__init(self, math.random(200), math.random(200),
        math.random(50), math.random(50))
    self.color = {math.random(255), math.random(255), math.random(255)}
end

function rgui.TestRect:ondrag(dx, dy)
    self:setPos(self.x + dx, self.y + dy)
end

function rgui.TestRect:draw(offx, offy)
    rgui.drawRect(self.parent, self.x + offx, self.y + offy, self.w, self.h,
        unpack(self.color))
end

-- Start everything!
rgui.start()
