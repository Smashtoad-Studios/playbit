local bit = require("bit")  -- LuaJIT's bitwise operations

local module = {}

module.kCollisionTypeSlide = "slide"
module.kCollisionTypeFreeze = "freeze"
module.kCollisionTypeOverlap = "overlap"
module.kCollisionTypeBounce = "bounce"

playdate.graphics.sprite = module

local mask_shader = love.graphics.newShader[[
   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }
]]

local function stencilImageFunction(img)
   love.graphics.setShader(mask_shader)
   love.graphics.draw(img, 0, 0)
   love.graphics.setShader(playbit.graphics.shader)
end

local meta = {}
meta.__index = meta
module.__index = meta
--[[
    TODO-Playbit: Not quite sure yet why this makes it work... but it does. It seems to
    be something with the metatable for "module" and the instance both getting overwritten
    in the object.lua when we extend from sprite, but I don't quite understand how this fixes it.
]]--
setmetatable(module, meta)

local allSprites = {}

function meta:init(imageOrTilemap)
    -- TODO-Playbit: Support timemaps
    if imageOrTilemap then
        self:setImage(imageOrTilemap)
    else
        self:setSize(0, 0)
    end
    self:moveTo(0, 0)
end

function module.new(imageOrTilemap)
    local sprite = setmetatable({}, meta)

    sprite.visible = true
    sprite.zIndex = 0
    sprite.collideRect = nil
    sprite.animator = nil
    sprite.canUpdate = true
    sprite.drawMode = playdate.graphics.kDrawModeCopy

    sprite:setRotation(0, 1)
    sprite:setCenter(0.5, 0.5)
    sprite:resetGroupMask()
    sprite:resetCollidesWithGroupsMask()

    sprite:init(imageOrTilemap)

    -- TODO-Playbit: Playdate does kinda do this... but they don't automatically draw, so it's slightly different
    -- table.insert(allSprites, sprite)
    return sprite
end

function module.baseObject()
    return module.new()
end

function module.performOnallSprites(func)
    for i = 1, #allSprites do
        func(allSprites[i])
    end
end

function module.spriteWithText(text, maxWidth, maxHeight, backgroundColor, leadingAdjustment, truncationString, alignment, font)
	error("spriteWithText not implemented!")
end

function meta:copy()
    local newSprite = module.new(self.image)
    newSprite:moveTo(self.x, self.y)
    newSprite:setCenter(self.centerX, self.centerY)
    newSprite:setRotation(self.rotation, self.scaleX, self.scaleY)
    newSprite:setZIndex(self.zIndex)
    newSprite:setVisible(self.visible)
    newSprite:setImageDrawMode(self.drawMode)
    newSprite:setUpdatesEnabled(self.canUpdate)

    --TODO-Playbit: double check what properties are copied on Playdate
    --TODO-Playbit: copy collision group properties?
    --TODO-Playbit: copy animator?

    return newSprite
end

function meta:setImage(image)
    self.image = image

    if not image then
        self:setSize(0, 0)
    else
        self:setSize(image:getSize())
    end
end

function meta:getImage()
    return self.image
end

function meta:setImageDrawMode(mode)
    self.drawMode = mode
    print("[WARN] playdate.graphics.sprite:setImageDrawMode() is not fully tested.")
end

function meta:setSize(w, h)
    self.width, self.height = w, h
end

function meta:getSize()
    return self.width, self.height
end

function meta:moveTo(x, y)
    self.x, self.y = x, y
end

function meta:getPosition()
    return self.x, self.y
end

function meta:moveBy(x, y)
    self:moveTo(self.x + x, self.y + y)
end

function meta:add()
    if not self.added then
        table.insert(allSprites, self)
        self.added = true
        table.sort(allSprites, function(a, b) return a.zIndex < b.zIndex end)
    end
end

function meta:remove()
    for i, sprite in ipairs(allSprites) do
        if sprite == self then
            table.remove(allSprites, i)
            self.added = false
            return
        end
    end
end

function meta:setZIndex(index)
    self.zIndex = index
    table.sort(allSprites, function(a, b) return a.zIndex < b.zIndex end)
end

function meta:getZIndex()
    return self.zIndex
end

function meta:setStencilImage(stencil)
    -- print("[WARN] playdate.graphics.sprite:setStencilImage() is not fully tested.")
    self.stencilImage = stencil
end

function meta:clearStencil()
    -- print("[WARN] playdate.graphics.sprite:clearStencil() is not fully tested.")
    self.stencilImage = nil
