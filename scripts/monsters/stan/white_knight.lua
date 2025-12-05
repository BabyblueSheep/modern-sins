ModernSins.Stan.WhiteKnight = {}

ModernSins.Stan.WhiteKnight.ID = Isaac.GetEntityTypeByName("White Knight")
ModernSins.Stan.WhiteKnight.Variant = Isaac.GetEntityVariantByName("White Knight")

ModernSins.Stan.WhiteKnight.States = {}
ModernSins.Stan.WhiteKnight.States.APPEAR = 0
ModernSins.Stan.WhiteKnight.States.MOVING = 1
ModernSins.Stan.WhiteKnight.States.CHARGING = 2
ModernSins.Stan.WhiteKnight.States.STUN = 3

local CHARGE_DIRECTIONS = {
    Vector(1, 0),
    Vector(0, 1),
    Vector(-1, 0),
    Vector(0, -1)
}
local CHARGE_SCAN_ACCURACY = 0.95
local CHARGE_AGGRO_TIME_AMOUNT = 5
local CHARGE_INITIAL_COOLDOWN = 60
local CHARGE_HIT_WALL_COOLDOWN = 30
local STUN_DURATION = 10

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if npc.Variant ~= ModernSins.Stan.WhiteKnight.Variant then
        return
    end

    local data = npc:GetData()
    local pathfinder = npc:GetPathfinder()
    local playerTarget = npc:GetPlayerTarget()

    if not data.Init then
        npc:GetSprite():Play("Appear", true)

        data.Init = true
        data.State = ModernSins.Stan.WhiteKnight.States.APPEAR

        data.ChargeCounter = 0
        data.ChargeCooldown = CHARGE_INITIAL_COOLDOWN
        data.ChargeDirection = Vector.Zero
        data.StunDuration = 0
    end

    if data.State == ModernSins.Stan.WhiteKnight.States.APPEAR then

        if npc:GetSprite():IsFinished("Appear") then
            data.State = ModernSins.Stan.WhiteKnight.States.MOVING
        end

    elseif data.State == ModernSins.Stan.WhiteKnight.States.MOVING then

        pathfinder:MoveRandomlyAxisAligned(1, false)
        npc:MultiplyFriction(0.8)

        if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
            npc:GetSprite():Play("WalkHori")
            npc.FlipX = npc.Velocity.X < 0
        elseif npc.Velocity.Y > 0 then
            npc:GetSprite():Play("WalkDown")
        else
            npc:GetSprite():Play("WalkUp")
        end

        if data.ChargeCooldown > 0 then
            data.ChargeCooldown = data.ChargeCooldown - 1
        end

        if data.ChargeCooldown <= 0 then
            local targetSpotted = false

            local targetDistance = playerTarget.Position - npc.Position
            targetDistance:Normalize()

            for i, direction in ipairs(CHARGE_DIRECTIONS) do
                if targetDistance:Dot(direction) > CHARGE_SCAN_ACCURACY then
                    targetSpotted = true
                    data.ChargeDirection = direction

                    break

                end
            end

            if targetSpotted then
                data.ChargeCounter = data.ChargeCounter + 1
                if data.ChargeCounter >= CHARGE_AGGRO_TIME_AMOUNT then
                    data.State = ModernSins.Stan.WhiteKnight.States.CHARGING
                    data.ChargeCounter = 0
                end
            else
                data.ChargeCounter = data.ChargeCounter - 2
                if data.ChargeCounter < 0 then
                    data.ChargeCounter = 0
                end
            end
            
        end

    elseif data.State == ModernSins.Stan.WhiteKnight.States.CHARGING then

        npc.Velocity = npc.Velocity + data.ChargeDirection * 3
        npc:MultiplyFriction(0.8)

        if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
            npc:GetSprite():Play("WalkHori")
            npc.FlipX = npc.Velocity.X < 0
        elseif npc.Velocity.Y > 0 then
            npc:GetSprite():Play("WalkDown")
        else
            npc:GetSprite():Play("WalkUp")
        end

    elseif data.State == ModernSins.Stan.WhiteKnight.States.STUN then

        npc:MultiplyFriction(0.8)

        data.StunDuration = data.StunDuration - 1
        if data.StunDuration <= 0 then
            data.State = ModernSins.Stan.WhiteKnight.States.MOVING
        end

    end

end, ModernSins.Stan.WhiteKnight.ID)

---@param npc EntityNPC
---@param gridIndex integer
---@param gridEntity GridEntity
ModernSins:AddCallback(ModCallbacks.MC_NPC_GRID_COLLISION, function (_, npc, gridIndex, gridEntity)
    if npc.Variant ~= ModernSins.Stan.WhiteKnight.Variant then
        return
    end

    local data = npc:GetData()
    
    if data.State ~= ModernSins.Stan.WhiteKnight.States.CHARGING then
        return
    end

    if gridEntity == nil then
        return
    end
    if gridEntity.CollisionClass == GridCollisionClass.COLLISION_NONE then
        return
    end

    data.State = ModernSins.Stan.WhiteKnight.States.STUN
    data.ChargeCooldown = CHARGE_HIT_WALL_COOLDOWN
    data.StunDuration = STUN_DURATION
end, ModernSins.Stan.WhiteKnight.ID)

---@param entity Entity
---@param damage number
---@param flags DamageFlag
---@param source EntityRef
---@param countdown integer
ModernSins:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, entity, damage, flags, source, countdown)
    if entity.Variant ~= ModernSins.Stan.WhiteKnight.Variant then
        return nil
    end
    
    return false
end, ModernSins.Stan.WhiteKnight.ID)