#=============================================================
# R Script for Linear Mixed Models (LMM)
# Analyzing whether `dv` varies across `LocComb` and whether
# `SF` modulates this variation.
#=============================================================

# Load required packages ----
library(lme4)       # For mixed-effects modeling
library(lmerTest)   # For p-values in mixed models
library(emmeans)    # For post-hoc pairwise comparisons
library(see)        # For visualization of mixed models
library(performance) # For model diagnostics
library(ggplot2)    # For general plotting
library(dplyr)      # For data manipulation
library(writexl)  # Load package

# Clear workspace ----
rm(list = ls()) # clear all
graphics.off() # close all
cat("\014")  # clc

# Set working directory
setwd(
    "/Volumes/purplab/EXPERIMENTS/1_Current_Experiments/Shutian_server/PF_INE_2023/Rscripts"
)

# Define the values to loop through ----
str_loc_list <- c("FovEcc4Ecc8",
                  "FovHM4HM8",
                  "FovVM4VM8",
                  "HM4VM4",
                  "HM8VM8",
                  "LVM4UVM4",
                  "LVM8UVM8")
dv_list <- c("Nadd", "Gain")
# dv_list <- c("Gamma")

# str_loc_list <- c("LVM8UVM8")
# dv_list <- c("Nadd")

# Define the formulas to loop through ----
formulas <- list(
    "~ LocComb * SF + (1|Subj)", # Examines the interaction between LocComb and SF, allowing each subject (Subj) to have a different baseline (random intercept).
    "~ LocComb * SF + (1 |Subj) + (1 |SF)", # Allows both Subj and SF to have independent variability in baseline performance (random intercepts for both).
    "~ LocComb * SF + (1 | Subj / SF)" # Models Subj as nested within SF, meaning each SF condition has its own set of subjects, capturing variability in subject responses within each SF level.

)

names_model <- c(
    '1RandInt4Subj',
    '2RandInt4SubjSF',
    '3Nested'
)

# Create folder to save the figures
dir_fig <- sprintf("%s/Figures_LMM_MC", nameFolder_Figures)
if (!dir.exists(dir_LMM_MC)) {dir.create(dir_LMM_MC, recursive = TRUE, showWarnings = FALSE)}

#=============================================================
# Function: fxn_plotLMM
# Fits an LMM, prints the summary, and visualizes the model
# with formula, R², and BIC in the title
#=============================================================
fxn_plotLMM <- function(model_name, model_formula, dataTable) {
    graphics.off() # close all

    # Load necessary packages
    library(lme4)
    library(lmerTest)
    library(see)
    library(performance)  # For R² and BIC extraction
    library(ggplot2)
    library(emmeans)
    library(dplyr)
    library(sjstats)

    # Set canvas size
    wd <- 12
    ht <- 7

    # Fit the linear mixed model ----------------
    model <- lmer(model_formula, data = dataTable, REML = TRUE)

    # Create a string reporting fixed effects ----------------
    model_summary <- summary(model)
    fixed_effects <- as.data.frame(model_summary$coefficients)
    effects_df <- fixed_effects[fixed_effects$'Pr(>|t|)' < 0.1, ]  # Filter for mg/sig effects
    effects_df$Predictor <- rownames(effects_df)  # Add predictor names as a column
    # Rename columns for clarity
    colnames(effects_df) <- c("Estimate", "SE", "df", "t", "p", "Predictor")

    # A full version with all effect details
    # formatted_effects <- apply(effects_df, 1, function(row) {
    #     sprintf("%s: b=%.3f, SE=%.3f, t(%.0f)=%.3f, p=%s",
    #             row["Predictor"], as.numeric(row["Estimate"]), as.numeric(row["SE"]),
    #             as.numeric(row["df"]), as.numeric(row["t"]), row["p_formatted"])
    # })

    # A simpler version with only b and p-value
    formatted_effects <- apply(effects_df, 1, function(row) {
        sprintf("[%s] b=%.3f, p=%.3f",
                row["Predictor"], as.numeric(row["Estimate"]),as.numeric(row["p"]))
    })

    # Combine into a single string with newlines
    str_FixedEffects <- paste(formatted_effects, collapse = "\n")

    # Others ----------------
    # Extract model formula as a formatted string
    formula_str <- paste(deparse(formula(model)), collapse = " ")

    # Extract fitted values from model
    dataTable$fitted <- predict(model)

    # Compute estimated marginal means (fixed effects predictions)
    emm_df <- as.data.frame(emmeans(model, ~ LocComb * SF))

    # Extract estimates of model
    model_estimates <- summary(model)
    # print(model_estimates)

    # Extract R2 and BIC
    model_bic <- BIC(model)
    model_r2_marg <- r2_nakagawa(model)$R2_marginal  # Marginal R² (fixed effects only)
    model_r2_cond <- r2_nakagawa(model)$R2_conditional  # Conditional R² (fixed effects + random effects)
    model_icc <- performance::icc(model)

    # Construct title with formula, R², and BIC ----------------
    title_str <- paste0(
        formula_str,
        "\nBIC = ", round(model_bic, 2),
        ", Marg. R2 = ", round(model_r2_marg, 2),
        ", Cond. R2 = ", round(model_r2_cond, 2),
        ", ICC = ", round(model_icc, 2),
        "\n", str_FixedEffects
    )

    # Open new graphics window
    quartz(width = wd, height = ht)


    # Use ggplot to plot raw data, individual subject data, and fixed effects
    fig <- ggplot() +

        # 🔹 Connect raw data points for each subject with solid lines (same color as points)
        geom_line(
            data = dataTable,
            aes(
                x = LocComb,
                y = .data[[dv]],
                group = Subj,
                color = factor(Subj)
            ),
            alpha = 0.5,
            size = .5
        ) +

        # 🔹 Raw data points with unique colors per subject
        geom_point(
            data = dataTable,
            aes(
                x = LocComb,
                y = .data[[dv]],
                color = factor(Subj)
            ),
            alpha = 0.5,
            size = .5
        ) +

        # 🔹 Dashed lines for fitted values, same color as raw data
        geom_line(
            data = dataTable,
            aes(
                x = LocComb,
                y = fitted,
                group = Subj,
                color = factor(Subj)
            ),
            linetype = "dashed",
            alpha = 0.5,
            size = 1
        ) +

        # 🔹 Bold black lines for fixed effects (group means)
        geom_line(
            data = emm_df,
            aes(x = LocComb, y = emmean, group = SF),
            color = "black",
            size = 1.5
        ) +
        geom_point(
            data = emm_df,
            aes(x = LocComb, y = emmean),
            color = "black",
            size = 3
        ) +

        # 🔹 Facet by SF condition
        facet_wrap( ~ SF) +

        # 🔹 Labels & Theme
        labs(title = title_str, x = "LocComb", y = dv) +
        theme_minimal()

    print(fig)

    # Save the figure (think about this later)
    ggsave(
        sprintf('%s.png', model_name),
        plot = fig,
        width = wd,
        height = ht,
        dpi = 300
    )

    # Save figure to a location-specific folder
    dir_perCond <- sprintf('%s/%s/%s', dir_LMM_MC, str_loc, dv)
    if (!dir.exists(dir_perCond)) {
        dir.create(dir_perCond,
                   recursive = TRUE,
                   showWarnings = FALSE)
    }
    ggsave(
        sprintf('%s/%s.png', dir_perCond, model_name),
        plot = fig,
        width = 10,
        height = 7,
        dpi = 300
    )

    # }

    return(model)  # Return the fitted model object

} # end of defining fxn_plotLMM

