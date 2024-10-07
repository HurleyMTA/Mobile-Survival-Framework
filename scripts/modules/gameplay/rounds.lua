-- scene stuff
local composer = require("composer")

-- prereqs
local utils = require("scripts.modules.utils.utils")
local globals = require("scripts.modules.utils.globals")
local hostiles = require("scripts.modules.gameplay.hostiles")
local weapons = require("scripts.modules.gameplay.weapons")
local hud = require("scripts.modules.gameplay.hud")

-- controls
local keyboard = require("scripts.modules.controls.keyboard")
local mobile = require("scripts.modules.controls.mobile")

-- summary screens
local gamesummary = require("scripts.modules.extras.post-game")
local roundsummary = require("scripts.modules.extras.post-round")

-- hold vars
local spawn_timer

-- enabling/disabling controls
local function enableControls(disable)
    if disable then
        if utils.isMobile() then
            mobile.disable()
        else
            keyboard.disable()
        end
    else
        if utils.isMobile() then
            mobile.enable()
        else
            keyboard.enable()
        end
    end
end

-- show the game summary on death
local function showGameSummary()
    -- hud/weps
    hud.destroy()
    weapons.stop()

    -- controls
    enableControls(true) -- disable

    -- stop spawning
    if spawn_timer then
        timer.cancel(spawn_timer)
        spawn_timer = nil
    end

    -- show post-game summary
    local summary = gamesummary.show()
    local function handleGameSummaryFinish()
        composer.removeScene("scripts.scenes.game")
        composer.gotoScene("scripts.scenes.menu")
    end
    summary:addEventListener("onGameSummaryFinish", handleGameSummaryFinish)
end

-- show the round summary on round complete
local function showRoundSummary(round)
    -- do not allow death
    globals.player:removeEventListener("onPlayerDeath", showGameSummary)

    -- hud/weps
    hud.destroy()
    weapons.stop()

    -- controls
    enableControls(true) -- disable

    -- show post-round summary
    local summary = roundsummary.show()
    local function handleRoundSummaryFinish()
        hud.create()
        enableControls()
        startRound(round + 1)
    end
    summary:addEventListener("onRoundSummaryFinish", handleRoundSummaryFinish)
end

-- start round x
function startRound(round)
    round = round or 1

    -- allow death
    globals.player:addEventListener("onPlayerDeath", showGameSummary)

    -- adjustable per round stats
    local zombies = math.floor(7 * round * 1.2)                 -- TOTAL ZOMBIES IN ROUND
    local delay = math.max(200, (2200 - (round * 10 * 15)))     -- DELAY BETWEEN ZOMBIE SPAWNS (ms)
    local speed = 6                                             -- ZOMBIE MOVEMENT SPEED (PLAYER IS 6)
    local health = 100                                          -- ZOMBIE MAX HEALTH
    local damage = 50                                           -- ZOMBIE DAMAGE PER HIT
    local attackspeed = 2000                                    -- ZOMBIE ATTACK SPEED (ms)

    -- don't change (used for tracking)
    local remaining = zombies
    local alive = 0

    -- multiplier 
    local multiplier = 1 -- 1x, default
    local multiplier_timer

    -- update, as we're on a new round
    Runtime:dispatchEvent({ name = "onRoundUpdate", round = round, remaining = remaining })

    -- death handler
    local function onHostileDeath(event)
        globals.player.points = math.floor(globals.player.points + (80 * multiplier)) -- death pts
        Runtime:dispatchEvent({ name = "onRoundUpdate", round = round, remaining = (remaining + alive) })
        globals.player.stats.killed = globals.player.stats.killed + 1
        alive = alive - 1

        -- cancel any existing multiplier timer
        if multiplier_timer then
            timer.cancel(multiplier_timer)
            multiplier = multiplier + 0.2
        end

        -- set a new multiplier timer
        multiplier_timer = timer.performWithDelay(2000, function()
            multiplier = 1
            multiplier_timer = nil
        end, 1)

        -- end the round 
        if (remaining + alive) == 0 then
            if spawn_timer then
                timer.cancel(spawn_timer)
                spawn_timer = nil
            end
            globals.player.stats.survived = globals.player.stats.survived + 1
            showRoundSummary(round)
        end
    end

    -- damage handler
    local function onHostileDamage(event)
        globals.player.points = math.floor(globals.player.points + (10 * multiplier)) -- damage pts
        Runtime:dispatchEvent({ name = "onRoundUpdate", round = round, remaining = (remaining + alive) })
        globals.player.stats.dealt = globals.player.stats.dealt + event.damage
    end

    -- poll every 2 secs to spawn a zombie. do not go over the 24 limit, and cancel the timer when all have been spawned.
    spawn_timer = timer.performWithDelay(delay, function()
        if remaining > 0 then
            if (#globals.hostiles < 24) then
                local zombie = hostiles.create("zombie")
                zombie:addEventListener("onHostileDeath", onHostileDeath)
                zombie:addEventListener("onHostileDamage", onHostileDamage)
                remaining = remaining - 1
                alive = alive + 1
            end
        else
            timer.cancel(spawn_timer)
            spawn_timer = nil
        end
    end, 0)

    -- debug
    print("Round " .. round .. " started.")
end

return {
    start = startRound
}