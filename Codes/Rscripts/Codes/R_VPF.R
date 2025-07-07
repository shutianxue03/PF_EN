# # =====================================================
# # 📈 LMM - Variation Analysis: Location x SF Effects on Thresholds N0
# # Shutian Xue — April 8, 2025
# # =====================================================
# # This script performs the third stage of the analysis:
# # Evaluating how model parameters (Gain, Gamma, Nadd) vary across:
# #   - Spatial Frequencies (SF)
# #   - Visual Field Locations (LocComb)
# #
# # For each parameter:
# #   - Runs LMM with different random/fixed effects
# #   - Performs ANOVA and post-hoc tests (optional)
# #   - Generates visualizations of raw data and model predictions
# #   - Outputs results by SF × LocComb
# 
# # ==== 🧹 Clean environment ====
# start_time <- Sys.time() # ⏱️ tic
# graphics.off() # Close all plots
# cat("\014") # Clear console (like MATLAB's clc)
# 
# # ==== ⚙️ Settings ====
# # param_list <- c("ThreshN0_t") # Parameters to test
# param <- "ThreshN0_t"
# 
# # Define equation to calculate empirical two-way p-values
# get_empirical_p <- function(boot_vals, obs_val) {
#     2 * min(
#         mean(boot_vals >= obs_val),
#         mean(boot_vals <= obs_val)
#     )
# }
# 
# # List the formula of all models I want to test
# formulas_all <- c(
#     formula_Intrc              = "LocComb * SF",
#     formula_Intrc_RandIntcpt   = "LocComb * SF + (1|Subj)",
#     formula_Intrc_RandSlopeLoc = "LocComb * SF + (LocComb|Subj)",
#     formula_Intrc_Full         = "LocComb * SF + (1 + LocComb | Subj)" # allows individual differences in how subjects respond across locations, while keeping SF fixed across subjects (since some are missing).
# )
# 
# # ==== 📁 Folder Setup ====
# nameFolder_Output <- sprintf("%s/Output/Output_0VPF/%s%s", nameFolder, str_SF, str_n9)
# if (!dir.exists(nameFolder_Output)) dir.create(nameFolder_Output, recursive = TRUE)
# 
# # ==== 🔁 Loop Through Print Modes (ANOVA, LMM, Step) ====
# 
# sink(sprintf("%s/ANOVA_%s%s_boot.txt", nameFolder_Output, str_SF, str_n9))
# 
# # ==== 🔁 Loop Through Location Groups ====
# for (str_loc in str_loc_list) {
#     
#     # 🧹 Load and Prepare Data
#     # Load non-bootstrapped data
#     dataTable_emp <- read.csv(sprintf("DataTable/%s%s/%s_nBoot1.csv", str_SF, str_n9, str_loc))
#     # Load bootstrapped data
#     dataTable_boot <- read.csv(sprintf("DataTable/%s%s/%s_nBoot%d.csv", str_SF, str_n9, str_loc, nBoot))
# 
#     dataTable_emp <- dataTable_emp %>%
#         filter(PerfLevel == PerfLevel_s) %>%
#         mutate(
#             Subj = factor(Subj, levels = 1:nsubj, labels = subjList),
#             LocComb = recode(as.character(LocComb),
#                              "1" = "01Fov", "2" = "02Ecc4", "3" = "03Ecc8",
#                              "4" = "04HM4", "5" = "05VM4", "6" = "06LVM4", "7" = "07UVM4",
#                              "8" = "08HM8", "9" = "09VM8", "10" = "10LVM8", "11" = "11UVM8"
#             ),
#             LocComb = factor(LocComb, levels = unique(LocComb)),
#             SF = as.factor(SF),
#             PerfLevel = as.factor(PerfLevel)
#         )
#     dataTable_boot <- dataTable_boot %>%
#         filter(PerfLevel == PerfLevel_s) %>%
#         mutate(
#             Subj = factor(Subj, levels = 1:nsubj, labels = subjList),
#             LocComb = recode(as.character(LocComb),
#                 "1" = "01Fov", "2" = "02Ecc4", "3" = "03Ecc8",
#                 "4" = "04HM4", "5" = "05VM4", "6" = "06LVM4", "7" = "07UVM4",
#                 "8" = "08HM8", "9" = "09VM8", "10" = "10LVM8", "11" = "11UVM8"
#             ),
#             LocComb = factor(LocComb, levels = unique(LocComb)),
#             SF = as.factor(SF),
#             PerfLevel = as.factor(PerfLevel)
#         )
# 
#     # Number of bootstraps should be the unique levels of iBoot
#     nBoot <- length(unique(dataTable_boot$iBoot))
# 
#     cat(sprintf("\nBootstraps: %d \n\n", nBoot))
# 
#     cat(sprintf(
#         "\n\n*******************************************************************\n [%s%s] Location: %s\n*******************************************************************\n\n",
#         str_SF, str_n9, str_loc
#     ))
# 
#     # ---- 🔁 Conduct stats on the non-bootstrapped samples ----
#     # Convert param to numeric
#     dataTable_emp[[param]] <- as.numeric(dataTable_emp[[param]])
#     
#     # Select the model
#     formula <- formulas_all[["formula_Intrc_RandIntcpt"]]
#     model <- lmer(as.formula(sprintf("%s ~ %s", param, formula)), data = dataTable_emp)
#     r2 <- r.squaredGLMM(model)
#     model_anova_emp <- anova(model) %>% as.data.frame()
#     model_anova_emp$Var <- rownames(model_anova_emp)
#     
#     colnames(model_anova_emp) <- c("SS", "MSQ", "df1", "df2", "F", "p", "Var")
#     model_anova_emp <- model_anova_emp %>% mutate(across(c(SS, MSQ, df1, df2, F, p), ~ round(.x, 3)))
#     
#     # Obtain effect size (eta-squared)
#     model_eta2p <- eta_squared(model, partial = TRUE) %>%
#         mutate(
#             Eta2p = round(Eta2_partial, 3),
#             Var = model_anova_emp$Var
#         )
#     
#     # Merge ANOVA and eta2
#     model_anova_emp <- merge(model_anova_emp[, c("Var", "df1", "df2", "F", "p")], model_eta2p[, c("Var", "Eta2p")], by = "Var")
#     model_anova_emp$p <- signif(model_anova_emp$p, 2)
#     model_anova_emp <- model_anova_emp[order(match(model_anova_emp$Var, c("LocComb", "SF", "LocComb:SF"))), ]
#     
#     # Post-hoc for Loc (needed for all SFxSubj cond)
#     MC_Loc_emp <- emmeans(model, pairwise ~ LocComb, adjust = "bonferroni")$contrasts %>%
#         as.data.frame() %>%
#         transmute(
#             contrast,
#             estimate = round(estimate, 3),
#             df = round(df, 1),
#             t = round(t.ratio, 2),
#             p.value = round(p.value, 3),
#         )
#     
#     if (str_SF != "SF6") {
#         # Posthoc for SF
#         MC_LocxSF <- emmeans(model, pairwise ~ LocComb * SF, adjust = "bonferroni")
#         
#         MC_SF_emp <- emmeans(model, pairwise ~ SF, adjust = "bonferroni")$contrasts %>%
#             as.data.frame() %>%
#             transmute(
#                 contrast,
#                 estimate = round(estimate, 3),
#                 df = round(df, 1),
#                 t = round(t.ratio, 2),
#                 p.value = round(p.value, 3),
#             )
#         
#         # Posthoc for LocxSF
#         MC_LocxSF_emp <- as.data.frame(MC_LocxSF$contrasts)
#         MC_LocxSF_emp <- emmeans(model, pairwise ~ LocComb * SF, adjust = "bonferroni")$contrasts %>%
#             as.data.frame() %>%
#             transmute(
#                 contrast,
#                 estimate = round(estimate, 3),
#                 df = round(df, 1),
#                 t = round(t.ratio, 2),
#                 p.value = round(p.value, 3)
#             )
#     }
#     
#     # Output: return a list for this bootstrap
#     if (str_SF == "SF6") {
#         list(
#             model_anova_emp = model_anova_emp,
#             MC_Loc_emp = MC_Loc_emp
#         )
#     } else {
#         list(
#             model_anova_emp = model_anova_emp,
#             MC_Loc_emp = MC_Loc_emp,
#             MC_SF_emp = MC_SF_emp,
#             MC_LocxSF_emp = MC_LocxSF_emp
#         )
#     }
#     
#     # ---- 🔁 Conduct stats on the bootstrapped samples ----
#     # Initialize storage for this param
#     # model_anova_allB <- list()
#     # MC_Loc_allB <- list()
#     # MC_SF_allB <- list()
#     # MC_LocxSF_allB <- list()
#     # 
#     # Setup parallel backend
#     cl <- makeCluster(detectCores() - 1)
#     registerDoParallel(cl)
# 
#     # Parallel for each loop
#     results_list <- foreach(iBoot_s = 1:nBoot, .packages = c("lmerTest", "MuMIn", "dplyr", "emmeans", "effectsize")) %dopar% {
#         # Filter to specific boot iteration
#         dataTable_boot_perB <- dataTable_boot %>% filter(iBoot == iBoot_s)
# 
#         # Convert param to numeric
#         dataTable_boot_perB[[param]] <- as.numeric(dataTable_boot_perB[[param]])
# 
#         # Select the model
#         formula <- formulas_all[["formula_Intrc_RandIntcpt"]]
#         model <- lmer(as.formula(sprintf("%s ~ %s", param, formula)), data = dataTable_boot_perB)
#         r2 <- r.squaredGLMM(model)
#         model_anova <- anova(model) %>% as.data.frame()
#         model_anova$Var <- rownames(model_anova)
# 
#         colnames(model_anova) <- c("SS", "MSQ", "df1", "df2", "F", "p", "Var")
#         model_anova <- model_anova %>% mutate(across(c(SS, MSQ, df1, df2, F, p), ~ round(.x, 3)))
#         
#         # Obtain effect size (eta-squared)
#         model_eta2p <- eta_squared(model, partial = TRUE) %>%
#             mutate(
#                 Eta2p = round(Eta2_partial, 3),
#                 Var = model_anova$Var
#             )
# 
#         # Merge ANOVA and eta2
#         MC_LocxSF <- merge(model_anova[, c("Var", "df1", "df2", "F", "p")], model_eta2p[, c("Var", "Eta2p")], by = "Var")
#         MC_LocxSF$p <- signif(MC_LocxSF$p, 2)
#         MC_LocxSF <- MC_LocxSF[order(match(MC_LocxSF$Var, c("LocComb", "SF", "LocComb:SF"))), ]
# 
#         # Post-hoc for Loc (needed for all SFxSubj cond)
#         MC_Loc <- emmeans(model, pairwise ~ LocComb, adjust = "bonferroni")$contrasts %>%
#             as.data.frame() %>%
#             transmute(
#                 contrast,
#                 estimate = round(estimate, 3),
#                 df = round(df, 1),
#                 t = round(t.ratio, 2),
#                 p.value = round(p.value, 3),
#             )
#         # print(MC_Loc$p)
# 
#         # Posthoc for LocxSF and SF
#         if (str_SF != "SF6") {
#             # Posthoc for SF
#             MC_SF <- emmeans(model, pairwise ~ SF, adjust = "bonferroni")$contrasts %>%
#                 as.data.frame() %>%
#                 transmute(
#                     contrast,
#                     estimate = round(estimate, 3),
#                     df = round(df, 1),
#                     t = round(t.ratio, 2),
#                     p.value = round(p.value, 3),
#                 )
#             
#             # Posthoc for LocxSF
#             MC_LocxSF <- as.data.frame(MC_LocxSF$contrasts)
#             MC_LocxSF <- emmeans(model, pairwise ~ LocComb * SF, adjust = "bonferroni")$contrasts %>%
#                 as.data.frame() %>%
#                 transmute(
#                     contrast,
#                     estimate = round(estimate, 3),
#                     df = round(df, 1),
#                     t = round(t.ratio, 2),
#                     p.value = round(p.value, 3)
#                 )
#         }
#         
#         # Output: return a list for this bootstrap
#         if (str_SF == "SF6") {
#             list(
#                 model_anova_allB = model_anova,
#                 MC_Loc_allB = MC_Loc
#             )
#         } else {
#             list(
#                 model_anova_allB = model_anova,
#                 MC_Loc_allB = MC_Loc,
#                 MC_SF_allB = MC_SF,
#                 MC_LocxSF_allB = MC_LocxSF
#             )
#         }
#     }
#     
#     # Stop the cluster
#     stopCluster(cl)
# 
#     # ---- Visualize distirbution of F-values
#     # --- Example Setup ---
#     # Replace these with your actual values
#     F_obs <- 6.175  # Observed F-value from non-bootstrapped ANOVA
#     varname <- "LocComb"  # Variable to extract from ANOVA
#     
#     # Collect F-values from all bootstrapped results
#     F_boot <- sapply(results_list, function(res) {
#         if (!is.null(res$model_anova_allB)) {
#             val <- res$model_anova_allB$F[res$model_anova_allB$Var == varname]
#             if (length(val) == 1) return(val)
#         }
#         return(NA)
#     })
#     F_boot <- na.omit(F_boot)
#     
#     # --- Visualization ---
#     library(ggplot2)
#     
#     # Put into a data frame for ggplot
#     df <- data.frame(F_value = F_boot)
#     
#     # Calculate median
#     F_median <- median(df$F_value)
#     
#     # Plot
#     ggplot(df, aes(x = F_value)) +
#         geom_histogram(aes(y = ..density..), bins = 40, fill = "lightgray", color = "black") +
#         geom_vline(xintercept = F_median, color = "blue", linetype = "dashed", linewidth = 1.2) +
#         geom_vline(xintercept = F_obs, color = "red", linetype = "solid", linewidth = 1.2) +
#         labs(
#             title = paste("Distribution of Bootstrapped F-values for", varname),
#             x = "F-value",
#             y = "Density"
#         ) +
#         annotate("text", x = F_median, y = Inf, vjust = 2, label = paste("Median =", round(F_median, 2)), color = "blue") +
#         annotate("text", x = F_obs, y = Inf, vjust = 4, label = paste("Observed =", round(F_obs, 2)), color = "red") +
#         theme_minimal()
#     
#     
#     # ---- calculate empirical p-values for each stats
#     # Cal empirical p-value for ANOVA
#     vars <- c("LocComb", "SF", "LocComb:SF")
#     emp_pvals_anova <- sapply(vars, function(varname) {
#         F_obs <- model_anova_emp$F[model_anova_emp$Var == varname]
#         F_boot <- sapply(results_list, function(res) {
#             if (!is.null(res$model_anova_allB)) {
#                 val <- res$model_anova_allB$F[res$model_anova_allB$Var == varname]
#                 if (length(val) == 1) return(val)
#             }
#             return(NA)
#         })
#         F_boot <- na.omit(F_boot)
#         get_empirical_p(F_boot, F_obs)
#     })
#     # Add empirical p-values to model_anova
#     model_anova$empirical_p <- emp_pvals_anova[match(model_anova$Var, vars)]
#     
#     
#     
#     # 
#     # model_anova_allB <- lapply(results_list, function(x) x$MC_LocxSF)
#     # MC_Loc_allB <- lapply(results_list, function(x) x$MC_Loc)
#     # if (str_SF != "SF6") {
#     #     MC_SF_allB <- lapply(results_list, function(x) x$MC_SF)
#     #     MC_LocxSF_allB <- lapply(results_list, function(x) x$MC_LocxSF)
#     # }
#     # 
#     # 
#     # # === Calculate median and CI ====
#     # model_anova_allB <- bind_rows(model_anova_allB, .id = "Boot")
#     # model_anova_CI <- model_anova_allB %>%
#     #     group_by(Var) %>%
#     #     summarise(
#     #         F_med = round(median(F, na.rm = TRUE), 3),
#     #         F_lb = round(quantile(F, perc_lb, na.rm = TRUE), 3),
#     #         F_ub = round(quantile(F, perc_ub, na.rm = TRUE), 3),
#     #         df1_med = round(median(df1, na.rm = TRUE), 3),
#     #         df2_med = round(median(df2, na.rm = TRUE), 3),
#     #         # p_med = round(median(p, na.rm = TRUE), 3),
#     #         # p_lb = round(quantile(p, perc_lb, na.rm = TRUE), 3),
#     #         # p_ub = round(quantile(p, perc_ub, na.rm = TRUE), 3),
#     #         
#     #         Eta2p_med = round(median(Eta2p, na.rm = TRUE), 3),
#     #         Eta2p_lb = round(quantile(Eta2p, perc_lb, na.rm = TRUE), 3),
#     #         Eta2p_ub = round(quantile(Eta2p, perc_ub, na.rm = TRUE), 3),
#     #         .groups = "drop"
#     #     ) %>%
#     #     mutate(
#     #         sig = symnum(p_emp,
#     #             corr = FALSE,
#     #             cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
#     #             symbols = c("***", "**", "*", ".", "ns")
#     #         )
#     #     )
#     # 
#     # fxn_getCI4MC <- function(df, group_col, t_col, df_col, p_col) {
#     #     df %>%
#     #         group_by({{ group_col }}) %>%
#     #         summarise(
#     #             t_med = round(median({{ t_col }}, na.rm = TRUE), 3),
#     #             t_lb = round(quantile({{ t_col }}, perc_lb, na.rm = TRUE), 3),
#     #             t_ub = round(quantile({{ t_col }}, perc_ub, na.rm = TRUE), 3),
#     #             df_med = round(median({{ df_col }}, na.rm = TRUE), 3),
#     #             # p_med = round(median({{ p_col }}, na.rm = TRUE), 3),
#     #             # p_lb = round(quantile({{ p_col }}, perc_lb, na.rm = TRUE), 3),
#     #             # p_ub = round(quantile({{ p_col }}, perc_ub, na.rm = TRUE), 3),
#     # 
#     #             # Two-tailed empirical p-value
#     #             n_pos = sum({{ t_col }} > 0, na.rm = TRUE),
#     #             n_neg = sum({{ t_col }} < 0, na.rm = TRUE),
#     #             n_total = n_pos + n_neg,
#     #             p_emp = ifelse(n_total > 0, round(2 * min(n_pos, n_neg) / n_total, 3), NA_real_),
#     #             .groups = "drop"
#     #         ) %>%
#     #         mutate(
#     #             Dir = case_when(
#     #                 t_med > 0 ~ ">",
#     #                 t_med < 0 ~ "<",
#     #                 TRUE ~ "="
#     #             ),
#     #             sig = symnum(p_emp,
#     #                 corr = FALSE,
#     #                 cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
#     #                 symbols = c("***", "**", "*", ".", "ns")
#     #             )
#     #         )
#     # } # end of getCI4MC
#     # 
#     # MC_Loc_allB <- bind_rows(MC_Loc_allB, .id = "Boot")
#     # mc_Loc_CI <- fxn_getCI4MC(MC_Loc_allB, contrast, t, df, p.value)
#     # 
#     # if (str_SF != "SF6") {
#     #     MC_SF_allB <- bind_rows(MC_SF_allB, .id = "Boot")
#     #     mc_SF_CI <- fxn_getCI4MC(MC_SF_allB, contrast, t, df, p.value)
#     # 
#     #     MC_LocxSF_allB <- bind_rows(MC_LocxSF_allB, .id = "Boot")
#     #     MC_LocxSF_CI <- fxn_getCI4MC(MC_LocxSF_allB, contrast, t, df, p.value)
#     # }
#     # 
#     # # ==== Create helper functions to format reports ====
#     # fxn_format_anova <- function(df, term) {
#     #     row <- df[df$Var == term, ]
#     #     if (nrow(row) == 0) {
#     #         return(NULL)
#     #     } else if (nrow(row) > 1) {
#     #         warning(sprintf("Multiple rows found for term '%s'. Using the first one.", term))
#     #         row <- row[1, ]
#     #     }
#     # 
#     #     stars <- if (row$p_med < 0.001) "***" else if (row$p_med < 0.01) "**" else if (row$p_med < 0.05) "*" else if (row$p_med < 0.1) "mg" else ""
#     # 
#     #     sprintf(
#     #         "F(%.0f, %.1f) = %.2f, p = %.3f, Eta²ₚ = %.3f %s",
#     #         row$df1_med, row$df2_med, row$F_med,
#     #         row$p_emp,
#     #         row$Eta2p_med, stars
#     #     )
#     # } # end of format_anova
#     # 
#     # fxn_format_posthoc <- function(df) {
#     #     apply(df, 1, function(r) {
#     #         contrast <- gsub(" - ", r["Dir"], r["contrast"])
#     #         tval <- as.numeric(r["t_med"])
#     #         df_ <- as.numeric(r["df_med"])
#     #         pval <- as.numeric(r["p_emp"])
#     #         # pval_lb <- as.numeric(r["p_lb"])
#     #         # pval_ub <- as.numeric(r["p_ub"])
#     #         sig <- r["sig"]
#     # 
#     #         if (sig %in% c("ns", ".")) {
#     #             sprintf("  %s: t(%.0f)=%.2f, p=%.3f\n", contrast, df_, tval, pval, pval_lb, pval_ub)
#     #         } else {
#     #             sprintf("  %s: t(%.0f)=%.2f, p=%.3f%s\n", contrast, df_, tval, pval, pval_lb, pval_ub, sig)
#     #         }
#     #     })
#     # } # end of format_posthoc
#     # 
#     # 
#     # if (str_SF != "SF6") {
#     #     fxn_format_posthoc_interaction <- function(df, type = c("sameSF", "sameLoc")) {
#     #         type <- match.arg(type)
#     # 
#     #         df %>%
#     #             mutate(
#     #                 LocSF1 = sub(" -.*", "", contrast),
#     #                 LocSF2 = sub(".*- ", "", contrast),
#     #                 Loc1 = sub(" .*", "", LocSF1),
#     #                 Loc2 = sub(" .*", "", LocSF2),
#     #                 SF1 = sub(".* ", "", LocSF1),
#     #                 SF2 = sub(".* ", "", LocSF2)
#     #             ) %>%
#     #             filter(
#     #                 if (type == "sameSF") SF1 == SF2 else Loc1 == Loc2,
#     #                 p_emp < 0.1
#     #             ) %>%
#     #             mutate(
#     #                 Group = if (type == "sameSF") SF1 else Loc1,
#     #                 contrast_clean = case_when(
#     #                     type == "sameSF" ~ paste(Loc1, Dir, Loc2),
#     #                     type == "sameLoc" ~ paste(SF1, Dir, SF2)
#     #                 ),
#     #                 label = ifelse(
#     #                     sig %in% c("ns", "."),
#     #                     sprintf("  %s: t(%.1f)=%.2f, p=%.3f", contrast_clean, df_med, t_med, p_emp),
#     #                     sprintf("  %s: t(%.1f)=%.2f, p=%.3f %s", contrast_clean, df_med, t_med, p_emp, sig)
#     #                 )
#     #             ) %>%
#     #             group_by(Group) %>%
#     #             summarise(lines = paste(label, collapse = "\n"), .groups = "drop") %>%
#     #             mutate(formatted = sprintf("[%s]\n%s", Group, lines)) %>%
#     #             pull(formatted) %>%
#     #             paste(collapse = "\n\n") # proper newlines between groups
#     #     } # end of format_posthoc_interaction
#     # }
#     # 
#     # # ==== Format & Print ====
#     # cat(" === Main effect of Loc ===\n")
#     # text_anova_loc <- fxn_format_anova(model_anova_CI, "LocComb")
#     # text_posthoc_loc <- fxn_format_posthoc(mc_Loc_CI)
#     # cat(text_anova_loc, "\n\n", text_posthoc_loc, "\n")
#     # 
#     # if (str_SF != "SF6") {
#     #     cat(" === Main effect of SF ===\n")
#     #     text_anova_sf <- fxn_format_anova(model_anova_CI, "SF")
#     #     text_posthoc_sf <- fxn_format_posthoc(mc_SF_CI)
#     #     cat(text_anova_sf, "\n\n", text_posthoc_sf, "\n")
#     # 
#     #     cat(" ==== Loc x SF ====\n")
#     #     text_anova_Locxsf <- fxn_format_anova(model_anova_CI, "LocComb:SF")
#     #     text_MC_LocxSF_sameSF <- fxn_format_posthoc_interaction(MC_LocxSF_CI, type = "sameSF")
#     #     text_MC_LocxSF_sameLoc <- fxn_format_posthoc_interaction(MC_LocxSF_CI, type = "sameLoc")
#     #     cat(text_anova_Locxsf, "\n\n", text_MC_LocxSF_sameSF, "\n\n", text_MC_LocxSF_sameLoc, "\n")
#     # }
# 
#     # } # end param loop
# } # end loc loop
# 
# sink() # Close log file
# 
# while (sink.number() > 0) sink(NULL)
# 
# 
# end_time <- Sys.time() # ⏱️ toc
# dur <- end_time - start_time # See how much time passed
# print(round(dur, 1))
# cat(sprintf(
#     "\n\n============= %s%s (P%.0f) ALL DONE ==============\n",
#     str_SF, str_n9, PerfLevel_s * 100
# ))