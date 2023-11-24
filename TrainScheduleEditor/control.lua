require 'rivenmods-common-v0-1-1'

function findElementInArray( arrayValues, toFind )
	for idx, val in ipairs(arrayValues) do
		if val == toFind then
			return idx
		end
	end
	
	return nil
end

function isElementChildOf( elem, root )
	while true do
		if elem == nil then
			return false
		end
		
		if elem == root then
			return true
		end
		
		elem = elem.parent
	end
end


function destroyChildren( container )
	for _, child in ipairs(container.children) do
		child.destroy()
	end
end

function getChildByName( container, childName, recursive )
	for _, child in ipairs(container.children) do
		if child.name == childName then
			return child
		end
		
		if recursive and #child.children > 0 then
			local got = getChildByName(child, childName, true)
			if got ~= nil then
				return got
			end
		end
	end
	
	return nil
end






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

function findPlayerTrainStopNames(player)
	local found = player.surface.find_entities_filtered{
		type="train-stop",
		force=player.force,
		to_be_deconstructed=false
	}
	
	local name2exists = {}
	for _, entity in ipairs(found) do
		name2exists[entity.backer_name] = 1
	end
	
	local result = {}
	for name, dummy in pairs(name2exists) do
		table.insert(result, name)
	end
	table.sort(result)
	return result
end

function changeTrainScheduleSlotStationName(train, stationIndex, newStationName)
	if train == nil or train.schedule == nil then
		return
	end
	
	local newSchedule = deepcopy(train.schedule)
	newSchedule.records[stationIndex].station = newStationName
	train.schedule = newSchedule
end



function getPlayerByIdx(idx)
	return game.get_player(idx)
end

function getPlayerUI(player)
	ensurePlayer2UI()
	
	if global.player2ui[player.index] == nil then
		buildGUI(player)
	end
	
	return global.player2ui[player.index]
end




function destroyGUIs()
	ensurePlayer2UI()
	
	for _, player in pairs(game.players) do	
		local idx = player.index
		if global.player2ui[idx] ~= nil and global.player2ui[idx].root ~= nil then
			global.player2ui[idx].root.destroy()
		end
		
		global.player2ui[idx] = nil
		
		
		
		if player.gui.top then
			for _, child in ipairs(player.gui.top.children) do
				child.destroy()
			end	
		end
	end
end


function findPlayerTrainIds(player)
	local trainIds = {}	
	for _, train in pairs(player.surface.get_trains()) do
		if train.valid then
			table.insert(trainIds, train.id)
		end
	end
	return trainIds
end




function ensurePlayer2UI() {
	if global.player2ui == nil then
		global.player2ui = {}
	end
}


function ensureGUIs()	
	ensurePlayer2UI()
	for _, player in pairs(game.players) do
		if global.player2ui[player.index] == nil then
			buildGUI(player)
		end
	end
end



function buildGUI(player)
	ensurePlayer2UI()

	local playerIdx = player.index
	if global.player2ui[playerIdx] ~= nil and global.player2ui[playerIdx].root ~= nil then
		global.player2ui[playerIdx].root.destroy()
		global.player2ui[playerIdx] = nil
	end
	
	local root = player.gui.top.add{
		type="frame",
		name="root",
		direction='vertical'
	}
	

	
	local resetButton = root.add{type="button", name="ui-reset", caption="RESET"}
	resetButton.visible = false
	
	
	local trainInfoPane = root.add{
		type="flow",
		name="train-info",
		direction="horizontal"
	}
	trainInfoPane.add{type="sprite-button", name="modify-schedule", sprite="item/locomotive"}
	trainInfoPane.add{type="sprite", name="train-id",        sprite="item/repair-pack"}
	
	
	local trainSchedulePane = root.add{
		type="frame",
		name="schedule-pane",
		direction="vertical"
	}
	local trainScheduleHeader = trainSchedulePane.add{
		type="label",
		name="schedule-header",
		caption="Train schedule:"
	}
	local trainScheduleTable = trainSchedulePane.add{
		type="table",
		name="schedule-table",
		column_count=2
	}
	local editOptionsPane = trainSchedulePane.add{
		type="flow",
		name="edit-options",
		direction="horizontal"
	}
	editOptionsPane.add{type="button", name="edit-fine",   caption="Looks fine"}
	editOptionsPane.add{type="button", name="edit-cancel", caption="Cancel"}
	editOptionsPane.add{type="button", name="edit-apply",  caption="Apply"}
	
	global.player2ui[playerIdx] = {
		root=root,
		status='monitoring',
		train=nil,
		killAt=nil
	}
	
	model_to_view_visibility(player)
end




function on_gui_click(e)
	local player = game.get_player(e.player_index)
	local ui = getPlayerUI(player)
	if ui == nil bthen
		return
	end
	
	if ui.root == nil or not isElementChildOf(e.element, ui.root) then
		return
	end

	if e.element.name == 'ui-reset' then
		destroyGUIs()
		ensureGUIs()
	elseif e.element.name == 'modify-schedule' then
		if ui.status == 'modify-train' then
			ui.status = 'suggest-train'
			ui.killAt = global.last_tick + 60 * 3
		else
			ui.status = 'modify-train'
		end
		model_to_view_full(player)
	elseif e.element.name == 'edit-fine'
	    or e.element.name == 'edit-cancel'
	  then
		ui.status = 'monitoring'
		ui.train = nil
		model_to_view_full(player)
	elseif e.element.name == 'edit-apply' then
		on_gui_apply_train(player)			
		ui.status = 'monitoring'
		ui.train = nil
		model_to_view_full(player)
	end
end


