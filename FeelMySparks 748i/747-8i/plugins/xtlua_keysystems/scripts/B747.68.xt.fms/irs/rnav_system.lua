
local vor1=""
local vor2=""
local dme1=""
local dme2=""
 --[[local page={
    "        NAV RADIO       ",
    "                        ",
    string.format("%6.2f %4s  %4s %6.2f", simDR_radio_nav_freq_hz[2]*0.01, simDR_radio_nav03_ID, simDR_radio_nav04_ID, simDR_radio_nav_freq_hz[3]*0.01),
    string.format("                        ", ""),
    string.format(" %03d     %3s  %3s    %03d", simDR_radio_nav_obs_deg[2], "---", "---", simDR_radio_nav_obs_deg[3]),
    "                        ",
    string.format("%06.1f         %06.1f   ", simDR_radio_adf1_freq_hz, simDR_radio_adf2_freq_hz),
    "                        ",
    ils1,
    ils2,
    "                        ", 
    "--------         -------",
    fmsModules["data"]["preselectLeft"].."            "..fmsModules["data"]["preselectRight"],
    }]]
nSize=0
lastUpdate=0
local navAids
function B747_setNAVRAD()
    
    local diff=simDRTime-lastUpdate
    if diff<10 then return end
    
    --print("do RNAV" .. nSize)
    lastUpdate=simDRTime
    local lat=irsSystem.calcLatD()
    local lon=irsSystem.calcLonD()
    if lat<-180 or lon<-180 then return end
    local modes=B747DR_radioModes
    
    local vorL_mode=modes:sub(2, 2)
    local vorR_mode=modes:sub(3, 3)
    

    if vorL_mode=="A" and simDR_radio_nav_horizontal[2]==1 then simDR_radio_nav_obs_deg[2]=simDR_radio_nav_radial[2] end
    if vorR_mode=="A" and simDR_radio_nav_horizontal[3]==1 then simDR_radio_nav_obs_deg[3]=simDR_radio_nav_radial[3] end
    --local adfL_mode=modes:sub(4, 1)
    --local adfR_mode=modes:sub(5, 1)
    local vor1_closest=200
    local vor2_closest=200
    local dme1_closest=200
    local dme2_closest=200 
    local vor1_closest_index=-1
    local vor2_closest_index=-1
    local dme1_closest_index=-1
    local dme2_closest_index=-1
    
    if string.len(navAidsJSON) ~= nSize then
      navAids=json.decode(navAidsJSON)
      nSize=string.len(navAidsJSON)
     
    end
    if navAids==nil then return end
    for n=table.getn(navAids),1,-1 do
      if navAids[n][2] == 4 and navAids[n][3]>=10800 and navAids[n][3]<=11795 then
	local distance = getDistance(lat,lon,navAids[n][5],navAids[n][6])

	--print("navaid "..n.."->".. distance.."->"..navAids[n][1].." ".. navAids[n][2].." ".. navAids[n][3].." ".. navAids[n][4].." ".. navAids[n][5].." ".. navAids[n][6].." ".. navAids[n][7].." ".. navAids[n][8])
	
	if distance<vor1_closest then
	  vor2_closest=vor1_closest
	  vor2_closest_index=vor1_closest_index
	  vor1_closest=distance
	  vor1_closest_index=n
	end
      end
    end
    if vor1_closest_index>0 then
    n=vor1_closest_index
    if vorL_mode=="A" then
      simDR_radio_nav_freq_hz[2]=navAids[n][3]
    elseif vorR_mode=="A" then
      simDR_radio_nav_freq_hz[3]=navAids[n][3]
    end
   --print("VOR1 "..n.."->"..navAids[n][1].." ".. navAids[n][2].." ".. navAids[n][3].." ".. navAids[n][4].." ".. navAids[n][5].." ".. navAids[n][6].." ".. navAids[n][7].." ".. navAids[n][8])
    end
    if vor2_closest_index>0 then
   n=vor2_closest_index
    if vorL_mode=="A" and vorR_mode=="A" then
      simDR_radio_nav_freq_hz[3]=navAids[n][3]
    end
   --print("VOR2 "..n.."->"..navAids[n][1].." ".. navAids[n][2].." ".. navAids[n][3].." ".. navAids[n][4].." ".. navAids[n][5].." ".. navAids[n][6].." ".. navAids[n][7].." ".. navAids[n][8])
    end
end 
