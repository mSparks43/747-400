simDR_headX=find_dataref("sim/graphics/view/pilots_head_x")
simDR_headY=find_dataref("sim/graphics/view/pilots_head_y")
simDR_headZ=find_dataref("sim/graphics/view/pilots_head_z")
simDR_headpsi=find_dataref("sim/graphics/view/pilots_head_psi")
simDR_headpitch=find_dataref("sim/graphics/view/pilots_head_the")
simCMD_viewUP					= find_command("sim/general/up")
simCMD_viewDOWN					= find_command("sim/general/down")
simCMD_viewLEFT					= find_command("sim/general/left")
simCMD_viewRIGHT				= find_command("sim/general/right")
simCMD_viewFWD					= find_command("sim/general/forward")
simCMD_viewBACK					= find_command("sim/general/backward")
simCMD_viewUPFast					= find_command("sim/general/up_fast")
simCMD_viewDOWNFast					= find_command("sim/general/down_fast")
simCMD_viewLEFTFast					= find_command("sim/general/left_fast")
simCMD_viewRIGHTFast				= find_command("sim/general/right_fast")
simCMD_viewFWDFast					= find_command("sim/general/forward_fast")
simCMD_viewBACKFast					= find_command("sim/general/backward_fast")
simDRTime=find_dataref("sim/time/total_running_time_sec")

pilotSeatHotspot={}
pilotSeatHotspot[0]=-0.53738
pilotSeatHotspot[1]=5.174243
pilotSeatHotspot[2]=(-26.094387)--+2.5)

fmcLHotspot={}
fmcLHotspot[0]=-0.240369
fmcLHotspot[1]=4.957494
fmcLHotspot[2]=(-26.407701)--+2.5)

mcpHotspot={}
mcpHotspot[0]=-0.059938
mcpHotspot[1]=5.153586
mcpHotspot[2]=(-26.093819)--+2.5)

ocpHotspot={}
ocpHotspot[0]=-0.059938
ocpHotspot[1]=5.153586
ocpHotspot[2]=(-25.635084)--+2.5)

docHotspot={}
docHotspot[0]=-0.546462
docHotspot[1]=5.301905
docHotspot[2]=(-26.0)--+2.5)

srcHotspot={}
srcHotspot[0]=-0.059938
srcHotspot[1]=5.153586
srcHotspot[2]=(-25.635084)--+2.5)

movingtoTarget=false
targetHotspot=pilotSeatHotspot
local dX=0
local dY=0
local dZ=0
function killMoves()
  if dX>0.1 then simCMD_viewRIGHT:stop() dX=0 end
    if dX<-0.1 then simCMD_viewLEFT:stop() dX=0 end
    if dY>0.1 then simCMD_viewUP:stop() dY=0 end
    if dY<-0.1 then simCMD_viewDOWN:stop() dY=0 end
    if dZ>0.1 then simCMD_viewBACK:stop() dZ=0 end
    if dZ<-0.1 then simCMD_viewFWD:stop() dZ=0 end
end
function B747CMD_VR_stop_CMDhandler(phase, duration)
  simCMD_viewRIGHT:stop()
  simCMD_viewLEFT:stop()
  simCMD_viewUP:stop()
  simCMD_viewDOWN:stop()
  simCMD_viewBACK:stop()
  simCMD_viewFWD:stop()
end

function B747CMD_VR_toPilot_CMDhandler(phase, duration)
  if phase ==0 then
    targetHotspot=pilotSeatHotspot
    movingtoTarget=true
  elseif phase==2 then
    --movingtoTarget=false
    --killMoves()
  end
end
function B747CMD_VR_toFMC_CMDhandler(phase, duration)
  if phase ==0 then
    targetHotspot=fmcLHotspot
    movingtoTarget=true
  elseif phase==2 then
    --movingtoTarget=false
    --killMoves()
  end
