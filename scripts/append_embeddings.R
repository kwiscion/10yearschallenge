# Script for appending embeddings to training and validation sets

library(tidyverse)

# Script args:
# - file with train and validation set
# - file with faces` embeddings 

args <- commandArgs(trailingOnly = TRUE)

trainset_file <- ifelse(is.na(args[1]), "data/10yearschallenge_trainset_bare.csv", args[1])
embedding_file <- ifelse(is.na(args[2]), "data/10yearschallenge_embeddings.csv", args[2])

output_file <- gsub('bare', 'embeddings', trainset_file)

# Read data ---------------------------------------------------------------

trainset <- read_csv(trainset_file)
embeddings <- read_csv(embedding_file)

trainset %>%
  inner_join(embeddings %>%
               rename_at(vars(-face), gsub, pattern = 'V', replacement = 'V1_'),
               by = c(face1 = 'face')) %>%
  inner_join(embeddings %>%
               rename_at(vars(-face), gsub, pattern = 'V', replacement = 'V2_'),
               by = c(face2 = 'face')) %>%
  write_csv(output_file)