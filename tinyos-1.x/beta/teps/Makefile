TEPS = $(wildcard txt/*.txt)
HTML = $(subst txt/,,$(subst .txt,.html,$(TEPS)))
STYLESHEET = stylesheets/tep.css

%.html: txt/%.txt
	rst2html.py --stylesheet-path=$(STYLESHEET) --embed-stylesheet $< > html/$@

all: $(HTML)

clean:
	rm -f html/*.html txt/*~ txt/#* txt/.#*

