# =====================================================
# 📦 Initial Setup Script for PF_INE 2023 Analysis
# Shutian Xue — April 8, 2025
# Updated: Jul, 2025
# =====================================================
# This script sets up the analysis environment:
#   - Loads necessary libraries
#   - Sets global flags and subject lists
#   - Defines folder structure and visual settings
#   - Should be sourced at the beginning of all analysis scripts
# =====================================================

# ==== 📚 Load Libraries ====
library(lmerTest)      # Linear mixed models with p-values
library(emmeans)       # Estimated marginal means (EMMs)
library(ggplot2)       # Data visualization
library(dplyr)         # Data manipulation
library(MuMIn)         # R² for LMMs
library(effectsize)    # Effect size (partial eta-squared)
library(partR2)        # Partial R²
library(ppcor)         # Partial correlation
library(bbmle)         # Information criteria tools
library(scales)        # for coloring in plotting
library(purrr)         # for map2_chr in 1Modulation
library(tidyr)
library(doParallel)
library(stringr)

# ==== 🧹 Clean Environment ====
graphics.off()         # Close all open plots
cat("\014")            # Clear console

# ==== Performance level to analyze
PerfLevel_s <- 0.75

# ==== 👥 Define Subjects ====
str_n9 <- ""
if (str_SF == "SF46") {
  if (flag_n9 == 1) {
    nsubj <- 9
    subjList <- c("AD", "DT", "HH", "HL", "LL", "MD", "RC", "SX", "ZL")
    str_n9 <- "_n9"
  } else {
    nsubj <- 12
    subjList <- c("AD", "DT", "HH", "HL", "LL", "MD", "RC", "SX", "ZL", "ASM", "JY", "RE")
  }
} else if (str_SF == "SF456") {
  nsubj <- 22
  subjList <- c(
    "AD", "DT", "HH", "HL", "LL", "MD", "RC", "SX", "ZL",     # SF4
    "ASM", "JY", "RE",                                        # SF6
    "fc", "ja", "jfa", "zw", "AB", "ASF", "CM", "LH", "MJ", "SP"  # SF5
  )
} else if (str_SF == "SF6") {
  nsubj <- 12
  subjList <- c("AD", "DT", "HH", "HL", "LL", "MD", "RC", "SX", "ZL", "ASM", "JY", "RE")
} else {
  stop("❌ Invalid SF value.")
}

# Create a list of unique shaoes for each subject
subject_shapes <- seq(0, nsubj - 1)
shape_SF <- c(
    "4" = 21,
    "5" = 22,
    "6" = 24
  )

# ==== 📁 Folder Paths ====

# Set the working directory to Rscripts/Codes
#library(here)
#setwd(here("Codes", "Rscripts", "Codes"))

# Server path
nameFolder_server <- '/Volumes/server/Users/purplab/EXPERIMENTS/1_Current_Experiments/Shutian_server/PF_EN'; 

# Define the directory to load data from (Data/R_DataTable)
nameFolder_Load <- sprintf("%s/Data/R_DataTable/%s%s", nameFolder_server, str_SF, str_n9)

# Define the directory to save figures
nameFolder_Figures <- sprintf("%s/Figures/acrossSFs/%s%s/R_Figures", nameFolder_server, str_SF, str_n9)
if (!dir.exists(nameFolder_Figures)) dir.create(nameFolder_Figures, recursive = TRUE)

# Define the directory to save outputs
nameFolder_Outputs <- sprintf("%s/R_outputs/%s%s", nameFolder_server, str_SF, str_n9)
if (!dir.exists(nameFolder_Outputs)) dir.create(nameFolder_Outputs, recursive = TRUE)

# ==== 🔁 Define Pair Mapping for Location Groups ====
pair_mapping <- list(
  "FovHM4HM8"   = c("Pair12", "Pair13", "Pair23"),
  "FovVM4VM8"   = c("Pair12", "Pair13", "Pair23"),
  "HM4VM4"      = c("Pair12"),
  "HM8VM8"      = c("Pair12"),
  "LVM4UVM4"    = c("Pair12"),
  "LVM8UVM8"    = c("Pair12"),
  "FovEcc4Ecc8" = c("Pair12", "Pair13", "Pair23")
)

# ==== ⚙️ Global Analysis Flags ====
flag_dv <- 2            # 1 = raw threshold, 2 = transformed performance (recommended)
str_REML <- FALSE       # Use ML (not REML) for model fitting
df_method <- "Kenward-Roger"  # Degrees of freedom method for ANOVA

# ==== 🎨 Plot Settings ====
sz_marker <- 2          # Marker size
set.seed(123)  # for reproducible jitter
jitter_width <- 0.05

