# =====================================================
# 📈 LMM - Contribution Analysis: Compare parameter LDIs over binned perf LDIs
# Shutian Xue — April 8, 2025
# =====================================================
# This script conducts contribution analysis across different SF/location pairs.
# For each pair of visual field regions, it:
#   - Bins individual bootstrapped observations by performance (Perf_LDI)
#   - Tests whether each parameter (Gain, GainLog, Gamma, Nadd) varies across bins
#   - Fits LMMs with Subj and SF as random effects (no interaction)
#   - Performs ANOVA and post-hoc pairwise comparisons with Bonferroni correction
#   - Visualizes model parameters across performance bins per spatial frequency

param_LDI_list <- c("Gain_LDI", "GainLog_LDI", "Nadd_LDI", "Gamma_LDI")
str_loc_list <- c("FovHM4HM8", "FovVM4VM8", "HM4VM4", "HM8VM8", "LVM4UVM4", "LVM8UVM8", "FovEcc4Ecc8")

nBins <- 2
nComp <- if (nBins == 3) 3 else 1

nameFolder_Fig <- sprintf("%s/Figures_3ContributionBin_P%.0f", nameFolder_Figures, PerfLevel_s * 100)
if (!dir.exists(nameFolder_Fig)) dir.create(nameFolder_Fig, recursive = TRUE)

nameFolder_Output <- sprintf("%s/Output_3ContributionBin/%s%s", nameFolder_Outputs, str_SF, str_n9)
if (!dir.exists(nameFolder_Output)) dir.create(nameFolder_Output, recursive = TRUE)

sink(sprintf("%s/nBin%d_nBoot%d.txt", nameFolder_Output, nBins, nBoot))

