local utils = require("scripts.modules.utils.utils")

local options = { "Play" }
local objects = {}

-- config
local GAME_TITLE = "Title"
local GAME_VERSION = "1.0.0"

-- function for handling player touching the screen
local selecting
local function touchDisplay(event)
    if event.phase == "began" then
        for index = 1, #options do
            local x, y = objects.options[index].background:localToContent(0, 0)
            if utils.isPointInsideRectangle(event.x, event.y, objects.group.x + objects.options[index].background.x, objects.group.y + objects.options[index].background.y, objects.options[index].background.width, objects.options[index].background.height) then
                objects.options[index].text.size = (objects.options[index].text.size + 2)
                objects.options[index].shadow.size = (objects.options[index].shadow.size + 2)
                selecting = index
            end
        end
    elseif event.phase == "ended" or event.phase == "cancelled" then
        if selecting then
            -- trigger select event
            if event.phase == "ended" then
                Runtime:dispatchEvent({ name = "onPlayerMenuSelect", option = options[selecting] })
            end

            -- revert text
            if objects.group then
                objects.options[selecting].text.size = (objects.options[selecting].text.size - 2)
                objects.options[selecting].shadow.size = (objects.options[selecting].shadow.size - 2)
            end
            selecting = nil
        end
    end
end

-- create the main menu
local function createMenu(scene)
    local x, y = display.screenOriginX, display.screenOriginY

    objects.group = display.newGroup()
    objects.group.anchorX = 0
    objects.group.anchorY = 0
    objects.group.x = x
    objects.group.y = y

    objects.wallpaper = display.newImageRect(objects.group, "./assets/wallpaper.jpg", display.actualContentWidth, display.actualContentHeight)
    objects.wallpaper.anchorX = 0
    objects.wallpaper.anchorY = 0

    x = x + 200
    y = y + 40

    local titleFont = native.newFont("./assets/stormgust.ttf", 40)

    objects.titleshadow = display.newText({ parent = objects.group, text = GAME_TITLE, x = x + 1, y = y + 1, width = 300, font = titleFont })
    objects.titleshadow.anchorX = 0
    objects.titleshadow.anchorY = 0
    objects.titleshadow:setFillColor(0)

    objects.title = display.newText({ parent = objects.group, text = GAME_TITLE, x = x, y = y, width = 300, font = titleFont })
    objects.title.anchorX = 0
    objects.title.anchorY = 0

    y = y + 45

    objects.versionshadow = display.newText({ parent = objects.group, text = "Version " .. GAME_VERSION, x = x + 1, y = y + 1, width = 200, fontSize = 9 })
    objects.versionshadow.anchorX = 0
    objects.versionshadow.anchorY = 0
    objects.versionshadow:setFillColor(0)

    objects.version = display.newText({ parent = objects.group, text = "Version " .. GAME_VERSION, x = x, y = y, width = 200, fontSize = 9 })
    objects.version.anchorX = 0
    objects.version.anchorY = 0

    objects.options = {}
    y = y + 70

    for index = 1, #options do
        objects.options[index] = {}

        objects.options[index].background = display.newRect(objects.group, x, y, 80, 20)
        objects.options[index].background.anchorX = 0
        objects.options[index].background.anchorY = 0
        objects.options[index].background:setFillColor(0, 0, 0, 0.5)

        objects.options[index].shadow = display.newText({ parent = objects.group, text = options[index], x = x + 1, y = y + 1, width = 80, font = native.systemFontBold, fontSize = 18 })
        objects.options[index].shadow.anchorX = 0
        objects.options[index].shadow.anchorY = 0
        objects.options[index].shadow:setFillColor(0)

        objects.options[index].text = display.newText({ parent = objects.group, text = options[index], x = x, y = y, width = 80, font = native.systemFontBold, fontSize = 18, align })
        objects.options[index].text.anchorX = 0
        objects.options[index].text.anchorY = 0

        y = y + 30
    end

    Runtime:addEventListener("touch", touchDisplay)

    return objects.group
end

local function destroyMenu()
    if objects.group then
        objects.group:removeSelf()
        objects = {}
        Runtime:removeEventListener("touch", touchDisplay)
    end
end

return {
    create = createMenu,
    destroy = destroyMenu,
}