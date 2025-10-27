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

module.kColorWhite = 1
module.kColorBlack = 0
-- TODO: clear and XOR support

kTextAlignment = {
	left = 0,
	right = 1,
	center = 2,
}

function module.setDrawOffset(x, y)
  playbit.graphics.drawOffset.x = x
  playbit.graphics.drawOffset.y = y
  love.graphics.pop()
  love.graphics.push()
  love.graphics.translate(x, y)
end

function module.getDrawOffset()
  return playbit.graphics.drawOffset.x, playbit.graphics.drawOffset.y
end

function module.setBackgroundColor(color)
  -- TODO: save this to graphics context
  @@ASSERT(color == 1 or color == 0, "Only values of 0 (black) or 1 (white) are supported.")
  playbit.graphics.backgroundColorIndex = color
  if color == 1 then
    playbit.graphics.backgroundColor = playbit.graphics.colorWhite
  else
    playbit.graphics.backgroundColor = playbit.graphics.colorBlack
  end
  -- don't actually set love's bg color here since doing so immediately sets the color, and this is not consistent with PD
end

function module.getBackgroundColor()
  error("playdate.graphics.getBackgroundColor() is not implemented")
end


function module.setColor(color)
  -- TODO: save this to graphics context
  @@ASSERT(color == 1 or color == 0, "Only values of 0 (black) or 1 (white) are supported.")
  playbit.graphics.drawColorIndex = color
  -- when drawing without a pattern, we must flip the pattern mask for white/black because of the way the shader draws patterns
  if color == 1 then
    local c = playbit.graphics.colorWhite
    playbit.graphics.drawColor = c
    -- reset pattern, as per PD behavior
    module.setPattern({0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff})
    love.graphics.setColor(c[1], c[2], c[3], c[4])
  else
    local c = playbit.graphics.colorBlack
    playbit.graphics.drawColor = c
    -- reset pattern, as per PD behavior
    module.setPattern({0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00})
    love.graphics.setColor(c[1], c[2], c[3], c[4])
  end
end

function module.getColor()
  error("playdate.graphics.getColor() is not implemented")
end

function module.setPattern(pattern)
  -- TODO: save this to graphics context
  playbit.graphics.drawPattern = pattern

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
  if not color then
    local c = playbit.graphics.backgroundColor
    love.graphics.clear(c[1], c[2], c[3], c[4])
    playbit.graphics.lastClearColor = c
  else
    @@ASSERT(color == 1 or color == 0, "Only values of 0 (black) or 1 (white) are supported.")
    if color == 1 then
      local c = playbit.graphics.colorWhite
      love.graphics.clear(c[1], c[2], c[3], c[4])
      playbit.graphics.lastClearColor = c
    else
      local c = playbit.graphics.colorBlack
      love.graphics.clear(c[1], c[2], c[3], c[4])
      playbit.graphics.lastClearColor = c
    end
  end
  playbit.graphics.updateContext()
end

-- "copy", "inverted", "XOR", "NXOR", "whiteTransparent", "blackTransparent", "fillWhite", or "fillBlack".
function module.setImageDrawMode(mode)
  -- TODO: save this to graphics context
  playbit.graphics.drawMode = mode

  -- playbit.graphics.shader:send(playbit.graphics.MODE_KEY, playbit.graphics.drawMode)

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
  -- elseif mode == module.kDrawModeXOR or mode == "XOR" then
  --   print("[WARN] Draw mode 'XOR' is not yet implemented. Draws as inverted.")
  --   playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeXOR)
  -- elseif mode == module.kDrawModeNXOR or mode == "NXOR" then
  --   print("[WARN] Draw mode 'NXOR' is not yet implemented. Draws as inverted.")
  --   playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeNXOR)
  elseif mode == module.kDrawModeInverted or mode == "inverted" then
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeInverted)
  else
    print("[WARN] Draw mode '"..mode.."' is not yet implemented.")
    playbit.graphics.shader:send(playbit.graphics.MODE_KEY, module.kDrawModeCopy)
  end
end