end
function B747CMD_VR_toMCP_CMDhandler(phase, duration)
  if phase ==0 then
    targetHotspot=mcpHotspot
    movingtoTarget=true
  elseif phase==2 then
    --movingtoTarget=false
    --killMoves()
  end
end
function B747CMD_VR_toOCP_CMDhandler(phase, duration)
  if phase ==0 then
    targetHotspot=ocpHotspot
    movingtoTarget=true
  elseif phase==2 then
    --movingtoTarget=false
    --killMoves()
  end
end

function B747CMD_VR_toDOC_CMDhandler(phase, duration)
  if phase ==0 then
    srcHotspot[0]=simDR_headX
    srcHotspot[1]=simDR_headY
    srcHotspot[2]=simDR_headZ
    targetHotspot=docHotspot
    movingtoTarget=true
  elseif phase==2 then
    --movingtoTarget=false
    --killMoves()
    targetHotspot=srcHotspot
    movingtoTarget=true
  end
end

B747CMD_VR_toPilot 				= create_command("laminar/B747/VR/pilotView", "Move to Pilot hotspot", B747CMD_VR_toPilot_CMDhandler)
B747CMD_VR_toFMC 				= create_command("laminar/B747/VR/fmcView", "Move to FMC hotspot", B747CMD_VR_toFMC_CMDhandler)
B747CMD_VR_toMCP 				= create_command("laminar/B747/VR/mcpView", "Move to MCP hotspot", B747CMD_VR_toMCP_CMDhandler)
B747CMD_VR_toOCP 				= create_command("laminar/B747/VR/ocpView", "Move to OCP hotspot", B747CMD_VR_toOCP_CMDhandler)
B747CMD_VR_toDoc 				= create_command("laminar/B747/VR/docView", "Move to Docking hotspot", B747CMD_VR_toDOC_CMDhandler)
B747CMD_VR_stop 				= create_command("laminar/B747/VR/stopMove", "Stop move commands", B747CMD_VR_stop_CMDhandler)


nextCom=find_command("AutoATC/NextCom")
prevCom=find_command("AutoATC/PrevCom")
swapCom=find_command("AutoATC/swapFreq")

function after_physics()
  if movingtoTarget==false then

    return
  end

  local diffX=targetHotspot[0]-simDR_headX
  nox=false
  if diffX<-0.02 then
    if dX>0.1 then dX=0 simCMD_viewRIGHT:stop()  end
    if dX>=0 then dX=-1 simCMD_viewLEFT:start()  end
  elseif diffX>0.02 then
     if dX<-0.1 then dX=0 simCMD_viewLEFT:stop()  end
     if dX<=0 then dX=1 simCMD_viewRIGHT:start()  end
  else
    if dX>0.1 then dX=0 simCMD_viewRIGHT:stop()  end
    if dX<-0.1 then dX=0 simCMD_viewLEFT:stop()  end
    nox=true
  end
  noy=false
  local diffY=targetHotspot[1]-simDR_headY
  if diffY<-0.02 then
    if dY>0.1 then dY=0 simCMD_viewUP:stop()  end
    if dY>=0 then dY=-1 simCMD_viewDOWN:start()  end
  elseif diffY>0.02 then
     if dY<-0.1 then dY=0 simCMD_viewDOWN:stop()  end
     if dY<=0 then dY=1 simCMD_viewUP:start()  end
  else
    if dY>0.1 then dY=0 simCMD_viewUP:stop()  end
    if dY<-0.1 then dY=0 simCMD_viewDOWN:stop()  end
    noy=true
  end
  noz=false
  local diffZ=targetHotspot[2]-simDR_headZ
  if diffZ<-0.02 then
    if dZ>0.1 then dZ=0 simCMD_viewBACK:stop()  end
    if dZ>=0 then dZ=-1 simCMD_viewFWD:start()  end
  elseif diffZ>0.02 then
    if dZ<-0.1 then dZ=0 simCMD_viewFWD:stop()  end
    if dZ<=0 then dZ=1 simCMD_viewBACK:start()  end
  else
    if dZ>0.1 then dZ=0 simCMD_viewBACK:stop()  end
    if dZ<-0.1 then dZ=0 simCMD_viewFWD:stop()  end
    noz=true
  end

  if nox and noy and noz then
    movingtoTarget=false
  end
