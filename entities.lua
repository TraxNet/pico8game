do 
    local _highest_id = 0

     	
    function atan(x1, y1, x2, y2)
    --finds the angle between x & y
        local x = x2 - x1
        local y = y2 - y1
        return atan2(x, y)
    end
    
    function distance(x1, y1, x2, y2)
        return sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    end

    --collision library
    --andy c
    function collision(r1x,r1y,r1w,r1h,r2x,r2y,r2w,r2h) --rectangular collisions
        if ((r1x < r2x + r2w) and (r1x + r1w > r2x) and (r1y < r2y + r2h) and (r1y + r1h > r2y)) then
            return true
        else
            return false
        end
    end

    --[[
        for circular collisions use: {where c is circle and r is radius}
        if distance(c1x,c1y,c2x,c2y) <= 1/2 * (c1r + c2r) then
            return true
        end
        distance can be found in my lookat library
    --]]

    function map_collision(r1x,r1y,r1w,r1h,flag)
        check = false
        for i=0,15,1 do
            for j=0,15,1 do
                if collision(r1x,r1y,r1w,r1h,i*8,j*8,8,8) and fget(mget(i,j),flag) then
                    check = true
                end
            end
        end
        return check
    end

    function cuid()
        _highest_id += 1
        return _highest_id
    end

    meta_entity = {
        __add = function(a, b)
            a.x += b.x
            a.y += b.y
        end,

        __sub = function(a, b)

        end

        }

    function create_entity(x, y, sprite)
        local e = {
            x = x,
            y = y,
            sprite = sprite,
            _id = cuid(),
            update = function(self, tick)
              
            end,
            draw = function(self, tick)
                
            end,
        }
        setmetatable(e, meta_entity)
        return e
    end

    function entities_update(tick)
        for key, entity in pairs(_entities) do
            entity:update()
        end
    end
    
    function entities_draw()
        for key, entity in pairs(_entities) do
            entity:draw()
        end
    end

    
end