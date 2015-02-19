remove_unknown = {}

minetest.register_privilege("rm")

minetest.register_chatcommand("rm", {
	params = "<radius>",
	description = "Remove unknown nodes in ",
	privs = {rm = true},
	func = function(name,param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		local radius = tonumber(param)
		local pos1 = {}
		local pos2 = {}

		if radius and radius > 0 then
			local playerpos = vector.round(player:getpos())
			pos1 = vector.subtract(playerpos,radius) -- low left
			pos2 = vector.add(playerpos,radius) -- top right
		elseif worldedit.pos1[name] and worldedit.pos2[name] then
			pos1 = worldedit.pos1[name]
			pos2 = worldedit.pos2[name]
			pos1, pos2 = worldedit.sort_pos(pos1, pos2)
		else
			minetest.chat_send_player(name,"Missing or invalid pos1/pos2/radius !")
			return false
		end
		local count = remove_unknown.rm(pos1,pos2)
		minetest.chat_send_player(name, count.." node(s) removed !")
		return true
	end,
})

remove_unknown.rm = function(pos1,pos2)
	
	local count = 0

	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1,pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})
	local nodes = manip:get_data()
	for i in area:iterp(pos1,pos2) do
		local cur_node = minetest.get_name_from_content_id(nodes[i])
		if not minetest.registered_nodes[cur_node] then
			nodes[i] = minetest.get_content_id("air") -- replace unknown with air
			count = count + 1
		end
	end

	-- write changes to map
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()
	
	return count
end
