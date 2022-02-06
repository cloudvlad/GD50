--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]

function PlayState:enter(params)
    self.paddle = params.paddle
    self.skin = params.skin
    self.size = params.size
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level
    self.recoverPoints = params.recoverPoints
    self.haveKey = false
    self.keyBrickHits = params.keyBrickHits

    -- give ball random starting velocity
    
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -60)

    keybrick_pu = PowerUp(10, 10, 9, false)
    pu = PowerUp(10, 10, 10, false)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        self.balls = PuBallPlus(self.paddle, self.balls)
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    keybrick_pu:update(dt)
    pu:update(dt)


    if keybrick_pu.y >= VIRTUAL_HEIGHT then
        keybrick_pu.inPlay = false
    end

    if pu.y >= VIRTUAL_HEIGHT + 20 then
        pu.inPlay = false
    end

    if keybrick_pu:collides(self.paddle) and keybrick_pu.inPlay then
        if keybrick_pu.type == 9 then
            self.balls = PuBallPlus(self.paddle, self.balls)
            keybrick_pu.inPlay = false
        end
    end

    if pu:collides(self.paddle) and pu.inPlay then
        self.haveKey = true
        pu.inPlay = false
    end

    if self.haveKey then
        SET_KEY = false
    end

    -- update all balls
    for i = 1, #self.balls do
        self.balls[i]:update(dt)
    end

    for i = 1, #self.balls do
        if self.balls[i]:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            self.balls[i].y = self.paddle.y - 8
            self.balls[i].dy = -self.balls[i].dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if self.balls[i].x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                self.balls[i].dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.balls[i].x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif self.balls[i].x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                self.balls[i].dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.balls[i].x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play

        for i = 1, #self.balls do
            if brick.inPlay and self.balls[i]:collides(brick) then

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- trigger the brick's hit function, which removes it from play
                if brick:hit() then
                    if not self.haveKey and SET_KEY then
                        brick.inPlay = true
                        self.keyBrickHits = self.keyBrickHits + 1
                        print("Hits: " .. tostring(self.keyBrickHits))
                    else
                        keybrick_pu = PowerUp(brick.x, brick.y, 9, true)
                        brick.inPlay = false
                    end
                end

                if self.keyBrickHits % NEEDED_HITS == 0 and SET_KEY then
                    if not pu.inPlay then
                        pu = PowerUp(math.random(32, VIRTUAL_WIDTH - 32), -16, 10, true)
                    end
                end

                

                

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then

                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    if self.health == 3 then
                        self.size = math.max(2, self.size - 1)
                        self.paddle = Paddle(self.skin, self.size)
                    end

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        skin = self.skin,
                        size = self.size,
                        health = self.health,
                        score = self.score,
                        balls = self.balls,
                        highScores = self.highScores,
                        recoverPoints = self.recoverPoints,
                        keyBrickHits = 1
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if self.balls[i].x + 2 < brick.x and self.balls[i].dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    self.balls[i].dx = -self.balls[i].dx
                    self.balls[i].x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif self.balls[i].x + 6 > brick.x + brick.width and self.balls[i].dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    self.balls[i].dx = -self.balls[i].dx
                    self.balls[i].x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif self.balls[i].y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    self.balls[i].dy = -self.balls[i].dy
                    self.balls[i].y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    self.balls[i].dy = -self.balls[i].dy
                    self.balls[i].y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(self.balls[i].dy) < 150 then
                    self.balls[i].dy = self.balls[i].dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    for i = 1, #self.balls do
        if self.balls[i].y >= VIRTUAL_HEIGHT then

            if #self.balls > 1 then
                table.remove(self.balls, i)
                break
            end

            self.health = self.health - 1
            gSounds['hurt']:play()

            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores
                })
            else
                gStateMachine:change('serve', {
                    skin = self.skin,
                    size = math.min(4, self.size + 1),
                    paddle = Paddle(self.skin, math.min(4, self.size + 1)),
                    bricks = self.bricks,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    level = self.level,
                    recoverPoints = self.recoverPoints,
                    keyBrickHits = self.keyBrickHits
                })
            end
        end
    end
    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    keybrick_pu:render()
    pu:render()
    self.paddle:render()

    for i = 1, #self.balls do
        self.balls[i]:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end
