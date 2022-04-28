--------------kbot version 0.3-----------------
-- this bot is GPL
-- questions & stuff -> kazamatzuri@informatik.uni-wuerzburg.de
-- author kazamatzuri
-----------------------------------------------


--global communication
converge=false
convergea=false
conx,cony=0,0
count=0
sc=0
foodsource=false
foodval=0
fx=0
fy=0    
range=25000
enemyviews={}
hardcore=false
globatt=false
globatt_id=0
globatt_x=0
globatt_y=0
x1, y1, x2, y2 = world_size()
gridx=math.floor(x2/256)
gridy=math.floor(y2/256)
grid_x={}
grid_y={}
fgrid={}
-- initializing grid for pheromon-traces
for i=1,gridx+2,1 do
grid_x[i]={}
grid_y[i]={}
fgrid[i]={}

end
-- at least one known target
kx,ky=get_koth_pos()
kxg,kyg=math.floor(kx/256),math.floor(ky/256)
fgrid[math.floor(kx/256)][math.floor(ky/256)]=1


-- initialization
function Creature:onSpawned()
    print("new kbot enters the world ")
    count=count+1
    enemyviews[self.id]={}
    self.mx,self.my=self:pos()
    self.lfxg,self.lfyg=kxg,kyg
    self.xg,self.yg=self.lfxg,self.lfyg
end

-- overwriting global info (keypress i in telnetserver)
-- to be a bit more talkative
function info()
    for id, creature in creatures do
    	posx,posy=get_pos(id)
        print("creature " .. id .. ": " ..get_type(id) .. " hp:"..get_health(id).."  food:"..get_food(id) .." state:" ..
	get_state(id).." on "..posx..":"..posy .."  punkte: "..player_score(player_number))
    end
end

function Creature:onAttacked(attacker)
    self.attacked=true
end


function Creature:onKilled(killer)
    if killer == self.id then
        print("kbot " .. self.id .. " suicided")
    elseif killer then 
        print("kbot " .. self.id .. " killed by Creature " .. killer)
    else
        print("kbot  " .. self.id .. " starved")
    end
    count=count-1
    enemyviews[self.id]=nil
end

function Creature:checkcount_hardcore()
    -- sometimes the own counting isn't right, so we have to check hardcore style
	local scnum=0
	for i,id in creatures do
		scnum=scnum+1
	end
	return scnum
end

function Creature:checkforfood()
    return get_tile_food(self.id)
end

function Creature:checkfordanger()
    -- anyone evil near? todo: tuneable
	local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
	if enemy_dist ==nil then
		return false
		end
	if enemy_dist < 600 then
		if get_type(enemy_id) == 1 then
			return true
		end
	end
	return false
end

function Creature:Wait()
    -- blocking Wait to current action finished, not a very good idea most of the time
    while (get_state(self.id) ~= CREATURE_IDLE) do
        self:wait_for_next_round()  
    end
end

function Creature:getdir(x0,y0,x1,y1)
	-- todo
end

function Creature:printloc()
    -- talkative debug
	self.mx,self.my=self:pos()
	return ( self.id..":"..self.t.." on  "..self.mx .. ":"..self.my.." ")
end

function Creature:checkdata()
    -- per round data 
    if (x1==nil and y1==nil) then x1, y1, x2, y2 = world_size() end
    self.mx,self.my=self:pos()    
    self.t=self:type()
    self.actfood=self:checkforfood()
    self.hp = self:health()
    if self.actfood==nil then self.actfood=0 end

end

--[[
function Creature:getmode()
	local bm=false
 	if self.t==0 then 
	   bm = false 
	else
	   bm = true
	end
	if bm then
		self.hpthres=80
	end
	return bm
end
--]]

function Creature:evolve()
  p(self.id ..":"..self.t.." is evolving")
  set_convert(self.id, 1)
  set_state(self.id,CREATURE_CONVERT)
  self:Wait()
  set_message(self.id,self.id.." of "..player_number)
end

function Creature:dist(x0,y0,x1,y1)
	return(math.sqrt((x0-x1)^2+(y0-y1)^2))
end

function Creature:reactattack()
    --p("------under attack-----")
    -- i am attacked
    -- set assistance needed mode throughout the fleet, aehm swarm
   	convergea=true
	convx,convy=self:pos()
	convx,convy=math.floor(convx/256),math.floor(convy/256)	
    local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)

    -- worth saving? -> command global attack mode (more force comes than in assistance mode)
    if self.hp>60 then
        globatt=true
	    globatt_id=enemy_id
	    globatt_x=math.floor(enemy_x/256)
	    globatt_y=math.floor(enemy_y/256)
    end

    -- can we fight back?
    if self.mymode then 	
	    self:kattack(enemy_id,enemy_dist,enemy_x,enemy_y)
    end
    -- here we are either dead, or the winner 
    self.attacked=false
