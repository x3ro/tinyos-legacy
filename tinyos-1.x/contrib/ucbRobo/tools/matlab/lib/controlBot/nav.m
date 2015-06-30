function nav(x_start,y_start,x_end,y_end,RAD_heading, moteID)
% nav(x_start,y_start,x_end,y_end,RAD_heading, moteID)
% Allows for command line navigation of COTSBOTS.
%
% INPUTS: (x_start, y_start)    initial coordinates
%         (x_end, y_end)        destination coordinates
%         RAD_heading           heading in radians
%         moteID                moteID of the robot we are controlling

global COTSBOTS;
global COMM;
if isempty(COTSBOTS)
    error('You must call controlBotInit.m first to set up a connection.');
end
if (nargin < 6)
    moteID = COMM.TOS_BCAST_ADDR;
end

NavMsg = RobotCmd.NavigationMsg;
NavMsg.set_x1(x_start);
NavMsg.set_y1(y_start);
NavMsg.set_x2(x_end);
NavMsg.set_y2(y_end);
[num, denom] = rad2NavUnits(RAD_heading);
NavMsg.set_PiNumerator(num);
NavMsg.set_PiDenominator(denom);
send(moteID,NavMsg);
NavMsg


function [num, denom] = rad2NavUnits(RAD_heading)
% internal function to convert to NavigationMsg units used by COTSBOTS
[num, denom] = rat(mod(RAD_heading/pi,2));
