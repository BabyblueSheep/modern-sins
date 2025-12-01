ModernSins.Doomscroll = {}

ModernSins.Doomscroll.ID = Isaac.GetEntityTypeByName("Doomscroll")
ModernSins.Doomscroll.Variant = Isaac.GetEntityVariantByName("Doomscroll")

ModernSins.Doomscroll.States = {}
ModernSins.Doomscroll.States.APPEAR = 0
ModernSins.Doomscroll.States.MOVING = 1
ModernSins.Doomscroll.States.ATTACK_TECH = 2
ModernSins.Doomscroll.States.ATTACK_SCREEN = 3

ModernSins.Doomscroll.DeathDropPickups = { EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, BatterySubType.BATTERY_MICRO }
ModernSins.Doomscroll.DeathDropCollectible = CollectibleType.COLLECTIBLE_POKE_GO

local ATTACK_TECH_INITIAL_COOLDOWN = 90
local ATTACK_TECH_MINIMUM_COOLDOWN = 30
local ATTACK_TECH_MAXIMUM_COOLDOWN = 120

local ATTACK_TECH_LASER_SPEED = 12
local ATTACK_TECH_LASER_RADIUS = 32

local ATTACK_SCREEN_TECH_DIRECTIONS = {}
for i = 0, 360, 90 do
    table.insert(ATTACK_SCREEN_TECH_DIRECTIONS, Vector.FromAngle(i))
end
ATTACK_SCREEN_TECH_ANGLE_ACCURACY = 0.99

local ATTACK_SCREEN_INITIAL_TIMER = 150
local ATTACK_SCREEN_MINIMUM_TIMER = 90
local ATTACK_SCREEN_MAXIMUM_TIMER = 180

local ATTACK_SCREEN_PUSH_MAGNITUDE = 8
local ATTACK_SCREEN_PUSH_DURATION = 6



---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if npc.Variant ~= ModernSins.Doomscroll.Variant then
        return
    end

    local data = npc:GetData()

    if not data.Init then
        npc:GetSprite():Play("Appear", true)

        data.Init = true
        data.State = ModernSins.Doomscroll.States.APPEAR

        data.AttackScreenTimer = ATTACK_SCREEN_INITIAL_TIMER

        data.AttackTechCooldown = ATTACK_TECH_INITIAL_COOLDOWN
        data.AttackTechDirection = Vector.Zero
    end

    if data.State == ModernSins.Doomscroll.States.APPEAR then

        if npc:GetSprite():IsFinished("Appear") then
            data.State = ModernSins.Doomscroll.States.MOVING
        end

    elseif data.State == ModernSins.Doomscroll.States.MOVING then
        
        ---@type PathFinder
        local pathfinder = npc:GetPathfinder()
        pathfinder:MoveRandomlyAxisAligned(2, false)
        npc:MultiplyFriction(0.8)

        if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
            npc:GetSprite():Play("WalkHori")
            npc.FlipX = npc.Velocity.X < 0
        else
            npc:GetSprite():Play("WalkVert")
        end

        if data.AttackTechCooldown > 0 then
            data.AttackTechCooldown = data.AttackTechCooldown - 1
        end
        
        if data.AttackScreenTimer > 0 then
            data.AttackScreenTimer = data.AttackScreenTimer - 1
        end

        if data.AttackScreenTimer <= 0 then
            data.State = ModernSins.Doomscroll.States.ATTACK_SCREEN

            npc:GetSprite():Play("AttackScreen", true)
        else

            local playerTarget = npc:GetPlayerTarget()
            local room = Game():GetRoom()

            local isTargetVisible = room:CheckLine(playerTarget.Position, npc.Position, LineCheckMode.PROJECTILE)
            if isTargetVisible and data.AttackTechCooldown <= 0 then
                local targetDistance = playerTarget.Position - npc.Position
                targetDistance:Normalize()
                local shouldShoot = false
                local angle = Vector.Zero

                for i, direction in ipairs(ATTACK_SCREEN_TECH_DIRECTIONS) do
                    if targetDistance:Dot(direction) > ATTACK_SCREEN_TECH_ANGLE_ACCURACY then
                        shouldShoot = true
                        angle = direction
                        break
                    end
                end

                if shouldShoot then
                    data.AttackTechDirection = angle
                    data.State = ModernSins.Doomscroll.States.ATTACK_TECH

                    npc:GetSprite():Play("AttackTech", true)
                end
            end

        end

    elseif data.State == ModernSins.Doomscroll.States.ATTACK_TECH then

        npc:MultiplyFriction(0.5)

        if npc:GetSprite():IsEventTriggered("ShootTech") then
            local laser = Isaac.Spawn
            (
                EntityType.ENTITY_LASER, LaserVariant.THIN_RED, LaserSubType.LASER_SUBTYPE_RING_PROJECTILE,
                npc.Position, data.AttackTechDirection * ATTACK_TECH_LASER_SPEED,
                npc
            ):ToLaser()
            laser.Parent = npc
            laser.Radius = ATTACK_TECH_LASER_RADIUS
        end

        if npc:GetSprite():IsFinished("AttackTech") then
            data.State = ModernSins.Doomscroll.States.MOVING
            data.AttackTechCooldown = npc:GetDropRNG():RandomInt(ATTACK_TECH_MINIMUM_COOLDOWN, ATTACK_TECH_MAXIMUM_COOLDOWN)
        end

    elseif data.State == ModernSins.Doomscroll.States.ATTACK_SCREEN then

        npc:MultiplyFriction(0.5)

        if npc:GetSprite():IsEventTriggered("ScreenAttack") then
            for i, entity in ipairs(Isaac.GetRoomEntities()) do
                if GetPtrHash(npc) ~= GetPtrHash(entity) then
                    entity:AddKnockback(EntityRef(npc), Vector(0, 1) * ATTACK_SCREEN_PUSH_MAGNITUDE, ATTACK_SCREEN_PUSH_DURATION, false)
                end
            end
        end

        if npc:GetSprite():IsFinished("AttackScreen") then
            data.State = ModernSins.Doomscroll.States.MOVING
            data.AttackScreenTimer = npc:GetDropRNG():RandomInt(ATTACK_SCREEN_MINIMUM_TIMER, ATTACK_SCREEN_MAXIMUM_TIMER)
        end

    end
end, ModernSins.Doomscroll.ID)

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function (_, npc)
    if npc.Variant ~= ModernSins.Doomscroll.Variant then
        return
    end

    npc:BloodExplode()
    local rng = npc:GetDropRNG()

    local type, variant, subtype
    if rng:RandomFloat() < 0.25 then
        type = EntityType.ENTITY_PICKUP
        variant = PickupVariant.PICKUP_COLLECTIBLE
        subtype = ModernSins.Doomscroll.DeathDropCollectible
    else
        type = ModernSins.Doomscroll.DeathDropPickups[1]
        variant = ModernSins.Doomscroll.DeathDropPickups[2]
        subtype = ModernSins.Doomscroll.DeathDropPickups[3]
    end
    Isaac.Spawn
    (
        type, variant, subtype,
        npc.Position, Vector.Zero, nil
    )
end, ModernSins.Doomscroll.ID)