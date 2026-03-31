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

sz_wd_3way <- 6
sz_ht_3way <- 3.5 # originally 4
sz_wd_2way <- 3
sz_ht_2way <- 3.5 # originally 4

sz_marker <- 4
wd_line <- 1.5
wd_line_idvd <- wd_line / 1.5
wd_line_comp <- wd_line / 1.5

theme_custom_3way <- theme(
  axis.title = element_text(size = 12, face = "bold"),
  axis.text = element_text(size = 14),
  strip.text = element_text(size = 10, face = "bold"),
  plot.title = element_text(size = 10),
)
theme_custom_2way <- theme_custom_3way
# theme_custom_2way <- theme(
#   axis.title = element_text(size = 12, face = "bold"),
#   axis.text = element_text(size = 10),
#   strip.text = element_text(size = 10, face = "bold"),
#   plot.title = element_text(size = 10)
# )

# define the x value of each group
xlimit <- c(.6, 3.9)
buffer <- .5
get_x_num_EccLoc <- function(EccLoc) {
  dplyr::case_when(
    EccLoc %in% c("4_HM", "4_LVM") ~ 1,
    EccLoc %in% c("4_VM", "4_UVM") ~ 2,
    EccLoc %in% c("8_HM", "8_LVM") ~ 2+buffer,
    EccLoc %in% c("8_VM", "8_UVM") ~ 3+buffer,
    TRUE ~ NA_real_
  )
}

get_x_num_SFLoc <- function(SFLoc) {
  dplyr::case_when(
    SFLoc %in% c("4_HM", "4_LVM") ~ 1,
    SFLoc %in% c("4_VM", "4_UVM") ~ 2,
    SFLoc %in% c("6_HM", "6_LVM") ~ 2+buffer,
    SFLoc %in% c("6_VM", "6_UVM") ~ 3+buffer,
    TRUE ~ NA_real_
  )
}

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
nameFolder_Fig_Variation_3way <- sprintf("%s/3way_interaction", nameFolder_Figures)
if (!dir.exists(nameFolder_Fig_Variation_3way)) dir.create(nameFolder_Fig_Variation_3way, recursive = TRUE, showWarnings = FALSE)

nameFolder_Output <- sprintf("%s/Output_2Variation_3Way", nameFolder_Outputs)
if (!dir.exists(nameFolder_Output)) dir.create(nameFolder_Output, recursive = TRUE, showWarnings = FALSE)

