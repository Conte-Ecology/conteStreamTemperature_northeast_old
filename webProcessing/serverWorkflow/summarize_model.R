# Summarize model
# requires jags input binary file (M.huc dataframe) and tempDataSync file
# saves output modSummary to binary file
#
# usage: $ Rscript summarize_model.R <input tempDataSync rdata> <input jags rdata> <output modSummary rdata>
# example: $ Rscript summarize_model.R ./tempDataSync.RData ./jags.RData ./modSummary.RData

# NOTE: this has not actually been run, and is mostly just copy and pasted from the analysis vignette

# parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

tempDataSync_file <- args[1]
if (!file.exists(tempDataSync_file)) {
  stop(paste0('Could not find tempDataSync binary file: ', tempDataSync_file))
}
load(tempDataSync_file)

jags_file <- args[2]
if (!file.exists(jags_file)) {
  stop(paste0('Could not find jags binary file: ', jags_file))
}
M.huc <- readRDS(jags_file)

output_file <- args[3]
if (file.exists(output_file)) {
  warning(paste0('Output file already exists, overwriting: ', output_file))
}

# ----
# Create model summaries that look like lme4 output and have mean coeficient values for predictions and validations

summary.stats <- summary(M.huc)

K.0 <- dim(data.fixed)[2]
K <- dim(data.random.sites)[2]
L <- dim(data.random.years)[2]
J <- length(unique(tempDataSyncS$site))
n <- dim(tempDataSyncS)[1]
M <- length(unique(tempDataSyncS$HUC8))
Ti <- length(unique(tempDataSyncS$year))

# Make "Fixed Effects" Output like summary(lmer)
#codaFixEf <- function (K.0, K, L, variables.fixed, variables.site, variables.year, k, summary.stats, l) {
fix.ef <- as.data.frame(matrix(NA, K.0+K+L, 4))
names(fix.ef) <- c("Mean", "Std. Error", "LCI", "UCI")
row.names(fix.ef) <- c(names(data.fixed), names(data.random.sites), names(data.random.years))
for(k in 1:K.0){
  fix.ef[k, 1:2] <- summary.stats$statistics[paste0('B.0[',k,']') , c("Mean", "SD")]
  fix.ef[k, 3:4] <- summary.stats$quantiles[paste0('B.0[',k,']') , c("2.5%", "97.5%")]
}
for(k in 1:K){
  fix.ef[k+K.0, 1:2] <- summary.stats$statistics[paste0('mu.huc[',k,']') , c("Mean", "SD")]
  fix.ef[k+K.0, 3:4] <- summary.stats$quantiles[paste0('mu.huc[',k,']') , c("2.5%", "97.5%")]
}
for(l in 1:L){
  fix.ef[l+K.0+K, 1:2] <- summary.stats$statistics[paste0('mu.year[',l,']') , c("Mean", "SD")]
  fix.ef[l+K.0+K, 3:4] <- summary.stats$quantiles[paste0('mu.year[',l,']') , c("2.5%", "97.5%")]
}
#}
# fix.ef

# Make Random Effects Output like summary(lmer)
ran.ef.huc <- as.data.frame(matrix(NA, K, 2))
names(ran.ef.huc) <- c("Variance", "SD")
row.names(ran.ef.huc) <- names(data.random.sites)
for(k in 1:K){
  ran.ef.huc[k, 2] <- summary.stats$statistics[paste0('sigma.b.huc[',k,']') , c("Mean")]
  ran.ef.huc[k, 1] <- ran.ef.huc[k, 2] ^ 2
}
# ran.ef.huc

B.huc <- as.data.frame(matrix(NA, M, K))
names(B.huc) <- names(data.random.sites)
row.names(B.huc) <- unique(tempDataSyncS$HUC8)
for(m in 1:M){
  for(k in 1:K){
    B.huc[m, k] <- summary.stats$statistics[paste('B.huc[',m,',',k,']', sep=""), "Mean"]
  }
}

