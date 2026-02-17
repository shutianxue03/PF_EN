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
# print_list <- c("ANOVA", "LMM", "Step") # Output types
print_list <- c("ANOVA") # Output types
param_list <- c("Gain", "ThreshN0_t", "GainLog", "Nadd", "Gamma") # Put Gamma before Nadd to aviod the weird plotting problem

# Define location groups (independent from modulation script)
if (str_SF == "SF6") {
  Effect_list <- c("MainEffect") # Effect types
  IV1_list <- c("LocComb")
  IV2_list <- c("SF")
} else {
  Effect_list <- c("MainEffect", "Interaction") # Effect types
  IV1_list <- c("LocComb", "SF")
  IV2_list <- c("SF", "LocComb")
  if (flag_plot7Locs == TRUE) {
    IV1_list <- c("SF")
    IV2_list <- c("LocComb")
  }
}

x_buffer <- .5 # the buffer on the x
wd_dodge <- .4 # width of the dodge

sz_wd <- 7
sz_ht <- 5 # for figure repository
pos_dodge <- position_dodge(width = wd_dodge)
jitter_width <- .05


# ==== 🔧 Global styling knobs ====
FIG_TEXT_SCALE <- 1.4   # enlarge all text
FIG_LINE_SCALE <- 1.4   # thicken all lines/strokes

sz_label_y <- c(25, 25) * FIG_TEXT_SCALE
sz_tick_y  <- c(20, 20) * FIG_TEXT_SCALE
sz_label_x <- c(10,10) # minimized, as ticks/labels will be replaced by diagrams
sz_tick_x <- c(10,10) # minimized, as ticks/labels will be replaced by diagrams
sz_legend <- c(10,10) # minimized, as ticks/labels will be replaced by diagrams
sz_legend_title <- c(10,10) # minimized, as ticks/labels will be replaced by diagrams
sz_title <- c(10,10) # minimized, will be hidden

sz_line   <- c(1.5, 1.5) * FIG_LINE_SCALE
sz_marker <- c(6, 6)     * FIG_LINE_SCALE   # optional: often scale markers too
sz_marg <- 15 # the gap between x/y label and ticks
# scale_MainEff <- .7 # everything is scaled down by this factor for main effects
marker_alpha <- .5
LW_ANNOT <- 0.6 * FIG_LINE_SCALE

layout_df <- list(
  "01Fov" = c(3, 1),
  "04HM4" = c(3, 2),
  "06LVM4" = c(4, 1),
  "07UVM4" = c(2, 1),
  "08HM8" = c(3, 3),
  "10LVM8" = c(5, 1),
  "11UVM8" = c(1, 1)
)

# ==== 📁 Folder Setup ====
nameFolder_Fig_variation <- sprintf("%s/Figures_2Variation_P%.0f", nameFolder_Figures, PerfLevel_s * 100)
if (!dir.exists(nameFolder_Fig_variation)) dir.create(nameFolder_Fig_variation, recursive = TRUE)

