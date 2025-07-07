# Script: PMF_GoF_Comparison.R
# Author: Shutian Xue
# Date: March 5, 2025
# 

# This script analyzes the GoF (BIC and R2) of PMF fitting across four IVs:
# - SF [categorical, 3 levels]: 4,5,6 cpd
# - Loc [categorical, 9 levels]
# - NoiseSD [double]: 7 levels for SF=5, 9 identical levels for SF=4 and 6
# - PMF model [categorical, 4 levels]

# Main question: Whether BIC varies across SF, Loc, NoiseSD, and PMF model
# Decision to be made: Should SF = 5 be excluded due to poor fit?

# 0. Setting up ----
# Load libraries
library(lmerTest)   
library(emmeans)    
library(ggplot2)
library(dplyr)      
library(pbkrtest)

# Clear environment
graphics.off() 
cat("\014")

# Create folder for figures
nameFolder_Fig <- sprintf("%s/Figures_PMF_GoF", nameFolder_Figures)
if (!dir.exists(nameFolder_Fig)) {dir.create(nameFolder_Fig, recursive = TRUE)} # create a new folder

# Name variable levels
names_LocSingle <- c('Fovea', 'LHM4', 'UVM4', 'RHM4', 'LVM4', 'LHM8', 'UVM8', 'RHM8', 'LVM8')

# Define custom colors for locations (using the provided RGB values)
colors_single <- c(
    "Fovea"  = rgb(0, 0, 0),       # Black
    "LHM4"   = rgb(0, 0.7, 0),     # Light Green (g2)
    "UVM4"   = rgb(0, 0, 1),       # Blue
    "RHM4"   = rgb(0, 0.5, 0),     # Dark Green (g1)
    "LVM4"   = rgb(1, 0, 0),       # Red
    "LHM8"   = rgb(0, 0.8, 0),     # Lighter Green (g3)
    "UVM8"   = rgb(0.5, 0.75, 1),  # Light Blue
    "RHM8"   = rgb(0, 0.7, 0),     # Light Green (g2)
    "LVM8"   = rgb(1, 0.5, 0.5)    # Light Red
)

# Define conditions (SF x nSubj)
str_SF <- "SF456"; flag_n9 <- 0 # 1=only include the 9 shared subjects
# str_SF <- "SF46"; flag_n9 <- 0 # 1=only include the 9 shared subjects
# str_SF <- "SF46"; flag_n9 <- 1 # 1=only include the 9 shared subjects

str_n9 <- ""
if (str_SF == "SF46") {
  if (flag_n9 == 1) {
    nsubj <- 9
    subjList <- c('AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL') #SF6, n=9+3 unique
    str_n9 <- "_n9"
  }
  else {
    nsubj <- 12
    subjList <- c('AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL', #SF4, n=9
                  'ASM', 'JY', 'RE') #SF6, n=9+3 unique
  }
  
} else if (str_SF == "SF456") {
  nsubj <- 22
  subjList <- c('AD', 'DT', 'HH', 'HL', 'LL', 'MD', 'RC',  'SX', 'ZL', #SF4, n=9
                'ASM', 'JY', 'RE', #SF6, n=9+3 unique
                'fc', 'ja', 'jfa', 'zw',    'AB', 'ASF', 'CM', 'LH', 'MJ', 'SP') #SF5, n=10 unique people)
} else {
  stop("Invalid SF value.")
}


# Create a mapping from Subj (1-22) to SubjNames
subj_mapping <- data.frame(Subj = 1:nsubj, subjName = subjList)

# Define the ylimit for each GoF
GoF_limits <- list(
    "BIC" = c(-400, 50),
    "R2"  = c(0, 1)
)
# Define how much higher the stats (Ave+1SEM) are printed in the figure
GoF_text_buffer <- list(
    "BIC" = 30,
    "R2"  = .05
)


# 1. Which PMF model is the best [Kudos to Weibull!] ----
library(nortest)
library(FSA)

names_PMFmodels <- c('Logistic', 'CumNorm', 'Gumbel', 'Weibull')

# Load data table
dataTable_PMF_GoF_all4 <- read.csv(sprintf("%s/DataTable/%s%s/PMF_GoF_All4.csv", nameFolder, str_SF, str_n9))

# Mutate factors
dataTable_PMF_GoF_all4 <- dataTable_PMF_GoF_all4 %>%
    mutate(
        Loc = factor(Loc, labels = c('Fovea', 'LHM4', 'UVM4', 'RHM4', 'LVM4', 'LHM8', 'UVM8', 'RHM8', 'LVM8')),
        SF = factor(SF, levels = c(4, 5, 6)),  # Ensure SF is categorical
        PMF = factor(PMF, labels = c('Logistic', 'CumNorm', 'Gumbel', 'Weibull'))  # Map numbers to model names
    )