end

function meta:setAnimator(animator)
    animator:currentValue()
    self.animator = animator
end

function meta:removeAnimator(animator)
    self.animator = nil
end

function meta:markDirty()
    print("[WARN] playdate.graphics.sprite:markDirty() is not yet implemented.")
end

function meta:setCollideRect(x, y, w, h)
    self.collideRect = { x = x, y = y, width = w, height = h }
end

function meta:getCollideRect()
    return self.collideRect
end

function meta:getCollideBounds()
end

function meta:setCollisionResponse(response)
    self.collisionResponse = response
end

function meta:setGroups(groups)
    self.groupMask = 0x00000000

    for _, group in ipairs(groups) do
        if group >= 1 and group <= 32 then
            self.groupMask = bit.bor(self.groupMask, bit.lshift(1, group - 1))
        end
    end
end

function meta:setCollidesWithGroups(groups)
    self.collidesWithGroupsMask = 0x00000000
    for _, group in ipairs(groups) do
        if group >= 1 and group <= 32 then
            self.collidesWithGroupsMask = bit.bor(self.collidesWithGroupsMask, bit.lshift(1, group - 1))
        end
    end
end

function meta:setGroupMask(mask)
    self.groupMask = mask
end

function meta:getGroupMask()
    return self.groupMask
end

function meta:setCollidesWithGroupsMask(mask)
    self.collidesWithGroupsMask = mask
end

function meta:getCollidesWithGroupsMask()
    return self.collidesWithGroupsMask
end

function meta:resetGroupMask()
    self.groupMask = 0x00000000
end

function meta:resetCollidesWithGroupsMask()
    self.collidesWithGroupsMask = 0x00000000
end

function meta:setClipRect(xOrRect, y, width, height)
    -- TODO-Playbit: Implement clip rect
    print("[WARN] playdate.graphics.sprite setClipRect() does not yet have any effect.")
end

function meta:clearCollideRect()
    self.collideRect = nil
end

function meta:setIgnoresDrawOffset(flag)
    -- TODO-Playbit: Implement ignore draw offset
    print("[WARN] playdate.graphics.sprite setIgnoresDrawOffset() does not yet have any effect.")
    self.ignoresDrawOffset = flag
end

function meta:canCollideWith(other)
    -- sprites can collide if they both have the default group mask
    if self.collidesWithGroupsMask == 0x00000000 and other.groupMask == 0x00000000 then
        return true
    end
    return bit.band(self.collidesWithGroupsMask, other.groupMask) ~= 0
end


local function checkAABBCollision(self, other)
    if not self:canCollideWith(other) then return false end
    if not self.collideRect or not other.collideRect then return false end
    return self.x + self.collideRect.x < other.x + other.collideRect.x + other.collideRect.width and
            self.x + self.collideRect.x + self.collideRect.width > other.x + other.collideRect.x and
            self.y + self.collideRect.y < other.y + other.collideRect.y + other.collideRect.height and
            self.y + self.collideRect.y + self.collideRect.height > other.y + other.collideRect.y
end


-- **Entry and Exit Calculation**
-- Finds when the moving sprite **enters** and **exits** collision on an axis.
local function entryExit(t0, t1, ds, sMin, sMax, oMin, oMax)
    -- If no movement along this axis, check for overlap (static collision case)
    if ds == 0 then
        if sMin >= oMax or sMax <= oMin then return nil, nil end
        return 0, 1  -- Overlapping, collision lasts full movement range
    end

    -- Compute time when movement **enters** and **exits** collision on this axis
    local tEntry = (oMin - sMax) / ds  -- Entry time (when first touching)
    local tExit = (oMax - sMin) / ds  -- Exit time (when leaving)

    -- Ensure proper ordering (entry should always be before exit)
    if tEntry > tExit then tEntry, tExit = tExit, tEntry end

    -- Return max entry time and min exit time (valid range for collision)
    return math.max(t0, tEntry), math.min(t1, tExit)
end

