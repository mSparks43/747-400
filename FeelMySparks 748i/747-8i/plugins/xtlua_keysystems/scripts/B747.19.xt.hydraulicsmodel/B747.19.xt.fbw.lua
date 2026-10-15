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
local buffetEnabled = find_dataref("laminar/B747/fbw/buffet_enabled")
local mlaDemandOutput = find_dataref("laminar/B747/fbw/mla_demand")
local droopOutput = find_dataref("laminar/B747/fbw/aileron_droop_ratio")
local normalG = find_dataref("sim/flightmodel/forces/g_nrml")
local onGround = find_dataref("sim/flightmodel/failures/onground_any")
local indicatedAirspeed = find_dataref("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
local flapRatio = find_dataref("laminar/B747/cablecontrols/flap_ratio")
local stickShaker = find_dataref("sim/aircraft/forcefeedback/acf_ff_stickshaker")

local function apply(controlRatios)
    if type(controlRatios) ~= "table" then
        error("FBW control mixer requires the hydraulic control-ratio table")
    end

    local mlaDemand = 0
    local aileronDroop = 0
    local active = readNumber(enabled) >= 0.5
    local ias = readNumber(indicatedAirspeed)

    if active and ias >= 80 then
        local rollBoost = clamp(readNumber(rollResponseGain), 0, 0.25)
        local lowSpeedBlend = clamp((220 - ias) / 120, 0, 1)
        local leftAileron = controlRatios[9]
        local rightAileron = controlRatios[10]
        local commonAileron = (leftAileron + rightAileron) * 0.5
        local differentialAileron = (leftAileron - rightAileron) * 0.5
        differentialAileron = differentialAileron * (1 + rollBoost * lowSpeedBlend)
        controlRatios[9] = clamp(commonAileron + differentialAileron, -100, 100)
        controlRatios[10] = clamp(commonAileron - differentialAileron, -100, 100)

        if readNumber(droopEnabled) >= 0.5 then
            aileronDroop = clamp(readNumber(flapRatio), 0, 1) * 2.5
            controlRatios[9] = clamp(controlRatios[9] + aileronDroop, -100, 100)
            controlRatios[10] = clamp(controlRatios[10] + aileronDroop, -100, 100)
        end

        if readNumber(mlaEnabled) >= 0.5 and readNumber(onGround) < 0.5 then
            mlaDemand = clamp((readNumber(normalG) - 1.3) / 0.8, 0, 1)
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
    writeNumber(stickShaker, readNumber(buffetEnabled) >= 0.5 and 1 or 0)
end

B747_fbw = {
    apply = apply
}
