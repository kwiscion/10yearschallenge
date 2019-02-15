
htag:=10yearschallenge
max_photos:=10
embed_batch_size:=1000

train_size:=20000
valid_size:=5000
positive_shr:=0.5

.PHONY : get_photos prepare_faces create_embeddings create_trainset plot_models_diagnostics

######
plot_models_diagnostics : reports/models_diagnostics.png

reports/models_diagnostics.png : scripts/plot_models_diagnostics.R data/predictions
	Rscript $^ $@

######
create_trainset : data/$(htag)_trainset_bare.csv data/$(htag)_trainset_embeddings.csv

data/$(htag)_trainset_bare.csv : scripts/create_train_validation.R data/$(htag)_embeddings.csv
	Rscript $^ $(train_size) $(valid_size) $(positive_shr)

data/$(htag)_trainset_embeddings.csv : scripts/append_embeddings.R data/$(htag)_trainset_bare.csv data/$(htag)_embeddings.csv
	Rscript $^

######
create_embeddings : data/$(htag)_embeddings.csv

data/$(htag)_embeddings.csv : scripts/create_embeddings.R photos/$(htag)_faces
	Rscript $^ $@ $(embed_batch_size)
	
######
prepare_faces : photos/$(htag)_faces

photos/$(htag)_faces : scripts/prepare_faces.R photos/$(htag)
	Rscript $^

######
get_photos : photos/$(htag)

photos/$(htag) :
	if [ -d photos/$(htag) ] ; then mv photos/$(htag) photos/$(htag)_old ; fi
	@while [ -z "$$INS_USER" ]; do \
		read -r -p "Instagram user name: " INS_USER;\
	done && \
	while [ -z "$$INS_PASSWORD" ]; do \
		read -r -p "Instagram password: " INS_PASSWORD; \
	done && \
	cd photos; instagram-scraper -u $$INS_USER -p $$INS_PASSWORD --tag $(htag) --maximum $(max_photos) --media-types image