library(TMB)
compile("streamtemp.cpp")
dyn.load("streamtemp.so")

X0 <- as.matrix(data.frame(intercept = 1,
                  lat = data$Latitude,
                  lon = data$Longitude,
                  airTemp = data$airTemp, 
                  airTempLag1 = data$airTempLagged1,
                  airTempLag2 = data$airTempLagged2,
                  precip = data$prcp,
                  precipLag1 = data$prcpLagged1,
                  precipLag2 = data$prcpLagged3,
                  drainage = data$TotDASqKM,
                  forest = data$Forest,
                  elevation = data$ReachElevationM,
                  coarseness = data$SurficialCoarseC,
                  wetland = data$CONUSWetland,
                  impoundments = data$ImpoundmentsAllSqKM,
                  swe = data$swe,
                  dOY = data$dOY, 
                  dOY2 = data$dOY^2,
                  dOY3 = data$dOY^3)))
variables.fixed <- names(X0)

Xyear <- as.matrix(data.frame(intercept.year = 1, 
                     dOY = data$dOY, 
                     dOY2 = data$dOY^2,
                     dOY3 = data$dOY^3))

Xsite <- as.matrix(data.frame(intercept.site = 1, 
                     airTemp = data$airTemp, 
                     airTempLag1 = data$airTempLagged1,
                     airTempLag2 = data$airTempLagged2,
                     precip = data$prcp,
                     precipLag1 = data$prcpLagged1,
                     precipLag2 = data$prcpLagged3,
                     drainage = data$TotDASqKM,
                     forest = data$Forest,
                     elevation = data$ReachElevationM,
                     coarseness = data$SurficialCoarseC,
                     wetland = data$CONUSWetland,
                     impoundments = data$ImpoundmentsAllSqKM,
                     swe = data$swe))
variables.site <- names(Xsite)

dat.list <- list(temp = data$temp,
             X0 = X0,
             Xsite = Xsite, #as.matrix(X.site),
             Xyear = as.matrix(Xyear),
             site = as.factor(data$site),
             year = as.factor(data$year))

params <- list(log_sigma = 1,
               site_pred_log_sd = rep(0, times = dim(Xsite)[2]),
               year_pred_log_sd = rep(0, times = dim(Xyear)[2]),
               B0 = rep(0, times = dim(X0)[2]),
               Bsite = matrix(0,  dim(Xsite)[1], dim(Xsite)[2]),
               Byear = matrix(0,  dim(Xyear)[1], dim(Xyear)[2]))

mod <- MakeADFun(data = dat.list, parameters = params, DLL = "streamtemp", random = c("Bsite", "Byear"))


