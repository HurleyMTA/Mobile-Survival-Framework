local utils = require("scripts.modules.utils.utils")
local globals = require("scripts.modules.utils.globals")
local maps = require("scripts.modules.gameplay.maps")
local weapons = require("scripts.modules.gameplay.weapons")
local physics = require("physics")

-- hold the player sprite in a var for exporting
local godmode = true

-- hardcoded margin settings
local marginSizeX, marginSizeY = (display.actualContentWidth / 100) * 20, (display.actualContentHeight / 100) * 20
local marginX, marginY = display.screenOriginX + marginSizeX, display.screenOriginY + marginSizeY
local marginWidth, marginHeight = display.actualContentWidth - (marginSizeX * 2), display.actualContentHeight - (marginSizeY * 2)

-- move the player by the given x, y
local function actuallyMovePlayer(deltaX, deltaY)
    if globals.player then
        -- get the local screen pos of the player collision
        local playerColScreenX, playerColScreenY = globals.player.collision:localToContent(0, 0)

        -- check if the player collides with a collision
        local isCollidingWithMap = maps.collides(
            playerColScreenX + deltaX,
            playerColScreenY + deltaY,
            globals.player.collision.width,
            globals.player.collision.height
        )

        -- back out if hit map collisions
        if isCollidingWithMap then
            return false
        end

        -- check if it's intersecting with the margin
        local isCollisionInBounds = utils.areRectanglesIntersecting(
            playerColScreenX + deltaX, 
            playerColScreenY + deltaY,
            globals.player.collision.width, 
            globals.player.collision.height,
            marginX,
            marginY,
            marginWidth,
            marginHeight
        )
        
        -- tell the map script to move the camera if the sprite is outside the boundary
        local hasMapMoved = false
        if not isCollisionInBounds then
            hasMapMoved = maps.camera(deltaX, deltaY) -- this will return false if at the edge of the map
        end

        -- update the sprite's x, y if the camera has moved OR they aren't at the boundary edge
        if (hasMapMoved or isCollisionInBounds) then
            globals.player.x = globals.player.x + deltaX
            globals.player.y = globals.player.y + deltaY
            globals.player.collision.x = globals.player.collision.x + deltaX
            globals.player.collision.y = globals.player.collision.y + deltaY
        end
    end
end

-- when the player moves with either keyboard or joystick
local function movePlayer(event)
    if globals.player then
        if event.method == "joystick" or event.method == "keyboard" then
            -- moving the player
            if event.phase == "moved" then
                local scale = globals.sheets[globals.player.id].scale[globals.platform]
                local deltaX, deltaY = 0, 0

                -- calculate distance and direction
                if event.method == "joystick" then -- from mobile.lua
                    local radians = math.rad(event.degrees)
                    local distance = ((event.distance / 5) * scale) * globals.player.speed
                    deltaX = distance * math.cos(radians)
                    deltaY = distance * math.sin(radians)
                elseif event.method == "keyboard" then -- from keyboard.lua
                    local distance = (6 * scale) * globals.player.speed
                    deltaX = (event.bind == "move_left" and -distance) or (event.bind == "move_right" and distance) or 0 -- 3 is max speed of joystick
                    deltaY = (event.bind == "move_up" and -distance) or (event.bind == "move_down" and distance) or 0
                end

                -- move the sprite, set animation and update laser pointer
                actuallyMovePlayer(deltaX, deltaY)
                utils.setSpriteAnimation({ sprite = globals.player.sprite, sequence = weapons.sequence("move") })
                utils.updateLaserPointer(globals.player)
            elseif event.phase == "ended" or event.phase == "cancelled" then
                -- return the sprite to the "default" position
                utils.setSpriteAnimation({ sprite = globals.player.sprite, sequence = weapons.sequence("idle") })
            end
        end
    end
end

local function rotatePlayer(event)
    if globals.player then
        if event.phase == "moved" then
            local rotation
            if event.method == "cursor" then
                local muzzleX, muzzleY = globals.player.muzzle:localToContent(-35, 0)
                rotation = utils.calculateDegrees(muzzleX, muzzleY, event.x, event.y)
            elseif event.method == "auto" then
                rotation = event.degrees
            end
            globals.player.sprite.rotation = rotation
            globals.player.muzzle.rotation = rotation
            globals.player.collision.rotation = rotation
            utils.updateLaserPointer(globals.player)
        end
    end
end