end
function useNavCOM(direction,phase, duration)
  logPage=0
 --print(phase.." use COM "..direction)
 if phase==0 then
 if direction>0 then
     nextCom:once()
  elseif direction<0 then
      prevCom:once()
  else
     swapCom:once()
  end
 end
end

simCMD_airspeed_down					= find_command("sim/autopilot/airspeed_down")
simCMD_airspeed_up					= find_command("sim/autopilot/airspeed_up")
simCMD_airspeed_press					= find_command("laminar/B747/button_switch/press_airspeed")

simCMD_heading_down					= find_command("sim/autopilot/heading_down")
simCMD_heading_up				= find_command("sim/autopilot/heading_up")
simCMD_heading_press					= find_command("laminar/B747/autopilot/button_switch/heading_select")

simCMD_altitude_down					= find_command("sim/autopilot/altitude_down")
simCMD_altitude_up					= find_command("sim/autopilot/altitude_up")
simCMD_altitude_press					= find_command("laminar/B747/button_switch/press_altitude")

simCMD_vs_down					= find_command("sim/autopilot/vertical_speed_down")
simCMD_vs_up					= find_command("sim/autopilot/vertical_speed_up")
simCMD_vs_press					= find_command("laminar/B747/autopilot/button_switch/vs_mode")

function useIAS(direction,phase, duration)
  --print(phase.." use useIAS "..direction)
  if phase==0 then
    if direction<0 then
      simCMD_airspeed_down:once()
     elseif direction>0 then
      simCMD_airspeed_up:once()
     else
      simCMD_airspeed_press:once()
     end
    elseif phase==2 and direction==0 then
      simCMD_airspeed_press:once()
    end
end
function useHDG(direction,phase, duration)
  --print(phase.." use useHDG "..direction)
  if phase==0 then
    if direction<0 then
      simCMD_heading_down:once()
     elseif direction>0 then
      simCMD_heading_up:once()
     else
      simCMD_heading_press:once()
     end

    end
end
function useAlt(direction,phase, duration)
  --print(phase.." use useAlt "..direction)
  if phase==0 then
    if direction<0 then
      simCMD_altitude_down:once()
     elseif direction>0 then
      simCMD_altitude_up:once()
     else
      simCMD_altitude_press:once()
     end
    elseif phase==2 and direction==0 then
      simCMD_altitude_press:once()
    end
end
function useVS(direction,phase, duration)
  --print(phase.." use useAlt "..direction)
  if phase==0 then
    if direction<0 then
      simCMD_vs_down:once()
     elseif direction>0 then
      simCMD_vs_up:once()
     else
      simCMD_vs_press:once()
     end
    end
end
local hotspots={{-0.166,4.53,-26.1612,useNavCOM,nil,nil}
,{-0.21,5.08,-26.38,useIAS,nil,nil}
,{-0.10,5.08,-26.38,useHDG,nil,nil}
,{-0.03,5.08,-26.38,useVS,nil,nil}
,{0.03,5.08,-26.38,useAlt,nil,nil}
}
--,{0.037,-0.201,-1.684,swapnav},{-0.037,-0.201,-1.684,swapcom}
function closest_intercept(x1,y1,z1,x2,y2,z2,psi,pitch)
    dx=x1 - x2;
    dy=y1 - y2;
    dz=z1 - z2;
    distance=math.sqrt(((dx*dx) + (dy*dy) + (dz*dz)));
    psiI=psi;



    pitchI=pitch;
    pdistance=math.cos(pitchI*math.pi/180.0)*distance;
    px=(-math.sin(psiI*math.pi/180.0))*pdistance;
    pz=math.cos(psiI*math.pi/180.0)*pdistance;
    py=(-math.sin(pitchI*math.pi/180.0))*distance;

    pdx=dx-px;
    pdy=dy-py;
    pdz=dz-pz;
    --print(distance.. " " .. pdx .. " " .. pdy .. " " .. pdz)
    loc=math.sqrt(((pdx*pdx) + (pdz*pdz) + (pdy*pdy)));
    return loc
