
htag:=10yearschallenge
max_photos:=10000
embed_batch_size:=1000



.PHONY : get_photos prepare_faces create_embeddings

create_embeddings : data/$(htag)_embeddings.csv

data/$(htag)_embeddings.csv : scripts/create_embeddings.R photos/$(htag)_faces
	Rscript $^ $@ $(embed_batch_size)
	
prepare_faces : photos/$(htag)_faces

photos/$(htag)_faces : scripts/prepare_faces.R photos/$(htag)
	Rscript $^

get_photos : photos/$(htag)

photos/$(htag) :
	if [ -d photos/$(htag) ] ; then mv photos/$(htag) photos/$(htag)_old ; fi \
	@while [ -z "$$INS_USER" ]; do \
		read -r -p "Instagram user name: " INS_USER;\
	done && \
	while [ -z "$$INS_PASSWORD" ]; do \
		read -r -p "Instagram password: " INS_PASSWORD; \
	done && \
	cd photos; instagram-scraper -u $$INS_USER -p $$INS_PASSWORD --tag $(htag) --maximum $(max_photos) --media-types image