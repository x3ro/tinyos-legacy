load("msrc/utils.mud");
load("msrc/sf/sf.mud");
load("mate/mate.mud");
sf=open_sf_source("localhost", 9001);
qi(sf, "send(126, \"abc\")");
