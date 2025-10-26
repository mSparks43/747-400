-- test.lua
-- scratchpad for testing lua code
dofile("plugins/xtlua/scripts/B747.05.xt.simconfig/json/json.lua")
local fmsJSON='[[16802564,1,0,351.0,37.47017288208008,126.45240020751953,"Seoul Incheon","RKSI",20,false],[-1,2048,0,0,37.44341278076172,126.44172668457031,"latlon","latlon",-91,false],[33691662,512,0,351.0,37.472808837890625,126.41557312011719,"DER34R","DE34R",328,false],[33691801,512,0,351.0,37.503692626953125,126.36880493164063,"YD020","YD020",2562,false],[33691802,512,0,351.0,37.50822067260742,126.1824722290039,"YD040","YD040",7084,false],[33691803,512,0,351.0,37.408721923828125,126.13583374023438,"YD070","YD070",10613,false],[33691804,512,0,351.0,37.32638931274414,126.25389099121094,"YD100","YD100",15031,false],[33691809,512,0,351.0,37.32461166381836,126.4586410522461,"YK130","YK130",19559,false],[33691810,512,0,351.0,37.32172393798828,126.71077728271484,"YK170","YK170",23555,false],[33691811,512,0,351.0,37.318138122558594,127.00872039794922,"YK210","YK210",25854,false],[33683670,512,0,351.0,37.4874153137207,127.3794174194336,"EGOBA","EGOBA",28848,false],[33684450,512,0,351.0,37.53305435180664,127.66444396972656,"KARBU","KARBU",30836,false],[33686182,512,0,351.0,37.6069450378418,128.13528442382813,"TORUS","TORUS",32938,false],[33683180,512,0,351.0,37.67555618286133,128.58444213867188,"BIKSI","BIKSI",34385,false],[5683,4,11560,351.0,37.70077896118164,128.7537841796875,"GANGWON VORTAC","KAE",34581,false],[33685482,512,0,351.0,37.44194412231445,129.2919464111328,"PILIT","PILIT",35000,false],[33683796,512,0,351.0,37.170555114746094,129.84750366210938,"ESNEG","ESNEG",34998,false],[33682821,512,0,351.0,36.75583267211914,130.67889404296875,"AGSUS","AGSUS",35000,true],[33684611,512,0,351.0,36.37323760986328,131.42831420898438,"LANAT","LANAT",35000,false],[33683562,512,0,351.0,36.28166580200195,133.76101684570313,"DISSH","DISSH",35000,false],[33685374,512,0,351.0,36.26515197753906,134.08819580078125,"OVSOS","OVSOS",35000,false],[33685754,512,0,351.0,36.242897033691406,134.50332641601563,"SAMON","SAMON",35000,false],[33686540,512,0,351.0,36.630523681640625,136.94981384277344,"ZUWAI","ZUWAI",35000,false],[33685354,512,0,351.0,36.790199279785156,138.09304809570313,"OTARI","OTARI",35000,false],[33684026,512,0,351.0,36.84299087524414,138.4791717529297,"HAKKA","HAKKA",35000,false],[33684228,512,0,351.0,36.920658111572266,139.07525634765625,"IKAHO","IKAHO",35000,false],[33684836,512,0,351.0,36.97356033325195,139.48484802246094,"MAUKA","MAUKA",35000,false],[33686468,512,0,351.0,37.012969970703125,139.79776000976563,"YAGAN","YAGAN",35000,false],[33686001,512,0,351.0,37.038490295410156,140.00392150878906,"SYOEN","SYOEN",35000,false],[33684707,512,0,351.0,37.06764602661133,140.24343872070313,"LIVET","LIVET",35000,false],[33683787,512,0,351.0,37.10976028442383,140.5970458984375,"ESKAS","ESKAS",35000,false],[33683760,512,0,351.0,36.99357986450195,140.79490661621094,"ENTAK","ENTAK",34460,false],[33683998,512,0,351.0,36.554561614990234,140.62680053710938,"GURIP","GURIP",26389,false],[33685994,512,0,351.0,36.3206787109375,140.53805541992188,"SWAMP","SWAMP",22107,false],[-1,0,0,0,36.3206787109375,140.53805541992188,"latlon","latlon",20845,false],[33685994,512,0,351.0,36.3206787109375,140.53805541992188,"SWAMP","SWAMP",20845,false],[33687800,512,0,351.0,36.226646423339844,140.66310119628906,"VIXEN","VIXEN",18711,false],[33687778,512,0,351.0,36.1263427734375,140.7959442138672,"PLEIA","PLEIA",16249,false],[33687765,512,0,351.0,36.042236328125,140.8332061767578,"MIFFY","MIFFY",14774,false],[33687752,512,0,351.0,35.845237731933594,140.9201202392578,"KARMA","KARMA",11326,false],[33687797,512,0,351.0,35.75382614135742,140.96029663085938,"UNARI","UNARI",10498,false],[33687717,512,0,351.0,35.6416015625,140.86080932617188,"CORGI","CORGI",9619,false],[33687735,512,0,351.0,35.524776458740234,140.7576141357422,"ELGAR","ELGAR",7098,false],[-1,0,0,0,35.52363586425781,140.6536865234375,"latlon","latlon",5672,false],[33687740,512,0,351.0,35.522403717041016,140.5497589111328,"GIINA","GIINA",4000,false],[33683408,512,0,351.0,35.5767822265625,140.51072692871094,"COSMO","COSMO",4000,false],[-1,2048,0,0,35.74332046508789,140.39073181152344,"latlon","latlon",197,false],[-1,0,0,0,35.76495361328125,140.37486267089844,"latlon","latlon",1000,false],[-1,0,0,0,35.748817443847656,140.3674774169922,"latlon","latlon",0,false],[33687744,512,0,351.0,35.546939849853516,140.3671417236328,"GUMYO","GUMYO",6000,false],[-1,0,0,0,35.43422317504883,140.44931030273438,"latlon","latlon",6000,false],[33687729,512,0,351.0,35.40609359741211,140.59735107421875,"NRE160025","D160Y",6000,false],[33683190,512,0,351.0,35.187862396240234,140.73240661621094,"BINKS","BINKS",6000,false],[33683190,512,0,351.0,35.187862396240234,140.73240661621094,"BINKS","BINKS",6000,false],[16797100,1,0,351.0,35.75886535644531,140.37948608398438,"Narita Intl","RJAA",132,false]]'


