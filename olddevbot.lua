
x1,y1,x2,y2=world_size()
gridx,gridy=math.floor(x2/256),math.floor(y2/256)
FEEDMODE=false
KOTHBOT=-1
general=0

function Creature:heal()
    if self:food()>2000 and get_health(self.id)< 50 then
        set_state(self.id,CREATURE_HEAL)
        return true
    else
        return false
    end
end

function Creature:getnearestmaster()
    local actmin=-1
    local min=gridx*256
    for id,creature in pairs(creatures) do
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
        return {x,y}
    end
end 

function Creature:onSpawned()
    self:setnextstep()
    p("init .."..self.id)
end

function Creature:expand()
    -- spawn/evolve
    if (self:food() > 8001 and get_type(self.id)==0 and not FEEDMODE) then
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
            self.wtg={math.floor(self.wt[1]/256),math.floor(self.wt[2]/256)}
            set_path(self.id,self.wtg[1]*256+128,self.wtg[2]*256+128)                        
            set_state(self.id,CREATURE_WALK)
            return true
        end
    end
end


function Creature:meal()
    if self.actfood>0 then
        set_state(self.id,CREATURE_EAT)        
        return true
    else 
        return false
    end
 end

function Creature:onKilled()
end

function Creature:onAttacked()
end

function Creature:setnextstep()
    if self.wtxg==nil then
        self.wtyg=1
        self.wtxg=1
    end

    if get_type(self.id)==1 then
    local x,y =get_koth_pos()
	self.wtxg=(x/256)
 	self.wtyg=(y/256)
	set_path(self.id,x,y)
	p("newstep koth")
     
    end
    p("nextstep")
    repeat
    self.wtxg=self.wtxg+1
    if self.wtxg>=gridx then 
        self.wtxg=1
        self.wtyg=self.wtyg+1
    end
    if self.wtyg>=gridy then
        self.wtyg=1
    end
    
    until set_path(self.id,self.wtxg*256+128,self.wtyg*256+128)
    p("new step"..self.wtxg..":"..self.wtyg)
end

function info()
    local chkd=0
    for id, creature in pairs(creatures) do
        posx,posy=get_pos(id)
        print(id .. ":" ..get_type(id) .. " on "..posx..":"..posy .. "==> hp:"..get_health(id)..". food:"..get_food(id) .." state:" ..
    get_state(id).." punkte: "..player_score(player_number))
    end
end

function Creature:move()
    local x,y=self:pos()
    local tx,ty=get_koth_pos()
    if KOTHBOT==self.id then
        set_path(self.id,tx,ty)
        set_state(self.id,CREATURE_WALK)
    else
        if self.wtxg==self.xg and self.wtyg==self.yg then
            self:setnextstep()
            set_state(self.id,CREATURE_WALK)
            return true       
        else
--            p(self.wtxg..":"..self.wtyg.." is target loc:"..self.xg..":"..self.yg)
            if not set_path(self.id,self.wtxg*256+128,self.wtyg*256+128) then
                self:setnextstep()
                p("blub")
            end
            set_state(self.id,CREATURE_WALK)
        end
    
    end
    set_state(self.id,CREATURE_WALK)
end

function Creature:generalupdate()
end

function Creature:updategrid()
end

function Creature:main()
        
    self.x,self.y = get_pos(self.id)
    self.xg = math.floor(self.x/256)
    self.yg = math.floor(self.y/256)
    self.actfood=get_tile_food(self.id)
    if math.abs(game_time()-general)>5000 then
        self:generalupdate()
        general=game_time()
    end

    if math.abs(gravupdate-game_time())>10000 then
        self:updategravitycenter()
        
        gravupdate=game_time()
        p("gravupdate at " .. gravupdate)
    end

    self:updategrid()

    while self:is_healing() and self:food() > 500 do
        self:wait_for_next_round()
    end
    set_message(self.id,self.id.." OF "..player_number)

    if self:hunt() then
    elseif FEEDMODE and self:go_feed() then        
    elseif self:expand() then
    elseif self:heal() then
    elseif self:meal() then
    elseif self:move() then
        if KOTHBOT==self.id then
            set_message(self.id,"KINGBOT")
        end
    end

    self:wait_for_next_round()    

end
