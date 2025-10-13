-- docs: https://sdk.play.date/2.6.2/Inside%20Playdate.html#C-graphics.animator

-- TODO-Playbit: is this needed?
-- require("easing")

playdate.graphics = playdate.graphics or {}

local module = {}
playdate.graphics.animator = module

local meta = {}
meta.__index = meta
module.__index = meta

-- note: this function has 5 overloaded definitions as of 2.6.2. 
-- the parameters will first need to be interpreted, then passed off to an appropriate local function for processing.
-- playdate.graphics.animator.new(duration, startValue, endValue, [easingFunction, [startTimeOffset]])
-- playdate.graphics.animator.new(duration, lineSegment, [easingFunction, [startTimeOffset]])
-- TODO-Playbit: Need to fully implement animators
function module.new(duration, ...)
    -- TODO-Playbit: Why does table.pack not work here...
    local args = {n=select("#", ...), ...}
    print(args.n)

    print(args[1])
    print(args[2])

    @@ASSERT(args.n > 0, "[ERR] animator requires at least two parameters")
    

    local newAnimator = setmetatable({}, module.meta)

    -- TODO-Playbit: Need to parse all params
    -- this is some kind of geometry
    if type(args[1]) == "number" then
        -- there should be two number values
        if args[2] == nil or type(args[2] ~= "number") then
            error("[ERR] unsupported parameters to animator.")
        end
        newAnimator.type = "number"
        print("[ERR] animator for two number values is not implemented.")
    elseif type(args[1]) == "table" then
        -- there could be a single geometry object, or a start and end point
        if args[2] == nil then
            newAnimator.type = "geometry"
            print("[ERR] animator for geometry values besides a line segment is not implemented.")
        elseif type(args[2]) == "table" then
            newAnimator.type = "points"
            print("[ERR] animator for two point values is not implemented.")
        end
    else
        error("[ERR] unsupported second parameter to animator.")
    end

    print("[ERR] playdate.graphics.animator.new() is not yet implemented.")
    return newAnimator
end

function meta:currentValue()
    error("[ERR] playdate.graphics.animator:currentValue() is not yet implemented.")
end

function meta:valueAtTime(time)
    print("[ERR] playdate.graphics.animator:valueAtTime() is not yet implemented.")
    if self.type == "number" then
        return 0
    elseif self.type == "point" then
        return {x = 0, y = 0}
    else
        return {x1 = 0, y1 = 0, x2 = 0, y2 = 0}
    end
end

function meta:progress()
    error("[ERR] playdate.graphics.animator:progress() is not yet implemented.")
end

function meta:reset(duration)
    error("[ERR] playdate.graphics.animator:reset() is not yet implemented.")
end

function meta:ended()
    error("[ERR] playdate.graphics.animator:ended() is not yet implemented.")
end

module.easingAmplitude = nil
module.easingPeriod = nil
module.repeatCount = nil
module.reverses = nil