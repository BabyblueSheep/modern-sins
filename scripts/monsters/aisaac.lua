ModernSins.AIsaac = {}

ModernSins.AIsaac.ID = Isaac.GetEntityTypeByName("AIsaac")
ModernSins.AIsaac.Variant = Isaac.GetEntityVariantByName("AIsaac")

ModernSins.AIsaac.States = {}
ModernSins.AIsaac.States.APPEAR = 0
ModernSins.AIsaac.States.IDLE = 1
ModernSins.AIsaac.States.MOVING = 2
ModernSins.AIsaac.States.SHOOT_TEARS = 3

ModernSins.AIsaac.DeathDropPickups =
{ 
    { EntityType.ENTITY_PICKUP, 0, 0 }
}
ModernSins.AIsaac.DeathDropCollectible = CollectibleType.COLLECTIBLE_EYE_SORE

local SWITCH_FROM_MOVING_TO_IDLE_CHANCE = 0.05
local MOVING_MINIMUM_FRAME_AMOUNT = 30
local SWITCH_FROM_IDLE_TO_MOVING_CHANCE = 0.1
local IDLE_MINIMUM_FRAME_AMOUNT = 10

local ATTACK_INITIAL_TIMER = 90
local ATTACK_MINIMUM_TIMER = 30
local ATTACK_MAXIMUM_TIMER = 90

local ATTACK_TEAR_AMOUNT_MINIMUM = 3
local ATTACK_TEAR_AMOUNT_MAXIMUM = 7
local ATTACK_TEAR_SPEED = 5
local ATTACK_TEAR_ANGLE_SPREAD = 45
local ATTACK_TEAR_FALLING_SPEED_MINIMUM = -4
local ATTACK_TEAR_FALLING_SPEED_MAXIMUM = 1

local ATTACK_TEARS_PARAMS = ProjectileParams()

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if npc.Variant ~= ModernSins.AIsaac.Variant then
        return
    end

    local data = npc:GetData()
    local rng = npc:GetDropRNG()

    if not data.Init then
        npc:GetSprite():Play("Appear", true)

        data.Init = true
        data.State = ModernSins.AIsaac.States.APPEAR

        data.AttackTimer = ATTACK_INITIAL_TIMER
        data.StateFrameCount = 0
    end

    if data.State == ModernSins.AIsaac.States.APPEAR then

        if npc:GetSprite():IsFinished("Appear") then
            data.State = ModernSins.AIsaac.States.MOVING
        end

    elseif data.State == ModernSins.AIsaac.States.MOVING or data.State == ModernSins.AIsaac.States.IDLE then
        
        if data.State == ModernSins.AIsaac.States.MOVING then
            local pathfinder = npc:GetPathfinder()
            pathfinder:MoveRandomlyAxisAligned(rng:RandomFloat() * 5, false)
            npc:MultiplyFriction(0.8)

            if data.StateFrameCount > MOVING_MINIMUM_FRAME_AMOUNT and rng:RandomFloat() < SWITCH_FROM_MOVING_TO_IDLE_CHANCE then
                data.State = ModernSins.AIsaac.States.IDLE
                data.StateFrameCount = 0
            end
        else
            npc:MultiplyFriction(0.8)

            if data.StateFrameCount > IDLE_MINIMUM_FRAME_AMOUNT and rng:RandomFloat() < SWITCH_FROM_IDLE_TO_MOVING_CHANCE then
                data.State = ModernSins.AIsaac.States.MOVING
                data.StateFrameCount = 0
            end
        end
        data.StateFrameCount = data.StateFrameCount + 1

        if data.State == ModernSins.AIsaac.States.IDLE and npc.Velocity:Length() < 1 then
            npc:GetSprite():Play("Idle", true)
        elseif math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
            npc:GetSprite():Play("WalkHori")
            npc.FlipX = npc.Velocity.X < 0
        elseif npc.Velocity.Y > 0 then
            npc:GetSprite():Play("WalkUp")
        else
            npc:GetSprite():Play("WalkDown")
        end
        
        if data.AttackTimer > 0 then
            data.AttackTimer = data.AttackTimer - 1
        end

        if data.AttackTimer <= 0 then
            
            data.State = ModernSins.AIsaac.States.SHOOT_TEARS
            npc:GetSprite():Play("ShootDown", true)

            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE)

            local tearAmount = rng:RandomInt(ATTACK_TEAR_AMOUNT_MINIMUM, ATTACK_TEAR_AMOUNT_MAXIMUM)
            local tearParamsVelocity = Vector(ATTACK_TEAR_SPEED, tearAmount)
            local tears = npc:FireProjectilesEx(npc.Position, tearParamsVelocity, ProjectileMode.CIRCLE_CUSTOM, ATTACK_TEARS_PARAMS)
            for i, tear in ipairs(tears) do
                local angle = (rng:RandomFloat() * 2 - 1) * ATTACK_TEAR_ANGLE_SPREAD
                tear.Velocity = tear.Velocity:Rotated(angle)
                tear.FallingSpeed = ATTACK_TEAR_FALLING_SPEED_MINIMUM + (ATTACK_TEAR_FALLING_SPEED_MAXIMUM - ATTACK_TEAR_FALLING_SPEED_MINIMUM) * rng:RandomFloat() 
            end

        end

    elseif data.State == ModernSins.AIsaac.States.SHOOT_TEARS then
        
        npc:MultiplyFriction(0.5)

        if npc:GetSprite():IsFinished("ShootDown") then
            data.State = ModernSins.AIsaac.States.MOVING
            data.AttackTimer = rng:RandomInt(ATTACK_MINIMUM_TIMER, ATTACK_MAXIMUM_TIMER)
        end

    end
end, ModernSins.AIsaac.ID)

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function (_, npc)
    if npc.Variant ~= ModernSins.AIsaac.Variant then
        return
    end

    npc:BloodExplode()
    local rng = npc:GetDropRNG()

    if rng:RandomFloat() < 0.25 then
        local type = EntityType.ENTITY_PICKUP
        local variant = PickupVariant.PICKUP_COLLECTIBLE
        local subtype = ModernSins.AIsaac.DeathDropCollectible

        Isaac.Spawn
        (
            type, variant, subtype,
            npc.Position, Vector.Zero, nil
        )
    else
        for i, drop in ipairs(ModernSins.AIsaac.DeathDropPickups) do
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
end, ModernSins.AIsaac.ID)