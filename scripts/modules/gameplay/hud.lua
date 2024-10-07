local globals = require("scripts.modules.utils.globals")

-- for storing the objects
local objects = {}

 -- define bar size
 local barWidth = 100
 local barHeight = 15
 local barPadding = 2

-- triggered when a player takes damage
local function updateHealth()
    if objects.health then
        objects.health.foreground.width = ((barWidth - (barPadding * 2)) / globals.player.maxhealth) * globals.player.health
        objects.health.label.text = globals.player.health
    end
end

-- triggered when a zombie dies during current round
local function updateRound(event)
    if objects.counter then
        objects.counter.roundshadow.text = event.round
        objects.counter.round.text = event.round
    end
    if objects.points then
        objects.points.label.text = "$" .. globals.player.points
    end
end

-- create the HUD for the first time
local function createTopHUD()
    local x, y = display.screenOriginX + 40, display.screenOriginY + 20

    local dropShadowPadding = 0.5

    -- font
    local hudFont = native.newFont("./assets/Nexa-Heavy.ttf", 12)

    -- counter
    objects.counter = display.newGroup()
    objects.counter.x = x
    objects.counter.y = y

    objects.counter.titleshadow = display.newText({ parent = objects.counter, text = "ROUND", width = 50, font = hudFont, fontSize = 12, x = dropShadowPadding, y = dropShadowPadding, align = "center" })
    objects.counter.titleshadow:setFillColor(0, 0, 0, 1)
    
    objects.counter.title = display.newText({ parent = objects.counter, text = "ROUND", width = 50, font = hudFont, fontSize = 12, align = "center" })
    objects.counter.title:setFillColor(0.8, 0, 0, 1)

    objects.counter.roundshadow = display.newText({ parent = objects.counter, text = "10", width = 50, font = hudFont, fontSize = 30, x = dropShadowPadding, y = 20 + dropShadowPadding, align = "center" })
    objects.counter.roundshadow:setFillColor(0, 0, 0, 1)

    objects.counter.round = display.newText({ parent = objects.counter, text = "10", width = 50, font = hudFont, fontSize = 30, y = 20, align = "center" })
    objects.counter.round:setFillColor(0.8, 0, 0, 1)

    -- adjust pos
    y = y - 3
    x = x + 40

    -- health
    objects.health = display.newGroup()
    objects.health.x = x
    objects.health.y = y
    
    objects.health.background = display.newImageRect(objects.health, "./assets/barbg.png", barWidth, barHeight)
    objects.health.background.anchorX = 0
    objects.health.background.anchorY = 0

    objects.health.foreground = display.newRect(objects.health, barPadding, barPadding, barWidth - (barPadding * 2), barHeight - (barPadding * 2))
    objects.health.foreground.anchorX = 0
    objects.health.foreground.anchorY = 0
    objects.health.foreground:setFillColor(0.95, 0, 0, 0.9)

    objects.health.label = display.newText({ parent = objects.health, text = "150", y = 1.5, width = barWidth, font = hudFont, fontSize = 9, align = "center" })
    objects.health.label.anchorX = 0
    objects.health.label.anchorY = 0

    -- bump down for next bar
    y = y + 19

    -- points
    objects.points = display.newGroup()
    objects.points.x = x
    objects.points.y = y

    objects.points.background = display.newImageRect(objects.points, "./assets/barbg.png", barWidth, barHeight)
    objects.points.background.anchorX = 0
    objects.points.background.anchorY = 0

    objects.points.foreground = display.newRect(objects.points, barPadding, barPadding, barWidth - (barPadding * 2), barHeight - (barPadding * 2))
    objects.points.foreground.anchorX = 0
    objects.points.foreground.anchorY = 0
    objects.points.foreground:setFillColor(0, 0.6, 0, 0.9)

    objects.points.label = display.newText({ parent = objects.points, text = "$5300", y = 2, width = barWidth, font = hudFont, fontSize = 9, align = "center" })
    objects.points.label.anchorX = 0
    objects.points.label.anchorY = 0
end

local function destroyTopHUD()
    if objects.health then
        objects.health:removeSelf()
        objects.health = nil
    end
    if objects.level then
        objects.level:removeSelf()
        objects.level = nil
    end
    if objects.counter then
        objects.counter:removeSelf()
        objects.counter = nil
    end
    if objects.points then
        objects.points:removeSelf()
        objects.points = nil
    end
end

local function destroyWeaponHUD()
    if (objects.weapon and objects.weapon.group) then
        objects.weapon.group:removeSelf()
        objects.weapon = nil
    end
end

