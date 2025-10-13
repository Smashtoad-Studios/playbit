-- docs: https://sdk.play.date/2.6.2/Inside%20Playdate.html#M-sound

playdate.sound = {}

local sampleplayer = {}
playdate.sound.sampleplayer = sampleplayer
sampleplayer.meta = {}
sampleplayer.meta.__index = sampleplayer.meta

function sampleplayer.new(path)
  local sample = setmetatable({}, sampleplayer.meta)
  local fileExtLoc, _ = string.find(path, "%.wav")
  if not fileExtLoc then
    path = path..".wav"
  end
  sample.data = love.audio.newSource(path, "static")
  return sample
end

function sampleplayer.meta:copy()
  local sample = setmetatable({}, sampleplayer.meta)
  sample.data = self.data:clone()
  return sample
end

function sampleplayer.meta:play(repeatCount, rate)
  -- TODO: repeat count
  if rate then
    self.data:setPitch(rate)
  end

  if repeatCount then
    -- TODO: specific repeat count
    if repeatCount == 0 then
      -- loop endlessly
      self.data:setLooping(true)
    end
  end

  self.data:play()
end

function sampleplayer.meta:stop()
  self.data:stop()
end

function sampleplayer.meta:isPlaying()
  return self.data:isPlaying()
end

function sampleplayer.meta:setVolume(value)
  self.data:setVolume(value)
end

function sampleplayer.meta:getVolume()
  return self.data:getVolume()
end

function sampleplayer.meta:setOffset(value)
  self.data:seek(value)
end

function sampleplayer.meta:getOffset()
  return self.data:tell()
end

function sampleplayer.meta:setRate(rate)
  self.data:setPitch(rate)
end

function sampleplayer.meta:getRate()
  self.data:getPitch()
end

local fileplayer = {}
playdate.sound.fileplayer = fileplayer
fileplayer.meta = {}
fileplayer.meta.__index = fileplayer.meta

function fileplayer.new(path, bufferSize)
  -- TODO: is there a way to use bufferSize to control Love2D chunks?
  local sample = setmetatable({}, fileplayer.meta)
  sample.data = love.audio.newSource(path..".wav", "stream")
  return sample
end

function fileplayer.meta:play(repeatCount)
  if repeatCount then
    -- TODO: specific repeat count
    if repeatCount == 0 then
      -- loop endlessly
      self.data:setLooping(true)
    end
  end

  self.data:play()
end

function fileplayer.meta:stop()
  self.data:stop()
end

function fileplayer.meta:pause(value)
  self.data:pause()
end

function fileplayer.meta:isPlaying()
  return self.data:isPlaying()
end

function fileplayer.meta:setVolume(value)
  self.data:setVolume(value)
end

function fileplayer.meta:getVolume()
  return self.data:getVolume()
end

function fileplayer.meta:setRate(rate)
  self.data:setPitch(rate)
end

function fileplayer.meta:getRate(rate)
  self.data:getPitch()
end

function fileplayer.meta:setOffset(value)
  self.data:seek(value)
end

function fileplayer.meta:getOffset()
  return self.data:tell()
end

function fileplayer.meta:getLength()
  return self.data:getDuration("seconds")
end

-- TODO: fileplayer
-- TODO: synth

-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-sound.channel 
local channel = {}
playdate.sound.channel = channel
channel.meta = {}
channel.meta.__index = channel.meta

function channel.new()
  local newChannel = setmetatable({}, channel.meta)
  newChannel.sources = {}
  newChannel.volume = 1.0
  return newChannel
end

function channel.meta:remove()
  error("[ERR] playdate.sound.channel:getSize() is not yet implemented.")
end

function channel.meta:addEffect(effect)
  error("[ERR] playdate.sound.channel:addEffect() is not yet implemented.")
end

function channel.meta:removeEffect(effect)
  error("[ERR] playdate.sound.channel:removeEffect() is not yet implemented.")
end

function channel.meta:addSource(source)
  self.sources[#self.sources + 1] = source
end

function channel.meta:removeSource(source)
  error("[ERR] playdate.sound.channel:removeSource() is not yet implemented.")
end

function channel.meta:setVolume(volume)
  print("[WARN] playdate.sound.channel:setVolume() is not fully implemented.")
  self.volume = volume
  for i=1, #self.sources do
    -- TODO-Playbit: this isn't quite right, but will maybe work for now
    self.sources[i]:setVolume(volume)
  end
end

function channel.meta:getVolume()
  error("[ERR] playdate.sound.channel:getVolume() is not yet implemented.")
end

function channel.meta:setPan(pan)
  error("[ERR] playdate.sound.channel:setPan() is not yet implemented.")
end

function channel.meta:setPanMod(signal)
  error("[ERR] playdate.sound.channel:setPanMod() is not yet implemented.")
end

function channel.meta:setVolumeMod(signal)
  error("[ERR] playdate.sound.channel:setVolumeMod() is not yet implemented.")
end

function channel.meta:getDryLevelSignal()
  error("[ERR] playdate.sound.channel:getDryLevelSignal() is not yet implemented.")
end

function channel.meta:getWetLevelSignal()
  error("[ERR] playdate.sound.channel:getWetLevelSignal() is not yet implemented.")
end