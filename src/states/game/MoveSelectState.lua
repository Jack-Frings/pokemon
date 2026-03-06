--[[
    GD50
    Pokemon
    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]
MoveSelectState = Class{__includes = BaseState}

function MoveSelectState:init(battleState)
    self.battleState = battleState
    local moveItems = {}
    for i, move in ipairs(self.battleState.moves) do
        local label
        if move.power == 0 then
            label = move.name .. '  --  ACC:' .. (move.accuracy * 100) .. '%'
        else
            label = move.name .. '  PWR:' .. move.power .. '  ACC:' .. (move.accuracy * 100) .. '%'
        end
        table.insert(moveItems, {
            text = label,
            onSelect = function()
                gStateStack:pop()
                local state = TakeTurnState(self.battleState, move)
                state.playerMove = move
                gStateStack:push(state)
            end
        })
    end
    self.menu = Menu {
        x = 10,
        y = VIRTUAL_HEIGHT - 64,
        width = VIRTUAL_WIDTH - 10,
        height = 64,
        items = moveItems
    }
end

function MoveSelectState:update(dt)
    self.menu:update(dt)
end

function MoveSelectState:render()
    self.menu:render()
end