# ==== 🎨 Define Custom Colors for Locations ====
location_colors <- c(
  "01Fov"   = rgb(0, 0, 0),
  "02Ecc4"  = rgb(0.4, 0.4, 0.4),
  "03Ecc8"  = rgb(0.6, 0.6, 0.6),
  "04HM4"   = rgb(0, .4, 0),
  "05VM4"   = rgb(0.5, 0, 1),
  "06LVM4"  = rgb(1, 0, 0),
  "07UVM4"  = rgb(0, 0, 1),
  "08HM8"   = rgb(0, .9, .25),
  "09VM8"   = rgb(0.75, 0.6, 0.95),
  "10LVM8"  = rgb(1, 0.5, 0.5),
  "11UVM8"  = rgb(0.5, 0.75, 1),
  "HM"  = rgb(0, .4, 0),
  "VM"  = rgb(0.5, 0, 1),
  "LVM"  = rgb(1, 0, 0),
  "UVM"  = rgb(0, 0, 1)
)

sf_colors <- c(
  "4" = rgb(0, 0, 0),
  "5" = rgb(0, 0, 0),
  "6" = rgb(0, 0, 0)
)

# Axis limit of params
# limits_params <- list(
#   "Gain"  = c(0.5, 4.5), # ub+1
#   "Nadd"  = c(-5, 0),
#   "Gamma" = c(0, 4+1)
# )

# define the position of inset histograms
limits_params_hist <- list(
  "ThreshN0_t"  = c(0, 1.6), # ub+1
  "Gain"  = c(3.5, 5), # ub+1
  "Nadd"  = c(-7 -5.5),
  "Gamma" = c(0, 1.5)
)

# ticks and lim for raw values
nTicks <- 5
# limits_params <- list(
#   "Thresh_t"  = c(0, 2), # ub+1
#   "GainLog"  = c(-.3, .7), # log gain
#   "Gain"  = c(0, 5), # linear gain
#   "Nadd"  = c(-6,0),
#   "Gamma" = c(0, 5)
# )

yticks_param <- list(
  "ThreshN0_t"  = seq(0, 2, length.out = nTicks),
  "GainLog"  = seq(-.3, .7, length.out = nTicks),
  "Gain"  = seq(0, 4, length.out = nTicks),
  "Nadd"  = seq(-6, 0, length.out = nTicks),
  "Gamma" = seq(0, 6, length.out = nTicks)
)

# ticks and lim for LDIs
param_LDI_info <- list(
  ThreshN0_t_LDI = list(label = "LDI for Performance"), yticks = seq(0, .4, length.out = nTicks),
  GainLog_LDI = list(label = "LDI for GainLog", yticks = seq(0.3, 0.9, length.out = nTicks)),
  Gain_LDI = list(label = "LDI for log Gain", yticks = seq(-0.3, 0.9, length.out = nTicks)),
  Nadd_LDI = list(label = "LDI for additive noise", yticks = seq(-0.2, 0.6, length.out = nTicks)),
  Gamma_LDI = list(label = "LDI for nonlinearity", yticks = seq(-0.2, 0.6, length.out = nTicks))
)


# Define height of comparison lines for 2-way interaction (in R_2V_boot_plot)
# For interaction (Gain only), the height depends on SF
y_buffer <- .4
y_start_SF4 <- .5
y_start_SF6 <- 3.2
line_interaction_Gain <- data.frame(
  SF = rep(c(4, 6), each = 3),
  x = c(1, 1, 2, 1, 1, 2),
  xend = c(3, 2, 3, 3, 2, 3),
  y = c(
    y_start_SF4 + y_buffer * 0:2,  # for SF = 4
    y_start_SF6 + y_buffer * 0:2   # for SF = 6
  ),
  yend = c(
    y_start_SF4 + y_buffer * 0:2,
    y_start_SF6 + y_buffer * 0:2
  )
)

# For main effects (Nadd and Gamma only)
y_start_ME <- list(
  Gain = 3.5,
  Nadd = -1,
  Gamma = 5,
  GainLog = 0.5,
  ThreshN0_t = 0.5
)

# Define height of comparison lines for 3-way interaction (in R_2V_boot_plot_2ECC)
y_start_3way <- list(
  Gain = -1,
  Nadd = 1,
  Gamma = -1,
  GainLog = 0.5,
  ThreshN0_t = 1.75
)

line_style <- c("4" = "dotdash", "5" = "dashed", "6" = "solid")

# ==== Bootstrapping ====
perc_CI <- .95
perc_lb <- (1-perc_CI)/2
perc_ub <- 1-perc_lb

perc_CI_plot <- .68
perc_lb_plot <- (1-perc_CI_plot)/2
perc_ub_plot <- 1-perc_lb_plot


cat(sprintf("=============================================== \nSettings DONE for %s%s (Perf=%.2f, nBoot=%d) \n===============================================", str_SF, str_n9, PerfLevel_s, nBoot))