end

function Creature:kattack(enemy_id,enemy_dist,enemy_x,enemy_y)
	if creature_exists(enemy_id) and self.t~=0 then
	-- move to attack range and attack
    if enemy_dist > 512 then
		
		self.txg=math.floor(enemy_x/256)
		self.tyg=math.floor(enemy_y/256)
		self:executemove()		
	else 
		self:attack(enemy_id)
		--p("attack---------")
		self:Wait()
	end
	end
end

function Creature:expand()
    -- spawn/evolve
    if (self:food() > 8010 and self.t==0 )then
    	p("----------------evolve----------------")
    	self:evolve()
	self:Wait()
	p("----------------evolved---------------")
    end
    if (self:food() > 8010 and self.t==1 and self.hp>40)then
    	p("----------------fork------------------")
    	self:begin_spawning()
	self:Wait()
	p("----------------forked----------------")
    end
    if ((self:food() > 2000) and (self.hp < 50) ) then
    	self:begin_healing()
	--p("some heal required  ---"..self.hp)
	self:wait_for_next_round()
    end
    
end

function Creature:getviews(enemy_id)
    -- how much of my soldiers see a specific enemy
	local c=0
	for i,id in enemyviews do
		if enemy_id==id then c=c+1 end
	end	
	return c
end

function Creature:hunt()
    -- have fun :), 
    -- type 0? grow up little puppy
    if get_type(self.id)==0 then 
        return 
    end    

    --if we're alone it definitly not time to have fun 
    if count==1 then return false end
    local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
    local enemy_type = get_type(enemy_id)   
    if enemy_id==nil then
    	return
    end
    local enemy_health=get_health(enemy_id)
    -- enemy to near? not my fault *G
    if enemy_dist< 512 then
    	self:kattack(enemy_id,enemy_dist,enemy_x,enemy_y)
    end
    
    -- easy prey anywhere?
    if enemy_dist < 6000 and enemy_type==0 and self.mymode and self.hp>20 then    	
	self:kattack(enemy_id,enemy_dist,enemy_x,enemy_y)
    elseif self.mymode and globatt==true then
    	-- run help anyone else 
        if get_distance(self.id,globatt_id)< 8000 then
		    self:kattack(globatt_id,get_distance(self.id,globatt_id),globatt_x,globatt_y)
	    end
    elseif enemy_dist < 1500 and enemy_type==1 and self.mymode and enemy_health<(self.hp-10 )then
	    -- grown enemy, but we are stronger 
        self:kattack(enemy_id,enemy_dist,enemy_x,enemy_y)
    	enemyviews[self.id]=enemy_id
--    elseif count>4 and enemy_dist<2000 then
--    	--p("global attack triggered -----a")
--	globatt=true
--	globatt_id=enemy_id
--	globatt_x=math.floor(enemy_x/256)
--	globatt_y=math.floor(enemy_y/256)
    end
    
    if self:getviews(enemy_id) >2 and globatt==false then
   	p("global attack triggered -----a")
    	globatt=true
	globatt_id=enemy_id
	globatt_x=math.floor(enemy_x/256)
	globatt_y=math.floor(enemy_y/256)
    end
        
    return false
end

function Creature:meal()
 --p(self:printloc() .. "feeding with from " .. self.actfood .. " food, now have: " .. self:food() .."f, " .. self:health() .."h")
-- have a nice meal
self.actfood = get_tile_food(self.id)
-- trigger circle search around it 
 if self.actfood>10 and not self.bigmeal then
 	--p("set bigmeal")
	self.bigmeal=true
	self.bx,self.by=self:pos()
	self.bx=math.floor(self.bx/256)
	self.by=math.floor(self.by/256)
	self.bmc=1
 end
 
-- that much? tell the others 
 if self.actfood>400 then
	if self.actfood>foodval then	
	    foodsource=true
	    foodval=self.actfood
	    fx,fy=self:pos()
	else
		foodsource=false
	end
 else 
	if self.xg==math.floor(fx/256) and self.yg==math.floor(fy/256) then
	  foodsource=false
	  foodval=0
	end
	
 end	
 self:begin_eating()
 self:wait_for_next_round()
 end

function Creature:checkfordeaths()
	if globatt_id ~= nil then
	
	for d,k in _killed_creatures do
		p(d.."=>"..k)
		if d==globatt_id then
			globatt=false
		end
	end
	end
