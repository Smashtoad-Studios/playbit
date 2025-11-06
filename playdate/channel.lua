-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-sound.channel 

local module = {}
playdate.sound.channel = module

-- TODO how to make this private?
module.sources = {}
module.volume = 1.0

function module.new()
  error("[ERR] playdate.sound.channel.new() is not yet implemented.")
end

function module:remove()
  error("[ERR] playdate.sound.channel:getSize() is not yet implemented.")
end

function module:addEffect(effect)
  -- error("[ERR] playdate.sound.channel:addEffect() is not yet implemented.")
end

function module:removeEffect(effect)
  error("[ERR] playdate.sound.channel:removeEffect() is not yet implemented.")
end

function module:addSource(source)
  module.sources[#module.sources + 1] = source
end

function module:removeSource(source)
  error("[ERR] playdate.sound.channel:removeSource() is not yet implemented.")
end

function module:setVolume(volume)
  self.volume = volume
  for i=1, #self.sources do
    -- TODO this isn't quite right, but will maybe work for now
    self.sources[i]:setVolume(volume)
  end
end

function module:getVolume()
  return self.volume
end

function module:setPan(pan)
  error("[ERR] playdate.sound.channel:setPan() is not yet implemented.")
end

function module:setPanMod(signal)
  error("[ERR] playdate.sound.channel:setPanMod() is not yet implemented.")
end

function module:setVolumeMod(signal)
  error("[ERR] playdate.sound.channel:setVolumeMod() is not yet implemented.")
end

function module:getDryLevelSignal()
  error("[ERR] playdate.sound.channel:getDryLevelSignal() is not yet implemented.")
end

function module:getWetLevelSignal()
  error("[ERR] playdate.sound.channel:getWetLevelSignal() is not yet implemented.")
end