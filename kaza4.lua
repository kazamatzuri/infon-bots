--------------kbot version 0.5-----------------
-- this bot is GPL
-- questions & stuff -> kazamatzuri@informatik.uni-wuerzburg.de
-- author kazamatzuri
-----------------------------------------------


--global communication
COUNT=0
HUNTRANGE=16*256
HUNTTHRESHOLD=10
DECAYFACTOR=2
--FOODWEIGHT_A=FOODWEIGHT
FOODWEIGHT=6
--food above threshold -> into map
FOODTHRESHOLD=20
ENEMYWEIGHT=10
ENEMYWEIGHTAT=5
EATWEIGHT=4
ASSISTRANGE=7*256
--count BOTAVERAGE last steps in speedkeep
BOTAVERAGE=20
GRAVWEIGHT=5
--bots not bound by swarm law
ROGUEBOTSMOD=10
--RANDOMWALK max step size
STEPSIZE=6*256
--
CLUMBMODE=1
CLUMBSIZE=1.5*256
gravupdate=0
swt={0,0}
x1, y1, x2, y2 = world_size()
gridx=math.floor(x2/256)
gridy=math.floor(y2/256)
attacked={}
foodmap={}
enemys={}
a_enemys={}
-- first gravity center

gx,gy=get_koth_pos()
g={gx,gy}
function Creature:kpos()
    local rx,ry=self:pos()
    return {rx,ry}
end

-- initialization
function Creature:onSpawned()
    print("new bot enters the world ")
    COUNT=COUNT+1
    self.wt=self:getrandomstep()
    self.steps={}
    local i = 0    
    for i=1,BOTAVERAGE do
        self.steps[i]={}
    end
    self.cstep=0
end

-- overwriting global info (keypress i in telnetserver)
-- to be a bit more talkative
function info()
    local chkd=0
    for id, creature in creatures do
    	posx,posy=get_pos(id)
        print(id .. ":" ..get_type(id) .. " on "..posx..":"..posy .. "==> hp:"..get_health(id)..". food:"..get_food(id) .." state:" ..
	get_state(id).." punkte: "..player_score(player_number))
        chkd=chkd+1
    end
    print("colony state: "..COUNT.." gravitycenter: "..math.floor(g[1]/256)..":"..math.floor(g[2]/256))
    COUNT=chkd
end

function suicideall()
    for id,creature in creatures do
        suicide(id)
    end
end


function Creature:onAttacked(attacker)
    attacked[self.id]=true
end


function Creature:onKilled(killer)
    if killer == self.id then
        print("kbot " .. self.id .. " suicided")
    elseif killer then 
        print("kbot " .. self.id .. " killed by Creature " .. killer)
    else
        print("kbot  " .. self.id .. " starved")
    end
    COUNT=COUNT-1
    attacked[self.id]=false
--    foodmap[self.id]=nil
    --foodmap[killer]=nil
end

function Creature:checkcount_hardcore()
    -- sometimes the own counting isn't right, so we have to check hardcore style
	local scnum=0
	for i,id in creatures do
		scnum=scnum+1
	end
	return scnum
end

function Creature:printloc()
    -- talkative debug
	self.mx,self.my=self:pos()
	return ( self.id..":"..get_type(self.id).." on  "..self.mx .. ":"..self.my.." ")
end

function Creature:checkdata()
    -- per round data 
    self.loc=self:kpos()    
    self.t=self:type()
    self.actfood=get_tile_food(self.id)
    self.hp = self:health()
end

function Creature:dist(x0,y0,x1,y1)
	return (math.sqrt((x0-x1)^2+(y0-y1)^2))
end

function Creature:reactattack()
    --p("------under attack-----")
    -- i am attacked
    local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
    a_enemys[enemy_id]=true
    enemys[enemy_id]={enemy_x,enemy_y}
    --todo: need attacked bool??
end

