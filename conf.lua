function love.conf(t)
    t.identity = "StarfallVengeance" -- Unique name for save folder
    t.version = "11.5"               -- Target LÖVE runtime

    t.window.title = "Starfall Vengeance"
    t.window.icon = "icon.png"       -- Icon file path
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true        -- Let it resize on Android
    t.window.vsync = true
    t.window.fullscreen = false      -- Desktop default, Android will override usually
    t.window.usedpiscale = true      -- Important for high DPI mobile screens

    t.modules.touch = true           -- Enable touch module
    t.accelerometer = false          -- Disable if not used to save battery
    t.externalstorage = false        -- Set to true if you need external storage access
    t.modules.joystick = false
end
