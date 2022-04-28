--------------kbot version 0.5-----------------
-- this bot is GPL
-- questions & stuff -> kazamatzuri@informatik.uni-wuerzburg.de
-- author kazamatzuri
-----------------------------------------------

KOTHBOTLIMIT=10
KOTHBOT=-1
COUNT=0

FEEDMODETHRESHOLD=0.5
INNERCIRCLE=4*256
HUNTRANGE=4*256
NOHUNTTHRESHOLD=5

foodgrid={}
gravupdate=0
grid={}
SEARCHRUN=1
SEARCHFIELDSIZE=10
SEARCHFIELDACT={0,0}
searchgrid={}
foodmap={}
x1, y1, x2, y2 = world_size()
gridx=math.floor(x2/256)
gridy=math.floor(y2/256)

function Creature:kpos()
    local rx,ry=self:pos()
    return {rx,ry}
end

-- initialization
function Creature:onSpawned()
    print("new bot enters the world ")
    self.lastmaxfood={0,0}
    self.lastmaxfoodv=0
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
    COUNT=chkd
end

function suicideall()
    for id,creature in creatures do
        suicide(id)
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
    if KOTHBOT==self.id then KOTHBOT=-1 end    
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


function Creature:dist(x0,y0,x1,y1)
	return (math.sqrt((x0-x1)^2+(y0-y1)^2))
end

function Creature:reactattack()
    --p("------under attack-----")
end

function Creature:expand()
    -- spawn/evolve
    if (self:food() > 8020 and get_type(self.id)==0 and not FEEDMODE) then
        set_convert(self.id,1)
    	set_state(self.id,CREATURE_CONVERT)
        --p("evolving <<<<<<<<<<<<<<")
        return true    
    end
    
    if (self:food() > 8020 and get_type(self.id)==1 and get_health(self.id)>40)then
    	set_state(self.id,CREATURE_SPAWN)
        return true 
    end
    return false
end



function Creature:hunt()
    if get_type(self.id)==0 then 
        return false
    end    

    local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
    if enemy_id==nil then
        --p("no enemy")
        return false
    end
    
    if enemy_dist>512 then
        self.attacked=false
    end
        

    local enemy_type = get_type(enemy_id)   
    local enemy_health=get_health(enemy_id)
    if enemy_dist < 512 then
        self:set_target(enemy_id)
    	set_state(self.id,CREATURE_ATTACK)       
        self.huntmode=true
        return true
    end    

    -- easy prey anywhere?
    if enemy_dist < HUNTRANGE and enemy_type==0 and self.t==1 and self.hp>20  and COUNT>NOHUNTTHRESHOLD then    	
        self.huntmode=true
        return false
    end
    return false
end

function Creature:turn_to(x1,x2)
        if self.dir==nil then self.dir=self:getdirection() end
        self.dir=self.dir+self:get_ankle(math.cos(self.dir),math.sin(self.dir),x1,x2)
end

function Creature:get_length(x1,x2)
    return math.sqrt(x1^2+x2^2)
end

function Creature:get_ankle(x1,y1,x2,y2)
    local mx,my=get_pos(self.id)
    local z=(x1*x2+y1*y2)
    local n=self:get_length(x1,y1)*self:get_length(x2,y2)
    return math.asin(z/n)
end

function Creature:updatefoodgrid()
    local x,y=get_pos(self.id)
    local gx,gy=math.floor(x/256),math.floor(y/256)    
    local blub=game_time()
    local t=gx+gy*gridx
    foodmap[t]={true,blub}
end

function Creature:meal()
 self.actfood = get_tile_food(self.id)
    if self.actfood>50 then 
	self.foodsearch=true
    end
    if self.actfood>0 then
        set_state(self.id,CREATURE_EAT)        
        self:updatefoodgrid()
        return true
    else 
        return false
    end
 end

	
function Creature:rndcircle(c,r)
	local dx=math.random(r*2+1)-r
	local dy=math.random(r*2+1)-r
	return {c[1]+dx,c[2]+dy}
end

