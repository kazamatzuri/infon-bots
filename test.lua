function Creature:main()
	local x,y=get_koth_pos()
	self:set_path(x,y)
	set_state(self.id,CREATURE_WALK)
	while self:get_state()==CREATURE_WALK  do
             self:wait_for_next_round()
        end	
end
