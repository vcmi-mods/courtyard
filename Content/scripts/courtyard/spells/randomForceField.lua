local Base = require("spells/obstacle")
local Script = setmetatable({}, {__index = Base})
Script.__index = Script

-- ENCHANTER supplies the caster's occupied hex, not a free location.
-- Reuse the normal obstacle validator for every possible anchor and all its shape hexes.
local silentProblem = {addStandard = function() end}
local function availableAnchors(self, mechanics)
    local battle = mechanics:getBattle()
    local targeted = {
        isMassive = function() return false end,
        getBattle = function() return battle end,
        getCasterSide = function() return mechanics:getCasterSide() end,
    }
    local result = {}
    local hexes = battle:getAllPossibleHexes()
    for i = 1, hexes:size() do
        local hex = hexes:at(i)
        if Base.applicableTarget(self, targeted, silentProblem, {{hex = hex}}) then
            result[#result + 1] = hex
        end
    end
    return result
end

function Script:applicableGeneral(mechanics, problem)
    if #availableAnchors(self, mechanics) > 0 then return true end
    problem:addStandard(mechanics, ENUM.SpellCastProblem.noAppropriateTarget)
    return false
end

function Script:applicableTarget(mechanics, problem, target)
    return self:applicableGeneral(mechanics, problem)
end

function Script:apply(mechanics, server, target)
    local anchors = availableAnchors(self, mechanics)
    if #anchors == 0 then return end
    Base.apply(self, mechanics, server, {{hex = anchors[server:rngInt(1, #anchors)]}})
end

return Script
