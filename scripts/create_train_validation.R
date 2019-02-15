# Script for generation of train and validation sets

library(tidyverse)

# Script args:
# - file with faces` embeddings 
# - size of training set
# - size of validation set
# - fraction of positive class in the training set

args <- commandArgs(trailingOnly = TRUE)

embedding_file <- ifelse(is.na(args[1]), "data/10yearschallenge_embeddings.csv", args[1])
train_size <- ifelse(is.na(args[2]), 7e3, as.numeric(args[2]))
validation_size <- ifelse(is.na(args[3]), 3e3, as.numeric(args[3]))
match_frac <- ifelse(is.na(args[4]), 0.3, as.numeric(args[4]))

output_file <- gsub('embeddings', 'trainset_bare', embedding_file)
total_size <- train_size + validation_size

other_face <- function(x){
  ifelse(grepl('-1', x), gsub('-1', '-0', x), gsub('-0', '-1', x))
}

faces <- read_csv(embedding_file)

margin <- 2
set.seed(1111)
data.frame(face1 = sample(faces$face, total_size * margin, replace = T),
           face2 = sample(faces$face, total_size * margin, replace = T),
           stringsAsFactors = F) %>%
  filter(face1 != face2 & face1 != other_face(face2)) %>%
  mutate(match = as.numeric(runif(n()) <= match_frac)) %>%
  mutate(face2 = if_else(match == 1,
                         other_face(face1),
                         face2)) %>%
  group_by(face1, face2) %>%
  filter(n() == 1) %>%
  ungroup() %>%
  sample_n(total_size) %>%
  mutate(set = sample(c(rep('train', train_size), rep('validation', validation_size)),
                      train_size + validation_size, replace = FALSE)) %>%
  write_csv(output_file)
