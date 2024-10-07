local globals = require("scripts.modules.utils.globals")
local weapons = require("scripts.modules.gameplay.weapons")
local interface = require("scripts.modules.gameplay.interface")

local restockCost = 500 -- price of ammo restock
local objects = {} -- table for objects

local function hasMulekick()
    return true -- in case I add perks later
end

local function updateMoney(price)
    globals.player.points = globals.player.points - price
    objects.shop.points.text.text = "You have $" .. globals.player.points .. " to spend."
end

local function showConfirm(id, price)
    -- when pressing a button
    local function selectButton(event)
        if (event.phase == "ended" and objects.confirm) then
            -- weapon purchase
            if (objects.confirm.primary and event.target == objects.confirm.primary) then
                updateMoney(price)
                weapons.give(id, "primary")
            elseif (objects.confirm.secondary and event.target == objects.confirm.secondary) then
                updateMoney(price)
                weapons.give(id, "secondary")
            elseif (objects.confirm.mulekick and event.target == objects.confirm.mulekick) then
                updateMoney(price)
                weapons.give(id, "mulekick")
            end

            -- destroy confirm window
            objects.confirm.window:removeSelf()
            objects.confirm = nil
        end
    end

    -- start x, y
    local x = 10
    local y = 30

    -- table for all the confirm objects
    objects.confirm = {}

    -- window
    objects.confirm.window = interface.window(0, 0, 200, (hasMulekick() and 170 or 135), "Which weapon to replace?", true)
    
    -- primary btn
    objects.confirm.primary = interface.button(x, y, 180, 24, globals.weapons[globals.player.weapons.primary.id].name, objects.confirm.window)
    objects.confirm.primary:addEventListener("touch", selectButton)
    y = y + 34

    -- secondary btn
    objects.confirm.secondary = interface.button(x, y, 180, 24, globals.weapons[globals.player.weapons.secondary.id].name, objects.confirm.window)
    objects.confirm.secondary:addEventListener("touch", selectButton)
    y = y + 34
    
    -- mulekick btn
    if hasMulekick() then
        objects.confirm.mulekick = interface.button(x, y, 180, 24, globals.weapons[globals.player.weapons.mulekick.id].name, objects.confirm.window)
        objects.confirm.mulekick:addEventListener("touch", selectButton)
        y = y + 34
    end

    -- cancel btn
    objects.confirm.cancel = interface.button(x, y, 180, 24, "Cancel", objects.confirm.window)
    objects.confirm.cancel:addEventListener("touch", selectButton)
end

local function showShop(master)
    -- table to hold all shop objects
    objects.shop = {}
    
    -- create the interface objects
    local width, height = display.safeActualContentWidth - 40, display.safeActualContentHeight - 40
    objects.shop.window = interface.window(0, 0, width, height, "Shop", true)
    objects.shop.done = interface.button(10, height - 34, 120, 24, "Exit", objects.shop.window)
    objects.shop.buy = interface.button(width - 130, height - 34, 120, 24, "Buy", objects.shop.window)
    objects.shop.ammo = interface.button((width / 2) - 60, height - 34, 120, 24, "Restock Ammo ($" .. restockCost .. ")", objects.shop.window)
    objects.shop.notice = interface.label(20, 30, 200, 11, "Select an item to purchase in the shop.", "left", objects.shop.window)
    objects.shop.points = interface.label(width - 220, 30, 200, 11, "You have $" .. globals.player.points .. " to spend.", "right", objects.shop.window)
    
    -- 6 random weps
    local sale = {
        math.random(1, #globals.weapons),
        math.random(1, #globals.weapons),
        math.random(1, #globals.weapons),
        math.random(1, #globals.weapons),
        math.random(1, #globals.weapons),
        math.random(1, #globals.weapons),
    }

    -- when pressing a button
    local function selectButton(event)
        if not objects.confirm then
            if event.phase == "ended" then
                if event.target == objects.shop.done then
                    master:dispatchEvent({ name = "onRoundSummaryFinish" })
                    master:removeSelf()
                    master = nil
                    objects.shop.window:removeSelf()
                    objects.shop = nil
                elseif event.target == objects.shop.ammo then
                    if globals.player.points >= restockCost then
                        updateMoney(restockCost)
                        weapons.restock()
                    end
                elseif event.target == objects.shop.buy then
                    local selector = objects.shop.selector
                    if selector then
                        local price = globals.weapons[selector.target.id].price
                        if globals.player.points >= price then
                            if not globals.player.weapons.primary then -- spare primary slot?
                                updateMoney(price)
                                weapons.give(selector.target.id, "primary")
                            elseif not globals.player.weapons.secondary then -- spare secondary slot?
                                updateMoney(price)
                                weapons.give(selector.target.id, "secondary")
                            elseif not globals.player.weapons.mulekick and hasMulekick() then -- spare mulekick slot? if they have mulekick
                                updateMoney(price)
                                weapons.give(selector.target.id, "mulekick")
                            else
                                showConfirm(selector.target.id, price) -- otherwise replace an existing wep
                            end
                        end
                    end
                end
            end
        end
    end

    -- listeners for the buttons
    objects.shop.done:addEventListener("touch", selectButton)
    objects.shop.ammo:addEventListener("touch", selectButton)
    objects.shop.buy:addEventListener("touch", selectButton)

    -- when selecting a weapon
    local function selectWeapon(event)
        if not objects.confirm then
            if event.phase == "ended" then
                if objects.shop.selector then
                    objects.shop.selector:removeSelf()
                end
                objects.shop.selector = interface.rect(event.target.x - 10, event.target.y - 10, event.target.width + 20, event.target.height + 20, objects.shop.window)
                objects.shop.selector.target = event.target
            end
        end
    end

    -- padding
    local horizontalPadding = 30
    local verticalPadding = 80

    -- start x, y for weapons
    local x = (width / 2) - (globals.weapons[sale[1]].width / 2) - (globals.weapons[sale[2]].width / 2) - (globals.weapons[sale[3]].width / 2) - ((horizontalPadding * 3) / 2)
    local y = (height / 2) - (globals.weapons[sale[1]].height / 2) - (verticalPadding / 2)

    -- create the images
    for index = 1, #sale do
        local wep = globals.weapons[sale[index]]
        local button = interface.image(x, y, wep.width, wep.height, wep.path, wep.name .. " ($" .. wep.price .. ")", objects.shop.window)
        button.id = sale[index]
        button:addEventListener("touch", selectWeapon)

        -- adjust pos
        if index == 3 then
            x = (width / 2) - (globals.weapons[sale[4]].width / 2) - (globals.weapons[sale[5]].width / 2) - (globals.weapons[sale[6]].width / 2) - ((horizontalPadding * 3) / 2)
            y = y + verticalPadding
        else
            x = x + wep.width + horizontalPadding
        end
    end
end

return {
    show = showShop,
}