# ==== 🔁 Loop Through Parameters (Gain, Nadd, Gamma) ====
for (param in param_list) {
  
  # Define height of comparison lines
  y <- y_start_3way[[param]]
  
  # Define yticks
  yticks <- yticks_param[[param]] # Get yticks for the current param_LDI
  
  # Define the string for the current parameter
  line_ME <- data.frame(
    x = c(1, 2+buffer),
    xend = c(2, 3+buffer),
    y = y
  )
  
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

    # ==== Visualize 3-way interaction ====
    # Define color palette based on str_loc
    if (str_loc == "HM4VM4HM8VM8") {
      colors_LocxEcc <- unlist(location_colors[c("04HM4", "05VM4", "08HM8", "09VM8")])
      names(colors_LocxEcc) <- c("4_HM", "4_VM", "8_HM", "8_VM")
    } else {
      colors_LocxEcc <- unlist(location_colors[c("06LVM4", "07UVM4", "10LVM8", "11UVM8")])
      names(colors_LocxEcc) <- c("4_LVM", "4_UVM", "8_LVM", "8_UVM")
    }

    # Add EccLoc composite and jitter
    dataTable_med <- dataTable %>%
      group_by(Subj, LocComb, SF, Ecc) %>%
      summarise(across(c(ThreshN0_t, Gain, GainLog, Nadd, Gamma), median), .groups = "drop") %>%
      mutate(
        LocComb = factor(LocComb),
        SF = factor(SF),
        Ecc = factor(Ecc),
        EccLoc = interaction(Ecc, LocComb, sep = "_", lex.order = TRUE),
        x_num = get_x_num_EccLoc(EccLoc),
        x_jitter = x_num + runif(n(), -jitter_width, jitter_width)
      )

    data_summary <- dataTable_med %>%
      group_by(SF, Ecc, LocComb, EccLoc) %>%
      summarise(
        mean_val = mean(.data[[param]]),
        se = sd(.data[[param]]) / sqrt(n()),
        .groups = "drop"
      ) %>%
      mutate(x_num = get_x_num_EccLoc(EccLoc))

    # Plot 3-way interaction
    p_3way <- ggplot() +
      # Individual lines (connect same-Eccentricity points)
      geom_line(
        data = dataTable_med,
        aes(x = x_jitter, y = get(param), color = "grey", group = interaction(Subj, Ecc)),
        alpha = 0.3, size = wd_line_idvd
      ) +

      # Group averages and error bars
      geom_errorbar(
        data = data_summary,
        aes(x = x_num, ymin = mean_val - se, ymax = mean_val + se, color = EccLoc),
        width = 0, position = position_dodge(width = 0.3), linewidth = wd_line
      ) +
      geom_line( # Group mean lines (within each Eccentricity)
        data = data_summary,
        aes(x = x_num, y = mean_val, group = Ecc),
        color = "black", linewidth = wd_line
      ) +
      geom_point(
        data = data_summary,
        aes(x = x_num, y = mean_val, color = EccLoc, shape = SF),
        position = position_dodge(width = 0.3), size = sz_marker, fill = "white", stroke = wd_line
      ) +
      geom_segment(
        data = line_ME,
                   aes(x = x, xend = xend, y = y, yend = y),
                   inherit.aes = FALSE,
                   color = "black", linetype = "solid", linewidth = wd_line_comp
                   ) +
      
      facet_wrap(~SF) +
      labs(
        # title = sprintf(
        #   "[%s%s | %s] %s (nBoot=%d)\n[3] Loc x SF x Ecc: %s\n[2] Loc x Ecc: %s\n[2] Loc x SF: %s\n[1] Loc: %s",
        #   str_SF, str_n9, str_loc, param, nBoot,
        #   text_anova_LocxSFxEcc, text_anova_LocxEcc, text_anova_LocxSF, text_anova_Loc
        # ),
        title = sprintf("[%s%s | %s] %s (nBoot=%d)", str_SF, str_n9, str_loc, param, nBoot),
        y = param,
        x = "Location × Eccentricity",
        color = "Location", shape = "SF"
      ) +
      # Define x-axis labels
      scale_x_continuous(
        breaks = data_summary$x_num,
        labels = data_summary$EccLoc
      ) +
      # Set y and x limits
      scale_y_continuous(
        limits = c(yticks[1], yticks[length(yticks)]),
        breaks = yticks
      )+
      # Map color
      scale_color_manual(values = colors_LocxEcc) +

      # Map shape
      scale_shape_manual(values = shape_SF) +

      # Define theme
      theme_bw(base_size = 16) +
      theme_custom_3way +
      theme(
        legend.position = "none", # turn off legends
        # panel.grid.major.x = element_blank(),   # turn off vertical major grid lines
        panel.grid.minor = element_blank(), # turn off minor grid lines
        # remove the facet band
        strip.background = element_blank(),
        strip.text = element_blank()
      ) +

      # Define x lim
      coord_cartesian(
        xlim = xlimit,
        # ylim = limits_params[[param]]
      ) # end of ggplot
    print(p_3way)

    # Save plot
    ggsave(sprintf("%s/%s_%s_nBoot%d.png", nameFolder_Fig_Variation_3way, param, str_loc, nBoot),
      plot = p_3way, width = sz_wd_3way, height = sz_ht_3way, dpi = 300
    )

    # ==== Visualize 2-way interactions: Loc x Ecc ====
    # Create composite factor for coloring when SF is not a factor
    dataTable$SF <- as.character(dataTable$SF)

    dataTable <- dataTable %>%
      mutate(LocComb_Ecc = interaction(Ecc, LocComb, sep = "_", lex.order = TRUE))

    # Define color palette based on str_loc
    if (str_loc == "HM4VM4HM8VM8") {
      colors_LocxEcc <- unlist(location_colors[c("04HM4", "05VM4", "08HM8", "09VM8")])
      names(colors_LocxEcc) <- c("4_HM", "4_VM", "8_HM", "8_VM")
    } else {
      colors_LocxEcc <- unlist(location_colors[c("06LVM4", "07UVM4", "10LVM8", "11UVM8")])
      names(colors_LocxEcc) <- c("4_LVM", "4_UVM", "8_LVM", "8_UVM")
    }

    plot_LocxEcc <- function(data, param, colors_LocxEcc, jitter_width = 0.1) {
      stopifnot(all(c("LocComb", "Ecc", "LocComb_Ecc", param) %in% names(data)))

      data_med <- data %>%
        group_by(Subj, LocComb, Ecc, LocComb_Ecc) %>%
        summarise({{ param }} := median(.data[[param]]), .groups = "drop") %>%
        mutate(
          EccLoc = interaction(Ecc, LocComb, sep = "_", lex.order = TRUE),
          x_num = get_x_num_EccLoc(EccLoc),
          x_jitter = x_num + runif(n(), -jitter_width, jitter_width)
        )

      data_summary <- data_med %>%
        group_by(LocComb, Ecc, LocComb_Ecc, EccLoc) %>%
        summarise(
          mean_val = mean(.data[[param]]),
          se = sd(.data[[param]]) / sqrt(n()), .groups = "drop"
        ) %>%
        mutate(x_num = get_x_num_EccLoc(EccLoc))

      p <- ggplot() +
        # Idvd data
        geom_line(
          data = data_med,
          aes(x = x_jitter, y = .data[[param]], group = interaction(Subj, Ecc)),
          color = "grey", alpha = 0.3, linewidth = wd_line_idvd
        ) +
        # Group averages and error bars
        geom_errorbar(
          data = data_summary,
          aes(x = x_num, ymin = mean_val - se, ymax = mean_val + se, color = LocComb_Ecc),
          width = 0, linewidth = wd_line
        ) +
        geom_line(
          data = data_summary,
          aes(x = x_num, y = mean_val, group = Ecc),
          color = "black", linewidth = wd_line
        ) +
        geom_point(
          data = data_summary,
          aes(x = x_num, y = mean_val, color = LocComb_Ecc),
          # size = sz_marker, shape = 21, fill = "white", stroke = wd_line
          size = .5, shape = 21, stroke = 1
        ) +
        geom_segment(
          data = line_ME,
          aes(x = x, xend = xend, y = y, yend = y),
          inherit.aes = FALSE,
          color = "black", linetype = "solid", linewidth = wd_line_comp
        ) +
        scale_color_manual(values = colors_LocxEcc) +
        labs(
          title = sprintf(
            "[%s%s | %s] %s | Loc x Ecc (nBoot=%d)",
            str_SF, str_n9, str_loc, param, nBoot
          ),
          x = "EccLoc",
          y = param,
          color = "LocComb_Ecc"
        ) +
        scale_x_continuous(
          breaks = data_summary$x_num,
          labels = data_summary$EccLoc
        ) +
        theme_bw(base_size = 16) +
        theme_custom_2way +
        theme(
          legend.position = "none", # turn off legends
          # panel.grid.major.x = element_blank(),   # turn off vertical major grid lines
          panel.grid.minor = element_blank() # turn off minor grid lines
        ) +
        # Define x lim
        # coord_cartesian(
        #   xlim = xlimit,
        #   ylim = limits_params[[param]]
        # )
        # Set y and x limits
        scale_y_continuous(
          limits = c(yticks[1], yticks[length(yticks)]),
          breaks = yticks
        )
      print(p)
      return(p)
    } # end of plot_LocxEcc function
    
    # Plot Loc x Ecc
    p_LocxEcc <- plot_LocxEcc(data = dataTable, param, colors_LocxEcc)
    ggsave(sprintf("%s/%s_%s_LocxEcc_nBoot%d.png", nameFolder_Fig_Variation_3way, param, str_loc, nBoot),
      plot = p_LocxEcc, width = sz_wd_2way, height = sz_ht_2way, dpi = 300
    )

    # ==== Visualize 2-way interactions: Loc x SF ====
    plot_LocxSF <- function(data, param, location_colors, shape_SF, jitter_width = 0.1) {
      stopifnot(all(c("LocComb", "SF", param) %in% names(data)))

      data_med <- data %>%
        group_by(Subj, LocComb, SF) %>%
        summarise({{ param }} := median(.data[[param]]), .groups = "drop") %>%
        mutate(
          SFLoc = interaction(SF, LocComb, sep = "_", lex.order = TRUE),
          x_num = get_x_num_SFLoc(SFLoc),
          x_jitter = x_num + runif(n(), -jitter_width, jitter_width)
        )

      data_summary <- data_med %>%
        group_by(LocComb, SF, SFLoc) %>%
        summarise(
          mean_val = mean(.data[[param]]),
          se = sd(.data[[param]]) / sqrt(n()), .groups = "drop"
        ) %>%
        mutate(x_num = get_x_num_SFLoc(SFLoc))

      p <- ggplot() +
        geom_line(
          data = data_med,
          aes(x = x_jitter, y = .data[[param]], group = interaction(Subj, SF)),
          color = "grey", alpha = 0.3, linewidth = wd_line_idvd
        ) +
        geom_errorbar(
          data = data_summary,
          aes(x = x_num, ymin = mean_val - se, ymax = mean_val + se, color = LocComb),
          width = 0, linewidth = wd_line
        ) +
        geom_line(
          data = data_summary,
          aes(x = x_num, y = mean_val, group = SF),
          color = "black", linewidth = wd_line
        ) +
        geom_point(
          data = data_summary,
          aes(x = x_num, y = mean_val, color = LocComb, shape = SF),
          size = sz_marker, position = position_dodge(width = 0.3), fill = "white", stroke = wd_line
        ) +
        geom_segment(
          data = line_ME,
          aes(x = x, xend = xend, y = y, yend = y),
          inherit.aes = FALSE,
          color = "black", linetype = "solid", linewidth = wd_line_comp
        ) +
        scale_color_manual(values = location_colors) +
        scale_shape_manual(values = shape_SF) +
        labs(
          title = sprintf("[%s%s | %s] %s | Loc x SF (nBoot=%d)", str_SF, str_n9, str_loc, param, nBoot),
          x = "SFLoc",
          y = param,
          color = "LocComb",
          shape = "SF",
        ) +
        coord_cartesian(
          xlim = xlimit,
          # ylim = limits_params[[param]]
        ) +
        scale_x_continuous(
          breaks = data_summary$x_num,
          labels = data_summary$SFLoc
        ) +
        theme_bw(base_size = 16) +
        theme_custom_2way +
        theme(
          legend.position = "none", # turn off legends
          # panel.grid.major.x = element_blank(),   # turn off vertical major grid lines
          panel.grid.minor = element_blank() # turn off minor grid lines
        )+
        # Set y and x limits
        scale_y_continuous(
          limits = c(yticks[1], yticks[length(yticks)]),
          breaks = yticks
        )
      print(p)
      return(p)
    } # end of plot_LocxSF function

    # Plot Loc x SF
    p_LocxSF <- plot_LocxSF(dataTable, param, location_colors, shape_SF)
    ggsave(sprintf("%s/%s_%s_LocxSF_nBoot%d.png", nameFolder_Fig_Variation_3way, param, str_loc, nBoot),
      plot = p_LocxSF, width = sz_wd_2way, height = sz_ht_2way, dpi = 300
    )
  } # end param loop
} # end loc loop

end_time <- Sys.time() # ⏱️ toc
dur <- end_time - start_time # See how much time passed
print(round(dur, 1))
cat(sprintf(
  "\n\n============= %s%s (P%.0f) ALL DONE ==============\n",
  str_SF, str_n9, PerfLevel_s * 100
))
