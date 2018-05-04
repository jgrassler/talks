.PHONY: all clean

SVG := $(shell find img/ -name '*.svg')
DIA := $(shell find img/ -name '*.dia')
SVG_PNG := $(patsubst %.svg, %.png, $(SVG))
DIA_PNG := $(patsubst %.dia, %.PNG, $(DIA))
PNG :=  $(DIA_PNG) $(SVG_PNG)

PRESENTATION=monasca-onboarding

CONTENT_MASTER=No-Logo_20_Content
BREAK_MASTER=Break

IMG := \
  img/sample0.PNG \
  img/sample1.PNG

FILES := \
  presentation.md \
	presentation-4-3.odp \
	presentation-4-3.pdf \
	presentation-16-9.odp \
	presentation-16-9.pdf \
	transcript.md \
	transcript.html

all: $(PRESENTATION) $(FILES)

presentation.md: src/*.md
	echo 'changequote(,)' | cat - src/main.md | m4 > $@

$(PRESENTATION): $(FILES) $(IMG)
	mkdir -p $(PRESENTATION)
	tar -cf - img | tar -C $(PRESENTATION) -xf -
	cp $(FILES) $(PRESENTATION)

presentation-4-3.odp: presentation.md templates/template-4-3.odp $(IMG)
	odpdown \
	-p 1 \
	--content-master $(CONTENT_MASTER) \
	--break-master $(BREAK_MASTER) \
	presentation.md templates/template-4-3.odp $@

presentation-16-9.odp: presentation.md templates/template-16-9.odp $(IMG)
	odpdown \
	-p 1 \
	--content-master $(CONTENT_MASTER) \
	--break-master $(BREAK_MASTER) \
	presentation.md templates/template-16-9.odp $@

%.pdf: %.odp
	libreoffice --convert-to pdf --outdir $(shell dirname $<) $<

%.html: %.md
	pandoc -s --toc -f markdown_github -t html5 -o $@ $<

transcript.md: presentation.md
	bin/htmlcomments $< > $@

# ugly, but will do
img/%.Png: img/%.svg
	inkscape --export-png=$@ $<

img/%.PNG: img/%.dia
	dia -e $@ -t png $<


$(PRESENTATION).tar.bz2: all
	tar -cjf $@ $(PRESENTATION)

clean:
	rm -f $(FILES)
	rm -f img/*PNG
	rm -f img/*Png
	rm -rf $(PRESENTATION)
	rm -rf $(PRESENTATION).tar.bz2
