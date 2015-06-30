function demo_vis_script

global VIS;

% start w/ clean slate
initVis;


for n = 1:VIS.num_nodes
    for i = 1:3
        m = ceil( rand(1) * VIS.num_nodes );
        VIS.node(n).anchor(i).nodeIdx = m;
        VIS.node(n).anchor(i).dist = 10*rand(1);
        
        m = ceil( rand(1) * VIS.num_nodes );
        VIS.node(n).neighbor(i).nodeIdx = m;
        VIS.node(n).neighbor(i).dist = 10*rand(1);
    end
end

VIS.show.ranging = 1;
VIS.show.anchor = 1;

drawVis
vis_gui

startVisTimer

