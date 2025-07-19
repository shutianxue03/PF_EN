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
param_list <- c("ThreshN0_t", "Gain", "GainLog", "Nadd", "Gamma") # Parameters to test

if (nBoot==1){
  str_pBOOT <- "p_obs" # the p to report
  str_pEMP <- "ignore"
}else{
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
    formula_Intrc              = "LocComb * SF",
    formula_Intrc_RandIntcpt   = "LocComb * SF + (1|Subj)",
    formula_Intrc_RandSlopeLoc = "LocComb * SF + (LocComb|Subj)",
    formula_Intrc_Full         = "LocComb * SF + (1 + LocComb | Subj)" # allows individual differences in how subjects respond across locations, while keeping SF fixed across subjects (since some are missing).
  )
}

# ==== 📁 Folder Setup ====
nameFolder_Output_variation <- sprintf("%s/Output_2Variation", nameFolder_Outputs)
if (!dir.exists(nameFolder_Output_variation)) dir.create(nameFolder_Output_variation, recursive = TRUE)

# ==== 🔁 Loop Through Parameters (Gain, Nadd, Gamma) ====
for (param in param_list) {
  
  # ==== 🔁 Loop Through Print Modes (ANOVA, LMM, Step) ====
  if (flag_plot7Locs == TRUE) {
    sink(sprintf("%s/ANOVA_%s_nBoot%d_7Loc.txt", nameFolder_Output_variation, param, nBoot))
  } else {
    sink(sprintf("%s/ANOVA_%s_nBoot%d.txt", nameFolder_Output_variation, param, nBoot))
  }

  # ==== 🔁 Loop Through Location Groups ====
  for (str_loc in str_loc_list) {
    
    cat(sprintf(
      "\n\n*******************************************************************\n [%s%s] Location: %s | Param: %s (nBoot = %d) \n*******************************************************************\n\n",
      str_SF, str_n9, str_loc, param, nBoot
    ))
    
    # 🧹 Load and Prepare Data
    dataTable <- read.csv(sprintf("%s/%s_nBoot%d.csv", nameFolder_Load, str_loc, nBoot))

    dataTable <- dataTable %>%
      filter(PerfLevel == PerfLevel_s) %>%
      mutate(
        Subj = factor(Subj, levels = 1:nsubj, labels = subjList),
        LocComb = recode(as.character(LocComb),
          "1" = "01Fov", "2" = "02Ecc4", "3" = "03Ecc8",
          "4" = "04HM4", "5" = "05VM4", "6" = "06LVM4", "7" = "07UVM4",
          "8" = "08HM8", "9" = "09VM8", "10" = "10LVM8", "11" = "11UVM8"
        ),
        LocComb = factor(LocComb, levels = unique(LocComb)),
        SF = as.factor(SF),
        PerfLevel = as.factor(PerfLevel)
      )

    # 📌 Determine number of comparisons for Bonferroni correction
    nLocComb <- length(unique(dataTable$LocComb))
    nSF <- length(unique(dataTable$SF))
    # Set number of comparisons
    nComp_Loc <- if (nLocComb == 3) 3 else 1 # nComp=3: 3 pairs (Fov vs. HM4, Fov vs. HM8, HM4 vs. HM8); nComp=2: 1 pair (HM4 vs. VM4)
    nComp_SF <- if (nSF == 2) 1 else 3 # nComp=1: 1 pair (SF4 vs. SF6); nComp=3:3 pairs (SF4 vs. SF6, SF4 vs. SF5, SF5 vs. SF6);
    nComp_LocxSF <- nComp_Loc * nSF

    # Initialize storage for this param
    model_anova_allB <- list()
    mc_Loc_allB <- list()
    mc_SF_allB <- list()
    mc_LocxSF_allB <- list()

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
      model_anova_full <- model_anova_full[order(match(model_anova_full$Var, c("LocComb", "SF", "LocComb:SF"))), ]

      # Post-hoc for Loc (needed for all SFxSubj cond)
      mc_Loc_df <- emmeans(model, pairwise ~ LocComb, adjust = "bonferroni")$contrasts %>%
        as.data.frame() %>%
        transmute(
          contrast,
          diff = round(estimate, 3), # Estimate difference between locations
          df = round(df, 1),
          t = round(t.ratio, 2),
          pVal = round(p.value, 3),
        )
      print(mc_Loc_df$p)

      if (str_SF != "SF6") {
        # Posthoc for SF
        mc_SF_df <- emmeans(model, pairwise ~ SF, adjust = "bonferroni")$contrasts %>%
          as.data.frame() %>%
          transmute(
            contrast,
            diff = round(estimate, 3), # Estimate difference between SFs
            df = round(df, 1),
            t = round(t.ratio, 2),
            pVal = round(p.value, 3),
          )

        # Posthoc for LocxSF
        # mc_LocxSF_df <- as.data.frame(mc_LocxSF$contrasts)
        mc_LocxSF_df <- emmeans(model, pairwise ~ LocComb * SF, adjust = "bonferroni")$contrasts %>%
          as.data.frame() %>%
          transmute(
            contrast,
            diff = round(estimate, 3), # Estimate difference between LocComb * SF
            df = round(df, 1),
            t = round(t.ratio, 2),
            pVal = round(p.value, 3),
          )
      }
      # Output: return a list for this bootstrap
      if (str_SF == "SF6") {
        list(
          model_anova_full = model_anova_full,
          mc_Loc_df = mc_Loc_df
        )
      } else {
        list(
          model_anova_full = model_anova_full,
          mc_Loc_df = mc_Loc_df,
          mc_SF_df = mc_SF_df,
          mc_LocxSF_df = mc_LocxSF_df
        )
      }
    } # end of bootstrap loop

    # Stop the cluster
    stopCluster(cl)

    # 📦 Unpack the results
    model_anova_allB <- lapply(results_allB, function(x) x$model_anova_full)
    mc_Loc_allB <- lapply(results_allB, function(x) x$mc_Loc_df)
    if (str_SF != "SF6") {
      mc_SF_allB <- lapply(results_allB, function(x) x$mc_SF_df)
      mc_LocxSF_allB <- lapply(results_allB, function(x) x$mc_LocxSF_df)
    }

    # === Summarize ANOVA ====
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

    # ==== Create helper functions to conduct posthoc stats ====
    fxn_getCI4MC <- function(df, group_col, t_col, diff_col, df_col, p_col, nComp) {
      df %>%
        group_by({{ group_col }}) %>%
        summarise(
          t_med = round(median({{ t_col }}, na.rm = TRUE), 3),
          t_lb = round(quantile({{ t_col }}, perc_lb, na.rm = TRUE), 3),
          t_ub = round(quantile({{ t_col }}, perc_ub, na.rm = TRUE), 3),
          df_med = round(median({{ df_col }}, na.rm = TRUE), 3),
          p_emp2tail = pmin(min(mean({{ diff_col }} > 0), mean({{ diff_col }} < 0)) * 2 * nComp,1) , # Clamp to 1
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

    mc_Loc_allB <- bind_rows(mc_Loc_allB, .id = "Boot")
    mc_Loc_CI <- fxn_getCI4MC(mc_Loc_allB, contrast, t, diff, df, pVal, nComp_Loc)

    if (str_SF != "SF6") {
      mc_SF_allB <- bind_rows(mc_SF_allB, .id = "Boot")
      mc_SF_CI <- fxn_getCI4MC(mc_SF_allB, contrast, t, diff, df, pVal, nComp_SF)

      mc_LocxSF_allB <- bind_rows(mc_LocxSF_allB, .id = "Boot")
      mc_LocxSF_CI <- fxn_getCI4MC(mc_LocxSF_allB, contrast, t, diff, df, pVal, nComp_LocxSF)
    }

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

      stars <- if (row$p_med < 0.001) "***" else if (row$p_med < 0.01) "**" else if (row$p_med < 0.05) "*" else if (row$p_med < 0.1) "mg" else ""

      if (nBoot == 1) {
        sprintf(
          "F(%.0f, %.1f) = %.3f, %s = %.3f, Eta²ₚ = %.3f %s",
          row$df1_med, row$df2_med,
          row$F_med,
          str_pBOOT, row$p_med,
          row$Eta2p_med,
          stars
        )
      } else {
        sprintf(
          "F(%.0f, %.1f) = %.3f [%.3f, %.3f], %s = %.3f, Eta²ₚ = %.3f [%.3f, %.3f] %s",
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
            sprintf("  %s: t(%.1f) = %.3f, %s = %.3f, CohenD = %.3f, %s = %.3f %s\n",
              contrast, df_, tval, str_pEMP, p_emp2tail, d_emp, str_pBOOT, pval, sig)
        } else {
            sprintf("  %s: t(%.1f) = %.3f [%.3f, %.3f], %s = %.3f, CohenD = %.3f, %s = %.3f %s\n",
              contrast, df_, tval, t_lb, t_ub, str_pEMP, p_emp2tail, d_emp, str_pBOOT, pval, sig)
        }
      })
    } # end of format_posthoc
    
    # Format posthoc results of interaction
    if (str_SF != "SF6") {
      fxn_format_posthoc_interaction <- function(df, type = c("sameSF", "sameLoc")) {
        type <- match.arg(type)

        df %>%
          mutate(
            LocSF1 = sub(" -.*", "", contrast),
            LocSF2 = sub(".*- ", "", contrast),
            Loc1 = sub(" .*", "", LocSF1),
            Loc2 = sub(" .*", "", LocSF2),
            SF1 = sub(".* ", "", LocSF1),
            SF2 = sub(".* ", "", LocSF2)
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
                sprintf("  %s: t(%.1f) = %.3f [%.3f, %.3f], %s = %.3f, CohenD = %.3f, %s = %.3f", 
                        contrast_clean, df_med, t_med, t_lb, t_ub, str_pEMP, p_emp2tail, d_emp, str_pBOOT, p_med),
                sprintf("  %s: t(%.1f) = %.3f [%.3f, %.3f], %s = %.3f, CohenD = %.3f, %s = %.3f %s",
                        contrast_clean, df_med, t_med, t_lb, t_ub, str_pEMP, p_emp2tail, d_emp, str_pBOOT, p_med, sig)
              )
            
          ) %>%
          group_by(Group) %>%
          summarise(lines = paste(label, collapse = "\n"), .groups = "drop") %>%
          mutate(formatted = sprintf("[%s]\n%s", Group, lines)) %>%
          pull(formatted) %>%
          paste(collapse = "\n\n") # proper newlines between groups
      } # end of format_posthoc_interaction
    }

    # ==== Format & Print ====
    cat(" === Main effect of Loc ===\n")
    text_anova_loc <- fxn_format_anova(model_anova_CI, "LocComb")
    text_posthoc_loc <- fxn_format_posthoc(mc_Loc_CI)
    cat(text_anova_loc, "\n\n", text_posthoc_loc, "\n")

    if (str_SF != "SF6") {

      cat(" ==== Interaction: Loc x SF ====\n")
      text_anova_LocxSF <- fxn_format_anova(model_anova_CI, "LocComb:SF")
      text_mc_LocxSF_sameSF <- fxn_format_posthoc_interaction(mc_LocxSF_CI, type = "sameSF")
      text_mc_LocxSF_sameLoc <- fxn_format_posthoc_interaction(mc_LocxSF_CI, type = "sameLoc")
      # cat(text_anova_LocxSF, "\n\n", text_mc_LocxSF_sameSF, "\n\n", text_mc_LocxSF_sameLoc, "\n")
      cat(text_anova_LocxSF, "\n\n", text_mc_LocxSF_sameSF, "\n\n") # omit SF results
      
      # cat(" === Main effect of SF ===\n")
      # text_anova_SF <- fxn_format_anova(model_anova_CI, "SF")
      # text_posthoc_SF <- fxn_format_posthoc(mc_SF_CI)
      # cat(text_anova_SF, "\n\n", text_posthoc_SF, "\n")
    }
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