end


function Creature:swarmlogic()
	
--react on global stuff
	self.t=get_type(self.id)
	
	if convergea and self.t==1 then
		--p("attack-merge")
		self.tx,self.ty=convx,convy
		self.txg=math.floor(self.tx/256)
		self.tyg=math.floor(self.ty/256)	
	end
	
	if foodsource==true and self.bigmeal==false then
		--p("---------------swarm mode food-------------")
		--p("---converge on "..fx..":"..fy.."-----------")
		self.txg,self.tyg=math.floor(fx/256),math.floor(fy/256)
		self.bigmeal=true
		self.bx,self.by=math.floor(fx/256),math.floor(fy/256)
		self.bmc=1
	end
end

function Creature:num()
	return count
end

function Creature:getpivot()
--    define moving swarm attracktor 
	timevalue=game_time()
	local thres=range/4
	local nowval = math.mod(timevalue,range)
	
	local dx=math.abs((x2-x1)/4)
	local dy=math.abs((y2-y1)/4)
	local cx,cy=math.abs((x2-x1)/2),math.abs((y2-y1)/2)
	local ex,ey=0,0
	if nowval<thres then
		ex,ey=cx+dx,(cy-dy)+(nowval/(thres*4))*dy
	        --p(ex..":"..ey.." edge 0")
	elseif (nowval>=thres and nowval<thres*2) then
		ex,ey=(cx-dx)+(nowval/(thres*4))*dx*2,cy+dy
	--p(ex..":"..ey.." edge 1")
	elseif (nowval>=thres*2 and nowval <thres) then
		ex,ey=cx-dx,(cy+dy)-(nowval/(thres*4))*2*dy
 	  --      p(ex..":"..ey.." edge 2")
	elseif (nowval>=thres*3) then
		ex,ey=(cx-dx)+(nowval/(thres*4))*dx*2,cy-dy
	--p(ex..":"..ey.." edge 3")
	end	
	
	return ex,ey
end

function Creature:searchgrid(cx,cy,count)
	gx,gy=cx,cy
	if count==1 then
		gx=gx+1
	elseif count==2 then
		gx=gx+1
		gy=gy+1
	elseif count==3 then
		gy=gy+1
	elseif count==4 then
		gy=gy+1
		gx=gx-1
	elseif count==5 then
		gx=gx-1
	elseif count==6 then
		gx=gx-1
		gy=gy-1
	elseif count==7 then
		gy=gy-1
	elseif count==8 then
		gy=gy-1
		gx=gx+1
	end
	--local scale=math.random(2)
	local scale=1
	gx=math.mod(gx,gridx) 
	gy=math.mod(gy,gridy) 
	
	return gx,gy
end

function Creature:rndcircle(cx,cy,r)
	local dx=math.random(r*2+1)-r
	local dy=math.random(r*2+1)-r
	return cx+dx,cy+dy
end

function Creature:getnearestfood(sx,sy)
--todo	
end

function Creature:getvalidtarget(tx,ty)
-- whereto based on pheromon traces/random

	local nx,ny=0,0
	if fgrid[tx][ty]==nil then fgrid[tx][ty]=0 end
	if (grid_x[tx][ty]~=nil and grid_y[tx][ty]~=nil) and fgrid[tx][ty]>0 and foodsource==false then
		return grid_x[tx][ty],grid_y[tx][ty]
	else
	if foodsource then
		return self:rndcircle(math.floor(fx/256),math.floor(fy/256),3)
	end
	nx=math.random(gridx)
	ny=math.random(gridy)
	if fgrid[nx][ny]==nil or fgrid[nx][ny]==nil then fgrid[nx][ny]=0 end
	
	local steps = 0
	 while (not self:set_path(nx*256,ny*256)) or (fgrid[nx][ny]==0 and steps< 200) do
	  nx=math.random(gridx)
	  ny=math.random(gridy)	
	  --p("random? -> "..nx..":"..ny)
	  steps=steps+1
	 end
	 grid_x[tx][ty]=nx
	 grid_y[tx][ty]=ny	
	   local kx,ky=get_koth_pos()
           fgrid[math.floor(kx/256)][math.floor(ky/256)]=1
	   nx,ny=kx,ky
	end
	return nx,ny
end

-- write pheromon trace

