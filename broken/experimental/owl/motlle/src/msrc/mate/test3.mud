load("msrc/utils.mud");
load("msrc/sf/sf.mud");
load("mate/mate.mud");
sf=open_sf_source("localhost", 9001);
qi(sf, "i = 0; Timer0 = fn () { i = (i + 1) & 7; LED(i) }; settimer0(10); ");
