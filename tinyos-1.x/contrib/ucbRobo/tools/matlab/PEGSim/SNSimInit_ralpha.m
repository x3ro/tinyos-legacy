function SN = SNSimInit_ralpha(n,dimX,dimY,rt_num,ob_noise,...
                               alphaS,betaS,etaS,alphaR,betaR,etaR,nodes)
% SNSimInit_ralpha(n,dimX,dimY,rt_num,ob_noise,...
%                  alphaS,betaS,etaS,alphaR,betaR,etaR,nodes)
% Initializes/Generates Sensor Network Data Structures.
% Use testParams to find appropriate eta, beta, alpha's. 
% Last argument 'nodes' is optional.

% Sensor Model
% 1) sensors sense (x,y) position
% 2) sensor detection probability: betaS/(betaS+dist^alphaS),
%    truncated when p < etaS; betaS unique to each node
% 
% Routing/Radio Model
% 1) Mobile-to-Mobile Routing
% 2) Assumes each sensor node knows how to route to every other sensor
%    node ("ideal", not implementable)
% 3) Symmetric Links
% 4) No modeling of congestion in the sensor network.
% 5) Per Hop Probability of Transmission: betaR/(betaR+dist^alphaR),
%    truncated when p < etaR; betaR unique to each node
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

if ~(abs(etaS) <= 1) || ~(abs(etaR) <=1) % sanity check
    error('1','You''ve mixed up the arguments for SNSimInit_ralpha');
end
SN.n = n;
SN.dimX = dimX;
SN.dimY = dimY;
SN.rt_num = rt_num;
SN.ob_noise = ob_noise;
SN.etaS = etaS; % minimum probability
SN.etaR = etaR;
SN.betaS = betaS;
SN.betaR = betaR;
SN.alphaS = alphaS;
SN.alphaR = alphaR;
SN.R_s = (betaS*(1-etaS)/etaS)^(1/alphaS); %minimum sensing radius
SN.R_r = (betaR*(1-etaR)/etaR)^(1/alphaR); %minimum transmission radius
% good values for alpha,beta,eta: (2,1,0.4)

if (nargin < 12) % need to autogenerate nodes
    SN.nodes = [SN.dimX 0 ; 0 SN.dimY] * rand(2,SN.n);
    node_betaS = (betaS + rand(1,SN.n));
    node_betaR = (betaR + rand(1,SN.n));

    SN.nodes = [SN.nodes ;
                (node_betaS.*(1-etaS)/etaS).^(1/alphaS);
                (node_betaR.*(1-etaR)/etaR).^(1/alphaR);
                node_betaS;
                node_betaR];
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
        R = min(SN.nodes(4,i),SN.nodes(4,j));
        bI = SN.nodes(6,i);
        bJ = SN.nodes(6,j);
        if (d < R)
            SN.linkP(i,j) = (bI/(bI+d^SN.alphaR)+bJ/(bJ+d^SN.alphaR)) / 2;
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
disp(sprintf('Routing took %.4f time to calculate',time));

if ~isequal((SN.pathMat == 0),eye(size(SN.pathMat)))
    disp('partition exists in network');
end

% Includes routing length from each node to itself
maxL = 0;
sumL = 0;
sumL2 = 0;
for i = 1:SN.n
    for j = i:SN.n
        l = length(SN.routePath{i,j});
        maxL = max(l,maxL);
        sumL = sumL + l;
        sumL2 = sumL2 + l^2;
    end
end
num = SN.n*(SN.n+1)/2;
SN.meanL = sumL/num;
SN.stdL = sqrt(sumL2/num - (SN.meanL)^2); %E[X^2] = sumL2/num
SN.maxL = maxL;
