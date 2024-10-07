-- store binds in a static table for now, we'll make it so you can rebind via main menu later
local binds = { 
    w = "move_up",
    a = "move_left",
    s = "move_down",
    d = "move_right",
    r = "weapon_reload",
    ['1'] = "weapon_switch_1",
    ['2'] = "weapon_switch_2",
    ['3'] = "weapon_switch_3",
}

-- send the keyboard input to the controls event, for moving the payer
local function triggerKeyboard(event)
    Runtime:dispatchEvent(
        { 
            name = "onControlsMovePlayer", 
            phase = "moved",
            method = "keyboard",
            bind = binds[event.source.keyName], -- pass the bind, not the keyName
        }
    )
end

-- triggered when any key is pressed, so filter based on binds table
local held = {}
local function useKeyboard(event)
    if binds[event.keyName] then
        if (binds[event.keyName] == "move_up" or binds[event.keyName] == "move_left" or binds[event.keyName] == "move_down" or binds[event.keyName] == "move_right") then
            if event.phase == "down" then
                -- pressed
                held[event.keyName] = timer.performWithDelay(10, triggerKeyboard, 0)
                held[event.keyName].keyName = event.keyName
            elseif event.phase == "up" then
                -- released
                if held[event.keyName] then
                    timer.cancel(held[event.keyName])
                    held[event.keyName] = nil
                    Runtime:dispatchEvent({ name = "onControlsMovePlayer", phase = "ended", method = "keyboard" })
                end
            end
        elseif (binds[event.keyName] == "weapon_reload") then
            if event.phase == "up" then
                Runtime:dispatchEvent({ name = "onControlsWeaponReload", method = "keyboard" })
            end
        elseif (binds[event.keyName] == "weapon_switch_1" or binds[event.keyName] == "weapon_switch_2" or binds[event.keyName] == "weapon_switch_3") then
            if event.phase == "up" then
                Runtime:dispatchEvent({ name = "onControlsWeaponSwitch", method = "keyboard", bind = binds[event.keyName] })
            end
        end
    end
end

-- triggered when the cursor is moved on screen
local function useCursor(event)
    if event.type == "move" or event.type == "drag" then
        Runtime:dispatchEvent(
            {
                name = "onControlsRotatePlayer",
                phase = "moved",
                method = "cursor",
                x = event.x,
                y = event.y,
            }
        )
    elseif event.type == "down" or event.type == "up" then
        Runtime:dispatchEvent(
            {
                name = "onControlsWeaponFire",
                phase = event.type, -- up or down
                method = "cursor",
            }
        )
    end
end

-- for enabling kb controls i.e. keyboard.enable()
function enableKeyboardControls()
    Runtime:addEventListener("key", useKeyboard)
    Runtime:addEventListener("mouse", useCursor)
end

-- for disabling kb controls i.e. keyboard.disable() - use when switching away from game scene?
function disableKeyboardControls()
    Runtime:removeEventListener("key", useKeyboard)
    Runtime:removeEventListener("mouse", useCursor)
    for keyName, bind in pairs(binds) do
        if held[keyName] then
            timer.cancel(held[keyName])
            held[keyName] = nil
        end
    end
end

return {
    enable = enableKeyboardControls,
    disable = disableKeyboardControls,
}