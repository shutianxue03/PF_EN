# ============================================
# Batch Analysis Script: PF_INE_2023 Project
# ============================================
# This script automates the batch analysis of PF_INE_2023 experimental data 
# across different SF x Subj configurations to run three analysis steps:
#   1. Modulation: does each parameter modulate performance (intercept threshold?
#   2. Variation: does each parameter vary throughout the visual field?
#   3. Contribution: how much doeslocation difference of each parameter contribute to the location difference of performance?
# ✏️ Author: Shutian Xue
# 📅 Last Updated: May 4, 2025
#
# ============================================

rm(list = ls())      # Uncomment to clear all variables

# ==== 📁 Set Working Directory ====
# nameFolder <- "/Volumes/purplab/EXPERIMENTS/1_Current_Experiments/Shutian_server/PF_INE_2023" # change this to PF_EN later
nameFolder <- "/Users/xueshutian/Desktop/GitHub_local/PF_EN/Codes/Rscripts/Codes" # change this to PF_EN later
setwd(nameFolder)
# nameFolder_Figures <- "/Volumes/purplab/EXPERIMENTS/1_Current_Experiments/Shutian_server/PF_INE_2023/Figures/R_Figures"

# Select bootstrapping mode (1 or 1000)
nBoot <- 1000

# ==== 🛠️ Define SF x Subj configurations ====
str_SF <- "SF46"; flag_n9 <- 0
configs <- list(
  list(str_SF = "SF46", flag_n9 = 0) # Include SF4 (n=9) and SF6 (n=12, 9 shared with SF4)
  # list(str_SF = "SF6",  flag_n9 = 0), # Include SF6 (n=12)
  # list(str_SF = "SF46", flag_n9 = 1), # Include SF4 (n=9) and SF6 (n=9 shared with SF4)
  # list(str_SF = "SF456",  flag_n9 = 0) # Include SF4 (n=9), SF5 (n=10, unique) and SF6 (n=12)
)

# ==== 🧠 Loop through configurations ====
for (cfg in configs) {configs
  str_SF <- cfg$str_SF
  flag_n9 <- cfg$flag_n9
 
  cat(sprintf("\n--- Running for %s (n9 = %d) ---\n", str_SF, flag_n9))
  
  start_time0 <- Sys.time() # ⏱️ tic
  
  # ---- 0. Setting ----
  source("R_0Setting.R")
  
  # ---- Nested PTM comparison (xx min) ----
  # str_loc_list <- c("FovHM4LVM4UVM4HM8LVM8UVM8") # List of location groups
  # source("R_nestedMC.R")
  
  # ---- 1. Modulation (2 min) ----
  str_loc_list <- c("FovHM4LVM4UVM4HM8LVM8UVM8") # List of location groups
  #source("R_1Modulation_boot.R")

  # ---- 2. Variation (24 min) ----
  flag_plot7Locs <- FALSE
  
  # [STATS] Loc x SF
  str_loc_list <- c("FovHM4HM8", "FovVM4VM8", "HM4VM4", "HM8VM8", "LVM4UVM4", "LVM8UVM8", "FovEcc4Ecc8")
  #source("R_2Variation_boot_stats.R")
  
  # [STATS] Meridian/Loc x Ecc x SF
  str_loc_list <- c("HM4VM4HM8VM8", "LVM4UVM4LVM8UVM8")
  #source("R_2Variation_boot_stats_2ECC.R")
  
  # [PLOT] Across three eccentricities
  str_loc_list <- c("FovHM4HM8", "FovVM4VM8","FovEcc4Ecc8")
  source("R_2Variation_boot_plot.R")
  
  # [PLOT] Around polar angle
  str_loc_list <- c("HM4VM4", "HM8VM8", "LVM4UVM4", "LVM8UVM8");
  source("R_2Variation_boot_plot.R")
  
  # [PLOT] Meridian/Loc x Ecc x SF
  str_loc_list <- c("HM4VM4HM8VM8", "LVM4UVM4LVM8UVM8")
  source("R_2Variation_boot_plot_2ECC.R")
  
  # ---- 3. Contribution (16 min) ----
  str_loc_list <- c("FovHM4HM8", "FovVM4VM8", "HM4VM4", "HM8VM8", "LVM4UVM4", "LVM8UVM8", "FovEcc4Ecc8")
  #source("R_3Contribution_boot.R")
  #source("R_3Contribution_BIN.R")
  
  # ---- END ----
  end_time0 <- Sys.time() # ⏱️ toc
  
  dur0 <- end_time0 - start_time0
  print(round(dur0, 1))
  cat(sprintf(
    "\n\n============= %s%s (P%.0f) ALL DONE ==============\n",
    str_SF, str_n9, PerfLevel_s * 100
  ))
}
