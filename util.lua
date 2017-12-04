local util = {}

function util.moveposition(position, offset)
	return {x=position.x + offset.x, y=position.y + offset.y}
end

function util.offset(direction, longitudinal, orthogonal)
	if direction == defines.direction.north then
		return {x=orthogonal, y=-longitudinal}
	end

	if direction == defines.direction.south then
		return {x=-orthogonal, y=longitudinal}
	end

	if direction == defines.direction.east then
		return {x=longitudinal, y=orthogonal}
	end

	if direction == defines.direction.west then
		return {x=-longitudinal, y=-orthogonal}
	end
end

function util.opposite_direction(direction)
	if direction >= 4 then
		return direction - 4
	end
	return direction + 4
end

function util.orthogonal_direction(direction)
	if direction == defines.direction.west then
		return defines.direction.north
	end
	return direction + 2
end

function util.is_miniloader(entity)
	return string.find(entity.name, "-miniloader$") ~= nil
end

function util.pickup_position(entity)
	if entity.belt_to_ground_type == "output" then
		return util.moveposition(entity.position, util.offset(util.opposite_direction(entity.direction), 0.75, 0))
	end
	return util.moveposition(entity.position, util.offset(entity.direction, 0.25, 0))
end

function util.drop_positions(entity)
	if entity.belt_to_ground_type == "output" then
		local chest_dir = util.opposite_direction(entity.direction)
		local p1 = util.moveposition(entity.position, util.offset(chest_dir, -0.25, 0.25))
		local p2 = util.moveposition(p1, util.offset(chest_dir, 0, -0.5))
		return {p1, p2}
	end
	local chest_dir = entity.direction
	local p1 = util.moveposition(entity.position, util.offset(chest_dir, 0.75, 0.25))
	local p2 = util.moveposition(p1, util.offset(chest_dir, 0, -0.5))
	return {p1, p2}
end

function util.get_loader_inserters(entity)
	if entity == nil then
		error("got nil entity")
	end
	return entity.surface.find_entities_filtered{
		position = entity.position,
		name = entity.name .. "-inserter"
	}
end

function util.update_miniloader(entity, direction, type)
	if entity.belt_to_ground_type ~= type then
		-- need to destroy and recreate since belt_to_ground_type is read-only
		local surface = entity.surface
		local name = entity.name
		local position = entity.position
		local force = entity.force
		entity.destroy()
		entity = surface.create_entity{
			name = name,
			position = position,
			direction = direction,
			type = type,
			force = force,
		}
	else
		entity.direction = direction
	end
	util.update_inserters(entity)
end

function util.update_inserters(entity)
	local inserters = util.get_loader_inserters(entity)
	local pickup = util.pickup_position(entity)
	local drop = util.drop_positions(entity)

	local n = #inserters
	for i = 1, n / 2 do
		inserters[i].pickup_position = pickup
		inserters[i].drop_position = drop[1]
		inserters[i].direction = inserters[i].direction
	end
	for i = n / 2 + 1, n do
		inserters[i].pickup_position = pickup
		inserters[i].drop_position = drop[2]
		inserters[i].direction = inserters[i].direction
	end
end

function util.num_inserters(entity)
	local speed = entity.prototype.belt_speed
	if speed < 0.1 then return 2
	else return 6 end
end

return util