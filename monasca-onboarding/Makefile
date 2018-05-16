.PHONY: all clean

PRESENTATION=monasca-onboarding

CONTENT_MASTER=No-Logo_20_Content
BREAK_MASTER=Break

FILES := \
  presentation.md \
	presentation-4-3.odp \
	presentation-4-3.pdf \
	presentation-16-9.odp \
	presentation-16-9.pdf \
	transcript.md \
	transcript.html

PDF := \
	img/architecture1.pdf \
	img/architecture2.pdf \
	img/architecture3.pdf \
	img/architecture4.pdf \
	img/architecture5.pdf \
	img/architecture6.pdf \
	img/architecture7.pdf \
	img/architecture8.pdf \
	img/architecture9.pdf \
	img/architecture10.pdf \
	img/architecture11.pdf

IMG := \
	img/architecture1.Png \
	img/architecture2.Png \
	img/architecture3.Png \
	img/architecture4.Png \
	img/architecture5.Png \
	img/architecture6.Png \
	img/architecture7.Png \
	img/architecture8.Png \
	img/architecture9.Png \
	img/architecture10.Png \
	img/architecture11.Png

all: $(PDF) $(IMG) $(FILES) $(PRESENTATION) $(PRESENTATION).tar.bz2

$(PDF): img/architecture.pdf
	(cd img; pdftk architecture.pdf burst output 'architecture%d.pdf')

presentation.md: src/*.md
	echo 'changequote(,)' | cat - src/main.md | m4 > $@

$(PRESENTATION): $(FILES)
	mkdir -p $(PRESENTATION)
	touch $(PRESENTATION)
	tar -cf - img | tar -C $(PRESENTATION) -xf -
	cp $(FILES) $(PRESENTATION)

presentation-4-3.odp: presentation.md templates/template-4-3.odp
	odpdown \
	-p 1 \
	--content-master $(CONTENT_MASTER) \
	--break-master $(BREAK_MASTER) \
	presentation.md templates/template-4-3.odp $@

presentation-16-9.odp: presentation.md templates/template-16-9.odp
	odpdown \
	-p 1 \
	--content-master $(CONTENT_MASTER) \
	--break-master $(BREAK_MASTER) \
	presentation.md templates/template-16-9.odp $@

%.pdf: %.odp
	rm -f $(PDF) # pdftk won't overwrite
	libreoffice --convert-to pdf --outdir $(shell dirname $<) $<

%.html: %.md
	pandoc -s --toc -f markdown_github -t html5 -o $@ $<

transcript.md: presentation.md
	bin/htmlcomments $< > $@

img/architecture.pdf: img/architecture.odg
	libreoffice --convert-to pdf --outdir img/ $<

# ugly, but will do
img/%.Png: img/%.pdf
	inkscape --export-png=$@ $<

img/%.PNG: img/%.dia
	dia -e $@ -t png $<


$(PRESENTATION).tar.bz2:	$(PRESENTATION)
	tar -cjf $@ $(PRESENTATION)

clean:
	rm -f $(FILES)
	rm -f img/*PNG
	rm -f img/*pdf
	rm -f img/doc_data.txt
	rm -f img/*Png
	rm -rf $(PRESENTATION)
	rm -rf $(PRESENTATION).tar.bz2
