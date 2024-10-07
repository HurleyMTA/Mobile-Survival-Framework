local exports = {}

-- localize math funcs, makes it quicker
local abs = math.abs
local sqrt = math.sqrt
local deg = math.deg
local atan2 = math.atan2
local cos = math.cos
local sin = math.sin
local rad = math.rad

-- used to check which direction an object is from another
exports.relativePositionToRectangle = function(x, y, rectX, rectY, rectWidth, rectHeight)
    local centerX = rectX + rectWidth / 2
    local centerY = rectY + rectHeight / 2

    local dx = x - centerX
    local dy = y - centerY

    local adx = abs(dx)
    local ady = abs(dy)

    if adx > rectWidth / 2 then
        if dx > 0 then
            return "right"
        else
            return "left"
        end
    elseif ady > rectHeight / 2 then
        if dy > 0 then
            return "below"
        else
            return "above"
        end
    else
        return "inside"
    end
end

-- checks collisions usually
exports.areRectanglesIntersecting = function(x1, y1, w1, h1, x2, y2, w2, h2)
    if x1 + w1 < x2 or x2 + w2 < x1 then
        return false
    end
    if y1 + h1 < y2 or y2 + h2 < y1 then
        return false
    end
    return true
end

exports.isPointInsideRectangle = function(x, y, rectX, rectY, rectWidth, rectHeight)
    return x >= rectX and x <= rectX + rectWidth and y >= rectY and y <= rectY + rectHeight
end

exports.calculateDegrees = function(ox, oy, ix, iy)
    return deg(atan2(iy - oy, ix - ox))
end

exports.calculateDistance = function(x1, y1, x2, y2)
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

exports.setSpriteAnimation = function(container) -- sprite, sequence, finishsequence, override
    if container.sprite.sequence ~= container.sequence then
        if not container.override then
            -- don't interrupt attacks (from hostiles)
            if (string.find(container.sprite.sequence, "attack")) then
                return
            end

            -- don't interrupt firing (from players)
            if (string.find(container.sprite.sequence, "shoot")) then
                return
            end
        end
        
        -- set the sequence if it's different
        container.sprite.sequence = container.sequence
        container.sprite:setSequence(container.sequence)
        container.sprite:play()
        
        -- if they need to return to another sequence after
        if container.finishsequence then
            timer.performWithDelay(500, function()
                if container.sprite.sequence == container.sequence then -- check the sequence hasn't changed since then
                    container.sprite.sequence = container.finishsequence
                    container.sprite:setSequence(container.finishsequence)
                    container.sprite:play()
                end
            end, 1)
        end
    end
end

exports.getMuzzlePosition = function(player) -- relative to map
    local radians = rad(player.muzzle.rotation)
    local x, y = player.muzzle:localToContent(-40, 0) -- minus 40 so we can kill hostiles close up
    return x - player.parent.x, y - player.parent.y, radians
end

exports.updateLaserPointer = function(player)
    if player.laser then
        player.laser:removeSelf()
    end
    local x, y = player.muzzle:localToContent(0, 0)
    local radians = rad(player.muzzle.rotation)
    player.laser = display.newLine(x, y, x + (display.actualContentWidth) * cos(radians), y + (display.actualContentWidth) * sin(radians))
    player.laser:setStrokeColor(1, 0, 0, 0.8)
end

exports.isMobile = function()
    return true
end

return exports