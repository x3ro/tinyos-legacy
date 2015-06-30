function initializeLocalization(varargin)
%initializeLocalization(transmitters, <fixedNodes>, <timeDuration>)
%this function does not erase your data
%
%This function takes the IDs of the motes it should localize
%It then tells each mote in turn to chirp that many times, listens
%to the responses from everybody else, and localizes every.  Then, the epoch
%starts again.


global LOCALIZATION
global MAX_NETWORK_DIMENSION
%MAX_NETWORK_DIMENSION=5;
global alpha
alpha = .05;

%TOF_DISTANCE.transmitterCalib{3}(2)=10;
%TOF_DISTANCE.transmitterCalib{27}(2)=20;

if length(varargin)>0
    LOCALIZATION.transmitters = sort(varargin{1});
else
    error('You need to enter the transmitters')
end

if length(varargin)>1
    LOCALIZATION.fixed=sort(varargin{2});
else
    LOCALIZATION.fixed=[];
end

LOCALIZATION.moteIDs = union(LOCALIZATION.transmitters, LOCALIZATION.fixed);

if length(varargin)>2
    LOCALIZATION.timeDuration = varargin{3};
else
    LOCALIZATION.timeDuration = .00005;
end

if ~isfield(LOCALIZATION,'distances') | ~isfield(LOCALIZATION,'locations')
    resetLocalization
end
