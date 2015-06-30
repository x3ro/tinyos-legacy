function [P,E] = PEinit(Pn,Ppos,Pmeas_std,Pact_std,En,Epos)

global P;
global E;
global Eprecomp;
global ReSimFlag;

P = struct;
E = struct;

if (ReSimFlag)
    Eprecomp = E;
end

% Positions should depend on sensor network dimensions
P.n = Pn;
P.pos = Ppos; % k*n*T matrix, for n pursuers, k dim state
              % vector, T time steps, last column is current state
P.control = zeros(2,1); % s*T matrix, for s control inputs, last
                        % control is current control
P.meas_std = Pmeas_std; % Standard Deviation of measurement noise of
                        % pursuer's own position
P.act_std = Pact_std; % Standard Deviation of actuation noise of
                      % pursuer's own position

E.n = En;
E.pos = Epos; % k*n*T matrix, for n pursuers, k dim state vector, T
              % time steps, last column is current state
