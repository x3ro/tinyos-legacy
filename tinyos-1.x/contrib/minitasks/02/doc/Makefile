
SECTIONS=title intro demo methodology estimation grouping localization \
  powermanagement routing servicecoordination timesync

DEPS=$(addsuffix .fake.xml,$(SECTIONS))

arch.html: $(DEPS) fakexml2html.pl Makefile
	./fakexml2html.pl $(DEPS) > arch.html

clean:
	rm -f arch.html

