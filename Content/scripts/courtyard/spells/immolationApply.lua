local Base = require("spells/unitEffect")
local Script = setmetatable({}, {__index = Base})
Script.__index = Script

-- One timed, dispellable spell bonus carries the burn parameters.
function Script:apply(mechanics, server, target)
    local battle = mechanics:getBattle()
    local spellKey = mechanics:getSpell():getJsonKey()
    for _, dest in ipairs(target) do
        local unit = dest.unit
        if unit and unit:isAlive() then
            local old = unit:getBonuses({type = "COMBAT_EVENT_TRIGGER", subtype = "courtyard:immolationTick"}):filter(function(b)
                return b:getSourceID() == spellKey
            end)
            -- The engine's non-cumulative update only extends duration, not mastery/value.
            -- Replace the previous curse explicitly so the latest successful cast wins.
            if old:size() > 0 then server:removeUnitBonuses(battle, unit, old) end
            server:addUnitBonus(battle, unit, {
                type = "COMBAT_EVENT_TRIGGER",
                subtype = "courtyard:immolationTick",
                val = self.baseDamage,
                addInfo = {countFactor = self.countFactor},
                duration = "N_TURNS",
                -- VCMI decrements N_TURNS before onRoundStart; reserve one extra count.
                turns = math.max(1, mechanics:getEffectDuration()) + 1,
                sourceType = "SPELL_EFFECT",
                sourceID = spellKey,
                sourceSecondaryID = mechanics:getEffectLevel(),
                stacking = spellKey
            }, false)
        end
    end
end

return Script
