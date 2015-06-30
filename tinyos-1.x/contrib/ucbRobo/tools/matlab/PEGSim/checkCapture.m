function capture = checkCapture
% Checks whether the pursuer has captured the evader
global P;
global E;

captureRadius = 1;
capture = (norm(P.pos(1:2,end) - E.pos(1:2,end)) < captureRadius);
