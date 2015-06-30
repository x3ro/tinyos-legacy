function t = generateTestSuite(numCases, minNumNodes, maxNumNodes, numAnchorNodes, percentConnected, boundingBox, connectivityRange, enforceStable, minimumStable, enforceConvex, enforceConvexHull, enforcedAverageDegree, psuedoUniform, enforceConnected, maxDistance, averageDegreeRange, gridNoise)
%
%randomly generates some test localization problems, which might look like this:
% t = 
% 
%                     xy: [49x2 double]
%         distanceMatrix: [49x49 double]
%     connectivityMatrix: [49x49 logical]
%                     kd: [49x49 double]
%                     bx: [0 20 0 20]
%                nodeIDs: [1x49 double]
%            anchorNodes: [1 7 48 43]
%             xyEstimate: []
%
% Where the fields are as follows:
% xy are the [x y] positions of the nodes
% distanceMatrix are the exact distances between each node
% connectivityMatrix indicates whether nodes i and j are connected to each other
% kd are the noisy, observed distances between each pair of nodes ( -1 if no distance esitmate)
% bx indicate the [xmin xmax ymin ymax] of the network
% nodeIDs are the node ids
% anchor nodes are the node ids of the anchor nodes
% xyEstimate holds the estimated position of the nodes given only the noisy distances in kd
% 
%parameters are (in order):
%
%numCases: the number of test suites that will be generated with the given parameters
%minNumNodes
%maxNumNodes
%numAnchorNodes
%percentConnected: this sets each pair of nodes within range to be connected with some probability
%boundingBox: [xmin xmax ymin ymax] is the bounding box within which all nodes with have positions
%connectivityRange: this will remove all edges larger than a percent of the largest edge
%enforceStable: (very strong!! use with caution) A graph is stable if every subset of nodes S in the graph is connected to S-bar with at least 3 non-colinear points
%minimumStable: minstable takes away as many edges as possible from the connectivity graph (starting from largest edges first) such that the graph is still stable 
%enforceConvex: enforces that the network is convex (not implemented)
%enforceConvexHull: enforces that the anchor nodes form a convex hull enclosing all other nodes
%enforcedAverageDegree: removes edges until the desired degree is achieved
%psuedoUniform: psuedoUniform means every node is a point on a grid with noise
%enforceConnected: ensures that there is a path from every node to every other node
%maxDistance: the maximum distance that two nodes can be and still be connected (unless this conflicts with requirements for average degree
%averageDegreeRange: instead of removing edges until the desired degree is achieved, this option simply rejects topologies that do not have an average degree within range
%gridNoise: some number between 0 and 1 that represents the noise on the grid (relative to the spacing of the grid)

if nargin<1 | isempty(numCases) numCases=10; end
if nargin<2 | isempty(minNumNodes) minNumNodes=4; end
if nargin<3 | isempty(maxNumNodes) maxNumNodes=20; end
if nargin<4 | isempty(numAnchorNodes) numAnchorNodes=[]; end %this enforces an exact number of anchor nodes.  If convex hull is enforced, the convex hull nodes are first chosen as anchor nodes, then, random nodes are added or removed to make the correct number in total.
if nargin<5 | isempty(percentConnected) percentConnected=1.00; end %this sets each pair of nodes to be connected with some probability
if nargin<6 | isempty(boundingBox) boundingBox=[0 1 0 1]; end %this is the size of the network [xmin xmax ymin ymax]
if nargin<7 | isempty(connectivityRange) connectivityRange=1; end %
if nargin<8 | isempty(enforceStable) enforceStable=0; end % (very strong!! use with caution) A graph is stable if every subset of nodes S in the graph is connected to S-bar with at least 3 non-colinear points
if nargin<9 | isempty(minimumStable) minimumStable=0; end %minstable takes away as many edges as possible from the connectivity graph (starting from largest edges first) such that the graph is still stable 
if nargin<10 | isempty(enforceConvex) enforceConvex=0; end %enforces that the network is convex (not implemented)
if nargin<11 | isempty(enforceConvexHull) enforceConvexHull=0; end %enforces that the anchor nodes form a convex hull enclosing all other nodes
if nargin<12 | isempty(enforcedAverageDegree) enforcedAverageDegree=maxNumNodes; end %removes edges until the desired degree is achieved
if nargin<13 | isempty(psuedoUniform) psuedoUniform=1; end %psuedoUniform means every node is a point on a grid with noise
if nargin<14 | isempty(enforceConnected) enforceConnected=1; end
if nargin<16 | isempty(averageDegreeRange) averageDegreeRange = [0 maxNumNodes]; end
if nargin<17 | isempty(gridNoise) gridNoise = .5; end %some number between 0 and 1 that represents the noise on the grid (relative to the spacing of the grid)

i=1;
while i <= numCases
	numNodes = ceil(rand*(maxNumNodes-minNumNodes))+minNumNodes;
    if psuedoUniform>0 %psuedoUniform means every node is a point on a grid with noise
        t(i).xy= createPsuedoUniformDistribution(numNodes, boundingBox, gridNoise);
    else %else completely uniform
    	t(i).xy = (rand(numNodes,1)*(boundingBox(2)-boundingBox(1)) +boundingBox(1)) + (rand(numNodes,1)*(boundingBox(4)-boundingBox(3))+ boundingBox(3))*1i;
    end
    [X1,X2]=meshgrid(t(i).xy); 
    t(i).distanceMatrix = abs(X1-X2);    
    kd = t(i).distanceMatrix;            %kd is the distances, but can be reduced to a subset if we want the minimum stable connected graph
    if minimumStable     %if we want the minimum stable connected graph, keep removing connections (largest first) until the graph is just barely stable)
        [r,c]=size(kd);
        kdValues = kd(:);
        [kdValues,oldOrder]=sort(-kdValues);
        kdValues = -kdValues;
        for j=1:length(kdValues)
            [row,col] = ind2sub([r c], oldOrder(j));
            if(row~=col)
                tempkd = kd;
                tempkd(row,col)=-1;
                tempkd(col,row)=-1;
		%        if sum((kd(:,col)+1)>0)>4 & sum((kd(:,row)+1)>0)>4
                if isStable(tempkd)
                    kd = tempkd;
                end
            end
        end
    end
    %set the connectivity matrix according to the percentConnected
    %parameter (but account for those edges removed to make it minamally stable)
    t(i).connectivityMatrix = rand(size(t(i).distanceMatrix))<percentConnected & kd~=-1;
    %now, update the connectivity matrix to account for the maxDistance (if
    %was passed and connectivityRange (if it was passed)
    if nargin<15 | isempty(maxDistance) maxDistance=max(max(kd)); end
    %make sure that the degree of the network satisfies the averageDegreeRange
    if findAverageDegree(t(i)) > averageDegreeRange(2) | findAverageDegree(t(i)) < averageDegreeRange(1) 
        continue
    end
    %now enforce the enforcedAverageDegree
    t(i).connectivityMatrix = t(i).connectivityMatrix & t(i).distanceMatrix<maxDistance*connectivityRange;
    while findAverageDegree(t(i))>enforcedAverageDegree
        connectivityRange = connectivityRange-.01;
        t(i).connectivityMatrix = t(i).connectivityMatrix & t(i).distanceMatrix<maxDistance*connectivityRange;
    end
    %kd is the variable that holds the true distances between the connected nodes
    t(i).kd = -ones(size(t(i).distanceMatrix));
    t(i).kd(t(i).connectivityMatrix) = t(i).distanceMatrix(t(i).connectivityMatrix);
    
    %make sure the network is connected if requested
    tempkd = t(i).kd;
    tempkd(tempkd==-1) = zeros(1,sum(sum(logical(tempkd==-1))));
    sp = dijkstra(tempkd);
    if enforceConnected & any(sp(2:end)==0)
        continue
    end
    
    %put the locations on the nodes within a bounding box
    t(i).bx = boundingBox;
    t(i).xy=[real(t(i).xy) imag(t(i).xy)];
    
    %enforce that the network is "stable" if requested
    if enforceStable & ~isStable(t(i).kd)
        continue
    end 
%     if enforceConvex & ~isConvex(t(i).kd)
%         i=i-1;
%         continue
%     end 

    t(i).nodeIDs = 1:size(t(i).xy,1);

    %assign anchor nodes: if they should be on a convex hull, choose the
    %entire convex hull by using a grahamScan.  Then, add randomly
    %to get the desired number.  If there are too many, remove those that
    %are closest to the other anchor nodes first.
    t(i).anchorNodes = [];
    if enforceConvexHull
        t(i).anchorNodes = t(i).nodeIDs(grahamScan(t(i).xy));
    end
    while length(t(i).anchorNodes) < numAnchorNodes
        t(i).anchorNodes=union(t(i).anchorNodes,ceil(rand*numNodes));
    end
    while ~isempty(numAnchorNodes) & length(t(i).anchorNodes) > numAnchorNodes
        anchorIndices = vectorFind(t(i).anchorNodes, t(i).nodeIDs);
        distances = t(i).distanceMatrix(anchorIndices, anchorIndices);
        [row,col]=find( distances == min(min(distances(distances>0))) );
        minRow=1 ;
        minmm=sum(sum(distances));
        for p=row'
            if sum(distances(p,:)) < minmm
                minmm = sum(distances(p,:));
                minRow=p;
            end
        end
        [sortedAnchors, oldAnchorOrder] = sort(t(i).anchorNodes);
        t(i).anchorNodes(oldAnchorOrder(minRow))=[];
    end              
%         a = randperm(length(t(i).anchorNodes));
%         [dummy, indices] = sort(a);
%         t(i).anchorNodes = t(i).anchorNodes(indices(1:numAnchorNodes));
%     end
    t(i).xyEstimate=[];
    i=i+1;
end