local fmsSTR = fmsJSON
local fmsO = json.decode(fmsSTR)
B747DR_fmscurrentIndex=-1
print(#fmsO)
function B747_getCurrentWayPoint(fms)
	--[[ for i=1,table.getn(fms),1 do
    if fms[i][10]==true and i<=getVNAVState("recalcAfter") then
      --print("simDR_autopilot_altitude_ft=".. simDR_autopilot_altitude_ft)
      return
    end
  end]]
	for i = 1, #fms, 1 do
		--print("FMS j="..fmsJSON)
    print(fms[i][10])
		if fms[i][10] == true then
			B747DR_fmscurrentIndex = i

			--setVNAVState("recalcAfter", i)
			break
		end
	end
end
B747_getCurrentWayPoint(fmsO)
print(B747DR_fmscurrentIndex)

local endI =#fmsO
function getDistance(lat1,lon1,lat2,lon2)
  alat=math.rad(lat1)
  alon=math.rad(lon1)
  blat=math.rad(lat2)
  blon=math.rad(lon2)
  av=math.sin(alat)*math.sin(blat) + math.cos(alat)*math.cos(blat)*math.cos(blon-alon)
  if av > 1 then av=1 end
  retVal=math.acos(av) * 3440
  --print(lat1.." "..lon1.." "..lat2.." "..lon2)
  --print("Distance = "..retVal) 
  return retVal
end

local start = B747DR_fmscurrentIndex
local LastLeg = getDistance(fmsO[start-1][5], fmsO[start-1][6], fmsO[start][5], fmsO[start][6])

local todDist = 45
local eLat = fmsO[start][5]
	local eLong = fmsO[start][6]
	local totalDistance = LastLeg
	local nextDistanceInFeet = totalDistance * 6076.12

	local eod = endI
	local setTOD = false
	local setTOC = false
	--local todDist = B747BR_totalDistance - B747BR_tod
	local vnavData={}
	local vnavI=1
	local lastVnavAlt=-9999

	if start == 0 then
		start = 1
	end
for i = 1, endI - 1, 1 do
		if i >= start then
			iLat = fmsO[i][5]
			iLong = fmsO[i][6]
			eLat = fmsO[i + 1][5]
			eLong = fmsO[i + 1][6]
			LastLeg = getDistance(fmsO[i][5], fmsO[i][6], fmsO[i + 1][5], fmsO[i + 1][6])
			totalDistance = totalDistance + LastLeg
		end

		--[[if totalDistance > todDist and setTOD == false and B747BR_totalDistance > 0 and todDist > 0 then
			setTOD = true
			--interpolate last leg
			local backingDist = totalDistance - todDist
			local legFrac = (LastLeg - backingDist) / LastLeg
			if legFrac >= 0 and legFrac <= 1 and totalDistance - LastLeg < todDist then
				B747BR_todLat = iLat + (eLat - iLat) * legFrac
				B747BR_todLong = iLong + (eLong - iLong) * legFrac
			end
		end
		if B747BR_toc>=0 and totalDistance > B747BR_toc and setTOC == false and B747BR_totalDistance > 0 then
			setTOC = true
			local backingDist = totalDistance - B747BR_toc
			local legFrac = (LastLeg - backingDist) / LastLeg
			if legFrac >= 0 and legFrac <= 1 and totalDistance - LastLeg < B747BR_toc then
				B747BR_tocLat = iLat + (eLat - iLat) * legFrac
				B747BR_tocLong = iLong + (eLong - iLong) * legFrac
			end
		end]]--
		--print("setVNAV "..i.." "..fmsO[i][5]..":"..fmsO[i][6].."/"..fmsO[i][9])
		dtoAirport = getDistance(fmsO[i][5], fmsO[i][6], fmsO[endI][5], fmsO[endI][6])
		--print("i=".. i .." B747DR_fmscurrentIndex="..B747DR_fmscurrentIndex .." speed="..simDR_groundspeed .. " distance="..totalDistance.." dtoAirport="..dtoAirport.. " ".. fmsO[i][5].." ".. fmsO[i][6].." ".. fmsO[i+1][5].." ".. fmsO[i+1][6])
		if dtoAirport < 10 then
			eod = i
			--print("end fms"..i.."=at alt "..fms[i][3])
			break
		end
		if fmsO[i][9]>0 then
			--construct vnav profile
			local isNext="false"
			if i==start then
				isNext="true"
			end
			if fmsO[i][9]~=lastVnavAlt or i==start then
				local vAlt=0
        local tAlt=fmsO[i][9]
				if i>1 then
					local distance=getDistance(fmsO[i-1][5],fmsO[i-1][6], fmsO[i][5],fmsO[i][6])
          if distance>0.1 then
					  vAlt=(lastVnavAlt-fmsO[i][9])/distance
          else
            vAlt=0
            tAlt=lastVnavAlt
          end
				end
				local vNavdataI={fmsO[i][5],fmsO[i][6],tAlt,i==start,vAlt}
				vnavData[vnavI]=vNavdataI
				vnavI=vnavI+1
				lastVnavAlt=tAlt
				--print("setVNAV "..i.." "..fmsO[i][5]..":"..fmsO[i][6].."/"..fmsO[i][9].." "..vAlt)
			end
		end
	end
	local vAlt=0
	if lastVnavAlt>0 then
		local distance=getDistance(vnavData[vnavI-1][1],vnavData[vnavI-1][2], fmsO[endI][5],fmsO[endI][6])
		vAlt=(lastVnavAlt-fmsO[endI][9])/distance
	end
	local vNavdataI={fmsO[endI][5],fmsO[endI][6],fmsO[endI][9],endI==start,vAlt}
	vnavData[vnavI]=vNavdataI
	B747BR_vnavProfile = json.encode(vnavData)


--[[function str_trim(s)
	return string.match(s,'^()%s*$') and '' or string.match(s,'^%s*(.*%S)')
end
noPages=math.ceil(7/7)
print(noPages)
function convertToFMSLines(msg)
    local retVal={}
    local line=1
    local start=1
    local endI=string.len(msg)
    while start<endI do
      local cLine=string.sub(msg,start,start+24)
      local index = string.find(cLine, " [^ ]*$")
      if index~=nil and index > 10 then
        cLine=string.sub(msg,start,start+index-1)
        local atindex = string.find(cLine, "@")
        if atindex~=nil then
            cLine=string.sub(msg,start,start+atindex-2)
            start=start+atindex
        else
            start=start+index
        end
        retVal[line]=str_trim(cLine)
        line=line+1
      else
        local atindex = string.find(cLine, "@")
        if atindex~=nil then
            cLine=string.sub(msg,start,start+atindex-2)
            start=start+atindex
        else
            start=start+24
        end    
        retVal[line]=str_trim(cLine)
        if string.len(retVal[line])>0 then
            line=line+1
        end
      end
    end
    return retVal
  end
  --local testMSG=convertToFMSLines("The quick brown @fo@x jumped over the lazy @dog@ Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
  
  local testMSG=convertToFMSLines(nil)
  for i=1,#testMSG,1 do
    print(testMSG[i])
  end


noPages=math.ceil(8/7)
print(noPages)]]--