require("playbit/playdate/baseTimer")

class("timer").extends("baseTimer")

playdate.timer = timer

local timers = {}
local timersToRemove = {}

---Creates and automatically starts a new timer. Timers are stored as contiguous arrays for faster updates.
---@param duration Number of milliseconds the timer should run. 
function timer.new(duration, ...)
	@@ASSERT(type(duration) == "number", "[ERR] playdate.timer.new duration is not passed in or is a not number")

	local timer = timer(duration, ...)
	table.insert(timers, timer)

	return timer
end

function timer.updateTimers()
	timer.super.updateTimers(timers, timersToRemove)
end

---Convinence function for calling playdate.timer.new
---@param frameDelay the number of frames until the callbackFunction is called
---@param callbackFunction the function to call once this timer finishes
function timer.performAfterDelay(frameDelay, callbackFunction, ...)
	@@ASSERT(type(frameDelay) == "number", "[ERR] playdate.timer.performAfterDelay frameDelay parameter needs to be a number")
	@@ASSERT(type(callbackFunction) == "function" , "[ERR] playdate.timer.performAfterDelay callbackFunction parameter needs to be a function")
	
	return timer.new(frameDelay, callbackFunction, ...)
end

function timer.allTimers()
	return timers
end

function timer:remove()
	timer.super.remove(self)
	timersToRemove[#timersToRemove + 1] = self
end

---@return returns true if the timer advanced and was not delayed
function timer:advanceTimer()
	local dt = love.timer.getDelta() * 1000
	
	-- start delay
	if not self._remainingDelay then 
		--[[
		remainingDelay is intially sent to nil so delay can be 
		set after the timer is created without having to call reset() afterwards
		]]--
		self._remainingDelay = self.delay
	end
	
	if self._remainingDelay > 0 then
		self._remainingDelay = self._remainingDelay - dt
		return false
	end
		
	self._lastTime = self:getCurrentDuration()
    -- update timer
    self:setCurrentDuration(self:getCurrentDuration() + dt)
	return true
end

function timer:repeatTimer()
      local ct = self:getCurrentDuration()
      -- continue off from where the timer ended so there isn't a huge gap on first tick
      self:setCurrentDuration(ct - self.duration)
end

function timer.unitTest()
	local numFinished = 0

	local normalTimer
	local discardOnCompletionTimer
	local performAfterDelayTimer
	local timerToReset
	local timerToPause
	local timerOtherNew

	-- Test adding. Finishes 1st
	normalTimer = playdate.timer.new(100, function ()
		numFinished = numFinished + 1

		timerToPause:pause()

		@@ASSERT(numFinished == 1, "[ERR] playdate.timer.unitTest failed to finish at the correct time")
		@@ASSERT(#timers == 6, "[ERR] playdate.timer.unitTest timer callback timers were not removed correctly")
	end)
	@@ASSERT(normalTimer ~= nil, "[ERR] playdate.timer.unitTest failed to add timer \"timer\"")

	-- Test discardOnCompletion. Finishes 2nd
	discardOnCompletionTimer = playdate.timer.new(400, function ()
		numFinished = numFinished + 1

		timerToReset:reset()
		@@ASSERT(not timerToReset._hasReversed, "[ERR] playdate.timer.unitTest to failed to reset _hasReversed")
		@@ASSERT(timerToReset._remainingDelay == timerToReset.delay, "[ERR] playdate.timer.unitTest to failed to reset _remainingDelay")
		@@ASSERT(timerToReset.active, "[ERR] playdate.timer.unitTest to failed to reset active")
		@@ASSERT(timerToReset.startValue == timerToReset.originalValues.startValue, "[ERR] playdate.timer.unitTest to failed to reset startValue")
		@@ASSERT(timerToReset.endValue == timerToReset.originalValues.endValue, "[ERR] playdate.timer.unitTest to failed to reset endValue")
		@@ASSERT(timerToReset.easingFunction == timerToReset.originalValues.easingFunction, "[ERR] playdate.timer.unitTest to failed to reset easingFunction")
		@@ASSERT(timerToReset:getCurrentDuration() == 0, "[ERR] playdate.timer.unitTest to failed to reset currentDuration")
		@@ASSERT(timerToReset.value == timerToReset.startValue, "[ERR] playdate.timer.unitTest to failed to reset value")
		@@ASSERT(timerToReset._calledOnRepeat == nil, "[ERR] playdate.timer.unitTest to failed to reset value")
		
		@@ASSERT(numFinished == 2, "[ERR] playdate.timer.unitTest timers failed to finish in the correct order")
		@@ASSERT(#timers == 5, "[ERR] playdate.timer.unitTest discardOnCompletionTimer callback timers were not removed correctly")
  	end)
	discardOnCompletionTimer.discardOnCompletion = false
	@@ASSERT(discardOnCompletionTimer ~= nil, "[ERR] playdate.timer.unitTest failed to add timer \"discardOnCompletionTimer\"")

	-- Test perform after delay. Finished 3th
	performAfterDelayTimer = playdate.timer.performAfterDelay(500, function ()
		numFinished = numFinished + 1

		@@ASSERT(numFinished == 3, "[ERR] playdate.timer.unitTest timers failed to finish in the correct order")
		@@ASSERT(#timers == 5, "[ERR] playdate.timer.unitTest performAfterDelayTimer callback timers were not removed correctly")
  	end)
	@@ASSERT(performAfterDelayTimer ~= nil, "[ERR] playdate.timer.unitTest failed to add timer \"performAfterDelayTimer\"")
		
	local runningDuration = 0
	local duration = 600

	-- Test pausing. Finishes 4th
	timerOtherNew = playdate.timer.new(duration, 0, duration, playdate.easingFunctions.linear)
	@@ASSERT(timerOtherNew ~= nil, "[ERR] playdate.timer.unitTest failed to add timer \"timerOtherNew\"")

	timerOtherNew.updateCallback = function (timer)
        runningDuration = runningDuration + love.timer.getDelta() * 1000
		@@ASSERT(tostring(timer.value) == tostring(runningDuration), "[ERR] playdate.timer.unitTest timer \"timerOtherNew\" reporting incorrect timer.value")
    end
	
    timerOtherNew.timerEndedCallback = function ()
		numFinished = numFinished + 1

		@@ASSERT(timerOtherNew.value == timerOtherNew.endValue, "[ERR] playdate.timer.unitTest timer value is not correct in the timerEndedCallback")
		@@ASSERT(numFinished == 4, "[ERR] playdate.timer.unitTest timers failed to finish in the correct order")
		@@ASSERT(#timers == 4, "[ERR] playdate.timer.unitTest timerToPause callback timers were not removed correctly")
    end

	-- Test reseting. Finishes 5th
	timerToReset = playdate.timer.new(500, function ()
		numFinished = numFinished + 1

		timerToPause:start()

		-- This is the last timer to trigger the timer ended callback
		@@ASSERT(numFinished == 5, "[ERR] playdate.timer.unitTest timers failed to finish in the correct order")
		@@ASSERT(#timers == 3, "[ERR] playdate.timer.unitTest timerToReset callback timers were not removed correctly")
	  end)
	@@ASSERT(timerToReset ~= nil, "[ERR] playdate.timer.unitTest failed to add timer \"timerToReset\"")

	-- Test pausing. Finishes 6th
	timerToPause = playdate.timer.new(700, function ()
		numFinished = numFinished + 1

		@@ASSERT(numFinished == 6, "[ERR] playdate.timer.unitTest timers failed to finish in the correct order")
		@@ASSERT(#timers == 2, "[ERR] playdate.timer.unitTest timerToPause callback timers were not removed correctly")

		-- Clean up the discardOnCompletionTimer to make sure it gets removed
		discardOnCompletionTimer:remove()

		-- timerToPause should get added to the list of frame timers to remove then cleaned up as well
		playdate.timer.new(2, function ()
			numFinished = numFinished + 1

			@@ASSERT(numFinished == 7, "[ERR] playdate.timer.unitTest timers failed to finish in the correct order")
			@@ASSERT(#timers == 1, "[ERR] playdate.timer.unitTest timerToPause callback clean up timers were not removed correctly")
	  	end)
	  end)
	@@ASSERT(timerToPause ~= nil, "[ERR] playdate.timer.unitTest failed to add timer \"timerToPause\"")
end