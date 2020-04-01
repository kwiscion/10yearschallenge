# Script splits photos into halfs and checks if each half contains a face. 
# If so, they are cropped and moved to target directory

library(purrr)

# Script args:
# - directory with photos to be processed
#
args <- commandArgs(trailingOnly = TRUE)
print(args)

if(interactive()) {
  data_dir <- 'photos/10yearschallenge-1'
} else {
  data_dir <- args[1]
}

# Directory to save detected faces to
target_dir <- sprintf('%s_faces', data_dir)
if(dir.exists(target_dir)) stop(sprintf('%s directory already exists!', target_dir))
dir.create(target_dir)

# Temp directory for photos processing
tmp_dir <- 'tmp/photo_processing'
if(! dir.exists(tmp_dir)) dir.create(tmp_dir, recursive = TRUE)
list.files(tmp_dir, full.names = TRUE) %>% map(file.remove)

# Process photos
list.files(data_dir) %>%
  keep(grepl, pattern = '\\.jpg|\\.png') %>%
  map(~{
    # Split photo in halfs and save to tmp directory
    system(sprintf('convert -crop 50%%x100%% +repage %s/%s %s/%s', data_dir, .x, tmp_dir, .x))
    
    # Detect faces at tmp images
    faces <- list.files(tmp_dir) %>%
      set_names() %>%
      map(~.x %>%
            file.path(tmp_dir, .) %>% 
            opencv::ocv_read() %>% 
            opencv::ocv_facemask() %>% 
            attr('faces')) %>%
      keep(~nrow(.x) == 1)
    
    # If there are exactly 2 faces, one on each image, crop them and save to target directory
    if(length(faces) == 2) {
      faces %>%
        imap(~{
          system(sprintf('convert -crop %dx%d+%d+%d +repage  %s/%s %s/%s',
                         2* .x$radius, 2 * .x$radius,
                         .x$x - .x$radius, .x$y - .x$radius,
                         tmp_dir, .y, target_dir, .y))
        })
    }
    list.files(tmp_dir, full.names = TRUE) %>% map(file.remove)
  }) %>% invisible()
