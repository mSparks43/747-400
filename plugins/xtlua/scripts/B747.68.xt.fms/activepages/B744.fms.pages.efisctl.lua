registerFMCCommand("laminar/B747/efis/dh/capt/reset_switch","")
fmsPages["EFISCTL152"]=createPage("EFISCTL152")
fmsPages["EFISCTL152"].getPage=function(self,pgNo,fmsID)

    local mapMode=simDR_nd_mode_dial_capt
    local mapCenter=simDR_nd_center_dial_capt
    local baro=simDR_altimeter_baro_inHg
    local baroString=""
    if fmsID=="fmsR" then 
        mapMode=simDR_nd_mode_dial_fo 
        mapCenter=simDR_nd_center_dial_fo
        baro=simDR_altimeter_baro_inHg_fo
        if B747DR_efis_baro_ref_fo_sel_dial_pos==1 then 
            baro=baro*33.863892
            baroString=" "..string.format("%04d",baro) 
        else
            baroString=string.format("%02.2f",baro) 
        end

    elseif  B747DR_efis_baro_ref_capt_sel_dial_pos ==1 then 
        baro=baro*33.863892  
        baroString=" "..string.format("%04d",baro) 
    else
        baroString=string.format("%02.2f",baro) 
    end

    local mapSelected="     "
    local plnSelected="     "
    local appSelected="     "
    local vorSelected="     "
    local ctrSelected="     "

    if mapMode==0 then appSelected="<SEL>"
    elseif mapMode==1 then vorSelected="<SEL>"
    elseif mapMode==2 then mapSelected="<SEL>" 
    elseif mapMode==3 then plnSelected="<SEL>"
    end
    local dh=string.format("%03d",simDR_radio_alt_DH_capt) 
    local mda=string.format("%04d",B747DR_efis_baro_alt_ref_capt) 
    if mapCenter==1 then ctrSelected ="<SEL>" end  
    local page={
    "      EFIS CONTROL      ",
    "                        ",
    baroString.."        ".. mapSelected .."  MAP>",
    "                        ",
    dh.."          ".. plnSelected .."  PLN>",
    "                        ",
    "<DH RESET    ".. appSelected .."  APP>",
    "                        ",
    mda.."         ".. vorSelected .."  VOR>",
    "                        ",
    "<RANGE INCR  ".. ctrSelected .."  CTR>",
    "             -----------",
    "<RANGE DECR     OPTIONS>"
    }
  return page
end

local ranges = {" 10", " 20", " 40", " 80", "160", "320", "640"}
fmsPages["EFISCTL152"].getSmallPage=function(self,pgNo,fmsID)
    local mode="IN "
    local baromode=B747DR_efis_baro_ref_capt_sel_dial_pos
    local range=ranges[simDR_range_dial_capt+1]
    if fmsID=="fmsR" then 
        baromode=B747DR_efis_baro_ref_fo_sel_dial_pos 
        range=ranges[simDR_range_dial_fo+1]
    end 
    if baromode==1 then mode="HPA" end 
    return {
        "                        ",
        " BARO SET           MODE",
        "      ".. mode .."               ",
        " DH SET                 ",
        "   FT                   ",
        "                        ",
        "                        ",
        " MDA SET                ",
        "    FT                  ",
        "                        ",
        "                        ", 
        range.."NM                   ",
        "                        "
        }
	end
fmsFunctionsDefs["EFISCTL152"]={}
fmsFunctionsDefs["EFISCTL152"]["L1"]={"setdata","BARO"}
fmsFunctionsDefs["EFISCTL152"]["L2"]={"setdata","DH"}
fmsFunctionsDefs["EFISCTL152"]["L3"]={"doCMD","laminar/B747/efis/dh/capt/reset_switch"}
fmsFunctionsDefs["EFISCTL152"]["L4"]={"setdata","MDA"}
fmsFunctionsDefs["EFISCTL152"]["L5"]={"setdata","RANGEINC"}
fmsFunctionsDefs["EFISCTL152"]["L6"]={"setdata","RANGEDEC"}
fmsFunctionsDefs["EFISCTL152"]["R1"]={"setdata","EFISMAP"}
fmsFunctionsDefs["EFISCTL152"]["R2"]={"setdata","EFISPLN"}
fmsFunctionsDefs["EFISCTL152"]["R3"]={"setdata","EFISAPP"}
fmsFunctionsDefs["EFISCTL152"]["R4"]={"setdata","EFISVOR"}
fmsFunctionsDefs["EFISCTL152"]["R5"]={"setdata","EFISCTR"}
fmsFunctionsDefs["EFISCTL152"]["R6"]={"setpage","EFISOPTIONS152"}


