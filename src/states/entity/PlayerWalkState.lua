--[[
    GD50
    Pokemon
    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]
PlayerWalkState = Class{__includes = EntityWalkState}

function PlayerWalkState:init(entity, level)
    EntityWalkState.init(self, entity, level)
    self.encounterFound = false
end

function PlayerWalkState:enter()
    self:checkForEncounter()
    if not self.encounterFound then
        self:attemptMove()
    end
end

function PlayerWalkState:checkForEncounter()
    local x, y = self.entity.mapX, self.entity.mapY
    if self.level.grassLayer.tiles[y][x].id == TILE_IDS['tall-grass'] and math.random(10) == 1 then
        self.entity:changeState('idle')
        gSounds['field-music']:pause()
        gSounds['battle-music']:play()
        gStateStack:push(
            FadeInState({
                r = 1, g = 1, b = 1,
            }, 1,
            function()
                gStateStack:push(BattleState(self.entity, self.level.playState))
                gStateStack:push(FadeOutState({
                    r = 1, g = 1, b = 1,
                }, 1,
                function()
                end))
            end)
        )
        self.encounterFound = true
    else
        self.encounterFound = false
    end
end
