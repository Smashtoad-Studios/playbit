-- docs: https://sdk.play.date/2.6.2/Inside%20Playdate.html#C-graphics.animator

-- TODO-Playbit: is this needed?
-- require("easing")

playdate.graphics = playdate.graphics or {}

local module = {}
playdate.graphics.animator = module

local meta = {}
meta.__index = meta
module.__index = meta

local function newNumberOrPointAnimator(type, startValue, endValue, easingFunction, startTimeOffset)
    local newAnimator = setmetatable({}, meta)
    newAnimator.type = type
    newAnimator.startTimeOffset = startTimeOffset or 0
    newAnimator.easingFunction = easingFunction or playdate.easingFunctions.linear
    newAnimator.startValue = startValue
    newAnimator.endValue = endValue
    newAnimator.change = endValue - startValue
    print("[WARN] animator for type '" .. type .. "' is not fully implemented.")
    return newAnimator
end

local function newGeometryAnimator(type, geom, easingFunction, startTimeOffset)
    local newAnimator = setmetatable({}, meta)
    newAnimator.type = type
    newAnimator.startTimeOffset = startTimeOffset or 0
    newAnimator.easingFunction = easingFunction or playdate.easingFunctions.linear
    newAnimator.geometry = geom
    print("[WARN] animator for type '" .. type .. "' is not fully implemented.")
    return newAnimator
end

local function newPartsAnimator(duration, parts, easingFunctions, startTimeOffset)
    error("[ERR] animator for polygon is not implemented.")
end


function module.new(duration, a, b, c, d)
    @@ASSERT(type(duration) == "number", "[ERR] animator requires a valid duration")
    @@ASSERT(a ~= nil, "[ERR] animator requires at least two parameters")

    local newAnimator = setmetatable({}, meta)
    if type(a) == "number" and type(b) == "number" then
        newAnimator = newNumberOrPointAnimator("number", a, b, c, d)
    elseif a.type == "point" and b.type == "point" then
        newAnimator = newNumberOrPointAnimator("point", a, b, c, d)
    elseif a.type == "lineSegment" then
        newAnimator = newGeometryAnimator("lineSegment", a, b, c)
    elseif a.type == "arc" then
        newAnimator = newGeometryAnimator("arc", a, b, c)
    elseif a.type == "polygon" then
        newAnimator = newGeometryAnimator("polygon", a, b, c)
    elseif type(a) == "table" and type(b) == "table" then
        newAnimator = newPartsAnimator(duration, a, b, c)
    else
        -- invalid parameters
        error("[ERR] invalid parameters to playdate.graphics.animator.new")
    end

    newAnimator.repeatCount = 0
    newAnimator.reverses = false
    newAnimator.easingPeriod = nil
    newAnimator.easingAmplitude = nil
    newAnimator.startTime = playdate.getCurrentTimeMilliseconds()
    newAnimator.duration = duration

    return newAnimator
end

function meta:currentValue()
    print("[WARN] playdate.graphics.animator:currentValue() is not yet implemented.")
    local elapsedTime = playdate.getCurrentTimeMilliseconds() - self.startTime
    return self:valueAtTime(elapsedTime)
end

function meta:valueAtTime(time)
    -- TODO-Playbit: check repeatCount and reverses
    if self.repeatCount < 0 then
        -- loop time around indefinitely
        time = time % self.duration
    end

    if self.type == "number" then
        return self.easingFunction(time, self.startValue, self.change, self.duration, self.easingAmplitude, self.easingPeriod)
    elseif self.type == "point" then
        local x = self.easingFunction(time, self.startValue.x, self.change.x, self.duration, self.easingAmplitude, self.easingPeriod)
        local y = self.easingFunction(time, self.startValue.y, self.change.y, self.duration, self.easingAmplitude, self.easingPeriod)
        return playdate.geometry.point.new(x, y)
    elseif self.type == "lineSegment" then
        local distance = self.easingFunction(time, 0, self.geometry:length(), self.duration, self.easingAmplitude, self.easingPeriod)
        return self.geometry:pointOnLine(distance, true)
    elseif self.type == "arc" then
        local distance = self.easingFunction(time, 0, self.geometry:length(), self.duration, self.easingAmplitude, self.easingPeriod)
        return self.geometry:pointOnArc(distance, true)
    else
        print("[WARN] playdate.graphics.animator:valueAtTime() is not yet implemented for animators of type: '" .. self.type .. "'")
        return {x = 0, y = 0}
    end
end

function meta:progress()
    error("[ERR] playdate.graphics.animator:progress() is not yet implemented.")
end

function meta:reset(duration)
    self.startTime = playdate.getCurrentTimeMilliseconds()
    if duration ~= nil then
        self.duration = duration
    end
end

function meta:ended()
    if self.repeatCount < 0 then
        return false
    end

    -- TODO there's more to it than this
    return playdate.getCurrentTimeMilliseconds() - self.startTime > self.duration
end

module.easingAmplitude = nil
module.easingPeriod = nil
module.repeatCount = nil
module.reverses = nil