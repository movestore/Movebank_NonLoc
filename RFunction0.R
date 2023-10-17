library('move2')
library('keyring')

## update to download all selected animals in one go.

## discuss how to provide sensor type table in cargo agent (or use API)

rFunction = function(data=NULL,username,password,config_version=NULL,study,animals=NULL,select_sensors,handle_duplicates=TRUE,timestamp_start=NULL,timestamp_end=NULL) {
  
  options("keyring_backend"="env")
  movebank_store_credentials(username,password)
  
  arguments <- list()
  
  arguments[["study_id"]] <- study

  if (exists("timestamp_start") && !is.null(timestamp_start)) {
      logger.info(paste0("timestamp_start is set and will be used: ", timestamp_start))
      arguments["timestamp_start"] = timestamp_start
      #arguments["timestamp_start"] = paste(substring(as.character(timestamp_start),c(1,6,9,12,15,18,21),c(4,7,10,13,16,19,23)),collapse="")
      #arguments["timestamp_start"] = as.POSIXct(as.character(timestamp_start),format="%Y-%m-%dT%H:%M:%OSZ")
    } else {
      logger.info("timestamp_start not set.")
    }
  
  if (exists("timestamp_end") && !is.null(timestamp_end)) {
    logger.info(paste0("timestamp_end is set and will be used: ", timestamp_end))
    arguments["timestamp_end"] = timestamp_end
    #arguments["timestamp_end"] = paste(substring(as.character(timestamp_end),c(1,6,9,12,15,18,21),c(4,7,10,13,16,19,23)),collapse="")
    #arguments["timestamp_end"] = as.POSIXct(as.character(timestamp_end),format="%Y-%m-%dT%H:%M:%OSZ")
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
  } else if (is.null(select_sensors) | length(select_sensors)==0)
  {
    logger.info("Either the selected study does not contain any non-location sensor data or you have deselected all available non-location sensors. No data will be downloaded (NULL output) by this App.")
    result <- NULL
  } else
  {
    select_sensors_names <- sensorinfo$name[which(as.numeric(sensorinfo$id) %in% select_sensors)]
    logger.info(paste("Of all available non-location sensors in this study (",paste(sensors_nonloc_names,collapse=", "),") you have selected to download these selected sensor types:",paste(select_sensors_names,collapse=", ")))

    #only selected sensors by animal
    sensors_by_animal <- lapply(sensors_by_animal, function(x) x[which(x %in% select_sensors)])
    
    #can only download one individual track, ok
    result_list <- lapply(animals, function(animal) {
      
      arguments["individual_local_identifier"] = URLencode(animal,reserved=T) #animal
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
      if (handle_duplicates==TRUE)
      {
        if (!is.null(data_id)) #if there are any data from the individual
        {
          dupl <- which(duplicated(data.frame(mt_time(data_id),data_id$sensor_type_id))) #remove duplicates, even if this can likely never happen (can it?)
          if (length(dupl)>0) 
          {
            data_id <- data_id[-dupl,]
            logger.info(paste(length(dupl),"duplicated measurements were removed from your dataset."))
          }
        }
      }
      if (!is.null(data_id)) logger.info(paste0(dim(data_id)[1]," non-location events were downloaded for the individual ", animal,".")) else logger.info(paste0("There were no data available for the specified settings for individual ",animal,"."))
      data_id
    })

    
    result_list <- result_list[unlist(lapply(result_list, is.null)==FALSE)]  #remove NULL entries
    if (length(result_list)>0) result <- mt_stack(result_list) else result <- NULL
    #note that one should not create generalised names here, as move2 objects require to have the attribute "individual_local_identifier"
    
  }

  if (exists("data") && !is.null(data)) 
  {
    if (is.null(result)) 
    {
      result <- data
      logger.info("No data downloaded, but input data returned.")
    } else
    {
      logger.info("Merging input and result together.")
      result <- mt_stack(data,result) #this gives an error if attributes of same name have differing class
    }
  }
  
  return(result) #move2 object
  
}
