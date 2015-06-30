function PEGSimInit(SNfile,PEfile,Pctrlfile)
% Initializes P,E,SN (through SNSimInit) for simulation
%
% Inputs: SNfile    filename of precomputed Sensor Network configuration
%         PEfile    filename of initial Pursuer and Evader positions
% both SNfile and PEfile can also be a noncharacter, which means don't load
% anything and assume the data structures exist on your workspace

%SN, P, E are here for loading
global SN;
global P; % pursuer structure
global E; % evader structure
global history;
global queue;
global ReSimFlag;

if (nargin == 0)
    SNSimInit_ralpha(50,25,25,15,0.20,2,20,0.8,2,30,0.6);
    %n,dimX,dimY,rt_num,ob_noise,alphaS,betaS,etaS,alphaR,betaR,etaR,nodes

    % SNSimInit_simple(100,25,25,10,0.20,15,10);
    % args are: n,dimX,dimY,rt_num,ob_noise,R_s,R_r
else
    if isa(SNfile,'char')
        load(SNfile);
    end
end
if (nargin <= 1)
    PEInit(1,[15; 15; 0; 0],0,0,1,[20 ; 20; 1; 0.7]);
    %Pn,Ppos,Pmeas_std,Pact_std,En,Epos
else
    if isa(PEfile,'char')
        load(PEfile);
    end
end
if (nargin <= 2)
    PpolicyNonLinOptInit(10,30,diag([1,1,0,0]),0,1,1,1,4)
    %(ch,ph,xWt,uWt,gWt,s_q,s_r,ctrlChoice)
    %PpolicyNonLinOptInit(20,20,diag([1,1,0.5,0.5]),0.5,10000,1,0.2,1)
else
    if isa(Pctrlfile,'char')
        load(Pctrlfile);
    end
end

queue = []; % reset the packet queue
history = struct;
history.delay = {};
history.packets = {};
history.rcvpkts = {};
initPlotState; %clears all the junk from the previous run;