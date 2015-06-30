function drawTree(plot_name, parent_field_name, real_pos)
%
% Draw a tree.  
% 
% tree_name: the name of the tree plot
% 
% parent_field_name:  The field in the node structure that
%     describes the parent/child relationships.
% 
% real_pos:  if true, draw arrows between real node positions.  If
%     false, draw between calculated positions.
%
global VIS;


% clear the previous plot
if ~isempty(VIS.plot.(plot_name))
  delete(VIS.plot.(plot_name));
  VIS.plot.(plot_name) = [];
end

% get the coordinates
n = find( [VIS.node.(parent_field_name)] > -1 );
p = [VIS.node(n).(parent_field_name)];
if real_pos
  nx = [VIS.node(n).real_x];
  ny = [VIS.node(n).real_y];
  px = [VIS.node(p).real_x];
  py = [VIS.node(p).real_y];
else 
  nx = [VIS.node(n).calc_x];
  ny = [VIS.node(n).calc_y];
  px = [VIS.node(p).calc_x];
  py = [VIS.node(p).calc_y];
end

lineOpts.LineWidth = 1;
lineOpts.Color = [50 200 50]/255;
VIS.plot.(plot_name) = newquiver(nx, ny, px, py);
set(VIS.plot.(plot_name), lineOpts);

