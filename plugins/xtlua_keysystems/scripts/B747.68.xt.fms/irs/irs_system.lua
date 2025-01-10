
simDR_groundspeed=find_dataref("sim/flightmodel/position/groundspeed")
B747DR_iru_mode_sel_pos         = find_dataref("laminar/B747/flt_mgmt/iru/mode_sel_dial_pos")
local timeToAlign=600
irs_A_status=find_dataref("laminar/B747/irs/line1") 
irs_L_status=find_dataref("laminar/B747/irs/line2") 
irs_C_status=find_dataref("laminar/B747/irs/line3") 
irs_R_status=find_dataref("laminar/B747/irs/line4") 
local allIRSOff=true

local startLat=0
local startLon=0

--IRS ND DISPLAY
B747DR_ND_IRS_Line	= deferred_dataref("laminar/B747/irs/irs_display_line", "string")


irs={
  index=0,
  failed=false,
  aligned=false,
  latitude=0,
  longitude=0,
  gs=0,
  vs=0,
  heading=0,
  track=0,
  alignStarted=0,
  getLat=function(self)
   if self["aligned"] then return toDMS(simDR_latitude+self["latitude"],true)
   else return "***`**.*" end
  end,
  getLon=function(self)
   if self["aligned"] then return toDMS(simDR_longitude+self["longitude"],false) 
   else return "***`**.*" end
  end,
  getLatD=function(self)
   if self["aligned"] then return simDR_latitude+self["latitude"]
   else return 0 end
  end,
  getLonD=function(self)
   if self["aligned"] then return simDR_longitude+self["longitude"] 
   else return 0 end
  end,
  getGS=function(self)
   if self["aligned"] then return string.format("%02d",simDR_groundspeed/0.514444)
   else return "**" end
  end,
  align=function(self)
   self["latitude"]=(math.random()-0.5)/500
   print(self["latitude"])
   self["longitude"]=(math.random()-0.5)/500
   difLat=simDR_latitude-startLat
   difLon=simDR_longitude-startLon
   if difLat<0.0001 and difLat>-0.0001 and difLon<0.0001 and difLon>-0.0001 then
   self["aligned"]=true
   print("aligned an irs")
     return true
   else
     irsSystem["motion"][self["id"]]=true
     return false
   end
  end
}

irsL = {}
setmetatable(irsL, {__index = irs})
irsL["id"]="irsL"
irsL["index"]=0
irsC = {}
setmetatable(irsC, {__index = irs})
irsC["id"]="irsC"
irsC["index"]=1
irsR = {}
setmetatable(irsR, {__index = irs})
irsR["id"]="irsR"
irsR["index"]=2
gpsL = {}
setmetatable(gpsL, {__index = irs})
gpsL["aligned"]=true
gpsR = {}
setmetatable(gpsR, {__index = irs})
gpsR["aligned"]=true

irsSystem={}
irsSystem["motion"]={irsL=false,irsC=false,irsR=false}
irsSystem["setPos"]=false
irsSystem["irsL"]=irsL
irsSystem["irsC"]=irsC
irsSystem["irsR"]=irsR
irsSystem["irsLat"]=fmsModules["data"]["irsLat"]
irsSystem["irsLon"]=fmsModules["data"]["irsLon"]
irsSystem["gpsL"]=gpsL
irsSystem["gpsR"]=gpsR

function irsFromNum(num)
  if num==0 then return "irsL" end
  if num==1 then return "irsC" end
  return "irsR"
end

function irs_notify()
--   fmsModules["fmsL"].notify="ENTER IRS POSITION"
--   fmsModules["fmsC"].notify="ENTER IRS POSITION"
--   fmsModules["fmsR"].notify="ENTER IRS POSITION"
  B747DR_fmc_notifications[12]=1
end
doIRSAlign={}
doIRSAlign["irsL"]=function()
  if irsSystem["irsL"].align(irsSystem["irsL"])==true then B747DR_iru_status[0]=2 end
  if irsSystem["setPos"]==false and irsSystem["irsL"]["aligned"]==true and irsSystem["irsC"]["aligned"]==true and irsSystem["irsR"]["aligned"]==true then 
    irs_notify()
  end 
end
doIRSAlign["irsC"]=function()
  if irsSystem["irsC"].align(irsSystem["irsC"])==true then B747DR_iru_status[1]=2 end
  if irsSystem["setPos"]==false and irsSystem["irsL"]["aligned"]==true and irsSystem["irsC"]["aligned"]==true and irsSystem["irsR"]["aligned"]==true then 
     irs_notify()
  end 
