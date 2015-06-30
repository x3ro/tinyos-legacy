function    [u,T] = feedback3(dx,dv,U,dT)
% this fuction computes the input to the thruster with feedback
% this is optimized for the discrete time system
% position error: dx = x_pursuer - x_evader 
% velocity error: dv = x_pursuer - x_evader 
% U: max thrust allowed
% dT: dicretization of thurster inputs  

% Copyright by Luca Schenato and UC Berkeley, 5 April 2004

x0 = dx/(U*dT^2); % normalized position
v0 = dv/(U*dT);  %normalized velocity
 
    
if x0 < -0.5*v0
    k = floor(-0.5 + 0.5*sqrt(1-4*(2*x0+v0)));
    dvv = -(x0+0.5*v0)/(k+1)+0.5*k;
else
    k = -floor(-0.5 + 0.5*sqrt(1+4*(2*x0+v0)));
    dvv = -(x0+0.5*v0)/(-k+1)+0.5*k;
end

if abs(dvv-v0) > 1
    u = U*sign(v0-dvv);
else
    u = U*(v0-dvv);
end

if 2*U*dx < -dv*abs(dv)
    T = (-dv + sqrt(2*dv^2-4*U*dx))/U;
else
    T = (+dv + sqrt(2*dv^2+4*U*dx))/U;
end