GoF_all4 <- "BIC"
# GoF_all4 <- "R2"

# Check Normality (for choosing the right test)
ad.test(dataTable_PMF_GoF_all4[[GoF_all4]])  # If p < 0.05, data is not normal

# Run Kruskal test (because data is not normal)
kruskal.test(as.formula(sprintf("%s ~ PMF", GoF_all4)), data = dataTable_PMF_GoF_all4)

# Multiple comparisons
dunnTest(as.formula(sprintf("%s ~ PMF", GoF_all4)), data = dataTable_PMF_GoF_all4, method = "bonferroni")

# Base violin plot using GoF variable dynamically
p <- ggplot(dataTable_PMF_GoF_all4, aes(x = PMF, y = !!sym(GoF_all4), fill = PMF)) +
    geom_violin(alpha = 0.5) +  # Show GoF distribution for each model
    geom_boxplot(width = 0.1, fill = "white", outlier.shape = NA) +  # Add boxplot inside violin
    theme_bw() +
    labs(title = sprintf("%s Comparison Across PMF Models", GoF_all4),
         x = "PMF Model",
         y = GoF_all4,
         fill = "PMF Model")
print(p)


# Then just Focus on Weibull!!

# 2. (Using Weibull function), does GoF vary across SF ----
# Load data table
dataTable_PMF_GoF <- read.csv(sprintf("%s/DataTable/%s%s/PMF_GoF_Weibull.csv", nameFolder, str_SF, str_n9))

# Mutate factors
dataTable_PMF_GoF <- dataTable_PMF_GoF %>%
    mutate(
        Loc = factor(Loc, labels = c('Fovea', 'LHM4', 'UVM4', 'RHM4', 'LVM4', 'LHM8', 'UVM8', 'RHM8', 'LVM8')),
        SF = factor(SF, levels = c(4, 5, 6)),  # Ensure SF is categorical
    )

# Define GoF
GoF <- "BIC"
# GoF <- "R2"

# 📊 1. Visualization: Violin Plot of GoF across SF ----
for (loc in names(colors_single)) {
    
    # Compute mean and 1 SEM for each SF & NoiseSD within the current location
    summary_stats <- dataTable_PMF_GoF %>%
        filter(Loc == loc) %>%
        group_by(Loc, SF, NoiseSD) %>%  # Ensure Loc is included
        summarise(
            Mean_GoF = mean(!!sym(GoF), na.rm = TRUE),
            SEM_GoF = sd(!!sym(GoF), na.rm = TRUE) / sqrt(n()),
            .groups = "drop"
        )
    
    p <- ggplot(filter(dataTable_PMF_GoF, Loc == loc), 
                aes(x = as.factor(NoiseSD), y = !!sym(GoF), fill = factor(Loc))) +  # Ensure Loc is a factor
        # Add grey thin lines connecting the same subjects
        geom_line(aes(group = Subj), color = "grey60", alpha = 0.5, size = 0.3) +
        # Add Mean ± SEM error bars, colored by Location
        geom_errorbar(data = summary_stats, 
                      aes(x = as.factor(NoiseSD), ymin = Mean_GoF - SEM_GoF, ymax = Mean_GoF + SEM_GoF, color = factor(Loc)), 
                      width = 0.1, inherit.aes = FALSE, size = 0.7) +
        # Add Mean points, colored by Location
        geom_point(data = summary_stats, 
                   aes(x = as.factor(NoiseSD), y = Mean_GoF, color = factor(Loc)), 
                   size = 3) +
        
        facet_wrap(~SF) +  # Separate plots for each SF
        scale_fill_manual(values = colors_single) +  # Assign custom colors to locations
        coord_cartesian(ylim = GoF_limits[[GoF]]) +  # Dynamically set y-axis limits
        theme_bw() +
        labs(title = sprintf("%s Across Noise Levels for Each SF - %s", GoF, loc),
             x = "Noise Level (NoiseSD)",
             y = GoF,
             fill = "Location") +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels
    
    print(p)
    # Save each plot dynamically in the preferred format
    ggsave(file.path(nameFolder_Fig, sprintf("%s_SFxNoise_%s.png", GoF, loc)), 
           plot = p, width = 12, height = 6, dpi = 300)
}

