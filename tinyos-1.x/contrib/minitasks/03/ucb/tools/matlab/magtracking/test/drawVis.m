function drawVis
%
% Draw the visualization.  This is called periodically by the timer
% function.  The set of elements to draw depends on global
% variables, set by the GUI.
%

global VIS;

% make sure we always target the right figure.  
if ishandle( VIS.root_figure )
    set(0,'CurrentFigure',VIS.root_figure);
else
    disp('Visualization window closed --- visualization tool halted');
    stopVisTimer;
    return;
end

% horrible kludge, to make sure the screen is redrawn if it has been
% obscured by another window.  Very silly.  ;-/
foo = plot(-1.2, -1.2, 'k');
delete(foo);

% timing info, for debugging
t = cputime;
timediff = t - VIS.prev_draw;
VIS.prev_draw = t;
tic


% refresh the route data.  try every 4 seconds
% poll for new data from the mote network

if 0 & VIS.last_route_pull + 4 < cputime
    VIS.last_route_pull = cputime;
    VIS.total_route_pulls = VIS.total_route_pulls + 1;

    if VIS.total_route_pulls < 4
        peg all ststatus
    else
        n = find( [VIS.node.parent] == -1 );
        %if length(n) < VIS.num_nodes - sqrt(VIS.num_nodes) + 2
        if length(n) < VIS.num_nodes - 1  % the landmark node's parent is always == -1
            r = ceil( rand(1) * length(n) );
            peg( VIS.node(n(r)).id, 'ststatus');
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate some dummy data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dummyData;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine which plots need to be recomputed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% recalculate the node plots if the node list has changed
if VIS.flag.nodes_updated > 0
  VIS.flag.nodes_updated = 0;

  % get coordinates
  rx = [VIS.node.real_x];
  ry = [VIS.node.real_y];
  cx = [VIS.node.calc_x];
  cy = [VIS.node.calc_y];

  % adjust the graph bounds, just in case
  axis([-1 (max(rx)+1) -1 (max(ry)+1)])
  
  % update point plots
  set(VIS.plot.real_pos, 'XData', rx, 'YData', ry);
  set(VIS.plot.calc_pos, 'XData', cx, 'YData', cy);

  % update the error plot
  VIS.plot.pos_error = quiver(rx, ry, (cx-rx), (cy-ry), 0);
  opts.LineWidth = 1;
  opts.Color = [50 200 50]/255;
  set(VIS.plot.pos_error(:), opts);

end

% update the routing tree
if VIS.flag.route_tree_updated & VIS.show.route_tree
  VIS.flag.route_tree_updated = 0;
  drawTree('real_route_tree', 'parent', 1);
  drawTree('calc_route_tree', 'parent', 0);
end

% update the crumb trail graphs
if VIS.show.crumb_trails & VIS.flag.route_crumbs_updated
  VIS.flag.route_crumbs_updated = 0;
  for i = 1:VIS.num_pursuers
    drawCrumbTrail(i);
  end
end

% update the routing message graph
%if VIS.flag.route_messages_updated & VIS.show.route_messages
%  VIS.flag.route_messages_updated = 0;
%  drawTree('message_tree', 'message_parent', VIS.show.real_route);
%end


% update the mag data plot.
if VIS.flag.mag_updated & (VIS.show.mag_contour | VIS.show.mag_nodes)
  % clear the contour plot
  if isfield(VIS.plot, 'mag_contour') & ~isempty(VIS.plot.mag_contour)
    delete(VIS.plot.mag_contour);
  end
  VIS.plot.mag_contour = [];

  % pick the data that hasn't timed out yet
  found = find( [VIS.node(:).mag_time] > cputime - VIS.mag_reading_timeout );

  % get X & Y coordinates
  x = [VIS.node(found).real_x];
  y = [VIS.node(found).real_y];
  

  % update the node plot
  set(VIS.plot.mag_nodes, 'XData', x, 'YData', y);

  % turn off checking if there is no new data left 
  if isempty(found)
    VIS.flag.mag_updated = 0;

  % update the contour plot
  else 
    side = ceil(sqrt(length(VIS.node)));
    z = zeros(side + 2);
    for i = 1:length(found)
      z(y(i)+2, x(i)+2) = VIS.node( found(i) ).mag_reading;
    end

    % NOTE: the contour plot is pretty slow:
    %   .2s for a 12x12 matrix with 20 colors.  
    %   .1s for a 12x12 matrix with 10 colors.  
    %tic    
    [C, VIS.plot.mag_contour, cf] = contourf([-1:side], [-1:side], z, 8);
    set(VIS.plot.mag_contour, 'EdgeColor', 'none');  %make it look nice
    %disp(toc);

    % set the color map
    if ~isfield(VIS, 'cmap')
      VIS.cmap = copper;
      VIS.cmap = VIS.cmap([1 22:end],:);
    end
    colormap(VIS.cmap);
  end

