-- https://love2d-community.github.io/love-api/#conf
-- Setting unused modules to false is encouraged when you release your game. It reduces startup time (slightly) and reduces memory usage (slightly).
function love.conf(t)
    -- (string) This flag determines the name of the save directory for your game. Note that you can only specify the name, not the location where it will be created: t.identity = "gabe_HL3" -- Correct t.identity = "c:/Users/gabe/HL3" -- Incorrect Alternatively love.filesystem.setIdentity can be used to set the save directory outside of the config file.
    t.identity = "SayWhen"
    -- (boolean) flag determines if game directory should be searched first then save directory (true) or otherwise (false)
    t.appendidentity = false
    -- (string) t.version should be a string, representing the version of LÖVE for which your game was made. It should be formatted as "X.Y.Z" where X is the major release number, Y the minor, and Z the patch level. It allows LÖVE to display a warning if it isn't compatible. Its default is the version of LÖVE running.
    t.version = "11.5"
    -- (boolean) Determines whether a console should be opened alongside the game window (Windows only) or not. Note: On OSX you can get console output by running LÖVE through the terminal.
    t.console = true
    -- (boolean) Sets whether the device accelerometer on iOS and Android should be exposed as a 3-axis Joystick. Disabling the accelerometer when it's not used may reduce CPU usage.
    t.accelerometerjoystick = true
    -- (boolean) Sets whether files are saved in external storage (true) or internal storage (false) on Android.
    t.externalstorage = false
    -- (boolean) Determines whether gamma-correct rendering is enabled, when the system supports it.
    t.gammacorrect = false

    ----- WINDOW -----
    -- Setting t.window = nil defers the window creation until love.window.setMode is first called in your code. Check settings.lua for more details.
    ------------------
    t.window = nil

    ----- MODULES -----
    t.modules.audio = true
    t.modules.event = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
    t.modules.thread = true
end