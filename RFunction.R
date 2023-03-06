library('move2')

## The parameter "data" is reserved for the data object passed on from the previous app

## to display messages to the user in the log file of the App in MoveApps one can use the function from the logger.R file: 
# logger.fatal(), logger.error(), logger.warn(), logger.info(), logger.debug(), logger.trace()

rFunction = function(data,login,password,study,animals=NULL,select_sensors,time0=NULL,timeE=NULL) {
  
  movebank_store_credentials(login,password)
  
  arguments <- list()
  
  arguments[["study_id"]] <- study

  if (exists("time0") && !is.null(time0)) {
      logger.info(paste0("timestamp_start is set and will be used: ", time0))
      arguments["timestamp_start"] = time0
    } else {
      logger.info("timestamp_start not set.")
    }
  
  if (exists("timeE") && !is.null(timeE)) {
    logger.info(paste0("timestamp_end is set and will be used: ", timeE))
    arguments["timestamp_end"] = timeE
  } else {
    logger.info("timestamp_end not set.")
  }

  if (length(animals)==0)
  {
    logger.info("no animals set, using full study")
    animals <- as.character(movebank_retrieve(entity_type = "individual", study_id =study)$local_identifier) #local_identifier not well named here...
  }
  
  logger.info(paste(length(animals), "animals:", paste(animals,collapse=", ")))
  
  sensorinfo <- as.data.frame(movebank_retrieve("entity_type" = "tag_type"))
  sensors <- unique(movebank_retrieve(entity_type="sensor", tag_study_id=study)$sensor_type_id)
  sensors_nonloc <- sensors[sensors %in% as.numeric(sensorinfo[sensorinfo$is_location_sensor==FALSE,"id"])]
  sensors_nonloc_names <- sensorinfo$name[as.numeric(sensorinfo$id) %in% sensors_nonloc]

  #list with available sensors by animal
  animals_list <- as.list(animals)
  sensors_by_animal <- lapply(animals_list, function(x) unique(movebank_retrieve(entity_type="sensor", tag_study_id=study)$sensor_type_id,individual_local_identifier=x))
  names(sensors_by_animal) <- animals_list
  
  if (is.null(sensors_nonloc))
  {
    logger.info("The selected study does not contain any non-location sensor data. No data will be downloaded (NULL output) by this App.")
    result <- NULL
  } else if (length(select_sensors)==0)
  {
    logger.info("You have deselected all available non-location sensors. No data will be downloaded (NULL output) by this App.")
    result <- NULL
  } else
  {
    select_sensors_names <- sensorinfo$name[which(as.numeric(sensorinfo$id) %in% select_sensors)]
    logger.info(paste("Of all available non-location sensors in this study (",paste(sensors_nonloc_names,collapse=", "),") you have selected to download these selected sensor types:",paste(select_sensors_names,collapse=", ")))

    #only selected sensors by animal
    sensors_by_animal <- lapply(sensors_by_animal, function(x) x[which(x %in% select_sensors)])
    
    #can only download one individual track, ok
    result_list <- lapply(animals,function(animal) {
      
      arguments["individual_local_identifier"] = animal
      logger.info(animal)
      
      sensors_animal <- sensors_by_animal[[which(names(sensors_by_animal)==animal)]]

      if (length(sensors_animal)==0)
      {
        logger.info("There are no data of the required sensor type for this animal.")
        data_id <- NULL
      } else 
      {
        arguments[["sensor_type_id"]] <- sensors_animal
        data_id <- tryCatch(do.call(movebank_download_study, arguments), error = function(e){
          logger.info(e)
          return(NULL)}) #can return NULL if there are no data by this animal
      }
      
      # possibility to remove duplicates if taken by the same sensor
      if (is.null(data_id)==FALSE)
      {
        dupl <- which(duplicated(data.frame(mt_time(data_id),data_id$sensor_type_id))) #remove duplicates, even if this can likely never happen (can it?)
        if (length(dupl)>0) 
        {
          data_id <- data_id[-dupl,]
          logger.info(paste(length(dupl),"duplicated measurements were removed from your dataset."))
        }
      }
      data_id
    })

    result <- result_list[[1]]
    if (length(result_list)>1) for (i in seq(along=result_list)[-1]) result <- rbind(result,result_list[[i]]) #this for-loop must be optimized somehow, not sure how that works with tibble, lists and move2..
    #NULL can be added with rbind, as it disappears. no need to take out individuals without data
    names(result) <- make.names(names(result),allow_=FALSE) #most apps work with generalised names attributes, but have to think here...
  }

  return(result)
  
}
