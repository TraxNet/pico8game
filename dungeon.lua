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
        DownStairCase               = 0x05,
        UpStairCase                 = 0x06,
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
    [Dungeon.Tile_Types.DownStairCase] = "u",
    [Dungeon.Tile_Types.UpStairCase] = "$",
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
      walls = {}
    }

    dungeon.scatteringFactor = ceil(max(height,width)/dungeon.maxRoomSize)+3
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
                id = "id"..i..j,
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
       
            if self.matrix[i][j].class != Dungeon.Tile_Types.Empty then
   
                
                return            -- Room is overlapping other room->room is discarded
            end
        end
    end
    self:buildRoom(startRow, startCol,  min(self.height-2, startRow+height),  min(self.width-2, startCol+width))
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

function Dungeon:placeWall(r,c, class)
    class  = class or Dungeon.Tile_Types.Wall + flr(rnd(3))

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

        if not (self:getTile(r,c).class == Dungeon.Tile_Types.Soil ) then
            self:placeWall(r, c)
        end
    end
 end


 --[[function Dungeon:lineCol(from, to)
    local dx = to.x - from.x
    local dy = to.y - from.y
    local m = dy/dx
    for x=from.x,to.x do
        local y = flr(m*(x - from.x) + from.y)

        --printh("from:"..from.x..""..from.y.." to:"..to.x.." "..to.y.." line:"..x.." "..y)
        pset(x*8, y*8, 5)
        local tile = self:getTile(y, x)
        if tile and (tile.class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall or tile.class == Dungeon.Tile_Types.Empty) then
            return true
        end
       
    end

    return false
 end]]


 --[[function Dungeon:lineCol(x0, y0, x1, y1, tile_id)
    local dx = x1 - x0;
    local dy = y1 - y0;

        if (dx ~= 0) then
            m = dy / dx;
        else 
            m = sgn(dy)
        end

        local b = y0 - m*x0;
        if x1 > x0 then
            dx = 1
        else
            dx = -1
        end
        while x0 ~= x1 do
            x0 = (x0 + dx)
            y0 = (m*x0 + b);
            

            local tile = self:getTile(flr(y0), flr(x0))
            if tile and (tile.class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall or tile.class == Dungeon.Tile_Types.Empty) then
                if tile.id == tile_id then 
                    return true 
                end

                return false
            end

            pset(flr(x0)*8+4, flr(y0)*8+4, 8)
        end

 

    return false
 end
 ]]

 function lineCircleIntersect(_cx, _cy, _r, _x1, _y1, _x2, _y2)
    local _cx = _x1 - _cx
    local _cy = _y1 - _cy

    local _vx  = _x2 - _x1
    local _vy  = _y2 - _y1
    local _a   = _vx * _vx + _vy * _vy
    local _b   = 2.0 * (_vx * _cx + _vy * _cy)
    local _c   = _cx * _cx + _cy * _cy - _r * _r
    local _det = _b * _b - 4.0 * _a * _c

    if (_a <= 0.000001 or _det < 0) then
        return false;
    elseif (_det == 0) then
        --local var _t = -_b / (2 * _a);
        --local var _p1 = { X : _x1 + _t * _vx, Y : _y1 + _t * _vy };
        --return [_p1, _p1];
        return false
    else
        --printh("intersec")
        
    
        _det = sqrt(_det)
        local _t1 = (-_b - _det) / (2 * _a)
        local _t2 = (-_b + _det) / (2 * _a)

        if( _t1 >= 0 and _t1 <= 1 ) then

            return true 
        end

        if( _t2 >= 0 and _t2 <= 1 ) then
            return true 
        end
        --[[
        // El primer punto es el más cercano a [_x1, _y1]
        return [{ X : _x1 + _t1 * _vx, Y : _y1 + _t1 * _vy },
                { X : _x1 + _t2 * _vx, Y : _y1 + _t2 * _vy }];
        ]]
        return false
    end
 end


 function Dungeon:checkTileVisibility(r, c, y, x)
    for w in all(self.walls) do
       
        if (w.r != r) and (w.c != c) then
            --printh("w "..w.r.." "..w.c)
            if lineCircleIntersect(w.c, w.r, 1, x, y, c, r) then return false end
        end
    end

    return true
 end

 function Dungeon:computeVisibility()
    for i=0,self.height do
        for j=0,self.width do   

            local tile = self:getTile(i, j)
            if tile.class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall then 
                add(self.walls, {r=i, c=j})
            end
        end
    end
 end


 function Dungeon:lineCol(_x0, _y0, x1, y1, tile_id)
    local x0 = _x0
    local y0 = _y0
    local dx = x1 - x0;
    local dy = y1 - y0;
    local stepx, stepy

    if dy < 0 then
        dy = -dy
        stepy = -1
    else
        stepy = 1
    end

    if dx < 0 then
        dx = -dx
        stepx = -1
    else
        stepx = 1
    end

    

    --self.buffer[x0 + y0 * pitch] = color
    if dx > dy then
        local fraction = dy - ( dx >> 1 )
        --local fraction = dy - dx*0.5
        while x0 ~= x1 do
            if fraction >= 0 then
                y0 = y0 + stepy
                fraction = fraction - dx
            end
            x0 = x0 + stepx
            fraction = fraction + dy

            local flrx0, flry0 = flr(y0), flr(x0)

            
            local tile = self:getTile(y0, x0)
            if tile.id == tile_id then 
                pset(flr(x0)*1+4, flr(y0)*1+4, 12)
                return true 
            end

            
            if (tile.class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall) or (tile.class == Dungeon.Tile_Types.Empty) then
                
                pset(flr(x0)*1+4, flr(y0)*1+4, 12)
                return false
            end

            if pget(flrx0, flry0) != 12 then
                pset(flr(x0)*1+4, flr(y0)*1+4, 8)
            end
            --self.buffer[flr(y0) * pitch + flr(x0)] = color
        end
    else
        local fraction = dx - (dy >> 1)
        --local fraction = dx - dy*0.5
        while y0 ~= y1 do
            if fraction >= 0 then
                x0 = x0 + stepx
                fraction = fraction - dy
            end
            y0 = y0 + stepy
            fraction = fraction + dx

            local tile = self:getTile(y0, x0)
            if tile.id == tile_id then 
                pset(flr(x0)*1+4, flr(y0)*1+4, 12)
                return true 
            end

            if (tile.class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall) or (tile.class == Dungeon.Tile_Types.Empty) then
                pset(flr(x0)*1+4, flr(y0)*1+4, 12)
                return false
            end

            if pget(flr(x0), flr(y0)) != 12 then
                pset(flr(x0)*1+4, flr(y0)*1+4, 8)
            end
            --self.buffer[flr(y0) * pitch + flr(x0)] = color
        end
    end

    return true
 end


 function Dungeon:renderToMap(y, x)
    for i=0,self.height do
        for j=0,self.width do   

            local tile = self:getTile(i, j)
            if  tile.class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall then
                mset(j,i, 16+6)
            end

            if tile.class != Dungeon.Tile_Types.Empty then
            
                local d = getDist({y, x}, {i, j})
                local dist = d
                local visible = self:lineCol(x, y, j, i, tile.id)
                if visible then
                    
                    if dist >= 7 then
                        dist = 6
                    elseif dist > 6 then
                
                        dist = 3
                    elseif dist > 5 then
                
                        dist = 3
                    elseif dist <= 4 then
                        dist = 0
                    end  
            
                end
            
                if dist < 1.5 then
                    dist = 0
                end
                
                
                --printh(dist)
                
                if(visible and tile.class&Dungeon.Tile_Types.Wall == Dungeon.Tile_Types.Wall) then
                    --if dist == 6 then printh("we"..d.." "..y.." "..x.." ".." "..i.." "..j.." v"..tonum(visible)) end
                    --mset(j,i, 16+band(tile.class,0x0F)+dist)
                    mset(j,i, 16)
                elseif dist != 9 and tile.class == Dungeon.Tile_Types.DownStairCase then
                    
                    mset(j,i, 0x05)
                    
                elseif dist != 9 and tile.class == Dungeon.Tile_Types.UpStairCase then
                    mset(j,i, 0x06)
                end
            end
        end
    end

    pset(x*1+4, y*1+4, 10)
