-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

require "__perel__.util.scripts.general"

local mod_data = assert(prototypes.mod_data["splitter-utils"], "ERROR: mod-data for splitter-utils not found!")
local base_splitters = assert(mod_data.data.base_splitters, "ERROR: data.base_splitters for splitter-utils not found!")
local splitter_ids = assert(mod_data.data.splitter_ids, "ERROR: data.splitter_ids for splitter-utils not found!")
local modded_splitters = assert(mod_data.data.modded_splitters, "ERROR: data.modded_splitters for splitter-utils not found!")

local event_filter = {{filter = "type", type = "splitter"}, {filter = "ghost_type", type = "splitter"}}

script.on_configuration_changed(function ()
  for _, player in pairs(game.players) do
    if player.gui.relative["splitter-utils-ui"] then
      player.gui.relative["splitter-utils-ui"].destroy()
    end
  end
end)

-- parse modded_splitters to convert ["0"] into [0]
for i, tabledata in pairs(modded_splitters) do
  for j, name in pairs(tabledata) do
    modded_splitters[i][j + 0] = name
    modded_splitters[i][j] = nil
  end
end

---@param old_entity LuaEntity
---@param player_index uint32
---@param new_id uint32
---@return LuaEntity?
local function replace(old_entity, player_index, new_id)
  -- swap open the new splitter gui if the old splitter gui is opened
  local player = player_index and game.get_player(player_index)
  local opened = player and player.opened == old_entity
  local old_name = old_entity.name == "entity-ghost" and old_entity.ghost_name or old_entity.name

  -- return if entity, id, or base type not found
  if not old_entity or not new_id or not base_splitters[old_name] then return end

  local surface = old_entity.surface
  local parameters = {
    name = old_entity.name == "entity-ghost" and "entity-ghost" or modded_splitters[base_splitters[old_entity.name]][new_id] or base_splitters[old_entity.name],
    ghost_name = old_entity.name == "entity-ghost" and modded_splitters[base_splitters[old_entity.ghost_name]][new_id] or base_splitters[old_entity.name] or nil,
    position = old_entity.position,
    direction = old_entity.direction,
    quality = old_entity.quality,
    force = old_entity.force,
    create_build_effect_smoke = false,
    spawn_decorations = false,
    raise_built = true,
    fast_replace = true,
    spill = false
  }
  local control_behavior = old_entity.get_control_behavior()
  local control_data = control_behavior and {
    set_input_side = control_behavior.set_input_side,
    input_left_condition = control_behavior.input_left_condition,
    input_right_condition = control_behavior.input_right_condition,
    set_output_side = control_behavior.set_output_side,
    output_left_condition = control_behavior.output_left_condition,
    output_right_condition = control_behavior.output_right_condition,
    set_filter = control_behavior.set_filter
  }
  local filter = old_entity.splitter_filter
  local input_priority = old_entity.splitter_input_priority
  local output_priority = old_entity.splitter_output_priority
  local red_connections = {}
  local green_connections = {}

  local stack = player and player.undo_redo_stack
  if stack then
    local item = perel.find_build_item(stack, old_entity)
    if item then
      parameters.player = player.index
      parameters.undo_index = item
    end
  end

  -- for _, connection in pairs((old_entity.get_wire_connector(defines.wire_connector_id.circuit_red) or {}).connections or {}) do
  --   red_connections[#red_connections+1] = connection.target
  -- end

  -- for _, connection in pairs((old_entity.get_wire_connector(defines.wire_connector_id.circuit_green) or {}).connections or {}) do
  --   green_connections[#green_connections+1] = connection.target
  -- end

  local new_entity = surface.create_entity(parameters)
  if not new_entity then return end

  -- copy circuit connections
  -- if #red_connections ~= 0 then
  --   for _, target in pairs(red_connections) do
  --     new_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(target)
  --   end
  -- end
  -- if #green_connections ~= 0 then
  --   for _, target in pairs(green_connections) do
  --     new_entity.get_wire_connector(defines.wire_connector_id.circuit_green, true).connect_to(target)
  --   end
  -- end

  -- update stack size if appliccable
  -- if stacking and new_entity.prototype.splitter_adjustable_belt_stack_size then
  --   new_entity.splitter_belt_stack_size_override = stacking
  -- end

  -- set filter(s) and circuit controls
  -- if mode then new_entity.splitter_filter_mode = mode end

  -- apply as many filters as possible
  -- for j, filter in pairs(filters) do
  --   if j <= new_entity.filter_slot_count then
  --     new_entity.set_filter(j, filter)
  --   else
  --     local i = 1
  --     for _, filter in pairs(filters) do
  --       new_entity.set_filter(i, filter)
  --       if i == new_entity.filter_slot_count then break end
  --       i = i + 1
  --     end
  --     break
  --   end
  -- end

  -- if control_data then
  --   local new_control = new_entity.get_or_create_control_behavior()

  --   new_control.circuit_set_filters = control_data.set_filters
  --   new_control.circuit_read_transfers = control_data.read_transfers
  --   new_control.circuit_enable_disable = control_data.enable
  --   new_control.circuit_condition = control_data.circuit_condition
  --   new_control.connect_to_logistic_network = control_data.connect_to_logistic_network
  --   new_control.logistic_condition = control_data.logistic_condition
  -- end

  -- remove 'remove old entity' action
  if stack and parameters.undo_index then
    for a, action in pairs(stack.get_undo_item(parameters.undo_index)) do
      if action.type == "removed-entity" and
        action.surface_index == new_entity.surface_index and
        action.target.name == old_name and
        action.target.position.x == new_entity.position.x and
        action.target.position.y == new_entity.position.y then
        stack.remove_undo_action(parameters.undo_index, a)
      end
    end
  end

  if opened then
    player.opened = new_entity
  end

  return new_entity
end

-- copy paste settings, but change the mode if they are different
---@param event EventData.on_entity_settings_pasted
script.on_event(defines.events.on_entity_settings_pasted, function (event)

  local source_id = splitter_ids[event.source.name == "entity-ghost" and event.source.ghost_name or event.source.name]
  local destination_id = splitter_ids[event.destination.name == "entity-ghost" and event.destination.ghost_name or event.destination.name]

  if not source_id or not destination_id then return end

  -- make sure both are valid entities
  if source_id ~= destination_id then
    -- two different styles, need to swap the destination to match the source
    local entity = event.destination
    local player = game.get_player(event.player_index)
    local item = entity.type ~= "entity-ghost" and {name = entity.prototype.mineable_properties.products[1].name, quality = entity.quality}
    local amount = item and player.get_main_inventory() and player.get_main_inventory().get_item_count(item)
    replace(entity, event.player_index, source_id)
    if item and player.controller_type ~= defines.controllers.remote then
      item.count = amount + 1
      player.get_main_inventory().remove(item)
      if amount > 0 then
        item.count = amount
        player.get_main_inventory().insert(item)
      end
    end
  end

  game.get_player(event.player_index).play_sound{path = "utility/entity_settings_pasted"}
end)

local bitmask = {
  eil = 0,
  eol = 1,
}

-- update gui events
---@param event EventData.on_gui_checked_state_changed
script.on_event(defines.events.on_gui_checked_state_changed, function (event)
  if event.element.get_mod() ~= "splitter-utils" then return end
  local player = game.get_player(event.player_index)
  local entity = player.opened
  if entity.name == "entity-ghost" and base_splitters[entity.ghost_name] then
    local tags = entity.tags or {}
    tags["splitter-utils"] = (tags["splitter-utils"] or 0) + (event.element.state and 1 or -1) * 2 ^ bitmask[event.element.name]
    entity.tags = tags
  elseif base_splitters[entity.name] then
    local item = {name = entity.prototype.mineable_properties.products[1].name, quality = entity.quality}
    local amount = player.get_main_inventory() and player.get_main_inventory().get_item_count(item)
    replace(entity, event.player_index, splitter_ids[entity.name] + (event.element.state and 1 or -1) * 2 ^ bitmask[event.element.name])
    if player.controller_type ~= defines.controllers.remote then
      item.count = amount + 1
      player.get_main_inventory().remove(item)
      if amount > 0 then
        item.count = amount
        player.get_main_inventory().insert(item)
      end
    end
  end
end)

local just_destroyed = {}
local masking = {
  [defines.events.on_player_mined_entity] = defines.events.on_built_entity,
  [defines.events.on_robot_mined_entity] = defines.events.on_robot_built_entity,
  [defines.events.on_space_platform_mined_entity] = defines.events.on_space_platform_built_entity,
  [defines.events.script_raised_destroy] = defines.events.script_raised_built,
  [defines.events.on_entity_died] = defines.events.script_raised_revive,
}
local snap_targets = {
  "container",
  "logistic-container",
  "linked-container",
  "infinity-container",
  "assembling-machine",
  "furnace",
  "rocket-silo",
  "mining-drill",
  "lab",
  "boiler",
  "reactor",
  "fusion-reactor",
  "ammo-turret",
  "artillery-turret",
  "straight-rail",
  "agricultural-tower",
  "asteroid-collector",
}

--- @param event EventData.on_built_entity|EventData.on_robot_built_entity|EventData.on_space_platform_built_entity|EventData.script_raised_built|EventData.script_raised_revive
local function on_built(event)
  -- if player has setting enabled, then replace with custom
  local player = event.player_index and game.get_player(event.player_index)
  local entity = event.entity
  local id = event.tags and event.tags["splitter-utils"] or
    just_destroyed.tick == event.tick and masking[just_destroyed.event] == event.name and just_destroyed.id or player and (
    (player.mod_settings["su-eil-default"].value and 1 or 0) +
    (player.mod_settings["su-eol-default"].value and 2 or 0) or nil)
  just_destroyed = {}
  if id and id ~= 0 and entity.name ~= "entity-ghost" then
    local item = {
      name = entity.prototype.mineable_properties.products[1].name,
      quality = entity.quality
    }
    entity = replace(entity, event.player_index, id)
    if player and player.controller_type ~= defines.controllers.remote then
      if player.cursor_stack and player.cursor_stack.valid_for_read then
        player.cursor_stack.count = player.cursor_stack.count - 1
      elseif player.is_cursor_empty() then
        -- just placed last item, remove from inventory
        player.get_main_inventory().remove(item)
      end
    end
  elseif id and entity.name == "entity-ghost" then
    local tags = entity.tags or {}
    tags["splitter-utils"] = tags["splitter-utils"] or id
    entity.tags = tags
  end
end

script.on_event(defines.events.on_built_entity, on_built, event_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, event_filter)
script.on_event(defines.events.on_space_platform_built_entity, on_built, event_filter)
script.on_event(defines.events.script_raised_built, on_built, event_filter)
script.on_event(defines.events.script_raised_revive, on_built, event_filter)

--- @param event EventData.on_player_mined_entity|EventData.on_robot_mined_entity|EventData.on_space_platform_mined_entity|EventData.script_raised_destroy|EventData.on_entity_died
local function on_destroyed(event)
  just_destroyed = {
    tick = event.tick,
    event = event.name,
    id = splitter_ids[event.entity.name == "entity-ghost" and event.entity.ghost_name or event.entity.name]
  }
end

script.on_event(defines.events.on_player_mined_entity, on_destroyed, event_filter)
script.on_event(defines.events.on_robot_mined_entity, on_destroyed, event_filter)
script.on_event(defines.events.on_space_platform_mined_entity, on_destroyed, event_filter)
script.on_event(defines.events.script_raised_destroy, on_destroyed, event_filter)
script.on_event(defines.events.on_entity_died, on_destroyed, event_filter)

---@param event EventData.on_gui_opened
script.on_event(defines.events.on_gui_opened, function (event)
  local entity = event.entity
  local type = entity and (entity.type == "entity-ghost" and entity.ghost_type or entity.type)
  local name = entity and (entity.name == "entity-ghost" and entity.ghost_name or entity.name)

  -- if splitter opened, handle it
  if type == "splitter" and splitter_ids[name] then
    local player = game.get_player(event.player_index)
    local id = entity.tags and entity.tags["splitter-utils"] or splitter_ids[name]
    if not id then return end
    local gui = player.gui.relative["splitter-utils-ui"]

    if not gui then
      -- create gui
      gui = player.gui.relative.add{
        type = "frame",
        name = "splitter-utils-ui",
        caption = { "splitter-utils-ui.frame" },
        direction = "horizontal",
        anchor = {
          gui = defines.relative_gui_type.splitter_gui,
          position = defines.relative_gui_position.right
        }
      }
      gui.add{
        type = "frame",
        name = "sub",
        style = "inside_shallow_frame_with_padding",
        direction = "vertical",
      }
      gui.sub.add{
        type = "checkbox",
        name = "eil",
        style = "caption_checkbox",
        caption = { "splitter-utils-ui.checkbox-eil" },
        state = false
      }
      gui.sub.add{
        type = "checkbox",
        name = "eol",
        style = "caption_checkbox",
        caption = { "splitter-utils-ui.checkbox-eol" },
        state = false
      }
    end

    -- update GUI
    gui.sub.eil.state = bit32.band(id, 1) ~= 0
    gui.sub.eol.state = bit32.band(id, 2) ~= 0
  end
end)

---@param event EventData.on_player_setup_blueprint
script.on_event(defines.events.on_player_setup_blueprint, function (event)
	local player = game.get_player(event.player_index)
	local blueprint = player.blueprint_to_setup
  -- if normally invalid
	if not blueprint or not blueprint.valid_for_read then blueprint = player.cursor_stack end
  -- if non existant, cancel
  local entities = blueprint and blueprint.get_blueprint_entities()
  if not entities then return end
  local changed = false
  -- update entities
  for _, entity in pairs(entities) do
    if base_splitters[entity.name] then
      changed = true
      local tags = entity.tags or {}
      tags["splitter-utils"] = tags["splitter-utils"] or splitter_ids[entity.name]
      entity.tags = tags
      entity.name = base_splitters[entity.name] or entity.name
    end
  end
  if not changed then return end -- make no changes unless required
  blueprint.set_blueprint_entities(entities)
end)