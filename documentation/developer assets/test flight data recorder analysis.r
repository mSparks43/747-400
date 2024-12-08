options(scipen = 999)
library(NHMStandardLib)
tFlight<-"flight_tests/mSparks/flight_data.jdat"
testsFrom<-"XP12-10-2024/01/01 00:00" #only report flight tests after this OP Program
#testsFrom<-"All"
myFlights<-FALSE #Set to false to read from sent flight tests folder
test_pilot<-"mSparks" #Set to test pilot name for myFlights
library(NISTunits)
getDistance<-function(lat1,lon1,lat2,lon2){
  alat=NISTdegTOradian(lat1)
  alon=NISTdegTOradian(lon1)
  blat=NISTdegTOradian(lat2)
  blon=NISTdegTOradian(lon2)
  av=sin(alat)*sin(blat) + cos(alat)*cos(blat)*cos(blon-alon)
  if (av > 1) 
    av=1 
  retVal=acos(av) * 3440
  return (retVal)
}

processRow <- function(row){
  if(startsWith(row,"{")){
    isValid<-FALSE
    json_final<-tryCatch({
      fromJSON(row)
      isValid<-TRUE
      }, error = function(e) {})
    if(isValid)
      return(data.frame(data=row))
    else {
      return(data.frame())
    }
  } else {
    return(data.frame())
  }
}

parseTestFlight<-function(filename){
  retVal<-list()
  flight_data<-mapReduce_map_ndjson(filename,processRow)
  flight_data<-mapReduce_reduce(flight_data)
  #flight_data is now a list of json object strings in date order
  flight_tests<-data.frame()
  in_test_flight<-FALSE
  currentOPProgram<-NA
  currentEngines<-NA
  startTime<-NA
  lastTime<-NA
  lastLat<-NA
  lastLong<-NA
  currentDistance<-0
  
  for(fentry in flight_data$data){
    json_data<-fromJSON(fentry) #tryCatch({fromJSON(fentry)}, error = function(e) {fromJSON("{}")})
    if(!is.null(json_data[["PLANE"]])){
      if(!is.na(lastTime)){
        print(lastTime)
        print(currentDistance)
        if(currentDistance>0){
          startTimeT<-as.numeric(as.POSIXct(strptime(startTime, "%Y/%m/%d %H:%M:%S")))
          endTimeT<-as.numeric(as.POSIXct(strptime(lastTime, "%Y/%m/%d %H:%M:%S")))
          duration<-((endTimeT-startTimeT)/60)
          flight_tests<-rbind(flight_tests,data.frame(currentOPProgram,currentEngines,startTime,lastTime,distance=currentDistance,duration))
        }
      }
      currentOPProgram<-json_data$FMC$INIT$op_program
      #print(currentOPProgram)
      currentEngines<-json_data$PLANE$engines
      if(json_data$FMC$INIT$op_program>=testsFrom){
        in_test_flight<-TRUE
        startTime<-NA
        lastTime<-NA
        lastLat<-NA
        lastLong<-NA
        currentDistance<-0
      }
      else {
        in_test_flight<-FALSE
        startTime<-NA
        lastTime<-NA
        lastLat<-NA
        lastLong<-NA
        currentDistance<-0
      }
      
    }
    if(in_test_flight&&!is.null(json_data[["time"]])){
      if(is.na(startTime)){
        startTime<-json_data[["time"]]
        lastTime<-json_data[["time"]]
        print(json_data[["time"]])
      } else {
        lastTime<-json_data[["time"]]
      }
      if(!is.null(json_data[["flightData"]])){
        if(is.na(lastLat)){
          lastLat<-json_data$flightData$simDR_latitude
          lastLong<-json_data$flightData$simDR_longitude
        }else{
          
          thisDistance<-getDistance(lastLat,lastLong,json_data$flightData$simDR_latitude,json_data$flightData$simDR_longitude)
          lastLat<-json_data$flightData$simDR_latitude
          lastLong<-json_data$flightData$simDR_longitude
          currentDistance<-currentDistance+thisDistance
        }
      }
    }
  }
  print(startTime)
  print(currentDistance)
  if(currentDistance>0){
    startTimeT<-as.numeric(as.POSIXct(strptime(startTime, "%Y/%m/%d %H:%M:%S")))
    endTimeT<-as.numeric(as.POSIXct(strptime(lastTime, "%Y/%m/%d %H:%M:%S")))
    duration<-((endTimeT-startTimeT)/60)
    flight_tests<-rbind(flight_tests,data.frame(currentOPProgram,currentEngines,startTime,lastTime,distance=currentDistance,duration))
  }
  return(flight_tests)
}