end
doIRSAlign["irsR"]=function()
  if irsSystem["irsR"].align(irsSystem["irsR"])==true then B747DR_iru_status[2]=2 end
  if irsSystem["setPos"]==false and irsSystem["irsL"]["aligned"]==true and irsSystem["irsC"]["aligned"]==true and irsSystem["irsR"]["aligned"]==true then 
     irs_notify()
  end 
end
function cancelAlign(func)
  if is_timer_scheduled(func) == true then
    stop_timer(func)
  end
end
irsSystem.setStatus=function()
  local L_status=irsSystem.getStatus("irsL")
  local C_status=irsSystem.getStatus("irsC")
  local R_status=irsSystem.getStatus("irsR")

  if string.sub(L_status,-3)=="OFF" and string.sub(C_status,-3)=="OFF"  and string.sub(R_status,-3)=="OFF" then
    irs_A_status=" "
    irs_L_status=" "
    irs_C_status=" "
    irs_R_status=" "
  else
    irs_A_status="TIME TO ALIGN"
    irs_L_status=L_status
    irs_C_status=C_status
    irs_R_status=R_status
  end
end

irsSystem.off=function()
  irsSystem.setStatus()
    
    irsSystem["irsL"]["aligned"] = false
    irsSystem["irsC"]["aligned"] = false
    irsSystem["irsR"]["aligned"] = false
end

