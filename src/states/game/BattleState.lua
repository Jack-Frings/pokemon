--[[
    GD50
    Pokemon

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

BattleState = Class{__includes = BaseState}

function BattleState:init(player)
    self.player = player
    self.bottomPanel = Panel(0, VIRTUAL_HEIGHT - 64, VIRTUAL_WIDTH, 64)

    self.moves = {
        { name = 'Tackle',   power = 40, accuracy = 1.0 },
        { name = 'Headbutt', power = 70, accuracy = 0.85 },
        { name = 'Slam',     power = 90, accuracy = 0.75 },
        { name = 'Growl',    power = 0,  accuracy = 1.0 }
    }

    -- flag for when the battle can take input, set in the first update call
    self.battleStarted = false

    if nightTime then 
        self.opponent = Opponent {
            party = Party {
                pokemon = {
                    Pokemon(Pokemon.getRandomDef(), math.random(2, 4))
                }
            }
        }
    elseif not nightTime then
        self.opponent = Opponent {
            party = Party {
                pokemon = {
                    Pokemon(Pokemon.getRandomDef(), math.random(2, 6))
                }
            }
        }
    end

    self.playerSprite = BattleSprite(self.player.party.pokemon[1].battleSpriteBack, 
        -64, VIRTUAL_HEIGHT - 128)
    self.opponentSprite = BattleSprite(self.opponent.party.pokemon[1].battleSpriteFront, 
        VIRTUAL_WIDTH, 8)

    self.playerHealthBar = ProgressBar {
        x = VIRTUAL_WIDTH - 160,
        y = VIRTUAL_HEIGHT - 80,
        width = 152,
        height = 6,
        color = {r = 189/255, g = 32/255, b = 32/255},
        value = self.player.party.pokemon[1].currentHP,
        max = self.player.party.pokemon[1].HP
    }

    self.opponentHealthBar = ProgressBar {
        x = 8,
        y = 8,
        width = 152,
        height = 6,
        color = {r = 189/255, g = 32/255, b = 32/255},
        value = self.opponent.party.pokemon[1].currentHP,
        max = self.opponent.party.pokemon[1].HP
    }

    self.playerExpBar = ProgressBar {
        x = VIRTUAL_WIDTH - 160,
        y = VIRTUAL_HEIGHT - 73,
        width = 152,
        height = 6,
        color = {r = 32/255, g = 32/255, b = 189/255},
        value = self.player.party.pokemon[1].currentExp,
        max = self.player.party.pokemon[1].expToLevel
    }

    self.renderHealthBars = false

    self.playerCircleX = -68
    self.opponentCircleX = VIRTUAL_WIDTH + 32

    self.playerPokemon = self.player.party.pokemon[1]
    self.opponentPokemon = self.opponent.party.pokemon[1]
end

function BattleState:enter(params)
    
end

function BattleState:exit()
    gSounds['battle-music']:stop()
end

function BattleState:update(dt)
    if not self.battleStarted then
        self:triggerSlideIn()
    end
end

function BattleState:render()
    love.graphics.clear(214/255, 214/255, 214/255, 1)

    love.graphics.setColor(45/255, 184/255, 45/255, 124/255)
    love.graphics.ellipse('fill', self.opponentCircleX, 60, 72, 24)
    love.graphics.ellipse('fill', self.playerCircleX, VIRTUAL_HEIGHT - 64, 72, 24)

    if nightTime == true then
        love.graphics.setColor(0, 0, .2, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.setColor(1, 1, 1, 1)
    self.opponentSprite:render()
    self.playerSprite:render()

    if self.renderHealthBars then
        self.playerHealthBar:render()
        self.opponentHealthBar:render()
        self.playerExpBar:render()

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.print('LV ' .. tostring(self.playerPokemon.level),
            self.playerHealthBar.x, self.playerHealthBar.y - 10)
        love.graphics.print('LV ' .. tostring(self.opponentPokemon.level),
            self.opponentHealthBar.x, self.opponentHealthBar.y + 8)
        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(1, 1, 1, 1)
    end

    self.bottomPanel:render()
end

function BattleState:triggerSlideIn()
    self.battleStarted = true

    Timer.tween(1, {
        [self.playerSprite] = {x = 32},
        [self.opponentSprite] = {x = VIRTUAL_WIDTH - 96},
        [self] = {playerCircleX = 66, opponentCircleX = VIRTUAL_WIDTH - 70}
    })
    :finish(function()
        self:triggerStartingDialogue()
        self.renderHealthBars = true
    end)
end

function BattleState:triggerStartingDialogue()
    gStateStack:push(BattleMessageState('A wild ' .. tostring(self.opponent.party.pokemon[1].name ..
        ' appeared!'),
    function()
        gStateStack:push(BattleMessageState('Go, ' .. tostring(self.player.party.pokemon[1].name .. '!'),
        function()
            gStateStack:push(BattleMenuState(self))
        end))
    end))
end
