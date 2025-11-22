-- docs: https://sdk.play.date/2.6.2/Inside%20Playdate.html#M-json

local module = {}
json = module

local jsonParser = require("json.json")

function module.decode(json)
  return jsonParser.decode(json)
end

-- TODO: handle overloaded signature (file) - where `file` is a playdate.file.file
function module.decodeFile(path)
  local contents, size = love.filesystem.read(path)
  return jsonParser.decode(contents)
end

function module.encode(table)
  playbit.logger.printError("json.encode() is not yet implemented.")
end

function module.encodePretty(table)
  playbit.logger.printError("json.encodePretty() is not yet implemented.")
end

function module.encodeToFile(path, pretty, table)
  -- If tthe table is passed in as the second argument set the table
  if type(pretty) == "table" then
    table = pretty
  end

  -- Extract the directory path from the full file path
  local directory = path:match("(.*/)")

  -- If a directory is in the path, recursively create the directories if they do not exist
  if directory then
    love.filesystem.createDirectory(directory)
  end

  local success, message = love.filesystem.write(path, jsonParser.encode(table))
end
