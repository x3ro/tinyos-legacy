There are two sample topologies in this directory.

topology.testbed.h - this is just a beacon configuration, really. It just
                     defines, for up to 256 nodes, whether they are or not 
                     beacons, and their beacon ids. To use this, copy it 
                     to topology.h (so that it will be compiled in), and 
                     now your motes with ids 1 through 5 will be beacons.

                     To use this file with TOSSIM you have to define a 
                     meaningful topology file for the radio model, specifying
                     which nodes can talk to which.


graph-n200-d12-r5-sd123-edges.topology.h -
                     this topology is created with a script
                     (generate_topology.pl), and is just a sample. It has
                     200 nodes, average number of neighbors of approximately
                     12, and 5 beacons evenly spread at the edges of the
                     network. To use this (and any other topology you 
                     may come to generate with that script), copy or link
                     the *.topology.h file to topology.h, and then run 
                     TOSSIM with the -pf switch pointing to the relevant file.

For example, to run TestBVRSimple with this topology (note that you must 
compile that with the right topology.h file), you could do the following:

$> cd TestBVRSimple
$> make pc
$> DBG=usr3 build/pc/main.exe -pf=../../topologies/graph-n200-d12-r5-sd123-edges.pkt_lossless -t=1800 200

This turns on the usr3 debugging, specifies the connectivity file for
TOSSIM-packet to be the pkt_lossless file, and runs the simulation with 200
motes for 1800 seconds of simulated time.




