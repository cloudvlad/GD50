--[[
    GD50
    Breakout Remake

    -- PowerUp Class --

    Represents a ball which will bounce back and forth between the sides
    of the world space, the player's paddle, and the bricks laid out above
    the paddle. The ball can have a skin, which is chosen at random, just
    for visual variety.
]]

PowerUp = Class{}

-- Take brick x and y
function PowerUp:init(bx, by, type)
    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16

    self.x = bx + 16
    self.y = by

    self.type = type
    self.inPlay = true
    -- these variables are for keeping track of our velocity on both the
    -- X and Y axis, since the ball can move in two dimensions
    self.dy = 20

    -- this will effectively be the color of our ball, and we will index
    -- our table of Quads relating to the global block texture using this
    self.skin = skin
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function PowerUp:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Places the ball in the middle of the screen, with no movement.
]]

function PowerUp:update(dt)
    self.y = self.y + self.dy * dt
end

function PowerUp:render()
    -- gTexture is our global texture for all blocks
    -- gBallFrames is a table of quads mapping to each individual ball skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.type],
        self.x, self.y)
end