function xy = createPsuedoUniformDistribution(numNodes, boundingBox, stdev)
%xy = createPsuedoUniformDistribution(numNodes, boundingBox, stdev)
%
%this function will create a uniform grid on the bounding box of this data
%set and assign each node to one grid of that box with gaussian noise.

if nargin<3 | isempty(stdev) stdev = .5; end

xy=[];
gridSize = ceil(sqrt(numNodes));
xgridWidth = (boundingBox(2)-boundingBox(1))/gridSize;
ygridWidth = (boundingBox(4)-boundingBox(3))/gridSize;
node = 1;
for x=1:gridSize
    for y=1:gridSize
        if node<=numNodes
            xy(node)= x*xgridWidth+normrnd(0,xgridWidth*stdev) + 1i*(y*ygridWidth+normrnd(0,ygridWidth*stdev));
            node=node+1;
        end
    end
end
xy=xy';
