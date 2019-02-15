# Script for plotting  models performance

source('scripts/utils.R')

# Script args:
# - directory with models' predictions
# - output plot file

args <- commandArgs(trailingOnly = TRUE)

predictions_dir <- ifelse(is.na(args[1]), "data/predictions", args[1])
plot_file <- ifelse(is.na(args[1]), "reports/models_diagnostics.png", args[1])

# Read data ---------------------------------------------------------------

p <- list.files(predictions_dir, full.names = TRUE) %>%
  map_dfr(read_csv) %>%
  plotModelDiagnostic(match, score, model, set)
ggsave(plot_file, p, width = 12, height = 10)