local function createWeaponHUD()
    if not globals.player.weapons then
        print("Error creating HUD. No weapon data found on player element.")
        return
    end

    -- cache details on weps
    local current = globals.player.weapons.current
    local data = (globals.player.weapons[current] and globals.weapons[globals.player.weapons[current].id])

    -- start x, y
    local x = display.safeScreenOriginX + (display.safeActualContentWidth / 2) - (data.width / 2)
    local y = display.safeScreenOriginY + display.safeActualContentHeight - data.height - 40

    -- table for weapon hud objects
    objects.weapon = {}

    -- group
    objects.weapon.group = display.newGroup()
    objects.weapon.group.anchorX = 0
    objects.weapon.group.anchorY = 0
    objects.weapon.group.x = x
    objects.weapon.group.y = y

    -- image
    objects.weapon.icon = display.newImageRect(objects.weapon.group, data.path, data.width, data.height)
    objects.weapon.icon.anchorX = 0
    objects.weapon.icon.anchorY = 0
    objects.weapon.icon:setFillColor(1, 1, 1, 0.7)

    -- clip
    objects.weapon.clip = display.newText({ parent = objects.weapon.group, text = globals.player.weapons[current].clip, x = 0, y = data.height, width = 15, height = 20, fontSize = 12, align = "left" })
    objects.weapon.clip.anchorX = 0
    objects.weapon.clip.anchorY = 0

    -- reserve
    objects.weapon.reserve = display.newText({ parent = objects.weapon.group, text = globals.player.weapons[current].reserve, x = 17, y = data.height + 2, width = 20, height = 20, fontSize = 9, align = "left" })
    objects.weapon.reserve.anchorX = 0
    objects.weapon.reserve.anchorY = 0

    -- type
    local slotlabel = (current == "primary" and 1) or (current == "secondary" and 2) or (current == "mulekick" and 3)
    objects.weapon.slot = display.newText({ parent = objects.weapon.group, text = slotlabel, x = 85, y = data.height, width = 10, height = 20, fontSize = 12, align = "left" })
    objects.weapon.slot.anchorX = 0
    objects.weapon.slot.anchorY = 0
end

-- triggered when a player has fired or reloaded, to refresh the visuals
function updateWeaponHUD(event) 
    if globals.player.weapons then
        -- check if primary/secondary/mulekick has been added, removed or changed
        local hasPrimaryChanged = (globals.player.weapons.primary and not objects.primary) or (objects.primary and not globals.player.weapons.primary) or (objects.primary and globals.player.weapons.primary and objects.primary.id ~= globals.player.weapons.primary.id)
        local hasSecondaryChanged = (globals.player.weapons.secondary and not objects.secondary) or (objects.secondary and not globals.player.weapons.secondary) or (objects.secondary and globals.player.weapons.secondary and objects.secondary.id ~= globals.player.weapons.secondary.id)
        local hasMulekickChanged = (globals.player.weapons.mulekick and not objects.mulekick) or (objects.mulekick and not globals.player.weapons.mulekick) or (objects.mulekick and globals.player.weapons.mulekick and objects.mulekick.id ~= globals.player.weapons.mulekick.id)
        
        -- recreate the HUD under some circumstances
        if (hasPrimaryChanged or hasSecondaryChanged or hasMulekickChanged or event.name == "onPlayerWeaponSwitch") then
            destroyWeaponHUD()
            createWeaponHUD()
        end

        local current = globals.player.weapons.current
        objects.weapon.clip.text = globals.player.weapons[current].clip
        objects.weapon.reserve.text = globals.player.weapons[current].reserve

    end
end

local function createHUD()
    if not globals.player then
        print("Failed to create HUD as no player element found.")
    else
        createTopHUD()
        createWeaponHUD()
        Runtime:addEventListener("onPlayerWeaponFire", updateWeaponHUD)
        Runtime:addEventListener("onPlayerWeaponReload", updateWeaponHUD)
        Runtime:addEventListener("onPlayerWeaponSwitch", updateWeaponHUD)
        globals.player:addEventListener("onPlayerDamage", updateHealth)
        globals.player:addEventListener("onPlayerHeal", updateHealth)
        Runtime:addEventListener("onRoundUpdate", updateRound)
    end
end

local function destroyHUD()
    Runtime:removeEventListener("onPlayerWeaponFire", updateWeaponHUD)
    Runtime:removeEventListener("onPlayerWeaponReload", updateWeaponHUD)
    Runtime:removeEventListener("onPlayerWeaponSwitch", updateWeaponHUD)
    globals.player:removeEventListener("onPlayerDamage", updateHealth)
    globals.player:removeEventListener("onPlayerHeal", updateHealth)
    Runtime:removeEventListener("onRoundUpdate", updateRound)
    destroyTopHUD()
    destroyWeaponHUD()
    objects = {}
end

return {
    create = createHUD,
    destroy = destroyHUD,
}