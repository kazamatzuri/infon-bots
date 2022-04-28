--some constants usefull in general...
--mean steps idea stolen from ursbot *G
x1, y1, x2, y2 = world_size()
kothx,kothy=get_koth_pos()
SCHRITTWEITE=256*10
--foodmap
FOODPROB=50
foodmap_x={}
foodmap_y={}

MEAN_STEPS = 100 -- Schritte, ueber die das fliessende positionsmittel erstellt wird.
MEAN=5



function Creature:onSpawned()
    print("Creature " .. self.id .. " spawned")
    self.speedx,self.speedy=math.random(-SCHRITTWEITE,SCHRITTWEITE),math.random(-SCHRITTWEITE,SCHRITTWEITE)
    self.wtargetx,self.wtargety=get_pos(self.id)
    p("tx,ty"..self.wtargetx..":"..self.wtargety)
    set_path(self.id,self.wtargetx,self.wtargety)    
end


function Creature:walk()
	local x,y=get_pos(self.id)
	if self.speedx==nil or self.speedy==nil then
	   self,speedx=0
	   self,speedy=0
	end
 	local rand=0
	local dx,dy=0,0
	local distance=((self.wtargetx-x)^2+(self.wtargety-y)^2)
	if distance<(768^2) then
	    local tx,ty = get_nearest_known_food(x,y)
	     if false then
		set_path(self.id,tx,ty)
		dx=self.wtargetx-x
		dy=self.wtargety-y
		self.wtargetx,self.wtargety=tx,ty
 	      else
    	           repeat
	           dx=self.speedx + (math.random(-SCHRITTWEITE,SCHRITTWEITE))
	           dy=self.speedy + (math.random(-SCHRITTWEITE,SCHRITTWEITE))
   	           self.wtargetx=dx+x
 	           self.wtargety=dy+y
	           until set_path(self.id,self.wtargetx,self.wtargety)
	       end
	end
	if dx~=0 and dy~=0 then
		self.speedx=(self.speedx*MEAN+dx)/(MEAN+1)
		self.speedy=(self.speedy*MEAN+dy)/(MEAN+1)
	end
	test=set_path(self.id,self.wtargetx,self.wtargety)
	set_state(self.id,CREATURE_WALK)
end

function Creature:onRestart()    
    self.STATE = STATE_NONE
    self.floating_x, self.floating_y = get_pos(self.id)
    self.wtargetx,self.wtargety=get_pos(self.id)
    set_path(self.id,self.wtargetx,self.wtargety)
end


function get_nearest_known_food (x,y)
    x = math.floor(x/256)
    y = math.floor(y/256)
    if foodmap_x[x] ~= nil and foodmap_x[x][y] ~=nil and foodmap_y[x] ~=nil and foodmap_y[x][y] ~=nil then
        return foodmap_x[x][y], foodmap_y[x][y]
    else
        return nil,nil
    end
end

function set_nearest_known_food(x,y,tox, toy)
    x = math.floor(x/256)
    y = math.floor(y/256)
    if foodmap_x[x] == nil then
        foodmap_x[x] = {}
    end
    if foodmap_y[x] == nil then
        foodmap_y[x] = {}
    end
    foodmap_x[x][y] = tox
    foodmap_y[x][y] = toy
end




function Creature:main()
      local x,y = get_pos(self.id)
       -- Floating-Position-Mean updaten
      if self.lastfoodx~=nil and self.lastfoody~=nil and ((self.lastfoodx-x)^2+ (self.lastfoody-y)^2)>512^2 then
	set_nearest_known_food(x,y,self.lastfoodx,self.lastfoody)
      end
	self:walk()
	x,y=get_pos(self.id)
        local creature_id, x, y, playernum, dist = nearest_enemy(self.id)
	if creature_id~=nil and get_type(self.id)==1 and dist <769 then
		set_target(self.id,creature_id)
		set_state(self.id,CREATURE_ATTACK)
	end
	while get_state(self.id)==CREATURE_ATTACK and dist<769 do
		self:wait_for_next_round()
		creature_id, x, y, playernum, dist = nearest_enemy(self.id)
	end

        local food=get_tile_food(self.id)
	if food>0 then
		set_state(self.id,CREATURE_EAT)
		self.lastfoodx=x
		self.lastfoody=y
	end

	while get_state(self.id)==CREATURE_EAT do
		if get_tile_food(self.id)==0 then
			set_state(self.id,CREATURE_IDLE)
		end
		self:wait_for_next_round()
	end

	food=get_food(self.id)
	if food>1000 and get_health(self.id)<70 then
		set_state(self.id,CREATURE_HEAL)
		while get_state(self.id)==CREATURE_HEAL do
			self:wait_for_next_round()
		end
	end

     food=get_food(self.id)

        if food > 8020 and get_type(self.id)==0 then
           set_convert(self.id,1)
           set_state(self.id,CREATURE_CONVERT)
           --p("evolving <<<<<<<<<<<<<<")
        end
	while get_state(self.id)==CREATURE_CONVERT do
		wait_for_next_round()
	end

	local distance=((self.wtargetx-x)^2 + (self.wtargety-y)^2)
	while self:is_walking() and distance>0 do
		food=get_tile_food(self.id)
		if food>0 then
			set_state(self.id,CREATURE_EAT)
		end
		x,y=get_pos(self.id)
	        distance=((self.wtargetx-x)^2 + (self.wtargety-y)^2)
		self:wait_for_next_round()
	end
end