irsSystem.update=function()
  
  
  if B747DR_iru_status[0]==0 then 
    irsSystem["irsL"]["aligned"] = false 
  elseif B747DR_iru_status[0]==2 and irsSystem["motion"]["irsL"]==false and irsSystem["setPos"]==true then
    --irsSystem["irsL"]["aligned"] = true
    irsL.align(irsL)
  end
  if B747DR_iru_status[1]==0 then 
    irsSystem["irsC"]["aligned"] = false 
  elseif B747DR_iru_status[1]==2 and irsSystem["motion"]["irsC"]==false and irsSystem["setPos"]==true then
    irsC.align(irsC)
  end
  if B747DR_iru_status[2]==0 then 
    irsSystem["irsR"]["aligned"] = false 
  elseif B747DR_iru_status[2]==2 and irsSystem["motion"]["irsR"]==false and irsSystem["setPos"]==true then
    irsR.align(irsR)
  end

  --Marauder28
  --GPS/IRS DISPLAY
  if irsSystem["irsL"]["aligned"] == true and irsSystem["irsC"]["aligned"] == true and irsSystem["irsR"]["aligned"] == true then
    B747DR_ND_IRS_Line = "IRS (3)"
  elseif irsSystem["irsL"]["aligned"] == true then
	  B747DR_ND_IRS_Line = "IRS (L)"
  elseif irsSystem["irsC"]["aligned"] == true then
	  B747DR_ND_IRS_Line = "IRS (C)"
  elseif irsSystem["irsR"]["aligned"] == true then
	  B747DR_ND_IRS_Line = "IRS (R)"
  else
    B747DR_ND_GPS_Line = "GPS"
  end

  --Update Set Hdg on FMC
  if (B747DR_iru_mode_sel_pos[0] == 3 or B747DR_iru_mode_sel_pos[1] == 3 or B747DR_iru_mode_sel_pos[2] == 3) then
	if tonumber(string.sub(fmsModules["data"].sethdg,1,3)) ~= nil then
		local diff = simDRTime - timer_start
		if diff < 2 then  --Display for 2 seconds
			return
		end	
		timer_start = simDRTime
	end
	fmsModules["data"].sethdg = "---`"
  else
	fmsModules["data"].sethdg = defaultFMSData().sethdg
  end
  --Marauder28
  
  
  
    if irsSystem["setPos"]==true and irsSystem[irsFromNum(B747DR_irs_src_capt)]["aligned"]==true then B747DR_pfd_mode_capt=1 else B747DR_pfd_mode_capt=0 end
    if irsSystem["setPos"]==true and irsSystem[irsFromNum(B747DR_irs_src_fo)]["aligned"]==true then B747DR_pfd_mode_fo=1 else B747DR_pfd_mode_fo=0 end
    
    if irsSystem[irsFromNum(B747DR_irs_src_capt)]["aligned"]==false or irsSystem[irsFromNum(B747DR_irs_src_fo)]["aligned"]==false or irsSystem["setPos"]==false then
      irsSystem.setStatus()
    end
    if B747DR_iru_mode_sel_pos[0]==0 then B747DR_iru_status[0]=0 cancelAlign(doIRSAlign["irsL"])
    elseif B747DR_iru_status[0]==1 and B747DR_iru_mode_sel_pos[0]==2 then B747DR_iru_status[0]=4 irsSystem.align("irsL",false)
    elseif B747DR_iru_status[0]==1 then
      irsSystem["irsL"]["aligned"]=false
      cancelAlign(doIRSAlign["irsL"])
    end
    if B747DR_iru_mode_sel_pos[1]==0 then B747DR_iru_status[1]=0 cancelAlign(doIRSAlign["irsC"])
    elseif B747DR_iru_status[1]==1 and B747DR_iru_mode_sel_pos[1]==2 then B747DR_iru_status[1]=4 irsSystem.align("irsC",false) 
    elseif B747DR_iru_status[1]==1 then
      irsSystem["irsC"]["aligned"]=false
      cancelAlign(doIRSAlign["irsC"])
    end
    if B747DR_iru_mode_sel_pos[2]==0 then B747DR_iru_status[2]=0 cancelAlign(doIRSAlign["irsR"])
    elseif B747DR_iru_status[2]==1 and B747DR_iru_mode_sel_pos[2]==2 then B747DR_iru_status[2]=4 irsSystem.align("irsR",false) 
    elseif B747DR_iru_status[2]==1 then
      irsSystem["irsR"]["aligned"]=false
      cancelAlign(doIRSAlign["irsR"])
    end
  if  B747DR_iru_status[0]==4 then B747DR_CAS_memo_status[14]=1 else B747DR_CAS_memo_status[14]=0 end
  if  B747DR_iru_status[1]==4 then B747DR_CAS_memo_status[15]=1 else B747DR_CAS_memo_status[15]=0 end
  if  B747DR_iru_status[2]==4 then B747DR_CAS_memo_status[16]=1 else B747DR_CAS_memo_status[16]=0 end 
  
  if irsSystem["irsL"]["aligned"]==true and 
      irsSystem["irsC"]["aligned"]==true and 
      irsSystem["irsR"]["aligned"]==true then 
        return 
  end
  
  if irsSystem["motion"]["irsL"]==true or irsSystem["motion"]["irsC"]==true or irsSystem["motion"]["irsR"]==true then 
    B747DR_CAS_advisory_status[233] = 1   
  else
    B747DR_CAS_advisory_status[233] = 0
  end
    
  
  difLat=simDR_latitude-startLat
  difLon=simDR_longitude-startLon
  if irsSystem["irsL"]["aligned"]==false and B747DR_iru_mode_sel_pos[0]==2 and (difLat>0.0001 or difLat<-0.0001 or difLon>0.0001 or difLon<-0.0001) then
    irsSystem["motion"]["irsL"]=true
  end 
  if irsSystem["irsC"]["aligned"]==false and B747DR_iru_mode_sel_pos[1]==2 and (difLat>0.0001 or difLat<-0.0001 or difLon>0.0001 or difLon<-0.0001) then
    irsSystem["motion"]["irsC"]=true
  end  
  if irsSystem["irsR"]["aligned"]==false and B747DR_iru_mode_sel_pos[2]==2 and (difLat>0.0001 or difLat<-0.0001 or difLon>0.0001 or difLon<-0.0001) then
    irsSystem["motion"]["irsR"]=true
  end  
end
function timeToAlignString(time)
  local min=(timeToAlign/60)-((simDRTime-time)/60)
  if min>7 then return " 7+" end 
  
  return string.format(" %1d",min+1)
end
irsSystem.getStatus=function(systemID)
  if irsSystem["motion"][systemID]==true then return systemID:sub(4, 4).." MOTION" end
  if B747DR_iru_status[irsSystem[systemID]["index"]]==0 then return systemID:sub(4, 4).." OFF" end
  if B747DR_iru_status[irsSystem[systemID]["index"]]==1 then return systemID:sub(4, 4).." ALIGN" end
  if B747DR_iru_status[irsSystem[systemID]["index"]]==2 then return systemID:sub(4, 4).." ALIGNED" end
  if B747DR_iru_status[irsSystem[systemID]["index"]]==4 then return systemID:sub(4, 4).. timeToAlignString(irsSystem[systemID]["alignStarted"]) .. " MIN" end
