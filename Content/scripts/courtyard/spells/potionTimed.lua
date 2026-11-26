local Base = require("spells/timed")
local Script = setmetatable({}, {__index = Base})
Script.__index = Script

-- The spellbook can briefly retain a propagated SPELL bonus after cart death.
-- Validate the actual battlefield, not the hero's cached bonus list.
function Script:hasLiveCart(mechanics)
    local side = mechanics:getCasterSide()
    local carts = mechanics:getBattle():getUnitsIf(function(unit)
        return unit:isAlive() and unit:getSide() == side
            and unit:getCreature():getJsonKey() == "courtyard:potionCartCreature"
    end)
    return #carts > 0
end

function Script:isValidTarget(mechanics, unit)
    return self:hasLiveCart(mechanics) and Base.isValidTarget(self, mechanics, unit)
end

function Script:apply(mechanics, server, target)
    if not self:hasLiveCart(mechanics) then return end
    Base.apply(self, mechanics, server, target)
end

return Script
