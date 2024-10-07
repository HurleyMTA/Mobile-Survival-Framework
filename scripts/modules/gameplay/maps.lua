local utils = require("scripts.modules.utils.utils")
local globals = require("scripts.modules.utils.globals")
local physics = require("physics")

-- global.maps is the table of maps
-- global.map is the map object

-- adjust the globals.maps scale dynamically
local function adjustMapScale(mapName)
    if not globals.maps[mapName].adjusted then
        -- prevent undersizing by mistake
        globals.maps[mapName].adjusted = true

        -- width/height
        local scale = globals.maps[mapName].scale[globals.platform]
        globals.maps[mapName].width = globals.maps[mapName].width * scale
        globals.maps[mapName].height = globals.maps[mapName].height * scale

        -- collisions
        for i = 1, #globals.maps[mapName].collisions do
            local adjust = { 
                globals.maps[mapName].collisions[i][1] * scale,
                globals.maps[mapName].collisions[i][2] * scale,
                globals.maps[mapName].collisions[i][3] * scale,
                globals.maps[mapName].collisions[i][4] * scale,
            }
            globals.maps[mapName].collisions[i] = adjust
        end

        -- spawn
        globals.maps[mapName].spawn[1] = globals.maps[mapName].spawn[1] * scale
        globals.maps[mapName].spawn[2] = globals.maps[mapName].spawn[2] * scale

        -- zm spawn
        globals.maps[mapName].zm_spawn[1] = globals.maps[mapName].zm_spawn[1] * scale
        globals.maps[mapName].zm_spawn[2] = globals.maps[mapName].zm_spawn[2] * scale
        globals.maps[mapName].zm_spawn[3] = globals.maps[mapName].zm_spawn[3] * scale
        globals.maps[mapName].zm_spawn[4] = globals.maps[mapName].zm_spawn[4] * scale
    end
end

-- checks whether the x, y, w, h collides with a map collision box
local function doesCollide(x, y, width, height)
    for _, col in ipairs(globals.map.collisions) do
        if(utils.areRectanglesIntersecting(x, y, width, height, globals.map.x + col.x, globals.map.y + col.y, col.width, col.height)) then
            return true
        end
    end
    return false
end

-- moves the camera (when the player is at the edge)
local function moveCamera(deltaX, deltaY)
    local group = globals.map
    local mapName = globals.map.mapName

    -- get the new x, y
    local newX = (group.x - deltaX)
    local newY = (group.y - deltaY)

    -- calculate the far x, y (map boundaries)
    local farX = display.screenOriginX - (globals.maps[mapName].width - display.actualContentWidth)
    local farY = display.screenOriginY - (globals.maps[mapName].height - display.actualContentHeight)

    -- if the camera is locked at the edge, return false so the sprite isn't moved as well
    if (newX > display.screenOriginX) or (newX < farX) or (newY > display.screenOriginY) or (newY < farY) then
        return false
    end

    -- lock the camera if at the edge
    newX = (newX > display.screenOriginX and display.screenOriginX) or (newX < farX and farX) or newX
    newY = (newY > display.screenOriginY and display.screenOriginY) or (newY < farY and farY) or newY

    -- set the x, y
    group.x = newX
    group.y = newY

    -- tell the player script that the camera was moved
    return true
end

-- for spawning players or hostiles to the map
local function spawnObject(event)
    if event.object and event.object.type then
        local mapName = globals.map.mapName
        
        -- player vs hostile
        local x, y
        if event.object.type == "player" then
            x, y = globals.maps[mapName].spawn[1], globals.maps[mapName].spawn[2]
            globals.map.x = -x + (display.safeActualContentWidth / 2) - (event.object.width / 2)
            globals.map.y = -y + (display.safeActualContentHeight / 2)
        elseif event.object.type == "hostile" then
            x = globals.maps[mapName].zm_spawn[1] + math.random(0, globals.maps[mapName].zm_spawn[3])
            y = globals.maps[mapName].zm_spawn[2] + math.random(0, globals.maps[mapName].zm_spawn[4])
        end

        -- set position and parent
        event.object.x = x
        event.object.y = y
        globals.map:insert(event.object)
    end
end

-- creates the map
local function createMap(mapName)
    -- fix scale of collisions and size
    adjustMapScale(mapName)

    -- group presets
    globals.map = display.newGroup()
    globals.map.mapName = mapName

    -- set group positioning
    globals.map.x = display.screenOriginX
    globals.map.y = display.screenOriginY
    globals.map.anchorChildren = true
    globals.map.anchorX = 0
    globals.map.anchorY = 0
    globals.map.type = "map"
    
    -- background image presets
    globals.map.background = display.newImageRect(globals.map, globals.maps[mapName].path, globals.maps[mapName].width, globals.maps[mapName].height)
    globals.map.background.anchorX = 0
    globals.map.background.anchorY = 0

    -- create collisions
    globals.map.collisions = {}
    for i = 1, #globals.maps[mapName].collisions do
        globals.map.collisions[i] = display.newRect(globals.map, globals.maps[mapName].collisions[i][1], globals.maps[mapName].collisions[i][2], globals.maps[mapName].collisions[i][3], globals.maps[mapName].collisions[i][4])
        globals.map.collisions[i].anchorX = 0
        globals.map.collisions[i].anchorY = 0
        globals.map.collisions[i]:setFillColor(0, 0, 0, 0)
        globals.map.collisions[i].type = "collision"
        physics.addBody(globals.map.collisions[i], "static")
    end

    -- listen for spawn event (for players & hostiles)
    globals.map:addEventListener("spawn", spawnObject)

    -- return the group
    return globals.map
end

-- destroys the map object
local function destroyMap()
    if globals.map then
        globals.map:removeEventListener("spawn", spawnObject)
        globals.map:removeSelf()
        globals.map = nil
    end
end

-- exports
return { 
    create = createMap,
    destroy = destroyMap,
    collides = doesCollide,
    camera = moveCamera,
 }
