local utils = require("scripts.modules.utils.utils")

local movingArray = {}

-- generated with gpt
local function adjustInnerCirclePosition(ix, iy, ox, oy, outerRadius)
    local distance = math.sqrt((ix - ox)^2 + (iy - oy)^2)

    if distance > outerRadius then
        -- Calculate the angle between the centers of the circles
        local angle = math.atan2(iy - oy, ix - ox)

        -- Set the inner circle to the maximum position within the outer circle
        ix = ox + outerRadius * math.cos(angle)
        iy = oy + outerRadius * math.sin(angle)
    end

    return ix, iy
end

local function triggerJoystick(event)
    local object = event.source.object
    Runtime:dispatchEvent(
        { 
            name = "onControlsMovePlayer", 
            phase = "moved",
            method = "joystick",
            degrees = utils.calculateDegrees(object.outer.x, object.outer.y, object.inner.x, object.inner.y),
            distance = utils.calculateDistance(object.outer.x, object.outer.y, object.inner.x, object.inner.y),
        }
    )
end

-- moving the joystick
local function moveJoystick(event)
    if movingArray[event.id] and movingArray[event.id].o then
        local inner = movingArray[event.id].o.inner
        local outer = movingArray[event.id].o.outer
        if inner and outer then
            if event.phase == "moved" then
                local ux, uy = adjustInnerCirclePosition(event.x - movingArray[event.id].x, event.y - movingArray[event.id].y, outer.x, outer.y, outer.path.radius)
                if (ux ~= inner.x or uy ~= inner.y) then
                    inner.x = ux
                    inner.y = uy
                    inner.overlay.x = inner.x
                    inner.overlay.y = inner.y
                end
            elseif event.phase == "ended" or event.phase == "cancelled" then
                timer.cancel(movingArray[event.id].t)
                movingArray[event.id].t = nil
                inner.x = outer.x
                inner.y = outer.y
                inner.overlay.x = inner.x
                inner.overlay.y = inner.y
                movingArray[event.id] = nil
                Runtime:removeEventListener("touch", moveJoystick)
                Runtime:dispatchEvent({ name = "onControlsMovePlayer", method = "joystick", phase = event.phase })
            end
        end
    end
end

-- touching the joystick
local function touchJoystick(event)
    if event.phase == "began" then
        movingArray[event.id] = { 
            o = event.target.parent,
            x = event.x - event.target.x, 
            y = event.y - event.target.y,
            t = timer.performWithDelay(10, triggerJoystick, 0),
        }
        movingArray[event.id].t.object = event.target.parent
        Runtime:addEventListener("touch", moveJoystick)
    end
end

-- draw the joystick
local function createJoystick(x, y, outerRadius, innerRadius)
    -- group object
    local object = display.newGroup()
    object.x = x
    object.y = y

    -- outer (larger) circle
    object.outer = display.newCircle(object, 0, 0, outerRadius)
    object.outer.fill = { 0, 0, 0, 0.01 }
    object.outer.overlay = display.newImageRect(object, "./assets/joystick_outer.png", 85, 85)
    object.outer.overlay:setFillColor(0, 0, 0, 0.7)

    -- inner (smaller) circle
    object.inner = display.newCircle(object, 0, 0, innerRadius)
    object.inner.fill = { 0.8, 0.8, 0.8, 0.01 }
    object.inner.overlay = display.newImageRect(object, "./assets/joystick_inner.png", 42, 42)
    object.inner.overlay:setFillColor(0, 0, 0, 0.7)

    -- event handler for start moving
    object.inner:addEventListener("touch", touchJoystick)

    -- send back the group
    return object
end

-- destroy the joystick and clean up
local function destroyJoystick(object)
    if object then
        -- cancel timers
        for id, value in pairs(movingArray) do
            if value.o == object then
                timer.cancel(movingArray[id].t)
                movingArray[id] = nil
                break
            end
        end

        -- 
        object.inner:removeEventListener("touch", touchJoystick)
        object:removeSelf()
        object = nil
    end
end

-- exporting
return { 
    create = createJoystick, 
    destroy = destroyJoystick
}