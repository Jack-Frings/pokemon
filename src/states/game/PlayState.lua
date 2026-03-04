--[[
    GD50
    Pokemon

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    self.level = Level()

    gSounds['field-music']:setLooping(true)
    gSounds['field-music']:play()

    self.dialogueOpened = false

    nightTimer = 0
    nightDuration = 45
end

function nightUpdate(dt)
    nightTimer = nightTimer + dt

    if nightTimer >= nightDuration then
        nightTime = not nightTime
        nightTimer = nightTimer - nightDuration

        if nightTime then
            gStateStack:push(BattleMessageState('Night is coming... Be careful!', function() end), false)
            Timer.after(1, function()
                gStateStack:pop()
            end)
        elseif not nightTime then
            gStateStack:push(BattleMessageState('The sun is rising again!',function() end, false))
            Timer.after(1, function()
                gStateStack:pop()
            end)
        end
    end
end

function PlayState:update(dt)
    if not self.dialogueOpened and love.keyboard.wasPressed('p') then
        
        -- heal player pokemon
        gSounds['heal']:play()
        self.level.player.party.pokemon[1].currentHP = self.level.player.party.pokemon[1].HP
        
        -- show a dialogue for it, allowing us to do so again when closed
        gStateStack:push(DialogueState('Your Pokemon has been healed!',
    
        function()
            self.dialogueOpened = false
        end))
    end

    nightUpdate(dt)
    self.level:update(dt)
end

function PlayState:render()
    self.level:render()   
end