registerFMCCommand("sim/instruments/EFIS_wxr","")
registerFMCCommand("sim/instruments/EFIS_tcas","")


fmsPages["EFISOPTIONS152"]=createPage("EFISOPTIONS152")
fmsPages["EFISOPTIONS152"].getPage=function(self,pgNo,fmsID)
    local wxrSelected="     "
    local posSelected="     "
    local terrSelected="     "
    local tfcSelected="     "
    local vorSelected="     "
    local wptSelected="     "
    local staSelected="     "
    local arptSelected="     "
    local dataSelected="     "
    local adfSelected="     "
    
    if B747DR_nd_wxr==1 then wxrSelected="<SEL>" end
    if fmsID=="fmsR" then 
        if B747DR_nd_fo_ftc==1 then tfcSelected="<SEL>" end
        if B747DR_nd_fo_vor_ndb==1 then staSelected="<SEL>" end
        if B747DR_nd_fo_wpt==1 then wptSelected="<SEL>" end
        if B747DR_nd_fo_apt==1 then arptSelected="<SEL>" end
        if simDR_EFIS_1_sel_fo==2 and simDR_EFIS_2_sel_fo==2 then vorSelected="<SEL>" end
        if simDR_EFIS_1_sel_fo==0 and simDR_EFIS_2_sel_fo==0 then adfSelected="<SEL>" end
    else
        if B747DR_nd_capt_ftc==1 then tfcSelected="<SEL>" end
        if B747DR_nd_capt_vor_ndb==1 then staSelected="<SEL>" end
        if B747DR_nd_capt_wpt==1 then wptSelected="<SEL>" end
        if B747DR_nd_capt_apt==1 then arptSelected="<SEL>" end
        if simDR_EFIS_1_sel_pilot==2 and simDR_EFIS_2_sel_pilot==2 then vorSelected="<SEL>" end
        if simDR_EFIS_1_sel_pilot==0 and simDR_EFIS_2_sel_pilot==0 then adfSelected="<SEL>" end
    end
    return {

        "       EFIS OPTIONS     ",
        "                        ",
        "<WXR  ".. wxrSelected .."  ".. wptSelected .."  WPT>",
        "                        ",
        "<POS  ".. posSelected .."  ".. staSelected .."  STA>",
        "                        ",
        "<TERR ".. terrSelected .."  ".. arptSelected .." ARPT>",
        "                        ",
        "<TFC  ".. tfcSelected .."  ".. dataSelected .." DATA>", 
        "                        ",
        "<VOR  ".. vorSelected .."  ".. adfSelected .."  ADF>",
        "------------------------",
        "                CONTROL>"
        }
end
fmsFunctionsDefs["EFISOPTIONS152"]["L1"]={"setdata","WXR"}
--fmsFunctionsDefs["EFISOPTIONS152"]["L2"]={"setdata","POS"}
--fmsFunctionsDefs["EFISOPTIONS152"]["L3"]={"setdata","TERR"}
fmsFunctionsDefs["EFISOPTIONS152"]["L4"]={"setdata","TFC"}
fmsFunctionsDefs["EFISOPTIONS152"]["L5"]={"setdata","VORDISP"}
--fmsFunctionsDefs["EFISOPTIONS152"]["R1"]={"setdata","WPT"}
fmsFunctionsDefs["EFISOPTIONS152"]["R2"]={"setdata","STA"}
fmsFunctionsDefs["EFISOPTIONS152"]["R3"]={"setdata","ARPT"}
--fmsFunctionsDefs["EFISOPTIONS152"]["R4"]={"setdata","DATA"}
fmsFunctionsDefs["EFISOPTIONS152"]["R5"]={"setdata","ADFDISP"}
fmsFunctionsDefs["EFISOPTIONS152"]["R6"]={"setpage","EFISCTL152"}