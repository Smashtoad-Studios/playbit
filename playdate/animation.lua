-- docs: https://sdk.play.date/2.6.2/Inside%20Playdate.html#C-graphics.animation.loop

playdate.graphics.animation = playdate.graphics.animation or {}

local module = {}
playdate.graphics.animation.loop = module

local meta = {}
meta.__index = meta
module.__index = meta

local animationLoops = {}
setmetatable(animationLoops, {__mode = "v"})

function module.new(interval, imageTable, shouldLoop)
  local animation = setmetatable({}, meta)
  
  animation.startFrame = 1
  animation.endFrame = 1
  animation.frame = 1
  animation.step = 1
  animation.paused = false
  animation._elapsedTime = 0.0

  animation.interval = interval or 100
  animation._imageTable = imageTable
  animation.shouldLoop = shouldLoop

  if imageTable then
    animation.endFrame = imageTable:getLength()
  end

  table.insert(animationLoops, animation)

  return animation
end

function module.update()
  local deltaTimeMs = love.timer.getDelta() * 1000
  for i = 1, #animationLoops, 1 do
    local animLoop = animationLoops[i]
    if animLoop then
      if not animLoop.paused then
        animLoop._elapsedTime = animLoop._elapsedTime + deltaTimeMs

        if animLoop.frame < animLoop.startFrame then
          animLoop.frame = animLoop.startFrame
        end

        -- figure out how many full intervals have been passed since last update
        local intervalProgress = animLoop._elapsedTime / animLoop.interval
        local fullIntervals = math.floor(intervalProgress)

        -- reset the elapsed time, keeping the partial interval amount
        animLoop._elapsedTime = animLoop._elapsedTime - (fullIntervals * animLoop.interval)

        -- increment the frame by the number of full steps
        animLoop.frame = animLoop.frame + (fullIntervals * animLoop.step)

        -- check if the animation should loop
        if animLoop.frame > animLoop.endFrame then
          if animLoop.shouldLoop then
            animLoop.frame = animLoop.startFrame
          else
            -- just leave the frame at one over the max so we know it has finished
            animLoop.frame = animLoop.endFrame + 1
          end
        end
      end
    end
  end
end

function meta:image()
  return self._imageTable:getImage(math.max(math.min(self.frame, self.endFrame), self.startFrame))
end

function meta:setImageTable(it)
  self._imageTable = it
end

function meta:isValid()
  if self.shouldLoop then
    return true
  end

  -- TODO-Playbit: should it do greater than, or greater equal check?
  -- Need to compare to Playdate SDK
  if self.frame > self.endFrame then
    return false
  end

  return true
end

function meta:draw(x, y, flip)
  self._imageTable:drawImage(math.max(math.min(self.frame, self.endFrame), self.startFrame), x, y, flip)
end

-- docs: https://sdk.play.date/2.6.2/Inside%20Playdate.html#C-graphics.animation.blinker
local blinkerModule = {}
playdate.graphics.animation.blinker = blinkerModule

local blinkerMeta = {}
blinkerMeta.__index = blinkerMeta
blinkerModule.__index = blinkerMeta

function blinkerModule.new(onDuration, offDuration, loop, cycles, default)
  error("[ERR] playdate.graphics.animation.blinker.new() is not yet implemented.")
end

function blinkerModule.updateAll()
  error("[ERR] playdate.graphics.animation.blinker.updateAll() is not yet implemented.")
end

function blinkerMeta:update()
  error("[ERR] playdate.graphics.animation.blinker:update() is not yet implemented.")
end

function blinkerMeta:start(onDuration, offDuration, loop, cycles, default)
  error("[ERR] playdate.graphics.animation.blinker:start() is not yet implemented.")
end

function blinkerMeta:startLoop()
  error("[ERR] playdate.graphics.animation.blinker:startLoop() is not yet implemented.")
end

function blinkerMeta:stop()
  error("[ERR] playdate.graphics.animation.blinker:stop() is not yet implemented.")
end

function blinkerModule.stopAll()
  error("[ERR] playdate.graphics.animation.blinker.stopAll() is not yet implemented.")
end

function blinkerMeta:remove()
  error("[ERR] playdate.graphics.animation.blinker:remove() is not yet implemented.")
end