function PpolicyNonLinOpt(rcvpkts)
% Updates P.control based on data received through the sensor network
% Uses Nonlinear Optimization to compute the controls

global P;
global Pctrlr; % holds the state of the controller estimators, etc.
global history; % make history hold the values of the Pctrlr
global dT;

if ~isempty(rcvpkts)
    [maxT maxIndices] = max(rcvpkts(6,:));
    lastpkts = rcvpkts(:,maxIndices);
    Epos = mean(lastpkts(3:4,:),2); % average over all received latest
                                    % packets; can use other weighting
                                    % later
else
    Epos = [];
end

% Seed the estimated state in the controller
if Pctrlr.uninit
    if ~isempty(Epos)
        Pctrlr.uninit = false;
        Pctrlr.E = [Epos; 0 ; 0]; %Guess 0 velocity first
        Pctrlr.lastUpdate = maxT;
    else
        P.control = [0 ; 0]; % Don't do anything
        return;
    end
else
    % Kalman Filter to estimate Evader State
    %Innovation Step
    A_e = Pctrlr.Emodel.a;
    C_e = Pctrlr.Emodel.c;
    G_e = Pctrlr.Emodel.b;
    Q = Pctrlr.Q;
    R = Pctrlr.R;
    E_vec = Pctrlr.E(:,end);
    P_mat = Pctrlr.Ecov(:,:,end);
    E_vec = A_e*E_vec; % x_k+1|k
    P_mat = A_e*P_mat*A_e' + G_e*Q*G_e'; %P_k+1|k

    % Correction Step
    if (~isempty(Epos) && Pctrlr.lastUpdate < maxT)
        Pctrlr.lastUpdate = maxT;
        K = P_mat*C_e'*(C_e*P_mat*C_e' + R)^-1; % K_k+1
        P_mat = P_mat - K*C_e*P_mat; % P_k+1|k+1
        E_vec = E_vec + K*(Epos - C_e*E_vec); % x_k+1|k+1
    end
    Pctrlr.E(:,end+1) = E_vec;
    Pctrlr.Ecov(:,:,end+1) = P_mat;
end

% Pursuer State, no need for Kalman Filter
Pctrlr.measPos(:,end+1) = P.pos(:,end)+randn(4,1)*P.meas_std;

% Actual Control Output Calculation Step
% Initial Guess: drive toward the predicted evader position at horizon 
%                directly
if isempty(Pctrlr.uHoriz)
    t = Pctrlr.ch*dT;
    u0 = Pctrlr.E(:,end) - Pctrlr.measPos(:,end);
    u0 = 2*(u0(1:2) - u0(3:4)*t)/t^2; %a = 2(x-vt)/t^2
    u0 = u0*dT;
    u0 = u0 * ones(1,Pctrlr.ch); u0 = reshape(u0,[numel(u0) 1]);
else % use previous guess
    u0 = [Pctrlr.uHoriz(:,end) ; zeros(2,1)];
    u0 = u0(3:end);
end

tic
options = optimset('GradObj','off');

switch(Pctrlr.ctrlChoice)
    case 1
        u = fminunc(@BasicCostFun,u0,options);
    case 2
        u = fminunc(@SumGammaCostFun,u0,options);
    case 3
        u = fminunc(@CovGammaCostFun,u0,options);
    case 4
        u = fminunc(@CovGammaOnlyCostFun,u0,options);
    otherwise
        %default
        u = fminunc(@CovGammaCostFun,u0,options);
        %u = fminunc(@BasicCostFun,u0,options);
end
toc
P.control(:,end+1) = u(1:2); %Use only first control value
Pctrlr.uHoriz(:,end+1) = u;
