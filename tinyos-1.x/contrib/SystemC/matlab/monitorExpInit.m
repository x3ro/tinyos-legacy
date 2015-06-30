function monitorExpInit
global experiment
global NUM_NODES

%peg all reset
%peg all reset
%peg all reset

%peg all on
%peg all on
%peg all on

peg all service(50)
peg all service(50)
peg all service(50)
	
experiment.nodes=[4 5 6];
experiment.index = 1;
experiment.numNodes = 25;

monitorExpRun