end


% agent positions

if VIS.flag.agent_updated & (VIS.show.real_agent_pos | VIS.show.calc_agent_pos)
    VIS.flag.agent_updated = 0;
    for i=1:VIS.num_agents
        pos = VIS.agent(i).real_pos;
        set(VIS.plot.agent(i).real_pos, 'XData', pos(1), 'YData', pos(2));
        
        pos = VIS.agent(i).calc_pos;
        set(VIS.plot.agent(i).calc_pos, 'XData', pos(1), 'YData', pos(2));
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% turn parts of the display on and off, as specified by the GUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% real node positions
if VIS.show.real_pos
  set(VIS.plot.real_pos, 'Visible', 'on');
else
  set(VIS.plot.real_pos, 'Visible', 'off');
end

% calculated node positions 
if VIS.show.calc_pos
  set(VIS.plot.calc_pos, 'Visible', 'on');
else
  set(VIS.plot.calc_pos, 'Visible', 'off');
end


% error arrows for position
if VIS.show.pos_error
  set(VIS.plot.pos_error, 'Visible', 'on');
else
  set(VIS.plot.pos_error, 'Visible', 'off');
end


% routing tree
if VIS.show.route_tree
  if VIS.show.real_route
    set(VIS.plot.real_route_tree, 'Visible', 'on');
    set(VIS.plot.calc_route_tree, 'Visible', 'off');
  else
    set(VIS.plot.real_route_tree, 'Visible', 'off');
    set(VIS.plot.calc_route_tree, 'Visible', 'on');
  end
else
  set(VIS.plot.real_route_tree, 'Visible', 'off');
  set(VIS.plot.calc_route_tree, 'Visible', 'off');
end


% crumb trail
if VIS.show.crumb_trails
  for i = 1:VIS.num_pursuers
    if VIS.show.real_route
      set(VIS.plot.crumb(i).real_pos, 'Visible', 'on');
      set(VIS.plot.crumb(i).calc_pos, 'Visible', 'off');
    else
      set(VIS.plot.crumb(i).real_pos, 'Visible', 'off');
      set(VIS.plot.crumb(i).calc_pos, 'Visible', 'on');
    end
  end
else
  for i = 1:VIS.num_pursuers
    set(VIS.plot.crumb(i).real_pos, 'Visible', 'off');
    set(VIS.plot.crumb(i).calc_pos, 'Visible', 'off');
  end
end




% mag contour stuff
if VIS.show.mag_nodes
  set(VIS.plot.mag_nodes, 'Visible', 'on');
else
  set(VIS.plot.mag_nodes, 'Visible', 'off');
end

if VIS.show.mag_contour
  set(VIS.plot.mag_contour, 'Visible', 'on');
else
  set(VIS.plot.mag_contour, 'Visible', 'off');
end



% agents
for i = 1:VIS.num_agents

  if VIS.show.real_agent_pos
    set(VIS.plot.agent(i).real_pos, 'Visible', 'on');
  else
    set(VIS.plot.agent(i).real_pos, 'Visible', 'off');
  end

  if VIS.show.calc_agent_pos
    set(VIS.plot.agent(i).calc_pos, 'Visible', 'on');
  else
    set(VIS.plot.agent(i).calc_pos, 'Visible', 'off');
  end

end


% localization
if VIS.show.ranging
    set(VIS.plot.ranging, 'Visible', 'on');
else
    set(VIS.plot.ranging, 'Visible', 'off');
end
    
if VIS.show.anchor
    set(VIS.plot.anchor, 'Visible', 'on');
else
    set(VIS.plot.anchor, 'Visible', 'off');
end



% print some timings, for debugging.

val = toc;
if val > 0
   %disp([timediff val]);
end

