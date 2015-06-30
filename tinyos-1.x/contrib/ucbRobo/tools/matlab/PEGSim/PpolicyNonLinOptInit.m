function Pctrlr = PpolicyNonLinOptInit(ch,ph,xWt,uWt,gWt,s_q,s_r,ctrlChoice)
% PpolicyNonLinOptInit(ch,ph,xWt,uWt,gWt,s_q,s_r,ctrlChoice)
% Initializes the Pursuer's Controller
% Meant for Nonlinear Optimization to calculate the control law

global Pctrlr;
global P;
global dT;

Pctrlr = struct; % clear Pctrlr
Pctrlr.ch = ch; % control horizon
Pctrlr.ph = ph; % prediction horizon
Pctrlr.xWt = xWt;
Pctrlr.uWt = uWt; % column dimension nh or scalar
Pctrlr.gWt = gWt; % weight for Gamma
Pctrlr.ctrlChoice = ctrlChoice; % see PpolicyNonLinOpt for details

%%Model of Pursuer & Evader's Linear Dynamics
Ad = [1 0 dT 0;
      0 1 0 dT;
      0 0 1  0;
      0 0 0  1];
% Evader: inputs are disturbances (unmodeled actuation)
% Pursuer: inputs are disturbances + actuation
Bd = [dT^2/2 0;
      0      dT^2/2;
      dT     0;
      0      dT];
C = [1 0 0 0;
     0 1 0 0];
D = zeros(2);
Pctrlr.Emodel = ss(Ad,Bd,C,D,1);
Pctrlr.Pmodel = ss(Ad,Bd,C,D,1);

%%Error Model (of evader)
Pctrlr.s_q = s_q; % Actuation Noise Standard Deviation
Pctrlr.s_r = s_r; % Measurement Noise Standard Deviation
Pctrlr.Q = Pctrlr.s_q^2*eye(2);
Pctrlr.R = Pctrlr.s_r^2*eye(2);

%%Initial State of the estimator in the model
Pctrlr.Ecov = Bd*Pctrlr.Q*Bd'; % initial Evader Covariance
Pctrlr.E = [];
Pctrlr.uHoriz = [];
Pctrlr.measPos = [];
Pctrlr.uninit = true; % need to initialize estimated state on first 
                      % packet reception
Pctrlr.lastUpdate = 0;
