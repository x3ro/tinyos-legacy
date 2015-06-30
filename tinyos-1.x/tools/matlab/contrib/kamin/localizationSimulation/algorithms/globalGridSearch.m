function t = globalGridSearch(t, xyInitialize, gridSpacing, stressCutoff)
%xy = globalGridSearch(t, xyInitialize, gridSpacing, stressCutoff)
%this function imposes a grid on the bounding box and finds the position on
%the grid that minimizes stress for all nodes.  It returns that position
%for each node.
%
%kd - trueDistance matrix: n x n matrix where n is the number of nodes
%bx - bounding box: [xmin xmax ymin ymax]
%xyInitialize - initial positions for the nodes (optional arg): n x 2
%vector where first column is x coord and second column is y coord
%gridSpacing - the number of cells along the side of the grid (e.g 0.1=>10
%cells)
%stressCutoff - a universally acceptable stress level, e.g. 1

kd = t.kd;
bx = t.bx;
npts = length(kd);
topRightCorner=t.bx(2)+1i*t.bx(4); %use imaginary numbers

%first, initialize the xy vector
xy=zeros(1,npts);

%include the anchorNode positions
anchors = vectorFind(t.anchorNodes, t.nodeIDs);
xy(anchors) = t.xy(anchors,1)+t.xy(anchors,2)*1i;

%initialize all other nodes to the center of box or anchor nodes
mobileNodes = vectorFind(setDiff(t.nodeIDs, t.anchorNodes), t.nodeIDs);
if isempty(t.xyEstimate)
    randxy = rand(size(t.xy));
    if length(t.anchorNodes)>2
        bounds = [min(t.xy(anchors,1)) max(t.xy(anchors,1)) min(t.xy(anchors,2)) max(t.xy(anchors,2))];
        xy(mobileNodes) = randxy(mobileNodes,1)*(bounds(2)-bounds(1))+bounds(1) +1i*randxy(mobileNodes,2)*(bounds(4)-bounds(3))+bounds(3);
%        centerPoint=sum(xy)/length(t.anchorNodes);
    else
        xy(mobileNodes) = randxy(mobileNodes,1)*(bx(2)-bx(1))+bx(1) +1i*randxy(mobileNodes,2)*(bx(4)-bx(3))+bx(3);
%        centerPoint=topRightCorner/2;
    end
%    xy(mobileNodes)=xy(mobileNodes)+centerPoint; %initialize all positions to the centerpoint
else
    xy(mobileNodes) = t.xyEstimate(mobileNodes,1)+t.xyEstimate(mobileNodes,2)*1i; %or initialize to user option
end

%then create a grid over the bounding box
if nargin<3 | isempty(gridSpacing) gridSpacing=0.05;  end
gridSpacing=gridSpacing*max(bx(2)-bx(1),bx(4)-bx(3));
x=bx(1):gridSpacing:bx(2);
y=bx(3):gridSpacing:bx(4);
[xx,yy] = ndgrid(x,1i*y);
[gridXLength,gridYLength]=size(xx);
gridXOnes=ones(1,gridXLength);
gridYOnes=ones(1,gridYLength);
gridPositions=xx(:)+yy(:);
numGridPositions=length(gridPositions);
gridSizeOnes=ones(numGridPositions,1);
gridSizeZeros=zeros(numGridPositions,1);

%make sure none of the true distances are bigger than the diagonal distance
diagonalDistance=abs(topRightCorner);
kd(find(kd>diagonalDistance))=diagonalDistance;

%intialize a few other variables
validDistances=(kd-eye(npts))>=0;
validDistances = double(validDistances);
if nargin<4 | isempty(stressCutoff) stressCutoff=1; end
nptsOnes=ones(1,npts);
oldStressValue = 1.0e30;

%sort the columns by those that have the largest values and reorder all the
%matrices to this order
[dummy,newNodeOrder]=sort(-max(kd));
validDistances=validDistances(newNodeOrder,newNodeOrder);
kd=kd(newNodeOrder,newNodeOrder);
xy=xy(newNodeOrder);
[v,oldNodeOrder]=sort(newNodeOrder); %and remember what the old order was

%Now, the algorithm starts.  Do the following global search ten times
for iter=1:20
    %This loop places each node into the position on the grid that most
    %closely matches the distances to all the other nodes (using their
    %currently hypothesized positions on the grid)
    for index = 1:npts
        I = find(validDistances(:,index)); 
        if ~isempty(I) & ~any(t.nodeIDs(newNodeOrder(index))==t.anchorNodes)
            %%rewritten 1 
            st = sum(abs(abs(gridPositions(:,ones(size(I)))-xy(gridSizeOnes,I))-kd(gridSizeZeros+index,I)),2);
            %%k1 = abs(gridPositions(:,ones(size(I)))-xy(gridSizeOnes,I); %row j col k = diff between position j on the grid and hypothesized position of node k
            %%k2 = abs(k1-kd(gridSizeZeros+index,I)); %smallness of each row indicates how similar pos j is to pos of "index" node
            %%st = sum(k2,2);
            %%rewritten 1 
            [null,minloc] = min(st);
            xy(index) = gridPositions(minloc);
        end
    end
    
    %now find the current stress and quit if it is acceptable or if we
    %plateued in our search
    stress=findGlobalAbsoluteStress(xy,kd,validDistances);
    if((abs(stress-oldStressValue)/(stress+1)) < 0.002) | stress < stressCutoff
% 		%create a newgrid over the bounding box
%         bx = [min(real(xy))*.75 max(real(xy))*1.5 min(imag(xy))*.75 max(imag(xy))*1.5];
% 		if nargin<3 | isempty(gridSpacing) gridSpacing=0.1;  end
% 		gridSpacing=gridSpacing*max(bx(2)-bx(1),bx(4)-bx(3));
% 		x=bx(1):gridSpacing:bx(2);
% 		y=bx(3):gridSpacing:bx(4);
% 		[xx,yy] = ndgrid(x,1i*y);
% 		[gridXLength,gridYLength]=size(xx);
% 		gridXOnes=ones(1,gridXLength);
% 		gridYOnes=ones(1,gridYLength);
% 		gridPositions=xx(:)+yy(:);
% 		numGridPositions=length(gridPositions);
% 		gridSizeOnes=ones(numGridPositions,1);
% 		gridSizeZeros=zeros(numGridPositions,1);
        disp(['GlobalGridSearch exited with ' num2str(iter) 'iterations.'])
        break
    end
    oldStressValue = stress;
end
xy=xy.';
xy=xy(oldNodeOrder,:);
t.xyEstimate=[real(xy) imag(xy)];
% kd=kd(oldNodeOrder,oldNodeOrder);
% validDistances=validDistances(oldNodeOrder,oldNodeOrder);

