function monitorSchExpInit
global experiment
global NUM_NODES

experiment.nodes=[4 5 6];
experiment.index = 1;
experiment.numNodes = 25;

monitorRunCollectData;

