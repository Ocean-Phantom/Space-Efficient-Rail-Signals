local cmu = require("collision-mask-util")
local colliding_signal_layers = {} --set of rail signal layers that collide with rail-segments
local copy_of_rails = {}

local function Set_Insert(set, insert, value)
  if not set[insert] then
    set[insert] = value or true
  end
end

--copies all straight and curved rails segments. warning! overwrites the other
local function copy_all_rails(old, new)
  for _, rail_type in pairs({"straight-rail", "curved-rail"}) do
    new[rail_type] = table.deepcopy(old[rail_type])
  end
end


local function get_collisions(signal_type, rail_type)
  for _, signal in pairs(data.raw[signal_type]) do
    signal.collision_mask = cmu.get_mask(signal)
    for _, rail in pairs(data.raw[rail_type]) do
      for _, signal_layer in pairs (signal.collision_mask) do
        if cmu.mask_contains_layer(cmu.get_mask(rail), signal_layer) then
          Set_Insert(colliding_signal_layers, signal_layer)
        end
      end
    end
  end
end


--get all rail signal and chain signal collision masks and place them in a set variable
local function get_all_collisions()
  for _, signal_type in pairs({"rail-signal", "rail-chain-signal"}) do
    for _, rail_type in pairs({"straight-rail", "curved-rail"}) do
      get_collisions(signal_type, rail_type)
    end
  end
end

--add new collision masks to everything that isn't a rail
local function edit_non_rail_segment()
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
          -- log("collision masks: "..serpent.block(prototype.collision_mask))
          
          if prototype.type == "rail-signal" or prototype.type == "rail-chain-signal" then
            cmu.remove_layer(prototype_mask, old_layer)
            log("Removing "..tostring(old_layer).." collision mask for "..tostring(prototype.name))
            -- log("name: "..tostring(prototype.name).."\n type: "..tostring(prototype.type))
            -- log("collision masks: "..serpent.block(prototype.collision_mask))
          end
        end
      -- else
      --   if cmu.mask_contains_layer(prototype_mask,new_layer) then
      --     cmu.remove_layer(prototype_mask, new_layer) --in case a mod tries to add this layer for some reason
      --     log("Removing "..tostring(new_layer).." collision mask for "..tostring(prototype.name))
      --   end
      --   log("name: "..tostring(prototype.name).."\n type: "..tostring(prototype.type))
      --   log("collision masks: "..serpent.block(prototype.collision_mask))
      end
    end
  end
end

local function all_rails_collide()
  local t = true
  for _, rail1 in pairs(data.raw["straight-rail"]) do
    for _, rail2 in pairs(data.raw["straight-rail"]) do
      if not cmu.masks_collide(rail1.collision_mask, rail2.collision_mask) then
        log(tostring(rail1.name).."did not collide with "..tostring(rail2.name))
        log("rail 1"..serpent.block(rail1.collision_mask))
        log("rail 2"..serpent.block(rail2.collision_mask))
        t = false
      end
    end
  end
  if t == true then
    log("All rails collide")
  else
    log("Error: Rails are not collidiing. Please report this to the mod author")
  end
end

get_all_collisions()
-- log("Layers to replace:"..serpent.block(colliding_signal_layers))
copy_all_rails(data.raw, copy_of_rails)
edit_non_rail_segment()
copy_all_rails(copy_of_rails, data.raw)
-- all_rails_collide()