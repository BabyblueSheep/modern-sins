---@class RewardDropInfo
---@field CollectibleChance number The chance to spawn an item instead of pickups
---@field CollectibleType CollectibleType The collectible ID to spawn
---@field CollectibleAchievement? Achievement An achievement the collectible is locked behind
---@field CollectibleFallback? CollectibleType The collectible ID to spawn if CollectibleAchievement isn't unlocked
---@field PickupTypes [integer, integer, integer][] A list of pickups to span
local RewardDropInfo = {}

---Drops rewards from an NPC based on behavior found in Sins.
---@param npc EntityNPC 
---@param info RewardDropInfo
function ModernSins:SpawnReward(npc, info)
    local rng = npc:GetDropRNG()

    if rng:RandomFloat() < info.CollectibleChance then
        local type = EntityType.ENTITY_PICKUP
        local variant = PickupVariant.PICKUP_COLLECTIBLE
        local subtype = info.CollectibleType
        if info.CollectibleAchievement ~= nil and not Isaac.GetPersistentGameData():Unlocked(info.CollectibleAchievement) then
            subtype = info.CollectibleFallback
        end
        
        Isaac.Spawn
        (
            type, variant, subtype,
            npc.Position, Vector.Zero, nil
        )
    else
        for _, pickup in ipairs(info.PickupTypes) do
            local type = pickup[1]
            local variant = pickup[2]
            local subtype = pickup[3]

            Isaac.Spawn
            (
                type, variant, subtype,
                npc.Position, Vector.Zero, nil
            )
        end
    end
end