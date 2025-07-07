# =====================================================
# 📈 LMM - Correlation Analysis: Modulation Problem
# Shutian Xue — March 6, 2025
# =====================================================
# This script performs the second step of the analysis:
# Assessing the correlation between each model parameter (Gain, Gamma, Nadd)
# and performance (CSN0 at no noise), while controlling for spatial frequency (SF)
# and location (LocComb).
# Two-tailed empirical p-values added

# ==== 🧹 Clean environment ====
start_time <- Sys.time() # ⏱️ tic
graphics.off() # Close all plots
cat("\014") # Clear console (equivalent to clc)

# ==== ⚙️ Settings ====
param_list <- c("Gain", "GainLog", "Nadd", "Gamma") # Parameters to test

# Define the LME model
if (str_SF == "SF6") {
  str_randEff <- "LocComb"
} else {
  str_randEff <- "LocComb:SF"
}

# ==== 📁 Folder Setup ====
# Create figure and output directories
nameFolder_Fig_modulation <- sprintf("%s/Figures_1Modulation_P%.0f", nameFolder_Figures, PerfLevel_s * 100)
if (!dir.exists(nameFolder_Fig_modulation)) dir.create(nameFolder_Fig_modulation, recursive = TRUE)

# Define SF color-coding
sf_levels <- c("4", "5", "6")
sf_alpha <- c("4" = 1.0, "5" = 0.7, "6" = 1.0)
sf_lineStyle <- c("4" = "dashed", "5" = "", "6" = "solid")

# Define figure structure size
sz_wd <- 7.2 # Default figure width
sz_ht <- 6 # Default figure height
sz_label_y <- 20 # main effect | Interaction
sz_tick_y <- 20
sz_label_x <- sz_label_y
sz_tick_x <- sz_tick_y
sz_title <- 10
sz_line <- 1.5
sz_marker <- 5
marker_alpha <- .4
sz_marg <- 15 # the gap between x/y label and ticks


# Create a data frame with all LocComb × SF combinations
color_df <- expand.grid(
  LocComb = names(location_colors),
  SF = sf_levels,
  stringsAsFactors = FALSE
) %>%
  mutate(
    LocComb_SF = paste(LocComb, SF, sep = "_"),
    base_color = location_colors[LocComb],
    shade_color = map2_chr(base_color, SF, ~ alpha(.x, sf_alpha[[.y]])),
    line_style = map_chr(SF, ~ sf_lineStyle[[.x]])
  )

# Final color vector with proper names
composite_colors <- setNames(color_df$shade_color, color_df$LocComb_SF)
composite_lineStyle <- setNames(color_df$line_style, color_df$LocComb_SF)

