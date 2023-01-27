local cmu = require("collision-mask-util")
local ensure_rail_signal_collision = cmu.get_first_unused_layer()
--local new_layer=cmu.get_first_unused_layer()

local function set_signal_collision_mask(signal)
  --signal.collision_mask = {layer}
  for _, rail in pairs(data.raw["straight-rail"]) do
    local rail_masks = cmu.get_mask(rail)
    --while there is chance of collision, remove every collision mask in each signal that matches a rail
    while cmu.masks_collide(rail_masks, signal.collision_mask) do
      for _, signal_layer in pairs (signal.collision_mask) do
        for _, rail_layer in pairs (rail_masks) do
          if signal_layer == rail_layer then
            cmu.remove_layer(signal.collision_mask, rail_layer)
          end
        end
      end
    end
  end
--  if not next(signal.collision_mask) then
 --   cmu.add_layer(signal.collision_mask, new_layer)
 -- end
end

local function set_all_signal_collision_masks()
  for _, signal in pairs(data.raw["rail-signal"]) do
    signal.collision_mask = cmu.get_mask(signal)
    cmu.add_layer(signal.collision_mask, ensure_rail_signal_collision)
    set_signal_collision_mask(signal)
  end
  for _, signal in pairs(data.raw["rail-chain-signal"]) do
    signal.collision_mask = cmu.get_mask(signal)
    cmu.add_layer(signal.collision_mask, ensure_rail_signal_collision)
    set_signal_collision_mask(signal)
  end
end

set_all_signal_collision_masks()