function Creature:expand()
    -- spawn/evolve
    if (self:food() > 8001 and get_type(self.id)==0 )then
        set_convert(self.id,1)
    	set_state(self.id,CREATURE_CONVERT)
        --p("evolving <<<<<<<<<<<<<<")
        return true    
    end
    
    if (self:food() > 8001 and get_type(self.id)==1 and get_health(self.id)>40)then
    	set_state(self.id,CREATURE_SPAWN)
        return true 
    end
    return false
end


function Creature:getnearestwar()
    local actmin=-1
    local minx,miny=0,0
    local min = gridx*256
    local d = 0 
for i,c in creatures do
		local x,y =get_pos(i)
        if attacked[i] then
            d = get_distance(self.id,i)
            if d<min then 
            min=d
            actmin=i            
            end
        end
end
    if actmin==-1  then
        return nil
    else
        local t,v=get_pos(actmin)
        return {t,v}
    end        

end

function Creature:hunt()
    local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
    if enemy_id==nil then
        --p("no enemy")
        return false
    end
    
    --if attacked[self.id]==true then
    --    if get_type(self.id)==0 then
    --        self:setescaperoute()
    --        self:wait_for_next_round()
    --    end
    -- end

    if enemy_dist > 512 then
        attacked[self.id]=false
    end

    if get_type(self.id)==0 then 
        return false
    end    
    
    helpe=self:getnearestwar()
    if helpe~=nil then
    local x,y=get_pos(self.id)
    local d = self:dist(x,y,helpe[1],helpe[2])
        if d > 512 and d < ASSISTRANGE then
            self.assistmode=true
            self.wt=helpe
            set_path(self.id,helpe[1],helpe[2])        
            set_state(self.id,CREATURE_WALK)
            return true
        end
    end
        
    local enemy_type = get_type(enemy_id)   
    local enemy_health=get_health(enemy_id)
    enemys[enemy_id]={enemy_x,enemy_y}
    -- enemy to near? not my fault *G
    if enemy_dist < 512 then
        self:set_target(enemy_id)
        --attacked[id]=true
    	set_state(self.id,CREATURE_ATTACK)
        --self:kattack(enemy_id,enemy_dist,enemy_x,enemy_y)
        return true
    end
    
    -- easy prey anywhere?

    if enemy_dist < HUNTRANGE and enemy_type==0 and self.t==1 and self.hp>20 then    	
        p("gone hunting------------")
        self.wt={enemy_x,enemy_y}
        set_path(self.id,enemy_x,enemy_y)
        return false
    end
    return false
end

function Creature:meal()
 --p(self:printloc() .. "feeding with from " .. self.actfood .. " food, now have: " .. self:food() .."f, " .. self:health() .."h")
-- have a nice meal
 self.actfood = get_tile_food(self.id)
-- trigger circle search around it 
  
    if self.actfood>FOODTHRESHOLD then
        foodmap[self.id]=self.loc
    else
        foodmap[self.id]=nil
    end
    if self.actfood>0 then
        set_state(self.id,CREATURE_EAT)        
        return true
    else 
        return false
    end
 end

	
function Creature:sign(x)
    if x<0 then return -1 
    else return 1
    end
end
function Creature:rndcircle(c,r)
	local dx=math.random(r*2+1)-r
	local dy=math.random(r*2+1)-r
        dx=dx+self:sign(dx)*512
        dy=dy+self:sign(dy)*512
	return {c[1]+dx,c[2]+dy}
end

function Creature:getnearestwarrior()
    local actmin=-1
    local minx,miny=0,0
    local min = gridx*256
    local d = 0 
for i,c in creatures do
        if get_type(i)==1 then
		    local x,y =get_pos(i)
            d = get_distance(self.id,i)
            if d<min then 
            min=d
            actmin=i            
            end
        end
end
    if actmin==-1  then
        return {get_koth_pos()}
    else
        return {get_pos(actmin)}
    end        

end

