local Base = require("combat/combatScript")
local BattleLog = require("battleLog")
local Script = setmetatable({}, {__index = Base})
Script.__index = Script

local SPELL = "courtyard:immolationCurse"
local LEGACY_DAMAGE = "courtyard:immolationDamage"
local ANIMATION = "courtyard/spells/Immolation/Immolation.def"

function Script:damage(unit)
    if unit:isInvincible() then return 0 end
    -- Preserve the original count-dependent raw formula without altering the victim's power.
    local amount = self.val + 10 * math.floor(unit:getCount() * self.countFactor / 100)
    local function value(kind, subtype)
        return unit:getBonusesValue({type = kind, subtype = subtype})
    end
    -- Apply only target-side modifiers. Spell:adjustDamage would use the victim's hero
    -- as the caster and incorrectly apply that hero's offensive magic bonuses.
    for _, school in ipairs({"fire", "any"}) do
        amount = math.floor(amount * math.max(0, 100 - value("SPELL_DAMAGE_REDUCTION", school)) / 100)
    end
    -- Preserve existing modifiers targeting the old helper spell; also recognize the curse.
    local vulnerability = value("MORE_DAMAGE_FROM_SPELL", LEGACY_DAMAGE) + value("MORE_DAMAGE_FROM_SPELL", SPELL)
    amount = math.floor(amount * math.max(0, 100 + vulnerability) / 100)
    local cap = unit:getBonusesValue({type = "DAMAGE_RECEIVED_CAP"})
    if cap > 0 then amount = math.min(amount, math.floor(unit:getMaxHealth() * cap / 100)) end
    return math.max(0, amount)
end

function Script:onRoundStart(server, battle, unit)
    if not unit:isAlive() then return end
    local last = unit:getBonuses({type = "COMBAT_EVENT_TRIGGER", subtype = "courtyard:immolationTick"}):filter(function(b)
        return b:getSourceID() == SPELL and b:getTurnsRemain() == 1
    end)
    local amount = self:damage(unit)
    if amount > 0 then
        local count = unit:getCount()
        local name = unit:getCreature():getNameTextID(count)
        server:showBattleAnimation(battle, {{unit = unit}}, ANIMATION, "FIREBLST", 1.0, true)
        local dealt, killed = server:damageUnit(battle, unit, amount)
        if server:describeChanges() and dealt > 0 then
            server:appendLog(battle, {
                append = {count == 1 and "courtyard.battleLog.immolation.singular" or "courtyard.battleLog.immolation.plural"},
                replaceStrings = {name}, replaceNumbers = {dealt}
            })
            BattleLog.creaturesPerish(server, battle, unit, killed)
        end
    end
    -- Remove immediately after the last tick, even when the damage was fully absorbed.
    if unit:isAlive() and last:size() > 0 then server:removeUnitBonuses(battle, unit, last) end
end

return Script
