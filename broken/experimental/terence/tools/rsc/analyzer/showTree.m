function value = showTree(varargin)
value = feval(varargin{:});


%feval(module, 'initialise');
%result = feval(module, 'fetch_data', expname);
%check_result(result);
%prepare_file;
%feval(module, 'general_info', result);
%feval(module, 'big_loop', result);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% node Pos stores the position of the nodes on the grid
% Indexed by node ID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function value=initialise()
global nodePos lineVector;
lineVector=[];
nodePos.X = [41 1 6 15 19 20 13 27 28.5 25 33 36 5.5 36.5];
nodePos.Y = [8 11 4 16 13 8 1 13 9.5 4 16 13 13 4];
value = -1;

function result=fetch_data(expname)
global expName;
expName = expname;
newMsg = StatPacket;
amtype_offset = num2str(newMsg.offset_amtype);
amtype = num2str(newMsg.AM_TYPE);
result = analyzer('fetch_data', ['select * from ' expname ' where ' ...
            'packetid = ' num2str(1) ' ; ']);
    %' and ' ...
     %       'b' amtype_offset ' = ' amtype ' ; ']);


function ret=general_info(result)
ret = 1;


function ret=big_loop(result)
global expName;

ret = 1;
%parent_list = 1:1:14;
newMsg = StatPacket;
amtype = num2str(newMsg.AM_TYPE);
startTime = analyzer('get_epoch', result(1,:));
startTime = startTime + 200;
timeElapsed = 0;
for i=1:300
    parent_list = extractParentList(expName,startTime,startTime+60,14,i);
    %drawTree(parent_list);
    startTime = startTime + 60;
    timeElapsed = timeElapsed + 60
end



% function parent_list=extractParentList(expName,startTime,endTime,numNode)
% newMsg = RouteDBMsg;
% amtype_offset = num2str(newMsg.offset_amtype);
% amtype = num2str(newMsg.AM_TYPE);
% parent_list = [1];
% for i=2:numNode
%     % Fetch data from the experiment for a particular node
%     tableName = sprintf('%s_n%s',expName, i);
%     startDateTime = analyzer('get_time_stamp', startTime);
%     endDateTime = analyzer('get_time_stamp',endTime);
%     tmp = analyzer('fetch_data', ['select * from ' tableName ' where ' ...
%             'time >= ' startDateTime ' and ' ...
%             'time <= ' endDateTime ' and ' ...
%             'b' amtype_offset ' = ' amtype ' ; ']);
%     % Create parents vector that keep track of all the parents of this node within this time
%     for j=1:size(tmp, 1)
%         raw_packet = tmp(j, :);
%         packet = analyzer('get_packet', raw_packet);
%         objMsg = RouteDBMsg(packet);
%         parents(j) = objMsg.get_parent;
%     end
%     % Determine the node that remains the parent for this node most of the time
%     % The result is stored in the majorParent
%     parents = unique(tmp(:,parent_index));
%     maxParent = 0;
%     majorParent = -1;
%     for j=1:length(parents)
%         [val, index]=find(parents(j)==tmp(parent_index,:));
%         if length(index) > maxParent
%             maxParent = length(index);
%             majorParent = parents(j);
%         end
%     end
%     % This is packet_list for all nodes in between time t and t+p
%     parent_list(i) = majorParent;
% end

function parent_list=extractParentList(expName,startTime,endTime,numNode,iter)
newMsg = StatPacket;
amtype_offset = num2str(newMsg.offset_amtype);
amtype = num2str(newMsg.AM_TYPE);

% Fetch data from the experiment for a particular node
startDateTime = analyzer('get_time_stamp', startTime);
endDateTime = analyzer('get_time_stamp',endTime);
tmp = analyzer('fetch_data', ['select b' num2str(newMsg.offset_realSource) ', b' num2str(newMsg.offset_parent) ' from ' expName ' where ' ...                    
               'time >= ''' startDateTime ''' and ' ...
               'time <= ''' endDateTime ''' and ' ...       
                'b' amtype_offset ' = ' amtype ' ; ']);        

parent_list.source=[tmp{:,1}];
parent_list.parent=[tmp{:,2}];
drawTree(parent_list);
%for i=1:size(tmp,1)
%    source = tmp{i,1};
%    parent = tmp{i,2};
%    if source ~= 1
%        parent_list(source) = parent;
%        drawTree(parent_list);
%    end
%end
        
% for i=2:numNode
%     sourceList = [tmp{:,1}];
%     parentList = [tmp{:,2}];
%     [val, index] = find(sourceList == i);
%     if isempty(index)
%         parent_list(i) = i;
%         continue;        
%     else
%         maxParent = 0;
%         majorParent = -1;
%         parents= unique(parentList(index));
%         for j=1:length(parents)
%             [val, tmp_index]=find(parents(j)==parentList(index));
%             if length(tmp_index) > maxParent
%                 maxParent = length(tmp_index);
%                 majorParent = parents(j);
%             end
%         end
%     end
%     parent_list(i) = majorParent;    
%     if mod(iter,2) == 0
%         parent_list(2) = 2;       
%     end
% end           


function value = drawTree(parent_list)
global nodePos lineVector;
numNodes = length(nodePos.X);
%parent_list
%clf;
if isempty(lineVector)
    figure;
    hold on;
    plot(nodePos.X, nodePos.Y,'bs');            
    plot(nodePos.X(1),nodePos.Y(1),'rx');
    for i=1:numNodes
        lineVector(i)=line([nodePos.X(i) nodePos.X(i)],[nodePos.Y(i) nodePos.Y(i)], 'EraseMode', 'normal', 'Color', [rand rand rand]);        
    end
else
    for i=1:length(parent_list.source)
        source=parent_list.source(i);
        if source == 1
            continue;
        end
        parent=parent_list.parent(i);
        set(lineVector(source),'XData',[nodePos.X(source) nodePos.X(parent)], 'YData',[nodePos.Y(source) nodePos.Y(parent)]);
        pause(0.1);
    end
    %for i=1:numNodes
    %    set(lineVector(i),'XData',[nodePos.X(i) nodePos.X(parent_list(i))], 'YData',[nodePos.Y(i) nodePos.Y(parent_list(i))]);
        %line([nodePos.X(i) nodePos.X(parent_list(i))],[nodePos.Y(i) nodePos.Y(parent_list(i))], 'EraseMode', 'xor');        
        %end
end
value = 1;






