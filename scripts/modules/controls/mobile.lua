local joystick = require("scripts.modules.controls.joystick")
local utils = require("scripts.modules.utils.utils")
local globals = require("scripts.modules.utils.globals")

local moveJoystick
local autoAimTimer
local fireObject
local reloadObject
local switchObject

local function fireWeapon(event)
    if event.phase == "began" or event.phase == "ended" or event.phase == "cancelled" then
        Runtime:dispatchEvent(
            {
                name = "onControlsWeaponFire",
                phase = (event.phase == "began" and "down" or "up"), -- up or down
                method = "touch",
            }
        )
    end
end

local function reloadWeapon(event)
    if event.phase == "ended" then
        Runtime:dispatchEvent(
            {
                name = "onControlsWeaponReload",
                method = "touch",
            }
        )
    end
end

local function switchWeapon(event)
    if event.phase == "ended" then
        local slot = globals.player.weapons.current
        local primary = (globals.player.weapons.primary and globals.weapons[globals.player.weapons.primary.id])
        local secondary = (globals.player.weapons.secondary and globals.weapons[globals.player.weapons.secondary.id])
        local mulekick = (globals.player.weapons.mulekick and globals.weapons[globals.player.weapons.mulekick.id])

        -- figure out the next slot
        local next
        if slot == "primary" then
            next = (secondary and "weapon_switch_2") or (mulekick and "weapon_switch_3")
        elseif slot == "secondary" then
            next = (mulekick and "weapon_switch_3") or (primary and "weapon_switch_1")
        elseif slot == "mulekick" then
            next = (primary and "weapon_switch_1") or (secondary and "weapon_switch_2")
        end
        if not next then
            return
        end
        
        -- trigger the event
        Runtime:dispatchEvent(
            {
                name = "onControlsWeaponSwitch",
                method = "touch",
                bind = next,
            }
        )
    end
end

local function enableMobileControls()
    local outerRadius = 40
    local innerRadius = 20
    local borderPadding = 20

    -- movement joystick
    moveJoystick = joystick.create(
        display.safeScreenOriginX + outerRadius + borderPadding, 
        display.safeScreenOriginY + display.safeActualContentHeight - outerRadius - borderPadding, 
        outerRadius, 
        innerRadius
    )

    -- firing button
    fireObject = display.newGroup()
    fireObject.x = display.safeScreenOriginX + display.safeActualContentWidth - outerRadius - borderPadding
    fireObject.y = display.safeScreenOriginY + display.safeActualContentHeight - outerRadius - borderPadding
    fireObject.button = display.newCircle(fireObject, 0, 0, 40)
    fireObject.button.fill = { 0, 0, 0, 0.01 }
    fireObject.button:addEventListener("touch", fireWeapon)
    fireObject.overlay = display.newImageRect(fireObject, "./assets/target.png", 85, 85)

    -- reload button
    reloadObject = display.newGroup()
    reloadObject.x = display.safeScreenOriginX + display.safeActualContentWidth - outerRadius - borderPadding
    reloadObject.y = display.safeScreenOriginY + display.safeActualContentHeight - outerRadius - borderPadding - 80
    reloadObject.button = display.newCircle(reloadObject, 0, 0, 30)
    reloadObject.button.fill = { 0, 0, 0, 0.01 }
    reloadObject.button:addEventListener("touch", reloadWeapon)
    reloadObject.overlay = display.newImageRect(reloadObject, "./assets/reload.png", 60, 60)

    -- switch button
    switchObject = display.newGroup()
    switchObject.x = display.safeScreenOriginX + display.safeActualContentWidth - outerRadius - borderPadding
    switchObject.y = display.safeScreenOriginY + display.safeActualContentHeight - outerRadius - borderPadding - 150
    switchObject.button = display.newCircle(switchObject, 0, 0, 30)
    switchObject.button.fill = { 0, 0, 0, 0.01 }
    switchObject.button:addEventListener("touch", switchWeapon)
    switchObject.overlay = display.newImageRect(switchObject, "./assets/switch.png", 60, 60)
    switchObject.overlay:setFillColor(0, 0, 0, 0.9)

    -- auto aiming for mobile
    autoAimTimer = timer.performWithDelay(10, function()
        if #globals.hostiles > 0 then
            -- find the nearest hostile
            local nearestHostile = { hostile = globals.hostiles[1], distance = 500 }
            for index = 1, #globals.hostiles do
                local distance = utils.calculateDistance(globals.player.x, globals.player.y, globals.hostiles[index].x, globals.hostiles[index].y)
                if distance < nearestHostile.distance then
                    nearestHostile = { 
                        hostile = globals.hostiles[index], 
                        distance = distance 
                    }
                end
            end

            -- dont auto aim if not close
            if nearestHostile.distance > (display.safeActualContentWidth / 2) then
                return
            end

            -- if they're not next to them, adjust aim
            if (nearestHostile.hostile and nearestHostile.hostile.collision and nearestHostile.distance > 20) then
                local x, y = globals.player.muzzle:localToContent(-50, 0)
                Runtime:dispatchEvent(
                    {
                        name = "onControlsRotatePlayer",
                        phase = "moved",
                        method = "auto",
                        degrees = utils.calculateDegrees(
                            x - globals.map.x, 
                            y - globals.map.y, 
                            nearestHostile.hostile.collision.x, 
                            nearestHostile.hostile.collision.y
                        ),
                    }
                )
            end
        end
    end, 0)
end

local function disableMobileControls()
    if moveJoystick then
        joystick.destroy(moveJoystick)
        moveJoystick = nil
    end
    if fireObject then
        fireObject.button:removeEventListener("touch", fireWeapon)
        fireObject:removeSelf()
        fireObject = nil
    end
    if reloadObject then
        reloadObject.button:removeEventListener("touch", reloadWeapon)
        reloadObject:removeSelf()
        reloadObject = nil
    end
    if switchObject then
        switchObject.button:removeEventListener("touch", switchWeapon)
        switchObject:removeSelf()
        switchObject = nil
    end
    if autoAimTimer then
        timer.cancel(autoAimTimer)
        autoAimTimer = nil
    end
end

return {
    enable = enableMobileControls,
    disable = disableMobileControls,
}