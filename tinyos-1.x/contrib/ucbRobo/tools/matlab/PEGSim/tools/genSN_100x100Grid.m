function [SN, P, E] = genSN_100x100Grid
% Sets up a grid of sensors
% Meant for testing expected behaviors of new cost functions

%% SN

[meshX, meshY] = meshgrid(4:4:64,4:4:64);
meshX = reshape(meshX,[1,numel(meshX)]);
meshY = reshape(meshY,[1 numel(meshY)]);
nodes = [meshX ; meshY];

% %Test plot of node positions
% testSN.n = size(nodes,2);
% testSN.dimX = 68;
% testSN.dimY = 68;
% nodes = [nodes ; [5 0; 0 5] * ones(2,testSN.n)];
% testSN.nodes = nodes;
% plotExSN(testSN);

%nodes initialization for SNSimInit_ralpha
n = size(nodes,2);
alphaS = 2;
betaS = 100;
etaS = 0.8;
alphaR = 2;
betaR = 25;
etaR = 0.5;
node_betaS = (betaS*ones(1,n));
node_betaR = (betaR*ones(1,n));
nodes = [nodes ;
        (node_betaS.*(1-etaS)/etaS).^(1/alphaS);
        (node_betaR.*(1-etaR)/etaR).^(1/alphaR);
        node_betaS;
        node_betaR];
        
SN = SNSimInit_ralpha(n,68,68,10,0.20,...
                      alphaS,betaS,etaS,alphaR,betaR,etaR,nodes);
%n,dimX,dimY,rt_num,ob_noise,alphaS,betaS,etaS,alphaR,betaR,etaR,nodes


save examples/nodes256_100x100_grid SN

