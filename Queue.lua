local Queue = class( "Queue" )

function Queue:init( )
	self:clear( )
end

function Queue:enqueue( x )
	self[self.entrance] = x
	self.entrance = self.entrance + 1
end

function Queue:dequeue( )
	local x
	if self.progress == self.entrance then
		-- queue is empty
	elseif self.progress <= self.entrance - 2 then
		-- not last entry
		x = self[self.progress]
		self.progress = self.progress + 1
	else
		-- last entry
		x = self[self.progress]
		self:clear()
	end

	return x
end

function Queue:clear( )
	self.progress = 1
	self.entrance = 1
end

function Queue:is_empty( )
	return self.progress == self.entrance
end

return Queue
