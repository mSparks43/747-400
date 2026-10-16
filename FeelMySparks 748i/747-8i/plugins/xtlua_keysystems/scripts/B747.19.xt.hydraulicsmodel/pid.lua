-- adaption of https://github.com/OpenPrograms/Kubuxu-Programs/blob/master/pid/pid.lua
-- Mark Parker, April 2022

local pid = {}

local function clamp(x, min, max)
  if x > max then
    return max
  elseif x < min then
    return min
  else
    return x
  end
end
function sleep(n)
  os.execute("sleep " .. tonumber(n))
end
--local seconds = os.clock

-- all values of the PID controller
-- values with '_' at beginning are considered private and should not be changed.
pid = {
    kp = 0.02,
    ki = 0.003,
    kd = 0.0002,
    input = nil,
    target = nil,
    output = nil,
    minout = -math.huge,
    maxout = math.huge,
    _lasttime = nil,
    _lastinput = nil,
    _lasterr= 0,
    _Iterm = 0
  }

  function pid:new(save)
    assert(save == nil or type(save) == "table", "If save is specified the it has to be table.")
    
    save = save or {}
    setmetatable(save, self)
    self.__index = self
    return save
  end
-- Exports calibration variables and targeted value.
function pid:save()
    return {kp = self.kp, ki = self.ki, kd = self.kd, target = self.target, minout = self.minout, maxout = self.maxout}
end 
  -- This is main method of PID controller.
  -- After creation of controller you have to set 'target' value in controller table
  -- then in loop you should regularly update 'input' value in controller table,
  -- call c:compute() and set 'output' value to the execution system.
  -- c.minout = 0
  -- c.maxout = 100
  -- while true do
  --   c.input = getCurrentEnergyLevel()
  --   c:compute()
  --   reactorcontrol:setAllControlRods(100 - c.output) -- PID expects the increase of output value will cause increase of input
  --   sleep(0.5)
  -- end
  -- You can limit output range by specifying 'minout' and 'maxout' values in controller table.
  -- By passing 'true' to the 'compute' function you will cause controller to not to take any actions but only
  -- refresh internal variables. It is most useful if PID controller was disconnected from the system.
  function pid:compute(waspaused)
    assert(self.input and self.target, "You have to sepecify current input and target before running compute()")
    -- reset values if PID was paused for prolonegd period of time
    if waspaused or self._lasttime == nil or self._lastinput == nil then
      self._lasttime = simDRTime--seconds()
      self._lastinput = self.input
      self._Iterm = self.output or 0
      return
    end
    local err = self.target - self.input
    local dtime = simDRTime - self._lasttime
    if dtime == 0 then
      return
    end
    self._Iterm = self._Iterm + self.ki * err * dtime
    self._Iterm = clamp(self._Iterm, self.minout, self.maxout)
    --local dinput = (self.input - self._lastinput) / dtime
    local dinput = (err - self._lasterr) / dtime
    self.output = self.kp * err + self._Iterm + self.kd * dinput
    self.output = clamp(self.output, self.minout, self.maxout)
    self._lasttime = simDRTime--seconds()
    self._lastinput = self.input
    self._lasterr = err
end

function newPid()
  return pid:new()
end
--[[local yaw=0.5


function getCurrentEnergyLevel()
    return yaw
end
function doYaw(rudder)
  if(rudder==nil) then
    return
  end
    yaw=yaw+rudder+rudder*rudder
end
print("hello")
c = pid:new()
c.minout=-1
c.maxout=1
c.target=10
c.input =getCurrentEnergyLevel()
c:compute()
targetTime=0.1
while true do
    c.input =getCurrentEnergyLevel()
    c:compute()

    doYaw(c.output)
    sleep(0.02)
    print(yaw)
    if seconds()>targetTime then 
      targetTime=targetTime+0.1  
      c.target=c.target-5
    end
    
end
print("hello")]]--
