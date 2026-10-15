local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function readNumber(ref)
    if type(ref) == "table" then
        local getter = rawget(ref, "__get")
        if getter then return getter(ref) end
    end
    return ref
end

local function writeNumber(ref, value)
    if type(ref) == "table" then
        local setter = rawget(ref, "__set")
        if setter then
            setter(ref, value)
            return
        end
    end
    error("FBW output DataRef is not writable")
end

local enabled = find_dataref("laminar/B747/fbw/enabled")
local mlaEnabled = find_dataref("laminar/B747/fbw/mla_enabled")
local droopEnabled = find_dataref("laminar/B747/fbw/droop_enabled")
local rollResponseGain = find_dataref("laminar/B747/fbw/roll_response_gain")
local rollRateDampingGain = find_dataref("laminar/B747/fbw/roll_rate_damping_gain")
local buffetEnabled = find_dataref("laminar/B747/fbw/buffet_enabled")
local mlaDemandOutput = find_dataref("laminar/B747/fbw/mla_demand")
local droopOutput = find_dataref("laminar/B747/fbw/aileron_droop_ratio")
local normalG = find_dataref("sim/flightmodel/forces/g_nrml")
local onGround = find_dataref("sim/flightmodel/failures/onground_any")
local indicatedAirspeed = find_dataref("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
local rollRate = find_dataref("sim/flightmodel/position/P")
local flapRatio = find_dataref("laminar/B747/cablecontrols/flap_ratio")
local stickShaker = find_dataref("sim/aircraft/forcefeedback/acf_ff_stickshaker")
local simTime = find_dataref("sim/time/total_running_time_sec")

local lawUpdatePeriod = 0.2
local lastLawUpdate = -1
local lawState = {
    lowSpeedBlend = 0,
    rollResponseGain = 0,
    rollRateDamping = 0,
    mlaDemand = 0,
    aileronDroop = 0,
    active = false
}

local function updateLawState()
    local now = readNumber(simTime)
    if lastLawUpdate >= 0 and now >= lastLawUpdate and now - lastLawUpdate < lawUpdatePeriod then
        return
    end

    lastLawUpdate = now
    lawState.active = readNumber(enabled) >= 0.5
    local ias = readNumber(indicatedAirspeed)
    local airborne = readNumber(onGround) < 0.5
    if not lawState.active or ias < 80 then
        lawState.lowSpeedBlend = 0
        lawState.rollResponseGain = 0
        lawState.rollRateDamping = 0
        lawState.mlaDemand = 0
        lawState.aileronDroop = 0
        return
    end

    lawState.lowSpeedBlend = clamp((220 - ias) / 120, 0, 1)
    lawState.rollResponseGain = clamp(readNumber(rollResponseGain), 0, 0.15)
        * lawState.lowSpeedBlend
    lawState.aileronDroop = readNumber(droopEnabled) >= 0.5
        and clamp(readNumber(flapRatio), 0, 1) * 2.5
        or 0

    local targetMlaDemand = 0
    if readNumber(mlaEnabled) >= 0.5 and airborne then
        targetMlaDemand = clamp((readNumber(normalG) - 1.3) / 0.8, 0, 1)
    end
    local mlaStep = targetMlaDemand - lawState.mlaDemand
    lawState.mlaDemand = lawState.mlaDemand + clamp(mlaStep, -0.2, 0.4)

    lawState.rollRateDamping = 0
    if airborne and readNumber(rollRateDampingGain) > 0 then
        lawState.rollRateDamping = clamp(
            readNumber(rollRate) * clamp(readNumber(rollRateDampingGain), 0, 1),
            -6,
            6
        )
    end
end

local function apply(controlRatios)
    if type(controlRatios) ~= "table" then
        error("FBW control mixer requires the hydraulic control-ratio table")
    end

    updateLawState()
    local mlaDemand = lawState.mlaDemand
    local aileronDroop = lawState.aileronDroop

    if lawState.active and readNumber(indicatedAirspeed) >= 80 then
        local leftAileron = controlRatios[9]
        local rightAileron = controlRatios[10]
        local commonAileron = (leftAileron + rightAileron) * 0.5
        local differentialAileron = (leftAileron - rightAileron) * 0.5
        differentialAileron = differentialAileron * (1 + lawState.rollResponseGain)
        if math.abs(differentialAileron) < 10 then
            differentialAileron = differentialAileron - lawState.rollRateDamping
        end
        controlRatios[9] = clamp(commonAileron + differentialAileron, -100, 100)
        controlRatios[10] = clamp(commonAileron - differentialAileron, -100, 100)

        if aileronDroop > 0 then
            controlRatios[9] = clamp(controlRatios[9] + aileronDroop, -100, 100)
            controlRatios[10] = clamp(controlRatios[10] + aileronDroop, -100, 100)
        end

        if mlaDemand > 0 then
            local aileronRelief = mlaDemand * 4
            local spoilerRelief = mlaDemand * 3
            controlRatios[9] = clamp(controlRatios[9] - aileronRelief, -100, 100)
            controlRatios[10] = clamp(controlRatios[10] - aileronRelief, -100, 100)
            for index = 15, 18 do
                controlRatios[index] = clamp(controlRatios[index] + spoilerRelief, -100, 100)
            end
        end
    end

    writeNumber(mlaDemandOutput, mlaDemand)
    writeNumber(droopOutput, aileronDroop)
    writeNumber(stickShaker, lawState.active and readNumber(buffetEnabled) >= 0.5 and 1 or 0)
end

B747_fbw = {
    apply = apply
}
