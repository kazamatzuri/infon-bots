--------------------------------------------------------------------------
-- UrsBot 1
-- Forking like crazy and counterattacking if attacked (to the death)
-- Leaves Pheromone Trails to food.
--
-- Fuer jedes gespawnte Vieh wird eine eigene Creature Klasse instanziiert
--------------------------------------------------------------------------
-- TODO:
-- Zeugungsfaehige Tiere sollten ihre Umgebung clearen.

-- Tuneable constants:
MIN_FOOD = 8000    -- Bei weniger als dieser Essi-Anzahl mampfen gehen
MAX_FOOD = 10000   -- Bei mehr als dieser Essi-Anzahl, aufhoeren zu futtern (typ 0)
MAX_FOOD2 = 15000   -- Bei mehr als dieser Essi-Anzahl, aufhoeren zu futtern (typ 1)
CRIT_FOOD = 200    -- Bei weniger als dieser Essi-Anzahl, gar nicht erst heilen
MIN_HEALTH = 80   -- Bei weniger als dieser Health-Zahl heilen.
ATK_HEALTH = 20   -- Bei weniger als dieser Health-Zahl aufhoeren zu kaempfen
ATK_DIST = 256    -- Maximale angriffsdistanz

DIRECT_PROB = 30  -- Wahrscheinlichkeit, direkt zu essen zu gehen, wenn moeglich
MEAN_STEPS = 100 -- Schritte, ueber die das fliessende positionsmittel erstellt wird.

-- States fuer die Statemachine
BEH_NONE = 0    -- Startzustand, forkt oder futtert / heilt
BEH_FEED = 1    -- Essen Suchen, finden und essen
BEH_HEAL = 4    -- Heilen.
BEH_FLEE = 3    -- Irgendwohin wegrennen
BEH_FORK = 5    -- Forken und abwarten.
BEH_ATTACK = 2  -- Naechsen Gegner angreifen.

Creature.behaviour = BEH_NONE
known_food_x = {}
known_food_y = {}

function Creature:onSpawned()
    print("Creature " .. self.id .. " spawned")
    x1,y1,x2,y2 = world_size()
    self.behaviour = BEH_NONE
    self.floating_x, self.floating_y = get_pos(self.id)
end

function Creature:onAttacked(attacker)
    -- print("Help! Creature " .. self.id .. " is attacked by Creature " .. attacker)
    if get_state(self.id) == CREATURE_SPWAN or self.behaviour == BEH_FORK or self.behaviour == BEH_FLEE then
        -- continue forking or fleeing
   else
       -- counterattack (currently: flee)
       self.behaviour = BEH_ATTACK
   end
end

function Creature:onRestart()
    -- wird nach Eingabe von 'r' ausgefuehrt
    self.behaviour = BEH_NONE
    self.floating_x, self.floating_y = get_pos(self.id)
end

function Creature:onKilled(killer)
    if killer == self.id then
        print("Creature " .. self.id .. " suicided")
    elseif killer then 
        print("Creature " .. self.id .. " killed by Creature " .. killer)
    else
        print("Creature " .. self.id .. " died")
    end
end

