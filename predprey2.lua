MAXDISTANCE=256*10
MINDISTANCE=256*2
x1,y1,x2,y2=world_size()
STEP=256*10

gx,gy=math.floor(x2/256),math.floor(y2/256)
foodmap_x={}
foodmap_y={}


function Creature:get_next_search_field()
for x=1,gx do
   for y=1,ty do
	if foodmap_x[x]==nil then
		return x*256+128,y*256+128
	else
	 	if foodmap_x[x][y]==nil then
			return x*256+128,y*256+128
		end
	end
   end
end
return nil,nil
end

function Creature:set_foodmap(x,y,m)
  local gx,gy=math.floor(x/256),math.floor(y/256)
  if foodmap_x[gx]==nil then
	foodmap_x[gx]={}
  end
  foodmap_x[gx][gy]=m
  
end

function Creature:get_nearest_own()
    local min=256*100
    local actmin=self.id
    for id,creature in creatures do
            local d=get_distance(self.id,id)
            if d < min then
                actmin=id
                min=d
            end
    end
    return actmin
end

function Creature:getrandomstep(mode)
 local x,y=get_pos(self.id)
 
 if mode==0 then
    repeat
	self.wtargetx,self.wtargety=self:get_next_search_field()
	if not self:set_path(self.wtargetx,self.wtargety) then
		set_foodmap(self.wtargetx,self,wtargety,0)
	end
    until self:set_path(self.wtargetx,self.wtargety)

 elseif mode==1 then
       repeat
	self.wtargetx=math.random(x1,x2)
        self.wtargety=math.random(y1,y2)
       until self:set_path(self.wtargetx,self.wtargety)  
 end
 
end

function onSpawned()
self.speedx,self.speedy=0,0
self.meanspeedx,self.meanspeedy=0,0
self:getrandomstep(0)
end

function Creature:getNextStep()
local x,y=get_pos(self.id)
local nearest=get_nearest_own()
local distance=get_distance(self.id,nearest)
if distance<MAXDISTANCE then
  if distance<MINDISTANCE then
     self:getrandomstep(1)
  else
     self:getrandomstep(0)
  end
else
   self:set_path((tx+x)/2,(ty+y)/2)
end
end


function Creature:main()
self:getNextStep()
set_state(self.id,CREATURE_WALK)
while get_state(self.id)==CREATURE_WALK do 
   wait_for_next_round()
end
end
