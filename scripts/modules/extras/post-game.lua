local globals = require("scripts.modules.utils.globals")

local objects = {}

local function showDeathSummary()
    objects.summary = {}

    objects.summary.group = display.newGroup()
    objects.summary.group.anchorX = 0
    objects.summary.group.anchorY = 0

    objects.summary.mask = display.newRect(objects.summary.group, display.screenOriginX, display.screenOriginY, display.actualContentWidth, display.actualContentHeight)
    objects.summary.mask.anchorX = 0
    objects.summary.mask.anchorY = 0
    objects.summary.mask:setFillColor(0, 0)
    
    objects.summary.overlay = display.newImageRect(objects.summary.group, "./assets/blood.png", 1024, 797)
    objects.summary.overlay.anchorX = 0
    objects.summary.overlay.anchorY = 0
    objects.summary.overlay.x = -300
    objects.summary.overlay.y = -100
    objects.summary.overlay:setFillColor(1, 0)

    local headerFont = native.newFont("./assets/stormgust.ttf", 40)
    objects.summary.header = display.newText({ parent = objects.summary.group, text = "You have died", x = display.screenOriginX, y = display.screenOriginY + (display.actualContentHeight / 2) - 30, width = display.actualContentWidth, font = headerFont, align = "center" })
    objects.summary.header.anchorX = 0
    objects.summary.header.anchorY = 0
    objects.summary.header:setFillColor(1, 0)

    -- phase 1: fade in the mask, overlay and header
    local fill = 0
    timer.performWithDelay(20, function()
        fill = fill + 0.01
        objects.summary.overlay:setFillColor(1, fill)
        objects.summary.header:setFillColor(1, fill)
        if fill < 0.7 then
            objects.summary.mask:setFillColor(0, fill)
        end
    end, 100)

    -- phase 2: transition the header to the top
    timer.performWithDelay(2000, function()
        transition.to(objects.summary.header, { time = 2000, y = display.screenOriginY + 20 })
    end, 1)

    -- phase 3: fade in game stats
    local stats = { "Rounds Survived: " .. globals.player.stats.survived, "Damage Dealt: " .. globals.player.stats.dealt, "Zombies Killed: " .. globals.player.stats.killed }
    objects.stats = {}
    local rowHeight = 25

    for index = 0, (#stats - 1) do
        timer.performWithDelay(4000 + (index * 500), function()
            objects.stats[index] = display.newText({ parent = objects.summary.group, text = stats[index + 1], x = display.screenOriginX, y = display.screenOriginY + (display.actualContentHeight / 2) - (rowHeight * (#stats / 2)) + (index * rowHeight), width = display.actualContentWidth, align = "center" })
            objects.stats[index].anchorX = 0
            objects.stats[index].anchorY = 0
        end)
    end

    -- phase 4: return to main menu
    timer.performWithDelay(5500, function()
        objects.menu = display.newText({ parent = objects.summary.group, text = "Return to Menu", x = display.screenOriginX, y = display.screenOriginY + display.actualContentHeight - 70, width = display.actualContentWidth, align = "center" })
        objects.menu.anchorX = 0
        objects.menu.anchorY = 0

        -- exit menu handler
        objects.menu:addEventListener("touch", function(event)
            if event.phase == "ended" then
                objects.summary.group:dispatchEvent({ name = "onGameSummaryFinish" })
                objects.summary.group:removeSelf()
                objects.summary = nil
            end
        end)
    end, 1)

    -- send the group back
    return objects.summary.group
end

return {
    show = showDeathSummary,
}