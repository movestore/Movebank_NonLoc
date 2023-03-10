# tie everything together
# the following files will NOT bundled into the final app - they are just helpers in the SDK
source("src/common/logger.R")
source("src/io/app_files.R")
source("src/io/io_handler.R")
source("src/io/rds.R")

# simulate an app run on moveapps.org
simulateMoveAppsRun <- function(args) {
    tryCatch(
    {
        #Sys.setenv(tz="UTC") #talk about this line... should probably remove

        data <- readInput(sourceFile())
        if (!is.null(data)) {
            args[["data"]] <- data
        }

        result <- do.call(rFunction, args)
        storeResult(result, outputFile())
    },
    error = function(e)
    {
        # error handler picks up where error was generated
        print(paste("ERROR: ", e))
        storeToFile(e, errorFile())
        stop(e) # re-throw the exception
    })
}