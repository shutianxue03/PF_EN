# =====================================================
# 📈 LMM - Variation Analysis: SF × Location Effects
# Shutian Xue — April 8, 2025
# =====================================================
# This script performs the third stage of the analysis:
# Evaluating how model parameters (Gain, Gamma, Nadd) vary across:
#   - Spatial Frequencies (SF)
#   - Visual Field Locations (LocComb)
#
# For each parameter:
#   - Runs LMM with different random/fixed effects
#   - Performs ANOVA and post-hoc tests (optional)
#   - Generates visualizations of raw data and model predictions
#   - Outputs results by SF × LocComb

# ==== 🧹 Clean environment ====
start_time <- Sys.time() # ⏱️ tic
graphics.off() # Close all plots
cat("\014") # Clear console (like MATLAB's clc)

# ==== ⚙️ Settings ====
# param_list <- c("ThreshN0_t", "Gain", "Nadd", "Gamma") # Parameters to test
param_list <- c("Gain", "ThreshN0_t", "GainLog", "Nadd", "Gamma") # Parameters to test

sz_wd_3way <- 7
sz_ht_3way <- 6
sz_wd_2way <- 3.5
sz_ht_2way <- 3

theme_custom_3way <- theme(
  axis.title = element_text(size = 16, face = "bold"),
  axis.text = element_text(size = 14),
  strip.text = element_text(size = 14, face = "bold"),
  plot.title = element_text(size = 14),
  legend.title = element_text(size = 14),
  legend.text = element_text(size = 12)
)
theme_custom_2way <- theme(
  axis.title = element_text(size = 12, face = "bold"),
  axis.text = element_text(size = 10),
  strip.text = element_text(size = 10, face = "bold"),
  plot.title = element_text(size = 10)
)

# Set number of comparisons
nComp_Loc <- 1 # (HM vs. VM) or (LVM vs. UVM)
nComp_SF <- 1 # SF4 vs. SF6
nComp_Ecc <- 1 # 4º vs. 8º
nComp_LocxEcc <- 2 # (HM4º vs. VM4º, HM8º vs. VM8º) or (LVM4º vs. UVM4º, LVM8º vs. UVM8º)
nComp_LocxSF <- 2 # (HM4 vs. VM4, HM6 vs. VM6) or (LVM4 vs. UVM4, LVM6 vs. UVM6)
nComp_LocxEccxSF <- 4 # (HM4º vs. VM4º, HM8º vs. VM8º, LVM4º vs. UVM4º, LVM8º vs. UVM8º)

if (nBoot == 1) {
  str_pBOOT <- "p_obs" # the p to report
  str_pEMP <- "ignore"
} else {
  str_pBOOT <- "p_med"
  str_pEMP <- "p_emp2tail" # the p to report
}

# List the formula of all models I want to test
if (str_SF == "SF6") {
  formulas_all <- c(
    formula_Intrc              = "LocComb",
    formula_Intrc_RandIntcpt   = "LocComb + (1|Subj)",
    formula_Intrc_RandSlopeLoc = "LocComb + (LocComb|Subj)",
    formula_Intrc_Full         = "LocComb + (1 + LocComb | Subj)" # allows individual differences in how subjects respond across locations, while keeping SF fixed across subjects (since some are missing).
  )
} else {
  formulas_all <- c(
    formula_Intrc              = "LocComb * SF * Ecc",
    formula_Intrc_RandIntcpt   = "LocComb * SF * Ecc + (1|Subj)",
    formula_Intrc_RandSlopeLoc = "LocComb * SF * Ecc + (LocComb|Subj)",
    formula_Intrc_Full         = "LocComb * SF * Ecc + (1 + LocComb | Subj)" # allows individual differences in how subjects respond across locations, while keeping SF fixed across subjects (since some are missing).
  )
}

# ==== 📁 Folder Setup ====
nameFolder_Output <- sprintf("%s/Output_2Variation_3Way", nameFolder_Outputs)
if (!dir.exists(nameFolder_Output)) dir.create(nameFolder_Output, recursive = TRUE)

