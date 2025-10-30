local module = {}
playdate = module

require("playbit.geometry")
require("playdate.geometry")
require("playdate.metadata")
require("playdate.sound")
require("playdate.file")
require("playdate.datastore")
require("playdate.accelerometer")
require("playdate.json")
require("playdate.easing")
require("playdate.display")

-- ████████╗██╗███╗   ███╗███████╗
-- ╚══██╔══╝██║████╗ ████║██╔════╝
--    ██║   ██║██╔████╔██║█████╗  
--    ██║   ██║██║╚██╔╝██║██╔══╝  
--    ██║   ██║██║ ╚═╝ ██║███████╗
--    ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝
                               
function module.getTime()
  local seconds = os.time()
  local date = os.date("*t", seconds)
  return {
    year = date.year,
    month = date.month,
    day = date.day,
    weekday = date.wday,
    hour = date.hour,
    minute = date.min,
    second = date.sec,
    -- TODO: PD also returns milliseconds to the next second, but time functions in native lua don't have millisecond precision
    millisecond = 0,
  }
end

function module.getCurrentTimeMilliseconds()
  return love.timer.getTime() * 1000
end

function module.getSecondsSinceEpoch()
  -- os.time() without params always returns in system local time, so we must convert to UTC
  local nowLocal = os.time()
  local nowTable = os.date("!*t", nowLocal)
  local nowUtc = os.time(nowTable)
  -- Playdate epoch, as described: https://sdk.play.date/2.6.0/Inside%20Playdate.html#f-getSecondsSinceEpoch
  local playdateEpochUtc = os.time({
    year = 2000,
    month = 1,
    day = 1,
    hour = 0,
    min = 0,
    sec = 0,
  })
  -- TODO: PD also returns milliseconds to the next second, but time functions in native lua don't have millisecond precision
  local milliseconds = 0
  return os.difftime(nowUtc, playdateEpochUtc), milliseconds
end

-- ██╗███╗   ██╗██████╗ ██╗   ██╗████████╗
-- ██║████╗  ██║██╔══██╗██║   ██║╚══██╔══╝
-- ██║██╔██╗ ██║██████╔╝██║   ██║   ██║   
-- ██║██║╚██╗██║██╔═══╝ ██║   ██║   ██║   
-- ██║██║ ╚████║██║     ╚██████╔╝   ██║   
-- ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝    ╚═╝   
  
local lastActiveJoystick = nil
local isCrankDocked = false
local crankPos = 0
local lastCrankPos = 0

local inputHandlerStack = {}

local inputHandlersModule = {}
playdate.inputHandlers = inputHandlersModule

