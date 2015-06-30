function clearStates(PctrlrFlag)
% resets the states used by P,E, and Pctrlr without reloading parameters
% For use with resimulation when we cannot reload the data structures from
% files (in this case, call PEGSimMain(0,0,0)).
%
% Input: PctrlrFlag chooses the correct Pctrlr fields to clear depending
%                   on which initialization was used
%        1 = PpolicyNonLinOptInit

global P;
global E;
global Pctrlr;

if (nargin < 1)
    PctrlrFlag = 1;
end
switch PctrlrFlag
    case 1 % PpolicyNonLinOptInit
        Pctrlr.Ecov = Pctrlr.Ecov(:,:,1);
        Pctrlr.E = [];
        Pctrlr.uHoriz = [];
        Pctrlr.measPos = [];
        Pctrlr.uninit = true; % need to initialize estimated state on first
        % packet reception
        Pctrlr.lastUpdate = 0;
    otherwise
        disp(sprintf('PctrlrFlag %d not recognized',PctrlrFlag));
end

% PEInit Stuff
P.pos = P.pos(:,1);
P.control = zeros(2,1);
E.pos = E.pos(:,1);