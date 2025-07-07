
# ==== 🧹 Clean environment ====
start_time <- Sys.time() # ⏱️ tic
graphics.off() # Close all plots
cat("\014") # Clear console (like MATLAB's clc)

# Define the path to save figures
nameFolder_Fig <- sprintf("%s/Figures_PMF_CompThreshLR", nameFolder_Figures)
if (!dir.exists(nameFolder_Fig)) {
    dir.create(nameFolder_Fig, recursive = TRUE)
}

# Define the path to save outputs
nameFolder_Output <- sprintf("%s/Output/", nameFolder)
if (!dir.exists(nameFolder_Output)) {
    dir.create(nameFolder_Output, recursive = TRUE)
}


# Load the data
nameFolder_Load <- sprintf("%s/DataTable/%s%s", nameFolder, str_SF, str_n9)
dataTable <- read.csv(sprintf("%s/PMF_compThreshLR_nBoot1.csv", nameFolder_Load))

# Convert the log Thresh to linear scale if needed
if (flag_LogLn == 0) {
    dataTable$Thresh_log <- 10^dataTable$Thresh_log
    str_LogLn <- "ln"
} else {
    str_LogLn <- "log"
}

# Create a sink file
sink(sprintf("%s/CompThreshLR_%s_%s%s.txt", nameFolder_Output, str_LogLn, str_SF, str_n9))

# Convert variables
dataTable$Subj <- factor(dataTable$Subj, levels = 1:nsubj, labels = subjList)
dataTable$Ecc48 <- as.factor(dataTable$Ecc48)
dataTable$L1R2 <- as.factor(dataTable$L1R2)
dataTable$SF <- as.factor(dataTable$SF)
dataTable$PerfLevel <- as.factor(dataTable$PerfLevel)
dataTable$NoiseSD <- factor(dataTable$NoiseSD)

# Fit the linear mixed model [Full Model] ----
model <- lmer(Thresh_log ~ L1R2 * (Ecc48 + SF + PerfLevel + NoiseSD) + (1 | Subj), data = dataTable)
model_summary <- summary(model)

# Perform ANOVA on the model
model_anova <- anova(model)
print(model_anova)

# Focus on the L1R2xnNoiseSD interaction
# Making predictions for Thresh_log as a fxn of L1R2 and noiseSD
# emm <- emmeans(model, ~ L1R2 | NoiseSD, at = list(NoiseSD = seq(min(dataTable$NoiseSD), max(dataTable$NoiseSD), length.out = 100)))
# print(emm)

# Multiple comparisons on raw data ----
# 1. Main effect of L1R2
mc_L1R2 <- emmeans(model, pairwise ~ L1R2, adjust = "bonferroni")
mc_L1R2 <- as.data.frame(mc_L1R2$contrasts) %>%
    select(contrast, estimate, p.value) %>%
    mutate(across(c(estimate, p.value), ~ round(.x, 3))) %>%
    mutate(
        Dir = case_when(
            estimate > 0 ~ ">",
            estimate < 0 ~ "<",
            TRUE ~ "="
        ),
        sig = symnum(p.value,
            corr = FALSE,
            cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
            symbols = c("***", "**", "*", ".", "ns")
        )
    ) %>%
    select(contrast, estimate, p.value, Dir, sig)

print(mc_L1R2)

# Visualize
# Step 1: Summarize raw data by NoiseSD and L1R2
summary_df <- dataTable %>%
    group_by(NoiseSD, L1R2) %>%
    summarise(
        meanThresh = mean(Thresh_log, na.rm = TRUE),
        seThresh = sd(Thresh_log, na.rm = TRUE) / sqrt(n()),
        .groups = "drop"
    )

# Ave + Errorbar
ggplot(summary_df, aes(x = NoiseSD, y = meanThresh, color = L1R2)) +
    geom_point(position = position_dodge(0.5), size = 3) + # don't override color here
    geom_errorbar(
        aes(ymin = meanThresh - seThresh, ymax = meanThresh + seThresh),
        width = 0.2,
        position = position_dodge(0.5)
    ) +
    labs(
        title = "Thresh_log by L1R2 and NoiseSD",
        x = "Noise SD Level", y = "Mean log Threshold",
        color = "L1R2"
    ) +
    theme_bw()

ggplot(summary_df, aes(x = NoiseSD, y = meanThresh, color = L1R2)) +
    geom_point(position = position_dodge(0.5), size = 3) +
    geom_errorbar(
        aes(ymin = meanThresh - seThresh, ymax = meanThresh + seThresh),
        width = 0.2,
        position = position_dodge(0.5)
    ) +
    scale_y_continuous(
        limits = c(-1.5, -.5),
        breaks = c(-1.5, -1.25, -1, -.75, -.5), # still in log space
        labels = function(x) format(exp(x), scientific = FALSE, digits = 2)
    ) +
    labs(
        title = "Thresh_log by L1R2 and NoiseSD",
        x = "Noise SD Level",
        y = "Threshold (linear units, log scale)",
        color = "L1R2"
    ) +
    theme_bw()
# Saeve the plot
ggsave(sprintf("%s/CompThreshLR_%s%s.png", nameFolder_Fig, str_SF, str_n9), width = 8, height = 6)

# Close the sink
sink()
# Close all sinks opened
while (sink.number() > 0) {sink(NULL)}
cat(sprintf("\n\n ============== %s ALL DONE ==============\n", str_SF))

