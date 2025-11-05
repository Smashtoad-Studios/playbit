local module = {}
playdate.graphics = module

require("playdate.font")
require("playdate.image")
require("playdate.imagetable")
require("playdate.tilemap")
require("playdate.sprites")
require("playdate.animation")

module.kDrawModeCopy = 0
module.kDrawModeWhiteTransparent = 1
module.kDrawModeBlackTransparent = 2
module.kDrawModeFillWhite = 3
module.kDrawModeFillBlack = 4
module.kDrawModeXOR = 5
module.kDrawModeNXOR = 6
module.kDrawModeInverted = 7

module.kImageUnflipped = 0
module.kImageFlippedX = 1
module.kImageFlippedY = 2
module.kImageFlippedXY = 3

module.kStrokeCentered = 0
module.kStrokeOutside = 1
module.kStrokeInside = 2

module.kLineCapStyleButt = 0
module.kLineCapStyleRound = 1
module.kLineCapStyleSquare = 2

module.kColorWhite = 1
module.kColorBlack = 0
-- TODO: clear and XOR support

kTextAlignment = {
	left = 0,
	right = 1,
	center = 2,
}

local function setPatternDrawModeAndColor()
  if playbit.graphics.activeContext.color == playdate.graphics.kColorBlack then
    playbit.graphics.shader:send("patternColor", playbit.graphics.colorBlack)
  else
    playbit.graphics.shader:send("patternColor", playbit.graphics.colorWhite)
  end
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)
end

function module.setDrawOffset(x, y)
  playbit.graphics.activeContext.drawOffset = {
    x = x,
    y = y
  }
  if love.graphics.getStackDepth() > 0 then
    love.graphics.pop()
  end
  -- TODO this causes problems with nested image contexts possibly due to draw offset when drawing the image to the canvas
  love.graphics.push()
  love.graphics.translate(x, y)
end

function module.getDrawOffset()
  return playbit.graphics.activeContext.drawOffset.x, playbit.graphics.activeContext.drawOffset.y
end

function module.setBackgroundColor(color)
  -- TODO: save this to graphics context
  @@ASSERT(color == 1 or color == 0, "Only values of 0 (black) or 1 (white) are supported.")
  playbit.graphics.activeContext.backgroundColor = color
  -- don't actually set love's bg color here since doing so immediately sets the color, and this is not consistent with PD
end

function module.getBackgroundColor()
  return playbit.graphics.activeContext.backgroundColor
end

function module.clearPattern()
    module.setPattern({0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff})
end

function module.setColor(color, keepPattern)
  -- TODO: save this to graphics context
  @@ASSERT(color == playdate.graphics.kColorBlack or color == playdate.graphics.kColorWhite, "Only values of 0 (black) or 1 (white) are supported.")
  playbit.graphics.activeContext.color = color
  -- when drawing without a pattern, we must flip the pattern mask for white/black because of the way the shader draws patterns
  local c = color == playdate.graphics.kColorWhite and playbit.graphics.colorWhite or playbit.graphics.colorBlack
  love.graphics.setColor(c)
  -- reset pattern, as per PD behavior
  if not keepPattern then
    module.clearPattern()
  end
end

function module.getColor()
  return playbit.graphics.activeContext.color
end

function module.setPattern(pattern)
  playbit.graphics.activeContext.pattern = pattern
  playbit.graphics.activeContext.ditherType = nil

  -- bitshifting does not work in shaders, so do it here in Lua
  local pixels = {}
  for i = 1, 8 do
    for j = 7, 0, -1 do
      local b = bit.lshift(1, j)
      if bit.band(pattern[i], b) == b then
        table.insert(pixels, 1)
      else
        table.insert(pixels, 0)
      end
    end
  end
  
  playbit.graphics.shader:send("pattern", unpack(pixels))
end

function module.clear(color)
  local clearColor = color
  if not clearColor then
    clearColor = playbit.graphics.activeContext.backgroundColor
  end

  @@ASSERT(clearColor == module.kColorWhite or clearColor == module.kColorBlack, "Only values of 0 (black) or 1 (white) are supported.")
  
  local c = clearColor == module.kColorWhite and playbit.graphics.colorWhite or playbit.graphics.colorBlack
  love.graphics.clear(c)
  playbit.graphics.lastClearColor = c
  playbit.graphics.updateContext()
end

