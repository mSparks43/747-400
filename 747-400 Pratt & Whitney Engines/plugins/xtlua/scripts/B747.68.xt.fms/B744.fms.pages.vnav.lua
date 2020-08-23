fmsPages["VNAV"]=createPage("VNAV")
fmsPages["VNAV"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    if pgNo==1 then 
      --ref pg 1519 fcomm
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
      return{
      "     ACT ECON DES       ",
      "                        ",
      "  **** *****    ***/****",
      "                        ",
      ".***/***                ",
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