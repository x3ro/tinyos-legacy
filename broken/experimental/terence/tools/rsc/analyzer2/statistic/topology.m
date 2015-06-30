function output = topology(varargin)
output = feval(varargin{:});

function output = init
global rsc

parent_bytes = statistic('byte_offset', 'parent');
orig_bytes = statistic('byte_offset', 'realSource');
amtype_bytes = statistic('byte_offset', 'amtype');
tablename = rsc.tablename;
type_filter = statistic('type_filter');

query = ['select ' parent_bytes ' from ' tablename ', (select ' orig_bytes ... 
	 ', max(packetid) as packetid from ' tablename ' where ' type_filter ...
	 ' group by ' orig_bytes ') as pidtable where ' tablename ...
	 '.packetid = pidtable.packetid and ' type_filter ';'];

%% select b12 from test, (select b31, max(packetid) as packetid
%% from test where b2 = 102 group by b31) as pidtable where test.packetid = pidtable.packetid
%% and b2 = 102;

rsc.parent = core('fetch_data', query);
output = -1;


function output = caption
global rsc
core('html_print', ['<p><b>Network Topology</b>']); core('print_br');;
output = -1;

function pic_name = graph
global rsc
draw_topology(rsc.nodesID, rsc.parent, rsc.coor, rsc.basestationID);
pic_name = 'topology';




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% hold on;
% %% first of all i need to draw the node
% plot(rsc.coor(:, 1), rsc.coor(:, 2), 'r.');
% %% special treatment to basestation
% basestation_index = find(rsc.nodesID == rsc.basestationID);
% plot(rsc.coor(basestation_index, 1), rsc.coor(basestation_index, 2), 'k.');
% %% then i draw the line between them
% for i = 1:length(rsc.nodesID)
%     if rsc.nodesID(i) == rsc.basestationID
%        continue;
%    else
%         parent_id = rsc.parent(i);
%         parent_index = find(rsc.nodesID == parent_id);
%         parent_x = rsc.coor(parent_index, 1);
%         parent_y = rsc.coor(parent_index, 2);
%         node_x = rsc.coor(i, 1);
%         node_y = rsc.coor(i, 2);
%         
%         vector_x = parent_x - node_x;
%         vector_y = parent_y - node_y;
%         quiver(node_x, node_y, vector_x, vector_y, 's'); %, 'Color', [rand rand rand]);
%         
%         % line([parent_x node_x], [parent_y node_y], 'Color', [rand rand rand]);
%     end
% end
% pic_name = 'topology';
% axis([min(rsc.coor(:, 1)) max(rsc.coor(:, 1)) min(rsc.coor(:, 2)) max(rsc.coor(:, 2))]);
% 
