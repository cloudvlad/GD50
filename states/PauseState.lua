PauseState = Class{__includes = BaseState}

function PauseState:enter(score)
    self.image = love.graphics.newImage('images/pause.png')
    self.score = score
    self.scale = 0.15
    sounds['music']:pause()
    sounds['pause']:play()
end
    

function PauseState:update(dt)
    -- transition to countdown when enter/return are pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown', self.score)
    end

    if love.keyboard.wasPressed('P') or love.keyboard.wasPressed('p') then
        gStateMachine:change('countdown', self.score)
    end
end

function PauseState:render()
    love.graphics.draw(self.image,
    ((VIRTUAL_WIDTH - (self.scale * self.image:getWidth())) / 2), 
    ((VIRTUAL_HEIGHT - (self.scale * self.image:getHeight())) / 2), 
    0, 
    self.scale, self.scale)
end

function PauseState:exit()
    sounds['pause']:play()
    sounds['music']:play()
end