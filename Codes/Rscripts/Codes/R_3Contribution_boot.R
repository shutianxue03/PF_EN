# =====================================================
# 📈 LMM - Contribution Analysis: Predicting Performance from Parameters
# Shutian Xue — April 8, 2025
# =====================================================
# This script conducts contribution analysis across different SF/location pairs.
# For each pair of visual field regions, it:
#   - Assesses correlation between model parameters (e.g., Nadd_LDI → Gain_LDI)
#   - Tests whether each parameter (Gain, Gamma, Nadd) predicts performance (DV_N0_LDI)
#   - Compares linear mixed models with SF as fixed/random effects
#   - Visualizes raw data and model predictions

# ==== 🧹 Clean Environment ====
start_time <- Sys.time() # ⏱️ tic
graphics.off()
cat("\014")

# ==== ⚙️ Settings ====
flag_printStep <- FALSE # Toggle to show stepwise model selection output
param_LDI_list <- c("Gain_LDI", "GainLog_LDI", "Nadd_LDI", "Gamma_LDI")
# param_LDI_list <- c("Gain_LDI")
flag_rank <- 0 # 0: value-based; 1: rank-based analysis (convert LDI values to rank)

if (flag_rank) {
  str_analysisMode <- "rank"
} else {
  str_analysisMode <- "value"
}

# Define location groups
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

# ==== 📁 Folder Setup ====
nameFolder_Fig_contribution <- sprintf("%s/Figures_3Contribution_P%.0f", nameFolder_Figures, PerfLevel_s * 100)
if (!dir.exists(nameFolder_Fig_contribution)) dir.create(nameFolder_Fig_contribution, recursive = TRUE)

