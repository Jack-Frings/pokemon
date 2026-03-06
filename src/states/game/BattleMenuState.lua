--[[
    GD50
    Pokemon

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

BattleMenuState = Class{__includes = BaseState}

function BattleMenuState:init(battleState)
    self.battleState = battleState
    local speed_diff = self.battleState.player.party.pokemon[1].speed - self.battleState.opponent.party.pokemon[1].speed 
    self.escape_chance = math.min(0.95, math.max(0.1, 0.5 + (0.05*speed_diff)))
    
    self.battleMenu = Menu {
        x = VIRTUAL_WIDTH - 64,
        y = VIRTUAL_HEIGHT - 64,
        width = 64,
        height = 64,
        items = {
            {
                text = 'Fight',
                onSelect = function()
                    gStateStack:pop()
                    gStateStack:push(MoveSelectState(self.battleState))
                end
            },
            {
                text = 'Run',
                onSelect = function()
                    if math.random() < self.escape_chance then
                        gSounds['run']:play()
                        gStateStack:pop()
                        gStateStack:push(BattleMessageState('You fled successfully!',
                            function() end), false)
                        Timer.after(0.5, function()
                            gStateStack:push(FadeInState({
                                r = 1, g = 1, b = 1
                            }, 1,
                            function()
                                gSounds['field-music']:play()
                                gStateStack:pop()
                                gStateStack:pop()
                                gStateStack:push(FadeOutState({
                                    r = 1, g = 1, b = 1
                                }, 1, function() end))
                            end))
                        end)
                    else
                        gSounds['run']:play()
                        gStateStack:pop()
                        local state = TakeTurnState(self.battleState)
                        state.attempted_run = true
                        gStateStack:push(BattleMessageState("Couldn't escape!", function()
                            gStateStack:push(state)
                        end))
                    end
                end
            }
        }
    }
end

function BattleMenuState:update(dt)
    self.battleMenu:update(dt)
end

function BattleMenuState:render()
    self.battleMenu:render()
end
