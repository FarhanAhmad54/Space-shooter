function love.conf(t)
    t.identity = "StarfallVengeance"
    t.version = "11.5"

    t.window.title = "Starfall Vengeance"
    t.window.icon = "icon.png"
    t.window.width = 1280
    t.window.height = 720
    t.window.minwidth = 960
    t.window.minheight = 540
    t.window.resizable = true
    t.window.vsync = 1
    t.window.msaa = 4
    t.window.usedpiscale = true
    t.window.highdpi = true

    t.modules.audio = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = false
    t.modules.timer = true
    t.modules.touch = true
    t.modules.video = false
    t.modules.window = true
end