-- create the player
local function createPlayer(id)
    -- image sheet
    local imagesheet = graphics.newImageSheet("./assets/" .. id .. ".png", globals.sheets[id].frames)

    -- get scale, which will vary on platform
    local scale = globals.sheets[id].scale[globals.platform]

    -- create the "element" group
    local element = display.newGroup()
    element.anchorX = 0
    element.anchorY = 0
    element.x = display.screenOriginX + (display.actualContentWidth / 2) - 32
    element.y = display.screenOriginY + (display.actualContentHeight / 2) - 32
    element.type = "player"
    element:scale(scale, scale)

    -- set scale info
    local spriteOffsetX = 40
    local spriteOffsetY = 0
    local collisionSize = (48 * scale)

    -- sprite
    local sprite = display.newSprite(element, imagesheet, globals.sheets[id].sequences)
    sprite.x = spriteOffsetX
    sprite.y = spriteOffsetY
    sprite.imagesheet = imagesheet

    -- metadata
    element.id = id
    element.sprite = sprite
    element.speed = 1 -- multiplier
    element.health = 150 -- 150 hp so it's 3 hit down
    element.maxhealth = element.health
    element.points = 1000

    -- tracking
    element.stats = {
        survived = 1,
        dealt = 0,
        killed = 0,
    }

    -- spawn
    globals.map:dispatchEvent({ name = "spawn", object = element })

    -- collision
    local collisionX, collisionY = element.sprite:localToContent(0, 0)
    element.collision = display.newRect(element.parent, (collisionX - element.parent.x), (collisionY - element.parent.y), collisionSize, collisionSize)
    element.collision.anchorX = 0.7
    element.collision.anchorY = 0.5
    element.collision.type = "player"
    element.collision:setFillColor(0, 0, 0, 0)
    physics.addBody(element.collision, "static")

    -- muzzle flash, which starts invisible
    element.muzzle = display.newImageRect(element, "./assets/muzzleflash.png", 8, 8)
    element.muzzle:setFillColor(0, 0)

    -- handle the natural health regen
    local function delayedHeal(cancel)
        -- if currently healing, cancel
        if element.healthregen then
            timer.cancel(element.healthregen)
            element.healthregen = nil
        end

        -- if currently on heal cooldown, cancel
        if element.healthcooldown then
            timer.cancel(element.healthcooldown)
            element.healthcooldown = nil
        end

        if not cancel then
            -- set a heal cooldown, which starts healing upon completion
            element.healthcooldown = timer.performWithDelay(5000, function() -- quick revive should effect this delay
                element.healthcooldown = nil
                element.healthregen = timer.performWithDelay(250, function()
                    element.health = math.min(element.maxhealth, element.health + 10)
                    element:dispatchEvent({ name = "onPlayerHeal" })
                    if element.health == element.maxhealth then
                        timer.cancel(element.healthregen)
                        element.healthregen = nil
                    end
                end, 0)
            end, 1)
        end
    end

    -- movement handlers
    Runtime:addEventListener("onControlsMovePlayer", movePlayer)
    Runtime:addEventListener("onControlsRotatePlayer", rotatePlayer)

    -- damage handler
    local function handlePlayerDamage(event)
        if not godmode then
            element.health = math.max(0, (element.health - event.damage))
            if element.health == 0 then
                element:dispatchEvent({ name = "onPlayerDeath" })
                delayedHeal(true)
            else
                delayedHeal()
            end
        end
    end
    element:addEventListener("onPlayerDamage", handlePlayerDamage)

    -- death handler
    local function handlePlayerDeath(event)
        element:removeEventListener("onPlayerDamage", handlePlayerDamage)
        element:removeEventListener("onPlayerDeath", handlePlayerDeath)
        if element.laser then
            element.laser:removeSelf()
            element.laser = nil
        end
    end
    element:addEventListener("onPlayerDeath", handlePlayerDeath)

    -- store this for later
    globals.player = element

    -- send the player element back
    return element
end

-- destroy the player and clean up
local function destroyPlayer()
    if globals.player then
        -- health regen timer
        if globals.player.healthregen then
            timer.cancel(globals.player.healthregen)
        end

        -- health cooldown timer
        if globals.player.healthcooldown then
            timer.cancel(globals.player.healthcooldown)
        end

        -- laser pointer
        if globals.player.laser then
            globals.player.laser:removeSelf()
        end

        -- movement events
        Runtime:removeEventListener("onControlsMovePlayer", movePlayer)
        Runtime:removeEventListener("onControlsRotatePlayer", rotatePlayer)

        -- remaining
        globals.player.collision:removeSelf() -- isn't a child, so must remove this manually
        globals.player.sprite.imagesheet = nil
        globals.player:removeSelf() -- removes all child objects t oo
        globals.player = nil
    end
end

return { 
    create = createPlayer,
    destroy = destroyPlayer,
    get = getPlayer,
 }
