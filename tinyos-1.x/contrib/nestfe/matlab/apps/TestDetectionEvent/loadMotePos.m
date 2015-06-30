function [X,Y,moteIDs] = loadMotePos(motePosFile,moteIDs)
% loadMotePos(motePosFile,moteIDs)
% Parses motePosFile to find X and Y coordinates of moteIDs
%
% Input:
%   Assumes format in tinyos-1.x/contrib/testbed/testbed
%   format: mote <mote_id> <ip_address|host name> [<position x> <position y>]
%   The ip_address|hostname is not used
%
% Returns:
%   X         row vector of X coordinates
%   Y         row vector of Y coordinates
%   moteIDS   row vector of corresponding moteIDs to X,Y vectors
%
% If moteIDs is not passed in but motePosFile exists, then
% defaults to returning mote positions of all nodes in file.  
% If neither exist, then returns empty vectors.
%
% NOT FULLY IMPLEMENTED

disp('NOT FULLY IMPLEMENTED');
if isempty(motePosFile) % incorrect check
    disp('Using Default Positions. ex. moteID=0x1234, X=12, Y=34');
    X = floor(moteIDs./256);
    Y = rem(moteIDs,256);
    return;
end
