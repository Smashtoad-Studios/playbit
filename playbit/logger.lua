local module = {}
playbit = playbit or {}
playbit.logger = module

module.LOGGER_LEVELS = {
    INFO = "INFO",
    WARNING = "WARNING",
    ERROR = "ERROR"
}

local enableInfoLogging = false
local enableWarningLogging = false
local enableErrorLogging = false

function module.setLoggerLevels(levelsToEnable)
    if levelsToEnable == nil then
        return
    end

    assert(type(levelsToEnable) == "table", "Logger levels need to be in a table")

    for i = 1, #levelsToEnable, 1 do
        if levelsToEnable[i] == module.LOGGER_LEVELS.INFO then
            enableInfoLogging = true
        elseif levelsToEnable[i] == module.LOGGER_LEVELS.WARNING then
            enableWarningLogging = true
        elseif levelsToEnable[i] == module.LOGGER_LEVELS.ERROR then
            enableErrorLogging = true
        end
    end
end

function module.printInfo(message)
    if not enableInfoLogging then
        return
    end

    print("[INFO] " .. message)
end

function module.printWarning(message)
    if not enableWarningLogging then
        return
    end

    print("[WARN] " .. message)
end

function module.printError(message)
    if not enableErrorLogging then
        return
    end
    print("[ERR] " .. message)
end