# Random Sites
ran.ef.site <- as.data.frame(matrix(NA, K, 2))
names(ran.ef.site) <- c("Variance", "SD")
row.names(ran.ef.site) <- names(data.random.sites)
for(k in 1:K){
  ran.ef.site[k, 2] <- summary.stats$statistics[paste0('sigma.b.site[',k,']') , c("Mean")]
  ran.ef.site[k, 1] <- ran.ef.site[k, 2] ^ 2
}
# ran.ef.site

B.site <- as.data.frame(matrix(NA, M, K))
names(B.site) <- names(data.random.sites)
row.names(B.site) <- unique(tempDataSyncS$site8)
for(m in 1:M){
  for(k in 1:K){
    B.site[m, k] <- summary.stats$statistics[paste('B.site[',m,',',k,']', sep=""), "Mean"]
  }
}

# Make Random Effects Output like summary(lmer)
ran.ef.year <- as.data.frame(matrix(NA, L, 2))
names(ran.ef.year) <- c("Variance", "SD")
row.names(ran.ef.year) <- names(data.random.years)
for(l in 1:L){
  ran.ef.year[l, 2] <- summary.stats$statistics[paste0('sigma.b.year[',l,']') , c("Mean")]
  ran.ef.year[l, 1] <- ran.ef.year[l, 2] ^ 2
}
# ran.ef.year

Y <- length(unique(tempDataSyncS$year))
B.year <- as.data.frame(matrix(NA, Y, L))
names(B.year) <- names(data.random.years)
row.names(B.year) <- unique(tempDataSyncS$year)
for(y in 1:Y){
  for(l in 1:L){
    B.year[y, l] <- summary.stats$statistics[paste('B.year[',y,',',l,']', sep=""), "Mean"]
  }
}

# Make correlation matrix of random huc effects
cor.huc <- as.data.frame(matrix(NA, K, K))
names(cor.huc) <- names(data.random.sites)
row.names(cor.huc) <- names(data.random.sites)
for(k in 1:K){
  for(k.prime in 1:K){
    cor.huc[k, k.prime] <- summary.stats$statistics[paste('rho.B.huc[',k,',',k.prime,']', sep=""), "Mean"]
  }
}
cor.huc <- round(cor.huc, digits=3)
cor.huc[upper.tri(cor.huc, diag=TRUE)] <- ''
# cor.huc

# Make correlation matrix of random year effects
cor.year <- as.data.frame(matrix(NA, L, L))
names(cor.year) <- variables.year
row.names(cor.year) <- variables.year
for(l in 1:L){
  for(l.prime in 1:L){
    cor.year[l, l.prime] <- summary.stats$statistics[paste('rho.B.year[',l,',',l.prime,']', sep=""), "Mean"]
  }
}
cor.year <- round(cor.year, digits=3)
cor.year[upper.tri(cor.year, diag=TRUE)] <- ''
# cor.year

# combine model summary results into an S4 Object
setClass("jagsSummary",
         representation(fixEf="data.frame",
                        ranEf="list",
                        ranCor="list",
                        BSite="data.frame",
                        BYear="data.frame"))

modSummary <- new("jagsSummary")
modSummary@fixEf <- fix.ef
modSummary@ranEf <- list(ranSite=ran.ef.site, ranYear=ran.ef.year)
modSummary@ranCor <- list(corSite=cor.site, corYear=cor.year)
modSummary@BSite <- B.site
modSummary@BYear <- B.year

# modSummary <- NULL
# modSummary$fixEf <- fix.ef
# modSummary$ranEf <- list(ranSite=ran.ef.site, ranYear=ran.ef.year)
# modSummary$ranCor <- list(corSite=cor.site, corYear=cor.year)
# modSummary$BSite <- B.site
# modSummary$BYear <- B.year

# modSummary
# str(modSummary)
# 
# modSummary
# str(modSummary)

# save(modSummary, file=paste0(dataOutDir, 'modSummary.RData'))
saveRDS(modSummary, file=output_file)