Powerup = Class{}

powerup_kind = {
    ["red-cross"] = 1,
    ["green-cross"] = 2,
    ["hearth"] = 3,
    ["skull"] = 4,
    ["up"] = 5,
    ["down"] = 6,
    ["ball"] = 7,
    ["square"] = 8,
    ["ball-square"] = 9,
    ["key"] = 10
}
function Powerup:init(x, y, kind)

    self.x = x
    self.y = y

    self.width = 16
    self.height = 16

    --Kind of power up from 1 to 10
    self.kind = kind
    self.inGame = true
end

function Powerup:update(dt)
    self.y = math.max(0, self.y + POWERUP_SPEED * dt)

end

function Powerup:collides(target)
    if self.inGame and self.x < target.x + target.width and self.x + self.width > target.x and self.y < target.y + target.height and self.height + self.y > target.y then
        self.inGame = false
        return true
    end
    return false
end

function Powerup:render()
    if self.inGame then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.kind - 1],
        self.x, self.y)
    end
end