-- nahrung suchen
function Creature:forage()
    local x,y = get_pos(self.id)
    local foodx,foody = get_nearest_known_food(x,y)

    if get_state(self.id) == CREATURE_IDLE then
        -- Zufaellig rumtapsen, mit hoher wahrscheinlichkeit, richtung bekanntem food zu gehen.
        if foodx ~= nil and math.random(100) <= DIRECT_PROB then
            if not set_path(self.id, foodx,foody) then
                print("gra!")
            end
            set_message(self.id, "-> food")
        else
            temp = true
            repeat 
                if (not temp) or self.speed_x ==0 or self.speex_x == nil then self.speed_x = (x - self.floating_x)+math.random(2048) - 1024 end
                if (not temp) or self.speed_y ==0 or self.speed_y == nil then self.speed_y = (y - self.floating_y)+math.random(2048) - 1024 end
                local target_x = x + self.speed_x;
                local target_y = y + self.speed_y;
                temp = set_path(self.id, target_x, target_y)
            until temp
            set_message(self.id, "food?")
        end
            
        -- Do it.
        if not set_state(self.id,CREATURE_WALK) then
            print("Moo")
        end
    elseif get_tile_food(self.id) > 0 then
        set_state(self.id,CREATURE_EAT)
    else
        -- print("Nix?")
    end

    -- Ein "kleiner" frisst bis 10000, ein grosser bis 15000
    if(get_type(self.id) == 0) then

        if(self:food() >= MAX_FOOD) then
            print("Creature " .. self.id .. " is now satiated.")
            self.behaviour = BEH_NONE
        end
    else
        if(self:food() >= MAX_FOOD2) then
            print("Creature " .. self.id .. " is now satiated.")
            self.behaviour = BEH_NONE
        end
    end
    if(self:health() < ATK_HEALTH and self:food() > 0) then
        print("Creature " .. self.id .. " stopping to eat in order to heal")
        self.behaviour = BEH_NONE
    end
end

-- fliehen
function Creature:flee(from_x, from_y)
    -- Laufe weg. (TODO: Besser machen) oder gar nicht?
    if from_x ~= nil then
        self.floating_x = from_x
        self.floating_y = from_y
    end
    temp = true
    repeat 
        if (not temp) or self.speed_x ==0 or self.speex_x == nil then self.speed_x = (x - self.floating_x)+math.random(2048) - 1024 end
        if (not temp) or self.speed_y ==0 or self.speed_y == nil then self.speed_y = (y - self.floating_y)+math.random(2048) - 1024 end
        local target_x = x + self.speed_x;
        local target_y = y + self.speed_y;
        temp = set_path(self.id, target_x, target_y)
    until temp
    
    -- Gehe (nach der flucht) in heilung und nahrungssuche ueber.
    enemy, enemy_x, enemy_y, playernum, dist = nearest_enemy(self.id)
    if(dist > 500) then self.behaviour = BEH_NONE end
    
end

-- Upgrade or fork
function Creature:multiply()
    if get_state(self.id) == CREATURE_IDLE and get_type(self.id) == 0 then
        -- Upgraden
        if(set_convert(self.id, 1) and set_state(self.id,CREATURE_CONVERT)) then
            print("Converting...")
        else
            print("Unable to convert")
            self.behaviour = BEH_NONE
        end
    elseif get_state(self.id) == CREATURE_IDLE then
        -- Forken
        print("Forking...")
        if not set_state(self.id, CREATURE_SPAWN) then
            print("ARGH")
        end
    elseif get_state(self.id) == CREATURE_SPAWN then
        -- Nix, warten.
        print("warting")
    end
    self.behaviour = BEH_NONE
end

-- Entscheide, was als naechstes zu tun ist.
function Creature:decide_what_to_do()
    -- Heile, wenn nicht voll und genug health
    if(get_health(self.id) < MIN_HEALTH and get_food(self.id) > 0) then
        print("Creature " .. self.id .. " is now healing itself")
        set_message(self.id, "Mal heilen.")
        self.behaviour = BEH_HEAL
    elseif get_food(self.id) < MIN_FOOD then
        print("Creature " .. self.id .. " is now feeding")
        set_message(self.id, "Hunger!")
        self.behaviour = BEH_FEED
    else 
        print("Creature " .. self.id .. " is now Multiplying")
        self.behaviour = BEH_FORK
    end
end

function Creature:heal()
    set_state(self.id, CREATURE_HEAL)
    self.behaviour = BEH_NONE
end