# Loop through 2 random effects
for (flag_RandSlope in c(0,1)) {
  # ==== 🔁 Loop Through Location Groups ====
  for (str_loc in str_loc_list) {
    # 🧹 Load and Prepare Data
    dataTable_allB <- read.csv(sprintf("%s/%s_nBoot%d.csv", nameFolder_Load, str_loc, nBoot))
    
    # Number of bootstraps should be the unique levels of iBoot
    nBoot <- length(unique(dataTable_allB$iBoot))

    # Filter to specific performance level
    dataTable_allB <- dataTable_allB %>% filter(PerfLevel == PerfLevel_s)

    # Choose dependent variable
    if (flag_dv == 1) {
      dataTable_allB$DV_N0 <- as.numeric(dataTable_allB$ThreshN0)
      str_ylabel <- "ThreshN0"
    } else if (flag_dv == 2) {
      dataTable_allB$DV_N0 <- as.numeric(dataTable_allB$ThreshN0_t)
      str_ylabel <- sprintf("Performance \n(|Log threshold|)")
    } else {
      stop("Invalid value for flag_dv.")
    }

    # 🧹 Data preprocessing
    dataTable_allB <- dataTable_allB %>%
      mutate(
        Subj = factor(Subj, levels = 1:nsubj, labels = subjList),
        SF = as.factor(SF),
        Gain = as.numeric(Gain),
        GainLog = as.numeric(GainLog),
        Nadd = as.numeric(Nadd),
        Gamma = as.numeric(Gamma),
        LocComb = recode(as.character(LocComb),
          "1" = "01Fov", "2" = "02Ecc4", "3" = "03Ecc8",
          "4" = "04HM4", "5" = "05VM4", "6" = "06LVM4", "7" = "07UVM4",
          "8" = "08HM8", "9" = "09VM8", "10" = "10LVM8", "11" = "11UVM8"
        ),
        LocComb_SF = paste(LocComb, SF, sep = "_") # code comb of SFxLoc for plot color
      )
    # ---- 🔁 Loop Through Parameters (Gain, Gamma, Nadd) ----
    for (param in param_list) {
      cat(sprintf("\n*** Analyzing: Loc Group = %s | Param = %s ***\n", str_loc, param))

      # Preallocate for model summaries
      results_allB <- data.frame(
        iBoot = integer(),
        slope_estimate = numeric(),
        slope_pvalue = numeric(),
        r2_marg = numeric(),
        r2_cond = numeric()
      )

      # Get the median of DV_nN0 and param across iBoot
      param_sym <- sym(param) # Symbol for the column (e.g., Gain)
      param_med_name <- paste0(param, "_med") # e.g., "Gain_med"
      param_med <- sym(param_med_name) # Convert to symbol for :=
      param_lb_name <- paste0(param, "_lb") # e.g., "Gain_med"
      param_lb <- sym(param_lb_name) # Convert to symbol for :=
      param_ub_name <- paste0(param, "_ub") # e.g., "Gain_med"
      param_ub <- sym(param_ub_name) # Convert to symbol for :=

      dataTable_boot <- dataTable_allB
      dataTable_boot <- dataTable_boot %>%
        group_by(Subj, LocComb, LocComb_SF, SF) %>%
        summarise(
          DV_N0_med = median(DV_N0, na.rm = TRUE),
          DV_N0_ub = quantile(DV_N0, perc_ub_plot, na.rm = TRUE),
          DV_N0_lb = quantile(DV_N0, perc_lb_plot, na.rm = TRUE),
          !!param_med := median(!!param_sym, na.rm = TRUE),
          !!param_lb := quantile(!!param_sym, perc_lb_plot, na.rm = TRUE),
          !!param_ub := quantile(!!param_sym, perc_ub_plot, na.rm = TRUE),
          .groups = "drop"
        )

      # ---- 🔁 Loop Through boot iteractions (to do stats) ----
      # Setup parallel backend
      cl <- makeCluster(detectCores() - 1)
      registerDoParallel(cl)

      # Parallel loop
      results_allB <- foreach(iBoot_s = 1:nBoot, .combine = rbind, .packages = c("lmerTest", "MuMIn", "dplyr")) %dopar% {
        # Filter to specific boot iteration
        dataTable <- dataTable_allB %>% filter(iBoot == iBoot_s)

        # Fit LME model
        if (flag_RandSlope == 1) {
          model <- lmer(as.formula(sprintf("DV_N0 ~ %s + (1+%s|%s)", param, param, str_randEff)), data = dataTable, REML = str_REML)
        } else {
          model <- lmer(as.formula(sprintf("DV_N0 ~ %s + (1|%s)", param, str_randEff)), data = dataTable, REML = str_REML)
        }
        model_summary <- summary(model)

        # Extract metrics
        r2_vals <- r.squaredGLMM(model)
        slope_row <- model_summary$coefficients[param, ]

        # Return a single row as data.frame
        data.frame(
          iBoot = iBoot_s,
          slope_estimate = slope_row["Estimate"],
          slope_pvalue = slope_row["Pr(>|t|)"],
          r2_marg = r2_vals[1],
          r2_cond = r2_vals[2]
        )
      } # end of for loop

      # Stop cluster
      stopCluster(cl)

      # Print summary
      param_summary <- results_allB %>%
        summarise(
          slope_med = median(slope_estimate, na.rm = TRUE), # na.rm: TRUE is removing NA values
          slope_lb = quantile(slope_estimate, perc_lb, na.rm = TRUE),
          slope_ub = quantile(slope_estimate, perc_ub, na.rm = TRUE),
          pval_med = median(slope_pvalue, na.rm = TRUE),
          p_emp_2tail = min(mean(slope_estimate >= 0), mean(slope_estimate <= 0))*2, 
          r2_cond_med = median(r2_cond, na.rm = TRUE),
          r2_cond_lb = quantile(r2_cond, perc_lb, na.rm = TRUE),
          r2_cond_ub = quantile(r2_cond, perc_ub, na.rm = TRUE)
        )
      str_title <- sprintf(
        "Cond R2=%.2f [%.2f,%.2f]; Slope=%.3f [%.3f,%.3f]\npEMP2Tail =%.3f, pBOOT =%.3f\n",
        param_summary$r2_cond_med, param_summary$r2_cond_lb, param_summary$r2_cond_ub,
        param_summary$slope_med, param_summary$slope_lb, param_summary$slope_ub,
        param_summary$p_emp_2tail, param_summary$pval_med
      )
      cat(str_title)

      # Fit LME to the median (just for visualization)
      if (flag_RandSlope == 1) {
        str_RandSlope <- "RandSlope"
        model_boot <- lmer(as.formula(sprintf("DV_N0_med ~ %s_med + (1+%s_med|%s)", param, param, str_randEff)), data = dataTable_boot, REML = str_REML)
      } else {
        str_RandSlope <- "RandIntcpt"
        model_boot <- lmer(as.formula(sprintf("DV_N0_med ~ %s_med + (1|%s)", param, str_randEff)), data = dataTable_boot, REML = str_REML)
      }

      dataTable_boot$preds <- predict(model_boot, newdata = dataTable_boot, re.form = NULL)

      dataTable_boot <- dataTable_boot %>%
        group_by(Subj, LocComb, LocComb_SF, SF) %>%
        mutate(
          preds_med = median(preds, na.rm = TRUE),
          preds_lb = quantile(preds, perc_lb, na.rm = TRUE),
          preds_ub = quantile(preds, perc_ub, na.rm = TRUE)
        ) %>%
        ungroup()

      # ---- 🎨 Plot Data + LMM Predictions + Histogram of slope and p ----
      # Create histograms as grobs
      p_slope <- ggplot(results_allB, aes(x = slope_estimate)) +
        geom_histogram(bins = 30, fill = "grey", color = "black") +
        geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
        geom_vline(xintercept = median(results_allB$slope_estimate), linetype = "dashed", color = "red") +
        xlab("Slope") +
        scale_x_continuous(limits = c(-.1, .1), breaks = c(-.1, 0, .1)) + # x limits + ticks
        theme_void() +
        theme(
          axis.title.x = element_text(size = 9, hjust = 0.5),
          axis.text.x = element_text(size = 8),
          axis.ticks.x = element_line()
        )

      p_pValue <- ggplot(results_allB, aes(x = slope_pvalue)) +
        geom_histogram(bins = 30, fill = "grey", color = "black") +
        geom_vline(xintercept = 0.05, linetype = "dashed", color = "black") +
        geom_vline(xintercept = median(results_allB$slope_pvalue), linetype = "dashed", color = "red") +
        xlab("P values") +
        scale_x_continuous(limits = c(0.0001, .1), breaks = c(0.0001, .05, .1)) + # x limits + ticks
        theme_void() +
        theme(
          axis.title.x = element_text(size = 9, hjust = 0.5),
          axis.text.x = element_text(size = 8),
          axis.ticks.x = element_line()
        )

      # Convert to grobs
      grob_pValue <- suppressWarnings(ggplotGrob(p_pValue))
      grob_slope <- suppressWarnings(ggplotGrob(p_slope))

      yticks <- yticks_param[[param]] # Get yticks for the current param_LDI
      yticks_perf <- yticks_param[['ThreshN0_t']] # Get yticks for ThreshN0_t_LDI
      
      
      p <- ggplot(dataTable_boot, aes(x = DV_N0_med, y = get(param_med), color = LocComb_SF)) +
        # p <- ggplot(subset(dataTable_boot, LocComb %in% c("01Fov", "04HM4", '06LVM4', '07UVM4')), aes(y = DV_N0_med, x = get(param_med), color = LocComb_SF)) +
        
        # Add vertical error bars for each idvd point (DV)
        # geom_errorbar(aes(ymin = DV_N0_lb, ymax = DV_N0_ub), alpha = 0.5, width = 0) +
        # Add horizontal error bars for each idvd point (Param)
        # geom_errorbarh(aes(xmin = get(param_lb), xmax = getc(param_ub)), alpha = 0.5, height = 0)+
        # Plot idvd data point
        geom_point(aes(shape = SF), size = sz_marker, alpha = marker_alpha) +

        # Local level (Loc x SF)
        # geom_line(aes(x = preds_med, group = LocComb_SF), linewidth = sz_line) +
        geom_line(aes(x = preds_med, group = LocComb_SF, linetype = LocComb_SF, color = LocComb_SF), linewidth = sz_line) +
      
        # Color scale
        scale_color_manual(values = composite_colors) +
        scale_linetype_manual(values = composite_lineStyle)+
        # scale_shape_manual(values = subject_shapes) +

        # 
        # facet_wrap(~SF) +
        
        
        # Set y and x limits
        scale_x_continuous(
          limits = c(yticks_perf[1], yticks_perf[length(yticks_perf)]),
          breaks = yticks_perf
        ) +
        scale_y_continuous(
          limits = c(yticks[1], yticks[length(yticks)]),
          breaks = yticks
        )+
        
        # Labels and theme
        labs(
          title = sprintf('[%s%s] %s (nBoot=%d)\n%s', str_SF, str_n9, param, nBoot, str_title),
          y = param,
          x = str_ylabel
        ) +
        
        # Set y and x limits
        # scale_y_continuous(limits = limits_params[[param]]) + # x limits + ticks
        # scale_x_continuous(limits = c(0,2)) + # x limits + ticks
        theme_bw() +

        theme( 
          # line width of axis
          axis.line = element_line(linewidth = sz_line),
          panel.grid.major.y = element_line(linewidth = sz_line/3),
          
          # Axis title text
          axis.title.x = element_text(size = sz_label_x),
          axis.title.y = element_text(size = sz_label_y),
          
          # Axis tick labels
          axis.text.x = element_text(size = sz_tick_x),
          axis.text.y = element_text(size = sz_tick_y),
          
          # Plot title
          plot.title = element_text(size = sz_title, face = "bold"),
          
          legend.position = "none"
        ) 

        # # The inset of slope distribution
        # annotation_custom(grob_slope, xmin = limits_params_hist[[param]][1], xmax = limits_params_hist[[param]][2], ymin = .5, ymax = 1) +
        # # The inset of p value distribution
        # annotation_custom(grob_pValue, xmin = limits_params_hist[[param]][1], xmax = limits_params_hist[[param]][2], ymin = 0, ymax = 0.5)

      print(p)

      # 💾 Saving the plot
      ggsave(
        filename = sprintf("%s/%s_pred_%s_nBoot%d.png", nameFolder_Fig_modulation, param, str_RandSlope, nBoot),
        plot = p, width = sz_wd, height = sz_ht, dpi = 300
      )
      
    } # end of loop through params
  } # end of loop through location groups
} # end of loop through random effects

end_time <- Sys.time() # ⏱️ toc
dur <- end_time - start_time # See how much time passed
print(round(dur, 1))
cat(sprintf(
  "\n\n============= %s%s (P%.0f) ALL DONE ==============\n",
  str_SF, str_n9, PerfLevel_s * 100
))