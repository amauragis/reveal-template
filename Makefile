include config.mk

.PHONY: all run clean

SLIDES = $(shell grep -E -h -o 'slides/.*' main.sed)

$(info )
$(info Slides)
$(info =======)
$(info $(SLIDES))
$(info )

all: index.html

run: index.html
	python -m SimpleHTTPServer 8080

main.html: main.sed $(SLIDES) Makefile
	echo | sed -f main.sed > $@

%.html: %.tex
	pandoc -f latex -t revealjs $< -o $@

%.html: %.md
	pandoc -f markdown-tex_math_dollars -t revealjs $< -o $@

dist: index.html
	mkdir -p $@
	cp $< $@/
	{\
		grep 'mathjax *:\|src *[=:]\|href *=' $< ; \
		test -n "$(DIST_FILES)" && echo $(DIST_FILES) | tr ' ' '\n' || echo; \
	} | \
	tr '"'"'" '\n' | \
	cat - | \
	while read line; do \
		test -e "$$line" && { \
			echo "Copying $$line" ; \
			mkdir -p $@/$$(dirname  "$$line"); \
			cp -r "$$line" $@/$$(dirname  "$$line"); \
		} || echo -n ;\
	done

index.html: main.html
	pandoc \
		--template=template/template-revealjs.html \
		-t html5 \
		-V author="$(AUTHOR)" \
		-V title="$(TITLE)" \
		-V date="$(DATE)" \
		-V revealjs-url="$(REVEALJS_URL)" \
		-V theme=$(THEME) \
		-V mathjax="$(MATHJAX_URL)" \
		-V transition=fade \
		$< -o $@


.FORCE:
gh-pages:
	$(MAKE) CDNLIBS=1
	git checkout gh-pages
	git add index.html
	git commit -m Update

clean:
	-rm -f index.html
	-rm -f main.html
	-rm -rf dist
