simDR_latitude=find_dataref("sim/flightmodel/position/latitude")
simDR_longitude=find_dataref("sim/flightmodel/position/longitude")
simDR_groundspeed=find_dataref("sim/flightmodel/position/groundspeed")
B747DR_iru_mode_sel_pos         = find_dataref("laminar/B747/flt_mgmt/iru/mode_sel_dial_pos")
startLat=0
startLon=0

irs={
  
  failed=false,
  aligned=false,
  latitude=0,
  longitude=0,
  gs=0,
  vs=0,
  heading=0,
  track=0,
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
   if self["aligned"] then return string.format("%02d",simDR_groundspeed)
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
irsC = {}
setmetatable(irsC, {__index = irs})
irsC["id"]="irsC"
irsR = {}
setmetatable(irsR, {__index = irs})
irsR["id"]="irsR"
gpsL = {}
setmetatable(gpsL, {__index = irs})
gpsL["aligned"]=true
gpsR = {}
setmetatable(gpsR, {__index = irs})
gpsR["aligned"]=true

irsSystem={}
irsSystem["aligned"]=false
irsSystem["aligning"]=false
irsSystem["motion"]={irsL=false,irsC=false,irsR=false}
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
irsSystem.update=function()
    if irsSystem[irsFromNum(B747DR_irs_src_capt)]["aligned"]==true then B747DR_pfd_mode_capt=1 else B747DR_pfd_mode_capt=0 end
    if irsSystem[irsFromNum(B747DR_irs_src_fo)]["aligned"]==true then B747DR_pfd_mode_fo=1 else B747DR_pfd_mode_fo=0 end
  
    
    if B747DR_iru_status[0]==1 and B747DR_iru_mode_sel_pos[0]==2 then B747DR_iru_status[0]=4 irsSystem.align("irsL",false)
    elseif B747DR_iru_status[0]==1 then
      irsSystem["irsL"]["aligned"]=false
    end
    if B747DR_iru_status[1]==1 and B747DR_iru_mode_sel_pos[1]==2 then B747DR_iru_status[1]=4 irsSystem.align("irsC",false) 
    elseif B747DR_iru_status[1]==1 then
      irsSystem["irsC"]["aligned"]=false
    end
    if B747DR_iru_status[2]==1 and B747DR_iru_mode_sel_pos[2]==2 then B747DR_iru_status[2]=4 irsSystem.align("irsR",false) 
    elseif B747DR_iru_status[2]==1 then
      irsSystem["irsR"]["aligned"]=false
    end
    
  if irsSystem["irsL"]["aligned"]==true and irsSystem["irsC"]["aligned"]==true and irsSystem["irsR"]["aligned"]==true then return end
  
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

irsSystem.getPos=function()
 return toDMS(simDR_latitude,true).." "..toDMS(simDR_longitude,false).. " "..string.format("%02d",simDR_groundspeed).."KT"
end
irsSystem.getLat=function(systemID)
 return irsSystem[systemID].getLat(irsSystem[systemID])
end
irsSystem.getLon=function(systemID)
 return irsSystem[systemID].getLon(irsSystem[systemID])
end
irsSystem.getLatPos=function()
 if irsSystem["irsL"]["aligned"]==true or irsSystem["irsC"]["aligned"]==true or irsSystem["irsR"]["aligned"]==true then return irsSystem["calcLatA"]() end
 return irsSystem["irsLat"]
end
irsSystem.getLonPos=function()
 if irsSystem["irsL"]["aligned"]==true or irsSystem["irsC"]["aligned"]==true or irsSystem["irsR"]["aligned"]==true then return irsSystem["calcLonA"]() end
 return irsSystem["irsLon"]
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
 if alignedIRS>1 then return toDMS((calcLat/alignedIRS),true) else return fmsModules["data"]["irsLat"] end
end
irsSystem.calcLonA=function()
 local alignedIRS=0
 local calcLon=0
 if irsSystem["irsL"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLon=calcLon+irsSystem.getLonD("irsL") end
 if irsSystem["irsC"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLon=calcLon+irsSystem.getLonD("irsC") end
 if irsSystem["irsR"]["aligned"]==true then alignedIRS=alignedIRS+1 calcLon=calcLon+irsSystem.getLonD("irsR") end
 if alignedIRS>1 then return toDMS((calcLon/alignedIRS),false) else return fmsModules["data"]["irsLon"] end
end
irsSystem.getGS=function(systemID)
 return irsSystem[systemID].getGS(irsSystem[systemID])
end
irsSystem.getLine=function(systemID)
 return irsSystem.getLat(systemID).." ".. irsSystem.getLon(systemID).. " "..irsSystem.getGS(systemID).."KT"
end
doIRSAlign={}
doIRSAlign["irsL"]=function()
  if irsSystem["irsL"].align(irsSystem["irsL"])==true then B747DR_iru_status[0]=2 end
  if irsSystem["irsL"]["aligned"]==true and irsSystem["irsC"]["aligned"]==true and irsSystem["irsR"]["aligned"]==true then irsSystem["aligned"]=true end 
end
doIRSAlign["irsC"]=function()
  if irsSystem["irsC"].align(irsSystem["irsC"])==true then B747DR_iru_status[1]=2 end
  if irsSystem["irsL"]["aligned"]==true and irsSystem["irsC"]["aligned"]==true and irsSystem["irsR"]["aligned"]==true then irsSystem["aligned"]=true end 
end
doIRSAlign["irsR"]=function()
  if irsSystem["irsR"].align(irsSystem["irsR"])==true then B747DR_iru_status[2]=2 end
  if irsSystem["irsL"]["aligned"]==true and irsSystem["irsC"]["aligned"]==true and irsSystem["irsR"]["aligned"]==true then irsSystem["aligned"]=true end 
end
irsSystem.align=function(systemID,instant)
  startLat=simDR_latitude
  startLon=simDR_longitude
  irsSystem[systemID]["aligned"]=false
  if instant==false and is_timer_scheduled(doIRSAlign[systemID]) == false then
        print("aligning "..systemID)
	irsSystem["motion"][systemID]=false
        run_after_time(doIRSAlign[systemID], 300.0)
  elseif instant==false then
        irsSystem["motion"][systemID]=false
  elseif instant==true then
    doIRSAlign[systemID]()   
  end
end