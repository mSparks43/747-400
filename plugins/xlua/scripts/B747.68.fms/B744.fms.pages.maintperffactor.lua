fmsPages["MAINTPERFFACTOR"]=createPage("MAINTPERFFACTOR")
fmsPages["MAINTPERFFACTOR"]["template"]={

"      PERF FACTORS  1/1 ",
" PERF CODE   OPTION CODE",
"1111        00000000XXXX",
" DRAG/F-F        R/C CLB",
"+0.0/+0.0            300",
" TO-1/TO-2       THR/CRZ",
"  10/20          CLB/100",
" MNVR MARGIN     THR RED",
"1.3                 1500",
" MIN CRZ TIME   ACCEL HT",
"1                   1500", 
"                        ",
"<INDEX               ARM"
    }


fmsFunctionsDefs["MAINTPERFFACTOR"]={}
fmsFunctionsDefs["MAINTPERFFACTOR"]["L6"]={"setpage","INITREF"}