function on_gui_opened(e)
	local entity = e.entity
	local player = getPlayerByIdx(e.player_index)
	local ui = getPlayerUI(player)
	if ui == nil bthen
		return
	end
		
	if entity ~= nil and entity ~= nil and entity.train ~= nil and entity.type == 'locomotive' then
		ui.status = 'suggest-train'
		ui.train = entity.train
		ui.killAt = nil
		model_to_view_full(player)
	else
		ui.status = 'monitoring'
		ui.train = nil
		model_to_view_full(player)
	end
end

function on_gui_closed(e)
	local entity = e.entity
	local player = getPlayerByIdx(e.player_index)
	local ui = getPlayerUI(player)
	if ui == nil bthen
		return
	end
	
	if entity ~= nil and entity ~= nil and entity.train ~= nil then
		if ui.status == 'suggest-train' then
			-- ui.killAt = global.last_tick + 60 * 3
			ui.status = 'monitoring'
			ui.train = nil
			model_to_view_full(player)
		end
	end
end

function on_tick_kill_ui(e)
	global.last_tick = e.tick
	ensurePlayer2UI()
	
	for playerIdx, ui in pairs(global.player2ui) do
		if ui.train ~= nil and ui.status == 'suggest-train' then
			if ui.killAt ~= nil and ui.killAt <= e.tick then
				ui.status = 'monitoring'
				ui.train = nil
				model_to_view_full(getPlayerByIdx(playerIdx))
			end
		end
	end
end

function on_gui_selection_state_changed(e)
	local player = game.get_player(e.player_index)
	local ui = getPlayerUI(player)
	if ui.root == nil or not isElementChildOf(e.element, ui.root) then
		return
	end
	
	if ui.status == 'modify-train' and e.element.parent.name == 'schedule-table' then
		ui.status = 'modified-train'
		model_to_view_visibility(player)
	end
end




function on_gui_apply_train( player )
	local ui = getPlayerUI(player)
	local tab = getChildByName(ui.root, 'schedule-table', true)
	
	local stationIndex = 1
	while true do
		local dropdown = getChildByName(tab, "drop-slot-" .. stationIndex)
		if dropdown == nil then
			break
		end
		
		local newStationName = dropdown.items[dropdown.selected_index]
		changeTrainScheduleSlotStationName(ui.train, stationIndex, newStationName)
		
		stationIndex = stationIndex + 1
	end
end



function model_to_view_visibility(player)
	local ui = getPlayerUI(player)
	
	local elemTrainInfo = getChildByName(ui.root, 'train-info', true)
	local elemTrainId = getChildByName(ui.root, 'train-id', true)
	local elemSchedulePane = getChildByName(ui.root, 'schedule-pane', true)
	
	local elemEditOptions = getChildByName(ui.root, 'edit-options', true)
	local elemEditFine = getChildByName(ui.root, 'edit-fine', true)
	local elemEditApply = getChildByName(ui.root, 'edit-apply', true)
	local elemEditCancel = getChildByName(ui.root, 'edit-cancel', true)
	
	ui.root.visible = (ui.train ~= nil)
	
	if false then
		if ui.train == nil then
			elemTrainId.caption = ""
		else
			elemTrainId.caption = "Train " .. ui.train.id
		end
	end
	
	if ui.status == 'monitoring' then
		elemTrainInfo.visible = false
		elemSchedulePane.visible = false
		elemEditOptions.visible = false
	elseif ui.status == 'suggest-train' then
		elemTrainInfo.visible = (ui.train ~= nil)
		elemSchedulePane.visible = false
		elemEditOptions.visible = false
	elseif ui.status == 'modify-train'
	    or ui.status == 'modified-train'
	  then
		elemTrainInfo.visible = (ui.train ~= nil)
		elemSchedulePane.visible = true
		elemEditOptions.visible = true
		elemEditFine.visible = (ui.status == 'modify-train')
		elemEditApply.visible = (ui.status == 'modified-train')
		elemEditCancel.visible = (ui.status == 'modified-train')
	end
end



function model_to_view_full(player)
	local ui = getPlayerUI(player)	
		
	model_to_view_visibility(player)
	
	-- clear old table contents
	local elemScheduleTable = getChildByName(ui.root, 'schedule-table', true)
	destroyChildren(elemScheduleTable)
	
	
	if ui.train == nil or ui.train.schedule == nil then
		return
	end
	
	local trainStopNames = findPlayerTrainStopNames(player)
	
-- build new table contents	
	for idx, record in ipairs(ui.train.schedule.records) do
		local trainStopNamesCopy = shallowcopy(trainStopNames)
		local selectedTrainStopIdx = findElementInArray(trainStopNamesCopy, record.station)
		if selectedTrainStopIdx == nil then
			table.insert(trainStopNamesCopy, record.station)
			selectedTrainStopIdx = #trainStopNamesCopy
		end
	
		elemScheduleTable.add{type="label", name="lab-slot-" .. idx, caption="#"..idx.." "}
		elemScheduleTable.add{
			type="drop-down",
			name="drop-slot-" .. idx,
			items=trainStopNamesCopy,
			selected_index=selectedTrainStopIdx
		}
	end
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

script.on_event({defines.events.on_init, defines.events.on_load},
	function (e)
		ensureGUIs(e)
	end
)

script.on_event({defines.events.on_gui_click},
	function (e)
		on_gui_click(e)
	end
)

script.on_event({defines.events.on_gui_opened},
	function (e)
		on_gui_opened(e)
	end
)

script.on_event({defines.events.on_gui_closed},
	function (e)
		on_gui_closed(e)
	end
)

script.on_event({defines.events.on_gui_selection_state_changed},
	function (e)
		on_gui_selection_state_changed(e)
	end
)

script.on_event({defines.events.on_tick},
	function (e)
		on_tick_kill_ui(e)
	end
)