-- **Swept AABB Collision Detection**
-- This function calculates the **time of impact (ti)** for a moving sprite
-- and determines the **collision normal** (direction of impact).
-- It prevents tunneling by checking **when** the collision happens (0-1 scale).
local function sweptAABB(self, other, startX, startY, endX, endY)
    if not self:canCollideWith(other) then return nil, 0, 0 end
    if not self.collideRect or not other.collideRect then return nil, 0, 0 end

    -- Compute movement vector
    local dx, dy = endX - startX, endY - startY

    -- Default values:
    local ti = 1  -- Time of impact (1 = full movement allowed, 0 = instant collision)
    local normalX, normalY = 0, 0  -- Collision normal

    -- **Check Collisions on X and Y Axis Separately**
    -- Loop through **X and Y axes**, applying `entryExit()` to both
    for _, axis in ipairs({ { "x", dx }, { "y", dy } }) do
        local key, ds = axis[1], axis[2]

        -- Get bounds of moving sprite
        local sMin, sMax = startX + self.collideRect.x, startX + self.collideRect.x + self.collideRect.width
        -- Get bounds of colliding object
        local oMin, oMax = other.x + other.collideRect.x, other.x + other.collideRect.x + other.collideRect.width

        -- Adjust values for Y axis if needed
        if key == "y" then
            sMin, sMax = startY + self.collideRect.y, startY + self.collideRect.y + self.collideRect.height
            oMin, oMax = other.y + other.collideRect.y, other.y + other.collideRect.y + other.collideRect.height
        end

        -- **Get the earliest and latest possible collision times for this axis**
        local tEntry, tExit = entryExit(0, 1, ds, sMin, sMax, oMin, oMax)

        -- **Check if collision is valid**
        -- If there is **no collision** (entry after exit), return no impact
        if not tEntry or tEntry > tExit or tExit < 0 or tEntry > 1 then
            return nil, 0, 0  -- No collision
        end

        -- **Track the earliest collision (smallest `ti`)**
        if tEntry < ti then
            ti = tEntry  -- Update the earliest collision time

            -- Set collision normal:
            -- - If movement is in positive direction, normal is `-1`
            -- - If movement is in negative direction, normal is `1`
            if key == "x" then
                normalX = (dx > 0) and -1 or 1
            else
                normalY = (dy > 0) and -1 or 1
            end
        end
    end

    return ti, normalX, normalY
end


function meta:checkCollisions(goalX, goalY)
    local collisions = {}
    local moveX, moveY = goalX - self.x, goalY - self.y
    local ti = 1
    local normalX, normalY = 0, 0
    local overlaps = false

    -- already overlapping another sprite?
    for _, other in ipairs(allSprites) do
        if other ~= self and checkAABBCollision(self, other) then
            overlaps = true
            break
        end
    end

    -- Check for possible future collisions
    for _, other in ipairs(allSprites) do
        if other ~= self then

            local tImpact, nx, ny = sweptAABB(self, other, self.x, self.y, goalX, goalY)

            if tImpact then
                ti = math.min(ti, tImpact)
                normalX, normalY = nx, ny
                table.insert(collisions, {
                    sprite = self,
                    other = other,
                    type = self.collisionResponse,
                    overlaps = overlaps,
                    ti = tImpact,
                    move = { x = moveX * ti, y = moveY * ti },
                    normal = { x = normalX, y = normalY },
                    touch = { x = self.x + moveX * ti, y = self.y + moveY * ti },
                    spriteRect = self.collideRect,
                    otherRect = other.collideRect
                })
            end
        end
    end

    return goalX, goalY, collisions, #collisions
end

