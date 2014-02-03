require("reactor/class")

local Transition = class()
function Transition:__init(value, element)
    self.value = value
    self.element = element
end


local Reaction = class()
function Reaction:__init(educt, product, range, mode)
    self.educt = educt
    self.product = product

    self.range = range
    self.mode = mode
end

function Reaction:generate()
    local t = string.format(
[[if sim.partProperty(sim.partID(math.random(%s, %s), math.random(%s, %s)), 'type') == %s then
    sim.partChangeType(i, %s)
end]],
        -self.range, self.range, -self.range, self.range, self.educt, self.product)
    return t
end


Element = class()
function Element:__init(id)
    self:loadFrom(id)
    self.reactions = {}
end

function Element:generateUpdateLua()
    local t = "return function(i, px, py, s, nt)\n"

    for i, v in ipairs(self.reactions) do
        t = t .. v:generate() .. "\n"
    end

    return t .. "end"
end

function Element:generateGraphicsLua()
    return [[return function(i, cr, cg, cb)
    return 0 
end]]
end

function Element:generateLua()
    return --
end

function Element:generateCpp(id)
    local t = string.format(
[[#include "simulation/Elements.h"
//#TPT-Directive ElementClass Element_%s PT_%s %s
Element_%s::Element_%s()
{
    Identifier = "DEFAULT_PT_%s";
    Name = "%s";
    Colour = PIXPACK(%.6X);
    MenuVisible = %s;
    MenuSection = %s;
    Enabled = %s;
}]])
end

function Element:loadFrom(id)
    -- load the properties from an existing element
    -- does NOT load the update functions
    local t = elem.element(id)
    self.name = t.Name
    self.colour = t.Colour
    self.menuvisible = t.MenuVisible
    self.menusection = t.MenuSection
    self.advection = t.Advection
    self.airdrag = t.AirDrag
    self.airloss = t.AirLoss
    self.loss = t.Loss
    self.collision = t.Collision
    self.gravity = t.Gravity
    self.diffusion = t.Diffusion
    self.hotair = t.HotAir
    self.falldown = t.Falldown
    self.flammable = t.Flammable
    self.explosive = t.Explosive
    self.meltable = t.Meltable
    self.hardness = t.Hardness
    self.weight = t.Weight
    self.temperature = t.Temperature
    self.heatconduct = t.HeatConduct
    self.description = t.Description
    self.state = t.State
    self.properties = t.Properties
    self.lpt = Transition(t.LowPressure, t.LowPressureTransition)
    self.hpt = Transition(t.HighPressure, t.HighPressureTransition)
    self.ltt = Transition(t.LowTemperature, t.LowTemperatureTransition)
    self.htt = Transition(t.HighTemperature, t.HighTemperatureTransition)
end

function Element:saveTo(id)
    -- save the properties to an existing element
    -- also generates and loads update and graphic functions
    local t = {}
    t.Name = self.name
    t.Colour = self.colour
    t.Color = self.colour
    t.MenuVisible = self.menuvisible
    t.MenuSection = self.menusection
    t.Advection = self.advection
    t.AirDrag = self.airdrag
    t.AirLoss = self.airloss
    t.Loss = self.loss
    t.Collision = self.collision
    t.Gravity = self.gravity
    t.Diffusion = self.diffusion
    t.HotAir = self.hotair
    t.Falldown = self.falldown
    t.Flammable = self.flammable
    t.Explosive = self.explosive
    t.Meltable = self.meltable
    t.Hardness = self.hardness
    t.Weight = self.weight
    t.Temperature = self.temperature
    t.HeatConduct = self.heatconduct
    t.Description = self.description
    t.State = self.state
    t.Properties = self.properties
    t.LowPressure = self.lpt.value
    t.LowPressureTransition = self.lpt.element
    t.HighPressure = self.hpt.value
    t.HighPressureTransition = self.hpt.element
    t.LowTemperature = self.ltt.value
    t.LowTemperatureTransition = self.ltt.element
    t.HighTemperature = self.htt.value
    t.HighTemperatureTransition = self.htt.element
    t.Update = nil
    t.Graphics = nil
    elem.element(id, t)
    tpt.element_func(loadstring(self:generateUpdateLua())(), id, 1)
    tpt.graphics_func(loadstring(self:generateGraphicsLua())(), id)
end
