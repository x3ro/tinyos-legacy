function updateMagData( nodeID, reading )


global VIS;

idx = getNodeIdx( nodeID );
VIS.node(idx).mag_reading = reading;
VIS.node(idx).mag_time = cputime;

VIS.flag.mag_updated = 1;

