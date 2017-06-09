function update(dt)
	if matchingEasel == nil then
		matchingEaselList = world.objectQuery({object.position()[1]-4,object.position()[2]},1)
		for i,j in ipairs(matchingEaselList) do
			if world.entityName(j) == "signstore" then matchingEasel = j end
		end
	end
end

function die()
	if matchingEasel ~= nil then world.breakObject(matchingEasel) end
end