end
function findHotSpot(dial)
  local bestDist=100
  local retVal=nil
  local psi=simDR_headpsi
  local pitch=simDR_headpitch
  if is_vr==1 then pitch=pitch-20 end
  for i = 1, #hotspots do
      local thisHit=closest_intercept(simDR_headX,simDR_headY,simDR_headZ,hotspots[i][1],hotspots[i][2],hotspots[i][3],psi,pitch)
      print(i.."="..closest_intercept(simDR_headX,simDR_headY,simDR_headZ,hotspots[i][1],hotspots[i][2],hotspots[i][3],psi,pitch))
      if thisHit< bestDist then

          local reFunc=nil
          if dial==0 then
              reFunc=hotspots[i][4]
          elseif dial==1 then
              reFunc=hotspots[i][5]
          else
              reFunc=hotspots[i][6]
          end
          if reFunc~=nil then
              retVal=reFunc
              bestDist= thisHit
          end
      end
  end
  return retVal
end

function VR_up_CMDhandler(phase, duration)
  local functionCall=findHotSpot(0)
  functionCall(1,phase, duration)
end

function VR_down_CMDhandler(phase, duration)
  local functionCall=findHotSpot(0)
  functionCall(-1,phase, duration)
end
function VR_use_CMDhandler(phase, duration)
  local functionCall=findHotSpot(0)
  functionCall(0,phase, duration)
end
B747CMD_VR_up 				= create_command("autoATC/VR/cmdup", "VR left command up", VR_up_CMDhandler)
B747CMD_VR_use 				= create_command("autoATC/VR/cmduse", "VR left command use", VR_use_CMDhandler)
B747CMD_VR_down 				= create_command("autoATC/VR/cmddown", "VR left command down", VR_down_CMDhandler)

function VR_up_right_CMDhandler(phase, duration)
  local functionCall=findHotSpot(1)
  functionCall(1,phase, duration)
end

function VR_down_right_CMDhandler(phase, duration)
  local functionCall=findHotSpot(1)
  functionCall(-1,phase, duration)
end
function VR_use_right_CMDhandler(phase, duration)
  local functionCall=findHotSpot(1)
  functionCall(0,phase, duration)
end
B747CMD_VR_up_right				= create_command("autoATC/VR/cmdup_right", "VR right command up", VR_up_right_CMDhandler)
B747CMD_VR_use_right 				= create_command("autoATC/VR/cmduse_right", "VR right command use", VR_use_right_CMDhandler)
B747CMD_VR_down_right 				= create_command("autoATC/VR/cmddown_right", "VR right command down", VR_down_right_CMDhandler)

function VR_up_key_CMDhandler(phase, duration)
  local functionCall=findHotSpot(2)
  functionCall(1,phase, duration)
end

function VR_down_key_CMDhandler(phase, duration)
  local functionCall=findHotSpot(2)
  functionCall(-1,phase, duration)
end
function VR_use_key_CMDhandler(phase, duration)
  local functionCall=findHotSpot(2)
  functionCall(0,phase, duration)
end
B747CMD_VR_up_right				= create_command("autoATC/VR/cmdup_key", "VR key command up", VR_up_key_CMDhandler)
B747CMD_VR_use_right 				= create_command("autoATC/VR/cmduse_key", "VR key command use", VR_use_key_CMDhandler)
B747CMD_VR_down_right 				= create_command("autoATC/VR/cmddown_key", "VR key command down", VR_down_key_CMDhandler)
