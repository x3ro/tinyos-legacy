function initVis

% declare the global structure that will hold all of our data
global VIS;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tunable demo parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

VIS.debug = 0;

VIS.node_separation = 2;  % separation b/w nodes.  Used to scale distance measurements.

VIS.num_nodes = 9;
VIS.width = 3;
VIS.landmark = 2;
VIS.num_pursuers = 1;
VIS.num_evaders = 1;
VIS.num_agents = (VIS.num_pursuers + VIS.num_evaders);


VIS.pursuer_opts.Marker = 'd';
VIS.pursuer_opts.MarkerSize = 15;
VIS.pursuer_colors = [
 0   0   255;   % blue
 100 100 255;   % blue
 150 150 255;   % blue
]/255;


VIS.evader_opts.Marker = 'p';
VIS.evader_opts.MarkerSize = 15;
VIS.evader_colors = [
 255  50  50;   % red
 255 100 100;   % red
 255 200 100;   % yellow
 200 100 255;   % ???
]/255;
				  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set initial values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear the timer
stopVisTimer

% clear out the node lists 
VIS.nodeIdx = [];
VIS.node = [];
VIS.route.leader = -1;

% init pursuer / evader
VIS.pursuer = [];
VIS.evader = [];

% init mag tracking flags
%VIS.mag_reading_timeout=.750; % in seconds
VIS.mag_reading_timeout=4; % in seconds


for y = 0:VIS.width-1
    for x = 0:VIS.width-1

        id = 512 + x*16 + y;

        % add the node
        idx = getNodeIdx(id);
        
        % position info
        VIS.node(idx).real_x = x;
        VIS.node(idx).real_y = y;
        VIS.node(idx).calc_x = x;
        VIS.node(idx).calc_y = y;
        
        VIS.node(idx).parent = -1;
        VIS.flag.route_tree_updated = 1;
    end
end

VIS.last_route_pull = 0;
VIS.total_route_pulls = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear the figure
clf
hold on;

% make sure all plots go here...
VIS.root_figure = gcf;

%
% node positions
%
VIS.plot.real_pos = plot(0,0,'.');
set(VIS.plot.real_pos, 'MarkerSize',15)
set(VIS.plot.real_pos, 'Color',[150 150 255]/255)%[153 204 255]/255)
set(VIS.plot.real_pos, 'XData', [], 'YData', []); %clear the plot
VIS.show.real_pos = 1;

VIS.plot.calc_pos = plot(0,0,'.');
set(VIS.plot.calc_pos, 'MarkerSize',15)
set(VIS.plot.calc_pos, 'Color',[50 255 50]/255)%[153 204 255]/255)
set(VIS.plot.calc_pos, 'XData', [], 'YData', []); %clear the plot
VIS.show.calc_pos = 0;

% arrows from real to calc
VIS.plot.pos_error = quiver([1], [1], [1], [1], 0);
delete(VIS.plot.pos_error);
VIS.plot.pos_error = [];
VIS.show.pos_error = 0;

VIS.flag.nodes_updated = 1;

%
% routing tree
%
VIS.plot.real_route_tree = quiver([1], [1], [1], [1], 0);
delete(VIS.plot.real_route_tree);
VIS.plot.real_route_tree = [];

VIS.plot.calc_route_tree = quiver([1], [1], [1], [1], 0);
delete(VIS.plot.calc_route_tree);
VIS.plot.calc_route_tree = [];

VIS.show.route_tree = 1;
VIS.show.real_route = 1;   % which tree should we show?
VIS.flag.route_tree_updated = 1;


% arrows for route messages
% FIXME: add visualization of other messages?
VIS.show.route_messages = 0;
VIS.flag.route_messages_updated = 1;


% arrows for crumb trails
for i = 1:VIS.num_pursuers
  % crumb trail w/ real positions
  VIS.plot.crumb(i).real_pos = quiver([1], [1], [1], [1], 0);
  delete(VIS.plot.crumb(i).real_pos);
  VIS.plot.crumb(i).real_pos = [];

  % crumb trail w/ calculated positions
  VIS.plot.crumb(i).calc_pos = quiver([1], [1], [1], [1], 0);
  delete(VIS.plot.crumb(i).calc_pos);
  VIS.plot.crumb(i).calc_pos = [];
end

VIS.show.crumb_trails = 1;
VIS.flag.route_crumbs_updated = 1;


% node locations for mag readings
VIS.plot.mag_nodes = plot(0,0,'.');
set(VIS.plot.mag_nodes, 'MarkerSize',15)
set(VIS.plot.mag_nodes, 'Color',[255 150 150]/255)%[153 204 255]/255)
set(VIS.plot.mag_nodes, 'XData', [], 'YData', []); %clear the plot
VIS.show.mag_nodes = 1;


%
%create the plot to hold the magnetometer contour
%
[C, VIS.plot.mag_contour, cf] = contourf(zeros(sqrt(VIS.num_nodes)));
%[C, VIS.plot.mag_contour, cf] = contourf(zeros(100));
VIS.show.mag_contour = 1;
VIS.flag.mag_updated = 1;


%
% init pursuer / evader plots
%
for i = 1:VIS.num_agents

  % set up plot options
  if i <= VIS.num_evaders 
    opts = VIS.evader_opts;
    opts.Color = VIS.evader_colors(i,:);
    opts.MarkerFaceColor = VIS.evader_colors(i,:);
  else
    opts = VIS.pursuer_opts;
    opts.Color = VIS.pursuer_colors(i-VIS.num_evaders,:);
    opts.MarkerFaceColor = VIS.pursuer_colors(i-VIS.num_evaders,:);
  end  
  opts.XData = [];
  opts.YData = [];

  VIS.plot.agent(i).real_pos = plot(0,0,'.');
  set(VIS.plot.agent(i).real_pos, opts);

  VIS.plot.agent(i).calc_pos = plot(0,0,'.');
  opts.MarkerFaceColor = [0 0 0];
  set(VIS.plot.agent(i).calc_pos, opts);
end

VIS.show.calc_agent_pos = 0;
VIS.show.real_agent_pos = 1;
VIS.flag.agent_updated = 0;

for i = 1:VIS.num_agents
  VIS.agent(i).real_pos = [NaN NaN];
  VIS.agent(i).calc_pos = [NaN NaN];
  VIS.agent(i).heading = [];
end


% FIXME: show headings, also?
VIS.show.agent_heading = 1;


% localization plots
VIS.plot.ranging = plot(0,0,'-r');
set(VIS.plot.ranging, 'XData', [], 'YData', []);
VIS.show.ranging = 0;

VIS.plot.anchor = plot(0,0,'-b');
set(VIS.plot.ranging, 'XData', [], 'YData', []);
VIS.show.anchor = 0;

VIS.localization.show_anchor_idx = NaN;
VIS.localization.show_ranging_idx = NaN;
VIS.flag.ranging_updated = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% configure graphics environment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set(gcf,'DoubleBuffer', 'on');
set(gcf,'BackingStore', 'on');
set(gcf,'Renderer', 'OpenGL');
set(gcf,'Color',[0 0 0]); %make everything black
set(gca,'Color',[0 0 0]);
axis off



% query data
VIS.crumb.route_counter = 0;
for i=1:VIS.num_pursuers
  VIS.crumb.agent(i).status = 1;
  VIS.crumb.agent(i).path_src = [];
 VIS.crumb.agent(i).path_dest = [];

end


VIS.prev_draw = 0;

