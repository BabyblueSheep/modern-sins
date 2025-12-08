ModernSins.Soy = {}

ModernSins.Soy.ID = Isaac.GetEntityTypeByName("Soy")
ModernSins.Soy.Variant = Isaac.GetEntityVariantByName("Soy")

ModernSins.Soy.States = {}
ModernSins.Soy.States.APPEAR = 0
ModernSins.Soy.States.MOVING = 1
ModernSins.Soy.States.ATTACK = 2

ModernSins.Soy.DeathDropInfo = {
    CollectibleChance = 1/4,
    CollectibleType = CollectibleType.COLLECTIBLE_SOY_MILK,
    PickupTypes = {
        { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, 0 }
    }
}

local MOVING_TIME_AMOUNT_INITIAL = 60
local MOVING_TIME_AMOUNT_MINIMUM = 30
local MOVING_TIME_AMOUNT_MAXIMUM = 90

local SHOOTING_TIME_AMOUNT_MINIMUM = 15
local SHOOTING_TIME_AMOUNT_MAXIMUM = 45

local TEAR_SHOOT_COOLDOWN = 2

local ATTACK_TEAR_SPEED = 8

local ATTACK_TEARS_PARAMS = ProjectileParams()
ATTACK_TEARS_PARAMS.Variant = ProjectileVariant.PROJECTILE_TEAR
--ATTACK_TEARS_PARAMS.FallingAccelModifier = 0.3
ATTACK_TEARS_PARAMS.Color = Color.TearSoy
ATTACK_TEARS_PARAMS.Scale = 0.01

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if npc.Variant ~= ModernSins.Soy.Variant then
        return
    end

    local data = npc:GetData()
    local rng = npc:GetDropRNG()
    local pathfinder = npc:GetPathfinder()

    if not data.Init then
        npc:GetSprite():Play("Appear", true)

        data.Init = true
        data.State = ModernSins.Soy.States.APPEAR

        data.TimeInStateLeft = MOVING_TIME_AMOUNT_INITIAL
        data.TearShootCooldown = 0
    end

    if data.State == ModernSins.Soy.States.APPEAR then

        if npc:GetSprite():IsFinished("Appear") then
            data.State = ModernSins.Soy.States.MOVING
        end

    elseif data.State == ModernSins.Soy.States.MOVING then

        pathfinder:MoveRandomly(false)
        npc:MultiplyFriction(0.8)

        if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
            npc:GetSprite():Play("WalkHori")
            npc.FlipX = npc.Velocity.X < 0
        else
            npc:GetSprite():Play("WalkVert")
        end

        data.TimeInStateLeft = data.TimeInStateLeft - 1
        if data.TimeInStateLeft <= 0 then
            data.State = ModernSins.Soy.States.ATTACK
            data.TimeInStateLeft = rng:RandomInt(SHOOTING_TIME_AMOUNT_MINIMUM, SHOOTING_TIME_AMOUNT_MAXIMUM)

            data.TearShootCooldown = 0
        end

    elseif data.State == ModernSins.Soy.States.ATTACK then

        npc:MultiplyFriction(0.5)
        
        local playerTarget = npc:GetPlayerTarget()
        local distanceToPlayer = playerTarget.Position - npc.Position
        distanceToPlayer:Normalize()
        local angleToPlayer = distanceToPlayer:GetAngleDegrees()
        local angleToShoot = math.floor((angleToPlayer + 45) / 90) * 90

        data.TearShootCooldown = data.TearShootCooldown - 1
        if data.TearShootCooldown <= 0 then
            data.TearShootCooldown = TEAR_SHOOT_COOLDOWN

            npc:FireProjectiles(npc.Position, distanceToPlayer * ATTACK_TEAR_SPEED, ProjectileMode.SINGLE, ATTACK_TEARS_PARAMS)
            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE)
        end

        if angleToShoot == 90 then
            npc:GetSprite():Play("Attack01Down")
        elseif angleToShoot == 90 then
            npc:GetSprite():Play("Attack01Up")
        else
            npc:GetSprite():Play("Attack01Hori")
            npc.FlipX = angleToShoot == -180
        end

        data.TimeInStateLeft = data.TimeInStateLeft - 1
        if data.TimeInStateLeft <= 0 then
            data.State = ModernSins.Soy.States.MOVING
            data.TimeInStateLeft = rng:RandomInt(MOVING_TIME_AMOUNT_MINIMUM, MOVING_TIME_AMOUNT_MAXIMUM)
        end

    end

end)

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function (_, npc)
    if npc.Variant ~= ModernSins.Soy.Variant then
        return
    end

    npc:BloodExplode()
    
    ModernSins:SpawnReward(npc, ModernSins.Soy.DeathDropInfo)
end, ModernSins.Soy.ID)