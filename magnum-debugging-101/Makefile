.PHONY: all clean

SVG := $(shell find img/ -name '*.svg')
DIA := $(shell find img/ -name '*.dia')
SVG_PNG := $(patsubst %.svg, %.png, $(SVG))
DIA_PNG := $(patsubst %.dia, %.PNG, $(DIA))
PNG :=  $(DIA_PNG) $(SVG_PNG)

IMG := \
  img/magnum_architecture_0.PNG \
	img/magnum_architecture_1.PNG \
	img/magnum_architecture_2.PNG \
	img/magnum_architecture_3.PNG \
	img/magnum_architecture_4.PNG \
	img/magnum_architecture_5.PNG \
	img/magnum_architecture_6.PNG \
	img/magnum_architecture_7.PNG \
	img/magnum_architecture_8.PNG \
	img/magnum_architecture_9.PNG \
	img/magnum_architecture_10.PNG \
	img/magnum_architecture_11.PNG \
	img/magnum_architecture_12.PNG \
	img/magnum_architecture_13.PNG \
	img/magnum_architecture_14.PNG \
	img/magnum_architecture_15.PNG \
	img/magnum_architecture_16.PNG

FILES_LIGHTNING := \
  magnum-debugging-101/lightning.md \
	magnum-debugging-101/lightning-4-3.odp \
	magnum-debugging-101/lightning-4-3.pdf \
	magnum-debugging-101/lightning-transcript.md \
	magnum-debugging-101/lightning-transcript.html
# Disabled for now: the architecture diagram doesn't fit into 16:9 format
#	magnum-debugging-101/full-16-9.odp \
#	magnum-debugging-101/full-16-9.pdf \
#	magnum-debugging-101/lightning-16-9.pdf \
#	magnum-debugging-101/lightning-16-9.odp

FILES_FULL := \
  magnum-debugging-101/full.md \
	magnum-debugging-101/full-4-3.odp \
	magnum-debugging-101/full-4-3.pdf \
	magnum-debugging-101/full-transcript.md \
	magnum-debugging-101/full-transcript.html
# Disabled for now: the architecture diagram doesn't fit into 16:9 format
#	magnum-debugging-101/full-16-9.odp \
#	magnum-debugging-101/full-16-9.pdf

FILES_COMMON := \
  cmd/* \
  output/* \
	common/*

all: magnum-debugging-101 $(FILES_LIGHTNING) $(FILES_FULL)

magnum-debugging-101/lightning.md: $(FILES_COMMON) lightning/*.md output/*
	echo 'changequote(,)' | cat - lightning/main.md | m4 > $@

magnum-debugging-101:
	mkdir -p magnum-debugging-101

magnum-debugging-101/full.md: $(FILES_COMMON)  full/*.md cmd/* output/*
	echo 'changequote(,)' | cat - full/main.md | m4 > $@

magnum-debugging-101/lightning-4-3.odp: magnum-debugging-101/lightning.md lightning/template-4-3.odp $(IMG)
	odpdown \
	-p 2 \
	--content-master SUSE_5f_4x3_5f_Template_5f_2016_25_20v1-ks1 \
	--break-master SUSE_5f_4x3_5f_Template_5f_2016_25_20v1-ks4 \
	magnum-debugging-101/lightning.md lightning/template-4-3.odp $@

magnum-debugging-101/lightning-16-9.odp: magnum-debugging-101/lightning.md lightning/template-16-9.odp $(IMG)
	odpdown \
	-p 2 \
	--content-master SUSE_5f_4x3_5f_Template_5f_2016_25_20v1-ks1 \
	--break-master SUSE_5f_4x3_5f_Template_5f_2016_25_20v1-ks1 \
	magnum-debugging-101/lightning.md lightning/template-16-9.odp $@

magnum-debugging-101/full-4-3.odp: magnum-debugging-101/full.md full/template-4-3.odp $(IMG)
	odpdown \
	-p 1 \
	--content-master SUSE_5f_4x3_5f_Template_5f_2016_25_20v1-ks1 \
	--break-master SUSE_5f_4x3_5f_Template_5f_2016_25_20v1-ks4 \
	magnum-debugging-101/full.md full/template-4-3.odp $@

magnum-debugging-101/full-16-9.odp: magnum-debugging-101/full.md full/template-16-9.odp $(IMG)
	odpdown \
	-p 1 \
	--content-master SUSE_5f_16x9_5f_Template_5f_2016_25_20v1-ks1 \
	--break-master SUSE_5f_16x9_5f_Template_5f_2016_25_20v1-ks4 \
	magnum-debugging-101/full.md full/template-16-9.odp $@

%.pdf: %.odp
	libreoffice --convert-to pdf --outdir $(shell dirname $<) $<

%.html: %.md
	pandoc -s --toc -f markdown_github -t html5 -o $@ $<

%-transcript.md: %.md $(IMG)
	rsync -a --delete img magnum-debugging-101
	bin/htmlcomments $< > $@

# ugly, but will do
img/%.Png: img/%.svg
	inkscape --export-png=$@ $<

img/%.PNG: img/%.dia
	dia -e $@ -t png $<

magnum-debugging-101.tar.bz2: all
	tar -cjf $@ magnum-debugging-101

clean:
	rm -f $(FILES_LIGHTNING) $(FILES_FULL)
	rm -f img/*PNG
	rm -f img/*Png
	rm -rf magnum-debugging-101
	rm -rf magnum-debugging-101.tar.bz2