# ==== 🔁 Loop Through Print Modes (ANOVA, LMM, Step) ====
for (str_print in print_list) {
  # 📄 Create log file

  # ==== 🔁 Loop Through Location Groups ====
  for (str_loc in str_loc_list) {
    # 🧹 Load and Prepare Data
    dataTable_allB <- read.csv(sprintf("%s/%s_nBoot%d.csv", nameFolder_Load, str_loc, nBoot))

    # Take median and CI of parameters across boot iterations
    dataTable <- dataTable_allB %>%
      group_by(Subj, LocComb, SF, PerfLevel) %>%
      summarise(
        ThreshN0_t = median(ThreshN0_t),
        Gain = median(Gain),
        GainLog = median(GainLog),
        Nadd = median(Nadd),
        Gamma = median(Gamma),
        .groups = "drop"
      )

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
        PerfLevel = as.factor(PerfLevel),
        LocxSF_LocComb = interaction(SF, LocComb, drop = TRUE),
        LocxSF_SF = interaction(LocComb, SF, drop = TRUE)
      )

    # Explicitly set the jittered x values for LocComb (to be combined with above later)
    # Create numeric x-axis variables (including LocComb × SF interaction)
    dataTable <- dataTable %>%
      mutate(
        # Numeric version of each factor alone
        x_num_LocComb = as.numeric(factor(LocComb)),
        x_num_SF = as.numeric(factor(SF)),
        x_num_LocxSF_LocComb = as.numeric(LocxSF_LocComb),
        x_num_LocxSF_SF = as.numeric(LocxSF_SF),

        # Jittered x values across Loc, SF, and LocxSF
        x_jitter_LocComb = x_num_LocComb + runif(n(), -jitter_width, jitter_width),
        x_jitter_SF = x_num_SF + runif(n(), -jitter_width, jitter_width),
        x_jitter_LocxSF_LocComb = x_num_LocxSF_LocComb + runif(n(), -jitter_width, jitter_width),
        x_jitter_LocxSF_SF = x_num_LocxSF_SF + runif(n(), -jitter_width, jitter_width),
      )

    # ==== 🔁 Loop Through Parameters (Gain, Nadd, Gamma) ====
    for (param in param_list) {
      cat(sprintf("\n\n*******************************************************************\n [%s%s] Location: %s | Param: %s \n*******************************************************************\n\n", str_SF, str_n9, str_loc, param))

      # Convert param to numeric (just in case)
      dataTable[[param]] <- as.numeric(dataTable[[param]])

      # Define y ticks
      yticks <- yticks_param[[param]] # Get yticks for the current param_LDI
      
      # ==== 🔁 Loop Through Effect Type ====
      for (iEffect in 1:length(Effect_list)) {
        str_effect <- Effect_list[iEffect] # "MainEffect", "Interaction"

        # ==== 🔸 Main effect ====
        if (str_effect == "MainEffect") {
          
          # ==== 🔁 Loop Through IV (Loc/SF) ====
          for (iIV in 1:length(IV1_list)) {
            IV1 <- IV1_list[iIV] # "LocComb", "SF"
            IV2 <- IV2_list[iIV] # "SF", "LocComb"

            # Create a folder for the current effect and IV
            nameFolder_Fig_variation_ <- sprintf("%s/%s_%s", nameFolder_Fig_variation, str_effect, IV1)
            if (!dir.exists(nameFolder_Fig_variation_)) dir.create(nameFolder_Fig_variation_, recursive = TRUE)
            
            # Extract x jitter given the IV
            dataTable$x_num <- dataTable[[paste0("x_num_", IV1)]]
            dataTable$x_jitter <- dataTable[[paste0("x_jitter_", IV1)]] # "x_jitter_Loc", "x_jitter_SF"
            # dataTable$x_num <- dataTable[[paste0("x_num_LocxSF_", IV1)]]
            # dataTable$x_jitter <- dataTable[[paste0("x_jitter_LocxSF_", IV1)]]
            
            nIVLevels <- length(unique(dataTable[[IV1]]))

            # Compute the group ave (not based on model)
            summary_df <- dataTable %>%
              group_by(.data[[IV1]], .data[[IV2]]) %>%
              summarise(
                emmean = mean(.data[[param]]),
                SE = sd(.data[[param]]) / sqrt(n()),
                .groups = "drop"
              ) %>%
              mutate(
                x_num = as.numeric(factor(.data[[IV1]])), 
                x_jitter = as.numeric(factor(.data[[IV1]]))
                )

            # Create x-axis tick labels based on unjittered group levels
            x_labels <- levels(factor(dataTable[[IV1]]))

            # ==== 🎨 Plot: Main effect ====
            p_ME <- ggplot() +

              # (1) IDVD data points and grey subject lines
              geom_line(
                data = dataTable,
                aes(x = x_jitter, y = get(param), group = interaction(Subj, .data[[IV2]])),
                color = "grey", alpha = marker_alpha, linewidth = sz_line[1]/2
              ) +
              # geom_point(
              #   data = dataTable,
              #   aes(x = x_jitter, y = get(param), color = LocComb, shape = SF),
              #   size = sz_marker[1]/2, alpha = marker_alpha
              # ) +

              # (2) Group averages and error bars
              geom_errorbar(
                data = summary_df,
                aes(x = x_num, ymin = emmean - SE, ymax = emmean + SE, group = .data[[IV2]], color = LocComb),
                position = pos_dodge, width = 0, linewidth = sz_line[1]
              ) +
              geom_line(
                data = summary_df,
                aes(x = x_num, y = emmean, group = .data[[IV2]]),
                position = pos_dodge, linewidth = sz_line[1], color = "black"
              ) +
              geom_point(
                data = summary_df,
                aes(x = x_num, y = emmean, group = .data[[IV2]], color = LocComb, shape = SF),
                position = pos_dodge, size = sz_marker[1],
                fill = "white" ,# This sets the inside of the marker to white
                stroke = sz_line[1]        # optional: controls outline thickness
              ) +

              # draw comparison lines only for nLoc_s==2 and for Gain 
              # (if (length(unique(summary_df$x_num)) == 2 & param == 'Gain') {
              #   
              #   geom_segment(aes(x = 1, xend = 2, y = 4.2, yend = 4.2), 
              #                color = "grey40", linetype = "solid", linewidth = 0.6)
              # })+
              # 
              
              # Add comparison lines only if nLoc_s == 3 and IV=LocComb
              (if (length(unique(summary_df$x_num)) == 3 && iIV==1) {
                y_start <- y_start_ME[[param]]
                
                line_ME <- data.frame(
                  x = c(1, 1, 2),
                  xend = c(3, 2, 3),
                  y = y_start + y_buffer * 0:2,
                  yend = y_start + y_buffer * 0:2
                )
                
                  geom_segment(data = line_ME,
                               aes(x = x, xend = xend, y = y, yend = yend),
                               inherit.aes = FALSE,
                               color = "black", linetype = "solid", linewidth = 0.6)
              })+

            
              # Other settings
              scale_color_manual(values = location_colors) +
              scale_shape_manual(values = shape_SF) + # shapes indicate SF
              coord_cartesian(
                xlim = c(1 - x_buffer, nIVLevels + x_buffer),
                # ylim = limits_params[[param]]
              ) +
              # Set y limits
              scale_y_continuous(
                limits = c(yticks[1], yticks[length(yticks)]),
                breaks = yticks
              )+
              theme_bw() +
              theme( 
                # line width of axis
                axis.line = element_line(linewidth = sz_line[1]/3),
                panel.grid.major.y = element_line(linewidth = sz_line[1]/3),
                
                # Axis title text (with margin added!)
                axis.title.x = element_text(size = sz_label_x[1], margin = margin(t = sz_marg)),
                axis.title.y = element_text(size = sz_label_y[1], margin = margin(r = sz_marg)),
                
                # Axis tick labels
                axis.text.x = element_text(size = sz_tick_x[1]),
                axis.text.y = element_text(size = sz_tick_y[1]),

                # Legend text and title
                legend.text = element_text(size = sz_legend[1]),
                legend.title = element_text(size = sz_legend_title[1]),

                # Plot title
                plot.title = element_text(size = sz_title[1], face = "bold")
              ) +
              
              labs(
                title = sprintf("[%s%s] %s Across %s", str_SF, str_n9, param, IV1),
                x = IV1, y = param
              ) +
              scale_x_continuous(breaks = 1:length(x_labels), labels = x_labels)

            print(p_ME)
            
            
            ggsave(sprintf("%s/%s_%s_nBoot%d.png", nameFolder_Fig_variation_, param, str_loc, nBoot),
              plot = p_ME, width = sz_wd, height = sz_ht, dpi = 300
            )
          } # End of for loop on iIV (main effect)

          # ==== 🔸 Interactions ====
        } else if (str_effect == "Interaction") {
          
          # Compute the group ave (not based on model)
          summary_df <- dataTable %>%
            group_by(LocComb, SF) %>%
            summarise(
              emmean = mean(.data[[param]]),
              SE = sd(.data[[param]]) / sqrt(n()),
              .groups = "drop"
            ) %>%
            mutate(
              x_num_LocComb = as.numeric(factor(LocComb)),
              x_num_SF = as.numeric(factor(SF))
            )

          # merge facet layout into dataTable
          if (flag_plot7Locs == TRUE) {
            # Combine layout index to two datasets
            layout_df_clean <- tibble(
              LocComb = names(layout_df),
              FacetRow = sapply(layout_df, function(x) x[1]),
              FacetCol = sapply(layout_df, function(x) x[2])
            )

            dataTable <- left_join(dataTable, layout_df_clean, by = "LocComb")
            summary_df <- left_join(summary_df, layout_df_clean, by = "LocComb")

            # Create a custom labeller function
            facet_labeller <- function(row, col) {
              mapply(function(r, c) {
                match_idx <- which(layout_df_clean$FacetRow == as.numeric(r) & layout_df_clean$FacetCol == as.numeric(c))
                if (length(match_idx) > 0) {
                  layout_df_clean$LocComb[match_idx]
                } else {
                  ""
                }
              }, row, col)
            }
          }

          # ==== 🔁 Loop Through IV (Loc/SF) ====
          for (iIV in 1:length(IV1_list)) {
            IV1 <- IV1_list[iIV] # "LocComb", "SF"
            IV2 <- IV2_list[iIV] # "SF", "LocComb"

            # Create a folder for the current effect and IV
            nameFolder_Fig_variation_ <- sprintf("%s/%s_%s", nameFolder_Fig_variation, str_effect, IV1)
            if (!dir.exists(nameFolder_Fig_variation_)) dir.create(nameFolder_Fig_variation_, recursive = TRUE)
            
            # determine the x jitter
            dataTable$x_jitter <- dataTable[[paste0("x_jitter_", IV1)]] # "x_jitter_Loc", "x_jitter_SF"
            summary_df$x_num <- summary_df[[paste0("x_num_", IV1)]] # "x_jitter_Loc", "x_jitter_SF"
            # dataTable$x_jitter <- dataTable[[paste0("x_jitter_LocxSF_", IV1)]] # "x_jitter_Loc", "x_jitter_SF"
            # summary_df$x_num <- summary_df[[paste0("x_num_LocxSF_", IV1)]] # "x_jitter_Loc", "x_jitter_SF"
            
            nIVLevels <- length(unique(dataTable[[IV1]]))
            x_labels <- levels(factor(dataTable[[IV1]]))

            # ==== 🎨 Plot Interaction ====
            p_int <- ggplot() +

              # (1) Individual data points and grey subject lines
              geom_line(
                data = dataTable,
                aes(x = x_jitter, y = get(param), group = interaction(Subj, .data[[IV2]])),
                color = "grey", alpha = marker_alpha, linewidth = sz_line[2]/2
              ) +
              # geom_point(
              #   data = dataTable,
              #   aes(x = x_jitter, y = get(param), color = LocComb, shape = SF),
              #   size = sz_marker[2]/2, alpha = 0.5
              # ) +

              # (2) Group averages and error bars
              geom_errorbar(
                data = summary_df,
                aes(x = x_num, ymin = emmean - SE, ymax = emmean + SE, group = .data[[IV1]], color = LocComb),
                position = pos_dodge, width = 0, linewidth = sz_line[2]
              ) +
              geom_line(
                data = summary_df,
                aes(x = x_num, y = emmean),
                position = pos_dodge, linewidth = sz_line[2], color = "black"
              ) +
              geom_point(
                data = summary_df,
                aes(x = x_num, y = emmean, group = .data[[IV2]], color = LocComb, shape = SF),
                position = pos_dodge, size = sz_marker[1],
                fill = "white" ,# This sets the inside of the marker to white
                stroke = sz_line[1]        # optional: controls outline thickness
              ) +
              
              # geom_point(
              #   data = summary_df,
              #   aes(x = x_num, y = emmean, group = .data[[IV1]], color = LocComb, shape = SF),
              #   position = pos_dodge, size = sz_marker[2]
              # ) +

              # (4) Other settings
              scale_color_manual(values = location_colors) +
              scale_shape_manual(values = shape_SF) + # shapes indicate SF
              
              coord_cartesian(
                xlim = c(1 - x_buffer, nIVLevels + x_buffer),
                # ylim = limits_params[[param]]
              ) +
              # Set y limits
              scale_y_continuous(
                limits = c(yticks[1], yticks[length(yticks)]),
                breaks = yticks
              )+
              theme_bw() +
              theme( 
                # line width of axis
                axis.line = element_line(linewidth = sz_line[2]/3),
                panel.grid.major.y = element_line(linewidth = sz_line[2]/3),
                
                # Axis title text (with margin added!)
                axis.title.x = element_text(size = sz_label_x[2], margin = margin(t = sz_marg)),
                axis.title.y = element_text(size = sz_label_y[2], margin = margin(r = sz_marg)),
                
                # Axis tick labels
                axis.text.x = element_text(size = sz_tick_x[2]),
                axis.text.y = element_text(size = sz_tick_y[2]),
                
                # Legend text and title
                legend.text = element_text(size = sz_legend[2]),
                legend.title = element_text(size = sz_legend_title[2]),
                
                # Plot title
                plot.title = element_text(size = sz_title[2], face = "bold"),
                
                # remove the facet band
                strip.background = element_blank(),
                strip.text = element_blank()
              ) +
              labs(
                title = sprintf("[%s%s] (nBoot=%d) %s across %s (Interaction)", str_SF, str_n9, nBoot, param, IV1),
                x = IV1, y = param
              ) +
              scale_x_continuous(breaks = 1:length(x_labels), labels = x_labels)
            
            # Add comparison lines only if nLoc_s == 3 and param == "Gain" and IV=LocComb
            if (length(unique(summary_df$x_num)) == 3 && param == 'Gain' && iIV==1) {
              p_int <- p_int +
                geom_segment(data = line_interaction_Gain,
                             aes(x = x, xend = xend, y = y, yend = yend),
                             inherit.aes = FALSE,
                             color = "black", linetype = "solid", linewidth = 0.6)
            }
              
            # (3) Facet by the second IV
            p_int_final <- 0
            # Add the facet after constructing the base plot
            if (flag_plot7Locs == TRUE) {
              p_int_final <- p_int + facet_grid(
                rows = vars(FacetRow),
                cols = vars(FacetCol),
                switch = "both",
                drop = TRUE
              )
            } else {
              p_int_final <- p_int + facet_wrap(~ .data[[IV2]])
            }
            
            print(p_int_final)

            ggsave(sprintf("%s/%s_%s_nBoot%d.png", nameFolder_Fig_variation_, param, str_loc, nBoot),
              plot = p_int_final, width = sz_wd * 1.5, height = sz_ht, dpi = 300
            )
          } # End of for loop on iIV (interaction)
        } # end of choosing effect based on iEffect
        
      } # End of for loop on IEffect
    } # end param loop
  } # end loc loop
  cat("\n\n============= DONE ==============\n")
} # end print mode loop

end_time <- Sys.time() # ⏱️ toc
dur <- end_time - start_time # See how much time passed
print(round(dur, 1))
cat(sprintf(
  "\n\n============= %s%s (P%.0f) ALL DONE ==============\n",
  str_SF, str_n9, PerfLevel_s * 100
))
