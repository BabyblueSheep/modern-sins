ModernSins.Ragebait = {}

ModernSins.Ragebait.ID = Isaac.GetEntityTypeByName("Ragebait")
ModernSins.Ragebait.Variant = Isaac.GetEntityVariantByName("Ragebait")
ModernSins.Ragebait.RingVariant = Isaac.GetEntityVariantByName("Ragebait Ring")

ModernSins.Ragebait.States = {}
ModernSins.Ragebait.States.APPEAR = 0
ModernSins.Ragebait.States.MOVING = 1
ModernSins.Ragebait.States.ATTACK_YELL = 2

ModernSins.Ragebait.DeathDropInfo = {
    CollectibleChance = 1/4,
    CollectibleType = CollectibleType.COLLECTIBLE_BOZO,
    PickupTypes = {
        { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, BombSubType.BOMB_TROLL }
    }
}

local DISTANCE_TO_ATTACK = 80
local ATTACK_COOLDOWN = 30

local MAXIMUM_SPEED = 7.5
local MINIMUM_SPEED = 0.5
local STARTING_SPEED = 0.5

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if npc.Variant ~= ModernSins.Ragebait.Variant then
        return
    end

    local data = npc:GetData()
    local rng = npc:GetDropRNG()
    local pathfinder = npc:GetPathfinder()
    local playerTarget = npc:GetPlayerTarget()

    if not data.Init then
        npc:GetSprite():Play("Appear", true)
        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

        data.Init = true
        data.State = ModernSins.Ragebait.States.APPEAR

        data.VelocitySpeed = STARTING_SPEED

        data.AttackCooldown = ATTACK_COOLDOWN
    end

    if data.State == ModernSins.Ragebait.States.APPEAR then

        if npc:GetSprite():IsFinished("Appear") then
            data.State = ModernSins.Ragebait.States.MOVING
        end

    elseif data.State == ModernSins.Ragebait.States.MOVING then
        
        if Game():GetRoom():CheckLine(npc.Position, playerTarget.Position, LineCheckMode.ENTITY, 500, false, false) then
            local previousDirection = npc.Velocity:Normalized()
            local direction = playerTarget.Position - npc.Position
            direction:Normalize()
            
            if direction:Dot(previousDirection) < 0.5 then
                data.VelocitySpeed = data.VelocitySpeed - 0.25
            else
                data.VelocitySpeed = data.VelocitySpeed + 0.25
            end
            data.VelocitySpeed = math.min(MAXIMUM_SPEED, math.max(MINIMUM_SPEED, data.VelocitySpeed))

            npc.Velocity = npc.Velocity * 0.9 + direction * data.VelocitySpeed * 0.1
        else
            data.VelocitySpeed = data.VelocitySpeed + 0.1
            data.VelocitySpeed = math.min(1, data.VelocitySpeed)
            pathfinder:FindGridPath(playerTarget.Position, data.VelocitySpeed, 900, true)
        end

        if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
            npc:GetSprite():Play("WalkHori")
            npc.FlipX = npc.Velocity.X < 0
        elseif npc.Velocity.Y > 0 then
            npc:GetSprite():Play("WalkDown")
        else
            npc:GetSprite():Play("WalkUp")
        end

        if data.AttackCooldown > 0 then
            data.AttackCooldown = data.AttackCooldown - 1
        end
        if npc.Position:Distance(playerTarget.Position) < DISTANCE_TO_ATTACK and data.AttackCooldown <= 0 then
            npc:GetSprite():Play("Attack01", true)
            data.State = ModernSins.Ragebait.States.ATTACK_YELL
        end

    elseif data.State == ModernSins.Ragebait.States.ATTACK_YELL then
        
        npc:MultiplyFriction(0.5)

        if npc:GetSprite():IsEventTriggered("Scream") then
            Isaac.Spawn
            (
                EntityType.ENTITY_EFFECT, ModernSins.Ragebait.RingVariant, 0,
                npc.Position, Vector.Zero, npc
            )
        end

        if npc:GetSprite():IsEventTriggered("InitialScream") then
            SFXManager():Play(SoundEffect.SOUND_BOSS_LITE_HISS)
            
            Isaac.Spawn
            (
                EntityType.ENTITY_EFFECT, ModernSins.Ragebait.RingVariant, 0,
                npc.Position, Vector.Zero, npc
            )
        end

        if npc:GetSprite():IsFinished("Attack01") then
            data.State = ModernSins.Ragebait.States.MOVING
            data.VelocitySpeed = STARTING_SPEED
            data.AttackCooldown = ATTACK_COOLDOWN
        end

    end
end, ModernSins.Ragebait.ID)

---@param effect EntityEffect
ModernSins:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function (_, effect)
    local capsule = effect:GetNullCapsule("Damage")
    --print(capsule)
    for _, player in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.PLAYER)) do
        player:TakeDamage(1, 0, EntityRef(effect.SpawnerEntity), 0)
    end

    if effect:GetSprite():IsFinished("Idle") then
        effect:Remove()
    end
end, ModernSins.Ragebait.RingVariant)

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function (_, npc)
    if npc.Variant ~= ModernSins.Ragebait.Variant then
        return
    end

    npc:BloodExplode()
    
    ModernSins:SpawnReward(npc, ModernSins.Ragebait.DeathDropInfo)
end, ModernSins.Ragebait.ID)