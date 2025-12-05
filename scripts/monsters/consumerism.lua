ModernSins.Consumerism = {}

ModernSins.Consumerism.ID = Isaac.GetEntityTypeByName("Consumerism")
ModernSins.Consumerism.Variant = Isaac.GetEntityVariantByName("Consumerism")

ModernSins.Consumerism.States = {}
ModernSins.Consumerism.States.APPEAR = 0
ModernSins.Consumerism.States.MOVING = 1
ModernSins.Consumerism.States.ATTACK_CHARGE = 2
ModernSins.Consumerism.States.CHARGE_STUNNED = 3
ModernSins.Consumerism.States.ATTACK_SWING = 4

ModernSins.Consumerism.DeathDropPickups =
{
    { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0 },
    { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0 },
    { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0 },
    { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, 0 }
}
ModernSins.Consumerism.DeathDropCollectible = CollectibleType.COLLECTIBLE_SACK_OF_PENNIES

local ATTACK_INITIAL_COOLDOWN = 90
local ATTACK_MINIMUM_COOLDOWN = 60
local ATTACK_MAXIMUM_COOLDOWN = 150

local ATTACK_DIRECTIONS = {
    Vector(1, 0),
    Vector(0, 1),
    Vector(-1, 0),
    Vector(0, -1)
}
local ATTACK_SWING_DISTANCE_CHECK = 60

local ATTACK_CHARGE_ANGLE_ACCURACY = 0.99
local ATTACK_CHARGE_SPEED = 8
local ATTACK_CHARGE_BOMB_DROP_FREQUENCY = 10
local ATTACK_CHARGE_STUN_DURATION = 30


---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if npc.Variant ~= ModernSins.Consumerism.Variant then
        return
    end

    local data = npc:GetData()
    local rng = npc:GetDropRNG()
    local playerTarget = npc:GetPlayerTarget()

    if not data.Init then
        npc:GetSprite():SetFrame("WalkDown", 0)
        npc:GetSprite():SetOverlayFrame("HeadDown", 0)

        data.Init = true
        data.State = ModernSins.Consumerism.States.APPEAR

        data.StateFrameCount = 0

        data.AttackChargeCooldown = ATTACK_INITIAL_COOLDOWN
        data.AttackChargeDirection = Vector.Zero
        data.AttackChargePerformedIt = false
    end

    if data.State == ModernSins.Consumerism.States.APPEAR then

        if data.StateFrameCount >= 20 then
            data.State = ModernSins.Consumerism.States.MOVING
        end

    elseif data.State == ModernSins.Consumerism.States.MOVING then

        local pathfinder = npc:GetPathfinder()
        pathfinder:MoveRandomlyAxisAligned(1, false)
        npc:MultiplyFriction(0.7)

        if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
            npc:GetSprite():Play("WalkHori")
            npc:GetSprite():PlayOverlay("HeadRight")
            npc.FlipX = npc.Velocity.X < 0
        elseif npc.Velocity.Y > 0 then
            npc:GetSprite():Play("WalkDown")
            npc:GetSprite():PlayOverlay("HeadDown")
        else
            npc:GetSprite():Play("WalkUp")
            npc:GetSprite():PlayOverlay("HeadUp")
        end

        if data.AttackChargeCooldown > 0 then
            data.AttackChargeCooldown = data.AttackChargeCooldown - 1
        end

        if data.AttackChargeCooldown <= 0 then
            local targetDistance = playerTarget.Position - npc.Position
            local targetLength = targetDistance:Length()
            targetDistance:Normalize()

            for i, direction in ipairs(ATTACK_DIRECTIONS) do
                if targetDistance:Dot(direction) > ATTACK_CHARGE_ANGLE_ACCURACY then

                    if targetLength < ATTACK_SWING_DISTANCE_CHECK then
                        data.State = ModernSins.Consumerism.States.ATTACK_SWING

                        if direction.Y == 0 then
                            npc:GetSprite():Play("AttackHori", true)
                            npc:GetSprite():PlayOverlay("HeadRight", true)
                            npc.FlipX = direction.X < 0
                        elseif direction.Y > 0 then
                            npc:GetSprite():Play("AttackDown", true)
                            npc:GetSprite():PlayOverlay("HeadDown", true)
                        else
                            npc:GetSprite():Play("AttackUp", true)
                            npc:GetSprite():PlayOverlay("HeadUp", true)
                        end
                    else
                        data.AttackChargeDirection = direction
                        data.AttackChargePerformedIt = false
                        data.State = ModernSins.Consumerism.States.ATTACK_CHARGE

                        if direction.Y == 0 then
                            npc:GetSprite():SetFrame("WalkHori", 0)
                            npc:GetSprite():PlayOverlay("HeadLaughRight", true)
                            npc.FlipX = direction.X < 0
                        elseif direction.Y > 0 then
                            npc:GetSprite():SetFrame("WalkDown", 0)
                            npc:GetSprite():PlayOverlay("HeadLaughDown", true)
                        else
                            npc:GetSprite():SetFrame("WalkUp", 0)
                            npc:GetSprite():PlayOverlay("HeadLaughUp", true)
                        end
                    end

                    break

                end
            end
        end
            
    elseif data.State == ModernSins.Consumerism.States.ATTACK_CHARGE then
        if data.AttackChargePerformedIt then
            npc.Velocity = npc.Velocity + data.AttackChargeDirection * ATTACK_CHARGE_SPEED

            if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
                npc:GetSprite():Play("WalkHori")
                npc:GetSprite():PlayOverlay("HeadLaughRight")
                npc.FlipX = npc.Velocity.X < 0
            elseif npc.Velocity.Y > 0 then
                npc:GetSprite():Play("WalkDown")
                npc:GetSprite():PlayOverlay("HeadLaughDown")
            else
                npc:GetSprite():Play("WalkUp")
                npc:GetSprite():PlayOverlay("HeadLaughUp")
            end

            if data.StateFrameCount % ATTACK_CHARGE_BOMB_DROP_FREQUENCY == 0 then
                Isaac.Spawn
                (
                    EntityType.ENTITY_BOMB, BombVariant.BOMB_TROLL, 0,
                    npc.Position, rng:RandomVector(),
                    npc
                )
            end
        else
            local isOverlayFinished = npc:GetSprite():IsOverlayFinished("HeadLaughUp")
            isOverlayFinished = isOverlayFinished or npc:GetSprite():IsOverlayFinished("HeadLaughDown")
            isOverlayFinished = isOverlayFinished or npc:GetSprite():IsOverlayFinished("HeadLaughRight")
            if isOverlayFinished then
                npc.Velocity = npc.Velocity + data.AttackChargeDirection * ATTACK_CHARGE_SPEED
                data.AttackChargePerformedIt = true
                data.StateFrameCount = 0

                Isaac.Spawn
                (
                    EntityType.ENTITY_BOMB, BombVariant.BOMB_TROLL, 0,
                    npc.Position, rng:RandomVector(),
                    npc
                )
            end
        end
        npc:MultiplyFriction(0.7)

    elseif data.State == ModernSins.Consumerism.States.CHARGE_STUNNED then

        npc:MultiplyFriction(0.7)

        if data.StateFrameCount >= ATTACK_CHARGE_STUN_DURATION then
            data.State = ModernSins.Consumerism.States.MOVING
            data.AttackChargeCooldown = rng:RandomInt(ATTACK_MINIMUM_COOLDOWN, ATTACK_MAXIMUM_COOLDOWN)
        end

    elseif data.State == ModernSins.Consumerism.States.ATTACK_SWING then

        npc:MultiplyFriction(0.6)

        local capsule = npc:GetNullCapsule("Hitbox")
        for _, player in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.PLAYER)) do
            player:TakeDamage(1, 0, EntityRef(npc), 0)
        end

        local isFinished = npc:GetSprite():IsFinished("AttackDown")
        isFinished = isFinished or npc:GetSprite():IsFinished("AttackUp")
        isFinished = isFinished or npc:GetSprite():IsFinished("AttackHori")

        if isFinished then
            data.State = ModernSins.Consumerism.States.MOVING
            data.AttackChargeCooldown = rng:RandomInt(ATTACK_MINIMUM_COOLDOWN, ATTACK_MAXIMUM_COOLDOWN)
        end

    end

    data.StateFrameCount = data.StateFrameCount + 1

