function t = localGridSearch(t, varargin)
%xy = localGridSearch(kd, bx, xyInitialize, gridSpacing, stressCutoff)
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

kd=t.kd
bx=t.bx
npts = length(kd);
%find the xy coords of each node relative to its neighbors
for i = 1:npts
    node(i).neighbors = union(find(kd(:,i)+1), find(kd(i,:)+1));    
    node(i).kd = kd(node(i).neighbors, node(i).neighbors);
    %the following code gets rid of pivot points in the local neighborhoods
    %it is commented out now because all neighborhoods are fully connected.
    oldUniquePoints=node(i).neighbors;
    uniquePoints = find(sum(node(i).kd>0)>2);
    while length(oldUniquePoints)~=length(uniquePoints)
        node(i).neighbors = node(i).neighbors(uniquePoints);    
        node(i).kd = node(i).kd(uniquePoints, uniquePoints);
        oldUniquePoints = uniquePoints;
        uniquePoints = find(sum(node(i).kd>0)>2);
    end    
    %this if statement is for the special case of singleton nodes
    if isempty(node(i).neighbors)
        node(i).neighbors=i;
        node(i).kd=0;
    end
    node(i).xy = solver(node(i).kd, bx, varargin{:});
    node(i).overlap=0;
    node(i).transform=[];
    node(i).newxy=[];
end

for k=1:npts
    if isempty(node(k).newxy)
		node(k).newxy = node(k).xy;
        node(k).transform = [1 0; 0 1; 0 0];
		xy(k,:) = node(k).newxy(find(node(k).neighbors==k),:);
		node(k).overlap=65535;
    end
    queue = k;
	while ~isempty(queue)
        i=queue(1);
        queue = queue(2:end);
        for j = setdiff(node(i).neighbors,i)
            [neighbors, indexJ, indexI] = intersect(node(j).neighbors, node(i).neighbors);
            [notneighbors, notindexJ, notindexI] = setxor(node(j).neighbors, node(i).neighbors);
            if min(node(i).overlap, length(neighbors))>node(j).overlap
                node(j).overlap=min(node(i).overlap, length(neighbors));
                queue = [queue j];
                [newxy1, transform1, error1] = linearConformalTransform(node(j).xy(indexJ,:),node(i).newxy(indexI,:));
                xyb=[node(j).xy(indexJ,1) -node(j).xy(indexJ,2)];
                [newxy2, transform2, error2] = linearConformalTransform(xyb,node(i).newxy(indexI,:));

                %here, instead of just checking for error I also
                %choose the transform that increases distance between the
                %two sets of nodes that are not neighbors
                newxy1=[node(j).xy ones(size(node(j).xy,1),1)]*transform1;
                xyb=[node(j).xy(:,1) -node(j).xy(:,2)];
                newxy2=[xyb ones(size(node(j).xy,1),1)]*transform2;
                notneighborXY = [newxy1(notindexJ,:); node(i).xy(notindexI,:)];
                notneighborXY = notneighborXY(:,1)+1i*notneighborXY(:,2);
                [X1,X2]=meshgrid(notneighborXY); 
                totalDistance1 = sum(sum(abs(X1-X2)));
                notneighborXY = [newxy2(notindexJ,:); node(i).xy(notindexI,:)];
                notneighborXY = notneighborXY(:,1)+1i*notneighborXY(:,2);
                [X1,X2]=meshgrid(notneighborXY); 
                totalDistance2 = sum(sum(abs(X1-X2)));

                if (totalDistance2-totalDistance1) - (error2-error1)*5000 > 0
                    node(j).transform = transform2;
                    node(j).newxy = newxy2;
                else
                    node(j).transform = transform1;
                    node(j).newxy = newxy1;
                end

                xy(j,:) = node(j).newxy(find(node(j).neighbors==j),:);
            end
        end
    end
end

t.xyEstimate=xy;