-- "copy", "inverted", "XOR", "NXOR", "whiteTransparent", "blackTransparent", "fillWhite", or "fillBlack".
function module.setImageDrawMode(mode)
  -- TODO: save this to graphics context
  playbit.graphics.activeContext.drawMode = mode

  -- playbit.graphics.shader:send(playbit.graphics.MODE_KEY, playbit.graphics.activeContext.drawMode)

  if mode == module.kDrawModeCopy or mode == "copy" then
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeCopy)
  elseif mode == module.kDrawModeWhiteTransparent or mode == "whiteTransparent" then
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeWhiteTransparent)
  elseif mode == module.kDrawModeBlackTransparent or mode == "blackTransparent" then
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeBlackTransparent)
  elseif mode == module.kDrawModeFillWhite or mode == "fillWhite" then
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeFillWhite)
  elseif mode == module.kDrawModeFillBlack or mode == "fillBlack" then
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeFillBlack)
  elseif mode == module.kDrawModeXOR or mode == "XOR" then
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeXOR)
  elseif mode == module.kDrawModeNXOR or mode == "NXOR" then
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeNXOR)
  elseif mode == module.kDrawModeInverted or mode == "inverted" then
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeInverted)
  else
    print("[WARN] Draw mode '"..mode.."' is not yet implemented.")
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeCopy)
  end
end

function module.getImageDrawMode()
  return playbit.graphics.activeContext.drawMode
end

function module.drawCircleAtPoint(x, y, radius)
  setPatternDrawModeAndColor()

  love.graphics.circle("line", x, y, radius)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.fillCircleAtPoint(x, y, radius)
  setPatternDrawModeAndColor()

  love.graphics.circle("fill", x, y, radius)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.fillCircleInRect(xOrRect, y, width, height)
  if y == nil then
    -- We should only have a rect
    -- TODO-Playbit: Implement fillCircleInRect for a rect param
    error("playdate.graphics.fillCircleInRect() is not implemented for rect parameter")
  else
    local centerX = math.floor(xOrRect + width / 2)
    local centerY = math.floor(y + height / 2)
    local radius = math.floor(math.min(width, height) / 2)
    module.fillCircleAtPoint(centerX, centerY, radius)
  end
end

function module.drawCircleInRect(xOrRect, y, width, height)
  if y == nil then
    -- We should only have a rect
    -- TODO-Playbit: Implement drawCircleInRect for a rect param
    error("playdate.graphics.drawCircleInRect() is not implemented for rect parameter")
  else
    local centerX = math.floor(xOrRect + width / 2)
    local centerY = math.floor(y + height / 2)
    local radius = math.floor(math.min(width, height) / 2)
    module.drawCircleAtPoint(centerX, centerY, radius)
  end
end

function module.setLineWidth(width)
  playbit.graphics.activeContext.lineWidth = width
  love.graphics.setLineWidth(width)
end

function module.getLineWidth()
  return playbit.graphics.activeContext.lineWidth
end

function module.setStrokeLocation(location)
  playbit.graphics.activeContext.strokeLocation = location
  print("[WARN] playdate.graphics.setStrokeLocation() has no effect")
end

function module.getStrokeLocation()
  return playbit.graphics.activeContext.strokeLocation
end

function module.drawRect(x, y, width, height)
  setPatternDrawModeAndColor()
  
  love.graphics.rectangle("line", x, y, width, height)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.fillRect(x, y, width, height)
  setPatternDrawModeAndColor()
  
  love.graphics.rectangle("fill", x, y, width, height)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.drawRoundRect(x, y, width, height, radius)
  -- TODO: love's rectangle function doesn't draw the same way as Playdate's
  -- TODO-Playbit: Figure out what is different here
  print("[WARN] playdate.graphics.drawRoundRect() does not draw exactly the same as on Playdate.")

  setPatternDrawModeAndColor()
  
  love.graphics.rectangle("line", x, y, width, height, radius, radius)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.fillRoundRect(x, y, width, height, radius)
  -- TODO: love's rectangle function doesn't draw the same way as Playdate's
  -- TODO-Playbit: Figure out what is different here
  print("[WARN] playdate.graphics.fillRoundRect() does not draw exactly the same as on Playdate.")

  setPatternDrawModeAndColor()
  
  love.graphics.rectangle("fill", x, y, width, height, radius, radius)
  playbit.graphics.updateContext()
  
  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.fillEllipseInRect(xOrRect, y, width, height, startAngle, endAngle)
  setPatternDrawModeAndColor()

  -- TODO-Playbit: support all params
  if startAngle or endAngle then
    print("[WARN] playdate.graphics.fillEllipseInRect() does not support start or end angle.")
  end
  local radiusX = math.floor(width / 2)
  local radiusY = math.floor(height / 2)
  local centerX = xOrRect + radiusX
  local centerY = y + radiusY
  love.graphics.ellipse("fill", centerX, centerY, radiusX, radiusY)
  print("[WARN] playdate.graphics.fillEllipseInRect() does not draw exactly the same as on Playdate.")
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.drawLine(x1, y1, x2, y2)
  setPatternDrawModeAndColor()
  
  love.graphics.line(x1, y1, x2, y2)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.setLineCapStyle(style)
  playbit.graphics.activeContext.lineCapStyle = style
  print("[WARN] playdate.graphics.setLineCapStyle() has no effect")
