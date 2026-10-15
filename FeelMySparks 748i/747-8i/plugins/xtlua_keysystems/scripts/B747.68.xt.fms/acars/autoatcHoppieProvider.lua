


local hoppielogon=""

local file = io.open("Resources/plugins/AutoATC/hoppieid.txt", "r")
local started=false
if file ~= nil then
	io.input(file)
	hoppielogon = io.read()
	io.close(file)
end

local lastNetCheck=0
local lastNetPoll=0

function processHoppiePacket(packetMessage)
  --ok {LYBE cpdlc {/data2/6431/2/NE/LOGON ACCEPTED}}

end

function checkNet()
    local currentData=netRequestDataref
    local diff=(simDRTime-lastNetCheck)
    if diff<2 then return end
    print("current status="..netstatusDataref)
    lastNetCheck=simDRTime
    if netstatusDataref==200 then
      print("Got URL Data")
      print(currentData)
      processHoppiePacket(currentData)
      netdataDataref=" "
      netstatusDataref=0
    end

    -- peek
    --ok {9979886 BAW1234 cpdlc {/data2/1//N/SPARKY744 HOPPIE TEST}} {9979890 BAW1234 cpdlc {/data2/1//N/SPARKY744 HOPPIE TEST}} {9979897 BAW1234 cpdlc {/data2/2//N/NEW SPARKY744 HOPPIE TEST}} 
    -- ok {9979964 LYBE cpdlc {/data2/2//NE/LOGON ACCEPTED}}
    -- /data2/35/1/NE/LOGON ACCEPTED
    -- error {illegal logon code}
end

function checkPoll()
    local from=str_trim(getFMSData("fltno"))
    local to=str_trim(fmsModules["data"]["atc"])
    netstatusDataref=2
    netRequestDataref="{'url':'https://www.hoppie.nl/acars/system/connect.html?from="..from..
        "&type=POLL"..
        "&to="..to..
        "','logon':'"..hoppielogon.."'" ..
        "}"
end



acarsSystem.remote={
    receive=function()
        if netstatusDataref==nil then return end
        if netstatusDataref~=0 then
            checkNet()
        end
        if started then
            local diff=(simDRTime-lastNetPoll)
            if diff>75 then
                lastNetPoll=simDRTime
                checkPoll()
            end
        end
    end,
    send=function(msgJSON)
        if netstatusDataref==nil then return false end
        local newMessage=json.decode(msgJSON)
        local type=newMessage["type"]
        if type~="cpdlc" then return false end
        local from=str_trim(newMessage["from"])
        local to=str_trim(newMessage["to"])
        local mID=newMessage["messageID"]
        local replyTo=""
        if newMessage["RT"]~=nil then
          replyTo=newMessage["RT"]
        end
        local msg=newMessage["msg"]
        local requiresResponse=newMessage["RR"]
        local packet="/data2/"..mID.."/"..replyTo .."/"..requiresResponse .."/"..msg
        print("Sending hoppie packet "..packet .. " logon "..hoppielogon)
        netRequestDataref="{'url':'https://www.hoppie.nl/acars/system/connect.html?from="..from..
        "&type=cpdlc"..
        "&to="..to..
        "','packet':'"..packet..
        "','logon':'"..hoppielogon.."'" ..
        "}"
        lastNetPoll=simDRTime
        started=true
        return true
    end,
    isHoppie=function()
      return (string.len(hoppielogon)>0 and B747DR_acarsProvider==1)
    end
  }
