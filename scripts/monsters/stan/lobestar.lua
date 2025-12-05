ModernSins.Stan.Lobestar = {}

ModernSins.Stan.Lobestar.ID = Isaac.GetEntityTypeByName("Lobestar")
ModernSins.Stan.Lobestar.Variant = Isaac.GetEntityVariantByName("Lobestar")

ModernSins.Stan.Lobestar.States = {}
ModernSins.Stan.Lobestar.States.APPEAR = 0
ModernSins.Stan.Lobestar.States.IDLE = 1
ModernSins.Stan.Lobestar.States.HOP = 2
ModernSins.Stan.Lobestar.States.SLIDE = 3

ModernSins.Stan.DeathDropInfo = {
    CollectibleChance = 1/4,
    CollectibleType = CollectibleType.COLLECTIBLE_BIG_FAN,
    PickupTypes = {
        { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_GRAB_BAG, 0 }
    }
}

local HOP_INITIAL_COOLDOWN = 30
local HOP_MINIMUM_COOLDOWN = 30
local HOP_MAXIMUM_COOLDOWN = 60

local HOP_DIRECTION_OFFSET_ANGLE_RANGE = 15
local HOP_SPEED = 5

local SLIDE_MINIMUM_DURATION = 30
local SLIDE_MAXIMUM_DURATION = 120
local SLIDE_CREEP_SPAWN_COOLDOWN = 5
local SLIDE_CREEP_DURATION = 30

local function SpawnCreep(npc)
    local creep = Isaac.Spawn
    (
        EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0,
        npc.Position, Vector.Zero, npc
    ):ToEffect()
    --creep.SpriteScale = Vector()
    creep:Update()
    creep:SetTimeout(SLIDE_CREEP_DURATION)
end

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if npc.Variant ~= ModernSins.Stan.Lobestar.Variant then
        return
    end

    local data = npc:GetData()
    local rng = npc:GetDropRNG()
    local sprite = npc:GetSprite()
    local pathfinder = npc:GetPathfinder()
    local playerTarget = npc:GetPlayerTarget()

    if not data.Init then
        sprite:Play("Appear", true)

        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

        data.Init = true
        data.State = ModernSins.Stan.Lobestar.States.APPEAR

        data.HopCooldown = HOP_INITIAL_COOLDOWN
        data.SlideDuration = 0
    end

    if data.State == ModernSins.Stan.Lobestar.States.APPEAR then

        if sprite:IsFinished("Appear") then
            data.State = ModernSins.Stan.Lobestar.States.IDLE
        end

    elseif data.State == ModernSins.Stan.Lobestar.States.IDLE then
        
        npc:MultiplyFriction(0.8)

        data.HopCooldown = data.HopCooldown - 1
        if data.HopCooldown <= 0 then
            data.State = ModernSins.Stan.Lobestar.States.HOP
            sprite:Play("Hop", true)
        end

    elseif data.State == ModernSins.Stan.Lobestar.States.HOP then
        
        if sprite:IsEventTriggered("Jump") then
            local targetDirection = playerTarget.Position - npc.Position
            targetDirection:Normalize()
            targetDirection = targetDirection:Rotated(rng:RandomFloat() * HOP_DIRECTION_OFFSET_ANGLE_RANGE * 2 - HOP_DIRECTION_OFFSET_ANGLE_RANGE)
            npc.Velocity = targetDirection * HOP_SPEED

            data.SlideDuration = rng:RandomInt(SLIDE_MINIMUM_DURATION, SLIDE_MAXIMUM_DURATION)
        end
        if sprite:IsEventTriggered("Land") then
            SpawnCreep(npc)
        end

        if sprite:WasEventTriggered("Land") then
            npc.Velocity = npc.Velocity:Resized(HOP_SPEED)
        elseif sprite:WasEventTriggered("Jump") then
            --no air friction
        else
            npc:MultiplyFriction(0.8)
        end

        if sprite:IsFinished("Hop") then
            data.State = ModernSins.Stan.Lobestar.States.SLIDE
        end

    elseif data.State == ModernSins.Stan.Lobestar.States.SLIDE then

        data.SlideDuration = data.SlideDuration - 1
        if data.SlideDuration == 0 then
            sprite:Play("Slide", true)
        end

        if sprite:WasEventTriggered("StopSlide") then
            npc:MultiplyFriction(0.8)
        else
            npc.Velocity = npc.Velocity:Resized(HOP_SPEED)

            if data.SlideDuration % SLIDE_CREEP_SPAWN_COOLDOWN == 0 then
                SpawnCreep(npc)
            end
        end

        if sprite:IsFinished("Slide") then
            data.State = ModernSins.Stan.Lobestar.States.IDLE
            data.HopCooldown = rng:RandomInt(HOP_MINIMUM_COOLDOWN, HOP_MAXIMUM_COOLDOWN)
        end

    end

end, ModernSins.Stan.Lobestar.ID)

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function (_, npc)
    if npc.Variant ~= ModernSins.Stan.Lobestar.Variant then
        return
    end

    npc:BloodExplode()

    ModernSins:SpawnReward(npc, ModernSins.Stan.DeathDropInfo)
end, ModernSins.Stan.Lobestar.ID)