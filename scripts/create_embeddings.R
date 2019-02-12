# Script reads preprocessed faces and creates embeddings 
# from OpenFace https://github.com/iwantooxxoox/Keras-OpenFace 

library(keras)
library(purrr)

# Script args:
# - directory with processed photos of faces
# - number of images to be embedded at once
#
args <- commandArgs(trailingOnly = TRUE)
print(args)

faces_dir <- ifelse(is.na(args[1]), "photos/10yearschallenge_faces/", args[1])
embedding_file <- ifelse(is.na(args[2]), "tmp/test.csv", args[2])
batch_size <- ifelse(is.na(args[3]), 1000, as.numeric(args[3]))
n_max <- ifelse(is.na(args[4]), Inf, as.numeric(args[4]))

# Load OpenFace model
model <- load_model_hdf5('nn4.small2.lrn.h5')

faces <- list.files(faces_dir)
n_faces <- pmin(length(faces), n_max)
n_batches <- ceiling(n_faces/batch_size)

1:n_batches %>%
  map(~{
    faces[(1 + (.x-1)*batch_size):(.x*batch_size)] %>%
      discard(is.na) %>%
      set_names() %>%
      map_df(~{
        image_load(file.path(faces_dir, .x), target_size = c(96,96)) %>%
          image_to_array() %>%
          array_reshape(., c(1, dim(.))) %>%
          imagenet_preprocess_input(mode = 'tf') %>%
          predict(model, .)
      }) %>%
      t %>%
      as.data.frame() %>%
      tibble::rownames_to_column('face') %>%
      write.table(embedding_file, row.names = F, append = .x != 1, col.names = .x == 1, sep = ',')
    
    print(sprintf('%d photos has been processed', min(.x * batch_size, n_faces)))
  }) %>% invisible()