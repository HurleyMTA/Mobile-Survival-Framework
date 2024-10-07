local shop = require("scripts.modules.extras.shop")

local objects = {}

local function showRoundSummary()
    -- used for events, will be destroyed 
    objects.master = display.newGroup()
    
    -- summary table
    objects.summary = {}

    -- group for the splash screen
    objects.summary.group = display.newGroup()
    objects.summary.group.anchorX = 0
    objects.summary.group.anchorY = 0

    -- darken mask
    objects.summary.mask = display.newRect(objects.summary.group, display.screenOriginX, display.screenOriginY, display.actualContentWidth, display.actualContentHeight)
    objects.summary.mask.anchorX = 0
    objects.summary.mask.anchorY = 0
    objects.summary.mask:setFillColor(0, 0)
    
    -- blood overlay
    objects.summary.overlay = display.newImageRect(objects.summary.group, "./assets/blood.png", 1024, 797)
    objects.summary.overlay.anchorX = 0
    objects.summary.overlay.anchorY = 0
    objects.summary.overlay.x = -300
    objects.summary.overlay.y = -100
    objects.summary.overlay:setFillColor(1, 0)

    -- header text
    local headerFont = native.newFont("./assets/stormgust.ttf", 40)
    objects.summary.header = display.newText({ parent = objects.summary.group, text = "You survived", x = display.screenOriginX, y = display.screenOriginY + (display.actualContentHeight / 2) - 30, width = display.actualContentWidth, font = headerFont, align = "center" })
    objects.summary.header.anchorX = 0
    objects.summary.header.anchorY = 0
    objects.summary.header:setFillColor(1, 0)

    -- fade in the mask, overlay and header
    local fill = 0
    timer.performWithDelay(20, function()
        fill = fill + 0.01
        objects.summary.overlay:setFillColor(1, fill)
        objects.summary.header:setFillColor(1, fill)
        if fill < 0.7 then
            objects.summary.mask:setFillColor(0, fill)
        end
    end, 100)

    -- transition the header to the top
    timer.performWithDelay(2000, function()
        transition.to(objects.summary.header, { time = 2000, y = display.screenOriginY + 20 })
    end, 1)

    -- proceed to the shop
    timer.performWithDelay(4500, function()
        objects.summary.menu = display.newText({ parent = objects.summary.group, text = "Continue", x = display.screenOriginX, y = display.screenOriginY + display.actualContentHeight - 70, width = display.actualContentWidth, align = "center" })
        objects.summary.menu.anchorX = 0
        objects.summary.menu.anchorY = 0

        -- exit menu handler
        objects.summary.menu:addEventListener("touch", function(event)
            if event.phase == "ended" then
                objects.summary.group:removeSelf()
                objects.summary = nil
                shop.show(objects.master) -- pass objects.master as we'll dispatch the event against this
            end
        end)
    end, 1)

    -- send the group back
    return objects.master
end

return {
    show = showRoundSummary
}