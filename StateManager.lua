local StateManager = class( "StateManager" )

function StateManager:init( states, initial_state, initial_state_table )
	self.states = states
	if not self.states[initial_state] then
		error("unknown state "..initial_state)
	end
	self.state = self.states[initial_state]:new( self, initial_state_table )
	if self.state.enter then
		self.state:enter()
	end
end

function StateManager:switch_to( new_state, new_state_table )
	if self.state.exit then
		self.state:exit()
	end
	self.state = self.states[new_state]:new( self, new_state_table )
	if self.state.enter then
		self.state:enter()
	end
end

return StateManager