end

-- TODO-Playbit: Handle just an arc parameter
function module.drawArc(x, y, radius, startAngle, endAngle)
  setPatternDrawModeAndColor()
  
  -- 0 degrees is 270 when drawing an arc on PD...
  startAngle = startAngle - 90
  endAngle = endAngle - 90
  
  if startAngle == endAngle then
    -- if startAngle and endAngle are the same, PD draws a full circle
    love.graphics.arc("line", "open", x, y, radius, math.rad(startAngle), math.rad(endAngle + 360), 16)
  elseif startAngle > endAngle then
    -- love2d adjusts for when the startAngle is larger, but PD does not, so we need to compensate
    love.graphics.arc("line", "open", x, y, radius, math.rad(startAngle), math.rad(endAngle + 360), 16)
  else
    love.graphics.arc("line", "open", x, y, radius, math.rad(endAngle), math.rad(startAngle), 16)
  end
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.fillTriangle(x1, y1, x2, y2, x3, y3)
  setPatternDrawModeAndColor()
  
  love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

-- TODO-Playbit: Support arbitrary number of points
function module.fillPolygon(x1, y1, x2, y2, x3, y3, x4, y4)
  setPatternDrawModeAndColor()
  
  love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.drawPixel(x, y)
  setPatternDrawModeAndColor()
  
  love.graphics.points(x, y)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.activeContext.drawMode)
end

function module.setFont(font, variant)
  if variant ~= nil then
    playbit.graphics.activeContext.fontFamily[variant] = font
  else
    playbit.graphics.activeContext.fontFamily[playdate.graphics.font.kVariantNormal] = font
  end
  love.graphics.setFont(font.data)
end

function module.setFontFamily(fontFamily)
  print("[WARN] playdate.graphics.setFontFamily() is not yet fully implemented.")
  -- TODO: should it only overwrite the values that are present in the new font family?
  playbit.graphics.activeContext.fontFamily = fontFamily
  local normalFont = fontFamily[playdate.graphics.font.kVariantNormal]
  if normalFont ~= nil then
    love.graphics.setFont(normalFont.data)
  end
end

function module.getFont(variant)
  if variant ~= nil then
    return playbit.graphics.activeContext.fontFamily[variant]
  else
    return playbit.graphics.activeContext.fontFamily[playdate.graphics.font.kVariantNormal]
  end
end

function module.getSystemFont(variant)
  error("[ERR] playdate.graphics.getSystemFont() is not yet implemented.")
end

function module.setFontTracking(pixels)
  error("[ERR] playdate.graphics.setFontTracking() is not yet implemented.")
end

function module.getTextSize(str, fontFamily, leadingAdjustment)
  @@ASSERT(fontFamily == nil, "[ERR] Parameter fontFamily is not yet implemented.")
  @@ASSERT(leadingAdjustment == nil, "[ERR] Parameter leadingAdjustment is not yet implemented.")

  local font = playbit.graphics.activeContext.fontFamily[playdate.graphics.font.kVariantNormal]
  return font:getWidth(str), font:getHeight()
end

-- playdate.graphics.drawTextInRect(str, x, y, width, height, [leadingAdjustment, [truncationString, [alignment, [font]]]]) 
function module.drawTextInRect(text, x, ...)
  local y, width, height, leadingAdjustment, truncationString, textAlignment, font
  if type(x) == "number" then
    y, width, height, leadingAdjustment, truncationString, textAlignment, font = select(1, ...)
  else
    -- rect
    error("[ERR] Support for the rect parameter is not yet implemented.")
  end

  font = font or playbit.graphics.activeContext.fontFamily[playdate.graphics.font.kVariantNormal]

  return font:_drawTextInRect(text, x, y, width, height, leadingAdjustment, truncationString, textAlignment)
end