end
irsSystem.getPos=function()
 return toDMS(simDR_latitude,true).." "..toDMS(simDR_longitude,false).. " "..string.format("%02d",simDR_groundspeed).."KT"
end
irsSystem.getLat=function(systemID)
 return irsSystem[systemID].getLat(irsSystem[systemID])
end
irsSystem.getLon=function(systemID)
 return irsSystem[systemID].getLon(irsSystem[systemID])
end
irsSystem.getInitLatPos=function()
 if B747DR_iru_status[0]==4 or B747DR_iru_status[1]==4 or B747DR_iru_status[2]==4 or irsSystem["setPos"]==false then
  return fmsModules["data"]["initIRSLat"]
 end
 return "         " 
end
irsSystem.getInitLonPos=function()
 if B747DR_iru_status[0]==4 or B747DR_iru_status[1]==4 or B747DR_iru_status[2]==4 or irsSystem["setPos"]==false then
  return fmsModules["data"]["initIRSLon"]
 end
 return "         " 
end
irsSystem.getLatD=function(systemID)
 return irsSystem[systemID].getLatD(irsSystem[systemID])
end
irsSystem.getLonD=function(systemID)
 return irsSystem[systemID].getLonD(irsSystem[systemID])
end
irsSystem.calcLatA=function()
 --should use the closest two, but meh
 local alignedIRS=0
 local calcLat=0
 if irsSystem["irsL"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLat=calcLat+irsSystem.getLatD("irsL") end
 if irsSystem["irsC"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLat=calcLat+irsSystem.getLatD("irsC") end
 if irsSystem["irsR"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLat=calcLat+irsSystem.getLatD("irsR") end
 if alignedIRS>1 and irsSystem["setPos"]==true then return toDMS((calcLat/alignedIRS),true) else return fmsModules["data"]["irsLat"] end
end
irsSystem.calcLonA=function()
 local alignedIRS=0
 local calcLon=0
 if irsSystem["irsL"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLon=calcLon+irsSystem.getLonD("irsL") end
 if irsSystem["irsC"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLon=calcLon+irsSystem.getLonD("irsC") end
 if irsSystem["irsR"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLon=calcLon+irsSystem.getLonD("irsR") end
 if alignedIRS>1 and irsSystem["setPos"]==true then return toDMS((calcLon/alignedIRS),false) else return fmsModules["data"]["irsLon"] end
end
irsSystem.calcLatD=function()
 --should use the closest two, but meh
 local alignedIRS=0
 local calcLat=0
 if irsSystem["irsL"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLat=calcLat+irsSystem.getLatD("irsL") end
 if irsSystem["irsC"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLat=calcLat+irsSystem.getLatD("irsC") end
 if irsSystem["irsR"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLat=calcLat+irsSystem.getLatD("irsR") end
 if alignedIRS>1 then return (calcLat/alignedIRS) else return -9999 end
end
irsSystem.calcLonD=function()
 local alignedIRS=0
 local calcLon=0
 if irsSystem["irsL"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLon=calcLon+irsSystem.getLonD("irsL") end
 if irsSystem["irsC"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLon=calcLon+irsSystem.getLonD("irsC") end
 if irsSystem["irsR"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLon=calcLon+irsSystem.getLonD("irsR") end
 if alignedIRS>1 then return (calcLon/alignedIRS) else return -9999 end
end


irsSystem.getGS=function(systemID)
 return irsSystem[systemID].getGS(irsSystem[systemID])
end
irsSystem.getLine=function(systemID)
 return irsSystem.getLat(systemID).." ".. irsSystem.getLon(systemID).. " "..irsSystem.getGS(systemID).."KT"
end

irsSystem.align=function(systemID,instant)
	--Simulator Config Options
  if hasSimConfig()==true then 
	  timeToAlign=simConfigData["data"].SIM.irs_align_time
  end
  startLat=simDR_latitude
  startLon=simDR_longitude
  irsSystem[systemID]["aligned"]=false
  if instant==false and is_timer_scheduled(doIRSAlign[systemID]) == false then
        print("aligning "..systemID)
	    irsSystem["motion"][systemID]=false
	    irsSystem[systemID]["alignStarted"]=simDRTime
        run_after_time(doIRSAlign[systemID], timeToAlign)
  elseif instant==false then
        irsSystem["motion"][systemID]=false
  elseif instant==true then
    irsSystem["motion"][systemID]=false  
    doIRSAlign[systemID]() 
    
  end
end