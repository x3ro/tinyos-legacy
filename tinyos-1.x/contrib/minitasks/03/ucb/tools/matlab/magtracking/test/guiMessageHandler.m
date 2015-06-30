function output = ws(varargin)
output = feval(varargin{:});

function void = anchor(text)
global VIS;
void = -1;
source = text.addr;
index = getNodeIdx(source);
num_anchors = text.numberOfAnchors;
for i = 1:num_anchors
    VIS.node(index).anchor(i).nodeIdx = getNodeIdx(text.anchors(i).addr);
    VIS.node(index).anchor(i).dist = text.anchors(i).dist;
end

function void = ranging(text)
global VIS;
void = -1;
source = text.addr;
index = getNodeIdx(source);
num_neighbors = text.numberOfNeighbors;
for i = 1:num_neighbors;
    VIS.node(index).neighbor(i).nodeIdx = getNodeIdx(text.neighbors(i).addr);
    VIS.node(index).neighbor(i).dist = text.neighbors(i).dist;
end

function void = ststatus(text)
global VIS;
void = -1;
source = text.routing_origin;
index = getNodeIdx(source);

if (source == VIS.landmark)
    VIS.node(index).parent = -1;
else
    VIS.node(index).parent = getNodeIdx( text.route1_parent );
end
% note that the route has been changed, so we catch it in the GUI
VIS.flag.route_tree_updated = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% calculate pursuer index, based on the agent index.  This assumes
% that all evaders are before all pursuers.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function index = getAgentIndex(agent_number)
global VIS;
index = agent_number - VIS.num_evaders;


% this is sent from the Sensor
function void = msgFromSensor(text)
global VIS
void = -1;
agent_number = text.dest;
agent_number = getAgentIndex(agent_number);
src = text.routing_origin;
dest = text.routing_address;
if VIS.crumb.agent(agent_number).status == 1
    % I am doing double buffering here, now switch to the "public readable" path
    VIS.crumb.agent(agent_number).completed_src = VIS.crumb.agent(agent_number).path_src;
    VIS.crumb.agent(agent_number).completed_dest = VIS.crumb.agent(agent_number).path_dest;
    % not until now the path is ready, so set the flag here
    VIS.flag.route_crumbs_updated = 1;
    % we need to clear the path here because we are starting a new path
    % from fresh
    VIS.crumb.agent(agent_number).path_src = [];
    VIS.crumb.agent(agent_number).path_dest = [];
end
VIS.crumb.agent(agent_number).status = 0;
VIS.crumb.agent(agent_number).path_src = [VIS.crumb.agent(agent_number).path_src src];
VIS.crumb.agent(agent_number).path_dest = [VIS.crumb.agent(agent_number).path_dest dest];


% this message is sent from base
% the path is being building up
function void = msgFromBase(text)
global VIS
void = -1;
agent_number = text.dest;
agent_number = getAgentIndex(agent_number);
src = text.routing_origin;
dest = text.routing_address;
VIS.crumb.agent(agent_number).status = 1;
VIS.crumb.agent(agent_number).path_src = [VIS.crumb.agent(agent_number).path_src src];
VIS.crumb.agent(agent_number).path_dest = [VIS.crumb.agent(agent_number).path_dest dest];
% the trail is still being built, so DON't set the flag
%VIS.flag.route_crumbs_updated = 1;