-- run forest run, but whereto?
function Creature:setescaperoute()
-- todo update to new format 
 local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
 local ex,ey=self:pos()
 local nx= -(enemy_x-ex)+ex
 local ny= -(enemy_y-ey)+ey
 local n={}
 if not set_path(self.id,nx,ny) then
    n=self:getnearestwarrior()
    set_path(self.id,n[1],n[2])
    self.wt=n
 end
end

function Creature:updategravitycenter()
--p("updategrav")
local ng={}
local lcount=0
local realcount=0
ng[1]=0
ng[2]=0
for id, creature in creatures do
    lcount=lcount+1
    realcount=realcount+1
    local x,y=get_pos(id)
    if get_state(id)==CREATURE_EAT then    
        ng[1],ng[2]=ng[1]+x*EATWEIGHT,ng[2]+y*EATWEIGHT
        lcount=lcount+EATWEIGHT-1
    else 
        ng[1],ng[2]=ng[1]+x,ng[2]+y
    end
end

COUNT=realcount
--todo move gravity in clumbmode better
--if COUNT<CLUMBMODE then
--    g=self:getrandomstep()
--    return
--end
--lcount=1
if COUNT>HUNTTHRESHOLD then
    for i,c in enemys do
        if creature_exists(i) then
		    local x,y =get_pos(i)
		    ng[1]=(ng[1]+ENEMYWEIGHT*x)
    	    ng[2]=(ng[2]+ENEMYWEIGHT*y)
	    else
		    enemys[i]=nil
	    end
        --p(ng[1]..":"..ng[2])
        lcount=lcount+ENEMYWEIGHT
    end
end

for i,c in foodmap do
    ng[1]=(ng[1]+FOODWEIGHT*c[1])
    ng[2]=(ng[2]+FOODWEIGHT*c[2])
    lcount=lcount+FOODWEIGHT
end

g[1],g[2]=ng[1]/lcount,ng[2]/lcount
if COUNT<CLUMBMODE then 
    STEPSIZE=CLUMBSTEPSIZE
    ROGUEBOTSMOD=5
elseif COUNT>10 and COUNT<20 then 
    STEPSIZE=10*256
    ROGUEBOTSMOD=6
elseif COUNT>20 and COUNT<40 then 
    STEPSIZE=7*256
    ROGUEBOTSMOD=8
else
    STEPSIZE=5*256
    ROGUEBOTSMOD=7
end

end

function Creature:nearfood()
    local erg=false
    if self.lgs==nil then self.lgs={} end 
    for i=1,5 do
        if self.lgs[1]==true then
            erg=true
        end
    end
    return erg
end

function Creature:clearfoodmap()
    for i=2,gridx-1 do 
        for j=2,gridy-1 do
            local max=0
            for c=i-1,i+1 do
                for v=j-1,j+1 do
                    if foodmap[i+c+(j+v)*gridx] > max then
                        max=foodmap[i+c+(j+v)*gridx]
                    end    
                end
            end
        end
    end
end

function Creature:getrandomstep()
    local x,y=self:pos()
    if self.v==nil then 
        self.v={}
    end

    if self.v[1]==nil then 
        self.v[1]=0 
        self.v[2]=0
    end
    local pivot={}
    
    if math.mod(self.id,ROGUEBOTSMOD)==0 then
        pivot[1]=self.v[1]*2+x
        pivot[2]=self.v[2]*2+y
    else
        pivot[1]=self.v[1]*2 + (x+GRAVWEIGHT*g[1])/(GRAVWEIGHT+1)
        pivot[2]=self.v[2]*2 + (y+GRAVWEIGHT*g[2])/(GRAVWEIGHT+1)
    end    
    local s = 1
    if self:nearfood() then
