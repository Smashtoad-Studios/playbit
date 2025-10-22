local module = {}
playdate.geometry = module


-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-geometry.lineSegment 

local lineSegment = {}
playdate.geometry.lineSegment = lineSegment
lineSegment.meta = {}
lineSegment.meta.__index = lineSegment.meta

-- TODO-Playbit: Need to fully implement lineSegment
function lineSegment.new(x1, x2, y1, y2)
  local newLineSegment = setmetatable({}, lineSegment.meta)

  newLineSegment.x1 = x1
  newLineSegment.x2 = x2
  newLineSegment.y1 = y1
  newLineSegment.y2 = y2

  return newLineSegment
end

-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-geometry.point 

local point = {}
playdate.geometry.point = point
point.meta = {}
point.meta.__index = point.meta

-- TODO-Playbit: Need to fully implement point
function point.new(x, y)
  local newPoint = setmetatable({}, point.meta)

  newPoint.x = x
  newPoint.y = y

  return newPoint
end

function point.meta:offsetBy(dx, dy)
  return point.new(self.x + dx, self.y + dy)
end

-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-geometry.arc

local arc = {}
playdate.geometry.arc = arc
arc.meta = {}
arc.meta.__index = arc.meta

-- direction is true for clockwise
-- playdate.geometry.arc.new(x, y, radius, startAngle, endAngle, [direction])
function arc.new(x, y, radius, startAngle, endAngle, direction)
  local newArc = setmetatable({}, arc.meta)

  arc.x = x
  arc.y = y
  arc.radius = radius
  arc.startAngle = startAngle
  arc.endAngle = endAngle
  arc.direction = direction
  
  return newArc
end
