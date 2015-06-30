function    T = time2capture(dx,dv,U)
% this fuction computes the the time to capture assuming continuous dynamics
% dx - distance error from evader to pursuer
% dv - velocity error from evader to pursuer
% U - max input allowed to thruster

% Copyright by Luca Schenato and UC Berkeley, 5 April 2004

if 2*U*dx < -dv*abs(dv)
    T = (-dv + sqrt(2*dv^2-4*U*dx))/U;
else
    T = (+dv + sqrt(2*dv^2+4*U*dx))/U;
end