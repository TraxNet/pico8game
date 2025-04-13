--[[
    *An adaptation of Lua-Dungeon-Generator by Veronica Hage 
    (https://github.com/vronc/Lua-Dungeon-Generator/tree/master) to pico-8 
  
    It takes around 1800 tokens, no optimizations at this stage
]]


Dungeon = {
    Tile_Types = {
        Empty                       = 0x00,
        Soil                        = 0x01,
        SoilRocks                   = 0x02,
        Water                       = 0x03,
        --- Above 0x20 values are non walkable types (i.e walls)
        Wall                        = 0x20,
        WallDown                    = 0x21,
        WallLeft                    = 0x22,
        WallRight                   = 0x23,
        WallLeftUpperCornner        = 0x24,
        WallRightUpperCornner       = 0x25,
        WallLeftBottomCornner       = 0x26,
        WallRightBottomCornner      = 0x27,
        WallLeftUpperCornnerOpen    = 0x28,
        WallRightUpperCornnerOpen   = 0x29,
        WallLeftBottomCornnerOpen   = 0x2A,
        WallRightBottomCornnerOpen  = 0x2B,
        InnerWall                   = 0x2C,
        FullWall                    = 0x2D,
    }
}
Dungeon.Type_Prints = {
    [Dungeon.Tile_Types.Empty] = " ",
    [Dungeon.Tile_Types.Soil] = ".",
    [Dungeon.Tile_Types.SoilRocks] = ":",
    [Dungeon.Tile_Types.Water] = "*",
    [Dungeon.Tile_Types.Wall] = "#",
    [Dungeon.Tile_Types.WallDown] = "#",
    [Dungeon.Tile_Types.WallLeft] = "#",
    [Dungeon.Tile_Types.WallRight] = "#",
    [Dungeon.Tile_Types.WallLeftUpperCornner] = "/",
    [Dungeon.Tile_Types.WallRightUpperCornner] = "\\",
    [Dungeon.Tile_Types.WallLeftBottomCornner] = "*",
    [Dungeon.Tile_Types.WallRightBottomCornner] = "+",
    [Dungeon.Tile_Types.WallLeftUpperCornnerOpen] = "1",
    [Dungeon.Tile_Types.WallRightUpperCornnerOpen] = "2",
    [Dungeon.Tile_Types.WallRightBottomCornnerOpen] = "3",
    [Dungeon.Tile_Types.WallLeftBottomCornnerOpen] = "4",
    [Dungeon.Tile_Types.InnerWall] = "z",
    [Dungeon.Tile_Types.FullWall] = "O",
}
Dungeon.__index = Dungeon
Dungeon.MIN_ROOM_SIZE = 1


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
      endRoom=nil,
      maxRoomSize = ceil(min(height, width)/10)+3,
      maxRooms = ceil(max(height, width)/Dungeon.MIN_ROOM_SIZE)+15,
      
    }

    dungeon.scatteringFactor = ceil(max(height,width)/dungeon.maxRoomSize)
    --dungeon.scatteringFactor = 0
    setmetatable(dungeon, Dungeon)

    return dungeon
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
    --printh("printMap")
    for i=0,self.height do
        local row = " "
        --self.matrix[i] = {} 
        for j=0,self.width do
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
            if (self.matrix[i][j].class != Dungeon.Tile_Types.Empty or 
                self.matrix[i-1][j].class != Dungeon.Tile_Types.Empty or 
                self.matrix[i+1][j].class != Dungeon.Tile_Types.Empty or
                self.matrix[i][j-1].class != Dungeon.Tile_Types.Empty or
                self.matrix[i][j+1].class != Dungeon.Tile_Types.Empty) then
                return            -- Room is overlapping other room->room is discarded
            end
        end
    end
    self:buildRoom(startRow, startCol,  min(self.height-1, startRow+height),  min(self.width-1, startCol+width))
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
    --[[for j=startC+1,endC-1 do
        self:placeWall(startR, j, Dungeon.Tile_Types.WallDown)
        self:placeWall(endR, j, Dungeon.Tile_Types.Wall)
    end
    
    -- Left and right sides
    for i=startR+1,endR-1 do
        self:placeWall(i, startC, Dungeon.Tile_Types.WallRight)
        self:placeWall(i, endC, Dungeon.Tile_Types.WallLeft)
    end
    self:placeWall(startR, startC, Dungeon.Tile_Types.WallLeftUpperCornner)
    self:placeWall(startR, endC, Dungeon.Tile_Types.WallRightUpperCornner)
    self:placeWall(endR, startC, Dungeon.Tile_Types.WallLeftBottomCornner)
    self:placeWall(endR, endC, Dungeon.Tile_Types.WallRightBottomCornner)
    ]]
    for j=startC+1,endC-1 do
        self:placeWall(startR, j)
        self:placeWall(endR, j)
    end
    
    -- Left and right sides
    for i=startR+1,endR-1 do
        self:placeWall(i, startC)
        self:placeWall(i, endC)
    end
    self:placeWall(startR, startC)
    self:placeWall(startR, endC)
    self:placeWall(endR, startC)
    self:placeWall(endR, endC)
