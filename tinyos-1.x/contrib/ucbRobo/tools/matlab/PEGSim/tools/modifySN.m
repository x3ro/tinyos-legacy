function SN = modifySN(SN)
% Assumes you have modified one or more of the parameters:
% rt_num,alphaS,betaS,etaS,alphaR,betaR,etaR on SN.
% Doesn't move physical position of nodes, but recomputes the routing
% characteristics from changing these parameters.

%% nodes initialization for SNSimInit_simple
%nodes = [nodes;
%   	    R_s*ones(1,n);
%           R_r*ones(1,n)];
%SN = SNSimInit_simple(21,25,25,15,0.20,2.5,4,nodes);

disp('Assumes that we are using an SN generated from SNSimInit_ralpha');
%% nodes initialization for SNSimInit_ralpha
node_betaS = (SN.betaS*ones(1,SN.n));
node_betaR = (SN.betaR*ones(1,SN.n));
nodes = [SN.nodes(1:2,:) ;
        (node_betaS.*(1-SN.etaS)/SN.etaS).^(1/SN.alphaS);
        (node_betaR.*(1-SN.etaR)/SN.etaR).^(1/SN.alphaR);
        node_betaS;
        node_betaR];

SN = SNSimInit_ralpha(SN.n,SN.dimX,SN.dimY,SN.rt_num,SN.ob_noise,...
                      SN.alphaS,SN.betaS,SN.etaS,SN.alphaR,SN.betaR,SN.etaR,...
                      nodes);
%n,dimX,dimY,rt_num,ob_noise,alphaS,betaS,etaS,alphaR,betaR,etaR,nodes
