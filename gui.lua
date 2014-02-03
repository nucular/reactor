-- We have to use this one until RGUI works flawlessly :/
-- What a pity...

local gui = {}

gui.mainTab = {}
gui.reactionsTab = {}
gui.graphicsTab = {}
gui.exportTab = {}
gui.tabs = {gui.mainTab, gui.reactionsTab, gui.graphicsTab, gui.exportTab}

gui.currentTab = 1
gui.mousePos = {}

function gui.promptSelection(default, list, callback)
    -- Display a window with a grid of buttons you can select
    local width = math.floor(math.sqrt(#list))
    local wwidth = 0
    local wheight = 0
    local wx, wy = 0,0
    local matrix = {}

    local i = 1
    while i <= #list do
        local w = 0

        for x = 0, width do
            local tw, th = gfx.textSize(list[i])

            tw = tw + 5

            if list[i] == default then
                wx = math.floor(gui.mousePos[1] - (w + (tw / 2)))
                wy = math.floor(gui.mousePos[2] - (wheight + 7))
            end

            local cell = {w, wheight,
                tw, 15,
                list[i]}
            table.insert(matrix, cell)

            w = (w + tw) - 1

            i = i + 1

            if i > #list then
                break
            end
        end
        wwidth = math.max(wwidth, w)
        wheight = wheight + 14
    end

    -- Avoid crash :/
    local wx = math.max(wx, 1)
    local wy = math.max(wy, 1)

    local w = Window:new(wx,wy, wwidth + 1,wheight + 1)

    for i,cell in ipairs(matrix) do
        local b = Button:new(unpack(cell))
        b:action(function()
                ui.closeWindow(w)
                callback(cell[5])
            end)
        w:addComponent(b)
    end
    ui.showWindow(w)
end

function gui.buildMain()
    b = Button:new(3,20, 50,15, "Copy...", "Copy properties from another element")
    b:action(function()
        local l = {}
        for k,v in pairs(tpt.el) do
            table.insert(l, v.name)
        end
        table.sort(l)
        table.insert(l, " ")
        table.insert(l, "Cancel")

        gui.promptSelection("", l, function(r)
            if r ~= "Cancel" and r ~= " " and
                r ~= "LOLZ" and r ~= "LOVE" then -- avoid another crash
                reactor.elem:loadFrom(tpt.el[r:lower()].id)
                gui.update()
            end
        end)
    end)
    table.insert(gui.mainTab, b)

    table.insert(gui.mainTab, Label:new(52,20, 150,15, "Load properties from element"))
end

function gui.update()
    --
end

function gui.initialize()
    -- The main window
    gui.window = Window:new(100,100, 300,200)
    gui.window:onMouseMove(
        function(x, y, dx, dy)
            gui.mousePos = {x, y}
        end
    )

    -- Add the notebook-like buttons
    gui.tabButton1 = Button:new(0,0, 50,14, "Main")
    gui.tabButton1:action(function()
        gui.changeTab(1)
    end)
    gui.window:addComponent(gui.tabButton1)

    gui.tabButton2 = Button:new(49,0, 50,14, "Reactions")
    gui.tabButton2:action(function()
        gui.changeTab(2)
    end)
    gui.window:addComponent(gui.tabButton2)

    gui.tabButton3 = Button:new(98,0, 50,14, "Graphics")
    gui.tabButton3:action(function()
        gui.changeTab(3)
    end)
    gui.window:addComponent(gui.tabButton3)

    gui.tabButton4 = Button:new(147,0, 50,14, "Export")
    gui.tabButton4:action(function()
        gui.changeTab(4)
    end)
    gui.window:addComponent(gui.tabButton4)

    -- Hide/Quit button
    local quit = Button:new(286,0, 14,14, "_", "Hide Reactor")
    quit:action(function()
        gui.hide()
    end)
    gui.window:addComponent(quit)

    -- The maximizing button
    local but = Button:new(gfx.WIDTH - 16,97, 15,15, "R")
    but:action(function()
        gui.show()
    end)
    ui.addComponent(but)

    local caption = Label:new(240,1, 0,14, "Reactor 0.1")
    gui.window:addComponent(caption)

    -- Build all the tabs
    gui.buildMain()

    gui.changeTab(1)
end

function gui.show()
    ui.showWindow(gui.window)
    gui.update()
end

function gui.hide()
    ui.closeWindow(gui.window)
    reactor.update()
end

function gui.changeTab(i)
    for i,v in ipairs(gui.tabs[gui.currentTab]) do
        v:visible(false)
    end

    gui.currentTab = i

    gui.tabButton1:enabled(true)
    gui.tabButton2:enabled(true)
    gui.tabButton3:enabled(true)
    gui.tabButton4:enabled(true)
    gui[string.format("tabButton%s", i)]:enabled(false)

    for i,v in ipairs(gui.tabs[i]) do
        v:visible(true)
    end
end

return gui