function Creature:updatepath(a,b,c,d)
	--p(a..":"..b.."->"..c..":"..d)
	a=math.mod(a,gridx)
	b=math.mod(b,gridy)
	grid_x[a][b]=c
	grid_y[a][b]=d
	if a>2 and a<gridx and b>2 and b<gridy then
	
	grid_x[a-1][b]=c
	grid_y[a-1][b]=d
	grid_x[a][b-1]=c
	grid_y[a][b-1]=d
	grid_x[a+1][b]=c
	grid_y[a+1][b]=d
	grid_x[a][b+1]=c
	grid_y[a][b+1]=d
	grid_x[a+1][b+1]=c
	grid_y[a+1][b+1]=d
	grid_x[a-1][b-1]=c
	grid_y[a-1][b-1]=d
	end
end

-- run forest run, but whereto?
function Creature:escaperoute()
 local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
 local ex,ey=self:pos()
 nx,ny=self:getvalidtarget(math.floor(ex/256),math.floor(ey/256))
 return nx,ny
end

-- go kill next bastard
function Creature:attacknearest()
	local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
	self:kattack(enemy_id,enemy_dist,enemy_x,enemy_y)
end

-- help, im dying
function Creature:sethelpcall()
	local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
	globatt_x,globatt_y=self:pos()
	globatt_x,globatt_y=math.floor(globatt_x/256),math.floor(globatt_y/256)
	globatt_id=enemy_id	
end

function Creature:setwalkto(tx,ty)
	self.txg=tx
	self.tyg=ty
end

function Creature:executemove()
	set_message(self.id,"k_moving")
	if self.txg==nil or self.tyg==nil then
		self.txg=0
		self.tyg=0
	end
	if math.abs(self.txg-self.xg)>1 or math.abs(self.tyg-self.yg)>1 then
		self:set_path(self.txg*256,self.tyg*256)
		self:begin_walk_path()
		self:wait_for_next_round()
	end
end

function Creature:main()
	set_message(self.id,self.id.." of "..player_number)
	if globatt_id==nil then globatt_id=-2 end        
	self:checkfordeaths()
	self.x,self.y=self:pos()
	self.xg,self.yg=math.floor(self.x/256),math.floor(self.y/256)
	if sc ~= count then
		count=self:checkcount_hardcore()
		p("new count = " ..count)
		sc=count 		
		if sc>3 then 
			hardcore= true
			p("adavanced swarm-logic enabled")
		else
			hardcore=false
			p("advanced swarm-logic disabled")
		end
	end
	self.hp = get_health(self.id)
		         
	if self:checkfordanger() then
		if self.t==0 then
			--p("danger will robinson danger")
			self.txg,self.tyg=self:escaperoute()
			self:sethelpcall()		
		else
			self:attacknearest()
		end
		self:wait_for_next_round()
	end
	
-- keine gefahr mehr ...	
    self:expand()
    self.localfood=get_tile_food(self.id)
    
    if (get_state(self.id)==CREATURE_SPAWN) then
    	self:wait_for_next_round()
    end
    
    self:checkdata()
    
           fgrid[self.xg][self.yg]=self.localfood 
    if self.lfxg==nil or self.lfyg==nil then
    	self.lfxg=self.xg
	self.lfyg=self.yg
    end
    
   fgrid[self.xg][self.yg]=self.localfood
    
    if self.localfood>50 then
		self.lfxg=self.xg
		self.lfyg=self.yg
    end
    
    if (self.lfxg-self.xg )+(self.lfyg-self.yg)>9 then
    	self:updatepath(self.xg,self.yg,self.lfxg,self,lfyg)
    end
        
    if self.attacked then
    	self:reactattack()
    end
    
    
    self:swarmlogic()
    self.h=self:hunt()     

    if self.localfood>1 then
    	--p(self:printloc() .. "eating -----")
        self:meal()
    else 
    	if math.abs(self.lfxg-self.xg)<2and math.abs(self.lfyg-self.yg)<2 then
	if self.bigmeal then
		self.bmc=self.bmc + 1
		if self.bmc>8 then
			self.bigmeal=false
			self.bmc=1
			--p("bigmeal reset ----")
		end	
		self.txg,self.tyg=self:searchgrid(self.bx,self.by,self.bmc-1)
	else
		if hardcore then
			local px,py=self:getpivot()		
			self.txg,self.tyg=self:rndcircle(px,py,5)
		else
			self.txg,self.tyg=self:getvalidtarget(self.xg,self.yg)
		end	
	end
	--p(self:printloc() .. " newtarget " .. self.tx .." " .. self.ty)
    	end
       end
    self:executemove()
if get_state(self.id)==CREATURE_IDLE or self.txg==nil or self.tyg==nil then
    	self.txg,self.tyg = self:getvalidtarget(self.xg,self.yg)
	p("idlecatch ---------")
	self:hunt()
     end
	
     self:executemove()
    
end

