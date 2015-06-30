COMMFN = FNcommM.nc FNrecvM.nc
MHOPFN = FNmhopM.nc
QUERYFN = FNqueryM.nc FNaggavgM.nc FNaggmaxM.nc FNaggminM.nc

all: gen/commfns.vmsf gen/mhopfns.vmsf gen/queryfns.vmsf \
     sgen/commfns.vmsf sgen/mhopfns.vmsf sgen/queryfns.vmsf

gen/commfns.vmsf: $(COMMFN)
	perl ../tools/genfns.pl $@ $(COMMFN)
	echo '<CONTEXT NAME="Receive">' >>$@

gen/mhopfns.vmsf: $(MHOPFN)
	perl ../tools/genfns.pl $@ $(MHOPFN)
	echo '<CONTEXT NAME="Snoop">' >>$@
	echo '<CONTEXT NAME="Intercept">' >>$@

gen/queryfns.vmsf: $(QUERYFN)
	perl ../tools/genfns.pl $@ $(QUERYFN)
	echo '<CONTEXT NAME="EpochChange">' >>$@

sgen/commfns.vmsf: $(COMMFN)
	perl ../tools/genfns.pl -scheme $@ $(COMMFN)
	echo '<CONTEXT NAME="Receive">' >>$@

sgen/mhopfns.vmsf: $(MHOPFN)
	perl ../tools/genfns.pl -scheme $@ $(MHOPFN)
	echo '<CONTEXT NAME="Snoop">' >>$@
	echo '<CONTEXT NAME="Intercept">' >>$@

sgen/queryfns.vmsf: $(QUERYFN)
	perl ../tools/genfns.pl -scheme $@ $(QUERYFN)
	echo '<CONTEXT NAME="EpochChange">' >>$@

clean:
	rm -rf gen sgen

install:
