local random = math.random
local floor = math.floor
local ceil = math.ceil
local min = math.min
local max = math.max
local insert = table.insert

--seed = os.time()
--math.randomseed(seed)

Dungeon = {
    Tile_Types = {
        Empty = 0x00,
        Soil = 0x01,
        SoilRocks = 0x02,
        Water = 0x03,
        --- Above 0x20 values are non walkable types (i.e walls)
        Wall = 0x20,
        InnerWall = 0x21
    },
    Type_Prints = {

    }
}
Dungeon.__index = Dungeon
Dungeon.MIN_ROOM_SIZE = 3

function Dungeon:new(height, width)
    if height < 10 or width < 10 then printh("Dungeon must have height>=10, width>=10") end
    
    local dungeon = { 
      height=height,
      width=width,
      matrix={},
      rooms = {},
      entrances = {},
      staircases = {},
      rootRoom=nil,
      endRoom=nil
    }
    dungeon.maxRoomSize = ceil(min(height, width)/10)+5
    dungeon.maxRooms = ceil(max(height, width)/Dungeon.MIN_ROOM_SIZE)
    -- dungeon amount of random tiles built when generating corridors:
    dungeon.scatteringFactor = ceil(max(height,width)/Dungeon.maxRoomSize)
    
    setmetatable(dungeon, Dungeon)
    return dungeon
end

function Dungeon:initMap()

    -- Create void
    for i=-1,self.height+1 do
        self.matrix[i] = {}
        for j=0,self.width+1 do
            self.matrix[i][j] = Dungeon.Tile_Types.Empty
        end
    end

    self:addWalls(0, 0, self.height+1, self.width+1)
end 

function Dungeon:printMap()
    for i=-1,self.height+1 do
        self.matrix[i] = {}
        for j=0,self.width+1 do
            printh(self.matrix[i][j]) -- TODO
        end
    end
end

function Dungeon:getTile(r, c)
    return self.matrix[r][c]
  end

function Dungeon:generateRooms()
    for i = 1,self.maxRooms do
        self:generateRoom()
      end
end

function Dungeon:generateRoom()
    -- Will randomly place rooms across tiles (no overlapping).
    
    local startRow = random(1, self.height-self.maxRoomSize)
    local startCol = random(1, self.width-self.maxRoomSize)
    
    local height = random(Dungeon.MIN_ROOM_SIZE, self.maxRoomSize)
    local width = random(Dungeon.MIN_ROOM_SIZE, self.maxRoomSize)
  
    for i=startRow-1, startRow+height+1 do
      for j=startCol-1, startCol+width+1 do
        
        if (self.matrix[i][j] != Dungeon.Tile_Types.Empty) then
          return            -- Room is overlapping other room->room is discarded
        end
      end
    end
    self:buildRoom(startRow, startCol, startRow+height, startCol+width)
  end

  function Dungeon:buildRoom(startR, startC, endR, endC)
    -- init room object and paint room onto tiles.
  
    local id = self.rooms+1
    local room = Room:new(id)
    local r,c =endR-floor((endR-startR)/2), endC-floor((endC-startC)/2)
    room:setCenter(r,c)
    insert(self.rooms, room)
    
    for i=startR, endR do
      for j=startC, endC do
        local tile = self:getTile(i,j)
        self.matrix[i][j] = Dungeon.Tile_Types.Soil -- Randomize by theme/room type
        tile.roomId, tile.class = id, Tile.FLOOR
      end
    end
    self:addWalls(startR-1, startC-1, endR+1, endC+1)
  end

  function Dungeon:addWalls(startR, startC, endR, endC)
    -- Places walls on circumference of given rectangle.
    
    -- Upper and lower sides
    for j=startC,endC do
      self:placeWall(startR, j)
      self:placeWall(endR, j)
    end
    
    -- Left and right sides
    for i=startR,endR do
      self:placeWall(i, startC)
      self:placeWall(i, endC)
    end
  end

  function Dungeon:placeWall(r,c)
    -- Places wall at given coordinate. Could either place
    -- regular wall, soil or mineral vein
    
    local tile = self:getTile(r,c)
    
   
  end