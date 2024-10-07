-- composer
local composer = require("composer")
local scene = composer.newScene()

-- utils
local utils = require("scripts.modules.utils.utils")
local globals = require("scripts.modules.utils.globals")

-- controls
local keyboard = require("scripts.modules.controls.keyboard")
local mobile = require("scripts.modules.controls.mobile")

-- gameplay
local hostiles = require("scripts.modules.gameplay.hostiles")
local maps = require("scripts.modules.gameplay.maps")
local player = require("scripts.modules.gameplay.player")
local weapons = require("scripts.modules.gameplay.weapons")
local hud = require("scripts.modules.gameplay.hud")
local rounds = require("scripts.modules.gameplay.rounds")

-- Code here runs when the scene is first created but has not yet appeared on screen
function scene:create(event)
    local group = self.view
    
    -- create the map and player
    maps.create("beach")
    player.create("soldier")
    weapons.enable()
    weapons.give(2, "primary")
    hud.create()

    -- controls
    if utils.isMobile() then
        mobile.enable()
    else
        keyboard.enable()
    end

    -- begin
    rounds.start()
end

-- Code here runs prior to the removal of scene's view
function scene:destroy(event)
    local group = self.view
    hostiles.clear()
    player.destroy()
    weapons.disable()
    maps.destroy()
end

-- event listeners for triggering the scene functions above
scene:addEventListener("create", scene)
scene:addEventListener("destroy", scene)

return scene