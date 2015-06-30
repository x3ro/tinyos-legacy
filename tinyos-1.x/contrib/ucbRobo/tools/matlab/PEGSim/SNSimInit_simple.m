function SN = SNSimInit_simple(n,dimX,dimY,rt_num,ob_noise,R_s,R_r,nodes)
% SNSimInit_simple(n,dimX,dimY,rt_num,ob_noise,R_s,R_r,nodes)
% Initializes/Generates Sensor Network Data Structures.
%
% Last argument 'nodes' is optional.

% Sensor Model
% 1) sensors sense (x,y) position
% 2) sensor detection probability: (R_s - dist)/R_s;
%    R_s is unique to each node
% 
% Routing/Radio Model
% 1) Mobile-to-Mobile Routing
% 2) Assumes each sensor node knows how to route to every other sensor
%    node ("ideal", not implementable)
% 3) Symmetric Links
% 4) No modeling of congestion in the sensor network.
% 5) Per Hop Probability of Transmission: (R_r - dist)/R_r; 
%    R_r is unique to each node
% 6) Number of retransmissions: SN.rt_num
% 7) End-to-End transmission probability:
%    Find path with maximum probability of transmission to the node
%    closest to the pursuer.  Then "maximize" the probability of the
%    worst hop using the number of retransmissions on the worst hop
%    (think binomial distribution).  Assume we have SN.rt_num2
%    retransmissions on the last hop.
%
% Output:
%      SN.nodes k*n column matrix
%               [x,y,R_s,R_r]' % R_r is used to compute the transmission
%                                 probability for the last hop
%      SN.linkP n*n Matrix with probabilities of successful 1-hop
%               transmission between two nodes.
%      SN.connProb n*n Matrix with probabilities of successful end-to-end
%                  transmission between two nodes.
%      SN.routePath n*n cell array of lists (cell array) of nodes in a
%                   path.  Does not include first node, includes last node.
%      SN.pathMat n*n Matrix with next hop neighbor when transmitting from
%                 node i to node j
%      SN.wtMat n*n Matrix used for calculating the routePath

global SN; % sensor network structure

SN = struct; % clean out junk from before

SN.n = n;
SN.dimX = dimX;
SN.dimY = dimY;
SN.rt_num = rt_num;
SN.ob_noise = ob_noise;
SN.R_s = R_s;
SN.R_r = R_r;

if (nargin < 8) % need to autogenerate nodes
    SN.nodes = [SN.dimX 0 ; 0 SN.dimY] * rand(2,SN.n);
    SN.nodes = [SN.nodes ;
        SN.R_s*(0.5 + 0.5*rand(1,SN.n)) ;
        SN.R_r*(0.7 + 0.3*rand(1,SN.n))];
else
    SN.nodes = nodes;
end


tic
%% Routing
% Find 1-hop probabilities
SN.linkP = zeros(SN.n);
for i = 1:SN.n
    for j = i:SN.n
        d = norm(SN.nodes(1:2,i) - SN.nodes(1:2,j));
        R = SN.nodes(4,i);
        if (d < R)
            SN.linkP(i,j) = (R-d)/R; %(d < R);
            SN.linkP(j,i) = SN.linkP(i,j);
        end
    end
end

% Use a variant of Floyd-Warshall algorithm to find most reliable paths
D = SN.linkP;
P = (D > 0) - eye(size(D));
P = diag(1:SN.n) * P;
for k = 1:SN.n
    for i = 1:SN.n
        for j = 1:SN.n
            [D(i,j), swap] = max([D(i,j) D(i,k)*D(k,j)]);
            if (swap == 2)
                P(i,j) = P(k,j);
            end % update P
        end
    end
end

SN.pathMat = P;
SN.wtMat = D;
SN.routePath = cell(SN.n);
for i = 1:SN.n
    for j = 1:SN.n
        path = [];
        k = j;
        while (k ~= 0 && P(i,k) ~= i)
            path = [P(i,k) path];
            k = P(i,k);
        end
        if (k == 0)
            path = []; % nodes are not connected
        else
            path = [path j];
        end
        SN.routePath{i,j} = path;
    end
end

% Find End-to-End routing probabilities
% This matrix will be important in Cost Function Calculations, but not
% so much for actual transmission simulation
for i = 1:SN.n
    for j = 1:SN.n
        route = SN.routePath{i,j};
        routeP = [];
        if isempty(route) && (i == j)
            SN.connProb(i,j) = 1;
        elseif isempty(route)
            SN.connProb(i,j) = 0;
        else
            routeP = [];
            for k = 1:size(route,2)-1
                routeP(end+1) = SN.linkP(route(k),route(k+1));
            end
            maxPvec = routeP;
            for k = 1:SN.rt_num % boosting minimum link
                [min_p ind] = min(maxPvec);
                maxPvec(ind) = 1-(1-routeP(ind))*(1-min_p);
            end
            SN.connProb(i,j) = prod(maxPvec);
        end
    end
end

time = toc;
disp(sprintf('Routing took %d time to calculate',time));

if ~isequal((SN.pathMat == 0),eye(size(SN.pathMat)))
    disp('partition exists in network');
end

% [x, y, alpha, beta, gamma, eta]
% node.nhbr = {p1 ... pn}