#=============================================================
# Function: fxn_checkModelConv
#=============================================================
fxn_checkModelConv <- function(model) {
    flag <- 1  # Default to a good model
    message_text <- "Model converged successfully"

    # Check if the model is singular
    if (isSingular(model)) {
        flag <- 0
        message_text <- "Model is singular"
    }

    # Check for optimizer convergence warnings
    if (length(model@optinfo$conv$lme4) > 0) {
        flag <- 0
        message_text <- paste("Optimizer warning:",
                              paste(model@optinfo$conv$lme4, collapse = " "))
    }

    # # Check for Hessian-related warnings
    # if (!is.null(model@optinfo$derivs)) {
    #     flag <- 0
    #     message_text <- "Potential Hessian issues detected"
    # }

    # Check if BIC or log-likelihood is NaN
    if (is.nan(BIC(model)) || is.nan(logLik(model))) {
        flag <- 0
        message_text <- "BIC or log-likelihood is not valid"
    }

    return(list(flag = flag, message_text = message_text))
}

#=============================================================
# Main Script: Loop through Locations and DVs
#=============================================================

best_model_results <- data.frame(
    Location = character(),
    Param = character(),
    Best_Model = character(),
    Best_BIC = numeric(),
    Marginal_R2 = numeric(),
    stringsAsFactors = FALSE
)

for (str_loc in str_loc_list) {
    for (dv in dv_list) {
        print(sprintf("*** Location: %s | Processing dv: %s ***", str_loc, dv))

        # Load Data
        dataTable <- read.csv(paste0('dataTable/dataTable_PTM_', str_loc, '.csv'))
        dataTable$Subj <- as.factor(dataTable$Subj)
        dataTable$LocComb <- as.factor(dataTable$LocComb)
        dataTable$SF <- as.factor(dataTable$SF)

        # Initialize placeholders
        bic_values <- data.frame(
            Model = character(),
            BIC = numeric(),
            stringsAsFactors = FALSE
        )

        # Fit models and store BIC values
        for (i in seq_along(formulas)) {
            model <- fxn_plotLMM(names_model[i], as.formula(paste(dv, formulas[i])), dataTable)

            if (fxn_checkModelConv(model)$flag == 1) {
                bic_values <- rbind(bic_values,
                                    data.frame(Model = names_model[i], BIC = BIC(model)))
            } else{
                print(fxn_checkModelConv(model)$message_text)
            }
        }

        # Find the best model
        if (nrow(bic_values) > 0) {
            best_model_index <- which.min(bic_values$BIC)
            best_model_name <- bic_values$Model[best_model_index]
            best_bic_value <- bic_values$BIC[best_model_index]

            best_model_results <- rbind(
                best_model_results,
                data.frame(
                    Location = str_loc,
                    Param = dv,
                    Best_Model = best_model_name,
                    Best_BIC = best_bic_value,
                    stringsAsFactors = FALSE
                )
            )
        }
    }
}

# Save results ----
# write_xlsx(best_model_results, "Summary_PFinParams_MC.xlsx")

print("All done!")
graphics.off() # close all
