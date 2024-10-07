local utils = require("scripts.modules.utils.utils")
local globals = require("scripts.modules.utils.globals")
local physics = require("physics")

local sounds = {}
local isReloading -- bool: is the player currently reloading
local firingTimer -- timer for firing function

local load_sounds = { 
    "handgun_fire", 
    "rifle_reload", 
    "empty_clip" 
}

-- get the animation sequence based on wep
local function getWeaponSequence(anim)
    if globals.player and globals.player.weapons then
        local slot = globals.player.weapons.current
        local id = globals.player.weapons[slot].id
        local type = globals.weapons[id].type
        return type .. "_" .. anim -- i.e., handgun_idle
    end
end

-- simple stop firing function
local function stopFiring()
    if firingTimer then
        timer.cancel(firingTimer)
        utils.setSpriteAnimation({ sprite = globals.player.sprite, sequence = getWeaponSequence("idle"), override = true })
        globals.player.muzzle:setFillColor(0, 0)
    end
end

local function firePlayerWeapon(event) -- e.g. Runtime:dispatchEvent({ name = "onControlsWeaponFire", method = "cursor", phase = "up" })
    if globals.player and globals.player.weapons and not isReloading then
        if event.phase == "down" then
            local slot = globals.player.weapons.current -- current weapon slot i.e. primary, secondary, mulekick
            local id = globals.player.weapons[slot].id -- current weapon id

            -- check clip
            if globals.player.weapons[slot].clip > 0 then
                -- animation and fire
                utils.setSpriteAnimation({ sprite = globals.player.sprite, sequence = getWeaponSequence("shoot") })
                local function fire(event)
                    -- update clip and trigger fire event
                    globals.player.weapons[slot].clip = globals.player.weapons[slot].clip - 1
                    Runtime:dispatchEvent({ name = "onPlayerWeaponFire" })
                    audio.play(sounds.handgun_fire)

                    -- handle the shot
                    local x, y, radians = utils.getMuzzlePosition(globals.player)
                    local hits = physics.rayCast(x, y, x + (display.actualContentWidth) * math.cos(radians), y + (display.actualContentWidth) * math.sin(radians), "sorted")
                    if hits then
                        local damage = globals.weapons[id].damage
                        for index = 1, #hits do
                            local object = hits[index].object
                            if object then
                                if object.type == "collision" then
                                    break
                                elseif object.type == "hostile" then
                                    -- trigger onPreHostileDamage so the hostile script can handle any health changes
                                    object.owner:dispatchEvent({ name = "onHostileDamage", damage = damage }) -- object.owner bc trigger against the hostile, not the collision
                                    
                                    -- reduce the damage for further hits
                                    damage = damage - 5
                                    if damage <= 0 then
                                        break -- break out if damage drops to 0
                                    end
                                end
                            end
                        end
                    end

                    -- muzzle flash
                    globals.player.muzzle:setFillColor(1, 1)
                    timer.performWithDelay(50, function()
                        globals.player.muzzle:setFillColor(0, 0)
                    end, 1)

                    -- cancel the firing if clip empty
                    if globals.player.weapons[slot].clip == 0 then
                        stopFiring()
                    end
                end
                firingTimer = timer.performWithDelay(globals.weapons[id].speed, fire, 0)
                fire()
            else
                audio.play(sounds.empty_clip)
            end
        elseif event.phase == "up" then
            -- cancel firing
            stopFiring()
        end
    end
end

local function reloadPlayerWeapon(event) -- e.g. Runtime:dispatchEvent({ name = "onControlsWeaponReload", method = "keyboard" })
    if globals.player and globals.player.weapons and not isReloading then
        local slot = globals.player.weapons.current -- primary, secondary or mulekick
        if globals.player.weapons[slot].reserve > 0 then
            -- stop spam reloading
            isReloading = true
            
            -- get data on current weapon
            local id = globals.player.weapons[slot].id -- current weapon id, for table lookup
            local required = (globals.weapons[id].clip - globals.player.weapons[slot].clip) -- how many rounds are needed to fill the clip

            -- proceed if reload is actually needed
            if required > 0 then
                -- cancel if currently firing
                stopFiring()

                local toLoad = 0
                if globals.player.weapons[slot].reserve < required then
                    toLoad = globals.player.weapons[slot].reserve -- not enough reserve to fill clip
                else
                    toLoad = required -- can fill clip
                end

                -- animation and sound
                utils.setSpriteAnimation({ sprite = globals.player.sprite, sequence = getWeaponSequence("reload") })
                audio.play(sounds.rifle_reload)

                -- update
                local function reload()
                    globals.player.weapons[slot].reserve = globals.player.weapons[slot].reserve - toLoad
                    globals.player.weapons[slot].clip = globals.player.weapons[slot].clip + toLoad
                    Runtime:dispatchEvent({ name = "onPlayerWeaponReload" })
                    isReloading = nil
                end
                timer.performWithDelay(1000, reload, 1) -- we need to consider speed cola here. also need to adjust the reload_fast sprite anim time to match
            else
                isReloading = nil
            end
        end
    end
