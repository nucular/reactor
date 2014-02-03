-- class.lua
-- Based on http://lua-users.org/wiki/SimpleLuaClasses

function class(base, init)
    local c = {} -- a new class instance
    if not init and type(base) == "function" then
        init = base
        base = nil
    elseif type(base) == "table" then
        -- the new class is a shallow copy of the new class!
        for i, v in pairs(base) do
            c[i] = v
        end
        c.__base = base
    end
    -- the class will be the metatable for all of its objects,
    -- and they will look up their methods in it
    c.__index = c

    -- expose a constructor which can be called by <classname>(<args>)
    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj, c)
        if class_tbl.__init then
            class_tbl.__init(obj, ...)
        else
            -- make sure that any stuff from the base class is initialized!
            if base and base.__init then
                base.__init(obj, ...)
            end
        end
        return obj
    end

    c.__init = init

    c.isinstance = function(self, klass)
        local m = getmetatable(self)
        while m do
            if m == klass then return true end
            m = m.__base
        end
        return false
    end

    setmetatable(c, mt)
    return c
end
