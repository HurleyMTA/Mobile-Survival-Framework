-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- prereqs
local composer = require("composer")
local physics = require("physics")

-- config
display.setDefault("isAnchorClamped", false)
system.activate("multitouch")
physics.start()
--physics.setDrawMode("hybrid")

-- android stuff
native.setProperty("androidSystemUiVisibility", "immersive")

-- send to main menu
composer.gotoScene("scripts.scenes.menu")
--composer.gotoScene("scripts.scenes.game")