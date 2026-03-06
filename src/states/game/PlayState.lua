--[[
    GD50
    Pokemon

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    self.level = Level()

	self.heals = 10

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
		local msg = "You've used up all your heals silly billy."

		if self.heals >= 0 then
			-- heal player pokemon
			gSounds['heal']:play()
			self.level.player.party.pokemon[1].currentHP = self.level.player.party.pokemon[1].HP

			msg = "Your Pokemon has been healed. You have " .. tostring(self.heals) .. " heals remaining."

			self.heals = self.heals - 1
		end
			
			-- show a dialogue for it, allowing us to do so again when closed
			gStateStack:push(DialogueState(msg,
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
