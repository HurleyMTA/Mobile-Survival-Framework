local utils = require("scripts.modules.utils.utils")
local globals = require("scripts.modules.utils.globals")
local physics = require("physics")
local platform = system.getInfo("platform")

-- local shite
local ticktimer

-- attack the player
local function handleHostileAttack(hostile)
    if not hostile.cooldown then
        -- attack animation
        utils.setSpriteAnimation({ sprite = hostile.sprite, sequence = "zombie_attack" })

        -- allow player script to handle the damage
        globals.player:dispatchEvent({ name = "onPlayerDamage", damage = hostile.damage })

        -- set a cooldown to expire, which is dynamic based on the hostiles attack speed
        hostile.cooldown = true
        timer.performWithDelay(hostile.attackspeed, function()
            hostile.cooldown = nil
        end, 1)
    end
end

-- recalculate all hostile movements on tick
local function handleHostileMovement()
    -- define center of the players collision
    local playerCenterX, playerCenterY = globals.player.collision:localToContent(0, 0)
    playerCenterX = playerCenterX - globals.map.x
    playerCenterY = playerCenterY - globals.map.y

    for _, hostile in ipairs(globals.hostiles) do
        -- define the center of the hostiles collision
        local hostileCenterX, hostileCenterY = hostile.collision:localToContent(0, 0)
        hostileCenterX = hostileCenterX - hostile.parent.x
        hostileCenterY = hostileCenterY - hostile.parent.y

        local hostileDistance = utils.calculateDistance(hostileCenterX, hostileCenterY, playerCenterX, playerCenterY)
        local isHostileAttacking = false

        -- next to the player, so handle attack
        if hostileDistance < 32 then
            if string.find(hostile.sprite.sequence, "walk") then -- if they're walking, stop them, ready to attack
                utils.setSpriteAnimation({ sprite = hostile.sprite, sequence = "idle" })
            end
            handleHostileAttack(hostile)
            isHostileAttacking = true
        end

        local target -- we're going to store the target object here once found, either player or breadcrumb
        local hostilesInLineOfSight = {} -- store any other hostiles that block the hostiles route to the player

        -- first search for the player and ignore breadcrumbs
        local hitPlayer = physics.rayCast(hostileCenterX, hostileCenterY, playerCenterX, playerCenterY, "sorted")
        if hitPlayer then
            for index = 1, #hitPlayer do
                if hitPlayer[index].object.type then
                    if hitPlayer[index].object.type == "hostile" then
                        hostilesInLineOfSight[#hostilesInLineOfSight + 1] = hitPlayer[index].object.owner
                    elseif hitPlayer[index].object.type == "collision" then
                        break
                    elseif hitPlayer[index].object.type == "player" then
                        target = {
                            object = globals.player,
                            x = playerCenterX,
                            y = playerCenterY,
                        }
                        break
                    end
                end
            end
        end

        -- walk toward the target for the next tick
        if target then
            -- angle/radians the hostile needs to walk
            local angle = utils.calculateDegrees(hostileCenterX, hostileCenterY, target.x, target.y)
            local radians = math.rad(angle)
        
            -- add these to the x, y for the new position
            local scale = globals.sheets[hostile.id].scale[globals.platform]
            local deltaX = (hostile.speed * scale) * math.cos(radians)
            local deltaY = (hostile.speed * scale) * math.sin(radians)

            -- rotate to face the player
            hostile.sprite.rotation = angle
            hostile.collision.rotation = angle
        
            -- check if the hostile is blocked
            local blocked = false
            for index = 1, #hostilesInLineOfSight do
                if utils.areRectanglesIntersecting(hostile.collision.x + deltaX, hostile.collision.y + deltaY, hostile.collision.width, hostile.collision.height,
                hostilesInLineOfSight[index].collision.x, hostilesInLineOfSight[index].collision.y, hostilesInLineOfSight[index].collision.width, hostilesInLineOfSight[index].collision.height) then
                    blocked = true
                    break
                end
            end
        
            -- allow them to move if they're 24+ from the player, or if they're targetting a breadcrumb
            if (hostileDistance > 32 or target.object ~= globals.player) and not blocked then
                hostile.x = hostile.x + deltaX
                hostile.y = hostile.y + deltaY
                hostile.collision.x = hostile.collision.x + deltaX
                hostile.collision.y = hostile.collision.y + deltaY
                utils.setSpriteAnimation({ sprite = hostile.sprite, sequence = "move" })
            else
                if not isHostileAttacking then
                    utils.setSpriteAnimation({ sprite = hostile.sprite, sequence = "idle" })
                end
            end
        else
            utils.setSpriteAnimation({ sprite = hostile.sprite, sequence = "idle" })
        end
    end
end

-- also clean up!
local function destroyHostile(hostile)
    for index = 1, #globals.hostiles do
        if globals.hostiles[index] == hostile then
            globals.hostiles[index].sprite.imagesheet = nil
            globals.hostiles[index].collision:removeSelf()
            globals.hostiles[index]:removeSelf()
            table.remove(globals.hostiles, index)
            break
        end
    end
end

-- clear all hostiles - we can use this for the nuke too
local function clearHostiles()
    if ticktimer then
        timer.cancel(ticktimer)
        ticktimer = nil
    end
    for index = 1, #globals.hostiles do
        destroyHostile(globals.hostiles[index])
    end
    globals.hostiles = {}
end

local function createHostile(id)
    -- image sheet
    local imagesheet = graphics.newImageSheet("./assets/" .. id .. ".png", globals.sheets[id].frames)

    -- get scale which varies on platform
    local scale = globals.sheets[id].scale[globals.platform]

    -- create the hostile group and set anchor
    local element = display.newGroup()
    element.anchorX = 0
    element.anchorY = 0
    element.type = "hostile"
    element:scale(scale, scale)

    -- set scale info
    local spriteOffsetX = 20
    local spriteOffsetY = 8
    local collisionSize = (48 * scale)

    -- create the hostile sprite within the group
    local sprite = display.newSprite(element, imagesheet, globals.sheets[id].sequences)
    sprite.x = spriteOffsetX
    sprite.y = spriteOffsetY
    sprite.imagesheet = imagesheet

    --- hostile metadata
    element.id = id
    element.sprite = sprite
    element.speed = 5
    element.health = 100
    element.maxhealth = element.health
    element.damage = 50 -- per hit
    element.attackspeed = 2000 -- hit cooldown

    -- spawn the group to a random position on the map
    globals.map:dispatchEvent({ name = "spawn", object = element })

    -- collision rect
    local collisionX, collisionY = element.sprite:localToContent(0, 0)
    element.collision = display.newRect(element.parent, (collisionX - element.parent.x), (collisionY - element.parent.y), collisionSize, collisionSize)
    element.collision.anchorX = 0.7
    element.collision.anchorY = 0.5
    element.collision.type = "hostile"
    element.collision.owner = element
    element.collision:setFillColor(0, 0, 0, 0)
    physics.addBody(element.collision, "static")

    -- health bar visual
    element.healthvis = {}
    element.healthvis.background = display.newRect(element, 0, -30, (element.width / 2), 8)
    element.healthvis.background.anchorX = 0
    element.healthvis.background.anchorY = 0
    element.healthvis.background:setFillColor(0, 0.5)
    element.healthvis.overlay = display.newRect(element, 2, -28, (element.healthvis.background.width - 4), 4)
    element.healthvis.overlay.anchorX = 0
    element.healthvis.overlay.anchorY = 0
    element.healthvis.overlay:setFillColor(1, 0, 0, 0.8)

    -- add to our table of active hostiles
    table.insert(globals.hostiles, element)

    -- called when the zombie takes damage
    local function takeDamage(event)
        -- update health and health bar
        element.health = math.max(0, (element.health - event.damage))
        element.healthvis.overlay.width = ((element.healthvis.background.width - 4) / element.maxhealth) * element.health

        -- damage indicator
        local x, y = element:localToContent(0, 0)
        local indicator = display.newText({ text = event.damage, x = x, y = y })
        indicator:setFillColor(1, 0, 0, 0.6)
        transition.to(indicator, { time = 350, y = y - 20 })
        timer.performWithDelay(350, function(event)
            indicator:removeSelf() 
            indicator = nil
        end, 1)

        -- if they hit 0 hp
        if element.health == 0 then
            element:dispatchEvent({ name = "onHostileDeath" })
            destroyHostile(element)
        end
    end
    element:addEventListener("onHostileDamage", takeDamage)

    -- set up our tick timer if it's the first hostile
    if not ticktimer then
        ticktimer = timer.performWithDelay(10, handleHostileMovement, 0)
    end

    return element
end

return {
    create = createHostile,
    destroy = destroyHostile,
    clear = clearHostiles,
}