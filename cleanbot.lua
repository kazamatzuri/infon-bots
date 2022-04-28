worldx,worldy=world_size()
gridx,gridy=math.floor(worldx/256),math.floor(worldy/256)

KOTHBOTID=-1
KOTHBOTLIMIT=3

FLYBOT=-1
FLYBOTNEEDED=false

UPDATE=0

COUNT=0

FOODLIST={}
FOODSOURCES=0
AKTFOOD=0

EATRANGE=24*256

function info()
    local chkd=0
    for id, creature in pairs(creatures) do
        posx,posy=get_pos(id)
        print(id .. ":" ..get_type(id) .. " on "..posx..":"..posy .. "==> hp:"..get_health(id)..". food:"..get_food(id) .." state:" ..
        get_state(id))
        chkd=chkd+1
    end
    print("colony state: "..chkd.." internal count:" .. COUNT.." punkte: ".. player_score(player_number))
	COUNT=chkd
end



function Creature:newFoodsource(x,y)
	for i in pairs(FOODLIST) do
		if FOODLIST[i][1]==x and FOODLIST[i][2]==y then
			return false
		end
	end
	return true
end

function Creature:addFoodsource(x,y)
	if self:newFoodsource(x,y) then
		foodsource={}
		foodsource[1],foodsource[2]=x,y
		FOODLIST[FOODSOURCES]=foodsource
		FOODSOURCES=FOODSOURCES+1
	end
end

function Creature:getNextfoodsource()
	local aktuell=AKTFOOD
	AKTFOOD=AKTFOOD+1
	if AKTFOOD>FOODSOURCES then
		AKTFOOD=0
	end
	return FOODLIST[aktuell]
end

function Creature:onSpawned()
	self.target={}
	local kx,ky=get_pos(self.id)
	self.target[1]=math.floor(kx/256),math.floor(ky/256)
	print("---new creature: id: "..self.id)
	COUNT=COUNT+1
end

function Creature:onKilled(killer)
	COUNT=COUNT-1
	if KOTHBOTID==self.id then KOTHBOTID=-1 end
	p("died")
end

function Creature:attack() 
	if get_type(self.id)==1 then
		local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
		if enemy_dist <= 512 then
			set_target(self.id,enemy_id)
			set_state(self.id,CREATURE_ATTACK)
			return true
		end
	end
	return false
end

function Creature:eat()
	if get_tile_food(self.id)>1 and get_food(self.id) < get_max_food(self.id) then 
		set_state(self.id,CREATURE_EAT)
		return true
	end
	return false
end

function Creature:expand()
    	if (get_food(self.id) > 8001 and get_type(self.id)==0 and not FEEDMODE) then
        	set_convert(self.id,1)
        	set_state(self.id,CREATURE_CONVERT)
		return true    
	end
    	if (get_food(self.id) > 8001 and get_type(self.id)==1 and get_health(self.id)>50)then
        	set_state(self.id,CREATURE_SPAWN)
        	return true 
    	end
	
	return false
end

function Creature:getNearesteating()
	local actmin=nil
	local actd=400*256	
	for i in pairs(creatures) do
		if get_state(i)==CREATURE_EAT then
			local d = get_distance(i,self.id)
			if d < actd then	
				actd=d
				actmin=i
			end
		end
	end
	return actmin
end


function Creature:nextstep()
--	print("----nextstep---- id "..self.id)
	dx=math.random(9)-5
	dy=math.random(9)-5
	self.dir[1]=self.dir[1]+dx
	self.dir[2]=self.dir[2]+dy
	self.target[1]=self.grid[1]+self.dir[1]
	self.target[2]=self.grid[2]+self.dir[2]		
end

function Creature:initvars()
	if UPDATETIME==nil then
		UPDATETIME=0
	end
	if self.dir==nil then
		self.dir={}
		self.dir[1]=0
		self.dir[2]=0
	end
	if self.target==nil then
		self:nextstep()
	end
	if self.target[1]==nil then
		self:nextstep()
	end
	if self.target[2]==nil then
		self:nextstep()
	end
