!if LOVE2D then
playbit = playbit or {}
local module = {}
playbit.graphics = module

-- #b0aea7
module.COLOR_WHITE = { 214 / 255, 211 / 255, 203 / 255, 1 }
-- #312f28
module.COLOR_BLACK = { 49 / 255, 46 / 255, 40 / 255, 1 }

module.COLOR_CLEAR = { 0, 0, 0, 0 }
module.MODE_KEY = "mode"

module.CANVAS_WIDTH = 400
module.CANVAS_HEIGHT = 240

module.canvas = love.graphics.newCanvas(module.CANVAS_WIDTH, module.CANVAS_HEIGHT)
module.frameBufferCanvas = love.graphics.newCanvas(module.CANVAS_WIDTH, module.CANVAS_HEIGHT)

module.colorWhite = module.COLOR_WHITE
module.colorBlack = module.COLOR_BLACK
module.colorClear = module.COLOR_CLEAR

module.lastClearColor = module.colorWhite
module.shader = love.graphics.newShader("playdate/shader")

module.drawOffset = { x = 0, y = 0}

module.activeContext = nil
module.contextStack = {}

-- shared quad to reduce gc
module.quad = love.graphics.newQuad(0, 0, 1, 1, 1, 1)

module.kDitherTypeNone = 0
module.kDitherTypeDiagonalLine = 1
module.kDitherTypeVerticalLine = 2
module.kDitherTypeHorizontalLine = 3
module.kDitherTypeScreen = 4
module.kDitherTypeBayer2x2 = 5
module.kDitherTypeBayer4x4 = 6
module.kDitherTypeBayer8x8 = 7
module.kDitherTypeFloydSteinberg = 8
module.kDitherTypeBurkes = 9
module.kDitherTypeAtkinson = 10

module.ditherThresholds = {
  [module.kDitherTypeDiagonalLine] = {
    { 13/16, 9/16, 5/16, 1/16 },
    { 9/16, 5/16, 1/16, 13/16 },
    { 5/16, 1/16, 13/16, 9/16 },
    { 1/16, 13/16, 9/16, 5/16 }
  },
  [module.kDitherTypeVerticalLine] = {
    { 6/16, 2/16, 14/16, 10/16 },
    { 6/16, 2/16, 14/16, 10/16 },
    { 6/16, 2/16, 14/16, 10/16 },
    { 6/16, 2/16, 14/16, 10/16 },
  },
  [module.kDitherTypeHorizontalLine] = {
    { 5/16, 1/16, 13/16, 9/16 },
    { 5/16, 1/16, 13/16, 9/16 },
    { 5/16, 1/16, 13/16, 9/16 },
    { 5/16, 1/16, 13/16, 9/16 },
  },
  [module.kDitherTypeScreen] = {
    { 14/16,  6/16, 14/16, 6/16 },
    { 10/16,  2/16, 10/16, 2/16 },
    { 14/16,  6/16, 14/16, 6/16 },
    { 10/16,  2/16, 10/16, 2/16 }
  },
  [module.kDitherTypeBayer2x2] = {
    {   0, 2/4 },
    { 3/4, 1/4 }
  },
  [module.kDitherTypeBayer4x4] = {
    {     0,  8/16,  2/16, 10/16 },
    { 12/16,  4/16, 14/16,  6/16 },
    {  3/16, 11/16,  1/16,  9/16 },
    { 15/16,  7/16, 13/16,  5/16 }
  },
  [module.kDitherTypeBayer8x8] = {
    {  0/64, 32/64,  8/64, 40/64,  2/64, 34/64, 10/64, 42/64 },
    { 48/64, 16/64, 56/64, 24/64, 50/64, 18/64, 58/64, 26/64 },
    { 12/64, 44/64,  4/64, 36/64, 14/64, 46/64,  6/64, 38/64 },
    { 60/64, 28/64, 52/64, 20/64, 62/64, 30/64, 54/64, 22/64 },
    {  3/64, 35/64, 11/64, 43/64,  1/64, 33/64,  9/64, 41/64 },
    { 51/64, 19/64, 59/64, 27/64, 49/64, 17/64, 57/64, 25/64 },
    { 15/64, 47/64,  7/64, 39/64, 13/64, 45/64,  5/64, 37/64 },
    { 63/64, 31/64, 55/64, 23/64, 61/64, 29/64, 53/64, 21/64 }
  },
}

