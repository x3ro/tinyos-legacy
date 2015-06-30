function PpolicyLQG(rcvpkts)
% Updates P.control based on data received through the sensor network
% Uses Algebraic Riccati Equations and dlqr to compute the controls
% J = cost(Ppos-Epos) + cost(u) with weights
%
% Works with PpolicyNonLinOptInit (for initialization).

% IMPLEMENTATION NOTES
% Uses Pctrlr.ph for control and prediction horizon.

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

tic
A_e = Pctrlr.Emodel.a;
A_p = [ 1 0 dT 0;
        0 1 0  dT;
        0 0 1  0;
        0 0 0  1];
B_p = [dT^2/2 0;
       0      dT^2/2;
       dT     0;
       0      dT];
bigA = blkdiag(A_p,A_e);
bigB = [B_p; zeros(size(B_p))];
diffMat = [-eye(4) eye(4)];
bigQ = diffMat'*Pctrlr.xWt*diffMat;
bigR = Pctrlr.uWt*eye(2);

switch (Pctrlr.ctrlChoice)
    case 1
        % Infinite Horizon LQR
        bigA = bigA - 1e-4*eye(8); % for enforcing stability
        Klqr = dlqr(bigA,bigB,bigQ,bigR);
        lqr_u = -Klqr*[Pctrlr.measPos(:,end) ; Pctrlr.E(:,end)];
        %u(1:2) - lqr_u
        P.control(:,end+1) = lqr_u;
        
        %Computing the Horizon, for comparison
        Ppred = Pctrlr.measPos(:,end);
        Epred = Pctrlr.E(:,end);
        for i = 2:Pctrlr.ph
            Ppred = A_p*Ppred + B_p*lqr_u(end-1:end);
            Epred = A_e*Epred;
            lqr_u = [lqr_u ; (-Klqr*[Ppred ; Epred])];
        end
        Pctrlr.uHoriz = lqr_u;
        
    case 2
        % Finite Horizon LQR
        X = bigQ;
        K_ARE(:,:,1) = -(bigR+bigB'*X*bigB)^-1*bigB'*X*bigA;
        for i = 2:Pctrlr.ph
            X = bigQ + bigA'*X*bigA - bigA'*X*bigB*(bigR+bigB'*X*bigB)^-1*...
                bigB'*X*bigA;
            K_ARE(:,:,i) = -(bigR+bigB'*X*bigB)^-1*bigB'*X*bigA;
        end
        K_ARE = flipdim(K_ARE,3);
        lqrH_u = K_ARE(:,:,1)*[Pctrlr.measPos(:,end) ; Pctrlr.E(:,end)]; %finite horizon
        P.control(:,end+1) = lqrH_u;

        %Computing the Horizon, for comparison
        Ppred = Pctrlr.measPos(:,end);
        Epred = Pctrlr.E(:,end);
        for i = 2:Pctrlr.ph
            Ppred = A_p*Ppred + B_p*lqrH_u(end-1:end);
            Epred = A_e*Epred;
            lqrH_u = [lqrH_u ; (K_ARE(:,:,i)*[Ppred ; Epred])];
        end
        Pctrlr.uHoriz = lqrH_u;
    otherwise
        disp(sprintf('Invalid ctrlChoice: %d, no control computed',...
            ctrlChoice));
end
toc