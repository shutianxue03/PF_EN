# assess whether the extent of HVA is stronger than VMA:
# Fit LMM and conduct ANOVA on LDIs
# IV: Asymmetry (HVA vs. VMA) x ecc (4º and 8º) x SF (4 and 6 cpd) on LDI
#     - cvs files to load and combine: HM4VM4, HM8VM8, LVM4UVM8, LVM4UVM8
#     - Columns of the long table: LDI, iSubj, Asymmetry (HVA/VMA), Ecc (4/8), SF (4/6)


nBoot <- 1000

# Load LDI values of all 4 asymmetries

dataTable_LDI_HVA4 <- read.csv(sprintf("%s/LDI_HM4VM4_Pair12_nBoot%d.csv", nameFolder_Load, nBoot))
dataTable_LDI_HVA8 <- read.csv(sprintf("%s/LDI_LVM8UVM8_Pair12_nBoot%d.csv", nameFolder_Load, nBoot))
dataTable_LDI_VMA4 <- read.csv(sprintf("%s/LDI_LVM4UVM4_Pair12_nBoot%d.csv", nameFolder_Load, nBoot))
dataTable_LDI_VMA8 <- read.csv(sprintf("%s/LDI_HM8VM8_Pair12_nBoot%d.csv", nameFolder_Load, nBoot))

# Combine LDIs into a long table
dataTable_LDI <- rbind(
    dataTable_LDI_HVA4,
    dataTable_LDI_HVA8,
    dataTable_LDI_VMA4,
    dataTable_LDI_VMA8
) # <- this is a typo, should be VMA8

# Add a column to indicate type of asymmetry (column "Asymmetry")
dataTable_LDI$Asymmetry <- factor(
    ifelse(grepl("HM", dataTable_LDI$FileName), "HVA", "VMA"),
    levels = c("HVA", "VMA")
)

# Define LMM formula
formula <- "Asymmetry * SF * Ecc + (1 + Asymmetry | Subj)"
formula <- "Asymmetry * SF * Ecc + (1 | Subj)"

for (param_LDI in param_LDI_list) {
    cat(sprintf(
        "\n\n*********************************************************************\n [%s%s] | %s \n*********************************************************************\n\n",
        str_SF, str_n9, param_LDI
    ))
    # Fit LMM
    lmm_LDI <- lmer(as.formula(formula), data = dataTable_LDI)
    
}
