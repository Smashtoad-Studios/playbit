require("playbit/playdate/baseTimer")

class("frameTimer").extends("baseTimer")

playdate.frameTimer = frameTimer

local timers = {}
local timersToRemove = {}

---Creates and automatically starts a new timer. Timers are stored as contiguous arrays for faster updates.
---@param duration Number of frames the timer should run. 
function frameTimer.new(numberOfFrames, ...)
	@@ASSERT(type(numberOfFrames) == "number", "[ERR] playdate.frameTimer.new numberOfFrames is not passed in or is a not number")
	
	local timer = frameTimer(numberOfFrames, ...)
	table.insert(timers, timer)

	return timer
end

function frameTimer.updateTimers()
	frameTimer.super.updateTimers(timers, timersToRemove)
end

---Convinence function for calling playdate.frameTimer.new
---@param frameDelay the number of frames until the callbackFunction is called
---@param callbackFunction the function to call once this timer finishes
function frameTimer.performAfterDelay(frameDelay, callbackFunction, ...)
	@@ASSERT(type(frameDelay) == "number", "[ERR] playdate.frameTimer.performAfterDelay frameDelay parameter needs to be a number")
	@@ASSERT(type(callbackFunction) == "function" , "[ERR] playdate.frameTimer.performAfterDelay callbackFunction parameter needs to be a function")
	
	return frameTimer.new(frameDelay, callbackFunction, ...)
end

function frameTimer.allTimers()
	return timers
end

