-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

local base_splitters, splitter_ids, modded_splitters = {}, {}, {}

local blacklist = {}

---@param old_prototype data.SplitterPrototype
---@param id string
---@return data.SplitterPrototype
local function make_copy(old_prototype, id)
  local new_prototype = table.deepcopy(old_prototype)
  new_prototype.name = id .. "-" .. old_prototype.name
  new_prototype.localised_name = old_prototype.localised_name or { "entity-name." .. old_prototype.name }
  new_prototype.localised_description = old_prototype.localised_description or { "entity-description." .. old_prototype.name }
  new_prototype.hidden = not settings.startup["su-show-all-splitters"].value
  new_prototype.factoriopedia_alternative = old_prototype.factoriopedia_alternative or old_prototype.name
  new_prototype.hidden_in_factoriopedia = true
  data.raw.splitter[new_prototype.name] = new_prototype
  return new_prototype
end

-- mark existing splitters as base splitters
for _, prototype in pairs(data.raw.splitter) do
  if not blacklist[prototype.name] and not prototype.ignore_by_splitter_utils then
    base_splitters[prototype.name] = prototype.name
    modded_splitters[prototype.name] = {[0] = prototype.name}
    splitter_ids[prototype.name] = 0
    prototype.exchange_input_lines = false
    prototype.exchange_output_lines = false
    prototype.placeable_by = prototype.placeable_by or data.raw.item[prototype.name] and {item = prototype.name, count = 1} or nil
    prototype.order = prototype.order or "splitter-[" .. prototype.name .. "]" -- default order parameter
  elseif prototype.ignore_by_splitter_utils then
    blacklist[prototype.name] = true
    prototype.ignore_by_splitter_utils = nil
  end
end

-- find a way to avoid the race condition
for bit, id in pairs {
  [0] = "eil",
  "eol"
} do for _, old_prototype in pairs(table.deepcopy(data.raw.splitter)) do
  if not blacklist[old_prototype.name] then
    local new_prototype = make_copy(old_prototype, id)
    new_prototype.order = data.raw.splitter[base_splitters[old_prototype.name]].order .. "[" .. (splitter_ids[old_prototype.name] + 2^bit) .. "]"

    if id == "eil" then
      new_prototype.exchange_input_lines = true
    elseif id == "eol" then
      new_prototype.exchange_output_lines = true
    end

    -- save the ID and lookup
    splitter_ids[new_prototype.name] = splitter_ids[old_prototype.name] + 2^bit
    base_splitters[new_prototype.name] = base_splitters[old_prototype.name]
    modded_splitters[base_splitters[new_prototype.name]][splitter_ids[new_prototype.name]] = new_prototype.name
    modded_splitters[base_splitters[new_prototype.name]][splitter_ids[new_prototype.name]] = new_prototype.name
  end
end end

for _, prototype in pairs(data.raw.splitter) do
  -- set next_upgrade properly
  if not blacklist[prototype.name] then
    if prototype.next_upgrade then
      prototype.next_upgrade = modded_splitters[prototype.next_upgrade][splitter_ids[prototype.name]]
    end

    -- update icons
    prototype.icons = prototype.icons or {{
      icon = prototype.icon,
      icon_size = prototype.icon_size
    }}
    prototype.icon = nil
    prototype.icon_size = nil
    for i = 1, 2 do
      prototype.icons[#prototype.icons+1] = {
        icon = ("__splitter-utils__/graphics/pips/pip-%s.png"):format(bit32.band(2^(i-1), splitter_ids[prototype.name]) ~= 0 and "green" or "red"),
        icon_size = 32,
        scale = 0.3,
        shift = {-14, i * 6}
      }
    end
  end
end

data:extend{{
  type = "mod-data",
  name = "splitter-utils",
  data = {
    base_splitters = base_splitters,
    splitter_ids = splitter_ids,
    modded_splitters = modded_splitters
  }
}}