end

function Dungeon:placeWall(r,c, class)
    class  = class or Dungeon.Tile_Types.Wall

    --printh("placeWall:"..r..","..c)
    local tile = self:getTile(r,c)
    tile.class = class
    
   
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

    --self:updateWallTypes()
end
  

  
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
        
        r, c = adj[i][1], adj[i][2]
        printh("adj"..r.." "..c)
        local left = self:getTile(r, c-1).class == Dungeon.Tile_Types.Soil or self:getTile(r, c-1).class == Dungeon.Tile_Types.Empty
        local right = self:getTile(r, c+1).class == Dungeon.Tile_Types.Soil or self:getTile(r, c-1).class == Dungeon.Tile_Types.Empty
        local up = self:getTile(r-1, c).class == Dungeon.Tile_Types.Soil or self:getTile(r, c-1).class == Dungeon.Tile_Types.Empty
        local down = self:getTile(r+1, c).class == Dungeon.Tile_Types.Soil or self:getTile(r, c-1).class == Dungeon.Tile_Types.Empty

        if not (self:getTile(r,c).class == Dungeon.Tile_Types.Soil or self:getTile(r,c).class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall) then
            --[[ if left and not (up or down or right) then
                self:placeWall(r, c, Dungeon.Tile_Types.WallLeft)
            elseif right and not (up or down or left) then
                self:placeWall(r, c, Dungeon.Tile_Types.WallRight)
            elseif up and not (right or down) then
                self:placeWall(r, c, Dungeon.Tile_Types.WallBottom)
            elseif down and not (right or down) then
                self:placeWall(r, c, Dungeon.Tile_Types.Wall)
            else
                self:placeWall(r, c, Dungeon.Tile_Types.Wall)
            end
            ]]
            --self:placeWall(r, c, Dungeon.Tile_Types.FullWall)
            self:placeWall(r, c)
        end
    end
 end


 function Dungeon:updateWallTypes()
    for i=1,self.width do
        for j=1,self.height do   
            local tile = self:getTile(i, j)

            if tile.class == Dungeon.Tile_Types.Wall then
                --local adj = getAdjacentPos(i,j)
                --printh("u"..self:getTile(i-1, j).class)
                
                local left = self:getTile(i, j-1).class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall 
                local right = self:getTile(i, j+1).class&Dungeon.Tile_Types.Wall  == Dungeon.Tile_Types.Wall 
                local up = self:getTile(i-1, j).class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall
                local down = self:getTile(i+1, j).class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall 
                printh(left)
                
                
             
                

                if left and not right then
                   if not up and not down then
                        --
                        -- [ ][x]
                        --
                    elseif (not down) and up then
                        --    [ ]
                        -- [ ][4] 
                        --
                        tile.class = Dungeon.Tile_Types.WallRightBottomCornnerOpen
                    elseif not up then
                        --    
                        -- [ ][2]
                        --    [ ]
                        tile.class = Dungeon.Tile_Types.WallRightUpperCornnerOpen
                    end
                elseif right and not left then
                    if not up and not down then
                        --
                        -- [x][ ]
                        --
                        
                    elseif not up and down then
                        --    
                        -- [1][ ] 
                        -- [ ]
                        tile.class = Dungeon.Tile_Types.WallLeftUpperCornnerOpen
                    elseif not down and up then
                        -- [ ]   
                        -- [3][ ]
                        --  
                        tile.class = Dungeon.Tile_Types.WallLeftBottomCornnerOpen
                    end    
                end
                
            end
        end
    end
 end


 function Dungeon:renderToMap()
    for i=0,self.width do
        for j=0,self.height do   
            local tile = self:getTile(i, j)
            if(tile.class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall) then
                mset(j,i, 16+band(tile.class,0x0F))
            end
        end
    end
end