function frameTimer:remove()
	frameTimer.super.remove(self)
	timersToRemove[#timersToRemove + 1] = self
end

function frameTimer:setCurrentDuration(duration)
	self.frame = duration
end

function frameTimer:getCurrentDuration(duration)
	return self.frame
end

---@return returns true if the timer advanced and was not delayed
function frameTimer:advanceTimer()
	-- start delay
	if not self._remainingDelay then 
		--[[
		remainingDelay is intially sent to nil so delay can be 
		set after the timer is created without having to call reset() afterwards
		]]--
		self._remainingDelay = self.delay
	end

	if self._remainingDelay > 0 then
		self._remainingDelay = self._remainingDelay - 1
		return false
	end

	self:setCurrentDuration(self:getCurrentDuration() + 1)
	return true
end

function frameTimer.unitTest()
	local numFinished = 0

	local frameTimer
	local discardOnCompletionTimer
	local performAfterDelayTimer
	local frameTimerToReset
	local frameTimerToPause
	local frameTimerOtherNew

	-- Test adding. Finishes 1st
	frameTimer = playdate.frameTimer.new(1, function ()
		numFinished = numFinished + 1

		frameTimerToPause:pause()

		@@ASSERT(numFinished == 1, "[ERR] playdate.frameTimer.unitTest failed to finish at the correct time")
		@@ASSERT(#timers == 6, "[ERR] playdate.frameTimer.unitTest frameTimer callback timers were not removed correctly")
	end)
	@@ASSERT(frameTimer ~= nil, "[ERR] playdate.frameTimer.unitTest failed to add timer \"frameTimer\"")

	-- Test discardOnCompletion. Finishes 2nd
	discardOnCompletionTimer = playdate.frameTimer.new(4, function ()
		numFinished = numFinished + 1

		frameTimerToReset:reset()
		@@ASSERT(not frameTimerToReset._hasReversed, "[ERR] playdate.frameTimer.unitTest to failed to reset _hasReversed")
		@@ASSERT(frameTimerToReset._remainingDelay == frameTimerToReset.delay, "[ERR] playdate.frameTimer.unitTest to failed to reset _remainingDelay")
		@@ASSERT(frameTimerToReset.active, "[ERR] playdate.frameTimer.unitTest to failed to reset active")
		@@ASSERT(frameTimerToReset.startValue == frameTimerToReset.originalValues.startValue, "[ERR] playdate.frameTimer.unitTest to failed to reset startValue")
		@@ASSERT(frameTimerToReset.endValue == frameTimerToReset.originalValues.endValue, "[ERR] playdate.frameTimer.unitTest to failed to reset endValue")
		@@ASSERT(frameTimerToReset.easingFunction == frameTimerToReset.originalValues.easingFunction, "[ERR] playdate.frameTimer.unitTest to failed to reset easingFunction")
		@@ASSERT(frameTimerToReset:getCurrentDuration() == 0, "[ERR] playdate.frameTimer.unitTest to failed to reset currentDuration")
		@@ASSERT(frameTimerToReset.value == frameTimerToReset.startValue, "[ERR] playdate.frameTimer.unitTest to failed to reset value")
		@@ASSERT(frameTimerToReset._calledOnRepeat == nil, "[ERR] playdate.frameTimer.unitTest to failed to reset value")
		
		@@ASSERT(numFinished == 2, "[ERR] playdate.frameTimer.unitTest timers failed to finish in the correct order")
		@@ASSERT(#timers == 5, "[ERR] playdate.frameTimer.unitTest discardOnCompletionTimer callback timers were not removed correctly")
  	end)
	discardOnCompletionTimer.discardOnCompletion = false
	@@ASSERT(discardOnCompletionTimer ~= nil, "[ERR] playdate.frameTimer.unitTest failed to add timer \"discardOnCompletionTimer\"")

	-- Test perform after delay. Finished 3th
	performAfterDelayTimer = playdate.frameTimer.performAfterDelay(5, function ()
		numFinished = numFinished + 1

		@@ASSERT(numFinished == 3, "[ERR] playdate.frameTimer.unitTest timers failed to finish in the correct order")
		@@ASSERT(#timers == 5, "[ERR] playdate.frameTimer.unitTest performAfterDelayTimer callback timers were not removed correctly")
  	end)
	@@ASSERT(performAfterDelayTimer ~= nil, "[ERR] playdate.frameTimer.unitTest failed to add timer \"performAfterDelayTimer\"")
		
	local numOtherNewUpdate = 0
	local otherNewDuration = 6

	-- Test pausing. Finishes 4th
	frameTimerOtherNew = playdate.frameTimer.new(otherNewDuration, 0, otherNewDuration, playdate.easingFunctions.linear)
	@@ASSERT(frameTimerOtherNew ~= nil, "[ERR] playdate.frameTimer.unitTest failed to add timer \"frameTimerOtherNew\"")

	frameTimerOtherNew.updateCallback = function (timer)
        numOtherNewUpdate = numOtherNewUpdate + 1

		@@ASSERT(timer.value == numOtherNewUpdate, "[ERR] playdate.frameTimer.unitTest timer \"frameTimerOtherNew\" reporting incorrect timer.value")
    end
	
    frameTimerOtherNew.timerEndedCallback = function ()
		numFinished = numFinished + 1
		
		@@ASSERT(frameTimerOtherNew.value == otherNewDuration, "[ERR] playdate.frameTimer.unitTest frame timer value is not correct in the timerEndedCallback")
		@@ASSERT(numOtherNewUpdate == otherNewDuration, "[ERR] playdate.frameTimer.unitTest frame timer did not run for the current ammount of frames")
		@@ASSERT(numFinished == 4, "[ERR] playdate.frameTimer.unitTest timers failed to finish in the correct order")
		@@ASSERT(#timers == 4, "[ERR] playdate.frameTimer.unitTest frameTimerToPause callback timers were not removed correctly")
    end

	-- Test reseting. Finishes 5th
	frameTimerToReset = playdate.frameTimer.new(5, function ()
		numFinished = numFinished + 1

		frameTimerToPause:start()

		-- This is the last timer to trigger the timer ended callback
		@@ASSERT(numFinished == 5, "[ERR] playdate.frameTimer.unitTest timers failed to finish in the correct order")
		@@ASSERT(#timers == 3, "[ERR] playdate.frameTimer.unitTest frameTimerToReset callback timers were not removed correctly")
	  end)
	@@ASSERT(frameTimerToReset ~= nil, "[ERR] playdate.frameTimer.unitTest failed to add timer \"frameTimerToReset\"")

	-- Test pausing. Finishes 6th
	frameTimerToPause = playdate.frameTimer.new(7, function ()
		numFinished = numFinished + 1

		@@ASSERT(numFinished == 6, "[ERR] playdate.frameTimer.unitTest timers failed to finish in the correct order")
		@@ASSERT(#timers == 2, "[ERR] playdate.frameTimer.unitTest frameTimerToPause callback timers were not removed correctly")

		-- Clean up the discardOnCompletionTimer to make sure it gets removed
		discardOnCompletionTimer:remove()

		-- frameTimerToPause should get added to the list of frame timers to remove then cleaned up as well
		playdate.frameTimer.new(2, function ()
			numFinished = numFinished + 1

			@@ASSERT(numFinished == 7, "[ERR] playdate.frameTimer.unitTest timers failed to finish in the correct order")
			@@ASSERT(#timers == 1, "[ERR] playdate.frameTimer.unitTest frameTimerToPause callback clean up timers were not removed correctly")
	  	end)
	  end)
	@@ASSERT(frameTimerToPause ~= nil, "[ERR] playdate.frameTimer.unitTest failed to add timer \"frameTimerToPause\"")
end