function drawCrumbTrail(i)

global VIS;

if ishandle( VIS.plot.crumb(i).real_pos ) 
    delete(VIS.plot.crumb(i).real_pos);
end
if ishandle( VIS.plot.crumb(i).calc_pos ) 
    delete(VIS.plot.crumb(i).calc_pos);
end


src = VIS.crumb.agent(i).completed_src;
dest = VIS.crumb.agent(i).completed_dest;

% set options
lineOpts.LineWidth = 1;
lineOpts.Color = VIS.pursuer_colors(i,:);


% do the real position plot
nx = [VIS.node(src).real_x];
ny = [VIS.node(src).real_y];
px = [VIS.node(dest).real_x];
py = [VIS.node(dest).real_y];
VIS.plot.crumb(i).real_pos = newquiver(nx, ny, px, py);
set(VIS.plot.crumb(i).real_pos, lineOpts);


% do the calc position plot
nx = [VIS.node(src).calc_x];
ny = [VIS.node(src).calc_y];
px = [VIS.node(dest).calc_x];
py = [VIS.node(dest).calc_y];
VIS.plot.crumb(i).calc_pos = newquiver(nx, ny, px, py);
set(VIS.plot.crumb(i).calc_pos, lineOpts);




