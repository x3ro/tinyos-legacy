function treeSetUpAndStatus(power, rfThreshold, base)
global nodes;
%% these are all the nodes
%nodes = ['281'; '2a1'; '293'; '2a2'; '2a0'; '291'; '290'; '283'; '270'; '273'; '280'; '292'; '272'; '282'];

%nodes = ['220';'221';'232';'28A';'247';'238';'289';'209';'269';'208';'216';'27A';'218';'270';...
%'290';'273';'280';'291';'293';'292';'279';'2A0';'2A1';'281';'282';'2A2';'235';'210'];

nodes = ['200';'201';'202';'203';'204';'205';'206';'207'];

% nodes = [{'220'} {'221'} {'232'} {'28a'} {'247'} {'238'} {'289'} {'209'} {'269'} {'208'} {'216'} {'27a'} {'218'} {'270'} ...
% {'290'} {'273'} {'280'} {'291'} {'293'} {'292'} {'279'} {'2a0'} {'2a1'} {'281'} {'282'} {'2a2'} {'235'} {'269'} {'210'}];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% concat x into it
if ~isstr(base)
    disp('Base should be a hex string without 0x');
    return;   
end
base = concat_hex(base);%concat_hex(nodes(base_index, :));
temp_nodes = [];
for i = 1:length(nodes)
    temp_nodes = [temp_nodes; concat_hex(nodes(i, :))];    
end
nodes = temp_nodes;

%start_exp(power, base, src, recv, numMessages);
build_tree(power, rfThreshold, base, 3);
disp('Tree is built');
%pause;
%query_status(nodes);

function s = concat_hex(s)
s = ['0x' s];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function build_tree(transPower, rfThreshold, base, numTimes)
global nodes;
global RETRY;
global identSummary;
global parentarray;

identSummary=[];
parentarray=[];
RETRY=3;
%% index of the array that is the base station
%base_index = 1;
%total_packet_to_sent = 100;

% do some initialising
% reset all nodes
disp('Reset all nodes');
for i=1:RETRY
    peg all reset;
    pause(1);
end

disp('Turn on all nodes');
% Turn them on
for i=1:RETRY
    peg all on;
    pause(1);
end

disp('Get Ident for all nodes');
for i=1:length(nodes)
    cmd = ['peg ' nodes(i,:) ' ident']
    eval(cmd)
    pause(0.25);
    eval(cmd)
    pause(0.25);
end
%heardFrom = length(unique(identSummary))

disp('Turn all service 30');
% Turn on service 30
for i=1:RETRY
    peg all service(30);
    pause(1);
end

disp('Setting power setting');
% Set the power to 4
for i=1:RETRY
    %peg all rfpower(transPower);
    cmd = ['peg all rfpower(' num2str(transPower) ')']
    eval(cmd);
    pause(1);
end

disp('Setting Routing Signal Threshold');
% Set the threshold to rfThreshold
for i=1:RETRY
    %peg all rfpower(transPower);
    cmd = ['peg all rtthresh(' num2str(rfThreshold) ')']
    eval(cmd);
    pause(1);
end


% build the tree
% need a 20 second pause for each
cmd = ['peg ' base ' rtbuild']
for i=1:numTimes
    disp('Build Tree Broadcast');
    eval(cmd);
    pause(20);
end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we need to collect some statistic here
function query_status(nodes)
global RETRY;
for i = 1:length(nodes)
   current_source = nodes(i,:);
   % use antenna
   % use high power
   for j=1:RETRY
       cmd = ['peg ' current_source ' ststatus']
       eval(cmd);
       pause(1);
   end
end









