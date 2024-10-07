-- composer prereqs
local composer = require("composer")
local scene = composer.newScene()

-- load modules
local mobile = require("scripts.modules.menu.mobile")

local function selectMenuOption(event)
    if event.option == "Play" then
        Runtime:removeEventListener("onPlayerMenuSelect", selectMenuOption) -- stop listening for menu select
        mobile.destroy()
        composer.removeScene("scripts.scenes.menu")
        composer.gotoScene("scripts.scenes.game")
    elseif event.option == "Settings" then
        -- blabla
    elseif event.option == "Credits" then
        -- blaba
    end
end

function scene:create(event)
    local group = self.view

    -- Code here runs when the scene is first created but has not yet appeared on screen
    mobile.create()

    -- capture when they click the menu
    Runtime:addEventListener("onPlayerMenuSelect", selectMenuOption)
end

function scene:show(event)
    local group = self.view

    if event.phase == "will" then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
    elseif event.phase == "did" then
        -- Code here runs when the scene is entirely on screen
        
    end
end

function scene:hide(event)
    local group = self.view

    if phase == "will" then
        -- Code here runs when the scene is on screen (but is about to go off screen)
    elseif phase == "did" then
        -- Code here runs immediately after the scene goes entirely off screen
    end
end

function scene:destroy(event)
    local group = self.view
    -- Code here runs prior to the removal of scene's view
end

-- event listeners for triggering the scene functions above
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)   
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene