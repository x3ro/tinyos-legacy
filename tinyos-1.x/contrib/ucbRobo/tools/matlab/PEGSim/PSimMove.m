function PSimMove
% Simulates the motion of the pursuer in one time frame
% Uses P.control for controls
  
global P;
global dT;

% Linear Dynamics
Ad = [ 1 0 dT 0;
       0 1 0  dT;
       0 0 1  0;
       0 0 0  1];
Bd = [dT^2/2 0;
      0      dT^2/2;
      dT     0;
      0      dT];

P.pos(:,end+1) = Ad*P.pos(:,end) + Bd*(P.act_std*randn(2,1) + ...
                                      P.control(:,end));
