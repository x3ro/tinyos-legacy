function [J,g] = BasicCostFun(u)
% J = cost(Ppos-Epos) + cost(u) with weights
% Input: u  nT*1 vector, n is the dimension of the control, h is the
%           control time horizon.  Stacked u's, [u(:,1); u(:,2); ...]
% Ouput: Value of the cost, J & g, the gradient
%
% Works with PpolicyNonLinOpt.
% Should produce the same controls as PpolicyLQG (uses ARE for
% calculations) with finite horizon, if we choose the prediction horizon to
% equal the control horizon.

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
J = 0;
A_e = Pctrlr.Emodel.a;
A_p = Pctrlr.Pmodel.a;
B = Pctrlr.Pmodel.b;
for t = 1:Pctrlr.ph
    Epos(:,end+1) = A_e*Epos(:,end);
    if (t <= Pctrlr.ch)
        Ppos(:,end+1) = A_p*Ppos(:,end) + B*u(2*t-1:2*t);
    else
        Ppos(:,end+1) = A_p*Ppos(:,end);
    end
end

for t = 2:Pctrlr.ph+1 %recall that Epos has 2-dim length h+1
    x_diff = Epos(:,t) - Ppos(:,t);
    J = J + x_diff'*Pctrlr.xWt*x_diff;
end
J = J + u'*Pctrlr.uWt*u;

% !!!Something is Wrong with this... not getting the right answer!!
g = zeros(size(u));
if nargout > 1
    if ~isequal(A_e,A_p)
        error('1','The pursuer and evader dynamics are not the same');
    end
    
    bigA = eye(size(A_e)); %[A^n A^(n-1)B ... B]
    for t = 1:Pctrlr.ph
        bigA = [A_e*bigA B];
    end
    g = [Epos(:,1) - Ppos(:,1); u];
    g = Pctrlr.xWt*bigA*g;
    g = bigA'*g;
    g = 2*g;
    g = -g(5:end); %first 4 entries are derivatives wrt x0
    % Incorrect... does not have cross terms between different u's
    %     for t = 1:Pctrlr.ph
    %         g(2*t-1:2*t) = 2*B'*Pctrlr.xWt*B*u(2*t-1:2*t) + ...
    %             2*B'*Pctrlr.xWt*(A_e*Epos(:,t)-A_p*Ppos(:,t));
    %     end
end