# 🏆 2. Linear Mixed Model to Test SF & NoiseSD Effects on GoF ----
model_GoF <- lmer(as.formula(sprintf("%s ~ SF + (1 | Loc) + (1 | Subj)", GoF)), 
                  data = dataTable_PMF_GoF)

summary(model_GoF)

# 📈 3. Post-hoc Pairwise Comparisons if SF is Significant
posthoc_results <- emmeans(model_GoF, pairwise ~ SF, adjust = "bonferroni")
print(posthoc_results)

# 3. Check for outliers ----
library(openxlsx)
# Load data table
dataTable_PMF_GoF <- read.csv(sprintf("%s/dataTable/dataTable_PMF_GoF_Weibull.csv", nameFolder))

# Merge subjName, SF, and Loc into Your Data Table
dataTable_PMF_GoF <- dataTable_PMF_GoF %>%
    left_join(subj_mapping, by = "Subj") %>%  # Merge subject names
    mutate(subjName = sprintf("%s_SF%d_L%s", subjName, SF, Loc))  # Append SF and Location

# Select Outliers based on Z-scores (BIC being normal)
# Compute mean and standard deviation of BIC and R2
BIC_ave <- mean(dataTable_PMF_GoF$BIC, na.rm = TRUE)
BIC_sd <- sd(dataTable_PMF_GoF$BIC, na.rm = TRUE)
R2_ave <- mean(dataTable_PMF_GoF$R2, na.rm = TRUE)
R2_sd <- sd(dataTable_PMF_GoF$R2, na.rm = TRUE)

# Compute Z-scores for BIC
dataTable_PMF_GoF <- dataTable_PMF_GoF %>%
    mutate(Z_BIC = (BIC - BIC_ave) / BIC_sd)%>%
    mutate(Z_R2 = (R2 - R2_ave) / R2_sd)

# Compute IQR-based outliers for BIC (data out of the middle 50% are outliers)
Q1 <- quantile(dataTable_PMF_GoF$BIC, 0.25, na.rm = TRUE)  # First quartile
Q3 <- quantile(dataTable_PMF_GoF$BIC, 0.75, na.rm = TRUE)  # Third quartile
IQR_BIC <- Q3 - Q1  # Interquartile range
lb_BIC <- Q1 - 1.5 * IQR_BIC  # Mild outliers
ub_BIC <- Q3 + 1.5 * IQR_BIC

Q1 <- quantile(dataTable_PMF_GoF$R2, 0.25, na.rm = TRUE)  # First quartile
Q3 <- quantile(dataTable_PMF_GoF$R2, 0.75, na.rm = TRUE)  # Third quartile
IQR_R2 <- Q3 - Q1  # Interquartile range
lb_R2 <- Q1 - 1.5 * IQR_R2  # Mild outliers
ub_R2 <- Q3 + 1.5 * IQR_R2

# Flag IQR-based outliers
dataTable_PMF_GoF <- dataTable_PMF_GoF %>%
    mutate(Outlier_IQR_BIC = BIC < lb_BIC | BIC > ub_BIC) %>%
    mutate(Outlier_IQR_R2 = R2 < lb_R2 | R2 > ub_R2)

# Select outliers (Z above and below a number)
wb <- createWorkbook() # Create a new Excel workbook

# Loop through Z = 2 and Z = 3
for (Z in c(2, 3)) {
    
    # Select outliers (Z above and below a number)
    outliers_Z <- dataTable_PMF_GoF %>%
        filter(abs(Z_BIC) > Z) %>%  # Select outliers based on Z-score of BIC
        filter(abs(Z_R2) > Z) %>%  # Select outliers based on Z-score of R2
        filter(R2 < .5) %>% # Select outliers based on R2<.5
        mutate(
            BIC = round(BIC, 1),
            R2 = round(R2, 2),
            Z_BIC = round(Z_BIC, 1),
            Z_R2 = round(Z_R2, 1)
        ) %>%
        arrange(desc(abs(Z_BIC)))  # Sort by Z_BIC in descending order
    
    # Add data to a new sheet named "Z=2" or "Z=3"
    addWorksheet(wb, sheetName = sprintf("Z=%d", Z))
    writeData(wb, sheet = sprintf("Z=%d", Z), outliers_Z)
}

# Save the Excel file
file_path <- sprintf("%s/Summary_outliers_Zscore.xlsx", nameFolder) # Define file path
saveWorkbook(wb, file_path, overwrite = TRUE)

# Select Outliers based on IQR-based thresholds (BIC being non-normal)
# Compute IQR-based thresholds
Q1 <- quantile(dataTable_PMF_GoF$BIC, 0.25, na.rm = TRUE)  # First quartile
Q3 <- quantile(dataTable_PMF_GoF$BIC, 0.75, na.rm = TRUE)  # Third quartile
IQR_BIC <- Q3 - Q1  # Interquartile range


