function [SN, P, E] = genSNTestScenario
% Sets up a fixed sensor network
% Meant for testing the Sensor Network Simulator SNSim_ralpha

n = 7;
nodes = [5    5    9   5    9    13   40;
         5    20   20  35   35   35   5];

% %% nodes initialization for SNSimInit_simple
% % Probability decay curve is too rapid to always get expected values... 
% % the tests were not meant for the simple sensor network
% R_s = 5;
% R_r = 5;
% nodes = [nodes;
%   	     R_s*ones(1,n);
%          R_r*ones(1,n)];
% % Make node 7 test different sensing and transmission radius
% nodes(3,7) = 2.5;
% 
% SN = SNSimInit_simple(n,50,50,5,0.20,R_s,R_r,nodes);
% %n,dimX,dimY,rt_num,ob_noise,R_s,R_r,nodes



%% nodes initialization for SNSimInit_ralpha
alphaS = 2;
betaS = 2475;
etaS = 0.99;
alphaR = 2;
betaR = 2475;
etaR = 0.99;
node_betaS = (betaS*ones(1,n));
node_betaR = (betaR*ones(1,n));
nodes = [nodes ;
        (node_betaS.*(1-etaS)/etaS).^(1/alphaS);
        (node_betaR.*(1-etaR)/etaR).^(1/alphaR);
        node_betaS;
        node_betaR];
% Make node 7 test different sensing and transmission radius
alphaS2 = 2;
betaS2 = 625;
etaS2 = 0.99;
nodes(3,7) = (betaS2.*(1-etaS2)/etaS2).^(1/alphaS2);
nodes(5,7) = betaS2;
    
SN = SNSimInit_ralpha(n,50,50,5,0.20,...
                      alphaS,betaS,etaS,alphaR,betaR,etaR,nodes);
%n,dimX,dimY,rt_num,ob_noise,alphaS,betaS,etaS,alphaR,betaR,etaR,nodes
 

save examples/SNtest_SN SN



%% Pursuer and Evader
%Scenario I: 0 node, Pursuer Not Connected, Evader Not Sensed
[P, E] = PEInit(1,[20; 5; 0; 0],0,0,1,[20; 5; 0; 0]);
         %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
expected = '';
save examples/SNtest_PE1 P E expected

%Scenario II: one node, Pursuer Connected, Evader Not Sensed
[P, E] = PEInit(1,[4; 5; 0; 0],0,0,1,[20; 5; 0; 0]);
         %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
expected = '';
save examples/SNtest_PE2 P E expected
         
%Scenario III: one node, Pursuer Not Connected, Evader Sensed
[P, E] = PEInit(1,[20; 5; 0; 0],0,0,1,[4; 5; 0; 0]);
         %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
expected = '-1';
save examples/SNtest_PE3 P E expected

%Scenario IV: one node, Pursuer Connected, Evader Sensed
[P, E] = PEInit(1,[4; 5; 0; 0],0,0,1,[6; 5; 0; 0]);
         %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
expected = '1';
save examples/SNtest_PE4 P E expected

%Scenario V: two nodes, 3 hop connection
[P, E] = PEInit(1,[2; 20; 0; 0],0,0,1,[12; 20; 0; 0]);
         %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
expected = '2';
save examples/SNtest_PE5 P E expected

%Scenario VI: three nodes, 4 hop connection
[P, E] = PEInit(1,[2; 35; 0; 0],0,0,1,[17; 35; 0; 0]);
         %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
expected = '3';
save examples/SNtest_PE6 P E expected

%Scenario VII: one Node, Pursuer Connected, Evader Not Sensed
[P, E] = PEInit(1,[39; 5; 0; 0],0,0,1,[44; 5; 0; 0]);
         %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
expected = '';
save examples/SNtest_PE7 P E expected
