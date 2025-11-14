-- docs: https://sdk.play.date/2.6.2/Inside%20Playdate.html#M-sound

playdate.sound = {}

local sampleplayer = {}
local playingSamplePlayers = {}

local function setFinishCallback(player, func, arg)
  if type(func) == "function" then
    player.finishCallback = func
  else
    error("[ERR] setFinishCallback() expects a function")
  end

  player.finishCallbackArg = arg
end

local function callPlayerFinishedCallback(player)
  if player.finishCallback ~= nil then
    -- First argument is always the player then the optional arg
    player.finishCallback(self, player.finishCallbackArg)
  end
end

local function updatePlayingPlayers(players)
  -- Iterate back-to-front to avoid skipping over elements when removing
  for i = #players, 1, -1 do
    if not players[i]:isPlaying() then
      -- Repeat count was passed in when played
      if players[i].repeatCount then
        -- Increment number of times this player was repeated
        players[i].currentRepeatCount = players[i].currentRepeatCount + 1
        
        -- This player is still repeating then play
        if players[i].currentRepeatCount < players[i].repeatCount then
          players[i].data:play()
          return
        end
      end

      callPlayerFinishedCallback(players[i])

      table.remove(players, i)
    end
  end
end

local function playerStop(player, playingPlayers)
  player.data:stop()

  callPlayerFinishedCallback(player)

  for i = 1, #playingPlayers, 1 do
    if playingPlayers[i] == player then
      table.remove(playingPlayers, i)
    end
  end
end

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

function sampleplayer.update()
  updatePlayingPlayers(playingSamplePlayers)
end

function sampleplayer.meta:copy()
  local sample = setmetatable({}, sampleplayer.meta)
  sample.data = self.data:clone()
  return sample
end

