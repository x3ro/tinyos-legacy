function resetLocalization(varargin)
%resetLocalization(varargin)
%
%this function starts characterization all over again.
%If you don't pass any moteIDs it resets all motes

global LOCALIZATION
global MAX_NETWORK_DIMENSION
MAX_NETWORK_DIMENSION=2;

if length(varargin) > 0
    moteIDs = varargin{1};
else
    moteIDs = LOCALIZATION.moteIDs;
end

LOCALIZATION.activeTransmitterIndex=length(LOCALIZATION.transmitters);
LOCALIZATION.activeTransmitter=LOCALIZATION.transmitters(LOCALIZATION.activeTransmitterIndex);
LOCALIZATION.distances = [];
LOCALIZATION.locations = [];
for i=1:length(moteIDs)
    LOCALIZATION.locations(moteIDs(i),:)=[rand*MAX_NETWORK_DIMENSION rand*MAX_NETWORK_DIMENSION];
    for j=1:length(moteIDs)
        LOCALIZATION.distances(moteIDs(i),moteIDs(j))=0;
        LOCALIZATION.tofReadings{moteIDs(i),moteIDs(j)}=[];
    end
end

for i=1:length(LOCALIZATION.fixed)
    [x y]=getLocation(LOCALIZATION.fixed(i));
    LOCALIZATION.locations(LOCALIZATION.fixed(i),:)=[x y];
end