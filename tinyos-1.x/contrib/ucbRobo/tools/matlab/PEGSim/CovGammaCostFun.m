function J = CovGammaCostFun(u)
% NEED TO ADD GRADIENT CALC
% J = cost(Ppos-Epos) + cost(u) - trace(Cov) with weights
% Input: u  nT*1 vector, n is the dimension of the control, h is the
%           control time horizon.  Stacked u's, [u(:,1); u(:,2); ...]
% Ouput: Value of the cost, J & g, the gradient
%
% Uses b/(b+x^alpha) radio model.
% Works with PpolicyNonLinOpt.

global P;
global Pctrlr;
global SN; % Placeholder for the Pursuer's estimate of the sensor network
global testT; % 0 means we are not testing, otherwise represents time.

if (~isempty(testT) && (testT ~= 0))
    Epos = Pctrlr.E(:,testT);
    Ppos = Pctrlr.measPos(:,testT);
else
    Epos = Pctrlr.E(:,end);
    Ppos = Pctrlr.measPos(:,end);
end

Gamma = [];
A_p = Pctrlr.Pmodel.a;
B = Pctrlr.Pmodel.b;
A_e = Pctrlr.Emodel.a;
C_e = Pctrlr.Emodel.c;
G_e = Pctrlr.Emodel.b;
Q = Pctrlr.Q;
R = Pctrlr.R;
P_mat = Pctrlr.Ecov(:,:,end);

J = 0;
for t = 1:Pctrlr.ph
    Epos(:,end+1) = A_e*Epos(:,end);
    if (t <= Pctrlr.ch)
        Ppos(:,end+1) = A_p*Ppos(:,end) + B*u(2*t-1:2*t);
    else
        Ppos(:,end+1) = A_p*Ppos(:,end);
    end
    % Gamma(t) = Pctrlr.gamma(Ppos(1:2,t),Epos(1:2,t)); % If precomputed

    x_p = Ppos(1,end);
    y_p = Ppos(2,end);
    x_e = Epos(1,end);
    y_e = Epos(2,end);
    
    % finding the closest node to the pursuer
    F =  - [x_p - SN.nodes(1,:); y_p - SN.nodes(2,:)];
    F(1,:) = F(1,:).*F(1,:);
    F(2,:) = F(2,:).*F(2,:);
    F = sqrt([1 1] * F);
    [r_minP closeNodeP] = min(F);
    % finding the closest node to the evader
    G = [x_e - SN.nodes(1,:); y_e - SN.nodes(2,:)];
    G(1,:) = G(1,:).*G(1,:);
    G(2,:) = G(2,:).*G(2,:);
    G = sqrt([1 1] * G);
    [r_minE closeNodeE] = min(G);
    % Calculate the probabilities
    p = SN.connProb(closeNodeP,closeNodeE);
    Rp = SN.nodes(4,closeNodeP); %comm radius
    if(r_minP < Rp)
        b = SN.nodes(6,closeNodeP);
        p_lastHop = b/(b+r_minP^SN.alphaR);
        Gamma(t) = p*(1-(1-p_lastHop^3)); %allow 3 retransmissions
    else 
        Gamma(t) = 0;
    end
    % Calculate Covariance wrt Gamma
    P_mat = A_e*P_mat*A_e' + G_e*Q*G_e'; %P_k+1|k
    K = P_mat*C_e'*(C_e*P_mat*C_e' + R)^-1; % K_k+1
    P_mat = P_mat - Gamma(t)*K*C_e*P_mat; % P_k+1|k+1
    J = J + trace(P_mat);
end

J = Pctrlr.gWt*J;

if (~isempty(testT) && (testT ~= 0)) %DEBUG
    disp(sprintf('J from Gamma = %.2f',J)); 
    Gamma
end
    
for t = 2:Pctrlr.ph+1 %recall that Epos has 2-dim length h+1
    x_diff = Epos(:,t) - Ppos(:,t);
    J = J + x_diff'*Pctrlr.xWt*x_diff;
end
J = J + u'*Pctrlr.uWt*u;


if (~isempty(testT) && (testT ~= 0)) %DEBUG
    disp(sprintf('J final = %.2f',J));
end

% IMPLEMENTATION NOTES:
% Evaluates the expected value for Gamma, the probability for receiving a
% packet, given a vector of control inputs u.
% Note that this function depends on the state of the Pursuer and the
% Estimated State of the Evader.
%
% Technically, we should compute Gamma by using NOT the closest node to the
% pursuer but the node with the best connectivity.  We'll fix this later.
