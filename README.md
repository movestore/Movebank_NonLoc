# Movebank non-Location Download

MoveApps

Github repository: *github.com/movestore/Movebank_NonLoc*

## Description
Download non-location data from Movebank studies. These can be e.g. accessory measurements or acceleration data (Tipp: Add multiple Apps of this type to combine similar data of different Movebank studies that can be analysed jointly.

## Documentation
TBD

### Input data
non-location move2 object in Movebank format


### Output data
non-location move2 object in Movebank format

### Artefacts
none.

### Settings 
TBD
*Please list and define all settings/parameters that the App requires to be set by the App user, if necessary including their unit.*

*Example:* `Radius of resting site` (radius): Defined radius the animal has to stay in for a given duration of time for it to be considered resting site. Unit: `metres`.

### Most common errors
TBD
*Please describe shortly what most common errors of the App can be, how they occur and best ways of solving them.*

### Null or error handling
TBD
*Please indicate for each setting as well as the input data which behaviour the App is supposed to show in case of errors or NULL values/input. Please also add notes of possible errors that can happen if settings/parameters are improperly set and any other important information that you find the user should be aware of.*

*Example:* **Setting `radius`:** If no radius AND no duration are given, the input data set is returned with a warning. If no radius is given (NULL), but a duration is defined then a default radius of 1000m = 1km is set. 
