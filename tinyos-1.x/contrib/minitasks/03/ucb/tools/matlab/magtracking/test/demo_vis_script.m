function demo_vis_script

global VIS;

% start w/ clean slate
initVis;



% dummy route tree
for x = 1:VIS.num_nodes
  if i > 1
    VIS.node(i).parent = i-1;
  end
end
VIS.flag.route_tree_updated = 1;




% make a dummy crumb trail
%VIS.crumb


drawVis
vis_gui

startVisTimer