function module.getImageDrawMode()
  error("playdate.graphics.getImageDrawMode() is not implemented")
end

function module.drawCircleAtPoint(x, y, radius)
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

  love.graphics.circle("line", x, y, radius)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.drawMode)
end

function module.fillCircleAtPoint(x, y, radius)
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

  love.graphics.circle("fill", x, y, radius)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.drawMode)
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
  -- TODO: save this to graphics context
  love.graphics.setLineWidth(width)
end

function module.getLineWidth()
  error("playdate.graphics.getLineWidth() is not implemented")
end

function module.setStrokeLocation(location)
  error("playdate.graphics.setStrokeLocation() is not implemented")
end

function module.getStrokeLocation()
  error("playdate.graphics.getStrokeLocation() is not implemented")
end

function module.drawRect(x, y, width, height)
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

  love.graphics.rectangle("line", x, y, width, height)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.drawMode)
end

function module.fillRect(x, y, width, height)
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

  love.graphics.rectangle("fill", x, y, width, height)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.drawMode)
end

function module.drawRoundRect(x, y, width, height, radius)
  -- TODO: love's rectangle function doesn't draw the same way as Playdate's
  -- TODO-Playbit: Figure out what is different here
  print("[WARN] playdate.graphics.drawRoundRect() does not draw exactly the same as on Playdate.")
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

  love.graphics.rectangle("line", x, y, width, height, radius, radius)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.drawMode)
end

function module.fillRoundRect(x, y, width, height, radius)
  -- TODO: love's rectangle function doesn't draw the same way as Playdate's
  -- TODO-Playbit: Figure out what is different here
  print("[WARN] playdate.graphics.fillRoundRect() does not draw exactly the same as on Playdate.")
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

  love.graphics.rectangle("fill", x, y, width, height, radius, radius)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.drawMode)
end

function module.fillEllipseInRect(xOrRect, y, width, height, startAngle, endAngle)
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
end

function module.drawLine(x1, y1, x2, y2)
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

  love.graphics.line(x1, y1, x2, y2)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.drawMode)
end

function module.setLineCapStyle(style)
  error("[ERR] playdate.graphics.setLineCapStyle() is not yet implemented.")
end

-- TODO-Playbit: Handle just an arc parameter
function module.drawArc(x, y, radius, startAngle, endAngle)
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

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

  module.setImageDrawMode(playbit.graphics.drawMode)
end

function module.fillTriangle(x1, y1, x2, y2, x3, y3)
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

  love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.drawMode)
end

-- TODO-Playbit: Support arbitrary number of points
function module.fillPolygon(x1, y1, x2, y2, x3, y3, x4, y4)
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

  love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.drawMode)
end

function module.drawPixel(x, y)
  playbit.graphics.shader:send(playbit.graphics.MODE_KEY, 8)

  love.graphics.points(x, y)
  playbit.graphics.updateContext()

  module.setImageDrawMode(playbit.graphics.drawMode)
end

function module.setFont(font)
  playbit.graphics.activeFont = font
  love.graphics.setFont(font.data)
end

function module.setFontFamily(fontFamily)
  -- TODO: save this to graphics context
  print("[WARN] playdate.graphics.setFontFamily() is not yet implemented.")
  playbit.graphics.activeFont = fontFamily[playdate.graphics.font.kVariantNormal]
  love.graphics.setFont(fontFamily[playdate.graphics.font.kVariantNormal].data)
end

function module.getFont()
  return playbit.graphics.activeFont
end

function module.getTextSize(str, fontFamily, leadingAdjustment)
  @@ASSERT(fontFamily == nil, "[ERR] Parameter fontFamily is not yet implemented.")
  @@ASSERT(leadingAdjustment == nil, "[ERR] Parameter leadingAdjustment is not yet implemented.")

  local font = playbit.graphics.activeFont
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

  font = font or playbit.graphics.activeFont

  return font:_drawTextInRect(text, x, y, width, height, leadingAdjustment, truncationString, textAlignment)
end

