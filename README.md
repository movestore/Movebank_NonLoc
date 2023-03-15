# Movebank Non-Location

MoveApps

Github repository: *github.com/movestore/Movebank_NonLoc*

## Description
Download non-location data from Movebank studies. These can be e.g. accessory measurements or acceleration data (Tipp: Add multiple Apps of this type to combine similar data of different Movebank studies that can be analysed jointly.

## Documentation
Using the new move2 R package, here the sf concept is used for quick download of non-location data from Movebank. Similar to the Movebank App, login and selection of a study and animals can be performed. Only non-location data types can be selected and downloaded, with the possibility to set start and/or end timestamps.

The main function used here is movebank_download_study() from the R package move2. If not animals are selected in the second selection step, data of all animals of the study are downloaded. Note that the data set will be combined by animal if more than one sensor type has been selected. This might complicate further analysis of the data, but could also allow for more general outcomes.

So far, it is not possible or recommended to include non-location data here.

### Input data
none or
non-location move2 object in Movebank format


### Output data
non-location move2 object in Movebank format

### Artefacts
none.

### Settings 
interactive: movebank credentials, study, animals, time range, sensor type

### Most common errors
not yet available.


### Null or error handling
The move2 object can handle empty tables, so those should not lead to problems.

The column names timestamp, sensory_type and individual_local_identifier are required.
