INTFN = FNarithM.nc FNbasicM.nc FNlistM.nc FNstringM.nc FNvectorM.nc FNseqM.nc
SCHEMEINTFN = $(INTFN) SFNarithM.nc SFNmagic.nc
FLOATFN = FNrealM.nc
SCHEMEFLOATFN = $(FLOATFN) SFNrealM.nc
TRANSFN = FNtranscendentalsM.nc
SCHEMETRANSFN = $(TRANSFN)

all: gen/intfns.vmsf gen/floatfns.vmsf gen/transcendentalfns.vmsf \
     sgen/intfns.vmsf sgen/floatfns.vmsf sgen/transcendentalfns.vmsf

gen/intfns.vmsf: $(INTFN)
	perl ../../tools/genfns.pl $@ $(INTFN)
	echo '<CONTEXT NAME="Once">' >>$@

gen/floatfns.vmsf: $(FLOATFN) gen/intfns.vmsf
	perl ../../tools/genfns.pl $@ $(FLOATFN)
	cat gen/intfns.vmsf >>$@

gen/transcendentalfns.vmsf: $(TRANSFN)
	perl ../../tools/genfns.pl $@ $(TRANSFN)

sgen/intfns.vmsf: $(SCHEMEINTFN)
	perl ../../tools/genfns.pl -scheme $@ $(SCHEMEINTFN)
	echo '<CONTEXT NAME="Once">' >>$@

sgen/floatfns.vmsf: $(SCHEMEFLOATFN) sgen/intfns.vmsf
	perl ../../tools/genfns.pl -scheme $@ $(SCHEMEFLOATFN)
	cat sgen/intfns.vmsf >>$@

sgen/transcendentalfns.vmsf: $(SCHEMETRANSFN)
	perl ../../tools/genfns.pl -scheme $@ $(SCHEMETRANSFN)


clean:
	rm -rf gen sgen

install:
