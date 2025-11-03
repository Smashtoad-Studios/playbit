-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-graphics.nineSlice 

local module = {}
playdate.graphics.nineSlice = module
module.meta = {}
module.meta.__index = module.meta

-- TODO-Playbit: Need to implement nineSlice
function module.new(imagePath, innerX, innerY, innerWidth, innerHeight)
  local self = setmetatable({}, module.meta)

  self.width = 0
  self.height = 0

  local fileExtLoc, _ = string.find(imagePath, "%.png")
    if not fileExtLoc then
      imagePath = imagePath..".png"
    end
  local image = love.graphics.newImage(imagePath)
  image:setFilter("nearest", "nearest")  -- optional for crisp pixel edges

  local imageWidth, imageHeight = image:getWidth(), image:getHeight()

  local left = innerX
  local top = innerY

  -- Automatically derive right/bottom border sizes
  local right = imageWidth - (innerWidth + left)
  local bottom = imageHeight - (innerHeight + top)

  if right < 0 or bottom < 0 then
      error(string.format(
          "NineSlice.new: inner size too large for image (%dx%d), got innerWidth=%d, innerHeight=%d",
          imageWidth, imageHeight, innerWidth, innerHeight
      ))
  end

  self.image = image
  self.left, self.top, self.right, self.bottom = left, top, right, bottom
  self.iw, self.ih = imageWidth, imageHeight
  self.innerWidth, self.innerHeight = innerWidth, innerHeight

  -- Precompute all 9 quads
  self.quads = {
      -- row 1
      love.graphics.newQuad(0,                   0,                    left,          top,            image),
      love.graphics.newQuad(left,                0,                    innerWidth,    top,            image),
      love.graphics.newQuad(left + innerWidth,   0,                    right,         top,            image),
       
      -- row 2       
      love.graphics.newQuad(0,                   top,                  left,          innerHeight,    image),
      love.graphics.newQuad(left,                top,                  innerWidth,    innerHeight,    image),
      love.graphics.newQuad(left + innerWidth,   top,                  right,         innerHeight,    image),
        
      -- row 3        
      love.graphics.newQuad(0,                   top + innerHeight,    left,           bottom,        image),
      love.graphics.newQuad(left,                top + innerHeight,    innerWidth,     bottom,        image),
      love.graphics.newQuad(left + innerWidth,   top + innerHeight,    right,          bottom,        image),
  }

  return self
end

function module.meta:getSize()
  return self.width, self.height
end

function module.meta:getMinSize()
  return self.left + self.right + 1, self.top + self.bottom + 1
end

function module.meta:drawInRect(xOrRect, y, width, height)
  @@ASSERT(y ~= nil, "[ERR] playdate.graphics.nineSlice:drawInRect() is not implemented for rect parameter")

  self.width = width
  self.height = height

  local l, t, r, b = self.left, self.top, self.right, self.bottom
  local iw, ih = self.iw, self.ih

  -- Compute the destination rectangles for each section
  local destRects = {
      {xOrRect, y, l, t},                                 -- top-left
      {xOrRect + l, y, width - l - r, t},                     -- top
      {xOrRect + width - r, y, r, t},                         -- top-right

      {xOrRect, y + t, l, height - t - b},                     -- left
      {xOrRect + l, y + t, width - l - r, height - t - b},         -- center
      {xOrRect + width - r, y + t, r, height - t - b},             -- right

      {xOrRect, y + height - b, l, b},                         -- bottom-left
      {xOrRect + l, y + height - b, width - l - r, b},             -- bottom
      {xOrRect + width - r, y + height - b, r, b},                 -- bottom-right
  }

  -- always render pure white so its not tinted
  local r, g, b = love.graphics.getColor()
  love.graphics.setColor(1, 1, 1, 1)
  for i = 1, 9 do
      local dx, dy, dw, dh = destRects[i][1], destRects[i][2], destRects[i][3], destRects[i][4]
      local sx, sy, sw, sh = self.quads[i]:getViewport()
      love.graphics.draw(self.image, self.quads[i], dx, dy, 0, dw / sw, dh / sh)
  end
  love.graphics.setColor(r, g, b, 1)
  playbit.graphics.updateContext()
end
