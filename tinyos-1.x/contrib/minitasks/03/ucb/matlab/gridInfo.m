function gridInfo
global nodes;
global anchors;

%NODES = ['220';'221';'232';'28A';'247';'238';'289';'209';'269';'208';'216';'27A';'218';'270';...
%'290';'273';'280';'291';'293';'292';'279';'2A0';'2A1';'281';'282';'2A2';'235';'210'];
%ANCHORS = ['220'];

NODES=['02';'03';'04';'05';'06';'07';'08';'09';'0A';'0B';'0C';'0D';'0E';'0F';'10';'11'];

NODES=['02';'03';'04';'05';'06';'07';'08';'09';'0A'];
ANCHORS=['02';'04';'08';'0A'];

% Init grid parameters
gridSpacing=180;
gridCol = 3;
xDist = 0;
yDist = 0;

% Find out nodes that we are using
nodes.realID = NODES;
tmp=[];
for i = 1:length(nodes.realID)
    tmp = [tmp; concat_hex(nodes.realID(i, :))];    
end
nodes.realID = tmp;

% Find out nodes that are anchors
tmpNodes = hex2dec(NODES);
tmpAnchors = hex2dec(ANCHORS);
nodes.anchor = zeros(1,length(tmpNodes));
for i=1:length(tmpAnchors)
    [index,val]=find(tmpNodes==tmpAnchors(i));
    if ~isempty(index)
        nodes.anchor(index) = 1;            
    end
end

% Assing ranging IDs
% Assume the order of NODES vector
nodes.rangingID = 2:(length(nodes.realID)+1);

% Assign Location Information As a grid
direction = 1;
for i=1:length(nodes.realID)
    nodes.X(i) = xDist;        
    nodes.Y(i) = yDist;
    
    % Get X position
    if mod(i,gridCol) == 0
            xDist = xDist + gridSpacing; 
    end
         
    if yDist == gridSpacing * (gridCol-1)
        if direction == 1
            yDist = yDist + direction*gridSpacing;
            direction = -1;
        end
    elseif yDist == 0
        if direction == -1
            yDist = yDist + direction*gridSpacing;
            direction = 1;        
        end
    end
    
    yDist = yDist + direction * gridSpacing;
        
end