end


function Dungeon:getRandRoom()
    -- return: Random room in level
    local i = flr(rnd(#self.rooms+1))
    return self.rooms[i]
end


function Dungeon:addStaircases(maxStaircases)
    -- Adds both descending and ascending staircases to random rooms.
    -- Number of staircases depend on number of rooms.
    
    if (not maxStaircases) or (maxStaircases > #self.rooms) then 
        maxStaircases = ceil(#self.rooms-(#self.rooms/2))+1 
    end
    local staircases = 2 --rnd(2,maxStaircases)

    repeat
        local room = self:getRandRoom()
        if room and not room.hasStaircase or #self.rooms == 1 then
            self:placeStaircase(room, staircases)
            staircases = staircases-1
        end
    until staircases==0
end


function Dungeon:placeStaircase(room, staircases)
    -- Places staircase in given room. 
    -- Position is random number of steps away from center.
    
    local steps = flr(rnd(self.maxRoomSize/2))
    
    local nrow, ncol = room.center[1], room.center[2]
    repeat 
        row, col = nrow, ncol
        repeat
            nrow, ncol = getRandNeighbour(row, col)
        until self:getTile(nrow, ncol).class == Dungeon.Tile_Types.Soil
        steps=steps-1
    until (self:getTile(nrow, ncol).roomId ~= room.id or steps <= 0)
        
    if staircases%2 == 0 then 
        self:getTile(row, col).class=Dungeon.Tile_Types.DownStairCase
    else
        self:getTile(row, col).class=Dungeon.Tile_Types.UpStairCase
        self.startPosition = {y = row, x = col}
    end

    room.hasStaircase = true
    add( self.staircases, { row, col } )
  end