# ==== 🔁 Loop Through Locations and Pairs ====
for (str_loc in str_loc_list) {
  iPair_list <- pair_mapping[[str_loc]]

  for (str_Pair in iPair_list) {

    # ==== 📦 Load and Prepare Data ====
    dataTable_LDI <- read.csv(sprintf("%s/LDI_%s_%s_nBoot%d.csv", nameFolder_Load, str_loc, str_Pair, nBoot))

    # ---- 🔁 Loop Through boot iterations (to do stats) ----
    dataTable_LDI <- dataTable_LDI[dataTable_LDI$PerfLevel == PerfLevel_s, ]

    # Data formatting
    dataTable_LDI <- dataTable_LDI %>%
      mutate(
        SF = as.factor(SF),
        Gain_LDI = as.numeric(Gain_LDI),
        GainLog_LDI = as.numeric(GainLog_LDI),
        Gamma_LDI = as.numeric(Gamma_LDI),
        Nadd_LDI = as.numeric(Nadd_LDI),
        Subj = factor(Subj, levels = 1:nsubj, labels = subjList)
      )

    # ==== Define Dependent Variable ====
    if (flag_dv == 1) {
      dataTable_LDI$DV_N0_LDI <- as.numeric(dataTable_LDI$ThreshN0_LDI)
      str_ylabel <- "ThreshN0"
    } else if (flag_dv == 2) {
      dataTable_LDI$DV_N0_LDI <- as.numeric(dataTable_LDI$ThreshN0_t_LDI)
      str_ylabel <- "Performance"
    } else {
      stop("Invalid flag_dv value.")
    }

    # Number of bootstraps should be the unique levels of iBoot
    nBoot <- length(unique(dataTable_LDI$iBoot))

    # ==== 🔁 Loop Through LDI Parameters (Gain, Gamma, Nadd) ====
    for (param_LDI in param_LDI_list) {
      
      cat(sprintf(
        "\n\n*********************************************************************\n [%s%s] %s | %s | %s \n*********************************************************************\n\n",
        str_SF, str_n9, str_loc, str_Pair, param_LDI
      ))
      
      # ---- 🔁 Loop Through boot iterations (to do stats) ----
      # Setup parallel backend
      cl <- makeCluster(detectCores() - 1)
      registerDoParallel(cl)

      # Parallel loop
      FixEff_allB <- foreach(iBoot_s = 1:nBoot, .combine = rbind, .packages = c("lmerTest", "MuMIn", "dplyr", "emmeans")) %dopar% {
        # Filter to specific boot iteration
        dataTable_LDI_perB <- dataTable_LDI %>% filter(iBoot == iBoot_s)

        # Switch to rank-based LME
        if (flag_rank) {
          str_analysisMode <- "rank"
          dataTable_LDI_perB <- dataTable_LDI_perB %>%
            mutate(
              DV_N0_LDI = rank(DV_N0_LDI),
              param_LDI = rank(.data[[param_LDI]]) # generic way to rank the parameter
            )
        } else {
          str_analysisMode <- "value"
        }

        # Fit LM/LME model (no interaction)
        if (str_SF == "SF6") {
          model_NoInt <- lm(as.formula(sprintf("DV_N0_LDI ~ %s", param_LDI)), data = dataTable_LDI_perB) # lonear regression
        } else {
          model_NoInt <- lmer(as.formula(sprintf("DV_N0_LDI ~ %s + (1|SF) + (1|Subj)", param_LDI)), data = dataTable_LDI_perB)
        }

        model_summary <- summary(model_NoInt)
        r2_NoInt <- r.squaredGLMM(model_NoInt)
        coefTable_NoInt <- model_summary$coefficients
        slopeEst_NoInt <- coefTable_NoInt[param_LDI, "Estimate"]
        slopeP_NoInt <- coefTable_NoInt[param_LDI, "Pr(>|t|)"]

        # Fit LME model (with interaction)
        if (str_SF != "SF6") {
          model_Int <- lmer(as.formula(sprintf("DV_N0_LDI ~ %s * SF + (1|Subj)", param_LDI)), data = dataTable_LDI_perB)
          anova_Int <- anova(model_Int)
          anovaP_Int <- anova_Int$`Pr(>F)`[3] # p-value for ParamLDI*SF interaction
          trends_perSF <- summary(emtrends(model_Int, specs = "SF", var = param_LDI), infer = c(TRUE, TRUE))

          # Extract slope of each SF
          trend_column <- paste0(param_LDI, ".trend")

          model_summary <- summary(model_Int)
          r2_Int <- r.squaredGLMM(model_Int)
          coefTable_Int <- model_summary$coefficients
          slopeEst_Int <- coefTable_Int[param_LDI, "Estimate"]
          slopeP_Int <- coefTable_Int[param_LDI, "Pr(>|t|)"]
        }

        # Fit linear regression model for SF4 and SF6
        if (str_SF == "SF6") {
          lm_SF6 <- lm(as.formula(sprintf("DV_N0_LDI ~ %s", param_LDI)), data = dataTable_LDI_perB %>% filter(SF == 6))
        } else {
          lm_SF4 <- summary(lm(as.formula(sprintf("DV_N0_LDI ~ %s", param_LDI)), data = dataTable_LDI_perB %>% filter(SF == "4")))
          lm_SF6 <- summary(lm(as.formula(sprintf("DV_N0_LDI ~ %s", param_LDI)), data = dataTable_LDI_perB %>% filter(SF == 6)))
        }

        
        # Store outputs
        if (str_SF == "SF6") {
          data.frame(
            iBoot = iBoot_s,
            R2Cond_NoInt = r2_NoInt[2],
            Slope_NoInt = slopeEst_NoInt,
            p_NoInt = slopeP_NoInt
          )
        } else {
          data.frame(
            iBoot = iBoot_s,
            R2Cond_NoInt = r2_NoInt[2],
            Slope_NoInt = slopeEst_NoInt,
            p_NoInt = slopeP_NoInt,
            pVal_Int = anovaP_Int,
            slope_SF4 = trends_perSF[[trend_column]][1],
            pVal_SF4 = trends_perSF$p.value[1],
            slope_SF6 = trends_perSF[[trend_column]][2],
            pVal_SF6 = trends_perSF$p.value[2],
            # store linear regression results for SF4 and SF6
            slopeLM_SF4 = lm_SF4$coefficients[2, 1],
            slopeLM_SF6 = lm_SF6$coefficients[2, 1],
            # extract p value from lm_SF4 and lm_SF6
            pLM_SF4 = lm_SF4$coefficients[2, 4],
            pLM_SF6 = lm_SF6$coefficients[2, 4]
          )
        }
      } # end boot loop

      stopCluster(cl) # Stop cluster

      # print the median and 95% CI of slope and p-value
      if (str_SF == "SF6") {
        FixEff_summary <- FixEff_allB %>%
          summarise(
            R2Cond_NoInt_med = median(R2Cond_NoInt, na.rm = TRUE),
            R2Cond_NoInt_lb = quantile(R2Cond_NoInt, perc_lb, na.rm = TRUE),
            R2Cond_NoInt_ub = quantile(R2Cond_NoInt, perc_ub, na.rm = TRUE),
            Slope_NoInt_med = median(Slope_NoInt, na.rm = TRUE),
            Slope_NoInt_lb = quantile(Slope_NoInt, perc_lb, na.rm = TRUE),
            Slope_NoInt_ub = quantile(Slope_NoInt, perc_ub, na.rm = TRUE),
            p_NoInt_med = median(p_NoInt, na.rm = TRUE),
          )
      } else{
        
        FixEff_summary <- FixEff_allB %>%
          summarise(
            # model without interaction
            R2Cond_NoInt_med = median(R2Cond_NoInt, na.rm = TRUE),
            R2Cond_NoInt_lb = quantile(R2Cond_NoInt, perc_lb, na.rm = TRUE),
            R2Cond_NoInt_ub = quantile(R2Cond_NoInt, perc_ub, na.rm = TRUE),
            Slope_NoInt_med = median(Slope_NoInt, na.rm = TRUE),
            Slope_NoInt_lb = quantile(Slope_NoInt, perc_lb, na.rm = TRUE),
            Slope_NoInt_ub = quantile(Slope_NoInt, perc_ub, na.rm = TRUE),
            Slope_NoInt_prop1 = 1-mean(Slope_NoInt>0),
            p_emp_2tail = pmin(min(mean(Slope_NoInt >= 0), mean(Slope_NoInt <= 0))*2, 1), 
            p_NoInt_med = median(p_NoInt, na.rm = TRUE),

            # model with interaction
            pVal_Int_med = median(pVal_Int, na.rm = TRUE),
            slope_SF4_med = median(slope_SF4, na.rm = TRUE),
            pVal_SF4_med = median(pVal_SF4, na.rm = TRUE),
            slope_SF6_med = median(slope_SF6, na.rm = TRUE),
            pVal_SF6_med = median(pVal_SF6, na.rm = TRUE),
            
            # linear regression
            pLM_SF4_emp_2tail = pmin(min(mean(slopeLM_SF4 >= 0), mean(slopeLM_SF4 <= 0))*2, 1), 
            pLM_SF6_emp_2tail = pmin(min(mean(slopeLM_SF6 >= 0), mean(slopeLM_SF6 <= 0))*2, 1), 
          )
      }

      # Assign star give pVal_med
      if (FixEff_summary$p_emp_2tail < 0.001) {
        star <- "***"
      } else if (FixEff_summary$p_emp_2tail < 0.01) {
        star <- "**"
      } else if (FixEff_summary$p_emp_2tail < 0.05) {
        star <- "*"
      } else if (FixEff_summary$p_emp_2tail < 0.1) {
        star <- "mg"
      } else {
        star <- "ns"
      }
      
      if (str_SF == "SF6") {
        # str_summary <- sprintf(
        #   "%s\n [No Int]Cond R2=%.2f [%.2f,%.2f] | Slope=%.3f [%.3f,%.3f]\n pEMP2TAIL=%.3f, pBOOT=%.3f, %s",
        #   param_LDI,
        #   FixEff_summary$R2Cond_NoInt_med, FixEff_summary$R2Cond_NoInt_lb, FixEff_summary$R2Cond_NoInt_ub,
        #   FixEff_summary$Slope_NoInt_med, FixEff_summary$Slope_NoInt_lb, FixEff_summary$Slope_NoInt_ub,
        #   FixEff_summary$p_emp_2tail, FixEff_summary$p_NoInt_med,
        #   star
        # )
      } else {
        # str_summary <- sprintf(
        #   "%s\n [No Int] Cond R2=%.2f [%.2f,%.2f] | Slope=%.2f [%.2f,%.2f], p=%.3f [%.3f,%.3f] %s\n [INT] p=%.3f [%.3f,%.3f] | SF4 (%.2f, p=%.3f), SF6 (%.2f, p=%.3f)",
        #   param_LDI,
        #   FixEff_summary$R2Cond_NoInt_med, FixEff_summary$R2Cond_NoInt_lb, FixEff_summary$R2Cond_NoInt_ub,
        #   FixEff_summary$Slope_NoInt_med, FixEff_summary$Slope_NoInt_lb, FixEff_summary$Slope_NoInt_ub,
        #   FixEff_summary$p_NoInt_med, FixEff_summary$p_NoInt_lb, FixEff_summary$p_NoInt_ub,
        #   star,
        #   FixEff_summary$pVal_Int_med, FixEff_summary$pVal_Int_lb, FixEff_summary$pVal_Int_ub,
        #   FixEff_summary$slope_SF4_med, FixEff_summary$pVal_SF4_med,
        #   FixEff_summary$slope_SF6_med, FixEff_summary$pVal_SF6_med
        # )
        str_summary <- sprintf(
          "%s\n [No Int] Cond R2=%.2f [%.2f,%.2f] | Slope=%.3f [%.3f,%.3f]\n pEMP2TAIL=%.3f, pBOOT=%.3f\npEMP2TAIL for 4 cpd=%.3f, for 6 cpd=%.3f",
          param_LDI,
          FixEff_summary$R2Cond_NoInt_med, FixEff_summary$R2Cond_NoInt_lb, FixEff_summary$R2Cond_NoInt_ub,
          FixEff_summary$Slope_NoInt_med, FixEff_summary$Slope_NoInt_lb, FixEff_summary$Slope_NoInt_ub,
          FixEff_summary$p_emp_2tail, FixEff_summary$p_NoInt_med,
          FixEff_summary$pLM_SF4_emp_2tail, FixEff_summary$pLM_SF6_emp_2tail
        )
      }
      # cat(str_summary)

      # Calculate the med and CI of data (thresh and param) for plotting
      dataTable_LDI_boot <- dataTable_LDI %>%
        group_by(SF, Subj) %>%
        summarise(
          DV_N0_LDI_med = median(DV_N0_LDI),
          DV_N0_LDI_lb = quantile(DV_N0_LDI, perc_lb_plot, na.rm = TRUE),
          DV_N0_LDI_ub = quantile(DV_N0_LDI, perc_ub_plot, na.rm = TRUE),
          param_LDI_med = median(.data[[param_LDI]]),
          param_LDI_lb = quantile(.data[[param_LDI]], perc_lb_plot, na.rm = TRUE),
          param_LDI_ub = quantile(.data[[param_LDI]], perc_ub_plot, na.rm = TRUE),
          .groups = "drop" # <- this removes all grouping
        )
      
      # Fit the lm/lme model for plotting
      if (str_SF == "SF6") {
        model_boot <- lm(as.formula("DV_N0_LDI_med ~ param_LDI_med"), data = dataTable_LDI_boot)
      } else {
        model_boot <- lmer(as.formula(sprintf("DV_N0_LDI_med ~ param_LDI_med + (1|SF) + (1|Subj)")), data = dataTable_LDI_boot)
      }

      # model_summary <- summary(model_boot)
      dataTable_LDI_boot$predicted <- predict(model_boot, re.form = NA)

      # ==== 🎨 Plot: Data + Model Prediction ====
      # Define limits and labels for each param_LDI in one lookup list
      # param_LDI_info <- list(
      #   GainLog_LDI  = list(ylim = c(-0.2, 0.4),  label = "LDI for GainLog"),
      #   Gain_LDI  = list(ylim = c(-0.2, 1),  label = "LDI for log Gain"),
      #   Nadd_LDI  = list(ylim = c(-0.3, 0.8),  label = "LDI for additive noise"),
      #   Gamma_LDI = list(ylim = c(-0.2, 0.6),  label = "LDI for nonlinearity")
      # )
      # 
      # if (!param_LDI %in% names(param_info)) stop("Invalid param_LDI value.")
      
      y_lim <- param_LDI_info[[param_LDI]]$ylim
      param_LDI_label <- param_LDI_info[[param_LDI]]$label
      yticks <- param_LDI_info[[param_LDI]]$yticks # Get yticks for the current param_LDI
      yticks_perf <- param_LDI_info[['ThreshN0_t_LDI']]$yticks # Get yticks for ThreshN0_t_LDI
      
      # Define scale_y without limits
      scale_y <- scale_y_continuous()

      
      pp <- ggplot(dataTable_LDI_boot, aes_string(x = "DV_N0_LDI_med", y = "param_LDI_med")) +

        # Individual data points
        geom_point(aes(fill=SF, shape = SF), 
                   color='black', size = sz_marker, stroke = 1.2) +
        
        scale_fill_manual(values = c("4" = "white", "6" = "white"))+
      
        # Add horizontal error bars for each idvd point (perf)
        # geom_errorbarh(aes(xmin = DV_N0_LDI_lb, xmax = DV_N0_LDI_ub, color = SF), alpha = 0.5, width = 0) +
        # Add vertical error bars for each idvd point (Param)
        # geom_errorbar(aes(ymin = param_LDI_lb, ymax = param_LDI_ub, color = SF), alpha = 0.5, height = 0) +

        # Model predictions (per SF))
        # geom_smooth(aes(color = SF), method = "lm", se = FALSE) +
        geom_smooth(aes(group = SF),color='black',  method = "lm", se = FALSE) +

        # Reference line
        geom_hline(yintercept = 0, color = "grey40", linetype = "solid", linewidth = 0.6) +
        geom_vline(xintercept = 0, color = "grey40", linetype = "solid", linewidth = 0.6) +

        # Others
        # scale_shape_manual(values = subject_shapes) +
        scale_shape_manual(values = shape_SF) +
        
        # Define xand y limits
        # scale_x_continuous() +
        # scale_y +
        # coord_cartesian(xlim = c(0, 0.4), ylim = y_lim)+

        scale_x_continuous(
          limits = c(yticks_perf[1], yticks_perf[length(yticks_perf)]),
          breaks = yticks_perf
        ) +
        scale_y_continuous(
          limits = c(yticks[1], yticks[length(yticks)]),
          breaks = yticks
        )+
      
        theme_bw() +
        theme( 
          # line width of axis
          axis.line = element_line(linewidth = sz_line/2),
          panel.grid.major.y = element_line(linewidth = sz_line/3),
          
          # Axis title text
          axis.title.x = element_text(size = sz_label_x, margin = margin(t = sz_marg)),
          axis.title.y = element_text(size = sz_label_y, margin = margin(r = sz_marg)),
          
          # Axis tick labels
          axis.text.x = element_text(size = sz_tick_x),
          axis.text.y = element_text(size = sz_tick_y),
          
          # Plot title
          plot.title = element_text(size = sz_title, face = "bold"),
          
          # legend.position = "none" # 
        ) +
        labs(
          title = sprintf("[%s%s] [%s %s] (nBoot=%d) %s", str_SF, str_n9, str_loc, str_Pair, nBoot, str_summary),
          # x = "LDI for performance",
          # y = param_LDI_label,
          x = "",
          y = "",
          shape = "SF"
        )

      print(pp)

      if (!dir.exists(sprintf("%s/%s", nameFolder_Fig_contribution, param_LDI))) {
        dir.create(sprintf("%s/%s/", nameFolder_Fig_contribution, param_LDI), recursive = TRUE)
      }
      
      ggsave(
        filename = sprintf("%s/%s/%s_%s_%s_nBoot%d.png", nameFolder_Fig_contribution, param_LDI, str_loc, str_Pair, str_analysisMode, nBoot),
        plot = pp, width = sz_wd, height = sz_ht, dpi = 300
      )
    } # end of param loop
  } # end  of pair loop
} # end of location loop


end_time <- Sys.time() # ⏱️ toc
dur <- end_time - start_time # See how much time passed
print(dur)
cat(sprintf(
  "\n\n============= %s%s (P%.0f) ALL DONE ==============\n",
  str_SF, str_n9, PerfLevel_s * 100
))