function [SN, P, E] = genScen21_25x25_fixed
% Sets up a fixed sensor network with fixed pursuer and evader positions
% Meant for testing expected behaviors of new cost functions

n = 21;
nodes = [5    5    5    5    5    5    5    5;
            2.5  5    7.5  10   12.5 15   17.5 20];
nodes = [nodes [
            7.5  10   12.5 15   17.5 20; 
            20   20   20   20   20   20]];
nodes = [nodes [
            17.5 20   22.5 22.5 22.5 20   17.5;
            17.5 17.5 17.5 20   22.5 22.5 22.5]];

%% nodes initialization for SNSimInit_simple
%nodes = [nodes;
%   	    R_s*ones(1,n);
%           R_r*ones(1,n)];
%SN = SNSimInit_simple(21,25,25,15,0.20,2.5,4,nodes);

%% nodes initialization for SNSimInit_ralpha
alphaS = 2;
betaS = 20;
etaS = 0.8;
alphaR = 2;
betaR = 30;
etaR = 0.6;
node_betaS = (betaS*ones(1,n));
node_betaR = (betaR*ones(1,n));
nodes = [nodes ;
        (node_betaS.*(1-etaS)/etaS).^(1/alphaS);
        (node_betaR.*(1-etaR)/etaR).^(1/alphaR);
        node_betaS;
        node_betaR];

SN = SNSimInit_ralpha(n,25,25,10,0.20,...
                      alphaS,betaS,etaS,alphaR,betaR,etaR,nodes);
%n,dimX,dimY,rt_num,ob_noise,alphaS,betaS,etaS,alphaR,betaR,etaR,nodes

%% Pursuer and Evader
P.n = 1;
P.pos = [5; 0; 0; 0];
P.control = zeros(2,1);
P.meas_std = 0;
P.act_std = 0;
E.n = 1;
E.pos = [20; 20; 0; 0];


save examples/scen21_25x25_fixedSN SN
save examples/scen21_25x25_fixedPE P E
