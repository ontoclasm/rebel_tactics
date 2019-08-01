local StateManager = class( "StateManager" )

function StateManager:init( states, initial_state )
	self.states = states
	if not self.states[initial_state] then
		error("unknown state "..initial_state)
	end
	self.state = self.states[initial_state]:new( self )
	if self.state.enter then
		self.state:enter()
	end
end

function StateManager:switch_to(new_state)
	if self.state.exit then
		self.state:exit()
	end
	self.state = self.states[new_state]:new( self )
	if self.state.enter then
		self.state:enter()
	end
end

return StateManager
