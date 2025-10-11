local module = {}
playdate.frameTimer = module

local meta = {}
meta.__index = meta
module.__index = meta

local timers = {}
local timersToRemove = {}
local timersLookUp = {}

---Call the update callback set for this timer
---@param timer The timer to call the updateCallback on.
local function updateTimer(timer)
	if not timer.updateCallback then
		return
	end

	if timer.timerEndedArgs then
		timer.updateCallback(table.unpack(timer.timerEndedArgs))
	else
		timer.updateCallback(timer)
	end
end

---Set the next value of this frame timer based on the easing
---@param timer The timer to update the value.
local function updateTimerValue(timer)
	if timer.startValue ~= timer.endValue and timer.currentFrame ~= 0 then
		timer.value = timer.easingFunction(
			timer.currentFrame, 
			timer.startValue, 
			timer.endValue - timer.startValue, 
			timer.numberOfFrames, 
			timer.easingAmplitude, 
			timer.easingPeriod
		)
	else
		timer.value = timer.endValue
	end
end

---Call the timerEndedCallback when this frame timer completes if one is set
---@param timer The timer to call the timerEndedCallback on.
local function completeTimer(timer)
	if not timer.timerEndedCallback then
		return
	end
	
	if timer.timerEndedArgs then
		timer.timerEndedCallback(table.unpack(timer.timerEndedArgs))
	else
		timer.timerEndedCallback(timer)
	end
end

