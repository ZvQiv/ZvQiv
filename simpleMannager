local ConnectionManager = {}

ConnectionManager.__index = ConnectionManager

function ConnectionManager.new()
	return setmetatable({connections = {}}, ConnectionManager)
end

function ConnectionManager:Connect(signal, callback)
	local new_connection = signal:Connect(callback)

	table.insert(self.connections, new_connection)

	return new_connection
end

function ConnectionManager:Disconnect(conn)
	for i, c in ipairs(self.connections) do
		if c == conn then
			c:Disconnect()
			
			table.remove(self.connections, i)
			
			break
		end
	end
end

function ConnectionManager:DisconnectAll()
	for i, c in ipairs(self.connections) do
		c:Disconnect()

		self.connections[i] = nil
	end
end

return ConnectionManager
