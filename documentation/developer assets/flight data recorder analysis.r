options(scipen = 999)
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
readAllFlights<-function(){
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
  return(flight_tests)
}
