


B.fixed <- data.frame(coef = c("a", "b", "c"), mean = c(1, 0.5, 2))
B.huc <- data.frame(huc = as.factor(rep(1:10, 3)),  coef = rep(c("d", "e", "f"), each = 10), mean = c(rnorm(10, 2), rnorm(10, 10), rnorm(10, 1, 0.2)))
B.site <- data.frame(site = as.factor(rep(1:100, 3)),  coef = rep(c("d", "e", "f"), each = 100), mean = c(rnorm(100, 1), rnorm(100, 1, 0.5), rnorm(100, 0.5, 0.1)))
B.year <- data.frame(year = as.factor(rep(2001:2010, 4)),  coef = rep(c("g", "h", "i", "j"), each = 10), mean = c(rnorm(10, 0.5), rnorm(10, 0.2, 0.2), rnorm(10, 1, 0.2), rnorm(10, 2, 0.5)))

data <- data.frame(
  row = 1:1000,
  site = as.factor(rep(1:100, length.out = 1000)),
  huc = as.factor(rep(1:10, length.out = 1000)),
  year = as.factor(rep(2001:2010, each = 100)),
  a = rnorm(1000, 0),
  b = rnorm(1000, 0),
  c = rnorm(1000, 0),
  d = rnorm(1000, 0),
  e = rnorm(1000, 0),
  f = rnorm(1000, 0),
  g = rnorm(1000, 0),
  h = rnorm(1000, 0),
  i = rnorm(1000, 0),
  j = rnorm(1000, 0)
)

data.random.sites <- dplyr::select(data, d, e, f)

dplyr::filter(B.huc, huc == as.character(data$huc[1]))$mean %*% t(data.random.sites[1, ])

dplyr::filter(B.huc, huc == as.character(data$huc[1]))$mean %*% t(select(data, d, e, f)[1, ])

mutate(data, rsite.ef = dplyr::filter(B.huc, huc == as.character(data$huc))$mean %*% select(data, d, e, f))
apply(data, MARGIN = 1, FUN = dplyr::filter(B.huc, huc == as.character(data$huc))$mean %*% select(data, d, e, f))

left_join(data, B.huc, by = "huc")

trend <- NA
for(i in 1:length(firstObsRows)) {
  trend[firstObsRows[i]] <- as.numeric(
    B.fixed$mean %*% t(df$data.fixed[firstObsRows[i], ]) + 
      dplyr::filter(B.huc, huc == as.character(data$HUC8[firstObsRows[i]]))$mean %*% t(df$data.random.sites[firstObsRows[i], ]) + 
      dplyr::filter(B.site, site == as.character(data$site[firstObsRows[i]]))$mean %*% t(df$data.random.sites[firstObsRows[i], ]) + 
      dplyr::filter(B.year, year == as.character(data$year[firstObsRows[i]]))$mean %*% t(df$data.random.years[firstObsRows[i], ])
  )
  
  Pred[firstObsRows[i]] <- trend[firstObsRows[i]]
}

for(i in 1:length(evalRows)) {
  trend[evalRows[i]] <- as.numeric(
    B.fixed$mean %*% t(df$data.fixed[evalRows[i], ]) + 
      dplyr::filter(B.huc, huc == as.character(data$HUC8[evalRows[i]]))$mean %*% t(df$data.random.sites[evalRows[i], ]) + 
      dplyr::filter(B.site, site == as.character(data$site[evalRows[i]]))$mean %*% t(df$data.random.sites[evalRows[i], ]) + 
      dplyr::filter(B.year, year == as.character(data$year[evalRows[i]]))$mean %*% t(df$data.random.years[evalRows[i], ]) 
  )
  
  if(is.na(data$temp[evalRows[i]-1]) | is.null(data$temp[evalRows[i]-1])) {
    Pred[evalRows[i]] <- trend[evalRows[i]]
  } else {
    Pred[evalRows[i]] <- trend[evalRows[i]] + 
      dplyr::filter(B.ar1, site == as.character(data$site[evalRows[i]]))$mean * (data$temp[evalRows[i]-1] - trend[evalRows[i]-1])
  }
  #as.numeric(B.ar1$mean * (data$temp[evalRows[i]-1] - trend[evalRows[i]-1]))
}
