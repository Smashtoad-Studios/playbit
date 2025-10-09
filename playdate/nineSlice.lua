-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-graphics.nineSlice 

local module = {}
playdate.graphics.nineSlice = module

module.innerX = nil
module.innerY = nil

function module.new(imagePath, innerX, innerY, innerWidth, innerHeight)
  error("[ERR] playdate.graphics.nineSlice.new() is not yet implemented.")
end

function module:getSize()
  error("[ERR] playdate.graphics.nineSlice:getSize() is not yet implemented.")
end

function module:getMinSize()
  error("[ERR] playdate.graphics.nineSlice:getMinSize() is not yet implemented.")
end

function module:drawInRect(...)
  error("[ERR] playdate.graphics.nineSlice:drawInRect() is not yet implemented.")
end
