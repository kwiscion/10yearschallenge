
htag:=10yearschallenge
max_photos:=10000
embed_batch_size:=1000



.PHONY : get_photos prepare_faces create_embeddings

get_photos : photos/$(htag)

photos/$(htag) :
	if [ -d photos/$(htag) ] ; then mv photos/$(htag) photos/$(htag)_old ; fi
	cd photos; instagram-scraper -u seweryn_bak -p hasloseweryna --tag $(htag) --maximum $(max_photos) --media-types image
	
prepare_faces : photos/$(htag)_faces

photos/$(htag)_faces : scripts/prepare_faces.R photos/$(htag)
	Rscript $^

create_embeddings : data/$(htag)_embeddings.csv

data/$(htag)_embeddings.csv : scripts/create_embeddings.R photos/$(htag)_faces
	Rscript $^ $@ $(embed_batch_size)