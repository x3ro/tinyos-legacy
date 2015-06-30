function [SN, P, E] = genScen94_100x50_fixed
% Sets up a fixed sensor network with fixed pursuer and evader positions
% Meant for testing expected behaviors of new cost functions

%% SN
% 'Ring' node placement
nodes = [0    2.5    5    7.5   10   12.5 15   17.5 20;
         25   27.5   30   30    30   30   30   27.5 25];

[meshX, meshY] = meshgrid(20:4:32,17:4:35);
meshX = reshape(meshX,[1,numel(meshX)]);
meshY = reshape(meshY,[1 numel(meshY)]);
nodes = [nodes [meshX ; meshY]];

% % Autogenerate region around Evader
% genNodes = [23 0 ; 0 15] * rand(2,15);
% genNodes(1,:) = 20 + genNodes(1,:);
% genNodes(2,:) = 17 + genNodes(2,:);
% nodes = [nodes genNodes];

%Autogenerate remaining nodes
genNodes = [50 0 ; 0 50] * rand(2,70);
genNodes(1,:) = 40 + genNodes(1,:);
nodes = [nodes genNodes];

% %Test plot of node positions
% testSN.n = size(nodes,2);
% testSN.dimX = 100;
% testSN.dimY = 50;
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
        
SN = SNSimInit_ralpha(n,100,50,10,0.20,...
                      alphaS,betaS,etaS,alphaR,betaR,etaR,nodes);
%n,dimX,dimY,rt_num,ob_noise,alphaS,betaS,etaS,alphaR,betaR,etaR,nodes


%% Pursuer and Evader
[P, E] = PEInit(1,[0; 22; 0; 0],0,0,1,[20; 22; 10; 0]);

%% Pctrlr
Pctrlr = PpolicyNonLinOptInit(10,30,diag([1,1,0.1,0.1]),1,1,2,0.2,1);
%ch,ph,xWt,uWt,gWt,s_q,s_r,ctrlChoice

save examples/scen94_100x50_fixedSN SN
save examples/scen94_100x50_fixedPE P E
save examples/scen94_100x50_fixedPctrlr Pctrlr;