function meta:overlappingSprites()
    local overlapping = {}
    for _, other in ipairs(allSprites) do
        if other ~= self and checkAABBCollision(self, other) then
            overlapping[#overlapping + 1] = other
        end
    end
    return overlapping
end

-- function meta:moveWithCollisions(goalX, goalY)
--     local actualX, actualY, collisions, count = self:checkCollisions(goalX, goalY)
    
--     -- Move only if there were no collisions
--     if count == 0 or self.collisionResponse == "overlap" then
--         self:moveTo(actualX, actualY)
--     end

--     return actualX, actualY, collisions, count
-- end

function meta:moveWithCollisions(goalX, goalY)
    local actualX, actualY, collisions, count = self:checkCollisions(goalX, goalY)

    if count == 0 then
        self:moveTo(goalX, goalY)
        return actualX, actualY, collisions, count
    end

    -- Iterate through each collision
    for _, col in ipairs(collisions) do
        local other = col.other
        local response = "freeze"  -- Default collision behavior

        -- **Check if `collisionResponse` is a function or string**
        if type(self.collisionResponse) == "function" then
            response = self:collisionResponse(other) or "freeze"  -- Call function with `other`
        elseif type(self.collisionResponse) == "string" then
            response = self.collisionResponse
        end

        -- **Handle Different Collision Types**
        if response == "slide" then
            -- **Slide:** Stop movement in the direction of collision
            if col.normal.x ~= 0 then actualX = col.touch.x end
            if col.normal.y ~= 0 then actualY = col.touch.y end

        elseif response == "freeze" then
            -- **Freeze:** Stop movement completely
            actualX, actualY = self.x, self.y  -- Reset to original position

        elseif response == "overlap" then
            -- **Overlap:** Ignore collision, allow full movement
            actualX, actualY = goalX, goalY

        elseif response == "bounce" then
            -- **Bounce:** Reflect movement based on collision normal
            local bounceX = (goalX - self.x) * (1 - math.abs(col.normal.x) * 2)
            local bounceY = (goalY - self.y) * (1 - math.abs(col.normal.y) * 2)
            actualX = self.x + bounceX
            actualY = self.y + bounceY
        end
    end

    -- Move sprite to final position based on response
    self:moveTo(actualX, actualY)
    return actualX, actualY, collisions, count
end

function meta:setScale(scale, yScale)
    self.scaleX = scale
    self.scaleY = yScale or scale
end

function meta:getScale()
    return self.scaleX, self.scaleY
end

function meta:setRotation(angle, scale, yScale)
    self.rotation = angle

    if (scale) then
        self:setScale(scale, yScale)
    end
end

function meta:getRotation()
    return self.rotation
end

function meta:setImageDrawMode(mode)
    self.drawMode = mode
end

function meta:setVisible(flag)
    self.visible = flag
end

function meta:isVisible()
    return self.visible
end

function meta:setCenter(x, y)
    self.centerX = x
    self.centerY = y
end

function meta:getCenter()
    return self.centerX, self.centerY
end

function meta:getCenterPoint()
    return self.x - self.width * self.centerX, self.y - self.height * self.centerY
end

function meta:update()
    -- TODO-Playbit: What does a regular sprite do in its update? Anything?
end

function meta:setUpdatesEnabled(flag)
    self.canUpdate = flag
end

function meta:updatesEnabled()
    return self.canUpdate
end

function meta:draw()
    if self.visible and self.image then
        
        if self.drawMode == playdate.graphics.kDrawModeXOR or self.drawMode == playdate.graphics.kDrawModeNXOR then
            playbit.graphics.updateFramebufferCanvas()
        end
        
        if self.drawMode then
            playbit.graphics.shader:send(playbit.graphics.MODE_KEY, self.drawMode)
        end
        
        if self.stencilImage then
            love.graphics.stencil(function () stencilImageFunction(self.stencilImage.data) end, "replace", 1)
            love.graphics.setStencilTest("greater", 0)
        end

        -- always render pure white so its not tinted
        local r, g, b = love.graphics.getColor()
        love.graphics.setColor(1, 1, 1, 1)

        -- TODO check to see if sprites are being drawed at fractional pixel values. If so, round them.
        love.graphics.draw(self.image.data,
            self.x, self.y,
            math.rad(self.rotation),
            self.scaleX, self.scaleY,
            self.width * self.centerX, self.height * self.centerY
        )
        love.graphics.setColor(r, g, b, 1)
        playbit.graphics.updateContext()

        love.graphics.setStencilTest()

        if self.drawMode then
            playbit.graphics.shader:send(playbit.graphics.MODE_KEY, playbit.graphics.activeContext.drawMode)
        end
    end
end

-- TODO-Playbit: This needs to be named update()
function module.updateAll()
    -- TODO: Should this always be white?
    love.graphics.clear(playbit.graphics.COLOR_WHITE)
    for _, spr in ipairs(allSprites) do
        if spr.canUpdate then
            if spr.animator then
                local p = spr.animator:currentValue()
                spr:moveTo(p.x, p.y)
                if spr.animator:ended() then
                    spr.animator = nil
                end
            end
            spr:update()
            spr:draw()
        end
    end
end

function module.drawAll()
    for _, spr in ipairs(allSprites) do
        spr:draw()
    end
end

function module.removeAll()
    for _, spr in ipairs(allSprites) do
        spr.added = false
    end
    allSprites = {}
end

function module.removeSprites(spritesToRemove)
    for _, spr in ipairs(spritesToRemove) do
        -- TODO-Playbit: is there a better way to do this that won't loop through the allSprites list for each sprite?
        spr:remove()
    end
end

function module.setBackgroundDrawingCallback(callback)
    module.backgroundCallback = callback
end

function module.drawBackground()
    if module.backgroundCallback then
        module.backgroundCallback()
    end
end

return module
