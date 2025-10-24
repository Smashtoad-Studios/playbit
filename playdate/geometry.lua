local module = {}
playdate.geometry = module


-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-geometry.lineSegment 

local lineSegment = {}
playdate.geometry.lineSegment = lineSegment
lineSegment.meta = {}
lineSegment.meta.__index = lineSegment.meta
lineSegment.meta.type = "lineSegment"

-- TODO-Playbit: Need to fully implement lineSegment
function lineSegment.new(x1, x2, y1, y2)
  local newLineSegment = setmetatable({}, lineSegment.meta)

  newLineSegment.startPoint = playdate.geometry.point.new(x1, y1)
  newLineSegment.endPoint = playdate.geometry.point.new(x2, y2)

  return newLineSegment
end

function lineSegment.meta:unpack()
  return self.startPoint.x, self.startPoint.y, self.endPoint.x, self.endPoint.y
end

function lineSegment.meta:length()
  local diff = self.endPoint - self.startPoint
  return math.sqrt(diff.x^2 + diff.y^2)
end

function lineSegment.meta:pointOnLine(distance, extend)
  local length = self:length()
  local percentage = distance / length
  if not extend then
    percentage = math.min(math.max(0, distance), 1)
  end
  return self.startPoint + (self.endPoint - self.startPoint) * percentage
end


-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-geometry.vector2D

local vector2d = {}
playdate.geometry.vector2d = vector2d
vector2d.meta = {}
vector2d.meta.__index = vector2d.meta
vector2d.meta.type = "vector2d"

vector2d.meta.__mul = function (a, b)
  -- TODO-Playbit: should also accept a vector (for dot product) or transform
  @@ASSERT(type(b) == "number", "[ERR] Invalid multiplication operation with a vector2d. Second operand must be a number.")
  return vector2d.new(a.x * b, a.y * b)
end

vector2d.meta.__div = function (a, b)
  @@ASSERT(type(b) == "number", "[ERR] Invalid division operation with a vector2d. Second operand must be a number.")
  return vector2d.new(a.x / b, a.y / b)
end

vector2d.meta.__add = function (a, b)
  @@ASSERT(b.type == "vector2d", "[ERR] Invalid addition operation with a vector2d. Can only add two vectors")
  return vector2d.new(a.x + b.x, a.y + b.y)
end

vector2d.meta.__sub = function (a, b)
  @@ASSERT(b.type == "vector2d", "[ERR] Invalid subtraction operation with a vector2d. Can only subtract two vectors")
  return vector2d.new(a.x - b.x, a.y - b.y)
end

vector2d.meta.__unm = function (a)
  return vector2d.new(-a.x, -a.y)
end

-- TODO-Playbit: Need to fully implement vector2d
function vector2d.new(x, y)
  local newVector2d = setmetatable({}, vector2d.meta)

  newVector2d.x = x
  newVector2d.y = y

  return newVector2d
end

function vector2d.meta:offsetBy(dx, dy)
  return vector2d.new(self.x + dx, self.y + dy)
end

-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#C-geometry.point 

local point = {}
playdate.geometry.point = point
point.meta = {}
point.meta.__index = point.meta
point.meta.type = "point"

point.meta.__add = function (a, b)
  @@ASSERT(b.type == "vector2d", "[ERR] Invalid addition operation with a point. Can only add point with vector")
  return point.new(a.x + b.x, a.y + b.y)
end

point.meta.__sub = function (a, b)
  @@ASSERT(b.type == "point", "[ERR] Invalid subtraction operation with a point. Can only subtract two points")
  return vector2d.new(a.x - b.x, a.y - b.y)
end

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
arc.meta.type = "arc"

-- direction is true for clockwise
-- playdate.geometry.arc.new(x, y, radius, startAngle, endAngle, [direction])
function arc.new(x, y, radius, startAngle, endAngle, direction)
  local newArc = setmetatable({}, arc.meta)
  newArc.x = x
  newArc.y = y
  newArc.radius = radius
  newArc.startAngle = startAngle
  newArc.endAngle = endAngle
  newArc.clockwise = direction
  return newArc
end

function arc.meta:length()
  local angle = self.endAngle - self.startAngle
  return math.abs(2 * math.pi * self.radius * angle / 360)
end

function arc.meta:pointOnArc(distance, extend)
  local length = self:length()
  local percentage = distance / length
  if not extend then
    percentage = math.min(math.max(0, distance), 1)
  end

  if not self.clockwise then
    percentage = percentage * -1
  end

  local angleRange = math.abs(self.endAngle - self.startAngle)
  local newAngle = math.rad(self.startAngle + angleRange * percentage)

  -- different from standard equations to handle screen space and angles starting at 0 in the -Y direction
  local newX = self.x + self.radius * math.sin(newAngle)
  local newY = self.y - self.radius * math.cos(newAngle)

  return point.new(newX, newY)
end