function Creature:attack()
    enemy, enemy_x, enemy_y, playernum, dist = nearest_enemy(self.id)
    if get_type(self.id) == 0 or self:health() < ATK_HEALTH then
        print("Creature " .. self.id .. " is now Fleeing")
        self.behaviour = BEH_FLEE
        self:flee(enemy_x, enemy_y)
        return
    else
        if (dist < ATK_DIST) then
            print("Creature " .. self.id .. " attacking!")
            set_target(self.id, enemy)
            set_state(self.id, CREATURE_ATTACK)
        else
            self.behaviour = BEH_NONE
        end
    end
end

function get_nearest_known_food (x,y)
    x = math.floor(x/256)
    y = math.floor(y/256)
    if known_food_x[x] ~= nil and known_food_x[x][y] ~=nil and known_food_y[x] ~=nil and known_food_y[x][y] ~=nil then
        return known_food_x[x][y], known_food_y[x][y]
    else
        return nil,nil
    end
end

function set_nearest_known_food(x,y,tox, toy)
    x = math.floor(x/256)
    y = math.floor(y/256)
    if known_food_x[x] == nil then
        known_food_x[x] = {}
    end
    if known_food_y[x] == nil then
        known_food_y[x] = {}
    end
    known_food_x[x][y] = tox
    known_food_y[x][y] = toy
end

function clear_food()
    known_food_x = {}
    known_food_y = {}
end

function Creature:main()
    -- Hole koordinaten und zustand
    x,y = get_pos(self.id)
    local state = get_state(self.id)

    -- Lege eigene message fest
    self.message = "(" .. self:type() .. ") at " .. x .. " : " .. y .. ", state: " .. state .. ", behaviour: " .. self.behaviour .. ", food: " .. self:food() .. ", health: " .. self:health()
    
    -- Update foo-d-path
    local foodx, foody = get_nearest_known_food(x,y)
    -- Undzwar nur, wenn noch kein foodx definiert ist, *und* nicht naeher als 2 Kloetzchen
    -- *und* das aktuelle besser ist, 
    if self.last_seen_food_x ~= nil and (self.last_seen_food_x-x)^2 + (self.last_seen_food_y-y)^2 > 512^2 then
        -- and ( foodx == nil or (foodx-x)^2 + (foody-y)^2 > (self.last_seen_food_x-x)^2 + (self.last_seen_food_y-y)^2 ) and (self.last_seen_food_x-x)^2 + (self.last_seen_food_y-y)^2 > 512^2 then
        -- print("Creature " .. self.id .. " marking food");
        set_nearest_known_food(x,y,self.last_seen_food_x,self.last_seen_food_y)
        foodx = self.last_seen_food_x
        foody = self.last_seen_food_y
    end
    -- Schaue, ob auf dem Aktuellen Feld Essi liegt - wenn ja, merke dir das.
    if get_tile_food(self.id) > 0 then
        -- print("Creature " .. self.id .. " found food at (" .. x .. ":" .. y .. ")")
        self.last_seen_food_x = x
        self.last_seen_food_y = y
    end
    
    -- Floating-Position-Mean updaten
    self.floating_x = (self.floating_x * MEAN_STEPS + x)/(MEAN_STEPS+1)
    self.floating_y = (self.floating_y * MEAN_STEPS + y)/(MEAN_STEPS+1)
    
    if self.behaviour == BEH_NONE then
        -- Warte, bis du fertig bist, dann entscheide, was es zu tun gibt.
        if(state == CREATURE_IDLE) then
            set_message(self.id,"?")
            self:decide_what_to_do()
        end
    end
    if self.behaviour == BEH_ATTACK then
        set_message(self.id, "GRR!")
        self:attack()
    elseif self.behaviour == BEH_FEED then
        self:forage()
    elseif self.behaviour == BEH_HEAL then
        self:heal()
    elseif self.behaviour == BEH_FLEE then
        set_message(self.id, "Argh!")
        self:flee()
    elseif self.behaviour == BEH_FORK then
        set_message(self.id, "0_o")
        self:multiply()
    end
end

