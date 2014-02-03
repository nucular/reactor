--[[ Reactor ]]--
--by nucular

require("reactor/class")
require("reactor/element")

reactor = {}
reactor.gui = dofile("reactor/gui.lua")

function reactor.initialize()
    reactor.TEST = elem.allocate("REACTOR", "TEST")
    elem.element(reactor.TEST, elem.element(1))

    reactor.elem = Element(reactor.TEST)

    reactor.gui.initialize()
end

function reactor.update()
    reactor.elem:saveTo(reactor.TEST)
end

reactor.initialize()
reactor.gui.show()