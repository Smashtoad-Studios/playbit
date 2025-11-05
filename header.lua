!if LOVE2D then
require("playbit.graphics")

--[[ since there is no CoreLibs/playdate, this file should always 
be included here so the methods are always available ]]--
require("playdate.playdate")
--[[ not really a way around including this one, but probably doesn't really
matter as all games are going to need to import graphics to draw stuff ]]--
require("playdate.graphics")

-- TODO-Playbit: this does not support relative paths, or files ending in .lua, both of which work on Playdate
function import(path)
  if string.match(path, "^CoreLibs/") then
    path = string.gsub(path, "/", ".")
    path = string.gsub(path, "CoreLibs", "playdate")
    return require(path)
  end
  path = string.gsub(path, "/", ".")
  return require(path)
end

local firstFrame = true
-- The frame buffer is used for XOR and NXOR draw modes
local framebuffer
local windowWidth, windowHeight = playbit.graphics.getWindowSize()

playbit.graphics.canvas:setFilter("nearest", "nearest")
playbit.graphics.frameBufferCanvas:setFilter("nearest", "nearest")

-- initialize the default context
playdate.graphics.pushContext()

love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")

math.randomseed(os.time())

local font = playdate.graphics.font.new("fonts/Phozon/Phozon")
playdate.graphics.setFont(font)

playbit.graphics.setWindowSize(windowWidth, windowHeight)

function love.draw()
  -- must be changed at start of frame when canvas is not active
  local newCanvasWidth, newCanvasHeight = playbit.graphics.getCanvasSize()
  local canvasWidth = playbit.graphics.canvas:getWidth()
  local canvasHeight = playbit.graphics.canvas:getHeight()
  if canvasWidth ~= newCanvasWidth or canvasHeight ~= newCanvasHeight then
    playbit.graphics.canvas = love.graphics.newCanvas(newCanvasWidth, newCanvasHeight)
  end

  -- must be changed at start of frame - love2d doesn't allow changing window size with canvas active
  local newWindowWidth, newWindowHeight = playbit.graphics.getWindowSize()
  local fullscreen = playbit.graphics.getFullscreen()
  local w, y, flags = love.window.getMode()
  if windowWidth ~= newWindowWidth or windowHeight ~= newWindowHeight or flags.fullscreen ~= fullscreen then
    flags.fullscreen = fullscreen

    -- stop window from ending up off screen when switching back from fullscreen
    if flags.x < 50 then
      flags.x = 50
    end
    if flags.y < 50 then
      flags.y = 50
    end

    love.window.setMode(newWindowWidth, newWindowHeight, flags)
    windowWidth = newWindowWidth
    windowHeight = newWindowHeight
  end

  -- render to canvas to allow 2x scaling
  love.graphics.setCanvas({playbit.graphics.canvas, stencil=true})
  love.graphics.setShader(playbit.graphics.shader)

  --[[ 
    Love2d won't allow a canvas to be set outside of the draw function, so we need to do this on the first frame of draw.
    Otherwise setting the bg color outside of playdate.update() won't be consistent with PD.
  --]]
  if firstFrame then
    love.graphics.clear(playbit.graphics.lastClearColor)
    firstFrame = false
  end

  -- love requires that this is set every loop
  love.graphics.setFont(playbit.graphics.activeContext.fontFamily[playdate.graphics.font.kVariantNormal].data)

  -- push main transform for draw offset
  love.graphics.push()
  love.graphics.translate(playbit.graphics.drawOffset.x, playbit.graphics.drawOffset.y)

  -- main update
  playdate.update()

  -- debug draw
  if playdate.debugDraw then
    playbit.graphics.shader:send("debugDraw", true)
    playdate.debugDraw()
    playbit.graphics.shader:send("debugDraw", false)
  end

  -- pop main transform for draw offset
  love.graphics.pop()

  -- pop canvas
  love.graphics.setCanvas()

  -- clear shader so that canvas is rendered normally
  love.graphics.setShader()

  -- always render pure white so its not tinted
  local r, g, b = love.graphics.getColor()
  love.graphics.setColor(1, 1, 1, 1)

  -- draw canvas to screen
  local currentCanvasScale = playbit.graphics.getCanvasScale()
  local x, y = playbit.graphics.getCanvasPosition()
  love.graphics.draw(playbit.graphics.canvas, x, y, 0, currentCanvasScale, currentCanvasScale)

  -- reset back to set color
  love.graphics.setColor(r, g, b, 1)

  -- TODO-Playbit: not a native Playdate SDK functions. Move to Playbit?
  -- update emulated input
  playdate.updateInput()
  playdate.graphics.animation.loop.update()
end

function love.resize(w, h)
  playbit.graphics.setWindowSize(w, h)
end

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
      -- Clear canvas before checking events
      love.graphics.setCanvas() 
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

      -- Clear canvas before presenting
      love.graphics.setCanvas() 
			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end

!end