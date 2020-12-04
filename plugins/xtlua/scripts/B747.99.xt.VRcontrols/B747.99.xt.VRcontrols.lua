function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end

simDR_headX=find_dataref("sim/graphics/view/pilots_head_x")
simDR_headY=find_dataref("sim/graphics/view/pilots_head_y")
simDR_headZ=find_dataref("sim/graphics/view/pilots_head_z")
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
pilotSeatHotspot[2]=-26.094387

fmcLHotspot={}
fmcLHotspot[0]=-0.240369
fmcLHotspot[1]=4.957494
fmcLHotspot[2]=-26.407701

mcpHotspot={}
mcpHotspot[0]=-0.059938
mcpHotspot[1]=5.153586
mcpHotspot[2]=-26.093819

ocpHotspot={}
ocpHotspot[0]=-0.059938
ocpHotspot[1]=5.153586
ocpHotspot[2]=-25.635084
movingtoTarget=false
targetHotspot=pilotSeatHotspot
local dX=0
local dY=0
local dZ=0
function killMoves()
  
--   if dX>0.1 then simCMD_viewRIGHT:stop() dX=0 end
--     if dX<-0.1 then simCMD_viewLEFT:stop() dX=0 end
--     if dY>0.1 then simCMD_viewUP:stop() dY=0 end
--     if dY<-0.1 then simCMD_viewDOWN:stop() dY=0 end
--     if dZ>0.1 then simCMD_viewBACK:stop() dZ=0 end 
--     if dZ<-0.1 then simCMD_viewFWD:stop() dZ=0 end
end
function B747CMD_VR_stop_CMDhandler(phase, duration)
--   if phase ==0 then
--     simCMD_viewRIGHT:stop()
--     simCMD_viewLEFT:stop()
--     simCMD_viewUP:stop()
--     simCMD_viewDOWN:stop()
--     simCMD_viewBACK:stop()
--     simCMD_viewFWD:stop()
--   end
end

function B747CMD_VR_toPilot_CMDhandler(phase, duration)
  if phase ==0 then
    targetHotspot=pilotSeatHotspot
    movingtoTarget=true
  elseif phase==2 then 
    movingtoTarget=false
    run_after_time(killMoves,0.05)
  end
end
function B747CMD_VR_toFMC_CMDhandler(phase, duration)
  if phase ==0 then
    targetHotspot=fmcLHotspot
    movingtoTarget=true
  elseif phase==2 then 
    movingtoTarget=false
    run_after_time(killMoves,0.05)
  end
end
function B747CMD_VR_toMCP_CMDhandler(phase, duration)
  if phase ==0 then
    targetHotspot=mcpHotspot
    movingtoTarget=true
  elseif phase==2 then 
    movingtoTarget=false
    run_after_time(killMoves,0.05)
  end
end
function B747CMD_VR_toOCP_CMDhandler(phase, duration)
  if phase ==0 then
    targetHotspot=ocpHotspot
    movingtoTarget=true
  elseif phase==2 then 
    movingtoTarget=false
    run_after_time(killMoves,0.05)
  end
end


B747CMD_VR_toPilot 				= deferred_command("laminar/B747/VR/pilotView", "Move to Pilot hotspot", B747CMD_VR_toPilot_CMDhandler)
B747CMD_VR_toFMC 				= deferred_command("laminar/B747/VR/fmcView", "Move to FMC hotspot", B747CMD_VR_toFMC_CMDhandler)
B747CMD_VR_toMCP 				= deferred_command("laminar/B747/VR/mcpView", "Move to MCP hotspot", B747CMD_VR_toMCP_CMDhandler)
B747CMD_VR_toOCP 				= deferred_command("laminar/B747/VR/ocpView", "Move to OCP hotspot", B747CMD_VR_toOCP_CMDhandler)
B747CMD_VR_stop 				= deferred_command("laminar/B747/VR/stopMove", "Stop move commands", B747CMD_VR_stop_CMDhandler)
local lastMoveUpdate=0
function after_physics()
  if movingtoTarget==false then 
    
    return 
  end
  local diff=simDRTime-lastMoveUpdate
  if diff<0.05 then return end --workaround XP bug with start/stop inside the same frame
  lastMoveUpdate=simDRTime
  
  
  local diffX=targetHotspot[0]-simDR_headX
  if diffX<-0.02 then 
    --if dX>0.1 then dX=0 simCMD_viewRIGHT:stop()  end
    --if dX>=0.1 then dX=-1 
    simCMD_viewLEFT:once()  
    --end
  elseif diffX>0.02 then
     --if dX<-0.1 then dX=0 simCMD_viewLEFT:stop()  end
     --if dX<=-0.1 then dX=1 
     simCMD_viewRIGHT:once()  
     --end
  --else
  --  if dX>0.1 then dX=0 simCMD_viewRIGHT:stop()  end
  --  if dX<-0.1 then dX=0 simCMD_viewLEFT:stop()  end
  end
  
  local diffY=targetHotspot[1]-simDR_headY
  if diffY<-0.02 then
    --if dY>0.1 then dY=0 simCMD_viewUP:stop()  end
    --if dY>=0.1 then dY=-1 
    simCMD_viewDOWN:once()  
    --end
  elseif diffY>0.02 then 
     --if dY<-0.1 then dY=0 simCMD_viewDOWN:stop()  end
     --if dY<=-0.1 then dY=1 
     simCMD_viewUP:once()  
      --end
  --else
   -- if dY>0.1 then dY=0 simCMD_viewUP:stop()  end
   -- if dY<-0.1 then dY=0 simCMD_viewDOWN:stop()  end
  end
  
  local diffZ=targetHotspot[2]-simDR_headZ
  if diffZ<-0.02 then 
    --if dZ>0.1 then dZ=0 simCMD_viewBACK:stop()  end
    --if dZ>=0 then dZ=-1 
    simCMD_viewFWD:once()  
    --end
  elseif diffZ>0.02 then 
    --if dZ<-0.1 then dZ=0 simCMD_viewFWD:stop()  end
    --if dZ<=0 then dZ=1 
    simCMD_viewBACK:once()  
  --end
  --else
  --  if dZ>0.1 then dZ=0 simCMD_viewBACK:stop()  end
  --  if dZ<-0.1 then dZ=0 simCMD_viewFWD:stop()  end
  end
end