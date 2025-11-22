local module = {}
playbit = playbit or {}
playbit.settings = module
module.settings = {}

local jsonParser = require("json.json")

-- Located in the project
local SETTINGS_DEFAULT_FILE_PATH = "playbit/defaultSettings.json"
-- Located in AppData
local SETTINGS_FILE_PATH = "playbit/settings.json"
local PDX_INFO_FILE_PATH = "pdxinfo.json"

local width, height, flags = love.window.getMode()

function module.loadSettings()
    local isDefaultSettingsUpdated = false
    local savedSettings, _ = love.filesystem.read(SETTINGS_FILE_PATH)

    if savedSettings then
        savedSettings = jsonParser.decode(savedSettings)
    end

    local defaultSettings, _ = love.filesystem.read(SETTINGS_DEFAULT_FILE_PATH)
    assert(defaultSettings, "playbit.settings.loadSettings default settings is nil. There should be a default settings file located: \"" .. SETTINGS_DEFAULT_FILE_PATH .. "\"")
    defaultSettings = jsonParser.decode(defaultSettings)

    -- If the settings file does not exist, read in the defaults
    if savedSettings == nil then
        savedSettings = defaultSettings
    else
        -- Add a default setting if the settings does not in the saved settings
        for key, value in pairs(defaultSettings) do
            if savedSettings[key] == nil then
                isDefaultSettingsUpdated = true
                savedSettings[key] = value
            end
        end
    end

    -- Add all settings
    for key, value in pairs(savedSettings) do
        module.settings[key] = value
    end

    -- Extract the directory path from the full file path (remove the file from the path)
    local directory = SETTINGS_FILE_PATH:match("(.*/)")

    -- If a directory is in the path, recursively create the directories if they do not exist
    if directory then
        love.filesystem.createDirectory(directory)
    end

    -- If the settings file does not exist save the defaults that were just read in
    if not love.filesystem.getInfo(SETTINGS_FILE_PATH) or isDefaultSettingsUpdated then
        module.saveSettings()
    end

    -- Load the PDX info file
    pdxInfo, _ = love.filesystem.read(PDX_INFO_FILE_PATH)
    assert(pdxInfo, "playbit.settings.loadSettings could not load the pdxInfo.json")
    pdxInfo = jsonParser.decode(pdxInfo)
end

function module.saveSettings()
    local success, message = love.filesystem.write(SETTINGS_FILE_PATH, jsonParser.encode(module.settings))
    assert(success, "Unable to write playbits settings: \"" .. SETTINGS_FILE_PATH .. "\"")
end

function module.setWindow()
    love.window.setTitle = pdxInfo.name

    playbit.logger.printInfo("fullscreen: " .. tostring(module.settings.fullscreen))
    playbit.logger.printInfo("fullscreentype: " .. tostring(module.settings.fullscreentype))
    playbit.logger.printInfo("vsync: " .. tostring(module.settings.vsync))
    playbit.logger.printInfo("msaa: " .. tostring(module.settings.msaa))
    playbit.logger.printInfo("stencil: " .. tostring(module.settings.stencil))
    playbit.logger.printInfo("depth: " .. tostring(module.settings.depth))
    playbit.logger.printInfo("resizable: " .. tostring(module.settings.resizable))
    playbit.logger.printInfo("borderless: " .. tostring(module.settings.borderless))
    playbit.logger.printInfo("centered: " .. tostring(module.settings.centered))
    playbit.logger.printInfo("display: " .. tostring(module.settings.display))
    playbit.logger.printInfo("minwidth: " .. tostring(module.settings.minwidth))
    playbit.logger.printInfo("minheight: " .. tostring(module.settings.minheight))
    playbit.logger.printInfo("highdpi: " .. tostring(module.settings.highdpi))
    playbit.logger.printInfo("x: " .. tostring(module.settings.x))
    playbit.logger.printInfo("y: " .. tostring(module.settings.y))
    playbit.logger.printInfo("usedpiscale: " .. tostring(module.settings.usedpiscale))

    local flags = {
        fullscreen = module.settings.fullscreen,
        fullscreentype = module.settings.fullscreentype,
        vsync = module.settings.vsync,
        msaa = module.settings.msaa,
        stencil = module.settings.stencil,
        depth = module.settings.depth,
        resizable = module.settings.resizable,
        borderless = module.settings.borderless,
        centered = module.settings.centered,
        display = module.settings.display,
        minwidth = module.settings.minwidth,
        minheight = module.settings.minheight,
        highdpi = module.settings.highdpi,
        x = module.settings.x,
        y = module.settings.y,
        usedpiscale = module.settings.usedpiscale
    }

    love.window.setMode(module.settings.width, module.settings.height, flags)
end

function module.setMode()
    local currentCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas()
    
    module.setWindow()

    -- Reapply the canvas
    love.graphics.setCanvas(currentCanvas)

    -- Update the graphics (canvas size, etc.)
    playbit.graphics.setCanvasSize()
end

function module.getWindowSize()
    return module.settings.width, module.settings.height
end

function module.setWindowSize(width, height)
    module.settings.width = width
    module.settings.height = height
end

function module.getFullscreen()
    return module.settings.fullscreen
end

function module.getDisplayIndex()
    return module.settings.display
end

function module.getFullscreenModes()
    local modes = love.window.getFullscreenModes(module.settings.display)

    -- Force Playdate native resolution
    modes[#modes+1] = {width = 400, height = 240}
    modes[#modes+1] = {width = 800, height = 480}

    table.sort(modes, function(a, b) return a.width*a.height < b.width*b.height end)

    return modes
end
