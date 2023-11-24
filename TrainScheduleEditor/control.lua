require 'rivenmods-common-v0-1-1'



function findTrainById(trainId)
	for _idx1_, surface in pairs(game.surfaces) do
		for _idx2_, train in pairs(surface.get_trains()) do
			if train.valid and train.id == trainId then
				return train
			end
		end
	end
	
	return nil
end

function changeTrainScheduleSlotStationName(train, stationIndex, newStationName)
	local newSchedule = deepcopy(train.schedule)
	newSchedule.records[stationIndex].station = newStationName
	train.schedule = newSchedule
end



remote.add_interface("train-schedule-editor", {
	setTrainScheduleSlotStationName = function(trainId, stationIndex, newStationName)
		if type(trainId) == 'string' then
			trainId = tonumber(trainId)
		end
		
		if type(stationIndex) == 'string' then
			stationIndex = tonumber(stationIndex)
		end
	
		game.print("Scheduling train with ID " .. trainId .. " to go to \"" .. newStationName .. "\" at station index " .. stationIndex .. ".")
	
		local train = findTrainById(trainId)
		if train == nil then
			game.print("Warning: Train with ID " .. trainId .. " not found.")
			return
		end
		
		if train.schedule == nil then
			game.print("Warning: Train with ID " .. trainId .. " does not have a schedule.")
			return			
		end
		
		if train.schedule.records[stationIndex] == nil then
			game.print("Warning: Train with ID " .. trainId .. " does not have slot index " .. stationIndex .. ", keep in mind the index starts at 1, not 0.")
			return			
		end
		
		changeTrainScheduleSlotStationName(train, stationIndex, newStationName)
	end
})