-- TODO: handle the overloaded signature (text, rect, fontFamily, leadingAdjustment, wrapMode, alignment)
function module.drawText(text, x, y, width, height, fontFamily, leadingAdjustment, wrapMode, alignment)
  @@ASSERT(width == nil, "[ERR] Parameter width is not yet implemented.")
  @@ASSERT(height == nil, "[ERR] Parameter height is not yet implemented.")
  @@ASSERT(wrapMode == nil, "[ERR] Parameter wrapMode is not yet implemented.")
  @@ASSERT(alignment == nil, "[ERR] Parameter alignment is not yet implemented.")

  @@ASSERT(text ~= nil, "Text is nil")
  local font = playbit.graphics.activeFont
  font:drawText(text, x, y, fontFamily, leadingAdjustment)
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

-- TODO: contexts still need to track any modifications to the context, e.g. line width, color, draw mode
function module.pushContext(image)
  if not image then
    -- push context
    table.insert(playbit.graphics.contextStack, {_canvas = playbit.graphics.canvas})
    -- update current render target
    love.graphics.setCanvas({playbit.graphics.canvas, stencil=true})
    return
  end

  -- create canvas if it doesn't exist
  if not image._canvas then
    -- render the image to the new canvas
    image._canvas = love.graphics.newCanvas(image:getSize())
    love.graphics.setCanvas({image._canvas, stencil=true})
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
  end
  
  -- push context
  table.insert(playbit.graphics.contextStack, image)

  -- update current render target
  love.graphics.setCanvas({image._canvas, stencil=true})
end

function module.popContext()
  @@ASSERT(#playbit.graphics.contextStack > 0, "No pushed context.")

  -- pop context
  table.remove(playbit.graphics.contextStack)
  -- update current render target
  if #playbit.graphics.contextStack == 0 then
    love.graphics.setCanvas({playbit.graphics.canvas, stencil=true})
  else
    local activeContext = playbit.graphics.contextStack[#playbit.graphics.contextStack]
    love.graphics.setCanvas({activeContext._canvas, stencil=true})
  end
end

function module.setDitherPattern()
  -- TODO: save this to graphics context
  print("[ERR] playdate.graphics.setDitherPattern() is not yet implemented.")
end

function module.setClipRect(xOrRect, y, width, height)
  -- TODO: save this to graphics context
  print("[WARN] playdate.graphics.setClipRect() is not yet implemented.")
end

function module.getClipRect()
  -- TODO: save this to graphics context
  error("[ERR] playdate.graphics.getClipRect() is not yet implemented.")
end

function module.setScreenClipRect(xOrRect, y, width, height)
  -- TODO: save this to graphics context
  error("[ERR] playdate.graphics.setScreenClipRect() is not yet implemented.")
end

function module.getScreenClipRect()
  -- TODO: save this to graphics context
  error("[ERR] playdate.graphics.getScreenClipRect() is not yet implemented.")
end

function module.clearScreenClipRect()
  -- TODO: save this to graphics context
  error("[ERR] playdate.graphics.clearScreenClipRect() is not yet implemented.")
end

function module.setStencilImage(image, tile)
  -- TODO: save this to graphics context
  error("[ERR] playdate.graphics.setStencilImage() is not yet implemented.")
end

function module.setStencilPattern(pattern)
  -- TODO: save this to graphics context
  error("[ERR] playdate.graphics.setStencilPattern() is not yet implemented.")
end

function module.setStencilPattern(row1, row2, row3, row4, row5, row6, row7, row8)
  -- TODO: save this to graphics context
  error("[ERR] playdate.graphics.setStencilPattern() is not yet implemented.")
end

function module.setStencilPattern(level, ditherType)
  -- TODO: save this to graphics context
  error("[ERR] playdate.graphics.setStencilPattern() is not yet implemented.")
end

function module.clearStencil()
  -- TODO: save this to graphics context
  error("[ERR] playdate.graphics.clearStencil() is not yet implemented.")
end

function module.clearStencilImage()
  -- TODO: save this to graphics context
  error("[ERR] playdate.graphics.clearStencilImage() is not yet implemented.")
end