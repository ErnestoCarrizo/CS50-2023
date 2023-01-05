Powerup = Class{}

function Powerup:init(x, y, kind)

    self.x = x
    self.y = y

    self.width = 16
    self.height = 16

    --Kind of power up from 1 to 10
    self.kind = kind
end

function Powerup:update(dt)
    self.y = math.max(0, self.y + POWERUP_SPEED * dt)

end

function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.kind - 1],
        self.x, self.y)
end