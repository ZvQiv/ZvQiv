local PlaceGuiWrapper = { }

PlaceGuiWrapper.__index = PlaceGuiWrapper

function PlaceGuiWrapper.new()
	return setmetatable({}, PlaceGuiWrapper)
end

function PlaceGuiWrapper:ForPlaces(placeIds, func)
	local currentPlace = game.PlaceId
	local allowed = false

	if type(placeIds) == "number" then
		placeIds = {placeIds}
	end

	for _, pid in ipairs(placeIds) do
		if pid == currentPlace then
			allowed = true
			break
		end
	end

	if allowed then
		return func()
	end
end

return PlaceGuiWrapper