# ==== 🔁 Loop Through Parameters (Gain, Nadd, Gamma) ====
for (param in param_list) {
  
  # ==== 🔁 Loop Through Print Modes (ANOVA, LMM, Step) ====
  if (flag_plot7Locs == TRUE) {
    sink(sprintf("%s/ANOVA_%s_nBoot%d_7Loc.txt", nameFolder_Output, param, nBoot))
  } else {
    sink(sprintf("%s/ANOVA_%s_nBoot%d.txt", nameFolder_Output, param, nBoot))
  }

  # ==== 🔁 Loop Through Location Groups ====
  for (str_loc in str_loc_list) {
    cat(sprintf(
      "\n\n*******************************************************************\n [%s%s] Location: %s | Param: %s (nBoot = %d) \n*******************************************************************\n\n",
      str_SF, str_n9, str_loc, param, nBoot
    ))

    # 🧹 Load and Prepare Data
    dataTable <- read.csv(sprintf("%s/%s_nBoot%d.csv", nameFolder_Load, str_loc, nBoot))

    recode_loccomb <- function(x) {
      recode(as.character(x),
        "1" = "HM", "2" = "VM",
        "3" = "LVM", "4" = "UVM"
      )
    }

    dataTable <- dataTable %>%
      filter(PerfLevel == PerfLevel_s) %>% # select one perf level
      mutate(
        Subj    = factor(Subj, levels = 1:nsubj, labels = subjList),
        LocComb = factor(recode_loccomb(LocComb)),
        SF      = factor(SF),
        Ecc     = factor(Ecc)
      )

    # 📌 Determine number of comparisons for Bonferroni correction
    nLocComb <- length(unique(dataTable$LocComb))
    nSF <- length(unique(dataTable$SF))

    # ---- 🔁 Loop Through boot iterations (to do stats) ----
    # Setup parallel backend
    cl <- makeCluster(detectCores() - 1)
    registerDoParallel(cl)


    # Parallel foreach loop
    results_allB <- foreach(iBoot_s = 1:nBoot, .packages = c("lmerTest", "MuMIn", "dplyr", "emmeans", "effectsize")) %dopar% {
      # Filter to specific boot iteration
      dataTable_perB <- dataTable %>% filter(iBoot == iBoot_s)

      # Convert param to numeric
      dataTable_perB[[param]] <- as.numeric(dataTable_perB[[param]])

      # Select the model
      formula <- formulas_all[["formula_Intrc_RandIntcpt"]]
      model <- lmer(as.formula(sprintf("%s ~ %s", param, formula)), data = dataTable_perB)
      r2 <- r.squaredGLMM(model)
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
      model_anova_full <- model_anova_full[order(match(
        model_anova_full$Var,
        c("LocComb", "Ecc", "SF", "LocComb:SF", "LocComb:Ecc", "SF:Ecc", "LocComb:SF:Ecc")
      )), ]
      # Post-hoc if IV is Loc
      mc_Loc_df <- emmeans(model, pairwise ~ LocComb)$contrasts %>%
        as.data.frame() %>%
        transmute(
          contrast,
          diff = round(estimate, 3), # Estimate difference between locations
          df = round(df, 1),
          t = round(t.ratio, 2),
          pVal = round(p.value * nComp_Loc, 3)
        )

      # Post-hoc for Loc x Ecc
      mc_LocxEcc_df <- emmeans(model, pairwise ~ LocComb * Ecc)$contrasts %>%
        as.data.frame() %>%
        transmute(
          contrast,
          diff = round(estimate, 3), # Estimate difference between locations
          df = round(df, 1),
          t = round(t.ratio, 2),
          pVal = round(p.value * nComp_LocxEcc, 3)
        )

      # Post-hoc for Loc x SF
      mc_LocxSF_df <- emmeans(model, pairwise ~ LocComb * SF)$contrasts %>%
        as.data.frame() %>%
        transmute(
          contrast,
          diff = round(estimate, 3), # Estimate difference between locations
          df = round(df, 1),
          t = round(t.ratio, 2),
          pVal = round(p.value * nComp_LocxSF, 3)
        )

      # Post-hoc for Loc x Ecc x SF
      mc_LocxEccxSF_df <- emmeans(model, pairwise ~ LocComb * Ecc * SF)$contrasts %>%
        as.data.frame() %>%
        transmute(
          contrast,
          diff = round(estimate, 3), # Estimate difference between locations
          df = round(df, 1),
          t = round(t.ratio, 2),
          pVal = round(p.value * nComp_LocxEccxSF, 3)
        )

      # Compile output: return a list for this bootstrap
      list(
        model_anova_full = model_anova_full,
        mc_Loc_df = mc_Loc_df,
        mc_LocxEcc_df = mc_LocxEcc_df,
        mc_LocxSF_df = mc_LocxSF_df,
        mc_LocxEccxSF_df = mc_LocxEccxSF_df
      )
    } # end of bootstrap loop

    # Stop the cluster
    stopCluster(cl)

    # === Compile ANOVA ====
    model_anova_allB <- lapply(results_allB, function(x) x$model_anova_full)
    model_anova_allB <- bind_rows(model_anova_allB, .id = "Boot")
    model_anova_CI <- model_anova_allB %>%
      group_by(Var) %>%
      summarise(
        F_med = round(median(F, na.rm = TRUE), 3),
        F_lb = round(quantile(F, perc_lb, na.rm = TRUE), 3),
        F_ub = round(quantile(F, perc_ub, na.rm = TRUE), 3),
        df1_med = round(median(df1, na.rm = TRUE), 3),
        df2_med = round(median(df2, na.rm = TRUE), 3),
        p_med = round(median(p, na.rm = TRUE), 3),
        Eta2p_med = round(median(Eta2p, na.rm = TRUE), 3),
        Eta2p_lb = round(quantile(Eta2p, perc_lb, na.rm = TRUE), 3),
        Eta2p_ub = round(quantile(Eta2p, perc_ub, na.rm = TRUE), 3),
        .groups = "drop"
      ) %>%
      mutate(
        sig = symnum(p_med,
          corr = FALSE,
          cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
          symbols = c("***", "**", "*", ".", "ns")
        )
      )

    # ==== Compile interactions ====
    fxn_getCI4MC <- function(df, group_col, t_col, diff_col, df_col, p_col, nComp) {
      df %>%
        group_by({{ group_col }}) %>%
        summarise(
          t_med = round(median({{ t_col }}, na.rm = TRUE), 3),
          t_lb = round(quantile({{ t_col }}, perc_lb, na.rm = TRUE), 3),
          t_ub = round(quantile({{ t_col }}, perc_ub, na.rm = TRUE), 3),
          df_med = round(median({{ df_col }}, na.rm = TRUE), 3),
          p_emp2tail = pmin(min(mean({{ diff_col }} > 0), mean({{ diff_col }} < 0)) * 2 * nComp, 1), # Clamp to 1
          p_med = round(median({{ p_col }}, na.rm = TRUE), 3),
          d_emp = round(median({{ diff_col }}, na.rm = TRUE) / sd({{ diff_col }}, na.rm = TRUE), 3), # empirical Cohen's d
          .groups = "drop"
        ) %>%
        mutate(
          Dir = case_when(
            t_med > 0 ~ ">",
            t_med < 0 ~ "<",
            TRUE ~ "="
          ),
          sig = symnum(p_emp2tail,
            corr = FALSE,
            cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
            symbols = c("***", "**", "*", ".", "ns")
          )
        )
    } # end of getCI4MC

    # Extract posthoc results for Loc
    mc_Loc_allB <- lapply(results_allB, function(x) x$mc_Loc_df)
    mc_Loc_allB <- bind_rows(mc_Loc_allB, .id = "Boot")
    mc_Loc_CI <- fxn_getCI4MC(mc_Loc_allB, contrast, t, diff, df, pVal, nComp_Loc)

    # Extract posthoc results for LocxEcc
    mc_LocxEcc_allB <- lapply(results_allB, function(x) x$mc_LocxEcc_df)
    mc_LocxEcc_allB <- bind_rows(mc_LocxEcc_allB, .id = "Boot")
    mc_LocxEcc_CI <- fxn_getCI4MC(mc_LocxEcc_allB, contrast, t, diff, df, pVal, nComp_LocxEcc)

    # Extract posthoc results for LocxSF
    mc_LocxSF_allB <- lapply(results_allB, function(x) x$mc_LocxSF_df)
    mc_LocxSF_allB <- bind_rows(mc_LocxSF_allB, .id = "Boot")
    mc_LocxSF_CI <- fxn_getCI4MC(mc_LocxSF_allB, contrast, t, diff, df, pVal, nComp_LocxSF)

    # Extract posthoc results for LocxEccxSF
    mc_LocxEccxSF_allB <- lapply(results_allB, function(x) x$mc_LocxEccxSF_df)
    mc_LocxEccxSF_allB <- bind_rows(mc_LocxEccxSF_allB, .id = "Boot")
    mc_LocxEccxSF_CI <- fxn_getCI4MC(mc_LocxEccxSF_allB, contrast, t, diff, df, pVal, nComp_LocxEccxSF)

    # ==== Create helper functions to format reports ====
    # Format ANOVA results
    fxn_format_anova <- function(df, term) {
      row <- df[df$Var == term, ]
      if (nrow(row) == 0) {
        return(NULL)
      } else if (nrow(row) > 1) {
        warning(sprintf("Multiple rows found for term '%s'. Using the first one.", term))
        row <- row[1, ]
      }

      stars <- if (row$p_med < 0.001) "***" else if (row$p_med < 0.01) "**" else if (row$p_med < 0.05) "*" else if (row$p_med < 0.1) "mg" else "ns"

      if (nBoot == 1) {
        sprintf(
          "F(%.0f, %.1f) = %.3f, %s = %.3f, Eta2p = %.3f %s",
          row$df1_med, row$df2_med,
          row$F_med,
          str_pBOOT, row$p_med,
          row$Eta2p_med,
          stars
        )
      } else {
        sprintf(
          "F(%.0f, %.1f) = %.3f [%.3f, %.3f], %s = %.3f, Eta2p = %.3f [%.3f, %.3f] %s",
          row$df1_med, row$df2_med,
          row$F_med, row$F_lb, row$F_ub,
          str_pBOOT, row$p_med,
          row$Eta2p_med, row$Eta2p_lb, row$Eta2p_ub,
          stars
        )
      }
    } # end of format_anova

    # Format posthoc results of one-way ANOVA
    fxn_format_posthoc <- function(df) {
      apply(df, 1, function(r) {
        contrast <- gsub(" - ", r["Dir"], r["contrast"])
        tval <- as.numeric(r["t_med"])
        t_lb <- as.numeric(r["t_lb"])
        t_ub <- as.numeric(r["t_ub"])
        df_ <- as.numeric(r["df_med"])
        p_emp2tail <- as.numeric(r["p_emp2tail"])
        pval <- as.numeric(r["p_med"])
        d_emp <- as.numeric(r["d_emp"]) # PROBLEMATIC!!
        sig <- r["sig"]

        if (nBoot == 1) {
          sprintf(
            "  %s: t(%.1f) = %.3f, %s = %.3f, CohenD = %.3f, %s = %.3f %s\n",
            contrast, df_, tval, str_pEMP, p_emp2tail, d_emp, str_pBOOT, pval, sig
          )
        } else {
          sprintf(
            "  %s: t(%.1f) = %.3f [%.3f, %.3f], %s = %.3f, CohenD = %.3f, %s = %.3f %s\n",
            contrast, df_, tval, t_lb, t_ub, str_pEMP, p_emp2tail, d_emp, str_pBOOT, pval, sig
          )
        }
      })
    } # end of format_posthoc

    # Format posthoc results of Loc x Ecc
    if (str_SF != "SF6") {
      fxn_format_posthoc_LocxEcc <- function(df, type = c("sameEcc", "sameLoc")) {
        type <- match.arg(type)

        df %>%
          mutate(
            LocxEcc1 = sub(" -.*", "", contrast),
            LocxEcc2 = sub(".*- ", "", contrast),
            Loc1 = sub(" .*", "", LocxEcc1),
            Loc2 = sub(" .*", "", LocxEcc2),
            Ecc1 = sub(".* ", "", LocxEcc1),
            Ecc2 = sub(".* ", "", LocxEcc2)
          ) %>%
          filter(
            if (type == "sameEcc") Ecc1 == Ecc2 else Loc1 == Loc2,
            # p_med < 0.1
          ) %>%
          mutate(
            Group = if (type == "sameEcc") Ecc1 else Loc1,
            contrast_clean = case_when(
              type == "sameEcc" ~ paste(Loc1, Dir, Loc2),
              type == "sameLoc" ~ paste(Ecc1, Dir, Ecc2)
            ),
            label = ifelse(
              sig %in% c("ns", "."),
              sprintf(
                "  %s: t(%.1f) = %.3f [%.3f, %.3f], %s = %.3f, CohenD = %.3f, %s = %.3f",
                contrast_clean, df_med, t_med, t_lb, t_ub, str_pEMP, p_emp2tail, d_emp, str_pBOOT, p_med
              ),
              sprintf(
                "  %s: t(%.1f) = %.3f [%.3f, %.3f], %s = %.3f, CohenD = %.3f, %s = %.3f %s",
                contrast_clean, df_med, t_med, t_lb, t_ub, str_pEMP, p_emp2tail, d_emp, str_pBOOT, p_med, sig
              )
            )
          ) %>%
          group_by(Group) %>%
          summarise(lines = paste(label, collapse = "\n"), .groups = "drop") %>%
          mutate(formatted = sprintf("[%s]\n%s", Group, lines)) %>%
          pull(formatted) %>%
          paste(collapse = "\n\n") # proper newlines between groups
      }
    } # end of format_posthoc_LocxEcc

    # Format posthoc results of Loc x SF
    if (str_SF != "SF6") {
      fxn_format_posthoc_LocxSF <- function(df, type = c("sameSF", "sameLoc")) {
        type <- match.arg(type)

        df %>%
          mutate(
            LocxSF1 = sub(" -.*", "", contrast),
            LocxSF2 = sub(".*- ", "", contrast),
            Loc1 = sub(" .*", "", LocxSF1),
            Loc2 = sub(" .*", "", LocxSF2),
            SF1 = sub(".* ", "", LocxSF1),
            SF2 = sub(".* ", "", LocxSF2)
          ) %>%
          filter(
            if (type == "sameSF") SF1 == SF2 else Loc1 == Loc2,
            # p_med < 0.1
          ) %>%
          mutate(
            Group = if (type == "sameSF") SF1 else Loc1,
            contrast_clean = case_when(
              type == "sameSF" ~ paste(Loc1, Dir, Loc2),
              type == "sameLoc" ~ paste(SF1, Dir, SF2)
            ),
            label = ifelse(
              sig %in% c("ns", "."),
              sprintf(
                "  %s: t(%.1f) = %.3f [%.3f, %.3f], %s = %.3f, CohenD = %.3f, %s = %.3f",
                contrast_clean, df_med, t_med, t_lb, t_ub, str_pEMP, p_emp2tail, d_emp, str_pBOOT, p_med
              ),
              sprintf(
                "  %s: t(%.1f) = %.3f [%.3f, %.3f], %s = %.3f, CohenD = %.3f, %s = %.3f %s",
                contrast_clean, df_med, t_med, t_lb, t_ub, str_pEMP, p_emp2tail, d_emp, str_pBOOT, p_med, sig
              )
            )
          ) %>%
          group_by(Group) %>%
          summarise(lines = paste(label, collapse = "\n"), .groups = "drop") %>%
          mutate(formatted = sprintf("[%s]\n%s", Group, lines)) %>%
          pull(formatted) %>%
          paste(collapse = "\n\n") # proper newlines between groups
      }
    } # end of format_posthoc_LocxSF


    # Format posthoc results of Loc x Ecc x SF
    fxn_format_posthoc_LocxEccxSF <- function(df) {
      df %>%
        mutate(
          LocxEccSF1 = sub(" -.*", "", contrast),
          LocxEccSF2 = sub(".*- ", "", contrast),
          Loc1 = word(LocxEccSF1, 1),
          Loc2 = word(LocxEccSF2, 1),
          Ecc1 = word(LocxEccSF1, 2),
          Ecc2 = word(LocxEccSF2, 2),
          SF1 = word(LocxEccSF1, 3),
          SF2 = word(LocxEccSF2, 3)
        ) %>%
        filter(Ecc1 == Ecc2, SF1 == SF2) %>%
        mutate(
          Group = paste(SF1, Ecc1, sep = "_"),
          contrast_clean = paste(Loc1, Dir, Loc2),
          label = ifelse(
            sig %in% c("ns", "."),
            sprintf(
              "  %s: t(%.1f) = %.3f [%.3f, %.3f], %s = %.3f, CohenD = %.3f, %s = %.3f",
              contrast_clean, df_med, t_med, t_lb, t_ub, str_pEMP, p_emp2tail, d_emp, str_pBOOT, p_med
            ),
            sprintf(
              "  %s: t(%.1f) = %.3f [%.3f, %.3f], %s = %.3f, CohenD = %.3f, %s = %.3f %s",
              contrast_clean, df_med, t_med, t_lb, t_ub, str_pEMP, p_emp2tail, d_emp, str_pBOOT, p_med, sig
            )
          )
        ) %>%
        group_by(Group) %>%
        summarise(lines = paste(label, collapse = "\n"), .groups = "drop") %>%
        mutate(formatted = sprintf("[%s]\n%s", Group, lines)) %>%
        pull(formatted) %>%
        paste(collapse = "\n\n")
    }

    # ==== Format & Print ====
    text_anova_Loc <- fxn_format_anova(model_anova_CI, "LocComb")
    text_anova_Ecc <- fxn_format_anova(model_anova_CI, "Ecc")
    text_anova_SF <- fxn_format_anova(model_anova_CI, "SF")
    text_anova_LocxEcc <- fxn_format_anova(model_anova_CI, "LocComb:Ecc")
    text_anova_LocxSF <- fxn_format_anova(model_anova_CI, "LocComb:SF")
    text_anova_SFxEcc <- fxn_format_anova(model_anova_CI, "SF:Ecc")
    text_anova_LocxSFxEcc <- fxn_format_anova(model_anova_CI, "LocComb:SF:Ecc")

    cat(" ==== [3] Loc x Ecc x SF ====\n")
    if (param %in% c("Nadd", "Gamma")) {
      text_mc_LocxEccxSF <- "Not applicable for Nadd and Gamma"
    } else {
      text_mc_LocxEccxSF <- fxn_format_posthoc_LocxEccxSF(mc_LocxEccxSF_CI)
    }

    cat(text_anova_LocxSFxEcc, "\n\n", text_mc_LocxEccxSF, "\n\n")

    cat(" ==== [2] Loc x Ecc ====\n")
    text_mc_LocxEcc_sameEcc <- fxn_format_posthoc_LocxEcc(mc_LocxEcc_CI, type = "sameEcc")
    # text_mc_LocxEcc_sameLoc <- fxn_format_posthoc_LocxEcc(mc_LocxEcc_CI, type = "sameLoc")
    cat(text_anova_LocxEcc, "\n\n", text_mc_LocxEcc_sameEcc, "\n\n")

    cat(" ==== [2] Loc x SF ====\n")
    text_mc_LocxSF_sameSF <- fxn_format_posthoc_LocxSF(mc_LocxSF_CI, type = "sameSF")
    # text_mc_LocxSF_sameLoc <- fxn_format_posthoc_LocxSF(mc_LocxSF_CI, type = "sameLoc")
    cat(text_anova_LocxSF, "\n\n", text_mc_LocxSF_sameSF, "\n\n")

    cat(" ==== [1] Loc ====\n")
    text_mc_Loc <- fxn_format_posthoc(mc_Loc_CI)
    cat(text_anova_Loc, "\n\n", text_mc_Loc, "\n\n")
# 
# 
#     
#     # ==== Visualize 3-way interaction ====
#     # Add EccLoc composite and jitter
#     dataTable_med <- dataTable %>%
#       group_by(Subj, LocComb, SF, Ecc) %>%
#       summarise(across(c(ThreshN0_t, Gain, GainLog, Nadd, Gamma), median), .groups = "drop") %>%
#       mutate(
#         LocComb = factor(LocComb),
#         SF = factor(SF),
#         Ecc = factor(Ecc),
#         EccLoc = interaction(Ecc, LocComb, sep = "_", lex.order = TRUE), # (Ecc, LocComb), so that 1=4_HM 2=4_VM 3=8_HM 4=8_VM
#         x_num = as.numeric(EccLoc),
#         x_jitter = x_num + runif(n(), -jitter_width, jitter_width)
#       )
# 
#     data_summary <- dataTable_med %>%
#       group_by(SF, Ecc, LocComb, EccLoc) %>%
#       summarise(
#         mean_val = mean(.data[[param]]),
#         se = sd(.data[[param]]) / sqrt(n()),
#         .groups = "drop"
#       ) %>%
#       mutate(
#         x_num = as.numeric(EccLoc)
#       )
# 
#     # Plot
#     p <- ggplot() +
#       # Individual lines (connect same-Eccentricity points)
#       geom_line(
#         data = dataTable_med,
#         aes(x = x_jitter, y = get(param), color = "grey", group = interaction(Subj, Ecc)),
#         alpha = 0.3, size = 1
#       ) +
# 
#       # Group averages and error bars
#       geom_errorbar(
#         data = data_summary,
#         aes(x = x_num, ymin = mean_val - se, ymax = mean_val + se, color = LocComb),
#         width = 0.2, position = position_dodge(width = 0.3), linewidth = 1
#       ) +
#       geom_line( # Group mean lines (within each Eccentricity)
#         data = data_summary,
#         aes(x = x_num, y = mean_val, group = Ecc),
#         color = "black", linewidth = 1.2
#       ) +
#       geom_point(
#         data = data_summary,
#         aes(x = x_num, y = mean_val, color = LocComb, shape = SF),
#         position = position_dodge(width = 0.3), size = 3
#       ) +
#       facet_wrap(~SF) +
#       
#       labs(
#         # title = sprintf(
#         #   "[%s%s | %s] %s (nBoot=%d)\n[3] Loc x SF x Ecc: %s\n[2] Loc x Ecc: %s\n[2] Loc x SF: %s\n[1] Loc: %s",
#         #   str_SF, str_n9, str_loc, param, nBoot,
#         #   text_anova_LocxSFxEcc, text_anova_LocxEcc, text_anova_LocxSF, text_anova_Loc
#         # ),
#         title = sprintf("[%s%s | %s] %s (nBoot=%d)", str_SF, str_n9, str_loc, param, nBoot),
#         y = param,
#         x = "Location × Eccentricity",
#         color = "Location", shape = "SF"
#       ) +
#       # Define x-axis labels
#       scale_x_continuous(
#         breaks = data_summary$x_num,
#         labels = data_summary$EccLoc
#       ) +
#       # Map color
#       scale_color_manual(values = location_colors) +
# 
#       # Map shape
#       scale_shape_manual(values = shape_SF) +
# 
#       # Define theme
#       theme_bw(base_size = 16) +
#         theme_custom_3way +
#         theme(
#           legend.position = "none", # turn off legends
#           panel.grid.major = element_blank(), # turn off grid lines
#           panel.grid.minor = element_blank(), # turn off grid lines
#           
#           # remove the facet band
#           strip.background = element_blank(),
#           strip.text = element_blank()
#         )
# 
#     print(p)
# 
#     # Save plot
#     ggsave(sprintf("%s/3way_interaction/%s_%s_nBoot%d.png", nameFolder_Fig, param, str_loc, nBoot),
#       plot = p, width = sz_wd_3way, height = sz_ht_3way, dpi = 300
#     )
# 
#     # ==== Visualize 2-way interactions: Loc x Ecc ====
#     # Create composite factor for coloring when SF is not a factor
#     dataTable$SF <- as.character(dataTable$SF)
#     
#     dataTable <- dataTable %>%
#       mutate(LocComb_Ecc = interaction(Ecc, LocComb, sep = "_", lex.order = TRUE))
#     
#     # Define color palette based on str_loc
#     if (str_loc == "HM4VM4HM8VM8") {
#       colors_LocxEcc <- unlist(location_colors[c("04HM4", "05VM4", "08HM8", "09VM8")])
#       names(colors_LocxEcc) <- c("4_HM", "4_VM", "8_HM", "8_VM")
#     } else {
#       colors_LocxEcc <- unlist(location_colors[c("06LVM4", "07UVM4", "10LVM8", "11UVM8")])
#       names(colors_LocxEcc) <- c("4_LVM", "4_UVM", "8_LVM", "8_UVM")
#     }
#     
#     plot_LocxEcc <- function(data, param, colors_LocxEcc, jitter_width = 0.1) {
#       stopifnot(all(c("LocComb", "Ecc", "LocComb_Ecc", param) %in% names(data)))
#       
#       data_med <- data %>%
#         group_by(Subj, LocComb, Ecc, LocComb_Ecc) %>%
#         summarise({{ param }} := median(.data[[param]]), .groups = "drop") %>%
#         mutate(
#           x_factor = interaction(Ecc, LocComb, sep = "_", lex.order = TRUE),
#           x_num = as.numeric(x_factor),
#           x_jitter = x_num + runif(n(), -jitter_width, jitter_width)
#         )
#       
#       data_summary <- data_med %>%
#         group_by(LocComb, Ecc, LocComb_Ecc, x_factor) %>%
#         summarise(
#           mean_val = mean(.data[[param]]),
#           se = sd(.data[[param]]) / sqrt(n()), .groups = "drop"
#         ) %>%
#         mutate(x_num = as.numeric(x_factor))
#       
#       p <- ggplot() +
#         geom_line(
#           data = data_med,
#           aes(x = x_jitter, y = .data[[param]], group = interaction(Subj, Ecc)),
#           color = "grey", alpha = 0.3, linewidth = 1
#         ) +
#         geom_errorbar(
#           data = data_summary,
#           aes(x = x_num, ymin = mean_val - se, ymax = mean_val + se, color = LocComb_Ecc),
#           width = 0, linewidth = 1
#         ) +
#         geom_line(
#           data = data_summary,
#           aes(x = x_num, y = mean_val, group = Ecc),
#           color = "black", linewidth = 1.2
#         ) +
#         geom_point(
#           data = data_summary,
#           aes(x = x_num, y = mean_val, color = LocComb_Ecc),
#           size = 3, shape = 16
#         ) +
#         scale_color_manual(values = colors_LocxEcc) +
#         labs(
#           title = sprintf("[%s%s | %s] %s | Loc x Ecc (nBoot=%d)", 
#                           str_SF, str_n9, str_loc, param, nBoot),
#           x = "Ecc_Loc",
#           y = param,
#           color = "LocComb_Ecc"
#         ) +
#         scale_x_continuous(
#           breaks = data_summary$x_num,
#           labels = data_summary$x_factor
#         ) +
#         theme_bw(base_size = 16) + 
#         theme_custom_2way +
#         theme(legend.position = "none") + # turn off legends
#         theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) # turn off grid lines
#         
#       print(p)
#       return(p)
#     }
#     # Plot Loc x Ecc
#     p_LocxEcc <- plot_LocxEcc(data = dataTable, param,colors_LocxEcc)
#     ggsave(sprintf("%s/3way_interaction/%s_%s_LocxEcc_nBoot%d.png", nameFolder_Fig, param, str_loc, nBoot),
#            plot = p_LocxEcc, width = sz_wd_2way, height = sz_ht_2way, dpi = 300
#     )
#     
#     # ==== Visualize 2-way interactions: Loc x SF ====
#     plot_LocxSF <- function(data, param, location_colors, shape_SF, jitter_width = 0.1) {
#       stopifnot(all(c("LocComb", "SF", param) %in% names(data)))
#       
#       data_med <- data %>%
#         group_by(Subj, LocComb, SF) %>%
#         summarise({{ param }} := median(.data[[param]]), .groups = "drop") %>%
#         mutate(
#           x_factor = interaction(SF, LocComb, sep = "_", lex.order = TRUE),
#           x_num = as.numeric(x_factor),
#           x_jitter = x_num + runif(n(), -jitter_width, jitter_width)
#         )
#       
#       data_summary <- data_med %>%
#         group_by(LocComb, SF, x_factor) %>%
#         summarise(
#           mean_val = mean(.data[[param]]),
#           se = sd(.data[[param]]) / sqrt(n()), .groups = "drop"
#         ) %>%
#         mutate(x_num = as.numeric(x_factor))
#       
#       p <- ggplot() +
#         geom_line(
#           data = data_med,
#           aes(x = x_jitter, y = .data[[param]], group = interaction(Subj, SF)),
#           color = "grey", alpha = 0.3, linewidth = 1
#         ) +
#         geom_errorbar(
#           data = data_summary,
#           aes(x = x_num, ymin = mean_val - se, ymax = mean_val + se, color = LocComb),
#           width = 0.1, linewidth = 1
#         ) +
#         geom_line(
#           data = data_summary,
#           aes(x = x_num, y = mean_val, group = SF),
#           color = "black", linewidth = 1.2
#         ) +
#         geom_point(
#           data = data_summary,
#           aes(x = x_num, y = mean_val, color = LocComb, shape = SF),
#           size = 3
#         ) +
#         scale_color_manual(values = location_colors) +
#         scale_shape_manual(values = shape_SF) +
#         labs(
#           title = sprintf("[%s%s | %s] %s | Loc x SF (nBoot=%d)", str_SF, str_n9, str_loc, param, nBoot),
#           x = "SF_Loc",
#           y = param,
#           color = "LocComb",
#           shape = "SF"
#         ) +
#         scale_x_continuous(
#           breaks = data_summary$x_num,
#           labels = data_summary$x_factor
#         ) +
#         theme_bw(base_size = 16) + 
#         theme_custom_2way +
#         theme(legend.position = "none") + # turn off legends
#         theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) # turn off grid lines
#       
#       print(p)
#       return(p)
#     }
#     
#     # Plot Loc x SF
#     p_LocxSF <- plot_LocxSF(dataTable, param, location_colors, shape_SF)
#     ggsave(sprintf("%s/3way_interaction/%s_%s_LocxSF_nBoot%d.png", nameFolder_Fig, param, str_loc, nBoot),
#            plot = p_LocxSF, width = sz_wd_2way, height = sz_ht_2way, dpi = 300
#     )
    

  } # end param loop
} # end loc loop

sink() # Close log file

while (sink.number() > 0) sink(NULL)


end_time <- Sys.time() # ⏱️ toc
dur <- end_time - start_time # See how much time passed
print(round(dur, 1))
cat(sprintf(
  "\n\n============= %s%s (P%.0f) ALL DONE ==============\n",
  str_SF, str_n9, PerfLevel_s * 100
))