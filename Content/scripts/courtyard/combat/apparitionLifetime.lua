local Base = require("combat/combatScript")
local Script = setmetatable({}, {__index = Base})
Script.__index = Script

local AGE = "courtyard.apparition.elapsedRounds"

-- Each stack keeps its own counter as a hidden battle bonus (save/load safe).
-- The hero's stronger trigger replaces the creature trigger via stacking.
function Script:onRoundStart(server, battle, unit)
    if not unit:isAlive() then return end
    local marker = unit:getBonuses({type = "NONE"}):filter(function(b)
        return b:getStacking() == AGE
    end)
    local elapsed = 1
    if marker:size() > 0 then
        elapsed = marker:getBonus(1):getVal() + 1
    end
    if elapsed >= self.val then
        server:removeUnit(battle, unit)
        return
    end
    -- At most two markers are ever added; the shared stacking key keeps the larger count.
    server:addUnitBonus(battle, unit, {
        type = "NONE", val = elapsed, duration = "ONE_BATTLE",
        sourceType = "OTHER", hidden = true, stacking = AGE
    }, true)
end

return Script