--        pivot[1],pivot[2]=get_pos(self.id)
        s=723
    else
       s = STEPSIZE
    end
    local n = {}
    local sc=CLUMBSIZE
    
    repeat
    if COUNT<CLUMBMODE then
        n = self:rndcircle(g,sc)
        sc=sc+128
    else
        n = self:rndcircle(pivot,s)
        s=s+256
    end
    --p("calc "..pivot[1]..":"..pivot[2].."__"..s)
    until set_path(self.id,math.floor(n[1]),math.floor(n[2]))

    local delta={}    
    delta[1]=math.floor(n[1]-x)
    delta[2]=math.floor(n[2]-y)

    n[1]=math.floor(n[1])
    n[2]=math.floor(n[2])
    
    self.v[1]=(self.v[1]*BOTAVERAGE+delta[1])/(BOTAVERAGE+1)
    self.v[2]=(self.v[2]*BOTAVERAGE+delta[2])/(BOTAVERAGE+1)
    
    return n
end

function Creature:getnearestfood()
    local actmin=-1
    local minx,miny=0,0
    local min = gridx*256
    local d = 0 
for i,c in creatures do
        if get_state(i)==CREATURE_EAT then
		    local x,y =get_pos(i)
            d = get_distance(self.id,i)
            if d<min then 
            min=d
            actmin=i            
            end
        end
end
    if actmin==-1  then
        return nil
    else
        return {get_pos(actmin)}
    end        
end

function Creature:move()
    local x,y=self:pos()
    if self.actfood < 10 then 
        local nf=self:getnearestfood()
        if nf ~=nil then self.wt=self:getnearestfood() end
    end
    if self:dist(x,y,self.wt[1],self.wt[2]) < 10 then
        local newc=self:getrandomstep()
        self.wt=newc
        self:set_path(newc[1],newc[2])
    else
        if self:nearfood() then self.wt=self:getrandomstep() end
        set_path(self.id,self.wt[1],self.wt[2])
    end
   set_state(self.id,CREATURE_WALK)
    return true
end

function Creature:heal()
    if self:food()>2000 and get_health(self.id)< 50 then
        set_state(self.id,CREATURE_HEAL)
        return true
    else
        return false
    end
end

function Creature:checkmoved()
    local x,y=get_pos(self.id)
    local xg,yg=math.floor(x/256),math.floor(y/256)
    if self.lgs==nil then self.lgs={} end    

    if self.oldxg==nil then
        self.oldxg=xg
        self.oldyg=yg
        if get_tile_food(self.id)>0 then
            self.lastgridhadfood=true
        else
            self.lastgridhadfood=false
        end
    end

   if get_tile_food(self.id)>0 then
       self.lastgridhadfood=true
   else
       self.lastgridhadfood=false
   end
    
    if self.oldxg~=xg or self.oldyg~=yg then
        --p(self.id.." moved to "..xg..":"..yg)
        self.oldxg=xg
        self.oldyg=yg
        self.lgs[5]=self.lgs[4]
        self.lgs[4]=self.lgs[3]
        self.lgs[3]=self.lgs[2]
        self.lgs[2]=self.lgs[1]
        self.lgs[1]=self.lastgridhadfood
    end
    
end

function Creature:main()
--	set_message(self.id,self.id.."OF"..player_number)
    if self.wt==nil then self.wt=self:kpos() end
    if math.abs(gravupdate-game_time())>10000 then
        self:updategravitycenter()
        gravupdate=game_time()
    end
    
    self:checkmoved()
    
    while self:is_converting() or self:is_spawning() do
        self:wait_for_next_round()
    end
    
    while self:is_healing() do
        --if attacked[self.id]==false then
            self:wait_for_next_round()
        --end
    end

 set_message(self.id,self.id.."OF"..player_number)  
    if self:hunt() then
    elseif self:expand() then
--        set_message(self.id,"evolving")
    elseif self:heal() then
--        set_message(self.id,"healing")
    elseif self:meal() then
--        set_message(self.id,"eating")
    elseif self:move() then
--        set_message(self.id,"moving")
    else 
--        set_message(self.id,"else ")
    end
    self:wait_for_next_round()    
    
end