# Select outliers
outliers_IQR <- dataTable_PMF_GoF %>%
    filter(BIC < lb_BIC | BIC > ub_BIC) %>%
    filter(R2 < lb_R2 | R2 > ub_R2)
outliers_IQR$BIC <- round(outliers_IQR$BIC, 1)
outliers_IQR$R2 <- round(outliers_IQR$R2, 2)
outliers_IQR$Z_BIC <- round(outliers_IQR$Z_BIC, 2)
outliers_IQR$Z_R2 <- round(outliers_IQR$Z_R2, 2)
print(outliers_IQR)

# Save the result in an excel sheet
write.csv(outliers_IQR, file = sprintf("%s/Summary_outliers_Z_IQR.csv", nameFolder), row.names = FALSE)


# 4. Plot BIC/R2 for each subj ----
# plot R2 and BIC as a function of subject (SX_SF4), include all 9 locations and all 7 or 9 noise levels in one figure; color code the dot according to location, and change the saturation according to where the noiseSD sits along 0 to 0.44
library(scales)
library(dplyr)

# Load data table
dataTable_PMF_GoF <- read.csv(sprintf("%s/dataTable/dataTable_PMF_GoF_Weibull.csv", nameFolder))

# Normalize NoiseSD for alpha scaling
# Merge subject names into the main dataset
dataTable_PMF_GoF <- dataTable_PMF_GoF %>%
  left_join(subj_mapping, by = "Subj") %>%
  mutate(
    subjName = sprintf("%s_SF%d", subjName, SF)  # Append SF to subject names
  )

# Define the Goodness-of-Fit metric dynamically
GoF_list <- c("BIC", "R2")  # Define metrics to loop through

# Get unique locations
unique_locs <- unique(dataTable_PMF_GoF$Loc)

# Loop through each GoF metric
for (GoF in GoF_list) {
    for (loc in unique_locs) {
        
        # Subset data for the current location (one figure per location)
        data_loc <- dataTable_PMF_GoF %>% filter(Loc == loc)
        
        # Extract the base color for the current location
        base_color <- colors_single[[loc]]
        
        # Convert NoiseSD to a factor (categorical variable)
        data_loc <- data_loc %>%
            mutate(
                NoiseSD_factor = as.factor(NoiseSD)  # Convert to discrete levels for legend
            )
        
        # 📌 Define distinct shades for each noise level ----
        noise_levels <- sort(unique(data_loc$NoiseSD))  # Get unique noise levels
        num_levels   <- length(noise_levels)            # Count number of noise levels
        
        # Generate shades by adjusting alpha (transparency) of base color
        noise_colors <- scales::alpha(base_color, seq(0.3, 1, length.out = num_levels))
        
        # Create named color mapping for legend
        names(noise_colors) <- as.character(noise_levels)
        
        # 📌 Define distinct shapes for each noise level ----
        shape_options <- c(15, 16, 17, 18, 15, 16, 17, 18, 15, 16)  # Different shapes (adjustable)
        noise_shapes  <- shape_options[1:num_levels]       # Select up to available levels
        names(noise_shapes) <- as.character(noise_levels)  # Assign to noise levels
        
        # 📌 Define the Plot (One Figure Per Location) ----
        p <- ggplot(data_loc, aes(x = subjName, y = !!sym(GoF), 
                                  color = NoiseSD_factor, shape = NoiseSD_factor)) +
            geom_point(size = 3) +
            labs(
                title = sprintf("%s Across Subjects for L%s", GoF, loc),
                x     = "Subject (SF Level Included)",
                y     = GoF,
                color = "Noise Level",  # Label for discrete legend
                shape = "Noise Level"   # Label for shape legend
            ) +
            scale_color_manual(values = noise_colors) +  # Use discrete color mapping
            scale_shape_manual(values = noise_shapes) +  # Use discrete shape mapping
            coord_cartesian(ylim = GoF_limits[[GoF]]) +  # Dynamically set y-axis limits
            theme_bw() +
            theme(
                axis.text.x = element_text(angle = 45, hjust = 1)
            ) +
            facet_wrap(~SF, scales = "free_x")  # Facet by SF if needed
        
        # 📌 Save the Plot ----
        ggsave(
            file.path(nameFolder_Fig, sprintf("%s_SubjxNoise_L%s.png", GoF, loc)), 
            plot  = p, 
            width = 12, height = 6, dpi = 300
        )
    }
}

