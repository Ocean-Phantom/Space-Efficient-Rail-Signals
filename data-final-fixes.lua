local cmu = require("collision-mask-util")
local colliding_signal_layers = {} --set of rail signal layers that collide with rail-segments

local function Set(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

local function Set_Insert(set, insert)
  if not set[insert] then
    set[insert] = true
  end
end

local function Set_Remove(set, remove)
  if set[remove] then
    set[remove] = nil
  end
end

--get all rail signal and chain signal collision masks and place them in a set variable
local function get_all_collisions()
  for _, signal in pairs(data.raw["rail-signal"]) do
    signal.collision_mask = cmu.get_mask(signal)
    for _, rail in pairs(data.raw["straight-rail"]) do
      for _, signal_layer in pairs (signal.collision_mask) do
        if cmu.mask_contains_layer(cmu.get_mask(rail), signal_layer) then
          Set_Insert(colliding_signal_layers, signal_layer)
        end
      end
    end
  end

  for _, signal in pairs(data.raw["rail-chain-signal"]) do
    signal.collision_mask = cmu.get_mask(signal)
    for _, rail in pairs(data.raw["straight-rail"]) do
      for _, signal_layer in pairs (signal.collision_mask) do
        if cmu.mask_contains_layer(cmu.get_mask(rail), signal.collision_mask) then
          table.insert(colliding_signal_layers, signal_layer)
        end
      end
    end
  end
end


local function edit_non_rail_segment()
  local prototypes_to_add = {}
  for old_layer, new_layer in pairs(colliding_signal_layers) do
    new_layer = cmu.get_first_unused_layer()

    local prototypes = cmu.collect_prototypes_with_layer(old_layer)
    for _, prototype in pairs(prototypes) do
      local prototype_mask = cmu.get_mask(prototype)
      prototype.collision_mask = prototype_mask
      if prototype.type ~= "straight-rail" and prototype.type ~= "curved-rail" then
        if cmu.mask_contains_layer(prototype_mask, old_layer) then
          cmu.add_layer(prototype_mask, new_layer)
          log("Adding "..tostring(new_layer).." collision mask for "..tostring(prototype.name))
          if prototype.type == "rail-signal" or prototype.type == "rail-chain-signal" then
            cmu.remove_layer(prototype_mask, old_layer)
            log("Removing "..tostring(old_layer).." collision mask for "..tostring(prototype.name))
          end
        end
      end
    end
  end
end

get_all_collisions()
log("Non Colliding Rail Signals: layers to replace:" ..serpent.block(colliding_signal_layers))
edit_non_rail_segment()
