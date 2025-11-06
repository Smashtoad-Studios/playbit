function love.conf(t)
    -- TODO: only enable in debug mode
    t.console = true
    t.window.title = "Say When!"
    t.identity = "SayWhen"
    t.window.width = 400
    t.window.height = 240
    t.window.msaa = false
    t.window.usedpiscale = false
    t.window.vsync = true
    t.window.resizable = true
end