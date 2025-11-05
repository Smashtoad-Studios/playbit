class("baseTimer").extends()

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

---Set the next value of this timer based on the easing
---@param timer The timer to update the value.
local function updateTimerValue(timer)
	if timer.workingValues.startValue ~= timer.workingValues.endValue then
		timer.value = timer.workingValues.easingFunction(
			timer:getCurrentDuration(), 
			timer.workingValues.startValue, 
			timer.workingValues.endValue - timer.workingValues.startValue, 
			timer.duration, 
			timer.easingAmplitude, 
			timer.easingPeriod
		)
	else
		timer.value = timer.workingValues.endValue
	end
end

---Call the timerEndedCallback when this timer completes if one is set
---@param timer The timer to call the timerEndedCallback on.
local function completeTimer(timer)
	if not timer.timerEndedCallback then
		return
	end

	timer.value = timer.workingValues.endValue
	
	if timer.timerEndedArgs then
		timer.timerEndedCallback(table.unpack(timer.timerEndedArgs))
	else
		timer.timerEndedCallback(timer)
	end
end

function baseTimer:init(duration, ...)
	local args = {...}
	
	self._remainingDelay = nil 
	self.hasReversed = false

	self.duration = duration
	self:setCurrentDuration(0)
	self.active = true
	self.delay = 0
	self.paused = false
	self.reverses = false
	self.reverseEasingFunction = nil
	self.repeats = false
	self.discardOnCompletion = true
	self.easingAmplitude = nil
	self.easingPeriod = nil
	self.updateCallback = nil
	
	self.timerEndedCallback = nil
	self.startValue = 0
	self.endValue = 0
	self.easingFunction = playdate.easingFunctions.linear
	self.timerEndedArgs = nil
	
	if #args > 0 then
		-- function.self.new(duration, f, args)
		if type(args[1]) == "function" then
			self.timerEndedCallback = args[1]
			
			if #args > 1 then
				table.remove(args, 1)
				self.timerEndedArgs = args
			end
			
		-- playdate.frameTimer.new(duration, [startValue, endValue, [easingFunction]]
		else
			assert(type(args[1]) == "number", "[ERR] playdate.frameTimer.new a startValue callback must be passed in and must be a number")
			assert(type(args[2]) == "number", "[ERR] playdate.frameTimer.new a endValue callback must be passed in and must be a number")

			self.timerEndedCallback = nil
			
			self.startValue = args[1]
			self.endValue = args[2]
			self.easingFunction = (#args == 3 and type(args[3]) == "function") and args[3] or self.easingFunction
			self.timerEndedArgs = nil
		end
	end

	self.value = self.startValue
	self.workingValues = {
		startValue = self.startValue,
		endValue = self.endValue,
		easingFunction = self.easingFunction,
	}
end

---Creates and automatically starts a new timer. Timers are stored as contiguous arrays for faster updates.
---@param duration time or frames the timer should run. 
function baseTimer.new(duration, ...)
	error("[ERR] new must be implemented in the baseTimer subclass")
end

function baseTimer.updateTimers(timers, timersToRemove)
	for i = 1, #timers do
		local timer = timers[i]

		-- skip inactive timers and delayed timers
		if timer == nil or not timer.active or timer.paused or not timer:advanceTimer() then
			goto continue
		end

		if timer:getCurrentDuration() == nil then
			print("timer current duration is nil")
		end
		if timer.duration == nil then
			print("timer duration is nil")
		end
		if timer:getCurrentDuration() <= timer.duration then
			-- timer still running
			updateTimerValue(timer)
			updateTimer(timer)
			goto continue
		end
		
		-- timer complete
		if timer.reverses and not timer.hasReversed then
			-- reverse timer
			timer.workingValues.startValue = timer.endValue
			timer.workingValues.endValue = timer.startValue
			timer.value = timer.endValue
			timer:setCurrentDuration(0)
			timer._remainingDelay = timer.delay

			if timer.reverseEasingFunction then
				timer.workingValues.easingFunction = timer.reverseEasingFunction
			end

			-- so we don't reverse a second time (set repeats to true to do that)
			timer.hasReversed = true 

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
			timer:setCurrentDuration(0)
			timer.value = timer.workingValues.endValue

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

	local index
	for i = 1, #timersToRemove, 1 do
		index = table.indexOfElement(timers, timersToRemove[i])
		if index then 
			table.remove(timers, index)
		end
	end

	timersToRemove = {}
end

---Convinence function for calling baseTimer.new
---@param delay the time or number of frames until the callbackFunction is called
---@param callbackFunction the function to call once this timer finishes
function baseTimer.performAfterDelay(delay, callbackFunction, ...)
	error("[ERR] performAfterDelay must be implemented in the baseTimer subclass")
end

function baseTimer.allTimers()
	error("[ERR] allTimers must be implemented in the baseTimer subclass")
end

function baseTimer:pause()
	self.paused = true
end

function baseTimer:start()
	self.paused = false
end

function baseTimer:remove()
	self.active = false
end

function baseTimer:reset()
	self:setCurrentDuration(0)
	self.hasReversed = false
	self._remainingDelay = self.delay
	self.active = true
	self.workingValues.startValue = self.startValue
	self.workingValues.endValue = self.endValue
	self.workingValues.easingFunction = self.easingFunction
	self.value = self.startValue
	self._calledOnRepeat = nil
	self._lastTime = nil
end

function baseTimer:setCurrentDuration(duration)
	self.currentTime = duration
end

function baseTimer:getCurrentDuration(duration)
	return self.currentTime
end

function baseTimer:advanceTimer()
	error("[ERR] advanceTimer must be implemented in the baseTimer subclass")
end