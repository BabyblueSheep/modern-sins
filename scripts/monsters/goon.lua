ModernSins.Goon = {}

ModernSins.Goon.ID = Isaac.GetEntityTypeByName("Goon")
ModernSins.Goon.Variant = Isaac.GetEntityVariantByName("Goon")

ModernSins.Goon.States = {}
ModernSins.Goon.States.APPEAR = 0
ModernSins.Goon.States.MOVING = 1
ModernSins.Goon.States.IDLE = 2
ModernSins.Goon.States.ATTACK_SLAM = 3
ModernSins.Goon.States.ATTACK_SUMMON = 4

ModernSins.Goon.DeathDropInfo = {
    CollectibleChance = 1/4,
    CollectibleType = CollectibleType.COLLECTIBLE_JUICY_SACK,
    PickupTypes = {
        { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, 0 }
    }
}

local SWITCH_FROM_MOVING_TO_IDLE_CHANCE = 0.1
local MOVING_MINIMUM_FRAME_AMOUNT = 15
local SWITCH_FROM_IDLE_TO_MOVING_CHANCE = 0.1
local IDLE_MINIMUM_FRAME_AMOUNT = 30

local ATTACK_INITIAL_COOLDOWN = 90
local ATTACK_MINIMUM_COOLDOWN = 60
local ATTACK_MAXIMUM_COOLDOWN = 150

local CHANCE_TO_SLAM = 0.5

local SLAM_TEAR_AMOUNT = 20

local SLAM_TEARS_PARAMS = ProjectileParams()
SLAM_TEARS_PARAMS.Variant = ProjectileVariant.PROJECTILE_ROCK
SLAM_TEARS_PARAMS.HeightModifier = -500
SLAM_TEARS_PARAMS.FallingSpeedModifier = 2
SLAM_TEARS_PARAMS.FallingAccelModifier = 2

local FLY_SUMMON_AMOUNT = 2


---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if npc.Variant ~= ModernSins.Goon.Variant then
        return
    end

    local data = npc:GetData()
    local rng = npc:GetDropRNG()
    local pathfinder = npc:GetPathfinder()

    if not data.Init then
        npc:GetSprite():Play("Appear", true)

        data.Init = true
        data.State = ModernSins.Goon.States.APPEAR

        data.StateFrameCount = 0

        data.AttackCooldown = ATTACK_INITIAL_COOLDOWN
    end

    if data.State == ModernSins.Goon.States.APPEAR then

        if npc:GetSprite():IsFinished("Appear") then
            data.State = ModernSins.Goon.States.MOVING
        end

    elseif data.State == ModernSins.Goon.States.MOVING or data.State == ModernSins.Goon.States.IDLE then
        
        if data.State == ModernSins.Goon.States.MOVING then
            pathfinder:MoveRandomlyAxisAligned(2, false)

            if data.StateFrameCount > MOVING_MINIMUM_FRAME_AMOUNT and rng:RandomFloat() < SWITCH_FROM_MOVING_TO_IDLE_CHANCE then
                data.State = ModernSins.Goon.States.IDLE
                data.StateFrameCount = 0
            end
        else

            if data.StateFrameCount > IDLE_MINIMUM_FRAME_AMOUNT and rng:RandomFloat() < SWITCH_FROM_IDLE_TO_MOVING_CHANCE then
                data.State = ModernSins.Goon.States.MOVING
                data.StateFrameCount = 0
            end
        end
        data.StateFrameCount = data.StateFrameCount + 1

        npc:MultiplyFriction(0.8)

        if data.State == ModernSins.Goon.States.IDLE and npc.Velocity:Length() < 1 then
            npc:GetSprite():SetFrame("WalkDown", 0)
        elseif math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
            if npc.Velocity.X > 0 then
                npc:GetSprite():Play("WalkRight")
            else
                npc:GetSprite():Play("WalkLeft")
            end
        else
            if npc.Velocity.Y > 0 then
                npc:GetSprite():Play("WalkDown")
            else
                npc:GetSprite():Play("WalkUp")
            end
        end

        data.AttackCooldown = data.AttackCooldown - 1
        if data.AttackCooldown <= 0 then
            if rng:RandomFloat() < CHANCE_TO_SLAM then
                data.State = ModernSins.Goon.States.ATTACK_SLAM
                npc:GetSprite():Play("Transition", true)
            else
                data.State = ModernSins.Goon.States.ATTACK_SUMMON
                npc:GetSprite():Play("Transition", true)
            end
        end
        
    elseif data.State == ModernSins.Goon.States.ATTACK_SLAM then
        
        npc:MultiplyFriction(0.5)
        
        if npc:GetSprite():IsEventTriggered("Shoot") then
            SFXManager():Play(SoundEffect.SOUND_HELLBOSS_GROUNDPOUND)
            Game():ShakeScreen(15)

            for i = 0, SLAM_TEAR_AMOUNT - 1 do
                Isaac.CreateTimer(function ()
                    local tear = npc:FireProjectilesEx(Game():GetRoom():GetRandomPosition(0), rng:RandomVector() * rng:RandomFloat(), ProjectileMode.SINGLE, SLAM_TEARS_PARAMS)
                    tear = tear[1]
                    tear:Update()
                end, i * 2, 1, false)
            end
        end

        if npc:GetSprite():IsFinished("Transition") then
            data.State = ModernSins.Goon.States.IDLE
            data.StateFrameCount = 0
            data.AttackCooldown = rng:RandomInt(ATTACK_MINIMUM_COOLDOWN, ATTACK_MAXIMUM_COOLDOWN)
        end

    elseif data.State == ModernSins.Goon.States.ATTACK_SUMMON then
        
        npc:MultiplyFriction(0.5)

        if npc:GetSprite():IsEventTriggered("Shoot") then
            SFXManager():Play(SoundEffect.SOUND_SPIDER_COUGH)

            for i = 0, FLY_SUMMON_AMOUNT - 1 do
                local offset = rng:RandomVector() * 30
                local fly = Isaac.Spawn(EntityType.ENTITY_DART_FLY, 0, 0, npc.Position + offset, Vector.Zero, npc)
            end
        end

        if npc:GetSprite():IsFinished("Transition") then
            data.State = ModernSins.Goon.States.IDLE
            data.StateFrameCount = 0
            data.AttackCooldown = rng:RandomInt(ATTACK_MINIMUM_COOLDOWN, ATTACK_MAXIMUM_COOLDOWN)
        end

    end
end, ModernSins.Goon.ID)

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function (_, npc)
    if npc.Variant ~= ModernSins.Goon.Variant then
        return
    end

    npc:BloodExplode()
    
    ModernSins:SpawnReward(npc, ModernSins.Goon.DeathDropInfo)
end, ModernSins.Goon.ID)