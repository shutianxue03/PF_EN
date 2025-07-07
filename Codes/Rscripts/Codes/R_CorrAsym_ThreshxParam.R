# Load libraries
library(lme4)       
library(lmerTest)   
library(emmeans)    
library(ggplot2)    
library(performance)
library(dplyr)      
library(pbkrtest)
library(effectsize)  
library(writexl)
library(ggpubr)  
library(ppcor) # for partial correlation

# Clear environment
rm(list = ls()) 
graphics.off() 
cat("\014")

# Set working directory
setwd("/Volumes/purplab/EXPERIMENTS/1_Current_Experiments/Shutian_server/PF_INE_2023/Rscripts")

# Define location groups and dependent variables
str_loc_list <- c("FovEcc4Ecc8", "FovHM4HM8", "FovVM4VM8", "HM4VM4", "HM8VM8", "LVM4UVM4", "LVM8UVM8")
dv_asym_list <- c("Gain_asym", "Gamma_asym", "Nadd_asym")

# Define SF-specific shapes
sf_shapes <- c("4" = 22, "5" = 5, "6" = 23)  # Square, Star, Hexagon

# Define number of pairs for each location group
pair_mapping <- list(
  "FovEcc4Ecc8" = c("Pair12", "Pair13", "Pair23"),
  "FovHM4HM8" = c("Pair12", "Pair13", "Pair23"),
  "FovVM4VM8" = c("Pair12", "Pair13", "Pair23"),
  "HM4VM4" = c("Pair12"),
  "HM8VM8" = c("Pair12"),
  "LVM4UVM4" = c("Pair12"),
  "LVM8UVM8" = c("Pair12")
)

# Set data directory
dir_current <- "/Volumes/purplab/EXPERIMENTS/1_Current_Experiments/Shutian_server/PF_INE_2023/Rscripts"

# Define hypothetical correlation slope
Slope_hypo_all <- list(
  "Gamma_asym" = "less",   # Assume negative correlation
  "Gain_asym" = "greater", # Assume positive correlation
  "Nadd_asym" = "greater"  # Assume positive correlation
)

# Initialize data frame to store results
correlation_results <- data.frame(
  Location = character(), Pair = character(), DV = character(),
  Pearson_r = numeric(), Pearson_p = numeric(), Pearson_p_1tailed = numeric(),
  Spearman_rho = numeric(), Spearman_p = numeric(), Spearman_p_1tailed = numeric(),
  Slope_hypo = character(), stringsAsFactors = FALSE
)

# Define (and create) output directory
dir_fig <- sprintf("%s/Figures_CorrAsym", nameFolder_Figures)
if (!dir.exists(dir_fig)) {dir.create(dir_fig, recursive = TRUE)}

# Loop through location, DV, and pairs
for (str_loc in str_loc_list) {
  iPair_list <- pair_mapping[[str_loc]]  
  
  for (dv_asym in dv_asym_list) {
    for (str_Pair in iPair_list) {  
      print(sprintf("*** Location: %s | DV: %s | Pair: %s ***", str_loc, dv_asym, str_Pair))
      
      # Load and prepare data
      data_file <- file.path(dir_current, sprintf("dataTable/dataTable_asym_%s_%s.csv", str_loc, str_Pair))
      dataTable_asym <- read.csv(data_file)
      
      # Convert variables
      dataTable_asym$Subj <- as.factor(dataTable_asym$Subj)       
      dataTable_asym$SF <- as.factor(dataTable_asym$SF)  
      dataTable_asym$Thresh_asym <- as.numeric(dataTable_asym$Thresh_asym)  
      
      # Get hypothetical correlation slope
      Slope_hypo <- Slope_hypo_all[[dv_asym]]
      
      # Compute partial Spearman correlation controlling for SF
      partial_spearman_cor <- pcor.test(
        x = dataTable_asym$Thresh_asym,
        y = dataTable_asym[[dv_asym]],
        z = as.numeric(as.character(dataTable_asym$SF)),  # Control variable, needs to be numeric
        method = "spearman"
      )
      
      # Extract partial correlation results
      spearman_rho_partial <- round(partial_spearman_cor$estimate, 3)
      spearman_p_partial <- round(partial_spearman_cor$p.value, 3)
      spearman_p_partial_1tailed <- round(spearman_p_partial / 2, 3)
      
      # Store results in dataframe
      correlation_results <- rbind(correlation_results, data.frame(
        Location = str_loc,
        Pair = str_Pair,
        DV = dv_asym,
        Slope_hypo = Slope_hypo,
        Spearman_rho = spearman_rho_partial,
        Spearman_p = spearman_p_partial,
        Spearman_p_1tailed = spearman_p_partial_1tailed
      ))
      
      ### PLOTTING ###
      # Create scatterplot with regression lines
      p <- ggplot(dataTable_asym, aes(x = !!sym(dv_asym), y = Thresh_asym, color = SF)) +
        geom_point(size = 3) +
        scale_shape_manual(values = sf_shapes) +
        scale_color_manual(values = c("4" = "blue", "5" = "red", "6" = "green")) +
        scale_fill_manual(values = c("4" = "blue", "5" = "red", "6" = "green")) +
        geom_smooth(method = "lm", se = FALSE, linewidth = 1.5, aes(group = SF)) +  # Regression for each SF
        # geom_smooth(method = "lm", se = FALSE, linewidth = 2, color = "black", linetype = "dashed", aes(group = 1)) +  # Overall regression
        stat_cor(method = "Spearman", label.x.npc = "left", label.y.npc = "top", size = 5) +  # Spearman correlation annotation
        annotate("text", x = min(dataTable_asym[[dv_asym]], na.rm = TRUE), 
                 y = max(dataTable_asym$Thresh_asym, na.rm = TRUE), 
                 label = sprintf("Partial rho = %.3f (p = %.3f)", spearman_rho_partial, spearman_p_partial_1tailed),
                 hjust = 0, vjust = 1, size = 5, fontface = "bold") +
  
        labs(
          title = sprintf("Thresh_asym vs. %s [%s %s] (control for SF)", dv_asym, str_loc, str_Pair),
          x = "Thresh_asym",
          y = dv_asym,
          color = "SF",
          shape = "SF"
        ) +
        theme_minimal(base_size = 12) +
        theme(
          panel.background = element_rect(fill = "white", color = "white"),  # Ensure white background
          plot.background = element_rect(fill = "white", color = "white"),   # White plot background
          legend.position = "right",
          plot.title = element_text(size = 14, face = "bold"),
          axis.title = element_text(size = 12, face = "bold"),
          axis.text = element_text(size = 12),
          legend.text = element_text(size = 12),
          legend.title = element_text(size = 12, face = "bold")
        )
      
      # Save the figure
      ggsave(filename = file.path(dir_fig, sprintf("%s_%s_%s.png", str_loc, dv_asym, str_Pair)), 
             plot = p, width = 8, height = 6, dpi = 300)
      
    } # End Pair loop
  } # End DV loop
} # End Location loop

# Save all correlation results to a single Excel sheet
write_xlsx(list(Correlation_Results = correlation_results), "Summary_CorrAsym.xlsx")

print("All correlation results and figures saved successfully!")
