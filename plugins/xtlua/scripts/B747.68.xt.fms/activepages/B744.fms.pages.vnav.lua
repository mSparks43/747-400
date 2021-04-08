fmsPages["VNAV"]=createPage("VNAV")
fmsPages["VNAV"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    if pgNo==1 then 
      --ref pg 1519 fcomm
      fmsFunctionsDefs["VNAV"]["L1"]={"setdata","crzalt"}
      fmsFunctionsDefs["VNAV"]["L2"]={"setdata","clbspd"}
      fmsFunctionsDefs["VNAV"]["L3"]={"setdata","clbtrans"}
      fmsFunctionsDefs["VNAV"]["L4"]={"setdata","clbrest"}
      fmsFunctionsDefs["VNAV"]["R1"]=nil
      fmsFunctionsDefs["VNAV"]["R3"]={"setdata","transalt"}
      return{
      "     ACT ECON CLB       ",
      "                        ",
      fmsModules["data"]["crzalt"].."           ***/****",
      "                        ",
      fmsModules["data"]["clbspd"].."                        ",
      "                        ",
      fmsModules["data"]["transpd"].."/"..fmsModules["data"]["spdtransalt"].."          "..fmsModules["data"]["transalt"],
      "                        ",
      fmsModules["data"]["clbrestspd"].."/"..fmsModules["data"]["clbrestalt"].."           24.7",
      "------------------------",
      "                ENG OUT>", 
      "                        ",
      "                CLB DIR>"
      }
    elseif pgNo==2 then 
      --ref pg 1543 fcomm
      fmsFunctionsDefs["VNAV"]["L1"]={"setdata","crzalt"}
      fmsFunctionsDefs["VNAV"]["L2"]={"setdata","crzspd"}
      fmsFunctionsDefs["VNAV"]["L3"]=nil
      fmsFunctionsDefs["VNAV"]["L4"]=nil
      fmsFunctionsDefs["VNAV"]["R1"]={"setdata","stepalt"}
      fmsFunctionsDefs["VNAV"]["R3"]=nil
      return{
      "     ACT ECON CRZ       ",
      "                        ",
      fmsModules["data"]["crzalt"].."              "..fmsModules["data"]["stepalt"],
      "                        ",
      "."..fmsModules["data"]["crzspd"].."       ****z /****NM",
      "                        ",
      "1.36        ****z /***.*",
      "                        ",
      "ICAO      FL358    FL376",
      "------------------------",
      "                ENG OUT>", 
      "                        ",
      "<RTA PROGRESS       LRC>"
      }  
    elseif pgNo==3 then 
      --ref pg 1583 fcomm
      fmsFunctionsDefs["VNAV"]["L1"]=nil
      fmsFunctionsDefs["VNAV"]["L2"]={"setdata","desspds"}
      fmsFunctionsDefs["VNAV"]["L3"]={"setdata","destrans"}
      fmsFunctionsDefs["VNAV"]["L4"]={"setdata","desrest"}
      fmsFunctionsDefs["VNAV"]["R1"]=nil
      fmsFunctionsDefs["VNAV"]["R3"]=nil
      if B747DR_ap_vnav_state==2 and simDR_autopilot_vs_status==2 then
	fmsModules["data"]["fpa"]=string.format("%1.1f",B747DR_ap_fpa)
	fmsModules["data"]["vb"]=string.format("%1.1f", B747DR_ap_vb)
	fmsModules["data"]["vs"]=string.format("%4d",simDR_autopilot_vs_fpm*-1) 
      else
	 fmsModules["data"]["fpa"]="*.*"
	fmsModules["data"]["vb"]="*.*"
	fmsModules["data"]["vs"]="****"
      end
      return{
      "     ACT ECON DES       ",
      "                        ",
      "  **** *****    ***/****",
      "                        ",
      ".".. fmsModules["data"]["desspdmach"].."/"..fmsModules["data"]["desspd"].."                ",
      "                        ",
      fmsModules["data"]["destranspd"].."/"..fmsModules["data"]["desspdtransalt"].."               ",
      "                        ",
      fmsModules["data"]["desrestspd"].."/"..fmsModules["data"]["desrestalt"].."   "..fmsModules["data"]["fpa"].." "..fmsModules["data"]["vb"].." "..fmsModules["data"]["vs"],
      "------------------------",
      "               FORECAST>", 
      "                        ",
      "OFFPATH DES     DES DIR>"
      }
    end
end

fmsPages["VNAV"].getSmallPage=function(self,pgNo,fmsID)
    if pgNo==1 then 
      return{
      "                    1/3 ",
      " CRZ ALT        AT *****",
      "                        ",
      " ECON SPD          ERROR",
      "                        ",
      " SPD TRANS     TRANS ALT",
      "                        ",
      " SPD REST      MAX ANGLE",
      "                        ",
      "                        ",
      "                        ", 
      "                        ",
      "                        "
      }
    elseif pgNo==2 then 
      return{
      "                    2/3 ",
      " CRZ ALT         STEP TO",
      "                        ",
      " ECON SPD             AT",
      "                        ",
      " N1        KATL ETA/FUEL",
      "                        ",
      " STEP SITE OPT       MAX",
      "                        ",
      "                        ",
      "                        ", 
      "                        ",
      "                        "
      }
    elseif pgNo==3 then 
      return{
      "                    3/3 ",
      " E/D AT         AT *****",
      "                        ",
      " ECON SPD               ",
      "                        ",
      " SPD TRANS              ",
      "                        ",
      " SPD REST   FPA V/B  V/S",
      "                        ",
      "                        ",
      "                        ", 
      "                        ",
      "                        "
      }
    end
end

fmsPages["VNAV"].getNumPages=function(self)
  return 3
end