end

local function fixWeapon(slot)
    -- update animation
    utils.setSpriteAnimation({ sprite = globals.player.sprite, sequence = getWeaponSequence("idle") })

    -- per wep
    local offsets = {
        handgun = { 40, 0, -5.6, -1.9 },
        rifle = { 40, 0, -7.2, -1.9 },
    }

    -- update muzzle
    local id = globals.player.weapons[slot].id
    local type = globals.weapons[id].type
    globals.player.muzzle.x = offsets[type][1]
    globals.player.muzzle.y = offsets[type][2]
    globals.player.muzzle.anchorX = offsets[type][3]
    globals.player.muzzle.anchorY = offsets[type][4]

    -- update laser pointer
    utils.updateLaserPointer(globals.player)
end

local function switchPlayerWeapon(event) -- e.g. Runtime:dispatchEvent({ name = "onControlsWeaponSwitch", method = "keyboard", bind = "weapon_switch_1" })
    if globals.player and globals.player.weapons and not isReloading then
        local slot = (event.bind == "weapon_switch_1" and "primary") or (event.bind == "weapon_switch_2" and "secondary") or (event.bind == "weapon_switch_3" and "mulekick")
        if slot then
            if globals.player.weapons.current ~= slot and globals.player.weapons[slot] then
                -- set weapon
                globals.player.weapons.current = slot

                -- event
                Runtime:dispatchEvent({ name = "onPlayerWeaponSwitch" })

                -- update animation
                fixWeapon(slot)
            end
        end
    end
end

local function restockAmmo()
    if globals.player.weapons.primary then
        local id = globals.player.weapons.primary.id
        globals.player.weapons.primary.clip = globals.weapons[id].clip
        globals.player.weapons.primary.reserve = globals.weapons[id].reserve
    end
    if globals.player.weapons.secondary then
        local id = globals.player.weapons.secondary.id
        globals.player.weapons.secondary.clip = globals.weapons[id].clip
        globals.player.weapons.secondary.reserve = globals.weapons[id].reserve
    end
    if globals.player.weapons.mulekick then
        local id = globals.player.weapons.mulekick.id
        globals.player.weapons.mulekick.clip = globals.weapons[id].clip
        globals.player.weapons.mulekick.reserve = globals.weapons[id].reserve
    end
end

local function givePlayerWeapon(id, slot)
    if globals.player and globals.weapons[id] then
        -- create weapons table if it doesn't exist
        if not globals.player.weapons then
            globals.player.weapons = {}
        end

        -- give the weapon
        globals.player.weapons[slot] = { id = id, clip = globals.weapons[id].clip, reserve = globals.weapons[id].reserve }
        globals.player.weapons.current = slot

        -- update animation
        fixWeapon(slot)
    end
end

local function enablePlayerFiring()
    if not globals.player then
        print("Failed to enable firing as no player element provided.")
    else
        Runtime:addEventListener("onControlsWeaponFire", firePlayerWeapon)
        Runtime:addEventListener("onControlsWeaponReload", reloadPlayerWeapon)
        Runtime:addEventListener("onControlsWeaponSwitch", switchPlayerWeapon)
        for index = 1, #load_sounds do
            sounds[load_sounds[index]] = audio.loadSound("./assets/sounds/" .. load_sounds[index] .. ".mp3")
        end
        audio.setVolume(0.03, { channel = 0 })
    end
end

local function disablePlayerFiring()
    Runtime:removeEventListener("onControlsWeaponFire", firePlayerWeapon)
    Runtime:removeEventListener("onControlsWeaponReload", reloadPlayerWeapon)
    Runtime:removeEventListener("onControlsWeaponSwitch", switchPlayerWeapon)
    for index = 1, #load_sounds do
        audio.dispose(sounds[load_sounds[index]])
        sounds[load_sounds[index]] = nil
    end
end

return {
   enable = enablePlayerFiring,
   disable = disablePlayerFiring,
   give = givePlayerWeapon,
   get = getWeapons,
   sequence = getWeaponSequence,
   stop = stopFiring,
   restock = restockAmmo,
}