-- run forest run, but whereto?
function Creature:escaperoute()
-- todo update to new format 
 local enemy_id, enemy_x, enemy_y, enemy_playernum, enemy_dist = nearest_enemy(self.id)
 local ex,ey=self:pos()
 nx,ny=self:getvalidtarget(math.floor(ex/256),math.floor(ey/256))
 return nx,ny
end

function Creature:updategravitycenter()
--p("updategrav")
local ng={}
local lcount=0
local realcount=0
local warriorcount=0
ng[1]=0
ng[2]=0
local avfood=0
for id, creature in creatures do
    lcount=lcount+1
    realcount=realcount+1
    if COUNT>KOTHBOTLIMIT and get_type(id)==1 and KOTHBOT==-1 and get_health(id)>50 then
        KOTHBOT=id
    end

    if get_type(id)==1 then 
        local x,y=get_pos(id)
        warriorcount=warriorcount+1 
        ng[1]=ng[1]+x
        ng[2]=ng[2]+y       
    end
end

if warriorcount~=0 then
    g[1]=ng[1]/warriorcount
    g[2]=ng[2]/warriorcount
end
if COUNT<=KOTHBOTLIMIT then KOTHBOT=-1 end

COUNT=realcount
WCOUNT=warriorcount
INNERCIRCLE=2*256+(1.105^WCOUNT)*256


if warriorcount==1 and COUNT==2 then
    FEEDMODE=true
elseif (WCOUNT/COUNT)>FEEDMODETHRESHOLD and COUNT>1 and COUNT<40 then
    --p("feedmode on")
    FEEDMODE=true
else
    --p("feedmode off")
    FEEDMODE=FALSE
end

end


function Creature:issearched(sfx,sfy)
local searched=true
local jetzt=game_time()
    for i=1,SEARCHFIELDSIZE do
        for j=1,SEARCHFIELDSIZE do  
            if searchedmap[sfx*SEARCHFIELDSIZE+sfy*SEARCHFIELDSIZE*gridx][1]~=nil then
            if searchedmap[sfx*SEARCHFIELDSIZE+sfy*SEARCHFIELDSIZE*gridx][1]~=SEARCHRUN then
                return false
            end
            end
        end
    end
end

function Creature:getnextsearchfield()
    local s=math.floor(x2/(256*SEARCHFIELDSIZE))
    local sy=math.floor(y2/(256*SEARCHFIELDSIZE))
    SEARCHFIELDACT[1]=SEARCHFIELDACT[1]+1

    if SEARCHFIELDACT[1]>=s then
        SEARCHFIELDACT[1]=SEARCHFIELDACT[1]-1
        SEARCHFIELDACT[2]=SEARCHFIELDACT[2]+1
    end
    
    if SEARCHFIELDACT[2]>=sy then
        SEARCHFIELDACT[1]=0
        SEARCHFIELDACT[2]=0
        SEARCHRUN=SEARCHRUN+1
    end
end


function Creature:getnextstep()    
    local x,y=0,0
    local sx,sy=0,0
    local size=SEARCHFIELDSIZE^2
    local t=0
    for i = 1, SEARCHFIELDSIZE do
        for j = 1,SEARCHFIELDSIZE do
-- weitermachen                
        end
    end
    return {get_koth_pos()}
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
   
    if self.id==KOTHBOT then
        return get_koth_pos()
    end
    local pivot={}
   
    pivot[1]=self.v[1]*2 + (x+GRAVWEIGHT*g[1])/(GRAVWEIGHT+1)
    pivot[2]=self.v[2]*2 + (y+GRAVWEIGHT*g[2])/(GRAVWEIGHT+1)

    local s = STEPSIZE
    local n = {}
    local sc=1    

    repeat        
    if get_type(self.id)==1 then
        n = self:rndcircle(g,INNERCIRCLE+sc)
        sc=sc+128
    else
        n = self:rndcircle(pivot,s)
        s=s+256
    end

    --p("calc "..pivot[1]..":"..pivot[2].."__"..s)
    until set_path(self.id,math.floor(n[1]),math.floor(n[2]))

    local delta={}    
    delta[1]=math.floor(-n[1]+x)
    delta[2]=math.floor(-n[2]+y)

    n[1]=math.floor(n[1])
    n[2]=math.floor(n[2])
    
    self.v[1]=(self.v[1]*BOTAVERAGE+delta[1])/(BOTAVERAGE+1)
    self.v[2]=(self.v[2]*BOTAVERAGE+delta[2])/(BOTAVERAGE+1)
    
    return n
