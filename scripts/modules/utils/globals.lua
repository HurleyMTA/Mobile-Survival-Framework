-- store globals here!
local data = {}

data.platform = system.getInfo("platform")

data.maps = {
    forest = {
        path = "./assets/forest.jpg",
        width = 2048,
        height = 1536,
        scale = {
            android = 0.9,
            ios = 0.9,
            macos = 0.4,
            win32 = 0.4,
        },
        collisions = {
            { 0, 0, 66, 1536 },
            { 0, 0, 2048, 55 },
            { 1979, 0, 69, 1536},
            { 0, 1447, 2048, 89 },
            { 66, 1372, 96, 75 },
        },
        spawn = { 921, 736 },
        zm_spawn = { 126, 113, 1762, 1251 } -- spawn anywhere within this rect
    },
    beach = {
        path = "./assets/beach.jpg",
        width = 2048,
        height = 1536,
        scale = {
            android = 0.9,
            ios = 0.9,
            macos = 0.4,
            win32 = 0.4,
        },
        collisions = {
            { 0, 0, 2048, 421 },
            { 0, 1429, 2048, 107 },
        },
        spawn = { 997, 841 },
        zm_spawn = { 54, 467, 1908, 903 } 
    }
}

data.weapons = {
    [1] = {
        name = "AK-47",
        path = "./assets/weapons/ak47.png",
        type = "rifle",
        width = 500 * 0.2,
        height = 200 * 0.2,
        clip = 25, -- max clip ammo
        reserve = 300, -- max reserve ammo
        damage = 35, -- health per hit
        speed = 100, -- time between shots
        price = 1000,
    },
    [2] = {
        name = "Glock",
        path = "./assets/weapons/glock17.png",
        type = "handgun",
        width = 400 * 0.15,
        height = 300 * 0.15,
        clip = 17, -- max clip ammo
        reserve = 68, -- max reserve ammo
        damage = 10, -- health per hit
        speed = 250, -- time between shots
        price = 400,
    },
    [3] = {
        name = "M4",
        path = "./assets/weapons/m4a1.png",
        type = "rifle",
        width = 500 * 0.2,
        height = 200 * 0.2,
        clip = 30, -- max clip ammo
        reserve = 240, -- max reserve ammo
        damage = 25, -- health per hit
        speed = 80, -- time between shots
        price = 1200,
    },
    [4] = {
        name = "SCAR",
        path = "./assets/weapons/scar.png",
        type = "rifle",
        width = 500 * 0.2,
        height = 200 * 0.2,
        clip = 20, -- max clip ammo
        reserve = 200, -- max reserve ammo
        damage = 40, -- health per hit
        speed = 150, -- time between shots
        price = 1500,
    },
    [5] = {
        name = "FAMAS",
        path = "./assets/weapons/famas.png",
        type = "rifle",
        width = 500 * 0.2,
        height = 200 * 0.2,
        clip = 30, -- max clip ammo
        reserve = 240, -- max reserve ammo
        damage = 20, -- health per hit
        speed = 80, -- time between shots
        price = 1100,
    },
}

data.sheets = {
    soldier = {
        scale = {
            android = 0.5,
            ios = 0.5,
            macos = 0.25,
            win32 = 0.25,
        },
        frames = {
            width = 128,
            height = 128,
            numFrames = 160,
        },
        sequences = {
            { name = "handgun_idle", start = 1, count = 20, time = 2000, loopCount = 0, loopDirection = "forward" },
            { name = "handgun_move", start = 21, count = 20, time = 500, loopCount = 0, loopDirection = "forward" },
            { name = "handgun_reload", start = 41, count = 15, time = 1250, loopCount = 1, loopDirection = "forward" },
            { name = "handgun_shoot", start = 61, count = 3, time = 250, loopCount = 0, loopDirection = "forward" },
            { name = "rifle_idle", start = 81, count = 20, time = 2000, loopCount = 0, loopDirection = "forward" },
            { name = "rifle_move", start = 101, count = 20, time = 500, loopCount = 0, loopDirection = "forward" },
            { name = "rifle_reload", start = 121, count = 20, time = 1250, loopCount = 1, loopDirection = "forward" },
            { name = "rifle_shoot", start = 141, count = 3, time = 250, loopCount = 0, loopDirection = "forward" },
        },
    },
    zombie = {
        scale = {
            android = 0.4,
            ios = 0.4,
            macos = 0.2,
            win32 = 0.2,
        },
        frames = {
            width = 128,
            height = 128,
            numFrames = 34,
        },
        sequences = {
            { name = "zombie_move", start = 1, count = 17, time = 2000, loopCount = 0, loopDirection = "forward"  },
            { name = "zombie_attack", start = 18, count = 9, time = 2000, loopCount = 0, loopDirection = "forward" },
        },
    },
}

--RESERVED: data.player
--RESERVED: data.map
data.hostiles = {}

return data