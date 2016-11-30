.PHONY: all clean

SVG := $(shell find img/ -name '*.svg')
DIA := $(shell find img/ -name '*.dia')
SVG_PNG := $(patsubst %.svg, %.png, $(SVG))
DIA_PNG := $(patsubst %.dia, %.PNG, $(DIA))
PNG :=  $(DIA_PNG) $(SVG_PNG)

all: presentation.odp presentation.pdf transcript.txt

presentation.odp: slides.md	template.odp $(PNG)
	odpdown \
	-p 1 \
	--content-master No-Logo_20_Content \
	--break-master Break \
	slides.md template.odp presentation.odp

presentation.pdf: presentation.odp
	libreoffice --convert-to pdf $<

img/%.png: img/%.svg
	convert $< $@

# ugly, but will do
img/%.PNG: img/%.dia
	dia -e $@ -t svg $<

clean:
	rm -f presentation.odp
	rm -f img/*png
	rm -f img/*PNG

transcript.txt: slides.md
	bin/htmlcomments slides.md > transcript.md