flight_tests<-data.frame()
if(!myFlights)
{
  test_pilots<-list.dirs(path = "flight_tests", full.names = FALSE, recursive = FALSE)
  
  for(test_pilot in test_pilots){
    print(test_pilot)
    testFlights<-list.files(path=CONCAT("flight_tests/",test_pilot,""), pattern=NULL, all.files=FALSE, full.names=TRUE)
    print(testFlights)
    for(testFlight in testFlights){
      theseFlights<-parseTestFlight(testFlight)
      flight_tests<-rbind(flight_tests,data.frame(test_pilot,theseFlights))
    }
  }
} else {
  testFlightsFolders<-list.dirs(path = "../../liveries/", full.names = TRUE, recursive = FALSE)
  for(test_flight in testFlightsFolders){
    print(test_flight)
    testFlights<-list.files(path=test_flight, pattern=".jdat", all.files=FALSE, full.names=TRUE)
    if(length(testFlights)==0)
      next
    theseFlights<-parseTestFlight(testFlights)
    if(nrow(theseFlights)>0)
      flight_tests<-rbind(flight_tests,data.frame(test_pilot,theseFlights))
  }
  
}

hText<-"---
header-includes:
- \\usepackage{hyperref}
- \\usepackage{fancyhdr}
- \\pagestyle{fancy}
- \\usepackage{xcolor}
- \\hypersetup{colorlinks=true,
                urlcolor=blue,
                linkcolor=blue,
                allbordercolors={0 0 0},
                pdfborderstyle={/S/U/W 1}} 

geometry: \"left=1.5cm,right=1.5cm,top=2cm,bottom=2cm\"
colorlinks: true  
toc: true  
title: Sparky744
include-before:
  - '`\\newpage{}`{=latex}'
subtitle: Flight Test Report
---
  
\\newpage{}"
retText<-unlist(strsplit(hText, split='\n'))
retText<-append(retText,c("# Flight Test report","OP Programs after",CONCAT("*",testsFrom,"*\n"), "*As at*",format(Sys.time(), "%Y/%m/%d %H:%M:%S\n")))
lastHeading<-"NA"
addReportText<-function(dText){
  retVal<<-retText
  retVal<-append(retVal,dText)
  retText<<-retVal
}
getReportText<-function(data,dText,eText){
  retVal<<-retText
  if(is.null(names(data))){
    for(i in rownames(data)){
      thisHeading<-CONCAT("## ",i)
      if(thisHeading!=lastHeading)
        retVal<-append(retVal,thisHeading)
      lastHeading<<-thisHeading
      for(n in colnames(data)){
        if(!is.na(round(data[i,n])))
        retVal<-append(retVal,CONCAT(" ",n," ",dText,round(data[i,n]),eText,"\n"))
      }
    }
  } else {
    for(n in names(data)){
      tVal<-round(data[n])
      if(!is.na(tVal))
      retVal<-append(retVal,CONCAT(" *",n,"* ",dText,tVal,eText,"\n"))
    }
  }
  retText<<-retVal
}

addReportText("# Summary")
getReportText(tapply(flight_tests$duration, flight_tests$test_pilot, FUN=sum),"duration: "," minutes")
getReportText(tapply(flight_tests$distance, flight_tests$test_pilot, FUN=sum),"distance: "," nm")
addReportText("::: {.columns columngap=10em column-rule=\"1px solid black\"}")
addReportText("\\newpage{}\n# Engines")
addReportText("# Engines duration")
getReportText(tapply(flight_tests$duration, list(flight_tests$currentEngines,flight_tests$test_pilot), FUN=sum),"duration: "," minutes")
addReportText("# Engines distance")
getReportText(tapply(flight_tests$distance, list(flight_tests$currentEngines,flight_tests$test_pilot), FUN=sum),"distance: "," nm")
addReportText("\\newpage{}\n# OP Program")
addReportText("# OP Program duration")
getReportText(tapply(flight_tests$duration, list(flight_tests$currentOPProgram,flight_tests$test_pilot), FUN=sum),"duration: "," minutes")
addReportText("# OP Program distance")
getReportText(tapply(flight_tests$distance, list(flight_tests$currentOPProgram,flight_tests$test_pilot), FUN=sum),"distance: "," nm")
addReportText(":::")
fName<-"flight testing.md"
if(myFlights)
  fName<-"mSparks flight testing.md"
writeLines(retText,fName)