end, ModernSins.Consumerism.ID)

---@param npc EntityNPC
---@param gridIndex integer
---@param gridEntity GridEntity
ModernSins:AddCallback(ModCallbacks.MC_NPC_GRID_COLLISION, function (_, npc, gridIndex, gridEntity)
    if npc.Variant ~= ModernSins.Consumerism.Variant then
        return
    end

    local data = npc:GetData()
    
    if data.State ~= ModernSins.Consumerism.States.ATTACK_CHARGE then
        return
    end

    if gridEntity == nil then
        return
    end
    if gridEntity.CollisionClass == GridCollisionClass.COLLISION_NONE then
        return
    end

    npc.Velocity = -npc.Velocity * 0.5
    data.State = ModernSins.Consumerism.States.CHARGE_STUNNED
    data.StateFrameCount = 0
end, ModernSins.Consumerism.ID)

---@param entity Entity
---@param damage number
---@param flags DamageFlag
---@param source EntityRef
---@param countdown integer
ModernSins:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, entity, damage, flags, source, countdown)
    if entity.Variant ~= ModernSins.Consumerism.Variant then
        return nil
    end

    if source.Entity.Type ~= EntityType.ENTITY_BOMB then
        return nil
    end
    if source.Entity.Variant ~= BombVariant.BOMB_TROLL then
        return nil
    end

    return false
end, ModernSins.Consumerism.ID)

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function (_, npc)
    if npc.Variant ~= ModernSins.Consumerism.Variant then
        return
    end

    npc:BloodExplode()
    local rng = npc:GetDropRNG()

    if rng:RandomFloat() < 0.25 then
        local type = EntityType.ENTITY_PICKUP
        local variant = PickupVariant.PICKUP_COLLECTIBLE
        local subtype = ModernSins.Consumerism.DeathDropCollectible

        Isaac.Spawn
        (
            type, variant, subtype,
            npc.Position, Vector.Zero, nil
        )
    else
        for i, drop in ipairs(ModernSins.Consumerism.DeathDropPickups) do
            local type = drop[1]
            local variant = drop[2]
            local subtype = drop[3]

            Isaac.Spawn
            (
                type, variant, subtype,
                npc.Position, Vector.Zero, nil
            )
        end
    end
end, ModernSins.Consumerism.ID)