function sampleplayer.meta:play(repeatCount, rate)
  if self:isPlaying() then
    self:stop()
  end

  if rate then
    self.data:setPitch(rate)
  end

  if repeatCount then
    self.repeatCount = repeatCount
    self.currentRepeatCount = 0

    if self.repeatCount == 0 then
      -- loop endlessly
      self.data:setLooping(true)
    end
  end

  self.data:play()
  playingSamplePlayers[#playingSamplePlayers + 1] = self
end

function sampleplayer.meta:stop()
  playerStop(self, playingSamplePlayers)
end

function sampleplayer.meta:isPlaying()
  return self.data:isPlaying()
end

function sampleplayer.meta:getLength()
  return self.data:getDuration()
end

function sampleplayer.meta:setFinishCallback(func, arg)
  setFinishCallback(self, func, arg)
end

function sampleplayer.meta:setVolume(volume)
  self.data:setVolume(volume)
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
local playingFilePlayers = {}

playdate.sound.fileplayer = fileplayer
fileplayer.meta = {}
fileplayer.meta.__index = fileplayer.meta



function fileplayer.new(path, bufferSize)
  -- TODO: is there a way to use bufferSize to control Love2D chunks?
  local sample = setmetatable({}, fileplayer.meta)
  sample.data = love.audio.newSource(path..".wav", "stream")
  sample.channelVolume = 1
  sample.volume = 1

  return sample
end

function fileplayer.update()
  updatePlayingPlayers(playingFilePlayers)
end

function fileplayer.meta:load(path)
  playbit.logger.printWarning("playdate.sound.fileplayer:load() is not yet implemented")
end

function fileplayer.meta:play(repeatCount)
  if repeatCount then
    self.repeatCount = repeatCount
    self.currentRepeatCount = 0

    if self.repeatCount == 0 then
      -- loop endlessly
      self.data:setLooping(true)
    end
  end

  self.data:play()
  playingFilePlayers[#playingFilePlayers + 1] = self
end

function fileplayer.meta:stop()
  playerStop(self, playingFilePlayers)
end

function fileplayer.meta:pause(value)
  self.data:pause()
end

function fileplayer.meta:isPlaying()
  return self.data:isPlaying()
end

function fileplayer.meta:getLength()
  return self.data:getDuration("seconds")
end

-- left, [right, [fadeSeconds, [fadeCallback, [arg]]]]
function fileplayer.meta:setVolume(left, right, fadeSeconds, fadeCallback, arg)
  @@ASSERT(type(left) == "number", "[ERR] playdate.sound.fileplayer.setVolume \"left\" needs to be a number")
  @@ASSERT((left >= 0 and left <= 1), "[ERR] playdate.sound.fileplayer.setVolume \"left\" needs to be between 0 and 1")

  -- playbit.logger.printWarning("playdate.sound.fileplayer:setVolume() right parameter is not used yet")
  @@ASSERT(fadeSeconds == nil or type(fadeSeconds) == "number", "[ERR] playdate.sound.fileplayer.setVolume \"fadeSeconds\" needs to be a number")
  @@ASSERT(fadeCallback == nil or type(fadeCallback) == "function", "[ERR] playdate.sound.fileplayer.setVolume \"fadeCallback\" needs to be a number")

  self.fadeSeconds = fadeSeconds

  -- Fade from the current volume to the specified volume if fadeSeconds is passed in
  if self.fadeSeconds ~= nil and self.fadeSeconds ~= 0 then
    local fadeTimer = playdate.timer.new(self.fadeSeconds * 1000, self.volume, left)

    fadeTimer.updateCallback = function (timer)
      self.volume = timer.value
      -- The channel acts as a master volume
      self.data:setVolume(self.volume * self.channelVolume)
    end

    fadeTimer.timerEndedCallback = function ()
      if fadeCallback ~= nil then
        -- The fileplayer object is passed as the first argument to the callback, and the optional arg argument is passed as the second
        fadeCallback(self, arg)
      end
    end

    return
  end

  self.volume = left

  -- The channel acts as a master volume
  -- Set volume instantly
  self.data:setVolume(self.volume * self.channelVolume)
  if fadeCallback ~= nil then
    -- The fileplayer object is passed as the first argument to the callback, and the optional arg argument is passed as the second
    fadeCallback(self, arg)
  end
end

function fileplayer.meta:setFinishCallback(func, arg)
  setFinishCallback(self, func, arg)
end

function fileplayer.meta:didUnderrun()
  playbit.logger.printWarning("playdate.sound.fileplayer:didUnderrun() is not yet implemented")
end

function fileplayer.meta:setStopOnUnderrun(flag)
  playbit.logger.printWarning("playdate.sound.fileplayer:setStopOnUnderrun() is not yet implemented")
end

-- start, [end, [loopCallback, [arg]]]
function fileplayer.meta:setLoopRange(startSeconds, endSeconds, loopCallback, arg)
  playbit.logger.printWarning("playdate.sound.fileplayer:setLoopRange() is not yet implemented")
end

function fileplayer.meta:setLoopCallback(callback, arg)
  playbit.logger.printWarning("playdate.sound.fileplayer:setLoopCallback() is not yet implemented")
end

function fileplayer.meta:setBufferSize(seconds)
  playbit.logger.printWarning("playdate.sound.fileplayer:setBufferSize() is not yet implemented")
end

-- NOT A NATIVE PLAYDATE FUNCTION
function fileplayer.meta:channelVolumeChanged(volume)
  @@ASSERT(type(volume) == "number", "[ERR] playdate.sound.fileplayer.channelVolumeChanged volume needs to be a number")
  self.channelVolume = volume

  -- The channel acts as a master volume
  self.data:setVolume(self.volume * self.channelVolume)
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

function fileplayer.meta:setRateMod(signal)
  playbit.logger.printWarning("playdate.sound.fileplayer:setRateMod() is not yet implemented")
end

function fileplayer.meta:setOffset(seconds)
  self.data:seek(seconds)
end

function fileplayer.meta:getOffset()
  return self.data:tell()
end

-- TODO: synth
-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-sound.synth

local synth = {}
playdate.sound.synth = synth
synth.meta = {}
synth.meta.__index = synth.meta

function synth.new()
  playbit.logger.printWarning("playdate.sound.synth is not yet implemented")
  local newSynth = setmetatable({}, synth.meta)
  return newSynth
end

function synth.meta:playNote(pitch, volume, length, when)
  playbit.logger.printWarning("playdate.sound.synth:playNote() is not yet implemented")
end

function synth.meta:playMIDINote(note, volume, length, when)
  playbit.logger.printWarning("playdate.sound.synth:playMIDINote() is not yet implemented")
end

function synth.meta:noteOff()
  playbit.logger.printWarning("playdate.sound.synth:noteOff() is not yet implemented")
end

function synth.meta:isPlaying()
  playbit.logger.printWarning("playdate.sound.synth:isPlaying() is not yet implemented")
end

function synth.meta:setAmplitudeMod(signal)
  playbit.logger.printWarning("playdate.sound.synth:setAmplitudeMod() is not yet implemented")
end

function synth.meta:setADSR(attack, decay, sustain, release)
  playbit.logger.printWarning("playdate.sound.synth:setADSR() is not yet implemented")
end

function synth.meta:setAttack(time)
  playbit.logger.printWarning("playdate.sound.synth:setAttack() is not yet implemented")
end

function synth.meta:setDecay(time)
  playbit.logger.printWarning("playdate.sound.synth:setDecay() is not yet implemented")
end

function synth.meta:setSustain(level)
  playbit.logger.printWarning("playdate.sound.synth:setSustain() is not yet implemented")
end

function synth.meta:setRelease(time)
  playbit.logger.printWarning("playdate.sound.synth:setRelease() is not yet implemented")
end

function synth.meta:clearEnvelope()
  playbit.logger.printWarning("playdate.sound.synth:clearEnvelope() is not yet implemented")
end

function synth.meta:setEnvelopeCurvature(amount)
  playbit.logger.printWarning("playdate.sound.synth:setEnvelopeCurvature() is not yet implemented")
end

function synth.meta:getEnvelope()
  playbit.logger.printWarning("playdate.sound.synth:getEnvelope() is not yet implemented")
end

function synth.meta:setFinishCallback(callback)
  playbit.logger.printWarning("playdate.sound.synth:setFinishCallback() is not yet implemented")
end


function synth.meta:setFrequencyMod(signal)
  playbit.logger.printWarning("playdate.sound.synth:setFrequencyMod() is not yet implemented")
end

function synth.meta:setLegato(flag)
  playbit.logger.printWarning("playdate.sound.synth:setLegato() is not yet implemented")
end


function synth.meta:setVolume(left, right)
  playbit.logger.printWarning("playdate.sound.synth:setVolume() is not yet implemented")
end

function synth.meta:setWaveform(waveform)
  playbit.logger.printWarning("playdate.sound.synth:setWaveform() is not yet implemented")
end

function synth.meta:setWavetable(sample, samplesize, xsize, ysize)
  playbit.logger.printWarning("playdate.sound.synth:setWavetable() is not yet implemented")
end

-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-sound.channel 
local channel = {}
local channels = {}
playdate.sound.channel = channel
channel.meta = {}
channel.meta.__index = channel.meta

function channel.new()
  local newChannel = setmetatable({}, channel.meta)
  newChannel.sources = {}
  newChannel.volume = 1.0

  channels[#channels + 1] = newChannel

  return newChannel
end

function channel.meta:remove()
    for i = 1, #channels, 1 do
    if channels[i] == self then
      table.remove(channels, i)
    end
  end
end

function channel.meta:addEffect(effect)
  error("[ERR] playdate.sound.channel:addEffect() is not yet implemented.")
end

function channel.meta:removeEffect(effect)
  error("[ERR] playdate.sound.channel:removeEffect() is not yet implemented.")
end

function channel.meta:addSource(source)
  source:channelVolumeChanged(self.volume)
  self.sources[#self.sources + 1] = source
end

function channel.meta:removeSource(source)
  source:channelVolumeChanged(1)

  for i = 1, #self.sources, 1 do
    if self.sources[i] == source then
      table.remove(self.sources, i)
    end
  end
end

function channel.meta:setVolume(volume)
  self.volume = volume

  for i=1, #self.sources do
    self.sources[i]:channelVolumeChanged(self.volume)
  end
end

function channel.meta:getVolume()
  return self.volume
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


-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#_mic_input

local micinput = {}
playdate.sound.micinput = micinput

function micinput.recordToSample(buffer, completionCallback)
  error("[ERR] playdate.sound.micinput.recordToSample() is not yet implemented.")
end

function micinput.stopRecording()
  playbit.logger.printWarning("playdate.sound.micinput.stopRecording() is not yet implemented.")
end

function micinput.startListening(source)
  playbit.logger.printWarning("playdate.sound.micinput.stopListening() is not yet implemented.")
  return true, nil
end

function micinput.stopListening()
  playbit.logger.printWarning("playdate.sound.micinput.stopListening() is not yet implemented.")
end

function micinput.getLevel()
  playbit.logger.printWarning("playdate.sound.micinput.getLevel() is not yet implemented.")
  return 0
end

function micinput.getSource()
  error("[ERR] playdate.sound.micinput.getSource() is not yet implemented.")
end
