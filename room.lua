Room = {}
Room.__index = Room

function Room:new(id)
  local room = {
    id=id,
    neighbours = {},
    center = {},
    hasStaircase = false
    }
  
  setmetatable(room, Room)
  
  return room
end

-- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- 

function Room:addNeighbour(other)
    add(self.neighbours, other)
end
  
-- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- 

function Room:hasNeighbours()
    return count(self.neighbours)>1
end

-- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- 

function Room:setCenter(r,c)
  self.center = {r, c}
end

-- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- 

function Room:distanceTo(other)
  -- returns distance from self to other room's center.
    local op1 = (self.center[1]-other.center[1])
    local op2 = (self.center[2]-other.center[2])

    return sqrt(abs(op1*op1)+abs(op2*op2))
end