end


function Creature:getnearestfood()    
    local min = gridx*2561
    local actmin = -1
    local minx,miny=0,0    
    local blub=game_time()

    for id,creature in creatures do
        local d= get_distance(self.id,id)
        if d<min and get_state(id)==CREATURE_EAT then
            min=d
            actmin=id
            minx,miny=get_pos(id)
        end
    end
    
    local bx,by=self
    if actmin==-1 then 
        return self.dir
    else
        return self:get_ankle(math.cos(self.dir),math.sin(self.dir),minx,miny)
    end
end

function Creature:getnearesteating()
    local min=gridx*256
    local actmin=-1
end

function Creature:move()
    local x,y=self:pos()
    if self.id==KOTHBOT then
        local x,y=get_koth_pos()
        set_state(self.id,CREATURE_WALK)
        if get_health(self.id)<50 then
            KOTHBOT=-1
        end
    elseif self:dist(x,y,self.wt[1],self.wt[2]) < 5 then
        self.wt=self:getnextstep()
        self:set_path(self.wt[1],self.wt[2])
        set_state(self.id,CREATURE_WALK)
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

function Creature:updategrid()
    local x,y=self:pos()
    local t=math.floor(x/256)+math.floor(y/256)*gridx
    if grid[t]==nil then 
        grid[t]={true,0}
    else        
        searchgrid[t]=SEARCHRUN
    end        
end

function Creature:getnearestmaster()
    local actmin=-1
    local min=gridx*256
    for id,creature in creatures do
        if get_type(id)==1 then
            local d=get_distance(self.id,id)
            if d < min then
                actmin=id
                min=d
            end
        end
    end
    
    if actmin==-1 then 
        return nil
    else
        local x,y=get_pos(actmin)
        return {x,y,actmin}
    end

end


function Creature:go_feed()
    if self:food()>5000 and self:health()>60 and get_type(self.id)==0 then
        local m=self:getnearestmaster()
        if m==nil then 
            return false
        end 
        if self:dist(m[1],m[2],self.loc[1],self.loc[2]) < 256 then
            set_target(self.id,m[3])
            set_state(self.id,CREATURE_FEED)
            return true
        else
            self:turn_to(m[1],m[2])                        
            set_state(self.id,CREATURE_WALK)
        end
    end
end

function Creature:getdirection()
    return math.random(360)/(2*3.14159265359)
end

function Creature:main()
--	set_message(self.id,self.id.."OF"..player_number)
    if self.wt==nil then self.wt=self:kpos() end
    self.loc=self:kpos()
    if  self.dir==nil then self.dir=self:getdirection() end
    
    self.gridloc={math.floor(self.loc[1]/256),math.floor(self.loc[2]/256)}
    if self.foodstepping==nil then self.foodstepping=1 end
    self.huntmode=false
    self.t=self:type()
    self.hp = self:health()

    if math.abs(gravupdate-game_time())>5000 then
        self:updategravitycenter()
        gravupdate=game_time()
    end
    
    while self:is_converting() or self:is_spawning() do
        self:wait_for_next_round()
    end

    while self:is_healing() and self.attacked==false do
        self:wait_for_next_round()
    end

    while self:is_feeding() and self:food()>1000 and self.attacked==false do
        self:wait_for_next_round()
    end

    self.actfood=get_tile_food(self.id)
    self:updategrid()
    
    if self:hunt() then
        set_message(self.id,"hunting")
    elseif FEEDMODE and self:go_feed() then        
        set_message(self.id,"feeding")
    elseif self:expand() then
        set_message(self.id,"evolving")
    elseif self:heal() then
        set_message(self.id,"healing")
    elseif self:meal() then
        set_message(self.id,"eating")
    elseif self:move() then
        if KOTHBOT==self.id then
            set_message(self.id,"KINGBOT")
        else
            set_message(self.id,"moving")
        end
    else 
        set_message(self.id,"else ")
    end
    self:wait_for_next_round()    
    
end