end


function Creature:move()

	local neater=self:getNearesteating()
	if neater~=nil then
		if get_distance(self.id,neater)<EATRANGE then
			local tx,ty = get_pos(neater)
			self.target[1],self.target[2]=math.floor(tx/256),math.floor(ty/256)
			set_path(self.id,tx,ty)
			set_state(self.id,CREATURE_WALK)
			return true
		end
	end

--	print(self.id..": moved1")

	if math.abs(self.grid[1]-self.target[1])<2 and math.abs(self.grid[2]-self.target[2])<2 then
		self:nextstep()	
	end	
	local temp=false
	local lcount=0	
	repeat
	 temp=set_path(self.id, self.target[1]*256+128,self.target[2]*256+128)
	 if not temp then
		self:nextstep()
	 end
	 lcount=lcount+1
	if lcount>10 then
		self.dir[1]=0
		self.dir[2]=0
		lcount=0
	end
	until temp  
--	print(self.id..": moved2")
	set_state(self.id,CREATURE_WALK)	
	return true
end


function Creature:heal()
	if get_health(self.id) < 50 and get_food(self.id)>1000 then
		set_state(self.id,CREATURE_HEAL)
		return true
	end
	return false
end

function Creature:update()
	local kx,ky=get_koth_pos()
	if not set_path(self.id,kx,ky) then
		FLYBOTNEEDED=true
	else
		FLYBOTNEEDED=false
	end
 	
	if KOTHBOTID==-1 and COUNT>KOTHBOTLIMIT then
		for i in pairs(creatures) do	
			if FLYBOTNEEDED then
				if get_health(i)> 80 and get_food(i)>5001 and get_type(i)==0 then
					KOTHBOTID=i
				end
			else
				if get_health(i)>80 and get_type(i)==1 then
					KOTHBOTID=i
				end
			end
		end
	end

--	print("updated")
end

function Creature:kothbot()
	if self.id == KOTHBOTID then
		local kx,ky=get_koth_pos()
		set_path(self.id,kx,ky)
		set_state(self.id,CREATURE_WALK)
		return true
	end	
	return false
end

function Creature:main()
	local x,y = get_pos(self.id)
	self.grid={}
	self.grid[1],self.grid[2]=math.floor(x/256),math.floor(y/256)
	self:initvars()
--	print("d1")
--	print(game_time())
	if math.abs(game_time()-UPDATETIME) >5000 then
		self:update()
		UPDATETIME=game_time()
	end
--	print("d2")

	while get_state(self.id)==CREATURE_SPAWN or get_state(self.id)==CREATURE_CONVERT or get_state(self.id)==CREATURE_HEAL do
--		print("wait")
		self:wait_for_next_round()
	end

--	print(self.id..": d3")
	
	while get_state(self.id)==CREATURE_SPAWN or get_state(self.id)==CREATURE_CONVERT or get_state(self.id)==CREATURE_HEAL do
--		print(self.id..": wait")
		self:wait_for_next_round()
	end
--	print(self.id..": d4")

--	set_message(self.id,"kuckuck")
	if self:attack() then
		set_message(self.id,"guerra")
	elseif self:heal() then
		set_message(self.id,"curar")	
	elseif self:eat() then
		set_message(self.id,"tomar")
	elseif self:kothbot() then
		set_message(self.id,"el rey")
	elseif self:expand() then
		set_message(self.id,"sexo")
	elseif self:move() then 
		set_message(self.id,"andar")
	--	print("target:  " ..self.target[1]..","..self.target[2].."  position: "..self.grid[1]..","..self.grid[2])

	else
		set_message(self.id,"nada")
	end
--	print(self.id..": d5")

	self:wait_for_next_round()
end

