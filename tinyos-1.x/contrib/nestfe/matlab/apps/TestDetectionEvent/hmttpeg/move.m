function [xf,vf] = move(xi,vi,T,u)
% this function computes dynamics of second order linear system with no damping 
% along one direction when input u is applied for T second
% xi - initial position
% vi - initial velocity
% xf - final position
% vf - final velocity

% Copyright by Luca Schenato and UC Berkeley, 5 April 2004

xf = xi + vi*T+0.5*u*T^2 ;
vf = vi + u*T ;