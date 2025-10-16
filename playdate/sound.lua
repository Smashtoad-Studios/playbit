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

function sampleplayer.meta:setFinishCallback()
  print("[WARN] playdate.sound.sampleplayer:setFinishCallback() is not yet implemented.")
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

-- TODO: synth
-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-sound.synth

local synth = {}
playdate.sound.synth = synth
synth.meta = {}
synth.meta.__index = synth.meta

function synth.new()
  print("[WARN] playdate.sound.synth is not yet implemented")
  local newSynth = setmetatable({}, synth.meta)
  return newSynth
end

function synth.meta:playNote(pitch, volume, length, when)
  print("[WARN] playdate.sound.synth:playNote() is not yet implemented")
end

function synth.meta:playMIDINote(note, volume, length, when)
  print("[WARN] playdate.sound.synth:playMIDINote() is not yet implemented")
end

function synth.meta:noteOff()
  print("[WARN] playdate.sound.synth:noteOff() is not yet implemented")
end

function synth.meta:isPlaying()
  print("[WARN] playdate.sound.synth:isPlaying() is not yet implemented")
end

function synth.meta:setAmplitudeMod(signal)
  print("[WARN] playdate.sound.synth:setAmplitudeMod() is not yet implemented")
end

function synth.meta:setADSR(attack, decay, sustain, release)
  print("[WARN] playdate.sound.synth:setADSR() is not yet implemented")
end

function synth.meta:setAttack(time)
  print("[WARN] playdate.sound.synth:setAttack() is not yet implemented")
end

function synth.meta:setDecay(time)
  print("[WARN] playdate.sound.synth:setDecay() is not yet implemented")
end

function synth.meta:setSustain(level)
  print("[WARN] playdate.sound.synth:setSustain() is not yet implemented")
end

function synth.meta:setRelease(time)
  print("[WARN] playdate.sound.synth:setRelease() is not yet implemented")
end

function synth.meta:clearEnvelope()
  print("[WARN] playdate.sound.synth:clearEnvelope() is not yet implemented")
end

function synth.meta:setEnvelopeCurvature(amount)
  print("[WARN] playdate.sound.synth:setEnvelopeCurvature() is not yet implemented")
end

function synth.meta:getEnvelope()
  print("[WARN] playdate.sound.synth:getEnvelope() is not yet implemented")
end

function synth.meta:setFinishCallback(callback)
  print("[WARN] playdate.sound.synth:setFinishCallback() is not yet implemented")
end


function synth.meta:setFrequencyMod(signal)
  print("[WARN] playdate.sound.synth:setFrequencyMod() is not yet implemented")
end

function synth.meta:setLegato(flag)
  print("[WARN] playdate.sound.synth:setLegato() is not yet implemented")
end


function synth.meta:setVolume(left, right)
  print("[WARN] playdate.sound.synth:setVolume() is not yet implemented")
end

function synth.meta:setWaveform(waveform)
  print("[WARN] playdate.sound.synth:setWaveform() is not yet implemented")
end

function synth.meta:setWavetable(sample, samplesize, xsize, ysize)
  print("[WARN] playdate.sound.synth:setWavetable() is not yet implemented")
end

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