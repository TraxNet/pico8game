
Dungeon = {
    Tile_Types = {
        Empty                   = 0x00,
        Soil                    = 0x01,
        SoilRocks               = 0x02,
        Water                   = 0x03,
        --- Above 0x20 values are non walkable types (i.e walls)
        Wall                    = 0x20,
        WallLeftUpperCornner    = 0x21,
        WallRightUpperCornner   = 0x22,
        WallLeftBottomCornner   = 0x23,
        WallRightBottomCornner  = 0x24,
        InnerWall               = 0x25,
    }
}
Dungeon.Type_Prints = {
    [Dungeon.Tile_Types.Empty] = " ",
    [Dungeon.Tile_Types.Soil] = ".",
    [Dungeon.Tile_Types.SoilRocks] = ":",
    [Dungeon.Tile_Types.Water] = "*",
    [Dungeon.Tile_Types.Wall] = "#",
    [Dungeon.Tile_Types.WallLeftUpperCornner] = "/",
    [Dungeon.Tile_Types.WallRightUpperCornner] = "\\",
    [Dungeon.Tile_Types.WallLeftBottomCornner] = "*",
    [Dungeon.Tile_Types.WallRightBottomCornner] = "+",
    [Dungeon.Tile_Types.InnerWall] = "z",
}
Dungeon.__index = Dungeon
Dungeon.MIN_ROOM_SIZE = 2


function Dungeon.new(height, width)
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
    dungeon.scatteringFactor = ceil(max(height,width)/dungeon.maxRoomSize)

    setmetatable(dungeon, Dungeon)
   

    return dungeon
end


function Dungeon:generate()

end


function Dungeon:initMap()

    -- Create void
    for i=-1,self.height+1 do
        self.matrix[i] = {}
        --printh("init["..i.."]")
        for j=-1,self.width+1 do
            self.matrix[i][j] = {
                class = Dungeon.Tile_Types.Empty,
                roomId = 0
            }
        end
    end

    --self:addWalls(0, 0, self.height+1, self.width+1)
end 


function Dungeon:printMap()
    printh("printMap")
    for i=-1,self.height+1 do
        local row = " "
        --self.matrix[i] = {} 
        for j=-1,self.width+1 do
            local class = self.matrix[i][j].class
            row = row..Dungeon.Type_Prints[class]
        end
        printh(row)
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
    local startRow = min(self.height,flr(rnd(self.height-self.maxRoomSize)))
    local startCol = min(self.width,flr(rnd(self.width-self.maxRoomSize)))
    
    local height = flr(Dungeon.MIN_ROOM_SIZE+rnd(Dungeon.MIN_ROOM_SIZE+self.maxRoomSize))
    local width = flr(Dungeon.MIN_ROOM_SIZE+rnd(Dungeon.MIN_ROOM_SIZE+self.maxRoomSize))
  
    for i=startRow, min(self.height,startRow+height) do
        for j=startCol, min(self.width, startCol+width) do
            --printh("gen"..i.." "..j)
            if (self.matrix[i][j].class != Dungeon.Tile_Types.Empty) then
                return            -- Room is overlapping other room->room is discarded
            end
        end
    end
    self:buildRoom(startRow, startCol,  startRow+height,  startCol+width)
end

function Dungeon:buildRoom(startR, startC, endR, endC)
    -- init room object and paint room onto tiles.
  
    local id = #self.rooms+1
    local room = Room:new(id)
    local r,c =endR-flr((endR-startR)/2), endC-flr((endC-startC)/2)
    room:setCenter(r,c)
    add(self.rooms, room)
    
    for i=startR, endR do
        for j=startC, endC do
            local tile = self:getTile(i,j)
            --self.matrix[i][j] = Dungeon.Tile_Types.Soil -- Randomize by theme/room type
      
            tile.roomId, tile.class = id, Dungeon.Tile_Types.Soil

        end
    end
    --self:addWalls(max(0, startR-1), max(0, startC-1), min(self.height, endR+1), min(self.width, endC+1))
    self:addWalls(max(0, startR-1), max(0, startC-1), min(self.height, endR+1), min(self.width, endC+1))
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
    --printh("placeWall:"..r..","..c)
    local tile = self:getTile(r,c)
    tile.class = Dungeon.Tile_Types.Wall
    
   
end

function Dungeon:getRoomTree()
    if #self.rooms < 1 then printh("Can't generate room tree, no rooms exists") end

    local root, lastLeaf = prims(clone(self.rooms))
    self.rootRoom = root
    self.endRoom = lastLeaf

    return self.rootRoom
end


function Dungeon:buildCorridors(root)
    -- Recursive DFS function for building corridors to every neighbour of a room (root)
    
    for i=1,#root.neighbours do
        local neigh = root.neighbours[i]
        self:buildCorridor(root, neigh)
        self:buildCorridors(neigh)
    end 
end
  
  -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- ##### -- 
  
function Dungeon:buildCorridor(from, to)
    -- Parameters from and to are both Room-objects.
    
    local start, goal = from.center, to.center
    local nextTile = findNext(start, goal)
    repeat
        local row, col = nextTile[1], nextTile[2]
        self:buildTile(row, col)
        
        if rnd() < self.scatteringFactor*0.05 then 
            --self:buildRandomTiles(row,col)    -- Makes the corridors a little more interesting 
        end
        nextTile = findNext(nextTile, goal)
    until (self:getTile(nextTile[1], nextTile[2]).roomId == to.id)
    
    add(self.entrances, {row,col})
end


function Dungeon:buildTile(r, c)
    -- Builds floor tile surrounded by walls. 
    -- Only floor and empty tiles around floor tiles turns to walls.
  
    local adj = getAdjacentPos(r,c)
    self:getTile(r, c).class = Dungeon.Tile_Types.Soil
    for i=1,#adj do
            --printh("adj"..i)
        r, c = adj[i][1], adj[i][2]
        if not (self:getTile(r,c).class == Dungeon.Tile_Types.Soil) then
            self:placeWall(r,c)
        end
    end
 end


 function Dungeon:updateWallTypes()
    for i=1,self.width do
        for j=1,self.height do   
            local tile = self:getTile(i, i)

            if tile.class == Dungeon.Tile_Types.Wall then
                --local adj = getAdjacentPos(i,j)

                local left = self:getTile(i-1, j)
                local right = self:getTile(i+1, j)
                local up = self:getTile(i, j-1)
                local down = self:getTile(i, j+1)
                
            end
        end
    end
 end