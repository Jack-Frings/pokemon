--[[
    GD50
    Pokemon

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

TakeTurnState = Class{__includes = BaseState}

function TakeTurnState:init(battleState, playerMove)
    self.battleState = battleState
    self.playerPokemon = self.battleState.player.party.pokemon[1]
    self.opponentPokemon = self.battleState.opponent.party.pokemon[1]

    self.playerSprite = self.battleState.playerSprite
    self.opponentSprite = self.battleState.opponentSprite

    self.attempted_run = false
    self.playerMove = playerMove or self.battleState.moves[1]

    -- opponent picks randomly but never heals
    local opponentMoves = {}
    for _, move in ipairs(self.battleState.moves) do
        if not move.heal then
            table.insert(opponentMoves, move)
        end
    end
    self.opponentMove = opponentMoves[math.random(#opponentMoves)]

    if self.playerPokemon.speed > self.opponentPokemon.speed then
        self.firstPokemon = self.playerPokemon
        self.secondPokemon = self.opponentPokemon
        self.firstSprite = self.playerSprite
        self.secondSprite = self.opponentSprite
        self.firstBar = self.battleState.playerHealthBar
        self.secondBar = self.battleState.opponentHealthBar
        self.firstMove = self.playerMove
        self.secondMove = self.opponentMove
    else
        self.firstPokemon = self.opponentPokemon
        self.secondPokemon = self.playerPokemon
        self.firstSprite = self.opponentSprite
        self.secondSprite = self.playerSprite
        self.firstBar = self.battleState.opponentHealthBar
        self.secondBar = self.battleState.playerHealthBar
        self.firstMove = self.opponentMove
        self.secondMove = self.playerMove
    end
end

function TakeTurnState:enter(params)
    if self.attempted_run then
        self:attack(self.opponentPokemon, self.playerPokemon, self.opponentSprite, self.playerSprite,
            self.battleState.opponentHealthBar, self.battleState.playerHealthBar, self.opponentMove,
            function()
                gStateStack:pop()
                if self:checkDeaths() then gStateStack:pop() return end
                gStateStack:pop()
                gStateStack:push(BattleMenuState(self.battleState))
            end)
        return
    end

    self:attack(self.firstPokemon, self.secondPokemon, self.firstSprite, self.secondSprite, self.firstBar, self.secondBar, self.firstMove,
    function()
        gStateStack:pop()
        if self:checkDeaths() then gStateStack:pop() return end

        self:attack(self.secondPokemon, self.firstPokemon, self.secondSprite, self.firstSprite, self.secondBar, self.firstBar, self.secondMove,
        function()
            gStateStack:pop()
            if self:checkDeaths() then gStateStack:pop() return end
            gStateStack:pop()
            gStateStack:push(BattleMenuState(self.battleState))
        end)
    end)
end

function TakeTurnState:attack(attacker, defender, attackerSprite, defenderSprite, attackerBar, defenderBar, move, onEnd)
    gStateStack:push(BattleMessageState(attacker.name .. ' used ' .. move.name .. '!',
        function() end, false))

    Timer.after(0.5, function()

        -- handle heal move
        if move.heal then
            gStateStack:pop()
            if self.battleState.playState.heals <= 0 then
                gStateStack:push(BattleMessageState("No heals remaining!",
                    function() end, false))
                Timer.after(0.5, function()
                    onEnd()
                end)
            else
                local healAmount = math.floor(attacker.HP / 2)
                attacker.currentHP = math.min(attacker.HP, attacker.currentHP + healAmount)
                self.battleState.playState.heals = self.battleState.playState.heals - 1

                Timer.tween(0.5, {
                    [attackerBar] = {value = attacker.currentHP}
                })

                gStateStack:push(BattleMessageState(attacker.name .. ' healed! ' ..
                    self.battleState.playState.heals .. ' heals remaining.',
                    function() end, false))
                Timer.after(0.5, function()
                    onEnd()
                end)
            end
            return
        end

        gSounds['powerup']:stop()
        gSounds['powerup']:play()

        Timer.every(0.1, function()
            attackerSprite.blinking = not attackerSprite.blinking
        end)
        :limit(6)
        :finish(function()
            if math.random() > move.accuracy then
                gStateStack:pop()
                gStateStack:push(BattleMessageState(attacker.name .. "'s attack missed!",
                    function() end, false))
                Timer.after(0.5, function()
                    onEnd()
                end)
                return
            end

            gSounds['hit']:stop()
            gSounds['hit']:play()

            Timer.every(0.1, function()
                defenderSprite.opacity = defenderSprite.opacity == 64/255 and 1 or 64/255
            end)
            :limit(6)
            :finish(function()
                local dmg
                if move.power == 0 then
                    dmg = 0
                else
                    dmg = math.max(1, (attacker.attack * move.power / 50) - defender.defense)
                end

                Timer.tween(0.5, {
                    [defenderBar] = {value = defender.currentHP - dmg}
                })
                :finish(function()
                    defender.currentHP = defender.currentHP - dmg
                    onEnd()
                end)
            end)
        end)
    end)
end

function TakeTurnState:checkDeaths()
    if self.playerPokemon.currentHP <= 0 then
        self:faint()
        return true
    elseif self.opponentPokemon.currentHP <= 0 then
        self:victory()
        return true
    end

    return false
end

function TakeTurnState:faint()
    Timer.tween(0.2, {
        [self.playerSprite] = {y = VIRTUAL_HEIGHT}
    })
    :finish(function()
        gStateStack:push(BattleMessageState('You fainted!',
        function()
            gStateStack:push(FadeInState({
                r = 0, g = 0, b = 0
            }, 1,
            function()
                self.playerPokemon.currentHP = self.playerPokemon.HP
                gSounds['battle-music']:stop()
                gSounds['field-music']:play()
                gStateStack:pop()
                gStateStack:push(FadeOutState({
                    r = 0, g = 0, b = 0
                }, 1, function()
                    gStateStack:push(DialogueState('Your Pokemon has been fully restored; try again!'))
                end))
            end))
        end))
    end)
end

function TakeTurnState:victory()
    Timer.tween(0.2, {
        [self.opponentSprite] = {y = VIRTUAL_HEIGHT}
    })
    :finish(function()
        gSounds['battle-music']:stop()
        gSounds['victory-music']:setLooping(true)
        gSounds['victory-music']:play()

        gStateStack:push(BattleMessageState('Victory!',
        function()
            local exp = (self.opponentPokemon.HPIV + self.opponentPokemon.attackIV +
                self.opponentPokemon.defenseIV + self.opponentPokemon.speedIV) * self.opponentPokemon.level

            gStateStack:push(BattleMessageState('You earned ' .. tostring(exp) .. ' experience points!',
                function() end, false))

            Timer.after(1.5, function()
                gSounds['exp']:play()

                Timer.tween(0.5, {
                    [self.battleState.playerExpBar] = {value = math.min(self.playerPokemon.currentExp + exp, self.playerPokemon.expToLevel)}
                })
                :finish(function()
                    gStateStack:pop()
                    self.playerPokemon.currentExp = self.playerPokemon.currentExp + exp

                    if self.playerPokemon.currentExp > self.playerPokemon.expToLevel then
                        gSounds['levelup']:play()
                        self.playerPokemon.currentExp = self.playerPokemon.currentExp - self.playerPokemon.expToLevel

                        local oldHP = self.playerPokemon.HP
                        local oldAttack = self.playerPokemon.attack
                        local oldDefense = self.playerPokemon.defense
                        local oldSpeed = self.playerPokemon.speed

                        local HPIncrease, attackIncrease, defenseIncrease, speedIncrease = self.playerPokemon:statsLevelUp()

                        gStateStack:push(BattleMessageState('Congratulations! Level Up! ' ..
                            'HP: ' .. oldHP .. ' + ' .. HPIncrease .. ' = ' .. self.playerPokemon.HP .. ' ' ..
                            'Attack: ' .. oldAttack .. ' + ' .. attackIncrease .. ' = ' .. self.playerPokemon.attack .. ' ' ..
                            'Defense: ' .. oldDefense .. ' + ' .. defenseIncrease .. ' = ' .. self.playerPokemon.defense .. ' ' ..
                            'Speed: ' .. oldSpeed .. ' + ' .. speedIncrease .. ' = ' .. self.playerPokemon.speed,
                        function()
                            self:fadeOutWhite()
                        end))
                    else
                        self:fadeOutWhite()
                    end
                end)
            end)
        end))
    end)
end

function TakeTurnState:fadeOutWhite()
    gStateStack:push(FadeInState({
        r = 1, g = 1, b = 1
    }, 1,
    function()
        gSounds['victory-music']:stop()
        gSounds['field-music']:play()
        gStateStack:pop()
        gStateStack:push(FadeOutState({
            r = 1, g = 1, b = 1
        }, 1, function() end))
    end))
end
