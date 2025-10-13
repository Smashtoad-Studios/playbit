-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-graphics.nineSlice 

local module = {}
playdate.graphics.nineSlice = module
module.meta = {}
module.meta.__index = module.meta

-- TODO-Playbit: Need to implement nineSlice
function module.new(imagePath, innerX, innerY, innerWidth, innerHeight)
  print("[ERR] playdate.graphics.nineSlice.new() is not yet implemented.")
  local nineSlice = setmetatable({}, module.meta)
  return nineSlice
end

function module.meta:getSize()
  print("[ERR] playdate.graphics.nineSlice:getSize() is not yet implemented.")
  return 0
end

function module.meta:getMinSize()
  print("[ERR] playdate.graphics.nineSlice:getMinSize() is not yet implemented.")
  return 0
end

function module.meta:drawInRect(...)
  print("[ERR] playdate.graphics.nineSlice:drawInRect() is not yet implemented.")
end
