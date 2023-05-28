local function NormalizeAngle(angle)
    while angle > 180 do
        angle = angle - 360
    end

    while angle < -180 do
        angle = angle + 360
    end

    return angle
end

local function GetBestHitbox(player)
    local localPos = entities.GetLocalPlayer():GetAbsOrigin()

    local bestHitbox = 0
    local bestDistance = 99999

    for i = 0, 18 do
        local hitboxPos = player:GetHitboxPosition(i)
        local distance = (localPos - hitboxPos):Length()

        if distance < bestDistance then
            bestHitbox = i
            bestDistance = distance
        end
    end

    return bestHitbox
end

local function IsVisible(player, hitbox)
    local localPlayer = entities.GetLocalPlayer()
    local playerPos = player:GetHitboxPosition(hitbox)

    local traceResult = engine.TraceLine(localPlayer:GetAbsOrigin(), playerPos, 0x46004009)

    return traceResult.entity == player
end

local function IsAntiAim(player)
    local angles = player:GetPropVector("m_angEyeAngles")

    if angles.x > 85 or angles.x < -85 then
        return true
    end

    return false
end

local function GetHitboxAngle(player, hitbox)
    local localPlayer = entities.GetLocalPlayer()
    local hitboxPos = player:GetHitboxPosition(hitbox)

    local aimVector = hitboxPos - localPlayer:GetAbsOrigin()
    local aimAngles = aimVector:Angles()

    local pitch = NormalizeAngle(aimAngles.pitch)
    local yaw = NormalizeAngle(aimAngles.yaw)

    return pitch, yaw
end

local function GetHitboxAnglesDelta(player, hitbox)
    local eyeAngles = engine.GetViewAngles() or client.GetViewAngles()
    local pitch, yaw = GetHitboxAngle(player, hitbox)

    local pitchDelta = NormalizeAngle(pitch - eyeAngles.pitch)
    local yawDelta = NormalizeAngle(yaw - eyeAngles.yaw)

    return pitchDelta, yawDelta
end

local function GetVelocity(player)
    local velocityProp = player:GetPropFloat("localdata", "m_vecVelocity[0]")
    return Vector3(velocityProp, velocityProp, player:GetPropFloat("localdata", "m_vecVelocity[2]"))
end

local function Resolve(player)
    local localPlayer = entities.GetLocalPlayer()

    if not localPlayer or type(player) ~= "table" or not player:IsPlayer() or not player:IsAlive() or IsAntiAim(player) then
        return
    end

    local bestHitbox = GetBestHitbox(player)

    local pitchDelta, yawDelta = GetHitboxAnglesDelta(player, bestHitbox)

    local currentAngles = engine.GetViewAngles() or client.GetViewAngles()
    local newAngles = EulerAngles(currentAngles.pitch + pitchDelta, currentAngles.yaw + yawDelta, 0)

    local velocity = GetVelocity(player)

    if velocity:Length2D() > 100 then
        local smoothedVelocity = velocity * (1 / (globals.TickInterval() * 10))
        local smoothedAngles = engine.GetViewAngles() or client.GetViewAngles() + EulerAngles(0, NormalizeAngle(smoothedVelocity.yaw - currentAngles.yaw), 0)
        newAngles = smoothedAngles
    end

    if not IsVisible(player, bestHitbox) then
        newAngles = engine.GetViewAngles() or client.GetViewAngles()
    end

    if not input.IsButtonDown(1) and input.IsButtonDown(2) then
        engine.SetViewAngles(newAngles)
    end
end

local function OnPlayerConnect(event)
    local userid = event:GetInt("userid")
    local playerIndex = client.GetPlayerIndexByUserID(userid)

    if playerIndex == client.GetLocalPlayerIndex() then
        -- Wykonaj dowolne czynności, które są wymagane przy połączeniu nowego gracza lokalnego
        print("Soul: Resolver reloaded.")
    else
        local playerName = entities.GetByUserID(userid):GetName()
        print("Soul: Resolver reloaded.")
    end
end

local function OnPlayerDisconnect(event)
    local userid = event:GetInt("userid")
    local playerIndex = client.GetPlayerIndexByUserID(userid)

    if playerIndex == client.GetLocalPlayerIndex() then
        -- Wykonaj dowolne czynności, które są wymagane przy rozłączeniu lokalnego gracza
        print("Soul: Resolver reloaded.")
    else
        local playerName = entities.GetByUserID(userid):GetName()
        print("Soul: Resolver reloaded.")
    end
end

local function OnFrameStageNotify(stage)
    if stage == 5 then
        local localPlayer = entities.GetLocalPlayer()
        if localPlayer and localPlayer:IsAlive() then
            for i = 1, entities.GetHighestEntityIndex() do
                local entity = entities.GetByIndex(i)
                if entity and entity:IsPlayer() and entity:IsAlive() and entity:GetTeamNumber() ~= localPlayer:GetTeamNumber() then
                    Resolve(entity)
                end
            end
        end
    end
end

callbacks.Register("player_connect", OnPlayerConnect)
callbacks.Register("player_disconnect", OnPlayerDisconnect)
callbacks.Register("frame_stage_notify", OnFrameStageNotify)

client.AllowListener("player_connect")
client.AllowListener("player_disconnect")
