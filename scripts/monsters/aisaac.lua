ModernSins.AIsaac = {}

ModernSins.AIsaac.ID = Isaac.GetEntityTypeByName("AIsaac")
ModernSins.AIsaac.Variant = Isaac.GetEntityVariantByName("AIsaac")

ModernSins.AIsaac.States = {}
ModernSins.AIsaac.States.APPEAR = 0
ModernSins.AIsaac.States.MOVING = 1
ModernSins.AIsaac.States.SHOOT_TEARS = 2

local ATTACK_INITIAL_TIMER = 90
local ATTACK_MINIMUM_TIMER = 30
local ATTACK_MAXIMUM_TIMER = 90

local ATTACK_TEARS_PARAMS = ProjectileParams()

---@param npc EntityNPC
ModernSins:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if npc.Variant ~= ModernSins.AIsaac.Variant then
        return
    end

    local data = npc:GetData()

    if not data.Init then
        npc:GetSprite():Play("Appear", true)

        data.Init = true
        data.State = ModernSins.AIsaac.States.APPEAR

        data.AttackTimer = ATTACK_INITIAL_TIMER
    end

    if data.State == ModernSins.AIsaac.States.APPEAR then

        if npc:GetSprite():IsFinished("Appear") then
            data.State = ModernSins.AIsaac.States.MOVING
        end

    elseif data.State == ModernSins.AIsaac.States.MOVING then
        
        local pathfinder = npc:GetPathfinder()
        pathfinder:MoveRandomlyAxisAligned(0.9, false)
        --npc:MultiplyFriction(0.8)

        if math.abs(npc.Velocity.X) > math.abs(npc.Velocity.Y) then
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
            npc:GetSprite():Play("ShootDown")

            local tears = npc:FireProjectilesEx(npc.Position, )

        end

    end
end, ModernSins.AIsaac.ID)