function inputHandlersModule.push(handler, maskPreviousHandlers)
    inputHandlerStack[#inputHandlerStack + 1] = {handler = handler, maskPreviousHandlers = maskPreviousHandlers}
end

function inputHandlersModule.pop()
    return table.remove(inputHandlerStack, #inputHandlerStack)
end

local function processButtonInput(button, buttonState)
  -- TODO-Playbit: check down the stack of input handlers
  local currentInputHandler = inputHandlerStack[#inputHandlerStack]
  if currentInputHandler then
    if not module._buttonFuncName[button] then
      return
    end
    local buttonFuncName = module._buttonFuncName[button] .. buttonState
    if currentInputHandler.handler[buttonFuncName] then
      currentInputHandler.handler[buttonFuncName]()
    end
  end
end

module.kButtonA = "a"
module.kButtonB = "b"
module.kButtonUp = "up"
module.kButtonDown = "down"
module.kButtonLeft = "left"
module.kButtonRight = "right"

module._buttonToKb = {
  [module.kButtonUp] = "kb_w",
  [module.kButtonDown] = "kb_s",
  [module.kButtonLeft] = "kb_a",
  [module.kButtonRight] = "kb_d",
  [module.kButtonA] = "kb_.",
  [module.kButtonB] = "kb_,",
}

module._buttonToJs = {
  [module.kButtonUp] = "js_dpup",
  [module.kButtonDown] = "js_dpdown",
  [module.kButtonLeft] = "js_dpleft",
  [module.kButtonRight] = "js_dpright",
  [module.kButtonA] = "js_a.",
  [module.kButtonB] = "js_b,",
}

module._inputKeyToButton = {
  ["kb_w"] = module.kButtonUp,
  ["kb_s"] = module.kButtonDown,
  ["kb_a"] = module.kButtonLeft,
  ["kb_d"] = module.kButtonRight,
  ["kb_."] = module.kButtonA,
  ["kb_,"] = module.kButtonB,
  ["js_a"] = module.kButtonA,
  ["js_b"] = module.kButtonB,
  ["js_dpup"] = module.kButtonUp,
  ["js_dpdown"] = module.kButtonDown,
  ["js_dpleft"] = module.kButtonLeft,
  ["js_dpright"] = module.kButtonRight,
}

module._buttonFuncName = {
  [module.kButtonUp] = "upButton",
  [module.kButtonDown] = "downButton",
  [module.kButtonLeft] = "leftButton",
  [module.kButtonRight] = "rightButton",
  [module.kButtonA] = "AButton",
  [module.kButtonB] = "BButton",
}

module._buttonStates =
{
  down = "Down",
  up = "Up",
  held = "Held",
}

local NONE = 0
local JUST_PRESSED = 1
local PRESSED = 2
local JUST_RELEASED = 3

local inputStates = {}

function module.buttonIsPressed(button)
  local inputKey = lastActiveJoystick and module._buttonToJs[button] or module._buttonToKb[button]
  if not inputStates[inputKey] then
    -- no entry, assume no input
    return false
  end

  return inputStates[inputKey] == JUST_PRESSED or inputStates[inputKey] == PRESSED
end

function module.buttonJustPressed(button)
  local inputKey = lastActiveJoystick and module._buttonToJs[button] or module._buttonToKb[button]
  if not inputStates[inputKey] then
    -- no entry, assume no input
    return false
  end

  return inputStates[inputKey] == JUST_PRESSED
end

function module.buttonJustReleased(button)
  local inputKey = lastActiveJoystick and module._buttonToJs[button] or module._buttonToKb[button]
  if not inputStates[inputKey] then
    -- no entry, assume no input
    return false
  end

  return inputStates[inputKey] == JUST_RELEASED
end

function module.getButtonState(button)
  local inputKey = lastActiveJoystick and module._buttonToJs[button] or module._buttonToKb[button]
  local value = inputStates[inputKey]
  return value == PRESSED, value == PRESSED, value == JUST_RELEASED
end

function module.isCrankDocked()
  if not lastActiveJoystick then
    return isCrankDocked
  end

  -- TODO: is basing dock state on if stick is non-zero a bad assumption here?
  -- will other games want a dedicated dock/undock button?
  local x = math.abs(lastActiveJoystick:getGamepadAxis("leftx"))
  local y = math.abs(lastActiveJoystick:getGamepadAxis("lefty"))
  local len = math.sqrt(x * x + y * y)
  -- TODO: deadzone sensitivity?
  if len < 0.1 then
    return true
  end

  return false
end

function module.getCrankChange()
    local change = playbit.geometry.angleDiff(lastCrankPos, crankPos)
    -- TODO: how does the playdate accelerate this?
    local acceleratedChange = change 
    return change, acceleratedChange
end

-- TODO: acceleramator, emulate via leftstick, keyboard...?

function module.getCrankPosition()
  if module.isCrankDocked() then
    return 0
  end

  if not lastActiveJoystick then
    return crankPos
  end


  local x = lastActiveJoystick:getGamepadAxis("leftx")
  local y = lastActiveJoystick:getGamepadAxis("lefty")

  local degrees = math.deg(math.atan2(x, -y))

  if degrees < 0 then
    return degrees + 360
  end
  return degrees
end

function module.setCrankSoundsDisabled(disable)
  print("[WARN] playdate.setCrankSoundsDisabled() has no effect.")
end

function love.joystickadded(joystick)
  -- always take most recently added joystick as active joystick
  lastActiveJoystick = joystick
end

function love.joystickremoved(joystick)
  if lastActiveJoystick == nil then
    return
  end

  if joystick:getID() == lastActiveJoystick:getID() then
    lastActiveJoystick = nil
  end
end

function love.gamepadpressed(joystick, gamepadButton)
  lastActiveJoystick = joystick
  local inputKey = "js_"..gamepadButton
  inputStates[inputKey] = JUST_PRESSED
  processButtonInput(module._inputKeyToButton[inputKey], module._buttonStates.down)
end

function love.gamepadreleased(joystick, gamepadButton)
  lastActiveJoystick = joystick
  local inputKey = "js_"..gamepadButton
  inputStates[inputKey] = JUST_RELEASED
  processButtonInput(module._inputKeyToButton[inputKey], module._buttonStates.up)
end

function love.mousepressed(x, y, button, istouch, presses)
  if button ~= 3 then
    return
  end

  isCrankDocked = not isCrankDocked
  crankPos = 0
  --[[ also reset lastCrankPos since on PD, you cant
  dock the crank without rotating it back to 0 --]]
  lastCrankPos = 0
end

function love.wheelmoved(x, y)
  if isCrankDocked then
    return
  end

  -- TODO: emulate PD crank acceleration?
  -- TODO: configure scroll sensitivity?
  local diff = -y * 6
  crankPos = crankPos + diff
  
  if crankPos < 0 then
    crankPos = 359
  elseif crankPos > 359 then
    crankPos = 0
  end

  local currentInputHandler = inputHandlerStack[#inputHandlerStack]
  if currentInputHandler then
    if currentInputHandler.handler.cranked then
      currentInputHandler.handler.cranked(diff, diff)
    end
  end
end

-- emulate the keys that PD simulator supports
-- https://sdk.play.date/Inside%20Playdate.html#c-keyPressed
local supportedCallbackKeys = {
  ["1"] = true,
  ["2"] = true,
  ["3"] = true,
  ["4"] = true,
  ["5"] = true,
  ["6"] = true,
  ["7"] = true,
  ["8"] = true,
  ["9"] = true,
  ["0"] = true,
  ["q"] = true,
  ["w"] = true,
  ["e"] = true,
  ["r"] = true,
  ["t"] = true,
  ["y"] = true,
  ["u"] = true,
  ["i"] = true,
  ["o"] = true,
  ["p"] = true,
  ["a"] = true,
  ["s"] = true,
  ["d"] = true,
  ["f"] = true,
  ["g"] = true,
  ["h"] = true,
  ["j"] = true,
  ["k"] = true,
  ["l"] = true,
  ["z"] = true,
  ["x"] = true,
  ["c"] = true,
  ["v"] = true,
  ["b"] = true,
  ["n"] = true,
  ["m"] = true,
  [";"] = true,
  ["'"] = true,
  [","] = true,
  ["."] = true,
  ["/"] = true,
  ["\\"] = true,
  ["`"] = true,
}

function love.keypressed(key)
  local inputKey = "kb_"..key
  inputStates[inputKey] = JUST_PRESSED

  --[[ Playdate only has a limited range of supported keys, so Playbit exposes the separate
  `playbit.keyPressed` handler so that it can be used to listen to any keypress under love2d. ]]--
  if playbit.keyPressed then
    playbit.keyPressed(key)
  end
  if supportedCallbackKeys[key] then
    if playdate.keyPressed then
      playdate.keyPressed(key)
    end
  end

  processButtonInput(module._inputKeyToButton[inputKey], module._buttonStates.down)
end

function love.keyreleased(key)
  local inputKey = "kb_"..key
  inputStates[inputKey] = JUST_RELEASED

  if playbit.keyReleased then
    playbit.keyReleased(key)
  end

  if supportedCallbackKeys[key] then
    if playdate.keyReleased then
      playdate.keyReleased(key)
    end
  end

  processButtonInput(module._inputKeyToButton[inputKey], module._buttonStates.up)
end

function module.updateInput()
  -- only update keys that are mapped
  for k,v in pairs(module._buttonToKb) do
    if inputStates[v] == JUST_PRESSED then
      inputStates[v] = PRESSED
    elseif inputStates[v] == JUST_RELEASED then
      inputStates[v] = NONE
    end
  end

  local currentCrankPos = crankPos

  -- update the crankPos for the next tick
  if lastActiveJoystick then
    local x = lastActiveJoystick:getGamepadAxis("leftx")
    local y = lastActiveJoystick:getGamepadAxis("lefty")

    local degrees = math.deg(math.atan2(x, -y))

    if degrees < 0 then
      crankPos = degrees + 360
    else
      crankPos = degrees
    end

    if crankPos ~= lastCrankPos then
      local diff = crankPos - lastCrankPos
      local currentInputHandler = inputHandlerStack[#inputHandlerStack]
      if currentInputHandler then
        if currentInputHandler.handler.cranked then
          currentInputHandler.handler.cranked(diff, diff)
        end
      end
    end
  end

  lastCrankPos = currentCrankPos
end

-- ██╗     ██╗   ██╗ █████╗ 
-- ██║     ██║   ██║██╔══██╗
-- ██║     ██║   ██║███████║
-- ██║     ██║   ██║██╔══██║
-- ███████╗╚██████╔╝██║  ██║
-- ╚══════╝ ╚═════╝ ╚═╝  ╚═╝
                         
function table.indexOfElement(table, element)
  for i = 1, #table do
    if table[i] == element then
      return i
    end
  end
  return nil
end

function printTable(...)
	error("[ERR] printTable() is not yet implemented.")
end

-- debug TODO: make a fancy header
function sample()
  error("[ERR] sample() is not yet implemented.")
end

function where()
  error("[ERR] where() is not yet implemented.")
end

function module.apiVersion()
  -- TODO: return Playbit version instead?
  error("[ERR] playdate.apiVersion() is not yet implemented.")
end