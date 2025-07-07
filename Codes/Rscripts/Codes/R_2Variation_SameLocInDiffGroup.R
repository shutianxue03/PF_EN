
# This script compares the same location (e.g., Fovea) that was involved in 
# param estimation in different location groups (e.g., FovHM4HM8 and FovVM4VM8)
# Results: absolutely no difference! Meaning that the estimated parameters 
# from different estimates can be considered identical and comparable

# ==== 🧹 Clean environment ====
graphics.off() # Close all plots
cat("\014") # Clear console (like MATLAB's clc)


# ==== 📁 Folder Setup ====
nameFolder_Fig <- sprintf("%s/Figures_2Variation/%s%s_P%.0f", nameFolder_Figures, str_SF, str_n9, PerfLevel_s * 100)
if (!dir.exists(nameFolder_Fig)) dir.create(nameFolder_Fig, recursive = TRUE)


# ==== 📋 List of comparison conditions ====
compare_conditions <- list(
  list(str_loc1 = "FovHM4HM8", str_loc2 = "FovVM4VM8", str_loc_comp = "Fov"),
  list(str_loc1 = "FovHM4HM8", str_loc2 = "HM4VM4",    str_loc_comp = "HM4"),
  list(str_loc1 = "FovHM4HM8", str_loc2 = "HM8VM8",    str_loc_comp = "HM8"),
  list(str_loc1 = "FovVM4VM8", str_loc2 = "HM4VM4",    str_loc_comp = "VM4"),
  list(str_loc1 = "FovVM4VM8", str_loc2 = "HM8VM8",    str_loc_comp = "VM8")
)

# ==== 🔁 Loop through each condition ====1
for (condition in compare_conditions) {
  str_loc1 <- condition$str_loc1
  str_loc2 <- condition$str_loc2
  str_loc_comp <- condition$str_loc_comp

  # Load two tables
  
  dataTable_allB1 <- read.csv(sprintf("DataTable/%s%s/%s.csv", str_SF, str_n9, str_loc1))
  dataTable1 <- dataTable_allB1 %>%
    group_by(Subj, LocComb, SF, PerfLevel) %>%
    summarise(
      Gain = median(Gain),
      Nadd = median(Nadd),
      Gamma = median(Gamma),
      .groups = "drop"
    )
  
  dataTable_allB2 <- read.csv(sprintf("DataTable/%s%s/%s.csv", str_SF, str_n9, str_loc2))
  dataTable2 <- dataTable_allB2 %>%
    group_by(Subj, LocComb, SF, PerfLevel) %>%
    summarise(
      Gain = median(Gain),
      Nadd = median(Nadd),
      Gamma = median(Gamma),
      .groups = "drop"
    )
  
  # Preprocessing
  dataTable1 <- dataTable1 %>%
    filter(PerfLevel == PerfLevel_s) %>%
    mutate(
      Subj = factor(Subj, levels = 1:nsubj, labels = subjList),
      LocComb = recode(as.character(LocComb),
        "1" = "Fov", "2" = "Ecc4", "3" = "Ecc8",
        "4" = "HM4", "5" = "VM4", "6" = "LVM4", "7" = "UVM4",
        "8" = "HM8", "9" = "VM8", "10" = "LVM8", "11" = "UVM8"
      ),
      LocComb = factor(LocComb, levels = unique(LocComb)),
      SF = as.factor(SF),
      PerfLevel = as.factor(PerfLevel)
    )
  dataTable2 <- dataTable2 %>%
    filter(PerfLevel == PerfLevel_s) %>%
    mutate(
      Subj = factor(Subj, levels = 1:nsubj, labels = subjList),
      LocComb = recode(as.character(LocComb),
        "1" = "Fov", "2" = "Ecc4", "3" = "Ecc8",
        "4" = "HM4", "5" = "VM4", "6" = "LVM4", "7" = "UVM4",
        "8" = "HM8", "9" = "VM8", "10" = "LVM8", "11" = "UVM8"
      ),
      LocComb = factor(LocComb, levels = unique(LocComb)),
      SF = as.factor(SF),
      PerfLevel = as.factor(PerfLevel)
    )

  # ==== 🔁 Loop Through Parameters (Gain, Nadd, Gamma) ====
  for (param in param_list) {
    cat(sprintf("\n\n***************************\n Location: %s and %s | Param: %s \n***************************\n\n", str_loc1, str_loc2, param))

    # Filter to just the location of interest
    data1 <- dataTable1 %>% filter(LocComb == str_loc_comp) %>% mutate(Group = str_loc1)
    data2 <- dataTable2 %>% filter(LocComb == str_loc_comp) %>% mutate(Group = str_loc2)
    
    combined_df <- bind_rows(data1, data2)
    
    # Perform t-test
    t_test_result <- t.test(
      combined_df[[param]][combined_df$Group == str_loc1],
      combined_df[[param]][combined_df$Group == str_loc2]
    )
    
    # Calcuate the averaged difference
    mean_diff <- mean(combined_df[[param]][combined_df$Group == str_loc1]) - mean(combined_df[[param]][combined_df$Group == str_loc2])
    # Plot the comparison
    p <- ggplot(combined_df, aes(x = Group, y = .data[[param]], color = SF, group = Subj)) +
      geom_point(position = position_dodge(0.2), size = 2, aes(shape = Subj)) +
      geom_line(position = position_dodge(0.2), alpha = 0.4) +
      facet_wrap(~SF) +
      scale_shape_manual(values = subject_shapes) +
      theme_bw() +
      labs(
        title = sprintf("[%s%s] %s at %s (%s vs %s)\nt = %.2f, p = %.3f",
                        str_SF, str_n9, param, str_loc_comp, str_loc1, str_loc2,
                        t_test_result$statistic, t_test_result$p.value),
        x = "Group", y = param
      )
    
    print(p)
    # save the plot
    ggsave(
      filename = sprintf("%s/SameLocInDiffGroup/%s_%s.png", nameFolder_Fig, str_loc_comp, param),
      plot = p,
      width = 10,
      height = 5
    )
  } # end of loop through params
} # end of loop through conditions