-- TODO: handle the overloaded signature (text, rect, fontFamily, leadingAdjustment, wrapMode, alignment)
function module.drawText(text, x, y, width, height, fontFamily, leadingAdjustment, wrapMode, alignment)
  @@ASSERT(width == nil, "[ERR] Parameter width is not yet implemented.")
  @@ASSERT(height == nil, "[ERR] Parameter height is not yet implemented.")
  @@ASSERT(wrapMode == nil, "[ERR] Parameter wrapMode is not yet implemented.")
  @@ASSERT(alignment == nil, "[ERR] Parameter alignment is not yet implemented.")

  @@ASSERT(text ~= nil, "Text is nil")

  local font = playbit.graphics.activeContext.fontFamily[playdate.graphics.font.kVariantNormal]
  font:drawText(text, x, y, width, height, leadingAdjustment, wrapMode, alignmen)
  playbit.graphics.updateContext()
end

-- TODO: handle the overloaded signature (key, rect, language, leadingAdjustment)
function module.drawLocalizedText(key, x, y, width, height, language, leadingAdjustment, wrapMode, alignment)
  error("[ERR] playdate.graphics.drawLocalizedText() is not yet implemented.")
end

function module.getLocalizedText(key, language)
  error("[ERR] playdate.graphics.getLocalizedText() is not yet implemented.")
end

function module.drawTextAligned(text, x, y, alignment, leadingAdjustment)
  module.getFont():drawTextAligned(text, x, y, alignment, leadingAdjustment)
end

function module.drawLocalizedTextAligned(text, x, y, alignment, language, leadingAdjustment)
  error("[ERR] playdate.graphics.drawLocalizedTextAligned() is not yet implemented.")
end

-- TODO: handle the overloaded signature (text, rect, leadingAdjustment, truncationString, alignment, font, language)
function module.drawLocalizedTextInRect(text, x, y, width, height, leadingAdjustment, truncationString, alignment, font, language)
  error("[ERR] playdate.graphics.drawLocalizedTextInRect() is not yet implemented.")
end

function module.getTextSizeForMaxWidth(text, maxWidth, leadingAdjustment, font)
  error("[ERR] playdate.graphics.getTextSizeForMaxWidth() is not yet implemented.")
end

function module.imageWithText(text, maxWidth, maxHeight, backgroundColor, leadingAdjustment, truncationString, alignment, font)
  error("[ERR] playdate.graphics.imageWithText() is not yet implemented.")
end

function module.checkAlphaCollision(image1, x1, y1, flip1, image2, x2, y2, flip2)
  error("[ERR] playdate.graphics.checkAlphaCollision() is not yet implemented.")
end

local function applyContext(context)
  love.graphics.setCanvas({context.canvas, stencil=true})

  -- these values should always be set on a context
  module.setImageDrawMode(context.drawMode)
  module.setLineWidth(context.lineWidth)
  module.setBackgroundColor(context.backgroundColor)
  module.setStrokeLocation(context.strokeLocation)
  module.setLineCapStyle(context.lineCapStyle)
  module.setFontFamily(context.fontFamily)
  -- module.setDrawOffset(context.drawOffset.x, context.drawOffset.y)

  if context.color ~= nil then
    module.setColor(context.color, true)
  end
  if context.ditherType ~= nil then
    module.setDitherPattern(context.ditherAlpha, context.ditherType)
  elseif context.pattern ~= nil then
    module.setPattern(context.pattern)
  else
    module.clearPattern()
  end
  if context.clipRect ~= nil then
    module.setClipRect(context.clipRect)
  else
    module.clearClipRect()
  end
  -- TODO do these overwrite each other?
  if context.stencilImage ~= nil then
    module.setStencilImage(context.stencilImage, context.tileStencilImage)
  elseif context.stencilPattern ~= nil then
    module.setStencilPattern(context.stencilPattern)
  else
    module.clearStencil()
  end
end

