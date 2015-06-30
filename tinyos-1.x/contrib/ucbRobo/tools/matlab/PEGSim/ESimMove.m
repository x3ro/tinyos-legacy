function ESimMove
% Simulates the motion of the evader in one time frame
% 1) Real Simulation: Controls are unknown and simulated by noise
% 2) Move following a precomputed path in Eprecomp
%    (Useful for comparing control law performance with a previous run)

global E;
global Eprecomp;
global T;
global dT;
global Pctrlr; % only necessary if you wish to match controller
global ReSimFlag;

if ReSimFlag
    index = round(T/dT); %avoid rounding errors in matlab
    if index < size(Eprecomp.pos,2)
        E.pos(:,end+1) = Eprecomp.pos(:,index + 1);
    else
        disp('Resimulation is taking more steps (probably means larger capture time).');
    end
end

if ~ReSimFlag || (index >= size(Eprecomp.pos,2))
    d = dT;
    % Linear Dynamics
    A = [ 1 0 d 0;
        0 1 0 d;
        0 0 1 0;
        0 0 0 1];
    Gd = [d^2/2 0;
        0     d^2/2;
        d     0;
        0     d];

    % actuation via noise.
    stdv =  Pctrlr.s_q;
    E.pos(:,end+1) = A*E.pos(:,end) + Gd*(stdv*randn(2,1));
end
