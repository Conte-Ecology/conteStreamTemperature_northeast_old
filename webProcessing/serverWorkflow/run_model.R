# Run model and save JAGS output
# requires tempDataSync input binary file
# saves output M.huc to binary file
#
# usage: $ Rscript run_model.R <input tempDataSync rdata> <output jags rdata>
# example: $ Rscript run_model.R ./tempDataSync.RData ./jags.RData

# NOTE: this has not actually been run, and is mostly just copy and pasted from the analysis vignette

# parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
tempDataSync_file <- args[1]
if (!file.exists(tempDataSync_file)) {
  stop(paste0('Could not find tempDataSync binary file: ', tempDataSync_file))
}
load(tempDataSync_file)

output_file <- args[2]
if (file.exists(output_file)) {
  warning(paste0('Output file already exists, overwriting: ', output_file))
}

# ----
### Run the model in JAGS

coda.tf <- TRUE # currently only works in full for TRUE (using coda.samples)

data.fixed <- data.frame(intercept = 1,
                         lat = tempDataSyncS$Latitude,
                         lon = tempDataSyncS$Longitude,
                         drainage = tempDataSyncS$TotDASqKM,
                         forest = tempDataSyncS$Forest,
                         elevation = tempDataSyncS$ReachElevationM,
                         coarseness = tempDataSyncS$SurficialCoarseC,
                         wetland = tempDataSyncS$CONUSWetland,
                         impoundments = tempDataSyncS$ImpoundmentsAllSqKM)

data.random.sites <- data.frame(intercept.site = 1, 
                                airTemp = tempDataSyncS$airTemp, 
                                #airTempLag1 = tempDataSyncS$airTempLagged1,
                                airTempLag2 = tempDataSyncS$airTempLagged2,
                                precip = tempDataSyncS$prcp,
                                precipLag1 = tempDataSyncS$prcpLagged1,
                                precipLag2 = tempDataSyncS$prcpLagged2) # , swe = tempDataSyncS$swe

data.random.years <- data.frame(intercept.year = 1, 
                                dOY = tempDataSyncS$dOY, 
                                dOY2 = tempDataSyncS$dOY^2,
                                dOY3 = tempDataSyncS$dOY^3)

monitor.params <- c("residuals",
                    #"deviance",
                    "sigma",
                    "B.0",
                    #"B.site",
                    #"rho.B.site",
                    #"mu.site",
                    "sigma.b.site",
                    #"B.huc",
                    #"rho.B.huc",
                    "mu.huc",
                    "sigma.b.huc",
                    #"B.year",
                    #"rho.B.year",
                    "mu.year",
                    "sigma.b.year")

M.huc <- modelRegionalTempHUC(tempDataSyncS, data.fixed=data.fixed, data.random.sites=data.random.sites, data.random.years=data.random.years, n.burn = 1000, n.it = 1000, n.thin = 1, nc = 3, coda = coda.tf, param.list = monitor.params)

# save to rdata
saveRDS(M.huc, file=output_file)