# ==== 🔁 Loop Through Locations and Pairs ====
for (str_loc in str_loc_list) {
  iPair_list <- pair_mapping[[str_loc]]

  for (str_Pair in iPair_list) {
    cat(sprintf(
      "\n\n*********************************************************************\n [%s%s] Location: %s | Pair: %s \n*********************************************************************\n\n",
      str_SF, str_n9, str_loc, str_Pair
    ))

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
      dataTable_LDI$Perf_LDI <- as.numeric(dataTable_LDI$ThreshN0_LDI)
      str_ylabel <- "ThreshN0"
    } else if (flag_dv == 2) {
      dataTable_LDI$Perf_LDI <- as.numeric(dataTable_LDI$ThreshN0_t_LDI)
      str_ylabel <- "Performance"
    } else {
      stop("Invalid flag_dv value.")
    }

    # Number of bootstraps should be the unique levels of iBoot
    nBoot <- length(unique(dataTable_LDI$iBoot))

    # ==== 🔁 Loop Through LDI Parameters (Gain, Gamma, Nadd) ====
    for (param_LDI in param_LDI_list) {
      dataTable_LDI_perB <- dataTable_LDI %>% filter(iBoot == 1)

      # Create a folder for figures
      nameFolder_Fig_ <- sprintf("%s/%s_nBin%d", nameFolder_Fig, param_LDI, nBins)
      if (!dir.exists(nameFolder_Fig_)) dir.create(nameFolder_Fig_, recursive = TRUE)

      # Use quantile-based binning on DV (performance LDI)
      # Bin for all data across SF
      dataTable_LDI_perB <- dataTable_LDI_perB %>%
        mutate(
          iBin_perfLDI = cut(Perf_LDI,
            breaks = quantile(Perf_LDI, probs = seq(0, 1, length.out = nBins + 1), na.rm = TRUE),
            include.lowest = TRUE, labels = FALSE
          ),
        ) %>%
        ungroup()

      # # Bin for data per EACH SF
      # dataTable_LDI_perB <- dataTable_LDI_perB %>%
      #   group_by(SF) %>%
      #   mutate(
      #     iBin_perfLDI = cut(
      #       Perf_LDI,
      #       breaks = quantile(Perf_LDI, probs = seq(0, 1, length.out = nBins + 1), na.rm = TRUE),
      #       include.lowest = TRUE, labels = FALSE
      #     )
      #   ) %>%
      #   ungroup()


      dataTable_LDI_perB$iBin_perfLDI <- factor(dataTable_LDI_perB$iBin_perfLDI)

      # Fit LM/LME model (no interaction)
      model <- lmer(as.formula(sprintf("%s ~ iBin_perfLDI + (1|SF) + (1|Subj)", param_LDI)), data = dataTable_LDI_perB)
      # model <- lmer(as.formula(sprintf("%s ~ iBin_perfLDI *SF + (1|Subj)", param_LDI)), data = dataTable_LDI_perB)
      r2 <- r.squaredGLMM(model)

      # Do ANOVA
      model_anova <- anova(model) %>% as.data.frame()
      model_anova$Var <- rownames(model_anova)

      colnames(model_anova) <- c("SS", "MSQ", "df1", "df2", "F", "p", "Var")
      model_anova <- model_anova %>% mutate(across(c(SS, MSQ, df1, df2, F, p), ~ round(.x, 3)))

      # Obtain effect size (eta-squared)
      model_eta2p <- eta_squared(model, partial = TRUE) %>%
        mutate(
          Eta2p = round(Eta2_partial, 3),
          Var = model_anova$Var
        )

      # Merge ANOVA and eta2
      model_anova_full <- merge(model_anova[, c("Var", "df1", "df2", "F", "p")], model_eta2p[, c("Var", "Eta2p")], by = "Var")
      model_anova_full$p <- signif(model_anova_full$p, 2)
      # model_anova_full <- model_anova_full[order(match(model_anova_full$Var, c("LocComb", "SF", "LocComb:SF"))), ]


      # Post-hoc for binned param_LDI
      mc_df <- emmeans(model, pairwise ~ iBin_perfLDI)$contrasts %>%
        as.data.frame() %>%
        transmute(
          contrast,
          diff = round(estimate, 3), # Estimate difference between locations
          df = round(df, 1),
          t = round(t.ratio, 2),
          pVal = round(p.value, 3) * nComp, # Bonferroni correction for multiple comparisons
        )

      # Format posthoc results of one-way ANOVA
      fxn_format_posthoc <- function(df) {
        apply(df, 1, function(r) {
          contrast <- r["contrast"]
          tVal <- as.numeric(r["t"])
          dfVal <- as.numeric(r["df"])
          pVal <- as.numeric(r["pVal"])
          sprintf("  %s: t(%.1f) = %.3f, p = %.3f", contrast, dfVal, tVal, pVal)
        })
      } # end of format_posthoc

      # Print anova and post-hoc results
      text_anova <- sprintf(
        "F(%.0f, %.1f) = %.3f, p = %.3f, Eta2p = %.3f ",
        model_anova_full$df1, model_anova_full$df2,
        model_anova_full$F, model_anova_full$p, model_anova_full$Eta2p
      )
      text_posthoc <- fxn_format_posthoc(mc_df)
      text_posthoc_block <- paste(text_posthoc, collapse = "\n")
      text_all <- sprintf("\n%s\n%s\n", text_anova, text_posthoc_block)
      cat(text_all)

      # Visualize param_LDI as a function of iBin_perfLDI
      p <- ggplot(dataTable_LDI_perB, aes_string(x = "iBin_perfLDI", y = param_LDI)) +
        geom_boxplot() +
        labs(title = sprintf("%s vs %s", param_LDI, str_ylabel), x = "Performance Bin", y = param_LDI) +
        theme_bw() +
        # add title
        labs(
          title = sprintf("[%s%s] (nBoot=%d) %s %s %s\n%s", str_SF, str_n9, nBoot, param_LDI, str_loc, str_Pair, text_all),
        ) +

        # plot idvd data, connected
        geom_line(aes(group = Subj, color = SF), alpha = 0.5) +
        geom_point(aes(color = SF, shape = Subj), alpha = 0.5) +
        scale_shape_manual(values = subject_shapes) + # shapes indicate SF
        facet_wrap(~SF, scales = "free")
      
      print(p)

      ggsave(sprintf("%s/%s_%s_nBoot%d.png", nameFolder_Fig_, str_loc, str_Pair, nBoot),
        plot = p, width = 7, height = 7, dpi = 300
      )

      # Format and save results
    } # end of param_LDI loop
  } # end of str_Pair loop
} # end of str loop

sink() # Close log file

while (sink.number() > 0) sink(NULL)