local canvasScale = 1
local canvasX = 0
local canvasY = 0

--- Sets the scale of the canvas.
---@param scale number
function module.setCanvasScale(scale)
  canvasScale = scale
end

---Returns the current scale of the canvas.
---@return number
function module.getCanvasScale()
  return canvasScale
end

--- Returns the current canvas size.
---@return integer width
---@return integer height
function module.getCanvasSize()
  return module.CANVAS_WIDTH, module.CANVAS_HEIGHT
end

--- Sets the canvas position within the window.
---@param x any
---@param y any
function module.setCanvasPosition(x, y)
  canvasX = x
  canvasY = y
end

--- Returns the current canvas position within the window.
---@return integer x
---@return integer y
function module.getCanvasPosition()
  return canvasX, canvasY
end

--- Sets the size of the window.
---@param width number
---@param height number
function module.setCanvasSize(width, height)
  local width = width == nil and love.graphics.getWidth() or width
  local height = height == nil and love.graphics.getHeight() or height

  canvasScale = math.min(width / module.CANVAS_WIDTH, height / module.CANVAS_HEIGHT)
  
  canvasX = (width - module.CANVAS_WIDTH * canvasScale) / 2
  canvasY = (height - module.CANVAS_HEIGHT * canvasScale) / 2
end

--- Sets the colors used when drawing graphics.
---@param white table An array of 4 values that correspond to RGBA that range from 0 to 1.
---@param black table An array of 4 values that correspond to RGBA that range from 0 to 1.
function module.setColors(white, black)
  if white == nil then
    white = module.COLOR_WHITE
  end
  if black == nil then
    black = module.COLOR_BLACK
  end
  
  module.colorWhite = white
  module.colorBlack = black
  module.shader:send("white", white)
  module.shader:send("black", black)
end

function module.updateFramebufferCanvas()
  -- copy current frame into framebuffer
  local r, g, b = love.graphics.getColor()
  local currentCanvas = love.graphics.getCanvas()

  local framebufferWidth, framebufferHeight = currentCanvas:getDimensions()
  
  -- TODO resize the framebuffer if needed and send the framebuffer size to the shader
  if framebufferWidth ~= playbit.graphics.frameBufferCanvas:getWidth() or framebufferHeight ~= playbit.graphics.frameBufferCanvas:getHeight() then
    playbit.graphics.frameBufferCanvas = love.graphics.newCanvas(framebufferWidth, framebufferHeight)
  end
  
  -- TODO resize the framebuffer if needed and send the framebuffer size to the shader
  love.graphics.setCanvas(playbit.graphics.frameBufferCanvas)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setShader()
  love.graphics.draw(currentCanvas)
  love.graphics.setCanvas({currentCanvas, stencil=true})
  love.graphics.setShader(playbit.graphics.shader)
  love.graphics.setColor(r, g, b, 1)
  
  -- send framebuffer to shader
  playbit.graphics.shader:send("destTex", playbit.graphics.frameBufferCanvas)
end

function module.updateContext()
  if module.activeContext == nil then
    return
  end

  local activeContext = module.activeContext

  -- love2d doesn't allow calling newImageData() when canvas is active
  love.graphics.setCanvas()
  local imageData = module.activeContext.canvas:newImageData()
  love.graphics.setCanvas({module.activeContext.canvas, stencil=true})

  -- check if active context is an image
  if module.activeContext.image then
    -- update image
    module.activeContext.image.data:replacePixels(imageData)
    -- also update the raw image data so we can duplcate the image as needed
    module.activeContext.image.imgData = imageData
  end
end
!end