---Creates and automatically starts a new timer. Timers are stored as contiguous arrays for faster updates.
---@param duration Number of frames the timer should run. 
function module.new(numberOfFrames, ...)
	@@ASSERT(type(numberOfFrames) == "number", "[ERR] playdate.frameTimer.new numberOfFrames is not passed in or is a number")

	local args = {...}
	local frameTimer = setmetatable({}, meta)

	frameTimer._remainingDelay = nil 
	frameTimer._hasReversed = false

	frameTimer.currentFrame = 0
	frameTimer.numberOfFrames = numberOfFrames
	frameTimer.active = true
	frameTimer.delay = 0
	frameTimer.paused = false
	frameTimer.reverses = false
	frameTimer.reverseEasingFunction = nil
	frameTimer.repeats = false
	frameTimer.discardOnCompletion = true
	frameTimer.easingAmplitude = nil
	frameTimer.easingPeriod = nil
	frameTimer.updateCallback = nil
	
	frameTimer.timerEndedCallback = nil
	frameTimer.startValue = 0
	frameTimer.endValue = 0
	frameTimer.easingFunction = playdate.easingFunctions.linear
	frameTimer.timerEndedArgs = nil
	
	if #args > 0 then
		-- function.frameTimer.new(duration, f, args)
		if type(args[1]) == "function" then
			frameTimer.timerEndedCallback = args[1]
			
			if #args > 1 then
				table.remove(args, 1)
				frameTimer.timerEndedArgs = args
			end
			
		-- playdate.frameTimer.new(duration, [startValue, endValue, [easingFunction]]
		else
			@@ASSERT(type(args[1]) == "number", "[ERR] playdate.frameTimer.new a startValue callback must be passed in and must be a number")
			@@ASSERT(type(args[2]) == "number", "[ERR] playdate.frameTimer.new a endValue callback must be passed in and must be a number")

			frameTimer.timerEndedCallback = nil
			
			frameTimer.startValue = args[1]
			frameTimer.endValue = args[2]
			frameTimer.easingFunction = (#args == 3 and type(args[3]) == "function") and args[3] or frameTimer.easingFunction
			frameTimer.timerEndedArgs = nil
		end
	end

	frameTimer.value = frameTimer.startValue
	frameTimer.originalValues = {}
	frameTimer.originalValues.startValue = frameTimer.startValue
	frameTimer.originalValues.endValue = frameTimer.endValue
	frameTimer.originalValues.easingFunction = frameTimer.easingFunction

	table.insert(timers, frameTimer)
	timersLookUp[frameTimer] = #timers

	return frameTimer
end

---Convinence function for calling playdate.frameTimer.new
---@param frameDelay the number of frames until the callbackFunction is called
---@param callbackFunction the function to call once this timer finishes
function module.performAfterDelay(frameDelay, callbackFunction, ...)
	@@ASSERT(type(frameDelay) == "number", "[ERR] playdate.frameTimer.performAfterDelay frameDelay parameter needs to be a number")
	@@ASSERT(type(callbackFunction) == "function" , "[ERR] playdate.frameTimer.performAfterDelay callbackFunction parameter needs to be a function")
	
	return module.new(frameDelay, callbackFunction, ...)
end

function meta:pause()
	self.paused = true
end

function meta:start()
	self.paused = false
end

function meta:remove()
	self.active = false
	timersToRemove[#timersToRemove + 1] = self
end

function meta:reset()
	self._hasReversed = false
	self._remainingDelay = self.delay
	self.active = true
	self.startValue = self.originalValues.startValue
	self.endValue = self.originalValues.endValue
	self.easingFunction = self.originalValues.easingFunction
	self.currentFrame = 0
	self.value = self.startValue
	self._calledOnRepeat = nil
end

function module.updateTimers()
	for i = 1, #timers do
		local timer = timers[i]

		if not timer.active or timer.paused then
			-- skip inactive timers
			goto continue
		end

		-- start delay
		if not timer._remainingDelay then 
			--[[
			remainingDelay is intially sent to nil so delay can be 
			set after the timer is created without having to call reset() afterwards
			]]--
			timer._remainingDelay = timer.delay
		end

		if timer._remainingDelay > 0 then
			timer._remainingDelay = timer._remainingDelay - dt
			goto continue
		end

		-- update timer
		timer.currentFrame = timer.currentFrame + 1

		if timer.currentFrame <= timer.numberOfFrames then
			-- timer still running
			updateTimerValue(timer)
			updateTimer(timer)
			goto continue
		end
		
		-- timer complete
		if timer.reverses and not timer._hasReversed then
			-- reverse timer
			local temp = timer.startValue
			timer.startValue = timer.endValue
			timer.endValue = temp
			timer.currentFrame = timer.numberOfFrames
			timer._remainingDelay = timer.delay

			if timer.reverseEasingFunction then
				timer.easingFunction = timer.reverseEasingFunction
			end

			-- so we don't reverse a second time (set repeats to true to do that)
			timer._hasReversed = true 

		-- repeat timer
		elseif timer.repeats then
			completeTimer(timer)

			timer:reset()
			-- record that the callback was invoked while repeating
			timer._calledOnRepeat = true 

			updateTimerValue(timer)
			updateTimer(timer)

		-- complete timer
		else
			timer.active = false
			timer.currentFrame = 0
			timer.value = timer.endValue

			-- when .repeats is true, then set to false, we shouldn't ever invoke the callback again
			if not timer._calledOnRepeat then
				completeTimer(timer)
			end

			if timer.discardOnCompletion then
				timer:remove()
			end
		end
		
		::continue::
	end

	for i = 1, #timersToRemove, 1 do
		local index = timersLookUp[timersToRemove[i]]

    	if index then
			-- Swap with last element for fast removal
			local last = #timers

			if index ~= last then
				timers[index] = timers[last]
				timersLookUp[timers[index]] = index
			end

			timers[last] = nil
			timersLookUp[timersToRemove[i]] = nil
		end

		timersToRemove[i] = nil
	end
end

function module.allTimers()
	return timers
end

function module.unitTest()
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
		@@ASSERT(frameTimerToReset.currentFrame == 0, "[ERR] playdate.frameTimer.unitTest to failed to reset numberOfFrames")
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
		-- Timers that exist at this point are paused, do not discardOnCompletion, this one. and reset
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

		@@ASSERT(timer.value == numOtherNewUpdate/otherNewDuration, "[ERR] playdate.frameTimer.unitTest timer \"frameTimerOtherNew\" reporting incorrect timer.value")
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
	@@ASSERT(frameTimerToReset ~= nil, "[ERR] playdate.frameTimer.unitTest failed to add timer \"frameTimerToPause\"")
end