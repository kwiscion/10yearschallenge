test :
	R -e "print(commandArgs(trailingOnly = TRUE))" --args aa

#htag:=orangeisnewblack
htag:=10yearschallenge
max_photos:=3

.PHONY : get_photos prepare_faces
get_photos : photos/$(htag)

prepare_faces : photos/$(htag)_faces

photos/$(htag) :
	if [ -d photos/$(htag) ] ; then mv photos/$(htag) photos/$(htag)_old ; fi
	cd photos; instagram-scraper -u seweryn_bak -p hasloseweryna --tag $(htag) --maximum $(max_photos) --media-types image
	
photos/$(htag)_faces : scripts/prepare_faces.R photos/$(htag)
	Rscript $^
