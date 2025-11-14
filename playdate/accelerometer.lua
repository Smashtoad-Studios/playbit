-- docs: https://sdk.play.date/2.6.2/Inside%20Playdate.html#accelerometer

local running = false

playdate.startAccelerometer = playdate.startAccelerometer or function()
    running = true
    playbit.logger.printError("playdate.startAccelerometer() is not yet implemented.")
end

playdate.stopAccelerometer = playdate.stopAccelerometer or function()
    running = false
    playbit.logger.printError("playdate.stopAccelerometer() is not yet implemented.")
end

playdate.readAccelerometer = playdate.readAccelerometer or function()
    playbit.logger.printWarning("playdate.readAccelerometer() is not yet implemented.")
    return 0,1,0 --upright
end

playdate.accelerometerIsRunning = playdate.accelerometerIsRunning or function()
    -- playbit.logger.printError("playdate.accelerometerIsRunning() is not yet implemented.")
    return running
end

-- undocumented functions (not in the public SDK documentation)
playdate.getDeviceOrientation = playdate.getDeviceOrientation or function()
    error("[ERR] playdate.getDeviceOrientation() is not yet implemented.")
end

playdate.getPitchAndRoll = playdate.getPitchAndRoll or function()
    error("[ERR] playdate.getPitchAndRoll() is not yet implemented.")
end