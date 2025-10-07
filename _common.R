# _common.R - Global setup and shared objects
# ===========================================

# Load required libraries
library(tidyverse)
library(xts)
library(timeSeries)
library(fPortfolio)
library(PerformanceAnalytics)
library(Hmisc)
library(pastecs)
library(kableExtra)
library(moments)
library(copula)
library(VineCopula)
library(esgtoolkit)
library(rvinecopulib)

# Set global options
options(scipen = 999)
knitr::opts_chunk$set(
  echo = FALSE,
  warning = FALSE,
  message = FALSE,
  cache = TRUE,
  fig.retina = 2,
  fig.width = 7,
  fig.height = 5,
  fig.align = "center",
  out.width = "100%"
)

# Custom theme for plots
theme_set(theme_minimal() +
            theme(
              plot.title = element_text(size = 14, face = "bold"),
              axis.title = element_text(size = 12),
              legend.position = "bottom"
            ))

# ===========================================
# LOAD DATA
# ===========================================

# Check if data exists, load or create
if (!file.exists("data/processed_data.rds")) {
  # Load raw data
  endow_data <- readRDS("latestEndowData.rds")
  
  # Create derived objects
  endow_xts <- xts(endow_data[, -1], order.by = as.Date(endow_data$caldt))
  risky_assets <- endow_data %>% select(-caldt, -tBillReturn)
  risky_ts <- as.timeSeries(risky_assets)
  returns_matrix <- as.matrix(risky_assets)
  
  # Save processed data
  dir.create("data", showWarnings = FALSE)
  saveRDS(list(
    endow_data = endow_data,
    endow_xts = endow_xts,
    risky_assets = risky_assets,
    risky_ts = risky_ts,
    returns_matrix = returns_matrix
  ), "data/processed_data.rds")
} else {
  # Load existing processed data
  data_list <- readRDS("data/processed_data.rds")
  list2env(data_list, envir = .GlobalEnv)
}

# ===========================================
# PORTFOLIO OPTIMIZATION (cached)
# ===========================================

if (!file.exists("data/portfolio_objects.rds")) {
  # Create portfolio specification
  spec_long <- portfolioSpec()
  setRiskFreeRate(spec_long) <- 0
  setSolver(spec_long) <- "solveRquadprog"
  
  spec_short <- portfolioSpec()
  setRiskFreeRate(spec_short) <- 0
  setSolver(spec_short) <- "solveRshortExact"
  
  # Calculate efficient frontiers
  frontier_long <- portfolioFrontier(
    data = risky_ts,
    spec = spec_long,
    constraints = "LongOnly"
  )
  
  frontier_short <- portfolioFrontier(
    data = risky_ts,
    spec = spec_short,
    constraints = "Short"
  )
  
  # Special portfolios
  mvp <- minvariancePortfolio(risky_ts)
  tangency <- tangencyPortfolio(risky_ts, spec = spec_long)
  
  # Save portfolio objects
  saveRDS(list(
    spec_long = spec_long,
    spec_short = spec_short,
    frontier_long = frontier_long,
    frontier_short = frontier_short,
    mvp = mvp,
    tangency = tangency
  ), "data/portfolio_objects.rds")
} else {
  # Load existing portfolio objects
  port_list <- readRDS("data/portfolio_objects.rds")
  list2env(port_list, envir = .GlobalEnv)
}

# ===========================================
# VINE COPULA SIMULATION (cached - expensive!)
# ===========================================

if (!file.exists("data/vine_results.rds")) {
  
  # Define simulation function
  simulate_rvine <- function(data, n = nrow(data), n_trials = 5, verbose = FALSE) {
    require(rvinecopulib)
    require(VineCopula)
    
    if (verbose) cat("Transforming data to uniform margins...\n")
    u_data <- pobs(as.matrix(data))
    
    if (verbose) cat("Fitting R-vine copula model...\n")
    vine_model <- vinecop(u_data, 
                          family_set = c("gaussian", "t", "clayton", 
                                         "gumbel", "frank", "joe"),
                          tree_crit = "tau")
    
    if (verbose) cat("Running", n_trials, "simulation trials...\n")
    
    best_sim <- NULL
    best_score <- Inf
    
    for (trial in 1:n_trials) {
      u_sim <- rvinecop(n, vine_model)
      sim_data <- matrix(NA, n, ncol(data))
      for (j in 1:ncol(data)) {
        sim_data[, j] <- quantile(data[, j], probs = u_sim[, j], type = 8)
      }
      colnames(sim_data) <- colnames(data)
      
      cor_diff_kendall <- mean(abs(cor(sim_data, method = "kendall") - 
                                     cor(data, method = "kendall")))
      cor_diff_pearson <- mean(abs(cor(sim_data) - cor(data)))
      score <- 0.5 * cor_diff_kendall + 0.5 * cor_diff_pearson
      
      if (score < best_score) {
        best_score <- score
        best_sim <- sim_data
      }
    }
    
    result <- list(
      original_data = data,
      simulated_data = best_sim,
      vine_model = vine_model,
      quality_score = best_score,
      diagnostics = list(
        cor_original = cor(data),
        cor_simulated = cor(best_sim),
        cor_diff = cor(best_sim) - cor(data)
      )
    )
    
    class(result) <- "rvine_simulation"
    return(result)
  }
  
  # Run vine copula simulation
  set.seed(123)
  result <- simulate_rvine(returns_matrix, 
                           n = nrow(returns_matrix) * 2,
                           n_trials = 5, 
                           verbose = TRUE)
  
  # Fit vine copula structure
  pseudo_obs <- pobs(returns_matrix)
  vine_fit <- vinecop(
    pseudo_obs,
    family_set = c("gaussian", "t", "clayton", "gumbel", "frank", "joe"),
    tree_crit = "tau",
    trunc_lvl = Inf,
    cores = 1
  )
  
  # Save vine results
  saveRDS(list(
    result = result,
    vine_fit = vine_fit,
    pseudo_obs = pseudo_obs
  ), "data/vine_results.rds")
  
} else {
  # Load existing vine results
  vine_list <- readRDS("data/vine_results.rds")
  list2env(vine_list, envir = .GlobalEnv)
}

# ===========================================
# HELPER FUNCTIONS
# ===========================================

# Portfolio weights
eq_weights <- rep(1/ncol(returns_matrix), ncol(returns_matrix))
mvp_weights_vec <- as.vector(getWeights(mvp))
tangency_weights_vec <- as.vector(getWeights(tangency))

# Risk-free rate
rf_rate <- mean(endow_data$tBillReturn, na.rm = TRUE)

cat("Global objects loaded successfully.\n")
cat("Data period:", format(range(endow_data$caldt), "%Y-%m-%d"), "\n")
cat("Assets:", ncol(risky_assets), "\n")
cat("Observations:", nrow(endow_data), "\n")