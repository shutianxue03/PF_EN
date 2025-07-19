# 📈 Simplified One-Way ANOVA with Bootstrapping
library(dplyr)
library(lmerTest)   # for eta_squared (optional)
library(emmeans)
library(doParallel)
library(foreach)

# ==== Settings ====
param_list <- c("Gain", "Nadd", "Gamma")
nameFolder_Output <- sprintf("Output/SimpleANOVA_%s%s", str_SF, str_n9)
if (!dir.exists(nameFolder_Output)) dir.create(nameFolder_Output, recursive=TRUE)

sink(sprintf("%s/ANOVA_Results.txt", nameFolder_Output))

# ==== Bootstrapping loop ====
for (str_loc in str_loc_list) {
  dataTable <- read.csv(sprintf("DataTable/%s%s/%s.csv", str_SF, str_n9, str_loc))
  
  dataTable <- dataTable %>%
    mutate(
      LocComb=factor(LocComb),
      Subj=factor(Subj),
      iBoot=factor(iBoot)
    )
  
  nBoot <- length(unique(dataTable$iBoot))
  # nBoot <-5 
  for (param in param_list) {
    cat(sprintf("\n\n********* %s | %s *********\n", str_loc, param))
    
    cl <- makeCluster(detectCores() - 1)
    registerDoParallel(cl)
    
    results_list <- foreach(iBoot_s=1:nBoot, .packages=c("MuMIn", "dplyr", "emmeans", "effectsize")) %dopar% {
      dataB <- dataTable %>% filter(iBoot == iBoot_s)
      dataB[[param]] <- as.numeric(dataB[[param]])
      
      # Simple ANOVA
      model <- aov(as.formula(sprintf("%s ~ LocComb", param)), data=dataB)
      aov_df <- summary(model)[[1]]
      rownames(aov_df) <- c("LocComb", "Residuals")
      
      F_val <- aov_df["LocComb", "F value"]
      p_val <- aov_df["LocComb", "Pr(>F)"]
      df1 <- aov_df["LocComb", "Df"]
      df2 <- aov_df["Residuals", "Df"]
      
      # Eta-squared (partial)
      eta2 <- eta_squared(model, partial=TRUE)
      eta2p <- eta2$Eta2_partial[1]
      
      # Posthoc
      mc_Loc_df <- emmeans(model, pairwise ~ LocComb, adjust="bonferroni")$contrasts %>%
        as.data.frame() %>%
        transmute(
          contrast,
          estimate=round(estimate, 3),
          df=round(df, 1),
          t=round(t.ratio, 2),
          p.value=round(p.value, 3)
        )
      
      list(F=F_val, p=p_val, df1=df1, df2=df2, eta2p=eta2p, mc_Loc_df=mc_Loc_df)
    }
    
    stopCluster(cl)
    
    # === Extract and combine ===
    F_vals <- sapply(results_list, function(x) x$F)
    p_vals <- sapply(results_list, function(x) x$p)
    df1s <- sapply(results_list, function(x) x$df1)
    df2s <- sapply(results_list, function(x) x$df2)
    eta_vals <- sapply(results_list, function(x) x$eta2p)
    mc_Loc_allB <- lapply(results_list, function(x) x$mc_Loc_df)
    
    # === CI Summary ===
    anova_CI <- data.frame(
      Var="LocComb",
      F_med=median(F_vals, na.rm=TRUE),
      F_lb=quantile(F_vals, perc_lb, na.rm=TRUE),
      F_ub=quantile(F_vals, perc_ub, na.rm=TRUE),
      df1=round(median(df1s, na.rm=TRUE)),
      df2=round(median(df2s, na.rm=TRUE)),
      p_med=median(p_vals, na.rm=TRUE),
      p_lb=quantile(p_vals, perc_lb, na.rm=TRUE),
      p_ub=quantile(p_vals, perc_ub, na.rm=TRUE)
      # eta2p_med=median(eta_vals, na.rm=TRUE),
      # eta2p_lb=quantile(eta_vals, perc_lb, na.rm=TRUE),
      # eta2p_ub=quantile(eta_vals, perc_ub, na.rm=TRUE)
    ) %>%
      mutate(sig=symnum(p_med, corr=FALSE,
                          cutpoints=c(0, 0.001, 0.01, 0.05, 0.1, 1),
                          symbols=c("***", "**", "*", ".", "ns")))
    
    # ==== Format & print ====
    cat("=== ANOVA Summary ===\n")
    with(anova_CI, cat(sprintf("F(%d, %.0f)=%.2f, p=%.3f [%.3f, %.3f], %s\n\n",
                               df1, df2, F_med, p_med, p_lb, p_ub,
                               # eta2p_med, eta2p_lb, eta2p_ub, 
                               sig)))
    
    # ==== Post-hoc summary ====
    fxn_posthoc_CI <- function(df_list) {
      bind_rows(df_list, .id="Boot") %>%
        group_by(contrast) %>%
        summarise(
          t_med=median(t),
          t_lb=quantile(t, perc_lb),
          t_ub=quantile(t, perc_ub),
          df_med=median(df),
          p_med=median(p.value),
          p_lb=quantile(p.value, perc_lb),
          p_ub=quantile(p.value, perc_ub),
          .groups="drop"
        ) %>%
        mutate(
          Dir=case_when(t_med > 0 ~ ">", t_med < 0 ~ "<", TRUE ~ "="),
          sig=symnum(p_med, corr=FALSE,
                       cutpoints=c(0, 0.001, 0.01, 0.05, 0.1, 1),
                       symbols=c("***", "**", "*", ".", "ns"))
        )
    }
    
    mc_CI <- fxn_posthoc_CI(mc_Loc_allB)
    cat("=== Post-Hoc Pairwise Comparisons ===\n")
    apply(mc_CI, 1, function(r) {
      contrast <- gsub(" - ", r["Dir"], r["contrast"])
      cat(sprintf("  %s: t(%.0f)=%.2f, p=%.3f [%.3f, %.3f] %s\n",
                  contrast, as.numeric(r["df_med"]), as.numeric(r["t_med"]),
                  as.numeric(r["p_med"]), as.numeric(r["p_lb"]), as.numeric(r["p_ub"]),
                  r["sig"]))
    })
    cat("\n")
  }
}

sink()