function module.pushContext(image)
  local canvas
  
  -- if an image was passed in, then render it to a canvas
  if image then
    canvas = love.graphics.newCanvas(image:getSize())
    love.graphics.setCanvas({canvas, stencil=true})
    -- clear shader so that canvas is rendered normally
    love.graphics.setShader()
    -- always render pure white so its not tinted
    local r, g, b = love.graphics.getColor()
    love.graphics.setColor(1, 1, 1, 1)
    -- draw image to canvas
    love.graphics.draw(image.data, 0, 0)
    -- reset back to set color
    love.graphics.setColor(r, g, b, 1)
    love.graphics.setShader(playbit.graphics.shader)
  else
    canvas = playbit.graphics.canvas
  end

  if playbit.graphics.activeContext == nil then
    -- create the base context with default values
    playbit.graphics.activeContext = {
      canvas = canvas,
      image = image,
      drawMode = module.kDrawModeCopy,
      color = module.kColorBlack,
      backgroundColor = module.kColorWhite,
      lineWidth = 1,
      lineCapStyle = module.kLineCapStyleButt,
      strokeLocation = module.kStrokeCentered,
      drawOffset = {x = 0, y = 0},
      ditherPattern = nil,
      ditherAlpha = 0.0,
      pattern = nil,
      fontFamily = {},
      clipRect = nil,
      stencilImage = nil,
      tileStencilImage = false,
      stencilPattern = nil,
    }
  else
    table.insert(playbit.graphics.contextStack, playbit.graphics.activeContext)
    -- if a value doesn't exist in the current context, check the context above
    local mt = {
      __index = playbit.graphics.activeContext
    }
    playbit.graphics.activeContext = {
      canvas = canvas,
      image = image,
    }
    setmetatable(playbit.graphics.activeContext, mt)
  end

  applyContext(playbit.graphics.activeContext)
end

function module.popContext()
  @@ASSERT(#playbit.graphics.contextStack > 0, "No pushed context.")
  -- pop context
  playbit.graphics.activeContext = table.remove(playbit.graphics.contextStack)
  applyContext(playbit.graphics.activeContext)
end

function module.setDitherPattern(alpha, ditherType)
  if ditherType == nil then
    ditherType = playdate.graphics.image.kDitherTypeBayer8x8
  end

  playbit.graphics.activeContext.pattern = nil
  playbit.graphics.activeContext.ditherType = ditherType
  playbit.graphics.activeContext.ditherAlpha = alpha

  if ditherType == playdate.graphics.image.kDitherTypeNone then
    -- TODO not completely sure this is correct
    module.clearPattern()
    return
  end
  
  local thresholds = playbit.graphics.ditherThresholds[ditherType]

  @@ASSERT(thresholds ~= nil, "[ERR] Invalid dither type. Only ordered dither types are currently implemented.")

  local pattern = {}

  local numRows = #thresholds
  local numCols = #thresholds[1]
  
  -- always create an 8x8 pattern, even for smaller dither types
  for i = 1, 8 do
    for j = 1, 8 do
      local thresholdValue = thresholds[((i - 1) % numRows) + 1][((j - 1) % numCols) + 1]
      if alpha > thresholds[((i - 1) % numRows) + 1][((j - 1) % numCols) + 1] then
        table.insert(pattern, 0)
      else
        table.insert(pattern, 1)
      end
    end
  end
  
  playbit.graphics.shader:send("pattern", unpack(pattern))
end

function module.setClipRect(xOrRect, y, width, height)
  -- playbit.graphics.activeContext.clipRect = 
  print("[WARN] playdate.graphics.setClipRect() is not yet implemented.")
end

function module.getClipRect()
  error("[ERR] playdate.graphics.getClipRect() is not yet implemented.")
end

function module.setScreenClipRect(xOrRect, y, width, height)
  -- TODO: save this to graphics context
  print("[WARN] playdate.graphics.setScreenClipRect() has no effect.")
end

function module.getScreenClipRect()
  error("[ERR] playdate.graphics.getScreenClipRect() is not yet implemented.")
end

function module.clearClipRect()
  playbit.graphics.activeContext.clipRect = nil
  print("[WARN] playdate.graphics.clearScreenClipRect() has no effect.")
end

function module.setStencilImage(image, tile)
  playbit.graphics.activeContext.stencilImage = image
  playbit.graphics.activeContext.tileStencilImage = tile
  print("[WARN] playdate.graphics.setStencilImage() has no effect.")
end

-- TODO handle overloaded parameters
-- function module.setStencilPattern(row1, row2, row3, row4, row5, row6, row7, row8)
-- function module.setStencilPattern(level, ditherType)
function module.setStencilPattern(pattern)
  playbit.graphics.activeContext.pattern = pattern
  print("[WARN] playdate.graphics.setStencilPattern() has no effect.")
end

function module.clearStencil()
  playbit.graphics.activeContext.stencilImage = nil
  playbit.graphics.activeContext.tileStencilImage = false
  print("[ERR] playdate.graphics.clearStencil() is not yet implemented.")
end

function module.clearStencilImage()
  playbit.graphics.activeContext.stencilImage = nil
  playbit.graphics.activeContext.tileStencilImage = false
  print("[ERR] playdate.graphics.clearStencilImage() is not yet implemented.")
end