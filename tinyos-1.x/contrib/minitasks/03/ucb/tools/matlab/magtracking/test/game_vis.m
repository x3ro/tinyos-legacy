function game_vis

global VIS;

% start w/ clean slate
initVis;


drawVis
vis_gui

startVisTimer
VIS.flag.nodes_updated = 1;


% collect the spanning tree info
%peg all ststatus;

VIS.flag.nodes_updated = 1;
