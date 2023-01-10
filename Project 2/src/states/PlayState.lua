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

powerup_spawn_timer = 5

paddle_sizes = {
    [1] = 32,
    [2] = 64,
    [3] = 96,
    [4] = 128
}
--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level

    self.recoverPoints = 5000
    self.paddleBonus = self.score + 1000
    -- give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -60)
end

function PlayState:update(dt)

    if not self.paused then
        powerup_spawn_timer = math.max(0, powerup_spawn_timer - 1 * dt)
    end

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
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for i = 1, #self.balls do
        self.balls[i]:update(dt)
    end

    if powerup then
        powerup:update(dt)
        if powerup:collides(self.paddle) and #self.balls <= 2 then
            self.balls[#self.balls + 1] = Ball(self.balls[1].x + 8,
                self.balls[1].y + 8, 
                self.balls[1].dx,
                self.balls[1].dy,
                math.random(7))
        end
    end

    for i = #self.balls, 1, -1 do
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

        for i = 1, #self.balls do
        -- only check collision if we're in play
            if brick.inPlay and self.balls[i]:collides(brick) then
                -- add to score
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)

                    -- trigger the brick's hit function, which removes it from play
                    brick:hit()

                    -- if we have enough points, recover a point of health
                    self:bonusLife()

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
                    
            end
        end
    end
    
    if self:checkVictory() then
        gSounds['victory']:play()
        powerup = nil
        self.balls = {}
        self.balls[1] = Ball(self.paddle.x + (self.paddle.width / 2) - 4, self.paddle.y - 8, 0, 0, math.random(7))
        gStateMachine:change('victory', {
            level = self.level,
            paddle = self.paddle,
            health = self.health,
            score = self.score,
            highScores = self.highScores,
            balls = self.balls,
            recoverPoints = self.recoverPoints
        })
    end

    if not self:atleastOne() then
        self.health = self.health - 1
        self.paddle.size = math.max(self.paddle.size - 1, 1)
        self.paddle.width = paddle_sizes[self.paddle.size]
        powerup = nil
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
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

    self.paddle:render()
    
    for i = 1, #self.balls do
        self.balls[i]:render()
    end

    if powerup then
        powerup:render()
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

function PlayState:atleastOne()
    res = false
    for i = #self.balls, 1, -1 do
        if self.balls[i].y < VIRTUAL_HEIGHT then
            res = true
        elseif self.balls[i].y > VIRTUAL_HEIGHT then
            table.remove(self.balls, i)
        end
    end
    return res
end

function PlayState:bonusLife()
    if self.score > self.recoverPoints then
        -- can't go above 3 health
        self.health = math.min(3, self.health + 1)

        -- multiply recover points by 2
        self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

        -- play recover sound effect
        gSounds['recover']:play()
    elseif self.score > self.paddleBonus then
        self.paddle.size = math.min(self.paddle.size + 1, 4)
        self.paddleBonus = self.paddleBonus + 1000
        self.paddle.width = paddle_sizes[self.paddle.size]
    end
end