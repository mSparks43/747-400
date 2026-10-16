



--Random unused code used to dev hoppie
function netTest(phase, duration)
    if phase == 0 then
        if netstatusDataref==nil then return end
        if string.len(hoppielogon)==0 then return end
        print("Do netTest")
        netstatusDataref=2
        lastNetPoll=simDRTime
        local from="BAW1234"
        local to="LYBE"
        local packet="/data2/1//Y/REQUEST LOGON"
        netRequestDataref="{'url':'https://www.hoppie.nl/acars/system/connect.html?from="..from..
        "&type=cpdlc"..
        "&to="..to..
        "','packet':'"..packet..
        "','logon':'"..hoppielogon.."'" ..
        "}"
        started=true
    end
  end
  B747CMD_netTest  = deferred_command("laminar/B747/networking/nettest", "Networking Test", netTest)